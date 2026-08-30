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



/* geometry.h --
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
 *
 * This module contains the basic definitions for geometrical
 * elements:  points, rectangles, and transforms.
 */

#ifndef _GEOMETRY
#define _GEOMETRY 

#define TRUE 1
#define FALSE 0
#define bool int

/* NOTE: polygon and wirepath funcs (all angle geometry) are in
 * DBpolygon.c and DBwirepath.crespectively.
 */ 

/*-------------------------------------------------------------------
 * Structure definition for Point (an x,y pair).
 *-------------------------------------------------------------------
 */

typedef struct
{
    int p_x;
    int p_y;
} Point;

typedef struct
{
    double pf_x;	
    double pf_y;
} PointFloat;

/*-------------------------------------------------------------------
 * Structure definition for rectangles.  A rectangle is defined
 * by the coordinates of its lower-left and upper-right corners.
 * Most routines that manipulate rectangles require the first
 * point to really be the lower-left one, so be careful about this.
 * A null rectangle is indicated by making both x-coordinates the
 * same.
 *-------------------------------------------------------------------
 */

typedef struct
{
    Point r_ll;			/* Lower-left corner of rectangle. */
    Point r_ur;			/* Upper-right corner of rectangle. */
} Rect;

#define r_xbot r_ll.p_x
#define r_ybot r_ll.p_y
#define r_xtop r_ur.p_x
#define r_ytop r_ur.p_y

typedef struct G1		/* A linked rectangle */
{
    Rect r_r;			/* A rectangle. */
    struct G1 *r_next;		/* Pointer to another linked rectangle */
} LinkedRect;

typedef struct
{
    PointFloat rf_ll;			/* Lower-left corner of rectangle. */
    PointFloat rf_ur;			/* Upper-right corner of rectangle. */
} RectFloat;

#define rf_xbot rf_ll.pf_x
#define rf_ybot rf_ll.pf_y
#define rf_xtop rf_ur.pf_x
#define rf_ytop rf_ur.pf_y

static __inline__ void geoRect2RectF(Rect *r, RectFloat *result)
{
  result->rf_xbot = r->r_xbot;
  result->rf_ybot = r->r_ybot;
  result->rf_xtop = r->r_xtop;
  result->rf_ytop = r->r_ytop;
}

static __inline__ void geoRectF2Rect(RectFloat *r, Rect *result)
{
  result->r_xbot = r->rf_xbot;
  result->r_ybot = r->rf_ybot;
  result->r_xtop = r->rf_xtop;
  result->r_ytop = r->rf_ytop;
}

/*-------------------------------------------------------------------
 * Structure definition for geometrical transformers.  They are
 * stored in the form described by Newman and Sproull on page 57.
 * Magic allows only 90 degree orientations, and normally there
 * is no scaling (scaling only occurs when transforming to pixel
 * coordinates).  Thus the elements a, b, d, and e always have
 * one of the following forms, where S is the scaling factor:
 *
 *  S  0    0 -S    -S  0    0  S    S  0    0  S    -S  0    0 -S
 *  0  S    S  0     0 -S   -S  0    0 -S    S  0     0  S   -S  0
 *
 * The first four forms correspond to clockwise rotations of 0, 90,
 * 180, and 270 degrees, and the second four correspond to the same
 * four orientations flipped upside down (mirror across the x-axis
 * after rotating).
 *         
 *--------------------------------------------------------------------
 */

typedef struct
{
  int t_a, t_b, t_c, t_d, t_e, t_f; 
} Transform;

/*-------------------------------------------------------------------
 *	Definitions for positions.  Positions are small integers
 *	used to select where text gets placed, relative to a point.
 *-------------------------------------------------------------------
 */

#define GEO_CENTER	0
#define GEO_NORTH	1
#define GEO_NORTHEAST	2
#define GEO_EAST	3
#define GEO_SOUTHEAST	4
#define GEO_SOUTH	5
#define GEO_SOUTHWEST	6
#define GEO_WEST	7
#define GEO_NORTHWEST	8


/* See if two points are equal */
#define GEO_SAMEPOINT(p1, p2) ((p1).p_x == (p2).p_x && (p1).p_y == (p2).p_y)
#define GEO_SAMEPOINTF(p1, p2) ((p1).pf_x == (p2).pf_x && (p1).pf_y == (p2).pf_y)

/* See if two rects are equal */
#define	GEO_SAMERECT(r1, r2) \
    (GEO_SAMEPOINT((r1).r_ll, (r2).r_ll) && GEO_SAMEPOINT((r1).r_ur, (r2).r_ur))

/*-------------------------------------------------------------------
 *	The following macros are predicates to see if two
 *	rectangles overlap or touch.  
 *-------------------------------------------------------------------
 */

/* see if the rectangles overlap (the overlap contains some area) */

#define GEO_OVERLAP(r1, r2) \
    (((r1)->r_xbot < (r2)->r_xtop) && ((r2)->r_xbot < (r1)->r_xtop) \
    && ((r1)->r_ybot < (r2)->r_ytop) && ((r2)->r_ybot < (r1)->r_ytop))

/* see if the rectangles touch (share part of a side) or overlap */

#define GEO_TOUCH(r1, r2) \
    (((r1)->r_xbot <= (r2)->r_xtop) && ((r2)->r_xbot <= (r1)->r_xtop) \
    && ((r1)->r_ybot <= (r2)->r_ytop) && ((r2)->r_ybot <= (r1)->r_ytop))

#define GEO_TOUCHF(r1, r2) \
    (((r1)->rf_xbot <= (r2)->rf_xtop) && ((r2)->rf_xbot <= (r1)->rf_xtop) \
    && ((r1)->rf_ybot <= (r2)->rf_ytop) && ((r2)->rf_ybot <= (r1)->rf_ytop))

/* see if rectangle r1 completely surrounds rectangle r2.  Touching between
 * r2 and r1 IS allowed.
 */

#define GEO_SURROUND(r1,r2) \
    ( ((r2)->r_xbot >= (r1)->r_xbot) && ((r2)->r_xtop <= (r1)->r_xtop) \
    && ((r2)->r_ybot >= (r1)->r_ybot) && ((r2)->r_ytop <= (r1)->r_ytop) )

#define GEO_SURROUNDF(r1,r2) \
    ( ((r2)->rf_xbot >= (r1)->rf_xbot) && ((r2)->rf_xtop <= (r1)->rf_xtop) \
    && ((r2)->rf_ybot >= (r1)->rf_ybot) && ((r2)->rf_ytop <= (r1)->rf_ytop) )

/* see if rectangle r1 completely surrounds rectangle r2 WITHOUT touching it.
 */

#define GEO_SURROUND_STRONG(r1,r2) \
    ( ((r2)->r_xbot > (r1)->r_xbot) && ((r2)->r_xtop < (r1)->r_xtop) \
    && ((r2)->r_ybot > (r1)->r_ybot) && ((r2)->r_ytop < (r1)->r_ytop) )

#define GEO_SURROUND_STRONGF(r1,r2) \
    ( ((r2)->rf_xbot > (r1)->rf_xbot) && ((r2)->rf_xtop < (r1)->rf_xtop) \
    && ((r2)->rf_ybot > (r1)->rf_ybot) && ((r2)->rf_ytop < (r1)->rf_ytop) )

/* See if point p is inside of or on the border of r */
#define GEO_ENCLOSE(p, r)	\
    ( ((p)->p_x <= (r)->r_xtop) && ((p)->p_x >= (r)->r_xbot) &&  \
      ((p)->p_y <= (r)->r_ytop) && ((p)->p_y >= (r)->r_ybot) )


/* See if PointFloat p i inside of or on the border of r */
#define GEO_ENCLOSEF(p, r)	\
    ( ((p)->pf_x <= (r)->rf_xtop) && ((p)->pf_x >= (r)->rf_xbot) &&  \
      ((p)->pf_y <= (r)->rf_ytop) && ((p)->pf_y >= (r)->rf_ybot) )


/* See if point p is inside of r and NOT TOUCHING the border */
#define GEO_ENCLOSE_STRONG(p, r)	\
    ( ((p)->p_x < (r)->r_xtop) && ((p)->p_x > (r)->r_xbot) &&  \
      ((p)->p_y < (r)->r_ytop) && ((p)->p_y > (r)->r_ybot) )


/* See if PointFloat p i inside of or on the border of r */
#define GEO_ENCLOSEF_STRONG(p, r)	\
    ( ((p)->pf_x < (r)->rf_xtop) && ((p)->pf_x > (r)->rf_xbot) &&  \
      ((p)->pf_y < (r)->rf_ytop) && ((p)->pf_y > (r)->rf_ybot) )
    
/* See if a label is in a given area */
#define GEO_LABEL_IN_AREA(lab,area) \
    (GEO_SURROUND(area, lab) || \
	(GEO_RECTNULL(area) && GEO_TOUCH(lab, area) && \
	!(GEO_SURROUND_STRONG(lab, area))))

/* copy rect */
#define GEO_COPY_RECT(src,dst) \
{ \
    (dst)->r_xbot = (src)->r_xbot; \
    (dst)->r_ybot = (src)->r_ybot; \
    (dst)->r_xtop = (src)->r_xtop; \
    (dst)->r_ytop = (src)->r_ytop; \
}

/* See if a rectangle has no area. */
#define GEO_RECTNULL(r) \
    (((r)->r_xbot >= (r)->r_xtop) || ((r)->r_ybot >= (r)->r_ytop))

/* See if a rectangle has no area. */
#define GEO_RECTFNULL(r) \
    (((r)->rf_xbot >= (r)->rf_xtop) || ((r)->rf_ybot >= (r)->rf_ytop))

/* Expand a rectangular area by a given amount. */

#define GEO_EXPAND(src, amount, dst) \
{ \
    (dst)->r_xbot = (src)->r_xbot - (amount); \
    (dst)->r_ybot = (src)->r_ybot - (amount); \
    (dst)->r_xtop = (src)->r_xtop + (amount); \
    (dst)->r_ytop = (src)->r_ytop + (amount); \
}

#define GEO_EXPANDF(src, amount, dst) \
{ \
    (dst)->rf_xbot = (src)->rf_xbot - (amount); \
    (dst)->rf_ybot = (src)->rf_ybot - (amount); \
    (dst)->rf_xtop = (src)->rf_xtop + (amount); \
    (dst)->rf_ytop = (src)->rf_ytop + (amount); \
}

/* Sizes of rectangles. */
#define GEO_WIDTH(r)    ((r)->r_xtop - (r)->r_xbot)
#define GEO_HEIGHT(r)   ((r)->r_ytop - (r)->r_ybot)
#define GEO_WIDTHF(r)    ((r)->rf_xtop - (r)->rf_xbot)
#define GEO_HEIGHTF(r)   ((r)->rf_ytop - (r)->rf_ybot)
#define GEO_AREA(r) ( ((double) GEO_WIDTH(r)) * ((double) GEO_HEIGHT(r)) )

/* expand bbox to include r */
static __inline__ void GeoIncludeRectInBBox(Rect *r, Rect *bbox)
{
  bbox->r_xbot = MIN(bbox->r_xbot,r->r_xbot);
  bbox->r_ybot = MIN(bbox->r_ybot,r->r_ybot);
  bbox->r_xtop = MAX(bbox->r_xtop,r->r_xtop);
  bbox->r_ytop = MAX(bbox->r_ytop,r->r_ytop);
}


/* expand bbox to include r */
static __inline__ void GeoIncludeRectFInBBoxF(RectFloat *r, RectFloat *bbox)
{
  bbox->rf_xbot = MIN(bbox->rf_xbot,r->rf_xbot);
  bbox->rf_ybot = MIN(bbox->rf_ybot,r->rf_ybot);
  bbox->rf_xtop = MAX(bbox->rf_xtop,r->rf_xtop);
  bbox->rf_ytop = MAX(bbox->rf_ytop,r->rf_ytop);
}


/*-------------------------------------------------------------------
 *	GeoInclude --
 *	This routine includes one rectangle into another by expanding
 *	the second.
 *
 *	Results:
 *	TRUE is returned if the destination had to be enlarged.
 *
 *	Side Effects:
 *	The destination is enlarged (if necessary) so that it completely
 *	contains the area of both the original src and dst rectangles.
 *-------------------------------------------------------------------
 */

static __inline__ bool
GeoInclude(register Rect *src, register Rect *dst)
{
    int value;
    if (GEO_RECTNULL(src)) return FALSE;
    else if (GEO_RECTNULL(dst))
    {
	*dst = *src;
	return TRUE;
    }
    
    value = FALSE;
    if (dst->r_xbot > src->r_xbot)
    {
	dst->r_xbot = src->r_xbot;
	value = TRUE;
    }
    if (dst->r_ybot > src->r_ybot)
    {
	dst->r_ybot = src->r_ybot;
	value = TRUE;
    }
    if (dst->r_xtop < src->r_xtop)
    {
	dst->r_xtop = src->r_xtop;
	value = TRUE;
    }
    if (dst->r_ytop < src->r_ytop)
    {
	dst->r_ytop = src->r_ytop;
	value = TRUE;
    }
    return value;
}

/*-------------------------------------------------------------------
 *	GeoIncludeAll --
 *	This routine includes one rectangle into another by expanding
 *	the second.  This routine differs from GeoInclude in that zero-
 *	size source rectangles are processed.  The source or destination
 *	rectangle is considered to be NULL only if its lower-left corner
 *	is above or to the right of its upper right corner.  In this
 *	case, the other rectangle is the result.
 *
 *	Results:
 *	TRUE is returned if the destination is enlarged; otherwise FALSE.
 *
 *	Side Effects:
 *	The destination is enlarged (if necessary) so that it completely
 *	contains the area of both the original src and dst rectangles.
 *-------------------------------------------------------------------
 */

static __inline__ bool
GeoIncludeAll(register Rect *src, register Rect *dst)
{
    int value;

    if ((dst->r_xbot > dst->r_xtop) || (dst->r_ybot > dst->r_ytop))
    {
	*dst = *src;
	return TRUE;
    }

    if ((src->r_xbot > src->r_xtop) || (src->r_ybot > src->r_ytop))
	return FALSE;
    
    value = FALSE;
    if (dst->r_xbot > src->r_xbot)
    {
	dst->r_xbot = src->r_xbot;
	value = TRUE;
    }
    if (dst->r_ybot > src->r_ybot)
    {
	dst->r_ybot = src->r_ybot;
	value = TRUE;
    }
    if (dst->r_xtop < src->r_xtop)
    {
	dst->r_xtop = src->r_xtop;
	value = TRUE;
    }
    if (dst->r_ytop < src->r_ytop)
    {
	dst->r_ytop = src->r_ytop;
	value = TRUE;
    }
    return value;
}

/*
 * -------------------------------------------------------------------
 * Fast Clipping Macros
 *-------------------------------------------------------------------
 */

/*
 * GEOCLIP(r, area) Rect *r, area;
 * clips the rectangle 'r' against the area 'area'.
 */

#define	GEOCLIP(r, area) \
    if (1) { \
	if ((r)->r_xbot < (area)->r_xbot) (r)->r_xbot = (area)->r_xbot; \
	if ((r)->r_ybot < (area)->r_ybot) (r)->r_ybot = (area)->r_ybot; \
	if ((r)->r_xtop > (area)->r_xtop) (r)->r_xtop = (area)->r_xtop; \
	if ((r)->r_ytop > (area)->r_ytop) (r)->r_ytop = (area)->r_ytop; \
    } else

#define	GEOCLIPF(r, area) \
    if (1) { \
	if ((r)->rf_xbot < (area)->rf_xbot) (r)->rf_xbot = (area)->rf_xbot; \
	if ((r)->rf_ybot < (area)->rf_ybot) (r)->rf_ybot = (area)->rf_ybot; \
	if ((r)->rf_xtop > (area)->rf_xtop) (r)->rf_xtop = (area)->rf_xtop; \
	if ((r)->rf_ytop > (area)->rf_ytop) (r)->rf_ytop = (area)->rf_ytop; \
    } else


/*-------------------------------------------------------------------
 *	GeoClipLine --
 *	Clips a line segment against a rectangle
 *
 *      Uses the Cohen/Sutherland algorithm  
 *      (See "Computer Graphics" by Newman & Sproul)
 *
 *	Results:	Normally 1, 0 if no intersection. 
 *
 *      Side Effects:  Clips line.
 *
 *      WARNING: may not terminate due to rounding area if clip
 *               rect is not integral.
 *-------------------------------------------------------------------
 */

/* outcodes bit defs */
#define LAY_LEFT 1
#define LAY_RIGHT 2
#define LAY_TOP 4
#define LAY_BOTTOM 8

/* compute bit code for geoClipLine */
static __inline__ bool 
geoClipLineCode(double x, double y, RectFloat *clip)
{
  int c=0; 

  if(x<clip->rf_xbot)
  {
    c|=LAY_LEFT;
  } 
  else if(x > clip->rf_xtop)
  {
    c|=LAY_RIGHT;
  }

  if(y<clip->rf_ybot)
  {
    c|=LAY_BOTTOM;
  } 
  else if(y > clip->rf_ytop)
  {
    c|=LAY_TOP;
  }

  return c;
}

static __inline__ int
geoClipLine(double *x1, double *y1, double *x2, double *y2, RectFloat *clip )
{
  int c, c1, c2;  /* outcode bit maps */

  c1 = geoClipLineCode(*x1, *y1, clip);
  c2 = geoClipLineCode(*x2, *y2, clip);

  while( c1 || c2 )
  {
    double x,y;
    double dx, dy;

    if(c1&c2) return FALSE;
    c=c1?c1:c2; 
    
    dx = *x2 - *x1;
    dy = *y2 - *y1;

    if(ABS(dx) > ABS(dy))
    {
      /* horizontal like */
    
      if(c&LAY_LEFT)
      {
	x = clip->rf_xbot;
	y = *y1 + (x - *x1)*dy/dx;
      }
      else if(c&LAY_RIGHT)
      {
	x = clip->rf_xtop;
	y = *y1 + (x - *x1)*dy/dx;
      }
      else if(c&LAY_BOTTOM)  
      {
	y = clip->rf_ybot;
	x = *x1 + (y - *y1)*dx/dy;

      }
      else /* if(c&LAY_TOP)  */
      {
	y = clip->rf_ytop;
	x = *x1 + (y - *y1)*dx/dy;
      }
    }
    else
    {
      /* vertical like */

      if(c&LAY_BOTTOM)  
      {
	y = clip->rf_ybot;
	x = *x1 + (y - *y1)*dx/dy;
      }
      else if(c&LAY_TOP)  
      {
	y = clip->rf_ytop;
	x = *x1 + (y - *y1)*dx/dy;
      }
      else if(c&LAY_LEFT)
      {
	x = clip->rf_xbot;
	y = *y1 + (x - *x1)*dy/dx;
      }
      else /* if(c&LAY_RIGHT) */
      {
	x = clip->rf_xtop;
	y = *y1 + (x - *x1)*dy/dx;
      }
    }

    if (c==c1)  
    {
      *x1 = x; 
      *y1 = y;
      c1 = geoClipLineCode(x,y,clip);
    }
    else
    {
      *x2 = x; 
      *y2 = y;
      c2 = geoClipLineCode(x,y,clip);
    }
  }
  return TRUE;
}

/*
 * -------------------------------------------------------------------
 * Fast Transform Macros (no scaling)
 *-------------------------------------------------------------------
 */

/*
 * The GEOTRANSRECT(t, r1, r2) macro has the same effect as the
 * following code.  It assumes that t_a, t_b, t_d, t_e are all
 * chosen from -1, 0, 1, so it can't handle scaling.
 *
 *	int x1, y1, x2, y2;
 *	x1 = r1->r_xbot*t->t_a + r1->r_ybot*t->t_b + t->t_c;
 *	y1 = r1->r_xbot*t->t_d + r1->r_ybot*t->t_e + t->t_f;
 *	x2 = r1->r_xtop*t->t_a + r1->r_ytop*t->t_b + t->t_c;
 *	y2 = r1->r_xtop*t->t_d + r1->r_ytop*t->t_e + t->t_f;
 *
 *	if (x1 < x2) r2->r_xbot = x1, r2->r_xtop = x2;
 *	else r2->r_xbot = x2, r2->r_xtop = x1;
 *
 *	if (y1 < y2) r2->r_ybot = y1, r2->r_ytop = y2;
 *	else r2->r_ybot = y2, r2->r_ytop = y1;
 *
 * We make use of the fact that if t_a != 0 for one of our transforms,
 * then t_e != 0 also, and t_b = t_d = 0.
 */

#define	transRectX(r1, r2, RBOT, RTOP, ta, tc) \
	if (ta > 0) \
	    r2->r_xbot = r1->RBOT + tc, r2->r_xtop = r1->RTOP + tc; \
	else \
	    r2->r_xtop = tc - r1->RBOT, r2->r_xbot = tc - r1->RTOP;

#define	transRectY(r1, r2, RBOT, RTOP, ta, tc) \
	if (ta > 0) \
	    r2->r_ybot = r1->RBOT + tc, r2->r_ytop = r1->RTOP + tc; \
	else \
	    r2->r_ytop = tc - r1->RBOT, r2->r_ybot = tc - r1->RTOP;

#define	GEOTRANSRECT(at, ar1, ar2) \
    if (1) { \
	register Transform *xt = (at); \
	register Rect *xr1 = (ar1), *xr2 = (ar2); \
	if (xt->t_a) \
	{ \
	    transRectX(xr1, xr2, r_xbot, r_xtop, xt->t_a, xt->t_c); \
	    transRectY(xr1, xr2, r_ybot, r_ytop, xt->t_e, xt->t_f); \
	} \
	else \
	{ \
	    transRectX(xr1, xr2, r_ybot, r_ytop, xt->t_b, xt->t_c); \
	    transRectY(xr1, xr2, r_xbot, r_xtop, xt->t_d, xt->t_f); \
	} \
    } else


/* --------------------- Transforming transforms ---------------------- */

/*
 * The GEOTRANSTRANS(first, second, net) macro has the same effect
 * as the following code.  It assumes that the t_a, t_b, t_d, and t_f
 * fields of 'second' are chosen from -1, 0, 1, so it can't handle scaling.
 *
 * net->t_a = first->t_a*second->t_a + first->t_d*second->t_b;
 * net->t_b = first->t_b*second->t_a + first->t_e*second->t_b;
 * net->t_c = first->t_c*second->t_a + first->t_f*second->t_b + second->t_c;
 * net->t_d = first->t_a*second->t_d + first->t_d*second->t_e;
 * net->t_e = first->t_b*second->t_d + first->t_e*second->t_e;
 * net->t_f = first->t_c*second->t_d + first->t_f*second->t_e + second->t_f;
 */

#define	transTransAC(t1, net, ta, tc, da, db, dc) \
    ((ta > 0) \
	? (net->t_a = t1->da, net->t_b = t1->db, net->t_c = t1->dc + tc) \
	: (net->t_a = -t1->da, net->t_b = -t1->db, net->t_c = tc - t1->dc))

#define	transTransDF(t1, net, ta, tc, da, db, dc) \
    ((ta > 0) \
	? (net->t_d = t1->da, net->t_e = t1->db, net->t_f = t1->dc + tc) \
	: (net->t_d = -t1->da, net->t_e = -t1->db, net->t_f = tc - t1->dc))

#define	GEOTRANSTRANS(xt1, xt2, xnet) \
	if (1) { \
	    register Transform *_t1 = (xt1), *_t2 = (xt2), *_net = (xnet); \
	    if (_t2->t_a) \
		transTransAC(_t1, _net, _t2->t_a, _t2->t_c, t_a, t_b, t_c); \
	    else \
		transTransAC(_t1, _net, _t2->t_b, _t2->t_c, t_d, t_e, t_f); \
	    if (_t2->t_d) \
		transTransDF(_t1, _net, _t2->t_d, _t2->t_f, t_a, t_b, t_c); \
	    else \
		transTransDF(_t1, _net, _t2->t_e, _t2->t_f, t_d, t_e, t_f); \
	} else

/* ----------------------- Inverting transforms ----------------------- */

/*
 * The GEOINVERTTRANS(t, inv) macro has the same effect as the following
 * code.  The code assumes that t_a, t_b, t_c, and t_d are one of
 * -1, 1, or 0, so it can't invert scaled transforms (but neither can
 * the normal GeoInvertTrans, anyway).
 *
 *	Transform t3;
 *
 *	t3.t_a = t->t_a;
 *	t3.t_b = t->t_d;
 *	t3.t_d = t->t_b;
 *	t3.t_e = t->t_e;
 *	t3.t_c = t3.t_f = 0;
 *	GeoTransTranslate(-t->t_c, -t->t_f, &t3, inv);
 *
 * where GeoTranslateTrans(x, y, t, net) is
 *
 *	net->t_a = t->t_a;
 *	net->t_b = t->t_b;
 *	net->t_d = t->t_d;
 *	net->t_e = t->t_e;
 *	net->t_c = x*t->t_a + y*t->t_b + t->t_c;
 *	net->t_f = x*t->t_d + y*t->t_e + t->t_f;
 */

/*
 * GEOINVERTTRANS(t, tinv) inverts Transform t into tinv
 * without multiplication.
 *
 * tMul(c, a) implements (a*c) without multiplication,
 * assuming that each of a, c are chosen from 0, -1, 1.
 */
#define	tMul(c, a) \
	((a)	? ((a) > 0 ? (c) : -(c))	: 0)

#define	GEOINVERTTRANS(t, inv) \
    if (1) { \
	register Transform *xt = (t), *xinv = (inv); \
	xinv->t_a = xt->t_a; \
	xinv->t_b = xt->t_d; \
	xinv->t_d = xt->t_b; \
	xinv->t_e = xt->t_e; \
	xinv->t_c = - tMul(xt->t_c, xinv->t_a) - tMul(xt->t_f, xinv->t_b); \
	xinv->t_f = - tMul(xt->t_c, xinv->t_d) - tMul(xt->t_f, xinv->t_e); \
    } else

/*
 * GEOTRANSTRANSLATE(x, y, t, tresult) transforms an (x, y) translation
 * by the transform t, resulting in the transform tresult.
 */
#define	GEOTRANSTRANSLATE(x, y, t, tresult) \
    { \
	register Transform *xt = (t); \
	*(tresult) = (*xt); \
	(tresult)->t_c += tMul(x, xt->t_a) + tMul(y, xt->t_b); \
	(tresult)->t_f += tMul(x, xt->t_d) + tMul(y, xt->t_e); \
    }

/*
 * -------------------------------------------------------------------
 * Scaling Macros
 *-------------------------------------------------------------------
 */

static __inline__ void GeoScaleInt(int *ip, double f, double *maxError)
{
  double tmp = *ip * f;
  double err;
  *ip = ROUND(tmp);
  err = ABS(*ip - tmp);
  if(maxError && err>*maxError) *maxError = err;
}

static __inline__ void GeoScaleIntGrid(int *ip, 
				       double f, 
				       double *maxError, 
				       int grid) /* scale to this grid */
{
  double tmp1 = *ip * f;
  double tmp2 = tmp1 / grid;
  double err;
  *ip = ROUND(tmp2)*grid;
  err = ABS(*ip - tmp1);
  if(maxError && err>*maxError) *maxError = err;
}

static __inline__ void GeoScaleDouble(double *dp, double f, double *maxError)
{
  double tmp = *dp * f;
  double err;
  *dp = ROUND(tmp);
  err = ABS(*dp - tmp);
  if(maxError && err>*maxError) *maxError = err;
}

static __inline__ void GeoScalePoint(Point *p, double f, double *maxError)
{
  GeoScaleInt(&p->p_x, f, maxError);
  GeoScaleInt(&p->p_y, f, maxError);
}

static __inline__ void GeoScalePointGrid(Point *p, 
					 double f, 
					 double *maxError,
					 int grid)
{
  GeoScaleIntGrid(&p->p_x, f, maxError, grid);
  GeoScaleIntGrid(&p->p_y, f, maxError, grid);
}

static __inline__ void GeoScalePointF(PointFloat *p, double f, double *maxError)
{
  GeoScaleDouble(&p->pf_x, f, maxError);
  GeoScaleDouble(&p->pf_y, f, maxError);
}

static __inline__ void GeoScaleRect(Rect *r, double f, double *maxError)
{
  GeoScalePoint(&r->r_ll, f, maxError);
  GeoScalePoint(&r->r_ur, f, maxError);
}

static __inline__ void GeoScaleRectF(RectFloat *r, double f, double *maxError)
{
  GeoScalePointF(&r->rf_ll, f, maxError);
  GeoScalePointF(&r->rf_ur, f, maxError);
}

/*
 *-------------------------------------------------------------------
 *	Declarations of exported transforms and rectangles:
 *-------------------------------------------------------------------
 */

extern Transform GeoIdentityTransform;
extern Transform GeoUpsideDownTransform;
extern Transform GeoSidewaysTransform;
extern Transform Geo90Transform;
extern Transform Geo180Transform;
extern Transform Geo270Transform;
extern Transform GeoRef45Transform;
extern Transform GeoRef135Transform;

extern Rect GeoNullRect;
extern Rect GeoInvertedRect;

extern int GeoOppositePos[];

/*-------------------------------------------------------------------
 *	Declarations for exported procedures:
 *-------------------------------------------------------------------
 */
extern int GeoNameToPos(char *name, int manhattan, int verbose);
extern char * GeoPosToName(int pos);

extern Transform *GeoNameToTrans(char *name, int noisy);
extern char *GeoTransToName(Transform *t);

extern void GeoTransRect(register Transform *t, register Rect *r1, register Rect *r2);

extern void GeoTransPoint(register Transform *t, 
			  register Point *p1, 
			  register Point *p2);

extern void GeoTransPointFOut(register Transform *t, 
			   register Point *p1, 
			   register PointFloat *p2);

extern void GeoTransPointF(register Transform *t, 
			   register PointFloat *p1, 
			   register PointFloat *p2);

extern void GeoTransTrans(register Transform *first, 
			  register Transform *second, 
			  register Transform *net);

extern void GeoInvertTrans(register Transform *t, Transform *inverse);
extern void GeoTranslateTrans(register Transform *trans1, int x, int y, register Transform *trans2);
extern void GeoTransTranslate(int x, int y, register Transform *trans1, register Transform *trans2);
extern int GeoTransPos(Transform *t, int pos);
extern void GeoClip(register Rect *r, register Rect *area);
extern void GeoClipPoint(register Point *p, register Rect *area);
extern int GeoRectPointSide(register Rect *r, register Point *p);
extern int GeoRectRectSide(register Rect *r0, register Rect *r1);
extern void GeoIncludePoint(register Point *src, register Rect *dst);
extern void GeoDecomposeTransform(Transform *t, int *upsidedown, int *angle);
extern void GeoCanonicalRect(Rect *r, Rect *rnew);
extern void GeoCanonicalRectF(RectFloat *r, RectFloat *rnew);


/*-------------------------------------------------------------------
 *	GeoIsCanonicalRect --
 *
 *      Check if rectangle is in canonical from:
 *	lower left is really below and to the left of the upper right.
 *
 *	Results:	TRUE if canonical, else FALSE.
 *
 *-------------------------------------------------------------------
 */
static bool
GeoIsCanonicalRect(Rect *r)
{
  return (r->r_xbot <= r->r_xtop) && (r->r_ybot <= r->r_ytop);
}

#endif _GEOMETRY




