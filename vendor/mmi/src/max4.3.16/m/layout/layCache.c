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



/* layCache.c -
 *
 * Implements pixel image cacheing for subcells.
 *
 */

#include <stdio.h>
#include "magic.h"
#include "utils.h"
#include "message.h"
#include "geometry.h"
#include "styles.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "undo.h"
#include "signals.h"
#include "memory.h"
#include "layout.h"
#include "layint.h"
#include "layDraw.h"
#include "graphics.h"

/* list of all cache entrys */
static LayoutCache *layCache = NULL;

/* stack of graphics diversions 
 * (subcells being diverted from window to pixmaps for cacheing)
 */
LayoutCache *layCacheStack = NULL;



/*
 * ----------------------------------------------------------------------------
 * layCacheDump --
 *
 *	debug: print cache contents.
 *
 * ----------------------------------------------------------------------------
 */

void
layCacheDump(CellDef *def)
                       /* if def = NULL, dump all defs */
{
  if(def)
  {
    LayoutCache *lc;

    for(lc = (LayoutCache *) def->cd_imageCache; lc; lc=lc->lc_next)
    {
/*
      fprintf(stderr,"lc:  def=%s styleGroup=%d clippedEdges=%d\n",
	      lc->lc_def->cd_name, 
	      lc->lc_styleGroup->sg_number, 
	      lc->lc_clippedEdges);
      DumpRect("lc_relAreaDB ", &lc->lc_relAreaDB);
      DumpRect("lc_area ", &lc->lc_area);
      fprintf(stderr,"\n");
*/      
    }

    return;
  }

  for(def=DBCellDefs; def; def=def->cd_next)
  {
    if(def->cd_imageCache) layCacheDump(def);
  }
}


/*
 * ----------------------------------------------------------------------------
 * layCacheLookup --
 *
 *	Lookup a cache entry for given def and orientation.
 *
 *      Does not create new entrys, just returns NULL on failure.
 * ----------------------------------------------------------------------------
 */

LayoutCache *
layCacheLookup(CellDef *def,          /* The subcell */
	       Transform *t,          /* orientation must match! */ 
	       StyleGroup *group,     /* display style group buffer corresponds
				       * to.
				       */
	       Rect *relAreaDB)       /* area relative to def bbox */
{
  LayoutCache *lc;

/*
  fprintf(stderr,"DEBUG top of layCacheLookup, def=%s\n",
	  def->cd_name);
  layCacheDump(NULL);
*/

  /* if cache out of date, clear it and return NULL */
  if(def->cd_imageCache && 
     !DBVStampSame(&((LayoutCache *)def->cd_imageCache)->lc_version, 
		   &def->cd_version))
  {
     layCacheClear(def);
  }

/*
  fprintf(stderr,"DEBUG layCacheLookup B, def=%s\n",
	  def->cd_name);
  layCacheDump(NULL);
*/

  /* lookup */
  for(lc=(LayoutCache *) def->cd_imageCache; 
      lc; 
      lc = lc->lc_next)
  {
    if(group == lc->lc_styleGroup &&
       lc->lc_transform.t_a == t->t_a && 
       lc->lc_transform.t_b == t->t_b && 
       lc->lc_transform.t_d == t->t_d && 
       lc->lc_transform.t_e == t->t_e &&
       GEO_SURROUND(&lc->lc_relAreaDB, relAreaDB))	 
     {
       /* hit! */
       return lc;
     }
  };

  /* not found */
  return NULL;
}


/*
 * ----------------------------------------------------------------------------
 * layCacheClear --
 *
 *	Free cache.
 *
 * ----------------------------------------------------------------------------
 */

void
layCacheClear(CellDef *def)
                       /* if def = NULL, clear all defs */
{
  if(def)
  {
/*
    fprintf(stderr,"DEBUG layCacheClear, def=%s\n",
	    def->cd_name);
*/

    while(def->cd_imageCache)
    {
      LayoutCache *lc = def->cd_imageCache;

      def->cd_imageCache = lc->lc_next;
      if(lc->lc_pixmap) GrFreePixmap(lc->lc_pixmap);    
      if(lc->lc_stipple) GrFreeStipple(lc->lc_stipple);    
      FREE(lc);
    }
    return;
  } 

  for(def=DBCellDefs; def; def=def->cd_next)
  {
    if(def->cd_imageCache) layCacheClear(def);
  }
}



/*
 * ----------------------------------------------------------------------------
 * layCacheFlushClipped -
 *
 *	Flush pixmaps of cells that are clipped on specified edges
 *
 * ----------------------------------------------------------------------------
 */

void
layCacheFlushClipped(int edges,       /* delete pixmaps with given edges clipped */
		      CellDef *def)   /* if NULL, flush partials from all defs */
{
  if(def)
  {
    LayoutCache **prevp = (LayoutCache **) &def->cd_imageCache; 

    while(*prevp)
    {
      LayoutCache *lc = *prevp;

      if(!(edges&lc->lc_clippedEdges))
      {
	/* skip item */
	prevp = &lc->lc_next;
	continue;
      }

      /* delete item */
      *prevp = lc->lc_next;
/*
      fprintf(stderr,"layCacheFlushClipped DEBUG, flushing def=%s edges=%d (clipping=%d)\n",
	      def->cd_name, lc->lc_clippedEdges, edges);
*/
      if(lc->lc_pixmap) GrFreePixmap(lc->lc_pixmap);    
      if(lc->lc_stipple) GrFreeStipple(lc->lc_stipple);    
      FREE(lc);
    }

    return;
  } 

  for(def=DBCellDefs; def; def=def->cd_next)
  {
    if(def->cd_imageCache) layCacheFlushClipped(edges, def);
  }
}


/*
 * ----------------------------------------------------------------------------
 * layStackChanged --
 *
 *      Called when diversion stack pushed/poped.
 *
 *	Set graphics to draw to top of cache stack.
 *      And set up clipping accordingly.
 * ----------------------------------------------------------------------------
 */
static __inline__ void layStackChanged(void)
{
  LayoutCache *lc = layCacheStack;
  
  if(lc)
  {
    /* make pixmap current drawable */
    GrSetDrawable(lc->lc_pixmap);
    layDrawSetClip(NULL,&lc->lc_area);
  }
  else
  {
    /* stack empty, graphics go to general overlay */
    GrSetDrawable(layDisplayWindow->lay_genOverlay);
    layDrawSetClip(&layDisplayAreaW, &layDisplayWindow->lay_area);
  }
}
     

/*
 * ----------------------------------------------------------------------------
 * layCacheNew --
 *
 *	Creates a new cache entry for def/orientation
 *      initials it to 0's
 *      and pushes it on to the diversion stack 
 *      (so future graphics diverted to it)
 * 
 *       Returns null if width or height would be zero.
 *
 *      SHOULD NOT BE CALLED IF AN ENTRY ALREADY EXISTS!
 * ----------------------------------------------------------------------------
 */
LayoutCache *
layCacheNew(CellDef *def,      /* The subcell */
	    Transform *t,      /* orientation must match! */ 
	    StyleGroup *group, /* display style group buffer corresponds to. */
	    Rect *relAreaDB)     /* area of cache relative to cell bbox */
{
  LayoutCache *lc;
  int width, height;

  /* compute pixmap dimensions (in pixels) */
  /* +2 = +1 (to include end pixel) 
   *      +1 (since layDimToWindow up to one pixel short) 
   */
  width = relAreaDB->r_xtop - relAreaDB->r_xbot;
  width = layDimToWindow(layDisplayWindow, width) + 2;
  height = relAreaDB->r_ytop - relAreaDB->r_ybot;
  height = layDimToWindow(layDisplayWindow, height) + 2;

  /* limit max cache size */
  if(width > layCacheMaxDim || height > layCacheMaxDim) return NULL;

  /* create new entry */
  MALLOC(LayoutCache *, lc, sizeof(LayoutCache));
  lc->lc_def = def;
  lc->lc_version = def->cd_version;
  lc->lc_transform = *t;
  lc->lc_styleGroup = group;

  /* pixmap area relative to lower left corner of cell */
  lc->lc_relAreaDB = *relAreaDB;

  /* clipped edges */
  lc->lc_clippedEdges = 0;
  if(lc->lc_relAreaDB.r_xbot != 0) lc->lc_clippedEdges |= LE_LEFT;
  if(lc->lc_relAreaDB.r_ybot != 0) lc->lc_clippedEdges |= LE_BOTTOM;
  if(lc->lc_relAreaDB.r_xtop != 
     def->cd_bbox.r_xtop - def->cd_bbox.r_xbot) lc->lc_clippedEdges |= LE_RIGHT;
  if(lc->lc_relAreaDB.r_ytop != 
     def->cd_bbox.r_ytop - def->cd_bbox.r_ybot) lc->lc_clippedEdges |= LE_TOP;


/*  
   fprintf(stderr, "layCacheNew def=%s, edges=%d\n",
	  def->cd_name, lc->lc_clippedEdges); 
 */

  /* pixmap bbox in pixels */
  lc->lc_area.r_xbot = 0;
  lc->lc_area.r_xtop = width - 1;
  lc->lc_area.r_ybot = 0;
  lc->lc_area.r_ytop = height - 1;

  /* link into def */
  lc->lc_next = (LayoutCache *) def->cd_imageCache;
  def->cd_imageCache = (ClientData) lc;

  /* create pixmap */
  ASSERT(width>0 && height>0,"layCacheNew");
  lc->lc_pixmap = GrCreatePixmap(width, height);
  lc->lc_stipple = NULL;

  /* push onto diversion stack */
  lc->lc_stack = layCacheStack;
  layCacheStack = lc;
  layStackChanged();

  /* Initialize pixmap to 0's */
  GrSetStipple(NULL);
  GrSetWriteMask(GrMaskAll);  /* color and flag bits */
  GrSetColor(0);   
  GrFillRect(lc->lc_area.r_xbot, 
	     lc->lc_area.r_ybot, 
	     lc->lc_area.r_xtop, 
	     lc->lc_area.r_ytop);

  return lc;
}

/*---------------------------------------------------------
 * layCachePop --
 *	
 *     End diversion of graphics to pixmap cache, 
 *
 *---------------------------------------------------------
 */
void layCachePop(void)
{
  LayoutCache *lc = layCacheStack;

  layCacheStack = lc->lc_stack;
  layStackChanged();
}

/*------------------------------------------------------------------------------
 * layCacheCoords
 *	
 *     compute xfer coords (shared by layCacheCopy and layCacheAdjustStippleOffset)
 *------------------------------------------------------------------------------
 */
static __inline__ void 
layCacheCoords(LayoutCache *lc,         /* cache entry to copy */
	       Rect *bboxDB,            /* def bbox 
					 * in DB coordinates.
					 */
	       Rect *relAreaDB,         /* area to copy
					 * relative to def bbox.
					 */
	       int *widthp, 
	       int *heightp, 
	       int *srcXp, 
	       int *srcYp, 
	       int *destXp, 
	       int *destYp)
{
  /* dest pixel coordinates:  destX, destY, width, height */
  {
    Rect destDB, dest; 

    /* dest rect */
    destDB.r_xbot = relAreaDB->r_xbot + bboxDB->r_xbot;
    destDB.r_ybot = relAreaDB->r_ybot + bboxDB->r_ybot;
    destDB.r_xtop = relAreaDB->r_xtop + bboxDB->r_xbot;
    destDB.r_ytop = relAreaDB->r_ytop + bboxDB->r_ybot;
    layRectToWindowInt(layDisplayWindow, &destDB, &dest);

    /* pixel dimensions */
    *widthp = dest.r_xtop - dest.r_xbot + 1;
    *heightp = dest.r_ytop - dest.r_ybot + 1;

    /* dest lower left corner */
    *destXp = dest.r_xbot;
    *destYp = dest.r_ybot;
  }

  /* compute src pixel coordinates:  srcX, srcY */
  {
    Point refDB, ref;  /* loc of lower left corner in dest, if
		        * whole pixmap were copied.
		        * (Determines src -> dest translation)
		        */

    /* lower left corner of pixmap in dest coordinates */
    refDB.p_x = lc->lc_relAreaDB.r_xbot + bboxDB->r_xbot;
    refDB.p_y = lc->lc_relAreaDB.r_ybot + bboxDB->r_ybot;
    layPointToWindowInt(layDisplayWindow, &refDB, &ref);
    
    /* src lower left corner */
    *srcXp = *destXp - ref.p_x;
    *srcYp = *destYp - ref.p_y;
  }
}

/*---------------------------------------------------------
 * layCacheAdjustStippleOffset --
 *	
 *     Set stipple offset so stippling inside current cache entry will match
 *     main window 0 offset stipple.
 *---------------------------------------------------------
 */
void layCacheAdjustStippleOffset(Rect *bboxDB,            /* def bbox 
							   * in DB coordinates.
							   */
				 Rect *relAreaDB)         /* area to copy
							   * relative to def bbox.
							   */
{
  int width, height, srcX, srcY, destX, destY;

  /* compute pixel coords */
  layCacheCoords(layCacheStack, bboxDB, relAreaDB, 
		 &width, &height, &srcX, &srcY, &destX, &destY);

  GrAdjustStippleOrigin(layDisplayWindow->lay_genOverlay,
			srcX-destX,
			srcY-destY);
}

/*---------------------------------------------------------
 * layCacheCopy --
 *	
 *     Copy cached subcell geometry into current drawable.
 *---------------------------------------------------------
 */
void layCacheCopy(LayoutCache *lc,         /* cache entry to copy */
		  Rect *bboxDB,            /* def bbox 
					    * in DB coordinates.
					    */
		  Rect *relAreaDB)         /* area to copy
					    * relative to def bbox.
					    */
{
  int width, height, srcX, srcY, destX, destY;

  /* set write mask */
  GrSetWriteMask(layCacheStack ? GrMaskAll : GrMaskColor);

  /* DEBUG
  fprintf(stderr,"DEBUG layCacheCopy, def=%s style group=%d stack=0%o\n",
	  lc->lc_def->cd_name, lc->lc_styleGroup->sg_number, layCacheStack);
	  
  DumpRect("bboxDB =",bboxDB);
  DumpRect("relAreaDB =",relAreaDB);
  */

  /* compute coords for xfer */
  layCacheCoords(lc, bboxDB, relAreaDB, 
		 &width, &height, &srcX, &srcY, &destX, &destY);

/* DEBUG - clear/mark area being copied
  GrSetStipple(NULL);
  GrSetColor(010);
  GrFillRect(destX, destY, destX+width-1, destY+height-1);
*/

  /* clear pixels to be written (if necessary) */
  if(!lc->lc_styleGroup->sg_orthogonal || 
     (!layCacheStack && lc->lc_styleGroup->sg_number != 1))
  {
    if(layCacheStippleMethod)
    {
      /* create stipple for area to be modified */
      if(!lc->lc_stipple)
      {
	lc->lc_stipple = GrCreateStippleFromPixmapPlane(lc->lc_pixmap,GrMaskFlag);
      }

      /* clear pixels to be written */
      GrSetStipple(lc->lc_stipple); 

      /* TODO: move stipple origin set to graphics module */
      grFlushInternal();

      XSetTSOrigin(grXdpy, grXGC, 
		   grMax2BufX(destX-srcX),
		   grMax2BufY(destY + lc->lc_area.r_ytop - srcY));

      GrSetColor(000); 
      GrFillRect(destX, destY, destX+width-1, destY+height-1); 
 
      GrSetStipple(NULL);
      XSetTSOrigin(grXdpy, grXGC, 0, 0);
      GrSetStipple(NULL);
    }
    else
    {
      GrSetFunction(GRFUNC_AND);

      GrCopyPlane(lc->lc_pixmap, 
		  GrMaskFlag,  /* mask giving plane to copy */
		  0,                /* color for 1 bits */
		  GrMaskAll,       /* color for 0 bits */
		  srcX, srcY,
		  destX, destY,
		  width, height);
    }
  }

  /* or in new values */
  GrSetFunction(GRFUNC_OR); 
  GrCopyPixmap(lc->lc_pixmap,
	       srcX, srcY,
	       destX, destY,
	       width, height);

  /* restore pixel combination func to default of "copy" */
  GrSetFunction(GRFUNC_COPY);
}












