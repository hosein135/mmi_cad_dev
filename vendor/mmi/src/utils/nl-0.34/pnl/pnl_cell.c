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


pnl_cell_data
pnl_cell_data_create (nl_kind kind)
{
  pnl_cell_data result = MALLOC (sizeof (*result));

  result->kind = kind;
  result->x.origin = 0;
  result->x.x = 0;
  result->y.valid = 0;
  result->y.y = 0;
  result->orientation = pnl_orientation_none;
  result->loctype = pnl_loctype_null;

  return result;
}


void
pnl_cell_data_free (pnl_cell_data data)
{
  FREE (data);
}


pnl_icell
pnl_icell_create (nl_icell icell)
{
  pnl_cell_data data = pnl_cell_data_create (pnl_kind_icell);
  pnl_icell result = (pnl_icell) data;

  result->nl_rep = icell;

  return result;
}


pnl_cell
pnl_cell_create (nl_cell cell)
{
  pnl_cell_data data = pnl_cell_data_create (pnl_kind_cell);
  pnl_cell result = (pnl_cell) data;

  result->nl_rep = cell;

  return result;
}
     

char *
pnl_icell_name (pnl_icell picell)
{
  nl_icell icell = picell->nl_rep;
  char *name = nl_icell_name (icell);

  return name;
}


char *
pnl_cell_name (pnl_cell pcell)
{
  nl_cell cell = pcell->nl_rep;
  char *name = nl_cell_name (cell);

  return name;
}


pnl_idesign
pnl_icell_pidesign (pnl_icell picell)
{
  nl_icell icell = picell->nl_rep;
  nl_idesign idesign = nl_icell_root_idesign (icell);
  pnl_idesign pidesign = NULL;

  nl_idesign_attr_get_by_name ("pnl design", idesign, &pidesign);

  return pidesign;
}


void
pnl_icell_free (pnl_icell picell)
{
  pnl_cell_data_free ((pnl_cell_data) picell);
}


void
pnl_cell_free (pnl_cell pcell)
{
  pnl_cell_data_free ((pnl_cell_data) pcell);
}


void
pnl_icell_set_loctype (pnl_icell picell, pnl_loctype loctype)
{
  picell->loctype = loctype;
}

  
void
pnl_cell_set_loctype (pnl_cell pcell, pnl_loctype loctype)
{
  pcell->loctype = loctype;
}


static
pnl_bbox
pnl_get_bbox_for_cell (nl_cell cell)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_object down_obj = nl_reference_down_design (reference);
  nl_kind down_kind;
  pnl_bbox bbox;

  if ( down_obj == NULL ) {
    error ("attempt to get the bounding box for an unlinked cell, %s",
	   nl_cell_name (cell));
  }

  down_kind = nl_object_kind (down_obj);

  if ( down_kind == nl_kind_design ) {
    nl_design down_design = (nl_design) down_obj;
    pnl_design pdesign = pnl_get_pdesign_for_design (down_design);

    bbox = pnl_design_die_area (pdesign);
  }
  else if ( down_kind == nl_kind_libcell ) {
    nl_libcell libcell = (nl_libcell) down_obj;
    pnl_libcell plibcell = pnl_get_plibcell_for_libcell (libcell);

    bbox = pnl_libcell_bbox (plibcell);
  }
  else {
    ASSERT (0);
  }

  return bbox;
}


pnl_bbox
pnl_icell_get_bbox (pnl_icell picell)
{
  nl_icell icell = picell->nl_rep;
  nl_cell cell = nl_icell_cell (icell);
  pnl_bbox result = pnl_get_bbox_for_cell (cell);

  return result;
}

  
pnl_bbox
pnl_cell_get_bbox (pnl_cell pcell)
{
  nl_cell cell = pcell->nl_rep;
  pnl_bbox result = pnl_get_bbox_for_cell (cell);

  return result;
}

  
void
pnl_icell_set_location (pnl_icell picell, int origin, int x, int y)
{
  pnl_cellx cx;
  pnl_celly cy;

  cx.origin = origin;
  cx.x = x;
  cy.valid = 1;
  cy.y = y;

  picell->x = cx;
  picell->y = cy;
}


void
pnl_cell_set_location (pnl_cell pcell, int origin, int x, int y)
{
  pnl_cellx cx;
  pnl_celly cy;

  cx.origin = origin;
  cx.x = x;
  cy.valid = 1;
  cy.y = y;

  pcell->x = cx;
  pcell->y = cy;
}


static
void
pnl_get_translated_cell_location (nl_cell cell, int cell_x, int cell_y,
				  pnl_orientation cell_orientation,
				  int origin, int *tx_p, int *ty_p)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_object down_object = nl_reference_down_design (reference);
  nl_kind kind;
  int xmin, ymin;
  int xmax, ymax;

  if ( cell_orientation == pnl_orientation_null ||
       cell_orientation == pnl_orientation_none ) {
    error ("attempt to apply cell location transformation to cell with no "
	   "orientation %s", nl_cell_name (cell));
  }

  if ( down_object == NULL ) {
    error ("attempt to apply cell location transformation to unlinked cell %s",
	   nl_cell_name (cell));
  }

  kind = nl_object_kind (down_object);

  if ( kind == nl_kind_design ) {
    nl_design down_design = (nl_design) down_object;
    pnl_design pdesign = pnl_get_pdesign_for_design (down_design);

    pnl_design_get_die_area (pdesign, &xmin, &ymin, &xmax, &ymax);
  }
  else if ( kind == nl_kind_libcell ) {
    nl_libcell libcell = (nl_libcell) down_object;
    pnl_libcell plibcell = pnl_get_plibcell_for_libcell (libcell);
    pnl_libcell_get_bounding_box (plibcell, &xmin, &ymin, &xmax, &ymax);
  }
  else {
    ASSERT (0);
  }

  {
    /* (xoff, yoff) will be the location of the cell origin relative
       to the lower-left corner */
    int xoff;
    int yoff;

    pnl_translate_coordinates (cell_orientation, 0, 0, xmin, ymin, xmax, ymax,
			       &xoff, &yoff);

    if ( origin ) {
      /* If we're looking for the origin, (cell_x, cell_y) must be the
	 lower-left corner (otherwise this routine would not have been
	 called). */
      *tx_p = cell_x + xoff;
      *ty_p = cell_y + yoff;
    }
    else {
      /* If we're looking for the lower-left corner, (cell_x, cell_y)
	 must be the origin (otherwise this routine would not have
	 been called). */
      *tx_p = cell_x - xoff;
      *ty_p = cell_y - yoff;
    }
  }
}


int
pnl_icell_has_location (pnl_icell picell)
{
  return picell->y.valid;
}


int
pnl_cell_has_location (pnl_cell pcell)
{
  return pcell->y.valid;
}


void
pnl_icell_get_location (pnl_icell picell, int origin, int *x_p, int *y_p)
{
  pnl_cellx cx = picell->x;
  pnl_celly cy = picell->y;

  if ( cy.valid == 0 ) {
    error ("attempt to get the location of a cell before it has been set");
  }

  ASSERT (origin == (origin & 0x1));

  if ( origin == cx.origin ) {
    *x_p = cx.x;
    *y_p = cy.y;
  }
  else {
    /* Need to adjust the coordinates. */
    nl_icell icell = picell->nl_rep;
    nl_cell cell = nl_icell_cell (icell);

    pnl_get_translated_cell_location (cell, cx.x, cy.y, picell->orientation,
				      origin, x_p, y_p);
  }
}


void
pnl_cell_get_location (pnl_cell pcell, int origin, int *x_p, int *y_p)
{
  pnl_cellx cx = pcell->x;
  pnl_celly cy = pcell->y;

  if ( cy.valid == 0 ) {
    error ("attempt to get the location of a cell before it has been set");
  }

  ASSERT (origin == (origin & 0x1));

  if ( origin == cx.origin ) {
    *x_p = cx.x;
    *y_p = cy.y;
  }
  else {
    /* Need to adjust the coordinates. */
    nl_cell cell = pcell->nl_rep;

    pnl_get_translated_cell_location (cell, cx.x, cy.y, pcell->orientation,
				      origin, x_p, y_p);
  }
}


void
pnl_icell_set_orientation (pnl_icell picell, pnl_orientation orientation)
{
  picell->orientation = orientation;
}


void
pnl_cell_set_orientation (pnl_cell pcell, pnl_orientation orientation)
{
  pcell->orientation = orientation;
}


static
void
pnl_get_pin_location (int cell_x, int cell_y, int origin,
		      pnl_orientation cell_orientation, nl_pin pin,
		      int *x_p, int *y_p)
{
  nl_refpin refpin = nl_pin_refpin (pin);
  nl_object down_port = nl_refpin_down_port (refpin);

  if ( down_port == NULL ) {
    error ("Attempt to get pin location for unlinked cell, %s",
	   nl_cell_name ((nl_cell) nl_pin_owner (pin)));
  }
  else {
    nl_kind down_kind = nl_object_kind (down_port);
    int pin_x, pin_y;
    int xmin, ymin;
    int xmax, ymax;

    if ( down_kind == nl_kind_port ) {
      nl_port port = (nl_port) down_port;
      nl_design design = nl_port_design (port);
      pnl_design pdesign = NULL;
      pnl_port pport;

      nl_design_attr_get_by_name ("pnl design", design, &pdesign);

      ASSERT (pdesign != NULL);

      pport = pnl_design_get_port (pdesign, port);

      pnl_port_get_location (pport, &pin_x, &pin_y);

      if ( origin ) {
	xmin = ymin = xmax = ymax = 0;
      }
      else {
	pnl_design_get_die_area (pdesign, &xmin, &ymin, &xmax, &ymax);
      }
    }
    else if ( down_kind == nl_kind_libpin ) {
      nl_libpin libpin = (nl_libpin) down_port;
      nl_libcell libcell = nl_libpin_libcell (libpin);
      nl_library library = nl_libcell_library (libcell);
      pnl_library plibrary = NULL;
      pnl_libcell plibcell;
      pnl_libpin plibpin;

      ASSERT (nl_libpin_kind (libpin) == nl_kind_libpin);

      nl_library_attr_get_by_name ("pnl library", library, &plibrary);

      ASSERT (plibrary != NULL);

      plibpin = pnl_library_get_libpin (plibrary, libpin);
      plibcell = pnl_libpin_libcell (plibpin);

      pin_x = pnl_libpin_x (plibpin);
      pin_y = pnl_libpin_y (plibpin);

      xmin = 0;
      ymin = 0;

      if ( origin ) {
	xmax = 0;
	ymax = 0;
      }
      else {
	xmax = pnl_libcell_sizex (plibcell);
	ymax = pnl_libcell_sizey (plibcell);
      }
    }
    else {
      ASSERT (0);
    }

    {
      int xoff;
      int yoff;

      pnl_translate_coordinates (cell_orientation, pin_x, pin_y,
				 xmin, ymin, xmax, ymax, &xoff, &yoff);

      *x_p = cell_x + xoff;
      *y_p = cell_y + yoff;
    }
  }
}


void
pnl_icell_get_pin_location (pnl_icell picell, nl_pin pin, int *x_p, int *y_p)
{
  pnl_cellx cx = picell->x;
  pnl_celly cy = picell->y;
  int origin = cx.origin;
  int cell_x = cx.x;
  int cell_y = cy.y;
  pnl_orientation cell_orientation = picell->orientation;

  if ( cy.valid == 0 ) {
    error ("attempt to get the location of a pin of a cell for which no "
	   "location has been set");
  }

  pnl_get_pin_location (cell_x, cell_y, origin, cell_orientation, pin,
			x_p, y_p);
}


void
pnl_cell_get_pin_location (pnl_cell pcell, nl_pin pin, int *x_p, int *y_p)
{
  pnl_cellx cx = pcell->x;
  pnl_celly cy = pcell->y;
  int origin = cx.origin;
  int cell_x = cx.x;
  int cell_y = cy.y;
  pnl_orientation cell_orientation = pcell->orientation;

  if ( cy.valid == 0 ) {
    error ("attempt to get the location of a pin of a cell for which no "
	   "location has been set");
  }

  ASSERT (pcell->nl_rep == (nl_cell) nl_pin_owner (pin));

  pnl_get_pin_location (cell_x, cell_y, origin, cell_orientation, pin,
			x_p, y_p);
}
