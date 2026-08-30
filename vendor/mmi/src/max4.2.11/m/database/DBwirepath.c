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
 * DBwirepath.c --
 *
 * all-angle geometries defined by centerline and width, equivalent
 * to gds path elements and cif wires.
 *
 * generates associated off-grid ("dependent") polygons in Max, 
 * but these polygons are not saved to disk.
 *
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include <math.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "layout.h"

/* if set, wirepaths are rendered as single polygon,
 * instead of one polygon per edge.
 * (tcl linked)
 */ 
bool dbWPathSinglePolygon = FALSE;

/* helper func, handles round flashes *
 * TODO replace with polygon approximation */
static __inline__ int dbWPathFlash(WirePath *wp,
				   PointFloat center,
				   float radius,
				   int (*func)(int size, 
					       PointFloat *points))
{
  PointFloat points[4];

  /* create points */
  points[0].pf_x = center.pf_x - radius;
  points[0].pf_y = center.pf_y - radius;
  points[1].pf_x = center.pf_x + radius;
  points[1].pf_y = center.pf_y + radius;

  /* call func */
  return (*func)(2, points);
}

/* absolute value */
static __inline__ double l_abs(double x)
{
  return (x<0) ? -x : x; 
}

/* segment length */
static __inline__ double l_length(PointFloat p0,
				  PointFloat p1)
{
  double dx = p1.pf_x - p0.pf_x;
  double dy = p1.pf_y - p0.pf_y;
  return sqrt(dx*dx + dy*dy);
}

/* extend segment (and adjust length) */
static __inline__ void l_extend(PointFloat *p0,
				PointFloat *p1, 
				double *length,
				double extend0, /* from p0 */
				double extend1) /* from p1 */
{ 
  double x0 = p0->pf_x;
  double y0 = p0->pf_y;
  double x1 = p1->pf_x;
  double y1 = p1->pf_y;
  double dx = x1-x0; 
  double dy = y1-y0;
  double r0,r1;

  /* extension of zero length segment not defined */
  if(length == 0) return;

  r0 = extend0/(*length);
  r1 = extend1/(*length);

  p0->pf_x = x0 - r0*dx;
  p0->pf_y = y0 - r0*dy;
  p1->pf_x = x1 + r1*dx;
  p1->pf_y = y1 + r1*dy;

  *length += extend0+extend1;
}

/* compute perpendicular segment */
/* (with p0 as midpoint and length 2*radius) */
static __inline__ void l_perpendicular(PointFloat p0,
				       PointFloat p1,		 
				       double d01,
				       double radius,
				       PointFloat *left,
				       PointFloat *right)
{
  double xTrans = (radius/d01) * (p0.pf_y - p1.pf_y);
  double yTrans = (radius/d01) * (p1.pf_x - p0.pf_x);

  left->pf_x = p0.pf_x + xTrans; 
  left->pf_y = p0.pf_y + yTrans; 

  right->pf_x = p0.pf_x - xTrans; 
  right->pf_y = p0.pf_y - yTrans; 
}

/* compute miter points for p1 */

/*

Mitering algorithm:

Given points P,Q,R in path, of radius 'radius', find 'LEFT' point where
first segment and second segment 'LEFT' boundary edges meet, and similarly
find 'RIGHT' point.

1.  translate so Q is at origin (will translate back when all done)

2.  normalize so that edges are unit length (does not change result).
    (so now have A corresponding to original P and B corresponding
     to original 'R')

3.  we find intersection for unit radius, the resulting coordinates
    must be scaled by radius (before applying translation in 1 above).

4.  to translate perpendicularly to left of vector (x,y), translate
    by vector (-y,x).  (call this op lp(V) for left perp.)
		
5.  to translate perpendicularly to right of vector (x,y), translate
    by vector (y,-x) (call this op rp(V) for right perp. )

6.  a parameterized representation (in t) of left edges is:

	rp(A) - At and lp(B) - Bt

    by symmetry, t must be same for both equations where edges meet:

	rp(A) - At0 = lp(B) - Bt0

    writing out equations for first and second coords and solving
    each for t yields:	

	t0 = (Ay + By) / (Ax - Bx)

	t0 = (Ax + Bx) / (By - Ay)

    these equations are equivalent, use one with greatest denominator
    to avoid divide by 0 problem.  If both are very small it means 
    path did a near 180, in which case the miter points ARE way out there.
    CONSIDER CLIPPING t0 to some reasonably small finite number.

    Plug t0 into one of the parametic equations (doesn't matter which
    one) to obtain the LEFT point.  If t0, clipped use both to obtain
    two LEFT points!	
	
7.  RIGHT point can be obtained from LEFT by inverting coordinates.
*/
static __inline__ void l_miter(PointFloat p0,  /* aka P */
			       PointFloat p1,  /* aka Q */		 
			       PointFloat p2,  /* aka R */ 		 
			       double d01,
			       double d12,
			       double radius,
			       PointFloat *left,
			       PointFloat *right)
{
  double t0, x, y; 

  /* translate p1 to origin, and normalize p1p0 to unit vector */
  double ax = (p0.pf_x - p1.pf_x)/d01;
  double ay = (p0.pf_y - p1.pf_y)/d01;

  /* normalize p1p2 to unit vector */
  double bx = (p2.pf_x - p1.pf_x)/d12;
  double by = (p2.pf_y - p1.pf_y)/d12;

  /* compute distance edges need to be extended to interesect */
  /* (being careful to avoid divide by zero) */
  if(l_abs(ax-bx) > l_abs(by-ay))
  {
    t0 = (ay+by)/(ax-bx);
  }
  else
  {
    t0 = (ax+bx)/(by-ay);
  }

  /* compute intersection coords from t0 */
  x = (ay - ax*t0)*radius;
  y = (-ax - ay*t0)*radius;

  /* translate result back to p1 */
  left->pf_x = p1.pf_x + x; 
  left->pf_y = p1.pf_y + y; 
  right->pf_x = p1.pf_x - x; 
  right->pf_y = p1.pf_y - y; 
}

/*
 *-----------------------------------------------------------------------------
 *
 * dbWPathEnumSinglePolygon --
 *
 * called by DBWPathEnumPolygons() for special cases where quadralateral
 * decomposition is problematic.
 *
 * converts tail of path to single polygon.
 *
 *-----------------------------------------------------------------------------
 */
PointFloat *dbWPSinglePointsBuf;
int dbWPSingleBufSize = 0;
int dbWPathEnumSinglePolygon(WirePath *wp,
			     int (*func)(int size, PointFloat *points),
			     int start, /* index of point to start with */
			     PointFloat first, 
			     PointFloat last) 
{
  int i;
  int size = wp->wp_size;             
  double radius = wp->wp_width/2.0;
  int style = wp->wp_style;          /* end style */
  PointFloat p0,p1,p2;
  double d01,d12;
  int pointsSize;
  PointFloat *points;
  int nextLeft, nextRight;

  /* allocate point array (2x to allow for extra points due to truncation) */
  pointsSize = 4*(size-start);
  if(pointsSize>dbWPSingleBufSize)
  {
    if(dbWPSingleBufSize>0) DBPointsFFree(dbWPSinglePointsBuf);
    dbWPSinglePointsBuf = DBPointsFAlloc(pointsSize, NULL, NULL);
  }
  points = dbWPSinglePointsBuf;
  nextLeft = 0;
  nextRight = pointsSize-1; 

  /* add initial and final points */
  points[nextLeft++] = first;
  points[nextRight--] = last;

  /* initialize per-path point processing */
  {
    /* points in first segment */
    p0.pf_x = wp->wp_points[start].p_x;
    p0.pf_y = wp->wp_points[start].p_y;
    p1.pf_x = wp->wp_points[start+1].p_x;
    p1.pf_y = wp->wp_points[start+1].p_y;

    /* get length of first segment */
    d01 = l_length(p0,p1);
  }

  /* process interior path points */ 
  for(i=start+2; i<size; i++)
  {
    p2.pf_x = wp->wp_points[i].p_x;
    p2.pf_y = wp->wp_points[i].p_y;

    /* get length of next segment */    
    d12 = l_length(p1,p2);
    if(i==size-1)
    {
      /* last point, adjust for extension (if any) */
      if(style == WP_STYLE_HALFWIDTH)
      {
	l_extend(&p1,&p2,&d12,0,radius);
      }
    }

    /* add miter points for this (p1) interior path point */
    l_miter(p0,p1,p2,d01,d12,radius,
	    &points[nextLeft++],  /* left miter point */
	    &points[nextRight--]);  /* right miter point */

    /* advance to next point */
    p0 = p1;
    p1 = p2;

    d01 = d12;
  }

  /* do final segment */
  {
    /* final polygon points */
    l_perpendicular(p1, p0, d01, radius, 
		    &points[nextRight--], /* left */
		    &points[nextLeft++]); /* right */
  }

  /* move right points up to get rid of gap in points, and call func */
  {
    int num = nextLeft + pointsSize-1-nextRight;

    while(++nextRight<pointsSize)
    {
      points[nextLeft++] = points[nextRight];
    }
    
    if ((*func)(num,points) != 0) return 1;
  }

  /* add final rounded end caps - if needed */
  if (style == WP_STYLE_ROUNDED)
  {
    /* round flash */
    if( dbWPathFlash(wp, 
		     p1, 
		     radius, 
		     func) != 0) return 1;
  }

  return 0;
}
    

/*
 *-----------------------------------------------------------------------------
 *
 * DBWPathEnumPolygons --
 * 
 * calls func for each (implicit) polygon in wirepath.
 *
 * func should returns 0 to continue search, 1 to abort search.
 *
 * Results:
 *	0 is returned if the search finished normally.  1 is returned
 *	if the search was aborted.
 *
 * NOTE: (re)creates polygon points, does not search for them!
 *
 *-----------------------------------------------------------------------------
 */


int DBWPathEnumPolygons(WirePath *wp,
			int (*func)(int size, PointFloat *points))
{
  int i;
  int size = wp->wp_size;             
  double radius = wp->wp_width/2.0;
  int style = wp->wp_style;          /* end style */
  PointFloat points[4];
  PointFloat p0,p1,p2;
  double d01, d12;

  /* initialize for per-segment processing */
  {
    /* points in first segment */
    p0.pf_x = wp->wp_points[0].p_x;
    p0.pf_y = wp->wp_points[0].p_y;
    p1.pf_x = wp->wp_points[1].p_x;
    p1.pf_y = wp->wp_points[1].p_y;

    /* get length of first segment */
    d01 = l_length(p0,p1);
    /* adjust for extension (if any) */
    if(style == WP_STYLE_HALFWIDTH)
    {
      l_extend(&p0,&p1,&d01,radius,0);
    }
    else if (style == WP_STYLE_ROUNDED)
    {
      /* round flash */
      if( dbWPathFlash(wp, 
		       p0, 
		       radius, 
		       func) != 0) return 1;
    }

    /* initial polygon points */
    l_perpendicular(p0, p1, d01, radius, &points[1], &points[0]);

    /* small segments problematic for quadraleteral decomposition,
     * render as single polygon.
     */
    if(dbWPathSinglePolygon || d01<radius)
    {
      return dbWPathEnumSinglePolygon(wp, func, 0, points[1], points[0]);
    }
  }

  /* process all segments but last */
  /* i = index of next point in path following current segment = p2 */
  for(i=2; i<size; i++)
  {
    p2.pf_x = wp->wp_points[i].p_x;
    p2.pf_y = wp->wp_points[i].p_y;

    /* get length of next segment */    
    d12 = l_length(p1,p2);
    if(i==size-1)
    {
      /* last point, adjust for extension (if any) */
      if(style == WP_STYLE_HALFWIDTH)
      {
	l_extend(&p1,&p2,&d12,0,radius);
      }
    }

    /* small segments problematic for quadraleteral decomposition,
     * render rest of path as single polygon.
     */
    if(d12<radius) 
    {
      return dbWPathEnumSinglePolygon(wp, func, i-1, points[1], points[0]);
    }

    l_miter(p0,p1,p2,d01,d12,radius,
	    &points[2],  /* left miter point */
	    &points[3]);  /* right miter point */
    
    /* call func on quadraleteral for this segment */
    if( (*func)(4,points) != 0) return 1;

    /* advance to next segment */
    p0 = p1;
    p1 = p2;

    d01 = d12;
    points[0] = points[3];
    points[1] = points[2];
  }

  /* do final segment */
  {

    /* final polygon points */
    l_perpendicular(p1, p0, d01, radius, 
		    &points[3], /* left */
		    &points[2]); /* right */

    /* call func on final segment */
    if( (*func)(4,points) != 0) return 1;
  }

  /* add final rounded end caps - if needed */
  if (style == WP_STYLE_ROUNDED)
  {
    /* round flash */
    if( dbWPathFlash(wp, 
		     p1, 
		     radius, 
		     func) != 0) return 1;
  }

  return 0;
}


/*
 *-----------------------------------------------------------------------------
 *
 * dbWPGenPolys --
 * 
 * generates dependent polygons for wirepath, and computes bounding box.
 *
 *-----------------------------------------------------------------------------
 */

/* vars for passing info to helper func */
static CellDef *gpDef;
static WirePath *gpWP;
static void (*gpFunc)(CellDef *def, WirePath *wp, Polygon *poly);
 

/* helper func, called for each polygon in wirepath */
static __inline__ int dbWPGenPolysFunc(int size,
				       PointFloat *points)
{
  Polygon *poly;

  poly = DBPolyNew(gpDef, 
		   gpWP->wp_type, 
		   size, 
		   DBPointsFAlloc(size, points, NULL), 
		   gpWP, 
		   FALSE);

  GeoIncludeRectInBBox(&poly->poly_bbox,&gpWP->wp_bbox);
  
  /* if callback, call it */
  if(gpFunc) (*gpFunc)(gpDef, gpWP, poly);

  /* continue enumeration */
  return 0;
}

static void dbWPGenPolys(CellDef *def,
			 WirePath *wp,
			 void (*func)(CellDef *def, 
				      WirePath *wp, 
				      Polygon *poly))  
                          /* func called on every new dependent polygon */ 
{

  gpDef = def;
  gpWP  = wp;
  gpFunc = func;

  /* intialize bbox */
  wp->wp_bbox.r_ll = wp->wp_points[0];
  wp->wp_bbox.r_ur = wp->wp_points[0];

  /* build the polygons */ 
  DBWPathEnumPolygons(wp, dbWPGenPolysFunc);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBWPathNew --
 *
 * Create new WirePath
 * If def is not null, links polygon into def.
 * if def non-null, notify undo
 *
 * Returns:
 *      pointer to new wirepath
 *
 * Side effects:
 *	Calls the undo package.
 *
 * NOTE: points array will be FREEd when polygon is deleted!
 *
 * ----------------------------------------------------------------------------
 */
WirePath *DBWPathNew(CellDef *def, 
		     TileType type, 
		     int style,
		     int width,
		     int size,  
		     Point *points,
		     bool notify,
                          /* if set change notification is done */
		     void (*func)(CellDef *def, WirePath *wp, Polygon *poly))  
                          /* func called on every new dependent polygon */ 
{
  WirePath *wp;

  MALLOC_TAG(WirePath *, wp, sizeof(WirePath),"WirePath");

  wp->wp_client = (ClientData) -1;
  wp->wp_type = type;
  wp->wp_group = NULL;
  wp->wp_style = style;
  wp->wp_width = width;
  wp->wp_size = size;
  wp->wp_points = points;
  wp->wp_next =  NULL;

  ASSERT(def,"DBWPathNew");

  /* set to active group */
  wp->wp_group = def->cd_activeGroup;

  /* link into def */
  wp->wp_next =  def->cd_wirePaths;
  def->cd_wirePaths = wp;

  /* Generate dependent polygons (and compute bbox) */
  dbWPGenPolys(def, wp, func);

  /* notify undo */
  DBUndoAddWP(def,wp);

  /* change notification  */
  if(notify)
  {
    TileTypeBitMask mask;

    TTMaskZero(&mask);
    TTMaskSetType(&mask, wp->wp_type);
    DBChangedArea(def, &wp->wp_bbox, &mask, DBCF_WIREPATH);
  }

  return wp;
}

/* delete wirepath */

/*
 * ----------------------------------------------------------------------------
 *
 * DBWPathDelete --
 *
 * Delete wirepath.  
 * If def is not null, unlinks wp from def.
 * if def non null undo is notified.
 *
 * NOTE: frees wirepaths point array. 
 *
 * ----------------------------------------------------------------------------
 */
void DBWPathDelete(CellDef *def, 
		   WirePath *wp, 
		   bool notify)
                        /* if set notify redisplay etc. */
{
  Polygon *poly, *nextPoly;
  WirePath *cur, *next;
  WirePath **prevPointer;

  /* handle unlinked wirepaths separately */
  if(!def)
  {
    ASSERT(wp->wp_next == NULL, "DBWPathDelete");
    ASSERT(!notify, "DBWPathDelete");

    DBPointsFree(wp->wp_points);
    FREE_TAG((char *) wp,"WirePath");
    return;
  }

  /* notify undo */
  DBUndoDeleteWP(def, wp);

  /* delete dependent polygons */
  for(poly=def->cd_polygons; poly; poly=nextPoly)
  {
    nextPoly = poly->poly_next;
    if(poly->poly_wirePath == wp) DBPolyDelete(def, poly, notify);
  }

  /* delete the wire path itself */
  cur= def->cd_wirePaths;
  prevPointer = &def->cd_wirePaths;
  while(cur && cur!= wp)
  {
    prevPointer = &cur->wp_next;
    cur = cur->wp_next;
  }

  if(cur) 
  {
    *prevPointer = wp->wp_next;
    DBPointsFree(wp->wp_points);
    FREE_TAG((char *) wp, "WirePath");
  }
}

/* delete all wirepaths in celldef */
void DBWPathsClear(CellDef *def)
{
  while(def->cd_wirePaths)
  {
    DBWPathDelete(def, def->cd_wirePaths, FALSE);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbWPathWrite --
 *
 * write wirepaths to .max file
 *
 * Results:
 *	Normally returns TRUE; returns FALSE on I/O error.
 *
 * Side effects:
 *	Writes to the disk file.
 *
 * ----------------------------------------------------------------------------
 */

#define OUTS(s)\
{\
     if (fputs(s,f) == EOF) goto ioerror;\
     DBFileOffset += strlen(s);\
}

bool
dbWPathWrite(CellDef *def, FILE *f)
{
    char buf[1000];
    register WirePath *wp;
    
    for (wp = def->cd_wirePaths; wp; wp = wp->wp_next)
    {
      int i;
      int size = wp->wp_size;

      sprintf(buf, "wpath %s %d %d %d {\n",
	      DBTypeLongName(wp->wp_type),
	      wp->wp_style,
	      wp->wp_width,
	      size);
      OUTS(buf);

      for(i=0; i<size; i++)
      {
        sprintf(buf, "\t%d %d\n",
	      wp->wp_points[i].p_x,
	      wp->wp_points[i].p_y);
	OUTS(buf);
      }

      OUTS("\t}\n");
    }
    return TRUE;

ioerror:
    return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbWPathRead --
 *
 * Starting with the line "SECTION WIREPATHS {", read the WIREPATHS section.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func - reads one polygon */
static __inline__ bool
dbWPathRead1(CellDef *def, 
                     	/* Cell being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    char layerName[50];
    TileType type;
    int size, style, width, i;
    Point *points;

    /* read "wpath" line */
    if (sscanf(lineBuf, "wpath %49s %d %d %d {", 
	       &layerName,
	       &style,
	       &width,
	       &size) != 4)
    {
	MsgErrorF("Bad wpath line: '%s'\n", lineBuf);
	return FALSE;
    }

    /* lookup type */
    type = DBTechNameType(layerName);
    if (type < 0)
    {
      MsgErrorF("Unknown type %s\n",layerName);
      return FALSE;
    }

    if (size < 2)
    {
      MsgErrorF("Bad wpath size:  %d\n",size);
      return FALSE;
    }

    /* read points (path) */
    points = DBPointsAlloc(size, NULL, NULL);
    for(i=0; i<size; i++)
    {
      if (!dbReadNextLine(lineBuf, bufSize, f)) 
      {
	DBPointsFree(points);
	return FALSE;
      }
      
      if(sscanf(lineBuf, "%d %d", &points[i].p_x, &points[i].p_y) != 2)
      {
	MsgErrorF("Bad wpath point: '%s'\n", lineBuf);
	return FALSE;
      }
      GeoScalePoint(&points[i], dbRdScaleFile2DB, &dbRdScaleFile2DBErr);
    }

    /* read closing brace line */
    if (!dbReadNextLine(lineBuf, bufSize, f)) 
    {
      DBPointsFree(points);
      return FALSE;
    }

    /* create new wirepath */
    DBWPathNew(def, type, style, width, size, points, FALSE, NULL);
    return TRUE;
}

bool
dbWPathRead(CellDef *cellDef, 
                     	/* Cell being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    while (dbReadNextLine(lineBuf, bufSize, f))
    {

        if (lineBuf[0]== '}' && 
	    strcmp(lineBuf,"} SECTION WIREPATHS\n") == 0) return TRUE;
        if(!dbWPathRead1(cellDef, lineBuf, bufSize, f)) return FALSE;
    }
    return (FALSE);
}

/* copy wire path into def */
WirePath *DBWPathCopy(WirePath *wp, 
		      CellDef *destDef, 
		      Transform *trans,
		      void (*func)(CellDef *def, WirePath *wp, Polygon *poly))
                           /* func called for each dependent polygon in new
			    * wirepath
			    */
{
  Point *points;
  int i;
  int size = wp->wp_size;

  /* copy points (path) */
  points = DBPointsAlloc(size, wp->wp_points, trans);
  
  /* create (and return) dest wire path */
  return DBWPathNew(destDef, 
		    wp->wp_type, 
		    wp->wp_style, 
		    wp->wp_width, 
		    size,  
		    points,
		    FALSE,
		    func);  /* don't do notification */
}

/* copy wire paths in srcDef to destDef (with transform) */
void DBWPathsCopy(CellDef *srcDef, 
		  CellDef *destDef, 
		  Transform *trans) 
{
  WirePath *wp;

  for (wp = srcDef->cd_wirePaths; wp; wp=wp->wp_next)
  {
    DBWPathCopy(wp, destDef, trans, NULL);
  }
} 

/*
 *-----------------------------------------------------------------------------
 *
 * DBWPathFind --
 *
 * Find wirepath in def matching the given specification
 *	
 * Returns pointer to matching wirepath (NULL if none found).
 *
 *-----------------------------------------------------------------------------
 */ 
WirePath *DBWPathFind(CellDef *def,   /* def to search */
		      TileType type, 
		      Group *group,
		      int style,
		      int width,
		      int size,  
		      Point *points,
		      Transform *trans)
{
  WirePath *wp;

  if(trans)
  {
    for (wp=def->cd_wirePaths; wp; wp=wp->wp_next)
    {
      int i;

      if(wp->wp_width != width) continue;
      if(wp->wp_type != type) continue;
      if(wp->wp_group != group) continue;

      if(wp->wp_size != size) continue;
      for(i=0;i<size; i++)
      {
	Point p;

	GeoTransPoint(trans,&points[i],&p);
	if(!GEO_SAMEPOINT(p,wp->wp_points[i])) break;
      }

      if(i==size) return wp;
    }
  }
  else
  {
    for (wp=def->cd_wirePaths; wp; wp=wp->wp_next)
    {
      int i;

      if(wp->wp_width != width) continue;
      if(wp->wp_type != type) continue;
      if(wp->wp_group != group) continue;
      if(wp->wp_size != size) continue;

      for(i=0;i<size; i++)
      {
	if(!GEO_SAMEPOINT(wp->wp_points[i],points[i])) break;
      }
      if(i==size) return wp;
    }
  }

  return NULL;
}

	  
/*
 *-----------------------------------------------------------------------------
 *
 * DBWirePathIntersectRectQ1 --
 *
 * Does real work for inline func DBWirePathIntersectQ()
 *	
 * Check for intersection between wirepath and rect.
 *
 * Returns TRUE if "wp" intersected with the closed rectangle
 * "rect" is non-empty and FALSE otherwise.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 * NOTE: assumes caller has already checked that following special cases
 *       do not hold:
 *       1. wp bbox contained in rect.
 *       2. wp bbox and rect disjoint.
 *
 *-----------------------------------------------------------------------------
 */
bool DBWirePathIntersectRectQ1(CellDef *def, WirePath *wp, Rect *rect)     
{
  Polygon *poly;

  /* wirepath intersects iff one of its polygons does */
  for(poly=def->cd_polygons; poly; poly=poly->poly_next)
  {
    if(poly->poly_wirePath != wp) continue;
    if(DBPolygonIntersectRectQ(poly,rect)) return TRUE;
  }

  return FALSE;
}
	  
/*
 *-----------------------------------------------------------------------------
 *
 * DBWirePathIntesectPolygonQ --
 *
 * Does real work for inline DBWirePathIntersectPolygonQ()
 *	
 * Returns TRUE if "wp" intersects the polygon
 *
 * NOTE: assumes caller handles following special case:
 *       wp bbox and poly bbox disjoint.
 *
 *-----------------------------------------------------------------------------
 */

/* vars for communicating with callback procedure */
static Polygon *dbwpipPoly;
static Transform *dbwpipTrans;

static int dbWirePathIntersectPolygonQ1Func(int size, 
					    PointFloat *points)
{
  Polygon *temp;
  int result;

  /* wirepath intersects poly iff one of its polygons does */

  /* create temporary polygon from points  TODO uses points directly! */
  temp = DBPolyNew(NULL,  /* don't link into def */
		   dbwpipPoly->poly_type, 
		   size,
		   DBPointsFAlloc(size,points,NULL),
		   NULL,
		   FALSE);

  result = DBPolygonIntersectPolygonQ(dbwpipPoly, temp, dbwpipTrans);
  
  DBPolyDelete(NULL, temp, FALSE);

  return result;
}

bool DBWirePathIntersectPolygonQ1(WirePath *wp, 
				  Polygon *poly,
				  Transform *trans)
{
  /* set up vars for callback */
  dbwpipTrans = trans;
  dbwpipPoly = poly;
 
  /* wirepath intersects polygon iff one of its polygons does */
  return DBWPathEnumPolygons(wp, 
			     dbWirePathIntersectPolygonQ1Func);
}










