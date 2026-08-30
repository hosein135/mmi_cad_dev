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



/* layDisplay.c -
 *
 * Redisplay code for Layout widgets.
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
#include "graphics.h"
#include "layout.h"
#include "layint.h"
#include "layDraw.h"
#include "debug.h"
#include "mm.h"

/* The window being redisplayed. */
Layout *layDisplayWindow;
void *layGraphicsWindow;

/* measures of display resolution in current window */
int layDBUnitsPerPixel;  /* (1 when zoomed in tight) */
int layPixelsPerDBUnit; /*  (0 when zoomed out) */

/* measure of typical feature size in database units */
int layTypicalWireWidth = -1;

/* factor to use in computing label mark and text size from typical
 * wire width. (linked to LAY_LABEL_SIZE_FACTOR)
 */
double layLabelSizeFactor = 1.0;

/* minimum radius of '+' for selected point labels (in pixels) */
int layLabelMinSelectedMark = 10;

Point layMinText; /* minimum size text area */
Point layMinSubcellText; /* minimum size subcell before text added */

/* The stuff below is set by the toplevel redisplay routines
 * and used by the action routines.
 * It is used to identify the edit cell so it can be 
 * displayed differently.
 */

CellDef *layEditDef;
Transform layEditTrans;	/* Contains transform from edit cell to
				 * screen coordinates.  If edit cell isn't
				 * in this window, editDef is NULL.
				 */
bool layAllSame;		/* Means don't display the edit cell
				 * differently after all.
				 */

/* ==== ROUTINES SHARED BY GENERAL AND HIGHLIGHT REDISPLAY ===== */

/*---------------------------------------------------------
 * layDisplaySubcellText --
 *
 *	display subcell names/orientation/id
 *
 *---------------------------------------------------------
 */
void
layDisplaySubcellText(SearchContext *scx,  /*  scx for subcell */
		      RectFloat *loc,   /* bbox of subcell in pixels */
		      bool showNames,      
		      bool showPorts)
{
    char nameBuf[102];
    CellUse *cu  = scx->scx_use;
    CellDef *def = cu->cu_def;

    if(!showNames && !showPorts) return;

    /* clip text to instance bbox */
    {
      Rect r;
      geoRectF2Rect(loc,&r);
      layDrawSetClip(&r,&layDisplayWindow->lay_area);
    }

    /* names */
    if(showNames) 
    {
      char *text;
      PointFloat p;
      RectFloat r;

      double h = loc->rf_ytop - loc->rf_ybot;
      double y1 = loc->rf_ybot + h*.4;
      double y2 = loc->rf_ytop - h*.4;

      r.rf_xbot = loc->rf_xbot;
      r.rf_xtop = loc->rf_xtop;
      p.pf_x = (loc->rf_xbot + loc->rf_xtop) / 2; 
      
      /* name */
      r.rf_ytop = loc->rf_ytop;
      r.rf_ybot = y2;
      p.pf_y = (r.rf_ytop + r.rf_ybot)/2;

      text = def->cd_showName;
      if(!text) text = def->cd_name;
      layTextDraw(text,
		  &p,
		  GEO_CENTER, 
		  GR_TEXT_LARGE, 
		  TRUE, 
		  &r, 
		  NULL);

      /* transform */
      r.rf_ytop = y2;
      r.rf_ybot = y1;
      p.pf_y = (r.rf_ytop + r.rf_ybot)/2;

      text = GeoTransToName(&cu->cu_transform);
      layTextDraw(text, 
		  &p,
		  GEO_CENTER, 
		  GR_TEXT_LARGE, 
		  TRUE, 
		  &r, 
		  NULL);

      /* inst */ 
      r.rf_ytop = y1;
      r.rf_ybot = loc->rf_ybot;
      p.pf_y = (r.rf_ytop + r.rf_ybot)/2;

      p.pf_y = loc->rf_ybot + h/4;
      text = def->cd_showInst;
      if(!text)
      {
	DBSrPrintUseId(scx, nameBuf, 100);
	text = nameBuf;
      }

      layTextDraw(text, 
		  &p, 
		  GEO_CENTER, 
		  GR_TEXT_LARGE, 
		  TRUE, 
		  &r, 
		  NULL);
    }

    /*  ports */
    if(showPorts) 
    {
      Label *l;
      RectFloat rlab;
      PointFloat plab;
      int screenPos;

      for(l=def->cd_labels;l!=NULL;l=l->lab_next)
      {
	Rect tmp;

	if(l->lab_kind < LAB_INPUT) continue;
	if(l->lab_kind > LAB_INOUT) continue;

	if(!GEO_TOUCH(&l->lab_rect, &scx->scx_area)) continue;
	
        screenPos = GeoTransPos(&scx->scx_trans, l->lab_pos);
	GeoTransRect(&scx->scx_trans, &l->lab_rect, &tmp);
	layRectToWindow(layDisplayWindow, &tmp, &rlab);

	/* display label rect */
	GEOCLIPF(&rlab,loc);
	layDrawRect(&rlab);

	/* display text */
	DBLabelTypedText(l->lab_text, l->lab_kind, nameBuf, 100);
	layLabelTextPoint(&rlab,screenPos,&plab);
	layTextDraw(nameBuf,
		    &plab, /* point to align to */
		    screenPos, /* type of alignment */
		    GR_TEXT_SMALL, /* font size */
		    TRUE, /* adjust position to fit in clipping rect */
		    loc, /* clip against bounding box */
		    NULL);
      }
    }

    /* turn off clipping */
    layDrawSetClip(NULL,&layDisplayWindow->lay_area);
}

/*
 * ----------------------------------------------------------------------------
 *
 * layLabelTextPoint--
 *
 *  Compute point to start label text at. 
 *
 * ----------------------------------------------------------------------------
 */
void 
layLabelTextPoint(RectFloat *rect,
		     /* labels area in screen coords */
		 int pos,
		     /* text position in screen coords */
		 PointFloat *point)
                     /* result put here */
{
    switch (pos)
    {
	case GEO_CENTER:
	    point->pf_x = (rect->rf_xbot + rect->rf_xtop)/2;
	    point->pf_y = (rect->rf_ybot + rect->rf_ytop)/2;
	    break;
	case GEO_NORTH:
	    point->pf_x = (rect->rf_xbot + rect->rf_xtop)/2;
	    point->pf_y = rect->rf_ytop;
	    break;
	case GEO_NORTHEAST:
	    *point = rect->rf_ur;
	    break;
	case GEO_EAST:
	    point->pf_x = rect->rf_xtop;
	    point->pf_y = (rect->rf_ybot + rect->rf_ytop)/2;
	    break;
	case GEO_SOUTHEAST:
	    point->pf_x = rect->rf_xtop;
	    point->pf_y = rect->rf_ybot;
	    break;
	case GEO_SOUTH:
	    point->pf_x = (rect->rf_xbot + rect->rf_xtop)/2;
	    point->pf_y = rect->rf_ybot;
	    break;
	case GEO_SOUTHWEST:
	    *point = rect->rf_ll;
	    break;
	case GEO_WEST:
	    point->pf_x = rect->rf_xbot;
	    point->pf_y = (rect->rf_ybot + rect->rf_ytop)/2;
	    break;
	case GEO_NORTHWEST:
	    point->pf_x = rect->rf_xbot;
	    point->pf_y = rect->rf_ytop;
	    break;
	ASSERT(FALSE,"layLabelTextPoint");
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * layDisplayLabel --
 *
 * 	This procedure does all the work of actually drawing labels
 * 	on the screen.  It is invoked during general redisplay of labels
 *	and during Highlight redisplay (for selected label) 
 *
 *      sizeBox is updated to be
 *	large enough to hold the total pixel area occupied by the label text
 *	(assuming it were drawn at (0,0)).
 *
 * ----------------------------------------------------------------------------
 */

void 
layDisplayLabel(Label *l,       
		Transform *trans, /* transform to root coords */
		bool selected)    /* selected labels have minimum mark size. */
{
    PointFloat p;
    RectFloat textBBox;
    char text[500];
    RectFloat rect;
    int pos;
    Layout *w = layDisplayWindow;

    /* transform label rect and position to window coordinates */
    {
      Rect tmp;

      pos = GeoTransPos(trans, l->lab_pos);
      GeoTransRect(trans, &l->lab_rect, &tmp);
      layRectToWindow(w, &tmp, &rect);
    }

    /* is label point or box ? */
    if( rect.rf_xbot == rect.rf_xtop && 
        rect.rf_ybot == rect.rf_ytop)
    {
      double markSize = w->lay_labelMarkSize;

      if(selected && markSize>0 && markSize < layLabelMinSelectedMark) 
      {
	markSize = layLabelMinSelectedMark;
      }

      /* point label, display as '+' */
      if(markSize != 0)
      {
	layDrawLine(rect.rf_xbot - markSize,
		    rect.rf_ybot,
		    rect.rf_xbot + markSize,
		    rect.rf_ybot);
	layDrawLine(rect.rf_xbot, 
		    rect.rf_ybot - markSize,
		    rect.rf_xbot,
		    rect.rf_ybot + markSize);
      }
    }
    else if (ABSDIFF(rect.rf_xbot,rect.rf_xtop) >= 1 &&
	     ABSDIFF(rect.rf_ybot,rect.rf_ytop) >= 1)
    {

      layDrawRect(&rect);
    }

    /* label text */
    if (w->lay_labelSize < 0) return;

    DBLabelTypedText(l->lab_text, l->lab_kind, text, sizeof(text));
    layLabelTextPoint(&rect,pos,&p);

    layTextDraw(text, 
		&p, 
		pos, 
		w->lay_labelSize,
		FALSE, /* don't adjust text position and font to fit */  
		NULL, /* don't clip */
		&textBBox); /* bbox of drawn text returned here */

    /* adjust label expand amounts to be big enough to include text
     * of this label.  
     *
     * (label expand amounts are kept big enough to include text of largest
     * label currently drawn in this window)
     */
    w->lay_labelExtents.r_xbot = MIN(w->lay_labelExtents.r_xbot, 
				    textBBox.rf_xbot - p.pf_x);
    w->lay_labelExtents.r_ybot = MIN(w->lay_labelExtents.r_ybot,
				    textBBox.rf_ybot - p.pf_y);
    w->lay_labelExtents.r_xtop = MAX(w->lay_labelExtents.r_xtop, 
				    textBBox.rf_xtop - p.pf_x);
    w->lay_labelExtents.r_ytop = MAX(w->lay_labelExtents.r_ytop,
				    textBBox.rf_ytop - p.pf_y);
}

/* ====== TOPLEVEL REDISPLAY CODE ===== */

/*
 * ----------------------------------------------------------------------------
 * layCallBack --
 *
 *	Tcl callback during redisplay.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	specified Tcl Command evaled.
 * ----------------------------------------------------------------------------
 */
static void layCallBack(Tcl_Interp *interp, char *cmd)
{
    int result;

    result = Tcl_Eval(interp, cmd);
    if (result != TCL_OK) 
    {
	Tcl_AddErrorInfo(interp,
	    "\n    (tcl call back from redisplay code )");
	Tcl_BackgroundError(interp);
    }
}


/*
 * ----------------------------------------------------------------------------
 * layNotifyScrollBar --
 *
 *	Notify scrollbar widget of change in view.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	specified Tcl Command evaled to communicate with scroll bar.
 * ----------------------------------------------------------------------------
 */

#define STRING_SIZE 200
static void layNotifyScrollBar(Tcl_Interp *interp, char *scrollCmd,
    int cellMin, 
    int cellMax, 
    int viewMin, 
    int viewMax)
{
    char string[STRING_SIZE];
    double cellSize = cellMax - cellMin;
    double minVis;
    double maxVis;

    minVis = (viewMin-cellMin)/cellSize;
    minVis = MAX(0.0,minVis);
    minVis = MIN(minVis,1.0);


    maxVis = (viewMax-cellMin)/cellSize;
    maxVis = MAX(0.0,maxVis);
    maxVis = MIN(maxVis,1.0);

    sprintf(string, "%s %f %f", scrollCmd, minVis, maxVis);
    layCallBack(interp, string);
}

/*
 * ----------------------------------------------------------------------------
 *
 * layFrameUpdate --
 *
 *  Makes sure frame dependent redisplay parameters are up-to-date for
 *  window.
 *
 *  frame = region being displayed in window.
 *
 * ----------------------------------------------------------------------------
 */
void layFrameUpdate(Layout *w) 
{
  int labelSize;
  int edges = 0;
  bool scaleChanged = FALSE;

  if(!w->lay_genOverlay || 
     GrPixmapWidth(w->lay_genOverlay) != Tk_Width(w->lay_tkWin) ||
     GrPixmapHeight(w->lay_genOverlay) != Tk_Height(w->lay_tkWin))
  {
    if(w->lay_genOverlay) GrFreePixmap(w->lay_genOverlay);

    w->lay_genOverlay = 
      GrCreatePixmap(Tk_Width(w->lay_tkWin),
		     Tk_Height(w->lay_tkWin));
  }		     
 
  if(w->lay_lastPixelsPerDB != w->lay_pixelsPerDB)
  {
    scaleChanged = TRUE;
  }
  else 
  {
    /* if window frame hasn't changed, just return */ 
    if(GEO_SAMERECT(w->lay_lastDBArea, w->lay_dbArea) &&
       w->lay_lastLabelSizeFactor == layLabelSizeFactor &&
       w->lay_lastLabelMinSelectedMark == layLabelMinSelectedMark) return;
  }
     
  /* flush image cache */
  if(scaleChanged)
  {
    /* fprintf(stderr,"DEBUG scale changed.\n"); */
    layCacheClear(NULL);
  }
  else
  {
    /* fprintf(stderr,"DEBUG scrolled.\n"); */
    if(w->lay_lastDBArea.r_xbot > w->lay_dbArea.r_xbot) edges |= LE_LEFT;
    if(w->lay_lastDBArea.r_xtop < w->lay_dbArea.r_xtop) edges |= LE_RIGHT;
    if(w->lay_lastDBArea.r_ybot > w->lay_dbArea.r_ybot) edges |= LE_BOTTOM;
    if(w->lay_lastDBArea.r_ytop < w->lay_dbArea.r_ytop) edges |= LE_TOP;

    if(edges) layCacheFlushClipped(edges, NULL);
  }

  /* save new frame values */
  w->lay_lastPixelsPerDB = w->lay_pixelsPerDB;
  w->lay_lastDBArea = w->lay_dbArea;
  w->lay_lastLabelSizeFactor = layLabelSizeFactor;
  w->lay_lastLabelMinSelectedMark = layLabelMinSelectedMark;

  /* size in window coordinates, based on typical wire dimensions 
   * (used for picking sizes below) 
   */
  labelSize = layDimFToWindow(w, layTypicalWireWidth*layLabelSizeFactor);

  /* LABEL SIZE
   *
   * Choose label font of about labelSize
   * Choose label mark size (for point labels) proportional to labelSize.
   *
   */
  {
    int i;
    Rect text;

    for (i = GrMaxFontSize; i >= 0; i -= 1)
    {
      GrTextBBox("B", i, 0 /* no rotation */,
		 &text.r_xbot,
		 &text.r_ybot,
		 &text.r_xtop,
		 &text.r_ytop);
      if (labelSize > (text.r_ytop - text.r_ybot)) break;
    }
    w->lay_labelSize = i; /* if negative, label text is not displayed */


    if(w->lay_labelSize >= 0)
    { 
      w->lay_labelMarkSize = (text.r_xtop - text.r_xbot)/4;
    }
    else
    {
      w->lay_labelMarkSize = labelSize/2;
    }
  }

  /* LABEL EXTENSION 
   *
   * initialize expand amounts to point label mark size 
   *
   * expandAmounts give max distance already drawn label text extends 
   * beyond label area in window.
   */
  {
    int markSize = MAX(w->lay_labelMarkSize, layLabelMinSelectedMark);
   
    w->lay_labelExtents.r_xbot = -markSize;
    w->lay_labelExtents.r_ybot = -markSize;
    w->lay_labelExtents.r_xtop = markSize;
    w->lay_labelExtents.r_ytop = markSize;
  }
}


/*
 * ----------------------------------------------------------------------------
 * layDisplay --
 *
 *	Redisplay the Layout window areas that were previously flagged 
 *      by calls to routines in layChanged.c
 *
 *      This routine is scheduled by routines in layChanged.c
 *      It should not be necessary to call it from anywhere else.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to update the display of the Layout 
 *	window.
 *
 *
 * NOTE: Highlights are drawn on top of everything else, are ephemeral, 
 *       and can be both drawn and erased without need to redraw 
 *       the Layout below.
 *
 *       Thus Redisplay is divided into "general" and "highlight" phases.
 *       The general phase marks all areas it redraws, for highlight redraw
 *       as well.  
 *
 *       This scheme avoids unnecessarily redrawing "paint".
 *
 *       ("paint" above is not strictly just paint, it includes, labels,
 *        subcell borders and names, and the grid.)
 * ----------------------------------------------------------------------------
 */

void
layDisplay(ClientData clientData)
{
    Rect r;
    register Layout *w = (Layout *) clientData;

    /* clear change count (since last redisplay) */ 
    /* DEBUG
    fprintf(stderr,"DEBUG layDisplay, layNumChanges=%d\n",
	    layNumChanges);
    */
    layNumChanges = 0;

    /* special handling full redisplay */
    if(layRedisplayAllPending || !w)
    {
      Layout *l;

      /* if redisplay all not pending, just return */
      if(!layRedisplayAllPending) return;
      layRedisplayAllPending = FALSE;

      /* DEBUG
      fprintf(stderr,"layDisplay() DEBUG, full redisplay!\n");
      */
 
      for(l= layTopWindow; l!= NULL; l = l->lay_next)
      {
	/* set general redraw area to entire window */
	DBPaintPlane(l->lay_genRedraw,
		     &l->lay_area,
		     DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
		     (PaintUndoInfo *) NULL);

	/* set highlight erase area to entire window */
	DBPaintPlane(l->lay_hlErase, 
		     &l->lay_area,
		     DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
		     (PaintUndoInfo *) NULL);

	/* set  highlight redraw area to entire window */
	{
	  /* the highlight redraw plane is in database coordinates! */
	  Rect redrawArea;

	  layRectWToDB(l, &l->lay_area, &redrawArea);

	  /* expand area by one unit to avoid edge effects */
	  GEO_EXPAND(&redrawArea, 1, &redrawArea);

	  DBPaintPlane(l->lay_hlRedrawDB, 
		       &redrawArea,
		       DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
		       (PaintUndoInfo *) NULL);
	}

	/* redraw window (recursively) */
	l->lay_flags |= Lay_REDRAWPENDING;
	layDisplay((ClientData) l);
      }
      return;
    }

    /* set global variable giving current redisplay window 
     * (used by subroutines)
     */
    layDisplayWindow = w;

    /*
    fprintf(stderr,"DEBUG layDisplay() top.\n");  
    layCacheDump(NULL);
    */

    /* if window isn't mapped yet, nothing to do */
    if ((w->lay_tkWin == NULL) || 
	!Tk_IsMapped(w->lay_tkWin)) goto layDisplayDone;

    /* 
     *  PRE REDISPLAY BOOKKEEPING 
     */  

    /* resolution */
    layPixelsPerDBUnit = floor(w->lay_pixelsPerDB);             
    layDBUnitsPerPixel = ceil(1 / w->lay_pixelsPerDB);

    /* typical feature size */
    {
      int typical = MnTypicalWireWidth();
      if(typical != layTypicalWireWidth)
      {
	layTypicalWireWidth= typical;
 
	layCoarseFlush();
	
	/* "zoomed out" threshold. minimum pixel dimension (in database units)
	 * for which zoomed out redisplay is used.
	 */
	layPaintZOT = 0.5 * layTypicalWireWidth;
	if(layPaintZOT<2) layPaintZOT = 2;

	/* min coarse resolution (dbunits per pixel) */
	layCoarseRes = 1.5 * layTypicalWireWidth;
	if(layCoarseRes<2) layCoarseRes=2;
      }
    }

    /* edit cell info */
    {
      CellDef *winRootDef = WINDOW_DEF(layDisplayWindow);

      layAllSame = layDisplayWindow->lay_flags & Lay_ALLSAME;

      if (winRootDef == EditRootDef)
      {
	layEditDef = EditCellUse->cu_def;
	layEditTrans = EditToRootTransform;
      }
      else 
      {
	layEditDef = NULL;
      }
    }

    /* show redisplay cursor and setup for zoomed (out/in) redisplay */
    if( ! (w->lay_flags & Lay_SPECIAL) )
    {
      layCallBack(w->lay_interp, "redisplay_hook 1");
    }   

    /* select window for graphics output */
    layGraphicsWindow = GrRegisterWindow(w->lay_tkWin);

    /* Update root cell def for window
     * (This may add redisplay areas via calls to layChangedDef()) 
     */ 
    DBUpdate(w->lay_rootUse->cu_def);

    /* update window frame dependent redisplay parameters */
    layFrameUpdate(w);

    /* 
     *  GENERAL REDISPLAY - 
     */  

    /* redisplay areas marked in lay_genRedraw */
    if(!DBPlaneEmptyQ(w->lay_genRedraw))
    {
      UndoDisable();

      /* do general redisplay of marked areas (in lay_genRedraw plane) */
      DBPlaneEnumAreaPaint((Tile *) NULL,
			   w->lay_genRedraw, 
			   &w->lay_area, 
			   &DBAllButSpaceBits,
			   layDisplayGeneral, 
			   NULL);

      /* clear redraw plane */
      DBPlaneClearPaint(w->lay_genRedraw);

      UndoEnable();
    }
    
   /* 
    *   HIGHLIGHT REDISPLAY - 
    *   update areas marked in lay_hlErase and lay_hlRedrawDB planes.
    *
    *   NOTE: general update marks its areas for highlight update.
    */

    GrSetDrawable(layGraphicsWindow);

    /* don't clip highlight redisplay */
    layDrawSetClip(NULL,&w->lay_area);
    
    /* mark any areas that need to be highlighted due to
     * new feedback areas.
     */
    layFeedbackReportChanges(); 
    
    /* erase highlights in areas marked for erasure (in lay_hlErase plane) */
    if(!DBPlaneEmptyQ(w->lay_hlErase))
    {
      GrSetWriteMask(GrMaskColor);  

      DBPlaneEnumAreaPaint((Tile *) NULL, 
			   w->lay_hlErase, 
			   &w->lay_area, 
			   &DBAllButSpaceBits, 
			   layDisplayHLErase, 
			   (ClientData) w);
    }
    
    /* redraw highlights */
    layDisplayHLSelection(w, w->lay_hlRedrawDB);
    layDisplayHLFeedback(w, w->lay_hlRedrawDB); 
    layDisplayHLFlylines(w->lay_hlRedrawDB); 
    layDisplayHLBox(w, LDB_DISPLAY);
    layDisplayHLAnnotations(w,w->lay_hlRedrawDB); 

    /* clear redraw planes */ 
    DBPlaneClearPaint(w->lay_hlErase);
    DBPlaneClearPaint(w->lay_hlRedrawDB);

/*    fprintf(stderr,"layDisplay DEBUG, highlighting done\n"); */

    /* 
     *   POST REDISPLAY BOOKKEEPING
     */

   /* notify scrollbars if view changed */
   if(w->lay_flags & Lay_UPDATESCROLLBARS)
   {
     /* reset flag */
     w->lay_flags &= ~Lay_UPDATESCROLLBARS;

     /* horizontal scroll bar */
     if(w->lay_xScrollCmd && *(w->lay_xScrollCmd))
     {
       int cellMin, cellMax;
       int viewMin, viewMax;

       ASSERT(w->lay_rootUse,"layDisplay");
       cellMin = w->lay_rootUse->cu_def->cd_bbox.r_xbot;
       cellMax = w->lay_rootUse->cu_def->cd_bbox.r_xtop;
       viewMin  = w->lay_dbArea.r_xbot;
       viewMax  = w->lay_dbArea.r_xtop;

       layNotifyScrollBar(w->lay_interp, w->lay_xScrollCmd,
	 cellMin, cellMax, viewMin, viewMax);
     }
     /* vertical scroll bar */
     if(w->lay_yScrollCmd && *(w->lay_yScrollCmd))
     {
       int cellMin, cellMax;
       int viewMin, viewMax;

       /* note y inverted between DB and X coords */
       ASSERT(w->lay_rootUse,"layDisplay");
       cellMin = -(w->lay_rootUse->cu_def->cd_bbox.r_ytop);
       cellMax = -(w->lay_rootUse->cu_def->cd_bbox.r_ybot);
       viewMin  = -(w->lay_dbArea.r_ytop);
       viewMax  = -(w->lay_dbArea.r_ybot);

       layNotifyScrollBar(w->lay_interp, w-> lay_yScrollCmd,
	 cellMin, cellMax, viewMin, viewMax);
     }
   }
       
   /* FLUSH GRAPHICS */
   GrFlush();
   GrUnregisterWindow(layGraphicsWindow);
 
layDisplayDone:

    /* clear redisplay cursor */
    if( ! (w->lay_flags & Lay_SPECIAL) )
    {
        layCallBack(w->lay_interp, "redisplay_hook 0");
    }   

    /* reset redisplay flag */
    w->lay_flags &= ~Lay_REDRAWPENDING;

    /* reset interrupt flag */
    if (SigInterruptPending)
    {
      SigInterruptPending = FALSE;
      fprintf(stderr,"[Redisplay Interrupted]\n");
    }

/*  fprintf(stderr,"DEBUG layDisplay() done.\n");  */
    return;
}


/*
 * ----------------------------------------------------------------------------
 * LayDisplayInit --
 *
 *	Called at startup time, 
 *      after technology file read in and graphics initialization.
 *
 * ----------------------------------------------------------------------------
 */
void
LayDisplayInit(char *tech, char *techVar)
{
  /* initialize colormap and display styles */
  layColorMapInit();
  layStyleGroupsTwo(); 

  /* calculate minimum areas for text from space occupied by "BBB" */
  {
    int x0,y0,x1,y1;

    GrTextBBox("BBB", GR_TEXT_SMALL, 0, &x0, &y0, &x1, &y1);
    layMinText.p_x = x1-x0;
    layMinText.p_y = y1-y0;

    /* subcell text uses 3 rows (+ borders) */
    layMinSubcellText = layMinText;
    layMinSubcellText.p_y *= 4;
  }
}

