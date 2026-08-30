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

jka_infer_inverting_ops_walker (nl_ast *root_p, void *ptr)
{
  nl_ast tree = *root_p;
  nl_ast_token token = nl_ast_token (tree);

  if ( token == nl_token_bitnot ) {
    nl_ast child = nl_ast_child (tree);

    if ( child != NULL ) {
      nl_ast child_token = nl_ast_token (child);

      if ( child_token == nl_token_and || child_token == nl_token_or ) {
	nl_ast_token new_token;
	nl_ast new_ast;
	char *file;
	int line;

	if ( child_token == nl_token_and )
	  new_token = nl_token_nand;
	else
	  new_token = nl_token_nor;

	nl_ast_get_file_line (tree, &file, &line);

	new_ast = nl_ast_create (new_token);

	nl_ast_set_file_line (new_ast, file, line);
	nl_ast_set_child (new_ast, child_children);
	nl_ast_set_sibling (new_ast, nl_ast_sibling (tree));

	*root_p = new_ast;

	nl_ast_free (tree);
	nl_ast_free (child);
      }
    }
  }

  return nl_walk_status_continue;
}
  
