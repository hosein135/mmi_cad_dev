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
 * DBcellUse.c --
 *
 * CellUse creation, deletion.
 *
 * Mostly celluses are for instances, but some are "handles" for cells
 * e.g. toplevel cells in windows, the selection etc.
 *
 * Instances, are created by:
 *   1. creating and setting up a celluse (using funcs in DBcellUse.c),
 *   2. calling DBInstanceAdd() (in DBinstance.c)
 *
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

#include <sys/types.h>
#include <stdio.h>
#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "hash.h"
#include "utils.h"
#include "geometry.h"
#include "tile.h"
#include "signals.h"
#include "undo.h"
#include "malloc.h"
#include "layout.h"
#include "message.h"
#include "main.h"
#include "ihash.h"


/*
 * ----------------------------------------------------------------------------
 *
 * dbCellUseComputeBBox --
 *
 * Compute the bounding box for a CellUse in coordinates of its parent.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *
 *	Sets cellUse->cu_bbox to be the bounding box for the indicated CellUse
 *	in coordinates of that CellUse's parent.
 *
 *      Sets cu_vBBOX to cd_vBBOX of subcell.
 *
 * ----------------------------------------------------------------------------
 */

void
dbCellUseComputeBBox(register CellUse *use, 
		     Rect *result)  /* if non-null, place result here 
				     * and don't change cu_bbox  
				     */
{
    register Rect *box;
    Rect childRect;
    int xdelta, ydelta;

    xdelta = use->cu_xsep * (use->cu_xhi - use->cu_xlo);
    ydelta = use->cu_ysep * (use->cu_yhi - use->cu_ylo);
    if (xdelta < 0) xdelta = (-xdelta);
    if (ydelta < 0) ydelta = (-ydelta);

    box = DBBBoxCellDef(use->cu_def);

    if (use->cu_xsep < 0)
    {
	childRect.r_xbot = box->r_xbot - xdelta;
	childRect.r_xtop = box->r_xtop;
    }
    else
    {
	childRect.r_xbot = box->r_xbot;
	childRect.r_xtop = box->r_xtop + xdelta;
    }

    if (use->cu_ysep < 0)
    {
	childRect.r_ybot = box->r_ybot - ydelta;
	childRect.r_ytop = box->r_ytop;
    }
    else
    {
	childRect.r_ybot = box->r_ybot;
	childRect.r_ytop = box->r_ytop + ydelta;
    }

    if(result)
    {
      /* return result, leaving celluse bbox alone! */
      GeoTransRect(&use->cu_transform, &childRect, result);
    }
    else  
    {
      /* Can't change bbox while linked into cellPlane */
      ASSERT(!use->cu_bpLinks[0],"dbCellUseComputeBBox");

      /* sets celluse bbox */
      GeoTransRect(&use->cu_transform, &childRect, &use->cu_bbox);
    
      /* copy version stamp */
      use->cu_vBBOX = use->cu_def->cd_vBBOX;
    }
}

/* initial use structure (common to DBCellNewUse() and DBInitTempUse() below) */
static __inline__ void dbInitUse(CellDef *cellDef, CellUse *cellUse)
{
    cellUse->cu_def = cellDef;

    cellUse->cu_bpLinks[0] = 0; 
    cellUse->cu_bbox.r_xbot = 0;
    cellUse->cu_bbox.r_ybot = 0;
    cellUse->cu_bbox.r_xtop = 1;
    cellUse->cu_bbox.r_ytop = 1;
    cellUse->cu_expandMask = 0;
    cellUse->cu_transform = GeoIdentityTransform;
    cellUse->cu_parent = (CellDef *) NULL;
    cellUse->cu_xlo = 0;
    cellUse->cu_ylo = 0;
    cellUse->cu_xhi = 0;
    cellUse->cu_yhi = 0;
    cellUse->cu_xsep = 0;
    cellUse->cu_ysep = 0;

    cellUse->cu_vMAIN = DBVStampInvalid;
    cellUse->cu_vDRC = DBVStampInvalid;
    cellUse->cu_vBBOX = DBVStampInvalid;
    cellUse->cu_vDISPLAY = DBVStampInvalid;

    cellUse->cu_nextSib = NULL;
    cellUse->cu_client = 0;

    /* note don't update def:  not necessary since
     * stamps marked invalid, and can cause trouble 
     * during flyline notify trigged by DBInstanceAdd()
     *

    dbCellUseComputeBBox(cellUse, 
			 NULL, 
			 FALSE);
    */			 

}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellNewUse --
 *
 * Create a new cell use of the supplied CellDef.
 *
 * Results:
 *	Returns a pointer to the new CellUse.  The CellUse is initialized
 *	to reflect that cellDef is its definition.  The transform is
 *	initialized to the identity, and the parent pointer initialized
 *	to NULL.
 *
 * Side effects:
 *	Updates the use list for cellDef.
 *
 * ----------------------------------------------------------------------------
 */

CellUse *
DBCellNewUse(CellDef *cellDef, 
                     	/* Pointer to definition of the cell */
	     char *useName)
                  	/* Pointer to use identifier for the cell.  This may
			 * be NULL, in which case a unique use identifier is
			 * generated automatically when the cell use is linked
			 * into a parent def.
			 */
{
    CellUse *cellUse;

    MALLOC_TAG(CellUse *, cellUse, sizeof (CellUse),"CellUse");
    dbInitUse(cellDef, cellUse);

    cellUse->cu_id = StrDup((char **) NULL, useName);
    cellUse->cu_nextuse = cellDef->cd_uses;
    cellDef->cd_uses = cellUse;

    return (cellUse);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellInitTempUse --
 *
 * Initialize a temporary use.  
 *
 * This is bascially a light weight alternative to DBCellNewUse, for use
 * in DBSearch routines to create initial use (handle) from which to start 
 * search.  Avoids Malloc (can be passed a use from stack), and does not
 * link use in cd_uses list, so DBCellDeleteUse() call is not needed. 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes use. 
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellInitTempUse(CellDef *cellDef,
		  CellUse *cellUse)
                     	/* Cell Use to initialize  */
{
    dbInitUse(cellDef, cellUse);
    return;
}



/*
 * ----------------------------------------------------------------------------
 *
 * DBCellDeleteUse --
 *
 * Remove a CellUse.
 * Frees the storage allocated to the CellUse, 
 * unlinks use from corresponding defs cd_use list.
 *
 * It is required that the CellUse has been removed from any CellTileBodies
 * in the subcell plane of its parent.  The parent pointer for this
 * CellUse must therefore be NULL.
 *
 * Results:
 *	TRUE if the CellUse was successfully removed, FALSE if
 *	the parent pointer were not NULL.
 *
 * Side effects:
 *	All storage for the CellUse is freed.
 *	The list of all CellUses associated with a given CellDef is
 *	updated to reflect the absence of the deleted CellUse.
 *
 * ----------------------------------------------------------------------------
 */

bool
DBCellDeleteUse(CellUse *cellUse)
                     		/* Pointer to CellUse to be deleted */
{
    CellDef *cellDef;
    CellUse *useptr;

    if (cellUse->cu_parent != (CellDef *) NULL)
	return (FALSE);

    cellDef = cellUse->cu_def;
    if (cellUse->cu_id != (char *) NULL)
    {
	FREE_TAG(cellUse->cu_id,"char *cu_id");
    }
    cellUse->cu_id = (char *) NULL;
    cellUse->cu_def = (CellDef *) NULL;

    ASSERT(cellDef->cd_uses != (CellUse *) NULL, "DBCellDeleteUse");

    if (cellDef->cd_uses == cellUse)
    {
	cellDef->cd_uses = cellUse->cu_nextuse;
    }
    else for (useptr = cellDef->cd_uses;  useptr != NULL;
	useptr = useptr->cu_nextuse)
    {
	if (useptr->cu_nextuse == cellUse)
	{
	    useptr->cu_nextuse = cellUse->cu_nextuse;
	    break;
	}
    }

    FREE_TAG((char *) cellUse,"CellUse");
    return (TRUE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseSetArray --
 *
 * Copy the array information from fromCellUse to toCellUse
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The array information if toCellUse is modified.
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellUseSetArray(CellUse *fromCellUse, CellUse *toCellUse)
{
    toCellUse->cu_xlo = fromCellUse->cu_xlo;
    toCellUse->cu_ylo = fromCellUse->cu_ylo;
    toCellUse->cu_xhi = fromCellUse->cu_xhi;
    toCellUse->cu_yhi = fromCellUse->cu_yhi;
    toCellUse->cu_xsep = fromCellUse->cu_xsep;
    toCellUse->cu_ysep = fromCellUse->cu_ysep;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBCellUseSetTrans --
 *
 * Change the transform for cellUse to that supplied.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Updates cellUse->cu_trans and cellUse->cu_bbox
 *
 * ----------------------------------------------------------------------------
 */

void
DBCellUseSetTrans(CellUse *cellUse, Transform *trans)
{
    cellUse->cu_transform = *trans;
    dbCellUseComputeBBox(cellUse, NULL);
}
