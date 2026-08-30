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
int
ast2g_get_input_and_polarity (nl_ast tree, int *input_p, int *polarity_p)
{
  int polarity = 0;
  nl_ast t = tree;

  while ( 1 ) {
    nl_token token = nl_ast_token (t);
  
    switch ( token ) {

    case nl_token_lognot:
    case nl_token_bitnot:
      polarity = 1 - polarity;
      t = nl_ast_child (t);
      break;

    case nl_token_in: {
      nl_in_ast in_ast = (nl_in_ast) t;
      int index = nl_in_ast_index (in_ast);
      
      if ( width > 1 ) {
	return 0;
      }

      *input_p = index;
      *polarity_p = polarity;

      return 1;
    }

    default:
      return 0;
    }
  }
}


static
void
ast2g_get_constant_nets (nl_ast tree, ar nets, nl_net zero, nl_net one)
{
  nl_token token = nl_ast_token (tree);

  switch ( token ) {

  case nl_token_hex:
  case nl_token_oct:
    ASSERT (0);

  case nl_token_bin:
    int width = nl_
    nl_vnum_ast vnum = nl_ast_child (tree);
    break;

  case nl_token_dec:
    ASSERT (0);

  default:
    ASSERT (0);
  }
}


static
int
ast2g_expr_to_nets (nl_ast tree, ar nets, ar inputs, ar outputs,
		    nl_net zero, nl_net one)
{
  nl_token token = nl_ast_token (tree);

  switch ( token ) {

  case nl_token_in: {
    nl_in_ast in_ast = (nl_in_ast) tree;
    int index = nl_in_ast_index (in_ast);
    nl_net net;

    ar_ref (inputs, index, &net);
    ar_add (nets, &net);
    return 1;
  }

  case nl_token_out: {
    nl_in_ast out_ast = (nl_out_ast) tree;
    int index = nl_out_ast_index (out_ast);
    nl_net net;

    ar_ref (inputs, index, &net);
    ar_add (nets, &net);
    return 1;
  }

  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct: {
    if ( zero == NULL || one == NULL ) {
      ASSERT (0);
    }

    ast2g_get_constant_nets (tree, nets, zero, one);
    return 1;
  }

  case nl_token_number:
    ASSERT (0);
    break;

  case nl_token_concat:
    break;

  case nl_token_repeat_concat:
    ASSERT (0);
    break;

  default:
    return 0;
  }
}


static
int
ast2g_get_assignment_nets (nl_ast tree, ar lhs_nets, ar rhs_nets,
			   ar inputs, ar outputs, nl_net zero, nl_net one)
{
  nl_token token = nl_ast_token (tree);

  if ( token == nl_token_begin ) {
    nl_ast child = nl_ast_child (tree);

    while ( child != NULL ) {
      int flag = ast2g_get_assignment_nets (child, lhs_nets, rhs_nets);

      if ( flag == 0 )
	return 0;

      child = nl_ast_sibling (child);
    }

    return 1;
  }
  else if ( token == nl_token_nonblock_assign ||
	    token == nl_token_block_assign ) {
    nl_ast rhs_ast = nl_ast_child (tree);
    nl_ast lhs_ast = nl_ast_sibling (rhs_ast);
    int flag = ast2g_expr_to_nets (lhs_ast, lhs_nets, NULL, NULL);

    if ( flag == 0 )
      return 0;

    flag = ast2g_expr_to_nets (rhs_ast, rhs_nets, zero, one);

    return flag;
  }
  else {
    return 0;
  }
}


int
ast2g_get_reg_info (nl_cell cell, nl_net *clk, nl_net *rst,
		    char *clk_sense, char *rst_sense,
		    ar rst_value, ar output, ar data)
{
  int i;
  nl_ast t = tree;
  ar inputs = nl_cell_inputs (cell);
  ar outputs = nl_cell_outputs (cell);
  int num_inputs = ar_size (inputs);
  char *input_sense = alloca (num_inputs);

  for ( i = 0; i < num_inputs; i++ ) {
    input_sense[i] = ' ';
  }

  if ( nl_ast_token (t) == nl_token_always ) {
    nl_ast list = nl_ast_child (t);
    nl_ast body = nl_ast_sibling (sens_list);
    nl_ast sens_list;

    ASSERT (nl_ast_token (list) == nl_token_list);

    sens_list = nl_ast_child (list);

    while ( sens_list != NULL ) {

      if ( nl_token (sens_list) == nl_token_posedge ||
	   nl_token (sens_list) == nl_token_negedge ) {
	nl_ast sens_var = nl_ast_child (sens_list);
	int index;

	ASSERT (nl_ast_token (sens_var) == nl_ast_in);

	index = nl_in_ast_index ((nl_in_ast) sens_var);

	if ( nl_token (sens_list) == nl_token_posedge )
	  input_sense[index] = 'R';
	else
	  input_sense[index] = 'F';
      }
      else {
	return 0;
      }

      sens_list = nl_ast_sibling (sens_list);
    }

    if ( nl_ast_token (body) == nl_token_if ) {
      nl_ast test = nl_ast_child (body);
      nl_ast then_ast = nl_ast_sibling (test);
      nl_ast else_ast = nl_ast_sibling (then_ast);
      int rst_input;
      int rst_level;
      int flag = ast2g_get_input_and_polarity (test, &rst_input, &rst_level);
      ar lhs_nets1;
      ar rhs_nets1;
      ar lhs_nets2;
      ar rhs_nets2;

      if ( !flag ) {
	return 0;
      }

      lhs_nets1 = ar_alloc (0, sizeof (nl_net));
      rhs_nets1 = ar_alloc (0, sizeof (nl_net));
      flag = ast2g_get_assignment_nets (then, lhs_nets1, rhs_nets1,
					inputs, outputs, zero_net, one_net);

      if ( !flag ) {
	ar_free (lhs_nets1);
	ar_free (rhs_nets1);
	return 0;
      }

      lhs_nets2 = ar_alloc (0, sizeof (nl_net));
      rhs_nets2 = ar_alloc (0, sizeof (nl_net));
      flag = ast2g_get_assignment_nets (else, lhs_nets2, rhs_nets2,
					inputs, outputs, zero_net, one_net);

      if ( !flag ) {
	ar_free (lhs_nets1);
	ar_free (rhs_nets1);
	ar_free (lhs_nets2);
	ar_free (rhs_nets2);
	return 0;
      }
    }
  }
}
