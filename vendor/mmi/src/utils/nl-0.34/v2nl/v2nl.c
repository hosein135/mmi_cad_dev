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
#include "str.h"
#include "stdpccts.h"
#include "v2nl_gettok.h"

const gettok_fun v2nl_current_gettok;
int v2nl_ports_only = 0;
int v2nl_ports_only_skip = 0;
int v2nl_rtl = 0;
nl_design v2nl_current_design;
nl_subprogram v2nl_current_subprogram;
char *v2nl_current_file = NULL;

static nl_context current_context;
static char *current_design_name;
static hashtab current_ext_names;
static hashtab current_int_names;
static ht_attr port_nets;
static ht_attr port_dirs;
static ht_attr int_to_ext_map;
static ar ext_name_list;
static char *bus_naming_style;
static int v2nl_assignment_num;
static int v2nl_primitive_num;


static ar designs_read;

mem_group v2nl_mem_group = NULL;

static void  v2nl_create_ports (void);

static hashtab v2nl_parameter_table;
static ht_attr v2nl_parameter_value;

static nl_named_object v2nl_get_net (char *);


void
v2nl_parameter (char *name, nl_ast value)
{
  ht_entry entry = ht_lookup (v2nl_parameter_table, name);

  if ( entry == ht_null ) {
    entry = ht_insert (v2nl_parameter_table, name);
    ht_set_attribute_for_entry (v2nl_parameter_value, entry, &value);
  }
}


int
v2nl_get_parameter (char *name, nl_ast *value_p)
{
  ht_entry entry = ht_lookup (v2nl_parameter_table, name);

  if ( entry == ht_null ) {
    return 0;
  }
  else {
    ht_get_attribute_for_entry (v2nl_parameter_value, entry, value_p);

    return 1;
  }
}


static
void
v2nl_free_parameter_value (void *value_p)
{
  nl_ast tree = *(nl_ast *) value_p;

  if ( tree != NULL ) {
    nl_ast_free_tree (tree);
  }
}


static
int
v2nl_implicit_wires_ok = 0;


void
v2nl_rtl_allow_implicit_wires (int flag)
{
  v2nl_implicit_wires_ok = flag;
}


nl_ast
v2nl_rtl_var_ref (Attrib *attr, int *es_parameter_p)
{
  char *name = attr->text;
  nl_ast result;
  
  if ( v2nl_rtl ) {
    nl_ast value;
    int flag = v2nl_get_parameter (name, &value);

    if ( flag ) {
      result = nl_ast_copy_tree (value);
    }
    else {
      nl_ref_ast ref_ast;
      nl_symbol sym = NULL;

      if ( v2nl_current_subprogram != NULL ) {
	sym = nl_subprogram_get_symbol_by_name (v2nl_current_subprogram, name);
      }

      if ( sym != NULL ) {
	ref_ast = nl_ref_ast_create (nl_token_ref, (nl_object) sym);
      }
      else {
	nl_named_object net_or_bus
	  = nl_design_get_net_or_bus_by_name (v2nl_current_design, name);

	if ( net_or_bus == NULL ) {
	  if ( v2nl_implicit_wires_ok ) {
	    net_or_bus = v2nl_get_net (name);
	  }
	  else {
	    v2nl_error ("undeclared variable, %s", name);
	  }
	}

	ref_ast = nl_ref_ast_create (nl_token_ref, (nl_object) net_or_bus);
      }

      result = (nl_ast) ref_ast;
    }

    *es_parameter_p = flag;
  }
  else {
    /* no es RTL */
    *es_parameter_p = 0;
    result = NULL;
  }

  if ( result != NULL ) {
    char *file = attr->file;
    int line = attr->line;

    nl_ast_set_file_line (result, file, line);
  }
    
  return result;
}


nl_ast
v2nl_make_shift (nl_ast op, nl_ast l, nl_ast r)
{
  int amount;
  int flag = v2nl_eval_expr (r, &amount);
  nl_ast result;

  nl_ast_set_sibling (op, NULL);
  nl_ast_set_sibling (l, NULL);

  if ( flag ) {
    /* right arg was constant */
    nl_number_ast num_ast = nl_number_ast_create (amount);

    nl_ast_free_tree (r);
    result = nl_ast_make (op, l, num_ast, NULL);
  }
  else {
    nl_token token = nl_ast_token (op);
    nl_ast op_ast;
    
    if ( token == nl_token_shr ) {
      op_ast = nl_ast_create (nl_token_varshr);
    }
    else if ( token == nl_token_shl ) {
      op_ast = nl_ast_create (nl_token_varshl);
    }
    else {
      ASSERT (0);
    }

    nl_ast_free (op);
    result = nl_ast_make (op_ast, l, r, NULL);
  }

  return result;
}


static hashtab v2nl_attributes;
static ht_attr v2nl_attribute_attrs;
static ht_attr v2nl_attribute_types;
static hashtab v2nl_active_attributes;
static ht_attr v2nl_active_int_values;
static ht_attr v2nl_active_string_values;


static
void
v2nl_free_string_attr (void *ptr)
{
  char *str = *(char **) ptr;

  if ( str != NULL ) {
    FREE (str);
  }
}


void
v2nl_new_attribute (char *name, nl_density density, char object, char type)
{
  ht_entry entry = ht_lookup (v2nl_attributes, name);
  nl_attr new_attr;
  int size;
  nl_free_fun free_fun;

  if ( entry != ht_null ) {
    v2nl_error ("attempt to redeclare attribute %s", name);
  }

  entry = ht_insert (v2nl_attributes, name);

  ht_set_attribute_for_entry (v2nl_attribute_types, entry, &type);

  switch (type) {
  case 'i':
  case 'b':
    size = sizeof (int);
    free_fun = NULL;
    break;
  case 's':
    size = sizeof (char *);
    free_fun = v2nl_free_string_attr;
    break;
  default:
    ASSERT (0);
  }
  
  switch (object) {
  case 'c':
    new_attr = (nl_attr) nl_cell_attr_create (name, v2nl_current_design,
					      density, size, NULL, free_fun);
    break;
  case 'p':
    new_attr = (nl_attr) nl_port_attr_create (name, v2nl_current_design,
					      density, size, NULL, free_fun);
    break;
  case 'n':
    new_attr = (nl_attr) nl_net_attr_create (name, v2nl_current_design,
					     density, size, NULL, free_fun);
    break;
  case 'd':
    new_attr = (nl_attr) nl_design_attr_create (name, v2nl_current_design,
						density, size, NULL, free_fun);
    break;
  default:
    ASSERT (0);
  }

  ht_set_attribute_for_entry (v2nl_attribute_attrs, entry, &new_attr);
}


static
nl_attr
v2nl_get_attribute (char *name, char type) UNUSED;


static
nl_attr
v2nl_get_attribute (char *name, char type)
{
  ht_entry entry = ht_lookup (v2nl_attributes, name);
  char attr_type;

  ASSERT (entry != ht_null);

  ht_get_attribute_for_entry (v2nl_attribute_types, entry, &attr_type);

  if ( type != attr_type ) {
    char *type_str;
    char *attr_type_str;

    switch (type) {
    case 'b': type_str = "boolean"; break;
    case 'i': type_str = "integer"; break;
    case 's': type_str = "string"; break;
    default:
      ASSERT (0);
    }

    switch (attr_type) {
    case 'b': attr_type_str = "boolean"; break;
    case 'i': attr_type_str = "integer"; break;
    case 's': attr_type_str = "string"; break;
    default:
      ASSERT (0);
    }

    v2nl_error ("attempt to use %s attribute %s as %s",
		attr_type_str, name, type_str);
  }
  else {
    nl_attr attr;

    ht_get_attribute_for_entry (v2nl_attribute_attrs, entry, &attr);

    return attr;
  }
}
  


void
v2nl_begin_boolean_attribute (char *name)
{
  ht_entry entry = ht_insert (v2nl_active_attributes, name);
  int flag = 1;

  ht_set_attribute_for_entry (v2nl_active_int_values, entry, &flag);
}

  
void
v2nl_begin_integer_attribute (char *name, int value)
{
  ht_entry entry = ht_insert (v2nl_active_attributes, name);

  ht_set_attribute_for_entry (v2nl_active_int_values, entry, &value);
}

  
void
v2nl_begin_string_attribute (char *name, char *value)
{
  ht_entry entry = ht_insert (v2nl_active_attributes, name);
  char *str = STRDUP (value);

  ht_set_attribute_for_entry (v2nl_active_string_values, entry, &str);
}


void
v2nl_end_attribute (char *name)
{
  ht_entry entry = ht_delete (v2nl_active_attributes, name);

  if ( entry == ht_null ) {
    v2nl_error ("attempt to end attribute %s, which has no begin statement.",
		name);
  }
}


void
v2nl_set_attributes (nl_object obj)
{
  nl_kind obj_kind = nl_object_kind (obj);

  ht_for_all_entries (v2nl_active_attributes, entry) {
    char *name = ht_get_key (v2nl_active_attributes, entry);
    ht_entry attr_entry = ht_lookup (v2nl_attributes, name);
    nl_attr attr;
    nl_kind kind;

    ASSERT (attr_entry != ht_null);

    ht_get_attribute_for_entry (v2nl_attribute_attrs, attr_entry, &attr);

    kind = nl_attr_attr_of (attr);

    if ( kind == obj_kind ) {
      char type;

      ht_get_attribute_for_entry (v2nl_attribute_types, attr_entry, &type);

      switch (type) {
      case 'b':
      case 'i': {
	int value;
	ht_get_attribute_for_entry (v2nl_active_int_values, entry, &value);
	nl_attr_set (attr, obj, &value);
	break;
      }
      case 's': {
	char *value;
	ht_get_attribute_for_entry (v2nl_active_string_values, entry, &value);
	nl_attr_set (attr, obj, &value);
	break;
      }
      default:
	ASSERT (0);
      }
    }
  } ht_end_for;
}
    
  
static
void
v2nl_check_cell_net_port_name (char *name)
{
  nl_named_object obj = nl_design_get_object_by_name (v2nl_current_design, name);

  if ( obj != NULL && nl_named_object_kind (obj) != nl_kind_reference ) {
    v2nl_error ("Redeclaration of '%s'", name);
  }
}


static
void
v2nl_free_array (void *ar_p)
{
  ar a = *(ar *)ar_p;

  if ( a != NULL )
    ar_free (a);
}


void
v2nl_mod (char *name)
{
  char *tmp_name = str_append ("design ", name, NULL);
  mem_group g;

  current_design_name = STRDUP (name);
  
  v2nl_current_design = nl_design_create (tmp_name, current_context);

  if ( v2nl_rtl ) {
    v2nl_parameter_table = ht_alloc (16, ht_hash_string, ht_compare_string,
				     ht_copy_string, ht_free_string);
    v2nl_parameter_value = ht_new_attribute (v2nl_parameter_table,
					     sizeof (nl_ast), NULL,
					     v2nl_free_parameter_value);
  }
  else {
    v2nl_parameter_table = NULL;
    v2nl_parameter_value = NULL;
  }

  v2nl_assignment_num = 1;
  v2nl_primitive_num = 1;

  g = nl_design_mem_group (v2nl_current_design);
  mem_group_set (g);

  FREE (tmp_name);

  {
    char *old_current_file = v2nl_current_file;

    v2nl_current_file = STRDUP (v2nl_current_file);
    FREE (old_current_file);
  }

  nl_design_set_bus_naming_style (v2nl_current_design, bus_naming_style);

  current_ext_names = ht_alloc (64, ht_hash_string, ht_compare_string,
				ht_copy_string, ht_free_string);
  current_int_names = ht_alloc (64, ht_hash_string, ht_compare_string,
				ht_copy_string, ht_free_string);
				

  port_nets = ht_new_attribute (current_ext_names, sizeof (ar),
				NULL, v2nl_free_array);
  port_dirs = ht_new_attribute (current_ext_names, sizeof (ar),
				NULL, v2nl_free_array);
  int_to_ext_map = ht_new_attribute (current_int_names, sizeof (ht_entry),
				     NULL, NULL);

  ext_name_list = AR_NEW (64, ht_entry);
}


void
v2nl_endmod (void)
{
  nl_design existing_design
    = nl_context_get_design_by_name (current_context, current_design_name);

  if ( existing_design != NULL ) {
    fprintf (stderr, "Overwriting design \"%s\"\n", current_design_name);
    nl_context_remove_design (current_context, existing_design);
  }

  nl_design_rename (v2nl_current_design, current_design_name);

  FREE (current_design_name);

  v2nl_create_ports ();

  mem_group_set (v2nl_mem_group);

  if ( v2nl_parameter_table != NULL ) {
    ht_free (v2nl_parameter_table);
  }

  v2nl_lex_end_escaped_translation ();

  v2nl_parameter_table = NULL;
  v2nl_parameter_value = NULL;

  ar_add (designs_read, &v2nl_current_design);

  v2nl_current_design = NULL;

  mem_group_set (v2nl_mem_group);

  v2nl_current_file = STRDUP (v2nl_current_file);
}


void
v2nl_port (char *name)
{
  ht_entry hte1 = ht_lookup (current_ext_names, name);
  ht_entry hte2 = ht_lookup (current_int_names, name);

  if ( hte1 != ht_null || hte2 != ht_null ) {
    v2nl_error ("Name included more than once in module port list -> %s",
		 name);
  }
  else {
    ar port_nets_attr = AR_NEW (4, nl_object);
    ar port_dirs_attr = AR_NEW (4, nl_object);

    hte1 = ht_insert (current_ext_names, name);
    hte2 = ht_insert (current_int_names, name);
    
    ht_set_attribute_for_entry (port_nets, hte1, &port_nets_attr);
    ht_set_attribute_for_entry (port_dirs, hte1, &port_dirs_attr);
    ht_set_attribute_for_entry (int_to_ext_map, hte2, &hte1);

    /* ar_add (current_int_port_list, &hte2); */
    ar_add (ext_name_list, &hte1);
  }
}


static
nl_net
v2nl_declare_net (char *name, nl_wireclass class)
{
  nl_named_object obj
    = nl_design_get_object_by_name (v2nl_current_design, name);

  if ( obj != NULL ) {
    nl_kind kind = nl_named_object_kind (obj);

    if ( kind == nl_kind_net ) {
      nl_net net = (nl_net) obj;
      nl_wireclass wireclass = nl_net_class (net);
      
      if ( wireclass != nl_wireclass_input &&
	   wireclass != nl_wireclass_output &&
	   wireclass != nl_wireclass_inout ) {
	v2nl_error ("Redeclaration of '%s', which doesn't have IO wireclass.",
		    name);
      }

      nl_net_set_class (net, class);
      
      return net;
    }
    else if ( kind == nl_kind_bus ) {
      v2nl_error ("Redeclaration of '%s', first as bus, then as net.", name);
    }
    else {
      v2nl_error ("Redeclaration of '%s', first as something, then as net.",
		  name);
    }
  }
  else {
    nl_net result = nl_net_create (name, class, v2nl_current_design);

    v2nl_set_attributes ((nl_object) result);

    return result;
  }
}


static
void
v2nl_declare_port (char *name, nl_direction direction, nl_object net_or_bus)
{
  ht_entry hte1 = ht_lookup (current_int_names, name);

  if ( hte1 == ht_null ) {
    v2nl_error ("Declared port does not appear in module port list -> %s\n",
		 name);
  }
  else {
    ar nets;
    ar dirs;

    ht_get_attribute_for_entry (port_nets, hte1, &nets);
    ht_get_attribute_for_entry (port_dirs, hte1, &dirs);

    ar_add (nets, &net_or_bus);
    ar_add (dirs, &direction);
  }
}

static
nl_port
v2nl_create_indexed_port (char *name, int index, nl_direction direction)
{
  int name_len = strlen (name);
  int style_len = strlen (bus_naming_style);
  char *pname = alloca (name_len + style_len + 16);
  nl_port port;

  sprintf (pname, bus_naming_style, name, index);
  port = nl_port_create (pname, v2nl_current_design, direction);

  /* v2nl_set_attributes ((nl_object) port); */

  return port;
}


static
void
v2nl_create_ports (void)
{
  ar_for_all (ext_name_list, ht_entry, hte) {
    char *name = ht_get_key (current_ext_names, hte);
    ar nets;
    ar dirs;

    ht_get_attribute_for_entry (port_nets, hte, &nets);
    ht_get_attribute_for_entry (port_dirs, hte, &dirs);
    
    ASSERT (ar_size (nets) == ar_size (dirs));

    if ( ar_size (nets) == 1 ) {
      nl_direction direction = AR_REF (dirs, nl_direction, 0);
      nl_object net_or_bus = AR_REF (nets, nl_object, 0);

      if ( nl_object_kind (net_or_bus) == nl_kind_net ) {
	nl_port port = nl_port_create (name, v2nl_current_design, direction);
	nl_wireclass class = nl_net_class ((nl_net) net_or_bus);

	nl_port_connect_net (port, (nl_net) net_or_bus);
	if ( class == nl_wireclass_input ||
	     class == nl_wireclass_output ||
	     class == nl_wireclass_inout ) {
	  nl_net_set_class ((nl_net) net_or_bus, nl_wireclass_wire);
	}
      }
      else { /* It's a bus. */
	nl_type type = nl_bus_type ((nl_bus) net_or_bus);
	nl_bus port_bus = nl_bus_create (name, type, nl_kind_port,
					 (nl_object) v2nl_current_design);

	nl_type_for_all_indexes (type, index) {
	  nl_port port = v2nl_create_indexed_port (name, index, direction);
	  int offset;
	  int flag = nl_type_get_offset_for_index (type, index, &offset);
	  nl_net net;
	  nl_wireclass class;

	  if ( !flag ) {
	    v2nl_error ("Internal error hooking up ports to nets.");
	  }

	  net = (nl_net) nl_bus_get_member ((nl_bus) net_or_bus, offset);

	  nl_bus_add_port (port_bus, port);
	  nl_port_connect_net (port, net);

	  class = nl_net_class (net);
	  if ( class == nl_wireclass_input ||
	       class == nl_wireclass_output ||
	       class == nl_wireclass_inout ) {
	    nl_net_set_class (net, nl_wireclass_wire);
	  }
	} nl_end_for;
      }
    }
    else {
      int width = 0;

      ar_for_all (nets, nl_object, net_or_bus) {
	if ( nl_object_kind (net_or_bus) == nl_kind_net ) {
	  width++;
	}
	else { /* It's a bus. */
	  nl_type type = nl_bus_type ((nl_bus) net_or_bus);
	  width += nl_type_width (type);
	}
      } ar_end_for;

      {
	nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);
	nl_type port_bus_type = nl_type_get_array (scalar, width-1, 0);
	nl_bus port_bus = nl_bus_create (name, port_bus_type, nl_kind_port,
					 (nl_object) v2nl_current_design);

	int index = width - 1;

	ar_for_all_indexed (nets, nl_object, net_or_bus, i) {
	  nl_direction dir = AR_REF (dirs, nl_direction, i);

	  if ( nl_object_kind (net_or_bus) == nl_kind_net ) {
	    nl_port port = v2nl_create_indexed_port (name, index, dir);
	    nl_wireclass class = nl_net_class ((nl_net) net_or_bus);

	    index--;
	    nl_bus_add_port (port_bus, port);
	    nl_port_connect_net (port, (nl_net) net_or_bus);

	    if ( class == nl_wireclass_input ||
		 class == nl_wireclass_output ||
		 class == nl_wireclass_inout ) {
	      nl_net_set_class ((nl_net) net_or_bus, nl_wireclass_wire);
	    }
	  }
	  else {
	    ar bus_nets = nl_bus_members ((nl_bus) net_or_bus);
	    ar_for_all (bus_nets, nl_net, net) {
	      nl_port port = v2nl_create_indexed_port (name, index, dir);
	      nl_wireclass class = nl_net_class ((nl_net) net_or_bus);

	      index--;
	      nl_bus_add_port (port_bus, port);
	      nl_port_connect_net (port, net);

	      if ( class == nl_wireclass_input ||
		   class == nl_wireclass_output ||
		   class == nl_wireclass_inout ) {
		nl_net_set_class (net, nl_wireclass_wire);
	      }
	    } ar_end_for;
	  }
	} ar_end_for;
      }
    }
  } ar_end_for;

  ar_free (ext_name_list);

  ht_free (current_int_names);
  current_int_names = NULL;

  ht_free (current_ext_names);
  current_ext_names = NULL;
}


static
void
v2nl_declare_supply0 (nl_object net_or_bus)
{
  nl_design_add_supply0 (v2nl_current_design, net_or_bus);
}


static
void
v2nl_declare_supply1 (nl_object net_or_bus)
{
  nl_design_add_supply1 (v2nl_current_design, net_or_bus);
}


static
void
v2nl_fill_refpin_bus (nl_reference ref, char *name, nl_type type, nl_bus bus)
{
  int name_len = strlen (name);
  int style_len = strlen (bus_naming_style);
  char *name_buf = alloca (name_len + style_len + 16);
  int width = nl_bus_width (bus);

  nl_type_for_all_indexes (type, index) {
    int offset;
    int flag = nl_type_get_offset_for_index (type, index, &offset);

    if ( ! flag ) {
      v2nl_error ("Internal error getting the offset for an index.");
    }

    if ( offset < width ) {
      continue;
    }
    else {
      nl_refpin refpin;

      sprintf (name_buf, bus_naming_style, name, index);
    
      refpin = nl_refpin_create (name_buf, NULL, ref);

      nl_bus_add_refpin (bus, refpin);
    }
  } nl_end_for;
}


static
void  
v2nl_declare_refpins (nl_reference ref, char *name, int width)
{
  nl_object refpin = nl_reference_get_refpin_by_name (ref, name);

  if ( refpin != NULL ) {
    v2nl_error ("Redeclaration of pin '%s' on module '%s'",
		 name, nl_reference_name (ref));
  }

  if ( width > 1 ) {
    nl_design design = nl_reference_design (ref);
    nl_type scalar = nl_type_get_scalar ((nl_object) design);
    nl_type type = nl_type_get_array (scalar, width-1, 0);
    nl_bus bus = nl_bus_create (name, type, nl_kind_refpin, (nl_object) ref);

    v2nl_fill_refpin_bus (ref, name, type, bus);
  }
  else {
    nl_refpin_create (name, NULL, ref);
  }
}


static
void  
v2nl_check_refpins (nl_reference ref, char *name, int width)
{
  nl_named_object refpin
    = (nl_named_object) nl_reference_get_refpin_by_name (ref, name);

  if ( refpin == NULL ) {
    v2nl_declare_refpins (ref, name, width);
  }
  else {
    if ( nl_named_object_kind (refpin) == nl_kind_bus ) {
      nl_bus bus = (nl_bus) refpin;
      int bus_width = nl_bus_width (bus);

      if ( width > bus_width ) {
	nl_type type = nl_bus_type (bus);
	nl_type base = nl_type_base_type (type);
	int left = nl_type_left (type);
	int right = nl_type_right (type);
	nl_type new_type;

	if ( left >= right ) {
	  new_type = nl_type_get_array (base,
					left + (width - bus_width), right);
	}
	else {
	  new_type = nl_type_get_array (base,
					left - (width - bus_width), right);
	}
	nl_bus_set_type (bus, new_type);

	v2nl_fill_refpin_bus (ref, name, type, bus);
      }
    }
    else {
      if ( width > 1 ) {
	nl_design design = nl_reference_design (ref);
	nl_type scalar = nl_type_get_scalar ((nl_object) design);
	nl_type type = nl_type_get_array (scalar, width-1, 0);
	nl_bus bus;

	ASSERT (nl_named_object_kind (refpin) == nl_kind_refpin);

	{
	  int name_len = strlen (name);
	  int style_len = strlen (bus_naming_style);
	  char *new_name = alloca (name_len + style_len + 16);

	  sprintf (new_name, bus_naming_style, name, 0);
	  
	  nl_refpin_rename ((nl_refpin) refpin, new_name);
	}

	bus = nl_bus_create (name, type, nl_kind_refpin, (nl_object) ref);
	nl_bus_add_refpin (bus, (nl_refpin) refpin);
	
	v2nl_fill_refpin_bus (ref, name, type, bus);
      }
    }
  }
}


static
char *
v2nl_get_alternate_net_name (char *name)
{
  int len = strlen (name);
  char *new_name = MALLOC (len + 16);
	
  nl_named_object net_or_bus;
  int count = 0;

  do {
    count++;
    sprintf (new_name, "%s%d", name, count);

    net_or_bus
      = nl_design_get_net_or_bus_by_name (v2nl_current_design, new_name);

  } while ( net_or_bus != NULL );

  return new_name;
}


static
nl_named_object
v2nl_get_net (char *name)
{
  nl_named_object net_or_bus
    = nl_design_get_net_or_bus_by_name (v2nl_current_design, name);

  if ( net_or_bus == NULL ) {
    nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);

    v2nl_variable (nl_wireclass_wire, nl_direction_null, scalar, name);
    net_or_bus = nl_design_get_net_or_bus_by_name (v2nl_current_design, name);

    ASSERT (net_or_bus != NULL);
  }
  else {
    nl_kind kind = nl_named_object_kind (net_or_bus);

    if ( kind == nl_kind_net ) {
      nl_net net = (nl_net) net_or_bus;
      nl_bus bus = nl_net_bus (net);

      if ( bus != NULL ) {
	char *new_name = v2nl_get_alternate_net_name (name);

	v2nl_lex_add_escaped_translation (name, new_name);

	net_or_bus = v2nl_get_net (new_name);

	FREE (new_name);
      }
    }
  }

  return net_or_bus;
}


static
char *
v2nl_remove_underbars (char *str)
{
  char *result = str;
  char *s;
  char *t;

  while ( *result == '_' ) {
    result++;
  }

  s = result;
  t = result;

  while ( *t != '\0' ) {
    if ( *t != '_' ) {
      *s = *t;
      s++;
    }
    t++;
  }

  *s = '\0';

  return result;
}


ar
v2nl_get_constant_nets (int width, char radix, char *str)
{
  int i;
  char *s = v2nl_remove_underbars (str);
  nl_net zero = (nl_net) v2nl_get_net ("1'b0");
  nl_net one = (nl_net) v2nl_get_net ("1'b1");
  ar result = AR_NEW (width, nl_net);

  if ( width == 0 ) {
    ar_add (result, &zero);
    v2nl_warning ("interpreting zero-width constant (\"%d'%c%s\") as \"1'b0\"",
		  width, radix, str);
    return result;
  }

  for ( i = 0; i < width; i++ ) {
    ar_add (result, &zero);
  }

  switch (radix) {

  case 'b': {
    int i;
    int len = strlen (s);

    for ( i = 0; i < len; i++ ) {
      if ( s[i] == '1' ) {
	ar_set (result, width - len + i, &one);
      }
      else if ( s[i] != '0' ) {
	v2nl_error ("invalid character in binary constant: '%c' in %d'%c%s.",
		    s[i], width, radix, s);
      }
    }
    break;
  }
  case 'h': {
    int i;
    int len = strlen (s);

    for ( i = 0; i < len; i++ ) {
      int x;
      int y;
      int idx;

      if ( s[i] >= '0' && s[i] <= '9' ) {
	x = s[i] - '0';
      }
      else if ( s[i] >= 'a' && s[i] <= 'f' ) {
	x = 10 + s[i] - 'a';
      }
      else if ( s[i] >= 'A' && s[i] <= 'F' ) {
	x = 10 + s[i] - 'A';
      }
      else {
	v2nl_error ("invalid character in hexadecimal constant: '%c' in %d'%c%s.",
		    s[i], width, radix, s);
      }

      y = x;
      idx = 0;

      while ( y != 0 ) {
	if ( y % 2 ) {
	  ar_set (result, width - 1 - 4*(len - 1 - i) - idx, &one);
	}

	idx++;
	y >>= 1;
      }
    }
    break;
  }
  case 'd': {
    unsigned int x;
    unsigned int y;
    int idx = width - 1;
    int len = strlen (s);

    if ( len > 9 ) {
      v2nl_error ("decimal constants longer than 9 digits are not supported: %d'%c%s.",
		  width, radix, str);
    }
      
    sscanf (s, "%u", &x);

    y = x;

    while ( y != 0 ) {
      if ( y % 2 )
	ar_set (result, idx, &one);

      idx--;
      y >>= 1;
    }
    break;
  }

  case 'o': {
    int i;
    int len = strlen (s);

    for ( i = 0; i < len; i++ ) {
      int x;
      int y;
      int idx;

      if ( s[i] >= '0' && s[i] <= '8' ) {
	x = s[i] - '0';
      }
      else {
	v2nl_error ("invalid character in octal constant: '%c' in %d'%c%s.",
		    s[i], width, radix, s);
      }

      y = x;
      idx = 0;

      while ( y != 0 ) {
	if ( y % 2 ) {
	  ar_set (result, width - 1 - 3*(len - 1 - i) - idx, &one);
	}

	idx++;
	y >>= 1;
      }
    }
    break;
  }
  default:
    v2nl_error ("invalid radix character in constant, '%c'.", radix);
  }
	  
  return result;
}


static
nl_refpin
v2nl_get_refpin (nl_reference reference, char *name, int index)
{
  int name_len = strlen (name);
  nl_object result = nl_reference_get_refpin_by_name (reference, name);

  if ( result == NULL ) {
    v2nl_error ("Could not find refpin -> %s\n", name);
    return NULL;
  }
  else if ( nl_object_kind ((nl_object) result) == nl_kind_refpin ) {
    return (nl_refpin) result;
  }
  else {
    int style_len = strlen (bus_naming_style);
    char *pname = alloca (name_len + style_len + 16);

    sprintf (pname, bus_naming_style, name, index);

    result = nl_reference_get_refpin_by_name (reference, pname);

    if ( result == NULL ) {
      v2nl_error ("Could not find refpin -> %s\n", pname);
      return NULL;
    }
    else {
      ASSERT (nl_object_kind ((nl_object) result) == nl_kind_refpin);
      return (nl_refpin) result;
    }
  }
}


nl_reference
v2nl_reference (char *base_name, ar params)
{
  char *name;

  if ( params == NULL ) {
    name = base_name;
  }
  else {
    char buf[16];
    int total_len = strlen (base_name) + 2;
    int idx = 0;

    ar_for_all (params, int, param) {
      sprintf (buf, "%d", param);

      total_len += strlen (buf) + 1;
    } ar_end_for;

    name = alloca (total_len + 2);

    strcpy (name, base_name);
    idx = strlen (base_name);
    name[idx] = '#';
    idx++;
    name[idx] = '(';
    idx++;

    ar_for_all_indexed (params, int, param, count) {
      sprintf (buf, "%d", param);

      if ( count > 0 ) {
	name[idx] = ',';
	idx++;
      }

      strcpy (name + idx, buf);
      idx += strlen (buf);
    } ar_end_for;

    name[idx] = ')';
    idx++;
    name[idx] = 0;
  }

  {
    nl_reference reference 
      = nl_design_get_reference_by_name (v2nl_current_design, name);

    if ( reference == NULL ) {
      reference = nl_reference_create (name, v2nl_current_design, NULL);

      if ( params ) {
	ar_for_all (params, int, param) {
	  nl_reference_add_parameter (reference, param);
	} ar_end_for;
      }
    }

    return reference;
  }
}


nl_cell
v2nl_cell (nl_reference reference, Attrib *name)
{
  nl_cell result;

  v2nl_check_cell_net_port_name (name->text);
  result = nl_cell_create (name->text, reference);

  nl_cell_set_file_line (result, name->file, name->line);

  v2nl_set_attributes ((nl_object) result);

  return result;
}


nl_reference
v2nl_primitive_reference (Attrib *a)
{
  switch (a->token) {
  case TRAN_GATE: {
    nl_reference ref
      = nl_design_get_reference_by_name (v2nl_current_design, "*tran*");

    if ( ref == NULL ) {
      nl_refpin in_refpin;
      nl_refpin out_refpin;

      ref = nl_reference_create ("*tran*", v2nl_current_design, NULL);

      out_refpin = nl_refpin_create ("out", NULL, ref);
      in_refpin = nl_refpin_create ("in", NULL, ref);

      nl_refpin_set_direction (in_refpin, nl_direction_inout);
      nl_refpin_set_direction (out_refpin, nl_direction_inout);
    }
    
    return ref;
  }
  default:
    v2nl_error ("primitive gate '%s' is not yet supported.", a->text);
  }
}


nl_cell
v2nl_primitive_gate (char *name, nl_reference reference, nl_type type,
		     ar params, char *file, int line)
{
  if ( nl_type_class (type) != nl_typeclass_scalar ) {
    v2nl_error ("arrays of primitives gates (for gate '%s') not yet supported", name);
  }

  {
    nl_dll_head refpins = nl_reference_refpins (reference);
    int num_refpins = nl_dll_head_num_elements (refpins);
    int num_params = ar_size (params);

    if ( num_params != num_refpins ) {
      v2nl_error ("wrong number of parameters for primitive instance "
		  "(%d instead of %d)", num_params, num_refpins);
    }
  }

  {
    int count = 0;
    char *cell_name;
    nl_cell cell;

    if ( name != NULL ) {
      cell_name = name;
    }
    else {
      cell_name = alloca (32);

      sprintf (cell_name, "*tran_%d*", v2nl_primitive_num);

      v2nl_primitive_num++;
    }

    cell = nl_cell_create (cell_name, reference);
    
    nl_reference_for_all_refpins (reference, refpin) {
      ar nets;

      ar_ref (params, count, &nets);
      count++;

      if ( ar_size (nets) != 1 ) {
	char *ord_suffix;

	switch (count) {
	case 1: ord_suffix = "st"; break;
	case 2: ord_suffix = "nd"; break;
	default: ord_suffix = "th";
	}

	v2nl_error ("%d%s parameter of primitive instance has invalid width "
		    "(%d instead of %d)", count, ord_suffix, ar_size (nets), 1);
      }

      {
	nl_net net;
	nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);

	ar_ref (nets, 0, &net);
	
	nl_pin_connect_net (pin, net);
      }
    } nl_end_for;

    nl_cell_set_file_line (cell, file, line);

    v2nl_set_attributes ((nl_object) cell);

    return cell;
  }
}


void
v2nl_pins (nl_cell cell, char *refpin_name, ar nets)
{
  if ( nets == NULL ) {
    return;
  }
  else {
    int width = ar_size (nets);
  
    v2nl_check_refpins (nl_cell_reference (cell), refpin_name, width);

    if ( nets != NULL ) {
      ar_for_all_indexed (nets, nl_net, net, index) {
	nl_reference reference = nl_cell_reference (cell);
	nl_refpin refpin = v2nl_get_refpin (reference, refpin_name,
					    width - index - 1);
	nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);

	nl_pin_connect_net (pin, net);
      } ar_end_for;
    }
  }
}


static
nl_reference
v2nl_get_assignment_reference (void)
{
  nl_reference ref = nl_design_get_reference_by_name (v2nl_current_design,
						      "*assignment*");
  if ( ref == NULL ) {
    nl_refpin in_refpin;
    nl_refpin out_refpin;

    ref = nl_reference_create ("*assignment*", v2nl_current_design, NULL);

    in_refpin = nl_refpin_create ("in", NULL, ref);
    out_refpin = nl_refpin_create ("out", NULL, ref);

    nl_refpin_set_direction (in_refpin, nl_direction_in);
    nl_refpin_set_direction (out_refpin, nl_direction_out);
  }

  return ref;
}


void
v2nl_assign (ar lhs, ar rhs, Attrib *attr)
{
  nl_reference ref = v2nl_get_assignment_reference ();
  char cell_name[64];
  nl_refpin in_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (ref, "in");
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (ref, "out");
  nl_net zero_net = NULL;
  int lhs_width = ar_size (lhs);
  int rhs_width = ar_size (rhs);
  nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);
  nl_type bus_type = nl_type_get_array (scalar, lhs_width-1, 0);
  nl_bus assign_bus;

  sprintf (cell_name, "*assignment_%d*", v2nl_assignment_num);
  v2nl_assignment_num++;

  assign_bus = nl_bus_create (cell_name, bus_type, nl_kind_cell,
			      (nl_object) v2nl_current_design);

  ar_for_all_reverse_indexed (lhs, nl_net, lhs_net, lhs_index) {
    int rhs_index = rhs_width - lhs_width + lhs_index;
    nl_cell assign_cell;
    nl_net rhs_net;
    nl_pin in_pin;
    nl_pin out_pin;

    if ( rhs_index >= 0 ) {
      ar_ref (rhs, rhs_index, &rhs_net);
    }
    else {
      if ( zero_net == NULL ) {
	zero_net = (nl_net) v2nl_get_net ("1'b0");
      }
      rhs_net = zero_net;
    }

    if ( rhs_net == lhs_net ) {
      v2nl_warning ("left- and right-hand sides of assignment refer to the "
		    "same net");
      continue;
    }

    sprintf (cell_name, "*assignment_%d*", v2nl_assignment_num);
    v2nl_assignment_num++;

    assign_cell = nl_cell_create (cell_name, ref);
    nl_bus_add_cell (assign_bus, assign_cell);

    nl_cell_set_file_line (assign_cell, attr->file, attr->line);

    v2nl_set_attributes ((nl_object) assign_cell);

    in_pin = nl_cell_get_pin_by_refpin (assign_cell, in_refpin);
    out_pin = nl_cell_get_pin_by_refpin (assign_cell, out_refpin);

    nl_pin_connect_net (in_pin, rhs_net);
    nl_pin_connect_net (out_pin, lhs_net);
  } ar_end_for;
}


static
void
v2nl_check_bus_member_name (char *name)
{
  nl_named_object net_or_bus
    = nl_design_get_net_or_bus_by_name (v2nl_current_design, name);

  if ( net_or_bus != NULL ) {
    char *new_name = v2nl_get_alternate_net_name (name);
    nl_kind kind = nl_named_object_kind (net_or_bus);

    if ( kind == nl_kind_net ) {
      nl_net_rename ((nl_net) net_or_bus, new_name);
    }
    else if ( kind == nl_kind_bus ) {
      nl_bus_rename ((nl_bus) net_or_bus, new_name);
    }
    else {
      ASSERT (0);
    }

    v2nl_lex_add_escaped_translation (name, new_name);

    FREE (new_name);
  }
}


static
nl_bus
v2nl_make_bus_nets (char *name, nl_wireclass class, nl_type type)
{
  nl_named_object obj
    = nl_design_get_object_by_name (v2nl_current_design, name);

  if ( obj != NULL ) {
    nl_kind kind = nl_named_object_kind (obj);

    if ( kind == nl_kind_net ) {
      v2nl_error ("Reclaration of '%s', first as scalar, then as bus.", name);
    }
    else if ( kind == nl_kind_bus ) {
      nl_bus bus = (nl_bus) obj;
      nl_kind member_kind = nl_bus_member_kind (bus);
      nl_type bus_type = nl_bus_type (bus);

      if ( member_kind != nl_kind_net ) {
	v2nl_error ("Redeclaration of bus '%s', "
		    "first as bus of %s, then as bus of nets.", name,
		    nl_kind_to_string (member_kind));
      }

      if ( type != bus_type ) {
	v2nl_error ("Redeclaration bus '%s' changes the type.", name);
      }

      nl_bus_for_all_net_members (bus, net) {
	nl_wireclass wireclass = nl_net_class (net);

	if ( wireclass != nl_wireclass_input &&
	     wireclass != nl_wireclass_output &&
	     wireclass != nl_wireclass_inout ) {
	  v2nl_error ("Redeclaration of '%s', which doesn't have IO "
		      "wireclass.", name);
	}

	nl_net_set_class (net, class);
      } nl_end_for;

      return bus;
    }
    else {
      v2nl_error ("Reclaration of '%s', first as something, then as bus.",
		  name);
    }
  }
  else {
    int name_len = strlen (name);
    int style_len = strlen (bus_naming_style);
    char *member_name = alloca (name_len + style_len + 16);

    nl_bus bus = nl_bus_create (name, type, nl_kind_net,
				(nl_object) v2nl_current_design);

    nl_type_for_all_indexes (type, index) {
      nl_net net;
      sprintf (member_name, bus_naming_style, name, index);
      v2nl_check_bus_member_name (member_name);
      net = v2nl_declare_net (member_name, class);
      nl_bus_add_net (bus, net);
    } nl_end_for;
    
    return bus;
  }
}


void
v2nl_variable (nl_wireclass class, nl_direction dir, nl_type type, char *name)
{
  nl_object new_thing;
  nl_typeclass type_class = nl_type_class (type);

  if ( type_class == nl_typeclass_array || type_class == nl_typeclass_integer ) {
    new_thing = (nl_object) v2nl_make_bus_nets (name, class, type);
  }
  else {
    new_thing = (nl_object) v2nl_declare_net (name, class);
  }

  if ( dir != nl_direction_null ) {
    v2nl_declare_port (name, dir, new_thing);
  }

  if ( class == nl_wireclass_supply0 ) {
    v2nl_declare_supply0 (new_thing);
  }
  else if ( class == nl_wireclass_supply1 ) {
    v2nl_declare_supply1 (new_thing);
  }
}


void
v2nl_declare_rtl_var (nl_subprogram subr, nl_wireclass class, nl_type type,
		      char *name)
{
  
  if ( class == nl_wireclass_input || class == nl_wireclass_reg ) {
    char *buf = alloca (strlen (name) + strlen (bus_naming_style) + 16);
    nl_symbol symbol = nl_symbol_create (name, type, class, subr);

    if ( class == nl_wireclass_input )
      nl_subprogram_add_formal (subr, symbol);
    else
      nl_subprogram_add_local (subr, symbol);

    if ( nl_type_class (type) == nl_typeclass_array ) {
      char *bus_naming_style
	= nl_design_bus_naming_style (v2nl_current_design);
      nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);

      nl_type_for_all_indexes (type, index) {
	nl_symbol new_sym;

	sprintf (buf, bus_naming_style, name, index);
	new_sym = nl_symbol_create (buf, scalar, class, subr);
	nl_symbol_add_constituent (symbol, new_sym);
	nl_subprogram_add_symbol (subr, new_sym);
      } nl_end_for;
    }
  }
  else if ( class == nl_wireclass_output || class == nl_wireclass_inout ) {
    v2nl_error ("function argument declared as %s; function arguments may "
		"only be inputs", nl_wireclass_to_string (class));
  }
  else {
    v2nl_error ("function local var declared as %s; function locals may "
		"only be regs", nl_wireclass_to_string (class));
  }
}


nl_type
v2nl_scalar (void)
{
  nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);

  return scalar;
}


nl_type
v2nl_integer (void)
{
  nl_type integer = nl_type_get_integer ((nl_object) v2nl_current_design);

  return integer;
}


nl_type
v2nl_array (int lb, int rb)
{
  nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);
  nl_type array = nl_type_get_array (scalar, lb, rb);

  return array;
}


ar
v2nl_get_net_or_bus_nets (nl_object obj)
{
  ar nets = AR_NEW (1, nl_net);
  nl_kind kind = nl_object_kind (obj);

  if ( kind == nl_kind_net ) {
    ar_add (nets, &obj);
  }
  else if ( kind == nl_kind_bus ) {
    nl_bus bus = (nl_bus) obj;
    ar members = nl_bus_members (bus);

    ar_for_all_reverse (members, nl_net, net) {
      ar_add (nets, &net);
    } ar_end_for;
  }

  return nets;
}


ar
v2nl_var_ref (char *name)
{
  nl_named_object obj = v2nl_get_net (name);

  {
    ar result = v2nl_get_net_or_bus_nets ((nl_object) obj);

    return result;
  }
}

ar
v2nl_var_bit (char *name, int index)
{
  ar nets = v2nl_var_slice (name, index, index);

  return nets;
}


ar
v2nl_get_bus_slice (nl_object obj, int l, int r)
{  
  nl_kind kind = nl_object_kind (obj);

  if ( kind != nl_kind_bus ) {
    char *name = nl_named_object_name ((nl_named_object) obj);
    v2nl_error ("Bit select applied to non-array object -> %s\n", name);
  }
  else {
    nl_bus bus = (nl_bus) obj;
    nl_type type = nl_bus_type (bus);
    int offset0;
    int offset1;
    int flag = nl_type_get_offset_for_index (type, l, &offset0);

    if ( flag == 0 ) {
      v2nl_error ("Bit select index out of range [%d:%d] -> %d\n",
		  nl_type_left (type), nl_type_right (type), l);
    }

    flag = nl_type_get_offset_for_index (type, r, &offset1);

    if ( flag == 0 ) {
      v2nl_error ("Bit select index out of range [%d:%d] -> %d\n",
		  nl_type_left (type), nl_type_right (type), r);
    }

    if ( offset0 < offset1 ) {
      v2nl_error ("Bit slice direction different than declared type [%d:%d] "
		  "-> [%d:%d]\n", nl_type_left (type), nl_type_right (type),
		  l, r);
    }

    {
      int i;
      ar nets = AR_NEW (1, nl_net);

      for ( i = offset0; i >= offset1; i-- ) {
	nl_net net = (nl_net) nl_bus_get_member (bus, i);
	ar_add (nets, &net);
      }

      return nets;
    }
  }
}


ar
v2nl_var_slice (char *name, int l, int r)
{
  nl_named_object obj = v2nl_get_net (name);
  ar result = v2nl_get_bus_slice ((nl_object) obj, l, r);

  return result;
}


ar
v2nl_shift_right (ar nets, int amt)
{
  ar result = AR_NEW (0, nl_net);
  int width = ar_size (nets);
  int i;

  if ( amt >= width ) {
    v2nl_error ("right shift amount (%d), is greater than or equal"
		" to data width (%d)", amt, width);
  }

  for ( i = 0; i < width - amt; i++ ) {
    nl_net net = AR_REF (nets, nl_net, i);

    ar_add (result, &net);
  }

  return result;
}


ar
v2nl_shift_left (ar nets, int amt)
{
  int i;
  nl_net zero = (nl_net) v2nl_get_net ("1'b0");
  ar result = ar_copy (nets);
  
  for ( i = 0; i < amt; i++ ) {
    ar_add (result, &zero);
  }

  return result;
}


nl_ast
v2nl_function_call (nl_ast tree)
{
  nl_id_ast id_ast = (nl_id_ast) tree;
  nl_ast args = nl_id_ast_sibling (id_ast);
  char *name = nl_id_ast_name (id_ast);
  nl_subprogram fun
    = nl_design_get_subprogram_by_name (v2nl_current_design, name);
  char *file = nl_id_ast_file (id_ast);
  int line = nl_id_ast_line (id_ast);

  nl_ast_free ((nl_ast) id_ast);

  if ( fun == NULL ) {
    v2nl_ast_error (tree, "called object is not a function: %s", name);
  }
  else {
    nl_ref_ast ref = nl_ref_ast_create (nl_token_ref, (nl_object) fun);
    nl_ast call_ast = nl_ast_create (nl_token_funcall);

    nl_ast_set_file_line ((nl_ast) ref, file, line);
    nl_ast_set_file_line (call_ast, file, line);

    nl_ast_set_sibling ((nl_ast) ref, args);
    nl_ast_set_child (call_ast, (nl_ast) ref);

    return call_ast;
  }
}


ar
v2nl_repeat_concat (int n, ar nets)
{
  int i;
  int size = n * ar_size (nets);
  ar result = AR_NEW (size, nl_net);

  for ( i = 0; i < n; i++ ) {
    ar_append (result, nets);
  }

  return result;
}


ar
v2nl_get_integer (int n)
{
  int i;
  ar result = AR_NEW (32, nl_net);
  unsigned int x = n;
  nl_net zero = (nl_net) v2nl_get_net ("1'b0");
  nl_net one = (nl_net) v2nl_get_net ("1'b1");

  for ( i = 0; i < 32; i++ ) {
    ar_add (result, &zero);
  }

  i = 32;

  while ( x > 0 ) {
    i--;

    if ( x % 2 ) {
      ar_set (result, i, &one);
    }
    x >>= 1;
  }

  return result;
}


ar
v2nl_read_verilog_files (nl_context context, ar files, ar defines,
			 char *bus_style, int ports_only, int rtl)
{
  ar result = ar_alloc (0, sizeof (nl_design));
  int i;
  int size = ar_size (defines);
  int num_defines = size / 2;
  mem_group old_group;

  current_context = context;

  v2nl_mem_group = mem_group_create ("verilog reader", 4);
  old_group = mem_group_set (v2nl_mem_group);

  v2nl_define_macro ("NL", "", 1);

  ASSERT (size % 2 == 0);

  for ( i = 0; i < num_defines; i++ ) {
    char *var;
    char *val;

    ar_ref (defines, 2*i, &var);
    ar_ref (defines, 2*i+1, &val);

    v2nl_define_macro (var, val, 1);
  }
  
  error_unwind_protect {
    ar_for_all (files, char *, file) {
      FILE *ifp = fopen (file, "r");
      ar designs;

      if ( ifp == NULL ) {
	error ("Cannot open %s for reading.", file);
      }

      v2nl_current_file = STRDUP (file);

      designs = v2nl_read_verilog (context, ifp, bus_style, ports_only, rtl);

      ar_append (result, designs);
      ar_free (designs);
    } ar_end_for;
  }
  error_on_exit {
    v2nl_free_macro_table ();

    mem_group_set (old_group);
    mem_group_free (v2nl_mem_group);
    v2nl_mem_group = NULL;

    current_context = NULL;
  } error_end;

  return result;
}


ar
v2nl_read_verilog (nl_context context, FILE *ifp, char *bus_style,
		   int ports_only, int rtl)
{
  AST *ptr;

  if ( ports_only ) {
    *(void **) &v2nl_current_gettok = v2nl_ports_only_gettok;
    v2nl_ports_only = 1;
    v2nl_ports_only_skip = 1;
  }
  else {
    v2nl_ports_only = 0;
    *(void **) &v2nl_current_gettok = v2nl_zzgettok;
  }

  v2nl_rtl = rtl;
  v2nl_current_subprogram = NULL;
  v2nl_implicit_wires_ok = 0;

  v2nl_attributes
    = ht_alloc (16, ht_hash_string, ht_compare_string, ht_copy_string,
		ht_free_string);
  v2nl_attribute_attrs
    = ht_new_attribute (v2nl_attributes, sizeof (nl_attr), NULL, NULL);
  v2nl_attribute_types
    = ht_new_attribute (v2nl_attributes, sizeof (char), NULL, NULL);
  
  v2nl_active_attributes
    = ht_alloc (16, ht_hash_string, ht_compare_string, ht_copy_string,
		ht_free_string);
  v2nl_active_int_values
    = ht_new_attribute (v2nl_active_attributes, sizeof (int), NULL, NULL);
  v2nl_active_string_values
    = ht_new_attribute (v2nl_active_attributes, sizeof (char *),
			NULL, v2nl_free_string_attr);

  designs_read = AR_NEW (1, nl_design);

  bus_naming_style = bus_style;

  error_unwind_protect {
    v2nl_zzasp = ZZA_STACKSIZE;
    v2nl_zzast_sp = ZZAST_STACKSIZE;
    ANTLR (verilog_file(&ptr), ifp);
  } 
  error_on_error {
    ar_free (designs_read);

    if ( v2nl_parameter_table != NULL ) {
      ht_free (v2nl_parameter_table);
    }

    if ( v2nl_current_design != NULL ) {
      nl_context_remove_design (context, v2nl_current_design);
      v2nl_current_design = NULL;
    }
  }
  error_on_exit {
    v2nl_lex_cleanup ();
    fclose (ifp);
  } error_end;

  return designs_read;
}
