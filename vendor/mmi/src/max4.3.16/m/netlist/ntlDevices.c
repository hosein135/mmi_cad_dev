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
 * ntlDevices.c --
 *
 * Routines for device definition, extraction and output.  
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
static char sccsid[] = "@(#)ntlTrans.c	4.13 MAGIC (Berkeley) 12/5/85";
#endif  not lint

#include <stdio.h>
#include <math.h>
#include "magic.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "memory.h"
#include "message.h"
#include "debug.h"
#include "netlistInt.h"
#include "netlist.h"
#include "signals.h"
#include "layout.h"
#include "layout.h"
#include "styles.h"
#include "stack.h"
#include "cif.h"


/* DEVICE DEFINITIONS */

/* fet gate types */
static TileTypeBitMask ntlTransMask;

/* source/drain terminal type(s), indexed by gate type */
static TileTypeBitMask ntlTransSDTypesTbl[NT];

/* substrate node type(s), indexed by gate type */
static TileTypeBitMask	 ntlTransSubstrateTypesTbl[NT];

/* table of fet names (by gate type) */ 
static char *ntlTransNameTbl[NT];

/* default substrate node name, indexed by gate type */
static char *ntlTransSubstrateDefaultNodeNameTbl[NT];


/* CURRENT DEVICE */
/* (info on device currently being extracted) */

/* maximum number of source/drain terminals */
#define MAXSD 2

/* Number of source/drain terminals in this device */
int ntlDevCurNumSD;		

/* Perimeter of connection to gate */
int ntlDevCurGateLength;      

/* Node region for gate terminal */
NodeRecord *ntlDevCurGateNode;

/* Node regions for source/drain terminals */
NodeRecord *devCurSDNodes[MAXSD];

/* Locations of source/drain terminals */
Point ntlDevCurSDLocs[MAXSD];	

/*
 * --------------------------------------------------------------------------
 *
 * ntlTransInit --
 *
 * Called once at Max startup to initialize device definition strucs.
 *
 * --------------------------------------------------------------------------
 */
void
ntlTransInit(void)
{
    register TileType t;

    TTMaskZero(&ntlTransMask);

    for (t = TT_TECHDEPBASE; t < DBNumTypes; t++)
    {
      TTMaskZero(&ntlTransSDTypesTbl[t]);

      ntlTransNameTbl[t] = NULL;
      ntlTransSubstrateDefaultNodeNameTbl[t] = NULL;
    }
}


/*
 * -------------------------------------------------------------------------
 *
 * ntlTransDefineFet --
 *
 * Define a fet device type to the netlister.
 *
 * -------------------------------------------------------------------------
 */
void 
ntlTransDefineFet(TileType gateLayer,
		  TileType sdLayer,
		  char *fetName,
		  char *subNode)
{
  fprintf(stderr,"DEBUG ntlTransDefineFet gate=%s sdLayer=%s fetName=%s sNode=%s\n",
	  DBTypeLongNameTbl[gateLayer],
	  DBTypeLongNameTbl[sdLayer],
	  fetName,
	  subNode);
}

/*
 * --------------------------------------------------------------------------
 *
 * ntlTransDump --
 *
 * Dump current device definitions to standard output.
 * (for debugging.) 
 *
 * --------------------------------------------------------------------------
 */
void
ntlTransDump(void)
{
    register TileType t;

    for (t = 0; t < DBNumTypes; t++)
    {
      if (TTMaskHasType(&ntlTransMask, t))
      {
	fprintf(stderr,"gate %s: fet_type=%s subNode=%s ", 
		DBTypeShortName(t), 
		ntlTransNameTbl[t],
		ntlTransSubstrateDefaultNodeNameTbl[t]);

	DumpTypes("sd_layers=", &ntlTransSDTypesTbl[t]);
      }
    }
}

#ifdef HIDE
/*
 * --------------------------------------------------------------------------
 *
 * ntlTransBad --
 *
 * For a transistor where an error was encountered, give feedback
 * as to the location of the error.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Complains to the user.
 *
 * --------------------------------------------------------------------------
 */
static void
ntlTransBad(CellDef *def, Tile *tp, char *mesg)
{
    Rect r;

    TiToRect(tp, &r);
    LayFeedbackAdd(&r, mesg, def, 1, STYLE_FEEDBACK_PALE);

    ntlNumWarnings++;
}

int
ntlTransFindSubsFunc(register Tile *tile, NodeRecord **pnreg)
{
    if (tile->ti_client != (ClientData) MINFINITY)
    {
	*pnreg = (NodeRecord *) tile->ti_client;
	return 1;
    }

    return 0;
}

NodeRecord *
ntlTransFindSubsNode(CellDef *def, register NTransRegion *treg)
{
    TileType t = DBgetTileType(treg->treg_tile);
    TileTypeBitMask *mask;
    NodeRecord *nreg;
    Rect tileArea;
    int pNum;

    TiToRect(treg->treg_tile, &tileArea);
    mask = &ntlTransSubstrateTypesTbl[t];
    for (pNum = PL_TECHDEPBASE; pNum < DBNumPlanes; pNum++)
    {
	if (TTMaskIntersect(&DBPlaneTypes[pNum], mask))
	{
	    if (DBPlaneEnumAreaPaint((Tile *) NULL, def->cd_planes[pNum], &tileArea,
		    mask, ntlTransFindSubsFunc, (ClientData) &nreg))
		return nreg;
	}
    }

    return (NodeRecord *) NULL;
}


int
ntlTransPerimFunc(register NBoundary *bp)
{
  TileType tinside = DBgetTileType(bp->b_inside);
  TileType toutside = DBgetTileType(bp->b_outside);
  NodeRecord *diffNode = (NodeRecord *) ntlGetRegion(bp->b_outside);
  int len = NBoundaryLength(bp);
  NLabelList *nll;
  Label *lab;
  Rect r;

  if (TTMaskHasType(&ntlTransSDTypesTbl[tinside], toutside))
  {
    /* Source/Drain terminal */

    int thisterm;

    for (thisterm = 0; 
	 thisterm < ntlDevNumTerms; 
	 thisterm++)
    {
      if (ntlDevCur.dev_termnode[thisterm] == diffNode)	break;
    }

    if (thisterm >= ntlDevNumTerms)
    {
      /* new terminal */ 

      ntlDevCur.dev_nterm++;
      ntlDevCur.dev_termnode[thisterm] = diffNode;
      ntlDevCur.dev_termlen[thisterm] = 0;
      ntlDevCur.dev_termpos[thisterm].pnum = 
	DBPlane(DBgetTileType(bp->b_outside));
      ntlDevCur.dev_termpos[thisterm].pt = 
	bp->b_outside->ti_ll;
    }
    else			
    {
      /* existing terminal, update the region tile position */

      TermTilePos  *pos = &(ntlDevCur.dev_termpos[thisterm]);
      Tile         *otile = bp->b_outside;

      if( DBPlane(DBgetTileType(otile)) < pos->pnum )
      {
	pos->pnum = DBPlane(DBgetTileType(otile));
	pos->pt = otile->ti_ll;
      }
      else if( DBPlane(DBgetTileType(otile)) == pos->pnum )
      {
	if( LEFT(otile) < pos->pt.p_x )
	{
	  pos->pt = otile->ti_ll;
	}
	else if( LEFT(otile) == pos->pt.p_x && 
		 BOTTOM(otile) < pos->pt.p_y )
	{
	  pos->pt.p_y = BOTTOM(otile);
	}
      }
    }

    /* update perimeter */
    ntlDevCur.dev_termlen[thisterm] += len;

    /*
     * Mark this attribute as belonging to this transistor
     * if it is either:
     *	(1) a terminal attribute whose LL corner touches bp->b_segment,
     *   or	(2) a gate attribute that lies inside bp->b_inside.
     */
    for (nll = ntlDevCur.dev_gatenode->nrec_labels; nll; nll = nll->ll_next)
    {
      /* Skip if already marked */
      if (nll->ll_attr != NLL_NOATTR) continue;

      lab = nll->ll_label;
      if (GEO_ENCLOSE(&lab->lab_rect.r_ll, &bp->b_segment)
	  && extLabType(lab->lab_text, NLABTYPE_TERMATTR))
      {
	nll->ll_attr = thisterm;
      }
    }
  }
  else if (ntlConnect(tinside, toutside))
  {
    /* Not in a terminal, but are in something that connects to gate */
    ntlCurDev.dev_gatelen += len;
  }

  /*
   * Total perimeter (separate from terminals, for dcaps
   * that might not be surrounded by terminals on all sides).
   */
  ntlCurDev.dev_perim += len;

  return (0);
}

/*
 * ----------------------------------------------------------------------------
 *
 * ntlTransTileFunc --
 *
 * Filter function called by ntlFindNeighbors for each tile in a
 * transistor.  Responsible for collecting the nodes, lengths,
 * and attributes of all the terminals on this transistor.
 *
 * Results:
 *	Returns 0 always.
 *
 * Side effects:
 *	Fills in ntlCurDev
 *
 * ----------------------------------------------------------------------------
 */

int
ntlTransTileFunc(Tile *tile)
{
    TileTypeBitMask mask;

    register NLabelList *nll;
    register Label *lab;
    Rect r;

    for (nll = ntlCurDev.dev_gatenode->nrec_labels; nll; nll = nll->ll_next)
    {
	/* Skip if already marked */
	if (nll->ll_attr != NLL_NOATTR) continue;
	lab = nll->ll_label;
	TITORECT(tile, &r);
	if (GEO_TOUCH(&r, &lab->lab_rect) && 
		extLabType(lab->lab_text, NLABTYPE_GATEATTR))  
	{
	     nll->ll_attr = NLL_GATEATTR;
	}
    }
    /*
     * Visit each segment of the perimeter of this tile that
     * that borders on something of a different type.
     */
    mask = DBSelfOnlyTbl[DBgetTileType(tile)];
    TTMaskCom(&mask);
    (void) ntlEnumTilePerim(tile, mask, ntlTransPerimFunc, (ClientData) NULL);
    return (0);
}


/*
 * --------------------------------------------------------------------------
 *
 * ntlOutputTrans --
 *
 * For each NTransRegion in the supplied list, corresponding to a single
 * transistor in the layout, compute and output:
 *	- Its type
 *	- Its area and perimeter
 *	- Its substrate node
 *	- For each of the gate, and the various diff terminals (eg,
 *	  source, drain):
 *		Node to which the terminal connects
 *		Length of the terminal
 *		Attributes (comma-separated), or 0 if none.
 *
 * The tiles in 'def' don't point back to the NTransRegions in this list,
 * but rather to the NodeRecord corresponding to their electrical nodes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Writes a number of 'fet' records to the file 'outFile'.
 *
 * Interruptible.  If SigInterruptPending is detected, we stop traversing
 * the transistor list and return.
 *
 * --------------------------------------------------------------------------
 */

void
ntlOutputTrans(CellDef *def, FILE *outFile)
                 		/* Cell being extracted */
                  		/* Output file */
{
    NodeRecord *node, *subsNode;
    register NTransRegion *reg;
    char *subsName;
    NFindRegion arg;
    NLabelList *nll;
    TileType t;
    int nsd;
    int lineNum;
    double v, s, fperim;
    int area;

    lineNum = 0;
    for (reg = (NTransRegion *) def->cd_trans;
	 reg && !SigInterruptPending;
	 reg = reg->treg_next)
    {
	/*
	 * Visit all of the tiles in the transistor region, updating
	 * ntlCurDev.dev_termnode[] and ntlCurDev.dev_termlen[],
	 * and the attribute lists for this transistor.
	 *
	 * Algorithm: first visit all tiles in the transistor, marking
	 * them with 'reg', then visit them again re-marking them with
	 * the gate node (ntlGetRegion(reg->treg_tile)).
	 */
	ntlCurDev.dev_nterm = 0;
	ntlCurDev.dev_gatelen = 0;
	ntlCurDev.dev_perim = 0;
	ntlCurDev.dev_gatenode = (NodeRecord *) ntlGetRegion(reg->treg_tile);

	arg.nfra_def = def;
	arg.nfra_connectsTo = DBSelfOnlyTbl;
	arg.nfra_pNum = DBPlane(DBgetTileType(reg->treg_tile));

	    /* Mark with reg and process each perimeter segment */
	arg.nfra_uninit = (ClientData) ntlCurDev.dev_gatenode;
	arg.nfra_region = (NRegion *) reg;
	arg.nfra_each = ntlTransTileFunc;
	(void) ntlFindNeighbors(reg->treg_tile, arg.nfra_pNum, &arg);

	    /* Re-mark with ntlCurDev.dev_gatenode */
	arg.nfra_uninit = (ClientData) reg;
	arg.nfra_region = (NRegion *) ntlCurDev.dev_gatenode;
	arg.nfra_each = (int (*)()) NULL;
	(void) ntlFindNeighbors(reg->treg_tile, arg.nfra_pNum, &arg);

	/*
	 * For types that require a minimum number of terminals,
	 * check to make sure that they all exist.  If they don't,
	 * issue a warning message and make believe the missing
	 * terminals are the same as the last terminal we do have.
	 */
	t = DBgetTileType(reg->treg_tile);
	nsd = 2;
	if (ntlCurDev.dev_nterm < nsd)
	{
	    char mesg[256];
	    int missing = nsd - ntlCurDev.dev_nterm;

	    (void) sprintf(mesg, "fet missing %d terminal%s", missing,
					missing == 1 ? "" : "s");
	    if (ntlCurDev.dev_nterm > 0)
	    {
		node = ntlCurDev.dev_termnode[ntlCurDev.dev_nterm-1];
		(void) strcat(mesg, ";\n connecting remainder to node ");
		(void) strcat(mesg, ntlNodeName(node));
		while (ntlCurDev.dev_nterm < nsd) 
		{
		    ntlCurDev.dev_termlen[ntlCurDev.dev_nterm] = 0;
		    ntlCurDev.dev_termnode[ntlCurDev.dev_nterm++] = node;
		}
	    }
	    if (ntlReportBadDevices)
		ntlTransBad(def, reg->treg_tile, mesg);
	}
	else if (ntlCurDev.dev_nterm > nsd)
	{
	  /* more terminals than expected*/
	  if (ntlReportBadDevices)
	    ntlTransBad(def, reg->treg_tile, "too many terminals on fet");
	}

	/*
	 * Output the transistor record.
	 * The type is ntlTransNameTbl[t], which should have
	 * some meaning to the simulator we are producing this file for.
	 * Use the default substrate node unless the transistor overlaps
	 * material whose type is in ntlTransSubstrateTypesTbl, in which
	 * case we use the node of the overlapped material.
	 */
	subsName = ntlTransSubstrateDefaultNodeNameTbl[t];
	if (!TTMaskIsZero(&ntlTransSubstrateTypesTbl[t])
		&& (subsNode = ntlTransFindSubsNode(def, reg)))
	{
	    subsName = ntlNodeName(subsNode);
	}
/*
	(void) fprintf(outFile, "fet %s %d %d %d %d %d %d \"%s\"",
		    ntlTransNameTbl[t],
		    reg->treg_ll.p_x, reg->treg_ll.p_y, 
		    reg->treg_ll.p_x + 1, reg->treg_ll.p_y + 1,
		    reg->treg_area, ntlCurDev.dev_perim, subsName);
*/
/*
	ntlCurDev.dev_nterm must be 2
*/
	ntlSortTerminals(&ntlCurDev);

	/* compute l, w from area and perimeter via quadratic */
	fperim = (float)ntlCurDev.dev_perim;
	area = reg->treg_area;

	v = (double) (fperim*fperim - 16*area);

	/* Approximate by one square if v < 0 */
	if (v < 0) s = 0; else s = sqrt(v);

	/* non-gate terminal 0 */
	(void) fprintf(outFile, "M%d %s", 
		lineNum, 
		ntlNodeName(ntlCurDev.dev_termnode[0]));

	/* gate */
	node = (NodeRecord *) ntlGetRegion(reg->treg_tile);
	(void) fprintf(outFile, " %s", ntlNodeName(node));

	/* non-gate terminal 1 */
	(void) fprintf(outFile, " %s", 
		ntlNodeName(ntlCurDev.dev_termnode[1]));

	/* Substrate (bulk) name */
	(void) fprintf(outFile, " %s", subsName);

	/* Transistor Name (in SPICE: MODname) */
	(void) fprintf(outFile, " %s", ntlTransNameTbl[t]);

	/* L and W */
	(void) fprintf(outFile, " L=%.3fU W=%.3fU", 
		(fperim-s) * CIFDBRes / 4.0, 
		(fperim+s) * CIFDBRes / 4.0); 

	(void) fputs("\n", outFile);

	/* SPICE comment line for location */
	(void) fprintf(outFile, "*   Transistor location  = %0.2fU %0.2fU\n",
				(double)reg->treg_ll.p_x * CIFDBRes, 
				(double)reg->treg_ll.p_y * CIFDBRes );
	lineNum = lineNum + 1;
    }
}


/*
 * ----------------------------------------------------------------------------
 *
 * ntlLabType --
 *
 * Check to see whether the text passed as an argument satisfies
 * any of the label types in 'typeMask'.
 *
 * Results:
 *	TRUE if the text is of one of the label types in 'typeMask',
 *	FALSE if not.
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */

bool
ntlLabType(register char *text, int typeMask)
{
    if (*text == '\0')
	return (FALSE);

    while (*text) text++;
    switch (*--text)
    {
	case '@':	/* Node attribute */
	    return (typeMask & NLABTYPE_NODEATTR);
	case '$':	/* Terminal (source/drain) attribute */
	    return (typeMask & NLABTYPE_TERMATTR);
	case '^':	/* Gate attribute */
	    return (typeMask & NLABTYPE_GATEATTR);
	default:
	    return (typeMask & NLABTYPE_NAME);
    }
    /*NOTREACHED*/
}
#endif HIDE

/*
 * ----------------------------------------------------------------------------
 *
 * ntlTransFirst --
 * ntlTransEach --
 *
 * Filter functions passed to ntlFindRegions when tracing out transistor
 * regions as part of flat circuit extraction.
 *
 * Results:
 *	ntlTransFirst returns a pointer to a new NTransRegion.
 *	ntlTransEach returns NULL.
 *
 * Side effects:
 *	Memory is allocated by ntlTransFirst.
 *	We cons the newly allocated region onto the front of the existing
 *	region list.
 *
 *	The area of each transistor is updated by ntlTransEach.
 *
 * ----------------------------------------------------------------------------
 */

static NRegion *
ntlTransFirst(Tile *tile, NFindRegion *arg)
{
    register NTransRegion *reg;

    MALLOC(NTransRegion *, reg, sizeof (NTransRegion));
    reg->treg_next = (NTransRegion *) NULL;
    reg->treg_labels = (NLabelList *) NULL;
    reg->treg_pnum = DBNumPlanes;
    reg->treg_area = 0;
    reg->treg_tile = tile;

    /* Prepend it to the region list */
    reg->treg_next = (NTransRegion *) arg->nfra_region;
    arg->nfra_region = (NRegion *) reg;
    return ((NRegion *) reg);
}

static int
ntlTransEach(Tile *tile, int pNum, NFindRegion *arg)
{
    register NTransRegion *reg;

    reg = (NTransRegion *) arg->nfra_region;
    reg->treg_area += NTILEAREA(tile);
    ntlSetNodeNum((NLabRegion *) reg, pNum, tile);

    return (0);
}



/*
 * -------------------------------------------------------------------------
 *
 * ntlTransFind --
 *
 * Results:
 *	Returns list of transistor regions in def.
 *
 * -------------------------------------------------------------------------
 */
NRegion *
ntlTransFind(CellDef *def)
{
  return ntlFindRegions(def, 
			&TiPlaneRect,
			&ntlTransMask,
			DBSelfOnlyTbl,
			ntlTransFirst, 
			ntlTransEach);
}



