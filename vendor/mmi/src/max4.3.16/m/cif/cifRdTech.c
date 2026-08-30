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



/* cifRdTech.c -
 *
 *	This module processes the portions of technology files that
 *	pertain to reading CIF files, and builds the tables used by
 *	the CIF-reading code.
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
static char rcsid[] = "$Header: CIFrdtech.c,v 6.1 90/09/03 14:33:24 stark Exp $";
#endif  not lint

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "main.h"
#include "message.h"
#include "utils.h"
#include "gdsInt.h"
#include "memory.h"
#ifdef SYSV
#include <string.h>
#endif
#include "cifInt.h"
#include "cifRead.h"

/* Pointer to a list of all the CIF-reading styles: */
CIFReadStyle *cifReadStyleList;

/* Names of all the CIF layer types used by any read style: */

int cifNReadLayers = 0;
char *(cifReadLayers[MAXCIFRLAYERS]);

/* Variables used to keep track of progress in reading the tech file: */

CIFReadStyle *cifCurReadStyle;		/* Current style being read. */
CIFReadStyleLayer *cifCurReadStyleLayer; /* Current layer being processed. */
CIFOp *cifCurReadOp;			/* Last geometric operation seen. */


/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadNameToType --
 *
 * 	This procedure finds the type (integer index) of a given
 *	layer name.
 *
 * Results:
 *	The return value is the type.  If we ran out of space in
 *	the CIF layer table, or if the layer wasn't recognized and
 *	it isn't OK to make a new layer, -1 gets returned.
 *
 * Side effects:
 *	If no layer exists by the given name and newOK is TRUE, a
 *	new layer is created.
 *
 * ----------------------------------------------------------------------------
 */

int
CIFReadNameToType(char *name, 
               		/* Name of a CIF layer. */
		  int newOK)
               		/* TRUE means OK to create a new layer if this
			 * name is one we haven't seen before.
			 */
{
    int i;
    static bool errorPrinted = FALSE;

    for (i=0; i < cifNReadLayers; i += 1)
    {
      /* If its not OK to add new layers skip them here. */
      if (newOK==FALSE && 
	  !TTMaskHasType(&cifCurReadStyle->crs_cifLayers, i)) continue;

      /* if wrong layer keep looking */
      if (strcmp(cifReadLayers[i], name) != 0) continue;
      
      TTMaskSetType(&cifCurReadStyle->crs_cifLayers, i);
      return i;
    }

    /* This name isn't in the table.  Return an error or make a new entry. */
    if (!newOK) return -1;

    if (cifNReadLayers == MAXCIFRLAYERS)
    {
	if (!errorPrinted)
	{
	    MsgErrorF("CIF read layer table ran out of space at %d layers.\n",
		    MAXCIFRLAYERS);
	    MsgErrorF("Contact Micro Magic to have the table size increased.\n");
	    errorPrinted = TRUE;
	}
	return -1;
    }

    (void) StrDup(&(cifReadLayers[cifNReadLayers]), name);
    TTMaskSetType(&cifCurReadStyle->crs_cifLayers, cifNReadLayers);
    cifNReadLayers += 1;
    return cifNReadLayers-1;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFCalmaLayerToCifLayer --
 *
 * Find the CIF number of the layer matching the supplied Calma
 * layer number and datatype.
 *
 * Results:
 *	Returns the CIF number of the above layer, or -1 if it
 *	can't be found.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

int
CIFCalmaLayerToCifLayer(int layer,             
			   /* GDS layer number */
			int datatype,          
			    /* GDS datatype */
			CIFReadStyle *calmaStyle)
{
    CalmaLayerType clt;
    HashEntry *he;

    clt.clt_layer = layer;
    clt.clt_type = datatype;
    if (he = HashLookOnly(&(calmaStyle->cifCalmaToCif), (char *) &clt))
      return ((int) HashGetValue(he));

    /* Try wildcarding the datatype */
    clt.clt_type = -1;
    if (he = HashLookOnly(&(calmaStyle->cifCalmaToCif), (char *) &clt))
      return ((int) HashGetValue(he));

    /* Try wildcarding the layer */
    clt.clt_layer = -1;
    clt.clt_type = datatype;
    if (he = HashLookOnly(&(calmaStyle->cifCalmaToCif), (char *) &clt))
      return ((int) HashGetValue(he));

    /* Try wildcarding them both, for a default value */
    clt.clt_layer = -1;
    clt.clt_type = -1;
    if (he = HashLookOnly(&(calmaStyle->cifCalmaToCif), (char *) &clt))
      return ((int) HashGetValue(he));

    /* No luck */
    return (-1);
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFParseReadLayers --
 *
 * 	Given a comma-separated list of CIF layer names, builds a
 *	bit mask of all those layer names.
 *
 * Results:
 *	Number of layers in list.
 *
 * Side effects:
 *	Modifies the parameter pointed to by mask so that it contains
 *	a mask of all the CIF layers indicated.  If any of the CIF
 *	layers didn't exist, new ones are created.  If we run out
 *	of CIF layers, an error message is output.
 *
 * ----------------------------------------------------------------------------
 */

int
CIFParseReadLayers(char *string, 
                 		/* Comma-separated list of CIF layers. */
		   TileTypeBitMask *mask)
                          	/* Where to store bit mask. */
{
    int i;
    char *p;
    int num;

    TTMaskZero(mask);
    num=0;

    /* Break the string up into the chunks between commas. */

    while (*string != 0)
    {
	p = strchr(string, ',');
	if (p != NULL)
	    *p = 0;
	
	i = CIFReadNameToType(string, TRUE);
	if (i >= 0)
	{
	  TTMaskSetType(mask, i);
	  num++;
	}

	if (p == NULL) break;
	*p = ',';
	for (string = p; *string == ','; string += 1) /* do nothing */;
    }

    return num;
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifNewReadStyle --
 *
 * 	This procedure creates a new CIF read style at the end of
 *	the list of styles and initializes it to completely null.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A new element is added to the end of cifReadStyleList, and
 *	cifCurReadStyle is set to point to it.
 *
 * ----------------------------------------------------------------------------
 */

void
cifNewReadStyle(char *name)
               			/* Name of new style. */
{
    CIFReadStyle *p;
    int i;

    MALLOC_TAG(CIFReadStyle *,
	       cifCurReadStyle,
	       sizeof(CIFReadStyle),
	       "CIFReadStyle");

    if (cifReadStyleList == NULL)
	cifReadStyleList = cifCurReadStyle;
    else
    {
	for (p = cifReadStyleList; p->crs_next != NULL; p = p->crs_next)
	    /* Just loop. */;
	p->crs_next = cifCurReadStyle;
    }
    cifCurReadStyle->crs_name = NULL;
    (void) StrDup(&cifCurReadStyle->crs_name, name);
    cifCurReadStyle->crs_cifLayers = DBZeroTypeBits;
    cifCurReadStyle->crs_nLayers = 0;
    cifCurReadStyle->crs_scaleFactor = 0;
    cifCurReadStyle->crs_iNamePropNum = -1;
    cifCurReadStyle->crs_iNameCalmaNum = -1;
    cifCurReadStyle->crs_iNameCalmaType = -1;
    cifCurReadStyle->crs_bBoxCalmaNum = -1;
    cifCurReadStyle->crs_bBoxCalmaType = -1;

    HashInit(&(cifCurReadStyle->cifCalmaToCif), 
	     64,       /* initial # of buckets in hash table */
	     sizeof (CalmaLayerType) / sizeof (unsigned));


    HashInit(&(cifCurReadStyle->crs_GDSToPort), 
	     64,       /* initial # of buckets in hash table */
	     sizeof (CalmaLayerType) / sizeof (unsigned));

    for (i=0; i<MAXCRSLAYERS; i+=1)
    {
      cifCurReadStyle->crs_layers[i] = NULL;
    }
    for (i=0; i<MAXCIFRLAYERS; i+=1)
    {
	cifCurReadStyle->crs_labelLayer[i] = TT_SPACE;
    }
    cifCurReadStyle->crs_next = NULL;
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifParseCalmaNums --
 *
 * Parse a comma-separated list of Calma numbers.  Each number in
 * the list must be between 0 and CALMA_LAYER_MAX, or an asterisk
 * "*" (stored as -1).  
 *
 * Results:
 *	A newly malloced linked list of numbers, NULL list on error
 *
 * Side effects:
 *	Newly malloced list elements.
 *
 * ----------------------------------------------------------------------------
 */
typedef struct intList
{
    int il_num;
    struct intList *il_next;
} IntList;

static IntList *
cifParseCalmaNums(register char *s) /* String to parse */
{
  IntList *iList = NULL;
  
  while(*s)
  {
    int num;

    /* parse number */
    if (*s == '*') 
    {
      /* encode wild card as -1 */
      num = -1;
    }
    else
    {
      num = atoi(s);
      if (num < 0 || num > CALMA_LAYER_MAX)
      {
	MnTechError("calma layer and type numbers must be 0 to %d.\n",
		    CALMA_LAYER_MAX);
	goto error;
      }
    }
    
    /* add number to list */
    {
      IntList *new;
	
      MALLOC(IntList *, new, sizeof(IntList));
      new->il_num = num;
      new->il_next = iList;
      iList = new;
    }


    /* skip number just parsed */
    while (*s && *s != ',')
    {
      if (*s != '*' && !isdigit(*s))
      {
	MnTechError("Calma layer/type numbers must be numeric or '*'\n");
	goto error;
      }
      s++;
    }

    /* skip comma separator */
    if (*s && *s == ',') s++;
  } /* while */

  return iList;

 error:
  while(iList)
  {
    IntList *next;
    next = iList->il_next;
    FREE(iList);
    iList = next;
  }
  return NULL;      
}


/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadTechInit --
 *
 * 	Called once at the beginning of technology file read-in to
 *	initialize data structures.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Clears out the layer data structure.
 *
 * ----------------------------------------------------------------------------
 */

Void
CIFReadTechInit(void)
{
    cifReadStyleList = NULL;
    cifNReadLayers = 0;
    cifCurReadStyle = NULL;
    cifCurReadStyleLayer = NULL;
    cifCurReadOp = NULL;
}

/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadTechLine --
 *
 * 	This procedure is called once by the tech module for each line
 *	in the "cifinput" section of the technology file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets up information in the tables used to read CIF, and prints
 *	error messages if problems arise.
 *
 * ----------------------------------------------------------------------------
 */
	/* ARGSUSED */
bool
CIFReadTechLine(char *sectionName, int argc, char **argv)
                      		/* Name of this section ("cifinput"). */
             			/* Number of fields on line. */
                 		/* Values of fields. */
{
    CIFOp *newOp = NULL;
    HashEntry *he;
    CalmaLayerType clt;
    int l, t;

    if (argc <= 0) return TRUE;

    /* See if we're starting a new style.  If so, create it.  If not,
     * make sure there's already a style around, and create one if
     * there isn't.
     */
    
    if (strcmp(argv[0], "style") == 0)
    {
	if (argc != 2)
	{
	    wrongNumArgs:
	    MnTechError("Wrong number of arguments in %s statement.\n",
		    argv[0]);
	    errorReturn:
	    if (newOp != NULL) FREE_TAG(newOp, "CIFOp");
	    return TRUE;
	}
	cifNewReadStyle(argv[1]);
	return TRUE;
    }
    
    if (cifCurReadStyle == NULL)
	cifNewReadStyle("unnamed");
    
    /* Process scalefactor lines next. */

    if (strcmp(argv[0], "scalefactor") == 0)
    {
	if (argc != 2) goto wrongNumArgs;
	cifCurReadStyle->crs_scaleFactor = atoi(argv[1]);
	if (cifCurReadStyle->crs_scaleFactor <= 0)
	{
	    cifCurReadStyle->crs_scaleFactor = 0;
	    MnTechError("Scalefactor must be positive.\n");
	    goto errorReturn;
	}
	return TRUE;
    }

    /* Process layer lines next. */

    if (strcmp(argv[0], "layer") == 0)
    {
	TileType type;

	cifCurReadStyleLayer = NULL;
	cifCurReadOp = NULL;
	if (cifCurReadStyle->crs_nLayers == MAXCRSLAYERS)
	{
	    MnTechError("Can't handle more than %d layers per style.\n",
		    MAXCRSLAYERS);
	    MnTechError("Contact Micro Magic to have the table size increased.\n");
	    goto errorReturn;
	}
        if ((argc != 2) && (argc != 3)) goto wrongNumArgs;
	type = DBTechNoisyNameType(argv[1]);
	if (type < 0) goto errorReturn;

	MALLOC(CIFReadStyleLayer *,
	       cifCurReadStyleLayer,
	       sizeof(CIFReadStyleLayer));

	cifCurReadStyle->crs_layers[cifCurReadStyle->crs_nLayers]
		= cifCurReadStyleLayer;
	cifCurReadStyle->crs_nLayers += 1;
	cifCurReadStyleLayer->crl_magicType = type;
	cifCurReadStyleLayer->crl_ops = NULL;

	/* If list of layer names given, turn them into an OR operation. */
	if (argc == 3)
	{
	  MALLOC_TAG(CIFOp *,
		     cifCurReadOp,
		     sizeof(CIFOp),
		     "CIFOp");

	  cifCurReadOp->co_opcode = CIFOP_OR;
	  CIFParseReadLayers(argv[2], &cifCurReadOp->co_cifMask);
	  TTMaskZero(&cifCurReadOp->co_paintMask);
	  cifCurReadOp->co_next = NULL;
	  cifCurReadStyleLayer->crl_ops = cifCurReadOp;
	}
	return TRUE;
    }

    /* Process mapping between CIF layers and calma layers/types */
    if (strcmp(argv[0], "calma") == 0)
    {
	int cifnum;
	IntList *layers, *layer;
	IntList *types, *type;

	if (argc != 4) goto wrongNumArgs;
	cifnum = CIFReadNameToType(argv[1], FALSE);
	if (cifnum < 0)
	{
	    MnTechError("Unrecognized CIF layer: \"%s\"\n", argv[1]);
	    return TRUE;
	}

	/* parse layer and type lists */
	layers = cifParseCalmaNums(argv[2]);
	types = cifParseCalmaNums(argv[3]);
	if (!layers || !types) return (TRUE);

	/* add each layer/type combination to CalmaToCif table */
	for (layer= layers; layer; layer=layer->il_next)
	{
	    for (type = types; type; type=type->il_next)
	      {
		clt.clt_layer = layer->il_num;
		clt.clt_type = type->il_num;
		he = HashFind(&(cifCurReadStyle->cifCalmaToCif),
		  (char *) &clt);
		HashSetValue(he, (ClientData) cifnum);
	    }
	}

	/* free number lists */
	while(layers) 
	{
	  layer = layers;
	  layers = layers->il_next;
	  FREE(layer);
	}
	while(types) 
	{
	  type = types;
	  types = types->il_next;
	  FREE(type);
	}

	return TRUE;
    }


    /* Associate label kind (e.g. inout) with gds num/types */
    if (strcmp(argv[0], "port") == 0)
    {
      int kind;
      IntList *layers, *layer;
      IntList *types, *type;

      if (argc != 4) goto wrongNumArgs;
      kind = DBLabelKindParse(argv[1]);
      if (kind < 0)
      {
	MnTechError("Unrecognized label kind on 'port' statement: \"%s\"\n", 
		    argv[1]);
	return TRUE;
      }

      /* parse layer and type lists */
      layers = cifParseCalmaNums(argv[2]);
      types = cifParseCalmaNums(argv[3]);
      if (!layers || !types) return (TRUE);

      /* add each layer/type combination to port (label kind) hash table */
      for (layer= layers; layer; layer=layer->il_next)
      {
	for (type = types; type; type=type->il_next)
	{
	  clt.clt_layer = layer->il_num;
	  clt.clt_type = type->il_num;
	  he = HashFind(&(cifCurReadStyle->crs_GDSToPort), (char *) &clt);
	  HashSetValue(he, (ClientData) kind);
	}
      }

      /* free number lists */
      while(layers) 
      {
	layer = layers;
	layers = layers->il_next;
	FREE(layer);
      }

      while(types) 
      {
	type = types;
	types = types->il_next;
	FREE(type);
      }

      return TRUE;
    }

    /* instance name specification 
     *
     * If "iname <num> <type>:  we attempt to take instance names 
     * from text on this layer.
     *
     * if "iname propattr <num>" we attempt to take instance names
     * from the given property attribute of structure references.
     *
     * If no "iname" given, instance names are NOT preserved:  unique
     * names are made up.
     */
    if (strcmp(argv[0], "iname") == 0)
    {
      int num, type;

      if (argc != 3) goto wrongNumArgs;

      if (strcmp(argv[1], "propattr") == 0)
      {
	/* iname propattr <num> */
	
        num = atoi(argv[2]);

	cifCurReadStyle->crs_iNamePropNum = num;
      }
      else
      {
	/* iname <num> <type> */
	
	num = atoi(argv[1]);
	type = atoi(argv[2]);

	if (!CalmaIsValidLayer(num) || !CalmaIsValidLayer(type))
      	{	
	  MnTechError("GDSII layer and type numbers must be 0 to %d.\n",
		      CALMA_LAYER_MAX);
	  return TRUE;
	}
	
	cifCurReadStyle->crs_iNameCalmaNum = num;
	cifCurReadStyle->crs_iNameCalmaType = type;
      }

      return TRUE;
    }

    /* instance bbox layer
     *
     * If "bbox <num> <type>:  we take initial instance bounding boxes
     * from text on this layer.
     *
     * If no "bbox" layer given, instance bboxes are taken from
     * the def for the instance.
     */
    if (strcmp(argv[0], "bbox") == 0)
    {
      int num, type;

      if (argc != 3) goto wrongNumArgs;

      num = atoi(argv[1]);
      type = atoi(argv[2]);

      if (!CalmaIsValidLayer(num) || !CalmaIsValidLayer(type))
      {	
	MnTechError("GDSII layer and type numbers must be 0 to %d.\n",
		    CALMA_LAYER_MAX);
	  return TRUE;
      }
	
      cifCurReadStyle->crs_bBoxCalmaNum = num;
      cifCurReadStyle->crs_bBoxCalmaType = type;

      return TRUE;
    }

    /* Figure out which Max layer should get labels from which
     * CIF layers.
     */
    
    if (strcmp(argv[0], "labels") == 0)
    {
	TileTypeBitMask mask;
	int i;

	if (cifCurReadStyleLayer == NULL)
	{
	    MnTechError("Must define layer before giving labels it holds.\n");
	    goto errorReturn;
	}
	if (argc != 2) goto wrongNumArgs;
	CIFParseReadLayers(argv[1], &mask);
	for (i=0; i<MAXCIFRLAYERS; i+=1)
	{
	    if (TTMaskHasType(&mask,i))
		cifCurReadStyle->crs_labelLayer[i]
			= cifCurReadStyleLayer->crl_magicType;
	}
	return TRUE;
    }

    /* Parse "ignore" lines:  look up the layers to enter them in
     * the table of known layers, but don't do anything else.  This
     * will cause the layers to be ignored when encountered in
     * cells.
     */
    
    if (strcmp(argv[0], "ignore") == 0)
    {
	TileTypeBitMask mask;
	int		i;

	if (argc != 2) goto wrongNumArgs;

        /* look up marks arg layers as known cif layers */
	CIFParseReadLayers(argv[1], &mask); 
	/* trash the value in crs_labelLayer so that any labels on this
	   layer get junked, also. dcs 4/11/90
        */
	for (i=0; i < cifNReadLayers; i++)
	{
	     if (TTMaskHasType(&mask,i))
	     {
	     	  if (cifCurReadStyle->crs_labelLayer[i] == TT_SPACE)
		  {
		       cifCurReadStyle->crs_labelLayer[i] = -1;
		  }
	     }
	}
	return TRUE;
    }

    /* Anything below here is a geometric operation, so we can
     * do some set-up that is common to all the operations.
     */
    
    if (cifCurReadStyleLayer == NULL)
    {
	MnTechError("Must define layer before specifying operations.\n");
	goto errorReturn;
    }
    MALLOC_TAG(CIFOp *,
	       newOp,
	       sizeof(CIFOp),
	       "CIFOp");

    TTMaskZero(&newOp->co_paintMask);
    TTMaskZero(&newOp->co_cifMask);
    newOp->co_opcode = 0;
    newOp->co_next = NULL;

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
    else
    {
	MnTechError("Unknown statement \"%s\".\n", argv[0]);
	goto errorReturn;
    }

    /* layers with operations other than OR can not be direct mapped. */
    switch (newOp->co_opcode)
    {
	case CIFOP_AND:
	case CIFOP_ANDNOT:
	case CIFOP_OR:
	    if (argc != 2) goto wrongNumArgs;
	    CIFParseReadLayers(argv[1], &newOp->co_cifMask);
	    break;
	
	case CIFOP_GROW:
	case CIFOP_SHRINK:
	    if (argc != 2) goto wrongNumArgs;
	    newOp->co_distance = atoi(argv[1]);
	    if (newOp->co_distance <= 0)
	    {
		MnTechError("Grow/shrink distance must be greater than zero.\n");
		goto errorReturn;
	    }
	    break;
    }

    /* Link the new CIFOp onto the list. */

    if (cifCurReadOp == NULL)
    {
	cifCurReadStyleLayer->crl_ops = newOp;
    }
    else
    {
        cifCurReadOp->co_next = newOp;
    }
    cifCurReadOp = newOp;

    return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifReadFindDirectMapsStyle --
 *
 * 	Called by cifReadFindDirectMaps to find cif layers that map directly
 *	to Max layers in given cif read style
 *      
 *      Sets up crs_DBType[] for this style
 *
 * ----------------------------------------------------------------------------
 */
static void cifReadFindDirectMapsStyle(CIFReadStyle *style)
{
  int i,layer;

  /* initially, mark all layers unreferenced */
  for(i=0; i<MAXCIFRLAYERS; i++) style->crs_DBType[i] = -1;

  /* process layer by layer for this style */
  for(i=0; i<style->crs_nLayers; i++)
  {
    CIFReadStyleLayer *layer = style->crs_layers[i];
    CIFOp *co; 

    ASSERT(layer,"cifReadFindDirectMapsStyle");
	
    /* proces cif operations */ 
    for(co=layer->crl_ops; co; co=co->co_next)
    {
      if(co == layer->crl_ops && 
	 !co->co_next && 
	 co->co_opcode == CIFOP_OR &&
	 DBIsSimpleType[layer->crl_magicType])
      {
	/* this layer is simple type defined by simple OR, 
	   consider cif layers for direct map */

	int t;

	for(t=0; t<MAXCIFRLAYERS; t++)
        {
	  if(!TTMaskHasType(&co->co_cifMask, t)) continue;
	  if(style->crs_DBType[t]==-1)
	  {
	    style->crs_DBType[t] = layer->crl_magicType;

	    /*
	    fprintf(stderr,"DEBUG, setting %s -> %s in style %s\n",
		    cifReadLayers[t],
		    DBTypeShortName(layer->crl_magicType),
		    style->crs_name);
	    */
	  }
	  else
	  {
	    /* CIF layer has multiple references so can't be direct mapped */
	    style->crs_DBType[t] = 0;

	    /*
	    fprintf(stderr,"DEBUG, disabling direct map for %s in style %s\n",
		    cifReadLayers[t], 
		    style->crs_name);
	    */

	  }
	}
      }
      else
      {
	/* disqualify layers referenced by this cif op */

	int t;
 
	for(t=0; t<MAXCIFRLAYERS; t++)
        {
	  if(!TTMaskHasType(&co->co_cifMask, t)) continue;
	  style->crs_DBType[t] = 0;

	  /*
	  fprintf(stderr,"DEBUG, disabling direct map for %s in style %s\n",
		  cifReadLayers[t], 
		  style->crs_name);
	  */
	}
      }
    }
  }

  /* finally, disqualify remaining unreferenced layers */
  for(i=0; i<MAXCIFRLAYERS; i++) 
  {
    if(style->crs_DBType[i] != -1) continue;
    style->crs_DBType[i] = 0;
  }
}

/*
 * ----------------------------------------------------------------------------
 *
 * cifReadFindDirectMaps --
 *
 * 	Called by CIFReadTechFinal to find cif layers that map directly
 *	to Max layers.
 *      
 *      Sets up crs_DBType[] arrays for all cif read styles.
 *
 * ----------------------------------------------------------------------------
 */
static void cifReadFindDirectMaps(void)
{
  CIFReadStyle *style;

  for(style = cifReadStyleList; style; style = style->crs_next)
  {
    cifReadFindDirectMapsStyle(style);
  }
}


/*
 * ----------------------------------------------------------------------------
 *
 * CIFReadTechFinal --
 *
 * 	This procedure is invoked after all the lines of a technology
 *	file have been read.  It checks to make sure that the information
 *	read in "cifinput" sections is reasonably complete.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Error messages may be output.
 *
 * ----------------------------------------------------------------------------
 */

Void
CIFReadTechFinal(void)
{
    CIFReadStyle *style;

    /* find CIF layers that can be mapped directly to Max layers
     *  (sets up crs_DBtype[])
     */
    cifReadFindDirectMaps();

    /* Make the first style the current one. */
    cifCurReadStyle = cifReadStyleList;
    
}
