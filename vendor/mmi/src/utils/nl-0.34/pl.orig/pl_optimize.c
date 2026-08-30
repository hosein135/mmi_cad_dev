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
static int pl_iter = 0;
static int pl_num_vars;
static double pl_wire_weight;
static double pl_overlap_weight;
static double pl_boundary_weight;


static
void
pl_print_status (double obj, double *grad)
{
  int i;
  double norm_sq_grad = 0.0;

  for ( i = 0; i < pl_num_vars; i++ ) {
    norm_sq_grad = grad[i] * grad[i];
  }

  printf ("%6d:  %.4e  %.4e,   w=%4e, o=%4e, b=%4e\n",
	  pl_iter, obj, norm_sq_grad,
	  pl_last_wire_obj, pl_last_overlap_obj, pl_last_boundary_obj);
}


static
double
pl_funcgrad (double *grad, double *x)
{
  double result
    = pl_objective_and_gradient (pl_pldes, x, grad, pl_wire_weight,
				 pl_overlap_weight, pl_boundary_weight);


  if ( 1 || (pl_iter % 1000 == 0) ) {
    pl_print_status (result, grad);
  }

  pl_iter++;

  return result;
}


void
pl_optimize_placement (pl_design pldes, double wire_weight,
		       double overlap_weight, double boundary_weight)
{
  double min;

  pl_pldes = pldes;
  pl_iter = 0;
  pl_num_vars = 2 * ar_size (pldes->cells);

  pl_wire_weight = wire_weight;
  pl_overlap_weight = overlap_weight;
  pl_boundary_weight = boundary_weight;

  pl_lbfgs (&min, pldes->x, pl_num_vars, pl_funcgrad, 1000);

  {
    double *g = alloca (pl_num_vars * sizeof (double));
    double obj = pl_funcgrad (g, pldes->x);

    pl_print_status (obj, g);
  }
}
