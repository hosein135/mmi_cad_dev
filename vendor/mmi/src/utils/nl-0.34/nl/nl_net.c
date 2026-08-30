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
   Create a new net named 'name' of class 'class' in design 'design'.
   The class is one of nl_wireclass_wire, nl_wireclass_reg, etc. and is
   used to distinguish between different types of Verilog wires.
**/
/*exported*/
nl_net
nl_net_create (char *name, nl_wireclass class, nl_design design)
{
  nl_net result = nl_design_alloc_net (design, name);
  mem_group design_group = nl_design_mem_group (design);
  mem_group prev_group = mem_group_set (design_group);
  nl_context context = nl_design_context (design);

  result->design = design;

  result->class = class;
  result->fanins = nl_dll_create (context, nl_kind_pin);
  result->fanouts = nl_dll_create (context, nl_kind_pin);
  result->fanios = nl_dll_create (context, nl_kind_pin);

  mem_group_set (prev_group);

  result->bus = NULL;

  nl_design_for_all_idesigns (design, idesign) {
    nl_inet_create (result, idesign);
  } nl_end_for;

  return result;
}


/*exported*/
void
nl_net_set_class (nl_net net, nl_wireclass class)
{
  net->class = class;
}


/*internal*/
void
nl_net_free_insides (nl_net net)
{
  nl_dll_free (net->fanins);
  nl_dll_free (net->fanouts);
  nl_dll_free (net->fanios);

  FREE (net->name);
}
  

/*internal*/
void
nl_net_free (nl_net net)
{
  nl_bus bus = net->bus;
  nl_design design = net->design;

  if ( bus != NULL ) {
    int offset = net->bus_offset;
    nl_bus_remove_member (bus, offset);
  }

  nl_net_free_insides (net);

  nl_design_free_object (design, (nl_object) net);
}


/**
   Add pin 'pin' to net 'net'.  Depending on its direction, the pin
   will be added to the fanouts, fanins, or fanios of the net.  If the
   direction of the pin is unknown, it will be added to the fanios of
   the net.
**/
/*internal*/
void
nl_net_add_pin (nl_net net, nl_pin pin)
{
  nl_direction direction = nl_pin_direction (pin);

  switch (direction) {
  case nl_direction_in:
    nl_dll_add (net->fanouts, (nl_dll) pin);
    break;

  case nl_direction_out:
    nl_dll_add (net->fanins, (nl_dll) pin);
    break;

  case nl_direction_inout:
  case nl_direction_unknown:
    nl_dll_add (net->fanios, (nl_dll) pin);
    break;

  default:
    ASSERT (0);
  }
}


/*exported*/
int
nl_net_num_pins (nl_net net)
{
  int result = 0;

  result += nl_dll_head_num_elements (net->fanins);
  result += nl_dll_head_num_elements (net->fanouts);
  result += nl_dll_head_num_elements (net->fanios);

  return result;
}


/**
   Remove pin 'pin' from net 'net'.
**/
/*internal*/
void
nl_net_remove_pin (nl_net net, nl_pin pin)
{
  nl_direction direction = nl_pin_direction (pin);

  switch (direction) {
  case nl_direction_in:
    nl_dll_remove (net->fanouts, (nl_dll) pin);
    break;

  case nl_direction_out:
    nl_dll_remove (net->fanins, (nl_dll) pin);
    break;

  case nl_direction_inout:
  case nl_direction_unknown:
    nl_dll_remove (net->fanios, (nl_dll) pin);
    break;

  default:
    ASSERT (0);
  }
}


/**
   Change the name of net 'net' to 'new_name'.
**/
/*exported*/
void
nl_net_rename (nl_net net, char *new_name)
{
  nl_design design = net->design;
  mem_group design_group = nl_design_mem_group (design);
  char *old_name = net->name;

  net->name = GSTRDUP (new_name, design_group);
  nl_design_rename_object (design, (nl_named_object) net, old_name);

  FREE (old_name);
}


static
void
nl_net_all_hierarchy_pins1 (nl_dll_head pin_dll, int fanins, int fanouts,
			    int fanios, int no_ports, ar result)
{
  nl_dll_for_all (pin_dll, nl_pin, pin) {
    nl_cell_or_port owner = nl_pin_owner (pin);
    nl_refpin refpin = nl_pin_refpin (pin);

    if ( no_ports && nl_cell_or_port_kind (owner) == nl_kind_port ) {
      continue;
    }

    if ( refpin == NULL ) {
      ar_add (result, &pin);
    }
    else {
      nl_object down_object = nl_refpin_down_port (refpin);
      nl_kind down_obj_kind = nl_kind_null;

      if ( down_object != NULL ) {
	down_obj_kind = nl_object_kind (down_object);
      }

      if ( down_object == NULL || down_obj_kind == nl_kind_libpin ) {
	ar_add (result, &pin);
      }
      else if ( nl_object_kind (down_object) == nl_kind_port ) {
	nl_port down_port = (nl_port) down_object;
	nl_pin down_pin = nl_port_pin (down_port);
	nl_net down_net;

	ASSERT (down_pin != NULL);

	down_net = nl_pin_net (down_pin);
	
	if ( down_net != NULL ) {
	  if ( fanins ) {
	    nl_dll_head down_pin_dll = down_net->fanins;
	    nl_net_all_hierarchy_pins1 (down_pin_dll, fanins, fanouts, fanios, 1,
					result);
	  }

	  if ( fanouts ) {
	    nl_dll_head down_pin_dll = down_net->fanouts;
	    nl_net_all_hierarchy_pins1 (down_pin_dll, fanins, fanouts, fanios, 1,
					result);
	  }

	  if ( fanios ) {
	    nl_dll_head down_pin_dll = down_net->fanios;
	    nl_net_all_hierarchy_pins1 (down_pin_dll, fanins, fanouts, fanios, 1,
					result);
	  }
	}
      }
    }
  } nl_end_for;
}


/*exported*/
ar
nl_net_all_hierarchy_pins (nl_net net, int fanins, int fanouts, int fanios)
{
  ar result = ar_alloc (0, sizeof (nl_pin));

  if ( fanins ) {
    nl_dll_head pin_dll = net->fanins;
    nl_net_all_hierarchy_pins1 (pin_dll, fanins, fanouts, fanios, 0, result);
  }

  if ( fanouts ) {
    nl_dll_head pin_dll = net->fanouts;
    nl_net_all_hierarchy_pins1 (pin_dll, fanins, fanouts, fanios, 0, result);
  }

  if ( fanios ) {
    nl_dll_head pin_dll = net->fanios;
    nl_net_all_hierarchy_pins1 (pin_dll, fanins, fanouts, fanios, 0, result);
  }

  return result;
}


/*internal*/
void
nl_net_set_bus_and_offset (nl_net net, nl_bus bus, int offset)
{
  net->bus = bus;
  net->bus_offset = offset;
}


/*exported*/
nl_net
nl_net_merge (nl_net in_net, nl_net out_net)
{
  nl_design design = in_net->design;
  char *in_name = in_net->name;
  char *out_name = out_net->name;
  int in_is_const = 0;
  int out_is_const = 0;
  int in_is_port = 0;
  int out_is_port = 0;
  int use_in_net;

  if ( out_net->design != design ) {
    error ("attempt to merge nets that do not belong to the same design\n"
	   "\tnet %s belongs to %s\n"
	   "\tnet %s belongs to %s",
	   in_name, nl_design_name (design),
	   out_name, nl_design_name (out_net->design));
  }

  if ( strcmp (in_name, "1'b0") == 0 || strcmp (in_name, "1'b1") == 0 ) {
    in_is_const = 1;
  }

  if ( strcmp (out_name, "1'b0") == 0 || strcmp (out_name, "1'b1") == 0 ) {
    out_is_const = 1;
  }

  if ( !in_is_const ) {
    nl_object port = nl_design_get_port_by_name (design, in_name);

    if ( port != NULL && nl_object_kind (port) == nl_kind_port ) {
      nl_pin port_pin = nl_port_pin ((nl_port) port);
      nl_net port_net = nl_pin_net (port_pin);

      if ( port_net == in_net )
	in_is_port = 1;
    }
  }

  if ( !out_is_const ) {
    nl_object port = nl_design_get_port_by_name (design, out_name);

    if ( port != NULL && nl_object_kind (port) == nl_kind_port ) {
      nl_pin port_pin = nl_port_pin ((nl_port) port);
      nl_net port_net = nl_pin_net (port_pin);

      if ( port_net == out_net )
	out_is_port = 1;
    }
  }


  if      ( in_is_const )
    use_in_net = 1;
  else if ( out_is_port )
    use_in_net = 0;
  else if ( in_is_port )
    use_in_net = 1;
  else if ( nl_net_bus (in_net) != NULL )
    use_in_net = 1;
  else if ( nl_net_bus (out_net) != NULL )
    use_in_net = 0;
  else
    use_in_net = 1;

  if ( use_in_net ) {
    nl_net_for_all_pins (out_net, pin) {
      nl_pin_connect_net (pin, in_net);
    } nl_end_for;

    nl_design_remove_net (design, out_net);

    return in_net;
  }
  else {
    nl_net_for_all_pins (in_net, pin) {
      nl_pin_connect_net (pin, out_net);
    } nl_end_for;

    nl_design_remove_net (design, in_net);

    return out_net;
  }
}
