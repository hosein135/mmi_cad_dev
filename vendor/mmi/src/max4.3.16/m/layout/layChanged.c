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



/* layChanged.c -
 *
 * Routines to mark changed areas that require redisplay in Layout windows,
 * and schedule their redisplay.
 *
 * (See layDisplay.c for the actual redisplay code.)
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
#include "magic.h"
#include "utils.h"
#include "message.h"
#include "geometry.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "commands.h"
#include "undo.h"
#include "signals.h"
#include "memory.h"
#include "layout.h"
#include "layint.h"
#include "graphics.h"
#include "debug.h"

/* max number of changes before we give up incremental redisplay
 * and redisplay everything (avoids excessive change/notify overhead)
 */
int layMaxIncremental = 1000; 

/* number of change notifications since last redisplay */
int layNumChanges = 0;

/* set when full redispisplay of all windows is desired */
bool layRedisplayAllPending = FALSE;


/*
 * ----------------------------------------------------------------------------
 * layChangedAll --
 *
 *	Schedule complete (nonincremental) redisplay of allwindows.
 *
 * ----------------------------------------------------------------------------
 */
static void layChangedAll(void)
{
  if(layRedisplayAllPending) return;

  /* DEBUG
  fprintf(stderr,"layChangedAll DEBUG layNumChanges=%d layMaxIncremental=%d\n",
	  layNumChanges, 
	  layMaxIncremental);
  */

  layRedisplayAllPending = TRUE;

  /* cancel pending partial redisplays! */
  {
    Layout *w;

    for(w= layTopWindow; w!= NULL; w = w->lay_next)
    {
      DBPlaneClearPaint(w->lay_genRedraw);
      DBPlaneClearPaint(w->lay_hlErase);
      DBPlaneClearPaint(w->lay_hlRedrawDB);
    }
  }

  Tcl_DoWhenIdle(layDisplay, 0 /* all windows */);
}
  

/*
 * ----------------------------------------------------------------------------
 * LayChangedWindow --
 *
 *      Schedule (partial) redisplay of window(s). 
 *
 *	Marks part of layout window for future redisplay, and schedule
 *      redisplay.
 *
 *	The area is noted as having changed in window w.  
 *	If area is NULL, the entire window is marked for redisplay.
 *      If w is NULL, all layout windows are marked for redisplay.
 *
 * ----------------------------------------------------------------------------
 */

void
LayChangedWindow(Layout *w, 
                 	/* The window that changed. */
		 Rect *area)
               		/* The area in pixel coordinates 
			 * NULL means the whole window. 
			 */
{
    Rect r;

    /* if incremental limit reached, redisplay all */
    if(layRedisplayAllPending) return;
    if(++layNumChanges > layMaxIncremental) 
    {
      layChangedAll();
      return;
    }

    /* for now, if an entire window is being redisplayed, forget about
     * incremental redisplay, and just redisplay everything.
     */
    if(area == NULL || GEO_SURROUND(area,&w->lay_area))
    {
      layChangedAll();
      return;
    }

    /* If w is NULL, call recursively for each layout windows */
    if (w == NULL) 
    {
        Layout *nw;
	for (nw = layTopWindow; nw != NULL; nw = nw->lay_next)
	{
	    LayChangedWindow(nw, area);
	}
	return;
    } 

    /* if no area specified, set to entire window */  
    if (!area) area = &w->lay_area;

    /* DEBUG
    fprintf(stderr,"DEBUG layChangedWindow(), rootDef=%s\n",
	    w->lay_rootUse->cu_def->cd_name);
    DumpRect("DEBUG area = ", area);
    */

    /* expand area one pixel to avoid edge effects, and clip to window */ 
    GEO_EXPAND(area, 1, &r);
    GEOCLIP(&r,&w->lay_area);

    /* Mark area in redisplay plane by painting an error tile over it. */
    UndoDisable();
    DBPaintPlane(w->lay_genRedraw, &r,
	    DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR), (PaintUndoInfo *) NULL);
    UndoEnable();

    /* Schedule redisplay for this window */
/*    fprintf(stderr,"DEBUG LayChangedWindow() isMapped = %d\n", 
	    Tk_IsMapped(w->lay_tkWin));
*/
    if (!(w->lay_flags & Lay_REDRAWPENDING) && Tk_IsMapped(w->lay_tkWin))
    {
	w->lay_flags |= Lay_REDRAWPENDING;
	Tcl_DoWhenIdle(layDisplay, (ClientData) w);
    }
}


/*
 * ----------------------------------------------------------------------------
 * layChangedWindowHL --
 *
 *	Mark part of layout window for future highlight redisplay, 
 *      and schedule it
 *
 *	The area is noted as having changed in window w.  
 *	If area is NULL, the entire window is marked for highlight redisplay.
 *      If w is NULL, all layout windows are marked for highlight redisplay.
 *
 * ----------------------------------------------------------------------------
 */

void
layChangedWindowHL(Layout *w, 
                 	/* The window that changed. */
		   Rect *area,
               		/* The area in screen coordinates.
			 * NULL means the whole window. 
			 */

		   bool erase)
                        /* if erase is set, the highlight area is erased
			 * before redraw.
			 */
{
    Rect eraseArea;
    Rect redrawArea;

    /* if incremental limit reached, redisplay all */
    if(layRedisplayAllPending) return;
    if(++layNumChanges > layMaxIncremental) 
    {
      layChangedAll();
      return;
    }

    /* If w is NULL, call recursively for each layout windows */
    if (w == NULL) 
    {
        Layout *nw;
	for (nw = layTopWindow; nw != NULL; nw = nw->lay_next)
	{
	   layChangedWindowHL(nw, area, erase);
	}
	return;
    } 

    /* If area NULL use entire window area */
    if (area == (Rect *) NULL) area = &w->lay_area;

    /* Increase bounds a bit, to avoid edge effects */
    eraseArea = *area;
    eraseArea.r_xbot -= 1;
    eraseArea.r_ybot -= 1;
    eraseArea.r_xtop += 2;
    eraseArea.r_ytop += 2;
    GEOCLIP(&eraseArea, &w->lay_area);

    /* mark for erase */
    if(erase)
    {
	DBPaintPlane(w->lay_hlErase, &eraseArea,
		DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
		(PaintUndoInfo *) NULL);
    }

    /* the highlight redraw plane is in database coordinates! */
    (void) layRectWToDB(w, &eraseArea, &redrawArea);

    /* expand area by one unit to avoid edge effects */
    GEO_EXPAND(&redrawArea, 1, &redrawArea);

    /* mark highlight redraw area */
    DBPaintPlane(w->lay_hlRedrawDB, &redrawArea,
	    DBStdPaintTbl(TT_ERROR_P, PL_DRC_ERROR),
	    (PaintUndoInfo *) NULL);

    /* Schedule redisplay for this window */
    if (!(w->lay_flags & Lay_REDRAWPENDING) && 
	Tk_IsMapped(w->lay_tkWin))
    {
	w->lay_flags |= Lay_REDRAWPENDING;
	Tcl_DoWhenIdle(layDisplay, (ClientData) w);
    }
}


/*
 * ----------------------------------------------------------------------------
 * LayChangedDef --
 *
 *	Called to notify layout module of need to redisplay area in def.
 *
 *      NOTE:  Only windows where def is the top-level-def are effected.
 *
 *      NOTE:  If any labels may have been deleted in the area, layers 
 *	       should be NULL. 
 *	       
 *             If layers = NULL, the area is automatically expanded enough to 
 *	       encompass any text that may have stuck out from labels in this 
 *	       area (so it is properly erased).
 *
 *	Returns:
 *	  FALSE - normally.
 *        TRUE  - if no incremental redisplay needed for this def 
 *                (used to terminate instance update loop) in layUpdate.c 
 *
 * ----------------------------------------------------------------------------
 */

/* helper func:  mark one window */
static __inline__ void
layChangedDefFunc(Layout *w,
               			/* Window in which to record area. */
		      Rect *area,
               			/* (Client data) Area to be redisplayed, in
				 * coordinates of the root definition.
				 *
				 * If NULL, redisplay entire window 
				 */
		      TileTypeBitMask *layers)
{
    Rect screenArea;
    TileTypeBitMask tmp;

    /* If none of the layers being redisplayed is visible in this
     * window, then there's no need to do anything.
     *
     * MHA:  Even when user turns ALL layers off, something is apparently
     *       left visible (space, drc?), so redisplay will not return here,
     *       but rather clear the layers just turned off from the screen,
     *       as desired.
     */
    
    if (layers != NULL)
    {
      TTMaskAndMask3(&tmp, layers, &w->lay_visibleLayers);
      if (TTMaskIsZero(&tmp)) return;
    }

    /* make sure lay_labelExtents is up-to-date */
    layFrameUpdate(w);

    /* if area NULL, redisplay entire window */
    if (area == NULL)
    {
      LayChangedWindow(w, NULL);
      return;
    }

    /* Compute screen area to redisplay, in pixels. */
    layRectToWindowInt(w, area, &screenArea);
    GeoClip(&screenArea, &w->lay_area);

    /* If labels might have been erased, expand the area enough
     * to include text that may have stuck out from these labels.
     */
    if (layers == NULL)
    {
	screenArea.r_xbot += w->lay_labelExtents.r_xbot;
	screenArea.r_ybot += w->lay_labelExtents.r_ybot;
	screenArea.r_xtop += w->lay_labelExtents.r_xtop;
	screenArea.r_ytop += w->lay_labelExtents.r_ytop;
    }

    /* If watching is enabled for this window, so sorry but the whole
     * thing will have to be redisplayed (even a small change could have
     * affected many many tiles.
     */
    if (w->lay_watchPlane >= 0) LayChangedWindow(w, (Rect *) NULL);
    else LayChangedWindow(w, &screenArea);
}

bool
LayChangedDef(CellDef *cellDef, 
                     		/* The cell definition that was modified 
				 * (or descendents were modified)
				 */
	       Rect *defArea, 
                  		/* The area of the definition that changed. */
	       TileTypeBitMask *layers)
                            	/* Indicates which layers were modified.  If
				 * NULL, it means that labels were deleted
				 * from defArea in addition to paint.  We'll
				 * have to redisplay a larger area in order
				 * to fully erase labels that used to stick
				 * out from defArea.  NULL is used when
				 * subcells are unexpanded or moved for
				 * example.  NULL is the most inclusive option
				 * (does everything that &DBAllButSpaceBits
				 * does and more), and should be used whenever
				 * you're not sure what to do.  
				 *
				 */
{
    Layout *w;

    /* if limit of incremental redisplay reached, just return */
    if(layRedisplayAllPending) return TRUE;
    if(++layNumChanges > layMaxIncremental) 
    {
      layChangedAll();
      return TRUE;
    }

/* DEBUG
    if(defArea)
    {
      fprintf(stderr,"DEBUG layChangedDefArea(): def=%s area=%d %d %d %d\n",
	      cellDef->cd_name, 
	      defArea->r_xbot, defArea->r_ybot, defArea->r_xtop, defArea->r_ytop);
    }
    else
    {
      fprintf(stderr,"DEBUG layChangedDefArea(): def=%s area=NULL\n",
	      cellDef->cd_name);
    }
*/

    /* if area degenerate, just return */
    if (defArea && layers &&
	(defArea->r_xbot == defArea->r_xtop ||	
	 defArea->r_ybot == defArea->r_ytop))
    {
      return TRUE;
    }

    /* special-case flyline-only redisplay 
     * (to avoid redrawing underlying layout)
     */
    if (layers && TTMaskEqual(layers, &DBFlyLineBits))
    {
      LayChangedDefHL(cellDef, 
			  defArea, 
			  TRUE);  /* we maybe erasing */
      return FALSE;
    }

    /* mark windows */
    {
      int hit = FALSE; 

      for (w = layTopWindow; w != (Layout *) NULL; w = w->lay_next)
      {
	if(w->lay_rootUse->cu_def != cellDef) continue;
	hit = TRUE;

	if(defArea && !GEO_TOUCH(defArea, &(w->lay_dbArea))) continue;
	layChangedDefFunc(w, defArea, layers);
      }

      return !hit;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * LayChangedDefHL --
 *
 * 	Schedule highlight redisplay of given area in given rootdef.
 *
 *      Highlights are "white".  They include, box,selection,feedback areas 
 *      and flylines.  The important thing about highlights is that, they
 *      use their own color-map plane, and hence can be changed without
 *      having to redraw "underlying" paint etc. 
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

/* variables for communciation between func and LayChangedDefHL */
static CellDef *layHLDef;
static bool layHLErase;

static int
layChangedHighlightFunc(Layout *window, 
                      		/* Window to redraw. */
			Rect *area)
               			/* area in database coordinates */
{
    Rect erase, redraw;
    Rect *expand;

    if (WINDOW_DEF(window) != layHLDef) return 0;

    /* make sure lay_labelExtents is up-to-date */
    layFrameUpdate(window);

    /* convert area window coordinates */
    layRectToWindowInt(window, area, &erase);

    /* Expand rectangle gives maximum distance text currently sticks
     * out from label areas (and flylines) in each direction.
     */
    expand = &window->lay_labelExtents;

    /* erase */
    if (layHLErase)
    {
        /* expand erase area to handle text sticking out from labels */
	erase.r_xbot += expand->r_xbot;
	erase.r_ybot += expand->r_ybot;
	erase.r_xtop += expand->r_xtop;
	erase.r_ytop += expand->r_ytop;

	layChangedWindowHL(window, &erase, TRUE /* erase */);
    }

    /* Expand area (again) so that text sticking into area from near by labels
     * gets redrawn
     */
    erase.r_xbot -= expand->r_xtop;
    erase.r_ybot -= expand->r_ytop;
    erase.r_xtop -= expand->r_xbot;
    erase.r_ytop -= expand->r_ybot;

    layChangedWindowHL(window, &erase, FALSE /* no erase */);

    /* continue search */
    return 0;
}

void
LayChangedDefHL(CellDef *rootDef, 
		                /* Highlight information will be redrawn in
				 * all windows for which this is the root
				 * cell definition.
				 */
		   Rect *area, 
               			/* The area over which to redraw.  Highlights
				 * will be redrawn in this area plus enough
				 * surrounding area to catch degenerate boxes
				 * (drawn as crosses) and labels that may
				 * stick out from their attachment points.
				 */
		   int erase)
               			/* TRUE means we should erase area before
				 * redrawing it.  FALSE means that either the
				 * client has erased the area, or there's no
				 * need to erase it because all that's
				 * happening is to add new information to the
				 * display.
				 */
{
    Rect ourArea;

    /* if limit of incremental redisplay reached, just return */
    if(layRedisplayAllPending) return;
    if(++layNumChanges > layMaxIncremental) 
    {
      layChangedAll();
      return;
    }

    layHLDef = rootDef;		/* Pass to search function. */
    layHLErase = erase;

    /* If we're passed a NULL area, expand it by one unit so that
     * we're certain to have non-zero area.  Otherwise the various
     * search procedures have big troubles.
     */
    ourArea = *area;
    if (ourArea.r_xbot >= ourArea.r_xtop)
	ourArea.r_xtop = ourArea.r_xbot + 1;
    if (ourArea.r_ybot >= ourArea.r_ytop)
	ourArea.r_ytop = ourArea.r_ybot + 1;

    /* mark area in all windows rooted at rootDef */
    (void) WindSearch((ClientData) NULL, 
		      &ourArea,
		      layChangedHighlightFunc, 
		      (ClientData) &ourArea);
}


/*
 * ----------------------------------------------------------------------------
 *
 * LayChangedDefSelection --
 *
 * 	Mark areas for selection redisplay 
 *      (in windows containing give rootDef)
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

void
LayChangedDefSelection(CellDef *rootDef, Rect *area, int erase)
{
    /* mark areas that require redisplay */
    LayChangedDefHL(rootDef, area, erase);
}
  
/*
 * ----------------------------------------------------------------------------
 *
 * layChangedDefBox --
 *
 * 	Schedule highlight redisplay due to change in box.
 *
 *      If erase is TRUE, we are erasing old box.
 *      If erase is FALSE, we are adding box at new location.
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
void
layChangedDefBox(CellDef *rootDef,
		         /* box root def */
		bool erase)
                         /* if true old box, erase it */
{

  /* if limit of incremental redisplay reached, just return */
  if(layRedisplayAllPending) return;
  if(++layNumChanges > layMaxIncremental) 
  {
    layChangedAll();
    return;
  }
  
  if(erase)
  {
    Layout *w;

    for (w = layTopWindow; w != (Layout *) NULL; w = w->lay_next)
    {
      if(w->lay_rootUse->cu_def != rootDef) continue;

      layDisplayHLBox(w, LDB_CHANGED);
    }
  }
  else
  {
    /* box redrawn on each redisplay,
     * so don't need to mark any particular area for highlight redisplay 
     */
    LayChangedScheduleDef(rootDef);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * LayChangedScheduleDef --
 *
 * 	Schedule redisplay for windows having rootDef as their root
 *      def.
 *
 *      NOTE:  This call does not specify which areas to redisplay.  The redisplay
 *             code does a DBUpdate() to generate calls to LayChangedDef()
 *             for areas that need redisplay.
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

void
LayChangedScheduleDef(CellDef *rootDef) 
		      /* Redisplay is scheduled for windows containing
		       * this def as root.
		       */
{
  Layout *w;

  /* if limit of incremental redisplay reached, just return */
  if(layRedisplayAllPending) return;
  if(++layNumChanges > layMaxIncremental) 
  {
    layChangedAll();
    return;
  }

  for (w = layTopWindow; w != (Layout *) NULL; w = w->lay_next)
  {
    if(w->lay_rootUse->cu_def != rootDef) continue;
    if (w->lay_flags & Lay_REDRAWPENDING) continue;
    if(!Tk_IsMapped(w->lay_tkWin)) continue;
   
    Tcl_DoWhenIdle(layDisplay, (ClientData) w);
    w->lay_flags |= Lay_REDRAWPENDING;
  }
}


/*
 * ----------------------------------------------------------------------------
 *	LayChangedDisplay --
 *
 * 	Called when something effecting redisplay is changed, 
 *      e.g. the layers visible on the screen or the styles for
 *      displaying layers are changed.
 *
 *      Flushes layout caches and schedules full redisplay.
 *
 * ----------------------------------------------------------------------------
 */
void
LayChangedDisplay(Layout *w)
               			/* Window effected NULL = all windows */
{
  layPixelInvalidate(NULL);   /* invalidate single pixel values for all defs */
  layCacheClear(NULL);        /* flush pixmap cache */
  LayChangedWindow(w, NULL);  /* redisplay all */
}
