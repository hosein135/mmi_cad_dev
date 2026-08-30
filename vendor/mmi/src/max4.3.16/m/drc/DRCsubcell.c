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
 * DRCsubcell.c --
 *
 * This file provides the facilities for finding design-rule
 * violations that occur as a result of interactions between
 * subcells and either paint or other subcells.
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
static char rcsid[] = "$Header: DRCsubcell.c,v 1.5 92/07/20 13:48:46 mayo Exp $";
#endif	not lint

#include <stdio.h>
#include <sys/types.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "commands.h"
#include "undo.h"
#include "signals.h"
#include "drc.h"
#include "drcInt.h"


/* The variables below are made owns so that they can be used to
 * pass information to the various search functions.
 */


static int drcSubCaller;  /* code giving who we are finding interations
			   * for, e.g. drc, cifgen or extractor.  
			   */

static bool drcSubWithParentFound; /* set if subcell that is always checked
				    * with parent is found in interaction
				    * area
				    */
static Rect drcSubIntArea;	/* Accumulates area of interactions. */
static CellDef *drcSubDef;	/* Cell definition we're checking. */
static int drcSubRadius;	/* Interaction radius. */
static TileTypeBitMask drcSubTileTypes; 
				/* Mask of layers to look at when computing
				 * interaction areas.  Anything not in the mask
				 * is ignored.
				 */
static Rect drcSubLookArea;	/* Area where we're looking for interactions */
static void (*drcSubFunc)();	/* Error function. */
static ClientData drcSubClientData;
				/* To be passed to error function. */

/* The cookie below is dummied up to provide an error message for
 * errors that occur because of inexact overlaps between subcells.
 */

static DRCCookie drcSubcellCookie = {
    0, { 0 }, { 0 }, (DRCCookie *) NULL,
    "This layer can't abut or partially overlap between subcells",
    0, 0, 0};


/*
 * ----------------------------------------------------------------------------
 *
 * drcSubcellFunc --
 *
 * It checks if this subcell participates in any interactions 
 * in the area we're rechecking.
 *
 * Side effects:
 *	The area drcSubIntArea is modified to include interactions
 *	stemming from this subcell.
 *
 * ----------------------------------------------------------------------------
 */

static void
drcSubcellFunc(CellUse *use)
               			/* cell use near check area */
{
    Rect haloArea, intArea;
    int i;

    GEO_EXPAND(&use->cu_bbox, drcSubRadius, &haloArea);
    GeoClip(&haloArea, &drcSubLookArea);

    /* special case DRC_WITH_PARENTS cells */
    if(drcSubCaller==DRCFI_DRC &&
       (use->cu_def->cd_flags & CD_DRC_WITH_PARENT))
    {
      GeoInclude(&haloArea, &drcSubIntArea);
      drcSubWithParentFound = TRUE;
      return;
    }

    /* special case GCELLS */
    if(drcSubCaller==DRCFI_CIF_FLATTEN_GCELLS &&
       (use->cu_def->cd_flags & CD_GENERATED))
    {
      return;
    }

    /* To determine interactions, find the bounding box of
     * all paint and other subcells within one halo of this
     * subcell tile (and also within the original area where
     * we're recomputing errors).
     */

    /* paint */
    intArea = GeoNullRect;
    for (i = PL_TECHDEPBASE; i < DBNumPlanes; i++)
    {
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, drcSubDef->cd_planes[i],
	    &haloArea, &drcSubTileTypes, drcIncludeArea,
	    (ClientData) &intArea);
    }

    /* other subcells */
    {
      BPEnum bpe;
      CellUse *found;

      BPEnumInit(&bpe, 
		 drcSubDef->cd_cellPlane,
		 &haloArea,
		 BPE_OVERLAP,
		 "DRCFindInteractions");

      while(found = BPEnumNext(&bpe))
      {
	if(use == found) continue;
	GeoInclude(&use->cu_bbox, &intArea);
      }

      BPEnumTerm(&bpe);
    }

    if (GEO_RECTNULL(&intArea)) return;

    GEO_EXPAND(&intArea, drcSubRadius, &intArea);
    GeoClip(&intArea, &haloArea);
    (void) GeoInclude(&intArea, &drcSubIntArea);
}


/*
 * ----------------------------------------------------------------------------
 *
 * drcAlwaysOne --
 *
 * 	This is a utility procedure that always returns 1 when it
 *	is called.  It aborts searches and notifies the invoker that
 *	an item was found during the search.
 *
 * Results:
 *	Always returns 1 to abort searches.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

int
drcAlwaysOne(void)
{
  return 1;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcSubCheckPaint --
 *
 * 	This procedure is invoked once for each subcell in a
 *	particular interaction area.  It checks to see whether the
 *	subcell's subtree actually contains some paint in the potential
 *	interaction area.  As soon as the second such subcell is found,
 *	it aborts the search.
 *
 * Results:
 *	Returns 0 to keep the search alive, unless we've found the
 *	second subcell containing paint in the interaction area.
 *	When this occurs, the search is aborted by returning 1.
 *
 * Side effects:
 *	When the first use with paint is found, curUse is modified
 *	to contain its address.
 *
 * ----------------------------------------------------------------------------
 */

int
drcSubCheckPaint(SearchContext *scx, CellUse **curUse)
                       		/* Contains information about the celluse
				 * that was found.
				 */
                     		/* Points to a celluse, or NULL, or -1.  -1
				 * means paint was found in the root cell,
				 * and non-NULL means some other celluse had
				 * paint in it.  If we find another celluse
				 * with paint, when this is non-NULL, it
				 * means there really are two cells with
				 * interacting paint, so we abort the
				 * search to tell the caller to really check
				 * this area.
				 */
{
      
    if (DBSearchPaint(scx, &drcSubTileTypes, 0, drcAlwaysOne,
	(ClientData) NULL) != 0)
    {

      if(drcSubCaller==DRCFI_CIF_FLATTEN_GCELLS && 
	 (scx->scx_use->cu_def->cd_flags&CD_GENERATED))
      {
	/* flattening gcells, treat like paint in parent */
	if(*curUse==NULL || *curUse== (CellUse *) -1) 
	{
	  *curUse = (CellUse *) -1;
	  return 0;
	}
	else 
	{
	  return 1;
	}
      }
      else
      {
	/* This subtree has stuff under the interaction area. */
	if (*curUse != NULL) return 1;
	*curUse = scx->scx_use;
      }
    }
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCFindInteractions --
 *
 * 	This procedure finds the bounding box of all subcell-subcell
 *	or subcell-paint interactions in a given area of a given cell.
 *
 * Results:
 *	Returns TRUE if there were any interactions in the given
 *	area, FALSE if there were none.
 *
 * Side effects:
 *	The parameter interaction is set to contain the bounding box
 *	of all places in area where one subcell comes within radius
 *	of another subcell, or where paint in def comes within radius
 *	of a subcell.  Interactions between elements of array are not
 *	considered here, but interactions between arrays and other
 *	things are considered.  This routine is a bit clever, in that
 *	it not only checks for bounding boxes interacting, but also
 *	makes sure the cells really contain material in the interaction
 *	area.
 * ----------------------------------------------------------------------------
 */

bool
DRCFindInteractions(CellDef *def, 
                 		/* Cell to check for interactions. */
		    Rect *area, 
               			/* Area of def to check for interacting
				 * material.
				 */
		    int radius, 
               			/* How close two pieces of material must be
				 * to be considered interacting.  Two pieces
				 * radius apart do NOT interact, but if they're
				 * closer than this they do.
				 */
		    Rect *interaction, 
                      		/* Gets filled in with the bounding box of
				 * the interaction area, if any.  Doesn't
				 * have a defined value when FALSE is returned.
				 */
		    TileTypeBitMask *layersToCheck,
				/* Only layers in this mask are checked when
				 * finding interactions.  Normally set to
				 * DBAllButSpaceAndDRCBits.
				 */
		    int caller)
		                /* code giving whose asking (since processing
				 * is slightly different for drc, cifgen, and
				 * extraction)
				 */
{
    int i;
    CellUse *use;
    CellUse dummy;
    SearchContext scx;
    
    
    drcSubDef = def;
    drcSubRadius = radius;
    drcSubTileTypes = *layersToCheck;

    /* pass caller code to helper funcs */ 
    drcSubCaller = caller;

    /* Find all the interactions in the area and compute the
     * outer bounding box of all those interactions.  An interaction
     * exists whenever material in one cell approaches within radius
     * of material in another cell.  As a first approximation, assume
     * each cell has material everywhere within its bounding box.
     */
    drcSubIntArea = GeoNullRect;
    drcSubWithParentFound = FALSE;
    GEO_EXPAND(area, radius, &drcSubLookArea);
    {
      BPEnum bpe;
      CellUse *use;

      BPEnumInit(&bpe, 
		 def->cd_cellPlane,
		 &drcSubLookArea,
		 BPE_OVERLAP,
		 "DRCFindInteractions");

      while(use = BPEnumNext(&bpe)) drcSubcellFunc(use);

      BPEnumTerm(&bpe);
    }
    if(drcSubWithParentFound) goto real;

    /* If there seems to be an interaction area, make a second pass
     * to make sure there's more than one cell with paint in the
     * area.  This will save us a lot of work where two cells
     * have overlapping bounding boxes without overlapping paint.
     */
    
    if (GEO_RECTNULL(&drcSubIntArea)) return FALSE;
    use = NULL;
    for (i = PL_TECHDEPBASE; i < DBNumPlanes; i++)
    {
	if (DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[i],
	    &drcSubIntArea, &drcSubTileTypes, drcAlwaysOne,
	    (ClientData) NULL) != 0)
	{
	    use = (CellUse *) -1;
	    break;
	}
    }

    scx.scx_use = DBCellUseNewTemp(def, &dummy);
    scx.scx_trans = GeoIdentityTransform;
    scx.scx_area = drcSubIntArea;
    if (DBSearchInstances2(&scx, 
			   0, 
			   NULL,
			   drcSubCheckPaint, 
			   (ClientData) &use,
			   DBSI_INCLUDE_EXPANDED | DBSI_NON_RECURSIVE)
	== 0)
    {
      return FALSE;
    }

 real:
    /* OK, no more excuses, there's really an interaction area here. */
    *interaction = drcSubIntArea;
    GeoClip(interaction, area);
    if (GEO_RECTNULL(interaction)) return FALSE;
    return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcExactOverlapCheck --
 *
 * 	This procedure is invoked to check for overlap violations.
 *	It is invoked by DBPlaneEnumAreaPaint from drcExactOverlapTile.
 *	Any tiles passed to this procedure must lie within
 *	arg->dCD_rect, or an error is reported.
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	If an error occurs, the client error function is called and
 *	the error count is incremented.
 *
 * ----------------------------------------------------------------------------
 */

int
drcExactOverlapCheck(Tile *tile, struct drcClientData *arg)
               			/* Tile to check. */
                              	/* How to detect and process errors. */
{
    Rect rect;

    TiToRect(tile, &rect);
    if (GEO_SURROUND(arg->dCD_rect, &rect)) return 0;

    GeoClip(&rect, arg->dCD_clip);
    if (GEO_RECTNULL(&rect)) return 0;

    (*(arg->dCD_function)) (arg->dCD_celldef, &rect, arg->dCD_cptr,
	arg->dCD_clientData);
    (*(arg->dCD_errors))++;
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcExactOverlapTile --
 *
 * 	This procedure is invoked by DBSearchPaint for each tile
 *	in each constituent cell of a subcell interaction.  It
 *	makes sure that if this tile overlaps other tiles of the
 *	same type in other cells, then the overlaps are EXACT:
 *	each cell contains exactly the same information.
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	If there are errors, the client error handling routine
 *	is invoked and the count in the drcClientData record is
 *	incremented.
 *
 * ----------------------------------------------------------------------------
 */

int
drcExactOverlapTile(Tile *tile, TreeContext *cxp)
               			/* Tile that must overlap exactly. */
                     		/* Tells how to translate out of subcell.
				 * The client data must be a drcClientData
				 * record, and the caller must have filled
				 * in the celldef, clip, errors, function,
				 * cptr, and clientData fields.
				 */
{
    struct drcClientData *arg;
    TileTypeBitMask typeMask;
    Rect r1, r2;
    int i;
    
    arg = (struct drcClientData *) cxp->tc_filter->tf_arg;
    TiToRect(tile, &r1);
    GeoTransRect(&(cxp->tc_scx->scx_trans), &r1, &r2);
    arg->dCD_rect = &r2;
    GEO_EXPAND(&r2, 1, &r1);
    for (i = PL_TECHDEPBASE; i < DBNumPlanes; i++)
    {
	TTMaskSetOnlyType(&typeMask, DBgetTileType(tile));
        (void) DBPlaneEnumAreaPaint((Tile *) NULL, DRCdef->cd_planes[i],
	    &r1, &typeMask, drcExactOverlapCheck, (ClientData) arg);
    }
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCInteractionCheck --
 *
 * 	This is the top-level procedure that performs subcell interaction
 *	checks.  All interaction rule violations in area of def are
 *	found, and func is called for each one.
 *
 * Results:
 *	The number of errors found.
 *
 * Side effects:
 *	The procedure func is called for each violation found.  See
 *	the header for DRCBasicCheck for information about how func
 *	is called.  The violations passed to func are expressed in
 *	the coordinates of def.  Only violations stemming from
 *	interactions in def, as opposed to def's children, are reported.
 *
 * Design Note:
 *	This procedure is trickier than you think.  The problem is that
 *	DRC must be guaranteed to produce EXACTLY the same collection
 *	of errors in an area, no matter how the area is checked.  Checking
 *	it all as one big area should produce the same results as
 *	checking it in several smaller pieces.  Otherwise, "drc why"
 *	won't work correctly, and the error configuration will depend
 *	on how the chip was checked, which is intolerable.  This problem
 *	is solved here by dividing the world up into squares along a grid
 *	of dimension drcStepSize aligned at the origin.  Interaction areas
 *	are always computed by considering everything inside one grid square
 *	at a time.  We may have to consider several grid squares in order
 *	to cover the area passed in by the client.
 * ----------------------------------------------------------------------------
 */

int
DRCInteractionCheck(CellDef *def, 
                 		/* Definition in which to do check. */
		    Rect *area,
               			/* Area in which all errors are to be found. */
		    void (*func) (/* ??? */), 
                   		/* Function to call for each error. */
		    ClientData cdarg, 
                     		/* Extra info to be passed to func. */
		    void (*funci) (/* ??? */), 
                    		/* Function to call for each interact area. */
		    ClientData cdargi)
                      		/* Extra info to be passed to funci. */
{
    int oldTiles, count, x, y;
    Rect intArea, square;
    PaintResultType (*savedPaintTable)[NT][NT];
    Void (*savedPaintPlane)();
    struct drcClientData arg;
    SearchContext scx;
    CellUse dummy;

    drcSubFunc = func;
    drcSubClientData = cdarg;
    oldTiles = DRCstatTiles;
    count = 0;

    /* DEBUG
    fprintf(stderr,"DEBUG DRCInteractionCheck def=%s\n", def->cd_name);
    DumpRect("DEBUG area= ",area);
    */

    /* Divide the area to be checked up into squares.  Process each
     * square separately.
     */
    
    x = (area->r_xbot/drcStepSize) * drcStepSize;
    if (x > area->r_xbot) x -= drcStepSize;
    y = (area->r_ybot/drcStepSize) * drcStepSize;
    if (y > area->r_ybot) y -= drcStepSize;
    for (square.r_xbot = x; square.r_xbot < area->r_xtop;
	 square.r_xbot += drcStepSize)
	for (square.r_ybot = y; square.r_ybot < area->r_ytop;
	     square.r_ybot += drcStepSize)
	{
	    square.r_xtop = square.r_xbot + drcStepSize;
	    square.r_ytop = square.r_ybot + drcStepSize;

	    /* Find all the interactions in the square, and clip to the error
	     * area we're interested in. */

	    if (!DRCFindInteractions(def, 
				     &square, 
				     TechHalo, 
				     &intArea, 
				     &DBAllButSpaceAndDRCBits,
				     DRCFI_DRC)) continue;

	    GeoClip(&intArea, area);
	    if(GEO_RECTNULL(&intArea)) continue;
	    if (funci) (*funci)(&intArea, cdargi);
    
	    /* Flatten the interaction area. */

	    DRCstatInteractions += 1;
	    GEO_EXPAND(&intArea, TechHalo, &scx.scx_area);
	    scx.scx_use = DBCellUseNewTemp(def, &dummy);
	    scx.scx_trans = GeoIdentityTransform;
	    DBCellClearContents(DRCdef);
	    savedPaintTable = DBNewPaintTable(DRCPaintTable);
	    savedPaintPlane = DBNewPaintPlane(DBPaintPlaneMergeOnce);
	    (void) DBCellCopyAllPaint(&scx, &DBAllButSpaceBits, 0, DRCuse);
	    (void) DBNewPaintTable(savedPaintTable);
	    (void) DBNewPaintPlane(savedPaintPlane);

	    /* Run the basic checker over the interaction area. */

	    count += DRCBasicCheck(DRCdef, &scx.scx_area, &intArea,
		func, cdarg);
	    /* MsgInfoF("Interaction area: (%d, %d) (%d %d)\n",
		intArea.r_xbot, intArea.r_ybot,
		intArea.r_xtop, intArea.r_ytop);
	    */

	    /* Check for illegal partial overlaps. */
	    scx.scx_use = &dummy;
	    scx.scx_area = intArea;
	    scx.scx_trans = GeoIdentityTransform;
	    arg.dCD_celldef = DRCdef;
	    arg.dCD_clip = &intArea;
	    arg.dCD_errors = &count;
	    arg.dCD_cptr = &drcSubcellCookie;
	    arg.dCD_function = func;
	    arg.dCD_clientData = cdarg;
	    (void) DBSearchPaint(&scx, &DRCExactOverlapTypes, 0,
		drcExactOverlapTile, (ClientData) &arg);
	}
    
    /* Update count of interaction tiles processed. */
    DRCstatIntTiles += DRCstatTiles - oldTiles;

    return count;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCFlatCheck --
 *
 * 	This is a top-level procedure that performs a DRC of a cell by
 *	flattening everything.  This is useful when we have a big chip were
 *	everything interacts -- such as when everything is covered by wiring.
 *	In these cases, a flat check of the topmost cell will catch all errors
 *	more quickly.
 *
 * Results:
 *	The number of errors found.
 *
 * Side effects:
 *	The procedure func is called for each violation found.  See
 *	the header for DRCBasicCheck for information about how func
 *	is called.  The violations passed to func are expressed in
 *	the coordinates of def.  All voilations found, even those in children,
 *	are reported.
 *
 * Design Note:
 *	This procedure is trickier than you think, in the same way as
 *	DRCInteractionCheck.  See the comments there.  
 *	Since this is a flat check of a single cell, no DRC updates are done
 *	to subcells.  Also, if this is interrupted the DRC error tiles will
 *	be incorrect!  This a a tradeoff to gain a slight amount of speed.
 * ----------------------------------------------------------------------------
 */
int
DRCFlatCheck(CellDef *def, 
                 		/* Definition in which to do check. */
	     Rect *area, 
               			/* Area in which all errors are to be found. */
	     int extraHalo)
                  		/* An extra amount to yank.  Kind of a kludge:
				 * CIF halo can be bigger than DRC halo. 
				 */
{
    Rect square, wholeArea;
    struct drcClientData arg;
    SearchContext scx;
    CellUse dummy;
    int count, x, y, x2, y2;

    /* make sure def is up-to-date */
    DBUpdate(def);

    drcSubFunc = drcPaintError;
    drcSubClientData = (ClientData) def->cd_planes[PL_DRC_ERROR];
    count = 0;

    /* Divide the area to be checked up into squares.  Process each
     * square separately.  Erase the error information in the area we
     * will be checking.  If we run to completion we will put the proper
     * errors back.  If we are interrupted the error info will be wrong,
     * but at least the code will run a bit faster this way.
     */
    
    x = (area->r_xbot/drcStepSize) * drcStepSize;
    if (x > area->r_xbot) x -= drcStepSize;
    x2 = (area->r_xtop/drcStepSize) * drcStepSize;
    if (x2 < area->r_xtop) x2 += drcStepSize;
    y = (area->r_ybot/drcStepSize) * drcStepSize;
    if (y > area->r_ybot) y -= drcStepSize;
    y2 = (area->r_ytop/drcStepSize) * drcStepSize;
    if (y2 < area->r_ytop) y2 += drcStepSize;
    wholeArea.r_xbot = x; wholeArea.r_xtop = x2;
    wholeArea.r_ybot = y; wholeArea.r_ytop = y2;
    DBPaintPlane(def->cd_planes[PL_DRC_ERROR], &wholeArea,
        DBStdEraseTbl(TT_ERROR_P, PL_DRC_ERROR),
        (PaintUndoInfo *) NULL);
    DBPaintPlane(def->cd_planes[PL_DRC_ERROR], &wholeArea,
        DBStdEraseTbl(TT_ERROR_S, PL_DRC_ERROR),
        (PaintUndoInfo *) NULL);
    DRCErrorType = TT_ERROR_P;
    DRCErrorDef = def;

    for (square.r_xbot = x; square.r_xbot < area->r_xtop;
	 square.r_xbot += drcStepSize)
	for (square.r_ybot = y; square.r_ybot < area->r_ytop;
	     square.r_ybot += drcStepSize)
	{
	    Rect yankarea, checkarea;
	    bool subcellFound;

	    square.r_xtop = square.r_xbot + drcStepSize;
	    square.r_ytop = square.r_ybot + drcStepSize;
	    if (SigInterruptPending) {
		MsgErrorF("Interrupted.\nWarning:  DRC errors may be missing from the display.\nYou are advised to re-check the area.\n");
		goto done;
	    }

	    /* See if there are any subcells in the area */
	    GEO_EXPAND(&square, TechHalo+extraHalo, &yankarea);  
	    GEO_EXPAND(&square, TechHalo, &checkarea);

	    /* check if any subcell overlaps check area */
	    {
	      BPEnum bpe;
	      
	      BPEnumInit(&bpe,
			 def->cd_cellPlane,
			 &checkarea,
			 BPE_OVERLAP,
			 "DRCFlatCheck");
	      subcellFound = (BPEnumNext(&bpe)!=NULL);
	      BPEnumTerm(&bpe);
	    }

	    if (subcellFound)
	    {
		/* We have a subcell.  Flatten the area and then check. */
		PaintResultType (*savedPaintTable)[NT][NT];
		Void (*savedPaintPlane)();

		scx.scx_area = yankarea;
		scx.scx_use = DBCellUseNewTemp(def, &dummy);
		scx.scx_trans = GeoIdentityTransform;
		DBCellClearContents(DRCdef);
		savedPaintTable = DBNewPaintTable(DRCPaintTable);
		savedPaintPlane = DBNewPaintPlane(DBPaintPlaneMergeOnce);
		(void) DBCellCopyAllPaint(&scx, &DBAllButSpaceBits, 0, DRCuse);
		(void) DBNewPaintTable(savedPaintTable);
		(void) DBNewPaintPlane(savedPaintPlane);

		/* Run the basic checker over the flattened area. */
		count += DRCBasicCheck(DRCdef, &checkarea, &square,
		    drcPaintError, (ClientData) def->cd_planes[PL_DRC_ERROR]);

		/* Check for illegal partial overlaps.  This can't be done
		 * flat!
		 */
		scx.scx_use = &dummy;
		scx.scx_area = checkarea;
		scx.scx_trans = GeoIdentityTransform;
		arg.dCD_celldef = DRCdef;
		arg.dCD_clip = &square;
		arg.dCD_errors = &count;
		arg.dCD_cptr = &drcSubcellCookie;
		arg.dCD_function = drcPaintError;
		arg.dCD_clientData = (ClientData) def->cd_planes[PL_DRC_ERROR];
		(void) DBSearchPaint(&scx, &DRCExactOverlapTypes, 0,
		    drcExactOverlapTile, (ClientData) &arg);
	    } else {
		/* No subcell, check in place. */
		count += DRCBasicCheck(def, &checkarea, &square,
		    drcPaintError, (ClientData) def->cd_planes[PL_DRC_ERROR]);
	    }
	}
    /* Since this meant for batch mode, and DRC speed is critical,
     * we redisplay the entire area rather
     * than being smart in the inner loop about which areas changed. 
     */
done:
    DBChangedArea(def, 
		  &wholeArea, 
		  &DRCTypes,
		  DBCF_DRC_ERROR_ONLY);
    return count;
}
