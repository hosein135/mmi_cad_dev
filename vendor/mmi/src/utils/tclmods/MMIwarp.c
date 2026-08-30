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

#include <tk.h>
#include "tclInt.h"
static char *rcsid = "$Id: MMIwarp.c,v 1.2 2000/10/19 23:12:43 pat Exp $";

/*
 *----------------------------------------------------------------------
 *
 *  Warp the cursor
 *
 *----------------------------------------------------------------------
 */

int
MMITcl_WarpObjCmd(clientData,interp,objc,objv)
     ClientData clientData;
     Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];      /* Argument objects. */
{
  /*  Tk_Window main = (Tk_Window) clientData; */
  Tk_Window tkwin;
  int x,y;

  if (objc != 3) {
    interp->result = "ERROR, syntax is: warp_cursor x y.";
    return TCL_ERROR;
  }

  tkwin = Tk_MainWindow(interp);

  x = atoi(Tcl_GetStringFromObj(objv[1],NULL));
  y = atoi(Tcl_GetStringFromObj(objv[2],NULL));

  /* move the X cursor */
  XWarpPointer(
	       Tk_Display(tkwin),     /* display */
	       None,                  /* src window */
	       Tk_WindowId(tkwin),    /* dest window */
	       0,                     /* src x */
	       0,                     /* src y */
	       0,                     /* src width */
	       0,                     /* src height */
	       x,                     /* dest x */
	       y                      /* dest y */
	       );

  return TCL_OK;
}

