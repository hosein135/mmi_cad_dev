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
#include "str.h"
#include "hashtab.h"
#include "unparse.h"
#include "nl.h"
#include "str.h"
#include "nl2v.h"


static void nl2v_write_direction (unparse_fp, nl_direction);
static void nl2v_write_type (unparse_fp, nl_type);
static void nl2v_write_port_list (unparse_fp, nl_design);
static void nl2v_write_ports (unparse_fp, nl_design, nl_net_attr);
static void nl2v_write_buses (unparse_fp, nl_design, nl_net_attr);
static void nl2v_write_nets (unparse_fp, nl_design, nl_net_attr);
static void nl2v_write_pins (unparse_fp, nl_cell, nl_reference, int *);
static void nl2v_write_cells (unparse_fp, nl_design);
static void nl2v_write_design (unparse_fp, nl_design, int, int,
			       nl_design_attr);

static void nl2v_write_net_ref (unparse_fp, nl_net, int);


static
void
nl2v_write_identifier (unparse_fp ufp, char *ident, int space)
{
  int i;
  int len = strlen (ident);
  int needs_backslash = 0;
  int has_backslash = (ident[0] == '\\');

  if ( ! has_backslash
       && strcmp (ident, "1'b0") != 0
       && strcmp (ident, "1'b1") != 0 ) {
    /* No backslash is needed for A-Z, a-z, 0-9, $, and _ */

    for ( i = 0; i < len; i++ ) {
      if ( isalpha ((int) ident[i]) || 
	   (isdigit ((int) ident[i]) && (i > 0)) ||
	   ident[i] == '$' ||
	   ident[i] == '_' ) {
	continue;
      }
      else {
	needs_backslash = 1;
	has_backslash = 1;
	break;
      }
    }
  }

  if ( needs_backslash || has_backslash ) {
    char *prefix = needs_backslash ? "\\" : "";
    char *suffix = has_backslash   ? " "  : "";
    char *backslashed = str_append (prefix, ident, suffix, NULL);

    unparse_token (ufp, backslashed, space);

    FREE (backslashed);
  }
  else {
    unparse_token (ufp, ident, space);
  }
}


static
void
nl2v_write_direction (unparse_fp ufp, nl_direction dir)
{
  switch (dir) {
  case nl_direction_in:
    unparse_token (ufp, "input", 0);
    break;
  case nl_direction_out:
    unparse_token (ufp, "output", 0);
    break;
  case nl_direction_inout:
    unparse_token (ufp, "inout", 0);
    break;
  case nl_direction_unknown:
    unparse_token (ufp, "inout /* unknown */", 0);
    break;
  default:
    ASSERT (0);
  }
}


static
void
nl2v_write_type (unparse_fp ufp, nl_type type)
{
  nl_typeclass class = nl_type_class (type);

  switch (class) {
  case nl_typeclass_scalar:
    return;
  case nl_typeclass_array:
    unparse_token (ufp, "[", 1);
    unparse_int (ufp, nl_type_left (type), -1);
    unparse_token (ufp, ":", -1);
    unparse_int (ufp, nl_type_right (type), -1);
    unparse_token (ufp, "]", -1);
    return;
  default:
    ASSERT (0);
  }
}


#if 0
static
void
nl2v_write_port_bus_members (unparse_fp ufp, nl_bus bus)
     /* Untested */
{
  int need_concat = 0;
  ar members = nl_bus_members (bus);

  ar_for_all (members, nl_port, port) {
    char *port_name = nl_port_name (port);
    nl_pin pin = nl_port_pin (port);
    nl_net net = nl_pin_net (pin);

    if ( net != NULL ) {
      char *net_name = nl_net_name (net);
      if ( strcmp (port_name, net_name) != 0 ) {
	need_concat = 1;
	break;
      }
    }
  } ar_end_for;

  if ( ! need_concat ) {
    return;
  }
  else {
    int first = 1;
    
    unparse_token (ufp, "(", -1);
    unparse_token (ufp, "{", -1);

    ar_for_all (members, nl_port, port) {
      nl_pin pin = nl_port_pin (port);
      nl_net net = nl_pin_net (pin);
      char *net_name;

      ASSERT (net != NULL);

      if ( !first ) {
	unparse_token (ufp, ",", -1);
	unparse_space (ufp, 1);
      }
      else {
	first = 0;
      }

      nl2v_write_net_ref (ufp, net, -1);
    } ar_end_for;

    unparse_token (ufp, "}", -1);
    unparse_token (ufp, ")", -1);
  }
}
#endif


static
void
nl2v_write_port_list (unparse_fp ufp, nl_design design)
{
  int first = 1;
  nl_bus prev_bus = NULL;

  nl_design_for_all_ports (design, port) {
    nl_bus bus = nl_port_bus (port);

    if ( bus != NULL && bus == prev_bus ) {
      continue;
    }
    else {
      char *pname;
      int sp = 1 - first;

      prev_bus = bus;

      if ( bus != NULL ) {
	pname = nl_bus_name (bus);
      }
      else {
	pname = nl_port_name (port);
      }

      if (first) {
	first = 0;
	unparse_token (ufp, "(", 1);
	unparse_set_indent (ufp, unparse_column (ufp));
      }
      else {
	unparse_token (ufp, ",", -1);
      }

      nl2v_write_identifier (ufp, pname, sp);

#if 0      
      if ( bus != NULL ) {
	nl2v_write_port_bus_members (ufp, bus);
      }
#endif
    }
  } nl_end_for;

  if ( !first ) {
    unparse_token (ufp, ")", -1);
  }
  unparse_token (ufp, ";", -1);
  unparse_set_indent (ufp, 2);
  unparse_newline (ufp);
}


static
void
nl2v_write_ports (unparse_fp ufp, nl_design design, nl_net_attr written_attr)
{
  int bol = 1;
  nl_direction prev_dir = nl_direction_null;
  nl_bus prev_bus = NULL;
  nl_type scalar = nl_type_get_scalar ((nl_object) design);
    
  nl_design_for_all_ports (design, port) {
    nl_direction dir = nl_port_direction (port);
    char *name; 
    nl_bus bus = nl_port_bus (port);
    nl_type type;
    int is_reg = 0;

    {
      nl_pin pin = nl_port_pin (port);
      nl_net net = nl_pin_net (pin);

      if ( net != NULL ) {
	char *port_name = nl_port_name (port);
	char *net_name = nl_net_name (net);

	if ( strcmp (port_name, net_name) == 0 ) {
	  int one = 1;

	  nl_net_attr_set (written_attr, net, &one);

	  if ( nl_net_class (net) == nl_wireclass_reg ) {
	    is_reg = 1;
	  }
	}
      }
    }

    if ( bus != NULL && bus == prev_bus )
      continue;

    prev_bus = bus;

    if ( bus ) {
      type = nl_bus_type (bus);
      name = nl_bus_name (bus);

      if ( ! bol ) {
	unparse_token (ufp, ";", -1);
	unparse_newline (ufp);
	unparse_set_indent (ufp, 2);
	bol = 1;
      }
    }
    else {
      type = scalar;
      name = nl_port_name (port);
    }

    if ( bol ) {
      unparse_space (ufp, 2);
      nl2v_write_direction (ufp, dir);
      nl2v_write_type (ufp, type);
      unparse_set_indent (ufp, 6);
      prev_dir = dir;
      bol = 0;
    }
    else if ( prev_dir != dir ) {
      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
      unparse_set_indent (ufp, 2);
      nl2v_write_direction (ufp, dir);
      unparse_set_indent (ufp, 6);
      nl2v_write_type (ufp, type);
      prev_dir = dir;
    }
    else {
      unparse_token (ufp, ",", -1);
    }

    nl2v_write_identifier (ufp, name, 1);

    if ( bus != NULL ) {
      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
      unparse_set_indent (ufp, 2);
      bol = 1;
    }

    if ( is_reg ) {
      if ( !bol ) {
	unparse_token (ufp, ";", -1);
	unparse_newline (ufp);
	unparse_set_indent (ufp, 2);
      }

      unparse_token (ufp, "reg", 0);
      unparse_set_indent (ufp, 6);
      nl2v_write_type (ufp, type);

      nl2v_write_identifier (ufp, name, 1);

      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
      unparse_set_indent (ufp, 2);
      bol = 1;
    }
  } nl_end_for;

  if ( !bol ) {
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
  }

  unparse_set_indent (ufp, 2);
}


static
void
nl2v_write_port_connections (unparse_fp ufp, nl_design design)
{
  int first = 1;
  
  nl_design_for_all_ports (design, port) {
    char *port_name = nl_port_name (port);
    nl_pin pin = nl_port_pin (port);
    nl_net net = nl_pin_net (pin);

    if ( net == NULL ) {
      continue;
    }
    else {
      char *net_name = nl_net_name (net);

      if ( strcmp (port_name, net_name) != 0 ) {
	nl_direction dir = nl_port_direction (port);

	if ( first ) {
	  unparse_newline (ufp);
	  first = 0;
	}

	switch (dir) {
	case nl_direction_in:
	  unparse_token (ufp, "assign", 1);
	  nl2v_write_net_ref (ufp, net, 1);
	  unparse_token (ufp, "=", 1);
	  unparse_token (ufp, port_name, 1);
	  unparse_token (ufp, ";", -1);
	  unparse_newline (ufp);
	  break;

	case nl_direction_out:
	  unparse_token (ufp, "assign", 1);
	  unparse_token (ufp, port_name, 1);
	  unparse_token (ufp, "=", 1);
	  nl2v_write_net_ref (ufp, net, 1);
	  unparse_token (ufp, ";", -1);
	  unparse_newline (ufp);
	  break;

	case nl_direction_inout:
	  unparse_token (ufp, "tran", 1);
	  unparse_token (ufp, "(", 1);
	  unparse_token (ufp, port_name, 0);
	  unparse_token (ufp, ",", 0);
	  nl2v_write_net_ref (ufp, net, 1);
	  unparse_token (ufp, ")", -1);
	  unparse_token (ufp, ";", -1);
	  unparse_newline (ufp);
	  break;
	default:
	  error ("cannot determine direction of port %s", port_name);
	}
	
      }
    }
  } nl_end_for;
}


static
int
is_constant (char *name)
{
  if ( strcmp (name, "1'b0") == 0 ||
       strcmp (name, "1'b1") == 0 ) {
    return 1;
  }
  else {
    return 0;
  }
}
      

#if 0
static
int
is_port (char *name, nl_design design)
{
  char *pname = alloca (strlen (name) + 2);
  nl_object port;

  pname[0] = '.';
  strcpy (pname + 1, name);

  port = (nl_object) nl_design_get_port_by_name (design, pname);

  if ( port == NULL ) {
    return 0;
  }
  else {
    return 1;
  }
}
#endif


#if 0
static
int
net_connects_to_port (nl_net net)
{
  ar in_pins = nl_net_fanins (net);
  ar out_pins = nl_net_fanouts (net);
  ar io_pins = nl_net_fanios (net);

  ar_for_all (in_pins, nl_pin, pin) {
    nl_cell_or_port owner = nl_pin_owner (pin);

    if ( nl_cell_or_port_kind (owner) == nl_kind_port ) {
      return 1;
    }
  } ar_end_for;

  ar_for_all (out_pins, nl_pin, pin) {
    nl_cell_or_port owner = nl_pin_owner (pin);

    if ( nl_cell_or_port_kind (owner) == nl_kind_port ) {
      return 1;
    }
  } ar_end_for;

  ar_for_all (io_pins, nl_pin, pin) {
    nl_cell_or_port owner = nl_pin_owner (pin);

    if ( nl_cell_or_port_kind (owner) == nl_kind_port ) {
      return 1;
    }
  } ar_end_for;

  return 0;
}
#endif


static
int
nl2v_write_single_net (unparse_fp ufp, nl_net net, nl_net_attr written_attr,
		       int first, char *class, int *any_written_p)
{
  int written = 0;

  nl_net_attr_get (written_attr, net, &written);

  if ( ! written ) {
    char *name = nl_net_name (net);
    int one = 1;

    nl_net_attr_set (written_attr, net, &one);

    if ( is_constant (name) ) {
      return first;
    }

    if ( *any_written_p == 0 ) {
      unparse_newline (ufp);
      *any_written_p = 1;
    }

    if ( first ) {
      unparse_token (ufp, class, 2);
      unparse_set_indent (ufp, 6);
      first = 0;
    }
    else {
      unparse_token (ufp, ",", -1);
    }

    nl2v_write_identifier (ufp, name, 1);
  }

  return first;
}


static
void
nl2v_write_single_bus (unparse_fp ufp, nl_bus bus, nl_net_attr written_attr,
		       char *class, int *any_written_p)
{
  int size = nl_bus_width (bus);
  if ( size > 0 ) {
    nl_net net = (nl_net) nl_bus_get_member (bus, 0);
    int flag;

    nl_net_attr_get (written_attr, net, &flag);

    if ( ! flag ) {
      nl_type type = nl_bus_type (bus);
      nl_typeclass typeclass = nl_type_class (type);
      char *name = nl_bus_name (bus);

      if ( *any_written_p == 0 ) {
	unparse_newline (ufp);
	*any_written_p = 1;
      }

      if ( typeclass == nl_typeclass_integer ) {
	unparse_token (ufp, "integer", 2);
	unparse_set_indent (ufp, 6);
      }
      else {
	unparse_token (ufp, class, 2);
	unparse_set_indent (ufp, 6);
	nl2v_write_type (ufp, type);
      }
      nl2v_write_identifier (ufp, name, 1);
      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
      unparse_set_indent (ufp, 2);

      {
	ar members = nl_bus_members (bus);

	ar_for_all (members, nl_net, net) {
	  int one = 1;

	  nl_net_attr_set (written_attr, net, &one);
	} ar_end_for;
      }
    }
  }
}


static
void
nl2v_write_supplies (unparse_fp ufp, nl_design design,
		     nl_net_attr written_attr)
{
  ar supply0s = nl_design_supply0s (design);
  ar supply1s = nl_design_supply1s (design);
  int first = 1;
  int any_written = 0;

  ar_for_all (supply0s, nl_object, obj) {
    if ( nl_object_kind (obj) == nl_kind_net ) {
      first = nl2v_write_single_net (ufp, (nl_net) obj, written_attr, first,
				     "supply0", &any_written);
    }
    else if ( nl_object_kind (obj) == nl_kind_bus ) {
      nl2v_write_single_bus (ufp, (nl_bus) obj, written_attr, "supply0",
			     &any_written);
      first = 1;
    }
    else {
      ASSERT (0);
    }
  } ar_end_for;
      
  if ( !first ) {
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
  }

  unparse_set_indent (ufp, 2);

  first = 1;

  ar_for_all (supply1s, nl_object, obj) {
    if ( nl_object_kind (obj) == nl_kind_net ) {
      first = nl2v_write_single_net (ufp, (nl_net) obj, written_attr, first,
				     "supply1", &any_written);
    }
    else if ( nl_object_kind (obj) == nl_kind_bus ) {
      nl2v_write_single_bus (ufp, (nl_bus) obj, written_attr, "supply1",
			     &any_written);
      first = 1;
    }
    else {
      ASSERT (0);
    }
  } ar_end_for;
      
  if ( !first ) {
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
  }

  unparse_set_indent (ufp, 2);
}


static
void
nl2v_write_buses (unparse_fp ufp, nl_design design, nl_net_attr written_attr)
{
  int any_written = 0;

  nl_design_for_all_net_buses (design, bus) {
    nl_net net = (nl_net) nl_bus_get_member (bus, 0);
    nl_wireclass class;
    char *class_str;

    ASSERT (nl_net_kind (net) == nl_kind_net);

    class = nl_net_class (net);
    class_str = (char *) nl_wireclass_to_string (class);
    nl2v_write_single_bus (ufp, bus, written_attr, class_str, &any_written);

  } nl_end_for;
}


static
void
nl2v_write_nets (unparse_fp ufp, nl_design design, nl_net_attr written_attr)
{
  int first = 1;
  nl_wireclass prev_class = nl_wireclass_null;
  int any_written = 0;

  nl_design_for_all_nets (design, net) {
    nl_wireclass class = nl_net_class (net);
    char *class_str = (char *) nl_wireclass_to_string (class);
     
    if ( class != prev_class ) {
      if ( !first ) {
	unparse_token (ufp, ";", -1);
	unparse_newline (ufp);
	unparse_set_indent (ufp, 2);
      }

      first = 1;
      prev_class = class;
    }

    first = nl2v_write_single_net (ufp, net, written_attr, first, class_str,
				   &any_written);

    if ( !any_written && !first ) {
      unparse_newline (ufp);
      any_written = 1;
    }
  } nl_end_for;

  if ( !first ) {
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
  }

  unparse_set_indent (ufp, 2);
}


static
void
nl2v_write_net_ref (unparse_fp ufp, nl_net net, int before)
{
  nl_bus bus = nl_net_bus (net);

  if ( bus != NULL ) {
    nl_type type = nl_bus_type (bus);
    char *bus_name = nl_bus_name (bus);
    int offset = nl_net_bus_offset (net);
    int index;

    nl_type_get_index_for_offset (type, offset, &index);

    nl2v_write_identifier (ufp, bus_name, before);
    unparse_token (ufp, "[", 0);
    unparse_int (ufp, index, -1);
    unparse_token (ufp, "]", -1);
  }
  else {
    char *net_name = nl_net_name (net);
    nl2v_write_identifier (ufp, net_name, before);
  }
}


static
void
nl2v_write_bus_range (unparse_fp ufp, nl_bus bus, int bus_first, int bus_last,
		      int need_comma)
{
  nl_type type = nl_bus_type (bus);
  char *bus_name = nl_bus_name (bus);
  int left = nl_type_left (type);
  int right = nl_type_right (type);

  if ( left == bus_first && right == bus_last ) {
    if ( need_comma ) {
      unparse_token (ufp, ",", -1);
    }
    nl2v_write_identifier (ufp, bus_name, need_comma);
  }
  else if ( bus_first == bus_last ) {
    if ( need_comma ) {
      unparse_token (ufp, ",", -1);
    }
    nl2v_write_identifier (ufp, bus_name, need_comma);
    unparse_token (ufp, "[", 0);
    unparse_int (ufp, bus_first, 0);
    unparse_token (ufp, "]", 0);
  }
  else {
    if ( need_comma ) {
      unparse_token (ufp, ",", -1);
    }
    nl2v_write_identifier (ufp, bus_name, need_comma);
    unparse_token (ufp, "[", 0);
    unparse_int (ufp, bus_first, 0);
    unparse_token (ufp, ":", 0);
    unparse_int (ufp, bus_last, 0);
    unparse_token (ufp, "]", 0);
  }
}


static
void
nl2v_write_net_bundle (unparse_fp ufp, ar nets, int *unconnected_count_p,
		       int need_braces)
{
  nl_bus cur_bus = NULL;
  int bus_first = -1;
  int bus_last = -1;
  int need_comma = 0;
  int concat_open = 0;
  int size = ar_size (nets);
  int incr = 0;

  if ( need_braces ) {
    unparse_token (ufp, "{", 0);
    concat_open = 1;
  }

  ar_for_all_indexed (nets, nl_net, net, i) {
    nl_bus bus = (net == NULL) ? NULL : nl_net_bus (net);

    if ( bus == NULL ) {
      if ( !concat_open && (cur_bus != NULL || i < size - 1) ) {
	unparse_token (ufp, "{", 0);
	need_comma = 0;
	concat_open = 1;
      }

      if ( cur_bus != NULL ) {
	nl2v_write_bus_range (ufp, cur_bus, bus_first, bus_last, need_comma);
	need_comma = 1;
      }
      cur_bus = NULL;

      if ( need_comma ) {
	unparse_token (ufp, ",", -1);
      }

      if ( net == NULL ) {
	char buf[40];
	sprintf (buf, "*JNPR_UNC_%03d*", *unconnected_count_p);
	nl2v_write_identifier (ufp, buf, need_comma);
	(*unconnected_count_p)++;
      }
      else {
	nl2v_write_net_ref (ufp, net, need_comma);
      }

      need_comma = concat_open;
    }
    else {
      nl_type type = nl_bus_type (bus);
      int offset = nl_net_bus_offset (net);
      int index;

      nl_type_get_index_for_offset (type, offset, &index);
      
      if ( bus != cur_bus ||
	   index != bus_last + incr ) {
	if ( cur_bus != NULL ) {
	  if ( !concat_open ) {
	    unparse_token (ufp, "{", 0);
	    need_comma = 0;
	    concat_open = 1;
	  }

	  ASSERT (bus_first != -1 && bus_last != -1);

	  nl2v_write_bus_range (ufp, cur_bus, bus_first, bus_last, need_comma);
	  need_comma = 1;
	}

	{
	  int left = nl_type_left (type);
	  int right = nl_type_right (type);
	  
	  if ( left <= right ) {
	    incr = 1;
	  }
	  else {
	    incr = -1;
	  }

	  cur_bus = bus;
	  bus_first = index;
	  bus_last = bus_first;
	}
      }
      else { /* bus == cur_bus && index == bus_last + incr */
	bus_last = index;
      }
    }
  } ar_end_for;

  if ( cur_bus != NULL ) {
    nl2v_write_bus_range (ufp, cur_bus, bus_first, bus_last, need_comma);
  }

  if ( concat_open ) {
    unparse_token (ufp, "}", 0);
  }
}


static
void
nl2v_write_pins (unparse_fp ufp, nl_cell cell, nl_reference reference,
		 int *unconnected_count_p)
{
  int first = 1;
  nl_bus prev_bus = NULL;

  nl_reference_for_all_refpins (reference, refpin) {
    nl_bus bus = nl_refpin_bus (refpin);

    if ( bus != NULL && bus == prev_bus ) {
      continue;
    }
    else {
      char *name;

      prev_bus = bus;

      if ( bus == NULL ) {
	name = nl_refpin_name (refpin);
      }
      else {
	name = nl_bus_name (bus);
      }

      if ( !first ) {
	unparse_token (ufp, ",", -1);
	unparse_space (ufp, 1);
      }
      else {
	first = 0;
      }

      unparse_token (ufp, ".", -1);

      nl2v_write_identifier (ufp, name, -1);

      unparse_token (ufp, "(", -1);

      if ( bus == NULL ) {
	nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
	nl_net net = nl_pin_net (pin);

	if ( net != NULL ) {
	  nl2v_write_net_ref (ufp, net, -1);
	}
      }
      else {
	int empty = 1;

	nl_bus_for_all_refpin_members (bus, bus_refpin) {
	  nl_pin pin = nl_cell_get_pin_by_refpin (cell, bus_refpin);
	  nl_net net = nl_pin_net (pin);

	  if ( net != NULL ) {
	    empty = 0;
	    break;
	  }
	} nl_end_for;

	if ( empty == 0 ) {
	  ar nets = ar_alloc (0, sizeof (nl_net));

	  nl_bus_for_all_refpin_members_reverse (bus, bus_refpin) {
	    nl_pin pin = nl_cell_get_pin_by_refpin (cell, bus_refpin);
	    nl_net net = nl_pin_net (pin);

	    ar_add (nets, &net);
	  } nl_end_for;

	  nl2v_write_net_bundle (ufp, nets, unconnected_count_p, 0);

	  ar_free (nets);
	}
      }

      unparse_token (ufp, ")", -1);
    }
  } nl_end_for;
}


static
void
nl2v_write_assignment (unparse_fp ufp, nl_cell cell)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_object in_refpin = nl_reference_get_refpin_by_name (reference, "in");
  nl_object out_refpin = nl_reference_get_refpin_by_name (reference, "out");
  nl_pin in_pin;
  nl_pin out_pin;
  nl_net in_net;
  nl_net out_net;

  ASSERT (in_refpin != NULL);
  ASSERT (out_refpin != NULL);
  ASSERT (nl_object_kind (in_refpin) == nl_kind_refpin);
  ASSERT (nl_object_kind (out_refpin) == nl_kind_refpin);

  in_pin = nl_cell_get_pin_by_refpin (cell, (nl_refpin) in_refpin);
  out_pin = nl_cell_get_pin_by_refpin (cell, (nl_refpin) out_refpin);

  in_net = nl_pin_net (in_pin);
  out_net = nl_pin_net (out_pin);

  if ( in_net != NULL && out_net != NULL ) {
    unparse_token (ufp, "assign", 2);
    unparse_set_indent (ufp, 4);
    nl2v_write_net_ref (ufp, out_net, 1);
    unparse_token (ufp, "=", 1);
    nl2v_write_net_ref (ufp, in_net, 1);
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
    unparse_set_indent (ufp, 2);
  }
}


static
void
nl2v_write_tran (unparse_fp ufp, nl_cell cell)
{
  nl_reference reference = nl_cell_reference (cell);
  nl_object in_refpin = nl_reference_get_refpin_by_name (reference, "in");
  nl_object out_refpin = nl_reference_get_refpin_by_name (reference, "out");
  nl_pin in_pin;
  nl_pin out_pin;
  nl_net in_net;
  nl_net out_net;

  ASSERT (in_refpin != NULL);
  ASSERT (out_refpin != NULL);
  ASSERT (nl_object_kind (in_refpin) == nl_kind_refpin);
  ASSERT (nl_object_kind (out_refpin) == nl_kind_refpin);

  in_pin = nl_cell_get_pin_by_refpin (cell, (nl_refpin) in_refpin);
  out_pin = nl_cell_get_pin_by_refpin (cell, (nl_refpin) out_refpin);

  in_net = nl_pin_net (in_pin);
  out_net = nl_pin_net (out_pin);

  if ( in_net != NULL && out_net != NULL ) {
    char *name = nl_cell_name (cell);

    unparse_token (ufp, "tran", 2);

    if ( strncmp (name, "*tran_", 6) != 0 ) {
      nl2v_write_identifier (ufp, nl_cell_name (cell), 1);
    }

    unparse_token (ufp, "(", 1);
    nl2v_write_net_ref (ufp, out_net, 0);
    unparse_token (ufp, ",", 0);
    nl2v_write_net_ref (ufp, in_net, 1);
    unparse_token (ufp, ")", 0);
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
  }
}


static void nl2v_dump_verilog (unparse_fp, nl_ast, nl_design, ar, ar);


static
void
nl2v_dump_verilog_expression_list (unparse_fp ufp, nl_ast list,
				   nl_design design, ar inputs, ar outputs)
{
  int first = 1;
  nl_ast tree = list;

  while ( tree != NULL ) {
    if ( first ) {
      first = 0;
    }
    else {
      unparse_token (ufp, ",", -1);
      unparse_token (ufp, "", 1);
    }

    nl2v_dump_verilog (ufp, tree, design, inputs, outputs);

    tree = nl_ast_sibling (tree);
  }
}


static
void
nl2v_dump_unary_op (unparse_fp ufp, char *op, nl_ast tree,
		    nl_design design, ar inputs, ar outputs)
{
  nl_ast arg = nl_ast_child (tree);
  nl_token arg_tok = nl_ast_token (arg);
  int need_parens;

  switch ( arg_tok ) {
  case nl_token_in:
  case nl_token_out:
  case nl_token_number:
  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct:
  case nl_token_bit:
  case nl_token_slice:
  case nl_token_varbit:
  case nl_token_funcall:
  case nl_token_concat:
    need_parens = 0;
    break;
  default:
    need_parens = 1;
    break;
  }

  unparse_token (ufp, op, 0);
  if ( need_parens ) {
    unparse_token (ufp, "(", 0);
  }

  nl2v_dump_verilog (ufp, arg, design, inputs, outputs);

  if ( need_parens ) {
    unparse_token (ufp, ")", 0);
  }
}


static
void
nl2v_dump_binary_op (unparse_fp ufp, char *op, nl_ast tree,
		     nl_design design, ar inputs, ar outputs)
{
  nl_ast arg1 = nl_ast_child (tree);
  nl_ast arg2 = nl_ast_sibling (arg1);
  nl_token arg1_tok = nl_ast_token (arg1);
  nl_token arg2_tok = nl_ast_token (arg2);
  int need_parens1;
  int need_parens2;

  switch ( arg1_tok ) {
  case nl_token_in:
  case nl_token_out:
  case nl_token_number:
  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct:
  case nl_token_bit:
  case nl_token_slice:
  case nl_token_varbit:
  case nl_token_bitnot:
  case nl_token_lognot:
  case nl_token_and_reduce:
  case nl_token_nand_reduce:
  case nl_token_or_reduce:
  case nl_token_nor_reduce:
  case nl_token_xor_reduce:
  case nl_token_xnor_reduce:
  case nl_token_pos:
  case nl_token_neg:
  case nl_token_funcall:
  case nl_token_concat:
    need_parens1 = 0;
    break;
  default:
    need_parens1 = 1;
    break;
  }

  switch ( arg2_tok ) {
  case nl_token_in:
  case nl_token_out:
  case nl_token_number:
  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct:
  case nl_token_bit:
  case nl_token_slice:
  case nl_token_varbit:
  case nl_token_bitnot:
  case nl_token_lognot:
  case nl_token_and_reduce:
  case nl_token_nand_reduce:
  case nl_token_or_reduce:
  case nl_token_nor_reduce:
  case nl_token_xor_reduce:
  case nl_token_xnor_reduce:
  case nl_token_pos:
  case nl_token_neg:
  case nl_token_funcall:
  case nl_token_concat:
    need_parens2 = 0;
    break;
  default:
    need_parens2 = 1;
    break;
  }

  if ( need_parens1 ) {
    unparse_token (ufp, "(", 0);
  }

  nl2v_dump_verilog (ufp, arg1, design, inputs, outputs);

  if ( need_parens1 ) {
    unparse_token (ufp, ")", 0);
  }

  unparse_token (ufp, op, 1);

  if ( need_parens2 ) {
    unparse_token (ufp, "(", 1);
  }
  else {
    unparse_token (ufp, "", 1);
  }

  nl2v_dump_verilog (ufp, arg2, design, inputs, outputs);

  if ( need_parens2 ) {
    unparse_token (ufp, ")", 0);
  }
}


static
void
nl2v_dump_verilog_number (unparse_fp ufp, char *radix, nl_ast tree,
			  nl_design design, ar inputs, ar outputs)
{
  nl_number_ast size_ast = (nl_number_ast) nl_ast_child (tree);
  nl_vnum_ast bits_ast = (nl_vnum_ast) nl_number_ast_sibling (size_ast);
  int size = nl_number_ast_value (size_ast);
  char *bits = nl_vnum_ast_bits (bits_ast);

  unparse_int (ufp, size, 0);
  unparse_token (ufp, radix, -1);
  unparse_token (ufp, bits, -1);
}

#if 0
static
void
nl2v_dump_sensitivity_list (unparse_fp ufp, nl_ast tree, nl_design design,
			    ar inputs, ar outputs, int first)
{
  nl_ast sens = tree;

  while ( sens != NULL ) {
    if ( !first )
      unparse_token (ufp, "or ", 1);
    else
      first = 0;

    if ( nl_ast_token (sens) == nl_token_concat ) {
      nl_ast child = nl_ast_child (sens);

      while ( nl_ast_sibling (child) != NULL ) {
	child = nl_ast_sibling (child);
      }

      nl2v_dump_sensitivity_list (ufp, child, design, inputs, outputs, 1);
    }
    else if ( nl_ast_token (sens) == nl_token_in ) {
      nl_in_ast in_ast = (nl_in_ast) sens;
      int index = nl_in_ast_index (in_ast);
      nl_pin pin;
      nl_net net;
      nl_bus bus;

      ar_ref (inputs, index, &pin);

      net = nl_pin_net (pin);

      bus = nl_net_bus (net);

      if ( bus != NULL ) {
	unparse_token (ufp, nl_bus_name (bus), 0);
      }
      else {
	unparse_token (ufp, nl_net_name (net), 0);
      }
    }
    else if ( nl_ast_token (sens) == nl_token_out ) {
      nl_out_ast in_ast = (nl_out_ast) sens;
      int index = nl_out_ast_index (in_ast);
      nl_pin pin;
      nl_net net;
      nl_bus bus;

      ar_ref (outputs, index, &pin);

      net = nl_pin_net (pin);

      bus = nl_net_bus (net);

      if ( bus != NULL ) {
	unparse_token (ufp, nl_bus_name (bus), 0);
      }
      else {
	unparse_token (ufp, nl_net_name (net), 0);
      }
    }
    else if ( nl_ast_token (sens) == nl_token_posedge ||
	      nl_ast_token (sens) == nl_token_negedge ) {
      nl_ast child = nl_ast_child (sens);
      const char *str = nl_token_to_string (nl_ast_token (sens));
      unparse_token (ufp, (char *) str, 0);
      unparse_token (ufp, "", 1);

      ASSERT (nl_ast_token (child) == nl_token_in);
      
      nl2v_dump_sensitivity_list (ufp, child, design, inputs, outputs, 1);
    }
    else {
      ASSERT (0);
    }

    sens = nl_ast_sibling (sens);
  }
}
#endif


static
void
nl2v_dump_verilog_always (unparse_fp ufp, nl_ast tree,
			  nl_design design, ar inputs, ar outputs)
{
  int base_indent = unparse_indent (ufp);
  nl_ast sens_list = nl_ast_child (tree);
  nl_ast stmt = nl_ast_sibling (sens_list);

  unparse_newline (ufp);
  unparse_token (ufp, "always", 0);
  if ( nl_ast_child (sens_list) != NULL ) {
    nl_ast sens = nl_ast_child (sens_list);
    int first = 1;

    unparse_token (ufp, "@(", 1);
    unparse_set_indent (ufp, base_indent + 9);
    while ( sens != NULL ) {
      if ( first )
	first = 0;
      else
	unparse_token (ufp, "or ", 1);

      nl2v_dump_verilog (ufp, sens, design, inputs, outputs);

      sens = nl_ast_sibling (sens);
    }
    unparse_token (ufp, ")", 0);
  }

  unparse_set_indent (ufp, base_indent + 2);
  nl2v_dump_verilog (ufp, stmt, design, inputs, outputs);
  unparse_set_indent (ufp, base_indent);
}


static
void
nl2v_dump_verilog_begin (unparse_fp ufp, nl_ast tree,
			 nl_design design, ar inputs, ar outputs)
{
  int base_indent = unparse_indent (ufp);
  nl_ast name_ast = nl_ast_child (tree);
  nl_ast stmt_ast = nl_ast_sibling (name_ast);

  unparse_token (ufp, "begin", 1);

  if ( nl_ast_token (name_ast) == nl_token_id ) {
    char *name = nl_id_ast_name ((nl_id_ast) name_ast);
    /* named begin */
    unparse_token (ufp, ":", 1);
    unparse_token (ufp, name, 0);
  }

  while ( stmt_ast != NULL ) {
    nl2v_dump_verilog (ufp, stmt_ast, design, inputs, outputs);
    stmt_ast = nl_ast_sibling (stmt_ast);
  }

  unparse_set_indent (ufp, base_indent);
  unparse_newline (ufp);
  unparse_token (ufp, "end", 0);
}
  

static
void
nl2v_dump_verilog_if (unparse_fp ufp, nl_ast tree,
		      nl_design design, ar inputs, ar outputs)
{
  nl_ast args_ast[3];
  int base_indent = unparse_indent (ufp);

  nl_ast_get_args (tree, 3, args_ast);
  unparse_newline (ufp);
  unparse_token (ufp, "if", 0);
  unparse_token (ufp, "(", 1);
  unparse_set_indent (ufp, 4 + base_indent);
  nl2v_dump_verilog (ufp, args_ast[0], design, inputs, outputs);
  unparse_token (ufp, ")", 0);

  unparse_set_indent (ufp, 2 + base_indent);
  nl2v_dump_verilog (ufp, args_ast[1], design, inputs, outputs);
  unparse_set_indent (ufp, base_indent);

  if ( args_ast[2] != NULL ) {
    unparse_newline (ufp);
    unparse_token (ufp, "else", 0);
    unparse_set_indent (ufp, base_indent + 2);
    nl2v_dump_verilog (ufp, args_ast[2], design, inputs, outputs);
  }

  unparse_set_indent (ufp, base_indent);
}


static
void
nl2v_dump_verilog_case (unparse_fp ufp, nl_ast tree,
			nl_design design, ar inputs, ar outputs)
{
  int base_indent = unparse_indent (ufp);
  nl_token token = nl_ast_token (tree);
  const char *kw = nl_token_to_string (token);
  nl_ast expr = nl_ast_child (tree);
  nl_ast pragmae = nl_ast_sibling (expr);
  nl_ast branch = nl_ast_sibling (pragmae);

  unparse_newline (ufp);
  unparse_token (ufp, (char *) kw, 0);

  unparse_token (ufp, "(", 1);
  unparse_set_indent (ufp, base_indent + 6);
  nl2v_dump_verilog (ufp, expr, design, inputs, outputs);
  unparse_token (ufp, ")", 0);

  unparse_set_indent (ufp, base_indent + 10);
  if ( nl_ast_child (pragmae) != NULL ) {
    nl_ast pragma = nl_ast_child (pragmae);

    unparse_token (ufp, "/* synopsys", 1);

    while ( pragma != NULL ) {
      nl_token which_pragma = nl_ast_token (pragma);

      unparse_token (ufp, (char *) nl_token_to_string (which_pragma), 1);

      pragma = nl_ast_sibling (pragma);
    }

    unparse_token (ufp, "*/", 1);
  }

  while ( branch != NULL ) {
    nl_ast stmts;

    unparse_newline (ufp);
    unparse_set_indent (ufp, base_indent + 2);

    if ( nl_ast_token (branch) == nl_token_case_item ) {
      nl_ast tags = nl_ast_child (branch);
      nl_ast tag = nl_ast_child (tags);
      int first = 1;

      while ( tag != NULL ) {
	if ( !first ) {
	  unparse_token (ufp, ",", -1);
	  unparse_token (ufp, "", 1);
	}
	else {
	  first = 0;
	}

	nl2v_dump_verilog (ufp, tag, design, inputs, outputs);

	tag = nl_ast_sibling (tag);
      }

      stmts = nl_ast_sibling (tags);
    }
    else if ( nl_ast_token (branch) == nl_token_default ) {
      unparse_token (ufp, "default", 0);
      stmts = nl_ast_child (branch);
    }
    else {
      ASSERT (0);
    }
    
    unparse_token (ufp, ":", 0);
    unparse_set_indent (ufp, base_indent + 4);
    nl2v_dump_verilog (ufp, stmts, design, inputs, outputs);

    branch = nl_ast_sibling (branch);
  }

  unparse_newline (ufp);
  unparse_set_indent (ufp, base_indent);
  unparse_token (ufp, "endcase", 0);
}


static
void
nl2v_dump_verilog_assignment (unparse_fp ufp, nl_ast tree,
			      nl_design design, ar inputs, ar outputs)
{
  int base_indent = unparse_indent (ufp);
  nl_ast rhs = nl_ast_child (tree);
  nl_ast lhs = nl_ast_sibling (rhs);
  nl_ast del = nl_ast_sibling (lhs);
  nl_token token = nl_ast_token (tree);
  
  unparse_newline (ufp);
  unparse_set_indent (ufp, base_indent + 2);
  nl2v_dump_verilog (ufp, lhs, design, inputs, outputs);

  if ( token == nl_token_block_assign ) {
    unparse_token (ufp, "=", 1);
  }
  else if ( token == nl_token_nonblock_assign ) {
    unparse_token (ufp, "<=", 1);
  }
  else {
    ASSERT (0);
  }

  if ( del != NULL ) {
    nl_ast child = nl_ast_child (del);
    unparse_token (ufp, "#", 1);
    nl2v_dump_verilog (ufp, child, design, inputs, outputs);
  }

  unparse_token (ufp, "", 1);

  nl2v_dump_verilog (ufp, rhs, design, inputs, outputs);

  unparse_token (ufp, ";", -1);
  unparse_set_indent (ufp, base_indent);
}


static
void
nl2v_dump_verilog_range (unparse_fp ufp, nl_ast tree,
			 nl_design design, ar inputs, ar outputs)
{
  if ( nl_ast_child (tree) != NULL ) {
    nl_ast l = nl_ast_child (tree);
    nl_ast r = nl_ast_sibling (l);

    unparse_token (ufp, "[", 1);
    nl2v_dump_verilog (ufp, l, design, NULL, NULL);
    unparse_token (ufp, ":", 0);
    nl2v_dump_verilog (ufp, r, design, NULL, NULL);
    unparse_token (ufp, "]", 0);
  }
}


#if 0
static
void
nl2v_dump_verilog_subprogram (unparse_fp ufp, nl_ast tree, nl_design design)
{
  int base_indent = unparse_indent (ufp);
  nl_token token = nl_ast_token (tree);
  const char *what = nl_token_to_string (token);
  nl_id_ast id;
  nl_ast body;

  unparse_newline (ufp);
  unparse_token (ufp, (char *) what, 0);

  unparse_set_indent (ufp, base_indent + 2);

  if ( token == nl_token_function ) {
    nl_ast range = nl_ast_child (tree);

    nl2v_dump_verilog_range (ufp, range, design, NULL, NULL);

    id = (nl_id_ast) nl_ast_sibling (range);
    body = nl_id_ast_sibling (id);
  }
  else if ( token == nl_token_task ) {
    id = (nl_id_ast) nl_ast_child (tree);
    body = nl_id_ast_sibling (id);
  }
  else {
    ASSERT (0);
  }

  {
    char *name = nl_id_ast_name (id);

    unparse_token (ufp, name, 1);
  }

  unparse_token (ufp, ";", -1);

  while ( body != NULL ) {
    nl_token token = nl_ast_token (body);

    if ( token == nl_token_input || token == nl_token_output ||
	 token == nl_token_inout || token == nl_token_wire ||
	 token == nl_token_reg   || token == nl_token_integer ) {
      nl2v_dump_verilog (ufp, body, design, NULL, NULL);
      body = nl_ast_sibling (body);
    }
    else {
      unparse_newline (ufp);
      unparse_set_indent (ufp, base_indent + 4);
      nl2v_dump_verilog (ufp, body, design, NULL, NULL);
      ASSERT (nl_ast_sibling (body) == NULL);
      break;
    }
  }

  unparse_newline (ufp);
  unparse_set_indent (ufp, base_indent);
  unparse_token (ufp, "end", 0);
  unparse_token (ufp, (char *) what, -1);
  unparse_newline (ufp);
}
#endif


static
void
nl2v_dump_verilog_declaration (unparse_fp ufp, nl_ast tree)
{
  nl_token token = nl_ast_token (tree);
  const char *wireclass = nl_token_to_string (token);
  nl_ast range = nl_ast_child (tree);
  nl_id_ast id = (nl_id_ast) nl_ast_sibling (range);
  int first = 1;

  unparse_newline (ufp);
  unparse_token (ufp, (char *) wireclass, 0);

  nl2v_dump_verilog_range (ufp, range, NULL, NULL, NULL);

  while ( id != NULL ) {
    char *name = nl_id_ast_name (id);

    if ( !first ) {
      unparse_token (ufp, ",", -1);
    }
    else {
      first = 0;
    }
      
    unparse_token (ufp, name, 1);

    id = (nl_id_ast) nl_id_ast_sibling (id);
  }

  unparse_token (ufp, ";", -1);
}


static
void
nl2v_dump_verilog_for (unparse_fp ufp, nl_ast tree,
		       nl_design design, ar inputs, ar outputs)
{
  int base_indent = unparse_indent (ufp);
  nl_ast args[4];

  nl_ast_get_args (tree, 4, args);

  unparse_newline (ufp);
  unparse_token (ufp, "for", 0);

  unparse_set_indent (ufp, base_indent + 5);
  unparse_token (ufp, "(", 1);

  {
    nl_ast init_rhs = nl_ast_child (args[0]);
    nl_ast init_lhs = nl_ast_sibling (init_rhs);

    nl2v_dump_verilog (ufp, init_lhs, design, inputs, outputs);
    unparse_token (ufp, "=", 1);
    nl2v_dump_verilog (ufp, init_rhs, design, inputs, outputs);
  }

  unparse_token (ufp, ";", -1);
  nl2v_dump_verilog (ufp, args[1], design, inputs, outputs);
  unparse_token (ufp, ";", -1);

  {
    nl_ast incr_rhs = nl_ast_child (args[2]);
    nl_ast incr_lhs = nl_ast_sibling (incr_rhs);

    nl2v_dump_verilog (ufp, incr_lhs, design, inputs, outputs);
    unparse_token (ufp, "=", 1);
    nl2v_dump_verilog (ufp, incr_rhs, design, inputs, outputs);
  }

  unparse_token (ufp, ")", 0);

  unparse_set_indent (ufp, base_indent + 2);

  nl2v_dump_verilog (ufp, args[3], design, inputs, outputs);

  unparse_set_indent (ufp, base_indent);
}


static
void
nl2v_dump_verilog_bit_and_slice (unparse_fp ufp, nl_ast tree,
				 nl_design design, ar inputs, ar outputs)
{
  nl_ast args[3];

  nl_ast_get_args (tree, 3, args);

  nl2v_dump_verilog (ufp, args[0], design, inputs, outputs);

  unparse_token (ufp, "[", 0);
  nl2v_dump_verilog (ufp, args[1], design, inputs, outputs);

  if ( args[2] != NULL ) {
    unparse_token (ufp, ":", 0);
    nl2v_dump_verilog (ufp, args[2], design, inputs, outputs);
  }

  unparse_token (ufp, "]", 0);
}


static
void
nl2v_dump_concat (unparse_fp ufp, nl_ast tree, nl_design design,
		  ar inputs, ar outputs, int need_braces)
{
  nl_ast child = nl_ast_child (tree);
  int is_net_bundle = 1;
  ar nets = ar_alloc (0, sizeof (nl_net));

  while ( child != NULL ) {
    nl_token token = nl_ast_token (child);

    if ( token == nl_token_in ) {
      nl_in_ast in_ast = (nl_in_ast) child;
      int index = nl_in_ast_index (in_ast);
      nl_pin pin;
      nl_net net;

      ar_ref (inputs, index, &pin);

      net = nl_pin_net (pin);

      ar_add (nets, &net);
    }
    else if ( token == nl_token_out ) {
      nl_out_ast out_ast = (nl_out_ast) child;
      int index = nl_out_ast_index (out_ast);
      nl_pin pin;
      nl_net net;

      ar_ref (outputs, index, &pin);

      net = nl_pin_net (pin);

      ar_add (nets, &net);
    }
    else {
      is_net_bundle = 0;
      break;
    }

    child = nl_ast_sibling (child);
  }

  if ( is_net_bundle ) {
    unparse_token (ufp, "", 1);
    nl2v_write_net_bundle (ufp, nets, NULL, need_braces);
  }
  else {
    unparse_token (ufp, "{", 0);
    nl2v_dump_verilog_expression_list (ufp, nl_ast_child (tree),
				       design, inputs, outputs);
    unparse_token (ufp, "}", 0);
  }

  ar_free (nets);
}
  

static
void
nl2v_dump_verilog (unparse_fp ufp, nl_ast root, nl_design design,
		   ar inputs, ar outputs)
{
  nl_token token = nl_ast_token (root);

  switch ( token ) {
  case nl_token_number:
    unparse_int (ufp, nl_number_ast_value ((nl_number_ast) root), 1);
    break;

  case nl_token_in: {
    nl_in_ast in_ast = (nl_in_ast) root;
    int index = nl_in_ast_index (in_ast);
    nl_pin pin;
    nl_net net;

    ar_ref (inputs, index, &pin);

    net = nl_pin_net (pin);

    nl2v_write_net_ref (ufp, net, 0);
    break;
  }

  case nl_token_out: {
    nl_out_ast in_ast = (nl_out_ast) root;
    int index = nl_out_ast_index (in_ast);
    nl_pin pin;
    nl_net net;

    ar_ref (outputs, index, &pin);

    net = nl_pin_net (pin);

    nl2v_write_net_ref (ufp, net, 0);
    break;
  }

  case nl_token_lognot:
    nl2v_dump_unary_op (ufp, "!", root, design, inputs, outputs);
    break;
  case nl_token_bitnot:
    nl2v_dump_unary_op (ufp, "~", root, design, inputs, outputs);
    break;
  case nl_token_and_reduce:
    nl2v_dump_unary_op (ufp, "&", root, design, inputs, outputs);
    break;
  case nl_token_or_reduce:
    nl2v_dump_unary_op (ufp, "|", root, design, inputs, outputs);
    break;
  case nl_token_xor_reduce:
    nl2v_dump_unary_op (ufp, "^", root, design, inputs, outputs);
    break;
  case nl_token_nand_reduce:
    nl2v_dump_unary_op (ufp, "&~", root, design, inputs, outputs);
    break;
  case nl_token_nor_reduce:
    nl2v_dump_unary_op (ufp, "|~", root, design, inputs, outputs);
    break;
  case nl_token_xnor_reduce:
    nl2v_dump_unary_op (ufp, "~^", root, design, inputs, outputs);
    break;

  case nl_token_posedge:
    unparse_token (ufp, "posedge", 0);
    unparse_token (ufp, "", 1);
    nl2v_dump_verilog (ufp, nl_ast_child (root), design, inputs, outputs);
    break;
  case nl_token_negedge:
    unparse_token (ufp, "negedge", 0);
    unparse_token (ufp, "", 1);
    nl2v_dump_verilog (ufp, nl_ast_child (root), design, inputs, outputs);
    break;

  case nl_token_andand:
    nl2v_dump_binary_op (ufp, "&&", root, design, inputs, outputs);
    break;
  case nl_token_oror:
    nl2v_dump_binary_op (ufp, "||", root, design, inputs, outputs);
    break;
  case nl_token_eq2:
    nl2v_dump_binary_op (ufp, "==", root, design, inputs, outputs);
    break;
  case nl_token_eq3:
    nl2v_dump_binary_op (ufp, "===", root, design, inputs, outputs);
    break;
  case nl_token_neq:
    nl2v_dump_binary_op (ufp, "!=", root, design, inputs, outputs);
    break;
  case nl_token_neq2:
    nl2v_dump_binary_op (ufp, "!==", root, design, inputs, outputs);
    break;
  case nl_token_lt:
    nl2v_dump_binary_op (ufp, "<", root, design, inputs, outputs);
    break;
  case nl_token_gt:
    nl2v_dump_binary_op (ufp, ">", root, design, inputs, outputs);
    break;
  case nl_token_leq:
    nl2v_dump_binary_op (ufp, "<=", root, design, inputs, outputs);
    break;
  case nl_token_geq:
    nl2v_dump_binary_op (ufp, ">=", root, design, inputs, outputs);
    break;
  case nl_token_add:
    nl2v_dump_binary_op (ufp, "+", root, design, inputs, outputs);
    break;
  case nl_token_sub:
    nl2v_dump_binary_op (ufp, "-", root, design, inputs, outputs);
    break;
  case nl_token_mul:
    nl2v_dump_binary_op (ufp, "*", root, design, inputs, outputs);
    break;
  case nl_token_div:
    nl2v_dump_binary_op (ufp, "/", root, design, inputs, outputs);
    break;
  case nl_token_and:
    nl2v_dump_binary_op (ufp, "&", root, design, inputs, outputs);
    break;
  case nl_token_or:
    nl2v_dump_binary_op (ufp, "|", root, design, inputs, outputs);
    break;
  case nl_token_xor:
    nl2v_dump_binary_op (ufp, "^", root, design, inputs, outputs);
    break;
  case nl_token_nand:
    nl2v_dump_binary_op (ufp, "&~", root, design, inputs, outputs);
    break;
  case nl_token_nor:
    nl2v_dump_binary_op (ufp, "|~", root, design, inputs, outputs);
    break;
  case nl_token_xnor:
    nl2v_dump_binary_op (ufp, "^~", root, design, inputs, outputs);
    break;
  case nl_token_shl:
    nl2v_dump_binary_op (ufp, "<<", root, design, inputs, outputs);
    break;
  case nl_token_varshl:
    nl2v_dump_binary_op (ufp, "<< /*var*/", root, design, inputs, outputs);
    break;
  case nl_token_shr:
    nl2v_dump_binary_op (ufp, ">>", root, design, inputs, outputs);
    break;
  case nl_token_varshr:
    nl2v_dump_binary_op (ufp, ">> /*var*/", root, design, inputs, outputs);
    break;
  case nl_token_bin:
    nl2v_dump_verilog_number (ufp, "'b", root, design, inputs, outputs);
    break;
  case nl_token_hex:
    nl2v_dump_verilog_number (ufp, "'h", root, design, inputs, outputs);
    break;
  case nl_token_dec:
    nl2v_dump_verilog_number (ufp, "'d", root, design, inputs, outputs);
    break;
  case nl_token_oct:
    nl2v_dump_verilog_number (ufp, "'o", root, design, inputs, outputs);
    break;

  case nl_token_cond: {
    nl_ast args[3];

    nl_ast_get_args (root, 3, args);
    unparse_token (ufp, "(", 1);
    nl2v_dump_verilog (ufp, args[0], design, inputs, outputs);
    unparse_token (ufp, ")", 0);
    unparse_token (ufp, "?", 1);
    unparse_token (ufp, "(", 1);
    nl2v_dump_verilog (ufp, args[1], design, inputs, outputs);
    unparse_token (ufp, ")", 0);
    unparse_token (ufp, ":", 1);
    unparse_token (ufp, "(", 1);
    nl2v_dump_verilog (ufp, args[2], design, inputs, outputs);
    unparse_token (ufp, ")", 0);
    break;
  }

  case nl_token_concat:
    nl2v_dump_concat (ufp, root, design, inputs, outputs, 0);
    break;

  case nl_token_repeat_concat: {
    nl_number_ast count_ast = (nl_number_ast) nl_ast_child (root);
    nl_ast concat_ast = nl_number_ast_sibling (count_ast);
    int count = nl_number_ast_value (count_ast);

    ASSERT (nl_ast_token (concat_ast) == nl_token_concat);

    unparse_token (ufp, "{", 1);
    unparse_int (ufp, count, 0);
    nl2v_dump_concat (ufp, concat_ast, design, inputs, outputs, 1);
    unparse_token (ufp, "}", 0);
    break;
  }

  case nl_token_funcall: {
    nl_id_ast fun_ast = (nl_id_ast) nl_ast_child (root);
    char *fun_name = nl_id_ast_name (fun_ast);
    nl_ast args_ast = nl_id_ast_sibling (fun_ast);
    
    unparse_token (ufp, fun_name, 1);
    unparse_token (ufp, "(", 1);
    nl2v_dump_verilog_expression_list (ufp, args_ast, design, inputs, outputs);
    unparse_token (ufp, ")", 0);
    break;
  }

  case nl_token_always:
    nl2v_dump_verilog_always (ufp, root, design, inputs, outputs);
    break;

  case nl_token_begin:
    nl2v_dump_verilog_begin (ufp, root, design, inputs, outputs);
    break;

  case nl_token_if:
    nl2v_dump_verilog_if (ufp, root, design, inputs, outputs);
    break;
    
  case nl_token_case:
  case nl_token_casex:
  case nl_token_casez:
    nl2v_dump_verilog_case (ufp, root, design, inputs, outputs);
    break;

  case nl_token_for:
    nl2v_dump_verilog_for (ufp, root, design, inputs, outputs);
    break;

  case nl_token_block_assign:
  case nl_token_nonblock_assign:
    nl2v_dump_verilog_assignment (ufp, root, design, inputs, outputs);
    break;

  case nl_token_ref:
  case nl_token_lref: {
    nl_ref_ast ref_ast = (nl_ref_ast) root;
    nl_object obj = nl_ref_ast_object (ref_ast);

    if ( nl_object_kind (obj) == nl_kind_net ) {
      nl_net net = (nl_net) obj;

      nl2v_write_net_ref (ufp, net, 0);
    }
    else if ( nl_object_kind (obj) == nl_kind_bus ) {
      nl_bus bus = (nl_bus) obj;
      char *name = nl_bus_name (bus);

      unparse_token (ufp, name, 0);
    }
    else if ( nl_object_kind (obj) == nl_kind_symbol ) {
      nl_symbol symbol = (nl_symbol) obj;
      char *name = nl_symbol_name (symbol);

      unparse_token (ufp, name, 0);
    }
    else {
      ASSERT (0);
    }

    break;
  }

#if 0
  case nl_token_task:
  case nl_token_function:
    nl2v_dump_verilog_subprogram (ufp, root, design);
    break;
#endif

  case nl_token_input:
  case nl_token_output:
  case nl_token_wire:
  case nl_token_reg: 
  case nl_token_integer: 
    nl2v_dump_verilog_declaration (ufp, root);
    break;

  case nl_token_bit:
  case nl_token_slice:
  case nl_token_varbit:
    nl2v_dump_verilog_bit_and_slice (ufp, root, design, inputs, outputs);
    break;

  default:
    ASSERT (0);
  }
}


static
void
nl2v_unparse_verilog_expression (unparse_fp ufp, nl_reference reference,
				 nl_design design, ar inputs, ar outputs)
{
  nl_ast root;

  root = nl_reference_tree (reference);
  nl2v_dump_verilog (ufp, root, design, inputs, outputs);
}


static
void
nl2v_write_expression (unparse_fp ufp, nl_cell cell)
{
  unparse_token (ufp, "assign", 1);
  unparse_set_indent (ufp, 4);
  unparse_token (ufp, "{", 1);

  {
    int first = 1;

    nl_cell_for_all_outputs (cell, out_pin) {
      nl_net out_net = nl_pin_net (out_pin);

      if ( !first ) {
	unparse_token (ufp, ",", -1);
      }
      else {
	first = 0;
      }

      nl2v_write_net_ref (ufp, out_net, 1);
    } nl_end_for;
  }

  unparse_token (ufp, "}", 0);
  unparse_token (ufp, "=", 1);
  unparse_token (ufp, "", 1);

  {
    nl_reference reference = nl_cell_reference (cell);
    nl_design design = nl_cell_design (cell);
    ar inputs = nl_cell_inputs (cell);
    ar outputs = nl_cell_outputs (cell);

    nl2v_unparse_verilog_expression (ufp, reference, design, inputs, outputs);
  }

  unparse_token (ufp, ";", -1);
  unparse_newline (ufp);
  unparse_set_indent (ufp, 2);
}


static
void
nl2v_unparse_verilog_process (unparse_fp ufp, nl_reference reference,
			      nl_design design, ar inputs, ar outputs)
{
  nl_ast root;
  
  root = nl_reference_tree (reference);
  nl2v_dump_verilog (ufp, root, design, inputs, outputs);
}


static
void
nl2v_write_process (unparse_fp ufp, nl_cell cell)
{
  nl_design design = nl_cell_design (cell);
  ar inputs = nl_cell_inputs (cell);
  ar outputs = nl_cell_outputs (cell);
  nl_reference reference = nl_cell_reference (cell);
  
  unparse_newline (ufp);
  unparse_set_indent (ufp, 2);
  unparse_token (ufp, "/*", 0);
  unparse_set_indent (ufp, 6);
  unparse_token (ufp, "inputs:", 1);
  nl_cell_for_all_inputs (cell, pin) {
    nl_net net = nl_pin_net (pin);
    char *net_name = nl_net_name (net);

    unparse_token (ufp, net_name, 1);
  } nl_end_for;
  unparse_token (ufp, "*/", 1);
    
  unparse_newline (ufp);
  unparse_set_indent (ufp, 2);
  unparse_token (ufp, "/*", 0);
  unparse_set_indent (ufp, 6);
  unparse_token (ufp, "outputs:", 1);
  nl_cell_for_all_outputs (cell, pin) {
    nl_net net = nl_pin_net (pin);
    char *net_name = nl_net_name (net);

    unparse_token (ufp, net_name, 1);
  } nl_end_for;
  unparse_token (ufp, "*/", 1);
    
  unparse_newline (ufp);
  unparse_set_indent (ufp, 2);
  unparse_token (ufp, "/*", 0);
  unparse_set_indent (ufp, 6);
  unparse_token (ufp, "inouts:", 1);
  nl_cell_for_all_inouts (cell, pin) {
    nl_net net = nl_pin_net (pin);
    char *net_name = nl_net_name (net);

    unparse_token (ufp, net_name, 1);
  } nl_end_for;
  unparse_token (ufp, "*/", 1);
    
  unparse_set_indent (ufp, 2);
  nl2v_unparse_verilog_process (ufp, reference, design, inputs, outputs);
  unparse_newline (ufp);
}


static
void
nl2v_write_subprograms (unparse_fp ufp, nl_design design)
{
  int written = 0;

  nl_design_for_all_subprograms (design, subprogram) {
    char *name = nl_subprogram_name (subprogram);
    nl_type type = nl_subprogram_type (subprogram);
    /* nl_ast pragmas = nl_subprogram_pragmas (subprogram); */
    nl_ast body = nl_subprogram_body (subprogram);

    unparse_newline (ufp);
    unparse_token (ufp, "function", 1);
    nl2v_write_type (ufp, type);
    unparse_token (ufp, name, 1);
    unparse_token (ufp, ";", -1);
    unparse_newline (ufp);
    unparse_set_indent (ufp, 4);

    nl_subprogram_for_all_formals (subprogram, formal) {
      nl_wireclass class = nl_symbol_class (formal);
      const char *class_str = nl_wireclass_to_string (class);
      nl_type type = nl_symbol_type (formal);
      char *name = nl_symbol_name (formal);

      unparse_token (ufp, (char *) class_str, 0);
      nl2v_write_type (ufp, type);
      unparse_token (ufp, name, 1);
      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
    } nl_end_for;

    nl_subprogram_for_all_locals (subprogram, local) {
      nl_wireclass class = nl_symbol_class (local);
      const char *class_str = nl_wireclass_to_string (class);
      nl_type type = nl_symbol_type (local);
      char *name = nl_symbol_name (local);

      unparse_token (ufp, (char *) class_str, 0);
      nl2v_write_type (ufp, type);
      unparse_token (ufp, name, 1);
      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
    } nl_end_for;

    nl2v_dump_verilog (ufp, body, design, NULL, NULL);

    unparse_newline (ufp);
    unparse_set_indent (ufp, 2);
    unparse_token (ufp, "endfunction", 0);
    unparse_newline (ufp);
    
#if 0
    nl2v_dump_verilog (ufp, nl_subprogram_tree (subprogram), design,
		       NULL, NULL);
#endif

    written++;
  } nl_end_for;
}


static
void
nl2v_write_reference (unparse_fp ufp, nl_reference reference)
{
  ar params = nl_reference_parameters (reference);
  char *ref_name = nl_reference_name (reference);
  char *base_name;

  if ( ar_size (params) == 0 ) {
    base_name = ref_name;
  }
  else {
    char *s;

    base_name = STRDUPA (ref_name);
    s = base_name;

    while ( *s && *s != '#' ) {
      s++;
    }

    *s = 0;
  }

  nl2v_write_identifier (ufp, base_name, 0);

  if ( ar_size (params) > 0 ) {
    unparse_token (ufp, "#(", 1);

    ar_for_all_indexed (params, int, param, count) {
      if ( count > 0 ) {
	unparse_token (ufp, ",", -1);
	unparse_token (ufp, "", 1);
      }
      
      unparse_int (ufp, param, 0);
    } ar_end_for;

    unparse_token (ufp, ")", -1);
  }
}


static
void
nl2v_write_cells (unparse_fp ufp, nl_design design)
{
  int count = 0;
  int unconnected_count = 0;
  nl_design_for_all_cells (design, cell) {
    char *cell_name = nl_cell_name (cell);
    nl_reference reference = nl_cell_reference (cell);
    char *ref_name = nl_reference_name (reference);

    if ( count == 0 ) {
      unparse_newline (ufp);
    }

    if ( strcmp (ref_name, "*assignment*") == 0 ) {
      nl2v_write_assignment (ufp, cell);
    }
    else if ( strncmp (ref_name, "*expression", 11) == 0 ) {
      nl2v_write_expression (ufp, cell);
    }
    else if ( strncmp (ref_name, "*process", 8) == 0 ) {
      nl2v_write_process (ufp, cell);
    }
    else if ( strncmp (ref_name, "*tran*", 6) == 0 ) {
      nl2v_write_tran (ufp, cell);
    }
    else {
      nl2v_write_reference (ufp, reference);
      unparse_set_indent (ufp, 4);
      nl2v_write_identifier (ufp, cell_name, 1);
      unparse_token (ufp, "(", 1);
      unparse_set_indent (ufp, 6);

      nl2v_write_pins (ufp, cell, reference, &unconnected_count);

      unparse_token (ufp, ")", -1);
      unparse_token (ufp, ";", -1);
      unparse_newline (ufp);
      unparse_set_indent (ufp, 2);
    }

    count++;
  } nl_end_for;
}


static
void
nl2v_write_design (unparse_fp ufp, nl_design design, int hierarchy,
		   int libcell_stubs, nl_design_attr written_designs)
{
  int is_libcell = nl_design_libcell (design);

  if ( hierarchy && !(libcell_stubs && is_libcell) ) {
    int flag;

    nl_design_attr_get (written_designs, design, &flag);

    if ( flag ) {
      return;
    }
    else {
      int one = 1;

      nl_design_attr_set (written_designs, design, &one);

      nl_design_for_all_references (design, reference) {
	int num_instances = nl_reference_num_instances (reference);
	if ( num_instances > 0 ) {
	  nl_object down_object = nl_reference_down_design (reference);

	  if ( down_object != NULL &&
	       nl_object_kind (down_object) == nl_kind_design ) {
	    nl_design down_design = (nl_design) down_object;
	    int is_down_design_libcell = nl_design_libcell (down_design);

	    if ( ! is_down_design_libcell || libcell_stubs ) {
	      nl2v_write_design (ufp, down_design, hierarchy, libcell_stubs,
				 written_designs);
	    }
	  }
	}
      } nl_end_for;
    }
  }

  {
    nl_net_attr written_nets
      = nl_net_attr_create ("nl2v written nets", design, nl_density_dense,
			    sizeof (int), NULL, NULL);

    unparse_newline (ufp);
    unparse_token (ufp, "module", 0);
    unparse_set_indent (ufp, 4);
    nl2v_write_identifier (ufp, nl_design_name (design), 1);

    nl2v_write_port_list (ufp, design);

    unparse_set_indent (ufp, 2);

    nl2v_write_ports (ufp, design, written_nets);

    if ( !(is_libcell && libcell_stubs) ) {
      nl2v_write_supplies (ufp, design, written_nets);
      nl2v_write_buses (ufp, design, written_nets);
      nl2v_write_nets (ufp, design, written_nets);
      nl2v_write_port_connections (ufp, design);
      nl2v_write_subprograms (ufp, design);
      nl2v_write_cells (ufp, design);
    }

    nl_design_remove_attr (design, (nl_attr) written_nets);
    
    unparse_newline (ufp);
    unparse_set_indent (ufp, 0);
    unparse_token (ufp, "endmodule", 0);
    unparse_newline (ufp);
  }
}


int
nl2v_write_verilog (FILE *ofp, nl_design design, int hierarchy,
		    int libcell_stubs)
{
  unparse_fp ufp;
  nl_design_attr written_designs
    = nl_design_attr_create ("nl2v written designs", design, nl_density_sparse,
			     sizeof (int), NULL, NULL);
    
  fprintf (ofp, "// VERILOG netlist for \"%s\" (generated by nl_shell)\n\n",
	   nl_design_name (design));

  ufp = unparse_open (ofp);
  unparse_set_line_limit (ufp, 76);

  nl2v_write_design (ufp, design, hierarchy, libcell_stubs, written_designs);

  nl_design_remove_attr (design, (nl_attr) written_designs);

  unparse_close (ufp);

  return 1;
}

