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



/* layDraw.h -
 *
 *  layDraw = Low level routines called by layDisplay code.
 *  These routines: 
 *       interface to Graphics module.
 *       implement display styles.
 *       clipping.
 *       
 */

#ifndef _LAYDRAW
#define	_LAYDRAW

#ifndef _GEOMETRY
#include "geometry.h"
#endif

#ifndef _DEBUG
#include "debug.h"
#endif



/* current display style */
extern int layDrawCurStyle;
extern bool layDrawFillInitDone; /* style has been setup for area fill? */
extern bool layDrawLineInitDone;   /* style has been setup for line drawing? */
extern int layDrawCurFill;             /* fill style for current style */
extern int layDrawCurOutline;          /* outline for current style */  

/* clip rectangle - used by layFillRect() and layDrawLine() */
/* NULL means no clipping */
/* (in pixel coordinates) */
extern RectFloat layDrawCurClip;

/*** FUNCTION PROTOTYPES ***/

extern void layDrawSetClip(Rect *clip, Rect *window);


/*** INLINED FUNCTIONS ***/

/*---------------------------------------------------------
 * layDrawClippedLine --
 *
 *         PRIMITIVE used in routines below
 *         Clip line and pass on to graphics module.
 *         
 *
 *---------------------------------------------------------
 */
static __inline__ void 
layDrawClippedLine(double x1, double y1, double x2, double y2)
{
  if(!geoClipLine(&x1, &y1, &x2, &y2, &layDrawCurClip)) return;
  GrDrawLine(x1, y1, x2, y2);
}

/*---------------------------------------------------------
 * layFillClippedRect --
 *
 *         PRIMITIVE used in routines below
 *         Clip rectangle and pass on to graphics module.
 *         
 *
 *---------------------------------------------------------
 */
static __inline__ void
layFillClippedRect(RectFloat *r)
{
  if(!GEO_TOUCHF(r, &layDrawCurClip)) return;
  GEOCLIPF(r, &layDrawCurClip);
  GrFillRect(r->rf_xbot, r->rf_ybot, r->rf_xtop, r->rf_ytop);  
}


/*---------------------------------------------------------
 * layFillClippedPolygon --
 *
 *         PRIMITIVE used in routines below
 *         Clip polygon and pass on to graphics module.
 *         
 *
 *---------------------------------------------------------
 */
static __inline__ void 
layFillClippedPolygon(int numPoints, double *coords)
{
  Polygon poly;  
  Rect clip;
  int num, i; 
  PointFloat **listp;

  /* THIS IS A HACK: For now build fake polygon for clipping. */
  poly.poly_size = numPoints;
  poly.poly_points = (PointFloat *) coords;

  /* compute bbox */
  {
    RectFloat bboxF;
    int i;

    bboxF.rf_xbot = bboxF.rf_xtop = *(coords++);
    bboxF.rf_ybot = bboxF.rf_ytop = *(coords++);

    for(i=1;i<numPoints;i++)
    {
      double x = *(coords++);
      double y = *(coords++);

      bboxF.rf_xbot = MIN(bboxF.rf_xbot, x);
      bboxF.rf_xtop = MAX(bboxF.rf_xtop, x);
      bboxF.rf_ybot = MIN(bboxF.rf_ybot, y);
      bboxF.rf_ytop = MAX(bboxF.rf_ytop, y);
    }
    GEOCLIPF(&bboxF,&TiPlaneRectF); /* guard against overflow */
    geoRectF2Rect(&bboxF,&poly.poly_bbox);
  }

  /* clip */
  /* ANOTHER HACK, need to convert clip rect to ints for now */ 
  geoRectF2Rect(&layDrawCurClip,&clip);
  /* ANOTHER HACK, software clip is just to avoid overflow, expand
   * a little to avoid extra work for polygons touching bbox.
   * Note right now polygons can actually extend almost 2 units to right
   * of bbox for some reason?
   */
  GEO_EXPAND(&clip,10,&clip); 
  num = DBPolygonIntersectRect(&poly, &clip, &listp);

  /* draw the resulting polygon(s) */
  for(i=0;i<num;i++) GrFillPolygon(listp[i+1]-listp[i],   /* num points */
				   (double *) listp[i]);  /* point list */
}

/*
 * ----------------------------------------------------------------------------
 * layDrawStyle --
 *
 *	Set current graphics style.
 *
 *      Determines appearance of lines and rects output by subsequent
 *      calls to layDrawLine() and layDrawRect()
 *
 *      Actual setup deferred to layDrawStyleInit() 
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ void
layDrawStyle(int style)
{
  DisplayStyle *new; 

  layDrawCurStyle = style;

  new = &layDrawStyleTable[style];

  if(layCacheStack)
  {
    /* when cacheing, draw everything solid
     * (group 2 gets stippled on final copy to window)
     */
    layDrawCurFill = FILL_STYLE_SOLID;
    layDrawCurOutline = 0;
  }
  else
  {
    layDrawCurFill = new->ds_fillStyle;
    layDrawCurOutline = new->ds_outline;
  }

  layDrawFillInitDone = FALSE;
  layDrawLineInitDone = FALSE;
}

/*---------------------------------------------------------------------------
 * layDrawStyleInit --
 *
 *	Setup graphics for drawing sequence of lines, or filled regions
 *      
 * Side Effects:
 *	None.
 *
 *----------------------------------------------------------------------------
 */
static __inline__ void
layDrawStyleInit(bool fill)
{
  int mask, color;
  DisplayStyle *new; 

  /* filter redundant sets */
  if(fill)
  {
    if(layDrawFillInitDone == TRUE) return;
    layDrawFillInitDone = TRUE;
  }
  else
  {
    if(layDrawLineInitDone == TRUE) return;
    layDrawLineInitDone = TRUE;
  }

  new = &layDrawStyleTable[layDrawCurStyle];
  /* If diverting output to Pixmap,
   * use pixwrite plane (bit) to keep track of 
   * which pixels written.
   *
   */
  mask = new->ds_writeMask; 
  color = new->ds_color; 

  if(layCacheStack)
  {
    mask |= GrMaskFlag;
    color |= GrMaskFlag;
    GrSetStipple(NULL);
  }
  else
  {
    GrSetStipple(layStippleTable[new->ds_stipple]);
  }

  /* DEBUG 
  fprintf(stderr,
	  "DEBUG layDrawStyleInit, layDrawCurStyle=%d mask=%#o color=%#o\n",
	  layDrawCurStyle,mask,color);
  */

  /* setup style in graphics */
  GrSetWriteMask(mask);
  GrSetColor(color);

  /* line style if drawing lines */
  if(!fill)
  {
    GrSetLinePattern(layLinePatternTable[new->ds_outline]);
  }
}

/*---------------------------------------------------------
 * layDrawLine -
 *
 *	Display a line in the current style.
 *
 *      NOTE:  There must be no intervening graphics calls between
 *      layDrawStyle() and layDrawLine() call(s).
 *
 *      The style determines color, solid or dashed, etc. 
 *
 *---------------------------------------------------------
 */
static __inline__ void
layDrawLine(double x1, double y1, double x2, double y2)
{
    layDrawStyleInit(FALSE);
    layDrawClippedLine(x1,y1,x2,y2);
}

/*---------------------------------------------------------
 * layDrawRect --
 *
 *	Display a rectangle.
 *
 *      NOTE:  layDrawRectSetup() must be called first, and there
 *             must be no intervening graphics between layDrawRectSet()
 *             and layDrawRect() calls. 
 *
 *      Depending on the style, the rectangle can be displayed
 *      as a solid filled region, a stipple pattern, an outline, 
 *      or an X (as in contacts).
 *
 *---------------------------------------------------------
 */
static __inline__ void
layDrawRect(RectFloat *r) 
                		/* The rectangle to be drawn, given in
				 * pixel coordinates.
			         */
{
  /*** FILL ***/
  switch(layDrawCurFill)
  {
  case FILL_STYLE_SOLID:
  case FILL_STYLE_STIPPLE:
    layDrawStyleInit(TRUE);
    layFillClippedRect(r);
    break;

  case FILL_STYLE_CROSS:
    /* skip tiny rectangles */
    if(r->rf_xtop - r->rf_xbot < CROSS_THRESHOLD &&
       r->rf_ytop - r->rf_ybot < CROSS_THRESHOLD) return;

    layDrawStyleInit(FALSE);
    layDrawClippedLine(r->rf_xbot, r->rf_ybot, r->rf_xtop, r->rf_ytop);
    layDrawClippedLine(r->rf_xbot, r->rf_ytop, r->rf_xtop, r->rf_ybot); 
    /* fall through to outline */

  case FILL_STYLE_OUTLINE:
    if(layDrawCurOutline != 0)
    {
      layDrawStyleInit(FALSE);
      layDrawClippedLine(r->rf_xbot, r->rf_ybot, r->rf_xbot, r->rf_ytop);
      layDrawClippedLine(r->rf_xbot, r->rf_ytop, r->rf_xtop, r->rf_ytop);
      layDrawClippedLine(r->rf_xtop, r->rf_ytop, r->rf_xtop, r->rf_ybot);
      layDrawClippedLine(r->rf_xtop, r->rf_ybot, r->rf_xbot, r->rf_ybot);
    }
  }
}


/*---------------------------------------------------------
 * layDrawPolygon --
 *
 *	Display a polygon (used for 45s)
 *
 *      NOTE:  layDrawRectSetup() must be called first, and there
 *             must be no intervening graphics between layDrawRectSetup()
 *             and layDrawPolygon() calls. 
 *
 *      Depending on the style, the polygon can be displayed
 *      as a solid filled region, a stipple pattern, or an outline. 
 *
 *---------------------------------------------------------
 */
static __inline__ void
layDrawPolygon(int numPoints, double *coords) 
                		/* The polygon to be drawn in
				 * pixel coordinates.
			         */
{
  switch(layDrawCurFill)
  {
  case FILL_STYLE_SOLID:
  case FILL_STYLE_STIPPLE:
    layDrawStyleInit(TRUE);
    layFillClippedPolygon(numPoints, coords);
    return;

  case FILL_STYLE_CROSS:  /* outline "cross style" for polygons */ 
  case FILL_STYLE_OUTLINE:
    if(layDrawCurOutline != 0)
    {
      int i;
      int limit = (numPoints-1)*2;

      layDrawStyleInit(FALSE);
      for(i=0;i<limit; i= i+2)
      {
	layDrawClippedLine(coords[i],coords[i+1],coords[i+2],coords[i+3]);
      }
      layDrawClippedLine(coords[i],coords[i+1],coords[0],coords[1]);
    }
    return;
  }
}

/*---------------------------------------------------------
 * layDrawPixels
 *
 *	Copy a color to a rectangle 
 *      (used for rendering subcells 2 or less pixels in diameter)
 * 
 *      DOES NOT USE CURRENT STYLE.  Should not intervene between
 *      layDrawStyle() and layDrawRect() or layDrawLine() calls.
 *
 *---------------------------------------------------------
 */
static __inline__ void
layDrawPixels(RectFloat *r, int color, void *stipple)
{
  /* 0 color means don't draw */
  if(!color) return;

  if(layCacheStack) 
  {
    color |= GrMaskFlag;  /* buffers use flag plane to track 
			   * which pixels have been written.
			   */
    GrSetWriteMask(GrMaskAll);
    GrSetStipple(NULL);
  }
  else
  {
    GrSetStipple(stipple);
    GrSetWriteMask(GrMaskColor);
  }

  GrSetColor(color);

  layFillClippedRect(r); 
}

#endif _LAYDRAW






