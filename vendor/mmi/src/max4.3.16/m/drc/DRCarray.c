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
 * DRCarray.c --
 *
 * This file provides routines that check arrays to be sure
 * there are no unpleasant interactions between adjacent
 * elements.  Note:  the routines in this file are NOT generally
 * re-entrant.
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

#ifndef	lint
static char rcsid[] = "$Header: DRCarray.c,v 6.0 90/08/28 18:12:24 mayo Exp $";
#endif	not lint

#include <sys/types.h>
#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "drc.h"
#include "layout.h"
#include "commands.h"

/* Forward references: */

extern int drcArrayYankFunc(CellUse *use, Transform *transform, int x, int y, Rect *yankArea), drcArrayOverlapFunc(CellUse *use, Transform *transform, int x, int y, struct drcClientData *arg);

/* Dummy DRC cookie used to pass the error message to DRC error
 * routines.
 */

static DRCCookie drcArrayCookie = {
    0, { 0 }, { 0 }, (DRCCookie *) NULL,
    "This layer can't abut or partially overlap between array elements",
    0, 0, 0};

/* Static variables used to pass information between DRCArrayCheck
 * and drcArrayFunc:
 */

static int drcArrayCount;		/* Count of number of errors found. */
static void (*drcArrayErrorFunc)();	/* Function to call on violations. */
static ClientData drcArrayClientData;	/* Extra parameter to pass to func. */


/*
 * ----------------------------------------------------------------------------
 *
 * drcArrayFunc --
 *
 * 	This procedure is invoked by DBSrChildren once for each cell
 *	overlapping the area being checked.  If the celluse is for
 *	an array, then it is checked for array correctness.
 *
 * Results:
 *	Always returns 2, to skip the remaining instances in the
 *	current array.
 *
 * Side effects:
 *	Design rules are checked for the subcell, if it is an array,
 *	and the count of errors is added into drcSubCount.
 *
 * Design:
 *	To verify that an array is correct, we only have to check
 *	four interaction areas, shaded as A, B, C, and D in the diagram
 *	below.  The exact size of the interaction areas depends on
 *	how much overlap there is.  In the extreme cases, there may be
 *	no areas to check at all (instances widely separated), or there
 *	may even be areas with more than four instances overlapping
 *	(spacing less than half the size of the instance).
 *
 * 	--------------DDDDD------------------------------
 *	|             DDDDD             |               |
 *	|               |               |               |
 *	|               |               |               |
 *	|               |               |               |
 * 	-------------------------------------------------
 *	|               |               |               |
 *	|               |               |               |
 *	|               |               |               |
 *	AAAAAAAAAAAAAAAAAAA             |             CCC
 * 	AAAAAAAAAAAAAAAAAAA---------------------------CCC
 *	AAAAAAAAAAAAAAAAAAA             |             CCC
 *	|             BBBBB             |               |
 *	|             BBBBB             |               |
 *	|             BBBBB             |               |
 * 	--------------BBBBB------------------------------
 *
 * ----------------------------------------------------------------------------
 */

int
drcArrayFunc(SearchContext *scx, Rect *area)
                       		/* Information about the search. */
               			/* Area in which errors are to be
				 * regenerated.
				 */
{
    int xsep, ysep;
    int xsize, ysize;
    Rect errorArea, yankArea, tmp, tmp2;
    CellUse *use = scx->scx_use;
    Rect *bbox = DBBBoxCellUseNoUp(use);
    struct drcClientData arg;

    /* if not array, skip it */
    if (!DBIsArray(use)) return 2;
    
    /* Set up the client data that will be passed down during
     * checks for exact overlaps.
     */
    
    arg.dCD_celldef = DRCdef;
    arg.dCD_errors = &drcArrayCount;
    arg.dCD_clip = &errorArea;
    arg.dCD_cptr = &drcArrayCookie;
    arg.dCD_function = drcArrayErrorFunc;
    arg.dCD_clientData = drcArrayClientData;

    /* Compute the sizes and separations of elements, in coordinates
     * of the parend.  If the array is 1-dimensional, we set the
     * corresponding spacing to an impossibly large distance.
     */
    
    tmp.r_xbot = 0;
    tmp.r_ybot = 0;
    if (use->cu_xlo == use->cu_xhi)
	tmp.r_xtop = TechHalo + use->cu_def->cd_bbox.r_xtop
	    - use->cu_def->cd_bbox.r_xbot;
    else tmp.r_xtop = use->cu_xsep;
    if (use->cu_ylo == use->cu_yhi)
	tmp.r_ytop = TechHalo + use->cu_def->cd_bbox.r_ytop
	    - use->cu_def->cd_bbox.r_ybot;
    else tmp.r_ytop = use->cu_ysep;
    GeoTransRect(&use->cu_transform, &tmp, &tmp2);
    xsep = tmp2.r_xtop - tmp2.r_xbot;
    ysep = tmp2.r_ytop - tmp2.r_ybot;
    GeoTransRect(&use->cu_transform, &use->cu_def->cd_bbox, &tmp2);
    xsize = tmp2.r_xtop - tmp2.r_xbot;
    ysize = tmp2.r_ytop - tmp2.r_ybot;

    /* Check each of the four areas A, B, C, and D.  Remember that
     * absolutely arbitrary overlaps between cells are allowed.
     * Skip some or all of the areas if the cell isn't arrayed in
     * that direction or if the instances are widely spaced.
     */
    
    if (ysep < ysize + TechHalo)
    {
	/* A */

	errorArea.r_xbot = bbox->r_xbot;
	errorArea.r_xtop = bbox->r_xbot + xsize + TechHalo;
	errorArea.r_ybot = bbox->r_ybot + ysep - TechHalo;
	errorArea.r_ytop = bbox->r_ybot + ysize + TechHalo;
	GeoClip(&errorArea, area);
	if (!GEO_RECTNULL(&errorArea))
	{
	    GEO_EXPAND(&errorArea, TechHalo, &yankArea);
	    DBCellClearContents(DRCdef);
	    (void) DBEnumArrayElements(use, &yankArea, drcArrayYankFunc,
		(ClientData) &yankArea);
	    drcArrayCount += DRCBasicCheck(DRCdef, &yankArea, &errorArea,
		drcArrayErrorFunc, drcArrayClientData);
	    (void) DBEnumArrayElements(use, &errorArea, drcArrayOverlapFunc,
		(ClientData) &arg);
	}

	/* C */

	errorArea.r_xtop = bbox->r_xtop;
	errorArea.r_xbot = bbox->r_xtop - TechHalo;
	GeoClip(&errorArea, area);
	if (!GEO_RECTNULL(&errorArea))
	{
	    GEO_EXPAND(&errorArea, TechHalo, &yankArea);
	    DBCellClearContents(DRCdef);
	    (void) DBEnumArrayElements(use, &yankArea, drcArrayYankFunc,
		(ClientData) &yankArea);
	    drcArrayCount += DRCBasicCheck(DRCdef, &yankArea, &errorArea,
		drcArrayErrorFunc, drcArrayClientData);
	    (void) DBEnumArrayElements(use, &errorArea, drcArrayOverlapFunc,
		(ClientData) &arg);
	}
    }

    if (xsep < xsize + TechHalo)
    {
	/* B */

	errorArea.r_xbot = bbox->r_xbot + xsep - TechHalo;
	errorArea.r_xtop = bbox->r_xbot + xsize + TechHalo;
	errorArea.r_ybot = bbox->r_ybot;
	errorArea.r_ytop = errorArea.r_ybot + ysep - TechHalo;
	GeoClip(&errorArea, area);
	if (!GEO_RECTNULL(&errorArea))
	{
	    GEO_EXPAND(&errorArea, TechHalo, &yankArea);
	    DBCellClearContents(DRCdef);
	    (void) DBEnumArrayElements(use, &yankArea, drcArrayYankFunc,
		(ClientData) &yankArea);
	    drcArrayCount += DRCBasicCheck(DRCdef, &yankArea, &errorArea,
		drcArrayErrorFunc, drcArrayClientData);
	    (void) DBEnumArrayElements(use, &errorArea, drcArrayOverlapFunc,
		(ClientData) &arg);
	}

	/* D */

	errorArea.r_ytop = bbox->r_ytop;
	errorArea.r_ybot = bbox->r_ytop - TechHalo;
	GeoClip(&errorArea, area);
	if (!GEO_RECTNULL(&errorArea))
	{
	    GEO_EXPAND(&errorArea, TechHalo, &yankArea);
	    DBCellClearContents(DRCdef);
	    (void) DBEnumArrayElements(use, &yankArea, drcArrayYankFunc,
		(ClientData) &yankArea);
	    drcArrayCount += DRCBasicCheck(DRCdef, &yankArea, &errorArea,
		drcArrayErrorFunc, drcArrayClientData);
	    (void) DBEnumArrayElements(use, &errorArea, drcArrayOverlapFunc,
		(ClientData) &arg);
	}
    }
    
    return 2;
}

/*
 * ----------------------------------------------------------------------------
 * DRCArrayCheck --
 *
 *	This procedure finds all DRC errors in a given area of
 *	a given cell that stem from array formation errors in
 *	children of that cell.  Func is called for each violation
 *	found.  Func should have the same form as in DRCBasicCheck.
 *	Note: the def passed to func is the dummy DRC definition,
 *	and the errors are all expressed in coordinates of celluse.
 *
 * Results:
 *	The number of errors found.
 *
 * Side effects:
 *      Whatever is done by func.
 *
 * ----------------------------------------------------------------------------
 */

int
DRCArrayCheck(CellDef *def, Rect *area, void (*func) (/* ??? */), ClientData cdarg)
                 		/* Parent cell containing the arrays to
				 * be rechecked.
				 */
               			/* Area, in def's coordinates, where all
				 * array violations are to be regenerated.
				 */
                   		/* Function to call for each error. */
                     		/* Client data to be passed to func. */

{
    SearchContext scx;
    CellUse dummy;
    int oldTiles;
    PaintResultType (*savedPaintTable)[NT][NT];
    Void (*savedPaintPlane)();

    /* Use DRCDummyUse to fake up a celluse for searching purposes. */



    drcArrayErrorFunc = func;
    drcArrayClientData = cdarg;
    drcArrayCount = 0;
    oldTiles = DRCstatTiles;

    /* set up search context */
    scx.scx_area = *area;
    scx.scx_use = DBCellUseNewTemp(def, &dummy);
    scx.scx_trans = GeoIdentityTransform;

    /* During array processing, switch the paint table to catch
     * illegal overlaps.
     */

    savedPaintTable = DBNewPaintTable(DRCPaintTable);
    savedPaintPlane = DBNewPaintPlane(DBPaintPlaneMergeOnce);
    (void) DBSrChildren(&scx, drcArrayFunc, (ClientData) area);
    (void) DBNewPaintTable(savedPaintTable);
    (void) DBNewPaintPlane(savedPaintPlane);

    /* Update count of array tiles processed. */

    DRCstatArrayTiles += DRCstatTiles - oldTiles;
    return drcArrayCount;
}


/*
 * ----------------------------------------------------------------------------
 *
 * drcArrayYankFunc --
 *
 * 	Search action function called while yanking pieces of an array.
 *
 * Results:
 *	Always returns 0, to keep the search going.
 *
 * Side effects:
 *	Yanks from an array element into the DRC yank buffer.
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
int
drcArrayYankFunc(CellUse *use, Transform *transform, int x, int y, Rect *yankArea)
                 			/* CellUse being array-checked. */
                         		/* Transform from instance to parent.*/
             				/* Element indices (not used). */
                   			/* Area to yank (in parent coords). */

{
    SearchContext scx;
    Transform tinv;

    GeoInvertTrans(transform, &tinv);
    GeoTransRect(&tinv, yankArea, &scx.scx_area);
    scx.scx_use = use;
    scx.scx_trans = *transform;
    (void) DBCellCopyAllPaint(&scx, &DBAllButSpaceBits, 0, DRCuse);
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcArrayOverlapFunc --
 *
 * 	This is a search action function called while checking pieces
 *	of an array to be sure that there aren't any illegal partial
 *	overlaps.  It just invokes overlap checking facilities in
 *	DRCsubcell.c
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	The client's error function may be invoked.
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
int
drcArrayOverlapFunc(CellUse *use, Transform *transform, int x, int y, struct drcClientData *arg)
                 		/* CellUse for array element. */
                         	/* Transform from use to parent. */
             			/* Indices of element. */
                              	/* Information used in overlap
				 * checking.  See drcExactOverlapTile.
				 */
{
    Transform tinv;
    SearchContext scx;

    GeoInvertTrans(transform, &tinv);
    GeoTransRect(&tinv, arg->dCD_clip, &scx.scx_area);
    scx.scx_use = use;
    scx.scx_trans = *transform;
    (void) DBSearchPaint(&scx, &DRCExactOverlapTypes, 0,
	drcExactOverlapTile, (ClientData) arg);
    return 0;
}
