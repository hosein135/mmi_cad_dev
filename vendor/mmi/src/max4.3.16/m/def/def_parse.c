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
 * A n t l r  T r a n s l a t i o n  H e a d e r
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-1999
 * Purdue University Electrical Engineering
 * With AHPCRC, University of Minnesota
 * ANTLR Version 1.33MR22
 *
 *   /volume/mmi/utils/pccts/bin.sparc-solaris2/antlr -gl -fl def_lex.dlg -fe def_parse_err.c -fh def_parse.h def_parse.g
 *
 */

#define ANTLR_VERSION	13322
#include "pcctscfg.h"
#include "pccts_stdio.h"
#define zzparser def
#include "remap.h"
#line 1 "def_parse.g"

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
#ifndef PURIFY
#define PURIFY(r,s) memset((char *) &(r),'\0',(s));
#endif
ANTLR_INFO
#line 31 "def_parse.g"

#include "database.h"
#define ID_MODE	 zzmode (IDENTIFIER)

int def_parse_fprintf(FILE*somewhere,char *fmt, ...)
{
	va_list args;
	va_start(args,fmt);
	if (somewhere==stderr) {
		MsgErrorV(fmt,args);
	} else {
		vfprintf(somewhere,fmt,args);
	}
	va_end(args);
	return 0;
}

//static char *stralloc(char *s) {return strcpy((char*)malloc(strlen(s)+1),s);}

int def2max_pre_comment_mode;

void
#ifdef __USE_PROTOS
def_file(void)
#else
def_file()
#endif
{
#line 215 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 215 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (setwd1[LA(1)]&0x1) ) {
#line 215 "def_parse.g"
			header();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 216 "def_parse.g"
	def_design();
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x2);
	}
}

void
#ifdef __USE_PROTOS
header(void)
#else
header()
#endif
{
#line 219 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	if ( (LA(1)==DEF_VERSION) ) {
#line 219 "def_parse.g"
		version();
	}
	else {
		if ( (LA(1)==DEF_NAMESCASESENSITIVE) ) {
#line 220 "def_parse.g"
			namescasesensitive();
		}
		else {
			if ( (LA(1)==DEF_DIVIDERCHAR) ) {
#line 221 "def_parse.g"
				dividerchar();
			}
			else {
				if ( (LA(1)==DEF_BUSBITCHARS) ) {
#line 222 "def_parse.g"
					busbitchars();
				}
				else {zzFAIL(1,zzerr1,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x4);
	}
}

void
#ifdef __USE_PROTOS
version(void)
#else
version()
#endif
{
#line 225 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 225 "def_parse.g"
	zzmatch(DEF_VERSION);
#line 225 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 225 "def_parse.g"
	zzmatch(DEF_IDENT); zzCONSUME;
#line 225 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x8);
	}
}

void
#ifdef __USE_PROTOS
namescasesensitive(void)
#else
namescasesensitive()
#endif
{
#line 228 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 229 "def_parse.g"
	zzmatch(DEF_NAMESCASESENSITIVE); zzCONSUME;
#line 230 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_ON) ) {
#line 230 "def_parse.g"
			zzmatch(DEF_ON);
#line 230 "def_parse.g"
			def2max_case_sensitive(1);
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_OFF) ) {
#line 231 "def_parse.g"
				zzmatch(DEF_OFF);
#line 231 "def_parse.g"
				def2max_case_sensitive(0);
 zzCONSUME;

			}
			else {zzFAIL(1,zzerr2,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		zzEXIT(zztasp2);
		}
	}
#line 232 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x10);
	}
}

void
#ifdef __USE_PROTOS
dividerchar(void)
#else
dividerchar()
#endif
{
#line 235 "def_parse.g"
	zzRULE;
	Attrib str;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 235 "def_parse.g"
	zzmatch(DEF_DIVIDERCHAR); zzCONSUME;
#line 235 "def_parse.g"
	zzmatch(DEF_QUOTED);
	str = zzaCur;

#line 236 "def_parse.g"
	def2max_divider_char ( str.text);
 zzCONSUME;

#line 237 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x20);
	}
}

void
#ifdef __USE_PROTOS
busbitchars(void)
#else
busbitchars()
#endif
{
#line 240 "def_parse.g"
	zzRULE;
	Attrib str;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 240 "def_parse.g"
	zzmatch(DEF_BUSBITCHARS); zzCONSUME;
#line 240 "def_parse.g"
	zzmatch(DEF_QUOTED);
	str = zzaCur;

#line 241 "def_parse.g"
	def2max_busbit_char( str.text);
 zzCONSUME;

#line 242 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x40);
	}
}

void
#ifdef __USE_PROTOS
def_design(void)
#else
def_design()
#endif
{
#line 245 "def_parse.g"
	zzRULE;
	Attrib name;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 245 "def_parse.g"
	zzmatch(DEF_DESIGN);
#line 245 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 245 "def_parse.g"
	zzmatch(DEF_IDENT);
	name = zzaCur;

#line 246 "def_parse.g"
	def2max_design ( name.text);
 zzCONSUME;

#line 247 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
#line 248 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (setwd1[LA(1)]&0x80) ) {
#line 248 "def_parse.g"
			declaration();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 249 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (setwd2[LA(1)]&0x1) ) {
#line 249 "def_parse.g"
			constituent();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 250 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 250 "def_parse.g"
	zzmatch(DEF_DESIGN); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x2);
	}
}

void
#ifdef __USE_PROTOS
declaration(void)
#else
declaration()
#endif
{
#line 253 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	if ( (LA(1)==DEF_UNITS) ) {
#line 253 "def_parse.g"
		units_decl();
	}
	else {
		if ( (LA(1)==DEF_DIEAREA) ) {
#line 254 "def_parse.g"
			diearea_decl();
		}
		else {
			if ( (LA(1)==DEF_TRACKS) ) {
#line 255 "def_parse.g"
				tracks_decl();
			}
			else {
				if ( (LA(1)==DEF_HISTORY) ) {
#line 256 "def_parse.g"
					history_decl();
				}
				else {
					if ( (LA(1)==DEF_ROW) ) {
#line 257 "def_parse.g"
						row_decl();
					}
					else {
						if ( (LA(1)==DEF_PROPERTYDEFINITIONS) ) {
#line 258 "def_parse.g"
							propertydefinitions_decl();
						}
						else {
							if ( (LA(1)==DEF_GCELLGRID) ) {
#line 259 "def_parse.g"
								gcellgrid_decl();
							}
							else {zzFAIL(1,zzerr3,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
						}
					}
				}
			}
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x4);
	}
}

void
#ifdef __USE_PROTOS
units_decl(void)
#else
units_decl()
#endif
{
#line 262 "def_parse.g"
	zzRULE;
	Attrib id;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 262 "def_parse.g"
	char name[2050];
	int num;
#line 265 "def_parse.g"
	zzmatch(DEF_UNITS); zzCONSUME;
#line 265 "def_parse.g"
	zzmatch(DEF_DISTANCE);
#line 265 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 266 "def_parse.g"
	zzmatch(DEF_IDENT);
	id = zzaCur;

#line 266 "def_parse.g"
	strcpy(name, id.text);
 zzCONSUME;

#line 267 "def_parse.g"
	 num  = number();

#line 268 "def_parse.g"
	zzmatch(DEF_SEMI);
#line 269 "def_parse.g"
	def2max_distance_units (name, num);
 zzCONSUME;

	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x8);
	}
}

void
#ifdef __USE_PROTOS
diearea_decl(void)
#else
diearea_decl()
#endif
{
#line 272 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 272 "def_parse.g"
	int x0, y0;
	int x1, y1;
#line 275 "def_parse.g"
	zzmatch(DEF_DIEAREA); zzCONSUME;
#line 275 "def_parse.g"
	{ struct _rv42 _trv; _trv = coordinate();

	x0 = _trv.x; y0  = _trv.y; }
#line 275 "def_parse.g"
	{ struct _rv42 _trv; _trv = coordinate();

	x1 = _trv.x; y1  = _trv.y; }
#line 276 "def_parse.g"
	zzmatch(DEF_SEMI);
#line 277 "def_parse.g"
	def2max_die_area (x0, y0, x1, y1);
 zzCONSUME;

	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x10);
	}
}

void
#ifdef __USE_PROTOS
tracks_decl(void)
#else
tracks_decl()
#endif
{
#line 280 "def_parse.g"
	zzRULE;
	Attrib id;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 280 "def_parse.g"
	zzmatch(DEF_TRACKS); zzCONSUME;
#line 281 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_X) ) {
#line 281 "def_parse.g"
			zzmatch(DEF_X); zzCONSUME;
		}
		else {
			if ( (LA(1)==DEF_Y) ) {
#line 281 "def_parse.g"
				zzmatch(DEF_Y); zzCONSUME;
			}
			else {zzFAIL(1,zzerr4,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		zzEXIT(zztasp2);
		}
	}
#line 282 "def_parse.g"
	number_discarded();
#line 283 "def_parse.g"
	zzmatch(DEF_DO); zzCONSUME;
#line 283 "def_parse.g"
	number_discarded();
#line 284 "def_parse.g"
	zzmatch(DEF_STEP); zzCONSUME;
#line 284 "def_parse.g"
	number_discarded();
#line 285 "def_parse.g"
	zzmatch(DEF_LAYER);
#line 285 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 286 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		int zzcnt=1;
		zzMake0;
		{
		do {
#line 286 "def_parse.g"
			zzmatch(DEF_IDENT);
			id = zzaCur;

#line 286 "def_parse.g"
			ID_MODE;
 zzCONSUME;

			zzLOOP(zztasp2);
		} while ( (LA(1)==DEF_IDENT) );
		zzEXIT(zztasp2);
		}
	}
#line 287 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x20);
	}
}

void
#ifdef __USE_PROTOS
history_decl(void)
#else
history_decl()
#endif
{
#line 290 "def_parse.g"
	zzRULE;
	Attrib hist;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 290 "def_parse.g"
	zzmatch(DEF_HISTORY);
#line 290 "def_parse.g"
	zzmode (LEX_HISTORY);
 zzCONSUME;

#line 290 "def_parse.g"
	zzmatch(DEF_HISTORY_LIST);
	hist = zzaCur;

#line 291 "def_parse.g"
	def2max_history ( hist.text);
 zzCONSUME;

	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x40);
	}
}

void
#ifdef __USE_PROTOS
row_decl(void)
#else
row_decl()
#endif
{
#line 294 "def_parse.g"
	zzRULE;
	Attrib name_id, core_id;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 295 "def_parse.g"
	zzmatch(DEF_ROW);
#line 295 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 296 "def_parse.g"
	zzmatch(DEF_IDENT);
	name_id = zzaCur;

#line 296 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 297 "def_parse.g"
	zzmatch(DEF_IDENT);
	core_id = zzaCur;
 zzCONSUME;
#line 298 "def_parse.g"
	number_discarded();
#line 298 "def_parse.g"
	number_discarded();
#line 298 "def_parse.g"
	orientation();
#line 299 "def_parse.g"
	zzmatch(DEF_DO); zzCONSUME;
#line 299 "def_parse.g"
	number_discarded();
#line 299 "def_parse.g"
	zzmatch(DEF_BY); zzCONSUME;
#line 299 "def_parse.g"
	number_discarded();
#line 300 "def_parse.g"
	zzmatch(DEF_STEP); zzCONSUME;
#line 300 "def_parse.g"
	number_discarded();
#line 300 "def_parse.g"
	number_discarded();
#line 301 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x80);
	}
}

void
#ifdef __USE_PROTOS
gcellgrid_decl(void)
#else
gcellgrid_decl()
#endif
{
#line 304 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 304 "def_parse.g"
	zzmatch(DEF_GCELLGRID); zzCONSUME;
#line 304 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_X) ) {
#line 304 "def_parse.g"
			zzmatch(DEF_X); zzCONSUME;
		}
		else {
			if ( (LA(1)==DEF_Y) ) {
#line 304 "def_parse.g"
				zzmatch(DEF_Y); zzCONSUME;
			}
			else {zzFAIL(1,zzerr5,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		zzEXIT(zztasp2);
		}
	}
#line 304 "def_parse.g"
	number_discarded();
#line 305 "def_parse.g"
	zzmatch(DEF_DO); zzCONSUME;
#line 305 "def_parse.g"
	number_discarded();
#line 305 "def_parse.g"
	zzmatch(DEF_STEP); zzCONSUME;
#line 305 "def_parse.g"
	number_discarded();
#line 305 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x1);
	}
}

void
#ifdef __USE_PROTOS
propertydefinitions_decl(void)
#else
propertydefinitions_decl()
#endif
{
#line 308 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 309 "def_parse.g"
	zzmatch(DEF_PROPERTYDEFINITIONS); zzCONSUME;
#line 310 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==DEF_DESIGN) ) {
#line 310 "def_parse.g"
			propertydefinition();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 311 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 311 "def_parse.g"
	zzmatch(DEF_PROPERTYDEFINITIONS); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x2);
	}
}

void
#ifdef __USE_PROTOS
propertydefinition(void)
#else
propertydefinition()
#endif
{
#line 314 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 315 "def_parse.g"
	zzmatch(DEF_DESIGN); zzCONSUME;
#line 315 "def_parse.g"
	zzmatch(DEF_VERILOGDESIGNNAME); zzCONSUME;
#line 316 "def_parse.g"
	zzmatch(DEF_STRING); zzCONSUME;
#line 316 "def_parse.g"
	zzmatch(DEF_QUOTED); zzCONSUME;
#line 316 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x4);
	}
}

void
#ifdef __USE_PROTOS
constituent(void)
#else
constituent()
#endif
{
#line 319 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	if ( (LA(1)==DEF_VIAS) ) {
#line 319 "def_parse.g"
		vias();
	}
	else {
		if ( (LA(1)==DEF_COMPONENTS) ) {
#line 320 "def_parse.g"
			components();
		}
		else {
			if ( (LA(1)==DEF_SPECIALNETS) ) {
#line 321 "def_parse.g"
				specialnets();
			}
			else {
				if ( (LA(1)==DEF_NETS) ) {
#line 322 "def_parse.g"
					nets();
				}
				else {
					if ( (LA(1)==DEF_PINS) ) {
#line 323 "def_parse.g"
						pins();
					}
					else {zzFAIL(1,zzerr6,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x8);
	}
}

void
#ifdef __USE_PROTOS
vias(void)
#else
vias()
#endif
{
#line 326 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 326 "def_parse.g"
	zzmatch(DEF_VIAS); zzCONSUME;
#line 326 "def_parse.g"
	number_discarded();
#line 326 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
#line 327 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==111) ) {
#line 327 "def_parse.g"
			via();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 328 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 328 "def_parse.g"
	zzmatch(DEF_VIAS); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x10);
	}
}

void
#ifdef __USE_PROTOS
via(void)
#else
via()
#endif
{
#line 331 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 331 "def_parse.g"
	zzmatch(111);
#line 331 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 331 "def_parse.g"
	zzmatch(DEF_IDENT); zzCONSUME;
#line 331 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==DEF_PLUS) ) {
#line 331 "def_parse.g"
			via_plus();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 331 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x20);
	}
}

void
#ifdef __USE_PROTOS
via_plus(void)
#else
via_plus()
#endif
{
#line 334 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 334 "def_parse.g"
	zzmatch(DEF_PLUS); zzCONSUME;
#line 334 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
#line 334 "def_parse.g"
		rect_clause();
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x40);
	}
}

void
#ifdef __USE_PROTOS
components(void)
#else
components()
#endif
{
#line 337 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 337 "def_parse.g"
	zzmatch(DEF_COMPONENTS); zzCONSUME;
#line 337 "def_parse.g"
	number_discarded();
#line 337 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
#line 338 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==111) ) {
#line 338 "def_parse.g"
			component();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 339 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 339 "def_parse.g"
	zzmatch(DEF_COMPONENTS); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd3, 0x80);
	}
}

void
#ifdef __USE_PROTOS
component(void)
#else
component()
#endif
{
#line 342 "def_parse.g"
	zzRULE;
	Attrib i, m;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 342 "def_parse.g"
	char inst_name[ZZLEXBUFSIZE];
	char mod_name[ZZLEXBUFSIZE];
#line 345 "def_parse.g"
	zzmatch(111);
#line 345 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 345 "def_parse.g"
	zzmatch(DEF_IDENT);
	i = zzaCur;

#line 346 "def_parse.g"
	strcpy(inst_name,  i.text);
	ID_MODE;
 zzCONSUME;

#line 349 "def_parse.g"
	zzmatch(DEF_IDENT);
	m = zzaCur;

#line 350 "def_parse.g"
	strcpy(mod_name, m.text);
 zzCONSUME;

#line 351 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==DEF_PLUS) ) {
#line 351 "def_parse.g"
			component_plus( inst_name, mod_name );
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 351 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x1);
	}
}

void
#ifdef __USE_PROTOS
pins(void)
#else
pins()
#endif
{
#line 354 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 354 "def_parse.g"
	zzmatch(DEF_PINS); zzCONSUME;
#line 354 "def_parse.g"
	number_discarded();
#line 354 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
#line 355 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==111) ) {
#line 355 "def_parse.g"
			pin();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 356 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 356 "def_parse.g"
	zzmatch(DEF_PINS); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x2);
	}
}

void
#ifdef __USE_PROTOS
pin(void)
#else
pin()
#endif
{
#line 359 "def_parse.g"
	zzRULE;
	Attrib n;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 359 "def_parse.g"
	defparse_place portbuf;
#line 360 "def_parse.g"
	zzmatch(111);
#line 360 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 360 "def_parse.g"
	zzmatch(DEF_IDENT);
	n = zzaCur;

#line 361 "def_parse.g"
	strcpy(portbuf.name, n.text);
	portbuf.x = portbuf.y = 0;
	portbuf.iotype = LAB_COMMENT;	// TODO: default should be what?
	portbuf.layer[0] = 0;
 zzCONSUME;

#line 366 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==DEF_PLUS) ) {
#line 366 "def_parse.g"
			pin_plus( &portbuf );
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 366 "def_parse.g"
	zzmatch(DEF_SEMI);
#line 366 "def_parse.g"
	def2max_port(&portbuf);
 zzCONSUME;

	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x4);
	}
}

void
#ifdef __USE_PROTOS
nets(void)
#else
nets()
#endif
{
#line 369 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 369 "def_parse.g"
	zzmatch(DEF_NETS); zzCONSUME;
#line 369 "def_parse.g"
	number_discarded();
#line 369 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
#line 370 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==111) ) {
#line 370 "def_parse.g"
			net( 0 );
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 371 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 371 "def_parse.g"
	zzmatch(DEF_NETS); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x8);
	}
}

void
#ifdef __USE_PROTOS
specialnets(void)
#else
specialnets()
#endif
{
#line 374 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 374 "def_parse.g"
	zzmatch(DEF_SPECIALNETS); zzCONSUME;
#line 374 "def_parse.g"
	number_discarded();
#line 374 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
#line 375 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==111) ) {
#line 375 "def_parse.g"
			net( 1 );
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 376 "def_parse.g"
	zzmatch(DEF_END); zzCONSUME;
#line 376 "def_parse.g"
	zzmatch(DEF_SPECIALNETS); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x10);
	}
}

void
#ifdef __USE_PROTOS
net( int special )
#else
net(special)
 int special ;
#endif
{
#line 379 "def_parse.g"
	zzRULE;
	Attrib id;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 380 "def_parse.g"
	pnl_net pnet;
#line 381 "def_parse.g"
	zzmatch(111);
#line 381 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 381 "def_parse.g"
	zzmatch(DEF_IDENT);
	id = zzaCur;

#line 382 "def_parse.g"
	pnet = def2max_net ( id.text, special);
 zzCONSUME;

#line 383 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==112) ) {
#line 383 "def_parse.g"
			net_connection();
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 383 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==DEF_PLUS) ) {
#line 383 "def_parse.g"
			net_plus( pnet, special );
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
#line 383 "def_parse.g"
	zzmatch(DEF_SEMI); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x20);
	}
}

void
#ifdef __USE_PROTOS
net_connection(void)
#else
net_connection()
#endif
{
#line 386 "def_parse.g"
	zzRULE;
	Attrib cell;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 386 "def_parse.g"
	zzmatch(112);
#line 386 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 386 "def_parse.g"
	zzmatch(DEF_IDENT);
	cell = zzaCur;

#line 387 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 387 "def_parse.g"
	zzmatch(DEF_IDENT); zzCONSUME;
#line 387 "def_parse.g"
	zzmatch(113); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x40);
	}
}

void
#ifdef __USE_PROTOS
component_plus( char *inst_name, char *mod_name )
#else
component_plus(inst_name,mod_name)
 char *inst_name;
char *mod_name ;
#endif
{
#line 395 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 396 "def_parse.g"
	defparse_place placebuf;
#line 397 "def_parse.g"
	zzmatch(DEF_PLUS); zzCONSUME;
#line 397 "def_parse.g"
	placed_clause( &placebuf );
#line 398 "def_parse.g"
	def2max_component (inst_name, mod_name,
	placebuf.loctype, placebuf.x, placebuf.y, placebuf.orient);
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd4, 0x80);
	}
}

void
#ifdef __USE_PROTOS
pin_plus( defparse_place *pport )
#else
pin_plus(pport)
 defparse_place *pport ;
#endif
{
#line 403 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 404 "def_parse.g"
	int unused;
#line 405 "def_parse.g"
	zzmatch(DEF_PLUS); zzCONSUME;
#line 406 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (setwd5[LA(1)]&0x1) ) {
#line 406 "def_parse.g"
			placed_clause( pport );
		}
		else {
			if ( (LA(1)==DEF_NET) ) {
#line 407 "def_parse.g"
				net_clause();
			}
			else {
				if ( (LA(1)==DEF_DIRECTION) ) {
#line 408 "def_parse.g"
					dir_clause( pport );
				}
				else {
					if ( (LA(1)==DEF_USE) ) {
#line 409 "def_parse.g"
						 unused  = use_clause();

					}
					else {
						if ( (LA(1)==DEF_LAYER) ) {
#line 410 "def_parse.g"
							layer_clause( pport );
						}
						else {zzFAIL(1,zzerr7,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
					}
				}
			}
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd5, 0x2);
	}
}

void
#ifdef __USE_PROTOS
net_plus( pnl_net pnet, int special )
#else
net_plus(pnet,special)
 pnl_net pnet;
int special ;
#endif
{
#line 414 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 415 "def_parse.g"
	pnl_use use;
	pnl_pattern pattern;
	pnl_route route;
#line 419 "def_parse.g"
	zzmatch(DEF_PLUS); zzCONSUME;
#line 420 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_USE) ) {
#line 420 "def_parse.g"
			 use  = use_clause();

#line 421 "def_parse.g"
			/*pnl_net_set_use (pnet, use);*/
		}
		else {
			if ( (LA(1)==DEF_PATTERN) ) {
#line 422 "def_parse.g"
				 pattern  = pattern_clause();

#line 423 "def_parse.g"
				/*pnl_net_set_pattern (pnet, pattern);*/
			}
			else {
				if ( (setwd5[LA(1)]&0x4) ) {
#line 424 "def_parse.g"
					 route  = route_clause( special );

#line 425 "def_parse.g"
					/*pnl_net_add_route (pnet, route);*/
				}
				else {zzFAIL(1,zzerr8,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd5, 0x8);
	}
}

void
#ifdef __USE_PROTOS
placed_clause( defparse_place *pport )
#else
placed_clause(pport)
 defparse_place *pport ;
#endif
{
#line 429 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 430 "def_parse.g"
	int x,y,orient;
	if ( (setwd5[LA(1)]&0x10) ) {
#line 431 "def_parse.g"
		{
			zzBLOCK(zztasp2);
			zzMake0;
			{
			if ( (LA(1)==DEF_PLACED) ) {
#line 431 "def_parse.g"
				zzmatch(DEF_PLACED);
#line 431 "def_parse.g"
				pport->loctype = pnl_loctype_PLACED;
 zzCONSUME;

			}
			else {
				if ( (LA(1)==DEF_FIXED) ) {
#line 432 "def_parse.g"
					zzmatch(DEF_FIXED);
#line 432 "def_parse.g"
					pport->loctype = pnl_loctype_FIXED;
 zzCONSUME;

				}
				else {
					if ( (LA(1)==DEF_COVER) ) {
#line 433 "def_parse.g"
						zzmatch(DEF_COVER);
#line 433 "def_parse.g"
						pport->loctype = pnl_loctype_COVER;
 zzCONSUME;

					}
					else {zzFAIL(1,zzerr9,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
			zzEXIT(zztasp2);
			}
		}
#line 435 "def_parse.g"
		{ struct _rv42 _trv; _trv = coordinate();

		x = _trv.x; y  = _trv.y; }
#line 435 "def_parse.g"
		 orient  = orientation();

#line 436 "def_parse.g"
		pport->x = x;
		pport->y = y;
		pport->orient = orient;
	}
	else {
		if ( (LA(1)==DEF_UNPLACED) ) {
#line 440 "def_parse.g"
			zzmatch(DEF_UNPLACED);
#line 440 "def_parse.g"
			pport->loctype = pnl_loctype_UNPLACED;
			pport->x = 0;
			pport->y = 0;
			pport->orient = pnl_orientation_none;
 zzCONSUME;

		}
		else {zzFAIL(1,zzerr10,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd5, 0x20);
	}
}

void
#ifdef __USE_PROTOS
net_clause(void)
#else
net_clause()
#endif
{
#line 447 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 447 "def_parse.g"
	zzmatch(DEF_NET);
#line 447 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 447 "def_parse.g"
	zzmatch(DEF_IDENT); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd5, 0x40);
	}
}

void
#ifdef __USE_PROTOS
dir_clause( defparse_place *pport )
#else
dir_clause(pport)
 defparse_place *pport ;
#endif
{
#line 450 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 451 "def_parse.g"
	zzmatch(DEF_DIRECTION); zzCONSUME;
#line 452 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_INPUT) ) {
#line 452 "def_parse.g"
			zzmatch(DEF_INPUT);
#line 452 "def_parse.g"
			pport->iotype = LAB_INPUT;
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_OUTPUT) ) {
#line 453 "def_parse.g"
				zzmatch(DEF_OUTPUT);
#line 453 "def_parse.g"
				pport->iotype = LAB_OUTPUT;
 zzCONSUME;

			}
			else {
				if ( (LA(1)==DEF_INOUT) ) {
#line 454 "def_parse.g"
					zzmatch(DEF_INOUT);
#line 454 "def_parse.g"
					pport->iotype = LAB_INOUT;
 zzCONSUME;

				}
				else {zzFAIL(1,zzerr11,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd5, 0x80);
	}
}

 pnl_use  
#ifdef __USE_PROTOS
use_clause(void)
#else
use_clause()
#endif
{
	 pnl_use  	 _retv;
#line 458 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( pnl_use  	))
	zzMake0;
	{
#line 459 "def_parse.g"
	zzmatch(DEF_USE); zzCONSUME;
#line 460 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_SIGNAL) ) {
#line 460 "def_parse.g"
			zzmatch(DEF_SIGNAL);
#line 460 "def_parse.g"
			_retv = pnl_use_SIGNAL;
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_POWER) ) {
#line 461 "def_parse.g"
				zzmatch(DEF_POWER);
#line 461 "def_parse.g"
				_retv = pnl_use_POWER;
 zzCONSUME;

			}
			else {
				if ( (LA(1)==DEF_GROUND) ) {
#line 462 "def_parse.g"
					zzmatch(DEF_GROUND);
#line 462 "def_parse.g"
					_retv = pnl_use_GROUND;
 zzCONSUME;

				}
				else {
					if ( (LA(1)==DEF_CLOCK) ) {
#line 463 "def_parse.g"
						zzmatch(DEF_CLOCK);
#line 463 "def_parse.g"
						_retv = pnl_use_CLOCK;
 zzCONSUME;

					}
					else {
						if ( (LA(1)==DEF_TIEOFF) ) {
#line 464 "def_parse.g"
							zzmatch(DEF_TIEOFF);
#line 464 "def_parse.g"
							_retv = pnl_use_TIEOFF;
 zzCONSUME;

						}
						else {
							if ( (LA(1)==DEF_ANALOG) ) {
#line 465 "def_parse.g"
								zzmatch(DEF_ANALOG);
#line 465 "def_parse.g"
								_retv = pnl_use_ANALOG;
 zzCONSUME;

							}
							else {zzFAIL(1,zzerr12,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
						}
					}
				}
			}
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x1);
	return _retv;
	}
}

 pnl_pattern  
#ifdef __USE_PROTOS
pattern_clause(void)
#else
pattern_clause()
#endif
{
	 pnl_pattern  	 _retv;
#line 469 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( pnl_pattern  	))
	zzMake0;
	{
#line 470 "def_parse.g"
	zzmatch(DEF_PATTERN); zzCONSUME;
#line 471 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_STEINER) ) {
#line 471 "def_parse.g"
			zzmatch(DEF_STEINER);
#line 471 "def_parse.g"
			_retv = pnl_pattern_STEINER;
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_BALANCED) ) {
#line 472 "def_parse.g"
				zzmatch(DEF_BALANCED);
#line 472 "def_parse.g"
				_retv = pnl_pattern_BALANCED;
 zzCONSUME;

			}
			else {
				if ( (LA(1)==DEF_WIREDLOGIC) ) {
#line 473 "def_parse.g"
					zzmatch(DEF_WIREDLOGIC);
#line 473 "def_parse.g"
					_retv = pnl_pattern_WIREDLOGIC;
 zzCONSUME;

				}
				else {
					if ( (LA(1)==DEF_TRUNK) ) {
#line 474 "def_parse.g"
						zzmatch(DEF_TRUNK);
#line 474 "def_parse.g"
						_retv = pnl_pattern_TRUNK;
 zzCONSUME;

					}
					else {zzFAIL(1,zzerr13,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x2);
	return _retv;
	}
}

 pnl_route  
#ifdef __USE_PROTOS
route_clause( int special )
#else
route_clause(special)
 int special ;
#endif
{
	 pnl_route  	 _retv;
#line 478 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( pnl_route  	))
	zzMake0;
	{
#line 479 "def_parse.g"
	pnl_routekind routekind;
	pnl_branch branch;
#line 482 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_ROUTED) ) {
#line 482 "def_parse.g"
			zzmatch(DEF_ROUTED);
#line 482 "def_parse.g"
			routekind = pnl_routekind_ROUTED; ID_MODE;
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_FIXED) ) {
#line 483 "def_parse.g"
				zzmatch(DEF_FIXED);
#line 483 "def_parse.g"
				routekind = pnl_routekind_FIXED; ID_MODE;
 zzCONSUME;

			}
			else {
				if ( (LA(1)==DEF_COVER) ) {
#line 484 "def_parse.g"
					zzmatch(DEF_COVER);
#line 484 "def_parse.g"
					routekind = pnl_routekind_COVER; ID_MODE;
 zzCONSUME;

				}
				else {zzFAIL(1,zzerr14,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		zzEXIT(zztasp2);
		}
	}
#line 486 "def_parse.g"
	_retv = 0; /*pnl_route_create (routekind);*/
#line 487 "def_parse.g"
	 branch  = route_branch( special );

#line 488 "def_parse.g"
	/*pnl_route_add_branch ($route, branch);*/
#line 493 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==DEF_NEW) ) {
#line 489 "def_parse.g"
			zzmatch(DEF_NEW);
#line 490 "def_parse.g"
			ID_MODE;
 zzCONSUME;

#line 491 "def_parse.g"
			 branch  = route_branch( special );

#line 492 "def_parse.g"
			/*pnl_route_add_branch ($route, branch);*/
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x4);
	return _retv;
	}
}

 pnl_branch  
#ifdef __USE_PROTOS
route_branch( int special )
#else
route_branch(special)
 int special ;
#endif
{
	 pnl_branch  	 _retv;
#line 496 "def_parse.g"
	zzRULE;
	Attrib id;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( pnl_branch  	))
	zzMake0;
	{
#line 497 "def_parse.g"
	int x0;
	int y0;
	int width = -1;
	pnl_segment segment;
	char layer[ZZLEXBUFSIZE];
#line 503 "def_parse.g"
	zzmatch(DEF_IDENT);
	id = zzaCur;

#line 503 "def_parse.g"
	strcpy(layer, id.text);
 zzCONSUME;

#line 504 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_NUMBER) ) {
			if (!(
#line 504 "def_parse.g"
special )) {zzfailed_pred("   special ");}
#line 504 "def_parse.g"
			 width  = number();

		}
		else {
			if ( (LA(1)==112) ) {
				if (!(
#line 505 "def_parse.g"
!special)) {zzfailed_pred("   !special");}
			}
			else {zzFAIL(1,zzerr15,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		zzEXIT(zztasp2);
		}
	}
#line 507 "def_parse.g"
	zzmatch(112); zzCONSUME;
#line 507 "def_parse.g"
	 x0  = number();

#line 507 "def_parse.g"
	 y0  = number();

#line 507 "def_parse.g"
	zzmatch(113);
#line 508 "def_parse.g"
	_retv = 0; /*pnl_branch_create (layer, x0, y0, width);*/
	zzmode (IDENT_NEW_OR_PLUS);
 zzCONSUME;

#line 511 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		int zzcnt=1;
		zzMake0;
		{
		do {
#line 511 "def_parse.g"
			 segment  = route_segment();

#line 512 "def_parse.g"
			/*pnl_branch_add_segment ($branch, segment);*/
			zzLOOP(zztasp2);
		} while ( (setwd6[LA(1)]&0x8) );
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x10);
	return _retv;
	}
}

 pnl_segment  
#ifdef __USE_PROTOS
route_segment(void)
#else
route_segment()
#endif
{
	 pnl_segment  	 _retv;
#line 517 "def_parse.g"
	zzRULE;
	Attrib via_name;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( pnl_segment  	))
	zzMake0;
	{
#line 518 "def_parse.g"
	int x, y;
#line 519 "def_parse.g"
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==DEF_ID_OPEN) ) {
#line 519 "def_parse.g"
			zzmatch(DEF_ID_OPEN); zzCONSUME;
#line 519 "def_parse.g"
			{
				zzBLOCK(zztasp3);
				zzMake0;
				{
				if ( (LA(1)==DEF_NUMBER) ) {
#line 519 "def_parse.g"
					 x  = number();

#line 519 "def_parse.g"
					zzmatch(114);
#line 520 "def_parse.g"
					_retv = 0;/*pnl_segment_create_x_segment (x);*/
 zzCONSUME;

				}
				else {
					if ( (LA(1)==114) ) {
#line 521 "def_parse.g"
						zzmatch(114); zzCONSUME;
#line 521 "def_parse.g"
						 y  = number();

#line 522 "def_parse.g"
						_retv = 0;/*pnl_segment_create_y_segment (y);*/
					}
					else {zzFAIL(1,zzerr16,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
				zzEXIT(zztasp3);
				}
			}
#line 523 "def_parse.g"
			zzmatch(113);
#line 524 "def_parse.g"
			zzmode (IDENT_NEW_OR_PLUS);
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_IDENT) ) {
#line 525 "def_parse.g"
				zzmatch(DEF_IDENT);
				via_name = zzaCur;

#line 526 "def_parse.g"
				_retv = 0;/*pnl_segment_create_via ($via_name.text);*/
				zzmode (IDENT_NEW_OR_PLUS);
 zzCONSUME;

			}
			else {zzFAIL(1,zzerr17,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		zzEXIT(zztasp2);
		}
	}
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x20);
	return _retv;
	}
}

void
#ifdef __USE_PROTOS
layer_clause( defparse_place *pport )
#else
layer_clause(pport)
 defparse_place *pport ;
#endif
{
#line 532 "def_parse.g"
	zzRULE;
	Attrib id;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 533 "def_parse.g"
	int x0, y0;
	int x1, y1;
#line 536 "def_parse.g"
	zzmatch(DEF_LAYER);
#line 536 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 537 "def_parse.g"
	zzmatch(DEF_IDENT);
	id = zzaCur;

#line 537 "def_parse.g"
	strcpy(pport->layer, id.text);
 zzCONSUME;

#line 538 "def_parse.g"
	{ struct _rv42 _trv; _trv = coordinate();

	x0 = _trv.x; y0  = _trv.y; }
#line 538 "def_parse.g"
	{ struct _rv42 _trv; _trv = coordinate();

	x1 = _trv.x; y1  = _trv.y; }
#line 539 "def_parse.g"
	/*pnl_port_set_geometry (pport, name, x0, y0, x1, y1);*/
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x40);
	}
}

void
#ifdef __USE_PROTOS
rect_clause(void)
#else
rect_clause()
#endif
{
#line 543 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 543 "def_parse.g"
	zzmatch(DEF_RECT);
#line 543 "def_parse.g"
	ID_MODE;
 zzCONSUME;

#line 543 "def_parse.g"
	zzmatch(DEF_IDENT); zzCONSUME;
#line 543 "def_parse.g"
	coordinate();
#line 543 "def_parse.g"
	coordinate();
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd6, 0x80);
	}
}

struct _rv42
#ifdef __USE_PROTOS
coordinate(void)
#else
coordinate()
#endif
{
	struct _rv42 _retv;
#line 546 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof(struct _rv42))
	zzMake0;
	{
#line 547 "def_parse.g"
	zzmatch(112); zzCONSUME;
#line 547 "def_parse.g"
	 _retv.x  = number();

#line 547 "def_parse.g"
	 _retv.y  = number();

#line 547 "def_parse.g"
	zzmatch(113); zzCONSUME;
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd7, 0x1);
	return _retv;
	}
}

 pnl_orientation  
#ifdef __USE_PROTOS
orientation(void)
#else
orientation()
#endif
{
	 pnl_orientation  	 _retv;
#line 550 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( pnl_orientation  	))
	zzMake0;
	{
	if ( (LA(1)==DEF_N) ) {
#line 551 "def_parse.g"
		zzmatch(DEF_N);
#line 551 "def_parse.g"
		_retv = pnl_orientation_N;
 zzCONSUME;

	}
	else {
		if ( (LA(1)==DEF_S) ) {
#line 552 "def_parse.g"
			zzmatch(DEF_S);
#line 552 "def_parse.g"
			_retv = pnl_orientation_S;
 zzCONSUME;

		}
		else {
			if ( (LA(1)==DEF_E) ) {
#line 553 "def_parse.g"
				zzmatch(DEF_E);
#line 553 "def_parse.g"
				_retv = pnl_orientation_E;
 zzCONSUME;

			}
			else {
				if ( (LA(1)==DEF_W) ) {
#line 554 "def_parse.g"
					zzmatch(DEF_W);
#line 554 "def_parse.g"
					_retv = pnl_orientation_W;
 zzCONSUME;

				}
				else {
					if ( (LA(1)==DEF_FN) ) {
#line 555 "def_parse.g"
						zzmatch(DEF_FN);
#line 555 "def_parse.g"
						_retv = pnl_orientation_FN;
 zzCONSUME;

					}
					else {
						if ( (LA(1)==DEF_FS) ) {
#line 556 "def_parse.g"
							zzmatch(DEF_FS);
#line 556 "def_parse.g"
							_retv = pnl_orientation_FS;
 zzCONSUME;

						}
						else {
							if ( (LA(1)==DEF_FE) ) {
#line 557 "def_parse.g"
								zzmatch(DEF_FE);
#line 557 "def_parse.g"
								_retv = pnl_orientation_FE;
 zzCONSUME;

							}
							else {
								if ( (LA(1)==DEF_FW) ) {
#line 558 "def_parse.g"
									zzmatch(DEF_FW);
#line 558 "def_parse.g"
									_retv = pnl_orientation_FW;
 zzCONSUME;

								}
								else {zzFAIL(1,zzerr18,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
							}
						}
					}
				}
			}
		}
	}
	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd7, 0x2);
	return _retv;
	}
}

 int  
#ifdef __USE_PROTOS
number(void)
#else
number()
#endif
{
	 int  	 _retv;
#line 561 "def_parse.g"
	zzRULE;
	Attrib n;
	zzBLOCK(zztasp1);
	PURIFY(_retv,sizeof( int  	))
	zzMake0;
	{
#line 562 "def_parse.g"
	zzmatch(DEF_NUMBER);
	n = zzaCur;

#line 562 "def_parse.g"
	_retv = atoi ( n.text);
 zzCONSUME;

	zzEXIT(zztasp1);
	return _retv;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd7, 0x4);
	return _retv;
	}
}

void
#ifdef __USE_PROTOS
number_discarded(void)
#else
number_discarded()
#endif
{
#line 565 "def_parse.g"
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
#line 566 "def_parse.g"
	zzmatch(DEF_NUMBER); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd7, 0x8);
	}
}
