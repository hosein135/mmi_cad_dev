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
 * DBcopy.c --
 *
 * Copying (yank and stuff)
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
static char rcsid[] = "$Header: DBcellcopy.c,v 6.0 90/08/28 18:09:32 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "memory.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "layout.h"
#include "layout.h"
#include "commands.h"

/*
 * The following variable points to the tables currently used for
 * painting.  The paint tables are occasionally switched, by clients
 * like the design-rule checker, by calling DBNewPaintTable.  This
 * paint table applies only to the routine in this module.
 */
static PaintResultType (*dbCurPaintTbl)[NT][NT] = DBPaintResultTbl;

/*
 * The following variable points to the version of DBPaintPlane used
 * for painting during yanks.  This is occasionally switched by clients
 * such as the design-rule checker that need to use, for example,
 * DBPaintPlaneMergeOnce instead of the standard version.
 */
static void (*dbCurPaintPlane)() = DBPaintPlane;

    /* Structure passed to DBSearchPaint() */
struct copyAllArg
{
    TileTypeBitMask	*caa_mask;	/* Mask of tile types to be copied */
    Rect		 caa_rect;	/* Clipping rect in target coords */
    CellUse		*caa_targetUse;	/* Use to which tiles are copied */
    Rect		*caa_bbox;	/* Bbox of material copied (in
					 * targetUse coords).  Used only when
					 * copying cells.
					 */
    char                *caa_prefix;    /* prefix to prepend to copied 
					 * instances.
					 */
};

    /* Structure passed to DBPlaneEnumAreaPaint() */
struct copyArg
{
    TileTypeBitMask	*ca_mask;	/* Mask of tile types to be copied */
    Rect		 ca_rect;	/* Clipping rect in source coords */
    CellUse		*ca_targetUse;	/* Use to which tiles are copied */
    Transform		*ca_trans;	/* Transform to target */
};

    /* Structure passed to DBSearchLabels to hold information about
     * copying labels.
     */

struct copyLabelArg
{
    CellUse *cla_targetUse;		/* Use to which labels are copied. */
    Rect *cla_bbox;			/* If non-NULL, points to rectangle
					 * to be filled in with total area of
					 * all labels copied.
					 */
    char *cla_prefix;                   /* If non-NULL, is prepended to label
					 * text of copied labels.
					 */
					   
};


/*
 *-----------------------------------------------------------------------------
 *
 * DBCopyPaint --
 *
 * Copy paint and polygons from scx->scx_use and descendents
 * to targetUse, transforming according to the transform in scx.
 *
 * Only the types specified by typeMask are copied.
 *
 * Flags:
 *     DBCP_NON_RECURSIVE - paint from top cell only.
 *     DBCP_ACTIVE_GROUP_ONLY - only copy active group.
 *     DBCP_NO_TILES - don't copy paint tiles. 
 *     DBCP_NO_POLY - don't copy polygons
 *     DBCP_NO_WP - don't copy wirepaths
 *
 *-----------------------------------------------------------------------------
 */

/* filter func */
static int dbCopyPaintFlags;
static int dbCopyPaintFunc(register Tile *tile, TreeContext *cxp)
{
    register SearchContext *scx = cxp->tc_scx;
    register struct copyAllArg *arg = (struct copyAllArg *) cxp->tc_filter->tf_arg;
    TileType type;
    Rect sourceRect, targetRect;
    PaintUndoInfo ui;
    CellDef *def;
    int pNum;

    /* get tile type */
    if(dbCopyPaintFlags&DBCP_ACTIVE_GROUP_ONLY)
    {
      type = DBgetTypeG(tile, cxp->tc_scx->scx_use->cu_def->cd_activeGroup);
    }
    else
    {
      type = DBgetTileType(tile);
    }

    /* Construct the rect for the tile in source coordinates */
    TITORECT(tile, &sourceRect);

    /* Transform to target coordinates */
    GEOTRANSRECT(&scx->scx_trans, &sourceRect, &targetRect);

    /* Clip against the target area */
    GEOCLIP(&targetRect, &arg->caa_rect);

    /* paint into target def, using current "copy" paint func and tables */
    pNum = DBPlane(type);
    ui.pu_def = def = arg->caa_targetUse->cu_def;
    ui.pu_pNum = pNum;
    (*dbCurPaintPlane)(def->cd_planes[pNum], 
		       &targetRect,
		       dbCurPaintTbl[pNum][type], 
		       &ui);

    return 0;
}
static int dbCopyPaintPolyFunc(SearchContext *scx,
			       Polygon *poly,
			       struct copyAllArg *arg)
{
  DBPolygonCopy(poly, arg->caa_targetUse->cu_def, &scx->scx_trans);
  return 0;
}

static int dbCopyPaintWPFunc(SearchContext *scx,
			     WirePath *wp,
			     struct copyAllArg *arg)
{
  DBWPathCopy(wp, arg->caa_targetUse->cu_def, &scx->scx_trans, NULL);
  return 0;
}

void
DBCopyPaint(SearchContext *scx, 
                       		/* Describes cell to search, area to
				 * copy, transform from cell to coords
				 * of targetUse.
				 */
	    TileTypeBitMask *mask, 
                          	/* Types of tiles to be yanked/stuffed */
	    int xMask, 
              			/* Expansion state mask to be used in search */
	    CellUse *targetUse,
                       		/* Cell into which material is to be stuffed */
	    int flags)
                                /* DBCP_*, see database.h for list */
{
    struct copyAllArg arg;
    int searchFlags = 0;

    /* flags */ 
    dbCopyPaintFlags = flags;
    if(flags&DBCP_NON_RECURSIVE) searchFlags |= DBSP_NON_RECURSIVE;
    if(flags&DBCP_ACTIVE_GROUP_ONLY) searchFlags |= DBSP_GROUP;

    /* setup copy all struct */
    arg.caa_mask = mask;
    arg.caa_targetUse = targetUse;
    GEOTRANSRECT(&scx->scx_trans, &scx->scx_area, &arg.caa_rect);

    /* call funcs on each matching tile, polygon, and wirepath */
    (void) DBSearchPaintNew(scx, 
			    mask,
			    xMask, 
			    (flags & DBCP_NO_TILES) ? NULL : dbCopyPaintFunc,
			    (flags & DBCP_NO_POLY) ? NULL : dbCopyPaintPolyFunc,
			    (flags & DBCP_NO_WP) ? NULL : dbCopyPaintWPFunc,
			    (ClientData) &arg,
			    searchFlags);
}



/*
 *-----------------------------------------------------------------------------
 *
 * DBCellCopyAllLabelsG --
 *
 * Copy labels from the tree rooted at scx->scx_use to targetUse,
 * transforming according to the transform in scx.  Only labels
 * attached to layers of the types specified by mask are copied.
 * The area to be copied is determined by GEO_LABEL_IN_AREA.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Copies labels to targetUse, clipping against scx->scx_area.
 *	If pArea is given, store in it the bounding box of all the
 *	labels copied.
 *
 *-----------------------------------------------------------------------------
 */

static int
dbCopyAllLabelsFunc(register SearchContext *scx, 
		register Label *lab, 
		TerminalPath *tpath, 
		struct copyLabelArg *arg)
{
    Rect labTargetRect;
    int targetPos;
    CellDef *def;
    char *prefix = arg->cla_prefix; 
    char buf[BUFSIZ];
    char *text;

    def = arg->cla_targetUse->cu_def;
    if (!GEO_LABEL_IN_AREA(&lab->lab_rect, &(scx->scx_area))) return 0;
    GeoTransRect(&scx->scx_trans, &lab->lab_rect, &labTargetRect);
    targetPos = GeoTransPos(&scx->scx_trans, lab->lab_pos);

    text = lab->lab_text;
    if(prefix)
    {
      sprintf(buf, "%s%s", prefix, text);
      text = buf;
    }

    (void) DBLabelAdd(def, 
		      &labTargetRect, 
		      targetPos,
		      text, 
		      lab->lab_type, 
		      lab->lab_kind);

    if (arg->cla_bbox != NULL)
	(void) GeoIncludeAll(&labTargetRect, arg->cla_bbox);
    return 0;
}

static int
dbCopyAllLabelsFuncG(register SearchContext *scx, register Label *lab, TerminalPath *tpath, struct copyLabelArg *arg)
{
    Rect labTargetRect;
    int targetPos;
    CellDef *def = arg->cla_targetUse->cu_def;
    char *prefix = arg->cla_prefix; 
    Group *group = scx->scx_use->cu_def->cd_activeGroup;
    char buf[BUFSIZ];
    char *text;

    if(lab->lab_group != group) return 0;

    if (!GEO_LABEL_IN_AREA(&lab->lab_rect, &(scx->scx_area))) return 0;
    GeoTransRect(&scx->scx_trans, &lab->lab_rect, &labTargetRect);
    targetPos = GeoTransPos(&scx->scx_trans, lab->lab_pos);

    text = lab->lab_text;
    if(prefix)
    {
      sprintf(buf, "%s%s", prefix, text);
      text = buf;
    }

    DBLabelAdd(def, 
	       &labTargetRect, 
	       targetPos,
	       text, 
	       lab->lab_type, 
	       lab->lab_kind);

    if (arg->cla_bbox != NULL)
	(void) GeoIncludeAll(&labTargetRect, arg->cla_bbox);
    return 0;
}

void
DBCellCopyAllLabelsG(SearchContext *scx, 
                       		/* Describes root cell to search, area to
				 * copy, transform from root cell to coords
				 * of targetUse.
				 */
		     TileTypeBitMask *mask, 
                          	/* Only labels of these types are copied */
		     int xMask, 
              			/* Expansion state mask to be used in search */
		     CellUse *targetUse, 
                       		/* Cell into which labels are to be stuffed */
		     Rect *pArea, 
                		/* If non-NULL, points to a box that will be
				 * filled in with bbox (in targetUse coords)
				 * of all labels copied.  Will be degenerate
				 * if nothing was copied.
				 */
		     bool activeGroupOnly,
		     char *prefix)
                                /* If non-null, is prepended to label
				 * text for all labels copied.
				 */
{
    struct copyLabelArg arg;

    /* DBTeeSrLabels finds all the labels that we want plus some more.
     * We'll filter out the ones that we don't need.
     */
    
    arg.cla_targetUse = targetUse;
    arg.cla_bbox = pArea;
    arg.cla_prefix = prefix;

    if (pArea != NULL)
    {
	pArea->r_xbot = 0;
	pArea->r_xtop = -1;
    }
    if(activeGroupOnly)
    {
        (void) DBSearchLabels(scx, mask, xMask, (TerminalPath *) 0,
			dbCopyAllLabelsFuncG, (ClientData) &arg);
    }
    else
    {
        (void) DBSearchLabels(scx, mask, xMask, (TerminalPath *) 0,
			dbCopyAllLabelsFunc, (ClientData) &arg);
    }
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBCellCopyAllLabels --
 *
 * Copy labels from the tree rooted at scx->scx_use to targetUse,
 * transforming according to the transform in scx.  Only labels
 * attached to layers of the types specified by mask are copied.
 * The area to be copied is determined by GEO_LABEL_IN_AREA.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Copies labels to targetUse, clipping against scx->scx_area.
 *	If pArea is given, store in it the bounding box of all the
 *	labels copied.
 *
 *-----------------------------------------------------------------------------
 */

void
DBCellCopyAllLabels(SearchContext *scx, 
                       		/* Describes root cell to search, area to
				 * copy, transform from root cell to coords
				 * of targetUse.
				 */
		    TileTypeBitMask *mask, 
                          	/* Only labels of these types are copied */
		    int xMask, 
              			/* Expansion state mask to be used in search */
		    CellUse *targetUse, 
                       		/* Cell into which labels are to be stuffed */
		    Rect *pArea,
                		/* If non-NULL, points to a box that will be
				 * filled in with bbox (in targetUse coords)
				 * of all labels copied.  Will be degenerate
				 * if nothing was copied.
				 */
		    char *prefix)
                                /* If non-null, is prepended to text of all
				 * labels copied.
				 */
{
    DBCellCopyAllLabelsG(scx, mask, xMask, targetUse, pArea, FALSE, prefix);
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBCellCopyLabelsG --
 *
 * Copy labels from scx->scx_use to targetUse, transforming according to
 * the transform in scx.  Only labels attached to layers of the types
 * specified by mask are copied.  If mask contains the L_LABEL bit, then
 * all labels are copied regardless of their layer.  The area copied is 
 * determined by GEO_LABEL_IN_AREA.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the labels in targetUse.  If pArea is given, it will
 *	be filled in with the bounding box of all labels copied.
 *
 *-----------------------------------------------------------------------------
 */

void
DBCellCopyLabelsG(SearchContext *scx, 
                       		/* Describes root cell to search, area to
				 * copy, transform from root cell to coords
				 * of targetUse.
				 */
		  TileTypeBitMask *mask, 
                          	/* Only labels of these types are copied */
		  int xMask, 
              			/* Expansion state mask to be used in search */
		  CellUse *targetUse, 
                       		/* Cell into which labels are to be stuffed */
		  Rect *pArea,
                		/* If non-NULL, points to rectangle to be
				 * filled in with bbox (in targetUse coords)
				 * of all labels copied.  Will be degenerate
				 * if no labels are copied.
				 */
		  bool activeGroupOnly)
                                /* If set, copy active group only */
{
    register Label *lab;
    CellDef *def = targetUse->cu_def;
    Rect labTargetRect;
    Rect *rect = &scx->scx_area;
    int targetPos;
    CellUse *sourceUse = scx->scx_use;
    Group *group = sourceUse->cu_def->cd_activeGroup;

    if (pArea != NULL)
    {
	pArea->r_xbot = 0;
	pArea->r_xtop = -1;
    }

    if (!DBIsExpand(sourceUse, xMask))
	return;

    for (lab = sourceUse->cu_def->cd_labels; lab; lab = lab->lab_next)
	if (GEO_LABEL_IN_AREA(&lab->lab_rect, rect) &&
		(TTMaskHasType(mask, lab->lab_type)
		|| TTMaskHasType(mask, L_LABEL)))
	{
	    if(activeGroupOnly && lab->lab_group != group) continue;

	    GeoTransRect(&scx->scx_trans, &lab->lab_rect, &labTargetRect);
	    targetPos = GeoTransPos(&scx->scx_trans, lab->lab_pos);

	    DBLabelAdd(def, &labTargetRect, targetPos,
		    lab->lab_text, lab->lab_type, lab->lab_kind);
	    if (pArea != NULL)
		(void) GeoIncludeAll(&labTargetRect, pArea);
	}
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBCellCopyLabels --
 *
 * Copy labels from scx->scx_use to targetUse, transforming according to
 * the transform in scx.  Only labels attached to layers of the types
 * specified by mask are copied.  If mask contains the L_LABEL bit, then
 * all labels are copied regardless of their layer.  The area copied is 
 * determined by GEO_LABEL_IN_AREA.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the labels in targetUse.  If pArea is given, it will
 *	be filled in with the bounding box of all labels copied.
 *
 *-----------------------------------------------------------------------------
 */

void
DBCellCopyLabels(SearchContext *scx, TileTypeBitMask *mask, int xMask, CellUse *targetUse, Rect *pArea)
                       		/* Describes root cell to search, area to
				 * copy, transform from root cell to coords
				 * of targetUse.
				 */
                          	/* Only labels of these types are copied */
              			/* Expansion state mask to be used in search */
                       		/* Cell into which labels are to be stuffed */
                		/* If non-NULL, points to rectangle to be
				 * filled in with bbox (in targetUse coords)
				 * of all labels copied.  Will be degenerate
				 * if no labels are copied.
				 */
{
    DBCellCopyLabelsG(scx, mask, xMask, targetUse, pArea, FALSE);
}

/*
 *-----------------------------------------------------------------------------
 *
 * dbCellCopyCellsFunc --
 *
 * Do the actual work of yanking cells for DBCellCopyAllCells() and
 * DBCellCopyCells() above.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the cell plane in arg->caa_targetUse->cu_def.
 *
 *-----------------------------------------------------------------------------
 */
static bool dbCellCopyCellsFlags;  /* flags to pass to DBInstanceAdd() */
static CellUse **dbCellCopyCellsListP;  /* if non-null, make list of new uses */
static int
dbCellCopyCellsFunc(register SearchContext *scx, 
                                	/* Pointer to search context containing
					 * ptr to cell use to be copied,
					 * and transform to the target def.
					 */
		    register struct copyAllArg *arg)
                                    	/* Client data from caller */
{
    CellUse *use = scx->scx_use;
    CellDef *def = use->cu_def;
    CellUse *newUse;
    Transform newTrans;
    char *id;


    /* When creating a new use, try to re-use the id from the old
     * one.  Only create a new one if the old id can't be used.
     */
    {
      char *prefix = arg->caa_prefix;
      char buf[BUFSIZ];
      
      id = use->cu_id;
      if(prefix)
      {
	sprintf(buf, "%s%s", prefix, id);
	id = buf;
      }
    }


    /* The translation stuff is funny, since we got one element of
     * the array, but not necessarily the lower-left element.  To
     * get the transform for the array as a whole, subtract off fo
     * the index of the element.  The easiest way to see how this
     * works is to look at the code in dbCellSrFunc;  the stuff here
     * is the opposite.
     */

    if(!DBIsArray(use))
    {
      newTrans = scx->scx_trans;
    }
    else
    {
      int xsep, ysep, xbase, ybase;

      if (use->cu_xlo > use->cu_xhi) xsep = -use->cu_xsep;
      else xsep = use->cu_xsep;
      
      if (use->cu_ylo > use->cu_yhi) ysep = -use->cu_ysep;
      else ysep = use->cu_ysep;

      xbase = xsep * (scx->scx_x - use->cu_xlo);
      ybase = ysep * (scx->scx_y - use->cu_ylo);

      GeoTransTranslate(-xbase, -ybase, &scx->scx_trans, &newTrans);
    }

    newUse = DBCellUseNewCopy(use,id,&newTrans);

    if(DBInstanceAdd(newUse, 
		     arg->caa_targetUse->cu_def, 
                     dbCellCopyCellsFlags))
    {
	/* ok and necessary to use cu_bbox directly 
	 *  here (set by DBCellUseSetTrans() above).
	 * since havn't called DBChangedArea() yet!
	 */
	if (arg->caa_bbox != NULL)
	    (void) GeoIncludeAll(&newUse->cu_bbox, arg->caa_bbox);
	
	/* add to list of new uses */
	if(dbCellCopyCellsListP)
	{
	  newUse->cu_client = (ClientData) *dbCellCopyCellsListP;
	  *dbCellCopyCellsListP = newUse;
	}
    }
    return 2;
}

/*
 *-----------------------------------------------------------------------------
 *
 * DBCellCopyAllCells --
 *
 * Copy unexpanded subcells from the tree rooted at scx->scx_use
 * to the subcell plane of targetUse, transforming according to
 * the transform in scx.
 *
 * This effectively "flattens" a cell hierarchy in the sense that
 * all unexpanded subcells in a region (which would appear in the
 * display as bounding boxes) are copied into targetUse without
 * regard for their original location in the hierarchy of scx->scx_use.
 * If an array is unexpanded, it is copied as an array, not as a
 * collection of individual cells.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the cell plane in targetUse.  If pArea is given, it
 *	will be filled in with the total area of all cells copied.
 *
 *-----------------------------------------------------------------------------
 */

void
DBCellCopyAllCells(SearchContext *scx, 
                       		/* Describes root cell to search, area to
				 * copy, transform from root cell to coords
				 * of targetUse.
				 */
		   int xMask, 
              			/* Expansion state mask to be used in
				 * searching.  Cells not expanded according
				 * to this mask are copied.  To inhibit hier.
				 * use -1
				 */
		   CellUse *targetUse, 
                       		/* Cell into which material is to be stuffed */
		   Rect *pArea,
                		/* If non-NULL, points to a rectangle to be
				 * filled in with bbox (in targetUse coords)
				 * of all cells copied.  Will be degenerate
				 * if nothing was copied.
				 */

		   CellUse **listp,
		                /* If non-null, do cu_client linked list
				 * of the new uses.
				 *
				 * NOTE: up to caller to reset the cd_client
				 * fields to 0.
				 */
		   bool dupOK,
                                /* If set, allow identical instances to
				 * be placed on top of each other
				 * (useful during interactive drag)
				 */
		   char *prefix)
                                /* If non-null prepend to instance names
				 * of copied instances.
				 */
{
    struct copyAllArg arg;

    arg.caa_targetUse = targetUse;
    arg.caa_bbox = pArea;
    arg.caa_prefix = prefix;

    /* initialize list */
    if(listp) *listp = NULL;

    /* set globals for func */
    dbCellCopyCellsListP = listp;
    dbCellCopyCellsFlags = dupOK ? DBIA_DUP_OK : DBIA_INFOMSG_ON_DUP;

    if (pArea != NULL)
    {
	pArea->r_xbot = 0;		/* Make bounding box empty initially. */
	pArea->r_xtop = -1;
    }
    GeoTransRect(&scx->scx_trans, &scx->scx_area, &arg.caa_rect);

    (void) DBSearchInstances(scx, xMask, dbCellCopyCellsFunc, (ClientData) &arg);
}

/*
 *-----------------------------------------------------------------------------
 *
 * DBCellCopyCells --
 *
 * Copy all subcells that are immediate children of scx->scx_use->cu_def
 * into the subcell plane of targetUse, transforming according to
 * the transform in scx.  Arrays are copied as arrays, not as a
 * collection of individual cells.  If a cell is already present in
 * targetUse that would be exactly duplicated by a new cell, the new
 * cell isn't copied.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the cell plane in targetUse.  If pArea is given, it will
 *	be filled in with the bounding box of all cells copied.
 *
 *-----------------------------------------------------------------------------
 */

void
DBCellCopyCells(SearchContext *scx, 
            	  		/* Describes root cell to search, area to
				 * copy, transform from coords of
				 * scx->scx_use->cu_def to coords of targetUse.
				 */
		CellUse *targetUse, 
                       		/* Cell into which material is to be stuffed */
		Rect *pArea)
                		/* If non-NULL, points to rectangle to be
				 * filled in with bbox (in targetUse coords)
				 * of all cells copied.  Will be degenerate
				 * if nothing was copied.
				 */                

{
    struct copyAllArg arg;

    dbCellCopyCellsFlags = DBIA_INFOMSG_ON_DUP;
    dbCellCopyCellsListP = NULL;  /* not used */

    arg.caa_targetUse = targetUse;
    arg.caa_bbox = pArea;
    arg.caa_prefix = NULL; /* not used */

    if (pArea != NULL)
    {
	pArea->r_xbot = 0;
	pArea->r_xtop = -1;
    }
    GeoTransRect(&scx->scx_trans, &scx->scx_area, &arg.caa_rect);

    (void) DBSrChildren(scx, dbCellCopyCellsFunc, (ClientData) &arg);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBNewPaintTable --
 *
 * 	This procedure changes the paint table to be used by 
 *	DBCopyPaint()
 *
 * Results:
 *	The return value is the address of the paint table that used
 *	to be in effect.  It is up to the client to restore this
 *	value with another call to this procedure.
 *
 * Side effects:
 *	A new paint table takes effect.
 *
 * ----------------------------------------------------------------------------
 */

PaintResultType (*
DBNewPaintTable(newTable))[NT][NT]
    PaintResultType (*newTable)[NT][NT];  /* Address of new paint table. */
{
    PaintResultType (*oldTable)[NT][NT] = dbCurPaintTbl;
    dbCurPaintTbl = newTable;
    return oldTable;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBNewPaintPlane --
 *
 * 	This procedure changes the painting procedure to be used by the
 *	DBCellCopyPaint and DBCellCopyAllPaint procedures.
 *
 * Results:
 *	The return value is the address of the paint procedure that
 *	used to be in effect.  It is up to the client to restore this
 *	value with another call to this procedure.
 *
 * Side effects:
 *	A new paint procedure takes effect.
 *
 * ----------------------------------------------------------------------------
 */

VoidProc
DBNewPaintPlane(void (*newProc) (/* ??? */))
                      		/* Address of new procedure */
{
    void (*oldProc)() = dbCurPaintPlane;
    dbCurPaintPlane = newProc;
    return (oldProc);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellCopyDefNotify --
 *
 * Copies the contents of the source cell def to the destination cell def.
 * Does not clear the dest def first!
 *
 * NOTE: does db change notification.
 *
 * ----------------------------------------------------------------------------
 */

/* clientdata struct for paint func */
struct paintFuncArg
{
  Plane	     *fa_plane;        /* plane to paint into */
  PaintResultType  *fa_pTable; /* paint table (preindexed by plane num) */
  PaintUndoInfo fa_ui;
  Transform *fa_trans;
};

/* filter func, paints single tile */
static int
dbCellCopyDefPaintFunc(Tile *tile, ClientData cdarg)
{
    Rect tmp, rect;
    struct paintFuncArg *fa = (struct paintFuncArg *) cdarg;
    TileType type = DBgetTileType(tile);
    TiToRect(tile,&tmp);

    GEOTRANSRECT(fa->fa_trans, &tmp, &rect);
    
    DBPaintPlane(fa->fa_plane, 
		 &rect, 
		 &fa->fa_pTable[type*NT], 
		 &fa->fa_ui);
    /* continue search */
    return 0;
}

/* filter func for properties */
CellDef *dbCellCopyDestDef; 
static void
dbCellCopyPropFunc(char *name, char *value)
{
  DBPropSet(dbCellCopyDestDef, name, value);
}
 
void
DBCellCopyDefNotify(CellDef *srcDef, 
		    CellDef *destDef, 
		    Transform *trans)  /* if not null, transform while copying. */
{
  CellUse srcUse;
  CellUse destUse;

  /* default to identity transform */
  if(!trans) trans = &GeoIdentityTransform;

  /* need uses as handles (for scx etc) */
  DBCellUseNewTemp(srcDef,&srcUse);
  DBCellUseNewTemp(destDef,&destUse);

  /* copy labels */
  {
    Label *lab;

    for (lab = srcDef->cd_labels; lab; lab = lab->lab_next)
    {
      Rect rect;
      int pos;

      /* transform rect and pos */
      GEOTRANSRECT(trans, &lab->lab_rect,&rect);
      pos = GeoTransPos(trans, lab->lab_pos);
      (void) DBLabelAdd(destDef, 
			&rect, 
			pos,
			lab->lab_text, 
			lab->lab_type, 
			lab->lab_kind);
    }
  }

  /* copy paint 
   * TODO:  eventually, make group aware!
   */
  {
    struct paintFuncArg fa;
    int pNum;

    fa.fa_ui.pu_def = destDef;
    fa.fa_trans = trans;

    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
      fa.fa_ui.pu_pNum = pNum;
      fa.fa_plane = destDef->cd_planes[pNum];
      fa.fa_pTable = &DBPaintResultTbl[pNum][0][0];

      if (DBPlaneEnumAreaPaint((Tile *) NULL, 
			  srcDef->cd_planes[pNum],
			  &TiPlaneRect, 
			  &DBAllButSpaceAndDRCBits, 
			  dbCellCopyDefPaintFunc, 
			  (ClientData) &fa))
      {
         MsgErrorF("Cell copy incomplete!\n");
         return;
      }
    }
  }

  /* copy all-angle geometry */
  DBPolygonsCopy(srcDef,destDef,trans);
  DBWPathsCopy(srcDef,destDef,trans);

  /* copy cell instances */
  {
    SearchContext scx;

    scx.scx_use = &srcUse;
    scx.scx_x = 0; 
    scx.scx_y = 0;
    scx.scx_area = *DBBBoxCellDef(srcDef);
    scx.scx_trans = *trans;

    DBCellCopyCells(&scx, &destUse, NULL);
  }

  /* copy properties */
  {
    dbCellCopyDestDef = destDef;
    DBPropEnum(srcDef, dbCellCopyPropFunc);
  }

  /* do change notification (needed before copy flylines below) */
  {
    Rect modified;
    GeoTransRect(trans, DBBBoxCellDef(srcDef), &modified);
    DBChangedArea(destDef, &modified, NULL, 0);
  }
  
  /* copy flylines */
  dbFlyLinesCopy(srcDef,destDef);


}


