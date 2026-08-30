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
 * DBpoints.c --
 *
 * routines for manipulating Point and PointFloat arrays 
 *
 * Polygons use PointFloat arrays 
 * WirePaths use Point arrays
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "mm.h"

/*
 * ----------------------------------------------------------------------------
 * DBPointsAlloc --
 *
 * Malloc a new point array, and copy in to it
 *
 * if in is NULL, no initialization.
 *
 * ----------------------------------------------------------------------------
 */
Point *
DBPointsAlloc(int num, Point *in, Transform *trans)
{
  int i;
  Point *out;

  MALLOC_TAG(Point *, 
	     out,
	     num*sizeof(*out), 
	     "Point Array");

  if(!in) return out; 

  /* copy points */
  if(trans)
  {
    for(i=0; i<num; i++) GeoTransPoint(trans, &in[i], &out[i]);
  }
  else
  {
    for(i=0; i<num; i++) out[i] = in[i];    
  }

  return out;
}

PointFloat *
DBPointsFAlloc(int num, PointFloat *in, Transform *trans)
{
  int i;
  PointFloat *out;

 MALLOC_TAG(PointFloat *, 
	     out,
	     num*sizeof(*out), 
	     "PointFloat Array");

  if(!in) return out;

  /* copy points */
  if(trans)
  {
    for(i=0; i<num; i++) GeoTransPointF(trans, &in[i], &out[i]);
  }
  else
  {
    for(i=0; i<num; i++) out[i] = in[i];    
  }

  return out;
}

/*
 * ----------------------------------------------------------------------------
 * DBPointsFree --
 *
 * Free point array.
 *
 * if in is NULL, no copy is done.
 *
 * ----------------------------------------------------------------------------
 */
void
DBPointsFree(Point *p)
{
  FREE_TAG(p,"Point Array");
}

void
DBPointsFFree(PointFloat *p)
{
  FREE_TAG(p,"PointFloat Array");
}

/*
 * ----------------------------------------------------------------------------
 * DBPointsBBox --
 *
 * compute bbox of point array.
 *
 * NOTE: result is overwritten on next call.
 *
 * ----------------------------------------------------------------------------
 */
Rect *DBPointsBBox(int size, Point *points)
{
  static Rect bbox;
  int i;

  bbox.r_xbot = MIN(points[0].p_x,points[1].p_x);
  bbox.r_xtop = MAX(points[0].p_x,points[1].p_x);
  bbox.r_ybot = MIN(points[0].p_y,points[1].p_y);
  bbox.r_ytop = MAX(points[0].p_y,points[1].p_y);

  for(i=2; i<size; i++)
  {
    bbox.r_xbot = MIN(bbox.r_xbot,points[i].p_x);
    bbox.r_xtop = MAX(bbox.r_xtop,points[i].p_x);
    bbox.r_ybot = MIN(bbox.r_ybot,points[i].p_y);
    bbox.r_ytop = MAX(bbox.r_ytop,points[i].p_y);
  }

  return &bbox;
}

Rect *DBPointsFBBox(int size, PointFloat *points)
{
  static Rect bbox;
  int i;

  bbox.r_xbot = MINF2I(points[0].pf_x,points[1].pf_x);
  bbox.r_xtop = MAXF2I(points[0].pf_x,points[1].pf_x);
  bbox.r_ybot = MINF2I(points[0].pf_y,points[1].pf_y);
  bbox.r_ytop = MAXF2I(points[0].pf_y,points[1].pf_y);

  for(i=2; i<size; i++)
  {
    bbox.r_xbot = MINF2I(bbox.r_xbot,points[i].pf_x);
    bbox.r_xtop = MAXF2I(bbox.r_xtop,points[i].pf_x);
    bbox.r_ybot = MINF2I(bbox.r_ybot,points[i].pf_y);
    bbox.r_ytop = MAXF2I(bbox.r_ytop,points[i].pf_y);
  }

  return &bbox;
}

/*
 * ----------------------------------------------------------------------------
 * DBPointsDump --
 *
 * print points for debugging.
 *
 * ----------------------------------------------------------------------------
 */
void DBPointsDump(char *msg, int size, Point *points)
{
  int i;

  fprintf(stderr,"%s - %d Points:\n", msg, size);
  for(i=0; i< size; i++) fprintf(stderr,"\t%d %d\n", 
				 points[i].p_x, 
				 points[i].p_y);
}

void DBPointsFDump(char *msg, int size, PointFloat *points)
{
  int i;

  fprintf(stderr,"%s - %d PointFloats:\n", msg, size);
  for(i=0; i< size; i++) fprintf(stderr,"\t%g %g\n", 
				 points[i].pf_x, 
				 points[i].pf_y);
}
