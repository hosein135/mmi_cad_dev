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
 * ntlHier.c --
 *
 * functions that perform paint to instance overlap for hierarchical netlisting
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
static char rcsid[] = "$Header: ntlHier.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "memory.h"
#include "message.h"
#include "debug.h"
#include "signals.h"
#include "styles.h"
#include "netlistInt.h"
#include "netlist.h"

extern ntlHierInstFunc(CellUse * use, ClientData none);


/*
 * ----------------------------------------------------------------------------
 * ntlTile2InstFunc --
 *
 * 	Calls ntlTile2ElementFunc for each array element 
 *	in the expanded area of the tile
 *	Working in coordinates of celldef that contains 
 *	the tile and the instance (use1)
 *
 *	Don't know if the tile is connected to anything yet
 *
 * Results:
 *	Returns result of DBEnumArrayElements()
 *
 * Side effects: none
 *
 * ----------------------------------------------------------------------------
 */

static int 
ntlTile2InstFunc(Tile * tile, HierArg * ha )
{
    Rect r;

    /*
     * expand overlapping tile bbox, to handle touching case
     * makes up for the celluse bbox being no longer expanded
     * (continue to allow touching case)
     */
    TITORECT(tile, &r);
    GEO_EXPAND(&r, 1, &r);

    ha->ha_extRect = &r;
    ha->ha_extTile = tile;

    /* enumerate all array elements, 
     * in case the tile connects to more than one element 
     */
    return (DBEnumArrayElements(ha->ha_use1, 
			&r, 
			ntlTile2ElementFunc, 
			(ClientData) ha));
}

/*
 * ----------------------------------------------------------------------------
 * ntlHierTileFunc --
 *
 *	Enumerate tiles that overlap expanded bbox of the celluse
 *
 *	The enummeration is done twice
 *
 *	pass 1: connects only to ports that already exist
 *	pass 2: creates ports when overlap is discovered
 *
 *	  This avoids creation of implicit ports,
 *	  when the connection is made by explicit port
 *
 * Results: 0 to continue enumeration of instances
 *
 * Side effects: Fills in ha_use1 and ha_use2
 *
 * ----------------------------------------------------------------------------
 */
static int
ntlHierTileFunc(CellUse * use, ClientData none)
{
    Rect  r;
    int	  pNum;
    HierArg ha;
    CellDef * ParentDef = DBCellUseParent(use);

/*
MsgInfoF("\nChecking use %s for paint overlap, use bbox = (%d %d) (%d %d)\n", 
		use->cu_id, 
		use->cu_bbox.r_xbot, use->cu_bbox.r_ybot,
		use->cu_bbox.r_xtop, use->cu_bbox.r_ytop);
 */

    /*
     * first pass -- connect paint that overlaps explicit ports in use
     *
     * dont bother trying if there ore no explicit ports to connect to 
     */
    if (   (ParentDef->cd_labels != NULL)
	&& (ParentDef->cd_portCount != 0) )
    {
	ha.ha_pass2 = FALSE;
	ha.ha_use1 = use;
	ha.ha_use2 = (CellUse *) NULL;

	GEO_EXPAND(&use->cu_bbox, 1, &r);
	for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++) {
	    DBPlaneEnumAreaPaint(
		(Tile *) NULL,
		DBCellUseParent(use)->cd_planes[pNum],
		&r,			/* the expanded bbox of the celluse */
		&DBAllButSpaceBits,
		ntlTile2InstFunc, 
		(ClientData) &ha);
	}
    }

    /*
     * skip second pass if ALL overlaps resulted in connections
     * in the first pass
     * may need to modify so that this can happen more often
     * 
     * the issue is: in pass1
     * the flag can be reset when one tile overlaps in non-port area,
     * but another tile (of the same external node) makes the connection 
     * to the port
     *
     */

    /* if(need_port) */
    {
	ha.ha_pass2 = TRUE;
	ha.ha_use1 = use;
	ha.ha_use2 = (CellUse *) NULL;

	GEO_EXPAND(&use->cu_bbox, 1, &r);
	for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++) {
	    DBPlaneEnumAreaPaint(
		(Tile *) NULL,
		DBCellUseParent(use)->cd_planes[pNum],
		&r,			/* the expanded bbox of the celluse */
		&DBAllButSpaceBits,
		ntlTile2InstFunc, 
		(ClientData) &ha);
	}
    }

    return(0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlHierInstances --
 * enumerates all instances in the celldef
 * three passes, pass 2 and 3 could be combined
 *
 * pass 1) paint to instance
 * for all instances:
 * enumerate all paint that overlaps the bbox of the current instance
 * (just tiles for now, no polygons)
 * should only traverse layers that are wires !!
 *
 * pass 2) inst to inst overlap
 * for all instances:
 * enumerate instances that overlap the current instance
 * mark current instance as having been processed,
 * to avoid processing the same over lap again
 *
 * pass 3) array element to array element 
 * develop "`prototype" assuming that maximum overlap is 
 * 2 elements in both X and Y
 *
 * ----------------------------------------------------------------------------
 */

void
ntlHierInstances(CellDef * def)
{
     /*  Pass 1 of all instances */
/*
MsgInfoF("Pass 1: paint to instance interaction for celldef %s\n",
	def->cd_name);
*/
    (void) DBEnumChildren(def, ntlHierTileFunc, (ClientData) NULL);

/*
MsgInfoF("Pass 2: instance to instance interaction for celldef %s\n",
	def->cd_name);
*/
     /*  Pass 2 of all instances */
    (void) DBEnumChildren(def, ntlHierInstFunc, (ClientData) NULL);
}



