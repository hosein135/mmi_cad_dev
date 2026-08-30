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

/*
 * DBsearch.c --
 *
 * Hierarchical area searches

 * SEARCH CONTEXTS:
 * ---------------
 * All of the routines in this file use a SEARCH CONTEXT (scx):
 *
 *   CellUse	*scx_use;	 Pointer to cell use currently searched 
 *   int	 scx_x, scx_y;	 X and Y array elementS if scx_use is array 
 *   Rect	 scx_area;	 Area searched in scx_use->cu_def coords 
 *   Transform	 scx_trans;	 Composite transform from coordinates
 *				 of the cell use (scx_use) all the way
 *				 back to those of the "root" of the
 *				 search.
 *
 * SEE ALSO:
 * --------
 *  DBnext.c   - finding nearby edges, and width changes. 
 *  DBplane.c  - searches involving single tile planes.
 *  Tile1.c    - tile plane primitives. 
 * 
 *  NOMENCLATURE:
 *  ------------
 *
 *   DBSearch...   (e.g. DBSearchPaintNew)
 *    these are the primary database search routines.  They search areas
 *    hierarchically down the database.  Descending into expanded subcells
 *    (if xMask arg = xmask of layout window) or all subcells (if xMask arg = 0).
 *    These routines all take a Search Context (scx as arg) and use an additional
 *    Tree Context structure internally to keep track of xMask and the client
 *    routine to call.
 *
 *   ...NR
 *     The suffix NR is used to designate variants of some of the search
 *     routines in this file.  It stands for "Non Recursive" and means that
 *     the search does not descend recursively into subcells of the initial
 *     def (scx->scx_use->cu_def).
 *
 *   DBSr...
 *     these are search support routines that take a Search Context (scx), 
 *     as arg.
 *
 *   DBPlane...
 *     these routines (in DBplane.c) act on individual paint planes not
 *     hierarchical cell structures.
 *
 *   DBEnum...
 *     These routines (in DBenum.c) are enumerations (or "searches") that 
 *     do not use Search Contexts.
 *    
 *
 *
 *  DESCENT INTO SUBCELLS:  
 *  ---------------------
 *      If the search routine has an NR suffix ("non recursive") it does not
 *      descend into subcells, otherwise it generally descends into either 
 *      expanded subcells (xMask arg = xmask of layout window) or ALL subcells
 *      (xMask arg = 0).
 *
 */

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "signals.h"
#include "utils.h"
#include "debug.h"


/*
 *-----------------------------------------------------------------------------
 *
 * DBSrChildren --
 *
 * Apply the supplied procedure to each of the cellUses found in the
 * given area in the subcell plane of the child def of the supplied
 * search context.
 *
 * The procedure is applied to each array element in each cell use that
 * overlaps the clipping rectangle.  The scx_x and scx_y parts of
 * the SearchContext passed to the filter function correspond to the
 * array element being visited.  The same CellUse is, of course, passed
 * as scx_use for all elements of the array.
 *
 * The array elements are visited by varying the X coordinate fastest.
 *
 * The procedure should be of the following form:
 *	int
 *	func(scx, cdarg)
 *	    SearchContext *scx;
 *	    ClientData cdarg;
 *	{
 *	}
 *
 * Func normally returns 0.  If it returns 1 then the search is
 * aborted.  If it returns 2, then any remaining elements in the
 * current array are skipped.
 *
 * Results:
 *	0 is returned if the search terminated normally.  1 is
 *	returned if it was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *--------------------------------------------------------------------------1---
 */

int
DBSrChildrenNested(register SearchContext *scx, 
			/* Pointer to search context specifying a cell use to
			 * search, an area in the coordinates of the cell's
			 * def, and a transform back to "root" coordinates.
			 * The area may have zero size.
			 */
		   int (*func) (/* ??? */), 
                  	/* Function to apply at every tile found */
		   ClientData cdarg)
                     	/* Argument to pass to function */
{
  BPEnum bpe;
  CellUse *use;

  /*
  fprintf(stderr,"DEBUG DBSrChildren cell=%s\n",
	  scx->scx_use->cu_def->cd_name);
  DumpRect("DEBUG DBSrChildren area= ",&scx->scx_area);
  */

  /* read in cell if necessary */
  if ((scx->scx_use->cu_def->cd_flags & CDAVAILABLE) == 0)
  {
    if (!DBCellRead(scx->scx_use->cu_def, (char *) NULL, TRUE)) return 0;
  }

  /* make sure def is up-to-date, BUT DO NOT
   * adjust bbox of top use (to avoid changing cellPlane of parent,
   * since this can screw up a "parent" DBSrChildren() that is in progress
   *
   * NOTE: may no longer be an issue now that we are using bplanes for
   * the cellplanes?
   */
  (void) DBUpdate(scx->scx_use->cu_def);

  BPEnumInit(&bpe,
	     scx->scx_use->cu_def->cd_cellPlane,
	     &scx->scx_area,
	     BPE_OVERLAP,
	     "DBSrChildren");

  while(use = BPEnumNext(&bpe)) 
  {
    register Rect *bbox;
    SearchContext newScx;
    Transform t, tinv;

    /*
    fprintf(stderr,"DEBUG DBSrChildren use=%s\n",
	    use->cu_def->cd_name);
    */

    newScx.scx_use = use;
    if (use->cu_xlo == use->cu_xhi && use->cu_ylo == use->cu_yhi)
    {
      /* non-array case */

      newScx.scx_x = use->cu_xlo;
      newScx.scx_y = use->cu_yhi;

      if (SigInterruptPending) goto abort;

      GEOINVERTTRANS(&use->cu_transform, &tinv);
      GeoTransTrans(&use->cu_transform, 
		    &scx->scx_trans,
		    &newScx.scx_trans);
      GEOTRANSRECT(&tinv, 
		   &scx->scx_area, 
		   &newScx.scx_area);

      if ((*func)(&newScx, cdarg) == 1) goto abort;
    } 
    else
    {
      /* array case */

      int xlo, xhi, ylo, yhi, xbase, ybase, xsep, ysep, clientResult;

      DBArrayOverlap(use, &scx->scx_area, &xlo, &xhi, &ylo, &yhi);
      xsep = (use->cu_xlo > use->cu_xhi) ? -use->cu_xsep : use->cu_xsep;
      ysep = (use->cu_ylo > use->cu_yhi) ? -use->cu_ysep : use->cu_ysep;

      for (newScx.scx_y = ylo; newScx.scx_y <= yhi; newScx.scx_y++)
      {
	for (newScx.scx_x = xlo; newScx.scx_x <= xhi; newScx.scx_x++)
	{
	  bool clientResult;

	  if (SigInterruptPending) goto abort;

	  xbase = xsep * (newScx.scx_x - use->cu_xlo);
	  ybase = ysep * (newScx.scx_y - use->cu_ylo);
	  
	  GeoTransTranslate(xbase, ybase, &use->cu_transform, &t);
	  GEOINVERTTRANS(&t, &tinv);
	  GeoTransTrans(&t, &scx->scx_trans, &newScx.scx_trans);
	  GEOTRANSRECT(&tinv, &scx->scx_area, &newScx.scx_area);

	  clientResult = (*func)(&newScx, cdarg);
	  if (clientResult == 2) goto skipArray;
	  if (clientResult == 1) goto abort;
	}
      }
    }
    skipArray: ;
  } /* while BPEnumNext()*/

  BPEnumTerm(&bpe);
  return 0;

abort:
  BPEnumTerm(&bpe);
  return 1;
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBSrPrintUseId --
 *
 * Generate the print name of the use identifier indicated by the supplied
 * SearchContext.
 *
 * Results:
 *	Returns a pointer to the NULL byte at the end of the string
 *	generated.
 *
 * Side effects:
 *	The character string pointed to by name is set to contain the use
 *	id of scx->scx_use followed by any array indices.  If scx->scx_use
 *	is a two dimensional array, the array indices are of the form [y,x],
 *	otherwise there is a single array index either of the form [y] or [x].
 *	The array indices are taken from scx->scx_x and scx->scx_y.  At most
 *	size characters are copied into the string pointed to by name.
 *
 *-----------------------------------------------------------------------------
 */

char *
DBSrPrintUseId(SearchContext *scx, char *name, int size)
                       	/* Pointer to current search context, specifying a
			 * cell use and X,Y array indices.
			 */
               		/* Pointer to string into which we will copy the
			 * print name of this instance.
			 */
             		/* Maximum number of characters to copy into string. */
{
    register CellUse *use = scx->scx_use;
    register char *sp, *id, *ep;
    char indices[100];

    if ((id = use->cu_id) == (char *) NULL)
    {
	name[0] = '\0';
	return (name);
    }

    for (sp = name, ep = &name[size]; (sp < ep) && *id; *sp++ = *id++)
	/* Nothing */;

    if (use->cu_xlo != use->cu_xhi || use->cu_ylo != use->cu_yhi)
    {
	if (use->cu_xlo == use->cu_xhi)
	    (void) sprintf(indices, "[%d]", scx->scx_y);
	else if (use->cu_ylo == use->cu_yhi)
	    (void) sprintf(indices, "[%d]", scx->scx_x);
	else
	    (void) sprintf(indices, "[%d,%d]", scx->scx_y, scx->scx_x);

	for (id = indices; (sp < ep) && *id; *sp++ = *id++)
	    /* Nothing */;
    }

    if (sp == ep)
	sp--;
    *sp = '\0';

    return (sp);
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBSearchPaintNew2 --
 *
 * Recursively search downward from the supplied CellUse for
 * all visible paint tiles and/or polygons matching the supplied type mask.
 *
 * The callback procedures should be of the following form:
 *	int func(Tile *tile,TreeContext *cxp);
 *	int polygonFunc(SearchContext *scx, 
 *                      Polygon *poly, 
 *                      ClientData cdarg)
 *	int wirePathFunc(SearchContext *scx, 
 *			 WirePath *wp, 
 *			 ClientData cdarg)
 *
 * If tpath is nonnull a 4th tpath arg is appended to polygonFunc() and
 * wirePathFunc().
 *
 * To search only tiles or only polygons set the other func arg to NULL.
 *
 * The SearchContext is stored in cxp->tc_scx, and the user's arg is stored
 * in cxp->tc_filter->tf_arg.
 *
 * In the above, the scx transform is the net transform from the coordinates
 * of tile to "world" coordinates (or whatever coordinates the initial
 * transform supplied to DBSearchPaint was a transform to).  Func and 
 * polygonFunc return 0 under normal conditions.  If 1 is returned, 
 * it is a request to abort the search.
 *
 *			*** WARNING ***
 *
 * The client procedure should not modify any of the paint planes in
 * the cells visited by DBSearchPaint, because we use DBPlaneEnumAreaPaint
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
  
/* helper func to do one def (ignoring subcells) */
static __inline__ int dbSearchPaintDef(CellDef *def,
				       SearchContext *scx, 
				       TreeFilter *fp)
{
    int groupFlag = fp->tf_flags&DBSP_GROUP; 
    int dependFlag = fp->tf_flags&DBSP_DEPENDENT_POLYGONS; 
    Group *group = def->cd_activeGroup;

    /*
     * Apply the function first to any of the tiles in the planes
     * for this CellUse's CellDef that match the mask.
     */

    /* paint tiles in this def */
    if(fp->tf_func)
    {
      PlaneList *pll;
      TreeContext context;

      context.tc_scx = scx;
      context.tc_filter = fp;

      for(pll = fp->tf_planes; pll; pll = pll->pll_next)
      {
	if(groupFlag)
	{
	  if (DBPlaneEnumAreaPaintG((Tile *) NULL, 
				    def->cd_planes[pll->pll_num],
				    &scx->scx_area, 
				    fp->tf_mask,
				    group,
				    fp->tf_func, 
				    (ClientData) &context))
	    return 1;
	}
	else
	{
	  if (DBPlaneEnumAreaPaint((Tile *) NULL, 
				   def->cd_planes[pll->pll_num],
				   &scx->scx_area, 
				   fp->tf_mask,
				   fp->tf_func, 
				   (ClientData) &context))
	    return 1;
	}
      }
    }

    if(fp->tf_tpath)
    {
      /* TPATH */

      /* polygons in this def */
      if(fp->tf_polygonFunc)
      {
	register Polygon *poly;
	register TileTypeBitMask *mask = fp->tf_mask; 
	register Rect *r = &scx->scx_area;

	for (poly = def->cd_polygons; poly; poly = poly->poly_next)
	{
	  if (TTMaskHasType(mask, poly->poly_type) &&
	      (!groupFlag || poly->poly_group == group) &&
	      (dependFlag || !poly->poly_wirePath) &&
	      DBPolygonIntersectRectQ(poly, r))
	  {
	    if ((*fp->tf_polygonFunc)(scx, 
				      poly, 
				      fp->tf_arg,
				      fp->tf_tpath)) return 1;
	  }
	}
      }

      /* wirepaths in this def */
      if(fp->tf_wirePathFunc)
      {  
	register WirePath *wp;
	register TileTypeBitMask *mask = fp->tf_mask; 
	register Rect *r = &scx->scx_area;

	for (wp = def->cd_wirePaths; wp; wp = wp->wp_next)
        {
	  if (TTMaskHasType(mask, wp->wp_type) &&
	      (!groupFlag || wp->wp_group == group) && 
	      DBWirePathIntersectRectQ(def, wp, r))
	  {
	    if ((*fp->tf_wirePathFunc)(scx, 
				       wp, 
				       fp->tf_arg,
				       fp->tf_tpath)) return 1;
	  }
	}
      }
    }
    else
    {
      /* NO TPATH */

      /* polygons in this def */
      if(fp->tf_polygonFunc)
      {
	register Polygon *poly;
	register TileTypeBitMask *mask = fp->tf_mask; 
	register Rect *r = &scx->scx_area;

	for (poly = def->cd_polygons; poly; poly = poly->poly_next)
	{
	  if (TTMaskHasType(mask, poly->poly_type) &&
	      (!groupFlag || poly->poly_group == group) &&
	      (dependFlag || !poly->poly_wirePath) &&
	      DBPolygonIntersectRectQ(poly, r))
	  {
	    if ((*fp->tf_polygonFunc)(scx, poly, fp->tf_arg)) return 1;
	  }
	}
      }

      /* wirepaths in this def */
      if(fp->tf_wirePathFunc)
      {
	register WirePath *wp;
	register TileTypeBitMask *mask = fp->tf_mask; 
	register Rect *r = &scx->scx_area;

	for (wp = def->cd_wirePaths; wp; wp = wp->wp_next)
        {
	  if (TTMaskHasType(mask, wp->wp_type) &&
	      (!groupFlag || wp->wp_group == group) && 
	      DBWirePathIntersectRectQ(def, wp, r))
	    
	  {
	    if ((*fp->tf_wirePathFunc)(scx, wp, fp->tf_arg)) return 1;
	  }
	}
      }
    }

    return 0;
}

/* filter func for DBSearchPaintNew() */
static int
dbSearchPaintNewFunc(register SearchContext *scx, register TreeFilter *fp)
{
    CellDef *def = scx->scx_use->cu_def;
    char *tnext = NULL;  /* initialize to avoid warning */
    int result;

    ASSERT(def != (CellDef *) NULL, "dbSearchPaintNewFunc");
    if (!DBIsExpand(scx->scx_use, fp->tf_xmask))
	return 0;
    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;

    /* add useid to terminal path */
    if (fp->tf_tpath != (TerminalPath *) NULL)
    {
      register TerminalPath *tp = fp->tf_tpath;
      tnext = tp->tp_next; 

      tp->tp_next = DBSrPrintUseId(scx, 
				   tp->tp_next, 
				   tp->tp_last-tp->tp_next);
      if (tp->tp_next < tp->tp_last)
      {
	*(tp->tp_next++) = '/';
	*(tp->tp_next) = '\0';
      }
    }

    /* do this def */
    if (dbSearchPaintDef(def, scx, fp))
    {
      result = 1;
      goto cleanup;
    }

    /*
     * Now apply ourselves recursively to each of the CellUses
     * in our tile plane.
     */

    if (DBSrChildrenNested(scx, dbSearchPaintNewFunc, (ClientData) fp))
    {
      result = 1;
    }
    else 
    {
      result = 0;
    }

cleanup:
    /* Remove the trailing pathname component from the TerminalPath */
    if (fp->tf_tpath != (TerminalPath *) NULL)
    {
	fp->tf_tpath->tp_next = tnext;
	*tnext = '\0';
    }

    return (result);
}

int
DBSearchPaintNew2(SearchContext *scx, 
                       		/* Pointer to search context specifying
				 * a cell use to search, an area in the
				 * coordinates of the cell's def, and a
				 * transform back to "root" coordinates.
				 */
		  TileTypeBitMask *mask, 
                          	/* Only tiles with a type for which
				 * a bit in this mask is on are processed.
				 */
		  int xMask, 
              			/* All subcells are visited recursively
				 * until we encounter uses whose flags,
				 * when anded with xMask, are not
				 * equal to xMask.
				 */
		  TerminalPath *tpath, 
                        	/* Pointer to a structure describing a
				 * partially filled in terminal pathname.
				 * If this pointer is NULL, we don't bother
				 * filling it in further; otherwise, we add
				 * new pathname components as we encounter
				 * them.
				 */
		  int (*func) (), 
                  		/* Function to apply at each qualifying tile */
		  int (*polygonFunc) (),
		                /* Function to apply at each qualified polygon */
		  int (*wirePathFunc) (),
		                /* Function to apply at each qualified wirepath */
		  ClientData cdarg,
                     		/* Client data for above function */
		  int flags)		 
                                /* DBSP_*, see database.h for list */

{
    TreeFilter filter;
    CellUse *cellUse = scx->scx_use;
    CellDef *def = cellUse->cu_def;
    int retValue = 0; 

    ASSERT(def != (CellDef *) NULL, "DBSearchPaintNew");
    if (!DBIsExpand(cellUse, xMask))
	return 0;

    /* read def from disk, if necessary */
    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;

    filter.tf_func = func;
    filter.tf_polygonFunc = polygonFunc;
    filter.tf_wirePathFunc = wirePathFunc;
    filter.tf_arg = cdarg;
    filter.tf_mask = mask;
    filter.tf_xmask = xMask;
    filter.tf_tpath = tpath;   
    /* tf_planes only used for paint func */
    filter.tf_planes = (func) ? DBPlaneListFromTypes(mask) : NULL;
    filter.tf_flags = flags;

    /* do toplevel def */
    if (dbSearchPaintDef(def, scx, &filter)) 
    {
      retValue = 1;
      goto done;
    }

    /* if non recursive, we are done */
    if(flags&DBSP_NON_RECURSIVE) goto done;

    /* Apply recursively to subcells */
    if (DBSrChildren(scx, dbSearchPaintNewFunc, (ClientData) &filter))
    {
      retValue = 1;
      goto done;
    }

done:
    if(filter.tf_planes) PlaneListFree(filter.tf_planes);
    return retValue;
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBSearchLabels2 --
 *
 * Recursively search downward from the supplied CellUse for
 * all visible labels attached to layers matching the supplied
 * type mask.
 *
 * The procedure should be of the following form:
 *	int
 *	func(scx, label, tpath, cdarg)
 *	    SearchContext *scx;
 *	    Label *label;
 *	    TerminalPath *tpath;
 *	    ClientData cdarg;
 *	{
 *	}
 *
 * In the above, the use associated with scx is the parent of the
 * CellDef containing the tile which contains the label, and the
 * transform associated is the net transform from the coordinates
 * of the tile to "root" coordinates.  Func normally returns 0.  If
 * func returns 1, it is a request to abort the search without finding
 * any more labels.
 *
 * Results:
 *	0 is returned if the search terminated normally.  1 is returned
 *	if the search was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *-----------------------------------------------------------------------------
 */

/* filter func for DBSearchLabels() */
static int
dbSearchLabelsFunc(register SearchContext *scx, register TreeFilter *fp)
{
    register Label *lab;
    register Rect *r = &scx->scx_area;
    register TileTypeBitMask *mask = fp->tf_mask;
    char *text = fp->tf_text;
    Rect *loc = fp->tf_loc;
    CellDef *def = scx->scx_use->cu_def;
    char *tnext = NULL;  /* initialize to avoid warning */ 
    int result;

    ASSERT(def != (CellDef *) NULL, "dbSearchLabelsFunc");
    if (!DBIsExpand(scx->scx_use, fp->tf_xmask)) return 0;
    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;
    
    if (fp->tf_tpath != (TerminalPath *) NULL)
    {
	register TerminalPath *tp = fp->tf_tpath;

	tnext = tp->tp_next;

	tp->tp_next = DBSrPrintUseId(scx, 
				     tp->tp_next, 
				     tp->tp_last-tp->tp_next);
	if (tp->tp_next < tp->tp_last)
	{
	    *(tp->tp_next++) = '/';
	    *(tp->tp_next) = '\0';
	}
    }

    /* Apply the function first to any of the labels in this def. */

    result = 0;
    if(loc)
    {
      Transform inverseTrans;
      Rect locLocal;

      /* translate location to coords of this def */ 
      GeoInvertTrans(&scx->scx_trans, &inverseTrans);
      GEOTRANSRECT(&inverseTrans, loc, &locLocal);

      for(lab = IHashLookUp(def->cd_labelLocHash,&locLocal);
      lab;
      lab = IHashLookUpNext(def->cd_labelLocHash,lab))
      {
	if (GEO_OVERLAP(&lab->lab_rect, r) &&
	    TTMaskHasType(mask, lab->lab_type) &&
	    strcmp(text,lab->lab_text) == 0)
	{
	    if ((*fp->tf_func)(scx, lab, fp->tf_tpath, fp->tf_arg))
	    {
		result = 1;
		goto cleanup;
	    }
	}
      }
    }
    else if(text)
    {
      for(lab = IHashLookUp(def->cd_labelHash,text);
      lab;
      lab = IHashLookUpNext(def->cd_labelHash,lab))
      {
	if (GEO_OVERLAP(&lab->lab_rect, r) &&
	    TTMaskHasType(mask, lab->lab_type))
	{
	    if ((*fp->tf_func)(scx, lab, fp->tf_tpath, fp->tf_arg))
	    {
		result = 1;
		goto cleanup;
	    }
	}
      }
    }
    else
    {
      for (lab = def->cd_labels; 
	   lab; 
	   lab = lab->lab_next)
      {
	if (GEO_OVERLAP(&lab->lab_rect, r) &&
	    TTMaskHasType(mask, lab->lab_type))
	{
	    if ((*fp->tf_func)(scx, lab, fp->tf_tpath, fp->tf_arg))
	    {
		result = 1;
		goto cleanup;
	    }
	}
      }
    }

    /* Now visit each child use recursively */
    if (DBSrChildrenNested(scx, dbSearchLabelsFunc, (ClientData) fp))
	result = 1;

cleanup:
    /* Remove the trailing pathname component from the TerminalPath */
    if (fp->tf_tpath != (TerminalPath *) NULL)
    {
	fp->tf_tpath->tp_next = tnext;
	*tnext = '\0';
    }

    return (result);
}

int 
DBSearchLabels2(SearchContext *scx, 
                       		/* Pointer to search context specifying
				 * a cell use to search, an area in the
				 * coordinates of the cell's def, and a
				 * transform back to "root" coordinates.
				 * The area may have zero size.  Labels
				 * need only touch the area.
				 */
		TileTypeBitMask *mask, 
                           	/* Only visit labels attached to these types */
		Rect *loc,      /* if non-null visit only labels with this
				 * location (exactly).
				 */
		char *text,
		                /* If non-null, only visit labels with matching
				 * lab_text.
				 */

		int xMask, 
              			/* All subcells are visited recursively
				 * until we encounter uses whose flags,
				 * when anded with xMask, are not
				 * equal to xMask.
				 */
		TerminalPath *tpath, 
                        	/* Pointer to a structure describing a
				 * partially filled in terminal pathname.
				 * If this pointer is NULL, we don't bother
				 * filling it in further; otherwise, we add
				 * new pathname components as we encounter
				 * them.
				 */
	       int (*func) (/* ??? */), 
                  		/* Function to apply at each qualifying tile */
	       ClientData cdarg,
                     		/* Client data for above function */
	       int flags)
{
    SearchContext scx2;
    register Label *lab;
    register Rect *r = &scx->scx_area;
    CellUse *cellUse = scx->scx_use;
    CellDef *def = cellUse->cu_def;
    TreeFilter filter;
    bool nonRecursive = flags&DBSL_NON_RECURSIVE;

    ASSERT(def != (CellDef *) NULL, "DBSearchLabels");
    if (!DBIsExpand(cellUse, xMask)) return 0;
    if ((def->cd_flags & CDAVAILABLE) == 0)
    {
      if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;
    }

    /* if path given, descend it recursively */
    {
      char *slash;
      
      while(text && (slash=strchr(text,'/')))
      {
	CellUse *cu;
	char id[BUFSIZ];
	char *p,*q;

	/* if slash present, use exact path only */
	nonRecursive = TRUE;

	/* peel of toplevel instance id */
	p=text;
	q=id;
	while(p!=slash) *(q++) = *(p++);
	*q='\0';
	text = slash+1;

	/* find corresponding instance */
	cu = DBInstanceFindByName(id,def);
	if(!cu) return 0;

	/* adjust scx */
	{
	  SearchContext newScx;
	  Transform tinv;

	  newScx.scx_use = cu;

	  /* TODO parse array subscripts! */
	  newScx.scx_x = 0;
	  newScx.scx_y = 0;

	  GEOINVERTTRANS(&cu->cu_transform, &tinv);	

	  GeoTransTrans(&cu->cu_transform, 
			&scx->scx_trans,
			&newScx.scx_trans);

	  GEOTRANSRECT(&tinv, 
		       &scx->scx_area, 
		       &newScx.scx_area);
	  *scx = newScx;
	}

	/* add useid to terminal path */
	if (tpath)
        {
	  char *tnext = tpath->tp_next; 

	  tpath->tp_next = DBSrPrintUseId(scx, 
					  tpath->tp_next, 
					  tpath->tp_last-tpath->tp_next);
	  if (tpath->tp_next < tpath->tp_last)
	  {
	    *(tpath->tp_next++) = '/';
	    *(tpath->tp_next) = '\0';
	  }
	}

	/* descend into instance */
	r = &scx->scx_area;
	cellUse = scx->scx_use;
	def = cellUse->cu_def;

	if (!DBIsExpand(cellUse, xMask)) return 0;
	if ((def->cd_flags & CDAVAILABLE) == 0)
	{
	  if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;
	}
      }
    }

    /* PROCESS TOP DEF */ 
    if(loc)
    {
      /* use location-based hash to narrow search! */
      for(lab = IHashLookUp(def->cd_labelLocHash,loc);
      lab;
      lab = IHashLookUpNext(def->cd_labelLocHash,lab))
      {
	if (SigInterruptPending) break;
	if (GEO_TOUCH(&lab->lab_rect, r) && 
	    TTMaskHasType(mask, lab->lab_type) &&
	    strcmp(lab->lab_text,text) == 0)
	{
	  if ((*func)(scx, lab, tpath, cdarg))
	    return (1);
	}
      }
    }
    else if(text)
    {
      /* use text-based hash to narrow search! */
      for(lab = IHashLookUp(def->cd_labelHash,text);
      lab;
      lab = IHashLookUpNext(def->cd_labelHash,lab))
      {
	if (SigInterruptPending) break;
	if (GEO_TOUCH(&lab->lab_rect, r) && 
	    TTMaskHasType(mask, lab->lab_type))
	{
	  if ((*func)(scx, lab, tpath, cdarg))
	    return (1);
	}
      }
    }
    else
    {
      /* no text given, so need to search all labels */  
      for (lab = def->cd_labels; lab; lab = lab->lab_next)
      {
	if (SigInterruptPending) break;
	if (GEO_TOUCH(&lab->lab_rect, r) && TTMaskHasType(mask, lab->lab_type))
	    if ((*func)(scx, lab, tpath, cdarg))
		return (1);
      }
    }

    if(nonRecursive) return 0;

    /* PROCESS CHILDREN */

    filter.tf_func = func;
    filter.tf_arg = cdarg;
    filter.tf_mask = mask;
    filter.tf_text = text;
    filter.tf_loc = loc;
    filter.tf_xmask = xMask;
    filter.tf_tpath = tpath;
    /* filter.tf_planes is unused */

    /* Visit each child CellUse recursively.
     * This code is a bit tricky because the area can have zero size.
     * This would cause subcells never to be examined.  What we do is
     * to expand the area by 1 here, then require the labels to OVERLAP
     * instead of just TOUCH.  Be careful when expanding:  can't expand
     * any coordinate past infinity.
     */
    
    scx2 = *scx;
    if (scx2.scx_area.r_xbot > TiPlaneRect.r_xbot) scx2.scx_area.r_xbot -= 1;
    if (scx2.scx_area.r_ybot > TiPlaneRect.r_ybot) scx2.scx_area.r_ybot -= 1;
    if (scx2.scx_area.r_xtop < TiPlaneRect.r_xtop) scx2.scx_area.r_xtop += 1;
    if (scx2.scx_area.r_ytop < TiPlaneRect.r_ytop) scx2.scx_area.r_ytop += 1;
    if (DBSrChildren(&scx2, dbSearchLabelsFunc, (ClientData) &filter))
	return 1;

    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBSearchLabelsGlob --
 *
 * Extends DBSearchLabels() to take a Glob (*,[],?) style pattern.
 * TODO: integrate into DBSearchLabels()
 *
 *
 * Search for all occurrences of a point label matching the pattern in the
 * region rect in the indicated cell and all of its children.  On each label
 * matching the pattern found in the area, the supplied procedure is invoked.
 *
 * The supplied procedure should be of the form
 *	int
 *	func(scx, label, tpath, cdarg)
 *	    SearchContext *scx;
 *	    Label *label;
 *	    TerminalPath *tpath;
 *	    ClientData cdarg;
 *	{
 *	}
 *
 * In the above, scx is a search context specifying the cell use whose
 * def was found to contain the label, and label is a pointer to the
 * Label structure itself.  The transform specified in scx is from
 * coordinates of the def of the cell containing the label to "root"
 * coordinates.  Func should normally return 0.  If it returns 1 then
 * the search is aborted.
 *
 * Results:
 *	If the search terminates normally, 0 is returned.  1 is
 *	returned if the search was aborted.
 *
 * Side effects:
 *	Applies the supplied procedure to each tile containing a label
 *	matching the pattern.
 *
 * WARNING: because of the way regex(3) works, it is possible to be
 *	    searching for at most one pattern at a time.
 *
 * ----------------------------------------------------------------------------
 */

/*
 * The following statically allocated variables are used to
 * pass args to helper func. 
 */

#define	MAXLABPATHSIZE	10000

static int (*labSrFunc)();	/* Function to apply to each label found */
static ClientData labSrArg;	/* Client data of caller */
static char labSrStr[MAXLABPATHSIZE];	/* String buffer in which the full 
					 * pathname of each label is assembled 
					 * for handing to the filter function.
					 */
static char *labSrPattern;	/* Pattern for matching. */


/* helper func */
static int
dbSrLabelsGlobFunc(SearchContext *scx, Label *label, TerminalPath *tpath)
                       		/* Contains pointer to use in which label
				 * occurred, and transform back to root
				 * coordinates.
				 */
                 		/* Label itself */
                        	/* Full pathname of the terminal */
{
    if (Match(labSrPattern, label->lab_text))
	if ((*labSrFunc)(scx, label, tpath, labSrArg))
	    return 1;
    return 0;
}

int
DBSearchLabelsGlob(SearchContext *scx, 
                       		/* Search context: specifies CellUse,
				 * transform to "root" coordinates, and
				 * an area to search.
				 */
		   TileTypeBitMask *mask, 
                          	/* Only search for labels on these layers */
		   int xMask, 
              			/* Expansion state mask for searching.  Cell
				 * uses are only considered to be expanded
				 * when their expand masks have all the bits
				 * of xMask set.
				 */
		   char *pattern, 
                  		/* Pattern for which to search */
		   int (*func) (/* ??? */), 
                  		/* Function to apply to each match */
		   ClientData cdarg,
                     		/* Argument to pass to function */
		   int flags)   /* flags passed on to DBSearchLabels2() */
{
    TerminalPath tpath;
    char buf[BUFSIZ];
    char *text = NULL;

    labSrStr[0] = '\0';
    tpath.tp_first = tpath.tp_next = labSrStr;
    tpath.tp_last = &labSrStr[sizeof labSrStr - 2];

    if(pattern) text = MatchPlainTextQ(pattern,buf,BUFSIZ);
    
    /* if pattern is plan text, we handle separately 
     * (and much more efficeintly)
     */
    if(!pattern || text)
    {
      return DBSearchLabels2(scx, 
			     mask, 
			     NULL, /* location unknown */
			     text,
			     xMask, 
			     &tpath, 
			     func, 
			     cdarg,
	                     flags);
    }

    /* real pattern (contains wildcards), so do the hard way */ 
    labSrPattern = pattern;
    labSrFunc = func;
    labSrArg = cdarg;

    return DBSearchLabels2(scx, 
			   mask, 
			   NULL, /* location unknown*/
			   NULL, /* text unknown */
			   xMask, 
			   &tpath, 
			   dbSrLabelsGlobFunc, 
			   (ClientData) 0,
			   flags);
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBSearchFlyLines --
 *
 * Recursively search downward from the supplied CellUse for
 * all visible flylines.
 *
 * The procedure should be of the following form:
 *
 *	int func(scx *SearchContext, FlyLine *flyline, Clientdata cdarg)
 *
 * In the above, the use associated with scx is the parent of the
 * CellDef containing the fly line, and the
 * transform associated is the net transform from the coordinates
 * of the use to "root" coordinates.  Func normally returns 0.  If
 * func returns 1, it is a request to abort the search without finding
 * any more flylines.
 *
 * Results:
 *	0 is returned if the search terminated normally.  1 is returned
 *	if the search was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *-----------------------------------------------------------------------------
 */

/* filter func */
static int
dbSearchFlylinesFunc(register SearchContext *scx, register TreeFilter *fp)
{
    register FlyLine *fl;
    register Rect *r = &scx->scx_area;
    CellDef *def = scx->scx_use->cu_def;

    ASSERT(def != (CellDef *) NULL, "dbSearchLabelsFunc");
    if (!DBIsExpand(scx->scx_use, fp->tf_xmask)) return 0;
    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;
    

    /* Apply the function first to any of the labels in this def. */
    for (fl = def->cd_flyLines; fl; fl = fl->fl_next)
	if (GEO_OVERLAP(&fl->fl_bbox, r))
	{
	    if ((*fp->tf_func)(scx, fl, fp->tf_arg))
	    {
		return 1;
	    }
	}

    /* Now visit each child use recursively */
    if (DBSrChildrenNested(scx, dbSearchFlylinesFunc, (ClientData) fp))
	return 1;

    return 0;
}

int
DBSearchFlyLines(SearchContext *scx, 
                       		/* Pointer to search context specifying
				 * a cell use to search, an area in the
				 * coordinates of the cell's def, and a
				 * transform back to "root" coordinates.
				 * The area may have zero size.  Labels
				 * need only touch the area.
				 */
		 int xMask, 
              			/* All subcells are visited recursively
				 * until we encounter uses whose flags,
				 * when anded with xMask, are not
				 * equal to xMask.
				 */
		 int (*func)(SearchContext *scx, FlyLine *flyline, ClientData arg), 
                  		/* Function to apply at each qualifying tile */
		 ClientData cdarg)
                     		/* Client data for above function */
{
    SearchContext scx2;
    register FlyLine *fl;
    register Rect *r = &scx->scx_area;
    CellUse *cellUse = scx->scx_use;
    CellDef *def = cellUse->cu_def;
    TreeFilter filter;

    ASSERT(def != (CellDef *) NULL, "DBSearchFlyLines");
    if (!DBIsExpand(cellUse, xMask)) return 0;
    if ((def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(def, (char *) NULL, TRUE)) return 0;

    for (fl = def->cd_flyLines; fl; fl = fl->fl_next)
    {
	if (SigInterruptPending) break;

	if (fl->flay_flags&FL_P1_VALID && 
	    fl->flay_flags&FL_P2_VALID &&
	    GEO_TOUCH(&fl->fl_bbox, r))
        {
	    if ((*func)(scx, fl, cdarg)) return 1;
	}
    }

    filter.tf_func = func;
    filter.tf_arg = cdarg;
    /* filter.tf_mask is unused */
    filter.tf_xmask = xMask;
    /* filter.tf_tpath is unused */
    /* filter.tf_planes is unused */

    /* Visit each child CellUse recursively.
     * This code is a bit tricky because the area can have zero size.
     * This would cause subcells never to be examined.  What we do is
     * to expand the area by 1 here, then require the flylines to OVERLAP
     * instead of just TOUCH.  Be careful when expanding:  can't expand
     * any coordinate past infinity.
     */
    
    scx2 = *scx;
    if (scx2.scx_area.r_xbot > TiPlaneRect.r_xbot) scx2.scx_area.r_xbot -= 1;
    if (scx2.scx_area.r_ybot > TiPlaneRect.r_ybot) scx2.scx_area.r_ybot -= 1;
    if (scx2.scx_area.r_xtop < TiPlaneRect.r_xtop) scx2.scx_area.r_xtop += 1;
    if (scx2.scx_area.r_ytop < TiPlaneRect.r_ytop) scx2.scx_area.r_ytop += 1;
    if (DBSrChildren(&scx2, dbSearchFlylinesFunc, (ClientData) &filter))
	return 1;

    return 0;
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBSearchInstances --
 *
 * Recursively search downward from the supplied CellUse for
 * all CellUses whose parents are expanded but which themselves
 * are unexpanded (unless DBSI_INCLUDE_EXPANDED set).
 *
 * The procedure should be of the following form:
 *	int func(SearchContext *scx, ClientData cdarg) {}
 *
 * If tpath is nonnull a 3rd tpath arg is added to the procedure call.
 *
 * In the above, the transform scx->scx_trans is from coordinates of
 * the def of scx->scx_use to the "root".  The array indices
 * scx->scx_x and scx->scx_y identify this element if it is a
 * component of an array.  Func normally returns 0.  If func returns
 * 1, then the search is aborted.  If func returns 2, then all
 * remaining elements of the current array are skipped, but the
 * search is not aborted.
 *
 * Each element of an array is returned separately.
 *
 * Results:
 *	0 is returned if the search terminated normally.  1 is
 *	returned if it was aborted.
 *
 * Side effects:
 *	Whatever side effects are brought about by applying the
 *	procedure supplied.
 *
 *-----------------------------------------------------------------------------
 */

/* filter function */
static int
DBSearchInstancesFunc(register SearchContext *scx, 
		      register TreeFilter *fp)
		      
{
    register CellUse *use = scx->scx_use;
    int result;

    /* if expanded, first visit descendents */
    if(DBIsExpand(use, fp->tf_xmask))
    {
      char *tnext = NULL;  /* initialize to avoid warning */

      if(fp->tf_flags & DBSI_NON_RECURSIVE) goto this;

      if ((use->cu_def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(use->cu_def, (char *) NULL, TRUE))
	  goto this;

      /* add pathname component for this instance */
      if (fp->tf_tpath != (TerminalPath *) NULL)
      {
	register TerminalPath *tp = fp->tf_tpath;

	tnext = tp->tp_next;

	tp->tp_next = DBSrPrintUseId(scx, 
				     tp->tp_next, 
				     tp->tp_last-tp->tp_next);
	if (tp->tp_next < tp->tp_last)
	{
	  *(tp->tp_next++) = '/';
	  *(tp->tp_next) = '\0';
	}
      }

      result = DBSrChildrenNested(scx, DBSearchInstancesFunc, (ClientData) fp);

      /* Remove the trailing pathname component from the TerminalPath */
      if (fp->tf_tpath != (TerminalPath *) NULL)
      {
	fp->tf_tpath->tp_next = tnext;
	*tnext = '\0';
      }

      /* abort ? */
      if(result!=0) return result;
    }

this:
    /* if unexpanded or DBSI_INCLUDE_EXPANDED, visit this instance */
    if(DBSI_INCLUDE_EXPANDED ||!DBIsExpand(use, fp->tf_xmask)) 	
    {
      if(fp->tf_tpath)
      {
	result = (*fp->tf_func)(scx, fp->tf_arg, fp->tf_tpath);
      }
      else
      {
	result = (*fp->tf_func)(scx, fp->tf_arg);
      }

      return result;
    }

    return 0;
}

int
DBSearchInstances2(SearchContext *scx, 
                       	/* Pointer to search context specifying a cell use to
			 * search, an area in the coordinates of the cell's
			 * def, and a transform back to "root" coordinates.
			 */
		   int xMask, 
              		/* All subcells are visited recursively until we
			 * encounter uses whose flags, when anded with
			 * xMask, are not equal to Mask.  
			 *
			 * xMask = 0 to treat ALL instances as EXPANDED
			 * xMask = -1 to treat ALL instances as UNEXPANDE.
			 */
		   TerminalPath *tpath, 
                        	/* Pointer to a structure describing a
				 * partially filled in terminal pathname.
				 * If this pointer is NULL, we don't bother
				 * filling it in further; otherwise, we add
				 * new pathname components as we encounter
				 * them.
				 */
		   int (*func) (/* ??? */), 
                  	/* Function to apply to each qualifying cell */

		   ClientData cdarg,
                     	/* Client data for above function */

                   int flags)
{
    CellUse *cellUse = scx->scx_use;
    TreeContext context;
    TreeFilter filter;

    if (!DBIsExpand(cellUse, xMask))
	return 0;
    if ((cellUse->cu_def->cd_flags & CDAVAILABLE) == 0)
	if (!DBCellRead(cellUse->cu_def, (char *) NULL, TRUE))
	    return 0;

    context.tc_scx = scx;
    context.tc_filter = &filter;

    filter.tf_func = func;
    filter.tf_arg = cdarg;
    filter.tf_xmask = xMask;
    filter.tf_tpath = tpath; 
    filter.tf_flags = flags;	    

    if (DBSrChildren(scx, DBSearchInstancesFunc, (ClientData) &filter))
	return 1;
    else return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBSrTouchingTypes --
 * 
 * Generate mask of all types touching or covering a given point. 
 *
 * Results:
 *	Mask of all types touching or covering a given point in cellUse or
 *      expanded subcell.  If an unexpanded subcell is 
 *      covering or touching point TT_SUBCELL is included in the result as
 *	well.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

/* used by DBSrTouchingTypes() to pass data to helper funcs */
typedef struct touchingfuncparms
{
  Point 		tfp_point;
  TileTypeBitMask	tfp_types;
  int                   tfp_flags;
} TouchingFuncParms;


/* helper func for DBSrTouchingTypes(), sets tile type in mask if tile
 * touchs point.
 */
static int touchingTypesTileFunc(register Tile *tile, TreeContext *cxp)
{
    SearchContext *scx = cxp->tc_scx;
    Rect r, rDest;
    TouchingFuncParms *parms = (TouchingFuncParms *) (cxp->tc_filter->tf_arg);

    /* Transform to result coordinates */
    TITORECT(tile, &r);
    GEOCLIP(&r, &scx->scx_area);
    GEOTRANSRECT(&scx->scx_trans, &r, &rDest);

    if(GEO_ENCLOSE(&(parms->tfp_point), &rDest))
    {
      bool group = cxp->tc_filter->tf_flags & DBSTT_GROUP;

      if(group)
      {
	TTMaskSetType(&(parms->tfp_types),
		      DBgetTypeG(tile,scx->scx_use->cu_def->cd_activeGroup));
      }
      else
      {
	TTMaskSetType(&(parms->tfp_types),DBgetTileType(tile));
      }
    }

    /* return 0 to continue search */
    return(0);
}

/* helper func for DBSrTouchingTypes(), sets tile type in mask if point
 * touchs polygon.
 *
 * NOTE:  currently, if this func gets called, we know the polygon is with
 *        in one database unit of the point - for now we just figure that's
 *        close enough, and call it touching!
 */
static int touchingTypesPolyFunc(SearchContext *scx,
				 Polygon *poly,
				 ClientData cdarg)
{
    TouchingFuncParms *parms = (TouchingFuncParms *) cdarg;
    bool group = parms->tfp_flags & DBSTT_GROUP;

    if(!group || scx->scx_use->cu_def->cd_activeGroup == poly->poly_group)
    {
      TTMaskSetType(&(parms->tfp_types), poly->poly_type);
    }

    /* return 0 to continue search */
    return(0);
}

/* helper func for DBSrTouchingTypes()  
 * sets TT_SUBCELL on match and terminates search.
 */
static int
touchingSubcellsFunc(SearchContext *scx, ClientData cdarg)
{
    Rect r, rDest;
    TouchingFuncParms *parms = (TouchingFuncParms *) cdarg;

    /* Transform bounding box to result coordinates */
    r = *DBBBoxCellDef(scx->scx_use->cu_def);
    GEOTRANSRECT(&scx->scx_trans, &r, &rDest);

    if(GEO_ENCLOSE(&(parms->tfp_point), &rDest))
    {
	/* touching subcell found, mark in types mask, and terminate search */
        TTMaskSetType(&(parms->tfp_types),TT_SUBCELL);
	return 1;	/* 1 = abort search */
    }
    else
    {
        /* subcell doesn't touch point after all, continue search */
        return 0;	/* 0 = continue search */
    }
    return 0;
}

TileTypeBitMask 
DBSrTouchingTypes(CellUse *cellUse, 
		  int expansionMask, 
		  Point *point, 
		  int flags) /* see DBSTT_* in database.h */ 
{
  TouchingFuncParms parms;
	    
  /* Search unit radius rectangle around point for paint tiles
   * (in cellUse or subcells expanded in cmd window) containing or 
   * touching point
   */
  {
    SearchContext scx;
    int spFlags;

    /* set up scx */
    scx.scx_area.r_ll = *point;
    scx.scx_area.r_ur = *point;
    scx.scx_area.r_ll.p_x -= 1;
    scx.scx_area.r_ll.p_y -= 1;
    scx.scx_area.r_ur.p_x += 1;
    scx.scx_area.r_ur.p_y += 1;
    scx.scx_trans = GeoIdentityTransform;
    scx.scx_use = cellUse;

    /* set up clientdata */
    parms.tfp_point = *point;
    parms.tfp_flags = flags;
    TTMaskZero(&(parms.tfp_types));

    /* set up flags */
    spFlags = DBSP_DEPENDENT_POLYGONS;
    if(flags & DBSTT_NON_RECURSIVE) spFlags |= DBSP_NON_RECURSIVE;
    if(flags & DBSTT_GROUP) spFlags |= DBSP_GROUP;

    DBSearchPaintNew(&scx,
		     &DBAllButSpaceAndDRCBits,
		     expansionMask,
		     touchingTypesTileFunc,
		     touchingTypesPolyFunc,
		     NULL, /* wire paths */
		     (ClientData) &parms,
		     spFlags);
  }

  /* Now check for presence of unexpanded subcells */
  {
    SearchContext scx;
    
    scx.scx_area.r_ll = *point;
    scx.scx_area.r_ur = *point;
    scx.scx_area.r_ll.p_x -= 1;
    scx.scx_area.r_ll.p_y -= 1;
    scx.scx_area.r_ur.p_x += 1;
    scx.scx_area.r_ur.p_y += 1;

    scx.scx_trans = GeoIdentityTransform;
    scx.scx_use = cellUse;

    DBSearchInstances(&scx,
		      expansionMask,
		      touchingSubcellsFunc,
		      (ClientData) &parms);
  }

  return(parms.tfp_types);
}






