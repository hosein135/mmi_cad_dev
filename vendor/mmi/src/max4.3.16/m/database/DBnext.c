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
 * DBnext.c --
 *
 * Routines for navigating through database by looking for the next edge
 * or the next width change while moving in a given direction.
 *
 */

#include <stdio.h>
#include "magic.h"
#include "main.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "memory.h"
#include "geometry.h"
#include "debug.h"


/* ----------------------------------------------------------------------------
 *
 * DBNextEdge --
 *
 * Find next edge in given direction.
 *
 * Results:
 *	pointer to statically allocated point of intersection between ray from 
 *      starting point in given direction and the edge that was found.
 *
 *      NULL if no edge found.
 *
 * NOTE:  boundary conditions handled carefully to make code using this
 *        routine direction independent.  e.g. we hide which edges are contained
 *        in a tile from caller.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func */
static Tile *dbNextEdgeNorth(Tile *tStart, Point *start, int limit)
{
  TileType type= DBgetTileType(tStart); 
  Tile *tp = tStart;

  while (BOTTOM(tp) <= limit &&
	TiGetBody(tp) != (ClientData)-1 && 
	DBgetTileType(tp) == type) 
  {
    NEXT_TILE_UP(tp, tp, start->p_x);
  }
  return tp;
}

/* helper func */
static Tile *dbNextEdgeSouth(Tile *tStart, Point *start, int limit)
{
  TileType type=DBgetTileType(tStart); 
  Tile *tp = tStart;
  
  while(TOP(tp) >= limit &&
	TiGetBody(tp)!=(ClientData) -1 && 
	DBgetTileType(tp)==type) 
  {
    NEXT_TILE_DOWN(tp, tp, start->p_x);
  }
  return tp;
}

/* helper func */
static Tile *dbNextEdgeEast(Tile *tStart, Point *start, int limit)
{
  TileType type=DBgetTileType(tStart); 
  Tile *tp = tStart;
  
  while(LEFT(tp) <= limit &&
	TiGetBody(tp)!=(ClientData) -1 && 
	DBgetTileType(tp)==type) 
  {
    NEXT_TILE_RIGHT(tp, tp, start->p_y);
  }
  return tp;
}

/* helper func */
static Tile *dbNextEdgeWest(Tile *tStart, Point *start, int limit)
{
  TileType type=DBgetTileType(tStart); 
  Tile *tp = tStart;
  
  while(RIGHT(tp) >= limit &&
	TiGetBody(tp)!=(ClientData) -1 && 
	DBgetTileType(tp)==type) 
  {
    NEXT_TILE_LEFT(tp, tp, start->p_y);
  }
  return tp;

}

Point 
DBNextEdge(Plane *plane,	/* plane to search */
	   Point *point,	/* starting point */
	   int direction,	/* direction to search */
           int maxd)		/* if not 0, maximum distance 
				 * to search for next edge 
				 */
{
  Point start = *point;
  static Point result;
  Tile *tStart;
  Tile *tNext, tNext1, tNext2;
  Tile *tp;

  switch(direction)
  {
    case GEO_NORTH:
    {
      Tile *tStart, *tNext1, *tNext2;
      int limit = maxd ? point->p_y+maxd : PLANE_TOP;

      tStart = TiSrPoint(NULL, plane, &start);
      tNext1 = dbNextEdgeNorth(tStart, &start, limit);

      /* also search one unit to left to catch tiles "ending" here */
      start.p_x--;
      tStart = TiSrPoint(NULL, plane, &start);
      tNext2 = dbNextEdgeNorth(tStart, &start, limit);

      result.p_x = point->p_x; 
      result.p_y = MIN(BOTTOM(tNext1), BOTTOM(tNext2));
      result.p_y = MIN(result.p_y, limit);
    }
    break;

    case GEO_SOUTH:
    {
      Tile *tStart, *tNext1, *tNext2;
      int limit = maxd ? point->p_y-maxd : PLANE_BOT;

      start.p_y--;
      tStart = TiSrPoint(NULL, plane, &start);
      tNext1 = dbNextEdgeSouth(tStart, &start, limit);

      /* also search one unit to left to catch tiles "ending" here */
      start.p_x--;
      tStart = TiSrPoint(NULL, plane, &start);
      tNext2 = dbNextEdgeSouth(tStart, &start, limit);

      result.p_x = point->p_x;
      result.p_y = MAX(TOP(tNext1), TOP(tNext2));
      result.p_y = MAX(result.p_y, limit);
    }
    break;

    case GEO_EAST:
    {
      Tile *tStart, *tNext1, *tNext2;
      int limit = maxd ? point->p_x+maxd : PLANE_TOP;

      tStart = TiSrPoint(NULL, plane, &start);
      tNext1 = dbNextEdgeEast(tStart, &start, limit);

      /* also search one unit down to catch tiles "ending" here */
      start.p_y--;
      tStart = TiSrPoint(NULL, plane, &start);
      tNext2 = dbNextEdgeEast(tStart, &start, limit);

      result.p_y = point->p_y;
      result.p_x = MIN(LEFT(tNext1), LEFT(tNext2));
      result.p_x = MIN(result.p_x, limit);
    }
    break;

    case GEO_WEST:
    {
      Tile *tStart, *tNext1, *tNext2;
      int limit = maxd ? point->p_x-maxd : PLANE_BOT;

      start.p_x--;
      tStart = TiSrPoint(NULL, plane, &start);
      tNext1 = dbNextEdgeWest(tStart, &start, limit);

      /* also search one unit down to catch tiles "ending" here */
      start.p_y--;
      tStart = TiSrPoint(NULL, plane, &start);
      tNext2 = dbNextEdgeWest(tStart, &start, limit);

      result.p_y = point->p_y;
      result.p_x = MAX(RIGHT(tNext1), RIGHT(tNext2));
      result.p_x = MAX(result.p_x, limit);
    }
    break;

    default:  ASSERT(FALSE,"DBNextEdge:  bad direction\n");
  }
      
  return result;
}


/* ----------------------------------------------------------------------------
 *
 * DBNextDistance --
 *
 * Find next point in given direction where distance to either
 * edge moving in the same direction changes.
 * For example, if direction is north, watch east and west edges,
 * return first point where either changes.
 * This is equivalent to looking for an edge anywhere in the
 * specified area.
 *
 * The edge returned is always at least one unit beyond the initial point,
 * ie, edge exactly at initial point is ignored.
 *
 * Results:
 *	Final point.
 *	If no edge is found, the final point will either be
 *	at infinity, or beyond the specified area, if any.
 *
 * NOTE:  boundary conditions handled carefully.
 *        If the routine returns a point at the edge of area,
 *        it indicates that there was actually an edge there.
 *
 * ----------------------------------------------------------------------------
 */


Point 
DBNextDistance(Plane *plane,	/* plane to search	*/
	       Point *startp,	/* starting point	*/
	       int direction,	/* direction to search	*/
	       Rect *area,      /* if not NULL, only search inside */
	       Point *unused)    /* if non-zero, set to 1 iff edge change found */
{
    Tile *home_tile;
    TileType home_type;
    Tile *some_tile;	/* along search path		*/
    Tile *previous_tile;
    int some_edge, r_edge, l_edge;
    Point newp;
    Point retval;
    Point n_retval, s_retval;
    int check_line;
    Rect limit;		/* boundaries of area to search */
    Rect ref;		/* left/right reference edges; y coords unused. */

    if (area) {
	limit = *area;
    } else {
	limit = TiPlaneRect;
    }

    /* If our starting point is exactly on an edge, we want to ignore it.
     * Set newp to a point that is in the next tile if we right on the edge.
     * Since tiles include the south and west edges, we need to decrement
     * it in those two cases only.
     * For the other edges, TiSrPoint will already return the next tile
     * if on an edge.
     */
    newp = *startp;
    if (direction == GEO_SOUTH) { newp.p_y--; }
    else if (direction == GEO_WEST) { newp.p_x--; }
    home_tile = TiSrPoint(NULL,plane,&newp);
    home_type = DBgetTileType(home_tile);

    /* Left/right ref edges are the edges we want to watch. */
    ref.r_xbot = LEFT(home_tile); 
    ref.r_xtop = RIGHT(home_tile);

    /* Clip left/right references edges to lie within limit rectangle.
     */
    if (ref.r_xbot < limit.r_xbot) ref.r_xbot = limit.r_xbot;
    if (ref.r_xtop > limit.r_xtop) ref.r_xtop = limit.r_xtop;

    switch (direction) {

	case GEO_NORTH: {

	    /* now, checking each tile as we go up.... 
	     * we are done when:
	     *	maxd is exceeded
	     *	Clientdata == -1 (have left The World)
	     *   (from pat: dont think this is possible because of limit)
	     *	the type changes
	     *	or (BTW) the distance changes....
	     */
	    retval.p_x = startp->p_x;

	    some_tile = previous_tile = home_tile;
	    while (TOP(some_tile) < limit.r_ytop &&
		TiGetBody(some_tile) != (ClientData)-1 &&
		DBgetTileType(some_tile) == home_type) {

		r_edge = MIN(RIGHT(some_tile),limit.r_xtop);
		l_edge = MAX(LEFT(some_tile),limit.r_xbot);
		if (r_edge != ref.r_xtop || l_edge != ref.r_xbot) {
		    break;
		}
	
		previous_tile = some_tile;
		NEXT_TILE_UP(some_tile, some_tile, startp->p_x);
	    }

	    retval.p_y = TOP(previous_tile);

	} break;


	case GEO_SOUTH: {
	    retval.p_x = startp->p_x;

	    some_tile = previous_tile = home_tile;
	    while (BOTTOM(some_tile) > limit.r_ybot &&
		TiGetBody(some_tile) != (ClientData)-1 &&
		DBgetTileType(some_tile) == home_type) {

		r_edge = MIN(RIGHT(some_tile),limit.r_xtop);
		l_edge = MAX(LEFT(some_tile),limit.r_xbot);
		if (r_edge != ref.r_xtop || l_edge != ref.r_xbot) {
		    break;
		}
	
		previous_tile = some_tile;
		NEXT_TILE_DOWN(some_tile, some_tile, startp->p_x);
	    }

	    retval.p_y = BOTTOM(previous_tile);

	} break;

	case GEO_EAST: {
	    /* Taking advantage of the tile-ish nature of things,
	     * we still want to traverse NORTH or SOUTH, depending
	     * this time on which way we are looking.
	     * If there is a stack of same-type tiles immediately
	     * NORTH (...etc. for S) of the start point, then the 
	     * distance will narrow at the bottom of the tile with 
	     * the closest EASTERN boundry in the stack.
	     * Then we still have to worry about the distance getting
	     * WIDER within this range, as it will if, on top of the
	     * stack, immediately N there is a tile of a different
	     * type, but somewhere EAST of there is a tile of the
	     * same type; in which case the next distance is at the
	     * the WEST edge of the matching tile.
	     * .... the simple example of this last is a cross,
	     * with the starting point in the western arm.
	     */ 

	    /* It's annoying to have four distinct cases that share
	     * so much code.... (NORTH | SOUTH) X (right | left)...
	     * ... but it's less ugly than combining them with a bunch
	     * of direction switches...
	     */

	    /* looking LEFT ... traversing NORTH ... */
	    n_retval.p_x = ref.r_xtop + 1;
	    n_retval.p_y = startp->p_y;

	    some_tile = home_tile;
	    while (TOP(some_tile) <= limit.r_ytop &&
		TiGetBody(some_tile) != (ClientData)-1 &&
		DBgetTileType(some_tile) == home_type) {

		some_edge = RIGHT(some_tile);
		if (some_edge != startp->p_x && some_edge < n_retval.p_x) {
		    n_retval.p_x = some_edge;
		}

		NEXT_TILE_UP(some_tile, some_tile, newp.p_x);
	    }

	    check_line = BOTTOM(some_tile);  /* bottom edge is in the tile */
	    if (check_line < limit.r_ytop) while (1) {
		NEXT_TILE_RIGHT(some_tile, some_tile, check_line);
		some_edge = LEFT(some_tile);
		if (TiGetBody(some_tile) == (ClientData)-1 ||
		    some_edge >= n_retval.p_x) {
			break;
		}

		if (DBgetTileType(some_tile) == home_type &&
		    some_edge != startp->p_x) {
		    n_retval.p_x = some_edge;
		    break;
		}
	    }

	    /* looking RIGHT ... traversing SOUTH ... */
	    s_retval.p_x = ref.r_xtop + 1;
	    s_retval.p_y = startp->p_y;

	    /* ... find narrowest place in the stack ... */
	    some_tile = home_tile;
	    while (BOTTOM(some_tile) >= limit.r_ybot &&
	    TiGetBody(some_tile) != (ClientData)-1 &&
	    DBgetTileType(some_tile) == home_type) {

		some_edge = RIGHT(some_tile);
		if (some_edge != startp->p_x && some_edge < s_retval.p_x) {
		    s_retval.p_x = some_edge;
		}

		NEXT_TILE_DOWN(some_tile, some_tile, newp.p_x);
	    }

	    /* ... now slide along eastwards looking for widening place ... */
	    check_line = TOP(some_tile) - 1;  /* top edge is not in the tile */
	    if (check_line >= limit.r_ybot) while (1) {
		NEXT_TILE_RIGHT(some_tile, some_tile, check_line);
		some_edge = LEFT(some_tile);
		if (TiGetBody(some_tile) == (ClientData)-1 ||
		    some_edge >= s_retval.p_x) {
		    /* we have gone past the interesting area 
		     * ... there is no widening.
		     */
		    break;
		}

		if (DBgetTileType(some_tile) == home_type &&
		    some_edge != startp->p_x) {
		    /* here is a widening place!
		     * ... get the new distance.
		     */
		    s_retval.p_x = some_edge;
		    break;
		}
	    }


	    /* ... which do we want?  north or south? */
	    if (s_retval.p_x <= n_retval.p_x) {
		    retval = s_retval;
	    } else {
		    retval = n_retval;
	    }
	} break;

	case GEO_WEST: {
	    /* see comments for case GEO_EAST */

	    /* looking RIGHT ... traversing NORTH ... */
	    n_retval.p_x = ref.r_xbot - 1;
	    n_retval.p_y = startp->p_y;

	    some_tile = home_tile;
	    while (TOP(some_tile) <= limit.r_ytop &&
		TiGetBody(some_tile) != (ClientData)-1 &&
		DBgetTileType(some_tile) == home_type) {

		some_edge = LEFT(some_tile);
		if (some_edge != startp->p_x && some_edge > n_retval.p_x) {
		    n_retval.p_x = some_edge;
		}		

		NEXT_TILE_UP(some_tile, some_tile, newp.p_x);
	    }

	    check_line = BOTTOM(some_tile);  /* bottom edge is in the tile */
	    if (check_line < limit.r_ytop) while (1) {
		NEXT_TILE_LEFT(some_tile, some_tile, check_line);
		some_edge = RIGHT(some_tile);
		if (TiGetBody(some_tile) == (ClientData)-1 ||
		    some_edge <= n_retval.p_x) {
		    break;
		} 

		if (DBgetTileType(some_tile) == home_type &&
		    some_edge != startp->p_x) {
		    n_retval.p_x = some_edge;
		    break;
		}
	    }

	    /* looking LEFT ... traversing SOUTH ... */
	    s_retval.p_x = ref.r_xbot - 1;
	    s_retval.p_y = startp->p_y;

	    some_tile = home_tile;
	    while (BOTTOM(some_tile) >= limit.r_ybot &&
		TiGetBody(some_tile) != (ClientData)-1 &&
		DBgetTileType(some_tile) == home_type) {

		some_edge = LEFT(some_tile);
		if (some_edge != startp->p_x && some_edge > s_retval.p_x) {
		    s_retval.p_x = some_edge;
		}

		NEXT_TILE_DOWN(some_tile, some_tile, newp.p_x);
	    }

	    check_line = TOP(some_tile) - 1;  /* top edge is not in the tile */
	    if (check_line >= limit.r_ybot) while (1) {
		NEXT_TILE_LEFT(some_tile, some_tile, check_line);
		some_edge = RIGHT(some_tile);
		if (TiGetBody(some_tile) == (ClientData)-1 ||
		    some_edge <= s_retval.p_x) {
		    break;
		} 

		if (DBgetTileType(some_tile) == home_type &&
		    some_edge != startp->p_x) {
		    s_retval.p_x = some_edge;
		    break;
		}
	    }

	    if (n_retval.p_x >= s_retval.p_x) {
		    retval = n_retval;
	    } else {
		    retval = s_retval;
	    }
	} break;
    }


    /*
     * printf("dbnext limit=%d,%d,%d,%d p=%d,%d r=%d,%d\n",
     *	limit.r_xbot,limit.r_ybot,limit.r_xtop,limit.r_ytop,
     *	startp->p_x,startp->p_y,retval.p_x,retval.p_y);
     */

    return retval;
}


			

/* ----------------------------------------------------------------------------
 *
 * DBNextEdgeH --
 *
 * Find next edge in given direction.
 * Like DBNextEdge(), but hierarchical (looks at instances)
 *
 * Results:
 *	point of intersection between ray from 
 *      starting point in given direction and the edge that was found.
 *
 *      NULL if no edge found.
 *
 * NOTE:  boundary conditions handled carefully to make code using this
 *        routine direction independent.  e.g. we hide which edges are contained
 *        in a tile from caller.
 *
 * ----------------------------------------------------------------------------
 */

/* helper function for DBNextEdgeH() and DBNextDistanceH()
 * paints tiles into private plane.
 */
static int dbNextEdgeHFunc(Tile *tile, TreeContext *cxp)
{
  SearchContext *scx = cxp->tc_scx;
  Plane *plane = (Plane *) cxp->tc_filter->tf_arg;
  TileType type = DBgetTileType(tile);
  Rect srcRect, destRect;

  /* Construct the rect for the tile in source coordinates */
  TITORECT(tile, &srcRect);

  /* Transform to target coordinates */
  GEOTRANSRECT(&scx->scx_trans, &srcRect, &destRect);

  /* paint rect into plane */
  DBPaintPlane(plane, 
	       &destRect, 
	       DBStdPaintTbl(type,DBPlane(type)), 
	       NULL);

  /* continue search */
  return 0;
}

Point  
DBNextEdgeH(CellUse *use, 
          	/* Pointer to toplevel cell for search */
	   TileType type, 
	        /* layer to search */
	   Point *point, 
	        /* starting point */
	   int direction,
	        /* direction to search */
           int maxd,
                /* if not 0, maximum distance to search for next edge */
	   int xMask)
                /* expansion mask, 0 to search all subcells */ 
{
  Rect area;
  Rect area2;
  int  planeNum;
  Plane *plane;
  Point result;

  /* figure out area user wants searched */
  area = TiPlaneRect;
  switch(direction)
    {
    case GEO_NORTH:
      {
	area.r_xbot = MAX(area.r_xbot, point->p_x - 1);
	area.r_xtop = MIN(area.r_xtop, point->p_x + 1);
	area.r_ybot = MAX(area.r_ybot, point->p_y - 1);
	if(maxd) area.r_ytop = MIN(area.r_ytop, point->p_y + maxd + 1);
      }
      break;
      
    case GEO_SOUTH:
      {
	area.r_xbot = MAX(area.r_xbot, point->p_x - 1);
	area.r_xtop = MIN(area.r_xtop, point->p_x + 1);
	if(maxd) area.r_ybot = MAX(area.r_ybot, point->p_y - maxd - 1);
	area.r_ytop = MIN(area.r_ytop, point->p_y + 1);
      }
      break;

    case GEO_EAST:
      {
	area.r_ybot = MAX(area.r_ybot, point->p_y - 1);
	area.r_ytop = MIN(area.r_ytop, point->p_y + 1);
	area.r_xbot = MAX(area.r_xbot, point->p_x - 1);
	if(maxd) area.r_xtop = MIN(area.r_xtop, point->p_x + maxd + 1);
      }
      break;

    case GEO_WEST:
      {
	area.r_ybot = MAX(area.r_ybot, point->p_y - 1);
	area.r_ytop = MIN(area.r_ytop, point->p_y + 1);
	if(maxd) area.r_xbot = MAX(area.r_xbot, point->p_x - maxd - 1);
	area.r_xtop = MIN(area.r_xtop, point->p_x + 1);
      }
      break;

    default:  ASSERT(FALSE,"DBNextEdgeH:  bad direction\n");
    }

  /* adjust actual area yanked/searched */
  area2 = area;
  {
    Rect *bbox = DBBBoxCellDef(use->cu_def);
    GEOCLIP(&area2,bbox);
  }
 
  /* grow search area by 1 unit in all directions to avoid those nasty
   * boundary conditions.
   */
  if(area2.r_xbot > PLANE_BOT) area2.r_xbot -= 1;
  if(area2.r_xtop < PLANE_TOP) area2.r_xtop += 1;
  if(area2.r_ybot > PLANE_BOT) area2.r_ybot -= 1;
  if(area2.r_ytop < PLANE_TOP) area2.r_ytop += 1;
   
  /* yank area to plane and do "flat" next edge search on plane */
  {
    SearchContext scx;
    TileTypeBitMask mask;
    Plane *plane = DBPlaneNew((ClientData) TT_SPACE);

    /* set up search context for search */
    scx.scx_use = use;
    scx.scx_area = area2;
    scx.scx_trans = GeoIdentityTransform;

    /* setup layer mask */
    TTMaskZero(&mask);
    TTMaskSetType(&mask, type);

    /* "yank" area to plane */ 
    DBSearchPaintNew2(&scx, 
		      &mask, 
		      xMask,      
		      NULL,  /* terminal path */
		      dbNextEdgeHFunc, /* paint function */
		      NULL,  /* polygon func */
		      NULL,  /* wirepath func */
		      (ClientData) plane,
		      0);    /* flags */    

    /* now find the next edge! */
    result = DBNextEdge(plane,point,direction,maxd); 

    /* free plane */
    DBFreePaintPlane(plane);
    TiFreePlane(plane);
  }

  /* if result falls on edge of area, move to edge of original area */
  if(result.p_x <= area2.r_xbot) result.p_x = area.r_xbot;
  if(result.p_x >= area2.r_xtop) result.p_x = area.r_xtop;
  if(result.p_y <= area2.r_ybot) result.p_y = area.r_ybot;
  if(result.p_y >= area2.r_ytop) result.p_y = area.r_ytop;


  return result;
}


/* ----------------------------------------------------------------------------
 *
 * DBNextDistanceH --
 *
 * Find next point in given direction where distance to edge changes.
 * Like DBNextDistance(), but hierarchical (looks at instances)
 *
 * Results:
 *	new point.
 *
 * ----------------------------------------------------------------------------
 */
Point 
DBNextDistanceH(CellUse *use, 
          	  /* Pointer to toplevel cell for search; if NULL, 
		   * use edit cell
		   */
		TileType type, 	        /* layer to search */
		Point *point, 	        /* starting point */
		int direction,	        /* direction to search */
		Rect *argArea,
  		  /* if not NULL, only search inside this rectangle */
		int xMask)
                  /* expansion mask (0 to search all subcells) */
{
  Rect origArea;
  Rect area;
  Point result;
  SearchContext scx; 
  TileTypeBitMask mask;
  int planeNum;
  Plane *plane;

  origArea = argArea ? *argArea : TiPlaneRect;

  /* whittle down the search area as much as possible before yanking */
  area = origArea;
  switch(direction)
  {
    case GEO_NORTH:
    area.r_ybot = MAX(area.r_ybot, point->p_y - 1);
    break;
  
    case GEO_SOUTH:
    area.r_ytop = MIN(area.r_ytop, point->p_y + 1);
    break;
  
    case GEO_EAST:
    area.r_xbot = MAX(area.r_xbot, point->p_x - 1);
    break;
  
    case GEO_WEST:
    area.r_xtop = MIN(area.r_xtop, point->p_x + 1);
    break;
  
    default:  ASSERT(FALSE,"DBNextDistance:  bad direction\n");
  }
  {
    Rect *bbox = DBBBoxCellDef(use->cu_def);
    GEOCLIP(&area,bbox);
  }

  /* grow search area by 1 unit in all directions to avoid those nasty
   * boundary conditions.
   */
  area.r_xbot -= 1;
  area.r_xtop += 1;
  area.r_ybot -= 1;
  area.r_ytop += 1;
   
  /*** yank area to plane and do "flat" next distance search on plane ***/
  plane = DBPlaneNew((ClientData) TT_SPACE);

  /* set up search context for search */
  scx.scx_use = use;
  scx.scx_area = area;
  scx.scx_trans = GeoIdentityTransform;

  /* setup layer mask */
  TTMaskZero(&mask);
  TTMaskSetType(&mask, type);

  /* "yank" area to plane */ 
  DBSearchPaintNew2(&scx, 
		    &mask,           /* layers */
		    xMask,           /* expansion mask */
		    NULL,	     /* terminal path */
		    dbNextEdgeHFunc, /* paint func */
		    NULL,   /* polygon func */ 
		    NULL,   /* wirepath func */ 
		    (ClientData) plane,
		    0);     /* flags */ 

  /* now find the next distance! */
  result = DBNextDistance(plane,
			  point,
			  direction,
			  &area,
			  NULL); 

  /* free plane */
  DBFreePaintPlane(plane);
  TiFreePlane(plane);

  /* if result falls on edge of area, move to edge of original area */
  if(result.p_x <= area.r_xbot) result.p_x = origArea.r_xbot;
  if(result.p_x >= area.r_xtop) result.p_x = origArea.r_xtop;
  if(result.p_y <= area.r_ybot) result.p_y = origArea.r_ybot;
  if(result.p_y >= area.r_ytop) result.p_y = origArea.r_ytop;

  return result;
}








