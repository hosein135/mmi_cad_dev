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
#include "hier.h"
#include "hier_int.h"


static
nl_cell_attr
hier_create_in_group_attr (nl_design design, ar cells)
{
  nl_cell_attr in_group = nl_cell_attr_create (NULL, design, nl_density_sparse,
					       sizeof (int), NULL, NULL);

  ar_for_all (cells, nl_cell, cell) {
    int one = 1;
    nl_cell_attr_set (in_group, cell, &one);
  } ar_end_for;

  return in_group;
}


static
nl_direction
hier_update_direction (nl_direction old, nl_direction new)
{
  if ( old == nl_direction_null )
    return new;
  else if ( old == nl_direction_unknown ||
       new == nl_direction_unknown )
    return nl_direction_unknown;
  else if ( old == nl_direction_inout ||
	    new == nl_direction_inout )
    return nl_direction_inout;
  else if ( new != old )
    return nl_direction_inout;
  else
    return old;
}


static
nl_direction
hier_figure_port_direction (nl_direction inside_dir, nl_direction outside_dir)
{
  if ( outside_dir == nl_direction_in ||
       inside_dir == nl_direction_out )
    return nl_direction_out;
  else if ( outside_dir == nl_direction_out ||
	    inside_dir == nl_direction_in )
    return nl_direction_in;
  else if ( outside_dir == nl_direction_unknown ||
	    outside_dir == nl_direction_unknown )
    return nl_direction_unknown;
  else
    return nl_direction_inout;
}


static
void
hier_find_external_nets (nl_design design, ar cells, nl_cell_attr in_group,
			 ar external_nets, ar directions, ar internal_nets)
{
  nl_net_attr checked_net
    = nl_net_attr_create (NULL, design, nl_density_sparse, sizeof (int),
			  NULL, NULL);

  ar_for_all (cells, nl_cell, cell) {
    nl_cell_for_all_pins (cell, cell_pin) {
      nl_net net = nl_pin_net (cell_pin);

      if ( net != NULL ) {
	int flag;

	nl_net_attr_get (checked_net, net, &flag);

	if ( !flag ) {
	  int is_external = 0;
	  nl_direction inside_dir = nl_direction_null;
	  nl_direction outside_dir = nl_direction_null;
	  char *name = nl_net_name (net);

	  /* Constant nets are always internal. */
	  if ( strcmp (name, "1'b0") != 0 &&
	       strcmp (name, "1'b1") != 0 ) {

	    nl_net_for_all_pins (net, net_pin) {
	      nl_direction pin_direction = nl_pin_direction (net_pin);
	      nl_cell_or_port net_pin_cell = nl_pin_owner (net_pin);

	      if ( nl_cell_or_port_kind (net_pin_cell) == nl_kind_port ) {
		/* Net is connected to a port.  It's external. */
		is_external = 1;
		outside_dir = hier_update_direction (outside_dir,
						     pin_direction);
		continue;
	      }

	      ASSERT (nl_cell_or_port_kind (net_pin_cell) == nl_kind_cell);
	    
	      nl_cell_attr_get (in_group, (nl_cell) net_pin_cell, &flag);

	      if ( ! flag ) {
		/* Net is connected to a cell that's not in the group.
		   It's external. */
		is_external = 1;
		outside_dir = hier_update_direction (outside_dir,
						     pin_direction);
		continue;
	      }
	      else {
		inside_dir = hier_update_direction (inside_dir, pin_direction);
	      }
	    } nl_end_for;
	  }

	  if ( is_external ) {
	    nl_direction port_dir
	      = hier_figure_port_direction (inside_dir, outside_dir);

	    ar_add (external_nets, &net);
	    ar_add (directions, &port_dir);
	  }
	  else {
	    ar_add (internal_nets, &net);
	  }

	  flag = 1;
	  nl_net_attr_set (checked_net, net, &flag);
	}
      }
    } nl_end_for;
  } ar_end_for;
  
  nl_design_remove_attr (design, (nl_attr) checked_net);
}


#if 0
static
void
hier_init_null_dir (void *ptr)
{
  nl_direction *attr_p = ptr;

  *attr_p = nl_direction_null;
}
#endif


static
void
hier_create_ports (nl_net_attr net_forward, nl_design design,
		   nl_design subdesign, nl_reference subdesign_ref,
		   ar external_nets, ar port_dirs)
{
  nl_direction null_dir = nl_direction_null;
  nl_net_attr net_attr
    = nl_net_attr_create (NULL, design, nl_density_sparse,
			  sizeof (nl_direction), &null_dir, NULL);

  struct bus_info {
    nl_direction dir;
    int right_index;
    int left_index;
  };

  nl_bus_attr bus_attr
    = nl_bus_attr_create (NULL, (nl_object) design, nl_density_sparse,
			  sizeof (struct bus_info), &null_dir, NULL);

  ar external_buses = ar_alloc (1, sizeof (nl_bus));

  ar_for_all_indexed (external_nets, nl_net, net, index) {
    nl_direction dir;

    ar_ref (port_dirs, index, &dir);
    nl_net_attr_set (net_attr, net, &dir);
  } ar_end_for;

  ar_for_all (external_nets, nl_net, net) {
    nl_bus bus = nl_net_bus (net);
    struct bus_info bus_info;

    if ( bus == NULL ) {
      continue;
    }

    nl_bus_attr_get (bus_attr, bus, &bus_info);

    if ( bus_info.dir == nl_direction_null ) {
      int ok = 1;
      nl_direction net_dir;
      nl_type type = nl_bus_type (bus);
      int min = nl_type_width (type);
      int max = 0;
      int i = 0;

      nl_net_attr_get (net_attr, net, &net_dir);

      ASSERT (net_dir != nl_direction_null);

      nl_bus_for_all_net_members (bus, member) {
	nl_direction dir;

	nl_net_attr_get (net_attr, member, &dir);

	if ( dir != net_dir ) {
	  ok = 0;
	  break;
	}

	if ( dir != nl_direction_null ) {
	  if ( i < min )
	    min = i;

	  if ( i > max )
	    max = i;
	}

	i++;
      } nl_end_for;

      if ( ok ) {
	nl_type_get_index_for_offset (type, min, &bus_info.right_index);
	nl_type_get_index_for_offset (type, max, &bus_info.left_index);
	
	bus_info.dir = net_dir;

	nl_bus_attr_set (bus_attr, bus, &bus_info);

	ar_add (external_buses, &bus);

	nl_bus_for_all_net_members (bus, member) {
	  nl_direction dir = nl_direction_null;

	  nl_net_attr_set (net_attr, member, &dir);
	} nl_end_for;
      }
    }
  } ar_end_for;

  ar_for_all (external_buses, nl_bus, bus) {
    struct bus_info bus_info;

    nl_bus_attr_get (bus_attr, bus, &bus_info);

    {
      char *name = nl_bus_name (bus);
      nl_type type = nl_bus_type (bus);

      if ( bus_info.left_index == nl_type_left (type) &&
	   bus_info.right_index == nl_type_right (type) ) {
	nl_type subtype = nl_type_copy (type, (nl_object) subdesign);
	nl_bus port_bus = nl_bus_create (name, subtype, nl_kind_port,
					 (nl_object) subdesign);
	nl_bus net_bus = nl_bus_create (name, subtype, nl_kind_net,
					(nl_object) subdesign);
	nl_bus refpin_bus = nl_bus_create (name, type, nl_kind_refpin,
					  (nl_object) subdesign_ref);
	nl_direction dir = bus_info.dir;

	nl_type_for_all_indexes (subtype, index) {
	  int offset;
	  int flag = nl_type_get_offset_for_index (type, index, &offset);
	  nl_net net = (nl_net) nl_bus_get_member (bus, offset);
	  char *net_name = nl_net_name (net);
	  nl_port sub_port = nl_port_create (net_name, subdesign, dir);
	  nl_net sub_net = nl_net_create (net_name, nl_wireclass_wire,
					  subdesign);
	  nl_refpin refpin = nl_refpin_create (net_name, NULL, subdesign_ref);

	  ASSERT (flag);

	  nl_refpin_set_direction (refpin, dir);

	  nl_bus_add_port (port_bus, sub_port);
	  nl_bus_add_net (net_bus, sub_net);
	  nl_bus_add_refpin (refpin_bus, refpin);

	  nl_port_connect_net (sub_port, sub_net);

	  nl_net_attr_set (net_forward, net, &sub_net);

	  if ( dir == nl_direction_out ) {
	    nl_wireclass class = nl_net_class (net);

	    if ( class == nl_wireclass_reg ) {
	      nl_net_set_class (net, nl_wireclass_wire);
	      nl_net_set_class (sub_net, nl_wireclass_reg);
	    }
	  }
	} nl_end_for;
      }
    }
  } ar_end_for;

  ar_for_all (external_nets, nl_net, net) {
    nl_direction dir;

    nl_net_attr_get (net_attr, net, &dir);

    if ( dir != nl_direction_null ) {
      char *net_name = nl_net_name (net);
      nl_port sub_port = nl_port_create (net_name, subdesign, dir);
      nl_net sub_net = nl_net_create (net_name, nl_wireclass_wire, subdesign);

      nl_refpin_create (net_name, NULL, subdesign_ref);

      nl_port_connect_net (sub_port, sub_net);

      nl_net_attr_set (net_forward, net, &sub_net);

      if ( dir == nl_direction_out ) {
	nl_wireclass class = nl_net_class (net);

	if ( class == nl_wireclass_reg ) {
	  nl_net_set_class (net, nl_wireclass_wire);
	  nl_net_set_class (sub_net, nl_wireclass_reg);
	}
      }
    }
  } ar_end_for;

  nl_design_remove_attr (design, (nl_attr) net_attr);
  nl_design_remove_attr (design, (nl_attr) bus_attr);
}


static
void
hier_copy_nets_to_design (ar internal_nets, nl_design from_design,
			  nl_design subdesign, nl_net_attr net_forward)
{
  nl_bus_attr bus_not_ok
    = nl_bus_attr_create (NULL, (nl_object) from_design, nl_density_sparse,
			  sizeof (int), NULL, NULL);

  ar_for_all (internal_nets, nl_net, int_net) {
    nl_net new_net;

    nl_net_attr_get (net_forward, int_net, &new_net);

    if ( new_net == NULL ) {
      int ok = 1;
      nl_bus int_bus = nl_net_bus (int_net);

      if ( int_bus != NULL ) {
	int not_ok;

	nl_bus_attr_get (bus_not_ok, int_bus, &not_ok);

	if ( not_ok ) {
	  ok = 0;
	}
	else {
	  nl_bus_for_all_net_members (int_bus, member) {
	    nl_net new_member;

	    nl_net_attr_get (net_forward, member, &new_member);
	  
	    if ( new_member != NULL ) {
	      ok = 0;
	      break;
	    }
	  } nl_end_for;

	  if ( ok == 0 ) {
	    int one = 1;
	    nl_bus_attr_set (bus_not_ok, int_bus, &one);
	  }
	}
      }
	
      if ( int_bus == NULL || !ok ) {
	char *name = nl_net_name (int_net);
	nl_wireclass class = nl_net_class (int_net);
	nl_net new_net = nl_net_create (name, class, subdesign);

	nl_net_attr_set (net_forward, int_net, &new_net);
      }
      else {
	char *bus_name = nl_bus_name (int_bus);
	nl_type type = nl_bus_type (int_bus);
	nl_type new_type = nl_type_copy (type, (nl_object) subdesign);
	nl_wireclass prev_class = nl_wireclass_null;
	nl_bus bus = nl_bus_create (bus_name, new_type, nl_kind_net,
				    (nl_object) subdesign);
	  
	nl_bus_for_all_net_members (int_bus, int_net) {
	  char *name = nl_net_name (int_net);
	  nl_wireclass class = nl_net_class (int_net);
	  nl_net new_net = nl_net_create (name, class, subdesign);

	  nl_bus_add_net (bus, new_net);
	  nl_net_attr_set (net_forward, int_net, &new_net);

	  ASSERT (prev_class == nl_wireclass_null || prev_class == class);
	  prev_class = class;
	} nl_end_for;
      }
    }
  } ar_end_for;

  nl_design_remove_attr (from_design, (nl_attr) bus_not_ok);
}


static
void
hier_copy_cells_to_design (ar cells, nl_design from_design, nl_design to_design,
			   nl_net_attr net_forward)
{
  nl_reference_attr ref_forward
    = nl_reference_attr_create (NULL, from_design, nl_density_sparse,
				sizeof (nl_reference), NULL, NULL);
  nl_cell_attr cell_forward
    = nl_cell_attr_create (NULL, from_design, nl_density_sparse,
			   sizeof (nl_cell), NULL, NULL);
  nl_bus_attr bus_checked
    = nl_bus_attr_create (NULL, (nl_object) from_design, nl_density_sparse,
			  sizeof (int), NULL, NULL);

  /* Step 1. Copy all the references and cells to the new design. */
  ar_for_all (cells, nl_cell, cell) {
    nl_reference reference = nl_cell_reference (cell);
    nl_reference new_ref;

    nl_reference_attr_get (ref_forward, reference, &new_ref);

    if ( new_ref == NULL ) {
      new_ref = hier_copy_reference (reference, to_design, ref_forward);
    }

    hier_copy_cell (cell, ref_forward, net_forward, "", cell_forward);
  } ar_end_for;

  /* Step 2. Copy all buses that had all their members copied to the new design.  */
  ar_for_all (cells, nl_cell, cell) {
    nl_bus cell_bus = nl_cell_bus (cell);

    if ( cell_bus != NULL ) {
      int bus_ok = 1;
      int flag;

      nl_bus_attr_get (bus_checked, cell_bus, &flag);

      if ( flag == 0 ) {
	int one = 1;

	nl_bus_attr_set (bus_checked, cell_bus, &one);

	nl_bus_for_all_cell_members (cell_bus, member) {
	  nl_cell new_cell;

	  nl_cell_attr_get (cell_forward, member, &new_cell);

	  if ( new_cell == NULL ) {
	    bus_ok = 0;
	    break;
	  }
	} nl_end_for;

	if ( bus_ok ) {
	  hier_copy_bus (cell_bus, (nl_object) to_design, "",
			 (nl_attr) cell_forward);
	}
      }
    }
  } ar_end_for;

  nl_design_remove_attr (from_design, (nl_attr) ref_forward);
  nl_design_remove_attr (from_design, (nl_attr) cell_forward);
  nl_design_remove_attr (from_design, (nl_attr) bus_checked);
}


static
void
hier_remove_cells_from_design (ar cells, nl_design from_design)
{
  nl_bus_attr remove_bus
    = nl_bus_attr_create (NULL, (nl_object) from_design, nl_density_sparse,
			  sizeof (int), NULL, NULL);
  ar dead_buses = ar_alloc (0, sizeof (nl_bus));
  nl_reference_attr affected_ref
    = nl_reference_attr_create (NULL, from_design, nl_density_sparse,
				sizeof (int), NULL, NULL);
  ar affected_refs = ar_alloc (0, sizeof (nl_bus));

  ar_for_all (cells, nl_cell, cell) {
    nl_reference cell_ref = nl_cell_reference (cell);
    nl_bus cell_bus = nl_cell_bus (cell);
    int flag = 0;

    if ( cell_bus != NULL ) {
      nl_bus_attr_get (remove_bus, cell_bus, &flag);

      if ( flag == 0 ) {
	int one = 1;

	nl_bus_attr_set (remove_bus, cell_bus, &one);
	ar_add (dead_buses, &cell_bus);
      }
    }

    nl_reference_attr_get (affected_ref, cell_ref, &flag);

    if ( flag == 0 ) {
      int one = 1;

      nl_reference_attr_set (affected_ref, cell_ref, &one);
      ar_add (affected_refs, &cell_ref);
    }
  } ar_end_for;

  nl_design_remove_attr (from_design, (nl_attr) remove_bus);
  nl_design_remove_attr (from_design, (nl_attr) affected_ref);

  ar_for_all (dead_buses, nl_bus, dead_bus) {
    nl_design_remove_cell_bus (from_design, dead_bus, 0);
  } ar_end_for;

  ar_free (dead_buses);

  ar_for_all (cells, nl_cell, cell) {
    nl_design_remove_cell (from_design, cell);
  } ar_end_for;

  ar_for_all (affected_refs, nl_reference, ref) {
    int num_inst = nl_reference_num_instances (ref);

    if ( num_inst == 0 ) {
      nl_design_remove_reference (from_design, ref);
    }
  } ar_end_for;

  ar_free (affected_refs);
}


static
nl_design
hier_group_make_subdesign (char *design_name, char *cell_name,
			   nl_design design, ar cells)
{
  nl_context context = nl_design_context (design);
  nl_cell_attr in_group = hier_create_in_group_attr (design, cells);
  ar external_nets = ar_alloc (32, sizeof (nl_net));
  ar port_dirs = ar_alloc (32, sizeof (nl_direction));
  ar internal_nets = ar_alloc (32, sizeof (nl_net));
  nl_net_attr net_forward
    = nl_net_attr_create (NULL, design, nl_density_sparse, sizeof (nl_net),
			  NULL, NULL);

  nl_design subdesign;

  /* Step 1. Of all the nets that are connected to the cells, figure
     out which nets are external to the group and which are internal
     to the group. */
  hier_find_external_nets (design, cells, in_group,
			   external_nets, port_dirs, internal_nets);

  /* Step 2. Create a subdesign. */
  subdesign = nl_design_create (design_name, context);
  {
    char *style = nl_design_bus_naming_style (design);
    nl_design_set_bus_naming_style (subdesign, style);
  }

  /* Step 3. Create a reference to the subdesign and an instance of
     that reference in the parent design.  Populate the ports on the
     subdesign and the refpins on the reference (populating the
     reference causes pins to be created on the new cell).  Connect
     the pins of the new cell to the external nets. */
  {
    nl_reference subdesign_ref
      = nl_reference_create (design_name, design, (nl_object) subdesign);
    nl_cell subdesign_cell;

    hier_create_ports (net_forward, design, subdesign, subdesign_ref,
		       external_nets, port_dirs);

    nl_reference_link (subdesign_ref, (nl_object) subdesign);

    subdesign_cell = nl_cell_create (cell_name, subdesign_ref);

    ar_for_all_indexed (external_nets, nl_net, ext_net, idx) {
      char *name = nl_net_name (ext_net);
      nl_object refpin = nl_reference_get_refpin_by_name (subdesign_ref, name);
      nl_pin cell_pin = nl_cell_get_pin_by_refpin (subdesign_cell,
						   (nl_refpin) refpin);

      nl_pin_connect_net (cell_pin, ext_net);
    } ar_end_for;
  }

  /* Step 4. Create nets in the subdesign for all remaining nets (the
     "internal" ones). */
  hier_copy_nets_to_design (internal_nets, design, subdesign, net_forward);

  /* Step 5. Create a reference in the subdesign for each reference in
     the group of cells.  Copy the cells to the subdesign. */
  hier_copy_cells_to_design (cells, design, subdesign, net_forward);

  /* Step 6. Remove all the cells from the parent design. */
  hier_remove_cells_from_design (cells, design);

  /* Step 7. Clean up. */
  ar_free (external_nets);
  ar_free (internal_nets);
  ar_free (port_dirs);
  nl_design_remove_attr (design, (nl_attr) in_group);
  nl_design_remove_attr (design, (nl_attr) net_forward);

  return subdesign;
}
  

nl_design
hier_group (ar cells, char *design_name, char *cell_name)
{
  nl_cell first_cell = AR_REF (cells, nl_cell, 0);
  nl_design design = nl_cell_design (first_cell);
  nl_design result = hier_group_make_subdesign (design_name, cell_name,
						design, cells);

  return result;
}
