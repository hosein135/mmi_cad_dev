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
 * ntlTcl.c -- Tcl command interface to this module
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "layout.h"
#include "units.h"
#include "utils.h"
#include "undo.h"
#include "select.h"
#include "cif.h"
#include "commands.h"
#include "netlist.h"
#include "netlistInt.h"


/*
 *--------------------------------------------------------------
 *
 * ntlNetlistCmd --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define ntl_netlist_DESC "netlist cell and descendents."

#define ntl_netlist_DOC "
Usage: ntl_netlist [-cell <cellName>]

If -cell given, netlists that cell, if no -cell, defaults to edit cell.

Generates hierarchical spice netlist for cell and descendents.
"

static int
ntlNetlistCmd(ClientData clientData, 
	      Tcl_Interp *interp, 
	      int argc, char **argv)
{
  char *cmdName;
  CellDef *def = EditCellUse->cu_def;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
	
    if(c=='c' && strncmp(*argv,"-cell",length)==0)
    {
      argc--; argv++;

      if(argc==0) goto usage;
      def = DBCellLookDef(*argv);
      if(!def)
      {
	MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		  cmdName, *argv);
	CMD_RETURN(interp);
      }
      argc--; argv++;

      continue;
      }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* no positional args yet */
  if(argc>0) goto usage;


  /* netlist cell and descendents */
  {
    CellUse dummyUse;
    DBCellInitTempUse(def, &dummyUse); 
    ntlAll(&dummyUse, (char *) NULL);
  }

  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s [-cell <cellName>]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * ntlMHACmd --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define ntl_mha_DESC "development command"

#define ntl_mha_DOC "
Usage: ntl_mha 

Copy paint and labels for selected instance and descendents into parent
"

static CellDef *ntlWriteDef;

/* callback func for paint tiles */
static int
ntlPaintFunc(Tile *tile, TreeContext *cxp)
{
  Rect rect, rootRect;
  SearchContext *scx = cxp->tc_scx;
  TileType type = DBgetTileType(tile);

  TiToRect(tile, &rect);
  GeoTransRect(&scx->scx_trans, &rect, &rootRect);

  DBPaint(ntlWriteDef, &rootRect, type);

  /* continue search */
  return 0;
}

/* callback func for polygons */
static int
ntlPolyFunc(SearchContext *scx, 
	   Polygon *poly, 
	   ClientData cdarg, 
	   TerminalPath *tpath)
{

  fprintf(stderr,"ntlPolyFunc, N/Y/I. \n");

  /* continue search */
  return 0;
}

/* callback func for wirepaths */
static int
ntlWPFunc(SearchContext *scx, 
	  WirePath *wp, 
	  ClientData cdarg, 
	  TerminalPath *tpath)
{
  fprintf(stderr,"ntlWPFunc, N/Y/I. \n");

  /* continue search */
  return 0;
}

/* call back for labels */
static int
ntlLabelFunc(SearchContext *scx, 
	     Label *label, 
	     TerminalPath *tpath,
	     ClientData clientdata)
{
  Rect rootRect; 
  int rootPos;
  
  /* if not global, skip it */
  if (label->lab_kind != LAB_GLOBAL) return 0;

  /* transform */
  rootPos = GeoTransPos(&scx->scx_trans, label->lab_pos);
  GeoTransRect(&scx->scx_trans, &label->lab_rect, &rootRect);

  /* add the label */
  (void) DBLabelAdd(ntlWriteDef, 
		    &rootRect, 
		    rootPos, 
		    label->lab_text,
		    label->lab_type,
		    label->lab_kind);

  /* continue search */
  return 0;  
}

static int
ntlMHACmd(ClientData clientData, 
	      Tcl_Interp *interp, 
	      int argc, char **argv)
{
  char *cmdName;
  CellDef *def = EditCellUse->cu_def;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /***	NO SWITCHS YET
    if(c=='c' && strncmp(*argv,"-cell",length)==0)
    {
      argc--; argv++;

      if(argc==0) goto usage;
      def = DBCellLookDef(*argv);
      if(!def)
      {
	MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		  cmdName, *argv);
	CMD_RETURN(interp);
      }
      argc--; argv++;

      continue;
      }
    ***/

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* no positional args yet */
  if(argc>0) goto usage;

  {
    CellUse *use = CmdGetSelectedCell(NULL);
    SearchContext scx;
    Group *saveGroup;     /* save group on entry for restore */ 

    if(!use)
    {
      MsgErrorF("No cell selected!\n");
      CMD_RETURN(interp);
    }
    
    fprintf(stderr,"raising %s in %s\n",
	    use->cu_id,
	    EditCellUse->cu_def->cd_name);

    /* set to def we want to write into */
    ntlWriteDef = SelectRootDef;

    UndoDisable();

    /* change to special temporary group */
    {
      Group *new;
      saveGroup = ntlWriteDef->cd_activeGroup;
      new = DBGroupFromName(ntlWriteDef,"_ntl");
      if(!new) new = DBGroupNew(ntlWriteDef,"_ntl");
      ntlWriteDef->cd_activeGroup = new;
    }

    /* Setup search context */
    scx.scx_use = use; 
    scx.scx_trans = use->cu_transform;
    scx.scx_area = *DBBBoxCellDef(use->cu_def);

    /* grow area slightly so we always get touching stuff,
     * this is important since bbox may not include all drc error	 
     * tiles for example.
     */
    GEO_EXPAND(&scx.scx_area, 1, &scx.scx_area);

    /* raise paint */
    DBSearchPaintNew2(&scx,
		      &DBAllButSpaceAndDRCBits, /* layers */
		      0,               /* include all descendent cells */
		      NULL,	       /* don't need path */
		      ntlPaintFunc,
		      ntlPolyFunc,
		      ntlWPFunc,
		      NULL,           /* ClientData */
		      0);             /* flags */


    /* reset search context (may not be necessary?) */
    scx.scx_use = use; 
    scx.scx_trans = use->cu_transform;
    scx.scx_area = *DBBBoxCellDef(use->cu_def);

    /* raise labels */
    DBSearchLabels(&scx, 
		   &DBAllTypeBits, 
		   0,          /* include all descendents */
		   NULL,       /* don't need terminal path */
		   ntlLabelFunc,
		   NULL);      /* ClientData */

    /* restore original group */
    ntlWriteDef->cd_activeGroup = saveGroup;
    
    UndoEnable();
  }


  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s\n", cmdName);
  CMD_RETURN(interp);
}



/*
 * ----------------------------------------------------------------------------
 *
 * NtlTclInit --
 *
 * Initialize netlist tcl commands.
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
NtlTclInit(Tcl_Interp *interp)
{
  
  MnDocCreateCommand(interp, "ntl_netlist", ntlNetlistCmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     ntl_netlist_DESC,
		     ntl_netlist_DOC);

  
  MnDocCreateCommand(interp, "ntl_mha", ntlMHACmd,
		     (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
		     ntl_mha_DESC,
		     ntl_mha_DOC);

  MnDocLinkVar(interp, "NTL_USE_GLOBALS", 
	       (char *) &ntlUseGlobals, TCL_LINK_BOOLEAN,
	       "control output .global lines",
	       "
If set .global lines are output for globals
If reset globals are treated just like ports.
");


  MnDocLinkVar(interp, "NTL_COMMENT_TOP_DEF", 
	       (char *) &ntlCommentTopDef, TCL_LINK_BOOLEAN,
	       "TODO:  Myron:  explain this var. :-)",
	       NULL);
}




