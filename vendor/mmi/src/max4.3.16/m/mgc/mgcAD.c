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
 * mgcAD.c --
 *
 * Old Magic commands with names beginning with the letters A through D.
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
static char rcsid[] = "$Header: CmdCD.c,v 6.0 90/08/28 18:07:08 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <tcl.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "main.h"
#include "commands.h"
#include "utils.h"
#include "message.h"
#include "drc.h"
#include "mgcint.h"
#include "cif.h"
#include "gds.h"
#include "styles.h"
#include "select.h"
#include "memory.h"
#include "units.h"

/* The following structure is used by CmdCorner to keep track of
 * areas to be filled.
 */

struct cmdCornerArea
{
    Rect cca_area;			/* Area to paint. */
    TileType cca_type;			/* Type of material. */
    struct cmdCornerArea *cca_next;	/* Next in list of areas to paint. */
};



/*
 * ----------------------------------------------------------------------------
 *
 * CmdArray --
 *
 * Implement the "array" command.  Make everything in the selection
 * into an array.  For paint and labels, just copy.  For subcells,
 * make each use into an arrayed use.
 *
 * Usage:
 *	array xlo xhi ylo yhi
 *	array xsize ysize
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Changes the edit cell.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */
void CmdArray(Layout *w, TxCommand *cmd)
{
    ArrayInfo a;
    Rect toolRect;

    if (cmd->tx_argc != 3 && cmd->tx_argc != 5) goto badusage;
    if (!StrIsInt(cmd->tx_argv[1]) || !StrIsInt(cmd->tx_argv[2])) 
	    goto badusage;
    if (cmd->tx_argc == 3)
    {
	a.ar_xlo = 0;
	a.ar_ylo = 0;
	a.ar_xhi = atoi(cmd->tx_argv[1]) - 1;
	a.ar_yhi = atoi(cmd->tx_argv[2]) - 1;
	if ( (a.ar_xhi < 0) || (a.ar_yhi < 0) ) goto badusage;
    }
    else
    {
	if (!StrIsInt(cmd->tx_argv[3]) || 
		!StrIsInt(cmd->tx_argv[4])) goto badusage;
	a.ar_xlo = atoi(cmd->tx_argv[1]);
	a.ar_xhi = atoi(cmd->tx_argv[2]);
	a.ar_ylo = atoi(cmd->tx_argv[3]);
	a.ar_yhi = atoi(cmd->tx_argv[4]);
    }

    if (!ToolGetBox((CellDef **) NULL, &toolRect))
    {
	MsgErrorF("Position the box to indicate the array spacing.\n");
	return;
    }
    a.ar_xsep = toolRect.r_xtop - toolRect.r_xbot;
    a.ar_ysep = toolRect.r_ytop - toolRect.r_ybot;

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    SelectArray(&a);
    return;

badusage:
    MsgErrorF("Usage: array xlo xhi ylo yhi or array xsize ysize\n");
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdCalma --
 *
 * Implement the "calma" command.
 *
 * Usage:
 *	calma option args
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	There are no side effects on the circuit.  Currently, there
 *	is only a single option, "write", to write a CALMA stream
 *	file.
 *
 * ----------------------------------------------------------------------------
 */

#define CALMA_HELP	0
#define	CALMA_FLATTEN	1
#define	CALMA_LABELS	2
#define	CALMA_LOWER	3
#define	CALMA_NOFLATTEN	4
#define	CALMA_NOLABELS	5
#define	CALMA_NOLOWER	6
#define	CALMA_READ	7
#define	CALMA_WRITE	8

	/* ARGSUSED */
void CmdCalma(Layout *w, TxCommand *cmd)
{
    int option;
    char **msg; 
    char *name = NULL;
    CellDef *rootDef;
    char *gdsSuffix = Tcl_GetVar2(MnInterp,"CELL","gds_suffix",TCL_GLOBAL_ONLY); 

    static char *cmdCalmaOption[] =
    {	
	"help		print this help information",
	"flatten		output arrays as individual subuses (like in CIF)",
	"labels		cause labels to be output when writing GDS-II",
	"lower		allow both upper and lower case in labels",
	"noflatten		output arrays intact; don't flatten",
	"nolabels		labels won't be output with GDS-II",
	"nolower		convert all labels to upper case",
	"read file [cellName]	read in GDS-II format file \"file\".\n\
				If \"cellName\" given, readin only that cell.",
	"write file		output Calma GDS-II format to \"file\"\n\
			for the window's root cell",
	NULL
    };

    if (w == (Layout *) NULL)
    {
	MsgErrorF("Point to a window first\n");
	return;
    }
    rootDef = w->lay_rootUse->cu_def;


    if (cmd->tx_argc == 1)
    {
      /* if no args, print help message */
      option = Lookup("help",cmdCalmaOption); 
    }
    else
    {
      option = Lookup(cmd->tx_argv[1], cmdCalmaOption);
    }
    if (option < 0)
    {
	MsgErrorF("\"%s\" isn't a valid calma option.\n", cmd->tx_argv[1]);
	option = CALMA_HELP;
	cmd->tx_argc = 2;
    }

    switch (option)
    {
	case CALMA_HELP:
	    MsgInfoF("Calma commands have the form \":calma option\",");
	    MsgInfoF(" where option is one of:\n");
	    for (msg = &(cmdCalmaOption[0]); *msg != NULL; msg++)
	    {
		if (**msg == '*') continue;
		MsgInfoF("    %s\n", *msg);
	    }
	    MsgInfoF("If no option is given, a GDS-II file is\n");
	    MsgInfoF("    produced for the root cell.\n");
	    MsgInfoF("The current CIF output style (\"cif ostyle\") is used\n");
	    MsgInfoF("    to select the mask layers output by :calma write.\n");
	    MsgInfoF("The current CIF input style (\"cif istyle\") is used\n");
	    MsgInfoF("    to select the mask layers read by :calma read.\n");
	    return;

	case CALMA_LABELS:
	    if (cmd->tx_argc != 2)
	    {
		wrongNumArgs:
		MsgErrorF("Wrong number of arguments in \"calma\" command.");
		MsgErrorF("  Try \":calma help\" for help.\n");
		return;
	    }
	    GDSWriteLabels = TRUE;
	    MsgInfoF("Labels will be output in GDS-II files\n");
	    return;

	case CALMA_NOLABELS:
	    if (cmd->tx_argc != 2) goto wrongNumArgs;
	    GDSWriteLabels = FALSE;
	    MsgInfoF("Labels won't be output in GDS-II files\n");
	    return;

	case CALMA_FLATTEN:
	    if (cmd->tx_argc != 2) goto wrongNumArgs;
	    GDSWriteArrays = FALSE;
	    MsgInfoF("Each element of an array will be output individually\n");
	    MsgInfoF("in GDS-II files\n");
	    return;

	case CALMA_NOFLATTEN:
	    if (cmd->tx_argc != 2) goto wrongNumArgs;
	    GDSWriteArrays = TRUE;
	    MsgInfoF("Arrays will be output intact in GDS-II files\n");
	    return;

	case CALMA_LOWER:
	    MsgInfoF("Labels in GDS-II file will be output as upper and lower case\n");
	    GDSWriteMixedCaseLabels = TRUE;
	    return;

	case CALMA_NOLOWER:
	    MsgInfoF("Labels in GDS-II file will be converted to upper case\n");
	    GDSWriteMixedCaseLabels = FALSE;
	    return;

	case CALMA_WRITE:
	    if (cmd->tx_argc != 3) goto wrongNumArgs;
	    name = cmd->tx_argv[2];
	    goto outputCalma;

	case CALMA_READ:
	  MsgErrorF("':calma read' OBSOLETE, use gds_read instead.\n");
	  return;
    }

 outputCalma:

    {
      FILE *f;
      char fileName[BUFSIZ];

      /* open file */
      ASSERT(name,"CmdCalma");
      sprintf(fileName,"%s%s", name, gdsSuffix);
      f = fopen(fileName, "w");
      if(!f)
      {
	MsgErrorF("Cannot open %s to write Calma stream output\n", fileName);
	return;
      }

      /* write it */
      if (!GDSWriteFile(rootDef, f))
      {
	MsgErrorF("I/O error in writing file %s.\n", fileName);
	MsgErrorF("File may be incompletely written.\n");
      }

      fclose(f);
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdCheckPoint --
 *
 * Implement the "checkpoint" command.
 * Writes the EditCell out to the indicated file without changing the editcell
 * without clearing modified bits in cd-flags.
 *
 * Usage:
 *	checkpoint file
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes the cell out to specified file.
 *	Clears the modified bit in the cd_flags.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */
void CmdCheckPoint(Layout *w, TxCommand *cmd)
{
  CellDef *def = EditCellUse->cu_def;
  char *fileName = NULL;

  /* Parse */
  if (cmd->tx_argc != 2)
  {
    MsgErrorF("Usage: %s file\n", cmd->tx_argv[0]);
    return;
  }
  fileName = cmd->tx_argv[1];

  DBWriteCell(def, fileName, DBSuffix);
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdCif --
 *
 * Implement the "cif" command.
 *
 * Usage:
 *	cif option args
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	There are no side effects on the circuit.  Various options
 *	may produce cif files, read cif, or display cif information
 *	on the screen.
 *
 * ----------------------------------------------------------------------------
 */
#define ARRAY		0
#define HIER		1
#define HELP		2
#define ISTYLE		3
#define OSTYLE		4
#define SEE		5
#define STATS		6
	/* ARGSUSED */
void CmdCif(Layout *w, TxCommand *cmd)
{
    extern bool CIFDoAreaLabels;
    int option, yesno;
    char **msg, *namep;
    CellDef *rootDef;
    Rect box;
    FILE *f;
    bool wizardHelp;
    bool flatCif = FALSE;

    static char *cmdCifYesNo[] = { "no", "yes", 0 };
    static char *cmdCifOption[] =
    {	
	"*array layer		display CIF layer under box (array only)",
	"*hier layer		display CIF layer under box (hier only)",
	"help		print this help information",
	"istyle [style]	change style for reading CIF to style",
	"ostyle [style]	change style for writing CIF to style",
	"see layer		display CIF layer under box",
	"statistics		print out statistics for CIF generator",
	NULL
    };

    if (w == (Layout *) NULL)
    {
	MsgErrorF("Point to a window first\n");
	return;
    }
    rootDef = w->lay_rootUse->cu_def;

    option = Lookup(cmd->tx_argv[1], cmdCifOption);
    if (option < 0)
    {
	MsgErrorF("\"%s\" isn't a valid cif option.\n", cmd->tx_argv[1]);
	option = HELP;
	cmd->tx_argc = 2;
    }

    switch (option)
    {
	case ARRAY:
	    if (cmd->tx_argc != 3)
	    {
		wrongNumArgs:
		MsgErrorF("Wrong arguments in \"cif %s\" command:\n",
		    cmd->tx_argv[1]);
		MsgErrorF("    :cif %s\n", cmdCifOption[option]);
		MsgErrorF("Try \":cif help\" for more help.\n");
		return;
	    }
	    if (!ToolGetBox(&rootDef, &box))
	    {
		MsgErrorF("Use the box to select the area in");
		MsgErrorF(" which you want to see CIF.\n");
		return;
	    }
	    CIFSeeHierLayer(rootDef, &box, cmd->tx_argv[2], TRUE, FALSE);
	    return;
	
	case HIER:
	    if (cmd->tx_argc != 3) goto wrongNumArgs;
	    if (!ToolGetBox(&rootDef, &box))
	    {
		MsgErrorF("Use the box to select the area in");
		MsgErrorF(" which you want to see CIF.\n");
		return;
	    }
	    CIFSeeHierLayer(rootDef, &box, cmd->tx_argv[2], FALSE, TRUE);
	    return;

	case HELP:
	    if ((cmd->tx_argc == 3)
		    && (strcmp(cmd->tx_argv[2], "wizard") == 0))
		wizardHelp = TRUE;
	    else wizardHelp = FALSE;
	    MsgInfoF("CIF commands have the form \":cif option\",");
	    MsgInfoF(" where option is one of:\n");
	    for (msg = &(cmdCifOption[0]); *msg != NULL; msg++)
	    {
		if ((**msg == '*') && !wizardHelp) continue;
		MsgInfoF("    %s\n", *msg);
	    }
	    MsgInfoF("If no option is given, CIF is output for the");
	    MsgInfoF(" root cell.\n");
	    return;
	
	case ISTYLE:
	    if (cmd->tx_argc == 3)
		CIFSetReadStyle(cmd->tx_argv[2]);
	    else if (cmd->tx_argc == 2)
		CIFSetReadStyle((char *) NULL);
	    else goto wrongNumArgs;
	    return;
	
	case OSTYLE:
	    if (cmd->tx_argc == 3)
		CIFSetStyle(cmd->tx_argv[2]);
	    else if (cmd->tx_argc == 2)
		CIFSetStyle((char *) NULL);
	    else goto wrongNumArgs;
	    return;
	
	case SEE:
	    if (cmd->tx_argc != 3) goto wrongNumArgs;
	    if (!ToolGetBox(&rootDef, &box))
	    {
		MsgErrorF("Use the box to select the area in");
		MsgErrorF(" which you want to see CIF.\n");
		return;
	    }
	    CIFSeeLayer(rootDef, &box, cmd->tx_argv[2]);
	    return;
	
	case STATS:
	    CIFPrintStats();
	    return;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdClockwise --
 *
 * Implement the "clockwise" command.  Rotate the selection and the
 * box clockwise around the point.
 *
 * Usage:
 *	clockwise [degrees]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies the edit cell.
 *
 * ----------------------------------------------------------------------------
 */
    /* ARGSUSED */

void CmdClockwise(Layout *w, TxCommand *cmd)
{
    Transform trans, t2;
    int degrees;
    Rect rootBox,  bbox;
    CellDef *rootDef;

    if (cmd->tx_argc == 1)
	degrees = 90;
    else if (cmd->tx_argc == 2)
    {
	if (!StrIsInt(cmd->tx_argv[1])) goto badusage;
	degrees = atoi(cmd->tx_argv[1]);
    }
    else goto badusage;

    switch (degrees)
    {
	case 90:
	    t2 = Geo90Transform;
	    break;
	case 180:
	    t2 = Geo180Transform;
	    break;
	case 270:
	    t2 = Geo270Transform;
	    break;
	default:
	    MsgErrorF("Rotation angle must be 90, 180, or 270 degrees\n");
	    return;
    }


    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    /* To rotate the selection, first rotate it around the origin
     * then move it so its lower-left corner is at the same place
     * that it used to be.
     */
    {
      Rect *selBBox = DBBBoxCellDef(SelectDef);

      GeoTransRect(&t2, selBBox, &bbox);
      GeoTranslateTrans(&t2, 
			selBBox->r_xbot - bbox.r_xbot,
			selBBox->r_ybot - bbox.r_ybot, 
			&trans);

      SelectTransform(&trans, FALSE /* no dup instances */);
    }

    /* Rotate the box, if it exists and is in the same window as the
     * selection.
     */
    
    if (ToolGetBox(&rootDef, &rootBox) && (rootDef == SelectRootDef))
    {
	Rect newBox;

	GeoTransRect(&trans, &rootBox, &newBox);
	LaySetBox(rootDef, &newBox);
    }

    return;

    badusage:
    MsgErrorF("Usage: %s [degrees]\n", cmd->tx_argv[0]);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdCopy --
 *
 * Implement the "copy" command.
 *
 * Usage:
 *	copy [direction [amount]]
 *	copy to x y
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection is copied.
 *
 * ----------------------------------------------------------------------------
 */
 /*ARGSUSED*/

void CmdCopy(Layout *w, TxCommand *cmd)
{
    Transform t;
    Rect rootBox, newBox;
    Point rootPoint, editPoint;
    CellDef *rootDef;

    if (cmd->tx_argc > 4)
    {
	badUsage:
	MsgErrorF("Usage: %s [direction [amount]]\n", cmd->tx_argv[0]);
	MsgErrorF("   or: %s to x y\n", cmd->tx_argv[0]);
	return;
    }

    if (cmd->tx_argc > 1)
    {
	int indx, amount;
	int xdelta, ydelta;

	if (strcmp(cmd->tx_argv[1], "to") == 0)
	{
	    if (cmd->tx_argc != 4)
		goto badUsage;
	    if (!UnitsValidS(cmd->tx_argv[2]) || !UnitsValidS(cmd->tx_argv[3]))
		goto badUsage;
	    editPoint.p_x = UnitsS2I(cmd->tx_argv[2]);
	    editPoint.p_y = UnitsS2I(cmd->tx_argv[3]);
	    GeoTransPoint(&EditToRootTransform, &editPoint, &rootPoint);
	    goto copyToPoint;
	}

	indx = GeoNameToPos(cmd->tx_argv[1], TRUE, TRUE);
	if (indx < 0)
	    return;
	if (cmd->tx_argc == 3)
	{
	    if (!UnitsValidS(cmd->tx_argv[2])) goto badUsage;
	    amount = UnitsS2I(cmd->tx_argv[2]);
	}
	else amount = 1;

	switch (indx)
	{
	    case GEO_NORTH:
		xdelta = 0;
		ydelta = amount;
		break;
	    case GEO_SOUTH:
		xdelta = 0;
		ydelta = -amount;
		break;
	    case GEO_EAST:
		xdelta = amount;
		ydelta = 0;
		break;
	    case GEO_WEST:
		xdelta = -amount;
		ydelta = 0;
		break;
	    default:
		ASSERT(FALSE, "Bad direction in CmdCopy");
		return;
	}
	GeoTransTranslate(xdelta, ydelta, &GeoIdentityTransform, &t);

	/* check for read-only */
	if(!DBAccessModify(EditCellUse->cu_def)) return;

	/* Move the box by the same amount as the selection, if the
	 * box exists.
	 */

	if (ToolGetBox(&rootDef, &rootBox) && (rootDef == SelectRootDef))
	{
	    GeoTransRect(&t, &rootBox, &newBox);
	    LaySetBox(rootDef, &newBox);
	}
    }
    else
    {
	/* Use the displacement between the box lower-left corner and
	 * the point as the transform.
	 */
	
	Layout *window;

	window = LayPointGet(&rootPoint, (Rect *) NULL);
	if ((window == NULL) ||
	    (EditRootDef != window->lay_rootUse->cu_def))
	{
	    MsgErrorF("\"Copy\" uses the point as the place to put down a\n");
	    MsgErrorF("    copy of the selection, but the point doesn't\n");
	    MsgErrorF("    point to the edit cell.\n");
	    return;
	}

copyToPoint:
	if (!ToolGetBox(&rootDef, &rootBox) || (rootDef != SelectRootDef))
	{
	    MsgErrorF("\"Copy\" uses the box lower-left corner as a place\n");
	    MsgErrorF("    to pick up the selection for copying, but the box\n");
	    MsgErrorF("    isn't in a window containing the selection.\n");
	    return;
	}
	GeoTransTranslate(rootPoint.p_x - rootBox.r_xbot,
	    rootPoint.p_y - rootBox.r_ybot, &GeoIdentityTransform, &t);
	GeoTransRect(&t, &rootBox, &newBox);
	LaySetBox(rootDef, &newBox);
    }
    
    SelectCopy(&t,FALSE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdCorner --
 *
 * Implement the "corner" command.  Find all paint touching one side
 * of the box, and paint it around two edges of the box in an "L"
 * shape.
 *
 * Usage:
 *	corner firstDirection secondDirection [layers]
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The edit cell is modified.
 *
 * ----------------------------------------------------------------------------
 */

/* Data passed between CmdCorner and cmdCornerFunc: */

int cmdCornerDir1;			/* First direction each wire must
					 * be extended.
					 */
int cmdCornerDir2;			/* Second direction each wire must
					 * be extended.
					 */
Rect cmdCornerRootBox;			/* Root coords of box. */
struct cmdCornerArea *cmdCornerList;	/* List of areas to fill. */

	/*ARGSUSED*/
void
CmdCorner(Layout *w, TxCommand *cmd)
                 		/* Window in which command was invoked. */
                   	/* Describes the command that was invoked. */
{
    TileTypeBitMask maskBits;
    Rect editBox;
    SearchContext scx;
    extern int cmdCornerFunc(Tile *tile, TreeContext *cxp);
    bool hasErr = FALSE;

    if (cmd->tx_argc < 3 || cmd->tx_argc > 4)
    {
	MsgErrorF("Usage: %s direction1 direction2 [layers]\n", cmd->tx_argv[0]);
	return;
    }

    if ( w == (Layout *) NULL )
    {
	MsgErrorF("Point to a window\n");
	return;
    }

    /* Find and check validity of directions. */

    cmdCornerDir1 = GeoNameToPos(cmd->tx_argv[1], TRUE, TRUE);
    if (cmdCornerDir1 < 0)
	return;
    cmdCornerDir2 = GeoNameToPos(cmd->tx_argv[2], TRUE, TRUE);
    if (cmdCornerDir2 < 0)
	return;
    if ((cmdCornerDir1 == GEO_NORTH) || (cmdCornerDir1 == GEO_SOUTH))
    {
	if ((cmdCornerDir2 == GEO_NORTH) || (cmdCornerDir2 == GEO_SOUTH))
	{
	    MsgInfoF("Can't corner-fill %s and then %s.\n",
		    cmd->tx_argv[1], cmd->tx_argv[2]);
	    return;
	}
    }
    else
    {
	if ((cmdCornerDir2 == GEO_EAST) || (cmdCornerDir2 == GEO_WEST))
	{
	    MsgInfoF("Can't corner-fill %s and then %s.\n",
		    cmd->tx_argv[1], cmd->tx_argv[2]);
	    return;
	}
    }

    /* Figure out which layers to fill. */

    if (cmd->tx_argc < 4)
	maskBits = DBAllButSpaceAndDRCBits;
    else
    {
	if (!CmdParseLayers(cmd->tx_argv[3], &maskBits))
	    return;
    }

    /* Figure out which material to search for and invoke a search
     * procedure to find it.
     */

    if (!ToolGetEditBox(&editBox)) return;
    GeoTransRect(&EditToRootTransform, &editBox, &cmdCornerRootBox);
    scx.scx_area = cmdCornerRootBox;
    switch (cmdCornerDir1)
    {
	case GEO_NORTH:
	    scx.scx_area.r_ytop = scx.scx_area.r_ybot + 1;
	    scx.scx_area.r_ybot -= 1;
	    break;
	case GEO_SOUTH:
	    scx.scx_area.r_ybot = scx.scx_area.r_ytop - 1;
	    scx.scx_area.r_ytop += 1;
	    break;
	case GEO_EAST:
	    scx.scx_area.r_xtop = scx.scx_area.r_xbot + 1;
	    scx.scx_area.r_xbot -= 1;
	    break;
	case GEO_WEST:
	    scx.scx_area.r_xbot = scx.scx_area.r_xtop - 1;
	    scx.scx_area.r_xtop += 1;
	    break;
    }
    scx.scx_use = w->lay_rootUse;
    scx.scx_trans = GeoIdentityTransform;
    cmdCornerList = (struct cmdCornerArea *) NULL;

    (void) DBSearchPaint(&scx, &maskBits,
	    w->lay_bitmask,
	    cmdCornerFunc, (ClientData) &hasErr);
    if (hasErr)
    {
	MsgErrorF("There's not enough room in the box for all the wires.\n");
    }

    /* Now that we've got all the material, scan over the list
     * painting the material and freeing up the entries on the list.
     */
    while (cmdCornerList != NULL)
    {
	DBPaint(EditCellUse->cu_def, &cmdCornerList->cca_area,
		cmdCornerList->cca_type);
	FREE_TAG(cmdCornerList,"cmdCornerArea");
	cmdCornerList = cmdCornerList->cca_next;
    }

    SelectClear();

    /* process database changes */
    DBChangedArea(EditCellUse->cu_def, &editBox, &maskBits, 0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cmdCornerFunc --
 *
 * 	Search procedure called by DBSearchPaint from CmdCorner.  Called once
 *	for each tile that crosses the appropriate boundary of the box.
 *	Makes an L-shaped 90 degree turn to extend a wire out of an
 *	adjacent side.
 *
 * Results:
 *	Returns 0 to keep the search alive.
 *
 * Side effects:
 *	Adds paint tiles to the display list.  If there are tiles found
 *	that can't be cornered correctly, the clientData value is set
 *	to TRUE.
 *
 * ----------------------------------------------------------------------------
 */
int
cmdCornerFunc(Tile *tile, TreeContext *cxp)
               			/* Tile to fill with. */
                     		/* Describes state of search. */
{
    Rect r1, r2, r3;
    struct cmdCornerArea *cca;
    bool *errPtr = (bool *) cxp->tc_filter->tf_arg;

    /* Get the tile dimensions in root coordinates.  Clip to the box.
     */
    TiToRect(tile, &r1);
    GeoTransRect(&cxp->tc_scx->scx_trans, &r1, &r2);
    GeoClip(&r2, &cmdCornerRootBox);

    /* Generate r2 and r3, the first and second legs of the L-shaped
     * geometry to be painted for this tile.
     */

    r3 = r2;
    switch (cmdCornerDir1)
    {
	case GEO_NORTH:
	    if (cmdCornerDir2 == GEO_EAST)
	    {
		r2.r_ytop = r3.r_ytop = cmdCornerRootBox.r_ytop
			- (r2.r_xbot - cmdCornerRootBox.r_xbot);
		r3.r_xtop = cmdCornerRootBox.r_xtop;
	    }
	    else
	    {
		r2.r_ytop = r3.r_ytop = cmdCornerRootBox.r_ytop
			- (cmdCornerRootBox.r_xtop - r2.r_xtop);
		r3.r_xbot = cmdCornerRootBox.r_xbot;
	    }
	    r3.r_ybot = r3.r_ytop - (r2.r_xtop - r2.r_xbot);
	    if (r3.r_ybot < cmdCornerRootBox.r_ybot)
		*errPtr = TRUE;
	    break;

	case GEO_SOUTH:
	    if (cmdCornerDir2 == GEO_EAST)
	    {
		r2.r_ybot = r3.r_ybot = cmdCornerRootBox.r_ybot
			+ (r2.r_xbot - cmdCornerRootBox.r_xbot);
		r3.r_xtop = cmdCornerRootBox.r_xtop;
	    }
	    else
	    {
		r2.r_ybot = r3.r_ybot = cmdCornerRootBox.r_ybot
			+ (cmdCornerRootBox.r_xtop - r2.r_xtop);
		r3.r_xbot = cmdCornerRootBox.r_xbot;
	    }
	    r3.r_ytop = r3.r_ybot + (r2.r_xtop - r2.r_xbot);
	    if (r3.r_ytop > cmdCornerRootBox.r_ytop)
		*errPtr = TRUE;
	    break;

	case GEO_EAST:
	    if (cmdCornerDir2 == GEO_NORTH)
	    {
		r2.r_xtop = r3.r_xtop = cmdCornerRootBox.r_xtop
			- (r2.r_ybot - cmdCornerRootBox.r_ybot);
		r3.r_ytop = cmdCornerRootBox.r_ytop;
	    }
	    else
	    {
		r2.r_xtop = r3.r_xtop = cmdCornerRootBox.r_xtop
			- (cmdCornerRootBox.r_ytop - r2.r_ytop);
		r3.r_ybot = cmdCornerRootBox.r_ybot;
	    }
	    r3.r_xbot = r3.r_xtop - (r2.r_ytop - r2.r_ybot);
	    if (r3.r_xbot < cmdCornerRootBox.r_xbot)
		*errPtr = TRUE;
	    break;

	case GEO_WEST:
	    if (cmdCornerDir2 == GEO_NORTH)
	    {
		r2.r_xbot = r3.r_xbot = cmdCornerRootBox.r_xbot
			+ (r2.r_ybot - cmdCornerRootBox.r_ybot);
		r3.r_ytop = cmdCornerRootBox.r_ytop;
	    }
	    else
	    {
		r2.r_xbot = r3.r_xbot = cmdCornerRootBox.r_xbot
			+ (cmdCornerRootBox.r_ytop - r2.r_ytop);
		r3.r_ybot = cmdCornerRootBox.r_ybot;
	    }
	    r3.r_xtop = r2.r_xbot + (r2.r_ytop - r2.r_ybot);
	    if (r3.r_xtop > cmdCornerRootBox.r_xtop)
		*errPtr = TRUE;
	    break;
    }

    /* Clip the resulting geometry to the box, translate to edit cell
     * coords, and add to the paint list if non-NULL.
     */

    GeoClip(&r2, &cmdCornerRootBox);
    GeoTransRect(&RootToEditTransform, &r2, &r1);
    if (!GEO_RECTNULL(&r1))
    {
	/* Add this rectangle to the list. */
	MALLOC_TAG(struct cmdCornerArea *,
		   cca,
		   sizeof(struct cmdCornerArea),
		   "cmdCornerArea");

	cca->cca_area = r1;
	cca->cca_type = DBgetTileType(tile);
	cca->cca_next = cmdCornerList;
	cmdCornerList = cca;
    }

    GeoClip(&r3, &cmdCornerRootBox);
    GeoTransRect(&RootToEditTransform, &r3, &r1);
    if (!GEO_RECTNULL(&r1))
    {
	MALLOC_TAG(struct cmdCornerArea *,
		   cca,
		   sizeof(struct cmdCornerArea),
		   "cmdCornerArea");

	cca->cca_area = r1;
	cca->cca_type = DBgetTileType(tile);
	cca->cca_next = cmdCornerList;
	cmdCornerList = cca;
    }
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdDelete --
 *
 * Implement the "delete" command.
 *
 * Usage:
 *	delete
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The selection is deleted.
 *
 * ----------------------------------------------------------------------------
 */

    /* ARGSUSED */

void CmdDelete(Layout *w, TxCommand *cmd)
{
    if (cmd->tx_argc != 1) goto badusage;

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    SelectDelete("deleted");
    return;

    badusage:
    MsgErrorF("Usage: %s\n", cmd->tx_argv[0]);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CmdDrc --
 *
 * Implement the "drc" command.
 *
 * Usage:
 *	drc option
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Most options have no side effects.  The only major side
 *	effects are to turn continuous DRC on or off, or recheck an
 *	area of a cell.
 *
 * ----------------------------------------------------------------------------
 */

#define FLATCHECK	0
#define SHOWINT		1
#define CATCHUP		2
#define CHECK		3
#define COUNT		4
#define FIND		5
#define OFF		6
#define ON		7
#define PRINTRULES	8
#define RULESTATS	9
#define STATISTICS	10
#define WHY		11

	/* ARGSUSED */
void CmdDrc(Layout *w, TxCommand *cmd)
{
    FILE        * fp;
    int		  option, nth, result, radius;
    Rect	  rootArea, area;
    CellUse	* rootUse, *use;
    CellDef	* rootDef;
    Transform	  trans;
    Layout	*window;
    char 	**msg;
    bool	  wizardHelp;

    static char *cmdDrcOption[] =
    {	
	"*flatcheck",
	"*showint",
	"catchup",
	"check",
	"count",
	"find",
	"off",
	"on",
	"printrules",
	"rulestats",
	"statistics",
	"why",
	NULL
    };

    if (cmd->tx_argc < 2)
    {
	MsgErrorF("No option given in \":drc\" command.\n");
	MsgErrorF("Please consult 'Text Commands' under the 'Help' menu\n");
	return;
    }
    else
    {
	option = Lookup(cmd->tx_argv[1], cmdDrcOption);
	if (option < 0)
	{
	    MsgErrorF("%s isn't a valid drc option.\n", cmd->tx_argv[1]);
	    MsgErrorF("Please consult 'Text Commands' under the 'Help' menu\n");
	    return;
	}
	if ((cmd->tx_argc > 2) && (option != PRINTRULES) && (option != FIND)
	    && (option != SHOWINT))
	{
	    badusage:
	    MsgErrorF("Wrong arguments in \"drc %s\" command:\n",
		cmd->tx_argv[1]);
	    MsgErrorF("    :drc %s\n", cmdDrcOption[option]);
	    MsgErrorF("Please consult 'Text Commands' under the 'Help' menu\n");
	    return;
	}
    }
    switch (option)
    {
	case FLATCHECK:
	    window = ToolGetBoxWindow(&rootArea, (int *) NULL);
	    if (window == NULL) return;
	    rootUse = window->lay_rootUse;
	    DRCFlatCheck(rootUse, &rootArea);
	    break;
	
	case SHOWINT:
	    if (cmd->tx_argc != 3 || !UnitsValidS(cmd->tx_argv[2])) goto badusage;
	    radius = UnitsS2I(cmd->tx_argv[2]);
	    if (radius < 0)
	    {
		MsgInfoF("Radius must not be negative\n");
		return;
	    }
	    window = ToolGetBoxWindow(&rootArea, (int *) NULL);
	    if (window == NULL) return;
	    rootUse = window->lay_rootUse;
	    if (!DRCFindInteractions(rootUse->cu_def, 
				     &rootArea,
				     radius, 
				     &area, 
				     &DBAllButSpaceAndDRCBits,
				     DRCFI_DRC))

	    {
		MsgInfoF("No interactions in this area for that radius.\n");
		return;
	    }
	    LaySetBox(rootUse->cu_def, &area);
	    break;
	
	case CATCHUP:
	    DRCCatchUp();
	    break;

	case CHECK:
	    window = ToolGetBoxWindow(&rootArea, (int *) NULL);
	    if (window == NULL) return;
	    rootUse = window->lay_rootUse;
	    DRCCheck(rootUse, &rootArea);
	    break;
	
	case COUNT:
	    window = ToolGetBoxWindow(&rootArea, (int *) NULL);
	    if (window == NULL) return;
	    rootUse = window->lay_rootUse;
	    DRCCount(rootUse, &rootArea);
	    break;
	
	case FIND:
	    if (cmd->tx_argc > 2)
	    {
		if (cmd->tx_argc > 3) goto badusage;
		nth = atoi(cmd->tx_argv[2]);
	    }
	    else nth = 0;
	    use = CmdGetSelectedCell(&trans);
	    rootDef = SelectRootDef;
	    if (use == NULL)
	    {
		use = EditCellUse;
		rootDef = EditRootDef;
		trans = EditToRootTransform;
	    }
	    result = DRCFind(use->cu_def, &area, nth);
	    if (result != 0)
	    {
		GeoTransRect(&trans, &area, &rootArea);
		LaySetBox(rootDef, &rootArea);
		MsgInfoF("Error area #%d:\n", result);
		DRCWhy(use, &area);
	    }
	    else
	    {
		if (nth > 1) MsgInfoF("There aren't that many errors");
		else MsgInfoF("There are no errors");
		MsgInfoF(" in %s.\n", use->cu_def->cd_name);
	    }
	    break;
	
	case OFF:
	    DRCBackGround = FALSE;
	    break;
	
	case ON:
	    DRCBackGround = TRUE;
	    break;
	
	case PRINTRULES:
	    if (cmd->tx_argc > 3) goto badusage;
	    if (cmd->tx_argc < 3)
		fp = stdout;
	    else if ((fp = fopen (cmd->tx_argv[2],"w")) == (FILE *) NULL)
	    {
		MsgErrorF("Cannot write file %s\n", cmd->tx_argv[2]);
		return;
	    }
	    DRCPrintRulesTable (fp);
	    if (fp != stdout)
		(void) fclose(fp);
	    break;
	
	case RULESTATS:
	    DRCTechRuleStats();
	    break;
	
	case STATISTICS:
	    DRCPrintStats();
	    break;

	case WHY:
	    window = ToolGetBoxWindow(&rootArea, (int *) NULL);
	    if (window == NULL) return;
	    rootUse = window->lay_rootUse;
	    DRCWhy(rootUse, &rootArea);
	    break;
    }
    return;
}

/*
 * cmdDumpFunc --
 *
 * Search function used to locate positioning label.  It just computes
 * the lower-left corner of the label and aborts the search.
 *
 * Results:
 *	Always returns 1.
 *
 * Side effects:
 *	Sets *point to the lower-left corner of the label.
 */
    /* ARGSUSED */
static int
cmdDumpFunc(Rect *rect, char *name, Label *label, Point *point)
               			/* Root coordinates of the label. */
               			/* Label name (not used). */
                 		/* Pointer to label (not used). */
                 		/* Place to store label's lower-left. */
{
    *point = rect->r_ll;
    return 1;
}


/*
 * ----------------------------------------------------------------------------
 *
 * cmdDumpParseArgs --
 *
 * Parse args for :dump, read in child cell, compute transform
 * implied by reference points.
 *
 * Results:
 *      TRUE on success; FALSE if arguments were missing or
 *	incorrect, or if the cell couldn't be found.
 *
 * Side effects:
 *	Fills in *dummy so that dummy->cu_def points to the cell
 *	specified by name in cmd->tx_argv[] 
 *
 *	Also fills in
 *	*scx so scx_use is dummy, scx_trans is the desired transform
 *	from dummy->cu_def back to root coordinates, and scx_area
 *	is the bounding box of dummy->cu_def.  (Scx is set up
 *	directly for a call to SelectDump()).
 *
 * ----------------------------------------------------------------------------
 */
bool
cmdDumpParseArgs(int argc,
		        /* arg count */
		 char **argv,
                   	/* arg list */
		 Layout *w, 
               		/* Window in which command was invoked (UNUSED) */
		 CellUse *dummy, 
                   	/* Filled in to point to cell mentioned in command */
		 SearchContext *scx,
                       	/* Filled in with the transform from the child cell's
			 * def to ROOT coordinates, the bounding box of the
			 * child cell in child cell coordinates, and with
			 * scx_use = dummy, where dummy->cu_def is the child
			 * cell itself.
			 */
		 bool *dupOK,
		        /* filled in according to -dup_ok */ 
		 char **instPrefix,
		        /* set according to -instance_prefix */ 
		 char **labelPrefix)
		        /* set according to -label_prefix */ 
{
    char *cmdName;
    char *cellName;
    Point childPoint, editPoint, rootPoint;
    CellDef *def, *rootDef, *editDef;
    bool hasChild, hasRoot;
    Rect rootBox;
    char c;

    /* parse command name */
    cmdName = *argv;
    argc--; argv++;
    
    /* Parse command line switchs */
    *dupOK = FALSE;
    *instPrefix = NULL;
    *labelPrefix = NULL;
    while(argc>0 && **argv=='-')
    {
      int length = strlen(*argv);
      char c = (*argv)[1];

      if(c=='d' && strncmp(*argv,"-dup_ok",length)==0)
      {
	argc--; argv++;
	*dupOK = TRUE;
	continue;
      }

      if(c=='i' && strncmp(*argv,"-instance_prefix",length)==0)
      {
	argc--; argv++;
	if(argc<= 0) goto usage; 
	*instPrefix = *argv;
	argc--; argv++;
	continue;
      }

      if(c=='l' && strncmp(*argv,"-label_prefix",length)==0)
      {
	argc--; argv++;
	if(argc<= 0) goto usage; 
	*labelPrefix = *argv;
	argc--; argv++;
	continue;
      }

      /* unrecognized option */
      goto usage;
    } /* end while(argc>0 && **argv=='-')  */

    /* parse cell name */
    if(argc <= 0) goto usage;
    cellName = *argv;
    argc--; argv++;
    if (!DBCellNameCheck(cellName)) return (FALSE);

    /* Locate the cell specified by the cell name */

    def = DBCellLookDef(cellName);
    if (def == (CellDef *) NULL)
	def = DBCellNewDef(cellName, (char *) NULL);
    editDef = EditCellUse->cu_def;
    
    /*
     * The following line of code is a bit of a hack.  It's needed to
     * force DBReadCell to print an error message if it can't find the
     * cell.  Otherwise, if the cell wasn't found the last time it was
     * looked for then no new error message will be printed.
     */
    def->cd_flags &= ~CD_NOT_FOUND;
    if (!DBReadCell(def)) return (FALSE);
    DBCellUseNewTemp(def, dummy);
    dummy->cu_expandMask = -1;

    /*
     * Parse the remainder of the arguments to find out the reference
     * points in the child cell and the edit cell.  Use the defaults
     * of the lower-left corner of the child cell's bounding box, and
     * the lower-left corner of the box tool, if the respective reference
     * points weren't provided.  (Lower-left of the box tool is interpreted
     * in root coordinates).
     */
    hasChild = hasRoot = FALSE;
    while (argc > 0)
    {
	static char *kwdNames[] = { "child", "parent", 0 };
	Label *lab;
	int n;

	n = Lookup(argv[0], kwdNames);
	if (n < 0)
	{
	    MsgErrorF("Unrecognized parent/child keyword: \"%s\"\n", argv[0]);
	    goto usage;
	}
	if (argc < 2)
	{
	    MsgErrorF("Keyword must be followed by a reference point\n");
	    goto usage;
	}
	switch (n)
	{
	    case  0:	/* Child */
		if (UnitsValidS(argv[1]))
		{
		    childPoint.p_x = UnitsS2I(argv[1]);
		    if (argc < 3 || !UnitsValidS(argv[2]))
		    {
			MsgErrorF("Must provide two coordinates\n");
			goto usage;
		    }
		    childPoint.p_y = UnitsS2I(argv[2]);
		    argv += 3;
		    argc -= 3;
		}
		else
		{
		    char pathName[BUFSIZ];
		    childPoint = TiPlaneRect.r_ur;
		    if(!DBInstanceParsePath(argv[1],pathName)) goto usage; 
		    (void) DBLabelFindByPathName(dummy, 
					pathName, 
					cmdDumpFunc, 
					&childPoint,
					FALSE /* dynamic load enabled */ );
		    if (childPoint.p_x == TiPlaneRect.r_xtop &&
			    childPoint.p_y == TiPlaneRect.r_ytop)
		    {
			MsgErrorF("Couldn't find label \"%s\" in cell \"%s\".\n",
				argv[1], cellName);
			return FALSE;
		    }
		    argv += 2;
		    argc -= 2;
		}
		hasChild = TRUE;
		break;
	    case  1:	/* Parent */
		if (UnitsValidS(argv[1]))
		{
		    editPoint.p_x = UnitsS2I(argv[1]);
		    if (argc < 3 || !UnitsValidS(argv[2]))
		    {
			MsgErrorF("Must provide two coordinates\n");
			goto usage;
		    }
		    editPoint.p_y = UnitsS2I(argv[2]);
		    argv += 3;
		    argc -= 3;
		}
		else
		{
		    for (lab = editDef->cd_labels; lab; lab = lab->lab_next)
			if (strcmp(lab->lab_text, argv[1]) == 0)
			    break;

		    if (lab == NULL)
		    {
			MsgErrorF("Couldn't find label \"%s\" in edit cell.\n",
				argv[1]);
			return FALSE;
		    }
		    editPoint = lab->lab_rect.r_ll;
		    argv += 2;
		    argc -= 2;
		}
		GeoTransPoint(&EditToRootTransform, &editPoint, &rootPoint);
		hasRoot = TRUE;
		break;
	}
    }

    /*
     * Use the default values if explicit reference points weren't
     * provided.
     */
    if (!hasChild)
	childPoint = DBBBoxCellDef(def)->r_ll;
    if (!hasRoot)
    {
	if (!ToolGetBox(&rootDef, &rootBox) || (rootDef != EditRootDef))
	{
	    MsgErrorF("The box's lower-left corner must point to the place\n");
	    MsgErrorF("    in the edit cell where you'd like to put \"%s\".\n",
		      cmdName);
	    return FALSE;
	}
	rootPoint = rootBox.r_ll;
    }

    scx->scx_use = dummy;
    GeoTransTranslate(rootPoint.p_x - childPoint.p_x,
	    rootPoint.p_y - childPoint.p_y,
	    &GeoIdentityTransform, &scx->scx_trans);
    scx->scx_area = *DBBBoxCellDef(def);
    return TRUE;

usage:
    MsgErrorF(
	"Usage: %s [-dup_ok] [-instance_prefix str1] [-label_prefix str2]
 cellName [child refPointChild] [parent refPointParent]\n",
	cmdName);
    MsgErrorF("       where the refPoints are either a single label name\n");
    MsgErrorF("       or a pair of integer coordinates\n");
    fprintf(stderr,"DEBUG cmdDumpParseArgs exit usage\n");
    return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * CmdDump --
 *
 *	Implement the ":dump" command.
 *
 * Usage:
 *	dump cellName [child refPointChild] [parent refPointParent]
 *
 * where the refPoints are either a label name, e.g., SOCKET_A, or an x-y
 * pair of integers, e.g., 100 200.  The words "child" and "parent" are
 * keywords, and may be abbreviated.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Copies the contents of a given cell into the edit cell,
 *	so that refPointChild in the child cell (or the lower-left
 *	corner of its bounding box) ends up at location refPointParent
 *	in the edit cell (or the location of the box tool's lower-left).
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
void CmdDump(Layout *w, TxCommand *cmd)
                 			/* Window in which command was invoked. */
                   		/* Describes command arguments. */
{
    SearchContext scx;
    CellUse dummy;
    bool dupOK;
    bool flush;
    char *instPrefix;
    char *labelPrefix;

    if (!cmdDumpParseArgs(cmd->tx_argc,
			 cmd->tx_argv, 
			 w, 
			 &dummy, 
			 &scx, 
			 &dupOK,
			 &instPrefix,
			 &labelPrefix)) return;

    /* check for read-only */
    if(!DBAccessModify(EditCellUse->cu_def)) return;

    SelectDump(&scx,dupOK,instPrefix,labelPrefix);
}






