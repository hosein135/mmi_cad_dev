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
 * mnMain.c --
 *
 * The topmost module of Max.  This module
 * initializes the other modules and then starts the main
 * event loop to execute commands.
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
static char rcsid[]="$Header$";
#endif  not lint

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/times.h>
#include <sys/stat.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>
#include "magic.h"
#include "hash.h"
#include "message.h"
#include "geometry.h"
#include "tile.h"
#include "main.h"
#include "database.h"
#include "drc.h"
#include "layout.h"
#include "commands.h"
#include "signals.h"
#include "utils.h"
#include "cif.h"
#include "extract.h"
#include "undo.h"
#include "malloc.h"
#include "bplane.h"
#include "netlist.h"
/* #include "talloc.h" */
#include "main.h"
#include "mainInt.h"
#include "Mgc.h"
#include "layout.h"

/* Copyright notice for the binary file. */
global char *MainCopyright = "\n"\
"MAX: Copyright (C) 1996 - 2002 Juniper Networks, Inc.\n"\
"MAGIC: Copyright (C) 1985, 1990 Regents of the University of California.\n";

/* Legal notice */
global char *MaxLegalNotice =
"Copyright (C) 1996 - 2002 Juniper Networks, Inc.";

/* run time libraries */
#define MMI_TOOLS_DEFAULT "/usr/local/mmi"
char *MnMMITools = NULL;
char *MnMMIToolsMax = NULL;
char *MnMMILocal = NULL;
char *MnMMILocalMax = NULL;
char *MnMMIPrivate = NULL;
char *MnMMIPrivateMax = NULL;

/* search paths */
char	*MnPathSysLib = NULL;	/* Used to find runtime files, such
				  as color maps, styles, technology files ... */
char    *MnPathCell = NULL;     /* Cell path (design data) */

/* technology */
char *MnTech = NULL;
char *MnTechVar = NULL;

/* edit cell */
CellUse	*EditCellUse = NULL;
CellDef	*EditRootDef = NULL;
Transform EditToRootTransform;
Transform RootToEditTransform;

Tcl_Interp *MnInterp;	/* Tcl interpreter for max */
Tk_Window MainTkWin;	/* Token for the main Tk window */

bool MnDeveloper;       /* set for developer mode */

bool MnCmdNesting = 0;  /* commands in progress */

/***** DATA STRUCTURES LOCAL TO THIS MODULE *****/

/* Interactive? */
int mainInteractive;		/* set if stdin is a terminal */

bool mnBackupOnExit = TRUE;     /* if set, all modified cells backed up on exit */

/***** DATA STRUCTURES LOCAL TO THIS FILE *****/

/*** command line options ***/
static char * mnCmdLineDeveloper = NULL;
static bool mnCmdLineHelp = FALSE;
static bool mnCmdLineProfile = FALSE;
static bool mnCmdLineVersion = FALSE;
char *mnMaxTcl = NULL;

static Tk_ArgvInfo mnArgTable[] = {
    {"-developer", TK_ARGV_STRING, (char *) NULL, (char *) &mnCmdLineDeveloper,
	"DEVELOPER, non-zero value, for developer mode"},
    {"-maxtcl <dir>", TK_ARGV_STRING, (char *) NULL, (char *) &mnMaxTcl,
	"DEVELOPER, directory to source maxtcl code from"},
    {"-mm", TK_ARGV_CONSTANT, (char *) 1, (char *) &MemMM,
	"DEVELOPER, enable memory monitoring"},
    {"-profile", TK_ARGV_CONSTANT, (char *) 1, (char *) &mnCmdLineProfile,
	"DEVELOPER, Begin profiling at startup"},
    {"-version", TK_ARGV_CONSTANT, (char *) 1, (char *) &mnCmdLineVersion,
	"just print Max version and exit"},
    {(char *) NULL, TK_ARGV_END, (char *) NULL, (char *) NULL,
	(char *) NULL}
};


/*
 * ----------------------------------------------------------------------------
 *
 * moncontrol --
 *
 * moncontrol() is a library funciton used to turn monitoring off/on when
 * generating gmon.out for performance profiling with gprof.
 *
 * to generate gmon.out max must be compiled with "-pg" option,
 * and linked with a library containing moncontrol() (-lgmon on my
 * linux system).  In addition -DGMON must be set to keep the
 * dummy moncontrol() below from being included.
 * 
 * moncontrol() does not appear to be part of the POSIX standard!
 * When gprof is not in use, the dummy moncontrol() avoids porting
 * problems due to moncontrol() not existing, or being in a different
 * library.
 *
 * ----------------------------------------------------------------------------
 */
#ifndef GMON
void moncontrol(int mode) {}
#endif GMON

/*
 * ----------------------------------------------------------------------------
 *
 * mnParseVersion --
 *
 * extract major,minor and patch numbers from version string.
 *
 * Returns:
 *     TRUE on valid version, FALSE on invalid version;
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
static bool
mnParseVersion(char *version, int *majorp, int *minorp, int *patchp, int *internalp)
{
  /* init */
  *majorp = 0;
  *minorp = 0;
  *patchp = 0;
  *internalp = 0;

  /* major */
  if(*version == '\0') return TRUE;
  if(!isdigit(*version)) goto bad;
  *majorp = strtol(version, &version, 10);

  /* '.' */
  if(*version == '\0') return TRUE;
  if(*version != '.') goto bad;
  version++;

  /* minor */
  if(*version == '\0') return TRUE;
  if(!isdigit(*version)) goto bad;
  *minorp = strtol(version, &version, 10);

  /* '.' */
  if(*version == '\0') return TRUE;
  if(*version != '.') goto bad;
  version++;

  /* patch */
  if(*version == '\0') return TRUE;
  if(!isdigit(*version)) goto bad;
  *patchp = strtol(version, &version, 10);

  /* '.' */
  if(*version == '\0') return TRUE;
  if(*version != '.') goto bad;
  version++;

  /* internal */
  if(*version == '\0') return TRUE;
  if(!isdigit(*version)) goto bad;
  *internalp = strtol(version, &version, 10);

  /* done */
  if(*version == '\0') return TRUE;

bad:
  *majorp = -1;
  *minorp = -1;
  *patchp = -1;
  *internalp = -1;

  return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * mnGetLib --
 *
 * Get name of max lib in given directory
 * (finds max lib with greatest version tag <= version of max executable.)
 *
 * Returns:
 *     pointer to freshly malloced full pathname, or empty string on failure.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
char *
mnGetLib(char *dirName)
{
  DIR *dir;
  struct dirent *entry;
  int maxMajor, maxMinor, maxPatch, maxInternal; 
  char best[BUFSIZ];
  int bestMajor = -1;
  int bestMinor = -1; 
  int bestPatch = -1;
  int bestInternal = -1;

  /* parse executable version */ 
  ASSERT(mnParseVersion(MaxVersion, 
			&maxMajor, &maxMinor, &maxPatch, &maxInternal),
	 "mnGetLib");

  dir = opendir(dirName);
  if(!dir) return "";

  while(entry = readdir(dir))
  {
    int major, minor, patch, internal;
    char *s = entry->d_name;

    if(*s++ != 'm') continue;
    if(*s++ != 'a') continue;
    if(*s++ != 'x') continue;

    if(!mnParseVersion(s, &major, &minor, &patch, &internal)) continue;

    /* compatible with executable? */
    if(major>maxMajor) continue;
    if(major<maxMajor) goto compatible;
    if(minor>maxMinor) continue;
    if(minor<maxMinor) goto compatible;
    if(patch>maxPatch) continue;
    if(patch<maxPatch) goto compatible;
    if(internal>maxInternal) continue;
  compatible:

    /* better? */ 
    if(major<bestMajor) continue;
    if(major>bestMajor) goto better;
    if(minor<bestMinor) continue;
    if(minor>bestMinor) goto better;
    if(patch<bestPatch) continue;
    if(patch>bestPatch) goto better;
    if(internal<bestInternal) continue;
  better:

    strcpy(best,entry->d_name);
    bestMajor = major;
    bestMinor = minor;
    bestPatch = patch;
    bestInternal = internal;
  }

  closedir(dir);

  if(bestMajor < 0) return "";

  {
    char buf[BUFSIZ];

    sprintf(buf,"%s/%s", dirName, best);
    return StrDup(NULL,buf);
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnGetEnvPath --
 *
 * get environment variable, and tilde expand it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnGetEnvPath(char *name, char **resultp)
{
  char *expanded;

  /* environment variable */
  *resultp = getenv(name);
    
  if(!*resultp) 
  {
    fprintf(stderr,"Max: Fatal Error, %s environment variable not set!\n",
	    name);
    exit(1);
  }

  /* tilde expand */
  {    
    char *expanded = PaTildeExpandName(*resultp);
    if(!expanded) 
    {
      fprintf(stderr,
	      "Max: Fatal Error, "
	      "Could not tilde expand environment variable %s: '%s'\n", 
	      name, *resultp);
      exit(1);
    }
    *resultp = expanded;
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnInitLibPaths --
 *
 * Set the following global variables:
 *      MnMMITools, MnMMIToolsMax,
 *      MnMMILocal, MnMMILocalMax,
 *      MnMMIPrivate, MnMMIPrivateMax, 
 *      MnPathSysLib
 * 
 * (all linked to tcl variables)
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnInitLibPaths()
{
  char *homeDir;
    
  /* HOME */
  mnGetEnvPath("HOME", &homeDir);

  /* MMI_TOOLS */
  mnGetEnvPath("MMI_TOOLS", &MnMMITools);
  MnMMIToolsMax = mnGetLib(MnMMITools);

  /* MMI_LOCAL */
  if(getenv("MMI_LOCAL"))
  {
    mnGetEnvPath("MMI_LOCAL", &MnMMILocal);
  }
  else
  {
    char buf[BUFSIZ];
    sprintf(buf, "%s/../mmi_local", MnMMITools);

    MnMMILocal = PaTildeExpandName(buf);
    if(!MnMMILocal) 
    {
      fprintf(stderr,
	      "Max: Fatal Error, Could not tilde expand MMI local dir: '%s'\n", 
	      MnMMILocal);
      exit(1);
    }    
  }
  MnMMILocalMax = mnGetLib(MnMMILocal);

  /* MMI_PRIVATE */
  {
    char buf[BUFSIZ];
    sprintf(buf, "%s/mmi_private", homeDir);
    MnMMIPrivate = StrDup(NULL, buf);
  }
  MnMMIPrivateMax = mnGetLib(MnMMIPrivate);

  /* MN_PATH_SYS_LIB */
  {
    char buf[BUFSIZ];

    sprintf(buf, "%s %s %s",
	    MnMMIPrivateMax, 
	    MnMMILocalMax, 
	    MnMMIToolsMax); 

    MnTclSetLinkedString(&MnPathSysLib, buf);
  }

}

/*
 * ----------------------------------------------------------------------------
 *
 * mnInitTcl --
 *
 * Set tcl lib to mmi version, and do Tcl_Init()
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnInitTcl(Tcl_Interp *interp)
{
  char buf[1000];
  FILE *fp;

  /* set tcl env variable to mmi library location */
  sprintf(buf, "%s/lib/tcl%s", MnMMITools, TCL_VERSION);
  Tcl_SetVar2(interp, "env", "TCL_LIBRARY", buf, TCL_GLOBAL_ONLY);


  /* make sure mmi library location is viable */
  fp = fopen(strcat(buf,"/init.tcl"),"r");
  if(!fp)
  {
    fprintf(stderr,
	    "Max: Fatal Error, Could not open tcl initialization file: %s'\n", 
	    buf);
    exit(1);
  }
  fclose(fp);

  /* remap info to MMI restricted version (unless in developer mode) */
  if(!MnDeveloper)  
  {
    extern int MMITcl_InfoObjCmd();
    Tcl_CreateObjCommand(MnInterp, 
			 "info",
			 MMITcl_InfoObjCmd,
			 (ClientData) 0,   /* non 0 => dont disable "info body" */
			 NULL);
  }

  /* remap "rename" and "proc" to MMI restricted versions that do not
   * allow "proc" or "rename" to be redefined.
   */
  {
    extern int MMITcl_RenameObjCmd();
    extern int MMITcl_ProcObjCmd();
    Tcl_CreateObjCommand(MnInterp, "rename", MMITcl_RenameObjCmd, NULL, NULL);
    Tcl_CreateObjCommand(MnInterp, "proc", MMITcl_ProcObjCmd, NULL, NULL);
  }

  /* add warp_cursor (used by prop_menu) */
  {
    extern int MMITcl_WarpObjCmd();
    Tcl_CreateObjCommand(interp, "warp_cursor", MMITcl_WarpObjCmd, NULL, NULL);
  }

  /* add lsearch2 (for efficient list lookups) */
  {
    extern int MMITcl_Lsearch2ObjCmd();
    Tcl_CreateObjCommand(interp, "lsearch2", MMITcl_Lsearch2ObjCmd, NULL, NULL);
  }

  /* TODO, remove when mha's home system is in sync! */ 
#ifndef NO_LUCK
  /*
    This will be used when max/sue opens a file to print a warning
    if another max/sue session already has the file open.
    Might print the warning when user goes to save the file, too.
  */
  {
    extern int MMITcl_SemaFileObjCmd();
    Tcl_CreateObjCommand(interp, "sema_file", MMITcl_SemaFileObjCmd, NULL, NULL);
  }
#endif

  /* do the initialization (reads init.tcl in tcl library) */
  if (Tcl_Init(interp) == TCL_ERROR) 
  {
    if(interp->result) fprintf(stderr,"%s\n",interp->result);
    fprintf(stderr, "Max: Fatal Error, Tcl initialization failed.\n");
    exit(1);
  }
    
  /* Set global Tcl vars */
  MnDocLinkVar(interp, "MN_TECH", (char *) &MnTech, 
	       TCL_LINK_STRING,
	       "Technology name (without variation part)",
	       "
This variable gets set in max0.tcl, to control which
technology gets loaded.");

  MnDocLinkVar(interp, "MN_TECH_VAR", (char *) &MnTechVar, 
	       TCL_LINK_STRING,
	       "Technology variation (if any)",
	       "
This variable gets set in max0.tcl, to control which
technology gets loaded.  If no variation, it should
be set to the null string");

  MnDocLinkVar(interp, "MMI_TOOLS", (char *) &MnMMITools, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "top level directory of MMI tools",
	       NULL);
  MnDocLinkVar(interp, "MMI_TOOLS_MAX", (char *) &MnMMIToolsMax, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "max library directory of MMI tools",
	       "latest version max library that does not exceed executable version");
  MnDocLinkVar(interp, "MMI_LOCAL", (char *) &MnMMILocal, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "top level directory for site specific files",
	       NULL);
  MnDocLinkVar(interp, "MMI_LOCAL_MAX", (char *) &MnMMILocalMax, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "site specific max library",
	       "latest version max library that does not exceed executable version");
  MnDocLinkVar(interp, "MMI_PRIVATE", (char *) &MnMMIPrivate, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "top level directory for user specific files",
	       NULL);
  MnDocLinkVar(interp, "MMI_PRIVATE_MAX", (char *) &MnMMIPrivateMax, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "user specific max library",
	       "latest version max library that does not exceed executable version");

  MnDocLinkVar(interp, "MAX_VERSION", (char *) &MaxVersion,
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       NULL,
	       NULL);
  MnDocLinkVar(interp, "MAX_VERSION_TAG", (char *) &MaxVersionTag,
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       NULL,
	       NULL);
  MnDocLinkVar(interp, "MC_VERSION", (char *) &MCVersion, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       "Mega Cell Compiler Version",
	       NULL);

  MnDocLinkVar(interp, "MAX_COMPILE_TIME", (char *) &MaxCompileTime, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       NULL,
	       NULL);

  MnDocLinkVar(interp, "MAX_LEGAL_NOTICE", (char *) &MaxLegalNotice, 
	       TCL_LINK_STRING|TCL_LINK_READ_ONLY,
	       NULL,
	       NULL);

  MnDocLinkVar(interp, "MAX_DEVELOPER", (char *) &MnDeveloper, 
	       TCL_LINK_BOOLEAN|TCL_LINK_READ_ONLY,
	       "set if Max is in developer mode",
	       "
Max developer mode can only be entered at startup.
To startup Max in developer mode, use `-developer 1' option on command-line,
or set MAX_DEVELOPER environment variable to 1.
");

  /* Interactive? */
  /* For now, under Windows, we assume we are not running as a console mode
   * app, so we need to use the GUI console.  In order to enable this, we
   * always claim to be running on a tty.  This probably isn't the right
   * way to do it.
   */
#ifdef __WIN32__
  mainInteractive = 1;
#else
  mainInteractive = isatty(0);
#endif
  MnDocLinkVar(interp, "tcl_interactive", (char *) &mainInteractive, 
	       TCL_LINK_BOOLEAN,
	       "set if input appears to be from a person rather than a file",
	       "can be set 'manually' to force prompts etc.");
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnTclInitModules --
 *
 * Register tcl commands for Max modules (and link some C and Tcl variables)
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnTclInitModules(Tcl_Interp *interp)
{
  BPTclInit(interp); 
  CifTclInit(interp);
  DBTclInit(interp);
  DRCTclInit(interp);
  ExtTclInit(interp); 
  GDSTclInit(interp);
  GrTclInit(interp);
  LayoutTclInit(interp);
  MgcTclInit(interp);
  mnTclInit(interp);
  NtlTclInit(interp);
  SelTclInit(interp);
  UndoTclInit(interp);
  UtlsTclInit(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnInitTk --
 *
 * Set tk lib to mmi version, and do Tk_Init()
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnInitTk(Tcl_Interp *interp)
{
  char buf[1000];
  FILE *fp;

  /* set tk env variable to mmi library location */
  sprintf(buf, "%s/lib/tk%s", MnMMITools, TK_VERSION);
  Tcl_SetVar2(interp, "env", "TK_LIBRARY", buf, TCL_GLOBAL_ONLY);

  /* make sure mmi library location is viable */
  fp = fopen(strcat(buf,"/tk.tcl"),"r");
  if(!fp)
  {
    fprintf(stderr,
	    "Max: Fatal Error, Could not open tk initialization file: %s'\n", 
	    buf);
    exit(1);
  }
  fclose(fp);

  if (Tk_Init(interp) == TCL_ERROR) 
  {
    if(interp->result) fprintf(stderr,"%s\n",interp->result);
    fprintf(stderr, "Max: Fatal Error, Tk initialization failed.\n");
    exit(1);
  }

  Tcl_StaticPackage(interp, "Tk", Tk_Init, (Tcl_PackageInitProc *) NULL);
  MainTkWin = Tk_MainWindow(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * mnInitGraphics --
 *
 * Initialize graphics module.
 * (graphics extensions used for layout widgets)
 *
 * NOTE:  If insufficient colormap resources are available, restarts Max
 *        with "-colormap new"
 *
 * ----------------------------------------------------------------------------
 */
static void
mnInitGraphics(Tcl_Interp *interp, int argc, char **argv)
{
  int i;
  char **newArgv;

  if(GrInit(interp)) return;

  fprintf(stderr, "Unable to allocate enough colormap planes.\n");

  /* avoid loop, by not restarting if "-colormap new" option already present */
  for(i=1;i<argc-1;i++)
  {
    if(strcmp("-colormap",argv[i]) == 0 && strcmp("new",argv[i+1]) == 0)
    {
	fprintf(stderr, "
Already using new colormap, giving up!

Max requires colormapped graphics.  Your XServer is probably setup
for true color (e.g. 16-bit or 24-bit mode).  To run Max, reconfigure    
your X server for 8 bit colormapped graphics.  

If you are running XFree86 edit XF86Config 
(probably /usr/X11R6/lib/X11/XF86Config) and set `Depth 8' in
the `Display' subsection of the appropriate `Screen' section.
See the XF86Config man page for details.

");
	exit(1);
    }
  }
    
  fprintf(stderr,"Restarting with \"-colormap new\" ...\n\n");
    
  /* setup argv */
  MALLOC(char **, newArgv, sizeof(char *)*(argc+3));
  newArgv[0] = StrDup(NULL,argv[0]);    
  newArgv[1] = "-colormap";
  newArgv[2] = "new";
  for(i=1; i<argc; i++) newArgv[i+2] = argv[i];  
  newArgv[argc+2] = NULL;

  /* exec it */
  {
    char *fileName = StrDup(NULL,newArgv[0]);

    execvp(fileName,newArgv); 

    /* if we got here, exec didn't work */
    perror("max restart");
    fprintf(stderr,"file = %s\n", fileName);
    fprintf(stderr,"PATH = %s\n", 
	    getenv("PATH") ? getenv("PATH") : "NULL");
    exit(1);
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnInitModules --
 *
 * Initialize Max modules.
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnInitModules(Tcl_Interp *interp)
{
      DBInit();
      DRCInit();
      ExtInit(); 
      LayoutInit();
      SelectInit();
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnDoOnExit --
 *
 * This function is registered by atexit() so it will be
 * called by exit() prior to exiting!
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If MnBackupOnExit is set, backs up all modified cells.
 *
 * ----------------------------------------------------------------------------
 */


static void
mnDoOnExit(void)
{
    if (mnBackupOnExit) DBPanicSave();
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnEventLoop --
 *
 * MAX EVENT LOOP
 *
 * NOTE:  NEVER RETURNS, loops until all windows closed then exits.
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnEventLoop(Tcl_Interp *interp)
{

  while (Tk_GetNumMainWindows() > 0)
  {
    int eventsDone;
    bool eventFound;

    /* process at least one and up to n=DRCPriority events in queue before 
     * giving background DRC a shot 
     */
    eventsDone=0;
    do  
    {
      /* Clear Interrupt flag.
       * This flag gets set on Interrupt (^C).
       *
       * Potentially long event responses should periodically check for this 
       * flag, and "abort" if it becomes true.
       */
      SigInterruptPending = FALSE;


      eventFound = Tcl_DoOneEvent(0);
      if(eventFound) eventsDone++;
    }
    while(eventFound && eventsDone<DRCPriority);

    /* Give background drc a chance, it will return if disabled,
     * no more work to be done, interrupt detected, or after it has   
     * done its check quota (determined by DRCPriority) and user
     * events are pending.
     */
    if(DRCContinuous(TRUE) == 0)
    {
      /* drc caught up or off, so block until next event */
      SigInterruptPending = FALSE;
      Tcl_DoOneEvent(0);
    }
  }

  /*
   * "They" closed all our windows - so we really don't have much
   * choice but to exit!
   */
  fprintf(stderr,
	  "max:  No windows left!  Backing up modified cells and exiting.\n");
  exit(1);
}

/*---------------------------------------------------------------------------
 * main:
 *
 *	Top-level procedure for Max.  
 *
 * Results:	
 *	None.
 *
 * Side Effects:
 *	Lots.
 *
 *----------------------------------------------------------------------------
 */
int main(int argc, char **argv)
{
    char **saveArgV;
    int saveArgC;

    /* note current time, for elapsed time computations */
    UtlsStatInit();
    
    /* stash away some memory to allow graceful processing
     * of out of memory condition.
     */
    mallocReserve(100000);

    /* turn off profiling initially 
     * (only significant when compiled with -pg, for use with gprof) 
     */
    moncontrol(0);

    /* stash away original args 
     * (used to restart with "-colormap new", if necessary)
     */
    {
      int i;

      /* don't use MALLOC here because we havn't processed
       * -mm command line option yet.
       */
      saveArgV = (char **) malloc(sizeof(char *)*(argc+1));
      saveArgC = argc;
      for(i=0; i<argc; i++) saveArgV[i] = StrDup(NULL,argv[i]);
      saveArgV[saveArgC] = NULL;
    }

    /* Create our Tcl interpreter */
    MnInterp = Tcl_CreateInterp();
#ifdef TCL_MEM_DEBUG
    Tcl_InitMemory(MnInterp);
#endif

    /* Parse command line args */
    if (Tk_ParseArgv(MnInterp, (Tk_Window) NULL, &argc, argv, mnArgTable, 0)
	    != TCL_OK)
    {
      /* just print help message and return */
      mnCmdLineHelp = TRUE;
    }

    /* Initialize cell paths  (used by DBGetTech() below) */
    MnTclSetLinkedString(&MnPathCell, ".");

    /* get technology of last file arg (if any) 
     * used in max0.tcl to choose technology to load.
     */
    {
      char *tech = NULL;

      if(argc-1>0) tech = DBGetTech(argv[argc-1]);
      if(!tech) tech ="";

      Tcl_SetVar(MnInterp, 
		 "MN_FILE_TECH", 
		 tech, 
		 TCL_GLOBAL_ONLY);
    }

    /* Make (remaining) command line args available in 
     * Tcl variables "argc" and "argv".
     */
    {
        char *args;
        char buf[20];

        args = Tcl_Merge(argc-1, argv+1);
        Tcl_SetVar(MnInterp, "argv", args, TCL_GLOBAL_ONLY);
        sprintf(buf, "%d", argc-1);
        Tcl_SetVar(MnInterp, "argc", buf, TCL_GLOBAL_ONLY);
        Tcl_SetVar(MnInterp, "argv0", argv[0], TCL_GLOBAL_ONLY);

    }

    /* if -profile arg given, begin performance profiling immediately.
     * (can also be turned on later with ":*profile on")
     */
    if(mnCmdLineProfile) moncontrol(1);

    /* identify version */
    MsgInfoF("\nMicro Magic MAX%s %s - compiled %s.\n", 
	     MaxVersion, 
	     MaxVersionTag, 
	     MaxCompileTime);

    /* Give legal notice first thing  */
    MsgInfoF("%s\n",MaxLegalNotice);

    /* if -version flag, exit now! */
    if(mnCmdLineVersion) exit(0);

    /* Setup developer mode flag */
    { 
      char *developer = mnCmdLineDeveloper;

      /* if no cmd line switch, try environment variable */
      if(!developer) developer = getenv("MAX_DEVELOPER");

      /* If still no developer specified, default to off */
      if (!developer) developer = "0";

      /* set global C variable */
      if(strcmp(developer,"0")==0)
      {
	MnDeveloper = FALSE;
      }
      else
      {
	MnDeveloper = TRUE;
      }
    }

    /* make args supported in C code (above) and their descriptions available 
     * in tcl var MN_SWITCHES. 
     *
     * (combined with tcl processed args to generate usage message)
     *
     * Note does not include tcl options (like -geometry)
     *
     */
    {
      Tk_ArgvInfo *arg;
      Tcl_DString ds;
      
      Tcl_DStringInit(&ds);
      for(arg=mnArgTable; arg->key; arg++)
      {
	if(!MnDeveloper && strncmp(arg->help,"DEVELOPER",9)==0) continue;
	Tcl_DStringAppendElement(&ds, arg->key);
	Tcl_DStringAppendElement(&ds, arg->help);
	Tcl_DStringAppend(&ds,"\n",1);
      }

      Tcl_SetVar(MnInterp, 
		 "MN_SWITCHES", 
		 Tcl_DStringValue(&ds),
		 TCL_GLOBAL_ONLY);

      Tcl_DStringFree(&ds);
    }

    /* Determine MMI tools dir, local dir, and system path */ 
    mnInitLibPaths();

    /* Do Tcl Initializaton
     * includes setting of some global tcl vars,
     * and remapping to MMI restricted "info" if not in developer mode
     * 
     */
    mnInitTcl(MnInterp);

    /* restore original "proc" and "rename",
     * prior to max0 script, so user can't redefine proc (in tcl init script)
     * to steal code in our scripts below.
     *
     * max0 script redefines "rename" and "proc" for integral documentation,
     * new rename does not permit subsequent rename of "proc" or "rename"
     */

    /* source max0 tcl script
     *  - initializes integral documentation, 
     *    redefines "proc" and "rename")
     *
     *    normally this script is part of executable, 
     *    but if MnDeveloper, or mnMaxTcl we try to source from a maxtcl/ 
     *    directory instead.
     */
    {
      /* Create unrestricted version of "proc" for use in redefining
       * "proc" and "rename" in max0.tcl (for integral documentation)
       * max0.tcl deletes unrestricted version when done with it.
       */
#if TCL_MAJOR_VERSION == 8
      extern int Tcl_ProcObjCmd();
      Tcl_CreateObjCommand(MnInterp, "proc_unrestricted",
	    Tcl_ProcObjCmd, NULL, NULL);
#else
      extern int Tcl_ProcCmd();
      Tcl_CreateCommand(MnInterp, "proc_unrestricted", 
			Tcl_ProcCmd, NULL, NULL);
#endif

      /* source max0.tcl script */
      mnScriptSourceMax0(MnInterp);
    }
      
    /* if "-help", print usage message and exit */
    if(mnCmdLineHelp) 
    {
      Tcl_Eval(MnInterp,"help_usage");
      exit(1);
    }

    /* document Tcl variables we already setup */
    MnDocVar(MnInterp, "env", "TCL_LIBRARY", TCL_LINK_STRING, 
	     "Tcl Library directory", 
	     NULL);
    MnDocVar(MnInterp, "env", "TK_LIBRARY", TCL_LINK_STRING, 
	     "Tk Library directory", 
	     NULL);
    MnDocVar(MnInterp, "argv", NULL, TCL_LINK_STRING, 
	     "command line arguments (sans those already handled in C code)", 
	     NULL);
    MnDocVar(MnInterp, "argc", NULL, TCL_LINK_STRING, 
	     "number of args in argv)", 
	     NULL);
    MnDocVar(MnInterp, "argv0", NULL, TCL_LINK_STRING, 
	     "name by which Max was invoked", 
	     NULL);
    MnDocVar(MnInterp, "MN_SWITCHES", NULL, TCL_LINK_STRING, 
	     "command line switches supported by C-code", 
	     "Does not include tk options, e.g. `-geometry'"); 
    MnDocVar(MnInterp, "MN_FILE_TECH", NULL, TCL_LINK_STRING, 
	     "technology of last file on command line", 
	     "used in max0.tcl to decide which technology to load");

    /* register tcl commands from Max modules */
    mnTclInitModules(MnInterp);

    /* Initialize Tk */
    mnInitTk(MnInterp);

    /* Initialize graphics module 
     * (graphics extensions for Layout widgets) 
     *
     * NOTE:  If insufficient colormap resources available, will
     *        restart Max with "-colormap new" !
     */
    mnInitGraphics(MnInterp,saveArgC,saveArgV);

    /* Do (technology independent) module initialization */
    mnInitModules(MnInterp);

    /* Start catching signals */
    SigInit();

    /* load the technology */
    /* (MnTech and MnTechVar are set in max0.tcl) */
    ASSERT(MnTech && MnTechVar,"main");
    mnTechLoad(MnTech, MnTechVar);

    /* Setup technolgy specific display in layout module 
     * loads styles and colormap for this technology.
     *  
     */
    LayDisplayInit(MnTech, MnTechVar);

    /* Setup backup of modified cells on exit() */
    atexit(mnDoOnExit);

    /* Source max.tcl startup script 
     * 
     *    Normally this script is (encrypted) part of executable. 
     *    If MnDeveloper set, we try to source from maxtcl/ directory
     *    instead.
     */
    mnScriptSourceMax(MnInterp);

    /* clear undo stack (don't permit undo of init file!)  */
    UndoFlush();

#if WINNTPAT
    /* You dont get console error messages until you init the interpreter.
     */
    TkConsoleCreate();
    if (TkConsoleInit(MnInterp) == TCL_ERROR) {
	WinPanic(MnInterp->result);
    }
#else
    /* setup event handler for stdin */
    mainTerminalInit(MnInterp);
#endif

    /* begin event loop */
    mnEventLoop(MnInterp); /* never returns */

    /* keep gcc from fussing */
    return 0; 

} /* main */
