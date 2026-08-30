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
#include "skip-list.h"
#include "nl.h"
#include "nl_int.h"


/*exported*/
nl_ast
nl_ast_create (nl_token token)
{
  nl_ast ast = CALLOC (1, sizeof (*ast));

  ast->kind = nl_kind_ast;
  ast->token = token;
  ast->file = NULL;
  ast->line = 0;

  return ast;
}


/*exported*/
nl_ast
nl_ast_copy (nl_ast node)
{
  if ( node == NULL ) {
    return NULL;
  }
  else {
    nl_ast ast = CALLOC (1, sizeof (*ast));

    memcpy (ast, node, sizeof (*ast));

    return ast;
  }
}


/*exported*/
nl_ast
nl_ast_copy_tree (nl_ast root)
{
  if ( root == NULL ) {
    return NULL;
  }
  else {
    nl_ast result = nl_ast_copy (root);
    nl_ast ast = result;

    while ( ast ) {
      ast->child = nl_ast_copy_tree (ast->child);
      ast->sibling = nl_ast_copy (ast->sibling);
      ast = ast->sibling;
    }

    return result;
  }
}


/*exported*/
nl_number_ast
nl_number_ast_create (int value)
{
  nl_number_ast result = (nl_number_ast) nl_ast_create (nl_token_number);

  result->value = value;

  return result;
}


/*exported*/
nl_in_ast
nl_in_ast_create (int index)
{
  nl_in_ast result = (nl_in_ast) nl_ast_create (nl_token_in);

  result->index = index;

  return result;
}


/*exported*/
nl_out_ast
nl_out_ast_create (int index)
{
  nl_out_ast result = (nl_out_ast) nl_ast_create (nl_token_out);

  result->index = index;

  return result;
}


/*exported*/
nl_id_ast
nl_id_ast_create (char *name)
{
  nl_id_ast result = (nl_id_ast) nl_ast_create (nl_token_id);

  result->name = STRDUP (name);

  return result;
}


/*exported*/
nl_vnum_ast
nl_vnum_ast_create (char *bits)
{
  nl_vnum_ast result = (nl_vnum_ast) nl_ast_create (nl_token_vnum);

  result->bits = STRDUP (bits);

  return result;
}


/*exported*/
nl_ref_ast
nl_ref_ast_create (nl_token token, nl_object object)
{
  nl_ref_ast result = (nl_ref_ast) nl_ast_create (token);

  result->object = object;

  return result;
}


/*exported*/
void
nl_ast_free (nl_ast tree)
{
  if ( tree->token == nl_token_id ) {
    nl_id_ast id_ast = (nl_id_ast) tree;
    FREE (id_ast->name);
  }
  FREE (tree);
}


/*exported*/
void
nl_ast_set_file_line (nl_ast tree, char *file, int line)
{
  tree->file = file;
  tree->line = line;
}


/*exported*/
void
nl_ast_inherit_file_line (nl_ast to, nl_ast from)
{
  to->file = from->file;
  to->line = from->line;
}
  

/*exported*/
void
nl_ast_set_token (nl_ast root, int token)
{
  root->token = token;
}


/*exported*/
void
nl_ast_set_width (nl_ast root, int width)
{
  root->width = width;
}


/*exported*/
void
nl_ast_set_child (nl_ast root, nl_ast child)
{
  root->child = child;
}


/*exported*/
nl_ast *
nl_ast_child_addr (nl_ast root)
{
  return &(root->child);
}


/*exported*/
nl_ast *
nl_ast_sibling_addr (nl_ast root)
{
  return &(root->sibling);
}


/*exported*/
void
nl_ast_set_sibling (nl_ast child, nl_ast sib)
{
  child->sibling = sib;
}


/*exported*/
void
nl_number_ast_set_value (nl_number_ast number, int value)
{
  number->value = value;
}


/*exported*/
void
nl_in_ast_set_index (nl_in_ast in, int index)
{
  in->index = index;
}


/*exported*/
void
nl_out_ast_set_index (nl_out_ast out, int index)
{
  out->index = index;
}


/*exported*/
void
nl_id_ast_set_name (nl_id_ast id, char *name)
{
  mem_group g = mem_group_of_pointer (id);

  if ( id->name != NULL )
    FREE (id->name);

  id->name = GSTRDUP (name, g);
}


/*exported*/
void
nl_vnum_ast_set_bits (nl_vnum_ast vnum, char *bits)
{
  mem_group g = mem_group_of_pointer (vnum);

  if ( vnum->bits != NULL )
    FREE (vnum->bits);

  vnum->bits = GSTRDUP (bits, g);
}


/*exported*/
void
nl_ref_ast_set_object (nl_ref_ast ref, nl_object object)
{
  ref->object = object;
}


/*exported*/
void
nl_ast_get_args (nl_ast tree, int n, nl_ast *args)
{
  int i;
  nl_ast t = tree->child;

  for ( i = 0; i < n; i++ ) {
    args[i] = t;
    
    if ( t != NULL ) {
      t = t->sibling;
    }
  }
}


static
void
nl_ast_dump_tree (nl_ast tree, int indent,
		  int avec_width, int avec_file, int avec_line)
{
  while ( tree != NULL ) {
    nl_ast child = tree->child;

    if ( child ) {
      int i;
      putchar ('\n');
      for ( i = 0; i < indent; i++ )
	putchar (' ');
      putchar ('(');
    }

    if ( tree->token == nl_token_number ) {
      nl_number_ast num_ast = (nl_number_ast) tree;
      printf ("%d", num_ast->value);
    }
    else if ( tree->token == nl_token_in ) {
      nl_in_ast in_ast = (nl_in_ast) tree;
      printf ("in%d", in_ast->index);
    }
    else if ( tree->token == nl_token_out ) {
      nl_out_ast out_ast = (nl_out_ast) tree;
      printf ("out%d", out_ast->index);
    }
    else if ( tree->token == nl_token_id ) {
      nl_id_ast id_ast = (nl_id_ast) tree;
      printf ("id:%s", id_ast->name);
    }
    else if ( tree->token == nl_token_vnum ) {
      nl_vnum_ast vnum_ast = (nl_vnum_ast) tree;
      printf ("\"%s\"", vnum_ast->bits);
    }
    else if ( tree->token == nl_token_ref ) {
      nl_ref_ast ref_ast = (nl_ref_ast) tree;
      nl_object obj = nl_ref_ast_object (ref_ast);

      if ( nl_object_kind (obj) == nl_kind_net ) {
	printf ("net:%s", nl_net_name ((nl_net) obj));
      }
      else if ( nl_object_kind (obj) == nl_kind_bus ) {
	printf ("bus:%s", nl_bus_name ((nl_bus) obj));
      }
      else if ( nl_object_kind (obj) == nl_kind_symbol ) {
	printf ("sym:%s", nl_symbol_name ((nl_symbol) obj));
      }
      else if ( nl_object_kind (obj) == nl_kind_subprogram ) {
	printf ("sub:%s", nl_symbol_name ((nl_symbol) obj));
      }
      else {
	ASSERT (0);
      }
    }
    else if ( tree->token == nl_token_lref ) {
      nl_ref_ast ref_ast = (nl_ref_ast) tree;
      nl_object obj = nl_ref_ast_object (ref_ast);

      if ( nl_object_kind (obj) == nl_kind_net ) {
	printf ("lnet:%s", nl_net_name ((nl_net) obj));
      }
      else if ( nl_object_kind (obj) == nl_kind_bus ) {
	printf ("lbus:%s", nl_bus_name ((nl_bus) obj));
      }
      else if ( nl_object_kind (obj) == nl_kind_symbol ) {
	printf ("lsym:%s", nl_symbol_name ((nl_symbol) obj));
      }
      else {
	ASSERT (0);
      }
    }
    else {
      const char *s = nl_token_to_string (tree->token);
      printf ("%s", s);
    }

    if ( avec_width || avec_file || avec_line ) {
      printf ("<");

      if ( avec_width ) {
	printf ("%d", tree->width);
      }

      if ( avec_file ) {
	if ( avec_width )
	  putchar (',');

	if ( tree->file ) 
	  printf ("%s", tree->file);
	else
	  printf ("<null>");
      }

      if ( avec_line ) {
	if ( avec_width || avec_file )
	  putchar (',');

	printf ("%d", tree->line);
      }

      printf (">");
    }

    if ( child ) {
      putchar (' ');
      nl_ast_dump_tree (child, indent+2, avec_width, avec_file, avec_line);
      putchar (')');
    }

    tree = tree->sibling;

    if ( tree != NULL )
      putchar (' ');
  }
}


/*exported*/
void
nl_ast_dump (nl_ast tree)
{
  nl_ast_dump_tree (tree, 0, 0, 0, 0);
  putchar ('\n');
}


/*exported*/
void
nl_ast_dump_w (nl_ast tree)
{
  nl_ast_dump_tree (tree, 0, 1, 0, 0);
  putchar ('\n');
}


/*exported*/
void
nl_ast_dump_fl (nl_ast tree)
{
  nl_ast_dump_tree (tree, 0, 0, 1, 1);
  putchar ('\n');
}


/*exported*/
void
nl_ast_dump_l (nl_ast tree)
{
  nl_ast_dump_tree (tree, 0, 0, 0, 1);
  putchar ('\n');
}


/*exported*/
void
nl_ast_link (nl_ast *root_p, nl_ast *sibling_p, nl_ast *tail_p)
{
  nl_ast sibling = *sibling_p;
  nl_ast root = *root_p;

  if ( sibling == NULL )
    return;

  if ( root == NULL ) {
    *root_p = sibling;
  }
  else if ( root != sibling ) {
    root->child = sibling;
  }

  if ( *tail_p == NULL )
    *tail_p = sibling;

  while ( (*tail_p)->sibling != NULL ) {
    *tail_p = (*tail_p)->sibling;
  }
}


/*exported*/
void
nl_ast_free_tree (nl_ast root)
{
  nl_ast tree = root;

  while ( tree ) {
    nl_ast child = tree->child;
    nl_ast sibling = tree->sibling;

    nl_ast_free (tree);

    if ( sibling == NULL ) {
      tree = child;
    }
    else if ( child == NULL ) {
      tree = sibling;
    }
    else {
      nl_ast_free_tree (child);
      tree = sibling;
    }
  }
}


/*exported*/
nl_ast
nl_ast_make (nl_ast root, ...)
{
  va_list ap;
  nl_ast *prev;
  nl_ast result;

  va_start (ap, root);

  if ( root != NULL ) {
    result = root;
    prev = &(root->child);
    ASSERT (root->child == NULL);
  }
  else {
    prev = &result;
  }

  while (1) {
    nl_ast child = va_arg (ap, nl_ast);
    nl_ast t = child;

    *prev = child;

    if ( child == NULL )
      break;

    while ( t->sibling != NULL )
      t = t->sibling;

    prev = &(t->sibling);
  }

  va_end (ap);

  return result;
}


/*exported*/
nl_ast
nl_ast_dup (nl_ast root)
{
  nl_ast dup = MALLOC (sizeof (*dup));

  *dup = *root;

  if ( dup->child != NULL )
    dup->child = nl_ast_dup (root->child);

  if ( dup->sibling != NULL )
    dup->sibling = nl_ast_dup (root->sibling);

  return dup;
}


/*exported*/
void
nl_ast_prewalk (nl_ast root, nl_ast_prewalk_fun fun,
		nl_ast_prewalk_fun pre, nl_ast_prewalk_fun post)
{
  nl_ast tree = root;

  while ( tree != NULL ) {
    if ( tree->child != NULL )
      pre (tree);

    fun (tree);

    if ( tree->child != NULL )
      post (tree);
  }
}


/*exported*/
nl_walk_status
nl_ast_walk (nl_ast *root_p, nl_ast_walk_fun pre, nl_ast_walk_fun post,
	     void *ptr)
{
  nl_ast root = *root_p;

  if ( root == NULL ) {
    return nl_walk_status_continue;
  }
  else {
    nl_walk_status status;

    if ( pre != NULL ) {
      status = pre (root_p, ptr);

      root = *root_p;
    }
    else {
      status = nl_walk_status_continue;
    }

    if ( status == nl_walk_status_stop ) {
      return nl_walk_status_stop;
    }
    else if ( status == nl_walk_status_continue ) {
      nl_ast *prev = &(root->child);

      while ( *prev != NULL ) {
	status = nl_ast_walk (prev, pre, post, ptr);

	if ( status == nl_walk_status_stop ) {
	  return status;
	}
	else if ( status == nl_walk_status_skip ) {
	  break;
	}
	else {
	  prev = &((*prev)->sibling);
	}
      }
    }

    if ( post != NULL ) {
      status = post (root_p, ptr);
      
      return status;
    }
    else {
      return nl_walk_status_continue;
    }
  }
}


/*exported*/
int
nl_ast_is_expr (nl_ast tree)
{
  nl_token token = nl_ast_token (tree);

  switch ( token ) {
  case nl_token_in:
  case nl_token_bin:
  case nl_token_hex:
  case nl_token_dec:
  case nl_token_oct:
  case nl_token_number:
  case nl_token_posedge:
  case nl_token_negedge:
  case nl_token_shr:
  case nl_token_shl:
  case nl_token_cond:
  case nl_token_bitnot:
  case nl_token_lognot:
  case nl_token_and_reduce:
  case nl_token_nand_reduce:
  case nl_token_or_reduce:
  case nl_token_nor_reduce:
  case nl_token_xor_reduce:
  case nl_token_xnor_reduce:
  case nl_token_and:
  case nl_token_or:
  case nl_token_xor:
  case nl_token_nand:
  case nl_token_nor:
  case nl_token_xnor:
  case nl_token_andand:
  case nl_token_oror:
  case nl_token_add:
  case nl_token_sub:
  case nl_token_mul:
  case nl_token_div:
  case nl_token_mod:
  case nl_token_gt:
  case nl_token_geq:
  case nl_token_lt:
  case nl_token_leq:
  case nl_token_eq2:
  case nl_token_eq3:
  case nl_token_neq:
  case nl_token_neq2:
  case nl_token_concat:
  case nl_token_repeat_concat:
  case nl_token_ref:
  case nl_token_bit:
  case nl_token_varbit:
  case nl_token_slice:
  case nl_token_pos:
  case nl_token_neg:
  case nl_token_funcall:
  case nl_token_varshl:
  case nl_token_varshr:
  case nl_token_lref:
    return 1;

  default:
    return 0;
  }
}
