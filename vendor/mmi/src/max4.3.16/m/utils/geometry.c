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



/* geometry.c --
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
 * This file contains a bunch of utility routines for manipulating
 * boxes, points, and transforms.
 */

#ifndef lint
static char rcsid[]="$Header: geometry.c,v 6.0 90/08/28 19:00:39 mayo Exp $";
#endif  not lint

#include <stdio.h>
#include "magic.h"
#include "geometry.h"
#include "utils.h"
#include "message.h"

/*
 *-------------------------------------------------------------------
 *	Declarations of exported transforms:
 *-------------------------------------------------------------------
 */

global Transform GeoIdentityTransform	= {  1,  0,  0,  0,  1,  0 };
global Transform GeoUpsideDownTransform	= {  1,  0,  0,  0, -1,  0 };
global Transform GeoSidewaysTransform	= { -1,  0,  0,  0,  1,  0 };
global Transform Geo90Transform		= {  0,  1,  0, -1,  0,  0 };
global Transform Geo180Transform	= { -1,  0,  0,  0, -1,  0 };
global Transform Geo270Transform	= {  0, -1,  0,  1,  0,  0 };
global Transform GeoRef45Transform	= {  0,  1,  0,  1,  0,  0 };  /* fx_r90 */ 
global Transform GeoRef135Transform	= {  0, -1,  0, -1,  0,  0 };  /* fy_r90 */

/*
 *-------------------------------------------------------------------
 *	Declaration of the table of opposite directions:
 *-------------------------------------------------------------------
 */
global int GeoOppositePos[] =
{
	GEO_CENTER,	/* GEO_CENTER */
	GEO_SOUTH,	/* GEO_NORTH */
	GEO_SOUTHWEST,	/* GEO_NORTHEAST */
	GEO_WEST,	/* GEO_EAST */
	GEO_NORTHWEST,	/* GEO_SOUTHEAST */
	GEO_NORTH,	/* GEO_SOUTH */
	GEO_NORTHEAST,	/* GEO_SOUTHWEST */
	GEO_EAST,	/* GEO_WEST */
	GEO_SOUTHEAST,	/* GEO_NORTHWEST */
};

/*
 *-------------------------------------------------------------------
 *	Declarations of exported rectangles:
 *-------------------------------------------------------------------
 */

global Rect GeoNullRect = { 0, 0, 0, 0 };
global Rect GeoInvertedRect = { 0, 0, -1, -1 };


/*-------------------------------------------------------------------
 *	GeoTransPoint --
 *	Transforms a point from one coordinate system to another.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	P2 is set to contain the coordinates that result from transforming
 *	p1 by t.
 *-------------------------------------------------------------------
 */

void
GeoTransPoint(register Transform *t, register Point *p1, register Point *p2)
                      		/* A description of the mapping from the
				 * coordinate system of p1 to that of p2.
				 */
                        	/* Pointers to two points; p1 is the old
				 * point, and p2 will contain the transformed
				 * point.
				 */

{
    p2->p_x = p1->p_x*t->t_a + p1->p_y*t->t_b + t->t_c;
    p2->p_y = p1->p_x*t->t_d + p1->p_y*t->t_e + t->t_f;
}

/*-------------------------------------------------------------------
 *	GeoTransPointFOut --
 *	Transforms a point from one coordinate system to another.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	P2 is set to contain the coordinates that result from transforming
 *	p1 by t.
 *-------------------------------------------------------------------
 */

void
GeoTransPointFOut(register Transform *t, 
	      register Point *p1, 
	      register PointFloat *p2)
                      		/* A description of the mapping from the
				 * coordinate system of p1 to that of p2.
				 */
                        	/* Pointers to two points; p1 is the old
				 * point, and p2 will contain the transformed
				 * point.
				 */

{
    p2->pf_x = p1->p_x*t->t_a + p1->p_y*t->t_b + t->t_c;
    p2->pf_y = p1->p_x*t->t_d + p1->p_y*t->t_e + t->t_f;
}

/*-------------------------------------------------------------------
 *	GeoTransPointF --
 *	Transforms a point from one coordinate system to another.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	P2 is set to contain the coordinates that result from transforming
 *	p1 by t.
 *-------------------------------------------------------------------
 */

void
GeoTransPointF(register Transform *t, 
	      register PointFloat *p1, 
	      register PointFloat *p2)
                      		/* A description of the mapping from the
				 * coordinate system of p1 to that of p2.
				 */
                        	/* Pointers to two points; p1 is the old
				 * point, and p2 will contain the transformed
				 * point.
				 */

{
    p2->pf_x = p1->pf_x*t->t_a + p1->pf_y*t->t_b + t->t_c;
    p2->pf_y = p1->pf_x*t->t_d + p1->pf_y*t->t_e + t->t_f;
}


/*-------------------------------------------------------------------
 *	GeoTransRect --
 *	Transforms a rectangle from one coordinate system to another.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	R2 is set to contain the coordinates that result from transforming
 *	r1 by t.
 *-------------------------------------------------------------------
 */

void
GeoTransRect(register Transform *t, 
         		        /* A description of the mapping from the
				 * coordinate system of r1 to that of r2.
				 */
	     register Rect *r1, 
	                        /* original rect */
	     register Rect *r2)
                                /* transformed rect put here */
{
    int x1, y1, x2, y2;
    x1 = r1->r_xbot*t->t_a + r1->r_ybot*t->t_b + t->t_c;
    y1 = r1->r_xbot*t->t_d + r1->r_ybot*t->t_e + t->t_f;
    x2 = r1->r_xtop*t->t_a + r1->r_ytop*t->t_b + t->t_c;
    y2 = r1->r_xtop*t->t_d + r1->r_ytop*t->t_e + t->t_f;

    /* Because of rotations, xbot and xtop may have to be switched, and
     * the same for ybot and ytop.
     */

    if (x1 < x2)
    {
	r2->r_xbot = x1;
	r2->r_xtop = x2;
    }
    else
    {
	r2->r_xbot = x2;
	r2->r_xtop = x1;
    }
    if (y1 < y2)
    {
	r2->r_ybot = y1;
	r2->r_ytop = y2;
    }
    else
    {
	r2->r_ybot = y2;
	r2->r_ytop = y1;
    }
}

/*-------------------------------------------------------------------
 *	GeoTranslateTrans --
 *	Translate a transform by the indicated (x, y) amount.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	Trans2 is set to the result of transforming trans1 by
 *	a translation of (x, y).
 *-------------------------------------------------------------------
 */

void
GeoTranslateTrans(register Transform *trans1, int x, int y, register Transform *trans2)
                           	/* Transform to be translated */
         			/* Amount by which to translated */
                           	/* Result transform */
{
    trans2->t_a = trans1->t_a;
    trans2->t_b = trans1->t_b;
    trans2->t_d = trans1->t_d;
    trans2->t_e = trans1->t_e;

    trans2->t_c = trans1->t_c + x;
    trans2->t_f = trans1->t_f + y;
}

/*-------------------------------------------------------------------
 *	GeoTransTranslate --
 *	Transform a translation by the indicated (x, y) amount.
 *
 *	This is the dual of GeoTranslateTrans, in that if
 *	Tinv is the inverse of T,
 *
 *	GeoTransTranslate(T, x, y) * GeoTranslateTrans(Tinv, -x, -y)
 *	is the identity transform.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	Trans2 is set to the result of transforming a translation
 *	of (x, y) by trans1.
 *-------------------------------------------------------------------
 */

void
GeoTransTranslate(int x, int y, register Transform *trans1, register Transform *trans2)
         			/* Amount of translation */
                           	/* Transform to be applied to translation */
                           	/* Result transform */
{
    trans2->t_a = trans1->t_a;
    trans2->t_b = trans1->t_b;
    trans2->t_d = trans1->t_d;
    trans2->t_e = trans1->t_e;

    trans2->t_c = x*trans1->t_a + y*trans1->t_b + trans1->t_c;
    trans2->t_f = x*trans1->t_d + y*trans1->t_e + trans1->t_f;
}


/*-------------------------------------------------------------------
 *	GeoTransTrans --
 *	This routine transforms a transform.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	The transform referred to by net is set to produce a geometrical
 *	transformation equivalent in effect to the application of transform
 *	first, followed by the application of transform second.
 *-------------------------------------------------------------------
 */

void
GeoTransTrans(register Transform *first, register Transform *second, register Transform *net)
                          		/* Pointers to three transforms */
                           
                        

{
    net->t_a = first->t_a*second->t_a + first->t_d*second->t_b;
    net->t_b = first->t_b*second->t_a + first->t_e*second->t_b;
    net->t_c = first->t_c*second->t_a + first->t_f*second->t_b + second->t_c;
    net->t_d = first->t_a*second->t_d + first->t_d*second->t_e;
    net->t_e = first->t_b*second->t_d + first->t_e*second->t_e;
    net->t_f = first->t_c*second->t_d + first->t_f*second->t_e + second->t_f;
}


/*-------------------------------------------------------------------
 *
 *	GeoNameToTrans --
 *	Map a transform name (orientation) to corresponding transform. 
 *
 *      Returns NULL if name invalid
 *
 *-------------------------------------------------------------------
 */

Transform *
GeoNameToTrans(char *name, 
	       bool noisy)  /* if set, generate error msg on error */
{
    static struct orientation
    {
	char	*o_name;
	Transform *o_trans;
    }
    orientations[] =
    {
      "",       &GeoIdentityTransform,
      "r90",    &Geo90Transform,
      "r180",	&Geo180Transform,
      "r270",	&Geo270Transform,
      "fx",	&GeoSidewaysTransform,
      "fy",	&GeoUpsideDownTransform,
      "fx_r90", &GeoRef45Transform,
      "fy_r90", &GeoRef135Transform,
      0
    };
    int index;

    index = LookupStruct(name, (LookupTable *) orientations, sizeof orientations[0]);
    if (index >= 0) return orientations[index].o_trans;

    if (noisy) 
    {
      int i;

      switch (index)
      {
      case -1:
	MsgErrorF("\"%s\" is ambiguous.\n", name);
	break;

      case -2:
	MsgErrorF("\"%s\" is not a valid orientation.\n",  name);
	break;
      }

      MsgErrorF("Legal orientations are:  ");
      for (i=0; orientations[i].o_name; i++)
      {
	MsgErrorF(" %s", orientations[i].o_name);
      }
      MsgErrorF("\n");
    }

    /* return small int to indicate error */
    return (Transform *) index;
}



/*-------------------------------------------------------------------
 *
 *	GeoTransToName --
 *	Map a transform to its name (orientation)
 *
 *-------------------------------------------------------------------
 */

char* 
GeoTransToName(Transform *t) 
{
  if (t->t_a == 1)
  {
    if (t->t_e == 1) return "";
    return "fy";
  }

  if (t->t_a == -1) 
  {
    if (t->t_e == -1) return "r180";
    return "fx";
  }

  if (t->t_b == 1)
  {
    if (t->t_d == -1) return "r90";
    return "fx_r90";
  }

  if (t->t_d == 1) return "r270";
  return "fy_r90";
}


/*-------------------------------------------------------------------
 *	GeoNameToPos --
 *	Map the name of a position into an integer position parameter.
 *	Position names may be unique abbreviations for direction names.
 *
 *	Results:
 *	Returns a position parameter (0 - 8, corresponding to GEO_CENTER
 *	through GEO_NORTHWEST), -1 if the position name was ambiguous,
 *	and -2 if it was unrecognized.
 *
 *	Side Effects:	None.
 *-------------------------------------------------------------------
 */

int
GeoNameToPos(char *name, int manhattan, int verbose)
               
                   	/* If TRUE, only Manhattan directions (up, down,
			 * left, right, and their synonyms) are allowed.
			 */
                 	/* If TRUE, we print an error message and list
			 * valid directions.
			 */
{
    static struct pos
    {
	char	*pos_name;
	int	 pos_value;
	bool	 pos_manhattan;
    }
    positions[] =
    {
	"bottom",	GEO_SOUTH,		TRUE,
	"center",	GEO_CENTER,		FALSE,
	"down",		GEO_SOUTH,		TRUE,
	"e",		GEO_EAST,		TRUE,
	"east",		GEO_EAST,		TRUE,
	"left",		GEO_WEST,		TRUE,
	"n",		GEO_NORTH,		TRUE,
	"ne",		GEO_NORTHEAST,		FALSE,
	"north",	GEO_NORTH,		TRUE,
	"northeast",	GEO_NORTHEAST,		FALSE,
	"northwest",	GEO_NORTHWEST,		FALSE,
	"nw",		GEO_NORTHWEST,		FALSE,
	"right",	GEO_EAST,		TRUE,
	"s",		GEO_SOUTH,		TRUE,
	"se",		GEO_SOUTHEAST,		FALSE,
	"south",	GEO_SOUTH,		TRUE,
	"southeast",	GEO_SOUTHEAST,		FALSE,
	"southwest",	GEO_SOUTHWEST,		FALSE,
	"sw",		GEO_SOUTHWEST,		FALSE,
	"top",		GEO_NORTH,		TRUE,
	"up",		GEO_NORTH,		TRUE,
	"w",		GEO_WEST,		TRUE,
	"west",		GEO_WEST,		TRUE,
	0
    };
    struct pos *pp;
    char *fmt;
    int pos;

    pos = LookupStruct(name, (LookupTable *) positions, sizeof positions[0]);

    if ((pos >= 0) && (!manhattan || positions[pos].pos_manhattan))
	return positions[pos].pos_value;
    if (!verbose)
    {
	if (pos < 0) return pos;
	else return -2;
    }
    if (pos < 0)
    {
	switch (pos)
	{
	    case -1:
		MsgErrorF("\"%s\" is ambiguous.\n", name);
		break;
	    case -2:
		MsgErrorF("\"%s\" is not a valid direction or position.\n",
		    name);
		break;
	}
    }
    else
    {
	MsgErrorF("\"%s\" is not a Manhattan direction or position.\n", name);
	pos = -2;
    }
    MsgErrorF("Legal directions/positions are:\n\t");
    for (fmt = "%s", pp = positions; pp->pos_name; pp++)
    {
	if (manhattan && !pp->pos_manhattan)
	    continue;
	MsgErrorF(fmt, pp->pos_name);
	fmt = ",%s";
    }
    MsgErrorF("\n");
    return (pos);
}


/*
 * ----------------------------------------------------------------------------
 *
 * GeoPosToName --
 *
 * 	Given a geometric name, return its position name.
 *
 * Results:
 *	Pointer to a static string holding the position name.
 *	NOTE: you'd better not try to alter the returned string!
 *
 * Side effects:
 *	None.
 *
 * ----------------------------------------------------------------------------
 */
char *
GeoPosToName(int pos)
{
    switch(pos)
    {
        case GEO_CENTER:    return("CENTER");
        case GEO_NORTH:     return("NORTH");
        case GEO_NORTHEAST: return("NORTHEAST");
        case GEO_EAST:      return("EAST");
        case GEO_SOUTHEAST: return("SOUTHEAST");
        case GEO_SOUTH:     return("SOUTH");
        case GEO_SOUTHWEST: return("SOUTHWEST");
        case GEO_WEST:      return("WEST");
        case GEO_NORTHWEST: return("NORTHWEST");
	default:            return("*ILLEGAL*");
    }
}

/*-------------------------------------------------------------------
 *	GeoTransPos --
 *	This routine computes the transform of a relative position.
 *
 *	Results:
 *	The return value is a position equal to the position parameter
 *	transformed by t.
 *
 *	Side Effects:	None.
 *-------------------------------------------------------------------
 */

int
GeoTransPos(Transform *t, int pos)
                 		/* Transform to be applied. */
            			/* Position to which it is to be applied. */

{
    if ((pos <= 0) || (pos > 8)) return pos;

    /* Handle rotation first, using modulo arithmetic. */

    pos -= 1;
    if (t->t_a <= 0)
    {
	if (t->t_a < 0) pos += 4;
	else if (t->t_b < 0) pos += 6;
	else pos += 2;
    }
    while (pos >= 8) pos -= 8;
    pos += 1;

    /* Handle mirroring across the x-axis on a case-by-case basis. */

    if ((t->t_a != t->t_e) || ((t->t_a == 0) && (t->t_b == t->t_d)))
    {
	switch (pos)
	{
	    case GEO_NORTH:	pos = GEO_SOUTH; break;
	    case GEO_NORTHEAST:	pos = GEO_SOUTHEAST; break;
	    case GEO_EAST:	break;
	    case GEO_SOUTHEAST:	pos = GEO_NORTHEAST; break;
	    case GEO_SOUTH:	pos = GEO_NORTH; break;
	    case GEO_SOUTHWEST:	pos = GEO_NORTHWEST; break;
	    case GEO_WEST:	break;
	    case GEO_NORTHWEST: pos = GEO_SOUTHWEST; break;
	}
    }
    return pos;
}


/*-------------------------------------------------------------------
 *	GeoInvertTrans --
 *	This routine computes the inverse of a transform.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	The transform pointed to by inverse is overwritten with
 *	the inverse transform of t.  Note:  this method of inversion
 *	only works for rotations that are multiples of 90 degrees with
 *	unit scale factor.  Beware any changes to this!
 *-------------------------------------------------------------------
 */

void
GeoInvertTrans(register Transform *t, Transform *inverse)
                      			/* Pointer to a transform */
                   			/* Place to store the inverse */

{
    Transform t2, t3;
    t2.t_a = t2.t_e = 1;
    t2.t_b = t2.t_d = 0;
    t2.t_c = -t->t_c;
    t2.t_f = -t->t_f;
    t3.t_a = t->t_a;
    t3.t_b = t->t_d;
    t3.t_d = t->t_b;
    t3.t_e = t->t_e;
    t3.t_c = t3.t_f = 0;
    GeoTransTrans(&t2, &t3, inverse);
}


/*-------------------------------------------------------------------
 *	GeoIncludePoint --
 *	This routine includes a point into a rectangle by expanding
 *	the rectangle if necessary.  If the destination rectangle has
 *	its lower left corner above or to the right of its upper right
 *	corner, then use the source point to initialize the destination
 *	rectangle.
 *
 *	Results:
 *	None.
 *
 *	Side Effects:
 *	The destination is enlarged (if necessary) so that it completely
 *	contains the area of both the original src and dst.
 *-------------------------------------------------------------------
 */

void
GeoIncludePoint(register Point *src, register Rect *dst)
{
    if ((dst->r_xbot > dst->r_xtop) || (dst->r_ybot > dst->r_ytop))
    {
	dst->r_ll = *src;
	dst->r_ur = *src;
    }
    else
    {
	if (dst->r_xbot > src->p_x)
	    dst->r_xbot = src->p_x;
	if (dst->r_ybot > src->p_y)
	    dst->r_ybot = src->p_y;
	if (dst->r_xtop < src->p_x)
	    dst->r_xtop = src->p_x;
	if (dst->r_ytop < src->p_y)
	    dst->r_ytop = src->p_y;
    }
}


/*-------------------------------------------------------------------
 *	GeoClip --
 *	clips one rectangle against another.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	Rectangle r is clipped so that it includes only the
 *	intersection area between r and area.  The rectangle
 *	may end up being turned inside out (xbot>xtop) if
 *	there was absolutely no intersection between the two
 *	boxes.
 *-------------------------------------------------------------------
 */

void
GeoClip(register Rect *r, register Rect *area)
                 		/* Rectangle to be clipped. */
                    		/* Area against which to be clipped. */

{
    if (r->r_xbot < area->r_xbot) r->r_xbot = area->r_xbot;
    if (r->r_ybot < area->r_ybot) r->r_ybot = area->r_ybot;
    if (r->r_xtop > area->r_xtop) r->r_xtop = area->r_xtop;
    if (r->r_ytop > area->r_ytop) r->r_ytop = area->r_ytop;
}


/*-------------------------------------------------------------------
 *	GeoClipPoint --
 *	Clips one point against a rectangle, moving the point into
 *	the rectangle if needed.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	Point p is clipped so that it lies within or on the rectangle.
 *-------------------------------------------------------------------
 */

void
GeoClipPoint(register Point *p, register Rect *area)
                  		/* Point to be clipped. */
                    		/* Area against which to be clipped. */

{
    if (p->p_x < area->r_xbot) p->p_x = area->r_xbot;
    if (p->p_y < area->r_ybot) p->p_y = area->r_ybot;
    if (p->p_x > area->r_xtop) p->p_x = area->r_xtop;
    if (p->p_y > area->r_ytop) p->p_y = area->r_ytop;
}


/*
 * ----------------------------------------------------------------------------
 *	GeoDisjoint --
 *
 * 	Clip a rectanglular area against a clipping box, applying the
 *	supplied procedure to each rectangular region in "area" which
 *	falls outside "clipbox".  This works in tile space, where a
 *	rectangle is assumed to contain its lower x- and y-coordinates
 *	but not its upper coordinates.  It does NOT work in pixel space
 *	(think about this carefully before using it for pixels!).
 *
 *	The procedure should be of the form:
 *		bool func(box, cdarg)
 *			Rect	   * box;
 *			ClientData   cdarg;
 *
 * Results:
 *	Return TRUE unless the supplied function returns FALSE.
 *
 * Side effects:
 *	The side effects of the invoked procedure.
 * ----------------------------------------------------------------------------
 */
bool
GeoDisjoint(Rect *area, Rect *clipBox, int (*func) (/* ??? */), ClientData cdarg)
{
    Rect 	  ok, rArea;
    bool	  result;

#define NULLBOX(R) ((R.r_xbot>R.r_xtop)||(R.r_ybot>R.r_ytop))

    ASSERT((area!=(Rect *) NULL), "GeoDisjoint");
    if((clipBox==(Rect *) NULL)||(!GEO_OVERLAP(area, clipBox)))
    {
    /* Since there is no overlap, all of "area" may be processed. */

	result= (*func)(area, cdarg);
	return(result);
    }

    /* Do the disjoint operation in four steps, one for each side
     * of clipBox.  In each step, divide the area being clipped
     * into one piece that is DEFINITELY outside clipBox, and one
     * piece left to check some more.
     */
    
    /* Top edge of clipBox: */

    rArea = *area;
    result = TRUE;
    if (clipBox->r_ytop < rArea.r_ytop)
    {
	ok = rArea;
	rArea.r_ytop = ok.r_ybot = clipBox->r_ytop;
	if (!(*func)(&ok, cdarg)) result = FALSE;
    }

    /* Bottom edge of clipBox: */

    if (clipBox->r_ybot > rArea.r_ybot)
    {
	ok = rArea;
	rArea.r_ybot = ok.r_ytop = clipBox->r_ybot;
	if (!(*func)(&ok, cdarg)) result = FALSE;
    }

    /* Right edge of clipBox: */

    if (clipBox->r_xtop < rArea.r_xtop)
    {
	ok = rArea;
	rArea.r_xtop = ok.r_xbot = clipBox->r_xtop;
	if (!(*func)(&ok, cdarg)) result = FALSE;
    }

    /* Left edge of clipBox: */

    if (clipBox->r_xbot > rArea.r_xbot)
    {
	ok = rArea;
	rArea.r_xbot = ok.r_xtop = clipBox->r_xbot;
	if (!(*func)(&ok, cdarg)) result = FALSE;
    }

    /* Just throw away what's left of the area being clipped, since
     * it overlaps the clipBox.
     */

    return result;
} /*GeoDisjoint*/


	/* ARGSUSED */
bool
GeoDummyFunc(Rect *box, ClientData cdarg)
{
    return TRUE;
}

/*-------------------------------------------------------------------
 *	GeoCanonicalRect --
 *	Turns a rectangle into a canonical form in which the
 *	lower left is really below and to the left of the upper right.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	Rectangle rnew is set to the canonical form of rectangle r.
 *-------------------------------------------------------------------
 */
void
GeoCanonicalRect(register Rect *r, register Rect *rnew)
{
    if (r->r_xbot > r->r_xtop)
    {
	rnew->r_xbot = r->r_xtop;
	rnew->r_xtop = r->r_xbot;
    }
    else
    {
	rnew->r_xbot = r->r_xbot;
	rnew->r_xtop = r->r_xtop;
    }

    if (r->r_ybot > r->r_ytop)
    {
	rnew->r_ybot = r->r_ytop;
	rnew->r_ytop = r->r_ybot;
    }
    else
    {
	rnew->r_ybot = r->r_ybot;
	rnew->r_ytop = r->r_ytop;
    }
}

/*-------------------------------------------------------------------
 *	GeoCanonicalRectF --
 *	Turns a rectangle into a canonical form in which the
 *	lower left is really below and to the left of the upper right.
 *
 *	Results:	None.
 *
 *	Side Effects:
 *	Rectangle rnew is set to the canonical form of rectangle r.
 *-------------------------------------------------------------------
 */
void
GeoCanonicalRectF(register RectFloat *r, register RectFloat *rnew)
{
    if (r->rf_xbot > r->rf_xtop)
    {
	rnew->rf_xbot = r->rf_xtop;
	rnew->rf_xtop = r->rf_xbot;
    }
    else
    {
	rnew->rf_xbot = r->rf_xbot;
	rnew->rf_xtop = r->rf_xtop;
    }

    if (r->rf_ybot > r->rf_ytop)
    {
	rnew->rf_ybot = r->rf_ytop;
	rnew->rf_ytop = r->rf_ybot;
    }
    else
    {
	rnew->rf_ybot = r->rf_ybot;
	rnew->rf_ytop = r->rf_ytop;
    }
}

/*-------------------------------------------------------------------
 *	GeoScale --
 *
 *	Returns the scale factor associated with a transform.
 *
 *	Results:
 *	Scale factor.
 *
 *	Side Effects:
 *	None.
 *-------------------------------------------------------------------
 */

int GeoScale(register Transform *t)
{
    int scale;

    scale = t->t_a;
    if (scale == 0)
	scale = t->t_b;

    if (scale < 0)
	scale = (-scale);

    return (scale);
}

/*-------------------------------------------------------------------
 *	GeoRectPointSide --
 *
 *	Returns the side of the rect on which a point lies.
 *
 *	Results:
 *	    A direction, or GEO_CENTER if the point is off the boundary.
 *
 *	Side Effects:
 *	    None.
 *-------------------------------------------------------------------
 */

int GeoRectPointSide(register Rect *r, register Point *p)
{
    if(r->r_xbot == p->p_x) return GEO_WEST;
    else
    if(r->r_xtop == p->p_x) return GEO_EAST;
    else
    if(r->r_ybot == p->p_y) return GEO_SOUTH;
    else
    if(r->r_ytop == p->p_y) return GEO_NORTH;
    else
	return(GEO_CENTER);
}

/*-------------------------------------------------------------------
 *	GeoRectRectSide --
 *
 *	Returns the side of the first rect on which the second one
 *	lies.
 *
 *	Results:
 *	    A direction, or GEO_CENTER if the rects don't share some
 *	    coordinate.  Note, this won't detect the case where the
 *	    rectangles don't touch but do share some coordinate.
 *
 *	Side Effects:
 *	    None.
 *-------------------------------------------------------------------
 */

int GeoRectRectSide(register Rect *r0, register Rect *r1)
{
    if(r0->r_xbot == r1->r_xtop) return GEO_WEST;
    else
    if(r0->r_xtop == r1->r_xbot) return GEO_EAST;
    else
    if(r0->r_ybot == r1->r_ytop) return GEO_SOUTH;
    else
    if(r0->r_ytop == r1->r_ybot) return GEO_NORTH;
    else
	return(GEO_CENTER);
}

/* ----------------------------------------------------------------------------
 *
 * GeoDecomposeTransform --
 *
 *	Break a transform up into an optional mirror followed by an optional
 *	rotation.  Translation is ignored.  Maybe someone will add this at
 *	a later date.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Modifies 'angle' and 'upsidedown' parameters.
 *
 * ----------------------------------------------------------------------------
 */

void
GeoDecomposeTransform(Transform *t, int *upsidedown, int *angle)
                 
                     		/* Set to TRUE iff we should flip upsidedown 
				 * before rotating.
				 */
               			/* Amount to rotate.
				 * Will be 0, 90, 180, or 270.
				 */
{
    Transform notrans;		/* Transform without any translation -- includes
				 * both rotation and mirroring.
				 */
    Transform rotonly;		/* Version of above with only rotation. */

    notrans = *t;
    notrans.t_c = 0;
    notrans.t_f = 0;

    /* Compute rotations and flips. */
    *upsidedown = ((notrans.t_a == 0) ^
	(notrans.t_b == notrans.t_d) ^ (notrans.t_a == notrans.t_e));
    if (*upsidedown) 
	GeoTransTrans(&notrans, &GeoUpsideDownTransform, &rotonly);
    else
	rotonly = notrans;
    /* Verify no flipping. */
    ASSERT(rotonly.t_a == rotonly.t_e, "GeoDecomposeTransform");	  

    *angle = 0;
    if (rotonly.t_b != 0) 
    {
	*angle += 90;
	if (*upsidedown) *angle += 180;
    }
    if ((rotonly.t_a < 0) || (rotonly.t_b < 0)) *angle += 180;
    if (*angle > 270) *angle -= 360;
}



