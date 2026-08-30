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
#include "str.h"
#include "stdpccts.h"


static nl_context  vim2nl_context;
static nl_design   vim2nl_current_design;
static nl_idesign  vim2nl_current_idesign;
static pnl_design  vim2nl_current_pdesign;
static pnl_idesign vim2nl_current_pidesign;
static char *      vim2nl_current_design_name;
static int	   vim2nl_gridx;
static int	   vim2nl_gridy;
static int	   vim2nl_gridded;
static char *	   vim2nl_core_site_name;


void
vim_zzsyn (char *text, int tok, char *egroup, SetWordType *eset,
	   int etok, int k, char *bad_text)
{
  error ("line %d: syntax error at '%s'", zzline, bad_text);
}


static
void
vim2nl_zzerr (const char *text)
{
  error ("line %d: %s at '%s'", zzline, text, zzlextext);
}


void
vim2nl_design (char *name)
{
  char *tmp_name = str_append ("vim2nl ", name, NULL);

  vim2nl_current_design_name = STRDUP (name);

  vim2nl_current_design = nl_design_create (tmp_name, vim2nl_context);

  nl_net_create ("1'b0", nl_wireclass_wire, vim2nl_current_design);
  nl_net_create ("1'b1", nl_wireclass_wire, vim2nl_current_design);

  FREE (tmp_name);
}


void
vim2nl_place_design (char *name)
{
  nl_design design = nl_context_get_design_by_name (vim2nl_context, name);
  nl_idesign idesign;
  pnl_design pdesign = NULL;
  pnl_idesign pidesign = NULL;

  if ( design == NULL ) {
    error ("cannot find a design in memory named '%s'", name);
  }

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  if ( pdesign == NULL ) {
    pdesign = pnl_design_create (design);
  }

  idesign = nl_idesign_get_or_create (design, NULL);

  nl_idesign_attr_get_by_name ("pnl idesign", idesign, &pidesign);

  if ( pidesign == NULL ) {
    pidesign = pnl_idesign_create (idesign);
  }

  vim2nl_current_design = design;
  vim2nl_current_idesign = idesign;
  vim2nl_current_pdesign = pdesign;
  vim2nl_current_pidesign = pidesign;
}


void
vim2nl_distance_units (void)
{
  pnl_design_set_distance_units (vim2nl_current_pdesign, "MICRONS", 1000);
}


void
vim2nl_net (char *name)
{
  nl_net_create (name, nl_wireclass_wire, vim2nl_current_design);
}


nl_cell
vim2nl_cell (char *name, nl_reference ref)
{
  nl_cell result = nl_cell_create (name, ref);

  return result;
}


void
vim2nl_port (char *name, nl_direction dir, nl_net net)
{
  nl_port port = nl_port_create (name, vim2nl_current_design, dir);

  nl_port_connect_net (port, net);
}


nl_pin
vim2nl_pin (nl_cell cell, char *name, nl_direction dir)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_refpin refpin = (nl_refpin) nl_reference_get_refpin_by_name (reference, name);
  nl_pin result;

  if ( refpin == NULL ) {
    refpin = nl_refpin_create (name, NULL, reference);
    nl_refpin_set_direction (refpin, dir);
  }

  ASSERT (nl_refpin_kind (refpin) == nl_kind_refpin);

  result = nl_cell_get_pin_by_refpin (cell, refpin);

  return result;
}


void
vim2nl_connect (nl_pin pin, nl_net net)
{
  nl_pin_connect_net (pin, net);
}


nl_net
vim2nl_get_net (char *name)
{
  nl_net result = nl_design_get_net_by_name (vim2nl_current_design, name);

  if ( result == NULL ) {
    if ( strcmp (name, "VDD") == 0 ) {
      result = nl_design_get_net_by_name (vim2nl_current_design, "1'b1");
    }
    else if ( strcmp (name, "GND") == 0 ) {
      result = nl_design_get_net_by_name (vim2nl_current_design, "1'b0");
    }
  }

  if ( result == NULL ) {
    error ("line %d: cannot find net named '%s'", zzline, name);
  }

  return result;
}


nl_reference
vim2nl_get_ref (char *name)
{
  nl_reference result = nl_design_get_reference_by_name (vim2nl_current_design, name);

  if ( result == NULL ) {
    result = nl_reference_create (name, vim2nl_current_design, NULL);
  }

  return result;
}


nl_cell
vim2nl_get_cell (char *name)
{
  nl_cell result = nl_design_get_cell_by_name (vim2nl_current_design, name);

  if ( result == NULL ) {
    error ("line %d: cannot find a cell named '%s'", zzline, name);
  }

  return result;
}


nl_port
vim2nl_get_port (char *name)
{
  nl_object result = nl_design_get_port_by_name (vim2nl_current_design, name);

  if ( result == NULL ) {
    error ("line %d: cannot find a port named '%s'", zzline, name);
  }
  else if ( nl_object_kind (result) != nl_kind_port ) {
    error ("line %d: '%s' does not refer to a unique port "
	   "(like maybe it's a bus)", zzline, name);
  }

  return (nl_port) result;
}


nl_direction
vim2nl_direction (char *c)
{
  if ( c[1] == 0 ) {
    switch (c[0]) {
    case 'I': return nl_direction_in;
    case 'O': return nl_direction_out;
    case 'B': return nl_direction_inout;
    }
  }

  error ("unrecognized direction (%s), on line %d", c, zzline);
}


pnl_orientation
vim2nl_orientation (int flipped, int rotation)
{
  switch (rotation) {
  case 0:
    if ( flipped )
      return pnl_orientation_FS;
    else
      return pnl_orientation_N;
  case 90:
    if ( flipped )
      return pnl_orientation_FW;
    else
      return pnl_orientation_E;
  case 180:
    if ( flipped )
      return pnl_orientation_FN;
    else
      return pnl_orientation_S;
  case 270:
    if ( flipped )
      return pnl_orientation_FE;
    else
      return pnl_orientation_W;
  default:
    error ("line %d: invalid rotation (%d)", zzline, rotation);
  }
}


void
vim2nl_check_reference (nl_cell cell, char *type_string)
{
  nl_reference reference = nl_cell_reference (cell);
  char *ref_name = nl_reference_name (reference);
  char *type_name = STRDUPA (type_string + 1);
  char *t;

  if ( *type_name == '\'' ) {
    type_name++;
  }

  t = type_name;

  while ( *t != '\'' && *t != 0 ) {
    t++;
  }

  if ( *t == '\'' ) {
    *t = 0;
  }

  if ( strcmp (ref_name, type_name) != 0 ) {
    error ("line %d: cell type in VIM file (%s), "
	   "does not match actual reference name (%s)",
	   type_name, ref_name);
  }
}


void
vim2nl_place_cell (nl_cell cell, int x, int y, pnl_orientation orientation)
{
  nl_icell icell = nl_idesign_get_icell (vim2nl_current_idesign, cell);
  pnl_icell picell = pnl_idesign_get_icell (vim2nl_current_pidesign, icell);

  pnl_icell_set_location (picell, 1, x, y);
  pnl_icell_set_orientation (picell, orientation);
  pnl_icell_set_loctype (picell, pnl_loctype_PLACED);
}


void
vim2nl_place_attribute (nl_cell cell, char *attr)
{
  if ( strcmp (attr, "MOVETYPE=FIXED") == 0 ) {
    nl_icell icell = nl_idesign_get_icell (vim2nl_current_idesign, cell);
    pnl_icell picell = pnl_idesign_get_icell (vim2nl_current_pidesign, icell);

    pnl_icell_set_loctype (picell, pnl_loctype_FIXED);
  }
}


void
vim2nl_place_port (nl_port port, char *layer,
		   int x, int y, int xsize, int ysize)
{
  pnl_port pport = pnl_design_get_port (vim2nl_current_pdesign, port);
  int x_mid = x + xsize / 2;
  int y_mid = y + ysize / 2;
  int x0 = x - x_mid;
  int y0 = y - y_mid;
  int x1 = x + xsize - x_mid;
  int y1 = y + xsize - y_mid;
  char *real_layer = STRDUPA (layer);
  int len = strlen (real_layer);
  int i;

  /* If the layer name ends in "PIN", chop that part off. */
  if ( strcmp (real_layer + len - 3 - 1, "PIN") == 0 ) {
    real_layer[len - 3 - 1] = 0;
  }
  
  pnl_port_set_location (pport, x_mid, y_mid);
  pnl_port_set_orientation (pport, pnl_orientation_N);
  pnl_port_set_loctype (pport, pnl_loctype_PLACED);
  pnl_port_set_geometry (pport, real_layer, x0, y0, x1, y1);
}


void
vim2nl_outline (char *layer, int x0, int y0, int xsize, int ysize)
{
  int x1 = x0 + xsize;
  int y1 = y0 + ysize;

  pnl_design_set_die_area (vim2nl_current_pdesign, x0, y0, x1, y1);
}


void
vim2nl_scale (char *scale)
{
  if ( strcmp (scale, "GRIDLESS") == 0 ) {
    vim2nl_gridded = 0;
  }
  else if ( strcmp (scale, "GRIDDED") == 0 ) {
    vim2nl_gridded = 1;
  }
  else {
    error ("unrecognized SCALE, %s, should be either GRIDLESS or GRIDDED", scale);
  }
}


int
vim2nl_coordinate (char *s, char xy)
{
  int result;

  if ( vim2nl_gridded ) {
    int x = str_parse_number (s, 0);

    if ( xy == 'x' ) {
      result = x * vim2nl_gridx;
    }
    else {
      result = x * vim2nl_gridy;
    }
  }
  else {
    result = str_parse_number (s, 3);
  }

  return result;
}


void
vim2nl_row (char *name, int x0, int y0, int xsize, int ysize)
{
  int step = vim2nl_gridx;
  int count = xsize / step;
  int die_x0, die_y0, die_x1, die_y1;
  int y_offset;
  int row_num = 0;
  pnl_orientation row_orientation;

  pnl_design_get_die_area (vim2nl_current_pdesign,
			   &die_x0, &die_y0, &die_x1, &die_y1);

  if ( ysize > 0 ) {
    y_offset = y0 - die_y0;
    row_num = y_offset / ysize;
  }

  if ( row_num % 2 == 0 ) {
    row_orientation = pnl_orientation_N;
  }
  else {
    row_orientation = pnl_orientation_S;
  }

  pnl_design_add_row_site (vim2nl_current_pdesign, name, vim2nl_core_site_name,
			   x0, y0, row_orientation, count, step, ysize);
}


nl_design
vim2nl_read_vim_tech (nl_context context, FILE *ifp)
{
  vim2nl_context = context;

  vim_zzerr = vim2nl_zzerr;

  error_unwind_protect {
    ANTLR (vim_tech_file (), ifp);
  }
  error_on_error {
    if ( vim2nl_current_design != NULL ) {
      nl_design_free (vim2nl_current_design);
      vim2nl_current_design = NULL;
      vim2nl_context = NULL;
    }
  }
  error_end;

  if ( vim2nl_current_design != NULL ) {
    nl_design existing_design
      = nl_context_get_design_by_name (vim2nl_context, vim2nl_current_design_name);

    if ( existing_design != NULL ) {
      fprintf (stderr, "Overwriting design \"%s\"\n", vim2nl_current_design_name);
      nl_context_remove_design (vim2nl_context, existing_design);
    }

    nl_design_rename (vim2nl_current_design, vim2nl_current_design_name);
  }

  return vim2nl_current_design;
}


void
vim2nl_read_vim_placement (nl_context context, int gridx, int gridy, FILE *ifp)
{
  vim2nl_context = context;

  vim2nl_gridx = gridx;
  vim2nl_gridy = gridy;
  vim2nl_gridded = 0;

  vim_zzerr = vim2nl_zzerr;

  error_unwind_protect {
    ANTLR (vim_place_file (), ifp);
  }
  error_on_error {
    vim2nl_current_design = NULL;
    vim2nl_context = NULL;
  }
  error_end;
}


void
vim2nl_read_vim_physcell (nl_context context, int gridx, int gridy, FILE *ifp,
			  char *core_site_name)
{
  vim2nl_context = context;

  vim2nl_gridx = gridx;
  vim2nl_gridy = gridy;
  vim2nl_gridded = 0;
  vim2nl_core_site_name = core_site_name;

  vim_zzerr = vim2nl_zzerr;

  error_unwind_protect {
    ANTLR (vim_physcell_file (), ifp);
  }
  error_on_error {
    vim2nl_current_design = NULL;
    vim2nl_context = NULL;
  }
  error_end;
}
