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


static double fsqrt (double x) UNUSED;


static
double
fsqrt (double x)
{
  return sqrt (x);
}


static
double
pl_wire_length_objective (pl_design pldes, double *x, double *grad,
			  double weight)
{
  double total = 0;
  int num_cells = pl_design_num_cells (pldes);
  double num_load_pins_recip = 1.0 / pldes->num_load_pins;
  double perimeter = (pldes->xmax - pldes->xmin) + (pldes->ymax - pldes->ymin);
  double perimeter_sq = perimeter * perimeter;
  double scale = num_load_pins_recip * weight / perimeter_sq;

  ar_for_all (pldes->nets, pl_net, plnet) {
    int driver = plnet->driver;
    double driver_x;
    double driver_y;
    int num_loads = plnet->num_loads;
    int i;
    double num_loads_sq = (double) num_loads * (double) num_loads;
    double net_scale = scale / num_loads_sq;

    driver_x = x[2*driver+0];
    driver_y = x[2*driver+1];
    
    for ( i = 0; i < num_loads; i++ ) {
      int load = plnet->loads[i];
      double load_x = x[2*load+0];
      double load_y = x[2*load+1];
      double dx = driver_x - load_x;
      double dy = driver_y - load_y;
      double dist_sq = dx * dx + dy * dy;

      total += dist_sq * net_scale;
      
      if ( grad != NULL ) {
	double x_grad = 2 * dx * net_scale;
	double y_grad = 2 * dy * net_scale;

	if ( driver < num_cells ) {
	  grad[2*driver+0] += x_grad;
	  grad[2*driver+1] += y_grad;
	}

	if ( load < num_cells ) {
	  grad[2*load+0] -= x_grad;
	  grad[2*load+1] -= y_grad;
	}
      }
    }
  } ar_end_for;

  return total;
}


static double pl_overlap_objective (pl_design, double *, double) UNUSED;


static
double
pl_overlap_objective (pl_design pldes, double *x, double weight)
{
  int i, j;
  int num_x_grids = pldes->num_x_grids;
  int num_y_grids = pldes->num_y_grids;
  double num_grids_recip = 1.0 / ((double) num_x_grids * (double) num_y_grids);
  double scale = weight * num_grids_recip;
  double a = pldes->a;
  double a_sq = a * a;
  double c4_by_a = 4.0 / a;
  double c2_by_a_sq = 2.0 / a_sq;
  double a_sq_by_4 = a_sq / 4.0;

  for ( i = 0; i < num_y_grids; i++ ) {
    for ( j = 0; j < num_x_grids; j++ ) {
      pldes->grid[i*num_x_grids + j] = 0;
    }
  }

  ar_for_all (pldes->cells, pl_cell, plcell) {
    int index = plcell->index;
    double cell_x = x[2*index+0];
    double cell_y = x[2*index+1];

    int grid_x_start = pl_design_get_grid_x_index (pldes, cell_x - a);
    int grid_y_start = pl_design_get_grid_y_index (pldes, cell_y - a);
    int grid_x_end   = pl_design_get_grid_x_index (pldes, cell_x + a);
    int grid_y_end   = pl_design_get_grid_y_index (pldes, cell_y + a);

    if ( grid_x_start < 0 )
      grid_x_start = 0;

    if ( grid_y_start < 0 )
      grid_y_start = 0;

    if ( grid_x_end >= num_x_grids )
      grid_x_end = num_x_grids - 1;

    if ( grid_y_end >= num_y_grids )
      grid_y_end = num_y_grids - 1;

    for ( i = grid_y_start; i <= grid_y_end; i++ ) {
      double grid_y = pl_design_get_grid_y (pldes, i);
      double dy = cell_y - grid_y;
      double dy_sq = dy * dy;

      for ( j = grid_x_start; j <= grid_x_end; j++ ) {
	double grid_x = pl_design_get_grid_x (pldes, j);
	double dx = cell_x - grid_x;
	double dx_sq = dx * dx;

	double dist_sq = dx_sq + dy_sq;
	double grid_incr;

	if ( dist_sq >= a_sq ) {
	  continue;
	}
	else if ( dist_sq >= a_sq_by_4 ) {
	  double dist = sqrt (dist_sq);

	  grid_incr = 2.0 - c4_by_a * dist + c2_by_a_sq * dist_sq;
	}
	else { /* 0 <= dist_sq < a_sq_by_4 */
	  grid_incr = c2_by_a_sq * dist_sq;
	}

	pldes->grid[i*num_x_grids + j] += grid_incr;
      }
    }
  } ar_end_for;

  {
    double total = 0;
    double result;

    for ( i = 0; i < num_y_grids; i++ ) {
      for ( j = 0; j < num_x_grids; j++ ) {
	double grid_val = pldes->grid[i*num_x_grids + j];

	total += grid_val * grid_val;
      }
    }

    result = scale * total;

    return result;
  }
}


static void pl_overlap_objective_gradient (pl_design, double *, double *, double)
     UNUSED;


static
void
pl_overlap_objective_gradient (pl_design pldes, double *x, double *grad,
			       double weight)
{
  int i, j;
  int num_x_grids = pldes->num_x_grids;
  int num_y_grids = pldes->num_y_grids;
  double num_grids_recip = 1.0 / ((double) num_x_grids * (double) num_y_grids);
  double scale = weight * num_grids_recip;
  double a = pldes->a;
  double a_recip = 1.0 / a;
  double a_sq = a * a;
  double c4_by_a = 4.0 / a;
  double c4_by_a_sq = 4.0 / a_sq;
  double a_sq_by_4 = a_sq / 4.0;

  ar_for_all (pldes->cells, pl_cell, plcell) {
    int index = plcell->index;
    double cell_x = x[2*index+0];
    double cell_y = x[2*index+1];

    int grid_x_start = pl_design_get_grid_x_index (pldes, cell_x - a);
    int grid_y_start = pl_design_get_grid_y_index (pldes, cell_y - a);
    int grid_x_end   = pl_design_get_grid_x_index (pldes, cell_x + a);
    int grid_y_end   = pl_design_get_grid_y_index (pldes, cell_y + a);

    if ( grid_x_start < 0 )
      grid_x_start = 0;

    if ( grid_y_start < 0 )
      grid_y_start = 0;

    if ( grid_x_end >= num_x_grids )
      grid_x_end = num_x_grids - 1;

    if ( grid_y_end >= num_y_grids )
      grid_y_end = num_y_grids - 1;

    for ( i = grid_y_start; i <= grid_y_end; i++ ) {
      double grid_y = pl_design_get_grid_y (pldes, i);
      double dy = cell_y - grid_y;
      double dy_sq = dy * dy;

      for ( j = grid_x_start; j <= grid_x_end; j++ ) {
	double grid_x = pl_design_get_grid_x (pldes, j);
	double dx = cell_x - grid_x;
	double dx_sq = dx * dx;
	double dist_sq = dx_sq + dy_sq;
	double grid_partial_x;
	double grid_partial_y;

	if ( dist_sq >= a_sq ) {
	  continue;
	}
	else if ( dist_sq >= a_sq_by_4 ) {
	  double dist = sqrt (dist_sq);
	  double dist_recip = 1.0 / dist;
	  double term = c4_by_a * (a_recip - dist_recip);

	  grid_partial_x = term * dx;
	  grid_partial_y = term * dy;
	}
	else { /* 0 <= dist_sq < a_sq_by_4 */
	  grid_partial_x = c4_by_a_sq * dx;
	  grid_partial_y = c4_by_a_sq * dy;
	}

	{
	  double grid_val = pldes->grid[i*num_x_grids + j];
	  
	  grad[2*index+0] += 2 * grid_val * grid_partial_x * scale;
	  grad[2*index+1] += 2 * grid_val * grid_partial_y * scale;
	}
      }
    }
  } ar_end_for;
}


static
double
pl_boundary_objective (pl_design pldes, double *x, double *grad, double weight)
{
  double total = 0;
  double perimeter_recip = 1.0 / ((double) pldes->num_x_grids +
				  (double) pldes->num_y_grids);
  double a_sq = pldes->a * pldes->a;
  double scale = perimeter_recip * weight / a_sq;

  double xmin = pldes->xmin;
  double xmax = pldes->xmax;
  double ymin = pldes->ymin;
  double ymax = pldes->ymax;

  ar_for_all (pldes->cells, pl_cell, plcell) {
    int index = plcell->index;
    double cell_x = x[2*index+0];
    double cell_y = x[2*index+1];
    double half_width = 0.5 * plcell->width;
    double half_height = 0.5 * plcell->height;

    {
      double from_left = cell_x - half_width - xmin;
      double from_right = xmax - cell_x - half_width;
    
      if ( from_left < 0 ) {
	total += from_left * from_left * scale;
	if ( grad != NULL ) {
	  grad[2*index+0] += 2 * from_left * scale;
	}
      }

      if ( from_right < 0 ) {
	total += from_right * from_right * scale;
	if ( grad != NULL ) {
	  grad[2*index+0] += -2 * from_right * scale;
	}
      }
    }

    {
      double from_bottom = cell_y - half_height - ymin;
      double from_top = ymax - cell_y - half_height;

      if ( from_bottom < 0 ) {
	total += from_bottom * from_bottom * scale;
	if ( grad != NULL ) {
	  grad[2*index+1] += 2 * from_bottom * scale;
	}
      }

      if ( from_top < 0 ) {
	total += from_top * from_top * scale;
	if ( grad != NULL ) {
	  grad[2*index+1] += -2 * from_top * scale;
	}
      }
    }
  } ar_end_for;

  return total;
}


double pl_last_wire_obj;
double pl_last_overlap_obj;
double pl_last_boundary_obj;


int pl_overlap_objective2_debug = 0;

double
pl_overlap_objective2 (pl_design pldes, double *x, double *grad, double weight)
{
  int num_x_grids = pldes->num_x_grids;
  int num_y_grids = pldes->num_y_grids;
  double total = 0.0;

  pl_design_clear_bins (pldes);

  ar_for_all (pldes->cells, pl_cell, plcell) {
    int index = plcell->index;
    double cell_x = x[2*index+0];
    double cell_y = x[2*index+1];
    int width = plcell->width;
    int height = plcell->height;
    double cell_x0 = cell_x - 0.5 * width;
    double cell_y0 = cell_y - 0.5 * height;
    double cell_y1 = cell_y + 0.5 * height;

    int grid_x_start = pl_design_get_grid_x_index (pldes, cell_x0);
    int grid_y_start = pl_design_get_grid_y_index (pldes, cell_y0);
    int grid_y_end   = pl_design_get_grid_y_index (pldes, cell_y1);

    if ( grid_x_start >= 0 && grid_x_start < num_x_grids ) {
      if ( grid_y_start >= 0 && grid_y_start < num_y_grids ) {
	int offset = grid_y_start * num_x_grids + grid_x_start;
	pldes->bins[offset] = pl_list_cons (pldes, plcell, pldes->bins[offset]);
      }

      if ( grid_y_end >= 0 && grid_y_end < num_y_grids ) {
	int offset = grid_y_end   * num_x_grids + grid_x_start;
	pldes->bins[offset] = pl_list_cons (pldes, plcell, pldes->bins[offset]);
      }
    }

    plcell->time = -1;
  } ar_end_for;

  if ( pl_overlap_objective2_debug ) {
    int i, j;

    printf ("\n");

    for ( i = 0; i < num_y_grids; i++ ) {
      int offset = num_x_grids * i;

      printf ("%3d: ", i);

      for ( j = 0; j < num_x_grids; j++ ) {
	printf (" %2d", pl_list_length (pldes->bins[offset + j]));
      }
      printf ("\n");
    }
    printf ("\n");
  }

  ar_for_all (pldes->cells, pl_cell, plcell1) {
    int i, j;
    int index1 = plcell1->index;
    double cell1_x = x[2*index1+0];
    double cell1_y = x[2*index1+1];
    int width = plcell1->width;
    int height = plcell1->height;
    double cell1_x0 = cell1_x - 0.5 * width;
    double cell1_y0 = cell1_y - 0.5 * height;
    double cell1_x1 = cell1_x + 0.5 * width;
    double cell1_y1 = cell1_y + 0.5 * height;
    pnl_cell pcell1 = plcell1->pcell;
    nl_cell cell1 = pnl_cell_nl_rep (pcell1);

    int grid_x_start = pl_design_get_grid_x_index (pldes, cell1_x0) - 1;
    int grid_y_start = pl_design_get_grid_y_index (pldes, cell1_y0) - 1;
    int grid_x_end   = pl_design_get_grid_x_index (pldes, cell1_x1) + 1;
    int grid_y_end   = pl_design_get_grid_y_index (pldes, cell1_y1) + 1;
    
    if ( grid_x_start < 0 )
      grid_x_start = 0;

    if ( grid_y_start < 0 )
      grid_y_start = 0;

    if ( grid_x_end >= num_x_grids )
      grid_x_end = num_x_grids - 1;

    if ( grid_y_end >= num_y_grids )
      grid_y_end = num_y_grids - 1;

    for ( i = grid_y_start; i <= grid_y_end; i++ ) {
      int offset = num_x_grids * i;

      for ( j = grid_x_start; j <= grid_x_end; j++ ) {
	pl_list cells = pldes->bins[offset + j];

	while ( cells != NULL ) {
	  pl_cell plcell2 = cells->the_car;
	  int index2;
	  double cell2_x;
	  double cell2_y;
	  double cell2_x0;
	  double cell2_y0;
	  double cell2_y1;

	  cells = cells->the_cdr;
	  
	  if ( plcell2 == plcell1 )
	    continue;

	  if ( plcell2->time == index1 )
	    continue;

	  plcell2->time = index1;

	  index2 = plcell2->index;
	  cell2_x = x[2*index2+0];
	  cell2_x0 = cell2_x - 0.5 * plcell2->width;

	  if ( cell1_x0 > cell2_x0 ) {
	    continue;
	  }
	  else if ( cell1_x0 == cell2_x0 ) {
	    if ( plcell1->index > plcell2->index )
	      continue;
	  }

	  if ( cell1_x1 <= cell2_x0 ) {
	    continue;
	  }

	  cell2_y = x[2*index2+1];
	  cell2_y0 = cell2_y - 0.5 * plcell2->height;

	  if ( cell1_y1 <= cell2_y0 ) {
	    continue;
	  }

	  cell2_y1 = cell2_y + 0.5 * plcell2->height;

	  if ( cell1_y0 >= cell2_y1 ) {
	    continue;
	  }

	  if ( pl_overlap_objective2_debug ) {
	    pnl_cell pcell2 = plcell2->pcell;
	    nl_cell cell2 = pnl_cell_nl_rep (pcell2);

	    printf ("%s %s\n", nl_cell_name (cell1), nl_cell_name (cell2));
	  }

	  {
	    double wavg = 0.5 * (plcell1->width + plcell2->width);
	    double havg = 0.5 * (plcell1->height + plcell2->height);
	    double dx = cell1_x - cell2_x;
	    double dy = cell1_y - cell2_y;
	    double dist_x = dx / wavg;
	    double dist_y = dy / havg;
	    double dist_x_sq = dist_x * dist_x;
	    double dist_y_sq = dist_y * dist_y;
	    double dist_sq = dist_x_sq + dist_y_sq;

	    if ( dist_sq >= 1 ) {
	      continue;
	    }
	    else if ( dist_sq > 0.25 ) {
	      double dist = sqrt (dist_sq);
	      double dist_1 = 1.0 - dist;
	      double dist_recip = 1.0 / dist;
	      double term = 4.0 * weight * (1 - dist_recip);
	      double x_grad = term * dx / (wavg * wavg);
	      double y_grad = term * dy / (havg * havg);
	      double incr = 2.0 * dist_1 * dist_1 * weight;

	      total += incr;
	      grad[2*index1+0] += x_grad;
	      grad[2*index1+1] += y_grad;
	      grad[2*index2+0] -= x_grad;
	      grad[2*index2+1] -= y_grad;
	    }
	    else {
	      double x_grad = -4.0 * weight * dx / (wavg * wavg);
	      double y_grad = -4.0 * weight * dy / (havg * havg);
	      double incr = (1.0 - 2.0 * dist_sq) * weight;

	      total += incr;
	      grad[2*index1+0] += x_grad;
	      grad[2*index1+1] += y_grad;
	      grad[2*index2+0] -= x_grad;
	      grad[2*index2+1] -= y_grad;
	    }
	  }
	}
      }
    }
  } ar_end_for;

  return total;
}

#if 0
double
pl_objective (pl_design pldes, double *x, double wire_weight,
	      double overlap_weight, double boundary_weight)
{
  double wire_obj = pl_wire_length_objective (pldes, x, NULL, wire_weight);
  double overlap_obj = pl_overlap_objective2 (pldes, x, overlap_weight);
  double boundary_obj
    = pl_boundary_objective (pldes, x, NULL, boundary_weight);

  double total = wire_obj + overlap_obj + boundary_obj;

  return total;
}
#endif


double
pl_objective_and_gradient (pl_design pldes, double *x, double *grad,
			   double wire_weight, double overlap_weight,
			   double boundary_weight)
{
  ar_for_all (pldes->cells, pl_cell, plcell) {
    int index = plcell->index;

    grad[2*index+0] = 0.0;
    grad[2*index+1] = 0.0;
  } ar_end_for;

  {
    double wire_obj = pl_wire_length_objective (pldes, x, grad, wire_weight);
    double overlap_obj = pl_overlap_objective2 (pldes, x, grad, overlap_weight);
    double boundary_obj
      = pl_boundary_objective (pldes, x, grad, boundary_weight);

    // pl_overlap_objective_gradient (pldes, x, grad, overlap_weight);

    pl_last_wire_obj = wire_obj;
    pl_last_overlap_obj = overlap_obj;
    pl_last_boundary_obj = boundary_obj;

    return wire_obj + overlap_obj + boundary_obj;
  }
}
