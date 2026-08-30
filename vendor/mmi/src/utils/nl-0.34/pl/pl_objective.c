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
			   double weight) UNUSED;

static
double
pl_wire_length_objective (pl_design pldes, double *x, double *grad,
			  double weight)
{
  if ( weight == 0.0 ) {
    return 0.0;
  }
  else {
    double total = 0;
    int num_vars = pl_design_num_vars (pldes);
    int num_load_pins = pl_design_num_load_pins (pldes);
    double num_load_pins_recip = 1.0 / (double) num_load_pins;
    double xmin = pl_design_xmin (pldes);
    double ymin = pl_design_ymin (pldes);
    double xmax = pl_design_xmax (pldes);
    double ymax = pl_design_ymax (pldes);
    double perimeter = (xmax - xmin) + (ymax - ymin);
    double perimeter_sq = perimeter * perimeter;
    double scale = num_load_pins_recip * weight / perimeter_sq;

    pl_design_for_all_nets (pldes, plnet) {
      int driver = pl_net_driver (plnet);
      double driver_x;
      double driver_y;
      int num_loads = pl_net_num_loads (plnet);
      int i;
      double num_loads_sq = 0.25 * (double) (1 + num_loads) * (double) (1 + num_loads);
      double net_scale = scale / num_loads_sq;

      driver_x = x[driver+0];
      driver_y = x[driver+1];

      ASSERT (driver % 2 == 0);

      if ( driver >= num_vars ) {
	/* it's a port, offset it */
	driver_x += x[0];
	driver_y += x[1];
      }
    
      for ( i = 0; i < num_loads; i++ ) {
	int load = pl_net_get_load (plnet, i);
	double load_x = x[load+0] + (load >= num_vars ? x[0] : 0);
	double load_y = x[load+1] + (load >= num_vars ? x[1] : 0);
	double dx = driver_x - load_x;
	double dy = driver_y - load_y;
	double dist_sq = dx * dx + dy * dy;

	ASSERT (load % 2 == 0);

	total += dist_sq * net_scale;
      

	if ( grad != NULL ) {
	  double x_grad = 2 * dx * net_scale;
	  double y_grad = 2 * dy * net_scale;

	  ASSERT (driver % 2 == 0);
      
	  if ( driver < num_vars ) {
	    grad[driver+0] += x_grad;
	    grad[driver+1] += y_grad;
	  }
	  else {
	    grad[0] += x_grad;
	    grad[1] += y_grad;
	  }

	  if ( load < num_vars ) {
	    grad[load+0] -= x_grad;
	    grad[load+1] -= y_grad;
	  }
	  else {
	    grad[0] -= x_grad;
	    grad[1] -= y_grad;
	  }
	}
      }
    } pl_end_for;

    return total;
  }
}


static double pl_wire_length_objective2 (pl_design, double *, double *, double) UNUSED;


static
double
pl_wire_length_objective2 (pl_design pldes, double *x, double *grad,
			   double weight)
{
  if ( weight == 0.0 ) {
    return 0.0;
  }
  else {
    double total = 0;
    int num_vars = pl_design_num_vars (pldes);
    int num_load_pins = pl_design_num_load_pins (pldes);
    double num_load_pins_recip = 1.0 / (double) num_load_pins;
    double xmin = pl_design_xmin (pldes);
    double ymin = pl_design_ymin (pldes);
    double xmax = pl_design_xmax (pldes);
    double ymax = pl_design_ymax (pldes);
    double perimeter = (xmax - xmin) + (ymax - ymin);
    double perimeter_sq = perimeter * perimeter;
    double scale = num_load_pins_recip * weight / perimeter_sq;

    pl_design_for_all_nets (pldes, plnet) {
      int driver = pl_net_driver (plnet);
      double driver_x;
      double driver_y;
      int num_loads = pl_net_num_loads (plnet);
      int i;
      double num_loads_sq = (double) num_loads * (double) num_loads;
      double net_scale = scale / num_loads_sq;

      driver_x = x[driver+0];
      driver_y = x[driver+1];

      if ( driver >= num_vars ) {
	/* it's a port, offset it */
	driver_x += x[0];
	driver_y += x[1];
      }
    
      for ( i = 0; i < num_loads; i++ ) {
	int load = pl_net_get_load (plnet, i);
	// pl_cell load_cell = pl_design_get_cell (pldes, load);
	double load_x = x[load+0];
	double load_y = x[load+1];
	double dx = driver_x - load_x;
	double dy = driver_y - load_y;
	double dist_sq = dx * dx + dy * dy;
	double a = pl_design_a (pldes);
	double dist = sqrt (dist_sq);

	if ( load >= num_vars ) {
	  load_x += x[0];
	  load_y += x[1];
	}

	if ( dist >= a ) {
	  double diff = dist - a;
	  double grad_term = 2 * (1 - a / dist) * net_scale;
	  double x_grad = grad_term * dx;
	  double y_grad = grad_term * dy;

	  total += diff * diff * net_scale;
	  
	  if ( driver < num_vars ) {
	    grad[driver+0] += x_grad;
	    grad[driver+1] += y_grad;
	  }
	  else {
	    grad[0] += x_grad;
	    grad[1] += y_grad;
	  }

	  if ( load < num_vars ) {
	    grad[load+0] -= x_grad;
	    grad[load+1] -= y_grad;
	  }
	  else {
	    grad[0] -= x_grad;
	    grad[1] -= y_grad;
	  }
	}
      }
    } pl_end_for;

    return total;
  }
}


static
double
pl_boundary_objective (pl_design pldes, double *x, double *grad, double weight)
{
  double total = 0;
  double xmin = pl_design_xmin (pldes);
  double xmax = pl_design_xmax (pldes);
  double ymin = pl_design_ymin (pldes);
  double ymax = pl_design_ymax (pldes);
  //  double perimeter = (xmax - xmin) + (ymax - ymin);
  //  double perimeter_recip = 1.0 / (double) perimeter;
  double perimeter_recip = 1.0 / ((double) pl_design_num_x_grids (pldes) +
				  (double) pl_design_num_y_grids (pldes));
  double a_sq = pl_design_a (pldes) * pl_design_a (pldes);
  double scale = perimeter_recip * weight / a_sq;
  //  double scale = perimeter_recip * weight;

  pl_design_for_all_cells (pldes, plcell) {
    int index = pl_cell_index (plcell);
    double cell_x = x[index+0] - x[0];
    double cell_y = x[index+1] - x[1];
    double half_width = 0.5 * pl_cell_width (plcell);
    double half_height = 0.5 * pl_cell_height (plcell);

    {
      double from_left = cell_x - half_width - xmin;
      double from_right = xmax - cell_x - half_width;
    
      if ( from_left < 0 ) {
	total += from_left * from_left * scale;
	if ( grad != NULL ) {
	  double grad_incr = 2 * from_left * scale;
	  grad[index+0] += grad_incr;
	  grad[0] -= grad_incr;
	}
      }

      if ( from_right < 0 ) {
	total += from_right * from_right * scale;
	if ( grad != NULL ) {
	  double grad_incr = -2 * from_right * scale;
	  grad[index+0] += grad_incr;
	  grad[0] -= grad_incr;
	}
      }
    }

    {
      double from_bottom = cell_y - half_height - ymin;
      double from_top = ymax - cell_y - half_height;

      if ( from_bottom < 0 ) {
	total += from_bottom * from_bottom * scale;
	if ( grad != NULL ) {
	  double grad_incr = 2 * from_bottom * scale;
	  grad[index+1] += grad_incr;
	  grad[1] -= grad_incr;
	}
      }

      if ( from_top < 0 ) {
	total += from_top * from_top * scale;
	if ( grad != NULL ) {
	  double grad_incr = -2 * from_top * scale;
	  grad[index+1] += grad_incr;
	  grad[1] -= grad_incr;
	}
      }
    }
  } pl_end_for;

  return total;
}


double pl_last_objective;
double pl_last_wire_obj;
double pl_last_overlap_obj;
double pl_last_boundary_obj;
double pl_last_row_obj;
double pl_last_distribution_obj;


static
double
pl_cell_overlap_cost (pl_cell plcell1, pl_cell plcell2, double weight,
		      double *x, double *grad)
{
  int width1 = pl_cell_width (plcell1);
  int height1 = pl_cell_height (plcell1);
  int width2 = pl_cell_width (plcell2);
  int height2 = pl_cell_height (plcell2);
  double wavg = 0.5 * (double) (width1 + width2);
  double havg = 0.5 * (double) (height1 + height2);
  double wavg_recip = 1.0 / wavg;
  double havg_recip = 1.0 / havg;
  int index1 = pl_cell_index (plcell1);
  int index2 = pl_cell_index (plcell2);
  double cell1_x = x[index1+0];
  double cell2_x = x[index2+0];
  double dx = cell1_x - cell2_x;
  double cell1_y = x[index1+1];
  double cell2_y = x[index2+1];
  double dy = cell1_y - cell2_y;
  double dist_x = dx * wavg_recip;
  double dist_y = dy * havg_recip;
  double dist_x_sq = dist_x * dist_x;
  double dist_y_sq = dist_y * dist_y;
  double dist_sq = dist_x_sq + dist_y_sq;

  if ( dist_sq >= 1 ) {
    return 0.0;
  }
  else if ( dist_sq > 0.25 ) {
    double dist = sqrt (dist_sq);
    double dist_1 = 1.0 - dist;
    double dist_recip = 1.0 / dist;
    double term = 4.0 * weight * (1 - dist_recip);
    double x_grad = term * dx * wavg_recip * wavg_recip;
    double y_grad = term * dy * havg_recip * havg_recip;
    double cost = 2.0 * dist_1 * dist_1 * weight;

    grad[index1+0] += x_grad;
    grad[index1+1] += y_grad;
    grad[index2+0] -= x_grad;
    grad[index2+1] -= y_grad;

    return cost;
  }
  else {
    double x_grad = -4.0 * weight * dx * wavg_recip * wavg_recip;
    double y_grad = -4.0 * weight * dy * havg_recip * havg_recip;
    double cost = (1.0 - 2.0 * dist_sq) * weight;

    grad[index1+0] += x_grad;
    grad[index1+1] += y_grad;
    grad[index2+0] -= x_grad;
    grad[index2+1] -= y_grad;

    return cost;
  }
}


static
double
pl_cell_overlap_cost2 (pl_cell plcell1, pl_cell plcell2, double weight,
		       double *x, double *grad)
{
  int index1 = pl_cell_index (plcell1);
  int index2 = pl_cell_index (plcell2);
  double xcost, xgrad;
  double ycost, ygrad;

  {
    int width1 = pl_cell_width (plcell1);
    int width2 = pl_cell_width (plcell2);
    double wavg = 0.5 * (double) (width1 + width2);
    double cell1_x = x[index1+0];
    double cell2_x = x[index2+0];
    double dx = cell1_x - cell2_x;
    double dx_sign = 2 * (dx > 0) - 1;
    double xdiff = wavg - dx * dx_sign;
    double wavg_half = 0.5 * wavg;

    ASSERT (xdiff <= wavg);

    if ( xdiff < wavg_half ) {
      xcost = xdiff * xdiff;
      xgrad = -2 * xdiff * dx_sign;
    }
    else {
      xcost = wavg_half * wavg - dx * dx;
      xgrad = -2 * dx;
    }
  }

  {
    int height1 = pl_cell_height (plcell1);
    int height2 = pl_cell_height (plcell2);
    double havg = 0.5 * (double) (height1 + height2);
    double cell1_y = x[index1+1];
    double cell2_y = x[index2+1];
    double dy = cell1_y - cell2_y;
    double dy_sign = 2 * (dy > 0) - 1;
    double ydiff = havg - dy * dy_sign;
    double havg_half = 0.5 * havg;

    ASSERT (ydiff <= havg);

    if ( ydiff < havg_half ) {
      ycost = ydiff * ydiff;
      ygrad = -2 * ydiff * dy_sign;
    }
    else {
      ycost = havg_half * havg - dy * dy;
      ygrad = -2 * dy;
    }
  }

  {
    double total = xcost * ycost * weight;

    grad[index1+0] += xgrad * ycost * weight;
    grad[index1+1] += ygrad * xcost * weight;
    grad[index2+0] -= xgrad * ycost * weight;
    grad[index2+1] -= ygrad * xcost * weight;

    return total;
  }
}


int pl_overlap_objective_method = 2;
int pl_overlap_objective_debug = 0;
ar  pl_overlap_objective_array = NULL;


double
pl_overlap_objective (pl_design pldes, double *x, double *grad, double weight)
{
  int num_x_grids = pl_design_num_x_grids (pldes);
  int num_y_grids = pl_design_num_y_grids (pldes);
  double scale;
  double total = 0.0;

  if ( weight == 0.0 ) {
    return 0.0;
  }

  {
    double a = pl_design_a (pldes);
    int num_cells = pl_design_num_cells (pldes);

    scale = weight / (a * a * a * a * num_cells);
  }

  pl_design_clear_bins (pldes);

  pl_design_for_all_cells (pldes, plcell) {
    int index = pl_cell_index (plcell);
    double cell_x = x[index+0];
    double cell_y = x[index+1];
    int width = pl_cell_width (plcell);
    int height = pl_cell_height (plcell);
    double cell_x0 = cell_x - 0.5 * width;
    double cell_y0 = cell_y - 0.5 * height;
    double cell_y1 = cell_y + 0.5 * height;

    int grid_x_start = pl_design_get_grid_x_index (pldes, cell_x0);
    int grid_y_start = pl_design_get_grid_y_index (pldes, cell_y0);
    int grid_y_end   = pl_design_get_grid_y_index (pldes, cell_y1);

    if ( grid_x_start >= 0 && grid_x_start < num_x_grids ) {
      if ( grid_y_start >= 0 && grid_y_start < num_y_grids ) {
	pl_design_add_cell_to_bin (pldes, grid_x_start, grid_y_start, plcell);
      }

      if ( grid_y_end >= 0 && grid_y_end < num_y_grids ) {
	pl_design_add_cell_to_bin (pldes, grid_x_start, grid_y_end, plcell);
      }
    }

    pl_cell_clear_visited (plcell);
  } pl_end_for;

  if ( pl_overlap_objective_debug > 1 ) {
    int i, j;

    printf ("\n");
    for ( i = 0; i < num_y_grids; i++ ) {
      printf ("%3d: ", i);

      for ( j = 0; j < num_x_grids; j++ ) {
	pl_list list = pl_design_get_bin (pldes, j, i);
	printf (" %2d", pl_list_length (list));
      }
      printf ("\n");
    }
    printf ("\n");
  }

  if ( pl_overlap_objective_debug > 0 ) {
    pl_overlap_objective_array = ar_alloc (0, sizeof (nl_cell));
  }

  pl_design_for_all_cells (pldes, plcell1) {
    int i, j;
    int index1 = pl_cell_index (plcell1);
    double cell1_x = x[index1+0];
    double cell1_y = x[index1+1];
    int width1 = pl_cell_width (plcell1);
    int height1 = pl_cell_height (plcell1);
    double cell1_x0 = cell1_x - 0.5 * width1;
    double cell1_y0 = cell1_y - 0.5 * height1;
    double cell1_x1 = cell1_x + 0.5 * width1;
    double cell1_y1 = cell1_y + 0.5 * height1;

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

      for ( j = grid_x_start; j <= grid_x_end; j++ ) {

	pl_design_for_all_cells_in_bin (pldes, j, i, plcell2) {
	  int index2;
	  double cell2_x;
	  double cell2_y;
	  double cell2_x0;
	  double cell2_y0;
	  double cell2_y1;
	  int width2;
	  int height2;

	  if ( plcell1 == plcell2 ) {
	    continue;
	  }

	  if ( pl_cell_visited (plcell2, index1) ) {
	    continue;
	  }

	  pl_cell_set_visited (plcell2, index1);

	  index2 = pl_cell_index (plcell2);
	  cell2_x = x[index2+0];
	  width2 = pl_cell_width (plcell2);
	  cell2_x0 = cell2_x - 0.5 * width2;

	  if ( cell1_x0 > cell2_x0 ) {
	    continue;
	  }

	  if ( cell1_x0 == cell2_x0 ) {
	    if ( index1 > index2 )
	      continue;
	  }

	  if ( cell1_x1 <= cell2_x0 ) {
	    continue;
	  }

	  cell2_y = x[index2+1];
	  height2 = pl_cell_height (plcell2);
	  cell2_y0 = cell2_y - 0.5 * height2;

	  if ( cell1_y1 <= cell2_y0 ) {
	    continue;
	  }

	  cell2_y1 = cell2_y + 0.5 * height2;

	  if ( cell1_y0 >= cell2_y1 ) {
	    continue;
	  }

	  if ( pl_overlap_objective_debug > 0 ) {
	    nl_cell cell1 = pl_cell_get_nl (plcell1);
	    nl_cell cell2 = pl_cell_get_nl (plcell2);

	    ar_add (pl_overlap_objective_array, &cell1);
	    ar_add (pl_overlap_objective_array, &cell2);
	  }

	  switch ( pl_overlap_objective_method ) {
	  case 1:
	    total += pl_cell_overlap_cost (plcell1, plcell2, scale, x, grad);
	    break;
	  case 2:
	    total += pl_cell_overlap_cost2 (plcell1, plcell2, scale, x, grad);
	    break;
	  default:
	    ASSERT (0);
	  }
	} pl_end_for;
      }
    }
  } pl_end_for;

  return total;
}


static
double
pl_row_objective (pl_design pldes, double *x, double *grad, double weight)
{
  if ( weight == 0.0 ) {
    return 0.0;
  }
  else {
    int site_height = pl_design_site_height (pldes);
    int num_cells = pl_design_num_cells (pldes);
    double scale = weight / (num_cells * (double) site_height * (double) site_height);
    double ymin = pl_design_ymin (pldes);
    double total = 0.0;

    pl_design_for_all_cells (pldes, plcell) {
      int index = pl_cell_index (plcell);
      int cell_height = pl_cell_height (plcell);
      double cell_y = x[index+1] - 0.5 * cell_height;
      double r = site_height;
      double r_by_2 = 0.5 * r;
      double r_by_4 = 0.25 * r;
      double cell_y_offset = cell_y - r_by_4 - ymin - x[1];
      int y_by_r = cell_y_offset / site_height;
      int y_by_r_eff = y_by_r - (cell_y_offset < 0);
      double y_mod_r = cell_y_offset - y_by_r_eff * r;

      if ( y_mod_r <= r_by_2 ) {
	double diff = y_mod_r - r_by_4;
	double grad_incr = -2 * diff * scale;

	total += (r_by_2 * r_by_4 - diff * diff) * scale;
	grad[index+1] += grad_incr;
	grad[1] -= grad_incr;
      }
      else {
	double diff = y_mod_r - r_by_2 - r_by_4;
	double grad_incr = 2 * diff * scale;

	total += diff * diff * scale;
	grad[index+1] += grad_incr;
	grad[1] -= grad_incr;
      }
    } pl_end_for;

    return total;
  }
}


static
double
pl_distribution_objective (pl_design pldes, double *x, double *grad, double weight)
{
  if ( weight == 0.0 ) {
    return 0.0;
  }
  else {
    double xmin = pl_design_xmin (pldes);
    double ymin = pl_design_ymin (pldes);
    double xmax = pl_design_xmax (pldes);
    double ymax = pl_design_ymax (pldes);
    double width = xmax - xmin;
    double height = ymax - ymin;
    double x_var_targ = width * width / 12.0;
    double y_var_targ = height * height / 12.0;
    double x_sigma_targ = sqrt (x_var_targ);
    double y_sigma_targ = sqrt (y_var_targ);
    double N = pl_design_num_cells (pldes);
    double xsum = 0.0;
    double xsum_sq = 0.0;
    double ysum = 0.0;
    double ysum_sq = 0.0;

    pl_design_for_all_cells (pldes, plcell) {
      int index = pl_cell_index (plcell);
      double cell_x = x[index+0];
      double cell_y = x[index+1];

      xsum += cell_x;
      ysum += cell_y;
      xsum_sq += cell_x * cell_x;
      ysum_sq += cell_y * cell_y;
    } pl_end_for;

    {
      double x_mean = xsum / N;
      double y_mean = ysum / N;
      double xsq_mean = xsum_sq / N;
      double ysq_mean = ysum_sq / N;
      double x_var = xsq_mean - x_mean * x_mean;
      double y_var = ysq_mean - y_mean * y_mean;
      double x_sigma = sqrt (x_var);
      double y_sigma = sqrt (y_var);
      double x_factor = weight * (2.0 / N) * (1.0 - x_sigma_targ / x_sigma) / (width * width);
      double y_factor = weight * (2.0 / N) * (1.0 - y_sigma_targ / y_sigma) / (height * height);
      double x_diff = (x_sigma - x_sigma_targ) / width;
      double y_diff = (y_sigma - y_sigma_targ) / height;
      double x_objective = weight * x_diff * x_diff;
      double y_objective = weight * y_diff * y_diff;
      double objective = x_objective + y_objective;

      pl_design_for_all_cells (pldes, plcell) {
	int index = pl_cell_index (plcell);
	double cell_x = x[index+0];
	double cell_y = x[index+1];

	grad[index+0] += (cell_x - x_mean) * x_factor;
	grad[index+1] += (cell_y - y_mean) * y_factor;
      } pl_end_for;

      return objective;
    }
  }
}


int new_wire_obj = 0;

double
pl_objective_and_gradient (pl_design pldes, double *x, double *grad,
			   double wire_weight, double overlap_weight,
			   double boundary_weight, double row_weight,
			   double distribution_weight, double constant_weight)
{
  int i;
  int num_vars = pl_design_num_vars (pldes);
  double *fc = pl_design_fc (pldes);
  double constant_obj = 0.0;

  for ( i = 0; i < num_vars; i++ ) {
    grad[i] = fc[i] * constant_weight / (double) num_vars;
    constant_obj += fc[i] * x[i];
  }

  constant_obj *= constant_weight / (double) num_vars;

  {
    double wire_obj
      = pl_wire_length_objective  (pldes, x, grad, wire_weight);
    double overlap_obj
      = pl_overlap_objective (pldes, x, grad, overlap_weight);
    double boundary_obj
      = pl_boundary_objective (pldes, x, grad, boundary_weight);
    double row_obj
      = pl_row_objective (pldes, x, grad, row_weight);
    double distribution_obj
      = pl_distribution_objective (pldes, x, grad, distribution_weight);

    pl_last_wire_obj = wire_obj;
    pl_last_overlap_obj = overlap_obj;
    pl_last_boundary_obj = boundary_obj;
    pl_last_row_obj = row_obj;
    pl_last_distribution_obj = distribution_obj;

    return constant_obj
      + wire_obj
      + overlap_obj
      + boundary_obj
      + row_obj
      + distribution_obj;
  }
}
