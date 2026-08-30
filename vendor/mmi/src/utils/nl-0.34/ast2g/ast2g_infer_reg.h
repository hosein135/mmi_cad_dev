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

/*
 * S O R C E R E R  T r a n s l a t i o n  H e a d e r
 *
 * SORCERER Developed by Terence Parr, Aaron Sawdey, & Gary Funck
 * Parr Research Corporation, Intrepid Technology, University of Minnesota
 * 1992-1994
 * SORCERER Version 13322
 */


#ifndef AST2G_HEADER
#  define AST2G_HEADER
#  include "port.h"
#  include "mem.h"
#  include "ar.h"
#  include "hashtab.h"
#  include "nl.h"
#endif

#define malloc MALLOC
#define calloc CALLOC
#define realloc REALLOC
#define free FREE

#define USER_DEFINED_AST
/* typedef struct nl_ast_s SORAST; */

#define zzASTright(x)         nl_ast_sibling (x)
#define zzASTright_addr(x)    nl_ast_sibling_addr (x)
#define zzASTdown(x)          nl_ast_child (x)
#define zzASTset_right(x, y)  nl_ast_set_sibling (x, y)
#define zzASTset_down(x, y)   nl_ast_set_child (x, y)
#define zzASTtoken(x)	      nl_ast_token (x)
#define zzASTset_token(x, y)  nl_ast_set_token (x, y)

#define _refvar_inits ast2g_refvar_inits
#define ast2g_no_viable_alt default_no_viable_alt
#define ast2g_mismatched_token default_mismatched_token
extern void ast2g_register(STreeParser *_parser, SORAST **_root, int num_inputs, int num_outputs, int *rst_index_p,
	  int *rst_polarity_p, char *input_sense, ar lhs_outs1, ar rhs_ins1,
 	  ar lhs_outs2, ar rhs_ins2 );
extern void ast2g_sens_item(STreeParser *_parser, SORAST **_root, char *input_sense );
extern void ast2g_body(STreeParser *_parser, SORAST **_root, int *rst_index_p, int *rst_polarity_p,
      ar lhs_outs1, ar rhs_ins1, ar lhs_outs2, ar rhs_ins2 );
extern  int   ast2g_test(STreeParser *_parser, SORAST **_root, int polarity, int *rst_polarity_p );
extern void ast2g_assignments(STreeParser *_parser, SORAST **_root, ar lhs_outs, ar rhs_ins );
extern void ast2g_assignment(STreeParser *_parser, SORAST **_root, ar lhs_outs, ar rhs_ins );
extern void ast2g_lhs(STreeParser *_parser, SORAST **_root, ar outs );
extern void ast2g_rhs(STreeParser *_parser, SORAST **_root, ar ins );
extern void ast2g_constant(STreeParser *_parser, SORAST **_root, ar ins );
extern  int   ast2g_number(STreeParser *_parser, SORAST **_root);
extern  char *  ast2g_vnum(STreeParser *_parser, SORAST **_root);
extern  int   ast2g_in(STreeParser *_parser, SORAST **_root);
extern  int   ast2g_out(STreeParser *_parser, SORAST **_root);
extern void ast2g_begin_name(STreeParser *_parser, SORAST **_root);
