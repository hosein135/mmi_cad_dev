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
 * Layundo.c --
 *
 *	Procedures for undoing/redoing operations associated
 *	with the layind module.
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
static char rcsid[] = "$Header: Layundo.c,v 6.0 90/08/28 18:11:31 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "layout.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "main.h"
#include "layout.h"
#include "undo.h"
#include "message.h"
#include "commands.h"

/*
 * Client identifiers returned by the undo package
 * in layUndoInit().
 */
UndoType layUndoIDOldEdit, layUndoIDNewEdit, 
         layUndoIDLoad,
         layUndoIDBox;

/* Structure used for undo-ing window loads.
 * contains pointer to window and old and new cell defs.
 * NOTE:  Must invalidate undo on window closings, or cell deletions,
 *        to avoid stale pointers.
 */
typedef struct
{
    Layout  *lue_layout;
    CellDef *lue_newDef;
    CellDef *lue_oldDef;
} LoadUndoEvent;

/* Structure used for undo-ing changes in the box.  It just holds the
 * box's old and new locations.
 */

typedef struct
{
    CellDef *bue_oldDef;
    Rect bue_oldArea;
    CellDef *bue_newDef;
    Rect bue_newArea;
} BoxUndoEvent;

/*
 * Structure to hold all the information needed to switch
 * to a new edit cell.  We rely upon the fact that undo info is cleared when 
 * ever a CellDef is deleted, so it is safe to retain pointers to defs.
 * The defs, transform, and use identifier are used to identify
 * uniquely the cell use affected.
 */
typedef struct
{
    Transform	 e_editToRoot;	/* Transform to root coordinates from edit */
    Transform	 e_rootToEdit;	/* Transform to edit coordinates from root */
    CellDef	*e_rootDef;	/* Root def in the edit cell's home window */
    CellDef	*e_editDef;	/* Edit cell def itself */
    CellDef	*e_parentDef;	/* Parent def of the editcell, or NULL if the
				 * edit cell was a root itself.
				 */
    char	 e_useId[4];	/* Use identifier.  This is a place holder
				 * only; the actual structure is allocated to
				 * hold all the bytes in the use id, plus the
				 * null byte.
				 */
} editUE;

#define	editSize(n)	(sizeof (editUE) - 3 + (n))


/*
 * ----------------------------------------------------------------------------
 *
 * LayUndoOldEdit --
 * LayUndoNewEdit --
 *
 *	Record the old and new edit cells when the edit cell changes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Each creates a single undo list entry.
 *
 * ----------------------------------------------------------------------------
 */
void
LayUndoOldEdit(CellUse *editUse, CellDef *editRootDef, Transform *editToRootTrans, Transform *rootToEditTrans)
{
    char *useid = editUse->cu_id;
    editUE *ep;

    /* don't record if under a no_undo cell,
     * since its celldef may be deleted.
     */  
    if(editRootDef->cd_flags & CD_NO_UNDO) return;

    ep = (editUE *) UndoNewEvent(layUndoIDOldEdit,
	    (unsigned) editSize(strlen(useid)));
    if (ep == (editUE *) NULL)
	return;

    ep->e_editToRoot = *editToRootTrans;
    ep->e_rootToEdit = *rootToEditTrans;
    ep->e_rootDef = editRootDef;
    ep->e_editDef = editUse->cu_def;
    ep->e_parentDef = editUse->cu_parent;
    (void) strcpy(ep->e_useId, useid);
}

void LayUndoNewEdit(CellUse *editUse, CellDef *editRootDef, Transform *editToRootTrans, Transform *rootToEditTrans)
{
    char *useid = editUse->cu_id;
    editUE *ep;

    /* don't record if under a no_undo cell,
     * since its celldef may be deleted.
     */  
    if(editRootDef->cd_flags & CD_NO_UNDO) return;

    ep = (editUE *) UndoNewEvent(layUndoIDNewEdit,
	    (unsigned) editSize(strlen(useid)));
    if (ep == (editUE *) NULL)
	return;

    ep->e_editToRoot = *editToRootTrans;
    ep->e_rootToEdit = *rootToEditTrans;
    ep->e_rootDef = editRootDef;
    ep->e_editDef = editUse->cu_def;
    ep->e_parentDef = editUse->cu_parent;
    (void) strcpy(ep->e_useId, useid);
}

/*
 * ----------------------------------------------------------------------------
 *
 * layUndoChangeEdit
 *
 *	Change the edit cell.
 *	The UndoEvent passed as an argument contains a pointer to
 *	the root cell def of the new edit cell and the parent def
 *	of the edit cell.  Both pointers are safe because edit change
 *      events are not recorded for CD_NO_UNDO cells and the undo
 *	list is cleared if any other CellDef is deleted.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Changes the edit cell.
 *	Redisplas the old edit cell and the new one.
 *
 * ----------------------------------------------------------------------------
 */

void
layUndoChangeEdit(register editUE *ep)
{
    Rect area;
    register CellUse *use;
    register CellDef *editDef, *parent;
    static Rect origin = {-1, -1, 1, 1};

    /* Redisplay the old edit cell */
    GeoTransRect(&EditToRootTransform, DBBBoxCellDef(EditCellUse->cu_def), &area);
    DBChangedArea(EditRootDef, &area, &DBAllButSpaceBits, DBCF_DISPLAY);
    GeoTransRect(&EditToRootTransform, &origin, &area);
    DBChangedArea(EditRootDef, &area, &DBAllButSpaceBits, DBCF_DISPLAY);

    /* Set up the transforms for the new edit cell */
    EditToRootTransform = ep->e_editToRoot;
    RootToEditTransform = ep->e_rootToEdit;

    /*
     * Search for the use uniquely identified by the parent cell
     * def 'parent' (which may be NULL) and the use identifier
     * 'ep->e_useId'.
     *
     * It's gotta be there.
     */
    EditRootDef = ep->e_rootDef;
    editDef = ep->e_editDef;
    parent = ep->e_parentDef;
    for (use = editDef->cd_uses; use != NULL; use = use->cu_nextuse)
	if (use->cu_parent == parent && strcmp(use->cu_id, ep->e_useId) == 0)
	    break;

    ASSERT(use != (CellUse *) NULL, "layUndoChangeEdit");

    MsgInfoF("Edit cell is now %s (%s)\n", editDef->cd_name, use->cu_id);
    EditCellUse = use;
    GeoTransRect(&EditToRootTransform, DBBBoxCellDef(EditCellUse->cu_def), &area);
    DBChangedArea(EditRootDef, &area, &DBAllButSpaceBits, DBCF_DISPLAY);
    GeoTransRect(&EditToRootTransform, &origin, &area);
    DBChangedArea(EditRootDef, &area, &DBAllButSpaceBits, DBCF_DISPLAY);
}

/*
 * ----------------------------------------------------------------------------
 *
 * LayUndoBox --
 *
 * 	Remember a box change for later undo-ing.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An entry is added to the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
LayUndoBox(CellDef *oldDef, Rect *oldArea, CellDef *newDef, Rect *newArea)
                    		/* Celldef containing old box. */
                  		/* Area of old box in oldDef coords. */
                    		/* Celldef containing new box. */
                  		/* Area of new box in newDef coords. */
{
    BoxUndoEvent *bue;

    bue = (BoxUndoEvent *) UndoNewEvent(layUndoIDBox, sizeof(BoxUndoEvent));
    if (bue == NULL) return;

    bue->bue_oldDef = oldDef;
    bue->bue_oldArea = *oldArea;
    bue->bue_newDef = newDef;
    bue->bue_newArea = *newArea;
}

/*
 * ----------------------------------------------------------------------------
 *
 * layUndoBoxForw --
 * layUndoBoxBack --
 *
 * 	This routines are called to undo a change to the box.  They
 *	are invoked by the undo package.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The box's location is modified.
 *
 * ----------------------------------------------------------------------------
 */

void
layUndoBoxForw(BoxUndoEvent *bue)
                      			/* Event to be redone. */
{
    LaySetBox(bue->bue_newDef, &bue->bue_newArea);
}

void
layUndoBoxBack(BoxUndoEvent *bue)
                      			/* Event to be undone. */
{
    LaySetBox(bue->bue_oldDef, &bue->bue_oldArea);
}

/*
 * ----------------------------------------------------------------------------
 *
 * LayUndoLoad --
 *
 * 	Remember a window rootcell change for later undo-ing.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An entry is added to the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
LayUndoLoad(Layout *w, CellDef *oldDef, CellDef *newDef)
{
    LoadUndoEvent *lue;

    lue = (LoadUndoEvent *) UndoNewEvent(layUndoIDLoad, sizeof(LoadUndoEvent));
    if (lue == NULL) return;

    lue->lue_layout = w;
    /* don't save pointers to CD_NO_UNDO defs since they may be deleted */
    lue->lue_oldDef = (oldDef->cd_flags & CD_NO_UNDO) ? NULL : oldDef;
    lue->lue_newDef = (oldDef->cd_flags & CD_NO_UNDO) ? NULL : newDef;
}

/*
 * ----------------------------------------------------------------------------
 *
 * layUndoBoxForw --
 * layUndoBoxBack --
 *
 * 	This routines are called to undo a changes to the root cell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The box's location is modified.
 *
 * ----------------------------------------------------------------------------
 */
void
layUndoLoadForw(LoadUndoEvent *lue)
{
  /* NULL for CD_NO_UNDO cells, since they may be deleted */
  if(lue->lue_newDef)
  {
    LayloadWindow(lue->lue_layout,lue->lue_newDef->cd_name);
  }
}

void
layUndoLoadBack(LoadUndoEvent *lue)
{
  /* NULL for CD_NO_UNDO cells, since they may be deleted */
  if(lue->lue_oldDef)
  {
    LayloadWindow(lue->lue_layout,lue->lue_oldDef->cd_name);
  }
}



/*
 * ----------------------------------------------------------------------------
 *
 * layUndoInit --
 *
 *	Initialize handling of undo for the layout module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Calls the undo package to add several clients.
 *
 * ----------------------------------------------------------------------------
 */

void layUndoInit(void)
{
    void (*nullProc)() = NULL;

    layUndoIDOldEdit = UndoAddClient(nullProc, nullProc,
	    nullProc,             /* redo */
	    layUndoChangeEdit,    /* undo */
            "change edit cell");

    layUndoIDNewEdit = UndoAddClient(nullProc, nullProc,
           layUndoChangeEdit,   /* redo */
           nullProc,            /* undo */ 
           "change edit cell");
    
    layUndoIDBox = UndoAddClient(nullProc, nullProc,
            layUndoBoxForw,	/* redo */
	    layUndoBoxBack,     /* undo */
    	    "box change");
    
    layUndoIDLoad = UndoAddClient(nullProc, nullProc,
            layUndoLoadForw,	 /* redo */
	    layUndoLoadBack,     /* undo */
    	    "window rootcell change");
}
