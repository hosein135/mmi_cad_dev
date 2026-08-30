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



/* layDisplayGen.c -
 *
 * General redisplay for layout widgets.
 * (see also layDisplay.c and layDisplayHL.c)
 * (low-level routines are in layDraw.c and layDraw.h) 
 *
 * The "interface" to redisplay is through the routines in layChanged.c: 
 * those routines mark areas for redisplay, and schedule layDisplay() (below)
 * to do the redisplay.
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
static char rcsid[]="$Header$";
#endif  not lint

#include <stdio.h>
#include <tk.h>
#include <X11/Xlib.h>
#include <X11/cursorfont.h>
#include "magic.h"
#include "utils.h"
#include "message.h"
#include "geometry.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "undo.h"
#include "signals.h"
#include "memory.h"
#include "main.h"
#include "select.h"
#include "selInt.h"
#include "layout.h"
#include "layint.h"
#include "graphics.h"
#include "layDraw.h"
#include "debug.h"

/* a round-up sort of integer division */
#define	ceilDiv(n,d)	( ((n) < 0)  ? -( ((-(n))+(d)-1) / d)  \
	: ((n)+(d)-1) / d )

static bool debugit = FALSE;

/* minimum  pixel dimension (in database units) for which 
 * zoomed out version of redisplay is done.
 *
 * initialized in layDisplayInit()
 * linked to tcl var LAY_PAINT_ZOT
 *
 * if = 0, always uses zoomed out redisplay  
 * if very big , never uses zoomed out.
 */
int layPaintZOT;

/* max cell diameter in pixels that gets painted with single pixel value */
int laySinglePixelThreshold = 4;

/* if set, style groups are stippled (just before final write to window) during
 * zoomed out redisplay.
 */
bool layStippleGroups = FALSE;

/* max diameter cell that gets the "single pixel" treatment.  */
/* maximum subcell dimension that gets cached (in pixels),
 * linked to tcl var LAY_CACHE_MAX_DIM;
 *
 */
int layCacheMaxDim = 10000;  

/* If set, bboxes and text are displayed for unexpanded subcells (tcl-linked)*/
bool laySubcellShowUnexpanded = TRUE;

/* if set stipple method used for clearing on group 2 copies */
bool layCacheStippleMethod = TRUE;

/* used in layCache.c to restore original clip area after terminating 
 * pixmap diversion.
 */
Rect layDisplayAreaW;    /* clip area */

/* The following statics are just for convenience in talking between
 * the top-level redisplay routine and the lower-level redisplay
 * routines invoked during the recursive search.
 */
static Rect layDisplayAreaDB;	/* area being redisplayed */ 


static int disStyle;		/* Display style. */


TileTypeBitMask layLabelLayers;	/* Layers we are currently 
				 * displaying labels for 
				 * NOTE: referenced in layPixel.c as well. 
				 */


/*
 *-----------------------------------------------------------------------------
 *
 * layEnumChildrenNested --
 *
 * Similiar DBSrChildrenNested() but uses CellKid structure to visit all
 * children, rather than bplane based area search.  This is more efficient, 
 * if searching a large part of a def, and also groups together instances 
 * of same def.
 *
 * NOTE: this function is VERY inefficient for small search areas!
 *       use DBSrChildrenNested() for smaller areas!!!
 *
 * This func only calls expanded children relative to the xMask argument 
 *
 * The procedure is applied to each array element in each cell use.
 * The array elements are visited by varying the X coordinate fastest.
 *
 * The procedure should be of the following form:
 *	int
 *	func(scx, cdarg)
 *	    SearchContext *scx;
 *	    ClientData cdarg;
 *	{
 *	}
 *
 * Func normally returns 0.  If it returns 1 then the search is
 * aborted.  If it returns 2, then any remaining elements in the
 * current array are skipped.
 *
 * Results:
 *	0 is returned if the search terminated normally.  1 is
 *	returned if it was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *--------------------------------------------------------------------------1---
 */

static int layEnumChildrenNested(SearchContext *scx, 
			/* Pointer to search context specifying a cell use to
			 * search, an area in the coordinates of the cell's
			 * def, and a transform back to "root" coordinates.
			 * The area may have zero size.
			 */

				 int xMask,
                         /* if set to window mask, only invokes client func
			  * on expanded childern (in that window)
			  *
			  * set to zero to get all childern
			  */

				 int (*func) (/* ??? */), 
                  	/* Function to apply at every tile found */

				 ClientData cdarg)
                     	/* Argument to pass to function */
{
  CellKid *kid;
  CellDef *def = scx->scx_use->cu_def;

  /* read in cell if necessary */
  if (!DBReadCell(def)) return 0;

  /* make sure def is up-to-date, BUT DO NOT
   * adjust bbox of top use (to avoid changing cellPlane of parent,
   * since this can screw up a "parent" DBSrChildren() that is in progress
   *
   * NOTE: may no longer be an issue now that we are using bplanes for
   * the cellplanes?
   */
  (void) DBUpdate(def);

  for(kid = def->cd_kids; kid; kid=kid->ck_next)
  {
    CellUse *use;
    for(use=kid->ck_uses; use; use=use->cu_next)
    {
      SearchContext newScx;
      int xsep, ysep;

      if(!GEO_OVERLAP(&use->cu_bbox,&scx->scx_area)) continue;
      if(!DBIsExpand(use, xMask)) continue;
      newScx.scx_use = use;

      /* If not an array element, life is much simpler */
      if (!DBIsArray(use))
      {
	newScx.scx_x = 0;
	newScx.scx_y = 0;

	if (SigInterruptPending) return 1;

	/* do transforms */
	{
	  Transform tinv;

	  GEOINVERTTRANS(&use->cu_transform, &tinv);
	  GeoTransTrans(&use->cu_transform, &scx->scx_trans,
			&newScx.scx_trans);
	  GEOTRANSRECT(&tinv, &scx->scx_area, &newScx.scx_area);
	}

	/* call client func */
	if ((*func)(&newScx, cdarg) == 1) return 1;

	continue;
      }

      /* array use - index through it */
      {
	int xlo, xhi, ylo, yhi, xbase, ybase, xsep, ysep, clientResult;

	DBArrayOverlap(use, &scx->scx_area, &xlo, &xhi, &ylo, &yhi);

	xsep = (use->cu_xlo > use->cu_xhi) ? -use->cu_xsep : use->cu_xsep;
	ysep = (use->cu_ylo > use->cu_yhi) ? -use->cu_ysep : use->cu_ysep;

	for (newScx.scx_y = ylo;
	     newScx.scx_y <= yhi; 
	     newScx.scx_y++)
        {
	  for (newScx.scx_x = xlo;
	       newScx.scx_x <= xhi;
	       newScx.scx_x++)
	  {
	    int result;

	    if (SigInterruptPending) return 1;

	    /* do transforms */
	    {
	      int xbase, ybase;
	      Transform t, tinv;

	      xbase = xsep * (newScx.scx_x - use->cu_xlo);
	      ybase = ysep * (newScx.scx_y - use->cu_ylo);
	      GeoTransTranslate(xbase, ybase, &use->cu_transform, &t);
	      GEOINVERTTRANS(&t, &tinv);
	      GeoTransTrans(&t, &scx->scx_trans, &newScx.scx_trans);
	      GEOTRANSRECT(&tinv, &scx->scx_area, &newScx.scx_area);
	    }

	    /* call client func */
	    result = (*func)(&newScx, cdarg);
	    if (result == 1) return 1;
	    if (result == 2) goto skipArray;
	  } /* for each x */
	} /* for each y */
      skipArray: continue;
      } /* array case */
    } /* for each use */
  } /* for each kid */

  return 0;
}

/*
 *  ===== PAINT ===== 
 */


/*
 * ----------------------------------------------------------------------------
 *
 * layPaintFunc --
 *
 * 	draws a rectangle in a given style on the screen.
 *
 * Results:
 *	Always returns 0 to keep the search from aborting.
 *
 * Side effects:
 *	Clips and draws a paint tile.
 *
 * ----------------------------------------------------------------------------
 */
static int
layPaintFunc(register Tile *tile, 
                        	/* Tile to be redisplayed. */
	     TreeContext *cxp)

                     		/* From DBSearchPaint */
{
  RectFloat rw;
  Rect r, r2;
  register SearchContext *scx = cxp->tc_scx;

    /* Set graphics style */
    if( !layAllSame && !layDisplayIsEdit(scx))
    {
      /* not in edit cell, so use pale styles */
      layDrawStyle(disStyle+MAXTILESTYLES);
    }
    else
    {
      layDrawStyle(disStyle);
    }

    r.r_xbot = LEFT(tile);
    r.r_ybot = BOTTOM(tile);
    r.r_xtop = RIGHT(tile);
    r.r_ytop = TOP(tile);
    GeoTransRect(&scx->scx_trans, &r, &r2);
    layRectToWindow(layDisplayWindow, &r2, &rw);
    layDrawRect(&rw);
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * layPolygonFunc --
 *
 * 	Invoked during database search in layRedisplayArea()
 *	to draw a polygon on the screen.
 *
 * Results:
 *	Always returns 0 to keep the search from aborting.
 *
 * Side effects:
 *	makes X calls to draw a polygon
 *
 * ----------------------------------------------------------------------------
 */
static int
layPolygonFunc(SearchContext *scx, 
	       Polygon *poly,
	       ClientData cdarg)
{
    Rect r, r2;

    /* Set graphics style */
    if( !layAllSame && !layDisplayIsEdit(scx))
    {
      /* not in edit cell, so use pale styles */
      layDrawStyle(disStyle+MAXTILESTYLES);
    }
    else
    {
      layDrawStyle(disStyle);
    }

    /* transform to window coordinates and display */
    {
      int i;
      double coords[2000];
      double *coord; 
      int numPoints = poly->poly_size;

      ASSERT(numPoints<=1000,"layPolygonFunc");

      coord = coords;
      for(i=0; i<numPoints; i++)
      {
	PointFloat p;
	PointFloat pScreen;

	GeoTransPointF(&scx->scx_trans, &poly->poly_points[i], &p);
	layPointFToWindow(layDisplayWindow, &p, &pScreen);	
	*(coord++) = pScreen.pf_x;
	*(coord++) = pScreen.pf_y;
      }

      layDrawPolygon(numPoints, coords);
    }

    return 0;
}

/* layDisplayPaint --
 *
 *    Called by layDisplayGeneral() to draw paint and polygons in specified area.
 *
 *  Goes through all of the tile display styles.  For each
 *  style, if there are tiles that include that style, then
 *  finds and displays all the tiles.
 *
 */
static void layDisplayPaint(SearchContext *scx)
{
  int i;
  Layout *w = layDisplayWindow;

  /* loop through styles */
  for (i=0; i<MAXTILESTYLES; i++)
  {
    TileTypeBitMask layers;
    TileTypeBitMask *mask = LayStyleToTypes(i);
    int bitMask = w->lay_bitmask;
      
    TTMaskAndMask3(&layers, mask, &w->lay_visibleLayers);

    if (!TTMaskIsZero(&layers))
    {
      /* pass style to lower level routines */
      disStyle=i;
      
      DBSearchPaintNew(scx, 
		       &layers, 
		       bitMask,
		       layPaintFunc, 
		       layPolygonFunc,
		       NULL,
		       (ClientData) NULL,
		       DBSP_DEPENDENT_POLYGONS /* include dependent polygons */);
    }
  }
}

/* layDisplayPaintZO --
 *
 *   Called by layDisplayArea() to draw paint and polygons in specified area,
 *   used when zoomed way out.
 *
 *  Searches cell hierarchy once for each style group (normally two groups)
 *  and displays styles for
 *  each subcell (deepest first).  This saves alot of overhead in designs
 *  with lots of subcells (particularly unexpanded ones) at the cost
 *  of not always painting styles in the "right" order.
 */

/* helper func (displays one style group)
 * calls itself recursively for subcells 
 */
static int layDisplayPaintZOFunc(SearchContext *scx, ClientData cData)
{
  int style;
  LayoutCache *cache;
  TreeContext context;
  Plane **paintPlanes; 
  CellDef *def = scx->scx_use->cu_def;
  int bitMask = layDisplayWindow->lay_bitmask;
  StyleGroup *styleGroup = (StyleGroup *) cData;

  Rect rootBBoxDB; /* use bbox in DB coordinates */
  Rect areaDB;     /* area to redisplay in DB coordinates */
  Rect relAreaDB;  /* area to redisplay relative to lower left corner
		    * of use
		    */
  RectFloat rootBBox; /* bbox in pixel coordinates (clipped to window) */
  
  /* save framing info here when changing frame to new pixmap */
  Rect saveDBArea;

  int retCode = 0;

  /* cell expanded ? */
  if (!DBIsExpand(scx->scx_use, bitMask)) return 0;

  /* DEBUG
  fprintf(stderr,"layDisplayPaintZOFunc, DEBUG def=%s id=%s, group=%d\n",
	  def->cd_name, scx->scx_use->cu_id, styleGroup->sg_number);
  */

  /* read in cell if necessary */
  if (!DBReadCell(def)) return 1;
  
  /* use bbox */
  GEOTRANSRECT(&scx->scx_trans, &def->cd_bbox, &rootBBoxDB);
  layRectToWindow(layDisplayWindow, &rootBBoxDB, &rootBBox);

  /* area to be redisplayed */
  areaDB = rootBBoxDB;
  GeoClip(&areaDB, &layDisplayAreaDB);

  /* if null area, just return */
  if(areaDB.r_xbot >= areaDB.r_xtop || areaDB.r_ybot >= areaDB.r_ytop) return 0;

  /* special case subcells only a few pixels in diameter */
  if(rootBBox.rf_xtop - rootBBox.rf_xbot <= laySinglePixelThreshold && 
     rootBBox.rf_ytop - rootBBox.rf_ybot <= laySinglePixelThreshold)
  {
    RectFloat area; /* redisplay area in pixel coordinates */
    int color = layPixelGet(def, styleGroup->sg_number);
    if(!color) return 0;
    layRectToWindow(layDisplayWindow, &areaDB, &area);
    layDrawPixels(&area, color, NULL); 
    return 0;
  }

  /* area to be redisplayed relative to use bbox */
  relAreaDB.r_xbot = areaDB.r_xbot - rootBBoxDB.r_xbot;
  relAreaDB.r_ybot = areaDB.r_ybot - rootBBoxDB.r_ybot;
  relAreaDB.r_xtop = areaDB.r_xtop - rootBBoxDB.r_xbot;
  relAreaDB.r_ytop = areaDB.r_ytop - rootBBoxDB.r_ybot;

  /* DEBUG
  DumpRect("layDisplayAreaDB", &layDisplayAreaDB);
  DumpRect("rootBBoxDB ", &rootBBoxDB);
  DumpRect("areaDB ", &areaDB);
  DumpRectF("rootBBox", &rootBBox);
  */

  /* look up in pixmap cache */
  if(cache=layCacheLookup(def, &scx->scx_trans, styleGroup, &relAreaDB))
  {
    /* Hit! Just copy cached pixmap and return */
    layCacheCopy(cache, &rootBBoxDB, &relAreaDB);

    return 0;
  }

  /* try cacheing */
  if(layDisplayWindow->lay_rootUse->cu_def != def || 
     (styleGroup->sg_stippleDimRev && layStippleGroups)) 
  {
    /* returns NULL, if non cacheable (e.g. 0 width), or too big */
    cache = layCacheNew(def, 
			&scx->scx_trans, 
			styleGroup, 
			&relAreaDB);
  }

  /* if cacheing, adjust DB -> Window transform for pixmap */
  if(cache)
  {
    Layout *w = layDisplayWindow;

    /* save DB -> Window transform */
    saveDBArea = w->lay_dbArea;

    /* adjust DB -> Window transform to pixmap */
    w->lay_dbArea = areaDB;

/* DEBUG
    {
      Rect r;
      Rect r2;
      DumpRect("areaDB", &areaDB);
      DumpRect("w->lay_dbArea", &w->lay_dbArea);
      DumpRect("cache->lc_area", &cache->lc_area);
      layRectToWindow(w, &areaDB, &r);
      DumpRect("areaDB -> pixmap coordinates", &r);
    }
*/

  }

  /*
  DumpRect("layDisplayAreaDB: ",&layDisplayAreaDB);
  DumpRect("rootBBoxDB: ",&rootBBoxDB);
  */

  /* apply ourselves recursively to children */
  if(scx->scx_use->cu_def->cd_kids)
  {
    Rect *bbox = &scx->scx_use->cu_def->cd_bbox;
    Rect search = scx->scx_area;
    
    GEOCLIP(&search,bbox);

    if(GEO_AREA(&search)/GEO_AREA(bbox) > .05 )
    {
      /* We are displaying more than 5% of the cell,
       * use kid strucs to enumerate subcells, 
       * (rather than area search).
       *
       * This avoids bplane overhead and groups
       * together subcells of the same def, making image cache copying
       * efficient.
       */
      if (layEnumChildrenNested(scx, 
				bitMask,
				layDisplayPaintZOFunc, 
				(ClientData) styleGroup))
      {
	retCode = 1;  /* interrupted */
      }
    }
    else
    {
      /* do area search */
      if (DBSrChildrenNested(scx, 
			     layDisplayPaintZOFunc, 
			     (ClientData) styleGroup))
      {
	retCode = 1;  /* interrupted */
      }
    }
  } /* if kids */

  /* if cacheing root cell, apply stipple, pop cache, and do the copy */
  if(cache && layDisplayWindow->lay_rootUse->cu_def == def)
  {
    void * stipple = layAllSame ? 
      styleGroup->sg_stippleRev : styleGroup->sg_stippleDimRev;

    /* revert DB -> Window transform */
    layDisplayWindow->lay_dbArea = saveDBArea;

    /* do the stippling */
    if(stipple)
    {
      GrSetWriteMask(GrMaskAll);
      GrSetColor(0); 
      GrSetStipple(stipple); 
      layCacheAdjustStippleOffset(&rootBBoxDB, &relAreaDB);

      GrFillRect(cache->lc_area.r_xbot, 
		 cache->lc_area.r_ybot, 
		 cache->lc_area.r_xtop, 
		 cache->lc_area.r_ytop);

      GrSetStipple(NULL); 
      GrDefaultStippleOrigin();
    }

    layCachePop();

    /* copy */
    layCacheCopy(cache, &rootBBoxDB, &relAreaDB);

    /* clear cache for rootcell to avoid reuse
     * since cache element does not contain paint in cell itself!
     */
    layCacheClear(def);

    cache = NULL;      
  }
  if(retCode) goto done;

  /**** PAINT THIS DEF ****/
  /* pass scx to paintFunc */
  context.tc_scx = scx;      

  /* pick appropriate paint planes for current resolution */
  paintPlanes = layCoarsePlanes(def,layDBUnitsPerPixel);

  /* if first group and orthogonal, we can use pixelOr to blend perfectly
   * with preexisting paint.
   */
  if(styleGroup->sg_number == 1 && styleGroup->sg_orthogonal)
  {
    GrSetFunction(GRFUNC_OR); 
  }

  for (style=0;  style<MAXTILESTYLES;  style++)
  {
    int planeNum;
    TileTypeBitMask visTypes;
    TileTypeBitMask *types;

    /* is this style in the current group? */
    if(!layStyleInGroup(style,styleGroup)) continue;
    
    /* visTypes = types to be drawn in this style that are visible in window */
    types = LayStyleToTypes(style);
    TTMaskAndMask3(&visTypes, types, &layDisplayWindow->lay_visibleLayers);
      
    if (TTMaskIsZero(&visTypes)) continue;
    
    /* pass style to lower level routines */
    disStyle=style;
      
    /* enumerate planes containing visible types */
    {
      PlaneList *visPlanes = DBPlaneListFromTypes(&visTypes);
      PlaneList *pll;


      for(pll = visPlanes;
	  pll;
	  pll = pll->pll_next)
      {
	if (DBPlaneEnumAreaPaint(NULL, 
				 paintPlanes[pll->pll_num],
				 &scx->scx_area, 
				 &visTypes,
				 layPaintFunc, 
				 (ClientData) &context))
	{
	  /* interrupted */
	  PlaneListFree(visPlanes);
	  goto done;
	}
      }
      PlaneListFree(visPlanes);
    }

    /* polygons */
    {
      Polygon *poly;

      for (poly = def->cd_polygons; poly; poly = poly->poly_next)
      {
	if (!GEO_OVERLAP(&poly->poly_bbox, &scx->scx_area)
	    || !TTMaskHasType(&visTypes, poly->poly_type)) continue;

	if (layPolygonFunc(scx, poly, NULL)) goto done;
      }
    }
  }

  /*** terminate any diversion to cache and return ***/
done:

  /* restore Pixel combination func to default of "copy" */
  GrSetFunction(GRFUNC_COPY);

  /* if cacheing, stop diversion, and copy buffer to previous drawable 
   */

  if(cache)
  {
    layCachePop();

    /* revert DB -> Window transform */
    layDisplayWindow->lay_dbArea = saveDBArea;

    /* copy */
    layCacheCopy(cache, &rootBBoxDB, &relAreaDB);
  }

  return retCode;
}

static void layDisplayPaintZO(SearchContext *scx) 
{
  StyleGroup *sGroup;

  /* descend hierarchy once for each style group in turn */
  for(sGroup = layStyleGroups; 
      sGroup != NULL; 
      sGroup = sGroup->sg_next)
  {
    layDisplayPaintZOFunc(scx, (ClientData) sGroup);
  }
}

/*
 *  ===== GRID ===== 
 */
int layGridOriginRadius = 4; /* default to 4 pixels  */
int layGridPointDiameterFine = 0; /* default to grid lines instead of points */
int layGridPointDiameterCoarse = 0;/* default to grid lines instead of points */
int layGridMinPixelPitchFine = 4; /* theshold for displaying fine grid */
int layGridMinPixelPitchCoarse = 4; /* theshold for displaying coarse grid */

/* helper func, does most of the work for layDisplayGrid() */
static void layDisplayGridLines(Rect *rect, 
				    /* Defines origin and pitch of grid */ 
				int style,  
				    /* Display style to use */
				int minPixelPitch) 
                                    /* don't display if too dense */
{
  Layout *w = layDisplayWindow;
  Rect *rootArea = &layDisplayAreaDB;
  int xsize = rect->r_xtop - rect->r_xbot; 
  int ysize = rect->r_ytop - rect->r_ybot;

  /* skip if too dense */
  if(layDimToWindow(w,xsize) < minPixelPitch ||
     layDimToWindow(w,ysize) < minPixelPitch) return;

  /* setup style */
  layDrawStyle(style);
    
  /* draw vertical lines */
  {
    int x;
    Rect r = *rootArea;

    for (x = rootArea->r_xbot - mod(rootArea->r_xbot,xsize) + mod(rect->r_xbot,xsize);
	 x <= rootArea->r_xtop; 
	 x += xsize)
    {
      RectFloat rw;
      r.r_xbot = x;
      r.r_xtop = x;
      layRectToWindow(w, &r, &rw);
      layDrawLine(rw.rf_xbot, rw.rf_ybot, rw.rf_xtop, rw.rf_ytop);
    }
  }

  /* draw horizontal lines */
  {
    int y;
    Rect r = *rootArea;

    for (y = rootArea->r_ybot - mod(rootArea->r_ybot,ysize) + mod(rect->r_ybot,ysize);
	 y <= rootArea->r_ytop; 
	 y += ysize)
    {
      RectFloat rw;
      r.r_ybot = y;
      r.r_ytop = y;
      layRectToWindow(w, &r, &rw);
      layDrawLine(rw.rf_xbot, rw.rf_ybot, rw.rf_xtop, rw.rf_ytop);
    }
  }
}

/* helper func, does most of the work for layDisplayGrid() */
static void layDisplayGridPoints(Rect *rect, 
				    /* Defines origin and pitch of grid */ 
				 int style,  
				    /* Display style to use */
				 int minPixelPitch, 
				    /* don't display if too tight */
				 int diameter) 
                                    /* size of dots */
{
  double deltaMinus, deltaPlus;
  Layout *w = layDisplayWindow;
  int xsize = rect->r_xtop - rect->r_xbot; 
  int ysize = rect->r_ytop - rect->r_ybot;
  int x,y;
  Rect area;
  Rect r;

  /* compute deltas for dot rects */ 
  {
    int rad = diameter/2;
    deltaMinus = rad;
    deltaPlus = diameter - rad;
  }

  /* skip if too dense */
  if(layDimToWindow(w,xsize) < minPixelPitch ||
     layDimToWindow(w,ysize) < minPixelPitch) return;


  /* expand root area by amount grid "points" can stick out. */
  {
    int deltaDB = layDimWToDBF(w, deltaPlus) + 1;

    GEO_EXPAND(&layDisplayAreaDB, deltaDB, &area);
  }

  /* setup style */
  layDrawStyle(style);

  /* draw dot array */ 
  for (x = area.r_xbot 
	 - mod(area.r_xbot,xsize)
	 + mod(rect->r_xbot,xsize);
       x <= area.r_xtop; 
       x += xsize)
  {
    r.r_xbot = x;
    r.r_xtop = x;

    for (y = area.r_ybot + 
	 - mod(area.r_ybot,ysize)
	 + mod(rect->r_ybot,ysize);
	 y <= area.r_ytop; 
	 y += ysize)
    {
      RectFloat rw;

      r.r_ybot = y;
      r.r_ytop = y;

      layRectToWindow(w, &r, &rw);

      rw.rf_xbot -= deltaMinus;
      rw.rf_xtop += deltaPlus;
      rw.rf_ybot -= deltaMinus;
      rw.rf_ytop += deltaPlus;

      layDrawRect(&rw);
    }
  }
}

/* layDisplayGrid --
 *
 *  Called by layDisplayArea() to redisplay grids (if on).
 *  Includes redisplaying edit cell origin.
 *
 *  NOTE:  Currently grid is redisplayed over entire screen each time!  
 *         TODO: fix this.
 *
 */

static void layDisplayGrid()
{ 
  Layout *w = layDisplayWindow;

  /* fine grid */
  if (w->lay_flags & Lay_GRIDFINE) 
  {
    if(layGridPointDiameterFine > 0)
    {
      layDisplayGridPoints(&w->lay_gridFineRect, 
			   STYLE_GRID_FINE, 
			   layGridMinPixelPitchFine,
			   layGridPointDiameterFine);
    }
    else
    {
      layDisplayGridLines(&w->lay_gridFineRect, 
			  STYLE_GRID_FINE,
			  layGridMinPixelPitchFine);
    }
  } 

  /* coarse grid */
  if (w->lay_flags & Lay_GRIDCOARSE)
  {
    if(layGridPointDiameterCoarse > 0)
    {
      layDisplayGridPoints(&w->lay_gridCoarseRect, 
			   STYLE_GRID_COARSE,
			   layGridMinPixelPitchCoarse,
			   layGridPointDiameterCoarse); 
    }
    else
    {    
      layDisplayGridLines(&w->lay_gridCoarseRect, 
			  STYLE_GRID_COARSE,
			  layGridMinPixelPitchCoarse);
    }
  }

  /* draw edit cell origin 
   * 
   * place a square around the origin for the edit cell
   * (if the edit cell is in this window). 
   */
  if (w->lay_flags&(Lay_GRIDFINE | Lay_GRIDCOARSE) && layEditDef != NULL )
  {
    Point originEdit, originRoot;
    RectFloat rW; 

    /* compute origin rect in pixel coordinates */
    originEdit.p_x = 0;
    originEdit.p_y = 0;
    GeoTransPoint(&EditToRootTransform, &originEdit, &originRoot);
    layPointToWindow(w, &originRoot, &rW.rf_ll);
    rW.rf_ur = rW.rf_ll;
    GEO_EXPANDF(&rW, layGridOriginRadius, &rW);

    /* draw it */
    layDrawStyle(STYLE_GRID_ORIGIN);
    layDrawRect(&rW);
  }
}

/*
 *  ===== LABELS ===== 
 */

/*
 * ----------------------------------------------------------------------------
 *
 * layExpandedDBArea--
 *
 *  Expand area (in database coords) enough to overlap any labels
 *  that might have text sticking into the original area.
 *
 *  Returns: 
 *    the expanded rect.
 *
 * NOTE:
 * The code that draws labels keeps track of the 
 * maximum size (in pixels) that label text sticks out (in each direction)
 * in the  window.  We expand by these "expand amounts" here.
 *
 * ----------------------------------------------------------------------------
 */
static Rect layExpandedDBArea(Layout *w, 
			      Rect *r)
                                       /* initial area in database coords */
{
    Rect result = *r;

    /* now do the expansion */
    if (layPixelsPerDBUnit > 0)
    {
      result.r_xtop -=  ceilDiv(w->lay_labelExtents.r_xbot, layPixelsPerDBUnit);
      result.r_ytop -=  ceilDiv(w->lay_labelExtents.r_ybot, layPixelsPerDBUnit);
      result.r_xbot -=  ceilDiv(w->lay_labelExtents.r_xtop, layPixelsPerDBUnit);
      result.r_ybot -=  ceilDiv(w->lay_labelExtents.r_ytop, layPixelsPerDBUnit);
    }
    else
    {
      result.r_xtop -=  w->lay_labelExtents.r_xbot * layDBUnitsPerPixel;
      result.r_ytop -=  w->lay_labelExtents.r_ybot * layDBUnitsPerPixel;
      result.r_xbot -=  w->lay_labelExtents.r_xtop * layDBUnitsPerPixel;
      result.r_ybot -=  w->lay_labelExtents.r_ytop * layDBUnitsPerPixel;
    }

    /* make sure  we have an area, not just a point */
    result.r_xtop = MAX(result.r_xtop, result.r_xbot + 1);
    result.r_ytop = MAX(result.r_ytop, result.r_ybot + 1);

    return result;
}

/* layDisplayLabelsFunc -
 *
 * Displays labels in cell,
 * and calls itself recursively for subcells.
 *
 */
static int
layDisplayLabelsFunc(SearchContext *scx, ClientData notUsed)
{
  CellDef *def = scx->scx_use->cu_def;
  int bitMask = layDisplayWindow->lay_bitmask;
  RectFloat loc; /* subcell bbox in window coordinates */

  /*
  fprintf(stderr,"layDisplayLabelsFunc, TOP.\n");
  */

  /* cell expanded ? */
  if (!DBIsExpand(scx->scx_use, bitMask)) return 0;

  /* read in cell if necessary */
  if (!DBReadCell(def)) return 1;

  /* convert use bbox to pixel coordinates */
  {
    Rect temp1, temp2;
    
    GEOTRANSRECT(&scx->scx_trans, &def->cd_bbox, &temp1);
    GeoCanonicalRect(&temp1, &temp2);
    layRectToWindow(layDisplayWindow, &temp2, &loc);

  }

  /* special case subcells only a few pixels in diameter (when zoomed out) */
  if(loc.rf_xtop -loc.rf_xbot <= laySinglePixelThreshold && 
     loc.rf_ytop - loc.rf_ybot <= laySinglePixelThreshold &&
     layDBUnitsPerPixel>=layPaintZOT)
  {
    /* Don't bother with labels for single pixel subcells! 
     *  layDrawPixels(&loc, layPixelGet(def, PV_LABEL, NULL));
     */
    return 0;
  }

  /* apply ourselves recursively to children */
  if (DBSrChildrenNested(scx, 
			 layDisplayLabelsFunc, 
			 (ClientData) NULL)) 
  {
    /* interrupted */
    return 1;
  }

  /* display labels in this cell */
  {
    Label *lab;
    TileTypeBitMask *mask = &layLabelLayers;  /* visible and space layers */
    Rect *r = &scx->scx_area;
    bool isEdit, showComments; 

    /* show local labels only if this is the edit cell */
    isEdit = layDisplayIsEdit(scx);
    showComments = isEdit || layDisplayWindow->lay_flags & Lay_LABELSNONEDIT; 

    /* set style */
    layDrawStyle((isEdit || layAllSame) ? STYLE_LABEL : STYLE_LABEL_DIM);

    for (lab = def->cd_labels; lab; lab = lab->lab_next)
    {
      if( !GEO_OVERLAP(&lab->lab_rect, r) ) continue;
      if( !TTMaskHasType(mask, lab->lab_type) ) continue;
      if((lab->lab_kind == LAB_HIDDEN) && 
	 !(layDisplayWindow->lay_flags & Lay_SEEHIDDENLABELS)) continue;
      if((lab->lab_kind == LAB_COMMENT || lab->lab_kind == LAB_LOCAL) 
	 && !showComments) continue;

      /* do the deed */
      layDisplayLabel(lab, &scx->scx_trans, FALSE /* not selection redisplay */); 
    }
  }

  return 0;
}

/* layDisplayLabels --
 *
 * Called by layDisplayGeneral() to redisplay labels impinging on
 * redisplay area.
 */
static void
layDisplayLabels(SearchContext *scx)
{
  Layout *w = layDisplayWindow;
  Rect *rootArea = &layDisplayAreaDB;

  /* if label display turned off, just return */ 
  if (!(w->lay_flags&Lay_SEELABELS)) return;

  /* if zoomed out too far too see labels, just return */
  if(w->lay_labelMarkSize <= 0 &&
     w->lay_labelSize < 0 &&
     DBLabelMaxDim * w->lay_pixelsPerDB < 1) return;

  /* set up context */
  TTMaskSetMask3(&layLabelLayers, &DBSpaceBits, &w->lay_visibleLayers);

  /* display labels cell by recursive cell */
  layDisplayLabelsFunc(scx, NULL);
}

/*
 *  ===== UNEXPANDED SUBCELLS ===== 
 */


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayUnexpandedSubcell --
 *
 * 	Called by database searching routines during redisplay.
 *      The caller should have already set the style information.
 *
 * Results:
 *	Always returns 0 to keep the search from aborting.
 *
 * Side effects:
 *	The bounding box of the cell is clipped and drawn on the screen,
 *	along with the name, id of the celluse and ports.
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ int
layDisplayUnexpandedSubcell(SearchContext *scx,
			    RectFloat *loc)
                                        /* bbox in window coordinates */
{
  /*
    fprintf(stderr,"DEBUG, layDisplayUnexpandedSubcell %s  TOP\n",
	    scx->scx_use->cu_id);
  */

    /* display bbox */
    layDrawRect(loc);

    /* display cell text */
    if ((loc->rf_xtop-loc->rf_xbot >= layMinSubcellText.p_x) &&
	(loc->rf_ytop-loc->rf_ybot >= layMinSubcellText.p_y))
    {
      layDisplaySubcellText(scx, 
			    loc, 
			    layDisplayWindow->lay_flags & Lay_SEEINSTANCENAMES,
			    layDisplayWindow->lay_flags & Lay_SEEINSTANCEPORTS);
    }

    return 0;
}

/* layDisplayUnexpandedSubcellsFunc -
 *
 * Displays unexpanded subcells in cell,
 * and calls itself recursively for expaned subcells.
 *
 */
static int
layDisplayUnexpandedSubcellsFunc(SearchContext *scx, ClientData cd)
{
  int style = (int) cd;
  CellDef *def = scx->scx_use->cu_def;
  int bitMask = layDisplayWindow->lay_bitmask;
  RectFloat loc; /* subcell bbox in window coordinates */

  /* convert use bbox to pixel coordinates */
  {
    Rect temp1, temp2;

    GEOTRANSRECT(&scx->scx_trans, &def->cd_userBBox, &temp1);
    GeoCanonicalRect(&temp1, &temp2);
    layRectToWindow(layDisplayWindow, &temp2, &loc);
  }

  /* if unexpanded, display it and we are done */
  if (!DBIsExpand(scx->scx_use, bitMask))
  {
    /* display it! */
    layDrawStyle(style);
    layDisplayUnexpandedSubcell(scx, &loc);
    return 0;
  }

  /* read in cell if necessary */
  if ((def->cd_flags & CD_AVAILABLE) == 0)
  {  
    if (!DBReadCell(def)) return 1;

    /* recompute bbox */
    {
      Rect temp1, temp2;
    
      GEOTRANSRECT(&scx->scx_trans, &def->cd_bbox, &temp1);
      GeoCanonicalRect(&temp1, &temp2);
      layRectToWindow(layDisplayWindow, &temp2, &loc);

    }
  }

  /* if no unexpanded descendents, we are done, and can just return
   * (THIS CAN SAVE ALOT OF TIME! FOR BIG DESIGNS) 
   * But, being careful not to force single pixel update when zoomed-in.
   */
  if((layPixelValid(def) || layDBUnitsPerPixel>=layPaintZOT) &&
     !layPixelGet(def, PV_SUBCELL)) return 0; 

  /* special case subcells only a few pixels across (when zoomed out) */
  if(loc.rf_xtop - loc.rf_xbot <= laySinglePixelThreshold && 
     loc.rf_ytop - loc.rf_ybot <= laySinglePixelThreshold)
  {
    int color = layPixelGet(def, PV_SUBCELL);
    if(!color) return 0;
    layDrawPixels(&loc, color, NULL);
    return 0;
  }

  /* apply ourselves recursively to children */

  /* set style appropriate for children */
  if (!layAllSame && !layDisplayIsEdit(scx))
  {     
    style = STYLE_UNEXPANDED_INSTANCE_DIM;
  }
  else
  {
    style = STYLE_UNEXPANDED_INSTANCE;
  }

  if (DBSrChildrenNested(scx, 
			 layDisplayUnexpandedSubcellsFunc, 
			 (ClientData) style)) 
  {
    /* interrupted */
    return 1;
  }

  return 0;
}

/* layDisplayUnexpandedSubcells --
 *
 *  Called by layDisplayArea().
 *
 */    
static void layDisplayUnexpandedSubcells(SearchContext *scx)
{
  int style;

  /* compute display style suitable for children of root */
  if (!layAllSame && !layDisplayIsEdit(scx))
  {     
    style = STYLE_UNEXPANDED_INSTANCE_DIM;

  }
  else
  {
    style = STYLE_UNEXPANDED_INSTANCE;
  }

  /* display unexpanded subcells cell by recursive cell */
  layDisplayUnexpandedSubcellsFunc(scx, (ClientData) style);
}

/*
 *  ===== WATCH PLANE===== 
 */

#define	OFFSETS	12


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayWatchPlaneFunc --
 *
 * 	Called for each tile on watch plane (during ":*watch" debugging)
 *	redisplay.
 *
 * Results:
 *	Always returns 0 to keep the search from aborting.
 *
 * Side effects:
 *	Displays a tile's bounding box and corner stitches.
 *
 * ----------------------------------------------------------------------------
 */
static int
layDisplayWatchPlaneFunc(Tile *tile, ClientData notUsed)
               				/* A tile to be redisplayed. */
{
    Rect r;
    RectFloat rW;
    int flags = layDisplayWindow->lay_flags;

    /* get tile rect and clip to abit larger than window 
     * (to avoid problems at infinity)
     */
    TiToRect(tile, &r);
    GeoClip(&r, &layDisplayAreaDB);

    /* convert to window coords */
    layRectToWindow(layDisplayWindow, &r, &rW);

    /*** TILE OUTLINE ***/
    layDrawStyle(STYLE_WATCHED_TILE);
    layDrawRect(&rW);

    /*** TILE ID ***/
    {
      char string[BUFSIZ];
      PointFloat p;
      
      if (flags & Lay_SEETYPES)
      {
	sprintf(string, "%s",DBTypeShortName(DBgetTileType(tile)));
      }
      else if (flags & Lay_SEEGROUPS)
      {
	DBGroupTileTypes2S(string, BUFSIZ, tile);
      }
      else
      {
	sprintf(string, "%x", tile);
      }
    
      p.pf_x = (rW.rf_xbot + rW.rf_xtop)/2;
      p.pf_y = (rW.rf_ybot + rW.rf_ytop)/2;

      layTextDraw(string, 
		  &p, 
		  GEO_CENTER,
		  GR_TEXT_LARGE, 
		  FALSE, 
		  &rW, 
		  NULL);
    }

    return 0;
}

/* layDisplayWatchPlane --
 *
 *  Called by layDisplayGeneral().
 *  Redisplay watch plane (for :*watch debugging command) 
 *
 *  (Note watch plane info regenerated for entire window) 
 *
 */    
static void layDisplayWatchPlane(void)
{
  Layout *w = layDisplayWindow;

  if (w->lay_watchPlane < 0) return;

  DBPlaneEnumAreaPaint((Tile *) NULL,
		       w->lay_rootUse->cu_def->cd_planes[w->lay_watchPlane],
		       &layDisplayAreaDB,
		       &DBAllTypeBits,
		       layDisplayWatchPlaneFunc, 
		       (ClientData) NULL);
}

/*
 *  ===== TOP LEVEL =====
 */


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayGeneral --
 *
 * 	This procedure is invoked by layDisplay for each non space tile in
 *	the redisplay plane intersecting the window. 
 *
 *	General redisplay is done for the intersection between the tile 
 *      and the window, and the area is marked for highlight redisplay. 
 *
 * Results:
 *	Always returns 0 to keep the search from aborting.
 *
 * Side effects:
 *	Information is redisplayed on the screen.
 *
 * ----------------------------------------------------------------------------
 */

int
layDisplayGeneral(Tile *tile, 
               			/* Tile giving area to redisplay */
		  ClientData notUsed)
{
    Rect area; /* in pixel coords */
    Rect rootArea; /* area in rootcell coords */
    Rect expandedRootArea; /* rootArea expanded to include labels that 
			    * may have text sticking into area.
			    */
    SearchContext scx;
    Layout *w = layDisplayWindow;

    /* DEBUG
    fprintf(stderr,"DEBUG layDisplayGen, top root cell =%s\n",
	    w->lay_rootUse->cu_def->cd_name);
    */

    ASSERT(DBgetTileType(tile) != TT_SPACE,"layDisplayFunc");

    /* general redisplay saved in Pixmap, so that changes
     * to highlights do not invalidate it.
     */
    GrSetDrawable(w->lay_genOverlay);  

    /* clip area to window */
    TiToRect(tile, &area);            
    
    /* 
    DumpRect("DEBUG layDisplayGen, area in ",&area);
    */

    if (w->lay_watchPlane >= 0) 
    {
      /* need to redisplay entire window, during ":*watch" */
      area = w->lay_area; 	 
    }
    else
    {
      GeoClip(&area, &w->lay_area); 
    }

    /*
    DumpRect("DEBUG layDisplayGen, clipped area ",&area);
    */

    /* if empty area just return */
    if ((area.r_xbot > area.r_xtop) || (area.r_ybot > area.r_ytop)) return 0;

    /* convert to rootcell coords 
     * (search on this area guaranteed to yield everything impinging
     *  on pixel area).
     */
    layRectWToDB(w, &area, &rootArea); 

    /*
    DumpRect("DEBUG layDisplayGeneral full window area = ", &w->lay_area);
    DumpRect("DEBUG layDisplayGeneral window area = ", &area);
    DumpRect("DEBUG layDisplayGeneral db area = ", &rootArea);
    */

    /* compute expanded rootArea, big enough to include any labels with text
     * extending into original area
     */
    expandedRootArea = layExpandedDBArea(w, &rootArea);

    /* set global context (used by subroutines) */  
    layDisplayAreaDB = rootArea;

    /*
    DumpRect("DEBUG layDisplayGeneral ++++ layDisplayAreaDB = ", 
	     &layDisplayAreaDB);
    */

    layDisplayAreaW = area;
    layDrawSetClip(&area,&w->lay_area);

    /* Setup scx (search context) */
    scx.scx_use = w->lay_rootUse;
    /*    scx.scx_x = scx.scx_y = -1; ??? */
    scx.scx_x = 0; 
    scx.scx_y = 0; 
    scx.scx_trans = GeoIdentityTransform;
    scx.scx_area = rootArea;

    /* erase previous contents of area */
    {
      RectFloat areaF;

      geoRect2RectF(&area, &areaF);

      layDrawStyle(STYLE_BACKGROUND);
      layDrawRect(&areaF);
    }

    /* redisplay paint (tiles and polygons) */
    if(layDBUnitsPerPixel >= layPaintZOT && 
       (!layStippleGroups || w->lay_rootUse == EditCellUse) &&                
       !(layDisplayWindow->lay_flags&Lay_SPECIAL))
    {
      /* zoomed out - do quick and dirty redisplay */ 
      layDisplayPaintZO(&scx); 
    }
    else
    {
      /* not zoomed out - be meticulous */
      layDisplayPaint(&scx);
    }

    layDisplayGrid(); 

    /* don't clip remaining stuff: 
     *   label text may protrude from area,
     *   and if we don't clip labels we can't clip overlying 
     *   unexpanded subcells.  Unexpanded subcells don't need
     *   clipping since they are topmost opaque layer!
     *
     *   NOTE BUT:  instance text is clipped to instance bboxes
     *
     */
    layDrawSetClip(NULL,&w->lay_area);

    /* we search expanded area so we redisplay text that extends into
     * rootArea from neighboring labels.
     *
     * also we don't clip, since text for new labels in this area may 
     * extend out of area.
     */
    scx.scx_area = expandedRootArea;

    layDisplayLabels(&scx);
    scx.scx_area = rootArea;

    if(laySubcellShowUnexpanded) layDisplayUnexpandedSubcells(&scx);

    /* redisplay watch plane (:*watch command for debugging) */
    if (w->lay_watchPlane >= 0) layDisplayWatchPlane();
 
   /* outline area just redisplayed (debug) */
    if (debugit)
    {
	RectFloat r;
	layRectToWindow(w, &scx.scx_area, &r);
	layDrawStyle(STYLE_LABEL);
	layDrawRect(&r);
    }

    /* copy from genOverlay to window */
    GrSetDrawable(layGraphicsWindow);
    GrSetWriteMask(GrMaskColor);  
    GrCopyPixmap(w->lay_genOverlay,
		 area.r_xbot, area.r_ybot,
		 area.r_xbot, area.r_ybot,
		 GEO_WIDTH(&area)+1,
		 GEO_HEIGHT(&area)+1);

    /* mark area for highlight redisplay */
    DBPaintPlane(w->lay_hlRedrawDB, 
		 &expandedRootArea,
		 DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
		 (PaintUndoInfo *) NULL);

    return 0;
}



