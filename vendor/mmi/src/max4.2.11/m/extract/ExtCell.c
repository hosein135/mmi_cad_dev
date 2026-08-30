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
 * ExtCell.c --
 *
 * Circuit extraction.
 * Extract a single cell.
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
static char rcsid[] = "$Header: ExtCell.c,v 6.0 90/08/28 18:15:06 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <math.h>
#include <string.h>
#include "magic.h"
#include "geometry.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "message.h"
#include "debug.h"
#include "extract.h"
#include "extractInt.h"
#include "signals.h"
#include "stack.h"
#include "utils.h"
#include "layout.h"
#include "main.h"
#include "undo.h"

/* --------------------------- Global data ---------------------------- */

    /* Used to identify the extractor version that produced a .ext file */
char *ExtVersionString = "5.0";

    /*
     * Value normally present in ti_client to indicate tiles that have not
     * been marked with their associated region.
     */
ClientData extUnInit = (ClientData) MINFINITY;

/* ------------------------ Data local to this file ------------------- */

    /* Forward declarations */
int extOutputUsesFunc(CellUse *cu, FILE *outf);
FILE *extFileOpen(CellDef *def, char *file, char *mode, char **prealfile);


/*
 * ----------------------------------------------------------------------------
 *
 * extFileOpen --
 *
 * Open the .ext file corresponding to a .mag file.
 * If def->cd_file is non-NULL, the .ext file is just def->cd_file with
 * the trailing .mag replaced by .ext.  Otherwise, the .ext file is just
 * def->cd_name followed by .ext.
 *
 * Results:
 *	Return a pointer to an open FILE, or NULL if the .ext
 *	file could not be opened in the specified mode.
 *
 * Side effects:
 *	Opens a file.
 *
 * ----------------------------------------------------------------------------
 */

FILE *
extFileOpen(CellDef *def, 
	                    /* Cell whose .ext file is to be written */
	    char *file, 
               		/* If non-NULL, open 'name'.ext; otherwise,
			 * derive filename from 'def' as described
			 * above.
			 */
	    char *mode, 
               		/* Either "r" or "w", the mode in which the .ext
			 * file is to be opened.
			 */
	    char **prealfile)
                     	/* If this is non-NULL, it gets set to point to
			 * a string holding the name of the .ext file.
			 */
{
    char name[BUFSIZ];
    int len;

    /* compute name of file to open */
    if (file)
    {
      /* explicit name given */
      strcpy(name,file);
    }
    else if (def->cd_file)
    {
      char base[BUFSIZ]; 
      char ext[BUFSIZ]; /* tossed */ 

      PaSplitName(def->cd_file,name,base,ext);
      strcat(name,base);  /* append base name to dir part */
    }
    else 
    {
      /* derive from cell name */
      strcpy(name,def->cd_name);
    }
    /* explicitly tack on extension because "." in names
     * of gcells otherwise inhibits ".ext" extension by PaOpen
     */
    strcat(name,".ext");

    return PaOpen(name, mode, NULL, MnPathCell, NULL, prealfile);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extHeader --
 *
 * Output header information to the .ext file for a cell.
 * This information consists of:
 *
 *	timestamp
 *	extractor version number
 *	technology
 *	scale factors for resistance, capacitance, and lambda
 *	calls on all subcells used by this cell (see extOutputUsesFunc)
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes to (FILE *) 'f'.
 *
 * ----------------------------------------------------------------------------
 */

void
extHeader(CellDef *def, FILE *f)
                 	/* Cell being extracted */
            		/* Write to this file */
{
    register int n;

    /* Output version stamp of def 
     * (identifys wich version of def the .ext file corresponds to.
     *
     * NOTE:  currently only outputting time part of version stamp,
     * since ext file format does not support "rev" info.
     */
    (void) fprintf(f, "timestamp %d\n", def->cd_vMAIN.vs_time);

    /* Output our version number */
    (void) fprintf(f, "version %s\n", ExtVersionString);

    /* Output the technology */
    (void) fprintf(f, "tech %s\n", DBTechName);

    /*
     * Output scaling factors: R C D
     *		R = amount to multiply all resistances in the file by
     *		C = amount to multiply all capacitances by
     *		D = amount to multiply all linear distances by (areas
     *		    should be multiplied by D**2).
     */
    (void) fprintf(f, "scale %d %d %g\n",
		ExtCurStyle->exts_resistScale,
		ExtCurStyle->exts_capScale,
		ExtCurStyle->exts_unitsPerLambda);

    /* Output the sheet resistivity classes */
    (void) fprintf(f, "resistclasses");
    for (n = 0; n < ExtCurStyle->exts_numResistClasses; n++)
	(void) fprintf(f, " %d", ExtCurStyle->exts_resistByResistClass[n]);
    (void) fprintf(f, "\n");

    /* Output all calls on subcells */
    (void) DBEnumChildren(def, extOutputUsesFunc, (ClientData) f);
}

/*
 * ----------------------------------------------------------------------------
 *
 * extCellFile --
 *
 * Internal interface for extracting a single cell.
 * Extracts it to the open FILE 'f'.  Doesn't print
 * any messages.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May leave feedback information where errors were encountered.
 *	Upon return, extNumFatal has been incremented by the number of
 *	fatal errors encountered while extracting 'def', and extNumWarnings
 *	by the number of warnings.
 *
 * ----------------------------------------------------------------------------
 */

void extCellFile(CellDef *def, 
                 	/* Def to be extracted */
		 FILE *f, 
            		/* Output to this file */
		 int doLength)
                  	/* TRUE if we should extract driver-receiver path
			 * length information for this cell (see ExtCell
			 * for more details).
			 */
{
    NodeRegion *reg;
    UndoDisable();

    /* Output the header: timestamp, technology, calls on cell uses */
    if (!SigInterruptPending) extHeader(def, f);

    /* Extract the mask information in this cell */
    reg = (NodeRegion *) NULL;
    if (!SigInterruptPending) reg = extBasic(def, f);

    /* Do hierarchical extraction */
    extParentUse->cu_def = def;
    if (!SigInterruptPending) extSubtree(extParentUse, f);
    if (!SigInterruptPending) extArray(extParentUse, f);

    /* Clean up from basic extraction */
    if (reg) ExtFreeLabRegions((LabRegion *) reg);
    ExtResetTiles(def, extUnInit);

    /* Final pass: extract length information if desired */
    if (!SigInterruptPending && doLength && (ExtOptions & EXT_DOLENGTH))
	extLength(extParentUse, f);

    UndoEnable();
}


/*
 * ----------------------------------------------------------------------------
 *
 * extOutputUsesFunc --
 *
 * Filter function, called via DBEnumChildren, that outputs all the
 * cell uses contained in the parent's cell tile planes.
 *
 * Results:
 *	Always returns 0, for DBEnumChildren to keep going.
 *
 * Side effects:
 *	Writes a line for each use encountered to 'outf'.
 *	The line is of the following form:
 *
 *		use defname useid Ta ... Tf
 *
 *	where 'defname' is the name of the cell def referenced (cd_name),
 *	'useid' is its use identifier (cu_id), and Ta ... Tf are the six
 *	components of the transform from coordinates of this use up to
 *	its parent.  If the cell is an array, the use id may be followed by:
 *
 *		[xlo,xhi,xsep][ylo,yhi,ysep]
 *
 *	The indices are xlo through xhi inclusive, or ylo through yhi
 *	inclusive.  The separation between adjacent elements is xsep
 *	or ysep; this is used in computing the transform for a particular
 *	array element.  If arraying is not present in a given direction,
 *	the low and high indices are equal and the separation is ignored.
 *
 * ----------------------------------------------------------------------------
 */

int
extOutputUsesFunc(CellUse *cu, FILE *outf)
{
    Transform *t = &cu->cu_transform;

    (void) fprintf(outf, "use %s %s", cu->cu_def->cd_name, cu->cu_id);
    if (cu->cu_xlo != cu->cu_xhi || cu->cu_ylo != cu->cu_yhi)
    {
	(void) fprintf(outf, "[%d:%d:%d]",
		       cu->cu_xlo, 
		       cu->cu_xhi, 
		       extScaleDim(cu->cu_xsep));
	(void) fprintf(outf, "[%d:%d:%d]",
		       cu->cu_ylo, 
		       cu->cu_yhi, 
		       extScaleDim(cu->cu_ysep));
    }

    /* Output transform to parent */
    (void) fprintf(outf, " %d %d %d %d %d %d\n",
		   t->t_a, 
		   t->t_b, 
		   extScaleDim(t->t_c), 
		   t->t_d, 
		   t->t_e, 
		   extScaleDim(t->t_f));

    return (0);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ExtCell --
 *
 * Extract the cell 'def', plus all its interactions with its subcells.
 * Place the result in the file named 'outName'.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates the file 'outName'.ext and writes to it.
 *	May leave feedback information where errors were encountered.
 *	Upon return, extNumFatal contains the number of fatal errors
 *	encountered while extracting 'def', and extNumWarnings contains
 *	the number of warnings.
 *
 * ----------------------------------------------------------------------------
 */

Void
ExtCell(CellDef *def, char *outName, int doLength)
                 	/* Cell being extracted */
                  	/* Name of output file; if NULL, derive from def name */
                  	/* If TRUE, extract pathlengths from drivers to
			 * receivers (the names are stored in ExtLength.c).
			 * Should only be TRUE for the root cell in a
			 * hierarchy.
			 */
{
    char *filename;
    FILE *f;

    f = extFileOpen(def, outName, "w", &filename);
    MsgInfoF("Extracting %s into %s:\n", def->cd_name, filename);
    if (f == NULL)
    {
	MsgErrorF("Cannot open output file: ");
	perror(filename);
	return;
    }

    extNumFatal = extNumWarnings = 0;
    extCellFile(def, f, doLength);
    (void) fclose(f);

    if (extNumFatal > 0 || extNumWarnings > 0)
    {
	MsgInfoF("%s:", def->cd_name);
	if (extNumFatal > 0)
	    MsgInfoF(" %d fatal error%s",
		extNumFatal, extNumFatal != 1 ? "s" : "");
	if (extNumWarnings > 0)
	    MsgInfoF(" %d warning%s",
		extNumWarnings, extNumWarnings != 1 ? "s" : "");
	MsgInfoF("\n");
    }
}
