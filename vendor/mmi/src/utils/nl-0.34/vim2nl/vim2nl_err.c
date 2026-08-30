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
 * A n t l r  S e t s / E r r o r  F i l e  H e a d e r
 *
 * Generated from: vim.g
 *
 * Terence Parr, Russell Quong, Will Cohen, and Hank Dietz: 1989-1999
 * Parr Research Corporation
 * with Purdue University Electrical Engineering
 * With AHPCRC, University of Minnesota
 * ANTLR Version 1.33MR22
 */

#define ANTLR_VERSION	13322
#include "pcctscfg.h"
#include "pccts_stdio.h"
#define zzparser vim2nl
#include "remap.h"
// -*-Fundamental-*-
#include <assert.h>
#include "port.h"
#include "charptr.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "skip-list.h"
#include "nl.h"
#include "pnl.h"
#include "vim2nl.h"
#include "vim2nl_int.h"

#define USER_ZZSYN

#if 0
#  define AST_FIELDS   int token; char *text;
#  define zzcr_ast(tr, attr, tok, txt) { cr_ast (tr, attr, tok, txt); }
#  define zzmk_ast(tr, tok, txt)	     (AST *) mk_ast (tr, tok, txt)
#endif

#define zzcr_attr(attr, tok, text)	(*(attr) = (text))
#undef  zzd_attr

  
#define zzSET_SIZE 4
#include "antlr.h"
#include "tokens.h"
#include "dlgdef.h"
#include "err.h"

ANTLRChar *vim2nl_zztokens[12]={
	/* 00 */	"Invalid",
	/* 01 */	"@",
	/* 02 */	"VIM_VERSION",
	/* 03 */	"PRTREF",
	/* 04 */	"NET",
	/* 05 */	"USGDEF",
	/* 06 */	"UPIN",
	/* 07 */	"PPIN",
	/* 08 */	"\\n\\+~[\\ ]*",
	/* 09 */	"STRING",
	/* 10 */	"[\\ \\t]+",
	/* 11 */	"EOL"
};
SetWordType zzerr1[4] = {0xbc,0x0,0x0,0x0};
SetWordType setwd1[12] = {0x0,0xfe,0xfd,0xfd,0xfd,0xfd,0x0,
	0xfd,0x0,0x0,0x0,0x0};
SetWordType setwd2[12] = {0x0,0x2,0x2,0x2,0x2,0x2,0x2,
	0x2,0x0,0x3c,0x0,0x19};
