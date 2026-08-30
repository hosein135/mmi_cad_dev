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
 * CmdSubrs.c --
 *
 * The functions in this file are local to the commands module
 * and not intended to be used by its clients.
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
static char rcsid[] = "$Header: CmdSubrs.c,v 6.1 90/09/13 12:07:54 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "geometry.h"
#include "utils.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "layout.h"
#include "main.h"
#include "commands.h"
#include "message.h"
#include "drc.h"
#include "undo.h"
#include "Mgc.h"
#include "mgcint.h"


/*
 * ----------------------------------------------------------------------------
 *
 * CmdParseLayers --
 *
 * Convert a string specifying a collection of layers into a TileTypeBitMask
 * representing the layers specified.
 *
 * A special layer, '$', refers to all tile types underneath the point
 * tool, except for the DRC "CHECKxxx" types.
 *
 * The layer '*' refers to all tile types except for "check-this" and
 * the label and cell pseudo-types.
 *
 * Results:
 *	TRUE on success, FALSE if any layers are unrecognized.
 *
 * Side effects:
 *	Prints an error message if any layers are unrecognized.
 *	Sets bits in 'mask' according to layers in layer specification.
 *	Leaves 'mask' set to 0 if any layers are unrecognized.
 *
 *	Eventually, this routine should return a "minimal" TileTypeBitMask,
 *	ie, one with the minimum number of bits set consistent with the
 *	string supplied it.
 *
 * ----------------------------------------------------------------------------
 */

bool
CmdParseLayers(char *s, TileTypeBitMask *mask)
{
    TileTypeBitMask newmask;
    register char *dp, c;
    char name[50];
    TileType type;
    bool adding = TRUE;
    int which, i;
#define LN_CELL		0
#define LN_LABELS	1
#define LN_ALL		2
#define LN_DOLLAR	3
#define LN_ERRORS	4

    static struct
    {
	char *layer_name;
	int layer_value;
    }
    special[] =
    {
	"$",		LN_DOLLAR,
	"*",		LN_ALL,
	"errors",	LN_ERRORS,
	"labels",	LN_LABELS,
	"subcell",	LN_CELL,
	0,
    };

    TTMaskZero(mask);
    while (c = *s++)
    {
	switch (c)
	{
	    case '-':
		adding = FALSE;
		continue;
	    case '+':
		adding = TRUE;
		continue;
	    case ',':
	    case ' ':
		continue;
	}

	dp = name; *dp++ = c;
	while (*s && *s != ',' && *s != '+' && *s != '-' && *s != ' ')
	    *dp++ = *s++;
	*dp = '\0';
	if (name[0] == '\0')
	    continue;

	TTMaskZero(&newmask);
	which = LookupStruct(name, (LookupTable *) special, sizeof special[0]);
	if (which >= 0)
	{
	    switch (special[which].layer_value)
	    {
		case LN_LABELS:
		    TTMaskSetType(&newmask, L_LABEL);
		    break;
		case LN_CELL:
		    TTMaskSetType(&newmask, L_CELL);
		    break;
		/*
		 * All layers currently beneath the point tool.
		 * Currently, neither labels nor cells are ever included
		 * in this.
		 */
		case LN_DOLLAR:
		{
		  TileTypeBitMask tempMask;
		  Layout *w;
		  Point rootPoint;

		  w = CmdGetRootPoint(&rootPoint, NULL);
		  if (!w) return (FALSE);
		  

		  newmask = DBSrTouchingTypes(w->lay_rootUse, 
					      w->lay_bitmask,
					      &rootPoint, 
					      0 /* flags */);
		    
		  TTMaskAndMask(&newmask, &w->lay_visibleLayers);
		  tempMask = DBAllButSpaceAndDRCBits;
		  TTMaskSetType(&tempMask, TT_SPACE);
		  TTMaskAndMask(&newmask, &tempMask);
		  break;
		}
		/*
		 * Everything but labels and subcells
		 */
		case LN_ALL:
		    newmask = DBAllButSpaceAndDRCBits;
		    TTMaskClearType(&newmask, L_LABEL);
		    TTMaskClearType(&newmask, L_CELL);
		    break;
		/*
		 * All DRC error layers.
		 */
		case LN_ERRORS:
		    TTMaskSetType(&newmask, TT_ERROR_P);
		    TTMaskSetType(&newmask, TT_ERROR_S);
		    TTMaskSetType(&newmask, TT_ERROR_PS);
		    break;
	    }
	}
	else
	{
	    type = DBTechNameType(name);
	    switch (type)
	    {
		case -2:
		    MsgErrorF("Unrecognized layer: %s\n", name);
		    printTypes:
		    DBTechPrintTypes();
		    for (i = 0; ; i++)
		    {
			if (special[i].layer_name == NULL) break;
			MsgInfoF("    %s\n", special[i].layer_name);
		    }
		    return (FALSE);
		case -1:
		    MsgErrorF("Ambiguous layer: %s\n", name);
		    goto printTypes;
	    }
	    TTMaskSetType(&newmask, type);
	}

	if (adding)
	{
	    TTMaskSetMask(mask, &newmask);
	}
	else
	{
	    TTMaskClearMask(mask, &newmask);
	}
    }

    return (TRUE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cmdMaskToType --
 *
 * Convert a TileTypeBitMask into a TileType.
 *
 * Results:
 *	Returns -1 if more than one type bit is set in the TileTypeBitMask;
 *	otherwise, returns the TileType of the bit set.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

TileType
cmdMaskToType(TileTypeBitMask *mask)
{
    TileType type, t;

    type = -1;
    for (t = TT_SELECTBASE; t < DBNumTypes; t++)
    {
	if (TTMaskHasType(mask, t))
	{
	    if (type >= 0)
		return (-1);
	    type = t;
	}
    }

    if (type < 0)
	return (TT_SPACE);
    return (type);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdGetRootPoint --
 *
 * Get the window containing the point tool, and return (in root cell
 * coordinates for that window) the coordinates of the point, and of
 * a minimum-grid-size rectangle enclosing the point.
 *
 * Results:
 *	Pointer to window containing the point tool, or NULL if the
 *	point tool is not present.
 *
 * Side effects:
 *	Sets *point to be the coordinates of the point tool in root
 *	coordinates, and *rect to be the minimum-grid-size enclosing
 *	rectangle.
 *
 *	Prints an error message if the point is not found.
 *
 *      If either arg is null pointer, it is not set.
 *
 *
 * ----------------------------------------------------------------------------
 */

Layout *
CmdGetRootPoint(Point *point, Rect *rect)
{
    Layout *window;

    window = LayPointGet(point, rect);
    if (window == (Layout *) NULL)
	MsgErrorF("Cursor not in a valid window for this command\n");

    return (window);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdGetEditPoint --
 *
 * Get the window containing the point tool, and return (in edit cell
 * coordinates for that window) the coordinates of the point, and of
 * a minimum-grid-size rectangle enclosing the point.
 *
 * Results:
 *	Pointer to window containing the point tool, or NULL if the
 *	point tool is not present.
 *
 * Side effects:
 *	Sets *point to be the coordinates of the point tool in edit
 *	coordinates, and *rect to be the minimum-grid-size enclosing
 *	rectangle.
 *
 *      If either arg is null pointer, it is not set.
 *
 * ----------------------------------------------------------------------------
 */

Layout *
CmdGetEditPoint(Point *point, Rect *rect)
{
    Layout *window;
    Rect rootRect;
    Point rootPoint;

    window = CmdGetRootPoint(&rootPoint, &rootRect);
    if (window != (Layout *) NULL)
    {
	if(rect) GeoTransRect(&RootToEditTransform, &rootRect, rect);
	if(point) GeoTransPoint(&RootToEditTransform, &rootPoint, point);
    }

    return (window);
}


/*
 * ----------------------------------------------------------------------------
 * cmdExpandOneLevel --
 *
 *	Expand (unexpand) a cell, and unexpand all of its children.  This is 
 *	called by commands such as getcell, expand current cell, and load.
 *	Don't bother to unexpand children if we are unexpanding this cell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 * ----------------------------------------------------------------------------
 */

int
cmdExpand1func(CellUse *cu, ClientData bitmask)
{
    DBExpand(cu, (int) bitmask, FALSE);
    return 0;
}

void
cmdExpandOneLevel(CellUse *cu, int bitmask, int expand)
{
    extern int cmdExpand1func(CellUse *cu, ClientData bitmask);

    /* first, expand this cell use */
    DBExpand(cu, bitmask, expand);

    /* now, unexpand its direct children (ONE LEVEL ONLY) */
    if (expand)
	(void) DBEnumChildren(cu->cu_def, cmdExpand1func, (ClientData) bitmask);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdGetSelectedCell --
 *
 * 	This procedure returns a pointer to the selected cell.
 *
 * Results:
 *	The return value is a pointer to the selected cell.  If more
 *	than one cell is selected, the upper-leftmost cell is returned.
 *	If no cell is selected, NULL is returned.
 *
 * Side effects:
 *	If pTrans isn't NULL, the area it points to is modified to hold
 *	the transform from coords of the selected cell to root coords.
 *
 * ----------------------------------------------------------------------------
 */

Transform *cmdSelTrans;		/* Shared between CmdGetSelectedCell and
				 * cmdGetCellFunc.
				 */

CellUse *
CmdGetSelectedCell(Transform *pTrans)
                      		/* If non-NULL, transform from selected
				 * cell to root coords is stored here.
				 */
{
    CellUse *result = NULL;
    int cmdGetSelFunc(CellUse *selUse, 
		      CellUse *realUse, 
		      Transform *transform, 
		      TerminalPath *tPath,
		      CellUse **pResult);		/* Forward declaration. */

    cmdSelTrans = pTrans;
    (void) SelEnumCells(FALSE, 
			(bool *) NULL, 
			(SearchContext *) NULL,
			(TerminalPath *) NULL,
			(TerminalPath *) NULL,
			cmdGetSelFunc, 
			(ClientData) &result);
    return result;
}

	/* ARGSUSED */
int
cmdGetSelFunc(CellUse *selUse,      /* Not used. */
	      CellUse *realUse,     /* The first selected use. */
	      Transform *transform, /* Transform from coords of realUse to root. */
	      TerminalPath *tPath,  /* Not used. */
	      CellUse **pResult)    /* Store realUse here. */
{
    *pResult = realUse;
    if (cmdSelTrans != NULL)
	*cmdSelTrans = *transform;
    return 1;			/* Skip any other selected cells. */
}
