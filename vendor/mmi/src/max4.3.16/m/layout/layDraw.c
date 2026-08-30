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
#include "memory.h"
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
