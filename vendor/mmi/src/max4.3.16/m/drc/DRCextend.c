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
 * DRCextend.c --
 *
 * DECWRL extensions to DRC
 *
 *********************************************************************************
 * Copyright (C) 1989 Digital Equipment Corporation                              *
 * Permission to use, copy, modify, and distribute this                          *
 * software and its documentation for any purpose and without                    *
 * fee is hereby granted, provided that the above copyright                      *
 * notice appear in all copies.  Digital Equipment Corporation                   *
 * makes no representations about the suitability of this                        *
 * software for any purpose.  It is provided "as is" without                     * 
 * express or implied warranty.  Export of this software outside                 *
 * of the United States of America may require an export license.                *
 *                                                                               * 
 * THE SOFTWARE IS PROVIDED "AS IS" AND DIGITAL EQUIPMENT CORP. DISCLAIMS ALL    *
 * WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF  *
 * MERCHANTABILITY AND FITNESS.   IN NO EVENT SHALL DIGITAL EQUIPMENT            *
 * CORPORATION BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL     *
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR         *
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS       *
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS   *
 * SOFTWARE.                                                                     *
 *********************************************************************************
 *
 */

#ifndef	lint
static char sccsid[] = "@(#)DRCwrl.c	4.2 MAGIC (Berkeley) 07/8/88";
#endif	not lint

#include <sys/types.h>
#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "layout.h"
#include "layout.h"
#include "layout.h"
#include "drc.h"
#include "signals.h"
#include "stack.h"

Stack	*DRCstack = NULL;

#define PUSHTILE(tp) \
    if ((tp)->ti_client == (ClientData) DRC_UNPROCESSED) { \
        (tp)->ti_client = (ClientData)  DRC_PENDING; \
        STACKPUSH((ClientData) (tp), DRCstack); \
    }

/*
 *-------------------------------------------------------------------------
 *
 * zerospaceCheck -- for zero-space drc rules, does additional checks.
 *
 *
 *-------------------------------------------------------------------------
 */
int
zerospaceCheck(register Tile *tile, register struct drcClientData *arg)
{

    if (arg->dCD_cptr->drcc_flags  & DRC_ZEROSPACERULE) 
    {
    	 switch (arg->dCD_which)
	 {
	      case DRC_LEFT:
	      		if (LEFT(arg->dCD_initial) <= LEFT(tile) ||
	      		    LEFT(arg->dCD_initial) >= RIGHT(tile))
			{
			     return(0);
			}
			break;
	      case DRC_RIGHT:
	      		if (RIGHT(arg->dCD_initial) <= LEFT(tile) ||
	      		    RIGHT(arg->dCD_initial) >= RIGHT(tile))
			{
			     return(0);
			}
			break;
	      case DRC_TOP:
	      		if (TOP(arg->dCD_initial) <= BOTTOM(tile) ||
	      		    TOP(arg->dCD_initial) >= TOP(tile))
			{
			     return(0);
			}
			break;
	      case DRC_BOTTOM:
	      		if (BOTTOM(arg->dCD_initial) <= BOTTOM(tile) ||
	      		    BOTTOM(arg->dCD_initial) >= TOP(tile))
			{
			     return(0);
			}
			break;
	      default:
	      	MsgErrorF("Bad edge label in drc check\n");
		break;
	 }
    }
    return 1;
}

/*
 *-------------------------------------------------------------------------
 *
 * drcCheckArea- checks to see that a collection of tiles of a given 
 *	type have more than a minimum area.
 *
 * Results: none
 *
 * Side Effects: may cause errors to be painted.
 *
 *-------------------------------------------------------------------------
 */
void drcCheckArea(Tile *starttile, 
		  struct drcClientData *arg, 
		  DRCCookie *cptr)
{
     double		arealimit = cptr->drcc_cdist;
     double		area=0;
     TileTypeBitMask	*oktypes = &cptr->drcc_mask;
     Tile		*tile,*tp;
     Rect		*cliprect = arg->dCD_rect;
     static Stack		*DRCstack= NULL;
     
    arg->dCD_cptr = cptr;
    if (DRCstack == (Stack *) NULL)
	DRCstack = StackNew(64);

    /* Mark this tile as pending and push it */
    PUSHTILE(starttile);

    while (!StackEmpty(DRCstack))
    {
	tile = (Tile *) STACKPOP(DRCstack);
	if (tile->ti_client != (ClientData)DRC_PENDING) continue;
	area += (RIGHT(tile)-LEFT(tile)) * (double) (TOP(tile)-BOTTOM(tile));
	tile->ti_client = (ClientData)DRC_PROCESSED;
	/* are we at the clip boundary? If so, skip to the end */
	if (RIGHT(tile) == cliprect->r_xtop ||
	    LEFT(tile) == cliprect->r_xbot ||
	    BOTTOM(tile) == cliprect->r_ybot ||
	    TOP(tile) == cliprect->r_ytop) goto forgetit;

         if (area >= arealimit) goto forgetit;

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp)))	PUSHTILE(tp);

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);
     }
     if (area <arealimit)
     {
	 Rect	rect;
	 TiToRect(starttile,&rect);
	 GeoClip(&rect, arg->dCD_clip);
	 if (!GEO_RECTNULL(&rect)) {
	     (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
		 arg->dCD_cptr, arg->dCD_clientData);
	     /***
	     DBChangedArea(arg->dCD_celldef,
	     &rect, 
	     &DBAllButSpaceBits,
	     DBCF_DRC_ERROR_ONLY);
	     ***/
	     (*(arg->dCD_errors))++;
	 }
     }
forgetit:
     /* reset the tiles */
     starttile->ti_client = (ClientData)DRC_UNPROCESSED;
     STACKPUSH(starttile, DRCstack);
     while (!StackEmpty(DRCstack))
     {
	tile = (Tile *) STACKPOP(DRCstack);

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

     }
}


/*
 *-------------------------------------------------------------------------
 *
 * drcCheckMaxwidth - checks to see that at least one dimension of a region
 *	does not exceed some amount.
 *
 *  This should really be folded together with drcCheckArea, since the routines
 *	are nearly identical, but I'm feeling lazy, so I'm just duplicating
 *	the code for now.
 *
 * Results: none
 *
 * Side Effects: may cause errors to be painted.
 *
 *-------------------------------------------------------------------------
 */
void drcCheckMaxwidth(Tile *starttile, 
		      struct drcClientData *arg, 
		      DRCCookie *cptr)
{
     int		edgelimit = cptr->drcc_dist;
     Rect		boundrect;
     TileTypeBitMask	*oktypes = &cptr->drcc_mask;
     Tile		*tile,*tp;
     
    arg->dCD_cptr = cptr;
    if (DRCstack == (Stack *) NULL)
	DRCstack = StackNew(64);

    /* if bends are allowed, just check on a tile-by-tile basis that
        one dimension is the max.  This is pretty stupid, but it correctly
	calculates the trench width rule. dcs 12.06.89 */
    if (cptr->drcc_flags & DRC_BENDS)
    {
	 Rect	rect;
	 TiToRect(starttile,&rect);
	 if (rect.r_xtop-rect.r_xbot != edgelimit &&
	    rect.r_ytop-rect.r_ybot != edgelimit)
	 {
	     GeoClip(&rect, arg->dCD_clip);
	     if (!GEO_RECTNULL(&rect)) {
		  (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
			arg->dCD_cptr, arg->dCD_clientData);
		  /***
		  DBChangedArea(arg->dCD_celldef,
		  &rect, 
		  &DBAllButSpaceBits,
		  DBCF_DRC_ERROR_ONLY);
		   ***/
		  (*(arg->dCD_errors))++;
		}
	 }
    }
    /* Mark this tile as pending and push it */
    PUSHTILE(starttile);
    TiToRect(starttile,&boundrect);

    while (!StackEmpty(DRCstack))
    {
	tile = (Tile *) STACKPOP(DRCstack);
	if (tile->ti_client != (ClientData)DRC_PENDING) continue;
	
	if (boundrect.r_xbot > LEFT(tile)) boundrect.r_xbot = LEFT(tile);
	if (boundrect.r_xtop < RIGHT(tile)) boundrect.r_xtop = RIGHT(tile);
	if (boundrect.r_ybot > BOTTOM(tile)) boundrect.r_ybot = BOTTOM(tile);
	if (boundrect.r_ytop < TOP(tile)) boundrect.r_ytop = TOP(tile);
	tile->ti_client = (ClientData)DRC_PROCESSED;

         if (boundrect.r_xtop - boundrect.r_xbot > edgelimit &&
             boundrect.r_ytop - boundrect.r_ybot > edgelimit) break;

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp)))	PUSHTILE(tp);

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (TTMaskHasType(oktypes, DBgetTileType(tp))) PUSHTILE(tp);
     }

     if (boundrect.r_xtop - boundrect.r_xbot > edgelimit &&
             boundrect.r_ytop - boundrect.r_ybot > edgelimit) 
     {
	 Rect	rect;
	 TiToRect(starttile,&rect);
	 GeoClip(&rect, arg->dCD_clip);
	 if (!GEO_RECTNULL(&rect)) {
	      (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
	            arg->dCD_cptr, arg->dCD_clientData);
	      /***
	      DBChangedArea(arg->dCD_celldef,
	      &rect, 
	      &DBAllButSpaceBits,
	      DBCF_DRC_ERROR_ONLY);
	      ***/
              (*(arg->dCD_errors))++;
	 }
	 
     }
     /* reset the tiles */
     starttile->ti_client = (ClientData)DRC_UNPROCESSED;
     STACKPUSH(starttile, DRCstack);
     while (!StackEmpty(DRCstack))
     {
	tile = (Tile *) STACKPOP(DRCstack);

	/* Top */
	for (tp = RT(tile); RIGHT(tp) > LEFT(tile); tp = BL(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Left */
	for (tp = BL(tile); BOTTOM(tp) < TOP(tile); tp = RT(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Bottom */
	for (tp = LB(tile); LEFT(tp) < RIGHT(tile); tp = TR(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

	/* Right */
	for (tp = TR(tile); TOP(tp) > BOTTOM(tile); tp = LB(tp))
	    if (tp->ti_client != (ClientData)DRC_UNPROCESSED)
	    {
	    	 tp->ti_client = (ClientData)DRC_UNPROCESSED;
		 STACKPUSH(tp,DRCstack);
	    }

     }
}

/*
 *-------------------------------------------------------------------------
 *
 * drcCheckRectSize- 
 *
 *	Checks to see that a collection of tiles of given 
 *	types have the proper size (max size and also even or odd size).
 *
 * Results: none
 *
 * Side Effects: may cause errors to be painted.
 *
 *-------------------------------------------------------------------------
 */

void drcCheckRectSize(Tile *starttile, 
		      struct drcClientData *arg, 
		      DRCCookie *cptr)
{
    int maxsize = cptr->drcc_dist;
    int even = cptr->drcc_cdist;
    TileTypeBitMask *oktypes = &cptr->drcc_mask;
    int width;
    int height;
    int errwidth;
    int errheight;
    Tile *t;
    bool error = FALSE;

    /* This code only has to work for rectangular regions, since we always
     * check for rectangular-ness using normal edge rules produced when
     * we read in the tech file.
     */
    arg->dCD_cptr = cptr;
    ASSERT(TTMaskHasType(oktypes, DBgetTileType(starttile)), "drcCheckRectSize");
    for (t = starttile; TTMaskHasType(oktypes, DBgetTileType(t)); t = TR(t)) 
	/* loop has empty body */ ;
    errwidth = width = LEFT(t) - LEFT(starttile);
    for (t = starttile; TTMaskHasType(oktypes, DBgetTileType(t)); t = RT(t)) 
	/* loop has empty body */ ;
    errheight = height = BOTTOM(t) - BOTTOM(starttile);
    ASSERT(width > 0 && height > 0, "drcCheckRectSize");

    if (width > maxsize) {error = TRUE; errwidth = (width - maxsize);}
    else if (height > maxsize) {error = TRUE; errheight = (height - maxsize);}
    else if (even >= 0) {
	/* meaning of "even" variable:  -1, any; 0, even; 1, odd */
	if (ABS(width - ((width/2)*2)) != even) {error = TRUE; errwidth = 1;}
	else if (ABS(height - ((height/2)*2)) != even) {error = TRUE; errheight = 1;}
    }

    if (error) {
	Rect rect;
	TiToRect(starttile, &rect);
	rect.r_xtop = rect.r_xbot + errwidth;
	rect.r_ytop = rect.r_ybot + errheight;
	GeoClip(&rect, arg->dCD_clip);
	if (!GEO_RECTNULL(&rect)) {
	    (*(arg->dCD_function)) (arg->dCD_celldef, &rect,
		arg->dCD_cptr, arg->dCD_clientData);
	    (*(arg->dCD_errors))++;
	}
	
    }
}

