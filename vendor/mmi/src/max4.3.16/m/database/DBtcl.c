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
 * DBtcl.c -- Tcl command interface to database module.
 */

static char rcsid[] = "$Header$";

#include <stdlib.h>
#include <limits.h>
#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "string.h"
#include "signals.h"
#include "layout.h"
#include "units.h"
#include "utils.h"
#include "geometry.h"
#include "database.h"
#include "databaseInt.h"
#include "bplane.h"
#include "debug.h"


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdChunk --
 *
 *      Implements db_chunk command.
 *
 * C Result:
 *	A standard Tcl result.
 *

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_chunk_DESC   "find largest rect of paint on given layer and covering given area"

#define db_chunk_DOC "
largest = fattest = maximum minimum dimension (secondarily, maximizes second dimension).

Usage: db_chunk [options] layer xbot ybot xtop ytop

Returns:  xbot ybot xtop ytop
          or
          {}, if no chunk containing initial area.

Options:
-any_cell
    don't restrict search to edit cell.
    consider paint in any cell in window with internals displayed

-group 
    restrict search to active group only
"
static int
dbTclCmdChunk(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  bool anyCell = FALSE;
  bool group = FALSE;

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
  argc--; argv++;

  /* rect coordinate args */
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  rect.r_ll.p_x = UnitsS2I(*argv);
  argc--; argv++;
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  rect.r_ll.p_y = UnitsS2I(*argv);
  argc--; argv++;
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  rect.r_ur.p_x = UnitsS2I(*argv);
  argc--; argv++;
  if(argc==0 || !UnitsValidS(*argv)) goto usage;
  rect.r_ur.p_y = UnitsS2I(*argv);
  argc--; argv++;

  /* should be no arguments left */
  if(argc>0) goto usage;

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

  /* set scx_area to largest chunk */
  DBChunk(&scx, 
	  layer, 
	  w->lay_bitmask, 
	  group,
	  noTreeRootUse);

  /* return result */
  if(!GEO_RECTNULL(&scx.scx_area)) 
  {
    Rect *result = &scx.scx_area;

    Tcl_SetResult(interp, UnitsI2S(result->r_xbot), TCL_VOLATILE);
    Tcl_AppendElement(interp, UnitsI2S(result->r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(result->r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(result->r_ytop));
  }

  CMD_RETURN(interp);

 usage:
  MsgErrorF("usage:  %s [options] layer xbot ybot xtop ytop\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdLayerAuto --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_layer_auto_DESC "define an autogenerated layer" 

#define db_layer_auto_DOC "
Usage: db_layer_auto [layer_name dependencies]

If no args, lists auto-generated layers and dependencies. 

dependencies is list of layers (',' separated, no white space)
"

static int
dbTclCmdLayerAuto(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  TileType type;
  TileTypeBitMask depends;
  int plane;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* unrecognized option */
    goto usage;
  }

  if(argc == 0)
  {
    fprintf(stderr,"TODO layer_auto, list case N/Y/I.\n");    

    CMD_RETURN(interp);
  }

  /* parse layer */
  if(argc == 0) goto usage;
  type = DBTechNameType(*argv);
  if(type==-1) 
  {
    MsgErrorF("Ambiguous layer:  '%s'.\n", *argv);
    CMD_RETURN(interp);
  }
  if(type==-2) 
  {
    MsgErrorF("Unknown layer:  '%s'.\n", *argv);
    CMD_RETURN(interp);
  }
  argv++; argc--;

  plane = DBPlane(type);

  /* parse dependencies */
  if(argc == 0) goto usage;
  if (!CmdParseLayers(*argv, &depends)) 
  {
    CMD_RETURN(interp);
  }
  argv++; argc--;
  if(argc!=0) goto usage;

  /* set it */
  DBPlaneFlags[plane] |= DBF_AUTO_GENERATED;
  DBPlaneDependencies[plane] = depends;

  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s [layer_name dependencies]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdLayerTemp --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_layer_temp_DESC "mark/unmark a layer as temporary" 

#define db_layer_temp_DOC "
Usage: db_layer_temp [-reset] [layer_name]

If no args, lists all temporary layers.

If -reset, removes layer from the temporary list.

Changing a temproary layer does not set the modified bit.
"
static int
dbTclCmdLayerTemp(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  int plane;
  bool reset = FALSE;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='r' && strncmp(*argv,"-reset",length)==0)
    {
      argc--; argv++;
      reset = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;
  }

  if(argc == 0)
  {
    /* list temporary layers */
    int i;
    for (i = 1; i < DBNumPlanes; i++)
    {
      if(DBPlaneFlags[i]&DBF_TEMP) 
      {
	Tcl_AppendElement(interp, DBPlaneLongNameTbl[i]);
      }
    }

    CMD_RETURN(interp);
  }

  /* parse layer */
  if(argc == 0) goto usage;
  plane = DBTechNamePlane(*argv);
  if(plane==-1) 
  {
    MsgErrorF("Ambiguous layer:  '%s'.\n", *argv);
    CMD_RETURN(interp);
  }
  if(plane==-2) 
  {
    MsgErrorF("Unknown layer:  '%s'.\n", *argv);
    CMD_RETURN(interp);
  }

  argv++; argc--;
  if(argc!=0) goto usage;

  /* do it */
  if(reset)
  {
    DBLayerTempReset(plane);
  }
  else
  {
    DBLayerTempSet(plane);
  }

  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s [-reset] [layer_name]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCells --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define db_cells_DESC "get info on cells in memory"

#define db_cells_DOC "
Usage: db_cells [-user] [cellName]

If cellName, restricts output to that cell, otherwise all
cell buffers.

    For each buffer, outputs one line:
    <cellname> <flaglist> <filename> 

    changes and changesPending for DEBUGGING of db consistency code.

If -user, does not print internal buffers.  The changes/changesPending
output is also ommited.

    See also 'cell_info'  
"

/* newlines before all but first cell */
static int cellsFirst;

/* if set, list only user cells */
static bool cellsUser;

/* cellsFunc - Callback func for dbTclCmdCells()
 *             Adds entery for cell to tcl result.
 */
static int
cellsFunc(CellDef *def, 
                 	/* Pointer to CellDef to be saved.  This def might
			 * be an internal buffer; if so, we ignore it.
			 */
	  ClientData clientdata)
{
    Tcl_Interp *interp = (Tcl_Interp *) clientdata;

    /*
    fprintf(stderr,"DEBUG cellsFunc def=%s\n",def->cd_name);
    */

    if (SigInterruptPending) return 1; 

    /* if -user, skip internal cells */
    if(cellsUser && def->cd_flags&CD_INTERNAL) return 0;

    /* output newline prior to all but first cell */
    if(!cellsFirst)
    {
        Tcl_AppendResult(interp,"\n", (char *) NULL);
    }
    cellsFirst = FALSE;

    /* output cell name */
    Tcl_AppendResult(interp, def->cd_name, (char *) NULL);

    /* output flaglist  */
    Tcl_AppendResult(interp, "\t{", (char *) NULL);

#define dbtclDOFLAG(f,p) if(def->cd_flags & f) Tcl_AppendResult(interp,p, NULL);
    dbtclDOFLAG(CD_AVAILABLE," available");
    dbtclDOFLAG(CD_NOT_FOUND," notFound");
    dbtclDOFLAG(CD_READ_RETRY," read_retry");
    dbtclDOFLAG(CD_READ_ONLY," readOnly");
    dbtclDOFLAG(CD_MODIFIED," modified");
    dbtclDOFLAG(CD_INTERNAL," internal");
    dbtclDOFLAG(CD_GENERATED," generated");
    dbtclDOFLAG(CD_NO_UNDO," no_undo");
    dbtclDOFLAG(CD_CHANGED_BBOX," changed_bbox");
    dbtclDOFLAG(CD_CHANGED_INSTANCE," changed_instance");
    dbtclDOFLAG(CD_DRC_ALL_PENDING," drc_all_pending");
    dbtclDOFLAG(CD_DRC_PENDING," drcPending");
    dbtclDOFLAG(CD_DRC_WITH_PARENT," drc_with_parent");
    dbtclDOFLAG(CD_NETLIST_WITH_PARENT," ntl_with_parent");
    dbtclDOFLAG(CD_ALLFEEDTHRUS," ntl_all_feed_thrus");
    dbtclDOFLAG(CD_NOFEEDTHRUS," ntl_no_feed_thrus");
    dbtclDOFLAG(CD_GDS_TAG," gds_tag");
#undef dbtclDOFLAG

    Tcl_AppendResult(interp, " }\t", (char *) NULL);

    /* output associated filename */
    if (def->cd_file)
    {
        Tcl_AppendResult(interp, def->cd_file, (char *) NULL);
    }
    else
    {
        Tcl_AppendResult(interp, "{}", (char *) NULL);
    }

    return 0;
}

static int
dbTclCmdCells(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  CellDef *def = NULL;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* initial switch values */
  cellsUser = FALSE;

  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    if(c=='u' && strncmp(*argv,"-user",length)==0)
    {
      argc--; argv++;
      cellsUser = TRUE;
      continue;
    }

    /* unrecognized option */
    goto usage;
  }
    
  /* parse cell_name */
  if(argc)
  {
    def = DBCellLookDef(*argv);
    if(!def)
    {
      /* return null if def not found */
      CMD_RETURN(interp);
    }
    argc--; argv++;
  }

  if(argc) goto usage;

  cellsFirst = TRUE;
  if(!def)
  {
    /* list cells */
    (void) DBCellSrDefs(0, cellsFunc, (ClientData) interp);
  }
  else
  {
    /* list single cell */
    cellsFunc(def,(ClientData) interp);
  }

  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s [cell_name]\n", cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellClear --
 *
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_clear_DESC "clear cell of all contents"

#define db_cell_clear_DOC "
usage:  db_cell_clear  [cell]

If -cell absent, defaults to edit cell.
Removes all contents of cell.

Not undoable.  Clears undo stack, unless cell has no_undo flag set.
"
static int

dbTclCmdCellClear(ClientData clientData, 
		  Tcl_Interp *interp, 
		  int argc, 
		  char **argv)
{
  char *cmdName= NULL;
  char *cellName= NULL;
  CellDef *clearDef;
  
  CMD_BEGIN(interp);

  /* Parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switches, yet */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* cell name */
  if(argc>0) 
  {
    cellName = *argv;
    argc--; argv++;
  }

  if(argc>0) goto usage;

  /* find def to clear */
  if(cellName)
  {
    clearDef = DBCellLookDef(cellName);
    if(!clearDef) 
    {
      MsgErrorF("Can not clear '%s', not found!\n", cellName);
      CMD_RETURN(interp);
    }
  }
  else
  {
    clearDef = EditCellUse->cu_def;
  }

  /* check for read-only */
  if(!DBAccessModify(clearDef)) CMD_RETURN(interp);

  /* Clear def contents and do all appropriate updates 
   * (may clear undo.)
   */
  DBCellClearContentsUp(clearDef);

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [cell]\n", cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellCopy --
 *
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_copy_DESC "copy the contents of one cell into another"

#define db_cell_copy_DOC "
usage:  db_cell_copy [-source src_cell] [-offset x y] dest_cell  

If no -source switch, source defaults to edit cell.
If -offset, translate by specified amounts in x and y.

Copies contents of source cell to dest_cell

NOTE:  If dest_cell doesn't exist, an empty one is created.

NOTE:  If dest_cell is already in memory, the contents of the source cell
are added to it.
"

static int
dbTclCmdCellCopy(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName= NULL;
  char *destName= NULL;
  char *srcName=NULL;
  CellDef *srcDef = NULL;
  CellDef *destDef = NULL;
  int deltaX = 0; 
  int deltaY = 0; 

  CMD_BEGIN(interp);

  /* Parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];


    if (c=='o' && strncmp(*argv,"-offset",length)==0)
    {
      argc--;
      argv++;

      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      deltaX = UnitsS2I(*argv);
      argc--; argv++;

      if(argc==0 || !UnitsValidS(*argv)) goto usage;
      deltaY = UnitsS2I(*argv);
      argc--; argv++;
      continue;
    }

    if (c=='s' && strncmp(*argv,"-source",length)==0)
    {
      argc--;
      argv++;

      if(argc==0) goto usage;
      srcName=*argv;
      argc--;
      argv++;
      continue;
    }

    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */
    
  /* dest def */
  if(argc==0) goto usage;
  destName = *argv;
  argc--; argv++;
  destDef = DBCellLookDef(destName);
  if (!destDef)
  {
       destDef = DBCellNewDef(destName, (char *) NULL);
       DBCellSetAvail(destDef);
  }
  
  if(argc!=0) goto usage;

  /* src def */
  if (!srcName) 
  {
    srcDef = EditCellUse->cu_def;
  }
  else
  {
    srcDef = DBCellLookDef(srcName);
    if (!srcDef)
    {
        MsgErrorF("%s:  source def '%s' does not exist!\n",
		  cmdName, srcName);
	CMD_RETURN(interp);
    }
  }

  /* check for read-only */
  if(!DBAccessModify(destDef)) CMD_RETURN(interp);

  /* do the copy */
  {
    Transform trans;

    GeoTransTranslate(deltaX, deltaY, &GeoIdentityTransform, &trans);
    DBCellCopyDefNotify(srcDef, destDef, &trans);
  }

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-source src_cell] [-offset x y] dest_cell\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellDelete --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_delete_DESC "delete cell"

#define db_cell_delete_DOC "
usage:  db_cell_delete  [cell]

Clears and deletes in-memory copy of a cell (defaults to edit cell), 
does not effect disk file.

Since the undo stack may contain references to this cell, it is
flushed (unless the cell has the no_undo attribute (see db_cell_new).

If the deleted cell was a toplevel cell in any window, that window is reloaded 
with some other available cell.

If there are any uses of the cell, the cell is cleared but not deleted.

NOTE:  The cell is deleted without warning, even if it has been modifed since
last change!
"

static CellDef *dbTclCmdCellDeleteReplaceDef;

/* helper func to pick replacement def */
static int
dbTclCmdCellDeleteFunc1(CellDef *def, ClientData cd)
{
  CellDef *deleteDef = (CellDef *) cd;

  if((def->cd_flags&CD_INTERNAL)) return 0;
  if(!(def->cd_flags&CD_AVAILABLE)) return 0;
  if(def == deleteDef) return 0;

  dbTclCmdCellDeleteReplaceDef = def;
  return 1;
}

/* helper func to reload windows whose root def is being deleted */
static int
dbTclCmdCellDeleteFunc2(Layout *w, ClientData cd)
{
  CellDef *deleteDef = (CellDef *) cd;

  if(w->lay_rootUse->cu_def == deleteDef)  
  {
    LayloadWindow(w,dbTclCmdCellDeleteReplaceDef->cd_name);
  }

  return 0;
}

static int
dbTclCmdCellDelete(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName= NULL;
  char *cellName= NULL;
  CellDef *deleteDef;
  
  CMD_BEGIN(interp);

  /* Parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* no switches, yet */

    /* unrecognized option */
    goto usage;

  } /* end while(argc>0 && **argv=='-')  */

  /* No positional args (yet) */
  if(argc>0) 
  {
    cellName = *argv;
    argc--; argv++;
  }

  if(argc>0) goto usage;

  /* find deleteDef */
  if(cellName)
  {
    deleteDef = DBCellLookDef(cellName);
    if(!deleteDef) 
    {
      MsgErrorF("Can not delete '%s', not found!\n", cellName);
      CMD_RETURN(interp);
    }
  }
  else
  {
    deleteDef = EditCellUse->cu_def;
  }

  /* pick a replacement def, for any windows that have editcell as root */
  dbTclCmdCellDeleteReplaceDef = NULL;
  DBCellSrDefs(0, dbTclCmdCellDeleteFunc1, (ClientData) deleteDef);

  if(!dbTclCmdCellDeleteReplaceDef)
  {
    MsgErrorF("Can't delete last buffer.\n", cmdName);
    CMD_RETURN(interp);
  }

  /* Reload windows with def as root */
  WindSearch(NULL, NULL, dbTclCmdCellDeleteFunc2, (ClientData) deleteDef); 

  /* Clear def contents, remove from symbol table and free it. 
   * (if def has references (uses) it is cleared but not removed)
   */
  DBCellDeleteDef(deleteDef);

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [cell]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellNew --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_new_DESC "create new cell"

#define db_cell_new_DOC "
usage:  db_cell_new [-not_available] [-drc_with_parent] [-internal] [-generated] [-no_undo] name [fileName]

If -not_available, the available flag is reset, which will cause Max 
to attempt to load the cell from disk when it is searched.

If fileName is given that is where the cell will be written when saved.

Internal cells are normally not written out to disk, and are not DRCed.
Generated cells are loaded via 'gcell_load' rather than reading from disk.

This command does not automatically load the new cell into the current window.
"

static int
dbTclCmdCellNew(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    char *name;
    char *fileName= NULL;
    bool internal = FALSE;
    bool generated = FALSE;
    bool drcWithParent = FALSE;
    bool noUndo = FALSE;
    bool available = TRUE;
    CellDef *def = NULL;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='d' && strncmp(*argv,"-drc_with_parent",length)==0)
      {
	argc--; argv++;
	drcWithParent = TRUE;
	continue;
      }
	
      if(c=='g' && strncmp(*argv,"-generated",length)==0)
      {
	argc--; argv++;
	generated = TRUE;
	continue;
      }

      if(c=='i' && strncmp(*argv,"-internal",length)==0)
      {
	argc--; argv++;
	internal = TRUE;
	continue;
      }

      if(c=='n' && strncmp(*argv,"-no_undo",MAX(4,length))==0)
      {
	argc--; argv++;
	noUndo = TRUE;
	continue;
      }

      if(c=='n' && strncmp(*argv,"-not_available",MAX(4,length))==0)
      {
	argc--; argv++;
	available = FALSE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* parse cell name */
    if(argc <= 0) goto usage;
    name = *argv;
    argc--; argv++;
    if(!DBCellNameCheck(name)) CMD_RETURN(interp);

    /* parse fileName */
    if(argc) 
    {
      fileName = *argv;
      argc--; argv++;
    }
    
    if(argc) goto usage;


    /* find or create cell */
    def = DBCellLookDef(name);
    if(def)
    {
      if (def->cd_flags & CD_AVAILABLE)
      {
	MsgErrorF("cell '%s' already exists!\n",name);
	CMD_RETURN(interp);
      }
      else
      {
	/* Buffer already exists but is unavailable,
	 * apparently because it is referenced as an instance.
	 * reinitial flags.
	 */
	def->cd_flags = 0;
      }
    }
    else
    {
      def = DBCellNewDef(name, (char *) NULL);
    }
    ASSERT(def != (CellDef *) NULL, "dbTclCmdCellNew");

    /* setup flags */
    if(available) DBCellSetAvail(def);
    if (drcWithParent) def->cd_flags |= CD_DRC_WITH_PARENT;
    if (generated) def->cd_flags |= CD_GENERATED;
    if (internal) def->cd_flags |= CD_INTERNAL;
    if (noUndo) def->cd_flags |= CD_NO_UNDO;
    if (fileName) def->cd_file = StrDup(NULL, fileName);

    /* if cell is referenced, propagate database changes */
    if(def->cd_refCnt) DBChangedArea(def, NULL, NULL, 0);

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-not_available] [-drc_with_parent] [-generated] [-internal] [-no_undo] name [fileName]\n", 
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdName2File --
 *
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_name2file_DESC "convert cell name to file name"
#define db_cell_name2file_DOC "
usage:  db_cell_name2file cellName

Max cell names and file names are generally identical, but a few 
special characters are mapped to avoid trouble:

  / -> {FS}
  \\ -> {BS}
  { -> {BC}
  } -> {EC}

Also initial '.' is mapped to {DT}
"

static int
dbTclCmdCellName2File(ClientData clientData, 
		      Tcl_Interp *interp, 
		      int argc, 
		      char **argv)
{
  char *cmdName;
  char *name;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {

/* NO SWITCHES YET
     if(c=='n' && strncmp(*argv,"-not_available",MAX(4,length))==0)
     {
       argc--; argv++;
       available = FALSE;
       continue;
     }
*/
    /* unrecognized option */
    goto usage;
  }

  /* parse name */
  if(argc <= 0) goto usage;
  name = *argv;
  argc--; argv++;
  if(!DBCellNameCheck(name)) CMD_RETURN(interp);

  /* should be no args left */
  if(argc) goto usage;

  /* do it */  
  {
    char buf[BUFSIZ];
    
    DBCellName2File(name, buf);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s cellName\n",
	    cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellSignature --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_signature_DESC "hash on contents of cell"

#define db_cell_signature_DOC "
usage:  db_cell_signature [-cell <cellName>]

Returns integer dependent on cell contents (ala CRC).
The intent is that if two cells have identical contents they
will have the same signature, while if they are different
they will almost certainly have different signatures.

(The same 'hash' function is used for version stamping gcells.)

If no -cell, defaults to editcell.
"

static int
dbTclCmdCellSignature(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
    }

    if(argc) goto usage;

    /* set result to hash */
    {
      char buf[BUFSIZ];
      VStamp vs = DBVStampHash(def);
      /* fprintf(stderr,"db_cell_signature cell=%s value=%d\n",
	 def->cd_name, vs.vs_time); */

      sprintf(buf,"%d", vs.vs_time);
      Tcl_SetResult(interp, buf, TCL_VOLATILE);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell <cellName>]\n", cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellReadOnly --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_read_only_DESC "control cell buffer read-only mode"

#define db_cell_read_only_DOC "
usage:  db_cell_read_only [-cell <cellName>] [value]

Returns 1 if cell buffer was read only otherwise 0 
(return value corresponds to state prior to this command.)

If value given, read-only mode is set/reset accordingly.
(value should be 0 or 1).

If no -cell, defaults to editcell.
"

static int
dbTclCmdCellReadOnly(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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

      fprintf(stderr,"TODO cell_read_only:  do set/reset.\n");
      /* unrecognized option */
      goto usage;
    }

    /* return current value */
    if(def->cd_flags & CD_READ_ONLY)
    {
      Tcl_SetResult(interp,"1", TCL_STATIC);  
    }
    else
    {
      Tcl_SetResult(interp,"0", TCL_STATIC);  
    }

    /* read arg, and set/reset accordingly */
    if(argc>0)
    {
      if(strcmp(*argv,"0")==0 || strcmp(*argv,"{}")==0)
      {
	def->cd_flags &= ~CD_READ_ONLY;
      }
      else if (strcmp(*argv,"1")==0)
      {
	def->cd_flags |= CD_READ_ONLY;
      }
      else
      {
	goto usage;
      }

      argc--; argv++;
    }

    if(argc) goto usage;
    
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell <cellName>] value\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellRead --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_read_DESC "read in cell from disk"

#define db_cell_read_DOC "
usage:  db_cell_read cellName [fileName]

cellName is the name of the cell to read

If fileName is given the cell is read from there,
else the MN_PATH_CELL is searched.

Returns:  filename cell was loaded from on success, {} on failure.

NOTE:  If filename is given, should be a complete pathname.
The name is stored as given with the cell buffer.  So
relative names could lead to trouble if the current directory 
is changed. 
"

static int
dbTclCmdCellRead(ClientData clientData, 
		 Tcl_Interp *interp, 
		 int argc, 
		 char **argv)
{
    char *cmdName = argv[0];
    char *cellName= NULL;
    char *fileName= NULL;
    CellDef *def;

    CMD_BEGIN(interp);

    /* parse args */
    {
      int i;

      /* flags */
      for (i=1; i<argc && argv[i][0] == '-'; i++)
      {
	/* no flags yet */
	goto badusage;
      }

      /* cellName arg */
      if(i==argc) goto badusage;
      cellName = argv[i++];

      /* fileName arg */
      if(i!=argc) fileName = argv[i++];

      if(i!=argc) goto badusage;
    }

    /* check that the cellName is legal */
    if(!DBCellNameCheck(cellName)) CMD_RETURN(interp);

    /* get cell def */
    def = DBCellLookDef(cellName);
    if(!def) def = DBCellNewDef(cellName,NULL);

    /* don't overload def */
    if(def->cd_flags &CD_AVAILABLE)
    {
      MsgErrorF("Cell read aborted, '%s' already loaded!\n",
		cellName);
      CMD_RETURN(interp);
    }

    /* set file name */
    if(fileName)
    {
      def->cd_file = StrDup(&def->cd_file,fileName);
    }

    /* do it */
    def->cd_flags |= CD_READ_RETRY; /* force retry */ 
    if(DBReadCell(def))
    {
      Tcl_SetResult(interp, def->cd_file, TCL_VOLATILE);
      CMD_RETURN(interp);
    }
    
    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s cellName [fileName]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellRename --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_rename_DESC "rename a cell"

#define db_cell_rename_DOC "
usage:  db_cell_rename oldName cellName fileName

cellName is the new name for the cell
fileName is where the cell will be written when saved.

NOTE: sets cell modified flag.
"

static int
dbTclCmdCellRename(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName = argv[0];
    char *oldName = NULL;
    char *cellName= NULL;
    char *fileName= NULL;
    bool internal = FALSE;
    CellDef *def;

    CMD_BEGIN(interp);

    /* parse */
    {
      int i;

      /* flags */
      for (i=1; i<argc && argv[i][0] == '-'; i++)
      {
	/* no flags yet */
	goto badusage;
      }

      /* positional args */
      if(i==argc) goto badusage;
      oldName = argv[i++];
      if(i==argc) goto badusage;
      cellName = argv[i++];
      if(i==argc) goto badusage;
      fileName = argv[i++];
      if(i!=argc) goto badusage;
    }

    /* find def */
    def = DBCellLookDef(oldName);
    if(!def) 
    {
      MsgErrorF("Can not rename cell '%s', not found!\n", oldName);
      CMD_RETURN(interp);
    }

    /* check that the new name is legal */
    if(!DBCellNameCheck(cellName)) CMD_RETURN(interp);

    /* if name hasn't change, just update the def filename */
    if(strcmp(cellName,def->cd_name)==0)
    {
      StrDup(&def->cd_file,fileName);
      def->cd_flags |= CD_MODIFIED;
      CMD_RETURN(interp);
    }

    /* Make sure cell doesn't already exists */
    if (DBCellLookDef(cellName))
    {
       MsgErrorF("cell '%s' already exists!\n",cellName);
       CMD_RETURN(interp);
    }

    /* Rename the cell */
    if (!DBCellRenameDef(def, cellName))
    {
	/* This should never happen */
	MsgErrorF("Max interal error: there is already a cell named \"%s\"\n",
		    cellName);
	CMD_RETURN(interp);
    }

    /* set the def filename */
    def->cd_file = StrDup(&def->cd_file,fileName);
    def->cd_flags |= CD_MODIFIED;

    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s oldName cellName fileName\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdCellFileTech --
 *
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_cell_file_tech_DESC "Look up technology of "

#define db_cell_file_tech_DOC "
usage:  db_cell_file_tech cellName 

Finds file for cellName in search path (MN_PATH_CELL), and returns
the technology associated with file
"

static int
dbTclCmdCellFileTech(ClientData clientData, Tcl_Interp *interp, 
		     int argc, char **argv)
{
    char *cmdName = argv[0];
    char *cellName= NULL;
    char *tech;

    CMD_BEGIN(interp);

    /* parse */
    {
      int i;

      /* flags */
      for (i=1; i<argc && argv[i][0] == '-'; i++)
      {
	/* no flags yet */
	goto badusage;
      }

      /* positional args */
      if(i==argc) goto badusage;
      cellName = argv[i++];
      if(i!=argc) goto badusage;
    }

    tech = DBGetTech(cellName);
    if(!tech) CMD_RETURN(interp);
    Tcl_SetResult(interp, tech, TCL_VOLATILE);

    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s cellName\n", cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdGCellNotify --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_gcell_notify_DESC "Notify database that gcell has been loaded"

#define db_gcell_notify_DOC "
usage:  db_gcell_notify cell_name

Sets appropriate versions in celldef for gcell, and   
does database change notification.
"

static int
dbTclCmdGCellNotify(ClientData clientData, Tcl_Interp *interp, 
		    int argc, char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      /* unrecognized option */
      goto usage;
    }

    /* parse cell name */
    if(argc==0) goto usage;
    def = DBCellLookDef(*argv);
    if(!def)
    {
      MsgErrorF("%s:  Couldn't find cell '%s'!\n",
		cmdName, *argv);
      CMD_RETURN(interp);
    }
    argc--; argv++;

    if(argc) goto usage;

    /* use hash based version stamp */
    {
      VStamp stamp = DBVStampHash(def);
      def->cd_version = stamp;
      def->cd_vMAIN = stamp;
      def->cd_vDRC = stamp;
    }

    /* mark need to compute bbox */
    def->cd_flags |= CD_CHANGED_BBOX;      

    /* clear modified flag */  
    def->cd_flags &= ~CD_MODIFIED;

    /* mark cell available (read in) */
    def->cd_flags |= CD_AVAILABLE;      

    /* propagate database changes */
    if(def->cd_refCnt)
    {
      DBChangedArea(def, NULL, NULL, DBCF_DEFREAD|DBCF_INSTANCE_ONLY);
    }
    else
    {
      DBChangedArea(def, NULL, NULL, DBCF_DEFREAD);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s cell_name]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdNotify --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_notify_DESC "Notify database of change to cell"

#define db_notify_DOC "
usage:  db_notify [-cell cell_name]

If no -cell, defaults to edit cell.

Does database change notification for cell.  This is needed only
if -no_notify options were used (see db_instance). 
"

static int
dbTclCmdNotify(ClientData clientData, Tcl_Interp *interp, 
	       int argc, char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
    }

    if(argc) goto usage;

    DBChangedArea(def, NULL, NULL, DBCF_INSTANCE_ONLY);
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell cell_name]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdBBox --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_bbox_DESC "get cells bounding box"

#define db_bbox_DOC "
usage:  db_bbox [-cell cell_name] [-user]

If no -cell, defaults to edit cell (and root cell coordinates)
If -cell option, outputs that cells bbox (in cells own coordinates).

Returns cells bounding box as: xbot ybot xtop ytop 

If -user, returns user bbox (displayed bbox).
"

static int
dbTclCmdBBox(ClientData clientData, Tcl_Interp *interp, 
	       int argc, char **argv)
{
  char *cmdName;
  bool cellArg = FALSE;
  bool user = FALSE;
  CellDef *def = EditCellUse->cu_def;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];
	
    if(c=='c' && strncmp(*argv,"-cell",length)==0)
    {
      argc--; argv++;

      cellArg = TRUE;
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

    if(c=='u' && strncmp(*argv,"-user",length)==0)
    {
      argc--; argv++;
      user = TRUE;

      continue;
    }

    /* unrecognized option */
    goto usage;
  }

  if(argc) goto usage;

  /* do it */
  {
    Rect r;  
    Rect *bbox = user ? DBUserBBoxCellDef(def) : DBBBoxCellDef(def);

    if(!cellArg)
    {
      /* transform bbox to root cell coordinates */
      GeoTransRect(&EditToRootTransform, bbox, &r);
      bbox = &r;
    }

    /* output bbox in user coords */
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_xbot));
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_ybot));
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_xtop));
    Tcl_AppendElement(interp, UnitsI2S(bbox->r_ytop));
  }

  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s [-cell cell_name] [-user]\n",
	    cmdName);
  CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdBBoxUserLayers --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_bbox_user_layers_DESC "get/set layers included in user bbox"

#define db_bbox_user_layers_DOC "
usage:  db_bbox_user_layers [layer_list] 

If layer_list is given (a ',' separated list of layers), 
use these layers to compute user bboxes, i.e, the displayed 
bboxes for cells.

To include subcells in user bbox computation, include the pseudo
layer 'subcell' in layer_list.

The user bbox is computed as follows:
  1. compute from layer_list, if non-empty use.
  2. Else, compute from subcell user bboxes, if non-empty use.
  3. Else, use actual bbox.

Returns list of layers in use prior to this command.
"

static int
dbTclCmdBBoxUserLayers(ClientData clientData, 
		       Tcl_Interp *interp, 
		       int argc, 
		       char **argv)
{
  char *cmdName;
  bool listArg = FALSE;
  TileTypeBitMask mask;

  CMD_BEGIN(interp);

  /* parse command name */
  cmdName = *argv;
  argc--; argv++;


  /* parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /*** NO SWITCHES YET
    if(c=='c' && strncmp(*argv,"-cell",length)==0)
    {
      argc--; argv++;

      cellArg = TRUE;
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
  }

  /* parse type list */
  if(argc)
  {
    listArg = TRUE;
    if(!CmdParseLayers(*argv, &mask)) CMD_RETURN(interp);
    argc--; argv++;
  }

  /* should be no args left */
  if(argc) goto usage;

  /* set result to current user layers */
  {
    char buf[BUFSIZ];

    if(!dbBBoxUserTypes2S(buf, BUFSIZ))
    {
      MsgWarnF("%s:  result too long (truncated)!\n",
	       cmdName);
    }

    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  /* do the set */
  if(listArg) dbBBoxSetUserPlanes(&mask);

  CMD_RETURN(interp);

usage:
  MsgErrorF("usage: %s [layer_list] [-user]\n",
	    cmdName);
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdFlyLine --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_flyline_DESC "add a fly line to the editcell"

#define db_flyline_DOC "
usage:  
  db_flyline [-delete] [-text text] [-width n] [[hier_label_name1] hier_label_name2] 

no names - lists all fly lines in cell.
one name - lists all fly lines in cell connecting to named label.
two names - creates fly line between named labels.

Flylines can be terminated inside instances via hierarchical names,
e.g. 'foo_0/bar'.  In addition flylines can be terminated at the center
or sides of an instance with the following special names:  
  {*center*}
  {*left*}
  {*right*}
  {*top*}
  {*bottom*}
For example to terminate a flyline at the center of an instace foo_0,
use the name 'foo_0/{*center*}'.

if \"-text text\": display text with flyline.
if \"-width n\": make flyline n pixels wide (default is 1).

if \"-delete\":
no names - delete all fly lines in cell.
one name - delete all fly lines in cell connecting to named label.
two names - delete fly line between named labels.

output format:  name1 name2 text width
"

/* helper func, appends fly line to result */
static void dbFlyLineListProc(Tcl_Interp *interp, FlyLine *fl)
{
        Tcl_AppendResult(interp, "flyline", NULL);
        Tcl_AppendElement(interp, fl->fl_name1);
        Tcl_AppendElement(interp, fl->fl_name2);
	Tcl_AppendElement(interp, 
			   fl->fl_text ? fl->fl_text : "");
	{
	  char buf[BUFSIZ];
	  sprintf(buf,"%d",fl->fl_width);

	  Tcl_AppendElement(interp, buf);
	}
	   
        Tcl_AppendResult(interp, "\n", NULL);
}

static int
dbTclCmdFlyLine(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CellDef *def = EditCellUse->cu_def;
    char *cmdName;
    bool delete = FALSE;
    char *text = NULL;
    int width = 1;
    char *name1 = NULL;
    char *name2 = NULL;
    char nameBuf1[BUFSIZ];
    char nameBuf2[BUFSIZ];
    
    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='d' && strncmp(*argv,"-delete",length)==0)
      {
	argc--; argv++;
	delete = TRUE;

	continue;
      }

      if(c=='t' && strncmp(*argv,"-text",length)==0)
      {
	argc--; argv++;

	if(!argc) goto usage;
	text = *argv;
	argc--; argv++;

	continue;
      }

      if(c=='w' && strncmp(*argv,"-width",length)==0)
      {
	char *end;
	argc--; argv++;

	if(!argc) goto usage;
	width = strtol(*argv,&end,10);
	if(*end!='\0') goto usage;
	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;

    } /* end while(argc>0 && **argv=='-')  */

    /* parse name1 */
    if(argc!=0)
    {
      if(!DBInstanceParsePath(*argv,nameBuf1)) goto usage; 
      name1 = nameBuf1;
      argc--; argv++;
    }
      
    /* parse name2 */
    if(argc!=0)
    {
      if(!DBInstanceParsePath(*argv,nameBuf2)) goto usage; 
      name2 = nameBuf2;
      argc--; argv++;
    }

    /* should be no args left */
    if(argc>0) goto usage;

    /* delete */
    if(delete)
    {
      /* check for read-only */
      if(dbFlylinesSave && !DBAccessModify(def)) CMD_RETURN(interp);
      
      /* null names act as wild card */ 
      dbFlyLineDelete(def,name1,name2);

      /* redisplay update triggered by call to DBFlylineDraw() */
      if(dbFlylinesSave) def->cd_flags |= CD_MODIFIED;

      CMD_RETURN(interp);
    }

    /* add */
    if(name1 && name2)
    {
      /* check for read-only */
      if(dbFlylinesSave && !DBAccessModify(def)) CMD_RETURN(interp);

      dbFlyLineAdd(def,name1,name2,width,text);

      /* redisplay update triggered by call to DBFlylineDraw() */
      if(dbFlylinesSave) def->cd_flags |= CD_MODIFIED;

      CMD_RETURN(interp);
    }

    /* list all flylines attached to label */
    if(name1)
    {
      FlyLine *fl;

      for(fl=def->cd_flyLines; fl; fl=fl->fl_next)
      {
	if(strcmp(fl->fl_name1,name1)==0 ||
	   strcmp(fl->fl_name2,name1)==0) 
	{
	  dbFlyLineListProc(interp,fl);
	}
      }
      CMD_RETURN(interp);
    }

    /* list all */
    {
      FlyLine *fl;

      for(fl=def->cd_flyLines; fl; fl=fl->fl_next)
      {
	dbFlyLineListProc(interp,fl);
      }

      CMD_RETURN(interp);
    }

usage:
    MsgErrorF("usage: %s [-delete] [-text text] [-width n] [[hier_label_name1] hier_label_name2]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdGroup --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_group_DESC "set the active group in current edit cell"

#define db_group_DOC "
usage:  db_group [<group_name>|0 [<group_class>] ] 

if no arg, returns current active group in edit cell.
if arg given sets active group to it (creating new group if it doesn't already exist).
special arg of 0 designates no group (the default). 
if type given AND new group, sets to type. (TODO fix this kludge). 


Paint operations are to active group.  
\"select -g\" operations are restricted to active group.
"

static int
dbTclCmdGroup(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName=argv[0];
    char *name= NULL;
    char *class= NULL;
    GroupClass *gc = NULL;
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
      if(i<argc) name = argv[i++];
      if(i<argc) class = argv[i++];

      /* check that no args left over */
      if(i!=argc) goto badusage;
    }

    /* look up group class */
    if(class)
    {
        gc = DBGroupClassFromName(class);
	if(!gc)
	{
	    MsgErrorF("Unrecognized group class: %s\n", class); 
            CMD_RETURN(interp);
	 }
    }

    /* do the set */ 
    if(name)
    {
      if(strcmp(name,"0")==0) 
      {
	cell->cd_activeGroup=NULL;
      }
      else
      {
        Group *g = DBGroupFromName(cell,name);

        if(!g)
	{
	  g = DBGroupNew(EditCellUse->cu_def,name);
	  g->g_class = gc;
	}

	cell->cd_activeGroup=g;
      }
    }

    /* return current group */
    Tcl_SetResult(interp, 
		  cell->cd_activeGroup?cell->cd_activeGroup->g_name:"0", 
		  TCL_VOLATILE);
    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s [<group_name>|0 [<group_type>]]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdGroupClass --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_group_class_DESC "define/list group classes"

#define db_group_class_DOC "
usage:  db_group_class [<name>]

if no arg, returns list of group classes.
if arg present, defines a group class by that name.
"

static int
dbTclCmdGroupClass(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName=argv[0];
    char *name= NULL;


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
      if(i<argc) name = argv[i++];

      /* check that no args left over */
      if(i!=argc) goto badusage;
    }

    if(name)
    {
      /* define new group class */

      if(DBGroupClassFromName(name))
      {
	MsgErrorF("%s: group class '%s' already exists!\n", cmdName, name);
	CMD_RETURN(interp);
      }
      DBGroupClassNew(name);
    }
    else
    {

      /* list existing group types */
      MsgErrorF("%s: Group listing N/Y/I.\n", cmdName);
    }

    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s [<name>]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdGroupAttribute --
 *
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_group_attribute_DESC "get/set attribute of current group"

#define db_group_attribute_DOC "
usage:  db_group_attriubute [ [<attribute_name>] [<value>] ]

if no args lists all attribute value pairs for current group.
if only attribute_name given, returns current value.
if attribute_name and value given, sets attribute_name to value.
"

static int
dbTclCmdGroupAttribute(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName=argv[0];
    char *name= NULL;
    char *value= NULL;
    Group *group = EditCellUse->cu_def->cd_activeGroup;

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
      if(i<argc) name = argv[i++];
      if(i<argc) value = argv[i++];

      /* check that no args left over */
      if(i!=argc) goto badusage;
    }

    if(!group)
    {
      MsgErrorF("%s: Group 0 can not have attributes.\n", cmdName, name);
      CMD_RETURN(interp);
    }

    if(name && value)
    {
      /* set */
      DBGroupAttributeSet(group, name, value);
    }
    else if (name)
    {
      /* get */
      char *v = DBGroupAttributeGet(group, name);
      if(!v) v = "";
      Tcl_SetResult(interp, v, TCL_VOLATILE);
    }
    else
    {
      /* list */
      MsgErrorF("%s: Group Attribute listing N/Y/I.\n", cmdName);
    }

    CMD_RETURN(interp);

badusage:
    MsgErrorF("usage: %s [ <name> [value]]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdLabel --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_label_DESC "add (or delete) a label"

#define db_label_DOC "
usage:  db_label [options] layer text x0 y0 [x1 y1]

add a label on the given layer.

options:

-cell cell_name

  If -cell, paint into cell_name (coordinates are in terms of cell_name).
  If no -cell, paint into edit cell (coordinates are in terms of root cell)

-no_notify

  If -no_notify, don't notify database that cell has changed.  FOR INTERNAL
  USE ONLY, DO NOT USE (CAN CAUSE COREDUMPS)!

-kind comment|hidden|local|global|input|output|inout

  If no -kind, defaults to comment.

-pos n|s|e|w|ne|nw|se|sw|center

  -pos specifies text position with respect to label point or area.

 -delete
   delete the specified label
   (-kind and -pos options ignored on delete)

"

static int
dbTclCmdLabel(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    int type; /* layer */
    char *text;
    Rect r;
    bool notify = TRUE; 
    bool delete = FALSE;
    CellDef *def = NULL;
    int kind = LAB_COMMENT;
    int pos = -1;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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

      if(c=='d' && strncmp(*argv,"-delete",length)==0)
      {
	argc--; argv++;

	delete = TRUE;
	continue;
      }
	
      if(c=='k' && strncmp(*argv,"-kind",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	kind = DBLabelKindParse(*argv);
	if(kind<0) goto usage;
	argc--; argv++;

	continue;
      }

      if(c=='n' && strncmp(*argv,"-no_notify",length)==0)
      {
	argc--; argv++;

	notify = FALSE;
	continue;
      }

      if(c=='p' && strncmp(*argv,"-pos",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	pos = GeoNameToPos(*argv, FALSE, TRUE);
	if(pos<0) goto usage; 

	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* parse layer */
    if(argc == 0) goto usage;
    type = DBTechNameType(*argv);
    if(type==-1) 
    {
      MsgErrorF("Ambiguous layer:  '%s'.\n", *argv);
      CMD_RETURN(interp);
    }
    if(type==-2) 
    {
      MsgErrorF("Unknown layer:  '%s'.\n", *argv);
      CMD_RETURN(interp);
    }
    argv++; argc--;

    /* parse text */
    if(argc == 0) goto usage;
    text = *argv;
    argv++; argc--;
    if(!DBLabelNameCheck(text)) goto usage;

    /* parse xbot */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    r.r_xbot = UnitsS2I(*argv);
    argv++; argc--;

    /* parse ybot */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    r.r_ybot = UnitsS2I(*argv);
    argv++; argc--;

    if(argc == 0) 
    {
      /* point label */ 
      r.r_xtop = r.r_xbot;
      r.r_ytop = r.r_ybot;
    }
    else
    {
      /* parse xtop */
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      r.r_xtop = UnitsS2I(*argv);
      argv++; argc--;

      /* parse ytop */
      if(argc<=0) goto usage;
      if (!UnitsValidSF(*argv)) 
      {
	MsgErrorF("bad coordinate: %s\n", *argv);
	goto usage;
      }
      r.r_ytop = UnitsS2I(*argv);
      argv++; argc--;
    }

    if(argc) goto usage;

    /* default def to edit cell */
    if(!def)
    {
      Rect tmp;

      def = EditCellUse->cu_def;
      GeoTransRect(&RootToEditTransform, &r, &tmp);
      r = tmp;

      pos = GeoTransPos(&RootToEditTransform, pos);
    }

    /* check for read-only */
    if(!DBAccessModifyType(def,type)) CMD_RETURN(interp);

    /* doit */
    if(delete)
    {
      DBLabelsEraseByContent(def, &r, type, text);
      /* TODO error message if label not found. */
    }
    else
    {
      DBLabelAdd(def, &r, pos, text, type, kind);
    }

    /* change notification */
    if(notify)
    {
      DBChangedArea(def, &r, NULL, DBCF_LABEL_ONLY);          
    }

    CMD_RETURN(interp);
usage:
    MsgErrorF("usage: %s [options] layer text x0 y0 x1 y1\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdPaint --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_paint_DESC "paint a rectangle"

#define db_paint_DOC "
usage:  db_paint [-cell cell_name] [-erase] [-no_notify] layer x0 y0 x1 y1

Paint rectangle on given layer.

If -erase, the given layer is erased instead of painted.

If -cell, paint into cell_name (coordinates are in terms of cell_name).
If no -cell, paint into edit cell (coordinates are in terms of root cell)

If -no_notify, don't notify database that cell has changed.  FOR INTERNAL
USE ONLY, DO NOT USE (CAN CAUSE COREDUMPS)!

NOTE:  paint/erase operations clear the selection.

"

static int
dbTclCmdPaint(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    int type; /* layer */
    Rect r;
    bool notify = TRUE; 
    bool erase = FALSE; 
    CellDef *def = NULL;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
	
      if(c=='e' && strncmp(*argv,"-erase",length)==0)
      {
	argc--; argv++;

	erase = TRUE;
	continue;
      }
	
      if(c=='n' && strncmp(*argv,"-no_notify",length)==0)
      {
	argc--; argv++;

	notify = FALSE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }
	
    /* parse type (layer) */
    if(argc == 0) goto usage;

    type = DBTechNameType(*argv);
    if(type==-1) 
    {
      MsgErrorF("Ambiguous layer:  '%s'.\n", *argv);
      CMD_RETURN(interp);
    }
    if(type==-2) 
    {
      MsgErrorF("Unknown layer:  '%s'.\n", *argv);
      CMD_RETURN(interp);
    }
    argv++; argc--;

    /* parse xbot */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    r.r_xbot = UnitsS2I(*argv);
    argv++; argc--;

    /* parse ybot */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    r.r_ybot = UnitsS2I(*argv);
    argv++; argc--;

    /* parse xtop */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    r.r_xtop = UnitsS2I(*argv);
    argv++; argc--;

    /* parse ytop */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    r.r_ytop = UnitsS2I(*argv);
    argv++; argc--;

    if(argc) goto usage;

    /* default def to edit cell */
    if(!def)
    {
      Rect tmp;

      def = EditCellUse->cu_def;
      GeoTransRect(&RootToEditTransform, &r, &tmp);
      r = tmp;
    }

    /* check for read-only */
    if(!DBAccessModifyType(def,type)) CMD_RETURN(interp);

    /* do it */ 
    if(erase)
    {
      DBErase(def, &r, type);
    }
    else
    {
      DBPaint(def, &r, type);
    }

    if(!(def->cd_flags&CD_INTERNAL) && !(def->cd_flags&CD_GENERATED))
    {
      SelectClear();
    }

    /* change notification */
    if(notify)
    {
      TileTypeBitMask mask;
      
      TTMaskSetOnlyType(&mask, type);
      DBChangedArea(def, &r, &mask, 0);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-erase] [-no_notify] layer x0 y0 x1 y1\n",
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdInstance --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_instance_DESC "create a cell instance"

#define db_instance_DOC "
usage:  db_instance [-cell cell_name] [-dup_ok] [-no_notify] [-orientation orientation] [-id instance_name] subcell_name x0 y0

Add an instance of def_name with origin at x0 y0.
Returns the name of the new instance, or NIL on failure.

If -cell, add instance to cell_name (coordinates are in terms of cell_name).
If no -cell, add instance to edit cell (coordinates are in terms of root cell)

If -dup_ok, allows duplicate instance to be placed on exact copy
(Should eventually be followed by selecting instance and 'sel_move 0 0'
to check for duplicates)

If -no_notify, don't notify database that cell has changed (must do
explicit notify later).  FOR INTERNAL USE ONLY, DO NOT USE 
(CAN CAUSE COREDUMPS)!

orientation is one of: {}, r90, r180, r270, fx, fy, fx_r90, fy_r90

If no '-id', picks unique instance name.

NOTE:  Max is load on-demand.  db_instance does not load the referenced subcell 
into memory!  However if the drc is on, the background checker will likely
reference the cell causing a load to be attempted, potentially generating
a Cell not-found error message asynchronously.
"
int dbTclCmdInstance(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    Point p;
    Transform *orientation = &GeoIdentityTransform;
    bool dupOK = FALSE;
    bool notify = TRUE; 
    char *id = NULL;
    char *subCellDefName;
    CellDef *subCellDef;
    CellUse *subCellUse;
    CellDef *def = NULL;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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

      if(c=='d' && strncmp(*argv,"-dup_ok",length)==0)
      {
	argc--; argv++;

	dupOK = TRUE;
	continue;
      }

      if(c=='i' && strncmp(*argv,"-id",length)==0)
      {
	argc--; argv++;

	if(argc<1) goto usage;
	id = *argv;
	argc--; argv++;
	if(!DBInstanceNameCheck(id)) CMD_RETURN(interp);
	continue;
      }
	
      if(c=='n' && strncmp(*argv,"-no_notify",length)==0)
      {
	argc--; argv++;

	notify = FALSE;
	continue;
      }
	
      if(c=='o' && strncmp(*argv,"-orientation",length)==0)
      {
	argc--; argv++;

	if(argc<=0) goto usage;
	orientation = GeoNameToTrans(*argv,TRUE);
	argc--; argv++;
	if((int) orientation <= 0) goto usage;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }
	
    /* parse subcell name */
    if(argc==0) goto usage;
    subCellDefName = *argv;
    argc--; argv++;

    /* parse x0 */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    p.p_x = UnitsS2I(*argv);
    argv++; argc--;

    /* parse y0 */
    if(argc<=0) goto usage;
    if (!UnitsValidSF(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    p.p_y = UnitsS2I(*argv);
    argv++; argc--;

    if(argc) goto usage;

    /* default def to edit cell */
    if(!def)
    {
      Point tmp;

      def = EditCellUse->cu_def;
      GeoTransPoint(&RootToEditTransform, &p, &tmp);
      p = tmp;
    }

    /* check for read-only */
    if(!DBAccessModify(def)) CMD_RETURN(interp);

    /* find subcell def
     *
     * if subcell def doesn't exist, create a skeleton def
     * with CD_AVAILABLE reset.
     */
    subCellDef = DBCellLookDef(subCellDefName);
    if(!subCellDef)
    {
      subCellDef = DBCellNewDef(subCellDefName, (char *) NULL);

      /* generated? */
      if(*subCellDefName == '#') DBReadCell(subCellDef);
    }

    /* create celluse */
    subCellUse = DBCellUseNew(subCellDef, id);

    /* set transform  (to orientation + translation) */
    {
      Transform t;
      GeoTranslateTrans(orientation, p.p_x, p.p_y, &t);
      DBCellUseSetTrans(subCellUse, &t);
    }

    /* create instance */
    /* ( on failure DBInstanceAdd() calls DBCellUseDelete() )*/
    {
      int flags = dupOK ? DBIA_DUP_OK : 0;
      if(!DBInstanceAdd(subCellUse, def, flags))  CMD_RETURN(interp);
    }

    /* change notification */
    if(notify)
    {
      DBChangedArea(def, 
		    &subCellUse->cu_bbox, 
		    &DBAllButSpaceBits, 
		    DBCF_INSTANCE_ONLY);
    }

    /* if gcell, expand it */
    /* NOTE: may cause tcl code to be run (to generate gcell), thus trashing tcl return
     * value, so return value must be set AFTER this code.
     */
    if(subCellDef->cd_flags&CD_GENERATED) 
    {
      DBExpand(subCellUse, LAY_ALL_WINDOWS, TRUE); 
    }

    /* return id of new instance (must be after DBExpand above) */
    Tcl_SetResult(interp, 
		  subCellUse->cu_id ? subCellUse->cu_id : "", 
		  TCL_VOLATILE);

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-dup_ok] [-no_notify] [-orientation orientation] [-id instance_name] subcell_name x0 y0\n",
	      cmdName);
    CMD_RETURN(interp);
}




/*
 *--------------------------------------------------------------
 *
 * dbTclCmdInstanceDelete --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_instance_delete_DESC "delete a cell instance"

#define db_instance_delete_DOC "
usage:  db_instance_delete [-cell cell_name] instance_id

delete given instance.

If -cell, delete instance from specified cell.
If no -cell, delete instance from current edit cell.

If -no_notify, don't notify database that cell has changed (must do
explicit notify later).  FOR INTERNAL USE ONLY, DO NOT USE 
(CAN CAUSE COREDUMPS)!
"
int dbTclCmdInstanceDelete(ClientData clientData, 
			   Tcl_Interp *interp, 
			   int argc, 
			   char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;
    char *id;
    CellUse *cu; /* inst to delete */
    Rect area;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
    }
	
    /* parse instance id */
    if(argc==0) goto usage;
    id = *argv;
    argc--; argv++;

    /* should be no args left */
    if(argc) goto usage;

    /* check for read-only */
    if(!DBAccessModify(def)) CMD_RETURN(interp);

    /* find instance */
    cu = DBInstanceFindByName(id,def);
    if(!cu)
    {
      MsgErrorF("%s:  Could not find instance %s in cell %s!\n",
		cmdName,
		id,
		def->cd_name);
      CMD_RETURN(interp);
    }

    /* stash area changed */
    area = cu->cu_bbox;

    /* delete instance */
    DBInstanceDelete(cu);

    /* change notification */
    DBChangedArea(def, 
		  &area,
		  &DBAllButSpaceBits, 
		  DBCF_INSTANCE_ONLY);


    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] instance_id\n",
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdInstancesL --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_instances_l_DESC "list instance info"

#define db_instances_l_DOC "
usage:  db_instances [-cell cell_name] [-of def_name] [-id instance_name] 

Returns following for each instance in cell:
  {instanceName defName xbot ybot xtop ytop path expansion transform arrayInfo}

NOTE: path currently empty ({}), included so output format matches 
      'sel_what cells' and 'db_search cells'

If -cell, list instances in given cell rather than edit cell
If no -cell, defaults to edit cell.

If -id, list only instance of that id.

If -of, only list instances of def_name
"

/* add one use to result list */
void dbTclCmdInstancesList(Tcl_Interp *interp, 
			   Tcl_Obj *list, 
			   CellUse *use)
{
  Tcl_Obj *l1 = Tcl_NewListObj(0,0);

  /* id */
  TListAppendStr(interp, l1, use->cu_id);

  /* def name */
  TListAppendStr(interp, l1, use->cu_def->cd_name);

  /* bbox in user coordinates */
  {
    Rect *bbox = DBBBoxCellUse(use);

    TListAppendStr(interp, l1, UnitsI2S(bbox->r_xbot));
    TListAppendStr(interp, l1, UnitsI2S(bbox->r_ybot));
    TListAppendStr(interp, l1, UnitsI2S(bbox->r_xtop));
    TListAppendStr(interp, l1, UnitsI2S(bbox->r_ytop));
  }

  /* output nil "path" so output matches 
   *   "sel_what cells" and 
   *   "db_search cells"
   */
  TListAppendStr(interp, l1, "");

  /* output expansion status */
  TListAppendStr(interp, l1, 
		 DBIsExpand(use, LayCurWindow()->lay_bitmask) ?
		 "expanded":"");

  /* transform */
  {
    Transform *trans = &use->cu_transform;

    Tcl_Obj *lt = Tcl_NewListObj(0,0);

    TListAppendInt(interp, lt, trans->t_a);
    TListAppendInt(interp, lt, trans->t_b);
    TListAppendStr(interp, lt, UnitsI2S(trans->t_c));
    TListAppendInt(interp, lt, trans->t_d);
    TListAppendInt(interp, lt, trans->t_e);
    TListAppendStr(interp, lt, UnitsI2S(trans->t_f));

    TListAppendObj(interp,l1,lt);
  }

  /* array info */
  {
    Tcl_Obj *la = Tcl_NewListObj(0,0);

    if(DBIsArray(use))
    {
      ArrayInfo *ar = &use->cu_array;

      TListAppendInt(interp, la, ar->ar_xlo);
      TListAppendInt(interp, la, ar->ar_xhi);
      TListAppendInt(interp, la, ar->ar_ylo);
      TListAppendInt(interp, la, ar->ar_yhi);
      TListAppendStr(interp, la, UnitsI2S(ar->ar_xsep));
      TListAppendStr(interp, la, UnitsI2S(ar->ar_ysep));
    }

    TListAppendObj(interp,l1,la);
  }

  TListAppendObj(interp,list,l1);
}

int dbTclCmdInstancesL(ClientData clientData, 
		       Tcl_Interp *interp, 
		       int argc, 
		       char **argv)
{
    char *cmdName;
    CellDef *def = EditCellUse->cu_def;
    CellDef *of = NULL;
    char *id = NULL;
    Tcl_Obj *result;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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

      if(c=='i' && strncmp(*argv,"-id",length)==0)
      {
	argc--; argv++;

	if(argc<1) goto usage;
	id = *argv;
	argc--; argv++;
	continue;
      }

      if(c=='o' && strncmp(*argv,"-of",length)==0)
      {
	argc--; argv++;

	if(argc==0) goto usage;
	of = DBCellLookDef(*argv);
	if(!of) CMD_RETURN(interp);
	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* on positional args */
    if(argc) goto usage;

    /* initial result list */
    result = Tcl_NewListObj(0,0);

    if(id)
    {
      /* -id CASE */

      CellUse *use;

      use = DBInstanceFindByName(id, def);
      if(!use) CMD_RETURN(interp);

      if(!of || use->cu_def == of)
      {
	dbTclCmdInstancesList(interp, result, use);
      }
    }
    else if(of)
    {
      /* -of CASE */

      CellKid *kid = IHashLookUp(def->cd_kidHash, &of); 

      if(kid)
      {
	CellUse *use;

	for(use=kid->ck_uses; use; use=use->cu_next)
	{
	  dbTclCmdInstancesList(interp, result, use);
	}
      }
    }
    else
    {
      /* general CASE */

      CellKid *kid;
      CellUse *use;

      for(kid = def->cd_kids; kid; kid= kid->ck_next)
      {
	for(use=kid->ck_uses; use; use=use->cu_next)
	{
	  dbTclCmdInstancesList(interp, result, use);
	}
      }
    }

    Tcl_SetObjResult(interp,result);
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-of def_name] [-id instance_name]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdProp --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_prop_DESC "get/set celldef property"

#define db_prop_DOC "
usage:  db_prop [-def def_name] [-delete] [prop_name [prop_value]]

if no -def, defaults to edit cell.
if -delete, deletes given property.
if no args lists all property names
if name but not value, returns current value of property
if property name and value, does set.
"

/* helper func for listing properties */
static Tcl_Interp *dbTclCmdPropInterp;
static bool dbTclCmdPropFirst;
static void dbTclCmdPropEnumFunc(char *name, char *value)
{
  if(dbTclCmdPropFirst)
  {
    dbTclCmdPropFirst = FALSE;
  }
  else
  {
    Tcl_AppendResult(dbTclCmdPropInterp, "\n", (char *) NULL);

  }

  Tcl_AppendElement(dbTclCmdPropInterp, name);

}

static int
dbTclCmdProp(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    bool delete = FALSE;
    char *name= NULL;
    char *value= NULL;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='d' && strncmp(*argv,"-delete",MAX(length,4))==0)
      {
	argc--; argv++;
	delete = TRUE;
	continue;
      }

      if(c=='d' && strncmp(*argv,"-def",MAX(length,4))==0)
      {
	argc--; argv++;
	
	if(argc==0) goto usage;
	def = DBCellLookDef(*argv);
	if(!def)
	{
	  MsgErrorF("%s:  Couldn't find def '%s'!\n",
		  cmdName, *argv);
	  CMD_RETURN(interp);
	}
	argc--; argv++;

	continue;
      }

      /* unrecognized option */
      goto usage;
    }
	
    /* parse name */
    if(argc) 
    {
      name = *argv;
      argc--; argv++;
    }
	
    /* parse value */
    if(argc) 
    {
      value = *argv;
      argc--; argv++;
    }

    /* -delete case */
    if(delete)
    {
      if(!name)
      {	
	MsgErrorF("%s:  -delete option requires prop_name argument!\n",
		  cmdName);
	CMD_RETURN(interp);
      }

      /* check for read-only */
      if(!DBAccessModify(def)) CMD_RETURN(interp);

      DBPropSet(def, name, NULL);
      def->cd_flags |= CD_MODIFIED;

      CMD_RETURN(interp);
    }
       
    if(name && value)
    {
      /* check for read-only */
      if(!DBAccessModify(def)) CMD_RETURN(interp);

      /* set */
      DBPropSet(def, name, value);
      def->cd_flags |= CD_MODIFIED;
    }
    else if (name)
    {

      /* get */
      char *v = DBPropGet(def, name);
      if(!v) v = "";
      Tcl_SetResult(interp, v, TCL_VOLATILE);
    }
    else
    {
      dbTclCmdPropInterp = interp;
      dbTclCmdPropFirst = TRUE;
      DBPropEnum(def,dbTclCmdPropEnumFunc);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-def def_name] [-delete] [prop_name [prop_value]]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdStatPaint --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_stat_paint_DESC "get statistics on paint in cell"

#define db_stat_paint_DOC "
usage:  db_stat_paint [-cell cell_name] [-verbose]

If no -cell option, defaults to edit cell.

Returns,
   'paint_summary' mem_usage num_tiles num_space_tiles

If -verbose, also returns, for each plane, a line of the form:
   plane_name mem_usage num_tiles num_space_tiles numTiles numOps

mem_usage = total memory usage of the paint plane (in bytes)
num_tiles = total number of tiles in the paint planes 
num_space_tiles = number of space tiles in the paint plane 
num_allocs = number of tile allocs for plane
num_frees  = number of tile frees for plane

NOTE:  4 tiles at infinity for each paint plane are included in num_tiles
but not num_space_tiles.
"

static int
dbTclCmdStatPaint(ClientData clientData, 
		  Tcl_Interp *interp, 
		  int argc, 
		  char **argv)
{
    char *cmdName;
    bool verbose = FALSE;
    CellDef *def = NULL;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
	
      if(c=='v' && strncmp(*argv,"-verbose",length)==0)
      {
	argc--; argv++;

	verbose = TRUE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* should be no args left */
    if(argc) goto usage;

    /* default def to edit cell */
    if(!def) def = EditCellUse->cu_def;

    /* compile stats plane by plane (and output */
    {
      int grandMem = 0;
      int grandTiles = 0;
      int grandSpace = 0;
      int pNum;

      /* for each paint plane ... */
      for (pNum = 1; pNum < DBNumPlanes; pNum++)
      {
	int counts[TT_MAXTYPES];
	int mem;
	int total=0;
	int t;
	Plane *plane;

	plane= def->cd_planes[pNum];
	mem = DBstatPaintPlane(plane,counts);
	for(t=0;t<DBNumTypes;t++) total += counts[t];
	total += 4; /* tiles at infinity */

	grandMem += mem;
	grandTiles += total;
	grandSpace += counts[TT_SPACE];

	if(verbose)
	{
	  char buf[BUFSIZ];

	  sprintf(buf,"%s %d %d %d %g %g\n",
		  DBPlaneShortName(pNum),
		  mem,
		  total,
		  counts[TT_SPACE],
		  plane->pl_numAllocs,
		  plane->pl_numFrees);

	  Tcl_AppendResult(interp,buf,NULL);
	}
      }

      /* summary */
      {
	char buf[BUFSIZ];

	sprintf(buf,"paint_summary %d %d %d\n",
		grandMem,
		grandTiles,
		grandSpace);

	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-verbose]\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdStatInstances --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_stat_instances_DESC "get statistics on instances in cell"

#define db_stat_instances_DOC "
usage:  db_stat_instances [-cell cell_name] [-verbose]  | -bplane] 

returns: 
  instance_summary memory num_instances num_defs 

  memory = total bytes for representting instances in this cell
  num_instances = total number of instances in this cell
  num_defs = number of distinct defs of which there are instances in
             this cell.

If -verbose,
  returns more detailed info.

If -bplane
  returns instance bplane info instead.

If no -cell option, defaults to edit cell.
"

static int
dbTclCmdStatInstances(ClientData clientData, 
		      Tcl_Interp *interp, 
		      int argc, 
		      char **argv)
{
    char *cmdName;
    bool verbose = FALSE;
    bool bplane = FALSE;
    CellDef *def = NULL;
    int totMem = 0;
    int numUses = 0;
    int numDefs = 0; 

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
	
      if(c=='b' && strncmp(*argv,"-bplane",length)==0)
      {
	argc--; argv++;

	bplane = TRUE;
	continue;
      }
	
      if(c=='v' && strncmp(*argv,"-verbose",length)==0)
      {
	argc--; argv++;

	verbose = TRUE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* should be no args left */
    if(argc) goto usage;

    /* default def to edit cell */
    if(!def) def = EditCellUse->cu_def;

    /* handle bplane option separately */
    if(bplane) 
    {
      BPlane *bp = def->cd_cellPlane;
      unsigned int mem;
      int count;           /* ret num of elements in bplane */
      int inBox;           /* ret num of elements in inBox */
      int totBins;
      int emptyBins;       /* ret number of empty bins */
      int binArrays;       /* ret number of bin arrays */
      int maxEff;
      int maxBinCount;     /* ret max count for regular bin */
      int totUnbinned;
      int maxDepth;
    
      mem = BPStat(bp,
		   &count,
		   &inBox,
		   &totBins,
		   &emptyBins,
		   &binArrays,
		   &maxEff,
		   &maxBinCount, 
		   &totUnbinned,
		   &maxDepth);

      /* set result */
      {
	char buf[BUFSIZ];
	sprintf(buf,
		"{memory %d} "
		"{numElements %d} "
		"{inBox %d} "
		"{numBins %d} "
		"{emptyBins %d} "
		"{binArrays %d} "
		"{maxEffective %d} " 
		"{maxBinCount %d} "
		"{unbinned %d} "
		"{maxDepth %d} "
		"\n",
		mem, count, inBox, totBins, emptyBins, binArrays,
		maxEff, maxBinCount, totUnbinned, maxDepth);

	Tcl_SetResult(interp, buf, TCL_VOLATILE);                    
      }

      CMD_RETURN(interp);
    }

    /* cell plane stats */
    {
      int mem = -1;
      int numTiles = -1;
      int numBodies = -1;
      
      mem = DBstatCellPlane(def,&numTiles,&numBodies);
      totMem += mem;
      
      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"cell_plane %d %d %d\n",
		mem,
		numTiles,
		numBodies);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* uses */
    {
      int memUses = 0;
      int memIds = 0;
      CellKid *kid;


      for(kid=def->cd_kids; kid; kid=kid->ck_next)
      {
	CellUse *use;

	for(use=kid->ck_uses; use; use=use->cu_next)
        {
	  numUses++;
	  if(DBIsArray(use))
	  {
	    memUses += UtlsStatMallocMem(sizeof(CellUse));
	  }
	  else
	  {
	    memUses += UtlsStatMallocMem(sizeof(CellUse)-sizeof(ArrayInfo));
	  }
	  if(use->cu_id) memIds += UtlsStatMallocMem(strlen(use->cu_id) + 1);
	}
      }
 
      totMem += memUses;
      totMem += memIds;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"uses %d %d\n",
		memUses, numUses);
	Tcl_AppendResult(interp,buf,NULL);
	
	sprintf(buf,"use_ids %d\n",
		memIds);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* kids */
    {
      int mem = 0;
      CellKid *kid;

      for(kid=def->cd_kids; kid; kid=kid->ck_next)
      {
	numDefs++;
	mem += UtlsStatMallocMem(sizeof(CellKid));
      }

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"kids %d %d\n",
		mem, numDefs);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* kids hash */
    {
      int mem = -1;
      int entries = -1;
      int buckets = -1;

      mem = IHashStats2(def->cd_kidHash, &entries, &buckets);

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"kid_hash %d %d %d\n",
		mem, buckets, entries);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* parents */
    {
      int mem = 0;
      int num = 0;
      CellPar *par;

      for(par=def->cd_pars; par; par=par->cp_next)
      {
	num++;
	mem += UtlsStatMallocMem(sizeof(CellPar));
      }

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"pars %d %d\n",
		mem, num);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* parents hash */
    {
      int mem = -1;
      int entries = -1;
      int buckets = -1;

      mem = IHashStats2(def->cd_parHash, &entries, &buckets);

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"pars_hash %d %d %d\n",
		mem, buckets, entries);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* summary */
    {
      char buf[BUFSIZ];
      sprintf(buf,"instance_summary %d %d %d\n",
	      totMem, numUses, numDefs);
      Tcl_AppendResult(interp,buf,NULL);
      }
     
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-verbose]\n",
	      cmdName);
    CMD_RETURN(interp);
}



/*
 *--------------------------------------------------------------
 *
 * dbTclCmdStatLabels --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_stat_labels_DESC "get statistics on labels in cell"

#define db_stat_labels_DOC "
usage:  db_stat_labels [-cell cell_name] [-verbose]

returns: 
  labels_summary memory num_labels

  memory = total bytes for representing labels in this cell
  num_labels = total number of labels in this cell

If -verbose,
  returns more detailed info.

If no -cell option, defaults to edit cell.
"

static int
dbTclCmdStatLabels(ClientData clientData, 
		   Tcl_Interp *interp, 
		   int argc, 
		   char **argv)
{
    char *cmdName;
    bool verbose = FALSE;
    CellDef *def = NULL;
    int totMem = 0;
    int numLabels = 0;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
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
	
      if(c=='v' && strncmp(*argv,"-verbose",length)==0)
      {
	argc--; argv++;

	verbose = TRUE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    }

    /* should be no args left */
    if(argc) goto usage;

    /* default def to edit cell */
    if(!def) def = EditCellUse->cu_def;

    /* labels */
    {
      Label *lab;
      int mem = 0;

      for(lab=def->cd_labels; lab; lab=lab->lab_next)
      {
	numLabels++;
	mem += UtlsStatMallocMem(sizeof(Label) + sizeof(lab->lab_text) -3);
      }

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"labels %d %d\n",
		mem, numLabels);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* label hash */
    {
      int mem = -1;
      int entries = -1;
      int buckets = -1;

      mem = IHashStats2(def->cd_labelTextHash, &entries, &buckets);

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"label_hash %d %d %d\n",
		mem, buckets, entries);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* label loc hash */
    {
      int mem = -1;
      int entries = -1;
      int buckets = -1;

      mem = IHashStats2(def->cd_labelHash, &entries, &buckets);

      totMem += mem;

      if(verbose)
      {
	char buf[BUFSIZ];
	sprintf(buf,"label_loc_hash %d %d %d\n",
		mem, buckets, entries);
	Tcl_AppendResult(interp,buf,NULL);
      }
    }

    /* summary */
    {
      char buf[BUFSIZ];
      sprintf(buf,"label_summary %d %d\n",
	      totMem, numLabels);
      Tcl_AppendResult(interp,buf,NULL);
    }
     
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s [-cell def_name] [-verbose]\n",
	      cmdName);
    CMD_RETURN(interp);
}




/*
 *--------------------------------------------------------------
 *
 * dbTclCmdReadRetry --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_read_retry_DESC "give not-found cells another chance"

#define db_read_retry_DOC "
usage:  db_read_retry

Sets read_retry flags on all NotFound cells.

Another attempt will be made to read these cells the next time
they are referenced.

This procedure is normally called prior to each interactive command,
and when the cell path (MN_PATH_CELL) is changed.
"

static int
dbTclCmdReadRetry(ClientData clientData, 
		  Tcl_Interp *interp, 
		  int argc, 
		  char **argv)
{
    char *cmdName;

    CMD_BEGIN(interp);

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;

    /* parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

/* NO SWITCHES YET
      if(c=='v' && strncmp(*argv,"-verbose",length)==0)
      {
	argc--; argv++;

	verbose = TRUE;
	continue;
      }
*/

      /* unrecognized option */
      goto usage;
    }

    /* do it */
    {
      CellDef *def;

      for(def=DBCellDefs; def; def=def->cd_next)
      {
	if(!(def->cd_flags&CD_NOT_FOUND)) continue;
	def->cd_flags |= CD_READ_RETRY;
      }
    }

    /* should be no args left */
    if(argc) goto usage;
     
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s\n",
	      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdKids --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      List of cells containing edit cell as instance.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_kids_DESC "list cells that are instances of given cell"

#define db_kids_DOC "
Usage:  db_kids [cell_name]

if cell_name not given, defaults to current edit cell.
"

static int
dbTclCmdKids(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    char *cellName = NULL;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /*** parse args ***/

    cmdName = *argv;
    argv++; argc--;
    if(argc)
    {
      cellName = *argv;
      argv++; argc--;
    }
    if(argc) goto usage;

    if(cellName)
    {
      def = DBCellLookDef(cellName);
      if (!def)
      {
	MsgErrorF("cell '%s' not found.\n", cellName);
	CMD_RETURN(interp);
      }
    }

    /* output list of kids */
    {
      CellKid *kid;
      for(kid=def->cd_kids; kid; kid=kid->ck_next)
      {
	Tcl_AppendElement(interp, kid->ck_def->cd_name);
      }
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [cell_name]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdMHA --
 *

 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_mha_DESC "development command"

#define db_mha_DOC "
Usage:  varys at mha's whim.
"

static int
dbTclCmdMHA(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  Rect box;
  CellDef *def;

  CMD_BEGIN(interp);

  ToolGetBox(&def, &box);
  fprintf(stderr,"DEBUG db_mha def=%s\n",def->cd_name);  
  IHashStats(def->cd_labelHash);

  CMD_RETURN(interp);

  DumpRect("DEBUG db_mha box= ",&box);

  /* exercise chunk code on m1 plane of box def, beginning with box
   * area.
   */
  
  dbChunk2(def->cd_planes[DBTechNamePlane("m1")],  /* plane */
	   DBTechNameType("m1"),                   /* type */
	   box);                                   /* initial area */
  
  CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdNextEdge --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_next_edge_DESC "find next real edge from a point, in a given direction"

#define db_next_edge_DOC "
Usage:  db_next_edge [-cell <cellName>] [-any_cell] x y direction layer [maxd]

Find next real edge (tiletype changes) in direction from point (x,y) on plane.

Result: coordinates of the intersection of the edge and the ray from (x,y) 
in direction (empty string if no edge found).  Rootcell coordinates are
used, unless the -cell option is given in which case coordinates are in 
terms of that cell.

If maxd is given and is non-zero, don't move further than maxd in direction.

If -cell is specified, search that cell.  If not specified, defaults to edit cell. 

If -any_cell is given, search is not restricted to a single cell:  all paint in 
the rootcell and expanded descendents is considered.  

WARNING:  -any_cell requires a flat version of the given layer to be generated 
internally.  If specified without -area this can be VERY slow as well 
as memory intensive.
"

static int
dbTclCmdNextEdge(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    char *cmdName;
    Point point;    /* start point */
    int direction;
    int maxd = 0;
    TileType layer;
    CellDef *def = NULL;
    char *cellName = NULL;
    int anyCell = FALSE;
    Point result;

    CMD_BEGIN(interp);

    /*** parse args ***/

    cmdName = *argv;
    argv++; argc--;

    /* parse switches */
    while (argc>0 && **argv=='-') 
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      /* if it looks like a number, break */
      if( c>='0' && c<= '9' ) break;

	
      if(c=='a' && strncmp(*argv,"-any_cell",length)==0)
      {
	argc--; argv++;
	anyCell = TRUE;
	continue;
      }

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
    }

    /* x */
    if(argc == 0) goto usage;
    if (!UnitsValidS(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    point.p_x = UnitsS2I(*argv);
    argv++; argc--;

    /* y */
    if(argc == 0) goto usage;
    if (!UnitsValidS(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    point.p_y = UnitsS2I(*argv);
    argv++; argc--;

    /* direction */
    if(argc == 0) goto usage;
    direction = GeoNameToPos(*argv, TRUE, TRUE);
    if (direction<0) goto usage;
    argv++; argc--;

    /* layer (tiletype) */
    if(argc == 0) goto usage;
    layer = DBTechNameType(*argv);
    if (layer < 0)
    {
      MsgErrorF("Unrecognized layer: '%s'.\n",
		*argv);
      goto usage;
    }
    argv++; argc--;

    /* maxd */
    if(argc>0)
    {
      if (!UnitsValidS(*argv)) 
      {
        MsgErrorF("bad maxd: %s\n", *argv);
        goto usage;
      }
      maxd = UnitsS2I(*argv);
      argv++; argc--;
    }

    if(argc) 
    {
      MsgErrorF("too many args.\n");
      goto usage;
    }

    if (maxd < 0) {
	/* Return empty string */
	CMD_RETURN(interp);
    }
      
    /* do it (in four cases) */
    if(def)
    {
      /* -cell option */

      if(!anyCell)
      {
	/* single cell */
	/* search the cell directly (no need to yank it) */ 

	int planeNum = DBTypePlaneTbl[layer];
	Plane *plane = def->cd_planes[planeNum];

	result = DBNextEdge(plane,
			    &point,
			    direction,
			    maxd ? maxd+1 : 0); 
      }
      else
      {
      	CellUse use;
	DBCellUseNewTemp(def, &use);

	/* hierarchical */ 
	result = DBNextEdgeH(&use,  
			     layer, 
			     &point, 
			     direction,
			     maxd ? maxd+1 : 0,
			     0); /* search all subcells */
      }
    }
    else
    {
      /* no -cell option (default to edit cell) */

      if(!anyCell)
      {
	Point editPoint;
	Point editResult;
	int editDirection;

	/* edit cell only */
	/* search the cell directly (no need to yank it) */ 

	int planeNum = DBTypePlaneTbl[layer];
	Plane *plane = EditCellUse->cu_def->cd_planes[planeNum];

	GeoTransPoint(&RootToEditTransform, &point, &editPoint);
	editDirection = GeoTransPos(&RootToEditTransform, direction);
	editResult = DBNextEdge(plane,
				&editPoint,
				editDirection,
				maxd ? maxd+1 : 0);
	GeoTransPoint(&EditToRootTransform, &editResult, &result); 
      }
      else
      {
	/* hierarchical */
	/* search from rootcell down */
	
	result = DBNextEdgeH(LayCurWindow()->lay_rootUse,
			     layer, 
			     &point, 
			     direction,
			     maxd ? maxd+1 : 0,
			     LayCurWindow()->lay_bitmask); /* expansion mask */ 
      }
    } /* do it (in four cases) */

    /* if no edge found, return null */
    {
      int d = ABSDIFF(result.p_x,point.p_x) + ABSDIFF(result.p_y,point.p_y);

      if((maxd && d>maxd) ||
	 result.p_x <= PLANE_BOT || 
	 result.p_x >= PLANE_TOP ||
	 result.p_y <= PLANE_BOT ||
	 result.p_y >= PLANE_TOP) CMD_RETURN(interp);
    }

    /* set tcl result */
    Tcl_SetResult(interp, UnitsI2S(result.p_x), TCL_VOLATILE);
    Tcl_AppendElement(interp, UnitsI2S(result.p_y));
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-cell <cellName>] [-any_cell] x y direction layer [maxd]", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdNextDistance --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_next_distance_DESC "find point in given direction where distance to parallel edge changes"

#define db_next_distance_DOC "
Usage: db_next_distance [-cell <cellName>] [-any_cell] [-area x0 y0 x1 y1] <xStart> <yStart> <direction> <layer>

Find next point where distance to parallel edge to left or right of ray changes.

If -area is given, only search within it.  If no change is found, return a 
value at the edge of the area.

If -cell is specified, search that cell.
If not specified, defaults to edit cell. 

If -any_cell is given, consider paint in subcells as well. 
WARNING:  -any_cell requires a flat version of the given layer to be generated 
internally.  If specified without -area this can be VERY slow as well 
as memory intensive.

Result: coordinates of point along ray where the change occurs,
or an empty string, if no change found.
"

static int
dbTclCmdNextDistance(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    char *cellName = NULL;
    Point point;
    int direction;
    TileType layer;
    bool anyCell = FALSE;
    bool areaOption = FALSE;
    Rect area;
    CellDef *def = NULL;
    Point result;
   
    area = TiPlaneRect; /* default area: entire tile plane */

    CMD_BEGIN(interp);

    /*** parse args ***/

    cmdName = *argv;
    argv++; argc--;

    /* parse switches */
    while (argc>0 && **argv=='-') 
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      /* if it looks like a number, break */
      if( c>='0' && c<= '9' ) break;

      if(c=='a' && strncmp(*argv,"-area",MAX(3,length))==0)
      {
	argv++; argc--;
	areaOption = TRUE;

	if(argc == 0) goto usage;
	if (!UnitsValidS(*argv)) 
	{
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	area.r_xbot = UnitsS2I(*argv);
	argv++; argc--;

	if(argc == 0) goto usage;
	if (!UnitsValidS(*argv)) 
	{
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	area.r_ybot = UnitsS2I(*argv);
	argv++; argc--;

	if(argc == 0) goto usage;
	if (!UnitsValidS(*argv)) 
	{
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	area.r_xtop = UnitsS2I(*argv);
	argv++; argc--;

	if(argc == 0) goto usage;
	if (!UnitsValidS(*argv)) 
	{
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	area.r_ytop = UnitsS2I(*argv);
	argv++; argc--;

	continue;
      }	
	
      if(c=='a' && strncmp(*argv,"-any_cell",MAX(3,length))==0)
      {
	argc--; argv++;
	anyCell = TRUE;
	continue;
      }

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
    }

    /* x */
    if(argc == 0) goto usage;
    if (!UnitsValidS(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    point.p_x = UnitsS2I(*argv);
    argv++; argc--;

    /* y */
    if(argc == 0) goto usage;
    if (!UnitsValidS(*argv)) 
    {
      MsgErrorF("bad coordinate: %s\n", *argv);
      goto usage;
    }
    point.p_y = UnitsS2I(*argv);
    argv++; argc--;

    /* direction */
    if(argc == 0) goto usage;
    direction = GeoNameToPos(*argv, TRUE, TRUE);
    if (direction<0) goto usage;
    argv++; argc--;

    /* layer */
    if(argc == 0) goto usage;
    layer = DBTechNameType(*argv);
    if (layer < 0)
    {
      MsgErrorF("Unrecognized layer: %s.\n", *argv);
      goto usage;
    }
    argv++; argc--;

    /* sanity check */
    if (areaOption) {
      if (point.p_x < area.r_xbot ||
	  point.p_x > area.r_xtop ||
	  point.p_y < area.r_ybot ||
	  point.p_y > area.r_ytop ) 
      {
	MsgErrorF("%s: starting point must be inside area", cmdName);
        CMD_RETURN(interp);
      }
    }

    /* do it (in four cases based on -cell and -any_cell options) */
    if(def)
    {
      /* -cell option */

      if(!anyCell)
      {
	/* single cell */
	/* search the cell directly (no need to yank it) */ 

	int planeNum = DBTypePlaneTbl[layer];
	Plane *plane = def->cd_planes[planeNum];

	result = DBNextDistance(plane,
				&point,
				direction,
				areaOption ? &area : NULL,
				NULL);
      }
      else
      {
      	CellUse use;
	DBCellUseNewTemp(def, &use);

	/* hierarchical */ 
	result = DBNextDistanceH(&use,  
				 layer, 
				 &point, 
				 direction,
				 areaOption ? &area : NULL,
				 0); /* search all subcells */
      }
    }
    else
    {
      /* no -cell option (default to edit cell) */

      if(!anyCell)
      {
	Point editPoint;
	Point editResult;
	int editDirection;
	Rect editArea;

	/* edit cell only */
	/* search the cell directly (no need to yank it) */ 

	int planeNum = DBTypePlaneTbl[layer];
	Plane *plane = EditCellUse->cu_def->cd_planes[planeNum];

	GeoTransPoint(&RootToEditTransform, &point, &editPoint);
	editDirection = GeoTransPos(&RootToEditTransform, direction);
	if(areaOption) GeoTransRect(&RootToEditTransform, &area, &editArea);

	editResult = DBNextDistance(plane,
				    &editPoint,
				    editDirection,
				    areaOption ? &editArea : NULL,
				    NULL);
	GeoTransPoint(&EditToRootTransform, &editResult, &result); 
      }
      else
      {
	/* hierarchical */
	/* search from rootcell down */

	result = DBNextDistanceH(LayCurWindow()->lay_rootUse,
				 layer, 
				 &point, 
				 direction,
				 areaOption ? &area : NULL,
				 LayCurWindow()->lay_bitmask); /* expansion mask */
      }
    } /* do it (in four cases) */

    /* if no change found, return null */
    if(areaOption)
    {
      if(!GEO_ENCLOSE(&result, &area)) CMD_RETURN(interp);
    }

    if(!GEO_ENCLOSE_STRONG(&result, &TiPlaneRect)) CMD_RETURN(interp);

    /* set tcl result */
    Tcl_SetResult(interp, UnitsI2S(result.p_x), TCL_VOLATILE);
    Tcl_AppendElement(interp, UnitsI2S(result.p_y));
    
    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-cell <cellName>] [-any_cell] [-area x0 y0 x1 y1] <xStart> <yStart> <direction> <layer>",
      cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdParents --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      List of cells containing edit cell as instance.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_parents_DESC "list cells containing given cell as instance"

#define db_parents_DOC "
Usage:  db_parents [cell_name]

if cell_name not given, defaults to current edit cell.
"

static int
dbTclCmdParents(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    char *cellName = NULL;
    CellDef *def = EditCellUse->cu_def;

    CMD_BEGIN(interp);

    /*** parse args ***/

    cmdName = *argv;
    argv++; argc--;
    if(argc)
    {
      cellName = *argv;
      argv++; argc--;
    }
    if(argc) goto usage;

    if(cellName)
    {
      def = DBCellLookDef(cellName);
      if (!def)
      {
	MsgErrorF("cell '%s' not found.\n", cellName);
	CMD_RETURN(interp);
      }
    }

    /* output list of parents */
    {
      CellPar *par;
      for(par=def->cd_pars; par; par=par->cp_next)
      {
	Tcl_AppendElement(interp, par->cp_def->cd_name);
      }
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [cell_name]\n", cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdPolygon --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_polygon_DESC "add,delete or list polygons"

#define db_polygon_DOC "
Usage:  db_polygon [-no_notify] [-cell cell_name] [layer x0 y0 x1 y1 x2 y2 ...]
        or 
        db_polygon -delete n 

NOTE:  Coordinates need not be on grid!

Creates polgyon on given layer.  
SPECIAL CASE:  Two point \"polygon\" is circle inside bounding bounding box of
two points.

If no args, returns one line per polygon of form:
  layer bbox coordinates attributes

coodinates = x0 y0 x1 y1 ...

attributes: 
  dependent = polygon is part of wire_path, not written to disk independently.
 
If -delete, deletes n-1th polygon in list (first polygon is 0)

If -cell, paint into cell_name (coordinates are in terms of cell_name).
If no -cell, paint into edit cell (coordinates are in terms of root cell)

If -no_notify, don't notify database that cell has changed.  FOR INTERNAL
USE ONLY, DO NOT USE (CAN CAUSE COREDUMPS)!
"

static int
dbTclCmdPolygon(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    TileType type;
    int deleteNum;
    CellDef *def = EditCellUse->cu_def;
    bool cellArg = FALSE;
    bool delete = FALSE;
    bool notify = TRUE;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

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
	cellArg = TRUE;
	argc--; argv++;

	continue;
      }

      if(c=='d' && strncmp(*argv,"-delete",length)==0)
      {
	argc--; argv++;
	delete = TRUE;

	if(argc==0) goto usage;
	if(sscanf(*argv,"%d",&deleteNum)!=1) goto usage;
	argc--; argv++;
        if(deleteNum<0) goto usage;

	continue;
      }

      if(c=='n' && strncmp(*argv,"-no_notify",length)==0)
      {
	argc--; argv++;

	notify = FALSE;
	continue;
      }

      /* bad switch */
      goto usage;
    }

    /* DELETE CASE */
    if(delete)
    {
      Polygon *poly;

      if(argc>0) goto usage;

      /* find polygon to delete */
      poly = def->cd_polygons;
      while(deleteNum>0)
      {
	poly = poly->poly_next;
	deleteNum--;
      }

      /* check for read-only */
      if(!DBAccessModifyType(def,poly->poly_type)) CMD_RETURN(interp);

      DBPolyDelete(def, poly, notify);

      CMD_RETURN(interp);
    }

    /* LIST POLYGONS CASE */
    if (argc==0)
    {
      Polygon *poly;
      Transform *trans; 

      if(cellArg)
      {
	trans = &GeoIdentityTransform;
      }
      else
      {
	trans = &EditToRootTransform;
      }

      for(poly = def->cd_polygons;
	  poly;
	  poly = poly->poly_next)
      {
	int i;
	PointFloat *p;
	Point tmp;
	PointFloat tmpF;

	/* type */
	Tcl_AppendElement(interp, DBTypeLongName(poly->poly_type));

	/* bbox */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	GeoTransPoint(trans, &poly->poly_bbox.r_ll, &tmp);
	Tcl_AppendElement(interp, UnitsI2S(tmp.p_x));
	Tcl_AppendElement(interp, UnitsI2S(tmp.p_y));

	GeoTransPoint(trans, &poly->poly_bbox.r_ur, &tmp);
	Tcl_AppendElement(interp, UnitsI2S(tmp.p_x));
	Tcl_AppendElement(interp, UnitsI2S(tmp.p_y));
	Tcl_AppendResult(interp, "}", (char *) NULL);
	
	/* points */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	p = poly->poly_points;
        for(i=0; i< poly->poly_size; i++)
	{
	  GeoTransPointF(trans, p, &tmpF);
	  Tcl_AppendElement(interp, UnitsF2S(tmpF.pf_x));
	  Tcl_AppendElement(interp, UnitsF2S(tmpF.pf_y));
	  p++;
	}
	Tcl_AppendResult(interp, "}", (char *) NULL);

	/* attributes */
	Tcl_AppendResult(interp, " {", (char *) NULL);
	if(poly->poly_wirePath)	Tcl_AppendResult(interp, "dependent", (char *) NULL);
	Tcl_AppendResult(interp, "}", (char *) NULL);


	Tcl_AppendResult(interp,"\n", (char *) NULL);
      }

      CMD_RETURN(interp);
    }
    
    /* ADD POLYGONS CASE */
    {
      PointFloat *points;
      int i; 
      int size;
      Transform *trans;

      if(cellArg)
      {
	trans = &GeoIdentityTransform;
      }
      else
      {
	trans = &RootToEditTransform;
      }

      /* parse type */
      if(argc == 0) goto usage;
      type = DBTechNameType(*argv);
      if(type==-1) 
      {
	  MsgErrorF("Ambiguous layer:  '%s'.\n", *argv);
	  CMD_RETURN(interp);
      }
      if(type==-2) 
      {
        MsgErrorF("Unknown layer:  '%s'.\n", *argv);
        CMD_RETURN(interp);
      }
      if(type==TT_SPACE) 
      {
	MsgErrorF("Can't add polygon of type space.\n");
	CMD_RETURN(interp);
      }
      argv++; argc--;

      if(argc%2 != 0) goto usage;  /* number of points must be even */
      size = argc/2;
      if(size<2) 
      {
        MsgErrorF("Minimum of 3 vertices for polygon (2 to draw circle)\n"); 
        CMD_RETURN(interp);
      }
      points = DBPointsFAlloc(size, NULL, NULL);
      for(i=0; i<size; i++)
      {
	PointFloat tmp;

	/* x */
	if (!UnitsValidSF(*argv)) 
        {
	  FREE((char *) points);
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	tmp.pf_x = UnitsS2F(*argv);
	argv++; argc--;

	/* y */
	if (!UnitsValidSF(*argv)) 
        {
	  FREE((char *) points);
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	tmp.pf_y = UnitsS2F(*argv);
	argv++; argc--;

	GeoTransPointF(trans,&tmp, &points[i]);
      }

      if(argc>0) goto usage;

      /* check for read-only */
      if(!DBAccessModifyType(def,type)) CMD_RETURN(interp);

      DBPolyNew(def, 
		type, 
		size, 
		points, 
		NULL,     /* independent (not part of wirepath) */
		notify);    /* notify redisplay etc. */

      CMD_RETURN(interp);
    }

usage:
    MsgErrorF("usage:  %s [-cell cell_name] [-no_notify] [layer x0 y0 x1 y1 x2 y2 ...]\nor\n"
	      "%s [-cell cell_name] [-no_notify] -delete n\n",cmdName, cmdName);
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdTypes --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_types_DESC "get info on all layers (types) defined for current technology"

#define db_types_DOC "
Result:
    Lists one line per type giving following:
    <longName> <official_short_name> <list_of_all_names> <planeName> <flags>
"

static int
dbTclCmdTypes(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n");
         CMD_RETURN(interp);
    }

    /* list types */
    for (i = 0; i < DBNumUserLayers; i++)
    {
        /* long name */
        Tcl_AppendResult(interp, DBTypeLongName(i), NULL);	

	/* official short name */
        Tcl_AppendElement(interp, DBTypeShortName(i));	

	/* list of all names for this type */
        {
            NameList *p;

	    Tcl_AppendResult(interp, " {",NULL);	

	    for (p = dbTypeNameLists.sn_next; 
		 p != &dbTypeNameLists;
		 p = p->sn_next)
	    {
	        if (((TileType) p->sn_value) == i)
	        {
		    Tcl_AppendElement(interp, p->sn_name);
		}
	    }

	    Tcl_AppendResult(interp, "} ",NULL);	
	}

	/* plane */
	if(i!=0)
	{
            Tcl_AppendElement(interp, DBPlaneLongName(DBPlane(i)));
	}
	else
	{
            Tcl_AppendResult(interp, "{}",NULL);
	}

	/* flags */
        Tcl_AppendResult(interp, " {",NULL);	
	if(i <TT_TECHDEPBASE) 
	  Tcl_AppendElement(interp, "builtin");	
	if(i >=TT_SELECTBASE) 
	  Tcl_AppendElement(interp, "selectable");	
	if(DBPlaneFlags[DBPlane(i)]&DBF_AUTO_GENERATED) 
	  Tcl_AppendElement(interp, "auto_generated");	
	if(DBPlaneFlags[DBPlane(i)]&DBF_TEMP) 
	  Tcl_AppendElement(interp, "temp");	
	Tcl_AppendResult(interp, "}",NULL);	

	/* newline between types */
	if(i != DBNumUserLayers)
	{
	    Tcl_AppendResult(interp, "\n",NULL);	
	}
    }

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdVStamp --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_vstamp_DESC "get/update version stamp"

#define db_vstamp_DOC "
Usage:  db_vstamp [-update] [-new] 

Returns current version stamp:  time rev 
(time is seconds since beginning of 1970 in universal coordinated time)
 
if -update, first updates current version stamp to present time.
if -new, first increments revision number. 

NOTE: not critical for version time to be up-to-date since the vs_rev field
      distinguishes between successive vstamps.
"

static int
dbTclCmdVStamp(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    bool update = FALSE;
    bool new = FALSE;

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='n' && strncmp(*argv,"-new",length)==0)
      {
	argc--; argv++;
	new = TRUE;

	continue;
      }

      if(c=='u' && strncmp(*argv,"-update",length)==0)
      {
	argc--; argv++;
	update = TRUE;

	continue;
      }

      /* bad switch */
      goto usage;
    }

    if(update) DBVStampUpdate();
    if(new) DBVStampNew();

    /* set result to current vstamp */
    {
      char buf[1000];

      sprintf(buf,"%d %d", 
	      DBVStampCurrent.vs_time,
	      DBVStampCurrent.vs_rev);

      Tcl_SetResult(interp,buf,TCL_VOLATILE);
    }

    CMD_RETURN(interp);

usage:
    MsgErrorF("usage:  %s [-new] [-update]");
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * dbTclCmdWirePath --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:
 *      Depends on option. 
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define db_wire_path_DESC "add,delete or list wire paths"

#define db_wire_path_DOC "
Usage:  db_wire_path [[-rounded | -half_width] layer width x0 y0 ...]
        or 
        db_wire_path -delete n 

A wire path is a mask geometry defined by a layer, a width and a series of 
points defining the center-line path.  In addition several end-cap styles
can be chosen between.

Creates wire path on given layer.  The default is no endcaps.
 
If \"-rounded\" given, rounded endcaps are added to wire, and circular
mitering is used at turning points.

If \"-half_width\" is given, square endcaps are extended 1/2 wire width from
endpoints.

If no args, returns one line per wire path of form:
  layer style width x0 y0 x1 y1 ...
 
If -delete, deletes n-1th polygon in list (first polygon is 0)
"

static int
dbTclCmdWirePath(ClientData clientData, 
	Tcl_Interp *interp, 
	int argc, 
	char **argv)
{
    char *cmdName;
    TileType type;
    int deleteNum;
    bool delete = FALSE;
    int style = WP_STYLE_FLUSH;  /* default style (no end caps) */

    CMD_BEGIN(interp);

    cmdName = *argv;
    argv++; argc--;

    /* Parse command line switchs */
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];
	
      if(c=='d' && strncmp(*argv,"-delete",length)==0)
      {
	argc--; argv++;
	delete = TRUE;

	if(argc==0) goto usage;
	if(sscanf(*argv,"%d",&deleteNum)!=1) goto usage;
	argc--; argv++;
        if(deleteNum<0) goto usage;

	continue;
      }

      if(c=='h' && strncmp(*argv,"-half_width",length)==0)
      {
	argc--; argv++;
	style = WP_STYLE_HALFWIDTH;
	continue;
      }
	
      if(c=='r' && strncmp(*argv,"-rounded",length)==0)
      {
	argc--; argv++;
	style = WP_STYLE_ROUNDED;
	continue;
      }

      /* bad switch */
      goto usage;
    }

    /* DELETE CASE */
    /* delete wire path with index deleteNum */
    if(delete)
    {
      WirePath *wp;

      if(argc>0) goto usage;

      /* find wirePath to delete */
      wp = EditCellUse->cu_def->cd_wirePaths;
      while(deleteNum>0)
      {
	wp = wp->wp_next;
	deleteNum--;
      }

      /* check for read-only */
      if(!DBAccessModifyType(EditCellUse->cu_def,wp->wp_type)) 
      {
	CMD_RETURN(interp);
      }

      DBWPathDelete(EditCellUse->cu_def, 
		    wp, 
		    TRUE); /* notify redisplay etc. */
      CMD_RETURN(interp);
    }

    /* LIST WIRE PATH CASE */
    if (argc==0)
    {
      WirePath *wp;

      for(wp = EditCellUse->cu_def->cd_wirePaths;
	  wp;
	  wp = wp->wp_next)
      {
	int i;
	Point *p;

	/* type */
	Tcl_AppendElement(interp, DBTypeLongName(wp->wp_type));

	/* style */
	switch (wp->wp_style)
	{
    	  case WP_STYLE_FLUSH:
  	  Tcl_AppendElement(interp, "flush");
	  break;

	  case WP_STYLE_ROUNDED:
  	  Tcl_AppendElement(interp, "rounded");
	  break;

    	  case WP_STYLE_HALFWIDTH:
  	  Tcl_AppendElement(interp, "half_width");
	  break;


	  default:
	  ASSERT(FALSE,"dbTclCmdWirePath");
	  break;
	}

	/* width */
	Tcl_AppendElement(interp, UnitsI2S(wp->wp_width));
	
	/* points */
	p = wp->wp_points;
        for(i=0; i< wp->wp_size; i++)
	{
	  Tcl_AppendElement(interp, UnitsI2S(p->p_x));
	  Tcl_AppendElement(interp, UnitsI2S(p->p_y));
	  p++;
	}

	Tcl_AppendResult(interp,"\n", (char *) NULL);
      }

      CMD_RETURN(interp);
    }
    
    /* ADD WIRE PATH CASE */
    {
      Point *points;
      int i; 
      int size;
      int width;

      /* parse type */
      if(argc == 0) goto usage;
      type = DBTechNameType(*argv);
      if(type==-1) 
      {
	  MsgErrorF("Ambiguous layer:  '%s'.\n", *argv);
	  CMD_RETURN(interp);
      }
      if(type==-2) 
      {
        MsgErrorF("Unknown layer:  '%s'.\n", *argv);
        CMD_RETURN(interp);
      }
      if(type==TT_SPACE) 
      {
	MsgErrorF("Can't add wire path of type space.\n");
	CMD_RETURN(interp);
      }
      argv++; argc--;

      /* check for read-only */
      if(!DBAccessModifyType(EditCellUse->cu_def,type)) CMD_RETURN(interp);

      /* parse width */
      if(argc ==0) goto usage;
      if(!UnitsValidS(*argv))
      {
	  MsgErrorF("bad width:  %s\n", *argv);
	  goto usage;
      }
      width = UnitsS2I(*argv);
      if(width<=0) 
      {
	  MsgErrorF("bad width (must be positive):  %s\n", *argv);
	  goto usage;
      }
      argv++; argc--;

      /* parse points */
      if(argc==0) goto usage;
      if(argc%2 != 0) goto usage;  /* number of coords must be even */
      size = argc/2;

      points = DBPointsAlloc(size, NULL, NULL);
      for(i=0; i<size; i++)
      {
	/* x */
	if (!UnitsValidS(*argv)) 
        {
	  DBPointsFree(points);
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	points[i].p_x = UnitsS2I(*argv);
	argv++; argc--;

	/* y */
	if (!UnitsValidS(*argv)) 
        {
	  DBPointsFree(points);
	  MsgErrorF("bad coordinate: %s\n", *argv);
	  goto usage;
	}
	points[i].p_y = UnitsS2I(*argv);
	argv++; argc--;
      }

      if(argc>0) goto usage;

      DBWPathNew(EditCellUse->cu_def, 
		 type, 
		 style,
		 width,
		 size, 
		 points, 
		 TRUE,    /* notify redisplay etc. */
		 NULL);

      CMD_RETURN(interp);
    }

usage:
    MsgErrorF("usage:  %s [ [-rounded | -half_width] wlayer width x0 y0 ...]\nor\n"
	      "%s -delete n\n",cmdName, cmdName);
    CMD_RETURN(interp);
}

/* DEBUG - polygon clipping */
static int
dbTclCmdDebug(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
  char *cmdName;
  CellDef *def;
  Rect box;
  Polygon *poly;
  TileType inType, outType;

  CMD_BEGIN(interp);

  /* Parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* NO SWITCHES CURRENTLY (example below)

       if (c=='s' && strncmp(*argv,"-source",length)==0)
       {
       argc--;
       argv++;
       
       if(argc==0) goto usage;
       srcName=*argv;
       argc--;
       argv++;
       continue;
       }
    */
    
    /* bad switch */
    goto usage;
  } /* end while(argc>0 && **argv=='-')  */

  /* get current box */
  ToolGetBox(&def, &box);
  
  inType = DBTechNameType("m1");
  outType = DBTechNameType("poly");

  /* erase existing polygons of outType */
  for(poly = def->cd_polygons; poly; poly=poly->poly_next)
  {
    if(poly->poly_type != outType) continue;
    if(poly->poly_wirePath) continue; 
    DBPolyDelete(def,poly,TRUE);
  }

  /* clip inType polygons (results to outType) */
  for(poly = def->cd_polygons; poly; poly=poly->poly_next)
  {
    if(poly->poly_type != inType) continue;
    {
      PointFloat **list;
      int num;
      int i;

      num = DBPolygonIntersectRect(poly,
				   &box,
				   &list);

      /* create result polygons */
      for(i=0; i<num; i++)
      {
	int size = list[i+1] - list[i];
	
	DBPolyNew(def, 
		  outType, 
		  size, 
		  DBPointsFAlloc(size, list[i], NULL), 
		  NULL,     /* not part of wirepath */ 
		  TRUE);    /* notify redisplay etc. */
      }
    }
  }

  CMD_RETURN(interp);

usage:
    MsgErrorF("usage: %s\n", cmdName);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTclInit --
 *
 * Initialize database tcl commands.
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
DBTclInit(Tcl_Interp *interp)
{
   /* initialize tcl commands in dbTclSearch.c */
   dbTclSearchInit(interp);

   /* initialize db_search_old (for debug) */
   dbTclSearchOldInit(interp);

   MnDocCreateCommand(interp, "db_bbox", dbTclCmdBBox,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_bbox_DESC,
	       db_bbox_DOC);
   MnDocCreateCommand(interp, "db_bbox_user_layers", dbTclCmdBBoxUserLayers,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_bbox_user_layers_DESC,
	       db_bbox_user_layers_DOC);
   MnDocCreateCommand(interp, "db_cells", dbTclCmdCells,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cells_DESC,
	       db_cells_DOC);
   MnDocCreateCommand(interp, "db_cell_clear", dbTclCmdCellClear,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_clear_DESC,
	       db_cell_clear_DOC);
   MnDocCreateCommand(interp, "db_cell_copy", dbTclCmdCellCopy,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_copy_DESC,
	       db_cell_copy_DOC);
   MnDocCreateCommand(interp, "db_cell_delete", dbTclCmdCellDelete,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_delete_DESC,
	       db_cell_delete_DOC);
   MnDocCreateCommand(interp, "db_cell_file_tech", dbTclCmdCellFileTech,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_file_tech_DESC,
	       db_cell_file_tech_DOC);
   MnDocCreateCommand(interp, "db_cell_name2file", dbTclCmdCellName2File,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_name2file_DESC,
	       db_cell_name2file_DOC);
   MnDocCreateCommand(interp, "db_cell_new", dbTclCmdCellNew,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_new_DESC,
	       db_cell_new_DOC);
   MnDocCreateCommand(interp, "db_cell_signature", dbTclCmdCellSignature,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_signature_DESC,
	       db_cell_signature_DOC);
   MnDocCreateCommand(interp, "db_cell_read_only", dbTclCmdCellReadOnly,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_read_only_DESC,
	       db_cell_read_only_DOC);
   MnDocCreateCommand(interp, "db_cell_read", dbTclCmdCellRead,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_read_DESC,
	       db_cell_read_DOC);
   MnDocCreateCommand(interp, "db_cell_rename", dbTclCmdCellRename,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_cell_rename_DESC,
	       db_cell_rename_DOC);
   MnDocCreateCommand(interp, "db_chunk", dbTclCmdChunk,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_chunk_DESC,
	       db_chunk_DOC);
   MnDocCreateCommand(interp, "db_debug", dbTclCmdDebug,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       "DEBUG", "DEBUG");
   MnDocCreateCommand(interp, "db_flyline", dbTclCmdFlyLine,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_flyline_DESC,
	       db_flyline_DOC);
   MnDocCreateCommand(interp, "db_gcell_notify", dbTclCmdGCellNotify,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_gcell_notify_DESC,
	       db_gcell_notify_DOC);
   MnDocCreateCommand(interp, "db_group", dbTclCmdGroup,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_group_DESC,
	       db_group_DOC);
   MnDocCreateCommand(interp, "db_group_attribute", dbTclCmdGroupAttribute,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_group_attribute_DESC,
	       db_group_attribute_DOC);
   MnDocCreateCommand(interp, "db_group_class", dbTclCmdGroupClass,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_group_class_DESC,
	       db_group_class_DOC);
   MnDocCreateCommand(interp, "db_instance", dbTclCmdInstance,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_instance_DESC,
	       db_instance_DOC);
   MnDocCreateCommand(interp, "db_instance_delete", dbTclCmdInstanceDelete,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_instance_delete_DESC,
	       db_instance_delete_DOC);
   MnDocCreateCommand(interp, "db_instances", dbTclCmdInstancesL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_instances_l_DESC,
	       db_instances_l_DOC);
	/* TODO: eventaully, remove (db_instances is new name) */
   MnDocCreateCommand(interp, "db_instances_l", dbTclCmdInstancesL,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_instances_l_DESC,
	       db_instances_l_DOC);
   MnDocCreateCommand(interp, "db_kids", dbTclCmdKids,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_kids_DESC,
	       db_kids_DOC);
   MnDocCreateCommand(interp, "db_label", dbTclCmdLabel,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_label_DESC,
	       db_label_DOC);
   MnDocCreateCommand(interp, "db_layer_auto", dbTclCmdLayerAuto,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_layer_auto_DESC,
	       db_layer_auto_DOC);
   MnDocCreateCommand(interp, "db_layer_temp", dbTclCmdLayerTemp,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_layer_temp_DESC,
	       db_layer_temp_DOC);
   MnDocCreateCommand(interp, "db_mha", dbTclCmdMHA,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_mha_DESC,
	       db_mha_DOC);
   MnDocCreateCommand(interp, "db_next_distance", dbTclCmdNextDistance,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_next_distance_DESC,
	       db_next_distance_DOC);
   MnDocCreateCommand(interp, "db_next_edge", dbTclCmdNextEdge,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_next_edge_DESC,
	       db_next_edge_DOC);
   MnDocCreateCommand(interp, "db_notify", dbTclCmdNotify,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_notify_DESC,
	       db_notify_DOC);
   MnDocCreateCommand(interp, "db_paint", dbTclCmdPaint,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_paint_DESC,
	       db_paint_DOC);
   MnDocCreateCommand(interp, "db_parents", dbTclCmdParents,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_parents_DESC,
	       db_parents_DOC);
   MnDocCreateCommand(interp, "db_polygon", dbTclCmdPolygon,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_polygon_DESC,
	       db_polygon_DOC);
   MnDocCreateCommand(interp, "db_prop", dbTclCmdProp,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_prop_DESC,
	       db_prop_DOC);
   MnDocCreateCommand(interp, "db_stat_paint", dbTclCmdStatPaint,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_stat_paint_DESC,
	       db_stat_paint_DOC);
   MnDocCreateCommand(interp, "db_stat_instances", dbTclCmdStatInstances,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_stat_instances_DESC,
	       db_stat_instances_DOC);
   MnDocCreateCommand(interp, "db_stat_labels", dbTclCmdStatLabels,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_stat_labels_DESC,
	       db_stat_labels_DOC);
   MnDocCreateCommand(interp, "db_read_retry", dbTclCmdReadRetry,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_read_retry_DESC,
	       db_read_retry_DOC);
   MnDocCreateCommand(interp, "db_types", dbTclCmdTypes,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_types_DESC,
	       db_types_DOC);
   MnDocCreateCommand(interp, "db_vstamp", dbTclCmdVStamp,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_vstamp_DESC,
	       db_vstamp_DOC);
   MnDocCreateCommand(interp, "db_wire_path", dbTclCmdWirePath,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       db_wire_path_DESC,
	       db_wire_path_DOC);

   MnDocLinkVar(interp, "DB_FLYLINES_SAVE", 
		(char *) &dbFlylinesSave, 
		TCL_LINK_BOOLEAN,
		"If reset, flylines are treated as annotations only",
"
This variable is set by default, and flylines are treated as full-fledged
database objects:  they are read/written to .max files, and operations
on flylines are undoable.

If this variable is reset, flyline operations are not read/written to
.max files, and undo will not undo flyline operations.
");

   MnDocLinkVar(interp, "DB_READ_LEGACY_RES", 
		(char *) &dbReadLegacyRes, 
		TCL_LINK_DOUBLE,
		"if non-zero, gives resolution of old max files (in microns)",
"
technology specific, so normally set in tech file
__RESOLUTION__ property in .max file overrides.
(__RESOLUTION__ written out since Max2.38)
");


   MnDocLinkVar(interp, "DB_WIRE_PATH_SINGLE_POLYGON", 
		(char *) &dbWPathSinglePolygon,
		TCL_LINK_BOOLEAN,
		"If set, wirepaths are rendered as single polygon (instead of one per segment)",
		NULL);


   MnDocLinkVar(interp, "DB_INSTANCE_DUP_OK", 
		(char *) &dbInstanceDupOK,
		TCL_LINK_BOOLEAN,
		"If set, identical coincident instances are permitted.",
		NULL);

   MnDocLinkVar(interp, "DB_READ_REPORT_ROUNDING_ERRORS", 
		(char *) &dbReadReportRoundingErrors,
		TCL_LINK_BOOLEAN,
"If set, give warning if rounding errors occur during .max file read-in",
		NULL);

   MnDocLinkVar(interp, "DB_LOAD_QUIET", 
		(char *) &DBReadOpenQuiet,
		TCL_LINK_INT,
		"If greater than zero, load messages are not printed",
"
Supresses \"Cell loaded\" and \"Cell not-found\" messages.

Useful for supressing messages during auto-load.

NOTE: Is int instead of bool, so \"silent\" code can be implemented by incrementing before and decrementing after.
");


#ifdef	PAINTDEBUG
   MnDocLinkVar(interp, "db_paint_debug", (char *) &dbPaintDebug, TCL_LINK_INT,
		NULL, NULL);
#endif  PAINTDEBUG

}
