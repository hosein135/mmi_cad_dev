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
 * DRCmain.c --
 *
 * This file provides global routines that are invoked at
 * command-level.  They do things like give information about
 * errors and print statistics.
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

#ifndef	lint
static char rcsid[] = "$Header: DRCmain.c,v 1.4 92/07/17 15:20:24 mayo Exp $";
#endif	not lint

#include <sys/types.h>
#include <stdio.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "undo.h"
#include "signals.h"
#include "drc.h"
#include "drcInt.h"

extern void MsgInfoF(), MsgErrorF();

/* stepsize for processing, in typical wire widths 
 * linked to tcl var DRC_STEP_SIZE 
 */
int drcStepSizeWidths = 50;

/* The global variables defined below are parameters between
 * the DRC error routines (drcPaintError and drcPrintError)
 * and the higher-level routines that start up DRC error checks.
 * It seemed simpler to do the communication this way rather
 * than creating a special new record that is passed down as
 * ClientData.  Any routine invoking DRCBasicCheck with drcPaintError
 * or drcPrintError as action routine should fill in the relevant
 * variables.
 */

/* Used by both routines: */

int DRCErrorCount;		/* Incremented by each call to either routine.
				 */

/* Used by drcPaintError: */

CellDef *DRCErrorDef;		/* Place to paint error tiles. */
TileType DRCErrorType;		/* Type of error tile to paint. */

/* Used by drcPrintError: */

HashTable DRCErrorTable;	/* Hash table used to eliminate duplicate
				 * error strings.
				 */

/* Values shared by DRCFind and drcFindFunc: */

Rect *drcFindRect;		/* Rectangle to fill in with found error. */
int drcFindIndex = 0;		/* Index of error to return. */
int drcCurrentIndex;

/* Global variables used by all DRC modules to record statistics.
 * For each statistic we keep two values, the count since stats
 * were last printed (in DRCstatXXX), and the total count (in
 * drcTotalXXX).
 */

int DRCstatSquares = 0;		/* Number of drcStepSize-by-drcStepSize
				 * squares processed by continuous checker.
				 */
int DRCstatTiles = 0;		/* Number of tiles processed by basic
				 * checker.
				 */
int DRCstatEdges = 0;		/* Number of "atomic" edges processed
				 * by basic checker.
				 */
int DRCstatRules = 0;		/* Number of rules processed by basic checker
				 * (rule = one constraint for one edge).
				 */
int DRCstatSlow = 0;		/* Number of places where constraint doesn't
				 * all fall in a single tile.
				 */
int DRCstatInteractions = 0;	/* Number of times drcInt is called to check
				 * an interaction area.
				 */
int DRCstatIntTiles = 0;	/* Number of tiles processed as part of
				 * subcell interaction checks.
				 */
int DRCstatCifTiles = 0;	/* Number of tiles processed as part of
				 * cif checks.
				 */
int DRCstatArrayTiles = 0;	/* Number of tiles processed as part of
				 * array interaction checks.
				 */

#ifdef	DRCRULESHISTO
int DRCstatVRulesHisto[DRC_MAXRULESHISTO];
int DRCstatHRulesHisto[DRC_MAXRULESHISTO];
#endif	DRCRULESHISTO

static int drcTotalSquares = 0;
static int drcTotalTiles = 0;
static int drcTotalEdges = 0;
static int drcTotalRules = 0;
static int drcTotalSlow = 0;
static int drcTotalInteractions = 0;
static int drcTotalIntTiles = 0;
static int drcTotalCifTiles = 0;
static int drcTotalArrayTiles = 0;

#ifdef	DRCRULESHISTO
static int drcTotalVRulesHisto[DRC_MAXRULESHISTO];
static int drcTotalHRulesHisto[DRC_MAXRULESHISTO];
#endif	DRCRULESHISTO


/* Record interaction areas here as part of the DRC why function, so we can
 * screen out the errors found by the basic checker that are corrected by
 * subcells.
 */
static Plane *drcInteractPlane = NULL;


/*
 * ----------------------------------------------------------------------------
 * drcSetup -
 *
 * called each time checker is invoked, to recompute stepsize etc.
 *
 * ----------------------------------------------------------------------------
 */

void drcSetup(void)
{
  drcStepSize = drcStepSizeWidths * MnTypicalWireWidth();
}


/*
 * ----------------------------------------------------------------------------
 * drcPaintError --
 *
 * Action function that paints error tiles for each violation found.
 *
 * Results:
 *	Zero.
 *
 * Side effects:
 *	A tile of type DRCErrorType is painted over the area of
 *	the error, in the plane given by "plane".  Also, DRCErrorCount
 *	is incremented.
 * ----------------------------------------------------------------------------
 */

/* ARGSUSED */
void
drcPaintError(CellDef *celldef, 
                        		/* CellDef being checked */
	      Rect *rect, 
                     			/* Area of error */
	      DRCCookie *cptr, 
                       			/* Design rule violated -- not used */
	      Plane *plane)
                      			/* Where to paint error tiles. */
{
    DBPaintPlane(plane, 
		 rect, 
		 DBStdPaintTbl(DRCErrorType,PL_DRC_ERROR), 
		 (PaintUndoInfo *) NULL);
    DRCErrorCount += 1;
}
/*
 * ----------------------------------------------------------------------------
 * drcRecordInteract --
 *
 * Action function that records interaction areas.
 *
 * Results:
 *	Zero.
 *
 * Side effects:
 *	Records the interaction area with a solid tile the plane passed.
 * ----------------------------------------------------------------------------
 */

/* ARGSUSED */
void
drcRecordInteract(Rect *area, Plane *plane)
                                /* Area to record.  */
                                /* Plane to erase from. */

{
    DBPaintPlane(plane, area, DBStdWriteTbl(TT_ERROR_S), (PaintUndoInfo *) NULL);
}

/*
 * ----------------------------------------------------------------------------
 * drcPrintError --
 *
 * Action function that prints the error message associated with each
 * violation found.
 *
 * Results:
 *	Zero.
 *
 * Side effects:
 *	DRCErrorCount is incremented.  The text associated with
 *	the error is entered into DRCErrorTable, and, if this is
 *	the first time that entry has been seen, then the error
 *	text is printed.  If the area parameter is non-NULL, then
 *	only errors intersecting that area are considered.
 * ----------------------------------------------------------------------------
 */

/* ARGSUSED */
void
drcPrintError (CellDef *celldef, Rect *rect, DRCCookie *cptr, Rect *area)
                        	/* CellDef being checked -- not used here */
                     		/* Area of error */
                       		/* Design rule violated */
                     		/* Only errors in this area get reported. */
{
    HashEntry *h;
    int i;

    ASSERT (cptr != (DRCCookie *) NULL, "drcPrintError");

    if ((area != NULL) && (!GEO_OVERLAP(area, rect))) return;
    if (GEO_RECTNULL(rect)) return;
    DRCErrorCount += 1;
    h = HashFind(&DRCErrorTable, cptr->drcc_why);
    i = (int) HashGetValue(h);
    if (i == 0)
	MsgInfoF("%s\n", cptr->drcc_why);
    i += 1;
    HashSetValue(h, i);
}
/*
 * ----------------------------------------------------------------------------
 * drcDetectSpaceTile --
 *
 * See if the tile being processed is a space tile.
 *
 * Results:
 *	1 if it is a space tile.
 *	0 to continue search.
 *
 * Side effects:
 *	None.
 * ----------------------------------------------------------------------------
 */

/* ARGSUSED */

int
drcDetectSpaceTile(Tile *tile, ClientData arg)
{
    if (DBgetTileType(tile) == TT_SPACE) return 1; 
    return 0;
}
/*
 * ----------------------------------------------------------------------------
 * drcPrintNoInteractFunc --
 *
 * Action function that prints the error message associated with each
 * violation found, but only if it is not over an interaction area.
 *
 * Results:
 *	Zero.
 *
 * Side effects:
 *	DRCErrorCount is incremented.  The text associated with
 *	the error is entered into DRCErrorTable, and, if this is
 *	the first time that entry has been seen, then the error
 *	text is printed.  If the area parameter is non-NULL, then
 *	only errors intersecting that area are considered.
 *	Interaction areas are retrieve from drcInteractPlane.
 * ----------------------------------------------------------------------------
 */

/* ARGSUSED */
void
drcPrintNoInteractFunc(CellDef *celldef, Rect *rect, DRCCookie *cptr, Rect *area)
                        	/* CellDef being checked -- not used here */
                     		/* Area of error */
                       		/* Design rule violated */
                     		/* Only errors in this area get reported. */
{
    HashEntry *h;
    int i;

    ASSERT (cptr != (DRCCookie *) NULL, "drcPrintError");

    if ((area != NULL) && (!GEO_OVERLAP(area, rect))) return;
    if (GEO_RECTNULL(rect)) return;
    if (DBPlaneEnumAreaPaint((Tile *) NULL, drcInteractPlane, rect,
	&DBAllTypeBits, drcDetectSpaceTile, (ClientData) NULL) == 0) return;

    DRCErrorCount += 1;
    h = HashFind(&DRCErrorTable, cptr->drcc_why);
    i = (int) HashGetValue(h);
    if (i == 0)
	MsgInfoF("%s\n", cptr->drcc_why);
    i += 1;
    HashSetValue(h, i);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCPrintStats --
 *
 * 	Prints out statistics gathered by the DRC checking routines.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Statistics are printed.  Two values are printed for each
 *	statistic:  the number since statistics were last printed,
 *	and the total to date.	The own variables used to keep
 *	track of statistics are updated.
 *
 * ----------------------------------------------------------------------------
 */

static int percent(int a, int b) { return (b <= 0) ? 0 : a*100/b;}

void
DRCPrintStats(void)
{
#ifdef	DRCRULESHISTO
    int n;
#endif	DRCRULESHISTO

    drcSetup();

    MsgInfoF("Design-rule checker statistics (recent/total):\n");

    drcTotalSquares += DRCstatSquares;
    drcTotalTiles += DRCstatTiles;
    drcTotalIntTiles += DRCstatIntTiles;
    drcTotalCifTiles += DRCstatCifTiles;
    drcTotalArrayTiles += DRCstatArrayTiles;
    drcTotalEdges += DRCstatEdges;
    drcTotalRules += DRCstatRules;
    drcTotalSlow += DRCstatSlow;
    drcTotalInteractions += DRCstatInteractions;

    MsgInfoF("    Squares processed: %d/%d\n", DRCstatSquares,
	drcTotalSquares);
    MsgInfoF("    Total tiles processed: %d/%d\n", DRCstatTiles, drcTotalTiles);

    MsgInfoF("    Tiles processed for interactions: %d (%d%%) / %d (%d%%)\n",
	DRCstatIntTiles, percent(DRCstatIntTiles, DRCstatTiles),
	drcTotalIntTiles, percent(drcTotalIntTiles, drcTotalTiles));
    MsgInfoF("    Tiles processed for cif rules: %d (%d%%) / %d (%d%%)\n",
	DRCstatCifTiles, percent(DRCstatCifTiles, DRCstatTiles), 
	drcTotalCifTiles, percent(drcTotalCifTiles, drcTotalTiles));
    MsgInfoF("    Tiles processed for arrays: %d (%d%%) / %d (%d%%)\n",
	DRCstatArrayTiles, percent(DRCstatArrayTiles, DRCstatTiles),
	drcTotalArrayTiles, percent(drcTotalArrayTiles, drcTotalTiles));

    MsgInfoF("    Edges pieces processed: %d/%d\n", DRCstatEdges,
	drcTotalEdges);
    MsgInfoF("    Constraint areas checked: %d/%d\n", DRCstatRules,
	drcTotalRules);
    MsgInfoF("    Multi-tile constraints: %d/%d\n", DRCstatSlow,
	drcTotalSlow);
    MsgInfoF("    Interaction areas processed: %d/%d\n",
	DRCstatInteractions, drcTotalInteractions);

    DRCstatTiles = 0;
    DRCstatSquares = 0;
    DRCstatIntTiles = 0;
    DRCstatCifTiles = 0;
    DRCstatArrayTiles = 0;
    DRCstatEdges = 0;
    DRCstatRules = 0;
    DRCstatSlow = 0;
    DRCstatInteractions = 0;

#ifdef	DRCRULESHISTO
    MsgInfoF("    Number of rules applied per edge:\n");
    MsgInfoF("    # rules         Horiz freq            Vert freq\n");
    for (n = 0; n < DRC_MAXRULESHISTO; n++)
    {
	drcTotalHRulesHisto[n] += DRCstatHRulesHisto[n];
	drcTotalVRulesHisto[n] += DRCstatVRulesHisto[n];
	if (drcTotalHRulesHisto[n] == 0 && drcTotalVRulesHisto[n] == 0)
	    continue;
	MsgInfoF("      %3d      %10d/%10d  %10d/%10d\n",
		n,
		DRCstatHRulesHisto[n], drcTotalHRulesHisto[n],
		DRCstatVRulesHisto[n], drcTotalVRulesHisto[n]);
	DRCstatHRulesHisto[n] = DRCstatVRulesHisto[n] = 0;
    }
#endif	DRCRULESHISTO

    MsgInfoF("Halo: %d, Stepsize: %d\n", TechHalo, drcStepSize);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCWhy --
 *
 * 	This procedure finds all errors within an area and prints messages
 *	about each distinct kind of violation found.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None, except that error messages are printed.  The given
 *	area is DRC'ed for both paint and subcell violations in every
 *	cell of def's tree that it intersects.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCWhy(CellUse *use, Rect *area)
                 			/* Use in whose definition to start
					 * the hierarchical check.
					 */
               				/* Area, in def's coordinates, that
					 * is to be checked.
					 */
{
    SearchContext scx;
    Rect box;
    extern int drcWhyFunc(SearchContext *scx, ClientData cdarg);		/* Forward reference. */

    drcSetup();

    /* Create a hash table to used for eliminating duplicate messages. */

    HashInit(&DRCErrorTable, 16, 0);
    DRCErrorCount = 0;

    /* Undo will only slow things down in here, so turn it off. */

    UndoDisable();
    scx.scx_use = use;
    scx.scx_x = use->cu_xlo;
    scx.scx_y = use->cu_ylo;
    scx.scx_area = *area;
    scx.scx_trans = GeoIdentityTransform;

    /* make sure we are all up-to-date, including scx_use->cu_bbox */
    (void) DBBBoxCellUse(scx.scx_use);

    (void) drcWhyFunc(&scx, (ClientData) NULL);
    UndoEnable();

    /* Delete the hash table now that we're finished (otherwise there
     * will be a core leak.
     */
	
    HashKill(&DRCErrorTable);

    /* Redisplay the DRC yank definition in case anyone is looking
     * at it.
     */
    DBChangedArea(DRCdef, NULL, &DBAllButSpaceBits, 0);

    if (DRCErrorCount == 0) MsgInfoF("No errors found.\n");
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcWhyFunc --
 *
 * 	This function is invoked underneath DrcWhy.  It's called once
 *	for each subcell instance of the current cell.  If the subcell
 *	is expanded, then it computes errors in that subcell and
 *	searches the subcell recursively.
 *
 * Results:
 *	Always returns 0 to keep the search alive.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
int
drcWhyFunc(SearchContext *scx, ClientData cdarg)
                       		/* Describes current state of search. */
                     		/* Not used. */
{
    Rect haloArea;
    CellDef *def = scx->scx_use->cu_def;
    void (*printFunc)();
    void (*recordFunc)();

    /* don't recheck cells that are checked with parent */ 
    if (def->cd_flags&CD_DRC_WITH_PARENT) return 0;

    if (drcInteractPlane == NULL)
    {  
	drcInteractPlane = DBPlaneNew((ClientData) TT_SPACE);
    }
    recordFunc = drcRecordInteract;
    printFunc = drcPrintNoInteractFunc;

    /* Check paint and interactions in this subcell. */
    GEO_EXPAND(&scx->scx_area, TechHalo, &haloArea);
    (void) DRCInteractionCheck(def, &scx->scx_area,
	drcPrintError, (ClientData) &scx->scx_area, 
	recordFunc, drcInteractPlane);
    (void) DRCBasicCheck(def, &haloArea, &scx->scx_area,
	printFunc, (ClientData) &scx->scx_area);
    (void) DRCArrayCheck(def, &scx->scx_area,
	drcPrintError, (ClientData) &scx->scx_area);

    DBPlaneClearPaint(drcInteractPlane);
    
    /* Recursively search children. */
    (void) DBSrChildrenNested(scx, drcWhyFunc, (ClientData) NULL);

    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCCheck --
 *
 * 	Marks area, to force recheck by the DRC. 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Check tiles are painted.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCCheck(CellUse *use, 
                 		/* Top-level use of hierarchy. */
	 Rect *area)
               			/* This area is rechecked everywhere in the
				 * hierarchy underneath use.
				 */
{
    SearchContext scx;
    extern int drcCheckFunc(SearchContext *scx, ClientData cdarg);	/* Forward reference. */

    drcSetup();

    DBCellReadArea(use, area);

    scx.scx_use = use;
    scx.scx_x = use->cu_xlo;
    scx.scx_y = use->cu_ylo;
    scx.scx_area = *area;
    scx.scx_trans = GeoIdentityTransform;

    /* make sure we are all up-to-date, including scx_use->cu_bbox */
    (void) DBBBoxCellUse(scx.scx_use);

    (void) drcCheckFunc(&scx, (ClientData) NULL);
}

	/* ARGSUSED */
int
drcCheckFunc(SearchContext *scx, ClientData cdarg)
                       
                     		/* Not used. */
{
    Rect cellArea;
    CellDef *def;

    /* Clip the area to the size of the cell, then recheck that area.
     * 
     */

    cellArea = scx->scx_area;
    def = scx->scx_use->cu_def;
    GeoClip(&cellArea, &def->cd_bbox);

    DRCChangedArea(def, &cellArea);

    /* recursviely do descendents */
    (void) DBSrChildrenNested(scx, drcCheckFunc, (ClientData) NULL);

    /* As a special performance hack, if the complete cell area is
     * handled here, don't bother to look at any more array elements.
     */
    if (GEO_SURROUND(&cellArea, &def->cd_bbox))
	return 2;
    else return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCCount --
 *
 * 	Searches the entire hierarchy underneath the given area.
 *	For each cell found, counts design-rule violations in
 *	that cell and outputs the counts.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None, except for the text output.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCCount(CellUse *use, Rect *area)
                 		/* Top-level use of hierarchy. */
               			/* Area in which violations are counted. */
{
    HashTable dupTable;
    SearchContext scx;
    extern int drcCountFunc(SearchContext *scx, HashTable *dupTable);	/* Forward reference. */

    drcSetup();

    /* Use a hash table to make sure that we don't output information
     * for any cell more than once.
     */

    HashInit(&dupTable, 16, 1);

    DBCellReadArea(use, area);

    scx.scx_use = use;
    scx.scx_x = use->cu_xlo;
    scx.scx_y = use->cu_ylo;
    scx.scx_area = *area;
    scx.scx_trans = GeoIdentityTransform;

    /* make sure we are all up-to-date, including scx_use->cu_bbox */
    (void) DBBBoxCellUse(scx.scx_use);

    (void) drcCountFunc(&scx, &dupTable);

    /* Clean up the hash table to avoid core leak. */

    HashKill(&dupTable);
}

int
drcCountFunc(SearchContext *scx, HashTable *dupTable)
                       
                        		/* Passsed as client data, used to
					 * avoid searching any cell twice.
					 */
{
    int count;
    HashEntry *h;
    CellDef *def;
    extern int drcCountFunc2(Tile *tile, int *pCount);

    /* If we've already seen this cell definition before, then skip it
     * now.
     */

    def = scx->scx_use->cu_def;
    h = HashFind(dupTable, (char *) def);
    if (HashGetValue(h) != 0) goto done;
    HashSetValue(h, 1);

    /* Count errors in this cell definition by scanning the error plane. */

    count = 0;
    (void) DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[PL_DRC_ERROR],
	&def->cd_bbox, &DBAllButSpaceBits, drcCountFunc2, (ClientData) &count);
    if (count > 1)
        MsgInfoF("Cell %s has %d error tiles.\n", def->cd_name, count);
    else if (count == 1)
	MsgInfoF("Cell %s has just one error tile.\n", def->cd_name);

    /* Scan children recursively. */
    (void) DBSrChildrenNested(scx, drcCountFunc, (ClientData) dupTable);

    /* As a special performance hack, if the complete cell area is
     * handled here, don't bother to look at any more array elements.
     */
    
    done: if (GEO_SURROUND(&scx->scx_area, &def->cd_bbox)) return 2;
    else return 0;
}

int
drcCountFunc2(Tile *tile, int *pCount)
               			/* Tile found in error plane. */
                		/* Address of count word. */
{
    if (DBgetTileType(tile) != (TileType) TT_SPACE) *pCount += 1;
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCCatchUp--
 *
 * 	This procedure just runs the background checker, regardless
 *	of whether it's enabled or not, and waits for it to complete.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Error and check tiles get painted and erased by the checker.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCCatchUp(void)
{
    int background;

    background = DRCBackGround;
    DRCBackGround = TRUE;

    /* process check areas until interrupted */
    DRCContinuous(FALSE /* don't check for user input */);

    DRCBackGround = background;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCFind --
 *
 * 	Locates the next violation tile in the cell pointed to by def.
 *	Successive calls will located successive violations, in
 *	circular order.
 *
 * Results:
 *	If an error tile was found in def, returns the indx of
 *	the error tile (> 0).  Returns 0 if there were no error
 *	tiles in def, or if a specific indx was given and there
 *	weren't that many error tiles in def.
 *
 * Side effects:
 *	Rect is filled with the location of the tile, if one is found.
 *
 * ----------------------------------------------------------------------------
 */

int
DRCFind(CellDef *def, Rect *rect, int indx)
                 		/* Cell definition to check. */
               			/* Rectangle to fill in with tile location. */
             			/* If > 1, go to this error.  If < 1, just go
				 * to the next error.
				 */
{
    int drcFindFunc(Tile *tile, ClientData dummy);

    drcSetup();

    drcFindRect = rect;
    if (indx > 0) drcFindIndex = indx;
    else drcFindIndex += 1;

    /* We may have to make two searches (the second is necessary if
     * we've seen the last error in the cell;  it goes back to the
     * first again).
     */

    (void) DBCellRead(def, (char *) NULL, TRUE);
    while (TRUE)
    {
	drcCurrentIndex = 1;
	if (DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[PL_DRC_ERROR],
	    &def->cd_bbox, &DBAllButSpaceBits, drcFindFunc,
	    (ClientData) NULL) != 0)
	{
	    return drcFindIndex;
	}
	if ((drcFindIndex == 1) || (indx > 0)) return FALSE;
	drcFindIndex = 1;
    }
}

    /*ARGSUSED*/
int
drcFindFunc(Tile *tile, ClientData dummy)
               			/* Tile in error plane. */
                     		/* Not used. */

{
    if (DBgetTileType(tile) == (TileType) TT_SPACE) return 0;
    if (drcCurrentIndex == drcFindIndex)
    {
	TiToRect(tile, drcFindRect);
	return 1;
    }
    drcCurrentIndex += 1;
    return 0;
}




/*
 * ----------------------------------------------------------------------------
 *
 * DRCClean --
 *
 * 	Called to declare a def drc correct (whether it really is or not).
 *      Rms all check areas, syncs up instance versions, rms all drc error
 *      tiles.
 *
 *	Subsequent changes will cause areas to be checked.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCClean(CellDef *def)
{
  CellUse *use;

  /* clear DRC info in cell */
  DBPlaneClearPaint(def->cd_planes[PL_DRC_CHECK]);
  DBPlaneClearPaint(def->cd_planes[PL_DRC_ERROR]);
  def->cd_flags &= ~(CD_DRC_PENDING | CD_DRC_ALL);

  DBChangedArea(def, 
		NULL, 
		&DBAllButSpaceBits,
		DBCF_DISPLAY);
		
  for(use = def->cd_uses; use; use=use->cu_nextuse)
  {  
    use->cu_vDRC = use->cu_def->cd_vDRC;
  }
}




