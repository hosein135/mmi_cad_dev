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



/* Layfeedback.c -
 *
 *	This file provides a standard set of procedures for Magic
 *	commands to use to provide feedback to users.  Feedback
 *	consists of areas of the screen that are highlighted, along
 *	with text describing why those particular areas are important.
 *	Feedback is used for things like displaying CIF, and for errors
 *	in CIF-generation and routing.
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
static char rcsid[] = "$Header: Layfdback.c,v 6.0 90/08/28 18:11:22 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "utils.h"
#include "styles.h"
#include "malloc.h"
#include "signals.h"
#include "layout.h"
#include "layint.h"
#include "graphics.h"

/* The following stuff describes all the feedback information we know
 * about.  The feedback is stored in a big array that grows whenever
 * necessary.
 */

global int LayFeedbackCount = 0;	/* Number of active entries in
					 * layfbArray.
					 */

global Feedback *layfbArray = NULL;	/* Array holding all feedback info. */

static int layfbSize = 0;	        /* Size of layfbArray, in entries. */
static int layfbNextToShow = 0;		/* Index of first feedback area that
					 * hasn't been displayed yet.  Used by
					 * LayFBShow.
					 */

static CellDef *layfbRootDef;	/* To pass root cell definition from
				 * layfbGetTransform back up to
				 * LayFeedbackAdd.
				 */

/*
 * ----------------------------------------------------------------------------
 *
 * LayFeedbackClear --
 *
 * 	This procedure clears all existing feedback information.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Any existing feedback information is cleared from the screen
 *	and from our database.
 *
 * ----------------------------------------------------------------------------
 */

void
LayFeedbackClear(void)
{
    int i, oldCount;
    Feedback *fb;
    Rect area;
    CellDef *currentRoot;

    /* Clear out the feedback array and recycle string storage.  Whenever
     * the root cell changes, make a call to erase from the screen.
     */

    currentRoot = (CellDef *) NULL;
    oldCount = LayFeedbackCount;
    LayFeedbackCount = 0;
    for (i = 0, fb = layfbArray; i < oldCount; i++, fb++)
    {
	if (currentRoot != fb->fb_rootDef)
	{
	    if (currentRoot != (CellDef *) NULL)
		LayChangedHighlight(currentRoot, &area, TRUE);
	    area = GeoNullRect;
	}
	freeMagic(fb->fb_text);
	fb->fb_text = NULL;
	(void) GeoInclude(&fb->fb_rootArea, &area);
	currentRoot = fb->fb_rootDef;
    }
    if (currentRoot != NULL)
	LayChangedHighlight(currentRoot, &area, TRUE);
    layfbNextToShow = 0;
}
/* The following is a temporary hack until everyone else can change
 * their code.
 */
void
LayFeedbackInit(void)
{
    LayFeedbackClear();
}

/*
 * ----------------------------------------------------------------------------
 *
 * LayFeedbackAdd --
 *
 * 	Adds a new piece of feedback information to the list we have
 *	already.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	CellDef's ancestors are searched until its first root definition
 *	is found, and the coordinates of area are transformed into the
 *	root.  Then the feedback area is added to our current list, using
 *	the style and scalefactor given.  This stuff will be displayed on
 *	the screen at the end of the current command.
 * ----------------------------------------------------------------------------
 */

void
LayFeedbackAdd(Rect *area, 
               			/* The area to be highlighted. */
	       char *text, 
               			/* Text associated with the area. */
	       CellDef *cellDef, 
                     		/* The cellDef in whose coordinates area
				 * is given.
				 */
	       float scaleFactor, 
                    		/* The coordinates provided for feedback
				 * areas are divided by this to produce
				 * coordinates in Magic database units.
				 * This will probably be 1 most of the time.
				 * By making it bigger, say 10, and scaling
				 * other coordinates appropriately, it's
				 * possible to draw narrow lines on the
				 * screen, or to handle CIF, which isn't in
				 * exactly the same coordinates as other Magic
				 * stuff.
				 */
	       int style)

              			/* A display style to use for the feedback.
				 * Use one of:
				 * STYLE_FEEDBACK_OUTLINE:	solid outlines
				 * STYLE_FEEDBACK_SOLID:	dotted outlines
				 * STYLE_FEEDBACK_SOLID:	solid fill
				 * STYLE_FEEDBACK_MEDIUM:	medium stipple
				 * STYLE_FEEDBACK_PALE:	pald stipple
				 * At very coarse viewing scales, the last
				 * two styles are hard to see, so they are
				 * turned into STYLE_FEEDBACK_SOLID.
				 */
{
    Rect tmp, tmp2, tmp3;
    Transform transform;
    Feedback *fb;
    extern int layfbGetTransform(CellUse *use, Transform *transform, Transform *cdarg);	/* Forward declaration. */

    /* Find a transform from this cell to the root, and use it to
     * transform the area.  If the root isn't an ancestor, just
     * return.
     */
    
    if (!DBEnumRoots(cellDef, &GeoIdentityTransform,
	layfbGetTransform, (ClientData) &transform)) return;

    /* SigInterruptPending screws up DBEnumRoots */
    if (SigInterruptPending)
	return;

    /* Don't get fooled like I did.  The translations for
     * this transform are in Magic coordinates, not feedback
     * coordinates.  Scale them into feedback coordinates.
     */
    
    transform.t_c *= scaleFactor;
    transform.t_f *= scaleFactor;
    GeoTransRect(&transform, area, &tmp2);
    area = &tmp2;

    /* Make sure there's enough space in the current array.  If
     * not, make a new array, copy the old to the new, then delete
     * the old array.
     */
    
    if (LayFeedbackCount == layfbSize)
    {
	Feedback *new;
	int i;

	if (layfbSize == 0) layfbSize = 32;
	else layfbSize *= 2;
	new = (Feedback *) mallocMagic((unsigned) layfbSize*sizeof(Feedback));
	for (i = 0; i < layfbSize; i++)
	{
	    if (i < LayFeedbackCount) new[i] = layfbArray[i];
	    else new[i].fb_text = NULL;
	}
	if (layfbArray != NULL)
	    freeMagic((char *) layfbArray);
	layfbArray = new;
    }
    fb = &layfbArray[LayFeedbackCount];
    fb->fb_area = *area;
    (void) StrDup(&(fb->fb_text), text);
    fb->fb_rootDef = layfbRootDef;
    fb->fb_scale = scaleFactor;
    fb->fb_style = style;
    LayFeedbackCount += 1;

    /* Round the area up into Magic coords, and save it too. */
    if (area->r_xtop > 0)
	tmp.r_xtop = (area->r_xtop + scaleFactor - 1)/scaleFactor;
    else tmp.r_xtop = area->r_xtop/scaleFactor;
    if (area->r_ytop > 0)
	tmp.r_ytop = (area->r_ytop + scaleFactor - 1)/scaleFactor;
    else tmp.r_ytop = area->r_ytop/scaleFactor;
    if (area->r_xbot > 0) tmp.r_xbot = area->r_xbot/scaleFactor;
    else tmp.r_xbot = (area->r_xbot - scaleFactor + 1)/scaleFactor;
    if (area->r_ybot > 0) tmp.r_ybot = area->r_ybot/scaleFactor;
    else tmp.r_ybot = (area->r_ybot - scaleFactor + 1)/scaleFactor;

    /* Clip to ensure well within TiPlaneRect */
    tmp3.r_xbot = TiPlaneRect.r_xbot + 10;
    tmp3.r_ybot = TiPlaneRect.r_ybot + 10;
    tmp3.r_xtop = TiPlaneRect.r_xtop - 10;
    tmp3.r_ytop = TiPlaneRect.r_ytop - 10;
    GeoClip(&tmp, &tmp3);

    fb->fb_rootArea = tmp;

    /* Mark and schedule for redisplay */
    LayChangedHighlight(fb->fb_rootDef,&(fb->fb_rootArea),FALSE);
}

/* This utility procedure is invoked by DBEnumRoots.  Save the root definition
 * in layfbRootDef, save the transform in the argument, and abort the search.
 * Make sure that the root we pick is actually displayed in a window
 * someplace (there could be root cells that are no longer displayed
 * anywhere).
 */

int
layfbGetTransform(CellUse *use, Transform *transform, Transform *cdarg)
                 			/* A root use that is an ancestor
					 * of cellDef in LayFeedbackAdd.
					 */
                         		/* Transform up from cellDef to use. */
                     			/* Place to store transform from
					 * cellDef to its root def.
					 */
{
    extern int layfbWindFunc(void);
    if (use->cu_def->cd_flags & CDINTERNAL) return 0;
    if (!WindSearch((ClientData) use,
	    (Rect *) NULL, layfbWindFunc, (ClientData) NULL)) return 0;
    if (SigInterruptPending)
	return 0;
    layfbRootDef = use->cu_def;
    *cdarg = *transform;
    return 1;
}

/* This procedure is called if a window is found for the cell in
 * layfbGetTransform above.  It returns 1 to abort the search and
 * notify layfbGetTransform that there was a window for that root
 * cell.
 */

int
layfbWindFunc(void)
{
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 *
 * layFeedbackReportChanges --
 *
 * 	Called prior to highlight redisplay to determine areas where highlights
 *      need to be redisplayed due to changes in feedback areas.
 * 
 *	the screen.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All new feedback information that has been created since the
 *	last call to this procedure is added to the display.
 *
 * ----------------------------------------------------------------------------
 */

void
layFeedbackReportChanges(void)
{
    Rect area;
    CellDef *currentRoot;
    Feedback *fb;
    int i;

    /* Scan through all of the feedback areas starting with layfbNextToShow.
     * Save up the total bounding box until the root definition changes,
     * then redisplay what's been saved up so far.
     */

    currentRoot = NULL;
    for (i = layfbNextToShow, fb = &(layfbArray[layfbNextToShow]);
	i < LayFeedbackCount; i++, fb++)
    {
	if (currentRoot != fb->fb_rootDef)
	{
	    if (currentRoot != NULL)
		LayChangedHighlight(currentRoot, &area, FALSE);
	    area = GeoNullRect;
	}
	(void) GeoInclude(&fb->fb_rootArea, &area);
	currentRoot = fb->fb_rootDef;
    }
    if (currentRoot != NULL)
	LayChangedHighlight(currentRoot, &area, FALSE);
    layfbNextToShow = LayFeedbackCount;
}

/*
 * ----------------------------------------------------------------------------
 *
 * LayFeedbackNth --
 *
 * 	Provides the area and text associated with a particular
 *	feedback area.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The parameter "area" is filled with the area of the nth
 *	feedback, and the text of that feedback is returned. *pRootDef
 *	is filled in with rootDef for window of feedback area.  *pStyle
 *	is filled in with the display style for the feedback area.  If
 *	the particular area doesn't exist (nth >= LayFeedbackCount),
 *	area and *pRootDef  and *pStyle are untouched and NULL is
 *	returned.  NULL	may also be returned if there simply wasn't
 *	any text associated with the selected feedback.
 *
 * ----------------------------------------------------------------------------
 */

char *
LayFeedbackNth(int nth, Rect *area, CellDef **pRootDef, int *pStyle)
            			/* Selects which feedback area to return
				 * stuff from.  (0 <= nth < LayFeedbackCount)
				 */
               			/* To be filled in with area of feedback, in
				 * rounded-outward Magic coordinates.
				 */
                       		/* *pRootDef gets filled in with root def for
				 * this feedback area.  If pRootDef is NULL,
				 * nothing is touched.
				 */
                		/* *pStyle gets filled in with the display
				 * style for this feedback area.  If NULL,
				 * nothing is touched.
				 */
{
    if (nth >= LayFeedbackCount) return NULL;
    *area = layfbArray[nth].fb_rootArea;
    if (pRootDef != NULL) *pRootDef = layfbArray[nth].fb_rootDef;
    if (pStyle != NULL) *pStyle = layfbArray[nth].fb_style;
    return layfbArray[nth].fb_text;
}
