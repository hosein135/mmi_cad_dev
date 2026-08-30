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



/* grRotText.c -
 *
 * Implements rotated text (in increments of 90 degrees).
 *
 * X does not directly support text rotation, so we
 * invert stipples ourselves to create rotated text. 
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <X11/keysym.h>
#include "graphics.h"
#include "graphicsInt.h"

static void
grRotTextDraw1(Display *display,  
	                          /* Display on which to draw. */
	       Drawable drawable, 	  
	                          /* Window or pixmap in which to draw. */
	       GC gc, 
	                          /* Graphics context for actually drawing
				   * of chars.
				   */

	       int x, 
	       int y,
	                          /* Coordinates at which to draw string. */

	       char *text, 
                   	          /* Characters to be displayed. */
	       int numChars,
	                          /* Number of characters to display from
				   * text. 
				   */
	       XFontStruct *font, 
	                          /* Font in which characters will be drawn;
				   * must be the same as font used in GC. 
				   */
	       int rot) 
	                          /* rotation (0,1,90,180,270: 1 == 270) */
{
  /* Allocating a GC is painfully slow on a Sun workstation.
   * So we allocate a single GC for bitmaps, and hold onto it forever.
   */
  static GC bitmapGC = 0;
  static int GCallocated = False;

  Pixmap rotBitmap;
  Pixmap bitmap;
  int rotwidth, rotheight;    /* width/height of rotated bitmap */
  XImage *src;
  XImage *dest;
  int dx,dy;
  unsigned int linewidth,height;
  XGCValues gcValues;
  unsigned long gcMask;
  XCharStruct overall;
  int dir;

  if (numChars == 0) return;

  /* get text dimensions */
  {
    int dir,fa,fd;  /* not used */
    XTextExtents(font, text, numChars, &dir, &fa, &fd, &overall);
  }
  height = overall.ascent + overall.descent;
  linewidth = overall.width;

  if (linewidth <= 0) linewidth = 1;
  if (height <= 0) height = 1; 

  /* compute ROTATED text dimensions */
  /* The (x,y) location is the rotated location of the baseline at
   * the left edge of the text.  We need the upper left corner of
   * the bounding box to know where to plop the rotbitmap.
   */
  switch (rot) {
  default:
  case 0:
    y -= overall.ascent;
    rotwidth = linewidth;
    rotheight = height;
    break;
  case 90:
    x -= overall.ascent;
    y -= linewidth;
    rotwidth = height;
    rotheight = linewidth;
    break;
  case 180:
    x -= linewidth;
    y -= overall.descent;
    rotwidth = linewidth;
    rotheight = height;
    break;
  case 1:
  case 270:
    x -= overall.descent;
    rotwidth = height;
    rotheight = linewidth;
    break;
  }

  rotBitmap = XCreatePixmap(display, drawable, rotwidth, rotheight, 1);

  if (! GCallocated) 
  {
    gcMask = (GCFont | GCForeground | GCBackground);
    XGetGCValues(display, gc, gcMask, &gcValues);
    gcValues.foreground = 1;
    gcValues.background = 0;
    bitmapGC = XCreateGC(display, rotBitmap, gcMask, &gcValues);
    GCallocated = True;
  }

  /* create destination pixmap */
  {
    /* Make sure we are using the current font.
     * We dont care about foreground/background colors for drawing
     * the font into the bitmap: the bitmap is in black and white.
     */
    XGetGCValues(display, gc, GCFont, &gcValues);
    XChangeGC(display,bitmapGC,GCFont,&gcValues);

    bitmap = XCreatePixmap(display, drawable, linewidth, height, 1);

    XDrawImageString(display, 
		     bitmap, 
		     bitmapGC, 
		     0,
		     overall.ascent, 
		     text, 
		     numChars);

    src = XGetImage(display, bitmap, 0, 0, linewidth, height, 1, XYPixmap);
    dest = XGetImage(display, rotBitmap, 0, 0, rotwidth, rotheight, 
		     1, XYPixmap);

    switch (rot) {
    case 0:
      break;  /* No rotation; Shouldnt have bothered to call this code */
    case 90:
      for (dx = 0; dx < height; dx++) {
	for (dy = 0; dy < linewidth; dy++) {
	  XPutPixel(dest, dx, dy,
		    XGetPixel(src, (linewidth-dy-1), dx));
	}
      }
      break;
    case 180:
      for (dx = 0; dx < linewidth; dx++) {
	for (dy = 0; dy < height; dy++) {
	  XPutPixel(dest, dx, dy,
			XGetPixel(src, (linewidth-dx-1), (height-dy-1)));
		}
	    }
	    break;
    case 1:
    case 270:
      for (dx = 0; dx < height; dx++) {
	int sy = height - dx - 1;
	for (dy = 0; dy < linewidth; dy++) {
	  XPutPixel(dest, dx, dy, XGetPixel(src, dy, sy));
	}
      }
      break;
    }

    XFreePixmap(display, bitmap);
    XDestroyImage(src);
  }

  XPutImage(display, rotBitmap, bitmapGC, dest, 
	    0, 0, 0, 0, rotwidth, rotheight);
  XDestroyImage(dest);
  XSetClipMask(display,gc,rotBitmap);
  XSetClipOrigin(display, gc, x, y);
  XFillRectangle(display, drawable, gc, x, y, rotwidth, rotheight);

  XSetClipMask(display,gc,None);
  XFreePixmap(display, rotBitmap);
}


/*---------------------------------------------------------
 * grRotTextDraw --
 *
 *      Draw a rotated text string.
 *
 *      Called by GrDrawText() to handle the rotated
 *      case.
 *
 *---------------------------------------------------------
 */
void
grRotTextDraw(char *text, 
	      int x, 
	      int y, 
	         /* position of leftmost point of
		  * the baseline for this string.
		  */
	      int rot) 
                 /* 0, 90, 180 or 270 */
		
{
  grRotTextDraw1(grXdpy, 
		 grXWin,
		 grXGC,
		 x,
		 y,
		 text,
		 strlen(text),
		 grXFonts[grCurFontSize],
		 rot);
		
}



