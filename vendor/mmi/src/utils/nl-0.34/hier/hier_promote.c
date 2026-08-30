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



static
int
hier_net_connects_to_other_cells (nl_net net, nl_cell_attr cell_attr)
{
  nl_net_for_all_pins (net, pin) {
    nl_cell_or_port owner = nl_pin_owner (pin);
    nl_kind owner_kind = nl_cell_or_port_kind (owner);

    if ( owner_kind == nl_kind_cell ) {
      int flag;

      nl_cell_attr_get (cell_attr, (nl_cell) owner, &flag);

      if ( flag == 0 ) {
	return 1;
      }
    }
  } nl_end_for;

  return 0;
}


static
void
hier_get_promoted_nets (ar cell_array, nl_design design,
			ar exported_buses, ar_exported_nets)
{
  nl_net_attr is_port = nl_net_attr_create ("hier is port", design,
					    nl_density_sparse, sizeof (int),
					    NULL, NULL);

  nl_cell_attr in_group = nl_cell_attr_create ("hier in group", design,
					       nl_density_sparse, sizeof (int),
					       NULL, NULL);

  nl_net_attr checked = nl_net_attr_create ("hier checked nets", design,
					    nl_density_sparse, sizeof (int),
					    NULL, NULL);
  
  nl_design_for_all_ports (design, port) {
    nl_pin pin = nl_port_pin (port);
    nl_net net = nl_pin_net (pin);

    if ( net != NULL ) {
      int one = 1;
      nl_net_attr_net (is_port, net, &one);
    }
  } nl_end_for;
 
  ar_for_all (cell_array, nl_cell, cell) {
    int one = 1;

    nl_cell_attr_set (in_group, cell, &one);
  } ar_end_for;

  ar_for_all (cell_array, nl_cell, cell) {
    nl_cell_for_all_pins (cell, pin) {
      nl_net net = nl_pin_net (pin);

      if ( net != NULL ) {
	int flag;

	nl_net_attr_get (checked, net, &flag);

	if ( !flag ) {
	  flag = 1;
	  nl_net_attr_set (checked, net, &flag);
	  
	  flag = hier_net_connects_to_other_cells (net, cell_attr);

	  if ( flag ) {
	    nl_bus bus = nl_net_bus (net);

	    if ( bus != NULL ) {
	      ar_add (exported_buses, &bus);

	      nl_bus_for_all_members (bus, member) {
		nl_net bus_net = (nl_net) member;
		int one = 1;

		nl_net_attr_set (bus_net, checked, &one);
	      } nl_end_for;
	    }
	    else {
	      ar_add (exported_nets, &net);
	    }
	  }
	}
      }
    } nl_end_for;
  } ar_end_for;
}


static
void
hier_promote_cell (nl_cell cell, nl_cell inst_cell)
{
  nl_design down_design = nl_cell_design (cell);
  nl_net_attr net_forward
    = nl_net_attr_create ("promote net forward", down_design,
			  nl_density_sparse, sizeof (nl_net), NULL, NULL);

  nl_cell_for_all_pins (inst_cell, inst_pin) {
    nl_net up_net = nl_pin_net (inst_pin);
    nl_refpin refpin = nl_pin_refpin (inst_pin);
    nl_port down_port = nl_refpin_down_port (refpin);
    nl_pin down_pin;
    nl_net down_net;

    ASSERT (down_port != NULL);

    down_pin = nl_port_pin (down_port);
    down_net = nl_pin_net (down_pin);

    if ( down_net != NULL ) {
      nl_net_attr_set (net_forward, down_net, &up_net);
    }
  } nl_end_for;
}


void
hier_promote (ar cell_array, nl_design to_design)
{
  ar promoted_nets = ar_alloc (4, sizeof (nl_net));
  ar promoted_buses = ar_alloc (4, sizeof (nl_bus));
  nl_design down_design = nl_cell_design (cell);

  nl_design_for_all_references (to_design, reference) {
    nl_design ref_down_design = nl_reference_down_design (reference);

    if ( ref_down_design == down_design ) {
      nl_reference_for_all_instances (reference, inst_cell) {
	hier_promote_cell (cell, inst_cell);
      } nl_end_for;
    }
  } nl_end_for;
}
