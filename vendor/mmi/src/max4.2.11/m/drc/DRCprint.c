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
 * DRCPrint.c --
 *
 * Edge-based design rule checker
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

#ifndef	lint
static char rcsid[] = "$Header: DRCprint.c,v 6.4 92/08/03 18:07:01 mayo Exp $";
#endif	not lint

#include <stdio.h>
#include <sys/types.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "drc.h"

extern char *maskToPrint(TileTypeBitMask *mask);
extern char *DBTypeShortName(TileType);

/*
 * ----------------------------------------------------------------------------
 *
 * drcGetName --
 *
 * 	This is a utility procedure that returns a convenient name for
 *	a mask layer.
 *
 * Results:
 *	The result is the first N characters of the long name for
 *	the layer.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

char *
drcGetName(int layer, char *string, int n)
              
                 		/* Used to hold name.  Must have length >= 8 */
{
    extern char *strncpy(char *, const char *, size_t);
    (void) strncpy(string, DBTypeShortName(layer), n);
    string[n] = '\0';
    if (layer == TT_SPACE) return "space";
    return string;
}


/*
 * ----------------------------------------------------------------------------
 * DRCPrintRulesTable --
 *
 *	Write compiled DRC rules table and adjacency matrix to the given file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 * ----------------------------------------------------------------------------
 */

void
DRCPrintRulesTable (FILE *fp)
{
    int		  i, j, k;
    int plane;
    DRCCookie	* dp;
    char buf1[60], buf2[60];
    int gotAny;
					/* print the rules table */
    for (i = 0; i < DBNumTypes; i++)
    {
	gotAny = FALSE;
	for (j = 0; j < DBNumTypes; j++)
	{
	    if (DRCRulesTbl [i][j] != (DRCCookie *) NULL)
	    {
		k = 1;
	        for (dp = DRCRulesTbl [i][j]; dp != (DRCCookie *) NULL;
			      dp = dp->drcc_next)
		{
		    gotAny = TRUE;
		    if (k == 1)
		    {
			(void) fprintf(fp,"\n%s --- %s\n",
			    drcGetName(i, buf1, 50), drcGetName(j, buf2, 50));
			k++;
		    }
		    (void) fprintf(fp,"\t%d x %d   %s\n",
			dp->drcc_dist, dp->drcc_cdist,
			maskToPrint(&dp->drcc_mask));
		    (void) fprintf(fp,"\t%s",
			maskToPrint(&dp->drcc_corner));
		    if (dp->drcc_flags &
			    (DRC_REVERSE|DRC_BOTHCORNERS|DRC_XPLANE))
			(void) fprintf(fp, "\n\t");
		    if (dp->drcc_flags & DRC_REVERSE)
			(void) fprintf(fp," reverse");
		    if (dp->drcc_flags & DRC_BOTHCORNERS)
			(void) fprintf(fp," both-corners");
		    if (dp->drcc_flags & DRC_XPLANE)
			(void) fprintf(fp," cross-plane(%s)",
			    DBPlaneLongName(dp->drcc_plane));
		    (void) fprintf(fp," \"%s\"\n", dp->drcc_why);
	        }
	    }
	}
	if (gotAny) (void) fprintf(fp,"\n");
    }

    /* Print out overlaps that are illegal between subcells. */

    for (plane = 0; plane < DBNumPlanes; plane++)
    {
	fprintf(fp, "\nPlane %s:\n", DBPlaneShortName(plane));
	for (i = 0; i < DBNumTypes; i++)
	{
	    for (j = 0; j < DBNumTypes; j++)
	    {
		if ((i == TT_ERROR_S) || (j == TT_ERROR_S)) continue;
		if (DRCPaintTable[plane][i][j] == TT_ERROR_S)
		    (void) fprintf(fp, "\tTile type %s can't overlap type %s.\n",
			drcGetName(i, buf1, 50), drcGetName(j, buf2, 50) );
	    }
	}
    }

    /* Print out tile types that must have exact overlaps. */

    if (!TTMaskIsZero(&DRCExactOverlapTypes))
    {
	(void) fprintf(fp, "Types that must overlap exactly: %s\n",
	    maskToPrint(&DRCExactOverlapTypes));
    }
}

char *
maskToPrint (TileTypeBitMask *mask)
{
    int	i;
    int gotSome = FALSE;
    static char printchain[1000];
    char buffer[60];

    if (TTMaskIsZero(mask))
	return "<none>";

    printchain[0] = '\0';

    for (i = 0; i < DBNumTypes; i++)
	if (TTMaskHasType(mask, i))
	{
	    if (gotSome) strcat(printchain, ",");
	    else gotSome = TRUE;
	    strcat(printchain, drcGetName(i, buffer, 50));
	}

    return (printchain);
}
