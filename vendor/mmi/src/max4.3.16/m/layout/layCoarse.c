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


 
/* layCoarse.c -
 *
 * Maintains coarse resolution versions of celldef paint planes, 
 * used to improve redisplay performance when zoomed out.
 *
 */

#include <stdio.h>
#include "magic.h"
#include "utils.h"
#include "message.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "signals.h"
#include "memory.h"
#include "geometry.h"
#include "geometry.h"
#include "layout.h"
#include "layint.h"
#include "debug.h"

/* 
 * knob for display resolution (in pixels)
 * 
 * initialized in layDisplayInit()
 * linked to tcl var LAY_RES
 */
double layRes = 1.0;

/* resolution of coarse version of paint planes 
 * (used for redisplay when zoomed out)
 *
 * initialized in layDisplayInit()
 * linked to tcl var LAY_COARSE_RES
 */
int layCoarseRes;

/* factor by which successive versions of paint planes 
 * get coarser.
 *
 * linked to tcl var LAY_COARSE_FACTOR
 */
double layCoarseFactor = 2.0;

/* minimum factor by which a coarse plane must shrink data 
 *  
 * linked to tcl var LAY_COARSE_DATA_FACTOR
 */
double layCoarseDataFactor = 4.0;

/* maximum ratio of total coarse data to corresponding paint data  
 *  
 * linked to tcl var LAY_COARSE_MAX_OVERHEAD
 */
double layCoarseMaxOverhead = 1.0;

/* maximum changes relative to data size, before coarse planes
 * are completely regened.
 *  
 * linked to tcl var LAY_COARSE_FLUSH_FACTOR
 */
double layCoarseFlushFactor = .50;

/*
 * ----------------------------------------------------------------------------
 * LayCoarseMakePlaneRedundant --
 *
 * Delete a coarse plane, and replace with reference to less coarse plane.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarseMakePlaneRedundant(CellDef *def,
			    Coarse *c, 
			    int pNum)
{
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  Plane *pDel = c->c_planes[pNum];

  ASSERT(!(c->c_flags[pNum] & CFLG_COPY),"layCoarseMakePlaneRedundant");
  ASSERT(cdb,"layCoarseMakePlaneRedundant");

  /* replace all references to this plane with less coarse 'replacement' */
  {
    Plane *pReplace;

    if(c->c_prev) 
    {
      pReplace = c->c_prev->c_planes[pNum];
    }
    else
    {
      pReplace = def->cd_planes[pNum];
    }
  
    while(c && c->c_planes[pNum] == pDel)
    {
      c->c_planes[pNum] = pReplace;
      c->c_flags[pNum] |= CFLG_COPY;
      c=c->c_next;
    }
  }

  /* delete the plane */
  cdb->cdb_totTiles[pNum] -= TiPlaneNumTiles(pDel);
  DBPlaneClearPaint(pDel);
  TiFreePlane(pDel);
}

/*
 * ----------------------------------------------------------------------------
 * layCoarseEnforceMaxOverhead --
 *
 * Remove coarse planes (beginning with least) coarse, until
 * total coarse tiles within specified factor of underlying paint plane.
 *
 * if cLimit non-null, only remove planes finer than cLimit.
 * removed.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarseEnforceMaxOverhead(CellDef *def, Coarse *cLimit, int pNum)
{
  Coarse *c;
  int totCoarse = 0;
  CoarseDB *cdb = def->cd_coarseDB;
  double budget = TiPlaneNumTiles(def->cd_planes[pNum]) * layCoarseMaxOverhead;  

  /* remove coarse planes, finest first, until within memory budget */
  c=cdb->cdb_coarse;
  while(cdb->cdb_totTiles[pNum] > budget 
	&& c!=cLimit)
  {
    ASSERT(c,"layCoarseEnforceMaxOverhead");

    if(!(c->c_flags[pNum] & CFLG_COPY))
    {
      layCoarseMakePlaneRedundant(def,c,pNum);
    }
    c=c->c_next;
  }
}

/*
 * ----------------------------------------------------------------------------
 * layCoarseEnforceMinCompression --
 *
 * Check given coarse plane for minimum data-compression, and remove
 * if not met.
 *
 * If a plane is removed, a less coarse version is referenced in its place.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarseEnforceMinCompression(CellDef *def, Coarse *c, int pNum)
{
  double f;

  /* data compression factor */
  if(c->c_prev)
  {
    f = TiPlaneNumTiles(c->c_prev->c_planes[pNum]);
  }
  else
  {
    f = TiPlaneNumTiles(def->cd_planes[pNum]);
  }
  f /= TiPlaneNumTiles(c->c_planes[pNum]);

  if(f < layCoarseDataFactor)
  {
    layCoarseMakePlaneRedundant(def, c, pNum);
  }
}

/*
 * ----------------------------------------------------------------------------
 * layCoarsePrune
 *
 * Enforce memory constraints on coarse planes, by removing excess
 * or redundant planes.
 *
 * If a plane is removed, a less coarse version is referenced in its place.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarsePrune(CellDef *def, Coarse *c, int pNum, bool lastSet)
{
  ASSERT(!(c->c_flags[pNum] & CFLG_COPY),"layCoarseGenPlaneArea");

  layCoarseEnforceMinCompression(def, c, pNum);
  layCoarseEnforceMaxOverhead(def, lastSet ? NULL : c, pNum);
}

/*
 * ----------------------------------------------------------------------------
 * layCoarseGenPlaneArea --
 *
 * Generate coarse resolution version of a plane area.
 *
 * ----------------------------------------------------------------------------
 */

/* used to communicate to func */
static int lRes; 
static int lPlaneNum; 
static Rect *lArea; 

/* helper func */
static int
layCoarsePaintFunc(register Tile *tile, /* source tile  */
		   Plane *dstPlane)     /* dest plane */ 
                    		
{
    Rect r; 

    r.r_xbot = roundDown(LEFT(tile), lRes);
    r.r_ybot = roundDown(BOTTOM(tile), lRes);
    r.r_xtop = roundUp(RIGHT(tile), lRes);
    r.r_ytop = roundUp(TOP(tile), lRes);

#ifdef HIDE
    r.r_xbot = roundNearest(LEFT(tile), lRes);
    r.r_ybot = roundNearest(BOTTOM(tile), lRes);
    r.r_xtop = roundNearest(RIGHT(tile), lRes);
    r.r_ytop = roundNearest(TOP(tile), lRes);

    /* don't let subpixel rects disappear */
    if(r.r_xbot == r.r_xtop)
    {
      if(LEFT(tile) < r.r_xbot)
      {
	r.r_xbot -= lRes;
      }
      else
      {
	r.r_xtop += lRes;
      }
    }

    if(r.r_ybot == r.r_ytop)
    {
      if(BOTTOM(tile) < r.r_ybot)
      {
	r.r_ybot -= lRes;
      }
      else
      {
	r.r_ytop += lRes;
      }
    }
#endif

    /* clip to area being generated */
    GEOCLIP(&r,lArea);

    DBPaintPlane(dstPlane, 
		 &r, 
		 DBStdPaintTbl(DBgetTileType(tile), lPlaneNum), 
		 NULL); /* no undo */

    return 0;
}

void static
layCoarseGenPlaneArea(CellDef *def,
		      int planeNum, /* paint plane number */
		      Coarse *c,    /* coarse struc we are regenerating */
		      Rect *area,   /* area to regenerate */  
		      bool lastSet) /* coarsest plane being generated? */
{
  Rect searchArea;
  Plane *src; 
  Plane *dst = c->c_planes[planeNum];
  int res = c->c_res;
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;

  ASSERT(!(c->c_flags[planeNum] & CFLG_COPY),"layCoarseGenPlaneArea");

  if(c->c_prev) 
  {
    src = c->c_prev->c_planes[planeNum];
  }
  else
  {
    src = def->cd_planes[planeNum];
  }

  /* adjust search area to include all paint that could impact area 
   * in dst plane.
   */
  if(GEO_SAMERECT(*area,TiPlaneRect))
  {
    searchArea = TiPlaneRect;
  }
  else
  {
    searchArea.r_xbot = roundDown(area->r_xbot, res);
    searchArea.r_ybot = roundDown(area->r_ybot, res);
    searchArea.r_xtop = roundUp(area->r_xtop, res);
    searchArea.r_ytop = roundUp(area->r_ytop, res);
  }

  /* pass parameters to func */
  lRes = res;
  lPlaneNum = planeNum;
  lArea = area;

  /* do the deed */
  {
    int before = TiPlaneNumTiles(dst);

    DBPlaneEnumAreaPaint(NULL, 
			 src,
			 &searchArea, 
			 &DBAllButSpaceBits,
			 layCoarsePaintFunc, 
			 (ClientData) dst);

    cdb->cdb_totTiles[planeNum] += (TiPlaneNumTiles(dst) - before);
  }

  /* prune 'redundant' planes and keep within memory budget */
  layCoarsePrune(def,
		 c, 
		 planeNum,
		 lastSet);
}

/*
 * ----------------------------------------------------------------------------
 * layCoarseNew --
 *
 * Generate "coarse" struct for given planes at given resolution.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarseNew(CellDef *def,
	     Plane **src, 
	     int res, /* resolution of coarse version */
	     bool lastSet)  /* set if last set to be generated now */
{
  Coarse *c;
  int planeNum;
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  Coarse *last = cdb->cdb_last;

  /*
  fprintf(stderr,"DEBUG layCoarseNew, def=%s lastSet=%d\n",
	  def->cd_name, lastSet);
  */

  /* allocate and link */
  MALLOC(Coarse *, c, sizeof(Coarse));
  c->c_res = res;
  c->c_next = NULL;
  c->c_prev = last;
  if(last) 
  {
    last->c_next = c;
  }
  else
  {
    cdb->cdb_coarse = c;
  }
  cdb->cdb_last = c;

  /* populate */
  for (planeNum = PL_DRC_ERROR; planeNum < DBNumPlanes; planeNum++)
  {
    c->c_planes[planeNum] = DBPlaneNew((ClientData) TT_SPACE);

    cdb->cdb_totTiles[planeNum] += TiPlaneNumTiles(c->c_planes[planeNum]);
    c->c_flags[planeNum] = 0;

    layCoarseGenPlaneArea(def, planeNum, c, &TiPlaneRect, lastSet);
  }
  return;
}

/*
 * ----------------------------------------------------------------------------
 * layCoarseInitDef --
 *
 * Initialize coarse database for given cell.
 *
 * (Gens first set of coarse planes) 
 *
 * ----------------------------------------------------------------------------
 */		 
void layCoarseInitDef(CellDef *def, 
		                     /* cell to init */
		      bool lastSet)            
{
  Rect *bbox = DBBBoxCellDef(def);
  CoarseDB *cdb; 
  int planeNum;

  ASSERT(!def->cd_coarseDB,"layCoarseInitDef");

  MALLOC(CoarseDB *, cdb, sizeof(CoarseDB));
  def->cd_coarseDB = (ClientData) cdb;

  cdb->cdb_last = NULL;

  cdb->cdb_update =  DBPlaneNew((ClientData) TT_SPACE);

  for (planeNum = PL_DRC_ERROR; planeNum < DBNumPlanes; planeNum++)
  {
    cdb->cdb_totTiles[planeNum] = 0;
    cdb->cdb_opsOrig[planeNum] = TiPlaneNumOps(def->cd_planes[planeNum]); 
    cdb->cdb_opsLast[planeNum] = cdb->cdb_opsOrig[planeNum];
  }

  layCoarseNew(def, def->cd_planes, layCoarseRes, lastSet);
}

/* update func */
static int layCoarseUpdatePlaneNum; /* used to pass planeNum to func */ 

static int
layCoarseUpdateClearFunc(register Tile *tile, /* update tile  */
			 CellDef *def)        /* def */ 
                    		
{
  Rect r;
  Coarse *c;
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  int planeNum = layCoarseUpdatePlaneNum;

  TiToRect(tile, &r);

  for (c= cdb->cdb_coarse; c; c=c->c_next)
  {
    Plane *plane = c->c_planes[planeNum];  
    int before;
    Rect r2;

    /* don't update copys! */
    if(c->c_flags[planeNum] & CFLG_COPY) continue;

    /* area impacted in coarse planes 
     * the +/- res is because we expand 0 width/height rects 
     */
    r2.r_xbot = roundNearest(r.r_xbot, c->c_res) - c->c_res;
    r2.r_ybot = roundNearest(r.r_ybot, c->c_res) - c->c_res;
    r2.r_xtop = roundNearest(r.r_xtop, c->c_res) + c->c_res;
    r2.r_ytop = roundNearest(r.r_ytop, c->c_res) + c->c_res;

    before = TiPlaneNumTiles(plane);
    DBPaintPlane(plane,
		 &r2, 
		 DBStdWriteTbl(TT_SPACE),  
		 NULL); /* no undo */
    cdb->cdb_totTiles[planeNum] += (TiPlaneNumTiles(plane) - before);
  }

  /* continue enumeration of update areas */
  return 0;
}

static int
layCoarseUpdateFunc(register Tile *tile, /* update tile  */
		    CellDef *def)        /* def */ 
                    		
{
  Rect r;
  Coarse *c;
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  int planeNum = layCoarseUpdatePlaneNum;

  TiToRect(tile, &r);

  for (c= cdb->cdb_coarse; c; c=c->c_next)
  {
    Rect r2;
    int numTiles;
    /* don't update copys! */
    if(c->c_flags[planeNum] & CFLG_COPY) continue;

    /* area impacted in coarse planes 
     * the +/- res is because we expand 0 width/height rects 
     */
    r2.r_xbot = roundNearest(r.r_xbot, c->c_res) - c->c_res;
    r2.r_ybot = roundNearest(r.r_ybot, c->c_res) - c->c_res;
    r2.r_xtop = roundNearest(r.r_xtop, c->c_res) + c->c_res;
    r2.r_ytop = roundNearest(r.r_ytop, c->c_res) + c->c_res;

    layCoarseGenPlaneArea(def, 
			  planeNum, 
			  c,  
			  &r2,
			  c==cdb->cdb_last); /* coarsest? */
  }

  /* continue enumeration of update areas */
  return 0;
}

/*
 * ----------------------------------------------------------------------------
 * LayCoarseUpdatePlane--
 *
 * Regenerate coarse plane in changed areas.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarseUpdatePlane(CellDef *def, int planeNum)
{
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  Plane *paint = def->cd_planes[planeNum];
  double tiles = TiPlaneNumTiles(paint);
  double ops =   TiPlaneNumOps(paint);
  double orig =   cdb->cdb_opsOrig[planeNum];
  double last =   cdb->cdb_opsLast[planeNum];

  /* if plane hasn't changed, skip update! */ 
  /* (Since active plane not simple, can change with out ops changing) */
  if(ops == last  && planeNum != DBPlaneActive) return;

  /*
  fprintf(stderr,"DEBUG layCoarseUpdatePlane def=%s plane=%s tiles=%g ops=%g last=%g orig=%g\n",
	  def->cd_name,
	  DBPlaneShortName(planeNum),
	  tiles,
	  ops,
	  last,
	  orig);
  */

  /* If massive changes, 
   * regenerate coarse planes from scratch.
   *
   * This provides a mechanism for restoring previously 
   * pruned planes.
   */
  if((ops - orig)/tiles >= layCoarseFlushFactor)
  {
    Coarse *c;

    /* fprintf(stderr,"DEBUG regen.\n"); */

    /* create empty coarse planes for this planeNum */ 
    cdb->cdb_totTiles[planeNum] = 0;
    for(c=cdb->cdb_coarse;c;c=c->c_next)
    {
      if(c->c_flags[planeNum] & CFLG_COPY)
      {
	c->c_planes[planeNum] = DBPlaneNew((ClientData) TT_SPACE);
	c->c_flags[planeNum] = 0;
      }
      else
      {
	DBPlaneClearPaint(c->c_planes[planeNum]);
      }

      cdb->cdb_totTiles[planeNum] += TiPlaneNumTiles(c->c_planes[planeNum]);
    }

    /* regenerate */ 
    for(c=cdb->cdb_coarse;c;c=c->c_next)
    {
      ASSERT(!(c->c_flags[planeNum] & CFLG_COPY),"layCoarseUpdatePlane");
      layCoarseGenPlaneArea(def, 
			    planeNum, 
			    c, 
			    &TiPlaneRect, 
			    c==cdb->cdb_last);
    }

    /* stash current op counts, so we can detect changes */
    cdb->cdb_opsOrig[planeNum] = ops;
    cdb->cdb_opsLast[planeNum] = ops;

    return;
  }

  /* pass planeNum to funcs */
  layCoarseUpdatePlaneNum = planeNum;

  /* Clear areas to be updated in all coarse planes.
   *  
   * This is done first to control data storage
   * highwater mark, and simplify pruning of coarse plane data.
   */
  DBPlaneEnumAreaPaint(NULL, 
		       cdb->cdb_update,
		       &TiPlaneRect, 
		       &DBAllButSpaceBits,
		       layCoarseUpdateClearFunc, 
		       (ClientData) def);

  /* regen changed areas */
  DBPlaneEnumAreaPaint(NULL, 
		       cdb->cdb_update,
		       &TiPlaneRect, 
		       &DBAllButSpaceBits,
		       layCoarseUpdateFunc, 
		       (ClientData) def);

  /* stash current op count, so we can detect changes */
  cdb->cdb_opsLast[planeNum] = ops;
}


/*
 * ----------------------------------------------------------------------------
 * LayCoarseUpdateDef--
 *
 * Regenerate coarse planes in changed areas.
 *
 * ----------------------------------------------------------------------------
 */		 
static void
layCoarseUpdateDef(CellDef *def)
{
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  int planeNum;

  SigDisableInterrupts();

  /* do the updates */
  for (planeNum = PL_DRC_ERROR; planeNum < DBNumPlanes; planeNum++)
  {
    layCoarseUpdatePlane(def,planeNum);
  }

  DBPlaneClearPaint(cdb->cdb_update);
  SigEnableInterrupts();
}



/*
 * ----------------------------------------------------------------------------
 * LayCoarseDelete --
 *
 * Delete coarse db for given def
 *
 * ----------------------------------------------------------------------------
 */		 
void
LayCoarseDelete(CellDef *def)
{
  Rect r;  
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  Coarse *c, *cnext;

  if(!cdb) return;

  DBPlaneClearPaint(cdb->cdb_update);
  TiFreePlane(cdb->cdb_update);

  for(c=cdb->cdb_coarse;c;c=cnext)
  {
    int planeNum;

    cnext = c->c_next;
  
    for (planeNum = PL_DRC_ERROR; planeNum < DBNumPlanes; planeNum++)
    {
      if(c->c_flags[planeNum] & CFLG_COPY) continue;
      DBPlaneClearPaint(c->c_planes[planeNum]);
      TiFreePlane(c->c_planes[planeNum]);
    }
    
    FREE(c);
  }

  FREE(cdb);

  def->cd_coarseDB = NULL;
}

/*
 * ----------------------------------------------------------------------------
 * LayCoarseChange --
 *
 * Mark changed area for recomputation of coarse db.
 * NULL area means recompute entire bbox.
 *
 *
 * ----------------------------------------------------------------------------
 */		 
void
LayCoarseChange(CellDef *def, Rect *area)
{
  Rect r;  
  CoarseDB *cdb = (CoarseDB *) def->cd_coarseDB;
  int grid= MAX(layCoarseRes,1)*10;

  if(!cdb) return;

  if(!area)
  {
    /* everything changed, delete coarse database for this def */
    LayCoarseDelete(def);
    return;
  }

  r.r_xbot = roundDown(area->r_xbot, grid);
  r.r_ybot = roundDown(area->r_ybot, grid);
  r.r_xtop = roundUp(area->r_xtop, grid);
  r.r_ytop = roundUp(area->r_ytop, grid);

  DBPaintPlane(cdb->cdb_update, 
	       &r,
	       DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
	       (PaintUndoInfo *) NULL);
}

/*
 * ----------------------------------------------------------------------------
 * LayCoarseFlush --
 *
 * Delete coarse planes for all defs.
 * ----------------------------------------------------------------------------
 */		 
void
layCoarseFlush(void)
{
  CellDef *def;

  for(def=DBCellDefs; def; def=def->cd_next) LayCoarseDelete(def);
}

/*
 * ----------------------------------------------------------------------------
 * layCoarsePlanes --
 *
 * Return set of paint planes appropraite for current display resolution
 *
 * ----------------------------------------------------------------------------
 */		 

static __inline__ bool layCoarseLastSet(int res, int coarseRes, int cellDiameter)
{
  return res <= coarseRes*layCoarseFactor || cellDiameter < coarseRes;
}
  
Plane **layCoarsePlanes(CellDef *def, int DBUnitsPerPixel)
{
  int cellDiameter;
  CoarseDB *cdb;
  Coarse *c;  
  Rect *bbox;
  int res = DBUnitsPerPixel * layRes; /* desired resolution */

  /* use real planes if coarsePlanes turned off, or resolution is too fine */
  if(layCoarseRes<0 || res < layCoarseRes)
  {
    return def->cd_planes;
  }

  /* compute cell dimensions */
  bbox = DBBBoxCellDef(def);
  cellDiameter = MIN(bbox->r_xtop - bbox->r_xbot, 
		     bbox->r_ytop - bbox->r_ybot);

  /* initialize coarseDB */
  if(!def->cd_coarseDB) 
  {
    bool lastSet = layCoarseLastSet(res,layCoarseRes,cellDiameter);
    layCoarseInitDef(def, lastSet);
  }
  cdb = (CoarseDB *) def->cd_coarseDB;

  /* update coarseDB */
  if(!DBPlaneEmptyQ(cdb->cdb_update)) layCoarseUpdateDef(def);

  /* find/gen planes of appropriate resolution */
  c = cdb->cdb_coarse;

  while(!layCoarseLastSet(res, c->c_res, cellDiameter))
  {
    /* gen coarser planes, if necessary */
    if(!c->c_next)
    {
      int cRes = c->c_res*layCoarseFactor;
      bool lastSet = layCoarseLastSet(res,cRes,cellDiameter);
      layCoarseNew(def, 
		   c->c_planes, 
		   cRes,
		   lastSet);
    }

    /* advance to next coarse planes */ 
    c=c->c_next;
    ASSERT(c,"layCoarsePlanes");
  }
  return c->c_planes;
}












