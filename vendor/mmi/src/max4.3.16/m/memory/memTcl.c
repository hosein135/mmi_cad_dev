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
 * memTcl.c -- Tcl command interface to utils module.
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
 * memStatSizeCmd --
 *
 *      Implements tcl command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define mem_stat_size_DESC   "returns current memory heap size in bytes"

#define mem_stat_size_DOC "
usage:  mem_stat_size

Gives size of malloc arena (dyanamically allocated data space).
Does not include the initial program size.
"

static int
memStatSizeCmd(ClientData clientData, 
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
    char buf[BUFSIZ];
    unsigned long size = MemStatHeapSize();
    sprintf(buf,"%lu",size);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * memStatMallocCmd --
 *
 *      Implements tcl command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define mem_stat_malloc_DESC   "get malloc statistics"

#define mem_stat_malloc_DOC "
usage:  mem_stat_malloc

Returns:  num_mallocs num_frees malloc_bytes 

NOTE:  does not include direct calls to malloc/free, e.g. by tcl.
NOTE:  malloc_bytes NOT reduced by frees.

See also mem_stat_size, mem_stat_free, mem_stat_jay and mm_statistics
"

static int
memStatMallocCmd(ClientData clientData, 
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
    char buf[BUFSIZ];

    sprintf(buf,"%d %d %d", 
	    memNumMalloc, 
	    memNumFree,
	    memMallocedBytes);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * memStatJayCmd --
 *
 *      Implements tcl command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define mem_stat_jay_DESC   "get stats from Jay's memory manager"

#define mem_stat_jay_DOC "
usage:  mem_stat_jay

Prints stats to standard output.
"

static int
memStatJayCmd(ClientData clientData, 
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

  mem_show_usage();

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s\n", cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * memStatFreeCmd --
 *
 *      Implements tcl command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define mem_stat_free_DESC   "returns bytes of freed memory in malloc arena"

#define mem_stat_free_DOC "
usage:  mem_stat_free

Returns total size in bytes of free-lists in memory manager.
Does not include memory malloced/freed directly, e.g. by tcl.
"

static int
memStatFreeCmd(ClientData clientData, 
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
    char buf[BUFSIZ];
    sprintf(buf,"%lu",mem_usage_free());
    
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
 * MemTclInit --
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
MemTclInit(Tcl_Interp *interp)
{
  mmTclInit(interp);

  MnDocCreateCommand(interp, "mem_stat_size", memStatSizeCmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     mem_stat_size_DESC,
		     mem_stat_size_DOC);

  MnDocCreateCommand(interp, "mem_stat_malloc", memStatMallocCmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     mem_stat_malloc_DESC,
		     mem_stat_malloc_DOC);


  MnDocCreateCommand(interp, "mem_stat_jay", memStatJayCmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     mem_stat_jay_DESC,
		     mem_stat_jay_DOC);


  MnDocCreateCommand(interp, "mem_stat_free", memStatFreeCmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     mem_stat_free_DESC,
		     mem_stat_free_DOC);

  MnDocLinkVar(interp, "MEM_AUDIT", 
	       (char *) &MemAudit, TCL_LINK_INT,
	       "if set a line is output for each malloc/free",
"
  NOTE:  More useful, if compiled with MALLOC_TAGGED set in memory.h
");
}






