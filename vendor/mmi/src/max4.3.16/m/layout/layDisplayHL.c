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



/* layDisplayHL.c -
 *
 * Redisplay code for highlights (invoked from layDisplay())
 *
 * Highlights = ephemeral white stuff on top of layout such as box
 * and selection.  Highlights can be changed without having to redisplay
 * underlying layout.
 *
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

/*
 *  ===== ERASE =====
 */

/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLErase --
 *
 * 	This procedure is invoked by layDisplay() for each tile in highlight
 *	erase plane.
 *
 *	Clears Highlights in area.
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
layDisplayHLErase(Tile *tile, Layout *w)
               			/* Tile describing area to be erased. */
{
    Rect area;
    TiToRect(tile, &area);

    /* just copy area from genOverlay to window */
    GrCopyPixmap(w->lay_genOverlay,
		 area.r_xbot, area.r_ybot,
		 area.r_xbot, area.r_ybot,
		 GEO_WIDTH(&area)+1,
		 GEO_HEIGHT(&area)+1);


    /* continue search */
    return 0;
}

/*
 *  ===== BOX =====
 */


/*
 * ----------------------------------------------------------------------------
 *
 * LayDisplayHLBox --
 *
 * 	This procedure is called by LayDisplay() to
 *      to redraw the box in a given window.
 *
 *      ALSO called by layChangedBox() to mark box areas for later highlight
 *      redisplay.
 *
 *      modes: 
 *      ----
 *             LDB_DISPLAY - redisplay box.
 *             LDB_CHANGED - mark old box loc for redisplay.
 *
 *      NOTE: box redrawn in its entirity on every HIGHLIGHT redisplay, 
 *            so new box loc need not be explicitly marked for redisplay.
 *      
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

/* If both dimensions of box are <= to this # of pixels, a target is
 * drawn to help locate the box 
 */
int layBoxTargetThreshold = 4;

/* length in pixels of the arms of '+' marking a small box */
int layBoxHairEnd = 25;
int layBoxHairBegin = 7;

/* width of box sides in pixels */ 
int layBoxLineWidth = 2;

/* helper function:  display, or mark rect */
static __inline__ void boxRect(Layout *window, int mode, 
			       RectFloat *r) 
{
  switch(mode)
  {
    case LDB_DISPLAY:
      layDrawRect(r);
      break;

    case LDB_CHANGED:
    {
      RectFloat rWindow;
      RectFloat rClip;
      Rect rInt;

      /* clip to window to avoid overflow, and convert to ints */
      geoRect2RectF(&window->lay_area, &rWindow);
      rClip = *r;
      GEOCLIPF(&rClip, &rWindow);
      geoRectF2Rect(&rClip, &rInt);
    
      layChangedWindowHL(window, &rInt, TRUE /* erase */);
      break;
    }
  }
}

/* helper function:  display, or mark line */
static __inline__ void boxLine(Layout *window, 
			       int mode,
			       double x0, 
			       double y0, 
			       double x1, 
			       double y1)
{
  switch(mode)
  {
  case LDB_DISPLAY:
    layDrawLine(x0,y0,x1,y1);
    break;
  case LDB_CHANGED:
    {
      RectFloat r;
      Rect rInt;

      r.rf_xbot = MIN(x0,x1);
      r.rf_xtop = MAX(x0,x1);
      r.rf_ybot = MIN(y0,y1);
      r.rf_ytop = MAX(y0,y1);

      GEO_EXPANDF(&r, 1, &r);

      /* clip to window to avoid overflow, and convert to ints */
      {
	RectFloat rWindow;

	geoRect2RectF(&window->lay_area, &rWindow);
	GEOCLIPF(&r, &rWindow);
	geoRectF2Rect(&r, &rInt);
      
	layChangedWindowHL(window, &rInt, TRUE /* erase */);
      }
    }
    break;
  }
}

void
layDisplayHLBox(Layout *window, 
                      		/* Window in which to redraw box. */
		int mode)
                 		/* If LDB_DISPLAY - display box
				 * If LDB_CHANGED - mark changed box for erase.
				 */
{
    RectFloat box;
    RectFloat out, in;
    RectFloat side;
    double width, height;
    PointFloat center;

    /* get box */
    {
      CellDef *def;
      Rect rootArea1, rootArea2;

      ToolGetBox(&def, &rootArea1);

      /* Return if the box is not in the window */
      if (def != WINDOW_DEF(window)) return;

      /* make sure box is not inverted */
      GeoCanonicalRect(&rootArea1, &rootArea2);

      /* transform box from db to window coordinates */
      layRectToWindow(window, &rootArea1, &box);
    }

    /* clip to slightly bigger than 

    /* box measurements */
    width = floor(box.rf_xtop - box.rf_xbot);
    height = floor(box.rf_ytop - box.rf_ybot);
    center.pf_x = floor(box.rf_xbot + width/2);
    center.pf_y = floor(box.rf_ybot + height/2);

    layDrawStyle(STYLE_BOX);

    /* compute widened box boundaries (box is square donut!) */
    {
      double minus = floor(-((layBoxLineWidth-1)/2));
      double plus  = floor((layBoxLineWidth-1) + minus); 

      GEO_EXPANDF(&box, plus, &out);

      GEO_EXPANDF(&box, minus, &in);

      /* don't let interior boundary invert */
      in.rf_xbot = MIN(in.rf_xbot, center.pf_x);
      in.rf_xtop = MAX(in.rf_xtop, center.pf_x);
      in.rf_ybot = MIN(in.rf_ybot, center.pf_y);
      in.rf_ytop = MAX(in.rf_ytop, center.pf_y);
    }

    /* horizontals */
    side.rf_xbot = out.rf_xbot;
    side.rf_xtop = out.rf_xtop;

    side.rf_ytop = out.rf_ytop;
    side.rf_ybot = in.rf_ytop;
    boxRect(window, mode, &side); /* top */

    side.rf_ytop = in.rf_ybot;
    side.rf_ybot = out.rf_ybot;
    boxRect(window, mode, &side); /* bot */

    /* verticals */
    side.rf_ybot = in.rf_ybot;
    side.rf_ytop = in.rf_ytop;

    side.rf_xbot = out.rf_xbot;
    side.rf_xtop = in.rf_xbot;
    boxRect(window, mode, &side); /* left */

    side.rf_xbot = in.rf_xtop;
    side.rf_xtop = out.rf_xtop;
    boxRect(window, mode, &side); /* right */

    /* If box too small to spot easily, add a cross hair site */
    if(width<layBoxTargetThreshold && 
       height<layBoxTargetThreshold)
    {
      boxLine(window, mode, 
	      center.pf_x - layBoxHairEnd, center.pf_y,
	      center.pf_x - layBoxHairBegin, center.pf_y);

      boxLine(window, mode, 
	      center.pf_x + layBoxHairBegin, center.pf_y,
	      center.pf_x +  layBoxHairEnd, center.pf_y);

      boxLine(window, mode, 
	      center.pf_x, center.pf_y - layBoxHairEnd,
	      center.pf_x, center.pf_y - layBoxHairBegin); 

      boxLine(window, mode, 
	      center.pf_x, center.pf_y + layBoxHairBegin, 
	      center.pf_x, center.pf_y +  layBoxHairEnd);
    }
}

/*
 *  ===== FEEDBACK =====
 */

/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLFeedback --
 *
 * 	This procedure is called by layDisplay() to redraw
 *	feedback highlights.  
 *
 * Tricky stuff:
 *	Redisplay is numerically difficult, particularly when feedbacks
 *	have a large internal scale factor:  the tendency is to get
 *	integer overflow and get everything goofed up.  Be careful
 *	when making changes to the code below.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func */
static int layFeedbackAlways1(void) { return 1; }

void
layDisplayHLFeedback(Layout *window, 
                      		/* Window in which to redraw. */
		     Plane *plane)
                                /* non space tiles indicate
				 * areas where highlights need to be redrawn.
				 */
{
    Rect tmp;
    RectFloat areaDB, areaW;
    Feedback *fb;
    CellDef *windowRoot; 
    int i;

    if (LayFeedbackCount == 0) return;

    windowRoot = WINDOW_DEF(window);

    for (i = 0, fb = layfbArray; i < LayFeedbackCount; i++, fb++)
    {
        /* if not in this window, continue */
	if (fb->fb_rootDef != windowRoot) continue;

	/*
	 * Check to make sure this feedback area is relevant.
	 * Clip to TiPlaneRect to avoid overflow during DBPlaneEnumAreaPaint
	 */
	tmp = fb->fb_rootArea;
	GeoClip(&tmp, &TiPlaneRect);
	if(GEO_RECTNULL(&tmp)) continue;
	if (!DBPlaneEnumAreaPaint((Tile *) NULL, plane, &tmp,
		&DBAllButSpaceBits, layFeedbackAlways1, (ClientData) NULL))
	    continue;

	/* transform to root DB coordinates */
	{
	  double scale = 1.0 / fb->fb_scale;

	  areaDB.rf_xbot = fb->fb_area.r_xbot * scale;
	  areaDB.rf_ybot = fb->fb_area.r_ybot * scale;
	  areaDB.rf_xtop = fb->fb_area.r_xtop * scale;
	  areaDB.rf_ytop = fb->fb_area.r_ytop * scale;
	}
	
	/* transform to window coordinates */
	layRectFToWindow(window, &areaDB, &areaW);

	layDrawStyle(fb->fb_style);
	layDrawRect(&areaW);
    }
}


/*
 *  ===== SELECTION =====
 */

/* The following variable is shared between selRedisplay and the search
 * functions that it invokes.  It points to the plane indicating which
 * highlight areas must be redrawn.
 */
static Plane *selRedisplayPlane;

/* Function used to see if an area in the selection touches an area
 * that's to be redisplayed:  it just returns 1 always.
 */

int
selAlways1(void)
{
    return 1;
}

/* Redisplay function for selected paint:  draw lines to outline
 * material.  Only draw lines on boundaries between different
 * kinds of material.
 */

int
laySelRedisplayOutlineFunc(Tile *tile, 
               			/* Tile to be drawn on highlight layer. */
			   Layout *window)
                      		/* Window in which to redisplay. */
{
  Rect area;
  register Tile *neighbor;

  TiToRect(tile, &area);

  if (!DBPlaneEnumAreaPaint((Tile *) NULL, 
			    selRedisplayPlane, 
			    &area,
			    &DBAllButSpaceBits, 
			    selAlways1, 
			    (ClientData) NULL))
    return 0;

  /* Go along the tile's bottom border, searching for tiles
   * of a different type along that border.  If the bottom of
   * the tile is at -infinity, then don't do anything.
   */
    
  if (area.r_ybot > TiPlaneRect.r_ybot)
  {
    Rect edge; 
    RectFloat edgeW;

    edge.r_ybot = edge.r_ytop = area.r_ybot;
    for (neighbor = tile->ti_lb; 
	 LEFT(neighbor) < area.r_xtop;
	 neighbor = neighbor->ti_tr)
    {
      if (DBgetTileType(neighbor) == DBgetTileType(tile)) continue;
      edge.r_xbot = LEFT(neighbor);
      edge.r_xtop = RIGHT(neighbor);
      if (edge.r_xbot < area.r_xbot) edge.r_xbot = area.r_xbot;
      if (edge.r_xtop > area.r_xtop) edge.r_xtop = area.r_xtop;
      layRectToWindow(window, &edge, &edgeW);
      layDrawLine(edgeW.rf_xbot, 
		  edgeW.rf_ybot, 
		  edgeW.rf_xtop, 
		  edgeW.rf_ytop); 
    }
  }

  /* Now go along the tile's left border, doing the same thing.   Ignore
   * edges that are at infinity.
   */

  if (area.r_xbot > TiPlaneRect.r_xbot)
  {
    Rect edge;
    RectFloat edgeW;

    edge.r_xbot = edge.r_xtop = area.r_xbot;
    for (neighbor = tile->ti_bl; 
	 BOTTOM(neighbor) < area.r_ytop;
	 neighbor = neighbor->ti_rt)
    {
      if (DBgetTileType(neighbor) == DBgetTileType(tile)) continue;
      edge.r_ybot = BOTTOM(neighbor);
      edge.r_ytop = TOP(neighbor);
      if (edge.r_ybot < area.r_ybot) edge.r_ybot = area.r_ybot;
      if (edge.r_ytop < area.r_ytop) edge.r_ytop = area.r_ytop;
      layRectToWindow(window, &edge, &edgeW);
      layDrawLine(edgeW.rf_xbot, 
		  edgeW.rf_ybot,
		  edgeW.rf_xtop, 
		  edgeW.rf_ytop);
    }
  }

  return 0;			/* To keep the search from aborting. */
}

/* Redisplay function for selected paint */
int
laySelRedisplayFunc(Tile *tile, 
               			/* Tile to be drawn on highlight layer. */
		    Layout *window)
                      		/* Window in which to redisplay. */
{
    Rect area;
    RectFloat areaW;
    register Tile *neighbor;

    TiToRect(tile, &area);
    if (!DBPlaneEnumAreaPaint((Tile *) NULL, 
			      selRedisplayPlane, 
			      &area,
			      &DBAllButSpaceBits, 
			      selAlways1, 
			      (ClientData) NULL))
    {
	return 0;
    }

    layRectToWindow(window, &area, &areaW);
    layDrawRect(&areaW);

    /* continue enumeration */
    return 0;
}

/* Redisplay function for cells:  do what the normal redisplay code does
 * in Laydisplay.c, except draw in the highlight color.
 */

int
laySelRedisplayCellFunc(SearchContext *scx, 
                       		/* Describes cell found. */
			Layout *window)
                      		/* Window in which to redisplay. */
{
    Rect rect;
    RectFloat rectW;
    Point p;
    char idName[100];
    char *text;

    /* draw bounding box */
    GeoTransRect(&scx->scx_trans, DBUserBBoxCellDef(scx->scx_use->cu_def), &rect);
    if (!DBPlaneEnumAreaPaint((Tile *) NULL, selRedisplayPlane, &rect,
	    &DBAllButSpaceBits, selAlways1, (ClientData) NULL))
	return 0;
    layRectToWindow(window, &rect, &rectW);
    layDrawRect(&rectW);

    /* check for name redisplay disabled 
     *
     * if(!(window->lay_flags&Lay_SEEINSTANCENAMES)) return 0;
     * 
     */
    
    /* Don't futz around with text if the bbox is tiny. */
    if (((rectW.rf_xtop-rectW.rf_xbot) < layMinSubcellText.p_x) ||
	((rectW.rf_ytop-rectW.rf_ybot) < layMinSubcellText.p_y)) return 0;


    /* show text names 
     *  
     * Don't show ports since these are displayed at different size than
     * labels for expanded subcells leading to wierd display.
     */
    layDisplaySubcellText(scx, 
			  &rectW, 
			  TRUE,        /* show names */
			  FALSE);      /* don't show ports */

    /*  layDisplayWindow->lay_flags & Lay_SEEINSTANCEPORTS); */

    return 0;
}

/* called by layDisplayHLSelection() to redisplay polygon in selection */
static __inline__ void laySelRedisplayPolygon(Layout *window, Polygon *poly)
{
  int i;
  double coords[2000];
  double *coord; 
  int numPoints = poly->poly_size;

  ASSERT(numPoints<=1000,"layPolygonFunc");

  /* transform to window coordinates */
  coord = coords;
  for(i=0; i<numPoints; i++)
  {
    PointFloat pScreen;
    
    layPointFToWindow(window, &poly->poly_points[i], &pScreen);	
    *(coord++) = pScreen.pf_x;
    *(coord++) = pScreen.pf_y;
  }

  /* display */
  layDrawPolygon(numPoints, coords);
}



/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLSelPaintZO --
 *
 * 	Zoomed out version of redisplay for paint in selection
 *
 * ----------------------------------------------------------------------------
 */

void
layDisplayHLSelPaintZO(Layout *window, 
		               /* Window in which to redisplay. */
		      Plane *plane,
                 		/* Non-space tiles on this plane indicate
				 * which areas must have their highlights
				 * redrawn.
				 */
		      Rect *bbox) 
                                /* bbox of areas to redisplay */ 
{
  int i;
  Plane **paintPlanes;
  CellDef *displayDef = SelectUse->cu_def;

  /* pick appropriate paint planes for current resolution */
  paintPlanes = layCoarsePlanes(displayDef,layDBUnitsPerPixel);

  selRedisplayPlane = plane;
  for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
  {
    DBPlaneEnumAreaPaint((Tile *) NULL, 
			 paintPlanes[i],
			 bbox, 
			 &DBAllButSpaceAndDRCBits,
			 laySelRedisplayFunc,
			 (ClientData) window);
  }
}




/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLSelLabels --
 *
 * 	Called by layDisplayHLSelection to redisplay selected labels.
 *
 * ----------------------------------------------------------------------------
 */

static void
layDisplayHLSelLabels(Layout *window, 
		               /* Window in which to redisplay. */
		      Plane *plane)
                 		/* Non-space tiles on this plane indicate
				 * which areas must have their highlights
				 * redrawn.
				 */
{
  CellDef *displayDef = SelectUse->cu_def;
  Label *label;

  if(window->lay_labelMarkSize <= 0 &&
     window->lay_labelSize < 0 &&
     DBLabelMaxDim * window->lay_pixelsPerDB < 1) return;

#ifdef HIDE

  TextStyle *ts = layTextStyleLabel;
  int font;

  /* compute font size */
  font = layTextFontFromStyle(window, ts, NULL);

  /* reduce font as necessary to avoid over congestion */
  if(ts->ts_maxCoverage>0 && font>=0)
  {
    double maxCoverage = ts->ts_maxCoverage;
    double wArea =  Tk_Width(window) * Tk_Height(window);
    double maxLength = maxCoverage*wArea;
    int length = 0;
    
    /* count length of text */
    for (label = displayDef->cd_labels; 
	 label != NULL; 
	 label = label->lab_next)
    {
      /* skip hidden labels? */
      if((label->lab_kind == LAB_HIDDEN) && 
	 !(window->lay_flags & Lay_SEEHIDDENLABELS)) 
      {
	continue;
      }

      length += strlen(label->lab_text);
      if(length>=maxLength) break;
    }
	
    if(length>maxLength)
    {
      font = -1;
    }
    else if(length!=0)
    {
      int h;
      int f;

      h = sqrt((2*maxCoverage*wArea)/length);
      f = GrFontHeightToIndex(h);
      if(f<font) font = f;
    }
  }
#endif HIDE

    
      layDrawStyle(STYLE_SELECTION_OUTLINE);

      for (label = displayDef->cd_labels; label != NULL; label = label->lab_next)
      {
	Rect larger;

	/* don't display hidden labels */
	if((label->lab_kind == LAB_HIDDEN) && 
	   !(window->lay_flags & Lay_SEEHIDDENLABELS)) 
	{
	  continue;
	}

	/* See if the label needs to be redisplayed (make sure we do the
	 * search with a non-null area, or it will never return "yes").
	 */
	larger = label->lab_rect;
	if (larger.r_xbot == larger.r_xtop)
	    larger.r_xtop += 1;
	if (larger.r_ybot == larger.r_ytop)
	    larger.r_ytop += 1;
	if (!DBPlaneEnumAreaPaint((Tile *) NULL, plane, &larger, &DBAllButSpaceBits,
		selAlways1, (ClientData) NULL))
	    continue;

	layDisplayLabel(label, &GeoIdentityTransform, TRUE /* selection redisplay */);

	if (SigInterruptPending) break;
      }
}




/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLSelection --
 *
 * 	This procedure is called by the highlight code to redraw
 *	the selection highlights.  The caller must have locked
 *	the window already.  Only the highlight code should invoke
 *	this procedure.  Other clients should always call the highlight
 *	procedures.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Highlights are redrawn, if there is a selection to display
 *	and if it overlaps any non-space tiles in plane.
 *
 * ----------------------------------------------------------------------------
 */

void
layDisplayHLSelection(Layout *window, 
		               /* Window in which to redisplay. */
		      Plane *plane)
                 		/* Non-space tiles on this plane indicate
				 * which areas must have their highlights
				 * redrawn.
				 */
{

    CellDef *displayDef;
    Rect planeArea;
    SearchContext scx;
    Polygon *poly;
	    
    if (WINDOW_DEF(window) != SelectRootDef) return;
    displayDef = SelectUse->cu_def;

    /* Make sure that we've got something to show in the area
     * being redisplayed.
     */
    if (!DBBoundPlane(plane, &planeArea)) return;
    if (!GEO_OVERLAP(DBBBoxCellDef(displayDef), &planeArea)) return;

    if(layDBUnitsPerPixel >= layPaintZOT && 
	 !(layDisplayWindow->lay_flags&Lay_SPECIAL))
    {
      /*** ZOOMED OUT ***/

      /* STIPPLES */
      layDrawStyle(STYLE_SELECTION_STIPPLED);

      /* tiles */  
      layDisplayHLSelPaintZO(window,plane,&planeArea); 

      /* polygons */
      for(poly = displayDef->cd_polygons; poly; poly=poly->poly_next)
      {
	/* check that polygon bbox intersects redisplay area */
	if (!DBPlaneEnumAreaPaint((Tile *) NULL, 
				  plane, 
				  &poly->poly_bbox, 
				  &DBAllButSpaceBits,
				  selAlways1, 
				  (ClientData) NULL)) continue;
	laySelRedisplayPolygon(window, poly);
      }

      /* OUTLINES */
      layDrawStyle(STYLE_SELECTION_OUTLINE);

      /* tiles */  
      layDisplayHLSelPaintZO(window,plane,&planeArea); 

      /* polygons */
      for(poly = displayDef->cd_polygons; poly; poly=poly->poly_next)
      {
	/* check that polygon bbox intersects redisplay area */
	if (!DBPlaneEnumAreaPaint((Tile *) NULL, 
				  plane, 
				  &poly->poly_bbox, 
				  &DBAllButSpaceBits,
				  selAlways1, 
				  (ClientData) NULL)) continue;
	laySelRedisplayPolygon(window, poly);
      }


    }
    else
    {
      /*** ZOOMED IN ***/
      int i;

      layDrawStyle(STYLE_SELECTION_STIPPLED);

      /* STIPPLES */

      /* tiles */
      selRedisplayPlane = plane;
      for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
      {
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, 
				    displayDef->cd_planes[i],
				    &planeArea, 
				    &DBAllButSpaceBits,
				    laySelRedisplayFunc,
				    (ClientData) window);
      }

      /* polygons */
      for(poly = displayDef->cd_polygons; poly; poly=poly->poly_next)
      {
	/* check that polygon bbox intersects redisplay area */
	if (!DBPlaneEnumAreaPaint((Tile *) NULL, 
				  plane, 
				  &poly->poly_bbox, 
				  &DBAllButSpaceBits,
				  selAlways1, 
				  (ClientData) NULL)) continue;
	laySelRedisplayPolygon(window, poly);
      }

      /* OUTLINES */
      layDrawStyle(STYLE_SELECTION_OUTLINE);

      /* tiles */
      selRedisplayPlane = plane;
      for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
      {
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, 
				    displayDef->cd_planes[i],
				    &planeArea, 
				    &DBAllTypeBits,
				    laySelRedisplayOutlineFunc,
				    (ClientData) window);
      }

      /* polygons */
      for(poly = displayDef->cd_polygons; poly; poly=poly->poly_next)
      {
	/* check that polygon bbox intersects redisplay area */
	if (!DBPlaneEnumAreaPaint((Tile *) NULL, 
				  plane, 
				  &poly->poly_bbox, 
				  &DBAllButSpaceBits,
				  selAlways1, 
				  (ClientData) NULL)) continue;
	laySelRedisplayPolygon(window, poly);
      }
    }


    /* labels */
    if (window->lay_flags&Lay_SEELABELS)
    {
      layDisplayHLSelLabels(window, plane);
    }

    /* Redisplay all of the subcells in the selection. */
    layDrawStyle(STYLE_SELECTION_OUTLINE);
    scx.scx_use = SelectUse;
    scx.scx_area = planeArea;
    scx.scx_trans = GeoIdentityTransform;
    (void) DBSrChildren(&scx, laySelRedisplayCellFunc, (ClientData) window);
}

/*
 *  ===== FLYLINES =====
 */


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLFlylines --
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Flylines are redrawn in areas where plane is non space.
 *
 * ----------------------------------------------------------------------------
 */

/* linked to tcl var LAY_FLYLINE_TIC */
int layFlyLineTic = 3;

/* display a single flyline
 * called by layDisplayHLFlylinesFunc()) 
 */
static void layDisplayFlyline(SearchContext *scx, FlyLine *fl, int font)
{
  PointFloat p1, p2;
  PointFloat p1W, p2W;
  double length;

  double deltaX = 0.0;  /* intialize to avoid compiler warnings */
  double deltaY = 0.0;
  double unitX  = 0.0; 
  double unitY  = 0.0; 

  Layout *w = layDisplayWindow;

#define x1 (p1W.pf_x)
#define y1 (p1W.pf_y)
#define x2 (p2W.pf_x)
#define y2 (p2W.pf_y)

  /* transform to window coordinates */
  GeoTransPointF(&scx->scx_trans, &fl->fl_p1, &p1);
  layPointFToWindow(w, &p1, &p1W);
  GeoTransPointF(&scx->scx_trans, &fl->fl_p2, &p2);
  layPointFToWindow(w, &p2, &p2W);

  /* compute normalized (unit) direction vector for flyline, if needed */
  if(fl->fl_width !=1 || (fl->fl_text && font>=0))
  {
    /* direction vector for flyline */
    deltaX = x2 - x1;
    deltaY = y2 - y1;

    /* point toward increasing x */
    if(deltaX < 0 || (deltaX==0 && deltaY<0))
    {
      deltaX = -deltaX;
      deltaY = -deltaY;
    }

    /* length */
    length = sqrt(deltaX*deltaX + deltaY*deltaY);
    
    /* guard against divide by zero */
    if(length<=1) return;

    /* unit vector corresponding to flyline */
    unitX = deltaX/length; 
    unitY = deltaY/length; 


    /* adjust window "labelExtents" to include wire width and tic
     *
     * (label expand amounts are kept big enough to include text of largest
     * label or flyline currently drawn in this window)
     *	   
     */
    {
      double delta = fl->fl_width + 1;

      if(fl->fl_text && font>=0) delta += layFlyLineTic;
	
      w->lay_labelExtents.r_xbot = MIN(w->lay_labelExtents.r_xbot, -delta);
      w->lay_labelExtents.r_ybot = MIN(w->lay_labelExtents.r_ybot, -delta);
      w->lay_labelExtents.r_xtop = MAX(w->lay_labelExtents.r_xtop, +delta);
      w->lay_labelExtents.r_ytop = MAX(w->lay_labelExtents.r_ytop, +delta);
    }
  }

  /* draw the line */
  if(fl->fl_width == 1)
  {
    layDrawLine(x1,y1,x2,y2);
  }
  else 
  {
    /* implement wide line as filled polygon */
    double coords[8];
    double r = fl->fl_width/2.0;
    double rX = unitX*r;
    double rY = unitY*r;

    coords[0] = x1 - rY;
    coords[1] = y1 + rX;

    coords[2] = x2 - rY;
    coords[3] = y2 + rX;

    coords[4] = x2 + rY;
    coords[5] = y2 - rX;

    coords[6] = x1 + rY;
    coords[7] = y1 - rX;

    layDrawPolygon(4,coords);


  }

  if(fl->fl_text && font>=0)
  {
    /* make center tic */
    double rx = unitX*(fl->fl_width/2.0 + layFlyLineTic);
    double ry = unitY*(fl->fl_width/2.0 + layFlyLineTic);
    double cx = (x1 + x2) / 2;    
    double cy = (y1 + y2) / 2;    

    layDrawLine(cx - ry,
		cy + rx,
		cx + ry,
		cy - rx);


    /* display the text */
    if(font>=0)
    {    
      PointFloat p;
      RectFloat textBBox;
      int align;

      /* text alignment point 
       * end of tic mark below line 
       */
      p.pf_x = cx + ry;
      p.pf_y = cy - rx;

      /* place label below flyline extending away from line.
       */
      if (deltaY >= 0)
      {
	align = GEO_SOUTHEAST;
      }
      else 
      {
	align = GEO_SOUTHWEST;
      }

      layTextDraw(fl->fl_text,
		  &p,
		  align,
		  font,
		  FALSE,
		  NULL,
		  &textBBox);


      /* adjust window "labelExtents" to include this text.
       *
       * (label expand amounts are kept big enough to include text of largest
       * label or flyline currently drawn in this window)
       *	   
       */
      w->lay_labelExtents.r_xbot = MIN(w->lay_labelExtents.r_xbot, 
				       textBBox.rf_xbot - cx);
      w->lay_labelExtents.r_ybot = MIN(w->lay_labelExtents.r_ybot,
				       textBBox.rf_ybot - cy);
      w->lay_labelExtents.r_xtop = MAX(w->lay_labelExtents.r_xtop, 
				       textBBox.rf_xtop - cx);
      w->lay_labelExtents.r_ytop = MAX(w->lay_labelExtents.r_ytop,
				       textBBox.rf_ytop - cy);
    }
  }

#undef x1 
#undef y1 
#undef x2 
#undef y2 
}

/* helper func */
static int
layDisplayHLFlylinesFunc(SearchContext *scx, ClientData arg)
{
  FlyLine *fl;
  Rect *rootClip = (Rect *) arg;
  Rect *area = &scx->scx_area;
  CellDef *def = scx->scx_use->cu_def;
  int bitMask = layDisplayWindow->lay_bitmask;
  RectFloat loc; /* subcell bbox in window coordinates */
  int font;

  /* cell expanded ? */
  if (!DBIsExpand(scx->scx_use, bitMask)) return 0;

  /* if no flylines visible beneath us, we can just return 
   * (THIS CAN SAVE ALOT OF TIME! FOR BIG DESIGNS) 
   * But, being careful not to force single pixel update when 
   * redisplaying small area.
   */
  if(layPixelValid(def)) 
  {
    /* single pixel already valid */ 
    if (!layPixelGet(def, PV_FLYLINE)) return 0;
  }
  else if(layDBUnitsPerPixel>=layPaintZOT)
  {
    /* zoomed out, so worth recomputing single pixel value */
    if (!layPixelGet(def, PV_FLYLINE)) return 0;
  }
  else
  {
    /* even if zoomed in, we may be processing a large area
     * since flylines may cross the area being viewed.
     * (stay in ints, since we don't care about round off)
     */
    int fx = GEO_WIDTH(area);
    int fy = GEO_HEIGHT(area);

    fx /= GEO_WIDTH(&layDisplayWindow->lay_dbArea)+1;
    fy /= GEO_HEIGHT(&layDisplayWindow->lay_dbArea)+1;

    if (layDBUnitsPerPixel * MAX(fx,fy) >= layPaintZOT &&
	!layPixelGet(def, PV_FLYLINE)) return 0;
  }

  /* read in cell if necessary */
  if (!DBReadCell(def)) return 1;

  /* convert use bbox to pixel coordinates */
  {
    Rect temp1, temp2;
    
    GEOTRANSRECT(&scx->scx_trans, &def->cd_bbox, &temp1);
    GeoCanonicalRect(&temp1, &temp2);
    layRectToWindow(layDisplayWindow, &temp2, &loc);
  }

  /* special case subcells two or less pixels in diameter */
  if(loc.rf_xtop -loc.rf_xbot <= 1 && loc.rf_ytop - loc.rf_ybot <= 1)
  {
    /* 
     * No need to show  flylines in two pixel cells!
     *
     * layDrawPixels(&loc, layPixelGet(def, PV_FLYLINE), NULL);
     */  
    return 0;
  }

  /* apply ourselves recursively to children */
  if (DBSrChildrenNested(scx, 
			 layDisplayHLFlylinesFunc, 
			 arg)) 
  {
    /* interrupted */
    return 1;
  }

  /* set the display style */
  if(!layAllSame && !layDisplayIsEdit(scx))
  {
    layDrawStyle(STYLE_FLYLINE_DIM);
  }
  else
  {
    layDrawStyle(STYLE_FLYLINE);
  }

  /* compute flyline text size */
  font = layTextFontFromStyle(layDisplayWindow, layTextStyleFlyline, NULL);

  /* reduce font as necessary to avoid over congestion */
  if(layTextStyleFlyline->ts_maxCoverage>0 && font>=0)
  {
    double maxCoverage = layTextStyleFlyline->ts_maxCoverage;
    double wArea = GEO_WIDTHF(&loc) * GEO_HEIGHTF(&loc);
    double maxLength = maxCoverage*wArea;
    int length = 0;

    /* count length of text */
    for (fl = def->cd_flyLines; fl; fl = fl->fl_next)
    {
      if((fl->flay_flags&(FL_P1_VALID|FL_P2_VALID)) !=
	 (FL_P1_VALID|FL_P2_VALID)) continue;

      if(!fl->fl_text) continue;

      length += strlen(fl->fl_text);
      if(length>=maxLength) break;
    }

    if(length>maxLength)
    {
      font = -1;
    }
    else if(length!=0)
    {
      int h;
      int f;

      h = sqrt((2*maxCoverage*wArea)/length);
      f = GrFontHeightToIndex(h);
      if(f<font) font = f;
    }
  }

  if(font<0) return 0;

  /* draw flylines for this cell */
  for (fl = def->cd_flyLines; fl; fl = fl->fl_next)
  {
    if((fl->flay_flags&(FL_P1_VALID|FL_P2_VALID)) !=
       (FL_P1_VALID|FL_P2_VALID)) continue;

    /* for now draw all flylines 
     * if (!GEO_TOUCH(&fl->fl_bbox, area)) continue;
     */

    layDisplayFlyline(scx,fl,font);
  }

  return 0;
}

void
layDisplayHLFlylines(Plane *redisplayPlane)
                 		/* Non-space tiles on this plane indicate
				 * which areas must have their highlights
				 * redrawn.
				 */
{
    Rect redisplayArea;
    SearchContext scx;
    Layout *w = layDisplayWindow;

    if (!DBFlyLinesExist || !(w->lay_flags & Lay_SEEFLYLINES)) return;
    
    /* Just redisplay entire bounding box of redisplay areas. */
    if (!DBBoundPlane(redisplayPlane, &redisplayArea)) return;
    if (!GEO_TOUCH(DBBBoxCellDef(w->lay_rootUse->cu_def), &redisplayArea)) return;

    /* for now redisplay entire window  
       redisplayArea = w->lay_dbArea; 
    */

    /* round up redisplay area to avoid boundary conditions */
    redisplayArea.r_xbot -= 1;
    redisplayArea.r_ybot -= 1;
    redisplayArea.r_xtop += 1;
    redisplayArea.r_ytop += 1;

    /* set up search context */
    scx.scx_area = redisplayArea;
    scx.scx_use = w->lay_rootUse;
    scx.scx_x = scx.scx_y = -1;
    scx.scx_trans = GeoIdentityTransform;

    /* draw the flylines cell by recursive cell */
    layDisplayHLFlylinesFunc(&scx, &redisplayArea);
}


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLAnnotationsText --
 *
 * 	called by layDisplayHLAnnotations() to redisplay
 *	text annotation "highlights".
 *
 * ----------------------------------------------------------------------------
 */
void
layDisplayHLAnnotationsText(Layout *w, 
		               /* Window in which to redisplay. */
			    Plane *plane,
                 		/* Non-space tiles on this plane indicate
				 * which areas must have their highlights
				 * redrawn.
				 */
			    Rect *redisplayArea)
{
  int i;

  for(i=0;i<=layTextStyleMax;i++)
  {
    int fontSize;
    int height;

    TextAnnotation *annotations = w->lay_textAnnotations[i];
    TextAnnotation *ta;
    TextStyle *ts;

    if(!annotations) continue;

    ts = &layTextStyleTable[i];

    /* compute fontSize from style */
    fontSize = layTextFontFromStyle(w, ts, &height);
    if(fontSize<0) continue;

    /* reduce fontSize as necessary to avoid over congestion */
    if(ts->ts_maxCoverage>0)
    {
      double maxCoverage = ts->ts_maxCoverage;
      double wArea = Tk_Width(w->lay_tkWin) * Tk_Height(w->lay_tkWin);
      double maxLength = maxCoverage*wArea;
      int length = 0;

      /* count length of text */
      for (ta = annotations; ta; ta = ta->ta_next)
      {
	/* if not in current window frame, skip */
	if(!GEO_TOUCH(&ta->ta_bbox,redisplayArea)) continue;

	length += strlen(ta->ta_text);
	if(length>=maxLength) break;
      }

      if(length>=maxLength) continue;
      
      if(length!=0)
      {
	int h = sqrt((2*maxCoverage*wArea)/length);
	if(h<height)
	{
	  height = h;
	  fontSize = GrFontHeightToIndex(height);
	}
      }
    }
    if(fontSize<0) continue;

    /* reduce fontSize as necessary, to avoid excessive text overlap */
    if(ts->ts_maxOverlap>0) 
    {
      while(fontSize>0)
      {
	double overlap;

	layTextDrawOverlapStatsBegin();

	for (ta = annotations; ta; ta = ta->ta_next)
        {
	  PointFloat pixelLoc;

	  /* if not in current window frame, skip */
	  if(!GEO_TOUCH(&ta->ta_bbox,redisplayArea)) continue;

	  /* transform location to window coordinates */
	  layPointFToWindow(w, &ta->ta_location, &pixelLoc);

	  layTextDraw(ta->ta_text,
		      &pixelLoc,
		      ta->ta_pos,
		      fontSize,
		      FALSE, /* don't slide text around */
		      NULL,  /* no clipping */
		      NULL);

	  if (SigInterruptPending) break;
	}

	overlap = layTextDrawOverlapStatsEnd();
	fprintf(stderr,"overlap =%lf height=%d fontSize=%d\n", 
		overlap,height,fontSize);

	/* within limit yet? */
	if(overlap <= ts->ts_maxOverlap) break;

	/* try reducing fontSize */
	height /= 2;
	fontSize = GrFontHeightToIndex(height);
      }
    }
    if(fontSize<0) continue;

    layDrawStyle(STYLE_ANNOTATION);

    for (ta = w->lay_textAnnotations[i]; ta; ta = ta->ta_next)
    {
      PointFloat pixelLoc;

      /* if not in current window frame, skip */
      if(!GEO_TOUCH(&ta->ta_bbox,redisplayArea)) continue;

      /* transform location to window coordinates */
      layPointFToWindow(w, &ta->ta_location, &pixelLoc);

      layTextDraw(ta->ta_text,
		  &pixelLoc,
		  ta->ta_pos,
		  fontSize,
		  FALSE, /* don't slide text around */
		  NULL,  /* no clipping */
		  NULL);

      if (SigInterruptPending) break;
    }
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayHLAnnotations --
 *
 * 	This procedure is called by layDisplay() to redisplay
 *	annotation "highlights".
 *
 * ----------------------------------------------------------------------------
 */

void
layDisplayHLAnnotations(Layout *w, 
		               /* Window in which to redisplay. */
			Plane *plane)
                 		/* Non-space tiles on this plane indicate
				 * which areas must have their highlights
				 * redrawn.
				 */
{
    LineAnnotation *la;
    DotAnnotation *da;
    Rect redisplayArea = w->lay_dbArea;

    /* round up redisplay area to avoid boundary conditions */
    redisplayArea.r_xbot -= 1;
    redisplayArea.r_ybot -= 1;
    redisplayArea.r_xtop += 1;
    redisplayArea.r_ytop += 1;

    /* Redisplay text annotations in window frame */
    layDisplayHLAnnotationsText(w, plane, &redisplayArea);

    /* Redisplay line annotations in window frame */
    for (la = w->lay_lineAnnotations; la; la = la->la_next)
    {
      PointFloat p1W, p2W;

      /* if not in current window frame, skip */
      if(!GEO_TOUCH(&la->la_bbox,&w->lay_dbArea)) continue;
    
      /* transform points to window coordinates */
      layPointFToWindow(w, &la->la_p1, &p1W);
      layPointFToWindow(w, &la->la_p2, &p2W);

      /* draw the line */
      layDrawStyle(STYLE_ANNOTATION);
      layDrawLine(p1W.pf_x, p1W.pf_y,
		  p2W.pf_x, p2W.pf_y);

      if (SigInterruptPending) break;
    }

    /* Redisplay dot annotations in window frame */
    for (da = w->lay_dotAnnotations; da; da = da->da_next)
    {
      PointFloat centerW;
      double d;
      double coordsW[4];

      /* if not in current window frame, skip */
      if(!GEO_TOUCH(&da->da_bbox,&w->lay_dbArea)) continue;

      /* transform center to window coordinates */
      layPointFToWindow(w, &da->da_center, &centerW);

      /* compute point "polygon" coords: 
       * 2 point polygon rendered as circle inscribed in square
       * with points as diagonally opposite corners.
       */
      d = da->da_diameter;
      coordsW[0] = centerW.pf_x - d/2;
      coordsW[1] = centerW.pf_y - d/2;
      coordsW[2] = coordsW[0] + d;
      coordsW[3] = coordsW[1] + d;
      
      layDrawStyle(STYLE_ANNOTATION);
      layDrawPolygon(2, coordsW);

      if (SigInterruptPending) break;
    }
}



