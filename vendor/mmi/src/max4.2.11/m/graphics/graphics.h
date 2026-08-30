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



/* graphics.h -
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

/*
   Graphics primitives intended for implementing layout widget.
   X Version.

   Assumes Tk.

   No X references should be required outside of this module.
   Porting, say to NT, will hopefully be limited to coding an NT version
   of this module.
   
   This module kept simple to minimize amount of code involved in any
   port.

   Primitives split between two files:
     grInline.h - most frequently called primitives in-lined for speed.
     graphics.c - everything else.

   Resources such as pixmaps and stipple patterns created by this
   module are passed to and from the module via opaque pointers (void *).

   Pixel coordinates passed to this module assumes: (0,0) in lower left corner.
   Rects include edges.
   Lines include end points.

   X uses (0,0) in upper right, with Y increasing as you go down.
   pixel coordinate transforms are done inside this module as required.
        
   Rects and Lines are queued internally, so GrFlush() required at end of
   redisplay to flush graphics through to the display.

   This module supports both pseudo-color (color-mapped) and true-color 
   visuals.  The visual is set by Tk before this module is called.  If 
   pseudo-color is in use GrColorMapped (linked to tcl var GR_COLOR_MAPPED) 
   is set at initialization time.  Tk can be directed into true or pseudo
   color mode by starting Max with command-line option of 
   '-visual [true|pseudo].

   PSEUDO-COLOR MODE (GrColorMapped set)
   -------------------------------------
   This module embeds a 7 bit 'logical' colormap in the physical color
   map (requires at least 8 bit pysical colormap).

   TRUE-COLOR MODE (GrColorMapped reset)
   -------------------------------------
   In true color mode a pixel values can be any size (typically 16 or
   24 bits).  The pixel value is split into Red Green and Blue fields. 
   GrRGBToPixel() converts R,G,B values to the corresponding pixel value.

   FLAG BIT (GrFlagBit)
   --------------------
   This module also implements a flag bit that can be stored with each
   pixel value.  The flag bit should only be used when writing to off-
   screen memory.  In pseudo color mode GrFlagBit = 0200.  In true color
   mode the low order bit of the largest of the R,G,B fields is stolen
   and made the flag bit.

   The flag bit is used by the layout module to keep track of
   which bits in pixmap have been written so that empty space in one
   pixmap won't obliterate actual content in another where they overlap.
*/

#ifndef _GRAPHICS
#define	_GRAPHICS

#ifndef _TK
#include <tk.h>
#endif

#define bool int

/* text font sizes */
#define GR_TEXT_SMALL 0
#define GR_TEXT_MEDIUM 1
#define GR_TEXT_LARGE 2
#define GR_TEXT_XLARGE 3
#define GR_MAX_FONT_SIZE 3

/* valid args for GrSetFunction() */
#define GRFUNC_COPY	GXcopy
#define GRFUNC_OR	GXor
#define GRFUNC_AND	GXand

/* return values for GrTicService */
#define GR_PENDING_NONE 0           
#define GR_PENDING_COMMAND 1  
#define GR_PENDING_INTERRUPT 2

/* set at initialization time, if using colormapped graphics */


/* info on graphics mode (set at initialization time) */
extern bool GrColorMapped;       /* pseudo color mode? */
extern int GrDepth;              /* bits per pixel */
extern int GrMaskColor;          /* pixel bits used for color */
extern int GrMaskFlag;           /* special pixel bit 
				  * (off screen memory only)
				  */
extern int GrMaskAll;            /* color bits + flag bit */


/* ===== Exported procedures ===== */

/* initialization */
extern bool GrInit(Tcl_Interp *interp);
extern void GrTclInit(Tcl_Interp *interp);

/* periodically read from XServer to avoid socket time out */
extern int GrTicService(void);

/* Pass all pending graphics through to display */
extern void GrFlush(void); 

/* windows and pixmaps */
extern void *GrRegisterWindow(Tk_Window tkWin);
extern void GrUnregisterWindow(void *gd);
extern void *GrCreatePixmap(int width, int height);
extern void GrFreePixmap(void *gd);
extern int GrPixmapWidth(void *gd);
extern int GrPixmapHeight(void *gd);

/* stipples and line styles */
extern void *GrCreateStipple(char **rows); 
extern void *GrCreateStippleFromPixmapPlane(void *pixmap, int planeMask); 
extern void GrFreeStipple(void *pixmap); 
void *GrCreateLinePattern(char *pattern);

/* colormap / colors */
void GrColorMapWrite(int c,       /* entry */ 
		     int r,       /* color */
		     int g,
		     int b);
int GrRGBToPixel(int r, 
		 int g, 
		 int b);

/* text */
extern void GrTextBBox(char *text, 
		       int fontSize,  /* ordinal of font */
		       int rot,       /* rotation = 0,90,180 or 270 */ 
		       int *xbot, 
		       int *ybot,
		       int *xtop,
		       int *ytop);

/* setting context */
extern void GrSetDrawable(void *gd);
extern void GrSetClipRect(int *rect);
extern void GrSetFontSize(int size);
extern void GrAdjustStippleOrigin(void *gd, int x, int y);
extern void GrDefaultStippleOrigin(void);
/* INLINE extern void GrSetFunction(int function); */
/* INLINE extern void GrSetWriteMask(unsigned int mask); */
/* INLINE extern void GrSetColor(unsigned int color); */
/* INLINE extern void GrSetStipple(void *stipple); */
/* INLINE extern void GrSetLinePattern(void *pattern); */

/* drawing */
extern void GrDrawText(char *text, int x, int y, int rot);
/* INLINE extern GrDrawLine(int x1, int y1, int x2, int y2); */
/* INLINE extern GrFillRect(int x1, int y1, int x2, int y2); */
extern void GrFillPolygon(int size, double *coords);
extern void GrCopyPixmap(void *src, 
			 int srcX0, int srcY0, 
			 int destX0, int destY0, 
			 int width, int height);
extern void GrCopyPlane(void *src, 
			int srcPlaneMask,
			int fgColor,               /* color for ones */
			int bgColor,               /* color for zeros */ 
			int srcX0, int srcY0, 
			int destX0, int destY0, 
			int width, int height);

/* debugging */
extern void GrDumpGC(void);

/*** inlined procedures ***/
#include "grInline.h"

#endif _GRAPHICS




