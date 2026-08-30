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
 * maxAbort.c --
 *
 * Code to deal with fatal errors.
 * Generally try to backup modified cells, then print error message
 * and abort.
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
static char rcsid[]="$Header: niceabort.c,v 6.1 90/09/13 12:08:54 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include "magic.h"
#include "message.h"
#include "utils.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"


/*
 * ----------------------------------------------------------------------------
 *
 * MaxAbort --
 *
 * Handle fatal errors.
 *
 * Args give error message.  Like printf, first arg is format, subsequent args
 * to fill in "%" escapes in format.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Backup modified cells, send error message to stderr, and abort.
 *      (abort normally causes coredump.)
 * ----------------------------------------------------------------------------
 */
void
MaxAbort(char *fmt, ...)
{
    va_list args;
    char msgbuf[1000];
    static int timesCalled = 0;

    va_start(args,fmt);
    timesCalled++;

    /* avoid looping */    
    if (timesCalled >= 4) _exit(EXIT_FAILURE);
    if (timesCalled >= 3) exit(EXIT_FAILURE);
    if (timesCalled >= 2) abort();

    fprintf(stderr,
	    "\n\n"
            "MAX %s %s (compiled %s) HAS ENCOUNTERED A FATAL INTERNAL ERROR:\n",
	    MaxVersion,
	    MaxVersionTag,
	    MaxCompileTime);

    /* assemble caller supplied message in message buffer */
    vsprintf(msgbuf, fmt, args);

    /* send message to standard error */
    fprintf(stderr,"%s\n",msgbuf);

    /* inform user, and enlist his support! */
    fprintf(stderr,
"
Max will attempt to backup modified cells 
(as <cellName>.max_panic_save) and then dump core.

PLEASE TAKE A MOMENT NOW to email the following information to 
support@micromagic.com:

 1.  The exact text of any error messages
     (cut and paste the messages if possible).

 2.  As precisely as possible describe what you were doing prior
     to the crash,  and whether or not its repeatable.  Also
     let us know whether a core file was generated (if so, please
     save it for us!)

Timely bug reports are very helpful to us, since they
greatly improve the odds of recreating the exact
circumstances that demonstrate the problem.

Thank you for your help!\n\n");


    /* make sure the user gets the message */
    fflush(stderr);

    /* Record crash in history file */
    if(MnMMILocalMax[0] != '\0')
    {
        char cmd[1000];
	char fname[1000];
	FILE *f;

        sprintf(cmd, 
		"echo Max crash:  `whoami` `date` >> %s/CRASH_LOG\n", 
		MnMMILocalMax); 
        system(cmd); 

	 sprintf(fname,"%s/CRASH_LOG", MnMMILocalMax);
         if(f=fopen(fname,"a"))
	 {
             fprintf(f,"Max crash reason: %s\n",msgbuf);
	     fclose(f);
	 }
    }

    /* Try to backup modified cells */
    DBPanicSave();

    /* coredump and exit */
    abort();

    va_end(args);
}    
