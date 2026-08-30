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



/* selUndo.c -
 *
 *	This file provides routines for undo-ing and redo-ing the
 *	the selection.  Most of the undo-ing is handled automatically
 *	by enabling undo-ing when the selection cell is modified.
 *	All this file does is record things to be redisplayed, since
 *	the normal undo package won't handle that.
 *
 *      If undoing of selection is disabled (SelUndo reset), the routines
 *      in this file also bracket changes to the selection with 
 *      undo enable/disable calls.
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
static char rcsid[]="$Header: selUndo.c,v 6.0 90/08/28 18:56:50 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "undo.h"
#include "message.h"
#include "select.h"
#include "selInt.h"
#include "layout.h"

/* Each selection modification causes two records of the following
 * format to be added to the undo event list.  The first record
 * is added BEFORE the modification (sue_before is TRUE), and the
 * second is added afterwards.  The reason for doubling the events
 * is that we can't redisplay selection information until after the
 * selection has been modified.  This requires events to be in
 * different places depending on whether we're undo-ing or redo-ing.
 */

typedef struct
{
    CellDef *sue_def;		/* Definition in which selection must be
				 * redisplayed.
				 */
    Rect sue_area;		/* Area of sue_def in which selection info
				 * must be redisplayed.
				 */
    bool sue_before;		/* TRUE means this entry was made before
				 * the selection modifications.  FALSE
				 * means afterwards.
				 */
} SelUndoEvent;

/* Identifier for selection undo records: */
UndoType SelUndoClientID;

/* if reset, undo info is not kept for selection
 * (controlled by tcl command sel_undo) 
 */
bool SelUndo = FALSE;



/*
 * ----------------------------------------------------------------------------
 *
 * selUndoBracket--
 *
 * 	All changes to the selection should be bracket with this routine, ie.
 *      called before (before=TRUE) and after (before=FALSE).
 *      
 *      If selection undo is disabled, this routine disables undo during
 *      changes to the selection.
 *
 *      If selection undo is enabled, it stores the def and area to which
 *      the selection changes apply.
 *
 * ----------------------------------------------------------------------------
 */

void
selUndoBracket(int before, 
                		/* TRUE means caller is about to modify
				 * the given area of the selection.  FALSE
				 * means the caller has just modified
				 * the area.
				 */
		   CellDef *def, 
                 		/* Root definition on top of whom selection
				 * information was just modified.
				 */
		   Rect *area)
               			/* The area of def where selection info
				 * changed.  This pointer may be NULL, even
				 * on the second call, if there's no need
				 * to do redisplay during undo's.  This is
				 * the case if layout information is being
				 * modified over the area of the selection:
				 * when layout is redisplayed, selection info
				 * will automatically be redisplayed too.
				 */
{
    SelUndoEvent *sue;
    static SelUndoEvent *beforeEvent = NULL;
    static Rect nullRect = {0, 0, -1, -1};


    /* if undo info is not being kept, bracket changes to selection
     * with UndoDisable/UndoEnable calls.
     */
    if(!SelUndo) 
    {
      if(before) 
      {
	UndoDisable();
      }
      else
      {
	UndoEnable();
      }

      return;
    }

    sue = (SelUndoEvent *) UndoNewEvent(SelUndoClientID, sizeof(SelUndoEvent));
    if (sue == NULL) return;

    /* We don't have complete information when the "before" event is
     * created, so save around its address and fill in the event when
     * the "after" event is created.
     */
    
    if (before)
    {
	sue->sue_before = TRUE;
	sue->sue_def = NULL;

	ASSERT(beforeEvent == NULL, "Forgot to call selUndoBracket after");
	beforeEvent = sue;
    }
    else
    {
	if (area == NULL) area = &nullRect;
	sue->sue_def = def;
	sue->sue_area = *area;
	sue->sue_before = before;

	ASSERT(beforeEvent != NULL, "Forgot to call selUndoBracket before");
	beforeEvent->sue_def = def;
	beforeEvent->sue_area = *area;
	beforeEvent = NULL;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * selUndoTerm --
 *
 * 	Called after undo log played backwards or forwards. 
 *
 *
 * ----------------------------------------------------------------------------
 */

void
selUndoTerm(void)
{
  /* if selection undo info not kept, need to clear selection on undo */ 
  if(!SelUndo) SelectClear();
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelUndoForw --
 * SelUndoBack --
 *
 * 	Called to process undo redisplay events.  The two procedures
 *	are identical except that each one looks at different events.
 *	The idea is to do the selection redisplay only AFTER the selection
 *	has actually been modified.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Highlights (including the selection) are redisplayed.
 *
 * ----------------------------------------------------------------------------
 */

void
SelUndoForw(SelUndoEvent *sue)
                      		/* Event to be redone. */
{
    if (sue->sue_before) return;
    if (sue->sue_def == NULL) return;
    SelectRootDef = sue->sue_def;

    if (sue->sue_area.r_xbot <= sue->sue_area.r_xtop)
    {
      LayChangedDefSelection(sue->sue_def, &sue->sue_area, TRUE);
      DBChangedArea(SelectDef, &sue->sue_area, NULL, 0);
    }


}

void
SelUndoBack(SelUndoEvent *sue)
                      		/* Event to be undone. */
{
    if (!sue->sue_before) return;
    if (sue->sue_def == NULL) return;
    SelectRootDef = sue->sue_def;
    if (sue->sue_area.r_xbot <= sue->sue_area.r_xtop)
    {
      LayChangedDefSelection(sue->sue_def, &sue->sue_area, TRUE);
    }
    DBChangedArea(SelectDef, &sue->sue_area, NULL, 0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * SelUndoInit --
 *
 * 	Adds us as a client to the undo package.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Adds a new client to the undo package, and sets SelUndoClientID.
 *
 * ----------------------------------------------------------------------------
 */

void
SelUndoInit(void)
{
    extern void SelUndoForw(SelUndoEvent *sue), SelUndoBack(SelUndoEvent *sue);

    SelUndoClientID = UndoAddClient((void (*)()) NULL, 
				    selUndoTerm,
				    SelUndoForw, 
				    SelUndoBack, 
				    "selection redisplay");
    if (SelUndoClientID < (UndoType) 0)
	MsgErrorF("Couldn't add selection as an undo client!\n");
}
