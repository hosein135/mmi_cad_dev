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

  while ( decl != NULL ) {
    nl_token token = nl_ast_token (decl);
    nl_ast range_ast = nl_ast_child (decl);
    nl_type type = v2nl_range_ast_to_type (range_ast);
    nl_id_ast id_ast = (nl_id_ast) nl_ast_sibling (range_ast);

    if ( token == nl_token_input || token == nl_token_reg ) {
      nl_wireclass class;

      if ( token == nl_token_input )
	class = nl_wireclass_input;
      else
	class = nl_wireclass_reg;
	
      while ( id_ast != NULL ) {
	char *name = nl_id_ast_name (id_ast);
	char *buf = MALLOC (strlen (name) + strlen (bus_naming_style) + 16);
	nl_symbol symbol = nl_symbol_create (name, type, class, fun);

	nl_type_for_all_indexes (type, index) {
	  nl_symbol new_sym;

	  sprintf (buf, bus_naming_style, name, index);
	  new_sym = nl_symbol_create (buf, scalar, class, fun);
	  nl_symbol_add_constituent (symbol, new_sym);
	  nl_subprogram_add_symbol (fun, new_sym);
	} nl_end_for;

	if ( token == nl_token_input )
	  nl_subprogram_add_formal (fun, symbol);
	else
	  nl_subprogram_add_local (fun, symbol);

	FREE (buf);
	id_ast = (nl_id_ast) nl_id_ast_sibling (id_ast);
      }
    }
    else if ( token == nl_token_output || token == nl_token_inout ) {
      v2nl_ast_error (decl, "function argument declared as %s; "
		      "function arguments may only be inputs",
		      nl_token_to_string (token));
    }
    else {
      v2nl_ast_error (decl, "function local var declared as %s; "
		      "function locals may only be regs",
		      nl_token_to_string (token));
    }

    decl = nl_ast_sibling (decl);
  }

