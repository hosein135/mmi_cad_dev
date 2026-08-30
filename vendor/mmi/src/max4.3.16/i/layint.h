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
 * layint.h --
 *
 * Internal interface for Layout module.
 *
 */

#ifndef _LAYINT
#define	_LAYINT

#ifndef _TCL
#include <tcl.h>
#endif

#ifndef _LAYOUT
#include "layout.h"
#endif

#ifndef _GRAPHICS
#include "graphics.h"
#endif


/* -------------- tunable constants ------------- */

/* min width (in pixels) or rectangle before we bother with 
 * diagonal X (as in contacts).
 */
#define CROSS_THRESHOLD	4

/* maximum number of stipple patterns */
#define MAX_STIPPLES	256

/* ----------------- data structures -------------- */

/* Each feedback area is stored in a record that looks like this: */
typedef struct feedback
{
    Rect fb_area;		/* The area to be highlighted, in coords of
				 * fb_rootDef, but prior to scaling by
				 * fb_scale.
				 */
    Rect fb_rootArea;		/* The area of the feedback, in Magic coords.
				 * of fb_rootDef, scaled up to the next
				 * integral Magic unit.
				 */
    char *fb_text;		/* Text explanation for the feedback. */
    CellDef *fb_rootDef;	/* Root definition of windows in which to
				 * display this feedback.
				 */
    float fb_scale;		/* Scale factor to use in redisplaying
				 * (fb_scale units in fb_area correspond
				 * to one unit in fb_rootDef).
				 */
    int fb_style;		/* Display style to use for this feedback. */
} Feedback;

typedef struct displaystyle 
{
    int ds_fillStyle;        /* rectangle fill style (see below) */
    int ds_writeMask;        /* write mask */
    int ds_color;            /* color */
    int ds_outline;          /* line pattern index */
    int ds_stipple;          /* stipple pattern index */
} DisplayStyle;

/* Rectangle filling styles.  
 * (note: this must match the array in grStyle.c)
 */
#define FILL_STYLE_SOLID 	0
#define FILL_STYLE_CROSS 	1
#define FILL_STYLE_OUTLINE	2
#define FILL_STYLE_STIPPLE 	3

/* zoomed out paint redisplay is broken into multiple passes with style
 * groups being drawn in order.  The idea is that the order of painting
 * within a style group does not matter.  This is literally true for
 * groups with sg_orthogonal set:  these groups assign a different bit
 * to each "color" used so that they are order independent.  In non-orthogonal
 * groups all bits are set for each style so only the last one painted (within
 * the group) remains visible.
 */
typedef struct stylegroup
{
    unsigned long sg_selMask;  	/* style is in group iff 
				 * (selSet && (color&selMask)) ||
				 * (!selSet && !(color&selMask))
				 */ 
    bool sg_selSet;   
    bool sg_orthogonal;         /* set if order of drawing within group doesn't
				 * matter.
				 */
    void *sg_stippleRev;           /* if non-null stipple for this group 
				    * (reversed)
				    */
    void *sg_stippleDimRev;     /* stipple to use to dim, for non-edit cell */
    int sg_number;              /* group ordinal, e.g. 1,2,3 */
    struct stylegroup *sg_next; 
} StyleGroup;
#define MAX_STYLE_GROUP 2

/* "cache" entry for cacheing pixels for subcell. */
typedef struct layoutcache
{
    CellDef *lc_def;		/* cell being cached */
    VStamp   lc_version;        /* cd_vDISPLAY this cache corresponds too */
    Transform lc_transform;     /* orientation */
    StyleGroup *lc_styleGroup;  /* paint style group being cached */
    int   lc_clippedEdges;      /* mask of edges that are clipped */
    Rect lc_relAreaDB;          /* area of pixmap relative to lower
				 * left corner of cell.
				 */
    Rect lc_area;               /* bbox of pixmap (0 0 width height) */
    void *lc_pixmap;            /* opaque pointer to graphics module "pixmap" */
    void *lc_stipple;           /* opaque pointer to graphics module "stipple"
				 * giving pixels written to in pixmap 
				 */
    struct layoutcache *lc_stack;   /* link for stack of "diversions" */
    struct layoutcache *lc_next;    /* list linked to this def */ 
} LayoutCache;

/* edge masks */
#define LE_LEFT  1
#define LE_RIGHT 2
#define LE_BOTTOM 4
#define LE_TOP 8

/* 
 * A single Pixel "image" is cached with a cell def for use when zoomed
 * way out.
 *
 * One color (value) is stored for each style group.
 * In addition colors are stored for labels and unexpanded subcell redisplay 
 */
#define PV_LABEL 0
#define PV_SUBCELL (MAX_STYLE_GROUP + 1)
#define PV_FLYLINE (MAX_STYLE_GROUP + 2)
#define PV_LAST PV_FLYLINE 
typedef struct pixelvalue
{
    VStamp               pv_version;  /* cd_vDISPLAY this value corresponds too */
    int                  pv_colors[PV_LAST + 1];
    
} PixelValue;

/* ----------------- shared data ----------------- */

/* layout widgets */
extern Layout *layTopWindow;
extern Layout *layBottomWindow;
extern Layout *layCurrent;           /* currently active window */
extern Layout *layDisplayWindow;
void *layGraphicsWindow;  /* graphics "window" corresponding to Layout widget
			   * currently being redisplayed.
			   */


/* edit info */
extern CellDef *layEditDef;
extern Transform layEditTrans;	
extern bool layAllSame;
		
/* feedback areas */
extern Feedback *layfbArray;
 
/* display styles */ 
extern void *layStippleTable[];
extern void *layLinePatternTable[];
extern DisplayStyle layDrawStyleTable[];
extern StyleGroup *layStyleGroups;

extern TileTypeBitMask	LayStyleToTypesTbl[MAXTILESTYLES];
extern int grBitPlaneMask;

/* stack of graphics diversions 
 * (subcells being diverted from window to pixmaps for cacheing)
 */
extern LayoutCache *layCacheStack;

/* used in layCache.c to restore original clip area after terminating 
 * pixmap diversion.
 */
extern Rect layDisplayAreaW;    /* clip area */

/* the two variables below are only valid during redisplay */
extern int layDBUnitsPerPixel;  /* (1 when zoomed in tight) */
extern int layPixelsPerDBUnit; /*  (0 when zoomed out) */

/* min window width or height (in database units) for which the "zoomed out"
 * version of redisplay is done.
 */
extern int layPaintZOT;

/* 
 * knob for redisplay resolution (in pixels)
 * initialized in LayDisplayInit()
 * linked to tcl var LAY_RES
 */
double layRes;

/* resolution of coarse version of paint planes used when zoomed out 
 * linked to tcl var LAY_COARSE_RES
 */
extern int layCoarseRes;

/* factor by which successive versions of paint planes 
 * get coarser.
 *
 * linked to tcl var LAY_COARSE_FACTOR
 */
extern double layCoarseFactor;

/* minimum factor by which a coarse plane must shrink data 
 *  
 * linked to tcl var LAY_COARSE_DATA_FACTOR
 */
extern double layCoarseDataFactor;

/* maximum ratio of total coarse data to corresponding paint data  
 *  
 * linked to tcl var LAY_COARSE_MAX_OVERHEAD
 */
extern double layCoarseMaxOverhead;

/* maximum changes relative to data size, before coarse planes
 * are completely regened.
 *  
 * linked to tcl var LAY_COARSE_FLUSH_FACTOR
 */
extern double layCoarseFlushFactor;

/* max cell diameter in pixels that gets painted with single pixel value */
extern int laySinglePixelThreshold;

/* if set, style groups are stippled (just before final write to window) during
 * zoomed out redisplay.
 */
extern bool layStippleGroups;

/* maximum subcell dimension that gets cached (in pixels),
 * linked to tcl var LAY_CACHE_MAX_DIM;
 */
extern int layCacheMaxDim;

/* if set stipple method used for clearing on group 2 copies */
extern bool layCacheStippleMethod;

/* width of box sides in pixels */ 
extern int layBoxLineWidth;

/* If both dimensions of box are <= to this # of pixels, a target is
 * drawn to help locate the box 
 */
extern int layBoxTargetThreshold;

/* cross hairs with respect to target center */
extern int layBoxHairBegin;
extern int layBoxHairEnd;

/* flyline tic extent in pixels */
extern int layFlyLineTic;

/* radius of grid origin in pixels */
extern int layGridOriginRadius;

/* size grid points (<= 0 to display grid lines instead) */
extern int layGridPointDiameterFine; 
extern int layGridPointDiameterCoarse; 

/* theshold for displaying grids */
extern int layGridMinPixelPitchFine; 
extern int layGridMinPixelPitchCoarse; 

/* label text and mark size in terms of typical wire widths */
extern double layLabelSizeFactor;

/* minimum radius of '+' for selected point labels (in pixels) */
extern int layLabelMinSelectedMark;

extern Point layMinText; /* minimum size text area */
extern Point layMinSubcellText; /* minimum size subcell before text added */

extern bool layRotatedText;  /* enables/disables rotated text */

/* enables/disables bboxes/text for unexpanded subcells. */
extern bool laySubcellShowUnexpanded;

/* --------------------- shared procedures  --------------------- */

/* initialization */
extern void layTclInit(Tcl_Interp *interp);
extern void layStylesTclInit(Tcl_Interp *interp);
extern void layTextTclInit(Tcl_Interp *interp);
extern void layColorMapTclInit(Tcl_Interp *interp);
extern void layStylesInit(void);
extern void layStyleGroupsOne(void);
extern void layStyleGroupsTwo(void);
extern void layColorMapInit(void);
extern void layTextInit(void);

/* current window and point */
extern void layCurSetWindow(Layout *window);
extern void layPointSetX(int x, int y);

/* annotation */
extern void layAnnotateTextAdd(Layout *w,
			       PointFloat location,
			       int pos, /* alignment */
			       int index, /* text style index */
			       char *text,
			       char *tag);
extern void layAnnotateTextClear(Layout *w, char *tag);

extern void layAnnotateLineAdd(Layout *w,
			       PointFloat p0,
			       PointFloat p1,
			       char *tag);
extern void layAnnotateLineClear(Layout *w, char *tag);
extern void layAnnotateLineDelete(Layout *w, int n, bool notify);

extern void layAnnotateDotAdd(Layout *w,
			      int diameter,
			      PointFloat center,
			      char *tag);
extern void layAnnotateDotClear(Layout *w, char *tag);
extern void layAnnotateDotDelete(Layout *w, int n, bool notify);

/* undo */
extern void LayUndoBox(CellDef *oldDef, 
		       Rect *oldArea, 
		       CellDef *newDef, 
		       Rect *newArea);

extern void LayUndoOldEdit(CellUse *editUse, 
			   CellDef *editRootDef, 
			   Transform *editToRootTrans, 
			   Transform *rootToEditTrans);

extern void LayUndoNewEdit(CellUse *editUse, 
			   CellDef *editRootDef, 
			   Transform *editToRootTrans, 
			   Transform *rootToEditTrans);

extern void LayUndoLoad(Layout *w, 
			CellDef *oldDef, 
			CellDef *newDef);

/* single pixel cacheing */
extern void layPixelInvalidate(CellDef *def);
extern bool layPixelValid(CellDef *def);
extern int layPixelGet(CellDef *def, int index);

/* coarse paint planes */
Plane **layCoarsePlanes(CellDef *def, int DBUnitsPerPixel);
void layCoarseFlush(void);
  
/* image cacheing */
extern LayoutCache *layCacheLookup(CellDef *def, 
				   Transform *t, 
				   StyleGroup *group,
				   Rect *relAreaDB);

extern void layCacheClear(CellDef *def);

extern void layCacheFlushClipped(int edges, 
				 CellDef *def);

extern LayoutCache *layCacheNew(CellDef *def, 
				Transform *t, 
				StyleGroup *group, 
				Rect *relAreaDB);


void LayCachePop(void);

void layCacheCopy(LayoutCache *lc, 
		  Rect *dest, 
		  Rect *relAreaDB);


void layCacheAdjustStippleOffset(Rect *dest, 
				 Rect *relAreaDB);

/* display scheduling */
extern void layFrameUpdate(Layout *w);
extern void layChangedWindowHL(Layout *w, Rect *area, bool erase);
extern void LayChangedDefHL(CellDef *rootDef, Rect *area, int erase);
extern void layChangedDefBox(CellDef *rootDef, bool erase);
extern void layFeedbackReportChanges(void);

/* display routines */
extern void layDisplay(ClientData clientData);
extern int layDisplayGeneral(Tile *tile, ClientData notUsed);
extern int layDisplayHLErase(Tile *tile, Layout *w);
extern void layDisplayHLFeedback(Layout *w, Plane *plane);
extern void layDisplayHLSelection(Layout *w, Plane *plane);
extern void layDisplayHLFlylines(Plane *plane);
extern void layDisplayHLAnnotations(Layout *w, Plane *plane);

/* layDisplayHLBox() called:
 *     1.  By layDisplay() with mode LDB_DISPLAY to redisplay box.
 *     2.  By layChangedDefBox() with mode LDB_CHANGED to mark old box for erasure.
 */
extern void layDisplayHLBox(Layout *window, int mode);
/* valid modes */
#define LDB_DISPLAY 1
#define LDB_CHANGED 2

/* text */
extern void layTextDrawOverlapStatsBegin(void);
extern double layTextDrawOverlapStatsEnd(void);
extern void layDrawText(char *str, 
			PointFloat *p, 
			int pos, 
			int size, 
			int adjust, 
			RectFloat *clip, 
			RectFloat *actual);

extern TextStyle *layTextStyleLookup(char *name);
extern int layTextFontFromStyle(Layout *w, TextStyle *ts, int *hp);

extern void
layLabelTextPoint(RectFloat *rect, int pos, PointFloat *point);

extern void 
layDisplayLabel(Label *l, Transform *trans, bool selected);

extern void
layDisplaySubcellText(SearchContext *scx,  
		      RectFloat *loc,  
		      bool showNames,      
		      bool showPorts);

extern void layLabelTextXBBox(char *text, 
               				/* Text of the label. */
	    int kind, 
	                                /* kind of label (e.g. LAB_INOUT) */
	    int pos, 
            				/* Position of the label relative
					 * to its positioning point.
					 */
	    int size, 
             				/* Text font size. */
	    Rect *area);
               				/* To be filled in with label size. */

/* X -> Window transform 
 *
 *   X has origin at upper left, Max at lower left.
 *
 * last visible coordinate is top edge-1 since pixels are closed
 * at lowerleft and open to top and right (e.g. pixel "address"
 * is coordinate of lower left corner of pixel area.
 *
 */
#define layXToPixel(l,y) (l->lay_area.r_ytop - (y))

/* Window to DB transform */
extern double layDimWToDBF(Layout *w, int x);
extern void layPointWToDBF(Layout *w, int x, int y, PointFloat *result);
extern void layRectWToDB(Layout *w, Rect *r, Rect *result);
extern void layRectWToDBInside(Layout *w, Rect *rW, Rect *rDB);


/*
 *-----------------------------------------------------------------------------
 *
 * layDisplayIsEdit --
 *
 * Determine whether current use in searchcontext is the edit use.
 *
 *-----------------------------------------------------------------------------
 */

static __inline__ bool layDisplayIsEdit(SearchContext *scx)
{
  return ( (layEditDef == scx->scx_use->cu_def)     &&
	   (scx->scx_trans.t_a == layEditTrans.t_a) &&
	   (scx->scx_trans.t_b == layEditTrans.t_b) &&
	   (scx->scx_trans.t_c == layEditTrans.t_c) && 
	   (scx->scx_trans.t_d == layEditTrans.t_d) &&
	   (scx->scx_trans.t_e == layEditTrans.t_e) &&
	   (scx->scx_trans.t_f == layEditTrans.t_f));
}

/* DB to Window transform (inlined for efficiency) */

/*
 * ----------------------------------------------------------------------------
 *
 * layDimToWindow --
 *
 *      Transform a DB dimension (height or width) to corresponding 
 *      dimension in window pixel coordinates.
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ double
layDimToWindow(Layout *w, int dDB) /* distance to transform */
{
  return dDB*w->lay_pixelsPerDB;
}

static __inline__ double
layDimFToWindow(Layout *w, double dDB) /* distance to transform */
{
  return dDB*w->lay_pixelsPerDB;
}


/*
 * ----------------------------------------------------------------------------
 *
 * layPointToWindow --
 *
 * 	Transform Point from database to window coordinates.
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ void
layPointToWindow(Layout *w, Point *pDB, PointFloat *result)
{
  result->pf_x = (pDB->p_x - w->lay_dbArea.r_xbot)*w->lay_pixelsPerDB;
  result->pf_y = (pDB->p_y - w->lay_dbArea.r_ybot)*w->lay_pixelsPerDB;
}

static __inline__ void
layPointToWindowInt(Layout *w, Point *pDB, Point *result)
{
  result->p_x = (pDB->p_x - w->lay_dbArea.r_xbot)*w->lay_pixelsPerDB;
  result->p_y = (pDB->p_y - w->lay_dbArea.r_ybot)*w->lay_pixelsPerDB;
}

static __inline__ void
layPointFToWindow(Layout *w, PointFloat *pfDB, PointFloat *result)
{
  result->pf_x = (pfDB->pf_x - w->lay_dbArea.r_xbot)*w->lay_pixelsPerDB;
  result->pf_y =  (pfDB->pf_y - w->lay_dbArea.r_ybot)*w->lay_pixelsPerDB;
}


/*
 * ----------------------------------------------------------------------------
 *
 * layRectToWindow --
 *
 *       Transform a DB rect to window coordinates.
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ void
layRectToWindow(Layout *w, Rect *rDB, RectFloat *result)
{
  layPointToWindow(w, &rDB->r_ll, &result->rf_ll);
  layPointToWindow(w, &rDB->r_ur, &result->rf_ur);
}

static __inline__ void
layRectFToWindow(Layout *w, RectFloat *rDB, RectFloat *result)
{
  layPointFToWindow(w, &rDB->rf_ll, &result->rf_ll);
  layPointFToWindow(w, &rDB->rf_ur, &result->rf_ur);
}

static __inline__ void
layRectToWindowInt(Layout *w, Rect *rDB, Rect *result)
{
  layPointToWindowInt(w, &rDB->r_ll, &result->r_ll);
  layPointToWindowInt(w, &rDB->r_ur, &result->r_ur);
}


/*
 * ----------------------------------------------------------------------------
 *
 * layPointsFToWindow --
 *
 *       Transform point list (e.g. polygon vertices) 
 *       from DB to window coords.
 *
 *       NOTE: uses ll + offset method, so that object dimensions
 *       don't vary with location!
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ void
layPointsFToWindow(Layout *w, 
		     Rect *bbox, 
		     int n,  /* num points */
		     PointFloat *pfDB,  
		     PointFloat *result)
{
  PointFloat *done = pfDB + n;

  while(pfDB != done)
  {
    layPointFToWindow(w, pfDB, result);
    result++;
    pfDB++;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * layStyleInGroup --
 *
 *       Determine whether style belongs to stylegroup.
 *
 *       Returns TRUE if style is in group.  
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ bool 
layStyleInGroup(int style, StyleGroup *group)
{
  unsigned long color = layDrawStyleTable[style].ds_color;
  unsigned long selMask = group->sg_selMask;
  bool selSet = group->sg_selSet;

  return selSet ? ((color&selMask) != 0) : ((color&selMask) == 0);
}

/* --------------------- macros --------------------- */
#define	LayStyleToTypes(s)	(&LayStyleToTypesTbl[s])
#define WINDOW_DEF(w)	(w->lay_rootUse->cu_def)


/* --------------------- coarse redisplay --------------------- */

/* following structure used to keep coarse resolution tile planes 
 * for use when zoomed out 
 */
typedef struct coarse
{
  int c_res;
  Plane *c_planes[MAXPLANES];
  char c_flags[MAXPLANES];
  struct coarse *c_next; 
  struct coarse *c_prev; 
} Coarse;

/* set if a plane is just a reference to a less coarse plane */
#define CFLG_COPY 1

/* this struct attached to cd_coarseDB of CellDef */
typedef struct coarsedb
{
  double cdb_opsOrig[MAXPLANES]; /* used to detect massive changes to paint */
  double cdb_opsLast[MAXPLANES]; /* used to detect no change to paint */
  int cdb_totTiles[MAXPLANES];   /* keep track of total size of data */
  Plane *cdb_update;  /* keep track of region that need updating */
  Coarse *cdb_coarse;  /* list of coarse strucs for this def */
  Coarse *cdb_last;    /* last coarse struc */
} CoarseDB;
  

/*** incremental change processing ***/

/* max number of changes before we give up incremental redisplay
 * and redisplay everything (avoids excessive change/notify overhead)
 */
extern int layMaxIncremental;

/* number of change notifications since last redisplay */
extern int layNumChanges;

/* set when full redispisplay of all windows is desired */
extern bool layRedisplayAllPending;

#endif _LAYINT








