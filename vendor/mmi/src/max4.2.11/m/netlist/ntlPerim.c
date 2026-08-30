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
 * ntlPerim.c --
 *
 * neltisting extraction.
 * Functions for tracing the perimeter of a tile or of a
 * connected region.
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
static char rcsid[] = "$Header: ntlPerim.c,v 6.0 90/08/28 18:15:22 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "malloc.h"
#include "stack.h"
#include "debug.h"
#include "netlistInt.h"
#include "netlist.h"


/*
 * ----------------------------------------------------------------------------
 *
 * ntlEnumTilePerim --
 *
 * Visit all the tiles along the perimeter of 'tpIn' whose types are in
 * the mask 'mask'.  For each such tile, call the supplied function 'func'
 * if it is non-null:
 *
 *	(*func)(bp, cdata)
 *	    NBoundary *bp;	/# bp->b_inside is tpIn, bp->b_outside
 *				 # is the tile along the boundary of tpIn,
 *				 # and bp->b_segment is the segment of the
 *				 # boundary in common.
 *				 #/
 *	    ClientData cdata;	/# Supplied in call to ntlEnumTilePerim #/
 *	{
 *	}
 *
 * The value returned by this function is ignored.
 *
 * Results:
 *	Returns the total length of the portion of the perimeter of
 *	'tpIn' that borders tiles whose types are in 'mask'.
 *
 * Side effects:
 *	None directly, but applies the client's filter function
 *	to each qualifying segment of the boundary.
 *
 * Non-interruptible.
 *
 * ----------------------------------------------------------------------------
 */

int
ntlEnumTilePerim(register Tile *tpIn, TileTypeBitMask mask, int (*func) (/* ??? */), ClientData cdata)
                        
                         	/* Note: this is not a pointer */
                  
                     
{
    register Tile *tpOut;
    int perimLength;
    NBoundary b;

    b.b_inside = tpIn;
    perimLength = 0;

	/* Top */
    b.b_segment.r_ybot = b.b_segment.r_ytop = TOP(tpIn);
    b.b_direction = NBD_LEFT;
    for (tpOut = RT(tpIn); RIGHT(tpOut) > LEFT(tpIn); tpOut = BL(tpOut))
    {
	if (TTMaskHasType(&mask, DBgetTileType(tpOut)))
	{
	    b.b_segment.r_xbot = MAX(LEFT(tpIn), LEFT(tpOut));
	    b.b_segment.r_xtop = MIN(RIGHT(tpIn), RIGHT(tpOut));
	    b.b_outside = tpOut;
	    perimLength += NBoundaryLength(&b);
	    if (func) (*func)(&b, cdata);
	}
    }

	/* Bottom */
    b.b_segment.r_ybot = b.b_segment.r_ytop = BOTTOM(tpIn);
    b.b_direction = NBD_RIGHT;
    for (tpOut = LB(tpIn); LEFT(tpOut) < RIGHT(tpIn); tpOut = TR(tpOut))
    {
	if (TTMaskHasType(&mask, DBgetTileType(tpOut)))
	{
	    b.b_segment.r_xbot = MAX(LEFT(tpIn), LEFT(tpOut));
	    b.b_segment.r_xtop = MIN(RIGHT(tpIn), RIGHT(tpOut));
	    b.b_outside = tpOut;
	    perimLength += NBoundaryLength(&b);
	    if (func) (*func)(&b, cdata);
	}
    }

	/* Left */
    b.b_segment.r_xbot = b.b_segment.r_xtop = LEFT(tpIn);
    b.b_direction = NBD_UP;
    for (tpOut = BL(tpIn); BOTTOM(tpOut) < TOP(tpIn); tpOut = RT(tpOut))
    {
	if (TTMaskHasType(&mask, DBgetTileType(tpOut)))
	{
	    b.b_segment.r_ybot = MAX(BOTTOM(tpIn), BOTTOM(tpOut));
	    b.b_segment.r_ytop = MIN(TOP(tpIn), TOP(tpOut));
	    b.b_outside = tpOut;
	    perimLength += NBoundaryLength(&b);
	    if (func) (*func)(&b, cdata);
	}
    }

	/* Right */
    b.b_segment.r_xbot = b.b_segment.r_xtop = RIGHT(tpIn);
    b.b_direction = NBD_DOWN;
    for (tpOut = TR(tpIn); TOP(tpOut) > BOTTOM(tpIn); tpOut = LB(tpOut))
    {
	if (TTMaskHasType(&mask, DBgetTileType(tpOut)))
	{
	    b.b_segment.r_ybot = MAX(BOTTOM(tpIn), BOTTOM(tpOut));
	    b.b_segment.r_ytop = MIN(TOP(tpIn), TOP(tpOut));
	    b.b_outside = tpOut;
	    perimLength += NBoundaryLength(&b);
	    if (func) (*func)(&b, cdata);
	}
    }

    return (perimLength);
}
