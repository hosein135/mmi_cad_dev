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

#include "port.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "nl.h"
#include "skip-list.h"
#include "pnl.h"
#include "pnl_int.h"


pnl_rectangle
pnl_rectangle_create (char *layer, int x0, int y0, int x1, int y1)
{
  pnl_rectangle result = MALLOC (sizeof (*result));

  result->layer = STRDUP (layer);
  result->x0 = x0;
  result->y0 = y0;
  result->x1 = x1;
  result->y1 = y1;

  return result;
}


void
pnl_rectangle_get_center (pnl_rectangle rect, int *x_p, int *y_p, int *area_p)
{
  int width  = abs (rect->x0 - rect->x1);
  int height = abs (rect->y0 - rect->y1);

  *area_p = width * height;

  *x_p = (rect->x0 + rect->x1) / 2;
  *y_p = (rect->y0 + rect->y1) / 2;
}


void
pnl_rectangle_free (pnl_rectangle rect)
{
  FREE (rect->layer);
  FREE (rect);
}


pnl_geometry
pnl_geometry_create (pnl_geometryclass class, char *name)
{
  pnl_geometry result = MALLOC (sizeof (*result));

  result->class = class;
  result->name = STRDUP (name);
  result->points = NULL;

  return result;
}


void
pnl_geometry_free (pnl_geometry g)
{
  FREE (g->name);

  if ( g->points != NULL ) {
    ar_free (g->points);
  }

  FREE (g);
}


void
pnl_geometry_add_point (pnl_geometry g, int x, int y)
{
  ASSERT (g->class == pnl_geometryclass_via);

  if ( g->points == NULL ) {
    g->points = ar_alloc (2, sizeof (int));
  }

  ar_add (g->points, &x);
  ar_add (g->points, &y);
}


void
pnl_geometry_add_rectangle (pnl_geometry g, int x0, int y0, int x1, int y1)
{
  int four = 4;

  ASSERT (g->class == pnl_geometryclass_layer);

  if ( g->points == NULL ) {
    g->points = ar_alloc (2, sizeof (int));
  }

  ar_add (g->points, &four);
  ar_add (g->points, &x0);
  ar_add (g->points, &y0);
  ar_add (g->points, &x1);
  ar_add (g->points, &y1);
}


void
pnl_geometry_add_polygon (pnl_geometry g, ar points)
{
  int size = ar_size (points);

  ASSERT (g->class == pnl_geometryclass_layer);

  if ( g->points == NULL ) {
    g->points = ar_alloc (2, sizeof (int));
  }

  ar_add (g->points, &size);

  ar_for_all (points, int, coord) {
    ar_add (g->points, &coord);
  } ar_end_for;
}


void
pnl_layer_geometry_get_center (pnl_geometry g, int *cx, int *cy,
			       double *area)
{
  ar points = g->points;
  int size = ar_size (g->points);
  double total_area = 0;
  double tx = 0;
  double ty = 0;
  int i = 0;

  ASSERT (g->class == pnl_geometryclass_layer);

  while ( i < size ) {
    int j;
    int num_points;
    int x, y;
    int xmin, ymin;
    int xmax, ymax;

    ar_ref (points, i, &num_points);
    i++;

    ar_ref (points, i, &x);
    i++;
    ar_ref (points, i, &y);
    i++;

    xmin = xmax = x;
    ymin = ymax = y;

    for ( j = 2; j < num_points; j += 2 ) {
      ar_ref (points, i, &x);
      i++;
      ar_ref (points, i, &y);
      i++;

      if ( x < xmin )
	xmin = x;
      if ( x > xmax )
	xmax = x;

      if ( y < ymin )
	ymin = y;
      if ( y > ymax )
	ymax = y;
    }

    {
      double width = xmax - xmin;
      double height = ymax - ymin;
      double area = width * height;

      total_area += area;

      tx += area * (xmin + xmax) / 2;
      ty += area * (ymin + ymax) / 2;
    }
  }

  *cx = tx / total_area;
  *cy = ty / total_area;
  *area = total_area;
}

