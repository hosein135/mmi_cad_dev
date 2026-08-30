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
#include "skip-list.h"
#include "nl.h"
#include "nl_int.h"


enum nl_walk_flags {
  nl_walk_flags_null	= 0x000,
  nl_walk_thru_assigns	= 0x001,
  nl_walk_thru_hierarchy= 0x002,
  nl_walk_fanins	= 0x004,
  nl_walk_fanouts	= 0x008,
  nl_walk_fanios	= 0x010,
  nl_walk_no_constant   = 0x020,
  nl_walk_no_empty	= 0x040,
  nl_walk_library	= 0x080,
  nl_walk_hier_cells	= 0x100,
  nl_walk_unlinked	= 0x200,
  nl_walk_only_constant	= 0x400
};


struct nl_mark_nets_data {
  nl_idesign idesign;
  nl_net_attr net_attr;
  int timestamp;
  int is_constant;
  int pin_count;
};


static
nl_walk_status
nl_walk_connected_1 (nl_net, nl_pin, nl_idesign, enum nl_walk_flags, void *,
		     nl_walk_fun, nl_walk_fun);



static
nl_walk_status
nl_mark_inets_walker (nl_object obj, void *ptr)
{
  nl_inet inet = (nl_inet) obj;
  struct nl_mark_nets_data *data = (struct nl_mark_nets_data *) ptr;

  nl_inet_set_timestamp (inet, data->timestamp);

  if ( !data->is_constant ) {
    char *net_name = nl_inet_name (inet);

    if ( strcmp (net_name, "1'b1") == 0 ||
	 strcmp (net_name, "1'b0") == 0 ) {
      data->is_constant = 1;
    }
  }

  return nl_walk_status_continue;
}


static
nl_walk_status
nl_mark_nets_walker (nl_object obj, void *ptr)
{
  nl_net net = (nl_net) obj;
  struct nl_mark_nets_data *data = (struct nl_mark_nets_data *) ptr;
  int one = 1;

  nl_net_attr_set (data->net_attr, net, &one);

  if ( !data->is_constant ) {
    char *net_name = nl_net_name (net);

    if ( strcmp (net_name, "1'b1") == 0 ||
	 strcmp (net_name, "1'b0") == 0 ) {
      data->is_constant = 1;
    }
  }

  return nl_walk_status_continue;
}


static
nl_walk_status
nl_mark_pins_walker (nl_object obj, void *ptr)
{
  struct nl_mark_nets_data *data = (struct nl_mark_nets_data *) ptr;

  data->pin_count++;

  return nl_walk_status_continue;
}


static
void
nl_walk_nets_1 (nl_design design, nl_idesign idesign,
		enum nl_walk_flags flags, int timestamp,
		nl_walk_fun net_fun, void *ptr)
{
  int thru_hier = flags & nl_walk_thru_hierarchy;
  nl_net_attr marked_nets_attr;
  nl_walk_fun mark_nets_walker;

  if ( idesign != NULL ) {
    mark_nets_walker = nl_mark_inets_walker;
    marked_nets_attr = NULL;
  }
  else {
    mark_nets_walker = nl_mark_nets_walker;
    marked_nets_attr = nl_net_attr_create (NULL, design, nl_density_dense,
					   sizeof (int), NULL, NULL);
  }
    
  nl_design_for_all_nets (design, net) {
    int check_constant
      = (flags & nl_walk_no_constant) || (flags & nl_walk_only_constant);
    struct nl_mark_nets_data data;
    nl_inet inet;

    data.idesign = idesign;
    data.net_attr = marked_nets_attr;
    data.timestamp = timestamp;
    data.is_constant = !check_constant;
    data.pin_count = 0;

    if ( idesign != NULL ) {
      inet = nl_idesign_get_inet (idesign, net);

      if ( nl_inet_timestamp (inet) == timestamp ) {
	continue;
      }
    }
    else {
      int flag;

      inet = NULL;
      nl_net_attr_get (marked_nets_attr, net, &flag);

      if ( flag ) {
	continue;
      }
    }

    nl_walk_connected_1 (net, NULL, idesign, flags, (void *) &data,
			 mark_nets_walker, nl_mark_pins_walker);

    if ( (flags & nl_walk_no_constant) && data.is_constant ) {
      continue;
    }

    if ( (flags & nl_walk_no_empty) && data.pin_count == 0 ) {
      continue;
    }

    if ( (flags & nl_walk_only_constant) && !data.is_constant ) {
      continue;
    }

    if ( idesign != NULL ) {
      int status = net_fun ((nl_object) inet, ptr);
      if ( status == nl_walk_status_stop )
	return;
    }
    else {
      int status = net_fun ((nl_object) net, ptr);
      if ( status == nl_walk_status_stop )
	return;
    }

  } nl_end_for;

  if ( thru_hier ) {
    nl_idesign_for_all_icells (idesign, icell) {
      nl_idesign down_idesign = nl_icell_down_design (icell);

      if ( down_idesign != NULL ) {
	nl_design down_design = nl_idesign_design (down_idesign);

	if ( !nl_design_libcell (down_design) ) {
	  nl_walk_nets_1 (down_design, down_idesign, flags, timestamp,
			  net_fun, ptr);
	}
      }
    } nl_end_for;
  }
}


/*exported*/
void
nl_walk_nets (nl_design design, nl_idesign idesign, int thru_assigns,
	      int thru_hier, int no_constant, int no_empty, int only_constant,
	      nl_walk_fun net_fun, void *ptr)
{
  nl_context context = nl_design_context (design);
  enum nl_walk_flags flags = nl_walk_fanins | nl_walk_fanouts | nl_walk_fanios;
  int timestamp;

  if ( thru_hier ) {
    timestamp = nl_context_advance_inet_timestamp (context);
  }
  else {
    timestamp = 0;
  }

  if ( thru_assigns ) {
    flags |= nl_walk_thru_assigns;
  }

  if ( thru_hier ) {
    flags |= nl_walk_thru_hierarchy;
  }

  if ( no_constant ) {
    flags |= nl_walk_no_constant;
  }

  if ( no_empty ) {
    flags |= nl_walk_no_empty;
  }

  if ( only_constant ) {
    flags |= nl_walk_only_constant;
  }

  nl_walk_nets_1 (design, idesign, flags, timestamp, net_fun, ptr);
}


static
nl_walk_status
nl_walk_cells_1 (nl_design design, nl_idesign idesign,
		 enum nl_walk_flags flags, nl_walk_fun cell_fun, void *ptr)
{
  nl_reference assign_ref
    = nl_design_get_reference_by_name (design, "*assignment*");

  nl_design_for_all_cells (design, cell) {
    nl_reference ref = nl_cell_reference (cell);
    nl_object down_design = nl_reference_down_design (ref);
    nl_walk_status status;
    nl_icell icell;
    int call_walker = 0;

    if ( flags & nl_walk_thru_assigns ) {
      if ( ref == assign_ref ) {
	continue;
      }
    }

    if ( down_design == NULL ) {
      if ( flags & nl_walk_unlinked ) {
	call_walker = 1;
      }
    }
    else {
      if ( nl_object_kind (down_design) == nl_kind_libcell ||
	   nl_design_libcell ((nl_design) down_design) ) {
	if ( flags & nl_walk_library ) {
	  call_walker = 1;
	}
      }
      else {
	if ( flags & nl_walk_hier_cells ) {
	  call_walker = 1;
	}
      }
    }

    if ( idesign != NULL ) {
      icell = nl_idesign_get_icell (idesign, cell);

      if ( !call_walker ) {
	if ( flags & nl_walk_unlinked ) {
	  nl_idesign down_idesign = nl_icell_down_design (icell);
	
	  call_walker = (down_idesign == NULL);
	}
      }
    }
    else {
      icell = NULL;
    }

    if ( call_walker ) {
      if ( idesign != NULL ) {
	status = cell_fun ((nl_object) icell, ptr);
      }
      else {
	status = cell_fun ((nl_object) cell, ptr);
      }
    }
    else {
      status = nl_walk_status_continue;
    }

    if ( status == nl_walk_status_continue &&
	 (flags & nl_walk_thru_hierarchy) ) {
      nl_idesign down_idesign = nl_icell_down_design (icell);

      if ( down_idesign != NULL ) {
	nl_design down_design = nl_idesign_design (down_idesign);
	int is_libcell = nl_design_libcell (down_design);

	if ( ! is_libcell ) {
	  status = nl_walk_cells_1 (down_design, down_idesign, flags,
				    cell_fun, ptr);
	}
      }
    }
    
    if ( status == nl_walk_status_stop ) {
      return status;
    }
  } nl_end_for;

  return nl_walk_status_continue;
}


/*exported*/
void
nl_walk_cells (nl_design design, nl_idesign idesign, int no_assign,
	       int thru_hier, int library, int unlinked, int hierarchy,
	       nl_walk_fun cell_fun, void *ptr)
{
  enum nl_walk_flags flags = nl_walk_flags_null;

  if ( no_assign ) {
    flags |= nl_walk_thru_assigns;
  }

  if ( thru_hier ) {
    flags |= nl_walk_thru_hierarchy;
  }

  if ( library ) {
    flags |= nl_walk_library;
  }

  if ( unlinked ) {
    flags |= nl_walk_unlinked;
  }

  if ( hierarchy ) {
    flags |= nl_walk_hier_cells;
  }
  
  nl_walk_cells_1 (design, idesign, flags, cell_fun, ptr);
}  


static
nl_walk_status
nl_walk_connected_2 (nl_pin pin, nl_idesign idesign, enum nl_walk_flags flags,
		     void *ptr, nl_walk_fun net_fun, nl_walk_fun pin_fun)
{
  nl_cell_or_port owner = nl_pin_owner (pin);
  nl_kind owner_kind = nl_cell_or_port_kind (owner);
  nl_refpin refpin = nl_pin_refpin (pin);

  if ( (flags & nl_walk_thru_assigns) && owner_kind == nl_kind_cell ) {
    nl_cell cell = (nl_cell) owner;
    nl_reference ref = nl_cell_reference (cell);
    char *ref_name = nl_reference_name (ref);

    if ( strcmp (ref_name, "*assignment*") == 0 ) {
      char *refpin_name = nl_refpin_name (refpin);
      nl_object other_refpin;
      nl_pin other_pin;
      nl_net other_net;

      if ( strcmp (refpin_name, "in") == 0 ) {
	other_refpin = nl_reference_get_refpin_by_name (ref, "out");
      }
      else {
	other_refpin = nl_reference_get_refpin_by_name (ref, "in");
      }

      ASSERT (other_refpin != NULL);
      ASSERT (nl_object_kind (other_refpin) == nl_kind_refpin);

      other_pin = nl_cell_get_pin_by_refpin (cell, (nl_refpin) other_refpin);

      other_net = nl_pin_net (other_pin);

      if ( other_net != NULL ) {
	nl_walk_status status
	  = nl_walk_connected_1 (other_net, other_pin, idesign, flags, ptr,
				 net_fun, pin_fun);

	return status;
      }
      else {
	return nl_walk_status_continue;
      }
    }
  }

  if ( owner_kind == nl_kind_port ) {
    if ( flags & nl_walk_thru_hierarchy ) {
      /* Have to go up the hierarchy. */
      nl_port port = (nl_port) owner;
      nl_iport iport = nl_idesign_get_iport (idesign, port);
      nl_ipin up_ipin = nl_iport_up_pin (iport);

      if ( up_ipin != NULL ) {
	nl_idesign up_idesign = nl_ipin_idesign (up_ipin);
	nl_pin up_pin = nl_ipin_pin (up_ipin);
	nl_net up_net = nl_pin_net (up_pin);

	if ( up_net != NULL ) {
	  nl_walk_status status
	    = nl_walk_connected_1 (up_net, up_pin, up_idesign, flags,
				   ptr, net_fun, pin_fun);

	  return status;
	}
	else {
	  return nl_walk_status_continue;
	}
      }
    }

    /* Falling through to this point means that we're already at the
       top of the hierarchy. */

    if ( idesign == NULL ) {
      nl_walk_status status = pin_fun ((nl_object) pin, ptr);

      return status;
    }
    else {
      nl_ipin ipin = nl_idesign_get_ipin (idesign, pin);
      nl_walk_status status = pin_fun ((nl_object) ipin, ptr);

      return status;
    }
  }

  if ( !(flags & nl_walk_thru_hierarchy) || refpin == NULL ) {
    nl_walk_status status;

    if ( idesign == NULL ) {
      status = pin_fun ((nl_object) pin, ptr);
    }
    else {
      nl_ipin ipin = nl_idesign_get_ipin (idesign, pin);
      status = pin_fun ((nl_object) ipin, ptr);
    }

    return status;    
  }
  else { /* thru_hier == 1 && refpin != NULL */
    /* Since we know that thru_hier is 1, idesign != NULL. */
    nl_ipin ipin = nl_idesign_get_ipin (idesign, pin);
    nl_object down_port = nl_refpin_down_port (refpin);

    if ( down_port == NULL ||
	 nl_object_kind (down_port) == nl_kind_libpin ) {
      nl_walk_status status = pin_fun ((nl_object) ipin, ptr);
      return status;
    }
    else {
      nl_cell cell = (nl_cell) owner;
      nl_icell icell = nl_idesign_get_icell (idesign, cell);
      nl_reference reference = nl_cell_reference (cell);
      nl_object down_design = nl_reference_down_design (reference);
      nl_idesign down_idesign = nl_icell_down_design (icell);

      if ( nl_object_kind (down_design) != nl_kind_design ||
	   nl_design_libcell ((nl_design) down_design) ||
	   down_idesign == NULL ) {
	nl_walk_status status = pin_fun ((nl_object) ipin, ptr);
	return status;
      }
      else {
	nl_pin down_pin = nl_port_pin ((nl_port) down_port);
	nl_net down_net = nl_pin_net (down_pin);

	if ( down_net == NULL ) {
	  return nl_walk_status_continue;
	}
	else {
	  nl_icell icell = nl_idesign_get_icell (idesign, cell);
	  nl_idesign down_idesign = nl_icell_down_design (icell);
	  nl_walk_status status
	    = nl_walk_connected_1 (down_net, down_pin, down_idesign,
				   flags, ptr, net_fun, pin_fun);

	  return status;
	}
      }
    }
  }
}


static
nl_walk_status
nl_walk_connected_1 (nl_net net, nl_pin exclude_pin, nl_idesign idesign,
		     enum nl_walk_flags flags, void *ptr,
		     nl_walk_fun net_fun, nl_walk_fun pin_fun)
{
  {
    nl_walk_status status;

    if ( idesign == NULL ) {
      status = net_fun ((nl_object) net, ptr);
    }
    else {
      nl_inet inet = nl_idesign_get_inet (idesign, net);

      status = net_fun ((nl_object) inet, ptr);
    }

    if ( status == nl_walk_status_continue ) {
      ;
    }
    else if ( status == nl_walk_status_skip ) {
      return nl_walk_status_continue;
    }
    else if ( status == nl_walk_status_stop ) {
      return nl_walk_status_stop;
    }
    else {
      ASSERT (0);
    }
  }

  if ( flags & nl_walk_fanins ) {
    nl_net_for_all_fanins (net, pin) {
      if ( pin != exclude_pin ) {
	nl_walk_status status
	  = nl_walk_connected_2 (pin, idesign, flags, ptr, net_fun, pin_fun);

	if ( status == nl_walk_status_stop ) {
	  return nl_walk_status_stop;
	}
	else if ( status != nl_walk_status_continue ) {
	  ASSERT (0);
	}
      }
    } nl_end_for;
  }

  if ( flags & nl_walk_fanouts ) {
    nl_net_for_all_fanouts (net, pin) {
      if ( pin != exclude_pin ) {
	nl_walk_status status
	  = nl_walk_connected_2 (pin, idesign, flags, ptr, net_fun, pin_fun);

	if ( status == nl_walk_status_stop ) {
	  return nl_walk_status_stop;
	}
	else if ( status != nl_walk_status_continue ) {
	  ASSERT (0);
	}
      }
    } nl_end_for;
  }

  if ( flags & nl_walk_fanios ) {
    nl_net_for_all_fanios (net, pin) {
      if ( pin != exclude_pin ) {
	nl_walk_status status
	  = nl_walk_connected_2 (pin, idesign, flags, ptr, net_fun, pin_fun);

	if ( status == nl_walk_status_stop ) {
	  return nl_walk_status_stop;
	}
	else if ( status != nl_walk_status_continue ) {
	  ASSERT (0);
	}
      }
    } nl_end_for;
  }

  return nl_walk_status_continue;
}


static
nl_walk_status
nl_walk_dummy_walker (nl_object obj, void *ptr)
{
  return nl_walk_status_continue;
}


/*exported*/
void
nl_walk_connected_nets (nl_net net, nl_idesign idesign, int thru_assigns,
			int thru_hier, int fanins, int fanouts, int fanios,
			nl_walk_fun net_fun, void *ptr)
{
  enum nl_walk_flags flags = nl_walk_flags_null;

  if ( thru_assigns )
    flags |= nl_walk_thru_assigns;

  if ( thru_hier )
    flags |= nl_walk_thru_hierarchy;

  if ( fanins )
    flags |= nl_walk_fanins;

  if ( fanouts )
    flags |= nl_walk_fanouts;

  if ( fanios )
    flags |= nl_walk_fanios;

  nl_walk_connected_1 (net, NULL, idesign, flags, ptr, net_fun,
		       nl_walk_dummy_walker);
}


/*exported*/
void
nl_walk_connected_pins (nl_net net, nl_idesign idesign, int thru_assigns,
			int thru_hier, int fanins, int fanouts, int fanios,
			nl_walk_fun pin_fun, void *ptr)
{
  enum nl_walk_flags flags = nl_walk_flags_null;

  if ( thru_assigns )
    flags |= nl_walk_thru_assigns;

  if ( thru_hier )
    flags |= nl_walk_thru_hierarchy;

  if ( fanins )
    flags |= nl_walk_fanins;

  if ( fanouts )
    flags |= nl_walk_fanouts;

  if ( fanios )
    flags |= nl_walk_fanios;

  nl_walk_connected_1 (net, NULL, idesign, flags, ptr, nl_walk_dummy_walker,
		       pin_fun);
}


/*exported*/
void
nl_walk_connected_nets_and_pins (nl_net net, nl_idesign idesign,
				 int thru_assigns, int thru_hier, int fanins,
				 int fanouts, int fanios, nl_walk_fun net_fun,
				 nl_walk_fun pin_fun, void *ptr)
{
  enum nl_walk_flags flags = nl_walk_flags_null;

  if ( thru_assigns )
    flags |= nl_walk_thru_assigns;

  if ( thru_hier )
    flags |= nl_walk_thru_hierarchy;

  if ( fanins )
    flags |= nl_walk_fanins;

  if ( fanouts )
    flags |= nl_walk_fanouts;

  if ( fanios )
    flags |= nl_walk_fanios;

  nl_walk_connected_1 (net, NULL, idesign, flags, ptr, net_fun, pin_fun);
}


static
nl_walk_status
nl_walk_hierarchy_1 (nl_design design, int walk_libcells,
		     nl_walk_fun walk_fun, void *ptr)
{
  if ( nl_design_libcell (design) ) {
    if ( walk_libcells ) {
      nl_walk_status status = walk_fun ((nl_object) design, ptr);

      if ( status == nl_walk_status_stop ) {
	return nl_walk_status_stop;
      }
      else {
	return nl_walk_status_continue;
      }
    }
  }
  else {
    nl_walk_status status = walk_fun ((nl_object) design, ptr);

    if ( status == nl_walk_status_skip ) {
      return nl_walk_status_continue;
    }
    else if ( status == nl_walk_status_stop ) {
      return nl_walk_status_stop;
    }
  }

  nl_design_for_all_references (design, reference) {
    nl_object down_design = nl_reference_down_design (reference);

    if ( down_design != NULL &&
	 nl_object_kind (down_design) == nl_kind_design ) {
      nl_walk_status status
	= nl_walk_hierarchy_1 ((nl_design) down_design, walk_libcells,
			       walk_fun, ptr);

      if ( status == nl_walk_status_stop ) {
	return nl_walk_status_stop;
      }
    }
  } nl_end_for;

  return nl_walk_status_continue;
}


/*exported*/
void
nl_walk_hierarchy (nl_design top_design, int walk_libcells,
		   nl_walk_fun walk_fun, void *ptr)
{
  nl_walk_hierarchy_1 (top_design, walk_libcells, walk_fun, ptr);
}


static
nl_walk_status
nl_walk_idesigns_1 (nl_idesign idesign, int walk_libcells,
		     nl_walk_fun walk_fun, void *ptr)
{
  nl_design design = nl_idesign_design (idesign);
  
  if ( nl_design_libcell (design) ) {
    if ( walk_libcells ) {
      nl_walk_status status = walk_fun ((nl_object) idesign, ptr);

      if ( status == nl_walk_status_stop ) {
	return nl_walk_status_stop;
      }
      else {
	return nl_walk_status_continue;
      }
    }
  }
  else {
    nl_walk_status status = walk_fun ((nl_object) idesign, ptr);

    if ( status == nl_walk_status_skip ) {
      return nl_walk_status_continue;
    }
    else if ( status == nl_walk_status_stop ) {
      return nl_walk_status_stop;
    }
  }

  nl_idesign_for_all_icells (idesign, icell) {
    nl_idesign down_idesign = nl_icell_down_design (icell);

    if ( down_idesign != NULL ) {
      nl_walk_status status
	= nl_walk_idesigns_1 (down_idesign, walk_libcells, walk_fun, ptr);

      if ( status == nl_walk_status_stop ) {
	return nl_walk_status_stop;
      }
    }
  } nl_end_for;

  return nl_walk_status_continue;
}


/*exported*/
void
nl_walk_idesigns (nl_idesign top_idesign, int walk_libcells,
		  nl_walk_fun walk_fun, void *ptr)
{
  nl_walk_idesigns_1 (top_idesign, walk_libcells, walk_fun, ptr);
}
