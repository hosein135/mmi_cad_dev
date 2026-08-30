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



/* cifMain.c -
 *
 *	This file contains global information for the CIF module,
 *	such as performance statistics.
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
static char rcsid[] = "$Header: CIFmain.c,v 6.0 90/08/28 18:05:06 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "message.h"
#include "layout.h"
#include "layout.h"
#include "styles.h"
#include "cifInt.h"
#include "cif.h"

/* unit sizes (determined by current cifoutput style) exported to rest of Max 
 * (intialized so Max can run with empty cif section of tech file).
 */
double CIFDBRes = 1.0; 	 /* size of max database unit in microns */
double CIFPlaneRes = .01; /* size of CIF plane unit in microns 
			  * (cif planes used for ops when generating gds or cif
			  * and also for drc)
			  */
double CIFRes = .01;      /* size of cifoutput unit in microns */
double CIFGDSRes = .001;  /* size of gds output unit in microns */

/* The following points to a list of all the CIF output styles
 * currently understood:
 */
CIFStyle *CIFStyleList;

/* The current style being used for CIF output: */

CIFStyle *CIFCurStyle = NULL;

/* The following are statistics gathered at various points in
 * CIF processing.  There are two versions of each statistic:
 * a total number, and the number since stats were last printed.
 */
int CIFTileOps = 0;		/* Total tiles touched in geometrical
				 * operations.
				 */
int CIFHierTileOps = 0;		/* Tiles touched in geometrical operations
				 * as part of hierarchical processing.
				 */
int CIFRects = 0;		/* Total CIF rectangles output. */
int CIFHierRects = 0;		/* Rectangles stemming from interactions. */

static int cifTotalTileOps = 0;
static int cifTotalHierTileOps = 0;
static int cifTotalRects = 0;
static int cifTotalHierRects = 0;

/* This file provides several procedures for dealing with errors during
 * the CIF generation process.  Low-level CIF artwork-manipulation
 * procedures call CIFError without knowing what cell CIF is being
 * generated for, or what layer is being generated.  Higher-level
 * routines are responsible for recording that information in the
 * variables below so that CIFError can output meaningful diagnostics
 * using the feedback mechanism.
 */

global CellDef *CIFErrorDef;	/* Definition in which to record errors. */
global int CIFErrorLayer;	/* Index of CIF layer associated with errors.*/


/*
 * ----------------------------------------------------------------------------
 *
 * CIFPrintStats --
 *
 * 	This procedure prints out CIF statistics including both
 *	total values and counts since the last printing.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Several messages are printed.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFPrintStats(void)
{
    MsgInfoF("CIF statistics (recent/total):\n");
    cifTotalTileOps += CIFTileOps;
    MsgInfoF("    Geometrical tile operations: %d/%d\n",
	CIFTileOps, cifTotalTileOps);
    CIFTileOps = 0;
    cifTotalHierTileOps += CIFHierTileOps;
    MsgInfoF("    Tile operations for hierarchy: %d/%d\n",
	CIFHierTileOps, cifTotalHierTileOps);
    CIFHierTileOps = 0;
    cifTotalRects += CIFRects;
    MsgInfoF("    CIF rectangles output: %d/%d\n",
	CIFRects, cifTotalRects);
    CIFRects = 0;
    cifTotalHierRects += CIFHierRects;
    MsgInfoF("    CIF rectangles due to hierarchical interactions: %d/%d\n",
	CIFHierRects, cifTotalHierRects);
    CIFHierRects = 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFSetStyle --
 *
 * 	This procedure changes the current CIF output style to the one
 *	named by the parameter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The current CIF style is changed.  If the name doesn't match,
 *	or is ambiguous, then a list of all CIF styles is output.
 *
 *      The variables exporting unit sizes are set to this style.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFSetStyle(char *name)
               			/* Name of the new style.  If NULL, just
				 * print out the valid styles.
				 */
{
    CIFStyle *style, *match;
    int length;

    if (name == NULL) goto badStyle;
    length = strlen(name);
    match = NULL;
    for (style = CIFStyleList; style != NULL; style = style->cs_next)
    {
	if (strncmp(name, style->cs_name, length) == 0)
	{
	    if (match != NULL)
	    {
		MsgErrorF("CIF output style \"%s\" is ambiguous.\n", name);
		goto badStyle;
	    }
	    match = style;
	}
    }

    if (match != NULL)
    {
	CIFCurStyle = match;
	CIFDBRes = CIFCurStyle->cs_DBRes;
	CIFPlaneRes = CIFCurStyle->cs_CIFPlaneRes;
	CIFRes = CIFCurStyle->cs_CIFRes;
	CIFGDSRes = CIFCurStyle->cs_GDSRes;
	return;
    }

    MsgErrorF("\"%s\" is not one of the CIF output styles for the current technology.\n", name);
    badStyle:
    MsgInfoF("The CIF output styles are: ");
    for (style = CIFStyleList; style != NULL; style = style->cs_next)
    {
	if (style == CIFStyleList)
	    MsgInfoF("%s", style->cs_name);
	else MsgInfoF(", %s", style->cs_name);
    }
    MsgInfoF(".\n");
    if (CIFCurStyle != NULL)
	MsgInfoF("The current style is \"%s\".\n", CIFCurStyle->cs_name);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFNameToMask --
 *
 * 	Finds the CIF planes for a given name.
 *
 * Results:
 *	TRUE if successful, FALSE if "name" failed to match any layers.
 *
 * Side effects:
 *	If there's no match, then an error message is output.
 *	The sets 'result' to be all types containing the CIF layer named
 *	"name".  The current CIF style is used for the lookup.
 * ----------------------------------------------------------------------------
 */

bool
CIFNameToMask(char *name, TileTypeBitMask *result)
{
    int i;

    TTMaskZero(result);
    for (i = 0;  i < CIFCurStyle->cs_nLayers; i+=1)
    {
	if (strcmp(name, CIFCurStyle->cs_layers[i]->cl_name) == 0)
	{
	    TTMaskSetType(result, i);
	}
    }

    if (!TTMaskEqual(result, &DBZeroTypeBits)) return (TRUE);

    MsgErrorF("CIF name \"%s\" doesn't exist in style \"%s\".\n", name,
	CIFCurStyle->cs_name);
    MsgErrorF("The valid CIF layer names are: ");
    for (i = 0; i < CIFCurStyle->cs_nLayers; i++)
    {
	if (i == 0)
	    MsgErrorF("%s", CIFCurStyle->cs_layers[i]->cl_name);
	else
	    MsgErrorF(", %s", CIFCurStyle->cs_layers[i]->cl_name);
    }
    MsgErrorF(".\n");
    return (FALSE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFError --
 *
 * 	This procedure is called by low-level CIF generation routines
 *	when a problem is encountered in generating CIF.  This procedure
 *	notes the problem using the feedback mechanism.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Feedback information is added.  The caller must have set CIFErrorDef
 *	to point to the cell definition that area refers to.  If CIFErrorDef
 *	is NULL, then errors are ignored.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFError(Rect *area, char *message)
               			/* Place in CIFErrorDef where there was a
				 * problem in generating CIFErrorLayer.
				 */
                  		/* Short note about what went wrong. */
{
    char msg[200];

    if (CIFErrorDef == (NULL)) return;
    (void) sprintf(msg, "Mask operation error in cell %s, layer %s: %s",
	CIFErrorDef->cd_name, CIFCurStyle->cs_layers[CIFErrorLayer]->cl_name,
	message);
    LayFeedbackAdd(area, 
		   msg, 
		   CIFErrorDef, 
		   CIFDBRes/CIFPlaneRes,
		   STYLE_FEEDBACK_PALE);
}


