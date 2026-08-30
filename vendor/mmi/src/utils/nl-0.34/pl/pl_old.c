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
    double cell_x = x[index+0];
    double cell_y = x[index+1];

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
    double cell_x = x[index+0];
    double cell_y = x[index+1];

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
	  
	  grad[index+0] += 2 * grid_val * grid_partial_x * scale;
	  grad[index+1] += 2 * grid_val * grid_partial_y * scale;
	}
      }
    }
  } ar_end_for;
}


#if 0
double
pl_objective (pl_design pldes, double *x, double wire_weight,
	      double overlap_weight, double boundary_weight)
{
  double wire_obj = pl_wire_length_objective (pldes, x, NULL, wire_weight);
  double overlap_obj = pl_overlap_objective (pldes, x, overlap_weight);
  double boundary_obj
    = pl_boundary_objective (pldes, x, NULL, boundary_weight);

  double total = wire_obj + overlap_obj + boundary_obj;

  return total;
}
#endif

