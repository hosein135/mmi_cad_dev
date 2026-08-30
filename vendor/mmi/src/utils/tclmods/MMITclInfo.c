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
/* #include "tclPort.h" */
/* #include "tclCompile.h" */
static char *rcsid = "$Id: MMITclInfo.c,v 1.6 2000/10/19 23:12:43 pat Exp $";

/*
 *----------------------------------------------------------------------
 * MMITcl_InfoCmd --
 *
 *      Restricted version of Tcl_InfoCmd ("info"):
 *
 *	  "info body"     - disabled (UNLESS bodyOk arg set to 1)
 *	  "info commands" - requires fixed name (no wildcarding)
 *        "info globals"  - requires fixed name (no wildcarding)
 *        "info procs"    - requires fixed name (no wildcarding)
 *        "info vars"     - requires fixed name (no wildcarding)
 *
 *
 *	This procedure is invoked to process the "info" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Tcl_InfoObjCmd --
 *
 *	This procedure is invoked to process the "info" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
int
MMITcl_InfoObjCmd(bodyOK, interp, objc, objv)
    ClientData bodyOK;		/* if nonzero, allow info body. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    char *subcmd;
    char *arg2;
    int result;

    if (objc < 2) {
        Tcl_WrongNumArgs(interp, 1, objv, "option ?arg arg ...?");
        return TCL_ERROR;
    }

    subcmd = Tcl_GetStringFromObj(objv[1],NULL);

    if (*subcmd == 'b' && strncmp(subcmd,"body",1) == 0) {
        /* special for SUE, only allow on ICON_* and SCHEMATIC_* */
        arg2 = Tcl_GetStringFromObj(objv[2],NULL);
        if (strncmp(arg2,"ICON_",5) == 0) { goto itsok; }
        if (strncmp(arg2,"SCHEMATIC_",10) == 0) { goto itsok; }

	if (!bodyOK) {
	    Tcl_AppendResult(interp, "\"info body\" disabled.",NULL);
	    return TCL_ERROR;
	}
    }
    else if (*subcmd == 'c' && strncmp(subcmd,"commands",4) == 0) {
	if (objc != 3) {
	    wrong_number_args:
	    Tcl_AppendResult(interp,
		"wrong # args: should be \"info ",subcmd," name\"",
		" (restricted MMI version)", (char *) NULL);
	    return TCL_ERROR;
	}

	arg2 = Tcl_GetStringFromObj(objv[2],NULL);

	/* Special hack for Sue:  allow "info commands icon_*" */
	if (strcmp(arg2,"ICON_*") == 0) { goto itsok; }

	if (strpbrk(arg2,"*?")) {
	    wildcard_disabled:
	    Tcl_AppendResult(interp, "wildcarding for \"info ",
		subcmd,
		"\" is disabled.", (char *) NULL);
	    return TCL_ERROR;
	}
    }
    else if (*subcmd == 'g' && strncmp(subcmd,"globals",1) == 0) {
	if (objc != 3) {
	    goto wrong_number_args;
	}
	arg2 = Tcl_GetStringFromObj(objv[2],NULL);

	/* Special hack for Gary using Sue:
	 * allow all patterns beginning with "_" 
	 */
	if(*arg2 == '_') { goto itsok; }

	if (strpbrk(arg2,"*?")) {
	    goto wildcard_disabled;
	}
    }
    else if (*subcmd == 'p' && strncmp(subcmd,"procs",2) == 0) {
	if (objc != 3) {
	    goto wrong_number_args;
	}
	arg2 = Tcl_GetStringFromObj(objv[2],NULL);
	if (strpbrk(arg2,"*?")) {
	    goto wildcard_disabled;
	}
    }
    else if (*subcmd == 'v' && strncmp(subcmd,"vars",1) == 0) {
	if (objc != 3) {
	    goto wrong_number_args;
	}

	arg2 = Tcl_GetStringFromObj(objv[2],NULL);

	/* Special hack for MCC:  allow "info vars _MC_CP_*" */
	if (strcmp(arg2,"_MC_CP_*") == 0) { goto itsok; }

	if (strpbrk(arg2,"*?")) {
	    goto wildcard_disabled;
	}
    }
    itsok:

    return Tcl_InfoObjCmd(0, interp, objc, objv);
}
