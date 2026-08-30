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

extern int ast2g_op_count;
void ast2g_get_constant (int, char, char *, ar);
ar ast2g_expression (ssa_context, nl_design, nl_ast, ar, ar);
void ast2g_statement (ssa_context, nl_design, nl_ast, ar, ar);
void ast2g_connect_nets (nl_net, nl_net, char *, int);
nl_reference ast2g_get_reference (nl_design, char *, ...);
nl_net ast2g_get_net (ssa_context, nl_design, char *);
/* int ast2g_infer_registers_for_reference (nl_reference); */
nl_reference ast2g_get_parameterized_ref (nl_design, char *, ...);
nl_net ast2g_create_new_net (nl_design, char *, int);
ar ast2g_create_new_bus (nl_design, int, char *, int);
nl_cell ast2g_create_new_cell (char *, nl_reference, char *, int, int);
void ast2g_connect_pin_bus (nl_cell, nl_bus, ar, int);
ar ast2g_build_mux (nl_design, int, ar, ar, char *, int);
int ast2g_eval_constant (nl_ast const_ast);
void ast2g_walk_constant (int, char, char *,
			  void make_one (void *, int), void *);

/* ast2g_error.c */
void ast2g_error (const char *, ...) NORETURN;
void ast2g_ast_error (nl_ast, const char *, ...) NORETURN;
void ast2g_warning (const char *, ...);
void ast2g_ast_warning (nl_ast, const char *, ...);


/* ast2g_rewrites.c */
nl_ast ast2g_eliminate_logical_ops (nl_ast);
nl_ast ast2g_simplify_reduce_ops (nl_ast);
nl_ast ast2g_explicit_case (nl_ast);
nl_ast ast2g_rewrite_clocks (nl_ast);
nl_ast ast2g_flip_cases (nl_ast);
nl_ast ast2g_flatten_concats (nl_ast);
nl_ast ast2g_infer_inverting_ops (nl_ast);
nl_ast ast2g_flatten_logic_trees (nl_ast);

/* ast2g.c */
void ast2g_define (ssa_context, nl_object, nl_net);
void ast2g_define_future (ssa_context, nl_object, nl_net);
nl_net ast2g_read (ssa_context, nl_object);
nl_net ast2g_read_final (ssa_context, nl_object);


/* ast2g_util.c */
void ast2g_get_clocks (nl_ast, nl_net *, nl_token *, ar);
void ast2g_register_net (nl_net, nl_net, nl_net, nl_token, nl_net, nl_token,
			 int, char *, int);
void ast2g_find_reset_preset (nl_design, ar, ar, ar, ar, ar);
nl_reference ast2g_build_reference_for_function (nl_subprogram,
						 char *, char *);

/* ast2g_typebal.c */
nl_ast ast2g_type_balance (nl_ast);
nl_ast ast2g_type_balance_expression (int, nl_ast);
void ast2g_update_widths (nl_ast tree);



