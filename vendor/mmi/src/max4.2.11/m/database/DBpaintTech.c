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
 * DBtechpaint.c --
 *
 * Management of composition rules and the paint/erase tables.
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
static char rcsid[] = "$Header: DBtpaint.c,v 6.0 90/08/28 18:10:29 mayo Exp $";
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

    /* Painting and erasing tables */
PaintResultType DBPaintResultTbl[NP][NT][NT];
PaintResultType DBEraseResultTbl[NP][NT][NT];
PaintResultType DBWriteResultTbl[NT][NT];

    /* Components */
TileTypeBitMask DBComponentTbl[NT];

/* ----------------- Data local to tech file processing --------------- */

/*
 * Tables telling which rules are default, and which have come
 * from user-specified rules.  The bit is CLEAR if the type is
 * a default type.
 */
TileTypeBitMask dbNotDefaultEraseTbl[NT];
TileTypeBitMask dbNotDefaultPaintTbl[NT];

/*
 * ----------------------------------------------------------------------------
 *
 * dbTechBitTypeInit --
 *
 * Handle initialization of the paint and erase result tables for a
 * set of ln2(n) primary types with n distinct mutual overlap types.
 * The table bitToType points to a table containing n TileTypes
 * (the overlap types) with the property that
 *
 *	bitToType[i] and bitToType[j] combine to yield bitToType[i | j]
 *
 * Also (unless composeFlag is set) erasing bitToType[j] from bitToType[i] 
 * gives bitToType[i & (~j)],
 * i.e., it clears all of the j-type material out of the i-type material.
 * The bitToType[k] for which k's binary representation has only a single
 * bit set in it are the "primary" types.
 *
 * If composeFlag is set, the above is modified slightly to be analagous
 * to compose rules, specifically, erase rules for nonprimary types are
 * the default rules, i.e. they only erase precisely themselves.  This
 * makes ":erase *-primary" work in the expected way.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

static void 
dbTechBitTypeInit(register TileType *bitToType, 
		  int n, 
		  int pNum, 
		  int composeFlag)
{
    register int i, j;
    TileType have, type;

    for (i = 0; i < n; i++)
    {
	have = bitToType[i];
	for (j = 0; j < n; j++)
	{
	    type = bitToType[j];
	    dbSetPaintEntry(have, type, pNum, bitToType[i | j]);
	    if(!composeFlag || dbIsPrimary(j))
	    {
	        dbSetEraseEntry(have, type, pNum, bitToType[i & (~j)]);
	    }
	}
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechInitCompose --
 *
 * Initialize the painting and erasing rules prior to processing
 * the "compose" section.  The rules for builtin types are computed
 * here, as well as the default rules for all other types.  This
 * procedure must be called after the "types" and "contacts" sections
 * have been read, since we need to know about all existing tile types.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the paint and erase tables.
 *
 * ----------------------------------------------------------------------------
 */

Void
DBTechInitCompose(void)
{
    register TileType s, t, r;
    int pNum, ps;
    /* Default painting rules for error types */
    static TileType errorBitToType[] =
    {
	TT_SPACE,	/* 0 */		TT_ERROR_P,	/* 1 */
	TT_ERROR_S,	/* 2 */		TT_ERROR_PS,	/* 3 */
    };

    /* Painting and erasing are no-ops for undefined tile types */
    for (pNum = 0; pNum < PL_MAXPLANES; pNum++)
    {
	for (s = 0; s < TT_MAXTYPES; s++)
	{
	    for (t = 0; t < TT_MAXTYPES; t++)
	    {
		/* Paint and erase are no-ops */
		dbSetEraseEntry(s, t, pNum, s);
		dbSetPaintEntry(s, t, pNum, s);

		/* Write overwrites existing contents */
		dbSetWriteEntry(s, t, t);
	    }
	}
    }

    /* All painting and erasing rules are default initially */
    for (s = 0; s < DBNumTypes; s++)
    {
	dbNotDefaultEraseTbl[s] = DBZeroTypeBits;
	dbNotDefaultPaintTbl[s] = DBZeroTypeBits;
    }

    /*
     *	For each type t:
     *	    erase(t, t, plane(t)) -> SPACE
     *
     *	For each type s, t:
     *	    paint(s, t, plane(t)) -> t
     *	    paint(s, t, ~plane(t)) -> s
     */
    for (s = 0; s < DBNumTypes; s++)
    {
	if ((ps = DBPlane(s)) > 0)
	{
	    for (t = 0; t < DBNumUserLayers; t++)
	    {
		if (DBPlane(t) > 0)
		{
		    r = (ps == DBPlane(t)) ? t : s;
		    dbSetEraseEntry(s, t, ps, s);
		    dbSetPaintEntry(s, t, ps, r);
		}
	    }

	    /* Everything can be erased to space on its home plane */
	    dbSetEraseEntry(s, s, ps, TT_SPACE);

	    /* Everything paints over space on its home plane */
	    dbSetPaintEntry(TT_SPACE, s, ps, s);
	}
    }

    /*
     * Special handling for check tile and error tile combinations.
     */
#define	PCHK	PL_DRC_CHECK
#define	PERR	PL_DRC_ERROR
#define	tblsize(t)	( (sizeof (t)) / (sizeof (t[0])) )
    dbTechBitTypeInit(errorBitToType, tblsize(errorBitToType), PERR, FALSE);
#undef	tblsize

    /*
     * Paint results are funny for check plane because
     * CHECKPAINT+CHECKSUBCELL = CHECKPAINT
     */
    dbSetPaintEntry(TT_SPACE, TT_CHECKPAINT, PCHK, TT_CHECKPAINT);
    dbSetPaintEntry(TT_SPACE, TT_CHECKSUBCELL, PCHK, TT_CHECKSUBCELL);
    dbSetPaintEntry(TT_CHECKPAINT, TT_CHECKSUBCELL, PCHK, TT_CHECKPAINT);
    dbSetPaintEntry(TT_CHECKSUBCELL, TT_CHECKPAINT, PCHK, TT_CHECKPAINT);
#undef	PCHK
#undef	PERR
}

/* Returns nonzero if exactly one bit set */ 
bool dbIsPrimary(int n)
{
    int bitCount;

    for(bitCount=0; n>0; n=n>>1)
    {
        if(n&1)
        {
	    bitCount++;
        }
    }

    return (bitCount==1);
}
      

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechAddCompose --
 *
 * Process a single compose/decompose rule.  
 *
 * Results:
 *	TRUE if successful, FALSE on error.
 *
 * Side effects:
 *	Modifies the paint/erase tables.
 *      Marks the paint/erase table entries affected to show that they contain
 *	user-specified rules instead of the default ones, so we don't
 *	override them later.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
bool
DBTechAddCompose(char *sectionName, int argc, char **argv)
{
    register TileType type, r, s;
    int ruleType, i;
    static char *ruleNames[] =
	{ "compose", "decompose", "paint", "erase", 0 };
    static int ruleTypes[] =
	{ RULE_COMPOSE, RULE_DECOMPOSE };

    if (argc < 4)
    {
	MnTechError("Line must contain at least ruletype, result + pair\n");
	return FALSE;
    }

    /* Look up and skip over type of rule */
    i = Lookup(*argv, ruleNames);
    if (i < 0)
    {
	MnTechError("%s rule type %s.  Must be one of:\n\t",
		i == -1 ? "Ambiguous" : "Unknown", *argv);
	for (i = 0; ruleNames[i]; i++)
	    MsgErrorF("\"%s\" ", ruleNames[i]);
	MsgErrorF("\n");
	return FALSE;
    }
    ruleType = ruleTypes[i];
    argv++, argc--;

    /* parse rsult type */
    if ((type = DBTechNoisyNameType(*argv)) < 0)
	return FALSE;
    argv++, argc--;

    if(!DBPlaneActive || DBPlane(type) != DBPlaneActive)
    {
	MnTechError("Compose rules only allowed for active plane\n");
	return FALSE;
    }

    if (argc & 01)
    {
	MnTechError("Types on RHS of rule must be in pairs\n");
	return FALSE;
    }

    /* process compose/decompose pairs */ 
    for ( ; argc > 0; argc -= 2, argv += 2)
    {
        int pNum = DBPlaneActive;

	if ((r = DBTechNoisyNameType(argv[0])) < 0
		|| (s = DBTechNoisyNameType(argv[1])) < 0)
	    return FALSE;

	/*  check that types are on active plane */
	if(!DBPlaneActive || 
	   DBPlane(r) != DBPlaneActive ||
	   DBPlane(s) != DBPlaneActive)
	{
	  MnTechError("Compose rules only allowed for active plane\n");
	  return FALSE;
	}
	pNum = DBPlaneActive;


	switch (ruleType)
	{
	    case RULE_COMPOSE:
		dbSetPaintEntry(r, s, pNum, type);
		dbSetPaintEntry(s, r, pNum, type);
		TTMaskSetType(&dbNotDefaultPaintTbl[r], s);
		TTMaskSetType(&dbNotDefaultPaintTbl[s], r);
		/* Fall through to */
	    case RULE_DECOMPOSE:
		dbSetPaintEntry(type, r, pNum, type);
		dbSetPaintEntry(type, s, pNum, type);
		dbSetEraseEntry(type, r, pNum, s);
		dbSetEraseEntry(type, s, pNum, r);
		TTMaskSetType(&dbNotDefaultPaintTbl[type], r);
		TTMaskSetType(&dbNotDefaultPaintTbl[type], s);
		TTMaskSetType(&dbNotDefaultEraseTbl[type], r);
		TTMaskSetType(&dbNotDefaultEraseTbl[type], s);
		break;
	}
    }

    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbTechCheckPaint --
 *
 * DEBUGGING.
 * Check painting and erasing rules to make sure that the result
 * type is legal for the plane being affected.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Prints stuff in the event of an error.
 *
 * ----------------------------------------------------------------------------
 */

Void
dbTechCheckPaint(char *where)
                	/* If non-null, print this as header */
{
    TileType have, t, result;
    bool printedHeader = FALSE;

    for (have = TT_TECHDEPBASE; have < DBNumTypes; have++)
    {
	for (t = TT_TECHDEPBASE; t < DBNumTypes; t++)
	{
	    result = DBStdPaintEntry(have, t, DBPlane(have));
	    if (result != TT_SPACE && DBPlane(result) != DBPlane(have))
	    {
		if (!printedHeader && where)
		    MsgInfoF("\n%s:\n", where), printedHeader = TRUE;
		MsgInfoF("%s + %s -> %s\n",
			DBTypeShortName(have), DBTypeShortName(t),
			DBTypeShortName(result));
	    }
	    result = DBStdEraseEntry(have, t, DBPlane(have));
	    if (result != TT_SPACE && DBPlane(result) != DBPlane(have))
	    {
		if (!printedHeader && where)
		    MsgInfoF("\n%s:\n", where), printedHeader = TRUE;
		MsgInfoF("%s - %s -> %s\n",
			DBTypeShortName(have), DBTypeShortName(t),
			DBTypeShortName(result));
	    }
	}
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbTechPrintPaint --
 *
 * DEBUGGING.
 * Print painting and erasing rules.  
 * The argument
 * "where" is printed as a header if it is non-NULL.  If doPaint is
 * TRUE, we print the paint rules, else we print the erase rules.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Prints stuff.
 *
 * ----------------------------------------------------------------------------
 */

Void
dbTechPrintPaint(char *where, int doPaint)
                	/* If non-null, print this as header */
                 	/* TRUE -> print paint tables, FALSE -> print erase */
                      
{
    TileType have, paint, erase, result;

    if (where)
	MsgInfoF("\f\n%s:\n\n", where);

    if (doPaint)
    {
	MsgInfoF("PAINTING RULES:\n");
	for (have = TT_TECHDEPBASE; have < DBNumTypes; have++)
	{
	    for (paint = TT_TECHDEPBASE; paint < DBNumUserLayers; paint++)
	    {
		result = DBStdPaintEntry(have, paint, DBPlane(have));
		if (result != have)
		{
		    MsgInfoF("%s + %s -> %s\n",
			    DBTypeShortName(have),
			    DBTypeShortName(paint),
			    DBTypeShortName(result));
		}
	    }
	}
    }
    else
    {
	MsgInfoF("ERASING RULES:\n");
	for (have = TT_TECHDEPBASE; have < DBNumTypes; have++)
	{
	    for (erase = TT_TECHDEPBASE; erase < DBNumUserLayers; erase++)
	    {
		result = DBStdEraseEntry(have, erase, DBPlane(have));
		if (result != have)
		{
		    MsgInfoF("%s - %s -> %s\n",
			    DBTypeShortName(have),
			    DBTypeShortName(erase),
			    DBTypeShortName(result));
		}
	    }
	}
    }
}
