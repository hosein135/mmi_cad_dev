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
 * MgcTZ.c --
 *
 * Commands with names beginning with the letters T through Z.
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
static char rcsid[] = "$Header: CmdTZ.c,v 6.0 90/08/28 18:07:26 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
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
#include "mgcint.h"
#include "signals.h"
#include "undo.h"
#include "select.h"
#include "styles.h"
#include "units.h"


/*
 * ----------------------------------------------------------------------------
 *
 * CmdUnexpand --
 *
 * Implement the "unexpand" command.
 *
 * Usage:
 *	unexpand
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Unexpands all cells under the box that don't completely
 *	contain the box.
 *
 * ----------------------------------------------------------------------------
 */

/* call back to propagate use expandMask change to selection */
static int
cmdUnexpandEnumFunc(CellUse *selUse, 
                    		/* Use from selection (not used). */
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
 * then returns 0 to keep looking for more cells to unexpand.
 */

static int
cmdUnexpandFunc(CellUse *use, int windowMask)
                 		/* Use that was just unexpanded. */
                   		/* Window where it was unexpanded. */
{
    if (DBCellUseParent(use) == NULL) return 0;
    /* use possibly out-of-date cu_bbox.
     * (if bboxes changes with future update, layout module will be notified then)
     */
    DBChangedArea(DBCellUseParent(use), 
		  &use->cu_bbox,
		  (TileTypeBitMask *) NULL,
		  DBCF_DISPLAY_ONLY);

    /* continue search */
    return 0;
}

void CmdUnexpand(Layout *w, TxCommand *cmd)
{
    int windowMask, boxMask;
    Rect rootRect;

    if (cmd->tx_argc != 1)
    {
	MsgErrorF("Usage: %s\n", cmd->tx_argv[0]);
	return;
    }
    
    if (w == (Layout *) NULL)
    {
	MsgErrorF("Point to a window first.\n");
	return;
    }
    windowMask = w->lay_bitmask;

    (void) ToolGetBoxWindow(&rootRect, &boxMask);
    if ((boxMask & windowMask) != windowMask)
    {
	MsgErrorF("The box isn't in the same window as the cursor.\n");
	return;
    }

    DBExpandAll(w->lay_rootUse, &rootRect, windowMask,
	    FALSE, cmdUnexpandFunc, (ClientData) windowMask);


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
			cmdUnexpandEnumFunc, 
			(ClientData) NULL);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdUpsidedown --
 *
 * Implement the "upsidedown" command.
 *
 * Usage:
 *	upsidedown
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The box and verything in the selection are flipped upside down
 *	using the point as the axis around which to flip.
 *
 * ----------------------------------------------------------------------------
 */
    
    /* ARGSUSED */

void CmdUpsidedown(Layout *w, TxCommand *cmd)
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
    
    /* To flip the selection upside down, first flip it around the
     * x-axis, then move it back so its lower-left corner is in
     * the same place that it used to be.
     */
    {
      Rect *selBBox = DBBBoxCellDef(SelectDef);

      GeoTransRect(&GeoUpsideDownTransform, selBBox, &bbox);
      GeoTranslateTrans(&GeoUpsideDownTransform,
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
