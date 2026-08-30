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
 * ntlTrans.c --
 *
 * Transistor related functions for netlisting
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
#include "malloc.h"
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

/* --------------------- Data local to this file ---------------------- */

    /*
     * The following are used to accumulate perimeter and area
     * on each layer when building up the node list.  They are
     * used to compute the resistance of each node.  Each is
     * indexed by sheet resistivity class.
     */
int extResistPerim[NT], extResistArea[NT];

    /*
     * The following structure is used in extracting transistors.
     *
     * A "terminal" below refers to any port on the transistor that
     * is not the gate.  In most cases, these are the "diffusion"
     * ports of the transistor.
     */
#define	MAXSD	10	/* Maximum # of terminals per transistor */


typedef struct		/* Position of each terminal (below) tile position */
{
    int		pnum;
    Point	pt;
} TermTilePos;


struct transRec
{
    int		 tr_nterm;		/* Number of terminals */
    int		 tr_gatelen;		/* Perimeter of connection to gate */
    NodeRecord	*tr_gatenode;		/* Node region for gate terminal */
    NodeRecord	*tr_termnode[MAXSD];	/* Node region for each diff terminal */
    int		 tr_termlen[MAXSD];	/* Length of each diff terminal edge,
					 * used for computing L/W for the fet.
					 */
    int		 tr_perim;		/* Total perimeter */
    TermTilePos  tr_termpos[MAXSD];	/* lowest tile connecting to term */
} ntlTransRec;

#define	EDGENULL(r)	((r)->r_xbot > (r)->r_xtop || (r)->r_ybot > (r)->r_ytop)

/* Forward declarations */
int ntlTransTileFunc(Tile *tile);
int ntlTransPerimFunc(register NBoundary *bp);


/*
 * ----------------------------------------------------------------------------
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
 * ----------------------------------------------------------------------------
 */

void
ntlTransBad(CellDef *def, Tile *tp, char *mesg)
{
    Rect r;

    if (!DebugIsSet(ntlDebugID, ntlDebNoFeedback))
    {
	TiToRect(tp, &r);
	LayFeedbackAdd(&r, mesg, def, 1, STYLE_FEEDBACK_PALE);
    }
    ntlNumWarnings++;
}


/*
 * ---------------------------------------------------------------------
 *
 * ntlSortTerminals --
 *
 * Sort the terminals of a transistor so that the terminal with the
 * lowest leftmost coordinate on the plane with the lowest number is
 * output first.
 *
 * Results:
 *	None
 *
 * Side effects:
 *	The tr_termnode, tr_termlen, and tr_termpos entries may change.
 *
 * ---------------------------------------------------------------------
 */
void ntlSortTerminals(struct transRec *tran)
{
    int		nsd, changed;
    TermTilePos	*p1, *p2;
    NodeRecord	*tmp_node;
    TermTilePos	tmp_pos;
    int		tmp_len;

    do
    {
	changed = 0;
	for( nsd = 0; nsd < tran->tr_nterm-1; nsd++ )
	{
	    p1 = &(tran->tr_termpos[nsd]);
	    p2 = &(tran->tr_termpos[nsd+1]);
	    if( p2->pnum > p1->pnum )
		continue;
	    else if( p2->pnum == p1->pnum )
	    {
		if( p2->pt.p_x > p1->pt.p_x )
		    continue;
		else if( p2->pt.p_x == p1->pt.p_x && p2->pt.p_y > p1->pt.p_y )
		    continue;
	    }
	    changed = 1;
	    tmp_node = tran->tr_termnode[nsd];
	    tmp_pos = tran->tr_termpos[nsd];
	    tmp_len = tran->tr_termlen[nsd];

	    tran->tr_termnode[nsd] = tran->tr_termnode[nsd+1];
	    tran->tr_termpos[nsd] = tran->tr_termpos[nsd+1];
	    tran->tr_termlen[nsd] = tran->tr_termlen[nsd+1];
	    
	    tran->tr_termnode[nsd+1] = tmp_node;
	    tran->tr_termpos[nsd+1] = tmp_pos;
	    tran->tr_termlen[nsd+1] = tmp_len;
	}
     }
     while( changed );
}

int
ntlTransFindSubsFunc(register Tile *tile, NodeRecord **pnreg)
{
    if (tile->ti_client != (ClientData) ntlUnInit)
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
    mask = &ntlTech_transSubstrateTypes[t];
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


/*
 * ----------------------------------------------------------------------------
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
 * ----------------------------------------------------------------------------
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
	 * ntlTransRec.tr_termnode[] and ntlTransRec.tr_termlen[],
	 * and the attribute lists for this transistor.
	 *
	 * Algorithm: first visit all tiles in the transistor, marking
	 * them with 'reg', then visit them again re-marking them with
	 * the gate node (ntlGetRegion(reg->treg_tile)).
	 */
	ntlTransRec.tr_nterm = 0;
	ntlTransRec.tr_gatelen = 0;
	ntlTransRec.tr_perim = 0;
	ntlTransRec.tr_gatenode = (NodeRecord *) ntlGetRegion(reg->treg_tile);

	arg.nfra_def = def;
	arg.nfra_connectsTo = ntlTech_transConn;
	arg.nfra_pNum = DBPlane(DBgetTileType(reg->treg_tile));

	    /* Mark with reg and process each perimeter segment */
	arg.nfra_uninit = (ClientData) ntlTransRec.tr_gatenode;
	arg.nfra_region = (NRegion *) reg;
	arg.nfra_each = ntlTransTileFunc;
	(void) ntlFindNeighbors(reg->treg_tile, arg.nfra_pNum, &arg);

	    /* Re-mark with ntlTransRec.tr_gatenode */
	arg.nfra_uninit = (ClientData) reg;
	arg.nfra_region = (NRegion *) ntlTransRec.tr_gatenode;
	arg.nfra_each = (int (*)()) NULL;
	(void) ntlFindNeighbors(reg->treg_tile, arg.nfra_pNum, &arg);

	/*
	 * For types that require a minimum number of terminals,
	 * check to make sure that they all exist.  If they don't,
	 * issue a warning message and make believe the missing
	 * terminals are the same as the last terminal we do have.
	 */
	t = DBgetTileType(reg->treg_tile);
	nsd = ntlTech_transSDCount[t];
	if (ntlTransRec.tr_nterm < nsd)
	{
	    char mesg[256];
	    int missing = nsd - ntlTransRec.tr_nterm;

	    (void) sprintf(mesg, "fet missing %d terminal%s", missing,
					missing == 1 ? "" : "s");
	    if (ntlTransRec.tr_nterm > 0)
	    {
		node = ntlTransRec.tr_termnode[ntlTransRec.tr_nterm-1];
		(void) strcat(mesg, ";\n connecting remainder to node ");
		(void) strcat(mesg, ntlNodeName(node));
		while (ntlTransRec.tr_nterm < nsd) 
		{
		    ntlTransRec.tr_termlen[ntlTransRec.tr_nterm] = 0;
		    ntlTransRec.tr_termnode[ntlTransRec.tr_nterm++] = node;
		}
	    }
	    if (NtlDoWarn & NTLWARN_FETS)
		ntlTransBad(def, reg->treg_tile, mesg);
	}
	else if (ntlTransRec.tr_nterm > nsd)
	{
	     /* more terminals than expected*/
	}

	/*
	 * Output the transistor record.
	 * The type is ntlTech_transName[t], which should have
	 * some meaning to the simulator we are producing this file for.
	 * Use the default substrate node unless the transistor overlaps
	 * material whose type is in ntlTech_transSubstrateTypes, in which
	 * case we use the node of the overlapped material.
	 */
	subsName = ntlTech_transSubstrateName[t];
	if (!TTMaskIsZero(&ntlTech_transSubstrateTypes[t])
		&& (subsNode = ntlTransFindSubsNode(def, reg)))
	{
	    subsName = ntlNodeName(subsNode);
	}
/*
	(void) fprintf(outFile, "fet %s %d %d %d %d %d %d \"%s\"",
		    ntlTech_transName[t],
		    reg->treg_ll.p_x, reg->treg_ll.p_y, 
		    reg->treg_ll.p_x + 1, reg->treg_ll.p_y + 1,
		    reg->treg_area, ntlTransRec.tr_perim, subsName);
*/
/*
	ntlTransRec.tr_nterm must be 2
*/
	ntlSortTerminals(&ntlTransRec);

	/* compute l, w from area and perimeter via quadratic */
	fperim = (float)ntlTransRec.tr_perim;
	area = reg->treg_area;

	v = (double) (fperim*fperim - 16*area);

	/* Approximate by one square if v < 0 */
	if (v < 0) s = 0; else s = sqrt(v);

	/* non-gate terminal 0 */
	(void) fprintf(outFile, "M%d %s", 
		lineNum, 
		ntlNodeName((NLabRegion *) ntlTransRec.tr_termnode[0]));

	/* gate */
	node = (NodeRecord *) ntlGetRegion(reg->treg_tile);
	(void) fprintf(outFile, " %s", ntlNodeName(node));

	/* non-gate terminal 1 */
	(void) fprintf(outFile, " %s", 
		ntlNodeName( (NLabRegion *) ntlTransRec.tr_termnode[1]));

	/* Substrate (bulk) name */
	(void) fprintf(outFile, " %s", subsName);

	/* Transistor Name (in SPICE: MODname) */
	(void) fprintf(outFile, " %s", ntlTech_transName[t]);

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


int
ntlTransPerimFunc(register NBoundary *bp)
{
    TileType tinside = DBgetTileType(bp->b_inside);
    TileType toutside = DBgetTileType(bp->b_outside);
    NodeRecord *diffNode = (NodeRecord *) ntlGetRegion(bp->b_outside);
    int len = NBoundaryLength(bp);
    register int thisterm;
    register NLabelList *nll;
    register Label *lab;
    Rect r;

    if (TTMaskHasType(&ntlTech_transSDTypes[tinside], toutside))
    {
	/*
	 * It's a diffusion terminal (source or drain).
	 * See if the node is already in our table; add it
	 * if it wasn't already there.
	 */
	for (thisterm = 0; thisterm < ntlTransRec.tr_nterm; thisterm++)
	    if (ntlTransRec.tr_termnode[thisterm] == diffNode)
		break;
	if (thisterm >= ntlTransRec.tr_nterm)
	{
	    ntlTransRec.tr_nterm++;
	    ntlTransRec.tr_termnode[thisterm] = diffNode;
	    ntlTransRec.tr_termlen[thisterm] = 0;
	    ntlTransRec.tr_termpos[thisterm].pnum = DBPlane(DBgetTileType(bp->b_outside));
	    ntlTransRec.tr_termpos[thisterm].pt = bp->b_outside->ti_ll;
	}
	else			/* update the region tile position */
	{
	    TermTilePos  *pos = &(ntlTransRec.tr_termpos[thisterm]);
	    Tile         *otile = bp->b_outside;

	    if( DBPlane(DBgetTileType(otile)) < pos->pnum )
	    {
		pos->pnum = DBPlane(DBgetTileType(otile));
		pos->pt = otile->ti_ll;
	    }
	    else if( DBPlane(DBgetTileType(otile)) == pos->pnum )
	    {
		if( LEFT(otile) < pos->pt.p_x )
		    pos->pt = otile->ti_ll;
		else if( LEFT(otile) == pos->pt.p_x && 
		  BOTTOM(otile) < pos->pt.p_y )
		    pos->pt.p_y = BOTTOM(otile);
	    }
	}

	/* Add the length to this terminal's perimeter */
	ntlTransRec.tr_termlen[thisterm] += len;

	/*
	 * Mark this attribute as belonging to this transistor
	 * if it is either:
	 *	(1) a terminal attribute whose LL corner touches bp->b_segment,
	 *   or	(2) a gate attribute that lies inside bp->b_inside.
	 */
	for (nll = ntlTransRec.tr_gatenode->nrec_labels; nll; nll = nll->ll_next)
	{
	    /* Skip if already marked */
	    if (nll->ll_attr != NLL_NOATTR)
		continue;
	    lab = nll->ll_label;
	    if (GEO_ENCLOSE(&lab->lab_rect.r_ll, &bp->b_segment)
		    && extLabType(lab->lab_text, NLABTYPE_TERMATTR))
	    {
		nll->ll_attr = thisterm;
	    }
	}
    }
    else if (ntlConnectsTo(tinside, toutside, ntlTech_nodeConn))
    {
	/* Not in a terminal, but are in something that connects to gate */
	ntlTransRec.tr_gatelen += len;
    }

    /*
     * Total perimeter (separate from terminals, for dcaps
     * that might not be surrounded by terminals on all sides).
     */
    ntlTransRec.tr_perim += len;

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
 *	Fills in the transRec structure ntlTransRec.
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

    for (nll = ntlTransRec.tr_gatenode->nrec_labels; nll; nll = nll->ll_next)
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
    mask = ntlTech_transConn[DBgetTileType(tile)];
    TTMaskCom(&mask);
    (void) ntlEnumTilePerim(tile, mask, ntlTransPerimFunc, (ClientData) NULL);
    return (0);
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

NRegion *
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

    /*ARGSUSED*/
int
ntlTransEach(Tile *tile, int pNum, NFindRegion *arg)
{
    register NTransRegion *reg;

    reg = (NTransRegion *) arg->nfra_region;
    reg->treg_area += NTILEAREA(tile);
    ntlSetNodeNum((NLabRegion *) reg, pNum, tile);

    return (0);
}

