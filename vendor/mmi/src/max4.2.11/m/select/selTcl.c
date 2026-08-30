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
 * selTcl.c -- Tcl command interface to select module.
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


/*
 *--------------------------------------------------------------
 *
 * selTclCmdArea --
 *
 *      Implements sel_area command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define sel_area_DESC   "select given area"

#define sel_area_DOC "
usage: sel_area [options] xbot ybot xtop ytop

Options:
-any_cell
    don't restrict selection to edit cell.
    consider any cell in window with internals displayed

-group 
    restrict selection to active group only

-layers
    select paint on given layers only

-less
    removing matching paint from selection!

-more
    don't clear selection first

-no_labels
    don't select labels.
    if not set, labels attached to selected paint are 
    selected or if -layers option includes 'labels' all 
    labels are selected.
    NOTE: currently not implemented for -less case. 

-no_poly
    don't select polygons
    NOTE: currently not implemented for -less case. 

-no_tiles
    don't select paint tiles
    NOTE: currently not implemented for -less case. 

-no_wp
    don't select wire paths.
    NOTE: currently not implemented for -less case. 
"

static int
selTclCmdArea(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  bool anyCell = FALSE;
  bool group = FALSE;
  char *layers = "*,label,subcell";  /* default to ALL layers */
  bool less = FALSE;
  bool more = FALSE;
  bool noLabels = FALSE;
  bool noPoly = FALSE;
  bool noTiles = FALSE;
  bool noWP = FALSE;
  Rect rect;

  SearchContext scx;
  TileTypeBitMask layerMask;
  CellUse *noTreeRootUse = NULL; /* null for tree search, 
				  * rootUse if searching just one cell
				  * the cell itself is indicated in
				  * scx
				  */
  Layout *w = LayCurWindow();

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='a' && strncmp(*argv,"-any_cell",length)==0)
    {
      argc--; argv++;
      anyCell = TRUE;
      continue;
    }

    if(c=='g' && strncmp(*argv,"-group",MAX(length,6))==0)
    {
      argc--; argv++;
      group = TRUE;
      continue;
    }

    if(c=='l' && strncmp(*argv,"-layers",MAX(length,3))==0)
    {
      argc--; argv++;
      if(argc==0) goto usage;
      layers = *argv;
      argc--; argv++;
      continue;
    }

    if(c=='l' && strncmp(*argv,"-less",MAX(length,3))==0)
    {
      argc--; argv++;
      less = TRUE;
      continue;
    }

    if((c=='m') && (strncmp(*argv,"-more",length) == 0)) 
    {
      argc--; argv++;
      more = TRUE;
      continue;
    }

    if((c=='n') && (strncmp(*argv,"-no_labels",MAX(length,5)) == 0)) 
    {
      argc--; argv++;
      noLabels = TRUE;
      continue;
    }

    if((c=='n') && (strncmp(*argv,"-no_poly",MAX(length,5)) == 0)) 
    {
      argc--; argv++;
      noPoly = TRUE;
      continue;
    }

    if((c=='n') && (strncmp(*argv,"-no_tiles",MAX(length,5)) == 0)) 
    {
      argc--; argv++;
      noTiles = TRUE;
      continue;
    }

    if((c=='n') && (strncmp(*argv,"-no_wp",MAX(length,5)) == 0)) 
    {
      argc--; argv++;
      noWP = TRUE;
      continue;
    }

    /* looks like a number not an option */
    if(isdigit(c)) break;

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  {
    Rect t;

    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ll.p_x = UnitsS2I(*argv);
    argc--; argv++;
    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ll.p_y = UnitsS2I(*argv);
    argc--; argv++;
    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ur.p_x = UnitsS2I(*argv);
    argc--; argv++;
    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ur.p_y = UnitsS2I(*argv);
    argc--; argv++;

    GeoCanonicalRect(&t, &rect);
    if(rect.r_xbot == rect.r_xtop) rect.r_xtop++;
    if(rect.r_ybot == rect.r_ytop) rect.r_ytop++;
  }

  /* should be no arguments left */
  if(argc>0) goto usage;

  /* start new selection */
  if(!(more || less)) SelectClear();

  /* parse layers */
  if (!CmdParseLayers(layers, &layerMask) || 
      TTMaskEqual(&layerMask, &DBSpaceBits))
  {
    CMD_RETURN(interp);
  }
  TTMaskClearType(&layerMask, TT_SPACE);

  /* set up scx */
  bzero(&scx, sizeof(SearchContext));
  if(anyCell)
  {
    scx.scx_use = w->lay_rootUse;
    scx.scx_trans = GeoIdentityTransform;    
    scx.scx_area = rect;
  }
  else
  {
    /* restrict search to edit cell */
    noTreeRootUse = w->lay_rootUse;
    if (noTreeRootUse->cu_def != EditRootDef)
    {
      MsgErrorF("Edit cell not rooted in current window.\n");
      CMD_RETURN(interp);
    }
    scx.scx_use = EditCellUse;
    scx.scx_trans = EditToRootTransform;
    GeoTransRect(&RootToEditTransform, &rect, &scx.scx_area);
  }

  /* do the deed */
  if (less)
  {
    if(noLabels) 
    {
      MsgErrorF("%s:  -no_labels currently not implemented for -less\n",
		cmdName);
      CMD_RETURN(interp);
    }

    if(noPoly) 
    {
      MsgErrorF("%s:  -no_poly currently not implemented for -less\n",
		cmdName);
      CMD_RETURN(interp);
    }

    if(noTiles) 
    {
      MsgErrorF("%s:  -no_tiles currently not implemented for -less\n",
		cmdName);
      CMD_RETURN(interp);
    }

    if(noWP) 
    {
      MsgErrorF("%s:  -no_wp currently not implemented for -less\n",
		cmdName);
      CMD_RETURN(interp);
    }

    SelRemoveArea(&scx, 
		  &layerMask, 
		  w->lay_bitmask,
		  group,
		  noTreeRootUse);
  }
  else
  {
    int saFlags = 0;
    
    if(group) saFlags |= SA_GROUP;
    if(noLabels) saFlags |= SA_NO_LABELS;
    if(noPoly) saFlags |= SA_NO_POLY;
    if(noTiles) saFlags |= SA_NO_TILES;
    if(noWP) saFlags |= SA_NO_WP;

    SelectArea(&scx, 
	       &layerMask, 
	       w->lay_bitmask,
	       saFlags,
	       noTreeRootUse);
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s [options] xbot ybot xtop ytop\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdCell --
 *
 *      Implements sel_cell command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_cell_DESC   "select cell instance with given id"

#define sel_cell_DOC "
usage: sel_cell [-more | -less] name 

Options:
-less
    removes instance from selection!

-more
    don't clear selection first (add instance to selection)

The instance name can be a path, to reference an instance down the
cell hierarchy.  For example:  

  sel_cell Midcell_3/Lowcell_6/Inv_0  
"
static int
selTclCmdCell(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  Layout *w = LayCurWindow();
  char *id = NULL;
  bool less = FALSE;
  bool more = FALSE;

  SearchContext scx;
  Transform trans;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='l' && strncmp(*argv,"-less",length)==0)
    {
      argc--; argv++;
      less = TRUE;
      continue;
    }

    if(c=='m' && strncmp(*argv,"-more",length)==0)
    {
      argc--; argv++;
      more = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* id */
  if(argc==0) goto usage;
  id = *argv;
  argc--;argv++;

  /* should be no arguments left */
  if(argc>0) goto usage;

  /* start new selection */
  if(!(more || less)) SelectClear();

  bzero(&scx, sizeof(SearchContext));
  DBTreeFindUse(id, 
		w->lay_rootUse,
		&scx,  /* fill in with use */
		TRUE,  /* array subscripts optional */
		FALSE); /* load cells dynamically as required to complete */

  if (!scx.scx_use)
  {
    MsgErrorF("Couldn't find a cell use named \"%s\"\n",id);
    CMD_RETURN(interp);
  }

  /* The translation stuff is funny, since we got one
   * element of the array, but not necessarily the
   * lower-left element.  To get the transform for the
   * array as a whole, subtract off for the indx of
   * the element.
   */
  {
    Transform tmp;

    GeoInvertTrans(DBGetArrayTransform(scx.scx_use, scx.scx_x, scx.scx_y), &tmp);
    GeoTransTrans(&tmp, &scx.scx_trans, &trans);
  }

  /* (de)select the cell */
  if (less)
  {
    SelectRemoveCellUse(scx.scx_use, &trans);
  }
  else
  {
    SelectCell(scx.scx_use, EditRootDef, &trans, FALSE);
  }
  
  /* move box to bbox of use just (de)selected */
  {
    Rect r;

    GeoTransRect(&scx.scx_trans, 
		 DBBBoxCellDef(scx.scx_use->cu_def), 
		 &r);
    LaySetBox(w->lay_rootUse->cu_def, &r);
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s [-more | -less] name\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdChunk --
 *
 *      Implements sel_chunk command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_chunk_DESC   "selects largest rect of paint (and attached labels) on given layer and covering given area"

#define sel_chunk_DOC "
largest = fattest = maximum minimum dimension 
(secondarily, maximizes second dimension).

usage: sel_chunk [options] layer xbot ybot xtop ytop

Options:
-any_cell
    don't restrict selection to edit cell.
    consider any cell in window with internals displayed

-group 
    restrict selection to active group only

-less
    removes matching paint from selection!

-more
    don't clear selection first (add to selection)
"
static int
selTclCmdChunk(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  bool anyCell = FALSE;
  bool group = FALSE;
  bool less = FALSE;
  bool more = FALSE;

  TileType layer;
  Rect rect;

  SearchContext scx;
  Layout *w = LayCurWindow();
  CellUse *noTreeRootUse = NULL; /* null for tree search, 
				  * rootUse if searching just one cell
				  * the cell itself is indicated in
				  * scx
				  */
  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='a' && strncmp(*argv,"-any_cell",length)==0)
    {
      argc--; argv++;
      anyCell = TRUE;
      continue;
    }

    if(c=='g' && strncmp(*argv,"-group",MAX(length,6))==0)
    {
      argc--; argv++;
      group = TRUE;
      continue;
    }

    if(c=='l' && strncmp(*argv,"-less",length)==0)
    {
      MsgErrorF("%s:  '-less' option not yet implemented.\n",cmdName);
      CMD_RETURN(interp);

      argc--; argv++;
      less = TRUE;
      continue;
    }

    if((c=='m') && (strncmp(*argv,"-more",length) == 0)) 
    {
      argc--; argv++;
      more = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* layer arg */
  if(argc<1) goto usage;
  layer = DBTechNameType(*argv);
  if (layer < 0)
  {
    MsgErrorF("Unknown layer: %s\n", *argv);
    CMD_RETURN(interp);
  }
  if (layer == TT_SPACE)
  {
    MsgErrorF("%s not allowed on 'space'\n", cmdName);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  /* rect coordinate args */
  {
    Rect t;

    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ll.p_x = UnitsS2I(*argv);
    argc--; argv++;
    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ll.p_y = UnitsS2I(*argv);
    argc--; argv++;
    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ur.p_x = UnitsS2I(*argv);
    argc--; argv++;
    if(argc==0 || !UnitsValidS(*argv)) goto usage;
    t.r_ur.p_y = UnitsS2I(*argv);
    argc--; argv++;

    GeoCanonicalRect(&t, &rect);
    if(rect.r_xbot == rect.r_xtop) rect.r_xtop++;
    if(rect.r_ybot == rect.r_ytop) rect.r_ytop++;
  }

  /* should be no arguments left */
  if(argc>0) goto usage;

  /* start new selection */
  if(!(more || less)) SelectClear();

  /* setup search context */
  bzero(&scx, sizeof(SearchContext));
  if(anyCell)
  {
    scx.scx_use = w->lay_rootUse;
    scx.scx_trans = GeoIdentityTransform;
    scx.scx_area = rect;
  }
  else
  {
    noTreeRootUse = w->lay_rootUse;
    if (noTreeRootUse->cu_def != EditRootDef)
    {
      MsgErrorF("Edit cell not rooted in current window.\n");
      CMD_RETURN(interp);
    }

    scx.scx_use = EditCellUse;
    scx.scx_trans = EditToRootTransform;
    GeoTransRect(&RootToEditTransform, &rect, &scx.scx_area);
  }

  /* do the deed */
  {
    static Rect chunkBBox;

    SelectChunk(&scx, 
		layer, 
		w->lay_bitmask, 
		&chunkBBox, 
		less, 
		group,
		noTreeRootUse);

    /* surround selection with box */
    if (!less)
    {
      if(noTreeRootUse)
      {
	LaySetBox(noTreeRootUse->cu_def, &chunkBBox);
      }
      else
      {
	LaySetBox(scx.scx_use->cu_def, &chunkBBox);
      }
    }
  }

  CMD_RETURN(interp);	  

 usage:
  MsgErrorF("usage:  %s [options] layer xbot ybot xtop ytop\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdClear --
 *
 *      Implements sel_clear command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_clear_DESC   "clear selection"

#define sel_clear_DOC "
usage: sel_clear

Deselects everything.
"

static int
selTclCmdClear(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switches yet. */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* there should be no args left */
  if(argc!=0) goto usage;

  /* Do the deed */
  SelectClear();

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage: %s\n", cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * selTclCmdDuplicate --
 *
 *      Implements sel_duplicate command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_duplicate_DESC   "duplicate (copy) selection"

#define sel_duplicate_DOC "
usage: sel_duplicate [-dup_ok] deltaX deltaY

creates copy of selection at offset (deltaX,deltaY)
The copy becomes the new selection.

If -dup_ok, permits a subcell to be placed on exact copy of itself.
(Useful during interactive move, to avoid instances disappearing when
they are dragged over their cousins.)

Calls with -dup_ok should eventually be followed by a call like
'sel_move 0 0' to check for duplicates.

NOTE:  This command does not move the box.
"
static int
selTclCmdDuplicate(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;

  bool dupOK = FALSE;
  int deltaX, deltaY; 

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* number (e.g. coordiante) ? */
    if('0'<=c && c<='9') break;

    if(c=='d' && strncmp(*argv,"-dup_ok",length)==0)
    {
      argc--; argv++;
      dupOK = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* deltaX */
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  deltaX = UnitsS2I(*argv);
  argc--; argv++;

  /* delta Y */
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  deltaY = UnitsS2I(*argv);
  argc--; argv++;

  /* should be no arguments left */
  if(argc>0) goto usage;

  /* check for read-only */
  if(!DBAccessModify(EditCellUse->cu_def))
  {
    CMD_RETURN(interp);
  }

  /* do it */
  {
    Transform trans;
    
    GeoTransTranslate(deltaX, deltaY, &GeoIdentityTransform, &trans);
    SelectCopy(&trans, dupOK);
  }
  CMD_RETURN(interp);	  

 usage:
  MsgErrorF("usage:  %s [-dup_ok] deltaX deltaY\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * seTclCmdGroupTransfer --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_group_transfer_DESC "move selection to new Group and make it the active Group."

#define sel_group_transfer_DOC "
usage:  sel_group_transfer <dest_group> 

Moves selection to dest_group, AND makes dest_group the active group.

NOTE:  Selection should only contain paint and labels in the active group of
       the edit cell prior to this command.  
       (e.g. \"sel_area -group ...; sel_group_transfer foo\")
"

static int
selTclCmdGroupTransfer(ClientData clientData, 
		       Tcl_Interp *interp, 
		       int argc, 
		       char **argv)
{
    char *cmdName=argv[0];
    char *name= NULL;
    Group *group;
    CellDef *cell = EditCellUse->cu_def;

    CMD_BEGIN(interp);
    /* parse */
    {
      int i;

      /* flags */
      for (i=1; i<argc && argv[i][0] == '-'; i++)
      {
	  /* no flags yet */
	  {
	    goto badusage;
	  }
      }

      /* positional args */
      if(i==argc) goto badusage;

      /* get destGroup name */
      name = argv[i++];

      /* check that no args left over */
      if(i!=argc) goto badusage;
    }

    /* get group from name */ 
    if(strcmp(name,"0")==0) 
    {
      group=NULL;
    }
    else
    {
      group = DBGroupFromName(cell,name);
      if(!group) group = DBGroupNew(EditCellUse->cu_def,name);
    }

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) CMD_RETURN(interp);

    /* do the transfer */
    SelectGroupTransfer(group);

    /* return current group */
    Tcl_SetResult(interp, 
		  cell->cd_activeGroup?cell->cd_activeGroup->g_name:"0", 
		  TCL_VOLATILE);
    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s <dest_group>\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdLabels --
 *
 *      Implements sel_labels command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_labels_DESC   "select labels by name"

#define sel_labels_DOC "
usage: sel_labels [options]

Select labels in edit cell (active group only).

Options:
-any_cell
	don't restrict selection to edit cell.
        consider any cell in window with internals displayed.
        NOT YET IMPLEMENTED.

-any_group
        don't restrict selection to active group.

-inside xbot xtop ybot ytop
	select only labels entirely inside indicated area

-kind kind
	kind = in, out, in_out, local, global, text, or hidden.
	select only labels of specified kind.

-layer layer
	select only labels attached to given layer.

-less
        removing matching labels from selection.

-more
	don't clear selection first..

-pos dir
	dir = North, South et.c
        select only labels with matching position.

-rect xbot ybot xtop ytop
       select only labels with matching rects.

-text text
	select only labels with specified text.
"
static int
selTclCmdLabels(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;

  bool anyCell = FALSE;
  bool anyGroup = FALSE;

  char **insideArgs = NULL;
  Rect inside;

  char *kindArg = NULL;
  int kind = -1;

  char *layerArg = NULL;
  TileType layer = -1;

  bool less = FALSE;
  bool more = FALSE;

  char *posArg = NULL;
  int pos = -1;

  char **rectArgs = NULL;
  Rect rect;

  char *textArg = NULL;

  Group *activeGroup = NULL;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='a' && strncmp(*argv,"-any_cell",MAX(length,6))==0)
    {
      MsgErrorF("%s:  '-any_cell' option not yet implemented.\n",cmdName);
      CMD_RETURN(interp);

      argc--; argv++;
      anyCell = TRUE;
      continue;
    }

    if(c=='a' && strncmp(*argv,"-any_group",MAX(length,6))==0)
    {
      argc--; argv++;
      anyGroup = TRUE;
      continue;
    }

    if((c=='i') && (strncmp(*argv,"-inside",length) == 0)) 
    {
      argc--; argv++;
      if(argc<4) goto usage;
      insideArgs = argv;
      argc = argc-4;
      argv = argv+4;

      /* check for valid coords */
      if(!UnitsValidS(insideArgs[0]) || 
	 !UnitsValidS(insideArgs[1]) ||
	 !UnitsValidS(insideArgs[2]) || 
	 !UnitsValidS(insideArgs[3]) 
	 )
      {
        goto usage;
      }

      /* build rect */
      {
	Rect r;
	r.r_ll.p_x = UnitsS2I(insideArgs[0]);
	r.r_ll.p_y = UnitsS2I(insideArgs[1]);
	r.r_ur.p_x = UnitsS2I(insideArgs[2]);
	r.r_ur.p_y = UnitsS2I(insideArgs[3]);

	/* make sure lower left is really lower left */
	GeoCanonicalRect(&r,&inside);
      }

      continue;
    }

    if(c=='l' && strncmp(*argv,"-layer",MAX(length,2))==0)
    {
      argc--; argv++;
      if(argc<1) goto usage;
      layerArg = *argv;
      argc--; argv++;

      layer = DBTechNameType(layerArg);
      if (layer < 0)
      {
	MsgErrorF("Unknown layer: %s\n", layerArg);
	CMD_RETURN(interp);
      }

      continue;
    }

    if((c=='k') && (strncmp(*argv,"-kind",length) == 0)) 
    {
      argc--; argv++;
      if(argc<1) goto usage;
      kindArg = *argv;
      argc--; argv++;
      kind = DBLabelKindParse(kindArg);
      if(kind<0) goto usage;
      continue;
    }

    if(c=='l' && strncmp(*argv,"-less",MAX(length,2))==0)
    {
      argc--; argv++;
      less = TRUE;
      continue;
    }

    if((c=='m') && (strncmp(*argv,"-more",length) == 0)) 
    {
      argc--; argv++;
      more = TRUE;
      continue;
    }

    if((c=='p') && (strncmp(*argv,"-pos",length) == 0)) 
    {
      argc--; argv++;
      if(argc<1) goto usage;
      posArg = *argv;
      argc--; argv++;

      pos = GeoNameToPos(posArg, FALSE, TRUE);
      if (pos < 0) CMD_RETURN(interp);

      continue;
    }

    if((c=='r') && (strncmp(*argv,"-rect",length) == 0)) 
    {
      argc--; argv++;
      if(argc<4) goto usage;
      rectArgs = argv;
      argc = argc-4;
      argv = argv+4;

      /* check for valid coords */
      if(!UnitsValidS(rectArgs[0]) || 
	 !UnitsValidS(rectArgs[1]) ||
	 !UnitsValidS(rectArgs[2]) || 
	 !UnitsValidS(rectArgs[3]) 
	 )
      {
        goto usage;
      }

      /* build rect */
      {
	Rect r;
	r.r_ll.p_x = UnitsS2I(rectArgs[0]);
	r.r_ll.p_y = UnitsS2I(rectArgs[1]);
	r.r_ur.p_x = UnitsS2I(rectArgs[2]);
	r.r_ur.p_y = UnitsS2I(rectArgs[3]);

	/* make sure lower left is really lower left */
	GeoCanonicalRect(&r,&rect);
      }

      continue;
    }

    if(c=='t' && strncmp(*argv,"-text",length)==0) 
    {
      argc--; argv++;
      if(argc<1) goto usage;
      textArg = *argv;
      argc--; argv++;
      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* should be no arguments left */
  if(argc>0) goto usage;

  if(!EditCellUse)
  {
    MsgErrorF("No edit cell!\n");
    CMD_RETURN(interp);
  }

  /* get active group */
  activeGroup = EditCellUse->cu_def->cd_activeGroup;

  /* start new selection */
  if(!SelectRootDef || SelectRootDef != EditRootDef || (!more && !less))
  {
      SelectClear();
      SelectRootDef = EditRootDef;
  }
 
  selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);


  if(!less)
  {
    /* select matching labels in edit cell (unselect if -less) */
    Label *l;

    for(l=EditCellUse->cu_def->cd_labels; l; l=l->lab_next)
    {
      Rect labRootRect;
      int  labRootPos;

      if(layerArg && 
	 (l->lab_type != layer)) continue;

      if(kindArg &&
	 (l->lab_kind != kind)) continue;

      if(textArg && 
	 (strcmp(textArg, l->lab_text) != 0)) continue;

      if(!anyGroup && l->lab_group != activeGroup) continue;

      /* use root coordinates */
      GeoTransRect(&EditToRootTransform, &(l->lab_rect), &labRootRect);

      if(rectArgs &&
	 (rect.r_xbot != labRootRect.r_xbot ||
	  rect.r_ybot != labRootRect.r_ybot ||
	  rect.r_xtop != labRootRect.r_xtop ||
	  rect.r_ytop != labRootRect.r_ytop)) continue;

      /* root coords! */
      labRootPos = GeoTransPos(&EditToRootTransform, l->lab_pos);

      if(posArg && 
	 (labRootPos != pos)) continue;

      if(insideArgs && !GEO_SURROUND(&inside,&labRootRect)) continue;

      /* label matches, add it to selection */
      {
	GeoTransRect(&EditToRootTransform, &(l->lab_rect), &labRootRect);
	(void) DBLabelAdd(SelectUse->cu_def, 
			  &labRootRect, 
			  labRootPos, 
			  l->lab_text, 
			  l->lab_type,
			  l->lab_kind);
      }
    }
  }
  else
  {
    /* delete matching labels from selection */
    Label *l = SelectUse->cu_def->cd_labels;
    
    while(l) 
    {
      Rect labRootRect;
      int  labRootPos;

      if(layerArg && 
	 (l->lab_type != layer)) goto next;

      if(kindArg &&
	 (l->lab_kind != kind)) goto next;

      if(textArg && 
	 (strcmp(textArg, l->lab_text) != 0)) goto next;

      if(!anyGroup && l->lab_group != activeGroup) goto next;

      /* use root coordinates */
      GeoTransRect(&EditToRootTransform, &(l->lab_rect), &labRootRect);

      if(rectArgs &&
	 (rect.r_xbot != labRootRect.r_xbot ||
	  rect.r_ybot != labRootRect.r_ybot ||
	  rect.r_xtop != labRootRect.r_xtop ||
	  rect.r_ytop != labRootRect.r_ytop)) goto next;

      /* root coords! */
      labRootPos = GeoTransPos(&EditToRootTransform, l->lab_pos);

      if(posArg && (labRootPos != pos)) goto next;

      if(insideArgs && !GEO_SURROUND(&inside,&labRootRect)) goto next;

      /* label matches, rm it */ 
      l = DBLabelErase(SelectUse->cu_def,l);
      continue;

    next:
      l = l->lab_next; 
    }
  }

  /* display new selection */  
  {
    Rect *area = DBBBoxCellDef(SelectRootDef);
    selUndoBracket(FALSE, SelectRootDef, area);
    LayChangedSelection(SelectRootDef, area, TRUE);
    
    DBChangedArea(SelectDef, area, &DBAllButSpaceBits, 0);

    CMD_RETURN(interp);	  
  }

 usage:
  MsgErrorF("usage:  %s [options]\n", cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * selTclCmdMove --
 *
 *      Implements sel_move command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_move_DESC   "move (translate) selection"

#define sel_move_DOC "
usage: sel_move [-dup_ok] x y

Moves selection deltaX to the right and deltaY up.

If -dup_ok, permits a subcell to be placed on exact copy of itself.
(Useful during interactive move, to avoid instances disappearing when
they are dragged over their cousins.)

Calls with -dup_ok should eventually be followed by a call with out
the flag to check for duplicates:  'sel_move 0 0' does the trick.

NOTE:  unlike :move, this command does not move the box.
"
static int
selTclCmdMove(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;

  bool dupOK = FALSE;
  int deltaX, deltaY; 

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* number (e.g. coordiante) ? */
    if('0'<=c && c<='9') break;

    if(c=='d' && strncmp(*argv,"-dup_ok",length)==0)
    {
      argc--; argv++;
      dupOK = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* deltaX */
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  deltaX = UnitsS2I(*argv);
  argc--; argv++;

  /* delta Y */
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  deltaY = UnitsS2I(*argv);
  argc--; argv++;

  /* should be no arguments left */
  if(argc>0) goto usage;

  /* check for read-only */
  if(!DBAccessModify(EditCellUse->cu_def)) CMD_RETURN(interp);

  /* transform selection */
  {
    Transform trans;
    
    GeoTransTranslate(deltaX, deltaY, &GeoIdentityTransform, &trans);
    SelectTransform(&trans, dupOK);
  }
  CMD_RETURN(interp);	  

 usage:
  MsgErrorF("usage:  %s [-dup_ok] deltaX deltaY\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdNet --
 *
 *      Implements sel_net command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_net_DESC   "select net under cursor"

#define sel_net_DOC "
usage: sel_net [-less | -more] [-no_labels] [-point x y] [-limit n] layer

Starting at layer under the cursor, all electrically connected material 
is selected.

However the search is stopped at cells whose internals are not displayed
(i.e. unexpanded cells).

RETURNS:  
  {} on normal completion, 
  1 if search interrupted (e.g. the specified limit was reached).

-less
        remove net from selection!

-more
	don't clear selection first.

-no_labels
        don't select labels (speeds up net selection)

-point x y
        start search at (x,y) instead of cursor.

-limit n
        interrupt search after extending from n rectangles/polygons 
"

static int
selTclCmdNet(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;

  TileType layer;
  Point point;

  bool less = FALSE;
  bool more = FALSE;
  bool pointArg = FALSE;
  bool noLabels = FALSE;
  int limit = 0;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='l' && strncmp(*argv,"-less",MAX(length,3))==0)
    {
      MsgErrorF("%s:  '-less' option not yet implemented.\n",cmdName);
      CMD_RETURN(interp);

      argc--; argv++;
      less = TRUE;
      continue;
    }


    if(c=='l' && strncmp(*argv,"-limit",MAX(length,3))==0)
    {
      argc--; argv++;

      if(argc==0) goto usage;
      limit = atoi(*argv);
      argc--; argv++;

      continue;
    }

    if((c=='m') && (strncmp(*argv,"-more",length) == 0)) 
    {
      argc--; argv++;
      more = TRUE;
      continue;
    }

    if((c=='n') && (strncmp(*argv,"-no_labels",length) == 0)) 
    {
      argc--; argv++;
      noLabels = TRUE;
      continue;
    }

    if((c=='p') && (strncmp(*argv,"-point",length) == 0)) 
    {
      argc--; argv++;
      pointArg = TRUE;

      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      point.p_x = UnitsS2I(*argv);
      argc--; argv++;

      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      point.p_y = UnitsS2I(*argv);
      argc--; argv++;

      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* get layer */
  if(argc<1) goto usage;
  layer = DBTechNameType(*argv);
  if (layer < 0)
  {
    MsgErrorF("Unknown layer: %s\n", *argv);
    CMD_RETURN(interp);
  }
  if (layer == TT_SPACE)
  {
    MsgErrorF("%s not allowed on 'space'\n", cmdName);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  /* there should be no args left */
  if(argc!=0) goto usage;

  if (!(more || less)) SelectClear();

  /* call SelectNet() todo the real work */
  {
    SearchContext scx;
    Layout *window = LayCurWindow();

    scx.scx_use = window->lay_rootUse;
    scx.scx_trans = GeoIdentityTransform;

    if(pointArg)
    {
      scx.scx_area.r_xbot = point.p_x;
      scx.scx_area.r_ybot = point.p_y;
      scx.scx_area.r_xtop = point.p_x+1;
      scx.scx_area.r_ytop = point.p_y+1;
    }
    else
    {
      if (!LayPointGet(NULL, &scx.scx_area))
      {
	MsgErrorF("Cursor not in layout window!\n");
	CMD_RETURN(interp);
      }
    }

    {
      bool incomplete;

      incomplete = SelectNet(&scx, 
			     layer, 
			     window->lay_bitmask, 
			     (Rect *) NULL, 
			     less,
			     !noLabels,
			     limit);

      if(incomplete) Tcl_SetResult(interp, "1", TCL_STATIC);
    }
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage: %s [-more | -less] [-point x y] [-limit n] layer\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdPolygons --
 *
 *      Implements sel_polygons command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define sel_polygons_DESC   "select polygons"

#define sel_polygons_DOC "
usage: sel_polygons n 

Select polygon n in edit cell (first polygon is 0).
NOTE:  Does not clear selection first.
"

static int
selTclCmdPolygons(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  int num; /* number of the polgyon to select */
  PointFloat *points;
  Polygon *poly;
  Polygon *selPoly;
  Layout *w = LayCurWindow();
  CellUse *rootUse = w->lay_rootUse;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* parse n */  
  if(argc==0) goto usage;
  if(sscanf(*argv,"%d",&num)!=1) goto usage;
  argc--; argv++;
  if(num<0) goto usage;

  if(argc!=0) goto usage;

  /* all changes to selection must be bracketed */
  selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);

  /* find the nth polygon */
  poly = EditCellUse->cu_def->cd_polygons;
  while(num>0 && poly)
  {
    poly = poly->poly_next;
    num--;
  }
  if(!poly) goto usage;
    
  /* generate points transformed to root cell coords */
  {
    int i;
    int size = poly->poly_size;

    MALLOC(PointFloat *, points, sizeof(PointFloat)*size);

    for(i=0; i<size; i++)
    {
      GeoTransPointF(&EditToRootTransform,
		     &poly->poly_points[i],
		     &points[i]);
    }
  }

  /* If the source definition is changing, clear the old selection. */
  if (SelectRootDef != rootUse->cu_def)
  {
    if (SelectRootDef != NULL)  SelectClear();
    SelectRootDef = rootUse->cu_def;
  }

  /* add polygon to selection def */
  {
    selPoly = DBPolyNew(SelectDef, 
			poly->poly_type,
			poly->poly_size,
			points,
			poly->poly_wirePath,
			FALSE); /* no notify */

  }

  /* do change notification */
  selUndoBracket(FALSE, SelectRootDef, &selPoly->poly_bbox);
  LayChangedSelection(SelectRootDef, &selPoly->poly_bbox, TRUE);
  DBChangedArea(SelectDef, &selPoly->poly_bbox, &DBAllButSpaceBits, 0);

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage:  %s n\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdRegion --
 *
 *      Implements sel_region command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_region_DESC   "select connected region under cursor"

#define sel_region_DOC "
usage: sel_region [-less | -more] [-point x y] layer

Select connected region on given layer under the cursor, 
(like sel_net except that search does not follow through layer changes).

The search is stopped at cells whose internals are not displayed
(i.e. unexpanded cells).

-less
        remove region from selection!

-more
	don't clear selection first.

-point x y
        start search at (x,y) instead of cursor.
"

static int
selTclCmdRegion(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;

  TileType layer;
  Point point;

  bool less = FALSE;
  bool more = FALSE;
  bool pointArg = FALSE;


  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='l' && strncmp(*argv,"-less",MAX(length,2))==0)
    {
      MsgErrorF("%s:  '-less' option not yet implemented.\n",cmdName);
      CMD_RETURN(interp);

      argc--; argv++;
      less = TRUE;
      continue;
    }

    if((c=='m') && (strncmp(*argv,"-more",length) == 0)) 
    {
      argc--; argv++;
      more = TRUE;
      continue;
    }

    if((c=='p') && (strncmp(*argv,"-point",length) == 0)) 
    {
      argc--; argv++;
      pointArg = TRUE;

      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      point.p_x = UnitsS2I(*argv);
      argc--; argv++;

      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      point.p_y = UnitsS2I(*argv);
      argc--; argv++;

      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* get layer */
  if(argc<1) goto usage;
  layer = DBTechNameType(*argv);
  if (layer < 0)
  {
    MsgErrorF("Unknown layer: %s\n", *argv);
    CMD_RETURN(interp);
  }
  if (layer == TT_SPACE)
  {
    MsgErrorF("%s not allowed on 'space'\n", cmdName);
    CMD_RETURN(interp);
  }
  argc--; argv++;

  /* there should be no args left */
  if(argc!=0) goto usage;

  if (!(more || less)) SelectClear();

  /* call SelectRegion() to do the real work */
  {
    SearchContext scx;
    Layout *window = LayCurWindow();

    scx.scx_use = window->lay_rootUse;
    scx.scx_trans = GeoIdentityTransform;

    if(pointArg)
    {
      scx.scx_area.r_xbot = point.p_x;
      scx.scx_area.r_ybot = point.p_y;
      scx.scx_area.r_xtop = point.p_x+1;
      scx.scx_area.r_ytop = point.p_y+1;
    }
    else
    {
      if (!LayPointGet(NULL, &scx.scx_area))
      {
	MsgErrorF("Cursor not in layout window!\n");
	CMD_RETURN(interp);
      }
    }

    SelectRegion(&scx, 
	      layer, 
	      window->lay_bitmask, 
	      (Rect *) NULL, 
	      less);
  }

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage: %s [-more | -less] layer\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdBuffer --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_buffer_DESC "add cell buffer contents to selection"

#define sel_buffer_DOC "
usage:  sel_buffer cell_name  

Selects everything that is present in cell buffer.

NOTE:  Current implementation assumes that everything in cell buffer
is also present in current window.  Beware, if this is not the case
strange behaviour and errors can result.
"
static int
selTclCmdBuffer(ClientData clientData, 
		Tcl_Interp *interp, 
		int argc, 
		char **argv)
{
  char *cmdName= NULL;
  char *srcName=NULL;
  CellDef *srcDef = NULL;
  Layout *w = LayCurWindow();

  CMD_BEGIN(interp);

  /* Parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */
    
  /* src def */
  if(argc==0) goto usage;
  srcName = *argv;
  argc--; argv++;
  srcDef = DBCellLookDef(srcName);
  if (!srcDef)
  {
    MsgErrorF("Could not augment selection, cell '%s' not found.\n",
	      srcName);
    CMD_RETURN(interp);
  }

  /* do it */
  SelectBuffer(srcDef,w->lay_rootUse->cu_def);

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s cell_name\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdSave --
 *
 *      Implements sel_save command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_save_DESC   "save selection to disk"

#define sel_save_DOC "
usage: sel_save file

Saves selection to file.max
"

static int
selTclCmdSave(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;
  char *fileName = NULL;
  TileType layer;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switches yet */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* get fileName */
  if(argc==0) goto usage;
  fileName =*argv;
  argc--; argv++;

  /* there should be no args left */
  if(argc!=0) goto usage;

  /* Be sure to paint DRC check information into the cell before
   * saving it!  Otherwise DRC problems may not be detected. 
   */
  DBPaintPlane(SelectDef->cd_planes[PL_DRC_CHECK],
	       DBBBoxCellDef(SelectDef),
	       DBStdPaintTbl(TT_CHECKPAINT, PL_DRC_CHECK),
	       (PaintUndoInfo *) NULL);

  cmdSaveCell(SelectDef, fileName, FALSE);

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage: %s file\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * selTclCmdTransform --
 *
 *      Implements tcl command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

#define sel_transform_DESC   "transform the selection"

#define sel_transform_DOC "
usage: sel_transform [-fix x y] [-offset x y] [-dup_ok] transform

transform is one of: {}, r90, r180, r270, fx, fy, fx_r90, fy_r90

if -fix, fix given point.  
if no -fix fix middle of selection bounding box.

if -offset, offset (translate) by given amount after applying transform. 

If -dup_ok, permits a subcell to be placed on exact copy of itself.
(Useful during series of operations to avoid instances from disappearing
when they (temporarily) fall on top of their cousins.)

Calls with -dup_ok should eventually be followed by a call with out
the flag to check for duplicates:  'sel_move 0 0' does the trick.

"

static int
selTclCmdTransform(ClientData clientData, 
		   Tcl_Interp *interp, 
		   int argc, 
		   char **argv)
{
  char *cmdName = NULL;
  PointFloat fix = {DBL_MAX,DBL_MAX};
  Point offset = {0,0};
  bool dupOK = FALSE;

  Transform trans;
    
  TileType layer;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='d' && strncmp(*argv,"-dup_ok",length)==0)
    {
      argc--; argv++;
      dupOK = TRUE;
      continue;
    }

    if(c=='f' && strncmp(*argv,"-fix",length)==0)
    {
      argc--; argv++;
      
      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      fix.pf_x = UnitsS2F(*argv);
      argc--; argv++;
      
      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      fix.pf_y = UnitsS2F(*argv);
      argc--; argv++;

      continue;
    }

    if(c=='o' && strncmp(*argv,"-offset",length)==0)
    {
      argc--; argv++;
      
      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      offset.p_x = UnitsS2I(*argv);
      argc--; argv++;
      
      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      offset.p_y = UnitsS2I(*argv);
      argc--; argv++;

      continue;
    }

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* parse transform */
  if(argc==0) goto usage;
  {
    Transform *orientation = GeoNameToTrans(*argv,TRUE);
    argc--; argv++;  
    if((int) orientation <= 0) goto usage;
    trans = *orientation;
  }

  /* there should be no args left */
  if(argc!=0) goto usage;

  /* check for read-only */
  if(!DBAccessModify(EditCellUse->cu_def)) CMD_RETURN(interp);

  /* if no fixed point specified, use center of selection */
  if(fix.pf_x == DBL_MAX)   
  {
    Rect *bbox = DBBBoxCellDef(SelectDef);

    fix.pf_x = (bbox->r_xbot + bbox->r_xtop) / 2.0;
    fix.pf_y = (bbox->r_ybot + bbox->r_ytop) / 2.0;
  }

  /* move fixed point back after operation */
  {
    PointFloat p;

    GeoTransPointF(&trans,&fix,&p);
    GeoTranslateTrans(&trans,
		      ROUND(fix.pf_x - p.pf_x),
		      ROUND(fix.pf_y - p.pf_y),
		      &trans);
  }

  /* offset */
  GeoTranslateTrans(&trans,
		    offset.p_x,
		    offset.p_y,
		    &trans);

  /* doit */
  SelectTransform(&trans, dupOK);

  CMD_RETURN(interp);	  

usage:
  MsgErrorF("usage: %s [-fix x y] [-translate x y] transform\n",
	    cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * selTclCmdUndo --
 *
 *      Implements sel_undo command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define sel_undo_DESC   "Control whether undo info kept for selection"

#define sel_undo_DOC "
usage: sel_undo [0|1]

If arg given turns selection undo off or on accordingly.
Returns selection undo status prior to command.

Side Effect:
If selection undo status is changed, all undo info is flushed.
"

static int
selTclCmdUndo(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName = NULL;
  char *value = NULL;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switches yet */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* get value, if any  */
  if(argc) 
  {
    value =*argv;
    argc--; argv++;
  }

  /* there should be no args left */
  if(argc!=0) goto usage;

  /* result is current value */
  Tcl_SetResult(interp, SelUndo?"1":"0", TCL_STATIC);

  /* set new value */
  if(value)
  {
    bool vnew;

    /* parse new value */
    if(strcmp(value,"0")==0 || strcmp(value,"{}")==0)
    {
      vnew=FALSE;
    }
    else if (strcmp(value,"1")==0)
    {
      vnew=TRUE;
    }
    else
    {
      goto usage;
    }

    if(vnew != SelUndo)
    {
      UndoFlush();
      SelUndo = vnew;
    }
  }
	 
  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s [0|1]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelTclInit --
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
SelTclInit(Tcl_Interp *interp)
{
  /* initialize tcl commands in selTclWhat.c 
   * (selection enumeration procs) 
   */
  selTclWhatInit(interp);

  /* initialize sel_what_old for debug */
  selTclWhatOldInit(interp);

  /* initialize commands in this file */
   MnDocCreateCommand(interp, "sel_area", selTclCmdArea,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_area_DESC,
	       sel_area_DOC);
   MnDocCreateCommand(interp, "sel_buffer", selTclCmdBuffer,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_buffer_DESC,
	       sel_buffer_DOC);
   MnDocCreateCommand(interp, "sel_cell", selTclCmdCell,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_cell_DESC,
	       sel_cell_DOC);
   MnDocCreateCommand(interp, "sel_chunk", selTclCmdChunk,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_chunk_DESC,
	       sel_chunk_DOC);
   MnDocCreateCommand(interp, "sel_clear", selTclCmdClear,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_clear_DESC,
	       sel_clear_DOC);
   MnDocCreateCommand(interp, "sel_duplicate", selTclCmdDuplicate,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_duplicate_DESC,
	       sel_duplicate_DOC);
   MnDocCreateCommand(interp, "sel_group_transfer", selTclCmdGroupTransfer,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_group_transfer_DESC,
	       sel_group_transfer_DOC);
   MnDocCreateCommand(interp, "sel_labels", selTclCmdLabels,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_labels_DESC,
	       sel_labels_DOC);
   MnDocCreateCommand(interp, "sel_move", selTclCmdMove,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_move_DESC,
	       sel_move_DOC);
   MnDocCreateCommand(interp, "sel_net", selTclCmdNet,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_net_DESC,
	       sel_net_DOC);
   MnDocCreateCommand(interp, "sel_polygons", selTclCmdPolygons,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_polygons_DESC,
	       sel_polygons_DOC);
   MnDocCreateCommand(interp, "sel_region", selTclCmdRegion,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_region_DESC,
	       sel_region_DOC);
   MnDocCreateCommand(interp, "sel_save", selTclCmdSave,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_save_DESC,
	       sel_save_DOC);
   MnDocCreateCommand(interp, "sel_transform", selTclCmdTransform,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_transform_DESC,
	       sel_transform_DOC);
   MnDocCreateCommand(interp, "sel_undo", selTclCmdUndo,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       sel_undo_DESC,
	       sel_undo_DOC);
}
