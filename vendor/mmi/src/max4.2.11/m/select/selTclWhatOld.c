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
 * selTclWhatOld.c -- keep old sel_what command intact here.
 *                    To be rendered OBSOLETE by sel_what_*_l commands.
 *                    TODO: replace by wrapper.
 */

static char rcsid[] = "$Header$";

#include <stdio.h>
#include <limits.h>
#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "database.h"
#include "select.h"
#include "selInt.h"
#include "units.h"
#include "geometry.h"
#include "commands.h"

/* used to implement -limit options to sel_what */
static int selCountMax;
static int selCount; 

/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatCellsFunc --
 *
 * Search function invoked for each cell in the selection.
 *
 *--------------------------------------------------------------
 */
    /*ARGSUSED*/
static unsigned selTclWindowMask;
static int
selTclCmdWhatCellsFunc(CellUse *selUse, 
			CellUse *realUse, 
			Transform *trans, 
			TerminalPath *tPath,
			Tcl_Interp *interp)
{

  /* separate cells in result with newlines */
  if(interp->result && interp->result[0]!='\0') Tcl_AppendResult(interp,"\n",NULL);

  /* output instance name */
  Tcl_AppendElement(interp,realUse->cu_id);

  /* output cellname */
  Tcl_AppendElement(interp,realUse->cu_def->cd_name);

  /* output bbox in rootcell user coords ( = Select cell coords) */
  {
    Rect *bbox = DBBBoxCellUseNoUp(selUse);

    Tcl_AppendElement(interp, UnitsI2S(bbox->r_xbot));
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_ytop));
  }

  /* output path to instance */
  Tcl_AppendElement(interp, tPath->tp_first); 

  /* output expansion status */
  Tcl_AppendElement(interp, DBIsExpand(realUse, selTclWindowMask)? "expanded":"");

  /* output transform from instance to root coordinates */
  {
    char c[100];
    char f[100];
    char buf[1000];

    strcpy(c,UnitsI2S(trans->t_c));
    strcpy(f,UnitsI2S(trans->t_f));
    sprintf(buf," {%d %d %s %d %d %s} ",
	    trans->t_a,
	    trans->t_b,
	    c,
	    trans->t_d,
	    trans->t_e,
	    f);

    Tcl_AppendResult(interp, buf, NULL);
  }

  /* output array info */
  if(!DBIsArray(realUse))
  {
    Tcl_AppendElement(interp,"");
  }
  else
  {
    ArrayInfo ar;
    char xsep[100];
    char ysep[100];
    char buf[1000];

    /* convert array info to rootcell */
    DBArrayTransformInfo(trans, &realUse->cu_array, &ar);
    
    strcpy(xsep,UnitsI2S(ar.ar_xsep));
    strcpy(ysep,UnitsI2S(ar.ar_ysep));
    sprintf(buf," {%d %d %d %d %s %s} ",
	    ar.ar_xlo, 
	    ar.ar_xhi, 
	    ar.ar_ylo, 
	    ar.ar_yhi, 
	    xsep, 
	    ysep); 
    
    Tcl_AppendResult(interp, buf, NULL);
  }
    
  /* return of 0 continues search, 1 aborts search */
  if(++selCount >= selCountMax) return 1;
  return 0;
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatCells --
 *
 *      Implements cells subcommand of sel_what
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
static void 
selTclCmdWhatCells(Tcl_Interp *interp, int argc, char **argv)
{
    int i;
    TerminalPath tPath;
    char tPathBuf[4096];
    TerminalPath tPath2;
    char tPathBuf2[4096];
    int limit = INT_MAX;
    bool editOnly = FALSE;
    bool boolean = FALSE;  /* if set just determine if any cells 
			    * are selected 
			    */ 
    char *nonEditFoundVar = NULL;
    bool foundNonEdit;

    
    /*  skip 'sel_what cells' */
    argv += 2;
    argc -= 2;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='b' && strncmp(*argv,"-boolean",length)==0)
      {
	argc--; argv++;
	boolean = TRUE;

	continue;
      }

      if(c=='e' && strncmp(*argv,"-edit_only",length)==0)
      {
	argc--; argv++;
	editOnly = TRUE;
      
	if(!argc) goto usage;
	nonEditFoundVar = *argv;
	argc--; argv++;

	continue;
      }
	
      if(c=='l' && strncmp(*argv,"-limit",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	limit = atoi(*argv);
	argc--; argv++;
	
	continue;
      }

      /* unrecognized option */
      goto usage;

    } /* end while(argc>0 && **argv=='-')  */

    if(argc!=0) goto usage;

    /* if -boolean, just check if selection contains any instances */
    if(boolean)
    {
      Tcl_SetResult(interp, 
		    SelectUse->cu_def->cd_kids ? "1" :"0", 
		    TCL_STATIC);
      return;
    }

    /* set window mask to mask for current layout window */
    selTclWindowMask = LayCurWindow()->lay_bitmask;

    /* Initialize pathname(s) to Null,
     * need two since SelEnumCells can have a tentative match 
     * (select id doesn't math real id) and continue searching
     * for a better match.
     */
    tPathBuf[0] = '\0';
    tPath.tp_next = tPath.tp_first = tPathBuf;
    tPath.tp_last = &tPathBuf[sizeof tPathBuf - 2];
    tPathBuf2[0] = '\0';
    tPath2.tp_next = tPath2.tp_first = tPathBuf2;
    tPath2.tp_last = &tPathBuf2[sizeof tPathBuf2 - 2];

    /* setup result limit */
    selCountMax = limit;
    selCount = 0;

    /* visit each selected instance and spit it out! */
    (void) SelEnumCells(editOnly,
			&foundNonEdit, 
			(SearchContext *) NULL,  /* NULL = search everything */
			&tPath,
			&tPath2,
			selTclCmdWhatCellsFunc, 
			(ClientData) interp);

    /* set non_edit_found var */
    if(nonEditFoundVar && *nonEditFoundVar != '\0')
    {
        if(!Tcl_SetVar(interp,
		       nonEditFoundVar,
		       foundNonEdit ? "1" : "0", 
		       0)) /* warning:  TCL_LEAVE_ERR_MSG wipes result 
			    * if var is not preexisting.
			    */  
	{
	  MsgErrorF("%s\n"
		    "'sel_what cells' could not save into"
		    "non_edit_found_var_name %s\n",
		    interp->result,
		    nonEditFoundVar);
	}
    }
    return;

    usage:
    MsgErrorF("usage:  sel_what cells"
	      " [-boolean] [-edit_only non_edit_found_var_name] [-limit n]\n");

    return;
}

/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatLabelsFunc --
 *
 * helper func for selTclCmdWhat
 * 
 * Search function invoked for each label in the selection.
 *
 *--------------------------------------------------------------
 */
    /*ARGSUSED*/
static int
selTclCmdWhatLabelsFunc(Label *label, 
			CellDef *def, 
			Transform *trans, 
			TerminalPath *tPath,
			Tcl_Interp *interp)
{
 
  /* separate labels in result with newlines */
  if(interp->result && interp->result[0]!='\0') Tcl_AppendResult(interp,"\n",NULL);

  /* output label type longname */
  Tcl_AppendResult(interp,DBTypeLongName(label->lab_type), (char *) NULL);

  /* output rect in rootcell user coords */
  {
    Rect rootRect;
    GeoTransRect(trans, &(label->lab_rect), &rootRect);
    Tcl_AppendElement(interp, UnitsI2S(rootRect.r_xbot));
    Tcl_AppendElement(interp, UnitsI2S(rootRect.r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(rootRect.r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(rootRect.r_ytop));
  }

  /* output label position */
  {
    int rootPos = GeoTransPos(&EditToRootTransform, label->lab_pos);
    Tcl_AppendElement(interp, GeoPosToName(rootPos));
  }

  /* output label text */
  Tcl_AppendElement(interp, label->lab_text);

  /* output path */
  Tcl_AppendElement(interp, tPath->tp_first);

  /* output  group */
  Tcl_AppendElement(interp, label->lab_group?label->lab_group->g_name:"0");

  /* output kind */
  Tcl_AppendElement(interp, DBLabelKindName(label->lab_kind));

  /* return of 0 continues search, 1 aborts search */
  if(++selCount >= selCountMax) return 1;
  return 0;
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatLabels --
 *
 *      Implements labels subcommand of sel_what
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
static void 
selTclCmdWhatLabels(Tcl_Interp *interp, int argc, char **argv)
{
    int i;
    char nameBuf[4096];
    TerminalPath tPath;
    int limit = INT_MAX;
    bool editOnly = FALSE;
    bool foundNonEdit;
    char *nonEditFoundVar = NULL;

    /*  skip 'sel_what labels' */
    argv += 2;
    argc -= 2;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='e' && strncmp(*argv,"-edit_only",length)==0)
      {
	argc--; argv++;
	editOnly = TRUE;
      
	if(!argc) goto usage;
	nonEditFoundVar = *argv;
	argc--; argv++;

	continue;
      }
	
      if(c=='l' && strncmp(*argv,"-limit",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	limit = atoi(*argv);
	argc--; argv++;
	
	continue;
      }

      /* unrecognized option */
      goto usage;

    } /* end while(argc>0 && **argv=='-')  */

    /* should be no args left */
    if(argc!=0) goto usage;

    /* Initialize pathname to Null */
    nameBuf[0] = '\0';
    tPath.tp_next = tPath.tp_first = nameBuf;
    tPath.tp_last = &nameBuf[sizeof nameBuf - 2];

    /* setup result limit */
    selCountMax = limit;
    selCount = 0;

    /* visit each label and spit it out! */
    (void) SelEnumLabelsAll(&DBAllTypeBits, 
			editOnly, 
			&foundNonEdit,
			&tPath,
			selTclCmdWhatLabelsFunc, 
			(ClientData) interp);

    /* set non_edit_found var */
    if(nonEditFoundVar && *nonEditFoundVar != '\0')
    {
        if(!Tcl_SetVar(interp,
		       nonEditFoundVar,
		       foundNonEdit ? "1" : "0", 
		       0)) /* warning:  TCL_LEAVE_ERR_MSG wipes result 
			    * if var is not preexisting.
			    */  
	{
	  MsgErrorF("%s\n"
		    "'sel_what cells' could not save into"
		    "non_edit_found_var_name %s\n",
		    interp->result,
		    nonEditFoundVar);
	}
    }

    return;

    usage:
    MsgErrorF("usage:  sel_what labels [-edit_only non_edit_found_var_name]\n");
    return;
}

/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatPaintFunc --
 *
 * helper func for selTclCmdWhat
 * 
 * Search function invoked for each paint tile in the selection:
 * just set a bit in a tile type mask.
 *
 *--------------------------------------------------------------
 */
    /*ARGSUSED*/
static int
selTclCmdWhatPaintFunc(Rect *rect, TileType type, Tcl_Interp *interp)
{
  /* separate rects in result with newlines */
  if(interp->result && interp->result[0]!='\0') Tcl_AppendResult(interp,"\n",NULL);

  /* add rect to result */
  Tcl_AppendResult(interp, DBTypeLongName(type), NULL);
  Tcl_AppendElement(interp, UnitsI2S(rect->r_xbot));
  Tcl_AppendElement(interp, UnitsI2S(rect->r_ybot));
  Tcl_AppendElement(interp, UnitsI2S(rect->r_xtop));
  Tcl_AppendElement(interp, UnitsI2S(rect->r_ytop));

  /* return of 0 continues search, 1 aborts search */
  if(++selCount >= selCountMax) return 1;
  return 0;
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatPaint --
 *
 *      Implements types subcommand of sel_what
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
static void 
selTclCmdWhatPaint(Tcl_Interp *interp, int argc, char **argv)
{
    int i;
    bool editOnly = FALSE;
    int limit = INT_MAX;
    bool foundNonEdit;
    char *nonEditFoundVar = NULL;

    /*  skip 'sel_what cells' */
    argv += 2;
    argc -= 2;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='e' && strncmp(*argv,"-edit_only",length)==0)
      {
	argc--; argv++;
	editOnly = TRUE;
      
	if(!argc) goto usage;
	nonEditFoundVar = *argv;
	argc--; argv++;

	continue;
      }
	
      if(c=='l' && strncmp(*argv,"-limit",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	limit = atoi(*argv);
	argc--; argv++;
	
	continue;
      }

      /* unrecognized option */
      goto usage;

    } /* end while(argc>0 && **argv=='-')  */

    /* should be no args left */
    if(argc!=0) goto usage;

    /* setup result limit */
    selCountMax = limit;
    selCount = 0;

    /* visit each rect and spit it out! */
    (void) SelEnumPaint(&DBAllButSpaceAndDRCBits, 
			editOnly, 
			(bool *) &foundNonEdit,
			selTclCmdWhatPaintFunc, 
			NULL, 
			NULL, 
			(ClientData) interp);

    /* set non_edit_found var */
    if(nonEditFoundVar && *nonEditFoundVar != '\0')
    {
        if(!Tcl_SetVar(interp,
		       nonEditFoundVar,
		       foundNonEdit ? "1" : "0", 
		       0)) /* warning:  TCL_LEAVE_ERR_MSG wipes result 
			    * if var is not preexisting.
			    */  

	{
	  MsgErrorF("%s\n"
		    "'sel_what cells' could not save into"
		    "non_edit_found_var_name %s\n",
		    interp->result,
		    nonEditFoundVar);
	}
    }
    return;

    usage:
    MsgErrorF("usage:  %s %s [-edit_only non_edit_found_var_name] [-limit n]\n",argv[0], argv[1]);
    return;
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatPolygons --
 *
 *      Implements polygons subcommand of sel_what
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
static void 
selTclCmdWhatPolygons(Tcl_Interp *interp, int argc, char **argv)
{
    int limit = INT_MAX;
    int count = 0;

    /*  skip 'sel_what cells' */
    argv += 2;
    argc -= 2;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='l' && strncmp(*argv,"-limit",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	limit = atoi(*argv);
	argc--; argv++;
	
	continue;
      }

      /* unrecognized option */
      goto usage;

    } /* end while(argc>0 && **argv=='-')  */

    /* list polygons in selection */
    {
      Polygon *poly;

      for(poly = SelectDef->cd_polygons;
	  poly;
	  poly = poly->poly_next)
      {
	int i;
	PointFloat *p;

	/* type */
	Tcl_AppendElement(interp, DBTypeLongName(poly->poly_type));

	/* bbox */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	Tcl_AppendElement(interp, UnitsI2S(poly->poly_bbox.r_xbot));
	Tcl_AppendElement(interp, UnitsI2S(poly->poly_bbox.r_ybot));
	Tcl_AppendElement(interp, UnitsI2S(poly->poly_bbox.r_xtop));
	Tcl_AppendElement(interp, UnitsI2S(poly->poly_bbox.r_ytop));
	Tcl_AppendResult(interp, "}", (char *) NULL);

	/* points */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	p = poly->poly_points;
        for(i=0; i< poly->poly_size; i++)
	{
	  Tcl_AppendElement(interp, UnitsF2S(p->pf_x));
	  Tcl_AppendElement(interp, UnitsF2S(p->pf_y));
	  p++;
	}
	Tcl_AppendResult(interp, "}", (char *) NULL);


	/* attributes */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	if(poly->poly_wirePath)	Tcl_AppendResult(interp, "dependent", (char *) NULL);
	Tcl_AppendResult(interp, "}", (char *) NULL);


	Tcl_AppendResult(interp,"\n", (char *) NULL);

	/* output no more than limit polygons */
	if(++count >= limit) break;
      }
    }

    return;

    usage:
    MsgErrorF("usage:  %s %s [-limit n]\n",argv[0], argv[1]);
    return;
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatTypes --
 *
 *      Implements types subcommand of sel_what
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

/* helper func */
static int
selTclCmdWhatTypesPaintFunc(Rect *rect, 
               			/* Not used. */
			    TileType type, 
                  		/* Type of this piece of paint. */
			    ClientData notUsed)
{
    return 1;
}

/* helper func */
static int
selTclCmdWhatTypesPolygonFunc(Polygon *poly, 
			      SearchContext *scx, 
			      ClientData notUsed) 
{
    return 1;
}

/* helper func */
static int
selTclCmdWhatTypesWirePathFunc(WirePath *wp, 
			      SearchContext *scx, 
			      ClientData notUsed)
{
    return 1;
}

static void 
selTclCmdWhatTypes(Tcl_Interp *interp, int argc, char **argv)
{
    int i, first;
    static TileTypeBitMask layers;
    static VStamp layersStamp = {0,0};
      
    /* check arg count */
    if (argc != 2) 
    {
         MsgErrorF("usage:  %s %s\n",argv[0], argv[1]);
         return;
    }

    if(!SelectDef) return;
  
    /* if layers no longer valid, recompute */
    DBUpdate(SelectDef);
    if(!DBVStampSame(&SelectDef->cd_vMAIN,&layersStamp))
    {
      layersStamp = SelectDef->cd_vMAIN;

      TTMaskZero(&layers);

      for(i = TT_SELECTBASE; i< DBNumUserLayers; i++)
      {
	bool found;
	TileTypeBitMask mask;

	TTMaskSetOnlyType(&mask, i);
	found = SelEnumPaint(&mask,
			     FALSE, 
			     (bool *) NULL,
			     selTclCmdWhatTypesPaintFunc, 
			     selTclCmdWhatTypesPolygonFunc, 
			     selTclCmdWhatTypesWirePathFunc, 
			     (ClientData) NULL);

	if(found) TTMaskSetType(&layers,i);
      }
    }

    /* spit out the layer names */
    first = TRUE;
    for (i = TT_SELECTBASE; i < DBNumUserLayers; i++)
    {
      if (TTMaskHasType(&layers, i)) 
      {
	if(!first) 
	{
	  Tcl_AppendResult(interp, " ", DBTypeLongName(i), NULL);	
	}
	else
	{
	  Tcl_AppendResult(interp, DBTypeLongName(i), NULL);	
	  first = FALSE;
	}
      }
    }
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhat --
 *
 *      Implements sel_what command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_what_DESC   "get info on selection OLD VERSION OF sel_what RESTORED FOR DEBUG ONLY"

#define sel_what_DOC "
usage: sel_what subcommand [args]

Subcommands:
    cells [-boolean] [-edit_only non_edit_found_var_name] [-limit n]
        if -boolean, returns boolean indicating whether selection
        includes any instances.

        Otherwise, lists all instances in selection: 
        \"instanceName defName xbot ybot xtop ytop path expansion transform arrayInfo\"

        (rootcell coordinates)
        xbot ybot xtop ytop = bounding box
        expansion = 'expanded' if internals visible, else {} (null list) 
        transform = {a b c d e f}  (first two columns of 3x3 transform matrix
                                    last column is {0 0 1})
        arrayInfo = {xlo xhi ylo yhi xsep ysep} (or NULL if not array)
          See db_search documentation for further notes on arrayInfo.  

        If -limit n, output is limited to n matchs.

    labels [-edit_only non_edit_found_var_name] [-limit n] 
        lists selected labels: 
        form:  \"layer xbot ybot xtop ytop pos text path group kind\"
        (rootcell coordinates)

        If -limit n, output is limited to n matchs.

    paint [-edit_only non_edit_found_var_name] [-limit n]
        lists selected rectangles: \"layer xbot ybot xtop ytop\"
        (rootcell coordinates)

        If -limit n, output is limited to n matchs.

    polygons [-limit n]
        lists selected polygons:
        form:  \"layer bbox coordinates attributes\"
        coodinates = x0 y0 x1 y1 ...
        attribute of \"dependent\" means polygon is part of a wire path. 
        (rootcell coordinates)

        If -limit n, output is limited to n matchs.

    types
        lists names of types (layers) in selection.

-edit_only flag:

if -edit_only flag given, only selected objects in the edit cell are listed.
if non_edit_found_var_name is not {}, that var is set to 1 if the
selection includes non-edit-cell objects of the type being queried, 
to 0 otherwise. 

"

static int
selTclCmdWhat(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  int length;
  char *subcmd,c;

  CMD_BEGIN(interp);

  /* get subcmd */
  if (argc < 2) goto usage;
  subcmd = argv[1];

  /* do subcmd */
  c = subcmd[0];
  length =strlen(subcmd);
  if(c=='c' && strncmp(subcmd,"cells",length)==0) 
  {
    selTclCmdWhatCells(interp,argc,argv);
  }
  else if(c=='l' && strncmp(subcmd,"labels",length)==0) 
  {
    selTclCmdWhatLabels(interp,argc,argv);
  }
  else if(c=='p' && strncmp(subcmd,"paint",MAX(length,2))==0) 
  {
    selTclCmdWhatPaint(interp,argc,argv);
  }
  else if(c=='p' && strncmp(subcmd,"polygons",MAX(length,2))==0) 
  {
    selTclCmdWhatPolygons(interp,argc,argv);
  }
  else if(c=='t' && strncmp(subcmd,"types",length)==0) 
  {
    selTclCmdWhatTypes(interp,argc,argv);
  }
  else
  {
    goto usage;
  }

  CMD_RETURN(interp);	  

 usage:
  MsgErrorF(
	    "usage:  %s subcmd [args]\n"
	    "\tWhere subcmd is \"cells\", \"labels\", \"paint\", \"polygons\" or \"types\"\n",
	    argv[0]);
  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * selTclWhatOldInit --
 *
 * Initialize tcl commands for this file.
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
selTclWhatOldInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "sel_what_old", selTclCmdWhat,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_DESC,
	       sel_what_DOC);
}

