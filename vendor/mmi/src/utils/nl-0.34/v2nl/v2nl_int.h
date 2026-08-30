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

extern nl_design v2nl_current_design;
extern nl_subprogram v2nl_current_subprogram;
extern char *   v2nl_current_file;
extern void     v2nl_mod (char *);
extern void	v2nl_endmod (void);
extern void     v2nl_port (char *);
extern int	v2nl_translate_integer (char *);
extern ar       v2nl_get_constant_nets (int, char, char *);
extern nl_reference v2nl_reference (char *, ar);
extern nl_cell  v2nl_cell (nl_reference, Attrib *);
extern nl_reference v2nl_primitive_reference (Attrib *);
extern nl_cell  v2nl_primitive_gate (char *, nl_reference, nl_type, ar,
				     char *, int);
extern void     v2nl_pins (nl_cell, char *, ar);
extern void     v2nl_assign (ar, ar, Attrib *);
extern void     v2nl_variable (nl_wireclass, nl_direction, nl_type, char *);
extern void 	v2nl_declare_rtl_var (nl_subprogram, nl_wireclass, nl_type,
				      char *);
extern nl_type  v2nl_scalar (void);
extern nl_type  v2nl_integer (void);
extern nl_type  v2nl_array (int, int);
extern ar       v2nl_get_net_or_bus_nets (nl_object);
extern ar       v2nl_get_bus_slice (nl_object, int, int);
extern ar       v2nl_var_ref (char *);
extern ar       v2nl_var_bit (char *, int);
extern ar       v2nl_var_slice (char *, int, int);
extern ar       v2nl_shift_left (ar, int);
extern ar       v2nl_shift_right (ar, int);
extern ar       v2nl_repeat_concat (int, ar);
extern ar       v2nl_get_integer (int);
extern void     v2nl_parameter (char *, nl_ast);
extern int      v2nl_get_parameter (char *, nl_ast *);
extern void     v2nl_rtl_allow_implicit_wires (int);
extern nl_ast   v2nl_rtl_var_ref (Attrib *, int *);
extern nl_ast   v2nl_make_shift (nl_ast, nl_ast, nl_ast);
extern nl_ast   v2nl_function_call (nl_ast);
extern void	v2nl_new_attribute (char *, nl_density, char, char);
extern void	v2nl_begin_boolean_attribute (char *);
extern void	v2nl_begin_integer_attribute (char *, int);
extern void	v2nl_begin_string_attribute (char *, char *);
extern void	v2nl_end_attribute (char *);
extern void     v2nl_set_attributes (nl_object);


extern nl_ast   v2nl_cr_ast (nl_ast, Attrib *, int);
extern void     v2nl_d_ast (nl_ast);
extern void     v2nl_dump (nl_ast, int);
extern int      v2nl_eval_expr (nl_ast, int *);
extern int      v2nl_eval_integer_expr (nl_ast);
extern nl_ast   v2nl_make_integer_ast (int);
extern int      v2nl_is_expr_trivial (nl_ast);
extern void     v2nl_do_rtl_assign (ar, nl_ast, Attrib *);
extern ar       v2nl_trivial_expr_to_nets (nl_ast);
extern nl_ast   v2nl_rewrite_ref_slice (nl_ast, nl_subprogram);
extern void	v2nl_create_process (nl_ast);
extern nl_subprogram v2nl_create_function (char *, nl_type);
extern void     v2nl_add_function_pragmas (nl_subprogram, nl_ast);
extern void     v2nl_add_function_body (nl_subprogram, nl_ast);
extern ar	v2nl_random_expr (nl_ast);

extern void v2nl_lex_cleanup (void);
extern void v2nl_free_macro_table (void);
extern int  v2nl_translate_off;
extern int  v2nl_dc_script;
extern int  v2nl_line_comment;
extern int  v2nl_is_pragma_begin (char *);
extern void v2nl_define_macro (char *, char *, int);
extern void v2nl_undef_macro (char *);
extern void v2nl_wrap (void);
extern void v2nl_do_macro_definition (char *);
extern void v2nl_do_macro_undef (char *);
extern void v2nl_do_macro_expansion (char *);
extern void v2nl_do_include_file (char *);
extern void v2nl_do_ifdef (char *);
extern void v2nl_do_else (char *);
extern void v2nl_do_endif (char *);
extern void v2nl_maybe_end_comment (char *);
extern void v2nl_ports_only_gettok (void);
typedef void (*gettok_fun) (void);
extern const gettok_fun v2nl_current_gettok;
extern void v2nl_process_escaped_id (void);
extern void v2nl_lex_add_escaped_translation (char *, char *);
extern void v2nl_lex_end_escaped_translation (void);

extern void v2nl_failed_predicate (char *text);
extern void v2nl_error (const char *, ...) NORETURN;
extern void v2nl_ast_error (nl_ast, const char *, ...) NORETURN;
extern void v2nl_warning (const char *, ...);
extern void v2nl_ast_warning (nl_ast, const char *, ...);

extern int v2nl_ports_only;
extern int v2nl_ports_only_skip;
extern int v2nl_rtl;
extern mem_group v2nl_mem_group;

/* v2nl_rewrites.ee */
extern nl_ast v2nl_lhs_ref_to_lref (nl_ast);
extern nl_ast v2nl_rewrite_var_shift (nl_ast);
extern nl_ast v2nl_if_to_case (nl_ast);
extern nl_ast v2nl_remove_useless_concats (nl_ast);
