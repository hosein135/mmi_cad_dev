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
 * signals.c --
 *
 * Handles signals, such as stop, start, interrupt.
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

static char rcsid[]="$Header: signals.c,v 6.0 90/08/28 18:57:09 mayo Exp $";

#include <stdlib.h>
#include <signal.h>
#include "magic.h"
#include "database.h"
#include "signals.h"

/* POSIX and Standard C signal handlers return void.  However some systems
 * have signal handlers returning int.  
 * If you have a machine that requires ints put it in the list of machines in 
 * magic.h.
 */
#ifdef	SIG_RETURNS_INT
#	define sigRetVal int
#else
#	define sigRetVal void
#endif

/*--------------- Global data structures -----------------*/
/* becomes true when we get an interrupt */
global volatile bool SigInterruptPending = FALSE;

/*--------------- Local data structures -----------------*/ 
volatile static bool sigInterruptRecieved = FALSE;
static int sigNumDisables = 0;

/*--------------- Forward declarations  -----------------*/ 
static sigRetVal sigHandleINT(int sig);
static sigRetVal sigHandleTERM(int sig);
static sigRetVal sigHandleCrash(int sig);


/*
 * ----------------------------------------------------------------------------
 * SigInit:
 *
 *	Set up signal handling for all signals.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Signal handling is set up.
 * ----------------------------------------------------------------------------
 */

void
SigInit(void)
{
    /* catch signals */
    signal(SIGINT, sigHandleINT);  
    signal(SIGTERM, sigHandleTERM);

/*********** Seems best to not catch crashes, as stack prior to interrupt
 *********** is lost to gdb, when we intercept SIGFPE etc.
 *********** NOTE: ASSERT() failures still "caught" since ASSERT calls
 *********** MaxAbort() instead of abort().

    signal( SIGABRT, sigHandleCrash);
    signal( SIGFPE, sigHandleCrash);
    signal( SIGILL, sigHandleCrash);
    signal( SIGSEGV, sigHandleCrash);
#ifdef SIGBUS
    signal( SIGBUS, sigHandleCrash);
#endif
#ifdef SIGIOT
    signal( SIGIOT, sigHandleCrash);
#endif
#ifdef SIGEMT
    signal( SIGEMT, sigHandleCrash);
#endif
#ifdef SIGSYS
    signal( SIGSYS, sigHandleCrash);
#endif
*************/

}


/*---------------------------------------------------------
 * sigEnableInterrupts:
 *	This procedure reenables our handling of interrupts.
 *
 * Results:	None.
 *
 * Side Effects:
 *	None.
 *
 * BUG: signals appearing in small window during execution
 *      of this routine will may be dropped   Can not be fixed
 *      without atomic operations, and/or suppression of compiler
 *      optimizations.
 *---------------------------------------------------------
 */

void
SigEnableInterrupts(void)
{
    sigNumDisables--;
    if (sigNumDisables == 0)
    {
	SigInterruptPending = sigInterruptRecieved;
	sigInterruptRecieved = FALSE;
    }
}


/*---------------------------------------------------------
 * sigDisableInterrupts:
 *	This procedure disables our handling of interrupts.
 *
 * Results:	None.
 *
 * Side Effects:
 *	None.
 *
 * BUG: signals appearing in small window during execution
 *      of this routine will may be dropped   Can not be fixed
 *      without atomic operations, and/or suppression of compiler
 *      optimizations.
 *---------------------------------------------------------
 */

void
SigDisableInterrupts(void)
{
    if (sigNumDisables++ == 0)
    {
	sigInterruptRecieved = SigInterruptPending;
	SigInterruptPending = FALSE;
    }
}


/*---------------------------------------------------------
 * sigHandleINT:
 *	This procedure handles SIGINT interupt signals
 *      (^C on controlling terminal)
 *
 * Results:	None.
 *
 * Side Effects:
 *    A global flag is set
 *---------------------------------------------------------
 */
static sigRetVal
sigHandleINT(int sig)
{
    if (sigNumDisables != 0)
	sigInterruptRecieved = TRUE;
    else
	SigInterruptPending = TRUE;

    /* ANSI C signal handlers have to be reregisted after each triggering! */
    signal(SIGINT, sigHandleINT);
}


/*
 * ----------------------------------------------------------------------------
 * sigHandleTERM:
 *
 *	Catch the terminate (SIGTERM) signal.
 *	Attempt to backup all modified cells to disk 
 *      (as <cellname>.save.mag).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes cells out to disk (by calling DBPanicSave()).
 *	Exits.
 * ----------------------------------------------------------------------------
 */

static sigRetVal
sigHandleTERM(int sig)
{
    /* backup of modified cells registered with atexit() 
     * so just call exit()
     */
    exit(EXIT_FAILURE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * sigHandleCrash --
 *
 *	Something went wrong, attempt to backup modified cells, and 
 *      write error message before dieing.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	We die.
 *
 * ----------------------------------------------------------------------------
 */

static sigRetVal
sigHandleCrash(int sig)
{
    /* Avoid looping - this isn't necessary in Standard C, but ... */
    signal(sig, SIG_DFL);
    signal(SIGABRT, SIG_DFL);

    /* Call MaxAbort() with appropriate message */
    if 		(sig == SIGABRT) MaxAbort("Abnormal termination (ABRT)");
    else if     (sig == SIGFPE)  MaxAbort("Floating point exception (FPE)");
    else if     (sig == SIGILL)  MaxAbort("Illegal function image (ILL)");
    else if     (sig == SIGSEGV) MaxAbort("Segmentation violation (SEGV)");
#ifdef SIGBUS
    else if     (sig == SIGBUS)  MaxAbort("Bus error (BUS)");
#endif
#ifdef SIGIOT
    else if     (sig == SIGIOT)  MaxAbort("IO Trap (IOT)");
#endif
#ifdef SIGEMT
    else if     (sig == SIGEMT)  MaxAbort("EMT Trap (EMT)");
#endif
#ifdef SIGSYS
    else if     (sig == SIGSYS)  MaxAbort("Bad system call (SYS)");
#endif
    else                         MaxAbort("Signal #%d",sig);
}

