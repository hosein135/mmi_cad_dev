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
#include "nl.h"
#include "nl_int.h"


/**
   Create a new instance (cell) of reference 'reference' named 'name'.
   This routine also creates a number of pins depending on the number
   of pins on the specified reference.  This routine uses the pins to
   populate the inputs, outputs, and inouts of the new cell.
**/
/*exported*/
nl_cell
nl_cell_create (char *name, nl_reference reference)
{
  nl_design design = nl_reference_design (reference);
  nl_cell result = nl_design_alloc_cell (design, name);

  result->design = design;
  result->reference = reference;
  result->bus = NULL;
  result->file = NULL;
  result->line = 0;
  
  {
    int num_inputs = nl_reference_input_width (reference);
    int num_outputs = nl_reference_output_width (reference);
    int num_inouts = nl_reference_inout_width (reference);
    mem_group g = nl_design_mem_group (design);

    if ( num_inputs > 0 )
      result->inputs = AR_GNEW (num_inputs, nl_pin, g);
    else
      result->inputs = NULL;

    if ( num_outputs > 0 )
      result->outputs = AR_GNEW (num_outputs, nl_pin, g);
    else
      result->outputs = NULL;

    if( num_inouts > 0 )
      result->inouts = AR_GNEW (num_inouts, nl_pin, g);
    else
      result->inouts = NULL;
  }

  nl_reference_for_all_inputs (reference, refpin) {
    (void) nl_pin_create (refpin, (nl_cell_or_port) result);
  } nl_end_for;

  nl_reference_for_all_outputs (reference, refpin) {
    (void) nl_pin_create (refpin, (nl_cell_or_port) result);
  } nl_end_for;

  nl_reference_for_all_inouts (reference, refpin) {
    (void) nl_pin_create (refpin, (nl_cell_or_port) result);
  } nl_end_for;

  nl_reference_add_instance (reference, result);

  nl_design_for_all_idesigns (design, idesign) {
    nl_icell_create (result, idesign, NULL);
  } nl_end_for;

  return result;
}


/*internal*/
void
nl_cell_free_insides (nl_cell cell)
{
  if ( cell->inputs != NULL )
    ar_free (cell->inputs);

  if ( cell->outputs != NULL )
    ar_free (cell->outputs);

  if ( cell->inouts != NULL )
    ar_free (cell->inouts);

  FREE (cell->name);
}


/*internal*/
void
nl_cell_free (nl_cell cell)
{
  nl_bus bus = cell->bus;

  if ( bus != NULL ) {
    int offset = cell->bus_offset;
    nl_bus_remove_member (bus, offset);
  }

  if ( cell->inputs != NULL ) {
    ar_for_all (cell->inputs, nl_pin, pin) {
      nl_pin_free (pin);
    } ar_end_for;
  }

  if ( cell->outputs != NULL ) {
    ar_for_all (cell->outputs, nl_pin, pin) {
      nl_pin_free (pin);
    } ar_end_for;
  }

  if ( cell->inouts != NULL ) {
    ar_for_all (cell->inouts, nl_pin, pin) {
      nl_pin_free (pin);
    } ar_end_for;
  }

  nl_cell_free_insides (cell);

  nl_reference_remove_instance (cell->reference, cell);
  nl_design_free_object (cell->design, (nl_object) cell);
}


/**
   Disconnect all nets from cell 'cell'.  The cell will still have all
   its pins, but none of them will be connected to nets.
**/
/*exported*/
void
nl_cell_disconnect (nl_cell cell)
{
  nl_cell_for_all_pins (cell, pin) {
    nl_pin_disconnect (pin);
  } nl_end_for;
}


/*internal*/
void
nl_cell_add_pin (nl_cell cell, nl_pin pin)
{
  nl_refpin refpin = nl_pin_refpin (pin);
  nl_direction direction = nl_refpin_direction (refpin);

  switch (direction) {
  case nl_direction_in:
    if ( cell->inputs == NULL ) {
      cell->inputs = AR_NEW (1, nl_pin);
    }
    ar_add (cell->inputs, &pin);
    break;
  case nl_direction_out:
    if ( cell->outputs == NULL ) {
      cell->outputs = AR_NEW (1, nl_pin);
    }
    ar_add (cell->outputs, &pin);
    break;
  case nl_direction_inout:
  case nl_direction_unknown:
    if ( cell->inouts == NULL ) {
      cell->inouts = AR_NEW (1, nl_pin);
    }
    ar_add (cell->inouts, &pin);
    break;
  default:
    ASSERT (0);
  }
}


/*exported*/
nl_pin
nl_cell_get_pin_by_name (nl_cell cell, char *name)
{
  nl_reference reference = cell->reference;
  nl_object object = nl_reference_get_refpin_by_name (reference, name);

  if ( nl_object_kind (object) == nl_kind_refpin ) {
    nl_refpin refpin = (nl_refpin) object;
    nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);

    return pin;
  }
  else {
    return NULL;
  }
}


/**
   Return the pin on cell 'cell' that corresponds to pin 'refpin' on
   the cell's reference.  It is assumed that 'refpin' belongs to the
   cell's reference.
**/
/*exported*/
nl_pin
nl_cell_get_pin_by_refpin (nl_cell cell, nl_refpin refpin)
{
  nl_direction direction = nl_refpin_direction (refpin);
  int position = nl_refpin_position (refpin);
  nl_pin pin;

  ASSERT (nl_refpin_reference (refpin) == nl_cell_reference (cell));

  switch (direction) {
  case nl_direction_in:
    pin = AR_REF (cell->inputs, nl_pin, position);
    break;
  case nl_direction_out:
    pin = AR_REF (cell->outputs, nl_pin, position);
    break;
  case nl_direction_inout:
  case nl_direction_unknown:
    pin = AR_REF (cell->inouts, nl_pin, position);
    break;
  default:
    ASSERT (0);
  }

  return pin;
}


/*internal*/
void
nl_cell_half_disconnect (nl_cell cell)
{
  nl_cell_for_all_pins (cell, pin) {
    nl_pin_half_disconnect (pin);
  } nl_end_for;
}


/*internal*/
void
nl_cell_half_reconnect (nl_cell cell)
{
  nl_cell_for_all_pins (cell, pin) {
    nl_pin_half_reconnect (pin);
  } nl_end_for;
}


/*internal*/
void
nl_cell_update_pins (nl_cell cell)
{
  nl_design design = cell->design;
  nl_reference reference = cell->reference;
  int num_inputs = nl_reference_input_width (reference);
  int num_outputs = nl_reference_output_width (reference);
  int num_inouts = nl_reference_inout_width (reference);
  int num_pins = num_inputs + num_outputs + num_inouts;
  nl_refpin_attr refpin_pin
    = nl_refpin_attr_create (NULL, design, nl_density_sparse, sizeof (nl_pin),
			     NULL, NULL);
  int num_cell_pins = 0;

  if ( cell->inputs != NULL ) {
    ar_for_all (cell->inputs, nl_pin, pin) {
      nl_refpin refpin = nl_pin_refpin (pin);
      nl_refpin_attr_set (refpin_pin, refpin, &pin);
      num_cell_pins++;
    } ar_end_for;
  }

  if ( cell->outputs != NULL ) {
    ar_for_all (cell->outputs, nl_pin, pin) {
      nl_refpin refpin = nl_pin_refpin (pin);
      nl_refpin_attr_set (refpin_pin, refpin, &pin);
      num_cell_pins++;
    } ar_end_for;
  }

  if ( cell->inouts != NULL ) {
    ar_for_all (cell->inouts, nl_pin, pin) {
      nl_refpin refpin = nl_pin_refpin (pin);
      nl_refpin_attr_set (refpin_pin, refpin, &pin);
      num_cell_pins++;
    } ar_end_for;
  }

  ASSERT (num_cell_pins == num_pins);

  if ( cell->inputs != NULL )
    ar_free (cell->inputs);

  if ( cell->outputs != NULL )
    ar_free (cell->outputs);

  if ( cell->inouts != NULL )
    ar_free (cell->inouts);

  {
    mem_group g = nl_design_mem_group (cell->design);

    cell->inputs = ar_alloc_from_group (num_inputs, sizeof (nl_pin), g);
    cell->outputs = ar_alloc_from_group (num_outputs, sizeof (nl_pin), g);
    cell->inouts = ar_alloc_from_group (num_inouts, sizeof (nl_pin), g);
  }

  nl_reference_for_all_refpins (reference, refpin) {
    nl_pin pin;
    
    nl_refpin_attr_get (refpin_pin, refpin, &pin);
    nl_cell_add_pin (cell, pin);
  } nl_end_for;

  nl_design_remove_attr (design, (nl_attr) refpin_pin);
}


/*internal*/
void
nl_cell_set_bus_and_offset (nl_cell cell, nl_bus bus, int offset)
{
  cell->bus = bus;
  cell->bus_offset = offset;
}


/**
   Change the name of cell 'cell' to 'new_name'.
**/
/*exported*/
void
nl_cell_rename (nl_cell cell, char *new_name)
{
  nl_design design = cell->design;
  mem_group design_group = nl_design_mem_group (design);
  char *old_name = cell->name;

  cell->name = GSTRDUP (new_name, design_group);
  nl_design_rename_object (design, (nl_named_object) cell, old_name);

  FREE (old_name);
}


/*exported*/
void
nl_cell_set_reference (nl_cell cell, nl_reference new_reference)
{
  nl_design design = nl_cell_design (cell);
  nl_design ref_design = nl_reference_design (new_reference);
  nl_reference old_reference = nl_cell_reference (cell);
  nl_refpin_attr refpin_attr
    = nl_refpin_attr_create (NULL, design, nl_density_sparse,
			     sizeof (nl_refpin), NULL, NULL);

  /* Both the old and new references must either be unlinked, or
     linked to libcells. */
  {
    nl_object down_design = nl_reference_down_design (old_reference);
    ASSERT (down_design == NULL || nl_design_libcell ((nl_design) down_design));
  }
  {
    nl_object down_design = nl_reference_down_design (new_reference);
    ASSERT (down_design == NULL || nl_design_libcell ((nl_design) down_design));
  }

  ASSERT (design == ref_design);

  /* Step 1: See if the buses on the two reference are compatible. */
  nl_reference_for_all_buses (old_reference, bus) {
    char *bus_name = nl_bus_name (bus);
    nl_object new_bus
      = nl_reference_get_refpin_by_name (new_reference, bus_name);
    int width = nl_bus_width (bus);
    int new_width;
    int index;

    if ( new_bus == NULL || nl_object_kind (new_bus) != nl_kind_bus ) {
      ASSERT (0);
    }

    new_width = nl_bus_width ((nl_bus) new_bus);

    if ( width != new_width ) {
      ASSERT (0);
    }

    index = 0;
    
    nl_bus_for_all_refpin_members (bus, bus_refpin) {
      nl_refpin new_refpin
	= (nl_refpin) nl_bus_get_member ((nl_bus) new_bus, index);

      nl_refpin_attr_set (refpin_attr, bus_refpin, &new_refpin);
      nl_refpin_attr_set (refpin_attr, new_refpin, &bus_refpin);
    } nl_end_for;
  } nl_end_for;

  /* Step 2: Look at all remaining refpins and make sure they exist on
     the new reference. */
  nl_reference_for_all_refpins (old_reference, old_refpin) {
    char *refpin_name;
    nl_object new_refpin;

    nl_refpin_attr_get (refpin_attr, old_refpin, &new_refpin);

    if ( new_refpin != NULL ) {
      continue;
    }
      
    refpin_name = nl_refpin_name (old_refpin);
    new_refpin = nl_reference_get_refpin_by_name (new_reference, refpin_name);

    if ( nl_object_kind (new_refpin) != nl_kind_refpin ) {
      ASSERT (0);
    }

    nl_refpin_attr_set (refpin_attr, old_refpin, &new_refpin);
    nl_refpin_attr_set (refpin_attr, (nl_refpin) new_refpin, &old_refpin);
  } nl_end_for;

  /* Step 3: Make sure all the refpins on the new reference are
     accounted for. */
  nl_reference_for_all_refpins (new_reference, new_refpin) {
    nl_refpin refpin;

    nl_refpin_attr_get (refpin_attr, new_refpin, &refpin);

    if ( refpin == NULL ) {
      ASSERT (0);
    }
  } nl_end_for;

  nl_cell_for_all_pins (cell, pin) {
    nl_refpin refpin = nl_pin_refpin (pin);
    nl_refpin new_refpin;

    nl_refpin_attr_get (refpin_attr, refpin, &new_refpin);

    nl_pin_set_refpin (pin, new_refpin);
  } nl_end_for;

  nl_design_remove_attr (design, (nl_attr) refpin_attr);

  nl_reference_remove_instance (old_reference, cell);

  cell->reference = new_reference;

  nl_reference_add_instance (new_reference, cell);

  nl_cell_update_pins (cell);
}


/*exported*/
void
nl_cell_set_file_line (nl_cell cell, char *file, int line)
{
  ASSERT (mem_group_of_pointer (cell) == mem_group_of_pointer (file));

  cell->file = file;
  cell->line = line;
}
