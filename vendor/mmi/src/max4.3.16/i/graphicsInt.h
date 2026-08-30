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



/* graphicsInt.h -
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
 * This file contains a bunch of macros that look like
 * normal procedure calls but really indirect through procedure
 * pointers in order to achieve graphics display independence.
 */

/* rcsid "$Header: graphics.h,v 6.0 90/08/28 18:41:46 mayo Exp $" */

#ifndef _GRAPHICSINT
#define	_GRAPHICSINT

#include <tk.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>

/***** Tunable Constants and Defaults *****/

/* number of rectangles (and lines) queued up before making X calls */
#define GR_BATCH_SIZE	10000

/* default text fonts */
#define	GR_FONT_SMALL  "-*-helvetica-medium-r-normal--10-*-75-75-p-*-iso8859-*"
#define	GR_FONT_MEDIUM "-*-helvetica-medium-r-normal--14-*-75-75-p-*-iso8859-*"
#define	GR_FONT_LARGE  "-*-helvetica-medium-r-normal--18-*-75-75-p-*-iso8859-*"
#define	GR_FONT_XLARGE "-*-helvetica-medium-r-normal--24-*-75-75-p-*-iso8859-*"

/* last ditch text font */
#define GR_DEFAULT_FONT "9x15"

/**** data structures ****/

/* X handles */
extern Tk_Window grMainTkWin;
extern Display *grXdpy;
extern int	grXscrn;
extern Colormap grXcmap;
extern GC       grXGC;       /* depth 8 */ 
extern GC       grXGCBitMap; /* depth 1 */

/* logical colormap to X colormap mapping */
extern unsigned long grBasePixel;  /* address of planes we own */
extern unsigned long grOtherColor;  /* planes we don't own */
extern unsigned long grOtherAll;  /* planes we don't own and not flag */
extern unsigned long grPlanes[]; /* logical cmap mask -> X */
extern unsigned long grPixelsColor[]; /* logical cmap entry -> X */
extern unsigned long grPixelsAll[]; /* logical cmap entry -> X */

/*** context ***/
extern Window grXWin;
extern int grYAdjust; /* height less 1 (used to transform to X coordinates) */
extern int grCurWriteMask;
extern int grCurColor;
extern int grCurFunction;  /* function for combining old and new values
			    * when writing pixels.
			    */
extern void *grCurStipple;
extern void *grCurLinePattern;

/*** line and rectangle queues ***/
extern XSegment grLines[];
extern int grNbLines;
extern XRectangle grRects[];
extern int grNbRects;

/* X dash info (for XSetDashes()) */
typedef struct linepattern
{
  int lp_dashOffset;  
  int lp_dashNum;
  char *lp_dashList;
} LinePattern;

/* fonts */
extern int grCurFontSize;
extern XFontStruct *grXFonts[];

/* our private drawable struct */
typedef struct grdrawable
{
  Drawable gd_drawable;  
  int gd_width;
  int gd_height;
} GrDrawable;

#endif _GRAPHICSINT


