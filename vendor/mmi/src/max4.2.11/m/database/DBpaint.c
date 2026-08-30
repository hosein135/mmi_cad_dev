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
 * DBpaint.c --
 *
 * Fast paint primitive.
 * This uses a very fast, heavily tuned algorithm for painting.
 * The basic outer loop is a non-recursive area enumeration, and
 * the inner loop attempts to avoid merging as much as possible.
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

static char rcsid[] = "$Header:$";

#include <sys/types.h>
#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "layout.h"
#include "signals.h"
#include "message.h"
#include "undo.h"
#include "main.h"

static bool dbSameTypesInAllGroups_multiGroup(Tile *t1, Tile *t2)
{
    GroupList *gl;
    int l1 = 0;
    int l2 = 0;
    ASSERT(DBisSetTileFlag(t1,TF_MULTIGROUP),"dbSameTypesInAllGroups_multiGroup");
    ASSERT(DBisSetTileFlag(t2,TF_MULTIGROUP),"dbSameTypesInAllGroups_multiGroup");

    for(gl=(GroupList *) TiGetGroups(t1); gl; gl=gl->gl_next)
    {
      l1++;
      if(DBgetTypeG(t2, gl->gl_group) != gl->gl_type) return FALSE;
    }

    for(gl=(GroupList *) TiGetGroups(t2); gl; gl=gl->gl_next) l2++;

    return (l1 == l2);
}

static __inline__ bool dbSameTypesInAllGroups(Tile *t1, Tile *t2)
{
    if(DBisSetTileFlag(t1,TF_MULTIGROUP) && DBisSetTileFlag(t2,TF_MULTIGROUP))
    {
      return dbSameTypesInAllGroups_multiGroup(t1,t2);
    }
    else
    {
      return !DBisSetTileFlag(t1,TF_MULTIGROUP) &&
	     !DBisSetTileFlag(t2,TF_MULTIGROUP) &&
	     TiGetGroups(t1)==TiGetGroups(t2) && 
	     DBgetTileType(t1) == DBgetTileType(t2);
    }
}

/* helper func */
static void dbCopyBodyAndGroups_multiGroup(Tile *tsrc, Tile *tdest)
{
    GroupList *glSrc, *glDest, *new;

    ASSERT(DBisSetTileFlag(tsrc,TF_MULTIGROUP),"dbCopyBodyAndGroups_multiGroup");

    glSrc = (GroupList *) TiGetGroups(tsrc);

    /* copy head of list (must stay at head in case group NULL) */
    MALLOC(GroupList *, glDest, sizeof(GroupList));
    glDest->gl_type = glSrc->gl_type;
    glDest->gl_group = glSrc->gl_group;
    glDest->gl_next = NULL;

    TiSetGroups(tdest, glDest);

    /* copy rest of list */
    glSrc = glSrc->gl_next;
    for(;glSrc; glSrc= glSrc->gl_next)
    {
        MALLOC(GroupList *, new, sizeof(GroupList));
        new->gl_type = glSrc->gl_type;
        new->gl_group = glSrc->gl_group;

        new->gl_next = glDest->gl_next;
        glDest->gl_next = new;
    }
}

static __inline__ void dbCopyBodyAndGroups(Tile *tsrc, Tile *tdest)
{ 
    TiSetBody(tdest, TiGetBody(tsrc));

    if(DBisSetTileFlag(tsrc,TF_MULTIGROUP))
    {
        dbCopyBodyAndGroups_multiGroup(tsrc,tdest);
    }
    else
    {
        TiSetGroups(tdest, TiGetGroups(tsrc));
    }
}

/* ---------------------- Imports from DBundo.c ----------------------- */
extern CellDef *dbUndoLastCell;
extern UndoType dbUndoIDPaint;

/* Record undo information */
static __inline__ void 
dbRecordPaintUndo(
		  Tile *tile, 
		  TileType oldType, 
		  Group *group, 
		  PaintUndoInfo *undo)
{
    register paintUE *xxpup; \

    if (undo->pu_def != dbUndoLastCell) dbUndoEdit(undo->pu_def); 

    xxpup = (paintUE *) UndoNewEvent(dbUndoIDPaint, sizeof(paintUE)); 

    if (xxpup) 
    { 
	xxpup->pue_rect.r_xbot = LEFT(tile); 
	xxpup->pue_rect.r_xtop = RIGHT(tile); 
	xxpup->pue_rect.r_ybot = BOTTOM(tile); 
        xxpup->pue_rect.r_ytop = TOP(tile); 
	xxpup->pue_newtype = DBgetTypeG(tile, group); 
	xxpup->pue_oldtype = oldType; 
	xxpup->pue_group = group; 
	xxpup->pue_plane = undo->pu_pNum; 
    }
}

/* must compile with -DPAINTDEBUG before turning on this switch works */
/* this var is linked to tcl var db_paint_debug in DBtcl.c */
int dbPaintDebug = 0;

#ifndef	PAINTDEBUG
#define dbPaintShowTile(plane,tile,str) /* null */
#else
/*
 * ----------------------------------------------------------------------------
 *
 * dbPaintShowTile -- 
 *
 * Show the tile 'tp' in a highlighted style,
 * then print a message, wait for more, and erase the highlights.
 * This procedure is for debugging the new paint code only.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Redisplays.
 *
 * ----------------------------------------------------------------------------
 */

#include "styles.h"

static dbPaintShowTile(Plane *plane,    /* Plane of tile */
		       Tile *tile, 	/* Tile to be highlighted */
		       char *str)    	/* Message to be displayed */
{
    char answer[100];
    Rect r;
    Layout *w = LayCurWindow();

    /* if not watched plane, just return */
    if (!dbPaintDebug ||
	!EditRootDef || 
	!w || 
	w->lay_watchPlane == 0 ||
	!w->lay_rootUse ||
	!w->lay_rootUse->cu_def ||
	w->lay_rootUse->cu_def->cd_planes[w->lay_watchPlane] != plane
      ) return;

    TiToRect(tile, &r);
    DBChangedArea(EditRootDef, &r, &DBAllButSpaceBits, DBCF_DISPLAY);
    LayFeedbackAdd(&r, str, EditRootDef, 1, STYLE_FEEDBACK_MEDIUM);
    LayFeedbackShow();
    /* update idle tasks (to redisplay) */
    while(Tcl_DoOneEvent(TCL_IDLE_EVENTS | TCL_DONT_WAIT)) ; /* empty body */

    MsgInfoF("%s --more--", str); fflush(stdout);
    (void) TxGetLine(answer, sizeof answer);
    LayFeedbackClear();
}
#endif	PAINTDEBUG

/* ----------------------- Flags to dbPaintMerge ---------------------- */

#define MRG_TOP		0x01
#define	MRG_LEFT	0x02
#define	MRG_RIGHT	0x04
#define	MRG_BOTTOM	0x08

/* -------------- Macros to see if merging is possible ---------------- */

/* check to see if types match (for all groups) */

#define	CAN_MERGE_UP_AND_DOWN(t1, t2) 	(	 LEFT(t1) == LEFT(t2) \
				    &&   dbSameTypesInAllGroups(t1,t2) \
				    &&   RIGHT(t1) == RIGHT(t2))


/*
 * ----------------------------------------------------------------------------
 *
 * dbPaintMerge -- 
 *
 * Used by paint routines above.
 * Merges a newly painted tile to maintain maximal vertical strips.
 *
 * This procedure splits off the biggest segment along the top of the
 * tile 'tp' that can be merged with its neighbors to the left and right
 * (depending on which of MRG_LEFT and MRG_RIGHT are set in the merge flags).
 * then merges to the left, right,
 * top, and bottom (in that order).
 *
 * Results:
 *	Returns a pointer to the topmost tile resulting from any splits
 *	and merges of the original tile 'tp'.  By the maximal horizontal
 *	strip property and the fact that the original tile 'tp' gets
 *	painted a single color, we know that this topmost resulting tile
 *	extends across the entire top of the area occupied by 'tp'.
 *
 * Side effects:
 *	Modifies the database plane that contains the given tile.
 *
 * THIS IS SLOW, SO SHOULD BE AVOIDED IF AT ALL POSSIBLE.
 * DBPaintPlaneG goes to great lengths to minimize calls to this routine.
 *
 * Since dbpaintPlaneG() is interruptable, we need to take care to restore any
 * part of tile we split off to oldType (in case we are interrupted before it 
 * is processed - else database may not be left in max hor strip form).
 *
 * ----------------------------------------------------------------------------
 */
static Tile *
dbPaintMerge(
	     register Tile *tile,  /* Tile to be merged with its neighbors */
	     TileType oldType,     /* Type of tile before this paint op */ 
	     Group *group,            /* Group being painted */
	     Plane *plane,         /* Plane on which this resides */
	     int mergeFlags,       /* Specify which directions to merge */
             PaintUndoInfo *undo)
{
    register Tile *tp, *tpLast;
    register int ysplit;

    ysplit = BOTTOM(tile);
    if (mergeFlags & MRG_LEFT)
    {
	/*
	 * Find the split point along the LHS of tile.
	 * If the topmost tile 'tp' along the LHS is mergeable with tile
	 * the split point will be no lower than the bottom of 'tp'.
	 * If the topmost tile is NOT mergeable with tile, then the split
	 * point will be no lower than the top of the first tile along
	 * the LHS that is mergeable.
	 */
	for (tpLast = NULL, tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	{
	  if (dbSameTypesInAllGroups(tile,tp)) tpLast = tp;
	}

	if (tpLast == NULL || TOP(tpLast) < TOP(tile))
	{
	    /* topmost LHS tile NOT mergeabe */
	    mergeFlags &= ~MRG_LEFT;
	    if (tpLast && TOP(tpLast) > ysplit) ysplit = TOP(tpLast);
	}
	else 
	{
	  /* topmost LHS tile is mergeable */
	  if (BOTTOM(tpLast) > ysplit) ysplit = BOTTOM(tpLast);
	}
    }

    if (mergeFlags & MRG_RIGHT)
    {
	/*
	 * Find the split point along the RHS of 'tile'.
	 * If the topmost tile 'tp' along the RHS is mergeable with tile
	 * the split point will be no lower than the bottom of 'tp'.
	 * If the topmost tile is NOT mergeable, then the split
	 * point will be no lower than the top of the first tile along
	 * the RHS that is of type 'newType'.
	 */
	tp = TR(tile);
	if (dbSameTypesInAllGroups(tile,tp))
	{
	    if (BOTTOM(tp) > ysplit) ysplit = BOTTOM(tp);
	}
	else
	{
	    /* Topmost RHS tile is not of type 'newType', so don't merge */
	    do
	    {
		tp = LB(tp);
	    }
	    while (!dbSameTypesInAllGroups(tile,tp) && TOP(tp) > ysplit);

	    if (TOP(tp) > ysplit) ysplit = TOP(tp);
	    mergeFlags &= ~MRG_RIGHT;
	}
    }

    /*
     * If 'tile' must be split horizontally, do so.
     * Any merging to the bottom will be delayed until the split-off
     * bottom tile is processed on a subsequent iteration of the area
     * enumeration loop in DBPaintPlane().
     */
    if (ysplit > BOTTOM(tile))
    {
	mergeFlags &= ~MRG_BOTTOM;
	tp = TiSplitY_Bottom(tile, ysplit, plane);
	dbCopyBodyAndGroups(tile,tp);
	DBsetTypeG(tp,oldType,group);

	dbPaintShowTile(plane, tile, "(DBMERGE) after split");
    }

    /* record fors undo */
    if (undo && UndoIsEnabled(undo->pu_def) && DBgetTypeG(tile,group) != oldType )
    {
	dbRecordPaintUndo(tile, oldType, group, undo);
	dbPaintShowTile(plane, tile, "(DBMERGE) registered with undo");
    }

    /*
     * Do the merging.
     * We are guaranteed that at most one tile abuts 'tile' on
     * any side that we will merge to, and that if MRG_LEFT or MRG_RIGHT
     * is set, that the tiles to that side passes CANMERGE_X.
     */
    if (mergeFlags & MRG_LEFT)
    {
	tp = tpLast = BL(tile);
	if (TOP(tp) > TOP(tile)) tp = TiSplitY_Bottom(tp, TOP(tile), plane);
        if (BOTTOM(tp) < BOTTOM(tile))
	{
	    if(tp != tpLast) dbCopyBodyAndGroups(tpLast,tp);
	    tp = TiSplitY(tp, BOTTOM(tile), plane);
	}
        TiJoinX(tile, tp, plane);
	dbPaintShowTile(plane, tile, "(DBMERGE) merged left");
    }
    if (mergeFlags & MRG_RIGHT)
    {
	tp = tpLast = TR(tile);
	if (TOP(tp) > TOP(tile)) tp = TiSplitY_Bottom(tp, TOP(tile), plane);
	if (BOTTOM(tp) < BOTTOM(tile))
	{
	    if(tp != tpLast) dbCopyBodyAndGroups(tpLast,tp);
	    tp = TiSplitY(tp, BOTTOM(tile), plane);
	}
	TiJoinX(tile, tp, plane);
	dbPaintShowTile(plane, tile, "(DBMERGE) merged right");
    }
    if (mergeFlags&MRG_TOP)
    {
	tp = RT(tile);
	if (CAN_MERGE_UP_AND_DOWN(tp, tile)) TiJoinY(tile, tp, plane);
	dbPaintShowTile(plane, tile, "(DBMERGE) merged up");
    }
    if (mergeFlags&MRG_BOTTOM)
    {
	tp = LB(tile);
	if (CAN_MERGE_UP_AND_DOWN(tp, tile)) TiJoinY(tile, tp, plane);
	dbPaintShowTile(plane, tile, "(DBMERGE) merged down");
    }
    return (tile);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPaintPlaneG --
 *
 * Paint a rectangular area ('area') on a single tile plane ('plane'), for 
 * a specified group.
 *
 * The argument 'resultTbl' is a table, indexed by the type of each tile
 * found while enumerating 'area', that gives the result type for this
 * operation.  The semantics of painting, erasing, and "writing" (storing
 * a new type in the area without regard to the previous contents) are
 * all encapsulated in this table. 
 *
 * If undo is desired, 'undo' should point to a PaintUndoInfo struct
 * that contains everything needed to build an undo record.  Otherwise,
 * 'undo' can be NULL.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database plane that contains the given tile.
 *
 * REMINDER:
 *	Callers are responsible for change notification on the cell
 *	being modified
 *
 * ----------------------------------------------------------------------------
 */

void
DBPaintPlaneG
(
 Plane *plane,   		/* Plane whose paint is to be modified */
 register Rect *area,           /* Area to be changed */
 PaintResultType *resultTbl,    /* Table, indexed by the type of tile already
				 * present in the plane, giving the type to
				 * which the existing tile must change as a
				 * result of this paint operation.
				 */
 Group *group,                  /* group to paint into */
 PaintUndoInfo *undo            /* Record containing everything needed to
				 * save undo entries for this operation.
				 * If NULL, the undo package is not used.
				 */
)
{
    Point start;
    int clipTop, mergeFlags;
    TileType oldType, newType;
    register Tile *tile, *tpnew;	/* Used for area search */
    register Tile *newtile, *tp;	/* Used for paint */
    
    if (area->r_xtop <= area->r_xbot || area->r_ytop <= area->r_ybot)
	return;

    /* mark the passage of time */
    MnTic(1);

    /*
     * The following is a modified version of the area enumeration
     * algorithm.  It expects the in-line paint code below to leave
     * 'tile' pointing to the tile from which we should continue the
     * search.
     */

    start.p_x = area->r_xbot;
    start.p_y = area->r_ytop - 1;
    tile = plane->pl_hint;
    GOTOPOINT(tile, &start);

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tile) > area->r_ybot)
    {
	/***
	 *** AREA SEARCH.
	 *** Each iteration enumerates another tile.
	 ***/
enumerate:
	if (SigInterruptPending) break;
        dbPaintShowTile(plane, tile, "area enum");

	clipTop = TOP(tile);
	if (clipTop > area->r_ytop) clipTop = area->r_ytop;
	oldType = DBgetTypeG(tile,group); 

	/***
	 *** ---------- THE FOLLOWING IS IN-LINE PAINT CODE ----------
	 ***/

	/*
	 * Set up the directions in which we will have to
	 * merge initially.  Clipping can cause some of these
	 * to be turned off.
	 */
	mergeFlags = MRG_TOP | MRG_LEFT;
	if (RIGHT(tile) >= area->r_xtop) mergeFlags |= MRG_RIGHT;
	if (BOTTOM(tile) <= area->r_ybot) mergeFlags |= MRG_BOTTOM;

	/*
	 * The following is a kludge for plowing that should go away
	 * once the plowing code gets stable.  Make sure that the intermediate
	 * coordinate of this tile is reset to "uninitialized".
	 */
	tile->ti_client = (ClientData) MINFINITY;

	/*
	 * Determine new type of this tile.
	 * Change the type if necessary.
	 */
	newType = resultTbl[oldType];
	if (oldType != newType)
	{
	    /*
	     * Clip the tile against the clipping rectangle.
	     * Turn off merging in directions tile clipped. 
	     */

	    /* Clip up */
	    if (TOP(tile) > area->r_ytop)
	    {
		newtile = TiSplitY(tile, area->r_ytop, plane);
		dbCopyBodyAndGroups(tile,newtile);
		mergeFlags &= ~MRG_TOP;
	    }

	    /* Clip down */
	    if (BOTTOM(tile) < area->r_ybot)
	    {
		newtile = tile, tile = TiSplitY(tile, area->r_ybot, plane);
		dbCopyBodyAndGroups(newtile,tile);
		mergeFlags &= ~MRG_BOTTOM;
	    }

	    /* Clip right */
	    if (RIGHT(tile) > area->r_xtop)
	    {
		newtile = TiSplitX(tile, area->r_xtop, plane);
		dbCopyBodyAndGroups(tile,newtile);
		mergeFlags &= ~MRG_RIGHT;

		/* Merge outside tile up and down to maintain max hor. strips */
		tp = RT(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);
		tp = LB(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);
	    }

	    /* Clip left */
	    if (LEFT(tile) < area->r_xbot)
	    {
		newtile = tile;
		tile = TiSplitX(newtile, area->r_xbot, plane);
		dbCopyBodyAndGroups(newtile,tile);
		mergeFlags &= ~MRG_LEFT;

		/* Merge outside tile up and down to maintain max hor. strips */
		tp = RT(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);

		tp = LB(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);
	    }

  	   dbPaintShowTile(plane, tile, "after clip");
	}

	/* change tiletype */
	if(oldType != newType) 
	{
	    DBsetTypeG(tile, newType, group);
	    dbPaintShowTile(plane, tile, "changed type");
	}

	/*
	 * Merge the tile back into the parts of the plane that have
	 * already been visited.  Note that if we clipped in a particular
	 * direction we avoid merging in that direction.
	 *
	 * We avoid calling dbPaintMerge if at all possible.
	 */
	if (mergeFlags & MRG_LEFT)
	{
	    dbPaintShowTile(plane, tile, "mha mergin left a");
	    for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    {
		if (dbSameTypesInAllGroups(tp,tile))
		{
		    dbPaintShowTile(plane, tile, "mha mergin left b");
		    tile = dbPaintMerge(tile, oldType, group, plane, mergeFlags, undo);
		    goto paintdone;
		}
	    }
	    mergeFlags &= ~MRG_LEFT;

	}
	if (mergeFlags & MRG_RIGHT)
	{
	    for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    {
		if (dbSameTypesInAllGroups(tp,tile))
		{
		    tile = dbPaintMerge(tile, oldType, group, plane, mergeFlags, undo);
		    goto paintdone;
		}
	    }
	    mergeFlags &= ~MRG_RIGHT;
	}

	/* Record the event on the undo list. */
	if( oldType != newType && undo && UndoIsEnabled(undo->pu_def))
	{
	   dbRecordPaintUndo(tile, oldType, group, undo);
           dbPaintShowTile(plane, tile, "recording change in undo list");
	}

	/*
	 * Cheap and dirty merge -- we don't have to merge to the
	 * left or right, so the top/bottom merge is very fast.
	 *
	 */
	if (mergeFlags & MRG_TOP)
	{
	    tp = RT(tile);
	    if (CAN_MERGE_UP_AND_DOWN(tile, tp)) 
	    {
	        TiJoinY(tile, tp, plane);
	        dbPaintShowTile(plane, tile, "merged up (CHEAP)");
	    }
	}
	if (mergeFlags & MRG_BOTTOM)
	{
	    tp = LB(tile);
	    if (CAN_MERGE_UP_AND_DOWN(tile, tp)) 
	    {
	        TiJoinY(tile, tp, plane);
		dbPaintShowTile(plane, tile, "merged down (CHEAP)");
	    }
	}

	/***
	 ***		END OF PAINT CODE
	 *** ---------- BACK TO AREA SEARCH ----------
	 ***/
paintdone:
	/* Move right if possible */
	tpnew = TR(tile);
	if (LEFT(tpnew) < area->r_xtop)
	{
	    /* Move back down into clipping area if necessary */
	    while (BOTTOM(tpnew) >= clipTop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tile) || BOTTOM(tile) <= area->r_ybot)
	    {
		tile = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tile) > area->r_xbot)
	{
	    /* Move left if necessary */
	    if (BOTTOM(tile) <= area->r_ybot)
		goto done;

	    /* Move down if possible; left otherwise */
	    tpnew = LB(tile); tile = BL(tile);
	    if (BOTTOM(tpnew) >= BOTTOM(tile) || BOTTOM(tile) <= area->r_ybot)
	    {
		tile = tpnew;
		goto enumerate;
	    }
	}
	/* At left edge -- walk down to next tile along the left edge */
	for (tile = LB(tile); RIGHT(tile) <= area->r_xbot; tile = TR(tile))
	    /* Nothing */;
    }

done:
    plane->pl_hint = tile;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPaintPlane --
 *
 * Paint a rectangular area ('area') on a single tile plane ('plane'), for 
 * group 0.
 *
 * See documentation for DBPaintPlaneG().
 *
 * ----------------------------------------------------------------------------
 */

void
DBPaintPlane
(
 Plane *plane,   		/* Plane whose paint is to be modified */
 register Rect *area,           /* Area to be changed */
 PaintResultType *resultTbl,    /* Table, indexed by the type of tile already
				 * present in the plane, giving the type to
				 * which the existing tile must change as a
				 * result of this paint operation.
				 */
 PaintUndoInfo *undo            /* Record containing everything needed to
				 * save undo entries for this operation.
				 * If NULL, the undo package is not used.
				 */
)
{
  if(undo)
  {
    DBPaintPlaneG(plane,area,resultTbl,undo->pu_def->cd_activeGroup,undo);
  }
  else
  {
    DBPaintPlaneG(plane,area,resultTbl,0,0);
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBPaintPlaneMergeOnce --
 *
 * This routine used in place of DBPaintPlane above by drc.
 * Unlike DBPaintPlane, it is non interruptable.
 * NOTE:  CURRENTLY this routine is not "group aware"
 *
 * Paint a rectangular area ('area') on a single tile plane ('plane').
 * This is identical to DBPaintPlane(), except that we work in two
 * passes:
 *
 *	Pass 1: clip all tiles to lie inside the area to be painted,
 *		merging all outside tiles as required.  Change the
 *		types of each of these internal tiles.
 *
 *	Pass 2:	re split and merge to insure that the database is
 *		once again in maximal horizontal strips.
 *
 * See DBPaintPlane for other comments.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the database plane that contains the given tile.
 *
 * ----------------------------------------------------------------------------
 */

Void
DBPaintPlaneMergeOnce(Plane *plane, register Rect *area, PaintResultType *resultTbl, PaintUndoInfo *undo)
                 		/* Plane whose paint is to be modified */
                        	/* Area to be changed */
                               	/* Table, indexed by the type of tile already
				 * present in the plane, giving the type to
				 * which the existing tile must change as a
				 * result of this paint operation.
				 */
                        	/* Record containing everything needed to
				 * save undo entries for this operation.
				 * If NULL, the undo package is not used.
				 */
{
    Point start;
    int clipTop, mergeFlags;
    TileType oldType, newType;
    register Tile *tile, *tpnew;	/* Used for area search */
    register Tile *newtile, *tp;	/* Used for paint */

    if (area->r_xtop <= area->r_xbot || area->r_ytop <= area->r_ybot)
	return;

    /*
     * The following is a modified version of the area enumeration
     * algorithm.  It expects the in-line paint code below to leave
     * 'tile' pointing to the tile from which we should continue the
     * search.
     */

    start.p_x = area->r_xbot;
    start.p_y = area->r_ytop - 1;
    tile = plane->pl_hint;
    GOTOPOINT(tile, &start);

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tile) > area->r_ybot)
    {
	/***
	 *** AREA SEARCH.
	 *** Each iteration enumerates another tile.
	 ***/
enumerate:
	if (SigInterruptPending)
	    break;

	clipTop = TOP(tile);
	if (clipTop > area->r_ytop) clipTop = area->r_ytop;
	oldType = DBgetTileType(tile);

#ifdef	PAINTDEBUG
	if (dbPaintDebug)
	    dbPaintShowTile(plane, tile, "first area enum");
#endif	PAINTDEBUG

	/***
	 *** ---------- THE FOLLOWING IS IN-LINE PAINT CODE ----------
	 ***/

	/*
	 * Determine new type of this tile.
	 * Change the type if necessary.
	 */
	newType = resultTbl[oldType];
	if (oldType != newType)
	{
	    /*
	     * Clip the tile against the clipping rectangle.
	     * Merging of the outside tiles is only necessary if we clip
	     * to the left or to the right, and then only to the top or
	     * the bottom.  We do the merge in-line for efficiency.
	     */

	    /* Clip up */
	    if (TOP(tile) > area->r_ytop)
	    {
		newtile = TiSplitY(tile, area->r_ytop, plane);
		TiSetBody(newtile, TiGetBody(tile));
	    }

	    /* Clip down */
	    if (BOTTOM(tile) < area->r_ybot)
	    {
		newtile = tile, tile = TiSplitY(tile, area->r_ybot, plane);
		TiSetBody(tile, TiGetBody(newtile));
	    }

	    /* Clip right */
	    if (RIGHT(tile) > area->r_xtop)
	    {
		newtile = TiSplitX(tile, area->r_xtop, plane);
		TiSetBody(newtile, TiGetBody(tile));

		/* Merge the outside tile to its top */
		tp = RT(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);

		/* Merge the outside tile to its bottom */
		tp = LB(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);
	    }

	    /* Clip left */
	    if (LEFT(tile) < area->r_xbot)
	    {
		newtile = tile;
		tile = TiSplitX(newtile, area->r_xbot, plane);
		TiSetBody(tile, TiGetBody(newtile));

		/* Merge the outside tile to its top */
		tp = RT(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);

		/* Merge the outside tile to its bottom */
		tp = LB(newtile);
		if (CAN_MERGE_UP_AND_DOWN(newtile, tp)) TiJoinY(newtile, tp, plane);
	    }

#ifdef	PAINTDEBUG
	    if (dbPaintDebug)
		dbPaintShowTile(plane, tile, "after clip");
#endif	PAINTDEBUG

	    /* Record the type of the new tile */
	    if (undo && UndoIsEnabled(undo->pu_def))
		dbRecordPaintUndo(tile, newType, NULL, undo);
	    TiSetBody(tile, newType);
	}

	/***
	 ***		END OF PAINT CODE
	 *** ---------- BACK TO AREA SEARCH ----------
	 ***/
	/* Move right if possible */
	tpnew = TR(tile);
	if (LEFT(tpnew) < area->r_xtop)
	{
	    /* Move back down into clipping area if necessary */
	    while (BOTTOM(tpnew) >= clipTop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tile) || BOTTOM(tile) <= area->r_ybot)
	    {
		tile = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tile) > area->r_xbot)
	{
	    /* Move left if necessary */
	    if (BOTTOM(tile) <= area->r_ybot)
		goto changedone;

	    /* Move down if possible; left otherwise */
	    tpnew = LB(tile); tile = BL(tile);
	    if (BOTTOM(tpnew) >= BOTTOM(tile) || BOTTOM(tile) <= area->r_ybot)
	    {
		tile = tpnew;
		goto enumerate;
	    }
	}
	/* At left edge -- walk down to next tile along the left edge */
	for (tile = LB(tile); RIGHT(tile) <= area->r_xbot; tile = TR(tile))
	    /* Nothing */;
    }

changedone:
    /*
     * Done with the area enumeration to change the types of all tiles
     * in this area.  Now go back and re-merge everything to form
     * maximal horizontal strips.  The following is another in-line
     * version of area enumeration, but is non-interruptible.
     */
    GOTOPOINT(tile, &start);

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tile) > area->r_ybot)
    {
	/***
	 *** AREA SEARCH.
	 *** Each iteration enumerates another tile.
	 ***/
mergenum:
	clipTop = TOP(tile);
	if (clipTop > area->r_ytop) clipTop = area->r_ytop;
	oldType = DBgetTileType(tile);

#ifdef	PAINTDEBUG
	if (dbPaintDebug)
	    dbPaintShowTile(plane, tile, "merge area enum");
#endif	PAINTDEBUG

	/***
	 *** ---------- THE FOLLOWING IS IN-LINE MERGE CODE ----------
	 ***/

	/* Set up initial merge directions */
	mergeFlags = MRG_TOP | MRG_LEFT;
	if (RIGHT(tile) >= area->r_xtop) mergeFlags |= MRG_RIGHT;
	if (BOTTOM(tile) <= area->r_ybot) mergeFlags |= MRG_BOTTOM;

	/*
	 * Merge the tile back into the parts of the plane that have
	 * already been visited.  Note that if we clipped in a particular
	 * direction we avoid merging in that direction.
	 * We avoid calling dbPaintMerge if at all possible.
	 */
	newType = DBgetTileType(tile);
	if (mergeFlags & MRG_LEFT)
	{
	    for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
		if (DBgetTileType(tp) == newType)
		{
		    tile = dbPaintMerge(tile, oldType, 0, plane, mergeFlags, undo);
		    goto mergedone;
		}
	    mergeFlags &= ~MRG_LEFT;
	}
	if (mergeFlags & MRG_RIGHT)
	{
	    for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
		if (DBgetTileType(tp) == newType)
		{
		    tile = dbPaintMerge(tile, oldType, 0, plane, mergeFlags, undo);
		    goto mergedone;
		}
	    mergeFlags &= ~MRG_RIGHT;
	}

	/*
	 * Cheap and dirty merge -- we don't have to merge to the
	 * left or right, so the top/bottom merge is very fast.
	 */

	if (mergeFlags & MRG_TOP)
	{
	    tp = RT(tile);
	    if (CAN_MERGE_UP_AND_DOWN(tile, tp)) TiJoinY(tile, tp, plane);
#ifdef	PAINTDEBUG
	    if (dbPaintDebug)
		dbPaintShowTile(plane, tile, "merged up (CHEAP)");
#endif	PAINTDEBUG
	}
	if (mergeFlags & MRG_BOTTOM)
	{
	    tp = LB(tile);
	    if (CAN_MERGE_UP_AND_DOWN(tile, tp)) TiJoinY(tile, tp, plane);
#ifdef	PAINTDEBUG
	    if (dbPaintDebug)
		dbPaintShowTile(plane, tile, "merged down (CHEAP)");
#endif	PAINTDEBUG
	}


	/***
	 ***		END OF MERGE CODE
	 *** ---------- BACK TO AREA SEARCH ----------
	 ***/
mergedone:
	/* Move right if possible */
	tpnew = TR(tile);
	if (LEFT(tpnew) < area->r_xtop)
	{
	    /* Move back down into clipping area if necessary */
	    while (BOTTOM(tpnew) >= clipTop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tile) || BOTTOM(tile) <= area->r_ybot)
	    {
		tile = tpnew;
		goto mergenum;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tile) > area->r_xbot)
	{
	    /* Move left if necessary */
	    if (BOTTOM(tile) <= area->r_ybot)
		goto done;

	    /* Move down if possible; left otherwise */
	    tpnew = LB(tile); tile = BL(tile);
	    if (BOTTOM(tpnew) >= BOTTOM(tile) || BOTTOM(tile) <= area->r_ybot)
	    {
		tile = tpnew;
		goto mergenum;
	    }
	}
	/* At left edge -- walk down to next tile along the left edge */
	for (tile = LB(tile); RIGHT(tile) <= area->r_xbot; tile = TR(tile))
	    /* Nothing */;
    }

done:
    plane->pl_hint = tile;
}
