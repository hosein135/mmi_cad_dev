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
 * ExtInteraction.c --
 *
 * Circuit extraction.
 * Finds interaction areas.
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
static char rcsid[] = "$Header: ExtInter.c,v 6.0 90/08/28 18:15:14 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "undo.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "message.h"
#include "debug.h"
#include "extract.h"
#include "extractInt.h"
#include "signals.h"
#include "styles.h"

    /* Local data */
CellUse *extInterUse = (CellUse *) NULL;	/* Subtree being processed */
Plane *extInterPlane;				/* Paint into this plane */
int extInterHalo;				/* Elements closer than this
						 * constitute an interaction.
						 */
int extInterBloat;				/* Bloat by this much when
						 * painting into result plane.
						 */

    /* Forward declarations */
int extInterOverlapSubtree(SearchContext *scx);
int extInterOverlapTile(register Tile *tile, TreeContext *cxp);
int extInterSubtree(SearchContext *scx);
int extInterSubtreeClip(SearchContext *overlapScx, SearchContext *scx);
int extInterSubtreeElement(CellUse *use, Transform *trans, int x, int y, Rect *r);
int extInterSubtreeTile(register Tile *tile, register TreeContext *cxp);
int extInterSubtreePaint(register SearchContext *scx, CellDef *def);

#define	BLOATBY(r, h) ( (r)->r_xbot -= (h), (r)->r_ybot -= (h), \
			(r)->r_xtop += (h), (r)->r_ytop += (h) )

/*
 * ----------------------------------------------------------------------------
 *
 * ExtFindInteractions --
 *
 * Paint into the supplied tile plane 'resultPlane' TT_ERROR_P tiles
 * for each area in the CellDef 'def' that must be processed for
 * interactions.
 *
 * Each interaction arises from paint in two different subtrees
 * being less than (but not equal to) 'halo' units away from
 * each other.  In this definition, a subtree refers to a single
 * CellUse, which may be either a single cell or an entire array.
 *
 * If 'bloat' is non-zero, each interaction area is bloated by
 * this amount when being painted into the result plane.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Paints into the plane 'resultPlane'.
 *
 * ----------------------------------------------------------------------------
 */

Void
ExtFindInteractions(CellDef *def, int halo, int bloatby, Plane *resultPlane)
                 	/* Find interactions among children of def */
             		/* Interaction is elements closer than halo */
                	/* Bloat each interaction area by this amount when
			 * painting into resultPlane.
			 */
                       	/* Paint interaction areas into this plane */
{
    SearchContext scx;

    UndoDisable();
    extInterPlane = resultPlane;
    extInterHalo = halo;
    extInterBloat = bloatby;
    extParentUse->cu_def = def;
    scx.scx_use = extParentUse;
    scx.scx_trans = GeoIdentityTransform;
    scx.scx_area = def->cd_bbox;

    /*
     * Process each child subtree.
     * This involves comparing all the paint in the subtree
     * with all the paint in all other subtrees up to, but
     * not including, the subtree under consideration.
     */
    extInterUse = (CellUse *) NULL;
    (void) DBSrChildrenNested(&scx, extInterSubtree, (ClientData) NULL);

    /*
     * Process parent paint if there were any subcells.
     * We compare each paint rectangle with all the paint in
     * all the subtrees, to see if there is an overlap.
     */
    if (extInterUse)
    {
	extInterUse = (CellUse *) NULL;
	(void) DBSrChildrenNested(&scx, extInterSubtreePaint, (ClientData) def);
    }
    UndoEnable();
}

extInterSubtreePaint(register SearchContext *scx, CellDef *def)
{
    Rect r;
    int pNum;

    r = *DBBBoxCellUseNoUp(scx->scx_use);
    BLOATBY(&r, extInterHalo);
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[pNum], &r,
	    &DBAllButSpaceAndDRCBits, extInterSubtreeTile, (ClientData) NULL);

    return (2);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extInterSubtree --
 *
 * Called for each immediate child use of the cell being processed
 * for interactions.  Our job is to process all the paint in this
 * use against all other subtrees overlapping this one.
 *
 * Results:
 *	Returns 2 to abort after the first array element.
 *
 * Side effects:
 *	Sets extInterUse to scx->scx_use.
 *	Children may paint into extInterPlane.
 *
 * ----------------------------------------------------------------------------
 */

int
extInterSubtree(SearchContext *scx)
{
    CellUse *oldUse = extInterUse;
    SearchContext parentScx;

    extInterUse = scx->scx_use;
    if (oldUse)
    {
	/* Find all other subtrees overlapping this cell */
	parentScx.scx_area = *DBBBoxCellUseNoUp(scx->scx_use);
	BLOATBY(&parentScx.scx_area, extInterHalo);
	parentScx.scx_trans = GeoIdentityTransform;
	parentScx.scx_use = extParentUse;
	(void) DBSrChildrenNested(&parentScx, extInterSubtreeClip, (ClientData) scx);
    }
    return (2);
}

int
extInterSubtreeClip(SearchContext *overlapScx, SearchContext *scx)
{
    Rect r, r2;

    /* Only search as far as extInterUse */
    if (overlapScx->scx_use == extInterUse)
	return (2);

    /*
     * Only process the overlap between overlapScx and scx,
     * bloating both by extInterHalo.
     */
    r = *DBBBoxCellUseNoUp(overlapScx->scx_use);
    BLOATBY(&r, extInterHalo);
    r2 = *DBBBoxCellUseNoUp(scx->scx_use);
    BLOATBY(&r2, extInterHalo);
    GEOCLIP(&r, &r2);

    (void) DBEnumArrayElements(scx->scx_use, &r, extInterSubtreeElement,
		(ClientData) &r);
    return (2);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extInterSubtreeElement --
 *
 * Called for each element in the array forming the use passed to
 * extInterSubtree().  See extInterSubtree() for comments.
 *
 * Results:
 *	Returns 0 always.
 *
 * Side effects:
 *	See ExtFindInteractions.
 *
 * ----------------------------------------------------------------------------
 */

int
extInterSubtreeElement(CellUse *use, Transform *trans, int x, int y, Rect *r)
{
    SearchContext scx;
    Transform tinv;

    scx.scx_use = use;
    scx.scx_trans = *trans;
    scx.scx_x = x;
    scx.scx_y = y;
    GEOINVERTTRANS(trans, &tinv);
    GEOTRANSRECT(&tinv, r, &scx.scx_area);
    (void) DBSearchPaint(&scx, &DBAllButSpaceAndDRCBits, 0,
		extInterSubtreeTile, (ClientData) NULL);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extInterSubtreeTile --
 *
 * Called for each tile in the subtree being processed by
 * extInterSubtree().  Transform this tile to root coordinates,
 * bloating by extInterHalo, and then call extInterOverlapSubtree
 * to process all the other subtrees for paint overlapping
 * this bloated area.  If the argument 'cxp' is non-NULL, we
 * use cxp->tc_scx->scx_trans to transform the area of tile to
 * root coordinates; otherwise, we don't transform it at all.
 *
 * Results:
 *	Returns 0 always.
 *
 * Side effects:
 *	See extInterOverlapTile.
 *
 * ----------------------------------------------------------------------------
 */

int
extInterSubtreeTile(register Tile *tile, register TreeContext *cxp)
{
    SearchContext newscx;
    Rect r;

    TITORECT(tile, &r);
    BLOATBY(&r, extInterHalo);
    if (cxp)
    {
	GEOTRANSRECT(&cxp->tc_scx->scx_trans, &r, &newscx.scx_area);
    }
    else newscx.scx_area = r;
    newscx.scx_trans = GeoIdentityTransform;
    newscx.scx_use = extParentUse;
    (void) DBSrChildrenNested(&newscx, extInterOverlapSubtree, (ClientData) NULL);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extInterOverlapSubtree --
 *
 * Called for each subcell of the root that overlaps the piece
 * of paint found by extInterSubtreeTile() above.  We stop
 * as soon as we see extInterUse; otherwise, search all the
 * cells in the subtree rooted at scx->scx_use for paint
 * overlapping scx->scx_area.
 *
 * Results:
 *	Returns 2 if we see extInterUse; otherwise, returns 0.
 *
 * Side effects:
 *	Paints into the plane 'resultPlane'; see extInterOverlapTile.
 *
 * ----------------------------------------------------------------------------
 */

int
extInterOverlapSubtree(SearchContext *scx)
{
    if (extInterUse == scx->scx_use)
	return (2);

    (void) extTreeSrPaintArea(scx, extInterOverlapTile, (ClientData) NULL);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extInterOverlapTile --
 *
 * Called for each piece of paint overlapping the piece found
 * by extInterSubtreeTile().  Bloat the found piece by extInterHalo,
 * then clip to the area of the overlapping piece of paint in root
 * coordinates.  If the result is non-empty, paint it into the
 * plane extInterPlane.
 *
 * Results:
 *	Returns 0 always.
 *
 * Side effects:
 *	Paints into the plane 'resultPlane'.
 *
 * ----------------------------------------------------------------------------
 */

int
extInterOverlapTile(register Tile *tile, TreeContext *cxp)
{
    register SearchContext *scx = cxp->tc_scx;
    Rect r, rootr;

    TITORECT(tile, &r);
    BLOATBY(&r, extInterHalo);
    GEOCLIP(&r, &scx->scx_area);
    if (GEO_RECTNULL(&r))
	return (0);

    GEOTRANSRECT(&scx->scx_trans, &r, &rootr);
    BLOATBY(&rootr, extInterBloat);
    DBPaintPlane(extInterPlane, &rootr, DBStdWriteTbl(TT_ERROR_P),
		    (PaintUndoInfo *) NULL);

    return (0);
}

/*
 *-----------------------------------------------------------------------------
 *
 * extTreeSrPaintArea --
 *
 * Recursively search downward from the supplied CellUse for
 * all paint tiles.
 *
 * The procedure should be of the following form:
 *
 *	int
 *	func(tile, scx, cdata)
 *	    Tile *tile;
 *	    SearchContext *scx;
 *	    ClientData cdata;
 *	{
 *	}
 *
 * The SearchContext is stored in cxp->tc_scx, and the user's arg is stored
 * in cxp->tc_filter->tf_arg.
 *
 * In the above, the scx transform is the net transform from the coordinates
 * of tile to "world" coordinates (or whatever coordinates the initial
 * transform supplied to extTreeSrTiles was a transform to).  Func returns
 * 0 under normal conditions.  If 1 is returned, it is a request to
 * abort the search.
 *
 *			*** WARNING ***
 *
 * The client procedure should not modify any of the paint planes in
 * the cells visited by extTreeSrTiles, because we use DBPlaneEnumAreaPaint
 * as our paint-tile enumeration function.
 *
 * Results:
 *	0 is returned if the search finished normally.  1 is returned
 *	if the search was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *-----------------------------------------------------------------------------
 */

int
extTreeSrPaintArea(SearchContext *scx, int (*func) (/* ??? */), ClientData cdarg)
                       		/* Pointer to search context specifying
				 * a cell use to search, an area in the
				 * coordinates of the cell's def, and a
				 * transform back to "root" coordinates.
				 */
                  		/* Function to apply at each qualifying tile */
                     		/* Client data for above function */
{
    int extTreeSrFunc(register SearchContext *scx, register TreeFilter *fp);
    CellDef *def = scx->scx_use->cu_def;
    TreeContext context;
    TreeFilter filter;
    int pNum;

    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;

    filter.tf_func = func;
    filter.tf_arg = cdarg;
    context.tc_scx = scx;
    context.tc_filter = &filter;

    /*
     * Apply the function first to any of the tiles in the planes
     * for this CellUse's CellDef that match the mask.
     */
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
	if (DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[pNum],
		&scx->scx_area, &DBAllButSpaceAndDRCBits, func,
		(ClientData) &context))
	    return (1);

    /* Visit our children recursively */
    return (DBSrChildrenNested(scx, extTreeSrFunc, (ClientData) &filter));
}

/*
 * extTreeSrFunc --
 *
 * Filter procedure applied to subcells by extTreeSrPaintArea().
 */

int
extTreeSrFunc(register SearchContext *scx, register TreeFilter *fp)
{
    CellDef *def = scx->scx_use->cu_def;
    TreeContext context;
    int pNum;

    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return (0);

    context.tc_scx = scx;
    context.tc_filter = fp;

    /*
     * Apply the function first to any of the tiles in the planes
     * for this CellUse's CellDef that match the mask.
     */
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
	if (DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[pNum],
		&scx->scx_area, &DBAllButSpaceAndDRCBits,
		fp->tf_func, (ClientData) &context))
	    return (1);

    /* Visit our children recursively */
    return (DBSrChildrenNested(scx, extTreeSrFunc, (ClientData) fp));
}
