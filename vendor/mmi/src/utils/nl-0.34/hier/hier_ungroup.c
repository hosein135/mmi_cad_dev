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
#include "nl.h"
#include "hier.h"
#include "hier_int.h"



static
nl_net
hier_ungroup_promote_net (nl_net down_net, nl_design up_design, char *prefix,
			  nl_net_attr net_forward)
{
  nl_net up_net;

  nl_net_attr_get (net_forward, down_net, &up_net);

  if ( up_net == NULL ) {
    up_net = hier_copy_net (down_net, up_design, prefix, net_forward);
    nl_net_attr_set (net_forward, down_net, &up_net);
  }

  return up_net;
}



static
void
hier_ungroup_promote_nets (nl_design down_design, nl_cell up_cell,
			   char *prefix, nl_net_attr net_forward)
{
  nl_design up_design = nl_cell_design (up_cell);

  /* Step 0. Make entries in the forward table for constant nets. */
  {
    nl_net zero = nl_design_get_net_by_name (down_design, "1'b0");
    nl_net one = nl_design_get_net_by_name (down_design, "1'b1");

    if ( zero != NULL ) {
      nl_net up_zero = nl_design_get_net_by_name (up_design, "1'b0");

      if ( up_zero == NULL ) {
	up_zero = nl_net_create ("1'b0", nl_wireclass_wire, up_design);
      }

      nl_net_attr_set (net_forward, zero, &up_zero);
    }

    if ( one != NULL ) {
      nl_net up_one = nl_design_get_net_by_name (up_design, "1'b1");

      if ( up_one == NULL ) {
	up_one = nl_net_create ("1'b1", nl_wireclass_wire, up_design);
      }

      nl_net_attr_set (net_forward, one, &up_one);
    }
  }

  /* Step 1. Promote the nets that are connected to ports. */
  nl_design_for_all_ports (down_design, down_port) {
    nl_pin down_pin = nl_port_pin (down_port);
    nl_net down_net = nl_pin_net (down_pin);
    nl_net existing_up_net = NULL;
    char *down_name = nl_port_name (down_port);
    nl_reference up_ref = nl_cell_reference (up_cell);
    nl_refpin up_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (up_ref, down_name);
    nl_pin up_pin;
    nl_net up_net;

    ASSERT (up_refpin != NULL);

    ASSERT (nl_refpin_kind (up_refpin) == nl_kind_refpin);

    up_pin = nl_cell_get_pin_by_refpin (up_cell, up_refpin);
    up_net = nl_pin_net (up_pin);

    nl_net_attr_get (net_forward, down_net, &existing_up_net);

    /* Don't do anything if this net has already been forwarded. */
    if ( existing_up_net == NULL ) {

      if ( up_net == NULL ) {
	up_net = hier_copy_net (down_net, up_design, prefix, net_forward);
      }
      else {
	nl_net_attr_set (net_forward, down_net, &up_net);
      }
    }
    else if ( up_net != NULL && up_net != existing_up_net ) {
      nl_direction dir = nl_port_direction (down_port);
      nl_net final_net;

      if ( dir == nl_direction_in ) {
	final_net = nl_net_merge (up_net, existing_up_net);
      }
      else {
	final_net = nl_net_merge (existing_up_net, up_net);
      }
	
      nl_net_attr_set (net_forward, down_net, &final_net);
    }
  } nl_end_for;

  /* Step 2. Promote all the supply nets. */
  {
    ar supply0s = nl_design_supply0s (down_design);
    ar supply1s = nl_design_supply1s (down_design);

    ar_for_all (supply0s, nl_object, supply) {
      if ( nl_object_kind (supply) == nl_kind_net ) {
	nl_net up_net = hier_ungroup_promote_net ((nl_net) supply, up_design,
						  prefix, net_forward);

	nl_design_add_supply0 (up_design, (nl_object) up_net);
      }
    } ar_end_for;
  
    ar_for_all (supply1s, nl_object, supply) {
      if ( nl_object_kind (supply) == nl_kind_net ) {
	nl_net up_net = hier_ungroup_promote_net ((nl_net) supply, up_design,
						  prefix, net_forward);

	nl_design_add_supply1 (up_design, (nl_object) up_net);
      }
    } ar_end_for;
  }
  
  /* Step 3. Promote all remaining nets. */
  nl_design_for_all_nets (down_design, down_net) {
    hier_ungroup_promote_net (down_net, up_design, prefix, net_forward);
  } nl_end_for;
}


static
void
hier_ungroup_cell_array (ar cells, char *hierarchy_separator, char *name_prefix,
			 int recursive, int silent)
{
  ar_for_all (cells, nl_cell, cell) {
    nl_reference reference = nl_cell_reference (cell);
    nl_object down_object = nl_reference_down_design (reference);

    if ( down_object != NULL &&
	 nl_object_kind (down_object) == nl_kind_design &&
	 nl_design_libcell ((nl_design) down_object) == 0 ) {
      hier_ungroup (cell, hierarchy_separator, name_prefix, recursive, silent);
    }
  } ar_end_for;
}  


void
hier_ungroup (nl_cell cell, char *hierarchy_separator, char *name_prefix,
	      int recursive, int silent)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_object down_object = nl_reference_down_design (reference);
  nl_design up_design = nl_cell_design (cell);

  if ( down_object == NULL ) {
    error ("cannot ungroup unlinked reference %s",
	   nl_reference_name (reference));
  }
  else {
    nl_kind down_kind = nl_object_kind (down_object);
    
    if ( down_kind == nl_kind_libcell ||
	 (down_kind == nl_kind_design &&
	  nl_design_libcell ((nl_design) down_object) ) ) {
      error ("cannot ungroup library cell %s", nl_reference_name (reference));
    }
  }

  if ( !silent ) {
    fprintf (stderr, "Ungrouping cell \"%s\".\n", nl_cell_name (cell));
  }

  ASSERT (nl_object_kind (down_object) == nl_kind_design);

  {
    nl_design down_design = (nl_design) down_object;
    ar new_cells;
    nl_net_attr net_forward;
    nl_cell_attr cell_forward;
    nl_reference_attr ref_forward;
    char *cell_name = nl_cell_name (cell);
    char *prefix;

    if ( name_prefix == NULL ) {
      prefix = str_append (cell_name, hierarchy_separator, NULL);
    }
    else {
      prefix = name_prefix;
    }

    if ( recursive )
      new_cells = ar_alloc (16, sizeof (nl_cell));
    else
      new_cells = NULL;

    net_forward = nl_net_attr_create ("ungroup net forward",
				      down_design, nl_density_dense,
				      sizeof (nl_net), NULL, NULL);
    cell_forward = nl_cell_attr_create ("ungroup cell forward",
					down_design, nl_density_dense,
					sizeof (nl_cell), NULL, NULL);
    ref_forward = nl_reference_attr_create ("ungroup reference forward",
					    down_design, nl_density_dense,
					    sizeof (nl_reference), NULL, NULL);

    hier_ungroup_promote_nets (down_design, cell, prefix, net_forward);

    nl_design_for_all_net_buses (down_design, bus) {
      int connects_to_port = 0;

      nl_bus_for_all_net_members (bus, net) {
	nl_net_for_all_pins (net, pin) {
	  nl_cell_or_port owner = nl_pin_owner (pin);

	  if ( nl_cell_or_port_kind (owner) == nl_kind_port ) {
	    connects_to_port = 1;
	    goto done;
	  }
	} nl_end_for;
      } nl_end_for;
    done:
      if ( connects_to_port ) {
	/* Don't copy buses whose net connects to a port. */
	nl_bus_for_all_net_members (bus, net) {
	  nl_net_for_all_pins (net, pin) {
	    nl_cell_or_port owner = nl_pin_owner (pin);

	    if ( nl_cell_or_port_kind (owner) == nl_kind_port ) {
	      goto next_net;
	    }
	  } nl_end_for;

	  error ("Internal error: net %s of bus %s does not connect "
		 "to a port, even though other nets in this bus do connect "
		 "to a port.\n", nl_net_name (net), nl_bus_name (bus));
	next_net:
	  ;
	} nl_end_for;
      }
      else {
	hier_copy_bus (bus, (nl_object) up_design, prefix,
		       (nl_attr) net_forward);
      }
    } nl_end_for;

    nl_design_for_all_references (down_design, reference) {
      hier_copy_reference (reference, up_design, ref_forward);
    } nl_end_for;

    nl_design_for_all_cells (down_design, cell) {
      nl_cell new_cell = hier_copy_cell (cell, ref_forward, net_forward,
					 prefix, cell_forward);
      if ( new_cells != NULL ) {
	ar_add (new_cells, &new_cell);
      }
    } nl_end_for;

    nl_design_for_all_cell_buses (down_design, bus) {
      hier_copy_bus (bus, (nl_object) up_design, prefix,
		     (nl_attr) cell_forward);
    } nl_end_for;

    /* need to do something about attributes */

    nl_design_remove_attr (down_design, (nl_attr) net_forward);
    nl_design_remove_attr (down_design, (nl_attr) cell_forward);
    nl_design_remove_attr (down_design, (nl_attr) ref_forward);

    FREE (prefix);

    {
      nl_design design = nl_cell_design (cell);
      nl_design_remove_cell (design, cell);
    }

    if ( new_cells != NULL ) {
      hier_ungroup_cell_array (new_cells, hierarchy_separator, name_prefix,
			       recursive, silent);
      ar_free (new_cells);
    }
  }
}


void
hier_ungroup_all (nl_design design, char *hierarchy_separator, char *name_prefix,
		  int recursive, int silent)
{
  ar cells = ar_alloc (16, sizeof (nl_cell));

  nl_design_for_all_cells (design, cell) {
    ar_add (cells, &cell);
  } nl_end_for;

  hier_ungroup_cell_array (cells, hierarchy_separator, name_prefix,
			   recursive, silent);

  ar_free (cells);
}
