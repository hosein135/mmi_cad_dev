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



/* DBconnect.c -
 *
 *	This file contains routines that extract electrically connected
 *	regions of a layout for Max.  
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
static char rcsid[] = "$Header: DBconnect.c,v 6.1 90/09/03 14:50:06 stark Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "signals.h"
#include "malloc.h"
#include "debug.h"

/* set to gather statistics */
#define DBC_STATS 0

/* The extraction proceeds in one pass, copying
 * all connected stuff from a hierarchy into a single cell.  
 * A queue of tiles that still need to be searched from is kept.
 */

typedef struct connectQueue
{
    Rect cq_area;			/* Area that we know is connected, but
					 * which may be connected to other
					 * stuff.
					 */
    int cq_type;			/* Type of material we found. */
    struct connectQueue *cq_next;	/* Pointer to next in list. */
} ConnectQueue;

/*
 *
 * This queue serves for both polygons and wirepaths:
 * when a wirepath is encountered, it is copied to the destination def
 * and its component ("dependent") polygons are queued.
 */
typedef struct connectQueuePoly
{
    Polygon *cqp_poly;                  /* polygon that we know is connected,
					 * but still need to search from.
					 */
    struct connectQueuePoly *cqp_next;
} ConnectQueuePoly;

/* def we are copying too */
static CellDef *dbcDestDef = NULL;

/* table defining what each tile type connects to */
static TileTypeBitMask *dbcConnectTable;
 
/* queue of areas to continue search from 
 * we keep two queues:
 *    dbcQueue     - manhattan rects
 *    dbcQueuePoly - polygons
 */
static ConnectQueue *dbcQueue = NULL;  
static ConnectQueuePoly *dbcQueuePoly = NULL;  /* polygon queue */ 

/* save last couple queue elements searched
 * (used for efficient filtering of already visited areas)
 */
static ConnectQueue *dbcLast = NULL;
static ConnectQueue *dbcLast2 = NULL;

/* keep our own free lists */ 
static ConnectQueue *dbcFree = NULL;  
static ConnectQueue *dbcBlocks = NULL;
static ConnectQueuePoly *dbcFreePoly = NULL;  
static ConnectQueuePoly *dbcBlocksPoly = NULL;

/* current polygon we are expanding from */
static Polygon *dbcCurPoly;
 
/* statistics */
static int statVisits, statQueues, statLast, statLast2;


/*
 * ----------------------------------------------------------------------------
 *
 * dbcStats
 *
 *      print stats (for debugging)
 * ----------------------------------------------------------------------------
 */
static void 
dbcStats(void)
{     
    fprintf(stderr,"statistics:\n"
	    "\tvisits=%d\n"
	    "\tqueues=%d\n"
	    "last filters = %d\n"
	    "last2 filters = %d\n",
	    statVisits, statQueues, statLast, statLast2);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcAllocCQ --
 *
 *      Allocate a queue element.
 *      (We allocate in blocks and keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
#define DBCQ_BLOCKSIZE 1000

static __inline__ void* 
dbcAllocCQ(void)
{
  ConnectQueue *new, *block;
  int i;

  if(dbcFree == NULL)
  {
    /* free list empty allocate a block of elements */

    MALLOC(ConnectQueue *, block, sizeof(ConnectQueue)*DBCQ_BLOCKSIZE);

    /* first element used to link blocks */
    block->cq_next = dbcBlocks;
    dbcBlocks = block;
    
    /* add remaining elements to free list */
    for(i=1; i<DBCQ_BLOCKSIZE-1; i++) block[i].cq_next = &block[i+1];
    block[DBCQ_BLOCKSIZE-1].cq_next = NULL;
    dbcFree = &block[1];
  }

  new = dbcFree;
  dbcFree = dbcFree->cq_next;
  return new;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcFreeCQ --
 *
 *      Free a queue element.
 *      (We keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void 
dbcFreeCQ(ConnectQueue *cq)
{
  cq->cq_next = dbcFree;
  dbcFree = cq;
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbcAllocCQP --
 *
 *      Allocate a polygon queue element.
 *      (We allocate in blocks and keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
#define DBCQP_BLOCKSIZE 1000

static __inline__ void* 
dbcAllocCQP(void)
{
  ConnectQueuePoly *new, *block;
  int i;

  if(dbcFreePoly == NULL)
  {
    /* free list empty allocate a block of elements */

    MALLOC(ConnectQueuePoly *, 
	   block, 
	   sizeof(ConnectQueuePoly)*DBCQP_BLOCKSIZE);

    /* first element used to link blocks */
    block->cqp_next = dbcBlocksPoly;
    dbcBlocksPoly = block;
    
    /* add remaining elements to free list */
    for(i=1; i<DBCQP_BLOCKSIZE-1; i++) block[i].cqp_next = &block[i+1];
    block[DBCQP_BLOCKSIZE-1].cqp_next = NULL;
    dbcFreePoly = &block[1];
  }

  new = dbcFreePoly;
  dbcFreePoly = dbcFreePoly->cqp_next;
  return new;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcFreeCQP --
 *
 *      Free a polygon queue element.
 *      (We keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void 
dbcFreeCQP(ConnectQueuePoly *cqp)
{
  cqp->cqp_next = dbcFreePoly;
  dbcFreePoly = cqp;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcCleanQueue --
 *
 *      Clear connect queue (and our private free list)
 *
 * ----------------------------------------------------------------------------
 */
static void 
dbcCleanQueue(void)
{
  dbcQueue = NULL;
  dbcLast = NULL;
  dbcLast2 = NULL;
  dbcFree = NULL;

  while(dbcBlocks)
  {
    ConnectQueue *top = dbcBlocks;
    dbcBlocks = top->cq_next;
    FREE(top);
  }

  dbcQueuePoly = NULL;
  dbcFreePoly = NULL;

  while(dbcBlocksPoly)
  {
    ConnectQueuePoly *top = dbcBlocksPoly;
    dbcBlocksPoly = top->cqp_next;
    FREE(top);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcVisit --
 *
 *      If area not already visited, copy to destination cell and queue
 * 	for future search
 *
 * ----------------------------------------------------------------------------
 */

/* helper func */
static int dbcAlwaysOneFunc(Tile *tile, ClientData cdata) { return 1; }

static __inline__ void 
dbcVisit(Tile *tile, 
	 	/* tile to process */ 
	 Transform *trans)
     		/* transform from tile to dest def coords */
{
  ConnectQueue *new;
  Rect area;
  TileType type;
  int planeNum;

  if(DBC_STATS) statVisits++;
  /* compute area */
  {
    Rect tmp;
    TiToRect(tile, &tmp);
    GeoTransRect(trans, &tmp, &area);
  }
  type = DBgetTileType(tile);
  planeNum = DBPlane(type);

  /* DEBUG
  fprintf(stderr,"DEBUG dbcVisit TOP, type = %s ",
	  DBTypeLongNameTbl[type]);
  DumpRect("area = ", &area);
  */

  /* filter out current and previous search area 
   * (for efficiency!)
   */

  /* filter out areas already visited */
  if(dbcLast && 
     type == dbcLast->cq_type && 
     GEO_SURROUND(&dbcLast->cq_area, &area))
  {
    if(DBC_STATS) statLast++;
    return;
  }
  if(dbcLast2 && 
     type == dbcLast2->cq_type && 
     GEO_SURROUND(&dbcLast2->cq_area, &area))
  {
    if(DBC_STATS) statLast2++;
    return;
  }

  {
    if (DBPlaneEnumAreaPaint((Tile *) NULL, 
			     dbcDestDef->cd_planes[planeNum],
			     &area, 
			     &DBSpaceBits,
			     dbcAlwaysOneFunc, 
			     NULL) == 0)
    {
      /* area already visited, just return */
      return;
    }
  }

  /* copy area to destination cell */
  DBPaintPlane(dbcDestDef->cd_planes[planeNum], 
	       &area,
	       DBStdPaintTbl(type, planeNum), 
	       (PaintUndoInfo *) NULL);

  /* add area to queue */
  if(DBC_STATS) statQueues++;
  new = dbcAllocCQ();
  new->cq_type = type;
  new->cq_area = area;
  new->cq_next = dbcQueue;
  dbcQueue = new;

  /* DEBUG
  fprintf(stderr,"DEBUG dbcVisit, QUEUING type = %s ",
	  DBTypeLongNameTbl[type]);
  DumpRect("area = ", &area);
  */
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbcVisitPoly --
 *
 *      If polygon not already visited, copy to destination cell and queue
 * 	for future search
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ void 
dbcVisitPoly(SearchContext *scx,
	     Polygon *poly)
{
  Polygon *polyDest;
  ConnectQueuePoly *new;

  /* if polygon already in dest, skip it */
  if(DBPolyFind(dbcDestDef, 
		poly->poly_type,
		dbcDestDef->cd_activeGroup,
		poly->poly_size,
		poly->poly_points,
		poly->poly_wirePath,
		&scx->scx_trans)) return;

  /* add polygon to dest def */
  polyDest =  DBPolygonCopy(poly, dbcDestDef, &scx->scx_trans);

  /* add polygon to queue */
  new = dbcAllocCQP();
  new->cqp_poly = polyDest;
  new->cqp_next = dbcQueuePoly;
  dbcQueuePoly = new;
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbcVisitWP --
 *
 *      If WirePath not already visited, 
 *      copy to destination cell and queue its polygons for future search.
 * 	for future search
 *
 * ----------------------------------------------------------------------------
 */

/* helper func to dbcVisitWP(), queues new dependent polygons */ 
static void dbcQueueWPPolyFunc(CellDef *def,
			       WirePath *wp,
			       Polygon *poly)
{
  ConnectQueuePoly *new;

  new = dbcAllocCQP();
  new->cqp_poly = poly;

  new->cqp_next = dbcQueuePoly;
  dbcQueuePoly = new;
}

static __inline__ void 
dbcVisitWP(SearchContext *scx,
	   WirePath *wp)
{
  WirePath *wpDest;
  Polygon *poly;

  /* if wirepath already in dest, skip it */
  if(DBWPathFind(dbcDestDef, 
		 wp->wp_type,
		 dbcDestDef->cd_activeGroup,
		 wp->wp_style,
		 wp->wp_width,
		 wp->wp_size,
		 wp->wp_points,
		 &scx->scx_trans)) return;

  /* add wirepath to dest def */
  wpDest =  DBWPathCopy(wp, 
			dbcDestDef, 
			&scx->scx_trans, 
			dbcQueueWPPolyFunc);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcInitialTileFunc --
 *
 * 	Func for DBSearchPaintNew(), adds initial tile to queue
 *      to start connectivity search.
 *
 * Results:
 *	returns 1 to abort search on first tile found. 
 *
 * Side effects:
 *	Adds a new item to the connect leaf queue.
 *
 * ----------------------------------------------------------------------------
 */

static int
dbcInitialTileFunc(Tile *tile, 
               			/* Tile found. */
	       TreeContext *cx)
                    		/* search context */
{
    dbcVisit(tile, &cx->tc_scx->scx_trans);

    /* we have our starting point, so abort search */ 
    return 1;
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbcInitialPolyFunc --
 *
 * 	Func for DBSearchPaintNew(), adds initial polygon
 *      to queue to start search.
 *
 * Results:
 *	returns 1 to abort search on first tile found. 
 *
 * Side effects:
 *	Adds a new item to the connect leaf queue.
 *
 * ----------------------------------------------------------------------------
 */

static int
dbcInitialPolyFunc(SearchContext *scx, 
		   Polygon *poly,
		   ClientData cdarg)
{
    dbcVisitPoly(scx, poly);

    /* we have our starting point, so abort search */ 
    return 1;
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbcInitialWPFunc --
 *
 * 	Func for DBSearchPaintNew(), visits initial wirepath
 *      to start search.
 *
 * Results:
 *	returns 1 to abort search on first tile found. 
 *
 * Side effects:
 *	Adds a new item to the connect leaf queue.
 *
 * ----------------------------------------------------------------------------
 */

static int
dbcInitialWPFunc(SearchContext *scx, 
		 WirePath *wp,
		 ClientData cdarg)
{
    dbcVisitWP(scx, wp);

    /* we have our starting point, so abort search */ 
    return 1;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcTile2Tile --
 *
 * 	Func for DBSearchPaintNew(), used to queue all tiles touching
 *      given paint tile.
 *
 * ----------------------------------------------------------------------------
 */

static int
dbcTile2Tile(Tile *tile, 
               			/* Tile found. */
	       TreeContext *cx)
                    		/* search context */
{
  /* process this tile for further search */
  dbcVisit(tile, &cx->tc_scx->scx_trans);

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcTile2Poly --
 *
 * 	Func for DBSearchPaintNew(), used to queue all polygons touching a
 *      given paint tile.
 *
 * ----------------------------------------------------------------------------
 */
static int
dbcTile2Poly(SearchContext *scx, 
		   Polygon *poly,
		   ClientData *cdarg)
{
  dbcVisitPoly(scx, poly);

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcTile2WP --
 *
 * 	Func for DBSearchPaintNew(), used to copy a wirepath touching a 
 *      given paint tile, and queue all associated polygons.
 *
 * ----------------------------------------------------------------------------
 */
static int
dbcTile2WP(SearchContext *scx, 
		   WirePath *wp,
		   ClientData *cdarg)
{
  dbcVisitWP(scx, wp);

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcPoly2Tile --
 *
 * 	Func for DBSearchPaintNew(), used to queue all tiles touching
 *      current polygon
 *
 * ----------------------------------------------------------------------------
 */

static int
dbcPoly2Tile(Tile *tile, 
               			/* Tile found. */
		   TreeContext *cx)
                    		/* search context */
{
  Transform *trans = &cx->tc_scx->scx_trans;
  Rect r, rDest;

  TiToRect(tile, &r);
  GEOTRANSRECT(trans,&r,&rDest);

  /* expand to handle touching case */
  GEO_EXPAND(&rDest,1,&rDest);

  if(DBPolygonIntersectRectQ(dbcCurPoly, &rDest))
  {
    /* tile intersects polygons, so copy and queue it */
    dbcVisit(tile, &cx->tc_scx->scx_trans);
  }

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcPoly2Poly --
 *
 * 	Func for DBSearchPaintNew(), used to queue all polygons touching 
 *      current polygon.
 *
 * ----------------------------------------------------------------------------
 */
static int
dbcPoly2Poly(SearchContext *scx, 
	     Polygon *poly,
	     ClientData cdarg)
{
  if(DBPolygonIntersectPolygonQ(dbcCurPoly, poly, &scx->scx_trans))
  {
    dbcVisitPoly(scx, poly);
  }

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbcPoly2WP --
 *
 * 	Func for DBSearchPaintNew(), used to copy wirepaths touching a given
 *      polygon and queue all of its polygons for further searching.
 *
 * ----------------------------------------------------------------------------
 */

static int
dbcPoly2WP(SearchContext *scx, 
	   WirePath *wp,
	   ClientData cdarg)
{
  if(DBWirePathIntersectPolygonQ(wp, dbcCurPoly, &scx->scx_trans))
  {
    dbcVisitWP(scx, wp);
  }

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTreeCopyConnect --
 *
 * 	This procedure copies connected information from a given cell
 *	hierarchy to a given (flat) cell.  Starting from the tile underneath
 *	the given area, this procedure copies all connected paint 
 *      (in all cells) to the result cell.
 * 
 *      If there are several electrically
 *	distinct nets underneath the given area, one is picked at "random".
 *
 *      NOTE: This routine assumes the dest cell starts out empty!
 *            May not work correctly if the dest cell doesn't start out empty.
 *
 * Results:  Normally returns 0, returns 1 if search incomplete.
 *
 * ----------------------------------------------------------------------------
 */

bool
DBTreeCopyConnect(SearchContext *scx, 
                       			/* Describes starting area.  The
					 * scx_use field gives the root of
					 * the hierarchy to search, and the
					 * scx_area field gives the starting
					 * area.  An initial tile must overlap
					 * this area.  The transform is from
					 * coords of scx_use to destUse.
					 */
		  TileTypeBitMask *mask, 
                          		/* Tile types to start from in area. */
		  int xMask, 
              				/* Information must be expanded in all
					 * of the windows indicated by this
					 * mask.  Use 0 to consider all info
					 * regardless of expansion.
					 */
		  TileTypeBitMask *connect, 
                             		/* Points to table that defines what
					 * each tile type is considered to
					 * connect to.  Use DBConnectTbl as
					 * a default.
					 */
		  CellUse *destUse,
                     			/* Result use in which to place
					 * anything connected to material of
					 * type mask in area of rootUse.
					 */
		  int limit)            /* if non-zero, extend from at most
					 * limit items.
					 */
{
    SearchContext scx2;
    int count = 0;
    bool interrupted = FALSE;

    /* SPACE in mask causes search to go off to infinity */
    ASSERT(!TTMaskHasType(mask,TT_SPACE),"DBTreeCopyConnect");

    /* initial statistics */
    if(DBC_STATS)
    {
      statVisits=0;
      statQueues=0;
      statLast=0;
      statLast2=0;
    }

    /* initialize globals */
    dbcDestDef = destUse->cu_def;
    dbcConnectTable = connect;
    dbcCleanQueue();
    
    /* Find and visit an initial tile or polygon to get things rolling */
    (void) DBSearchPaintNew(scx, 
			    mask, 
			    xMask, 
			    dbcInitialTileFunc, 
			    dbcInitialPolyFunc,
			    dbcInitialWPFunc,
			    (ClientData) NULL,
			    0 /* flags */);

    /* search from top item in queue, until queue is empty or limit is reached */
    scx2 = *scx;
    while (dbcQueue != NULL || dbcQueuePoly != NULL)
    {  
      /* handle all queued rects first */
      while (dbcQueue != NULL) 
      {
	ConnectQueue *current;

	if(limit &&  ++count > limit) goto done;

	/* pop top item off of queue */
	current = dbcQueue;
	dbcQueue = current->cq_next;

	/* keep last couple queue elements, free after that 
	 * (used for pruning search)
	 */
	if(dbcLast2) dbcFreeCQ(dbcLast2);
	dbcLast2 = dbcLast;
	dbcLast = current;

	/* expand search area to catch touching objects */
	scx2.scx_area = current->cq_area;
	scx2.scx_area.r_xbot -= 1;
	scx2.scx_area.r_ybot -= 1;
	scx2.scx_area.r_xtop += 1;
	scx2.scx_area.r_ytop += 1;

	/* visit every tile, polygon, or wirepath 
	 * touching current area 
	 */
	if(DBSearchPaintNew(&scx2, 
			    &connect[current->cq_type],
			    xMask, 
			    dbcTile2Tile, 
			    dbcTile2Poly,
			    dbcTile2WP,
			    (ClientData) NULL,
			    0 /* flags */))
	{
	  MsgInfoF("Connectivity extraction interrupted!");
	  interrupted = TRUE;
	  goto done;
	}
      }

      /* no queued rects left, handle any polygons */
      if (dbcQueuePoly != NULL)
      {
	Polygon *poly;

	if(limit && ++count > limit) goto done;

	/* pop queue */
	{
	  ConnectQueuePoly *next;

	  poly = dbcQueuePoly->cqp_poly;
	  next = dbcQueuePoly->cqp_next;
	  dbcFreeCQP(dbcQueuePoly);
	  dbcQueuePoly = next;
	}
	dbcCurPoly = poly;
	
	/* expand to catch touching objects */
	scx2.scx_area = dbcCurPoly->poly_bbox;
	scx2.scx_area.r_xbot -= 1;
	scx2.scx_area.r_ybot -= 1;
	scx2.scx_area.r_xtop += 1;
	scx2.scx_area.r_ytop += 1;

	/* check every tile and polygon in bbox that may connect */
	if(DBSearchPaintNew(&scx2, 
			    &connect[poly->poly_type],
			    xMask, 
			    dbcPoly2Tile, 
			    dbcPoly2Poly,
			    dbcPoly2WP,
			    (ClientData) NULL,
			    0 /* flags  */))
	{
	  MsgInfoF("Connectivity extraction interrupted!");
	  interrupted = TRUE;
	  goto done;
	}

      }
    }
 done:

    /* clean up */
    dbcCleanQueue();

    /* process database change */
    DBChangedArea(dbcDestDef, NULL, &DBAllButSpaceBits, 0);

    if(DBC_STATS) dbcStats();

    return interrupted || (limit && count>limit);
}




