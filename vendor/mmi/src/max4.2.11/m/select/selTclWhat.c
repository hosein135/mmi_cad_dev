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
 * selTclWhat.c -- implements sel_what_* commands 
 *                 (selection enumeration routines)
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

/* used to build up results */
static Tcl_Obj *selResult;


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatCellsL --
 *
 *      Implements sel_what_cells command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_what_cells_DESC   "list currently selected instances"

#define sel_what_cells_DOC "
usage: sel_what_cells [-boolean] [-edit_only non_edit_found_var_name] [-limit n]

If -boolean, returns boolean indicating whether selection
includes any instances.

Otherwise, lists of all instances in selection: 
        \"instanceName defName xbot ybot xtop ytop path expansion transform arrayInfo\"

        (rootcell coordinates)
        xbot ybot xtop ytop = bounding box
        expansion = 'expanded' if internals visible, else {} (null list) 
        transform = {a b c d e f}  (first two columns of 3x3 transform matrix
                                    last column is {0 0 1})
        arrayInfo = {xlo xhi ylo yhi xsep ysep} (or NULL if not array)
          See db_search documentation for further notes on arrayInfo.  

If -limit n, output is limited to n matchs.

If -edit_only, only selected objects in the edit cell are listed.
if non_edit_found_var_name is not {}, that var is set to 1 if the
selection includes non-edit-cell objects of the type being queried, 
to 0 otherwise. 

NOTE: Returns tcl list object:  no new-lines!
"

/* helper func */
static unsigned selTclWindowMask;
static int
selTclCmdWhatCellsLFunc(CellUse *selUse, 
			CellUse *realUse, 
			Transform *trans, 
			TerminalPath *tPath,
			Tcl_Interp *interp)
{
  Tcl_Obj *l = Tcl_NewListObj(0,0);

  /* output instance name */
  TListAppendStr(interp, l, realUse->cu_id);

  /* output cellname */
  TListAppendStr(interp, l, realUse->cu_def->cd_name);

  /* output bbox in rootcell user coords ( = Select cell coords) */
  {
    Rect *bbox = DBBBoxCellUseNoUp(selUse);

    TListAppendDouble(interp, l, UnitsI2D(bbox->r_xbot));
    TListAppendDouble(interp, l, UnitsI2D(bbox->r_ybot));
    TListAppendDouble(interp, l, UnitsI2D(bbox->r_xtop));
    TListAppendDouble(interp, l, UnitsI2D(bbox->r_ytop));
  }

  /* output path to instance */
  TListAppendStr(interp, l, tPath->tp_first); 

  /* output expansion status */
  TListAppendStr(interp, l, 
		 DBIsExpand(realUse, selTclWindowMask)? "expanded":"");

  /* output transform from instance to root coordinates */
  {
    Tcl_Obj *lt = Tcl_NewListObj(0,0);

    TListAppendInt(interp, lt, trans->t_a);
    TListAppendInt(interp, lt, trans->t_b);
    TListAppendDouble(interp, lt, UnitsI2D(trans->t_c));
    TListAppendInt(interp, lt, trans->t_d);
    TListAppendInt(interp, lt, trans->t_e);
    TListAppendDouble(interp, lt, UnitsI2D(trans->t_f));

    TListAppendObj(interp, l, lt);
  }

  /* output array info */
  if(!DBIsArray(realUse))
  {
    TListAppendStr(interp, l, "");
  }
  else
  {
    ArrayInfo ar;

    Tcl_Obj *la = Tcl_NewListObj(0,0);

    /* convert array info to rootcell */
    DBArrayTransformInfo(trans, &realUse->cu_array, &ar);

    TListAppendInt(interp, la, ar.ar_xlo);
    TListAppendInt(interp, la, ar.ar_xhi);
    TListAppendInt(interp, la, ar.ar_ylo);
    TListAppendInt(interp, la, ar.ar_yhi);
    TListAppendDouble(interp, la, UnitsI2D(ar.ar_xsep));
    TListAppendDouble(interp, la, UnitsI2D(ar.ar_ysep));

    TListAppendObj(interp, l, la);
  }
    
  /* add to result */
  TListAppendObj(interp, selResult, l);

  /* return of 0 continues search, 1 aborts search */
  if(++selCount >= selCountMax) return 1;
  return 0;
}

static int
selTclCmdWhatCellsL(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
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
    CMD_RETURN(interp);
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

  /* gen selected cells list */
  selResult =  Tcl_NewListObj(0,0);
  (void) SelEnumCells(editOnly,
		      &foundNonEdit, 
		      (SearchContext *) NULL,  /* NULL = search everything */
		      &tPath,
		      &tPath2,
		      selTclCmdWhatCellsLFunc, 
		      (ClientData) interp);

  /* set non_edit_found var */
  if(nonEditFoundVar && *nonEditFoundVar != '\0')
  {
    if(!Tcl_SetVar(interp,
		   nonEditFoundVar,
		   foundNonEdit ? "1" : "0", 
		   TCL_LEAVE_ERR_MSG))
    {
      MsgErrorF("%s\n"
		"'%s' could not save into"
		"non_edit_found_var_name %s\n",
		interp->result,
		cmdName,
		nonEditFoundVar);
    }
  }
  
  /* return result */
  Tcl_SetObjResult(interp,selResult);
  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s"
	    " [-boolean] [-edit_only non_edit_found_var_name] [-limit n]\n",
	    cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatLabelsL --
 *
 *      Implements sel_what_labels
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_what_labels_DESC "list labels in current selection"
#define sel_what_labels_DOC "
sel_what_labels [-edit_only non_edit_found_var_name] [-limit n] 

        lists selected labels: 
        form:  \"layer xbot ybot xtop ytop pos text path group kind\"
        (rootcell coordinates)

If -limit n, output is limited to n matchs.

if -edit_only, only selected objects in the edit cell are listed.
if non_edit_found_var_name is not {}, that var is set to 1 if the
selection includes non-edit-cell objects of the type being queried, 
to 0 otherwise. 

NOTE: Returns tcl list object:  no new-lines!
"

/* helper func */
static int
selTclCmdWhatLabelsLFunc(Label *label, 
			 CellDef *def, 
			 Transform *trans, 
			 TerminalPath *tPath,
			 Tcl_Interp *interp)
{
  Tcl_Obj *l = Tcl_NewListObj(0,0);

  /* output label type */
  TListAppendStr(interp, l, DBTypeLongName(label->lab_type));

  /* output rect in rootcell user coords */
  {
    Rect rootRect;
    GeoTransRect(trans, &label->lab_rect, &rootRect);

    TListAppendDouble(interp, l, UnitsI2D(rootRect.r_xbot));
    TListAppendDouble(interp, l, UnitsI2D(rootRect.r_ybot));
    TListAppendDouble(interp, l, UnitsI2D(rootRect.r_xtop));
    TListAppendDouble(interp, l, UnitsI2D(rootRect.r_ytop));
  }

  /* output label position */
  {
    int rootPos = GeoTransPos(&EditToRootTransform, label->lab_pos);
    TListAppendStr(interp, l, GeoPosToName(rootPos));
  }

  /* output label text */
  TListAppendStr(interp, l, label->lab_text);

  /* output path */
  TListAppendStr(interp, l, tPath->tp_first);

  /* output  group */
  TListAppendStr(interp, l, label->lab_group?label->lab_group->g_name:"0");

  /* output kind */
  TListAppendStr(interp, l, DBLabelKindName(label->lab_kind));

  /* add to result */
  TListAppendObj(interp, selResult, l);

  /* return of 0 continues search, 1 aborts search */
  if(++selCount >= selCountMax) return 1;
  return 0;
}

static int
selTclCmdWhatLabelsL(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  int i;
  char nameBuf[4096];
  TerminalPath tPath;
  int limit = INT_MAX;
  bool editOnly = FALSE;
  bool foundNonEdit;
  char *nonEditFoundVar = NULL;
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

  /* gen selected labels list */
  selResult =  Tcl_NewListObj(0,0);
  (void) SelEnumLabelsAll(&DBAllTypeBits, 
			  editOnly, 
			  &foundNonEdit,
			  &tPath,
			  selTclCmdWhatLabelsLFunc, 
			  (ClientData) interp);

  /* set non_edit_found var */
  if(nonEditFoundVar && *nonEditFoundVar != '\0')
  {
    if(!Tcl_SetVar(interp,
		   nonEditFoundVar,
		   foundNonEdit ? "1" : "0", 
		   TCL_LEAVE_ERR_MSG)) 
    {
      MsgErrorF("%s\n"
		"'%s' could not save into"
		"non_edit_found_var_name %s\n",
		interp->result,
		cmdName,
		nonEditFoundVar);
    }
  }

  /* return result */
  Tcl_SetObjResult(interp,selResult);
  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s [-edit_only non_edit_found_var_name]\n",
	    cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatPaintL --
 *
 *      Implements sel_what_paint
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_what_paint_DESC   "list selected paint rectangles" 

#define sel_what_paint_DOC "
usage: sel_what_paint [-edit_only non_edit_found_var_name] [-limit n]

        lists selected rectangles: \"layer xbot ybot xtop ytop\"
        (rootcell coordinates)

If -limit n, output is limited to n matchs.

If -edit_only, only selected objects in the edit cell are listed.
if non_edit_found_var_name is not {}, that var is set to 1 if the
selection includes non-edit-cell objects of the type being queried, 
to 0 otherwise. 

NOTE: Returns tcl list object:  no new-lines!
"

/* helper func for selTclCmdWhatPaintL() */
static int
selTclCmdWhatPaintLFunc(Rect *rect, TileType type, Tcl_Interp *interp)
{
  Tcl_Obj *l = Tcl_NewListObj(0,0);

  /* build up this element */
  TListAppendStr(interp, l, DBTypeLongName(type));
  TListAppendDouble(interp, l, UnitsI2D(rect->r_xbot));
  TListAppendDouble(interp, l, UnitsI2D(rect->r_ybot));
  TListAppendDouble(interp, l, UnitsI2D(rect->r_xtop));
  TListAppendDouble(interp, l, UnitsI2D(rect->r_ytop));

  /* add to result */
  TListAppendObj(interp, selResult, l);

  /* return of 0 continues search, 1 aborts search */
  if(++selCount >= selCountMax) return 1;
  return 0;
}

static int
selTclCmdWhatPaintL(ClientData clientData,
		       Tcl_Interp *interp, 
		       int argc, 
		       char **argv)
{
  int i;
  bool editOnly = FALSE;
  int limit = INT_MAX;
  bool foundNonEdit;
  char *nonEditFoundVar = NULL;
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

  /* gen selected paint list */
  selResult =  Tcl_NewListObj(0,0);
  (void) SelEnumPaint(&DBAllButSpaceAndDRCBits, 
		      editOnly, 
		      (bool *) &foundNonEdit,
		      selTclCmdWhatPaintLFunc, 
		      NULL, 
		      NULL, 
		      (ClientData) interp);
  
  /* set non_edit_found var */
  if(nonEditFoundVar && *nonEditFoundVar != '\0')
  {
    if(!Tcl_SetVar(interp,
		   nonEditFoundVar,
		   foundNonEdit ? "1" : "0", 
		   TCL_LEAVE_ERR_MSG))
    {
      MsgErrorF("%s\n"
		"'%s' could not save into"
		"non_edit_found_var_name %s\n",
		interp->result,
		
		nonEditFoundVar);
    }
  }

  /* return result */
  Tcl_SetObjResult(interp,selResult);
  CMD_RETURN(interp);
  
 usage:
  MsgErrorF("usage:  %s [-edit_only non_edit_found_var_name] [-limit n]\n",
	    cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatPolygonsL --
 *
 *      Implements sel_what_polygons
 *
 *--------------------------------------------------------------
 */
#define sel_what_polygons_DESC   "list polygons in selection"

#define sel_what_polygons_DOC "
usage: sel_what_polygons [-limit n]

lists selected polygons:
        form:  \"layer bbox coordinates attributes\"
        coodinates = x0 y0 x1 y1 ...
        attribute of \"dependent\" means polygon is part of a wire path. 
        (rootcell coordinates)

If -limit n, output is limited to n matchs.

NOTE: Returns tcl list object:  no new-lines!
"
static int
selTclCmdWhatPolygonsL(ClientData clientData,
		       Tcl_Interp *interp, 
		       int argc, 
		       char **argv)
{
  int limit = INT_MAX;
  int count = 0;
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
  if(argc>0) goto usage;

  /* list polygons in selection */
  {
    Polygon *poly;
    Tcl_Obj *result = Tcl_NewListObj(0,0);

    for(poly = SelectDef->cd_polygons;
	poly;
	poly = poly->poly_next)
    {
      int i;
      PointFloat *p;
      Tcl_Obj *lpoly = Tcl_NewListObj(0,0);

      /* type */
      TListAppendStr(interp, lpoly, DBTypeLongName(poly->poly_type));

      /* bbox */
      {
	Tcl_Obj *lbbox = Tcl_NewListObj(0,0);
	
	TListAppendDouble(interp, lbbox, UnitsI2D(poly->poly_bbox.r_xbot));
	TListAppendDouble(interp, lbbox, UnitsI2D(poly->poly_bbox.r_ybot));
	TListAppendDouble(interp, lbbox, UnitsI2D(poly->poly_bbox.r_xtop));
	TListAppendDouble(interp, lbbox, UnitsI2D(poly->poly_bbox.r_ytop));
	
	TListAppendObj(interp, lpoly, lbbox);
      }

      /* points */
      {
	Tcl_Obj *lpoints = Tcl_NewListObj(0,0);

	p = poly->poly_points;
	for(i=0; i< poly->poly_size; i++)
        {
	  TListAppendDouble(interp, lpoints, UnitsF2D(p->pf_x));
	  TListAppendDouble(interp, lpoints, UnitsF2D(p->pf_y));
	  p++;
	}

	TListAppendObj(interp, lpoly, lpoints);
      }

      /* attributes */
      {
	Tcl_Obj *lat = Tcl_NewListObj(0,0);

	if(poly->poly_wirePath) TListAppendStr(interp, lat, "dependent");

	TListAppendObj(interp, lpoly, lat);
      }

      TListAppendObj(interp, result, lpoly);

      /* output no more than limit polygons */
      if(++count >= limit) break;
    }

    Tcl_SetObjResult(interp,result);
  }

  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s [-limit n]\n",cmdName);
  CMD_RETURN(interp);;
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhatTypesL --
 *
 *      Implements sel_what_types command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_what_types_DESC   "list layers in current selection."
#define sel_what_types_DOC ""

/* helper func */
static int
selTclCmdWhatTypesLPaintFunc(Rect *rect, 
               			/* Not used. */
			    TileType type, 
                  		/* Type of this piece of paint. */
			    ClientData notUsed)
{
    return 1;
}

/* helper func */
static int
selTclCmdWhatTypesLPolygonFunc(Polygon *poly, 
			      SearchContext *scx, 
			      ClientData notUsed) 
{
    return 1;
}

/* helper func */
static int
selTclCmdWhatTypesLWirePathFunc(WirePath *wp, 
			      SearchContext *scx, 
			      ClientData notUsed)
{
    return 1;
}

static int
selTclCmdWhatTypesL(ClientData clientData, 
		    Tcl_Interp *interp, 
		    int argc, 
		    char **argv)
{
  int i, first;
  static TileTypeBitMask layers;
  static VStamp layersStamp = {0,0};
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

    /* no switches yet 
    if(c=='a' && strncmp(*argv,"-any_cell",length)==0)
    {
      argc--; argv++;
      anyCell = TRUE;
      continue;
    }
    */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* should be no arguments left */
  if(argc>0) goto usage;

  if(!SelectDef) CMD_RETURN(interp);
  
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
			   selTclCmdWhatTypesLPaintFunc, 
			   selTclCmdWhatTypesLWirePathFunc, 
			   selTclCmdWhatTypesLPolygonFunc, 
			   (ClientData) NULL);

      if(found) TTMaskSetType(&layers,i);
    }
  }

  /* spit out the layer names */
  {
    Tcl_Obj *result = Tcl_NewListObj(0,0);

    for (i = TT_SELECTBASE; i < DBNumUserLayers; i++)
    {
      if (TTMaskHasType(&layers, i)) 
      {
	TListAppendStr(interp, result, DBTypeLongName(i));
      }
    }
    Tcl_SetObjResult(interp,result);
  }
  CMD_RETURN(interp);

usage:
  MsgErrorF("usage:  %s\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdWhat --
 *
 *      reimplements sel_what command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_what_DESC   "get info on selection (OBSOLETE)"

#define sel_what_DOC "
usage: sel_what subcommand [args]

OBSOLETE AND INEFFICIENT:  please use sel_what_* commands instead!

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
  char *cmdName;
  char *subCmd;
  Tcl_DString script;

  CMD_BEGIN(interp);

  /* get cmd name */
  cmdName = *argv;
  argc--;argv++;

  /* get sub command */
  if(!argc) 
  {
    MsgErrorF("wrong # args: should be \"%s sub_command [arg arg ...]\"",
	      cmdName);
    CMD_RETURN(interp);
  }
  subCmd = *argv;
  argc--; argv++;

  /* build script */
  if(strncmp("types",subCmd,strlen(subCmd))==0)
  {
    /* special case 'sel_what types' */

    Tcl_DStringInit(&script);

    /* command */
    Tcl_DStringAppend(&script, "sel_what_types", -1);

    /* args */
    while(argc)
    {
      Tcl_DStringAppendElement(&script, *argv);
      argc--;argv++;
    }

    /* suffix */
    Tcl_DStringAppend(&script,"\n", -1);
  }
  else   
  {
    Tcl_DStringInit(&script);

    /* prefix */
    Tcl_DStringAppend(&script, "join [sel_what_", -1);

    /* subcommand */
    Tcl_DStringAppend(&script, subCmd, -1);

    /* args */
    while(argc)
    {
      Tcl_DStringAppendElement(&script, *argv);
      argc--;argv++;
    }

    /* suffix */
    Tcl_DStringAppend(&script,"] \"\\n\" \n", -1);
  }

  /* run the script */
  if(Tcl_Eval(interp,Tcl_DStringValue(&script))!=TCL_OK)
  {
    MsgErrorF("%s",Tcl_GetStringResult(interp));
  }

  /* clean up */
  Tcl_DStringFree(&script);

  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * selTclWhatInit --
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
selTclWhatInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "sel_what_cells", selTclCmdWhatCellsL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_cells_DESC,
	       sel_what_cells_DOC);
   MnDocCreateCommand(interp, "sel_what_labels", selTclCmdWhatLabelsL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_labels_DESC,
	       sel_what_labels_DOC);
   MnDocCreateCommand(interp, "sel_what_paint", selTclCmdWhatPaintL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_paint_DESC,
	       sel_what_paint_DOC);
   MnDocCreateCommand(interp, "sel_what_polygons", selTclCmdWhatPolygonsL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_polygons_DESC,
	       sel_what_polygons_DOC);
   MnDocCreateCommand(interp, "sel_what_types", selTclCmdWhatTypesL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_types_DESC,
	       sel_what_types_DOC);
   MnDocCreateCommand(interp, "sel_what", selTclCmdWhat,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_what_DESC,
	       sel_what_DOC);
}

