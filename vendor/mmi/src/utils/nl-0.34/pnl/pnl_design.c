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
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "nl.h"
#include "skip-list.h"
#include "pnl.h"
#include "pnl_int.h"


static
void
pnl_free_object_attr (void *ptr)
{
  pnl_object *pobject_p = (pnl_object *) ptr;

  if ( *pobject_p != NULL ) {
    pnl_kind kind = pnl_object_kind (*pobject_p);

    switch (kind) {

    case pnl_kind_cell:
      pnl_cell_free ((pnl_cell) *pobject_p);
      return;
    case pnl_kind_icell:
      pnl_icell_free ((pnl_icell) *pobject_p);
      return;
    case pnl_kind_net:
      pnl_net_free ((pnl_net) *pobject_p);
      return;
    case pnl_kind_inet:
      pnl_inet_free ((pnl_inet) *pobject_p);
      return;
    case pnl_kind_port:
      pnl_port_free ((pnl_port) *pobject_p);
      return;
    case pnl_kind_design:
      pnl_design_free ((pnl_design) *pobject_p);
      return;
    case pnl_kind_idesign:
      pnl_idesign_free ((pnl_idesign) *pobject_p);
      return;
    default:
      ASSERT (0);
    }
  }
}


pnl_design
pnl_design_create (nl_design design)
{
  mem_group group = nl_design_mem_group (design);
  pnl_design result = GMALLOC (sizeof (*result), group);

  result->kind = pnl_kind_design;
  result->nl_rep = design;
  result->history = NULL;
#if 0
  result->rows = NULL;
#endif

  result->cell_attr = nl_cell_attr_create ("pnl cell",
					   design, nl_density_dense,
					   sizeof (pnl_cell), NULL,
					   pnl_free_object_attr);

  result->port_attr = nl_port_attr_create ("pnl port",
					   design, nl_density_dense,
					   sizeof (pnl_port), NULL,
					   pnl_free_object_attr);

  result->net_attr = nl_net_attr_create ("pnl net",
					 design, nl_density_dense,
					 sizeof (pnl_net), NULL,
					 pnl_free_object_attr);

  result->design_attr = nl_design_attr_create ("pnl design",
					       design, nl_density_dense,
					       sizeof (pnl_design), NULL,
					       pnl_free_object_attr);

  nl_design_attr_set (result->design_attr, design, &result);

  nl_design_for_all_cells (design, cell) {
    pnl_cell pcell = pnl_cell_create (cell);
    nl_cell_attr_set (result->cell_attr, cell, &pcell);
  } nl_end_for;

  nl_design_for_all_ports (design, port) {
    pnl_port pport = pnl_port_create (port);
    nl_port_attr_set (result->port_attr, port, &pport);
  } nl_end_for;

  nl_design_for_all_nets (design, net) {
    pnl_net pnet = pnl_net_create (net);
    nl_net_attr_set (result->net_attr, net, &pnet);
  } nl_end_for;

  result->die_area = NULL;
  result->distance_units = NULL;
  result->x_tracks = NULL;
  result->y_tracks = NULL;
  result->row_sites = NULL;
  result->location_rep = pnl_location_rep_null;

  return result;
}


pnl_idesign
pnl_idesign_create (nl_idesign idesign)
{
  nl_design design = nl_idesign_design (idesign);
  mem_group group = nl_design_mem_group (design);
  pnl_idesign result = GMALLOC (sizeof (*result), group);

  result->kind = pnl_kind_idesign;
  result->nl_rep = idesign;

  result->icell_attr = nl_icell_attr_create ("pnl icell",
					     idesign, nl_density_dense,
					     sizeof (pnl_cell), NULL,
					     pnl_free_object_attr);

  result->inet_attr = nl_inet_attr_create ("pnl inet",
					   idesign, nl_density_dense,
					   sizeof (pnl_net), NULL,
					   pnl_free_object_attr);

  result->idesign_attr = nl_idesign_attr_create ("pnl idesign",
						 idesign, nl_density_dense,
						 sizeof (pnl_design), NULL,
						 pnl_free_object_attr);

  nl_idesign_attr_set (result->idesign_attr, idesign, &result);

  nl_idesign_for_all_icells (idesign, icell) {
    pnl_icell picell = pnl_icell_create (icell);
    nl_idesign down_idesign = nl_icell_down_design (icell);
    if ( down_idesign != NULL ) {
      pnl_idesign_create (down_idesign);
    }
    nl_icell_attr_set (result->icell_attr, icell, &picell);
  } nl_end_for;

  nl_idesign_for_all_inets (idesign, inet) {
    pnl_inet pinet = pnl_inet_create (inet);
    nl_inet_attr_set (result->inet_attr, inet, &pinet);
  } nl_end_for;

  return result;
}


pnl_idesign
pnl_idesign_fill (nl_idesign idesign)
{
  pnl_idesign pidesign = NULL;

  nl_idesign_attr_get_by_name ("pnl idesign", idesign, &pidesign);

  if ( pidesign == NULL ) {
    pidesign = pnl_idesign_create (idesign);
  }
  else {
    nl_icell_attr icell_attr = pidesign->icell_attr;

    nl_idesign_for_all_icells (idesign, icell) {
      nl_idesign down_idesign = nl_icell_down_design (icell);
      pnl_icell picell;

      nl_icell_attr_get (icell_attr, icell, &picell);

      if ( picell == NULL ) {
	picell = pnl_icell_create (icell);
	nl_icell_attr_set (pidesign->icell_attr, icell, &picell);

	if ( down_idesign != NULL ) {
	  pnl_idesign_create (down_idesign);
	}
      }
      else if ( down_idesign != NULL ) {
	pnl_idesign_fill (down_idesign);
      }
    } nl_end_for;
  }

  return pidesign;
}


void
pnl_idesign_update_locations (nl_idesign idesign, int x_origin, int y_origin,
			      pnl_orientation orientation, pnl_loctype loctype)
{
  nl_design design = nl_idesign_design (idesign);
  pnl_design pdesign = NULL;
  pnl_idesign pidesign = NULL;
  int xmin, ymin;
  int xmax, ymax;

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  if ( pdesign == NULL ) {
    return;
  }

  pnl_design_get_die_area (pdesign, &xmin, &ymin, &xmax, &ymax);

  nl_idesign_attr_get_by_name ("pnl idesign", idesign, &pidesign);

  if ( pidesign == NULL ) {
    error ("idesign for %s does not have any physical information",
	   nl_design_name (design));
  }

  nl_idesign_for_all_icells (idesign, icell) {
    nl_cell cell = nl_icell_cell (icell);
    pnl_cell pcell = pnl_design_get_cell (pdesign, cell);
    int cell_x;
    int cell_y;
    pnl_orientation cell_orient;
    pnl_loctype cell_loctype;
    int abs_x;
    int abs_y;
    pnl_orientation abs_orient;
    pnl_loctype abs_loctype;
    pnl_icell picell = pnl_idesign_get_icell (pidesign, icell);
    nl_idesign down_idesign;

    pnl_cell_get_location (pcell, 0, &cell_x, &cell_y);
    cell_orient = pnl_cell_orientation (pcell);
    cell_loctype = pnl_cell_loctype (pcell);

    pnl_translate_coordinates (orientation, cell_x, cell_y,
			       xmin, ymin, xmax, ymax,
			       &abs_x, &abs_y);

    abs_x += x_origin;
    abs_y += y_origin;

    abs_orient = pnl_translate_orientation (cell_orient, orientation);

    switch (loctype) {
    case pnl_loctype_null:
      abs_loctype = cell_loctype;
      break;
    case pnl_loctype_PLACED:
      abs_loctype = pnl_loctype_PLACED;
      break;
    case pnl_loctype_FIXED:
      if ( cell_loctype == pnl_loctype_PLACED ) {
	abs_loctype = pnl_loctype_PLACED;
      }
      else {
	abs_loctype = pnl_loctype_FIXED;
      }
      break;
    case pnl_loctype_COVER:
      if ( cell_loctype == pnl_loctype_PLACED ||
	   cell_loctype == pnl_loctype_FIXED ) {
	abs_loctype = cell_loctype;
      }
      else {
	abs_loctype = pnl_loctype_COVER;
      }
      break;
    default:
      ASSERT (0);
    }

    pnl_icell_set_location (picell, 0, abs_x, abs_y);
    pnl_icell_set_orientation (picell, abs_orient);
    pnl_icell_set_loctype (picell, abs_loctype);

    down_idesign = nl_icell_down_design (icell);

    if ( down_idesign != NULL ) {
      pnl_idesign_update_locations (down_idesign, abs_x, abs_y, abs_orient,
				    abs_loctype);
    }
  } nl_end_for;
}

#if 0

  nl_icell up_icell = nl_idesign_icell (idesign);
  nl_cell up_cell = nl_icell_cell (cell);
  nl_design design = nl_cell_design (cell);
  pnl_design pdesign = NULL;
  pnl_cell pcell;
  int cell_x;
  int cell_y;
  pnl_orientation cell_orientation;
  pnl_loctype cell_loctype;

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  if ( pdesign == NULL ) {
    return;
  }

  pcell = pnl_design_get_cell (pdesign, cell);

  pnl_cell_get_location (pcell, 0, &cell_x, &cell_y);
  cell_orientation = pnl_cell_orientation (pcell);
  cell_loctype = pnl_cell_loctype (pcell);
}
#endif


void
pnl_design_set_die_area (pnl_design pdesign, int x0, int y0, int x1, int y1)
{
  if ( pdesign->die_area == NULL ) {
    nl_design design = pdesign->nl_rep;
    mem_group group = nl_design_mem_group (design);

    pdesign->die_area = GMALLOC (sizeof (*(pdesign->die_area)), group);
  }

  pdesign->die_area->x0 = x0;
  pdesign->die_area->y0 = y0;
  pdesign->die_area->x1 = x1;
  pdesign->die_area->y1 = y1;
}


void
pnl_design_clear_die_area (pnl_design pdesign)
{
  if ( pdesign->die_area != NULL ) {
    FREE (pdesign->die_area);
  }

  pdesign->die_area = NULL;
}


int
pnl_design_get_die_area (pnl_design pdesign,
			 int *x0, int *y0, int *x1, int *y1)
{
  if ( pdesign->die_area == NULL ) {
    return 0;
  }
  else {
    *x0 = pdesign->die_area->x0;
    *y0 = pdesign->die_area->y0;
    *x1 = pdesign->die_area->x1;
    *y1 = pdesign->die_area->y1;

    return 1;
  }
}


void
pnl_design_set_distance_units (pnl_design pdesign, char *unit_name, int number)
{
  nl_design design = pdesign->nl_rep;
  mem_group group = nl_design_mem_group (design);

  if ( pdesign->distance_units == NULL ) {
    pdesign->distance_units = GMALLOC (sizeof (*(pdesign->distance_units)),
				       group);
    pdesign->distance_units->name = NULL;
  }

  if ( pdesign->distance_units->name != NULL ) {
    FREE (pdesign->distance_units->name);
  }

  pdesign->distance_units->name = GSTRDUP (unit_name, group);
  pdesign->distance_units->value = number;
}


void
pnl_design_get_distance_units (pnl_design pdesign, char **unit_name,
			       int *number)
{
  if ( pdesign->distance_units == NULL ) {
    *unit_name = NULL;
    *number = 0;
  }
  else {
    *unit_name = pdesign->distance_units->name;
    *number = pdesign->distance_units->value;
  }
}


static
void
pnl_design_add_tracks (pnl_design pdesign, pnl_dll_head *head_p,
		       int start, int count, int step, ar layers)
{
  pnl_dll_head head = *head_p;
  nl_design design = pdesign->nl_rep;
  mem_group group = nl_design_mem_group (design);
  pnl_tracks tracks;

  if ( head == NULL ) {
    mem_group prev_group = mem_group_set (group);
    head = pnl_dll_create ();
    *head_p = head;
    mem_group_set (prev_group);
  }

  tracks = GMALLOC (sizeof (*tracks), group);

  tracks->start = start;
  tracks->count = count;
  tracks->step = step;

  {
    int num_layers = ar_size (layers);

    tracks->layers = ar_alloc_from_group (num_layers, sizeof (char *), group);

    ar_for_all (layers, char *, layer_name) {
      char *copy = GSTRDUP (layer_name, group);

      ar_add (tracks->layers, &copy);
    } ar_end_for;
  }

  pnl_dll_add (head, (pnl_dll) tracks);
}


static
void
pnl_design_free_tracks (pnl_design pdesign, pnl_dll_head *head_p)
{
  pnl_dll_head head = *head_p;

  pnl_dll_for_all (head, pnl_tracks, tracks) {
    ar_free (tracks->layers);
    FREE (tracks);
  } pnl_end_for;

  pnl_dll_free (head);

  *head_p = NULL;
}


void
pnl_design_add_x_tracks (pnl_design pdesign, int start, int count, int step,
			 ar layer)
{
  pnl_design_add_tracks (pdesign, &(pdesign->x_tracks), start, count, step,
			 layer);
}


void
pnl_design_add_y_tracks (pnl_design pdesign, int start, int count, int step,
			 ar layer)
{
  pnl_design_add_tracks (pdesign, &(pdesign->y_tracks), start, count, step,
			 layer);
}


void
pnl_design_free_x_tracks (pnl_design pdesign)
{
  pnl_design_free_tracks (pdesign, &(pdesign->x_tracks));
}


void
pnl_design_free_y_tracks (pnl_design pdesign)
{
  pnl_design_free_tracks (pdesign, &(pdesign->y_tracks));
}


void
pnl_design_free (pnl_design pdesign)
{
#if 0  
  if ( pdesign->rows != NULL ) {
    sl_for_all_entries (pdesign->rows, x, skip_list, row) {
      if ( row != NULL ) {
	sl_free (row);
      }
    } sl_end_for;

    sl_free (pdesign->rows);
  }
#endif

  if ( pdesign->history != NULL ) {
    ar_for_all (pdesign->history, char *, str) {
      FREE (str);
    } ar_end_for;

    ar_free (pdesign->history);
  }

  if ( pdesign->x_tracks != NULL ) {
    pnl_design_free_tracks (pdesign, &(pdesign->x_tracks));
  }

  if ( pdesign->y_tracks != NULL ) {
    pnl_design_free_tracks (pdesign, &(pdesign->y_tracks));
  }

#if 0
  pnl_design_free_row_sites (pdesign);
#endif

  FREE (pdesign);
}


void
pnl_idesign_free (pnl_idesign pidesign)
{
  FREE (pidesign);
}


pnl_cell
pnl_design_get_cell_by_name (pnl_design pdesign, char *cell_name)
{
  nl_design design = pnl_design_nl_rep (pdesign);
  nl_cell_attr cell_attr = pdesign->cell_attr;
  nl_cell cell = nl_design_get_cell_by_name (design, cell_name);

  if ( cell != NULL ) {
    pnl_cell pcell;

    nl_cell_attr_get (cell_attr, cell, &pcell);

    return pcell;
  }
  else {
    return NULL;
  }
}


pnl_icell
pnl_idesign_get_icell_by_name (pnl_idesign pidesign, char *cell_name)
{
  nl_idesign idesign = pnl_idesign_nl_rep (pidesign);
  nl_icell_attr icell_attr = pidesign->icell_attr;
  nl_icell icell = nl_idesign_get_icell_by_name (idesign, cell_name);

  if ( icell != NULL ) {
    pnl_icell picell;

    nl_icell_attr_get (icell_attr, icell, &picell);

    return picell;
  }
  else {
    return NULL;
  }
}


#if 0
void
pnl_design_add_cell_to_rows (pnl_design pdesign, pnl_cell pcell)
{
  int x;
  int y;
  skip_list row = NULL;

  pnl_cell_get_location (pcell, &x, &y);

  if ( pdesign->rows == NULL ) {
    pdesign->rows = sl_create ();
  }

  sl_get (pdesign->rows, (unsigned int) y, (void **)&row);

  if ( row == NULL ) {
    row = sl_create ();
    sl_insert (pdesign->rows, (unsigned int) y, row);
  }

  {
    pnl_cell existing_cell = NULL;

    sl_get (row, (unsigned int) x, (void **)&existing_cell);

    if ( existing_cell != NULL ) {
      fprintf (stderr, "More than one cell at location %d, %d\n", x, y);
    }

    sl_insert (row, (unsigned int) x, pcell);
  }
}
#endif


#if 0
void
pnl_design_remove_cell_from_rows (pnl_design pdesign, pnl_cell pcell)
{
  int x;
  int y;
  skip_list row = NULL;
  int flag;

  pnl_cell_get_location (pcell, &x, &y);

  flag = sl_get (pdesign->rows, (unsigned int) y, (void **)&row);

  if ( !flag ) {
    return;
  }
  else {
    flag = sl_remove (row, (unsigned int) x);
  }
}
#endif


void
pnl_design_add_row_site (pnl_design pdesign, char *name, char *core_name,
			 int x0, int y0, pnl_orientation orientation,
			 int count, int step, int height)
{
  nl_design design = pdesign->nl_rep;
  mem_group group = nl_design_mem_group (design);
  pnl_row_site row_site = GMALLOC (sizeof (*row_site), group);

  if ( pdesign->row_sites == NULL ) {
    pdesign->row_sites = ar_alloc_from_group (16, sizeof (pnl_row_site),
					      group);
  }

  row_site->name = GSTRDUP (name, group);
  row_site->core = GSTRDUP (core_name, group);
  row_site->x0 = x0;
  row_site->y0 = y0;
  row_site->orientation = orientation;
  row_site->count = count;
  row_site->step = step;
  row_site->height = height;

  ar_add (pdesign->row_sites, &row_site);
}


void
pnl_design_free_row_sites (pnl_design pdesign)
{
  if ( pdesign->row_sites != NULL ) {
    ar_for_all (pdesign->row_sites, pnl_row_site, site) {
      FREE (site);
    } ar_end_for;

    ar_free (pdesign->row_sites);

    pdesign->row_sites = NULL;
  }
}


void
pnl_design_add_history (pnl_design pdesign, char *str)
{
  nl_design design = pdesign->nl_rep;
  mem_group group = nl_design_mem_group (design);
  char *dup  = GSTRDUP (str, group);

  if ( pdesign->history == NULL ) {
    pdesign->history = ar_alloc (4, sizeof (char *));
  }

  ar_add (pdesign->history, &dup);
}


pnl_icell
pnl_idesign_get_icell (pnl_idesign pidesign, nl_icell icell)
{
  pnl_icell picell;

  nl_icell_attr_get (pidesign->icell_attr, icell, &picell);

  if ( picell == NULL ) {
    picell = pnl_icell_create (icell);
  }

  return picell;
}


pnl_cell
pnl_design_get_cell (pnl_design pdesign, nl_cell cell)
{
  pnl_cell pcell;

  nl_cell_attr_get (pdesign->cell_attr, cell, &pcell);

  if ( pcell == NULL ) {
    pcell = pnl_cell_create (cell);
  }

  return pcell;
}


pnl_inet
pnl_idesign_get_inet (pnl_idesign pidesign, nl_inet inet)
{
  pnl_inet pinet;

  nl_inet_attr_get (pidesign->inet_attr, inet, &pinet);

  return pinet;
}


pnl_net
pnl_design_get_net (pnl_design pdesign, nl_net net)
{
  pnl_net pnet;

  nl_net_attr_get (pdesign->net_attr, net, &pnet);

  return pnet;
}


pnl_port
pnl_design_get_port (pnl_design pdesign, nl_port port)
{
  pnl_port pport;

  nl_port_attr_get (pdesign->port_attr, port, &pport);

  return pport;
}


void
pnl_design_set_location_rep (pnl_design pdesign, pnl_location_rep rep)
{
  pdesign->location_rep = rep;
}
