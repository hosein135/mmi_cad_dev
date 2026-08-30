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
#include "str.h"
#include "skip-list.h"
#include "unparse.h"
#include "nl.h"
#include "pnl.h"
#include "pnl2def.h"


static
void
pnl2def_write_direction (unparse_fp ufp, nl_direction direction)
{
  if ( direction == nl_direction_null || direction == nl_direction_unknown ) {
    return;
  }

  unparse_token (ufp, "+", 1);
  unparse_token (ufp, "DIRECTION", 1);
  
  switch ( direction ) {
  case nl_direction_in:
    unparse_token (ufp, "INPUT", 1);
    break;
  case nl_direction_out:
    unparse_token (ufp, "OUTPUT", 1);
    break;
  case nl_direction_inout:
    unparse_token (ufp, "INOUT", 1);
    break;
  default:
    ASSERT (0);
  }
}


static
void
pnl2def_write_location (unparse_fp ufp, pnl_loctype loctype, int x, int y,
			pnl_orientation orientation)
{
  switch ( loctype ) {
  case pnl_loctype_PLACED:
    unparse_token (ufp, "+", 1);
    unparse_token (ufp, "PLACED", 1);
    goto xy;
  case pnl_loctype_FIXED:
    unparse_token (ufp, "+", 1);
    unparse_token (ufp, "FIXED", 1);
    goto xy;
  case pnl_loctype_COVER:
    unparse_token (ufp, "+", 1);
    unparse_token (ufp, "COVER", 1);
  xy:
    unparse_token (ufp, "(", 1);
    unparse_int (ufp, x, 1);
    unparse_int (ufp, y, 1);
    unparse_token (ufp, ")", 1);
    {
      const char *orient = pnl_orientation_to_string (orientation);
      unparse_token (ufp, (char *) orient, 1);
    }
    break;
  case pnl_loctype_UNPLACED:
    unparse_token (ufp, "+", 1);
    unparse_token (ufp, "UNPLACED", 1);
    break;
  case pnl_loctype_null:
    break;
  }
}


static
void
pnl2def_write_geometry (unparse_fp ufp, char *layer,
			int x0, int y0, int x1, int y1)
{
  unparse_token (ufp, "+", 1);
  unparse_token (ufp, "LAYER", 1);
  unparse_token (ufp, layer, 1);
  unparse_token (ufp, "(", 1);
  unparse_int (ufp, x0, 1);
  unparse_int (ufp, y0, 1);
  unparse_token (ufp, ")", 1);
  unparse_token (ufp, "(", 1);
  unparse_int (ufp, x1, 1);
  unparse_int (ufp, y1, 1);
  unparse_token (ufp, ")", 1);
}


static
void
pnl2def_write_units (unparse_fp ufp, pnl_design pdesign)
{
  char *name;
  int number;

  pnl_design_get_distance_units (pdesign, &name, &number);

  if ( name != NULL ) {
    unparse_token (ufp, "UNITS", 0);
    unparse_token (ufp, "DISTANCE", 1);
    unparse_token (ufp, name, 1);
    unparse_int (ufp, number, 1);
    unparse_token (ufp, ";", 1);
    unparse_newline (ufp);
    unparse_newline (ufp);
  }
}


static
void
pnl2def_write_die_area (unparse_fp ufp, pnl_design pdesign)
{
  int x0;
  int y0;
  int x1;
  int y1;
  int flag = pnl_design_get_die_area (pdesign, &x0, &y0, &x1, &y1);

  if ( flag ) {
    unparse_token (ufp, "DIEAREA", 0);
    unparse_token (ufp, "(", 1);
    unparse_int (ufp, x0, 1);
    unparse_int (ufp, y0, 1);
    unparse_token (ufp, ")", 1);
    unparse_token (ufp, "(", 1);
    unparse_int (ufp, x1, 1);
    unparse_int (ufp, y1, 1);
    unparse_token (ufp, ")", 1);
    unparse_token (ufp, ";", 1);
    unparse_newline (ufp);
    unparse_newline (ufp);
  }
}


static
void
pnl2def_write_tracks (unparse_fp ufp, pnl_design pdesign)
{
  int wrote_tracks = 0;

  pnl_design_for_all_x_tracks (pdesign, tracks) {
    int start = pnl_tracks_start (tracks);
    int count = pnl_tracks_count (tracks);
    int step = pnl_tracks_step (tracks);
    ar layers = pnl_tracks_layers (tracks);

    unparse_token (ufp, "TRACKS", 0);
    unparse_token (ufp, "X", 1);
    unparse_int (ufp, start, 1);
    unparse_token (ufp, "DO", 1);
    unparse_int (ufp, count, 1);
    unparse_token (ufp, "STEP", 1);
    unparse_int (ufp, step, 1);
    unparse_token (ufp, "LAYER", 1);
    ar_for_all (layer, char *, layer_name) {
      unparse_token (ufp, layer_name, 1);
    } ar_end_for;
    unparse_token (ufp, ";", 1);
    unparse_newline (ufp);
    wrote_tracks = 1;
  } pnl_end_for;

  pnl_design_for_all_y_tracks (pdesign, tracks) {
    int start = pnl_tracks_start (tracks);
    int count = pnl_tracks_count (tracks);
    int step = pnl_tracks_step (tracks);
    ar layers = pnl_tracks_layers (tracks);

    unparse_token (ufp, "TRACKS", 0);
    unparse_token (ufp, "Y", 1);
    unparse_int (ufp, start, 1);
    unparse_token (ufp, "DO", 1);
    unparse_int (ufp, count, 1);
    unparse_token (ufp, "STEP", 1);
    unparse_int (ufp, step, 1);
    unparse_token (ufp, "LAYER", 1);
    ar_for_all (layer, char *, layer_name) {
      unparse_token (ufp, layer_name, 1);
    } ar_end_for;
    unparse_token (ufp, ";", 1);
    unparse_newline (ufp);
    wrote_tracks = 1;
  } pnl_end_for;

  if ( wrote_tracks ) {
    unparse_newline (ufp);
  }
}


static
int
pnl2def_num_components (pnl_design pdesign)
{
  nl_idesign idesign = pnl_design_nl_rep (pdesign);
  nl_icell_attr icell_attr = pnl_design_icell_attr (pdesign);
  int count = 0;

  nl_idesign_for_all_icells (idesign, icell) {
    nl_idesign down_idesign = nl_icell_down_design (icell);
    int is_leaf = 1;

    if ( down_idesign != NULL ) {
      nl_design down_design = nl_idesign_design (down_idesign);
      int is_lib = nl_design_libcell (down_design);

      is_leaf = is_lib;
    }

    if ( !is_leaf ) {
      pnl_design down_pdesign = NULL;

      nl_idesign_attr_get_by_name ("pnl design", down_idesign, &down_pdesign);

      count += pnl2def_num_components (down_pdesign);
    }
    else {
      pnl_cell pcell = NULL;

      nl_icell_attr_get (icell_attr, icell, &pcell);

      if ( pcell != NULL ) {
	pnl_loctype loctype = pnl_cell_loctype (pcell);

	if ( loctype != pnl_loctype_null ) {
	  count++;
	}
      }
    }
  } nl_end_for;

  return count;
}


static
void
pnl2def_write_components (unparse_fp ufp, pnl_design pdesign, char *prefix)
{
  nl_idesign idesign = pnl_design_nl_rep (pdesign);
  nl_design design = nl_idesign_design (idesign);
  nl_icell_attr icell_attr = pnl_design_icell_attr (pdesign);

  nl_design_for_all_cells (design, cell) {
    nl_reference reference = nl_cell_reference (cell);
    char *cell_name = nl_cell_name (cell);
    char *reference_name = nl_reference_name (reference);
    nl_icell icell = nl_idesign_get_icell (idesign, cell);
    nl_idesign down_idesign = nl_icell_down_design (icell);
    int is_leaf = 1;

    if ( down_idesign != NULL ) {
      nl_design down_design = nl_idesign_design (down_idesign);
      int is_lib = nl_design_libcell (down_design);

      is_leaf = is_lib;
    }

    if ( !is_leaf ) {
      pnl_design down_pdesign = NULL;
      char *down_prefix = str_append (prefix, cell_name, "/", NULL);

      nl_idesign_attr_get_by_name ("pnl design", down_idesign, &down_pdesign);

      pnl2def_write_components (ufp, down_pdesign, down_prefix);

      FREE (down_prefix);
    }
    else {
      pnl_cell pcell = NULL;

      nl_icell_attr_get (icell_attr, icell, &pcell);

      if ( pcell != NULL ) {
	pnl_loctype loctype = pnl_cell_loctype (pcell);
	
	unparse_token (ufp, "-", 0);
	unparse_token (ufp, prefix, 1);
	unparse_token (ufp, cell_name, 0);
	unparse_token (ufp, reference_name, 1);

	if ( loctype == pnl_loctype_null ) {
	  unparse_token (ufp, "+", 1);
	  unparse_token (ufp, "UNPLACED", 1);
	}
	else {
	  int x;
	  int y;
	  pnl_orientation orientation = pnl_cell_orientation (pcell);

	  pnl_cell_get_location (pcell, &x, &y);

	  pnl2def_write_location (ufp, loctype, x, y, orientation);
	}

	unparse_token (ufp, ";", 1);
	unparse_newline (ufp);
      }
    }
  } nl_end_for;
}


static
int
pnl2def_num_pins (pnl_design pdesign)
{
  nl_idesign idesign = pnl_design_nl_rep (pdesign);
  nl_design design = nl_idesign_design (idesign);
  nl_iport_attr iport_attr = pnl_design_iport_attr (pdesign);
  int count = 0;

  nl_design_for_all_ports (design, port) {
    nl_iport iport = nl_idesign_get_iport (idesign, port);
    pnl_port pport = NULL;

    nl_iport_attr_get (iport_attr, iport, &pport);

    if ( pport != NULL ) {
      count++;
    }
  } nl_end_for;

  return count;
}


static
void
pnl2def_write_pins (unparse_fp ufp, pnl_design pdesign)
{
  nl_idesign idesign = pnl_design_nl_rep (pdesign);
  nl_design design = nl_idesign_design (idesign);
  nl_iport_attr iport_attr = pnl_design_iport_attr (pdesign);

  nl_design_for_all_ports (design, port) {
    char *port_name = nl_port_name (port);
    nl_iport iport = nl_idesign_get_iport (idesign, port);
    pnl_port pport = NULL;

    nl_iport_attr_get (iport_attr, iport, &pport);

    if ( pport != NULL ) {
      nl_pin pin = nl_port_pin (port);
      nl_net net = nl_pin_net (pin);
      char *net_name = nl_net_name (net);

      unparse_token (ufp, "-", 0);
      unparse_token (ufp, port_name, 1);
      unparse_token (ufp, "+", 1);
      unparse_token (ufp, "NET", 1);
      unparse_token (ufp, net_name, 1);

      {
	nl_direction dir = nl_port_direction (port);

	pnl2def_write_direction (ufp, dir);
      }

      {
	pnl_loctype loctype = pnl_port_loctype (pport);
	pnl_orientation orientation = pnl_port_orientation (pport);
	int x;
	int y;

	pnl_port_get_location (pport, &x, &y);

	pnl2def_write_location (ufp, loctype, x, y, orientation);
      }

      {
	char *layer;
	int x0;
	int y0;
	int x1;
	int y1;
	int flag = pnl_port_get_geometry (pport, &layer, &x0, &y0, &x1, &y1);

	if ( flag ) {
	  pnl2def_write_geometry (ufp, layer, x0, y0, x1, y1);
	}
      }

      unparse_token (ufp, ";", 1);
      unparse_newline (ufp);
    }
  } nl_end_for;
}


static
int
pnl2def_num_nets_with_routes (pnl_design pdesign)
{
  int count = 0;

  pnl_design_for_all_nets (pdesign, pnet) {
    pnl_dll_head routes = pnl_net_routes (pnet);
    int size = pnl_dll_head_num_elements (routes);

    if ( size > 0 ) {
      count++;
    }
  } pnl_end_for;

  return count;
}


static
void
pnl2def_write_nets_with_routes (unparse_fp ufp, pnl_design pdesign)
{
  pnl_design_for_all_nets (pdesign, pnet) {
    if ( pnl_net_routes (pnet) != NULL ) {
      char *net_name = pnl_net_name (pnet);

      unparse_token (ufp, "-", 0);
      unparse_token (ufp, net_name, 1);

      pnl_net_for_all_routes (pnet, route) {
	pnl_routekind routekind = pnl_route_kind (route);
	const char *routekind_str = pnl_routekind_to_string (routekind);
	int first = 1;

	unparse_newline (ufp);
	unparse_token (ufp, "+", 2);
	unparse_token (ufp, (char *) routekind_str, 1);

	pnl_route_for_all_branches (route, branch) {
	  char *layer = pnl_branch_layer (branch);
	  int x0 = pnl_branch_x0 (branch);
	  int y0 = pnl_branch_y0 (branch);

	  unparse_newline (ufp);

	  if ( first ) {
	    unparse_token (ufp, layer, 4);
	    first = 0;
	  }
	  else {
	    unparse_token (ufp, "NEW", 4);
	    unparse_token (ufp, layer, 1);
	  }

	  unparse_token (ufp, "(", 1);
	  unparse_int (ufp, x0, 1);
	  unparse_int (ufp, y0, 1);
	  unparse_token (ufp, ")", 1);

	  pnl_branch_for_all_segments (branch, segment) {
	    pnl_segmentkind segkind = pnl_segment_kind (segment);

	    switch ( segkind ) {
	    case pnl_segmentkind_x: {
	      pnl_x_segment x_seg = (pnl_x_segment) segment;
	      int x = pnl_x_segment_x (x_seg);

	      unparse_token (ufp, "(", 1);
	      unparse_int (ufp, x, 1);
	      unparse_token (ufp, "*", 1);
	      unparse_token (ufp, ")", 1);

	      break;
	    }
	    case pnl_segmentkind_y: {
	      pnl_y_segment y_seg = (pnl_y_segment) segment;
	      int y = pnl_y_segment_y (y_seg);

	      unparse_token (ufp, "(", 1);
	      unparse_token (ufp, "*", 1);
	      unparse_int (ufp, y, 1);
	      unparse_token (ufp, ")", 1);

	      break;
	    }
	    case pnl_segmentkind_via: {
	      pnl_via via = (pnl_via) segment;
	      char *via_name = pnl_via_name (via);

	      unparse_newline (ufp);
	      unparse_token (ufp, via_name, 6);

	      break;
	    }
	    default:
	      error ("internal error: funky segment kind detected.");
	    }
	  } pnl_end_for;
	} pnl_end_for;

      } pnl_end_for;

      unparse_token (ufp, ";", 1);
      unparse_newline (ufp);
    }
  } pnl_end_for;
}


static
void
pnl2def_write_pdesign (unparse_fp ufp, pnl_design pdesign,
		       int components, int pins, int nets)
{
  nl_idesign idesign = pnl_design_nl_rep (pdesign);
  nl_design design = nl_idesign_design (idesign);
  char *design_name = nl_design_name (design);

  unparse_token (ufp, "DESIGN", 0);
  unparse_token (ufp, design_name, 1);
  unparse_token (ufp, ";", 1);
  unparse_newline (ufp);
  unparse_newline (ufp);

  pnl2def_write_units (ufp, pdesign);

  pnl2def_write_die_area (ufp, pdesign);

  pnl2def_write_tracks (ufp, pdesign);

  /* pnl2def_write_row_sites (ufp, pdesign); */

  if ( components ) {
    int num_components = pnl2def_num_components (pdesign);
    if ( num_components > 0 ) {
      unparse_token (ufp, "COMPONENTS", 0);
      unparse_int (ufp, num_components, 1);
      unparse_token (ufp, ";", 1);
      unparse_newline (ufp);

      pnl2def_write_components (ufp, pdesign, "");

      unparse_token (ufp, "END", 0);
      unparse_token (ufp, "COMPONENTS", 1);
      unparse_newline (ufp);
      unparse_newline (ufp);
    }
  }

  if ( pins ) {
    int num_pins = pnl2def_num_pins (pdesign);
    
    if ( num_pins > 0 ) {
      unparse_token (ufp, "PINS", 0);
      unparse_int (ufp, num_pins, 1);
      unparse_token (ufp, ";", 1);
      unparse_newline (ufp);

      pnl2def_write_pins (ufp, pdesign);

      unparse_token (ufp, "END", 0);
      unparse_token (ufp, "PINS", 1);
      unparse_newline (ufp);
      unparse_newline (ufp);
    }
  }

  if ( nets ) {
    int num_nets = pnl2def_num_nets_with_routes (pdesign);

    if ( num_nets > 0 ) {
      unparse_token (ufp, "NETS", 0);
      unparse_int (ufp, num_nets, 1);
      unparse_token (ufp, ";", 1);
      unparse_newline (ufp);

      pnl2def_write_nets_with_routes (ufp, pdesign);

      unparse_token (ufp, "END", 0);
      unparse_token (ufp, "NETS", 1);
      unparse_newline (ufp);
      unparse_newline (ufp);
    }
  }

  unparse_token (ufp, "END", 0);
  unparse_token (ufp, "DESIGN", 1);
  unparse_newline (ufp);
}


int
pnl2def_write_def (FILE *ofp, pnl_design pdesign, int components, int pins,
		   int nets)
{
  unparse_fp ufp;

  ufp = unparse_open (ofp);
  unparse_set_line_limit (ufp, 256);

  pnl2def_write_pdesign (ufp, pdesign, components, pins, nets);

  unparse_close (ufp);

  return 1;
}
