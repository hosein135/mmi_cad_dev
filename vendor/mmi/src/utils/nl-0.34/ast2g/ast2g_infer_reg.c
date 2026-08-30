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
#define SORCERER_VERSION	13322
#define SORCERER_NONTRANSFORM
#include "pcctscfg.h"
#include <stdio.h>
#include <setjmp.h>
/* rename error routines; used in macros, must use /lib/cpp */
#define mismatched_token ast2g_mismatched_token
#define mismatched_range ast2g_mismatched_range
#define missing_wildcard ast2g_missing_wildcard
#define no_viable_alt ast2g_no_viable_alt
#define sorcerer_panic ast2g_sorcerer_panic


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
typedef struct nl_ast_s SORAST;

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
#include "sorcerer.h"
#include "ast2g_infer_reg.h"

void
#ifdef __USE_PROTOS
_refvar_inits(STreeParser *p)
#else
_refvar_inits(p)
STreeParser *p;
#endif
{
}


#include "errsupport.c"
#include "ast2g_tokdefs.h"

#undef ast2g_no_viable_alt
#undef ast2g_mismatched_token

static char *input_sense = NULL;
static ar lhs_outs1 = NULL;
static ar rhs_outs2 = NULL;
static ar rhs_ins1 = NULL;
static ar rhs_ins2 = NULL;
static int reset_index = 0;
static int reset_polarity = 0;

static
void
ast2g_no_viable_alt (STreeParser *parser, char *rulename, nl_ast tree)
{
	/* fprintf (stderr, "No viable alt for %s at\n", rulename); */
	/* nl_ast_dump (tree); */
	error_throw (2);
}


static
void
ast2g_mismatched_token (STreeParser *parser, nl_token looking_for, nl_ast tree)
{
	fprintf (stderr, "Token mismatch.  Looking for %s at\n",
	nl_token_to_string (looking_for));
	nl_ast_dump (tree);
	error_throw (2);
}



void ast2g_register(STreeParser *_parser, SORAST **_root, int num_inputs, int num_outputs, int *rst_index_p,
	  int *rst_polarity_p, char *input_sense, ar lhs_outs1, ar rhs_ins1,
 	  ar lhs_outs2, ar rhs_ins2 )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==ALWAYS) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(ALWAYS);
		_DOWN;
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(LIST);
		_DOWN;
		{int _done=0;
		do {
			if ( _t!=NULL && (zzASTtoken(_t)==POSEDGE||zzASTtoken(_t)==NEGEDGE) ) {
				ast2g_sens_item(_parser, &_t,  input_sense );
			}
			else {
			if ( _t==NULL ) {
				_done = 1;
			}
			else {
				if ( _parser->guessing ) _GUESS_FAIL;
				no_viable_alt(_parser, "register", _t);
			}
			}
		} while ( !_done );
		}
		_RESTORE;
		}
		_RIGHT;
		ast2g_body(_parser, &_t,  rst_index_p, rst_polarity_p, lhs_outs1, rhs_ins1,
	           lhs_outs2, rhs_ins2 );
		_RESTORE;
		}
		_RIGHT;
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "register", _t);
	}
	*_root = _t;
}

void ast2g_sens_item(STreeParser *_parser, SORAST **_root, char *input_sense )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==POSEDGE) ) {
		int index;   
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(POSEDGE);
		_DOWN;
		 index =ast2g_in(_parser, &_t);
		_RESTORE;
		}
		_RIGHT;
		input_sense[index] = 'R';   
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==NEGEDGE) ) {
		int index;   
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(NEGEDGE);
		_DOWN;
		 index =ast2g_in(_parser, &_t);
		_RESTORE;
		}
		_RIGHT;
		input_sense[index] = 'F';   
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "sens_item", _t);
	}
	}
	*_root = _t;
}

void ast2g_body(STreeParser *_parser, SORAST **_root, int *rst_index_p, int *rst_polarity_p,
      ar lhs_outs1, ar rhs_ins1, ar lhs_outs2, ar rhs_ins2 )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==IF) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(IF);
		_DOWN;
		 *rst_index_p =ast2g_test(_parser, &_t,  0, rst_polarity_p );
		ast2g_assignments(_parser, &_t,  lhs_outs1, rhs_ins1 );
		ast2g_assignments(_parser, &_t,  lhs_outs2, rhs_ins2 );
		_RESTORE;
		}
		_RIGHT;
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==BEGIN||zzASTtoken(_t)==BLOCK_ASSIGN||
	zzASTtoken(_t)==NONBLOCK_ASSIGN) ) {
		ast2g_assignments(_parser, &_t,  lhs_outs1, rhs_ins1 );
		*rst_index_p = -1; 
		*rst_polarity_p = 0;
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "body", _t);
	}
	}
	*_root = _t;
}

 int   ast2g_test(STreeParser *_parser, SORAST **_root, int polarity, int *rst_polarity_p )
{
	SORAST *_t = *_root;
	 int rst_index ;
	if ( _t!=NULL && (zzASTtoken(_t)==LOGNOT) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(LOGNOT);
		_DOWN;
		 rst_index =ast2g_test(_parser, &_t,  1 - polarity, rst_polarity_p );
		_RESTORE;
		}
		_RIGHT;
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==BITNOT) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(BITNOT);
		_DOWN;
		 rst_index =ast2g_test(_parser, &_t,  1 - polarity, rst_polarity_p );
		_RESTORE;
		}
		_RIGHT;
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==IN) ) {
		 rst_index =ast2g_in(_parser, &_t);
		*rst_polarity_p = polarity;   
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "test", _t);
	}
	}
	}
	*_root = _t;
	return rst_index;
}

void ast2g_assignments(STreeParser *_parser, SORAST **_root, ar lhs_outs, ar rhs_ins )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==BLOCK_ASSIGN||zzASTtoken(_t)==NONBLOCK_ASSIGN) ) {
		ast2g_assignment(_parser, &_t,  lhs_outs, rhs_ins );
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==BEGIN) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(BEGIN);
		_DOWN;
		ast2g_begin_name(_parser, &_t);
		{int _done=0;
		do {
			if ( _t!=NULL && (zzASTtoken(_t)==BEGIN||zzASTtoken(_t)==BLOCK_ASSIGN||
			zzASTtoken(_t)==NONBLOCK_ASSIGN) ) {
				ast2g_assignments(_parser, &_t,  lhs_outs, rhs_ins );
			}
			else {
			if ( _t==NULL ) {
				_done = 1;
			}
			else {
				if ( _parser->guessing ) _GUESS_FAIL;
				no_viable_alt(_parser, "assignments", _t);
			}
			}
		} while ( !_done );
		}
		_RESTORE;
		}
		_RIGHT;
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "assignments", _t);
	}
	}
	*_root = _t;
}

void ast2g_assignment(STreeParser *_parser, SORAST **_root, ar lhs_outs, ar rhs_ins )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==BLOCK_ASSIGN) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(BLOCK_ASSIGN);
		_DOWN;
		ast2g_rhs(_parser, &_t,  rhs_ins );
		ast2g_lhs(_parser, &_t,  lhs_outs );
		if ( _t!=NULL && (zzASTtoken(_t)==DELAY) ) {
			_MATCH(DELAY);
			_RIGHT;
		}
		else {
		if ( _t==NULL ) {
		}
		else {
			if ( _parser->guessing ) _GUESS_FAIL;
			no_viable_alt(_parser, "assignment", _t);
		}
		}
		_RESTORE;
		}
		_RIGHT;
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==NONBLOCK_ASSIGN) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(NONBLOCK_ASSIGN);
		_DOWN;
		ast2g_rhs(_parser, &_t,  rhs_ins );
		ast2g_lhs(_parser, &_t,  lhs_outs );
		if ( _t!=NULL && (zzASTtoken(_t)==DELAY) ) {
			_MATCH(DELAY);
			_RIGHT;
		}
		else {
		if ( _t==NULL ) {
		}
		else {
			if ( _parser->guessing ) _GUESS_FAIL;
			no_viable_alt(_parser, "assignment", _t);
		}
		}
		_RESTORE;
		}
		_RIGHT;
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "assignment", _t);
	}
	}
	*_root = _t;
}

void ast2g_lhs(STreeParser *_parser, SORAST **_root, ar outs )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==OUT) ) {
		int index;   
		 index =ast2g_out(_parser, &_t);
		ar_add (outs, &index);   
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==CONCAT) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(CONCAT);
		_DOWN;
		{int _done=0;
		do {
			if ( _t!=NULL && (zzASTtoken(_t)==CONCAT||zzASTtoken(_t)==OUT) ) {
				ast2g_lhs(_parser, &_t,  outs );
			}
			else {
			if ( _t==NULL ) {
				_done = 1;
			}
			else {
				if ( _parser->guessing ) _GUESS_FAIL;
				no_viable_alt(_parser, "lhs", _t);
			}
			}
		} while ( !_done );
		}
		_RESTORE;
		}
		_RIGHT;
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "lhs", _t);
	}
	}
	*_root = _t;
}

void ast2g_rhs(STreeParser *_parser, SORAST **_root, ar ins )
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==IN) ) {
		int index;   
		 index =ast2g_in(_parser, &_t);
		ar_add (ins, &index);   
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==CONCAT) ) {
		{_SAVE; TREE_CONSTR_PTRS;
		_MATCH(CONCAT);
		_DOWN;
		{int _done=0;
		do {
			if ( _t!=NULL && (zzASTtoken(_t)==CONCAT||zzASTtoken(_t)==BIN_RADIX||
			zzASTtoken(_t)==HEX_RADIX||zzASTtoken(_t)==DEC_RADIX||zzASTtoken(_t)==OCT_RADIX||
			zzASTtoken(_t)==NUMBER||zzASTtoken(_t)==IN) ) {
				ast2g_rhs(_parser, &_t,  ins );
			}
			else {
			if ( _t==NULL ) {
				_done = 1;
			}
			else {
				if ( _parser->guessing ) _GUESS_FAIL;
				no_viable_alt(_parser, "rhs", _t);
			}
			}
		} while ( !_done );
		}
		_RESTORE;
		}
		_RIGHT;
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==BIN_RADIX||zzASTtoken(_t)==HEX_RADIX||
	zzASTtoken(_t)==DEC_RADIX||zzASTtoken(_t)==OCT_RADIX||zzASTtoken(_t)==NUMBER) ) {
		ast2g_constant(_parser, &_t,  ins );
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "rhs", _t);
	}
	}
	}
	*_root = _t;
}

void ast2g_constant(STreeParser *_parser, SORAST **_root, ar ins )
{
	SORAST *_t = *_root;
	SORAST *n_ast=NULL;
	if ( _t!=NULL && (zzASTtoken(_t)==BIN_RADIX||zzASTtoken(_t)==HEX_RADIX||
	zzASTtoken(_t)==DEC_RADIX||zzASTtoken(_t)==OCT_RADIX) ) {
		int n;
		int num;
		char *bits;
		char r;
		if ( _t!=NULL && (zzASTtoken(_t)==BIN_RADIX) ) {
			{_SAVE; TREE_CONSTR_PTRS;
			_MATCH(BIN_RADIX);
			_DOWN;
			 n =ast2g_number(_parser, &_t);
			 bits =ast2g_vnum(_parser, &_t);
			_RESTORE;
			}
			_RIGHT;
			r = 'b';   
		}
		else {
		if ( _t!=NULL && (zzASTtoken(_t)==HEX_RADIX) ) {
			{_SAVE; TREE_CONSTR_PTRS;
			_MATCH(HEX_RADIX);
			_DOWN;
			 n =ast2g_number(_parser, &_t);
			 bits =ast2g_vnum(_parser, &_t);
			_RESTORE;
			}
			_RIGHT;
			r = 'h';   
		}
		else {
		if ( _t!=NULL && (zzASTtoken(_t)==DEC_RADIX) ) {
			{_SAVE; TREE_CONSTR_PTRS;
			_MATCH(DEC_RADIX);
			_DOWN;
			 n =ast2g_number(_parser, &_t);
			 bits =ast2g_vnum(_parser, &_t);
			_RESTORE;
			}
			_RIGHT;
			r = 'd';   
		}
		else {
		if ( _t!=NULL && (zzASTtoken(_t)==OCT_RADIX) ) {
			{_SAVE; TREE_CONSTR_PTRS;
			_MATCH(OCT_RADIX);
			_DOWN;
			 n =ast2g_number(_parser, &_t);
			 bits =ast2g_vnum(_parser, &_t);
			_RESTORE;
			}
			_RIGHT;
			r = 'o';   
		}
		else {
			if ( _parser->guessing ) _GUESS_FAIL;
			no_viable_alt(_parser, "constant", _t);
		}
		}
		}
		}
		ast2g_get_constant_ins (n, r, bits, ins);   
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==NUMBER) ) {
		int width;
		int num;
		char *digits;
		n_ast=(SORAST *)_t;  num =ast2g_number(_parser, &_t);
		width = nl_ast_width (n_ast);
		digits = alloca (16);
		sprintf (digits, "%d", num);
		ast2g_get_constant_ins (width, 'd', digits, ins);
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "constant", _t);
	}
	}
	*_root = _t;
}

 int   ast2g_number(STreeParser *_parser, SORAST **_root)
{
	SORAST *_t = *_root;
	 int result ;
	SORAST *n=NULL;
	if ( _t!=NULL && (zzASTtoken(_t)==NUMBER) ) {
		_MATCH(NUMBER);
		n=(SORAST *)_t;
		_RIGHT;
		result = nl_number_ast_value ((nl_number_ast) n);   
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "number", _t);
	}
	*_root = _t;
	return result;
}

 char *  ast2g_vnum(STreeParser *_parser, SORAST **_root)
{
	SORAST *_t = *_root;
	 char *result ;
	SORAST *n=NULL;
	if ( _t!=NULL && (zzASTtoken(_t)==VERILOG_NUMBER) ) {
		_MATCH(VERILOG_NUMBER);
		n=(SORAST *)_t;
		_RIGHT;
		result = nl_vnum_ast_bits ((nl_vnum_ast) n);   
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "vnum", _t);
	}
	*_root = _t;
	return result;
}

 int   ast2g_in(STreeParser *_parser, SORAST **_root)
{
	SORAST *_t = *_root;
	 int index ;
	SORAST *n=NULL;
	if ( _t!=NULL && (zzASTtoken(_t)==IN) ) {
		_MATCH(IN);
		n=(SORAST *)_t;
		_RIGHT;
		index = nl_in_ast_index ((nl_in_ast) n);   
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "in", _t);
	}
	*_root = _t;
	return index;
}

 int   ast2g_out(STreeParser *_parser, SORAST **_root)
{
	SORAST *_t = *_root;
	 int index ;
	SORAST *n=NULL;
	if ( _t!=NULL && (zzASTtoken(_t)==OUT) ) {
		_MATCH(OUT);
		n=(SORAST *)_t;
		_RIGHT;
		index = nl_out_ast_index ((nl_out_ast) n);   
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "out", _t);
	}
	*_root = _t;
	return index;
}

void ast2g_begin_name(STreeParser *_parser, SORAST **_root)
{
	SORAST *_t = *_root;
	if ( _t!=NULL && (zzASTtoken(_t)==LIST) ) {
		_MATCH(LIST);
		_RIGHT;
	}
	else {
	if ( _t!=NULL && (zzASTtoken(_t)==ID) ) {
		_MATCH(ID);
		_RIGHT;
	}
	else {
		if ( _parser->guessing ) _GUESS_FAIL;
		no_viable_alt(_parser, "begin_name", _t);
	}
	}
	*_root = _t;
}
