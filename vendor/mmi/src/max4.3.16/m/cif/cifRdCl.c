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



/* cifRdCl.c -
 *
 *	This file contains more routines to parse CIF files.  In
 *	particular, it contains the routines to handle cells,
 *	both definitions and calls, and user-defined features
 *	like labels.
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
static char rcsid[] = "$Header: CIFrdcl.c,v 6.1 90/09/03 14:33:27 stark Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "utils.h"
#include "layout.h"
#include "layout.h"
#include "main.h"
#include "drc.h"
#include "cifInt.h"
#include "cifRead.h"
#include "cif.h"

/* scale factors used during CIF (and GDS) reading */
 /* cif planes = internal planes used for geometric operations. */
double cifRdScaleCIFPlane2DB;
double cifRdScaleCIF2CIFPlane;
double cifRdScaleCIF2DB;

/* following variables keep track of max err when applying above scale factors */
double cifRdScaleCIFPlane2DBErr = 0;
double cifRdScaleCIF2CIFPlaneErr = 0;
double cifRdScaleCIF2DBErr = 0;

/* The following variable is made available to the outside world,
 * and is the cell definition currently being modified.
 */

CellDef *cifReadCellDef;

/*
 * The following hash table is used internally to keep track of
 * of all the cells we've seen definitions for or calls on.
 * The hash table entries contain pointers to cellDefs, and
 * are indexed by CIF cell number.  If the CD_AVAILABLE bit is
 * set it means we've read the cell's contents.  If not set, it
 * means that the cell has been called but not yet defined.
 */
HashTable CifCellTable;

/* The following variable is used to save and restore current
 * paint layer information so that we can resume the correct
 * layer after a subcell definition.
 */

Plane *cifOldReadPlane = NULL;

/* The following boolean is TRUE if a subcell definition is being
 * read.  FALSE means we're working on the EditCell.
 */

bool cifSubcellBeingRead;

/* The following two collections of planes are used to hold CIF
 * information while cells are being read in (one set for the
 * outermost, unnamed cell, and one for the current subcell).
 * When a cell is complete, then geometrical operations are
 * performed on the layers and stuff is painted into Magic.
 */

Plane *cifEditCellPlanes[MAXCIFRLAYERS];
Plane *cifSubcellPlanes[MAXCIFRLAYERS];
Plane **cifCurReadPlanes = cifEditCellPlanes;	/* Set of planes currently
						 * in force.
						 */
TileType cifCurLabelType = TT_SPACE;	/* Magic layer on which to put '94'
					 * labels that aren't identified by
					 * type.
					 */

/* The following variable is used to hold a subcell id between
 * the 91 statement and the (immediately-following?) call statement.
 * The string this points to is dynamically allocated, so it must
 * also be freed explicitly.
 */

char *cifSubcellId = NULL;

/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadCellInit --
 *
 * 	This procedure initializes the data structures in this
 *	module just prior to reading a CIF or GDS file.
 *
 *	If ptrkeys is 0, the keys used in this hash table will
 *	be strings; if it is 1, the keys will be CIF numbers.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The cell hash table is initialized, and things are set up
 *	to put information in the EditCell first.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFReadCellInit(int ptrkeys)
{
    int i;

    /* set up scale factors */
    if (cifCurReadStyle->crs_scaleFactor)
    {
      /* old fashioned scaleFactor specified in cifinput style */
      cifRdScaleCIFPlane2DB = 1.0 / cifCurReadStyle->crs_scaleFactor; 
      cifRdScaleCIF2CIFPlane = 1.0; /* centimicrons in cif and cif planes */
    }
    else
    {
      /* compute scale factors from resolutions */
      cifRdScaleCIFPlane2DB = CIFPlaneRes/CIFDBRes;
      cifRdScaleCIF2CIFPlane = .01/CIFPlaneRes; /* cif is in centimicrons */
    }
    cifRdScaleCIF2DB = cifRdScaleCIF2CIFPlane * cifRdScaleCIFPlane2DB;

/*
    fprintf(stderr,"DEBUG CIFReadCellInit.\n");
    fprintf(stderr,"\tcifRdScaleCIFPlane2DB = %g\n",
	    cifRdScaleCIFPlane2DB);
    fprintf(stderr,"\tcifRdScaleCIF2CIFPlane = %g\n",
	    cifRdScaleCIF2CIFPlane);
*/

    HashInit(&CifCellTable, 32, ptrkeys);
    cifReadCellDef = EditCellUse->cu_def;
    cifSubcellBeingRead = FALSE;
    cifCurReadPlanes = cifEditCellPlanes;
    for (i = 0; i < MAXCIFRLAYERS; i += 1)
    {
	if (cifEditCellPlanes[i] == NULL)
	    cifEditCellPlanes[i] = DBPlaneNew((ClientData) TT_SPACE);
	if (cifSubcellPlanes[i] == NULL)
	    cifSubcellPlanes[i] = DBPlaneNew((ClientData) TT_SPACE);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadCellCleanup --
 *
 * 	Free temporary storage after a CIF or GDS file has been read in.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFReadCellCleanup()
{
    HashKill(&CifCellTable);
}


/*
 * ----------------------------------------------------------------------------
 *
 * cifFindCell --
 *
 * 	This local procedure is used to find a cell in the subcell
 *	table, and create a new subcell if there isn't already
 *	one there.  If a new subcell is created, its CD_AVAILABLE
 *	is left FALSE.
 *
 * Results:
 *	The return value is a pointer to the definition for the
 *	cell whose CIF number is cifNum.
 *
 * Side effects:
 *	A new CellDef may be created.
 *
 * ----------------------------------------------------------------------------
 */

CellDef *
cifFindCell(int cifNum)
               			/* The CIF number of the desired cell. */
{
    HashEntry *h;
    CellDef *def;

    h = HashFind(&CifCellTable, (char *) cifNum);
    if (HashGetValue(h) == 0)
    {
	char name[15];
	(void) sprintf(name, "%d", cifNum);
	def = DBCellLookDef(name);
	if (def == NULL) DBCellNewDef(name, (char *) NULL);
	HashSetValue(h, def);
    }
    return (CellDef *) HashGetValue(h);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CIFPaintCurrent --
 *
 * 	This procedure does geometrical processing on the current
 *	set of CIF planes, and paints the results into the current
 *	CIF cell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Lots of information gets added to the current Magic cell.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFPaintCurrent(void)
{
    Plane *plane;
    int i;

    for (i = 0; i < cifCurReadStyle->crs_nLayers; i += 1)
    {
	TileType type;
	extern int cifPaintCurrentFunc(Tile *tile, TileType type);	/* Forward declaration. */

	plane = CIFGenLayer(cifCurReadStyle->crs_layers[i]->crl_ops,
			    &TiPlaneRect, 
			    (CellDef *) NULL, 
			    cifCurReadPlanes,
			    FALSE);

	/* Generate a paint/erase table, then paint from the CIF
	 * plane into the current Magic cell.
	 */

	type = cifCurReadStyle->crs_layers[i]->crl_magicType;

	(void) DBPlaneEnumAreaPaint((Tile *) NULL, plane, &TiPlaneRect,
		&CIFSolidBits, cifPaintCurrentFunc, (ClientData) type);
	
	/* Recycle the plane, which was dynamically allocated. */

	DBFreePaintPlane(plane);
	TiFreePlane(plane);
    }

    /* Now go through all the current planes and zero them out. */
    for (i = 0; i < MAXCIFRLAYERS; i += 1)
    {
	DBPlaneClearPaint(cifCurReadPlanes[i]);
    }
}

/* Below is the search function invoked for each CIF tile type
 * found for the current layer.
 */

int
cifPaintCurrentFunc(Tile *tile, TileType type)
               			/* Tile of CIF information. */
                  		/* Magic type to be painted. */
{
    Rect area;
    int pNum;

    /* Compute the area of the CIF tile, then scale it into
     * Max Database coordinates.
     */
    
    TiToRect(tile, &area);
    GeoScaleRect(&area, 
		 cifRdScaleCIFPlane2DB,
		 &cifRdScaleCIFPlane2DBErr);

    pNum = DBPlane(type);
    DBPaintPlane(cifReadCellDef->cd_planes[pNum], 
		 &area,
		 DBStdPaintTbl(type, pNum), 
		 (PaintUndoInfo *) NULL);

    return  0;		/* To keep the search alive. */
}










