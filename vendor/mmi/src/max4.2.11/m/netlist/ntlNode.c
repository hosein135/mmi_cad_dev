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



/* ntlNode.c -
 *
 *	This file contains routines that extract electrically connected
 *	regions of a layout for netlister capability of Max.  
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
static char rcsid[] = "$Header: ntlNode.c,v 6.1 90/09/03 14:50:06 stark Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "netlistInt.h"
#include "netlist.h"
#include "signals.h"
#include "malloc.h"
#include "debug.h"

/*
 * process all the paint on all the wiring layers
 *
 * starting with paint that has not neen marked
 * a node record is created first, and then
 * all tiles and polygons that are electrically connected
 * have their client fields set to point to the node record
 *
 * after all paint has been marked,
 * the result is that a list of nodes is created,
 * and each tile and each polygon in the celldef has its 
 * client field pointing to the node that it is part of
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
 * This queue serves for polygons only:
 * wire paths are ignored, 
 * as their dependent polygons are processed instead
 */
typedef struct connectQueuePoly
{
    Polygon *cqp_poly;                  /* polygon that we know is connected,
					 * but still need to search from.
					 */
    struct connectQueuePoly *cqp_next;
} ConnectQueuePoly;

/* table defining what each tile type connects to */
/* moved to  netlist.h*/
/*static TileTypeBitMask *ntlConnectTable; */
 
/* queue of areas to continue search from 
 * we keep two queues:
 *    ntlQueue     - manhattan rects
 *    ntlQueuePoly - polygons
 */
static ConnectQueue *ntlQueue = NULL;  
static ConnectQueuePoly *ntlQueuePoly = NULL;  /* polygon queue */ 

/* keep our own free lists */ 
static ConnectQueue *ntlFree = NULL;  
static ConnectQueue *ntlBlocks = NULL;
static ConnectQueuePoly *ntlFreePoly = NULL;  
static ConnectQueuePoly *ntlBlocksPoly = NULL;

/* current polygon we are expanding from */
static Polygon *ntlCurPoly;

static NodeRecord  *ntlCurNode;

NodeRecord * ntlNewNode()
{
    NodeRecord * node;
    int nclasses, n;

/* Allocate a new node
 * right now, we are not doing area and perimeter for nodes, 
 * should set nclasses to 0 in tech file
 * the cap, resist, and pnum  fields could go too
 */
    /*
    nclasses = NtlCurStyle->ntls_numResistClasses;
    n = sizeof (NodeRecord) + (sizeof (PerimArea) * (nclasses - 1));
    */
    n = sizeof (NodeRecord);
    nclasses = 1;
    MALLOC(NodeRecord *, node, (unsigned) n);
    node->nrec_alias = (NodeRecord **) NULL;
    node->nrec_next = (NodeRecord *) NULL;
    node->nrec_pnum = DBNumPlanes;

    /* note that nrec_class and nrec_ll are not initialized */

    node->nrec_labels = (NLabelList *) NULL;
    /* node->nrec_cap = (CapValue) 0; */
    node->nrec_nodenum = 0;
    node->nrec_type = LAB_COMMENT;
    for (n = 0; n < nclasses; n++)
        node->nrec_area[n] = 0;

    /* Prepend the new node to the node list */
    node->nrec_next = ntlCurNode;
    return (node);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlAllocCQ --
 *
 *      Allocate a queue element.
 *      (We allocate in blocks and keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
#define DBCQ_BLOCKSIZE 1000

static __inline__ void* 
ntlAllocCQ(void)
{
  ConnectQueue *new, *block;
  int i;

  if(ntlFree == NULL)
  {
    /* free list empty allocate a block of elements */

    MALLOC(ConnectQueue *, block, sizeof(ConnectQueue)*DBCQ_BLOCKSIZE);

    /* first element used to link blocks */
    block->cq_next = ntlBlocks;
    ntlBlocks = block;
    
    /* add remaining elements to free list */
    for(i=1; i<DBCQ_BLOCKSIZE-1; i++) block[i].cq_next = &block[i+1];
    block[DBCQ_BLOCKSIZE-1].cq_next = NULL;
    ntlFree = &block[1];
  }

  new = ntlFree;
  ntlFree = ntlFree->cq_next;
  return new;
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlFreeCQ --
 *
 *      Free a queue element.
 *      (We keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void 
ntlFreeCQ(ConnectQueue *cq)
{
  cq->cq_next = ntlFree;
  ntlFree = cq;
}



/*
 * ----------------------------------------------------------------------------
 *
 * ntlAllocCQP --
 *
 *      Allocate a polygon queue element.
 *      (We allocate in blocks and keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
#define DBCQP_BLOCKSIZE 1000

static __inline__ void* 
ntlAllocCQP(void)
{
  ConnectQueuePoly *new, *block;
  int i;

  if(ntlFreePoly == NULL)
  {
    /* free list empty allocate a block of elements */

    MALLOC(ConnectQueuePoly *, 
	   block, 
	   sizeof(ConnectQueuePoly)*DBCQP_BLOCKSIZE);

    /* first element used to link blocks */
    block->cqp_next = ntlBlocksPoly;
    ntlBlocksPoly = block;
    
    /* add remaining elements to free list */
    for(i=1; i<DBCQP_BLOCKSIZE-1; i++) block[i].cqp_next = &block[i+1];
    block[DBCQP_BLOCKSIZE-1].cqp_next = NULL;
    ntlFreePoly = &block[1];
  }

  new = ntlFreePoly;
  ntlFreePoly = ntlFreePoly->cqp_next;
  return new;
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlFreeCQP --
 *
 *      Free a polygon queue element.
 *      (We keep our own free list for efficiency)
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void 
ntlFreeCQP(ConnectQueuePoly *cqp)
{
  cqp->cqp_next = ntlFreePoly;
  ntlFreePoly = cqp;
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlCleanQueue --
 *
 *      Clear connect queue (and our private free list)
 *
 * ----------------------------------------------------------------------------
 */
static void 
ntlCleanQueue(void)
{
  ntlQueue = NULL;
  ntlFree = NULL;

  while(ntlBlocks)
  {
    ConnectQueue *top = ntlBlocks;
    ntlBlocks = top->cq_next;
    FREE(top);
  }

  ntlQueuePoly = NULL;
  ntlFreePoly = NULL;

  while(ntlBlocksPoly)
  {
    ConnectQueuePoly *top = ntlBlocksPoly;
    ntlBlocksPoly = top->cqp_next;
    FREE(top);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlTile2Tile --
 *
 * 	Func for DBPlaneEnumAreaPaintClient(), used to queue all tiles touching
 *      given paint tile.
 *
 * ----------------------------------------------------------------------------
 */

static int
ntlTile2Tile(Tile *tile,	/* Tile found */
	   ClientData none)   /* unused, needed by calling function */
{

  ConnectQueue *new;
  Rect area;
  TileType type;

  /* set client field in tile to point to node */
  tile->ti_client = (ClientData)ntlCurNode;

  /* compute area */
  TiToRect(tile, &area);
  /* get type */
  type = DBgetTileType(tile);

  /* update LL corner in node record */
  ntlSetNodeNum((NLabRegion *)ntlCurNode, DBPlane(type), tile);

/*
 MsgInfoF("Tile2Tile: Enque : points = %d, %d, %d, %d , node = %x, type = 0x%x\n", 
    area.r_ll.p_x, area.r_ll.p_y, area.r_ur.p_x, area.r_ur.p_y, tile-> ti_client, type);
*/

  /* add area to front of connect queue */
  new = ntlAllocCQ();
  new->cq_type = type;
  new->cq_area = area;
  new->cq_next = ntlQueue;
  ntlQueue = new;

  /* continue search */
  return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlPoly2Tile --
 *
 * 	Func for DBPlaneEnumAreaPaintClient(), used to queue all tiles touching
 *      current polygon
 *
 * ----------------------------------------------------------------------------
 */

static int
ntlPoly2Tile(Tile *tile,	/* Tile found. */
	   ClientData cdarg)     /* not used */
{
  Rect rDest;
  ConnectQueue *new;
  Rect area;
  TileType type;

  TiToRect(tile, &rDest);

  /* expand to handle touching case */
  GEO_EXPAND(&rDest,1,&rDest);

  if(DBPolygonIntersectRectQ(ntlCurPoly, &rDest))
  {
    /* poly intersects tile, so queue tile */
    /* set client field in tile to point to node */
    tile->ti_client = (ClientData)ntlCurNode;

    /* compute area */
    TiToRect(tile, &area);
    /* get type */
    type = DBgetTileType(tile);

    /* update LL corner in node record */
    ntlSetNodeNum ((NLabRegion *)ntlCurNode, DBPlane(type), tile);

    /* add tile to front of connect queue */
    new = ntlAllocCQ();
    new->cq_type = type;
    new->cq_area = area;
    new->cq_next = ntlQueue;
    ntlQueue = new;
  }

  /* continue search */
  return 0;
}

    /*
     * search  rects and polys in queue, until queue is empty
     * at that point all paint on a one node has been marked
     */
void ntlSearchQueue(CellDef * def)
{
    Rect area;
    TileTypeBitMask * mask;
    
    register Polygon * poly;

    while (ntlQueue != NULL || ntlQueuePoly != NULL)
    {  
      /* process all queued rects first  */
      while (ntlQueue != NULL) 
      {
	ConnectQueue *current = ntlQueue;

	    /* get elements from top item */
	area = current-> cq_area;
	    /* mask has 1 bit set in each plane that connects to this type */
	mask = &ntlConnectTable[current->cq_type];
	    /* pop top item off of queue */
	ntlQueue = current->cq_next;
	    /* free queue element */
	ntlFreeCQ (current);

	/* expand search area to handle touching case */
	GEO_EXPAND( &area, 1, &area);

	/*
	 * step 1: visit every tile touching current tile 
	 * borrowed/unwrapped from DBsearchPaintDef
	 */
	{
	  PlaneList *planes = DBPlaneListFromTypes(mask);
	  PlaneList *pll;
	  
	  for(pll=planes; pll; pll=pll->pll_next)
	  {
	    if (DBPlaneEnumAreaPaintClient((Tile *) NULL,
					   def->cd_planes[pll->pll_num],
					   &area,
					   mask,
					   (ClientData)MINFINITY,
					   ntlTile2Tile,
					   (ClientData) NULL))
	    {
		MsgInfoF("ntlSearchQueue, step 1: Netlist extraction interrupted !\n");
		break;
	    }
	  }

	  PlaneListFree(planes);
	}

	/*
	 * step 2: visit every polygon touching current tile 
	 * also borrowed/unwrapped from DBsearchPaintDef
	 */

	for (poly = def->cd_polygons; poly; poly = poly->poly_next)
	{
	    if (SigInterruptPending)
	    {
		MsgInfoF("ntlSearchQueue, step 2: Netlist extraction interrupted !\n");
		break;
	    }

	  if( ( poly-> poly_client == (ClientData)MINFINITY) &&
		TTMaskHasType(mask, poly->poly_type) &&
		DBPolygonIntersectRectQ(poly, &area))
	  {
	      ConnectQueuePoly *new = ntlAllocCQP();

	      /* set client field in poly to point to node */
	      poly->poly_client = (ClientData) ntlCurNode;

	      /* update node ll corner, using first point in polygon */
	      ntlSetNodeLLPoly(ntlCurNode, DBPlane(poly->poly_type), poly);


	      /* add polygon to polygon connect queue */
	      new->cqp_poly = poly;
	      new->cqp_next = ntlQueuePoly;
	      ntlQueuePoly = new;
	  }
	}
      }


      /* no queued rects left, handle any polygons */
      if (ntlQueuePoly != NULL)
      {

	ConnectQueuePoly * next;

	    /* get poly */
	ntlCurPoly = ntlQueuePoly->cqp_poly;

	    /* pop connect queue (polygon) */
	next = ntlQueuePoly->cqp_next;
	ntlFreeCQP(ntlQueuePoly);
	ntlQueuePoly = next;

	    /* get elements from poly */
	area       = ntlCurPoly->poly_bbox;
	mask       = &ntlConnectTable[ntlCurPoly->poly_type];

	/* expand search area to handle touching case */
	GEO_EXPAND( &area, 1, &area);

	/*
	 * step 3: visit every tile touching bbox of current poly 
	 */
	{
	  PlaneList *pll;
	  PlaneList *planes = DBPlaneListFromTypes(mask);

	  for(pll=planes; pll; pll=pll->pll_next)
	  {
	    if (DBPlaneEnumAreaPaintClient((Tile *) NULL,
					   def->cd_planes[pll->pll_num],
					   &area,
					   mask,
					   (ClientData)MINFINITY,
					   ntlPoly2Tile,
					   (ClientData) NULL))
	    {
		MsgInfoF("ntlSearchQueue, step 3: Netlist extraction interrupted !\n");
		break;
	    }
	  }
	  
	  PlaneListFree(planes);
	}

	/*
	 * step 4: visit every polygon touching bbox of current poly
	 */
	for (poly = def->cd_polygons; poly; poly = poly->poly_next)
	{
	  if (SigInterruptPending)
	  {
	    MsgInfoF("ntlSearchQueue, step 4: Netlist extraction interrupted !\n");
	    break;
	  }

	  if( ( poly-> poly_client == (ClientData)MINFINITY) &&
		TTMaskHasType(mask, poly->poly_type) &&
		DBPolygonIntersectPolygonQ(ntlCurPoly, poly, (Transform *) NULL))
	  {
	      ConnectQueuePoly *new = ntlAllocCQP();

	      /* set client field in poly to point to node */
	      poly->poly_client = (ClientData) ntlCurNode;

	      /* update node ll corner, using first point in polygon */
	      ntlSetNodeLLPoly (ntlCurNode, DBPlane(poly->poly_type), poly);

	      /* add polygon to polygon connect queue */
	      new->cqp_poly = poly;
	      new->cqp_next = ntlQueuePoly;
	      ntlQueuePoly = new;
	  }
	}
      }
    }
/* MsgInfoF("net  at %x finished \n\n", ntlCurNode); */

    /* clean up */
    ntlCleanQueue();
}

/* start from a tile, with client field MINFINITY
 * place pointer to node on everything connected to this tile
 */
static int ntlMarkTileFunc(Tile * tile, CellDef * def  )
{
    ConnectQueue * new;
    Rect area;
    TileType type;

    /* Allocate a new Node */
    ntlCurNode = ntlNewNode();

    /* put tile on front of empty queue */
    TiToRect(tile, &area);
    type = DBgetTileType(tile);

/*
MsgInfoF("ntlMarkTile %d, %d, %d, %d, type = %x\n", 
    area.r_ll.p_x, area.r_ll.p_y, area.r_ur.p_x, area.r_ur.p_y, type);
*/
    new = ntlAllocCQ();
    new->cq_type = type;
    new->cq_area = area;
    new->cq_next = ntlQueue;
    ntlQueue = new;

    /* put node pointer in client field of all connected tile and polys */
    ntlSearchQueue(def);

    return 0; /* keep going */
}

/* start from a polygon, with client field MINFINITY
 * mark node number on everything connected to this polygon
 */

static int ntlMarkPoly(Polygon * poly, CellDef * def  )
{
    ConnectQueuePoly * new;

    /* Allocate a new Node */
    ntlCurNode = ntlNewNode();

  /* add polygon to front of connect queue (polygon) */
    new = ntlAllocCQP();
    new->cqp_poly = poly;
    new->cqp_next = ntlQueuePoly;
    ntlQueuePoly = new;

    /* put node pointer in client field of all connected tile and polys */
    ntlSearchQueue(def);

    return 0; /* keep going */
}


/* ----------------------------------------------------------------------------
 * ntlFindNodes
 * ----------------------------------------------------------------------------
 */

extern Rect TiPlaneRect;

NodeRecord *
ntlFindNodes( CellDef * def)
/* , TileTypeBitMask * connect) */
{
    int pNum;
    Polygon  * poly;
    Plane * plane;

/* MsgInfoF("marking nodes of celldef %s \n", def->cd_name);  */
    ntlCurNode = (NodeRecord *) NULL;

    ntlCleanQueue();

    /* ntlConnectTable = connect; */
    
    /*ntlConnectTable = DBConnectTbl; */

     /* read def from disk, if necessary  */
/*
ISSUEwhat to return, really,  this belongs in Extmain (calls this function)
if ((def->cd_flags & CDAVAILABLE) == 0)
if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;
	 */

    /*
     * for all tiles in celldef
     * DBPlaneEnumAreaPaintClient: only executes callbacks
     * if client field is not already marked
     */
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++) {
	DBPlaneEnumAreaPaintClient(
	    (Tile *) NULL,
	    def->cd_planes[pNum],
	    &TiPlaneRect,		/* all tiles */
	    &DBAllButSpaceBits,
	    (ClientData) MINFINITY,
	    ntlMarkTileFunc, 
	    (ClientData) def);
    }

    /* for all polys in celldef */
    for(poly = def->cd_polygons; poly; poly = poly-> poly_next) {
	    /* if poly not already marked */
	    if(poly-> poly_client == (ClientData)MINFINITY)	
		ntlMarkPoly(poly, def);
    }
    return ntlCurNode;
}
