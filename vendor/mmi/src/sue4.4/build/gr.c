// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
// LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
// CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
// DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
// INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
// DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
// PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

// Global Router

// Uses database from nl.
// Build probability network for steiner boxes into grid.

// For steiner boxes (not degenerate lines), tries one or two turn routes only.
// Updates probabilities if passed and erases old probabilities in matrix.

// For steiner lines, tries straight and +/-1, +/-2 jogs.

// to run as a shared library
//   need a wish with an nl loaded (e.g. sue)
//   load ./gr_package.so
//   load ~/dev/groute/gr_package.so

// to run sdp
//   setenv NL_PATH /volume/mmi/src/nl-0.29/bin-debug.sparc-solaris2
//   setenv NL_PATH /volume/mmi/src/nl-0.30x/bin-debug.sparc-solaris2
//   cd /volume/mmi_proj/test/malleable/sdp/sue
//   suez -SET PROJECT=maltest sdp

//   cd /volume/mmi_proj/test/malleable/sue
//   suez -SET PROJECT=maltest mdp1


// TODO: fix for edges of design -- possibly add congestion to make
//       up for outside of diearea (tracks)   

// TODO: possibly extend steiner route out 1

// TODO: possibly endpoints using real coords, not gr coords.  not BEF

// TODO: remove route_start vs. route_cont since BEF???

// 0 disables.  Might be a bug with
#define DO_ROUTE_START 0

// TODO: save routes in segment.  save whether h or v first and x or y
//       of turn.  Special for jogged routes.


#include <stdio.h>
#include <math.h> 
#include <string.h>
#include <strings.h>

// Uses Jays memory manager instead
//#include <malloc.h> 

#include <time.h> 
#include <tcl.h>


// nl stuff
#include "nl_include.h" 

#ifndef NULL
#define NULL 0
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FAIL
#define FAIL -1
#endif

#ifndef SUCCEED
#define SUCCEED 1
#endif


// Beginning/Ending Fudge.  Could use the actual point in the grid box.
// 0.5 assume average is half way.  This is the amount of h/v usage for
// the grid at beginning/end of a route.

//#define BEF 1.0
#define BEF 0.5


// for compute 2-d array locations

#define twod(x,y) ((x)*tech.ydim+(y))

#define max(x,y) ((x) > (y) ? (x) : (y))
#define min(x,y) ((x) < (y) ? (x) : (y))


// convert coords to global route grid coords
#define x_adjust(x) ( floor( 1.0 * (x) / tech.grid_x - tech.offset_x ) )
#define y_adjust(y) ( floor( 1.0 * (y) / tech.grid_y - tech.offset_y ) )

// memory group for memory allocator
mem_group gr_group = NULL;

typedef struct s_Point  {

  int x, y;      // coords of point

} Point;


typedef struct s_Segment  {

  Point pt1, pt2;   // the actual points, not pointers to them
  int pt1_status, routed;
  // save ipin or at least net name also

} Segment;


typedef struct s_SLink  {

  Segment *segment;
  struct s_SLink *next;

} SLink;

SLink *unrouted_list = NULL;
SLink *routed_list = NULL;


// Routing grid data

typedef struct s_Grid  {

  double v, h;    // vertical and horizontal grids

} Grid;

// probability grid
Grid *pgrid;

// routing resource grid
Grid *rgrid;


struct tech  {

  int xdim, ydim;            // width, height of global routing grid

  double v_rsrc_track, h_rsrc_track;     // vertical and horizontal routing resources per track
  double v_rsrc, h_rsrc;     // vertical and horizontal routing resources
  double v_limit, h_limit;   // vertical and horizontal limits

  int offset_x, offset_y;   // convert so ggrid starts at 0,0
  int rgrid_x, rgrid_y;     // routing grid
  int ggrid_x, ggrid_y;     // routes per global route grid

  int grid_x, grid_y;       // convert millimicrons to global route grid

  int units;                // 1000 == milli microns

  int left_size, right_size, top_size, bottom_size;
                            // number of usable grids in respective edge ggrids

  double res_mult_x, res_mult_y;  // multiply by resource grid to find best

  int num_nets, num_segments;   // for stats

  int pin_unplaced, cell_unplaced; // for warning
};

struct tech tech;



// add a pair of points to the grid, computing probabilities
// can add or subtract

#define ADD 1
#define SUBTRACT -1

// If pt1_status is ROUTE_START then add/subtract probabilities for it.
// Otherwise, assume that it was done by the previous steiner box.

#define ROUTE_START 1
#define ROUTE_CONT 0

// Adds/subtract the probabilities for routes with either 1 or 2 turns only.
// Reduced since probabilities only account for 1 or 2 turn.

int 
add_prob_reduced (pt1, pt2, function, pt1_status)
  Point *pt1, *pt2;
  int function, pt1_status;
{

  int x1, x2, y1, y2;
  int x,y,i,j;

  int dx = abs(pt2->x - pt1->x);
  int dy = abs(pt2->y - pt1->y);
  int denom = dx + dy;
  double basis = 1.0/denom;

  //printf ("add box --> %d,%d to %d,%d (%d)\n",pt1->x,pt1->y,pt2->x,pt2->y, pt1_status);

  // order points so x2 >= x1.

  if ( pt1->x > pt2->x ) {
    // swap points
    x2 = pt1->x;
    x1 = pt2->x;

    y2 = pt1->y;
    y1 = pt2->y;

  } else {
    x1 = pt1->x;
    x2 = pt2->x;

    y1 = pt1->y;
    y2 = pt2->y;
  }

  // note: percentages are not exact but very close to correct.

  if ( x1 == x2 ) {
    // vertical line, special case
    int xm1 = x1-1;
    int xp1 = x1+1;
    int xm2 = x1-2;
    int xp2 = x1+2;

    double l_inv = function * 0.25 / abs(y2 - y1);

    // order y points
    int ymax = max ( y1, y2 );
    int ymin = min ( y1, y2 );

    // start/end
    if (pt1_status == ROUTE_START) {
      pgrid[twod(pt1->x,pt1->y)].h += BEF * function - 2 * l_inv;
      pgrid[twod(pt1->x,pt1->y)].v += BEF * function - 0.4 * function;
    } else {
      pgrid[twod(pt1->x,pt1->y)].v -= 0.4 * function;
    }

    pgrid[twod(pt2->x,pt2->y)].h += BEF * function - 2 * l_inv;
    pgrid[twod(pt2->x,pt2->y)].v += BEF * function - 0.4 * function;

    // other
    // assure that we stay inside the grid
/* For jog of +-1
    if ( x1 == 0 ) {
      // special case, no grid below

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(x1,i)].v += 0.5 * function;
	pgrid[twod(xp1,i)].v += 0.5 * function;

	pgrid[twod(x1,i)].h += 2 * l_inv;
	pgrid[twod(xp1,i)].h += 2 * l_inv;
      }

    } else if ( xp1 == tech.xdim ) {
      // special case, no grid above

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(xm1,i)].v += 0.5 * function;
	pgrid[twod(x1,i)].v += 0.5 * function;

	pgrid[twod(xm1,i)].h += 2 * l_inv;
	pgrid[twod(x1,i)].h += 2 * l_inv;
      }

    } else {
      // normal case

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(xm1,i)].v += 0.25 * function;
	pgrid[twod(x1,i)].v += 0.5 * function;
	pgrid[twod(xp1,i)].v += 0.25 * function;

	pgrid[twod(xm1,i)].h += 1 * l_inv;
	pgrid[twod(x1,i)].h += 2 * l_inv;
	pgrid[twod(xp1,i)].h += 1 * l_inv;
      }
    }
*/
    // Allows jogs of up to +/- 2 grids
    // NOTE: breaks if less than 3 grids wide

    if ( x1 == 0 ) {
      // special case, no grid left

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(x1,i)].v += 0.4 * function;
	pgrid[twod(xp1,i)].v += 0.4 * function;
	pgrid[twod(xp2,i)].v += 0.2 * function;

	pgrid[twod(x1,i)].h += 2 * l_inv;
	pgrid[twod(xp1,i)].h += 2 * l_inv;
	pgrid[twod(xp2,i)].h += l_inv;
      }

    } else if ( x1 == 1 ) {

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(xm1,i)].v += 0.3 * function;
	pgrid[twod(x1,i)].v += 0.4 * function;
	pgrid[twod(xp1,i)].v += 0.2 * function;
	pgrid[twod(xp2,i)].v += 0.1 * function;

	pgrid[twod(xm1,i)].h += l_inv;
	pgrid[twod(x1,i)].h += 2 * l_inv;
	pgrid[twod(xp1,i)].h += l_inv;
	pgrid[twod(xp2,i)].h += l_inv;
      }

    } else if ( xp1 == tech.xdim ) {
      // special case, no grid right

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(xm2,i)].v += 0.2 * function;
	pgrid[twod(xm1,i)].v += 0.4 * function;
	pgrid[twod(x1,i)].v += 0.4 * function;

	pgrid[twod(xm2,i)].h += l_inv;
	pgrid[twod(xm1,i)].h += 2 * l_inv;
	pgrid[twod(x1,i)].h += 2 * l_inv;
      }

    } else if ( xp2 == tech.xdim ) {
      // special case, no grid right

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(xm2,i)].v += 0.1 * function;
	pgrid[twod(xm1,i)].v += 0.2 * function;
	pgrid[twod(x1,i)].v += 0.4 * function;
	pgrid[twod(xp1,i)].v += 0.3 * function;

	pgrid[twod(xm2,i)].h += l_inv;
	pgrid[twod(xm1,i)].h += l_inv;
	pgrid[twod(x1,i)].h += 2 * l_inv;
	pgrid[twod(xp1,i)].h += l_inv;
      }

    } else {
      // normal case

      for (i = ymin ; i <= ymax ; i++) {
	pgrid[twod(xm2,i)].v += 0.1 * function;
	pgrid[twod(xm1,i)].v += 0.2 * function;
	pgrid[twod(x1,i)].v += 0.4 * function;
	pgrid[twod(xp1,i)].v += 0.2 * function;
	pgrid[twod(xp2,i)].v += 0.1 * function;

	pgrid[twod(xm2,i)].h += l_inv;
	pgrid[twod(xm1,i)].h += 2 * l_inv;
	pgrid[twod(x1,i)].h += 2 * l_inv;
	pgrid[twod(xp1,i)].h += 2 * l_inv;
	pgrid[twod(xp2,i)].h += l_inv;
      }
    }

  } else if ( y1 == y2 ) {
    // horizontal line, special case
    int ym1 = y1-1;
    int yp1 = y1+1;
    int ym2 = y1-2;
    int yp2 = y1+2;

    double l_inv = function * 0.25 / (x2 - x1);

    // start/end
    if (pt1_status == ROUTE_START) {
      pgrid[twod(pt1->x,pt1->y)].v += BEF * function - 2 * l_inv;
      pgrid[twod(pt1->x,pt1->y)].h += BEF * function - 0.4 * function;
    } else {
      pgrid[twod(pt1->x,pt1->y)].h -= 0.4 * function;
    }

    pgrid[twod(pt2->x,pt2->y)].v += BEF * function - 2 * l_inv;
    pgrid[twod(pt2->x,pt2->y)].h += BEF * function - 0.4 * function;

    // other
    // assure that we stay inside the grid
/* For jog of +-1
    if ( y1 == 0 ) {
      // special case, no grid below

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,y1)].h += 0.5 * function;
	pgrid[twod(i,yp1)].h += 0.5 * function;

	pgrid[twod(i,y1)].v += 2 * l_inv;
	pgrid[twod(i,yp1)].v += 2 * l_inv;
      }

    } else if ( yp1 == tech.ydim ) {
      // special case, no grid above

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,ym1)].h += 0.5 * function;
	pgrid[twod(i,y1)].h += 0.5 * function;

	pgrid[twod(i,ym1)].v += 2 * l_inv;
	pgrid[twod(i,y1)].v += 2 * l_inv;
      }

    } else {
      // normal case

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,ym1)].h += 0.25 * function;
	pgrid[twod(i,y1)].h += 0.5 * function;
	pgrid[twod(i,yp1)].h += 0.25 * function;

	pgrid[twod(i,ym1)].v += 1 * l_inv;
	pgrid[twod(i,y1)].v += 2 * l_inv;
	pgrid[twod(i,yp1)].v += 1 * l_inv;
      }
    }
*/

    // Allows jogs of up to +/- 2 grids
    // NOTE: breaks if less than 3 grids tall

    if ( y1 == 0 ) {
      // special case, no grid below

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,y1)].h += 0.4 * function;
	pgrid[twod(i,yp1)].h += 0.4 * function;
	pgrid[twod(i,yp2)].h += 0.2 * function;

	pgrid[twod(i,y1)].v += 2 * l_inv;
	pgrid[twod(i,yp1)].v += 2 * l_inv;
	pgrid[twod(i,yp2)].v += l_inv;
      }

    } else if ( y1 == 1 ) {

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,ym1)].h += 0.3 * function;
	pgrid[twod(i,y1)].h += 0.4 * function;
	pgrid[twod(i,yp1)].h += 0.2 * function;
	pgrid[twod(i,yp2)].h += 0.1 * function;

	pgrid[twod(i,ym1)].v += l_inv;
	pgrid[twod(i,y1)].v += 2 * l_inv;
	pgrid[twod(i,yp1)].v += l_inv;
	pgrid[twod(i,yp2)].v += l_inv;
      }

    } else if ( yp1 == tech.ydim ) {
      // special case, no grid above

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,ym2)].h += 0.2 * function;
	pgrid[twod(i,ym1)].h += 0.4 * function;
	pgrid[twod(i,y1)].h += 0.4 * function;

	pgrid[twod(i,ym2)].v += l_inv;
	pgrid[twod(i,ym1)].v += 2 * l_inv;
	pgrid[twod(i,y1)].v += 2 * l_inv;
      }

    } else if ( yp2 == tech.ydim ) {
      // special case, no grid above

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,ym2)].h += 0.1 * function;
	pgrid[twod(i,ym1)].h += 0.2 * function;
	pgrid[twod(i,y1)].h += 0.4 * function;
	pgrid[twod(i,yp1)].h += 0.3 * function;

	pgrid[twod(i,ym2)].v += l_inv;
	pgrid[twod(i,ym1)].v += l_inv;
	pgrid[twod(i,y1)].v += 2 * l_inv;
	pgrid[twod(i,yp1)].v += l_inv;
      }

    } else {
      // normal case

      for (i = x1 ; i <= x2 ; i++) {
	pgrid[twod(i,ym2)].h += 0.1 * function;
	pgrid[twod(i,ym1)].h += 0.2 * function;
	pgrid[twod(i,y1)].h += 0.4 * function;
	pgrid[twod(i,yp1)].h += 0.2 * function;
	pgrid[twod(i,yp2)].h += 0.1 * function;

	pgrid[twod(i,ym2)].v += l_inv;
	pgrid[twod(i,ym1)].v += 2 * l_inv;
	pgrid[twod(i,y1)].v += 2 * l_inv;
	pgrid[twod(i,yp1)].v += 2 * l_inv;
	pgrid[twod(i,yp2)].v += l_inv;
      }
    }

  } else {
    // box, NOT a line

    basis *= function;

    //  printf("function = %d, basis = %g\n",function,basis);

    // begin/end
    if (pt1_status == ROUTE_START) {
      pgrid[twod(pt1->x,pt1->y)].h += BEF * function;
      pgrid[twod(pt1->x,pt1->y)].v += BEF * function;
    }

    pgrid[twod(pt2->x,pt2->y)].h += BEF * function;
    pgrid[twod(pt2->x,pt2->y)].v += BEF * function;

    // corners
    pgrid[twod(pt1->x,pt2->y)].h += basis;
    pgrid[twod(pt1->x,pt2->y)].v += basis;
    pgrid[twod(pt2->x,pt1->y)].h += basis;
    pgrid[twod(pt2->x,pt1->y)].v += basis;

    for (i = x1 + 1 ; i < x2 ; i++) {

      // top and bottom edge
      pgrid[twod(i,pt1->y)].h += (x2-i+1)*basis;
      pgrid[twod(i,pt1->y)].v += basis;
      pgrid[twod(i,pt2->y)].h += (i-x1+1)*basis;
      pgrid[twod(i,pt2->y)].v += basis;

      // soft, juicy middle
      if (y2 > y1) {
	for (j = y1 + 1 ; j < y2 ; j++) {
	  pgrid[twod(i,j)].h += basis;
	  pgrid[twod(i,j)].v += basis;
	}
      } else {
	for (j = y2 + 1 ; j < y1 ; j++) {
	  pgrid[twod(i,j)].h += basis;
	  pgrid[twod(i,j)].v += basis;
	}
      }
    }

    // right and left edge
    if (y2 > y1) {
      for (j = y1 + 1 ; j < y2 ; j++) {
	pgrid[twod(pt1->x,j)].h += basis;
	pgrid[twod(pt1->x,j)].v += (y2-j+1)*basis;
	pgrid[twod(pt2->x,j)].h += basis;
	pgrid[twod(pt2->x,j)].v += (j-y1+1)*basis;
      }
    } else {
      for (j = y2 + 1 ; j < y1 ; j++) {
	pgrid[twod(pt1->x,j)].h += basis;
	pgrid[twod(pt1->x,j)].v += (j-y2+1)*basis;
	pgrid[twod(pt2->x,j)].h += basis;
	pgrid[twod(pt2->x,j)].v += (y1-j+1)*basis;
      }
    }
  }
}


// Only looks for 1 turn and 2 turn routes.  If it can't find either, punts.
// Looks for routes starting horizontal first, only.
// Just looks for a route that is less that limits, not the best one.

int 
route_box_h (pt1, pt2, pt1_status)

  Point *pt1, *pt2;
  int pt1_status;
{
  int x1_i, y1_i, x2_i, y2_i;
  int x1_iv, x2_iv, ok;
  int i, j, routable, xdir, ydir;
  
  int x1 = pt1->x;
  int y1 = pt1->y;
  int x2 = pt2->x;
  int y2 = pt2->y;

  xdir = x1 < x2 ? 1 : -1;

//printf("h routing %d %d --> %d %d\n", x1, y1, x2, y2);

  if ( y1 == y2 ) {
    // horizontal route only
    // Can route up/down one or two.

    for (x1_i = x1 + xdir ; xdir > 0 ? x1_i < x2 : x1_i > x2 ; x1_i += xdir) {
      if (pgrid[twod(x1_i,y1)].h >= tech.h_limit) {
	// blocked from going further
	break;
      }
    }

    if ( x1_i == x2 ) {
      // made it horizontal only

      // now eliminate probabilities since we routed it
      add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

      // add 1's in since it is no longer a probability
      for (j = x1 + xdir ; xdir > 0 ? j < x2 : j > x2 ; j += xdir) {    
	pgrid[twod(j,y1)].h += 1.0;	
      }

      // special case for endpoints
      if ( pt1_status == ROUTE_START ) {
	pgrid[twod(x1,y1)].h += BEF;	
	pgrid[twod(x1,y1)].v += BEF;	
      }

      pgrid[twod(x2,y2)].h += BEF;	
      pgrid[twod(x2,y2)].v += BEF;	
      
      //printf("\t> %d -> %d  (%d)\n", x1, x2, y1);

      return SUCCEED;

    } else {
      int dy;

      // don't allow jogging until limit larger -- special case
      if ( tech.h_limit < 0.75 ) {
	return FAIL;
      }

      // check if can make it by jogging up/down 1
      x1_i -= xdir;

      for (x2_i = x2-xdir ; xdir > 0 ? x2_i > x1 : x2_i < x1 ; x2_i -= xdir) {
	if (pgrid[twod(x2_i,y2)].h >= tech.h_limit) {
	  // blocked from going further
	  break;
	}
      }
      x2_i += xdir;

/*
      //DEBUG
      if ( x2_i - x1_i < 5 && x2 - x2_i + x1_i - x1 > 2) {
	printf("skip short %d ^ %d -> %d v %d (%d)\n", x1, x1_i, x2_i, x2, y1);

	return FAIL;
      }
*/

      for (dy = -1 ; dy < 2 ; dy += 2) {
	int yy = y1 + dy;

	if ( yy < 0 || yy >= tech.ydim ) {
	  // outside of grid
	  continue;
	}

	// check vertical resource for jog, if not, backup one.
	ok = 0;
	for (x1_iv = x1_i ; xdir > 0 ? x1_iv >= x1 : x1_iv <= x1 ; x1_iv -= xdir) {
	  if (pgrid[twod(x1_iv,y1)].v < tech.v_limit &&
	      pgrid[twod(x1_iv,yy)].v < tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  //printf ("No Vertical resource x1: %d (%d) %d %d %g %g\n", x1, x2, x1_i, x1_iv, pgrid[twod(x1_iv,y1)].v, pgrid[twod(x1_iv,yy)].v);
	  continue;
	}

	ok = 0;
	for (x2_iv = x2_i ; xdir > 0 ? x2_iv <= x2 : x2_iv >= x2 ; x2_iv += xdir) {
	  if (pgrid[twod(x2_iv,y1)].v < tech.v_limit &&
	      pgrid[twod(x2_iv,yy)].v < tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  //printf ("No Vertical resource x2: %d %d %d %g %g\n", x2, x2_i, x2_iv, pgrid[twod(x2_iv,y1)].v, pgrid[twod(x2_iv,yy)].v);
	  continue;
	}

	for (j = x1_iv ; xdir > 0 ? j < x2_iv : j > x2_iv ; j += xdir) {
	  //printf("\t\t%g >= %g (%d %d)\n", pgrid[twod(j,yy)].h, tech.h_limit, j, yy);
	  if (pgrid[twod(j,yy)].h >= tech.h_limit) {
	    //printf("\t\tfail\n");
	    break;
	  }
	}

	if ( j != x2_iv ) {
	  // this jog failed
	  continue;
	}

	// jog worked, route it
	//printf("\t%d ^ %d -> %d v %d (%d -> %d)\n", x1, x1_iv, x2_iv, x2, y1, yy);

	// now eliminate probabilities since we routed it
	add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

	// add 1's in since it is no longer a probability
	for (j = x1 + xdir ; xdir > 0 ? j <= x1_iv : j >= x1_iv ; j += xdir) {    
	  pgrid[twod(j,y1)].h += 1.0;	
	}

	for (j = x2_iv ; xdir > 0 ? j < x2 : j > x2 ; j += xdir) {    
	  pgrid[twod(j,y1)].h += 1.0;	
	}

	// jog
	pgrid[twod(x1_iv,y1)].v += BEF;	
	pgrid[twod(x1_iv,yy)].v += BEF;
	pgrid[twod(x2_iv,y1)].v += BEF;	
	pgrid[twod(x2_iv,yy)].v += BEF;

	for (j = x1_iv ; xdir > 0 ? j <= x2_iv : j >= x2_iv ; j += xdir) {    
	  pgrid[twod(j,yy)].h += 1.0;	
	}

	// corners
	pgrid[twod(x1_iv,yy)].h += BEF - 1.0;	
	pgrid[twod(x2_iv,yy)].h += BEF - 1.0;	
	if ( x1_iv != x1 ) {
	  pgrid[twod(x1_iv,y1)].h += BEF - 1.0;	
	}
	if ( x2_iv != x2 ) {
	  pgrid[twod(x2_iv,y1)].h += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  pgrid[twod(x1,y1)].h += BEF;	
	  if ( x1_iv != x1 ) {
	    pgrid[twod(x1,y1)].v += BEF;	
	  } else {
	    //pgrid[twod(x1,y1)].v += BEF - 1.0;	
	  }
	}

	pgrid[twod(x2,y2)].h += BEF;	
	if ( x2_iv != x2 ) {
	  pgrid[twod(x2,y2)].v += BEF;	
	} else {
	  //pgrid[twod(x2,y2)].v += BEF - 1.0;	
	}
      
	return SUCCEED;
      }

      // check if can make it by jogging up/down 2

      for (dy = -1 ; dy < 2 ; dy += 2) {
	int yy = y1 + dy;
	int yy2 = yy + dy;

	if ( yy < 0 || yy2 < 0 || yy >= tech.ydim || yy2 >= tech.ydim ) {
	  // outside of grid
	  continue;
	}

	// check vertical resource for jog, if not, backup one.
	ok = 0;
	for (x1_iv = x1_i ; xdir > 0 ? x1_iv >= x1 : x1_iv <= x1 ; x1_iv -= xdir) {
	  if ( (x1_iv == x1 || pgrid[twod(x1_iv,y1)].v < tech.v_limit) &&
	      pgrid[twod(x1_iv,yy)].v < tech.v_limit &&
	      pgrid[twod(x1_iv,yy2)].v < tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  x1_iv += xdir;
	  //printf ("No Vertical resource x1: %d %d %d %g %g %g >= %g\n", x1, x1_i, x1_iv, pgrid[twod(x1_iv,y1)].v, pgrid[twod(x1_iv,yy)].v, pgrid[twod(x1_iv,yy2)].v, tech.v_limit);
	  continue;
	}

	ok = 0;
	for (x2_iv = x2_i ; xdir > 0 ? x2_iv <= x2 : x2_iv >= x2 ; x2_iv += xdir) {
	  if ( (x2_iv == x2 || pgrid[twod(x2_iv,y1)].v < tech.v_limit) &&
	      pgrid[twod(x2_iv,yy)].v < tech.v_limit &&
	      pgrid[twod(x2_iv,yy2)].v < tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  x2_iv -= xdir;
	  //printf ("No Vertical resource x2: %d %d %d %g %g %g >= %g\n", x2, x2_i, x2_iv, pgrid[twod(x2_iv,y1)].v, pgrid[twod(x2_iv,yy)].v, pgrid[twod(x2_iv,yy2)].v, tech.v_limit);
	  continue;
	}

	for (j = x1_iv ; xdir > 0 ? j < x2_iv : j > x2_iv ; j += xdir) {
	  if (pgrid[twod(j,yy2)].h >= tech.h_limit) {
	    //printf("\t\tfail\n");
	    break;
	  }
	}

	if ( j != x2_iv ) {
	  // this jog failed
	  continue;
	}

	// jog worked, route it
	//printf("\t%d ^ %d -> %d v %d (%d -> %d)\n", x1, x1_iv, x2_iv, x2, y1, yy2);

	// now eliminate probabilities since we routed it
	add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

	// add 1's in since it is no longer a probability
	for (j = x1 + xdir ; xdir > 0 ? j <= x1_iv : j >= x1_iv ; j += xdir) {    
	  pgrid[twod(j,y1)].h += 1.0;	
	}

	for (j = x2_iv ; xdir > 0 ? j < x2 : j > x2 ; j += xdir) {    
	  pgrid[twod(j,y1)].h += 1.0;	
	}

	// jog
	pgrid[twod(x1_iv,y1)].v += BEF;	
	pgrid[twod(x1_iv,yy)].v += 1.0;
	pgrid[twod(x1_iv,yy2)].v += BEF;
	pgrid[twod(x2_iv,y1)].v += BEF;	
	pgrid[twod(x2_iv,yy)].v += 1.0;
	pgrid[twod(x2_iv,yy2)].v += BEF;

	for (j = x1_iv ; xdir > 0 ? j <= x2_iv : j >= x2_iv ; j += xdir) {    
	  pgrid[twod(j,yy2)].h += 1.0;	
	}

	// corners
	pgrid[twod(x1_iv,yy2)].h += BEF - 1.0;	
	pgrid[twod(x2_iv,yy2)].h += BEF - 1.0;	
	if ( x1_iv != x1 ) {
	  pgrid[twod(x1_iv,y1)].h += BEF - 1.0;	
	}
	if ( x2_iv != x2 ) {
	  pgrid[twod(x2_iv,y1)].h += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  pgrid[twod(x1,y1)].h += BEF;	
	  if ( x1_iv != x1 ) {
	    pgrid[twod(x1,y1)].v += BEF;	
	  } else {
	    //pgrid[twod(x1,y1)].v += BEF - 1.0;	
	  }
	}

	pgrid[twod(x2,y2)].h += BEF;	
	if ( x2_iv != x2 ) {
	  pgrid[twod(x2,y2)].v += BEF;	
	} else {
	  //pgrid[twod(x2,y2)].v += BEF - 1.0;	
	}
      
	return SUCCEED;
      }
    }

    return FAIL;
  }

  if ( x1 == x2 ) {
    // leave for vertical router
    return FAIL;
  }

  //printf("h routing %d %d --> %d %d\n", x1, y1, x2, y2);

  // Ignores limits from beginning/ending

  // look first for the horizontals
  for (x1_i = x1 + xdir ; xdir > 0 ? x1_i <= x2 : x1_i >= x2 ; x1_i += xdir) {  
    // should really check that it can add 1-prob to this
    // printf("%g >= %g  (%d %d)\n",pgrid[twod(x1_i,y1)].h, tech.h_limit, x1_i, y1);

    if (pgrid[twod(x1_i,y1)].h >= tech.h_limit) {
      // blocked from going further
      //printf("blocked a\n");
      break;
    }
  }
  x1_i -= xdir;

  for (x2_i = x2 - xdir ; xdir > 0 ? x2_i >= x1 : x2_i <= x1 ; x2_i -= xdir) {  
    //printf("%g >= %g  (%d %d)\n",pgrid[twod(x2_i,y2)].h, tech.h_limit, x2_i, y2);
    if (pgrid[twod(x2_i,y2)].h >= tech.h_limit) {
      // blocked from going further
      //printf("blocked b\n");
      break;
    }
  }
  x2_i += xdir;

  // printf("(%d) xxxxx %d --> %d\n", xdir, x1_i, x2_i);

  if (xdir > 0 ? x2_i > x1_i : x2_i < x1_i) {
    // no overlap, can't route
    return FAIL;
  }

  // now look for the verticals
  for (i = x2_i ; xdir > 0 ? i <= x1_i : i >= x1_i ; i += xdir) {    
    routable = SUCCEED;

    if (y1 < y2) {
      for (j = y1 ; j <= y2 ; j++) {  
	if (pgrid[twod(i,j)].v >= tech.v_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    } else {
      for (j = y2 ; j <= y1 ; j++) {  
	if (pgrid[twod(i,j)].v >= tech.v_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    }

    if (routable == SUCCEED) {
      // got one -- not necessarily the best
      //printf("h> x1=%d,i=%d,x2=%d,y1=%d,y2=%d\n",x1,i,x2,y1,y2);

      // now eliminate probabilities since we routed it
      add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

      // add 1's in since it is no longer a probability
      for (j = x1 ; xdir > 0 ? j <= i : j >= i ; j += xdir) {    
	pgrid[twod(j,y1)].h += 1.0;	
      }

      if (y1 < y2) {
	for (j = y1 ; j <= y2 ; j++) {  
	  pgrid[twod(i,j)].v += 1.0;
	}
      } else {
	for (j = y2 ; j <= y1 ; j++) {  
	  pgrid[twod(i,j)].v += 1.0;
	}
      }

      for (j = i ; xdir > 0 ? j <= x2 : j >= x2 ; j += xdir) {    
	pgrid[twod(j,y2)].h += 1.0;	
      }

      // special case for corners
      if ( pt1_status == ROUTE_START ) {
	pgrid[twod(x1,y1)].h += BEF - 1.0;	

	if (i != x1) {
	  pgrid[twod(x1,y1)].v += BEF;	
	} else {
	  pgrid[twod(x1,y1)].v += BEF - 1.0;	
	}

      } else {
	pgrid[twod(x1,y1)].h -= 1.0;	
      }

      if (i != x1) {
	pgrid[twod(i,y1)].h += BEF - 1.0;	
	pgrid[twod(i,y1)].v += BEF - 1.0;	
      }

      pgrid[twod(x2,y2)].h += BEF - 1.0;	

      if (i != x2) {
	pgrid[twod(x2,y2)].v += BEF;	

	pgrid[twod(i,y2)].h += BEF - 1.0;	
	pgrid[twod(i,y2)].v += BEF - 1.0;	

      } else {
	pgrid[twod(x2,y2)].v += BEF - 1.0;	
      }

      // TODO: save route somewhere

      return SUCCEED;
    }
  }

  return FAIL;
}


// same as route_box_h but tries a vertical route first

int 
route_box_v (pt1, pt2, pt1_status)

  Point *pt1, *pt2;
  int pt1_status;
{
  int x1_i, y1_i, x2_i, y2_i;
  int y1_iv, y2_iv, ok;
  int i, j, routable, xdir, ydir;

  int x1 = pt1->x;
  int y1 = pt1->y;
  int x2 = pt2->x;
  int y2 = pt2->y;

  ydir = y1 < y2 ? 1 : -1;

  if ( x1 == x2 ) {
    // vertical route only
    // Can route up/down one or two.

    for (y1_i = y1 + ydir ; ydir > 0 ? y1_i < y2 : y1_i > y2 ; y1_i += ydir) {
      if (pgrid[twod(x1,y1_i)].v >= tech.v_limit) {
	// blocked from going further
	break;
      }
    }

    if ( y1_i == y2 ) {
      // made it vertical only

      // now eliminate probabilities since we routed it
      add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

      // add 1's in since it is no longer a probability
      for (j = y1 + ydir ; ydir > 0 ? j < y2 : j > y2 ; j += ydir) {    
	pgrid[twod(x1,j)].v += 1.0;	
      }

      // special case for endpoints
      if ( pt1_status == ROUTE_START ) {
	pgrid[twod(x1,y1)].h += BEF;	
	pgrid[twod(x1,y1)].v += BEF;	
      }

      pgrid[twod(x2,y2)].h += BEF;	
      pgrid[twod(x2,y2)].v += BEF;	
      
      //printf("\t> %d -> %d  (%d)\n", y1, y2, x1);

      return SUCCEED;

    } else {
      int dx;

      // don't allow jogging until limit larger -- special case
      if ( tech.v_limit < 0.75 ) {
	return FAIL;
      }

      // check if can make it by jogging left/right 1
      y1_i -= ydir;

      for (y2_i = y2-ydir ; ydir > 0 ? y2_i > y1 : y2_i < y1 ; y2_i -= ydir) {
	if (pgrid[twod(x2,y2_i)].v >= tech.v_limit) {
	  // blocked from going further
	  break;
	}
      }
      y2_i += ydir;

      for (dx = -1 ; dx < 2 ; dx += 2) {
	int xx = x1 + dx;

	if ( xx < 0 || xx >= tech.xdim ) {
	  // outside of grid
	  continue;
	}

	// check vertical resource for jog, if not, backup one.
	ok = 0;
	for (y1_iv = y1_i ; ydir > 0 ? y1_iv >= y1 : y1_iv <= y1 ; y1_iv -= ydir) {
	  if (pgrid[twod(x1,y1_iv)].h < tech.h_limit &&
	      pgrid[twod(xx,y1_iv)].h < tech.h_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  continue;
	}

	ok = 0;
	for (y2_iv = y2_i ; ydir > 0 ? y2_iv <= y2 : y2_iv >= y2 ; y2_iv += ydir) {
	  if (pgrid[twod(x2,y1_iv)].h < tech.h_limit &&
	      pgrid[twod(xx,y1_iv)].h < tech.h_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  continue;
	}

	for (j = y1_iv ; ydir > 0 ? j < y2_iv : j > y2_iv ; j += ydir) {
	  if (pgrid[twod(xx,j)].v >= tech.v_limit) {
	    break;
	  }
	}

	if ( j != y2_iv ) {
	  // this jog failed
	  continue;
	}

	// jog worked, route it

	// now eliminate probabilities since we routed it
	add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

	// add 1's in since it is no longer a probability
	for (j = y1 + ydir ; ydir > 0 ? j <= y1_iv : j >= y1_iv ; j += ydir) {    
	  pgrid[twod(x1,j)].v += 1.0;	
	}

	for (j = y2_iv ; ydir > 0 ? j < y2 : j > y2 ; j += ydir) {    
	  pgrid[twod(x1,j)].v += 1.0;	
	}

	// jog
	pgrid[twod(x1,y1_iv)].h += BEF;	
	pgrid[twod(xx,y1_iv)].h += BEF;
	pgrid[twod(x1,y2_iv)].h += BEF;	
	pgrid[twod(xx,y2_iv)].h += BEF;

	for (j = y1_iv ; ydir > 0 ? j <= y2_iv : j >= y2_iv ; j += ydir) {    
	  pgrid[twod(xx,j)].v += 1.0;	
	}

	// corners
	pgrid[twod(xx,y1_iv)].v += BEF - 1.0;	
	pgrid[twod(xx,y2_iv)].v += BEF - 1.0;	
	if ( y1_iv != y1 ) {
	  pgrid[twod(x1,y1_iv)].v += BEF - 1.0;	
	}
	if ( y2_iv != y2 ) {
	  pgrid[twod(x1,y2_iv)].v += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  pgrid[twod(x1,y1)].v += BEF;	
	  if ( y1_iv != y1 ) {
	    pgrid[twod(x1,y1)].h += BEF;	
	  } else {
	    //pgrid[twod(x1,y1)].h += BEF - 1.0;	
	  }
	}

	pgrid[twod(x2,y2)].v += BEF;	
	if ( y2_iv != y2 ) {
	  pgrid[twod(x2,y2)].h += BEF;	
	} else {
	  //pgrid[twod(x2,y2)].h += BEF - 1.0;	
	}
      
	return SUCCEED;
      }

      // check if can make it by jogging left/right 2
      for (dx = -1 ; dx < 2 ; dx += 2) {
	int xx = x1 + dx;
	int xx2 = xx + dx;

	if ( xx < 0 || xx2 < 0 || xx >= tech.xdim || xx2 >= tech.xdim ) {
	  // outside of grid
	  continue;
	}

	// check horizontal resource for jog, if not, backup one.
	ok = 0;
	for (y1_iv = y1_i ; ydir > 0 ? y1_iv >= y1 : y1_iv <= y1 ; y1_iv -= ydir) {
	  if ( (y1_iv == y1 || pgrid[twod(x1,y1_iv)].h < tech.h_limit) &&
	       pgrid[twod(xx,y1_iv)].h < tech.h_limit &&
	       pgrid[twod(xx2,y1_iv)].h < tech.h_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  y1_iv += ydir;
	  continue;
	}

	ok = 0;
	for (y2_iv = y2_i ; ydir > 0 ? y2_iv <= y2 : y2_iv >= y2 ; y2_iv += ydir) {
	  if ( (y2_iv == y2 || pgrid[twod(x1,y2_iv)].h < tech.h_limit) &&
	       pgrid[twod(xx,y2_iv)].h < tech.h_limit &&
	       pgrid[twod(xx2,y2_iv)].h < tech.h_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  y2_iv -= ydir;
	  continue;
	}

	for (j = y1_iv ; ydir > 0 ? j < y2_iv : j > y2_iv ; j += ydir) {
	  if (pgrid[twod(xx2,j)].v >= tech.v_limit) {
	    //printf("\t\tfail\n");
	    break;
	  }
	}

	if ( j != y2_iv ) {
	  // this jog failed
	  continue;
	}

	// jog worked, route it

	// now eliminate probabilities since we routed it
	add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

	// add 1's in since it is no longer a probability
	for (j = y1+ydir ; ydir > 0 ? j <= y1_iv : j >= y1_iv ; j += ydir) {    
	  pgrid[twod(x1,j)].v += 1.0;	
	}

	for (j = y2_iv ; ydir > 0 ? j < y2 : j > y2 ; j += ydir) {    
	  pgrid[twod(x1,j)].v += 1.0;	
	}

	// jog
	pgrid[twod(x1,y1_iv)].h += BEF;	
	pgrid[twod(xx,y1_iv)].h += 1.0;
	pgrid[twod(xx2,y1_iv)].h += BEF;
	pgrid[twod(x1,y2_iv)].h += BEF;	
	pgrid[twod(xx,y2_iv)].h += 1.0;
	pgrid[twod(xx2,y2_iv)].h += BEF;

	for (j = y1_iv ; ydir > 0 ? j <= y2_iv : j >= y2_iv ; j += ydir) {    
	  pgrid[twod(xx2,j)].v += 1.0;	
	}

	// corners
	pgrid[twod(xx2,y1_iv)].v += BEF - 1.0;	
	pgrid[twod(xx2,y2_iv)].v += BEF - 1.0;	
	if ( y1_iv != y1 ) {
	  pgrid[twod(x1,y1_iv)].v += BEF - 1.0;	
	}
	if ( y2_iv != y2 ) {
	  pgrid[twod(x1,y2_iv)].v += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  pgrid[twod(x1,y1)].v += BEF;	
	  if ( y1_iv != y1 ) {
	    pgrid[twod(x1,y1)].h += BEF;	
	  } else {
	    //pgrid[twod(x1,y1)].h += BEF - 1.0;	
	  }
	}

	pgrid[twod(x2,y2)].v += BEF;	
	if ( y2_iv != y2 ) {
	  pgrid[twod(x2,y2)].h += BEF;	
	} else {
	  //pgrid[twod(x2,y2)].h += BEF - 1.0;	
	}
      
	return SUCCEED;
      }
    }

    return FAIL;
  }

  // look first for the verticals
  for (y1_i = y1 + ydir ; ydir > 0 ? y1_i <= y2 : y1_i >= y2 ; y1_i += ydir) {  
    // should really check that it can add 1-prob to this
    if (pgrid[twod(x1,y1_i)].v >= tech.v_limit) {
      // blocked from going further
      break;
    }
  }
  y1_i -= ydir;

  for (y2_i = y2 - ydir ; ydir > 0 ? y2_i >= y1 : y2_i <= y1 ; y2_i -= ydir) {  
    if (pgrid[twod(x2,y2_i)].v >= tech.v_limit) {
      // blocked from going further
      break;
    }
  }
  y2_i += ydir;

  if (ydir > 0 ? y2_i > y1_i : y2_i < y1_i) {
    // no overlap, can't route
    return FAIL;
  }

// printf("yyyyy %d --> %d\n",y1_i,y2_i);

  // now look for the horizontals
  for (i = y2_i ; ydir > 0 ? i <= y1_i : i >= y1_i ; i += ydir) {    
    routable = SUCCEED;

    if (x1 < x2) {
      for (j = x1 ; j <= x2 ; j++) {  
	if (pgrid[twod(j,i)].h >= tech.h_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    } else {
      for (j = x2 ; j <= x1 ; j++) {  
	if (pgrid[twod(j,i)].h >= tech.h_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    }

    if (routable == SUCCEED) {
      // got one -- not necessarily the best

      // now eliminate probabilities since we routed it
      add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

      //printf("v> x1=%d,i=%d,x2=%d,y1=%d,y2=%d\n",x1,i,x2,y1,y2);

      // add 1's in since it is no longer a probability
      for (j = y1 ; ydir > 0 ? j <= i : j >= i ; j += ydir) {    
	pgrid[twod(x1,j)].v += 1.0;	
      }

      if (x1 < x2) {
	for (j = x1 ; j <= x2 ; j++) {  
	  pgrid[twod(j,i)].h += 1.0;
	}
      } else {
	for (j = x2 ; j <= x1 ; j++) {  
	  pgrid[twod(j,i)].h += 1.0;
	}
      }

      for (j = i ; ydir > 0 ? j <= y2 : j >= y2 ; j += ydir) {    
	pgrid[twod(x2,j)].v += 1.0;	
      }

      // special case for corners
      if ( pt1_status == ROUTE_START ) {
	if (i != y1) {
	  pgrid[twod(x1,y1)].h += BEF;
	} else {
	  pgrid[twod(x1,y1)].h += BEF - 1.0;
	}

	pgrid[twod(x1,y1)].v += BEF - 1.0;	

      } else {
	pgrid[twod(x1,y1)].v -= 1.0;	
      }

      if (i != y1) {
	pgrid[twod(x1,i)].h += BEF - 1.0;	
	pgrid[twod(x1,i)].v += BEF - 1.0;	
      }

      pgrid[twod(x2,y2)].v += BEF - 1.0;	

      if (i != y2) {
	pgrid[twod(x2,y2)].h += BEF;

	pgrid[twod(x2,i)].h += BEF - 1.0;	
	pgrid[twod(x2,i)].v += BEF - 1.0;	

      } else {
	pgrid[twod(x2,y2)].h += BEF - 1.0;
      }

      // TODO: save route somewhere

      return SUCCEED;
    }
  }

  return FAIL;
}



// nl setup
nl_design design;


/* Traverses every net in the design using nl, steiner routes it, and 
   then adds to prob. matrix.
 */

int preroute_design () 
{

  nl_idesign idesign;
  nl_walk_status preroute_net_walker ();

  int do_hierarchy = 1;
  int noassign = 1;
  int noconstant = 1;
  int noempty = 1;
  int onlyconstant = 0;

  idesign = nl_idesign_get_or_create (design, NULL);

  // calls command for each net
  nl_walk_nets (design, idesign, noassign, do_hierarchy, noconstant, noempty,
		onlyconstant, preroute_net_walker, NULL);
}


// process each net

nl_walk_status preroute_net_walker (inet_object, null_ptr)
     
     nl_object inet_object;
     int *null_ptr;
{

  nl_walk_status preroute_pin_walker ();

  int drivers = 1;
  int loads = 1;
  int fanios = 1;
  int do_hier = 1;
  int noassign = 1;

  nl_net net = nl_inet_net ( (nl_inet) inet_object );
  nl_idesign idesign = nl_inet_idesign ( (nl_inet) inet_object );

  int cmd = 1;

  Point pt1, pt2;
  int route_type = ROUTE_START;

  Segment *segment;
  SLink *slink;

  char *name1, *name2;

  // NOTE: not the hier name.  Only the local name
  char *net_name = nl_net_name (net);

  // don't really need name here.
  //printf("net = %s\n",net_name);
  steiner_begin_net (net_name);

  nl_walk_connected_pins (net, idesign, noassign, do_hier, drivers, loads,
			  fanios, preroute_pin_walker, NULL);

  // steiner route it, if cmd == 1 then route.
  while (steiner_get_route_seg(NULL, cmd, &(pt1.x), &(pt1.y), 
			       &(pt2.x), &(pt2.y), NULL, NULL) > 0) {

    //printf ("\t\t --> %d %d %d %d\n", pt1.x, pt1.y, pt2.x, pt2.y);
    //printf ("\t\t g --> %d %d %d %d\n", (int) x_adjust(pt1.x), (int) y_adjust(pt1.y), (int) x_adjust(pt2.x), (int) y_adjust(pt2.y));

    //    pt1.x = x_adjust(pt1.x);
    //    pt1.y = y_adjust(pt1.y);
    //    pt2.x = x_adjust(pt2.x);
    //    pt2.y = y_adjust(pt2.y);

    if ( pt1.x == pt2.x && pt1.y == pt2.y ) {
      
      // add route here since same grid
      pgrid[twod(pt1.x,pt1.y)].h += BEF;
      pgrid[twod(pt1.x,pt1.y)].v += BEF;

    } else {

      //printf ("\t\t e --> %d %d %d %d\n", pt1.x, pt1.y, pt2.x, pt2.y);

      // remember this segment for later routing
      segment = mem_malloc(sizeof(Segment));
      segment->pt1 = pt1;
      segment->pt2 = pt2;
      segment->pt1_status = route_type;
      segment->routed = FALSE;

      slink = mem_malloc(sizeof(SLink));      
      slink->segment = segment;
      slink->next = unrouted_list;
      unrouted_list = slink;

      // add to the probability grid
      add_prob_reduced (&pt1, &pt2, ADD, route_type);

      if ( route_type == ROUTE_START ) {
	tech.num_nets++;
#if DO_ROUTE_START
	route_type = ROUTE_CONT;
#endif
      }

      tech.num_segments++;
    }

    // so subsequent calls just return next segment
    cmd = 0;
  }

  return nl_walk_status_continue;
}


// process each pin in a given net

nl_walk_status preroute_pin_walker (pin_or_ipin, null_ptr)
     
     nl_object pin_or_ipin;
     int *null_ptr;
{
  int x, y, xg, yg;
  char dir, *name;
  char empty[] = "";

  // find type and coords of pin
  
  // for now, just get coords of cell pin is in
  nl_ipin ipin = (nl_ipin) pin_or_ipin;

  nl_direction direction = nl_ipin_direction (ipin);

  // iport or icell
  nl_idesign_object owner = nl_ipin_owner (ipin);

  nl_kind kind = nl_object_kind ( (nl_object) owner );
  
  if ( kind == nl_kind_iport ) {
    pnl_port pport;
    nl_port port = nl_iport_port ((nl_iport) owner);
    nl_port_attr_get_by_name ("pnl port", port, &pport);

    if ( pnl_port_has_location (pport) ) {
      pnl_port_get_location (pport, &x, &y);

    } else {
      // unplaced, ignore but remember how many we ignored
      tech.pin_unplaced += 1;

      //> printf ("\t\tskipped\n");
      return nl_walk_status_continue;
    }

    name = empty;

  } else {
    pnl_icell pcell;
    nl_pin pin = nl_ipin_pin (ipin);

    // get location of pin
    nl_icell_attr_get_by_name ("pnl icell", (nl_icell) owner, &pcell);

    if ( pnl_icell_has_location (pcell) ) {
      pnl_icell_get_pin_location (pcell, pin, &x, &y);

    } else {
      // unplaced, ignore but remember how many we ignored
      tech.cell_unplaced += 1;

      //> printf ("\t\tskipped\n");
      return nl_walk_status_continue;
    }

    // old way -- origin of cell
    //pnl_cell_get_location (pcell, &x, &y);

    name = nl_icell_name( (nl_icell) owner );
  }

  switch (direction) {
  case nl_direction_in: dir = 'I'; break;
  case nl_direction_out: dir = 'O'; break;
  case nl_direction_inout: dir = 'B'; break;
  default: dir = 'B';
  }

  //>printf ("\t%s %s --> %d, %d (%c)\n", name, nl_ipin_name(ipin), x, y, dir);

  // scaled x,y to ggrids
  xg = x_adjust(x);
  yg = y_adjust(y);

  if ( xg < 0 || xg >= tech.xdim || yg < 0 || yg >= tech.ydim ) {
    // error
    printf ("Error: %s is outside of routing grid (%d, %d), ignoring.\n",
	    nl_ipin_name(ipin), xg, yg);

  } else {
    // add to steiner route
    // NOTE: coords need to be integers
    // name is not hierarchical name but shouldn't matter except for dspf
    steiner_add_point(NULL, xg, yg, name, nl_ipin_name(ipin), dir);
  }

  return nl_walk_status_continue;
}


int route ()
{
  int route_int();

  //double mult[] = {0.001, 0.1, 0.2, 0.5, 1.0, 2.0, 10.0, 100.0};

  double mult[] = {0.01, 0.1, 0.3, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 5.0, 10.0, 100.0};
  int max_passes = 14;

  int pass;

  for ( pass = 0 ; pass < max_passes ; pass++ ) {

    tech.v_limit = tech.v_rsrc * mult[pass];
    tech.h_limit = tech.h_rsrc * mult[pass];

    //printf ("limits --> h=%g v=%g\n", tech.h_limit, tech.v_limit);

    if ( route_int (mult[pass]) ) {
      // done
      printf ("Route Completed in %d passes.\n", pass + 1);

      if ( tech.pin_unplaced > 0 || tech.cell_unplaced > 0 ) {
	printf ("Route WARNING: %d pins and %d cells unplaced (i.e., not included in route).\n", tech.pin_unplaced, tech.cell_unplaced);
      }

      break;
    }
  }
}


int route_int (mult)
     double mult;
{

  int h_route, v_route;

  int total = 0;
  int routed = 0;
  int routed_this_pass = 0;
  int total_this_pass = 0;

  Segment *segment;
  SLink *slink;

  // walk through all segments -- could remove routed
  for (slink = unrouted_list ; slink != NULL ; slink = slink->next) {
    segment = slink->segment;

    total++;

    if ( segment->routed ) {
      // already routed this
      routed++;

    } else {
      // not routed
      total_this_pass++;

      // try a horizontal first route
      h_route = route_box_h (&(segment->pt1), &(segment->pt2), segment->pt1_status);
      //h_route = FAIL;

      if ( h_route == FAIL ) {
	// try the vertical first route
	v_route = route_box_v (&(segment->pt1), &(segment->pt2), segment->pt1_status);
	//v_route = FAIL;
      } else {
	v_route = FAIL;
      }

      /*
      printf("%d %d --> %d %d ROUTED: h=%d, v=%d\n", segment->pt1.x, 
	     segment->pt1.y, segment->pt2.x, segment->pt2.y, h_route, v_route);
      */

      if ( h_route == SUCCEED || v_route == SUCCEED) {
	// success, mark this as routed
	segment->routed = 1;
	routed++;
	routed_this_pass++;

	//printf("%d %d --> (%d %d %d %d) ROUTED: h=%d, v=%d\n", abs(segment->pt2.x - segment->pt1.x), abs(segment->pt2.y - segment->pt1.y), segment->pt1.x, segment->pt1.y, segment->pt2.x, segment->pt2.y, h_route, v_route);

      }
    }

  }

  printf("Routed %d/%d segments this pass (%g), total routed %d/%d.\n",
    routed_this_pass, total_this_pass, mult, routed, total);
  //printf ("limits %g %g\n", tech.v_limit, tech.h_limit);

  if ( routed == total ) {
    // done
    return 1;

  } else {
    return 0;
  }
}


int show_grid (grid)
     Grid *grid;
{

  int i,j;

  if ( 1 || tech.xdim > 20 ) {

      if ( tech.ydim < 20 ) {
	// rotate
	printf("rotated-------------- horizontal -------------------------\n");
	for (j = 0 ; j < tech.xdim ; j++) {
	  for (i = 0; i < tech.ydim ; i++) {
	    if ( fabs(grid[twod(j,i)].h) < 0.01 ) {
	      printf("%5.2g ", 0.0);
	    } else {
	      printf("%5.2g ", grid[twod(j,i)].h);
	    }
	  } 
	  printf("\n");
	}

	printf("rotated-------------- vertical -------------------------\n");
	for (j = 0 ; j < tech.xdim ; j++) {
	  for (i = 0; i < tech.ydim ; i++) {
	    if ( fabs(grid[twod(j,i)].v) < 0.01 ) {
	      printf("%5.2g ", 0.0);
	    } else {
	      printf("%5.2g ", grid[twod(j,i)].v);
	    }
	  } 
	  printf("\n");
	}
      }

    // skip if big
    return;
  }

  printf("-------------- horizontal -------------------------\n");
  for (j = tech.ydim-1; j >= 0 ; j--) {
    for (i = 0; i < tech.xdim ; i++) {
      if ( fabs(grid[twod(i,j)].h) < 0.01 ) {
	printf("%5.2g ", 0.0);
      } else {
	printf("%5.2g ", grid[twod(i,j)].h);
      }
    } 
    printf("\n");
  }

  printf("-------------- vertical -------------------------\n");
  for (j = tech.ydim-1; j >= 0 ; j--) {
    for (i = 0; i < tech.xdim ; i++) {
      if ( fabs(grid[twod(i,j)].v) < 0.01 ) {
	printf("%5.2g ", 0.0);
      } else {
	printf("%5.2g ", grid[twod(i,j)].v);
      }
    } 
    printf("\n");
  }
}


// setup technology constraints

int init_tech ()
{

  // should read units line
  tech.units = 1000;

  tech.offset_x = 0;
  tech.offset_y = 0;

  // passed in.  global route grid size in routing grids
//  tech.ggrid_x = 10;
//  tech.ggrid_y = 10;

  // times number of layers
  tech.v_rsrc = tech.ggrid_x * tech.v_rsrc_track;
  tech.h_rsrc = tech.ggrid_y * tech.h_rsrc_track;

  // for stats
  tech.num_nets = 0;
  tech.num_segments = 0;
}


int init_die ()
{

  pnl_design pdesign;

  int x1, y1, x2, y2;
  int start, end, count;

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  if ( ! pnl_design_get_die_area (pdesign, &x1, &y1, &x2, &y2) ) {
    printf("No die area in def file.\n");
    return TCL_ERROR;
  }

  // printf ("\t\t diearea --> %d %d %d %d\n",x1,y1,x2,y2);

  // TODO: assumes only one x and one y for now
  pnl_design_for_all_x_tracks (pdesign, tracks) {

    // layers --> ar_size(pnl_tracks_layers (tracks));

    tech.rgrid_x = pnl_tracks_step (tracks);

    start = floor( 1.0 * pnl_tracks_start (tracks) / tech.rgrid_x );
    count = pnl_tracks_count(tracks) - 1;
    end = count + start;

    // offset in ggrids
    tech.offset_x = floor( 1.0*start / tech.ggrid_x );

    tech.xdim = end / tech.ggrid_x - tech.offset_x + 1;

    tech.left_size = ( tech.ggrid_x - start ) % tech.ggrid_x;
    tech.right_size = end % tech.ggrid_x;

    //printf ("%d %d -> %d  offset = %d, xdim = %d edges = %d, %d\n", start, count, end, tech.offset_x, tech.xdim, tech.left_size, tech.right_size);

  } pnl_end_for;

  pnl_design_for_all_y_tracks (pdesign, tracks) {

    // layers --> ar_size(pnl_tracks_layers (tracks));

    tech.rgrid_y = pnl_tracks_step (tracks);

    start = floor( 1.0 * pnl_tracks_start (tracks) / tech.rgrid_y );
    count = pnl_tracks_count(tracks) - 1;
    end = count + start;

    // offset in ggrids
    tech.offset_y = floor( 1.0*start / tech.ggrid_y );

    tech.ydim = end / tech.ggrid_y - tech.offset_y + 1;

    tech.bottom_size = ( tech.ggrid_y - start ) % tech.ggrid_y;
    tech.top_size = end % tech.ggrid_y;

    //printf ("%d %d -> %d  offset = %d, ydim = %d, edges = %d, %d\n", start, count, end, tech.offset_y, tech.ydim, tech.bottom_size, tech.top_size);

  } pnl_end_for;

  // multiplier to get global grids from millimicrons
  tech.grid_x = tech.rgrid_x * tech.ggrid_x;
  tech.grid_y = tech.rgrid_y * tech.ggrid_y;

  // set counters
  tech.pin_unplaced = 0;
  tech.cell_unplaced = 0;
}


// initialize the grid.

int
init_grid (grid)
     Grid *grid;
{
  int i,j;

  // initialize
  for (i = 0; i < tech.xdim ; i++) {
    for (j = 0; j < tech.ydim ; j++) {
      grid[twod(i,j)].h = 0.0;
      grid[twod(i,j)].v = 0.0;
    }
  }
}


// fix up partial edge ggrids

int
fix_edge_grids (grid, function)
     Grid *grid;
     int function;
{
  int i,j,value;

  // remove resources for edge cells

  // bottom edge
  if ( tech.bottom_size > 0 ) {
    j = 0;
    value = (tech.ggrid_y - tech.bottom_size) * tech.h_rsrc_track * function;
    for (i = 0; i < tech.xdim ; i++) {
      grid[twod(i,j)].h += value;
    }
  }

  // top edge
  if ( tech.top_size > 0 ) {
    j = tech.ydim - 1;
    value = (tech.ggrid_y - tech.top_size) * tech.h_rsrc_track * function;
    for (i = 0; i < tech.xdim ; i++) {
      grid[twod(i,j)].h += value;
    }
  }

  // left edge
  if ( tech.left_size > 0 ) {
    i = 0;
    value = (tech.ggrid_x - tech.left_size) * tech.v_rsrc_track * function;
    for (j = 0; j < tech.ydim ; j++) {
      grid[twod(i,j)].v += value;
    }
  }

  // right edge
  if ( tech.right_size > 0 ) {
    i = tech.xdim - 1;
    value = (tech.ggrid_x - tech.right_size) * tech.v_rsrc_track * function;
    for (j = 0; j < tech.ydim ; j++) {
      grid[twod(i,j)].v += value;
    }
  }
}


int
route_stats (grid, show)
     Grid *grid;
     int show;
{
  int i, j;
  int h, v;
  int max_congestion_h = 0;
  int max_congestion_v = 0;
  int max_congestion = 0;

  int h_tot_r = 0;
  int v_tot_r = 0;
  int h_tot_s = 0;
  int v_tot_s = 0;
  int histogram[1000];

  Segment *segment;
  SLink *slink;

  for (i = 0; i < 1000 ; i++) {
    histogram[i] = 0;
  }

  // routed length
  for (i = 0; i < tech.xdim ; i++) {
    for (j = 0; j < tech.ydim ; j++) {
      h_tot_r += grid[twod(i,j)].h;
      v_tot_r += grid[twod(i,j)].v;

      h = (int) ceil(grid[twod(i,j)].h - 0.0001);
      v = (int) ceil(grid[twod(i,j)].v - 0.0001);

      //printf ("%g %g %d %d\n", grid[twod(i,j)].h, grid[twod(i,j)].v, h, v);

      histogram[ max (h,v) ] += 1;

      max_congestion_h = max (max_congestion_h, h);
      max_congestion_v = max (max_congestion_v, v);
    }
  }

  // segment lengths
  for (slink = unrouted_list ; slink != NULL ; slink = slink->next) {
    segment = slink->segment;

    // add extra for endpoints
    h_tot_s += abs(segment->pt1.x - segment->pt2.x) + 0.5;
    v_tot_s += abs(segment->pt1.y - segment->pt2.y) + 0.5;
  }

  printf ("total wire length: steiner = %d, global router = %d\n", 
	  h_tot_s * tech.ggrid_x + v_tot_s * tech.ggrid_y,
	  h_tot_r * tech.ggrid_x + v_tot_r * tech.ggrid_y);

  max_congestion = max( max_congestion_h, max_congestion_v);

  if (show == TRUE) {
    // histogram
    for (i = 0; i <= max_congestion ; i++) {
      printf("%4d ", i);
    }
    printf("\n");

    for (i = 0; i <= max_congestion ; i++) {
      printf("==== ");
    }
    printf("\n");

    for (i = 0; i <= max_congestion ; i++) {
      printf("%4d ", histogram[i]);
    }
    printf("\n");
  }

  printf ("Maximum congestion: %d  (%g%% vertical, %g%% horizontal def/layout direction)\n", 
	  max_congestion, 100.0*max_congestion_v/tech.v_rsrc, 
	  100.0*max_congestion_h/tech.h_rsrc);
}


// Tcl entry point for global router.
// assumes nl is already loaded up with the design.

// Usage (from tcl): gr_command <x_ggrid_size> <y_ggrid_size> <v_resources_per_track> <h_resources_per_track> <show_grid>

// show_grid typically 0 or 1.
// if adding blockages, call this proc with show_grid=2 to setup grid, 
// then call gr_block to add blockages, and then call with show_grid=3 to 
// route.

int
tcl_gr (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{
  int i, j, start;
  char *verilog_file, *def_file, *technology;
  int code, show;

  nl_object obj = ui_obj_get_nl_object (objv[1]);

  mem_group prev_group;

  // print debugging info
  code = Tcl_GetIntFromObj(interp, objv[6], &show);
  if (code != TCL_OK) return code;

  // skip setup if show==3.  Already done and blockages added
  if ( show != 3 ) {

    // global route grid size in routing grids
    code = Tcl_GetIntFromObj(interp, objv[2], &tech.ggrid_x);
    if (code != TCL_OK) return code;

    code = Tcl_GetIntFromObj(interp, objv[3], &tech.ggrid_y);
    if (code != TCL_OK) return code;

    // routing resource per track
    code = Tcl_GetDoubleFromObj(interp, objv[4], &tech.v_rsrc_track);
    if (code != TCL_OK) return code;

    code = Tcl_GetDoubleFromObj(interp, objv[5], &tech.h_rsrc_track);
    if (code != TCL_OK) return code;

    if ( gr_group == NULL ) {
      gr_group = mem_group_create ("gr", 8);
    }

    // free from previous
    mem_group_free_contents (gr_group);

    // change to "gr" group for alloc/free
    prev_group = mem_group_set (gr_group);

    if ( nl_object_kind (obj) != nl_kind_design ) {
      printf ("Error: arg isn't an nl design\n");

      mem_group_set (prev_group);
      
      return TCL_ERROR;
    }

    design = (nl_design) obj;

    printf ("Global Router\n");

    // setup
    init_tech ();

    unrouted_list = NULL;
    routed_list = NULL;

    error_catch {
      
      init_die ();

      pgrid = mem_malloc(tech.xdim*tech.ydim*sizeof(Grid));
      init_grid (pgrid);
      printf ("Built %d X %d global route grid.  Each grid is %d X %d tracks.\n",
	      tech.xdim, tech.ydim, tech.ggrid_x, tech.ggrid_y);

      fix_edge_grids (pgrid, ADD);
    }
    error_on_error {
      fprintf (stderr, "ERROR: %s", error_message);
    }
    error_end;
    
    if ( show == 2 ) {
      // setup only.  User is going to add blockages and then rerun with show=3
      return TCL_OK;
    }
  }

  // preroute and route
  error_catch {

    // remember start time
    start = time((time_t *) NULL);

    preroute_design ();

    if (show == TRUE) {
      show_grid(pgrid);
    }

    printf ("Probability Matrix built with %d nets and %d segments, Routing ...\n", tech.num_nets, tech.num_segments);

    route ();

    // undo edge grids so they don't look full
    fix_edge_grids (pgrid, SUBTRACT);

    printf ("Route elapsed time: %d seconds\n", time((time_t *) NULL) - start);

    if (show == TRUE) {
      show_grid(pgrid);
    }

    route_stats(pgrid, show);
  }
  error_on_error {
    fprintf (stderr, "ERROR: %s", error_message);
  }
  error_end;

  printf("done.\n");

  mem_group_set (prev_group);

  return TCL_OK;
}


// Set up iterator to get congestion
// Takes a vertical minimum, horizontal minimum for return

int max_c_v, max_c_h;
int grid_i, grid_j;

int
tcl_gr_grid (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{
  int code;

  Tcl_Obj *lobj = Tcl_NewObj();  // tcl list result

  code = Tcl_GetIntFromObj(interp, objv[1], &max_c_v);
  if (code != TCL_OK) return code;

  code = Tcl_GetIntFromObj(interp, objv[2], &max_c_h);
  if (code != TCL_OK) return code;

  // eliminate rounding error
  max_c_v -= 0.5;
  max_c_h -= 0.5;

  // reset iterator
  grid_i = 0;
  grid_j = 0;

  //printf ("--> %d %d\n", max_c_v, max_c_h);

  return TCL_OK;
}


// Returns x, y, h, v.  Where x, y are the coords of the ggrid (offset
// to corresponds to microns) and h, v are the congestions there.

tcl_gr_grid_iter (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{

  int done;
  double value_h, value_v;

  Grid *grid = pgrid;

  Tcl_Obj *lobj = Tcl_NewObj();  // tcl list result

  if ( grid_j < 0 ) {
    // done
    Tcl_SetObjResult(interp,lobj);
    return TCL_OK;
  }

  // routed length
  while ( TRUE ) {

    if ( grid_j == 0 && tech.bottom_size > 0 ) {
      // fix up for edge cell
      value_h = grid[twod(grid_i,grid_j)].h * tech.ggrid_y / tech.bottom_size;

    } else if ( grid_j == tech.ydim - 1 && tech.top_size > 0 ) {
      // fix up for edge cell
      value_h = grid[twod(grid_i,grid_j)].h * tech.ggrid_y / tech.top_size;

    } else {
      value_h = grid[twod(grid_i,grid_j)].h;
    }

    if ( grid_i == 0 && tech.left_size > 0 ) {
      // fix up for edge cell
      value_v = grid[twod(grid_i,grid_j)].v * tech.ggrid_x / tech.left_size;

    } else if ( grid_i == tech.xdim - 1 && tech.right_size > 0 ) {
      // fix up for edge cell
      value_v = grid[twod(grid_i,grid_j)].v * tech.ggrid_x / tech.right_size;

    } else {
      value_v = grid[twod(grid_i,grid_j)].v;
    }

    if ( value_h >= max_c_h || value_v >= max_c_v ) {

      Tcl_ListObjAppendElement(interp,lobj,Tcl_NewIntObj(grid_i + tech.offset_x));
      Tcl_ListObjAppendElement(interp,lobj,Tcl_NewIntObj(grid_j + tech.offset_y));

      Tcl_ListObjAppendElement(interp, lobj, Tcl_NewIntObj(
		   (int) ceil(value_h - 0.0001)));
      Tcl_ListObjAppendElement(interp, lobj, Tcl_NewIntObj(
		   (int) ceil(value_v - 0.0001)));

      done = TRUE;
    } else {
      done = FALSE;
    }

    //printf("---> %d %d %d %d %d (%g %g) %d %d\n", tech.xdim, tech.ydim, twod(grid_i,grid_j), grid_i, grid_j, grid[twod(grid_i,grid_j)].h, grid[twod(grid_i,grid_j)].v, (int) ceil(grid[twod(grid_i,grid_j)].h - 0.0001), (int) ceil(grid[twod(grid_i,grid_j)].v - 0.0001));

    if ( grid_i + 1 >= tech.xdim ) {
      grid_i = 0;
      if ( grid_j + 1 >= tech.ydim ) {
	// done
	grid_j = -1;
	break;

      } else {
	grid_j++;
      }

    } else {
      grid_i++;
    }

    if ( done ) {
      break;
    }
  }

  Tcl_SetObjResult(interp,lobj);

  return TCL_OK;
}


// Tcl entry point to add blockages.
// usage (from tcl): gr_block x y v h
//   where x,y is the ggrid in ggrid units (i.e. 0,0 is lower left)
//         h,v are the blockage amounts in horizontal/vertical dirs.

int
tcl_gr_block (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{
  int x, y, code;
  double v, h;

  // global route coords
  code = Tcl_GetIntFromObj(interp, objv[2], &x);
  if (code != TCL_OK) return code;

  code = Tcl_GetIntFromObj(interp, objv[3], &y);
  if (code != TCL_OK) return code;

  if ( x < 0 || x >= tech.xdim || y < 0 || y >= tech.ydim ) {
    // oops, out of bounds
    printf("ggrid %d,%d out of range, must be between 0 and %d,%d.\n",
	   x, y, tech.xdim, tech.ydim);
    return TCL_ERROR;
  }

  // vertical blockage in this ggrid
  code = Tcl_GetDoubleFromObj(interp, objv[4], &v);
  if (code != TCL_OK) return code;

  // horizontal blockage in this ggrid
  code = Tcl_GetDoubleFromObj(interp, objv[5], &h);
  if (code != TCL_OK) return code;

  // add directly into probability grid
  pgrid[twod(x,y)].h += h;
  pgrid[twod(x,y)].v += v;

  return TCL_OK;
}
