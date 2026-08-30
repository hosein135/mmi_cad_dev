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
pnl_library_free_library_attr (void *ptr)
{
  pnl_library *library_p = (pnl_library *)ptr;

  if ( *library_p != NULL ) {
    pnl_library_free (*library_p);
  }
}


static
void
pnl_library_free_libcell_attr (void *ptr)
{
  pnl_libcell *libcell_p = (pnl_libcell *)ptr;

  if ( *libcell_p != NULL ) {
    pnl_libcell_free (*libcell_p);
  }
}


static
void
pnl_library_free_libpin_attr (void *ptr)
{
  pnl_libpin *libpin_p = (pnl_libpin *)ptr;

  if ( *libpin_p != NULL ) {
    pnl_libpin_free (*libpin_p);
  }
}


static
void
pnl_library_add_libcell (pnl_library plibrary, pnl_libcell plibcell)
{
  nl_libcell libcell = plibcell->nl_rep;
  nl_libcell_attr_set (plibrary->libcell_attr, libcell, &plibcell);
}


pnl_libcell
pnl_library_get_libcell (pnl_library plibrary, nl_libcell libcell)
{
  pnl_libcell plibcell;

  nl_libcell_attr_get (plibrary->libcell_attr, libcell, &plibcell);

  return plibcell;
}


pnl_libpin
pnl_library_get_libpin (pnl_library plibrary, nl_libpin libpin)
{
  pnl_libpin plibpin;

  nl_libpin_attr_get (plibrary->libpin_attr, libpin, &plibpin);

  return plibpin;
}


static
void
pnl_library_add_libpin (pnl_library plibrary, pnl_libpin plibpin)
{
  nl_libpin libpin = plibpin->nl_rep;
  nl_libpin_attr_set (plibrary->libpin_attr, libpin, &plibpin);
}


pnl_library
pnl_library_create (nl_library library)
{
  mem_group group = nl_library_mem_group (library);
  pnl_library result = GMALLOC (sizeof (*result), group);

  result->kind = pnl_kind_library;
  result->nl_rep = library;

  result->library_attr
    = nl_library_attr_create ("pnl library", library, nl_density_dense,
			      sizeof (pnl_library), NULL,
			      pnl_library_free_library_attr);
  result->libcell_attr
    = nl_libcell_attr_create (NULL, library, nl_density_dense,
			      sizeof (pnl_libcell), NULL,
			      pnl_library_free_libcell_attr);
  result->libpin_attr
    = nl_libpin_attr_create (NULL, library, nl_density_dense,
			     sizeof (pnl_libpin), NULL,
			     pnl_library_free_libpin_attr);
  
  nl_library_attr_set (result->library_attr, library, &result);
  
  nl_library_for_all_libcells (library, libcell) {
    pnl_libcell plibcell = pnl_libcell_create (libcell, result);

    nl_libcell_for_all_libpins (libcell, libpin) {
      pnl_libpin_create (libpin, plibcell);
    } nl_end_for;
  } nl_end_for;
    
  return result;
}


void
pnl_library_free (pnl_library plibrary)
{
  nl_library_remove_attr (plibrary->nl_rep, (nl_attr) plibrary->library_attr);
  nl_library_remove_attr (plibrary->nl_rep, (nl_attr) plibrary->libcell_attr);
  nl_library_remove_attr (plibrary->nl_rep, (nl_attr) plibrary->libpin_attr);

  FREE (plibrary);
}


pnl_libcell
pnl_libcell_create (nl_libcell libcell, pnl_library plibrary)
{
  nl_library library = nl_libcell_library (libcell);
  mem_group group = nl_library_mem_group (library);
  pnl_libcell result = GMALLOC (sizeof (*result), group);

  result->kind = pnl_kind_libcell;
  result->nl_rep = libcell;

  result->library = plibrary;
  result->class = pnl_cellclass_null;
  result->bbox = NULL;
  result->symmetry = 0;
  result->site = NULL;
  result->obstructions = NULL;

  pnl_library_add_libcell (plibrary, result);

  return result;
}


void
pnl_libcell_free (pnl_libcell plibcell)
{
  if ( plibcell->site != NULL ) 
    FREE (plibcell->site);

  if ( plibcell->obstructions ) {
    ar_for_all (plibcell->obstructions, pnl_geometry, geom) {
      pnl_geometry_free (geom);
    } ar_end_for;
  }
  
  FREE (plibcell);
}


void
pnl_libcell_add_symmetry (pnl_libcell plibcell, pnl_symmetry symmetry)
{
  switch ( symmetry ) {
  case pnl_symmetry_X:
    plibcell->symmetry |= (1 << 0);
    break;
  case pnl_symmetry_Y:
    plibcell->symmetry |= (1 << 1);
    break;
  case pnl_symmetry_R90:
    plibcell->symmetry |= (1 << 2);
    break;
  default:
    ASSERT (0);
  }
}


int
pnl_libcell_get_symmetry (pnl_libcell plibcell, pnl_symmetry symmetry)
{
  switch ( symmetry ) {
  case pnl_symmetry_X:
    return (plibcell->symmetry & (1 << 0)) != 0;
  case pnl_symmetry_Y:
    return (plibcell->symmetry & (1 << 1)) != 0;
  case pnl_symmetry_R90:
    return (plibcell->symmetry & (1 << 2)) != 0;
  default:
    ASSERT (0);
  }
}


pnl_libpin
pnl_libpin_create (nl_libpin libpin, pnl_libcell plibcell)
{
  nl_libcell libcell = nl_libpin_libcell (libpin);
  nl_library library = nl_libcell_library (libcell);
  pnl_library plibrary = plibcell->library;
  mem_group group = nl_library_mem_group (library);
  pnl_libpin result = GMALLOC (sizeof (*result), group);

  result->kind = pnl_kind_libpin;
  result->nl_rep = libpin;
  result->libcell = plibcell;
  result->use = pnl_use_null;
  result->shape = pnl_shape_null;
  result->ports = NULL;
  result->antennadiffarea = 0;
  result->antennagatearea = 0;
  result->port_area = 0;
  result->x = 0;
  result->y = 0;

  pnl_library_add_libpin (plibrary, result);

  return result;
}


void
pnl_libpin_free (pnl_libpin plibpin)
{
  if ( plibpin->ports != NULL ) {
    ar_for_all (plibpin->ports, pnl_geometry, geom) {
      pnl_geometry_free (geom);
    } ar_end_for;
  }
  
  FREE (plibpin);
}


void
pnl_libcell_set_class (pnl_libcell plibcell, pnl_cellclass class)
{
  plibcell->class = class;
}


void
pnl_libcell_set_size (pnl_libcell plibcell, int x, int y)
{
  pnl_bbox bbox = plibcell->bbox;

  if ( bbox == NULL ) {
    pnl_library plibrary = plibcell->library;
    nl_library library = plibrary->nl_rep;
    mem_group group = nl_library_mem_group (library);

    bbox = GMALLOC (sizeof (*bbox), group);
    plibcell->bbox = bbox;

    bbox->x0 = 0;
    bbox->y0 = 0;
  }

  bbox->x1 = x + bbox->x0;
  bbox->y1 = y + bbox->y0;
}


void
pnl_libcell_set_origin (pnl_libcell plibcell, int x, int y)
{
  pnl_bbox bbox = plibcell->bbox;

  if ( bbox == NULL ) {
    pnl_library plibrary = plibcell->library;
    nl_library library = plibrary->nl_rep;
    mem_group group = nl_library_mem_group (library);

    bbox = GMALLOC (sizeof (*bbox), group);
    plibcell->bbox = bbox;

    bbox->x0 = 0;
    bbox->y0 = 0;
    bbox->x1 = 0;
    bbox->y1 = 0;
  }

  bbox->x0 -= x;
  bbox->y0 -= y;
  bbox->x1 -= x;
  bbox->y1 -= y;
}


void
pnl_libcell_set_site (pnl_libcell plibcell, char *site)
{
  pnl_library plibrary = plibcell->library;
  nl_library library = plibrary->nl_rep;
  mem_group group = nl_library_mem_group (library);

  if ( plibcell->site != NULL ) {
    FREE (plibcell->site);
  }

  plibcell->site = GSTRDUP (site, group);
}


void
pnl_libcell_add_obs_geometry (pnl_libcell plibcell, pnl_geometry g)
{
  if ( plibcell->obstructions == NULL ) {
    plibcell->obstructions = ar_alloc (1, sizeof (pnl_geometry));
  }

  ar_add (plibcell->obstructions, &g);
}


char *
pnl_libcell_name (pnl_libcell plibcell)
{
  nl_libcell libcell = plibcell->nl_rep;
  char *name = nl_libcell_name (libcell);

  return name;
}


char *
pnl_libpin_name (pnl_libpin plibpin)
{
  nl_libpin libpin = plibpin->nl_rep;
  char *name = nl_libpin_name (libpin);

  return name;
}


int
pnl_libpin_set_or_check_use (pnl_libpin plibpin, nl_use use)
{
  nl_libpin libpin = plibpin->nl_rep;
  nl_use existing = nl_libpin_use (libpin);

  if ( existing == nl_use_null ) {
    nl_libpin_set_use (libpin, use);
  }
  else if ( existing != use ) {
    return 0;
  }

  return 1;
}


void
pnl_libpin_set_shape (pnl_libpin plibpin, pnl_shape shape)
{
  plibpin->shape = shape;
}


int
pnl_libpin_set_or_check_direction (pnl_libpin plibpin, nl_direction direction)
{
  nl_libpin libpin = plibpin->nl_rep;
  nl_direction existing = nl_libpin_direction (libpin);

  if ( existing == nl_direction_null ) {
    nl_libpin_set_direction (libpin, direction);
  }
  else if ( existing != direction ) {
    return 0;
  }

  return 1;
}


void
pnl_libpin_add_port_geometry (pnl_libpin plibpin, pnl_geometry geometry)
{
  if ( plibpin->ports == NULL ) {
    plibpin->ports = ar_alloc (1, sizeof (pnl_geometry));
  }

  ar_add (plibpin->ports, &geometry);
}


void
pnl_libpin_set_location (pnl_libpin plibpin, int x, int y)
{
  plibpin->x = x;
  plibpin->y = y;
}


void
pnl_libpin_compute_location (pnl_libpin plibpin)
{
  double total_area = 0;
  double tx = 0;
  double ty = 0;

  if ( plibpin->ports != NULL ) {
    ar_for_all (plibpin->ports, pnl_geometry, geometry) {
      pnl_geometryclass class = pnl_geometry_class (geometry);

      if ( class == pnl_geometryclass_layer ) {
	int x, y;
	double area;

	pnl_layer_geometry_get_center (geometry, &x, &y, &area);

	tx += x * area;
	ty += y * area;

	total_area += area;
      }
    } ar_end_for;
  
    plibpin->x = tx / total_area;
    plibpin->y = ty / total_area;
  }
}


void
pnl_libpin_set_antennadiffarea (pnl_libpin plibpin, int area)
{
  plibpin->antennadiffarea = area;
}


void
pnl_libpin_set_antennagatearea (pnl_libpin plibpin, int area)
{
  plibpin->antennagatearea = area;
}


void
pnl_libpin_set_capacitance (pnl_libpin plibpin, float cap)
{
  nl_libpin libpin = plibpin->nl_rep;

  nl_libpin_set_capacitance (libpin, cap);
}


int
pnl_libcell_sizex (pnl_libcell plibcell)
{
  pnl_bbox bbox = plibcell->bbox;
  int sizex;

  if ( bbox == NULL ) {
    error ("attempt to get the x size of a libcell with no bbox");
  }

  sizex = pnl_bbox_x1 (bbox) - pnl_bbox_x0 (bbox);

  return sizex;
}


int
pnl_libcell_sizey (pnl_libcell plibcell)
{
  pnl_bbox bbox = plibcell->bbox;
  int sizey;

  if ( bbox == NULL ) {
    error ("attempt to get the y size of a libcell with no bbox");
  }

  sizey = pnl_bbox_y1 (bbox) - pnl_bbox_y0 (bbox);

  return sizey;
}


void
pnl_libcell_get_bounding_box (pnl_libcell plibcell,
			      int *xmin_p, int *ymin_p,
			      int *xmax_p, int *ymax_p)
{
  pnl_bbox bbox = plibcell->bbox;

  if ( bbox == NULL ) {
    error ("attempt to get the bounding box of a libcell before it has been set");
  }

  *xmin_p = pnl_bbox_x0 (bbox);
  *ymin_p = pnl_bbox_y0 (bbox);
  *xmax_p = pnl_bbox_x1 (bbox);
  *ymax_p = pnl_bbox_y1 (bbox);
}
