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



/* windCmdAM.c -
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
static char rcsid[]="$Header: windCmdAM.c,v 6.0 90/08/28 19:02:12 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/times.h>
#include <sys/stat.h>
#include <errno.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "layout.h"
#include "memory.h"
#include "signals.h"
#include "mgcint.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "utils.h"


/*
 * ----------------------------------------------------------------------------
 *
 * windCenterCmd --
 *
 * Implement the "center" command.
 * Move a window's view to center the point underneath the cursor.
 *
 * Usage:
 *	center 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The view in the window underneath the cursor is changed
 *	to center the point underneath the cursor.  
 *
 * ----------------------------------------------------------------------------
 */

void windCenterCmd(Layout *w, TxCommand *cmd)
{
    Point rootPoint;
    Rect newArea, oldArea;

    if (cmd->tx_argc != 1)
    {
	MsgErrorF("Usage: center\n");
	return;
    }

    if(!LayPointGet(&rootPoint, (Rect *) NULL))
    {
        MsgErrorF("Point to a window first.\n");
    }

    oldArea = w->lay_dbArea;
    newArea.r_xbot = rootPoint.p_x - (oldArea.r_xtop - oldArea.r_xbot)/2;
    newArea.r_xtop = newArea.r_xbot - oldArea.r_xbot + oldArea.r_xtop;
    newArea.r_ybot = rootPoint.p_y - (oldArea.r_ytop - oldArea.r_ybot)/2;
    newArea.r_ytop = newArea.r_ybot - oldArea.r_ybot + oldArea.r_ytop;

    LayFrame(w, &newArea);
}


/*
 * ----------------------------------------------------------------------------
 * windCrashCmd --
 *
 *	Generate a core dump.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Dumps core by calling MaxAbort().
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
void windCrashCmd(Layout *w, TxCommand *cmd)
{
    if (cmd->tx_argc != 1)
    {
	MsgErrorF("Usage:  *crash\n");
	return;
    }

    MaxAbort("windCrashCmd invoked");
}
