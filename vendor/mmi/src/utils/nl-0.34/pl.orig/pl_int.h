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

typedef struct pl_net_s *pl_net;
typedef struct pl_cell_s *pl_cell;
typedef struct pl_port_s *pl_port;
typedef struct pl_design_s *pl_design;
typedef struct pl_list_s *pl_list;


struct pl_net_s {
  int driver;
  int num_loads;
  int loads[0];
};


struct pl_cell_s {
  int index;
  pnl_cell pcell;
  int width;
  int height;
  int time;
};


struct pl_port_s {
  int index;
  pnl_port pport;
};


struct pl_list_s {
  pl_cell the_car;
  pl_list the_cdr;
};


struct pl_design_s {
  mem_group group;
  pnl_design pdesign;
  ar nets;
  ar cells;
  ar ports;
  int num_load_pins;
  double cell_area;
  nl_cell_attr cell_attr;
  nl_port_attr port_attr;
  double xmin;
  double xmax;
  double ymin;
  double ymax;
  double grid_xmin;
  double grid_xmax;
  double grid_ymin;
  double grid_ymax;
  double *x;
  double a;
  int num_x_grids;
  int num_y_grids;
  double grid_xd;
  double grid_yd;
  double *grid;
  pl_list *bins;
  int time;
};


typedef double (*pl_fun_t) (double *, double *);

pl_design	pl_design_create (pnl_design);
void		pl_design_free (pl_design);
double		pl_design_get_grid_x (pl_design, int);
double		pl_design_get_grid_y (pl_design, int);
int		pl_design_get_grid_x_index (pl_design, double);
int		pl_design_get_grid_y_index (pl_design, double);
int		pl_design_num_cells (pl_design);

/* double		pl_objective (pl_design, double *, double, double, double); */
double		pl_objective_and_gradient (pl_design, double *, double *,
					   double, double, double);

pnl_libcell     pl_get_plibcell_for_libcell (nl_libcell);

void		pl_optimize_placement (pl_design, double, double, double);

void		pl_lbfgs (double *, double *, int, pl_fun_t, int);

extern double pl_last_wire_obj;
extern double pl_last_overlap_obj;
extern double pl_last_boundary_obj;

pl_list		pl_list_cons (pl_design, pl_cell, pl_list);
void		pl_design_clear_bins (pl_design);

void pl_design_show_overlapping_cells (pl_design);
double		pl_overlap_objective2 (pl_design, double *, double *, double);

extern int pl_overlap_objective2_debug;

int pl_list_length (pl_list list);

