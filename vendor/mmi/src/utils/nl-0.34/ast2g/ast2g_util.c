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
#include "nl.h"
#include "str.h"
#include "ssa.h"
#include "ast2g.h"
#include "ast2g_int.h"
#include "namegen.h"


static
char *
ast2g_remove_underbars (char *str)
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


void
ast2g_walk_constant (int width, char radix, char *str,
		     void make_one (void *, int), void *data)
{
  char *s = ast2g_remove_underbars (str);

  switch (radix) {

  case 'b': {
    int i;
    int len = strlen (s);

    for ( i = 0; i < len; i++ ) {
      if ( s[i] == '1' ) {
	make_one (data, width - len + i);
      }
      else if ( s[i] == 'x' ) {
	/* dont-care: assume it's a zero */
      }
      else if ( s[i] != '0' ) {
	error ("invalid character in binary constant: '%c' in %d'%c%s.",
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
      else if ( s[i] == 'x' ) {
	/* dont-care: assume it's a zero */
	x = 0;
      }
      else {
	error ("invalid character in hexadecimal constant: '%c' in %d'%c%s.",
	       s[i], width, radix, s);
      }

      y = x;
      idx = 0;

      while ( y != 0 ) {
	if ( y % 2 ) {
	  make_one (data, width - 1 - 4*(len - 1 - i) - idx);
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
      error ("decimal constants longer than 9 digits are not supported: %d'%c%s.",
	     width, radix, str);
    }
      
    sscanf (s, "%u", &x);

    y = x;

    while ( y != 0 ) {
      if ( y % 2 )
	make_one (data, idx);

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
	error ("invalid character in octal constant: '%c' in %d'%c%s.",
	       s[i], width, radix, s);
      }

      y = x;
      idx = 0;

      while ( y != 0 ) {
	if ( y % 2 ) {
	  make_one (data, width - 1 - 3*(len - 1 - i) - idx);
	}

	idx++;
	y >>= 1;
      }
    }
    break;
  }
  default:
    error ("invalid radix character in constant, '%c'.", radix);
  }
}


#if 0
static
int
ast2g_hex_char_to_decimal (char c)
{
  int x;

  if ( '0' <= c <= '9' ) {
    x = c - '0';
  }
  else if ( 'a' <= c <= 'f' ) {
    x = 10 + (c - 'a');
  }
  else if ( 'A' <= c <= 'F' ) {
    x = 10 + (c - 'A');
  }
  else {
    ASSERT (0);
  }

  return x;
}
#endif


static
void
ast2g_get_constant_ins_walker (void *ptr, int idx)
{
  ar ins = (ar) ptr;
  int one = -2;

  ar_set (ins, idx, &one);
}


void
ast2g_get_constant_ins (int width, char radix, char *bits, ar ins)
{
  int i;

  for ( i = 0; i < width; i++ ) {
    int zero = -1;
    
    ar_add (ins, &zero);
  }

  ast2g_walk_constant (width, radix, bits, ast2g_get_constant_ins_walker,
		       (void *) ins);
}


struct ast2g_get_constant_value_struct {
  int result;
  int width;
};


static
void
ast2g_get_constant_value_walker (void *ptr, int idx)
{
  struct ast2g_get_constant_value_struct *data = ptr;

  data->result |= (1 << (data->width - idx - 1));
}


int
ast2g_get_constant_value (int width, char radix, char *bits)
{
  struct ast2g_get_constant_value_struct data;

  data.result = 0;
  data.width = width;

  ast2g_walk_constant (width, radix, bits, ast2g_get_constant_value_walker,
		       (void *) &data);

  return data.result;
}


static
int
ast2g_get_constant_value_for_verilog_number (nl_ast num)
{
  nl_ast child1 = nl_ast_child (num);
  nl_ast child2 = nl_ast_sibling (child1);
  nl_number_ast width_ast = (nl_number_ast) child1;
  nl_vnum_ast vnum_ast = (nl_vnum_ast) child2;
  int width = nl_number_ast_value (width_ast);
  char *bits = nl_vnum_ast_bits (vnum_ast);
  nl_token token = nl_ast_token (num);
  int value;

  switch (token) {
  case nl_token_bin:
    value = ast2g_get_constant_value (width, 'b', bits);
    break;
  case nl_token_oct:
    value = ast2g_get_constant_value (width, 'o', bits);
    break;
  case nl_token_dec:
    value = ast2g_get_constant_value (width, 'd', bits);
    break;
  case nl_token_hex:
    value = ast2g_get_constant_value (width, 'h', bits);
    break;
  default:
    ASSERT (0);
  }

  return value;
}

  
int
ast2g_eval_constant (nl_ast const_ast)
{
  nl_token token = nl_ast_token (const_ast);

  switch (token) {
  case nl_token_number: {
    nl_number_ast num_ast = (nl_number_ast) const_ast;
    int value = nl_number_ast_value (num_ast);

    return value;
  }

  case nl_token_bin:
  case nl_token_oct:
  case nl_token_dec:
  case nl_token_hex: {
    int value = ast2g_get_constant_value_for_verilog_number (const_ast);

    return value;
  }

  default:
    ASSERT (0);
  }
}


nl_reference
ast2g_get_reference (nl_design design, char *ref_name, ...)
{
  va_list ap;
  nl_reference ref = nl_design_get_reference_by_name (design, ref_name);

  va_start (ap, ref_name);
  
  if ( ref == NULL ) {
    char *port_name;

    ref = nl_reference_create (ref_name, design, NULL);

    while ( (port_name = va_arg (ap, char *)) != NULL ) {
      nl_refpin_create (port_name, NULL, ref);
    }
  }

  va_end (ap);

  return ref;
}


nl_net
ast2g_get_net (ssa_context context, nl_design design, char *name)
{
  nl_net net = nl_design_get_net_by_name (design, name);

  if ( net == NULL ) {
    net = nl_net_create (name, nl_wireclass_wire, design);
  }

  return net;
}


void
ast2g_connect_nets (nl_net out_net, nl_net in_net, char *file, int line)
{
  nl_design design = nl_net_design (out_net);
  ar lhs_ar = ar_alloc (1, sizeof (nl_net));
  ar rhs_ar = ar_alloc (1, sizeof (nl_net));

  ASSERT (nl_net_design (in_net) == design);

  ar_add (lhs_ar, &out_net);
  ar_add (rhs_ar, &in_net);

  ast2g_assign (design, lhs_ar, rhs_ar, file, line);

  ar_free (lhs_ar);
  ar_free (rhs_ar);
}


#if 0
static
const char *
ast2g_get_unique_net_name (nl_design design)
{
  const char *name;
  nl_named_object existing_obj;

  do {
    name = namegen_random_name ();
    existing_obj = nl_design_get_net_or_bus_by_name (design, (char *) name);
  } while (existing_obj != NULL);

  return name;
}
#endif


static
const char *
ast2g_get_unique_net_name (nl_design design, char *file, int line)
{
  char *format = "n_%d_%d";
  static char buf[32];
  int i = 0;
  nl_named_object existing_obj;

  do {
    i++;
    sprintf (buf, format, line, i);
    existing_obj = nl_design_get_net_or_bus_by_name (design, (char *) buf);
  } while (existing_obj != NULL);

  return buf;
}


nl_net
ast2g_create_new_net (nl_design design, char *file, int line)
{
  const char *net_name = ast2g_get_unique_net_name (design, file, line);
  nl_net new_net
    = nl_net_create ((char *) net_name, nl_wireclass_wire, design);

  return new_net;
}


ar
ast2g_create_new_bus (nl_design design, int width, char *file, int line)
{
  char *bus_naming_style = nl_design_bus_naming_style (design);
  nl_type scalar = nl_type_get_scalar ((nl_object) design);
  nl_type array = nl_type_get_array (scalar, width-1, 0);
  const char *bus_name = ast2g_get_unique_net_name (design, file, line);
  nl_bus bus
    = nl_bus_create ((char *) bus_name, array, nl_kind_net,
		     (nl_object) design);
  char *net_name = alloca (strlen (bus_name) + 16);
  ar result = ar_alloc (width, sizeof (nl_net));

  nl_type_for_all_indexes (array, index) {
    nl_net net;

    sprintf (net_name, bus_naming_style, bus_name, index);
    net = nl_net_create (net_name, nl_wireclass_wire, design);
    nl_bus_add_net (bus, net);
  } nl_end_for;

  nl_bus_for_all_net_members_reverse (bus, out_net) {
    ar_add (result, &out_net);
  } nl_end_for;

  return result;
}


nl_cell
ast2g_create_new_cell (char *name, nl_reference reference,
		       char *file, int line, int index)
{
  char *base_name = (name == NULL) ? nl_reference_name (reference) : name;
  char *cell_name = alloca (strlen (base_name) + 16);
  nl_cell cell;

  if ( index >= 0 ) {
    sprintf (cell_name, "%s_%d$%d$", base_name, ast2g_op_count, index);
  }
  else {
    sprintf (cell_name, "%s_%d", base_name, ast2g_op_count);
  }

  cell = nl_cell_create (cell_name, reference);

  nl_cell_set_file_line (cell, file, line);

  return cell;
}
    

nl_reference
ast2g_get_parameterized_ref (nl_design design, char *base_name, ...)
{
  va_list ap;
  int base_len = strlen (base_name);
  int num_params = 0;
  char *ref_name;
  nl_reference ref;

  va_start (ap, base_name);

  while ( va_arg (ap, int) >= 0 ) {
    num_params++;
  }

  va_end (ap);

  ref_name = alloca (base_len + 4 + 12 * num_params);

  va_start (ap, base_name);
    
  {
    int idx;

    strcpy (ref_name, base_name);
    idx = base_len;
    ref_name[idx] = '#';
    idx++;
    ref_name[idx] = '(';
    idx++;

    {
      int i;

      for ( i = 0; i < num_params; i++ ) {
	int param_value = va_arg (ap, int);

	if ( param_value > 0 ) {
	  char buf[16];
	
	  sprintf (buf, "%d", param_value);

	  if ( i > 0 ) {
	    ref_name[idx] = ',';
	    idx++;
	  }

	  strcpy (ref_name+idx, buf);
	  idx += strlen (buf);
	}
      }
    }

    ref_name[idx] = ')';
    idx++;
    ref_name[idx] = 0;
    idx++;

    ASSERT (idx <= base_len + 4 + 12 * num_params);
  }

  va_end (ap);

  ref = nl_design_get_reference_by_name (design, ref_name);

  if ( ref == NULL ) {
    nl_reference new_ref = ref = nl_reference_create (ref_name, design, NULL);
    nl_type scalar = nl_type_get_scalar ((nl_object) design);
    char *port_name;
    int i;

    va_start (ap, base_name);

    for ( i = 0; i < num_params; i++ ) {
      int param_value = va_arg (ap, int);

      nl_reference_add_parameter (new_ref, param_value);
    }
  
    ASSERT (va_arg (ap, int) == -1);

    while ( (port_name = va_arg (ap, char *)) != NULL ) {
      int port_width = va_arg (ap, int);

      if ( port_width > 0 ) {
	nl_type type = nl_type_get_array (scalar, port_width-1, 0);

	nl_refpin_create_bus (port_name, type, ref);
      }
      else {
	nl_refpin_create (port_name, NULL, ref);
      }
    }

    va_end (ap);
  }
    
  return ref;
}


void
ast2g_connect_pin_bus (nl_cell cell, nl_bus refpin_bus, ar nets, int offset)
{
  int count = 0;

  ASSERT (nl_bus_width (refpin_bus) + offset == ar_size (nets));

  nl_bus_for_all_refpin_members_reverse (refpin_bus, refpin) {
    nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
    int index = count + offset;
    nl_net net;

    ar_ref (nets, index, &net);
    nl_pin_connect_net (pin, net);
    count++;
  } nl_end_for;
}


ar
ast2g_build_mux (nl_design design, int width, ar ctrl_nets, ar in_buses,
		 char *file, int line)
{
  int ctrl_size = ar_size (ctrl_nets);
  int num_branches = 1 << ctrl_size;
  char ref_name[32];
  nl_reference mux_ref;

  sprintf (ref_name, "JNPR_MUX%d", num_branches);

  switch (num_branches) {
  case 2:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "out", width, NULL);
    break;
  case 4:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "out", width, NULL);
    break;
  case 8:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "in4", width, "in5", width,
					   "in6", width, "in7", width,
					   "out", width, NULL);
    break;
  case 16:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "in4", width, "in5", width,
					   "in6", width, "in7", width,
					   "in8", width, "in9", width,
					   "in10", width, "in11", width,
					   "in12", width, "in13", width,
					   "in14", width, "in15", width,
					   "out", width, NULL);
    break;
  case 32:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "in4", width, "in5", width,
					   "in6", width, "in7", width,
					   "in8", width, "in9", width,
					   "in10", width, "in11", width,
					   "in12", width, "in13", width,
					   "in14", width, "in15", width,
					   "in16", width, "in17", width,
					   "in18", width, "in19", width,
					   "in20", width, "in21", width,
					   "in22", width, "in23", width,
					   "in24", width, "in25", width,
					   "in26", width, "in27", width,
					   "in28", width, "in29", width,
					   "in30", width, "in31", width,
					   "out", width, NULL);
    break;
  case 64:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "in4", width, "in5", width,
					   "in6", width, "in7", width,
					   "in8", width, "in9", width,
					   "in10", width, "in11", width,
					   "in12", width, "in13", width,
					   "in14", width, "in15", width,
					   "in16", width, "in17", width,
					   "in18", width, "in19", width,
					   "in20", width, "in21", width,
					   "in22", width, "in23", width,
					   "in24", width, "in25", width,
					   "in26", width, "in27", width,
					   "in28", width, "in29", width,
					   "in30", width, "in31", width,
					   "in32", width, "in33", width,
					   "in34", width, "in35", width,
					   "in36", width, "in37", width,
					   "in38", width, "in39", width,
					   "in40", width, "in41", width,
					   "in42", width, "in43", width,
					   "in44", width, "in45", width,
					   "in46", width, "in47", width,
					   "in48", width, "in49", width,
					   "in50", width, "in51", width,
					   "in52", width, "in53", width,
					   "in54", width, "in55", width,
					   "in56", width, "in57", width,
					   "in58", width, "in59", width,
					   "in60", width, "in61", width,
					   "in62", width, "in63", width,
					   "out", width, NULL);
    break;
  case 128:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "in4", width, "in5", width,
					   "in6", width, "in7", width,
					   "in8", width, "in9", width,
					   "in10", width, "in11", width,
					   "in12", width, "in13", width,
					   "in14", width, "in15", width,
					   "in16", width, "in17", width,
					   "in18", width, "in19", width,
					   "in20", width, "in21", width,
					   "in22", width, "in23", width,
					   "in24", width, "in25", width,
					   "in26", width, "in27", width,
					   "in28", width, "in29", width,
					   "in30", width, "in31", width,
					   "in32", width, "in33", width,
					   "in34", width, "in35", width,
					   "in36", width, "in37", width,
					   "in38", width, "in39", width,
					   "in40", width, "in41", width,
					   "in42", width, "in43", width,
					   "in44", width, "in45", width,
					   "in46", width, "in47", width,
					   "in48", width, "in49", width,
					   "in50", width, "in51", width,
					   "in52", width, "in53", width,
					   "in54", width, "in55", width,
					   "in56", width, "in57", width,
					   "in58", width, "in59", width,
					   "in60", width, "in61", width,
					   "in62", width, "in63", width,
					   "in64", width, "in65", width,
					   "in66", width, "in67", width,
					   "in68", width, "in69", width,
					   "in70", width, "in71", width,
					   "in72", width, "in73", width,
					   "in74", width, "in75", width,
					   "in76", width, "in77", width,
					   "in78", width, "in79", width,
					   "in80", width, "in81", width,
					   "in82", width, "in83", width,
					   "in84", width, "in85", width,
					   "in86", width, "in87", width,
					   "in88", width, "in89", width,
					   "in90", width, "in91", width,
					   "in92", width, "in93", width,
					   "in94", width, "in95", width,
					   "in96", width, "in97", width,
					   "in98", width, "in99", width,
					   "in100", width, "in101", width,
					   "in102", width, "in103", width,
					   "in104", width, "in105", width,
					   "in106", width, "in107", width,
					   "in108", width, "in109", width,
					   "in110", width, "in111", width,
					   "in112", width, "in113", width,
					   "in114", width, "in115", width,
					   "in116", width, "in117", width,
					   "in118", width, "in119", width,
					   "in120", width, "in121", width,
					   "in122", width, "in123", width,
					   "in124", width, "in125", width,
					   "in126", width, "in127", width,
					   "out", width, NULL);
    break;

  case 256:
    mux_ref = ast2g_get_parameterized_ref (design, ref_name, width, -1,
					   "sel", ctrl_size,
					   "in0", width, "in1", width,
					   "in2", width, "in3", width,
					   "in4", width, "in5", width,
					   "in6", width, "in7", width,
					   "in8", width, "in9", width,
					   "in10", width, "in11", width,
					   "in12", width, "in13", width,
					   "in14", width, "in15", width,
					   "in16", width, "in17", width,
					   "in18", width, "in19", width,
					   "in20", width, "in21", width,
					   "in22", width, "in23", width,
					   "in24", width, "in25", width,
					   "in26", width, "in27", width,
					   "in28", width, "in29", width,
					   "in30", width, "in31", width,
					   "in32", width, "in33", width,
					   "in34", width, "in35", width,
					   "in36", width, "in37", width,
					   "in38", width, "in39", width,
					   "in40", width, "in41", width,
					   "in42", width, "in43", width,
					   "in44", width, "in45", width,
					   "in46", width, "in47", width,
					   "in48", width, "in49", width,
					   "in50", width, "in51", width,
					   "in52", width, "in53", width,
					   "in54", width, "in55", width,
					   "in56", width, "in57", width,
					   "in58", width, "in59", width,
					   "in60", width, "in61", width,
					   "in62", width, "in63", width,
					   "in64", width, "in65", width,
					   "in66", width, "in67", width,
					   "in68", width, "in69", width,
					   "in70", width, "in71", width,
					   "in72", width, "in73", width,
					   "in74", width, "in75", width,
					   "in76", width, "in77", width,
					   "in78", width, "in79", width,
					   "in80", width, "in81", width,
					   "in82", width, "in83", width,
					   "in84", width, "in85", width,
					   "in86", width, "in87", width,
					   "in88", width, "in89", width,
					   "in90", width, "in91", width,
					   "in92", width, "in93", width,
					   "in94", width, "in95", width,
					   "in96", width, "in97", width,
					   "in98", width, "in99", width,
					   "in100", width, "in101", width,
					   "in102", width, "in103", width,
					   "in104", width, "in105", width,
					   "in106", width, "in107", width,
					   "in108", width, "in109", width,
					   "in110", width, "in111", width,
					   "in112", width, "in113", width,
					   "in114", width, "in115", width,
					   "in116", width, "in117", width,
					   "in118", width, "in119", width,
					   "in120", width, "in121", width,
					   "in122", width, "in123", width,
					   "in124", width, "in125", width,
					   "in126", width, "in127", width,
					   "in128", width, "in129", width,
					   "in130", width, "in131", width,
					   "in132", width, "in133", width,
					   "in134", width, "in135", width,
					   "in136", width, "in137", width,
					   "in138", width, "in139", width,
					   "in140", width, "in141", width,
					   "in142", width, "in143", width,
					   "in144", width, "in145", width,
					   "in146", width, "in147", width,
					   "in148", width, "in149", width,
					   "in150", width, "in151", width,
					   "in152", width, "in153", width,
					   "in154", width, "in155", width,
					   "in156", width, "in157", width,
					   "in158", width, "in159", width,
					   "in160", width, "in161", width,
					   "in162", width, "in163", width,
					   "in164", width, "in165", width,
					   "in166", width, "in167", width,
					   "in168", width, "in169", width,
					   "in170", width, "in171", width,
					   "in172", width, "in173", width,
					   "in174", width, "in175", width,
					   "in176", width, "in177", width,
					   "in178", width, "in179", width,
					   "in180", width, "in181", width,
					   "in182", width, "in183", width,
					   "in184", width, "in185", width,
					   "in186", width, "in187", width,
					   "in188", width, "in189", width,
					   "in190", width, "in191", width,
					   "in192", width, "in193", width,
					   "in194", width, "in195", width,
					   "in196", width, "in197", width,
					   "in198", width, "in199", width,
					   "in200", width, "in201", width,
					   "in202", width, "in203", width,
					   "in204", width, "in205", width,
					   "in206", width, "in207", width,
					   "in208", width, "in209", width,
					   "in210", width, "in211", width,
					   "in212", width, "in213", width,
					   "in214", width, "in215", width,
					   "in216", width, "in217", width,
					   "in218", width, "in219", width,
					   "in220", width, "in221", width,
					   "in222", width, "in223", width,
					   "in224", width, "in225", width,
					   "in226", width, "in227", width,
					   "in228", width, "in229", width,
					   "in230", width, "in231", width,
					   "in232", width, "in233", width,
					   "in234", width, "in235", width,
					   "in236", width, "in237", width,
					   "in238", width, "in239", width,
					   "in240", width, "in241", width,
					   "in242", width, "in243", width,
					   "in244", width, "in245", width,
					   "in246", width, "in247", width,
					   "in248", width, "in249", width,
					   "in250", width, "in251", width,
					   "in252", width, "in253", width,
					   "in254", width, "in255", width,
					   "out", width, NULL);
    break;

  default:
    ASSERT (0);
  }

  ast2g_op_count++;

  {
    nl_cell mux_cell
      = ast2g_create_new_cell (ref_name, mux_ref, file, line, -1);
    nl_bus sel_refpin_bus
      = (nl_bus) nl_reference_get_refpin_by_name (mux_ref, "sel");
    nl_bus out_refpin_bus
      = (nl_bus) nl_reference_get_refpin_by_name (mux_ref, "out");
    ar out_nets = ast2g_create_new_bus (design, width, file, line);
    int i;

    ast2g_connect_pin_bus (mux_cell, sel_refpin_bus, ctrl_nets, 0);
    ast2g_connect_pin_bus (mux_cell, out_refpin_bus, out_nets, 0);

    for ( i = 0; i < num_branches; i++ ) {
      char pin_name[8];
      nl_bus in_refpin_bus;
      ar in_nets;

      ar_ref (in_buses, i, &in_nets);

      sprintf (pin_name, "in%d", i);
    
      in_refpin_bus
	= (nl_bus) nl_reference_get_refpin_by_name (mux_ref, pin_name);

      ast2g_connect_pin_bus (mux_cell, in_refpin_bus, in_nets, 0);
    }

    return out_nets;
  }
}


void
ast2g_build_mux2 (nl_net sel_net, ar in0_nets, ar in1_nets, ar out_nets,
		  char *file, int line)
{
  nl_design design = nl_net_design (sel_net);
  int width = ar_size (out_nets);
  nl_reference ref
    = ast2g_get_parameterized_ref (design, "JNPR_MUX2", width, -1,
				   "sel", 1, "in0", width, "in1", width,
				   "out", width, NULL);
  nl_cell mux_cell = ast2g_create_new_cell (NULL, ref, file, line, -1);
  nl_bus sel_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "sel");
  nl_bus in0_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "in0");
  nl_bus in1_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "in1");
  nl_bus out_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "out");
  nl_refpin sel_refpin = (nl_refpin) nl_bus_get_member (sel_bus, 0);
  nl_pin sel_pin = nl_cell_get_pin_by_refpin (mux_cell, sel_refpin);

  ast2g_connect_pin_bus (mux_cell, in0_bus, in0_nets, 0);
  ast2g_connect_pin_bus (mux_cell, in1_bus, in1_nets, 0);
  ast2g_connect_pin_bus (mux_cell, out_bus, out_nets, 0);
  nl_pin_connect_net (sel_pin, sel_net);
}


void
ast2g_get_clocks (nl_ast sens_list, nl_net *clks, nl_token *clk_edges,
		  ar inputs)
{
  nl_ast l = nl_ast_child (sens_list);
  int clocks_found = 0;

  clks[0] = NULL;
  clks[1] = NULL;
  clk_edges[0] = nl_token_null;
  clk_edges[1] = nl_token_null;
  
  while ( l != NULL ) {
    nl_token token = nl_ast_token (l);
    
    if ( token == nl_token_posedge || token == nl_token_negedge ) {
      if ( clocks_found < 0 ) {
	ast2g_ast_error (sens_list, "sensitivity list contains both "
			 "edge-sensitive and level-sensitive elements");
      }
      else {
	nl_in_ast in_ast = (nl_in_ast) nl_ast_child (l);
	int index = nl_in_ast_index (in_ast);
	nl_pin clk_pin;
	nl_net clk_net;

	ASSERT (nl_in_ast_token (in_ast) == nl_token_in);

	ar_ref (inputs, index, &clk_pin);
	clk_net = nl_pin_net (clk_pin);

	clks[clocks_found] = clk_net;
	clk_edges[clocks_found] = token;
	clocks_found++;
      }
    } 
    else {
      if ( clocks_found > 0 ) {
	ast2g_ast_error (sens_list, "sensitivity list contains both "
			 "edge-sensitive and level-sensitive elements");
      }
      else {
	clocks_found = -1;
      }
    }

    l = nl_ast_sibling (l);
  }
}


void
ast2g_register_net (nl_net q_net, nl_net d_net, nl_net clk_net,
		    nl_token clk_edge, nl_net rst_net, nl_token rst_edge,
		    int is_preset, char *file, int line)
{
  nl_design design = nl_net_design (q_net);
  nl_reference ref;
  char *clk_name;
  char *rst_name;

  if ( rst_net == NULL ) {
    char *ref_name;
    
    if ( clk_edge == nl_token_posedge ) {
      ref_name = "JNPR_FF_R";
      clk_name = "clk";
    }
    else {
      ref_name = "JNPR_FF_F";
      clk_name = "nclk";
    }

    ref = ast2g_get_reference (design, ref_name, clk_name, "d", "q", NULL);

    rst_name = "*nonexistent*";
  }
  else {
    char *ref_name;

    if ( clk_edge == nl_token_posedge ) {
      clk_name = "clk";

      if ( !is_preset ) {
	if ( rst_edge == nl_token_posedge ) {
	  ref_name = "JNPR_FF_RCR";
	  rst_name = "clrb";
	}
	else if ( rst_edge == nl_token_negedge ) {
	  ref_name = "JNPR_FF_RCF";
	  rst_name = "nclrb";
	}
	else if ( rst_edge == nl_token_null ) {
	  ref_name = "JNPR_FF_RSCH";
	  rst_name = "clr";
	}
	else if ( rst_edge == nl_token_bitnot ) {
	  ref_name = "JNPR_FF_RSCL";
	  rst_name = "nclr";
	}
	else {
	  ASSERT (0);
	}
      }
      else { /* is_preset */
	if ( rst_edge == nl_token_posedge ) {
	  ref_name = "JNPR_FF_RPR";
	  rst_name = "setb";
	}
	else if ( rst_edge == nl_token_negedge ) {
	  ref_name = "JNPR_FF_RPF";
	  rst_name = "nsetb";
	}
	else if ( rst_edge == nl_token_null ) {
	  ref_name = "JNPR_FF_RSPH";
	  rst_name = "set";
	}
	else if ( rst_edge == nl_token_bitnot ) {
	  ref_name = "JNPR_FF_RSPL";
	  rst_name = "nset";
	}
	else {
	  ASSERT (0);
	}
      }
    }
    else {
      clk_name = "nclk";

      if ( !is_preset ) {
	if ( rst_edge == nl_token_posedge ) {
	  ref_name = "JNPR_FF_FCR";
	  rst_name = "clrb";
	}
	else if ( rst_edge == nl_token_negedge ) {
	  ref_name = "JNPR_FF_FCF";
	  rst_name = "nclrb";
	}
	else if ( rst_edge == nl_token_null ) {
	  ref_name = "JNPR_FF_FSCH";
	  rst_name = "clr";
	}
	else if ( rst_edge == nl_token_bitnot ) {
	  ref_name = "JNPR_FF_FSCL";
	  rst_name = "nclr";
	}
	else {
	  ASSERT (0);
	}
      }
      else { /* is_preset */
	if ( rst_edge == nl_token_posedge ) {
	  ref_name = "JNPR_FF_FPR";
	  rst_name = "setb";
	}
	else if ( rst_edge == nl_token_negedge ) {
	  ref_name = "JNPR_FF_FPF";
	  rst_name = "nsetb";
	}
	else if ( rst_edge == nl_token_null ) {
	  ref_name = "JNPR_FF_FSPH";
	  rst_name = "set";
	}
	else if ( rst_edge == nl_token_bitnot ) {
	  ref_name = "JNPR_FF_FSPL";
	  rst_name = "nset";
	}
	else {
	  ASSERT (0);
	}
      }
    }

    ref = ast2g_get_reference (design, ref_name, clk_name, "d", "q",
			       rst_name, NULL);
  }

  {
    nl_refpin clk_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (ref, clk_name);
    nl_refpin d_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (ref, "d");
    nl_refpin q_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (ref, "q");
    nl_refpin rst_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (ref, rst_name);
    nl_cell cell = ast2g_create_new_cell (NULL, ref, file, line, -1);
    nl_pin clk_pin = nl_cell_get_pin_by_refpin (cell, clk_refpin);
    nl_pin d_pin   = nl_cell_get_pin_by_refpin (cell, d_refpin);
    nl_pin q_pin   = nl_cell_get_pin_by_refpin (cell, q_refpin);

    nl_pin_connect_net (clk_pin, clk_net);
    nl_pin_connect_net (d_pin, d_net);
    nl_pin_connect_net (q_pin, q_net);

    if ( rst_refpin != NULL ) {
      nl_pin rst_pin = nl_cell_get_pin_by_refpin (cell, rst_refpin);

      nl_pin_connect_net (rst_pin, rst_net);
    }
  }

  ast2g_op_count++;
}


void
ast2g_find_reset_preset (nl_design design, ar d_nets, ar new_d_nets,
			 ar reset_nets, ar reset_levels, ar presets)
{
  nl_net zero_net = nl_design_get_net_by_name (design,"1'b0");
  nl_net one_net = nl_design_get_net_by_name (design, "1'b1");
  nl_cell_attr cell_attr
    = nl_cell_attr_create (NULL, design, nl_density_sparse, sizeof (int),
			   NULL, NULL);
  ar dead_nets = ar_alloc (ar_size (d_nets), sizeof (nl_net));
  ar dead_cells = ar_alloc (1, sizeof (nl_cell));
  
  ar_for_all (d_nets, nl_net, d_net) {
    int num_pins = nl_net_num_pins (d_net);

    if ( num_pins == 1 ) {
      nl_dll_head fanios = nl_net_fanios (d_net);
      nl_pin out_pin = (nl_pin) nl_dll_gen_first (fanios);
      nl_cell_or_port owner = nl_pin_owner (out_pin);

      if ( nl_cell_or_port_kind (owner) == nl_kind_cell ) {
	nl_cell cell = (nl_cell) owner;
	nl_reference ref = nl_cell_reference (cell);
	char *ref_name = nl_reference_name (ref);

	if ( strncmp (ref_name, "JNPR_MUX2#", 10) == 0 ) {
	  nl_bus in0_bus
	    = (nl_bus) nl_reference_get_refpin_by_name (ref, "in0");
	  nl_bus in1_bus
	    = (nl_bus) nl_reference_get_refpin_by_name (ref, "in1");
	  nl_bus sel_bus
	    = (nl_bus) nl_reference_get_refpin_by_name (ref, "sel");
	  nl_refpin out_refpin = nl_pin_refpin (out_pin);
	  int out_offset = nl_refpin_bus_offset (out_refpin);
	  nl_refpin sel_refpin
	    = (nl_refpin) nl_bus_get_member (sel_bus, 0);
	  nl_refpin in0_refpin
	    = (nl_refpin) nl_bus_get_member (in0_bus, out_offset);
	  nl_refpin in1_refpin
	    = (nl_refpin) nl_bus_get_member (in1_bus, out_offset);
	  nl_pin sel_pin = nl_cell_get_pin_by_refpin (cell, sel_refpin);
	  nl_pin in0_pin = nl_cell_get_pin_by_refpin (cell, in0_refpin);
	  nl_pin in1_pin = nl_cell_get_pin_by_refpin (cell, in1_refpin);
	  nl_net sel_net = nl_pin_net (sel_pin);
	  nl_net in0_net = nl_pin_net (in0_pin);
	  nl_net in1_net = nl_pin_net (in1_pin);
	  int zero = 0;
	  int one = 1;

	  if ( in1_net == zero_net ) {
	    ar_add (new_d_nets, &in0_net);
	    ar_add (reset_nets, &sel_net);
	    ar_add (presets, &zero);
	    ar_add (reset_levels, &one);
	  }
	  else if ( in1_net == one_net ) {
	    ar_add (new_d_nets, &in0_net);
	    ar_add (reset_nets, &sel_net);
	    ar_add (presets, &one);
	    ar_add (reset_levels, &one);
	  }
	  else if ( in0_net == zero_net ) {
	    ar_add (new_d_nets, &in1_net);
	    ar_add (reset_nets, &sel_net);
	    ar_add (presets, &zero);
	    ar_add (reset_levels, &zero);
	  }
	  else if ( in0_net == one_net ) {
	    ar_add (new_d_nets, &in1_net);
	    ar_add (reset_nets, &sel_net);
	    ar_add (presets, &one);
	    ar_add (reset_levels, &zero);
	  }
	  else {
	    goto no_reset;
	  }

	  {
	    int flag;

	    nl_cell_attr_get (cell_attr, cell, &flag);

	    if ( flag == 0 ) {
	      nl_cell_attr_set (cell_attr, cell, &one);
	      ar_add (dead_cells, &cell);
	    }

	    ar_add (dead_nets, &d_net);
	    nl_pin_disconnect (out_pin);
	  }
	}
	else {
	  goto no_reset;
	}
      }
      else {
	goto no_reset;
      }
    }
    else {
      int zero;
      nl_net null;
    no_reset:

      zero = 0;
      null = NULL;

      ar_add (new_d_nets, &d_net);
      ar_add (reset_nets, &null);
      ar_add (presets, &zero);
      ar_add (reset_levels, &zero);
    }
  } ar_end_for;

  {
    int num_nets = ar_size (d_nets);
    
    ASSERT (num_nets == ar_size (new_d_nets));
    ASSERT (num_nets == ar_size (reset_nets));
    ASSERT (num_nets == ar_size (presets));
    ASSERT (num_nets == ar_size (reset_levels));
  }

  ar_for_all (dead_cells, nl_cell, dead_cell) {
    nl_reference ref = nl_cell_reference (dead_cell);
    nl_bus out_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "out");
    nl_bus in0_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "in0");
    nl_bus in1_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "in1");
    ar in0_nets = ar_alloc (1, sizeof (nl_net));
    ar in1_nets = ar_alloc (1, sizeof (nl_net));
    ar out_nets = ar_alloc (1, sizeof (nl_net));
    
    nl_bus_for_all_refpin_members (out_bus, out_refpin) {
      nl_pin out_pin = nl_cell_get_pin_by_refpin (dead_cell, out_refpin);
      nl_net out_net = nl_pin_net (out_pin);

      if ( out_net != NULL ) {
	int off = nl_refpin_bus_offset (out_refpin);
	nl_refpin in0_refpin = (nl_refpin) nl_bus_get_member (in0_bus, off);
	nl_refpin in1_refpin = (nl_refpin) nl_bus_get_member (in1_bus, off);
	nl_pin in0_pin = nl_cell_get_pin_by_refpin (dead_cell, in0_refpin);
	nl_pin in1_pin = nl_cell_get_pin_by_refpin (dead_cell, in1_refpin);
	nl_net in0_net = nl_pin_net (in0_pin);
	nl_net in1_net = nl_pin_net (in1_pin);

	ar_add (in0_nets, &in0_net);
	ar_add (in1_nets, &in1_net);
	ar_add (out_nets, &out_net);
      }
    } nl_end_for;

    if ( ar_size (in0_nets) > 0 ) {
      nl_bus sel_bus = (nl_bus) nl_reference_get_refpin_by_name (ref, "sel");
      nl_refpin sel_refpin = (nl_refpin) nl_bus_get_member (sel_bus, 0);
      nl_pin sel_pin = nl_cell_get_pin_by_refpin (dead_cell, sel_refpin);
      nl_net sel_net = nl_pin_net (sel_pin);
      char *file = nl_cell_file (dead_cell);
      int line = nl_cell_line (dead_cell);

      ASSERT (nl_bus_width (sel_bus) == 1);
      
      ast2g_build_mux2 (sel_net, in0_nets, in1_nets, out_nets, file, line);
    }

    ar_free (in0_nets);
    ar_free (in1_nets);
    ar_free (out_nets);

    nl_design_remove_cell (design, dead_cell);
  } ar_end_for;

  ar_free (dead_cells);
  nl_design_remove_attr (design, (nl_attr) cell_attr);

  ar_for_all (dead_nets, nl_net, d_net) {
    nl_design_remove_net (design, d_net);
  } ar_end_for;

  ar_free (dead_nets);
}


nl_reference
ast2g_build_reference_for_function (nl_subprogram fun, char *ref_name,
				    char *out_name)
{
  nl_design design = nl_subprogram_design (fun);
  nl_reference reference = nl_reference_create (ref_name, design, NULL);

  nl_subprogram_for_all_formals (fun, formal) {
    char *arg_name = nl_symbol_name (formal);
    nl_type arg_type = nl_symbol_type (formal);
    nl_typeclass class = nl_type_class (arg_type);

    if ( class == nl_typeclass_scalar ) {
      nl_refpin_create (arg_name, NULL, reference);
    }
    else if ( class == nl_typeclass_array ) {
      nl_refpin_create_bus (arg_name, arg_type, reference);
    }
    else {
      ASSERT (0);
    }
  } nl_end_for;

  {
    nl_type out_type = nl_subprogram_type (fun);
    nl_typeclass class = nl_type_class (out_type);

    if ( class == nl_typeclass_scalar ) {
      nl_refpin_create (out_name, NULL, reference);
    }
    else if ( class == nl_typeclass_array ) {
      nl_refpin_create_bus (out_name, out_type, reference);
    }
    else {
      ASSERT (0);
    }
  }

  return reference;
}
