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
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "str.h"
#include "nl.h"
#include "hier.h"
#include "hier_int.h"



nl_type
hier_copy_type (nl_type type, nl_design into_design)
{
  nl_typeclass class = nl_type_class (type);
  nl_type new_type;

  if ( class == nl_typeclass_scalar ) {
    new_type = nl_type_get_scalar ((nl_object) into_design);
  }
  else if ( class == nl_typeclass_array ) {
    int left = nl_type_left (type);
    int right = nl_type_right (type);
    nl_type base = nl_type_base_type (type);
    nl_type new_base = hier_copy_type (base, into_design);

    new_type = nl_type_get_array (new_base, left, right);
  }
  else {
    ASSERT (0);
  }

  return new_type;
}


nl_net
hier_copy_net (nl_net from_net, nl_design to_design, char *prefix,
	       nl_net_attr net_forward)
{
  char *name = nl_net_name (from_net);
  char *new_name = str_append (prefix, name, NULL);
  nl_wireclass class = nl_net_class (from_net);
  nl_net to_net = nl_net_create (new_name, class, to_design);

  FREE (new_name);
  nl_net_attr_set (net_forward, from_net, &to_net);

  return to_net;
}


nl_bus
hier_copy_bus (nl_bus from_bus, nl_object to_owner,
	       char *prefix, nl_attr member_forward)
{
  nl_kind member_kind = nl_bus_member_kind (from_bus);
  char *name = nl_bus_name (from_bus);
  char *new_name = str_append (prefix, name, NULL);
  nl_type from_type = nl_bus_type (from_bus);
  nl_type to_type;
  nl_bus to_bus;

  {
    nl_kind owner_kind = nl_object_kind (to_owner);
    nl_design to_design;
    if ( owner_kind == nl_kind_design ) {
      to_design = (nl_design) to_owner;
    }
    else {
      to_design = nl_design_object_design ((nl_design_object) to_owner);
    }

    to_type = hier_copy_type (from_type, to_design);
  }

  to_bus = nl_bus_create (new_name, to_type, member_kind, to_owner);

  FREE (new_name);

  nl_bus_for_all_members (from_bus, from_member) {
    nl_object to_member;
    nl_kind member_kind;

    nl_attr_get (member_forward, from_member, &to_member);

    ASSERT (to_member != NULL);

    member_kind = nl_object_kind (to_member);

    switch (member_kind) {
    case nl_kind_net:
      nl_bus_add_net (to_bus, (nl_net) to_member);
      break;
    case nl_kind_cell:
      nl_bus_add_cell (to_bus, (nl_cell) to_member);
      break;
    case nl_kind_refpin:
      nl_bus_add_refpin (to_bus, (nl_refpin) to_member);
      break;
    case nl_kind_port:
      nl_bus_add_port (to_bus, (nl_port) to_member);
      break;
    default:
      ASSERT (0);
    }

  } nl_end_for;

  return to_bus;
}


nl_refpin
hier_copy_refpin (nl_refpin from_refpin, nl_reference to_reference,
		  nl_refpin_attr refpin_forward)
{
  char *name = nl_refpin_name (from_refpin);
  nl_object down_port = nl_refpin_down_port (from_refpin);
  nl_refpin to_refpin = nl_refpin_create (name, down_port, to_reference);
  
  nl_refpin_attr_set (refpin_forward, from_refpin, &to_refpin);

  return to_refpin;
}


#if 0
static
void
hier_copy_refpin_to_reference (nl_reference from_ref, nl_reference to_ref)
{
  nl_bus prev_bus = NULL;
      
  nl_reference_for_all_refpins (from_ref, from_refpin) {
    char *refpin_name = nl_refpin_name (from_refpin);
    nl_bus refpin_bus = nl_refpin_bus (from_refpin);

    if ( refpin_bus == NULL ) {
      nl_object to_refpin
	= nl_reference_get_refpin_by_name (to_ref, refpin_name);

      if ( to_refpin == NULL ) {
	(void) nl_refpin_create (refpin_name, NULL, to_ref);
      }
      else if ( nl_object_kind (to_refpin) == nl_kind_bus ) {
	/* The from refpin is a scalar and the to refpin is a bus. */
	nl_bus to_refpin_bus = (nl_bus) to_refpin;
	nl_type to_bus_type = nl_bus_type (to_refpin_bus);
	int width = nl_type_width (to_bus_type);

	/* Handle this case here. */
      }
    }
    else if ( refpin_bus != prev_bus ) {
      nl_object to_refpin
	= nl_reference_get_refpin_by_name (to_ref, refpin_name);

      prev_bus = refpin_bus;

      if ( to_refpin == NULL ) {
	char *from_bus_name = nl_bus_name (refpin_bus);
	nl_type from_type = nl_bus_type (refpin_bus);
	nl_type to_type = nl_type_copy (from_type, to_design);
	nl_bus to_bus 
	  = nl_bus_create (refpin_name, to_type, nl_kind_refpin,
			   (nl_object) to_ref);
	char *bus_naming_style = nl_design_bus_naming_style (to_design);
	int name_len = strlen (refpin_name);
	int style_len = strlen (bus_naming_style);
	    
	char *name_buf = MALLOC (name_len + str_len + 16);

	nl_type_for_all_indexes (to_type, index) {
	  nl_refpin new_refpin;

	  sprintf (name_buf, bus_naming_style, from_bus_name, index);
	  new_refpin = nl_refpin_create (name_buf, NULL, to_ref);
	  nl_bus_add_refpin (to_bus, new_refpin);
	} nl_end_for;

	FREE (name_buf);
      }
      else if ( nl_object_kind (to_refpin) == nl_kind_refpin ) {
	/* The from refpin is a bus and the to refpin is a scalar. */
	/* Not yet handled. */
	ASSERT (0);
      }
    }
  } nl_end_for;
}
#endif


static
void
hier_copy_reference_pins (nl_reference from_ref, nl_reference to_ref)
{
  nl_design from_design = nl_reference_design (from_ref);
  nl_design to_design = nl_reference_design (to_ref);
  nl_refpin_attr refpin_forward
    = nl_refpin_attr_create ("copy refpin forward", from_design,
			     nl_density_dense, sizeof (nl_refpin), NULL, NULL);
  char *from_name = nl_reference_name (from_ref);
  int preserve_directions;

  if ( strcmp (from_name, "*assignment*") == 0 ||
       strncmp (from_name, "*expression_", 12) == 0 ||
       strncmp (from_name, "*process_", 9) == 0 ) {
    preserve_directions = 1;
  }
  else {
    preserve_directions = 0;
  }
    
  nl_reference_for_all_buses (from_ref, from_bus) {
    char *bus_name = nl_bus_name (from_bus);
    nl_object to_object = nl_reference_get_refpin_by_name (to_ref, bus_name);
    nl_bus to_bus;

    if ( to_object == NULL ) {
      nl_type from_type = nl_bus_type (from_bus);
      nl_type to_type = hier_copy_type (from_type, to_design);
      nl_bus new_bus = nl_bus_create (bus_name, to_type, nl_kind_refpin,
				      (nl_object) to_ref);
      char *bus_naming_style = nl_design_bus_naming_style (to_design);
      int position = 0;
      int name_len = strlen (bus_name);
      int style_len = strlen (bus_naming_style);
      char *name_buf = MALLOC (name_len + style_len + 16);

      nl_type_for_all_indexes (from_type, index) {
	nl_refpin new_refpin;
	nl_refpin from_refpin
	  = (nl_refpin) nl_bus_get_member (from_bus, position);
	nl_object from_down_port = nl_refpin_down_port (from_refpin);
	
	position++;
	
	sprintf (name_buf, bus_naming_style, bus_name, index);
	new_refpin = nl_refpin_create (name_buf, from_down_port, to_ref);
	nl_bus_add_refpin (new_bus, new_refpin);

	nl_refpin_attr_set (refpin_forward, from_refpin, &new_refpin);
      } nl_end_for;

      FREE (name_buf);

      to_bus = new_bus;
    }
    else if ( nl_object_kind (to_object) != nl_kind_bus ) {
      /* The from_refpin is a bus and the to refpin is a scalar.  Not
	 implemented yet. */
      ASSERT (0);
    }
    else {
      int from_width = nl_bus_width (from_bus);
      int to_width = nl_bus_width ((nl_bus) to_object);

      if ( from_width != to_width ) {
	/* Not yet implemented. */
	ASSERT (0);
      }

      to_bus = (nl_bus) to_object;
    }

    {
      int i;
      int width = nl_bus_width (from_bus);

      for ( i = 0; i < width; i++ ) {
	nl_refpin from_refpin = (nl_refpin) nl_bus_get_member (from_bus, i);
	nl_refpin to_refpin = (nl_refpin) nl_bus_get_member (to_bus, i);

	nl_refpin_attr_set (refpin_forward, from_refpin, &to_refpin);
      }
    }
  } nl_end_for;

  nl_reference_for_all_refpins (from_ref, from_refpin) {
    nl_refpin forwarded_refpin;
      
    nl_refpin_attr_get (refpin_forward, from_refpin, &forwarded_refpin);

    if ( forwarded_refpin == NULL ) {
      char *refpin_name = nl_refpin_name (from_refpin);
      nl_object from_down_port = nl_refpin_down_port (from_refpin);
      nl_object to_refpin
	= nl_reference_get_refpin_by_name (to_ref, refpin_name);

      if ( to_refpin == NULL ) {
	nl_refpin new_refpin
	  = nl_refpin_create (refpin_name, from_down_port, to_ref);

	if ( preserve_directions ) {
	  nl_direction from_direction = nl_refpin_direction (from_refpin);
	  nl_refpin_set_direction (new_refpin, from_direction);
	}
      }
      else if ( nl_object_kind (to_refpin) != nl_kind_refpin ) {
	/* Not yet implemented. */
	ASSERT (0);
      }
    }
  } nl_end_for;

  nl_design_remove_attr (from_design, (nl_attr) refpin_forward);
}


static
nl_ast
hier_copy_ast (nl_ast from_tree, nl_design to_design)
{
  mem_group g = nl_design_mem_group (to_design);
  mem_group prev = mem_group_set (g);
  nl_ast to_tree = nl_ast_dup (from_tree);

  mem_group_set (prev);

  return to_tree;
}


nl_reference
hier_copy_reference (nl_reference from_ref, nl_design to_design,
		     nl_reference_attr ref_forward)
{
  char *name = nl_reference_name (from_ref);
  nl_reference to_ref = nl_design_get_reference_by_name (to_design, name);

  if ( to_ref == NULL ) {
    nl_ast from_tree = nl_reference_tree (from_ref);

    nl_object down_object = nl_reference_down_design (from_ref);

    to_ref = nl_reference_create (name, to_design, down_object);

    if ( from_tree != NULL ) {
      nl_ast to_tree = hier_copy_ast (from_tree, to_design);
      nl_reference_set_tree (to_ref, to_tree);
    }

    hier_copy_reference_pins (from_ref, to_ref);
  }
  else {
    nl_object to_down_object = nl_reference_down_design (to_ref);

    if ( to_down_object == NULL ) {
      hier_copy_reference_pins (from_ref, to_ref);
    }

    /* Check the consistency of the two references. */
  }

  if ( ref_forward != NULL ) {
    nl_reference_attr_set (ref_forward, from_ref, &to_ref);
  }

  return to_ref;
}


static
void
hier_copy_pin_connection (nl_pin from_pin, nl_cell to_cell,
			  nl_net_attr net_forward)
{
  nl_net from_net = nl_pin_net (from_pin);

  if ( from_net != NULL ) {
    nl_refpin from_refpin = nl_pin_refpin (from_pin);
    char *name = nl_refpin_name (from_refpin);
    nl_reference to_ref = nl_cell_reference (to_cell);
    nl_refpin to_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (to_ref, name);
    nl_pin to_pin;
    nl_net to_net;

    ASSERT (nl_refpin_kind (to_refpin) == nl_kind_refpin);

    to_pin = nl_cell_get_pin_by_refpin (to_cell, to_refpin);

    ASSERT (to_pin != NULL);

    nl_net_attr_get (net_forward, from_net, &to_net);

    ASSERT (to_net != NULL);

    nl_pin_connect_net (to_pin, to_net);
  }
}


nl_cell
hier_copy_cell (nl_cell from_cell, nl_reference_attr ref_forward,
		nl_net_attr net_forward, char *prefix,
		nl_cell_attr cell_forward)
{
  nl_reference from_ref = nl_cell_reference (from_cell);
  nl_reference to_ref;
  nl_cell to_cell;

  nl_reference_attr_get (ref_forward, from_ref, &to_ref);

  ASSERT (to_ref != NULL);

  {
    char *name = nl_cell_name (from_cell);
    char *new_name = str_append (prefix, name, NULL);

    to_cell = nl_cell_create (new_name, to_ref);
    FREE (new_name);

    if ( cell_forward != NULL ) {
      nl_cell_attr_set (cell_forward, from_cell, &to_cell);
    }
  }

  nl_cell_for_all_pins (from_cell, from_pin) {
    hier_copy_pin_connection (from_pin, to_cell, net_forward);
  } nl_end_for;

  return to_cell;
}


nl_port
hier_copy_port (nl_port port, nl_design to_design, nl_port_attr port_forward)
{
  return NULL;
}


/*exported*/
nl_design
hier_copy_design (nl_design design, char *copy_name)
{
  nl_context context = nl_design_context (design);
  nl_design new_design = nl_design_create (copy_name, context);
  nl_net_attr net_forward
    = nl_net_attr_create ("copy net forward", design, nl_density_dense,
			  sizeof (nl_net), NULL, NULL);
  nl_cell_attr cell_forward
    = nl_cell_attr_create ("copy cell forward", design, nl_density_dense,
			   sizeof (nl_cell), NULL, NULL);
  nl_reference_attr ref_forward
    = nl_reference_attr_create ("copy reference forward", design,
				nl_density_dense, sizeof (nl_reference), NULL,
				NULL);
  nl_port_attr port_forward
    = nl_port_attr_create ("copy port forward", design, nl_density_dense,
			   sizeof (nl_port), NULL, NULL);

  nl_design_for_all_nets (design, net) {
    hier_copy_net (net, new_design, "", net_forward);
  } nl_end_for;

  nl_design_for_all_net_buses (design, bus) {
    hier_copy_bus (bus, (nl_object) new_design, "", (nl_attr) net_forward);
  } nl_end_for;

  nl_design_for_all_references (design, reference) {
    hier_copy_reference (reference, new_design, ref_forward);
  } nl_end_for;

  nl_design_for_all_cells (design, cell) {
    hier_copy_cell (cell, ref_forward, net_forward, "", cell_forward);
  } nl_end_for;

  nl_design_for_all_cell_buses (design, bus) {
    hier_copy_bus (bus, (nl_object) new_design, "", (nl_attr) cell_forward);
  } nl_end_for;

  nl_design_for_all_ports (design, port) {
    hier_copy_port (port, new_design, port_forward);
  } nl_end_for;

  nl_design_for_all_port_buses (design, bus) {
    hier_copy_bus (bus, (nl_object) new_design, "", (nl_attr) port_forward);
  } nl_end_for;

  return new_design;
}


