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

#include "tclInt.h"
static char *rcsid = "$Id: MMITclRename.c,v 1.3 2000/10/19 23:12:43 pat Exp $";

/*
 *----------------------------------------------------------------------
 *
 * MMITcl_RenameCmd --
 *
 *      Wrapper around rename that does not allow proc or rename to be redefined
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

int
MMITcl_RenameObjCmd(cdata, interp, objc, objv)
    ClientData cdata;			
    Tcl_Interp *interp;			/* Current interpreter. */
    int objc;                   /* Number of arguments. */
    Tcl_Obj *CONST objv[];      /* Argument objects. */
{
    extern int Tcl_RenameObjCmd();

    if( objc>=3) {
	char *arg2 = Tcl_GetStringFromObj(objv[2],NULL);
	/* added modify_setup for SUE read_only */
	if ( strcmp(arg2,"proc")==0 
	     || strcmp(arg2,"rename")==0 
	     || strcmp(arg2,"modify_setup")==0
	     || strncmp(arg2,"SCHEMATIC_",10) == 0
	     || strncmp(arg2,"ICON_",5) == 0
	  ) {
	    Tcl_AppendResult(interp,
		"Can't redefine '",
		arg2,
		"' (MMI restricted version)",
		NULL);
	    return TCL_ERROR;
	}
    }

    return Tcl_RenameObjCmd(cdata, interp, objc, objv);
}
