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
   Create port named 'name' on design 'design'.  The direction of the
   port will be 'direction'.  This routine also creates a pin on the
   port.
**/
/*exported*/
nl_port
nl_port_create (char *name, nl_design design, nl_direction direction)
{
  /* int position = nl_design_num_port_positions (design); */
  nl_port result = nl_design_alloc_port (design, name);

  result->design = design;
  result->direction = direction;
  /* result->position = position; */
  result->bus = NULL;

  result->pin = nl_pin_create (NULL, (nl_cell_or_port) result);

  nl_design_for_all_idesigns (design, idesign) {
    nl_iport_create (result, NULL, idesign);
  } nl_end_for;

  return result;
}


/*internal*/
void
nl_port_free_insides (nl_port port)
{
  nl_bus bus = port->bus;

  if ( bus != NULL ) {
    int offset = port->bus_offset;
    nl_bus_remove_member (bus, offset);
  }

  FREE (port->name);
}

  
/*internal*/
void
nl_port_free (nl_port port)
{
  nl_design design = port->design;

  nl_pin_free (port->pin);

  nl_port_free_insides (port);

  nl_design_free_object (design, (nl_object) port);
}


/**
   Connect net 'net' to port 'port'.
**/
/*exported*/
void
nl_port_connect_net (nl_port port, nl_net net)
{
  nl_pin pin = port->pin;

  nl_pin_connect_net (pin, net);
}


/*internal*/
void
nl_port_set_bus_and_offset (nl_port port, nl_bus bus, int offset)
{
  port->bus = bus;
  port->bus_offset = offset;
}


/**
   Change the name of port 'port' to 'new_name'.
**/
/*exported*/
void
nl_port_rename (nl_port port, char *new_name)
{
  nl_design design = port->design;
  mem_group design_group = nl_design_mem_group (design);
  char *old_name = port->name;

  port->name = GSTRDUP (new_name, design_group);
  nl_design_rename_object (design, (nl_named_object) port, old_name);

  FREE (old_name);
}


