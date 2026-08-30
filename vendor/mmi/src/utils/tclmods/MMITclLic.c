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
static char *rcsid = "$Id: MMITclLic.c,v 1.4 2000/10/19 23:12:43 pat Exp $";

/*
 *----------------------------------------------------------------------
 *
 * MMITcl_License --
 *
 *      Wrapper around MMI license check so it can be called from Tcl.
 *	Written by pat.
 *
 * Syntax:
 *	LicenseCheck [ -options ] <cap>
 * where:
 *	<cap> is the licensed capability you want to check.
 *	If no -options are specified, the license is checked out.
 *	If no license is available, the calling program prints
 *	an error message and exits immediately.
 *	Options can be:
 *	-return : return 1 if license found, if not print message
 *		and return 0.
 *	-check : check for capability and return 1 if found, 0 otherwise.
 *		This option prints no messages if license not found,
 *		and does not leave the license checked out:  if a license
 *		is found, it is immediately checked back in again
 *		before the function returns.
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

int
MMITcl_LicenseObjCmd(cdata, interp, objc, objv)
    ClientData cdata;			
    Tcl_Interp *interp;			/* Current interpreter. */
    int objc;                   /* Number of arguments. */
    Tcl_Obj *CONST objv[];      /* Argument objects. */
{
    char *arg1;
    int checkonly = 0;
    int result;

    if (objc < 2 || objc > 3) {
	    /* Not much of an error message, but better than nothing.
	     */
	    Tcl_AppendResult(interp,
		"Wrong number of arguments",
		NULL);
	    return TCL_ERROR;
    }
    arg1 = Tcl_GetStringFromObj(objv[1],NULL);
    if (strcmp(arg1,"-check") == 0 || strcmp(arg1,"-return") == 0) {
	checkonly = (strcmp(arg1,"-check") == 0) ? 3 : 2;
	if (objc != 3) {
	    /* Not much of an error message, but better than nothing.
	     */
	    Tcl_AppendResult(interp,
		"Invalid second argument",
		NULL);
	    return TCL_ERROR;
	}
	arg1 = Tcl_GetStringFromObj(objv[2],NULL);
    }
    // result = LicenseCheckCap(arg1,checkonly,NULL);
    result = 1;		// licences no longer needed
    Tcl_AppendResult(interp,result ? "1" : "0",NULL);
    return TCL_OK;
}
