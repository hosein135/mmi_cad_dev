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


/* SUE C setup, including loading tcl */

/* gets nl's assert.h which doesn't declare this */
//#ifdef ASSERT
#define assert ASSERT
//#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 1
#endif


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
#include <assert.h>

#include "tk.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/*
 * The following variable is a special hack that is needed in order for
 * Sun shared libraries to be used for Tcl.
 */

extern int matherr();
int *tclDummyMathPtr = (int *) matherr;

/* demo_mode = 1 means in read only mode */
int demo_mode = 0;

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
char *MMI_TOOLS, *MMI_LOCAL, *MMI_DEMO;
char *progname = "";

char sue_tcl[] = 
#include "sueInit"
;

/* Copyright notice for the binary file. */
char *MainCopyright = "\n"\
"SUE IS IN THE PUBLIC DOMAIN.\n";

int
main(argc, argv)
    int argc;			/* Number of command-line arguments. */
    char **argv;		/* Values of command-line arguments. */
{

  char **sue_argv;
  int i;

  progname = argv[0];	/* For error messages */

  /* Versions are of the form MMI_SUE<major>.<minor>.<inc> */
  printf ("Micro Magic SUE, Version MMI_SUE%s Compiled %s\n", SUE_VERSION, __DATE__);

  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i],"-v") == 0 || strcmp(argv[i],"-version") == 0) {
      /* user just wanted header, so exit */
      exit(0);      
    }
  }

  MMI_TOOLS = getenv("MMI_TOOLS");
  if(!MMI_TOOLS) {
    fprintf(stderr,"ERROR, aborting SUE.  Can't find environment variable MMI_TOOLS.\n");
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

  MMI_DEMO = getenv("MMI_DEMO");
  if(MMI_DEMO) {
    /* user specified demo mode.  Make everything read only and run */
    demo_mode = 1;
    fprintf (stderr, "\n *** DEMO Mode.  No modifications allowed. ***\n\n");
  }

  /* Hack to prevent tcl from parsing the arguments to sue */
  sue_argv = (char **)malloc(sizeof(char*) * (argc+3));

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

  sue_argv[0] = argv[0];
  if (argc > 1 && *(argv[1]) == '-') {
    /* works if first argument is a switch */
    Tk_Main(argc, argv, Tcl_AppInit);

  } else {
    /* make the first argument be a switch */
    sue_argv[1] = "-name";
    sue_argv[2] = "sue";
    for (i = 1; i < argc; i++) {
      sue_argv[i+2] = argv[i];
    }

    Tk_Main(argc+2, sue_argv, Tcl_AppInit);
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

  char buf[1030];
  char tclname[100];
  static int nlsh_app_init ();

  /* set tcl env variable to mmi library location */
  /* Pat changed: search in $MMI_LOCAL/lib if $MMI_TOOLS/lib not found.
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
    extern int MMI_check_netlist_license();
    extern int MMI_check_edif_license();
    extern int MMI_check_read_only();
    extern int Tcl_ProcObjCmd();
    extern int MMITcl_Lsearch2ObjCmd();

    Tcl_CreateObjCommand(interp, "lsearch2", MMITcl_Lsearch2ObjCmd, NULL, NULL);


#if 0
    Tcl_CreateObjCommand(interp, "info", 
		      MMITcl_InfoObjCmd, 
		      (ClientData) 1,   /* non 0 => dont disable "info body" */
		      NULL);
#endif
    Tcl_CreateObjCommand(interp, "rename", MMITcl_RenameObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "proc", MMITcl_ProcObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "warp_cursor", MMITcl_WarpObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, "proc_unrestricted", Tcl_ProcObjCmd, NULL, NULL);
    Tcl_CreateCommand(interp, "netlist_setup", MMI_check_netlist_license, NULL, NULL);
    Tcl_CreateCommand(interp, "edif_setup", MMI_check_edif_license, NULL, NULL);
    Tcl_CreateCommand(interp, "modify_setup", MMI_check_read_only, NULL, NULL);
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

  /* register mmi interrupt command */
  mmiInterruptInit(interp);

  steiner_init(interp);

#ifndef SHARED_OBJECT
  /* except when a shared object

  /* initialize nl */
  nlsh_app_init(interp);

  /* initialize speedy */
  //  Speedy_package_Init(interp);

  // initialize gr
  groute_init(interp);
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

  /* setup tcl global variable for read only */
  if (demo_mode) {
    Tcl_VarEval(interp,"set READ_ONLY_MODE 1", (char *) NULL);
  } else {
    Tcl_VarEval(interp,"set READ_ONLY_MODE 0", (char *) NULL);
  }

  if (geometry[0] != '\0') {
    Tcl_VarEval(interp,"set GEOMETRY(cmd) ", geometry, (char *) NULL);
  }

  Tcl_SetVar(interp, "COMPILE_TIME", __DATE__, TCL_GLOBAL_ONLY);
  Tcl_SetVar(interp, "SUE_VERSION", SUE_VERSION, TCL_GLOBAL_ONLY);
  Tcl_SetVar(interp, "SUE2EDIF_VERSION", SUE2EDIF_VERSION, TCL_GLOBAL_ONLY);

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

  /*
   * Call Tcl_CreateCommand for application-specific commands, if
   * they weren't already created by the init procedures called above.
   */

  /* now source the tcl script that sets up and runs SUE */

  {
    register Tcl_Obj *cmdPtr;

    /*
     * Initialize a Tcl object from the command string.
     */

    TclNewObj(cmdPtr);

    /*    TclInitStringRep(cmdPtr, sue_tcl, length); */

    cmdPtr->bytes = sue_tcl;
    /* since this should be strlen which doesn't include trailing null char */
    cmdPtr->length = sizeof(sue_tcl) - 2;

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
      fprintf(stderr,"ERROR, aborting SUE.  %s\n",msg);
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

  if (Tcl_Eval(interp, sue_tcl) == TCL_ERROR) {
    char *msg;
    msg = Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY);
    if (msg == NULL) msg = interp->result;
    fprintf(stderr,"ERROR, aborting SUE.  %s\n",msg);
    exit(1);
  }
  */

  return TCL_OK;
}


/* Called on every netlist operation.  First argument is the netlist type.
*/

int dpc_license = 0;
int spice_license = 0;
int verilog_license = 0;
int vhdl_license = 0;

int
MMI_check_netlist_license(cdata, interp, argc, argv)
    ClientData cdata;			
    Tcl_Interp *interp;			/* Current interpreter. */
    int argc;                   /* Number of arguments. */
    char *argv[];               /* Argument strings. */
{

  return TCL_OK;
}


int
MMI_check_edif_license(cdata, interp, argc, argv)
    ClientData cdata;			
    Tcl_Interp *interp;			/* Current interpreter. */
    int argc;                   /* Number of arguments. */
    char *argv[];               /* Argument strings. */
{

  return TCL_OK;
}


int
MMI_check_read_only(cdata, interp, argc, argv)
    ClientData cdata;			
    Tcl_Interp *interp;			/* Current interpreter. */
    int argc;                   /* Number of arguments. */
    char *argv[];               /* Argument string. */
{

  int result;
  /*  char return_cmd[] = "return -code return"; */
  char cmd[] = "is_read_only";

  /* special case if argument passed */
  if (argc > 1) {
    if (demo_mode) {
      /* abort this command */
      return TCL_RETURN;
    } else {
      /* allow this command */
      return TCL_OK;
    }
  }

  /* call tcl command to see if user wants this to be read only */
  Tcl_Eval(interp, cmd);

  /* check if user has a full SUE license */
  if (demo_mode || strcmp(interp->result,"0")) {
    /* abort this command */
    Tcl_Eval(interp, "msg_window \"COMMAND IGNORED -- READ ONLY BUFFER\"");
    return TCL_RETURN;
  } 

  return TCL_OK;
}


/* initializes C routines for tcl for steiner routing */

int steiner_init(interp)
    Tcl_Interp *interp;			/* Current interpreter. */
{
#if 1
  extern int Tcl_steiner_output_file();
  extern int Tcl_steiner_begin_net();
  extern int Tcl_steiner_add_point();
  extern int Tcl_steiner_end_net();

  Tcl_CreateObjCommand(interp, "steiner_output_file", Tcl_steiner_output_file, NULL, NULL);
  Tcl_CreateObjCommand(interp, "steiner_begin_net", Tcl_steiner_begin_net, NULL, NULL);
  Tcl_CreateObjCommand(interp, "steiner_add_point", Tcl_steiner_add_point, NULL, NULL);
  Tcl_CreateObjCommand(interp, "steiner_end_net", Tcl_steiner_end_net, NULL, NULL);

#else
  extern int output_file();
  extern int begin_net();
  extern int add_point();
  extern int end_net();

  Tcl_CreateObjCommand(interp, "steiner_output_file", output_file, NULL, NULL);
  Tcl_CreateObjCommand(interp, "steiner_begin_net", begin_net, NULL, NULL);
  Tcl_CreateObjCommand(interp, "steiner_add_point", add_point, NULL, NULL);
  Tcl_CreateObjCommand(interp, "steiner_end_net", end_net, NULL, NULL);
#endif

}

#ifndef SHARED_OBJECT

extern int tcl_gr();
extern int tcl_gr_grid();
extern int tcl_gr_grid_iter();

int groute_init(Tcl_Interp *interp) {

  Tcl_CreateObjCommand(interp, "gr_command", tcl_gr, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_grid", tcl_gr_grid, NULL, NULL);
  Tcl_CreateObjCommand(interp, "gr_grid_iter", tcl_gr_grid_iter, NULL, NULL);

  return TCL_OK;
}

#endif

#ifndef SHARED_OBJECT

#include "mem.h"
#include "ar.h"
typedef void* nl_object;
typedef int nl_kind;
// #include "ui.h"

static
int
nlsh_app_init (Tcl_Interp *interp)
{
  extern int Nl_shell_Init (Tcl_Interp *interp);
  int status = Nl_shell_Init (interp);
#if 0
  void *context;
  int status = ui_app_init (interp, "nl_", &context);

  if ( status != TCL_OK )
    return status;

  status = ui_alias_init (interp, "nl_", context);
#endif

  return status;
}


#endif
