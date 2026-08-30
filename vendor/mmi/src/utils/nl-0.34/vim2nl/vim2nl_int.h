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

void		vim2nl_design (char *);
void		vim2nl_place_design (char *);
void		vim2nl_distance_units (void);
void		vim2nl_net (char *);
nl_cell		vim2nl_cell (char *, nl_reference);
void		vim2nl_port (char *, nl_direction, nl_net);
nl_pin		vim2nl_pin (nl_cell, char *, nl_direction);
void		vim2nl_connect (nl_pin, nl_net);
nl_net		vim2nl_get_net (char *);
nl_reference	vim2nl_get_ref (char *);
nl_cell		vim2nl_get_cell (char *);
nl_port		vim2nl_get_port (char *);
nl_direction	vim2nl_direction (char *);
pnl_orientation	vim2nl_orientation (int, int);
void		vim2nl_place_cell (nl_cell, int, int, pnl_orientation);
void		vim2nl_place_attribute (nl_cell, char *);
void		vim2nl_place_port (nl_port, char *, int, int, int, int);
void		vim2nl_outline (char *, int, int, int, int);
void		vim2nl_check_reference (nl_cell, char *);
void		vim2nl_scale (char *);
int		vim2nl_coordinate (char *, char);
void		vim2nl_row (char *, int, int, int, int);
