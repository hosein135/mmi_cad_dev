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



/* windCmdSZ.c -
 *
 *	This file contains Magic command routines for those commands
 *	that are valid in all windows.
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
static char rcsid[]="$Header: windCmdSZ.c,v 6.0 90/08/28 19:02:15 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "tile.h"
#include "layout.h"
#include "utils.h"
#include "signals.h"
#include "mgcint.h"
#include "hash.h"
#include "database.h"
#include "main.h"
#include "units.h"
#include "undo.h"


/*
 * ----------------------------------------------------------------------------
 *
 * windScrollCmd --
 *
 *	Scroll the view around
 *
 * Usage:
 *	scroll [dir [amount]]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window underneath the cursor is changed.
 *
 * ----------------------------------------------------------------------------
 */

void
windScrollCmd(Layout *w, TxCommand *cmd)
{
    Rect frame;
    int xsize, ysize;
    int pos;
    float amount;
    Point delta; 

    if ( (cmd->tx_argc < 1) || (cmd->tx_argc > 3) )
    {
	MsgErrorF("Usage: %s [direction [amount]]\n", cmd->tx_argv[0]);
	return;
    }

    if (w == NULL)
    {
	MsgErrorF("Point to a window first.\n");
	return;
    }

    pos = GeoNameToPos(cmd->tx_argv[1], FALSE, TRUE);
    if (pos < 0 || pos == GEO_CENTER)
	return;

    if (cmd->tx_argc == 3)
    {
	if (sscanf(cmd->tx_argv[2], "%f", &amount) != 1)
	{
	    MsgErrorF("Usage: %s [direction [amount]]\n", cmd->tx_argv[0]);
	    return;
	}
    }
    else
    {
      amount = 0.5;
    }

    /* get current frame and compute offsets */
    layRectWToDB(w, &w->lay_area, &frame);
    xsize = (frame.r_xtop - frame.r_xbot) * amount;
    ysize = (frame.r_ytop - frame.r_ybot) * amount;
    if(xsize<=0) xsize = 1;
    if(ysize<=0) ysize = 1;

    delta.p_x = 0;
    delta.p_y = 0;
    switch (pos)
    {
	case GEO_NORTH:
	    delta.p_y = -ysize;
	    break;
	case GEO_SOUTH:
	    delta.p_y = ysize;
	    break;
	case GEO_EAST:
	    delta.p_x = -xsize;
	    break;
	case GEO_WEST:
	    delta.p_x = xsize;
	    break;
	case GEO_NORTHEAST:
	    delta.p_x = -xsize;
	    delta.p_y = -ysize;
	    break;
	case GEO_NORTHWEST:
	    delta.p_x = xsize;
	    delta.p_y = -ysize;
	    break;
	case GEO_SOUTHEAST:
	    delta.p_x = -xsize;
	    delta.p_y = ysize;
	    break;
	case GEO_SOUTHWEST:
	    delta.p_x = xsize;
	    delta.p_y = ysize;
	    break;
    }

    /* apply delta to frame */
    frame.r_xbot += delta.p_x;
    frame.r_ybot += delta.p_y;
    frame.r_xtop += delta.p_x;
    frame.r_ytop += delta.p_y;
 
    /* reframe */
    LayFrame(w, &frame);
    return;
}

int
windSetPrintProc(char *name, char *val)
{
    MsgInfoF("%s = \"%s\"\n", name, val);
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * windUndoCmd
 *
 * Implement the "undo" command.
 *
 * Usage:
 *	undo [count]
 *
 * If a count is supplied, the last count events are undone.  The default
 * count if none is given is 1.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Calls the undo module.
 *
 * ----------------------------------------------------------------------------
 */
 /*ARGSUSED*/

void windUndoCmd(Layout *w, TxCommand *cmd)
{
    int count;

    if (cmd->tx_argc > 2)
    {
	MsgErrorF("Usage: undo [count]\n");
	return;
    }

    if (cmd->tx_argc == 2)
    {
	if (!StrIsInt(cmd->tx_argv[1]))
	{
	    MsgErrorF("Count must be numeric\n");
	    return;
	}
	count = atoi(cmd->tx_argv[1]);
    }
    else
	count = 1;

    if (UndoBackward(count) == 0)
	MsgInfoF("Nothing more to undo\n");
}


/*
 * ----------------------------------------------------------------------------
 *
 * windViewCmd --
 *
 * Implement the "View" command.
 * Change the view in the selected window so everything is visible.
 *
 * Usage:
 *	view
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window underneath the cursor is changed.
 *
 * ----------------------------------------------------------------------------
 */
 /*ARGSUSED*/

/* Amount of border to add (in fraction of a screen full) */
#define SLOP	10

void windViewCmd(Layout *w, TxCommand *cmd)
{
  Rect view;
  Rect *bbox; 

  if (w == NULL) return;

  bbox = &w->lay_rootUse->cu_def->cd_bbox;
  view = *bbox;
  view.r_xbot -= (bbox->r_xtop - bbox->r_xbot + 1) / SLOP;
  view.r_xtop += (bbox->r_xtop - bbox->r_xbot + 1) / SLOP;
  view.r_ybot -= (bbox->r_ytop - bbox->r_ybot + 1) / SLOP;
  view.r_ytop += (bbox->r_ytop - bbox->r_ybot + 1) / SLOP;

  LayFrame(w, &view);
}


/*
 * ----------------------------------------------------------------------------
 *
 * windZoomCmd --
 *
 * Implement the "zoom" command.
 * Change the view in the selected window by the given scale factor.
 *
 * Usage:
 *	zoom amount
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window underneath the cursor is changed.
 *
 * ----------------------------------------------------------------------------
 */

void windZoomCmd(Layout *w, TxCommand *cmd)
{
    float factor;
    int centerx, centery;
    Rect newArea;

    if (w == NULL)
	return;

    if (cmd->tx_argc != 2)
    {
	MsgErrorF("Usage: %s factor\n", cmd->tx_argv[0]);
	return;
    }

    factor = atof(cmd->tx_argv[1]);
    if ((factor <= 0) || (factor >= 20))
    {
	MsgErrorF("zoom factor must be between 0 and 20.\n");
	return;
    }

    /* compute new view area */
    centerx = (w->lay_dbArea.r_xbot + w->lay_dbArea.r_xtop) / 2;
    centery = (w->lay_dbArea.r_ybot + w->lay_dbArea.r_ytop) / 2;
    newArea.r_xbot = centerx - (centerx - w->lay_dbArea.r_xbot) * factor;
    newArea.r_xtop = centerx + (w->lay_dbArea.r_xtop - centerx) * factor;
    newArea.r_ybot = centery - (centery - w->lay_dbArea.r_ybot) * factor;
    newArea.r_ytop = centery + (w->lay_dbArea.r_ytop - centery) * factor;

    /* frame it */
    LayFrame(w, &newArea);
}


