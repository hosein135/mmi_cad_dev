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


pnl_route
pnl_route_create (pnl_routekind kind)
{
  pnl_route result = MALLOC (sizeof (*result));

  result->kind = kind;
  result->branches = pnl_dll_create ();

  return result;
}


void
pnl_route_free (pnl_route route)
{
  pnl_route_for_all_branches (route, branch) {
    pnl_branch_free (branch);
  } pnl_end_for;

  FREE (route);
}


void
pnl_route_add_branch (pnl_route route, pnl_branch branch)
{
  pnl_dll_add (route->branches, (pnl_dll) branch);
}


pnl_branch
pnl_branch_create (char *layer, int x0, int y0, int width)
{
  pnl_branch result = MALLOC (sizeof (*result));

  result->layer = STRDUP (layer);
  result->x0 = x0;
  result->y0 = y0;
  result->width = width;
  result->segments = pnl_dll_create ();

  return result;
}


void
pnl_branch_free (pnl_branch branch)
{
  pnl_branch_for_all_segments (branch, segment) {
    pnl_segment_free (segment);
  } pnl_end_for;

  FREE (branch);
}


void
pnl_branch_add_segment (pnl_branch branch, pnl_segment segment)
{
  pnl_dll_add (branch->segments, (pnl_dll) segment);
}


pnl_segment
pnl_segment_create_x_segment (int x)
{
  pnl_x_segment result = MALLOC (sizeof (*result));

  result->kind = pnl_segmentkind_x;
  result->x = x;

  return (pnl_segment) result;
}


pnl_segment
pnl_segment_create_y_segment (int y)
{
  pnl_y_segment result = MALLOC (sizeof (*result));

  result->kind = pnl_segmentkind_y;
  result->y = y;

  return (pnl_segment) result;
}


pnl_segment
pnl_segment_create_via (char *via_name)
{
  pnl_via result = MALLOC (sizeof (*result));

  result->kind = pnl_segmentkind_via;
  result->name = STRDUP (via_name);

  return (pnl_segment) result;
}


void
pnl_segment_free (pnl_segment segment)
{
  pnl_via via = (pnl_via) segment;

  if ( via->kind == pnl_segmentkind_via ) {
    FREE (via->name);
  }

  FREE (via);
}
