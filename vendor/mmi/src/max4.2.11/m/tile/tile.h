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
 * tile.h --
 *
 * Definitions of the basic tile structures
 * The definitions in this file are all that is visible to
 * the Ti (tile) modules.
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
 *
 * Needs:
 *	magic.h
 *	geometry.h
 *
 * rcsid "$Header: tile.h,v 6.0 90/08/28 18:02:51 mayo Exp $"
 */

#ifndef _TILE
#define	_TILE

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC
#ifndef	_GEOMETRY
#include "geometry.h"
#endif	_GEOMETRY

/*
 * A tile is the basic unit used for representing both space and
 * solid area in a plane.  It has the following structure:
 *
 *				       RT
 *					^
 *					|
 *		-------------------------
 *		|			| ---> TR
 *		|			|
 *		|			|
 *		| (lower left)		|
 *	BL <--- -------------------------
 *		|
 *		v
 *	        LB
 *
 * The (x, y) coordinates of the lower left corner of the tile are stored,
 * along with four "corner stitches": RT, TR, BL, LB.
 *
 * Space tiles are distinguished at a higher level by having a distinguished
 * tile body.
 */

typedef struct tile
{
    ClientData	 ti_body;	/* Body of tile */
    ClientData	 ti_groups;	/* used by database module to implement groups */
    struct tile	*ti_lb;		/* Left bottom corner stitch */
    struct tile	*ti_bl;		/* Bottom left corner stitch */
    struct tile	*ti_tr;		/* Top right corner stitch */
    struct tile	*ti_rt;		/* Right top corner stitch */
    Point	 ti_ll;		/* Lower left coordinate */
    ClientData	 ti_client;	/* This space for hire.  Warning: the default
				 * value for this field, to which all users
				 * should return it when done, is MINFINITY
				 * instead of NULL.
				 */
} Tile;

    /*
     * The following macros make it appear as though both
     * the lower left and upper right coordinates of a tile
     * are stored inside it.
     */

#define	BOTTOM(tp)		((tp)->ti_ll.p_y)
#define	LEFT(tp)		((tp)->ti_ll.p_x)
#define	TOP(tp)			(BOTTOM(RT(tp)))
#define	RIGHT(tp)		(LEFT(TR(tp)))

#define	LB(tp)		((tp)->ti_lb)
#define	BL(tp)		((tp)->ti_bl)
#define	TR(tp)		((tp)->ti_tr)
#define	RT(tp)		((tp)->ti_rt)


/* ----------------------- Tile planes -------------------------------- */

/*
 * A plane of tiles consists of the four special tiles needed to
 * surround all internal tiles on all sides.  Logically, these
 * tiles appear as below, except for the fact that all are located
 * off at infinity.
 *
 *	 --------------------------------------
 *	 |\				     /|
 *	 | \				    / |
 *	 |  \		   TOP  	   /  |
 *	 |   \				  /   |
 *	 |    \				 /    |
 *	 |     --------------------------     |
 *	 |     |			|     |
 *	 |LEFT |			|RIGHT|
 *	 |     |			|     |
 *	 |     --------------------------     |
 *	 |    /				 \    |
 *	 |   /				  \   |
 *	 |  /		 BOTTOM 	   \  |
 *	 | /				    \ |
 *	 |/				     \|
 *	 --------------------------------------
 */

typedef struct
{
    double      pl_numAllocs;   /* number of tile allocs for plane */
    double      pl_numFrees;    /* number of tile frees for plane */
    Tile	*pl_left;	/* Left pseudo-tile */
    Tile	*pl_top;	/* Top pseudo-tile */
    Tile	*pl_right;	/* Right pseudo-tile */
    Tile	*pl_bottom;	/* Bottom pseudo-tile */
    Tile	*pl_hint;	/* Pointer to a "hint" at which to
				 * begin searching.
				 */
} Plane;

/*
 * The coordinates, INFINITY, and MINFINITY are used to represent 
 * tile location outside of the tile plane.
 *
 * The cordinates PLANE_BOT and PLANE_TOP are used to represent TiPlaneRect
 * the rectangle encompassing all of the tile plane.
 * 
 * It must be possible to represent INFINITY+1 as well as
 * INFINITY.
 *
 * NOTE that -INFINITY = MINFINITY and -PLANE_TOP = PLANE_BOT,
 *
 * Also, because locations involving INFINITY may be transformed,
 * it is desirable that additions and subtractions of small integers
 * from either INFINITY or MINFINITY not cause overflow.
 *
 * Consequently, we define INFINITY to be the largest integer
 * representable in wordsize - 5 bits.
 */

/* #define	INFINITY	((1 << (8*sizeof (int) - 6)) - 4) */
#define	INFINITY	((1 << (8*sizeof (int) - 3)) - 4) 
#define	MINFINITY	(-INFINITY)

#define PLANE_TOP       (INFINITY - 2)
#define PLANE_BOT       (-PLANE_TOP)

/* ------------------------ Flags, etc -------------------------------- */

#define	BADTILE		((Tile *) -1)	/* Invalid tile pointer */

/* ============== Function headers and external interface ============= */

/*
 * The following macros and procedures should be all that are
 * ever needed by modules other than the tile module.
 */

/* managing our own tile allocation saves about 20% space over-head */
extern void TileBlockMalloc(void);
extern Tile *TileFreeList;
extern int TilesAlloced, TilesFreed;
static __inline__ Tile *TiAlloc(Plane *plane) /* plane tile is being added to */
{ 
  Tile *ti;

  /*  TilesAlloced++; */
  plane->pl_numAllocs++;

  if(!TileFreeList) TileBlockMalloc();
  ti = TileFreeList;
  TileFreeList = (Tile *) ti->ti_client;
  return ti;
}

static __inline__ void TiFree(Tile *ti,
			      Plane *plane)  /* plane tile is being rmed from */
{
  /* TilesFreed++; */
  plane->pl_numFrees++;

  ti->ti_client =  (ClientData) TileFreeList;
  TileFreeList = ti;
}
 
extern Plane *TiNewPlane(ClientData body);
extern void TiFreePlane(Plane *plane);
extern void TiToRect(register Tile *tile, register Rect *rect);
 

/*
 * --------------------------------------------------------------------
 *
 * TiSplitX --
 *
 * Given a tile and an X coordinate, split the tile into two
 * along a line running vertically through the given coordinate.
 *
 * Results:
 *	Returns the new tile resulting from the splitting, which
 *	is the tile occupying the right-hand half of the original
 *	tile.
 * 
 * NOTE: in-lining seems to buy about 15% speedup of painting 
 *
 * Side effects:
 *	Modifies the corner stitches in the database to reflect
 *	the presence of two tiles in place of the original one.
 *
 * --------------------------------------------------------------------
 */

static __inline__ Tile *TiSplitX(register Tile *tile, /* Tile to be split */
				 register int x,      /* X coordinate of split */
				 Plane *plane)
{
    register Tile *newtile;
    register Tile *tp;

    ASSERT(x > LEFT(tile) && x < RIGHT(tile), "TiSplitX");

    newtile = TiAlloc(plane);
    newtile->ti_client = (ClientData) MINFINITY;

    LEFT(newtile) = x;
    BOTTOM(newtile) = BOTTOM(tile);
    BL(newtile) = tile;
    TR(newtile) = TR(tile);
    RT(newtile) = RT(tile);

    /*
     * Adjust corner stitches along the right edge
     */

    for (tp = TR(tile); BL(tp) == tile; tp = LB(tp))
	BL(tp) = newtile;
    TR(tile) = newtile;

    /*
     * Adjust corner stitches along the top edge
     */

    for (tp = RT(tile); LEFT(tp) >= x; tp = BL(tp))
	LB(tp) = newtile;
    RT(tile) = tp;

    /*
     * Adjust corner stitches along the bottom edge
     */

    for (tp = LB(tile); RIGHT(tp) <= x; tp = TR(tp))
	/* nothing */;
    LB(newtile) = tp;
    while (RT(tp) == tile)
    {
	RT(tp) = newtile;
	tp = TR(tp);
    }

    return (newtile);
}
extern Tile *TiSplitY(register Tile *tile, register int y, Plane *plane);
extern Tile *TiSplitX_Left(register Tile *tile, register int x, Plane *plane);
extern Tile *TiSplitY_Bottom(register Tile *tile, register int y, Plane *plane);
extern void  TiJoinX(Tile *tile1, Tile *tile2, Plane *plane);
extern void  TiJoinY(Tile *tile1, Tile *tile2, Plane *plane);
extern Tile *TiSrPoint(Tile *hintTile, Plane *plane, register Point *point);

#define	TiBottom(tp)		(BOTTOM(tp))
#define	TiLeft(tp)		(LEFT(tp))
#define	TiTop(tp)		(TOP(tp))
#define	TiRight(tp)		(RIGHT(tp))

#define	TiGetBody(tp)		((tp)->ti_body)
#define	TiSetBody(tp, b)	((tp)->ti_body = (ClientData) (b))
#define	TiGetGroups(tp)		((tp)->ti_groups)
#define	TiSetGroups(tp, b)	((tp)->ti_groups = (ClientData) (b))
#define	TiGetClient(tp)		((tp)->ti_client)
#define	TiSetClient(tp,b)	((tp)->ti_client = (ClientData) (b))

#define EnclosePoint(tile,point)	((LEFT(tile)   <= (point)->p_x ) && \
					 ((point)->p_x   <  RIGHT(tile)) && \
					 (BOTTOM(tile) <= (point)->p_y ) && \
					 ((point)->p_y   <  TOP(tile)  ))

#define EnclosePoint4Sides(tile,point)	((LEFT(tile)   <= (point)->p_x ) && \
					 ((point)->p_x  <=  RIGHT(tile)) && \
					 (BOTTOM(tile) <= (point)->p_y ) && \
					 ((point)->p_y  <=  TOP(tile)  ))

/* The four macros below are for finding next tile RIGHT, UP, LEFT or DOWN 
 * from current tile at a given coordinate value.
 *
 * For example, NEXT_TILE_RIGHT points tResult to tile to right of t 
 * at y-coordinate y.
 */

#define NEXT_TILE_RIGHT(tResult, t, y) \
    for ((tResult) = TR(t); BOTTOM(tResult) > (y); (tResult) = LB(tResult)) \
        /* Nothing */;

#define NEXT_TILE_UP(tResult, t, x) \
    for ((tResult) = RT(t); LEFT(tResult) > (x); (tResult) = BL(tResult)) \
        /* Nothing */;

#define NEXT_TILE_LEFT(tResult, t, y) \
    for ((tResult) = BL(t); TOP(tResult) <= (y); (tResult) = RT(tResult)) \
        /* Nothing */;
 
#define NEXT_TILE_DOWN(tResult, t, x) \
    for ((tResult) = LB(t); RIGHT(tResult) <= (x); (tResult) = TR(tResult)) \
        /* Nothing */;

#define	TiSrPointNoHint(plane, point)	(TiSrPoint((Tile *) NULL, plane, point))

/*
 * GOTOPOINT is used whenever a macroized version of TiSrPoint is
 * needed.
 */

#define	GOTOPOINT(tp, p) \
    { \
	if ((p)->p_y < BOTTOM(tp)) \
	    do tp = LB(tp); while ((p)->p_y < BOTTOM(tp)); \
	else \
	    while ((p)->p_y >= TOP(tp)) tp = RT(tp); \
	if ((p)->p_x < LEFT(tp)) \
	    do  \
	    { \
		do tp = BL(tp); while ((p)->p_x < LEFT(tp)); \
		if ((p)->p_y < TOP(tp)) break; \
		do tp = RT(tp); while ((p)->p_y >= TOP(tp)); \
	    } \
	    while ((p)->p_x < LEFT(tp)); \
	else \
	    while ((p)->p_x >= RIGHT(tp)) \
	    { \
		do tp = TR(tp); while ((p)->p_x >= RIGHT(tp)); \
		if ((p)->p_y >= BOTTOM(tp)) break; \
		do tp = LB(tp); while ((p)->p_y < BOTTOM(tp)); \
	    } \
    }

/* Fill in the bounding rectangle for a tile */
#define	TITORECT(tp, rp) \
	((rp)->r_xbot = LEFT(tp), (rp)->r_ybot = BOTTOM(tp), \
	 (rp)->r_xtop = RIGHT(tp), (rp)->r_ytop = TOP(tp))

extern Rect TiPlaneRect;	/* Rectangle large enough to force area
				 * search to visit every tile in the
				 * plane.  This is the largest rectangle
				 * that should ever be painted in a plane.
				 */
extern RectFloat TiPlaneRectF;	/* Rectangle large enough to force area
				 * search to visit every tile in the
				 * plane.  This is the largest rectangle
				 * that should ever be painted in a plane.
				 */
/*
 *--------------------------------------------------------------
 *
 * TiRectIsFinite --
 *
 * Return TRUE if rectangle falls completely inside plane.
 *
 *--------------------------------------------------------------
 */
static __inline__ bool TiRectIsFinite(Rect *r)
{
  return 
    r->r_xbot > PLANE_BOT && 
    r->r_ybot > PLANE_BOT &&
    r->r_xtop < PLANE_TOP &&
    r->r_ytop < PLANE_TOP; 
}

static __inline__ double TiPlaneNumTiles(Plane *pl)
{
  return pl->pl_numAllocs - pl->pl_numFrees;
}

static __inline__ double TiPlaneNumOps(Plane *pl)
{
  return pl->pl_numAllocs + pl->pl_numFrees;
}
#endif _TILE
