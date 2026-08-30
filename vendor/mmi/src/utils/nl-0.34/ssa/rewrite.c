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



nl_ast
if_to_case (nl_ast tree)
{
  nl_ast __expr;
  nl_ast __then_stmt;
  nl_ast __elst_stmt;
  nl_ast replaced[1];

  /* do children */

  /* match */
  if ( nl_ast_token (tree) == nl_token_if ) {
    nl_ast child = nl_ast_child (tree);

    replaced[0] = tree;

    if ( child != NULL ) {
      __expr = child;
      child = nl_ast_sibling (child);

      if ( child != NULL ) {
	__then_stmt = child;
	child = nl_ast_sibling (child);

	if ( child != NULL ) {
	  __else_stmt = child;
	}
	else {
	  __else_stmt = NULL;
	}

	goto replace;
      }
    }
  }

  return tree;

 replace:
  /* replace */
  
  /**************************/
}


static
nl_walk_status
explicit_case_walker (nl_ast *tree_p, void *ptr)
{
  nl_ast tree = *tree_p;
  nl_token tok;

  do {
    nl_ast __test_expr = NULL;
    nl_ast __pragmas = NULL;
    nl_ast __terms = NULL;
    
    /* (CASE */
    tok = nl_ast_token (tree);
    if ( !( tok == nl_token_case ||
            tok == nl_token_casex ||
	    token == nl_token_casez ) ) {
      break;
    }
    
    tree_p = nl_ast_child_addr (tree);
    tree = *tree_p;

    if ( child == NULL ) {
      if ( error_missing_child )
	error ();
      else
	break;
    }

    /* ?test_expr */
    __test_expr = tree;

    tree_p = nl_ast_sibling_addr (tree);
    tree = *tree_p;

    if ( tree == NULL ) {
      if ( error_missing_child )
	error ();
      else
	break;
    }
    
    /* ?pragmas */
    __pragmas = tree;

    tree_p = nl_ast_sibling_addr (tree);
    tree = *tree_p;

    /* (repeat */
    while ( 1 ) {
      /* (CASE_ITEM */
      tok = nl_ast_token (tree);
      if ( ! (tok == nl_token_case_item ) ) {
	break;
      }

      /* (replace */
      {
	nl_ast *replace_p = tree_p;
	nl_ast sibling = nl_ast_sibling (tree);

	/* (LIST */
	free_1 = tree;
	tok = nl_ast_token (tree);
	if ( tok != nl_token_list ) {
	  if ( error_on_mismatch )
	    error ();
	  else
	    break;
	}

	tree_p = nl_ast_child_addr (tree);
	tree = *tree_p;

	/* ?term1 */
	__term1 = tree;
	   
	tree_p = nl_ast_sibling_addr (tree);
	tree = *tree_p;

	/* &rest */

	/* ?terms */
	__terms = tree;

	/* matched (LIST ?term1 &rest ?terms) */

	/* replace with (OR_REDUCE ?term1 . ?terms) */
	{
	  nl_ast new = nl_ast_create (nl_token_or_reduce);

	  nl_ast_set_sibling (__term1, NULL);
	  nl_ast_make (new, __term1, __terms, NULL);
	  nl_ast_set_sibling (new, sibling);

	  nl_ast_free (free_1);

	  *replace_p = new;
	}
	/* end of (replace ...) */
	/* &rest */
      }
      /* end of (repeat ...) */
    }

    /* &rest */

    /* end of ((or CASE CASEX CASEZ) ...) */
  }
