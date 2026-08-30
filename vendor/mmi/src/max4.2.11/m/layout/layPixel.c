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



/* layPixel.c -
 *
 * Maintains single pixel "images" of defs, for use when zoomed WAY out.
 *
 */

#include <stdio.h>
#include "magic.h"
#include "utils.h"
#include "message.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "signals.h"
#include "malloc.h"
#include "layout.h"
#include "layint.h"
#include "styles.h"
#include "graphics.h"

extern TileTypeBitMask layLabelLayers;

/*
 * ----------------------------------------------------------------------------
 * layPixelInvalidate --
 *
 * Invalidate all cached pixel values.
 *
 * ----------------------------------------------------------------------------
 */
void layPixelInvalidate(CellDef *def)
                              /* if def = NULL, invalidate all */
{
  PixelValue *pv;

  if(def)
  {
    if((pv=(PixelValue *) def->cd_pixelValue))
    {
      pv->pv_version = DBVStampInvalid;
    }

    return;
  }

  for(def=DBCellDefs; def; def=def->cd_next)
  {
    if((pv=(PixelValue *) def->cd_pixelValue))
    {
      pv->pv_version = DBVStampInvalid;
    }
  }
}

/*
 * ----------------------------------------------------------------------------
 * layPixelValid -
 *
 * Returns TRUE iff current single pixel values for cell are up-to-date
 *
 * ----------------------------------------------------------------------------
 */
bool layPixelValid(CellDef *def)
{
  PixelValue *pv = (PixelValue *) def->cd_pixelValue;

  if(!pv) return FALSE;

  return DBVStampSame(&pv->pv_version, &def->cd_vDISPLAY);
}

/*
 * ----------------------------------------------------------------------------
 * layPixelValueNew --
 *
 * Allocate and initialize PixelValue structure.
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ PixelValue *layPixelValueNew(void)
{
  PixelValue *pv;

  MALLOC(PixelValue *, pv, sizeof(PixelValue));
  pv->pv_version = DBVStampInvalid;

  return pv;
}


/*
 * ----------------------------------------------------------------------------
 *
 * alwaysOneFunc --
 *
 * 	returns 1 to indicate search has found something!
 *
 * ----------------------------------------------------------------------------
 */
static int
alwaysOneFunc(register Tile *tile, TreeContext *cxp)
{
  return 1;
}

/*
 * ----------------------------------------------------------------------------
 * noneExpanded --
 *
 *  Returns true if no instances of the given kid def
 *  are expanded.
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ bool noneExpanded(CellKid *kid)
{
  CellUse *use;
  int bitMask = layDisplayWindow->lay_bitmask;

  for(use=kid->ck_sibUses; use; use=use->cu_nextSib)
  {
    if(DBIsExpand(use, bitMask)) return FALSE;
  }

  return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 * allExpanded --
 *
 *  Returns true if all instances of the given kid def
 *  are expanded.
 *
 * ----------------------------------------------------------------------------
 */
static __inline__ bool allExpanded(CellKid *kid)
{
  CellUse *use;
  int bitMask = layDisplayWindow->lay_bitmask;

  for(use=kid->ck_sibUses; use; use=use->cu_nextSib)
  {
    if(!DBIsExpand(use, bitMask)) return FALSE;
  }

  return TRUE;
}

/*
 * ----------------------------------------------------------------------------
 * layPixelLabel --
 *
 *   Compute label pixel value for cell (ignoring subcells)
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ int layPixelLabel(CellDef *def)
{
  TileTypeBitMask *mask = &layLabelLayers;  /* visible and space layers */
  Label *lab;

  for (lab = def->cd_labels; lab; lab = lab->lab_next)
  {
    if( !TTMaskHasType(mask, lab->lab_type) ) continue;

    /* assume we are not the edit cell */
    if(lab->lab_kind == LAB_COMMENT) continue;
    if(lab->lab_kind == LAB_LOCAL) continue;

    if((lab->lab_kind == LAB_HIDDEN) && 
       !(layDisplayWindow->lay_flags & Lay_SEEHIDDENLABELS)) continue;

    /* set flag bit so result guaranteed non-zero */
    return layDrawStyleTable[STYLE_LABEL].ds_color | GrMaskFlag;
  }

  return 0;
}

/*
 * ----------------------------------------------------------------------------
 * layPixelSubcell --
 *
 *   Returns color for unexpanded subcells (if there is one)
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ int layPixelSubcell(CellDef *def)
{
  CellKid *kid;
	  
  /* search kids */
  for(kid = def->cd_kids; kid; kid=kid->ck_next)
  {
    /* set flag bit so result guaranteed non-zero */
    if(!allExpanded(kid)) return layDrawStyleTable[STYLE_UNEXPANDED_INSTANCE].ds_color | GrMaskFlag;
  }

  return 0;
}

/*
 * ----------------------------------------------------------------------------
 * layPixelFlyline --
 *
 *   Compute pixel value for flyline display (ignoring subcells)
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ int layPixelFlyline(CellDef *def)
{
  if(def->cd_flyLines)
  {
    /* set flag bit so result guaranteed non-zero */
    return layDrawStyleTable[STYLE_FLYLINE].ds_color | GrMaskFlag;
  }

  return 0;
}

/*
 * ----------------------------------------------------------------------------
 * layPixelPaintGroup --
 *
 *   Compute given paint group pixel value for cell 
 *   (assumes subcells have already been "painted")
 *
 *   If non-outlined style found, ignore outlined styles. 
 *   If solid non-outlined style found, ignore stippled styles. 
 *
 * ----------------------------------------------------------------------------
 */

static __inline__ void layPixelPaintGroup(CellDef *def, StyleGroup *group)
{
  int style;
  PixelValue *pv = (PixelValue *) def->cd_pixelValue;
  int *colorp = &(pv->pv_colors[group->sg_number]);
  int somethingFound = FALSE; 
  int nonOutlineFound = FALSE;
  int solidFound = FALSE;
  int allC = *colorp;
  int nonOutlineC = *colorp;
  int solidC = *colorp;

  for (style=0;  style<MAXTILESTYLES;  style++)
  {
    int planeNum;
    int planeMask;
    TileTypeBitMask visTypes;
    TileTypeBitMask *types;

    /* is this style in the current group? */
    if(!layStyleInGroup(style,group)) continue;

    /* visTypes = types to be drawn in this style that are visible in window */
    types = LayStyleToTypes(style);
    TTMaskAndMask3(&visTypes, types, &layDisplayWindow->lay_visibleLayers);
    if (TTMaskIsZero(&visTypes)) continue;

    /* tile planes */
    {
      PlaneList *visPlanes = DBPlaneListFromTypes(&visTypes);
      PlaneList *pll;

      for(pll = visPlanes;
	  pll;
	  pll = pll->pll_next)
      {
	if (DBPlaneEnumAreaPaint(NULL, 
				 def->cd_planes[pll->pll_num],
				 &def->cd_bbox,
				 &visTypes,
				 alwaysOneFunc, 
				 (ClientData) NULL))
	{
	  DisplayStyle *ds = &layDrawStyleTable[style];
	  int m = ds->ds_writeMask;
	  int c = ds->ds_color;

	  somethingFound = TRUE;
	  allC = (allC & ~m) | (c & m);	

	  if(ds->ds_outline != 0) continue;
	  nonOutlineFound = TRUE;
	  nonOutlineC = (nonOutlineC & ~m) | (c & m);	

	  if(ds->ds_stipple != 0) continue;
	  solidFound = TRUE;	  
	  solidC = (solidC & ~m) | (c & m);	
	}
      }

      PlaneListFree(visPlanes);
    }

    /* TODO polygons */
  }

  if(solidFound)
  {
    /* set flag bit so result guaranteed non-zero */
    *colorp = solidC | GrMaskFlag;
  }
  else if (nonOutlineFound)
  {
    /* set flag bit so result guaranteed non-zero */
    *colorp = nonOutlineC | GrMaskFlag;
  }
  else if (somethingFound)
  {
    /* set flag bit so result guaranteed non-zero */
    *colorp = allC | GrMaskFlag;
  }
  /* else, don't change current value */
}


/*
 * ----------------------------------------------------------------------------
 * layPixelUpdate --
 *
 *   Recompute single pixel values stored with def.
 *
 * ----------------------------------------------------------------------------
 */

static void layPixelUpdate(CellDef *def)
{
  PixelValue *pv = (PixelValue *) def->cd_pixelValue;
  CellKid *kid;
  int i;
  int c;

  if(!pv)
  {
    pv = layPixelValueNew();
    def->cd_pixelValue = (ClientData) pv;
  }

  if( DBVStampSame(&pv->pv_version, &def->cd_vDISPLAY) ) return;

  /* DEBUG
  fprintf(stderr,"DEBUG layPixelUpdate of %s\n", def->cd_name);
  */

  /* initialize colors to zero */
  for(i=0; i<= PV_LAST; i++) pv->pv_colors[i] = 0; 

  /* search kids */
  for(kid = def->cd_kids; kid; kid=kid->ck_next)
  {
    if(noneExpanded(kid)) continue;

    for(i=0; i<= PV_LAST; i++)
    {
      c = layPixelGet(kid->ck_def, i);
      if(c) pv->pv_colors[i] = c; 
    }
  }

  /* paint groups */
  {
    StyleGroup *group;

    for(group = layStyleGroups; 
	group != NULL; 
	group = group->sg_next)
    {
      layPixelPaintGroup(def, group);
    }
  }

  /* labels */
#ifdef HIDE
  /* don't bother displaying labels for zero pixel cells! */
  if( !(pv->pv_colors[PV_LABEL]))
  {
    pv->pv_colors[PV_LABEL] = layPixelLabel(def);
  }
#endif

  /* unexpanded subcell */
  if(!(pv->pv_colors[PV_SUBCELL]))
  {
    pv->pv_colors[PV_SUBCELL] = layPixelSubcell(def);
  }

  /* flylines */
  if( !(pv->pv_colors[PV_FLYLINE]))
  {
    pv->pv_colors[PV_FLYLINE] = layPixelFlyline(def);
  }

  /* update version */ 
  pv->pv_version = def->cd_vDISPLAY;
}

/*
 * ----------------------------------------------------------------------------
 * layPixelGet --
 *
 *   returns indicated single pixel image of cell def
 *
 * ----------------------------------------------------------------------------
 */
int layPixelGet(CellDef *def, int index)
{
  layPixelUpdate(def);

  /* DEBUG
   fprintf(stderr,"layPixelGet, DEBUG def=%s index=%d color=0%o\n",
	  def->cd_name, 
	  index, 
	  ((PixelValue *)(def->cd_pixelValue))->pv_colors[index]);
  */

  return ((PixelValue *)(def->cd_pixelValue))->pv_colors[index];
}

