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
 * cifTcl.c -- Tcl command interface to this module.
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "signals.h"
#include "layout.h"
#include "database.h"
#include "units.h"
#include "utils.h"
#include "database.h"
#include "databaseInt.h"
#include "cif.h"
#include "cifInt.h"
#include "cifRead.h"


/*
 *--------------------------------------------------------------
 *
 * cifTclCmdLayers --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define cif_layers_DESC "list cif layers (for current ostyle)"

#define cif_layers_DOC "
  returns a line for each cif layer in current ostyle:       
    name gds_num gds_type [temp]

layers with no GDSII correspondence have gds_num and gds_type of -1 
templayers (not output to cif or gdsII) are marked \"temp\".
"

static int
cifTclCmdLayers(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
	MsgErrorF("usage: %s\n",argv[0]);
	CMD_RETURN(interp);
    }

    /* list types */
    for (i = 0; i < CIFCurStyle->cs_nLayers; i++)
    {
        char buf[100];

        /* separate types in result with new lines */
	if (i != 0) Tcl_AppendResult(interp,"\n",NULL);

	/* name */
        Tcl_AppendElement(interp, CIFCurStyle->cs_layers[i]->cl_name);

	/* calma num */
	sprintf(buf,"%d",CIFCurStyle->cs_layers[i]->cl_calmanum);
   	Tcl_AppendElement(interp, buf);

	/* calma type */
	sprintf(buf,"%d",CIFCurStyle->cs_layers[i]->cl_calmatype);
   	Tcl_AppendElement(interp, buf);

	/* temp layer? */
	if(CIFCurStyle->cs_layers[i]->clay_flags & CIF_TEMP)
	{
	  Tcl_AppendElement(interp, "temp");
	}
    }
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * cifTclCmdIStyle --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define cif_istyle_DESC "set/query import style (CIF input style)"

#define cif_istyle_DOC "
usage:	cif_istyle [name]
	or 
	cif_istyle -list

returns name of istyle prior to set.
if name given, sets istyle to name.
-list returns list of valid istyles for current technology.

Cif Istyles define mappings from CIF and GDSII layers to Max layers
(when reading CIF or GDSII stream). 
"

static int
cifTclCmdIStyle(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;
    char *cmdName;
    bool list = FALSE;
    CIFReadStyle *style;

    CMD_BEGIN(interp);

    /* Parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='l' && strncmp(*argv,"-list",length)==0)
      {
	argc--; argv++;
	list = TRUE;
	continue;
      }
      
      /* bad switch */
      goto usage;
      
    }
    
    /* list istyles */
    if(list)
    {
      if(argc != 0) goto usage;

      for (style = cifReadStyleList; style != NULL; style = style->crs_next)
      {
        Tcl_AppendElement(interp, style->crs_name);
      }

      CMD_RETURN(interp);
    }

    if(argc > 1) goto usage;

    /* return current istyle name */
    Tcl_AppendElement(interp, cifCurReadStyle->crs_name);

    /* do set */
    if(argc > 0)
    {
      char *name = *argv;
      argc++;
      CIFSetReadStyle(name);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [name]\n\tor\n%s -list\n",cmdName, cmdName);     
    CMD_RETURN(interp);

badStyle:
    MsgInfoF("The CIF input styles are: ");
    for (style = cifReadStyleList; style != NULL; style = style->crs_next)
    {
	if (style == cifReadStyleList)
	    MsgInfoF("%s", style->crs_name);
	else MsgInfoF(", %s", style->crs_name);
    }
    MsgInfoF(".\n");
    if (cifCurReadStyle != NULL)
	MsgInfoF("The current style is \"%s\".\n", cifCurReadStyle->crs_name);

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * cifTclCmdOStyle --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define cif_ostyle_DESC "set/query export style (CIF output style)"

#define cif_ostyle_DOC "
usage:	cif_ostyle [name]
	or 
	cif_ostyle -list

returns name of ostyle prior to set.
if name given, sets ostyle to name.
-list returns list of valid ostyles for current technology.

Cif Ostyles define mappings from Max layers to CIF and GDSII (when writing CIF
or GDSII stream).  The scale of the current ostyle also defines the size
of objects in microns (that is the relationship between Max database units and
microns).
"

static int
cifTclCmdOStyle(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;
    char *cmdName;
    bool list = FALSE;
    CIFStyle *style;

    CMD_BEGIN(interp);

    /* Parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='l' && strncmp(*argv,"-list",length)==0)
      {
	argc--; argv++;
	list = TRUE;
	continue;
      }
      
      /* bad switch */
      goto usage;
      
    }
    
    /* list ostyles */
    if(list)
    {
      if(argc != 0) goto usage;

      for (style = CIFStyleList; style != NULL; style = style->cs_next)
      {
        Tcl_AppendElement(interp, style->cs_name);
      }

      CMD_RETURN(interp);
    }

    if(argc > 1) goto usage;

    /* return current ostyle name */
    Tcl_AppendElement(interp, CIFCurStyle->cs_name);

    /* do set */
    if(argc > 0)
    {
      char *name = *argv;
      argc++;
      CIFSetStyle(name);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [name]\n\tor\n%s -list\n",cmdName, cmdName);     
    CMD_RETURN(interp);

badStyle:
    MsgInfoF("The CIF output styles are: ");
    for (style = CIFStyleList; style != NULL; style = style->cs_next)
    {
	if (style == CIFStyleList)
	    MsgInfoF("%s", style->cs_name);
	else MsgInfoF(", %s", style->cs_name);
    }
    MsgInfoF(".\n");
    if (CIFCurStyle != NULL)
	MsgInfoF("The current style is \"%s\".\n", CIFCurStyle->cs_name);

    CMD_RETURN(interp);
}



/*
 * ----------------------------------------------------------------------------
 *
 * cifTclInit --
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
CifTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "cif_layers", cifTclCmdLayers,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       cif_layers_DESC,
	       cif_layers_DOC);

   MnDocCreateCommand(interp, "cif_istyle", cifTclCmdIStyle,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       cif_istyle_DESC,
	       cif_istyle_DOC);

   MnDocCreateCommand(interp, "cif_ostyle", cifTclCmdOStyle,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       cif_ostyle_DESC,
	       cif_ostyle_DOC);

  MnDocLinkVar(interp, "CIF_HIER_STEP_SIZE", 
	       (char *) &cifHierStepSizeWidths, TCL_LINK_INT,
	       "hierarchical mask operation step size in typical wire widths",
	       "e.g. if 1000, then processing is broken down" 
	       " into squares 1000 typical wire widths on a side");
}





