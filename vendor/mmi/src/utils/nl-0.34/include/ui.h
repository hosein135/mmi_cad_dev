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

enum ui_find_mode {
  ui_find_mode_null,
  ui_find_mode_exact,
  ui_find_mode_glob,
  ui_find_mode_regexp,
  ui_find_mode_subregexp
};

typedef enum ui_find_mode ui_find_mode;


int ui_app_init (Tcl_Interp *, char *, void **, const char *);
int ui_alias_init (Tcl_Interp *, char *, void *);
ar  ui_tokenize_hierarchy_path (char *, char **, char *);
nl_object ui_obj_get_nl_object (Tcl_Obj *);
nl_object ui_get_nl_context (void);

#ifndef UI_NO_FIND_FNS
int ui_find_iobject_path (Tcl_Interp *, ar, nl_kind, nl_idesign,
			  ui_find_mode, ar);
int ui_find_iobject (Tcl_Interp *, char *, char *, nl_kind, nl_idesign,
		     int, int, int, ar);
#endif

