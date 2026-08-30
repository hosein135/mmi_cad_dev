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


int
hier_replace_cell (nl_cell cell, nl_reference new_reference)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_design design = nl_cell_design (cell);
  nl_design ref_design = nl_reference_design (new_reference);
  nl_refpin_attr refpin_attr
    = nl_refpin_attr_create (NULL, design, nl_density_sparse,
			     sizeof (nl_refpin), NULL, NULL);
  int result = 1;

  ASSERT (design == ref_design);

  /* Step 1: See if the buses on the two reference are compatible. */
  nl_reference_for_all_buses (reference, bus) {
    char *bus_name = nl_bus_name (bus);
    nl_object new_bus
      = nl_reference_get_refpin_by_name (new_reference, bus_name);
    int width = nl_bus_width (bus);
    int new_width;
    int index;

    if ( new_bus == NULL || nl_object_kind (new_bus) != nl_kind_bus ) {
      result = 0;
      goto bail;
    }

    new_width = nl_bus_width ((nl_bus) new_bus);

    if ( width != new_width ) {
      result = 0;
      goto bail;
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
  nl_reference_for_all_refpins (reference, refpin) {
    char *refpin_name;
    nl_object new_refpin;

    nl_refpin_attr_get (refpin_attr, refpin, &new_refpin);

    if ( new_refpin != NULL ) {
      continue;
    }
      
    refpin_name = nl_refpin_name (refpin);
    new_refpin = nl_reference_get_refpin_by_name (new_reference, refpin_name);

    if ( nl_object_kind (new_refpin) != nl_kind_refpin ) {
      result = 0;
      goto bail;
    }

    nl_refpin_attr_set (refpin_attr, refpin, &new_refpin);
    nl_refpin_attr_set (refpin_attr, (nl_refpin) new_refpin, &refpin);
  } nl_end_for;

  /* Step 3: Make sure all the refpins on the new reference are
     accounted for. */
  nl_reference_for_all_refpins (new_reference, new_refpin) {
    nl_refpin refpin;

    nl_refpin_attr_get (refpin_attr, new_refpin, &refpin);

    if ( refpin == NULL ) {
      result = 0;
      goto bail;
    }
  } nl_end_for;

  /* Step 4: Create a new cell and hook it up. */
  {
    char *cell_name = STRDUPA (nl_cell_name (cell));
    nl_cell new_cell = nl_cell_create ("temp cell name", new_reference);

    nl_cell_for_all_pins (cell, pin) {
      nl_net net = nl_pin_net (pin);
      nl_refpin refpin = nl_pin_refpin (pin);
      nl_refpin new_refpin;
      nl_pin new_pin;

      nl_refpin_attr_get (refpin_attr, refpin, &new_refpin);

      new_pin = nl_cell_get_pin_by_refpin (new_cell, new_refpin);

      nl_pin_connect_net (new_pin, net);
    } nl_end_for;

    nl_design_remove_cell (design, cell);
    nl_cell_rename (new_cell, cell_name);
  }

 bail:
  nl_design_remove_attr (design, (nl_attr) refpin_attr);

  return result;
}
