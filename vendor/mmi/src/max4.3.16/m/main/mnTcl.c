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
 * mnTcl.c -- Tcl command interface to main module
 */

static char rcsid[] = "$Header$";

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/times.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>
#include "magic.h"
#include "main.h"
#include "mainInt.h"
#include "message.h"
#include "signals.h"
#include "database.h"
#include "units.h"
#include "utils.h"

/*
 * ----------------------------------------------------------------------------
 *
 * mnExitTclCmd --
 *
 * Tcl command to exit.  
 *
 * C Result:
 *	Normally none (does not return - unless error)
 *
 * Side effects:
 *       exit with or without backup of modified buffers.
 *
 * ----------------------------------------------------------------------------
 */

#define mn_exit_DESC "\
exit max (with or without backups)"

#define mn_exit_DOC "
Usage:  mn_exit [-nobackup]

Main use of this routine is to exit without backing up modified files.
(If backups are desired plain 'exit' or even 'abort' works fine.)
"

static int    
mnExitTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    CMD_BEGIN(interp);

    /* if there is no arg, exit with backup */ 
    if (argc == 1) 
    {
       mnBackupOnExit = TRUE;   
       exit(0);
    }

    if (argc==2 && strcmp(argv[1],"-backup")==0)
    {
       mnBackupOnExit = TRUE;   
       exit(0);
    }
    else if (argc==2 && strcmp(argv[1],"-nobackup")==0)
    {
       mnBackupOnExit = FALSE;   
       exit(0);
    }   

    /* if we got here, usage error */
    MsgErrorF("Usage:  %s [-backup | -nobackup]\n",argv[0]);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * mnTicTclCmd --
 *
 * Tcl command.
 *
 * C Result:
 *	Normally none (does not return - unless error)
 *
 * Side effects:
 *       exit with or without backup of modified buffers.
 *
 * ----------------------------------------------------------------------------
 */

#define mn_tic_DESC "\
note the passage of time."

#define mn_tic_DOC "
Usage:  mn_tic [time]

time is estimate of time passed in milliseconds (defaults to 1).

Causes check for passage of time (when cumulative value reaches threshold),
and call to service routine if a second has 'ticed' by.

The service routine keeps the X-connection alive, checks for Cntl-C 
from user etc.
"

static int    
mnTicTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    char *cmdName;
    int value = 1;

    CMD_BEGIN(interp);


    /*** parse args ***/

    cmdName = *argv;
    argv++; argc--;

    if(argc)
    {
      if(sscanf(*argv,"%d",&value)!=1) goto usage;
      argv++; argc--;

    }
    if(argc) goto usage;

/* DEBUG
    fprintf(stderr,"mn_tic:  DEBUG delay loop!\n");
    {
      int j=0;
      while(j<200)
      {
	int i = 0;
	while(i<1000*1000) i++;
	j++;
      }
    }
*/

    MnTic(100*value);

/*
    fprintf(stderr,"mn_tic:  DEBUG delay loop2!\n");
    {
      int j=0;
      while(j<200)
      {
	int i = 0;
	while(i<1000*1000) i++;
	j++;
      }
    }
*/

    MnTic(100*value);

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [time]\n", cmdName);
    CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnButtonStateTclCmd --
 *
 * Tcl command.
 *
 *
 * ----------------------------------------------------------------------------
 */

#define mn_button_state_DESC "
returns list of mouse buttons that are down (and modifiers)
"

#define mn_button_state_DOC "
Usage:  mn_button_state
"

static int    
mnButtonStateTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    char *cmdName;
    Window rootW, childW;
    int rootX, rootY, winX, winY;
    unsigned int bMask;

    CMD_BEGIN(interp);

    /* process args */
    cmdName = *argv;
    argv++; argc--;
    if(argc!=0) goto usage;

    XQueryPointer(Tk_Display(MainTkWin), 
		  Tk_WindowId(MainTkWin),
		  &rootW, &childW, &rootX, &rootY, &winX, &winY,
		  &bMask);

    if(bMask & ShiftMask) Tcl_AppendElement(interp, "Shift");
    if(bMask & LockMask) Tcl_AppendElement(interp, "Lock");
    if(bMask & ControlMask) Tcl_AppendElement(interp, "Control");
    if(bMask & Mod1Mask) Tcl_AppendElement(interp, "Mod1");
    if(bMask & Mod2Mask) Tcl_AppendElement(interp, "Mod2");
    if(bMask & Mod3Mask) Tcl_AppendElement(interp, "Mod3");
    if(bMask & Mod4Mask) Tcl_AppendElement(interp, "Mod4");
    if(bMask & Mod5Mask) Tcl_AppendElement(interp, "Mod5");
    if(bMask & Button1Mask) Tcl_AppendElement(interp, "Button1");
    if(bMask & Button2Mask) Tcl_AppendElement(interp, "Button2");
    if(bMask & Button3Mask) Tcl_AppendElement(interp, "Button3");
    if(bMask & Button4Mask) Tcl_AppendElement(interp, "Button4");
    if(bMask & Button5Mask) Tcl_AppendElement(interp, "Button5");
			
    CMD_RETURN(interp);

usage:
    MsgErrorF("Usage:  %s",cmdName);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * mnLoadMCTclCmd --
 *
 * Tcl command.
 *
 *
 * ----------------------------------------------------------------------------
 */

#define mn_load_mc_DESC "
load megacell compiler.
"

#define mn_load_mc_DOC "
Usage:  mn_load_mc

NOTE:  This command attempts to acquire an MC license each time it is called,
       so should not be called if MC already loaded ($MC(loaded) == 1). 
"

static int    
mnLoadMCTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    char *cmdName;
    char *cap = "max_mcc";

    CMD_BEGIN(interp);

    /* process args */
    cmdName = *argv;
    argv++; argc--;
    if(argc!=0) goto usage;

    mnScriptSourceMC(MnInterp);

    CMD_RETURN(interp);

usage:
    MsgErrorF("Usage:  %s",cmdName);
    CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnPathFindTclCmd --
 *
 * Tcl command.
 *
 *
 * ----------------------------------------------------------------------------
 */

#define mn_path_find_DESC "
look up file in given directory path
"

#define mn_path_find_DOC "
Usage:  mn_path_find directory_list file_name

Returns full path name of first readable occurance of file_name in 
directory_list, or NULL if none.

(Use with directory_list of $MN_PATH_CELL to search for files in cell (design) path.)
"

static int    
mnPathFindTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    char *cmdName;
    char *path;
    char *fileName;

    CMD_BEGIN(interp);

    /* process args */
    cmdName = argv[0];
    if(argc!=3) goto usage;
    path = argv[1];
    fileName = argv[2];
    
    /* look it up! */
    {
      char *fullName;
      FILE *fp;

      fp = PaOpen(fileName, "r", NULL, path, &fullName);

      if(fp)
      {
	fclose(fp);
	Tcl_SetResult(interp, fullName,TCL_VOLATILE);
      }
    }
			
    CMD_RETURN(interp);

usage:
    MsgErrorF("Usage:  %s directory_list file_name",argv[0]);
    CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnSysFindTclCmd --
 *
 * Tcl command.
 *
 *
 * ----------------------------------------------------------------------------
 */

#define mn_sys_find_DESC "
look up file in system library path
"

#define mn_sys_find_DOC "
Usage:  mn_sys_find file_name

Returns full path name of first readable occurance of file_name in 
system library path (tcl variable MN_PATH_SYS_LIB), or NULL if none.
"

static int    
mnSysFindTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    char *cmdName;
    char *fileName;

    CMD_BEGIN(interp);

    /* process args */
    cmdName = argv[0];
    if(argc!=2) goto usage;
    fileName = argv[1];
    
    /* look it up! */
    {
      char *fullName;
      FILE *fp;

      fp = PaOpen(fileName, "r", NULL, MnPathSysLib, &fullName);

      if(fp)
      {
	fclose(fp);
	Tcl_SetResult(interp, fullName,TCL_VOLATILE);
      }
    }
			
    CMD_RETURN(interp);

usage:
    MsgErrorF("Usage:  %s file_name",argv[0]);
    CMD_RETURN(interp);
}
  
/*
 * ----------------------------------------------------------------------------
 *
 * MnTclEvalBg --
 *
 * Tcl Eval a string.
 * wrapper for Tcl_Eval with some error checking.
 *
 * Error reporting, assumes this is a background call, 
 * e.g. triggered by 'async' event such as redisplay or load on demand.
 *
 * NOTE: resets tcl result on success.
 *
 * Results:
 *	TRUE on success FALSE on failure.
 *
 * ----------------------------------------------------------------------------
 */
bool MnTclEvalBg(char *script,    /* string to eval */
		 char *errMsg)    /* add to errorInfo on error */ 
{
  bool retCode;

  /* check that we are not stomping on an existing result */
  ASSERT(!CMD_INSIDEQ(interp) || *Tcl_GetStringResult(MnInterp)=='\0', "MnTclEval");

  /* do it */
  retCode = Tcl_Eval(MnInterp, script);

  /* check return code */
  if(retCode == TCL_OK)
  {
    Tcl_ResetResult(MnInterp);
    return TRUE;
  }
  else
  {
    /* error */
    char msg[BUFSIZ];

    sprintf(msg,"\n\t(%s)", errMsg ? errMsg : "MnTclEval");

    Tcl_AddErrorInfo(MnInterp, msg);
    Tcl_BackgroundError(MnInterp);
    return(FALSE);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * MnTclSetLinkedString --
 *
 * Set linked tcl string variable.  
 * (free old value, and copy new value to freshly malloced block).
 *
 * Results:
 *	None.
 *
 * NOTE:  Critical to use system malloc() and free() here, for 
 *	  compatibility with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void MnTclSetLinkedString(char **sp, char *value)
{
   if(*sp) free(sp);

  if(!value)
  {
    *sp = NULL;
  }
  else
  {
    int l = strlen(value);
    *sp = (char *) malloc(l+1);
    strcpy(*sp,value);
  }

  return;
}
  

/*
 * ----------------------------------------------------------------------------
 *
 * mnTclInit --
 *
 * Initialize tcl commands in this module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
mnTclInit(Tcl_Interp *interp)
{
  MsgTclInit(interp);
  mnUnitsTclInit(interp);
  DebugTclInit(interp);

  MnDocCreateCommand(interp, "mn_exit", mnExitTclCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mn_exit_DESC, mn_exit_DOC);

  MnDocCreateCommand(interp, "mn_tic", mnTicTclCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mn_tic_DESC, mn_tic_DOC);

  MnDocCreateCommand(interp, "mn_path_find", mnPathFindTclCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mn_path_find_DESC, mn_path_find_DOC);

  MnDocCreateCommand(interp, "mn_sys_find", mnSysFindTclCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mn_sys_find_DESC, mn_sys_find_DOC);

  MnDocCreateCommand(interp, "mn_button_state", mnButtonStateTclCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mn_button_state_DESC, mn_button_state_DOC);

  MnDocCreateCommand(interp, "mn_load_mc", mnLoadMCTclCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mn_load_mc_DESC, mn_load_mc_DOC);

  MnDocLinkVar(interp, "MN_PATH_CELL", 
	       (char *) &MnPathCell, TCL_LINK_STRING,
	       "search path for cells",
	       NULL);
  MnDocLinkVar(interp, "MN_PATH_SYS_LIB", 
	      (char *) &MnPathSysLib, TCL_LINK_STRING,
	      "search path for system files",
	       NULL);
  MnDocLinkVar(interp, "MN_TYPICAL_WIRE_WIDTH", 
	      (char *) &mnTypicalWireWidthUser, TCL_LINK_DOUBLE,
	      "typical feature size in microns",
	      "if negative, m1 width (DRC rule) is used instead.");
}









