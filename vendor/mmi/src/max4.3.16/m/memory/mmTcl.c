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
 * mmTcl.c -- Tcl command interface to mm (memory monitor)
 */

static char rcsid[] = "$Header$";

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <tcl.h>
#include <tk.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "utils.h"
#include "mm.h"

/*
 * ----------------------------------------------------------------------------
 *
 * mmCheckCmd --
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

#define mm_check_DESC "check memory consistency." 

#define mm_check_DOC "
prints error message and aborts on inconsistencies.
"

static int    
mmCheckCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    CMD_BEGIN(interp);

    /* if there is no arg, exit with backup */ 
    if (argc != 1)  goto usage;

    MM_Check();

    CMD_RETURN(interp);

  usage:
    MsgErrorF("Usage:  %s\n",argv[0]);
    CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mmStatisticsCmd --
 *
 * Implements Tcl command
 *
 * C Result:
 *	A standard Tcl result
 *
 * ----------------------------------------------------------------------------
 */

#define mm_statistics_DESC "print memory monitor statistics"

#define mm_statistics_DOC "

Info printed to stderr.
Requires Max to be run with '-mm' (memory monitor) command line flag.
See also 'mem_stat_malloc'.
"

static int    
mmStatisticsCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    CMD_BEGIN(interp);

    /* if there is no arg, exit with backup */ 
    if (argc != 1)  goto usage;

    MM_Statistics();

    CMD_RETURN(interp);

  usage:
    MsgErrorF("Usage:  %s\n",argv[0]);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * mmTclInit --
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
mmTclInit(Tcl_Interp *interp)
{
  MnDocCreateCommand(interp, "mm_check", mmCheckCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mm_check_DESC, mm_check_DOC);

  MnDocCreateCommand(interp, "mm_statistics", mmStatisticsCmd,
		(ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		mm_statistics_DESC, mm_statistics_DOC);

  MnDocLinkVar(interp, "MM_CHUNK_SIZE", 
	      (char *) &MMChunkSize, TCL_LINK_INT,
	       "chunk size of memory grabs (memory monitor)",
	       "
This parameter only applies when the memory monitor is on.
The memory monitor, used for debugging MALLOC/FREE problems,
is enabled with the -mm command line option.
");
	       
  MnDocLinkVar(interp, "MM_HOLD_MAX", 
	      (char *) &MMHoldMax, TCL_LINK_INT,
	       "maximum bytes on hold list (memory monitor)",
	       "
This parameter only applies when the memory monitor is on.
The memory monitor, used for debugging MALLOC/FREE problems,
is enabled with the -mm command line option.
");

  MnDocLinkVar(interp, "MM_CHECK_INTERVAL", 
	      (char *) &MMCheckInterval, TCL_LINK_INT,
	       "number of mallocs between memory checks",
	       "
This parameter only applies when the memory monitor is on.
The memory monitor, used for debugging MALLOC/FREE problems,
is enabled with the -mm command line option.
");
	       
  MnDocLinkVar(interp, "MM_STATISTICS_INTERVAL", 
	      (char *) &MMStatisticsInterval, TCL_LINK_INT,
	       "number of mallocs between statistics reports",
	       "
This parameter only applies when the memory monitor is on.
The memory monitor, used for debugging MALLOC/FREE problems,
is enabled with the -mm command line option.
");
}
