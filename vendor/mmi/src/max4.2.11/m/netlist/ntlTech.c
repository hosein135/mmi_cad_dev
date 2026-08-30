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
 * ntlTech.c --
 *
 * netlisting
 * Code to read and process the sections of a technology file
 * that are specific to netlisting
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
static char sccsid[] = "@(#)ntlTech.c	4.8 MAGIC (Berkeley) 10/26/85";
#endif  not lint

#include <stdio.h>
#include <math.h>
#include "magic.h"
#include "utils.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "message.h"
#include "main.h"
#include "debug.h"
#include "netlistInt.h"
#include "netlist.h"
#include <string.h>

#include "extractInt.h"

/*
 * ----------------------------------------------------------------------------
 *
 * ntlBorrowExtTechStyle --
 *
 * Initializes the Netlister technology style by copying the needed fields 
 * from the extractor style
 * a Hack to get the netlister working, until things are changed so that 
 * these variables are filled in by Tcl routines
 *
 * Results:
 *	A pointer to a NtlStyle that has elements copied from 
 *	the current ExtStyle, NULL if the Extstyle is NULL
 *
 * Side effects:
 *
 * ----------------------------------------------------------------------------
 */

int
ntlBorrowExtTechStyle()
{
    register TileType t;

    /* make sure the extractor has a style defined */
    if((ExtStyle *)NULL == ExtCurStyle)
	return( FALSE);

    /* fill in global variables -- obsoletes ntl_style structure */
    ntlTech_name = StrDup((char **) NULL, ExtCurStyle->exts_name);
    ntlTech_transMask = ExtCurStyle->exts_transMask;

    for (t = TT_TECHDEPBASE; t < DBNumTypes; t++)
    {
	ntlTech_transName[t] = StrDup((char **) NULL, 
				     ExtCurStyle->exts_transName[t]);
	/* each assignment copies one TTBitMask (struct element copy) */
	ntlTech_nodeConn[t]  = DBConnectTbl[t];
	ntlTech_transConn[t] = ExtCurStyle->exts_transConn[t];
	ntlTech_transSDTypes[t] = ExtCurStyle->exts_transSDTypes[t];
	ntlTech_transSDCount[t] = ExtCurStyle->exts_transSDCount[t];
	ntlTech_transSubstrateTypes[t] = ExtCurStyle->exts_transSubstrateTypes[t];
	ntlTech_transSubstrateName[t] = StrDup((char **) NULL, 
				     ExtCurStyle->exts_transSubstrateName[t]);
    }
    return(TRUE);
}

void
ntlShowMask(register TileTypeBitMask *m, FILE *out)
{
    register TileType t;
    register bool first = TRUE;

    for (t = 0; t < DBNumTypes; t++)
        if (TTMaskHasType(m, t))
        {
            if (!first)
                (void) fprintf(out, ",");
            first = FALSE;
            (void) fprintf(out, "%s", DBTypeShortName(t));
        }
}

void
ntlShowConnect(char *hdr, TileTypeBitMask *connectsTo, FILE *out)
{
    register TileType t;

    (void) fprintf(out, "%s\n", hdr);
    for (t = TT_TECHDEPBASE; t < DBNumTypes; t++)
        if (!TTMaskEqual(&connectsTo[t], &DBZeroTypeBits))
        {
            (void) fprintf(out, "    %-8.8s: ", DBTypeShortName(t));
            ntlShowMask(&connectsTo[t], out);
            (void) fprintf(out, "\n");
        }
}


void
ntlShowTrans(char *name, register TileTypeBitMask *mask, FILE *out)
{
    register TileType t;

    (void) fprintf(out, "%s types: ", name);
    ntlShowMask(mask, out);
    (void) fprintf(out, "\n");

    for (t = 0; t < DBNumTypes; t++)
        if (TTMaskHasType(mask, t))
        {
            (void) fprintf(out, "    %-8.8s  %d terminals: ",
                        DBTypeShortName(t), ntlTech_transSDCount[t]);
            ntlShowMask(&ntlTech_transSDTypes[t], out);
            (void) fprintf(out, "\n");
/*
            (void) fprintf(out, "\n\tcap (gate-sd/gate-ch) = %lf/%lf\n",
                        ntlTech_transSDCap[t],
                        ntlTech_transGateCap[t]);
*/
        }
}

void
ntlShowTech(char *name)
{
    FILE *out;

    if (strcmp(name, "-") == 0)
        out = stdout;
    else
    {
        out = fopen(name, "w");
        if (out == NULL)
        {
            perror(name);
            return;
        }
    }
    if( (char *) NULL == ntlTech_name)
    {
	MsgInfoF("ntlTech name is null, no technology to show\n");
	return;
    }

    MsgInfoF("ntlShowTech into file %s\n", name);

    (void) fprintf(out, "Technology type %s\n\n", ntlTech_name);


    ntlShowTrans("Transistor", &ntlTech_transMask, out);
    ntlShowConnect("\nNode connectivity", ntlTech_nodeConn, out);
    ntlShowConnect("\nTransistor connectivity", ntlTech_transConn, out);

    if (out != stdout)
	(void) fclose(out);
}

