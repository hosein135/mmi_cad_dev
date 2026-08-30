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
 * undo.c --
 *
 * Undo/redo module.
 *
 * The undo package records a seris of invertible editing events
 * in a log maintained in main memory.
 *
 * The current state may be rewound back toward the time the editing
 * session began, and it may be replayed forward as well.
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
static char rcsid[] = "$Header: undo.c,v 6.0 90/08/28 18:58:33 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/types.h>
#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "utils.h"
#include "memory.h"
#include "undo.h"

/* ------------------------------------------------------------------------ */

/*
 * CONFIGURATION INFORMATION
 */

#define	MAXUNDOCLIENTS	50	/* Maximum number of calls to UndoAddClient */

    /*
     * MAXCOMMANDS is the maximum number of delimited event sequences
     * ("commands") retained in main memory.  LOWCOMMANDS is a low-water
     * mark for the number of commands in memory; whenever we free up
     * commands, we do so until there are no more than LOWCOMMANDS in
     * main memory.
     *
     */

#define	MAXCOMMANDS	200
#define	LOWCOMMANDS	100	/* Must be > 0 ! */

/* ------------------------------------------------------------------------ */

/*
 * The following structure describes the basic information
 * required by the undo package for each event it stores.
 * This information is NOT intended to be visible to any of
 * the clients of the undo package and is susceptible to being
 * changed arbitrarily.
 *
 * To enforce the absolute ignorance of undo's clients, when
 * we allocate an internalUndoEvent, we only give the client
 * a pointer to the iue_client part, which is of a size determined
 * by the client when it calls UndoNewEvent().  This pointer is
 * what the client sees as an (UndoEvent *) (really a (char *)).
 */

    typedef struct ue
    {
	UndoType	 iue_type;	/* Event type */
	struct ue	*iue_back;	/* Previous event on list */
	struct ue	*iue_forw;	/* Next event on list */
	double		 iue_client;	/* Client data area.  This is merely a
					 * dummy placeholder; the actual size
					 * of one of these structures is
					 * determined at the time of
					 * UndoNewEvent().
					 */
    } internalUndoEvent;

/* internal undo event types */
#define	UT_DELIM	(-1)

/*
 * The following macro is used to compute the number of bytes we must
 * allocate in order to give the user an UndoEvent capable of holding
 * n bytes.
 */

#define	undoSize(n)	(sizeof (struct ue) + (n) \
			    - sizeof (((struct ue *) 0)->iue_client))

/*
 * Mapping between internal and external undo event pointers.
 * When the undo package hands an (UndoEvent *) to a client, it is
 * really a pointer to the iue_client part of the structure
 * above.
 */

#define	CLIENTOFFSET	((int) &((internalUndoEvent) 0)->iue_client)
#define	undoExport(p)	((UndoEvent *) (&(p)->iue_client))
#define	undoImport(p)	((internalUndoEvent) (((char *) (p)) - CLIENTOFFSET))

/*
 * The following table is used to record the information about clients
 * of the undo package.  The number of such clients is stored in
 * undoNumClients.
 */

    typedef struct
    {
	char		  *uc_name;	/* Name (for error messages) */
	void		 (*uc_init)();	/* Called before playing log */
	void		 (*uc_done)();	/* Called after playing log */
	void		 (*uc_forw)();	/* Play event forward */
	void		 (*uc_back)();	/* Play event backward */
    } undoClient;

undoClient undoClientTable[MAXUNDOCLIENTS];
int undoNumClients = 0;

/* current undo disable nesting level (0 = not disabled) */
global int UndoDisableCount = 0;

/*
 * Log of events kept in main memory.
 *
 *	undoLogHead	Pointer to first entry stored in main memory.
 *			    - NULL, indicating no events are in memory
 *			    - a pointer to the first event of a command
 *	undoLogTail	Pointer to last entry stored in main memory.
 *			    - Undefined (if undoLogHead == NULL)
 *			    - a pointer to a UT_DELIM event if
 *			      undoNumRecentEvents == 0
 *			    - a pointer to a non-UT_DELIM event if
 *			      undoNumRecentEvents != 0
 *	undoLogCur	Pointer to "current" event, ie, one after which
 *			next event will be added.
 *			    - NULL if at beginning of event list
 *			    - a pointer to a UT_DELIM event if
 *			      undoNumRecentEvents == 0
 *			    - a pointer to a non-UT_DELIM event if
 *			      undoNumRecentEvents != 0
 *
 *	undoNumRecentEvents
 *			Number of events written since last call to
 *			UndoDelim().
 *	undoNumCommands
 *			Number of complete commands in main memory.
 */

internalUndoEvent *undoLogCur = NULL;
internalUndoEvent *undoLogHead = NULL;
internalUndoEvent *undoLogTail = NULL;
int undoNumRecentEvents = 0;
int undoNumCommands = 0;

/* forward declarations */
extern internalUndoEvent *undoGetForw(internalUndoEvent *iup);
extern internalUndoEvent *undoGetBack(internalUndoEvent *iup);
extern void undoFreeHead(void);
extern void undoMemTruncate(void);

void undoPrintEvent(internalUndoEvent *iup)
{
    int size;
    unsigned *fakeip;

    fakeip = (unsigned *) iup;
    size = (fakeip[-1] & (~1)) - (unsigned) fakeip;
    (void) printf("0x%x:\t%d\tf=0x%x\tb=0x%x\tsize=%u\n", iup, iup->iue_type,
		iup->iue_forw, iup->iue_back, size);
}

/* print procedures for debugging */
void undoPrintForw(internalUndoEvent *iup)
{
    (void) printf("head=0x%x\ttail=0x%x\tcur=0x%x\n",
		undoLogHead, undoLogTail, undoLogCur);
    if (iup == (internalUndoEvent *) NULL)
	iup = undoLogHead;
    while (iup != (internalUndoEvent *) NULL)
    {
	undoPrintEvent(iup);
	iup = iup->iue_forw;
    }
}

void undoPrintBack(internalUndoEvent *iup)
{
    (void) printf("head=0x%x\ttail=0x%x\tcur=0x%x\n",
		undoLogHead, undoLogTail, undoLogCur);
    if (iup == (internalUndoEvent *) NULL)
	iup = undoLogTail;
    while (iup != (internalUndoEvent *) NULL)
    {
	undoPrintEvent(iup);
	iup = iup->iue_back;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * UndoAddClient --
 *
 * Define an undo "type".
 *
 * Results:
 *	Returns an UndoType which must be passed in future calls
 *	to UndoNewEvent().  If -1 is returned, this means that there
 *	are too many clients of the undo package.
 *
 * Side effects:
 *	Initializes local state in the undo package.
 *
 * ----------------------------------------------------------------------------
 */

UndoType
UndoAddClient(void (*init)(void),
	      /* called before playing undo log forwards or backwards */

	      void (*done)(void), 
	      /* called after playing undo log forwards or backwards */ 

	      void (*forwEvent)(/* pointer to client event data */), 
	      /* called to redo event */ 

	      void (*backEvent)(/* poitner to client event data */), 
	      /* called to undo event */

	      char *name
	      /* name of event type, for error messages */

	      )
{
    if (undoNumClients >= MAXUNDOCLIENTS)
	return ((UndoType) -1);

    undoClientTable[undoNumClients].uc_name = StrDup((char **) NULL, name);
    undoClientTable[undoNumClients].uc_forw = forwEvent;
    undoClientTable[undoNumClients].uc_back = backEvent;
    undoClientTable[undoNumClients].uc_init = init;
    undoClientTable[undoNumClients].uc_done = done;

    return (undoNumClients++);
}


/*
 * ----------------------------------------------------------------------------
 *
 * UndoDisable --
 *
 * Turn the undo package off.
 * Future calls to UndoNewEvent() will return NULL, and future calls
 * to UndoIsEnabled() will return FALSE, until the next call to
 * UndoEnable();
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Disables undoing until the next call to UndoEnable().
 *
 * ----------------------------------------------------------------------------
 */

void
UndoDisable(void)
{
    UndoDisableCount++;
}

/*
 * ----------------------------------------------------------------------------
 *
 * UndoEnable --
 *
 * Turn the undo package on.
 * Re-enables the undo package after a call to UndoDisable().
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Re-enables undoing.
 *
 * ----------------------------------------------------------------------------
 */

void
UndoEnable(void)
{
    if (UndoDisableCount > 0)
	UndoDisableCount--;
}

/*
 * ----------------------------------------------------------------------------
 *
 * UndoFlush --
 *
 * Flush the current undo list.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Deletes everything from the undo list.
 *
 * ----------------------------------------------------------------------------
 */

void
UndoFlush(void)
{
    if (undoLogHead == (internalUndoEvent *) NULL)
	return;

    while (undoLogTail != undoLogHead)
    {
	FREE((char *) undoLogTail);
	undoLogTail = undoLogTail->iue_back;
	ASSERT(undoLogTail != (internalUndoEvent *) NULL, "UndoFlush");
    }
    FREE((char *) undoLogHead);

    undoLogHead = undoLogTail = undoLogCur = (internalUndoEvent *) NULL;
    undoNumCommands = 0;
    undoNumRecentEvents = 0;

    /* notify database module of flush */
    DBUndoFlush();
}


/*
 * ----------------------------------------------------------------------------
 *
 * UndoNewEvent --
 *
 * Return a pointer to a new UndoEvent of the specified type and capable
 * of holding size bytes of client data.
 *
 * Results:
 *	A pointer to a new UndoEvent.
 *
 * WARNING:
 *	The pointer to the new UndoEvent must not be retained past the
 *	next call to any of the routines in the undo package, as the
 *	event is liable to be reallocated. ???
 *
 * Side effects:
 *	Appends new event after the current
 *      event, and makes it current (events forward of the current event
 *      are flushed, i.e. no redo info after a new event is added.)
 *
 * ----------------------------------------------------------------------------
 */

UndoEvent *
UndoNewEvent(UndoType clientType, unsigned int size)
                        	/* Type of event to allocate */
                  		/* Number of bytes of client data to allocate */
{
    internalUndoEvent *iup;
    int usize;

    if (UndoDisableCount > 0)
	return ((UndoEvent *) NULL);

    /* DEBUG
    if(strcmp(undoClientTable[clientType].uc_name,"box change")!=0)
    {
      fprintf(stderr,"DEBUG UndoNewEvent, type=%s\n",
	      undoClientTable[clientType].uc_name);
    }
    */

    usize = undoSize(size);
    MALLOC(internalUndoEvent *, iup, usize);
    ASSERT(clientType >= 0 && clientType < undoNumClients, "UndoNewEvent");
    iup->iue_type = clientType;

    /*
     * Append the new event after the event pointed to by
     * undoLogCur.
     */
    iup->iue_forw = (internalUndoEvent *) NULL;
    iup->iue_back = undoLogCur;
    if (undoLogCur == (internalUndoEvent *) NULL)
    {
        if (undoLogHead != (internalUndoEvent *) NULL) undoMemTruncate();
	undoLogHead = undoLogCur = undoLogTail = iup;
    }
    else
    {
        if (undoLogCur->iue_forw != (internalUndoEvent *) NULL) undoMemTruncate();
        undoLogCur->iue_forw = iup;
        undoLogCur = undoLogTail = iup;
    }
	undoNumRecentEvents++;

    return (undoExport(iup));
}

/*
 * ----------------------------------------------------------------------------
 *
 * UndoDelim --
 *
 * Delimit a sequence of operations to the undo package with an event
 * delimiter.  
 *
 * (Operations between delims are treated as single command for
 *  purposes of undo/redo.)
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Appends a marker to the undo list signifying a "command" boundary.
 *
 * ----------------------------------------------------------------------------
 */

void
UndoDelim(void)
{
    internalUndoEvent *iup;
    int usize;

    if (UndoDisableCount > 0 || undoNumRecentEvents == 0)
	return;

    undoNumRecentEvents = 0;
    undoNumCommands++;
    usize = undoSize(0);
    MALLOC(internalUndoEvent *, iup, usize);
    iup->iue_type = UT_DELIM;
    iup->iue_back = undoLogTail;
    iup->iue_forw = (internalUndoEvent *) NULL;
    if (undoLogTail != (internalUndoEvent *) NULL)
	undoLogTail->iue_forw = iup;
    undoLogCur = undoLogTail = iup;
    if (undoNumCommands >= MAXCOMMANDS)
	undoFreeHead();
}

/*
 * ----------------------------------------------------------------------------
 *
 * UndoBackward --
 *
 * Play the undo log backward n events.
 *
 * Argument of 0 means delete recent events (i.e. up to last delim).
 *
 * Results:
 *	The number of events actually played backward.  Normally, this
 *	will be equal to n unless we encounter the beginning of the log.
 *
 * Side effects:
 *	Applies the client backEvent() procedures to each event encountered
 *	in playing the log backward.
 *
 * ----------------------------------------------------------------------------
 */

int
UndoBackward(int n)
          		/* Number of events to unplay */
{
    internalUndoEvent *iup;
    int client, count;

    /* n=0 means delete recent events. */
    if(n==0)
    {
      if(undoNumRecentEvents == 0) return 0;
      n = 1;
    }

    /* Call the initialization routines of all clients */
    for (client = 0; client < undoNumClients; client++)
	if (undoClientTable[client].uc_init)
	    (*undoClientTable[client].uc_init)();

    iup = undoLogCur;
    undoNumRecentEvents = 0;
    UndoDisableCount++;
    for (count = 0; (count < n) && (iup != NULL); count++)
    {
	do
	{
	    if (iup->iue_type != UT_DELIM)
		if (undoClientTable[iup->iue_type].uc_back != NULL)
		{
		  (*undoClientTable[iup->iue_type].uc_back)(undoExport(iup));
		}
	    iup = undoGetBack(iup);
	}
	while (iup != (internalUndoEvent *) NULL && iup->iue_type != UT_DELIM);
    }
    UndoDisableCount--;

    undoLogCur = iup;

    /* Call the termination routines of all clients */
    for (client = 0; client < undoNumClients; client++)
	if (undoClientTable[client].uc_done)
	    (*undoClientTable[client].uc_done)();

    return (count);
}

/*
 * ----------------------------------------------------------------------------
 *
 * UndoForward --
 *
 * Play the undo log forward n events.
 *
 * Results:
 *	The number of events actually played forward.  Normally, this
 *	will be equal to n unless we encounter the end of the log.
 *
 * Side effects:
 *	Applies the client forwEvent() procedures to each event encountered
 *	in playing the log forward.
 *
 * ----------------------------------------------------------------------------
 */

int
UndoForward(int n)
          		/* Number of events to replay */
{
    internalUndoEvent *iup;
    int count, client;

    /* Call the initialization routines of all clients */
    for (client = 0; client < undoNumClients; client++)
	if (undoClientTable[client].uc_init)
	    (*undoClientTable[client].uc_init)();

    count = 0;
    iup = undoGetForw(undoLogCur);
    if (iup == NULL) goto done;

    undoNumRecentEvents = 0;
    UndoDisableCount++;
    for ( ; count < n; count++)
    {
	do
	{
	    if (iup->iue_type != UT_DELIM)
		if (undoClientTable[iup->iue_type].uc_forw != NULL)
		    (*undoClientTable[iup->iue_type].uc_forw)(undoExport(iup));
	    iup = undoGetForw(iup);
	}
	while (iup != (internalUndoEvent *) NULL && iup->iue_type != UT_DELIM);
	if (iup == (internalUndoEvent *) NULL)
	{
	    iup = undoLogTail;
	    break;
	}
    }
    UndoDisableCount--;

    undoLogCur = iup;

done:
    /* Call the termination routines of all clients */
    for (client = 0; client < undoNumClients; client++)
	if (undoClientTable[client].uc_done)
	    (*undoClientTable[client].uc_done)();
    return (count);
}

/*
 * ============================================================================
 *
 *	All of the remaining procedures in the file are invisible
 *	to the clients of the undo package and should not be used.
 *
 * ============================================================================
 */


/*
 * ----------------------------------------------------------------------------
 *
 * undoGetForw --
 *
 * Return a pointer to the next undo event in the list.
 *
 * Results:
 *	A pointer to an undo event.
 *
 * Side effects:
 *	None.
 *
 * Directly modifies:
 *	undoLogHead, undoLogTail
 *	undoNumCommands
 *	undoNumRecentEvents = 0
 *
 * Indirectly modifies:
 *	Nothing.
 *
 * ----------------------------------------------------------------------------
 */

internalUndoEvent *
undoGetForw(internalUndoEvent *iup)
{
    if (iup != (internalUndoEvent *) NULL)
    {
	/*
	 * Return the next event in memory if there is one.
	 */
	if (iup->iue_forw != (internalUndoEvent *) NULL)
	    return (iup->iue_forw);
    }
    else
    {
	/*
	 * A NULL initial iup means to start at the very beginning of
	 * the main-memory undo list.  If there is anything there, return
	 * it; otherwise return NULL.
	 */
	if (undoLogHead != (internalUndoEvent *) NULL)
	    return (undoLogHead);
    }

    return ((internalUndoEvent *) NULL);
}

/*
 * ----------------------------------------------------------------------------
 *
 * undoGetBack --
 *
 * Return a pointer to the previous undo event in the list.
 *
 * Results:
 *	A pointer to an undo event.
 *
 * Side effects:
 *	None.
 *
 * Directly modifies:
 *
 * Indirectly modifies:
 *
 * ----------------------------------------------------------------------------
 */

internalUndoEvent *
undoGetBack(internalUndoEvent *iup)
{
    if (iup == (internalUndoEvent *) NULL) return (iup);
    if (iup->iue_back != (internalUndoEvent *) NULL) return (iup->iue_back);
    return ((internalUndoEvent *) NULL);
}

/*
 * ----------------------------------------------------------------------------
 *
 * undoFreeHead --
 *
 * Free up space by throwing away events from the front of the in-memory
 * event list until the total number of in-memory commands falls below
 * LOWCOMMANDS
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Deallocates events from the front of the in-memory event list.
 *	Updates undoLogHead, undoNumCommands.
 *	Guaranteed to leave undoLogHead pointing to the first event
 *	in a command (not of type UT_DELIM).
 *
 * WARNING:
 *	It is important that undoLogCur point beyond the region
 *	to be freed.  Also, it is important that the in-core list
 *	be terminated by an UT_DELIM event.
 *
 * ----------------------------------------------------------------------------
 */

void
undoFreeHead(void)
{
    if (undoNumCommands <= LOWCOMMANDS)
	return;

    while (undoNumCommands > LOWCOMMANDS)
    {
	do
	{
	    ASSERT(undoLogHead != undoLogCur, "undoFreeHead");
	    FREE((char *) undoLogHead);
	    undoLogHead = undoLogHead->iue_forw;
	    ASSERT(undoLogHead != (internalUndoEvent *) NULL, "undoFreeHead");
	}
	while (undoLogHead->iue_type != UT_DELIM);
	undoNumCommands--;
    }
    FREE((char *) undoLogHead);
    undoLogHead = undoLogHead->iue_forw;
    undoLogHead->iue_back = (internalUndoEvent *) NULL;
}

/*
 * ----------------------------------------------------------------------------
 *
 * undoMemTruncate --
 *
 * Delete events forward of the current event (they would be "overwritten"
 * by the next event).
 *
 * NOTE: this routine expects to be called on a command boundary.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Truncates the event list so there are no events to the 
 *      future of undoLogCur.
 *
 * ----------------------------------------------------------------------------
 */

void
undoMemTruncate(void)
{
    internalUndoEvent *up;

    if (undoLogHead == (internalUndoEvent *) NULL) return;

    if (undoLogCur == (internalUndoEvent *) NULL)
    {
	/*
	 * Delete ALL events from memory
	 */
	up = undoLogHead;
	while (up != (internalUndoEvent *) NULL)
	{
	    FREE((char *) up);
	    up = up->iue_forw;
	}
	undoLogTail = undoLogHead = (internalUndoEvent *) NULL;
	undoNumCommands = 0;
    }
    else
    {
	ASSERT(undoLogCur->iue_type == UT_DELIM, "undoMemTruncate");
	/*
	 * Delete events to future of current event 
	 */
	up = undoLogCur->iue_forw;
	while (up != (internalUndoEvent *) NULL)
	{
	    if (up->iue_type == UT_DELIM)
		undoNumCommands--;
	    FREE((char *) up);
	    up = up->iue_forw;
	}
	undoLogCur->iue_forw = (internalUndoEvent *) NULL;
	undoLogTail = undoLogCur;
    }

}


/*
 *--------------------------------------------------------------
 *
 * undoTclCmdDelim --
 *
 *      Implements undo_delim command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define undo_delim_DESC	"add undo delimeter (marks \"command\" boundaries)"

#define undo_delim_DOC "
The undo module treats operations between delimeters as single operations
to be undone/redone as a unit.
"

static int
undoTclCmdDelim(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n",argv[0]);
         CMD_RETURN(interp);
    }

    UndoDelim();
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * undoTclCmdDisable --
 *
 *      Implements undo_disable command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define undo_disable_DESC	"turn off undo"

#define undo_disable_DOC "
Reenable undo with undo_enable.
Undo disables can be nested.
NOTE:  Consider an undo_flush after an undo_disable.
"

static int
undoTclCmdDisable(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n",argv[0]);
         CMD_RETURN(interp);
    }
    UndoDisable();
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * undoTclCmdEnable --
 *
 *      Implements undo_enable command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define undo_enable_DESC	"turn undo logging back on"

#define undo_enable_DOC "
Reenables undo after  undo_disable.
Undo disables can be nested.
"

static int
undoTclCmdEnable(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    int i;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n",argv[0]);
         CMD_RETURN(interp);
    }

    UndoEnable();
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * undoTclCmdFlushRedo --
 *
 *      Implements undo_flush_redo command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define undo_flush_redo_DESC	"remove events to future of current from undo log"

#define undo_flush_redo_DOC "
Must be called on undo command boundary (normally right after :undo).
"

static int
undoTclCmdFlushRedo(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n",argv[0]);
         CMD_RETURN(interp);
    }

    if (undoLogHead == (internalUndoEvent *) NULL) 
    {
      CMD_RETURN(interp);
    }

    if(undoLogCur && undoLogCur->iue_type != UT_DELIM) 
    {
      MsgErrorF("%s must be on command boundary (e.g. right after :undo)!\n",
		argv[0]);
      CMD_RETURN(interp);
    }
  
    undoMemTruncate();

    CMD_RETURN(interp);
}

/*
 *--------------------------------------------------------------
 *
 * undoTclCmdFlush --
 *
 *      Implements undo_flush command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */
#define undo_flush_DESC	"delete everything from undo list"

static int
undoTclCmdFlush(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
{
    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n",argv[0]);
         CMD_RETURN(interp);
    }

    UndoFlush();
    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * undoTclCmdToDelim --
 *
 *      Implements undo_to_delim command.
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define undo_to_delim_DESC	"undo up to (but not past) last undo delimeter"

#define undo_to_delim_DOC "
Intended for aborting partial commands.

NOTE: Does nothing when invoked directly by user, since an undo delimeter
is added after each user command.  (Use :undo instead).
"

static int
undoTclCmdToDelim(ClientData clientData, 
		  Tcl_Interp *interp, 
		  int argc, 
		  char **argv)
{
    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
         MsgErrorF("usage:  %s\n",argv[0]);
         CMD_RETURN(interp);
    }

    UndoBackward(0);
    CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * UndoTclInit --
 *
 * Register tcl commands in this module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
UndoTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "undo_delim", undoTclCmdDelim,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       undo_delim_DESC,
	       undo_delim_DOC);

   MnDocCreateCommand(interp, "undo_disable", undoTclCmdDisable,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       undo_disable_DESC,
	       undo_disable_DOC);

   MnDocCreateCommand(interp, "undo_enable", undoTclCmdEnable,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       undo_enable_DESC,
	       undo_enable_DOC);

   MnDocCreateCommand(interp, "undo_flush", undoTclCmdFlush,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       undo_flush_DESC,
	       NULL);

   MnDocCreateCommand(interp, "undo_flush_redo", undoTclCmdFlushRedo,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       undo_flush_redo_DESC,
	       undo_flush_redo_DOC);

   MnDocCreateCommand(interp, "undo_to_delim", undoTclCmdToDelim,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       undo_to_delim_DESC,
	       undo_to_delim_DOC);
}

