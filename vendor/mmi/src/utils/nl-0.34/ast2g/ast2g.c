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
#include "v2nl.h"
#include "namegen.h"


void
ast2g_assign (nl_design design, ar lhs, ar rhs, char *file, int line)
{
  static int assignment_num = 1000;
  nl_reference ref = ast2g_get_reference (design, "*assignment*",
					  "in", "out", NULL);
  char cell_name[64];
  nl_refpin in_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (ref, "in");
  nl_refpin out_refpin
    = (nl_refpin) nl_reference_get_refpin_by_name (ref, "out");
  int rhs_width = ar_size (rhs);
  int lhs_width = ar_size (lhs);
  int i;

  ASSERT (rhs_width >= lhs_width);

  for ( i = 0; i < lhs_width; i++ ) {
    int rhs_index = rhs_width - lhs_width + i;
    nl_net lhs_net;
    nl_net rhs_net;
    nl_cell assign_cell;
    nl_pin in_pin;
    nl_pin out_pin;

    sprintf (cell_name, "*assignment_%d*", assignment_num);
    assignment_num++;

    assign_cell = nl_cell_create (cell_name, ref);

    nl_cell_set_file_line (assign_cell, file, line);

    ar_ref (rhs, rhs_index, &rhs_net);
    ar_ref (lhs, i, &lhs_net);

    in_pin = nl_cell_get_pin_by_refpin (assign_cell, in_refpin);
    out_pin = nl_cell_get_pin_by_refpin (assign_cell, out_refpin);

    nl_pin_connect_net (in_pin, rhs_net);
    nl_pin_connect_net (out_pin, lhs_net);
  }
}


static
ssa_binding
ast2g_var_get (void *var, void *ptr)
{
  nl_object obj = (nl_object) var;
  nl_kind kind = nl_object_kind (obj);
  ssa_binding binding;

  if ( kind == nl_kind_net ) {
    nl_net net = (nl_net) obj;
    nl_net_attr net_attr = (nl_net_attr) ptr;

    nl_net_attr_get (net_attr, net, &binding);
  }
  else if ( kind == nl_kind_symbol ) {
    nl_symbol sym = (nl_symbol) obj;

    binding = (ssa_binding) nl_symbol_binding (sym);
  }
  else {
    ASSERT (0);
  }

  return binding;
}

  
static
void
ast2g_var_set (void *var, ssa_binding binding, void *ptr)
{
  nl_object obj = (nl_object) var;
  nl_kind kind = nl_object_kind (obj);

  if ( kind == nl_kind_net ) {
    nl_net net = (nl_net) obj;
    nl_net_attr net_attr = (nl_net_attr) ptr;

    nl_net_attr_set (net_attr, net, &binding);
  }
  else if ( kind == nl_kind_symbol ) {
    nl_symbol sym = (nl_symbol) obj;

    nl_symbol_set_binding (sym, binding);
  }
  else {
    ASSERT (0);
  }
}
  

static
void
ast2g_translate_expression (nl_design design, nl_ast tree,
			    ar inputs, ar outputs, char *file, int line)
{
  nl_net_attr net_attr
    = nl_net_attr_create (NULL, design, nl_density_sparse,
			  sizeof (ssa_binding), NULL, NULL);
  ssa_global global
    = ssa_global_create (ast2g_var_get, ast2g_var_set, net_attr);
  ssa_context context = ssa_context_create (NULL, NULL, global);
  ar rhs_nets = ast2g_expression (context, design, tree, inputs, outputs);
  int num_outs = ar_size (outputs);
  ar lhs_nets = ar_alloc (num_outs, sizeof (nl_net));

  ar_for_all (outputs, nl_pin, out_pin) {
    nl_net out_net = nl_pin_net (out_pin);
    ar_add (lhs_nets, &out_net);
  } ar_end_for;

  ast2g_assign (design, lhs_nets, rhs_nets, file, line);

  ar_free (rhs_nets);
  ar_free (lhs_nets);

  nl_design_remove_attr (design, (nl_attr) net_attr);
  ssa_context_free (context);
  ssa_global_free (global);
}


static
void
ast2g_translate_process (nl_design design, nl_ast tree, ar inputs, ar outputs)
{
  nl_net_attr net_attr
    = nl_net_attr_create (NULL, design, nl_density_sparse,
			  sizeof (ssa_binding), NULL, NULL);
  ssa_global global
    = ssa_global_create (ast2g_var_get, ast2g_var_set, net_attr);
  ssa_context context = ssa_context_create (NULL, NULL, global);
  nl_ast sens_ast = nl_ast_child (tree);
  nl_ast body_ast = nl_ast_sibling (sens_ast);
  char *file = nl_ast_file (tree);
  int line = nl_ast_line (tree);
  nl_net clks[2];
  nl_token clk_edges[2];
  ar out_nets = ar_alloc (ar_size (outputs), sizeof (nl_net));
  ar d_nets = ar_alloc (ar_size (outputs), sizeof (nl_net));
  ar reset_nets;
  ar reset_levels;
  ar presets;

  ast2g_statement (context, design, body_ast, inputs, outputs);
  ast2g_get_clocks (sens_ast, clks, clk_edges, inputs);

  ar_for_all (outputs, nl_pin, out_pin) {
    nl_net out_net = nl_pin_net (out_pin);
    int num_pins = nl_net_num_pins (out_net);

    if ( num_pins > 1 ) {
      nl_net value_net = ast2g_read_final (context, (nl_object) out_net);

      ASSERT (value_net != NULL);
      ar_add (d_nets, &value_net);
      ar_add (out_nets, &out_net);
    }
  } ar_end_for;

  if ( clks[0] != NULL ) {
    int num_d_nets = ar_size (d_nets);
    ar new_d_nets = ar_alloc (num_d_nets, sizeof (nl_net));

    reset_nets = ar_alloc (num_d_nets, sizeof (nl_net));
    presets = ar_alloc (num_d_nets, sizeof (nl_net));
    reset_levels = ar_alloc (num_d_nets, sizeof (nl_net));

    ast2g_find_reset_preset (design, d_nets, new_d_nets, reset_nets,
			     reset_levels, presets);

    ar_free (d_nets);
    d_nets = new_d_nets;
  }
  else {
    reset_nets = NULL;
    reset_levels = NULL;
    presets = NULL;
  }

  ar_for_all_indexed (out_nets, nl_net, out_net, index) {
    nl_net d_net;

    ar_ref (d_nets, index, &d_net);

    if ( clks[0] == NULL ) {
      ast2g_connect_nets (out_net, d_net, file, line);
    }
    else {
      nl_net reset_net;
      int is_preset;
      int reset_level;

      ar_ref (reset_nets, index, &reset_net);
      ar_ref (presets, index, &is_preset);
      ar_ref (reset_levels, index, &reset_level);

      if ( clks[1] == NULL ) {
	nl_token reset_tok;

	if ( reset_level == 0 ) {
	  reset_tok = nl_token_bitnot;
	}
	else {
	  reset_tok = nl_token_null;
	}

	ast2g_register_net (out_net, d_net, clks[0], clk_edges[0],
			    reset_net, reset_tok, is_preset, file, line);
      }
      else if ( reset_net == NULL ) {
	ast2g_ast_error (sens_ast, "malformed reset: could not find reset "
			 "for %s or %s", nl_net_name (clks[0]),
			 nl_net_name (clks[1]));
      }
      else {
	nl_net clk_net;
	nl_token clk_edge;
	nl_token reset_edge;

	if ( reset_net == clks[0] ) {
	  reset_edge = clk_edges[0];
	  clk_net = clks[1];
	  clk_edge = clk_edges[1];
	}
	else if ( reset_net == clks[1] ) {
	  reset_edge = clk_edges[1];
	  clk_net = clks[0];
	  clk_edge = clk_edges[0];
	}
	else {
	  ast2g_ast_error (sens_ast, "malformed reset: could not find %s "
			   "among %s and %s", nl_net_name (reset_net),
			   nl_net_name (clks[0]), nl_net_name (clks[1]));
	}
	
	ast2g_register_net (out_net, d_net, clk_net, clk_edge,
			    reset_net, reset_edge, is_preset, file, line);
      }
    }
  } ar_end_for;

  ar_free (d_nets);

  if ( reset_nets != NULL ) {
    ar_free (reset_nets);
    ar_free (reset_levels);
    ar_free (presets);
  }

  nl_design_remove_attr (design, (nl_attr) net_attr);
  ssa_context_free (context);
  ssa_global_free (global);
}


static
nl_ast
ast2g_apply_rewrites_to_tree (nl_ast tree)
{
  tree = ast2g_eliminate_logical_ops (tree);

  ast2g_update_widths (tree);
  tree = ast2g_simplify_reduce_ops (tree);

  tree = ast2g_flip_cases (tree);

  tree = ast2g_flatten_concats (tree);

  tree = ast2g_infer_inverting_ops (tree);

  tree = ast2g_flatten_logic_trees (tree);

  ast2g_update_widths (tree);

  return tree;
}


void
ast2g_apply_rewrites_to_design (nl_design design)
{
  nl_design_for_all_references (design, reference) {
    char *ref_name = nl_reference_name (reference);

    if ( strncmp (ref_name, "*expression", 11) == 0 ) {
      nl_ast tree = nl_reference_tree (reference);
      int lhs_width = nl_reference_output_width (reference);

      tree = ast2g_type_balance_expression (lhs_width, tree);
      tree = ast2g_apply_rewrites_to_tree (tree);

      nl_reference_set_tree (reference, tree);
    }
    else if ( strncmp (ref_name, "*process", 8) == 0 ) {
      nl_ast tree = nl_reference_tree (reference);

      tree = ast2g_type_balance (tree);
      tree = ast2g_apply_rewrites_to_tree (tree);

      nl_reference_set_tree (reference, tree);
    }
  } nl_end_for;

  nl_design_for_all_subprograms (design, subr) {
    nl_ast tree = nl_subprogram_body (subr);

    tree = ast2g_type_balance (tree);
    tree = ast2g_apply_rewrites_to_tree (tree);

    nl_subprogram_set_body (subr, tree);
  } nl_end_for;
}


void
ast2g_dump_trees (nl_design design, int widths, int file, int line)
{
  nl_design_for_all_references (design, reference) {
    nl_ast tree = nl_reference_tree (reference);

    printf ("Tree for %s\n", nl_reference_name (reference));

    if ( widths ) {
      nl_ast_dump_w (tree);
    }
    else if ( file && line ) {
      nl_ast_dump_fl (tree);
    }
    else if ( line ) {
      nl_ast_dump_l (tree);
    }
    else {
      nl_ast_dump (tree);
    }

    printf ("\n");
  } nl_end_for;

  nl_design_for_all_subprograms (design, subr) {
    nl_ast tree = nl_subprogram_body (subr);

    printf ("Tree for %s\n", nl_subprogram_name (subr));

    if ( widths ) {
      nl_ast_dump_w (tree);
    }
    else if ( file && line ) {
      nl_ast_dump_fl (tree);
    }
    else if ( line ) {
      nl_ast_dump_l (tree);
    }
    else {
      nl_ast_dump (tree);
    }

    printf ("\n");
  } nl_end_for;
}


void
ast2g_map_rtl (nl_design design)
{
  namegen_randomize (0);
  ast2g_op_count = 1;

  nl_design_for_all_references (design, reference) {
    char *ref_name = nl_reference_name (reference);

    if ( strncmp (ref_name, "*expression", 11) == 0 ) {
      nl_ast tree = nl_reference_tree (reference);

      nl_reference_for_all_instances (reference, cell) {
	ar inputs = nl_cell_inputs (cell);
	ar outputs = nl_cell_outputs (cell);
	char *file = nl_cell_file (cell);
	int line = nl_cell_line (cell);

	ast2g_translate_expression (design, tree, inputs, outputs,
				    file, line);
	nl_design_remove_cell (design, cell);
      } nl_end_for;
    }
    else if ( strncmp (ref_name, "*process", 8) == 0 ) {
      nl_ast tree = nl_reference_tree (reference);
      
      nl_reference_for_all_instances (reference, cell) {
	ar inputs = nl_cell_inputs (cell);
	ar outputs = nl_cell_outputs (cell);

	ast2g_translate_process (design, tree, inputs, outputs);
	nl_design_remove_cell (design, cell);
      } nl_end_for;
    }
  } nl_end_for;

  nl_design_for_all_subprograms (design, subr) {
    nl_design_remove_subprogram (design, subr);
  } nl_end_for;
}


void
ast2g_define (ssa_context context, nl_object var, nl_net value)
{
  nl_kind kind = nl_object_kind (var);

  ASSERT (kind == nl_kind_net || kind == nl_kind_symbol);
  
  ssa_define (context, var, (ssa_value) value);
}


void
ast2g_define_future (ssa_context context, nl_object var, nl_net value)
{
  nl_kind kind = nl_object_kind (var);

  ASSERT (kind == nl_kind_net || kind == nl_kind_symbol);
  
  ssa_define_future (context, var, (ssa_value) value);
}


nl_net
ast2g_read (ssa_context context, nl_object var)
{
  nl_kind kind = nl_object_kind (var);
  nl_net value = ssa_read (context, var);

  ASSERT (kind == nl_kind_net || kind == nl_kind_symbol);

  return value;
}

nl_net
ast2g_read_final (ssa_context context, nl_object var)
{
  nl_kind kind = nl_object_kind (var);
  nl_net value = ssa_read_final (context, var);

  ASSERT (kind == nl_kind_net || kind == nl_kind_symbol);

  return value;
}

