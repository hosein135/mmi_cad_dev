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



/* layDraw.c -
 *
 * Low level routines called by layDisplay cdoe.
 *
 *  These routines: 
 *       interface to Graphics module.
 *       implement display styles.
 *       clipping.
 *
 * (Many routines are inlined for efficiency, see layDraw.h)
 *
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
static char rcsid[]="$Header$";
#endif  not lint

#include <stdio.h>
#include <float.h>
#include <tk.h>
#include <X11/Xlib.h>
#include <X11/cursorfont.h>
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
#include "malloc.h"
#include "main.h"
#include "select.h"
#include "selInt.h"
#include "graphics.h"
#include "layout.h"
#include "layint.h"
#include "layDraw.h"

/* tcl linked var, to enable/disable rotated text */
bool layRotatedText = FALSE;

/* current style */
int layDrawCurStyle;
int layDrawCurFill;
int layDrawCurOutline;
bool layDrawFillInitDone;
bool layDrawLineInitDone;

/* clip rectangle - used by layFillRect() and layDrawLine() */
/* (in pixel coordinates) */
RectFloat layDrawCurClip;              
RectFloat layDrawCurClipLines;              

/*
 * ----------------------------------------------------------------------------
 *
 * layDrawSetClip--
 *
 *  Set a clipping rectangle for layFillRect() and layDrawLine()
 *
 * ----------------------------------------------------------------------------
 */

/* reduce by minimum resolvable amount */
static double layMinusEpsilon(double in) 
{
  double result;
  int exponent;

  (void) frexp(in,&exponent);
  result = in - ldexp(DBL_EPSILON, exponent-1); 

  ASSERT(result<in,"layMinusEpsilon");

  return result;
}

void 
layDrawSetClip(Rect *clip,    /* clip area in pixel coordinates 
			       * NULL = don't clip.
			       */
	       Rect *window)  /* total window (or pixmap) area in
			       * pixels.
			       */
{

  /* software clip to window (to avoid overflow) */
  geoRect2RectF(window, &layDrawCurClip);

  /* include points that get rounded into clip area. */
  layDrawCurClip.rf_xtop = layMinusEpsilon(layDrawCurClip.rf_xtop + 1.0);
  layDrawCurClip.rf_ytop = layMinusEpsilon(layDrawCurClip.rf_ytop + 1.0);

  /* hardware clip to clip area */
  if(!clip || GEO_SAMERECT(*clip,*window))
  {
    /* full window redisplay, no need for hardware clipping */
    GrSetClipRect((int *)NULL);
  }
  else
  {
    GrSetClipRect((int *)clip);
  }
}


/*---------------------------------------------------------
 * layDrawText --
 *
 *	This routine puts a chunk of text on the screen in the given
 *	color, size, and position.  We do our best to fit the result
 *      inside clip.
 *
 *	The text is drawn on the screen at pos relative to p, using
 *	the current style (text can also be erased by using a suitable style).
 *
 *	The rectangle 'actual' is filled in with the actual location of
 *	the text on the screen (if actual is a non-null pointer).  
 *
 *	The text will be shrunk to a smaller font, if that will help it to
 *	fit into the clipping rectangle.
 *---------------------------------------------------------
 */

/* spacing between text and its positioning point */
#define LAY_TEXT_OFFSET 5

void
layDrawText(char *str,           /* The text to be drawn. */
	    PointFloat *p,       /* The point to align with */
	    int pos, 
        			/* The alignment desired (GEO_NORTH, 
				 * GEO_NORTHEAST, etc.)
				 */

	    int size, 
         			/* The desired size of the text 
				 * (such as GR_TEXT_MEDIUM).  
				 */
	    int adjust, 

            			/* TRUE means adjust the text (either by
				 * sliding it around or using a smaller font)
				 * if that is necessary to make it fit into
				 * the clipping rectangle.  FALSE means
				 * display the text exactly as instructed,
				 * clipping it if it doesn't fit.
				 */
	    RectFloat *clip, 
           			/* A clipping rectangle for the text
				 * (we try to fit in here, but don't actually clip)   
				 * NULL, to not clip.
				 */
	    RectFloat *actual)
             			/* To be filled in with the location of the
				 * text.
				 */
{
    Rect posR;
    RectFloat posRW;
    PointFloat drawPoint;
    double xpos, ypos;
    int rot = 0;

    if (actual)
    {
	actual->rf_xbot = actual->rf_ybot = 0;
	actual->rf_xtop = actual->rf_ytop = 0;
    }

    /* rotated text? */
    if (layRotatedText)
    {
      if(pos == GEO_NORTH || pos == GEO_SOUTH) rot = 270; 
    }
    
    /* The following loop sees if the text will fit in the clipping
     * area.  If not, and shrinking is allowed, we try again and
     * again with smaller sizes.
     */
    while (TRUE)
    {
	/* what portion of the screen is taken up by the text? */
	GrTextBBox(str, 
		   size, 
		   rot,
		   &posR.r_xbot,
		   &posR.r_ybot,
		   &posR.r_xtop,
		   &posR.r_ytop);

	/* figure out where the text will go, including a border on 1 side */
        switch (pos)	/* horizontal centering */
	{
	    case GEO_NORTHWEST:
	    case GEO_WEST:
	    case GEO_SOUTHWEST:
	      xpos = p->pf_x - LAY_TEXT_OFFSET - posR.r_xtop;
	      break;
	    case GEO_NORTH:
	    case GEO_SOUTH:
	    case GEO_CENTER:
	      xpos = p->pf_x - posR.r_xtop/2.0;
	      break;
	    case GEO_NORTHEAST:
	    case GEO_EAST:
	    case GEO_SOUTHEAST:
	      xpos = p->pf_x + LAY_TEXT_OFFSET;
	      break;
	    default:
	      xpos = 0;  /* keep compiler happy */
	      ASSERT(FALSE,"layDrawText");			  
	  }

	switch (pos)	/* vertical centering */
	{
	    case GEO_NORTH:
	      if(rot)
	      {
		ypos = p->pf_y + LAY_TEXT_OFFSET - posR.r_ytop;
		break;
	      }
	    case GEO_NORTHEAST:
	    case GEO_NORTHWEST:
	      ypos = p->pf_y + LAY_TEXT_OFFSET;
	      break;
	    case GEO_CENTER:
	    case GEO_WEST:
	    case GEO_EAST:
	      ypos = p->pf_y - (posR.r_ytop / 2.0);
	      break;
	    case GEO_SOUTH:
	      if(rot)
	      {
		ypos = p->pf_y - LAY_TEXT_OFFSET;
		break;
	      }
	    case GEO_SOUTHEAST:
	    case GEO_SOUTHWEST:
	      ypos = p->pf_y - posR.r_ytop - LAY_TEXT_OFFSET;
	      break;
	    default:
	      ypos = 0;  /* keep compiler happy */
	      ASSERT(FALSE,"layDrawText");			  
	}

	/* area in screen coordinates */
	{
	  RectFloat tmp;

	  tmp.rf_xbot = posR.r_xbot + xpos;
	  tmp.rf_ybot = posR.r_ybot + ypos;
	  tmp.rf_xtop = posR.r_xtop + xpos;
	  tmp.rf_ytop = posR.r_ytop + ypos;

	  GeoCanonicalRectF(&tmp,&posRW);
	}
	
	/* will that area fit within the clipping rectangle? */
	if (clip &&
	    (posRW.rf_xtop <= clip->rf_xtop) && (posRW.rf_xbot >= clip->rf_xbot) &&
	    (posRW.rf_ytop <= clip->rf_ytop) && (posRW.rf_ybot >= clip->rf_ybot) )
	{
	    /* it fits! */
	    break;
	}

	/* it doesn't fit, will sliding it be enough? */
	if(!clip) break;
	if (adjust)
	{
	    if (((clip->rf_xtop-clip->rf_xbot) >= (posRW.rf_xtop - posRW.rf_xbot)) &&
		((clip->rf_ytop - clip->rf_ybot) >= (posRW.rf_ytop - posRW.rf_ybot)) )
	    {
		/* it will fit */
		break;
	    }

	}

	/* Won't fit even with sliding, so shrink if possible. */
	if (adjust && (size > 0) )
	{
	    /* maybe shrinking it will help */
	    size -= 1;
	}
	else break;

    } /* while */

    /* Slide the text, if that is allowable and needed.  We'll only
     * slide the text if there's available space on one side and
     * insufficient space on the other.
     */
    if (adjust)
    {
	double top, bottom, left, right;	/* Space needed on each side. */
	double slide;

	right = posRW.rf_xtop - clip->rf_xtop;
	left = clip->rf_xbot - posRW.rf_xbot;
	top = posRW.rf_ytop - clip->rf_ytop;
	bottom = clip->rf_ybot - posRW.rf_ybot;

	slide = 0;
	if (right > 0)
	{
	    if (left < 0) slide = MAX(-right, left);
	}
	else if (left > 0) slide = MIN(left, -right);
	posRW.rf_xbot += slide;
	posRW.rf_xtop += slide;
	xpos += slide;

	slide = 0;
	if (top > 0)
	{
	    if (bottom < 0) slide = MAX(-top, bottom);
	}
	else if (bottom > 0) slide = MIN(bottom, -top);
	posRW.rf_ybot += slide;
	posRW.rf_ytop += slide;
	ypos += slide;
    }

    /* draw it */
    {
      DisplayStyle *ds = &layDrawStyleTable[layDrawCurStyle];

      GrSetWriteMask(ds->ds_writeMask);
      GrSetColor(ds->ds_color);
      GrSetStipple(layStippleTable[ds->ds_stipple]);
      GrSetFontSize(size);

      GrDrawText(str, xpos, ypos, rot);
    }

    /* return actual position of text */
    if (actual) *actual = posRW;
}
  

  

    
  





