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
 * MgcRS.c --
 *
 * Commands with names beginning with the letters R through S.
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
static char rcsid[] = "$Header: CmdRS.c,v 6.0 90/08/28 18:07:21 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include <string.h>

#include "magic.h"
#include "stack.h"
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
#include "main.h"
#include "drc.h"
#include "heap.h"
#include "select.h"
#include "Mgc.h"
#include "mgcint.h"

#include "units.h"

extern void DisplayWindow();

/*DEBUG*/ 
void debugMask(char *msg, TileTypeBitMask *mask)
{
  fprintf(stderr,"%s %0o %0o %0o\n",
	  msg,
	  mask->tt_words[0],
	  mask->tt_words[1],
	  mask->tt_words[2]);
}


/* these guys are used in a couple of places */
int RtrMetalWidth=2, RtrPolyWidth=2, RtrContactWidth=2;


/*
 * ----------------------------------------------------------------------------
 *
 * CmdSave --
 *
 * Implement the "save" command.
 * Writes the EditCell out to a disk file.
 *
 * Usage:
 *	save [file]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes the cell out to file, if specified, or the file
 *	associated with the cell otherwise.
 *	Updates the caption in the window if the name of the edit
 *	cell has changed.
 *	Clears the modified bit in the cd_flags.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

void CmdSave(Layout *w, TxCommand *cmd)
{
    CellDef *def;

    if (cmd->tx_argc > 2)
    {
	MsgErrorF("Usage: %s [file]\n", cmd->tx_argv[0]);
	return;
    }

    ASSERT(EditCellUse != (CellUse *) NULL, "CmdSave");
    def = EditCellUse->cu_def;
 
    if (cmd->tx_argc == 2)
    {
	if (CmdIllegalChars(cmd->tx_argv[1], "[],", "Cell name"))
	    return;
	cmdSaveCell(def, cmd->tx_argv[1], TRUE);
    }
    else 
    {
      /* don't save read-only cell */
      if(def->cd_flags&CDREADONLY)
      {
	MsgErrorF("Cell %s not saved (cell buffer is read-only!)\n", 
		  def->cd_name);
	return;
      }

      cmdSaveCell(def, (char *) NULL, TRUE);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdSee --
 *
 * 	This procedure is used to enable or disable display of certain
 *	things on the screen.
 *
 * Usage:
 *	see [no] stuff
 *
 *	Stuff consists of mask layers or the keyword "allSame"
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The indicated mask layers are enabled or disabled from being
 *	displayed in the current window.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

void CmdSee(Layout *w, TxCommand *cmd)
{
    int flags;
    bool off;
    char *arg;
    TileTypeBitMask mask;
    Layout *crec;

    if (!w)
    {
	MsgErrorF("Point to a layout window first.\n");
	return;
    }
    crec = w;

    arg = (char *) NULL;
    off = FALSE;
    flags = 0;
    if (cmd->tx_argc > 1)
    {
	if (strcmp(cmd->tx_argv[1], "no") == 0)
	{
	    off = TRUE;
	    if (cmd->tx_argc > 2) arg = cmd->tx_argv[2];
	}
	else arg = cmd->tx_argv[1];
	if ((cmd->tx_argc > 3) || ((cmd->tx_argc == 3) && !off))
	{
	    MsgErrorF("Usage: :see [no] layers|allSame|hiddenLabels|instanceNames|instancePorts\n");
	    return;
	}
    }

    /* Figure out which things to set or clear.  Don't ever make space
     * invisible:  that doesn't make any sense.
     */

    if (arg != NULL)
    {
	if (strcmp(arg, "allSame") == 0)
	{
	    mask = DBZeroTypeBits;
	    flags = Lay_ALLSAME;
	}
	else if (strcmp(arg, "flyLines") == 0)
	{
	    mask = DBZeroTypeBits;
	    flags = Lay_SEEFLYLINES;
	}
	else if (strcmp(arg, "hiddenLabels") == 0)
	{
	    mask = DBZeroTypeBits;
	    flags = Lay_SEEHIDDENLABELS;
	}
	else if (strcmp(arg, "instanceNames") == 0)
	{
	    mask = DBZeroTypeBits;
	    flags = Lay_SEEINSTANCENAMES;
	}
	else if (strcmp(arg, "instancePorts") == 0)
	{
	    mask = DBZeroTypeBits;
	    flags = Lay_SEEINSTANCEPORTS;
	}
	else
	{
	    if (!CmdParseLayers(arg, &mask))
		return;
	}
    }
    else mask = DBAllTypeBits;

    if(TTMaskHasType(&mask, L_LABEL))	flags |= Lay_SEELABELS;
    TTMaskClearType(&mask, L_LABEL);
    TTMaskClearType(&mask, L_CELL);
    TTMaskClearType(&mask, L_FLYLINE);
    TTMaskClearType(&mask, TT_SPACE);

    if (off)
    {
	int i;
	for (i = 0; i < DBNumUserLayers; i++)
	{
	    if (TTMaskHasType(&mask, i))
		TTMaskClearType(&crec->lay_visibleLayers,i);
	}
	crec->lay_flags &= ~flags;
    }
    else
    {
	int i;
	for (i = 0; i < DBNumUserLayers; i++)
	{
	    if (TTMaskHasType(&mask, i))
		TTMaskSetType(&crec->lay_visibleLayers,i);
	}
	crec->lay_flags |= flags;
    }
    LayChangedDisplay(w);
    return;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdSideways --
 *
 * Implement the "sideways" command.
 *
 * Usage:
 *	sideways
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection and box are flipped left-to-right, using the
 *	center of the selection as the axis for flipping.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

void CmdSideways(Layout *w, TxCommand *cmd)
{
    Transform trans;
    Rect rootBox, bbox;
    CellDef *rootDef;

    if (cmd->tx_argc != 1)
    {
	MsgErrorF("Usage: %s\n", cmd->tx_argv[0]);
	return;
    }

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    /* To flip the selection sideways, first flip it around the
     * y-axis, then move it back so its lower-left corner is in
     * the same place that it used to be.
     */
    
    {
      Rect *selBBox = DBBBoxCellDef(SelectDef);
      GeoTransRect(&GeoSidewaysTransform, selBBox, &bbox);
      GeoTranslateTrans(&GeoSidewaysTransform,
			selBBox->r_xbot - bbox.r_xbot,
			selBBox->r_ybot - bbox.r_ybot, 
			&trans);
      SelectTransform(&trans, FALSE /* disallow dup instances */);
    }

    /* Flip the box, if it exists and is in the same window as the
     * selection.
     */
    
    if (ToolGetBox(&rootDef, &rootBox) && (rootDef == SelectRootDef))
    {
	Rect newBox;

	GeoTransRect(&trans, &rootBox, &newBox);
	LaySetBox(rootDef, &newBox);
    }

    return;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdStretch --
 *
 * Implement the "stretch" command.
 *
 * Usage:
 *	stretch [-g] [direction [distance]]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Moves everything that's currently selected, erases material that
 *	the selection would sweep over, and fills in material behind the
 *	selection.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

void
CmdStretch(Layout *w, TxCommand *cmd)
{
    Transform t;
    Rect rootBox, newBox;
    CellDef *rootDef;
    int xdelta, ydelta;
    char **argv = cmd->tx_argv;
    int argc = cmd->tx_argc;
    bool group = FALSE;
    char *cmdName = argv[0];

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    /* check for "-g" arg */
    if(argc>1 && strcmp(argv[1],"-g")==0) 
    {
        group = TRUE;
	argv++;
	argc--;
    }

    if (argc > 3)
    {
	badUsage:
	MsgErrorF("Usage: %s [-g] [direction [amount]]\n", cmdName);
	return;
    }

    if (argc > 1)
    {
	int indx, amount;

	indx = GeoNameToPos(argv[1], TRUE, TRUE);
	if (indx < 0)
	    return;
	if (argc == 3)
	{
	    if (!UnitsValidS(argv[2])) goto badUsage;
	    amount = UnitsS2I(argv[2]);
	}
	else amount = 1;

	switch (indx)
	{
	    case GEO_NORTH:
		xdelta = 0;
		ydelta = amount;
		break;
	    case GEO_SOUTH:
		xdelta = 0;
		ydelta = -amount;
		break;
	    case GEO_EAST:
		xdelta = amount;
		ydelta = 0;
		break;
	    case GEO_WEST:
		xdelta = -amount;
		ydelta = 0;
		break;
	    default:
		ASSERT(FALSE, "Bad direction in CmdStretch");
		return;
	}
	GeoTransTranslate(xdelta, ydelta, &GeoIdentityTransform, &t);

	/* Move the box by the same amount as the selection, if the
	 * box exists.
	 */

	if (ToolGetBox(&rootDef, &rootBox) && (rootDef == SelectRootDef))
	{
	    GeoTransRect(&t, &rootBox, &newBox);
	    LaySetBox(rootDef, &newBox);
	}
    }
    else
    {
	/* Use the displacement between the box lower-left corner and
	 * the point as the transform.  Round off to a Manhattan distance.
	 */
	
	Point rootPoint;
	Layout *window;
	int absX, absY;

	if (!ToolGetBox(&rootDef, &rootBox) || (rootDef != SelectRootDef))
	{
	    MsgErrorF("\"Stretch\" uses the box lower-left corner as a place\n");
	    MsgErrorF("    to pick up the selection for stretching, but the\n");
	    MsgErrorF("    box isn't in a window containing the selection.\n");
	    return;
	}
	window = LayPointGet(&rootPoint, (Rect *) NULL);
	if ((window == NULL) ||
	    (EditRootDef != window->lay_rootUse->cu_def))
	{
	    MsgErrorF("\"Stretch\" uses the point as the place to put down a\n");
	    MsgErrorF("    the selection, but the point doesn't point to the\n");
	    MsgErrorF("    edit cell.\n");
	    return;
	}
	xdelta = rootPoint.p_x - rootBox.r_xbot;
	ydelta = rootPoint.p_y - rootBox.r_ybot;
	if (xdelta < 0) absX = -xdelta;
	else absX = xdelta;
	if (ydelta < 0) absY = -ydelta;
	else absY = ydelta;
	if (absY <= absX) ydelta = 0;
	else xdelta = 0;
	GeoTransTranslate(xdelta, ydelta, &GeoIdentityTransform, &t);
	GeoTransRect(&t, &rootBox, &newBox);
	LaySetBox(rootDef, &newBox);
    }
    
    SelectStretch(xdelta, ydelta, group);
}
