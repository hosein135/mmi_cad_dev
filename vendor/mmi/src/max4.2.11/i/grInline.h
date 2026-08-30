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



/* grInline.h -
 *
 *  This file includes graphics module procedures that are inlined for
 *  performance.  It is included at the end of graphics.h
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
 *
 */

#ifndef _GRINLINE
#define	_GRINLINE

#include <assert.h>
#include "graphics.h"
#include "graphicsInt.h"

/*---------------------------------------------------------
 * grMax2BufX
 *
 *	Convert pixel x-coordinate from logical to 
 *      current drawable.
 *
 *---------------------------------------------------------
 */
static __inline__ int
grMax2BufX(int x)
{
  return x;
}

/*---------------------------------------------------------
 * grMax2BufY
 *
 *	Convert pixel y-coordinate from logical to 
 *      to current drawable.
 *
 *---------------------------------------------------------
 */
static __inline__ int
grMax2BufY(int y)
{
  return grYAdjust - y;
}

/*---------------------------------------------------------
 * grFlushLines --
 *
 *	This routine does the X call to draw a batch of lines
 *      which have been queued up by calls to grDrawLine()
 *
 *---------------------------------------------------------
 */
static __inline__ void
grFlushLines(void)
{
  if(grNbLines == 0) return;

  XDrawSegments(grXdpy, grXWin, grXGC, grLines, grNbLines);
  grNbLines = 0;
}

/*---------------------------------------------------------
 * grFlushRects --
 *
 *	This routine does the X calls to fill a batch of rects
 *      which have been queued up by calls to grFillRect()
 *
 *---------------------------------------------------------
 */
static __inline__ void
grFlushRects(void)
{
  if(grNbRects == 0) return;

  XFillRectangles(grXdpy, grXWin, grXGC, grRects, grNbRects);
  grNbRects = 0;
}

/*---------------------------------------------------------
 * grFlushInternal --
 *
 *	Flush graphics operations queued up inside graphics module
 *      through to client side X routines.
 *
 *---------------------------------------------------------
 */
static __inline__ void
grFlushInternal(void)
{
  grFlushRects();
  grFlushLines();
}

/*---------------------------------------------------------
 * GrSetFunction -
 * 
 *  Set function used on pixel writes to combine new and old
 *  value.  
 *
 *  (GRFUNC_COPY ignores old value and just writes new)
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrSetFunction(int func)
{
  /* filter out redundant sets */
  if(func == grCurFunction) return; 
  grCurFunction = func;

  /* flush queued graphics operations before changing style */
  grFlushInternal();

  XSetFunction(grXdpy,grXGC, func);
}


/*---------------------------------------------------------
 * GrSetColor -
 *
 *	Set current color in Graphic Contexts.
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrSetColor(unsigned int color)
          			/* color */
{
  /* fprintf(stderr,"DEBUG GrSetColor logical = %#o\n",color); */
  /* filter out redundant sets */
  if(color == grCurColor) return;
  grCurColor = color;

  /* flush queued graphics operations before changing style */
  grFlushInternal();

  /* map from logical to real */
  if(GrColorMapped)
  {
    if(grCurWriteMask & 0200)
    {
      color = grPixelsAll[color];
    }
    else
    {
      color = grPixelsColor[color];
    }
  }
      
  /* fprintf(stderr,"DEBUG GrSetColor actual = %#o\n", color); */
  XSetForeground(grXdpy,grXGC,color);
}

/*---------------------------------------------------------
 * GrSetWriteMask --
 * 
 *	Set WriteMask (planes written) in Graphic Contexts.
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrSetWriteMask(unsigned int mask)
             			/* New write mask */
{
  /* fprintf(stderr,"DEBUG GrSetWriteMask logical = %#o\n", mask); */
  /* filter out redundant sets */
  if(mask == grCurWriteMask) return; 

  if( GrColorMapped && ((grCurWriteMask^mask)&0200)) 
  {
    /* if flag bit flipped in mask, need to recompute color */
    int color = grCurColor;

    grCurWriteMask = mask;
    grCurColor++;
    GrSetColor(color);
  }
  else
  {  
    grCurWriteMask = mask;
  }

  /* flush queued graphics operations before changing style */
  grFlushInternal();

  /* map from logical to real */
  if(GrColorMapped) mask = grPlanes[mask];

  /* fprintf(stderr,"DEBUG GrSetWriteMask actual = %#o\n", mask); */
  XSetPlaneMask(grXdpy,grXGC,mask);

  /*  fprintf(stderr,"DEBUG GrSetWriteMask mask = 0%o\n", mask); */
}

/*---------------------------------------------------------
 * GrSetStipple --
 *
 *	Set stipple pattern for use in (Fill operations)
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrSetStipple (void *stipple)
                			/* id of bitmap to be used */
{
  /* filter out redundant sets */
  if(stipple == grCurStipple) return;
  grCurStipple = stipple;

  /* flush queued graphics operations before changing context */
  grFlushInternal();
  
  if (!stipple) 
  {
    /* no stipple */
    XSetFillStyle(grXdpy, grXGC, FillSolid);
  } 
  else 
  {
    XSetFillStyle(grXdpy, grXGC, FillStippled);
    XSetStipple(grXdpy, grXGC, *((Pixmap *) stipple));
  }
}


/*---------------------------------------------------------
 * GrSetLinePattern --
 *
 *	Set dash pattern for lines.
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrSetLinePattern(void *pattern)
                                /* points to line pattern 
				 * created by grCreateLinePattern
				 */
{
  /* filter out redundant sets */
  if(pattern == grCurLinePattern) return;
  grCurLinePattern = pattern;

  /* flush queued graphics operations before changing context */
  grFlushInternal();

  XSetLineAttributes(grXdpy, 
		     grXGC, 
		     0, /* 1 pixel wide line with
			 * (hardware dependent drawing algor.) 
			 */
		     pattern ? LineOnOffDash : LineSolid, 
		     CapNotLast, 
		     JoinMiter);

  if(!pattern) return;

  XSetDashes(grXdpy, 
	     grXGC, 
     	     ((LinePattern *) pattern)->lp_dashOffset, 
	     ((LinePattern *) pattern)->lp_dashList, 
	     ((LinePattern *) pattern)->lp_dashNum);
}


/*---------------------------------------------------------
 * GrDrawLine--
 *
 *   Display a line.
 *
 *   (lines are batched)    
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrDrawLine(int x1, int y1, int x2, int y2)
{
    if (grNbLines == GR_BATCH_SIZE) grFlushLines();
    grLines[grNbLines].x1 = grMax2BufX(x1);
    grLines[grNbLines].y1 = grMax2BufY(y1);
    grLines[grNbLines].x2 = grMax2BufX(x2);
    grLines[grNbLines].y2 = grMax2BufY(y2);
    grNbLines++;
}


/*---------------------------------------------------------
 * GrFillRect --
 *
 *	Display a filled rectangle.
 *
 *  (Rectangles are batched.)
 *
 *---------------------------------------------------------
 */
static __inline__ void
GrFillRect(int x1, int y1, int x2, int y2)
{
    if (grNbRects == GR_BATCH_SIZE) grFlushRects();
    grRects[grNbRects].x = grMax2BufX(x1);
    grRects[grNbRects].y = grMax2BufY(y2);
    grRects[grNbRects].width = x2-x1+1;
    grRects[grNbRects].height = y2-y1+1;
    grNbRects++;
}

#endif _GRINLINE











