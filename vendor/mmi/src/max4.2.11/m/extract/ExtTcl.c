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
 * ExtTcl.c -- Tcl command interface to this module
 */

static char rcsid[] = "$Header$";

#include <tcl.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "layout.h"
#include "units.h"
#include "utils.h"
#include "undo.h"
#include "select.h"
#include "cif.h"
#include "extract.h"
#include "extractInt.h"


/*
 *--------------------------------------------------------------
 *
 * extTclCmdCapacitance --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define ext_capacitance_DESC "returns total capacitance of selection"

#define ext_capacitance_DOC "
Computes total capacitance of selection based on areas and perimeters.
Uses current extraction style.
"

static int
extTclCmdCapacitance(ClientData clientData, 
		    Tcl_Interp *interp, 
		    int argc, char **argv)
{
    CellDef *def;
    NodeRegion *nodeList;
    double totalCap = 0.0;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
	MsgErrorF("usage: %s\n",argv[0]);
	CMD_RETURN(interp);
    }

    if (!SelectDef)
    {
	MsgErrorF("Nothing selected!\n",argv[0]);
    }

    UndoDisable();

    ExtSetup();

    ExtResetTiles(SelectDef, extUnInit);  /* probably not needed */
    nodeList = extFindNodes(SelectDef, (Rect *) NULL);  

    /* sum caps */
    {
      register NodeRegion *reg;

      for (reg = nodeList; reg; reg = reg->nreg_next)
      {
        totalCap += reg->nreg_cap;
      }
    }

    /* output result */
    {
      char buf[100];
      sprintf(buf,"%g fF",totalCap/1000.0);
      Tcl_SetResult(interp, buf, TCL_VOLATILE);
    }

    /* Clean up */
    if (nodeList) ExtFreeLabRegions((LabRegion *) nodeList);
    ExtResetTiles(SelectDef, extUnInit);

    UndoEnable();

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * extTclCmdGeometry --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define ext_geometry_DESC "returns area and perimeter of selection for each resistance class"

#define ext_geometry_DOC "

Usage:  ext_geometry

(Uses current extraction style.)
"

static int
extTclCmdGeometry(ClientData clientData, 
		    Tcl_Interp *interp, 
		    int argc, char **argv)
{
    CellDef *def;
    NodeRegion *nodeList;
    int *perim;
    int *area;
    int i;
    int num = ExtCurStyle->exts_numResistClasses;

    CMD_BEGIN(interp);

    /* check arg count */
    if (argc != 1) 
    {
	MsgErrorF("usage: %s\n",argv[0]);
	CMD_RETURN(interp);
    }

    if (!SelectDef)
    {
	MsgErrorF("Nothing selected!\n",argv[0]);
    }
	
    UndoDisable();

    ExtSetup();

    ExtResetTiles(SelectDef, extUnInit);  /* probably not needed */
    nodeList = extFindNodes(SelectDef, (Rect *) NULL);  

    /* sum perimeters and areas */
    {
      NodeRegion *reg;

      MALLOC(int *, perim, sizeof(int)*num);
      MALLOC(int *, area, sizeof(int)*num);

      for(i=0; i<num; i++)
      {
	perim[i] = 0;
	area[i] = 0;
      }

      for (reg = nodeList; reg; reg = reg->nreg_next)
      {
	for(i=0; i<num; i++)
	{
	  perim[i] += reg->nreg_pa[i].pa_perim;
	  area[i] += reg->nreg_pa[i].pa_area;
	}
      }
    }

    /* output result */
    {
      char buf[100];
      for(i=0; i<num; i++) 
      {
	sprintf(buf,"%g um2  %g um\n",
		area[i]*CIFDBRes*CIFDBRes, perim[i]*CIFDBRes);
	Tcl_AppendResult(interp, buf, NULL);
      }
    }

    /* Clean up */
    FREE(perim);
    FREE(area);
    if (nodeList) ExtFreeLabRegions((LabRegion *) nodeList);
    ExtResetTiles(SelectDef, extUnInit);

    UndoEnable();

    CMD_RETURN(interp);
}


/*
 *--------------------------------------------------------------
 *
 * extTclCmdLayerParameters --
 *
 *
 * C Result:
 *	A standard Tcl result.

 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define ext_layer_parameters_DESC "returns extraction parameters for given layer (e.g. sheet resistance)"

#define ext_layer_parameters_DOC "

Usage: ext_layer_parameters layer

Returns:  resistance_class sheet_resistance

first resistance_class is 0.
Resistance is in milli-ohms / square.

(Values are for current extraction style.)
"

static int
extTclCmdLayerParameters(ClientData clientData, 
		    Tcl_Interp *interp, 
		    int argc, char **argv)
{
  TileType type;

  CMD_BEGIN(interp);

  /* check arg count */
  if (argc != 2) 
  {
    MsgErrorF("usage: %s layer\n",argv[0]);
    CMD_RETURN(interp);
  }

  /* parse layer */
  if ((type = DBTechNoisyNameType(argv[1])) < 0) CMD_RETURN(interp);

  ExtSetup();

  /* output result */
  {
    char buf[100];

    sprintf(buf,"%d %d\n",
	    ExtCurStyle->exts_typeToResistClass[type],
	    ExtCurStyle->exts_sheetResist[type]);
    
    Tcl_AppendResult(interp, buf, NULL);
  }

  CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * ExtTclInit --
 *
 * Initialize extraction tcl commands.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
ExtTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "ext_capacitance", extTclCmdCapacitance,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       ext_capacitance_DESC,
	       ext_capacitance_DOC);
   MnDocCreateCommand(interp, "ext_geometry", extTclCmdGeometry,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       ext_geometry_DESC,
	       ext_geometry_DOC);
   MnDocCreateCommand(interp, "ext_layer_parameters", extTclCmdLayerParameters,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       ext_layer_parameters_DESC,
	       ext_layer_parameters_DOC);

   MnDocLinkVar(interp, "EXT_STEP_SIZE", 
		(char *) &extStepSize, TCL_LINK_INT,
		"extractor processing step size in typical wire widths",
		"e.g. if 100, then interaction areas are broken down" 
		" into squares 100 typical wire widths on a side");
}




