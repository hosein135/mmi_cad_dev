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
 * undo.h --
 *
 * Exported definitions for the undo/redo module.
 * The undo/redo module is designed to be as client-independent
 * as possible.  Communication to and from clients is by means
 * of objects, allocated by the undo package, known as UndoEvents.
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
 *
 * rcsid "$Header: undo.h,v 6.0 90/08/28 18:58:35 mayo Exp $"
 */

#ifndef _UNDO
#define	_UNDO

#ifndef	_MAGIC
#include "magic.h"
#endif	_MAGIC

#ifndef	_TCL
#include <tcl.h>
#endif	_TCL

#ifndef _DATABASE
#include "database.h"
#endif

#ifndef _SELECT
#include "select.h"
#endif

/* -------------------- Exported definitions -------------------------- */

typedef int	 UndoType;	/* Type of undo event */
typedef char	 UndoEvent;	/* Externally visible undo event */

/* -------------------- Interface procedures -------------------------- */


/* register tcl commands for this module */
extern void UndoTclInit(Tcl_Interp *interp);

/*	UndoAddClient	-- used by a client to inform the undo package of
 *			   its existence and to obtain an UndoType used in
 *			   all future interactions with undo.
 */
extern UndoType UndoAddClient(
	      void (*init)(void), 
	      void (*done)(void), 
	      void (*redoEvent)(/* pointer to client event data */), 
	      void (*undoEvent)(/* poitner to client event data */), 
	      char *name);

/*	UndoNewEvent	-- returns a new UndoEvent which the client may load
 *			   with its own data.  The event is appended to the
 *			   undo log.  The client should not retain this
 *			   new event past the next call to the undo package.  
 *			   If undoing is disabled, returns NULL.
 */
extern UndoEvent *UndoNewEvent(UndoType clientType, unsigned int size);


/*	UndoDelim	-- used by a client to inform the undo package that
 *			   all events since the last call to UndoDelim are
 *			   to be treated as a single unit by UndoForward()
 *			   and UndoBackward().
 */
extern void UndoDelim(void);

/*	UndoBackward	-- play the undo log backward N units (until the prev-
 *			   ious call to UndoDelim()).
 */
extern int UndoBackward(int n);

/*	UndoForward	-- play the undo log forward N units. */
extern int UndoForward(int n);

/*	UndoDisable	-- turn off the undo package until the next UndoEnable. */
extern void UndoDisable(void);

/*	UndoEnable	-- turn the undo package back on. */
extern void UndoEnable(void);

/*	UndoFlush	-- throw away all undo information. */
extern void UndoFlush(void);


/*
 * ----------------------------------------------------------------------------
 *
 * UndoIsEnabled --
 *
 * Test whether undo is enabled for given def.
 *
 * Results:
 *	Returns TRUE if undoing is enabled, FALSE otherwise.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

extern bool UndoDisableCount;
static __inline__ bool UndoIsEnabled(CellDef *def)
{
  ASSERT(def!=NULL,"UndoIsEnabled");
  return (UndoDisableCount == 0) && (def != SelectDef || SelUndo) && !(def->cd_flags&CD_NO_UNDO);
}

#endif _UNDO

