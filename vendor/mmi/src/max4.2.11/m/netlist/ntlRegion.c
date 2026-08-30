// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************



/*
 * ntlRegion.c --
 *
 * Circuit netlisting.
 * This file contains the code to trace out connected Regions
 * in a layout, and to build up or tear down lists of Regions.
 *
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */

#ifndef lint
static char rcsid[] = "$Header: ntlRegion.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "message.h"
#include "debug.h"
#include "netlist.h"
#include "netlistInt.h"
#include "signals.h"

/*
 * ----------------------------------------------------------------------------
 *
 * ntlRegionAreaFunc --
 *
 * Filter function called for each tile found during the area enumeration
 * in ExtFindRegions above.  Only tiles whose ti_client is not already
 * equal to arg->nfra_uninit are visited.
 *
 * We call 'nfra_first' to allocate a new region struct for it, and then
 * prepend it to the Region list (Region *) arg->nfra_clientData.  We
 * then call ExtFindNeighbors to trace out recursively all the remaining
 * tiles in the region.
 *
 * Results:
 *	Always returns 0, to cause DBPlaneEnumAreaPaintClient to continue its search.
 *
 * Side effects:
 *	Allocates a new Region struct if the tile has not yet been visited.
 *	See also the comments for ExtFindNeighbors.
 *
 * ----------------------------------------------------------------------------
 */

int
ntlRegionAreaFunc(register Tile *tile, register NFindRegion *arg)
{
    /* Allocate a new region */
    if (arg->nfra_first)
	(void) (*arg->nfra_first)(tile, arg);

    /* Recursively visit all tiles surrounding this one that we connect to */
    (void) ntlFindNeighbors(tile, arg->nfra_pNum, arg);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlFindRegions --
 *
 * Find all the connected geometrical regions in a given area of a CellDef
 * that will correspond to nodes or devices in the extracted circuit.
 * Two procedures are supplied by the caller, 'first' and 'each'.
 *
 * The function 'first' must be non-NULL.  It is called for each tile
 * tile found in the region.  It must return a pointer to a Region
 * struct (or one of the client forms of a Region struct; see the
 * comments in extractInt.h).
 *
 *	Region *
 *	(*first)(tile, arg)
 *	    Tile *tile;		/# Tile is on plane arg->nfra_pNum #/
 *	    FindRegion *arg;
 *	{
 *	}
 *
 * If the function 'each' is non-NULL, it is applied once to each tile found
 * in the region:
 *
 *	(*each)(tile, planeNum, arg)
 *	    Tile *tile;
 *	    int planeNum;	/# May be different than arg->nfra_pNum #/
 *	    FindRegion *arg;
 *	{
 *	}
 *
 * Results:
 *	Returns a pointer to the first element in the linked list
 *	of Region structures for this CellDef.  The Region structs
 *	may in fact contain more than the basic Region struct; this
 *	will depend on what the function 'first' allocates.
 *
 * Side effects:
 *	Each non-space tile has its ti_client field left pointing
 *	to a Region structure that describes the region that tile
 *	belongs to.
 *
 * Non-interruptible.  It is the caller's responsibility to check
 * for interrupts.
 *	
 * ----------------------------------------------------------------------------
 */

NRegion *
ntlFindRegions(CellDef *def, 
		Rect *area, 
		TileTypeBitMask *mask, 
		TileTypeBitMask *connectsTo, 
		ClientData uninit, 
		NRegion *(*first) (/* ??? */),
		int (*each) (/* ??? */))
                 		/* Cell definition being searched */
               			/* Area to search initially for tiles */
                          	/* In the initial area search, only visit
				 * tiles whose types are in this mask.
				 */
                                /* Connectivity table for determining regions.
				 * If t1 and t2 are the types of adjacent
				 * tiles, then t1 and t2 belong to the same
				 * region iff:
				 *	TTMaskHasType(&connectsTo[t1], t2)
				 *
				 * We assume that connectsTo[] is symmetric,
				 * so this is the same as:
				 *	TTMaskHasType(&connectsTo[t2], t1)
				 */
                      		/* Contents of a ti_client field indicating
				 * that the tile has not yet been visited.
				 */
                        	/* Applied to first tile in region */
                  		/* Applied to each tile in region */
{
    NFindRegion arg;
    int extRegionAreaFunc(register Tile *tile, register NFindRegion *arg);

    ASSERT(first != NULL, "ntlFindRegions");
    arg.nfra_connectsTo = connectsTo;
    arg.nfra_def = def;
    arg.nfra_uninit = uninit;
    arg.nfra_first = first;
    arg.nfra_each = each;
    arg.nfra_region = (NRegion *) NULL;

    SigDisableInterrupts();
    for (arg.nfra_pNum=PL_TECHDEPBASE; arg.nfra_pNum<DBNumPlanes; arg.nfra_pNum++)
	(void) DBPlaneEnumAreaPaintClient((Tile *) NULL, def->cd_planes[arg.nfra_pNum],
		area, mask, uninit, ntlRegionAreaFunc, (ClientData) &arg);
    SigEnableInterrupts();

    return (arg.nfra_region);
}
