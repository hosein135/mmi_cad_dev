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

/*********************************
   layFrame.c -
 
   Routines in this file implement the transformation from the database
   to a layout window.  They fall into two categories:
 
       1.  Modify the db/pixel transform, e.g. modify the viewable area
           in the window.
 
       2.  Routines for transforming between db and pixel coordinates.
 

REQUIREMENTS
------------

0.  subpixel objects don't disappear (especially if they are dense!)

1.  objects dimension doesn't vary with position.
    (because:
      very useful when using pixmap caches for cells.
      helps make identical objects look identical.
      keeps things from growing and shrinking etc, while being dragged.
    )

2.  touching objects go to touching objects.


3.  cells identical except for transform (e.g. mirroring) look
    that way.

4.  iterated LayFrame stays put.

5.  can pan without changing scale. (so pixmap caches remain usable).


SOLUTION (ADOPTED HERE)
-----------------------

transform lower left corner of bbox of objects to pixel coordinates.
then transform deltas from bbox lower left corners to pixels.  

truncate when converting to pixel coordinates.
if dimension is 0, make 1.

For the sake of 4-above perform final mirroring in pixel coordinates.


A NOTE ON COORDINATE SYSTEMS. 
----------------------------

Both pixel and db grid point at lower left corner of window.

Since pxiel and db coordinates are generally incommensurate, generally
a fraction of a db unit is cut off at top and right edge of window.

Both pixel and db areas are closed at lower left and open at upper
right.

So that "address" of pixel corresponds to coordinates of lower left corner.

*********************************/

#include <stdio.h>
#include <math.h>
#include <tk.h>
#include "magic.h"
#include "message.h"
#include "geometry.h"
#include "layout.h"
#include "layint.h"
  


/*
 * ----------------------------------------------------------------------------
 * LayFrame --
 *
 *      Make the given database area visible in the layout widget.
 *	(Sets up the db/pixel transform accordingly)
 *
 *      PROPERTIES OF THIS ROUTINE:
 * 
 *      lowerleft corner of window corresponds to db point.
 *      (right and upper edges generally not on exact db grid).
 *
 *      iterated LayFrame call on lay_dbArea does not change the transform.
 *
 * ----------------------------------------------------------------------------
 */

/* truncate double to n bit mantissa */
static double layTruncate(double in, 
			  int n /*number of bits */)
{
  int exponent;
  int i;

  i = frexp(in,&exponent)*(1<<n);
  return ldexp(i, exponent-n); 
}       

void
LayFrame(Layout *w, 
	 Rect *frameDBarg) /* the area to be viewed, or NULL to restore
			    * last Req area after window size change.
			    */
{
  double wDBreq, hDBreq, wDB, hDB;
  Rect frameDB;
  static double maxWidthDB   =  0.90 * INFINITY;
  static double maxCoordDB   =  0.45 * INFINITY;
  static double minCoordDB   = -0.45 * INFINITY;

  /* window dimensions in pixels */
  double wWindow = w->lay_area.r_xtop - w->lay_area.r_xbot; 
  double hWindow = w->lay_area.r_ytop - w->lay_area.r_ybot;

  /* if no area, just return 
   * (happens during intermediate configure notifys during packing)
   */
  if(wWindow == 0 || hWindow == 0) return;

  if(frameDBarg) w->lay_dbAreaReq = *frameDBarg;
  frameDB = w->lay_dbAreaReq;

  /* display at least one square DB unit */
  if(frameDB.r_xtop == frameDB.r_xbot) frameDB.r_xtop++; 
  if(frameDB.r_ytop == frameDB.r_ybot) frameDB.r_ytop++; 

  /* dimensions of Req area to be displayed in DB coords */
  wDBreq = frameDB.r_xtop - frameDB.r_xbot;
  hDBreq = frameDB.r_ytop - frameDB.r_ybot;
  
  /* set scale
   * 
   * truncated to 8 bits so that DBcoord * scale = windowCoord has 0's at 
   * the end of the mantissa.  This is used during clipping etc.
   *
   */
  {
    /* min scale to avoid integer overflow */
    double minScale = MAX(wWindow,hWindow)/maxWidthDB; 

    /* scale to fit requested view */ 
    double scale = MIN(wWindow/wDBreq, hWindow/hDBreq);

    w->lay_pixelsPerDB = layTruncate(MAX(minScale, scale), 8);
  }

  /* actual DB dimensions */
  wDB = floor(wWindow / w->lay_pixelsPerDB);
  hDB = floor(hWindow / w->lay_pixelsPerDB);
  ASSERT(wDB>0 && hDB>0, "LayFrame");

  /* center Req area in window */
  {
    double x0, y0;

    x0 = floor(frameDB.r_xbot - (wDB-wDBreq)/2);
    x0 = MAX(x0,minCoordDB);
    x0 = MIN(x0,maxCoordDB-wDB);

    y0 = floor(frameDB.r_ybot - (hDB-hDBreq)/2);
    y0 = MAX(y0,minCoordDB);
    y0 = MIN(y0,maxCoordDB-hDB);

    w->lay_dbArea.r_xbot = x0;
    w->lay_dbArea.r_ybot = y0;
    w->lay_dbArea.r_xtop = x0 + wDB;
    w->lay_dbArea.r_ytop = y0 + hDB;
  }

  /* Cause scrollbar notification on next redisplay */
  w->lay_flags |= Lay_UPDATESCROLLBARS;

  /* Schedule redisplay of entire window */
  LayChangedWindow(w, NULL);

  /*
  DumpRect("DEBUG LayFrame() requested: ", frameDBarg); 
  DumpRect("DEBUG LayFrame() got: ", &w->lay_dbArea); 
  */
}


/*
 * ----------------------------------------------------------------------------
 * layDimWToDBF --
 *
 *	Transform dimension from window coordinates (pixels) to database
 *	coordinates.
 *	
 *
 * Returns: 
 *      Exact point as PointFloat.
 *
 * ----------------------------------------------------------------------------
 */
double
layDimWToDBF(Layout *w, int x)
{
  return  x / w->lay_pixelsPerDB;
}


/*
 * ----------------------------------------------------------------------------
 * layPointWToDBF --
 *
 *	Transform point from window coordinates to database
 *	coordinates.
 *	
 *
 * Returns: 
 *      Exact point as PointFloat.
 *
 * ----------------------------------------------------------------------------
 */

void
layPointWToDBF(Layout *w, 
	       int x, int y, /* point in pixel coordinates */
	       PointFloat *result) 
{
  result->pf_x = w->lay_dbArea.r_xbot + x / w->lay_pixelsPerDB;
  result->pf_y = w->lay_dbArea.r_ybot + y / w->lay_pixelsPerDB;
}


/*
 * ----------------------------------------------------------------------------
 * layRectWToDB --
 *
 *   Transform a rectangle from window coords to database coords.
 *
 *   NOTE:  Result is big enough so, search on it's area will yield all 
 *          database objects that might write into pixel.
 *
 * ----------------------------------------------------------------------------
 */

void
layRectWToDB
(
   Layout *w, 
                 /* Window in whose coordinates screen is
		  * is defined.
		  */
   Rect *rW, 
                 /* a rectangle in window coordinates */
   Rect *rDB)
                 /* db rect filled in here */

{
  PointFloat pf;

  layPointWToDBF(w, rW->r_xbot, rW->r_ybot, &pf);
  rDB->r_xbot = floor(pf.pf_x)-1;
  rDB->r_ybot = floor(pf.pf_y)-1;

  layPointWToDBF(w, rW->r_xtop+1, rW->r_ytop+1, &pf);
  rDB->r_xtop = floor(pf.pf_x)+2;
  rDB->r_ytop = floor(pf.pf_y)+2;
}



/*
 * ----------------------------------------------------------------------------
 * layRectWToDBInside --
 *
 *   Transform a rectangle from window coords to database coords.
 *
 *   result is largest DB rect contained inside rW
 *
 * ----------------------------------------------------------------------------
 */

void
layRectWToDBInside
(
   Layout *w, 
                 /* Window in whose coordinates screen is
		  * is defined.
		  */
   Rect *rW, 
                 /* a rectangle in window coordinates */
   Rect *rDB)
                 /* db rect filled in here */

{
  PointFloat pf;

  layPointWToDBF(w, rW->r_xbot, rW->r_ybot, &pf);
  rDB->r_xbot = ceil(pf.pf_x);
  rDB->r_ybot = ceil(pf.pf_y);

  layPointWToDBF(w, rW->r_xtop, rW->r_ytop, &pf);
  rDB->r_xtop = floor(pf.pf_x);
  rDB->r_ytop = floor(pf.pf_y);
}






