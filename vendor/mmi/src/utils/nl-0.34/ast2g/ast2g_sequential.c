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


static
void
ast2g_do_begin (ssa_context context, nl_design design, nl_ast tree,
		ar inputs, ar outputs)
{
  nl_ast name = nl_ast_child (tree);
  nl_ast stmt = nl_ast_sibling (name);

  while ( stmt ) {
    ast2g_statement (context, design, stmt, inputs, outputs);

    stmt = nl_ast_sibling (stmt);
  }
}


static
void
ast2g_do_assign (ssa_context context, nl_design design, nl_ast tree,
		 ar inputs, ar outputs)
{
  nl_ast rhs_ast = nl_ast_child (tree);
  nl_ast lhs_ast = nl_ast_sibling (rhs_ast);
  ar rhs_nets = ast2g_expression (context, design, rhs_ast, inputs, outputs);
  ar lhs_nets = ast2g_expression (NULL, design, lhs_ast, NULL, outputs);
  int rhs_size = ar_size (rhs_nets);
  int lhs_size = ar_size (lhs_nets);
  int offset = rhs_size - lhs_size;
  nl_token token = nl_ast_token (tree);

  ASSERT (offset >= 0);

  ar_for_all_indexed (lhs_nets, nl_net, lhs_net, index) {
    nl_net rhs_net;

    ar_ref (rhs_nets, index + offset, &rhs_net);

    ASSERT (rhs_net != NULL);

    if ( token == nl_token_nonblock_assign ) {
      ast2g_define_future (context, (nl_object) lhs_net, rhs_net);
    }
    else if ( token == nl_token_block_assign ) {
      ast2g_define (context, (nl_object) lhs_net, rhs_net);
    }
    else {
      ASSERT (0);
    }
  } ar_end_for;
}


static
ar
ast2g_get_branch_indexes (nl_ast list_ast, int width)
{
  ar result = ar_alloc (1, sizeof (int));
  nl_ast child = nl_ast_child (list_ast);

  while ( child != NULL ) {
    nl_token token = nl_ast_token (child);
    int val;

    if ( token == nl_token_default ) {
      val = -1;
    }
    else {
      val = ast2g_eval_constant (child);
    }

    ar_add (result, &val);
    child = nl_ast_sibling (child);
  }

  return result;
}


static
void
ast2g_do_case (ssa_context context, nl_design design, nl_ast tree,
	       ar inputs, ar outputs)
{
  ssa_context cxt = context;
  nl_ast test_ast = nl_ast_child (tree);
  ar test_nets = ast2g_expression (context, design, test_ast, inputs, outputs);
  nl_ast pragma_ast = nl_ast_sibling (test_ast);
  nl_ast branch = nl_ast_sibling (pragma_ast);
  int test_size = ar_size (test_nets);
  int num_branches = 1 << test_size;
  nl_net_attr net_attr
    = nl_net_attr_create (NULL, design, nl_density_sparse,
			  sizeof (nl_net *), NULL, NULL);
  nl_symbol_attr sym_attr
    = nl_symbol_attr_create (NULL, design, nl_density_sparse,
			     sizeof (nl_net *), NULL, NULL);
  ar vars;
  ar vars_nonblocking;
  ar branch_index_list = ar_alloc (4, sizeof (ar));

  while ( branch ) {
    nl_token branch_tok = nl_ast_token (branch);
    nl_ast body;
    ar branch_indexes;

    if ( branch_tok == nl_token_default ) {
      int minus_one = -1;

      body = nl_ast_child (branch);
      branch_indexes = ar_alloc (1, sizeof (int));
      ar_add (branch_indexes, &minus_one);
    }
    else {
      nl_ast test_list = nl_ast_child (branch);

      body = nl_ast_sibling (test_list);
      branch_indexes = ast2g_get_branch_indexes (test_list, test_size);
    }

    ar_add (branch_index_list, &branch_indexes);

    cxt = ssa_context_branch (cxt);
    ast2g_statement (cxt, design, body, inputs, outputs);
    cxt = ssa_context_up (cxt);

    branch = nl_ast_sibling (branch);
  }

  vars = ar_alloc (4, sizeof (char *));
  vars_nonblocking = ar_alloc (4, sizeof (int));

  {
    int i = 0;
    
    ssa_context_for_all_children (context, child) {
      ar bindings = ssa_context_bindings (child);
      ar branch_indexes;

      ar_ref (branch_index_list, i, &branch_indexes);
      i++;

      ar_for_all (branch_indexes, int, index) {
	ar_for_all (bindings, ssa_binding, binding) {
	  nl_object var = (nl_object) ssa_binding_var (binding);
	  nl_net future_value = ssa_binding_future_value (binding);
	  nl_net current_value = ssa_binding_current_value (binding);
	  nl_net value;
	  int var_nonblocking;
	  nl_net *nets;
	  nl_attr attr;

	  if ( future_value != NULL ) {
	    var_nonblocking = 1;
	    value = future_value;
	  }
	  else if ( current_value != NULL ) {
	    var_nonblocking = 0;
	    value = current_value;
	  }
	  else {
	    ASSERT (0);
	  }

	  if ( nl_object_kind (var) == nl_kind_net ) {
	    attr = (nl_attr) net_attr;
	  }
	  else if ( nl_object_kind (var) == nl_kind_symbol ) {
	    attr = (nl_attr) sym_attr;
	  }
	  else {
	    ASSERT (0);
	  }

	  nl_attr_get (attr, var, &nets);

	  if ( nets == NULL ) {
	    int j;

	    nets = alloca (num_branches * sizeof (nl_net));

	    for ( j = 0; j < num_branches; j++ ) {
	      nets[j] = NULL;
	    }

	    nl_attr_set (attr, var, &nets);
	    ar_add (vars, &var);
	    ar_add (vars_nonblocking, &var_nonblocking);
	  }

	  if ( index == -1 ) {
	    int i;

	    for ( i = 0; i < num_branches; i++ ) {
	      if ( nets[i] == NULL ) {
		nets[i] = value;
	      }
	    }
	  }
	  else {
	    nets[index] = value;
	  }
	} ar_end_for;
      } ar_end_for;

      ar_free (branch_indexes);
    } ssa_end_for;

    ssa_context_clear_children (context);
    ar_free (branch_index_list);
  }

  {
    int i;
    int num_vars = ar_size (vars);
    ar in_buses = ar_alloc (num_branches, sizeof (ar));
    ar out_nets;

    for ( i = 0; i < num_branches; i++ ) {
      ar in_bus = ar_alloc (num_vars, sizeof (nl_net));

      ar_add (in_buses, &in_bus);
    }
    
    ar_for_all (vars, nl_object, var) {
      nl_net *nets;

      if ( nl_object_kind (var) == nl_kind_net ) {
	nl_net_attr_get (net_attr, (nl_net) var, &nets);
      }
      else if ( nl_object_kind (var) == nl_kind_symbol ) {
	nl_symbol_attr_get (sym_attr, (nl_symbol) var, &nets);
      }

      ASSERT (nets != NULL);

      for ( i = 0; i < num_branches; i++ ) {
	nl_net net = nets[i];
	ar in_bus;

	ar_ref (in_buses, i, &in_bus);

	if ( net == NULL ) {
	  net = ast2g_read (context, var);

	  if ( nl_object_kind (var) == nl_kind_symbol ) {
	    ast2g_ast_error (tree, "reference (by non-full case stmt) to free "
			     "variable: %s", nl_symbol_name ((nl_symbol) var));
	  }
	  else if ( nl_object_kind (var) == nl_kind_net ) {
	    net = (nl_net) var;
	  }
	  else {
	    ASSERT (0);
	  }
	}

	ar_add (in_bus, &net);
      }
    } ar_end_for;

    {
      char *file = nl_ast_file (tree);
      int line = nl_ast_line (tree);

      out_nets = ast2g_build_mux (design, num_vars, test_nets, in_buses,
				  file, line);
    }

    ar_for_all_indexed (vars, nl_net, var, index) {
      nl_net value;
      int nonblocking;

      ar_ref (out_nets, index, &value);
      ar_ref (vars_nonblocking, index, &nonblocking);

      if ( nonblocking ) 
	ast2g_define_future (context, (nl_object) var, value);
      else
	ast2g_define (context, (nl_object) var, value);
    } ar_end_for;

    ar_for_all (in_buses, ar, in_bus) {
      ar_free (in_bus);
    } ar_end_for;

    ar_free (in_buses);
    ar_free (out_nets);
  }

  ar_free (vars);
  ar_free (vars_nonblocking);
  nl_design_remove_attr (design, (nl_attr) net_attr);
  nl_design_remove_attr (design, (nl_attr) sym_attr);
}


void
ast2g_statement (ssa_context context, nl_design design, nl_ast tree,
		 ar inputs, ar outputs)
{
  nl_token token = nl_ast_token (tree);

  switch ( token ) {
  case nl_token_block_assign:
  case nl_token_nonblock_assign:
    ast2g_do_assign (context, design, tree, inputs, outputs);
    break;

  case nl_token_begin:
    ast2g_do_begin (context, design, tree, inputs, outputs);
    break;

  case nl_token_case:
    ast2g_do_case (context, design, tree, inputs, outputs);
    break;

  default:
    ASSERT (0);
  }
}


