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
 * tile1.c --
 *
 * Basic tile plane manipulation
 * (painting, for example, is built on top of this see DBpaint.c) 
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

#ifndef	lint
static char rcsid[] = "$Header: tile.c,v 6.0 90/08/28 18:02:49 mayo Exp $";
#endif	not lint

#include <stdio.h>
#include "magic.h"
#include "malloc.h"
#include "geometry.h"
#include "tile.h"

/*
 * Rectangle that defines the maximum extent of any plane.
 * No tile created by the user should ever extend outside of
 * this area.
 */

global Rect TiPlaneRect = { PLANE_BOT, PLANE_BOT, PLANE_TOP, PLANE_TOP };
global RectFloat TiPlaneRectF = { PLANE_BOT, PLANE_BOT, PLANE_TOP, PLANE_TOP };

/* tile allocation */
Tile *TileFreeList = NULL;
int TilesAlloced = 0;
int TilesFreed = 0;

/* called by TiAlloc() when out of tiles */
void TileBlockMalloc(void)
{
  int i;
  Tile *block;

#define TILE_BLOCK_SIZE 1024
  MALLOC_TAG(Tile *, block, sizeof(Tile)*TILE_BLOCK_SIZE,"tiles"); 

  for(i=1;i<=TILE_BLOCK_SIZE;i++)
  {
    block->ti_client = (ClientData) TileFreeList;
    TileFreeList = block++;  
  }
}


/*
 * --------------------------------------------------------------------
 *
 * TiNewPlane --
 *
 * Allocate and initialize a new tile plane.
 *
 * Results:
 *	A newly allocated Plane with all corner stitches set
 *	appropriately.
 *
 * Side effects:
 *	Adjusts the corner stitches of the Tile supplied to
 *	point to the appropriate bounding tile in the newly
 *	created Plane.
 *
 * --------------------------------------------------------------------
 */

Plane *
TiNewPlane(ClientData body)
{
    Plane *newplane;
    Tile *tile;  /* initial tile */
    static Tile *infinityTile = (Tile *) NULL;

    MALLOC(Plane *, newplane, sizeof (Plane));
    newplane->pl_numAllocs = 0;
    newplane->pl_numFrees = 0;

    /* tiles at infinity */
    newplane->pl_top = TiAlloc(newplane);
    newplane->pl_right = TiAlloc(newplane);
    newplane->pl_bottom = TiAlloc(newplane);
    newplane->pl_left = TiAlloc(newplane);

    /* initial finite tile */
    tile = TiAlloc(newplane);
    TiSetBody(tile, body);
    TiSetGroups(tile, NULL); 
    LEFT(tile) = TiPlaneRect.r_xbot;
    BOTTOM(tile) = TiPlaneRect.r_ybot;

    /*
     * Since the lower left coordinates of the TR and RT
     * stitches of a tile are used to determine its upper right,
     * we must give the boundary tiles a meaningful TR and RT.
     * To make certain that these tiles don't have zero width
     * or height, we use a dummy tile at (INFINITY+1,INFINITY+1).
     */

    if (infinityTile == (Tile *) NULL)
    {
	infinityTile = TiAlloc(newplane);
	LEFT(infinityTile) = INFINITY+1;
	BOTTOM(infinityTile) = INFINITY+1;
    }

    RT(tile) = newplane->pl_top;
    TR(tile) = newplane->pl_right;
    LB(tile) = newplane->pl_bottom;
    BL(tile) = newplane->pl_left;


    LEFT(newplane->pl_bottom) = MINFINITY;
    BOTTOM(newplane->pl_bottom) = MINFINITY;
    RT(newplane->pl_bottom) = tile;
    TR(newplane->pl_bottom) = newplane->pl_right;
    LB(newplane->pl_bottom) = BADTILE;
    BL(newplane->pl_bottom) = newplane->pl_left;
    TiSetBody(newplane->pl_bottom, -1);

    LEFT(newplane->pl_top) = MINFINITY;
    BOTTOM(newplane->pl_top) = INFINITY;
    RT(newplane->pl_top) = infinityTile;
    TR(newplane->pl_top) = newplane->pl_right;
    LB(newplane->pl_top) = tile;
    BL(newplane->pl_top) = newplane->pl_left;
    TiSetBody(newplane->pl_top, -1);

    LEFT(newplane->pl_left) = MINFINITY;
    BOTTOM(newplane->pl_left) = MINFINITY;
    RT(newplane->pl_left) = newplane->pl_top;
    TR(newplane->pl_left) = tile;
    LB(newplane->pl_left) = newplane->pl_bottom;
    BL(newplane->pl_left) = BADTILE;
    TiSetBody(newplane->pl_left, -1);

    LEFT(newplane->pl_right) = INFINITY;
    BOTTOM(newplane->pl_right) = MINFINITY;
    RT(newplane->pl_right) = newplane->pl_top;
    TR(newplane->pl_right) = infinityTile;
    LB(newplane->pl_right) = newplane->pl_bottom;
    BL(newplane->pl_right) = tile;
    TiSetBody(newplane->pl_right, -1);

    newplane->pl_hint = tile;
    return (newplane);
}

/*
 * --------------------------------------------------------------------
 *
 * TiFreePlane --
 *
 * Free the storage associated with a tile plane.
 * Only the plane itself and its four border tiles are deallocated.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Frees memory.
 *
 * --------------------------------------------------------------------
 */

void
TiFreePlane(Plane *plane)
                 	/* Plane to be freed */
{
    TiFree(plane->pl_left, plane);
    TiFree(plane->pl_right, plane);
    TiFree(plane->pl_top, plane);
    TiFree(plane->pl_bottom, plane);
    FREE((char *) plane);
}

/*
 * --------------------------------------------------------------------
 *
 * TiToRect --
 *
 * Convert a tile to a rectangle.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets *rect to the bounding box for the supplied tile.
 *
 * --------------------------------------------------------------------
 */

void
TiToRect(register Tile *tile, register Rect *rect)
                         /* Tile whose bounding box is to be stored in *rect */
                         /* Pointer to rect to be set to bounding box */
{
    rect->r_xbot = LEFT(tile);
    rect->r_xtop = RIGHT(tile);
    rect->r_ybot = BOTTOM(tile);
    rect->r_ytop = TOP(tile);
}


/*
 * --------------------------------------------------------------------
 *
 * TiSplitY --
 *
 * Given a tile and a Y coordinate, split the tile into two
 * along a horizontal line running through the given coordinate.
 *
 * Results:
 *	Returns the new tile resulting from the splitting, which
 *	is the tile occupying the top half of the original
 *	tile.
 *
 * Side effects:
 *	Modifies the corner stitches in the database to reflect
 *	the presence of two tiles in place of the original one.
 *
 * --------------------------------------------------------------------
 */

Tile *
TiSplitY(register Tile *tile, 
	                       /* Tile to be split */
	 register int y, 
                   		/* Y coordinate of split */
	 Plane *plane)
         

{
    register Tile *newtile;
    register Tile *tp;

    ASSERT(y > BOTTOM(tile) && y < TOP(tile), "TiSplitY");

    newtile = TiAlloc(plane);
    newtile->ti_client = (ClientData) MINFINITY;

    LEFT(newtile) = LEFT(tile);
    BOTTOM(newtile) = y;
    LB(newtile) = tile;
    RT(newtile) = RT(tile);
    TR(newtile) = TR(tile);

    /*
     * Adjust corner stitches along top edge
     */

    for (tp = RT(tile); LB(tp) == tile; tp = BL(tp))
	LB(tp) = newtile;
    RT(tile) = newtile;

    /*
     * Adjust corner stitches along right edge
     */

    for (tp = TR(tile); BOTTOM(tp) >= y; tp = LB(tp))
	BL(tp) = newtile;
    TR(tile) = tp;

    /*
     * Adjust corner stitches along left edge
     */

    for (tp = BL(tile); TOP(tp) <= y; tp = RT(tp))
	/* nothing */;
    BL(newtile) = tp;
    while (TR(tp) == tile)
    {
	TR(tp) = newtile;
	tp = RT(tp);
    }

    return (newtile);
}

/*
 * --------------------------------------------------------------------
 *
 * TiSplitX_Left --
 *
 * Given a tile and an X coordinate, split the tile into two
 * along a line running vertically through the given coordinate.
 * Intended for use when plowing to the left.
 *
 * Results:
 *	Returns the new tile resulting from the splitting, which
 *	is the tile occupying the left-hand half of the original
 *	tile.
 *
 * Side effects:
 *	Modifies the corner stitches in the database to reflect
 *	the presence of two tiles in place of the original one.
 *
 * --------------------------------------------------------------------
 */

Tile *
TiSplitX_Left(register Tile *tile, 
                        	/* Tile to be split */
	      register int x,
                   		/* X coordinate of split */
	      Plane *plane)
{
    register Tile *newtile;
    register Tile *tp;

    ASSERT(x > LEFT(tile) && x < RIGHT(tile), "TiSplitX");

    newtile = TiAlloc(plane);
    newtile->ti_client = (ClientData) MINFINITY;

    LEFT(newtile) = LEFT(tile);
    LEFT(tile) = x;
    BOTTOM(newtile) = BOTTOM(tile);

    BL(newtile) = BL(tile);
    LB(newtile) = LB(tile);
    TR(newtile) = tile;
    BL(tile) = newtile;

    /* Adjust corner stitches along the left edge */
    for (tp = BL(newtile); TR(tp) == tile; tp = RT(tp))
	TR(tp) = newtile;

    /* Adjust corner stitches along the top edge */
    for (tp = RT(tile); LEFT(tp) >= x; tp = BL(tp))
	/* nothing */;
    RT(newtile) = tp;
    for ( ; LB(tp) == tile; tp = BL(tp))
	LB(tp) = newtile;

    /* Adjust corner stitches along the bottom edge */
    for (tp = LB(tile); RIGHT(tp) <= x; tp = TR(tp))
	RT(tp) = newtile;
    LB(tile) = tp;

    return (newtile);
}

/*
 * --------------------------------------------------------------------
 *
 * TiSplitY_Bottom --
 *
 * Given a tile and a Y coordinate, split the tile into two
 * along a horizontal line running through the given coordinate.
 * Used when plowing down.
 *
 * Results:
 *	Returns the new tile resulting from the splitting, which
 *	is the tile occupying the bottom half of the original
 *	tile.
 *
 * Side effects:
 *	Modifies the corner stitches in the database to reflect
 *	the presence of two tiles in place of the original one.
 *
 * --------------------------------------------------------------------
 */

Tile *
TiSplitY_Bottom(register Tile *tile, 
                        	/* Tile to be split */
		register int y,
                   		/* Y coordinate of split */
		Plane *plane)
{
    register Tile *newtile;
    register Tile *tp;

    ASSERT(y > BOTTOM(tile) && y < TOP(tile), "TiSplitY");

    newtile = TiAlloc(plane);
    newtile->ti_client = (ClientData) MINFINITY;

    LEFT(newtile) = LEFT(tile);
    BOTTOM(newtile) = BOTTOM(tile);
    BOTTOM(tile) = y;

    RT(newtile) = tile;
    LB(newtile) = LB(tile);
    BL(newtile) = BL(tile);
    LB(tile) = newtile;

    /* Adjust corner stitches along bottom edge */
    for (tp = LB(newtile); RT(tp) == tile; tp = TR(tp))
	RT(tp) = newtile;

    /* Adjust corner stitches along right edge */
    for (tp = TR(tile); BOTTOM(tp) >= y; tp = LB(tp))
	/* nothing */;
    TR(newtile) = tp;
    for ( ; BL(tp) == tile; tp = LB(tp))
	BL(tp) = newtile;

    /* Adjust corner stitches along left edge */
    for (tp = BL(tile); TOP(tp) <= y; tp = RT(tp))
	TR(tp) = newtile;
    BL(tile) = tp;

    return (newtile);
}

/*
 * --------------------------------------------------------------------
 *
 * TiJoinX --
 *
 * Given two tiles sharing an entire common vertical edge, replace
 * them with a single tile occupying the union of their areas.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The first tile is simply relinked to reflect its new size.
 *	The second tile is deallocated.  Corner stitches in the
 *	neighboring tiles are updated to reflect the new structure.
 *	If the hint tile pointer in the supplied plane pointed to
 *	the second tile, it is adjusted to point instead to the
 *	first.
 *
 * --------------------------------------------------------------------
 */

void
TiJoinX(Tile *tile1, 
                	/* First tile, remains allocated after call */
	Tile *tile2, 
                	/* Second tile, deallocated by call */
	Plane *plane)
                 	/* Plane in which hint tile is updated */
{
    Tile *tp;

    /*
     * Basic algorithm:
     *
     *	Update all the corner stitches in the neighbors of tile2
     *	to point to tile1.
     *	Update the corner stitches of tile1 along the shared edge
     *	to be those of tile2.
     *	Change the bottom or left coordinate of tile1 if appropriate.
     *	Deallocate tile2.
     */

    ASSERT(BOTTOM(tile1)==BOTTOM(tile2) && TOP(tile1)==TOP(tile2), "TiJoinX");
    ASSERT(LEFT(tile1)==RIGHT(tile2) || RIGHT(tile1)==LEFT(tile2), "TiJoinX");

    /*
     * Update stitches along top of tile
     */

    for (tp = RT(tile2); LB(tp) == tile2; tp = BL(tp))
	LB(tp) = tile1;

    /*
     * Update stitches along bottom of tile
     */

    for (tp = LB(tile2); RT(tp) == tile2; tp = TR(tp))
	RT(tp) = tile1;

    /*
     * Update stitches along either left or right, depending
     * on relative position of the two tiles.
     */

    ASSERT(LEFT(tile1) != LEFT(tile2), "TiJoinX");
    if (LEFT(tile1) < LEFT(tile2))
    {
	for (tp = TR(tile2); BL(tp) == tile2; tp = LB(tp))
	    BL(tp) = tile1;
	TR(tile1) = TR(tile2);
	RT(tile1) = RT(tile2);
    }
    else
    {
	for (tp = BL(tile2); TR(tp) == tile2; tp = RT(tp))
	    TR(tp) = tile1;
	BL(tile1) = BL(tile2);
	LB(tile1) = LB(tile2);
	LEFT(tile1) = LEFT(tile2);
    }

    if (plane->pl_hint == tile2) plane->pl_hint = tile1;
    TiFree(tile2,plane);
}

/*
 * --------------------------------------------------------------------
 *
 * TiJoinY --
 *
 * Given two tiles sharing an entire common horizontal edge, replace
 * them with a single tile occupying the union of their areas.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The first tile is simply relinked to reflect its new size.
 *	The second tile is deallocated.  Corner stitches in the
 *	neighboring tiles are updated to reflect the new structure.
 *	If the hint tile pointer in the supplied plane pointed to
 *	the second tile, it is adjusted to point instead to the
 *	first.
 *
 * --------------------------------------------------------------------
 */

void
TiJoinY(Tile *tile1, 
                	/* First tile, remains allocated after call */
	Tile *tile2, 
                	/* Second tile, deallocated by call */
	Plane *plane)
                 	/* Plane in which hint tile is updated */
{
    Tile *tp;

    /*
     * Basic algorithm:
     *
     *	Update all the corner stitches in the neighbors of tile2
     *	to point to tile1.
     *	Update the corner stitches of tile1 along the shared edge
     *	to be those of tile2.
     *	Change the bottom or left coordinate of tile1 if appropriate.
     *	Deallocate tile2.
     */

    ASSERT(LEFT(tile1)==LEFT(tile2) && RIGHT(tile1)==RIGHT(tile2), "TiJoinY");
    ASSERT(TOP(tile1)==BOTTOM(tile2) || BOTTOM(tile1)==TOP(tile2), "TiJoinY");

    /*
     * Update stitches along right of tile.
     */

    for (tp = TR(tile2); BL(tp) == tile2; tp = LB(tp))
	BL(tp) = tile1;

    /*
     * Update stitches along left of tile.
     */

    for (tp = BL(tile2); TR(tp) == tile2; tp = RT(tp))
	TR(tp) = tile1;

    /*
     * Update stitches along either top or bottom, depending
     * on relative position of the two tiles.
     */

    ASSERT(BOTTOM(tile1) != BOTTOM(tile2), "TiJoinY");
    if (BOTTOM(tile1) < BOTTOM(tile2))
    {
	for (tp = RT(tile2); LB(tp) == tile2; tp = BL(tp))
	    LB(tp) = tile1;
	RT(tile1) = RT(tile2);
	TR(tile1) = TR(tile2);
    }
    else
    {
	for (tp = LB(tile2); RT(tp) == tile2; tp = TR(tp))
	    RT(tp) = tile1;
	LB(tile1) = LB(tile2);
	BL(tile1) = BL(tile2);
	BOTTOM(tile1) = BOTTOM(tile2);
    }

    if (plane->pl_hint == tile2) plane->pl_hint = tile1;
    TiFree(tile2,plane);
}


/*
 * --------------------------------------------------------------------
 *
 * TiSrPoint --
 *
 * Search for a point.
 *
 * Results:
 *	A pointer to the tile containing the point.
 *	The bottom and left edge of a tile are considered part of
 *	the tile; the top and right edge are not.
 *
 * Side effects:
 *	Updates the hint tile in the supplied plane to point
 *	to the tile found.
 *
 * --------------------------------------------------------------------
 */

Tile *
TiSrPoint(Tile *hintTile, 
                    		/* Pointer to tile at which to begin search.
				 * If this is NULL, use the hint tile stored
				 * with the plane instead.
				 */
	  Plane *plane, 
                  		/* Plane (containing hint tile pointer) */
	  register Point *point)
                           	/* Point for which to search */
{
    register Tile *tp = (hintTile) ? hintTile : plane->pl_hint;

    GOTOPOINT(tp, point);
    plane->pl_hint = tp;
    return(tp);
}
