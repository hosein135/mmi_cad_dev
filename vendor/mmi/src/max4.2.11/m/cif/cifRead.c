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



/* cifRead.c -
 *
 *	This file contains routines that parse a file in CIF
 *	format.  This file contains the top-level routine for
 *	reading CIF files, plus a bunch of utility routines
 *	for skipping white space, parsing numbers and points, etc.
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
static char rcsid[] = "$Header: CIFrdutils.c,v 6.0 90/08/28 18:05:18 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "message.h"
#include "signals.h"
#include "undo.h"
#include "malloc.h"
#include "cifInt.h"
#include "cifRead.h"
#include "cif.h"

/* The following variables are used to provide one character of
 * lookahead.  cifParseLaAvail is TRUE if cifParseLaChar contains
 * a valid character, FALSE otherwise.  The PEEK and TAKE macros
 * are used to manipulate this stuff.
 */

bool cifParseLaAvail = FALSE;
int cifParseLaChar = EOF;

/* Below is a variable pointing to the CIF input file.  It's used
 * by the PEEK and TAKE macros.  The other stuff is used to keep
 * track of our location in the CIF file for error reporting
 * purposes.
 */

FILE *cifInputFile;
int cifLineNumber;		/* Number of current line. */

/* The variables used below hold general information about what
 * we're currently working on.
 */

int cifReadScale1;			/* Scale factor:  multiply by Scale1 */
int cifReadScale2;			/* then divide by Scale2. */
Plane *cifReadPlane;			/* Plane into which to paint material
					 * NULL means no layer command has
					 * been seen for the current cell.
					 */

/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadError --
 *
 * 	This procedure is called to print out error messages during
 *	CIF file reading.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An error message is printed.
 *
 * Note:
 *	You can add more arguments if three turns out not to be enough.
 *
 * ----------------------------------------------------------------------------
 */
void
CIFReadError(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    MsgErrorF("Error at line %d of CIF file: ", cifLineNumber);
    MsgErrorV(fmt, args);

    va_end(args);
}



/*
 * ----------------------------------------------------------------------------
 *
 * CIFMakeManhattanPath --
 *
 *	Convert a non-Manhattan path into a Manhattan one by adding
 *	additional points.  These points are added using a simple
 *	scan-conversion algorithm that generates a series of stair
 *	steps that are at least one Max Database units
 *	high and wide (but which may be higher or wider).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May insert additional points in the path.
 *
 * ----------------------------------------------------------------------------
 */

void CIFMakeManhattanPath(CIFPath *pathHead)
{
    register CIFPath *new, *next, *path;
    int xinit, xdiff, xincr, xlast, x;
    int yinit, ydiff, yincr, ylast, y;
    int minIncr = MAX(1.0, (1.0 / cifRdScaleCIFPlane2DB)); 

    for (path = pathHead; path->cifp_next; path = path->cifp_next)
    {
	next = path->cifp_next;

	/* No work if this segment is Manhattan */
	if (path->cifp_x == next->cifp_x || path->cifp_y == next->cifp_y)
	    continue;

	/*
	 * The major loop will be over whichever difference (x or y)
	 * is the SMALLER of the two; for each iteration over the smaller
	 * dimension, we will add the number of units of the larger
	 * dimension per unit of the smaller dimension to the larger
	 * dimension.
	 */
	xdiff = next->cifp_x - path->cifp_x;
	ydiff = next->cifp_y - path->cifp_y;
	xinit = path->cifp_x;
	yinit = path->cifp_y;
	if (ABS(xdiff) > ABS(ydiff))
	{
	    /* Iterate over y, stopping before next->cifp_y */
	    yincr = minIncr;
	    ylast = yinit;
	    if (ydiff < 0) yincr = -yincr;
	    for (y = yinit + yincr, x = xinit;
			(yincr > 0 && y < next->cifp_y)
		     || (yincr < 0 && y > next->cifp_y);
		    y += yincr)
	    {
		/* Move by one in y first */
		MALLOC(CIFPath *, new, sizeof (CIFPath));
		new->cifp_x = x;
		new->cifp_y = y;
		path->cifp_next = new;
		path = new;

		/*
		 * Now move in x.
		 * Note that ((y - yinit) / ydiff) >= 0 always.
		 * Also, as long as y has not reached next->cifp_y,
		 * this quantity will be < 1, so x will range from
		 * path->cifp_x up to but not reaching next->cifp_x.
		 */
		x = xinit + (xdiff * (y - yinit)) / ydiff;
		MALLOC(CIFPath *, new, sizeof (CIFPath));
		new->cifp_x = x;
		new->cifp_y = y;
		new->cifp_next = next;
		path->cifp_next = new;
		path = new;
		ylast = y;
	    }

	    /*
	     * The last y processed was short of next->cifp_y.
	     * If x was not yet at next->cifp_x, add one more point
	     * to bridge the gap.
	     */
	    if (x != next->cifp_x)
	    {
		MALLOC(CIFPath *, new, sizeof (CIFPath));
		new->cifp_x = next->cifp_x;
		new->cifp_y = ylast;;
		new->cifp_next = next;
		path->cifp_next = new;
		path = new;
	    }
	}
	else
	{
	    /* Iterate over x, stopping before next->cifp_x */
	    xincr = minIncr;
	    xlast = xinit;
	    if (xdiff < 0) xincr = -xincr;
	    for (x = xinit + xincr, y = yinit;
			(xincr > 0 && x < next->cifp_x)
		     || (xincr < 0 && x > next->cifp_x);
		x += xincr)
	    {
		/* Move by one in x first */
		MALLOC(CIFPath *, new, sizeof (CIFPath));
		new->cifp_x = x;
		new->cifp_y = y;
		path->cifp_next = new;
		path = new;

		/*
		 * Now move in y.
		 * Note that ((x - xinit) / xdiff) >= 0 always.
		 * Also, as long as x has not reached next->cifp_x,
		 * this quantity will be < 1, so y will range from
		 * path->cifp_y up to but not reaching next->cifp_y.
		 */
		y = yinit + (ydiff * (x - xinit)) / xdiff;
		MALLOC(CIFPath *, new, sizeof (CIFPath));
		new->cifp_x = x;
		new->cifp_y = y;
		new->cifp_next = next;
		path->cifp_next = new;
		path = new;
		xlast = x;
	    }

	    /*
	     * The last x processed was short of next->cifp_x.
	     * If y was not yet at next->cifp_y, add one more point
	     * to bridge the gap.
	     */
	    if (y != next->cifp_y)
	    {
		MALLOC(CIFPath *, new, sizeof (CIFPath));
		new->cifp_x = xlast;
		new->cifp_y = next->cifp_y;
		new->cifp_next = next;
		path->cifp_next = new;
		path = new;
	    }
	}
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFFreePath --
 *
 * 	This procedure frees up a path once it has been used.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All the elements of path are returned to the storage allocator.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFFreePath(CIFPath *path)
                  		/* Path to be freed. */
{
    while (path != NULL)
    {
	freeMagic((char *) path);
	path = path->cifp_next;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * CIFDirectionToTrans --
 *
 * 	This procedure is used to convert from a direction vector
 *	to a Magic transformation.  The direction vector is a point
 *	giving a direction from the origin.  It better be along
 *	one of the axes.
 *
 * Results:
 *	The return value is the transformation corresponding to
 *	the direction, or the identity transform if the direction
 *	isn't along one of the axes.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

Transform *
CIFDirectionToTrans(Point *point)
                 		/* Direction vector from origin. */
{
    if ((point->p_x != 0) && (point->p_y == 0))
    {
	if (point->p_x > 0)
	    return &GeoIdentityTransform;
	else return &Geo180Transform;
    }
    else if ((point->p_y != 0) && (point->p_x == 0))
    {
	if (point->p_y > 0)
	    return &Geo270Transform;
	else return &Geo90Transform;
    }
    CIFReadError("non-manhattan direction vector (%d, %d); ignored.\n",
	point->p_x, point->p_y);
    return &GeoIdentityTransform;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CIFSetReadStyle --
 *
 * 	This procedure changes the current style used for reading
 *	CIF.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The CIF style is changed to the one specified by name.  If
 *	there is no style by that name, then a list of all valid
 *	styles is output.
 *
 * ----------------------------------------------------------------------------
 */

void
CIFSetReadStyle(char *name)
               			/* Name of the new style.  If NULL,
				 * just print the name of the current
				 * style.
				 */
{
    CIFReadStyle *style, *match;
    int length;

    match = NULL;
    if (name == NULL) goto badStyle;
    length = strlen(name);
    for (style = cifReadStyleList; style != NULL; style = style->crs_next)
    {
	if (strncmp(name, style->crs_name, length) == 0)
	{
	    if (match != NULL)
	    {
		MsgErrorF("CIF input style \"%s\" is ambiguous.\n", name);
		goto badStyle;
	    }
	    match = style;
	}
    }

    if (match != NULL)
    {
	cifCurReadStyle = match;
	return;
    }

    MsgErrorF("\"%s\" is not a valid input style for this technology.\n", name);
    badStyle:
    MsgInfoF("The CIF input styles are: ");
    for (style = cifReadStyleList; style != NULL; style = style->crs_next)
    {
	if (style == cifReadStyleList)
	    MsgInfoF("%s", style->crs_name);
	else MsgInfoF(", %s", style->crs_name);
    }
    MsgInfoF(".\n");
    if (cifCurReadStyle != NULL)
        MsgInfoF("The current style is \"%s\".\n", cifCurReadStyle->crs_name);
}
