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


static pl_design pl_pldes;
static int pl_gradients;
static int pl_steps;
static int pl_max_steps;
static int pl_num_vars;
static double pl_wire_weight;
static double pl_overlap_weight;
static double pl_boundary_weight;
static double pl_row_weight;
static double pl_distribution_weight;
static double pl_constant_weight;
static double pl_displacement_average_limit;


static
void
pl_print_status (int iter, double *grad, double disp_avg)
{
  int i;
  double norm_sq_grad = 0.0;

  for ( i = 0; i < pl_num_vars; i++ ) {
    norm_sq_grad = grad[i] * grad[i];
  }

  if ( iter >= 0 ) {
    printf ("%6d", iter);
  }
  else {
    printf ("  done");
  }

  printf (" (%6d):  %.4e  %.4e  %.4e,  w=%4e, o=%4e, b=%4e, r=%4e, d=%4e\n",
	  pl_gradients, pl_last_objective, norm_sq_grad, disp_avg,
	  pl_last_wire_obj, pl_last_overlap_obj, pl_last_boundary_obj,
	  pl_last_row_obj, pl_last_distribution_obj);
}


static
double
pl_funcgrad (double *x, double *grad)
{
  double result
    = pl_objective_and_gradient (pl_pldes, x, grad, pl_wire_weight,
				 pl_overlap_weight, pl_boundary_weight,
				 pl_row_weight, pl_distribution_weight,
				 pl_constant_weight);


  pl_gradients++;

  return result;
}


#define DISP_AVERAGE_WINDOW 16

static double pl_disp_queue[DISP_AVERAGE_WINDOW];
static double *pl_last_x;


static
double
pl_average_displacement (int n, double *x)
{
  int i;
  double total = 0.0;

  for ( i = 2; i < n; i += 2 ) {
    double dx = x[i+0] - x[0] - pl_last_x[i+0] + pl_last_x[0];
    double dy = x[i+1] - x[1] - pl_last_x[i+1] + pl_last_x[1];

    pl_last_x[i+0] = x[i+0];
    pl_last_x[i+1] = x[i+1];

    total += dx * dx + dy * dy;
  }

  pl_last_x[0] = x[0];
  pl_last_x[1] = x[1];

  {
    double avg = total / (double) n;

    return avg;
  }
}


static
int
pl_step (double *x, double *grad)
{
  double disp = pl_average_displacement (pl_num_vars, x);
  double disp_average;

  pl_disp_queue[pl_steps % DISP_AVERAGE_WINDOW] = disp;

  pl_steps++;

  if ( pl_steps >= DISP_AVERAGE_WINDOW ) {
    int i;
    double total = 0.0;

    for ( i = 0; i < DISP_AVERAGE_WINDOW; i++ ) {
      total += pl_disp_queue[i];
    }

    disp_average = total / DISP_AVERAGE_WINDOW;
  }
  else {
    disp_average = pl_displacement_average_limit;
  }

  if ( pl_steps % 100 == 0 ) {
    pl_print_status (pl_steps, grad, disp_average);
  }

  if ( disp_average < pl_displacement_average_limit ) {
    return 0;
  }

  if ( pl_steps >= pl_max_steps ) {
    return 0;
  }

  return 1;
}


void
pl_optimize_placement (pl_design pldes, int iter_max, double wire_weight,
		       double overlap_weight, double boundary_weight,
		       double row_weight, double distribution_weight,
		       double constant_weight, double disp_limit)
{
  double min;
  double *x = pl_design_x (pldes);

  pl_pldes = pldes;
  pl_gradients = 0;
  pl_steps = 0;
  pl_num_vars = pl_design_num_vars (pldes);

  pl_last_x = MALLOC (pl_num_vars * sizeof (double));

  pl_max_steps = iter_max;

  pl_wire_weight = wire_weight;
  pl_overlap_weight = overlap_weight;
  pl_boundary_weight = boundary_weight;
  pl_row_weight = row_weight;
  pl_distribution_weight = distribution_weight;
  pl_constant_weight = constant_weight;
  pl_displacement_average_limit = disp_limit;

  pl_lbfgs (&min, x, pl_num_vars, pl_funcgrad, pl_step);

  {
    double *g = alloca (pl_num_vars * sizeof (double));

    pl_funcgrad (x, g);

    pl_print_status (-1, g, 0);
  }

  FREE (pl_last_x);
}
