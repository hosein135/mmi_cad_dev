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
 * ExtMain.c --
 *
 * Circuit extraction.
 * Command interface.
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
static char rcsid[] = "$Header: ExtMain.c,v 6.0 90/08/28 18:15:19 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <math.h>
#include "magic.h"
#include "geometry.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "message.h"
#include "debug.h"
#include "signals.h"
#include "stack.h"
#include "utils.h"
#include "layout.h"
#include "main.h"
#include "undo.h"
#include "extract.h"
#include "extractInt.h"

/* Imports from elsewhere in this module */
extern FILE *extFileOpen(CellDef *def, char *file, char *mode, char **prealfile);

/* ------------------------ Exported variables ------------------------ */

    /*
     * See extract.h for the bit flags that may be set in the following.
     * If any are set, the corresponding warnings get generated, leaving
     * feedback messages.  If this word is zero, only fatal errors are
     * reported.
     */
int ExtDoWarn = EXTWARN_DUP|EXTWARN_FETS;
int ExtOptions = EXT_DOALL;

/* stepsize for hierarchical processing, in typical wire widths 
 * linked to tcl var EXT_STEP_SIZE 
 */
int extStepSize = 100;

/* --------------------------- Global data ---------------------------- */

    /* Cumulative yank buffer for hierarchical circuit extraction */
CellUse *extYuseCum = NULL;
CellDef *extYdefCum = NULL;

    /* Identifier returned by the debug module for circuit extraction */
ClientData extDebugID;

    /* Number of errors encountered during extraction */
int extNumFatal;
int extNumWarnings;

    /* Dummy use pointing to def being extracted */
CellUse *extParentUse;

/* ------------------------ Data local to this file ------------------- */

    /* Stack of defs pending extraction */
Stack *extDefStack;


/*
 * ----------------------------------------------------------------------------
 *
 * ExtInit --
 *
 * Initialize the technology-independent part of the extraction module.
 * This procedure should be called once, after the database module has
 * been initialized.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes the local variables of the extraction module.
 *	Registers the extractor with the debugging module.
 *
 * ----------------------------------------------------------------------------
 */

void
ExtInit()
{
    register n;
    static struct
    {
	char	*di_name;
	int	*di_id;
    } debugFlags[] = {
	"areaenum",	&extDebAreaEnum,
	"array",	&extDebArray,
	"hardway",	&extDebHardWay,
	"hiercap",	&extDebHierCap,
        "hierareacap",	&extDebHierAreaCap,
	"label",	&extDebLabel,
	"length",	&extDebLength,
	"neighbor",	&extDebNeighbor,
	"noarray",	&extDebNoArray,
	"nofeedback",	&extDebNoFeedback,
	"nohard",	&extDebNoHard,
	"nosubcell",	&extDebNoSubcell,
	"perimeter",	&extDebPerim,
	"resist",	&extDebResist,
	"visonly",	&extDebVisOnly,
	"yank",		&extDebYank,
	0
    };

    /* Register ourselves with the debugging module */
    extDebugID =
	    DebugAddClient("extract", sizeof debugFlags/sizeof debugFlags[0]);
    for (n = 0; debugFlags[n].di_name; n++)
	*(debugFlags[n].di_id) =
		DebugAddFlag(extDebugID, debugFlags[n].di_name);

    /* Create the yank buffer used for hierarchical extraction */
    DBNewYank("__ext_cumulative", &extYuseCum, &extYdefCum);

    /* Create the dummy use also used in hierarchical extraction */
    extParentUse = DBCellNewUse(extYdefCum, (char *) NULL);
    DBCellUseSetTrans(extParentUse, &GeoIdentityTransform);

    /* Initialize the hash tables used in ExtLength.c */
    extLengthInit();
}

/*
 * ----------------------------------------------------------------------------
 *
 * ExtSetup --
 *
 * called on each invocation of extractor, 
 * sets up "stepsize" etc. 
 *
 * ----------------------------------------------------------------------------
 */

void
ExtSetup(void)
{
  if(ExtCurStyle)
  {
    ExtCurStyle->exts_stepSize = extStepSize * MnTypicalWireWidth();
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * ExtAll --
 *
 * Extract the subtree rooted at the CellDef 'rootUse->cu_def'.
 * Each cell is extracted to a file in the current directory
 * whose name consists of the last part of the cell's path,
 * with a .ext suffix.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates a number of .ext files and writes to them.
 *	Adds feedback information where errors have occurred.
 *
 * ----------------------------------------------------------------------------
 */

ExtAll(CellUse *rootUse)
{
    /* Make sure the entire subtree is read in, and instance bounding boxes
     * are up-to-date */
    DBCellReadTree(rootUse->cu_def);
    DBUpdate(rootUse->cu_def);

    /* make sure that all cd_client fields are clear 
     *  (used to mark defs we have visited)
     */
    DBCellClearDefClients(TRUE);

    /* Recursively visit all defs in the tree and push on stack */
    extDefStack = StackNew(100);
    (void) extDefPushFunc(rootUse);

    /* Now extract all the cells we just found */
    extExtractStack(extDefStack, TRUE, rootUse->cu_def);
    StackFree(extDefStack);

    /* be a good citizen and clear all cd_client fields */
    DBCellClearDefClients(FALSE);
}

/*
 * Function to push each cell def on extDefStack
 * if it hasn't already been pushed, and then recurse
 * on all that def's children.
 */
extDefPushFunc(CellUse *use)
{
    CellDef *def = use->cu_def;

    if (def->cd_client || (def->cd_flags&CDINTERNAL))
	return (0);

    def->cd_client = (ClientData) 1;
    StackPush((ClientData) def, extDefStack);
    (void) DBEnumChildren(def, extDefPushFunc, (ClientData) 0);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ExtUnique --
 *
 * For each cell in the subtree rooted at rootUse->cu_def, make
 * sure that there are not two different nodes with the same label.
 * If there are, and either the label ends in a '#' or allNames is
 * TRUE, we generate unique names by appending a numeric suffix to
 * all but one of the offending labels.  Otherwise, if the label
 * doesn't end in a '!', we leave feedback.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May modify the label lists of some of the cells rooted
 *	at rootUse->cu_def, and mark the cells as CDMODIFIED.
 *	May also leave feedback.
 *
 * ----------------------------------------------------------------------------
 */

ExtUnique(CellUse *rootUse, int allNames)
{
    CellDef *def;
    int nwarn;

    /* Make sure the entire subtree is read in, and instance bounding boxes
     * are up-to-date 
     */
    DBCellReadTree(rootUse->cu_def);
    DBUpdate(rootUse->cu_def);

    /* make sure that all cd_client fields are clear 
     *  (used to mark defs we have visited)
     */
    DBCellClearDefClients(TRUE);

    /* Recursively visit all defs in the tree and push on stack */
    extDefStack = StackNew(100);
    (void) extDefPushFunc(rootUse);

    /* Now process all the cells we just found */
    nwarn = 0;
    while (def = (CellDef *) StackPop(extDefStack))
    {
	def->cd_client = (ClientData) 0;
	if (!SigInterruptPending)
	    nwarn += extUniqueCell(def, allNames);
    }
    StackFree(extDefStack);

    /* be a good citizen and clear all cd_client fields */
    DBCellClearDefClients(FALSE);

    if (nwarn)
	MsgErrorF("%d uncorrected errors (see the feedback info)\n", nwarn);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ExtParents --
 * ExtShowParents --
 *
 * ExtParents extracts the cell use->cu_def and all its parents.
 * ExtShowParents merely finds and prints all the parents without
 * extracting them.
 *
 * As in ExtAll, each cell is extracted to a file in the current
 * directory whose name consists of the last part of the cell's path,
 * with a .ext suffix.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates a number of .ext files and writes to them.
 *	Adds feedback information where errors have occurred.
 *
 * ----------------------------------------------------------------------------
 */

ExtParents(CellUse *use)
{
    extParents(use, TRUE);
}

ExtShowParents(CellUse *use)
{
    extParents(use, FALSE);
}

extParents(CellUse *use, int doExtract)
                 
                   	/* If TRUE, we extract; if FALSE, we print */
{
    /* make sure that all cd_client fields are clear 
     *  (used to mark defs we have visited)
     */
    DBCellClearDefClients(TRUE);

    /* Recursively visit all defs in the tree and push on stack */
    extDefStack = StackNew(100);
    extDefParentFunc(use->cu_def);

    /* Now extract all the cells we just found */
    extExtractStack(extDefStack, doExtract, (CellDef *) NULL);
    StackFree(extDefStack);

    /* be a good citizen and clear all cd_client fields */
    DBCellClearDefClients(FALSE);
}

/*
 * Function to visit all the parents of 'def' and push them on
 * extDefStack.  We only push a def if it is unmarked, ie, its
 * cd_client field is 0.  After pushing a def, we mark it by
 * setting its cd_client field to 1.
 */

extDefParentFunc(CellDef *def)
{
    CellUse *parent;

    if (def->cd_client || (def->cd_flags&CDINTERNAL))
	return;

    def->cd_client = (ClientData) 1;
    StackPush((ClientData) def, extDefStack);
    for (parent = def->cd_uses; parent; parent = parent->cu_nextuse)
	if (parent->cu_parent)
	    extDefParentFunc(parent->cu_parent);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ExtParentArea --
 *
 * ExtParentArea extracts the cell use->cu_def and each of its
 * parents that contain geometry touching or overlapping the area
 * of use->cu_def.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates one or more .ext files and writes to them.
 *	Adds feedback information where errors have occurred.
 *
 * ----------------------------------------------------------------------------
 */

ExtParentArea(CellUse *use, Rect *changedArea, int doExtract)
                 	/* Use->cu_def changed; extract its affected parents */
                      	/* Area changed in use->cu_def coordinates */
                   	/* If TRUE, we extract; if FALSE, we just print names
			 * of the cells we would extract.
			 */
{
    Rect area;

    /* make sure we are up-to-date */
    (void) DBBBoxCellUse(use);

    /* make sure that all cd_client fields are clear 
     *  (used to mark defs we have visited)
     */
    DBCellClearDefClients(TRUE);

    /*
     * Recursively visit all defs in the tree
     * and push on stack if they contain any geometry
     * overlapping or touching the area 'changedArea'.
     */
    area = *changedArea;
    area.r_xbot--, area.r_ybot--;
    area.r_xtop++, area.r_ytop++;
    extDefStack = StackNew(100);
    extDefParentAreaFunc(use->cu_def, use->cu_def, (CellUse *) NULL, &area);

    /* Now extract all the cells we just found */
    extExtractStack(extDefStack, doExtract, (CellDef *) NULL);
    StackFree(extDefStack);

    /* be a good citizen and clear all cd_client fields */
    DBCellClearDefClients(FALSE);
}

/*
 * Function to visit all the parents of 'def' and push them on
 * extDefStack.  We only push a def if it is unmarked, ie, its
 * cd_client field is 0, and if it is either 'baseDef' or it
 * contains geometry or other subcells in the area 'area'.
 * We mark each def visited by setting cd_client to 1.
 */

extDefParentAreaFunc(CellDef *def, CellDef *baseDef, CellUse *allButUse, Rect *area)
{
    int x, y, xoff, yoff;
    CellUse *parent;
    Transform t, t2;
    Rect parArea;

    if (def->cd_client || (def->cd_flags&CDINTERNAL))
	return;

    if (def == baseDef || extContainsGeometry(def, allButUse, area))
    {
	def->cd_client = (ClientData) 1;
	StackPush((ClientData) def, extDefStack);
    }

    for (parent = def->cd_uses; parent; parent = parent->cu_nextuse)
    {
	if (parent->cu_parent)
	{
	    for (x = parent->cu_xlo; x <= parent->cu_xhi; x++)
	    {
		for (y = parent->cu_ylo; y <= parent->cu_yhi; y++)
		{
		    xoff = (x - parent->cu_xlo) * parent->cu_xsep;
		    yoff = (y - parent->cu_ylo) * parent->cu_ysep;
		    GeoTranslateTrans(&GeoIdentityTransform, xoff, yoff, &t);
		    GeoTransTrans(&t, &parent->cu_transform, &t2);
		    GeoTransRect(&t2, area, &parArea);
		    extDefParentAreaFunc(parent->cu_parent, baseDef,
				parent, &parArea);
		}
	    }
	}
    }
}

static int extContainsPaintFunc(void)
{
    return (1);
}

bool
extContainsGeometry(CellDef *def, CellUse *allButUse, Rect *area)
{
    int pNum;

    /* contains cells ? */
    {
      BPEnum bpe;
      bool cellFound;
	      
      BPEnumInit(&bpe,
		 def->cd_cellPlane,
		 area,
		 BPE_OVERLAP,
		 "extContainsGeometry");
      cellFound = (BPEnumNext(&bpe)!=NULL);
      BPEnumTerm(&bpe);

      if(cellFound) return TRUE;
    }

    /* contains paint ? */
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
	if (DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[pNum],
			area, &DBAllButSpaceBits,
			extContainsPaintFunc, (ClientData) NULL))
	    return (TRUE);

    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ExtIncremental --
 *
 * Starting at 'rootUse', extract all cell defs that have changed.
 * Right now, we forcibly read in the entire tree before doing the
 * extraction.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates a number of .ext files and writes to them.
 *	Adds feedback information where errors have occurred.
 *
 * ----------------------------------------------------------------------------
 */

ExtIncremental(CellUse *rootUse)
{
    /* Make sure the entire subtree is read in, 
     * and instance bounding boxes are up-to-date 
     */
    DBCellReadTree(rootUse->cu_def);
    DBUpdate(rootUse->cu_def);

    /* make sure that all cd_client fields are clear 
     *  (used to mark defs we have visited)
     */
    DBCellClearDefClients(TRUE);

    /*
     * Recursively visit all defs in the tree
     * and push on stack if they need extraction.
     */
    extDefStack = StackNew(100);
    (void) extDefIncrementalFunc(rootUse);

    /* Now extract all the cells we just found */
    extExtractStack(extDefStack, TRUE, rootUse->cu_def);

    StackFree(extDefStack);

    /* be a good citizen and clear all cd_client fields */
    DBCellClearDefClients(FALSE);
}

/*
 * Function to push each cell def on extDefStack if it hasn't
 * already been pushed and if it needs re-extraction, and then
 * recurse on all that def's children.
 */

extDefIncrementalFunc(CellUse *use)
{
    CellDef *def = use->cu_def;

    if (def->cd_client || (def->cd_flags&CDINTERNAL))
	return (0);

    def->cd_client = (ClientData) 1;
    if (extTimestampMisMatch(def))
	StackPush((ClientData) def, extDefStack);
    (void) DBEnumChildren(def, extDefIncrementalFunc, (ClientData) 0);
    return (0);
}

/*
 * Function returning TRUE if 'def' needs re-extraction.
 * This will be the case if either the .ext file for 'def'
 * does not exist, or if its timestamp fails to match that
 * recorded in 'def'.
 */

bool
extTimestampMisMatch(CellDef *def)
{
    char line[256];
    FILE *extFile;
    bool ret = TRUE;
    int stamp;

    extFile = extFileOpen(def, (char *) NULL, "r", (char **) NULL);
    if (extFile == NULL)
	return (TRUE);

    if (fgets(line, sizeof line, extFile) == NULL) goto closeit;
    if (sscanf(line, "timestamp %d", &stamp) != 1) goto closeit;

    /* check if def version matches last extraction  */
    if (def->cd_vMAIN.vs_time != stamp) goto closeit;
    ret = FALSE;

closeit:
    (void) fclose(extFile);
    return (ret);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extExtractStack --
 *
 * If 'doExtract' is TRUE, call ExtCell for each def on the stack 'stack';
 * otherwise, print the name of each def on the stack 'stack'.
 * The root cell of the tree being processed is 'rootDef'; we only
 * extract pathlength information for this cell.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Leaves 'stack' empty.
 *	Calls ExtCell on each def on the stack if 'doExtract' is TRUE.
 *	Resets cd_client to 0 for each def on the stack.
 *	Prints the total number of errors and warnings.
 *
 * ----------------------------------------------------------------------------
 */

extExtractStack(Stack *stack, int doExtract, CellDef *rootDef)
{
    int fatal = 0, warnings = 0;
    bool first = TRUE;
    CellDef *def;

    while (def = (CellDef *) StackPop(stack))
    {
	def->cd_client = (ClientData) 0;
	if (!SigInterruptPending)
	{
	    if (doExtract)
	    {
		ExtCell(def, (char *) NULL, def == rootDef);
		fatal += extNumFatal;
		warnings += extNumWarnings;
	    }
	    else
	    {
		if (!first) MsgInfoF(", ");
		MsgInfoF("%s", def->cd_name);
		first = FALSE;
	    }
	}
    }

    if (!doExtract)
    {
	MsgInfoF("\n");
    }
    else
    {
	if (fatal > 0)
	    MsgErrorF("Total of %d fatal error%s.\n",
		    fatal, fatal != 1 ? "s" : "");
	if (warnings > 0)
	    MsgErrorF("Total of %d warning%s.\n",
		    warnings, warnings != 1 ? "s" : "");
    }
}
