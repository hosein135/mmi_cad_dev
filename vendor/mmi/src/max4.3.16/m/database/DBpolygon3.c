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
 * DBpolygon3.c --
 *
 * polygon polygon intersection test.
 *
 *
 */

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "memory.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "layout.h"

/*
*  The main data structure of the routine.  All the line segments in "poly2"
*  are represented in this form to reduce repeated computations.
*/

typedef struct lineSegment
{
    PointFloat *p1,*p2;
    float a,b,c;
} LineSegment;

/*
*  "lists" is an array are temporary "LineSegment"s used by this routine.
*  These are NOT "free"d after each call and they are only "realloc"ed if
*  more are needed.  "ns" is the total number allocated so far and "cs" is
*  the number of the currect line segments available.
*/

static LineSegment *lists = NULL;
static int ns = 0;
static int cs;

/*
 *
 *	If returns TRUE if one polygon, "poly1", intersected with another
 *	polygon, "poly2", is non-empty and FALSE otherwise.
 */


/*
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectPolygonQ1 --
 *
 * Does real work for inline func DBPolygonIntersectPolygonQ()
 *	
 * RETURNS:  TRUE if one polygon, "poly1", intersected with another
 *	     polygon, "poly2", is non-empty and FALSE otherwise.
 *
 *
 * NOTE: Caller (DBPolygonIntersectPolygonQ) handles case where polygon
 *       bboxes are disjoint.
 *
 *-----------------------------------------------------------------------------
 */

bool DBPolygonIntersectPolygonQ1(Polygon *poly1,
				 Polygon *poly2)
{
	int i,j;
	int n1,n2;
	float a1,b1,c1;
	float a2,b2,c2;
	PointFloat *p11,*p12,*p21,*p22;
	float v11,v12,v21,v22;
	int count;
	float x0,y0,x1,y1,x2,y2;

	/* Get number of points in the polygons */
	n1 = poly1->poly_size;
	n2 = poly2->poly_size;

	/* Allocate enough room for the line segments */
	if (ns < n2) 
	{
	  ns = n2;

	  if(lists) FREE_TAG(lists,"lists");
	  MALLOC_TAG(Vertex *, 
		     lists, 
		     ns*sizeof(*lists), 
		     "lists");
	}

	/*
	*  Set up the line equation information for each line segment in
	*  polygon 2.
	*/
	cs = 0;

	p21 = poly2->poly_points;

	for (i = 0; i < n2; i++) {
		if (i == n2-1) {
			p22 = poly2->poly_points;
		} else {
			p22 = p21+1;
		}

		lists[cs].p1 = p21;
		lists[cs].p2 = p22;

		lists[cs].a = p22->pf_y - p21->pf_y;
		lists[cs].b = p21->pf_x - p22->pf_x;
		lists[cs].c = p22->pf_x*p21->pf_y - p21->pf_x*p22->pf_y;

		cs++;

		p21 = p22;
	}

	p11 = poly1->poly_points;

	/*
	*  Check to see if any line segment in polygon 1 intersects any line
	*  segment in polygon 2.  If so, the polygons intersect so return
	*  TRUE.
	*/

	for (i = 0; i < n1; i++) {
	    if (i == n1-1) {
		p12 = poly1->poly_points;
	    } else {
		p12 = p11+1;
	    }

	    /*
	    *  Set up the line equation information for the current line
	    *  segment in polygon 1.
	    */

	    a1 = p12->pf_y - p11->pf_y;
	    b1 = p11->pf_x - p12->pf_x;
	    c1 = p12->pf_x*p11->pf_y - p11->pf_x*p12->pf_y;

	    for (j = 0; j < n2; j++) {
	    	p21 = lists[j].p1;
	    	p22 = lists[j].p2;

	    	v21 = a1*p21->pf_x + b1*p21->pf_y + c1;
	    	v22 = a1*p22->pf_x + b1*p22->pf_y + c1;

	    	if ((v21 <  0 && v22 >  0) ||
		    (v21 >  0 && v22 <  0) ||
		    (v21 == 0 && v22 != 0) ||
		    (v21 != 0 && v22 == 0)) {
	    	    a2 = lists[j].a;
	    	    b2 = lists[j].b;
	    	    c2 = lists[j].c;

	    	    v11 = a2*p11->pf_x + b2*p11->pf_y + c2;
	    	    v12 = a2*p12->pf_x + b2*p12->pf_y + c2;

	    	    if ((v11 <  0 && v12 >  0) ||
		        (v11 >  0 && v12 <  0) ||
		        (v11 == 0 && v12 != 0) ||
		        (v11 != 0 && v12 == 0)) {

			return(TRUE);
		    }
		} else
		if (v21 == 0 && v22 == 0) {
		    float qx,qy;
		    float vx,vy;
		    float p_qx,p_qy;
		    float t1,t2,tmp;

		    qx = p11->pf_x;
		    qy = p11->pf_y;

		    vx = p12->pf_x - qx;
		    vy = p12->pf_y - qy;

		    p_qx = p21->pf_x - qx;
		    p_qy = p21->pf_y - qy;

		    t1 = (p_qx*vx + p_qy*vy) / (vx*vx + vy*vy);

		    p_qx = p22->pf_x - qx;
		    p_qy = p22->pf_y - qy;

		    t2 = (p_qx*vx + p_qy*vy) / (vx*vx + vy*vy);

		    if (t1 > t2) {
  			tmp = t1;
  			t1 = t2;
  			t2 = tmp; 
		    }

		    if (t1 <= 1 && t2 >= 0) {
		    	return(TRUE);
		    }
    		}
	    }

	    p11 = p12;
	}

	/*
	*  Either one polygon is completely inside the other or completely
	*  outside the other.  Check this by casting a ray.
	*/

	count = 0;

	p11 = poly1->poly_points;
	x0 = p11->pf_x;
	y0 = p11->pf_y;

	p22 = poly2->poly_points;
	x2 = p22->pf_x;
	y2 = p22->pf_y;

	if (y2 == y0) y2 -= 0.01;

	for (i = 0; i < n2; i++) {
		x1 = x2;
		y1 = y2;
		
		if (i == n2-1) {
			p22 = poly2->poly_points;
		} else {
			p22++;
		}

		x2 = p22->pf_x;
		y2 = p22->pf_y;
		if (y2 == y0) y2 -= 0.01;
			
		if ((y1 > y0 && y2 < y0) ||
		    (y1 < y0 && y2 > y0)) {
		    	float x;

			x = x2 + (x1-x2)/(y1-y2)*(y0-y2);

			if (x < x0) {
				count++;
			}
		}
	}

	if ((count & 1) == 1) {
		return(TRUE);
	}

	count = 0;

	p11 = poly2->poly_points;
	x0 = p11->pf_x;
	y0 = p11->pf_y;

	p22 = poly1->poly_points;
	x2 = p22->pf_x;
	y2 = p22->pf_y;

	if (y2 == y0) y2 -= 0.01;

	for (i = 0; i < n1; i++) {
		x1 = x2;
		y1 = y2;

		if (i == n1-1) {
			p22 = poly1->poly_points;
		} else {
			p22++;
		}

		x2 = p22->pf_x;
		y2 = p22->pf_y;
		if (y2 == y0) y2 -= 0.01;

		if ((y1 > y0 && y2 < y0) ||
		    (y1 < y0 && y2 > y0)) {
		    	float x;

			x = x2 + (x1-x2)/(y1-y2)*(y0-y2);

			if (x < x0) {
				count++;
			}
		}
	}

	if ((count & 1) == 1) {
		return(TRUE);
	}

	return(FALSE);
}
