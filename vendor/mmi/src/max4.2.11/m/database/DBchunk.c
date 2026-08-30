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




#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "signals.h"
#include "database.h"
#include "databaseInt.h"
#include "debug.h"

/* internal scratch cell used by chunk code */
static CellDef *dbChunkDef;
static CellUse *dbChunkUse;

/*
 * ----------------------------------------------------------------------------
 *
 * dbChunkInit --
 *
 * called once at startup (from DBInit()) to initialize chunk extraction code.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

void dbChunkInit(void)
{
  UndoDisable();

  /* create internal __DBCHUNK__ cell */
  dbChunkDef = DBCellNewDef("__DBCHUNK__",(char *) NULL);
  ASSERT(dbChunkDef != (CellDef *) NULL, "dbChunkInit");
  DBCellSetAvail(dbChunkDef);
  dbChunkDef->cd_flags |= CDINTERNAL;

  /* handle (use) for __DBCHUNK__ */
  dbChunkUse = DBCellNewUse(dbChunkDef, (char *) NULL);
  DBCellUseSetTrans(dbChunkUse, &GeoIdentityTransform);
  dbChunkUse->cu_expandMask = -1;	/* This is always expanded. */

  UndoEnable();
}



/* This procedure is called for each tile of the wrong type in an
 * area that is supposed to contain only tiles of other types.  It
 * just returns the area of the wrong material and aborts the search.
 */

static int
dbChunkFunc(Tile *tile, 
               			/* The offending tile. */
	    Rect *rect)
               			/* Place to store the tile's area. */
{
    TiToRect(tile, rect);
    return 1;			/* Abort the search. */
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbFindChunk --
 *
 * 	This is a recursive procedure to find the largest chunk of
 *	material in a particular area.  It locates a rectangular
 *	area of given materials whose minimum dimension is as
 *	large as possible, and whose maximum dimension is also as
 *	large as possible (but minimum dimension is more important).
 *	Furthermore, the chunk must lie within a particular area and
 *	must contain a given area.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbFindChunk(Plane *plane, 
                 			/* Plane on which to hunt for chunk. */
	     TileTypeBitMask *wrongTypes, 
                                	/* Types that are not allowed to be
					 * part of the chunk.
					 */
	     Rect *searchArea, 
                     			/* Largest allowable size for the
					 * chunk.  Note:  don't overestimate
					 * this or the procedure will take a
					 * long time!  (it processes every
					 * tile in this area).
					 */
	     Rect *containedArea, 
                        		/* The chunk returned must contain
					 * this entire area.
					 */
	     int *bestMin, 
                 			/* Largest minimum dimension seen so
					 * far: skip any chunks that can't
					 * match this.  Updated by this
					 * procedure.
					 */
	     int *bestMax, 
                 			/* Largest maximum dimension seen
					 * so far.
					 */
	     Rect *bestChunk)
                    			/* Filled in with largest chunk seen
					 * so far, if we find one better than
					 * bestMin and bestMax.
					 */
{
    Rect wrong, smaller;
    int min, max;
    extern int selChunkFunc(Tile *tile, Rect *rect);

    /* If the search area is already smaller than the chunk to beat,
     * there's no point in even examining this chunk.
     */

    min = searchArea->r_xtop - searchArea->r_xbot;
    max = searchArea->r_ytop - searchArea->r_ybot;
    if (min > max)
    {
	int tmp;
	tmp = min; min = max; max = tmp;
    }

    if (min < *bestMin) return;
    if ((min == *bestMin) && (max <= *bestMax)) return;

    /* At each stage, search the area that's left for material of the
     * wrong type.
     */

    if (DBPlaneEnumAreaPaint((Tile *) NULL, plane, searchArea, wrongTypes,
	    dbChunkFunc, (ClientData) &wrong) == 0)
    {
	/* The area contains nothing but material of the right type,
	 * so it is now the "chunk to beat".
	 */

	*bestMin = min;
	*bestMax = max;
	*bestChunk = *searchArea;
	return;
    }

    if (SigInterruptPending)
	return;

    /* At this point the current search area contains some material of
     * the wrong type.  We have to reduce the search area to exclude this
     * material.  There are two ways that this can be done while still
     * producing areas that contain containedArea.  Try both of those,
     * and repeat the whole thing recursively on the smaller areas.
     */

    /* First, try reducing the x-range. */

    smaller = *searchArea;
    if (wrong.r_xbot >= containedArea->r_xtop)
	smaller.r_xtop = wrong.r_xbot;
    else if (wrong.r_xtop <= containedArea->r_xbot)
	smaller.r_xbot = wrong.r_xtop;
    else goto tryY;  /* Bad material overlaps containedArea in x. */
    dbFindChunk(plane, 
		wrongTypes, 
		&smaller, 
		containedArea,
		bestMin, 
		bestMax, 
		bestChunk);
    

    /* Also try reducing the y-range to see if that works better. */

    tryY: smaller = *searchArea;
    if (wrong.r_ybot >= containedArea->r_ytop)
	smaller.r_ytop = wrong.r_ybot;
    else if (wrong.r_ytop <= containedArea->r_ybot)
	smaller.r_ybot = wrong.r_ytop;
    else return;  /* Bad material overlaps containedArea in y. */
    dbFindChunk(plane, 
		wrongTypes, 
		&smaller, 
		containedArea,
		bestMin, 
		bestMax, 
		bestChunk);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBChunk --
 *
 * 	This procedure finds largest rectangular chunk of homogeneous material
 *      on given layer and covering given area.
 *
 *      largest:
 *           first, maximum minimum dimension.
 *           second (subordinate to above), maximum maximum dimension.
 *
 *      Adjusts scx_area to chunk.  
 *
 * ----------------------------------------------------------------------------
 */

void
DBChunk(SearchContext *scx, /* Area to tree-search for material.  The
			     * transform must map to root coordinates
			     * of the edit cell.
                             *
                             * area adjusted to chunk. 
		             */
	TileType type,      /* The type of material to be considered. */
	int xMask,          /* Indicates window (or windows) where cells
			     * must be expanded for their contents to be
			     * considered.  0 means treat everything as
			     * expanded.
				 */
	bool group,         /* if set only select things in currently active
			     * groups.
			     */
	CellUse *noTreeRootUse) /* null for tree search,
				 * rootUse if searching just one cell, 
				 * the cell itself is indicated 
				 * in the scx.
				 */
{
#define INITIALSIZE 10
    TileTypeBitMask wrongTypes, typeMask;
    Rect bestChunk;
    int bestMin, bestMax, width, height;
    Transform rootToUse;
    Rect rootArea; 
    Rect initialRootArea;

    GeoInvertTrans(&scx->scx_trans, &rootToUse);

    /* The chunk is computed iteratively.  First extract a small
     * region (defined by INITIALSIZE) into dbChunkDef.  Then find
     * the largest chunk in the region.  If the chunk touches a
     * side of the region, then extract a larger region and try
     * again.  Keep making the region larger and larger until we
     * eventually find a region that completely contains the chunk
     * with space left over around the edges.
     */

    UndoDisable();
    TTMaskZero(&typeMask);
    TTMaskSetType(&typeMask, type);
    TTMaskCom2(&wrongTypes, &typeMask);

    GeoTransRect(&scx->scx_trans,&scx->scx_area,&initialRootArea);
    GEO_EXPAND(&scx->scx_area, INITIALSIZE, &scx->scx_area);
    GeoTransRect(&scx->scx_trans,&scx->scx_area,&rootArea);

    while (TRUE)
    {
	/* Extract a bunch of junk. */

	DBCellClearContents(dbChunkDef);
	if (noTreeRootUse)
	{
	    DBCellCopyPaintG(scx, &typeMask, xMask, dbChunkUse, group);
	}
	else
	{
	    DBCellCopyAllPaintG(scx, &typeMask, xMask, dbChunkUse, group);
        }

	/* Now find the best chunk in the area. */
	bestMin = bestMax = 0;
	bestChunk = GeoNullRect;
	dbFindChunk(dbChunkDef->cd_planes[DBPlane(type)],
		    &wrongTypes, 
		    &rootArea, 
		    &initialRootArea,
		    &bestMin, 
		    &bestMax, 
		    &bestChunk);

	if (GEO_RECTNULL(&bestChunk))
	{
	    /* No chunk was found, return null */
	    UndoEnable();
	    scx->scx_area = GeoNullRect;
	    return;
	}

	/* If the chunk is completely inside the area we yanked, then we're
	 * done.
	 */
	if (GEO_SURROUND_STRONG(&rootArea, &bestChunk)) break;

	/* The chunk extends to the edge of the area.  Anyplace that the
	 * chunk touches an edge, move that edge out by a factor of two.
	 * Anyplace it doesn't touch, move the edge in to be just one
	 * unit out from the chunk.
	 */
	
	width = rootArea.r_xtop - rootArea.r_xbot;
	height = rootArea.r_ytop - rootArea.r_ybot;

	if (bestChunk.r_xbot == rootArea.r_xbot)
	    rootArea.r_xbot -= width;
	else rootArea.r_xbot = bestChunk.r_xbot - 1;
	if (bestChunk.r_ybot == rootArea.r_ybot)
	    rootArea.r_ybot -= height;
	else rootArea.r_ybot= rootArea.r_ybot - 1;
	if (bestChunk.r_xtop == rootArea.r_xtop)
	    rootArea.r_xtop += width;
	else rootArea.r_xtop = bestChunk.r_xtop + 1;
	if (bestChunk.r_ytop == rootArea.r_ytop)
	    rootArea.r_ytop += height;
	else rootArea.r_ytop = bestChunk.r_ytop + 1;

	GeoTransRect(&rootToUse, &rootArea, &scx->scx_area);
    }

    UndoEnable();
    GeoTransRect(&rootToUse, &bestChunk, &scx->scx_area);
    return;
}



