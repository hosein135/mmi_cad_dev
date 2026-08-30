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
  int visited;
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
  int num_vars;
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
  double *fc;
  pl_list *bins;
  int time;
  int site_width;
  int site_height;
  double cell_bloat;
};



static
int
pl_design_get_index (pl_design pldes, nl_object object)
{
  nl_kind kind = nl_object_kind (object);
  int index;

  if ( kind == nl_kind_cell ) {
    nl_cell_attr_get (pldes->cell_attr, (nl_cell) object, &index);
  }
  else if ( kind == nl_kind_port ) {
    nl_port_attr_get (pldes->port_attr, (nl_port) object, &index);
  }
  else {
    ASSERT (0);
  }

  return index;
}


pnl_libcell
pl_get_plibcell_for_libcell (nl_libcell libcell)
{
  nl_library library = nl_libcell_library (libcell);
  pnl_library plibrary = NULL;
  pnl_libcell plibcell;

  nl_library_attr_get_by_name ("pnl library", library, &plibrary);

  if ( plibrary == NULL ) {
    error ("library %s has no physical information", nl_library_name (library));
  }

  plibcell = pnl_library_get_libcell (plibrary, libcell);

  return plibcell;
}


static
void
pl_design_add_cell (pl_design pldes, pnl_cell pcell)
{
  nl_cell cell = pnl_cell_nl_rep (pcell);
  nl_reference ref = nl_cell_reference (cell);
  nl_object link = nl_reference_down_design (ref);
  nl_kind link_kind = nl_object_kind (link);
  pl_cell plcell = GMALLOC (sizeof (*plcell), pldes->group);
  int index = ar_size (pldes->cells) + 1;
  double cell_bloat = pldes->cell_bloat;
  
  plcell->index = index;
  pldes->num_vars += 2;

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
    int width = (x1 - x0) * cell_bloat;
    int height = (y1 - y0) * cell_bloat;
    int x, y;
    int xmid, ymid;

    plcell->pcell = pcell;
    plcell->width = width;
    plcell->height = height;

    error_unwind_protect {
      pnl_cell_get_location (pcell, 0, &x, &y);
    }
    error_on_error {
      error_append_message ("\n\twhile processing cell %s", nl_cell_name (cell));
    } error_end;

    pldes->cell_area += width * height;

    xmid = x + width / 2;
    ymid = y + height / 2;

    pldes->x[2*index+0] = (double) xmid;
    pldes->x[2*index+1] = (double) ymid;

    {
      int index2 = 2*index;

      nl_cell_attr_set (pldes->cell_attr, cell, &index2);
    }
  }

  ar_add (pldes->cells, &plcell);
}


static
void
pl_design_add_port (pl_design pldes, pnl_port pport)
{
  nl_port port = pnl_port_nl_rep (pport);
  int num_cells = ar_size (pldes->cells);
  int num_ports = ar_size (pldes->ports);
  int index = num_cells + num_ports + 1;
  pl_port plport = GMALLOC (sizeof (*plport), pldes->group);
  int x, y;

  plport->index = index;

  plport->pport = pport;

  pnl_port_get_location (pport, &x, &y);

  pldes->x[2*index+0] = (double) x;
  pldes->x[2*index+1] = (double) y;

  {
    int index2 = 2*index;

    nl_port_attr_set (pldes->port_attr, port, &index2);
  }

  ar_add (pldes->ports, &plport);
}


static
void
pl_design_add_net (pl_design pldes, pnl_net pnet)
{
  nl_net net = pnl_net_nl_rep (pnet);
  int num_pins = nl_net_num_pins (net);
  pl_net plnet = GMALLOC (sizeof (*plnet) 
			  + num_pins * sizeof (int), pldes->group);
  int load_count = 0;

  plnet->driver = -1;

  nl_net_for_all_pins (net, pin) {
    nl_direction dir = nl_pin_direction (pin);
    nl_object owner = (nl_object) nl_pin_owner (pin);
    int idx = pl_design_get_index (pldes, owner);

    if ( dir == nl_direction_out ) {
      if ( plnet->driver >= 0 ) {
	error ("net %s has more than one driver", nl_net_name (net));
      }
      else {
	plnet->driver = idx;
      }
    }
    else if ( dir == nl_direction_in ) {
      plnet->loads[load_count] = idx;
      load_count++;
    }

  } nl_end_for;

  if ( plnet->driver < 0 ) {
    /* net had no driver, ignore it */
    FREE (plnet);
  }
  else {
    ASSERT (load_count == num_pins - 1);
    plnet->num_loads = load_count;
    ar_add (pldes->nets, &plnet);
    pldes->num_load_pins += load_count;
  }
}


static
void
pl_min_cell_size (pl_design pldes, int *min_width_p, int *min_height_p)
{
  int min_width = pldes->xmax - pldes->xmin;
  int min_height = pldes->ymax - pldes->ymin;
  
  ar_for_all (pldes->cells, pl_cell, plcell) {
    int width = plcell->width;
    int height = plcell->height;

    if ( width < min_width ) {
      min_width = width;
    }

    if ( height < min_height ) {
      min_height = height;
    }
  } ar_end_for;

  *min_width_p = min_width;
  *min_height_p = min_height;
}


void
pl_design_compute_fc (pl_design pldes, double *x, int zero)
{
  int i;
  int num_vars = pl_design_num_vars (pldes);
  double fc_scale_x;
  double fc_scale_y;

  {
    double des_width = pldes->xmax - pldes->xmin;
    double des_height = pldes->ymax - pldes->ymin;

    double denom = des_width * des_width + des_height * des_height;

    denom /= (pldes->a * pldes->a);

    fc_scale_x = 1.0 / (des_width * denom);
    fc_scale_y = 1.0 / (des_height * denom);
  }

  for ( i = 0; i < num_vars; i++ ) {
    pldes->fc[i] = 0.0;
  }

  if ( zero ) {
    return;
  }

  pl_design_for_all_cells (pldes, plcell1) {
    int index1 = pl_cell_index (plcell1);
    double cell1_x = x[index1+0];
    double cell1_y = x[index1+1];
    int width1 = pl_cell_width (plcell1);
    int height1 = pl_cell_height (plcell1);
    double area1 = (double) width1 * (double) height1;
    int cell_gridx = pl_design_get_grid_x_index (pldes, cell1_x);
    int cell_gridy = pl_design_get_grid_x_index (pldes, cell1_y);

    {
      double grid_area = pldes->grid_xd * pldes->grid_yd;

      for ( i = 0; i < pldes->num_y_grids; i++ ) {
	double grid_y = pldes->grid_ymin + i * pldes->grid_yd + 0.5 * pldes->grid_yd;
	int j;

	if ( grid_y < pldes->ymin )
	  continue;

	if ( grid_y > pldes->ymax )
	  continue;
    
	for ( j = 0; j < pldes->num_x_grids; j++ ) {
	  double grid_x = pldes->grid_xmin + j * pldes->grid_xd + 0.5 * pldes->grid_xd;

	  if ( grid_x < pldes->xmin )
	    continue;

	  if ( grid_x > pldes->xmax )
	    continue;

	  if ( i == cell_gridy && j == cell_gridx )
	    continue;

	  {
	    double dx = cell1_x - grid_x;
	    double dy = cell1_y - grid_y;
	    double d_sq = dx * dx + dy * dy;
	    double fx = area1 * grid_area * dx / d_sq;
	    double fy = area1 * grid_area * dy / d_sq;

	    pldes->fc[index1+0] += fx * fc_scale_x;
	    pldes->fc[index1+1] += fy * fc_scale_y;
	  }
	}
      }
    }
  
    pl_design_for_all_cells (pldes, plcell2) {
      if ( plcell1 == plcell2 ) {
	continue;
      }

      {
	int index2 = pl_cell_index (plcell2);
	double cell2_x = x[index2+0];
	double cell2_y = x[index2+1];
	double dx = cell1_x - cell2_x;
	double dy = cell1_y - cell2_y;
	double d_sq = dx * dx + dy * dy;
	int width2 = pl_cell_width (plcell2);
	int height2 = pl_cell_height (plcell2);
	double area2 = (double) width2 * (double) height2;
	double fx = - area1 * area2 * dx / d_sq;
	double fy = - area1 * area2 * dy / d_sq;

	pldes->fc[index1+0] += fx * fc_scale_x;
	pldes->fc[index1+1] += fy * fc_scale_y;
      }
    } pl_end_for;
  } pl_end_for;
}


pl_design
pl_design_create (pnl_design pdesign, double cell_bloat)
{
  nl_design design = pnl_design_nl_rep (pdesign);
  volatile pl_design result = NULL;

  error_unwind_protect {
    char *name = nl_design_name (design);
    char *format = "pl design for %s";
    char *buf = alloca (strlen (name) + strlen (format));
    int num_nets = nl_design_num_nets (design);
    int num_cells = nl_design_num_cells (design);
    int num_ports = nl_design_num_ports (design);
    mem_group g;

    sprintf (buf, format, name);
    g = mem_group_create (buf, 8);

    result = GMALLOC (sizeof (*result), g);
    result->group = g;
    result->cell_attr = NULL;
    result->port_attr = NULL;
    result->time = 0;

    result->nets = ar_alloc_from_group (num_nets, sizeof (pl_net), g);
    result->cells = ar_alloc_from_group (num_cells, sizeof (pl_cell), g);
    result->ports = ar_alloc_from_group (num_ports, sizeof (pl_port), g);

    result->num_vars = 2;
    result->num_load_pins = 0;
    result->cell_area = 0;

    result->site_width  =  620;
    result->site_height = 6200;

    result->cell_bloat = cell_bloat;

    result->x = GMALLOC (2 * (num_cells + num_ports + 1) * sizeof (double), g);
    result->fc = GMALLOC (2 * (num_cells + num_ports + 1) * sizeof (double), g);

    result->x[0] = 0.0;
    result->x[1] = 0.0;

    {
      int x0, y0;
      int x1, y1;
      double xpad;
      double ypad;

      pnl_design_get_die_area (pdesign, &x0, &y0, &x1, &y1);

      result->xmin = (double) x0;
      result->ymin = (double) y0;
      result->xmax = (double) x1;
      result->ymax = (double) y1;

      xpad = (result->xmax + result->xmin) / 5.0;
      ypad = (result->ymax + result->ymin) / 5.0;

      result->grid_xmin = result->xmin - 0.5 * xpad;
      result->grid_xmax = result->xmax + 0.5 * xpad;
      result->grid_ymin = result->ymin - 0.5 * ypad;
      result->grid_ymax = result->ymax + 0.5 * ypad;
    }

    result->cell_attr = nl_cell_attr_create ("pl cell", design, nl_density_dense,
					     sizeof (int), NULL, NULL);

    result->port_attr = nl_port_attr_create ("pl port", design, nl_density_dense,
					     sizeof (int), NULL, NULL);

    pnl_design_for_all_cells (pdesign, pcell) {
      pl_design_add_cell (result, pcell);
    } pnl_end_for;

    pnl_design_for_all_ports (pdesign, pport) {
      pl_design_add_port (result, pport);
    } pnl_end_for;

    pnl_design_for_all_nets (pdesign, pnet) {
      pl_design_add_net (result, pnet);
    } pnl_end_for;

    {
      double grid_width = result->grid_xmax - result->grid_xmin;
      double grid_height = result->grid_ymax - result->grid_ymin;
      int min_width;
      int min_height;
      int num_x_grids;
      int num_y_grids;
      int num_grids;

      pl_min_cell_size (result, &min_width, &min_height);

      num_x_grids = 2 * grid_width / min_width;
      num_y_grids = grid_height / min_height;

      result->num_x_grids = num_x_grids;
      result->num_y_grids = num_y_grids;
      result->grid_xd = grid_width / num_x_grids;
      result->grid_yd = grid_height / num_y_grids;

      num_grids = num_x_grids * num_y_grids;

      result->grid = GMALLOC (sizeof (double) * num_grids, g);
      result->bins = GMALLOC (sizeof (pl_list) * num_grids, g);

      {
	int i;

	for ( i = 0; i < num_grids; i++ ) {
	  result->bins[i] = NULL;
	}
      }
	

      {
	double num_cells = ar_size (result->cells);
	double avg_size = result->cell_area / num_cells;

	result->a = sqrt (avg_size * 24.0 / (7.0 * 3.1416));
      }
    }
  }
  error_on_error {
    if ( result != NULL ) {
      pl_design_free (result);
    }
  } error_end;

  return result;
}


void
pl_design_free (pl_design pldes)
{
  mem_group g = pldes->group;

  if ( pldes->cell_attr != NULL ) {
    nl_design design = (nl_design) nl_cell_attr_owner (pldes->cell_attr);

    ASSERT (nl_design_kind (design) == nl_kind_design);
    nl_design_remove_attr (design, (nl_attr) pldes->cell_attr);
  }

  if ( pldes->port_attr != NULL ) {
    nl_design design = (nl_design) nl_port_attr_owner (pldes->port_attr);

    ASSERT (nl_design_kind (design) == nl_kind_design);
    nl_design_remove_attr (design, (nl_attr) pldes->port_attr);
  }

  mem_group_free (g);
}


double
pl_design_get_grid_x (pl_design pldes, int n)
{
  double result = pldes->grid_xmin + pldes->grid_xd * (0.5 + n);

  return result;
}


int
pl_design_get_grid_x_index (pl_design pldes, double x)
{
  int result = (x - pldes->grid_xmin) / pldes->grid_xd;

  return result;
}


double
pl_design_get_grid_y (pl_design pldes, int n)
{
  double result = pldes->grid_ymin + pldes->grid_yd * (0.5 + n);

  return result;
}


int
pl_design_get_grid_y_index (pl_design pldes, double y)
{
  int result = (y - pldes->grid_ymin) / pldes->grid_yd;

  return result;
}


int
pl_design_num_cells (pl_design pldes)
{
  int num_cells = ar_size (pldes->cells);

  return num_cells;
}


pl_list
pl_list_cons (pl_design pldes, pl_cell plcell, pl_list rest)
{
  pl_list result = GMALLOC (sizeof (*result), pldes->group);

  result->the_car = plcell;
  result->the_cdr = rest;

  return result;
}


void
pl_design_clear_bins (pl_design pldes)
{
  int i;
  int num_x_bins = pldes->num_x_grids;
  int num_y_bins = pldes->num_y_grids;
  int num_bins = num_x_bins * num_y_bins;

  for ( i = 0; i < num_bins; i++ ) {
    pl_list l = pldes->bins[i];

    pldes->bins[i] = NULL;

    while (l != NULL) {
      pl_list next = l->the_cdr;

      FREE (l);
      l = next;
    }
  }
}

  
ar
pl_design_get_overlapping_cells (pl_design pldes)
{
  ar result = ar_alloc (0, sizeof (nl_cell));

  ar_for_all (pldes->cells, pl_cell, plcell1) {
    int index1 = plcell1->index;
    double cell1_x = pldes->x[2*index1+0];
    double cell1_y = pldes->x[2*index1+1];
    int width1 = plcell1->width;
    int height1 = plcell1->height;
    double cell1_x0 = cell1_x - 0.5 * width1;
    double cell1_x1 = cell1_x + 0.5 * width1;
    double cell1_y0 = cell1_y - 0.5 * height1;
    double cell1_y1 = cell1_y + 0.5 * height1;

    ar_for_all (pldes->cells, pl_cell, plcell2) {
      int index2 = plcell2->index;
      double cell2_x = pldes->x[2*index2+0];
      double cell2_y = pldes->x[2*index2+1];
      int width2 = plcell2->width;
      int height2 = plcell2->height;
      double cell2_x0 = cell2_x - 0.5 * width2;
      // double cell2_x1 = cell2_x + 0.5 * width2;
      double cell2_y0 = cell2_y - 0.5 * height2;
      double cell2_y1 = cell2_y + 0.5 * height2;

      if ( plcell1 == plcell2 )
	continue;

      if ( cell1_x0 > cell2_x0 )
	continue;

      if ( cell1_x0 == cell2_x0 )
	if ( index1 > index2 )
	  continue;

      if ( cell1_x1 <= cell2_x0 )
	continue;

      if ( cell1_y1 <= cell2_y0 )
	continue;

      if ( cell1_y0 >= cell2_y1 )
	continue;

      {
	pnl_cell pcell1 = plcell1->pcell;
	pnl_cell pcell2 = plcell2->pcell;
	nl_cell cell1 = pnl_cell_nl_rep (pcell1);
	nl_cell cell2 = pnl_cell_nl_rep (pcell2);

	ar_add (result, &cell1);
	ar_add (result, &cell2);
      }
    } ar_end_for;
  } ar_end_for;

  return result;
}


int
pl_design_num_vars (pl_design pldes)
{
  return pldes->num_vars;
}


int
pl_cell_index (pl_cell plcell)
{
  return 2 * (plcell->index);
}


int
pl_cell_width (pl_cell plcell)
{
  return plcell->width;
}


int
pl_cell_height (pl_cell plcell)
{
  return plcell->height;
}


double *
pl_design_x (pl_design pldes)
{
  return pldes->x;
}


ar
pl_design_cells (pl_design pldes)
{
  return pldes->cells;
}


ar
pl_design_nets (pl_design pldes)
{
  return pldes->nets;
}


pnl_cell
pl_cell_pcell (pl_cell plcell)
{
  return plcell->pcell;
}


double
pl_design_xmin (pl_design pldes)
{
  return pldes->xmin;
}


double
pl_design_ymin (pl_design pldes)
{
  return pldes->ymin;
}


double
pl_design_xmax (pl_design pldes)
{
  return pldes->xmax;
}


double
pl_design_ymax (pl_design pldes)
{
  return pldes->ymax;
}


int
pl_design_num_x_grids (pl_design pldes)
{
  return pldes->num_x_grids;
}


int
pl_design_num_y_grids (pl_design pldes)
{
  return pldes->num_y_grids;
}


int
pl_net_driver (pl_net plnet)
{
  return plnet->driver;
}


int
pl_net_num_loads (pl_net plnet)
{
  return plnet->num_loads;
}


int
pl_net_get_load (pl_net plnet, int load)
{
  return plnet->loads[load];
}


int
pl_design_num_load_pins (pl_design pldes)
{
  return pldes->num_load_pins;
}


void
pl_cell_clear_visited (pl_cell plcell)
{
  plcell->visited = -1;
}


int
pl_cell_visited (pl_cell plcell, int index)
{
  return plcell->visited == index;
}


void
pl_cell_set_visited (pl_cell plcell, int index)
{
  plcell->visited = index;
}


void
pl_design_add_cell_to_bin (pl_design pldes, int x, int y, pl_cell plcell)
{
  int offset = y * pldes->num_x_grids + x;

  pldes->bins[offset] = pl_list_cons (pldes, plcell, pldes->bins[offset]);
}


pl_list
pl_design_get_bin (pl_design pldes, int x, int y)
{
  int offset = y * pldes->num_x_grids + x;

  return pldes->bins[offset];
}


pl_cell
pl_list_car (pl_list list)
{
  return list->the_car;
}


pl_list
pl_list_cdr (pl_list list)
{
  return list->the_cdr;
}


char *
pl_cell_name (pl_cell plcell)
{
  pnl_cell pcell = plcell->pcell;
  nl_cell cell = pnl_cell_nl_rep (pcell);
  char *name = nl_cell_name (cell);

  return name;
}


nl_cell
pl_cell_get_nl (pl_cell plcell)
{
  pnl_cell pcell = plcell->pcell;
  nl_cell cell = pnl_cell_nl_rep (pcell);

  return cell;
}


double
pl_design_a (pl_design pldes)
{
  return pldes->a;
}


int
pl_list_length (pl_list list)
{
  int result = 0;
  pl_list l = list;

  while (l != NULL) {
    result++;
    l = l->the_cdr;
  }

  return result;
}


int
pl_design_site_width (pl_design pldes)
{
  return pldes->site_width;
}


int
pl_design_site_height (pl_design pldes)
{
  return pldes->site_height;
}


pl_cell
pl_design_get_cell (pl_design pldes, int index)
{
  pl_cell result;

  ar_ref (pldes->cells, index, &result);

  return result;
}


double *
pl_design_fc (pl_design pldes)
{
  return pldes->fc;
}
