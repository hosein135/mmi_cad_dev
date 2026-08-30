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
 * DBplane.c --
 *
 * Low level routines for managing tile planes.
 * This includes area searching and all other primitives that
 * need to know what lives in a tile body.
 *
 * See also DBpaint*.c
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
static char rcsid[] = "$Header: DBtiles.c,v 6.0 90/08/28 18:10:24 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "signals.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "utils.h"
#include "layout.h"


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneNew --
 *
 * Allocates and initializes a new tile plane for a cell.
 * The new plane contains a single tile whose body is specified by
 * the caller.  The tile extends from minus infinity to plus infinity.
 *
 * Results:
 *	Returns a pointer to a new tile plane.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 *
 */
Plane *
DBPlaneNew(ClientData body)
                    	/* Body of initial, central tile */
{
    return (TiNewPlane(body));
}



/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneEmptyQ --
 *
 * Returns True iff a single SPACE tile spans entire plane 
 *
 * ----------------------------------------------------------------------------
 *
 */
bool DBPlaneEmptyQ(Plane *plane)
{
  Tile *ti = LB(plane->pl_top);

  return  BOTTOM(ti) <= TiPlaneRect.r_ybot &&
          RIGHT(ti)  >= TiPlaneRect.r_xtop &&
          DBgetTileType(ti) == TT_SPACE;
}


/*
 * --------------------------------------------------------------------
 *
 * DBFreePaintPlane --
 *
 * Deallocates all tiles in a paint tile plane of a given CellDef.
 * Doesn't deallocate the four boundary tiles, or the plane itself.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Deallocates a lot of memory.  
 *
 *			*** WARNING ***
 *
 * This procedure uses a carfully constructed non-recursive area 
 * enumeration algorithm.  Care is taken to not access a tile that has
 * been deallocated.  The only exception is for a tile that has just been
 * passed to TiFree(), but no more calls to TiFree() or TiAlloc() have 
 * been made since.  
 *
 * All this care is obsolete!  As long as no TiAlloc() calls are made 
 * and ti_client fields of freed tiles are not referenced, everything 
 * is hunky-doory.
 *
 * --------------------------------------------------------------------
 */

void
DBFreePaintPlane(Plane *plane)
                 	/* Plane whose storage is to be freed */
{
    register Tile *tp, *tpnew;
    register Rect *rect = &TiPlaneRect;

    /* Start with the bottom-right non-infinity tile in the plane */
    tp = plane->pl_right->ti_bl;

    /* Each iteration visits another tile on the RHS of the search area */
    while (BOTTOM(tp) < rect->r_ytop)
    {
enumerate:

#define	CLIP_TOP(t)	(MIN(TOP(t),rect->r_ytop))

	/* Move along to the next tile to the left */
	if (LEFT(tp) > rect->r_xbot)
	{
	    tpnew = BL(tp);
	    while (TOP(tpnew) <= rect->r_ybot) tpnew = RT(tpnew);
	    if (CLIP_TOP(tpnew) <= CLIP_TOP(tp))
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the right */
	while (RIGHT(tp) < rect->r_xtop)
	{
	    TiFree(tp, plane); 
	    tpnew = RT(tp);
	    tp = TR(tp);
	    if (CLIP_TOP(tpnew) <= CLIP_TOP(tp) && BOTTOM(tpnew) < rect->r_ytop)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	TiFree(tp, plane); 
	/* At right edge -- walk up to next tile along the right edge */
	tp = RT(tp);
	if (BOTTOM(tp) < rect->r_ytop) {
	    while(LEFT(tp) >= rect->r_xtop) tp = BL(tp);
	}
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbPlaneInitToTile --
 *
 * Set the single central tile of a plane to be that specified.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the plane given.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbPlaneInitToTile(register Plane *plane, register Tile *newCenterTile)
{
    /*
     * Set the stitches of the newly created center tile
     * to point to the four boundaries of the plane.
     */

    RT(newCenterTile) = plane->pl_top;
    TR(newCenterTile) = plane->pl_right;
    LB(newCenterTile) = plane->pl_bottom;
    BL(newCenterTile) = plane->pl_left;

    /*
     * Set the stitches for the four boundaries of the plane
     * all to point to the newly created center tile.
     */

    RT(plane->pl_bottom) = newCenterTile;
    LB(plane->pl_top) = newCenterTile;
    TR(plane->pl_left) = newCenterTile;
    BL(plane->pl_right) = newCenterTile;

    LEFT(newCenterTile) = TiPlaneRect.r_xbot;
    BOTTOM(newCenterTile) = TiPlaneRect.r_ybot;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneClearPaint --
 *
 * Similar in effect to painting space over an entire tile plane, but
 * much faster.  The resultant tile plane is guaranteed to contain a
 * single central space tile, exactly as though it had been newly allocated.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database plane given.
 *
 * ----------------------------------------------------------------------------
 */

void
DBPlaneClearPaint(Plane *plane)
{
    register Tile *newCenterTile;

    /* Eliminate all the tiles from this plane */
    DBFreePaintPlane(plane);

    /* Allocate a new central space tile */
    newCenterTile = TiAlloc(plane);
    plane->pl_hint = newCenterTile;
    TiSetBody(newCenterTile, TT_SPACE);
    dbPlaneInitToTile(plane, newCenterTile);
}

/* Used by DBPlaneCheckMaxHStrips() and DBPlaneCheckMaxVStrips() below */
struct dbCheck
{
    int		(*dbc_proc)();
    Rect	  dbc_area;
    ClientData    dbc_cdata;
};


/*
 * --------------------------------------------------------------------
 *
 * DBPlaneResetClients --
 *
 * Reset the ti_client fields of all tiles in a paint tile plane to
 * the value 'cdata'.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Resets the ti_client fields of all tiles.
 *
 * --------------------------------------------------------------------
 */

void DBPlaneResetClients(Plane *plane, 
			 /* Plane whose tiles are to be reset */
			 ClientData cdata)

                     
{
    register Tile *tp, *tpnew;
    register Rect *rect = &TiPlaneRect;

    /* Start with the leftmost non-infinity tile in the plane */
    tp = plane->pl_left->ti_tr;

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tp) > rect->r_ybot)
    {
	/* Each iteration frees another tile */
enumerate:
	tp->ti_client = cdata;

	/* Move along to the next tile */
	tpnew = TR(tp);
	if (LEFT(tpnew) < rect->r_xtop)
	{
	    while (BOTTOM(tpnew) >= rect->r_ytop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tp) > rect->r_xbot)
	{
	    if (BOTTOM(tp) <= rect->r_ybot)
		return;
	    tpnew = LB(tp);
	    tp = BL(tp);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* At left edge -- walk down to next tile along the left edge */
	for (tp = LB(tp); RIGHT(tp) <= rect->r_xbot; tp = TR(tp))
	    /* Nothing */;
    }
}


/*
 * --------------------------------------------------------------------
 *
 * DBPlaneCheckMaxHStrips --
 *
 * Check the maximal horizontal strip property for the
 * tile plane 'plane' over the area 'area'.
 *
 * Results:
 *	Normally returns 0; returns 1 if the procedure
 *	(*proc)() returned 1 or if the search were
 *	aborted with an interrupt.
 *
 * Side effects:
 *	Calls the procedure (*proc)() for each offending tile.
 *	This procedure should have the following form:
 *
 *	int
 *	proc(tile, side, cdata)
 *	    Tile *tile;
 *	    int side;
 *	    ClientData cdata;
 *	{
 *	}
 *
 *	The client data is the argument 'cdata' passed to us.
 *	The argument 'side' is one of GEO_NORTH, GEO_SOUTH,
 *	GEO_EAST, or GEO_WEST, and indicates which side of
 *	the tile the strip property was violated on.
 *	If (*proc)() returns 1, we abort and return 1
 *	to our caller.
 *
 * --------------------------------------------------------------------
 */

/* filter func */
static int
dbCheckMaxHFunc(register Tile *tile, register struct dbCheck *dbc)
{
    register Tile *tp;

    /*
     * Property 1:
     * No tile to the left or to the right should have the same
     * type as 'tile'.
     */
    if (RIGHT(tile) < dbc->dbc_area.r_xtop)
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (DBgetTileType(tp) == DBgetTileType(tile))
		if ((*dbc->dbc_proc)(tile, GEO_EAST, dbc->dbc_cdata))
		    return (1);
    if (LEFT(tile) > dbc->dbc_area.r_xbot)
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (DBgetTileType(tp) == DBgetTileType(tile))
		if ((*dbc->dbc_proc)(tile, GEO_WEST, dbc->dbc_cdata))
		    return (1);

    /*
     * Property 2:
     * No tile to the top or bottom should be of the same type and
     * have the same width.
     */
    if (TOP(tile) < dbc->dbc_area.r_ytop)
    {
	tp = RT(tile);
	if (DBgetTileType(tp) == DBgetTileType(tile)
		&& LEFT(tp) == LEFT(tile)
		&& RIGHT(tp) == RIGHT(tile))
	    if ((*dbc->dbc_proc)(tile, GEO_NORTH, dbc->dbc_cdata))
		return (1);
    }
    if (BOTTOM(tile) > dbc->dbc_area.r_ybot)
    {
	tp = LB(tile);
	if (DBgetTileType(tp) == DBgetTileType(tile)
		&& LEFT(tp) == LEFT(tile)
		&& RIGHT(tp) == RIGHT(tile))
	    if ((*dbc->dbc_proc)(tile, GEO_SOUTH, dbc->dbc_cdata))
		return (1);
    }

    return (0);
}

int
DBPlaneCheckMaxHStrips(Plane *plane, Rect *area, int (*proc) (/* ??? */), ClientData cdata)
                 	/* Search this plane */
               		/* Process all tiles in this area */
                  	/* Filter procedure: see above */
                     	/* Passed to (*proc)() */
{
    struct dbCheck dbc;

    dbc.dbc_proc = proc;
    dbc.dbc_area = *area;
    dbc.dbc_cdata = cdata;
    return (DBPlaneEnumAreaPaint((Tile *) NULL, plane, area,
		&DBAllTypeBits, dbCheckMaxHFunc, (ClientData) &dbc));
}


/*
 * --------------------------------------------------------------------
 *
 * DBPlaneCheckMaxVStrips --
 *
 * Check the maximal vertical strip property for the
 * tile plane 'plane' over the area 'area'.
 *
 * Results:
 *	Normally returns 0; returns 1 if the procedure
 *	(*proc)() returned 1 or if the search were
 *	aborted with an interrupt.
 *
 * Side effects:
 *	See DBPlaneCheckMaxHStrips() above.
 *
 * --------------------------------------------------------------------
 */

/* filter func */
static int
dbCheckMaxVFunc(register Tile *tile, register struct dbCheck *dbc)
{
    register Tile *tp;

    /*
     * Property 1:
     * No tile to the top or to the bottom should have the same
     * type as 'tile'.
     */
    if (TOP(tile) < dbc->dbc_area.r_ytop)
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (DBgetTileType(tp) == DBgetTileType(tile))
		if ((*dbc->dbc_proc)(tile, GEO_NORTH, dbc->dbc_cdata))
		    return (1);
    if (BOTTOM(tile) > dbc->dbc_area.r_ybot)
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (DBgetTileType(tp) == DBgetTileType(tile))
		if ((*dbc->dbc_proc)(tile, GEO_SOUTH, dbc->dbc_cdata))
		    return (1);

    /*
     * Property 2:
     * No tile to the left or right should be of the same type and
     * have the same height.
     */
    if (RIGHT(tile) < dbc->dbc_area.r_xtop)
    {
	tp = TR(tile);
	if (DBgetTileType(tp) == DBgetTileType(tile)
		&& BOTTOM(tp) == BOTTOM(tile)
		&& TOP(tp) == TOP(tile))
	    if ((*dbc->dbc_proc)(tile, GEO_EAST, dbc->dbc_cdata))
		return (1);
    }
    if (LEFT(tile) > dbc->dbc_area.r_xbot)
    {
	tp = BL(tile);
	if (DBgetTileType(tp) == DBgetTileType(tile)
		&& BOTTOM(tp) == BOTTOM(tile)
		&& TOP(tp) == TOP(tile))
	    if ((*dbc->dbc_proc)(tile, GEO_WEST, dbc->dbc_cdata))
		return (1);
    }

    return (0);
}

int
DBPlaneCheckMaxVStrips(Plane *plane, Rect *area, int (*proc) (/* ??? */), ClientData cdata)
                 	/* Search this plane */
               		/* Process all tiles in this area */
                  	/* Filter procedure: see above */
                     	/* Passed to (*proc)() */
{
    struct dbCheck dbc;

    dbc.dbc_proc = proc;
    dbc.dbc_area = *area;
    dbc.dbc_cdata = cdata;
    return (DBPlaneEnumAreaPaint((Tile *) NULL, plane, area,
		&DBAllTypeBits, dbCheckMaxVFunc, (ClientData) &dbc));
}


/*
 * --------------------------------------------------------------------
 *
 * DBPlaneEnumAreaPaint --
 *
 * Find all tiles overlapping a given area whose types are contained
 * in the mask supplied.  Apply the given procedure to each such tile.
 * The procedure should be of the following form:
 *
 *	int
 *	func(tile, cdata)
 *	    Tile *tile;
 *	    ClientData cdata;
 *	{
 *	}
 *
 * Func normally should return 0.  If it returns 1 then the search
 * will be aborted.  WARNING: THE CALLED PROCEDURE MAY NOT MODIFY
 * THE PLANE BEING SEARCHED!!!
 *
 *
 * Results:
 *	0 is returned if the search completed normally.  1 is returned
 *	if it aborted.
 *
 * --------------------------------------------------------------------
 */

int
DBPlaneEnumAreaPaint(Tile *hintTile, 
                   		/* Tile at which to begin search, if not NULL.
				 * If this is NULL, use the hint tile supplied
				 * with plane.
				 */
	      register Plane *plane, 
                          	/* Plane in which tiles lie.  This is used to
				 * provide a hint tile in case hintTile == NULL.
				 * The hint tile in the plane is updated to be
				 * the last tile visited in the area
				 * enumeration.
				 */
	      register Rect *rect, 
                        	/* Area to search.  This area should not be
				 * degenerate.  Tiles must OVERLAP the area.
				 */
	      TileTypeBitMask *mask, 
                          	/* Mask of those paint tiles to be passed to
				 * func.
				 */
	      int (*func) (/* ??? */), 
                  		/* Function to apply at each tile */
	      ClientData arg)
                   		/* Additional argument to pass to (*func)() */
{
    Point start;
    register Tile *tp, *tpnew;


#ifdef PARANOID
    /* area must not be degenerate, since we look for area OVERLAP */ 
    ASSERT(rect->r_xbot<rect->r_xtop && rect->r_ybot<rect->r_ytop,
	   "DBPlaneEnumAreaPaint");
#endif PARANOID

    start.p_x = rect->r_xbot;
    start.p_y = rect->r_ytop - 1;
    tp = hintTile ? hintTile : plane->pl_hint;
    GOTOPOINT(tp, &start);

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tp) > rect->r_ybot)
    {
	/* Each iteration enumerates another tile */
enumerate:
	plane->pl_hint = tp;
	if (SigInterruptPending)
	    return (1);

	if (TTMaskHasType(mask, DBgetTileType(tp)) && (*func)(tp, arg))
	    return (1);

	tpnew = TR(tp);
	if (LEFT(tpnew) < rect->r_xtop)
	{
	    while (BOTTOM(tpnew) >= rect->r_ytop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	} 

	/* Each iteration returns one tile further to the left */
	while (LEFT(tp) > rect->r_xbot)
	{
	    if (BOTTOM(tp) <= rect->r_ybot) 
		return (0);
	    tpnew = LB(tp);
	    tp = BL(tp);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* At left edge -- walk down to next tile along the left edge */
	for (tp = LB(tp); RIGHT(tp) <= rect->r_xbot; tp = TR(tp))
	    /* Nothing */;
    }
    return (0);
}



/*
 * --------------------------------------------------------------------
 *
 * DBPlaneEnumAreaPaintG --
 *
 * Like DBPlaneEnumAreaPaint, but enumerates given group.
 *
 * Find all tiles overlapping a given area whose types are contained
 * in the mask supplied.  Apply the given procedure to each such tile.
 * The procedure should be of the following form:
 *
 *	int
 *	func(tile, cdata)
 *	    Tile *tile;
 *	    ClientData cdata;
 *	{
 *	}
 *
 * Func normally should return 0.  If it returns 1 then the search
 * will be aborted.  WARNING: THE CALLED PROCEDURE MAY NOT MODIFY
 * THE PLANE BEING SEARCHED!!!
 *
 *
 * Results:
 *	0 is returned if the search completed normally.  1 is returned
 *	if it aborted.
 *
 * --------------------------------------------------------------------
 */

int
DBPlaneEnumAreaPaintG(Tile *hintTile, 
                   		/* Tile at which to begin search, if not NULL.
				 * If this is NULL, use the hint tile supplied
				 * with plane.
				 */
	      register Plane *plane, 
                          	/* Plane in which tiles lie.  This is used to
				 * provide a hint tile in case hintTile == NULL.
				 * The hint tile in the plane is updated to be
				 * the last tile visited in the area
				 * enumeration.
				 */
	      register Rect *rect, 
                        	/* Area to search.  This area should not be
				 * degenerate.  Tiles must OVERLAP the area.
				 */
	      TileTypeBitMask *mask, 
                          	/* Mask of those paint tiles to be passed to
				 * func.
				 */
              Group *group,		     
                                /* group to enumerate */
	      int (*func) (/* ??? */), 
                  		/* Function to apply at each tile */
	      ClientData arg)
                   		/* Additional argument to pass to (*func)() */

{
    Point start;
    register Tile *tp, *tpnew;

#ifdef PARANOID
    /* area must not be degenerate, since we look for area OVERLAP */
    ASSERT(rect->r_xbot<rect->r_xtop && rect->r_ybot<rect->r_ytop,
	   "DBPlaneEnumAreaPaintG");
#endif PARANOID

    start.p_x = rect->r_xbot;
    start.p_y = rect->r_ytop - 1;
    tp = hintTile ? hintTile : plane->pl_hint;
    GOTOPOINT(tp, &start);

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tp) > rect->r_ybot)
    {
	/* Each iteration enumerates another tile */
enumerate:
	plane->pl_hint = tp;
	if (SigInterruptPending)
	    return (1);

	if (TTMaskHasType(mask, DBgetTypeG(tp, group)) && (*func)(tp, arg))
	    return (1);

	tpnew = TR(tp);
	if (LEFT(tpnew) < rect->r_xtop)
	{
	    while (BOTTOM(tpnew) >= rect->r_ytop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	} 

	/* Each iteration returns one tile further to the left */
	while (LEFT(tp) > rect->r_xbot)
	{
	    if (BOTTOM(tp) <= rect->r_ybot) 
		return (0);
	    tpnew = LB(tp);
	    tp = BL(tp);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* At left edge -- walk down to next tile along the left edge */
	for (tp = LB(tp); RIGHT(tp) <= rect->r_xbot; tp = TR(tp))
	    /* Nothing */;
    }
    return (0);
}


/*
 * --------------------------------------------------------------------
 *
 * DBPlaneEnumAreaPaintClient --
 *
 * Find all tiles overlapping a given area whose types are contained
 * in the mask supplied, and whose ti_client field matches 'client'.
 * Apply the given procedure to each such tile.  The procedure should
 * be of the following form:
 *
 *	int
 *	func(tile, cdata)
 *	    Tile *tile;
 *	    ClientData cdata;
 *	{
 *	}
 *
 * Func normally should return 0.  If it returns 1 then the search
 * will be aborted.
 *
 * Results:
 *	0 is returned if the search completed normally.  1 is returned
 *	if it aborted.
 *
 * Side effects:
 *	Whatever side effects result from application of the
 *	supplied procedure.
 *
 * --------------------------------------------------------------------
 */

int
DBPlaneEnumAreaPaintClient(Tile *hintTile, 
                   		/* Tile at which to begin search, if not NULL.
				 * If this is NULL, use the hint tile supplied
				 * with plane.
				 */
			   register Plane *plane, 
                          	/* Plane in which tiles lie.  This is used to
				 * provide a hint tile in case hintTile == NULL.
				 * The hint tile in the plane is updated to be
				 * the last tile visited in the area
				 * enumeration.
				 */
			   register Rect *rect, 
                        	/* Area to search.  This area should not be
				 * degenerate.  Tiles must OVERLAP the area.
				 */
			   TileTypeBitMask *mask, 
                          	/* Mask of those paint tiles to be passed to
				 * func.
				 */
			   ClientData client, 
                      		/* The ti_client field of each tile must
				 * match this.
				 */
			   int (*func) (/* ??? */), 
                  		/* Function to apply at each tile */
			   ClientData arg)
                   		/* Additional argument to pass to (*func)() */
{
    Point start;
    register Tile *tp, *tpnew;


#ifdef PARANOID
    /* area must not be degenerate, since we look for area OVERLAP */
    ASSERT(rect->r_xbot<rect->r_xtop && rect->r_ybot<rect->r_ytop,
	   "DBPlaneEnumAreaPaintClient");
#endif PARANOID

    start.p_x = rect->r_xbot;
    start.p_y = rect->r_ytop - 1;
    tp = hintTile ? hintTile : plane->pl_hint;
    GOTOPOINT(tp, &start);

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tp) > rect->r_ybot)
    {
	/* Each iteration enumerates another tile */
enumerate:
	plane->pl_hint = tp;
	if (SigInterruptPending)
	    return (1);

	if (TTMaskHasType(mask, DBgetTileType(tp)) && tp->ti_client == client
		&& (*func)(tp, arg))
	    return (1);

	tpnew = TR(tp);
	if (LEFT(tpnew) < rect->r_xtop)
	{
	    while (BOTTOM(tpnew) >= rect->r_ytop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tp) > rect->r_xbot)
	{
	    if (BOTTOM(tp) <= rect->r_ybot)
		return (0);
	    tpnew = LB(tp);
	    tp = BL(tp);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* At left edge -- walk down to next tile along the left edge */
	for (tp = LB(tp); RIGHT(tp) <= rect->r_xbot; tp = TR(tp))
	    /* Nothing */;
    }
    return (0);
}
