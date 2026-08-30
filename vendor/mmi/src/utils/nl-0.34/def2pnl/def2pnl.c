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
#include "stdpccts.h"
#define Tcl_Interp void
#define Tcl_Obj void
#include "ui.h"


static nl_icell top_icell = NULL;
static nl_context current_context = NULL;
static nl_design current_design = NULL;
static nl_idesign current_idesign = NULL;
static pnl_design current_pdesign = NULL;
static pnl_idesign current_pidesign = NULL;
static char *current_hierarchy_divider = NULL;
static hashtab filler_cells = NULL;
static hashtab logic_0_nets = NULL;
static hashtab logic_1_nets = NULL;
static int current_dx = 0;
static int current_dy = 0;
static pnl_orientation current_orientation = pnl_orientation_N;
static mem_group prev_mem_group = NULL;
static int def2pnl_nohierarchy = 0;


static
void
def2pnl_zzerr (const char *text)
{
  error ("error: line %d at '%s': %s", def_zzline, def_zzlextext, text);
}


void
def2pnl_design (char *name)
{
  if ( top_icell == NULL ) {
    current_design = nl_context_get_design_by_name (current_context, name);

    if ( current_design == NULL ) {
      error ("design name in the DEF file, %s, does not exist in memory.",
	     name);
    }
    current_pdesign = NULL;

    nl_design_attr_get_by_name ("pnl design", current_design,
				 &current_pdesign);

    if ( current_pdesign == NULL ) {
      current_pdesign = pnl_design_create (current_design);
    }
    
    current_idesign = NULL;
    current_pidesign = NULL;

    if ( !def2pnl_nohierarchy ) {
      current_idesign = nl_idesign_get_or_create (current_design, NULL);

      nl_idesign_attr_get_by_name ("pnl idesign", current_idesign,
				   &current_pidesign);

      if ( current_pidesign == NULL ) {
	current_pidesign = pnl_idesign_create (current_idesign);
      }
    }
  }
  else {
    char *design_name;

    current_idesign = nl_icell_down_design (top_icell);
    current_design = nl_idesign_design (current_idesign);

    design_name = nl_design_name (current_design);

    if ( strcmp (design_name, name) != 0 ) {
      error ("The design name specified in the .def file, %s, does not match "
	     "the design name of the specified instance cell, %s.",
	     name, design_name);
    }
    
    current_pdesign = NULL;

    /* Special case: current_pdesign should remain NULL when reading
       the DEF for a subcell. */

    current_idesign = NULL;
    current_pidesign = NULL;

    if ( !def2pnl_nohierarchy ) {
      current_idesign = nl_icell_down_design (top_icell);
      nl_idesign_attr_get_by_name ("pnl idesign", current_idesign,
				   &current_pidesign);

      if ( current_pidesign == NULL ) {
	error ("No physical design information exists for the specified "
	       "instance cell.");
      }
    }
  }

  {
    mem_group design_mem_group = nl_design_mem_group (current_design);
    prev_mem_group = mem_group_set (design_mem_group);
  }
}


static
char *
def2pnl_get_history_string (char *text)
{
  char *s = text;
  char *result;
  int len;

  while ( *s && (*s == ';' || *s == ' ' || *s == '\t' || *s == '\n' ) ) {
    s++;
  }

  result = STRDUP (s);
  len = strlen (s) - 2;

  while (len >= 0 &&
         (result[len] == ' ' || result[len] == '\t' || result[len] == '\n')) {
    len--;
  }

  result[len+1] = 0;
  return result;
}


void
def2pnl_history (char *str)
{
  char *hist_string = def2pnl_get_history_string (str);

  if ( current_pdesign != NULL ) {
    pnl_design_add_history (current_pdesign, hist_string);
  }

  FREE (hist_string);
}


void
def2pnl_die_area (int x0, int y0, int x1, int y1)
{
  int xll = x0 + current_dx;
  int yll = y0 + current_dy;
  int xur = x1 + current_dx;
  int yur = y1 + current_dy;

  if ( current_pdesign != NULL ) {
    pnl_design_set_die_area (current_pdesign, xll, yll, xur, yur);
  }
}


void
def2pnl_divider_char (char *str)
{
  char *divider = STRDUP (str + 1);

  ASSERT (str[0] == '"');

  {
    char *s = NULL;
    char *t = divider;

    while ( t[0] != 0 ) {
      s = t;
      t++;
    }

    ASSERT (s != NULL && s[0] == '"');

    s[0] = 0;
  }

  if ( current_hierarchy_divider != NULL ) {
    FREE (current_hierarchy_divider);
  }

  if ( divider != NULL && divider[0] == 0 ) {
    FREE (divider);
    current_hierarchy_divider = NULL;
  }
  else {
    current_hierarchy_divider = divider;
  }
}


static
nl_inet
def2pnl_get_or_create_inet (char *name)
{
  return NULL;
}  


static
nl_inet
def2pnl_lookup_constant_nets (char *name)
{
  if ( logic_0_nets != NULL ) {
    ht_entry ent = ht_lookup (logic_0_nets, name); 

    if ( ent != ht_null ) {
      nl_inet result = def2pnl_get_or_create_inet ("1'b0");

      return result;
    }
  }

  if ( logic_1_nets != NULL ) {
    ht_entry ent = ht_lookup (logic_1_nets, name);

    if ( ent != ht_null ) {
      nl_inet result = def2pnl_get_or_create_inet ("1'b1");

      return result;
    }
  }

  return NULL;
}
  

pnl_net
def2pnl_net (char *name, int special)
{
  ar net_array = ar_alloc (1, sizeof (nl_inet));
  char *str = NULL;
  volatile pnl_net pnet;

  error_unwind_protect {
    nl_inet inet;

    inet = def2pnl_lookup_constant_nets (name);

    if ( inet == NULL ) {
      ar path_ar
	= ui_tokenize_hierarchy_path (name, &str, current_hierarchy_divider);

      int status
	= ui_find_iobject_path (NULL, path_ar, nl_kind_inet, current_idesign,
				ui_find_mode_exact, net_array);

      if ( status != 0 || ar_size (net_array) != 1 ) {
	if ( special ) {
	  nl_design design;
	  mem_group group;
	  mem_group prev_group;
	  nl_idesign idesign;
	  nl_net new_net;
	  char *new_net_name;
	  int path_size = ar_size (path_ar);

	  ASSERT (path_size != 0);

	  if ( path_size == 1 ) {
	    new_net_name = name;
	    design = current_design;
	    idesign = current_idesign;
	  }
	  else {
	    ar_ref (path_ar, path_size-1, &new_net_name);
	    ar_remove_indexed_element (path_ar, path_size-1);
	    ar_make_size (net_array, 0);
	    status = ui_find_iobject_path (NULL, path_ar, nl_kind_icell,
					   current_idesign, ui_find_mode_exact,
					   net_array);

	    if ( status != 0 || ar_size (net_array) != 1 ) {
	      def2pnl_error ("could not find parent cell for \"%s\".", name);
	    }
	    else {
	      nl_icell parent_icell;

	      ar_ref (net_array, 0, &parent_icell);
	      idesign = nl_icell_down_design (parent_icell);
	      design = nl_idesign_design (idesign);
	    }
	  }

	  group = nl_design_mem_group (design);
	  prev_group = mem_group_set (group);

	  fprintf (stderr, "Warning:%d: creating net '%s' in design '%s'\n",
		   zzline, new_net_name, nl_design_name (design));

	  new_net = nl_net_create (new_net_name, nl_wireclass_wire, design);
	  inet = nl_idesign_get_inet (idesign, new_net);

	  nl_design_for_all_idesigns (design, idesign) {
	    nl_inet new_inet = nl_idesign_get_inet (idesign, new_net);
	    pnl_inet pinet = pnl_inet_create (new_inet);

	    nl_inet_attr_set_by_name ("pnl inet", new_inet, (void *) &pnet);
	  } nl_end_for;

	  mem_group_set (prev_group);
	}
	else {
	  def2pnl_error ("could not find a net named \"%s\".", name);
	}
      }
      else {
	ar_ref (net_array, 0, &inet);
      }
    }

    nl_inet_attr_get_by_name ("pnl inet", inet, (void *) &pnet);
    
  }
  error_on_exit {
    if ( net_array != NULL ) {
      ar_free (net_array);
    }

    if ( str != NULL ) {
      FREE (str);
    }
  }
  error_end;

  pnl_net_set_special (pnet, special);

  return pnet;
}


static
void
def2pnl_component_nohier (char *inst_name, char *libcell_name, pnl_loctype loctype,
			  int x, int y, pnl_orientation orientation)
{
  nl_cell cell = nl_design_get_cell_by_name (current_design, inst_name);

  if ( cell == NULL ) {
    def2pnl_error ("could not find cell named \"%s\".", inst_name);
  }
  else {
    pnl_cell pcell = pnl_design_get_cell (current_pdesign, cell);
    nl_reference reference = nl_cell_reference (cell);
    char *ref_name = nl_reference_name (reference);
    pnl_orientation orient_eff;

    if ( strcmp (ref_name, libcell_name) != 0 ) {
      fprintf (stderr, "Error: cell name in .def file does not match stored "
	       "netlist -> \"%s\" vs. \"%s\".\n", ref_name, libcell_name);
    }

    pnl_cell_set_loctype (pcell, loctype);

    if ( loctype != pnl_loctype_UNPLACED ) {
      pnl_cell_set_location (pcell, 0, x + current_dx, y + current_dy);
    }

    orient_eff = pnl_translate_orientation (orientation, current_orientation);
    pnl_cell_set_orientation (pcell, orient_eff);
  }
}


static
void
def2pnl_component_hier (char *inst_name, char *libcell_name, pnl_loctype loctype,
			int x, int y, pnl_orientation orientation)
{
  ar cell_array = ar_alloc (1, sizeof (nl_icell));

  error_unwind_protect {
    int status;
    nl_icell icell;
    char *str;
    ar path_ar = ui_tokenize_hierarchy_path (inst_name, &str,
					     current_hierarchy_divider);
  
    status
      = ui_find_iobject_path (NULL, path_ar, nl_kind_icell, current_idesign,
			      ui_find_mode_exact, cell_array);
  
    if ( status != 0 || ar_size (cell_array) != 1 ) {
      ht_entry ent = (filler_cells == NULL
		      ? ht_null
		      : ht_lookup (filler_cells, libcell_name));

      if ( ent == ht_null ) {
	def2pnl_error ("could not find cell named \"%s\".", inst_name);
      }
      else {
	nl_design design;
	mem_group group;
	mem_group prev_group;
	nl_idesign idesign;
	nl_reference reference;
	nl_cell new_cell;
	char *cell_name;
	int path_size = ar_size (path_ar);

	ASSERT (path_size != 0);

	if ( path_size == 1 ) {
	  cell_name = inst_name;
	  design = current_design;
	  idesign = current_idesign;
	}
	else {
	  ar_ref (path_ar, path_size-1, &cell_name);
	  ar_remove_indexed_element (path_ar, path_size-1);
	  ar_make_size (cell_array, 0);
	  status = ui_find_iobject_path (NULL, path_ar, nl_kind_icell,
					 current_idesign, ui_find_mode_exact,
					 cell_array);

	  if ( status != 0 || ar_size (cell_array) != 1 ) {
	    def2pnl_error ("could not find parent cell for \"%s\".",
			   inst_name);
	  }
	  else {
	    nl_icell parent_icell;

	    ar_ref (cell_array, 0, &parent_icell);
	    idesign = nl_icell_down_design (parent_icell);
	    design = nl_idesign_design (idesign);
	  }
	}

	reference = nl_design_get_reference_by_name (design, libcell_name);

	if ( reference == NULL ) {
	  reference = nl_reference_create (libcell_name, design, NULL);
	}

	group = nl_design_mem_group (design);
	prev_group = mem_group_set (group);
	new_cell = nl_cell_create (cell_name, reference);

	icell = nl_idesign_get_icell (idesign, new_cell);

	nl_design_for_all_idesigns (design, idesign) {
	  nl_icell new_icell = nl_idesign_get_icell (idesign, new_cell);
	  pnl_icell picell = pnl_icell_create (new_icell);

	  nl_icell_attr_set_by_name ("pnl icell", new_icell, &picell);

	  pnl_icell_set_loctype (picell, pnl_loctype_UNPLACED);
	} nl_end_for;

	mem_group_set (prev_group);
      }
    }
    else {
      ar_ref (cell_array, 0, &icell);
    }

    FREE (str);

    {
      nl_reference reference = nl_icell_reference (icell);
      char *ref_name = nl_reference_name (reference);
      pnl_icell picell;
      pnl_orientation orient_eff;

      if ( strcmp (ref_name, libcell_name) != 0 ) {
	fprintf (stderr, "Error: cell name in .def file does not match stored "
		 "netlist -> \"%s\" vs. \"%s\".\n", ref_name, libcell_name);
      }

      nl_icell_attr_get_by_name ("pnl icell", icell, &picell);

      ASSERT (picell != NULL);

      pnl_icell_set_loctype (picell, loctype);
      if ( loctype != pnl_loctype_UNPLACED ) {
	pnl_icell_set_location (picell, 0, x + current_dx, y + current_dy);
      }

      orient_eff = pnl_translate_orientation (orientation,
					      current_orientation);
      pnl_icell_set_orientation (picell, orient_eff);
    }
  }
  error_on_exit {
    ar_free (cell_array);
  }
  error_end;
}


void
def2pnl_component (char *inst_name, char *libcell_name, pnl_loctype loctype,
		   int x, int y, pnl_orientation orientation)
{
  if ( def2pnl_nohierarchy ) {
    def2pnl_component_nohier (inst_name, libcell_name, loctype, x, y, orientation);
  }
  else {
    def2pnl_component_hier (inst_name, libcell_name, loctype, x, y, orientation);
  }
}


pnl_port
def2pnl_pin (char *pin_name)
{
  ar port_array = ar_alloc (1, sizeof (nl_iport));
  volatile pnl_port pport;

  error_unwind_protect {
    int status;
    nl_port port;
  
    port = (nl_port) nl_design_get_port_by_name (current_design, pin_name);
  
    if ( port == NULL || nl_port_kind (port) != nl_kind_port ) {
      def2pnl_error ("could not find port named \"%s\".", pin_name);
    }

    nl_port_attr_get_by_name ("pnl port", port, (void *) &pport);
  }
  error_on_exit {
    ar_free (port_array);
  }
  error_end;

  return pport;
}


void
def2pnl_port (pnl_port pport, pnl_loctype loctype, int x0, int y0,
	      pnl_orientation orient)
{
  int x = x0 + current_dx;
  int y = y0 + current_dy;

  pnl_port_set_loctype (pport, loctype);
  pnl_port_set_location (pport, x, y);
  pnl_port_set_orientation (pport, orient);
}


void
def2pnl_tracks (int is_x, int start, int count, int step, ar layers)
{
  if ( current_pdesign != NULL ) {
    if ( is_x ) {
      int x0 = start + current_dx;
      pnl_design_add_x_tracks (current_pdesign, x0, count, step, layers);
    }
    else {
      int y0 = start + current_dy;
      pnl_design_add_y_tracks (current_pdesign, y0, count, step, layers);
    }
  }
}


void
def2pnl_row_site (char *name, char *core_name, int x0, int y0,
		   pnl_orientation orient, int count, int width, int height)
{
  int x = x0 + current_dx;
  int y = y0 + current_dy;

  if ( current_pdesign != NULL ) {
    pnl_design_add_row_site (current_pdesign, name, core_name, x, y, orient,
			     count, width, height);
  }
}


void
def2pnl_distance_units (char *unit_name, int number)
{
  if ( current_pdesign != NULL ) {
    pnl_design_set_distance_units (current_pdesign, unit_name, number);
  }
}


int
def2pnl_read_def (FILE *ifp, nl_context context, nl_icell icell,
		  int dx, int dy, pnl_orientation orient, ar fillers,
		  ar zero_names, ar one_names, int nohierarchy)
{
  void (*def2pnl_zzerr)(const char *);

  current_context = context;
  top_icell = icell;
  current_dx = dx;
  current_dy = dy;
  current_orientation = orient;
  def2pnl_nohierarchy = nohierarchy;

  def2pnl_zzerr = def2pnl_lex_error;
  def2pnl_divider_char ("\"/\"");

  if ( fillers != NULL ) {
    int size = ar_size (fillers);

    filler_cells = ht_alloc (size, ht_hash_string, ht_compare_string,
			     ht_copy_string, ht_free_string);

    ar_for_all (fillers, char *, filler) {
      ht_insert (filler_cells, filler);
    } ar_end_for;
  }

  if ( zero_names != NULL ) {
    int size = ar_size (zero_names);

    logic_0_nets = ht_alloc (size, ht_hash_string, ht_compare_string,
			     ht_copy_string, ht_free_string);

    ar_for_all (zero_names, char *, zero) {
      ht_insert (logic_0_nets, zero);
    } ar_end_for;
  }

  if ( one_names != NULL ) {
    int size = ar_size (one_names);

    logic_1_nets = ht_alloc (size, ht_hash_string, ht_compare_string,
			     ht_copy_string, ht_free_string);

    ar_for_all (one_names, char *, one) {
      ht_entry ent = ht_lookup (logic_0_nets, one);
      if ( ent != ht_null ) {
	error ("'%s' appears in both the -zero and the -one lists.",
	       one);
      }
      ht_insert (logic_1_nets, one);
    } ar_end_for;
  }

  def_zzerr = def2pnl_zzerr;

  error_unwind_protect {
    ANTLR (def_file(), ifp);
  }
  error_on_error {
    if ( current_idesign != NULL ) {
      current_pdesign = NULL;
      current_idesign = NULL;
    }
  }
  error_on_exit {
    def2pnl_divider_char ("\"\"");

    if ( prev_mem_group != NULL ) {
      mem_group_set (prev_mem_group);
      prev_mem_group = NULL;
    }

    if ( filler_cells != NULL )
      ht_free (filler_cells);
    filler_cells = NULL;

    if ( logic_0_nets != NULL )
      ht_free (logic_0_nets);
    logic_0_nets = NULL;

    if ( logic_1_nets != NULL )
      ht_free (logic_1_nets);
    logic_1_nets = NULL;
  }
  error_end;

  return 1;
}
