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
 * debug.c --
 *
 * Debugging module.
 * The debugging module provides a standard collection of
 * procedures for setting, examining, and testing debugging flags.
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
static char rcsid[] = "$Header: debugFlags.c,v 6.0 90/08/28 18:11:51 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "debug.h"
#include "database.h"
#include "message.h"
#include "malloc.h"
#include "utils.h"
#include "units.h"

struct debugClient debugClients[MAXDEBUGCLIENTS];
int debugNumClients = 0;

/* linked to tcl var DEBUG_0 DEBUG_1 etc., available for any purpose during debugging. */
int Debug0=0;
int Debug1=0;
int Debug2=0;
int Debug3=0;


/*
 * ----------------------------------------------------------------------------
 *
 * DebugAddClient --
 *
 * Add a client to the debugging module.
 * The argument 'name' is used to identify the client, and the
 * argument 'maxflags' indicates the maximum number of flags
 * that will be added for that client.
 *
 * Results:
 *	Returns a word of ClientData that identifies the
 *	client just added.  This word must be passed to
 *	DebugAddFlag, DebugSet(), or DebugShow() to identify
 *	the client being referred to.
 *
 * Side effects:
 *	Updates the list of known debugging clients.
 *
 * ----------------------------------------------------------------------------
 */

ClientData
DebugAddClient(char *name, register int maxflags)
{
    register struct debugClient *dc;

    if (debugNumClients >= MAXDEBUGCLIENTS)
    {
	MsgErrorF("No room for debugging client '%s'.\n", name);
	MsgErrorF("Maximum number of clients is %d\n", MAXDEBUGCLIENTS);
	return ((ClientData) (MAXDEBUGCLIENTS-1));
    }

    dc = &debugClients[debugNumClients];
    dc->dc_name = name;
    dc->dc_maxflags = maxflags;
    dc->dc_nflags = 0;
    MALLOC(struct debugFlag *, dc->dc_flags,
		sizeof (struct debugFlag) * maxflags);

    while (--maxflags > 0)
    {
	dc->dc_flags[maxflags].df_name = (char *) NULL;
	dc->dc_flags[maxflags].df_value = FALSE;
    }

    return ((ClientData) debugNumClients++);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DebugAddFlag --
 *
 * Add a debugging flag for a particular client.
 * This flag can be set when DebugSet() is called with 'clientID',
 * and will appear in the display of DebugShow().
 *
 * WARNING:
 *	The order in which flags appear for purposes of setting them
 *	with DebugSet(), and when being displayed with DebugShow(),
 *	will be the same as the order in which they are passed to
 *	DebugAddFlag().  To make LookupStruct() work best for DebugSet(),
 *	the flag names should be ordered monotonically.
 *
 * Results:
 *	Returns the index of the debugging flag in the array
 *	debugFlags[].
 *
 * Side effects:
 *	Updates the array debugFlags[].
 *
 * ----------------------------------------------------------------------------
 */

int
DebugAddFlag(ClientData clientID, char *name)
                        	/* Client identifier from DebugAddClient */
               			/* Name of debugging flag */
{
    int id = (int) clientID;
    register struct debugClient *dc;

    if (id < 0 || id >= debugNumClients)
    {
	MsgErrorF("DebugAddFlag: bad client id %d (flag %s)\n", clientID, name);
	return (0);
    }

    dc = &debugClients[id];
    if (dc->dc_nflags >= dc->dc_maxflags)
    {
	MsgErrorF("Too many flags for client %s (maximum was set to %d)\n",
		dc->dc_name, dc->dc_maxflags);
	return (dc->dc_nflags);
    }

    dc->dc_flags[dc->dc_nflags].df_name = name;
    dc->dc_flags[dc->dc_nflags].df_value = FALSE;
    return (dc->dc_nflags++);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DebugShow --
 *
 * Show all the debugging flags and their values for a particular
 * client.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to the terminal.
 *
 * ----------------------------------------------------------------------------
 */

void 
DebugShow(ClientData clientID)
{
    int id = (int) clientID;
    register struct debugClient *dc;
    register int n;

    if (id < 0 || id >= debugNumClients)
    {
	MsgErrorF("DebugShow: bad client id %d\n", clientID);
	return;
    }
    dc = &debugClients[id];
    for (n = 0; n < dc->dc_nflags; n++)
	MsgInfoF("%-5.5s %s\n", dc->dc_flags[n].df_value ? "TRUE" : "FALSE",
		dc->dc_flags[n].df_name);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DebugSet --
 *
 * Allow debugging flags to be set or cleared for the client 'clientID'.
 * The argument 'argv' contains an array of 'argc' string pointers,
 * each of which is the name of a flag that will be set to 'value'
 * (either TRUE or FALSE).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the debugging flags specified in (argc, argv).
 *	Will complain about any unrecognized flag names.
 *
 * ----------------------------------------------------------------------------
 */

void 
DebugSet(ClientData clientID, int argc, char **argv, int value)
{
    bool badFlag = FALSE;
    int id = (int) clientID;
    register struct debugClient *dc;
    register int n;

    if (id < 0 || id >= debugNumClients)
    {
	MsgErrorF("DebugSet: bad client id %d\n", clientID);
	return;
    }
    dc = &debugClients[id];
    for (; argc-- > 0; argv++)
    {
	n = LookupStruct(*argv, (LookupTable *) dc->dc_flags,
			sizeof dc->dc_flags[0]);
	if (n < 0)
	{
	    MsgErrorF("Unrecognized flag '%s' for client '%s' (ignored)\n",
		*argv, dc->dc_name);
	    badFlag = TRUE;
	    continue;
	}
	dc->dc_flags[n].df_value = value;
    }
    /* if badFlag passed, give list of valid flags */
    if(badFlag)
    {
	int n;
	MsgErrorF("Valid flags are:  ");
	for (n = 0; n < dc->dc_nflags; n++)
	    MsgErrorF("%s ", dc->dc_flags[n].df_name);
	MsgErrorF("\n");
    }
}

/*
 * ----------------------------------------------------------------------------
 * DumpRect --
 * 
 * print Rect
 *
 * ----------------------------------------------------------------------------
 */		 
void
DumpRect(char *msg, Rect *r)
{
  fprintf(stderr,"%s ", msg? msg : "DumpRect:"); 

  if(r)
  {
    fprintf(stderr,"%d %d %d %d\n",
	    r->r_xbot,
	    r->r_ybot,
	    r->r_xtop,
	    r->r_ytop);
  }
  else
  {
    fprintf(stderr,"NULL\n");
  }
}

/*
 * ----------------------------------------------------------------------------
 * DumpRectU --
 * 
 * print Rect (converting to user units)
 *
 * ----------------------------------------------------------------------------
 */		 
void 
DumpRectU(char *msg, Rect *r)
{
  fprintf(stderr,"%s ", msg? msg : "DumpRectU:"); 

  if(r)
  {
    fprintf(stderr,"%s ",
	    UnitsI2S(r->r_xbot));
    fprintf(stderr,"%s ",
	    UnitsI2S(r->r_ybot));
    fprintf(stderr,"%s ",
	    UnitsI2S(r->r_xtop));
    fprintf(stderr,"%s",
	    UnitsI2S((int) r->r_ytop));
  }
  else
  {
    fprintf(stderr,"NULL\n");
  }
}

/*
 * ----------------------------------------------------------------------------
 * DumpRectF --
 * 
 * print RectFloat 
 *
 * ----------------------------------------------------------------------------
 */		 
void 
DumpRectF(char *msg, RectFloat *r)
{
  fprintf(stderr,"%s ", msg? msg : "DumpRectF:"); 

  if(r)
  {
    fprintf(stderr,"%g %g %g %g\n",
	    r->rf_xbot,
	    r->rf_ybot,
	    r->rf_xtop,
	    r->rf_ytop);
  }
  else
  {
    fprintf(stderr,"NULL\n");
  }
}

/*
 * ----------------------------------------------------------------------------
 * DumpRectFU --
 * 
 * print RectFloat (converting to user units)
 *
 * ----------------------------------------------------------------------------
 */		 
void 
DumpRectFU(char *msg, RectFloat *rf)
{
  fprintf(stderr,"%s ", msg? msg : "DumpRectFU:"); 

  if(rf)
  {
    fprintf(stderr,"%s ",
	    UnitsI2S((int) rf->rf_xbot));
    fprintf(stderr,"%s ",
	    UnitsI2S((int) rf->rf_ybot));
    fprintf(stderr,"%s ",
	    UnitsI2S((int) rf->rf_xtop));
    fprintf(stderr,"%s",
	    UnitsI2S((int) rf->rf_ytop));
  }
  else
  {
    fprintf(stderr,"NULL\n");
  }
}

/*
 * ----------------------------------------------------------------------------
 * DumpTypes --
 * 
 * print type mask (as type names)
 *
 * ----------------------------------------------------------------------------
 */		 
void 
DumpTypes(char *msg, TileTypeBitMask *types)
{
  int i;

  fprintf(stderr,"%s ", 
	  msg ? msg : "DumpTypes:");

  for(i=0; i< DBNumTypes; i++)
  {
    if (TTMaskHasType(types,i)) fprintf(stderr,"%s ",DBTypeLongName(i));
  }

  fprintf(stderr,"\n");
}


/*
 * ----------------------------------------------------------------------------
 * DumpPlaneList --
 * 
 * print list of planes (names and numbers)
 *
 * ----------------------------------------------------------------------------
 */		 
void 
DumpPlaneList(char *msg, PlaneList *pll)
{
  fprintf(stderr,"%s ", 
	  msg ? msg : "DumpPlaneList:  ");

  for(;pll;pll=pll->pll_next)
  {
    fprintf(stderr,"%s(%d) ",
	    DBPlaneLongNameTbl[pll->pll_num],
	    pll->pll_num);
  }

  fprintf(stderr,"\n");
}

/*
 * ----------------------------------------------------------------------------
 * DebugUse --
 * 
 * print use info (to debug bbox mismatch)
 *
 * ----------------------------------------------------------------------------
 */		 
void 
DebugUse(char *msg, CellUse *use)
{
  fprintf(stderr,"%s ", 
	  msg ? msg : "DebugUse:  ");

  fprintf(stderr,"cu_def=%s\n\tcu_vBBOX=(%d,%d)\n\tcd_vBBOX=(%d,%d)\n",
	  use->cu_def->cd_name,
	  use->cu_vBBOX.vs_time,
	  use->cu_vBBOX.vs_rev,
	  use->cu_def->cd_vBBOX.vs_time,
	  use->cu_def->cd_vBBOX.vs_rev);
  DumpRect("\tcu_bbox= ",&use->cu_bbox);
  DumpRect("\tcd_bbox= ",&use->cu_def->cd_bbox);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DebugUnitsTclInit --
 *
 * Initialize debug tcl stuff
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
DebugTclInit(Tcl_Interp *interp)
{
   MnDocLinkVar(interp, "DEBUG_0", 
	       (char *) &Debug0, TCL_LINK_INT,
		"available for misc use during debugging.",
		"linked to C global int Debug0");
   MnDocLinkVar(interp, "DEBUG_1", 
	       (char *) &Debug1, TCL_LINK_INT,
		"available for misc use during debugging.",
		"linked to C global int Debug1");
   MnDocLinkVar(interp, "DEBUG_2", 
	       (char *) &Debug2, TCL_LINK_INT,
		"available for misc use during debugging.",
		"linked to C global int Debug2");
   MnDocLinkVar(interp, "DEBUG_3", 
	       (char *) &Debug3, TCL_LINK_INT,
		"available for misc use during debugging.",
		"linked to C global int Debug3");
}






