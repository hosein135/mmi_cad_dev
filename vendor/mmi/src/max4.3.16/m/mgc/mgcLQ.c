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
 * mgcLQ.c --
 *
 * Old Magic commands with names beginning with the letters L through Q.
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
static char rcsid[] = "$Header: CmdLQ.c,v 6.0 90/08/28 18:07:18 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
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
#include "undo.h"
#include "select.h"
#include "debug.h"
#ifdef SYSV
#include <string.h>
#endif
#include "units.h"


/*
 * ----------------------------------------------------------------------------
 *
 * cmdLabelProc --
 *
 * 	This procedure does all the work of putting a label except for
 *	parsing argments.  It is separated from CmdLabel so it can be
 *	used by the net-list menu system.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A label is added to the edit cell at the box location, with
 *	the given text position, on the given layer.  If type is -1,
 *	then the layer is added to the top layer underneath the box.
 *
 * ----------------------------------------------------------------------------
 */

static void
cmdLabelProc(char *text, 
               			/* Text for label. */
	     int pos, 
            			/* Position for text relative to text. -1
				 * means "pick a nice one for me."
				 */
	     TileType type, 
                  		/* Type of material label is to be attached
				 * to.  -1 means "pick a reasonable layer".
				 */
	     int kind)      
                                /* label kind */
{
    Rect editBox;

    /* Make sure the box exists */
    if (!ToolGetEditBox(&editBox)) return;

    /* Make sure there's a valid string of text. */
    if(!DBLabelNameCheck(text)) return; 

    /* check for read-only */
    if(type == -1)
    {
      if(DBAccessModify(EditCellUse->cu_def)) return;
    }
    else
    {
      if(!DBAccessModifyType(EditCellUse->cu_def,type)) return;
    }

    DBLabelAdd(EditCellUse->cu_def, 
	       &editBox, 
	       pos, 
	       text, 
	       type,
	       kind);

    DBChangedArea(EditCellUse->cu_def, &editBox, NULL, DBCF_LABEL_ONLY);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdLabel --
 *
 * Implement the "label" command.
 * Place a label at a specific point on a specific type in EditCell
 *
 * Usage:
 *	label text [direction [layer]]
 *
 * Direction may be one of:
 *	right left top bottom
 *	east west north south
 *	ne nw se sw
 * or any unique abbreviation.  If not specified, it defaults to a value
 * chosen to keep the label text inside the cell.
 *
 * Layer defaults to the type of material beneath the degenerate box.
 * If the box is a rectangle, then use the lower left corner to determine
 * the material.
 *
 * If more than more than one tiletype other than space touches the box,
 * then the "layer" must be specified in the command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modified EditCellUse->cu_def.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

Void
CmdLabel(Layout *w, TxCommand *cmd)
{
    TileType type;
    int pos;
    char *p;
    int kind = LAB_COMMENT;
    int argc = cmd->tx_argc;
    char **argv = &(cmd->tx_argv[0]);
    char *cmdName = argv[0];

    if(argc==1) goto usage;

    /* parse flags */
    while(*(argv[1]) == '-')
    {
      int l = strlen(argv[1]);
      if(strncmp(argv[1],"-kind",l)==0) 
      {
	argc--; argv++;
	kind = DBLabelKindParse(argv[1]);
	if(kind<0) goto usage;
	argc--; argv++;
      }
      else
      {
	goto usage;
      }
    }

    if (argc < 2 || argc > 4) goto usage;

    p = argv[1];

    /*
     * Find and check validity of type parameter
     */

    if (argc > 3)
    {
	type = DBTechNameType(argv[3]);
	if (type < 0)
	{
	    MsgErrorF("Unknown layer: %s\n", argv[3]);
	    return;
	}
    } else type = -1;

    /*
     * Find and check validity of position.
     */

    if (argc > 2)
    {
	pos = GeoNameToPos(argv[2], FALSE, TRUE);
	if (pos < 0)
	    return;
        pos = GeoTransPos(&RootToEditTransform, pos);
    }
    else pos = -1;
    
    cmdLabelProc(p, pos, type, kind);

    return;

usage:
    MsgErrorF("Usage: %s [-kind kind] text [direction [layer]]\n", cmdName);
    return;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdLoad --
 *
 * Implement the "load" command.
 *
 * Usage:
 *	load [name]
 *
 * If name is supplied, then the window containing the point tool is
 * remapped so as to edit the cell with the given name.
 *
 * If no name is supplied, then a new cell with the name "(UNNAMED)"
 * is created in the selected window.  If there is already a cell by
 * that name in existence (eg, in another window), that cell gets loaded
 * rather than a new cell being created.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets EditCellUse.
 *
 * ----------------------------------------------------------------------------
 */

Void
CmdLoad(Layout *w, TxCommand *cmd)
{
    if (w == (Layout *) NULL)
    {
	MsgErrorF("Point to a window first.\n");
	return;
    }

    if (cmd->tx_argc > 2)
    {
	MsgErrorF("Usage: %s [name]\n", cmd->tx_argv[0]);
	return;
    }

    if (cmd->tx_argc == 2)
    {
        if(!DBCellNameCheck(cmd->tx_argv[1])) return;
	LayloadWindow(w, cmd->tx_argv[1]);
    }
    else 
    {
        LayloadWindow(w, (char *) NULL);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdMove --
 *
 * Implement the "move" command.
 *
 * Usage:
 *	move [direction [amount]]
 *	move to x y
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Moves everything that's currently selected.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

Void
CmdMove(Layout *w, TxCommand *cmd)
{
    Transform t;
    Rect rootBox, newBox;
    Point rootPoint, editPoint;
    CellDef *rootDef;

    if (cmd->tx_argc > 4)
    {
	badUsage:
	MsgErrorF("Usage: %s [direction [amount]]\n", cmd->tx_argv[0]);
	MsgErrorF("   or: %s to x y\n", cmd->tx_argv[0]);
	return;
    }

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    if (cmd->tx_argc > 1)
    {
	int indx, amount;
	int xdelta, ydelta;

	if (strcmp(cmd->tx_argv[1], "to") == 0)
	{
	    if (cmd->tx_argc != 4)
		goto badUsage;
	    if (!UnitsValidS(cmd->tx_argv[2]) || !UnitsValidS(cmd->tx_argv[3]))
		goto badUsage;
	    editPoint.p_x = UnitsS2I(cmd->tx_argv[2]);
	    editPoint.p_y = UnitsS2I(cmd->tx_argv[3]);
	    GeoTransPoint(&EditToRootTransform, &editPoint, &rootPoint);
	    goto moveToPoint;
	}

	indx = GeoNameToPos(cmd->tx_argv[1], TRUE, TRUE);
	if (indx < 0)
	    return;
	if (cmd->tx_argc == 3)
	{
	    if (!UnitsValidS(cmd->tx_argv[2])) goto badUsage;
	    amount = UnitsS2I(cmd->tx_argv[2]);
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
		ASSERT(FALSE, "Bad direction in CmdMove");
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
	 * the point as the transform.
	 */
	
	Layout *window;

	window = LayPointGet(&rootPoint, (Rect *) NULL);
	if ((window == NULL) ||
	    (EditRootDef != window->lay_rootUse->cu_def))
	{
	    MsgErrorF("\"Move\" uses the point as the place to put down a\n");
	    MsgErrorF("    the selection, but the point doesn't point to the\n");
	    MsgErrorF("    edit cell.\n");
	    return;
	}

moveToPoint:
	if (!ToolGetBox(&rootDef, &rootBox) || (rootDef != SelectRootDef))
	{
	    MsgErrorF("\"Move\" uses the box lower-left corner as a place\n");
	    MsgErrorF("    to pick up the selection for moving, but the box\n");
	    MsgErrorF("    isn't in a window containing the selection.\n");
	    return;
	}
	GeoTransTranslate(rootPoint.p_x - rootBox.r_xbot,
	    rootPoint.p_y - rootBox.r_ybot, &GeoIdentityTransform, &t);
	GeoTransRect(&t, &rootBox, &newBox);
	LaySetBox(rootDef, &newBox);
    }
    
    SelectTransform(&t,FALSE /* disallow dup instances */);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cmdPaintButton --
 *
 * Old "middle button" Magic command
 * Called by CmdPaint to handle "-button" option (paint layers under point).
 *
 * "mgc_paint -button" is similar to "mgc_paint $",
 *  but differs when Point is over space.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modified EditCellUse->cu_def (paint layers under point into box)
 *
 * ----------------------------------------------------------------------------
 */

static void
cmdPaintButton(Layout *w)
                 
                    	/* Screen location at which button was raised */
{
    Point rootPoint;
    Rect editRect;
    TileTypeBitMask mask;
    TileTypeBitMask yMAllButSpace;
    Layout *crec;

    /* create mask for all but space and subcell pseudo layer */
    yMAllButSpace = DBAllButSpaceBits;
    TTMaskClearType(&yMAllButSpace, L_CELL);

    crec = w;

    if(LayPointGet(&rootPoint, NULL)!=w)
    {
        MsgErrorF("Point not in current Layout window.\n");
	return;
    }

    mask = DBSrTouchingTypes(w->lay_rootUse, 
			     w->lay_bitmask,
			     &rootPoint, 
			     0 /* flags */);


    TTMaskAndMask(&mask, &DBAllButSpaceAndDRCBits);
    TTMaskAndMask(&mask, &crec->lay_visibleLayers);

    if (!ToolGetEditBox(&editRect)) return;

    if (TTMaskEqual(&mask, &DBZeroTypeBits))
    {
	TTMaskAndMask3(&mask, &yMAllButSpace, &crec->lay_visibleLayers);

	/* A little extra bit of cleverness:  if the box is zero size
	 * then delete all labels (this must be what the user intended
	 * since a zero size box won't delete any paint).  Otherwise,
	 * only delete labels whose paint has completely vanished.
	 */

	if (GEO_RECTNULL(&editRect))
	    TTMaskSetType(&mask, L_LABEL);

        if(!DBAccessModifyMask(EditCellUse->cu_def,
			       &crec->lay_visibleLayers) || 
	   !DBAccessModifyMask(EditCellUse->cu_def,
			       &mask))
	{
	  return;
	}

	DBEraseMask(EditCellUse->cu_def, &editRect, &crec->lay_visibleLayers);
	(void) DBLabelsEraseArea(EditCellUse->cu_def, &editRect, &mask);
    }
    else
    {
        if(!DBAccessModifyMask(EditCellUse->cu_def,&mask)) return;
	DBPaintMask(EditCellUse->cu_def, &editRect, &mask);
    }
    SelectClear();

    /* process database changes */
    DBChangedArea(EditCellUse->cu_def, &editRect, &mask, 0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdPaint --
 *
 * Implement the "paint" command.
 * Paint the specified layers underneath the box in EditCellUse->cu_def.
 *
 * Usage:
 *	paint [layers]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modified EditCellUse->cu_def.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

Void
CmdPaint(Layout *w, TxCommand *cmd)
{
    Rect editRect;
    TileTypeBitMask mask;

    if (!w)
    {
	MsgErrorF("Put the cursor in a layout window\n");
	return;
    }

    if (cmd->tx_argc != 2)
    {
	MsgErrorF("Usage: %s layers\n\tor %s -button\n", cmd->tx_argv[0], cmd->tx_argv[0]);
	return;
    }

    /* if arg is -button, call cmdPaintButton (old middle button), to
     * paint layers under point into box.
     */
    if (strcmp(cmd->tx_argv[1],"-button")==0) 
    {
        cmdPaintButton(w);
	return;
    }

    if (!ToolGetEditBox(&editRect)) return;

    if (!CmdParseLayers(cmd->tx_argv[1], &mask))
	return;

    if (TTMaskHasType(&mask, L_LABEL))
    {
       fprintf(stderr,"DEBUG L_LABEL=%#o TT_MAXTYPES=%#o\n",
	       L_LABEL,TT_MAXTYPES);
       DumpTypes("mask =",&mask);
	MsgErrorF("Label layer cannot be painted.  Use the \"label\" command\n");
	return;
    }
    if (TTMaskHasType(&mask, L_CELL))
    {
	MsgErrorF("Subcell layer cannot be painted.  Use \"getcell\".\n");
	return;
    }

    TTMaskClearType(&mask, TT_SPACE);

    /* check for read-only */
    if(!DBAccessModifyMask(EditCellUse->cu_def,&mask)) return;

    DBPaintMask(EditCellUse->cu_def, &editRect, &mask);
    SelectClear();

    /* process database changes */
    DBChangedArea(EditCellUse->cu_def, &editRect, &mask, 0);
}
