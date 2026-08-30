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



/* cifSee.c -
 *
 *	This file provides procedures for displaying CIF layers on
 *	the screen using the highlight facilities.
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
static char rcsid[] = "$Header: CIFsee.c,v 6.0 90/08/28 18:05:21 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "styles.h"
#include "message.h"
#include "undo.h"
#include "cif.h"
#include "cifInt.h"
#include "gds.h"

/* The following variable holds the CellDef into which feedback
 * is to be placed for displaying CIF.
 */

static CellDef *cifSeeDef;


/*
 * ----------------------------------------------------------------------------
 *
 * cifSeeFunc --
 *
 * 	Called once for each tile that is to be displayed as feedback.
 *	This procedure enters the tile as feedback.  Note: the caller
 *	must arrange for cifSeeDef to contain a pointer to the cell
 *	def where feedback is to be displayed.
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	A new feedback area is created over the tile.  The parameter
 *	"text" is associated with the feedback.
 * ----------------------------------------------------------------------------
 */

int
cifSeeFunc(Tile *tile, char *text)
               			/* Tile to be entered as feedback. */
               			/* Explanation for the feedback. */
{
    Rect area;
    TiToRect(tile, &area);
    LayFeedbackAdd(&area, 
		   text, 
		   cifSeeDef, 
		   CIFDBRes/CIFPlaneRes,
		   STYLE_FEEDBACK_PALE);
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFSeeLayer --
 *
 * 	Generates CIF over a given area of a given cell, then
 *	highlights a particular CIF layer on the screen.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Highlight information is drawn on the screen.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFSeeLayer(CellDef *rootDef, Rect *area, char *layer)
                     		/* Cell for which to generate CIF.  Must be
				 * the rootDef of a window.
				 */
               			/* Area in which to generate CIF. */
                		/* CIF layer to highlight on the screen. */
{
    int oldCount, i;
    char msg[100];
    SearchContext scx;
    CellUse dummy;
    TileTypeBitMask mask;

    /* Make sure the desired layer exists. */

    if (!CIFNameToMask(layer, &mask))
	return;

    /* Flatten the area and generate CIF for it. */

    CIFErrorDef = rootDef;
    CIFInitCells();
    UndoDisable();

    /* set up scx */
    GEO_EXPAND(area, CIFCurStyle->cs_radius, &scx.scx_area);
    scx.scx_use = DBCellUseNewTemp(rootDef, &dummy);
    scx.scx_trans = GeoIdentityTransform;

    DBSearchPaint(&scx, 
		  &DBAllButSpaceAndDRCBits, 
		  0,
		  cifHierCopyFunc, 
		  (ClientData) CIFComponentDef);

    oldCount = LayFeedbackCount;
    CIFGen(CIFComponentDef, 
	   area, 
	   CIFPlanes, 
	   &DBAllTypeBits, 
	   TRUE, 
	   TRUE,
	   FALSE);
    DBCellClearContents(CIFComponentDef);

    /* Report any errors that occurred. */

    if (LayFeedbackCount != oldCount)
    {
	MsgInfoF("%d problems occurred.  See feedback entries.\n",
	    LayFeedbackCount-oldCount);
    }

    /* Display the chosen layer. */

    (void) sprintf(msg, "CIF layer \"%s\"", layer);
    cifSeeDef = rootDef;
    for (i = 0; i < CIFCurStyle->cs_nLayers; i++)
    {
	if (!TTMaskHasType(&mask, i)) continue;
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, CIFPlanes[i], &TiPlaneRect,
	    &CIFSolidBits, cifSeeFunc, (ClientData) msg);
    }
    UndoEnable();
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFSeeHierLayer --
 *
 * 	This procedure is similar to CIFSeeLayer except that it only
 *	generates hierarchical interaction information.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	CIF information is highlighed on the screen.  If arrays is
 *	TRUE, then CIF that stems from array interactions is displayed.
 *	if subcells is TRUE, then CIF stemming from subcell interactions
 *	is displayed.  If both are TRUE, then both are displayed.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFSeeHierLayer(CellDef *rootDef, Rect *area, char *layer, int arrays, int subcells)
                     		/* Def in which to compute CIF.  Must be
				 * the root definition of a window.
				 */
               			/* Area in which to generate CIF. */
                		/* CIF layer to be highlighted. */
                		/* TRUE means show array interactions. */
                  		/* TRUE means show subcell interactions. */
{
    int i, oldCount;
    char msg[100];
    TileTypeBitMask mask;

    /* Check out the CIF layer name. */

    if (!CIFNameToMask(layer, &mask)) return;

    CIFErrorDef = rootDef;
    oldCount = LayFeedbackCount;
    CIFClearPlanes(CIFPlanes);
    if (subcells)
	CIFGenSubcells(rootDef, area, CIFPlanes, GDSWriteFlattenGCells);
    if (arrays)
	CIFGenArrays(rootDef, area, CIFPlanes, GDSWriteFlattenGCells);
    
    /* Report any errors that occurred. */

    if (LayFeedbackCount != oldCount)
    {
	MsgInfoF("%d problems occurred.  See feedback entries.\n",
	    LayFeedbackCount - oldCount);
    }
    
    (void) sprintf(msg, "CIF layer \"%s\"", layer);
    cifSeeDef = rootDef;
    for (i = 0; i < CIFCurStyle->cs_nLayers; i++)
    {
	if (!TTMaskHasType(&mask, i)) continue;
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, CIFPlanes[i], &TiPlaneRect,
	    &CIFSolidBits, cifSeeFunc, (ClientData) msg);
    }
}
