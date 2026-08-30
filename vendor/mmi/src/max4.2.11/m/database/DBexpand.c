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
 * DBexpand.c --
 *
 * Expansion and unexpansion of cells
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
static char rcsid[] = "$Header: DBexpand.c,v 6.0 90/08/28 18:09:51 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "utils.h"
#include "stack.h"

    /*
     * Argument passed down to search functions when searching for
     * cells to expand or unexpand.
     */
struct expandArg
{
    int		ea_xmask;	/* Expand mask. */
    int		(*ea_func)();	/* Function to call for each cell whose
				 * status is changed.
				 */
    ClientData	ea_arg;		/* Argument to pass to func. */
};

/*
 * ----------------------------------------------------------------------------
 *
 * DBExpand --
 *
 * Expand/unexpand a single CellUse.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If expandFlag is TRUE, sets all the bits of expandMask in
 *	the flags of the given cellUse.
 *      If expandFlag is FALSE, clears all bits of expandMask.
 *
 *	If expandFlag is TRUE and the cell being expanded has not
 *	been read in, reads it in from disk.
 *
 * ----------------------------------------------------------------------------
 */

void
DBExpand(CellUse *cellUse, int expandMask, int expandFlag)
{
    CellDef *def;

    if (DBIsExpand(cellUse, expandMask) == expandFlag)
	return;

    if (expandFlag)
    {
	def = cellUse->cu_def;
	if ((def->cd_flags & CDAVAILABLE) == 0)
	{
	    if (!DBCellRead(def, (char *) NULL, TRUE))
		return;
	    /* Note:  we don't have to recompute the bbox here, because
	     * if it changed, then a timestamp violation must have occurred
	     * and the timestamp manager will take care of recomputing
	     * the bbox.
	     */
	}
	cellUse->cu_expandMask |= expandMask;
    }
    else
    {
      /* don't unexpand generated cells */
      if(cellUse->cu_def->cd_flags & CD_GENERATED) return;

      cellUse->cu_expandMask &= ~expandMask;
    }
}

/*
 * dbExpandFunc --
 *
 * Filter function called by DBSrChildren on behalf of DBExpandAll above
 * when cells are being expanded.
 */

static int
dbExpandFunc(register SearchContext *scx, 
                                	/* Pointer to search context containing
					 * child use, search area in coor-
					 * dinates of the child use, and
					 * transform back to "root".
					 */
	     register struct expandArg *arg)
                                   	/* Client data from caller */
{
    CellUse *childUse = scx->scx_use;

    /*
     * Change the expansion status of this cell if necessary.  Call the
     * client's function if the expansion status has changed.
     */

    if (!DBIsExpand(childUse, arg->ea_xmask))
    {
	/* If the cell is unavailable, then don't expand it. */
	if ((childUse->cu_def->cd_flags & CDAVAILABLE) == 0)
	{
	  if(!DBCellRead(childUse->cu_def, (char *) NULL, TRUE))
	  {
	    MsgErrorF("Cell %s is unavailable.  It could not be expanded.\n",
		      childUse->cu_def->cd_name);
	    return 2;
	  }
	}

	childUse->cu_expandMask |= arg->ea_xmask;
	if (arg->ea_func != NULL)
	{
	    if ((*arg->ea_func)(childUse, arg->ea_arg) != 0) 
	    {
	      return 1;
	    }
	}
    }

    if (DBSrChildrenNested(scx, dbExpandFunc, (ClientData) arg))
	return 1;
    return 2;
}

/*
 * dbUnexpandFunc --
 *
 * Filter function called by DBSrChildren on behalf of DBExpandAll 
 * when cells are being unexpanded.
 */

static int
dbUnexpandFunc(register SearchContext *scx, 
                                	/* Pointer to search context containing
					 * child use, search area in coor-
					 * dinates of the child use, and
					 * transform back to "root".
					 */
	       register struct expandArg *arg)
                                   	/* Client data from caller */
{
    CellUse *childUse = scx->scx_use;

    /*
     * Change the expansion status of this cell if necessary.
     */

    if (DBIsExpand(childUse, arg->ea_xmask))
    {
        Rect *childBBox = DBBBoxCellDef(childUse->cu_def);
	
	/* don't unexpand generated cells */
	if (childUse->cu_def->cd_flags & CD_GENERATED) return 2;

	if (!GEO_SURROUND(childBBox, &scx->scx_area)
	    || GEO_SURROUND(&scx->scx_area, childBBox))
	{
	    childUse->cu_expandMask &= ~arg->ea_xmask;

	    /* Call the client's function, if there is one. */

	    if (arg->ea_func != NULL)
	    {
		if ((*arg->ea_func)(childUse, arg->ea_arg) != 0) return 1;
	    }
	}
    }
    else 
    {
      /* Don't recursively search things that aren't already expanded. */
      return 2;
    }

    if (DBSrChildrenNested(scx, dbUnexpandFunc, (ClientData) arg)) return 1;
    return 2;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBExpandAll --
 *
 * Recursively expand/unexpand all cells which intersect or are
 * contained within the given rectangle.  Furthermore, if func is
 * non-NULL, it is invoked for each cell whose status has changed,
 * just after the change has been made.  The calling sequence is
 *
 *     int
 *     func(cellUse, cdarg)
 *	   CellUse *cellUse;
 *	   ClientData cdarg;
 *     {
 *     }
 *
 * In the calls to func, cellUse is the use whose expand bit has just
 * been changed, and cdarg is the argument that the caller gave to us.
 * Func should normally return 0.  If it returns a non-zero value, then
 * the call terminates immediately and no more cells are expanded.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If expandFlag is TRUE, sets all the bits specified by
 *	expandMask in the flags of each CellUse found to intersect
 *	the given rectangle.  If expandFlag is FALSE, clears all bits
 *	of expandMask.
 *
 * NOTE:  a cell that is unexpanded and read-in and whose previous bbox
 *        (stored with parent) does not intersect the area, will not be
 *        expanded, since we do not know that it intersects the area. 
 * ----------------------------------------------------------------------------
 */
void
DBExpandAll(CellUse *rootUse, 
         	/* Root cell use from which search begins */
	    Rect *rootRect, 
	        /* Area to be expanded, in root coordinates */
	    int expandMask, 
               	/* Window mask in which cell is to be expanded */
	    int expandFlag, 
               	/* TRUE => expand, FALSE => unexpand */
	    int (*func) (/* ??? */), 
               	/* Function to call for each cell whose expansion
		 * status is modified.  NULL means don't call anyone.
		 */
	    ClientData cdarg)
               	/* Argument to pass to func. */
{
    SearchContext scontext;
    struct expandArg arg;

    /*
     * Walk through the area and set the expansion state
     * appropriately.
     */
    arg.ea_xmask = expandMask;
    arg.ea_func = func;
    arg.ea_arg = cdarg;

    scontext.scx_use = rootUse;
    scontext.scx_trans = GeoIdentityTransform;
    scontext.scx_area = *rootRect;

    (void) DBSrChildren(&scontext, 
			expandFlag ? dbExpandFunc :  dbUnexpandFunc,
			(ClientData) &arg);

}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellReadArea --
 *
 * Recursively read all cells which intersect or are contained within
 * the given rectangle.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May make new cells known to the database.  Sets the CDAVAILABLE
 *	bit in all cells intersecting the search area.
 *
 * ----------------------------------------------------------------------------
 */

static int
dbReadAreaFunc(register SearchContext *scx)
                                	/* Pointer to context specifying
					 * the cell use to be read in, and
					 * an area to be recursively read in
					 * coordinates of the cell use's def.
					 */
{
    register CellDef *def = scx->scx_use->cu_def;

    if ((def->cd_flags & CDAVAILABLE) == 0)
    {
	(void) DBCellRead(def, (char *) NULL, TRUE);
    }

    (void) DBSrChildren(scx, dbReadAreaFunc, (ClientData) NULL);

    /* Be clever about handling arrays:  if the search area covers this
     * whole definition, then there's no need to look at any other
     * array elements, since we've already expanded the entire area
     * of the definition.
     */

    if (GEO_SURROUND(&scx->scx_area, DBBBoxCellDef(scx->scx_use->cu_def)))
	return 2;
    return 0;
}

void
DBCellReadArea(CellUse *rootUse, 
	                /* Root cell use from which search begins */
	       Rect *rootRect)
                       	/* Area to be read, in root coordinates */
                        /* Use TiPlaneRect if area is not to be restricted */
{
    SearchContext scontext;

    scontext.scx_use = rootUse;
    scontext.scx_trans = GeoIdentityTransform;
    scontext.scx_area = *rootRect;
    (void) dbReadAreaFunc(&scontext);
}








