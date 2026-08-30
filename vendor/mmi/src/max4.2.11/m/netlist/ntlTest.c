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
 * ntlTest.c --
 *
 * netlisting
 * Interface for testing.
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
static char rcsid[] = "$Header: ntlTest.c,v 1.4 91/04/01 21:57:37 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "utils.h"
#include "geometry.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "layout.h"
#include "layout.h"
#include "main.h"
#include "commands.h"
#include "message.h"
#include "debug.h"
#include "extract.h"
#include "extractInt.h"

int ntlDebAreaEnum;
int ntlDebArray;
int ntlDebHardWay;
int ntlDebHierCap;
int ntlDebHierAreaCap;
int ntlDebLabel;
int ntlDebNeighbor;
int ntlDebNoArray;
int ntlDebNoFeedback;
int ntlDebNoHard;
int ntlDebNoSubcell;
int ntlDebLength;
int ntlDebPerim;
int ntlDebResist;
int ntlDebVisOnly;

#ifdef NOT_NOW
extern void ntlAll(CellUse* use, char * name);

/*
 * The following are used for selective redisplay while debugging
 * the circuit extractor.
 */
Rect extScreenClip;
CellDef *extCellDef;
Layout *extDebugWindow;

/* The width of an edge in pixels when it is displayed */
int extEdgePixels = 4;

int extShowInter(Tile *tile);

/*
 * ----------------------------------------------------------------------------
 *
 * ExtractTest --
 *
 * Command interface for testing circuit extraction.
 * Usage:
 *	*extract
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Extracts the current cell, writing a file named
 *	currentcellname.ext.
 *
 * ----------------------------------------------------------------------------
 */
void
NetlistTest(Layout *w, int argc, char *argv[])
{
    extern long extSubtreeTotalArea;
    extern long extSubtreeInteractionArea;
    extern long extSubtreeClippedArea;
    static Plane *interPlane = (Plane *) NULL;
    static long areaTotal = 0, areaInteraction = 0, areaClipped = 0;
    long a1, a2;
    int n, halo, bloat;
    CellUse *selectedCell;
    Rect editArea;
    char *addr, *name;
    FILE *f;
    typedef enum {  CLRDEBUG, CLRLENGTH, DRIVER, INTERACTIONS,
		    INTERCOUNT, PARENTS, RECEIVER, SETDEBUG, SHOWDEBUG,
		    SHOWPARENTS, SHOWTECH, STATS, STEP, TIME } cmdType;
    static struct
    {
	char	*cmd_name;
	cmdType	 cmd_val;
    } cmds[] = {
	"clrdebug",		CLRDEBUG,
	"clrlength",		CLRLENGTH,
	"driver",		DRIVER,
	"interactions",		INTERACTIONS,
	"intercount",		INTERCOUNT,
	"parents",		PARENTS,
	"receiver",		RECEIVER,
	"setdebug",		SETDEBUG,
	"showdebug",		SHOWDEBUG,
	"showparents",		SHOWPARENTS,
	"showtech",		SHOWTECH,
	"stats",		STATS,
	"step",			STEP,
	"times",		TIME,
	0
    };

    if (argc == 1)
    {
	selectedCell = CmdGetSelectedCell((Transform *) NULL);
	if (selectedCell == NULL)
	{
	    MsgErrorF("No cell selected\n");
	    return;
	}

	/*
	 borrowing this action for netlister
	 extDispInit(selectedCell->cu_def, w);
	ExtCell(selectedCell->cu_def, selectedCell->cu_def->cd_name, FALSE);
	*/

	/**************** NETLISTER **********************/
	ntlAll(selectedCell, (char *)NULL);

	return;
    }

    n = LookupStruct(argv[1], (LookupTable *) cmds, sizeof cmds[0]);
    if (n < 0)
    {
	MsgErrorF("Unrecognized subcommand: %s\n", argv[1]);
	MsgErrorF("Valid subcommands:");
	for (n = 0; cmds[n].cmd_name; n++)
	    MsgErrorF(" %s", cmds[n].cmd_name);
	MsgErrorF("\n");
	return;
    }

    switch (cmds[n].cmd_val)
    {
	case STATS:
	    areaTotal += extSubtreeTotalArea;
	    areaInteraction += extSubtreeInteractionArea;
	    areaClipped += extSubtreeClippedArea;
	    MsgInfoF("Extraction statistics (recent/total):\n");
	    MsgInfoF("Total area of all cells = %ld / %ld\n",
			extSubtreeTotalArea, areaTotal);
	    a1 = extSubtreeTotalArea;
	    a2 = areaTotal;
	    if (a1 == 0) a1 = 1;
	    if (a2 == 0) a2 = 1;
	    MsgInfoF(
	    "Total interaction area processed = %ld (%.2f%%) / %ld (%.2f%%)\n",
		extSubtreeInteractionArea,
		((double) extSubtreeInteractionArea) / ((double) a1) * 100.0,
		((double) areaInteraction) / ((double) a2) * 100.0);
	    MsgInfoF(
	    "Clipped interaction area= %ld (%.2f%%) / %ld (%.2f%%)\n",
		extSubtreeClippedArea,
		((double) extSubtreeClippedArea) / ((double) a1) * 100.0,
		((double) areaClipped) / ((double) a2) * 100.0);
	    extSubtreeTotalArea = 0;
	    extSubtreeInteractionArea = 0;
	    extSubtreeClippedArea = 0;
	    break;
	case INTERACTIONS:
	    if (interPlane == NULL)
		interPlane = DBPlaneNew((ClientData) TT_SPACE);
	    halo = 1, bloat = 0;
	    if (argc > 2) halo = atoi(argv[2]) + 1;
	    if (argc > 3) bloat = atoi(argv[3]);
	    ExtFindInteractions(EditCellUse->cu_def, halo, bloat, interPlane);
	    (void) DBPlaneEnumAreaPaint((Tile *) NULL, interPlane, &TiPlaneRect,
			&DBAllButSpaceBits, extShowInter, (ClientData) NULL);
	    DBPlaneClearPaint(interPlane);
	    break;
	case INTERCOUNT:
	    f = stdout;
	    halo = 1;
	    if (argc > 2)
		halo = atoi(argv[2]);
	    if (argc > 3)
	    {
		f = fopen(argv[3], "w");
		if (f == NULL)
		{
		    perror(argv[3]);
		    break;
		}
	    }
	    ExtInterCount(w->lay_rootUse, halo, f);
	    if (f != stdout)
		(void) fclose(f);
	    break;
	case TIME:
	    f = stdout;
	    if (argc > 2)
	    {
		f = fopen(argv[2], "w");
		if (f == NULL)
		{
		    perror(argv[2]);
		    break;
		}
	    }
	    ExtTimes(w->lay_rootUse, f);
	    if (f != stdout)
		(void) fclose(f);
	    break;
	case PARENTS:
	    if (ToolGetEditBox(&editArea))
		ExtParentArea(EditCellUse, &editArea, TRUE);
	    break;

	case DRIVER:
	    if (argc != 3)
	    {
		MsgErrorF("Usage: *extract driver terminalname\n");
		break;
	    }
	    ExtSetDriver(argv[2]);
	    break;
	case RECEIVER:
	    if (argc != 3)
	    {
		MsgErrorF("Usage: *extract receiver terminalname\n");
		break;
	    }
	    ExtSetReceiver(argv[2]);
	    break;
	case CLRLENGTH:
	    MsgInfoF("Clearing driver/receiver length list\n");
	    ExtLengthClear();
	    break;

	case SHOWPARENTS:
	    if (ToolGetEditBox(&editArea))
		ExtParentArea(EditCellUse, &editArea, FALSE);
	    break;
	case SETDEBUG:
	    DebugSet(extDebugID, argc - 2, &argv[2], TRUE);
	    break;
	case CLRDEBUG:
	    DebugSet(extDebugID, argc - 2, &argv[2], FALSE);
	    break;

	case SHOWDEBUG:
	    DebugShow(extDebugID);
	    break;
	case SHOWTECH:
	    MsgErrorF("showtech option not supported for netlister\n");
	    break;
	case STEP:
	    MsgInfoF("Current interaction step size is %d\n",
		    ExtCurStyle->exts_stepSize);
	    if (argc > 2)
	    {
		ExtCurStyle->exts_stepSize = atoi(argv[2]);
		MsgInfoF("New interaction step size is %d\n",
			ExtCurStyle->exts_stepSize);
	    }
	    break;
    }
}

extShowInter(Tile *tile)
{
    Rect r;

    TiToRect(tile, &r);
    LayFeedbackAdd(&r, "interaction", EditCellUse->cu_def,
	    1, STYLE_MEDIUMHIGHLIGHTS);

    return (0);
}

extShowTrans(char *name, register TileTypeBitMask *mask, FILE *out)
{
    register TileType t;

    (void) fprintf(out, "%s types: ", name);
    extShowMask(mask, out);
    (void) fprintf(out, "\n");

    for (t = 0; t < DBNumTypes; t++)
	if (TTMaskHasType(mask, t))
	{
	    (void) fprintf(out, "    %-8.8s  %d terminals: ",
			DBTypeShortName(t), ExtCurStyle->exts_transSDCount[t]);
	    extShowMask(&ExtCurStyle->exts_transSDTypes[t], out);
	    (void) fprintf(out, "\n\tcap (gate-sd/gate-ch) = %lf/%lf\n",
			ExtCurStyle->exts_transSDCap[t],
			ExtCurStyle->exts_transGateCap[t]);
	}
}

extShowConnect(char *hdr, TileTypeBitMask *connectsTo, FILE *out)
{
    register TileType t;

    (void) fprintf(out, "%s\n", hdr);
    for (t = TT_TECHDEPBASE; t < DBNumTypes; t++)
	if (!TTMaskEqual(&connectsTo[t], &DBZeroTypeBits))
	{
	    (void) fprintf(out, "    %-8.8s: ", DBTypeShortName(t));
	    extShowMask(&connectsTo[t], out);
	    (void) fprintf(out, "\n");
	}
}

extShowMask(register TileTypeBitMask *m, FILE *out)
{
    register TileType t;
    register bool first = TRUE;

    for (t = 0; t < DBNumTypes; t++)
	if (TTMaskHasType(m, t))
	{
	    if (!first)
		(void) fprintf(out, ",");
	    first = FALSE;
	    (void) fprintf(out, "%s", DBTypeShortName(t));
	}
}

extShowPlanes(register int m, FILE *out)
{
    register int pNum;
    register bool first = TRUE;

    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
	if (PlaneMaskHasPlane(m, pNum))
	{
	    if (!first)
		(void) fprintf(out, ",");
	    first = FALSE;
	    (void) fprintf(out, "%s", DBPlaneShortName(pNum));
	}
}

/*
 * ----------------------------------------------------------------------------
 *
 * extDispInit --
 *
 * Initialize the screen information to be used during
 * extraction debugging.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes extDebugWindow, extScreenClip, and extCellDef.
 *
 * ----------------------------------------------------------------------------
 */

extDispInit(CellDef *def, Layout *w)
{
  MsgErrorF("extDispInit, internal, error:  TODO mv to layout\n");
/*
  NEED TO MOVE GRAPHICS TO LAYOUT MODULE
  extDebugWindow = w;
  extCellDef = def;
  extScreenClip = w->lay_area;
  GeoClip(&extScreenClip, &GrScreenRect); 
*/
}

/*
 * ----------------------------------------------------------------------------
 *
 * extShowEdge --
 *
 * Display the edge described by the Boundary 'bp' on the display,
 * with text string 's' on the text terminal.  Prompt with '--next--'
 * to allow a primitive sort of 'more' processing.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the display.
 *
 * ----------------------------------------------------------------------------
 */

extShowEdge(char *s, Boundary *bp)
{
    Rect extScreenRect, edgeRect;
    int style = STYLE_SOLIDHIGHLIGHTS;

#ifdef HIDEIT
/*    TODO move this to layout? can't do graphics outside of layout module!  */

    edgeRect = bp->b_segment;

    layTransRectDBToW(extDebugWindow, &edgeRect, &extScreenRect); 
    if (extScreenRect.r_ybot == extScreenRect.r_ytop)
    {
	extScreenRect.r_ybot -= extEdgePixels/2;
	extScreenRect.r_ytop += extEdgePixels - extEdgePixels/2;
    }
    else /* extScreenRect.r_xtop == extScreenRect.r_xbot */
    {
	extScreenRect.r_xbot -= extEdgePixels/2;
	extScreenRect.r_xtop += extEdgePixels - extEdgePixels/2;
    }

    if (DebugIsSet(extDebugID, extDebVisOnly))
    {
	Rect r;

	r = extScreenRect;
	GeoClip(&r, &extScreenClip);
	if (r.r_xtop <= r.r_xbot || r.r_ytop <= r.r_ybot)
	    return;
    }

    MsgInfoF("%s: ", s);
    GrLock(extDebugWindow, TRUE);
    GrClipBox(&extScreenRect, style);
    GrUnlock(extDebugWindow);
    (void) GrFlush();
    extMore();
    GrLock(extDebugWindow, TRUE);
    GrClipBox(&extScreenRect, STYLE_ORANGE1);
    GrUnlock(extDebugWindow);
    (void) GrFlush();
#endif HIDEIT
}

/*
 * ----------------------------------------------------------------------------
 *
 * extShowTile --
 *
 * Display the tile 'tp' on the display by highlighting it.  Also show
 * the text string 's' on the terminal.  Prompt with '--next--' to allow
 * a primitive sort of more processing.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the display.
 *
 * ----------------------------------------------------------------------------
 */

extShowTile(Tile *tile, char *s, int style_index)
{
    Rect tileRect;
    static int styles[] = { STYLE_PALEHIGHLIGHTS, STYLE_DOTTEDHIGHLIGHTS };

    TiToRect(tile, &tileRect);
    if (!extShowRect(&tileRect, styles[style_index]))
	return;

    MsgInfoF("%s: ", s);
    extMore();
    (void) extShowRect(&tileRect, STYLE_ERASEHIGHLIGHTS);
}

bool
extShowRect(Rect *r, int style)
{
    Rect extScreenRect;

#ifdef HIDEIT
/* TODO remove can't do graphics outside of layout module! */

    layTransRectDBToW(extDebugWindow, r, &extScreenRect);
    if (DebugIsSet(extDebugID, extDebVisOnly))
    {
	Rect rclip;

	rclip = extScreenRect;
	GeoClip(&rclip, &extScreenClip);
	if (rclip.r_xtop <= rclip.r_xbot || rclip.r_ytop <= rclip.r_ybot)
	    return (FALSE);
    }

    GrLock(extDebugWindow, TRUE);
    GrClipBox(&extScreenRect, style);
    GrUnlock(extDebugWindow);
    (void) GrFlush();
#endif HIDEIT

    return (TRUE);
}

extMore(void)
{
    char line[100];

    MsgInfoF("--next--"); (void) fflush(stdout);
    (void) TxGetLine(line, sizeof line);
}

extNewYank(char *name, CellUse **puse, CellDef **pdef)
{
    DBNewYank(name, puse, pdef);
}

#endif
