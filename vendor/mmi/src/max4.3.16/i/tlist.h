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
 * tlist.h --
 *
 * Tcl list object convenience routines.
 *
 */

#ifndef	_DATABASE
#include "database.h"
#endif	_DATABASE

Tcl_Obj *
TListAppendStr(Tcl_Interp *interp, 
	       Tcl_Obj *tList,        /* if null, creates new list */
	       char *str);

Tcl_Obj *
TListAppendInt(Tcl_Interp *interp, 
	       Tcl_Obj *tList,         /* if null, creates new list */
	       int n);

Tcl_Obj *
TListAppendDouble(Tcl_Interp *interp, 
		  Tcl_Obj *tList,      /* if null, creates new list */
		  double f);

Tcl_Obj *
TListAppendObj(Tcl_Interp *interp, 
	       Tcl_Obj *tList,         /* if null, creates new list */
	       Tcl_Obj *obj);


Tcl_Obj *
TListAppendTPath(Tcl_Interp *interp, 
		 Tcl_Obj *tList,         /* if null, creates new list */
		 TerminalPath *tPath);








