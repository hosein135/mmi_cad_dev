// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
// LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
// CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
// DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
// INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
// DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
// PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

/* mmiInterrupt.c -- 
 *
 * implements tcl command to check for Control-C in X event queue.
 */

#include <stdio.h>
#include <tcl.h>
#include <tk.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>

/*
 * ----------------------------------------------------------------------------
 *
 * isControlC --
 *
 * predicate procedure passed to XCheckIfEvent() to 
 * to see if Control-c event pending.
 *
 * ----------------------------------------------------------------------------
 */
static Bool IsControlC(Display *display, XEvent *event, XPointer arg)
{
  /* key press? */ 
  if(event->xany.type != KeyPress) return False;

  /* control down? */
  if((event->xkey.state&ControlMask) == 0) return False;

  /* c key? */
  if(XLookupKeysym(&event->xkey,0) != XK_c) return False;

  return True;
}

/*
 * ----------------------------------------------------------------------------
 *
 * mmiInterruptCmd --
 *
 * checks to see if Control-c event pending.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * ----------------------------------------------------------------------------
 */

static int    
mmiInterruptCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
  char *cmdName;
  XEvent event;
  Display *display;

  /* parse command name */
  cmdName = *argv;
  argv++; argc--;

  /* should be no args */
  if (argc != 0) goto usage;
		 
  /* get the X display */
  {
    Tk_Window tkWin = Tk_MainWindow(interp);

    /* make sure we are initialized */
    Tk_MakeWindowExist(tkWin);

    /* get X display */
    display = Tk_Display(tkWin);
  }

  /* check the queue */
  if(XCheckIfEvent(display,               /* X display */
		   &event,                /* event copied here, 
					   * (we just toss it) 
					   */
		   IsControlC,            /* predicate procedure 
					   * (applied to every event in queue)
					   */
		   NULL)                  /* passed to predicate */
     == True)
  {
    Tcl_SetResult(interp, "1", TCL_STATIC);
  } else {
    Tcl_SetResult(interp, "0", TCL_STATIC);
  }
  return TCL_OK;
  
 usage:
  Tcl_AppendResult(interp, "usage:  ",cmdName, NULL);
  return TCL_ERROR;
}

/*
 * ----------------------------------------------------------------------------
 *
 * mmiInterruptInit --
 *
 * called at startup time, registers "mmi_interrupt" command
 *
 * C Result:
 *	A standard Tcl result.
 *
 * ----------------------------------------------------------------------------
 */
mmiInterruptInit(Tcl_Interp *interp)
{
  Tcl_CreateCommand(interp, "mmi_interrupt", mmiInterruptCmd,
		    NULL, NULL);
}

