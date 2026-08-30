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

#ifndef STDPCCTS_def_parse_H
#define STDPCCTS_def_parse_H
/*
 * Standard PCCTS include file with -fh def_parse.h -- P C C T S  I n c l u d e
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-1999
 * Purdue University Electrical Engineering
 * With AHPCRC, University of Minnesota
 * ANTLR Version 1.33MR22
 */

#ifndef ANTLR_VERSION
#define ANTLR_VERSION	13322
#endif

#include "pcctscfg.h"
#include "pccts_stdio.h"
#define zzparser def
#include "remap.h"

#include <assert.h>
#include <stdio.h>
#include <stdarg.h>
#include "def2max.h"

// TODO: Redefine zzsyn from $MMI_UTILS/pccts/h/err.h to provide better error messages.
//#define USER_ZZSYN

// I dont think this is needed:
//#define ZZCOL

#define ZZLEXBUFSIZE 2050	/* DEF doc says 2048 max */
#define ZZA_STACKSIZE 400	/* way overkill */

#define zzfailed_pred(_p)     def2max_failed_pred(_p);

// This is a clever way to get the error routines for the parser to go to the
// max error printer, without rewriting all the routines.
// This must be here in the header so the .h file included by the lexer gets this too.
#define fprintf def_parse_fprintf

extern int def2max_pre_comment_mode;

#define NEXT_LINE if (++zzline%10000==0) {printf("\r%d ",zzline);fflush(stdout);}

  
#define zzSET_SIZE 16
#include "antlr.h"
#include "tokens.h"
#include "dlgdef.h"
#include "mode.h"
#endif
