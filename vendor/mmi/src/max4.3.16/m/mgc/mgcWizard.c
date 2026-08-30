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
 * mgcWizard.c --
 *
 * *** Wizard commands ***
 *
 * These commands are not intended to be used by the ordinary magic
 * user, but are provided for the benefit of system maintainers/implementors.
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
static char rcsid[] = "$Header: CmdWizard.c,v 6.1 90/09/04 10:41:54 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/types.h>
#include <sys/times.h>
#include "magic.h"
#include "geometry.h"
#include "memory.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"
#include "commands.h"
#include "message.h"
#include "signals.h"
#include "utils.h"
#include "extract.h"
#include "mgcint.h"


/*
 * ----------------------------------------------------------------------------
 *
 * CmdCoord --
 *
 * Show the coordinates of various things:
 *	Point tool		edit coords, root coords, curr coords
 *	Box tool		edit coords, root coords, curr coords
 *	Edit cell bounding box	edit coords, root coords
 *	Root cell bounding box	edit coords, root coords
 *	Curr cell bounding box	curr coords, root coords
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

void CmdCoord(Layout *w, TxCommand *cmd)
{
    Layout *pointW = (Layout *) NULL;
    Rect editRect, rootRect;
    Transform tinv;
    CellDef *rootDef;

    if ((w = LayPointGet((Point *) NULL, &rootRect)) != (Layout *) NULL)
    {
	pointW = w;
	rootDef = w->lay_rootUse->cu_def;
	MsgInfoF("Point:\tr=(%d,%d)::(%d,%d)",
			rootRect.r_xbot, rootRect.r_ybot,
			rootRect.r_xtop, rootRect.r_ytop);
	if (EditRootDef == rootDef)
	{
	    GeoTransRect(&RootToEditTransform, &rootRect, &editRect);
	    MsgInfoF("\te=(%d,%d)::(%d,%d)",
			editRect.r_xbot, editRect.r_ybot,
			editRect.r_xtop, editRect.r_ytop);
	}
	MsgInfoF("\n");
    }

    if (ToolGetBox(&rootDef, &rootRect))
    {
	MsgInfoF("Box:\tr=(%d,%d)::(%d,%d)",
			rootRect.r_xbot, rootRect.r_ybot,
			rootRect.r_xtop, rootRect.r_ytop);
	if (EditRootDef == rootDef)
	{
	    GeoTransRect(&RootToEditTransform, &rootRect, &editRect);
	    MsgInfoF("\te=(%d,%d)::(%d,%d)",
			editRect.r_xbot, editRect.r_ybot,
			editRect.r_xtop, editRect.r_ytop);
	}
	MsgInfoF("\n");
    }

    if (pointW == (Layout *) NULL)
    {
	rootRect.r_xbot = rootRect.r_ybot = 0;
	rootRect.r_xtop = rootRect.r_ytop = 1;
	rootDef = EditRootDef;
    }
    else
    {
	rootDef = pointW->lay_rootUse->cu_def;
	rootRect = *DBBBoxCellUse(pointW->lay_rootUse);
    }

    MsgInfoF("Root cell:\tr=(%d,%d)::(%d,%d)",
		    rootRect.r_xbot, rootRect.r_ybot,
		    rootRect.r_xtop, rootRect.r_ytop);
    if (EditRootDef == rootDef)
    {
	GeoTransRect(&RootToEditTransform, &rootRect, &editRect);
	MsgInfoF("\te=(%d,%d)::(%d,%d)",
		    editRect.r_xbot, editRect.r_ybot,
		    editRect.r_xtop, editRect.r_ytop);
    }
    MsgInfoF("\n");

    GeoInvertTrans(&EditCellUse->cu_transform, &tinv);
    GeoTransRect(&tinv, DBBBoxCellUse(EditCellUse), &editRect);
    MsgInfoF("Edit cell:");
    if (EditRootDef == rootDef)
    {
	GeoTransRect(&EditToRootTransform, &editRect, &rootRect);
	MsgInfoF("\tr=(%d,%d)::(%d,%d)",
		    rootRect.r_xbot, rootRect.r_ybot,
		    rootRect.r_xtop, rootRect.r_ytop);
    }
    MsgInfoF("\te=(%d,%d)::(%d,%d)",
		    editRect.r_xbot, editRect.r_ybot,
		    editRect.r_xtop, editRect.r_ytop);
    MsgInfoF("\n");
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdExtractTest --
 *
 * Debugging of circuit extraction.
 *
 * Usage:
 *	*extract cmd [args]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See comments in ExtractTest() in extract/ExtTest.c for details.
 *
 * ----------------------------------------------------------------------------
 */

void CmdExtractTest(Layout *w, TxCommand *cmd)
{
    ExtractTest(w, cmd->tx_argc, cmd->tx_argv);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdShowtech --
 *
 * Usage:
 *
 *	showtech [outfile]
 *
 * Display all the internal technology tables.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May write to a disk file.
 *
 * ----------------------------------------------------------------------------
 */

void showTech(FILE *outf, 
               		/* File to which information is to be output */
	      int verbose)
                 	/* If TRUE, output detailed erase table */
{
    int i, j;
    int pNum;
    bool first, any;

    (void) fprintf(outf, "Technology %s\n", DBTechName);
    (void) fprintf(outf, "%d tile planes, %d tile types\n\n",
		DBNumPlanes, DBNumTypes);
    (void) fprintf(outf, "Planes:\n");
    for (i = 0; i < DBNumPlanes; i++)
	(void) fprintf(outf, "%s\t%s\n", DBPlaneShortName(i),
		DBPlaneLongName(i));

    (void) fprintf(outf, "\n");
    (void) fprintf(outf, "Types:\n");
    for (i = 0; i < DBNumTypes; i++)
	(void) fprintf(outf, "%s\t%s\t%s\n", DBPlaneShortName(DBPlane(i)),
		DBTypeShortName(i), DBTypeLongName(i));

    (void) fprintf(outf, "\n");
    (void) fprintf(outf, "\014Connectivity:\n");
    for (j = 0; j < DBNumTypes; j++)
	for (i = 0; i < j; i++)
	    if (DBConnectsTo(i, j))
		fprintf(outf, "%s :: %s\n",
			DBTypeLongName(j), DBTypeLongName(i));
    (void) fprintf(outf, "\n");

    (void) fprintf(outf, "\n\014Component Layers:\n");
    for (i = 0; i < DBNumUserLayers; i++)
	for (j = 0; j < DBNumUserLayers; j++)
	    if ((j != i) && TTMaskHasType(&DBComponentTbl[j], i))
		fprintf(outf, "%s is a component of %s\n",
		    DBTypeLongName(i), DBTypeLongName(j));
    (void) fprintf(outf, "\n");

    (void) fprintf(outf, "\014Planes affected by painting:\n");
    (void) fprintf(outf, "Type                  Planes\n");
    (void) fprintf(outf, "----                  ------\n");
    for (i = 0; i < DBNumTypes; i++)
    {
	(void) fprintf(outf, "%-22.22s", DBTypeLongName(i));
	first = TRUE;
	for (pNum = 1; pNum < DBNumPlanes; pNum++)
	{
	    if( i==TT_SPACE || DBPlane(i) == pNum)
	    {
		if (first)
		    first = FALSE;
		else
		    (void) fprintf(outf, ", ");
		(void) fprintf(outf, "%s", DBPlaneLongName(pNum));
	    }
	}
	(void) fprintf(outf, "\n");
    }

    (void) fprintf(outf, "\014Planes affected by erasing:\n");
    (void) fprintf(outf, "Type                  Planes\n");
    (void) fprintf(outf, "----                  ------\n");
    for (i = 0; i < DBNumTypes; i++)
    {
	(void) fprintf(outf, "%-22.22s", DBTypeLongName(i));
	first = TRUE;
	for (pNum = 1; pNum < DBNumPlanes; pNum++)
	{
	    if (i==TT_SPACE || DBPlane(i)==pNum)
	    {
		if (!first)
		    (void) fprintf(outf, ", ");
		first = FALSE;
		(void) fprintf(outf, "%s", DBPlaneLongName(pNum));
	    }
	}
	(void) fprintf(outf, "\n");
    }

    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
	(void) fprintf(outf, "\014Paint: %s\n", DBPlaneLongName(pNum));
	(void) fprintf(outf, "=======================================\n");
	for (i = 0; i < DBNumTypes; i++)
	{
	    if (i == TT_SPACE || DBPlane(i) == pNum)
	    {
		any = FALSE;
		for (j = 0; j < DBNumTypes; j++)
		{
		    if (!verbose && (i == TT_SPACE || j == TT_SPACE))
			continue;
		    if (DBStdPaintEntry(i, j, pNum) != i)
		    {
			(void) fprintf(outf, "%s + %s --> %s\n",
				DBTypeLongName(i), DBTypeLongName(j),
				DBTypeLongName(DBStdPaintEntry(i, j, pNum)));
			any = TRUE;
		    }
		}
		if (any)
		    (void) fprintf(outf,
				"--------------------------------------\n");
	    }
	}
    }

    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
	(void) fprintf(outf, "\014Erase: %s\n", DBPlaneLongName(pNum));
	(void) fprintf(outf, "=======================================\n");
	for (i = 0; i < DBNumTypes; i++)
	{
	    if (i == TT_SPACE || DBPlane(i) == pNum)
	    {
		any = FALSE;
		for (j = 0; j < DBNumTypes; j++)
		{
		    if (!verbose && i == j)
			continue;
		    if (DBStdEraseEntry(i, j, pNum) != i)
		    {
			(void) fprintf(outf, "%s - %s --> %s\n",
				DBTypeLongName(i), DBTypeLongName(j),
				DBTypeLongName(DBStdEraseEntry(i, j, pNum)));
			any = TRUE;
		    }
		}
		if (any)
		    (void) fprintf(outf,
				"--------------------------------------\n");
	    }
	}
    }
}

    /* ARGSUSED */

void CmdShowtech(Layout *w, TxCommand *cmd)
{
    FILE *outf;
    bool verbose;
    char **av;
    int ac;

    if (cmd->tx_argc > 3)
    {
	MsgErrorF("Usage: showtech [-v] [file]\n");
	return;
    }

    verbose = FALSE;
    av = &cmd->tx_argv[1];
    ac = cmd->tx_argc - 1;

    outf = stdout;
    if (ac > 0 && strcmp(av[0], "-v") == 0)
    {
	verbose = TRUE;
	av++, ac--;
    }

    if (ac > 0)
    {
	outf = fopen(av[0], "w");
	if (outf == (FILE *) NULL)
	{
	    perror(av[0]);
	    MsgErrorF("Nothing written\n");
	    return;
	}
    }

    showTech(outf, verbose);
    if (outf != stdout)
	(void) fclose(outf);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdTilestats --
 *
 * Generate statistics on tile utilization.
 * The output is either to the terminal or to the file supplied.
 * Usage:
 *	*tilestats -a [file]	to generate statistics for all cells
 *	*tilestats [file]	to generate statistics for the currently
 *				selected cell.
 *
 * If the argument 'file' is specified, it is created to hold the
 * output of the *tilestats command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May create a disk file.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */
void CmdTilestats(Layout *w, TxCommand *cmd)
{
    CellUse *selectedUse;
    FILE *outf = stdout;
    bool allDefs = FALSE;
    char **av = cmd->tx_argv + 1;
    int ac = cmd->tx_argc - 1;
    int cmdStatsFunc(CellDef *def, FILE *outf);

    if (ac > 2)
    {
	MsgErrorF("Usage: tilestats [-a] [outputfile]\n");
	return;
    }

    if (ac > 0 && strcmp(av[0], "-a") == 0)
	allDefs = TRUE, ac--, av++;

    if (ac > 0 && (outf = fopen(av[0], "w")) == NULL)
    {
	perror(av[0]);
	return;
    }

    selectedUse = CmdGetSelectedCell((Transform *) NULL);

    /* make sure that all cd_client fields are clear */
    DBCellClearDefClients(TRUE);

    if (allDefs)
	(void) DBCellSrDefs(0, cmdStatsFunc, (ClientData) outf);
    else if (selectedUse != NULL)
	(void) cmdStatsFunc(selectedUse->cu_def, outf);
    else
	MsgErrorF("No cell selected.\n");
    if (outf != stdout)
	(void) fclose(outf);

    /* check that all cd_client fields are clear again */ 
    DBCellClearDefClients(TRUE);
}


/* Stored with each CellDef in the cd_client field */
struct cellInfo
{
    int		ci_count[TT_MAXTYPES];		/* Count of tiles of each
						 * type in this cell.
						 */
    int		ci_hierCount[TT_MAXTYPES];	/* Count of tiles of each
						 * type in all subtrees,
						 * weighted by the number
						 * of times each subtree is
						 * used.
						 */
    bool	ci_countedHier;			/* TRUE if ci_hierCount has
						 * yet been computed.
						 */
};

/* Passed by DBTreeCountPaint to the clients */
struct countClient
{
    FILE	*cc_outFile;	/* Output statistics to this file */
    CellDef	*cc_rootDef;	/* Root definition for which we're computing
				 * all the statistics.
				 */
};

/* Records the total number of drawn tiles of each type */
int totalTiles[TT_MAXTYPES];

/*
 * ----------------------------------------------------------------------------
 *
 * cmdStatsFunc --
 *
 * Generate the hierarchical statistics for a single cell def.
 *
 * Results:
 *	Returns 0 always.
 *
 * Side effects:
 *	Writes to the file outf.
 *
 * ----------------------------------------------------------------------------
 */

int cmdStatsFunc(CellDef *def, FILE *outf)
{
    int cmdStatsCount(CellDef *def, struct countClient *cc), cmdStatsOutput(CellDef *def, struct countClient *cc);
    Void cmdStatsHier(CellDef *parent, register int nuses, CellDef *child);
    struct countClient cc;
    int total;
    TileType t;

    cc.cc_outFile = outf;
    cc.cc_rootDef = def;
    for (t = 0; t < DBNumTypes; t++)
	totalTiles[t] = 0;

    DBTreeCountPaint(def, cmdStatsCount, cmdStatsHier,
		cmdStatsOutput, (ClientData) &cc);

    total = 0;
    for (t = TT_SPACE; t < DBNumTypes; t++)
    {
	if (totalTiles[t])
	{
	    (void) fprintf(outf, "%s\tTOTAL\t%s\t%d\n",
		    def->cd_name, DBTypeLongName(t), totalTiles[t]);
	    total += totalTiles[t];
	}
    }

    (void) fprintf(outf, "%s\tTOTAL\tALL\t%d\n", def->cd_name, total);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cmdStatsCount --
 *
 * Count the number of tiles in a single cell.
 * If def->cd_client has already been filled in, we just return;
 * otherwise, we make def->cd_client point to a newly allocated
 * cellInfo struct, and fill in the ci_count and ci_pageFill
 * fields.
 *
 * Results:
 *	Returns 1 if def->cd_client had already been filled in,
 *	0 otherwise.
 *
 * Side effects:
 *	May modify def->cd_client.
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
int cmdStatsCount(CellDef *def, struct countClient *cc)
{
    int cmdStatsCountTile(register Tile *tile, register struct cellInfo *ci);
    int pNum, tCount;
    struct cellInfo *ci;
    TileType t;

    if (def->cd_client)
	return (1);

    /* Allocate a new cellInfo struct for this CellDef */
    MALLOC_TAG(struct cellInfo *,
	       ci,
	       sizeof (struct cellInfo),
	       "cellInfo");

    def->cd_client = (ClientData) ci;
    for (t = TT_SPACE; t < DBNumTypes; t++)
    {
	ci->ci_count[t] = ci->ci_hierCount[t] = 0;
	ci->ci_countedHier = FALSE;
    }

    /* Visit all tiles */
    for (pNum = PL_SELECTBASE; pNum < DBNumPlanes; pNum++)
	(void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[pNum],
		&TiPlaneRect, &DBAllTypeBits,
		cmdStatsCountTile, def->cd_client);

    /* Compute total number of tiles */
    tCount = 0;
    for (t = TT_SPACE; t < DBNumTypes; t++)
	tCount += ci->ci_count[t];

    return (0);
}

int
cmdStatsCountTile(register Tile *tile, register struct cellInfo *ci)
{
    TileType type = DBgetTileType(tile);

    /*
     * Count this tile both toward the cell being visited,
     * and the overall total.
     */
    ci->ci_count[type]++;
    totalTiles[type]++;

    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cmdStatsHier --
 *
 * Add to the hierarchical statistics for a given CellDef.
 * If parent's cd_client cellInfo struct has ci_countedHier
 * set, we just return.  (It means that the subtree we are now
 * visiting has already been visited, but since we are called
 * in bottom-up order, there's not much we can do about it).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Adds the hierarchical statistics for child, plus the
 *	per-cell statistics for child, to the hierarchical
 *	statistics for 'parent'.
 *
 *	Since we are guaranteed to be called only after all
 *	children of 'child' have been visited, we know that
 *	we can mark 'child' as having ci_countedHier TRUE.
 *
 * ----------------------------------------------------------------------------
 */

void cmdStatsHier(CellDef *parent, register int nuses, CellDef *child)
{
    register struct cellInfo *pi, *ci;
    register TileType t;

    pi = (struct cellInfo *) parent->cd_client;
    if (pi->ci_countedHier)
	return;

    ci = (struct cellInfo *) child->cd_client;
    ci->ci_countedHier = TRUE;
    for (t = TT_SPACE; t < DBNumTypes; t++)
	pi->ci_hierCount[t] += nuses * (ci->ci_hierCount[t] + ci->ci_count[t]);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cmdStatsOutput --
 *
 * Output the hierarchical statistics for a single cell def.
 * If 'def' has not yet had its statistics output, we output
 * for each tile type having non-zero counts:
 *	- the number of tiles of this type in this cell, plus
 *	  hierarchically in all of its children, pretending
 *	  that the entire subtree was flattened (so each tile
 *	  is counted as many times as it logically appears in
 *	  the hierarchy).
 *	- the number of tiles of this type in this cell alone.
 * These numbers are also output for the total number of tiles
 * of all types.
 *
 * Results:
 *	If we had already output statistics for this cell, we
 *	return 1; otherwise we return 0.
 *
 * Side effects:
 *	Writes to the file outf.
 *	If def->cd_client points to a cellInfo struct, we free it
 *	and clear def->cd_client.
 *
 * ----------------------------------------------------------------------------
 */

int cmdStatsOutput(CellDef *def, struct countClient *cc)
{
    register TileType t;
    register struct cellInfo *ci;
    int count, hiercount;

    if (def->cd_client == NULL)
	return (1);

    ci = (struct cellInfo *) def->cd_client;
    def->cd_client = (ClientData) NULL;

    count = hiercount = 0;
    for (t = TT_SPACE; t < DBNumTypes; t++)
    {
	if (ci->ci_hierCount[t] | ci->ci_count[t])
	{
	    /* Root-def this-def type-name num-flat num-paint */
	    (void) fprintf(cc->cc_outFile, "%s\t%s\t%s\t%d\t%d\n",
		    cc->cc_rootDef->cd_name, def->cd_name,
		    DBTypeLongName(t),
		    ci->ci_hierCount[t] + ci->ci_count[t], ci->ci_count[t]);
	    count += ci->ci_count[t];
	    hiercount += ci->ci_hierCount[t];
	}
    }

    /* Root-def this-def ALL num-flat num-paint fill-factor */
    if (hiercount | count)
    {
	(void) fprintf(cc->cc_outFile, "%s\t%s\tALL\t%d\t%d\n",
		cc->cc_rootDef->cd_name, def->cd_name,
		hiercount + count, count);
	(void) fprintf(cc->cc_outFile, "%s\t%s\n",
		cc->cc_rootDef->cd_name, def->cd_name);
    }

    FREE_TAG(ci, "cellInfo");
    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdPsearch --
 *
 * Run point search a number of times the point at the lower-left
 * corner of the box tool to each point in the edit cell.
 *
 * Usage:
 *	psearch plane count
 *
 * Where plane is the name of the plane on which the search is to be
 * carried out, and count is the number of searches to be performed.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

 /* ARGSUSED */

void CmdPsearch(Layout *w, TxCommand *cmd)
{
    char *RunStats();
    Point p;
    Plane *plane;
    Rect rtool;
    register Rect *ebox;
    register Tile *tp;
    Tile *TiSrPointNew();
    int i, pNum, count;
    double userBase,sysBase,realBase;
    double user,sys,real;


    if (cmd->tx_argc != 3)
    {
	MsgErrorF("Usage: psearch plane count\n");
	return;
    }

    pNum = DBTechNamePlane(cmd->tx_argv[1]);
    if (pNum < 0)
    {
	MsgErrorF("Unrecognized plane: %s\n", cmd->tx_argv[1]);
	return;
    }

    if (!StrIsInt(cmd->tx_argv[2]))
    {
	MsgErrorF("Count must be numeric\n");
	return;
    }

    count = atoi(cmd->tx_argv[2]);

    ebox = DBBBoxCellDef(EditCellUse->cu_def);
    if (!ToolGetEditBox(&rtool)) return;

    plane = EditCellUse->cu_def->cd_planes[pNum];

    tp = TiSrPoint((Tile *) NULL, plane, &rtool.r_ll);
    
    /* initial times */ 
    UtlsStatProcessTimes(&userBase,&sysBase,&realBase);

#define	BUMP(p, b)	\
	if (++((p).p_x) >= (b)->r_xtop) { (p).p_y++; (p).p_x = (b)->r_xbot; } \
	if ((p).p_y >= (b)->r_ytop) (p) = (b)->r_ll;

    /* Procedural search */
    for (p = ebox->r_ll, i = count; i-- > 0; )
    {
	BUMP(p, ebox);
	(void) TiSrPoint(tp, plane, &p);
    }

    /* elapsed times */ 
    UtlsStatProcessTimes(&user,&sys,&real);
    MsgInfoF("proc: \t%d searches \t%g user_secs \t%g sys_secs \t%g real_secs\n",
	     count,
	     user-userBase,
	     sys-sysBase,
	     real-realBase); 
    userBase=user; sysBase=sys; realBase = real; 

    /* Macro search */
    for (p = ebox->r_ll, i = count; i-- > 0; )
    {
	register Tile *txp = tp;
	BUMP(p, ebox);
	GOTOPOINT(txp, &p);
    }

    /* elapsed times */ 
    UtlsStatProcessTimes(&user,&sys,&real);
    MsgInfoF("macro: \t%d searches \t%g user_secs \t%g sys_secs \t%g real_secs\n",
	     count,
	     user-userBase,
	     sys-sysBase,
	     real-realBase); 
    userBase=user; sysBase=sys; realBase = real; 
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdWatch --
 *
 * Enable/disable watching of tile planes in the given window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Causes the display package to display the actual tile structure
 *	for a given plane, or disables such display.
 *
 * ----------------------------------------------------------------------------
 */

void CmdWatch(Layout *w, TxCommand *cmd)
{
    int pNum;
    int i,flags=0;

    if (w == (Layout *) NULL)
    {
	MsgErrorF("Gee, you don't seem like a wizard!\n");
	MsgErrorF("Cursor not in a layout window.\n");
        return;
    }

    for (i =2 ; i < cmd->tx_argc;i++)
    {
    	 if (strcmp("groups", cmd->tx_argv[i]) ==0)
	 {
	      flags |= Lay_SEEGROUPS;
	 }
	 else if (strcmp("types", cmd->tx_argv[i]) ==0)
	 {
	      flags |= Lay_SEETYPES;
	 }
	 else
	 {
	      MsgErrorF("Gee, you don't sound like a wizard!\n");
	      MsgErrorF("Usage: %s [plane] groups | types]\n", cmd->tx_argv[0]);
	      return;
	 }
    }
    if (cmd->tx_argc == 1)
    {
	pNum = -1;
    }
    else
    {
	pNum = DBTechNamePlane(cmd->tx_argv[1]);
	if (pNum < 0)
	{
	    char *cp;
	    MsgErrorF("Unrecognized plane: %s.  Legal names are:\n",
		    cmd->tx_argv[1]);
	    for(pNum=0; pNum < PL_MAXPLANES; pNum++) {
		cp = DBPlaneLongName(pNum);
		if (cp != NULL)
		    MsgErrorF("	%s\n", cp);
	    };
	    return;
	}
    }

    w->lay_watchPlane = pNum;
    w->lay_flags &= ~(Lay_SEETYPES|Lay_SEEGROUPS);
    w->lay_flags |= flags;

    LayChangedWindow(w, (Rect *) NULL);
}
