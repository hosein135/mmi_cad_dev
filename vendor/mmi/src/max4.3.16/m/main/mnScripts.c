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
 * mnScripts.c --
 *
 * Contains code for sourcing encrypted integral startup tcl scripts.
 *
 */

#ifndef lint
static char rcsid[]="$Header$";
#endif  not lint

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/times.h>
#include <sys/stat.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>
#include <tclInt.h> 
#include "magic.h"
#include "utils.h"
#include "main.h"
#include "mainInt.h"

/* integral tcl startup scripts (encrypted) */

/*
 * ----------------------------------------------------------------------------
 *
 * mnSourceScriptFile --
 *
 * Source a startup tcl file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	complains and exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
static void
mnSourceScriptFile(Tcl_Interp *interp, char *pathName)
{

  /* make script pathname available to the script */
  Tcl_SetVar(interp,"MN_SCRIPT_FILE",pathName,TCL_GLOBAL_ONLY);

  if (Tcl_VarEval(interp,"source ",pathName,(char *) NULL) != TCL_OK)
  {
    char *msg;

    msg = Tcl_GetVar(interp, "errorInfo", TCL_GLOBAL_ONLY);
    if (msg == NULL) msg = interp->result;
    fprintf(stderr,"%s\n",msg);
    fprintf(stderr,
	    "Max:  Fatal Error, system startup script %s"
	    " did not complete normally.\n", 
	    pathName);
    exit(1);
  }

  /* var only set during script readin */
  Tcl_UnsetVar(interp,"MN_SCRIPT_FILE",TCL_GLOBAL_ONLY);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnScriptEval -
 *
 * Like Tcl_Eval but does not make copy of script being evaled.
 * (Leaving a copy around is a security problem!)
 *
 * Results:
 *	TCL_OK on success, TCL_ERROR on failure.
 *
 * ----------------------------------------------------------------------------
 */
static int mnScriptEval(Tcl_Interp *interp, 
			char *script,
			int scriptLength)
{
    Tcl_Obj *cmdPtr;
    int result;

    /*
     * Initialize a Tcl object from the command string.
     */
    TclNewObj(cmdPtr);
    cmdPtr->bytes = script;
    cmdPtr->length = scriptLength-1 ; /* need -1 here, don't know why! :-( */ 
    Tcl_IncrRefCount(cmdPtr);

    /*
     * Compile and execute the bytecodes.
     */
    result = Tcl_EvalObj(interp, cmdPtr);

    /* Make sure nobody else is referencing this */
    ASSERT(cmdPtr->refCount == 1,"mnScriptEval");

    /* (Don't want to free our Tcl_OBj since string was not malloced) */

    /* return the result */
    return result;
}


/*
 * ----------------------------------------------------------------------------
 *
 * mnSourceScript --
 *
 * Source startup tcl script into tcl interpreter.
 *
 * Normally, we source encrypted version in executable, 
 * BUT if fileName, we try to source it first (if found in system path).
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
mnSourceScript(Tcl_Interp *interp, 
	       char *name, 
	       char *script, 
	       int scriptLength,
	       char *fileName)
{
  FILE *fp;
  int result;
  char *realName;

  /* if file given and exists, read from disk */ 
  if( fileName && 
     (fp=PaOpen(fileName, "r", NULL, MnPathSysLib, &realName)) != NULL)
  {
    char realName2[BUFSIZ];
    fclose(fp);

    /* copy so pathname doesn't get trashed */
    strcpy(realName2,realName);

    mnSourceScriptFile(interp, realName2);
  }
  else
  {
    /* use internal version */
    result = mnScriptEval(interp, script, scriptLength);

    if(result != TCL_OK) 
    {
      char *msg;
      msg = Tcl_GetVar(MnInterp, "errorInfo", TCL_GLOBAL_ONLY);
      if (msg == NULL) msg = MnInterp->result;
      fprintf(stderr,"%s\n",msg);
      fprintf(stderr,
	      "Max:  Fatal Error, integral %s startup script"
	      " did not complete normally.\n", 
	      name);
      exit(1);
    }
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnScriptSourceMax0 --
 *
 * Source Max0 startup script.
 *
 * Normally, we source encrypted version in executable, but if MnDeveloper set,
 * we try to source from maxtcl dir.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
void
mnScriptSourceMax0(Tcl_Interp *interp)
{
  char buf[BUFSIZ];
  char *fileName = NULL;
  static char script[] = 
#include "../../maxtcl/max0.prep_h"
  ;

  /* set filename */
  if (MnDeveloper) fileName = "maxtcl/max0.tcl";
  if (mnMaxTcl)
  {
    sprintf(buf,"%s/max0.tcl",
	    mnMaxTcl);
    fileName = buf;
  }

  mnSourceScript(interp, 
		 "max0", 
		 script, 
		 sizeof(script) -1, /* length doesn't include terminating null */ 
		 fileName);
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnScriptSourceMax --
 *
 * Source Max startup script.
 *
 * Normally, we source encrypted version in executable, but if MnDeveloper set,
 * we try to source from maxtcl dir.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
void
mnScriptSourceMax(Tcl_Interp *interp)
{
  char buf[BUFSIZ];
  char *fileName = NULL;
  static char script[] = 
#include "../../maxtcl/max.prep_h"
  ;

  /* set filename */
  if (MnDeveloper) fileName = "maxtcl/max.tcl";
  if (mnMaxTcl)
  {
    sprintf(buf,"%s/max.tcl",
	    mnMaxTcl);
    fileName = buf;
  }

  mnSourceScript(interp, 
		 "max", 
		 script, 
		 sizeof(script) -1, /* length doesn't include terminating null */ 
		 fileName);
}


/*
 * ----------------------------------------------------------------------------
 *
 * mnScriptSourceMC --
 *
 * Source Megacell compiler 
 *
 * Source encrypted version in executable.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	exits on trouble.
 *
 * ----------------------------------------------------------------------------
 */
void
mnScriptSourceMC(Tcl_Interp *interp)
{
  static char script[] = 
#include "../../mc/mc.prep_h"
  ;

  mnSourceScript(interp, 
		 "mc", 
		 script, 
		 sizeof(script) -1, /* length doesn't include terminating 
				     *  null 
				     */ 
		 NULL);
}

