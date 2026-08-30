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
 * mgcFI.c --
 *
 * Commands with names beginning with the letters F through I.
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
static char rcsid[] = "$Header: CmdFI.c,v 6.0 90/08/28 18:07:14 mayo Exp $";
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
#include "mgcint.h"
#include "message.h"
#include "drc.h"
#include "mgcint.h"
#include "styles.h"
#include "extract.h"
#include "malloc.h"
#include "select.h"
#include "units.h"

/* The following structure is used by CmdFill to keep track of
 * areas to be filled.
 */

struct cmdFillArea
{
    Rect cfa_area;			/* Area to fill. */
    TileType cfa_type;			/* Type of material. */
    struct cmdFillArea *cfa_next;	/* Next in list of areas to fill. */
};

/*
 * ----------------------------------------------------------------------------
 *
 * CmdFeedback --
 *
 * 	Implement the "feedback" command, which provides facilities
 *	for querying and manipulating feedback information provided
 *	by other commands when they have troubles or want to highlight
 *	certain things.
 *
 * Usage:
 *	feedback option [additional_args]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Depends on the option.
 *
 * ----------------------------------------------------------------------------
 */

#undef	CLEAR
#define ADD		0
#define CLEAR		1
#define COUNT		2
#define FIND		3
#define SAVE		4
#define WHY		5

	/* ARGSUSED */

void
CmdFeedback(Layout *w, TxCommand *cmd)
{
    static char *cmdFeedbackOptions[] =
    {
	"add",
	"clear",
	"count",
	"find",
	"save",
	"why",
	NULL
    };
    static char *cmdFeedbackStyleNames[] =
    {
	"dotted", "medium", "outline", "pale", "solid", NULL
    };
    static int cmdFeedbackStyles[] =
    {
	STYLE_FEEDBACK_DOTTED, STYLE_FEEDBACK_MEDIUM,
	STYLE_FEEDBACK_OUTLINE, STYLE_FEEDBACK_PALE,
	STYLE_FEEDBACK_SOLID, -1
    };
    static int nth = 0;			/* Last entry displayed in
					 * "feedback find".
					 */
    int option, i, style;
    Rect box;
    char *text, **msg;
    CellDef *rootDef;
    HashTable table;
    HashEntry *h;
    FILE *f;

    if (cmd->tx_argc < 2)
    {
	badusage:
	MsgErrorF("Wrong number of arguments for \"feedback\" command.\n");
	MsgErrorF("Please consult 'Text Commands' under the 'Help' menu.\n");
	return;
    }
    option = Lookup(cmd->tx_argv[1], cmdFeedbackOptions);
    if (option < 0)
    {
	MsgErrorF("%s isn't a valid feedback option.\n",
	    cmd->tx_argv[1]);
	MsgErrorF("Please consult 'Text Commands' under the 'Help' menu.\n");
	return;
    }
    switch (option)
    {
	case ADD:
	    if (cmd->tx_argc == 3) style = STYLE_FEEDBACK_PALE;
	    else
	    {
		if (cmd->tx_argc != 4) goto badusage;
		i = Lookup(cmd->tx_argv[3], cmdFeedbackStyleNames);
		if (i < 0)
		{
		    MsgErrorF("%s isn't a valid display style.  Try one of:\n",
			cmd->tx_argv[3]);
		    MsgErrorF("    dotted        pale\n");
		    MsgErrorF("    medium        solid\n");
		    MsgErrorF("    outline\n");
		    break;
		}
		style = cmdFeedbackStyles[i];
	    }
	    w = ToolGetBoxWindow(&box, (int *) NULL);
	    if (w == NULL) return;
	    rootDef = w->lay_rootUse->cu_def;
	    LayFeedbackAdd(&box, cmd->tx_argv[2], rootDef, 1, style);
	    break;
	
	case CLEAR:
	    if (cmd->tx_argc != 2) goto badusage;
	    LayFeedbackClear();
	    nth = 0;
	    break;
	
	case COUNT:
	    if (cmd->tx_argc != 2) goto badusage;
	    MsgInfoF("There are %d feedback areas.\n", LayFeedbackCount);
	    break;
	
	case FIND:
	    if (cmd->tx_argc > 3) goto badusage;
	    if (LayFeedbackCount == 0)
	    {
		MsgInfoF("There are no feedback areas right now.\n");
		break;
	    }
	    if (cmd->tx_argc == 3)
	    {
		nth = atoi(cmd->tx_argv[2]);
		if ((nth > LayFeedbackCount) || (nth <= 0))
		{
		    MsgErrorF("Sorry, but only feedback areas 1-%d exist.\n",
			LayFeedbackCount);
		    nth = 1;
		}
	    }
	    else
	    {
		nth += 1;
		if (nth > LayFeedbackCount) nth = 1;
	    }
	    text = LayFeedbackNth(nth-1, &box, &rootDef, (int *) NULL);
	    LaySetBox(rootDef, &box);
	    MsgInfoF("Feedback #%d: %s\n", nth, text);
	    break;
	
	case SAVE:
	    if (cmd->tx_argc != 3) goto badusage;
	    f = PaOpen(cmd->tx_argv[2], "w", (char *) NULL, ".",
	        (char *) NULL, (char **) NULL);
	    if (f == NULL)
	    {
		MsgErrorF("Can't open file %s.\n", cmd->tx_argv[2]);
		break;
	    }
	    for (i = 0; i < LayFeedbackCount; i++)
	    {
		int j, style;
		text = LayFeedbackNth(i, &box, (CellDef **) NULL, &style);

		/* output lay_box ... */
		fprintf(f, "lay_box ");
                fprintf(f, "%s ", UnitsI2S(box.r_xbot));
                fprintf(f, "%s ", UnitsI2S(box.r_ybot));
                fprintf(f, "%s ", UnitsI2S(box.r_xtop));
                fprintf(f, "%s\n", UnitsI2S(box.r_ytop));

                /* output :feedback add ... */			
		{	
		  Tcl_DString ds;
		  Tcl_DStringInit(&ds);

		  Tcl_DStringAppend(&ds,":feedback add",-1);
		  Tcl_DStringAppendElement(&ds,text);
		  for (j = 0; cmdFeedbackStyles[j] >= 0; j++)
		  {
		    if (cmdFeedbackStyles[j] == style)
		    {
			Tcl_DStringAppendElement(&ds,cmdFeedbackStyleNames[j]);
			break;
		    }
		  }
		  Tcl_DStringAppend(&ds,"\n",-1);
		  fputs(Tcl_DStringValue(&ds),f);

		  Tcl_DStringFree(&ds);
		}
	    }
	    (void) fclose(f);
	    break;
	
	case WHY:
	    if (cmd->tx_argc > 2) goto badusage;
	    w = ToolGetBoxWindow(&box, (int *) NULL);
	    if (w == NULL) return;
	    rootDef = w->lay_rootUse->cu_def;
	    HashInit(&table, 16, 0);
	    for (i=0; i<LayFeedbackCount; i++)
	    {
		Rect area;
		CellDef *fbRootDef;

		text = LayFeedbackNth(i, &area, &fbRootDef, (int *) NULL);
		if (rootDef != fbRootDef) continue;
		if (!GEO_OVERLAP(&box, &area)) continue;
		h = HashFind(&table, text);
		if (HashGetValue(h) == 0) MsgInfoF("%s\n", text);
		HashSetValue(h, 1);
	    }
	    HashKill(&table);
	    break;
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdFill --
 *
 * Implement the "fill" command.  Find all paint touching one side
 * of the box, and paint it across to the other side of the box.  Can
 * operate in any of four directions.
 *
 * Usage: 
 *	fill direction [layers]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the edit cell definition.
 *
 * ----------------------------------------------------------------------------
 */

/* Data passed between CmdFill and cmdFillFunc: */

int cmdFillDir;				/* Direction in which to fill. */
Rect cmdFillRootBox;			/* Root coords of box. */
struct cmdFillArea *cmdFillList;	/* List of areas to fill. */

void
CmdFill(Layout *w, TxCommand *cmd)
                 		/* Window in which command was invoked. */
                   	/* Describes the command that was invoked. */
{
    TileTypeBitMask maskBits;
    Rect editBox;
    SearchContext scx;
    extern int cmdFillFunc(Tile *tile, TreeContext *cxp);

    if (cmd->tx_argc < 2 || cmd->tx_argc > 3)
    {
	MsgErrorF("Usage: %s direction [layers]\n", cmd->tx_argv[0]);
	return;
    }

    if ( w == (Layout *) NULL )
    {
	MsgErrorF("Point to a window\n");
	return;
    }

    /* Find and check validity of position argument. */

    cmdFillDir = GeoNameToPos(cmd->tx_argv[1], TRUE, TRUE);
    if (cmdFillDir < 0)
	return;

    /* Figure out which layers to fill. */

    if (cmd->tx_argc < 3)
	maskBits = DBAllButSpaceAndDRCBits;
    else
    {
	if (!CmdParseLayers(cmd->tx_argv[2], &maskBits))
	    return;
    }

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    /* Figure out which material to search for and invoke a search
     * procedure to find it.
     */

    if (!ToolGetEditBox(&editBox)) return;
    GeoTransRect(&EditToRootTransform, &editBox, &cmdFillRootBox);
    scx.scx_area = cmdFillRootBox;
    switch (cmdFillDir)
    {
	case GEO_NORTH:
	    scx.scx_area.r_ytop = scx.scx_area.r_ybot + 1;
	    scx.scx_area.r_ybot -= 1;
	    break;
	case GEO_SOUTH:
	    scx.scx_area.r_ybot = scx.scx_area.r_ytop - 1;
	    scx.scx_area.r_ytop += 1;
	    break;
	case GEO_EAST:
	    scx.scx_area.r_xtop = scx.scx_area.r_xbot + 1;
	    scx.scx_area.r_xbot -= 1;
	    break;
	case GEO_WEST:
	    scx.scx_area.r_xbot = scx.scx_area.r_xtop - 1;
	    scx.scx_area.r_xtop += 1;
	    break;
    }
    scx.scx_use = w->lay_rootUse;
    scx.scx_trans = GeoIdentityTransform;
    cmdFillList = (struct cmdFillArea *) NULL;

    (void) DBSearchPaint(&scx, &maskBits,
	    w->lay_bitmask,
	    cmdFillFunc, (ClientData) NULL);

    /* Now that we've got all the material, scan over the list
     * painting the material and freeing up the entries on the list.
     */
    while (cmdFillList != NULL)
    {
	DBPaint(EditCellUse->cu_def, &cmdFillList->cfa_area,
		cmdFillList->cfa_type);
	freeMagic((char *) cmdFillList);
	cmdFillList = cmdFillList->cfa_next;
    }

    SelectClear();

    /* process database changes */
    DBChangedArea(EditCellUse->cu_def, &editBox, &maskBits, 0);
}

/* Important note:  these procedures can't paint the tiles directly,
 * because a search is in progress over the same planes and if we
 * paint here it may mess up the search.  Instead, the procedures
 * save areas on a list.  The list is post-processed to paint the
 * areas once the search is finished.
 */

int
cmdFillFunc(Tile *tile, TreeContext *cxp)
               			/* Tile to fill with. */
                     		/* Describes state of search. */
{
    Rect r1, r2;
    struct cmdFillArea *cfa;

    TiToRect(tile, &r1);
    GeoTransRect(&cxp->tc_scx->scx_trans, &r1, &r2);
    GeoClip(&r2, &cmdFillRootBox);
    switch (cmdFillDir)
    {
	case GEO_NORTH:
	    r2.r_ytop = cmdFillRootBox.r_ytop;
	    break;
	case GEO_SOUTH:
	    r2.r_ybot = cmdFillRootBox.r_ybot;
	    break;
	case GEO_EAST:
	    r2.r_xtop = cmdFillRootBox.r_xtop;
	    break;
	case GEO_WEST:
	    r2.r_xbot = cmdFillRootBox.r_xbot;
	    break;
    }
    GeoTransRect(&RootToEditTransform, &r2, &r1);
    cfa = (struct cmdFillArea *) mallocMagic(sizeof(struct cmdFillArea));
    cfa->cfa_area = r1;
    cfa->cfa_type = DBgetTileType(tile);
    cfa->cfa_next = cmdFillList;
    cmdFillList = cfa;
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdFindBox --
 *
 * Center the display on a corner of the box.  If 'zoom', then make the box
 * fill the window.
 *
 * Usage:
 *	findbox [zoom]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window underneath the cursor is moved.
 *
 * ----------------------------------------------------------------------------
 */

void
CmdFindBox(Layout *w, TxCommand *cmd)
{
    CellDef *boxDef;
    Rect box;

    if (w == NULL)
    {
	MsgErrorF("Point to a window first.\n");
	return;
    };

    if (!ToolGetBox(&boxDef, &box))
    {
	MsgErrorF("Put the box in a window first.\n");
	return;
    };

    if (boxDef != w->lay_rootUse->cu_def)
    {
	MsgErrorF("The box is not in the same coordinate " 
		"system as the window.\n");
	return;
    };

    if (cmd->tx_argc == 1) 
    {
	/* center view on box */
	Point rootPoint;
	Rect newArea, oldArea;

	rootPoint.p_x = (box.r_xbot + box.r_xtop)/2;
	rootPoint.p_y = (box.r_ybot + box.r_ytop)/2;

	oldArea = w->lay_dbArea;
	newArea.r_xbot = rootPoint.p_x - (oldArea.r_xtop - oldArea.r_xbot)/2;
	newArea.r_xtop = newArea.r_xbot - oldArea.r_xbot + oldArea.r_xtop;
	newArea.r_ybot = rootPoint.p_y - (oldArea.r_ytop - oldArea.r_ybot)/2;
	newArea.r_ytop = newArea.r_ybot - oldArea.r_ybot + oldArea.r_ytop;

	LayFrame(w, &newArea);
	return;
    }
    else if (cmd->tx_argc == 2)
    {
	int expand;

	/* zoom in to box */

	if (strcmp(cmd->tx_argv[1], "zoom") != 0) goto usage;

	/* Allow a 5% ring around the box on each side. */

	expand = (box.r_xtop - box.r_xbot)/20;
	if (expand < 2) expand = 2;
	box.r_xtop += expand;
	box.r_xbot -= expand;
	expand = (box.r_ytop - box.r_ybot)/20;
	if (expand < 2) expand = 2;
	box.r_ytop += expand;
	box.r_ybot -= expand;

	LayFrame(w, &box);
	return;
    };

usage:
    MsgErrorF("Usage: findbox [zoom]\n");
}


/*
 * cmdGetcellFunc --
 *
 * Search function used to locate positioning label.  It just computes
 * the lower-left corner of the label and aborts the search.
 *
 * Results:
 *	Always returns 1.
 *
 * Side effects:
 *	Sets *point to the lower-left corner of the label.
 */
    /* ARGSUSED */
static int
cmdGetcellFunc(Rect *rect, char *name, Label *label, Point *point)
               			/* Root coordinates of the label. */
               			/* Label name (not used). */
                 		/* Pointer to label (not used). */
                 		/* Place to store label's lower-left. */
{
    *point = rect->r_ll;
    return 1;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdFlush --
 *
 * Implement the "flush" command.
 * Throw away all changes made within magic to the specified cell,
 * and re-read it from disk.  If no cell is specified, the default
 * is the current edit cell.
 *
 * Usage:
 *	flush [cellname]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	THIS IS NOT UNDO-ABLE!
 *	Modifies the specified CellDef.
 *
 * ----------------------------------------------------------------------------
 */
 /*ARGSUSED*/

void
CmdFlush(Layout *w, TxCommand *cmd)
{
    CellDef *def;
    int action;
    static char *actionNames[] = { "no", "yes", 0 };
    char answer[100];

    if (cmd->tx_argc > 2)
    {
	MsgErrorF("Usage: flush [cellname]\n");
	return;
    }

    if (cmd->tx_argc == 1)
	def = EditCellUse->cu_def;
    else
    {
	def = DBCellLookDef(cmd->tx_argv[1]);
	if (def == (CellDef *) NULL)
	{
	    /* an error message has already been printed by the database */
	    return;
	}
    }

    cmdFlushCell(def);
    MsgInfoF("cell %s reverted to last saved.\n",def->cd_name);
}



/*
 * ----------------------------------------------------------------------------
 *
 * cmdGetcellParseArgs --
 *
 * parse args for :getcell, read in child cell, compute transform
 * implied by reference points.
 *
 * Results:
 *      TRUE on success; FALSE if arguments were missing or
 *	incorrect, or if the cell couldn't be found.
 *
 * Side effects:
 *	Fills in *dummy so that dummy->cu_def points to the cell
 *	specified by name in cmd->tx_argv[] 
 *
 *	Also fills in
 *	*scx so scx_use is dummy, scx_trans is the desired transform
 *	from dummy->cu_def back to root coordinates, and scx_area
 *	is the bounding box of dummy->cu_def. 
 *
 * ----------------------------------------------------------------------------
 */
static bool
cmdGetcellParseArgs(int argc,
		        /* arg count */
		 char **argv,
                   	/* arg list */
		 Layout *w, 
               		/* Window in which command was invoked (UNUSED) */
		 CellUse *dummy, 
                   	/* Filled in to point to cell mentioned in command */
		 SearchContext *scx,
                       	/* Filled in with the transform from the child cell's
			 * def to ROOT coordinates, the bounding box of the
			 * child cell in child cell coordinates, and with
			 * scx_use = dummy, where dummy->cu_def is the child
			 * cell itself.
			 */
		 bool *dupOK)
		        /* filled in according to -dup_ok */ 
{
    char *cmdName;
    char *cellName;
    Point childPoint, editPoint, rootPoint;
    CellDef *def, *rootDef, *editDef;
    bool hasChild, hasRoot;
    Rect rootBox;
    char c;

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;
    
    /* Parse command line switchs */
    *dupOK = FALSE;
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='d' && strncmp(*argv,"-dup_ok",length)==0)
      {
	argc--; argv++;
	*dupOK = TRUE;
	continue;
      }

      /* unrecognized option */
      goto usage;
    } /* end while(argc>0 && **argv=='-')  */

    /* parse cell name */
    if(argc <= 0) goto usage;
    cellName = *argv;
    argc--; argv++;

    /* Locate the cell specified by the cell name */
    if (CmdIllegalChars(cellName, "", "Cell name")) return (FALSE);
    def = DBCellLookDef(cellName);
    if (def == (CellDef *) NULL)
	def = DBCellNewDef(cellName, (char *) NULL);
    editDef = EditCellUse->cu_def;
    
    /*
     * The following line of code is a bit of a hack.  It's needed to
     * force DBCellRead to print an error message if it can't find the
     * cell.  Otherwise, if the cell wasn't found the last time it was
     * looked for then no new error message will be printed.
     */
    def->cd_flags &= ~CDNOTFOUND;
    if (!DBCellRead(def, (char *) NULL, TRUE)) return (FALSE);
    DBCellInitTempUse(def, dummy);
    dummy->cu_expandMask = -1;

    /*
     * Parse the remainder of the arguments to find out the reference
     * points in the child cell and the edit cell.  Use the defaults
     * of the lower-left corner of the child cell's bounding box, and
     * the lower-left corner of the box tool, if the respective reference
     * points weren't provided.  (Lower-left of the box tool is interpreted
     * in root coordinates).
     */
    hasChild = hasRoot = FALSE;
    while (argc > 0)
    {
	static char *kwdNames[] = { "child", "parent", 0 };
	Label *lab;
	int n;

	n = Lookup(argv[0], kwdNames);
	if (n < 0)
	{
	    MsgErrorF("Unrecognized parent/child keyword: \"%s\"\n", argv[0]);
	    goto usage;
	}
	if (argc < 2)
	{
	    MsgErrorF("Keyword must be followed by a reference point\n");
	    goto usage;
	}
	switch (n)
	{
	    case  0:	/* Child */
		if (UnitsValidS(argv[1]))
		{
		    childPoint.p_x = UnitsS2I(argv[1]);
		    if (argc < 3 || !UnitsValidS(argv[2]))
		    {
			MsgErrorF("Must provide two coordinates\n");
			goto usage;
		    }
		    childPoint.p_y = UnitsS2I(argv[2]);
		    argv += 3;
		    argc -= 3;
		}
		else
		{
		    childPoint = TiPlaneRect.r_ur;
		    (void) DBLabelFindByPathName(dummy, 
					argv[1], 
					cmdGetcellFunc, 
					&childPoint,
					FALSE /* dynamic load enabled */ );
		    if (childPoint.p_x == TiPlaneRect.r_xtop &&
			    childPoint.p_y == TiPlaneRect.r_ytop)
		    {
			MsgErrorF("Couldn't find label \"%s\" in cell \"%s\".\n",
				argv[1], cellName);
			return FALSE;
		    }
		    argv += 2;
		    argc -= 2;
		}
		hasChild = TRUE;
		break;
	    case  1:	/* Parent */
		if (UnitsValidS(argv[1]))
		{
		    editPoint.p_x = UnitsS2I(argv[1]);
		    if (argc < 3 || !UnitsValidS(argv[2]))
		    {
			MsgErrorF("Must provide two coordinates\n");
			goto usage;
		    }
		    editPoint.p_y = UnitsS2I(argv[2]);
		    argv += 3;
		    argc -= 3;
		}
		else
		{
		    for (lab = editDef->cd_labels; lab; lab = lab->lab_next)
			if (strcmp(lab->lab_text, argv[1]) == 0)
			    break;

		    if (lab == NULL)
		    {
			MsgErrorF("Couldn't find label \"%s\" in edit cell.\n",
				argv[1]);
			return FALSE;
		    }
		    editPoint = lab->lab_rect.r_ll;
		    argv += 2;
		    argc -= 2;
		}
		GeoTransPoint(&EditToRootTransform, &editPoint, &rootPoint);
		hasRoot = TRUE;
		break;
	}
    }

    /*
     * Use the default values if explicit reference points weren't
     * provided.
     */
    if (!hasChild)
	childPoint = DBBBoxCellDef(def)->r_ll;
    if (!hasRoot)
    {
	if (!ToolGetBox(&rootDef, &rootBox) || (rootDef != EditRootDef))
	{
	    MsgErrorF("The box's lower-left corner must point to the place\n");
	    MsgErrorF("    in the edit cell where you'd like to put \"%s\".\n",
		      cmdName);
	    return FALSE;
	}
	rootPoint = rootBox.r_ll;
    }

    scx->scx_use = dummy;
    GeoTransTranslate(rootPoint.p_x - childPoint.p_x,
	    rootPoint.p_y - childPoint.p_y,
	    &GeoIdentityTransform, &scx->scx_trans);
    scx->scx_area = *DBBBoxCellDef(def);
    return TRUE;

usage:
    MsgErrorF(
	"Usage: %s [-dup_ok] cellName [child refPointChild] [parent refPointParent]\n",
	cmdName);
    MsgErrorF("       where the refPoints are either a single label name\n");
    MsgErrorF("       or a pair of integer coordinates\n");
    fprintf(stderr,"DEBUG cmdDumpParseArgs exit usage\n");
    return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdGetcell --
 *
 *	Implement the ":getcell" command.
 *
 * Usage:
 *	getcell cellName [child refPointChild] [parent refPointParent]
 *
 * where the refPoints are either a label name, e.g., SOCKET_A, or an x-y
 * pair of integers, e.g., 100 200.  The words "child" and "parent" are
 * keywords, and may be abbreviated.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *	Makes cellName a subcell of the edit cell, positioned so
 *	that refPointChild in the child cell (or the lower-left
 *	corner of its bounding box) ends up at location refPointParent
 *	in the edit cell (or the location of the box tool's lower-left).
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
void CmdGetcell(Layout *w, 
      			     /* Window in which command was invoked. */
		TxCommand *cmd)
                             /* Describes command arguments. */
{
    CellUse dummy, *newUse;
    Transform editTrans;
    SearchContext scx;
    CellDef *def;
    Rect *bbox;
    Rect newBox;
    int result;
    bool dupOK;

    /* Leaves scx.scx_trans set to the transform from the child to root */
    if (!cmdGetcellParseArgs(cmd->tx_argc, 
			     cmd->tx_argv,
			     w, 
			     &dummy, 
			     &scx, 
			     &dupOK)) return;
    def = dummy.cu_def;

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    /* update def, before creating subcell */
    DBUpdate(def);

    /* Create the new use. */
    newUse = DBCellNewUse(def, (char *) NULL);

    /*
    fprintf(stderr,"DEBUG CmdGetCell after DBCellNewUse\n");
    */

    GeoTransTrans(&scx.scx_trans, &RootToEditTransform, &editTrans);
    DBCellUseSetTrans(newUse, &editTrans);  /* sets transform and cu_bbox */

    /* make instance */
    {
      int flags = DBIA_ERROR_ON_CIRCULAR;
      if(dupOK) 
      {
	flags |= DBIA_DUP_OK;
      }
      else
      {
	flags |= DBIA_ERROR_ON_DUP;
      }
      
      result=DBInstanceAdd(newUse, EditCellUse->cu_def, flags);
    }
    if(!result)	return;

    /* bbox is correct since we did an update of the def above */
    bbox = &newUse->cu_bbox;

    /*
     * Reposition the box tool to around the gotten cell to show
     * that it has become the current cell.
     */
    GeoTransRect(&EditToRootTransform, bbox, &newBox);
    LaySetBox(EditRootDef, &newBox);

    /* process database change */
    DBChangedArea(EditCellUse->cu_def, bbox, &DBAllButSpaceBits, DBCF_INSTANCE);

    /* if gcell, expand it */
    if(def->cd_flags&CD_GENERATED) DBExpand(newUse, LAY_ALL_WINDOWS, TRUE); 

    /* Select the new use */
    SelectClear();
    SelectCell(newUse, EditRootDef, &scx.scx_trans, FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdIdentify --
 *
 * Implement the "identify" command.
 * Sets the instance identifier for the currently selected cell.
 *
 * Usage:
 *	identify use_id
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the instance identifier for the selected cell (the
 *	first selected cell, if there are many).
 *
 * ----------------------------------------------------------------------------
 */
 /*ARGSUSED*/

void
CmdIdentify(Layout *w, TxCommand *cmd)
{
    extern int cmdIdFunc(CellUse *selUse, 
			 CellUse *use, 
			 Transform *transform, 
			 TerminalPath *tPath,   
			 char *newId);		/* Forward reference. */

    if (cmd->tx_argc != 2)
    {
	MsgErrorF("Usage: identify use_id\n");
	return;
    }

    if (CmdIllegalChars(cmd->tx_argv[1], "[],/", "Cell use id"))
	return;

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    if (SelEnumCells(FALSE, 
		     (int *) NULL, 
		     (SearchContext *) NULL,
		     (TerminalPath *) NULL,
		     (TerminalPath *) NULL,
		     cmdIdFunc, 
		     (ClientData) cmd->tx_argv[1]) 
	== 0)
    {
	MsgErrorF("There isn't a selected subcell;  can't change ids.\n");
	return;
    }
}

    /* ARGSUSED */
int
cmdIdFunc(CellUse *selUse, 
                 		/* Use from selection cell. */
	  CellUse *use, 
                 		/* Use from layout that corresponds to
				 * selUse.
				 */
	  Transform *transform, 
	  TerminalPath *tPath,
	  char *newId)
                		/* New id for cell use. */
{
    if (!DBIsChild(use, EditCellUse))
    {
	MsgErrorF("Cell %s (%s) isn't a child of the edit cell.\n",
	    use->cu_id, use->cu_def->cd_name);
	MsgErrorF("    Cell identifier not changed.\n");
	return 1;
    }

    if (!DBInstanceRename(use, newId))
    {
	MsgErrorF("New name isn't unique within its parent definition.\n");
	MsgErrorF("    Cell identifier not changed.\n");
	return 1;
    }

    /* Change the id of the cell in the selection too, so that they
     * stay in sync.
     */
    (void) DBInstanceRename(selUse, newId);

    /* change notifications */
    use->cu_parent->cd_flags |= CDMODIFIED;
    DBChangedArea(use->cu_parent, 
		  &use->cu_bbox,
		  &DBAllButSpaceBits,
		  DBCF_DISPLAY);

/* this should be taken care of by above?
    LayChangedHighlight(EditRootDef, 
			selUse->cu_bbox, 
			TRUE);
*/

    return 1;
}
