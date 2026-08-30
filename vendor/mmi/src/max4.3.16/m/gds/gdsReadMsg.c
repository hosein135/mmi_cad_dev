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
 * gdsReadMsg.c --
 *
 * Handles error/warning messages during GDS-II reading.
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

/* As in Max message.h, three classes of messages:
 *
 *   Error    - condition so serious reading has to be aborted.
 *   Warning  - problem, but read-in will not be aborted.
 *   Info     - no problem, just print informative message. 
 * 
 *
 * Errors and Warnings result in dialog box requiring "OK" from user.
 * No routine for Info messages in this file (just use MsgInfoF() directly).
 *
 */

#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#include "magic.h"
#include "database.h"
#include "message.h"
#include "gds.h"
#include "gdsInt.h"

/* number of warnings printed for current def */
static int gdsReadMsgWarnings;

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadMsgInit -
 *
 * This procedure is called just prior to the read in of each cell def.
 * Also called (with NULL def arg at start of gds file.
 *
 * ----------------------------------------------------------------------------
 */
void 
gdsReadMsgInit(void)
{
  gdsReadMsgWarnings = 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadMsgError --
 *
 * This procedure is called to print out error messages during
 * GDS-II file reading.
 *
 * ----------------------------------------------------------------------------
 */
void 
gdsReadMsgError(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);


    /* header */
    if(cifReadCellDef)
    {
      MsgErrorF("Error while reading GDS-II for cell %s:\n\t",
	       cifReadCellDef->cd_name); 
    }
    else
    {
      MsgErrorF("Warning, while reading GDS-II:\n\t"); 
    }

    /* message */
    MsgErrorV(fmt, args);

    /* trailing newline */
    MsgErrorF("\n");

    va_end(args);
}


/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadMsgWarn --
 *
 * This procedure is called to generate warnings during
 * GDS-II file reading.
 *
 * Results:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
#define GDS_READ_MAX_WARNINGS 10

void
gdsReadMsgWarn(char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);

    /* limit number of warnings */
    gdsReadMsgWarnings++;
    if(gdsReadMsgWarnings > gdsReadReportMaxWarnings) return;

    /* header */
    if(cifReadCellDef)
    {
      MsgWarnF("Warning, while reading GDS-II for cell %s:\n\t",
	       cifReadCellDef->cd_name); 
    }
    else
    {
      MsgWarnF("Warning, while reading GDS-II:\n\t"); 
    }

    /* message */
    if (gdsReadMsgWarnings == gdsReadReportMaxWarnings)
    {
      MsgWarnF("... (Too many warnings, skipping some.)");
    }
    else
    {
      MsgWarnV(fmt, args);
    }

    /* trailing newline */
    MsgWarnF("\n");

    va_end(args);
}

/*
 * ----------------------------------------------------------------------------
 *
 * gdsReadMsgUnexpectedRecord --
 *
 * Complain about a record where we expected one kind but got another.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Prints an error message.
 *
 * ----------------------------------------------------------------------------
 */
void 
gdsReadMsgUnexpectedRecord(int wanted, 
		             /* Type of record we wanted */
	                   int got)
            	             /* Type of record we got */
{
  char wantedBuf[BUFSIZ];
  char gotBuf[BUFSIZ];

  strcpy(wantedBuf,calmaRecordName(wanted));
  strcpy(gotBuf,calmaRecordName(got));
  
  gdsReadMsgWarn("Expected %s record, but got %s.",
		 wantedBuf,
		 gotBuf);
}





