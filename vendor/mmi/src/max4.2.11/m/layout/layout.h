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
 * layout.h --
 *
 * External interface for Layout package.
 *
 * This package implements layout window widgets
 *
 * rcsid $Header$
 */

#ifndef _LAYOUT
#define	_LAYOUT

#ifndef _TK
#include <tk.h>
#endif

#ifndef _GEOMETRY
#include "geometry.h"
#endif

#ifndef _DATABASE
#include "database.h"
#endif

typedef struct textannotation {
  Rect ta_bbox;
  PointFloat ta_location;
  int ta_pos;
  int ta_fontSize;
  char *ta_text;
  char *ta_tag;
  struct textannotation *ta_next;
} TextAnnotation;

typedef struct lineannotation {

  Rect la_bbox;
  PointFloat la_p1;
  PointFloat la_p2;
  char *la_tag;
  struct lineannotation *la_next;
} LineAnnotation;

typedef struct dotannotation {

  Rect da_bbox;
  int da_diameter;
  PointFloat da_center;
  char *da_tag;
  struct dotannotation *da_next;
} DotAnnotation;

/* Data struc for Layout widgets.
 *
 * Kept in doubly linked list.
 *
 */
typedef struct layout {
  Tk_Window lay_tkWin;	/* Tk Window for this Layout widget.  NULL
			 * means that the window has been destroyed. */

  Display *lay_display;	/* Display containing widget.  Needed to
			 * free up resources after tkwin is gone. */

  Tcl_Interp *lay_interp;	/* Interpreter associated with LAYWIN. */

  int lay_bitmask;		/* A single bit in a word, unique between all
				 * layout windows.  Any cell that is expanded
				 * in this window has this bit set in its
				 * expand mask.
				 */

  int lay_flags;		/* Various flags;  see below for
				 * definitions. */

  char *lay_xScrollCmd;        /* Prefix of command to issue to update
				* horizontal scrollbar when view changes */

  char *lay_yScrollCmd;        /* Prefix of command to issue to update
				* vertical scrollbar when view changes */

  int lay_widthReq;	/* If > 0, these specify dimensions to request
			 * for window (in pixels). */
  int lay_heightReq;

  CellUse *lay_rootUse;       /* Toplevel cell in displayed window. 
			       * Set via LayloadWindow().
			       */

  Rect lay_area;		/* The area of the window in pixel
				 * coordinates.
				 */

  /*** graphics buffers (overlays) ***/
  void *lay_genOverlay;        /* opaque pointer to graphics module Pixmap
			      * (general redisplay buffer)
			      */

  /*** frame (DB to pixel transform) ***/
  Rect lay_dbArea;		/* Window frame (view) in database coordinates 
				 * = max db rect fully visible in window
				 * (generally fraction of db unit more visible
				 *  to top and right)
				 */

  Rect lay_dbAreaReq;        	/* last frame request (may differ from dbArea 
				 * above do to aspect ratio of window.
				 */

  double lay_pixelsPerDB;	/* scale factor for converting from db units
				 * to pixels.
				 */

  Rect lay_lastDBArea;	      /* old frame used for detecting frame changes */
  double lay_lastPixelsPerDB;  /* old scale for detecting scale changes */ 
  double lay_lastLabelSizeFactor;  /* old label size controls used for detecting
				  *  need to recompute frame dependent quantities
				  */
  double lay_lastLabelMinSelectedMark; 

  /***  annotations ***/ 
  TextAnnotation *lay_textAnnotations;
  LineAnnotation *lay_lineAnnotations;
  DotAnnotation *lay_dotAnnotations;
  
  /*** pending redisplay areas ***/

  ClientData lay_genRedraw;	/* Areas requiring general redisplay 
				 * (window coordinates)
				 */
  Plane *lay_hlErase;		/* Areas where highlights need to be erased
				 * (window coordinates)
				 */
  Plane *lay_hlRedrawDB;	/* Areas where highlights need to be redrawn
				 * (database coordinates)
				 */

  /*** fields controlling redisplay ***/

  TileTypeBitMask lay_visibleLayers;
				/* This bit mask tells which mask layers
				 * should be displayed on the screen.
				 */

  Rect lay_gridFineRect;	/* Defines fine grid in world coordinates:  grid
				 * lines run along sides of rect, rect size
				 * determines spacing.
				 */
  Rect lay_gridCoarseRect;	/* Defines coarse grid in world coordinates:  
				 * grid lines run along sides of rect, 
				 * rect size determines spacing.
				 */

  Rect lay_labelExtents;	/* The sides of this rectangle are expanded
				 * out from the origin by the same amount
				 * that a redisplayed area should be expanded
				 * in order to catch all labels.  This
				 * reflects the size of the largest label
				 * displayed anywhere in the window.
				 *
				 * adding flylines as well.
				 */
  int lay_labelMarkSize;        /* length of arms of '+' for point labels
				 * in pixels.  (included in lay_labelExtents
				 * above).
				 */
  int lay_labelSize;		/* What size to use for text when drawing
				 * labels in this window (e.g. GR_TEXT_SMALL).
				 * This is recomputed each time the window
				 * is completely redrawn.  -1 means don't
				 * draw labels at all.
				 */

  int lay_watchPlane;        	/* The plane number of a plane to watch
				 * (show tile structure)
				 */

  /*** links ***/

  struct layout *lay_next; /* A doubly-linked list */
  struct layout *lay_prev; /* A doubly-linked list */
} Layout;

/* Flag values for lay_flags:

 * Lay_REDRAWPENDING:	Non-zero means a DoWhenIdle handler
 *			has already been queued to redraw
 *			this window.
 * Lay_UPDATESCROLLBARS:    Set after view change to cause scrollbar
 *                          notification on next redisplay
 * Lay_SPECIAL:         Set for special "icon" Layout windows
 *                      such as used in palette.
 *
 * Lay_ALLSAME:		Means don't use different display styles for
 *			edit and other cells.
 *
 * Lay_GRIDFINE:	Means fine grid is to be displayed in window.
 * Lay_GRIDCOARSE:	Means coarse grid is to be displayed in window.
 *
 * Lay_LABELSNONEDIT    Means display Comment and Local labels for all cells
 *                      (not just edit cell)
 *
 * Lay_SEELABELS:	0 means don't display labels ever.
 * Lay_SEEFLYLINES:	0 means don't display flylines ever.
 * Lay_SEEHIDDENLABELS  1 means display hidden labels (for debugging).
 * Lay_SEEINSTANCENAMES 0 means don't display names for unexpanded instances.
 * Lay_SEEINSTANCEPORTS 0 means don't display ports for unexpanded instances.
 *
 * Lay_SEEHIDDENLABELS  1 means display hidden labels (for debugging).
 *
 * Lay_SEETYPES		display tiletype instead of tile address - on watch plane
 * Lay_SEEGROUPS	display groups instead of tile address - on watch plane 
 */

#define Lay_REDRAWPENDING	 (1<<0)
#define Lay_UPDATESCROLLBARS     (1<<1)
#define Lay_SPECIAL              (1<<2)

#define Lay_ALLSAME              (1<<3)

#define Lay_GRIDFINE             (1<<4)
#define Lay_GRIDCOARSE           (1<<5)

#define Lay_SEELABELS            (1<<6)
#define Lay_SEEFLYLINES          (1<<7)
#define Lay_SEEINSTANCENAMES     (1<<8)
#define Lay_SEEINSTANCEPORTS     (1<<9)

#define Lay_SEEHIDDENLABELS      (1<<10)

#define Lay_SEETYPES             (1<<12)
#define Lay_SEEGROUPS            (1<<13)

#define Lay_LABELSNONEDIT        (1<<14)


/*
 * first MAXTILESTYLES reserved for rendering edit cell 'paint' 
 *
 * second MAXTILESTYLES reserved for dimmed versions (n -> n+MAXTILESTYLES)
 * of paint (used for paint not in edit cell).
 *
 */
#define	MAXTILESTYLES	1000

/* The following expansion mask can be used to select all layout windows */
#define LAY_MAX_WINDOW_CONTEXTS 16
#define LAY_ALL_WINDOWS  0177777

/* --------------------- Global Variables --------------------- */
extern int LayFeedbackCount;

/* --------------------- Global procedure headers --------------------- */

/* initialization */
extern void LayoutInit();
extern void LayoutTclInit(Tcl_Interp *interp);
extern void LayDisplayInit(char *tech, char *techVar);

/* styles */
extern TileTypeBitMask	LayStyleToTypesTbl[MAXTILESTYLES];
#define	LayStyleToTypes(s)	(&LayStyleToTypesTbl[s])

/* search */
extern int WindSearch(CellUse *rootUse, Rect *surfaceArea, int (*func)(/* ??? */), ClientData clientData);

/* load */
extern void LayloadWindow(Layout *window, char *name);

/* window mangager interaction */
extern void WindIconChanged(Layout *w);

/* view */
extern void LayFrame(Layout *w, Rect *areaDB);

/* redisplay */
extern void LayChangedWindow(Layout *w, Rect *area);
extern void LayChangedDisplay(Layout *w);
extern void LayChangedSelection(CellDef *rootDef, Rect *area, int erase);
extern void LayChangedHighlight(CellDef *rootDef, Rect *area, int erase);
extern void LayChangedDef(CellDef *rootDef, Rect *area, TileTypeBitMask *layers);
extern void LayChangedScheduleDef(CellDef *rootDef);
extern void LayCoarseChange(CellDef *def, Rect *area);

/* box and point */
extern Layout *LayPointGet(Point *rootPoint, Rect *rootArea);
extern Layout *ToolGetBoxWindow(Rect *rootArea, int *pMask);
extern bool ToolGetBox(CellDef **rootDef, Rect *rootArea);
extern void LaySetBox(CellDef *rootDef, Rect *rect);

/* feedback */
extern void LayFeedbackClear(void);
extern void LayFeedbackAdd(Rect *area, 
			   char *text, 
			   CellDef *cellDef, 
			   float scaleFactor, 
			   int style);
extern char *LayFeedbackNth(int nth, Rect *area, CellDef **pRootDef, int *pStyle);

/* current context */
extern Layout *LayCurWindow();  /* Used by Mgc module to pass current Window
				 * To Magic commands.
				 * Hopefully this can be eliminated sometime,
				 * as modularity would be much better if
				 * Layout strucs were strictly internal
				 * to this module.
				 */

#endif _LAYOUT

