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
 * MgcGlobal.c --
 *
 * 	This file contains initialization code for the Magic global commands
 *      (now part of the Mgc package)
 *
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <tcl.h>
#include "magic.h"
#include "commands.h"
#include "layout.h"
#include "layout.h"
#include "windglobal.h"
#include "mgcint.h"
#include "Mgc.h"
#include "main.h"

/* 
 * GLOBAL COMMAND TABLES
 *
 * mgcGlobalCmds	 - contains three strings for each command:
 *                           [0] name and args
 *                           [1] one line description
 *                           [2] additional documentation of any length.
 *
 *mgcGlobalFuncs         - contains pointers to the routines implementing the 
 *                         commands.
*/

static char *mgcGlobalCmds[] =
    {
	"*crash",			
        "cause a core dump",
	"",

	"*profile on|off",
	"toggle runtime profiling",
	"",

	"center",
	"center window on the cursor",
	"",

	"redo [count]",
	"redo commands",
	"See also :undo.",

	"scroll dir [amount]",
	"scroll the window",
	"
dir is N,S,E, or W.
amount is number of windows to move over (default is .5).

For example, ':scroll N 1' moves the view up one window height.
",

	"undo [count]",
	"undo commands",
	"See also :redo.",

	"view",
	"adjust view so everything is visible",
	"",

	"zoom amount",
	"zoom window by amount",
	"
amount is factor to zoom out by.

Examples:
':zoom 2' - zooms out by a factor of two.
':zoom .5' - zooms in by a factor of two.
",
  
	0
    };

static void (*mgcGlobalFuncs[])() =
    {
	windCrashCmd,
	windProfileCmd,
	windCenterCmd,
	windRedoCmd,
	windScrollCmd,
	windUndoCmd,
	windViewCmd,
	windZoomCmd
    };

/*
 * ----------------------------------------------------------------------------
 *
 * mgcGlobalCmdWrapper --
 *
 * Tcl command procedure!
 * Called back by tcl interp for magic global commands
 *
 * Results:
 *	TODO.
 *
 * Side effects:
 *	Command is executed.
 *	
 * ----------------------------------------------------------------------------
 */
/* TODO:  Is there away to use function prototype and cast func here? */
int
mgcGlobalCmdWrapper(func,interp,argc,argv)
   void func();
   Tcl_Interp *interp;
   int argc;
   char *argv[];
{
  int i;
  TxCommand cmd;
  Layout *w;

  CMD_BEGIN(interp);

  /* get current layout window */
  w = LayCurWindow();
  ASSERT(w,"mgcGlobalCmdWrapper");  

  /* increment magic command Number */
  MgcCommandNumber++;

  /* copy argc, argv to command struc */
  ASSERT(argc<=TX_MAXARGS,"mgcGlobalCmdWrapper");
  cmd.tx_argc = argc;
  for(i=0; i<argc; i++)
  {
      cmd.tx_argv[i] = argv[i];
  }

  /* Finally call the Magic command routine */
  (func)(w, &cmd);

  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * mgcGlobalInit --
 *
 * Register the Magic Layout commands in the above tables with tcl.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Register Magic layout commands.
 *	
 * ----------------------------------------------------------------------------
 */

void
mgcGlobalInit(Tcl_Interp *interp )
{
  char **commandp = mgcGlobalCmds;
  void (**funcp)() = mgcGlobalFuncs; 

  for(;*commandp;commandp += 3,funcp++)
  {
      char c;
      int nameLength;
      Tcl_DString name, doc;

      /* get command name */
      for(nameLength=0; c=(*commandp)[nameLength]; nameLength++)
      {
	if( c==' ' || c=='\t' || c=='\n') break;
      }
      Tcl_DStringInit(&name);
      Tcl_DStringAppend(&name,":",-1);
      Tcl_DStringAppend(&name,*commandp,nameLength);

      /* build doc string */
      Tcl_DStringInit(&doc);
      Tcl_DStringAppend(&doc,"Usage:   :",-1);
      Tcl_DStringAppend(&doc,commandp[0],-1);
      Tcl_DStringAppend(&doc,"\n\n",-1);
      Tcl_DStringAppend(&doc,commandp[2],-1);

      /* register with tcl */
      MnDocCreateCommand(interp, 
		  Tcl_DStringValue(&name),
		  mgcGlobalCmdWrapper,
		  (ClientData) *funcp,
		  (Tcl_CmdDeleteProc *) NULL,
		  commandp[1],  /* desc */
		  Tcl_DStringValue(&doc) 
		  );


      /* clean up */
      Tcl_DStringFree(&name);
      Tcl_DStringFree(&doc);
  }
}







