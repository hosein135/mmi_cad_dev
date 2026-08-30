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
#include "nl_int.h"


/**
   Create a new reference named 'name' within design 'design'.  The
   down design of the reference will be 'down_design'.  This routine
   does not create any pins on the reference.
**/
/*exported*/
nl_reference
nl_reference_create (char *name, nl_design design, nl_object down_design)
{
  nl_reference result = nl_design_alloc_reference (design, name);
  mem_group design_group = nl_design_mem_group (design);
  mem_group prev_group = mem_group_set (design_group);
  nl_context context = nl_design_context (design);

  result->design = design;
  result->down_design = down_design;
  result->refpins_by_name = ht_alloc (4, ht_hash_string, ht_compare_string,
				      NULL, NULL);
  result->refpins_attr = ht_new_attribute (result->refpins_by_name,
					   sizeof (nl_object), NULL, NULL);

  result->refpins = nl_dll_create (context, nl_kind_refpin);
  result->buses = nl_dll_create (context, nl_kind_bus);

  result->instances = AR_NEW (4, nl_cell);

  result->inputs = AR_NEW (4, nl_refpin);
  result->outputs = AR_NEW (4, nl_refpin);
  result->inouts = AR_NEW (4, nl_refpin);

  result->tree = NULL;
  result->parameters = ar_alloc (0, sizeof (nl_ast));

  mem_group_set (prev_group);
  return result;
}


/*internal*/
void
nl_reference_free (nl_reference reference)
{
  nl_design design = reference->design;

  nl_reference_for_all_refpins (reference, refpin) {
    nl_refpin_free (refpin);
  } nl_end_for;

  nl_reference_for_all_buses (reference, bus) {
    nl_bus_free (bus);
  } nl_end_for;

  nl_dll_free (reference->refpins);
  nl_dll_free (reference->buses);

  ht_free (reference->refpins_by_name);

  ar_free (reference->inputs);
  ar_free (reference->outputs);
  ar_free (reference->inouts);

  ar_free (reference->instances);

  FREE (reference->name);

  nl_design_free_object (design, (nl_object) reference);
}


/*internal*/
void
nl_reference_free_object (nl_reference reference, nl_object obj)
{
  nl_kind kind = nl_object_kind (obj);

  switch ( kind ) {
  case nl_kind_refpin:
  case nl_kind_bus:
    FREE (obj);
    break;

  default:
    ASSERT (0);
  }
}


static
ar
nl_reference_get_refpin_array (nl_reference reference, nl_direction direction)
{
  switch (direction) {
  case nl_direction_in: return reference->inputs;
  case nl_direction_out: return reference->outputs;
  case nl_direction_inout:   
  case nl_direction_unknown: return reference->inouts;
  default:
    ASSERT (0);
  }
}


/**
   Add reference pin 'refpin' to reference 'reference'.
**/
/*internal*/
void
nl_reference_add_refpin (nl_reference reference, nl_refpin refpin)
{
  char *name = nl_refpin_name (refpin);
  nl_direction direction = nl_refpin_direction (refpin);
  ht_entry hte = ht_insert (reference->refpins_by_name, name);
  ar refpin_ar = nl_reference_get_refpin_array (reference, direction);

  ht_set_attribute_for_entry (reference->refpins_attr, hte, &refpin);

  nl_dll_add (reference->refpins, (nl_dll) refpin);

  nl_refpin_set_position (refpin, ar_size (refpin_ar));
  ar_add (refpin_ar, &refpin);

  nl_reference_for_all_instances (reference, cell) {
    nl_pin_create (refpin, (nl_cell_or_port) cell);
  } nl_end_for;
}


/**
   Add refpin bus 'bus' to reference 'reference'.
**/
/*exported*/
void
nl_reference_add_bus (nl_reference reference, nl_bus bus)
{
  char *name = nl_bus_name (bus);
  ht_entry hte = ht_insert (reference->refpins_by_name, name);

  ht_set_attribute_for_entry (reference->refpins_attr, hte, &bus);
  nl_dll_add (reference->buses, (nl_dll) bus);
}


/*exported*/
void
nl_reference_remove_refpin (nl_reference ref, nl_refpin refpin)
{
  char *name = nl_refpin_name (refpin);
  nl_direction direction = nl_refpin_direction (refpin);
  int index = nl_refpin_position (refpin);
  ar refpin_ar = nl_reference_get_refpin_array (ref, direction);

  ht_delete (ref->refpins_by_name, name);
  nl_dll_remove (ref->refpins, (nl_dll) refpin);

  ar_remove_indexed_element (refpin_ar, index);

  if ( index < ar_size (refpin_ar) ) {
    nl_refpin moved_refpin;

    ar_ref (refpin_ar, index, &moved_refpin);

    nl_refpin_set_position (moved_refpin, index);
  }

  nl_reference_for_all_instances (ref, cell) {
    ar cell_pins;
    nl_pin toasted_pin;

    switch ( direction ) {
    case nl_direction_in:
      cell_pins = nl_cell_inputs (cell);
      break;
    case nl_direction_out:
      cell_pins = nl_cell_outputs (cell);
      break;
    case nl_direction_inout:
    case nl_direction_unknown:
      cell_pins = nl_cell_inouts (cell);
      break;
    default:
      ASSERT (0);
    }

    ar_ref (cell_pins, index, &toasted_pin);
    nl_pin_free (toasted_pin);
    ar_remove_indexed_element (cell_pins, index);
  } nl_end_for;
}


/*internal*/
void
nl_reference_add_instance (nl_reference reference, nl_cell cell)
{
  ar_add (reference->instances, &cell);
}


/*internal*/
void
nl_reference_remove_instance (nl_reference reference, nl_cell cell)
{
  ar_remove_element (reference->instances, &cell);
}


/**
   Return the number of instances (cells) whose reference is 'reference'.
**/
/*exported*/
int
nl_reference_num_instances (nl_reference reference)
{
  int result = ar_size (reference->instances);

  return result;
}


/**
   Return the refpin named 'name' on reference 'reference'.  If there
   is no pin with that name on the reference, return NULL.
**/
/*exported*/
nl_object
nl_reference_get_refpin_by_name (nl_reference reference, char *name)
{
  nl_object refpin_or_bus;

  ht_get_attribute (reference->refpins_attr, name, &refpin_or_bus);

  return refpin_or_bus;
}


/**
   Return the number of input pins on reference 'reference'.
**/
/*exported*/
int
nl_reference_input_width (nl_reference reference)
{
  int result = ar_size (reference->inputs);

  return result;
}


/**
   Return the number of output pins on reference 'reference'.
**/
/*exported*/
int
nl_reference_output_width (nl_reference reference)
{
  int result = ar_size (reference->outputs);

  return result;
}


/**
   Return the number of inout pins on reference 'reference'.
**/
/*exported*/
int
nl_reference_inout_width (nl_reference reference)
{
  int result = ar_size (reference->inouts);

  return result;
}


static
void
nl_reference_place_refpin_after (nl_reference reference, nl_refpin refpin,
				 nl_refpin after)
{
  nl_dll_remove (reference->refpins, (nl_dll) refpin);
  nl_dll_insert_after (reference->refpins, (nl_dll) refpin, (nl_dll) after);
}


static
void
nl_reference_zero_unconnected_bus_inputs (nl_cell cell)
{
  nl_bus prev_bus = NULL;
  int bus_is_connected = 0;
  int prev_is_connected = 0;
  nl_net zero_net = NULL;

  nl_cell_for_all_pins (cell, pin) {
    nl_refpin refpin = nl_pin_refpin (pin);
    nl_bus refpin_bus = nl_refpin_bus (refpin);
    nl_direction direction = nl_refpin_direction (refpin);

    if ( refpin_bus == NULL || direction != nl_direction_in ) {
      continue;
    }

    if ( refpin_bus == prev_bus ) {
      nl_net net = nl_pin_net (pin);

      if ( bus_is_connected ) {
	if ( net == NULL ) {
	  prev_is_connected = 0;

	  if ( zero_net == NULL ) {
	    nl_design design = nl_cell_design (cell);

	    zero_net = nl_design_get_net_by_name (design, "1'b0");

	    if ( zero_net == NULL ) {
	      zero_net = nl_net_create ("1'b0", nl_wireclass_wire, design);
	    }
	  }
	  nl_pin_connect_net (pin, zero_net);
	}
	else {
	  /* If this pin is connected, the previous one should also be
             connected. */
	  ASSERT (prev_is_connected);
	}
      }
      else {
	/* If the bus is not connected, none of its pins should be
           connected. */
	ASSERT (net == NULL);
      }
    }
    else {
      nl_net net = nl_pin_net (pin);
	  
      prev_bus = refpin_bus;

      if ( net != NULL ) {
	bus_is_connected = 1;
	prev_is_connected = 1;
      }
      else {
	bus_is_connected = 0;
	prev_is_connected = 0;
      }
    }
  } nl_end_for;
}


static
void
nl_reference_set_refpin_type (nl_reference reference, char *name, nl_type type)
{
  nl_design design = reference->design;
  nl_object refpin = nl_reference_get_refpin_by_name (reference, name);

  if ( refpin == NULL ) {
    /* Need to create a refpin of the proper type. */
    nl_type refpin_type = nl_type_copy (type, (nl_object) design);
    nl_bus refpin_bus = nl_bus_create (name, refpin_type, nl_kind_refpin,
				       (nl_object) reference);
    char *bus_naming_style = nl_design_bus_naming_style (design);
    int name_len = strlen (name);
    int style_len = strlen (bus_naming_style);
    char *name_buf = MALLOC (name_len + style_len + 16);

    nl_type_for_all_indexes (refpin_type, index) {
      nl_refpin new_refpin;

      sprintf (name_buf, bus_naming_style, name, index);
      new_refpin = nl_refpin_create (name_buf, NULL, reference);
      nl_bus_add_refpin (refpin_bus, new_refpin);
    } nl_end_for;

    FREE (name_buf);
  }
  else if ( nl_object_kind (refpin) == nl_kind_refpin ) {
    /* Handle the case in which the port is a bus and the refpin
       is a scalar.  This can happen if the port is a single-bit
       bus. */
    nl_type new_refpin_type = nl_type_copy (type, (nl_object) design);
    int right = nl_type_right (new_refpin_type);
    int name_len = strlen (name);
    char *bus_naming_style = nl_design_bus_naming_style (design);
    int style_len = strlen (bus_naming_style);
    char *new_refpin_name = MALLOC (name_len + style_len + 16);
    nl_bus refpin_bus;
    nl_refpin last_refpin = NULL;

    nl_refpin_rename ((nl_refpin) refpin, " ");

    refpin_bus = nl_bus_create (name, new_refpin_type, nl_kind_refpin,
				(nl_object) reference);

    nl_type_for_all_indexes (new_refpin_type, index) {
      nl_refpin new_refpin;

      sprintf (new_refpin_name, bus_naming_style, name, index);

      if ( index == right ) {
	nl_refpin_rename ((nl_refpin) refpin, new_refpin_name);
	new_refpin = (nl_refpin) refpin;
      }
      else {
	new_refpin = nl_refpin_create (new_refpin_name, NULL, reference);
      }

      nl_bus_add_refpin (refpin_bus, new_refpin);

      if ( last_refpin != NULL ) {
	nl_reference_place_refpin_after (reference, new_refpin,
					 last_refpin);
      }

      last_refpin = new_refpin;
    } nl_end_for;

    FREE (new_refpin_name);
  }
  else if ( nl_object_kind (refpin) == nl_kind_bus ) {
    /* Both the port and the refpin are buses, match the port type
       to the refpin type. */
    nl_bus refpin_bus = (nl_bus) refpin;
    nl_type refpin_type = nl_bus_type ((nl_bus) refpin);
    nl_type new_refpin_type = nl_type_copy (type, (nl_object) design);

    /* Are the types different?  If so, convert the refpin to the
       port type. */

    if ( refpin_type != new_refpin_type ) {
      int width = nl_type_width (refpin_type);
      int new_width = nl_type_width (new_refpin_type);
      nl_design design = nl_reference_design (reference);
      char *bus_naming_style = nl_design_bus_naming_style (design);
      int name_len = strlen (name);
      int style_len = strlen (bus_naming_style);
      char *name_buf = MALLOC (name_len + style_len + 16);
      int i, j;
      nl_refpin last_refpin = NULL;

      /* First rename all the refpins to some impossible name, so
	 that when we go to rename them, we won't get name
	 collisions partway through. */
      i = 0;
      nl_bus_for_all_refpin_members (refpin_bus, bus_refpin) {
	sprintf (name_buf, bus_naming_style, " ", i);
	nl_refpin_rename (bus_refpin, name_buf);
	last_refpin = bus_refpin;
	i++;
      } nl_end_for;

      for ( j = 0; j < new_width - width; j++ ) {
	nl_refpin new_refpin;

	sprintf (name_buf, bus_naming_style, " ", i);
	new_refpin = nl_refpin_create (name_buf, NULL, reference);
	nl_bus_add_refpin (refpin_bus, new_refpin);
	nl_reference_place_refpin_after (reference, new_refpin,
					 last_refpin);
	last_refpin = new_refpin;
	i++;
      }

      nl_type_for_all_indexes (new_refpin_type, index) {
	int offset;
	int flag
	  = nl_type_get_offset_for_index (new_refpin_type, index, &offset);
	nl_refpin bus_refpin
	  = (nl_refpin) nl_bus_get_member (refpin_bus, offset);

	ASSERT (flag);
	    
	sprintf (name_buf, bus_naming_style, name, index);
	nl_refpin_rename (bus_refpin, name_buf);
      } nl_end_for;

      FREE (name_buf);
	  
      nl_bus_set_type (refpin_bus, new_refpin_type);
    }
  }
  else {
    ASSERT (0);
  }
}


static
void
nl_reference_finish_linking (nl_reference reference)
{
  /* Step 4. Adjust the inputs, outputs, and inouts lists
     accordingly. */
  ar_make_size (reference->inputs, 0);
  ar_make_size (reference->outputs, 0);
  ar_make_size (reference->inouts, 0);

  nl_reference_for_all_refpins (reference, refpin) {
    nl_direction direction = nl_refpin_direction (refpin);

    switch (direction) {
    case nl_direction_in:
      nl_refpin_set_position (refpin, ar_size (reference->inputs));
      ar_add (reference->inputs, &refpin);
      break;
    case nl_direction_out:
      nl_refpin_set_position (refpin, ar_size (reference->outputs));
      ar_add (reference->outputs, &refpin);
      break;
    case nl_direction_inout:
    case nl_direction_unknown:
      nl_refpin_set_position (refpin, ar_size (reference->inouts));
      ar_add (reference->inouts, &refpin);
      break;
    default:
      ASSERT (0);
    }
  } nl_end_for;

  /* Step 5. Adjust the inputs, outputs, and inouts lists
     on all cells that are instances of this reference. */
  nl_reference_for_all_instances (reference, cell) {
    nl_cell_update_pins (cell);
  } nl_end_for;

  /* Step 6. Remember Step 2?  Here we reconnect the pins to their nets. */
  nl_reference_for_all_instances (reference, cell) {
    nl_cell_half_reconnect (cell);

    /* Here we also take care of the Verilog feature that says that
       unconnected high-order bus inputs should be set to zero. */
    nl_reference_zero_unconnected_bus_inputs (cell);
  } nl_end_for;

  {
    nl_design up_design = reference->design;

    nl_design_for_all_idesigns (up_design, up_idesign) {
      nl_reference_for_all_instances (reference, cell) {
	nl_icell icell = nl_idesign_get_icell (up_idesign, cell);
	nl_idesign down_idesign = nl_icell_down_design (icell);

	if ( down_idesign == NULL ) {
	  nl_icell_link (icell);
	}
	else {
	  ASSERT (0);
	}
      } nl_end_for;
    } nl_end_for;
  }
}

static
void
nl_reference_link_design (nl_reference reference, nl_design down_design)
{
  nl_bus prev_bus = NULL;

  /* Step 1. Set the type of all refpin buses to the types of the
     corresponding port buses. */
  nl_design_for_all_ports (down_design, port) {
    nl_bus port_bus = nl_port_bus (port);

    if ( port_bus != NULL && port_bus == prev_bus )
      continue;

    prev_bus = port_bus;

    if ( port_bus != NULL ) {
      char *port_bus_name = nl_bus_name (port_bus);
      nl_type port_bus_type = nl_bus_type (port_bus);

      nl_reference_set_refpin_type (reference, port_bus_name, port_bus_type);
    }
    else {
      /* The port is not a bus.  Just see if we need to create a
         refpin. */
      char *port_name = nl_port_name (port);
      nl_object refpin
	= nl_reference_get_refpin_by_name (reference, port_name);

      if ( refpin == NULL ) {
	(void) nl_refpin_create (port_name, NULL, reference);
      }
    }
  } nl_end_for;

  /* Step 2. Do a "half disconnect" on all instances of this
     reference.  Since the direction of the pins on these cells are
     going to change, the fanins and fanouts of the nets that the
     cell's pins are connected to are going to change. */
  nl_reference_for_all_instances (reference, cell) {
    nl_cell_half_disconnect (cell);
  } nl_end_for;

  /* Step 3. Set the direction of all refpins to the direction of the
     corresponding ports. */
  nl_reference_for_all_refpins (reference, refpin) {
    char *name = nl_refpin_name (refpin);
    nl_object port
      = (nl_object) nl_design_get_port_by_name (down_design, name);
    nl_direction port_dir;

    ASSERT (nl_object_kind (port) == nl_kind_port);

    port_dir = nl_port_direction ((nl_port) port);

    nl_refpin_set_direction_no_update (refpin, port_dir);
    nl_refpin_set_down_port (refpin, (nl_object) port);
  } nl_end_for;

  nl_reference_finish_linking (reference);

  /* Step 7. Set the down_design of this reference. */
  reference->down_design = (nl_object) down_design;

}


static
void
nl_reference_link_libcell (nl_reference reference, nl_libcell libcell)
{
  nl_bus prev_bus = NULL;

  /* Step 2. Set the type of all refpin buses to the types of the
     corresponding port buses. */
  nl_libcell_for_all_libpins (libcell, libpin) {
    nl_bus libpin_bus = nl_libpin_bus (libpin);

    if ( libpin_bus != NULL && libpin_bus == prev_bus )
      continue;

    prev_bus = libpin_bus;

    if ( libpin_bus != NULL ) {
      char *libpin_bus_name = nl_bus_name (libpin_bus);
      nl_type libpin_type = nl_bus_type (libpin_bus);

      nl_reference_set_refpin_type (reference, libpin_bus_name, libpin_type);
    }
    else {
      /* The libpin is not a bus.  Just see if we need to create a
         refpin. */
      nl_use use = nl_libpin_use (libpin);

      if ( use != nl_use_power && use != nl_use_ground ) {
	char *libpin_name = nl_libpin_name (libpin);
	nl_object refpin
	  = nl_reference_get_refpin_by_name (reference, libpin_name);

	if ( refpin == NULL ) {
	  (void) nl_refpin_create (libpin_name, NULL, reference);
	}
      }
    }
  } nl_end_for;

  /* Step 1. Do a "half disconnect" on all instances of this
     reference.  Since the direction of the pins on these cells are
     going to change, the fanins and fanouts of the nets that the
     cell's pins are connected to are going to change. */
  nl_reference_for_all_instances (reference, cell) {
    nl_cell_half_disconnect (cell);
  } nl_end_for;

  /* Step 3. Set the direction of all refpins to the direction of the
     corresponding ports. */
  nl_reference_for_all_refpins (reference, refpin) {
    char *name = nl_refpin_name (refpin);
    nl_libpin libpin
      = (nl_libpin) nl_libcell_get_libpin_by_name (libcell, name);
    nl_direction libpin_dir = nl_libpin_direction (libpin);

    nl_refpin_set_direction_no_update (refpin, libpin_dir);
    nl_refpin_set_down_port (refpin, (nl_object) libpin);
  } nl_end_for;

  nl_reference_finish_linking (reference);

  /* Step 7. Set the down_design of this reference. */
  reference->down_design = (nl_object) libcell;

}


/*exported*/
void
nl_reference_link (nl_reference reference, nl_object down_object)
{
  nl_kind obj_kind = nl_object_kind (down_object);

  if ( obj_kind == nl_kind_design ) {
    nl_reference_link_design (reference, (nl_design) down_object);
  }
  else if ( obj_kind == nl_kind_libcell ) {
    nl_reference_link_libcell (reference, (nl_libcell) down_object);
  }
  else {
    error ("cannot link a reference (%s) to an object of type %s",
	   nl_reference_name (reference), nl_kind_to_string (obj_kind));
  }
}


/*exported*/
void
nl_reference_unlink (nl_reference reference)
{
  nl_reference_for_all_instances (reference, cell) {
    nl_cell_half_disconnect (cell);
  } nl_end_for;

  ar_make_size (reference->inputs, 0);
  ar_make_size (reference->outputs, 0);
  ar_make_size (reference->inouts, 0);

  nl_reference_for_all_refpins (reference, refpin) {
    nl_refpin_set_direction_no_update (refpin, nl_direction_unknown);
    nl_refpin_set_down_port (refpin, NULL);
    nl_refpin_set_position (refpin, ar_size (reference->inouts));
    ar_add (reference->inouts, &refpin);
  } nl_end_for;

  nl_reference_for_all_instances (reference, cell) {
    nl_cell_update_pins (cell);
    nl_cell_half_reconnect (cell);
  } nl_end_for;

  reference->down_design = NULL;
}


/*exported*/
void
nl_reference_rename (nl_reference reference, char *new_name)
{
  nl_design design = reference->design;
  mem_group design_group = nl_design_mem_group (design);
  char *old_name = reference->name;

  reference->name = GSTRDUP (new_name, design_group);
  nl_design_rename_object (design, (nl_named_object) reference, old_name);

  FREE (old_name);
}


/*internal*/
void
nl_reference_rename_refpin (nl_reference reference, nl_refpin refpin,
			    char *old_name)
{
  char *new_name = nl_refpin_name (refpin);
  ht_entry hte = ht_replace (reference->refpins_by_name, old_name, new_name);

  ASSERT (hte != ht_null);
}


/*exported*/
void
nl_reference_set_tree (nl_reference reference, nl_ast tree)
{
  reference->tree = tree;
}


/*exported*/
void
nl_reference_add_parameter (nl_reference reference, int value)
{
  ar_add (reference->parameters, &value);
}


/*internal*/
void
nl_reference_update_refpin_direction (nl_reference reference, nl_refpin refpin,
				      nl_direction old_direction)
{
  nl_direction new_direction = nl_refpin_direction (refpin);
  int old_position = nl_refpin_position (refpin);
  ar old_refpin_ar = nl_reference_get_refpin_array (reference, old_direction);
  ar new_refpin_ar = nl_reference_get_refpin_array (reference, new_direction);
  int new_position;

  nl_reference_for_all_instances (reference, cell) {
    nl_cell_half_disconnect (cell);
  } nl_end_for;

  ar_remove_indexed_element (old_refpin_ar, old_position);

  if ( old_position < ar_size (old_refpin_ar) ) {
    nl_refpin moved_refpin;
    ar_ref (old_refpin_ar, old_position, &moved_refpin);
    nl_refpin_set_position (moved_refpin, old_position);
  }

  new_position = ar_size (new_refpin_ar);
  nl_refpin_set_position (refpin, new_position);
  ar_add (new_refpin_ar, &refpin);

  nl_reference_for_all_instances (reference, cell) {
    nl_cell_update_pins (cell);
    nl_cell_half_reconnect (cell);
  } nl_end_for;
}
