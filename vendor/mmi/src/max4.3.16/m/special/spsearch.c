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

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "signals.h"
#include "utils.h"
#include "units.h"
#include "special.h"

static char *rcsid = "$Header: /volume/mmi/src/max/m/special/RCS/spsearch.c,v 1.1 2002/02/19 22:56:30 pat Exp $";


// TODO:
// Write functions that take an SPSearchContext
// to enumerate cells, planes, polygons, wirepaths.
// SPsxTileEnumInit(SPSearchEnum *spe,SPSearchContext *spx) {}
// SPPolyEnumInit(SPPolyEnum *spe, CellDef *def, Rect *area, TileTypeBitMask *mask, int flags) {}
// SPsxPolyEnumInit(SPPolyEnum *spe,SPSearchContect *spx) {}
// SPWirePathEnumInit(SPWirePathEnum *spe, CellDef *def, Rect *area, TileTypeBitMask *mask, int flags) {}
// SPsxWirePathEnumInit(SPWirePathEnum *spe,SPSearchContect *spx) {}


/***********************************************************************/
/* Utility functions */
/***********************************************************************/

// Return the root def where a search started.
// Handy for error messages, since the transforming spx_area by spx_trans
// yields coords in the coordinate system of this cell def.
// Whenever you print coords, should print this cell name, too.
CellDef *SPsxRoot(SPSearchContext *spx)
{
    while (spx->spx_parent) { spx = spx->spx_parent; }
    return spx->spx_rootdef;
}


// Return the instance path (aka tpath) from the root cell of the search to current celluse.
// Pass in a buffer of size buflen.
// Overflow is indicated if result is exactly buflen-1 in size.
char * SPsxInstPath(SPSearchContext *spx, char *buf, int buflen)
{
    int len;
    if (spx->spx_parent) {
	SPsxInstPath(spx->spx_parent,buf,buflen);
	len = strlen(buf);
	if (len < buflen-2) {
	    buf[len++] = '/';
	    buf[len] = 0;
	}
    } else {
	len = 0;
    }

    // This is naughty.  Pass an SPSearchContext as the SearchContext.
    // It works because the first part of the two structures is the same.
    (void) DBSrPrintUseId((SearchContext *)spx,&buf[len],buflen-len);
    return buf;
}


// Return the transform from spx coord system to
// its immediate parent.
Transform *SPsxGetTrans(SPSearchContext *spx)
{
    if (DBIsArray(spx->spx_use)) {
	return &spx->spx_atrans;
    } else {
	return &spx->spx_use->cu_transform;
    }
}

#if 0
// Return scx area in root cell coordinates.
// If a rectangle is given, clip by it first.
int SPsxTransRect(SPSearchContext *spx,Rect *clip,Rect *result)
{
    Rect rtmp = *spx->spx_area;  Transform inv;
    if (clip) {
      GEOCLIP(&rtmp,clip);
    }
    // NO: GEOINVERTTRANS(&spx->spx_trans,&inv);
    GEOTRANSRECT(&inv,&rtmp,&result);
}
#endif


// Return the composite transform for array element [x,y] of a CellUse.
// This is the transform that is used instead of cu_transform for that array element,
// ie, it transforms coords in the array element to the parent coords.
void SPGetArrayTransform(CellUse *use, int x, int y, Transform *result)
{
    // Figure out the xbase,ybase which are the offsets of array elements.
    int xsep = (use->cu_xlo > use->cu_xhi) ? -use->cu_xsep : use->cu_xsep;
    int ysep = (use->cu_ylo > use->cu_yhi) ? -use->cu_ysep : use->cu_ysep;
    int xbase = xsep * (x - use->cu_xlo);
    int ybase = ysep * (y - use->cu_ylo);

    GeoTransTranslate(xbase,ybase,&use->cu_transform,result);
}



/***********************************************************************/
/* Tile plane enumerator functions */
/***********************************************************************/

// SPTileFirst and SPTileNext are fast enumerator functions for tile planes.
// Functions return NULL when all tiles have been returned.
// Aguments to both functions:
//    tp - For SPTileFirst, return a hint tile, or plane->pl_hint.
//    rect  - return all tiles in this rectangle.  Must not change during enumeration.
//    mask - return only tiles matching this type.
// User may want to set plane->pl_hint to the returned tile.

Tile *SPTileNext(register Tile *tp, register Rect *rect, TileTypeBitMask *mask)
{
    register Tile *tpnew;

    while (1) {

	/* Each iteration visits another tile on the LHS of the search area */

	tpnew = TR(tp);
	if (LEFT(tpnew) < rect->r_xtop)
	{
	    while (BOTTOM(tpnew) >= rect->r_ytop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tp) > rect->r_xbot)
	{
	    if (BOTTOM(tp) <= rect->r_ybot) 
		return NULL;
	    tpnew = LB(tp);
	    tp = BL(tp);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* At left edge -- walk down to next tile along the left edge */
	for (tp = LB(tp); RIGHT(tp) <= rect->r_xbot; tp = TR(tp))
	   continue; 
	if (TOP(tp) <= rect->r_ybot) return NULL;

	enumerate:
	if (TTMaskHasType(mask, DBgetTileType(tp))) {
	    return tp;
	}
    }
}

// Fast enumerator function for tile planes.
// See documentation above.
Tile *SPTileFirst(register Tile *tp, Rect *rect, TileTypeBitMask *mask)
{
    Point start;

#ifdef PARANOID
    ASSERT(tp && rect && mask, "SPTileFirst");
    /* area must not be degenerate, since we look for area OVERLAP */ 
    ASSERT(rect->r_xbot<rect->r_xtop && rect->r_ybot<rect->r_ytop,
	   "SPTileFirst");
#endif PARANOID

    // Find the first tile.
    start.p_x = rect->r_xbot;
    start.p_y = rect->r_ytop - 1;
    GOTOPOINT(tp, &start);
    if (TOP(tp) <= rect->r_ybot) { return NULL; } // rect outside tile plane boundaries.

    if (TTMaskHasType(mask, DBgetTileType(tp))) {
	return tp;
    } else {
	return SPTileNext(tp,rect,mask);
    }
}



// Wrapper functions for SPTileFirst and SPTileNext.
// These functions save the search state in an SPSearchEnum structure.
//
// Arguments identical to DBPlaneEnumAreaPaint:
// hintTile
// 	Tile at which to begin search, if not NULL.
//	If this is NULL, use the hint tile supplied with plane.
// plane
//	Plane in which tiles lie.  This is used to provide a
//	hint tile in case hintTile == NULL.
//	The hint tile in the plane is updated to be the last tile visited in the area enumeration.
// rect
//	Area to search.  This area should not be degenerate.  Tiles must OVERLAP the area.
// mask
//	Mask of those paint tiles to be passed to func.
void SPTileEnumInit(SPTileEnum *tpe, Tile *hintTile, Plane *plane, Rect *rect, TileTypeBitMask *mask, char *id)
{
    tpe->spe_mask = *mask;
    tpe->spe_area = *rect;
    tpe->spe_plane = plane;
    tpe->spe_tile = hintTile ? hintTile : plane->pl_hint;
    tpe->spe_firsttime = 1;
}


Tile *SPTileEnumNext(SPSearchEnum *tpe)
{
    Tile *tile;
    if (tpe->spe_firsttime) {
	tpe->spe_firsttime = 0;
	tile = SPTileFirst(tpe->spe_tile,&tpe->spe_area,&tpe->spe_mask);
    } else {
	tile = SPTileNext(tpe->spe_tile,&tpe->spe_area,&tpe->spe_mask);
    }
    if (tile) {
	tpe->spe_tile = tile;
    }
    return tile;
}


void SPTileEnumTerm(SPSearchEnum *tpe)
{
    if (tpe->spe_tile) {
	tpe->spe_plane->pl_hint = tpe->spe_tile;
    }
}


#if 0  // Old code
Tile *SPTileEnumNext(SPTileEnum *tpe)
{
    register Tile *tp = tpe->spe_tile;
    register Tile *tpnew;
    register Rect *rect = &tpe->spe_area;

    // Logic is a little wierd so code below is unmodified from original DBPlaneEnumAreaPaint
    if (tpe->spe_firsttime) {
	tpe->spe_firsttime = 0;
    } else {
	goto guts;
    }

    /* Each iteration visits another tile on the LHS of the search area */
    while (TOP(tp) > rect->r_ybot)
    {
	/* Each iteration enumerates another tile */
	/* if (SigInterruptPending) return (1); */
	enumerate:
	if (TTMaskHasType(&tpe->spe_mask, DBgetTileType(tp))) {
	    tpe->spe_plane->pl_hint = tp;
	    tpe->spe_tile = tp;
	    return tp;
	}

	guts:
	tpnew = TR(tp);
	if (LEFT(tpnew) < rect->r_xtop)
	{
	    while (BOTTOM(tpnew) >= rect->r_ytop) tpnew = LB(tpnew);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* Each iteration returns one tile further to the left */
	while (LEFT(tp) > rect->r_xbot)
	{
	    if (BOTTOM(tp) <= rect->r_ybot) 
		return NULL;
	    tpnew = LB(tp);
	    tp = BL(tp);
	    if (BOTTOM(tpnew) >= BOTTOM(tp) || BOTTOM(tp) <= rect->r_ybot)
	    {
		tp = tpnew;
		goto enumerate;
	    }
	}

	/* At left edge -- walk down to next tile along the left edge */
	for (tp = LB(tp); RIGHT(tp) <= rect->r_xbot; tp = TR(tp))
	   continue; 
    }
    return NULL;
}
#endif



// Like SPTileEnumInit, but take a plane list instead of a single tile plane.
// If plane list is null, it will look at all the planes necessary to get all tiletypes in the mask.
void SPPlanesEnumInit(SPSearchEnum *ppe, CellDef *def, PlaneList *planes, 
	Rect *rect, TileTypeBitMask *mask, int flags, char *unused_id)
{
    memset(ppe,0,sizeof(SPSearchEnum));

    if (planes == NULL) {
	planes = ppe->spe_planelist = DBPlaneListFromTypes(mask);
    }
    ppe->spe_def = def;
    ppe->spe_pll = planes;
    if (planes == NULL) {
	return;		// all 0 mask
    }
    // ppe->spe_flags = flags;  // no flags defined.

    SPTileEnumInit(ppe,NULL,def->cd_planes[ppe->spe_pll->pll_num],rect,mask,"");

    // TODO: Should I implement this?
    //if (flags & SP_RECURSIVE) {
    //	ppe->dfp = SPCellEnumInit1(def,rect,SP_RECURSIVE,"whatever");
    //}
}

void SPsxPlanesEnumInit(SPSearchEnum *ppe,SPSearchContext *spx,TileTypeBitMask *mask)
{
    SPPlanesEnumInit(ppe,spx->spx_use->cu_def,NULL,&spx->spx_area,mask,spx->u.f.spx_flags,"");
}


void SPPlanesEnumTerm(SPSearchEnum *ppe)
{
    if (ppe->spe_pll) {
	// The user quit out of the middle of a SPTileEnum.
	// We will carefully terminate this search, even though this function is currently a no-op.
	SPTileEnumTerm(ppe);
    }

    if (ppe->spe_planelist) {
	// Free the planelist that we allocated.
	PlaneListFree(ppe->spe_planelist);
	ppe->spe_planelist = NULL;	// Insurance so we dont accidently free it twice.
    }

    // Will we support hierarchical searches direct from here?
    //if (ppe->spp_???) {
    //	SPInstEnumTerm(ppe->dfp);
    //}
}


Tile *SPPlanesEnumNext(SPSearchEnum *ppe)
{
    Tile *tile;  PlaneList *pll;

    if (ppe->spe_pll == NULL) {
	// SPPlanesEnumInit was passed an all zero tile type mask.
	return NULL;
    }

    if (tile = SPTileEnumNext(ppe)) {return tile;}
    SPTileEnumTerm(ppe);

    // Try other planes until we find one with a tile.
    for (pll = ppe->spe_pll->pll_next; pll; pll = pll->pll_next) {
	ppe->spe_pll = pll;
	SPTileEnumInit(ppe,NULL,ppe->spe_def->cd_planes[pll->pll_num],&ppe->spe_area,&ppe->spe_mask,"");
	if (tile = SPTileEnumNext(ppe)) { return tile; }
	SPTileEnumTerm(ppe);
    }
    SPPlanesEnumTerm(ppe);
    return NULL;
}


/***********************************************************************/
/* Cell Instance enumerator functions */
/***********************************************************************/

static SPSearchContext *spContextHead = NULL;

static SPSearchContext *spNewSearchContext()
{
    SPSearchContext *spx;
    if ((spx = spContextHead) != NULL) {
	spContextHead = spx->spx_parent;
    } else {
	MALLOC(SPSearchContext*, spx, sizeof(SPSearchContext));
    }
    // This memset was taking a whopping 70% of total extraction time, so I just removed it.
    //memset(spx,0,sizeof(SPSearchContext));
    spx->u.spx_all_flags = 0;	// zeros all flags in one swell foop.
    return spx;
}

static void spFreeSearchContext(SPSearchContext *spx)
{
    spx->spx_parent = spContextHead;
    spContextHead = spx;
}

// Returns a new hierarchical search context.
// Area is optional, defaults to entre cell.
// Transform is optional, defaults to identity.
// spxpar is optional, if specified, the parent field of the returned context is linked
// to spxpar.  The SearchContexts are refcnted, so actual freeing does not happen
// until both the original and the derived linked lists of contexts are both freed.
#if 0
SPSearchContext *UNUSED_SPInstEnumInit(CellDef *def, Rect *area, Transform *trans,
	SPSearchContext *spxpar,int flags, char *id)
{
    SPSearchContext *spx;
    if (!(def->cd_flags & CDAVAILABLE)) {
	if (!DBCellRead(def, (char *) NULL, TRUE)) return NULL;
    }
    DBUpdate(def);
    
    spx = spNewSearchContext();
    spx->spx_rootdef = def;
    if (area || trans) {
	// We need to allocate a dummy node just to hold the special
	// area and transform.
	spx->spx_trans = trans ? *trans : GeoIdentityTransform;
	spx->spx_area = area ? *area : *DBBBoxCellDef(def);
	spx2 = spNewSearchContext();
	spx2->spx_parent = spx;
	spx2->u.f.spx_anchor = 2;
	spx = spx2;
    } else {
	spx->u.f.spx_anchor = 1;
    }
    if (spxpar) { spx->spx_parent = spxpar; }

    BPEnumInit(&spx->spx_bpe,def->cd_cellPlane,area,area ? BPE_OVERLAP : BPE_ALL,"SPInstEnumInit2");
    return spx;
}
#endif


// Return 0 on success.
static int spReadDef(CellDef *def)
{
    if (!(def->cd_flags & CD_AVAILABLE)) {
	if (!DBReadCell(def)) {
	    MsgWarnF("Could not read cell %s\n",def->cd_name);
	    return -1;
	}
    }
    DBUpdate(def);
    return 0;
}


SPSearchContext *SPInstEnumInit(CellDef *def, Rect *area, Transform *trans,
	SPSearchContext *spxpar,int flags, char *id)
{
    SPSearchContext *spx;
    if (spReadDef(def) != 0) { return NULL; }
    
    spx = spNewSearchContext();
    spx->spx_rootdef = def;
    // We need to allocate a dummy node just to hold the area and transform.
    spx->spx_parent_trans = trans ? *trans : GeoIdentityTransform;
    spx->spx_parent = spxpar;
    spx->u.f.spx_anchor = 1;
    if (area) {
	spx->spx_parent_area = *area;
	BPEnumInit(&spx->spx_bpe,def->cd_cellPlane,area,area ? BPE_OVERLAP : BPE_ALL,"SPInstEnumInit2");
    } else {
	// Is the parent_area used in this case?
	spx->spx_parent_area = *DBBBoxCellDef(def);
	spx->u.f.spx_allcells = 1;
	spx->spx_use = NULL;	// Will cause initialization.
    }

    return spx;
}


// A convenient short-hand to derive a sub-search from a previous search.
// This searches sub-cells of spx->spx_use in the are specified by spx->spx_area.
SPSearchContext *SPsxInstEnumInit(SPSearchContext *spx,char *id)
{
    return SPInstEnumInit(spx->spx_use->cu_def,&spx->spx_area,&spx->spx_trans,spx,0,id);

    //new = spNewSearchContext();
    //new->spx_parent = spx;
    //new->u.f.spx_anchor = 1;
    //new->spx_parent_trans = spx->spx_trans;
    //new->spx_parent_area = spx->spx_area;
    //BPEnumInit(&new->spx_bpe,spx->spx_use->cu_def->cd_cellPlane,&spx->spx_area,BPE_OVERLAP,"SPsxIEI");
    //return new;
}


SPSearchContext *SPInstEnumNext(SPSearchContext *spx)
{
    CellUse *use = NULL;

    while (spx) {
	if (spx->u.f.spx_descend) {
	    SPSearchContext *new;
	    spx->u.f.spx_descend = 0;
	    if (spReadDef(spx->spx_use->cu_def) != 0) continue;

	    // Note: new->spx_area and new->spx_trans are filled in by transforming
	    // from the parent on the next pass through the while loop.
	    new = spNewSearchContext();
	    new->spx_parent = spx;
	    new->spx_parent_trans = spx->spx_trans;
	    new->spx_parent_area = spx->spx_area;
	    // Just let the sub-search be a normal search for now.  It doesnt really matter.
	    //new->u.f.spx_allcells = spx->u.f.spx_allcells;

	    BPEnumInit(&new->spx_bpe,new->spx_use->cu_def->cd_cellPlane,
		&spx->spx_area,BPE_OVERLAP,"SPInstEnumNext");
	    spx = new;
	    continue;
	}

	if (spx->u.f.spx_inarray) {

	    // We were previously traversing the elements of an arrayed cell.
	    if (++spx->spx_x > spx->spx_ar.ar_xhi) {
		if (++spx->spx_y > spx->spx_ar.ar_yhi) {
		    // This array is history!
		    spx->u.f.spx_inarray = FALSE;
		    continue;
		} else {
		    spx->spx_x = spx->spx_ar.ar_xlo;
		}
	    }

	    {
		Transform tinv;
		SPGetArrayTransform(spx->spx_use,spx->spx_x,spx->spx_y,&spx->spx_atrans);

		GEOINVERTTRANS(&spx->spx_atrans, &tinv);
		GeoTransTrans(&spx->spx_atrans, &spx->spx_parent_trans, &spx->spx_trans);
		GEOTRANSRECT(&tinv, &spx->spx_parent_area, &spx->spx_area);
	    }
	    spx->u.f.spx_descend = (spx->u.f.spx_flags & SP_RECURSIVE);
	    return spx;
	}
	
	if (spx->u.f.spx_allcells) {
	    struct cellkid *nextkid;
	    if (spx->spx_use == NULL) {
		// First time here: init.
		nextkid = spx->spx_rootdef->cd_kids;
		use = NULL;
	    } else {
		use = spx->spx_use->cu_next;
		if (use) {
		    goto found_use;
		}
		nextkid = spx->spx_use->cu_kid->ck_next;
	    }

	    // We will skip kids with no uses in them, even though I doubt it happens.
	    while (nextkid) {
		use = nextkid->ck_uses;
		if (use) { break; }
		nextkid = nextkid->ck_next;
	    }
	} else {
	    use = BPEnumNext(&spx->spx_bpe);
	}

	if (use) {
	    found_use:
	    spx->spx_use = use;
	    if (DBIsArray(use)) {
		ArrayInfo *ap = &spx->spx_ar;
		/* array case */

		DBArrayOverlap(use, &spx->spx_area, &ap->ar_xlo, &ap->ar_xhi, &ap->ar_ylo, &ap->ar_yhi);
		//ap->ar_xsep = (use->cu_xlo > use->cu_xhi) ? -use->cu_xsep : use->cu_xsep;
		//ap->ar_ysep = (use->cu_ylo > use->cu_yhi) ? -use->cu_ysep : use->cu_ysep;

		spx->spx_y = ap->ar_ylo;
		spx->spx_x = ap->ar_xlo-1;  // Will be incremented to get to first element.
		spx->u.f.spx_inarray = TRUE;
		continue;
	    }
	    spx->spx_x = 1;
	    spx->spx_y = 1;
	    //spx->spx_x = use->cu_xlo;
	    //spx->spx_y = use->cu_ylo;

	    // if (SigInterruptPending) goto abort;
	    {
		Transform tinv;
		// tinv is transform from parent to child coords.
		GEOINVERTTRANS(&use->cu_transform, &tinv);
		GeoTransTrans(&use->cu_transform, &spx->spx_parent_trans, &spx->spx_trans);
		GEOTRANSRECT(&tinv, &spx->spx_parent_area, &spx->spx_area);

	    }
	    spx->u.f.spx_descend = (spx->u.f.spx_flags & SP_RECURSIVE);
	    return spx;

	} else {
	    // Pop the previous search.
	    // We are being overly cautious since the spx struct is not actually freed.
	    int anchor = spx->u.f.spx_anchor;
	    SPSearchContext *next = spx->spx_parent;
	    if (! spx->u.f.spx_allcells) {
		BPEnumTerm(&spx->spx_bpe);
	    }
	    spFreeSearchContext(spx);
	    if (anchor) {
		// This was the root of this search or sub-search.
		return NULL;
	    }
	    spx = next;
	    continue;
	}
    }

    return NULL;
}


// Only needed if you terminate early.
// Doesnt hurt to call it anyway (with a NULL spx).
void SPInstEnumTerm(SPSearchContext *spx)
{
    while (spx) {
	SPSearchContext *next = spx->spx_parent;
	if (! spx->u.f.spx_allcells) {
	    BPEnumTerm(&spx->spx_bpe);
	}
	spFreeSearchContext(spx);
	spx = next;
    }
}
