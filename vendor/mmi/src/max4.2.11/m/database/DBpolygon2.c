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
 * DBpolygon2.c --
 *
 * geometric tests and operations on polygons
 *
 */

#ifndef lint
static char rcsid[] = "$Header$";
#endif  not lint

#include <stdio.h>
#include <string.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "malloc.h"
#include "message.h"
#include "geometry.h"
#include "utils.h"
#include "layout.h"


/*
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectRectQ1 --
 *
 * Does real work for inline func DBPolygonIntersectQ()
 *	
 * Check for intersection between polygon and rect.
 * Two point polygons are treated as circle inscribed in
 * "polygon" bbox.
 *
 * Returns TRUE if "poly" intersected with the closed rectangle
 * "rect" is non-empty and FALSE otherwise.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 * NOTE: assumes caller has already checked that following special cases
 *       do not hold:
 *       1. polygon bbox contained in rect.
 *       2. polygon bbox and rect disjoint.
 *
 *-----------------------------------------------------------------------------
 */

bool DBPolygonIntersectRectQ1(Polygon *poly, Rect *rect) 
{
  int i,n;
  PointFloat *cur,*next;
  double l,r,b,t;
  PointFloat p1,p2,ps;
  int count;
  double x0,y0;
  double x1,y1;
  double x2,y2;
  double x,y;
  double eps;

  /* Get left, right, bottom, and top */
  l = rect->r_ll.p_x;
  r = rect->r_ur.p_x;
  b = rect->r_ll.p_y;
  t = rect->r_ur.p_y;

  /* Get number of points and start of point array */
  n = poly->poly_size;
  next = poly->poly_points;

  /* special case two point polygon (as circle inscribed in bbox) 
   *
   * NOTE:  Assumes caller handles special case where
   *        rect x or y extent contains circle x or y bbox.
   *        Hence only case we need to handle below is where  
   *        a corner or rect pokes into circle bbox.
   */ 
  if(n == 2)
  {
    double dx, dy, cx, cy, dx2, dy2;
    PointFloat *p0 = next;
    PointFloat *p1 = next+1;

    /* deltas from p0 to center of circle */
    dx = (p1->pf_x - p0->pf_x)/2; 
    dy = (p1->pf_y - p0->pf_y)/2; 

    /* center of circle */
    cx = p0->pf_x + dx;
    cy = p0->pf_y + dy;

    /* deltas from rect to center of circle squared */
    dx2 = MIN((l-cx)*(l-cx),(r-cx)*(r-cx));
    dy2 = MIN((b-cy)*(b-cy),(t-cy)*(t-cy)); 

    return dx2+dy2 <= dx*dx;
  }

  /* check for intersection between polygon edges and rect. */
  for (i = 0; i < n; i++)
  {
    /* Move to the next line segment */
    cur = next;

    /* The first point comes "after" the last point */
    if (i == n-1)
    {
      next = poly->poly_points;
    } else {
      next++;
    }

    /* Get the endpoints of the current line segment */
    x1 = cur->pf_x;
    y1 = cur->pf_y;
    x2 = next->pf_x;
    y2 = next->pf_y;

    /* If the line segment isn't below the bottom or above the top of the rect. */
    if ((y1 >= b || y2 >= b) && (y1 <= t || y2 <= t)) {
      /* If it could cross (or touch) the left of the rect. */
      if (x1 < l) {
        if (x2 >= l) {
          /* Get the y intersection */
          y = y1 + (y2-y1)*(l-x1)/(x2-x1);
          /* If it's between the bottom and the top there is an intersection */
          if (y >= b && y <= t) {
            return(TRUE);
          }
        }
      } else
      /* If it could cross (or touch) the left of the rect. */
      if (x1 > l) {
        if (x2 <= l) {
          /* Get the y intersection */
          y = y1 + (y2-y1)*(l-x1)/(x2-x1);
          /* If it's between the bottom and the top there is an intersection */
          if (y >= b && y <= t) {
            return(TRUE);
          }
        }
      /* If x1 is at the left */
      } else {
          /* If y1 between the bottom and the top there is an intersection */
          if (y1 >= b && y1 <= t) {
            return(TRUE);
          }
      }

      /* If it could cross (or touch) the right of the rect. */
      if (x1 < r) {
        if (x2 >= r) {
          /* Get the y intersection */
          y = y1 + (y2-y1)*(r-x1)/(x2-x1);
          /* If it's between the bottom and the top there is an intersection */
          if (y >= b && y <= t) {
            return(TRUE);
          }
        }
      } else
      /* If it could cross (or touch) the right of the rect. */
      if (x1 > r) {
        if (x2 <= r) {
          /* Get the y intersection */
          y = y1 + (y2-y1)*(r-x1)/(x2-x1);
          /* If it's between the bottom and the top there is an intersection */
          if (y >= b && y <= t) {
            return(TRUE);
          }
        }
      /* If x1 is at the right */
      } else {
          /* If y1 between the bottom and the top there is an intersection */
          if (y1 >= b && y1 <= t) {
            return(TRUE);
          }
      }
    }

    /* If the line segment isn't left of the left or right of the right of the rect. */
    if ((x1 >= l || x2 >= l) && (x1 <= r || x2 <= r)) {
      /* If it could cross (or touch) the bottom of the rect. */
      if (y1 < b) {
        if (y2 >= b) {
          /* Get the x intersection */
          x = x1 + (x2-x1)*(b-y1)/(y2-y1);
          /* If it's between the left and the right there is an intersection */
          if (x >= l && x <= r) {
            return(TRUE);
          }
        }
      } else
      /* If it could cross (or touch) the bottom of the rect. */
      if (y1 > b) {
        if (y2 <= b) {
          /* Get the x intersection */
          x = x1 + (x2-x1)*(b-y1)/(y2-y1);
          /* If it's between the left and the right there is an intersection */
          if (x >= l && x <= r) {
            return(TRUE);
          }
              }
      /* If y1 is at the bottom */
      } else {
          /* If x1 between the left and the right there is an intersection */
          if (x1 >= l && x1 <= r) {
            return(TRUE);
          }
      }

      /* If it could cross (or touch) the top of the rect. */
      if (y1 < t) {
        if (y2 >= t) {
          /* Get the x intersection */
          x = x1 + (x2-x1)*(t-y1)/(y2-y1);
          /* If it's between the left and the right there is an intersection */
          if (x >= l && x <= r) {
            return(TRUE);
          }
        }
      } else
      /* If it could cross (or touch) the top of the rect. */
      if (y1 > t) {
        if (y2 <= t) {
          /* Get the x intersection */
          x = x1 + (x2-x1)*(t-y1)/(y2-y1);
          /* If it's between the left and the right there is an intersection */
          if (x >= l && x <= r) {
            return(TRUE);
          }
              }
      /* If y1 is at the top */
      } else {
          /* If x1 between the left and the right there is an intersection */
          if (x1 >= l && x1 <= r) {
            return(TRUE);
          }
      }
    }
  }

  /* if we get here the polygon edges don't intersect the rect, so
   * the rect is either entirely inside the polygon or does not
   * intersect it.
   */ 

  /* first do quick check with bboxes for speed */
  if(!GEO_SURROUND(&poly->poly_bbox,rect)) return FALSE;
  
  /*
  *  OK, need to check the "hard" case.
  *
  *  If none of the edges intersect or lie inside the rectangle then 
  *  the only other possibility for intersection is that the rectangle
  *  lies entirely inside the polygon.  Check this by counting the
  *  number of intersections a ray from the center of the rectangle
  *  to the right makes with the polygon.  If this number is odd then
  *  that point (and the rectangle) lie inside the polygon.
  *
  *  NOTE: This test fails when a vertex lies exactly at the height of
  *  center point and the two adjacent vertices are either both above
  *  or below. This is avoided by perturbing any points which lie
  *  exactly at the height "eps" down.
  */

  /* Initial the intersection count */
  count = 0;

  /* Set the point to the center of the rect. */
  x0 = 0.5*(l+r);
  y0 = 0.5*(b+t);

  /* Set the perturbation, "eps", to 0.0001 of the smallest rect. dim. */
  eps = r-l;
  if (t-b < eps) eps = t-b;
  eps *= 0.0001;

  /* Start at the first point */
  next = poly->poly_points;

  /* Copy and perturb it if necessary */
  p2 = *next;
  if (p2.pf_y == y0) p2.pf_y -= eps;
  next++;

  /* Go through all edges */
  for (i = 0; i < n; i++, next++)
  {
    /* Wrap the end to the beginning */
    if (i == n-1) next = poly->poly_points;

    /* Copy the two end points and perturb if necessary */
    p1 = p2; 
    p2 = *next;
    if (p2.pf_y == y0) p2.pf_y -= eps;

    /* If is can intersect a ray to the left of (x0,y0) */
    if ((p1.pf_y > y0 && p2.pf_y < y0) ||
        (p1.pf_y < y0 && p2.pf_y > y0))
    {
      /* Find the x intersection point */
      x = p2.pf_x + (p1.pf_x-p2.pf_x)/(p1.pf_y-p2.pf_y)*(y0-p2.pf_y);

      /* If it's to the left of (x0,y0) count it */
      if (x < x0) {
        count++;
      }
    }
  }

  /* If the count is odd, (x0,y0) (and the rect.) is inside the polygon */
  if ((count & 1) == 1) {
    return(TRUE);
  }

  return(FALSE);
}

/* Maximum polygon size for which enough space has been allocated */
static int dbPolySizeAlloced = 0;

/* data areas for results of DBPolygonIntersectRect()
 * these are "grown" as needed and reused on each call
 * to DBPolygonIntersectRect
 */

static PointFloat *dbPolyPoints = NULL; 
PointFloat **dbPolyList = NULL; 

/*
 * Vertex / listv - main data structure used internally by 
 *                  DBPolygonIntersectRect().  
 *
 *  All the points in the polygon and the rect are copied into this form 
 *  and intersections between lines are added.
 */

typedef struct vertex
{
  int entry_exit;
  PointFloat p;
  double alpha;
  struct vertex *prev,*next;
  struct vertex *neighbor;
} Vertex;

/* A few constants for the "entry_exit" element of "Vertex" */

#define ENTRY		0
#define EXIT		1
#define SCANNED		2

/*
*  "listv" is an array are temporary "Vertex"s used by this routine.  These
*  are NOT "free"d after each call and they are only "realloc"ed if more are
*  needed.  "cv" is the number of the currect vertex available.
*/

static Vertex *listv = NULL;
static int cv;

/* for debugging */
static void printvertex(char *intro, Vertex *vert) {
  fprintf(stderr,"%s%g %g, %g %d, %08x, %08x %08x, %08x\n",
	  intro,vert->p.pf_x,vert->p.pf_y,vert->alpha,vert->entry_exit,
	  vert,vert->prev,vert->next,vert->neighbor);
}

/*
*  This routine gets, initializes, and appends a vertex to a circularly
*  linked list of vertices, "list" and return a pointer to the new vertex.
*/

static Vertex *appendv(Vertex **list, double x, double y, double alpha) 
{
  Vertex *cur,*head;

  /* Get the head of the list */
  head = *list;

  /* If it's "NULL" then initialize the entire list */
  if (head == NULL) 
  {
    /* Get an available "vertex" */
    cur = &listv[cv];
    cv++;
		
    /* Initialize it */
    cur->entry_exit = ENTRY;
    cur->p.pf_x = x;
    cur->p.pf_y = y;
    cur->alpha = alpha;
    cur->next = cur;
    cur->prev = cur;
    cur->neighbor = NULL;

    /* Point the list at this entry */
    *list = cur;
  } 
  else 
  {
    /* Get an available "vertex" */
    cur = &listv[cv];
    cv++;
		
    /* Initialize it */
    cur->entry_exit = ENTRY;
    cur->p.pf_x = x;
    cur->p.pf_y = y;
    cur->alpha = alpha;
    cur->next = head;
    cur->prev = head->prev;
    cur->neighbor = NULL;
    
    /* Link it at the end of the list */
    head->prev = cur;
    cur->prev->next = cur;
  }

  /* Return a pointer to the new "vertex" */
  return(cur);
}

/*
*  This routine inserts a new vertex (an intersection of two line segments)
*  into the list where it belongs.  "start" points to the initial endpoint
*  of one of the line segments in question.
*/

static Vertex *insertv(Vertex *start, double x, double y, double alpha)
{
  Vertex *cur,*new;

  /* Start after the initial endpoint */
  cur = start->next;;

  /*
  *  Continue until the final endpoint is reached, "neighbor == NULL"
  *  or the next vertex should be after this one.
  */
  while (cur->neighbor != NULL && alpha > cur->alpha)
  {
    cur = cur->next;
  }

  /* Append the new vertex in the correct place */
  new = appendv(&cur,x,y,alpha);

  /* Return a pointer to the new "vertex" */
  return(new);
}


/*
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectRect1 --
 *
 * Does real work for inline function DBPolygonIntersectRect()
 *
 *	This routine clips "poly" against "rect".  
 *
 *      RETURNS the number of resulting polygons, >= 0.
 *
 *      storage is allocated for and:
 *        dbPolyPoints is filled in with points for the clipped polygon(s).
 *        dbPolyList is filled in with pointers to the start of the points 
 *             for each polygon in the result.  An additional final entry 
 *             in "list" points one beyond the end of the points in clip.
 *	       This is so "list[i+1] - list[i]" always gives the number 
 *             of points in polygon i (which start at "list[i]").
 *        THESE DATA AREAS ARE REUSED ON NEXT CALL.
 *
 *      *listp is set to point to dbPolyList.
 *
 *	This algorithm is based on "Efficient Clipping of Arbitrary Polygons"
 *	by Gunther Greiner and Kai Hormann, ACM Transactions on Graphics,
 *	Vol. 17, No. 4, April 1998, pages 71-83.  It has been specialized
 *	for one of the polygons being a rectangle (in places).
 *
 *
 * NOTE:  results are overwritten on next call to this routine.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 * NOTE: assumes caller has already checked that following special cases
 *       do not hold:
 *
 *       1. polygon bbox contained in rect.
 *       2. polygon bbox and rect disjoint.
 *
 * NOTE:
 *
 *-----------------------------------------------------------------------------
 */
int DBPolygonIntersectRect1(Polygon *poly, 
			               /* polygon to "clip" */ 
			    Rect *rect,
			               /* rectangle to clip against */     
			    PointFloat ***listp)
                                       /* set to list of pointers into
					* point array that gives vertices
					* of the polygons.
					*
					* See header comment above for
					* details.
					*/
{
  int i,n;
  double l,r,b,t;
  int intcount;
  Vertex *polyv;
  Vertex *rectv;
  Vertex *vlb,*vlt,*vrb,*vrt;
  Vertex *scanv,*nextv;
  PointFloat p1,p2,pn;
  Vertex *v1,*v2;
  double x,y,alpha;
  int inside;
  int npoly,npts;
  PointFloat *clippt;
  Vertex *scanv2;

  /* Get left, right, bottom, and top */
  l = rect->r_ll.p_x;
  r = rect->r_ur.p_x;
  b = rect->r_ll.p_y;
  t = rect->r_ur.p_y;

  /* Get number of points in the polygon */
  n = poly->poly_size;

  /* Allocate enough room for the worst case. */
  if (dbPolySizeAlloced < n) 
  {
    if(listv) FREE_TAG(listv,"listv");
    MALLOC_TAG(Vertex *, 
               listv, 
               8*n*sizeof(Vertex), 
               "listv");

    if(dbPolyPoints) FREE_TAG(dbPolyPoints,"dbPolyPoints");
    MALLOC_TAG(PointFloat *, 
               dbPolyPoints, 
               4*n*sizeof(PointFloat), 
               "dbPolyPoints");


    if(dbPolyList) FREE_TAG(dbPolyList,"dbPolyList");
    MALLOC_TAG(PointFloat **, 
               dbPolyList, 
               2*n*sizeof(PointFloat), 
               "dbPolyList");

    dbPolySizeAlloced = n;
  }
  *listp = dbPolyList;

  /* Start allocating from the start of the list */
  cv = 0;

  /* The first polygon goes at beginning of points array */
  dbPolyList[0] = dbPolyPoints;

  /* Convert clipping rectangle to a list of vertices */
  rectv = NULL;
  vlb = appendv(&rectv,l,b,0.0);
  vlt = appendv(&rectv,l,t,0.0);
  vrt = appendv(&rectv,r,t,0.0);
  vrb = appendv(&rectv,r,b,0.0);

  /* Convert polygon to a list of vertices */
  polyv = NULL;
  for (i = 0; i < n; i++) 
  {
    appendv(&polyv,poly->poly_points[i].pf_x,poly->poly_points[i].pf_y,0.0);
  }


    /*
    *  Move any points exactly even with sides of the rectangle.  This
    *  helps minimize the degenerate cases.
    */
    scanv = polyv;
    for (i = 0; i < n; i++)
    {
      if (scanv->p.pf_x == l) {
        scanv->p.pf_x -= 0.000001;  /* Smaller movement */
      } else
      if (scanv->p.pf_x == r) {
        scanv->p.pf_x += 0.000001;  /* Smaller movement */
      }

      if (scanv->p.pf_y == b) {
        scanv->p.pf_y -= 0.000001;  /* Smaller movement */
      } else
      if (scanv->p.pf_y == t) {
        scanv->p.pf_y += 0.000001;  /* Smaller movement */
      }

      scanv = scanv->next;          /* TJL's oversite!!! */
    }

  /*
  *  Get ready to count the number of line segment intersections,
  *  "intcount" and detect of the LL corner of the rectangle is
  *  "inside" the polygon.
  */
  intcount = 0;
  inside = ENTRY;

  /*
  *  Intersect each line segment in the polygon with each edge of
  *  the rectangle.  This is optimized for the rectangle (i.e.
  *  arbitrary line segment to line segment intersections don't
  *  occur).
  *
  *  This was Phase 1 in the paper (referenced in header comment
  *  for this routine)
  */

  scanv = polyv;
  for (i = 0; i < n; i++)
  {
    nextv = scanv->next;

    /* Get the current, "untouched" polygon line segment */
        p1 = scanv->p;
        p2 = nextv->p;

    /*  May want to further reject optimize this test,
     *  as suggested in the paper mentioned
     *  in header comment.
     */

    /* If it isn't all below or all above the rectangle */
    if ((p1.pf_y > b || p2.pf_y > b) && (p1.pf_y < t || p2.pf_y < t))
    {
      /* If is spans the left edge in the x direction */
      if ((p1.pf_x < l && p2.pf_x > l) || (p1.pf_x > l && p2.pf_x < l))
      {
        /* Find the intersection with x = left */
        alpha = (l-p1.pf_x)/(p2.pf_x-p1.pf_x);
        y = p1.pf_y + alpha*(p2.pf_y-p1.pf_y);

        /* If an intersection occurs */
        if (y > b && y < t)
        {
          /* Count it */
          intcount++;

          /*
          *  Insert the intersection in both lists and
          *  link them together
          */
          v1 = insertv(scanv,l,y,alpha);

          alpha = (y-b)/(t-b);
          v2 = insertv(vlb,l,y,alpha);

          v1->neighbor = v2;
          v2->neighbor = v1;
        }
      }

      /* If is spans the right edge in the x direction */
      if ((p1.pf_x < r && p2.pf_x > r) || (p1.pf_x > r && p2.pf_x < r))
      {
        /* Find the intersection with x = right */
        alpha = (r-p1.pf_x)/(p2.pf_x-p1.pf_x);
        y = p1.pf_y + alpha*(p2.pf_y-p1.pf_y);

        /* If an intersection occurs */
        if (y > b && y < t)
        {
          /* Count it */
          intcount++;

          /*
          *  Insert the intersection in both lists and
          *  link them together
          */
          v1 = insertv(scanv,r,y,alpha);

          alpha = (t-y)/(t-b);
          v2 = insertv(vrt,r,y,alpha);

          v1->neighbor = v2;
          v2->neighbor = v1;
        }
      }
    }

    /* If it isn't all left or all right the rectangle */
    if ((p1.pf_x > l || p2.pf_x > l) && (p1.pf_x < r || p2.pf_x < r))
    {

      /* If is spans the bottom edge in the y direction */
      if ((p1.pf_y < b && p2.pf_y > b) || (p1.pf_y > b && p2.pf_y < b))
      {

        /* Find the intersection with y = bottom */
        alpha = (b-p1.pf_y)/(p2.pf_y-p1.pf_y);
        x = p1.pf_x + alpha*(p2.pf_x-p1.pf_x);

        /* If an intersection occurs */
        if (x > l && x < r)
        {
          /* Count it */
          intcount++;

          /*
          *  Insert the intersection in both lists and
          *  link them together
          */
          v1 = insertv(scanv,x,b,alpha);

          alpha = (r-x)/(r-l);
          v2 = insertv(vrb,x,b,alpha);

          v1->neighbor = v2;
          v2->neighbor = v1;
        }
      }

      /* If is spans the top edge in the y direction */
      if ((p1.pf_y < t && p2.pf_y > t) || (p1.pf_y > t && p2.pf_y < t))
      {
        /* Find the intersection with y = top */
        alpha = (t-p1.pf_y)/(p2.pf_y-p1.pf_y);
        x = p1.pf_x + alpha*(p2.pf_x-p1.pf_x);

        /* If an intersection occurs */
        if (x > l && x < r)
        {
          /* Count it */
          intcount++;

          /*
          *  Insert the intersection in both lists and
          *  link them together
          */
          v1 = insertv(scanv,x,t,alpha);

          alpha = (x-l)/(r-l);
          v2 = insertv(vlt,x,t,alpha);

          v1->neighbor = v2;
          v2->neighbor = v1;
        }
      }
    }

    /*
    *  Check to see if a ray from the LL corner of the rectangle
    *  intersects this line segment (to determine if the LL corner
    *  is inside of outside the polygon).
    */
    if ((p1.pf_y < b && p2.pf_y > b) || (p1.pf_y > b && p2.pf_y < b))
    {
      alpha = (b-p1.pf_y)/(p2.pf_y-p1.pf_y);
      x = p1.pf_x + alpha*(p2.pf_x-p1.pf_x);

      if (x < l)
      {
        if (inside == ENTRY) inside = EXIT;
        else                 inside = ENTRY;
      }
    }

    /* Next line segment */
    scanv = nextv;
  }

  /* If there were not intersections */
  if (intcount == 0)
  {
    /* If the LL corner of the rectangle was inside */
    if (inside == EXIT)
    {
      /* Then the rectangle was all inside and return this */
      dbPolyPoints[0].pf_x = l;
      dbPolyPoints[0].pf_y = b;

      dbPolyPoints[1].pf_x = l;
      dbPolyPoints[1].pf_y = t;

      dbPolyPoints[2].pf_x = r;
      dbPolyPoints[2].pf_y = t;

      dbPolyPoints[3].pf_x = r;
      dbPolyPoints[3].pf_y = b;

      dbPolyList[0] = dbPolyPoints;
      dbPolyList[1] = dbPolyPoints + 4;

      return(1);
    } else {
      /*
      *  If not, the rectangle was entirely outside so zero (0)
      *  polygons are returned.
      */
      return(0);
    }
  }

  /*
  *  Phase 2 (in the paper referenced in header comment for this
  *  routine) is done below by marking all the intersections as 
  *  entering or exiting the other polygon.
  */

  /* Mark all the intersections in the rectangle as entering or exiting */
  scanv = rectv;
  do
  {
    /* If this vertex is an intersection */
    if (scanv->neighbor != NULL)
    {
      /* Record the current value */
      scanv->entry_exit = inside;

      /* Toggle it */
      if (inside == ENTRY) inside = EXIT;
      else                 inside = ENTRY;
    }

    /* Next vertex */
    scanv = scanv->next;
  } while (scanv != rectv);

  /* Decide if the first point in the polygon, inside the rectangle */
  if (polyv->p.pf_x >= l && polyv->p.pf_x <= r &&
      polyv->p.pf_y >= b && polyv->p.pf_y <= t)
  {
    inside = EXIT;
  } else {
    inside = ENTRY;
  }


  /* Mark all the intersections in the polygon as entering or exiting */
  scanv = polyv;
  do
  {
    /* If this vertex is an intersection */
    if (scanv->neighbor != NULL)
    {
      /* Record the current value */
      scanv->entry_exit = inside;

      /* Toggle it */
      if (inside == ENTRY) inside = EXIT;
      else                 inside = ENTRY;
    }

    /* Next vertex */
    scanv = scanv->next;
  } while (scanv != polyv);

  /*
  *  Phase 3 in the paper mentioned above (i.e. generating the clipped,
  *  output polygons) is done below.
  */

  /* No output polygons or points to start with */
  npoly = 0;
  clippt = dbPolyPoints;
  npts = 0;

  /* Scan the entire original polygon and intersection points */
  scanv = polyv;
  do
  {
    /* If this is an intersection point and it hasn't been scanned */
    if (scanv->neighbor != NULL && scanv->entry_exit != SCANNED)
    {
      /* Start a new polygon */
      dbPolyList[npoly] = clippt + npts;
      npoly++;

      /* With this point and continue scanning */
      scanv2 = scanv;
      clippt[npts].pf_x = scanv2->p.pf_x;
      clippt[npts].pf_y = scanv2->p.pf_y;
      npts++;

      /* Continue until we return to the starting point */
      do
      {
        /* If this intersection point in entering */
        if (scanv2->entry_exit == ENTRY)
        {
          /* Scan forward through all the non-intersection points */
          do
          {
            /* Mark this as scanned */
            scanv2->entry_exit = SCANNED;
            scanv2 = scanv2->next;

            /* Stop if almost back */
            if (scanv2->neighbor == scanv) break;

            /* Add this point to the current output polygon */
            clippt[npts].pf_x = scanv2->p.pf_x;
            clippt[npts].pf_y = scanv2->p.pf_y;
            npts++;
          } while (scanv2->neighbor == NULL);
        } else {
          /* Scan backward through all the non-intersection points */
          do
          {
            /* Mark this as scanned */
            scanv2->entry_exit = SCANNED;
            scanv2 = scanv2->prev;

            /* Stop if almost back */
            if (scanv2->neighbor == scanv) break;

            /* Add this point to the current output polygon */
            clippt[npts].pf_x = scanv2->p.pf_x;
            clippt[npts].pf_y = scanv2->p.pf_y;
            npts++;
          } while (scanv2->neighbor == NULL);
        }

        /*
        *  Mark this as scanned and move to the identical
        *  intersection in the other polygon list.
        */
        scanv2->entry_exit = SCANNED;
        scanv2 = scanv2->neighbor;
      } while (scanv2 != scanv); 
    }

    /* Continue moving through the polygon vertex list */
    scanv = scanv->next;
  } while (scanv != polyv);

  /* Finish the last polygon */
  dbPolyList[npoly] = clippt + npts;

  /* Return the number of polygons */
  return(npoly);
}


/*
*  The main data structure of the routine.  All the line segments in "poly2"
*  are represented in this form to reduce repeated computations.
*/

typedef struct lineSegment
{
  PointFloat *p1,*p2;
  double a,b,c;
  PointFloat ll,ur;
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
 *-----------------------------------------------------------------------------
 *
 * DBPolygonIntersectPolyQ1 --
 *
 * Does real work for inline func DBPolygonIntersectPolyQ()
 *	
 * Check for intersection between polygon and polygon.
 * Two point polygons (circles) are not treated.
 *
 * Returns TRUE if "poly1" intersected with "poly2" 
 * is non-empty and FALSE otherwise.
 *
 * NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"
 *
 * NOTE: assumes caller has already checked that following special case
 *       do not hold:
 *       1. poly1 bbox and poly2 bbox.
 *
 *-----------------------------------------------------------------------------
 */

bool DBPolygonIntersectPolyQ1(Polygon *poly1, Polygon *poly2) 
{
  int i,j;
  int n1,n2;
  double a1,b1,c1;
  PointFloat ll,ur;
  double a2,b2,c2;
  PointFloat *p11,*p12,*p21,*p22;
  double v11,v12,v21,v22;
  int count;
  double x0,y0,x1,y1,x2,y2;
  double eps;

  /* Get number of points in the polygons */
  n1 = poly1->poly_size;
  n2 = poly2->poly_size;

  /* Allocate enough room for the line segments */
  if (ns < n2)
  {
    /* Get enough room */
    if(lists) FREE_TAG(lists,"lists");
    MALLOC_TAG(LineSegment *,
    	       lists,
    	       n2*sizeof(LineSegment),
    	       "lists");

    ns = n2;
  }

  /*
  *  Set up the line equation information for each line segment in
  *  polygon 2.
  */
  cs = 0;

  p21 = poly2->poly_points;

  for (i = 0; i < n2; i++)
  {
    if (i == n2-1) {
      p22 = poly2->poly_points;
    } else {
      p22 = p21+1;
    }

    lists[cs].p1 = p21;
    lists[cs].p2 = p22;

    if (p21->pf_x < p22->pf_x) {
      lists[cs].ll.pf_x = p21->pf_x;
      lists[cs].ur.pf_x = p22->pf_x;
    } else {
      lists[cs].ll.pf_x = p22->pf_x;
      lists[cs].ur.pf_x = p21->pf_x;
    }

    if (p21->pf_y < p22->pf_y) {
      lists[cs].ll.pf_y = p21->pf_y;
      lists[cs].ur.pf_y = p22->pf_y;
    } else {
      lists[cs].ll.pf_y = p22->pf_y;
      lists[cs].ur.pf_y = p21->pf_y;
    }

    lists[cs].a = p22->pf_y - p21->pf_y;
    lists[cs].b = p21->pf_x - p22->pf_x;
    lists[cs].c = p22->pf_x*p21->pf_y - p21->pf_x*p22->pf_y;

    cs++;

    p21 = p22;
  }

  p11 = poly1->poly_points;

  /*
  *  Check to see if any line segment in polygon 1 intersects any line
  *  segment in polygon 2.  If so, the polygons intersect and return
  *  TRUE.
  */

  for (i = 0; i < n1; i++)
  {
    if (i == n1-1) {
      p12 = poly1->poly_points;
    } else {
      p12 = p11+1;
    }

    /*
    *  Set up the line equation information for the current line
    *  segment in polygon 1.
    */

    if (p11->pf_x < p12->pf_x) {
      ll.pf_x = p11->pf_x;
      ur.pf_x = p12->pf_x;
    } else {
      ll.pf_x = p12->pf_x;
      ur.pf_x = p11->pf_x;
    }

    if (p11->pf_y < p12->pf_y) {
      ll.pf_y = p11->pf_y;
      ur.pf_y = p12->pf_y;
    } else {
      ll.pf_y = p12->pf_y;
      ur.pf_y = p11->pf_y;
    }

    a1 = p12->pf_y - p11->pf_y;
    b1 = p11->pf_x - p12->pf_x;
    c1 = p12->pf_x*p11->pf_y - p11->pf_x*p12->pf_y;

    for (j = 0; j < n2; j++)
    {
      if (ll.pf_x > lists[j].ur.pf_x || ur.pf_x < lists[j].ll.pf_x ||
          ll.pf_y > lists[j].ur.pf_y || ur.pf_y < lists[j].ll.pf_y) {
        continue;
      }

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
          return(TRUE);
        }
    }

    p11 = p12;
  }

  /*
  *  Either one polygon is completely inside the other or completely
  *  outside the other.  Check this by casting a ray.
  */

  eps = poly1->poly_bbox.r_ur.p_x - poly1->poly_bbox.r_ll.p_x;
  if (eps > poly1->poly_bbox.r_ur.p_y - poly1->poly_bbox.r_ll.p_y) {
    eps = poly1->poly_bbox.r_ur.p_y - poly1->poly_bbox.r_ll.p_y;
  }
  eps *= 0.0001;

  count = 0;

  p11 = poly1->poly_points;
  x0 = p11->pf_x;
  y0 = p11->pf_y;

  p22 = poly2->poly_points;
  x2 = p22->pf_x;
  y2 = p22->pf_y;

  if (y2 == y0) y2 -= eps;

  for (i = 0; i < n2; i++)
  {
    x1 = x2;
    y1 = y2;

    if (i == n2-1) {
      p22 = poly2->poly_points;
    } else {
      p22++;
    }

    x2 = p22->pf_x;
    y2 = p22->pf_y;
    if (y2 == y0) y2 -= eps;

    if ((y1 > y0 && y2 < y0) ||
        (y1 < y0 && y2 > y0)) {
          double x;

      x = x2 + (x1-x2)/(y1-y2)*(y0-y2);

      if (x < x0) {
        count++;
      }
    }
  }

  if ((count & 1) == 1) {
    return(TRUE);
  }

  eps = poly2->poly_bbox.r_ur.p_x - poly2->poly_bbox.r_ll.p_x;
  if (eps > poly2->poly_bbox.r_ur.p_y - poly2->poly_bbox.r_ll.p_y) {
    eps = poly2->poly_bbox.r_ur.p_y - poly2->poly_bbox.r_ll.p_y;
  }

  eps *= 0.0001;

  count = 0;

  p11 = poly2->poly_points;
  x0 = p11->pf_x;
  y0 = p11->pf_y;

  p22 = poly1->poly_points;
  x2 = p22->pf_x;
  y2 = p22->pf_y;

  if (y2 == y0) y2 -= eps;

  for (i = 0; i < n1; i++)
  {
    x1 = x2;
    y1 = y2;

    if (i == n1-1) {
      p22 = poly1->poly_points;
    } else {
      p22++;
    }

    x2 = p22->pf_x;
    y2 = p22->pf_y;
    if (y2 == y0) y2 -= eps;

    if ((y1 > y0 && y2 < y0) ||
        (y1 < y0 && y2 > y0)) {
          double x;

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



