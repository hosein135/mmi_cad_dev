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



/* selCreate.c -
 *
 *	This file provides routines to make selections by copying
 *	things into a special cell named "__SELECT__".
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
static char rcsid[]="$Header: selCreate.c,v 6.0 90/08/28 18:56:34 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <tcl.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "undo.h"
#include "commands.h"
#include "select.h"
#include "selInt.h"
#include "drc.h"
#include "main.h"
#include "signals.h"
#include "layout.h"

/* Two cells worth of information are kept around by the selection
 * module.  SelectDef and SelectUse are for the cells whose contents
 * are the current selection.  Select2Def and Select2Use provide a
 * temporary working space for procedures that manipulate the selection.
 * for example, Select2Def is used to hold nets or regions while they
 * are being extracted by SelectRegion or SelectNet.  Once completely
 * extracted, information is copied to SelectDef.  Changes to
 * SelectDef are undo-able and redo-able (so that the undo package
 * can deal with selection changes), but changes to Select2Def are
 * not undo-able (undoing is always disabled when the cell is modified).
 */

global CellDef *SelectDef, *Select2Def;
global CellUse *SelectUse, *Select2Use;

/* The CellDef below points to the definition FROM which the selection
 * is extracted.  This is the root definition of a window.  Everything
 * in the selection must have come from the same place, so we clear the
 * selection whenever the user tries to select from a new hierarchy.
 */

CellDef *SelectRootDef = NULL;

/* The CellUse below is the last use selected by SelectUse.  It is
 * kept around to support the "replace" feature of SelectUse.
 *
 * Procedures which deselect a cell must reset this to null if they
 * happen to deselect this usage.  (Danger Will Robinson)
 */

global CellUse *selectLastUse = NULL;

/*
 * ----------------------------------------------------------------------------
 *
 * SelectInit --
 *
 * 	Non-technology dependent intialization of selection stuff.
 *       
 * Results:
 *	None.
 *
 * Side effects:
 *	The select cells are created if they don't already exist.
 *	Selection undo-ing is also initialized.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectInit()
{
    static bool initialized = FALSE;

    if (initialized) return;
    else initialized = TRUE;

    /* Create the working cells used internally to this module to
     * hold selected information.  Don't allow any of this to be
     * undone, or else it could invalidate all the pointers we
     * keep around to the cells.
     */

    UndoDisable();

    SelectDef = DBCellLookDef("__SELECT__");
    if (!SelectDef) 
    {
      DBNewYank("__SELECT__", &SelectUse, &SelectDef);
    }

    Select2Def = DBCellLookDef("__SELECT2__");
    if (!Select2Def)
    {
      DBNewYank("__SELECT2__", &Select2Use, &Select2Def);
    }

    UndoEnable();
    SelUndoInit();
}

/*
 * ----------------------------------------------------------------------------
 *
 * SelectClear --
 *
 * 	This procedure clears the current selection.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All information is removed from the select cell, and selection
 *	information is also taken off the screen.
 *
 * ----------------------------------------------------------------------------
 */

/* The variables below are used to record information about subcells that
 * must be cleared from the select cell.
 */

#define MAXUSES 30
static CellUse *(selDeleteUses[MAXUSES]);
static int selNDelete;

void
SelectClear(void)
{
    SearchContext scx;
    extern int selClearFunc(SearchContext *scx);		/* Forward declaration. */

    if (SelectRootDef == NULL) return;

    /* if no undo for selection, do the fast and easy way! */
    if(!SelUndo) 
    {
      Rect bbox = *DBBBoxCellDef(SelectDef);

      /* clear selection */
      DBCellClearContents(SelectDef); 

      /* notifications */
      LayChangedDefSelection(SelectRootDef, &bbox, TRUE);
      DBChangedArea(SelectDef, NULL, NULL, 0);
      
      return;
    }
       
    scx.scx_area = *DBBBoxCellDef(SelectDef);
    selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);

    /* Erase all the paint from the select cell. */
    DBEraseMask(SelectDef, &TiPlaneRect, &DBAllButSpaceBits);

    /* Erase all of the labels from the select cell. */
    DBLabelsClear(SelectDef);

    /* Erase all polygons from the select cell. */
    DBPolyClear(SelectDef);

    /* Erase all wirepaths from the select cell. */
    DBWPathsClear(SelectDef);

    /* Erase all of the subcells from the select cell.  This is a bit tricky,
     * because we can't erase the subcells while searching for them (it will
     * cause problems for the database).  The code below first grabs up a
     * few subcells, then deletes them, then grabs up a few more, then deletes
     * them, and so on until done.
     */

    scx.scx_use = SelectUse;
    scx.scx_trans = GeoIdentityTransform;
    while (TRUE)
    {
	int i;

	selNDelete = 0;
	(void) DBSrChildren(&scx, selClearFunc, (ClientData) NULL);
	for (i = 0; i < selNDelete; i += 1)
	{
	  DBInstanceDelete(selDeleteUses[i]);
	}
	if (selNDelete < MAXUSES) break;
    }

    selectLastUse = NULL;

    /* Erase the selection from the screen. */

    selUndoBracket(FALSE, SelectRootDef, &scx.scx_area);
    LayChangedDefSelection(SelectRootDef, &scx.scx_area, TRUE);
    DBChangedArea(SelectDef, NULL, NULL, 0);
}

/* Search function to help clear subcells from the selection.  It just
 * records information about several subcells (up to MAXUSES).
 */

int
selClearFunc(SearchContext *scx)
                       		/* Describes a cell that was found. */
{
    selDeleteUses[selNDelete] = scx->scx_use;
    selNDelete += 1;
    if (selNDelete == MAXUSES) return 1;
    else return 2;
}

/*
 * ----------------------------------------------------------------------------
 *
 * SelectArea --
 *
 * 	This procedure selects all information of given types that
 *	falls in a given area.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The indicated information is added to the select cell, and
 *	outlined on the screen.  Only information of particular
 *	types, and in expanded cells (according to xMask) is
 *	selected.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectArea(SearchContext *scx,  /* Describes the area in which material
				 * is to be selected.  The resulting
				 * coordinates should map to the coordinates
				 * of EditRootDef.  The cell use should be
				 * the root of a window, unless noTreeRootUse 
				 * is non-null.
				 */
	   TileTypeBitMask *types, /* Indicates which layers to select.  Can
				    * include L_CELL and L_LABELS to select
				    * labels and unexpanded subcells.  
				    * If L_LABELS
				    * is specified then all labels touching the
				    * area are selected.  If L_LABELS isn't
				    * specified, then only labels attached to
				    * selected material are selected.
				    */
	   int xMask,		/* Indicates window (or windows) where cells
				 * must be expanded for their contents to be
				 * considered.  0 means treat everything as
				 * expanded.
				 */
	   int flags,           /* see SA_* in select.h */
	   CellUse *noTreeRootUse) /* if non-null search only "toplevel"
				    * cell in scx.
				    */
{
    Rect labelArea, cellArea;
    CellUse *rootUse = scx->scx_use;
    bool activeGroupOnly = flags & SA_GROUP;

    if(noTreeRootUse) rootUse = noTreeRootUse;

    /* If the source definition is changing, clear the old selection. */
    if (SelectRootDef != rootUse->cu_def)
    {
	if (SelectRootDef != NULL)  SelectClear();
	SelectRootDef = rootUse->cu_def;
    }

    selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);

    /* Select paint. */
    {
      int dbcpFlags;
      
      /* setup copy flags */
      dbcpFlags = 0;
      if(noTreeRootUse) dbcpFlags |= DBCP_NON_RECURSIVE;
      if(activeGroupOnly) dbcpFlags |= DBCP_ACTIVE_GROUP_ONLY;
      if(flags & SA_NO_TILES)  dbcpFlags |= DBCP_NO_TILES;
      if(flags & SA_NO_POLY)  dbcpFlags |= DBCP_NO_POLY;
      if(flags & SA_NO_WP)  dbcpFlags |= DBCP_NO_WP;
	
      /* do the copy */
      DBCopyPaint(scx,
		  types,
		  xMask,
		  SelectUse,
		  dbcpFlags);
    }

    /* Select labels. */
    if(!(flags & SA_NO_LABELS))
    {
        TileTypeBitMask *mask = types;
	

        if (TTMaskHasType(types, L_LABEL)) mask = &DBAllTypeBits;
      
        if(noTreeRootUse)
        {
            (void) DBCellCopyLabelsG(scx, 
				     mask, 
				     xMask,
				     SelectUse, 
				     &labelArea, 
				     activeGroupOnly);
	}
        else 
        {
            (void) DBCellCopyAllLabelsG(scx, 
					mask, 
					xMask, 
					SelectUse, 
					&labelArea, 
					activeGroupOnly,
					(char *) NULL);
        }
    }

    /* Select unexpanded cell uses. */
    if (TTMaskHasType(types, L_CELL))
    {
        if(noTreeRootUse)
        {
            (void) DBCellCopyCells(scx, SelectUse, &cellArea);
        }
        else
        {
            (void) DBCellCopyAllCells(scx, 
				      xMask, 
				      SelectUse, 
				      &cellArea, 
				      NULL,
				      FALSE,
				      (char *) NULL);
        }
    }
    else
    {
	cellArea.r_xbot = 0;
	cellArea.r_xtop = -1;
    }

    /* Notifiy redisplay and undo */
    {
       Rect modified;

       /* compute modified area */
       GeoTransRect(&scx->scx_trans,&scx->scx_area, &modified);
       (void) GeoIncludeAll(&labelArea, &modified);
       (void) GeoIncludeAll(&cellArea, &modified);

       selUndoBracket(FALSE, SelectRootDef, &modified);
       LayChangedDefSelection(SelectRootDef, &modified, TRUE);
       DBChangedArea(SelectDef, &modified, &DBAllButSpaceBits, 0);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectBuffer --
 *
 * 	This procedure selects all information in buffer.
 *
 * NOTE:  Currently DOES NOT CHECK that info actually exists in
 *        current source tree!
 *  
 * Results:
 *	None.
 *
 * Side effects:
 *	The indicated information is added to the select cell, and
 *	outlined on the screen.  
 *
 * ----------------------------------------------------------------------------
 */

void
SelectBuffer(CellDef *buffer, /* add contents of buffer to selection */
	     CellDef *selRoot)   /* cell hierarchy selection is to apply to */
{

  /* If the source definition is changing, clear the old selection. */
  if (SelectRootDef != selRoot)
  {
    if (SelectRootDef != NULL)  SelectClear();
    SelectRootDef = selRoot;
  }

  selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);

  DBCellCopyDefNotify(buffer, SelectDef, &GeoIdentityTransform);

  /* Notifiy redisplay and undo */
  {
    Rect *modified = DBBBoxCellDef(buffer);
    
    selUndoBracket(FALSE, SelectRootDef, modified);
    LayChangedDefSelection(SelectRootDef, modified, TRUE);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * selGetLabels --
 *
 * 	This is a local procedure used to extract all the labels
 *	associated with the paint in Select2Def.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Labels are added to SelectDef for all labels in the hierarchy
 *	under rootUse that are visible (according to xMask), and
 *	for which there is connected material in Select2Def.
 *
 * ----------------------------------------------------------------------------
 */

void
selGetLabels(CellUse *rootUse, 
        	        /* Hierarchy to search for visible labels. */
	     int xMask)
             
              		/* Indicates windows where cells must be expanded
			 * in order for their labels to be copied.
			 */
{
    SearchContext scx;

    /* This procedure duplicates much of the code of DBSearchLabels.
     * However, it is much more efficient in some cases because it
     * only checks a subtree if Select2Def contains some paint in
     * the area of the subtree.  If a very large L-shaped net has
     * been selected, this could drastically reduce the amount of
     * searching that must be done to find labels.
     */
    
    scx.scx_use = rootUse;
    scx.scx_area = *DBBBoxCellDef(Select2Def);
    scx.scx_trans = GeoIdentityTransform;

    /* make sure we are all up-to-date, including scx_use->cu_bbox */
    (void) DBBBoxCellUse(scx.scx_use);

    (void) selLabelCellFunc(&scx, xMask);
}

/* The procedure below does all the work of getting labels.  It's
 * called from above, and also indirectly by itself, through
 * DBSrChildren.
 */

int
selLabelCellFunc(SearchContext *scx, int xMask)
                       		/* Area and cell we're currently searching. */
              			/* Indicates window where cell must be
				 * expanded.
				 */
{
    Label *lab;
    CellDef *def;
    int i;
    Rect rootArea;
    extern int selLabelPaintFunc(void);

    /* No point in checking this cell, its children, or its siblings
     * in an array if it isn't expanded.
     */

    if (!DBIsExpand(scx->scx_use, xMask)) return 2;

    /* Make sure that there's some material in Select2Def under
     * the area we're searching.  Otherwise there's no point
     * in checking for labels.
     */
    
    def = scx->scx_use->cu_def;
    GeoTransRect(&scx->scx_trans, DBBBoxCellDef(def), &rootArea);
    for (i = PL_SELECTBASE; i < DBNumPlanes; i += 1)
    {
	if (DBPlaneEnumAreaPaint((Tile *) NULL, Select2Def->cd_planes[i], &rootArea,
	    &DBAllButSpaceAndDRCBits, selLabelPaintFunc,
	    (ClientData) NULL) != 0) goto checkCell;
    }
    return 0;

    checkCell:

    /* Make sure that the cell is in memory. */
    if (!DBReadCell(def)) return 2;

    /* For each label in the cell, see if there is connected paint
     * in Select2Def.  If so, add the label to SelectDef.  Ignore
     * space labels here, since they can't possibly be connected
     * to anything.
     */

    for (lab = def->cd_labels; lab != NULL; lab = lab->lab_next)
    {
	Rect area, searchArea;
	int newPos;

	if (lab->lab_type == TT_SPACE) continue;
	GeoTransRect(&scx->scx_trans, &lab->lab_rect, &area);
	newPos = GeoTransPos(&scx->scx_trans, lab->lab_pos);
	GEO_EXPAND(&area, 1, &searchArea);
	if (DBPlaneEnumAreaPaint((Tile *) NULL,
	    Select2Def->cd_planes[DBPlane(lab->lab_type)],
	    &searchArea, &DBConnectTbl[lab->lab_type], selLabelPaintFunc,
	    (ClientData) NULL) == 0) continue;

	(void) DBLabelAdd(SelectDef, &area, 
			  newPos, lab->lab_text,
			  lab->lab_type, 
			  lab->lab_kind);
    }

    /* Now check subcells of this cell. */
    (void) DBSrChildrenNested(scx, selLabelCellFunc, (ClientData) xMask);

    return 0;
}

/* The function below returns 1 whenever called.  It is used to detect
 * when there is paint of particular types under a particular area.
 */

int
selLabelPaintFunc(void)
{
    return 1;
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectChunk --
 *
 * 	This procedure selects a single rectangular chunk of 
 *	homogeneous material, maximizing the minimum dimension.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	More material is added to the select cell and displayed
 *	on the screen.  This procedure finds the largest rectangular
 *	chunk of material "type" that contains the area given in
 *	in scx.  The material need not all be in one cell, but it
 *	must all be in cells that are expanded according to "xMask".
 *	If pArea is given, the rectangle it points to is filled in
 *	with the area of the chunk that was selected.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectChunk(SearchContext *scx, /* Area to tree-search for material.  The
				 * transform must map to root coordinates
				 * of the edit cell.
				 */
	    TileType type,      /* The type of material to be considered. */
	    int xMask,          /* Indicates window (or windows) where cells
				 * must be expanded for their contents to be
				 * considered.  -1 means treat everything as
				 * expanded.
				 */
	    Rect *pArea,        /* If non-NULL, gets filled in with the area
				 * of the selection.
				 * in scx_use coords.
				 */
	    int less,           /* if set SUBTRACT matches from selection instead
				 * of adding. 
				 */
	    bool group,         /* if set only select things in currently active
				 * groups.
				 */
	    CellUse *noTreeRootUse) /* null for tree search,
				     * rootUse if searching just one cell, 
				     * the cell itself is indicated 
				     * in the scx.
				     */
{
#define INITIALSIZE 10
    SearchContext newscx = *scx;
    TileTypeBitMask typeMask;

    /* If the source definition is changing, clear the old selection. */
    if (SelectRootDef != scx->scx_use->cu_def)
    {
      if (SelectRootDef != NULL) SelectClear();
      SelectRootDef = scx->scx_use->cu_def;
    }

    /* set newscx area to chunk */
    DBChunk(&newscx,type, xMask, group, noTreeRootUse);

    if(GEO_RECTNULL(&newscx.scx_area)) goto done;

    TTMaskSetOnlyType(&typeMask, type);
    if (less)
    {
      SelRemoveArea(&newscx, &typeMask, xMask, group, noTreeRootUse);
    }
    else
    {
      SelectArea(&newscx, 
		 &typeMask, 
		 xMask, 
		 SA_NO_POLY | SA_NO_WP | (group ? SA_GROUP : 0),
		 noTreeRootUse);
    }

 done:
    if (pArea != NULL) *pArea = newscx.scx_area;
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelectRegion --
 *
 * 	Select an entire region of material, no matter what its
 *	shape.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	This procedure traces out the region consisting entirely
 *	of type "type", and selects all that material.  The search
 *	starts from "type" material under scx and continues outward
 *	to get all material in all cells connected to the area under
 *	scx by material of type "type".  If pArea is specified, then
 *	the rectangle that it points to is filled in with the bounding
 *	box of the region that was selected.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectRegion(SearchContext *scx, 
                       		/* Area to tree-search for material.  The
				 * transform must map to EditRoot coordinates.
				 */
	     TileType type, 
                  		/* The type of material to be considered. */
	     int xMask, 
              			/* Indicates window (or windows) where cells
				 * must be expanded for their contents to be
				 * considered.  0 means treat everything as
				 * expanded.
				 */
	     Rect *pArea, 
                		/* If non-NULL, points to rectangle to be
				 * filled in with region's bounding box.
				 */
	     int less)
{
    TileTypeBitMask connections[TT_MAXTYPES];
    int i;
    SearchContext scx2;

    /* If the source definition is changing, clear the old selection. */

    if (SelectRootDef != scx->scx_use->cu_def)
    {
	if (SelectRootDef != NULL)
	    SelectClear();
	SelectRootDef = scx->scx_use->cu_def;
    }

    /* Clear out the temporary selection cell and yank all of the
     * connected paint into it.
     */

    UndoDisable();
    DBCellClearContents(Select2Def);
    DBTreeCopyConnect(scx, 
		      &DBSelfOnlyTbl[type], 
		      xMask, 
		      connections, 
		      Select2Use,
		      0);  /* no limit (yet) */   
    UndoEnable();

    /* Now transfer what we found into the main selection cell.  Pick
     * up all the labels that correspond to the selected material.
     */
    
    selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);
    if (less)
      {
	(void) SelRemoveSel2();
      }
    else
      {
	scx2.scx_use = Select2Use;
	scx2.scx_area = *DBBBoxCellDef(Select2Def);
	scx2.scx_trans = GeoIdentityTransform;
	DBCellCopyAllPaint(&scx2, &DBAllButSpaceAndDRCBits,
			   0, SelectUse);
	
	/* Grab relevant labels. */
	selGetLabels(scx->scx_use, xMask);
      }

    /* Display the new selection. */

    {
      Rect *sel2BBox = DBBBoxCellDef(Select2Def);

      selUndoBracket(FALSE, SelectRootDef, sel2BBox);
      LayChangedDefSelection(SelectRootDef, sel2BBox, TRUE);
      DBChangedArea(SelectDef, sel2BBox, &DBAllButSpaceBits, 0);

      if (pArea != NULL) *pArea = *sel2BBox;
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * SelectNet --
 *
 * 	This procedure selects an entire electrically-connected net.
 *
 * Results:
 *	0 on normal completion, 1 if result is incomplete.
 *
 * Side effects:
 *	Starting from material of type "type" under scx, this procedure
 *	finds and highlights all material in all expanded cells that
 *	is electrically-connected to the starting material through a
 *	chain of expanded cells.  If pArea is specified, then the
 *	rectangle that it points to is filled in with the bounding box
 *	of the net that was selected.
 *
 * ----------------------------------------------------------------------------
 */

bool
SelectNet(SearchContext *scx, 
                       		/* Area to tree-search for material.  The
				 * transform must map to EditRoot coordinates.
				 */
	  TileType type, 
                  		/* The type of material to be considered. */
	  int xMask, 
              			/* Indicates window (or windows) where cells
				 * must be expanded for their contents to be
				 * considered.  0 means treat everything as
				 * expanded.
				 */
	  Rect *pArea, 
                		/* If non-NULL, points to rectangle to be
				 * filled in with net's bounding box.
				 */
	  int less,
	  bool labels,          /* if set, select labels attached to net */
	  int limit)            /* if non-zero, restricts search to limit 
				 * expansions.
				 */
{
    TileTypeBitMask mask;
    SearchContext scx2;
    bool completion;

    /* If the source definition is changing, clear the old selection. */
    if (SelectRootDef != scx->scx_use->cu_def)
    {
	if (SelectRootDef != NULL)
	    SelectClear();
	SelectRootDef = scx->scx_use->cu_def;
    }

    /* special case SPACE since it breaks DBTreeCopyConnect */
    if (type == TT_SPACE) return 0;

    TTMaskZero(&mask);
    TTMaskSetType(&mask, type);

    /* Copy connected paint into temporary selection */
    UndoDisable();
    DBCellClearContents(Select2Def);
    completion = DBTreeCopyConnect(scx, 
				   &mask, 
				   xMask, 
				   DBConnectTbl, 
				   Select2Use,
				   limit);
    UndoEnable();

    /* Now transfer what we found into the main selection cell.  Pick
     * up all the labels that correspond to the selected material.
     */
    selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);
    if (less)
    {
	SelRemoveSel2();
    }
    else
    {
      scx2.scx_use = Select2Use;
      scx2.scx_area = *DBBBoxCellDef(Select2Def);
      scx2.scx_trans = GeoIdentityTransform;
      DBCellCopyAllPaint(&scx2, &DBAllButSpaceAndDRCBits,
			   0, SelectUse);
	
      /* select relevant labels. */
      if(labels) selGetLabels(scx->scx_use, xMask);
    }

    /* Display the newly-selected material. */
    {
      Rect *sel2BBox = DBBBoxCellDef(Select2Def);

      selUndoBracket(FALSE, SelectRootDef, sel2BBox);
      LayChangedDefSelection(SelectRootDef, sel2BBox, TRUE);
      DBChangedArea(SelectDef, sel2BBox, &DBAllButSpaceBits, 0);

      if (pArea != NULL) *pArea = *sel2BBox;
    }

    return completion;
}

/*
 * ----------------------------------------------------------------------------
 *
 * SelectCell --
 *
 * 	Select a subcell by making a copy of it in the __SELECT__ cell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The given use is copied into the selection.  If replace is TRUE,
 *	then the last subcell to be selected via this procedure is
 *	deselected.
 *
 * ----------------------------------------------------------------------------
 */

void
SelectCell(CellUse *use, 
                 		/* Cell use to be selected. */
	   CellDef *rootDef, 
                     		/* Root definition of window in which selection
				 * is being made.
				 */
	   Transform *trans, 
                     		/* Transform from the coordinates of use's
				 * definition to the coordinates of rootDef.
				 */
	   int replace)
                 		/* TRUE means deselect the last cell selected
				 * by this procedure, if it's still selected.
				 */
{
    CellUse *newUse;

    /* If the source definition is changing, clear the old selection. */

    if (SelectRootDef != rootDef)
    {
	if (SelectRootDef != NULL)
	    SelectClear();
	SelectRootDef = rootDef;
    }

    /* Deselect the last cell selected, if requested. */
    if (replace && (selectLastUse != NULL))
    {
	Rect area = *DBBBoxCellUse(selectLastUse);

	selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);
	DBInstanceDelete(selectLastUse);
	selUndoBracket(FALSE, SelectRootDef, &area);
	LayChangedDefSelection(SelectRootDef, &area, TRUE);
    }

    selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);

    /* When creating a new use, try to re-use the id from the old
     * one.  Only create a new one if the old id can't be used.
     */
    newUse = DBCellUseNewCopy(use,NULL,trans);

    /* If cell already selected, just return */
    if( !DBInstanceAdd(newUse, SelectDef, 0))
    {
	selectLastUse = (CellUse *) NULL;
	selUndoBracket(FALSE, (CellDef *) NULL, (Rect *) NULL);
	return;
    }
    selectLastUse = newUse;

    /* change notification */
    {
      Rect *area; 

      DBChangedArea(SelectDef, &newUse->cu_bbox, &DBAllButSpaceBits, 0);
      area = DBBBoxCellUse(newUse); 
      selUndoBracket(FALSE, SelectRootDef, area);
      LayChangedDefSelection(SelectRootDef, area, TRUE);
    }
}

/* Utility function: for each tile, copy information over its area from
 * the given edit cell plane to SelectDef.  Always return 0 to keep the
 * search alive.
 */

int
selACPaintFunc(Tile *tile, int plane)
               			/* Tile in Select2Def. */
              			/* Index of plane this tile came from. */
{
    Rect area, editArea;
    int selACPaintFunc2(Tile *tile, Rect *editClip);	/* Forward reference. */

    TiToRect(tile, &area);
    GeoTransRect(&RootToEditTransform, &area, &editArea);
    (void) DBPlaneEnumAreaPaint((Tile *) NULL, EditCellUse->cu_def->cd_planes[plane],
	    &editArea, &DBAllButSpaceAndDRCBits, selACPaintFunc2,
	    (ClientData) &editArea);
    return 0;
}

/* Second-level paint function:  just paint the overlap between
 * tile and editClip into SelectDef.
 */

int
selACPaintFunc2(Tile *tile, 
               			/* Tile in edit cell. */
		Rect *editClip)
                   		/* Edit-cell area to clip to before painting
				 * into selection.
				 */
{
    Rect area, selArea;

    TiToRect(tile, &area);
    GeoClip(&area, editClip);
    GeoTransRect(&EditToRootTransform, &area, &selArea);
    DBPaint(SelectDef, &selArea, DBgetTileType(tile));

    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * selectAndCopy2 --
 *
 * 	This is procedure is intended for use only within the selection
 *	module.  It takes what's in Select2Def, makes a copy of it in the
 *	edit cell, and makes the copy the selection.  It's used, for
 *	example, by the transformation and copying routines.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection is augmented with what's in Select2Def.  The caller
 *	should normally have cleared the selection before calling us.
 *	The edit cell is modified to include everything that was in
 *	Select2Def.
 *
 * ----------------------------------------------------------------------------
 */

void
selectAndCopy2(bool dupOK)
	                                /* If set allow duplicate instances
					 * on top of each other.  (Useful
					 * for interactive drag.
					 */
{
    SearchContext scx;
    Rect editArea, labelArea;
    int plane;
    CellUse *editInstances;

    /* Just copy the information in Select2Def twice, once into the
     * edit cell and once into the main selection cell.
     */
    
    scx.scx_use = Select2Use;
    scx.scx_area = *DBBBoxCellUse(Select2Use);
    scx.scx_trans = RootToEditTransform;

    (void) DBCellCopyAllPaint(&scx, 
			      &DBAllButSpaceAndDRCBits, 
			      -1,               /* non hierarchical */ 
			      EditCellUse);

    (void) DBCellCopyAllLabels(&scx, 
			       &DBAllTypeBits, 
			       -1, 
			       EditCellUse, /* non hierarchical */
			       (Rect *) NULL,
			       (char *) NULL);

    (void) DBCellCopyAllCells(&scx, 
			      -1, 
			      EditCellUse,    /* non hierarchical */
			      (Rect *) NULL, 
			      &editInstances, /* creates list of new instances
					       * (cu_client linked)
					       */ 
			      dupOK,
			      (char *) NULL);

    /* process database changes */
    GeoTransRect(&scx.scx_trans, &scx.scx_area, &editArea);
    DBChangedArea(EditCellUse->cu_def, &editArea, NULL, 0);

    /* set selection root */
    SelectRootDef = EditRootDef;

    selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);
    scx.scx_trans = GeoIdentityTransform;

    /* In copying stuff into SelectUse, we have to be careful.  The problem
     * is that the stuff now in the edit cell may have switched layers.
     * (for example, Select2Def might have diff, which got painted
     * over poly in the edit cell to form transistor).  As a result, we
     * use Select2Def to figure out what areas of what planes to put into
     * SelectUse, but use the actual tile types from the edit cell.
     */
    
    for (plane = PL_SELECTBASE; plane < DBNumPlanes; plane++)
    {
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, Select2Def->cd_planes[plane],
		&TiPlaneRect, &DBAllButSpaceAndDRCBits, selACPaintFunc,
		(ClientData) plane);
    }

    /* copy polygons */
    if(Select2Def->cd_polygons) 
      DBPolygonsCopy(Select2Def, SelectDef, &GeoIdentityTransform);

    /* copy wirepaths */
    if(Select2Def->cd_wirePaths) 
      DBWPathsCopy(Select2Def, SelectDef, &GeoIdentityTransform);

    (void) DBCellCopyAllLabels(&scx, 
			       &DBAllTypeBits, 
			       -1, 
			       SelectUse,
			       &labelArea,
			       (char *) NULL);

    /* We also have to be careful about copying subcells into the
     * main selection cell.  It might not have been possible to copy
     * a subcell into the edit cell (above), because the copying
     * would have formed a circularity.  In that case, we need to
     * drop that subcell from the new selection.  The code below just
     * copies those that are still in the edit cell.
     */

    /* copy instances */
    while(editInstances)
    {
      CellUse *editUse = editInstances;
      CellUse *selUse;
      Transform trans;

      GEOTRANSTRANS(&editUse->cu_transform,&EditToRootTransform,&trans);

      /* duplicate editUse in SelectDef */
      selUse = DBCellUseNewCopy(editUse, NULL, &trans);
      DBInstanceAdd(selUse, SelectDef, DBIA_DUP_OK);

      /* pop it */
      editInstances = (CellUse *) editUse->cu_client;
      editUse->cu_client = 0; 
    }
    
    /* A little hack here:  don't do explicit redisplay of the selection,
     * or record a very large redisplay area for undo-ing.  It's not
     * necessary since the layout redisplay also redisplays the highlights.
     * If we do it too, then we're just double-displaying and wasting
     * time.  (note: must record something for undo-ing in order to get
     * SelectRootDef set right... just don't pass a redisplay area).
     */
    selUndoBracket(FALSE, SelectRootDef, (Rect *) NULL);
    DBChangedArea(SelectDef, NULL, NULL, 0);
}





