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
 * ExtYank.c --
 *
 * Circuit extraction.
 * Hierarchical yanking of paint and labels.
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
static char rcsid[] = "$Header: ExtYank.c,v 6.0 90/08/28 18:15:38 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <math.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "memory.h"
#include "message.h"
#include "debug.h"
#include "styles.h"
#include "extract.h"
#include "extractInt.h"

Rect extSubcellArea;		/* Area of currently processed subcell, clipped
				 * to area of interaction, in parent coords.
				 */

/* Forward declarations of filter functions */
int extHierYankFunc(CellUse *use, Transform *trans, int x, int y, HierYank *hy);
int extHierLabelFunc(SearchContext *scx, Label *label, TerminalPath *tpath, CellDef *targetDef);

/*
 * ----------------------------------------------------------------------------
 *
 * extHierCopyLabels --
 *
 * Copy the label list from sourceDef to targetDef, prepending
 * it to any labels already in targetDef.  Does not change
 * sourceDef's label list.
 *
 * Labels are copied in order, so the first label on sourceDef's
 * list becomes the first label on targetDef's list.  THIS IS
 * CRITICAL TO INSURE THAT HIERARCHICAL ADJUSTMENTS CAN BE MADE
 * PROPERLY; SEE extSubtreeAdjustInit() FOR AN EXPLANATION.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

extHierCopyLabels(CellDef *sourceDef, CellDef *targetDef)
{
    Label *revList;
    Label *lab;

    /* create copy of sourceDef labels in reverse order */
    revList = NULL;
    for (lab = sourceDef->cd_labels; lab; lab = lab->lab_next)
    {
      Label *new = DBLabelDup(lab);
      new->lab_next = revList;
      revList = new;
    }

    /* link list of labels into targetDef 
     *
     * (results in source defs labels being prepended to target def 
     *  in original order)
     */
    while(revList)
    {
      Label *top = revList;

      revList = top->lab_next;
      DBLabelLink(targetDef, top, DBLL_PREPEND);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * extHierYankFunc --
 *
 * Filter function normally called by DBEnumArrayElements to yank hierarchically the
 * paint and labels from 'use'.  Called for each array element.  Also called
 * during array extraction.
 *
 * Expects hy->hy_area to be the area, in parent coordinates,
 * to be yanked.  What we yank will be transformed to parent coordinates
 * and placed in the cell hy->hy_target.  If hy->hy_prefix is TRUE, we
 * will prepend all the labels we yank with the use id of this array
 * element; otherwise, the labels have no prefix.
 *
 * WARNING:
 *	Only node-name labels are yanked; attributes are not.
 *	The hierarchical extraction code depends on this fact.
 *
 * Results:
 *	Returns 0 to cause DBEnumArrayElements to keep going.
 *
 * Side effects:
 *	Adds paint and new labels to 'hy->hy_target'.
 *
 * ----------------------------------------------------------------------------
 */

extHierYankFunc(CellUse *use, Transform *trans, int x, int y, HierYank *hy)
                 	/* Use that is the root of the subtree being yanked */
                     	/* Transform from coordinates of use->cu_def to those
			 * in parent, for the array element (x, y).
			 */
             		/* Indices of this array element */
                 	/* See comments in procedure header */
{
    char labelBuf[4096];
    TerminalPath tpath;
    SearchContext scx;
    Transform tinv;

    /*
     * Want scx.scx_area to be the area in coordinates of use->cu_def
     * but hy->hy_area is in coordinates of parent.
     */
    GEOINVERTTRANS(trans, &tinv);
    GEOTRANSRECT(&tinv, hy->hy_area, &scx.scx_area);
    GEOCLIP(&scx.scx_area, &use->cu_def->cd_bbox);

    scx.scx_use = use;
    scx.scx_trans = *trans;
    scx.scx_x = x;
    scx.scx_y = y;

    /* Yank the paint */
    DBCellCopyAllPaint(&scx, &DBAllButSpaceBits, 0, hy->hy_target);

    /* Yank the labels */
    tpath.tp_next = tpath.tp_first = labelBuf;
    tpath.tp_last = &labelBuf[sizeof labelBuf - 2];
    if (hy->hy_prefix)
    {
	tpath.tp_next = DBSrPrintUseId(&scx, labelBuf, sizeof labelBuf - 3);
	*tpath.tp_next++ = '/';
    }
    *tpath.tp_next = '\0';

    (void) DBSearchLabels(&scx, &DBAllButSpaceBits, 0, &tpath, extHierLabelFunc,
		(ClientData) hy->hy_target->cu_def);

    return (0);
}

extHierLabelFunc(SearchContext *scx, Label *label, 
		 TerminalPath *tpath, CellDef *targetDef)
{
    register char *srcp, *dstp;
    Rect rect;
    int len;
    char newText[10000];

    /* Reject if the label falls over space */
    if (label->lab_type == TT_SPACE)
	return (0);

    /* Reject if not a node label */
    if (!extLabType(label->lab_text, LABTYPE_NAME))
	return (0);

    /* Construct text of new label */
    dstp = newText;
    for (srcp = tpath->tp_first; *dstp++ = *srcp++; )
	/* Nothing */;
    for (--dstp, srcp = label->lab_text; *dstp++ = *srcp++; )
	/* Nothing */;

    /* new label area */
    GeoTransRect(&scx->scx_trans, &label->lab_rect, &rect);

    /* add new label to target def */
    (void) DBLabelAdd(targetDef, 
		      &rect, 
		      label->lab_pos,
		      newText,
		      label->lab_type,
		      label->lab_kind);
    
    return 0;
}
