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

extern void hier_ungroup (nl_cell, char *, char *, int, int);
extern void hier_ungroup_all (nl_design, char *, char *, int, int);
extern nl_design hier_group (ar, char *, char *);
extern void hier_link_design (nl_design, int, int, ar);
extern void hier_link_reference (nl_reference, int, int, ar);
extern int  hier_replace_cell (nl_cell, nl_reference);
extern nl_reference hier_copy_reference (nl_reference, nl_design,
					 nl_reference_attr);
