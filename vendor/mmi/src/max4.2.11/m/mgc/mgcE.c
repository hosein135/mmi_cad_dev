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
 * MgcE.c --
 *
 * Commands with names beginning with the letter E.
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
static char rcsid[] = "$Header: CmdE.c,v 6.0 90/08/28 18:07:11 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "utils.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"
#include "commands.h"
#include "message.h"
#include "drc.h"
#include "mgcint.h"
#include "extract.h"
#include "select.h"
#include "mgcint.h"

/*
 * ----------------------------------------------------------------------------
 *
 * CmdEdit --
 *
 * Implement the "edit" command.
 * Use the cell that is currently selected as the edit cell.  If more than
 * one cell is selected, use the point to choose between them.
 *
 * Usage:
 *	edit
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets EditCellUse.
 *
 * ----------------------------------------------------------------------------
 */

/* The following variable is set by cmdEditEnumFunc to signal that there
 * was at least one cell in the selection.
 */

static bool cmdFoundNewEdit;

	/*ARGSUSED*/

/* Search function to find the new edit cell:  look for a cell use
 * that contains the rectangle passed as argument.  If we find such
 * a use, return 1 to abort the search.  Otherwise, save information
 * about this use anyway:  it'll become the edit cell if nothing
 * better is found.
 */
static int
cmdEditEnumFunc(CellUse *selUse, 
                    		/* Use from selection (not used). */
		CellUse *use, 
                 		/* Use from layout that corresponds to
				 * selUse (could be an array!).
				 */
		Transform *transform, 
                         	/* Transform from use->cu_def to root coords. */
		TerminalPath *tPath, /* Not Used */
		Rect *area)
               			/* We're looking for a use containing this
				 * area, in root coords.
				 */
{
    Rect defArea, useArea;
    int xhi, xlo, yhi, ylo;

    /* Save this use as the default next edit cell, regardless of whether
     * or not it overlaps the area we're interested in.
     */

    EditToRootTransform = *transform;
    GeoInvertTrans(transform, &RootToEditTransform);
    EditCellUse = use;
    EditRootDef = SelectRootDef;
    cmdFoundNewEdit = TRUE;

    /* See if the bounding box of this use overlaps the area we're
     * interested in.
     */

    GeoTransRect(&RootToEditTransform, area, &defArea);
    GeoTransRect(&use->cu_transform, &defArea, &useArea);
    if (!GEO_OVERLAP(&useArea, DBBBoxCellUseNoUp(use))) return 0;

    /* It overlaps.  Now find out which array element it points to,
     * and adjust the transforms accordingly.
     */
    
    DBArrayOverlap(use, &useArea, &xlo, &xhi, &ylo, &yhi);
    GeoTransTrans(DBGetArrayTransform(use, xlo, ylo), transform,
	    &EditToRootTransform);
    GeoInvertTrans(&EditToRootTransform, &RootToEditTransform);
    return 1;
}

Void
CmdEdit(Layout *w, TxCommand *cmd)
{
    Rect pointArea;
    CellDef *oldEditDef = EditCellUse->cu_def;

    if (cmd->tx_argc > 1)
    {
	MsgErrorF("Usage: edit\nMaybe you want the \"load\" command\n");
	return;
    }

    LayUndoOldEdit(EditCellUse, EditRootDef,
	    &EditToRootTransform, &RootToEditTransform);
	
    /* Use the position of the point to select one of the currently-selected
     * cells (if there are more than one).  If worst comes to worst, just
     * select any selected cell.
     */
    (void) LayPointGet((Point *) NULL, &pointArea);
    cmdFoundNewEdit = FALSE;
    (void) SelEnumCells(FALSE, 
			(bool *) NULL, 
			(SearchContext *) NULL,
			(TerminalPath *) NULL,
			(TerminalPath *) NULL,
			cmdEditEnumFunc, 
			(ClientData) &pointArea);
    if (!cmdFoundNewEdit)
	MsgErrorF("You haven't selected a new cell to edit.\n");

    LayUndoNewEdit(EditCellUse, EditRootDef,
		&EditToRootTransform, &RootToEditTransform);

    /* Since edit and non-edit cells may be displayed differently need
     * to redisplay ond an new edit cells.
     */
    DBChangedArea(oldEditDef, 
		  NULL, /* area = whole def */
		  NULL, /* all layers, etc. */
		  DBCF_DISPLAY);
    DBChangedArea(EditCellUse->cu_def, 
		  NULL, /* area = whole def */
		  NULL, /* all layers, etc. */
		  DBCF_DISPLAY);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdErase --
 *
 * Implement the "erase" command.
 * Erase paint in the specified layers from underneath the box in
 * EditCellUse->cu_def.
 *
 * Usage:
 *	erase [layers]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modified EditCellUse->cu_def.
 *
 * ----------------------------------------------------------------------------
 */

/* The following information is used to keep track of cells to be
 * erased.  It is needed because we can't delete cells while searching
 * for cells, or the database gets screwed up.
 */

#define MAXCELLS 100
static CellUse *cmdEraseCells[MAXCELLS];
static int cmdEraseCount;

Void
CmdErase(Layout *w, TxCommand *cmd)
{
    Rect editRect;
    TileTypeBitMask mask;
    extern int cmdEraseCellsFunc(SearchContext *scx, ClientData cdarg);

    if (w == (Layout *) NULL) return;

    if (cmd->tx_argc > 2)
    {
	MsgErrorF("Usage: %s [layers]\n", cmd->tx_argv[0]);
	return;
    }

    if (!ToolGetEditBox(&editRect)) return;

    /*
     * Erase with no arguments is the same as erasing
     * everything underneath the box tool (ie, painting space)
     * Labels are automatically affected; subcells are not.
     */

    if (cmd->tx_argc == 1)
	(void) CmdParseLayers("*,label", &mask);
    else if (!CmdParseLayers(cmd->tx_argv[1], &mask))
	return;

    if (TTMaskEqual(&mask, &DBSpaceBits))
	(void) CmdParseLayers("*,label", &mask);
    TTMaskClearType(&mask, TT_SPACE);
    if (TTMaskIsZero(&mask))
	return;

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    /* Erase paint. */
    DBEraseMask(EditCellUse->cu_def, &editRect, &mask);

    /* Erase labels. */
    (void) DBLabelsEraseArea(EditCellUse->cu_def, &editRect, &mask);

    /* Erase subcells. */
    if (TTMaskHasType(&mask, L_CELL))
    {
	SearchContext scx;
	int i;

	/* To erase cells, we make a series of passes.  In each
	 * pass, collect a whole bunch of cells that are in the
	 * area of interest, then erase all those cells.  Continue
	 * this until all cells have been erased.
	 */
	
	scx.scx_use = EditCellUse;
	scx.scx_x = scx.scx_y = 0;
	scx.scx_area = editRect;
	scx.scx_trans = GeoIdentityTransform;
	while (TRUE)
	{
	    cmdEraseCount = 0;
	    (void) DBSrChildren(&scx, cmdEraseCellsFunc, (ClientData) NULL);
	    for (i=0; i<cmdEraseCount; i++)
	    {
	      Rect *area = DBBBoxCellUseNoUp(cmdEraseCells[i]);

      	      DBInstanceUnlink(cmdEraseCells[i], EditCellUse->cu_def);
	      DBInstanceUnplace(cmdEraseCells[i]);
	      DBCellDeleteUse(cmdEraseCells[i]);

              DBChangedArea(EditCellUse->cu_def, area, NULL, DBCF_INSTANCE);
	    }
	    if (cmdEraseCount < MAXCELLS) break;
	}
    }

    TTMaskClearType(&mask, L_CELL);
    TTMaskClearType(&mask, L_LABEL);

    SelectClear();

    /* process database changes */
    DBChangedArea(EditCellUse->cu_def, &editRect, NULL, 0);
}

	/* ARGSUSED */
int
cmdEraseCellsFunc(SearchContext *scx, ClientData cdarg)
                   		/* Indicates cell found. */
                 		/* Not used. */
{
    /* All this procedure does is to remember cells that are
     * found, up to MAXCELLS of them.
     */
    
    if (cmdEraseCount >= MAXCELLS) return 1;
    cmdEraseCells[cmdEraseCount] = scx->scx_use;
    cmdEraseCount += 1;
    return 2;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdExpand --
 *
 * Implement the "expand" command.
 *
 * Usage:
 *	expand
 *	expand toggle
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If "toggle" is specified, flips the expanded/unexpanded status
 *	of all selected cells.  Otherwise, aren't any unexpanded cells
 *	left under the box.  May read cells in from disk, and updates
 *	bounding boxes that have changed.
 *
 * ----------------------------------------------------------------------------
 */

/* call back to propagate use expandMask change to selection */
static int
cmdExpandEnumFunc(CellUse *selUse, 
                    		/* Use from selection */
		CellUse *use, 
                 		/* Use from layout that corresponds to
				 * selUse (could be an array!).
				 */
		Transform *transform, 
                         	/* Transform from use->cu_def to root coords. */
		                /* Not Used */
		TerminalPath *tPath, 
		                /* Not Used */
		ClientData cdata)
		                /* Not Used */
{
  selUse->cu_expandMask = use->cu_expandMask;
    
  /* continue search */
  return 0;
}

/* This function is called for each cell whose expansion status changed.
 * It forces the cells area to be redisplayed, and updates selection,
 * then returns 0 to keep looking for more cells to expand.
 */

int
cmdExpandFunc(CellUse *use, int windowMask)
                 		/* Use that was just expanded. */
                   		/* Window where it was expanded. */
{
    if (use->cu_parent == NULL) return 0;
    /* use possibly out-of-date cu_bbox.
     * (if bbox changes with future update, layout module will be notified then)
     */
    DBChangedArea(use->cu_parent, 
		  &use->cu_bbox,
		  NULL, /* all layers, labels etc. */
		  DBCF_DISPLAY);

    /* continue search */
    return 0;
}

Void
CmdExpand(Layout *w, TxCommand *cmd)
{
    int windowMask, boxMask;
    Rect rootRect;

    if (cmd->tx_argc > 2 || (cmd->tx_argc == 2 
	&& (strncmp(cmd->tx_argv[1], "toggle", strlen(cmd->tx_argv[1])) != 0)))
    {
	MsgErrorF("Usage: %s or %s toggle\n", cmd->tx_argv[0], cmd->tx_argv[0]);
	return;
    }

    if (w == (Layout *) NULL)
    {
	MsgErrorF("Point to a window first.\n");
	return;
    }
    windowMask = w->lay_bitmask;

    if (cmd->tx_argc == 2)
    {
      SelectExpand(windowMask);
      return;
    }

    (void) ToolGetBoxWindow(&rootRect, &boxMask);
    if ((boxMask & windowMask) != windowMask)
    {
      MsgErrorF("The box isn't in the same window as the cursor.\n");
      return;
    }

    DBExpandAll(w->lay_rootUse, &rootRect, windowMask,
		TRUE, cmdExpandFunc, (ClientData) windowMask);


    /* Update expansion modes of instances in selection */
    {
      SearchContext scx;

      scx.scx_use = SelectUse;
      GeoTransRect(&scx.scx_use->cu_transform, 
		   DBBBoxCellDef(scx.scx_use->cu_def),
		   &scx.scx_area);
      scx.scx_area.r_xtop = scx.scx_area.r_xbot + 1;
      scx.scx_area.r_ytop = scx.scx_area.r_ybot + 1;
      scx.scx_trans = GeoIdentityTransform;

      (void) SelEnumCells(FALSE, 
			  (bool *) NULL, 
			  &scx,
			  (TerminalPath *) NULL,
			  (TerminalPath *) NULL,
			  cmdExpandEnumFunc, 
			  (ClientData) NULL);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdExtract --
 *
 * Implement the "extract" command.
 *
 * Usage:
 *	extract option args
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	There are no side effects on the circuit.  Various options
 *	may produce .ext files or change extraction parameters.
 *
 * ----------------------------------------------------------------------------
 */
#ifndef NO_EXT

#define	EXTALL		0
#define EXTCELL		1
#define	EXTDO		2
#define EXTHELP		3
#define	EXTLENGTH	4 
#define	EXTNO		5
#define	EXTPARENTS	6
#define	EXTSHOWPARENTS	7
#define	EXTSTYLE	8
#define	EXTUNIQUE	9
#define	EXTWARN		10

#define	WARNALL		0
#define WARNDUP		1
#define WARNDUPGLOBAL   2
#define	WARNFETS	3
#define WARNLABELS	4

#define	DOADJUST	0
#define	DOALL		1
#define	DOCAPACITANCE	2
#define	DOCOUPLING	3
#define	DOLENGTH	4
#define	DORESISTANCE	5

#define	LENCLEAR	0
#define	LENDRIVER	1
#define	LENRECEIVER	2

	/* ARGSUSED */
Void
CmdExtract(Layout *w, TxCommand *cmd)
{
    char **msg, *namep, *arg;
    int option, len, n;
    bool no, all;
    CellUse *selectedUse;
    CellDef	*selectedDef;

    static char *cmdExtWarn[] =
    {
	"all			enable all warnings",
	"dup			warn when different nodes have the same name",
	"dupglobal              warn even on global duplicate names",
	"fets			warn about badly constructed fets",
	"labels		warn when subcell nodes are unlabelled",
	NULL
    };
    static char *cmdExtOption[] =
    {
	"adjust			compensate R and C hierarchically",
	"all			all options",
	"capacitance		extract substrate capacitance",
	"coupling		extract coupling capacitance",
	"length			compute driver-receiver pathlengths",
	"resistance		estimate resistance",
	NULL
    };
    static char *cmdExtLength[] =
    {
	"clear			clear the driver and receiver tables",
	"driver termName(s)	identify a driving (output) terminal",
	"receiver termName(s)	identify a receiving (input) terminal",
	NULL
    };
    static char *cmdExtCmd[] =
    {	
	"all			extract root cell and all its children",
	"cell name		extract selected cell into file \"name\"",
	"do [option]		enable extractor option",
	"help			print this help information",
	"length [option]	control pathlength extraction information", 
	"no [option]		disable extractor option",
	"parents		extract selected cell and all its parents",
	"showparents		show all parents of selected cell",
	"style [stylename]	set current extraction parameter style",
	"unique [#]	generate unique names when different nodes\n\
			have the same name",
	"warn [ [no] option]	enable/disable reporting of non-fatal errors",
	NULL
    };

    if (w == (Layout *) NULL)
    {
	if (ToolGetBox(&selectedDef,NULL) == FALSE)
	{
	     MsgErrorF("Point to a window first\n");
	     return;
	}
	selectedUse = selectedDef->cd_uses;
    }
    else
    {
    	 selectedUse = w->lay_rootUse;
    }

    ExtSetup();

    if (cmd->tx_argc == 1)
    {
	ExtIncremental(selectedUse);
	return;
    }

    option = Lookup(cmd->tx_argv[1], cmdExtCmd);
    if (option < 0)
    {
	MsgErrorF("\"%s\" isn't a valid extract option.", cmd->tx_argv[1]);
	MsgErrorF("  Type \"extract help\" for a list of valid options.\n");
	return;
    }

    switch (option)
    {
	case EXTUNIQUE:
	    all = TRUE;
	    if (cmd->tx_argc > 2)
	    {
		if (cmd->tx_argc != 3) goto wrongNumArgs;
		if (strcmp(cmd->tx_argv[2], "#") != 0)
		{
		    MsgErrorF("Usage: extract unique [#]\n");
		    return;
		}
		all = FALSE;
	    }
	    ExtUnique(selectedUse, all);
	    break;

	case EXTALL:
	    ExtAll(selectedUse);
	    return;

	case EXTCELL:
	    if (cmd->tx_argc != 3) goto wrongNumArgs;
	    namep = cmd->tx_argv[2];
	    selectedUse = CmdGetSelectedCell((Transform *) NULL);
	    if (selectedUse == NULL)
	    {
		MsgErrorF("No cell selected\n");
		return;
	    }
	    ExtCell(selectedUse->cu_def, namep);
	    return;

	case EXTPARENTS:
	    selectedUse = CmdGetSelectedCell((Transform *) NULL);
	    if (selectedUse == NULL)
	    {
		MsgErrorF("No cell selected\n");
		return;
	    }
	    ExtParents(selectedUse);
	    return;

	case EXTSHOWPARENTS:
	    selectedUse = CmdGetSelectedCell((Transform *) NULL);
	    if (selectedUse == NULL)
	    {
		MsgErrorF("No cell selected\n");
		return;
	    }
	    ExtShowParents(selectedUse);
	    return;

	case EXTSTYLE:
	    if (cmd->tx_argc == 2)
		ExtSetStyle((char *) NULL);
	    else
		ExtSetStyle(cmd->tx_argv[2]);
	    return;

	case EXTHELP:
	    if (cmd->tx_argc != 2)
	    {
		wrongNumArgs:
		MsgErrorF("Wrong number of arguments in \"extract\" command.");
		MsgErrorF("  Try \"extract help\" for help.\n");
		return;
	    }
	    MsgInfoF("Extract commands have the form \"extract option\",\n");
	    MsgInfoF("where option is one of:\n");
	    for (msg = &(cmdExtCmd[0]); *msg != NULL; msg++)
	    {
		if (**msg == '*') continue;
		MsgInfoF("  %s\n", *msg);
	    }
	    MsgInfoF("If no option is given, the root cell and all its\n");
	    MsgInfoF("children are extracted incrementally.\n");
	    return;

#define	WARNSET(f)	((ExtDoWarn & (f)) ? "do" : "no")
	case EXTWARN:
	    if (cmd->tx_argc < 3)
	    {
		MsgInfoF("The following extractor warnings are enabled:\n");
		MsgInfoF("    %s dup\n", WARNSET(EXTWARN_DUP));
		MsgInfoF("    %s dupglobal\n", WARNSET(EXTWARN_DUPGLOBAL));
		MsgInfoF("    %s fets\n", WARNSET(EXTWARN_FETS));
		MsgInfoF("    %s labels\n", WARNSET(EXTWARN_LABELS));
		return;
	    }
#undef	WARNSET

	    no = FALSE;
	    arg = cmd->tx_argv[2];
	    if (cmd->tx_argc > 3 && strcmp(arg, "no") == 0)
		no = TRUE, arg = cmd->tx_argv[3];

	    option = Lookup(arg, cmdExtWarn);
	    if (option < 0)
	    {
		MsgErrorF("Usage: extract warnings [no] option\n");
		MsgInfoF("where option is one of:\n");
		for (msg = &(cmdExtWarn[0]); *msg != NULL; msg++)
		{
		    if (**msg == '*') continue;
		    MsgInfoF("  %s\n", *msg);
		}
		return;
	    }
	    {
	      int warn; 
	      switch (option)
	      {
	        case WARNALL:		warn = EXTWARN_ALL; break;
		case WARNDUP:		warn = EXTWARN_DUP; break;
		case WARNDUPGLOBAL:	warn = EXTWARN_DUPGLOBAL; break;
		case WARNFETS:		warn = EXTWARN_FETS; break;
		case WARNLABELS:	warn = EXTWARN_LABELS; break;
	        default:                warn=0; ASSERT(FALSE,"CmdExtract");
	      }
	      if (no) ExtDoWarn &= ~warn;
	      else ExtDoWarn |= warn;
	    }
	    return;
	case EXTDO:
	case EXTNO:
#define	OPTSET(f)	((ExtOptions & (f)) ? "do" : "no")
	    if (cmd->tx_argc < 3)
	    {
		MsgInfoF("The following are the extractor option settings:\n");
		MsgInfoF("%s adjust\n", OPTSET(EXT_DOADJUST));
		MsgInfoF("%s capacitance\n", OPTSET(EXT_DOCAPACITANCE));
		MsgInfoF("%s coupling\n", OPTSET(EXT_DOCOUPLING));
		MsgInfoF("%s length\n", OPTSET(EXT_DOLENGTH));
		MsgInfoF("%s resistance\n", OPTSET(EXT_DORESISTANCE));
		return;
#undef	OPTSET
	    }

	    no = (option == EXTNO);
	    arg = cmd->tx_argv[2];
	    option = Lookup(arg, cmdExtOption);
	    if (option < 0)
	    {
		MsgErrorF("Usage: extract do option\n");
		MsgErrorF("   or  extract no option\n");
		MsgInfoF("where option is one of:\n");
		for (msg = &(cmdExtOption[0]); *msg != NULL; msg++)
		{
		    if (**msg == '*') continue;
		    MsgInfoF("  %s\n", *msg);
		}
		return;
	    }
	    switch (option)
	    {
		case DOADJUST:		option = EXT_DOADJUST; break;
		case DOALL:		option = EXT_DOALL; break;
		case DOCAPACITANCE:	option = EXT_DOCAPACITANCE; break;
		case DOCOUPLING:	option = EXT_DOCOUPLING; break;
		case DOLENGTH:		option = EXT_DOLENGTH; break;
		case DORESISTANCE:	option = EXT_DORESISTANCE; break;
	    }
	    if (no) ExtOptions &= ~option;
	    else ExtOptions |= option;
	    return;
	case EXTLENGTH:
	    if (cmd->tx_argc < 3)
		goto lenUsage;
	    arg = cmd->tx_argv[2];
	    len = Lookup(arg, cmdExtLength);
	    if (len < 0)
	    {
lenUsage:
		MsgErrorF("Usage: extract length option [args]\n");
		MsgInfoF("where option is one of:\n");
		for (msg = &(cmdExtLength[0]); *msg != NULL; msg++)
		{
		    if (**msg == '*') continue;
		    MsgInfoF("  %s\n", *msg);
		}
		return;
	    }
	    switch (len)
	    {
		case LENCLEAR:
		    ExtLengthClear();
		    break;
		case LENDRIVER:
		    if (cmd->tx_argc < 4)
		    {
driverUsage:
			MsgErrorF("Must specify one or more terminal names\n");
			return;
		    }
		    for (n = 3; n < cmd->tx_argc; n++)
			ExtSetDriver(cmd->tx_argv[n]);
		    break;
		case LENRECEIVER:
		    if (cmd->tx_argc < 4)
			goto driverUsage;
		    for (n = 3; n < cmd->tx_argc; n++)
			ExtSetReceiver(cmd->tx_argv[n]);
		    break;
	    }
	    return;
    }

    /*NOTREACHED*/
}
#endif





