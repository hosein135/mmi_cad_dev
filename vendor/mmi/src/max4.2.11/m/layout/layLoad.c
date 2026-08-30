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
 * layLoad.c --
 *
 *	Procedure for loading a (root) cell into a layout window.
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
static char rcsid[] = "$Header: Layprocs.c,v 6.0 90/08/28 18:11:27 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "layout.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "main.h"
#include "commands.h"
#include "layout.h"
#include "message.h"
#include "utils.h"
#include "undo.h"
#include "malloc.h"
#include "styles.h"
#include "layout.h"
#include "layint.h"


/*
 * ----------------------------------------------------------------------------
 *
 * LayloadWindow --
 *
 *	Replace the root cell of a window by the specified cell.
 *
 *	A cell name of NULL causes the cell with name "(UNNAMED)" to be
 *	created if it does not already exist, or used if it does.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Makes new cell the edit cell.
 *	Clears the selection.  (to make sure no refs to old rootUse)
 *
 * ----------------------------------------------------------------------------
 */
void
LayloadWindow(Layout *window, 
	                /* Identifies window to which cell is to be bound */
	      char *name)
               		/* Name of new cell to be bound to this window */
{
    CellDef *newRootDef;
    CellUse *oldRootUse;

    /* Get Root Def */
    if (name == (char *) NULL)
    {
	/*
	 * If there is an existing unnamed cell, we use it.
	 * Otherwise, we create one afresh.
	 */
	newRootDef = DBCellLookDef(UNNAMED);
	if (newRootDef == (CellDef *) NULL)
	{
	    newRootDef = DBCellNewDef(UNNAMED, (char *) NULL);
	    DBCellSetAvail(newRootDef);
	}
    }
    else
    {
	/*
	 * Name specified.
	 * First try to find it in main memory, then try to
	 * read it from disk.
	 */
	newRootDef = DBCellLookDef(name);

	if (newRootDef == (CellDef *) NULL)
	{
	    newRootDef = DBCellNewDef(name, (char *) NULL);
	}

	if (!DBCellRead(newRootDef, (char *) NULL, TRUE))
	{
	    /* TODO optionally delete new cell and fail here! */
	    MsgInfoF("Creating new cell\n");
	    DBCellSetAvail(newRootDef);
	}
    }

    /* Create new Root Use */
    oldRootUse = window->lay_rootUse;
    window->lay_rootUse = DBCellNewUse(newRootDef, "Topmost cell in the window");

    DBExpand(window->lay_rootUse,window->lay_bitmask, TRUE);

    /* Setup mapping from DB to window */
    {
        int xadd, yadd;
	Rect frame = *DBBBoxCellDef(newRootDef);

        /* enforce a minimum size of 60 and a border of 10% around the sides */
        xadd = MAX(0, (60 - (frame.r_xtop - frame.r_xbot)) / 2) + 
	  (frame.r_xtop - frame.r_xbot + 1) / 10;

	yadd = MAX(0, (60 - (frame.r_ytop - frame.r_ybot)) / 2) +
	  (frame.r_ytop - frame.r_ybot + 1) / 10;

	frame.r_xbot -= xadd;  frame.r_xtop += xadd;
	frame.r_ybot -= yadd;  frame.r_ytop += yadd;

	/* do the mapping */
	LayFrame(window, &frame); 
    }

    /* Make Edit Cell */
    {
        /* record for undo */
        /* LayUndoLoad ALWAYS makes new root def edit cell, so
	 * need to remember old edit cell and load for undo
	 * but, LayUndoEditNew() would be redundant here
	 */ 
        if (EditCellUse && EditRootDef)
        {

            LayUndoOldEdit(EditCellUse, EditRootDef,
		     &EditToRootTransform, &RootToEditTransform);
	}
	/* Can't undo initial cell in window */
	if(oldRootUse)
	{
	    LayUndoLoad(window, oldRootUse->cu_def, newRootDef);
	}

	/* set edit cell */
	EditCellUse = window->lay_rootUse;
	EditRootDef = newRootDef;
	EditToRootTransform = GeoIdentityTransform;
	RootToEditTransform = GeoIdentityTransform;

	/* redisplay new and old edit cells (in case visible in other windows)
	 * (since non-edit cells dimmed) 
	 */
	DBChangedArea(newRootDef, 
		      NULL, 
		      &DBAllButSpaceBits,
		      DBCF_DISPLAY);
	if(oldRootUse)
	{
	  DBChangedArea(oldRootUse->cu_def, 
			NULL, 
			&DBAllButSpaceBits,
			DBCF_DISPLAY);
	}
    }

    /* Delete old Root Use 
     * (Can't do this before LayUndoOldEdit() above!)
     */
    if(oldRootUse) DBCellDeleteUse(oldRootUse);
}




