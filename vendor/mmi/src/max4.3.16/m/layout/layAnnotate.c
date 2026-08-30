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



/* layAnnotate.c -
 *
 * Implements layout widget "annotations": 
 * temporary text and graphics displayed as highlights.
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
#include "graphics.h"


/*
 * ----------------------------------------------------------------------------
 * layAnnotateTextAdd -
 *
 *   Add text annotation to layout widget. 
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateTextAdd(Layout *w,
		   PointFloat location,
		   int pos, /* alignment */
		   int index, /* text style index */
		   char *text,
		   char *tag)
{
  TextAnnotation *new;

  /* build */
  MALLOC_TAG(TextAnnotation *, new, sizeof(*new),"TextAnnotation");
  new->ta_location = location;
  new->ta_pos = pos;
  new->ta_text = StrDup(NULL,text);
  new->ta_tag = StrDup(NULL,tag);

  /* compute bbox (oversizing to avoid any nasty boundary conditions) */
  new->ta_bbox.r_xbot = ROUND(location.pf_x) - 1;
  new->ta_bbox.r_ybot = ROUND(location.pf_y) - 1;
  new->ta_bbox.r_xtop = ROUND(location.pf_x) + 1;
  new->ta_bbox.r_ytop = ROUND(location.pf_y) + 1;

  /* link */
  new->ta_next = w->lay_textAnnotations[index];
  w->lay_textAnnotations[index] = new;

  /* schedule highlight redisplay */
  layChangedWindowHL(w, NULL, FALSE /* no need to erase first */);
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateTextFree -
 *
 *   free storage associated with text annotation
 *
 * ----------------------------------------------------------------------------
 */

static void 
layAnnotateTextFree(TextAnnotation *ta)
{
  FREE(ta->ta_text);
  if(ta->ta_tag) FREE(ta->ta_tag);
  FREE_TAG(ta,"TextAnnotation");

}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateTextClear -
 *
 *   clear all text annotations for layout widget. 
 *   
 *   if tag not NULL, only clear annotations with matching tag
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateTextClear(Layout *w, char *tag)
{
  int i;

  for(i=0;i<=layTextStyleMax;i++)
  {
    TextAnnotation *ta;
    TextAnnotation **nextpp = &w->lay_textAnnotations[i];
    
    while(ta = *nextpp)
    {
      if(!tag || (ta->ta_tag && strcmp(tag,ta->ta_tag)==0)) 
      {
	*nextpp = ta->ta_next;
	layAnnotateTextFree(ta);
      }
      else
      {
	nextpp = &ta->ta_next;
      }
    }
  }
    
  layChangedWindowHL(w, NULL, TRUE /* erase first */);
}



/*
 * ----------------------------------------------------------------------------
 * layAnnotateLineAdd -
 *
 *   Add line annotation to layout widget. 
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateLineAdd(Layout *w,
		   PointFloat p1,
		   PointFloat p2,
		   char *tag)
{
  LineAnnotation *new;

  /* build */
  MALLOC_TAG(LineAnnotation *, new, sizeof(*new),"LineAnnotation");
  new->la_p1 = p1;
  new->la_p2 = p2;
  new->la_tag = StrDup(NULL,tag);

  /* compute bbox (oversizing to avoid any nasty boundary conditions) */
  new->la_bbox.r_xbot = ROUND(MIN(p1.pf_x,p2.pf_x)) - 1;
  new->la_bbox.r_ybot = ROUND(MIN(p1.pf_y,p2.pf_y)) - 1;
  new->la_bbox.r_xtop = ROUND(MAX(p1.pf_x,p2.pf_x)) + 1;
  new->la_bbox.r_ytop = ROUND(MAX(p1.pf_y,p2.pf_y)) + 1;

  /* link */
  new->la_next = w->lay_lineAnnotations;
  w->lay_lineAnnotations = new;

  /* schedule highlight redisplay */
  layChangedWindowHL(w, NULL, FALSE /* no need to erase first */);
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateLineFree -
 *
 *   free storage associated with line annotation
 *
 * ----------------------------------------------------------------------------
 */

static void 
layAnnotateLineFree(LineAnnotation *la)
{
  if(la->la_tag) FREE(la->la_tag);
  FREE_TAG(la,"LineAnnotation");
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateLineDelete -
 *
 *   delete n+1th line annotation
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateLineDelete(Layout *w, int n, bool notify)
{
  LineAnnotation **nextpp;

  nextpp = &w->lay_lineAnnotations;

  for(; n>0 && *nextpp; n--) nextpp = &(*nextpp)->la_next;

  if(*nextpp)
  {
    LineAnnotation *la = *nextpp;
    
    *nextpp = la->la_next;
    layAnnotateLineFree(la);
  }

  if(notify) layChangedWindowHL(w, NULL, TRUE /* erase first */);
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateLineClear -
 *
 *   clear all line annotations for layout widget. 
 *   
 *   if tag not NULL, only clear annotations with matching tag
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateLineClear(Layout *w, char *tag)
{
  LineAnnotation *la;
  LineAnnotation **nextpp = &w->lay_lineAnnotations;

  while(la = *nextpp)
  {
    if(!tag || (la->la_tag && strcmp(tag,la->la_tag)==0)) 
    {
      *nextpp = la->la_next;
      layAnnotateLineFree(la);
    }
    else
    {
      nextpp = &la->la_next;
    }
  }
    
  layChangedWindowHL(w, NULL, TRUE /* erase first */);
}



/*
 * ----------------------------------------------------------------------------
 * layAnnotateDotAdd -
 *
 *   Add dot annotation to layout widget. 
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateDotAdd(Layout *w,
		  int diameter,
		  PointFloat center,
		  char *tag)
{
  DotAnnotation *new;

  ASSERT(1 <= diameter, "layAnnotateDotAdd");

  /* build */
  MALLOC_TAG(DotAnnotation *, new, sizeof(*new),"DotAnnotation");
  new->da_diameter = diameter;
  new->da_center = center;
  new->da_tag = StrDup(NULL,tag);

  /* compute bbox (oversizing to avoid any nasty boundary conditions) */
  {
    int grow = diameter/2+2;

    new->da_bbox.r_xbot = ROUND(center.pf_x) - grow;
    new->da_bbox.r_ybot = ROUND(center.pf_y) - grow;
    new->da_bbox.r_xtop = ROUND(center.pf_x) + grow;
    new->da_bbox.r_ytop = ROUND(center.pf_y) + grow;
  }

  /* link */
  new->da_next = w->lay_dotAnnotations;
  w->lay_dotAnnotations = new;

  /* schedule highlight redisplay */
  layChangedWindowHL(w, NULL, FALSE /* no need to erase first */);
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateDotFree -
 *
 *   free storage associated with dot annotation
 *
 * ----------------------------------------------------------------------------
 */

static void 
layAnnotateDotFree(DotAnnotation *da)
{
  if(da->da_tag) FREE(da->da_tag);
  FREE_TAG(da,"DotAnnotation");
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateDotDelete -
 *
 *   delete n-1th dot annotation
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateDotDelete(Layout *w, int n, bool notify)
{
  DotAnnotation **nextpp;

  nextpp = &w->lay_dotAnnotations;

  for(; n>0 && *nextpp; n--) nextpp = &(*nextpp)->da_next;

  if(*nextpp)
  {
    DotAnnotation *da = *nextpp;
    
    *nextpp = da->da_next;
    layAnnotateDotFree(da);
  }

  if(notify) layChangedWindowHL(w, NULL, TRUE /* erase first */);
}


/*
 * ----------------------------------------------------------------------------
 * layAnnotateDotClear -
 *
 *   clear all dot annotations for layout widget. 
 *   
 *   if tag not NULL, only clear annotations with matching tag
 *
 * ----------------------------------------------------------------------------
 */

void
layAnnotateDotClear(Layout *w, char *tag)
{
  DotAnnotation *da;
  DotAnnotation **nextpp = &w->lay_dotAnnotations;

  while(da = *nextpp)
  {
    if(!tag || (da->da_tag && strcmp(tag,da->da_tag)==0)) 
    {
      *nextpp = da->da_next;
      layAnnotateDotFree(da);
    }
    else
    {
      nextpp = &da->da_next;
    }
  }
    
  layChangedWindowHL(w, NULL, TRUE /* erase first */);
}


