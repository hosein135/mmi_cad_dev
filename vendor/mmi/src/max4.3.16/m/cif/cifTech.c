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



/* cifTech.c -
 *
 *	This module processes the portions of technology
 *	files pertaining to CIF, and builds the tables
 *	used by the CIF generator.
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
static char rcsid[] = "$Header: CIFtech.c,v 6.0 90/08/28 18:05:22 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "main.h"
#include "utils.h"
#include "message.h"
#include "memory.h"
#include "cifInt.h"
#include "gdsInt.h"
#include "cif.h"

/* The following statics are used to keep track of things between
 * calls to CIFTechLine.
 */
static CIFStyle *cifCurStyle;   /* Current CIF style being built. */
static CIFLayer *cifCurLayer;	/* Current layer whose spec. is being read. */
static CIFOp *cifCurOp;		/* Last geometric operation read in. */
static bool cifGotLabels;	/* TRUE means some labels have been assigned
				 * to the current layer.
				 */
static bool cifGotPolygons;	/* TRUE means some polygons have been assigned
				 * to the current layer.
				 */
static bool cifGotUnits;        /* TRUE means have parsed "units" or 
				 * "scalefactor" line for current style.
				 */

/* The following is a TileTypeBitMask array with only the CIF_SOLIDTYPE
 * bit set in it.
 */
TileTypeBitMask CIFSolidBits;
/*
 * ----------------------------------------------------------------------------
 * cifDimension --
 *
 * Convert string to int.
 *
 * If string is int (no '.'), it is in DB units.
 *
 * If string is not int (has  '.') its in microns,
 * converted to microns using scale factor for cifstyle.
 * ----------------------------------------------------------------------------
 */

static int cifDimension(char *s)
{
  int result;

  if(!strchr(s,'.'))
  {
    /* integer dimension (DB units) */
    char *tail;
    result = strtol(s, &tail, 10);
    if(*tail)
    {
      MnTechError("Bad cif dimension: '%s'", s);
      return 0;
    }
    return result;
  }
  else
  {
    /* floating point dimension (microns) */
    char *tail;
    double d;
    double res;  
    
    if(!cifGotUnits)
    {
      MnTechError("cif dimension in microns requires prior 'units' statement: '%s'", s);
      return 0;
    }
    res = cifCurStyle->cs_CIFPlaneRes;

    d = strtod(s, &tail);
    if(*tail)
    {
      MnTechError("Bad DRC dimension: '%s'", s);
      return 0;
    }

    result = ROUND(d/res);

    if(ABSDIFF(result*res,d) > UNIT_TOLERANCE)
    {
      MnTechError("cif dimension %f not on %g design grid, approximating as %g\n",
		  d, res, result*res);
    }
    return result;
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * cifTechNewStyle --
 *
 * 	This procedure creates a new CIF style at the end of
 *	the list of style and initializes it to completely
 *	null.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A new element is added to the end of CIFStyleList, and cifCurStyle
 *	is set to point to it.
 *
 * ----------------------------------------------------------------------------
 */

void
cifTechNewStyle(void)
{
    CIFStyle *p;
    int i;

    /* need scaleFactor or units spec before grows/shrinks
     * so we can parse dimensions.
     */
    cifGotUnits = FALSE;

    MALLOC_TAG(CIFStyle *,
	       cifCurStyle,
	       sizeof(CIFStyle),
	       "CIFStyle");

    if (CIFStyleList == NULL)
	CIFStyleList = cifCurStyle;
    else
    {
	for (p = CIFStyleList; p->cs_next != NULL; p = p->cs_next) /*loop*/;
	p->cs_next = cifCurStyle;
    }
    cifCurStyle->cs_name = NULL;
    cifCurStyle->cs_nLayers = 0;
    cifCurStyle->cs_DBRes = 0;
    cifCurStyle->cs_CIFPlaneRes = 0;
    cifCurStyle->cs_CIFRes = 0;
    cifCurStyle->cs_GDSRes = 0;
    cifCurStyle->cs_charSetRestrict = TRUE;
    cifCurStyle->cs_bBoxCalmaNum = -1;
    cifCurStyle->cs_bBoxCalmaType = -1;
    cifCurStyle->cs_iNamePropNum = -1;
    cifCurStyle->cs_iNameCalmaNum = -1;
    cifCurStyle->cs_iNameCalmaType = -1;
    cifCurStyle->cs_yankLayers = DBZeroTypeBits;
    cifCurStyle->cs_hierLayers = DBZeroTypeBits;
    cifCurStyle->cs_hierInteractions = FALSE;
    for (i=0;  i<TT_MAXTYPES;  i+=1)
	cifCurStyle->cs_labelLayer[i] = -1;
    for (i=0;  i<TT_MAXTYPES;  i+=1)
	cifCurStyle->cs_polygonLayer[i] = -1;
    for (i = 0; i < MAXCIFLAYERS; i++)
	cifCurStyle->cs_layers[i] = NULL;
    cifCurStyle->cs_next = NULL;
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifParseLayers --
 *
 * 	Takes a comma-separated list of layers and turns it into two
 *	masks, one of paint layers and one of previously-defined CIF
 *	layers.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The masks pointed to by the paintMask and cifMask parameters
 *	are modified.  If some of the layers are unknown, then an error
 *	message is printed.
 *
 * ----------------------------------------------------------------------------
 */

void
cifParseLayers(char *string, 
                 		/* List of layers. */
	       CIFStyle *style, 
                    		/* Gives CIF style for parsing string.*/
	       TileTypeBitMask *paintMask, 
                               	/* Place to store mask of paint layers.  If
				 * NULL, then only CIF layer names are
				 * considered.
				 */
	       TileTypeBitMask *cifMask, 
                             	/* Place to store mask of CIF layers.  If
				 * NULL, then only paint layer names are
				 * considered.
				 */
	       int spaceOK)
       	        		/* are space layers permissible in this cif
    				 *  layer?
				 */
{
    TileTypeBitMask curCifMask,curPaintMask;
    char curLayer[40], *p, *cp;
    TileType paintType;
    int i;

    if (paintMask != NULL) TTMaskZero(paintMask);
    if (cifMask != NULL) TTMaskZero(cifMask);

    while (*string != 0)
    {
	p = curLayer;
	while ((*string != ',') && (*string != 0))
	    *p++ = *string++;
	*p = 0;
	while (*string == ',') string += 1;

	/* See if this is a paint type. */

	if (paintMask != NULL)
	{
	    paintType = DBTechNameTypes(curLayer,&curPaintMask);
	    if (paintType >= 0) goto okpaint;
	}
	else paintType = -2;

okpaint:
	/* See if this is the name of another CIF layer.  Be
	 * careful not to let the current layer be used in
	 * generating itself.  Exact match is requred on CIF
	 * layer names, but the same name can appear multiple
	 * times in different styles.
	 */

	TTMaskZero(&curCifMask);
	if (cifMask != NULL)
	{
	    for (i = 0;  i < style->cs_nLayers; i++)
	    {
		if (style->cs_layers[i] == cifCurLayer) continue;
		if (strcmp(curLayer, style->cs_layers[i]->cl_name) == 0)
		{
		    TTMaskSetType(&curCifMask, i);
		}
	    }
	}

	/* Make sure that there's exactly one match among cif and
	 * paint layers together.
	 */
	
	if ((paintType == -1)
	    || ((paintType >= 0) && !TTMaskEqual(&curCifMask, &DBZeroTypeBits)))
	{
	    MnTechError("Ambiguous layer (type) \"%s\".\n", curLayer);
	    continue;
	}
	if (paintType >= 0)
	{
	    if (paintType == TT_SPACE && spaceOK ==0)
		MnTechError("\"Space\" layer not permitted in CIF rules.\n");
	    else
	    {
		 TTMaskSetMask(paintMask, &curPaintMask);
	    } 
	}
	else if (!TTMaskEqual(&curCifMask, &DBZeroTypeBits))
	{
	    TTMaskSetMask(cifMask, &curCifMask);
	}
	else MnTechError("Unrecognized layer (type) \"%s\".\n", curLayer);
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFTechInit --
 *
 * 	Called once at beginning of technology file read-in to
 *	initialize data structures.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Just clears out the layer data structures.
 *
 * ----------------------------------------------------------------------------
 */

Void
CIFTechInit(void)
{
    GDSTechInit();
    CIFStyleList = NULL;

    /* Create the TileTypeBitMask array with only the CIF_SOLIDTYPE bit set */
    TTMaskZero(&CIFSolidBits);
    TTMaskSetType(&CIFSolidBits, CIF_SOLIDTYPE);

    /* Create a default CIF style with no name.  This keeps
     * Max from crashing if the user enters an empty CIF section.
     */

    cifTechNewStyle();
    CIFCurStyle = CIFStyleList;
    cifCurOp = NULL;
    cifCurLayer = NULL;
    cifGotLabels = FALSE;
    cifGotPolygons = FALSE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFTechLine --
 *
 * 	This procedure is called once for each line in the "cif"
 *	section of the technology file.
 *
 * Results:
 *	TRUE normally, FALSE on error.
 *
 * Side effects:
 *	Sets up information in the tables of CIF layers, and
 *	prints error messages where there are problems.
 *
 * ----------------------------------------------------------------------------
 */

	/* ARGSUSED */
bool
CIFTechLine(char *sectionName, int argc, char **argv)
                      		/* The name of this section. */
             			/* Number of fields on line. */
                 		/* Values of fields. */
{
    TileTypeBitMask mask, tempMask, bloatLayers;
    int i, distance;
    CIFLayer *newLayer;
    CIFOp *newOp = NULL;
    char **bloatArg;
    int scaleFactor;
    int reducer;

    if (argc <= 0) return TRUE;

    /* See if we're starting a new CIF style.  If not, make
     * sure that the current (maybe default?) CIF style has
     * a name.
     */
    
    if (strcmp(argv[0], "style") == 0)
    {
	if (argc != 2) goto wrongNumArgs;

	/* If there's no name for the current CIF style, it
	 * means that it's the initial style, so give it this
	 * name.  Otherwise make a new CIF style.
	 */

	if (cifCurStyle->cs_name != NULL)
	    cifTechNewStyle();
	(void) StrDup(&cifCurStyle->cs_name, argv[1]);
	return TRUE;
    }
    else if (cifCurStyle->cs_name == NULL)
	(void) StrDup(&cifCurStyle->cs_name, "default");

    /*** SCALEFACTOR LINE ***/
    if (strcmp(argv[0], "scalefactor") == 0)
    {
      scaleFactor = 0;
      reducer = 0;

      if (cifGotUnits)
      {
	MnTechError("Redundant cif scalefactor statement.\n");
	goto errorReturn;
      }

      if (argc > 3)
      {
wrongNumArgs:
	MnTechError("Wrong number of arguments in cif %s statement\n"
		    "Do you have a space in a list of layers?\n\n",
		    argv[0]);
errorReturn:
	if (newOp != NULL) FREE_TAG(newOp, "CIFOp");
	return FALSE;
      }

      /* get scale factor */
      scaleFactor = atoi(argv[1]);
      if (scaleFactor <= 0)
      {
	scaleFactor = 0;
	MnTechError("Scalefactor must be positive integer.\n");
	goto errorReturn;
      }

      /* get reducer */
      if (argc == 2)
      {
	reducer = 1;
      }
      else
      {
	if (strcmp(argv[2], "calmaonly") == 0)
        {
	  reducer = 0;
	  goto setUnits;
	}
	reducer = atoi(argv[2]);
      }

      /* If we get here, not calmaOnly style, 
       * so error check scale for cif
       */
      if ((scaleFactor <= 0) || (scaleFactor & 1))
      {
	MnTechError("Scalefactor must be positive even integer.\n");
	goto errorReturn;
      }
      if (reducer <= 0)
      {
	MnTechError("Reducer must be positive integer.\n");
	goto errorReturn;
      }
      
      /* now use scaleFactor and reducer to set all the various
       * units (resolutions)
       */
setUnits:
      cifCurStyle->cs_DBRes = scaleFactor/100.0;
      cifCurStyle->cs_CIFPlaneRes = .01;
      cifCurStyle->cs_CIFRes = .01*reducer;
      cifCurStyle->cs_GDSRes = .001;

      cifGotUnits = TRUE;
      return TRUE;
    }

    /*** UNITS LINE ***/
    if (strcmp(argv[0], "units") == 0)
    {
      char *suffix;
      double res;

      if (cifGotUnits)
      {
	MnTechError("Redundant cif units statement.\n");
	goto errorReturn;
      }

      if (argc != 5)
      {
	MnTechError("Bad cif units statement, usage:\n"
		    "\tunits DBRes CPRes CIFRes GDSRes\n"
		    "where all resolutions are in microns\n\n");
	goto errorReturn;
      }

      cifCurStyle->cs_DBRes = res = strtod(argv[1],&suffix);
      if(*suffix!='\0'|| res <= 0)
      {
	MnTechError("bad DBRes (%s) on cif units statement.\n\n", 
		    argv[1]);
	goto errorReturn;
      }

      cifCurStyle->cs_CIFPlaneRes = res = strtod(argv[2],&suffix);
      if(*suffix!='\0'|| res <= 0)
      {
	MnTechError("bad CIFPlaneRes (%s) on cif units statement.\n\n", 
		    argv[2]);
	goto errorReturn;
      }

      /* zero value means don't allow cif output for this style */
      cifCurStyle->cs_CIFRes = res = strtod(argv[3],&suffix);
      if(*suffix!='\0'|| res < 0)
      {
	MnTechError("bad CIFRes (%s) on cif units statement.\n\n", 
		    argv[3]);
	goto errorReturn;
      }

      cifCurStyle->cs_GDSRes = res = strtod(argv[4],&suffix);
      if(*suffix!='\0'|| res <= 0)
      {
	MnTechError("bad GDSRes (%s) on cif units statement.\n\n", 
		    argv[3]);
	goto errorReturn;
      }

      /* TODO, additional error checking on units */

      cifGotUnits = TRUE;
      return TRUE;
    }

    if (strcmp(argv[0], "stepsize") == 0)
    {
      MnTechError("Warning:  cifoutput 'stepsize' ignored"
		  " (see tcl variable CIF_HIER_STEP_SIZE)\n");
      return TRUE;
    }

    if (strcmp(argv[0], "charset") == 0)
    {
	if (argc != 2) goto wrongNumArgs;
	if (strcmp(argv[1],"restricted") == 0) 
	{
	  cifCurStyle->cs_charSetRestrict = TRUE;
	}
	else if (strcmp(argv[1],"unrestricted") == 0) 
	{
	  cifCurStyle->cs_charSetRestrict = FALSE;
	}
	else 
	{
	  MnTechError("Invalid charset arg \"%s\".\n", argv[1]);
	  MnTechError("Valid charset args are \"restricted\" and \"unrestricted\"");
	}
	return TRUE;
    }

    /* instance name specification 
     *
     * If "iname <num> <type>:  we output instance names 
     * as text on the given GDS layer.
     *
     * if "iname propattr <num>" we output instance names
     * as the given property attribute of structure references.
     *
     * If no "iname" given, we do not output instance names.
     */
    if(strcmp(argv[0], "iname") == 0)
    {
      int num, type;

      if (argc != 3) goto wrongNumArgs;

      if (strcmp(argv[1], "propattr") == 0)
      {
	/* iname propattr <num> */
	
        num = atoi(argv[2]);

	cifCurStyle->cs_iNamePropNum = num;
      }
      else
      {
	/* iname <num> <type> */
	
	num = atoi(argv[1]);
	type = atoi(argv[2]);

	if (!CalmaIsValidLayer(num) || !CalmaIsValidLayer(type))
      	{	
	  MnTechError("Calma layer and type numbers must be 0 to %d.\n",
		      CALMA_LAYER_MAX);
	  return TRUE;
	}
	
	cifCurStyle->cs_iNameCalmaNum = num;
	cifCurStyle->cs_iNameCalmaType = type;
      }

      return TRUE;
    }

    /* bounding box layer specification 
     * (if none given bounding boxes are not output )
     */
    if (strcmp(argv[0], "bbox") == 0)
    {
      int num, type;

      if (argc != 3) goto wrongNumArgs;
      num = atoi(argv[1]);
      type = atoi(argv[2]);

      if(!CalmaIsValidLayer(num) || !CalmaIsValidLayer(type)) 
      {
	MnTechError("Calma layer and type numbers must be 0 to %d.\n",
		  CALMA_LAYER_MAX);
	return TRUE;
      }
	
      cifCurStyle->cs_bBoxCalmaNum = num;
      cifCurStyle->cs_bBoxCalmaType = type;

      return TRUE;
    }

    newLayer = NULL;
    if ((strcmp(argv[0], "templayer") == 0)
	|| (strcmp(argv[0], "layer") == 0))
    {

	if (cifCurStyle->cs_nLayers == MAXCIFLAYERS)
	{
	    cifCurLayer = NULL;
	    MnTechError("Can't handle more than %d CIF layers.\n", MAXCIFLAYERS);
	    MnTechError("Please contact Micro Magic to have this restriction eased.\n");
	    goto errorReturn;
	}
	if (argc != 2 && argc != 3)
	{
	    cifCurLayer = NULL;
	    goto wrongNumArgs;
	}

	MALLOC_TAG(CIFLayer *,
		   newLayer,
		   sizeof(CIFLayer),
		   "CIFLayer");

	cifCurStyle->cs_layers[cifCurStyle->cs_nLayers] = newLayer; 
	cifCurStyle->cs_nLayers += 1;
	if ((cifCurOp == NULL) && 
	    (cifCurLayer != NULL) && 
	    !cifGotLabels &&
	    !cifGotPolygons)
	{
	    MnTechError("Layer \"%s\" contains no material.\n",
		cifCurLayer->cl_name);
	}
	newLayer->cl_name = NULL;
	(void) StrDup(&newLayer->cl_name, argv[1]);
	newLayer->cl_ops = NULL;
	newLayer->clay_flags = 0;
	newLayer->cl_calmanum = newLayer->cl_calmatype = -1;
	for(i=0;i<=LAB_MAX_KIND;i++)
	{
	  newLayer->cl_labelGDSNum[i] = -1;
	  newLayer->cl_labelGDSType[i] = -1;
	}

	if (strcmp(argv[0], "templayer") == 0)
	    newLayer->clay_flags |= CIF_TEMP;
	cifCurLayer = newLayer;
	cifCurOp = NULL;
	cifGotLabels = FALSE;
	cifGotPolygons = FALSE;

	/* Handle a special case of a list of layer names on the layer
	 * line.  Turn them into an OR operation. 
	 */
	if (argc == 3)
	{
	    MALLOC_TAG(CIFOp *,
		       cifCurOp,
		       sizeof(CIFOp),
		       "CIFOp");
	    
	    cifCurOp->co_opcode = CIFOP_OR;
	    cifParseLayers(argv[2], cifCurStyle, &cifCurOp->co_paintMask,
		&cifCurOp->co_cifMask,FALSE);
	    cifCurOp->co_distance = 0;
	    cifCurOp->co_next = NULL;
	    for (i = 0; i < TT_MAXTYPES; i += 1)
		cifCurOp->co_bloats[i] = 0;
	    cifCurLayer->cl_ops = cifCurOp;
	}
	return TRUE;
    }

    if (strcmp(argv[0], "labels") == 0)
    {
	if (cifCurLayer == NULL)
	{
	    MnTechError("Must define layer before giving labels it holds.\n");
	    goto errorReturn;
	}
	if (cifCurLayer->clay_flags & CIF_TEMP)
	    MnTechError("Why are you attaching labels to a temporary layer?\n");
	if (argc != 2) goto wrongNumArgs;
	DBTechNoisyNameMask(argv[1], &mask);
	for (i=0; i<TT_MAXTYPES; i+=1)
	{
	    if (TTMaskHasType(&mask, i))
	        cifCurStyle->cs_labelLayer[i] = cifCurStyle->cs_nLayers-1;
	}
	cifGotLabels = TRUE;
	return TRUE;
    }


    if (strcmp(argv[0], "polygons") == 0)
    {
	if (cifCurLayer == NULL)
	{
	    MnTechError("Must define layer before giving polygons it holds.\n");
	    goto errorReturn;
	}
	if (cifCurLayer->clay_flags & CIF_TEMP)
	    MnTechError("Why are you attaching polygons to a temporary layer?\n");
	if (argc != 2) goto wrongNumArgs;
	DBTechNoisyNameMask(argv[1], &mask);
	for (i=0; i<TT_MAXTYPES; i+=1)
	{
	    if (TTMaskHasType(&mask, i))
	        cifCurStyle->cs_polygonLayer[i] = cifCurStyle->cs_nLayers-1;
	}
	cifGotPolygons = TRUE;
	return TRUE;
    }

    if (strcmp(argv[0], "calma") == 0)
    {
	if (cifCurLayer == NULL)
	{
	    MnTechError("Must define layers before giving their Calma types.\n");
	    goto errorReturn;
	}
	if (cifCurLayer->clay_flags & CIF_TEMP)
	    MnTechError("Why assign a Calma number to a temporary layer?\n");
	if (argc != 3) goto wrongNumArgs;
	if (!cifCheckCalmaNum(argv[1]) || !cifCheckCalmaNum(argv[2]))
	    MnTechError("Calma layer and type numbers must be 0 to %d.\n",
		CALMA_LAYER_MAX);
	cifCurLayer->cl_calmanum = atoi(argv[1]);
	cifCurLayer->cl_calmatype = atoi(argv[2]);
	return TRUE;
    }


    if (strcmp(argv[0], "port") == 0)
    {
      int kind;

      if (cifCurLayer == NULL)
      {
	MnTechError("Must define layers before assigning ports.\n");
	goto errorReturn;
      }

      if (cifCurLayer->clay_flags & CIF_TEMP)
      {
	MnTechError("Port GDS number definitions on temporary layer!?\n");
      }

      /* parse args */
      if (argc != 4) goto wrongNumArgs;
      if (!cifCheckCalmaNum(argv[1]) || !cifCheckCalmaNum(argv[2]))
      {
	MnTechError("GDSII layer and type numbers must be 0 to %d.\n",
		    CALMA_LAYER_MAX);
	goto errorReturn;
      }
      kind = DBLabelKindParse(argv[3]);
      if(kind<0) 
      {
	MnTechError("Bad kind on 'port' specification\n");
	goto errorReturn;
      }

      cifCurLayer->cl_labelGDSNum[kind] = atoi(argv[1]);
      cifCurLayer->cl_labelGDSType[kind] = atoi(argv[2]);
      return TRUE;
    }

    /* Anything below here is a geometric operation, so we can
     * do some set-up that is common to all the operations.
     */
    
    if (cifCurLayer == NULL)
    {
	MnTechError("Must define layer before specifying operation.\n");
	goto errorReturn;
    }

    MALLOC_TAG(CIFOp *,
	       newOp,
	       sizeof(CIFOp),
	       "CIFOp");

    TTMaskZero(&newOp->co_paintMask);
    TTMaskZero(&newOp->co_cifMask);
    newOp->co_opcode = 0;
    newOp->co_distance = 0;
    newOp->co_next = NULL;
    for (i = 0; i < TT_MAXTYPES; i += 1)
	newOp->co_bloats[i] = 0;

    if (strcmp(argv[0], "and") == 0)
	newOp->co_opcode = CIFOP_AND;
    else if (strcmp(argv[0], "and-not") == 0)
	newOp->co_opcode = CIFOP_ANDNOT;
    else if (strcmp(argv[0], "or") == 0)
	newOp->co_opcode = CIFOP_OR;
    else if (strcmp(argv[0], "grow") == 0)
	newOp->co_opcode = CIFOP_GROW;
    else if (strcmp(argv[0], "shrink") == 0)
	newOp->co_opcode = CIFOP_SHRINK;
    else if (strcmp(argv[0], "shrinkx") == 0)
	newOp->co_opcode = CIFOP_SHRINKX;
    else if (strcmp(argv[0], "shrinky") == 0)
	newOp->co_opcode = CIFOP_SHRINKY;
    else if (strcmp(argv[0], "bloat-or") == 0)
	newOp->co_opcode = CIFOP_BLOAT;
    else if (strcmp(argv[0], "bloat-max") == 0)
	newOp->co_opcode = CIFOP_BLOATMAX;
    else if (strcmp(argv[0], "bloat-min") == 0)
	newOp->co_opcode = CIFOP_BLOATMIN;
    else if (strcmp(argv[0], "squares") == 0)
	newOp->co_opcode = CIFOP_SQUARES;
    else
    {
	MnTechError("Unknown statement \"%s\".\n", argv[0]);
	goto errorReturn;
    }

    switch (newOp->co_opcode)
    {
	case CIFOP_AND:
	case CIFOP_ANDNOT:
	case CIFOP_OR:
	    if (argc != 2) goto wrongNumArgs;
	    cifParseLayers(argv[1], cifCurStyle, &newOp->co_paintMask,
		&newOp->co_cifMask,FALSE);
	    break;
	
	case CIFOP_GROW:
	case CIFOP_SHRINK:
        case CIFOP_SHRINKX:  
        case CIFOP_SHRINKY:  
	    if (argc != 2) goto wrongNumArgs;
	    newOp->co_distance = cifDimension(argv[1]);
	    if (newOp->co_distance <= 0)
	    {
		MnTechError("Grow/shrink distance must be greater than zero.\n");
		goto errorReturn;
	    }
	    break;
	
	case CIFOP_BLOAT:
	case CIFOP_BLOATMIN:
	case CIFOP_BLOATMAX:
	    if (argc < 4) goto wrongNumArgs;
	    cifParseLayers(argv[1], cifCurStyle, &newOp->co_paintMask,
		(TileTypeBitMask *) NULL,FALSE);
	    argc -= 2;
	    bloatArg = argv + 2;
	    bloatLayers = newOp->co_paintMask;
	    while (argc > 0)
	    {
		if (argc == 1) goto wrongNumArgs;
		if (strcmp(*bloatArg, "*") == 0)
		{
		    mask = DBAllTypeBits;
		    tempMask = DBZeroTypeBits;
		}
		else
		{
		    cifParseLayers(*bloatArg, cifCurStyle, &mask, &tempMask,TRUE);
		    TTMaskSetMask(&bloatLayers, &mask);
		}
		if (!TTMaskEqual(&tempMask, &DBZeroTypeBits))
		    MnTechError("Can't use templayers in bloat statement.\n");
		distance = cifDimension(bloatArg[1]);
		if ((distance < 0) && (newOp->co_opcode == CIFOP_BLOAT))
		{
		    MnTechError("Bloat-or distances must not be negative.\n");
		    distance = 0;
		}
		for (i = 0;  i < TT_MAXTYPES;  i += 1)
		{
		    if (TTMaskHasType(&mask, i))
			newOp->co_bloats[i] = distance;
		}
		argc -= 2;
		bloatArg += 2;
	    }

	    /* Don't do any bloating at boundaries between tiles of the
	     * types being bloated.  Otherwise a bloat could pass right
	     * through a skinny tile and out the other side.
	     */
	    
	    for (i = 0; i < TT_MAXTYPES; i += 1)
	    {
		if (TTMaskHasType(&newOp->co_paintMask, i))
		    newOp->co_bloats[i] = 0;
	    }

	    /* Make sure that all the layers specified in the statement
	     * fall in a single plane.
	     */
	
	    for (i = 0; i < PL_MAXPLANES; i++)
	    {
		tempMask = bloatLayers;
		TTMaskAndMask(&tempMask, &DBPlaneTypes[i]);
		if (TTMaskEqual(&tempMask, &bloatLayers))
		    goto bloatDone;
	    }
	    MnTechError("Not all bloat layers fall in the same plane.\n");
	    bloatDone: break;
	
	case CIFOP_SQUARES:
	    if (argc == 2)
	    /* squares <size> */
	    {
		i = cifDimension(argv[1]);
		newOp->co_bloats[0]= cifDimension(argv[1]);
		if ((i <= 0) || (i & 1))
		{
		    MnTechError("Squares must have positive even sizes.\n");
		    goto errorReturn;
		}
		newOp->co_bloats[0] = i/2;
		newOp->co_bloats[1] = i;
		newOp->co_bloats[2] = i;
	    }
	    else if (argc == 4 || argc == 5)
            /* squares <border> <size> <separation> [align] */
	    {
	        /* border */
		newOp->co_bloats[0] = cifDimension(argv[1]);
		if (newOp->co_bloats[0] < 0)
		{
		    MnTechError("Square border must not be negative.\n");
		    goto errorReturn;
		}
		newOp->co_bloats[1] = cifDimension(argv[2]);

		/* size */
		if (newOp->co_bloats[1] <= 0)
		{
		    MnTechError("Squares must have positive sizes.\n");
		    goto errorReturn;
		}
		newOp->co_bloats[2] = cifDimension(argv[3]);

		/* separation */
		if (newOp->co_bloats[2] <= 0)
		{
		    MnTechError("Square separation must be positive.\n");
		    goto errorReturn;
		}

		/* align */
		newOp->co_bloats[3] = 0;
		if (argc == 5)
		{
                    if (strcmp(argv[4], "align") == 0)
		    {
		        newOp->co_bloats[3] = 1;
		    }
		    else
		    {
		       MnTechError("Square unrecognized flag:  %s\n",
			 argv[4]);
		       goto errorReturn;
		    }
		}
	    }
	    else goto wrongNumArgs;
	    break;
    }

    /* Link the new CIFOp into the list. */

    if (cifCurOp == NULL)
    {
	cifCurLayer->cl_ops = newOp;
    }
    else
    {
	cifCurOp->co_next = newOp;
    }

    cifCurOp = newOp;

    return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifCheckCalmaNum --
 *
 * 	This local procedure checks whether its argument is the ASCII
 *	representation of a positive integer between 0 and CALMA_LAYER_MAX.
 *
 * Results:
 *	TRUE if the argument string is valid as described above, FALSE if not.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

bool
cifCheckCalmaNum(char *str)
{
    int n = atoi(str);

    if (n < 0 || n > CALMA_LAYER_MAX)
	return (FALSE);

    while (*str) {
	char ch = *str++;
	if (ch < '0' || ch > '9') 
	    return (FALSE);
    }

    return (TRUE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifComputeRadii --
 *
 * 	This local procedure computes and fills in the grow and
 *	shrink distances for a layer.  Before calling this procedure,
 *	the distances must have been computed for all temporary
 *	layers used by this layer.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Modifies cl_growDist and cl_shrinkDist in layer.
 *
 * ----------------------------------------------------------------------------
 */

void
cifComputeRadii(CIFLayer *layer, CIFStyle *des)
                    		/* Layer for which to compute distances. */
                  		/* CIF style (used to find temp layer
				 * distances.
				 */
{
    int i, grow, shrink, curGrow, curShrink;
    CIFOp *op;

    grow = shrink = 0;

    for (op = layer->cl_ops; op != NULL; op = op->co_next)
    {
	/* If CIF layers are used, switch to the max of current
	 * distances and those of the layers used.
	 */
	
	if (!TTMaskEqual(&op->co_cifMask, &DBZeroTypeBits))
	{
	    for (i=0; i < des->cs_nLayers; i++)
	    {
		if (TTMaskHasType(&op->co_cifMask, i))
		{
		    if (des->cs_layers[i]->cl_growDist > grow)
			grow = des->cs_layers[i]->cl_growDist;
		    if (des->cs_layers[i]->cl_shrinkDist > shrink)
			shrink = des->cs_layers[i]->cl_shrinkDist;
		}
	    }
	}

	/* Add in grows and shrinks at this step. */

	switch (op->co_opcode)
	{
	    case CIFOP_AND: break;

	    case CIFOP_ANDNOT: break;

	    case CIFOP_OR: break;

	    case CIFOP_GROW:
		grow += op->co_distance;
		break;
	    
	    case CIFOP_SHRINK:
		shrink += op->co_distance;
		break;
	    
	    /* For bloats use the largest distances (negative values are
	     * for shrinks).
	     */

	    case CIFOP_BLOAT:
		curGrow = curShrink = 0;
		for (i=0; i<TT_MAXTYPES; i++)
		{
		    if (op->co_bloats[i] > curGrow)
			curGrow = op->co_bloats[i];
		    else if ((-op->co_bloats[i]) > curShrink)
			curShrink = -op->co_bloats[i];
		}
		grow += curGrow;
		shrink += curShrink;
		break;
	    
	    case CIFOP_SQUARES: break;
	}
    }

    layer->cl_growDist = grow;
    layer->cl_shrinkDist = shrink;

    /* MsgInfoF("Radii for %s: grow %d, shrink %d.\n", layer->cl_name,
	grow, shrink);
     */
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFTechFinal --
 *
 * 	This procedure is invoked after all the lines of a technology
 *	file have been read.  It checks to make sure that the
 *	section ended at a consistent point, and computes the interaction
 *	distances for hierarchical CIF processing.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Error messages are output if there's incomplete stuff left.
 *	Interaction distances get computed for each CIF style
 *	in two steps.  First, for each layer the total grow and
 *	shrink distances are computed.	These are the maximum distances
 *	that edges may move because of grows and shrinks in creating
 *	the layer.  Second, the	radius for the style is computed.
 *	The radius is used in two ways: first to determine how far
 *	apart two subcells may be and still interact during CIF
 *	generation;  and second, to see how much material to yank in
 *	order to find all additional CIF resulting from interactions.
 *	Right now, a conservative approach is used:  use the greater
 *	of twice the largest grow distance or twice the largest shrink
 *	distance for both.  Twice the grow distance must be considered
 *	because two pieces of material may each grow towards the other
 *	and interact in the middle.  Twice the largest shrink distance
 *	is needed because subcells considered individually may each
 *	shrink away from a boundary where they touch;  the parent must
 *	fill in the gap.  To do this, it must include 2S additional
 *	material:  S is the size of the gap that must be filled, but
 *	its outside edge will shrink in by S, so we must start with
 *	2S material to have S left after the shrink.  Finally, one extra
 *	unit gets added because two pieces of material one radius apart
 *	can interact:  to find all this material we must look one unit
 *	farther out for anything overlapping (the search routines only
 *	look for overlapping material and ignore abutting material).
 *
 * ----------------------------------------------------------------------------
 */

Void
CIFTechFinal(void)
{
    CIFStyle *style;
    CIFOp *op;
    int i, maxGrow, maxShrink;
    bool reducerOK;

    /* if no cif styles, just return */
    if (CIFCurStyle->cs_name == NULL) return;

    /* officially register cif output style (exports units) */
    CIFSetStyle(CIFCurStyle->cs_name);

    if ((cifCurLayer != NULL) && 
	(cifCurOp == NULL) && 
	!cifGotLabels &&
	!cifGotPolygons)
    {
	MnTechError("Layer \"%s\" contains no material.\n",
	    cifCurLayer->cl_name);
    }
    cifCurLayer = NULL;

    /* error check */
    for (style = CIFStyleList; style != NULL; style = style->cs_next)
    {
	if (style->cs_DBRes <= 0)
	{
	    MnTechError("No (valid) scaleFactor or units for %s CIF.\n",
		style->cs_name);
	    exit(0);
	}

#ifdef HIDE
	TODO : check cifRes.
	/*
	 * Make sure that the reducer for the layer really does
	 * divide evenly into every distance specified for the layer.
	 * Only bother to check if the reducer is non-zero (if it's
	 * zero, this style will only be used for generating Calma).
	 */
	if (style->cs_reducer > 0)
	{
	    if ( ((int)style->cs_scaleFactor)%(2*style->cs_reducer) != 0)
	     {
		 MnTechError("2*reducer for %s CIF must divide %s.\n",
			 style->cs_name, "evenly into scalefactor");
	     }
	     reducerOK = TRUE;
	     for (i=0; i<style->cs_nLayers; i++)
	     {
		 for (op = style->cs_layers[i]->cl_ops; op != NULL;
		     op = op->co_next)
		 {
		     int j;
		     if ((op->co_distance%style->cs_reducer) != 0)
			 reducerOK = FALSE;
		     for (j=0; j<TT_MAXTYPES; j++)
			 if ((op->co_bloats[j] % style->cs_reducer) != 0)
			     reducerOK = FALSE;
		 }
	     }
	     if (!reducerOK)
		 MnTechError("Reducer for %s CIF doesn't divide distances evenly.\n",
		     style->cs_name);
	 }
 #endif HIDE

	 /* Compute grow and shrink distances for each layer,
	  * and remember the largest.
	  */
	 maxGrow = maxShrink = 0;
	 for (i=0; i<style->cs_nLayers; i++)
	 {
	     cifComputeRadii(style->cs_layers[i], style);
	     if (style->cs_layers[i]->cl_growDist > maxGrow)
		 maxGrow = style->cs_layers[i]->cl_growDist;
	     if (style->cs_layers[i]->cl_shrinkDist > maxShrink)
		 maxShrink = style->cs_layers[i]->cl_shrinkDist;
	 }
	 if (maxGrow > maxShrink)
	     style->cs_radius = 2*maxGrow;
	 else style->cs_radius = 2*maxShrink;
	 /* convert from CIFPlane coords to DBcoords and add 1 to avoid boundary
	  * problems.
	  */
	 style->cs_radius *= (style->cs_CIFPlaneRes/style->cs_DBRes);
	 style->cs_radius += 1;

	 /* MsgInfoF("Radius for %s CIF is %d.\n",
	     style->cs_name, style->cs_radius);
	  */

	 /* Go through the layers to see which ones depend on which
	  * other ones.  The purpose of this is so that we don't
	  * have to yank unnecessary layers in processing subcell
	  * interactions.  Also find out which layers involve only
	  * a single OR operation, and remember the others specially
	  * (they'll require fancy CIF geometry processing).
	  * 
	  * MHA 1/7/2000, cs_hierLayers seems to be computed incorrectly,
	  * but ignored everywhere:  all layers are hier extracted.
	  * Am not going to try and fix at this point, because we
	  * plan to obsolete this code anyway.
	  */

	 for (i = style->cs_nLayers-1; i >= 0; i -= 1)
	 {
	     TileTypeBitMask ourDepend, ourYank;
	     bool needThisLayer;
	     int j;

	     ourDepend = DBZeroTypeBits;
	     ourYank = DBZeroTypeBits;

	     /* This layer must be computed hierarchically if it is needed
	      * by some other layer that is computed hierarchically, or if
	      * it includes operations that require hierarchical processing.
	      */

	     needThisLayer = TTMaskHasType(&style->cs_hierLayers, i);

	     for (op = style->cs_layers[i]->cl_ops; op != NULL;
		     op = op->co_next)
	     {
		 TTMaskSetMask(&ourDepend, &op->co_cifMask);
		 TTMaskSetMask(&ourYank, &op->co_paintMask);
		 switch (op->co_opcode)
		 {
		     case CIFOP_BLOAT:
		     case CIFOP_BLOATMAX:
		     case CIFOP_BLOATMIN:
			 for (j = TT_SELECTBASE; j < TT_MAXTYPES; j += 1)
			 {
			     if (op->co_bloats[j] != op->co_bloats[TT_SPACE])
			     {
			       TTMaskSetType(&ourYank, j);
			     }
			 }
			 needThisLayer = TRUE;
			 break;

		     case CIFOP_AND:
		     case CIFOP_ANDNOT:
		     case CIFOP_SHRINK:
		     case CIFOP_SHRINKX:
		     case CIFOP_SHRINKY:
			 needThisLayer = TRUE;
			 break;
		 }
	     }

	     if (needThisLayer)
	     {
		 TTMaskSetMask(&style->cs_yankLayers, &ourYank);
		 TTMaskSetType(&style->cs_hierLayers, i);
		 TTMaskSetMask(&style->cs_hierLayers, &ourDepend);
	     }
	 }

	 /* see if we really need to process hierarchical interactions
	  * when writing gds (sets cs_hierInteractions accordingly).
	  */
	 {
	   TileTypeBitMask hier = DBZeroTypeBits;

	   for (i=0,style->cs_hierInteractions=FALSE;
		i<style->cs_nLayers && !style->cs_hierInteractions; 
		i++)
	   {
	     CIFLayer *layer = style->cs_layers[i];

	     for (op = layer->cl_ops; 
		  op != NULL;
		  op = op->co_next)
	     {
	       /* if op depends on hier layer, we got a hier layer */ 
	       if(TTMaskIntersect(&op->co_cifMask, &hier))
	       {
		 TTMaskSetType(&hier, i);
		 break;
	       }

	       /* if op is naughty, we got a hier layer */  
	       if(op->co_opcode != CIFOP_OR &&
		  op->co_opcode != CIFOP_GROW &&
		  op->co_opcode != CIFOP_SQUARES)
	       {
		 TTMaskSetType(&hier, i);
		 break;		   
	       }
	     }

	     /* if this layer is nontemp hier, we are done */
	     if(layer->cl_calmatype != -1 && TTMaskHasType(&hier, i))
	     {
	       style->cs_hierInteractions = TRUE;
	     }
	   }
	 }

	 /* Uncomment this code to print out information about which
	  * layers have to be processed hierarchically.

	 MsgInfoF("ostyle %s:\n", style->cs_name);
	 for (i = 0; i < DBNumUserLayers; i++)
	 {
	     if (TTMaskHasType(&style->cs_yankLayers, i))
		 MsgInfoF("\tWill have to yank %s.\n",
			  DBTypeLongName(i)); 
	 }
	 for (i = 0; i < CIFCurStyle->cs_nLayers; i++)
	 {
	     if (TTMaskHasType(&style->cs_hierLayers, i))
		 MsgInfoF("\tLayer %s must be processed hierarchically.\n",
			  style->cs_layers[i]->cl_name);
	 }


	 MsgInfoF("\thierInteractions = %d\n",
		  style->cs_hierInteractions);
	 */
    }
}








