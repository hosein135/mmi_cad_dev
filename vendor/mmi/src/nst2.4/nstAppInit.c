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


/* 
 * tkAppInit.c --
 *
 *	Provides a default version of the Tcl_AppInit procedure for
 *	use in wish and similar Tk-based applications.
 *
 * Copyright (c) 1993 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tkAppInit.c 1.21 96/03/26 16:47:07
 */

#include "tclInt.h"
#include "tk.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>


#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 1
#endif


/*
 * The following variable is a special hack that is needed in order for
 * Sun shared libraries to be used for Tcl.
 */

extern int matherr();
int *tclDummyMathPtr = (int *) matherr;

#ifdef TK_TEST
EXTERN int		Tktest_Init _ANSI_ARGS_((Tcl_Interp *interp));
#endif /* TK_TEST */

/*
 *----------------------------------------------------------------------
 *
 * main --
 *
 *	This is the main program for the application.
 *
 * Results:
 *	None: Tk_Main never returns here, so this procedure never
 *	returns either.
 *
 * Side effects:
 *	Whatever the application does.
 *
 *----------------------------------------------------------------------
 */

char geometry[30];
char *MMI_TOOLS, *MMI_LOCAL;
char *progname = "";

char nst_tcl[] = {
#include "nstInit"
};


/* Copyright notice for the binary file. */
char *MainCopyright = "\n"\
"NST IS IN THE PUBLIC DOMAIN.\n";


int
main(argc, argv)
    int argc;			/* Number of command-line arguments. */
    char **argv;		/* Values of command-line arguments. */
{

  char **nst_argv;
  int i;


  progname = argv[0];	/* For error messages */

  /* Versions are of the form MMI_NST<major>.<minor>.<inc> */
  printf ("Micro Magic NST, Version MMI_NST%s Compiled %s\n", NST_VERSION, __DATE__);

  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i],"-v") == 0 || strcmp(argv[i],"-version") == 0) {
      /* user just wanted header, so exit */
      exit(0);      
    }
  }

  MMI_TOOLS = getenv("MMI_TOOLS");
  if(!MMI_TOOLS) {
    fprintf(stderr,"ERROR, aborting NST.  Can't find environment variable MMI_TOOLS.\n");
    exit(1);
  }

  MMI_LOCAL = getenv("MMI_LOCAL");
  if(!MMI_LOCAL) {
    char buf[BUFSIZ];
    /* default to ${MMI_TOOLS}/../mmi_local */
    MMI_LOCAL = (char*) malloc(1024);
    sprintf (MMI_LOCAL, "%s/../mmi_local", MMI_TOOLS);
    sprintf (buf,"MMI_LOCAL=%s",MMI_LOCAL);
    /* set the environment variable */
    putenv(buf);
  }

  /* Hack to prevent tcl from parsing the arguments to nst */
  nst_argv = (char **)malloc(sizeof(int) * (argc+3));

  /* if the user specified a geometry, snag it */
  geometry[0] = '\0';
  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i],"-geometry") == 0) {
      if (argv[i+1] != NULL) {
	strncpy(geometry,argv[i+1],29);
	geometry[29] = '\0';
      }
      break;
    }
  }

  nst_argv[0] = argv[0];
  if (argc > 1 && *(argv[1]) == '-') {
    /* works if first argument is a switch */
    Tk_Main(argc, argv, Tcl_AppInit);

  } else {
    /* make the first argument be a switch */
    nst_argv[1] = "-name";
    nst_argv[2] = "nst";
    for (i = 1; i < argc; i++) {
      nst_argv[i+2] = argv[i];
    }

    Tk_Main(argc+2, nst_argv, Tcl_AppInit);
  }

/*  Tk_Main(argc, argv, Tcl_AppInit); */
  return 0;			/* Needed only to prevent compiler warning. */
}


/* Find afile on the MMI search path.
 * If found, return the file location in pathfnd.
 * If not found, print a fatal error message and return FALSE.
 * (pat)
 */
static int FindOnMmiPath(char *pathfnd, char* afile)
{
    FILE *fp;
    char *home;

    if (home = getenv("HOME")) {
	sprintf(pathfnd,"%s/mmi_private/%s",home,afile);
	if (fp = fopen(pathfnd,"r")) {
	    fclose(fp);
	    return TRUE;
	}
    }

    sprintf(pathfnd,"%s/%s",MMI_LOCAL,afile);
    if (fp = fopen(pathfnd,"r")) {
	fclose(fp);
	return TRUE;
    }

    sprintf(pathfnd,"%s/%s",MMI_TOOLS,afile);
    if (fp = fopen(pathfnd,"r")) {
	fclose(fp);
	return TRUE;
    }
    fprintf(stderr,
	"%s: fatal: Could not open file: %s on the path: %s\n",
	afile,"$HOME/mmi_private:$MMI_LOCAL:$MMI_TOOLS");
    return FALSE;
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit --
 *
 *	This procedure performs application-specific initialization.
 *	Most applications, especially those that incorporate additional
 *	packages, will have their own version of this procedure.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error
 *	message in interp->result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_AppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{
  extern nst_read_tr0();
  extern nst_get_node();
  extern nst_free_struct();
  extern int Blt_Init _ANSI_ARGS_((Tcl_Interp *interp));

  char buf[1030];
  char tclname[100];
  FILE *fp;
  char *ptr;

  /* set tcl env variable to mmi library location */
  /* Pat changed: search in $MMI_LOCAL if $MMI_TOOLS/lib not found.
   */
  sprintf(tclname,"lib/tcl%s/init.tcl",TCL_VERSION);
  if (FindOnMmiPath(buf,tclname)) {
	/* TCL_LIBRARY needs to be the path without "/init.tcl" appended.
	 */
	buf[strlen(buf) - strlen("/init.tcl")] = 0;
	Tcl_SetVar2(interp, "env", "TCL_LIBRARY", buf, TCL_GLOBAL_ONLY);
  } else {
	exit(1);
  }

  sprintf(tclname,"lib/tk%s/tk.tcl",TK_VERSION);
  if (FindOnMmiPath(buf,tclname)) {
	/* TK_LIBRARY needs to be the path without "/tk.tcl" appended.
	 */
	buf[strlen(buf) - strlen("/tk.tcl")] = 0;
	Tcl_SetVar2(interp, "env", "TK_LIBRARY", buf, TCL_GLOBAL_ONLY);
  } else {
	exit(1);
  }


#if TCL_MAJOR_VERSION == 8
  {
    extern int MMITcl_InfoObjCmd();
    extern int MMITcl_RenameObjCmd();
    extern int MMITcl_ProcObjCmd();
    extern int MMITcl_WarpObjCmd();
    extern int Tcl_ProcObjCmd();

    Tcl_CreateObjCommand(interp, "info", 
		      MMITcl_InfoObjCmd, 
		      (ClientData) 0,   /* non 0 => dont disable "info body" */
		      NULL);
    Tcl_CreateObjCommand(interp, "rename", MMITcl_RenameObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "proc", MMITcl_ProcObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "warp_cursor", MMITcl_WarpObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "proc_unrestricted", Tcl_ProcObjCmd, NULL, NULL);
  }
#else

  /* remap info, rename and proc to MMI restricted versions (for security) */
  {
    extern int MMITcl_InfoCmd();
    extern int MMITcl_RenameCmd();
    extern int MMITcl_ProcCmd();

    Tcl_CreateCommand(interp, "info", 
		      MMITcl_InfoCmd, 
		      (ClientData) 1,   /* non null = don't disable "info body" */
		      NULL);
    Tcl_CreateCommand(interp, "rename", MMITcl_RenameCmd, NULL, NULL);
    Tcl_CreateCommand(interp, "proc", MMITcl_ProcCmd, NULL, NULL);
  }
#endif

  if (Tcl_Init(interp) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (Tk_Init(interp) == TCL_ERROR) {
    return TCL_ERROR;
  }
  Tcl_StaticPackage(interp, "Tk", Tk_Init, (Tcl_PackageInitProc *) NULL);
#ifdef TK_TEST
  if (Tktest_Init(interp) == TCL_ERROR) {
    return TCL_ERROR;
  }
  Tcl_StaticPackage(interp, "Tktest", Tktest_Init,
		    (Tcl_PackageInitProc *) NULL);
#endif /* TK_TEST */


  if (geometry[0] != '\0') {
    Tcl_VarEval(interp,"set GEOMETRY ", geometry, (char *) NULL);
  }

  Tcl_SetVar(interp, "COMPILE_TIME", __DATE__, TCL_GLOBAL_ONLY);
  Tcl_SetVar(interp, "NST_VERSION", NST_VERSION, TCL_GLOBAL_ONLY);


  /*
   * Call the init procedures for included packages.  Each call should
   * look like this:
   *
   * if (Mod_Init(interp) == TCL_ERROR) {
   *     return TCL_ERROR;
   * }
   *
   * where "Mod" is the name of the module.
   */

  if (Blt_Init(interp) != TCL_OK) {
    return TCL_ERROR;
  }


  /*
   * Call Tcl_CreateCommand for application-specific commands, if
   * they weren't already created by the init procedures called above.
   */

  Tcl_CreateCommand(interp, "nst_read_tr0", nst_read_tr0, (ClientData) NULL,
		    (Tcl_CmdDeleteProc *) NULL);
  
  Tcl_CreateCommand(interp, "nst_get_node", nst_get_node, (ClientData) NULL,
		    (Tcl_CmdDeleteProc *) NULL);

  Tcl_CreateCommand(interp, "nst_free_struct", nst_free_struct, 
		    (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

  /* set the nst directory in tcl */
  Tcl_VarEval(interp, "set NST_DIR ",MMI_TOOLS,"/nst", (char *) NULL);

  /* now source the tcl script that sets up and runs nst */

  {
    register Tcl_Obj *cmdPtr;

    /*
     * Initialize a Tcl object from the command string.
     */

    TclNewObj(cmdPtr);

    /*    TclInitStringRep(cmdPtr, nst_tcl, length); */

    cmdPtr->bytes = nst_tcl;
    /* since this should be strlen which doesn't include trailing null char */
    cmdPtr->length = sizeof(nst_tcl) - 2;

    Tcl_IncrRefCount(cmdPtr);

    /*
     * Compile and execute the bytecodes.
     */
    
    if (Tcl_EvalObj(interp, cmdPtr) == TCL_ERROR) {
      char *msg;
      Tcl_SetResult(interp,
		    TclGetStringFromObj(Tcl_GetObjResult(interp), (int *) NULL),
		    TCL_VOLATILE);

      msg = Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY);
      if (msg == NULL) msg = interp->result;
      fprintf(stderr,"ERROR, aborting NST.  %s\n",msg);
      exit(1);
    }

    /* Make sure noone else is referencing this */
    assert(cmdPtr->refCount == 1);

    /*
     * Discard the Tcl object created to hold the command and its code.
     */

    /* Don't want to free this now */
    /*    Tcl_DecrRefCount(cmdPtr);	*/

  }

  /* OLD WAY that left a pristine copy of all of the source code in the 
     executable image

  if (Tcl_Eval(interp, nst_tcl) == TCL_ERROR) {
    char *msg;
    msg = Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY);
    if (msg == NULL) msg = interp->result;
    fprintf(stderr,"ERROR, aborting NST.  %s\n",msg);
    exit(1);
  }
  */

  return TCL_OK;
}
