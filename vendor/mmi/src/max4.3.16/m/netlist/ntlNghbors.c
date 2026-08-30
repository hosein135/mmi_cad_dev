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
 * ntlNeighbors.c --
 *
 * Netlisting
 * This file contains the primitive function ntlFindNeighbors()
 * for visiting all neighbors of a tile that connect to it, and
 * applying a filter function at each tile.
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

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "memory.h"
#include "debug.h"
#include "netlist.h"
#include "netlistInt.h"
#include "signals.h"
#include "stack.h"

/*
 * The algorithm used by ntlFindNeighbors is non-recursive.
 * It uses a stack (ntlNodeStack) to hold a list of tiles yet to
 * be processed.  To mark a tile as being on the stack, we store
 * the value VISITPENDING in its ti_client field.
 */

/* Used for communicating with ntlNbrPushFunc */
ClientData ntlNbrUn;

Stack *ntlNodeStack = NULL;

/*
 * ----------------------------------------------------------------------------
 *
 * ntlNbrPushFunc --
 *
 * Called for each tile overlapped by a 1-unit wide halo around the area
 * tileArea.  If the tile overlaps or shares a non-null segment of border
 * with tileArea, and it hasn't already been visited, push it on the stack
 * ntlNodeStack.
 *
 * Uses the global parameter ntlNbrUn to determine whether or not a tile
 * has been visited; if the tile's client field is equal to ntlNbrUn, then
 * this is the first time the tile has been seen.
 *
 * Results:
 *	Always returns 0.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

static int
ntlNbrPushFunc(register Tile *tile, register Rect *tileArea)
{
    Rect r;

    /* Ignore tile if it's already been visited */
    if (tile->ti_client != ntlNbrUn)
	return 0;

    /* Only consider tile if it overlaps tileArea or shares part of a side */
    TITORECT(tile, &r);
    if (!GEO_OVERLAP(&r, tileArea))
    {
	GEOCLIP(&r, tileArea);
	if (r.r_xbot >= r.r_xtop && r.r_ybot >= r.r_ytop)
	    return 0;
    }

    /* Push tile on the stack and mark as being visited */
    NPUSHTILE(tile);

    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlFindNeighbors --
 *
 * For each tile adjacent to 'tile' that connects to it (according to
 * arg->nfra_connectsTo), and (if it is a contact) for tiles on other
 * planes that connect to it, we recursively visit the tile, call the
 * client's filter procedure (*arg->nfra_each)(), if it is non-NULL.
 * The tile is marked as being visited by setting it's ti_client field
 * to arg->nfra_region.
 *
 * Results:
 *	Returns 0 normally, or 1 if a client decided to abort the
 *	search, or if an interrupt was seen.
 *
 * Side effects:
 *	See comments above.
 *
 * ----------------------------------------------------------------------------
 */

int
ntlFindNeighbors(register Tile *tile, int tilePlaneNum, NFindRegion *arg)
{
    TileTypeBitMask *connTo = arg->nfra_connectsTo;
    register Tile *tp;
    register TileType type;
    register TileTypeBitMask *mask;
    Rect tileArea, biggerArea;
    int pNum;

    ntlNbrUn = arg->nfra_uninit;
    if (ntlNodeStack == (Stack *) NULL)
	ntlNodeStack = StackNew(64);

    /* Mark this tile as pending and push it */
    NPUSHTILE(tile);

    while (!StackEmpty(ntlNodeStack))
    {
	tile = (Tile *) STACKPOP(ntlNodeStack);
	type = DBgetTileType(tile);
	mask = &connTo[type];
	tilePlaneNum = DBPlane(DBgetTileType(tile));

	/*
	 * Since tile was pushed on the stack, we know that it
	 * belongs to this region.  Check to see that it hasn't
	 * been visited in the meantime.  If it's still unvisited,
	 * visit it and process its neighbors.
	 */
	if (tile->ti_client == (ClientData) arg->nfra_region)
	    continue;
	tile->ti_client = (ClientData) arg->nfra_region;

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (tp->ti_client == ntlNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		NPUSHTILE(tp);

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (tp->ti_client == ntlNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		NPUSHTILE(tp);

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (tp->ti_client == ntlNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		NPUSHTILE(tp);

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (tp->ti_client == ntlNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		NPUSHTILE(tp);

	/* Apply the client's filter procedure if one exists */
	if (arg->nfra_each)
	    if ((*arg->nfra_each)(tile, tilePlaneNum, arg))
		goto fail;

	/*
	 * The hairiest case is when this type connects to stuff on
	 * other planes.  In a case like this,
	 * we need to search the entire AREA of the tile plus a
	 * 1-lambda halo to find everything it overlaps or touches
	 * on the other plane.
	 */
	if (DBConnectPlanes[type])
	{
	    PlaneList *pll;

	    TITORECT(tile, &tileArea);
	    GEO_EXPAND(&tileArea, 1, &biggerArea);

	    for(pll = DBConnectPlanes[type]; pll; pll=pll->pll_next)
	    {
	      pNum = pll->pll_num;

	      (void) DBPlaneEnumAreaPaint((Tile *) NULL,
					  arg->nfra_def->cd_planes[pNum], 
					  &biggerArea,
					  mask, 
					  ntlNbrPushFunc, 
					  (ClientData) &tileArea);
	    }
	}
    }

    return (0);

fail:
    /* Flush the stack */
    while (!StackEmpty(ntlNodeStack))
    {
	tile = (Tile *) STACKPOP(ntlNodeStack);
	tile->ti_client = (ClientData) arg->nfra_region;
    }
    return (1);
}
