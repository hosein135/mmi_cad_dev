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
 * DRCtech.c --
 *
 * Technology initialization for the DRC module.
 *
 * Copyright (C) 1985 Regents of the University of California
 * All rights reserved.
 */

#ifndef lint
static char rcsid[] = "$Header: DRCtech.c,v 4.16 92/08/03 18:06:49 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "magic.h"
#include "geometry.h"
#include "utils.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "drc.h"
#include "main.h"
#include "message.h"
#include "malloc.h"
#include "cif.h"
/* DEVIATION:  using cifInt.h in drc module. */
#include "cifInt.h"

/* m1 width exported for use as typical feature size */
int DRCm1Width = 0;

/*
 * Largest DRC interaction radius in the given technology
 */
global int TechHalo;
CIFStyle	*drcCifStyle=NULL;

/*
 * List of rules applicable for each possible pair of edges.
 */
global DRCCookie      * DRCRulesTbl [TT_MAXTYPES] [TT_MAXTYPES];

/* The paint table defined below is used when yanking paint for subcell
 * interaction checks.  It turns some kinds of overlaps into automatic
 * errors.
 */

global PaintResultType DRCPaintTable[NP][NT][NT];

/* The mask below defines tile types that are not permitted to overlap
 * themselves across cells unless the overlap is exact (each cell
 * contains exactly the same material).
 */

global TileTypeBitMask DRCExactOverlapTypes;

/* The following variable can be set to zero to turn off
 * any optimizations of design rule lists.
 * MHA TODO DEBUG:  fix area optimization and turn DRCRuleOptimization back on
 */

global int DRCRuleOptimization = FALSE;

/* The following variables count how many rules were specified by
 * the technology file and how many edge rules were optimized away.
 */

static int drcRulesSpecified = 0;
static int drcRulesOptimized = 0;

static int drcM1Type;

/*
 * Forward declarations.
 */
int drcWidth(int argc, char **argv), drcSpacing(int argc, char **argv), drcEdge(int argc, char **argv), drcNoOverlap(int argc, char **argv), drcExactOverlap(int argc, char **argv);
int drcStepSizeCmd(int argc, char **argv), drcRectangle(int argc, char **argv);
int drcSetCifStyle(int argc, char **argv),drcCifWidth(int argc, char **argv),drcCifSpacing(int argc, char **argv),drcCifEdge(int argc, char **argv);
int drcMaxwidth(int argc, char **argv),drcArea(int argc, char **argv);
int drcCifMaxwidth(int argc, char **argv),drcCifArea(int argc, char **argv);


/*
 * ----------------------------------------------------------------------------
 * drcDimension --
 *
 * Convert string to int.
 *
 * If string is int (no '.'), it is in DB units.
 *
 * If string is not int (has  '.') its in microns,
 * converted to microns using scale factor of drc cifstyle.
 *
 * On error, returns 1, since non-positive dimension may lead to coredump
 * ----------------------------------------------------------------------------
 */

static int drcDimension(char *s)
{
  int result;

  if(!strchr(s,'.'))
  {
    /* integer dimension (DB units) */
    char *tail;
    result = strtol(s, &tail, 10);
    if(*tail)
    {
      MnTechError("Bad DRC dimension: '%s'", s);
      return 1;
    }
    if(result <= 0)
    {
      MnTechError("Bad DRC dimension (must be positive): '%d'\n", 
		  result);
      return 1;
    }
    return result;
  }
  else
  {
    /* floating point dimension (microns) */
    char *tail;
    double d;
    double res;  
    
    if(!drcCifStyle)
    {
      MnTechError("DRC dimension in microns requires prior 'cifstyle' statemente: '%s'", s);
      return 1;
    }
    res = drcCifStyle->cs_DBRes;

    d = strtod(s, &tail);
    if(*tail)
    {
      MnTechError("Bad DRC dimension: '%s'", s);
      return 1;
    }

    result = ROUND(d/res);

    if(ABSDIFF(result*res,d) > UNIT_TOLERANCE)
    {
      MnTechError("DRC dimension %g not on %g design grid, approximating as %g\n",
		  d, res, result*res);
    }

    if(result*res <= 0)
    {
      MnTechError("Bad DRC dimension (must be positive): '%g'\n",
		  result*res);
      return 1;
    }      
    return result;
  }
}


/*
 * ----------------------------------------------------------------------------
 * drcDimension2 --
 *
 * Convert string to int (square dimension).
 *
 * If string is int (no '.'), it is in DB units**2.
 *
 * If string is floating point (has  '.') its in microns**2,
 * converted to microns using drc scale factor of drc output style.
 *
 * On error, returns 1, since non-positive dimension may lead to coredump
 * ----------------------------------------------------------------------------
 */

static int drcDimension2(char *s)
{
  int result;

  if(!strchr(s,'.'))
  {
    /* integer dimension (DB units) */
    char *tail;
    result = strtol(s, &tail, 10);
    if(*tail)
    {
      MnTechError("Bad DRC dimension: '%s'", s);
      return 1;
    }
    if(result <= 0)
    {
      MnTechError("Bad DRC dimension (must be positive): '%d'\n", 
		  result);
      return 1;
    }
    return result;
  }
  else
  {
    /* floating point dimension (microns) */
    char *tail;
    double d;
    double res;  

    if(!drcCifStyle)
    {
      MnTechError("DRC dimension in microns requires prior 'cifstyle' statement: '%s'", s);
      return 1;
    }
    res = drcCifStyle->cs_DBRes;

    d = strtod(s, &tail);
    if(*tail)
    {
      MnTechError("Bad DRC dimension: '%s'", s);
      return 1;
    }

    result = ROUND(d/(res*res));
    if(ABSDIFF(result*(res*res),d)> UNIT_TOLERANCE)
    {
      MnTechError("DRC square dimension %g not on %g design grid, approximating as %g\n",
		  d, res, result*res*res);
    }
    if(result*res*res <= 0)
    {
      MnTechError("Bad DRC dimension (must be positive): '%g'\n", 
		  result*res*res);
      return 1;
    }      
    return result;
  }
}


/*
 * ----------------------------------------------------------------------------
 * DRCTechInit --
 *
 * Initialize the technology-specific variables for the DRC module.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Clears out all the DRC tables.
 * ----------------------------------------------------------------------------
 */

int drcDebugOverlaps = FALSE;

Void
DRCTechInit(void)
{
    register int i, j, plane;
    register DRCCookie *dp;

    TechHalo = 0;
    drcRulesOptimized = 0;
    drcRulesSpecified = 0;
    TTMaskZero(&DRCExactOverlapTypes);

    /* m1 width exported as typical feature size */
    drcM1Type = DBTechNameType("m1");

    /* Remove all old rules from the DRC rules table and put a dummy
     * rule at the front of each list.
     */

    for (i = 0; i < TT_MAXTYPES; i++)
    {
	for (j = 0; j < TT_MAXTYPES; j++)
	{
	    for (dp = DRCRulesTbl[i][j]; dp != NULL; dp = dp->drcc_next)
	    {
		(void) StrDup (&(dp->drcc_why), (char *) NULL);
		FREE( (char *) dp );
	    }
	    MALLOC(DRCCookie *, dp, sizeof (DRCCookie));
	    dp->drcc_dist = -1;
	    dp->drcc_next = (DRCCookie *) NULL;
	    DRCRulesTbl[i][j] = dp;
	}
    }

    /* Copy the default paint table into the DRC paint table.  The DRC
     * paint table will be modified as we read the drc section.  Also
     * make sure that the error layer is super-persistent (once it
     * appears, it can't be gotten rid of by painting).  Also, make
     * some crossings automatically illegal:  two layers can't cross
     * unless the result of painting one on top of the other is to
     * get one of the layers, and it doesn't matter which is painted
     * on top of which.
     */
    
    for (plane = 0; plane < DBNumPlanes; plane++)
    {
	if (drcDebugOverlaps)
	    printf("Figuring DRC overlap errors on plane %s:\n", DBPlaneLongName(plane));
	for (i = 0; i < DBNumTypes; i++)
	    for (j = 0; j < DBNumTypes; j++)
	    {
		PaintResultType result = DBPaintResultTbl[plane][i][j];
		if ((i == TT_ERROR_S) || (j == TT_ERROR_S))
		    DRCPaintTable[plane][i][j] = TT_ERROR_S;
		else if ((i == TT_SPACE) 
			 || (j == TT_SPACE)
			 || (DBPlane(j) != plane)
			 || (!DBPlane(i) == DBPlane(j)))
		    DRCPaintTable[plane][i][j] = result;
		else if ((i!=result && j!=result)
			|| ((result != DBPaintResultTbl[plane][j][i])
			    && (DBPlane(i) == plane)
			    && DBPlane(j) == DBPlane(i)))
		{
		    DRCPaintTable[plane][i][j] = TT_ERROR_S;
		    if (drcDebugOverlaps) {
			char *iName, *jName, *rName;
			iName = DBTypeShortName(i);
			jName = DBTypeShortName(j);
			rName = DBTypeShortName(result);
			printf("    DRC overlap error:  %s over %s\n", 
			    iName, jName);
			printf("        reason:  ");
			if ((result != DBPaintResultTbl[plane][j][i])
			    && (DBPlane(i) == plane)
			    && DBPlane(j) == DBPlane(i)) {
			    printf("order-dependent painting:\n        %s + %s --> %s\n        %s + %s --> %s\n",
			    iName, jName, rName, jName, iName, 
			    DBTypeShortName(DBPaintResultTbl[plane][j][i]));
			}
		    }
		}
		else
		    DRCPaintTable[plane][i][j] = result;
	    }
    }
    drcCifInit();
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCTechAddRule --
 *
 * Add a new entry to the DRC table.
 *
 * Results:
 *	Always returns TRUE so that tech file read-in doesn't abort.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * Organization:
 *	We select a procedure based on the first keyword (argv[0])
 *	and call it to do the work of implementing the rule.  Each
 *	such procedure is of the following form:
 *
 *	int
 *	proc(argc, argv)
 *	    int argc;
 *	    char *argv[];
 *	{
 *	}
 *
 * 	It returns the distance associated with the design rule,
 *	or -1 in the event of a fatal error that should cause
 *	DRCTechAddRule() to return FALSE (currently, none of them
 *	do, so we always return TRUE).  If there is no distance
 *	associated with the design rule, 0 is returned.
 *
 * ----------------------------------------------------------------------------
 */

#define ASSIGN(cookie,dist,next,mask,corner,why,cdist,flags,plane) \
	((cookie)->drcc_dist = dist, \
	(cookie)->drcc_next = next, \
	(cookie)->drcc_mask = mask, \
	(cookie)->drcc_corner = corner, \
	(cookie)->drcc_why = StrDup ((char **) NULL, why), \
	(cookie)->drcc_cdist = cdist, \
	(cookie)->drcc_flags = flags, \
	(cookie)->drcc_plane = plane)

	/* ARGSUSED */
bool
DRCTechAddRule(char *sectionName, int argc, char **argv)
                      		/* Unused */
             
                 
{
    int which, distance;
    char *fmt;
    static struct
    {
	char	*rk_keyword;	/* Initial keyword */
	int	 rk_minargs;	/* Min # arguments */
	int	 rk_maxargs;	/* Max # arguments */
	int    (*rk_proc)();	/* Procedure implementing this keyword */
	char	*rk_err;	/* Error message */
    } ruleKeys[] = {
	"edge",		 8,	9,	drcEdge,
    "layers1 layers2 distance okTypes cornerTypes cornerDistance why [plane]",
	"edge4way",	 8,	9,	drcEdge,
    "layers1 layers2 distance okTypes cornerTypes cornerDistance why [plane]",
	"exact_overlap", 2,	2,	drcExactOverlap,
    "layers",
	"no_overlap",	 3,	3,	drcNoOverlap,
    "layers1 layers2",
	"spacing",	 6,	6,	drcSpacing,
    "layers1 layers2 separation adjacency why",
	"stepsize",	 2,	2,	drcStepSizeCmd,
    "step_size",
	"width",	 4,	4,	drcWidth,
    "layers width why",
        "area",		5,	5,	drcArea,
    "layers area horizon why",
        "maxwidth",	5,	5,	drcMaxwidth,
    "layers maxwidth bends why",
        "cifstyle",	 2,	2,	drcSetCifStyle,
    "cif_style",
        "cifedge",	 8,	9,	drcCifEdge,
    "layers1 layers2 distance okTypes cornerTypes cornerDistance why [plane]",
	"cifedge4way",	 8,	9,	drcCifEdge,
    "layers1 layers2 distance okTypes cornerTypes cornerDistance why [plane]",
	"cifwidth",	 4,	4,	drcCifWidth,
    "layers width why",
	"cifspacing",	 6,	6,	drcCifSpacing,
    "layers1 layers2 separation adjacency why",
        "cifarea",	 5,	5,	drcCifArea,
    "layers area horizon why",
        "cifmaxwidth",	5,	5,	drcCifMaxwidth,
    "layers maxwidth bends why",
	"rectangle",	5,	5,	drcRectangle,
    "layers maxwidth [even|odd|any] why",
	0
    }, *rp;

    drcRulesSpecified += 1;

    which = LookupStruct(argv[0], (LookupTable *) ruleKeys, sizeof ruleKeys[0]);
    if (which < 0)
    {
	MnTechError("Bad DRC rule type \"%s\"\n", argv[0]);
	MsgErrorF("Valid rule types are:\n");
	for (fmt = "%s", rp = ruleKeys; rp->rk_keyword; rp++, fmt = ", %s")
	    MsgErrorF(fmt, rp->rk_keyword);
	MsgErrorF(".\n");
	return (TRUE);
    }
    rp = &ruleKeys[which];
    if (argc < rp->rk_minargs || argc > rp->rk_maxargs)
    {
	MnTechError("Rule type \"%s\" usage: %s %s\n",
		rp->rk_keyword, rp->rk_keyword, rp->rk_err);
	return (TRUE);
    }

    distance = (*rp->rk_proc)(argc, argv);

    if(FALSE) /* DEBUG */
    {
      int i;

      fprintf(stderr,"DEBUG DRCTechAddRule, rule= \"");
      for(i=0; i<argc; i++) fprintf(stderr,"%s ", argv[i]);
      fprintf(stderr,"\" distance=%d\n",distance);
    }

    if (distance < 0)
	return (FALSE);

    /* Update the halo to be the maximum distance of any design rule */
    if (distance > TechHalo)
	TechHalo = distance;

    return (TRUE);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcWidth --
 *
 * Process a width rule.
 * This is of the form:
 *
 *	width layers distance why
 *
 * e.g,
 *
 *	width poly,pmc 2 "poly width must be at least 2"
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcWidth(int argc, char **argv)
{
    char *layers = argv[1];
    int distance = drcDimension(argv[2]);
    char *why = argv[3];
    TileTypeBitMask set, setC, tmp1;
    DRCCookie *dp, *dpnew;
    TileType i, j;
    int plane;

    DBTechNoisyNameMask(layers, &set);
    for (plane = PL_TECHDEPBASE; plane < DBNumPlanes; plane++)
	if (DBTechSubsetLayers(set, DBPlaneTypes[plane], &tmp1))
	    goto widthOK;
    MnTechError("All layers for \"width\" must be on same plane\n");
    return (0);

widthOK:
    if(drcM1Type>=0 && TTMaskHasType(&set,drcM1Type)) DRCm1Width = distance;

    set = tmp1;
    TTMaskCom2(&setC, &set);

    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    /*
	     * Must have types in 'set' for at least 'distance'
	     * to the right of any edge between a type in '~set'
	     * and a type in 'set'.
	     */
	    if (SamePlane(i, j)
		    && TTMaskHasType(&setC, i) && TTMaskHasType(&set, j))
	    {
		/* find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl [i][j];
			 dp->drcc_next != (DRCCookie *) NULL &&
			 dp->drcc_next->drcc_dist < distance;
			     dp = dp->drcc_next)
		    ; /* null body */

		MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		ASSIGN(dpnew, distance, dp->drcc_next, set, set, why,
			    distance, DRC_FORWARD, plane);

		dp->drcc_next = dpnew;
	    }
	}
    }

    return (distance);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcArea --
 *
 * Process an area rule.
 * This is of the form:
 *
 *	area layers nn horizon why
 *
 * e.g,
 *
 *	area pmc 4 "poly contact area must be at least 4"
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcArea(int argc, char **argv)
{
    char *layers = argv[1];
    int nn = drcDimension2(argv[2]);
    int	minWidth = drcDimension(argv[3]);
    int horizon;
    char *why = argv[4];
    TileTypeBitMask set, setC, tmp1;
    DRCCookie *dp, *dpnew;
    TileType i, j;
    int plane;

    /* horizon = amount of context needed to check this rule properly. */ 
    horizon = (nn + minWidth - 1) / minWidth;

    DBTechNoisyNameMask(layers, &set);
    for (plane = PL_TECHDEPBASE; plane < DBNumPlanes; plane++)
	if (DBTechSubsetLayers(set, DBPlaneTypes[plane], &tmp1))
	    goto widthOK;
    MnTechError("All layers for \"area\" must be on same plane\n");
    return (0);

widthOK:
    set = tmp1;
    TTMaskCom2(&setC, &set);

    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    /*
	     * Must have types in 'set' for at least 'distance'
	     * to the right of any edge between a type in '~set'
	     * and a type in 'set'.
	     */
	    if (SamePlane(i, j)
		    && TTMaskHasType(&setC, i) && TTMaskHasType(&set, j))
	    {
		/* find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl [i][j];
			 dp->drcc_next != (DRCCookie *) NULL &&
			 dp->drcc_next->drcc_dist < horizon;
			     dp = dp->drcc_next)
		    ; /* null body */

		MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		ASSIGN(dpnew, horizon, dp->drcc_next, set, set, why,
			    nn, DRC_AREA|DRC_FORWARD, plane);

		dp->drcc_next = dpnew;
	    }
	}
    }

    return (horizon);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcMaxwidth --
 *
 * Process a maxwidth rule.
 * This is of the form:
 *
 *	maxwidth layers distance bends why
 *
 * e.g,
 *
 *	maxwidth pmc 4 bend_illegal "poly contact area must be at least 4"
 *	maxwidth trench 4 bend_ok "poly contact area must be at least 4"
 *
 *      bend_illegal - means that one_dimension must be distance for any 
 *  		point in the region.  This is used for emitters and contacts
 *		that are rectangular (so we can't generate them with the
 *		squares command) and some exact width in one direction.
 *	bend_ok - used for things like trench, where the width is some fixed
 *		value:
 *
 *			XXXXX		XXXXXX
 *			X   X		XXXXXX
 *			X   X		X    X
 *			XXXXX		XXXXXX
 *			
 *			 OK		 BAD		
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcMaxwidth(int argc, char **argv)
{
    char *layers = argv[1];
    int distance = drcDimension(argv[2]);
    char *bends = argv[3];
    char *why = argv[4];
    TileTypeBitMask set, setC, tmp1;
    DRCCookie *dp, *dpnew;
    TileType i, j;
    int plane;
    int bend;

    DBTechNoisyNameMask(layers, &set);
    for (plane = PL_TECHDEPBASE; plane < DBNumPlanes; plane++)
	if (DBTechSubsetLayers(set, DBPlaneTypes[plane], &tmp1))
	    goto widthOK;
    MnTechError("All layers for \"area\" must be on same plane\n");
    return (0);

widthOK:
    if (strcmp(bends,"bend_illegal") == 0) bend =0;
    else if (strcmp(bends,"bend_ok") == 0) bend =DRC_BENDS;
    else
    {
    	 MnTechError("unknown bend option %s\n",bends);
	 return (0);
    }
    set = tmp1;
    TTMaskCom2(&setC, &set);

    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    /*
	     * Must have types in 'set' for at least 'distance'
	     * to the right of any edge between a type in '~set'
	     * and a type in 'set'.
	     */
	    if (SamePlane(i, j)
		    && TTMaskHasType(&setC, i) && TTMaskHasType(&set, j))
	    {
		/* find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl [i][j];
			 dp->drcc_next != (DRCCookie *) NULL &&
			 dp->drcc_next->drcc_dist < distance;
			     dp = dp->drcc_next)
		    ; /* null body */

		MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		ASSIGN(dpnew, distance, dp->drcc_next, set, set, why,
			    distance, DRC_MAXWIDTH|bend, plane);

		dp->drcc_next = dpnew;
	    }
	}
    }

    return (distance);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcSpacing --
 *
 * Process a spacing rule.
 * This is of the form:
 *
 *	spacing layers1 layers2 distance adjacency why
 *
 * e.g,
 *
 *	spacing metal,pmc/m,dmc/m metal,pmc/m,dmc/m 4 touching_ok \
 *		"metal spacing must be at least 4"
 *
 * Adjacency may be either "touching_ok" or "touching_illegal"
 * In the first case, no violation occurs when types in layers1 are
 * immediately adjacent to types in layers2.  In the second case,
 * such adjacency causes a violation.
 *
 * Results:
 *	Returns distance.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcSpacing(int argc, char **argv)
{
    char *layers1 = argv[1], *layers2 = argv[2];
    int distance = drcDimension(argv[3]);
    char *adjacency = argv[4];
    char *why = argv[5];
    TileTypeBitMask set1, set2, tmp1, tmp2, setR, setRreverse;
    int plane1, plane2, plane, curPlane;
    DRCCookie *dp, *dpnew;
    int needReverse = FALSE;
    TileType i, j;

    DBTechNoisyNameMask(layers1, &set1);
    DBTechNoisyNameMask(layers2, &set2);

    /* what plane(s) are we on ? */
    plane1 = 0;
    for (i = TT_SELECTBASE; i < DBNumTypes; i++)
    {
      if (!TTMaskHasType(&set1, i)) continue;
	  
      if(!plane1)
      {
	plane1 = DBPlane(i);
      }
      else
      {
	if(plane1 != DBPlane(i))
	{
	    MnTechError(
		"First set of layers in spacing check not all on same plane.\n");
	    return (0);
	}
      }
    }
    plane2 = 0;
    for (i = TT_SELECTBASE; i < DBNumTypes; i++)
    {
      if (!TTMaskHasType(&set1, i)) continue;
	  
      if(!plane2)
      {
	plane2 = DBPlane(i);
      }
      else
      {
	if(plane2 != DBPlane(i))
	{
	    MnTechError(
		"Second set of layers in spacing check not all on same plane.\n");
	    return (0);
	}
      }
    }

    /* common plane? */
    plane = 0;
    if(plane1 == plane2) plane = plane1;

    if (strcmp (adjacency, "touching_ok") == 0)
    {
	/* If touching is OK, everything must fall in the same plane. */
	if (!plane)
	{
	    MnTechError(
		"Spacing check with touching ok must all be in one plane.\n");
	    return (0);
	}

	/* In "touching_ok rules, spacing to set2  is be checked in FORWARD 
	 * direction at edges between set1 and  (setR = ~set1 AND ~set2).
	 *
	 * In addition, spacing to set1 is checked in FORWARD direction 
	 * at edges between set2 and (setRreverse = ~set1 AND ~set2).
	 *
	 * If set1 and set2 are different, above are checked in REVERSE as
	 * well as forward direction.  This is important since touching
	 * material frequently masks violations in one direction.
	 *
	 * setR and setRreverse are set appropriately below.
	 */

	tmp1 = set1;
	tmp2 = set2; 

	plane1 = plane2 = plane;
	TTMaskCom(&tmp1);
	TTMaskCom(&tmp2);
	TTMaskAndMask(&tmp1, &tmp2);
	setR = tmp1;
	setRreverse = tmp1;

	/* If set1 = set2, set flag to check rules in both directions */
	if (!TTMaskEqual(&set1, &set2))
	    needReverse = TRUE;
    }
    else if (strcmp (adjacency, "touching_illegal") == 0)
    {
	/* If touching is illegal, set1 and set2 should not intersect 
	 * (adjacencies between types on the same plane would be missed)
	 */
	if (TTMaskIntersect(&set1, &set2))
	{
	    MnTechError(
		"Spacing check with touching illegal must be between non intersecting type lists.\n");
	    return (0);
	}

	/* In "touching_illegal rules, spacing to set2 will be checked
	 * in FORWARD 
	 * direction at edges between set1 and (setR=~set1). 
	 *
	 * In addition, spacing to set1 will be checked in FORWARD direction
	 * at edges between set2 and (setRreverse=  ~set2).
	 *
	 * setR and setRreverse are set appropriately below.
	 */
	TTMaskCom2(&setR, &set1);
	TTMaskCom2(&setRreverse, &set2);
    }
    else
    {
	MnTechError("Badly formed drc spacing line\n");
	return (0);
    }

    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    if (i == j || !SamePlane(i, j)) continue;

	    /* LHS is an element of set1, RHS is an element of setR */
	    if (TTMaskHasType(&set1, i) && TTMaskHasType(&setR, j))
	    {
		/*
		 * Must not have 'set2' for 'distance' to the right of
		 * an edge between 'set1' and the types not in 'set1'
		 * (touching_illegal case) or in neither
		 * 'set1' nor 'set2' (touching_ok case).
		 */

		/* Find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl [i][j];
			 dp->drcc_next != (DRCCookie *) NULL &&
			 dp->drcc_next->drcc_dist < distance;
			     dp = dp->drcc_next)
		    ; /* null body */
		
		/* May have to insert several buckets on different planes */
		curPlane = plane2;
		{
		    MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		    TTMaskClearMask3(&tmp1, &DBPlaneTypes[curPlane], &set2);
		    TTMaskAndMask3(&tmp2, &DBPlaneTypes[curPlane], &setR);
		    ASSIGN(dpnew, distance, dp->drcc_next,
			tmp1, tmp2, why, distance, DRC_FORWARD, curPlane);

		    if (i == TT_SPACE)
		    {
			if (curPlane != DBPlane(j))
			    dpnew->drcc_flags |= DRC_XPLANE;
		    }
		    else
		    {
			if (curPlane != DBPlane(i))
			    dpnew->drcc_flags |= DRC_XPLANE;
		    }
		    
		    if (needReverse)
		        dpnew->drcc_flags |= DRC_BOTHCORNERS;

		    dp->drcc_next = dpnew;

		    if (needReverse)
		    {
			/* Add check in reverse direction, 
			 * NOTE:  am assuming single plane rule here (since reverse
			 * rules only used with touching_ok which must be 
			 * single plane)
			 * so am not setting DRC_XPLANE as above.
			 * /
			 
			 /* find bucket preceding new one we wish to insert */
			 for (dp = DRCRulesTbl [j][i];
			          dp->drcc_next != (DRCCookie *) NULL &&
   			          dp->drcc_next->drcc_dist < distance;
			          dp = dp->drcc_next)
			     ; /* null body */
			 
			 MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
			 ASSIGN(dpnew,distance,dp->drcc_next,
				tmp1, tmp2, why, distance, 
				DRC_REVERSE|DRC_BOTHCORNERS, curPlane);
			 
			 dp->drcc_next = dpnew;
		     }
		}
	    }

	    /*
	     * Now, if set1 and set2 are distinct apply the rule for LHS in set1
	     * and RHS in set2.
	     */
	    if (TTMaskEqual(&set1, &set2)) continue;

	    /* LHS is an element of set2, RHS is an element of setRreverse */
	    if (TTMaskHasType(&set2, i) && TTMaskHasType(&setRreverse, j))
	    {
		/* Find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl [i][j];
			 dp->drcc_next != (DRCCookie *) NULL &&
			 dp->drcc_next->drcc_dist < distance;
			     dp = dp->drcc_next)
		    ; /* null body */

		curPlane = plane1;
		{
		    MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		    TTMaskClearMask3(&tmp1,&DBPlaneTypes[curPlane],&set1);
		    TTMaskAndMask3(&tmp2,&DBPlaneTypes[curPlane],&setRreverse);
		    ASSIGN(dpnew, distance, dp->drcc_next,
			tmp1, tmp2, why, distance, DRC_FORWARD, curPlane);

		    if (i == TT_SPACE)
		    {
			if (curPlane != DBPlane(j))
			    dpnew->drcc_flags |= DRC_XPLANE;
		    }
		    else
		    {
			if (curPlane != DBPlane(i))
			    dpnew->drcc_flags |= DRC_XPLANE;
		    }

		    if (needReverse)
		        dpnew->drcc_flags |= DRC_BOTHCORNERS;

		    dp->drcc_next = dpnew;		    

		    if (needReverse)
		    {
			/* Add check in reverse direction, 
			 * NOTE:  am assuming single plane rule here (since reverse
			 * rules only used with touching_ok which must be 
			 * single plane)
			 * so am not setting DRC_XPLANE as above.
			 * /
			 
			 /* find bucket preceding new one we wish to insert */
			 for (dp = DRCRulesTbl [j][i];
			          dp->drcc_next != (DRCCookie *) NULL &&
   			          dp->drcc_next->drcc_dist < distance;
			          dp = dp->drcc_next)
			     ; /* null body */
			 
			 MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
			 ASSIGN(dpnew,distance,dp->drcc_next,
				tmp1, tmp2, why, distance, 
				DRC_REVERSE|DRC_BOTHCORNERS, curPlane);
			 
			 dp->drcc_next = dpnew;
		     }
		}
	    }

	    /* Finally, if multiplane rule then check that set2 types
	     * are not present just to right of edges with setR on LHS
	     * and set1 on RHS.  This check is necessary to make sure
	     * that a set1 rectangle doesn't coincide exactly with a
	     * set2 rectangle.  
	     * (This check added by Michael Arnold on 4/10/86.)
	     */

	    /* If not cross plane rule, check does not apply */
	    if (plane) continue; 

	    /* LHS is an element of setR, RHS is an element of set1 */
	    if (TTMaskHasType(&setR, i) && TTMaskHasType(&set1, j))
	    {
		/*
		 * Must not have 'set2' for 'distance' to the right of
		 * an edge between the types not in set1 and set1.
		 * (is only checked for cross plane rules - these are
		 * all of type touching_illegal)
		 */

		/* Walk list to last check.  New checks ("cookies") go
		 * at end of list since we are checking for distance of
		 * 1 and the list is sorted in order of decreasing distance.
		 */
		for (dp = DRCRulesTbl [i][j];
		     dp->drcc_next != (DRCCookie *) NULL;
		     dp = dp->drcc_next)
		    ; /* null body */

		/* Insert one check for each plane involved in set2 */
		curPlane = plane2;  
		{
		    /* filter out checks that are not cross plane */
		    if (i == TT_SPACE) 
		    {
			if (curPlane == DBPlane(j))
			    continue;
		    }
		    else
		    {
			if (curPlane == DBPlane(i))
			    continue;
		    }

		    /* create new check and add it to list */
		    MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		    TTMaskClearMask3(&tmp1, &DBPlaneTypes[curPlane], &set2);
		    TTMaskZero(&tmp2);
		    ASSIGN(dpnew, 1, dp->drcc_next,
			tmp1, tmp2, why, distance, 
			DRC_FORWARD | DRC_XPLANE, curPlane);
		    dp->drcc_next = dpnew;
		}
	    }
	}
    }

    return (distance);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcEdge --
 *
 * Process a primitive edge rule.
 * This is of the form:
 *
 *	edge layers1 layers2 dist OKtypes cornerTypes cornerDist why [plane]
 * or	edge4way layers1 layers2 dist OKtypes cornerTypes cornerDist why [plane]
 *
 * e.g,
 *
 *	edge poly,pmc s 1 diff poly,pmc "poly-diff separation must be 2"
 *
 * An "edge" rule is applied only down and to the left.
 * An "edge4way" rule is applied in all four directions.
 *
 * Results:
 *	Returns greater of dist and cdist.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

int drcEdge(int argc, char **argv)
{
    char *layers1 = argv[1], *layers2 = argv[2];
    int distance = drcDimension(argv[3]);
    char *okTypes = argv[4], *cornerTypes = argv[5];
    int cdist = (*cornerTypes=='0') ? 1 : drcDimension(argv[6]);
    char *why = argv[7];
    bool fourway = (strcmp(argv[0], "edge4way") == 0);
    TileTypeBitMask set1, set2, tmp1, tmp2, tmp3, setC, setM;
    DRCCookie *dp, *dpnew;
    int plane, checkPlane;
    TileType i, j;
    unsigned k = (distance != 0)?0:DRC_ZEROSPACERULE;

    /* crude hack to implement zero spacing rule.  If distance is zero,
       set the DRC_SEROSPACERULE flag and reset it to 1. areaCheck should
       do the rest.
    */
    if (distance == 0) 
    {
    	 distance=1;
    }
    /*
     * Edge4way rules produce [j][i] entries as well as [i][j]
     * ones, and check both corners rather than just one corner.
     */
    DBTechNoisyNameMask(layers1, &set1);
    DBTechNoisyNameMask(layers2, &set2);

    /*
     * Make sure that all edges between the two sets can be
     * found on one plane.
     */
    for (plane = PL_TECHDEPBASE; plane < DBNumPlanes; plane++)
    {
	if (DBTechSubsetLayers(set1, DBPlaneTypes[plane], &tmp1)
	    && DBTechSubsetLayers(set2, DBPlaneTypes[plane], &tmp2))
	    goto edgeOK;
    }
    MnTechError("All edges in edge rule must lie in one plane.\n");
    return (0);

edgeOK:
    set1 = tmp1;
    set2 = tmp2;

    /* Give warning if types1 and types2 intersect */
    if(TTMaskIntersect(&set1,&set2))
    {
	MnTechError("Warning:  types1 and types2 have nonempty intersection.  DRC does not check edges with the same type on both sides.\n");
    }

    DBTechNoisyNameMask(cornerTypes, &tmp3);
    if (!DBTechSubsetLayers(tmp3, DBPlaneTypes[plane], &setC))
    {
	MnTechError("Corner types aren't in same plane as edges.\n");
	return (0);
    }

    checkPlane = plane;
    if (argc == 9)
    {
	checkPlane = DBTechNoisyNamePlane(argv[8]);
	if (checkPlane < 0)
	    return (0);
    }

    DBTechNoisyNameMask(okTypes, &setM);
    if (!DBTechSubsetLayers(setM, DBPlaneTypes[checkPlane], &setM))
    {
	MnTechError("OK types aren't all in the right plane.\n");
	return (0);
    }

    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    if (TTMaskHasType(&set1, i) && TTMaskHasType(&set2, j))
	    {
		/* Find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl [i][j];
		    dp->drcc_next != (DRCCookie *) NULL &&
		    dp->drcc_next->drcc_dist < distance;
			dp = dp->drcc_next)
		    ; /* null body */

		MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		ASSIGN(dpnew, distance, dp->drcc_next,
		    setM, setC, why, cdist, DRC_FORWARD|k, checkPlane);
		if (fourway) dpnew->drcc_flags |= DRC_BOTHCORNERS;
		if (checkPlane != plane)
		    dpnew->drcc_flags |= DRC_XPLANE;
		dp->drcc_next = dpnew;

		if (fourway)
		{
		    /* find bucket preceding new one we wish to insert */
		    for (dp = DRCRulesTbl [j][i];
			dp->drcc_next != (DRCCookie *) NULL &&
			dp->drcc_next->drcc_dist < distance;
			    dp = dp->drcc_next)
			; /* null body */

		    MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		    ASSIGN(dpnew,distance,dp->drcc_next,
			    setM, setC, why, cdist, DRC_REVERSE|k, checkPlane);
		    dpnew->drcc_flags |= DRC_BOTHCORNERS;
		    if (checkPlane != plane)
			dpnew->drcc_flags |= DRC_XPLANE;
		    dp->drcc_next = dpnew;
		}
	    }
	}
    }

    return (MAX(distance, cdist));
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcNoOverlap --
 *
 * Process a no-overlap rule.
 * This is of the form:
 *
 *	no_overlap layers1 layers2
 *
 * e.g,
 *
 *	no_overlap poly m2contact
 *
 * Results:
 *	Returns 0.
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcNoOverlap(int argc, char **argv)
{
    char *layers1 = argv[1], *layers2 = argv[2];
    TileTypeBitMask set1, set2;
    TileType i, j;
    int plane;

    /*
     * Grab up two sets of tile types, and make sure that if
     * any type from one set is painted over any type from the
     * other, then an error results.
     */

    DBTechNoisyNameMask(layers1, &set1);
    DBTechNoisyNameMask(layers2, &set2);

    for (i = 0; i < DBNumTypes; i++)
	for (j = 0; j < DBNumTypes; j++)
	    if (TTMaskHasType(&set1, i) && TTMaskHasType(&set2, j))
		for (plane = 0; plane < DBNumPlanes; plane++)
		{
		    DRCPaintTable[plane][j][i] = TT_ERROR_S;
		    DRCPaintTable[plane][i][j] = TT_ERROR_S;
		}

    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcExactOverlap --
 *
 * Process an exact overlap
 * This is of the form:
 *
 *	exact_overlap layers
 *
 * Results:
 *	Returns 0.
 *
 * Side effects:
 *	Updates DRCExactOverlapTypes.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcExactOverlap(int argc, char **argv)
{
    char *layers = argv[1];
    TileTypeBitMask set;


    /*
     * Grab up a bunch of tile types, and remember these: tiles
     * of these types cannot overlap themselves in different cells
     * unless they overlap exactly.
     */

    DBTechNoisyNameMask(layers, &set);
    TTMaskSetMask(&DRCExactOverlapTypes, &set);

    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcRectangle --
 *
 * Process a rectangle rule.  This is of the form:
 *
 *	rectangle layers maxwidth [even|odd|any] why
 *
 * The rule checks to make sure that the region is rectangular and that the
 * width and length are even or odd, as specified.  These two criteria ensure 
 * that the squares rule of * the cifout section can properly produce via 
 * holes without misaligning them between cells and without putting the via 
 * holes off grid.  The maxwidth is required to make the extent of this rule
 * a finite size, so that we can set the DRChalo to something finite.
 *
 * Results:
 *	maxwidth
 *
 * Side effects:
 *	Updates the DRC technology variables.
 *
 * ----------------------------------------------------------------------------
 */

int drcRectangle(int argc, char **argv)
{
    char *layers = argv[1];
    char *why = argv[4];
    TileTypeBitMask set, types, nottypes;
    int maxwidth;
    static char *drcRectOpt[4] = {"any", "even", "odd", 0};
    int i, j, even, plane;

    /* parse arguments */
    DBTechNoisyNameMask(layers, &set);
    if (sscanf(argv[2], "%d", &maxwidth) != 1) {
	MnTechError("bad maxwidth in rectangle rule");
	return 0;
    }
    even = Lookup(argv[3], drcRectOpt);
    if (even < 0) {
	MnTechError("bad [even|odd|any] selection in rectangle rule");
	return 0;
    }
    even--;  /* -1: any, 0: even, 1: odd */
    for (plane = PL_TECHDEPBASE; plane < DBNumPlanes; plane++) {
	if (DBTechSubsetLayers(set, DBPlaneTypes[plane], &types)) break;
    }
    if (plane == DBNumPlanes) {
	MnTechError("Layers in rectangle rule must lie in a single plane.");
	return 0;
    }
    TTMaskCom2(&nottypes, &types);
    TTMaskAndMask(&nottypes, &DBPlaneTypes[plane]);

    /* Install 2 edge rules: one that checks rectangle-ness, and one that
     * checks size
     */
    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    if (TTMaskHasType(&types, i) && TTMaskHasType(&nottypes, j))
	    {
		DRCCookie *dp, *dpnew;

		/* 
		 * A rule that checks rectangle-ness. 
		 *   left:  oktypes, right: other types
		 * This rule needs to be checked in all 4 directions
		 */
		int distance = 1;

		/* Find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl[i][j];
		    dp->drcc_next != (DRCCookie *) NULL &&
		    dp->drcc_next->drcc_dist < distance;
			dp = dp->drcc_next)
		    ; /* null body */

		MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		ASSIGN(dpnew, distance, dp->drcc_next, 
		    nottypes, DBAllTypeBits, why, distance, 
		    DRC_FORWARD, plane);
		dp->drcc_next = dpnew;

		/* Find bucket preceding the new one we wish to insert */
		for (dp = DRCRulesTbl[j][i];  /* note: j, i not i, j */
		    dp->drcc_next != (DRCCookie *) NULL &&
		    dp->drcc_next->drcc_dist < distance;
			dp = dp->drcc_next)
		    ; /* null body */

		MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		ASSIGN(dpnew, distance, dp->drcc_next, 
		    nottypes, DBAllTypeBits, why, distance, 
		    DRC_REVERSE, plane);
		dp->drcc_next = dpnew;

		if (maxwidth > 0) {
		    /* 
		     * A rule that checks size.
		     *   left:  other types, right: oktypes
		     */
		    distance = maxwidth;

		    for (dp = DRCRulesTbl[j][i];  /* note: j, i not i, j */
			dp->drcc_next != (DRCCookie *) NULL &&
			dp->drcc_next->drcc_dist < distance;
			    dp = dp->drcc_next)
			; /* null body */

		    MALLOC(DRCCookie *, dpnew, sizeof (DRCCookie));
		    ASSIGN(dpnew, distance, dp->drcc_next, 
			types, DBZeroTypeBits, why, even, 
			DRC_RECTSIZE, plane);
		    dp->drcc_next = dpnew;
		}
	    }
	}
    }
    return maxwidth;
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcStepSizeCmd --
 *
 * Process a declaration of the step size.
 * This is of the form:
 *
 *	stepsize step_size
 *
 * e.g,
 *
 *	stepsize 1000
 *
 * OBSOLETE:  JUST PRINTS WARNING MESSAGE.
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcStepSizeCmd(int argc, char **argv)
{
  MnTechError("Warning:  DRC 'stepsize' ignored"
	      " (see tcl variable DRC_STEP_SIZE)\n");
  return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * drcSetCifStyle --
 *
 * Process a declaration of the cif style.
 * This is of the form:
 *
 *	cifstyle cif_style
 *
 * e.g,
 *
 *	cifstyle pg
 *
 * Results:
 *	Returns 0.
 *
 * Side effects:
 *	Updates drcCifStyle
 *
 * ----------------------------------------------------------------------------
 */

    /*ARGSUSED*/
int drcSetCifStyle(int argc, char **argv)
{
    CIFStyle	*new;
    
    for (new = CIFStyleList; new != NULL; new = new->cs_next)
    {
    	 if (strcmp(new->cs_name,argv[1]) == 0)
	 {
	          drcCifStyle = new;
		  return 0;
	 }
    }
    MnTechError("Unknown DRC cifstyle %s\n",argv[1]);
    return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCTechFinal --
 *
 * Called after all lines of the drc section in the technology file have been
 * read.  The preliminary DRC Rules Table is pruned by removing rules covered
 * by other (longer distance) rules, and by removing the dummy rule at the
 * front of each list.  Where edges are completely illegal, the rule list is
 * pruned to a single rule.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May remove DRCCookies from the linked lists of the DRCRulesTbl.
 *
 * ----------------------------------------------------------------------------
 */

Void
DRCTechFinal(void)
{
    TileTypeBitMask tmpMask, nextMask;
    DRCCookie  *dummy, *dp, *next;
    DRCCookie **dpp, **dp2back;
    TileType i, j;

    /* Remove dummy buckets */
    for (i = 0; i < TT_MAXTYPES; i++)
    {
	for (j = 0; j < TT_MAXTYPES; j++)
	{
	    dpp = &( DRCRulesTbl [i][j]);
	    dummy = *dpp;
	    *dpp = dummy->drcc_next;
	    FREE ((char *) dummy); 	/* "why" string is null */
	}
    }

    drcCifFinal();

    if (!DRCRuleOptimization) return;

    /* Check for edges that are completely illegal.  Where this is the
     * case, eliminate all of the edge's rules except one.
     */
    
    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    DRCCookie *keep = NULL;
	    
	    for (dp = DRCRulesTbl[i][j]; dp != NULL; dp = dp->drcc_next)
	    {
		if (dp->drcc_flags & DRC_XPLANE) continue;
		/* the old code had a break here; I don't see why we 
		   can just continue.  -dcs 12/05/90 

		if (dp->drcc_flags & DRC_WEIRDONES) break;
                */
		if (dp->drcc_flags & DRC_WEIRDONES) continue;
		if (dp->drcc_flags & DRC_REVERSE)
		{
		    if (TTMaskHasType(&dp->drcc_mask, i)) continue;
		}
		else if (TTMaskHasType(&dp->drcc_mask, j)) continue;
		keep = dp;
		goto illegalEdge;
	    }
	    continue;

	    /* This edge is illegal.  Throw away all rules except the one
	     * needed that is always violated.
	     */
	    
	    illegalEdge:
	    for (dp = DRCRulesTbl[i][j]; dp != NULL; dp = dp->drcc_next)
	    {
		if (dp == keep) continue;
		(void) StrDup(&(dp->drcc_why), (char *) NULL);
		FREE((char *) dp);
		drcRulesOptimized += 1;
	    }
	    DRCRulesTbl[i][j] = keep;
	    keep->drcc_next = NULL;
	    /* MsgInfoF("Edge %s-%s is illegal.\n", DBTypeShortName(i),
		DBTypeShortName(j));
	    */
	}
    }

    /*
     * Remove any rule A "covered" by another rule B, i.e.,
     *		B's distance >= A's distance,
     *		B's corner distance >= A's corner distance,
     *		B's RHS type mask is a subset of A's RHS type mask, and
     *		B's corner mask == A's corner mask
     *		B's check plane == A's check plane
     *		either both A and B or neither is a REVERSE direction rule
     *		if A is BOTHCORNERS then B must be, too
     */

    for (i = 0; i < DBNumTypes; i++)
    {
	for (j = 0; j < DBNumTypes; j++)
	{
	    for (dp = DRCRulesTbl[i][j]; dp != NULL; dp = dp->drcc_next)
	    {
		/*
		 * Check following buckets to see if any is a superset.
		 */
		if (dp->drcc_flags & DRC_WEIRDONES) continue;
		
		for (next = dp->drcc_next; next != NULL;
			next = next->drcc_next)
		{
		    tmpMask = nextMask = next->drcc_mask;
		    TTMaskAndMask(&tmpMask, &dp->drcc_mask);
		    if (!TTMaskEqual(&tmpMask, &nextMask)) continue;
		    if (!TTMaskEqual(&dp->drcc_corner, &next->drcc_corner))
			continue;
		    if (dp->drcc_dist > next->drcc_dist) continue;
		    if (dp->drcc_cdist > next->drcc_cdist) continue;
		    if (dp->drcc_plane != next->drcc_plane) continue;
		    if (dp->drcc_flags & DRC_REVERSE)
		    {
			if (!(next->drcc_flags & DRC_REVERSE)) continue;
		    }
		    else if (next->drcc_flags & DRC_REVERSE) continue;
		    if ((next->drcc_flags & DRC_BOTHCORNERS)
			    && (dp->drcc_flags & DRC_BOTHCORNERS) == 0)
			continue;

		    break;
		}

		if (next == NULL) continue;

		/* "dp" is a subset of "next".  Eliminate it. */

		/* MsgInfoF("For edge %s-%s, \"%s\" covers \"%s\"\n",
		    DBTypeShortName(i), DBTypeShortName(j),
		    next->drcc_why, dp->drcc_why);
		*/
		dp2back = &(DRCRulesTbl [i][j]);
		while (*dp2back != dp)
		    dp2back = &(*dp2back)->drcc_next;
		*dp2back = dp->drcc_next;
		(void) StrDup (&(dp->drcc_why), (char *) NULL);
		FREE ((char *) dp);
		drcRulesOptimized += 1;
	    }
	}
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * DRCTechRuleStats --
 *
 * 	Print out some statistics about the design rule database.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A bunch of stuff gets printed on the terminal.
 *
 * ----------------------------------------------------------------------------
 */

void
DRCTechRuleStats(void)
{
#define MAXBIN 10
    int counts[MAXBIN+1];
    int edgeRules, overflow;
    int i, j;
    DRCCookie *dp;

    /* Count up the total number of edge rules, and histogram them
     * by the number of rules per edge.
     */
    
    edgeRules = 0;
    overflow = 0;
    for (i=0; i<=MAXBIN; i++) counts[i] = 0;

    for (i=0; i<DBNumTypes; i++)
	for (j=0; j<DBNumTypes; j++)
	{
	    int thisCount = 0;
	    for (dp = DRCRulesTbl[i][j]; dp != NULL; dp = dp->drcc_next)
		thisCount++;
	    edgeRules += thisCount;
	    if ((i != TT_SPACE) && (j != TT_SPACE) &&
		(DBPlane(i) != DBPlane(j))) continue;
	    if (thisCount <= MAXBIN) counts[thisCount] += 1;
	    else overflow += 1;
	}
    
    /* Print out the results. */

    MsgInfoF("Total number of rules specifed in tech file: %d\n",
	drcRulesSpecified);
    MsgInfoF("Edge rules optimized away: %d\n", drcRulesOptimized);
    MsgInfoF("Edge rules left in database: %d\n", edgeRules);
    MsgInfoF("Histogram of # edges vs. rules per edge:\n");
    for (i=0; i<=MAXBIN; i++)
    {
	MsgInfoF("  %2d rules/edge: %d.\n", i, counts[i]);
    }
    MsgInfoF(" >%2d rules/edge: %d.\n", MAXBIN, overflow);
}
