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
 * selUnselect.c --
 *
 */

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "layout.h"
#include "commands.h"
#include "main.h"
#include "select.h"
#include "selInt.h"
#include "malloc.h"
#include "message.h"

/*
 * ----------------------------------------------------------------------------
 *
 * selUnselFunc --
 *
 *	This function is used by SelRemoveSel2; 
 *      it is passed to DBPlaneEnumAreaPaint as
 *	the search function for a search of the select2 cell, and erases
 *	equivalent areas of paint in the select cell (in effect, it deletes
 *	the contents of select2 from select).
 *
 * Results:
 *	Always returns zero (so the search will continue).
 *
 * Side effects:
 *	Paint is removed from the select cell.
 *
 * ----------------------------------------------------------------------------
 */

static int
selUnselFunc(Tile *tile, ClientData *arg)
{
  TileType type = DBgetTileType(tile);
  Rect rect;
  
  TiToRect(tile, &rect);
  DBErase(SelectDef, &rect, type);
  return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * selRemoveCellFunc --
 *
 *	This procedure hides some (limited number of) cell uses for later
 *	munging; it is a search procedure for DBSrChildren.
 *
 * Results:
 *	Always aborts array enumeration (we only need one placement in order
 *	to rip out the whole array).  Aborts the search once MAXUNSELUSES
 *	cell uses have been hidden away.
 *
 * Side effects:
 *	Cell uses are entered in the array selRemoveUses; the variable
 *	selNRemove is incremented.
 *
 * ----------------------------------------------------------------------------
 */

#define MAXUNSELUSES 3
static CellUse *(selRemoveUses[MAXUNSELUSES]);
static int selNRemove;

static int
selRemoveCellFunc(SearchContext *scx, Rect *cdarg)
{
  ASSERT((selNRemove < MAXUNSELUSES) && (selNRemove >= 0),
	 "selRemoveCellFunc(selNRemove)");
  selRemoveUses[selNRemove] = scx->scx_use;
  GeoIncludeAll(DBBBoxCellUseNoUp(scx->scx_use), cdarg);
  if (++selNRemove >= MAXUNSELUSES) return 1;
  else return 2;
}


/*
 * ----------------------------------------------------------------------------
 *
 * selRemovePaintFunc --
 *
 *	Remove paint from selection corresponding to paint in active group
 *      in search area. 
 *
 * ----------------------------------------------------------------------------
 */


/* Structure passed to selRemovePaintFunc  */
struct selRemovePaintArg 
{
    TileTypeBitMask	*srpa_mask;	/* Mask of tile types to be copied */
    Rect		 srpa_rect;	/* Clipping rect in target coords */
};

static int 
selRemovePaintFunc(register Tile *tile, TreeContext *cxp)
                        	/* Pointer to tile to copy */
                     		/* Context from DBSearchPaint */
{
    register SearchContext *scx = cxp->tc_scx;
    register struct selRemovePaintArg *arg = 
      (struct selRemovePaintArg *) cxp->tc_filter->tf_arg;
    TileType type = DBgetTypeG(tile, cxp->tc_scx->scx_use->cu_def->cd_activeGroup);
    Rect sourceRect, targetRect;

    /* filter types */
    if (!TTMaskHasType(arg->srpa_mask,type)) return 0;

    /* Construct the rect for the tile in source coordinates */
    TITORECT(tile, &sourceRect);

    /* Transform to target coordinates */
    GEOTRANSRECT(&scx->scx_trans, &sourceRect, &targetRect);

    /* Clip against the target area */
    GEOCLIP(&targetRect, &arg->srpa_rect);

    /* erase from selection */
    DBErase(SelectDef, &targetRect, type);

    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelRemoveArea --
 *
 *	Remove a rectangular chunk of the select cell, possibly masked
 *	by a user-specified mask (which may include the pseudo-levels
 *	L_CELL and L_LABEL).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Paint, labels, and/or cell uses may be removed from the select cell.
 *	The selection highlights are redrawn, and undo checkpoints are saved,
 *	so this thrilling process may be undone or redone.  The select cell's
 *	bounding box is updated.
 *
 * ----------------------------------------------------------------------------
 */

void
SelRemoveArea(SearchContext *scx,  /* Describes the area in which material
		                    * is to be selected.  The resulting
				    * coordinates should map to the coordinates
				    * of EditRootDef.  The cell use should be
				    * the root of a window.
				    */
	   TileTypeBitMask *mask, /* Indicates which layers to select.  Can
				    * include L_CELL and L_LABELS to select
				    * labels and unexpanded subcells.  If L_LABELS
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
	   bool activeGroupOnly,  /* if set only select paint in active groups */
           CellUse *noTreeRootUse)  /* if non-null search only "toplevel" cell
				     * in scx */
/* TODO: implement noTree */     
{
  Rect bbox;
  Rect *area = &(scx->scx_area);

  if(noTreeRootUse)
  {
      MsgErrorF("TODO noTree option not yet implemented for SelRemoveArea()\n");
      return;
  }

  /* get ready; save checkpoint for undo. */

  selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);

  /* erase ordinary paint in area */

  if(!activeGroupOnly)
  {
    /* if we are erasing all groups, no need to consult "source"
     * cell, just wipe area in select def.
     */
    DBEraseMask(SelectDef, &(scx->scx_area), mask);
  }
  else
  {
    struct selRemovePaintArg arg;
    arg.srpa_mask = mask;
    GEOTRANSRECT(&scx->scx_trans, &scx->scx_area, &arg.srpa_rect);

    (void) DBSearchPaint(scx, mask, xMask, selRemovePaintFunc, (ClientData) &arg);
  }

  /* defenestrate a few labels */

  if (TTMaskHasType(mask, L_LABEL))
    (void) DBLabelsEraseArea(SelectDef, area, &DBAllTypeBits);
  else
    (void) DBLabelsEraseArea(SelectDef, area, mask);

  /* now blast away at cells; we do this a tiny bit at a time, as in
     selectClear.  We search, and remember up to MAXUNSELUSES cell
     placements in each search; then we rip out those placements, and
     search further.  As always, thou shalt not rip out what thou
     searchest, or thine database shall be corrupt, and thy name
     anathema in the ears of thy mask designers.  */

  bbox = *area;
  if (TTMaskHasType(mask, L_CELL))
    {
      SearchContext scx2;
      scx2.scx_use = SelectUse;
      scx2.scx_trans = GeoIdentityTransform;
      scx2.scx_area = *area;
      while (TRUE)
	{
	  int i;
	  
	  selNRemove = 0;
	  (void) DBSrChildren(&scx2, selRemoveCellFunc, (ClientData) &bbox);
	  for (i = 0; i < selNRemove; i++)
	    {
	      if (selectLastUse == selRemoveUses[i])
		selectLastUse = (CellUse *) NULL;
	      DBInstanceUnlink(selRemoveUses[i], SelectDef);
	      DBInstanceUnplace(selRemoveUses[i]);
	      (void) DBCellDeleteUse(selRemoveUses[i]);
	    }
	  if (selNRemove < MAXUNSELUSES) break;
	}
    }

  /* now remember stuff for redo (and fill in info for undo), redraw highlights,
     recompute the bounding box on the off chance it has changed, tell the
     database we've mucked around with the select cell, then go home. */

  selUndoBracket(FALSE, SelectRootDef, &bbox);
  LayChangedSelection(SelectRootDef, &bbox, TRUE);
  DBChangedArea(SelectDef, &bbox, NULL, 0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * selRemoveLabelPaintFunc --
 *
 *	Put labels in the select2 cell.  The SelRemoveSel2 function runs through
 *	all the labels in the select cell, and calls DBPlaneEnumAreaPaint on select2 for
 *	each one.  If there is (suitable) paint in select2 under the label, this
 *	function gets called, and places the label in select2.
 *
 * Results:
 *	Always returns one (and thus aborts the search).
 *
 * Side effects:
 *	Labels may appear in select2.
 *
 * ----------------------------------------------------------------------------
 */

static int
selRemoveLabelPaintFunc(Tile *tile, Label *label)
{
  (void) DBLabelAdd(Select2Def, &label->lab_rect, label->lab_pos,
		    &label->lab_text[0], label->lab_type, label->lab_kind);

  return 1;
}

/*
 * ----------------------------------------------------------------------------
 *
 * SelRemoveSel2 --
 *	Run through the select2 cell, removing corresponding paint and labels
 *	from the select cell.
 *
 * Results:
 *	Should always return zero; returns 1 if there is a problem traversing
 *	select2.
 *
 * Side effects:
 *	Paint and labels (but not cell uses) may be deleted from the select
 *	cell.  The calling procedure is responsible for updating highlighting
 *	and undo information.
 *
 *	Labels may be placed in the select2 cell; SelRemoveSel2 assumes that
 *	there are no labels in select2 when it is called.
 *
 * ----------------------------------------------------------------------------
 */

int
SelRemoveSel2(void)
{
  int plane;
  Label *label;

  /* Enumerate paint tiles in select2; selUnselFunc will erase corresponding
     pieces in the select cell. */

  for (plane = PL_TECHDEPBASE; plane < DBNumPlanes; plane++)
    {
      if (DBPlaneEnumAreaPaint((Tile *) NULL, Select2Def->cd_planes[plane],
			&TiPlaneRect, &DBAllButSpaceAndDRCBits, selUnselFunc,
			(ClientData) NULL) != 0)
	return 1;
    }

  /* Enumerate labels in select; selRemoveLabelPaintFunc will place a copy of
     the label in select2 if it finds appropriate paint underneath the label. */

  ASSERT(Select2Def->cd_labels == (Label *) NULL, "SelRemoveSel2 labels");

  for (label = SelectDef->cd_labels;
       label != (Label *) NULL;
       label = label->lab_next)
    {
      Rect area, searchArea;

      if (label->lab_type == TT_SPACE) continue;
      area = label->lab_rect;
      GEO_EXPAND(&area, 1, &searchArea);
      (void) DBPlaneEnumAreaPaint((Tile *) NULL,
			   Select2Def->cd_planes[DBPlane(label->lab_type)],
			   &searchArea, &DBConnectTbl[label->lab_type],
			   selRemoveLabelPaintFunc,
			   (ClientData) label);
    }

  /* Now run through the labels we just copied, and delete them from
     the select cell.  */

  for (label = Select2Def->cd_labels;
       label != (Label *) NULL;
       label = label->lab_next)
    DBLabelsEraseByContent(SelectDef,
			   &label->lab_rect,
			   label->lab_pos,
			   -1,
			   label->lab_text);
  return 0;
}

typedef struct
{
  CellUse *ed_use, *sel_use;
  Transform *orient;
} SelRemoveCellArgs;

/*
 * ----------------------------------------------------------------------------
 *
 * SelRemoveCellSearchFunc --
 *	find the cell use in the select cell which matches a given
 *	cell use in the root def.
 *
 * Results:
 *	Returns 1 to abort the search if it finds a match.  Otherwise
 *	returns zero.
 *
 * Side effects:
 *	fills in the sel_use field of its client argument if it finds a match.
 *
 * ----------------------------------------------------------------------------
 */

static int
SelRemoveCellSearchFunc(SearchContext *scx, SelRemoveCellArgs *cdarg)
{
  Transform *et, *st;

  /* To match, cell uses must point to the same cell def. */

  if (scx->scx_use->cu_def != cdarg->ed_use->cu_def)
    return 0;

  /* If these usages are in the same orientation, at the same
     location, they match.  To check this, we compare the
     search context transformation with the transformation
     computed earlier for the usage in the edit cell. */

  st = &scx->scx_trans;
  et = cdarg->orient;
  if ((st->t_a == et->t_a) &&
      (st->t_b == et->t_b) &&
      (st->t_c == et->t_c) &&
      (st->t_d == et->t_d) &&
      (st->t_e == et->t_e) &&
      (st->t_f == et->t_f))
    {
      cdarg->sel_use = scx->scx_use;
      return 1;
    }
  return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * SelectRemoveCellUse --
 *	remove the cell use in the select cell which matches the given
 *	use from the root def.
 *
 * Results:
 *	Returns 1 if no such use was found; returns zero otherwise.
 *
 * Side effects:
 *	If SelectRemoveCellUse returns 1, there are no side effects.
 *	Otherwise:  undo/redo markers will be created, one cell use
 *	will be deleted from the select cell, the select cell's bounding
 *	box will be recomputed, the highlights redrawn, and the area
 *	which had been covered by the cell use will be marked as
 *	changed.  If selectLastUse was pointing to the use, it will
 *	be set to NULL, so the select cycling code will not try
 *	to deselect this (now trashed) cell use.
 *
 * ----------------------------------------------------------------------------
 */

int SelectRemoveCellUse(CellUse *use, Transform *trans)
{
  SearchContext scx;
  SelRemoveCellArgs args;

  /* The search context is the area covered by the cell's bounding box in
     the select cell. */

  scx.scx_use = SelectUse;
  GEOTRANSRECT(trans, 
	       DBBBoxCellDef(use->cu_def), 
	       &scx.scx_area);
  scx.scx_trans = GeoIdentityTransform;
  args.ed_use = use;
  args.orient = trans;

  /* DBSrChildren will return all of the cells overlapping this box;
     often, this is just one cell.  If the search runs to completion
     (is not aborted), we did not find a match, so we quit, returning
     1 as a failure indication.  */

  if (DBSrChildren(&scx, SelRemoveCellSearchFunc, (ClientData) &args) == 0)
    return 1;

  /* remunge the selectLastUse Horrid Side Effect Pointer */

  if (selectLastUse == args.sel_use)
    selectLastUse = (CellUse *) NULL;

  /* Now remove the cell use (with appropriate undo and database
     incantations). */

  selUndoBracket(TRUE, (CellDef *) NULL, (Rect *) NULL);
  DBInstanceUnlink(args.sel_use, SelectDef);
  DBInstanceUnplace(args.sel_use);
  (void) DBCellDeleteUse(args.sel_use);
  selUndoBracket(FALSE, SelectRootDef, &scx.scx_area);
  LayChangedSelection(SelectRootDef, &scx.scx_area, TRUE);
  DBChangedArea(SelectDef, &scx.scx_area, NULL, 0);

  return 0;
}

