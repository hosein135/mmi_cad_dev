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

/* remap.h -- List of symbols to remap
 *
 * Generated from: def_parse.g
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-1999
 * Purdue University Electrical Engineering
 * ANTLR Version 1.33MR22
 */

/* rename rule functions to be 'ParserName_func' */
#define def_file def_def_file
#define header def_header
#define version def_version
#define namescasesensitive def_namescasesensitive
#define dividerchar def_dividerchar
#define busbitchars def_busbitchars
#define def_design def_def_design
#define declaration def_declaration
#define units_decl def_units_decl
#define diearea_decl def_diearea_decl
#define tracks_decl def_tracks_decl
#define history_decl def_history_decl
#define row_decl def_row_decl
#define gcellgrid_decl def_gcellgrid_decl
#define propertydefinitions_decl def_propertydefinitions_decl
#define propertydefinition def_propertydefinition
#define constituent def_constituent
#define vias def_vias
#define via def_via
#define via_plus def_via_plus
#define components def_components
#define component def_component
#define pins def_pins
#define pin def_pin
#define nets def_nets
#define specialnets def_specialnets
#define net def_net
#define net_connection def_net_connection
#define component_plus def_component_plus
#define pin_plus def_pin_plus
#define net_plus def_net_plus
#define placed_clause def_placed_clause
#define net_clause def_net_clause
#define dir_clause def_dir_clause
#define use_clause def_use_clause
#define pattern_clause def_pattern_clause
#define route_clause def_route_clause
#define route_branch def_route_branch
#define route_segment def_route_segment
#define layer_clause def_layer_clause
#define rect_clause def_rect_clause
#define coordinate def_coordinate
#define orientation def_orientation
#define number def_number
#define number_discarded def_number_discarded

/* rename PCCTS-supplied symbols to be 'ParserName_symbol' */
#define zzStackOvfMsg def_zzStackOvfMsg
#define zzasp def_zzasp
#define zzaStack def_zzaStack
#define inf_tokens def_inf_tokens
#define inf_text def_inf_text
#define inf_text_buffer def_inf_text_buffer
#define inf_text_buffer_ptr def_inf_text_buffer_ptr
#define inf_text_buffer_size def_inf_text_buffer_size
#define inf_labase def_inf_labase
#define inf_last def_inf_last
#define inf_lap def_inf_lap
#define zztokenLA def_zztokenLA
#define zztextLA def_zztextLA
#define zzlap def_zzlap
#define zzlabase def_zzlabase
#define zztoktext def_zztoktext
#define zztoken def_zztoken
#define zzdirty def_zzdirty
#define zzguessing def_zzguessing
#define zzguess_start def_zzguess_start
#define zzresynch def_zzresynch
#define zzinf_tokens def_zzinf_tokens
#define zzinf_text def_zzinf_text
#define zzinf_text_buffer def_zzinf_text_buffer
#define zzinf_labase def_zzinf_labase
#define zzinf_last def_zzinf_last
#define zzfill_inf_look def_zzfill_inf_look
#define zzFAIL def_zzFAIL
#define zzsave_antlr_state def_zzsave_antlr_state
#define zzrestore_antlr_state def_zzrestore_antlr_state
#define zzsyn def_zzsyn
#define zzset_el def_zzset_el
#define zzset_deg def_zzset_deg
#define zzedecode def_zzedecode
#define _zzsetmatch def__zzsetmatch
#define _zzmatch def__zzmatch
#define _inf_zzgettok def__inf_zzgettok
#define zzconsumeUntil def_zzconsumeUntil
#define zzconsumeUntilToken def_zzconsumeUntilToken
#define _zzmatch_wsig def__zzmatch_wsig
#define _zzsetmatch_wsig def__zzsetmatch_wsig
#define _zzmatch_wdfltsig def__zzmatch_wdfltsig
#define _zzsetmatch_wdfltsig def__zzsetmatch_wdfltsig
#define zzdflthandlers def_zzdflthandlers
#define zzreal_line def_zzreal_line
#define zzcharfull def_zzcharfull
#define zzerr def_zzerr
#define zzlextext def_zzlextext
#define zzbegexpr def_zzbegexpr
#define zzendexpr def_zzendexpr
#define zzbufsize def_zzbufsize
#define zzbegcol def_zzbegcol
#define zzendcol def_zzendcol
#define zzline def_zzline
#define zzchar def_zzchar
#define zzbufovf def_zzbufovf
#define zzrdstream def_zzrdstream
#define zzrdfunc def_zzrdfunc
#define zzrdstr def_zzrdstr
#define zzclose_stream def_zzclose_stream
#define zzsave_dlg_state def_zzsave_dlg_state
#define zzrestore_dlg_state def_zzrestore_dlg_state
#define zzmode def_zzmode
#define zzskip def_zzskip
#define zzmore def_zzmore
#define zzreplchar def_zzreplchar
#define zzreplstr def_zzreplstr
#define zzgettok def_zzgettok
#define zzadvance def_zzadvance
#define zzerrstd def_zzerrstd
#define zzerr_in def_zzerr_in
#define zzconstr_attr def_zzconstr_attr
#define zzempty_attr def_zzempty_attr
#define zzerraction def_zzerraction
#define zztokens def_zztokens
#define dfa def_dfa
#define accepts def_accepts
#define actions def_actions
#define zzTraceOptionValue def_zzTraceOptionValue
#define zzTraceGuessOptionValue def_zzTraceGuessOptionValue
#define zzTraceCurrentRuleName def_zzTraceCurrentRuleName
#define zzTraceDepth def_zzTraceDepth
#define zzGuessSeq def_zzGuessSeq
#define zzSyntaxErrCount def_zzSyntaxErrCount
#define zzLexErrCount def_zzLexErrCount
#define zzTraceGuessDone def_zzTraceGuessDone
#define zzTraceGuessFail def_zzTraceGuessFail
#define zzTraceGuessOption def_zzTraceGuessOption
#define zzTraceIn def_zzTraceIn
#define zzTraceOption def_zzTraceOption
#define zzTraceOut def_zzTraceOut
#define zzTraceReset def_zzTraceReset
#define setwd1 def_setwd1
#define setwd2 def_setwd2
#define setwd3 def_setwd3
#define setwd4 def_setwd4
#define setwd5 def_setwd5
#define setwd6 def_setwd6
#define setwd7 def_setwd7
#define zzerr1 def_err1
#define zzerr2 def_err2
#define zzerr3 def_err3
#define zzerr4 def_err4
#define zzerr5 def_err5
#define zzerr6 def_err6
#define zzerr7 def_err7
#define zzerr8 def_err8
#define zzerr9 def_err9
#define zzerr10 def_err10
#define zzerr11 def_err11
#define zzerr12 def_err12
#define zzerr13 def_err13
#define zzerr14 def_err14
#define zzerr15 def_err15
#define zzerr16 def_err16
#define zzerr17 def_err17
#define zzerr18 def_err18
