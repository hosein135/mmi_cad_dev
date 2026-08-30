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
 * ntlHier1.c --
 *
 * functions that perform instance to instance overlap 
 * processing for hierarchical netlisting
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
static char rcsid[] = "$Header: ntlHier1.c,v 6.0 90/08/28 18:15:25 mayo Exp $";
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
#include "signals.h"
#include "styles.h"
#include "netlistInt.h"
#include "netlist.h"



/* 
 * ----------------------------------------------------------------------------
 * ntlInst2InstFunc2 --
 *
 *	Transform tile (from use 2) into parent coordinates
 *	and enumerate all array elements in use 1 that overlap
 *
 * Results: returns result of DBEnumArrayElements
 *
 * Side effects: stores tile2 in local variable 
 *
 * ----------------------------------------------------------------------------
 */
int ntlInst2InstFunc2 (Tile * tile2, HierArg * ha)
{
    Rect r, r1;

    /*return(0); */

    TITORECT(tile2, &r);
    GEOTRANSRECT(ntlTransUse2toParent, &r, &r1);
    GEO_EXPAND(&r1, 1, &r1);

    ha->ha_extRect = &r1;
    ha->ha_extTile = tile2;

    return (DBEnumArrayElements(ha->ha_use1, 
	    &r,
	    ntlTile2ElementFunc,
	    (ClientData) ha));
}

/* 
 * ----------------------------------------------------------------------------
 * ntlInst2InstFunc1 --
 *
 *	Enumerate all paint in use2 that overlaps expanded bbox of use1
 *
 * Results: none
 *
 * Side effects: saves use 2 information in hierarg
 *	Saves transform for use2 to Parent coords in local variable
 *	
 *
 * ----------------------------------------------------------------------------
 */

int ntlInst2InstFunc1 (SearchContext * scx, HierArg * ha)
{
    Rect  r;
    int   pNum, xlen, element;
    CellUse * use2 = scx->scx_use;

    /*
     * done if this interaction has already been processed 
     * separate flags based on pass
     */
    if(use2->cu_flags & (ha->ha_pass2 ? CU_NTL_CHECKED2 : CU_NTL_CHECKED2 ))
	return 0;

    /* fill in hierarg fields for use2 */
    ha->ha_use2 = use2;

    /* compute the address of the port connections for this array element */
    xlen =  ABS(use2->cu_xhi - use2->cu_xlo) + 1;
    element = (scx->scx_y * xlen ) + scx->scx_x;
    ha->ha_elementConns2 = (PortConnector **) &(use2->cu_elementConns[element]);

    /* save transform to parent */
    ntlTransUse2toParent = &scx->scx_trans;

    /* expand the bbox of celluse1 
     * note that scx_area has been transforemed 
     * into coordinates of use2's def by calling function 
     */
    GEO_EXPAND(&scx->scx_area, 1, &r);

    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++) {
        DBPlaneEnumAreaPaint(
            (Tile *) NULL,
            scx->scx_use->cu_def->cd_planes[pNum],
            &r,                 
            &DBAllButSpaceBits,
            ntlInst2InstFunc2,
            (ClientData) ha);
    }
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 * ntlHierInstFunc --
 *
 *	Enumerate instances (use2) that overlap the bbox of the 
 *	calling use (use1)
 *
 * 	The celldef to be searched is (CellDef *) use->cu_parent
 *
 *	The use of DBSrChildrenNested for this purpose is a little confusing
 *	It is not being used recursively, but only to search a single celldef
 *
 *	The required search context includes a CellUse * argument, 
 *	but it is only used to pass the def to search, 
 *	in scx->scx_use->cu_def
 *
 * Results: 0 to continue enumeration
 *
 * Side effects:
 * 	Saves pointer to use1 in HierArg
 *	Marks current instance (use1) as having been processed,
 *	to avoid processing the same overlap again
 * 
 * ----------------------------------------------------------------------------
 */

int ntlHierInstFunc(CellUse * use1, ClientData none)
{
    SearchContext scx;
    CellUse dummyUse;
    Transform tinv;

    HierArg ha;

    ha.ha_use1 = use1;

    /* mark use1 as having had all of its interactions checked 
     * marking now, instead of after checking,
     * to prevent checking when use2 is the same as use1
     */
    use1->cu_flags |= CU_NTL_CHECKED;

    /* no other fields of dummyUse are filled in ! */
    dummyUse.cu_def = use1->cu_parent;
    scx.scx_use = &dummyUse;

    /* search parent def for instances that overlap use1 */
    scx.scx_area = use1->cu_bbox;

    /* start with identity xform, so callback receives use-to-parent xform */
    scx.scx_trans = GeoIdentityTransform;

    /* dont bother if use1's def has no ports or labels */
    if (   (use1->cu_def->cd_labels != NULL)
	&& (use1->cu_def->cd_portCount != 0) )

    {
	ha.ha_pass2 = FALSE;
	DBSrChildrenNested(&scx, ntlInst2InstFunc1, (ClientData) &ha);
    }

    /* second pass allows creation of implicit ports in use1->cu_def
     * could optimize here if all ports have connections 
     */
    {
	use1->cu_flags |= CU_NTL_CHECKED2;
	ha.ha_pass2 = TRUE;
	DBSrChildrenNested(&scx, ntlInst2InstFunc1, (ClientData) &ha);
    }

    return(0);
}
