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
 * message.c --
 *
 * 	This module handles "terminal" i/o inside commands.
 *      NOTE: Not used for parsing commands themselves!
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
static char rcsid[]="$Header: txMain.c,v 6.0 90/08/28 18:58:16 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <tcl.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "memory.h"
#include "main.h"

/* truncate messages exceeding this length
 * (note truncation is not exact, somewhat longer messages are possible)
 */
#define MESSAGE_MAX_LENGTH 5000 

/* If script pointers non-null, they are tcl evaled from corresponding
 * C routines.
 *
 * (These are set via msg_map tcl command).
 */
static char *infoScript = NULL;
static char *warnScript = NULL;
Tcl_Interp *interp = NULL;       /* Tcl Interpeter to eval scripts with */

/* context stacks used to divert messages and collect error msgs (in reentrant way) */
typedef struct msgcxtstack
{
  Tcl_DString *mcs_textDS;
  struct msgcxtstack *mcs_next;
} MsgCxtStack;


static MsgCxtStack *msgInfoStack = NULL;
static int msgInfoStackDepth = 0;  /* for debug (tcl linked) */

static MsgCxtStack *msgWarnStack = NULL;
static int msgWarnStackDepth = 0;  /* for debug (tcl linked) */

static MsgCxtStack *msgErrorStack = NULL;
static int msgErrorStackDepth = 0; /* for debug (tcl linked) */


/*
 * ----------------------------------------------------------------------------
 * msgV:
 *
 *	Called by MsgInfo*, MsgWarn*, and MsgError* funcs below to  
 *      generate info warn and error messages.
 *
 *      Handles message diversion (via context stacks, see "msg_catch")
 *      and message mapping (to tcl funcs, see msg_map).
 *
 * Types of messages:
 *
 *      info - messages during normal processing (defaults to stdout)
 *      warn - abnormal conditions, but command not aborted (default: stderr)
 *      error - abnormal condition, command aborting (messages passed up call stack
 *              as tcl result, according to tcl error mechanism)
 *      panic - internal inconsistency, Max aborting (not handled here).
 *
 * ----------------------------------------------------------------------------
 */ 
static void
msgV(MsgCxtStack *stack, 
     char *script, 
     FILE *file,
     char *fmt,
     va_list args)
{
    if(stack)
    {
      /* if first message this context, alloc and intial dynamic string */
      if(!stack->mcs_textDS) 
      {
	  Tcl_DString *newDS;
	  MALLOC(Tcl_DString *, newDS, sizeof(Tcl_DString));
	  Tcl_DStringInit(newDS);
	  stack->mcs_textDS = newDS;
      }
      /* if max length reached, ignore further messages */
      else if(Tcl_DStringLength(stack->mcs_textDS) >= MESSAGE_MAX_LENGTH)
      {
	return;
      }

      /* append message to top of stack */
      {
	int n;
	char buf[MESSAGE_MAX_LENGTH + 5000];
	(void) vsprintf(buf, fmt, args);
	n = MIN(strlen(buf),
		(MESSAGE_MAX_LENGTH - Tcl_DStringLength(stack->mcs_textDS)));

	Tcl_DStringAppend(stack->mcs_textDS, 
			  buf, 
			  n);
      }

      /* add ... to max length messages */
      if(Tcl_DStringLength(stack->mcs_textDS) >= MESSAGE_MAX_LENGTH)
      {
	Tcl_DStringAppend(stack->mcs_textDS, "...", -1);
      }
    }
    else if(script && *script!='\0')
    {
        /* TCL SCRIPT, SO INVOKE IT */
        int completion;
        Tcl_DString saveResultDS; 
	Tcl_DString scriptDS;
        char buf[MESSAGE_MAX_LENGTH+5000];

	/* gen print string */
        (void) vsprintf(buf, fmt, args);

	/* build script to eval */
	Tcl_DStringInit(&scriptDS);
        Tcl_DStringAppend(&scriptDS, script, -1),
        Tcl_DStringAppend(&scriptDS, " ", -1),
        Tcl_DStringAppendElement(&scriptDS, buf),
	
        /* Stash away current interp result, and reset */
        Tcl_DStringInit(&saveResultDS);
        Tcl_DStringAppend(&saveResultDS, interp->result, -1),
        Tcl_ResetResult(interp);

        completion = Tcl_Eval(interp, Tcl_DStringValue(&scriptDS));
        if (completion != TCL_OK) 
        {
	    Tcl_AddErrorInfo(interp,
	        "\n    (msgV script)");
	    /* TODO:  Should not use Tcl_BackgroundError here? */
  	    Tcl_BackgroundError(interp);
        }

        /* restore interp result */
        Tcl_FreeResult(interp);
        Tcl_SetResult(interp, Tcl_DStringValue(&saveResultDS), TCL_VOLATILE);

	/* free dynamic strings */
	Tcl_DStringFree(&saveResultDS);
	Tcl_DStringFree(&scriptDS);
    }
    else
    {
        /* NO TCL SCRIPT - just print to default file */
        ASSERT(file,"msgV");
#if WINNTPAT
        /* This terrible hack is needed because messages to stdout
         * and stderr do not appear until the console is inited.
         * To prevent this, printf, fprintf and vprintf are all hooked,
         * but vfprintf is not.  So route message to vprintf.
         */
        if (file == stdout || file == stderr) {
	    vprintf(fmt,args);
	    return;
        }
#endif
        (void) vfprintf(file, fmt, args);
    }

    return;
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgPushInfoStack --
 *
 * Start new info message diversion. 
 *
 * Used by msgCatchTclCmd below
 *
 * ----------------------------------------------------------------------------
 */
static void msgPushInfoStack(void)
{
  MsgCxtStack *new;

  MALLOC_TAG(MsgCxtStack *, new, sizeof(MsgCxtStack),"MsgCxtStack");
  new->mcs_textDS = 0;
  new->mcs_next = msgInfoStack;
  msgInfoStack = new;

  msgInfoStackDepth++;
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgPopInfoStack --
 *
 * End info message diversion.
 *
 * Used by msgCatchTclCmd below
 *
 * Result:  Pointer to dynamic string containing diverted messages (or NULL if none)
 *
 * ----------------------------------------------------------------------------
 */
static Tcl_DString *msgPopInfoStack(void)
{
  Tcl_DString *textDS;
  MsgCxtStack *top = msgInfoStack;

  ASSERT(top,"msgPopInfoStack");

  /* get text */
  textDS = top->mcs_textDS;

  /* pop */
  msgInfoStack = top->mcs_next;
  FREE(top);

  msgInfoStackDepth--;
  
  return textDS;
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgPushWarnStack --
 *
 * Start new warning message diversion. 
 *
 * Used by msgCatchTclCmd below
 *
 * ----------------------------------------------------------------------------
 */
static void msgPushWarnStack(void)
{
  MsgCxtStack *new;

  MALLOC_TAG(MsgCxtStack *, new, sizeof(MsgCxtStack),"MsgCxtStack");
  new->mcs_textDS = 0;
  new->mcs_next = msgWarnStack;
  msgWarnStack = new;

  msgWarnStackDepth++;
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgPopWarnStack --
 *
 * End warning message diversion.
 *
 * Used by msgCatchTclCmd below
 *
 * Result:  Pointer to dynamic string containing diverted messages (or NULL if none)
 *
 * ----------------------------------------------------------------------------
 */
static Tcl_DString *msgPopWarnStack(void)
{
  Tcl_DString *textDS;
  MsgCxtStack *top = msgWarnStack;

  ASSERT(top,"msgPopWarnStack");

  /* get text */
  textDS = top->mcs_textDS;

  /* pop */
  msgWarnStack = top->mcs_next;
  FREE(top);

  msgWarnStackDepth--;
  
  return textDS;
}


/*
 * ----------------------------------------------------------------------------
 *
 * msgPushErrorStack --
 *
 * Start new error message diversion. 
 *
 * Used by msgBeginCmd and msgCatchTclCmd below
 *
 * ----------------------------------------------------------------------------
 */
static void msgPushErrorStack(void)
{
  MsgCxtStack *new;

  MALLOC_TAG(MsgCxtStack *, new, sizeof(MsgCxtStack),"MsgCxtStack");
  new->mcs_textDS = 0;
  new->mcs_next = msgErrorStack;
  msgErrorStack = new;

  msgErrorStackDepth++;
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgPopErrorStack --
 *
 * End error message diversion.
 *
 * Used by msgEndCmd and msgCatchTclCmd below
 *
 * Result:  Pointer to dynamic string containing diverted messages (or NULL if none)
 *
 * ----------------------------------------------------------------------------
 */
static Tcl_DString *msgPopErrorStack(void)
{
  Tcl_DString *textDS;
  MsgCxtStack *top = msgErrorStack;

  ASSERT(top,"msgPopErrorStack");

  /* get text */
  textDS = top->mcs_textDS;

  /* pop */
  msgErrorStack = top->mcs_next;
  FREE(top);

  msgErrorStackDepth--;
  
  return textDS;
}


/*
 * ----------------------------------------------------------------------------
 * MsgCmdBegin
 *
 * 	Called at beginning of tcl commands to push error context stack
 * 
 *      NOTE:  Don't call directly, use CMD_BEGIN() macro.
 *
 * ----------------------------------------------------------------------------
 */
void
MsgCmdBegin()
{
  msgPushErrorStack();
}


/*
 * ----------------------------------------------------------------------------
 * MsgCmdEnd
 *
 * 	Called just prior to return from tcl commands.
 *
 *      NOTE:  Don't call directly, use CMD_RETURN() macro instead.
 *
 * Results:
 *      Appropriate return code for tcl command.
 *
 * Side Effects:
 *      Pops error stack.
 *      If MsgErrorF called during execution, sets tcl return value to 
 *      error text.
 *
 * ----------------------------------------------------------------------------
 */
int
MsgCmdEnd(Tcl_Interp *interp)
{
  Tcl_DString *errorDS = msgPopErrorStack();
  
  if(errorDS)
  {
    /* ERRORS OCCURRED - move error string into tcl result and return TCL_ERROR */
    Tcl_FreeResult(interp);
    Tcl_SetResult(interp, Tcl_DStringValue(errorDS), TCL_VOLATILE);
    Tcl_DStringFree(errorDS);

    /* reset error msg counts */
    DBAccessMsgsClear();

    return TCL_ERROR;
  }
  else
  {
    /* NO ERRORS */
    return TCL_OK;
  }
}


/*
 * ----------------------------------------------------------------------------
 * MsgInfoV:
 *
 *	MsgInfoF() with var args roled into single arg.
 *      Called by var arg funcs to invoke MsgInfoF internally.
 *      See MsgInfoF below.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See MsgInfoF
 *
 * ----------------------------------------------------------------------------
 */

void
MsgInfoV(char *fmt, va_list args)
{
    msgV(msgInfoStack, infoScript, stdout, fmt, args);
}


/*
 * ----------------------------------------------------------------------------
 * MsgInfoF:
 *
 *	Args like printf, for info messages.
 *
 *      "Info" messages are messages during normal exectuion.
 *
 *      Info messages go to standard out by default.
 *      But they can be diverted (see msg_catch and msg_map).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
void
MsgInfoF(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    MsgInfoV(fmt,args);

    va_end(args);
}


/*
 * ----------------------------------------------------------------------------
 * MsgWarnV:
 *
 *	MsgWarnF() with var args roled into single arg.
 *      Called by var arg funcs to invoke MsgInfoF internally.
 *      See MsgInfoF below.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See MsgWarnF
 *
 * ----------------------------------------------------------------------------
 */

void
MsgWarnV(char *fmt, va_list args)
{
    msgV(msgWarnStack,warnScript,stderr, fmt, args);
}


/*
 * ----------------------------------------------------------------------------
 * MsgWarnF:
 *
 *	Args like printf, for warning messages.
 *
 *      "warning" are used to indicate abnormal events, when command exection is not aborted.
 *
 *      Warn messages go to standard error by default.
 *      But they can be diverted (see msg_catch and msg_map).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
void
MsgWarnF(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    MsgWarnV(fmt,args);

    va_end(args);
}


/*
 * ----------------------------------------------------------------------------
 * MsgErrorV:
 *
 *	MsgErrorF() with var args roled into single arg.
 *      Called by var arg funcs to invoke MsgErrorF internally.
 *      See MsgErrorF below.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See MsgErrorF
 *
 * ----------------------------------------------------------------------------
 */

void
MsgErrorV(char *fmt, va_list args)
{
    msgV(msgErrorStack,NULL,stderr, fmt, args);
}


/*
 * ----------------------------------------------------------------------------
 * MsgErrorF:
 *
 *	Args like printf, for error messages.
 *      Error messages inside commands indicate command is aborting.
 *
 *      INSIDE COMMAND, collects error messages in Dynamic string.
 *      On command completion (txCmdEnd() called) error messages copied to
 *      tcl result, and command returns TCL_ERROR.
 *
 *      NOT INSIDE COMMAND messages sent to standard error.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */
void
MsgErrorF(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    MsgErrorV(fmt,args);

    va_end(args);
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgTclCmd --
 *
 * Implement msg command.
 *
 * Result:
 *	A standard Tcl result.
 *
 * ----------------------------------------------------------------------------
 */

#define msg_DESC "generate a message (info or warning)."

#define msg_DOC "
Usage:
  msg [-warn] message

  Puts out \"info\" message by default, or \"warning\" message if -warn flag
  given.

  \"info\"  = message during normal execution (default).
  \"warn\"  = message when abnormal situation encountered, but execution continues .
  \"error\" = message when abnormal situation encountered, and command aborted.
              (Use Tcl \"error\" command for errors.)
 
  See also \"msg_catch\" and \"msg_map\" commands.
"
static int    
msgTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
  bool warn;
  char *msg;

  CMD_BEGIN(interp);

  /* parse args */
  if (argc == 2)
  {
    /* info message */
    warn = False;
    msg = argv[1];
  }
  else if (argc == 3 && strcmp(argv[1],"-warn")==0)
  {
    /* warning message */
    warn = True;
    msg = argv[2];
  }
  else
  {
    /* usage */ 
    MsgErrorF("usage: %s [-warn] message\n", argv[0]);
    CMD_RETURN(interp);  
  }

  /* truncate long messages to avoid buffer overflow and annoying user */
  {
    char buf[MESSAGE_MAX_LENGTH + 100];
    int length = 0;

    while(*msg && length<MESSAGE_MAX_LENGTH) 
    for(length=0; length<MESSAGE_MAX_LENGTH; length++)      
    {
      buf[length] = *msg;
      msg++;
      if(*msg == '\0') break;
    }
    buf[length+1] = '\0';

    if(warn)
    {
      MsgWarnF("%s",buf);
    } 
    else
    {
      MsgInfoF("%s",buf);
    } 
  }

  CMD_RETURN(interp);  
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgCatchTclCmd --
 *
 * Implement msg_catch command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * ----------------------------------------------------------------------------
 */
#define msg_catch_DESC "catch info messages, warnings and errors"

#define msg_catch_DOC "
Usage:
  msg_catch command [return_var_name [info_var_name [warn_var_name]]] 

  \"msg_catch\" evaluates \"command\" and returns a completion code, like the tcl 
  catch command, but additionally allows info and warning messages to be diverted.

  If \"return_var_name\" is given, the return value of \"command\" is put in the
  named variable.  (May be null-string)

  If \"info_var_name\" is given, any info messages generated by \"command\" are diverted
  to the named variable.  If null-string, info messages are not diverted.

  If \"warn_var_name\" is given, any warning messages generated by \"command\" are diverted
  to that variable.  If null-string, warning messages are not diverted.

Result:
  Normally \"msg_catch\" returns a completion code of 0.  

  If an error occurs during \"command\", \"msg_catch\" returns 1, and the return_var_name 
  (if present) is set to an error message.  The global variable \"errorInfo\" is set
  to a stack trace.
"

static int    
msgCatchTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
   int completion;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc < 2 || argc > 5 ) goto usage;

    /* divert info messages */
    if(argc>=4 && *argv[3]!='\0') msgPushInfoStack();

    /* divert warn messages */
    if(argc>=5 && *argv[4]!='\0') msgPushWarnStack();
    
    /* Tcl eval command */
    completion = Tcl_Eval(interp, argv[1]);

    /* set return_var_name */
    if(argc>=3 && *argv[2]!= '\0')
    {
        if(!Tcl_SetVar(interp,
		       argv[2],
		       interp->result,
		       TCL_LEAVE_ERR_MSG))
	  {
	     MsgErrorF("%s\n"
		       "%s could not save return value into %s\n",
		       interp->result,
		       argv[0],
		       argv[2]);
	   }

    }

    /* set info_var_name */
    if(argc>=4 && *argv[3]!='\0') 
    {
      Tcl_DString *msgDS = msgPopInfoStack();
 
      if(!Tcl_SetVar(interp,
		     argv[3],
		     msgDS ? Tcl_DStringValue(msgDS) : "",
		     TCL_LEAVE_ERR_MSG))
      {
	   MsgErrorF("%s\n"
		     "%s could not save info messages into %s\n",
		     interp->result,
		     argv[0],
		     argv[3]);
      }
      if(msgDS) Tcl_DStringFree(msgDS);
    }
      
    /* set warn_var_name */
    if(argc>=5 && *argv[4]!='\0') 
    {
      Tcl_DString *msgDS = msgPopWarnStack();
 
      if(!Tcl_SetVar(interp,
		     argv[4],
		     msgDS ? Tcl_DStringValue(msgDS) : "",
		     TCL_LEAVE_ERR_MSG))
      {
	   MsgErrorF("%s\n"
		     "%s could not save warning messages into %s\n",
		     interp->result,
		     argv[0],
		     argv[4]);
      }
      if(msgDS) Tcl_DStringFree(msgDS);
    }

    /* set tcl result to completion code */
    {
      char buf[1000];
      ASSERT(sprintf(buf,"%d",completion)>0,"msgCatchTclCmd");
      Tcl_SetResult(interp, buf, TCL_VOLATILE);
    }

    /* return */
    CMD_RETURN(interp);

usage:
    {
      MsgErrorF("usage:  %s command [return_var_name [info_var_name [warn_var_name]]]\n",
	      argv[0]); 
      CMD_RETURN(interp);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * msgMapTclCmd --
 *
 * Implement msg_map command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side effects:
 *       Subsequent calls to msg routines cause given scripts to be invoked.
 *
 * ----------------------------------------------------------------------------
 */

#define msg_map_DESC "map C msg (and text input) funcs to tcl commands"

#define msg_map_DOC "
Usage:
  msg_map [inputScript infoScript warnScript]

 (null args indicated don't map that function)

 inputScript - SHOULD BE NULL (this feature no longer supported).  
 infoScript  - use to \"print\" info messages. 
 warnScript  - use to \"print\" warning messages. 


Tcl Result (previous values):
  inputScript infoScript warnScript
"

static int    
msgMapTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1 && argc !=4 ) goto usage;

    /* set result to current value of scripts */
#   define f(x) ( (x!=NULL)?x:"" ) 
        Tcl_AppendElement(interp,"");  /* inputScript no longer supported */
        Tcl_AppendElement(interp,f(infoScript));
        Tcl_AppendElement(interp,f(warnScript));
#    undef f

    /* if args present, set scripts to them */
    if (argc == 4)
    {
        if(strlen(argv[1])!=0) MsgWarnF("msg_map:  non_null <inputScript> ignored (no longer supported)\n");
        StrDup(&infoScript,argv[2]);
        StrDup(&warnScript,argv[3]);
    }

    CMD_RETURN(interp);  

usage:
    MsgErrorF("usage: %s [inputScript infoScript warnScript]", argv[0]);
    CMD_RETURN(interp);  
}


/*
 * ----------------------------------------------------------------------------
 *
 * MsgTclInit --
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
MsgTclInit(Tcl_Interp *tclInterp)
{
   interp = tclInterp;

   MnDocCreateCommand(interp, 
	       "msg", msgTclCmd,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       msg_DESC, msg_DOC);

   MnDocCreateCommand(interp, 
	       "msg_catch", msgCatchTclCmd,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       msg_catch_DESC, msg_catch_DOC);

   MnDocCreateCommand(interp, 
	       "msg_map", msgMapTclCmd,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       msg_map_DESC, msg_map_DOC);

   MnDocLinkVar(interp, "MSG_INFO_STACK_DEPTH", 
	       (char *) &msgInfoStackDepth, 
	       TCL_LINK_INT | TCL_LINK_READ_ONLY,
	       "number of info message diversions in effect",
	       NULL);

   MnDocLinkVar(interp, "MSG_WARN_STACK_DEPTH", 
	       (char *) &msgWarnStackDepth, 
	       TCL_LINK_INT | TCL_LINK_READ_ONLY,
	       "number of warning message diversions in effect",
	       NULL);

   MnDocLinkVar(interp, "MSG_ERROR_STACK_DEPTH", 
	       (char *) &msgErrorStackDepth, 
	       TCL_LINK_INT | TCL_LINK_READ_ONLY,
	       "number of error message diversions in effect",
	       NULL);
}
