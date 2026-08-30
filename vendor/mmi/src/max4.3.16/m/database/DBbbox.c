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
#include "commands.h"

/* planes included in user bounding box */
PlaneList *dbBBoxUserPlanes = NULL;

/* planes included in actual bounding box, but not user bbox */
PlaneList *dbBBoxNonUserPlanes = NULL;

/* types included in user bounding box */
TileTypeBitMask dbBBoxUserTypes;

/*
 * --------------------------------------------------------------------
 *
 * dbBBoxSetUserPlanes --
 *
 * Set user and nonuser planelists from tiletype mask.
 *
 * --------------------------------------------------------------------
 */


/* dbBBoxFunc - Callback func for dbBBoxSetUserPlanes (below) 
 *    invalidates defs bbox.
 */
static int
dbBBoxFunc(CellDef *def, 
	   ClientData clientdata)
{
  if(!def->cd_flags&CD_AVAILABLE || def->cd_flags&CD_GENERATED) return 0;

  def->cd_flags |= (CD_CHANGED_BBOX|CD_CHANGED_INSTANCE);
  def->cd_version = DBVStampInvalid; 
  return 0;
}


void dbBBoxSetUserPlanes(TileTypeBitMask *mask)
{
  int pNum;

  /* clear lists */
  PlaneListFree(dbBBoxUserPlanes);
  dbBBoxUserPlanes = NULL;
  PlaneListFree(dbBBoxNonUserPlanes);
  dbBBoxNonUserPlanes = NULL;

  /* repopulate lists */
  for (pNum = 1; pNum < DBNumPlanes; pNum++)
  {
    /* don't include DRC_CHECK plane in bounding boxes */ 
    if(pNum == PL_DRC_CHECK) continue;

    if(TTMaskIntersect(&DBPlaneTypes[pNum],mask))
    {
      /* user plane */
      DBPlaneListAdd(&dbBBoxUserPlanes, pNum);
    }
    else
    {
      /* other plane */
      DBPlaneListAdd(&dbBBoxNonUserPlanes, pNum);
    }
  }

  /* compute type mask */
  dbBBoxUserTypes = DBPlaneListToTypes(dbBBoxUserPlanes);

  /* include subcells? */
  if(TTMaskHasType(mask, L_CELL))
  {
    TTMaskSetType(&dbBBoxUserTypes, L_CELL);
  }

  /* invalidates all user bboxes! */
  DBCellSrDefs(0, dbBBoxFunc, NULL);

  /* redisplay all windows */
  LayChangedWindow(NULL,NULL);
}


/*
 * --------------------------------------------------------------------
 *
 * DBBBoxUserTypes2S --
 *
 * 'print' types factored into user bbox.
 * returns TRUE normally, FALSE on truncation.
 *
 * --------------------------------------------------------------------
 */

bool dbBBoxUserTypes2S(char *buf, int bufSize)
{
  int pNum;
  int first = TRUE;
  int i=0;
  int t;

  for(t=1; t<DBNumTypes; t++)
  {
    char *p;

    /* skip types not in mask */
    if(!TTMaskHasType(&dbBBoxUserTypes,t)) continue;

    if(!first) 
    {
      if(i==bufSize) goto overflow;
      buf[i++] = ',';
    }
    else
    {
      first=FALSE;
    }

    for(p=DBTypeLongNameTbl[t]; *p!='\0'; p++)
    {
      if(i==bufSize) goto overflow;
      buf[i++] = *p;
    }
  }

  /* 'subcell' pseudo layer? */
  if(TTMaskHasType(&dbBBoxUserTypes,L_CELL))
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

    for(p="subcell"; *p!='\0'; p++)
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
 * --------------------------------------------------------------------
 *
 * DBBoxCellInitial --
 *
 * Sets cells bbox and user-bbox to small rectangle near origin.
 * Used as (initial) bbox for empty cells.
 *
 * --------------------------------------------------------------------
 */

void DBBoxCellInitial(CellDef *def)
{
  int w = 1;

  def->cd_bbox.r_xbot = 0;
  def->cd_bbox.r_ybot = 0;

  def->cd_bbox.r_xtop = w;
  def->cd_bbox.r_ytop = w;

  def->cd_userBBox = def->cd_bbox;
}
  

/*
 * --------------------------------------------------------------------
 *
 * DBBBoxPlane --
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
 * Recompute this cells bounding boxes:  actual, and user bbox.
 * (assumes instaces are up-to-date)
 *
 * --------------------------------------------------------------------
 */

void 
dbBBoxCellCompute(CellDef *cellDef)
                     	/* Cell def whose bounding box may have changed */
{
    bool foundAny = FALSE;  /* set when first item factored into bbox */ 
    bool foundUser = FALSE; /* set when first itme factored into user bbox */
    Rect bbox, userBBox;
    PlaneList *pll;
    register Polygon *poly;
    register Label *label;

    /*
    fprintf(stderr,"DEBUG dbBBoxCellCompute, def=%s\n",
	    cellDef->cd_name);
    */

    /* if uninitialiazed, just return */
    if(!dbBBoxUserPlanes && !dbBBoxNonUserPlanes) return; 

    /* instance bounding boxes should be up-to-date */
    ASSERT(!(cellDef->cd_flags&CD_CHANGED_INSTANCE), "dbBBoxCellCompute");

    /*
     * add user paint 
     */
    for(pll=dbBBoxUserPlanes; pll; pll = pll->pll_next)
    {
      int pNum = pll->pll_num;
      Rect r;
      if (!DBBBoxPlane(cellDef->cd_planes[pNum], &r)) continue;

      if (foundUser)
      {
	  GeoIncludeRectInBBox(&r, &userBBox);
      }
      else
      {
	userBBox = r;
	foundUser = TRUE;
      }
    }

    /* 
     *  add non-user paint 
     * (excludes DRC_CHECK plane) 
     */
    for(pll=dbBBoxNonUserPlanes; pll; pll = pll->pll_next)
    {
      int pNum = pll->pll_num;
      Rect r;

      if (!DBBBoxPlane(cellDef->cd_planes[pNum], &r)) continue;

      if (foundAny)
      {
	  GeoIncludeRectInBBox(&r, &bbox);
      }
      else
      {
	bbox = r;
	foundAny = TRUE;
      }
    }

    /*
     * add polygons
     */
    for (poly = cellDef->cd_polygons; poly != NULL;  poly = poly->poly_next)
    {
      if(TTMaskHasType(&dbBBoxUserTypes,poly->poly_type))
      {
	/* user layer polygon */
	if (foundUser)
	{
	  GeoIncludeRectInBBox(&poly->poly_bbox, &userBBox);
	}
	else
	{
	  userBBox = poly->poly_bbox;
	  foundUser = TRUE;
	}
      }
      else
      {
	/* non user layer polygon */
	if (foundAny)
	{
	  GeoIncludeRectInBBox(&poly->poly_bbox, &bbox);
	}
	else
	{
	  bbox = poly->poly_bbox;
	  foundAny = TRUE;
	}
      }
    }

    /*
     * Include labels.
     */
    for (label = cellDef->cd_labels; label != NULL;  label = label->lab_next)
    {
      if(TTMaskHasType(&dbBBoxUserTypes,label->lab_type))
      {
	/* user layer label */
	if (foundUser)
	{
	  GeoIncludeRectInBBox(&label->lab_rect,&userBBox);
	}
	else
	{
	    userBBox = label->lab_rect;
	    foundUser = TRUE;
	}
      }
      else
      {
	/* non-user layer label */
	if (foundAny)
	{
	  GeoIncludeRectInBBox(&label->lab_rect,&bbox);
	}
	else
	{
	    bbox = label->lab_rect;
	    foundAny = TRUE;
	}
      }
    }

    /* include subcell areas */
    {
      BPEnum bpe;
      CellUse *use;

      /* if user bbox empty, or 'cell' set, 
       *  subcell bboxes in user bbox
       */  
      bool userIncludeCells = !foundUser ||
	TTMaskHasType(&dbBBoxUserTypes,L_CELL);

      BPEnumInit(&bpe,
		 cellDef->cd_cellPlane,
		 NULL,
		 BPE_ALL,
		 "DBbbox");

      while(use = BPEnumNext(&bpe)) 
      {
	/* user */
	if(userIncludeCells)
	{
	  Rect r;

	  GEOTRANSRECT(&use->cu_transform, &use->cu_def->cd_userBBox, &r);
	  if(foundUser)
	  { 
	    GeoIncludeRectInBBox(&r, &userBBox);
	  }
	  else
	  {
	    userBBox = r;
	    foundUser = TRUE;
	  }
	}

	/* non-user */
	if( foundAny)
	{ 
	  GeoIncludeRectInBBox(&use->cu_bbox, &bbox);
	}
	else
	{
	    bbox = use->cu_bbox;
	    foundAny = TRUE;
	}
      }

      BPEnumTerm(&bpe);
    }

    /* include user bbox in actual */
    if(foundUser)
    {
      if(foundAny)
      {
	GeoIncludeRectInBBox(&userBBox,&bbox);
      }
      else
      {
	bbox = userBBox;
	foundAny = TRUE;
      }
    }

    /*
     * If cell is completely empty, produce a 1x1 box with its
     * lower left corner at the origin.
     */
    if (!foundAny)
    {
	bbox.r_xbot = 0;
	bbox.r_ybot = 0;
	bbox.r_xtop = 1;
	bbox.r_ytop = 1;
	foundAny = TRUE;
    }

    /* if null user bbox, default to real bbox */ 
    if (!foundUser)
    {
      userBBox = bbox;
      foundUser = TRUE;
    }

    /* make bboxes at least one unit high and wide */
    if (bbox.r_xbot == bbox.r_xtop) bbox.r_xtop += 1;
    if (bbox.r_ybot == bbox.r_ytop) bbox.r_ytop += 1;
    if (userBBox.r_xbot == userBBox.r_xtop) userBBox.r_xtop += 1;
    if (userBBox.r_ybot == userBBox.r_ytop) userBBox.r_ytop += 1;

    /* DEBUG
    fprintf(stderr,"DEBUG dbBBoxCellCompute, def=%s END.\n",
	    cellDef->cd_name);
    fprintf(stderr,"foundUser=%d foundAny=%d\n", foundUser, foundAny);
    DumpRect("userBBox = ", &userBBox);
    DumpRect("bbox = ", &bbox);
    */

    /* set new bboxes */
    cellDef->cd_bbox = bbox;
    cellDef->cd_userBBox = userBBox;
}

