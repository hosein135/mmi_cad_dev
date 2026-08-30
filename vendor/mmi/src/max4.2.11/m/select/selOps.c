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
 * selOps.c --
 *
 * This file contains top-level procedures to manipulate the selection,
 * e.g. to delete it, move it, etc.
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
static char rcsid[]="$Header: selOps.c,v 6.0 90/08/28 18:56:48 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"
#include "select.h"
#include "selInt.h"
#include "message.h"
#include "undo.h"
#include "malloc.h"
#include "drc.h"

/* The following variables are shared between SelectStretch and the
 * search functions that it causes to be invoked.
 */
static bool selStretchGroup;            /* if set ignore all but active group */
static int selStretchX, selStretchY;	/* Stretch distances.  Only one should
					 * ever be non-zero.
					 */
static TileType selStretchType;		/* Type of material being stretched. */

/* The following structure type is used to build up a list of areas
 * to be painted.  It's used to save information while a search of
 * the edit cell is in progress:  can't do the paints until the
 * search has finished.
 */

typedef struct stretchArea
{
    Rect sa_area;			/* Area to be painted. */
    TileType sa_type;			/* Type of material to paint. */
    struct stretchArea *sa_next;	/* Next element in list. */
} StretchArea;

/* Search function to delete paint. */

static int
selDelPaintFunc(Rect *rect, TileType type)
               			/* Area of paint, in root coords. */
                  		/* Type of paint to delete. */
{
    Rect editRect;

    GeoTransRect(&RootToEditTransform, rect, &editRect);
    DBErase(EditCellUse->cu_def, &editRect, type);
    return 0;
}

static int
selDelPolygonFunc(Polygon *poly, SearchContext *scx, ClientData notUsed)
{
  DBPolyDelete(scx->scx_use->cu_def, 
	       poly, 
	       FALSE /* FALSE = don't notify redisplay etc. */);
  return 0;
}

static int
selDelWirePathFunc(WirePath *wp, SearchContext *scx, ClientData notUsed)
{
  DBWPathDelete(scx->scx_use->cu_def, 
		wp, 
		FALSE /* FALSE = don't notify redisplay etc. */);
  return 0;
}

/* Search function to delete subcell uses. */

static int
selDelCellFunc(CellUse *selUse, 
	       CellUse *use, 
	       Transform *transform,
	       TerminalPath *tPath,
	       ClientData clientData)
{
    DBInstanceUnlink(use, use->cu_parent);
    DBInstanceUnplace(use);
    (void) DBCellDeleteUse(use);
    return 0;
}

static int
selDelLabelFunc(Label *label,	/* Label to delete. */
		CellDef *def,	/* cell label lives in */ 
		Transform *transform,
		TerminalPath *tPath,
		ClientData *notUsed)
{
  ASSERT(def==EditCellUse->cu_def,"selDelLabelFunc");
  DBLabelErase(def,label);

  return 0;
}

static StretchArea *selStretchList;	/* List of areas to paint. */

/*
 * ----------------------------------------------------------------------------
 *
 * SelectDelete --
 *
 * 	Delete everything in the edit cell that's selected.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stuff is removed from the edit cell.  If there's selected
 *	stuff that isn't in the edit cell, the user is warned.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectDelete(char *msg)
              		/* Some information to print in error messages.
			 * For example, if called as part of a move procedure,
			 * supply "moved".  This will appear in messages of
			 * the form "only edit cell information was moved".
			 */
{
    bool nonEdit;

    (void) SelEnumPaint(&DBAllButSpaceAndDRCBits, 
			TRUE, 
			&nonEdit,
			selDelPaintFunc, 
			selDelPolygonFunc,
			selDelWirePathFunc,
			(ClientData) NULL);

    if (nonEdit)
    {
	MsgInfoF("You selected paint outside the edit cell.  Only\n");
	MsgInfoF("    the paint in the edit cell was %s.\n", msg);
    }

    (void) SelEnumCells(TRUE, 
			&nonEdit, 
			(SearchContext *) NULL,
			(TerminalPath *) NULL, 
			(TerminalPath *) NULL, 
			selDelCellFunc, 
			(ClientData) NULL);

    if (nonEdit)
    {
	MsgInfoF("You selected one or more subcells that aren't children\n");
	MsgInfoF("    of the edit cell.  Only those in the edit cell were\n");
	MsgInfoF("    %s.\n", msg);
    }

    (void) SelEnumLabels(&DBAllTypeBits, 
			 TRUE, 
			 &nonEdit,
			 (TerminalPath *) NULL,  /* don't bother with pathnames */
			 selDelLabelFunc, (ClientData) NULL);

    if (nonEdit)
    {
	MsgErrorF("You selected one or more labels that aren't in the\n");
	MsgErrorF("    edit cell.  Only the label(s) in the edit cell\n");
	MsgErrorF("    were %s.\n", msg);
    }

    /* process database change */
    {
      Rect editArea;

      GeoTransRect(&RootToEditTransform, 
		   DBBBoxCellDef(SelectDef), 
		   &editArea);

      DBChangedArea(EditCellUse->cu_def, &editArea, NULL, 0);

    }

    /* clear selection */
    SelectClear();
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectCopy --
 *
 * 	This procedure makes a copy of the selection.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection is copied, with the copy being transformed by
 *	"transform" relative to the current selection.  The copy is
 *	made the new selection.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectCopy(Transform *transform,
                         	/* How to displace the copy relative
				 * to the original.  This displacement
				 * is given in root coordinates.
				 */
	   bool dupOK)          
	                        /* allow duplicate instances 
				 * on top of each other.
				 */
{
    SearchContext scx;

    /* Copy from SelectDef to Select2Def while transforming, then
     * let selectAndCopy2 do the rest of the work.  Don't record
     * anything involving Select2Def for undo-ing.
     */

    UndoDisable();
    DBCellClearContents(Select2Def);
    scx.scx_use = SelectUse;
    scx.scx_area = *DBBBoxCellUse(SelectUse);
    scx.scx_trans = *transform;
    (void) DBCellCopyAllPaint(&scx, &DBAllButSpaceAndDRCBits, -1, Select2Use);

    (void) DBCellCopyAllLabels(&scx, 
			       &DBAllTypeBits, 
			       -1, 
			       Select2Use,
			       (Rect *) NULL,
			       (char *) NULL);

    (void) DBCellCopyAllCells(&scx, -1, 
			      Select2Use, 
			      (Rect *) NULL, 
			      NULL,
			      FALSE,
			      (char *) NULL);

    DBChangedArea(Select2Def, NULL, NULL, 0);
    UndoEnable();

    SelectClear();
    selectAndCopy2(dupOK);
}


/* helper function to copy paint.  
 * Always return 1 to keep the search alive. */
static int
selTransPaintFunc(Rect *rect, TileType type, Transform *transform)
               			/* Area of paint. */
                  		/* Type of paint. */
                         	/* How to change coords before painting. */
{
    Rect new;

    GeoTransRect(transform, rect, &new);
    DBPaint(Select2Def, &new, type);
    return 0;
}


/* helper function to copy polygon.  
 * Always return 1 to keep the search alive. 
 */
static int
selTransPolygonFunc(Polygon *poly, 
		    SearchContext *scx, 
		    ClientData cdarg)
{
  Transform tFinal; 
  Transform *transform = (Transform *) cdarg;

  /* skip dependent polygons (part of wirepath */
  if(poly->poly_wirePath) return 0;

  /* compute composite transform */
  GeoTransTrans(&scx->scx_trans, transform, &tFinal);

  DBPolygonCopy(poly, Select2Def, &tFinal);

  return 0;
}


/* helper function to copy wirepath  
 * Always return 1 to keep the search alive. 
 */
static int
selTransWirePathFunc(WirePath *wp, 
		    SearchContext *scx, 
		    ClientData cdarg)
{
  Transform tFinal; 
  Transform *transform = (Transform *) cdarg;

  /* compute composite transform */
  GeoTransTrans(&scx->scx_trans, transform, &tFinal);

  DBWPathCopy(wp, Select2Def, &tFinal, NULL);

  return 0;
}

/* Search function to copy subcells.  Always return 1 to keep the
 * search alive.
 */

static int
selTransCellFunc(CellUse *selUse, 
		 CellUse *realUse, 
		 Transform *realTrans, 
		 TerminalPath *tPath,
		 Transform *transform)
                    		/* Use from selection. */
                     		/* Corresponding use from layout (used to
				 * get id). */
                         	/* Transform for realUse (ignored). */
                         	/* How to change coords of selUse before
				 * copying.
				 */
{
    CellUse  *newUse;
    Transform newTrans;

    newUse = DBCellNewUse(selUse->cu_def, (char *) realUse->cu_id);

    GeoTransTrans(&selUse->cu_transform, transform, &newTrans);
    DBCellUseSetArray(selUse, newUse);
    DBCellUseSetTrans(newUse, &newTrans);
    newUse->cu_expandMask = selUse->cu_expandMask;

    DBInstanceAdd(newUse, Select2Def, 0);

    return 0;
}

/* Search function to copy labels.  Return 0 always to avoid
 * aborting search.
 */

static int
selTransLabelFunc(Label *label, CellDef *cellDef, Transform *defTransform, TerminalPath *tPath, Transform *transform)
                 		/* Label to copy.  This points to label
				 * in cellDef.
				 */
                     		/* Definition containing label in layout. */
                            	/* Transform from cellDef to root. */
                         	/* How to modify coords before copying to
				 * Select2Def.
				 */
{
    Rect rootArea, finalArea;
    int rootPos, finalPos;

    GeoTransRect(defTransform, &label->lab_rect, &rootArea);
    rootPos = GeoTransPos(defTransform, label->lab_pos);
    GeoTransRect(transform, &rootArea, &finalArea);
    finalPos = GeoTransPos(transform, rootPos);
    (void) DBLabelAdd(Select2Def, 
		      &finalArea, 
		      finalPos, 
		      label->lab_text,
		      label->lab_type, 
		      label->lab_kind);
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * selTransTo2 --
 *
 * 	This local procedure makes a transformed copy of the selection
 *	in Select2Def, ignoring everything that's not in the edit cell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Select2Def gets modified to hold the transformed selection.
 *	Error messages get printed if the selection contains any
 *	non-edit material.
 *
 * ----------------------------------------------------------------------------
 */

static void
selTransTo2(Transform *transform)
                         	/* How to transform stuff before copying
				 * it to Select2Def.
				 */
{
    UndoDisable();
    DBCellClearContents(Select2Def);
    (void) SelEnumPaint(&DBAllButSpaceAndDRCBits, 
			TRUE,          /* edit cell only */
			(bool *) NULL,
			selTransPaintFunc, 
			selTransPolygonFunc,
			selTransWirePathFunc,
			(ClientData) transform);
    (void) SelEnumCells(TRUE, 
			(bool *) NULL, 
			(SearchContext *) NULL,
			(TerminalPath *) NULL,
			(TerminalPath *) NULL,
			selTransCellFunc, 
			(ClientData) transform);
    (void) SelEnumLabels(&DBAllTypeBits, 
			 TRUE, 
			 (bool *) NULL,
			 (TerminalPath *) NULL, /* don't bother with pathnames */
			 selTransLabelFunc, (ClientData) transform);
    DBChangedArea(Select2Def, NULL, NULL, 0);
    UndoEnable();
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectTransform --
 *
 * 	This procedure modifies the selection by transforming
 *	it geometrically.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection is modified and redisplayed.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectTransform(Transform *transform,
                         		/* How to displace the selection.
					 * The transform is in root (user-
					 * visible) coordinates.
					 */
		bool dupOK)
                                        /* If set allow identical instances
					 * on top of each other.
					 * (useful during interactive drag)
					 */
{
    /* Copy from SelectDef to Select2Def, transforming along the way. */
    selTransTo2(transform);

    /* Now just delete the selection and recreate it from Select2Def,
     * copying into the edit cell along the way.
     */
    SelectDelete("modified");
    selectAndCopy2(dupOK);
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectGroupTransfer --
 *
 * 	Copies selection to newGroup,
 *      Deletes parts of selection in the activeGroup.
 *      Leaves ActiveGroup as newGroup!
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection is modified and redisplayed.  
 *      The activeGroup is changed
 *
 * ----------------------------------------------------------------------------
 */

void
SelectGroupTransfer(Group *newGroup)
{
    /* Copy from SelectDef to Select2Def */
    selTransTo2(&GeoIdentityTransform);

    /* Delete selection */
    SelectDelete("modified");

    /* switch to new group */
    EditCellUse->cu_def->cd_activeGroup = newGroup;

    /* Copy to new group */
    selectAndCopy2(FALSE);
}

static int
selExpandFunc(CellUse *selUse, 
                    		/* Use from selection. */
	      CellUse *use, 
                 		/* Use to expand (in actual layout). */
	      Transform *transform, 
	      TerminalPath *tPath,
	      int mask)
             			/* Windows in which to expand. */
{
    if (use->cu_parent == NULL)
    {
	MsgErrorF("Can't unexpand root cell of window.\n");
	return 0;
    }

    /* Be sure to modify the expansion bit in the selection as well as
     * the one in the layout in order to keep them consistend.
     */

    if (DBIsExpand(use, mask))
    {
	DBExpand(selUse, mask, FALSE);
	DBExpand(use, mask, FALSE);
	DBChangedArea(use->cu_parent, 
		      &use->cu_bbox, 
		      (TileTypeBitMask *) NULL, 
		      DBCF_DISPLAY);
    }
    else
    {
	DBExpand(selUse, mask, TRUE);
	DBExpand(use, mask, TRUE);
	DBChangedArea(use->cu_parent, 
		      &use->cu_bbox, 
		      &DBAllButSpaceBits, 
		      DBCF_DISPLAY);
    }
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectExpand --
 *
 * 	Expand all of the selected cells that are unexpanded, and
 *	unexpand all of those that are expanded.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The contents of the selected cells will become visible or
 *	invisible on the display in the indicated window(s).
 *
 * ----------------------------------------------------------------------------
 */

void
SelectExpand(int mask)
             			/* Bits of this word indicate which
				 * windows the selected cells will be
				 * expanded in.
				 */
{
    (void) SelEnumCells(FALSE, 
			(bool *) NULL, 
			(SearchContext *) NULL,
			(TerminalPath *) NULL,
			(TerminalPath *) NULL,
			selExpandFunc, 
			(ClientData) mask);
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelInternals --
 *
 * 	Expand/unexpand selected cells.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The contents of the selected cells will become visible or
 *	invisible on the display.
 *
 * ----------------------------------------------------------------------------
 */

static int
selShowFunc(CellUse *selUse, 
                    		/* Use from selection. */
	    CellUse *use, 
                 		/* Use to expand (in actual layout). */
	    Transform *transform, 
	    TerminalPath *tPath,
                         	/* Not used. */
	    int mask)
             			/* Windows in which to expand. */
{
  /* if already expanded, just return */
  if (DBIsExpand(use, mask)) return 0;

  DBExpand(selUse, mask, TRUE);
  DBExpand(use, mask, TRUE);
  DBChangedArea(use->cu_parent, 
		&use->cu_bbox, 
		&DBAllButSpaceBits,
		DBCF_DISPLAY);
  return 0;
}

static int
selHideFunc(CellUse *selUse, 
                    		/* Use from selection. */
	    CellUse *use, 
                 		/* Use to expand (in actual layout). */
	    Transform *transform, 
	    TerminalPath *tPath,
                         	/* Not used. */
	    int mask)
             			/* Windows in which to expand. */
{
    if (use->cu_parent == NULL)
    {
	MsgErrorF("Can't unexpand root cell of window.\n");
	return 0;
    }

    /* if already unexpanded just return */
    if (!DBIsExpand(use, mask)) return 0;

    DBExpand(selUse, mask, FALSE);
    DBExpand(use, mask, FALSE);
    DBChangedArea(use->cu_parent, 
		  &use->cu_bbox, 
		  NULL,
		  DBCF_DISPLAY);
    return 0;
}

void
SelInternals(int mask, 
	     	/* Bits of this word indicate which
		 * windows the selected cells will be
		 * expanded/unexpanded in.
		 */
	     bool show)
                /* if set expand, else unexpand */
{
    SelEnumCells(FALSE, 
		 (bool *) NULL, 
		 (SearchContext *) NULL,
		 (TerminalPath *) NULL,
		 (TerminalPath *) NULL,
		 show? selShowFunc : selHideFunc, 
		 (ClientData) mask);
}

/* Search function for paint.  Just make many copies of the paint
 * into Select2Def.  Always return 0 to keep the search alive.
 */

static int
selArrayPFunc(Rect *rect, TileType type, ArrayInfo *arrayInfo)
               			/* Rectangle to be arrayed. */
                  		/* Type of tile. */
                         	/* How to array. */
{
    int y, nx, ny;
    Rect current;

    nx = arrayInfo->ar_xhi - arrayInfo->ar_xlo;
    if (nx < 0) nx = -nx;
    ny = arrayInfo->ar_yhi - arrayInfo->ar_ylo;
    if (ny < 0) ny = -ny;

    current = *rect;
    for ( ; nx >= 0; nx -= 1)
    {
	current.r_ybot = rect->r_ybot;
	current.r_ytop = rect->r_ytop;
	for (y = ny; y >= 0; y -= 1)
	{
	    DBPaint(Select2Def, &current, type);
	    current.r_ybot += arrayInfo->ar_ysep;
	    current.r_ytop += arrayInfo->ar_ysep;
	}
	current.r_xbot += arrayInfo->ar_xsep;
	current.r_xtop += arrayInfo->ar_xsep;
    }
    return 0;
}

/* Search function for polygons.  Just make many copies of the polygon
 * into Select2Def.  Always return 0 to keep the search alive.
 */

static int
selArrayPolygonFunc(Polygon *poly, 
		    SearchContext *scx,
		    ClientData cdarg)
{
  int nx, ny;
  int deltaX, deltaY;
  ArrayInfo *arrayInfo = (ArrayInfo *) cdarg;

  /* skip dependent polygons (part of wirepath) */
  if(poly->poly_wirePath) return 0;

  nx = arrayInfo->ar_xhi - arrayInfo->ar_xlo;
  if (nx < 0) nx = -nx;
  ny = arrayInfo->ar_yhi - arrayInfo->ar_ylo;
  if (ny < 0) ny = -ny;

  deltaX = 0;
  for ( ; nx >= 0; nx -= 1)
  {
    int y;
    Transform trans;

    deltaY = 0;
    for (y = ny; y >= 0; y -= 1)
    {
      GeoTranslateTrans(&scx->scx_trans, deltaX, deltaY, &trans);
      DBPolygonCopy(poly, Select2Def, &trans);
      deltaY += arrayInfo->ar_ysep;
    }
    deltaX += arrayInfo->ar_xsep;
  }

  return 0;
}


/* Search function for wirepaths.  Just make many copies of the wirepath
 * into Select2Def.  Always return 0 to keep the search alive.
 */
static int
selArrayWirePathFunc(WirePath *wp, 
		     SearchContext *scx,
		     ClientData cdarg)
{
  int nx, ny;
  int deltaX, deltaY;
  ArrayInfo *arrayInfo = (ArrayInfo *) cdarg;

  nx = arrayInfo->ar_xhi - arrayInfo->ar_xlo;
  if (nx < 0) nx = -nx;
  ny = arrayInfo->ar_yhi - arrayInfo->ar_ylo;
  if (ny < 0) ny = -ny;

  deltaX = 0;
  for ( ; nx >= 0; nx -= 1)
  {
    int y;
    Transform trans;

    deltaY = 0;
    for (y = ny; y >= 0; y -= 1)
    {
      GeoTranslateTrans(&scx->scx_trans, deltaX, deltaY, &trans);
      DBWPathCopy(wp, Select2Def, &trans, NULL);
      deltaY += arrayInfo->ar_ysep;
    }
    deltaX += arrayInfo->ar_xsep;
  }

  return 0;
}

/* Search function for cells.  Just make an arrayed copy of
 * each subcell found.
 */

    /* ARGSUSED */
static int
selArrayCFunc(CellUse *selUse, 
	      CellUse *use, 
	      Transform *transform, 
	      TerminalPath *tPath,
	      ArrayInfo *arrayInfo)
                    		/* Use from selection (not used). */
                 		/* Use to be copied and arrayed. */
                         	/* Transform from use->cu_def to root. */
                         	/* Array characteristics desired. */
{
    CellUse *newUse;
    Transform tinv, newTrans;
    Rect tmp, oldBbox;

    /* When creating a new use, try to re-use the id from the old
     * one.  Only create a new one if the old id can't be used.
     */

    newUse = DBCellNewUse(use->cu_def, (char *) use->cu_id);
    newUse->cu_expandMask = use->cu_expandMask;

    DBCellUseSetTrans(newUse, transform);
    GeoInvertTrans(transform, &tinv);
    DBMakeArray(newUse, &tinv, arrayInfo->ar_xlo,
	arrayInfo->ar_ylo, arrayInfo->ar_xhi, arrayInfo->ar_yhi,
	arrayInfo->ar_xsep, arrayInfo->ar_ysep);
    
    /* Set the array's transform so that its lower-left corner is in
     * the same place that it used to be.
     */
    
    GeoInvertTrans(&use->cu_transform, &tinv);
    GeoTransRect(&tinv, &use->cu_bbox, &tmp);
    GeoTransRect(transform, &tmp, &oldBbox);
    GeoTranslateTrans(&newUse->cu_transform,
	    oldBbox.r_xbot - newUse->cu_bbox.r_xbot,
	    oldBbox.r_ybot - newUse->cu_bbox.r_ybot,
	    &newTrans);
    DBCellUseSetTrans(newUse, &newTrans);

    DBInstanceAdd(newUse, Select2Def, 0);

    return 0;
}

/* Search function for labels.  Similar to paint search function. */

    /* ARGSUSED */
static int
selArrayLFunc(Label *label,  		/* Label to be copied and replicated. */
	      CellDef *def,		/* Definition containing label. */
	      Transform *transform,    	/* Transform from coords of def to root. */
	      TerminalPath *tPath,
	      ArrayInfo *arrayInfo)     /* How to replicate. */
{
    int y, nx, ny, rootPos;
    Rect original, current;

    nx = arrayInfo->ar_xhi - arrayInfo->ar_xlo;
    if (nx < 0) nx = -nx;
    ny = arrayInfo->ar_yhi - arrayInfo->ar_ylo;
    if (ny < 0) ny = -ny;

    GeoTransRect(transform, &label->lab_rect, &original);
    rootPos = GeoTransPos(transform, label->lab_pos);
    current = original;
    for ( ; nx >= 0; nx -= 1)
    {
	current.r_ybot = original.r_ybot;
	current.r_ytop = original.r_ytop;
	for (y = ny; y >= 0; y -= 1)
	{
	    DBLabelAdd(Select2Def, &current, rootPos, label->lab_text,
		       label->lab_type, label->lab_kind);
	    current.r_ybot += arrayInfo->ar_ysep;
	    current.r_ytop += arrayInfo->ar_ysep;
	}
	current.r_xbot += arrayInfo->ar_xsep;
	current.r_xtop += arrayInfo->ar_xsep;
    }
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectArray --
 *
 * 	Array everything in the selection.  Cells get turned into
 *	arrays, and paint and labels get replicated.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The edit cell is modified in a big way.  It's also redisplayed.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectArray(ArrayInfo *arrayInfo)
                         	/* Describes desired shape of array, all in
				 * root coordinates.
				 */
{
    /* The way arraying is done is similar to moving:  make an
     * arrayed copy of everything in Select2Def, then delete the
     * selection, then copy everything back from Select2Def and
     * select it.
     */
    
    UndoDisable();
    DBCellClearContents(Select2Def);
    (void) SelEnumPaint(&DBAllButSpaceAndDRCBits, 
			TRUE, 
			(bool *) NULL,
			selArrayPFunc, 
			selArrayPolygonFunc,
			selArrayWirePathFunc,
			(ClientData) arrayInfo);
    (void) SelEnumCells(TRUE, 
			(bool *) NULL, 
			(SearchContext *) NULL,
			(TerminalPath *) NULL,
			(TerminalPath *) NULL,
			selArrayCFunc, 
			(ClientData) arrayInfo);
    (void) SelEnumLabels(&DBAllTypeBits, 
			 TRUE, 
			 (bool *) NULL,
			 (TerminalPath *) NULL,  /* don't bother with pathnames */
			 selArrayLFunc, (ClientData) arrayInfo);
    DBChangedArea(Select2Def, NULL, NULL, 0);
    UndoEnable();

    /* Now just delete the selection and recreate it from Select2Def,
     * copying into the edit cell along the way.
     */
    
    SelectDelete("arrayed");
    selectAndCopy2(FALSE);
}

/*
 * ----------------------------------------------------------------------------
 *	selStretchEraseFunc --
 *
 * 	Called by DBPlaneEnumAreaPaint during stretching for each tile in the
 *	new selection.  Erase the area that the tile swept out as it
 *	moved.
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	The edit cell is modified.
 * ----------------------------------------------------------------------------
 */

static int
selStretchEraseFunc(Tile *tile)
               			/* Tile being moved in a stretch operation. */
{
    Rect area, editArea;
    TileType type;

    type = DBgetTileType(tile);

    TiToRect(tile, &area);

    /* Compute the area that this tile swept out (the current area is
     * its location AFTER moving), and erase everything that was in
     * its path.
     */

    if (selStretchX > 0)
	area.r_xbot -= selStretchX;
    else area.r_xtop -= selStretchX;
    if (selStretchY > 0)
	area.r_ybot -= selStretchY;
    else area.r_ytop -= selStretchY;

    /* Translate into edit coords and erase all material on the
     * tile's plane.
     */
    
    GeoTransRect(&RootToEditTransform, &area, &editArea);
    DBEraseMaskG(EditCellUse->cu_def, &editArea, &DBPlaneTypes[DBPlane(type)], selStretchGroup);

    return 0;
}

/* OK, now we've found a piece of material in the edit cell that is
 * right next to a piece of selected material that's about to move
 * away from it.  Stretch one or the other to fill the gap.  Use the
 * material that's moving as the stretch material unless it's a fixed-size
 * material and the other stuff is stretchable.
 */

static int
selStretchFillFunc3(Tile *tile, 
      		                /* Tile of edit material that's about to
				 * be left behind selection.
				 */
		    Rect *area)
               		        /* Border area we're interested in, in 
    				 * root coords.
				 */
{
    Rect editArea, rootArea;
    TileType type;
    register TileTypeBitMask *mask;
    StretchArea *sa;

    /* get type, and (if group set) filter out tiles not in active group */
    if(selStretchGroup)
    {
        type = DBgetTypeG(tile,EditCellUse->cu_def->cd_activeGroup);
	if (type == TT_SPACE) return 0;
    }
    else
    {
        type = DBgetTileType(tile);
    }

    /* Compute the area to be painted. */

    TiToRect(tile, &editArea);
    GeoTransRect(&EditToRootTransform, &editArea, &rootArea);
    GeoClip(&rootArea, area);
    if (selStretchX > 0)
    {
	rootArea.r_xbot = rootArea.r_xtop;
	rootArea.r_xtop += selStretchX;
    }
    else if (selStretchX < 0)
    {
	rootArea.r_xtop = rootArea.r_xbot;
	rootArea.r_xbot += selStretchX;
    }
    else if (selStretchY > 0)
    {
	rootArea.r_ybot = rootArea.r_ytop;
	rootArea.r_ytop += selStretchY;
    }
    else
    {
	rootArea.r_ytop = rootArea.r_ybot;
	rootArea.r_ybot += selStretchY;
    }
    GeoTransRect(&RootToEditTransform, &rootArea, &editArea);

    /* Save around the area we just found. */

    sa = (StretchArea *) mallocMagic(sizeof(StretchArea));
    sa->sa_area = editArea;
    sa->sa_type = type;
    sa->sa_next = selStretchList;
    selStretchList = sa;

    return 0;
}

/* Second-level filling search function:  find all of the edit material
 * that intersects areas where space borders a selected paint tile.
 */

static int
selStretchFillFunc2(Tile *tile, 
		    	/* Space tile that borders selected
			 * paint.
			 */
		    Rect *area)
                        /* A one-unit wide strip along the
			 * border (i.e. the area in which
			 * we're interested in space).
			 */
{
    Rect spaceArea, editArea;

    TiToRect(tile, &spaceArea);

    /* Find out which portion of this space tile borders the selected
     * tile, transform it back to coords of the old selection and then
     * to edit coords, and find all the edit material that borders the
     * selected tile in this area.
     */

    GeoClip(&spaceArea, area);
    spaceArea.r_xbot -= selStretchX;
    spaceArea.r_xtop -= selStretchX;
    spaceArea.r_ybot -= selStretchY;
    spaceArea.r_ytop -= selStretchY;
    GeoTransRect(&RootToEditTransform, &spaceArea, &editArea);

    (void) DBPlaneEnumAreaPaint((Tile *) NULL,
	    EditCellUse->cu_def->cd_planes[DBPlane(selStretchType)],
	    &editArea, &DBAllButSpaceAndDRCBits, selStretchFillFunc3,
	    (ClientData) &spaceArea);

    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *	selStretchFillFunc --
 *
 * 	This function is invoked during stretching for each paint tile in
 *	the (new) selection.  It finds places where the back-side of this
 *	tile borders space in the (new) selection, then looks for paint in
 *	the edit cell that borders the old location of the paint.  If the
 *	selection has been moved away from paint in the edit cell, additional
 *	material is filled in behind the selection.
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	Modifies the edit cell by painting material.
 * ----------------------------------------------------------------------------
 */

static int
selStretchFillFunc(Tile *tile)
               			/* Tile in the old selection. */
{
    Rect area;

    selStretchType = DBgetTileType(tile);
    TiToRect(tile, &area);

    /* Check the material just behind this paint (in the sense of the
     * stretch direction) for space in the selection and non-space in
     * the edit cell.
     */
    
    if (selStretchX > 0)
    {
	area.r_xtop = area.r_xbot;
	area.r_xbot -= 1;
    }
    else if (selStretchX < 0)
    {
	area.r_xbot = area.r_xtop;
	area.r_xtop += 1;
    }
    else if (selStretchY > 0)
    {
	area.r_ytop = area.r_ybot;
	area.r_ybot -= 1;
    }
    else
    {
	area.r_ybot = area.r_ytop;
	area.r_ytop += 1;
    }

    /* The search functions invoked indirectly by the following procedure
     * call build up a list of areas to paint.
     */

    (void) DBPlaneEnumAreaPaint((Tile *) NULL,
	    Select2Def->cd_planes[DBPlane(selStretchType)], &area,
	    &DBSpaceBits, selStretchFillFunc2, (ClientData) &area);
    
    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *	SelectStretch --
 *
 * 	Move the selection a given amount in x (or y).  While moving,
 *	erase everything that the selection passes over, and stretch
 *	material behind the selection.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The edit cell is modified.  The selection is also modified
 *	and redisplayed.
 * ----------------------------------------------------------------------------
 */

void
SelectStretch(int x, 	/* Amount to move in the x-direction. */
	      int y,    /* Amount to move in the y-direction.  Must
			 * be zero if x is non-zero.
			 */
	      bool group)  /* if set, don't erase or strectch material not in active group. */
{
    Transform transform;
    int plane;
    Rect modifiedArea, editModified;

    if ((x == 0) && (y == 0)) return;

    /* First of all, copy from SelectDef to Select2Def, moving the
     * selection along the way.
     */
    
    GeoTranslateTrans(&GeoIdentityTransform, x, y, &transform);
    selTransTo2(&transform);

    /* We're going to modify not just the old selection area or the new
     * one, but everything in-between too.  Remember this and tell the
     * displayer and DRC about it later.
     */

    modifiedArea = *DBBBoxCellDef(Select2Def);
    (void) GeoInclude(DBBBoxCellDef(SelectDef), &modifiedArea);
    GeoTransRect(&RootToEditTransform, &modifiedArea, &editModified);

    /* Delete the selection itself. */

    SelectDelete("stretched");

    /* Next, delete all the material in front of each piece of paint in
     * the selection.
     */
    
    selStretchGroup = group;
    selStretchX = x;
    selStretchY = y;
    for (plane = PL_SELECTBASE; plane < DBNumPlanes; plane += 1)
    {
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, Select2Def->cd_planes[plane],
		&TiPlaneRect, &DBAllButSpaceAndDRCBits, selStretchEraseFunc,
		(ClientData) NULL);
    }

    /* To achieve the stretch affect, fill in material behind the selection
     * everywhere that it used to touch other material in the edit cell.
     * This code first builds up a list of areas to paint, then paints them
     * (can't paint as we go because the new paint interacts with the
     * computation of what to stretch).
     */

    selStretchList = NULL;
    for (plane = PL_SELECTBASE; plane < DBNumPlanes; plane += 1)
    {
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, Select2Def->cd_planes[plane],
		&TiPlaneRect, &DBAllButSpaceAndDRCBits, selStretchFillFunc,
		(ClientData) NULL);
    }

    /* Paint back the areas in the list. */

    while (selStretchList != NULL)
    {
	DBPaint(EditCellUse->cu_def, &selStretchList->sa_area,
		selStretchList->sa_type);
	freeMagic((char *) selStretchList);
	selStretchList = selStretchList->sa_next;
    }

    /* Paint the new translated selection back into the edit cell,
     * select it again, and tell DRC and display about what we
     * changed.
     */
    
    selectAndCopy2(FALSE);

    /* process database change */
    DBChangedArea(EditCellUse->cu_def, &editModified, NULL, 0);
}



/*
 * ----------------------------------------------------------------------------
 *
 * SelectDump --
 *
 *      Copies an area of one cell into the edit cell, selecting the
 *	copy so that it can be manipulated later.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The edit cell is modified.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectDump(SearchContext *scx,
                       			/* Describes the cell from which
					 * material is to be copied, the
					 * area to copy, and the transform
					 * to root coordinates in the edit
					 * cell's window.
					 */
	   bool dupOK,
                                        /* allow exact copies of instances
					 * on top of each other.
					 */
	   char *instPrefix,            /* prefix to add to instance ids
					 * for all instances copied.
					 */
	   char *labPrefix)             /* prefix to add to label text for
					 * all labels copied.
					 */
{
    /* Copy from the source cell to Select2Def while transforming,
     * then let selectandCopy2 do the rest of the work.  Don't
     * record any of the Select2Def changes for undo-ing.
     */

    UndoDisable();
    DBCellClearContents(Select2Def);

    (void) DBCellCopyAllPaint(scx, 
			      &DBAllButSpaceAndDRCBits, 
			      -1, 
			      Select2Use);

    (void) DBCellCopyAllLabels(scx, 
			       &DBAllTypeBits, 
			       -1, 
			       Select2Use,
			       (Rect *) NULL,
			       labPrefix);

    (void) DBCellCopyAllCells(scx, 
			      -1, 
			      Select2Use, 
			      (Rect *) NULL, 
			      NULL,
			      FALSE,
			      instPrefix);

    DBChangedArea(Select2Def, NULL, NULL, 0);
    UndoEnable();

    SelectClear();
    selectAndCopy2(dupOK);
}
