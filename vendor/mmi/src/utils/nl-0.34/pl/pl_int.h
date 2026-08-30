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


typedef double  (*pl_obj_fun_t) (double *, double *);
typedef int     (*pl_step_fun_t) (double *, double *);

pl_design	pl_design_create (pnl_design, double);
void		pl_design_free (pl_design);
double		pl_design_get_grid_x (pl_design, int);
double		pl_design_get_grid_y (pl_design, int);
int		pl_design_get_grid_x_index (pl_design, double);
int		pl_design_get_grid_y_index (pl_design, double);
int		pl_design_num_cells (pl_design);
int		pl_design_num_vars (pl_design);

double		pl_objective_and_gradient (pl_design, double *, double *,
					   double, double, double, double,
					   double, double);

pnl_libcell     pl_get_plibcell_for_libcell (nl_libcell);

void		pl_optimize_placement (pl_design, int, double, double, double,
				       double, double, double, double);

void		pl_lbfgs (double *, double *, int, pl_obj_fun_t, pl_step_fun_t);


extern double pl_last_objective;
extern double pl_last_wire_obj;
extern double pl_last_overlap_obj;
extern double pl_last_boundary_obj;
extern double pl_last_row_obj;
extern double pl_last_distribution_obj;

pl_list		pl_list_cons (pl_design, pl_cell, pl_list);
void		pl_design_clear_bins (pl_design);
int		pl_cell_index (pl_cell);
int		pl_cell_width (pl_cell);
int		pl_cell_height (pl_cell);
double *	pl_design_x (pl_design);
ar		pl_design_cells (pl_design);
ar		pl_design_nets (pl_design);
pnl_cell	pl_cell_pcell (pl_cell);
double		pl_design_xmin (pl_design);
double		pl_design_ymin (pl_design);
double		pl_design_xmax (pl_design);
double		pl_design_ymax (pl_design);
int		pl_net_driver (pl_net);
int		pl_net_num_loads (pl_net);
int		pl_net_get_load (pl_net, int);
int		pl_design_num_x_grids (pl_design);
int		pl_design_num_y_grids (pl_design);
int		pl_design_num_load_pins (pl_design);
void		pl_cell_clear_visited (pl_cell);
int		pl_cell_visited (pl_cell, int);
void		pl_cell_set_visited (pl_cell, int);
void		pl_design_add_cell_to_bin (pl_design, int, int, pl_cell);
pl_list		pl_design_get_bin (pl_design, int, int);
pl_cell		pl_list_car (pl_list);
pl_list		pl_list_cdr (pl_list);
char *          pl_cell_name (pl_cell);
nl_cell		pl_cell_get_nl (pl_cell);
ar		pl_design_get_overlapping_cells (pl_design);
pl_cell		pl_design_get_cell (pl_design, int);

double		pl_design_a (pl_design);
int		pl_design_site_width (pl_design);
int		pl_design_site_height (pl_design);
double *        pl_design_fc (pl_design);



extern int pl_overlap_objective_debug;
extern ar  pl_overlap_objective_array;
double		pl_overlap_objective (pl_design, double *, double *, double);


#define pl_design_for_all_cells(pldes, var) \
  { ar_for_all (pl_design_cells (pldes), pl_cell, var)


#define pl_design_for_all_cells_in_bin(pldes, x, y, var) \
  { ar_begin_for \
    pl_list __l = pl_design_get_bin (pldes, x, y); \
    pl_cell var; \
    for ( ; \
	  __l != NULL && ((var = pl_list_car (__l)) || 1); \
	  __l = pl_list_cdr (__l) )


#define pl_design_for_all_nets(pldes, var) \
  { ar_for_all (pl_design_nets (pldes), pl_net, var)


#define pl_end_for ar_end_for }

int pl_list_length (pl_list list);

void pl_design_compute_fc (pl_design, double *, int);
