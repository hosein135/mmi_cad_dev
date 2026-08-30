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

/* layText.c --
 *
 * support for text display in layout widgets.
 *
 */

#include <stdio.h>
#include <ctype.h>
#include "magic.h"
#include "main.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "utils.h"
#include "signals.h"
#include "message.h"
#include "layout.h"
#include "layint.h"
#include "layDraw.h"
#include "graphics.h"
#include "styles.h"

TextStyle layTextStyleTable[LAY_TEXT_STYLE_TABLE_SIZE];

/* built in styles */
TextStyle *layTextStyleLabelSmall           = &layTextStyleTable[0];
TextStyle *layTextStyleLabelMedium          = &layTextStyleTable[1];
TextStyle *layTextStyleLabelLarge           = &layTextStyleTable[2];
TextStyle *layTextStyleLabelExtraLarge      = &layTextStyleTable[3];
TextStyle *layTextStyleFlyline              = &layTextStyleTable[4];
TextStyle *layTextStyleAnnotationSmall      = &layTextStyleTable[5];
TextStyle *layTextStyleAnnotationMedium     = &layTextStyleTable[6];
TextStyle *layTextStyleAnnotationLarge      = &layTextStyleTable[7];
TextStyle *layTextStyleAnnotationExtraLarge = &layTextStyleTable[8];

int layTextStyleMax                         = 8; 

/*
 * ----------------------------------------------------------------------------
 * layTextInit --
 *
 * Initialize text styles dataStructures (called at startup time)
 *
 * ----------------------------------------------------------------------------
 */
void
layTextInit(void)
{
    register i;

    for (i = 0; i < MAXTILESTYLES; i++) 
    {
      TTMaskZero(&LayStyleToTypesTbl[i]);
    }

    for(i=0; i<MAX_STIPPLES; i++) 
    {
      layStippleTable[i] = NULL; 
    }

    /* TEXT STYLES */
    for(i=0; i<LAY_TEXT_STYLE_TABLE_SIZE; i++) 
    {
      layTextStyleTable[i].ts_name = NULL;
      layTextStyleTable[i].ts_index = i;
      layTextStyleTable[i].ts_maxHeight = 1000;
      layTextStyleTable[i].ts_maxHeightDB = -1000;
      layTextStyleTable[i].ts_maxCoverage = .5;
      layTextStyleTable[i].ts_maxOverlap = 0.1;
      layTextStyleTable[i].ts_visible = 1;
    }

    layTextStyleLabelSmall->ts_name = "label_small";
    layTextStyleLabelSmall->ts_maxHeightDB = 125;

    layTextStyleLabelMedium->ts_name = "label_medium";
    layTextStyleLabelMedium->ts_maxHeightDB = 250;

    layTextStyleLabelLarge->ts_name = "label_large";
    layTextStyleLabelLarge->ts_maxHeightDB = 500;

    layTextStyleLabelExtraLarge->ts_name = "label_extra_large";
    layTextStyleLabelExtraLarge->ts_maxHeightDB = 1000;

    layTextStyleFlyline->ts_name = "flyline";
    layTextStyleFlyline->ts_maxHeight = 18;

    layTextStyleAnnotationSmall->ts_name = "annotation_small";
    layTextStyleAnnotationSmall->ts_maxHeight = 14;

    layTextStyleAnnotationMedium->ts_name = "annotation_medium";
    layTextStyleAnnotationMedium->ts_maxHeight = 18;

    layTextStyleAnnotationLarge->ts_name = "annotation_large";
    layTextStyleAnnotationLarge->ts_maxHeight = 22;

    layTextStyleAnnotationExtraLarge->ts_name = "annotation_extra_large";
    layTextStyleAnnotationExtraLarge->ts_maxHeight = 30;
}


BPlane *layTextBP = NULL;

typedef struct rectelement
{
   struct rectelement *re_bpLinks[BP_NUM_LINKS];
   Rect re_rect;           
} RectElement;

/*---------------------------------------------------------
 * 
 * layTextDrawOverlapStatsBegin --
 *
 * called to start collecting stats on text overlap.
 *
 * Subsequent calls to layTextDraw() are not actually drawn,
 * instead, stats are collected.
 *
 * See layTextDrawOverlapStatsEnd() 
 *
 *---------------------------------------------------------
 */
void layTextDrawOverlapStatsBegin(void)
{
  ASSERT(!layTextBP,"layTextDrawOverlapStatsBegin");
  layTextBP = BPNew();
  return;
}

/*---------------------------------------------------------
 * 
 * layTextDrawOverlapStatsEnd --
 *
 * Called to end layDrawText stat collection.
 *
 * Returns fraction of text that overlaps other text.
 *
 *---------------------------------------------------------
 */
double layTextDrawOverlapStatsEnd(void)
{
  BPEnum bpe;
  RectElement *re;
  int overlapCount = 0;
  int textCount = 0;

  ASSERT(layTextBP,"layTextDrawOverlapStatsEnd");

  fprintf(stderr,"DEBUG StatsEnd TOP.\n");

  /* get overlap stats from bplane */
  BPEnumInit(&bpe, layTextBP, NULL, BPE_ALL, "allText");
  while(re = BPEnumNext(&bpe))
  {
    BPEnum bpe2;
    RectElement *re2;
    textCount++;

    /***
    BPEnumInit(&bpe2, layTextBP, &re->re_rect, BPE_OVERLAP, "overlapText");
    while((re2 = BPEnumNext(&bpe2)) && re2 == re);
    if(re2) overlapCount++;
    BPEnumTerm(&bpe2);
    ***/
    fprintf(stderr,"DEBUG StatsEnd A overlapCount=%d textCount=%d\n",
	    overlapCount,textCount);
  }
  BPEnumTerm(&bpe);

  /* clear bplane */
  BPEnumInit(&bpe, layTextBP, NULL, BPE_ALL, "allText");
  while(re = BPEnumNext(&bpe)) BPDelete(layTextBP, re);
  BPFree(layTextBP);
  layTextBP=NULL;

  /* return result */
  textCount = MAX(textCount,1);
  return (overlapCount + 0.0)/textCount;
}


/*---------------------------------------------------------
 * layTextDraw --
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
layTextDraw(char *str,           /* The text to be drawn. */
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

    if(!layTextBP)
    {
      /* draw it */
      DisplayStyle *ds = &layDrawStyleTable[layDrawCurStyle];

      GrSetWriteMask(ds->ds_writeMask);
      GrSetColor(ds->ds_color);
      GrSetStipple(layStippleTable[ds->ds_stipple]);
      GrSetFontSize(size);

      GrDrawText(str, xpos, ypos, rot);
    }
    else
    {
      /* just gather stats */
      RectElement *re;

      MALLOC_TAG(RectElement *, 
		 re, 
		 sizeof(RectElement), 
		 "RectElement");

      re->re_rect.r_xbot = posRW.rf_xbot;
      re->re_rect.r_xtop = posRW.rf_xtop;
      re->re_rect.r_ybot = posRW.rf_ybot;
      re->re_rect.r_ytop = posRW.rf_ytop;

      BPAdd(layTextBP,re);
    }

    /* return actual position of text */
    if (actual) *actual = posRW;
}
  
/*
 * ----------------------------------------------------------------------------
 * layTextStyleLookup --
 *
 * Find text style by name.
 *
 * Returns:
 * text style if found, else NULL.
 *
 * ----------------------------------------------------------------------------
 */
TextStyle *
layTextStyleLookup(char *name)
{
  int i;

  for(i=0;i<=layTextStyleMax;i++)
  {
    if(name[0] != layTextStyleTable[i].ts_name[0]) continue;
    if(strcmp(name,layTextStyleTable[i].ts_name)!= 0) continue;
    return &layTextStyleTable[i];
  }

  return NULL;
}

/*
 * ----------------------------------------------------------------------------
 * layTextFontFromStyle --
 *
 * compute font index from text style.
 *
 * returns index of font to use (-1 = text off)
 *
 * ----------------------------------------------------------------------------
 */
int
layTextFontFromStyle(Layout *w, 
		     TextStyle *ts,
		     int *hp)      /* if nonnull, set to computed height */

{  int h1 = ts->ts_maxHeight;       /* pixel height limit */ 
  int h2 = INFINITY;              /* db height limit */
  int h;

  if(!ts->ts_visible)
  {
    if(hp) *hp = 0;
    return -1;
  }

  if(ts->ts_maxHeightDB>0) h2 = layDimToWindow(w,ts->ts_maxHeightDB); 
  h = MIN(h1,h2);
  if(hp) *hp = h;
  return GrFontHeightToIndex(h);
}
  
/*
 *--------------------------------------------------------------
 *
 * layTextStyleCmd --
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Tcl Result:

 *
 * Side Effects:      
 *      None.
 *
 *--------------------------------------------------------------
 */

#define lay_text_style_DESC "get/set text display style" 

#define lay_text_style_DOC "
 Usage:
	lay_text_style [name [pixel_height db_height coverage spacing visible]]

 If no name, returns names of all currently defined styles. 
 If name, returns current settings for given text style.
 If pixel_height arg etc., sets text style to those values. 

 name           - text style name.  If new name new style created. 

 pixel_height   - max height in pixels.

 db_height      - max height in database units (-1 for no limit)

 coverage       - max fraction of screen text may obscure (-1 for no limit)

 overlap        - limit text height to this fraction of min text spacing
                  (-1 for no limit)

 visible        - if zero, don't display text of this style.
"

static int
layTextStyleCmd(ClientData clientData, Tcl_Interp *interp, 
	     int argc, char **argv)
{

  char *cmdName;
  char *name;
  int pixelHeight;
  int dbHeight;
  bool visible;
  TextStyle *ts;
    
  CMD_BEGIN(interp);
    
  /* parse command name */
  cmdName = *argv;
  argc--; argv++;

  /* Parse command line switchs */
  while(argc>0 && **argv=='-')
  {
    int length = strlen(*argv);
    char c = (*argv)[1];

    /* NO SWITCHES YET
    if(c=='d' && strncmp(*argv,"-dim",length) == 0) 
    {
      dim = TRUE;
      argc--;
      argv++;
      continue;
    }
    */

    /* unrecognized option */
    goto usage;
  } 

  /* Positional args? */
  if(!argc) 
  {
    /* list current styles */ 
    int i;

    for(i=0;i<=layTextStyleMax;i++) 
    {
      Tcl_AppendElement(interp, layTextStyleTable[i].ts_name);
    }

    CMD_RETURN(interp);
  }

  /* name */ 
  name = *argv;
  argc--; argv++;

  /* lookup name */
  ts = layTextStyleLookup(name);

  if(!ts)
  {
    /* new text style */
    if(!argc) 
    {
      MsgErrorF("Could not find text style '%s'\n", 
		name);
      CMD_RETURN(interp);
    }

    if(layTextStyleMax >= LAY_TEXT_STYLE_TABLE_SIZE -1)
    {
      MsgErrorF("Too many text styles:  could not add text style '%s'\n", 
		name);
      CMD_RETURN(interp);
    }

    ts = &layTextStyleTable[++layTextStyleMax];
    ts->ts_name = StrDup(NULL,name);
  }
  else
  {
    char buf[BUFSIZ];    
    /* output current settings for style */

    sprintf(buf,"%d %s %g %g %d",
	    ts->ts_maxHeight,
	    UnitsI2S(ts->ts_maxHeightDB),
	    ts->ts_maxCoverage,
	    ts->ts_maxOverlap,
	    ts->ts_visible);

    Tcl_SetResult(interp, buf, TCL_VOLATILE);
  }

  if(!argc) CMD_RETURN(interp);

  /* pixel height */
  if(sscanf(*argv,"%d", &ts->ts_maxHeight) !=1) goto usage;
  argc--; argv++;

  /* database height */
  if (!UnitsValidSF(*argv)) 
  {
    MsgErrorF("bad dimension:  %s\n", *argv);
    goto usage;
  }
  ts->ts_maxHeightDB = UnitsS2I(*argv);
  argc--; argv++;

  /* coverage */
  if(sscanf(*argv,"%lf", &ts->ts_maxCoverage) !=1) goto usage;
  argc--; argv++;

  /* overlap */
  if(sscanf(*argv,"%lf", &ts->ts_maxOverlap) !=1) goto usage;
  argc--; argv++;

  /* visible? */ 
  if(!argc) goto usage;
  if(sscanf(*argv,"%d", &ts->ts_visible) !=1) goto usage;
  argc--; argv++;

  if(argc) goto usage;

  /* need to redisplay everything */
  LayChangedDisplay(NULL);
   
  CMD_RETURN(interp);

usage:
  MsgErrorF("Usage:  "
	    "%s [name [pixel_height db_height coverage overlap visible]]\n",
	    cmdName,
	    cmdName);

  CMD_RETURN(interp);
}

/*
 * ----------------------------------------------------------------------------
 *
 * layTextTclInit --
 *
 * Register Tcl command interface to this file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers commands with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
layTextTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, "lay_text_style", layTextStyleCmd, 
	       (ClientData) NULL,  (Tcl_CmdDeleteProc *) NULL,
	       lay_text_style_DESC,
	       lay_text_style_DOC);
}

