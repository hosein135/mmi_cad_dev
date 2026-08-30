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

#include "stdpccts.h"
typedef AST SORAST;
#include "sorcerer.h"
#include "v2nl_walks.h"
#include "ssa.h"
#include "ast2g.h"


static char *v2nl_token_table[1024];

static char *v2nl_token_to_string (int, const char *) UNUSED;
static void v2nl_free_ast_attr (void *) UNUSED;
static nl_ast v2nl_rewrite_lhs_ref (nl_ast) UNUSED;
static nl_ast v2nl_rewrite_case (nl_ast) UNUSED;
static nl_type v2nl_range_ast_to_type (nl_ast) UNUSED;


static
char *
v2nl_token_to_string (int token, const char *text)
{
  if ( v2nl_token_table[token] == NULL ) {
    v2nl_token_table[token] = strdup (text);
  }

  return v2nl_token_table[token];
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


int
v2nl_translate_integer (char *str)
{
  char *s = v2nl_remove_underbars (str);
  int result = atoi (s);

  return result;
}


nl_ast
v2nl_cr_ast (nl_ast tree, Attrib *attr, int token)
{
  nl_token nl_tok;

  switch ( token ) {
  case NULL: nl_tok = nl_token_null; break;
  case ID: nl_tok = nl_token_id; break;
  case IN: nl_tok = nl_token_in; break;
  case BIN_RADIX: nl_tok = nl_token_bin; break;
  case HEX_RADIX: nl_tok = nl_token_hex; break;
  case DEC_RADIX: nl_tok = nl_token_dec; break;
  case OCT_RADIX: nl_tok = nl_token_oct; break;
  case NUMBER: nl_tok = nl_token_number; break;
  case VERILOG_NUMBER: nl_tok = nl_token_vnum; break;
  case ALWAYS: nl_tok = nl_token_always; break;
  case POSEDGE: nl_tok = nl_token_posedge; break;
  case NEGEDGE: nl_tok = nl_token_negedge; break;
  case SENS_OR: nl_tok = nl_token_sens_or; break;
  case IF: nl_tok = nl_token_if; break;
  case CASE: nl_tok = nl_token_case; break;
  case CASEX: nl_tok = nl_token_casex; break;
  case CASEZ: nl_tok = nl_token_casez; break;
  case DEFAULT: nl_tok = nl_token_default; break;
  case FOR: nl_tok = nl_token_for; break;
  case WHILE: nl_tok = nl_token_while; break;
  case FUNCTION: nl_tok = nl_token_function; break;
  case TASK: nl_tok = nl_token_task; break;
  case SHR: nl_tok = nl_token_shr; break;
  case SHL: nl_tok = nl_token_shl; break;
  case COND: nl_tok = nl_token_cond; break;
  case BITNOT: nl_tok = nl_token_bitnot; break;
  case LOGNOT: nl_tok = nl_token_lognot; break;
  case AND_REDUCE: nl_tok = nl_token_and_reduce; break;
  case NAND_REDUCE: nl_tok = nl_token_nand_reduce; break;
  case OR_REDUCE: nl_tok = nl_token_or_reduce; break;
  case NOR_REDUCE: nl_tok = nl_token_nor_reduce; break;
  case XOR_REDUCE: nl_tok = nl_token_xor_reduce; break;
  case XNOR_REDUCE: nl_tok = nl_token_xnor_reduce; break;
  case AND: nl_tok = nl_token_and; break;
  case OR: nl_tok = nl_token_or; break;
  case XOR: nl_tok = nl_token_xor; break;
  case XNOR: nl_tok = nl_token_xnor; break;
  case ANDAND: nl_tok = nl_token_andand; break;
  case OROR: nl_tok = nl_token_oror; break;
  case ADD: nl_tok = nl_token_add; break;
  case SUB: nl_tok = nl_token_sub; break;
  case MUL: nl_tok = nl_token_mul; break;
  case DIV: nl_tok = nl_token_div; break;
  case MOD: nl_tok = nl_token_mod; break;
  case GT: nl_tok = nl_token_gt; break;
  case GEQ: nl_tok = nl_token_geq; break;
  case LT: nl_tok = nl_token_lt; break;
  case LEQ: nl_tok = nl_token_leq; break;
  case EQ2: nl_tok = nl_token_eq2; break;
  case EQ3: nl_tok = nl_token_eq3; break;
  case NEQ: nl_tok = nl_token_neq; break;
  case NEQ2: nl_tok = nl_token_neq2; break;
  case CONCAT: nl_tok = nl_token_concat; break;
  case REPEAT_CONCAT: nl_tok = nl_token_repeat_concat; break;
  case REF: nl_tok = nl_token_ref; break;
  case BIT: nl_tok = nl_token_bit; break;
  case VARBIT: nl_tok = nl_token_varbit; break;
  case SLICE: nl_tok = nl_token_slice; break;
  case BEGIN: nl_tok = nl_token_begin; break;
  case LIST: nl_tok = nl_token_list; break;
  case CASE_ITEM: nl_tok = nl_token_case_item; break;
  case POS: nl_tok = nl_token_pos; break;
  case NEG: nl_tok = nl_token_neg; break;
  case BLOCK_ASSIGN: nl_tok = nl_token_block_assign; break;
  case NONBLOCK_ASSIGN: nl_tok = nl_token_nonblock_assign; break;
  case DELAY: nl_tok = nl_token_delay; break;
  case INSTANCE: nl_tok = nl_token_instance; break;
  case PIN: nl_tok = nl_token_pin; break;
  case PARAMS: nl_tok = nl_token_params; break;
  case FUNCALL: nl_tok = nl_token_funcall; break;
  case CALL: nl_tok = nl_token_call; break;
  case VARSHL: nl_tok = nl_token_varshl; break;
  case VARSHR: nl_tok = nl_token_varshr; break;
  case PARALLEL_CASE: nl_tok = nl_token_parallel_case; break;
  case FULL_CASE: nl_tok = nl_token_full_case; break;
  case INFER_MUX: nl_tok = nl_token_infer_mux; break;
  case WIRE: nl_tok = nl_token_wire; break;
  case REG: nl_tok = nl_token_reg; break;
  case INPUT: nl_tok = nl_token_input; break;
  case OUTPUT: nl_tok = nl_token_output; break;
  case INOUT: nl_tok = nl_token_inout; break;
  case RANGE: nl_tok = nl_token_range; break;
  case INTEGER: nl_tok = nl_token_integer; break;

  /* Tokens of these types are currently ignored. */
  case P_STRING: nl_tok = nl_token_null; break;
  case SYNC_SET_RESET: nl_tok = nl_token_null; break;
  case ASYNC_SET_RESET: nl_tok = nl_token_null; break;

  case MAP_TO_MODULE: nl_tok = nl_token_map_to_module; break;
  case RETURN_PORT_NAME: nl_tok = nl_token_return_port_name; break;
  case P_ID: nl_tok = nl_token_id; break;

  default:
    ASSERT (0);
    break;
  }

  if ( attr != NULL ) {
    nl_ast_set_file_line (tree, attr->file, attr->line);
  }

  nl_ast_set_token (tree, nl_tok);

  if ( nl_tok == nl_token_number ) {
    nl_number_ast number_ast = (nl_number_ast) tree;
    int value = v2nl_translate_integer ((char *) attr->text);

    nl_number_ast_set_value (number_ast, value);
  }
  else if ( nl_tok == nl_token_id ) {
    nl_id_ast id_ast = (nl_id_ast) tree;
    
    nl_id_ast_set_name (id_ast, (char *) attr->text);
  }
  else if ( nl_tok == nl_token_vnum ) {
    nl_vnum_ast vnum_ast = (nl_vnum_ast) tree;

    nl_vnum_ast_set_bits (vnum_ast, (char *) attr->text);
  }

  return tree;
}


static
char *
v2nl_eval (nl_ast tree, int *val_p)
{
  nl_ast arg_ast[2];
  int arg[2];
  nl_token token = nl_ast_token (tree);

  nl_ast_get_args (tree, 2, arg_ast);

  if ( arg_ast[0] != NULL ) {
    char *err = v2nl_eval (arg_ast[0], &arg[0]);

    if ( err != NULL )
      return err;

    if ( arg_ast[1] != NULL ) {
      err = v2nl_eval (arg_ast[1], &arg[1]);

      if ( err != NULL )
	return err;
    }
  }
  
  switch (token) {
  case nl_token_number:
    *val_p = nl_number_ast_value ((nl_number_ast) tree);
    return NULL;
  case nl_token_add:
    *val_p = arg[0] + arg[1];
    return NULL;
  case nl_token_sub:
    *val_p = arg[0] - arg[1];
    return NULL;
  case nl_token_mul:
    *val_p = arg[0] * arg[1];
    return NULL;
  case nl_token_div:
    *val_p = arg[0] / arg[1];
    return NULL;
  case nl_token_neg:
    *val_p = -arg[0];
    return NULL;
  default:
    return (char *) nl_token_to_string (token);
  }
}


int
v2nl_eval_expr (nl_ast tree, int *val_p)
{
  char *err = v2nl_eval (tree, val_p);

  return err == NULL;
}


int
v2nl_eval_integer_expr (nl_ast tree)
{
  int value;
  char *err = v2nl_eval (tree, &value);

  nl_ast_free_tree (tree);

  if ( err != NULL ) {
    v2nl_ast_error (tree, "Unsupported operation in constant expression -> %s",
		    err);
  }
  else {
    return value;
  }
}


nl_ast
v2nl_make_integer_ast (int n)
{
  nl_number_ast result = nl_number_ast_create (n);

  return (nl_ast) result;
}


int
v2nl_is_expr_trivial (nl_ast tree)
{
  nl_token token = nl_ast_token (tree);

  switch (token) {
  case nl_token_ref:
  case nl_token_bit:
  case nl_token_slice:
  case nl_token_number:
  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct:
    return 1;

#if 0    
  case nl_token_shr:
  case nl_token_shl: {
    nl_ast arg = nl_ast_child (tree);
    int flag = v2nl_is_expr_trivial (arg);

    return flag;
  }
#endif
  case nl_token_repeat_concat: {
    nl_ast args[2];
    int flag;

    nl_ast_get_args (tree, 2, args);
    flag = v2nl_is_expr_trivial (args[1]);

    return flag;
  }
  case nl_token_concat: {
    nl_ast arg = nl_ast_child (tree);

    while ( arg != NULL ) {
      int flag = v2nl_is_expr_trivial (arg);

      if ( !flag )
	return 0;

      arg = nl_ast_sibling (arg);
    }

    return 1;
  }
      
  default:
    return 0;
  }
}


#if 0
ar
v2nl_expr_to_nets (void *ptr)
{
  AST *expr = ptr;
  AST *arg[2];

  arg[0] = zzchild (expr);

  if ( arg[0] != NULL ) {
    arg[1] = zzsibling (arg[0]);

    if ( arg[1] != NULL ) {
      arg[2] = zzsibling (arg[1]);
    }
  }

  switch ( expr->token ) {
  case REF: {
    ar result = v2nl_var_ref (arg[0]->u.text);
    return result;
  }
  case BIT: {
    int index = v2nl_translate_integer (arg[1]->u.text);
    ar result = v2nl_var_bit (arg[0]->u.text, index);
    return result;
  }
  case SLICE: {
    int l = v2nl_translate_integer (arg[1]->u.text);
    int r = v2nl_translate_integer (arg[2]->u.text);
    ar result = v2nl_var_slice (arg[0]->u.text, l, r);
    return result;
  }
  case CONCAT: {
    AST *arg = zzchild (expr);
    ar result = ar_alloc (4, sizeof (nl_net));

    while ( arg != NULL ) {
      ar nets = v2nl_trivial_expr_to_nets (arg);

      ar_append (result, nets);
      ar_free (nets);

      arg = zzsibling (arg);
    }

    return result;
  }
  case REPEAT_CONCAT: {
    int repeat = v2nl_translate_integer (arg[0]->u.text);
    ar nets = v2nl_trivial_expr_to_nets (arg[1]);
    ar result = v2nl_repeat_concat (repeat, nets);
    return result;
  }
  case NUMBER: {
    int x = expr->u.num;
    ar result = v2nl_get_integer (x);
    return result;
  }
  case BIN_RADIX: {
    int x = v2nl_translate_integer (arg[0]->u.text);
    ar result = v2nl_get_constant_nets (x, 'b', arg[1]->u.text);
    return result;
  }
  case HEX_RADIX: {
    int x = v2nl_translate_integer (arg[0]->u.text);
    ar result = v2nl_get_constant_nets (x, 'h', arg[1]->u.text);
    return result;
  }
  case DEC_RADIX: {
    int x = v2nl_translate_integer (arg[0]->u.text);
    ar result = v2nl_get_constant_nets (x, 'd', arg[1]->u.text);
    return result;
  }
  case OCT_RADIX: {
    int x = v2nl_translate_integer (arg[0]->u.text);
    ar result = v2nl_get_constant_nets (x, 'o', arg[1]->u.text);
    return result;
  }
  case SHR: {
    int x = v2nl_translate_integer (arg[1]->u.text);
    ar nets = v2nl_trivial_expr_to_nets (arg[0]);
    ar result = v2nl_shift_right (nets, x);
    return result;
  }
  case SHL: {
    int x = v2nl_translate_integer (arg[1]->u.text);
    ar nets = v2nl_trivial_expr_to_nets (arg[0]);
    ar result = v2nl_shift_left (nets, x);
    return result;
  }
  case AND: {
  }
  case OR: {
  }
  default:
    ASSERT (0);
  }
}
#endif


static
nl_net
v2nl_get_net_for_bit_ref (nl_bus bus, int index, nl_ast tree)
{
  nl_type type = nl_bus_type (bus);
  int offset;
  int flag = nl_type_get_offset_for_index (type, index, &offset);

  if ( flag == 0 ) {
    int left = nl_type_left (type);
    int right = nl_type_right (type);

    v2nl_ast_error (tree, "index out of bounds for bus %s; "
		    "range is [%d:%d], index is %d",
		    left, right, index);
  }
  else {
    nl_net net = (nl_net) nl_bus_get_member (bus, offset);

    return net;
  }
}


static
nl_ast
v2nl_build_concat_ast_for_bus (nl_bus bus, int left, int right, nl_ast tree)
{
  int lower = left < right ? left : right;
  int upper = left > right ? left : right;
  nl_type type = nl_bus_type (bus);
  int type_left = nl_type_left (type);
  int type_right = nl_type_right (type);
  nl_ast result = nl_ast_create (nl_token_concat);
  nl_ast last = NULL;

  nl_ast_inherit_file_line (result, tree);

  if ( (type_left <= type_right && left > right) ||
       (type_left >  type_right && left < right) ) {
    v2nl_ast_error (tree, "slice direction ([%d:%d]) does not match "
		    "that of bus %s ([%d:%d])", left, right,
		    nl_bus_name (bus), type_left, type_right);
  }

  if ( (left < lower) || (left > upper) ||
       (right < lower) || (right > upper) ) {
    v2nl_ast_error (tree, "slice ([%d:%d]) goes out of bounds of "
		    "bus %s ([%d:%d])", left, right, nl_bus_name (bus),
		    type_left, type_right);
  }

  nl_type_for_all_indexes (type, index) {
    if ( index >= lower && index <= upper ) {
      nl_net net = v2nl_get_net_for_bit_ref (bus, index, tree);
      nl_ref_ast ref_ast = nl_ref_ast_create (nl_token_ref, (nl_object) net);

      nl_ast_inherit_file_line ((nl_ast) ref_ast, tree);
      nl_ast_set_sibling ((nl_ast) ref_ast, last);
      last = (nl_ast) ref_ast;
    }
  } nl_end_for;

  nl_ast_set_child (result, last);

  return result;
}


static
nl_symbol
v2nl_get_symbol_for_bit_ref (nl_symbol symbol, int index, nl_ast tree)
{
  nl_type type = nl_symbol_type (symbol);
  int offset;
  int flag = nl_type_get_offset_for_index (type, index, &offset);

  if ( flag == 0 ) {
    int left = nl_type_left (type);
    int right = nl_type_right (type);

    v2nl_ast_error (tree, "index out of bounds for symbol %s; "
		    "range is [%d:%d], index is %d",
		    left, right, index);
  }
  else {
    nl_symbol result = nl_symbol_get_constituent (symbol, offset);

    return result;
  }
}


static
nl_ast
v2nl_build_concat_ast_for_sym (nl_symbol sym, int left, int right, nl_ast tree)
{
  int lower = left < right ? left : right;
  int upper = left > right ? left : right;
  nl_type type = nl_symbol_type (sym);
  int type_left = nl_type_left (type);
  int type_right = nl_type_right (type);
  nl_ast result = nl_ast_create (nl_token_concat);
  nl_ast last = NULL;

  nl_ast_inherit_file_line (result, tree);
  
  if ( (type_left <= type_right && left > right) ||
       (type_left >  type_right && left < right) ) {
    v2nl_ast_error (tree, "slice direction ([%d:%d]) does not match "
		    "that of symbol %s ([%d:%d])", left, right,
		    nl_symbol_name (sym), type_left, type_right);
  }

  if ( (left < lower) || (left > upper) ||
       (right < lower) || (right > upper) ) {
    v2nl_ast_error (tree, "slice ([%d:%d]) goes out of bounds of "
		    "symbol %s ([%d:%d])", left, right, nl_symbol_name (sym),
		    type_left, type_right);
  }

  nl_type_for_all_indexes (type, index) {
    if ( index >= lower && index <= upper ) {
      nl_symbol ref_sym = v2nl_get_symbol_for_bit_ref (sym, index, tree);
      nl_ref_ast ref_ast
	= nl_ref_ast_create (nl_token_ref, (nl_object) ref_sym);

      nl_ast_inherit_file_line ((nl_ast) ref_ast, tree);
      nl_ast_set_sibling ((nl_ast) ref_ast, last);
      last = (nl_ast) ref_ast;
    }
  } nl_end_for;

  nl_ast_set_child (result, last);

  return result;
}


nl_ast
v2nl_rewrite_ref_slice (nl_ast root, nl_subprogram subr)
{
  nl_ast result = root;
  nl_ast *prev = &result;

  while ( *prev != NULL ) {
    nl_ast tree = *prev;
    nl_token tok = nl_ast_token (tree);

    if ( tok == nl_token_ref ) {
      nl_ref_ast ref_ast = (nl_ref_ast) tree;
      nl_object object = nl_ref_ast_object (ref_ast);
      nl_kind kind = nl_object_kind (object);
      nl_ast concat_ast = NULL;
      
      if ( kind == nl_kind_bus ) {
	nl_bus bus = (nl_bus) object;
	nl_type type = nl_bus_type (bus);
	int left = nl_type_left (type);
	int right = nl_type_right (type);

	concat_ast = v2nl_build_concat_ast_for_bus (bus, left, right, tree);
      }
      else if ( kind == nl_kind_net ) {
	/* Don't need to do anything. */
      }
      else if ( kind == nl_kind_symbol ) {
	nl_symbol sym = (nl_symbol) object;
	nl_type type = nl_symbol_type (sym);
       
	if ( nl_type_class (type) != nl_typeclass_scalar ) {
	  int left = nl_type_left (type);
	  int right = nl_type_right (type);

	  concat_ast = v2nl_build_concat_ast_for_sym (sym, left, right, tree);
	}
      }
      else if ( kind == nl_kind_subprogram ) {
	;
      }
      else {
	ASSERT (0);
      }

      if ( concat_ast != NULL ) {
	nl_ast_set_sibling (concat_ast, nl_ast_sibling (tree));
	nl_ast_set_sibling (tree, NULL);
	nl_ast_free_tree (tree);
	*prev = concat_ast;
      }

      prev = nl_ast_sibling_addr (*prev);
    }
    else if ( tok == nl_token_bit ) {
      nl_ref_ast ref_ast = (nl_ref_ast) nl_ast_child (tree);
      nl_number_ast index_ast
	= (nl_number_ast) nl_ast_sibling ((nl_ast) ref_ast);
      nl_object object = nl_ref_ast_object (ref_ast);
      int index = nl_number_ast_value (index_ast);
      nl_kind kind = nl_object_kind (object);
      nl_object new_ref_obj;

      ASSERT (nl_ref_ast_token (ref_ast) == nl_token_ref);
      ASSERT (nl_number_ast_token (index_ast) == nl_token_number);
      
      if ( kind == nl_kind_net ) {
	nl_net net = (nl_net) object;
	
	v2nl_ast_error (tree, "bit selection applied to non-bus wire: %s",
			nl_net_name (net));
      }
      else if ( kind == nl_kind_bus ) {
	nl_bus bus = (nl_bus) object;
	nl_net bit_net = v2nl_get_net_for_bit_ref (bus, index, tree);

	new_ref_obj = (nl_object) bit_net;
      }
      else if ( kind == nl_kind_symbol ) {
	nl_symbol sym = (nl_symbol) object;
	nl_type type = nl_symbol_type (sym);

	if ( nl_type_class (type) == nl_typeclass_scalar ) {
	  v2nl_ast_error (tree, "bit select operation applied to non-array "
			  "symbol: %s", nl_symbol_name (sym));
	}
	else {
	  nl_symbol bit_sym = v2nl_get_symbol_for_bit_ref (sym, index, tree);

	  new_ref_obj = (nl_object) bit_sym;
	}
      }
      else {
	ASSERT (0);
      }

      {
	nl_ref_ast new_ref_ast = nl_ref_ast_create (nl_token_ref, new_ref_obj);

	nl_ast_inherit_file_line ((nl_ast) new_ref_ast, tree);
	nl_ast_set_sibling ((nl_ast) new_ref_ast, nl_ast_sibling (tree));
	nl_ast_free (tree);
	*prev = (nl_ast) new_ref_ast;
	prev = nl_ast_sibling_addr ((nl_ast) new_ref_ast);
      }
    }
    else if ( tok == nl_token_slice ) {
      nl_ref_ast ref_ast = (nl_ref_ast) nl_ast_child (tree);
      nl_number_ast left_ast
	= (nl_number_ast) nl_ast_sibling ((nl_ast) ref_ast);
      nl_number_ast right_ast
	= (nl_number_ast) nl_ast_sibling ((nl_ast) left_ast);
      nl_object object = nl_ref_ast_object (ref_ast);
      int left = nl_number_ast_value (left_ast);
      int right = nl_number_ast_value (right_ast);
      nl_ast concat_ast = NULL;
      nl_kind kind = nl_object_kind (object);

      ASSERT (nl_ref_ast_token (ref_ast) == nl_token_ref);
      ASSERT (nl_number_ast_token (left_ast) == nl_token_number);
      ASSERT (nl_number_ast_token (right_ast) == nl_token_number);

      if ( kind == nl_kind_bus ) {
	nl_bus bus = (nl_bus) object;

	concat_ast = v2nl_build_concat_ast_for_bus (bus, left, right, tree);
      }
      else if ( kind == nl_kind_net ) {
	nl_net net = (nl_net) object;

	v2nl_ast_error (tree, "slice operation applied to non-bus object: "
			"%s", nl_net_name (net));
      }
      else if ( kind == nl_kind_symbol ) {
	nl_symbol sym = (nl_symbol) object;
	nl_type type = nl_symbol_type (sym);

	if ( nl_type_class (type) == nl_typeclass_scalar ) {
	  v2nl_ast_error (tree, "slice operation applied to non-array symbol: "
			  "%s", nl_symbol_name (sym));
	}
	else {
	  concat_ast = v2nl_build_concat_ast_for_sym (sym, left, right, tree);
	}
      }

      ASSERT (concat_ast != NULL);

      nl_ast_set_sibling (concat_ast, nl_ast_sibling (tree));
      nl_ast_set_sibling (tree, NULL);
      nl_ast_free_tree (tree);
      *prev = concat_ast;
      prev = nl_ast_sibling_addr (concat_ast);
    }
    else {
      nl_ast child = nl_ast_child (tree);

      if ( child != NULL ) {
	nl_ast new_child = v2nl_rewrite_ref_slice (child, subr);
	nl_ast_set_child (tree, new_child);
      }

      prev = nl_ast_sibling_addr (tree);
    }
  }

  return result;
}


ar
v2nl_trivial_expr_to_nets (nl_ast tree)
{
  STreeParser stp;
  ar result;

  STreeParserInit (&stp);

  result = v2nl_walk_trivial_expr (&stp, &tree);

  return result;
}


static
nl_ast
v2nl_collect_nets (nl_ast root, nl_net_attr net_attr, ar nets)
{
  nl_ast result = root;
  nl_ast *prev = &result;

  while ( *prev != NULL ) {
    nl_ast tree = *prev;

    if ( nl_ast_token (tree) == nl_token_ref ) {
      nl_ref_ast ref_ast = (nl_ref_ast) tree;
      nl_object obj = nl_ref_ast_object (ref_ast);
      int index;

      if ( nl_object_kind (obj) == nl_kind_subprogram ) {
	prev = nl_ast_sibling_addr (tree);
      }
      else {
	nl_net net = (nl_net) obj;
	nl_net_attr_get (net_attr, net, &index);

	if ( index == -1 ) {
	  index = ar_size (nets);
	  ar_add (nets, &net);
	  nl_net_attr_set (net_attr, net, &index);
	}

	{
	  nl_ast in_ast = (nl_ast) nl_in_ast_create (index);
	  
	  nl_ast_inherit_file_line (in_ast, tree);
	  nl_ast_set_sibling (in_ast, nl_ast_sibling (tree));
	  nl_ast_set_sibling (tree, NULL);
	  nl_ast_free_tree (tree);
	  *prev = in_ast;
	  prev = nl_ast_sibling_addr (in_ast);
	}
      }
    }
    else {
      nl_ast child = nl_ast_child (tree);

      if ( child != NULL ) {
	nl_ast new_child = v2nl_collect_nets (child, net_attr, nets);
	nl_ast_set_child (tree, new_child);
      }

      prev = nl_ast_sibling_addr (tree);
    }
  }

  return result;
}

#if 0
static
void
v2nl_init_minus_one (void *ptr, nl_object obj)
{
  int *attr_p = ptr;

  *attr_p = -1;
}
#endif


static
nl_ast
v2nl_collect_inputs (nl_ast tree, ar inputs)
{
  int minus_one = -1;
  nl_net_attr net_attr
    = nl_net_attr_create ("collected nets", v2nl_current_design,
			  nl_density_sparse, sizeof (int),
			  &minus_one, NULL);

  nl_ast result = v2nl_collect_nets (tree, net_attr, inputs);

  nl_design_remove_attr (v2nl_current_design, (nl_attr) net_attr);

  return result;
}


static
void
v2nl_free_ast_attr (void *ptr)
{
  nl_ast root = *(nl_ast *) ptr;

  if ( root != NULL ) {
    nl_ast_free (root);
  }
}


#if 0
static
nl_reference_attr
v2nl_get_expression_attribute (void)
{
  nl_reference_attr attr 
    = (nl_reference_attr) nl_design_get_attr_by_name (v2nl_current_design,
						      "expression AST");

  if ( attr == NULL ) {
    attr = nl_reference_attr_create ("expression AST", v2nl_current_design,
				     nl_density_sparse, sizeof (nl_ast),
				     NULL, v2nl_free_ast_attr);
  }

  return attr;
}
#endif


static
nl_walk_status
v2nl_rewrite_lhs_ref_prewalker (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;
  nl_token token = nl_ast_token (tree);

  if ( token == nl_token_block_assign || token == nl_token_nonblock_assign ) {
    nl_ast args[3];

    nl_ast_get_args (tree, 3, args);

    nl_ast_walk (&args[1], v2nl_rewrite_lhs_ref_prewalker, NULL, (void *)1);

    return nl_walk_status_skip;
  }
  else if ( token == nl_token_ref ) {
    if ( ptr != NULL ) {
      nl_ast_set_token (tree, nl_token_lref);
    }

    return nl_walk_status_skip;
  }
  else if ( token == nl_token_for ) {
    nl_ast args[3];

    nl_ast_get_args (tree, 3, args);

    nl_ast_walk (&args[0], v2nl_rewrite_lhs_ref_prewalker, NULL, (void *)1);
    nl_ast_walk (&args[2], v2nl_rewrite_lhs_ref_prewalker, NULL, (void *)1);
  }

  return nl_walk_status_continue;
}


static
nl_ast
v2nl_rewrite_lhs_ref (nl_ast tree)
{
  nl_ast root = tree;

  nl_ast_walk (&root, v2nl_rewrite_lhs_ref_prewalker, NULL, NULL);

  return root;
}


static
int
v2nl_ast_get_input_index (ssa_context context, nl_design design, nl_net net,
			  nl_net_attr net_attr, ar inputs)
{
  int index = -1;
  nl_ast source = (nl_ast) ssa_read (context, net);

  if ( source == NULL ) {
    nl_net_attr_get (net_attr, net, &index);

    if ( index == -1 ) {
      index = ar_size (inputs);
	
      ar_add (inputs, &net);
	
      nl_net_attr_set (net_attr, net, &index);
    }
  }

  return index;
}


struct collect_ios_data {
  ssa_context context;
  ar inputs;
  nl_net_attr net_attr;
  nl_design design;
  int nonblocking;
};


static
nl_walk_status
v2nl_collect_ios_walker (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;
  nl_token token = nl_ast_token (tree);
  struct collect_ios_data *data = ptr;

  if ( token == nl_token_case ) {
    ssa_context context = data->context;
    nl_ast *child_p = nl_ast_child_addr (tree);
    int has_default = 0;
    int branch_count = 0;
    int is_full_case = 0;

    /* Walk the expression. */
    nl_ast_walk (child_p, v2nl_collect_ios_walker, NULL, ptr);
    child_p = nl_ast_sibling_addr (*child_p);

    /* Next child is the list of pragmas. */
    /* Look for the full_case pragma. */
    ASSERT (nl_ast_token (*child_p) == nl_token_list);
    {
      nl_ast pragma = nl_ast_child (*child_p);

      while ( pragma != NULL ) {
	if ( nl_ast_token (pragma) == nl_token_full_case ) {
	  is_full_case = 1;
	  break;
	}
	pragma = nl_ast_sibling (pragma);
      }
    }
    child_p = nl_ast_sibling_addr (*child_p);

    /* The remaining children are the branches. */
    while ( *child_p != NULL ) {
      if ( nl_ast_token (*child_p) == nl_token_default ) {
	has_default = 1;
      }
      else {
	ASSERT (nl_ast_token (*child_p) == nl_token_case_item);
      }

      data->context = ssa_context_branch (context);
      nl_ast_walk (child_p, v2nl_collect_ios_walker, NULL, ptr);
      data->context = ssa_context_up (data->context);
      branch_count++;

      child_p = nl_ast_sibling_addr (*child_p);
    }

    {
      nl_net_attr net_attr
	= nl_net_attr_create (NULL, v2nl_current_design, nl_density_sparse,
			      sizeof (int), NULL, NULL);
      ar nets = ar_alloc (4, sizeof (nl_net));
      ar nets_nonblocking = ar_alloc (4, sizeof (int));

      ssa_context_for_all_children (context, child) {
	ar bindings = ssa_context_bindings (child);
	int nonblocking = -1;

	ar_for_all (bindings, ssa_binding, binding) {
	  nl_net net = (nl_net) ssa_binding_var (binding);
	  nl_ast future_val = (nl_ast) ssa_binding_future_value (binding);
	  int count;

	  if ( future_val != NULL ) {
	    nonblocking = 1;
	  }
	  else {
	    nonblocking = 0;
	  }

	  nl_net_attr_get (net_attr, net, &count);

	  if ( count == 0 ) {
	    ar_add (nets, &net);
	    ar_add (nets_nonblocking, &nonblocking);
	  }
	  
	  count++;
	  nl_net_attr_set (net_attr, net, &count);
	} ar_end_for;
      } ssa_end_for;

      ar_for_all_indexed (nets, nl_net, net, which) {
	int count;
	int nonblocking;

	nl_net_attr_get (net_attr, net, &count);

	if (count < branch_count || 
	    (has_default == 0 && is_full_case == 0 && count == branch_count)) {
	  v2nl_ast_get_input_index (context, data->design, net,
				    data->net_attr, data->inputs);
	}

	ar_ref (nets_nonblocking, which, &nonblocking);

	if ( nonblocking ) {
	  ssa_define_future (context, net, tree);
	}
	else {
	  ssa_define (context, net, tree);
	}
      } ar_end_for;

      nl_design_remove_attr (v2nl_current_design, (nl_attr) net_attr);
      ar_free (nets);
    }

    ssa_context_clear_children (context);

    return nl_walk_status_skip;
  }
  else if ( token == nl_token_ref ) {
    ssa_context context = data->context;
    nl_object object = nl_ref_ast_object ((nl_ref_ast) tree);

    if ( nl_object_kind (object) == nl_kind_subprogram ) {
      return nl_walk_status_continue;
    }
    else {
      nl_net net = (nl_net) object;
      int index = v2nl_ast_get_input_index (context, data->design, net,
					    data->net_attr, data->inputs);

      ASSERT (nl_object_kind (object) == nl_kind_net);
      
      if ( index != -1 ) {
	nl_ast in_ast = (nl_ast) nl_in_ast_create (index);
	
	nl_ast_inherit_file_line (in_ast, tree);
	nl_ast_set_sibling (in_ast, nl_ast_sibling (tree));
	nl_ast_set_sibling (tree, NULL);
	nl_ast_free_tree (tree);
	*tree_p = in_ast;
      }

      return nl_walk_status_skip;
    }
  }
  else if ( token == nl_token_lref ) {
    ssa_context context = data->context;
    nl_object object = nl_ref_ast_object ((nl_ref_ast) tree);
    nl_net net = (nl_net) object;

    ASSERT (nl_object_kind (object) == nl_kind_net);

    if ( data->nonblocking ) {
      ssa_define_future (context, net, tree);
    }
    else {
      ssa_define (context, net, tree);
    }

    return nl_walk_status_skip;
  }
  else if ( token == nl_token_nonblock_assign ) {
    nl_ast *rhs_p = nl_ast_child_addr (tree);
    nl_ast *lhs_p;

    nl_ast_walk (rhs_p, v2nl_collect_ios_walker, NULL, data);
    data->nonblocking = 1;
    lhs_p = nl_ast_sibling_addr (*rhs_p);
    nl_ast_walk (lhs_p, v2nl_collect_ios_walker, NULL, data);
    data->nonblocking = 0;

    return nl_walk_status_skip;
  }

  return nl_walk_status_continue;
}


static
nl_walk_status
v2nl_rename_outputs_walker (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;
  nl_token token = nl_ast_token (tree);
  nl_net_attr net_attr = (nl_net_attr) ptr;
  
  if ( token == nl_token_lref || token == nl_token_ref ) {
    nl_object object = nl_ref_ast_object ((nl_ref_ast) tree);

    if ( nl_object_kind (object) != nl_kind_net ) {
      return nl_walk_status_continue;
    }
    else {
      nl_net net = (nl_net) object;
      int index;

      ASSERT (nl_object_kind (object) == nl_kind_net);
      
      nl_net_attr_get (net_attr, net, &index);

      {
	nl_ast out_ast = (nl_ast) nl_out_ast_create (index);

	nl_ast_inherit_file_line (out_ast, tree);
	nl_ast_set_sibling (out_ast, nl_ast_sibling (tree));
	nl_ast_set_sibling (tree, NULL);
	nl_ast_free_tree (tree);
	*tree_p = out_ast;
      }
    }
  }

  return nl_walk_status_continue;
}


static
ssa_binding
v2nl_var_get (void *var, void *ptr)
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
    
    binding = nl_symbol_binding (sym);
  }
  else {
    ASSERT (0);
  }

  return binding;
}


static
void
v2nl_var_set (void *var, ssa_binding binding, void *ptr)
{
  nl_object obj = (nl_object) var;
  nl_kind kind = nl_object_kind (obj);

  if ( kind == nl_kind_net ) {
    nl_net net = (nl_net) obj;
    nl_net_attr net_attr = (nl_net_attr) ptr;;

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
v2nl_collect_ios (nl_ast tree, ar inputs, ar outputs)
{
  nl_net_attr net_attr
    = nl_net_attr_create (NULL, v2nl_current_design, nl_density_sparse,
			  sizeof (ssa_binding), NULL, NULL);
  ssa_global global = ssa_global_create (v2nl_var_get, v2nl_var_set, net_attr);
  ssa_context context = ssa_context_create (NULL, NULL, global);

  {
    int minus_one = -1;
    nl_net_attr net_attr
      = nl_net_attr_create (NULL, v2nl_current_design, nl_density_sparse,
			    sizeof (int), &minus_one, NULL);
    struct collect_ios_data data;

    data.context = context;
    data.inputs = inputs;
    data.net_attr = net_attr;
    data.design = v2nl_current_design;
    data.nonblocking = 0;

    nl_ast_walk (&tree, v2nl_collect_ios_walker, NULL, &data);

    nl_design_remove_attr (v2nl_current_design, (nl_attr) net_attr);
  }

  {
    nl_net_attr net_attr =
      nl_net_attr_create (NULL, v2nl_current_design, nl_density_sparse,
			  sizeof (int), NULL, NULL);
    ar bindings = ssa_context_bindings (context);
    
    ar_for_all (bindings, ssa_binding, binding) {
      nl_net net = (nl_net) ssa_binding_var (binding);
      int index = ar_size (outputs);

      nl_net_attr_set (net_attr, net, &index);
      ar_add (outputs, &net);
    } ar_end_for;

    nl_ast_walk (&tree, v2nl_rename_outputs_walker, NULL, net_attr);

    nl_design_remove_attr (v2nl_current_design, (nl_attr) net_attr);
  }
}


static
char *
v2nl_temp_id (void)
{
  static char buf[256];
  int r = random ();

  sprintf (buf, "tmp_%08x", r);

  return buf;
}


static
nl_walk_status
v2nl_rewrite_case_walker_1 (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;
  nl_token token = nl_ast_token (tree);

  if ( token == nl_token_case ||
       token == nl_token_casex ||
       token == nl_token_casez ) {
    nl_ast sibling = nl_ast_sibling (tree);
    nl_ast test = nl_ast_child (tree);
    nl_ast rest = nl_ast_sibling (test);
    char *tmp_id_name = v2nl_temp_id ();
    nl_id_ast tmp_id1 = nl_id_ast_create (tmp_id_name);
    nl_id_ast tmp_id2 = nl_id_ast_create (tmp_id_name);
    nl_ast begin_ast = nl_ast_create (nl_token_begin);
    nl_ast assign_ast = nl_ast_create (nl_token_block_assign);
    nl_ast assign_lhs = nl_ast_create (nl_token_lref);
    nl_ast assign_rhs = test;
    nl_ast new_test = nl_ast_create (nl_token_ref);

    nl_ast_make (assign_lhs, tmp_id1, NULL);
    nl_ast_make (assign_ast, assign_rhs, assign_lhs, NULL);
    nl_ast_make (new_test, tmp_id2, NULL);
    nl_ast_make (begin_ast, assign_ast, tree, NULL);
    nl_ast_make (tree, new_test, rest, NULL);

    nl_ast_set_sibling (begin_ast, sibling);

    *tree_p = begin_ast;
  }

  return nl_walk_status_continue;
}


static
nl_ast
v2nl_rewrite_case (nl_ast tree)
{
  nl_ast result = tree;
  nl_ast_walk (&result, v2nl_rewrite_case_walker_1, NULL, NULL);

  return result;
}
  

static
nl_reference
v2nl_get_synthetic_reference (char *name, int num_outs, int num_ins,
			      nl_ast tree)
{
  static int synthetic_num = 1;
  nl_reference reference;
  int i;
  char *buf = alloca (sizeof (name) + 16);

  sprintf (buf, "*%s_%d*", name, synthetic_num);
  synthetic_num++;

  reference = nl_reference_create (buf, v2nl_current_design, NULL);
  nl_reference_set_tree (reference, tree);

  for ( i = 0; i < num_outs; i++ ) {
    nl_refpin refpin;

    sprintf (buf, "out%d", i);

    refpin = nl_refpin_create (buf, NULL, reference);
    nl_refpin_set_direction (refpin, nl_direction_out);
  }

  for ( i = 0; i < num_ins; i++ ) {
    nl_refpin refpin;

    sprintf (buf, "in%d", i);

    refpin = nl_refpin_create (buf, NULL, reference);
    nl_refpin_set_direction (refpin, nl_direction_in);
  }

  return reference;
}
  

static
nl_ast
v2nl_apply_rewrites (nl_ast tree, nl_subprogram subr)
{
  tree = v2nl_rewrite_var_shift (tree);
  tree = v2nl_rewrite_ref_slice (tree, subr);
  tree = v2nl_lhs_ref_to_lref (tree);
  tree = v2nl_if_to_case (tree);
  /* tree = v2nl_remove_useless_concats (tree); */

  return tree;
}
      

static
void
v2nl_build_expression_cell (ar inputs, ar outputs, nl_ast tree,
			    char *file, int line)
{
  nl_reference reference
    = v2nl_get_synthetic_reference ("expression", ar_size (outputs),
				    ar_size (inputs), tree);

  nl_cell cell = nl_cell_create (nl_reference_name (reference), reference);

  nl_cell_set_file_line (cell, file, line);

  v2nl_set_attributes ((nl_object) cell);

  {
    int index = 0;

    nl_cell_for_all_outputs (cell, out_pin) {
      nl_net out_net;

      ar_ref (outputs, index, &out_net);
      nl_pin_connect_net (out_pin, out_net);

      index++;
    } nl_end_for;
    
    index = 0;

    nl_cell_for_all_inputs (cell, in_pin) {
      nl_net in_net;

      ar_ref (inputs, index, &in_net);
      nl_pin_connect_net (in_pin, in_net);

      index++;
    } nl_end_for;
  }
}


static
void
v2nl_expression (ar outputs, nl_ast tree, char *file, int line)
{
  ar inputs = ar_alloc (0, sizeof (nl_net));

  tree = v2nl_apply_rewrites (tree, NULL);

  tree = v2nl_collect_inputs (tree, inputs);

  v2nl_build_expression_cell (inputs, outputs, tree, file, line);
}


void
v2nl_do_rtl_assign (ar lhs, nl_ast rhs_ast, Attrib *attr)
{ 
  int flag =  v2nl_is_expr_trivial (rhs_ast);

  if ( flag ) {
    ar rhs = v2nl_trivial_expr_to_nets ((AST *) rhs_ast);
    v2nl_assign (lhs, rhs, attr);
    ar_free (rhs);
  }
  else {
    v2nl_expression (lhs, rhs_ast, attr->file, attr->line);
  }
}


void
v2nl_create_process (nl_ast tree)
{
  ar inputs = ar_alloc (0, sizeof (nl_net));
  ar outputs = ar_alloc (0, sizeof (nl_net));
  nl_reference reference;
  nl_cell cell;

  tree = v2nl_apply_rewrites (tree, NULL);

  v2nl_collect_ios (tree, inputs, outputs);

  reference = v2nl_get_synthetic_reference ("process", ar_size (outputs),
					    ar_size (inputs), tree);

  cell = nl_cell_create (nl_reference_name (reference), reference);

  {
    char *file = nl_ast_file (tree);
    int line = nl_ast_line (tree);

    nl_cell_set_file_line (cell, file, line);
  }

  v2nl_set_attributes ((nl_object) cell);

  {
    int index = 0;

    nl_cell_for_all_outputs (cell, out_pin) {
      nl_net out_net;

      ar_ref (outputs, index, &out_net);
      nl_pin_connect_net (out_pin, out_net);

      index++;
    } nl_end_for;

    index = 0;

    nl_cell_for_all_inputs (cell, in_pin) {
      nl_net in_net;

      ar_ref (inputs, index, &in_net);
      nl_pin_connect_net (in_pin, in_net);

      index++;
    } nl_end_for;
  }
}


static
nl_type
v2nl_range_ast_to_type (nl_ast range_ast)
{
  nl_number_ast left_ast = (nl_number_ast) nl_ast_child (range_ast);
  nl_number_ast right_ast = (nl_number_ast) nl_number_ast_sibling (left_ast);
  int left = nl_number_ast_value (left_ast);
  int right = nl_number_ast_value (right_ast);
  nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);
  nl_type array = nl_type_get_array (scalar, left, right);

  return array;
}


nl_subprogram
v2nl_create_function (char *name, nl_type type)
{
  nl_subprogram fun = nl_subprogram_create (name, type, v2nl_current_design);
  nl_symbol retval = nl_symbol_create (name, type, nl_wireclass_output, fun);
  char *bus_naming_style = nl_design_bus_naming_style (v2nl_current_design);
  char *buf = alloca (strlen (name) + strlen (bus_naming_style) + 16);

  nl_subprogram_add_symbol (fun, retval);

  if ( nl_type_class (type) == nl_typeclass_array ) {
    nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);

    nl_type_for_all_indexes (type, index) {
      nl_symbol new_sym;
      
      sprintf (buf, bus_naming_style, name, index);
      new_sym = nl_symbol_create (buf, scalar, nl_wireclass_output, fun);
      nl_symbol_add_constituent (retval, new_sym);
      nl_subprogram_add_symbol (fun, new_sym);
    } nl_end_for;
  }

  return fun;
}


void
v2nl_add_function_pragmas (nl_subprogram subr, nl_ast pragmas)
{
  nl_subprogram_set_pragmas (subr, pragmas);
}


void
v2nl_add_function_body (nl_subprogram subr, nl_ast body)
{
  nl_ast tree = body;

  tree = v2nl_apply_rewrites (tree, subr);  

  nl_subprogram_set_body (subr, tree);
}


ar
v2nl_random_expr (nl_ast tree)
{
  int flag = v2nl_is_expr_trivial (tree);

  if ( flag ) {
    ar result = v2nl_trivial_expr_to_nets (tree);

    return result;
  }
  else {
    ar inputs = ar_alloc (0, sizeof (nl_ast));

    tree = v2nl_apply_rewrites (tree, NULL);

    tree = v2nl_collect_inputs (tree, inputs);

    {
      int out_width = ast2g_expression_width (tree);
      nl_type scalar = nl_type_get_scalar ((nl_object) v2nl_current_design);
      nl_type type = nl_type_get_array (scalar, out_width-1, 0);
      char net_name[32];
      ar result;
      
      sprintf (net_name, "*net_%08x", (int) random ());

      v2nl_variable (nl_wireclass_wire, nl_direction_null, type, net_name);

      {
	nl_bus bus
	  = (nl_bus) nl_design_get_net_or_bus_by_name (v2nl_current_design,
						       net_name);

	ASSERT (nl_bus_kind (bus) == nl_kind_bus);

	result = nl_bus_members (bus);

	result = ar_copy (result);

	ar_reverse (result);

	{
	  char *file = nl_ast_file (tree);
	  int line = nl_ast_line (tree);

	  v2nl_build_expression_cell (inputs, result, tree, file, line);
	}

	return result;
      }
    }
  }
}
