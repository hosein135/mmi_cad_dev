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
 * utlsTcl.c -- Tcl command interface to utils module.
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "utils.h"
#include "memory.h"


/*
 *--------------------------------------------------------------
 *
 * utlsStatTimeCmd --
 *
 *      Implements tcl command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define utls_stat_time_DESC   "current user, system and real (elapsed) time"

#define utls_stat_time_DOC "
usage:  utls_stat_time

Returns:  user system real

These are the times for the Max process in seconds.
"

static int
utlsStatTimeCmd(ClientData clientData, 
		Tcl_Interp *interp, 
		int argc, 
		char **argv)
{
  char *cmdName;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* none yet */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* should be no arguments left */
  if(argc>0) goto usage;

  {
    double user,system,real;
    char buf[BUFSIZ];

    UtlsStatProcessTimes(&user,&system,&real);
    sprintf(buf,"%g %g %g", 
	    user, 
	    system,
	    real);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s\n", cmdName);
  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * UtlsTclInit --
 *
 * Initialize tcl commands for this module.
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
UtlsTclInit(Tcl_Interp *interp)
{
  MnDocCreateCommand(interp, "utls_stat_time", utlsStatTimeCmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     utls_stat_time_DESC,
		     utls_stat_time_DOC);
}






