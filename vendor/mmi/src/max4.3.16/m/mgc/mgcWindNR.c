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



/* windCmdNR.c -
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
static char rcsid[]="$Header: windCmdNR.c,v 6.0 90/08/28 19:02:13 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/times.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "layout.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "main.h"
#include "utils.h"
#include "mgcint.h"
#include "undo.h"
#include "main.h"



char *onoffTable[] =
{
    "off",
    "on",
    0
};

/*
 * ----------------------------------------------------------------------------
 *
 * windProfileCmd --
 *
 * Turn system profiling on/off.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
 /*ARGSUSED*/

void windProfileCmd(Layout *w, TxCommand *cmd)
{
    int onoff;

    if (cmd->tx_argc != 2) goto usage;
    onoff = Lookup(cmd->tx_argv[1], onoffTable);
    if (onoff < 0) goto usage;
    moncontrol(onoff);
    MsgInfoF("Profiling turned %s\n", onoffTable[onoff]);
    return;

usage:
    MsgErrorF("Usage: *profile on|off\n");
}


/*
 * ----------------------------------------------------------------------------
 *
 * windRedoCmd
 *
 * Implement the "redo" command.
 *
 * Usage:
 *	redo [count]
 *
 * If a count is supplied, the last count events are redone.  The default
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

void windRedoCmd(Layout *w, TxCommand *cmd)
{
    int count;

    if (cmd->tx_argc > 2)
    {
	MsgErrorF("Usage: redo [count]\n");
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

    if (UndoForward(count) == 0)
	MsgInfoF("Nothing more to redo\n");
}











