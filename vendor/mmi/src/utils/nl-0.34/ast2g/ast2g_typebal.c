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


static void ast2g_propagate_width (nl_ast *, int);


#define	max(x, y)  ((x) > (y) ? (x) : (y))


static
nl_ast
ast2g_zero_pad (nl_ast tree, int width)
{
  int tree_width = nl_ast_width (tree);
  int pad_size = width - tree_width;
  nl_ast pad_ast = nl_ast_create (nl_token_bin);
  nl_number_ast num_ast = nl_number_ast_create (pad_size);
  nl_vnum_ast vnum_ast = nl_vnum_ast_create ("0");
  nl_ast concat_ast = nl_ast_create (nl_token_concat);

  ASSERT (pad_size > 0);

  nl_ast_inherit_file_line (pad_ast, tree);
  nl_ast_inherit_file_line ((nl_ast) num_ast, tree);
  nl_ast_inherit_file_line ((nl_ast) vnum_ast, tree);
  nl_ast_inherit_file_line (concat_ast, tree);

  nl_ast_set_width (pad_ast, pad_size);
  nl_ast_set_width (concat_ast, width);

  nl_ast_make (pad_ast, num_ast, vnum_ast, NULL);
  nl_ast_make (concat_ast, pad_ast, tree, NULL);

  return concat_ast;
}


int
ast2g_expression_width (nl_ast tree)
{
  nl_token token = nl_ast_token (tree);
  int result = -1;

  switch ( token ) {

  case nl_token_number:
    result = 32;
    break;

  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct: {
    nl_number_ast num_ast = (nl_number_ast) nl_ast_child (tree);

    result = nl_number_ast_value (num_ast);
    break;
  }

  case nl_token_bit:
  case nl_token_slice:
    /* These should have been turned into concats. */
    ASSERT (0);
    
  case nl_token_in:
  case nl_token_out:
  case nl_token_ref:
  case nl_token_lref:
  case nl_token_varbit:
    result = 1;
    break;

  case nl_token_lognot:
  case nl_token_and_reduce:
  case nl_token_or_reduce:
  case nl_token_xor_reduce:
  case nl_token_nand_reduce:
  case nl_token_nor_reduce:
  case nl_token_xnor_reduce:
  case nl_token_andand:
  case nl_token_oror:
  case nl_token_gt:
  case nl_token_geq:
  case nl_token_lt:
  case nl_token_leq:
  case nl_token_eq2:
  case nl_token_eq3:
  case nl_token_neq:
  case nl_token_neq2:
  case nl_token_posedge:
  case nl_token_negedge: {
    nl_ast arg1 = nl_ast_child (tree);
    nl_ast arg2 = nl_ast_sibling (arg1);

    ast2g_expression_width (arg1);
    if ( arg2 != NULL )
      ast2g_expression_width (arg2);

    result = 1;
    break;
  }

  case nl_token_bitnot:
  case nl_token_pos:
  case nl_token_neg: {
    nl_ast arg = nl_ast_child (tree);

    result = ast2g_expression_width (arg);
    break;
  }

  case nl_token_shr:
  case nl_token_shl:
  case nl_token_varshr:
  case nl_token_varshl: {
    nl_ast arg1 = nl_ast_child (tree);
    nl_ast arg2 = nl_ast_sibling (arg1);

    result = ast2g_expression_width (arg1);
    ast2g_expression_width (arg2);

    break;
  }

  case nl_token_and:
  case nl_token_or:
  case nl_token_xor:
  case nl_token_nand:
  case nl_token_nor:
  case nl_token_xnor:
  case nl_token_add:
  case nl_token_sub:
  case nl_token_mul:
  case nl_token_div: {
    nl_ast arg1 = nl_ast_child (tree);
    nl_ast arg2 = nl_ast_sibling (arg1);
    int width1 = ast2g_expression_width (arg1);
    int width2 = ast2g_expression_width (arg2);

    result = max (width1, width2);
    break;
  }

  case nl_token_cond: {
    nl_ast args[3];
    int then_width;
    int else_width;
    
    nl_ast_get_args (tree, 3, args);

    ast2g_expression_width (args[0]);
    then_width = ast2g_expression_width (args[1]);
    else_width = ast2g_expression_width (args[2]);

    result = max (then_width, else_width);
    break;
  }

  case nl_token_concat: {
    nl_ast child = nl_ast_child (tree);

    result = 0;

    while ( child != NULL ) {
      int child_width = ast2g_expression_width (child);

      result += child_width;
      child = nl_ast_sibling (child);
    }
    break;
  }

  case nl_token_repeat_concat: {
    nl_number_ast num_ast = (nl_number_ast) nl_ast_child (tree);
    nl_ast arg_ast = nl_number_ast_sibling (num_ast);
    int repeat = nl_number_ast_value (num_ast);
    int arg_width = ast2g_expression_width (arg_ast);

    result = repeat * arg_width;
    break;
  }

  case nl_token_funcall: {
    nl_ref_ast ref_ast = (nl_ref_ast) nl_ast_child (tree);
    nl_ast args = nl_ref_ast_sibling (ref_ast);
    nl_object obj = nl_ref_ast_object (ref_ast);
    nl_subprogram fun = (nl_subprogram) obj;
    nl_type fun_type = nl_subprogram_type (fun);
    int width = nl_type_width (fun_type);

    ASSERT (nl_object_kind (obj) == nl_kind_subprogram);
    
    while ( args != NULL ) {
      ast2g_expression_width (args);
      args = nl_ast_sibling (args);
    }

    result = width;
    break;
  }

  default:
    ASSERT (0);
  }

  ASSERT (result > 0);
  nl_ast_set_width (tree, result);

  return result;
}


static
void
ast2g_trim_number (nl_ast tree, int width)
{
  if ( width < 32 ) {
    int x = nl_number_ast_value ((nl_number_ast) tree);
    int y = x & ((1 << width) - 1);

    nl_ast_set_width (tree, width);
    
    if ( y != x ) {
      nl_number_ast_set_value ((nl_number_ast) tree, y);
    }
  }
}


static
char 
ast2g_trim_msb (char digit, int mod)
{
  char result;

  if ( '0' <= digit <= '9' ) {
    result = '0' + (digit - '0') % mod;
  }
  else if ( 'a' <= digit <= 'f' ) {
    result = 'a' + (digit - 'a' + 10) % mod;
  }
  else if ( 'A' <= digit <= 'F' ) {
    result = 'A' + (digit - 'A' + 10) % mod;
  }
  else {
    ASSERT (0);
  }

  return result;
}


static
char *
ast2g_trim_bits (char *bits, int bits_per_char, int width)
{
  int len = strlen (bits);
  
  if ( bits_per_char*len > width ) {
    char *new_bits = bits + (bits_per_char*len - width) / bits_per_char;

    switch (width % bits_per_char) {
    case 0:
      break;
    case 1:
      bits[0] = ast2g_trim_msb (bits[0], 2);
      break;
    case 2:
      bits[0] = ast2g_trim_msb (bits[0], 4);
      break;
    case 3:
      bits[0] = ast2g_trim_msb (bits[0], 8);
      break;
    default:
      ASSERT (0);
    }

    return new_bits;
  }
  else {
    return bits;
  }
}


static
void
ast2g_trim_or_pad_verilog_number (nl_ast tree, int width)
{
  if ( width != 0 ) {
    nl_token token = nl_ast_token (tree);
    nl_number_ast num_ast = (nl_number_ast) nl_ast_child (tree);
    nl_vnum_ast vnum_ast = (nl_vnum_ast) nl_number_ast_sibling (num_ast);
    char *bits = nl_vnum_ast_bits (vnum_ast);

    nl_number_ast_set_value (num_ast, width);

    switch (token) {

    case nl_token_bin: {
      int len = strlen (bits);

      if ( len > width ) {
	char *new_bits = bits + len - width;

	nl_vnum_ast_set_bits (vnum_ast, STRDUPA (new_bits));
      }
      break;
    }

    case nl_token_hex: {
      char *new_bits = ast2g_trim_bits (bits, 4, width);

      if ( new_bits != bits ) {
	nl_vnum_ast_set_bits (vnum_ast, STRDUPA (new_bits));
      }
      break;
    }

    case nl_token_oct: {
      char *new_bits = ast2g_trim_bits (bits, 3, width);

      if ( new_bits != bits ) {
	nl_vnum_ast_set_bits (vnum_ast, STRDUPA (new_bits));
      }
      break;
    }

    case nl_token_dec:
      if ( width < 32 ) {
	int x;
	int y;

	sscanf (bits, "%u", &x);
	y = x & ((1 << width) - 1);

	if ( y != x ) {
	  char new_bits[16];

	  sprintf (new_bits, "%u", y);

	  nl_vnum_ast_set_bits (vnum_ast, new_bits);
	}
      }
      break;

    default:
      ASSERT (0);
    }
  }
}


static
void
ast2g_trim_concat (nl_ast tree, int width)
{
  ar children = ar_alloc (4, sizeof (nl_ast));

  {
    nl_ast child = nl_ast_child (tree);

    while ( child != NULL ) {
      ar_add (children, &child);
      child = nl_ast_sibling (child);
    }
  }

  {
    nl_ast first_child = NULL;
    int total_width = 0;
    nl_ast free_me;

    ar_for_all_reverse (children, nl_ast, child) {
      int child_width = nl_ast_width (child);

      total_width += child_width;

      if ( total_width == width ) {
	first_child = child;
	break;
      }
      else if ( total_width > width ) {
	int target_width = child_width - (total_width - width);

	ast2g_propagate_width (&child, target_width);
	first_child = child;
	break;
      }
    } ar_end_for;

    ASSERT (first_child != NULL);

    free_me = nl_ast_child (tree);
    nl_ast_set_child (tree, first_child);

    while ( free_me != first_child ) {
      nl_ast next = nl_ast_sibling (free_me);

      nl_ast_set_sibling (free_me, NULL);
      nl_ast_free_tree (free_me);
      free_me = next;
    }

    ast2g_expression_width (tree);

    ASSERT (nl_ast_width (tree) == width);
  }

  ar_free (children);
}


static
nl_ast
ast2g_trim_repeat_concat (nl_ast tree, int width)
{
  nl_number_ast num_ast = (nl_number_ast) nl_ast_child (tree);
  nl_ast arg_ast = nl_number_ast_sibling (num_ast);
  int arg_width = nl_ast_width (arg_ast);
  int new_count = width / arg_width;
  int remainder = width % arg_width;
  nl_ast repeat_ast = tree;
  nl_ast result;
  char *file = nl_ast_file (tree);
  int line = nl_ast_line (tree);

  if ( new_count == 0 ) {
    nl_ast_free (repeat_ast);
    repeat_ast = NULL;
  }
  else {
    nl_number_ast_set_value (num_ast, new_count);
  }

  if ( remainder == 0 ) {
    result = tree;
  }
  else {
    nl_ast arg_copy = nl_ast_copy_tree (arg_ast);
    nl_ast concat = nl_ast_create (nl_token_concat);

    ast2g_propagate_width (&arg_copy, remainder);

    nl_ast_set_child (concat, arg_copy);
    nl_ast_set_sibling (arg_copy, repeat_ast);
    nl_ast_set_file_line (concat, file, line);

    result = concat;
  }

  ast2g_expression_width (result);

  ASSERT (nl_ast_width (result) == width);

  return result;
}


static
void
ast2g_propagate_width (nl_ast *tree_p, int context_width)
{
  nl_ast tree = *tree_p;
  nl_ast sibling = nl_ast_sibling (tree);
  nl_token token = nl_ast_token (tree);
  int width;

  nl_ast_set_sibling (tree, NULL);

  if ( context_width == 0 ) {
    width = nl_ast_width (tree);
  }
  else {
    width = context_width;
  }

  /* ASSERT (nl_ast_width (tree) <= width); */

  switch ( token ) {
  case nl_token_number:
    if ( width < 32 ) {
      ast2g_trim_number (tree, width);
    }
    else if ( width > 32 ) {
      *tree_p = ast2g_zero_pad (tree, width);
    }
    break;

  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct:
    ast2g_trim_or_pad_verilog_number (tree, width);
    break;

  case nl_token_bit:
  case nl_token_slice:
    ASSERT (0);

  case nl_token_in:
  case nl_token_out:
  case nl_token_ref:
  case nl_token_lref:
  case nl_token_varbit:
    if ( width > 1 ) {
      *tree_p = ast2g_zero_pad (tree, width);
    }
    break;

  case nl_token_lognot:
  case nl_token_oror:
  case nl_token_andand:
  case nl_token_and_reduce:
  case nl_token_or_reduce:
  case nl_token_xor_reduce:
  case nl_token_nand_reduce:
  case nl_token_nor_reduce:
  case nl_token_xnor_reduce:
  case nl_token_gt:
  case nl_token_geq:
  case nl_token_lt:
  case nl_token_leq:
  case nl_token_eq2:
  case nl_token_eq3:
  case nl_token_neq:
  case nl_token_neq2: {
    nl_ast *arg_p = nl_ast_child_addr (tree);
    
    if ( width > 1 ) {
      *tree_p = ast2g_zero_pad (tree, width);
    }

    ast2g_propagate_width (arg_p, 0);

    break;
  }

  case nl_token_bitnot:
  case nl_token_pos:
  case nl_token_neg: {
    nl_ast *arg_p = nl_ast_child_addr (tree);

    ast2g_propagate_width (arg_p, width);

    break;
  }

  case nl_token_shr:
  case nl_token_shl:
  case nl_token_varshr:
  case nl_token_varshl: {
    nl_ast *arg1_p = nl_ast_child_addr (tree);
    nl_ast *arg2_p;

    ast2g_propagate_width (arg1_p, 0);

    arg2_p = nl_ast_sibling_addr (*arg1_p);
    ast2g_propagate_width (arg2_p, 0);

    break;
  }

  case nl_token_and:
  case nl_token_or:
  case nl_token_xor:
  case nl_token_nand:
  case nl_token_nor:
  case nl_token_xnor:
  case nl_token_add:
  case nl_token_sub:
  case nl_token_mul:
  case nl_token_div: {
    nl_ast *arg1_p = nl_ast_child_addr (tree);
    nl_ast *arg2_p;

    ast2g_propagate_width (arg1_p, width);

    arg2_p = nl_ast_sibling_addr (*arg1_p);
    ast2g_propagate_width (arg2_p, width);

    break;
  }

  case nl_token_cond: {
    nl_ast *test_p = nl_ast_child_addr (tree);
    nl_ast *then_p;
    nl_ast *else_p;

    ast2g_propagate_width (test_p, 0);

    then_p = nl_ast_sibling_addr (*test_p);
    ast2g_propagate_width (then_p, width);

    else_p = nl_ast_sibling_addr (*then_p);
    ast2g_propagate_width (else_p, width);

    break;
  }

  case nl_token_concat: {
    nl_ast *child_p;
    int concat_width = nl_ast_width (tree);

    if ( width > concat_width ) {
      *tree_p = ast2g_zero_pad (tree, width);
    }
    if ( width < concat_width ) {
      ast2g_trim_concat (tree, width);
    }

    child_p = nl_ast_child_addr (tree);

    while ( *child_p != NULL ) {
      ast2g_propagate_width (child_p, 0);

      child_p = nl_ast_sibling_addr (*child_p);
    }

    break;
  }

  case nl_token_repeat_concat: {
    nl_ast *repeat_p = nl_ast_child_addr (tree);
    nl_ast *arg_p = nl_ast_sibling_addr (*repeat_p);
    
    if ( width > nl_ast_width (tree) ) {
      *tree_p = ast2g_zero_pad (tree, width);
    }
    else if ( width < nl_ast_width (tree) ) {
      *tree_p = ast2g_trim_repeat_concat (tree, width);
    }

    ast2g_propagate_width (arg_p, 0);

    break;
  }

  case nl_token_posedge:
  case nl_token_negedge: {
    nl_ast *arg_p = nl_ast_child_addr (tree);

    ast2g_propagate_width (arg_p, 0);
    break;
  }

  case nl_token_funcall: {
    nl_ref_ast ref_ast = (nl_ref_ast) nl_ast_child (tree);
    nl_ast *arg_p = nl_ast_sibling_addr ((nl_ast) ref_ast);
    nl_object obj = nl_ref_ast_object (ref_ast);
    nl_subprogram fun = (nl_subprogram) obj;
    
    if ( width > nl_ast_width (tree) ) {
      *tree_p = ast2g_zero_pad (tree, width);
    }

    nl_subprogram_for_all_formals (fun, formal) {
      nl_type arg_type = nl_symbol_type (formal);
      int arg_width = nl_type_width (arg_type);
      
      ast2g_propagate_width (arg_p, arg_width);

      if ( *arg_p == NULL ) {
	ast2g_ast_error (tree, "too few arguments to function %s",
			nl_subprogram_name (fun));
      }
      
      arg_p = nl_ast_sibling_addr (*arg_p);

    } nl_end_for;

    if ( *arg_p != NULL ) {
      ast2g_ast_error (tree, "too many arguments to function %s",
		      nl_subprogram_name (fun));
    }
    
    break;
  }

  default:
    ASSERT (0);
  }

  nl_ast_set_width (tree, width);

  if ( context_width == 0 ) {
    /* If context_width is 0 (i.e. width is self-determined) than this
       node should not have changed. */
    ASSERT (tree == *tree_p);
  }

  nl_ast_set_sibling (*tree_p, sibling);
}


static
void
ast2g_balance_assignment (nl_ast lhs, nl_ast *rhs_p)
{
  int lhs_width = ast2g_expression_width (lhs);
  int rhs_width UNUSED = ast2g_expression_width (*rhs_p);
  int new_rhs_width = lhs_width;

  ast2g_propagate_width (rhs_p, new_rhs_width);
}


static void ast2g_type_balance_case_vcs (nl_ast tree) UNUSED;

static
void
ast2g_type_balance_case_vcs (nl_ast tree)
/* This routine does case statement type balancing according to the 1364 LRM,
   not the way VCS does it.
*/
{
  nl_ast test = nl_ast_child (tree);
  nl_ast pragmae = nl_ast_sibling (test);
  int test_width = ast2g_expression_width (test);
  int max_width = test_width;

  {
    nl_ast branch = nl_ast_sibling (pragmae);

    while ( branch != NULL ) {
      nl_token br_tok = nl_ast_token (branch);

      if ( br_tok == nl_token_case_item ) {
	nl_ast tags = nl_ast_child (branch);
	nl_ast body = nl_ast_sibling (tags);
	nl_ast tag = nl_ast_child (tags);

	ast2g_type_balance (body);

	while ( tag != NULL ) {
	  int tag_width = ast2g_expression_width (tag);

	  if ( tag_width > max_width )
	    max_width = tag_width;

	  tag = nl_ast_sibling (tag);
	}
      }
      else if ( br_tok == nl_token_default ) {
	nl_ast body = nl_ast_child (branch);

	ast2g_type_balance (body);
      }

      branch = nl_ast_sibling (branch);
    }
  }

  {
    nl_ast *test_p = nl_ast_child_addr (tree);
    nl_ast branch = nl_ast_sibling (pragmae);

    ast2g_propagate_width (test_p, max_width);

    while ( branch != NULL ) {
      nl_token br_tok = nl_ast_token (branch);

      if ( br_tok == nl_token_case_item ) {
	nl_ast tags = nl_ast_child (branch);
	nl_ast *tag_p = nl_ast_child_addr (tags);

	while ( *tag_p != NULL ) {
	  ast2g_propagate_width (tag_p, max_width);
	  
	  tag_p = nl_ast_sibling_addr (*tag_p);
	}
      }

      branch = nl_ast_sibling (branch);
    }
  }
}



static
void
ast2g_type_balance_case_jka (nl_ast tree)
{
  nl_ast test = nl_ast_child (tree);
  nl_ast pragmae = nl_ast_sibling (test);
  int test_width = ast2g_expression_width (test);
  nl_ast *test_p = nl_ast_child_addr (tree);

  {
    nl_ast branch = nl_ast_sibling (pragmae);

    ast2g_propagate_width (test_p, 0);

    while ( branch != NULL ) {
      nl_token br_tok = nl_ast_token (branch);

      if ( br_tok == nl_token_case_item ) {
	nl_ast tags = nl_ast_child (branch);
	nl_ast *tag_p = nl_ast_child_addr (tags);
	nl_ast body = nl_ast_sibling (tags);
	nl_ast new_body = ast2g_type_balance (body);

	nl_ast_set_sibling (tags, new_body);

	while ( *tag_p != NULL ) {
	  ast2g_propagate_width (tag_p, test_width);
	  
	  tag_p = nl_ast_sibling_addr (*tag_p);
	}
      }
      else if ( br_tok == nl_token_default ) {
	nl_ast body = nl_ast_child (branch);
	nl_ast new_body = ast2g_type_balance (body);

	nl_ast_set_child (branch, new_body);
      }
      else {
	ASSERT (0);
      }

      branch = nl_ast_sibling (branch);
    }
  }
}



static
nl_walk_status
ast2g_update_widths_walker (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;

  if ( nl_ast_is_expr (tree) ) {
    ast2g_expression_width (tree);

    return nl_walk_status_skip;
  }
  else {
    return nl_walk_status_continue;
  }
}


void
ast2g_update_widths (nl_ast tree)
{
  nl_ast_walk (&tree, ast2g_update_widths_walker, NULL, NULL);
}


static
nl_walk_status
ast2g_type_balance_walker (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;
  nl_token token = nl_ast_token (tree);

  if ( token == nl_token_block_assign || token == nl_token_nonblock_assign ) {
    nl_ast *rhs_p = nl_ast_child_addr (tree);
    nl_ast lhs = nl_ast_sibling (*rhs_p);

    ast2g_balance_assignment (lhs, rhs_p);

    return nl_walk_status_skip;
  }
  else if ( token == nl_token_case ||
	    token == nl_token_casex ||
	    token == nl_token_casez ) {
    ast2g_type_balance_case_jka (*tree_p);

    return nl_walk_status_skip;
  }
  else if ( nl_ast_is_expr (tree) ) {
    ast2g_propagate_width (tree_p, 0);

    return nl_walk_status_skip;
  }

  return nl_walk_status_continue;
}


nl_ast
ast2g_type_balance (nl_ast tree)
{
  nl_ast result = tree;

  nl_ast_walk (&result, ast2g_type_balance_walker, NULL, NULL);

  return result;
}


nl_ast
ast2g_type_balance_expression (int lhs_width, nl_ast rhs_tree)
{
  int rhs_width UNUSED = ast2g_expression_width (rhs_tree);
  int new_rhs_width = lhs_width;
  nl_ast result = rhs_tree;

  ast2g_propagate_width (&result, new_rhs_width);

  return result;
}
