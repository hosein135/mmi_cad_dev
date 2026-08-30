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
#include "pl.h"
#include "pl_int.h"


void
pl_place_design (pnl_design pdesign,
		 int iter_max,
		 double wire_weight,
		 double overlap_weight,
		 double boundary_weight,
		 double row_weight,
		 double distribution_weight,
		 double constant_weight,
		 double displacement_limit,
		 double cell_bloat)
{
  pl_design pldes = pl_design_create (pdesign, cell_bloat);

  pl_design_compute_fc (pldes, pl_design_x (pldes), (constant_weight == 0.0));

  error_unwind_protect {

    pl_optimize_placement (pldes, iter_max, wire_weight, overlap_weight,
			   boundary_weight, row_weight, distribution_weight,
			   constant_weight, displacement_limit);

    {
      double *x = pl_design_x (pldes);

      pl_design_for_all_cells (pldes, plcell) {
	pnl_cell pcell = pl_cell_pcell (plcell);
	int index = pl_cell_index (plcell);
	double cell_xd = x[index+0] - x[0];
	double cell_yd = x[index+1] - x[1];
	int width = pl_cell_width (plcell);
	int height = pl_cell_height (plcell);

	int cell_x = cell_xd + 0.5 - width / 2.0;
	int cell_y = cell_yd + 0.5 - height / 2.0;

	pnl_cell_set_location (pcell, 0, cell_x, cell_y);
	pnl_cell_set_orientation (pcell, pnl_orientation_N);
	pnl_cell_set_loctype (pcell, pnl_loctype_PLACED);
      } pl_end_for;
    }
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


ar
pl_get_overlaps (pnl_design pdesign, int brute)
{
  pl_design pldes = pl_design_create (pdesign, 1.0);
  volatile ar result = NULL;

  error_unwind_protect {
    if ( brute ) {
      result = pl_design_get_overlapping_cells (pldes);
    }
    else {
      int num_vars = pl_design_num_vars (pldes);
      double *x = pl_design_x (pldes);
      double *g = alloca (num_vars * sizeof (double));

      pl_overlap_objective_debug = 1;
      pl_overlap_objective (pldes, x, g, 1.0);
      pl_overlap_objective_debug = 0;
      result = pl_overlap_objective_array;
    }
  }
  error_on_error {
    if ( pl_overlap_objective_array != NULL ) {
      ar_free (pl_overlap_objective_array);
    }
    result = NULL;
  }
  error_on_exit {
    pl_design_free (pldes);
    pl_overlap_objective_debug = 0; 
    pl_overlap_objective_array = NULL; 
  } error_end;

  return result;
}


ar
pl_compute_objective_and_gradient (pnl_design pdesign, double delta,
				   double wire_weight,
				   double overlap_weight,
				   double boundary_weight,
				   double row_weight,
				   double distribution_weight,
				   double constant_weight,
				   double cell_bloat)
{
  pl_design pldes = pl_design_create (pdesign, cell_bloat);
  int num_vars = pl_design_num_vars (pldes);
  double *g = alloca (sizeof (double) * num_vars);
  double *x = pl_design_x (pldes);

  double objective = pl_objective_and_gradient (pldes, x, g,
						wire_weight,
						overlap_weight,
						boundary_weight,
						row_weight,
						distribution_weight,
						constant_weight);

  volatile ar result = NULL;

  error_unwind_protect {
    int i;

    if ( delta > 0 ) {
      double *g_tmp = alloca (sizeof (double) * num_vars);

      for ( i = 0; i < num_vars; i++ ) {
	double obj1;

	x[i] += delta;
	obj1 = pl_objective_and_gradient (pldes, x, g_tmp, wire_weight,
					  overlap_weight, boundary_weight,
					  row_weight, distribution_weight,
					  constant_weight);
	x[i] -= delta;

	g[i] = (obj1 - objective) / delta;
      }
    }

    result = ar_alloc (0, sizeof (double));

    ar_add (result, &objective);

    for ( i = 0; i < num_vars; i++ ) {
      ar_add (result, &(g[i]));
    }
  }
  error_on_error {
    if ( result != NULL ) {
      ar_free (result);
    }
  }
  error_on_exit {
    pl_design_free (pldes);
  } error_end;


  return result;
}


int
pl_get_index_of_cell (pnl_design pdesign, nl_cell cell)
{
  pl_design pldes = pl_design_create (pdesign, 1.0);
  int result = -1;

  pl_design_for_all_cells (pldes, plcell) {
    nl_cell nlcell = pl_cell_get_nl (plcell);

    if ( nlcell == cell ) {
      result = pl_cell_index (plcell);
      break;
    }
  } pl_end_for;

  pl_design_free (pldes);

  return result;
}

