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
static char *rcsid = "$Id: MMITclProc.c,v 1.3 2000/10/19 23:12:43 pat Exp $";

/*
 *----------------------------------------------------------------------
 *
 * MMITcl_ProcCmd --
 *
 *      Wrapper around proc that does not allow proc or rename to be redefined
 *      Ignores -whatever options appearing between procedure arguments
 *      and procedure body so it ignores Michael Arnolds procedure
 *      documentation.  This is necessary just so other programs can
 *      use the "improved" documented tcl files.
 *
 * Aguments:
 *     objv[0]   "proc"
 *     objv[1]   procedure name
 *     objv[2]   procedure arguments
 *  Optional additional arguments for Michael Arnolds documentation scheme:
 *     objv[3+2n]   -doc, -desc
 *     objv[4+2n]   string for documentation
 *     objv[argc-1]   procedure body
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
MMITcl_ProcObjCmd(cdata, interp, objc, objv)
    ClientData cdata;			
    Tcl_Interp *interp;			/* Current interpreter. */
    int objc;                   /* Number of arguments. */
    Tcl_Obj *CONST objv[];      /* Argument objects. */

{
    extern int Tcl_ProcObjCmd();
    int i;
    Tcl_Obj *newobjv[4];

    if (objc>=4) {
	char *arg1 = Tcl_GetStringFromObj(objv[1],NULL);
	/* Do not permit the user to define a proc named "proc" or "rename".
	 */

	/* added modify_setup for SUE read_only */
	if ( strcmp(arg1,"proc")==0 || strcmp(arg1,"rename")==0 
	     || strcmp(arg1,"modify_setup")==0 ) {
	    Tcl_AppendResult(interp, 
		     "Can't redefine '",
		     arg1,
		     "' (MMI restricted version)",
		     NULL);
	    return TCL_ERROR;
	}

	if (objc % 2 != 0) {
	    Tcl_AppendResult(interp, 
		     "Error: wrong number of arguments to proc command",
		     NULL);
	    return TCL_ERROR;
	}

	/* Verify that any extra parameters look like -whatever.
	 */
	for (i = 3; i < objc-1; i += 2) {
	    char *option = Tcl_GetStringFromObj(objv[i],NULL);
	    if (*option != '-') {
		char buf[80];
		sprintf(buf,"%.78s",option);
		Tcl_AppendResult(interp, 
		     "Error: unrecognized argument to proc command: ",
		     option,
		     NULL);
		return TCL_ERROR;
	    }
	}

	newobjv[0] = objv[0];
	newobjv[1] = objv[1];
	newobjv[2] = objv[2];
	newobjv[3] = objv[objc-1];
	return Tcl_ProcObjCmd(cdata, interp, 4, newobjv);
    } else {
	/* Not enough arguments: this is an error.
	 * Let the TCL original proc function catch it and print the error.
	 */
	return Tcl_ProcObjCmd(cdata, interp, objc, objv);
    }
}
