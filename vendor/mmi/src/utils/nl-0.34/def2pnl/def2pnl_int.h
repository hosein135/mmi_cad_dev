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

void     def2pnl_design (char *);
void     def2pnl_history (char *);
void     def2pnl_die_area (int, int, int, int);
void     def2pnl_divider_char (char *);
void     def2pnl_component (char *, char *, pnl_loctype, int, int,
				pnl_orientation);
void     def2pnl_port (pnl_port, pnl_loctype, int, int, pnl_orientation);
pnl_port def2pnl_pin (char *);
pnl_net  def2pnl_net (char *, int);
void     def2pnl_tracks (int, int, int, int, ar);
void     def2pnl_row_site (char *, char *, int, int, pnl_orientation,
			       int, int, int);
void     def2pnl_distance_units (char *, int);

void     def2pnl_error (const char *format, ...) NORETURN;
void     def2pnl_lex_error (const char *);
