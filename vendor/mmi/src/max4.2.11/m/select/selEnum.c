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
 * selEnum.c --
 *
 * This file contains routines to enumerate various pieces of the
 * selection, e.g. find all subcells that are in the selection and
 * also in the edit cell.  The procedures here are used as basic
 * building blocks for the selection commands like copy or delete.
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
static char rcsid[]="$Header: selEnum.c,v 6.0 90/08/28 18:56:43 mayo Exp $";
#endif  not lint

#include <signal.h>
#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"
#include "malloc.h"
#include "message.h"
#include "signals.h"
#include "select.h"
#include "selInt.h"



/* Structure passed from top-level enumeration procedures to lower-level
 * ones:
 */

struct searg
{
    int (*sea_func)();		/* Client function to call. */
    int sea_func_result;        /* result returned by func */
    ClientData sea_cdarg;	/* Client data to pass to sea_func. */
    bool sea_editOnly;		/* Only consider stuff that's in edit cell. */
    bool *sea_nonEdit;		/* Word to set if non-edit stuff is found. */
    int sea_plane;		/* Index of plane currently being searched. */
    TileType sea_type;		/* Type of current piece of selected paint. */
    LinkedRect *sea_rectList;	/* List of rectangles found in edit cell. */
    CellUse *sea_use;		/* Use that we're looking for an identical
				 * copy of in the layout.
				 */
    CellUse *sea_foundUse;	/* Use that was found to match sea_use, or else
				 * NULL.  
				 */
    Transform sea_foundTrans;	/* Transform from coords of foundUse to root. */
    TerminalPath *sea_foundTPath; /* path to foundUse */
    TerminalPath *sea_tPath;    /* used to track instance path */ 
    Label *sea_label;		/* Label that we're trying to match in the
				 * layout.
				 */
    Label *sea_foundLabel;	/* Matching label that was found, or NULL.
				 * If non_NULL, foundUse and foundTrans
				 * describe its containing cell.
				 */
    Polygon *sea_poly;	/* Polygon that we're trying to match in the
				 * layout.
				 */

    WirePath *sea_wp;	/* wire path that we're trying to match in the
				 * layout.
				 */
};


/* 
 * =============== PAINT ENUMERATION =============== 
 */

/* Second-level paint search function:  save around (in edit coords)
 * each tile that has the same type as requested in arg.  Record if
 * any wrong-type tiles are found.
 */

int
selEnumPFunc2(Tile *tile, struct searg *arg)
               			/* Tile found in the edit cell. */
                      		/* Describes our search. */
{
    LinkedRect *lr;

    if ((arg->sea_type != DBgetTileType(tile)) &&
	(!DBisSetTileFlag(tile,TF_MULTIGROUP) || 
	 !TTMaskHasType(DBGroupTileTypesMask(tile),arg->sea_type)))
    {

      if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
      return 0;
    }

    lr = (LinkedRect *) mallocMagic(sizeof(LinkedRect));
    TiToRect(tile, &lr->r_r);
    lr->r_next = arg->sea_rectList;
    arg->sea_rectList = lr;
    return 0;
}

/* Search function invoked for each piece of paint on the right layers
 * in the select cell.  Collect all of the sub-areas of this piece that
 * are also in the edit cell, then call the client function for each
 * one of them.  It's important to collect the pieces first, then call
 * the client:  if we call the client while the edit cell search is
 * underway, the client might trash the tile plane underneath us.
 */
int
selEnumPFunc1(Tile *tile, struct searg *arg)
               			/* Tile of matching type. */
                      		/* Describes the current search. */
{
    Rect rect, editRect, rootRect;

    TiToRect(tile, &rect);
    arg->sea_type = DBgetTileType(tile);

    /* If this tile is a contact's secondary image, ignore it:  the
     * primary image will take care of everything (otherwise when
     * the second image is processed, the contact might not be there
     * anymore).
     */

    if (arg->sea_type >= DBNumUserLayers) return 0;

    /* If the paint doesn't have to be in the edit cell, life's pretty
     * simple:  just call the client and quit.
     */
    
    if (!arg->sea_editOnly)
    {
	if ((*arg->sea_func)(&rect, arg->sea_type, arg->sea_cdarg) != 0)
	    return 1;
	return 0;
    }
    
    /* Find the stuff that's in the edit cell. */
    GeoTransRect(&RootToEditTransform, &rect, &editRect);
    arg->sea_rectList = NULL;
    (void) DBPlaneEnumAreaPaint((Tile *) NULL,
	    EditCellUse->cu_def->cd_planes[arg->sea_plane],
	    &editRect, &DBAllTypeBits, selEnumPFunc2,
	    (ClientData) arg);
    
    /* Call the client for each rectangle found. */

    while (arg->sea_rectList != NULL)
    {
	GeoTransRect(&EditToRootTransform, &arg->sea_rectList->r_r, &rootRect);
	GeoClip(&rootRect, &rect);
	if ((*arg->sea_func)(&rootRect, arg->sea_type, arg->sea_cdarg) != 0)
	    return 1;
	freeMagic((char *) arg->sea_rectList);
	arg->sea_rectList = arg->sea_rectList->r_next;
    }
    return 0;
}

/* helper func called on polygons in SelectDef */
int selEnumPolyFunc1(SearchContext *scx, 
		     Polygon *poly,
		     ClientData cdarg)
{
  Rect *want, got;
  struct searg *arg = (struct searg *) cdarg;

  /* TODO: mv polygon equal func to DBpolygon.c */

  /* number of vertices the same? */
  if(poly->poly_size != arg->sea_poly->poly_size) return 0;

  /* bounding boxes the same? */
  GeoTransRect(&scx->scx_trans, &poly->poly_bbox, &got);
  want = &arg->sea_poly->poly_bbox;
  if (want->r_xbot != got.r_xbot) return 0;
  if (want->r_ybot != got.r_ybot) return 0;
  if (want->r_xtop != got.r_xtop) return 0;
  if (want->r_ytop != got.r_ytop) return 0;

  /* vertices the same? */
  { 
    int i;
    int size = poly->poly_size;
    PointFloat *wantPoint = arg->sea_poly->poly_points;
    PointFloat *gotPoint = poly->poly_points;
   
    for(i = 0; i<size; i++)
    {
      PointFloat pf;
      GeoTransPointF(&scx->scx_trans, gotPoint, &pf);

      if(pf.pf_x != wantPoint->pf_x) return 0;
      if(pf.pf_y != wantPoint->pf_y) return 0;

      wantPoint++;
      gotPoint++;
    }
  }

  /* If only edit-cell polygons are wanted, check this polygons
   * parentage.
   */
  if (arg->sea_editOnly && (scx->scx_use->cu_def != EditCellUse->cu_def))
  {
    if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
    return 0;
  }

  /* call user func */
  arg->sea_func_result = (arg->sea_func)(poly, scx, arg->sea_cdarg);
  return 1;  /* matching polygon was found, abort search 
              * since user func may have modified database.
	      */
}


/* helper func called on wirepaths in SelectDef */
int selEnumWirePathFunc1(SearchContext *scx, 
			 WirePath *wp,
			 ClientData cdarg)
{
  Rect *want, got;
  struct searg *arg = (struct searg *) cdarg;

  /* TODO: mv wirepath equal func to DBpolygon.c */

  /* bounding boxes the same? */
  GeoTransRect(&scx->scx_trans, &wp->wp_bbox, &got);
  want = &arg->sea_wp->wp_bbox;
  if (want->r_xbot != got.r_xbot) return 0;
  if (want->r_ybot != got.r_ybot) return 0;
  if (want->r_xtop != got.r_xtop) return 0;
  if (want->r_ytop != got.r_ytop) return 0;

  /* number of points the same ? */
  if(wp->wp_size != arg->sea_wp->wp_size) return 0;

  /* points the same? */
  { 
    int i;
    int size = wp->wp_size;
    Point *wantPoint = arg->sea_wp->wp_points;
    Point *gotPoint = wp->wp_points;
   
    for(i = 0; i<size; i++)
    {
      Point p;
      GeoTransPoint(&scx->scx_trans, gotPoint, &p);

      if(p.p_x != wantPoint->p_x) return 0;
      if(p.p_y != wantPoint->p_y) return 0;

      wantPoint++;
      gotPoint++;
    }
  }

  /* width the same ? */
  if(wp->wp_width != arg->sea_wp->wp_width) return 0;

  /* style the same ? */
  if(wp->wp_style != arg->sea_wp->wp_style) return 0;

  /* If only edit-cell elements, check this guys
   * parentage.
   */
  if (arg->sea_editOnly && (scx->scx_use->cu_def != EditCellUse->cu_def))
  {
    if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
    return 0;
  }

  /* call user func */
  arg->sea_func_result = (arg->sea_func)(wp, scx, arg->sea_cdarg);

  return 1;  /* matching wirepath was found, abort search 
              * since user func may have modified database.
	      */

}


/*
 * ----------------------------------------------------------------------------
 *
 * SelEnumPaint --
 *
 * 	Find all selected paint, and call the client's procedure for
 *	all the areas of paint that are found.  Only consider paint
 *	on "layers", and if "editOnly" is TRUE, then only consider
 *	paint that is in the edit cell.  The client procedure must
 *	be of the form
 *
 *	int
 *	func(rect, type, clientData)
 *	    Rect *rect;
 *	    TileType type;
 *	    ClientData clientData;
 *	{
 *	}
 *
 *	The rect and type parameters identify the paint that was found,
 *	in root coordinates, and clientData is just the clientData
 *	argument passed to this	procedure.  Func should normally return
 *	0.  If it returns a non-zero return value, then the search
 *	will be aborted.
 *
 * Results:
 *	Returns 0 if the search finished normally.  Returns 1 if the
 *	search was aborted.
 *
 * Side effects:
 *	If foundNonEdit is non-NULL, its target is set to indicate
 *	whether there was selected paint from outside the edit cell.
 *	Otherwise, the only side effects are those of func.
 *
 * ----------------------------------------------------------------------------
 */

int
SelEnumPaint(TileTypeBitMask *layers, 
                            	/* Mask layers to find. */
	     int editOnly, 
                  		/* TRUE means only find material that is
				 * both selected and in the edit cell.
				 */
	     int *foundNonEdit, 
                       		/* If non-NULL, this word is set to TRUE
				 * if there's selected paint that's not in
				 * the edit cell, FALSE otherwise.
				 */
	     int (*func) (/* ??? */), 
                  		/* Function to call for paint that's found. */
	     int (*polyFunc) (/* ??? */), 
                  		/* Function to call for polygons. */
	     int (*wirePathFunc) (/* ??? */), 
                  		/* Function to call for wirepaths */
	     ClientData clientData)
                          	/* Argument to pass through to func */

{
    struct searg arg;

    /* set up searcharg */
    arg.sea_cdarg = clientData;
    arg.sea_editOnly = editOnly;
    arg.sea_nonEdit = foundNonEdit;
    if (foundNonEdit != NULL) *foundNonEdit = FALSE;


    /* visit tiles in selection on given layers */    
    {
      int plane;
      arg.sea_func = func;

      for (plane = PL_SELECTBASE; plane < DBNumPlanes; plane++)
      {
	arg.sea_plane = plane;
	if (DBPlaneEnumAreaPaint((Tile *) NULL, 
				 SelectDef->cd_planes[plane],
				 &TiPlaneRect, 
				 layers, 
				 selEnumPFunc1,
				 (ClientData) &arg) != 0)
	  return 1;
      }
    }

    /* now match polgyons in selection on given layers with 
     * polygons they refer to 
     */
    if(polyFunc && SelectDef->cd_polygons)
    {
      Polygon *poly;

      arg.sea_func = polyFunc;

      for(poly=SelectDef->cd_polygons; poly; poly=poly->poly_next)
      {
	SearchContext scx;     
	CellUse dummy; 
	TileTypeBitMask mask;

	if(!TTMaskHasType(layers, poly->poly_type)) continue;

	arg.sea_poly = poly;
	arg.sea_func_result = 0;

	/* set up scx */
	DBCellInitTempUse(SelectRootDef, &dummy); 
	scx.scx_use = &dummy;
	GEO_EXPAND(&poly->poly_bbox, 1, &scx.scx_area);
	scx.scx_trans = GeoIdentityTransform;
	scx.scx_x = 0; 
	scx.scx_y = 0;

	TTMaskSetOnlyType(&mask, poly->poly_type); 

	/* find (first) matching polygon in database and apply user 
	 * func to it */
	DBSearchPaintNew(&scx, 
			 &mask, 
			 0, 
			 NULL, /* paint func */
			 selEnumPolyFunc1,
			 NULL, /* wirepath func */ 
			 &arg,
			 0 /* flags */);
	if(SigInterruptPending || arg.sea_func_result) return 1;
      }
    }

    /* now match wirepaths in selection on given layers with 
     * wirepaths they refer to 
     */
    if(wirePathFunc && SelectDef->cd_wirePaths)
    {
      WirePath *wp;

      arg.sea_func = wirePathFunc;

      for(wp=SelectDef->cd_wirePaths; wp; wp=wp->wp_next)
      {
	SearchContext scx;     
	CellUse dummy; 
	TileTypeBitMask mask;

	if(!TTMaskHasType(layers, wp->wp_type)) continue;

	arg.sea_wp = wp;
	arg.sea_func_result = 0;

	/* set up scx */
	DBCellInitTempUse(SelectRootDef, &dummy); 
	scx.scx_use = &dummy;
	GEO_EXPAND(&wp->wp_bbox, 1, &scx.scx_area);
	scx.scx_trans = GeoIdentityTransform;
	scx.scx_x = 0; 
	scx.scx_y = 0;

	TTMaskSetOnlyType(&mask, wp->wp_type); 

	/* selEnumWirePathFunc1 terminates search after calling user func.
         * This is important since user func might alter database
         * and hence not safe to continue search.
         */
	DBSearchPaintNew(&scx, 
			 &mask, 
			 0, 
			 NULL,        /* tile func */
			 NULL,        /* polygon func */
			 selEnumWirePathFunc1,
			 &arg,
			 0 /* flags */);
	if(SigInterruptPending || arg.sea_func_result) return 1;
      }
    }

    return 0;
}

/* 
 * =============== CELL (INSTANCE) ENUMERATION =============== 
 */

/* called to set tentative match */
static __inline__ void
selEnumCMatch(struct searg *arg, SearchContext *scx, CellUse *use)
{
  arg->sea_foundUse = use;
  arg->sea_foundTrans = scx->scx_trans; 

  /* stash terminal path */
  if(arg->sea_tPath)
  {
    TerminalPath *tp = arg->sea_tPath;
    TerminalPath *tpf = arg->sea_foundTPath;
    char *s;

    tpf->tp_next=tpf->tp_first;
    s=tp->tp_first;
    while(*s!='\0') *tpf->tp_next++ = *s++;
    *tpf->tp_next = '\0';
  }
}

/* Second-level cell search function:  called for each cell in the
 * tree of SelectRootDef that touches the lower-left corner of
 * the subcell in the selection that we're trying to match.  If
 * this use is for the same subcell, and has the same transformation
 * and array structure, and id, then remember the cell use for the caller
 * and abort the search.
 */

static int
selEnumCFunc2(SearchContext *scx, 
                       		/* Describes child of edit cell. */
	      struct searg *arg)
                      		/* Describes what we're looking for. */
{
    CellUse *use, *selUse;

    use = scx->scx_use;
    selUse = arg->sea_use;

    /* compare def */
    if (use->cu_def != selUse->cu_def) goto checkChildren;

    /* compare trans */
    if ((scx->scx_trans.t_a != selUse->cu_transform.t_a)
	    || (scx->scx_trans.t_b != selUse->cu_transform.t_b)
	    || (scx->scx_trans.t_c != selUse->cu_transform.t_c)
	    || (scx->scx_trans.t_d != selUse->cu_transform.t_d)
	    || (scx->scx_trans.t_e != selUse->cu_transform.t_e)
	    || (scx->scx_trans.t_f != selUse->cu_transform.t_f))
	goto checkChildren;

    /* compare array info */
    if ((use->cu_array.ar_xlo != selUse->cu_array.ar_xlo)
	    || (use->cu_array.ar_ylo != selUse->cu_array.ar_ylo)
	    || (use->cu_array.ar_xhi != selUse->cu_array.ar_xhi)
	    || (use->cu_array.ar_yhi != selUse->cu_array.ar_yhi)
	    || (use->cu_array.ar_xsep != selUse->cu_array.ar_xsep)
	    || (use->cu_array.ar_ysep != selUse->cu_array.ar_ysep))
	goto checkChildren;

    /* tentative match.
     * 
     * There may be multiple matchs since the selection is 
     * flat.  The ids may not match for the same reason.
     *
     * Between tentative matches give priority to ones in 
     * the edit-cell.
     *
     * Secondarily give priority to uses with matching id.
     *
     */
    if(!arg->sea_foundUse) 
    {
      /* no previous match */
      selEnumCMatch(arg,scx,use);
      return 0;
    }

    if (use->cu_parent == EditCellUse->cu_def)
    {
      /* new guy is in the edit cell */
      selEnumCMatch(arg,scx,use);

      if(strcmp(use->cu_id,selUse->cu_id)==0)
      {
	/* exact match! */
	return 1;
      }
      else
      {	
	/* keep looking, may find better match */
	return 0;
      }
    }

    if (arg->sea_foundUse->cu_parent == EditCellUse->cu_def)
    {
      /* previous match in editcell, new guy isn't,
       * keep looking.
       */
      return 0;
    }

    if (strcmp(arg->sea_foundUse->cu_id, selUse->cu_id) != 0)
    {
      /* ids didn't previously match */
      selEnumCMatch(arg,scx,use);
    }
    return 0;

    /***** This cell didn't match, recursively try cells descendents  ****/
    checkChildren:

    /* if def not in memory, don't descend into its children */
    if(!(use->cu_def->cd_flags & CDAVAILABLE)) return 0;

    /* If editOnly, no point descending past edit cell */
    if(arg->sea_editOnly && use->cu_parent == EditCellUse->cu_def) return 0;
    {
      TerminalPath *tp = arg->sea_tPath;      
      char *tnextSave = NULL;  /* initialize to avoid compiler warning */

      /* add scx_use to tPath */
      if (tp)
      {
	tnextSave = tp->tp_next;
	tp->tp_next = DBSrPrintUseId(scx, tp->tp_next, tp->tp_last-tp->tp_next);
	if (tp->tp_next < tp->tp_last)
	{
	    *(tp->tp_next++) = '/';
	    *(tp->tp_next) = '\0';
	}
      }

      /* recursively search descendends of scx_use */
      if (DBSrChildrenNested(scx, selEnumCFunc2, (ClientData) arg) != 0)
      {
	/* search interrupted (leave tPath as is!) */
	return 1;
      }

      /* done with descendends of scx_use, "pop" tPath and continue search */
      if (tp)
      {
	tp->tp_next = tnextSave;
	*tnextSave = '\0';
      }
    }

    return 0;
}

/* The first-level search function:  called for each subcell in the
 * selection.
 */

static int
selEnumCFunc1(SearchContext *scx, 
                       		/* Describes cell that was found. */
	      struct searg *arg)
                      		/* Describes our search. */
{
    /* If this cell is the top-level one in its window, we have to
     * handle it specially:  just look for any use that's a top-level
     * use, then call the client for it.
     */
    
    if (scx->scx_use->cu_def == SelectRootDef)
    {
	CellUse *parent;

	/* A root use can't ever be a child of the edit cell. */

	if (arg->sea_editOnly)
	{
	    if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
	    return 2;
	}
	
	/* Find a top-level use (one with no parent). */

	for (parent = SelectRootDef->cd_uses;
	     parent != NULL;
	     parent = parent->cu_nextuse)
	{
	    if (parent->cu_parent == NULL) break;
	}

	if (parent == NULL)
	{
	    MsgErrorF("Internal error:  couldn't find selected root cell %s.\n",
		SelectRootDef->cd_name);
	    return 2;
	}

	/* make sure "real" use is up-to-date 
         * this is necessary since we are not calling DBSrChildren() as
	 * in the general case below.
	 */
	(void) DBBBoxCellUse(parent);

	/* Call the client. */
	if ((*arg->sea_func)(scx->scx_use, parent, &GeoIdentityTransform, 
			     arg->sea_tPath, arg->sea_cdarg) != 0)
	    return 1;
	return 2;
    }

    /* This isn't a top-level cell.  Find the instance corresponding
     * to this one in the layout.  Only search a 1-unit square at the
     * cell's lower-left corner in order to cut down the work that
     * has to be done.  Unfortunately
     * we can't use DBSearchInstances for this, because we don't want to
     * look at expanded/unexpanded information.
     */
    {
      SearchContext scx2;
      CellUse dummy;
      char *initialNext = NULL;  /* initialize to keep compiler happy */
      TerminalPath *tPath = arg->sea_tPath;

      /* remember initial state of pathname, so we can back up to
       * there for each search
       */
      if(tPath) initialNext = tPath->tp_next;

      /* set up temporary use as "handle" for search */
      DBCellInitTempUse(SelectRootDef, &dummy);
      scx2.scx_use = &dummy;

      GeoTransRect(&scx->scx_use->cu_transform, 
		   DBBBoxCellDef(scx->scx_use->cu_def),
		   &scx2.scx_area);
      scx2.scx_area.r_xtop = scx2.scx_area.r_xbot + 1;
      scx2.scx_area.r_ytop = scx2.scx_area.r_ybot + 1;
      scx2.scx_trans = GeoIdentityTransform;
      arg->sea_use = scx->scx_use;
      arg->sea_foundUse = NULL;

      (void) DBSrChildren(&scx2, selEnumCFunc2, (ClientData) arg);
      if (arg->sea_foundUse == NULL)
      {
	/* no corresponding real use found, probably
	 * due to truncated search.
	 */
	if(arg->sea_editOnly && arg->sea_nonEdit)
	{
	  *arg->sea_nonEdit = TRUE;
	}
	goto keepLooking;
      }

      /* See whether the cell is a child of the edit cell and
       * call the client's procedure if everything's OK.  We do the
       * call here rather than in selEnumCFunc2 because the client
       * could modify the edit cell in a way that would cause the
       * search in progress to core dump.  By the time we get back
       * here, the search is complete so there's no danger.
       */
      if ((arg->sea_editOnly)
	  && (arg->sea_foundUse->cu_parent != EditCellUse->cu_def))
      {
	if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
	goto keepLooking;
      }

      /* do func */
      if ((*arg->sea_func)(scx->scx_use, 
			   arg->sea_foundUse,
			   &arg->sea_foundTrans, 
			   arg->sea_foundTPath, 
			   arg->sea_cdarg) != 0)
      {
	/* func returned non-zero, so abort search */
	return 1;
      }
      
      /* skip (any) other elements of this array, but keep searching */
      keepLooking:

      /* reinitial terminal path */
      if(tPath)
      {
	tPath->tp_next = initialNext;
	*(tPath->tp_next) = '\0';
      }
      
      return 2;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelEnumCells --
 *
 * 	Call a client-supplied procedure for each selected subcell.
 *	If "editOnly" is TRUE, then only consider selected subcells
 *	that are children of the edit cell.  The client procedure
 *	must be of the form
 *
 *	int
 *	func(selUse, realUse, transform, clientData)
 *	    CellUse *selUse;
 *	    CellUse *realUse;
 *	    Transform *transform;
 *          TerminalPath *tPath;
 *	    ClientData clientData;
 *	{
 *	}
 *
 *	SelUse is a pointer to a cellUse that's in the selection cell.
 *	RealUse is a pointer to the corresponding cell that's part of
 *	the layout.  Transform is a transform from the coordinates of
 *	RealUse to root coordinates.  tPath (if nonNull) is set to
 *      path to parent.  
 *
 *      If the cell is an array, only one
 *	call is made for the entire array, and transform is the transform
 *	for the root element of the array (array[xlo, ylo]).  Func should
 *	normally return 0.  If it returns a non-zero return value, then
 *	the search will be aborted.
 *
 *      NOTE:  func may safely modify the database but should not modify
 *             the selection.
 *
 * Results:
 *	Returns 0 if the search finished normally.  Returns 1 if the
 *	search was aborted.
 *
 * Side effects:
 *	If foundNonEdit is non-NULL, its target is set to indicate
 *	whether there were selected cells that weren't children of
 *	the edit cell. 	Otherwise, the only side effects are those
 *	of func.
 *
 * ----------------------------------------------------------------------------
 */

int
SelEnumCells(int editOnly,      /* TRUE means only find material that is
				 * both selected and in the edit cell.
				 */
	     int *foundNonEdit, /* If non-NULL, this word is set to TRUE
				 * if there are one or more selected cells
				 * that aren't children of the edit cell,
				 * FALSE otherwise.
				 */
	     SearchContext *scx, /* Most clients will provide a NULL value
				  * here, in which case all the subcells in
				  * the selection are enumerated.  If this
				  * is non-NULL, it describes a different
				  * area in which to enumerate subcells.  This
				  * feature is intended primarily for internal
				  * use within this module.
				  */
	     TerminalPath *tPath,    /* if nonNull, an initalized TerminalPath
				       * to be filled in with path to parent,
				       * and passed to func.
				       * NOTE: reinitialed before SelEnumCells
				       * returns.
				       */
	     TerminalPath *foundTPath, /* used to stash path to tentative match */
             int (*func)(),          /* Function to call for subcells found. */
	     ClientData clientData)  /* Argument to pass through to func. */
{
    struct searg arg;
    SearchContext scx2;

    arg.sea_func = func;
    arg.sea_cdarg = clientData;
    arg.sea_editOnly = editOnly;
    arg.sea_nonEdit = foundNonEdit;
    arg.sea_foundTPath = foundTPath;
    arg.sea_tPath = tPath;    /* current tpath */

    if (foundNonEdit != NULL) *foundNonEdit = FALSE;

    /* Process all the subcells that are in the selection. */
    if (scx != NULL)
	scx2 = *scx;
    else
    {
	scx2.scx_use = SelectUse;
	scx2.scx_area = TiPlaneRect;
	scx2.scx_trans = GeoIdentityTransform;
    }
    if (DBSrChildren(&scx2, selEnumCFunc1, (ClientData) &arg) != 0) return 1;
    return 0;
}

/* 
 * =============== LABEL ENUMERATION =============== 
 */

/* Search function for label enumeration:  make sure that this label
 * matches the one we're looking for.  If it does, then record
 * information about it and return right away.
 */

static int
selEnumLFunc(SearchContext *scx, Label *label, TerminalPath *tPath, struct searg *arg)
                       		/* Describes current cell for search. */
                 		/* Describes label that is in right area
				 * and has right type.
				 */
                        	/* Ignored. */
                      		/* Indicates what we're looking for. */
{
    arg->sea_foundLabel = label;

    /* If only edit-cell labels are wanted, check this label's
     * parentage.
     */
    if (arg->sea_editOnly && (scx->scx_use->cu_def != EditCellUse->cu_def))
    {
      if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
      return 0;
    }

    /* call user func */
    arg->sea_func_result = (arg->sea_func)(label,
				    scx->scx_use->cu_def,
				    &(scx->scx_trans),
				    tPath, 
				    arg->sea_cdarg);


   /* Terminate search (this is important since user func may have
    *  altered database.
    */
   return 1;
}


/* Search function for label enumeration:  make sure that this label
 * matches the one we're looking for.  If it does, then record
 * information about it and return right away.
 *
 * This version does not terminate search after first match!
 */

	/* ARGSUSED */
static int
selEnumLFuncAll(SearchContext *scx, Label *label, TerminalPath *tPath, struct searg *arg)
                       		/* Describes current cell for search. */
                 		/* Describes label that is in right area
				 * and has right type.
				 */
                        	/* Ignored. */
                      		/* Indicates what we're looking for. */
{
    arg->sea_foundLabel = label;

    /* If only edit-cell labels are wanted, check this label's
     * parentage.
     */
    if (arg->sea_editOnly && (scx->scx_use->cu_def != EditCellUse->cu_def))
    {
      if (arg->sea_nonEdit != NULL) *(arg->sea_nonEdit) = TRUE;
      return 0;
    }

    /* caller user func */
    arg->sea_func_result = (arg->sea_func)(label,
				    scx->scx_use->cu_def,
				    &(scx->scx_trans),
				    tPath, 
				    arg->sea_cdarg);


   /* Continue search - if user modifed database, we are in trouble! */
   return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelEnumLabels --
 *
 * 	Find all selected labels, and call the client's procedure for
 *	each label found.  Only consider labels attached to "layers",
 *	and if "editOnly" is TRUE, then only consider labels that
 *	are in the edit cell.  The client procedure must be of the
 *	form
 *
 *	int
 *	func(label, cellDef, transform, tpath, clientData)
 *	    Label *label;
 *	    CellDef *cellDef;
 *	    Transform *transform;
 *          TerminalPath *tpath;   
 *	    ClientData clientData;
 *	{
 *	}
 *
 *	Label is a pointer to a selected label.  It refers to the label
 *	in cellDef, and transform gives the transform from that
 *	cell's coordinates to root coordinates.  Terminal path gives
 *      hierarchical name of the instance containing the label.
 *      ClientData is just
 *	the clientData argument passed to this procedure.  Func
 *	should normally return 0.  If it returns a non-zero return
 *	value, then the search will be aborted.
 *
 *      NOTE:  user function may safely modify database, but should not
 *      modify selection during enumeration.
 *
 * Results:
 *	Returns 0 if the search finished normally.  Returns 1 if the
 *	search was aborted.
 *
 * Side effects:
 *	If foundNonEdit is non-NULL, its target is set to indicate
 *	whether there was at least one selected label that was not
 *	in the edit cell.  Otherwise, the only side effects are
 *	those of func.
 *
 * ----------------------------------------------------------------------------
 */

int
SelEnumLabels(TileTypeBitMask *layers, /* Find labels on these layers. */
	      int editOnly,	       /* TRUE means only find labels that are
		                        * both selected and in the edit cell.
                                        */
	      bool *foundNonEdit,      /* If non-NULL, this word is set to TRUE
					* if there are selected labels that aren't
					* in the edit cell, FALSE otherwise.
					*/
	      TerminalPath *tPath,     /* if nonNull, an initalized TerminalPath
					* to be filled in with instance path name
					* and passed to func
					* NOTE: note reinitialed before SelEnumLabels
					* returns.
					*/
	      int (*func) (/* ??? */),  /* Function to call for each label found. */
	      ClientData clientData)    /* Argument to pass through to func. */
{
    register Label *selLabel;
    CellUse dummy;
    SearchContext scx;
    struct searg arg;
    char *initialNext = NULL;  /* initialize to keep compiler happy */

    if (foundNonEdit != NULL) *foundNonEdit = FALSE;

    /* remember initial state of pathname, so we can back up to
     * there for each search
     */
    if(tPath) initialNext = tPath->tp_next;

    /* Loop on all selected labels */

    for (selLabel = SelectDef->cd_labels; selLabel != NULL;
	    selLabel = selLabel->lab_next)
    {
	if (!TTMaskHasType(layers, selLabel->lab_type)) continue;

	/* reinitial terminal path */
	if(tPath)
	{
	  tPath->tp_next = initialNext;
	  *(tPath->tp_next) = '\0';
	}

	/* Find the label corresponding to this one in the design and call
	 * user func on it */
	DBCellInitTempUse(SelectRootDef, &dummy);
	scx.scx_use = &dummy;
	GEO_EXPAND(&selLabel->lab_rect, 1, &scx.scx_area);
	scx.scx_trans = GeoIdentityTransform;
	arg.sea_label = selLabel;
	arg.sea_editOnly = editOnly;
	arg.sea_nonEdit = foundNonEdit;
	arg.sea_foundLabel = NULL;
	arg.sea_func = func;
	arg.sea_cdarg = clientData;
	arg.sea_func_result = 0;

	/* selEnumLFunc terminates search after calling user func.
         * This is important since user func might alter database
         * and hence not safe to continue search.
         */
	(void) DBSearchLabels2(&scx, 
			       &DBAllTypeBits, 
			       &selLabel->lab_rect,
			       selLabel->lab_text,
			       0, 
			       tPath,
			       selEnumLFunc, 
			       (ClientData) &arg,
			       0);

	if (arg.sea_foundLabel == NULL)
	{
	    MsgErrorF("Internal error:  couldn't find selected label %s.\n",
		selLabel->lab_text);
	    continue;
	}

	if(arg.sea_func_result == 1) return 1;
    }
    return 0;
}

/* 
 *       same as SelEnumLabels - but does not stop search when user func called.
 *       THIS MEANS USER FUNC MUST NOT alter database!
 */      
int
SelEnumLabelsAll(TileTypeBitMask *layers, /* Find labels on these layers. */
	      int editOnly,	       /* TRUE means only find labels that are
		                        * both selected and in the edit cell.
                                        */
	      bool *foundNonEdit,      /* If non-NULL, this word is set to TRUE
					* if there are selected labels that aren't
					* in the edit cell, FALSE otherwise.
					*/
	      TerminalPath *tPath,     /* if nonNull, an initalized TerminalPath
					* to be filled in with instance path name
					* and passed to func
					* NOTE: note reinitialed before SelEnumLabels
					* returns.
					*/
	      int (*func) (/* ??? */),  /* Function to call for each label found. */
	      ClientData clientData)    /* Argument to pass through to func. */
{
    register Label *selLabel;
    CellUse dummy;
    SearchContext scx;
    struct searg arg;
    char *initialNext = NULL;  /* initialize to avoid compiler warning */

    if (foundNonEdit != NULL) *foundNonEdit = FALSE;

    /* remember initial state of pathname, so we can back up to
     * there for each search
     */
    if(tPath) initialNext = tPath->tp_next;

    /* Loop on all selected labels */

    for (selLabel = SelectDef->cd_labels; selLabel != NULL;
	    selLabel = selLabel->lab_next)
    {
	if (!TTMaskHasType(layers, selLabel->lab_type)) continue;

	/* reinitial terminal path */
	if(tPath)
	{
	  tPath->tp_next = initialNext;
	  *(tPath->tp_next) = '\0';
	}

	/* Find the label corresponding to this one in the design and call
	 * user func on it */
	DBCellInitTempUse(SelectRootDef,&dummy);
	scx.scx_use = &dummy;
	GEO_EXPAND(&selLabel->lab_rect, 1, &scx.scx_area);
	scx.scx_trans = GeoIdentityTransform;
	arg.sea_label = selLabel;
	arg.sea_editOnly = editOnly;
	arg.sea_nonEdit = foundNonEdit;
	arg.sea_foundLabel = NULL;
	arg.sea_func = func;
	arg.sea_cdarg = clientData;
	arg.sea_func_result = 0;

	(void) DBSearchLabels2(&scx, 
			       &DBAllTypeBits,
			       &selLabel->lab_rect,
			       selLabel->lab_text,
			       0, 
			       tPath,
			       selEnumLFuncAll, 
			       (ClientData) &arg,
			       0);

	if (arg.sea_foundLabel == NULL)
	{
	    MsgErrorF("Internal error:  couldn't find selected label %s.\n",
		selLabel->lab_text);
	    continue;
	}

	if(arg.sea_func_result == 1) return 1;
    }
    return 0;
}









