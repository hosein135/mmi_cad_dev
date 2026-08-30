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
 * DBpaint2.c --
 *
 * More paint and erase primitives
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
static char rcsid[] = "$Header: DBpaint2.c,v 6.0 90/08/28 18:10:08 mayo Exp $";
#endif  not lint

#include <sys/types.h>
#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "debug.h"

/*
 * ----------------------------------------------------------------------------
 * DBPaint --
 *
 * Paint a rectangular area with a specific tile type.
 * All paint tile planes in cellDef are painted.
 *
 * Up to caller to call DBChangedArea() to notify of change.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies potentially all paint tile planes in cellDef.
 * ----------------------------------------------------------------------------
 */

void
DBPaint(CellDef *cellDef, Rect *rect, TileType type)
                       		/* CellDef to modify */
                    		/* Area to paint */
                    		/* Type of tile to be painted */
{
    int pNum;
    PaintUndoInfo ui;

    ui.pu_def = cellDef;

    /* special case space tiles (they effect ALL planes  */
    if(type == TT_SPACE)
    {
      for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
      {
	ui.pu_pNum = pNum;
	DBPaintPlane(cellDef->cd_planes[pNum], 
		     rect,
		     DBStdPaintTbl(type, pNum), 
		     &ui);
      }
    }
    else
    {
      /* nonspace - only effects types home plane */

      pNum = DBPlane(type);
      ui.pu_pNum = pNum;
      DBPaintPlane(cellDef->cd_planes[pNum], 
		   rect,
		   DBStdPaintTbl(type, pNum), 
		   &ui);
    }
}

/*
 * ----------------------------------------------------------------------------
 * DBErase --
 *
 * Erase a specific tile type from a rectangular area.
 * The plane in which tiles of the given type reside is modified
 * in cellDef.
 *
 * Up to caller to call DBChangedArea()
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies potentially all paint tile planes in cellDef.
 * ----------------------------------------------------------------------------
 */

void
DBErase (CellDef *cellDef, 
                       		/* Cell to modify */
	 Rect *rect, 
                    		/* Area to paint */
	 TileType type)
                    		/* Type of tile to be painted */
{
    int pNum;
    PaintUndoInfo ui;

    ui.pu_def = cellDef;
    if (type == TT_SPACE)
    {
	/*
	 * Erasing space is the same as erasing everything under
	 * the rectangle.  NOT.  SEE COMMENT BELOW.
	 */
	for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
	{
	    ui.pu_pNum = pNum;
	    /* TODO mha 4/17/98 this looks like a bug, since space doesn't
	     * erase things that are not on its "home" plane.  Need
	     * to use DBWritePaintTbl(TT_SPACE) to erase everything!!!
             *
	     * this branch may never happen ???
	     */
	    DBPaintPlane(cellDef->cd_planes[pNum], 
			 rect,
			 DBStdPaintTbl(TT_SPACE, pNum) /* bug? */, 
			 &ui);
	}
    }
    else
    {
      /* Ordinary type is being erased. */
      pNum = DBPlane(type);
      ui.pu_pNum = pNum;
      DBPaintPlane(cellDef->cd_planes[pNum], 
		   rect,
		   DBStdEraseTbl(type, pNum), 
		   &ui);
    }
}

/*
 * ----------------------------------------------------------------------------
 * DBEraseG --
 *
 * Erase a specific tile type from a rectangular area.
 * The plane in which tiles of the given type reside is modified
 * in cellDef.
 *
 * Only the active group is erased.
 * 
 * Up to caller to call DBChangedArea()
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies potentially all paint tile planes in cellDef.
 * ----------------------------------------------------------------------------
 */

void
DBEraseG (CellDef *cellDef, Rect *rect, TileType type)
                       		/* Cell to modify */
                    		/* Area to paint */
                    		/* Type of tile to be painted */
{
    int pNum;
    PaintUndoInfo ui;
    Group *activeGroup = cellDef->cd_activeGroup;

    ui.pu_def = cellDef;

    if (type == TT_SPACE)
    {
	/*
	 * Erasing space is the same as erasing everything under
	 * the rectangle.  NOT.  SEE COMMENT BELOW.
	 */
	for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
	{
	    ui.pu_pNum = pNum;
	    /* TODO mha 4/17/98 this looks like a bug, since space doesn't
	     * erase things that are not on its "home" plane.  Need
	     * to use DBWritePaintTbl(TT_SPACE) to erase everything!!!
             *
	     * this branch may never happen ???
	     */
	    DBPaintPlaneG(cellDef->cd_planes[pNum], 
			  rect,
			  DBStdPaintTbl(TT_SPACE, pNum) /* bug? */, 
			  activeGroup, 
			  &ui);
	}
    }
    else
    {
      /* Ordinary type is being erased. */
      pNum = DBPlane(type);
      ui.pu_pNum = pNum;

      DBPaintPlaneG(cellDef->cd_planes[pNum], 
		    rect,
		    DBStdEraseTbl(type, pNum), 
		    activeGroup, 
		    &ui);
    }
}


/*
 * ----------------------------------------------------------------------------
 * DBPaintMask --
 *
 * Paint a rectangular area with all tile types specified in the
 * mask supplied.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies potentially all paint tile planes in cellDef.
 * ----------------------------------------------------------------------------
 */

void
DBPaintMask(CellDef *cellDef, Rect *rect, TileTypeBitMask *mask)
           	         	/* CellDef to modify */
        	      		/* Area to paint */
                          	/* Mask of types to be erased */
{
    TileType t;

    for (t = TT_SPACE + 1; t < DBNumTypes; t++)
	if (TTMaskHasType(mask, t))
	    DBPaint(cellDef, rect, t);
}

/*
 * ----------------------------------------------------------------------------
 * DBEraseMask --
 *
 * Erase a rectangular area with all tile types specified in the
 * mask supplied.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies potentially all paint tile planes in cellDef.
 * ----------------------------------------------------------------------------
 */

void
DBEraseMask(CellDef *cellDef, Rect *rect, TileTypeBitMask *mask)
           	         	/* CellDef to modify */
        	      		/* Area to erase */
                          	/* Mask of types to be erased */
{
    TileType t;

    for (t = TT_SPACE + 1; t < DBNumTypes; t++)
	if (TTMaskHasType(mask, t))
	    DBErase(cellDef, rect, t);
}


/*
 * ----------------------------------------------------------------------------
 * DBEraseMask --
 *
 * Erase a rectangular area with all tile types specified in the
 * mask supplied.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies potentially all paint tile planes in cellDef.
 * ----------------------------------------------------------------------------
 */

void
DBEraseMaskG(CellDef *cellDef, Rect *rect, TileTypeBitMask *mask, bool activeGroupOnly)
           	         	/* CellDef to modify */
        	      		/* Area to erase */
                          	/* Mask of types to be erased */
{
    TileType t;

    for (t = TT_SPACE + 1; t < DBNumTypes; t++)
	if (TTMaskHasType(mask, t))
	    if(activeGroupOnly)
	    {
	        DBEraseG(cellDef, rect, t);
	    }
            else
	    {
	        DBErase(cellDef, rect, t);
            }
}
   
