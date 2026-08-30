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
 * DBbbox.c --
 *
 * handles cell bounding boxes.
 */

#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "tile.h"
#include "debug.h"


/*
 * --------------------------------------------------------------------
 *
 * DBBoxCellInitial --
 *
 * Sets cells bbox to rectangle with corners at (0,0) and (1,1)
 * Used as (initial) bbox for empty cells.
 *
 * --------------------------------------------------------------------
 */

void DBBoxCellInitial(CellDef *def)
{
  def->cd_bbox.r_xbot = 0;
  def->cd_bbox.r_ybot = 0;

  def->cd_bbox.r_xtop = 1;
  def->cd_bbox.r_ytop = 1;
}
  

/*
 * --------------------------------------------------------------------
 *
 * DBBoxPlane --
 *
 * Determine the bounding box for the supplied tile plane.
 * The bounding box is the smallest rectangle that completely
 * encloses all non-space tiles.
 *
 * If the tile plane is completely empty, we return a 0x0 bounding
 * box at the origin.
 *
 * Results:
 *	TRUE if the tile plane contains any geometry, FALSE
 *	if it is completely empty.
 *
 * Side effects:
 *	Sets *rect to the bounding rectangle.
 *
 * --------------------------------------------------------------------
 */

bool
DBBBoxPlane(Plane *plane, register Rect *rect)
{
    Tile *left, *right, *top, *bottom, *tp;

    left = plane->pl_left;
    right = plane->pl_right;
    top = plane->pl_top;
    bottom = plane->pl_bottom;

    rect->r_ur = TiPlaneRect.r_ll;
    rect->r_ll = TiPlaneRect.r_ur;

    /*
     * To find the rightmost and leftmost solid edges, we
     * scan along the respective edges.  Our assumption is
     * that the only tiles along the edges are space tiles,
     * which, by the maximum horizontal strip property, must
     * have either solid tiles or the edge of the plane on
     * their other sides.
     */

    for (tp = TR(left); tp != bottom; tp = LB(tp))
	if (RIGHT(tp) < rect->r_xbot)
	    rect->r_xbot = RIGHT(tp);

    for (tp = BL(right); tp != top; tp = RT(tp))
	if (LEFT(tp) > rect->r_xtop)
	    rect->r_xtop = LEFT(tp);

    /*
     * We assume that only space tiles extend all the way
     * from the left edge of the plane to the right.  We
     * also assume that the topmost and bottommost tiles
     * are space tiles.
     */

    rect->r_ytop = BOTTOM(LB(top));
    rect->r_ybot = TOP(RT(bottom));

    /*
     * If the bounding rectangle is degenerate (indicating no solid
     * tiles in the plane), we make it the 1x1 rectangle: (0,0)::(1,1).
     * MHA TODO:  comment doesn't match code.  Safe to use DBBBoxInitial() here.?
     *            
     */
    if (rect->r_xtop < rect->r_xbot || rect->r_ytop < rect->r_ybot)
    {
	rect->r_xbot = rect->r_xtop = 0;
	rect->r_ybot = rect->r_ytop = 0;
	return (FALSE);
    }

    return (TRUE);
}


/*
 * --------------------------------------------------------------------
 *
 * dbBBoxCellCompute --
 *
 * Recompute this cells bounding box.
 * (assumes instaces are up-to-date)
 *
 * --------------------------------------------------------------------
 */

void 
dbBBoxCellCompute(CellDef *cellDef)
                     	/* Cell def whose bounding box may have changed */
{
    Rect rect, area;
    register bool foundAny;
    register Label *label;
    register Polygon *poly;
    int pNum;

    /*
    fprintf(stderr,"DEBUG dbBBoxCellCompute, def=%s\n",
	    cellDef->cd_name);
    */

    /* instance bounding boxes should be up-to-date */
    ASSERT(!(cellDef->cd_changes&DBC_BBOX) && 
	   !(cellDef->cd_changesPending&DBC_BBOX),
	   "dbBBoxCellCompute");

    /* set when first item factored into bbox! */
    foundAny = FALSE;

    /* include paint planes  (excludes DRC_CHECK plane) */
    for (pNum = PL_PAINTBASE; pNum < DBNumPlanes; pNum++)
    {
      if (pNum == PL_DRC_CHECK) continue;
      if (!DBBBoxPlane(cellDef->cd_planes[pNum], &rect)) continue;

      if (foundAny)
      {
	  GeoInclude(&rect, &area);
      }
      else
      {
	area = rect;
	foundAny = TRUE;
      }
    }

    /*
     * Include the area of labels.
     */
    for (label = cellDef->cd_labels; label != NULL;  label = label->lab_next)
    {
	if (foundAny)
	{
	    if (label->lab_rect.r_xbot < area.r_xbot)
		area.r_xbot = label->lab_rect.r_xbot;
	    if (label->lab_rect.r_ybot < area.r_ybot)
		area.r_ybot = label->lab_rect.r_ybot;
	    if (label->lab_rect.r_xtop > area.r_xtop)
		area.r_xtop = label->lab_rect.r_xtop;
	    if (label->lab_rect.r_ytop > area.r_ytop)
		area.r_ytop = label->lab_rect.r_ytop;
	}
	else
	{
	    area = label->lab_rect;
	    foundAny = TRUE;
	}
    }

    /*
     * Include the area of polygons.
     */
    for (poly = cellDef->cd_polygons; poly != NULL;  poly = poly->poly_next)
    {
	if (foundAny)
	{
	  GeoInclude(&poly->poly_bbox, &area);
	}
	else
	{
	    area = poly->poly_bbox;
	    foundAny = TRUE;
	}
    }

    /* include area of subcells TODO optimize this! */
    {
      BPEnum bpe;
      CellUse *use;

      BPEnumInit(&bpe,
		 cellDef->cd_cellPlane,
		 NULL,
		 BPE_ALL,
		 "DBbbox");

      while(use = BPEnumNext(&bpe)) 
      {
	if( foundAny)
	{ 
	  GeoInclude(&use->cu_bbox, &area);
	}
	else
	{
	    area = use->cu_bbox;
	    foundAny = TRUE;
	}
      }

      BPEnumTerm(&bpe);
    }

    /*
     * If cell is completely empty, produce a 1x1 box with its
     * lower left corner at the origin.
     */
    if (!foundAny)
    {
	area.r_xbot = area.r_ybot = 0;
	area.r_xtop = area.r_ytop = 1;
    }

    /* make bbox is at least one unit high and wide */
    if (area.r_xbot == area.r_xtop) area.r_xtop += 1;
    if (area.r_ybot == area.r_ytop) area.r_ytop += 1;

    /* set new bbox */
    cellDef->cd_bbox = area;
}
