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
#include <math.h>
#include "mem.h"
#include "error.h"
#include "ar.h"
#include "nl.h"
#include "pnl.h"
#include "pl_int.h"


static void pl_compare_gradients (pl_design, double, double, double) UNUSED;

static
void
pl_compare_gradients (pl_design pldes, double wire_weight,
		      double overlap_weight, double boundary_weight)
{
  int i;
  int num_cells = pl_design_num_cells (pldes);
  double *g1 = alloca (sizeof (double) * 2 * num_cells);
  double *g2 = alloca (sizeof (double) * 2 * num_cells);
  double *g3 = alloca (sizeof (double) * 2 * num_cells);
  double objective = pl_objective_and_gradient (pldes, pldes->x, g1, wire_weight,
						overlap_weight, boundary_weight);
  
  fprintf (stdout, "weights are %e, %e, %e\n",
	   wire_weight, overlap_weight, boundary_weight);
  fprintf (stdout, "objective is %e\n", objective);
  fprintf (stdout, "symbolic gradient is\n");
  {
    for ( i = 0; i < num_cells * 2; i++ ) {
      fprintf (stdout, "  %e", g1[i]);
    }
  }
  fprintf (stdout, "\n");

  for ( i = 0; i < 2*num_cells; i++ ) {
    double dx = pldes->x[i] / 1e6;
    double obj1;

    pldes->x[i] += dx;
    obj1 = pl_objective_and_gradient (pldes, pldes->x, g3,
				      wire_weight, overlap_weight, boundary_weight);
    pldes->x[i] -= dx;

    g2[i] = (obj1 - objective) / dx;
  }

  fprintf (stdout, "numeric gradient is \n");
  {
    for ( i = 0; i < num_cells * 2; i++ ) {
      fprintf (stdout, "  %e", g2[i]);
    }
  }
  fprintf (stdout, "\n");

  {
    double norm_diff_sq = 0.0;
    double norm_g_sq = 0.0;
    double max_diff = 0.0;
    int max_diff_index;

    for ( i = 0; i < 2*num_cells; i++ ) {
      double diff = g1[i] - g2[i];
      double abs_diff = fabs (diff);

      norm_diff_sq += diff * diff;
      norm_g_sq += g1[i] * g1[i];

      if ( abs_diff > max_diff ) {
	max_diff = abs_diff;
	max_diff_index = i;
      }
    }

    fprintf (stdout, "norm sq gradient error is %g\n\n", norm_diff_sq / norm_g_sq);
    fprintf (stdout, "max gradient difference is %g (at %d, %e vs %e)\n\n",
	     max_diff, max_diff_index, g1[max_diff_index], g2[max_diff_index]);
  }
}


void
pl_place_design (pnl_design pdesign, double wire_weight, double overlap_weight,
		 double boundary_weight)
{
  volatile pl_design pldes = pl_design_create (pdesign);

  error_unwind_protect {

    if ( 1 )
    {
      double cost;
      int num_cells = ar_size (pldes->cells);
      double *g = alloca (2 * num_cells * sizeof (double));

      printf ("\n\n");
      pl_design_show_overlapping_cells (pldes);
      printf ("\n\n");
      pl_overlap_objective2_debug = 1;
      cost = pl_overlap_objective2 (pldes, pldes->x, g, 1.0);
      printf ("\n\n");
      printf ("overlap objective is %e\n", cost);
      printf ("\n\n");
      cost = pl_overlap_objective2 (pldes, pldes->x, g, 1.0);
      printf ("\n\n");
      printf ("overlap objective is %e\n", cost);
      printf ("\n\n");
      pl_overlap_objective2_debug = 0;
    }

    if ( 1 ) {
    pl_compare_gradients (pldes, wire_weight, overlap_weight, boundary_weight);
    pl_compare_gradients (pldes, 1.0, 0.0, 0.0);
    pl_compare_gradients (pldes, 0.0, 1.0, 0.0);
    pl_compare_gradients (pldes, 0.0, 0.0, 1.0);
    error ("finished");
    }

    pl_optimize_placement (pldes, wire_weight, overlap_weight,
			   boundary_weight);

    ar_for_all (pldes->cells, pl_cell, plcell) {
      pnl_cell pcell = plcell->pcell;
      int index = plcell->index;
      double cell_xd = pldes->x[2*index+0];
      double cell_yd = pldes->x[2*index+1];
      int width = plcell->width;
      int height = plcell->height;

      int cell_x = cell_xd + 0.5 - width / 2.0;
      int cell_y = cell_yd + 0.5 - height / 2.0;

      pnl_cell_set_location (pcell, 0, cell_x, cell_y);
      pnl_cell_set_orientation (pcell, pnl_orientation_N);
      pnl_cell_set_loctype (pcell, pnl_loctype_PLACED);
    } ar_end_for;
  }
  error_on_exit {
    pl_design_free (pldes);
  } error_end;
}


void
pl_randomize_placement (pnl_design pdesign)
{
  int xmin, ymin;
  int xmax, ymax;

  pnl_design_get_die_area (pdesign, &xmin, &ymin, &xmax, &ymax);

  pnl_design_for_all_cells (pdesign, pcell) {
    nl_cell cell = pnl_cell_nl_rep (pcell);
    nl_reference ref = nl_cell_reference (cell);
    nl_object link = nl_reference_down_design (ref);
    nl_kind link_kind = nl_object_kind (link);

    if ( link_kind != nl_kind_libcell ) {
      error ("cell %s is not linked to a library cell", nl_cell_name (cell));
    }
    else {
      pnl_libcell plibcell = pl_get_plibcell_for_libcell ((nl_libcell) link);
      pnl_bbox bbox = pnl_libcell_bbox (plibcell);
      int x0 = pnl_bbox_x0 (bbox);
      int y0 = pnl_bbox_y0 (bbox);
      int x1 = pnl_bbox_x1 (bbox);
      int y1 = pnl_bbox_y1 (bbox);
      int width = x1 - x0;
      int height = y1 - y0;
      int cell_x = xmin + drand48 () * (xmax - xmin - width);
      int cell_y = ymin + drand48 () * (ymax - ymin - height);

      pnl_cell_set_location (pcell, 0, cell_x, cell_y);
      pnl_cell_set_orientation (pcell, pnl_orientation_N);
      pnl_cell_set_loctype (pcell, pnl_loctype_PLACED);
    } pnl_end_for;
  }
}
