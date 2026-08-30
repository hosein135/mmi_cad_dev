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

/*
 * DBlayers.c --
 *
 * Routines for creating and querying mapping between tiletypes and planes 
 * and their names.
 *
 * WARNING: with the exception of DB*TechName{Type,Plane}() and
 * DB*ShortName(), * the name lookup procedures in this file MUST be called
 * after DBTechFinalType() has been called.
 */

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "magic.h"
#include "main.h"
#include "database.h"
#include "databaseInt.h"
#include "commands.h"
#include "geometry.h"
#include "utils.h"
#include "tile.h"
#include "hash.h"
#include "message.h"
#include "memory.h"

    /* Types and their names */
int DBNumTypes;
char *DBTypeLongNameTbl[NT];
int DBTypePlaneTbl[NT];
bool DBIsSimpleType[NT];
NameList dbTypeNameLists;

    /* Planes and their names */
int DBNumPlanes;
int DBPlaneActive = 0;    /* set to "active" plane num, if any */

char *DBPlaneLongNameTbl[PL_MAXPLANES];

/* Plane Lists */
PlaneList *PlaneListFreeList = NULL;

int DBPlaneFlags[PL_MAXPLANES];

/* layer dependencies (only used for auto generated planes) */
TileTypeBitMask DBPlaneDependencies[PL_MAXPLANES];

/* temporary layers */
TileTypeBitMask DBTempTypes;
TileTypeBitMask DBNonTempTypes;

/* Types belonging to each plane */
TileTypeBitMask DBPlaneTypes[PL_MAXPLANES];

NameList dbPlaneNameLists;

    /*
     * Sets of types.
     * These are generated after the "types" section of the
     * technology file has been read, but before any automatically
     * generated types (contact images) are created.
     */
int DBNumUserLayers;
TileTypeBitMask DBZeroTypeBits;
TileTypeBitMask DBAllTypeBits;
TileTypeBitMask DBBuiltinLayerBits;
TileTypeBitMask DBAllButSpaceBits;
TileTypeBitMask DBAllButSpaceAndDRCBits;
TileTypeBitMask DBSpaceBits;
TileTypeBitMask DBUserLayerBits;
TileTypeBitMask DBNonSpaceUserLayerBits;
TileTypeBitMask DBFlyLineBits;

/* Table of default, builtin planes */
DefaultPlane dbTechDefaultPlanes[] =
{
    PL_DRC_ERROR,	"designRuleError",
    PL_DRC_CHECK,	"designRuleCheck",
    0,			0,	0
};

/* Table of default, builtin types */
DefaultType dbTechDefaultTypes[] =
{
    TT_SPACE,		-1,		"space",		FALSE,
    TT_CHECKPAINT,	PL_DRC_CHECK,	"checkpaint,CP",	FALSE,
    TT_CHECKSUBCELL,	PL_DRC_CHECK,	"checksubcell,CS",	FALSE,
    TT_ERROR_P,		PL_DRC_ERROR,	"error_p,EP",		FALSE,
    TT_ERROR_S,		PL_DRC_ERROR,	"error_s,ES",		FALSE,
    TT_ERROR_PS,	PL_DRC_ERROR,	"error_ps,EPS",		FALSE,
    0,			0,		NULL,			0
};

/* Forward declarations */
ClientData dbTechNameLookup(char *str, NameList *table);
char *dbTechNameAdd(register char *name, ClientData cdata, NameList *ptable);
NameList *dbTechNameAddOne(register char *name, ClientData cdata, int isPrimary, NameList *ptable);



/*
 * ----------------------------------------------------------------------------
 *
 * dbLayersInitType --
 *
 * Add the names and planes of the builtin types.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *	Initializes DBNumTypes to TT_TECHDEPBASE.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbLayersInitType(void)
{
    register DefaultType *dtp;
    register char *cp;

    /* Tables of short names */
    dbTypeNameLists.sn_next = &dbTypeNameLists;
    dbTypeNameLists.sn_prev = &dbTypeNameLists;

    /*
     * Add the type names to the list of known names, and set
     * the default plane for each type.
     */
    for (dtp = dbTechDefaultTypes; dtp->dt_names; dtp++)
    {
	cp = dbTechNameAdd(dtp->dt_names, (ClientData) dtp->dt_type,
			&dbTypeNameLists);
	if (cp == NULL)
	{
	    MaxAbort("DBTechInit: can't add type names %s\n", dtp->dt_names);
	}
	DBTypeLongNameTbl[dtp->dt_type] = cp;
	DBTypePlaneTbl[dtp->dt_type] = dtp->dt_plane;
    }

    DBNumTypes = TT_TECHDEPBASE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbLayersInitPlane --
 *
 * initialize the default plane information.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes DBNumPlanes to PL_TECHDEPBASE.
 *	Initializes DBPlaneLongNameTbl[] for builtin planes.
 *
 * ----------------------------------------------------------------------------
 */

static void
dbLayersInitPlane(void)
{
    register DefaultPlane *dpp;
    register char *cp;
    int i;

    /* Tables of short names */
    dbPlaneNameLists.sn_next = &dbPlaneNameLists;
    dbPlaneNameLists.sn_prev = &dbPlaneNameLists;

    for (dpp = dbTechDefaultPlanes; dpp->dp_names; dpp++)
    {
	cp = dbTechNameAdd(dpp->dp_names, (ClientData) dpp->dp_plane,
			&dbPlaneNameLists);
	if (cp == NULL)
	{
	    MaxAbort("DBTechInit: can't add plane names %s\n", dpp->dp_names);
	}
	DBPlaneLongNameTbl[dpp->dp_plane] = cp;
    }

    DBNumPlanes = PL_TECHDEPBASE;

    
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbLayersInit --
 *
 * Called by DBInit() at startup to do technology independent initialization
 * of layers data structures.
 *
 *
 * ----------------------------------------------------------------------------
 */
void
dbLayersInit()
{
  dbLayersInitType();
  dbLayersInitPlane();
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechNameType --
 *
 * Map from a type name into a type number.  If the type name has
 * the form "<type>/<plane>" and <type> is a contact, then the
 * type returned is the image of the contact on <plane>.  Of
 * course, in this case, <type> must have an image on <plane>.
 *
 * Results:
 *	Type number.  A value of -2 indicates that the type name was
 *	unknown; -1 indicates that it was ambiguous.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

TileType
DBTechNameType(char *typename)
                   	/* The name of the type */
{
    char *slash;
    TileType type;
    int plane, i;

    slash = strchr(typename, '/');
    if (slash != NULL) *slash = 0;
    type = (TileType) dbTechNameLookup(typename, &dbTypeNameLists);
    if (slash == NULL) return type;
    *slash = '/';
    if (type < 0) return type;

    /* There's a plane qualification.  Locate the image. */

    plane = (int) dbTechNameLookup(slash+1, &dbPlaneNameLists);
    if (plane < 0) return -2;
    if (DBPlane(type) == plane) return type;

    return -2;
}

/*
 *-------------------------------------------------------------------------
 *
 * The following returns a bitmask with the appropriate types set for the
 *	typename supplied.  This is useful when searching for plane-qualified
 *	images, where there may be more than one that fits the bill.
 *
 * Results: returns the first type found
 *
 * Side Effects: sets bitmask with the appropriate types.
 *
 *-------------------------------------------------------------------------
 */

TileType
DBTechNameTypes(char *typename, TileTypeBitMask *bitmask)
                   	/* The name of the type */
                   	         
{
    char *slash;
    TileType type,returntype;
    int plane, i;

    TTMaskZero(bitmask);
    slash = strchr(typename, '/');
    if (slash != NULL) *slash = 0;
    type = (TileType) dbTechNameLookup(typename, &dbTypeNameLists);
    if(type<0) return type;

    if (slash == NULL)
    {
    	 TTMaskSetType(bitmask,type);
	 return type;
    } 
    *slash = '/';
    if (type < 0) return type;

    /* There's a plane qualification.  Locate the image. */

    plane = (int) dbTechNameLookup(slash+1, &dbPlaneNameLists);
    if (plane < 0) return -2;
    if (DBPlane(type) == plane)
    {
    	 TTMaskSetType(bitmask,type);
    	 return type;
    } 
    returntype = -2;

    return returntype;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechNoisyNameType --
 *
 * Map from a type name into a type number, complaining if the type
 * is unknown.
 *
 * Results:
 *	Type number.  A value of -2 indicates that the type name was
 *	unknown; -1 indicates that it was ambiguous.
 *
 * Side effects:
 *	Prints a diagnostic message if the type name is unknown.
 *
 * ----------------------------------------------------------------------------
 */

TileType
DBTechNoisyNameType(char *typename)
                   	/* The name of the type */
{
    TileType type;

    switch (type = DBTechNameType(typename))
    {
	case -1:
	    MnTechError("Ambiguous layer (type) name \"%s\"\n", typename);
	    break;
	case -2:
	    MnTechError("Unrecognized layer (type) name \"%s\"\n", typename);
	    break;
	default:
	    if (type < 0)
		MnTechError("Funny type \"%s\" returned %d\n", typename, type);
	    break;
    }

    return (type);
}
/*
 * ----------------------------------------------------------------------------
 *
 * DBTechNamePlane --
 *
 * Map from a plane name into a plane number.
 *
 * Results:
 *	Plane number.  A value of -2 indicates that the plane name was
 *	unknown; -1 indicates that it was ambiguous.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

int DBTechNamePlane(char *planename)
                    	/* The name of the plane */
{
    return ((int) dbTechNameLookup(planename, &dbPlaneNameLists));
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechNoisyNamePlane --
 *
 * Map from a plane name into a plane number, complaining if the plane
 * is unknown.
 *
 * Results:
 *	Plane number.  A value of -2 indicates that the plane name was
 *	unknown; -1 indicates that it was ambiguous.
 *
 * Side effects:
 *	Prints a diagnostic message if the type name is unknown.
 *
 * ----------------------------------------------------------------------------
 */

int
DBTechNoisyNamePlane(char *planename)
                    	/* The name of the plane */
{
    int pNum;

    switch (pNum = DBTechNamePlane(planename))
    {
	case -1:
	    MnTechError("Ambiguous plane name \"%s\"\n", planename);
	    break;
	case -2:
	    MnTechError("Unrecognized plane name \"%s\"\n", planename);
	    break;
    }

    return (pNum);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTypeShortName --
 * DBPlaneShortName --
 *
 * Return the short name for a type or plane.
 * The short name is the "official abbreviation" for the type or plane,
 * identified by a leading '*' in the list of names in the technology
 * file.
 *
 * Results:
 *	Pointer to the primary short name for the given type or plane.
 *	If the type or plane has no official abbreviation, returns
 *	a pointer to the string "???".
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

char *
DBTypeShortName(TileType type)
{
    register NameList *tbl;

    for (tbl = dbTypeNameLists.sn_next;
	    tbl != &dbTypeNameLists;
	    tbl = tbl->sn_next)
    {
	if (tbl->sn_value == (ClientData) type && tbl->sn_primary)
	    return (tbl->sn_name);
    }

    if (DBTypeLongNameTbl[type])
	return (DBTypeLongNameTbl[type]);
    return ("???");
}

char *
DBPlaneShortName(int pNum)
{
    register NameList *tbl;

    for (tbl = dbPlaneNameLists.sn_next;
	    tbl != &dbPlaneNameLists;
	    tbl = tbl->sn_next)
    {
	if (tbl->sn_value == (ClientData) pNum && tbl->sn_primary)
	    return (tbl->sn_name);
    }

    if (DBPlaneLongNameTbl[pNum])
	return (DBPlaneLongNameTbl[pNum]);
    return ("???");
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneListHasPlane --
 *
 * Returns TRUE iff given plane list contains Plane indexed by num
 *
 * ----------------------------------------------------------------------------
 */

bool DBPlaneListHasPlane(PlaneList *pll, int num)
{
  while(pll && pll->pll_num != num) pll = pll->pll_next;

  return pll!=NULL;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneListAdd --
 *
 * Add to plane list.
 *
 *
 * ----------------------------------------------------------------------------
 */

void DBPlaneListAdd(PlaneList **pllp, int num)
{
  PlaneList *new;

  new = PlaneListAlloc();
  new->pll_num = num;
  new->pll_next = *pllp;
  *pllp = new;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneListAddUnique --
 *
 * Add plane num to list iff not already in list.
 *
 *
 * ----------------------------------------------------------------------------
 */

void DBPlaneListAddUnique(PlaneList **pllp, int num)
{
  PlaneList *new;

  /* avoid redundant adds */
  if(DBPlaneListHasPlane(*pllp, num)) return;

  DBPlaneListAdd(pllp,num);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneListAddList --
 *
 * Add second list into first
 *
 *
 * ----------------------------------------------------------------------------
 */

void DBPlaneListAddList(PlaneList **pllp, PlaneList *addList)
{
  PlaneList *new;

  while(addList)
  {
    DBPlaneListAddUnique(pllp,addList->pll_num);
    addList = addList->pll_next;
  }
}

/*
 * ----------------------------------------------------------------------------
 * DBPlaneList2String --
 * 
 * generate comment seperated list of plane names.
 *
 * returns TRUE on success, FALSE on failure. 
 *
 * ----------------------------------------------------------------------------
 */		 
bool
DBPlaneList2String(PlaneList *pll, char *buf, int bufSize)
{
  int first = TRUE;
  int i=0;

  for(;pll;pll=pll->pll_next)
  {
    char *p;

    if(!first) 
    {
      if(i==bufSize) goto overflow;
      buf[i++] = ',';
    }
    else
    {
      first=FALSE;
    }

    for(p=DBPlaneLongNameTbl[pll->pll_num]; *p!='\0'; p++)
    {
      if(i==bufSize) goto overflow;
      buf[i++] = *p;
    }
  }

  if(i==bufSize) goto overflow;
  buf[i]= '\0';
  return TRUE;

 overflow:
  buf[i-1] = '\0';
  return FALSE;
} 


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneListFromTypes --
 *
 * Convert a TileTypeBitMask into a list of the planes which may
 * contain tiles of those types.
 *
 * NOTE: call PlaneListFree() on result when done with it. 
 *
 * ----------------------------------------------------------------------------
 */

PlaneList *DBPlaneListFromTypes(TileTypeBitMask *mask)
{
  PlaneList *pll = NULL;
  TileType type;
  bool haveActive = FALSE;
  bool haveDRCErrors = FALSE;
  bool haveDRCCheck = FALSE;

  if (TTMaskHasType(mask, TT_SPACE))  
  {
    /* special case masks with TT_SPACE in them
     * Space tiles are present in all planes but 0 (the cell plane) 
     */
    for(type = DBNumTypes-1; type > 0; type--)
    {
      /* avoid redundant entries for multi-type planes */
      if(DBPlane(type)==PL_DRC_ERROR)
      {
	if(haveDRCErrors) continue;
	haveDRCErrors = TRUE;
      }
      if(DBPlane(type)==PL_DRC_CHECK)
      {
	if(haveDRCCheck) continue;
	haveDRCCheck = TRUE;
      }
      if(DBPlaneActive && DBPlane(type)==DBPlaneActive)
      {
	if(haveActive) continue;
	haveActive = TRUE;
      }

      DBPlaneListAdd(&pll,DBPlane(type));
    }
  }
  else
  {
    /* non-space tiles live on exactly one plane
     * (no longer use Magic style contacts!)
     */
    for(type = DBNumTypes-1; type > 0; type--)
    {

      if (TTMaskHasType(mask,type)) 
      {
	/* avoid redundant entries for multi-type planes */
	if(DBPlane(type)==PL_DRC_ERROR)
	{
	  if(haveDRCErrors) continue;
	  haveDRCErrors = TRUE;
	}
        if(DBPlane(type)==PL_DRC_CHECK)
        {
	  if(haveDRCCheck) continue;
	  haveDRCCheck = TRUE;
	}
	if(DBPlaneActive && DBPlane(type)==DBPlaneActive)
	{
	  if(haveActive) continue;
	  haveActive = TRUE;
	}

	DBPlaneListAdd(&pll,DBPlane(type));
      }
    }
  }
  return pll;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBPlaneListToTypes --
 *
 * Convert a planelist into mask of all non-space tiletypes 
 * on those planes.
 *
 * ----------------------------------------------------------------------------
 */

TileTypeBitMask DBPlaneListToTypes(PlaneList *pll)
{
  TileTypeBitMask mask;

  TTMaskZero(&mask);

  for(;pll;pll=pll->pll_next)
  {
    TTMaskSetMask(&mask, &DBPlaneTypes[pll->pll_num]);
  }

  TTMaskClearType(&mask,TT_SPACE);

  return mask;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechPrintTypes --
 *
 * 	This routine prints out all the layer names for types defined
 *	in the current technology.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stuff is printed.
 *
 * ----------------------------------------------------------------------------
 */

void
DBTechPrintTypes(void)
{
    TileType i;
    NameList *p;
    bool first;
    DefaultType *dtp;

    MsgInfoF("Layer names are:\n");

    /* List technology independent types */
    for (i = TT_TECHDEPBASE; i < DBNumUserLayers; i++)
    {
	first = TRUE;
	for (p = dbTypeNameLists.sn_next; p != &dbTypeNameLists;
		p = p->sn_next)
	{
	    if (((TileType) p->sn_value) == i)
	    {
		if (first) MsgInfoF("    %s", p->sn_name);
		else MsgInfoF(" or %s", p->sn_name);
		first = FALSE;
	    }
	}
	if (!first) MsgInfoF("\n");
    }

    /* List build in types that are normally painted by name */
    for (dtp = dbTechDefaultTypes; dtp->dt_names; dtp++)
    {
	if (dtp->dt_print)
	{
	    first = TRUE;
	    for (p = dbTypeNameLists.sn_next; p != &dbTypeNameLists;
		p = p->sn_next)
	    {
		if (((TileType) p->sn_value) == dtp->dt_type)
		{
		    if (first)
			MsgInfoF("    %s", p->sn_name);
		    else 
			MsgInfoF(" or %s", p->sn_name);
		    first = FALSE;
		}
	    }
	    if (!first) MsgInfoF("\n");
	}
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechNoisyNameMask --
 *
 *	Parses an argument string that selects a group of layers.
 *	The string may contain one or more layer names separated
 *	by commas.  The special layer name of "0" specifies no layer,
 *      it is used as a place holder, e.g., to specify a null
 *      layer list for the CornerTypes field in a drc edge-rule.
 *      In addition, a tilde may be used to indicate
 *	"all layers but", and parentheses may be used for grouping.
 *	Thus ~x means "all layers but x", and ~(x,y),z means "z plus
 *	everything except x and y)".  
 *	Layer expressions can be suffixed with a plane specifier.
 *	For example, ~(x,y)/foo refers to
 *	all layers on plane "foo" except "x" and "y".
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Error messages are output if layers aren't understood.
 *	Sets the TileTypeBitMask 'mask' to all the layer names indicated.
 *
 * ----------------------------------------------------------------------------
 */

void
DBTechNoisyNameMask(char *layers, TileTypeBitMask *mask)
                 			/* String to be parsed. */
                          		/* Where to store the layer mask. */
{
    register char *p, *p2, c;
    TileTypeBitMask m2;            /* Each time around the loop, we will
                                         * form the mask for one section of
                                         * the layer string.
                                         */
    char save;
    bool allBut;

    TTMaskZero(mask);
    p = layers;
    while (TRUE)
    {
	TTMaskZero(&m2);

	c = *p;
	if (c == 0) break;

	/* Check for a tilde, and remember it in order to do negation. */

	if (c == '~')
	{
	    allBut = TRUE;
	    p += 1;
	    c = *p;
	}
	else allBut = FALSE;

	/* Check for parentheses.  If there's an open parenthesis,
	 * find the matching close parenthesis and recursively parse
	 * the string in-between.
	 */

	if (c == '(')
	{
	    int nesting = 0;

	    p += 1;
	    for (p2 = p; ; p2 += 1)
	    {
		if (*p2 == '(') nesting += 1;
		else if (*p2 == ')')
		{
		    nesting -= 1;
		    if (nesting < 0) break;
		}
		else if (*p2 == 0)
		{
		    MnTechError("Unmatched parenthesis in layer name \"%s\".\n",
			layers);
		    break;
		}
	    }
	    save = *p2;
	    *p2 = 0;
	    DBTechNoisyNameMask(p, &m2);
	    *p2 = save;
	    if (save == ')') p = p2 + 1;
	    else p = p2;
	}
	else
	{
	    TileType t;

	    /* No parenthesis, so just parse off a single name.  Layer
	     * name "0" corresponds to no layers at all.
	     */

	    for (p2 = p; ; p2++)
	    {
		c = *p2;
		if ((c == '/') || (c == ',') || (c == 0)) break;
	    }
	    if (p2 == p)
	    {
		MnTechError("Missing layer name in \"%s\".\n", layers);
	    }
	    else if (strcmp(p, "0") != 0)
	    {
		save = *p2;
		*p2 = 0;
		t = DBTechNoisyNameType(p);
		if (t >= 0) TTMaskSetOnlyType(&m2,t);
		*p2 = save;
	    }
	    p = p2;
	}

	/* Now negate the layers, if that is called for. */

	if (allBut) TTMaskCom(&m2);

	/* Restrict to a single plane, if that is called for. */

	if (*p == '/')
	{
	    int plane;

	    p2 = p+1;
	    while ((*p2 != 0) && (*p2 != ',')) p2 += 1;
	    save = *p2;
	    *p2 = 0;
    	    plane = DBTechNoisyNamePlane(p+1);
	    *p2 = save;
	    p = p2;
	    if (plane > 0) TTMaskAndMask(&m2, &DBPlaneTypes[plane]);
	}

	TTMaskSetMask(mask, &m2);
	while (*p == ',') p++;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechSubsetLayers --
 *
 * 	Eliminate all bits from one mask that aren't in another, and
 *	check to be sure that this elimination only occurs for contact
 *	types that will still have one image in the result.
 *
 * Results:
 *	TRUE is returned if the subsetting was successful.  Success
 *	means that for each layer in "src", the corresponding layer
 *	is in "mask" or else "src" contains another image of the bit
 *	that is in "mask".
 *
 * Side effects:
 *	The mask pointed to by "result" is modified to contain the
 *	subset of "src" that is in "mask".
 *
 * ----------------------------------------------------------------------------
 */

bool
DBTechSubsetLayers(TileTypeBitMask src, TileTypeBitMask mask, TileTypeBitMask *result)
                        		/* Original set of tile types. */
                         		/* Only keep types in this mask. */
                            		/* Store subset here. */
{
    TileTypeBitMask tmp,tmp2,clrmask;
    register int i;
    bool success = TRUE;

    TTMaskZero(result);
    TTMaskZero(&clrmask);
    for (i = 0; i < DBNumUserLayers; i++)
    {
        TileTypeBitMask iMask;
 
	TTMaskSetOnlyType(&iMask,i);
	TTMaskAndMask3(&tmp, &src, &iMask);
	if (!TTMaskIsZero(&tmp))
	{
	     TTMaskAndMask3(&tmp2, &tmp,&mask);
	     if (!TTMaskIsZero(&tmp2))
	     {
	     	  TTMaskSetMask(&clrmask,&tmp);
	          TTMaskSetMask(result, &tmp2);
	     }
	}
    }
    if (TTMaskEqual(&clrmask,&src)) return TRUE; else return FALSE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechAddPlane --
 *
 * Define a tile plane type for the new technology.
 *
 * Results:
 *	TRUE if successful, FALSE on error
 *
 * Side effects:
 *	Updates the database technology variables.
 *	In particular, updates the number of known tile planes.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
bool
DBTechAddPlane(char *sectionName, int argc, char **argv)
{
    char *cp;

    if (DBNumPlanes >= PL_MAXPLANES)
    {
	MnTechError("Too many tile planes (max=%d)\n", PL_MAXPLANES);
	return FALSE;
    }

    if (argc != 1)
    {
	MnTechError("Line must contain names for plane\n");
	return FALSE;
    }

    cp = dbTechNameAdd(argv[0], (ClientData) DBNumPlanes, &dbPlaneNameLists);
    if (cp == NULL)
	return FALSE;

    DBPlaneLongNameTbl[DBNumPlanes] = cp;
    DBPlaneFlags[DBNumPlanes] = 0;

    /* remember active plane */
    if(strcmp(cp,"active")==0) DBPlaneActive = DBNumPlanes;

    /* add the new plane to each existing celldef */
    {
      CellDef *def;
      for (def=DBCellDefs; def; def=def->cd_next)
      {
	def->cd_planes[DBNumPlanes] = DBPlaneNew((ClientData) NULL);
      }
    }

    DBNumPlanes++;	
    return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBTechAddType --
 *
 * Define a tile type for the new technology.
 *
 * Results:
 *	TRUE if successful, FALSE on error
 *
 * Side effects:
 *	Updates the database technology variables.
 *	In particular, updates the number of known tile types.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
bool
DBTechAddType(char *sectionName, int argc, char **argv)
{
    char *cp;
    int pNum;

    if (DBNumTypes >= TT_MAXTYPES-TT_RESERVEDTYPES)
    {
	MnTechError("Too many tile types (max=%d)\n",
		TT_MAXTYPES-TT_RESERVEDTYPES);
	return FALSE;
    }

    if (argc < 2)
    {
	MnTechError("Line must contain at least 2 fields\n");
	return TRUE;
    }

    cp = dbTechNameAdd(argv[1], (ClientData) DBNumTypes, &dbTypeNameLists);
    if (cp == NULL)
	return FALSE;
    pNum = DBTechNoisyNamePlane(argv[0]);
    if (pNum < 0)
	return FALSE;

    DBTypeLongNameTbl[DBNumTypes] = cp;
    DBTypePlaneTbl[DBNumTypes] = pNum;
    DBNumTypes++;

    return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBTechFinalType --
 *
 * After processing the types and planes sections, compute the
 * various derived type and plane masks and tables.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes DBNumUserLayers to be DBNumTypes at the time
 *	    this procedure is called, since none of the automatically
 *	    generated plane images have yet been created.
 *	Initializes the following bit masks:
 *		DBAllTypeBits
 *		DBSpaceBits
 *		DBBuiltinLayerBits
 *		DBAllButSpaceBits
 *		DBAllButSpaceAndDRCBits
 *		DBUserLayerBits
 *		DBNonSpaceUserLayerBits
 *              DBFlyLineBits
 *
 * ----------------------------------------------------------------------------
 */

void
DBTechFinalType(void)
{
    TileType i;
    int pNum;

    DBNumUserLayers = DBNumTypes;

    for (i = 0; i < TT_MAXTYPES; i++)
    {
	if (i >= TT_SELECTBASE)
	    TTMaskSetType(&DBAllButSpaceAndDRCBits, i);

	if (i < TT_TECHDEPBASE)
	    TTMaskSetType(&DBBuiltinLayerBits, i);
	else if (i < DBNumUserLayers)
	    TTMaskSetType(&DBUserLayerBits, i);
    }

    TTMaskZero(&DBTempTypes);
    TTMaskCom2(&DBNonTempTypes, &DBTempTypes);
    TTMaskCom2(&DBAllTypeBits, &DBZeroTypeBits);
    TTMaskSetOnlyType(&DBSpaceBits, TT_SPACE);
    TTMaskCom2(&DBAllButSpaceBits, &DBSpaceBits);
    TTMaskClearMask3(&DBNonSpaceUserLayerBits, &DBUserLayerBits, &DBSpaceBits);
    TTMaskSetOnlyType(&DBFlyLineBits, L_FLYLINE);

    /* Space is visible on all planes */
    for (pNum = PL_PAINTBASE;  pNum < PL_MAXPLANES;  pNum++)
	TTMaskSetOnlyType(&DBPlaneTypes[pNum], TT_SPACE);

    /* Update the mask of types visible on each plane. */
    for (i = 0; i < DBNumTypes; i++)
    {
        int pNum = DBTypePlaneTbl[i];
	if (pNum > 0)
	{
	    TTMaskSetType(&DBPlaneTypes[pNum], i);
	}
    }

    /* initialize user bbox layers */
    dbBBoxSetUserPlanes(&DBAllButSpaceAndDRCBits);

    /* check that only active (and drc planes) are multi-typed */ 
    for(i=1; i < DBNumTypes; i++)
    {
      TileTypeBitMask mask;

      TTMaskSetOnlyType(&mask,i);
      TTMaskSetType(&mask,TT_SPACE);
      pNum = DBPlane(i);
      
      if(!TTMaskEqual(&mask,&DBPlaneTypes[pNum]) && 
	 pNum!=DBPlaneActive && 
	 pNum!=PL_DRC_ERROR &&
	 pNum!=PL_DRC_CHECK)
      {
	 MnTechError("non-active plane '%s' has multiple types!\n",
		     DBPlaneLongNameTbl[pNum]);
      }
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbTechNameLookup --
 *
 * Lookup a type or plane name.
 * Case is significant.
 *
 * Results:
 *	Returns the ClientData associated with the given name.
 *	If the name was not found, we return -2; if it was ambiguous,
 *	we return -1.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

ClientData
dbTechNameLookup(char *str, NameList *table)
              		/* The name to be looked up */
                    	/* Table of names to search */
{
    /*
     * The search is carried out by using two pointers, one which moves
     * forward through list from its start, and one which moves backward
     * through table from its end.  The two pointers mark the range of
     * strings that match the portion of str that we have scanned.  When
     * all of the characters of str have been scanned, then the two
     * pointers better be identical, or one of the strings in the range
     * between the two pointers better match 'str' exactly.
     */
    register NameList *bot, *top;
    char currentchar;
    int indx;

    bot = table->sn_next;
    top = table->sn_prev;
    if (top == bot) return ((ClientData) -2);

    for (indx = 0; ; indx++)
    {
	/* Check for the end of string */
	currentchar = str[indx];
	if (currentchar == '\0')
	{
	    if (bot == top)
		return (bot->sn_value);

	    /*
	     * Several entries match this one up to the last character
	     * of the string.  If one is an exact match, we allow it;
	     * otherwise, we claim the string was ambiguous.
	     */
	    for ( ; bot != top; bot = bot->sn_next)
		if (bot->sn_name[indx] == '\0')
		    return (bot->sn_value);

	    return ((ClientData) -1);
	}

	/*
	 * Move bot up until the string it points to matches str in the
	 * indx'th position.  Make match refer to the indx of bot in table.
	 */
	while (bot->sn_name[indx] != currentchar)
	{
	    if (bot == top) return((ClientData) -2);
	    bot = bot->sn_next;
	}

	/* Move top down until it matches */
	while (top->sn_name[indx] != currentchar)
	{
	    if (bot == top) return((ClientData) -2);
	    top = top->sn_prev;
	}
    }

    /*NOTREACHED*/
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbTechNameAdd --
 *
 * Add several names to a name table.
 * The shortest name is marked as the standard "short" name
 * for this cdata value.
 *
 * Results:
 *	Returns a pointer to the first name added if successful,
 *	or NULL if not.  In this latter case, we print error messages.
 *
 * Side effects:
 *	Adds new entries to the table pointed to by *ptable, and
 *	modifies *ptable if necessary.
 *
 * ----------------------------------------------------------------------------
 */

char *
dbTechNameAdd(register char *name, ClientData cdata, NameList *ptable)
                        	/* Comma-separated list of names to be added */
                     		/* Value to be stored with each name above */
                     		/* Table to which we will add names */
{
    register char *cp;
    char onename[BUFSIZ];
    char *first;
    int shortestLength, length;
    NameList *primary, *current;

    if (name == NULL)
	return (NULL);

    first = NULL;
    shortestLength = INFINITY;
    primary = NULL;
    while (*name)
    {
	if (*name == ',')
	{
	    name++;
	    continue;
	}
	for (cp = onename; *name && *name != ','; *cp++ = *name++)
	    /* Nothing */;
	*cp = '\0';
	if (*(cp = onename))
	{
	    if ((current = dbTechNameAddOne(cp, cdata, FALSE, ptable)) == NULL)
		return (NULL);
	    if (first == NULL)
		first = current->sn_name;
	    length = strlen(onename);
	    if (length < shortestLength)
		shortestLength = length, primary = current;
	}
    }

    if (primary)
	primary->sn_primary = TRUE;
    return (first);
}

/*
 * ----------------------------------------------------------------------------
 *
 * dbTechNameAddOne --
 *
 * Add a single name to the table.
 *
 * Results:
 *	Returns a pointer to the new entry if succesful,
 *	or NULL if the name was already in the table.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

NameList *
dbTechNameAddOne(register char *name, ClientData cdata, int isPrimary, NameList *ptable)
                        	/* Name to be added */
                     		/* Client value associated with this name */
                   		/* TRUE if this is the primary abbreviation */
                     		/* Table of names to which we're adding this */
{
    register cmp;
    register NameList *tbl, *new;

    /* Sort the name into the existing list */
    for (tbl = ptable->sn_next ;tbl != ptable; tbl = tbl->sn_next)
	if ((cmp = strcmp(name, tbl->sn_name)) == 0)
	{
	    MnTechError("Duplicate name: %s\n", name);
	    return (NULL);
	}
	else if (cmp < 0)
	    break;

    /* Create a new name */
    MALLOC(NameList *, new, sizeof (NameList));
    new->sn_name = StrDup((char **) NULL, name);
    new->sn_value = cdata;
    new->sn_primary = isPrimary;

    /* Link this entry in to the list before 'tbl' */
    new->sn_next = tbl;
    new->sn_prev = tbl->sn_prev;
    tbl->sn_prev->sn_next = new;
    tbl->sn_prev = new;
    return (new);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLayerTempSet
 *
 * Mark a layer as temporary.
 *
 * Temporary layers are not normally read from or written to disk.
 *
 * Changing a temporary layer does not set the modified bit for a cell.
 * 
 * Temporary layers can be modified even in read-only cells.
 *
 * ----------------------------------------------------------------------------
 */

void
DBLayerTempSet(int plane)
{

  /* must be simple plane */
  if(plane == DBPlaneActive)
  {
    MsgErrorF("Can not mark active plane temporary!\n");
    return;
  }

  DBPlaneFlags[plane] |= DBF_TEMP;

  TTMaskSetMask(&DBTempTypes,&DBPlaneTypes[plane]);
  TTMaskClearType(&DBTempTypes,TT_SPACE);

  TTMaskCom2(&DBNonTempTypes, &DBTempTypes);
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBLayerTempReset
 *
 * clear temporary flag on layer.
 *
 * ----------------------------------------------------------------------------
 */

void
DBLayerTempReset(int plane)
{

  DBPlaneFlags[plane] &= ~DBF_TEMP;

  TTMaskClearMask(&DBTempTypes,&DBPlaneTypes[plane]);

  TTMaskCom2(&DBNonTempTypes, &DBTempTypes);
}

