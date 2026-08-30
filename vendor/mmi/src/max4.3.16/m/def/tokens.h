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

#ifndef tokens_h
#define tokens_h
/* tokens.h -- List of labelled tokens and stuff
 *
 * Generated from: def_parse.g
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-1999
 * Purdue University Electrical Engineering
 * ANTLR Version 1.33MR22
 */
#define zzEOF_TOKEN 1
#define DEF_ANALOG 4
#define DEF_BALANCED 5
#define DEF_BUSBITCHARS 6
#define DEF_BY 7
#define DEF_CLOCK 8
#define DEF_COMPONENT 9
#define DEF_COMPONENTS 10
#define DEF_COVER 11
#define DEF_DEFAULT 12
#define DEF_DESIGN 13
#define DEF_DIEAREA 14
#define DEF_DIRECTION 15
#define DEF_DIST 16
#define DEF_DISTANCE 17
#define DEF_DIVIDERCHAR 18
#define DEF_DO 19
#define DEF_END 20
#define DEF_FIXED 21
#define DEF_GCELLGRID 22
#define DEF_GROUND 23
#define DEF_HISTORY 24
#define DEF_HORIZONTAL 25
#define DEF_IN 26
#define DEF_INOUT 27
#define DEF_INPUT 28
#define DEF_LAYER 29
#define DEF_MICRONS 30
#define DEF_NAMESCASESENSITIVE 31
#define DEF_NET 32
#define DEF_NETS 33
#define DEF_NEW 34
#define DEF_OFF 35
#define DEF_ON 36
#define DEF_OUT 37
#define DEF_OUTPUT 38
#define DEF_PATTERN 39
#define DEF_PIN 40
#define DEF_PINS 41
#define DEF_PLACED 42
#define DEF_POWER 43
#define DEF_PROPERTYDEFINITIONS 44
#define DEF_RECT 45
#define DEF_REGIONS 46
#define DEF_ROUTED 47
#define DEF_ROW 48
#define DEF_ROWS 49
#define DEF_SIGNAL 50
#define DEF_SITE 51
#define DEF_SOURCE 52
#define DEF_SPECIAL 53
#define DEF_SPECIALNET 54
#define DEF_SPECIALNETS 55
#define DEF_START 56
#define DEF_STEINER 57
#define DEF_STEP 58
#define DEF_STOP 59
#define DEF_STRING 60
#define DEF_TECHNOLOGY 61
#define DEF_TIEOFF 62
#define DEF_TRACKS 63
#define DEF_TRUNK 64
#define DEF_UNITS 65
#define DEF_UNPLACED 66
#define DEF_USE 67
#define DEF_VERILOGDESIGNNAME 68
#define DEF_VERSION 69
#define DEF_VERTICAL 70
#define DEF_VIAS 71
#define DEF_WIREDLOGIC 72
#define DEF_X 73
#define DEF_Y 74
#define DEF_N 75
#define DEF_S 76
#define DEF_E 77
#define DEF_W 78
#define DEF_FN 79
#define DEF_FS 80
#define DEF_FE 81
#define DEF_FW 82
#define DEF_PLUS 83
#define DEF_SEMI 84
#define DEF_NUMBER 85
#define DEF_IDENT 91
#define DEF_ID_OPEN 95
#define DEF_QUOTED 99
#define DEF_HISTORY_LIST 105

#ifdef __USE_PROTOS
void def_file(void);
#else
extern void def_file();
#endif

#ifdef __USE_PROTOS
void header(void);
#else
extern void header();
#endif

#ifdef __USE_PROTOS
void version(void);
#else
extern void version();
#endif

#ifdef __USE_PROTOS
void namescasesensitive(void);
#else
extern void namescasesensitive();
#endif

#ifdef __USE_PROTOS
void dividerchar(void);
#else
extern void dividerchar();
#endif

#ifdef __USE_PROTOS
void busbitchars(void);
#else
extern void busbitchars();
#endif

#ifdef __USE_PROTOS
void def_design(void);
#else
extern void def_design();
#endif

#ifdef __USE_PROTOS
void declaration(void);
#else
extern void declaration();
#endif

#ifdef __USE_PROTOS
void units_decl(void);
#else
extern void units_decl();
#endif

#ifdef __USE_PROTOS
void diearea_decl(void);
#else
extern void diearea_decl();
#endif

#ifdef __USE_PROTOS
void tracks_decl(void);
#else
extern void tracks_decl();
#endif

#ifdef __USE_PROTOS
void history_decl(void);
#else
extern void history_decl();
#endif

#ifdef __USE_PROTOS
void row_decl(void);
#else
extern void row_decl();
#endif

#ifdef __USE_PROTOS
void gcellgrid_decl(void);
#else
extern void gcellgrid_decl();
#endif

#ifdef __USE_PROTOS
void propertydefinitions_decl(void);
#else
extern void propertydefinitions_decl();
#endif

#ifdef __USE_PROTOS
void propertydefinition(void);
#else
extern void propertydefinition();
#endif

#ifdef __USE_PROTOS
void constituent(void);
#else
extern void constituent();
#endif

#ifdef __USE_PROTOS
void vias(void);
#else
extern void vias();
#endif

#ifdef __USE_PROTOS
void via(void);
#else
extern void via();
#endif

#ifdef __USE_PROTOS
void via_plus(void);
#else
extern void via_plus();
#endif

#ifdef __USE_PROTOS
void components(void);
#else
extern void components();
#endif

#ifdef __USE_PROTOS
void component(void);
#else
extern void component();
#endif

#ifdef __USE_PROTOS
void pins(void);
#else
extern void pins();
#endif

#ifdef __USE_PROTOS
void pin(void);
#else
extern void pin();
#endif

#ifdef __USE_PROTOS
void nets(void);
#else
extern void nets();
#endif

#ifdef __USE_PROTOS
void specialnets(void);
#else
extern void specialnets();
#endif

#ifdef __USE_PROTOS
void net( int special );
#else
extern void net();
#endif

#ifdef __USE_PROTOS
void net_connection(void);
#else
extern void net_connection();
#endif

#ifdef __USE_PROTOS
void component_plus( char *inst_name, char *mod_name );
#else
extern void component_plus();
#endif

#ifdef __USE_PROTOS
void pin_plus( defparse_place *pport );
#else
extern void pin_plus();
#endif

#ifdef __USE_PROTOS
void net_plus( pnl_net pnet, int special );
#else
extern void net_plus();
#endif

#ifdef __USE_PROTOS
void placed_clause( defparse_place *pport );
#else
extern void placed_clause();
#endif

#ifdef __USE_PROTOS
void net_clause(void);
#else
extern void net_clause();
#endif

#ifdef __USE_PROTOS
void dir_clause( defparse_place *pport );
#else
extern void dir_clause();
#endif

#ifdef __USE_PROTOS
extern  pnl_use   use_clause(void);
#else
extern  pnl_use   use_clause();
#endif

#ifdef __USE_PROTOS
extern  pnl_pattern   pattern_clause(void);
#else
extern  pnl_pattern   pattern_clause();
#endif

#ifdef __USE_PROTOS
extern  pnl_route   route_clause( int special );
#else
extern  pnl_route   route_clause();
#endif

#ifdef __USE_PROTOS
extern  pnl_branch   route_branch( int special );
#else
extern  pnl_branch   route_branch();
#endif

#ifdef __USE_PROTOS
extern  pnl_segment   route_segment(void);
#else
extern  pnl_segment   route_segment();
#endif

#ifdef __USE_PROTOS
void layer_clause( defparse_place *pport );
#else
extern void layer_clause();
#endif

#ifdef __USE_PROTOS
void rect_clause(void);
#else
extern void rect_clause();
#endif

struct _rv42 {
	int x;
	int y ;
};

#ifdef __USE_PROTOS
extern struct _rv42 coordinate(void);
#else
extern struct _rv42 coordinate();
#endif

#ifdef __USE_PROTOS
extern  pnl_orientation   orientation(void);
#else
extern  pnl_orientation   orientation();
#endif

#ifdef __USE_PROTOS
extern  int   number(void);
#else
extern  int   number();
#endif

#ifdef __USE_PROTOS
void number_discarded(void);
#else
extern void number_discarded();
#endif

#endif
extern SetWordType zzerr1[];
extern SetWordType zzerr2[];
extern SetWordType setwd1[];
extern SetWordType zzerr3[];
extern SetWordType zzerr4[];
extern SetWordType zzerr5[];
extern SetWordType setwd2[];
extern SetWordType zzerr6[];
extern SetWordType setwd3[];
extern SetWordType setwd4[];
extern SetWordType zzerr7[];
extern SetWordType zzerr8[];
extern SetWordType zzerr9[];
extern SetWordType zzerr10[];
extern SetWordType zzerr11[];
extern SetWordType zzerr12[];
extern SetWordType setwd5[];
extern SetWordType zzerr13[];
extern SetWordType zzerr14[];
extern SetWordType zzerr15[];
extern SetWordType zzerr16[];
extern SetWordType zzerr17[];
extern SetWordType setwd6[];
extern SetWordType zzerr18[];
extern SetWordType setwd7[];
