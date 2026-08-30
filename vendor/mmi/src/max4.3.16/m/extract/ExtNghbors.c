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
 * ExtNeighbors.c --
 *
 * Circuit extraction.
 * This file contains the primitive function ExtFindNeighbors()
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

#ifndef lint
static char rcsid[] = "$Header: ExtNghbors.c,v 6.0 90/08/28 18:15:21 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "memory.h"
#include "debug.h"
#include "extract.h"
#include "extractInt.h"
#include "signals.h"
#include "stack.h"

/*
 * The algorithm used by ExtFindNeighbors is non-recursive.
 * It uses a stack (extNodeStack) to hold a list of tiles yet to
 * be processed.  To mark a tile as being on the stack, we store
 * the value VISITPENDING in its ti_client field.
 */

/* Used for communicating with extNbrPushFunc */
ClientData extNbrUn;

/*
 * ----------------------------------------------------------------------------
 *
 * ExtFindNeighbors --
 *
 * For each tile adjacent to 'tile' that connects to it (according to
 * arg->fra_connectsTo), and (if it is a contact) for tiles on other
 * planes that connect to it, we recursively visit the tile, call the
 * client's filter procedure (*arg->fra_each)(), if it is non-NULL.
 * The tile is marked as being visited by setting it's ti_client field
 * to arg->fra_region.
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

ExtFindNeighbors(register Tile *tile, int tilePlaneNum, FindRegion *arg)
{
    TileTypeBitMask *connTo = arg->fra_connectsTo;
    register Tile *tp;
    register TileType type;
    register TileTypeBitMask *mask;
    Rect tileArea, biggerArea;
    int pNum;

    extNbrUn = arg->fra_uninit;
    if (extNodeStack == (Stack *) NULL)
	extNodeStack = StackNew(64);

    /* Mark this tile as pending and push it */
    PUSHTILE(tile);

    while (!StackEmpty(extNodeStack))
    {
	tile = (Tile *) STACKPOP(extNodeStack);
	type = DBgetTileType(tile);
	mask = &connTo[type];
	tilePlaneNum = DBPlane(DBgetTileType(tile));

	/*
	 * Since tile was pushed on the stack, we know that it
	 * belongs to this region.  Check to see that it hasn't
	 * been visited in the meantime.  If it's still unvisited,
	 * visit it and process its neighbors.
	 */
	if (tile->ti_client == (ClientData) arg->fra_region)
	    continue;
	tile->ti_client = (ClientData) arg->fra_region;
	if (DebugIsSet(extDebugID, extDebNeighbor))
	    extShowTile(tile, "neighbor", 1);

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (tp->ti_client == extNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		PUSHTILE(tp);

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (tp->ti_client == extNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		PUSHTILE(tp);

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (tp->ti_client == extNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		PUSHTILE(tp);

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (tp->ti_client == extNbrUn && TTMaskHasType(mask, DBgetTileType(tp)))
		PUSHTILE(tp);

	/* Apply the client's filter procedure if one exists */
	if (arg->fra_each)
	    if ((*arg->fra_each)(tile, tilePlaneNum, arg))
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
					  arg->fra_def->cd_planes[pNum], 
					  &biggerArea,
					  mask, 
					  extNbrPushFunc, 
					  (ClientData) &tileArea);
	    }
	}
    }

    return (0);

fail:
    /* Flush the stack */
    while (!StackEmpty(extNodeStack))
    {
	tile = (Tile *) STACKPOP(extNodeStack);
	tile->ti_client = (ClientData) arg->fra_region;
    }
    return (1);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extNbrPushFunc --
 *
 * Called for each tile overlapped by a 1-unit wide halo around the area
 * tileArea.  If the tile overlaps or shares a non-null segment of border
 * with tileArea, and it hasn't already been visited, push it on the stack
 * extNodeStack.
 *
 * Uses the global parameter extNbrUn to determine whether or not a tile
 * has been visited; if the tile's client field is equal to extNbrUn, then
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

int
extNbrPushFunc(register Tile *tile, register Rect *tileArea)
{
    Rect r;

    /* Ignore tile if it's already been visited */
    if (tile->ti_client != extNbrUn)
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
    PUSHTILE(tile);

    return 0;
}
