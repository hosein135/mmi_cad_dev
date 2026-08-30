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
 * DRCtcl.c -- Tcl command interface to DRC module.
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "units.h"
#include "drc.h"
#include "drcInt.h"


/*
 *--------------------------------------------------------------
 *
 * drcTclCmdClear --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define drc_clear_DESC "test command: clear drc check info from all cells"

#define drc_clear_DOC "
clears check tiles and drcPending and drcAll flags from all cells.
"

static int
drcTclCmdClear(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    CellDef *def;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;
    if(argc!=0) goto usage;


    for(def=DBCellDefs; def; def=def->cd_next)
    {
      def->cd_flags &= ~(CD_DRC_PENDING | CD_DRC_ALL_PENDING);
      DBPlaneClearPaint(def->cd_planes[PL_DRC_CHECK]);
    }
    CMD_RETURN(interp);
    
usage:
    MsgErrorF("usage:  %s\n",
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * drcTclCmdClean --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define drc_clean_DESC "Declare cell free of drc errors (whether it really is or not)"

#define drc_clean_DOC "

Usage: drc_clean [-cell cell_name]

If no -cell option, defaults to edit cell.

Clears any existing error tiles, or pending checks for cell.
Syncs up instance versions, so parent/instance interactions not checked.
Subsequent changes to cell, parents or descendents will cause effected areas to
be checked.

NOTE: this is a dangerous command, can cause DRC violations to be overlooked!
"

static int
drcTclCmdClean(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='c' && strncmp(*argv,"-cell",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	def = DBCellLookDef(*argv);
	if(!def)
	{
	  MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		  cmdName, *argv);
	  CMD_RETURN(interp);
	}
	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    if(argc!=0) goto usage;

    DRCClean(def);
    CMD_RETURN(interp);
    
usage:
    MsgErrorF("usage:  %s [-cell cell_name]\n", 
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * drcTclCmdWithParent --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define drc_with_parent_DESC "disable independent drc of a cell"

#define drc_with_parent_DOC "
usage: drc_with_parent [-cell cell_name]

If no -cell, defaults to edit cell.
"

static int
drcTclCmdWithParent(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='c' && strncmp(*argv,"-cell",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	def = DBCellLookDef(*argv);
	if(!def)
	{
	  MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		  cmdName, *argv);
	  CMD_RETURN(interp);
	}
	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    if(argc!=0) goto usage;

    /* set flag */
    def->cd_flags |= CD_DRC_WITH_PARENT;

    /* clear DRC info in cell */
    DBPlaneClearPaint(def->cd_planes[PL_DRC_CHECK]);
    DBPlaneClearPaint(def->cd_planes[PL_DRC_ERROR]);

    /* TODO clear DRC pending etc. flags? */
    /* TODO notify ? */ 

    CMD_RETURN(interp);
    
usage:
    MsgErrorF("usage:  %s [-cell cell_name]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DRCTclInit --
 *
 * Initialize drc tcl commands, and link C and tcl variables..
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCTclInit(Tcl_Interp *interp)
{
  MnDocLinkVar(interp, "drc_on", (char *) &DRCBackGround, 
	      TCL_LINK_BOOLEAN,
	      "turns background checker on/off",
	      "LOW-LEVEL, USE INSTEAD: `pal_special_on drc', `pal_special_off drc'");

  MnDocLinkVar(interp, "drc_busy", (char *) &DRCBusy, 
	      TCL_LINK_BOOLEAN | TCL_LINK_READ_ONLY,
	      "non-nil when background checker has work to do",
	      NULL);

  MnDocLinkVar(interp, "DRC_STEP_SIZE", 
	       (char *) &drcStepSizeWidths, TCL_LINK_INT,
	       "drc processing step size in typical wire widths",
	       "e.g. if 1000, then processing is broken down" 
	       " into squares 1000 typical wire widths on a side");


  MnDocLinkVar(interp, "DRC_PRIORITY", 
	       (char *) &DRCPriority, TCL_LINK_INT,
	       "scheduling priority of background drc vs event queue",
	       "lower number = higher priority.

                if n=DRC_PRIORITY<0  -n drc chunks checked between events.

                if n=DRC_PRIORITY>0, n pending events processed between 
                drc checks");

  MnDocCreateCommand(interp, "*drc_clear", drcTclCmdClear,
	     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	     drc_clear_DESC,
	     drc_clear_DOC);

  MnDocCreateCommand(interp, "drc_clean", drcTclCmdClean,
	     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	     drc_clean_DESC,
	     drc_clean_DOC);

  MnDocCreateCommand(interp, "drc_with_parent", drcTclCmdWithParent,
	     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	     drc_with_parent_DESC,
	     drc_with_parent_DOC);
}





