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


/*exported*/
nl_bus
nl_bus_create (char *name, nl_type type, nl_kind member_kind, nl_object owner)
{
  nl_kind owner_kind = nl_object_kind (owner);
  mem_group group;
  nl_bus result;

  if ( owner_kind == nl_kind_design ) {
    group = nl_design_mem_group ((nl_design) owner);
    result = nl_design_alloc_bus ((nl_design) owner, name, member_kind);
    
    ASSERT (nl_type_owner (type) == owner);
  }
  else if ( owner_kind == nl_kind_reference ) {
    nl_design design = nl_reference_design ((nl_reference) owner);

    group = nl_design_mem_group (design);
    result = nl_design_alloc_bus (design, name, member_kind);

    ASSERT (nl_type_owner (type) == (nl_object) design);
  }
  else if ( owner_kind == nl_kind_libcell ) {
    nl_library library = nl_libcell_library ((nl_libcell) owner);

    group = nl_library_mem_group (library);
    result = nl_library_alloc_bus (library, name, member_kind);

    ASSERT (nl_type_owner (type) == (nl_object) library);
  }
  else {
    ASSERT (0);
  }

  result->owner = owner;
  result->type = type;
  result->member_kind = member_kind;

  {
    int width = nl_type_width (type);
    result->members = ar_alloc_from_group (width, sizeof (nl_object), group);
  }

  if ( owner_kind == nl_kind_reference ) {
    nl_reference_add_bus ((nl_reference) owner, result);
  }
  else if ( owner_kind == nl_kind_libcell ) {
    nl_libcell_add_bus ((nl_libcell) owner, result);
  }

  return result;
}


/*internal*/
void
nl_bus_free (nl_bus bus)
{
  nl_object owner = nl_bus_owner (bus);
  nl_kind owner_kind = nl_object_kind (owner);

  ar_free (bus->members);
  FREE (bus->name);

  if ( owner_kind == nl_kind_design ) {
    nl_design_free_object ((nl_design) owner, (nl_object) bus);
  }
  else if ( owner_kind == nl_kind_reference ) {
    nl_reference_free_object ((nl_reference) owner, (nl_object) bus);
  }
  else if ( owner_kind == nl_kind_libcell ) {
    ASSERT (!"freeing buses owned by libraries is not yet implemented");
  }
  else {
    ASSERT (0);
  }
}


/*exported*/
void
nl_bus_add_net (nl_bus bus, nl_net net)
{
  int offset;

  ASSERT (bus->member_kind == nl_kind_net);
  ASSERT (nl_net_bus (net) == NULL);

  offset = ar_size (bus->members);
  ar_add (bus->members, &net);
  nl_net_set_bus_and_offset (net, bus, offset);
}


/*exported*/
void
nl_bus_add_cell (nl_bus bus, nl_cell cell)
{
  int offset;

  ASSERT (bus->member_kind == nl_kind_cell);
  ASSERT (nl_cell_bus (cell) == NULL);

  offset = ar_size (bus->members);
  ar_add (bus->members, &cell);
  nl_cell_set_bus_and_offset (cell, bus, offset);
}


/*exported*/
void
nl_bus_add_port (nl_bus bus, nl_port port)
{
  int offset;

  ASSERT (bus->member_kind == nl_kind_port);
  ASSERT (nl_port_bus (port) == NULL);

  offset = ar_size (bus->members);
  ar_add (bus->members, &port);
  nl_port_set_bus_and_offset (port, bus, offset);
}


/*exported*/
void
nl_bus_add_refpin (nl_bus bus, nl_refpin refpin)
{
  int offset;

  ASSERT (bus->member_kind == nl_kind_refpin);
  ASSERT (nl_refpin_bus (refpin) == NULL);

  offset = ar_size (bus->members);
  ar_add (bus->members, &refpin);
  nl_refpin_set_bus_and_offset (refpin, bus, offset);
}


/*exported*/
void
nl_bus_add_libpin (nl_bus bus, nl_libpin libpin)
{
  int offset;

  ASSERT (bus->member_kind == nl_kind_libpin);
  ASSERT (nl_libpin_bus (libpin) == NULL);

  offset = ar_size (bus->members);
  ar_add (bus->members, &libpin);
  nl_libpin_set_bus_and_offset (libpin, bus, offset);
}


/*exported*/
void
nl_bus_set_type (nl_bus bus, nl_type type)
{
  bus->type = type;
}


/*exported*/
int
nl_bus_width (nl_bus bus)
{
  return ar_size (bus->members);
}


/*exported*/
nl_design_object
nl_bus_get_member (nl_bus bus, int index)
{
  nl_design_object obj;

  ar_ref (bus->members, index, &obj);

  return obj;
}


/*internal*/
void
nl_bus_remove_member (nl_bus bus, int index)
{
  nl_design_object null = NULL;

  ar_set (bus->members, index, &null);
}


/*exported*/
void
nl_bus_rename (nl_bus bus, char *new_name)
{
  nl_design design = (nl_design) bus->owner;
  mem_group design_group = nl_design_mem_group (design);
  char *old_name = bus->name;
  int name_len = strlen (new_name);
  char *naming_style = nl_design_bus_naming_style (design);
  int style_len = strlen (naming_style);
  char *member_name_buf = alloca (name_len + style_len + 16);
  nl_type type = nl_bus_type (bus);
  nl_kind member_kind = nl_bus_member_kind (bus);

  if ( nl_design_kind (design) != nl_kind_design ) {
    error ("nl_bus_rename: can only rename buses of cells, ports, or nets.");
  }

  bus->name = GSTRDUP (new_name, design_group);

  nl_design_rename_object (design, (nl_named_object) bus, old_name);

  FREE (old_name);

  nl_type_for_all_indexes (type, index) {
    int offset;
    int flag = nl_type_get_offset_for_index (type, index, &offset);
    nl_design_object member = nl_bus_get_member (bus, offset);

    ASSERT (flag == 1);

    sprintf (member_name_buf, naming_style, new_name, index);

    switch (member_kind) {
    case nl_kind_net:
      nl_net_rename ((nl_net) member, member_name_buf);
      break;

    case nl_kind_port:
      nl_port_rename ((nl_port) member, member_name_buf);
      break;

    case nl_kind_cell:
      nl_cell_rename ((nl_cell) member, member_name_buf);
      break;

    default:
      ASSERT (0);
    }
  } nl_end_for;
}
