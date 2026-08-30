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
 * mnDoc.c --
 *
 * All (Tcl) commands in Max, and Tcl linked C varaiables
 * are defined via the commands in this module.  
 *
 * (wrappers for Tcl procedures for auto documentation)
 *
 */

#ifndef lint
static char rcsid[]="$$";
#endif  not lint

#include <stdlib.h>
#include <stdio.h>
#include <tcl.h>
#include <tk.h>
#include "magic.h"

/*
 * ----------------------------------------------------------------------------
 *
 * MnDocCreateCommand --
 *
 * Register Tcl Command for Max, and update documentation database
 *
 * ----------------------------------------------------------------------------
 */
void
MnDocCreateCommand(Tcl_Interp *interp, 
	      char *name, 
	      int func(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[]),
	      ClientData cData,
	      Tcl_CmdDeleteProc *deleteP,
	      char *desc,
	      char *doc
	      )
{
  /* Register command */
  Tcl_CreateCommand(interp, name, func, cData, deleteP);

  /* Document command */
  {
    Tcl_DString e;
    
    Tcl_DStringInit(&e);
    Tcl_DStringAppendElement(&e, desc);
    Tcl_DStringAppendElement(&e, doc);

    Tcl_VarEval(interp,
	      "doc_add_cmd ", name, " ",Tcl_DStringValue(&e),"\n",
	      (char *) NULL);

    Tcl_DStringFree(&e);
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * MnDocCreateObjCommand --
 *
 * Register Tcl Command for Max, that takes args as OBJECTS 
 * and update documentation database
 *
 * ----------------------------------------------------------------------------
 */
void
MnDocCreateObjCommand(Tcl_Interp *interp,
		      char *name,
		      Tcl_ObjCmdProc func,
		      ClientData cData,
		      Tcl_CmdDeleteProc *deleteP,
		      char *desc,
		      char *doc)
{
  /* Register command */
  Tcl_CreateObjCommand(interp, name, func, cData, deleteP);

  /* Document command */
  {
    Tcl_DString e;

    Tcl_DStringInit(&e);
    Tcl_DStringAppendElement(&e, desc);
    Tcl_DStringAppendElement(&e, doc);

    Tcl_VarEval(interp,
              "doc_add_cmd ", name, " ",Tcl_DStringValue(&e),"\n",
              (char *) NULL);

    Tcl_DStringFree(&e);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * MnDocVar --
 *
 * Document a Tcl Variable.
 * 
 * Used to document Tcl variables that already exist.
 *
 * ----------------------------------------------------------------------------
 */
void
MnDocVar(Tcl_Interp *interp, 
	 char *part1,              
	 char *part2,              
	 int type,             
	 char *desc,               /* one line desc */
	 char *doc)                /* detailed documentation */
{
  char name[BUFSIZ];
  Tcl_DString e;

  /* full name */
  if(part2) 
  {
    sprintf(name,"%s(%s)", part1, part2);
  }
  else
  {
    sprintf(name,"%s", part1);
  }

  Tcl_DStringInit(&e);
  Tcl_DStringAppendElement(&e, desc);
  Tcl_DStringAppendElement(&e, doc);

  /* type */
  switch (type&07) {
  case TCL_LINK_INT: Tcl_DStringAppendElement(&e, "INT");
    break;
  case TCL_LINK_DOUBLE: Tcl_DStringAppendElement(&e, "DOUBLE");
    break;
  case TCL_LINK_BOOLEAN: Tcl_DStringAppendElement(&e, "BOOLEAN");
    break;
  case TCL_LINK_STRING: Tcl_DStringAppendElement(&e, "STRING");
    break;
  default: Tcl_DStringAppendElement(&e, "?");
  }

  /* flags */
  Tcl_DStringStartSublist(&e);
  if(type&TCL_LINK_READ_ONLY) Tcl_DStringAppendElement(&e, "READ_ONLY");
  Tcl_DStringEndSublist(&e);

  Tcl_VarEval(interp,
	      "doc_add_var ", name, " ",Tcl_DStringValue(&e),"\n",
	      (char *) NULL);

  Tcl_DStringFree(&e);
}

/*
 * ----------------------------------------------------------------------------
 *
 * MnDocLinkVar --
 *
 * Link C and Tcl Variable, and update documentation database.
 *
 * ----------------------------------------------------------------------------
 */
void
MnDocLinkVar(Tcl_Interp *interp, 
	     char *name,               /* tcl var name */
	     char *addr,               /* address of corresponding C variable */
	     int type,                 /* variable type */
	     char *desc,               /* one line desc */
	     char *doc)                /* detailed documentation */
{
  /* do the link */
  Tcl_LinkVar(interp, name, addr, type);

  /* document variable */
  MnDocVar(interp, name, NULL, type, desc, doc);
}

/*
 * ----------------------------------------------------------------------------
 *
 * MnDocSetVar --
 *
 * Set (initial) Tcl Variable, and document it. 
 *
 * ----------------------------------------------------------------------------
 */
void
MnDocSetVar(Tcl_Interp *interp, 
	    char *name,              
	    char *newValue,             
	    int flags,             
	    char *desc,               /* one line desc */
	    char *doc)                /* detailed documentation */
{
  /* do the link */
  Tcl_SetVar(interp, name, newValue, flags);

  /* document variable */
  MnDocVar(interp, name, NULL, 
	   TCL_LINK_STRING | TCL_LINK_READ_ONLY, 
	   desc, doc);
}

/*
 * ----------------------------------------------------------------------------
 *
 * MnDocSetVar2 --
 *
 * Set (initial) Tcl Variable, and document it. 
 *
 * ----------------------------------------------------------------------------
 */
void
MnDocSetVar2(Tcl_Interp *interp, 
	     char *part1,              
	     char *part2,              
	     char *newValue,             
	     int flags,             
	     char *desc,               /* one line desc */
	     char *doc)                /* detailed documentation */
{
  /* do the link */
  Tcl_SetVar2(interp, part1, part2, newValue, flags);

  /* document variable */
  MnDocVar(interp, part1, part2, 
	   TCL_LINK_STRING | TCL_LINK_READ_ONLY, 
	   desc, doc);

}


