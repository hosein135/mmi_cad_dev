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
 * DBtech.c --
 *
 * Technology initialization for the database module.
 * This file handles overall initialization, construction
 * of the general-purpose exported TileTypeBitMasks, and
 * the "connect" section.
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
static char rcsid[] = "$Header: DBtech.c,v 6.0 90/08/28 18:10:14 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "utils.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "main.h"
#include "message.h"
#include "malloc.h"

    /* Name of this technology */
char *DBTechName = 0;
char *DBTechVersion = 0;
char *DBTechDescription = 0;

    /* Connectivity */
TileTypeBitMask	 DBConnectTbl[NT];
TileTypeBitMask	 DBNotConnectTbl[NT];
PlaneList *DBConnectPlanes[NT];

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechInit --
 *
 * Clear technology description information for database module.
 * CURRENTLY A NO-OP.  EVENTUALLY WILL CLEAR OUT ALL TECHNOLOGY
 * VARIABLES PRIOR TO REINITIALIZING A NEW TECHNOLOGY.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

void
DBTechInit(void)
{
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechSetTech --
 *
 * Set the name for the technology.
 *
 * Results:
 *	Returns FALSE if there were an improper number of
 *	tokens on the line.
 *
 * Side effects:
 *	Sets DBTechName to the name of the technology.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
bool
DBTechSetTech(char *sectionName, int argc, char **argv)
{
    if (argc != 1)
    {
	MnTechError("Badly formed technology name\n");
	return FALSE;
    }
    (void) StrDup(&DBTechName, argv[0]);

    /* check that DBTechName matches MnTech name (used for loading tech files) */
    if(strcmp(DBTechName,MnTech) != 0)
    {
      MnTechError("technology name ('%s') does not match tech file name\n", 
		  DBTechName);
    }
    return TRUE;
}
/*
 * ----------------------------------------------------------------------------
 *
 * DBTechSetVersion --
 *
 * Set the version number & description for the technology.
 *
 * Results:
 *	Returns FALSE if there were an improper number of
 *	tokens on the line.
 *
 * Side effects:
 *	Sets DBTechVersion and DBTechDescription.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
bool
DBTechSetVersion(char *sectionName, int argc, char **argv)
{
    if (argc != 2) goto usage;
    if (strcmp(argv[0], "version") == 0) {
	(void) StrDup(&DBTechVersion, argv[1]);
	return TRUE;
    }
    if (strcmp(argv[0], "description") == 0) {
	(void) StrDup(&DBTechDescription, argv[1]);
	return TRUE;
    }
usage:
    MnTechError("Badly formed version line\nUsage: {version text}|{description text}\n");
    return FALSE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechInitConnect --
 *
 * Initialize the connectivity tables.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes DBConnectTbl[] and DBConnectPlanes.
 *
 * ----------------------------------------------------------------------------
 */

Void
DBTechInitConnect(void)
{
    register int i;

    for (i = 0; i < TT_MAXTYPES; i++)
    {
	TTMaskSetOnlyType(&DBConnectTbl[i], i);
	DBConnectPlanes[i] = NULL;
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechAddConnect --
 *
 * Add connectivity information.
 * Record the fact that material of the types in the comma-separated
 * list types1 connects to material of the types in the list types2.
 *
 * Results:
 *	TRUE if successful, FALSE on error
 *
 * Side effects:
 *	Updates DBConnectTbl[].
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
bool
DBTechAddConnect(char *sectionName, int argc, char **argv)
{
    TileTypeBitMask types1, types2;
    register TileType t1, t2;

    if (argc != 2)
    {
	MnTechError("Line must contain exactly 2 lists of types\n");
	return FALSE;
    }

    DBTechNoisyNameMask(argv[0], &types1);
    DBTechNoisyNameMask(argv[1], &types2);
    for (t1 = 0; t1 < DBNumTypes; t1++)
	if (TTMaskHasType(&types1, t1))
	    for (t2 = 0; t2 < DBNumTypes; t2++)
		if (TTMaskHasType(&types2, t2))
		{
		    TTMaskSetType(&DBConnectTbl[t1], t2);
		    TTMaskSetType(&DBConnectTbl[t2], t1);
		}


    return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechFinalConnect --
 *
 * Postprocessing for the connectivity information.
 *
 * Builds DBConnectPlanes[] (list of planes connecting to each type) 
 *
 * Create DBNotConnectTbl[], the complement of DBConnectTbl[].
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies DBConnectTbl[]
 *	as above.
 *
 * ----------------------------------------------------------------------------
 */

Void
DBTechFinalConnect(void)
{
    TileType base, s;

    /* Make the connectivity matrix symmetric */
    for (base = TT_TECHDEPBASE; base < DBNumTypes; base++)
	for (s = TT_TECHDEPBASE; s < DBNumTypes; s++)
	    if (TTMaskHasType(&DBConnectTbl[base], s))
		TTMaskSetType(&DBConnectTbl[s], base);

    /* Construct DBNotConnectTbl[] to be the complement of DBConnectTbl[] */
    for (base = 0; base < TT_MAXTYPES; base++)
	TTMaskCom2(&DBNotConnectTbl[base], &DBConnectTbl[base]);

    /*
     * Now finally create DBconnectTbl, and DBConnectPlanes
     * for those planes to which each type 'base' connects, exclusive
     * of its home plane.
     */
    for (base = TT_TECHDEPBASE; base < DBNumTypes; base++)
    {
      TileTypeBitMask types;
      TileTypeBitMask *samePlaneTypes = &DBPlaneTypes[DBPlane(base)];

      /* types connecting to base */
      types = DBConnectTbl[base];

      /* less types on same plane */
      TTMaskClearMask(&types, samePlaneTypes);
      
      DBConnectPlanes[base] = DBPlaneListFromTypes(&types);
    }
}
