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
 * DBstat.c --
 *
 * Database Statistics routines.
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

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "utils.h"
#include "geometry.h"
#include "tile.h"
#include "message.h"
#include "main.h"
#include "debug.h"

/* helper func for DBstatPaintPlane */
static int
dbStatPaintPlaneFunc(register Tile *tile, int *array)
{
    TileType t = DBgetTileType(tile);

    ++array[t]; 

    return 0;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBstatPaintPlane --
 *
 * Collect statistics on a tile plane.
 *
 * Returns: amount of memory used by plane.
 *
 *
 * ----------------------------------------------------------------------------
 */

int 
DBstatPaintPlane(Plane *pl, 
		 int *byType) /* If non-null break count down by type.
			       * Should point to array at least DBNumTypes
			       * big.
			       */
{
  int buf[TT_MAXTYPES];
  int *array = buf;
  int total;

  if(byType) array = byType;

  /* initial result array */
  {
    int t;
    for (t = TT_SPACE; t < DBNumTypes; t++) array[t] = 0;
  }
  
  /* Visit all tiles in the plane */
  (void) DBPlaneEnumAreaPaint((Tile *) NULL, 
			      pl,
			      &TiPlaneRect, 
			      &DBAllTypeBits,
			      dbStatPaintPlaneFunc,
			      (ClientData) array);

  /* Compute total number of tiles */
  {
    int t;
    total = 0;
    for (t = TT_SPACE; t < DBNumTypes; t++) total += array[t];
  }

  /* four tiles at infinity */
  total += 4;

  return total*sizeof(Tile);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBstatCellPlane --
 *
 * Collect statistics on cell plane.
 *
 * Returns: amount of memory used by cell plane.
 *
 *
 * ----------------------------------------------------------------------------
 */

int 
DBstatCellPlane(CellDef *def, 
		int *numTiles,   /* If non-null return number of tiles here */
		int *numBodies)  /* If non-null return number of tile bodies 
				  * here.
				  */
{
  /* no longer used */ 
  if(numTiles) *numTiles = 0;
  if(numBodies) *numBodies = 0;

  return 
    BPStatMemory(def->cd_cellPlane);
}








