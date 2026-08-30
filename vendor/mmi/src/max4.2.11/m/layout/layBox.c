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
 * layBox.c --
 *
 * Routines to get/set box.
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

#include <stdio.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>

#include "magic.h"
#include "main.h"
#include "layout.h"
#include "layint.h"
#include "geometry.h"
#include "graphics.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "message.h"
#include "select.h" 
#include "units.h"
#include "utils.h"

static char rcsid[] = "$Header$";

/* The Box */
static CellDef *boxRootDef = NULL;	/* CellDef for the box */
static Rect boxRootArea;		/* Root def coords */


/*
 * ----------------------------------------------------------------------------
 * ToolGetBox --
 *
 *	Returns the box CellDef and location in CellDef coords.
 *
 * Results:
 *	TRUE if the box exists.
 *
 * Side effects:
 *	The rootArea parameter is modified to contain the area
 *	of the box.  If rootArea is NULL, it is ignored.
 *	Same with rootDef.
 * ----------------------------------------------------------------------------
 */

bool
ToolGetBox(CellDef **rootDef, 
                      		/* Filled in with the root def of the box */
Rect *rootArea)
                   		/* Filled in with area of box.  Will be
				 * unchanged when NULL is returned.
				 */
{
  if (rootDef != NULL) *rootDef = boxRootDef;
  if (rootArea != NULL) *rootArea = boxRootArea;
  return (boxRootDef != NULL);
}


/*
 * ----------------------------------------------------------------------------
 * ToolGetBoxWindow --
 *
 * 	Returns information about the current box location.  Used by
 *	command processing routines.
 *
 * Results:
 *	The return value is a pointer to a window containing the
 *	box, or NULL if the box doesn't exist in any window.  Note:
 *	the box may actually be in more than one window, so this
 *	isn't necessarily the only window containing the box.
 *
 * Side effects:
 *	The rootArea parameter is modified to contain the area
 *	of the box.  If rootArea is NULL, it is ignored.  The
 *	integer pointed to by pMask is modified to contain a
 *	mask of all windows containing the box (there may be more
 *	than one).  If pMask is NULL, it is ignored.
 * ----------------------------------------------------------------------------
 */

static int toolMask;		/* Shared between these two routines. */

Layout *
ToolGetBoxWindow(Rect *rootArea, int *pMask)
                   		/* Filled in with area of box.  Will be
				 * unchanged when NULL is returned.
				 */
               			/* Filled in with mask of all windows
				 * containing box.
				 */
{
    Layout *window;
    extern int toolWindowSave(Layout *window, ClientData clientData);

    /* Search through the windows and remember a window that has
     * the right root cell.  It's important to NOT search on the
     * area of the box (i.e. take any window with the box's root
     * definition, even if the box isn't visible in the window).
     * Otherwise, some commands won't work when the box goes
     * off-screen.  Also accumulate the mask bits.
     */

    toolMask = 0;
    window = NULL;
    if (boxRootDef != NULL)
	(void) WindSearch((ClientData) NULL, (Rect *) NULL, 
	    toolWindowSave, (ClientData) &window);
    if ((window != NULL) && (rootArea != NULL)) *rootArea = boxRootArea;
    if (pMask != NULL) *pMask = toolMask;
    return window;
}

int
toolWindowSave(Layout *window, ClientData clientData)
                      		/* Window that matched in some search. */
                          	/* Contains the address of a location
				 * to be filled in with the window address.
				 */
{
    if (WINDOW_DEF(window) == boxRootDef)
    {
	*((Layout **) clientData) = window;
        toolMask |= window->lay_bitmask;
    }
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * ToolGetEditBox --
 *
 *	Fill in the location of the box in edit cell coordinates.
 *
 * Results:
 *	TRUE if the box can indeed be put into edit cell coordinates.
 *	FALSE and an error message otherwise.
 *
 * Side effects:
 *	Sets *rect to be the coordinates of the box tool in edit cell
 *	coordinates, if TRUE was returned.
 *
 *	Prints an error message if the box is not found or the box
 *	is not in the edit cell coordinate system.
 *
 * ----------------------------------------------------------------------------
 */

bool
ToolGetEditBox(Rect *rect)
{
    if (boxRootDef == NULL) 
    {
	MsgErrorF("Box must be present\n");
	return FALSE;
    }
    if (EditRootDef != boxRootDef) 
    {
	MsgErrorF("The box isn't in a window on the edit cell.\n");
	return FALSE;
    }
    if (rect != NULL)
	GeoTransRect(&RootToEditTransform, &boxRootArea, rect);
    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * LaySetBox --
 *
 * 	Change the location and/or size of the box.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Information is recorded so that the box will be redrawn.
 * ----------------------------------------------------------------------------
 */

void
LaySetBox(CellDef *rootDef, Rect *rect)
                     		/* Root definition in whose coordinate system
				 * the box is defined.  It will appear in all
				 * windows with this as root cell.
				 */
               			/* New box location in coords of rootDef. */
{
    /* Record the old and area of the box for redisplay. */

    /* inform redisplay code of need to erase old box */
    layChangedHLBox(boxRootDef, TRUE /* erase */);

    /* Save information for undo-ing. */
    LayUndoBox(boxRootDef, &boxRootArea, rootDef, rect);

    /* Update the box location. */
    boxRootDef = rootDef;
    boxRootArea = *rect;

    /* inform redisplay code of need to display new box */
    layChangedHLBox(boxRootDef, FALSE /* don't erase */);
}









