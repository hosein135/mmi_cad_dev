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


int ast2g_op_count = 0;


struct ast2g_constant_nets_data {
  ar result;
  nl_net one;
};


static
void
ast2g_get_constant_nets_walker (void *ptr, int idx)
{
  struct ast2g_constant_nets_data *data = ptr;

  ar_set (data->result, idx, &data->one);
}


ar
ast2g_get_constant_nets (nl_design design, int width, char radix, char *str)
{
  nl_net zero = ast2g_get_net (NULL, design, "1'b0");
  nl_net one = ast2g_get_net (NULL, design, "1'b1");
  ar result = ar_alloc (width, sizeof (nl_net));
  struct ast2g_constant_nets_data data;
  int i;

  data.result = result;
  data.one = one;

  for ( i = 0; i < width; i++ ) {
    ar_add (result, &zero);
  }

  ast2g_walk_constant (width, radix, str, ast2g_get_constant_nets_walker,
		       &data);

  return result;
}

			 
static
ar
ast2g_verilog_number (nl_design design, char radix, nl_ast tree)
{
  nl_number_ast width_ast = (nl_number_ast) nl_ast_child (tree);
  int width = nl_number_ast_value (width_ast);
  nl_vnum_ast vnum_ast = (nl_vnum_ast) nl_number_ast_sibling (width_ast);
  char *bits = nl_vnum_ast_bits (vnum_ast);
  ar result = ast2g_get_constant_nets (design, width, radix, bits);

  return result;
}


static
ar
ast2g_concat (ssa_context context, nl_design design, nl_ast tree,
	      ar inputs, ar outputs)
{
  nl_ast child = nl_ast_child (tree);
  ar result = NULL;

  while ( child != NULL ) {
    ar nets = ast2g_expression (context, design, child, inputs, outputs);

    if ( result != NULL ) {
      ar_append (result, nets);
      ar_free (nets);
    }
    else {
      result = nets;
    }

    child = nl_ast_sibling (child);
  }

  return result;
}


static
ar
ast2g_repeat_concat (ssa_context context, nl_design design, nl_ast tree,
		     ar inputs, ar outputs)
{
  nl_number_ast num_ast = (nl_number_ast) nl_ast_child (tree);
  int width = nl_number_ast_value (num_ast);
  nl_ast arg = nl_number_ast_sibling (num_ast);
  ar nets = ast2g_expression (context, design, arg, inputs, outputs);
  int i;
  int size = width * ar_size (nets);
  ar result = AR_NEW (size, nl_net);

  for ( i = 0; i < width; i++ ) {
    ar_append (result, nets);
  }

  ar_free (nets);

  return result;
}


static
void
ast2g_invert_net (nl_net in_net, nl_net out_net,
		  char *file, int line, int index)
{
  nl_design design = nl_net_design (in_net);
  char *in_net_name = nl_net_name (in_net);
  
  if ( strcmp (in_net_name, "1'b0") == 0 ) {
    nl_net one_net = ast2g_get_net (NULL, design, "1'b1");
    ast2g_connect_nets (out_net, one_net, file, line);
  }
  else if ( strcmp (in_net_name, "1'b1") == 0 ) {
    nl_net zero_net = ast2g_get_net (NULL, design, "1'b0");
    ast2g_connect_nets (out_net, zero_net, file, line);
  }
  else {
    nl_reference reference
      = ast2g_get_reference (design, "JNPR_INV", "in", "out", NULL);
    nl_refpin in_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (reference, "in");
    nl_refpin out_refpin
      = (nl_refpin) nl_reference_get_refpin_by_name (reference, "out");
    nl_cell cell = ast2g_create_new_cell (NULL, reference, file, line, index);
    nl_pin in_pin = nl_cell_get_pin_by_refpin (cell, in_refpin);
    nl_pin out_pin = nl_cell_get_pin_by_refpin (cell, out_refpin);

    nl_pin_connect_net (in_pin, in_net);
    nl_pin_connect_net (out_pin, out_net);
  }
}


static
ar
ast2g_invert_nets (nl_design design, ar in_nets, char *file, int line)
{
  int size = ar_size (in_nets);
  ar out_nets;

  if ( size > 1 ) {
    out_nets = ast2g_create_new_bus (design, size, file, line);
  }
  else {
    nl_net out_net = ast2g_create_new_net (design, file, line);

    out_nets = ar_alloc (1, sizeof (nl_net));
    ar_add (out_nets, &out_net);
  }

  ast2g_op_count++;

  ar_for_all_indexed (in_nets, nl_net, in_net, index) {
    nl_net out_net;

    ar_ref (out_nets, index, &out_net);

    ast2g_invert_net (in_net, out_net, file, line, index);
  } ar_end_for;

  return out_nets;
}

/*
static
ar
ast2g_unary_op (char *op_name, ssa_context context, nl_design design,
		nl_ast tree, ar inputs, ar outputs, char *file, int line)
    UNUSED;	       
*/

static
ar
ast2g_unary_op (char *op_name, ssa_context context, nl_design design,
		nl_ast tree, ar inputs, ar outputs, char *file, int line)
{
  nl_ast arg = nl_ast_child (tree);
  ar in_nets = ast2g_expression (context, design, arg, inputs, outputs);
  nl_reference reference
    = ast2g_get_reference (design, op_name, "in", "out", NULL);
  nl_refpin in_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "in");
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "out");
  int width = ar_size (in_nets);
  ar out_nets;

  if ( width > 1 ) {
    out_nets = ast2g_create_new_bus (design, width, file, line);
  }
  else {
    nl_net out_net = ast2g_create_new_net (design, file, line);

    ASSERT (width == 1);

    out_nets = ar_alloc (1, sizeof (nl_net));
    ar_add (out_nets, &out_net);
  }

  ast2g_op_count++;

  ar_for_all_indexed (in_nets, nl_net, in_net, index) {
    nl_cell cell = ast2g_create_new_cell (NULL, reference, file, line, index);
    nl_pin in_pin = nl_cell_get_pin_by_refpin (cell, in_refpin);
    nl_pin out_pin = nl_cell_get_pin_by_refpin (cell, out_refpin);
    nl_net out_net;

    ar_ref (out_nets, index, &out_net);

    nl_pin_connect_net (in_pin, in_net);
    nl_pin_connect_net (out_pin, out_net);
  } ar_end_for;

  ar_free (in_nets);

  return out_nets;
}


static
ar
ast2g_binary_op (char *op_name, ssa_context context, nl_design design,
		 nl_ast tree, ar inputs, ar outputs,
		 char *force_0, char *force_1, char *feedthru, char *invert,
		 char *file, int line)
{
  nl_ast arg0 = nl_ast_child (tree);
  nl_ast arg1 = nl_ast_sibling (arg0);
  ar in0_nets = ast2g_expression (context, design, arg0, inputs, outputs);
  ar in1_nets = ast2g_expression (context, design, arg1, inputs, outputs);
  nl_reference reference
    = ast2g_get_reference (design, op_name, "in0", "in1", "out", NULL);
  nl_refpin in0_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "in0");
  nl_refpin in1_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "in1");
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "out");
  int in0_width = ar_size (in0_nets);
  int in1_width = ar_size (in1_nets);
  int out_width = in0_width > in1_width ? in0_width : in1_width;
  nl_net zero_net = ast2g_get_net (NULL, design, "1'b0");
  nl_net one_net = ast2g_get_net (NULL, design, "1'b1");
  nl_net force_0_net = force_0 ? ast2g_get_net (NULL, design, force_0) : NULL;
  nl_net force_1_net = force_1 ? ast2g_get_net (NULL, design, force_1) : NULL;
  nl_net feedthru_net = feedthru ? ast2g_get_net (NULL, design, feedthru)
                                 : NULL;
  nl_net invert_net = invert ? ast2g_get_net (NULL, design, invert) : NULL;
  ar out_nets;
  int i;

  if ( out_width > 1 ) {
    out_nets = ast2g_create_new_bus (design, out_width, file, line);
  }
  else {
    nl_net out_net = ast2g_create_new_net (design, file, line);

    ASSERT (out_width == 1);

    out_nets = ar_alloc (1, sizeof (nl_net));
    ar_add (out_nets, &out_net);
  }

  ast2g_op_count++;

  /* The following condition is guaranteed by type balancing. */
  ASSERT (in0_width == in1_width && in1_width == out_width);

  for ( i = 0; i < out_width; i++ ) {
    nl_net in0_net;
    nl_net in1_net;
    nl_net out_net;

    int index = out_width - i - 1;

    ar_ref (in0_nets, i, &in0_net);
    ar_ref (in1_nets, i, &in1_net);
    ar_ref (out_nets, i, &out_net);

    if ( in0_net == force_0_net || in1_net == force_0_net ) {
      ast2g_connect_nets (out_net, zero_net, file, line);
    }
    else if ( in1_net == force_1_net || in1_net == force_1_net ) {
      ast2g_connect_nets (out_net, one_net, file, line);
    }
    else if ( in0_net == feedthru_net ) {
      ast2g_connect_nets (out_net, in1_net, file, line);
    }
    else if ( in1_net == feedthru_net ) {
      ast2g_connect_nets (out_net, in0_net, file, line);
    }
    else if ( in0_net == invert_net ) {
      ast2g_invert_net (in1_net, out_net, file, line, index);
    }
    else if ( in1_net == invert_net ) {
      ast2g_invert_net (in0_net, out_net, file, line, index);
    }
    else {
      nl_cell cell
	= ast2g_create_new_cell (NULL, reference, file, line, index);
      nl_pin in0_pin = nl_cell_get_pin_by_refpin (cell, in0_refpin);
      nl_pin in1_pin = nl_cell_get_pin_by_refpin (cell, in1_refpin);
      nl_pin out_pin = nl_cell_get_pin_by_refpin (cell, out_refpin);

      nl_pin_connect_net (in0_pin, in0_net);
      nl_pin_connect_net (in1_pin, in1_net);
      nl_pin_connect_net (out_pin, out_net);
    }
  }

  ar_free (in0_nets);
  ar_free (in1_nets);

  return out_nets;
}

#if 0
static
ar
ast2g_logic_op (char *op_name, ssa_context context, nl_design design,
		nl_ast tree, ar inputs, ar outputs,
		char *force_0, char *force_1, char *feedthru, char *invert,
		char *file, int line)
{
  int num_children = nl_ast_num_children (tree);
  nl_ast *args = alloca (num_children * sizeof (nl_ast_tree));
  ar *in_nets = alloca (num_children * sizeof (ar));
  ar reference = ast2g_get_logic_reference (design, op_name, num_chldren);
  nl_refpin *in_refpins = alloc (num_children * sizeof (ar));
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "out");
  int out_width = -1;
  int i;

  nl_ast_get_args (tree, num_children, args);

  for ( i = 0; i < num_children; i++ ) {
    char in_name[16];
    int in_width;
    
    in_nets[i] = ast2g_expression (context, design, args[i], inputs, outputs);
    in_width = ar_size (in_nets[i]);

    sprintf (in_name, "in%d", i);
    in_refpins[i] = nl_reference_get_refpin_by_name (reference, in_name);

    if ( out_width < 0 ) {
      out_width = in_width;
    }
    else {
      ASSERT (out_width == in_width);
    }
  }

  {
    nl_net zero_net = ast2g_get_net (NULL, design, "1'b0");
    nl_net one_net = ast2g_get_net (NULL, design, "1'b1");
    nl_net force_0_net = force_0 ? ast2g_get_net (NULL, design, force_0) : NULL;
    nl_net force_1_net = force_1 ? ast2g_get_net (NULL, design, force_1) : NULL;
    nl_net feedthru_net = feedthru ? ast2g_get_net (NULL, design, feedthru)
      : NULL;
    nl_net invert_net = invert ? ast2g_get_net (NULL, design, invert) : NULL;
    ar out_nets;

    if ( out_width > 1 ) {
      out_nets = ast2g_create_new_bus (design, out_width, file, line);
    }
    else {
      nl_net out_net = ast2g_create_new_net (design, file, line);

      ASSERT (out_width == 1);

      out_nets = ar_alloc (1, sizeof (nl_net));
      ar_add (out_nets, &out_net);
    }

    ast2g_op_count++;

    /* The following condition is guaranteed by type balancing. */
    ASSERT (in0_width == in1_width && in1_width == out_width);

  for ( i = 0; i < out_width; i++ ) {
    nl_net in0_net;
    nl_net in1_net;
    nl_net out_net;

    int index = out_width - i - 1;

    ar_ref (in0_nets, i, &in0_net);
    ar_ref (in1_nets, i, &in1_net);
    ar_ref (out_nets, i, &out_net);

    if ( in0_net == force_0_net || in1_net == force_0_net ) {
      ast2g_connect_nets (out_net, zero_net, file, line);
    }
    else if ( in1_net == force_1_net || in1_net == force_1_net ) {
      ast2g_connect_nets (out_net, one_net, file, line);
    }
    else if ( in0_net == feedthru_net ) {
      ast2g_connect_nets (out_net, in1_net, file, line);
    }
    else if ( in1_net == feedthru_net ) {
      ast2g_connect_nets (out_net, in0_net, file, line);
    }
    else if ( in0_net == invert_net ) {
      ast2g_invert_net (in1_net, out_net, file, line, index);
    }
    else if ( in1_net == invert_net ) {
      ast2g_invert_net (in0_net, out_net, file, line, index);
    }
    else {
      nl_cell cell
	= ast2g_create_new_cell (NULL, reference, file, line, index);
      nl_pin in0_pin = nl_cell_get_pin_by_refpin (cell, in0_refpin);
      nl_pin in1_pin = nl_cell_get_pin_by_refpin (cell, in1_refpin);
      nl_pin out_pin = nl_cell_get_pin_by_refpin (cell, out_refpin);

      nl_pin_connect_net (in0_pin, in0_net);
      nl_pin_connect_net (in1_pin, in1_net);
      nl_pin_connect_net (out_pin, out_net);
    }
  }

  ar_free (in0_nets);
  ar_free (in1_nets);

  return out_nets;
}
#endif


#if 0
static
nl_reference
ast2g_get_arith_reference (nl_design design, char *op_name,
			   int in0_width, int in1_width, int out_width)
{
  int name_len = strlen (op_name);
  char *ref_name = alloca (name_len + 64);
  nl_reference ref;

  if ( out_width == 1 ) {
    sprintf (ref_name, "%s#(%d,%d)", op_name, in0_width, in1_width);
  }
  else {
    sprintf (ref_name, "%s#(%d,%d,%d)", op_name, in0_width, in1_width,
	     out_width);
  }

  ref = nl_design_get_reference_by_name (design, ref_name);

  if ( ref == NULL ) {
    nl_reference new_ref = ref = nl_reference_create (ref_name, design, NULL);
    nl_type scalar = nl_type_get_scalar (design);
    nl_type in0_type = nl_type_get_array (scalar, in0_width-1, 0);
    nl_bus in0_bus
      = nl_bus_create ("in0", in0_type, nl_kind_refpin, (nl_object) ref);
    nl_type in1_type = nl_type_get_array (scalar, in1_width-1, 0);
    nl_bus in1_bus
      = nl_bus_create ("in1", in1_type, nl_kind_refpin, (nl_object) ref);

    ast2g_fill_refpin_bus (in0_bus);
    ast2g_fill_refpin_bus (in1_bus);
    
    if ( out_width == 1 ) {
      nl_refpin_create ("out", NULL, ref);
    }
    else {
      nl_type out_type = nl_type_get_array (scalar, out_width-1, 0);
      nl_bus out_bus
	= nl_bus_create ("out", out_type, nl_kind_refpin, (nl_object) ref);

      ast2g_fill_refpin_bus (out_bus);
    }

    nl_reference_add_parameter (ref, in0_width);
    nl_reference_add_parameter (ref, in1_width);
    if ( out_width > 1 )
      nl_reference_add_parameter (ref, out_width);
  }

  return ref;
}
#endif


#if 0
static
nl_reference
ast2g_get_reduction_reference (nl_design design, char *op_name, int in_width)
{
  int name_len = strlen (op_name);
  char *ref_name = alloca (name_len + 32);
  nl_reference ref;

  sprintf (ref_name, "%s#(%d)", op_name, in_width);

  ref = nl_design_get_reference_by_name (design, ref_name);

  if ( ref == NULL ) {
    nl_reference new_ref = ref = nl_reference_create (ref_name, design, NULL);
    nl_type scalar = nl_type_get_scalar (design);
    nl_type in_type = nl_type_get_array (scalar, in_width-1, 0);
    nl_bus in_bus
      = nl_bus_create ("in", in_type, nl_kind_refpin, (nl_object) ref);

    ast2g_fill_refpin_bus (in_bus);

    nl_refpin_create ("out", NULL, ref);

    nl_reference_add_parameter (ref, in_width);
  }

  return ref;
}
#endif


static
ar
ast2g_addsub_op (char *op_name, ssa_context context, nl_design design,
		 nl_ast tree, ar inputs, ar outputs, char *file, int line)
{
  nl_ast in0_ast = nl_ast_child (tree);
  nl_ast in1_ast = nl_ast_sibling (in0_ast);
  ar in0_nets = ast2g_expression (context, design, in0_ast, inputs, outputs);
  ar in1_nets = ast2g_expression (context, design, in1_ast, inputs, outputs);
  int out_width = nl_ast_width (tree);
  ar out_nets = ast2g_create_new_bus (design, out_width, file, line);
  int adder_width = out_width;
  int has_cout = 0;

  {
    nl_net msb0_net;
    nl_net msb1_net;
    nl_net zero_net = nl_design_get_net_by_name (design, "1'b0");

    ar_ref (in0_nets, 0, &msb0_net);
    ar_ref (in1_nets, 0, &msb1_net);

    if ( msb0_net == zero_net && msb1_net == zero_net ) {
      adder_width--;
      has_cout = 1;
    }
  }

  ast2g_op_count++;
  
  {
    nl_reference ref
      = ast2g_get_parameterized_ref (design, op_name, adder_width, -1,
				     "in0", adder_width, "in1", adder_width,
				     "out", adder_width, "cout", 0, NULL);
    nl_cell cell = ast2g_create_new_cell (op_name, ref, file, line, -1);
    nl_bus in0_refpin_bus 
      = (nl_bus) nl_reference_get_refpin_by_name (ref, "in0");
    nl_bus in1_refpin_bus
      = (nl_bus) nl_reference_get_refpin_by_name (ref, "in1");
    nl_bus out_refpin_bus
      = (nl_bus) nl_reference_get_refpin_by_name (ref, "out");

    ast2g_connect_pin_bus (cell, in0_refpin_bus, in0_nets, has_cout);
    ast2g_connect_pin_bus (cell, in1_refpin_bus, in1_nets, has_cout);
    ast2g_connect_pin_bus (cell, out_refpin_bus, out_nets, has_cout);

    if ( has_cout ) {
      nl_refpin cout_refpin
	= (nl_refpin) nl_reference_get_refpin_by_name (ref, "cout");
      nl_pin cout_pin = nl_cell_get_pin_by_refpin (cell, cout_refpin);
      nl_net cout_net;

      ar_ref (out_nets, 0, &cout_net);
      nl_pin_connect_net (cout_pin, cout_net);
    }
  }

  return out_nets;
}


static
ar
ast2g_relational_op (char *op_name, ssa_context context, nl_design design,
		     nl_ast tree, int swap, ar inputs, ar outputs,
		     char *file, int line)
{
  nl_ast child_0 = nl_ast_child (tree);
  nl_ast child_1 = nl_ast_sibling (child_0);
  nl_ast in0_ast = swap ? child_1 : child_0;
  nl_ast in1_ast = swap ? child_0 : child_1;
  ar in0_nets = ast2g_expression (context, design, in0_ast, inputs, outputs);
  ar in1_nets = ast2g_expression (context, design, in1_ast, inputs, outputs);
  int in0_width = ar_size (in0_nets);
  int in1_width = ar_size (in1_nets);
  int out_width = nl_ast_width (tree);
  nl_reference reference
    = ast2g_get_parameterized_ref (design, op_name, in0_width, -1,
				   "in0", in0_width, "in1", in0_width,
				   "out", 0, NULL);
  nl_bus in0_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "in0");
  nl_bus in1_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "in1");
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "out");
  int dummy UNUSED = ast2g_op_count++;
  nl_cell cell = ast2g_create_new_cell (op_name, reference, file, line, -1);
  nl_net out_net = ast2g_create_new_net (design, file, line);
  ar out_nets = ar_alloc (1, sizeof (nl_net));
  nl_pin out_pin;

  ASSERT (nl_bus_kind (in0_refpin_bus) == nl_kind_bus);
  ASSERT (nl_bus_kind (in1_refpin_bus) == nl_kind_bus);
  ASSERT (nl_refpin_kind (out_refpin) == nl_kind_refpin);
  /* The following condition is guaranteed by type balancing. */
  ASSERT (in0_width == in1_width);
  ASSERT (out_width == 1);

  ast2g_connect_pin_bus (cell, in0_refpin_bus, in0_nets, 0);
  ast2g_connect_pin_bus (cell, in1_refpin_bus, in1_nets, 0);

  out_pin = nl_cell_get_pin_by_refpin (cell, (nl_refpin) out_refpin);
  nl_pin_connect_net (out_pin, out_net);
  ar_add (out_nets, &out_net);

  ar_free (in0_nets);
  ar_free (in1_nets);

  return out_nets;
}


static
ar
ast2g_cond_op (ssa_context context, nl_design design, nl_ast tree,
	       ar inputs, ar outputs, char *file, int line)
{
  nl_ast test_ast = nl_ast_child (tree);
  nl_ast then_ast = nl_ast_sibling (test_ast);
  nl_ast else_ast = nl_ast_sibling (then_ast);
  ar test_nets = ast2g_expression (context, design, test_ast, inputs, outputs);
  ar then_nets = ast2g_expression (context, design, then_ast, inputs, outputs);
  ar else_nets = ast2g_expression (context, design, else_ast, inputs, outputs);
  int test_width = ar_size (test_nets);
  int then_width = ar_size (then_nets);
  int else_width = ar_size (else_nets);
  int out_width = then_width;
  nl_reference reference
    = ast2g_get_parameterized_ref (design, "JNPR_MUX2", out_width, -1,
				   "in0", out_width, "in1", out_width,
				   "sel", 1, "out", out_width, NULL);
  nl_bus in0_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "in0");
  nl_bus in1_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "in1");
  nl_bus sel_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "sel");
  nl_bus out_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "out");
  ar out_nets;

  ASSERT (test_width == 1);
  ASSERT (then_width == else_width);

  ASSERT (nl_bus_kind (in0_refpin_bus) == nl_kind_bus);
  ASSERT (nl_bus_kind (in1_refpin_bus) == nl_kind_bus);
  ASSERT (nl_bus_kind (out_refpin_bus) == nl_kind_bus);
  ASSERT (nl_bus_kind (sel_refpin_bus) == nl_kind_bus);

  if ( out_width > 1 ) {
    out_nets = ast2g_create_new_bus (design, out_width, file, line);
  }
  else {
    nl_net out_net = ast2g_create_new_net (design, file, line);

    ASSERT (out_width == 1);

    out_nets = ar_alloc (1, sizeof (nl_net));
    ar_add (out_nets, &out_net);
  }

  ast2g_op_count++;

  {
    nl_cell cell
      = ast2g_create_new_cell ("JNPR_MUX2", reference, file, line, -1);

    ast2g_connect_pin_bus (cell, sel_refpin_bus, test_nets, 0);
    ast2g_connect_pin_bus (cell, in0_refpin_bus, else_nets, 0);
    ast2g_connect_pin_bus (cell, in1_refpin_bus, then_nets, 0);
    ast2g_connect_pin_bus (cell, out_refpin_bus, out_nets, 0);
  }

  ar_free (test_nets);
  ar_free (then_nets);
  ar_free (else_nets);

  return out_nets;
}


static
ar
ast2g_reduction_op (char *op_name, ssa_context context, nl_design design,
		    nl_ast tree, ar inputs, ar outputs, char *file, int line)
{
  nl_ast arg = nl_ast_child (tree);
  ar in_nets = ast2g_expression (context, design, arg, inputs, outputs);
  int in_width = ar_size (in_nets);
  nl_reference reference
    = ast2g_get_parameterized_ref (design, op_name, in_width, -1,
				   "in", in_width, "out", 0, NULL);
  nl_bus in_refpin_bus
    = (nl_bus) nl_reference_get_refpin_by_name (reference, "in");
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (reference, "out");
  nl_net out_net = ast2g_create_new_net (design, file, line);
  ar out_nets = ar_alloc (1, sizeof (nl_net));
  int dummy UNUSED = ast2g_op_count++;
  nl_cell cell = ast2g_create_new_cell (op_name, reference, file, line, -1);

  ASSERT (nl_bus_kind (in_refpin_bus) == nl_kind_bus);
  ASSERT (nl_refpin_kind (out_refpin) == nl_kind_refpin);

  ast2g_connect_pin_bus (cell, in_refpin_bus, in_nets, 0);

  {
    nl_pin out_pin = nl_cell_get_pin_by_refpin (cell, out_refpin);

    nl_pin_connect_net (out_pin, out_net);
    ar_add (out_nets, &out_net);
  }

  ar_free (in_nets);

  return out_nets;

#if 0
  if ( force_0 != NULL ) {
    nl_net force_0_net = ast2g_get_net (NULL, design, force_0);

    ar_for_all (in_nets, nl_net, in_net) {
      if ( in_net == force_0_net ) {
	nl_net zero_net = ast2g_get_net (NULL, design, "1'b0");
	asg2g_connect_nets (out_net, zero_net, file, line);
	goto finished;
      }
    } ar_end_for;
  }

  if ( force_1 != NULL ) {
    nl_net force_1_net = ast2g_get_net (NULL, design, force_1);

    ar_for_all (in_nets, nl_net, in_net) {
      if ( in_net == force_1_net ) {
	nl_net one_net = ast2g_get_net (NULL, design, "1'b1");
	asg2g_connect_nets (out_net, one_net, file, line);
	goto finished;
      }
    } ar_end_for;
  }

  if ( feedthru != NULL || invert != NULL ) {
    int size = ar_size (in_nets);
    nl_net feedthru_net = NULL;
    nl_net invert_net = NULL;
    int j;

    if ( feedthru != NULL ) 
      feedthru_net = ast2g_get_net (NULL, design, feedthru);

    if ( invert != NULL )
      invert_net = ast2g_get_net (NULL, design, invert);

    j = 0;
    for ( i = 0; i < size; i++ ) {
      nl_net net_i;

      ar_ref (in_nets, i, &net_i);

      if ( net_i == feedthru_net ) {
      }
      else if ( net_i == invert_net ) {
	invert_output = !invert_output;
      }
      else {
	if ( i > j ) {
	  ar_set (in_nets, j, &net);
	  j++;
	}
      }
    }
    /* not finished */
  }
#endif
}


ar
ast2g_integer (nl_design design, int n)
{
  int i;
  ar result = AR_NEW (32, nl_net);
  unsigned int x = n;
  nl_net zero = ast2g_get_net (NULL, design, "1'b0");
  nl_net one = ast2g_get_net (NULL, design, "1'b1");

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


static
ar
ast2g_map_to_module (nl_design design, nl_subprogram fun, ar actual_nets,
		     char *file, int line)
{
  char *fun_name = nl_subprogram_name (fun);
  nl_ast pragmas = nl_subprogram_pragmas (fun);
  nl_ast pragma = pragmas;
  char *mod_name = NULL;
  char *out_name = NULL;
  nl_reference reference;
  nl_cell cell;
  int which_arg;

  while ( pragma != NULL ) {
    nl_token prag_tok = nl_ast_token (pragma);

    if ( prag_tok == nl_token_map_to_module ) {
      nl_id_ast child = (nl_id_ast) nl_ast_child (pragma);

      ASSERT (nl_id_ast_token (child) == nl_token_id);

      mod_name = nl_id_ast_name (child);
    }
    else if ( prag_tok == nl_token_return_port_name ) {
      nl_id_ast child = (nl_id_ast) nl_ast_child (pragma);

      ASSERT (nl_id_ast_token (child) == nl_token_id);

      out_name = nl_id_ast_name (child);
    }

    pragma = nl_ast_sibling (pragma);
  }

  ASSERT (mod_name != NULL);

  if ( out_name == NULL ) {
    ast2g_ast_error (pragmas, "function with map_to_module pragma is missing "
		     "return_port_name pragma");
  }

  reference = nl_design_get_reference_by_name (design, mod_name);

  if ( reference == NULL ) {
    reference = ast2g_build_reference_for_function (fun, mod_name, out_name);
  }

  cell = ast2g_create_new_cell (fun_name, reference, file, line, -1);

  ast2g_op_count++;

  which_arg = 0;

  nl_subprogram_for_all_formals (fun, formal) {
    char *name = nl_symbol_name (formal);
    nl_type formal_type = nl_symbol_type (formal);
    nl_object refpin_obj = nl_reference_get_refpin_by_name (reference, name);
    nl_kind refpin_kind;
    ar arg_nets;

    if ( refpin_obj == NULL ) {
      ast2g_ast_error (pragmas, "reference referred to by map_to_module "
		       "function is missing port %s", name);
    }

    ar_ref (actual_nets, which_arg, &arg_nets);
    refpin_kind = nl_object_kind (refpin_obj);

    if ( refpin_kind == nl_kind_refpin ) {
      nl_typeclass formal_class = nl_type_class (formal_type);

      if ( formal_class != nl_typeclass_scalar ) {
	ast2g_ast_error (pragmas, "type of map_to_module function argument "
			 "'%s' does not match that of the port on reference "
			 "'%s'", name, mod_name);
      }
      else {
	nl_refpin refpin = (nl_refpin) refpin_obj;
	nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
	nl_net arg_net;
      
	ASSERT (ar_size (arg_nets) == 1);
	
	ar_ref (arg_nets, 0, &arg_net);

	nl_pin_connect_net (pin, arg_net);
      }
    }
    else if ( refpin_kind == nl_kind_bus ) {
      nl_bus refpin_bus = (nl_bus) refpin_obj;
      nl_type bus_type = nl_bus_type (refpin_bus);

      if ( bus_type != formal_type ) {
	ast2g_ast_error (pragmas, "type of map_to_module function argument "
			 "'%s' does not match that of the port on reference "
			 "'%s'", name, mod_name);
      }

      ast2g_connect_pin_bus (cell, refpin_bus, arg_nets, 0);
    }
    else {
      ASSERT (0);
    }

    which_arg++;
  } nl_end_for;

  {
    nl_object out_refpin_obj
      = nl_reference_get_refpin_by_name (reference, out_name);
    nl_kind out_refpin_kind;
    nl_type out_type = nl_subprogram_type (fun);

    if ( out_refpin_obj == NULL ) {
      ast2g_ast_error (pragmas, "reference referred to by map_to_module "
		       "function is missing return port %s", out_name);
    }

    out_refpin_kind = nl_object_kind (out_refpin_obj);

    if ( out_refpin_kind == nl_kind_refpin ) {
      nl_refpin out_refpin = (nl_refpin) out_refpin_obj;
      nl_pin pin = nl_cell_get_pin_by_refpin (cell, out_refpin);
      nl_net net = ast2g_create_new_net (design, file, line);
      ar out_nets = ar_alloc (1, sizeof (nl_net));

      if ( nl_type_class (out_type) != nl_typeclass_scalar ) {
	ast2g_ast_error (pragmas, "return type of map_to_module function '%s' "
			 "does not match the type of port '%s' on reference "
			 "'%s'", fun_name, out_name, mod_name);
      }
      
      nl_pin_connect_net (pin, net);
      ar_add (out_nets, &net);

      return out_nets;
    }
    else if ( out_refpin_kind == nl_kind_bus ) {
      nl_bus out_refpin_bus = (nl_bus) out_refpin_obj;
      nl_type bus_type = nl_bus_type (out_refpin_bus);
      int width = nl_type_width (bus_type);
      ar out_nets;

      if ( bus_type != out_type ) {
	ast2g_ast_error (pragmas, "return type of map_to_module function '%s' "
			 "does not match the type of port '%s' on reference "
			 "'%s'", fun_name, out_name, mod_name);
      }

      out_nets = ast2g_create_new_bus (design, width, file, line);
      ast2g_connect_pin_bus (cell, out_refpin_bus, out_nets, 0);

      return out_nets;
    }
    else {
      ASSERT (0);
    }
  }
}


static
ar
ast2g_function_call (ssa_context context, nl_design design, nl_ast tree,
		     ar inputs, ar outputs, char *file, int line)
{
  nl_ref_ast ref_ast = (nl_ref_ast) nl_ast_child (tree);
  nl_ast args = nl_ref_ast_sibling (ref_ast);
  nl_object obj = nl_ref_ast_object (ref_ast);
  nl_subprogram fun = (nl_subprogram) obj;
  nl_type type = nl_subprogram_type (fun);
  int output_width = nl_type_width (type);
  ar nets;
  nl_ast pragmas = nl_subprogram_pragmas (fun);
  int num_args = nl_subprogram_num_formals (fun);
  ar actual_nets = ar_alloc (num_args, sizeof (ar));

  ASSERT (nl_object_kind (obj) == nl_kind_subprogram);
  
  /* Step 0. Eval all the arguments. */
  while ( args != NULL ) {
    ar arg_nets = ast2g_expression (context, design, args, inputs, outputs);

    ar_add (actual_nets, &arg_nets);
    args = nl_ast_sibling (args);
  }

  /* Step 0.5. See if the function has a map_to_module pragma. */
  while ( pragmas != NULL ) {
    nl_token prag_tok = nl_ast_token (pragmas);

    if ( prag_tok == nl_token_map_to_module ) {
      nets = ast2g_map_to_module (design, fun, actual_nets, file, line);
      goto done;
    }

    pragmas = nl_ast_sibling (pragmas);
  }

  /* If we fall through to here, it means we didn't see map_to_module. */
  nets = ar_alloc (output_width, sizeof (nl_net));

  /* Step 1. Bind the formal parameters. */
  {
    int which_arg = 0;

    nl_subprogram_for_all_formals (fun, formal) {
      ar form_syms = nl_symbol_constituents (formal);
      ar arg_nets;
      int arg_width;

      ar_ref (actual_nets, which_arg, &arg_nets);
      arg_width = ar_size (arg_nets);
      which_arg++;

      if ( form_syms != NULL ) {
	ar_for_all_indexed (form_syms, nl_symbol, form_sym, i) {
	  nl_net arg_net;

	  ar_ref (arg_nets, arg_width-i-1, &arg_net);

	  ast2g_define (context, (nl_object) form_sym, arg_net);
	} ar_end_for;
      }
      else {
	nl_net arg_net;

	ar_ref (arg_nets, arg_width-1, &arg_net);
	
	ast2g_define (context, (nl_object) formal, arg_net);
      }
    } nl_end_for;
  }

  /* Step 2. Eval the function body. */
  {
    nl_ast body = nl_subprogram_body (fun);

    ast2g_statement (context, design, body, NULL, NULL);
  }

  /* Step 3. Get the result. */
  {
    char *name = nl_subprogram_name (fun);
    nl_symbol fun_sym = nl_subprogram_get_symbol_by_name (fun, name);

    if ( nl_type_class (type) == nl_typeclass_scalar ) {
      nl_net net = ast2g_read (context, (nl_object) fun_sym);

      if ( net == NULL ) {
	nl_ast body = nl_subprogram_body (fun);
	ast2g_ast_error (body, "function body fails to define function "
			 "return value.");
      }

      ar_add (nets, &net);
      ssa_unbind (context, fun_sym);
    }
    else {
      ar fun_syms = nl_symbol_constituents (fun_sym);

      ar_for_all (fun_syms, nl_symbol, sym) {
	nl_net net = ast2g_read (context, (nl_object) sym);

	if ( net == NULL ) {
	  nl_ast body = nl_subprogram_body (fun);
	  ast2g_ast_error (body, "function body fails to define function "
			   "return value.");
	}

	ar_add (nets, &net);
	ssa_unbind (context, sym);
      } ar_end_for;
    }
  }

  /* Step 4. Unbind all the formals. */
  nl_subprogram_for_all_formals (fun, formal) {
    ar form_syms = nl_symbol_constituents (formal);

    if ( form_syms != NULL ) {
      ar_for_all (form_syms, nl_symbol, form_sym) {
	ssa_unbind (context, form_sym);
      } ar_end_for;
    }
    else {
      ssa_unbind (context, formal);
    }
  } nl_end_for;

  /* Step 5. Unbind the locals. */
  nl_subprogram_for_all_locals (fun, local) {
    ar loc_syms = nl_symbol_constituents (local);

    if ( loc_syms != NULL ) {
      ar_for_all (loc_syms, nl_symbol, loc_sym) {
	ssa_unbind (context, loc_sym);
      } ar_end_for;
    }
    else {
      ssa_unbind (context, local);
    }
  } nl_end_for;

 done:
  ar_for_all (actual_nets, ar, nets) {
    ar_free (nets);
  } ar_end_for;
  ar_free (actual_nets);

  return nets;
}


static
ar
ast2g_shift_op (char *op_name, ssa_context context, nl_design design,
		nl_ast tree, ar inputs, ar outputs, char *file, int line)
{
  nl_ast in_ast = nl_ast_child (tree);
  nl_ast sh_ast = nl_ast_sibling (in_ast);
  ar in_nets = ast2g_expression (context, design, in_ast, inputs, outputs);
  ar sh_nets = ast2g_expression (context, design, sh_ast, inputs, outputs);
  int in_width = ar_size (in_nets);
  int sh_width = ar_size (sh_nets);
  int out_width = nl_ast_width (tree);
  ar out_nets = ast2g_create_new_bus (design, out_width, file, line);

  ast2g_op_count++;
  
  {
    nl_reference ref
      = ast2g_get_parameterized_ref (design, op_name, in_width, sh_width,
				     out_width, -1, "in", in_width,
				     "sh", sh_width, "out", out_width, NULL);
    nl_cell cell = ast2g_create_new_cell (op_name, ref, file, line, -1);
    nl_bus in_refpin_bus 
      = (nl_bus) nl_reference_get_refpin_by_name (ref, "in");
    nl_bus sh_refpin_bus
      = (nl_bus) nl_reference_get_refpin_by_name (ref, "sh");
    nl_bus out_refpin_bus
      = (nl_bus) nl_reference_get_refpin_by_name (ref, "out");

    ast2g_connect_pin_bus (cell, in_refpin_bus, in_nets, 0);
    ast2g_connect_pin_bus (cell, sh_refpin_bus, sh_nets, 0);
    ast2g_connect_pin_bus (cell, out_refpin_bus, out_nets, 0);
  }

  return out_nets;
}


ar
ast2g_expression (ssa_context context, nl_design design,
		  nl_ast tree, ar inputs, ar outputs)
{
  nl_token token = nl_ast_token (tree);
  char *file = nl_ast_file (tree);
  int line = nl_ast_line (tree);

  switch ( token ) {

  case nl_token_number: {
    nl_number_ast num_ast = (nl_number_ast) tree;
    int n = nl_number_ast_value (num_ast);
    ar result = ast2g_integer (design, n);
    return result;
  }

  case nl_token_bin: {
    ar result = ast2g_verilog_number (design, 'b', tree);
    return result;
  }

  case nl_token_hex: {
    ar result = ast2g_verilog_number (design, 'h', tree);
    return result;
  }

  case nl_token_dec: {
    ar result = ast2g_verilog_number (design, 'd', tree);
    return result;
  }

  case nl_token_oct: {
    ar result = ast2g_verilog_number (design, 'o', tree);
    return result;
  }

  case nl_token_in: {
    nl_in_ast in_ast = (nl_in_ast) tree;
    int index = nl_in_ast_index (in_ast);
    nl_pin pin;
    nl_net net;
    ar result;

    ASSERT (inputs != NULL);
    ar_ref (inputs, index, &pin);
    net = nl_pin_net (pin);
    result = ar_alloc (1, sizeof (nl_net));
    ar_add (result, &net);

    return result;
  }

  case nl_token_out: {
    nl_out_ast out_ast = (nl_out_ast) tree;
    int index = nl_out_ast_index (out_ast);
    nl_pin pin;
    nl_net net;
    ar result = ar_alloc (1, sizeof (nl_net));

    ASSERT (outputs != NULL);

    ar_ref (outputs, index, &pin);
    net = nl_pin_net (pin);

    if ( context != NULL ) {
      nl_net value = ast2g_read (context, (nl_object) net);

      ASSERT (value != NULL);

      ar_add (result, &value);
    }
    else {
      ar_add (result, &net);
    }

    return result;
  }

  case nl_token_ref: {
    nl_ref_ast ref_ast = (nl_ref_ast) tree;
    nl_object obj = nl_ref_ast_object (ref_ast);
    nl_symbol sym = (nl_symbol) obj;
    nl_net net = ast2g_read (context, (nl_object) sym);
    ar result = ar_alloc (1, sizeof (nl_net));

    if ( net == NULL ) {
      ast2g_ast_error (tree, "Reference to free variable: %s",
		       nl_symbol_name (sym));
    }

    ASSERT (nl_object_kind (obj) == nl_kind_symbol);

    ar_add (result, &net);

    return result;
  }

  case nl_token_lref: {
    nl_ref_ast ref_ast = (nl_ref_ast) tree;
    nl_object obj = nl_ref_ast_object (ref_ast);
    ar result = ar_alloc (1, sizeof (nl_net));

    ASSERT (nl_object_kind (obj) == nl_kind_symbol);

    ar_add (result, &obj);

    return result;
  }

  case nl_token_concat: {
    ar result = ast2g_concat (context, design, tree, inputs, outputs);
    return result;
  }

  case nl_token_repeat_concat: {
    ar result = ast2g_repeat_concat (context, design, tree, inputs, outputs);
    return result;
  }

  case nl_token_bitnot: {
    nl_ast arg = nl_ast_child (tree);
    ar in_nets = ast2g_expression (context, design, arg, inputs, outputs);
    ar result = ast2g_invert_nets (design, in_nets, file, line);

    ar_free (in_nets);
    return result;
  }

  case nl_token_and: {
    ar result = ast2g_binary_op ("JNPR_AND2", context, design, tree,
				 inputs, outputs, "1'b0", NULL, "1'b1", NULL,
				 file, line);
    return result;
  }
    
  case nl_token_or: {
    ar result = ast2g_binary_op ("JNPR_OR2", context, design, tree,
				 inputs, outputs, NULL, "1'b1", "1'b0", NULL,
				 file, line);
    return result;
  }

  case nl_token_xor: {
    ar result = ast2g_binary_op ("JNPR_XOR2", context, design, tree,
				 inputs, outputs, NULL, NULL, "1'b0", "1'b1",
				 file, line);
    return result;
  }

  case nl_token_nand: {
    ar result = ast2g_binary_op ("JNPR_NAND2", context, design, tree,
				 inputs, outputs, NULL, "1'b0", NULL, "1'b1",
				 file, line);
    return result;
  }
    
  case nl_token_nor: {
    ar result = ast2g_binary_op ("JNPR_NOR2", context, design, tree,
				 inputs, outputs, "1'b1", NULL, NULL, "1'b0",
				 file, line);
    return result;
  }

  case nl_token_xnor: {
    ar result = ast2g_binary_op ("JNPR_XNOR2", context, design, tree,
				 inputs, outputs, NULL, NULL, "1'b1", "1'b0",
				 file, line);
    return result;
  }

  case nl_token_cond: {
    ar result = ast2g_cond_op (context, design, tree, inputs, outputs,
			       file, line);
    return result;
  }

  case nl_token_add: {
    ar result = ast2g_addsub_op ("JNPR_ADD", context, design, tree,
				 inputs, outputs, file, line);
    return result;
  }

  case nl_token_sub: {
    ar result = ast2g_addsub_op ("JNPR_SUB", context, design, tree,
				 inputs, outputs, file, line);
    return result;
  }

  case nl_token_gt: {
    ar result = ast2g_relational_op ("JNPR_GT", context, design, tree, 0,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_geq: {
    ar result = ast2g_relational_op ("JNPR_GTE", context, design, tree, 0,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_lt: {
    ar result = ast2g_relational_op ("JNPR_GT", context, design, tree, 1,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_leq: {
    ar result = ast2g_relational_op ("JNPR_GTE", context, design, tree, 1,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_eq2: {
    ar result = ast2g_relational_op ("JNPR_EQ", context, design, tree, 0,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_neq: {
    ar result = ast2g_relational_op ("JNPR_NEQ", context, design, tree, 0,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_and_reduce: {
    ar result = ast2g_reduction_op ("JNPR_ANDn", context, design, tree,
				    inputs, outputs, file, line);
    return result;
  }

  case nl_token_nand_reduce: {
    ar result = ast2g_reduction_op ("JNPR_NANDn", context, design, tree,
				    inputs, outputs, file, line);
    return result;
  }

  case nl_token_or_reduce: {
    ar result = ast2g_reduction_op ("JNPR_ORn", context, design, tree,
				    inputs, outputs, file, line);
    return result;
  }

  case nl_token_nor_reduce: {
    ar result = ast2g_reduction_op ("JNPR_NORn", context, design, tree,
				    inputs, outputs, file, line);
    return result;
  }

  case nl_token_xor_reduce: {
    ar result = ast2g_reduction_op ("JNPR_XORn", context, design, tree,
				    inputs, outputs, file, line);
    return result;
  }

  case nl_token_xnor_reduce: {
    ar result = ast2g_reduction_op ("JNPR_XNORn", context, design, tree,
				    inputs, outputs, file, line);
    return result;
  }

  case nl_token_funcall: {
    ar result = ast2g_function_call (context, design, tree,
				     inputs, outputs, file, line);
    return result;
  }

  case nl_token_posedge: {
    ar result = ast2g_unary_op ("*POSEDGE*", context, design, tree,
				inputs, outputs, file, line);
    return result;
  }

  case nl_token_negedge: {
    ar result = ast2g_unary_op ("*NEGEDGE*", context, design, tree,
				inputs, outputs, file, line);
    return result;
  }

  case nl_token_varshl: {
    ar result = ast2g_shift_op ("JNPR_SHIFT_LEFT", context, design, tree,
				inputs, outputs, file, line);
    return result;
  }

  case nl_token_varshr: {
    ar result = ast2g_shift_op ("JNPR_SHIFT_RIGHT", context, design, tree,
				inputs, outputs, file, line);
    return result;
  }

  default:
    ASSERT (0);
  }
}
