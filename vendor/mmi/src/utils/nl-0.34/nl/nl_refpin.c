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
   Create a new refpin named 'name' on reference 'reference' that
   corresponds to 'down_port' on the down design of the reference.
   'down_port' may be NULL, in which case the refpin will be unlinked
   and its direction will be "unknown."
**/
/*exported*/
nl_refpin
nl_refpin_create (char *name, nl_object down_port, nl_reference reference)
{
  nl_design design = nl_reference_design (reference);
  nl_refpin result = nl_design_alloc_refpin (design, name);

  if ( down_port != NULL ) {
    nl_kind down_port_kind = nl_object_kind (down_port);
    nl_direction direction;

    if ( down_port_kind == nl_kind_port ) {
      nl_port port = (nl_port) down_port;

      direction = nl_port_direction (port);

      ASSERT (nl_port_design (port)
	      == (nl_design) nl_reference_down_design (reference));
    }
    else if ( down_port_kind == nl_kind_libpin ) {
      nl_libpin libpin = (nl_libpin) down_port;
      
      direction = nl_libpin_direction (libpin);

      ASSERT (nl_libpin_libcell (libpin)
	      == (nl_libcell) nl_reference_down_design (reference));
    }
    else {
      ASSERT (0);
    }

    result->direction = direction;
  }
  else {
    result->direction = nl_direction_unknown;
  }

  result->reference = reference;
  result->down_port = down_port;
  result->bus = NULL;

  nl_reference_add_refpin (reference, result);

  return result;
}


/*exported*/
nl_bus
nl_refpin_create_bus (char *name, nl_type type, nl_reference ref)
{
  nl_design design = nl_reference_design (ref);
  char *bus_naming_style = nl_design_bus_naming_style (design);
  int name_len = strlen (name);
  int style_len = strlen (bus_naming_style);
  char *name_buf = alloca (name_len + style_len + 16);
  nl_bus bus = nl_bus_create (name, type, nl_kind_refpin, (nl_object) ref);

  nl_type_for_all_indexes (type, index) {
    int offset;
    int flag = nl_type_get_offset_for_index (type, index, &offset);
    nl_refpin refpin;

    if ( ! flag ) {
      error ("Internal error getting the offset for an index.");
    }

    sprintf (name_buf, bus_naming_style, name, index);
    
    refpin = nl_refpin_create (name_buf, NULL, ref);

    nl_bus_add_refpin (bus, refpin);
  } nl_end_for;

  return bus;
}


/*exported*/
void
nl_refpin_set_direction (nl_refpin refpin, nl_direction direction)
{
  nl_direction old_dir = refpin->direction;

  refpin->direction = direction;
  nl_reference_update_refpin_direction (refpin->reference, refpin, old_dir);
}


/*internal*/
void
nl_refpin_set_direction_no_update (nl_refpin refpin, nl_direction direction)
{
  refpin->direction = direction;
}


/*internal*/
void
nl_refpin_free (nl_refpin refpin)
{
  nl_reference reference = refpin->reference;

  FREE (refpin->name);
  nl_reference_free_object (reference, (nl_object) refpin);
}


/*exported*/
void
nl_refpin_rename (nl_refpin refpin, char *new_name)
{
  nl_reference reference = refpin->reference;
  nl_design design = nl_reference_design (reference);
  mem_group design_group = nl_design_mem_group (design);
  char *old_name = refpin->name;

  refpin->name = GSTRDUP (new_name, design_group);

  nl_reference_rename_refpin (reference, refpin, old_name);

  FREE (old_name);
}


/*internal*/
void
nl_refpin_set_bus_and_offset (nl_refpin refpin, nl_bus bus, int offset)
{
  refpin->bus = bus;
  refpin->bus_offset = offset;
}

