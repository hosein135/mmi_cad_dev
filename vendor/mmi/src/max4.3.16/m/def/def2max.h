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

// The Antler parser creates remap.h to add "def" to the front of all
// the symbols it creates.
#define zzparser def
#include "remap.h"


// The definitions of Attrib, zzcr_attr and zzd_attr are
// needed before including anything from antler.
// These define how tokens are stored.  There are multiple examples
// in the pccts/h directory in charptr.h+charptr.c or charbuf.h
// Jay created another fancier version for NL.
// THIS IS THE VERSION THAT MALLOCS EACH TOKEN:
#if 0
    typedef struct {char *text;} Attrib;
    extern void zzcr_attr(Attrib*,int,char*);
    #define zzdef0(a)    {*(a)=NULL;}
    #define zzd_attr(a)  {if (*(a)!=NULL) {free(*(a)); *(a)=NULL;}}
#endif

typedef struct { char *text; } Attrib;

#if ZZCR_MALLOC
    #define D_TextSize 2050		/* 2048 plus some slop */
    extern void def_zzcr_attr(Attrib*,int,char*);
    extern void def_zzd_attr(Attrib*);
    #define zzcr_attr def_zzcr_attr
    #define zzd_attr def_zzd_attr
    #define zzdef0(a)    {(a)->text=NULL;}
#endif

// This is a clever way used by Jay.
// Store the current token as a pointer into the single
// lexical buffer.  This means if you want to use a token,
// you must grab it instantly before reading the next token.
#define zzcr_attr(attr, tok, t)	((attr)->text = (t))
#undef  zzd_attr



// TODO: These need to be replaced with something real!
typedef long pnl_net;
typedef long pnl_segment;
typedef long pnl_route;
typedef long pnl_branch;
enum pnl_routekind {
  pnl_routekind_null, pnl_routekind_ROUTED, pnl_routekind_FIXED,
  pnl_routekind_COVER
};
typedef enum pnl_routekind pnl_routekind;


enum pnl_segmentkind {
  pnl_segmentkind_null, pnl_segmentkind_via, pnl_segmentkind_x,
  pnl_segmentkind_y
};
typedef enum pnl_segmentkind pnl_segmentkind;


enum pnl_loctype {
  pnl_loctype_null, pnl_loctype_UNPLACED, pnl_loctype_PLACED,
  pnl_loctype_FIXED, pnl_loctype_COVER
};
typedef enum pnl_loctype pnl_loctype;

enum pnl_pattern {
  pnl_pattern_null, pnl_pattern_STEINER, pnl_pattern_BALANCED,
  pnl_pattern_WIREDLOGIC, pnl_pattern_TRUNK
};
typedef enum pnl_pattern pnl_pattern;

enum pnl_orientation {
  pnl_orientation_null, pnl_orientation_none, pnl_orientation_N,
  pnl_orientation_S, pnl_orientation_E, pnl_orientation_W, pnl_orientation_FN,
  pnl_orientation_FS, pnl_orientation_FE, pnl_orientation_FW
};
typedef enum pnl_orientation pnl_orientation;

enum pnl_use {
  pnl_use_null, pnl_use_SIGNAL, pnl_use_POWER, pnl_use_GROUND, pnl_use_CLOCK,
  pnl_use_TIEOFF, pnl_use_ANALOG
};
typedef enum pnl_use pnl_use;

// Temp struct to hold port info while a port is parsed from def file.
struct defparse_place_struct {
	char name[2050];
	char layer[2050];
	pnl_loctype loctype;
	pnl_orientation orient;
	int iotype;
	int x, y;
	};
typedef struct defparse_place_struct defparse_place;




extern void def2max_design (char *);
extern void def2max_history (char *);
extern void def2max_die_area (int, int, int, int);
extern void def2max_divider_char (char *);
extern void def2max_busbit_char (char *);
extern void def2max_component (char *, char *, pnl_loctype, int, int, pnl_orientation);
extern void def2max_distance_units (char *, int);
extern void def2max_case_sensigive (int);
extern pnl_net def2max_net (char *, int);

//extern void def2max_row_site (char *, char *, int, int, pnl_orientation, int, int, int);

//extern void def2max_error (const char *format, ...) __attribute__ ((noreturn));
//extern void def2max_lex_error (const char *);

//#define malloc mallocMagic
//#define calloc callocMagic
//#define realloc REALLOC
//#define free FREE
