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

// Global Router

// TODO: snap right_size, etc, to units of the default track size (rgrid_x).

// TODO: max blockage analyzer needs to support multiple pitches.
//       Congestion analyzer uses a single routing track - use a multiplier for each layer to determine
//       the amount that the congestion actually affects the grid.

// Notes from PAT to LEE:
//
// I prepended "gr_" to global variables and typedefs.
// Modified preroute_net_walker to handle hierarchical and non-hierarchical traversals.
// Modified preroute_pin_walker to handle hierarchical and non-hierarchical traversals;
// if non-hierchical and #if USE_MAX, gets pin locations from max.
// Switched function arguments to ANSI syntax (looks like function prototypes.)
// Took out the memory group stuff - you should not change the global memory group,
// as it causes bugs if any other called function does a malloc.
// It would probably be ok to use alloc_from_group with a specified group,
// but I just took it completely out to save time.
//
// Added interface to max congestion.
// Modified gr_command to take options.  Left tcl_gr more or less there, but its probably broken now.
// Modified to support multiple layers that have different track spacing.  This entailed:
// 	Nearly eradicating ggrid_x/ggrid_y and rgrid_x/rgrid_y.
//	Wiring resources calculated from list of metal layers.
//	Changed left_size,etc,  (formerly in tracks), to left_frac (now in fraction of global grid avail)
//	Rewrote init_die:  It snarfs the track data into a data-base.  Then examines the
//	user specified layers to compute the global grid size, and the total resources.


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
#define GR_MALLOC(x) malloc(x)
#define GR_FREE(x) free(x)

#include <time.h> 
#include <tcl.h>


// nl stuff
#include "nl_include.h" 

#if USE_MAX
// NL and max both define ASSERT, MALLOC, etc.  We dont use them in this file,
// so just undef them to avoid compiler error messages.
#undef ASSERT
#undef MALLOC
#undef CALLOC
#undef FREE
#include "main.h"		// This is the max main.h
#include "database.h"
#include "layout.h"
#include "special.h"
#define ERRORF MsgErrorF
#define PRINTF MsgInfoF
#else

#define CMD_BEGIN(interp) {gr_tcl_interp = interp; gr_tcl_result = TCL_OK;}
#define CMD_RETURN(interp) {return gr_tcl_result;}
#define ERRORF gr_error
#define PRINTF printf

#endif

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

#define twod(x,y) ((x)*gr_tech.ydim+(y))

#define max(x,y) ((x) > (y) ? (x) : (y))
#define min(x,y) ((x) < (y) ? (x) : (y))


// convert from coords in nanons to global route grid coords
#define x_adjust(x) ( floor( 1.0 * (x) / gr_tech.grid_x - gr_tech.offset_x ) )
#define y_adjust(y) ( floor( 1.0 * (y) / gr_tech.grid_y - gr_tech.offset_y ) )

typedef struct s_Point  {

  int x, y;      // coords of point

} grPoint;

typedef struct s_Rect {
    int x1, y1, x2, y2;
} grRect;

typedef struct s_Blockage {
    short hblock,vblock;	// pre-existing congestion in this bin.
} grBlockage;


// pre-existing congestion grid.
grBlockage *gr_cong_grid = NULL;

typedef struct s_Segment  {
  grPoint pt1, pt2;   // the actual points, not pointers to them
  int pt1_status, routed;
  // save ipin or at least net name also
} grSegment;


typedef struct s_SLink  {
  grSegment *segment;
  struct s_SLink *next;
} grSLink;

grSLink *gr_unrouted_list = NULL;


// Routing grid data

typedef struct s_Grid  {
  double v, h;    // vertical and horizontal grids
} grGrid;

// probability grid
grGrid *gr_pgrid = NULL;


struct tech  {

  int xdim, ydim;            // width, height of global routing grid in units.

  //double v_rsrc_track, h_rsrc_track;     // vertical and horizontal routing resources per track
  double v_rsrc, h_rsrc;     // vertical and horizontal routing resources in a global grid
  double v_limit, h_limit;   // vertical and horizontal limits

  int offset_x, offset_y;   // offset in global routing grid units, convert so ggrid starts at 0,0

  //int rgrid_x, rgrid_y;     // routing grid (size of a wire track in nanons)

  int ggrid_x, ggrid_y;     // number of routes per global route grid
			    // NOTE: Since ggrid_x and ggrid_y depend on the specific layer,
			    // they are used primarily just to compute grid_x and grid_y.

  int grid_x, grid_y;       // size of global routing boxes in nanons
  grRect grid_area;	    // area to global route.

  int units;                // 1000 == milli microns  NOT USED!!!

  double left_frac, right_frac, top_frac, bottom_frac;
                            // Fraction of respective edge grids available.
  int num_nets, num_segments;   // for stats

  int pin_unplaced, cell_unplaced; // for warning

  int do_hier;
};

struct tech gr_tech;

// nl setup
nl_design gr_design;


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


// Like printf, but sends the message to the tcl intepreter result value,
// and sets the tcl return status to TCL_ERROR.
// To use this, you must bracket the tcl command with CMD_BEGIN and CMD_RETURN macros.
// Max defines these internally, so this routine is for use inside sue or elsewhere.

// tcl error junk
Tcl_Interp *gr_tcl_interp;
int gr_tcl_result;

static gr_error(char *fmt,...)
{
  va_list args;
  char buf[3000];	// error message better not be bigger.
  va_start(args,fmt);
  vsprintf(buf,fmt,args);
  Tcl_AppendResult(gr_tcl_interp,buf);
  gr_tcl_result = TCL_ERROR;
}

static void
add_prob_reduced (grPoint *pt1, grPoint *pt2, int function, int pt1_status)
{

  int x1, x2, y1, y2;
  int x,y,i,j;

  int dx = abs(pt2->x - pt1->x);
  int dy = abs(pt2->y - pt1->y);
  int denom = dx + dy;
  double basis = 1.0/denom;

  //PRINTF ("add box --> %d,%d to %d,%d (%d)\n",pt1->x,pt1->y,pt2->x,pt2->y, pt1_status);

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
      gr_pgrid[twod(pt1->x,pt1->y)].h += BEF * function - 2 * l_inv;
      gr_pgrid[twod(pt1->x,pt1->y)].v += BEF * function - 0.4 * function;
    } else {
      gr_pgrid[twod(pt1->x,pt1->y)].v -= 0.4 * function;
    }

    gr_pgrid[twod(pt2->x,pt2->y)].h += BEF * function - 2 * l_inv;
    gr_pgrid[twod(pt2->x,pt2->y)].v += BEF * function - 0.4 * function;

    // other
    // assure that we stay inside the grid
/* For jog of +-1
    if ( x1 == 0 ) {
      // special case, no grid below

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(x1,i)].v += 0.5 * function;
	gr_pgrid[twod(xp1,i)].v += 0.5 * function;

	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp1,i)].h += 2 * l_inv;
      }

    } else if ( xp1 == gr_tech.xdim ) {
      // special case, no grid above

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(xm1,i)].v += 0.5 * function;
	gr_pgrid[twod(x1,i)].v += 0.5 * function;

	gr_pgrid[twod(xm1,i)].h += 2 * l_inv;
	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
      }

    } else {
      // normal case

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(xm1,i)].v += 0.25 * function;
	gr_pgrid[twod(x1,i)].v += 0.5 * function;
	gr_pgrid[twod(xp1,i)].v += 0.25 * function;

	gr_pgrid[twod(xm1,i)].h += 1 * l_inv;
	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp1,i)].h += 1 * l_inv;
      }
    }
*/
    // Allows jogs of up to +/- 2 grids
    // NOTE: breaks if less than 3 grids wide

    if ( x1 == 0 ) {
      // special case, no grid left

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(x1,i)].v += 0.4 * function;
	gr_pgrid[twod(xp1,i)].v += 0.4 * function;
	gr_pgrid[twod(xp2,i)].v += 0.2 * function;

	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp2,i)].h += l_inv;
      }

    } else if ( x1 == 1 ) {

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(xm1,i)].v += 0.3 * function;
	gr_pgrid[twod(x1,i)].v += 0.4 * function;
	gr_pgrid[twod(xp1,i)].v += 0.2 * function;
	gr_pgrid[twod(xp2,i)].v += 0.1 * function;

	gr_pgrid[twod(xm1,i)].h += l_inv;
	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp1,i)].h += l_inv;
	gr_pgrid[twod(xp2,i)].h += l_inv;
      }

    } else if ( xp1 == gr_tech.xdim ) {
      // special case, no grid right

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(xm2,i)].v += 0.2 * function;
	gr_pgrid[twod(xm1,i)].v += 0.4 * function;
	gr_pgrid[twod(x1,i)].v += 0.4 * function;

	gr_pgrid[twod(xm2,i)].h += l_inv;
	gr_pgrid[twod(xm1,i)].h += 2 * l_inv;
	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
      }

    } else if ( xp2 == gr_tech.xdim ) {
      // special case, no grid right

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(xm2,i)].v += 0.1 * function;
	gr_pgrid[twod(xm1,i)].v += 0.2 * function;
	gr_pgrid[twod(x1,i)].v += 0.4 * function;
	gr_pgrid[twod(xp1,i)].v += 0.3 * function;

	gr_pgrid[twod(xm2,i)].h += l_inv;
	gr_pgrid[twod(xm1,i)].h += l_inv;
	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp1,i)].h += l_inv;
      }

    } else {
      // normal case

      for (i = ymin ; i <= ymax ; i++) {
	gr_pgrid[twod(xm2,i)].v += 0.1 * function;
	gr_pgrid[twod(xm1,i)].v += 0.2 * function;
	gr_pgrid[twod(x1,i)].v += 0.4 * function;
	gr_pgrid[twod(xp1,i)].v += 0.2 * function;
	gr_pgrid[twod(xp2,i)].v += 0.1 * function;

	gr_pgrid[twod(xm2,i)].h += l_inv;
	gr_pgrid[twod(xm1,i)].h += 2 * l_inv;
	gr_pgrid[twod(x1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp1,i)].h += 2 * l_inv;
	gr_pgrid[twod(xp2,i)].h += l_inv;
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
      gr_pgrid[twod(pt1->x,pt1->y)].v += BEF * function - 2 * l_inv;
      gr_pgrid[twod(pt1->x,pt1->y)].h += BEF * function - 0.4 * function;
    } else {
      gr_pgrid[twod(pt1->x,pt1->y)].h -= 0.4 * function;
    }

    gr_pgrid[twod(pt2->x,pt2->y)].v += BEF * function - 2 * l_inv;
    gr_pgrid[twod(pt2->x,pt2->y)].h += BEF * function - 0.4 * function;

    // other
    // assure that we stay inside the grid
/* For jog of +-1
    if ( y1 == 0 ) {
      // special case, no grid below

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,y1)].h += 0.5 * function;
	gr_pgrid[twod(i,yp1)].h += 0.5 * function;

	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp1)].v += 2 * l_inv;
      }

    } else if ( yp1 == gr_tech.ydim ) {
      // special case, no grid above

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,ym1)].h += 0.5 * function;
	gr_pgrid[twod(i,y1)].h += 0.5 * function;

	gr_pgrid[twod(i,ym1)].v += 2 * l_inv;
	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
      }

    } else {
      // normal case

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,ym1)].h += 0.25 * function;
	gr_pgrid[twod(i,y1)].h += 0.5 * function;
	gr_pgrid[twod(i,yp1)].h += 0.25 * function;

	gr_pgrid[twod(i,ym1)].v += 1 * l_inv;
	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp1)].v += 1 * l_inv;
      }
    }
*/

    // Allows jogs of up to +/- 2 grids
    // NOTE: breaks if less than 3 grids tall

    if ( y1 == 0 ) {
      // special case, no grid below

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,y1)].h += 0.4 * function;
	gr_pgrid[twod(i,yp1)].h += 0.4 * function;
	gr_pgrid[twod(i,yp2)].h += 0.2 * function;

	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp2)].v += l_inv;
      }

    } else if ( y1 == 1 ) {

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,ym1)].h += 0.3 * function;
	gr_pgrid[twod(i,y1)].h += 0.4 * function;
	gr_pgrid[twod(i,yp1)].h += 0.2 * function;
	gr_pgrid[twod(i,yp2)].h += 0.1 * function;

	gr_pgrid[twod(i,ym1)].v += l_inv;
	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp1)].v += l_inv;
	gr_pgrid[twod(i,yp2)].v += l_inv;
      }

    } else if ( yp1 == gr_tech.ydim ) {
      // special case, no grid above

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,ym2)].h += 0.2 * function;
	gr_pgrid[twod(i,ym1)].h += 0.4 * function;
	gr_pgrid[twod(i,y1)].h += 0.4 * function;

	gr_pgrid[twod(i,ym2)].v += l_inv;
	gr_pgrid[twod(i,ym1)].v += 2 * l_inv;
	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
      }

    } else if ( yp2 == gr_tech.ydim ) {
      // special case, no grid above

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,ym2)].h += 0.1 * function;
	gr_pgrid[twod(i,ym1)].h += 0.2 * function;
	gr_pgrid[twod(i,y1)].h += 0.4 * function;
	gr_pgrid[twod(i,yp1)].h += 0.3 * function;

	gr_pgrid[twod(i,ym2)].v += l_inv;
	gr_pgrid[twod(i,ym1)].v += l_inv;
	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp1)].v += l_inv;
      }

    } else {
      // normal case

      for (i = x1 ; i <= x2 ; i++) {
	gr_pgrid[twod(i,ym2)].h += 0.1 * function;
	gr_pgrid[twod(i,ym1)].h += 0.2 * function;
	gr_pgrid[twod(i,y1)].h += 0.4 * function;
	gr_pgrid[twod(i,yp1)].h += 0.2 * function;
	gr_pgrid[twod(i,yp2)].h += 0.1 * function;

	gr_pgrid[twod(i,ym2)].v += l_inv;
	gr_pgrid[twod(i,ym1)].v += 2 * l_inv;
	gr_pgrid[twod(i,y1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp1)].v += 2 * l_inv;
	gr_pgrid[twod(i,yp2)].v += l_inv;
      }
    }

  } else {
    // box, NOT a line

    basis *= function;

    //  PRINTF("function = %d, basis = %g\n",function,basis);

    // begin/end
    if (pt1_status == ROUTE_START) {
      gr_pgrid[twod(pt1->x,pt1->y)].h += BEF * function;
      gr_pgrid[twod(pt1->x,pt1->y)].v += BEF * function;
    }

    gr_pgrid[twod(pt2->x,pt2->y)].h += BEF * function;
    gr_pgrid[twod(pt2->x,pt2->y)].v += BEF * function;

    // corners
    gr_pgrid[twod(pt1->x,pt2->y)].h += basis;
    gr_pgrid[twod(pt1->x,pt2->y)].v += basis;
    gr_pgrid[twod(pt2->x,pt1->y)].h += basis;
    gr_pgrid[twod(pt2->x,pt1->y)].v += basis;

    for (i = x1 + 1 ; i < x2 ; i++) {

      // top and bottom edge
      gr_pgrid[twod(i,pt1->y)].h += (x2-i+1)*basis;
      gr_pgrid[twod(i,pt1->y)].v += basis;
      gr_pgrid[twod(i,pt2->y)].h += (i-x1+1)*basis;
      gr_pgrid[twod(i,pt2->y)].v += basis;

      // soft, juicy middle
      if (y2 > y1) {
	for (j = y1 + 1 ; j < y2 ; j++) {
	  gr_pgrid[twod(i,j)].h += basis;
	  gr_pgrid[twod(i,j)].v += basis;
	}
      } else {
	for (j = y2 + 1 ; j < y1 ; j++) {
	  gr_pgrid[twod(i,j)].h += basis;
	  gr_pgrid[twod(i,j)].v += basis;
	}
      }
    }

    // right and left edge
    if (y2 > y1) {
      for (j = y1 + 1 ; j < y2 ; j++) {
	gr_pgrid[twod(pt1->x,j)].h += basis;
	gr_pgrid[twod(pt1->x,j)].v += (y2-j+1)*basis;
	gr_pgrid[twod(pt2->x,j)].h += basis;
	gr_pgrid[twod(pt2->x,j)].v += (j-y1+1)*basis;
      }
    } else {
      for (j = y2 + 1 ; j < y1 ; j++) {
	gr_pgrid[twod(pt1->x,j)].h += basis;
	gr_pgrid[twod(pt1->x,j)].v += (j-y2+1)*basis;
	gr_pgrid[twod(pt2->x,j)].h += basis;
	gr_pgrid[twod(pt2->x,j)].v += (y1-j+1)*basis;
      }
    }
  }
}


// Only looks for 1 turn and 2 turn routes.  If it can't find either, punts.
// Looks for routes starting horizontal first, only.
// Just looks for a route that is less that limits, not the best one.

static int
route_box_h (grPoint *pt1, grPoint *pt2, int pt1_status)
{
  int x1_i, y1_i, x2_i, y2_i;
  int x1_iv, x2_iv, ok;
  int i, j, routable, xdir, ydir;
  
  int x1 = pt1->x;
  int y1 = pt1->y;
  int x2 = pt2->x;
  int y2 = pt2->y;

  xdir = x1 < x2 ? 1 : -1;

//PRINTF("h routing %d %d --> %d %d\n", x1, y1, x2, y2);

  if ( y1 == y2 ) {
    // horizontal route only
    // Can route up/down one or two.

    for (x1_i = x1 + xdir ; xdir > 0 ? x1_i < x2 : x1_i > x2 ; x1_i += xdir) {
      if (gr_pgrid[twod(x1_i,y1)].h >= gr_tech.h_limit) {
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
	gr_pgrid[twod(j,y1)].h += 1.0;	
      }

      // special case for endpoints
      if ( pt1_status == ROUTE_START ) {
	gr_pgrid[twod(x1,y1)].h += BEF;	
	gr_pgrid[twod(x1,y1)].v += BEF;	
      }

      gr_pgrid[twod(x2,y2)].h += BEF;	
      gr_pgrid[twod(x2,y2)].v += BEF;	
      
      //PRINTF("\t> %d -> %d  (%d)\n", x1, x2, y1);

      return SUCCEED;

    } else {
      int dy;

      // don't allow jogging until limit larger -- special case
      if ( gr_tech.h_limit < 0.75 ) {
	return FAIL;
      }

      // check if can make it by jogging up/down 1
      x1_i -= xdir;

      for (x2_i = x2-xdir ; xdir > 0 ? x2_i > x1 : x2_i < x1 ; x2_i -= xdir) {
	if (gr_pgrid[twod(x2_i,y2)].h >= gr_tech.h_limit) {
	  // blocked from going further
	  break;
	}
      }
      x2_i += xdir;

/*
      //DEBUG
      if ( x2_i - x1_i < 5 && x2 - x2_i + x1_i - x1 > 2) {
	PRINTF("skip short %d ^ %d -> %d v %d (%d)\n", x1, x1_i, x2_i, x2, y1);

	return FAIL;
      }
*/

      for (dy = -1 ; dy < 2 ; dy += 2) {
	int yy = y1 + dy;

	if ( yy < 0 || yy >= gr_tech.ydim ) {
	  // outside of grid
	  continue;
	}

	// check vertical resource for jog, if not, backup one.
	ok = 0;
	for (x1_iv = x1_i ; xdir > 0 ? x1_iv >= x1 : x1_iv <= x1 ; x1_iv -= xdir) {
	  if (gr_pgrid[twod(x1_iv,y1)].v < gr_tech.v_limit &&
	      gr_pgrid[twod(x1_iv,yy)].v < gr_tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  //PRINTF ("No Vertical resource x1: %d (%d) %d %d %g %g\n", x1, x2, x1_i, x1_iv, gr_pgrid[twod(x1_iv,y1)].v, gr_pgrid[twod(x1_iv,yy)].v);
	  continue;
	}

	ok = 0;
	for (x2_iv = x2_i ; xdir > 0 ? x2_iv <= x2 : x2_iv >= x2 ; x2_iv += xdir) {
	  if (gr_pgrid[twod(x2_iv,y1)].v < gr_tech.v_limit &&
	      gr_pgrid[twod(x2_iv,yy)].v < gr_tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  //PRINTF ("No Vertical resource x2: %d %d %d %g %g\n", x2, x2_i, x2_iv, gr_pgrid[twod(x2_iv,y1)].v, gr_pgrid[twod(x2_iv,yy)].v);
	  continue;
	}

	for (j = x1_iv ; xdir > 0 ? j < x2_iv : j > x2_iv ; j += xdir) {
	  //PRINTF("\t\t%g >= %g (%d %d)\n", gr_pgrid[twod(j,yy)].h, gr_tech.h_limit, j, yy);
	  if (gr_pgrid[twod(j,yy)].h >= gr_tech.h_limit) {
	    //PRINTF("\t\tfail\n");
	    break;
	  }
	}

	if ( j != x2_iv ) {
	  // this jog failed
	  continue;
	}

	// jog worked, route it
	//PRINTF("\t%d ^ %d -> %d v %d (%d -> %d)\n", x1, x1_iv, x2_iv, x2, y1, yy);

	// now eliminate probabilities since we routed it
	add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

	// add 1's in since it is no longer a probability
	for (j = x1 + xdir ; xdir > 0 ? j <= x1_iv : j >= x1_iv ; j += xdir) {    
	  gr_pgrid[twod(j,y1)].h += 1.0;	
	}

	for (j = x2_iv ; xdir > 0 ? j < x2 : j > x2 ; j += xdir) {    
	  gr_pgrid[twod(j,y1)].h += 1.0;	
	}

	// jog
	gr_pgrid[twod(x1_iv,y1)].v += BEF;	
	gr_pgrid[twod(x1_iv,yy)].v += BEF;
	gr_pgrid[twod(x2_iv,y1)].v += BEF;	
	gr_pgrid[twod(x2_iv,yy)].v += BEF;

	for (j = x1_iv ; xdir > 0 ? j <= x2_iv : j >= x2_iv ; j += xdir) {    
	  gr_pgrid[twod(j,yy)].h += 1.0;	
	}

	// corners
	gr_pgrid[twod(x1_iv,yy)].h += BEF - 1.0;	
	gr_pgrid[twod(x2_iv,yy)].h += BEF - 1.0;	
	if ( x1_iv != x1 ) {
	  gr_pgrid[twod(x1_iv,y1)].h += BEF - 1.0;	
	}
	if ( x2_iv != x2 ) {
	  gr_pgrid[twod(x2_iv,y1)].h += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  gr_pgrid[twod(x1,y1)].h += BEF;	
	  if ( x1_iv != x1 ) {
	    gr_pgrid[twod(x1,y1)].v += BEF;	
	  } else {
	    //gr_pgrid[twod(x1,y1)].v += BEF - 1.0;	
	  }
	}

	gr_pgrid[twod(x2,y2)].h += BEF;	
	if ( x2_iv != x2 ) {
	  gr_pgrid[twod(x2,y2)].v += BEF;	
	} else {
	  //gr_pgrid[twod(x2,y2)].v += BEF - 1.0;	
	}
      
	return SUCCEED;
      }

      // check if can make it by jogging up/down 2

      for (dy = -1 ; dy < 2 ; dy += 2) {
	int yy = y1 + dy;
	int yy2 = yy + dy;

	if ( yy < 0 || yy2 < 0 || yy >= gr_tech.ydim || yy2 >= gr_tech.ydim ) {
	  // outside of grid
	  continue;
	}

	// check vertical resource for jog, if not, backup one.
	ok = 0;
	for (x1_iv = x1_i ; xdir > 0 ? x1_iv >= x1 : x1_iv <= x1 ; x1_iv -= xdir) {
	  if ( (x1_iv == x1 || gr_pgrid[twod(x1_iv,y1)].v < gr_tech.v_limit) &&
	      gr_pgrid[twod(x1_iv,yy)].v < gr_tech.v_limit &&
	      gr_pgrid[twod(x1_iv,yy2)].v < gr_tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  x1_iv += xdir;
	  //PRINTF ("No Vertical resource x1: %d %d %d %g %g %g >= %g\n", x1, x1_i, x1_iv, gr_pgrid[twod(x1_iv,y1)].v, gr_pgrid[twod(x1_iv,yy)].v, gr_pgrid[twod(x1_iv,yy2)].v, gr_tech.v_limit);
	  continue;
	}

	ok = 0;
	for (x2_iv = x2_i ; xdir > 0 ? x2_iv <= x2 : x2_iv >= x2 ; x2_iv += xdir) {
	  if ( (x2_iv == x2 || gr_pgrid[twod(x2_iv,y1)].v < gr_tech.v_limit) &&
	      gr_pgrid[twod(x2_iv,yy)].v < gr_tech.v_limit &&
	      gr_pgrid[twod(x2_iv,yy2)].v < gr_tech.v_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  x2_iv -= xdir;
	  //PRINTF ("No Vertical resource x2: %d %d %d %g %g %g >= %g\n", x2, x2_i, x2_iv, gr_pgrid[twod(x2_iv,y1)].v, gr_pgrid[twod(x2_iv,yy)].v, gr_pgrid[twod(x2_iv,yy2)].v, gr_tech.v_limit);
	  continue;
	}

	for (j = x1_iv ; xdir > 0 ? j < x2_iv : j > x2_iv ; j += xdir) {
	  if (gr_pgrid[twod(j,yy2)].h >= gr_tech.h_limit) {
	    //PRINTF("\t\tfail\n");
	    break;
	  }
	}

	if ( j != x2_iv ) {
	  // this jog failed
	  continue;
	}

	// jog worked, route it
	//PRINTF("\t%d ^ %d -> %d v %d (%d -> %d)\n", x1, x1_iv, x2_iv, x2, y1, yy2);

	// now eliminate probabilities since we routed it
	add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

	// add 1's in since it is no longer a probability
	for (j = x1 + xdir ; xdir > 0 ? j <= x1_iv : j >= x1_iv ; j += xdir) {    
	  gr_pgrid[twod(j,y1)].h += 1.0;	
	}

	for (j = x2_iv ; xdir > 0 ? j < x2 : j > x2 ; j += xdir) {    
	  gr_pgrid[twod(j,y1)].h += 1.0;	
	}

	// jog
	gr_pgrid[twod(x1_iv,y1)].v += BEF;	
	gr_pgrid[twod(x1_iv,yy)].v += 1.0;
	gr_pgrid[twod(x1_iv,yy2)].v += BEF;
	gr_pgrid[twod(x2_iv,y1)].v += BEF;	
	gr_pgrid[twod(x2_iv,yy)].v += 1.0;
	gr_pgrid[twod(x2_iv,yy2)].v += BEF;

	for (j = x1_iv ; xdir > 0 ? j <= x2_iv : j >= x2_iv ; j += xdir) {    
	  gr_pgrid[twod(j,yy2)].h += 1.0;	
	}

	// corners
	gr_pgrid[twod(x1_iv,yy2)].h += BEF - 1.0;	
	gr_pgrid[twod(x2_iv,yy2)].h += BEF - 1.0;	
	if ( x1_iv != x1 ) {
	  gr_pgrid[twod(x1_iv,y1)].h += BEF - 1.0;	
	}
	if ( x2_iv != x2 ) {
	  gr_pgrid[twod(x2_iv,y1)].h += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  gr_pgrid[twod(x1,y1)].h += BEF;	
	  if ( x1_iv != x1 ) {
	    gr_pgrid[twod(x1,y1)].v += BEF;	
	  } else {
	    //gr_pgrid[twod(x1,y1)].v += BEF - 1.0;	
	  }
	}

	gr_pgrid[twod(x2,y2)].h += BEF;	
	if ( x2_iv != x2 ) {
	  gr_pgrid[twod(x2,y2)].v += BEF;	
	} else {
	  //gr_pgrid[twod(x2,y2)].v += BEF - 1.0;	
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

  //PRINTF("h routing %d %d --> %d %d\n", x1, y1, x2, y2);

  // Ignores limits from beginning/ending

  // look first for the horizontals
  for (x1_i = x1 + xdir ; xdir > 0 ? x1_i <= x2 : x1_i >= x2 ; x1_i += xdir) {
    // should really check that it can add 1-prob to this
    // PRINTF("%g >= %g  (%d %d)\n",gr_pgrid[twod(x1_i,y1)].h, gr_tech.h_limit, x1_i, y1);

    if (gr_pgrid[twod(x1_i,y1)].h >= gr_tech.h_limit) {
      // blocked from going further
      //PRINTF("blocked a\n");
      break;
    }
  }
  x1_i -= xdir;

  for (x2_i = x2 - xdir ; xdir > 0 ? x2_i >= x1 : x2_i <= x1 ; x2_i -= xdir) {
    //PRINTF("%g >= %g  (%d %d)\n",gr_pgrid[twod(x2_i,y2)].h, gr_tech.h_limit, x2_i, y2);
    if (gr_pgrid[twod(x2_i,y2)].h >= gr_tech.h_limit) {
      // blocked from going further
      //PRINTF("blocked b\n");
      break;
    }
  }
  x2_i += xdir;

  // PRINTF("(%d) xxxxx %d --> %d\n", xdir, x1_i, x2_i);

  if (xdir > 0 ? x2_i > x1_i : x2_i < x1_i) {
    // no overlap, can't route
    return FAIL;
  }

  // now look for the verticals
  for (i = x2_i ; xdir > 0 ? i <= x1_i : i >= x1_i ; i += xdir) {    
    routable = SUCCEED;

    if (y1 < y2) {
      for (j = y1 ; j <= y2 ; j++) {  
	if (gr_pgrid[twod(i,j)].v >= gr_tech.v_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    } else {
      for (j = y2 ; j <= y1 ; j++) {  
	if (gr_pgrid[twod(i,j)].v >= gr_tech.v_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    }

    if (routable == SUCCEED) {
      // got one -- not necessarily the best
      //PRINTF("h> x1=%d,i=%d,x2=%d,y1=%d,y2=%d\n",x1,i,x2,y1,y2);

      // now eliminate probabilities since we routed it
      add_prob_reduced (pt1, pt2, SUBTRACT, pt1_status);

      // add 1's in since it is no longer a probability
      for (j = x1 ; xdir > 0 ? j <= i : j >= i ; j += xdir) {    
	gr_pgrid[twod(j,y1)].h += 1.0;	
      }

      if (y1 < y2) {
	for (j = y1 ; j <= y2 ; j++) {  
	  gr_pgrid[twod(i,j)].v += 1.0;
	}
      } else {
	for (j = y2 ; j <= y1 ; j++) {  
	  gr_pgrid[twod(i,j)].v += 1.0;
	}
      }

      for (j = i ; xdir > 0 ? j <= x2 : j >= x2 ; j += xdir) {    
	gr_pgrid[twod(j,y2)].h += 1.0;	
      }

      // special case for corners
      if ( pt1_status == ROUTE_START ) {
	gr_pgrid[twod(x1,y1)].h += BEF - 1.0;	

	if (i != x1) {
	  gr_pgrid[twod(x1,y1)].v += BEF;	
	} else {
	  gr_pgrid[twod(x1,y1)].v += BEF - 1.0;	
	}

      } else {
	gr_pgrid[twod(x1,y1)].h -= 1.0;	
      }

      if (i != x1) {
	gr_pgrid[twod(i,y1)].h += BEF - 1.0;	
	gr_pgrid[twod(i,y1)].v += BEF - 1.0;	
      }

      gr_pgrid[twod(x2,y2)].h += BEF - 1.0;	

      if (i != x2) {
	gr_pgrid[twod(x2,y2)].v += BEF;	

	gr_pgrid[twod(i,y2)].h += BEF - 1.0;	
	gr_pgrid[twod(i,y2)].v += BEF - 1.0;	

      } else {
	gr_pgrid[twod(x2,y2)].v += BEF - 1.0;	
      }

      // TODO: save route somewhere

      return SUCCEED;
    }
  }

  return FAIL;
}


// same as route_box_h but tries a vertical route first

static int 
route_box_v (grPoint *pt1, grPoint *pt2, int pt1_status)
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
      if (gr_pgrid[twod(x1,y1_i)].v >= gr_tech.v_limit) {
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
	gr_pgrid[twod(x1,j)].v += 1.0;	
      }

      // special case for endpoints
      if ( pt1_status == ROUTE_START ) {
	gr_pgrid[twod(x1,y1)].h += BEF;	
	gr_pgrid[twod(x1,y1)].v += BEF;	
      }

      gr_pgrid[twod(x2,y2)].h += BEF;	
      gr_pgrid[twod(x2,y2)].v += BEF;	
      
      //PRINTF("\t> %d -> %d  (%d)\n", y1, y2, x1);

      return SUCCEED;

    } else {
      int dx;

      // don't allow jogging until limit larger -- special case
      if ( gr_tech.v_limit < 0.75 ) {
	return FAIL;
      }

      // check if can make it by jogging left/right 1
      y1_i -= ydir;

      for (y2_i = y2-ydir ; ydir > 0 ? y2_i > y1 : y2_i < y1 ; y2_i -= ydir) {
	if (gr_pgrid[twod(x2,y2_i)].v >= gr_tech.v_limit) {
	  // blocked from going further
	  break;
	}
      }
      y2_i += ydir;

      for (dx = -1 ; dx < 2 ; dx += 2) {
	int xx = x1 + dx;

	if ( xx < 0 || xx >= gr_tech.xdim ) {
	  // outside of grid
	  continue;
	}

	// check vertical resource for jog, if not, backup one.
	ok = 0;
	for (y1_iv = y1_i ; ydir > 0 ? y1_iv >= y1 : y1_iv <= y1 ; y1_iv -= ydir) {
	  if (gr_pgrid[twod(x1,y1_iv)].h < gr_tech.h_limit &&
	      gr_pgrid[twod(xx,y1_iv)].h < gr_tech.h_limit) {
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
	  if (gr_pgrid[twod(x2,y1_iv)].h < gr_tech.h_limit &&
	      gr_pgrid[twod(xx,y1_iv)].h < gr_tech.h_limit) {
	    // o.k. to jog here
	    ok = 1;
	    break;
	  }
	}

	if ( !ok ) {
	  continue;
	}

	for (j = y1_iv ; ydir > 0 ? j < y2_iv : j > y2_iv ; j += ydir) {
	  if (gr_pgrid[twod(xx,j)].v >= gr_tech.v_limit) {
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
	  gr_pgrid[twod(x1,j)].v += 1.0;	
	}

	for (j = y2_iv ; ydir > 0 ? j < y2 : j > y2 ; j += ydir) {    
	  gr_pgrid[twod(x1,j)].v += 1.0;	
	}

	// jog
	gr_pgrid[twod(x1,y1_iv)].h += BEF;	
	gr_pgrid[twod(xx,y1_iv)].h += BEF;
	gr_pgrid[twod(x1,y2_iv)].h += BEF;	
	gr_pgrid[twod(xx,y2_iv)].h += BEF;

	for (j = y1_iv ; ydir > 0 ? j <= y2_iv : j >= y2_iv ; j += ydir) {    
	  gr_pgrid[twod(xx,j)].v += 1.0;	
	}

	// corners
	gr_pgrid[twod(xx,y1_iv)].v += BEF - 1.0;	
	gr_pgrid[twod(xx,y2_iv)].v += BEF - 1.0;	
	if ( y1_iv != y1 ) {
	  gr_pgrid[twod(x1,y1_iv)].v += BEF - 1.0;	
	}
	if ( y2_iv != y2 ) {
	  gr_pgrid[twod(x1,y2_iv)].v += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  gr_pgrid[twod(x1,y1)].v += BEF;	
	  if ( y1_iv != y1 ) {
	    gr_pgrid[twod(x1,y1)].h += BEF;	
	  } else {
	    //gr_pgrid[twod(x1,y1)].h += BEF - 1.0;	
	  }
	}

	gr_pgrid[twod(x2,y2)].v += BEF;	
	if ( y2_iv != y2 ) {
	  gr_pgrid[twod(x2,y2)].h += BEF;	
	} else {
	  //gr_pgrid[twod(x2,y2)].h += BEF - 1.0;	
	}
      
	return SUCCEED;
      }

      // check if can make it by jogging left/right 2
      for (dx = -1 ; dx < 2 ; dx += 2) {
	int xx = x1 + dx;
	int xx2 = xx + dx;

	if ( xx < 0 || xx2 < 0 || xx >= gr_tech.xdim || xx2 >= gr_tech.xdim ) {
	  // outside of grid
	  continue;
	}

	// check horizontal resource for jog, if not, backup one.
	ok = 0;
	for (y1_iv = y1_i ; ydir > 0 ? y1_iv >= y1 : y1_iv <= y1 ; y1_iv -= ydir) {
	  if ( (y1_iv == y1 || gr_pgrid[twod(x1,y1_iv)].h < gr_tech.h_limit) &&
	       gr_pgrid[twod(xx,y1_iv)].h < gr_tech.h_limit &&
	       gr_pgrid[twod(xx2,y1_iv)].h < gr_tech.h_limit) {
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
	  if ( (y2_iv == y2 || gr_pgrid[twod(x1,y2_iv)].h < gr_tech.h_limit) &&
	       gr_pgrid[twod(xx,y2_iv)].h < gr_tech.h_limit &&
	       gr_pgrid[twod(xx2,y2_iv)].h < gr_tech.h_limit) {
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
	  if (gr_pgrid[twod(xx2,j)].v >= gr_tech.v_limit) {
	    //PRINTF("\t\tfail\n");
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
	  gr_pgrid[twod(x1,j)].v += 1.0;	
	}

	for (j = y2_iv ; ydir > 0 ? j < y2 : j > y2 ; j += ydir) {    
	  gr_pgrid[twod(x1,j)].v += 1.0;	
	}

	// jog
	gr_pgrid[twod(x1,y1_iv)].h += BEF;	
	gr_pgrid[twod(xx,y1_iv)].h += 1.0;
	gr_pgrid[twod(xx2,y1_iv)].h += BEF;
	gr_pgrid[twod(x1,y2_iv)].h += BEF;	
	gr_pgrid[twod(xx,y2_iv)].h += 1.0;
	gr_pgrid[twod(xx2,y2_iv)].h += BEF;

	for (j = y1_iv ; ydir > 0 ? j <= y2_iv : j >= y2_iv ; j += ydir) {    
	  gr_pgrid[twod(xx2,j)].v += 1.0;	
	}

	// corners
	gr_pgrid[twod(xx2,y1_iv)].v += BEF - 1.0;	
	gr_pgrid[twod(xx2,y2_iv)].v += BEF - 1.0;	
	if ( y1_iv != y1 ) {
	  gr_pgrid[twod(x1,y1_iv)].v += BEF - 1.0;	
	}
	if ( y2_iv != y2 ) {
	  gr_pgrid[twod(x1,y2_iv)].v += BEF - 1.0;	
	}

	// special case for endpoints
	if ( pt1_status == ROUTE_START ) {
	  gr_pgrid[twod(x1,y1)].v += BEF;	
	  if ( y1_iv != y1 ) {
	    gr_pgrid[twod(x1,y1)].h += BEF;	
	  } else {
	    //gr_pgrid[twod(x1,y1)].h += BEF - 1.0;	
	  }
	}

	gr_pgrid[twod(x2,y2)].v += BEF;	
	if ( y2_iv != y2 ) {
	  gr_pgrid[twod(x2,y2)].h += BEF;	
	} else {
	  //gr_pgrid[twod(x2,y2)].h += BEF - 1.0;	
	}
      
	return SUCCEED;
      }
    }

    return FAIL;
  }

  // look first for the verticals
  for (y1_i = y1 + ydir ; ydir > 0 ? y1_i <= y2 : y1_i >= y2 ; y1_i += ydir) {  
    // should really check that it can add 1-prob to this
    if (gr_pgrid[twod(x1,y1_i)].v >= gr_tech.v_limit) {
      // blocked from going further
      break;
    }
  }
  y1_i -= ydir;

  for (y2_i = y2 - ydir ; ydir > 0 ? y2_i >= y1 : y2_i <= y1 ; y2_i -= ydir) {  
    if (gr_pgrid[twod(x2,y2_i)].v >= gr_tech.v_limit) {
      // blocked from going further
      break;
    }
  }
  y2_i += ydir;

  if (ydir > 0 ? y2_i > y1_i : y2_i < y1_i) {
    // no overlap, can't route
    return FAIL;
  }

// PRINTF("yyyyy %d --> %d\n",y1_i,y2_i);

  // now look for the horizontals
  for (i = y2_i ; ydir > 0 ? i <= y1_i : i >= y1_i ; i += ydir) {    
    routable = SUCCEED;

    if (x1 < x2) {
      for (j = x1 ; j <= x2 ; j++) {  
	if (gr_pgrid[twod(j,i)].h >= gr_tech.h_limit) {	
	  // blocked
	  routable = FAIL;
	  break;
	}
      }
    } else {
      for (j = x2 ; j <= x1 ; j++) {  
	if (gr_pgrid[twod(j,i)].h >= gr_tech.h_limit) {	
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

      //PRINTF("v> x1=%d,i=%d,x2=%d,y1=%d,y2=%d\n",x1,i,x2,y1,y2);

      // add 1's in since it is no longer a probability
      for (j = y1 ; ydir > 0 ? j <= i : j >= i ; j += ydir) {    
	gr_pgrid[twod(x1,j)].v += 1.0;	
      }

      if (x1 < x2) {
	for (j = x1 ; j <= x2 ; j++) {  
	  gr_pgrid[twod(j,i)].h += 1.0;
	}
      } else {
	for (j = x2 ; j <= x1 ; j++) {  
	  gr_pgrid[twod(j,i)].h += 1.0;
	}
      }

      for (j = i ; ydir > 0 ? j <= y2 : j >= y2 ; j += ydir) {    
	gr_pgrid[twod(x2,j)].v += 1.0;	
      }

      // special case for corners
      if ( pt1_status == ROUTE_START ) {
	if (i != y1) {
	  gr_pgrid[twod(x1,y1)].h += BEF;
	} else {
	  gr_pgrid[twod(x1,y1)].h += BEF - 1.0;
	}

	gr_pgrid[twod(x1,y1)].v += BEF - 1.0;	

      } else {
	gr_pgrid[twod(x1,y1)].v -= 1.0;	
      }

      if (i != y1) {
	gr_pgrid[twod(x1,i)].h += BEF - 1.0;	
	gr_pgrid[twod(x1,i)].v += BEF - 1.0;	
      }

      gr_pgrid[twod(x2,y2)].v += BEF - 1.0;	

      if (i != y2) {
	gr_pgrid[twod(x2,y2)].h += BEF;

	gr_pgrid[twod(x2,i)].h += BEF - 1.0;	
	gr_pgrid[twod(x2,i)].v += BEF - 1.0;	

      } else {
	gr_pgrid[twod(x2,y2)].h += BEF - 1.0;
      }

      // TODO: save route somewhere

      return SUCCEED;
    }
  }

  return FAIL;
}




/* Traverses every net in the design using nl, steiner routes it, and 
   then adds to prob. matrix.
 */

static void preroute_design () 
{

  nl_idesign idesign;
  static nl_walk_status preroute_net_walker ();

  int do_hierarchy = gr_tech.do_hier;
  int noassign = 1;
  int noconstant = 1;
  int noempty = 1;
  int onlyconstant = 0;

  idesign = do_hierarchy ? nl_idesign_get_or_create (gr_design, NULL) : NULL;

  // calls command for each net
  nl_walk_nets (gr_design, idesign, noassign, do_hierarchy, noconstant, noempty,
		onlyconstant, preroute_net_walker, NULL);
}


// process each net

static nl_walk_status preroute_net_walker (nl_object net_or_inet, int *null_ptr)
{

  static nl_walk_status preroute_pin_walker ();

  int drivers = 1;
  int loads = 1;
  int fanios = 1;
  int noassign = 1;
  nl_net net;
  nl_idesign idesign;
  char *net_name;
  int cmd = 1;

  grPoint pt1, pt2;
  int route_type = ROUTE_START;

  grSegment *segment;
  grSLink *slink;

  if (nl_object_kind(net_or_inet) == nl_kind_net) {
    // It is a non-hierarchical traversal of net connections in the current module.
    net = (nl_net) net_or_inet;
    idesign = NULL;
  } else {
    // It is a hierarchical traversal of everything hooked to inet.
    net = nl_inet_net ( (nl_inet) net_or_inet );
    idesign = nl_inet_idesign ( (nl_inet) net_or_inet );
  }

  // NOTE: not the hier name.  Only the local name
  net_name = nl_net_name (net);

  // don't really need name here.
  //PRINTF("net = %s\n",net_name);
  steiner_begin_net (net_name);

  nl_walk_connected_pins (net, idesign, noassign, gr_tech.do_hier, drivers, loads,
			  fanios, preroute_pin_walker, NULL);

  // steiner route it, if cmd == 1 then route.
  while (steiner_get_route_seg(NULL, cmd, &(pt1.x), &(pt1.y), 
			       &(pt2.x), &(pt2.y), NULL, NULL) > 0) {

    //PRINTF ("\t\t --> %d %d %d %d\n", pt1.x, pt1.y, pt2.x, pt2.y);
    //PRINTF ("\t\t g --> %d %d %d %d\n", (int) x_adjust(pt1.x), (int) y_adjust(pt1.y), (int) x_adjust(pt2.x), (int) y_adjust(pt2.y));

    //    pt1.x = x_adjust(pt1.x);
    //    pt1.y = y_adjust(pt1.y);
    //    pt2.x = x_adjust(pt2.x);
    //    pt2.y = y_adjust(pt2.y);

    if ( pt1.x == pt2.x && pt1.y == pt2.y ) {
      
      // add route here since same grid
      gr_pgrid[twod(pt1.x,pt1.y)].h += BEF;
      gr_pgrid[twod(pt1.x,pt1.y)].v += BEF;

    } else {

      //PRINTF ("\t\t e --> %d %d %d %d\n", pt1.x, pt1.y, pt2.x, pt2.y);

      // remember this segment for later routing
      segment = GR_MALLOC(sizeof(grSegment));
      segment->pt1 = pt1;
      segment->pt2 = pt2;
      segment->pt1_status = route_type;
      segment->routed = FALSE;

      slink = GR_MALLOC(sizeof(grSLink));      
      slink->segment = segment;
      slink->next = gr_unrouted_list;
      gr_unrouted_list = slink;

      // add to the probability grid
      add_prob_reduced (&pt1, &pt2, ADD, route_type);

      if ( route_type == ROUTE_START ) {
#if DO_ROUTE_START
	route_type = ROUTE_CONT;
#endif
      }

      if (cmd==1) { gr_tech.num_nets++; }
      gr_tech.num_segments++;
    }

    // so subsequent calls just return next segment
    cmd = 0;
  }

  return nl_walk_status_continue;
}


// This should be built into nl.
static int gr_nl_obj_location(nl_object whatever, int *px, int *py)
{
  switch (nl_object_kind(whatever)) {

  case nl_kind_pin: {
    nl_pin pin = (nl_pin) whatever;
    nl_object owner = (nl_object) nl_pin_owner((nl_pin)whatever);

    // port or cell
    switch (nl_object_kind(owner)) {
    case nl_kind_port: {
      pnl_port pport;
      nl_port_attr_get_by_name ("pnl port", (nl_port)owner, &pport);
      if (! pnl_port_has_location (pport) ) {return 0;}
      pnl_port_get_location (pport, px, py);
      return 1;
    }
    case nl_kind_cell: {
      // for now, just get coords of cell pin is in
      pnl_cell pcell;
      nl_cell_attr_get_by_name ("pnl cell", (nl_cell) owner, &pcell);

      if (!pnl_cell_has_location (pcell) ) {return 0;}
      pnl_cell_get_pin_location (pcell, pin, px, py);
      return 1;
    }
    default: assert(0);
    }
  }

  case nl_kind_ipin: {
    nl_ipin ipin = (nl_ipin) whatever;
    // iport or icell
    nl_object owner = (nl_object) nl_ipin_owner((nl_ipin)whatever);

    switch (nl_object_kind(owner)) {
    case nl_kind_iport: {
      pnl_port pport;
      nl_port port = nl_iport_port ((nl_iport) owner);
      nl_port_attr_get_by_name ("pnl port", port, &pport);

      if (!pnl_port_has_location (pport) ) {return 0;}
      pnl_port_get_location (pport, px, py);
      return 1;
    }
    case nl_kind_icell: {
      // for now, just get coords of cell pin is in
      pnl_icell pcell;
      nl_pin pin = nl_ipin_pin (ipin);

      // get location of pin
      nl_icell_attr_get_by_name ("pnl icell", (nl_icell) owner, &pcell);

      if (!pnl_icell_has_location (pcell) ) {return 0;}
      pnl_icell_get_pin_location (pcell, pin, px, py);
      return 1;
    }
    default: assert(0);
    }
  }

  default: assert(0);
  }
}

#if USE_MAX
// Find a label in a max cell.
static Rect gr_max_label_rect;
static int gr_max_label_callback(SearchContext *scx, Rect *rect, char *name, Label *label, ClientData cdarg)
{
  gr_max_label_rect = *rect;
  return 1;	// Terminate search when first label found.
}

// Note: DFFix* procedures will be defined elsewhere after max is recompiled.
static char *DFFixLabelName(char *buf,char *name)
{
    // Max supports any names now.
    return strcpy(buf,name);
#if 0
    char *cp, *bp = buf;
    for (cp = name; *cp; cp++) {
      switch (*cp) {
            case '\\': strcpy(bp,"{BS}"); bp+= 4; break;
            default: *bp++ = *cp; break;
        }
    }
    *bp = 0;
    return buf;
#endif
}

static char * DFFixName(char *buf,char *name)
{
    // Max supports any names now.
    return strcpy(buf,name);
#if 0
    char *cp, *bp = buf;

    for (cp = name; *cp; cp++) {
      switch (*cp) {
            case '\\': strcpy(bp,"{BS}"); bp+= 4; break;
            case '/':  strcpy(bp,"{FS}"); bp+= 4; break;
            case '[':  strcpy(bp,"{LB}"); bp+= 4; break;
            case ']':  strcpy(bp,"{RB}"); bp+= 4; break;
            case ',':  strcpy(bp,"{CO}"); bp+= 4; break;
            case '{':  strcpy(bp,"{LC}"); bp+= 4; break;
            case '}':  strcpy(bp,"{RC}"); bp+= 4; break;
            default: *bp++ = *cp; break;
        }
    }
    *bp = 0;
    return buf;
#endif
}
#endif


// process each pin in a given net
// pat modified to work for hierarchical/non-hierarchical, but did not test hierarchical using nl, only using max.
static nl_walk_status preroute_pin_walker (nl_object pin_or_ipin, int *null_ptr)
{
  int x, y, xg, yg;
  char dir, *cell_name, *pin_name;
  char empty[] = "";
  nl_direction direction;

  // find type and coords of pin

  switch (nl_object_kind(pin_or_ipin)) {

  case nl_kind_pin: {
    nl_pin pin = (nl_pin) pin_or_ipin;
    nl_object owner = (nl_object) nl_pin_owner(pin); // port or cell

    direction = nl_pin_direction(pin);
    pin_name = nl_pin_name(pin);

    switch (nl_object_kind(owner)) {
    case nl_kind_port:
      cell_name = empty;
      break;
    case nl_kind_cell:
      cell_name = nl_cell_name( (nl_cell) owner );
      break;
    default:
      assert(0);
    }

    break;
  }

  case nl_kind_ipin: {
    // for now, just get coords of cell pin is in
    nl_ipin ipin = (nl_ipin) pin_or_ipin;
    nl_object owner = (nl_object) nl_ipin_owner (ipin); // iport or icell

    direction = nl_ipin_direction (ipin);
    pin_name = nl_ipin_name(ipin);

    switch (nl_object_kind(pin_or_ipin)) {
    case nl_kind_iport:
      cell_name = empty;
      break;
    case nl_kind_icell:
      cell_name = nl_icell_name( (nl_icell) owner );
    default:
      assert(0);
    }

    break;
  }

  default:
    assert(0);
  }

#if USE_MAX
  if (cell_name[0]) {
    CellDef *def;  CellUse *use; Rect r;
    char buf[3000];

    def = DBCellLookDef(DFFixName(buf,nl_design_name(gr_design)));
    if (def == NULL) {
      ERRORF("error: can not find MAX top-level cell named %s\n",nl_design_name(gr_design));
      return nl_walk_status_continue;
    }

    use = DBInstanceFindByName(DFFixName(buf,cell_name),def);
    if (use == NULL) {
      PRINTF("warning: Can not find MAX instance %s in cell %s\n",cell_name,def->cd_name);
      return nl_walk_status_continue;
    }

    if (! DBLabelFindByPathName(use,DFFixLabelName(buf,pin_name),gr_max_label_callback,0,0)) {
      PRINTF("warning: Can not find MAX label %s in cell %s\n",pin_name,cell_name);
    }
    GeoTransRect(&use->cu_transform,&gr_max_label_rect,&r);
    x = r.r_xbot;
    y = r.r_ybot;
    // printf("pin %s:%s at %d %d\n",cell_name,pin_name,x,y);
  } else {
    // Its a label!
    if (! DBLabelFindByPathName(EditCellUse,pin_name,gr_max_label_callback,0,0)) {
      PRINTF("warning: Can not find MAX label %s in cell %s\n",pin_name,EditCellUse->cu_def->cd_name);
    }
    x = gr_max_label_rect.r_xbot;
    y = gr_max_label_rect.r_ybot;
    // printf("port %s at %d %d\n",pin_name,x,y);
  }
#else
  if (! gr_nl_obj_location(pin_or_ipin,&x,&y)) {
    // No location information for this pin or ipin.
    if (cell_name[0]) {
      gr_tech.cell_unplaced++; // It was a pin on a cell.
    } else {
      gr_tech.pin_unplaced++; // It was a top-level port, variable name notwithstanding.
    }
    return nl_walk_status_continue;
  }
#endif

  switch (direction) {
  case nl_direction_in: dir = 'I'; break;
  case nl_direction_out: dir = 'O'; break;
  case nl_direction_inout: dir = 'B'; break;
  default: dir = 'B';
  }

  //>PRINTF ("\t%s %s --> %d, %d (%c)\n", cell_name, pin_name, x, y, dir);

  // scaled x,y to ggrids
  xg = x_adjust(x);
  yg = y_adjust(y);

  if ( xg < 0 || xg >= gr_tech.xdim || yg < 0 || yg >= gr_tech.ydim ) {
    // error
    PRINTF("Error: %s is outside of routing grid (%d, %d), ignoring.\n",
	    pin_name, xg, yg);

  } else {
    // add to steiner route
    // NOTE: coords need to be integers
    // name is not hierarchical name but shouldn't matter except for dspf
    steiner_add_point(NULL, xg, yg, cell_name, pin_name, dir);
  }

  return nl_walk_status_continue;
}


static void route ()
{
  static int route_int(double mult);

  //double mult[] = {0.001, 0.1, 0.2, 0.5, 1.0, 2.0, 10.0, 100.0};

  double mult[] = {0.01, 0.1, 0.3, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 5.0, 10.0, 100.0};
  int max_passes = 14;

  int pass;

  for ( pass = 0 ; pass < max_passes ; pass++ ) {

    gr_tech.v_limit = gr_tech.v_rsrc * mult[pass];
    gr_tech.h_limit = gr_tech.h_rsrc * mult[pass];

    //PRINTF ("limits --> h=%g v=%g\n", gr_tech.h_limit, gr_tech.v_limit);

    if ( route_int (mult[pass]) ) {
      // done
      PRINTF ("Route Completed in %d passes.\n", pass + 1);

      if ( gr_tech.pin_unplaced > 0 || gr_tech.cell_unplaced > 0 ) {
	PRINTF("Route WARNING: %d pins and %d cells unplaced (i.e., not included in route).\n", gr_tech.pin_unplaced, gr_tech.cell_unplaced);
      }

      break;
    }
  }
}


static int route_int (double mult)
{

  int h_route, v_route;

  int total = 0;
  int routed = 0;
  int routed_this_pass = 0;
  int total_this_pass = 0;

  grSegment *segment;
  grSLink *slink;

  // walk through all segments -- could remove routed
  for (slink = gr_unrouted_list ; slink != NULL ; slink = slink->next) {
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
      PRINTF("%d %d --> %d %d ROUTED: h=%d, v=%d\n", segment->pt1.x, 
	     segment->pt1.y, segment->pt2.x, segment->pt2.y, h_route, v_route);
      */

      if ( h_route == SUCCEED || v_route == SUCCEED) {
	// success, mark this as routed
	segment->routed = 1;
	routed++;
	routed_this_pass++;

	//PRINTF("%d %d --> (%d %d %d %d) ROUTED: h=%d, v=%d\n", abs(segment->pt2.x - segment->pt1.x), abs(segment->pt2.y - segment->pt1.y), segment->pt1.x, segment->pt1.y, segment->pt2.x, segment->pt2.y, h_route, v_route);

      }
    }

  }

  PRINTF("Routed %d/%d segments this pass (%g), total routed %d/%d.\n",
    routed_this_pass, total_this_pass, mult, routed, total);
  //PRINTF ("limits %g %g\n", gr_tech.v_limit, gr_tech.h_limit);

  if ( routed == total ) {
    // done
    return 1;

  } else {
    return 0;
  }
}


static void show_grid (grGrid *grid)
{

  int i,j;

  if ( 1 || gr_tech.xdim > 20 ) {

      if ( gr_tech.ydim < 20 ) {
	// rotate
	PRINTF("rotated-------------- horizontal -------------------------\n");
	for (j = 0 ; j < gr_tech.xdim ; j++) {
	  for (i = 0; i < gr_tech.ydim ; i++) {
	    if ( fabs(grid[twod(j,i)].h) < 0.01 ) {
	      PRINTF("%5.2g ", 0.0);
	    } else {
	      PRINTF("%5.2g ", grid[twod(j,i)].h);
	    }
	  } 
	  PRINTF("\n");
	}

	PRINTF("rotated-------------- vertical -------------------------\n");
	for (j = 0 ; j < gr_tech.xdim ; j++) {
	  for (i = 0; i < gr_tech.ydim ; i++) {
	    if ( fabs(grid[twod(j,i)].v) < 0.01 ) {
	      PRINTF("%5.2g ", 0.0);
	    } else {
	      PRINTF("%5.2g ", grid[twod(j,i)].v);
	    }
	  } 
	  PRINTF("\n");
	}
      }

    // skip if big
    return;
  }

  PRINTF("-------------- horizontal -------------------------\n");
  for (j = gr_tech.ydim-1; j >= 0 ; j--) {
    for (i = 0; i < gr_tech.xdim ; i++) {
      if ( fabs(grid[twod(i,j)].h) < 0.01 ) {
	PRINTF("%5.2g ", 0.0);
      } else {
	PRINTF("%5.2g ", grid[twod(i,j)].h);
      }
    } 
    PRINTF("\n");
  }

  PRINTF("-------------- vertical -------------------------\n");
  for (j = gr_tech.ydim-1; j >= 0 ; j--) {
    for (i = 0; i < gr_tech.xdim ; i++) {
      if ( fabs(grid[twod(i,j)].v) < 0.01 ) {
	PRINTF("%5.2g ", 0.0);
      } else {
	PRINTF("%5.2g ", grid[twod(i,j)].v);
      }
    } 
    PRINTF("\n");
  }
}


// setup technology constraints

static int init_tech(int ggrid_x, int ggrid_y)
{
  int retval;
  grRect track_area;	// Area of routing area of first layer found in nl/DEF TRACK statements.

  memset(&gr_tech,0,sizeof(gr_tech));

  // should read units line
  gr_tech.units = 1000;
  gr_tech.ggrid_x = ggrid_x;
  gr_tech.ggrid_y = ggrid_y;

#if USE_MAX
  gr_tech.do_hier = 0;
#else
  gr_tech.do_hier = 1;
#endif
  return 0;
}


// Parse tokens separated by any of the chars in sepchars.
// Return one token at a time in buf.
// Advance pointer pline to point past returned token, so pline
// is typically passed unchanged to parse_tokens until it returns NULL.
// Return NULL when all tokens have been returned.
static char *parse_tokens(char *buf,char **pline,char *sepchars)
{
    char *bp = buf, *lp = *pline;
    while (*lp && (strchr(sepchars,*lp))) {lp++;}
    if (*lp == 0) return NULL;
    while (*lp && !strchr(sepchars,*lp)) {
	*bp++ = *lp++;
    }
    *bp = 0;
    *pline = lp;
    return buf;
}


#define GR_LAYER_NAME_LEN 30
#define GR_MAX_TRACKS 50
#define GR_HORIZONTAL 1
#define GR_VERTICAL 2
typedef struct s_grWireTrack {
    char grLayer[GR_LAYER_NAME_LEN+2];	// layer name
    int grPitch;	// wire pitch in nanons
    int grDir;		// 0 = horizontal, 1 == vertical
    int grStart;	// Starting location in nanons
    int grEnd;		// Ending location in nanons (-1)
} grWireTrack;

static grWireTrack gr_wire_tracks[GR_MAX_TRACKS];
int gr_wire_track_count;


static int add_track(pnl_tracks tracks, int dir) {
    int i;
    grWireTrack *wtp;
    ar layerlist = pnl_tracks_layers(tracks);
    char **ptr = ar_data(layerlist);
    for (i = ar_size(layerlist); i > 0; i--,ptr++) {

      if (gr_wire_track_count >= GR_MAX_TRACKS) {
	  ERRORF("error: too many wire tracks\n");
	  return 1;
      }
      if (strlen(*ptr) >= GR_LAYER_NAME_LEN) {
	  ERRORF("error: layer name too long: %s\n",*ptr);
	  return 1;
      }

      wtp = &gr_wire_tracks[gr_wire_track_count++];
      strcpy(wtp->grLayer,*ptr);
      wtp->grDir = dir;
      wtp->grPitch = pnl_tracks_step(tracks);
      wtp->grStart = pnl_tracks_start (tracks);
      wtp->grEnd = wtp->grStart + (pnl_tracks_count(tracks) * wtp->grPitch) - 1;

    }
    return 0;
}


// Snarf the wiring data from nl into our own data-base.
// We are assuming that there is only one rectangular track data
// for each layer.  Some errors are reported, but currently do not abort.
static int load_track_data(nl_design design)
{
  pnl_design pdesign;
  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  gr_wire_track_count = 0;

  pnl_design_for_all_x_tracks (pdesign, tracks) {
    add_track(tracks,GR_VERTICAL);
  } pnl_end_for;

  pnl_design_for_all_y_tracks (pdesign, tracks) {
    add_track(tracks,GR_HORIZONTAL);
  } pnl_end_for;
}


// Return wire track data for layer, or NULL if not found.
static grWireTrack *gr_find_layer(char *layername,int dir) {
  int i;
  grWireTrack *wtp = &gr_wire_tracks[0];
  for (i = 0; i < gr_wire_track_count; i++, wtp++) {
    if (dir == wtp->grDir && strcasecmp(layername,wtp->grLayer) == 0) {
      return wtp;
    }
  }
  return NULL;
}


// Compute the global grid dimensions using the specified area and gr_tech.grid_x/y.
static tech_finish(grRect *area)
{
  int tmp;

  gr_tech.grid_area = *area;

  gr_tech.xdim = ceil(1.0*area->x2 / gr_tech.grid_x) - gr_tech.offset_x + 1;
  gr_tech.offset_x = floor( 1.0*area->x1 / gr_tech.grid_x );

  tmp = ((area->x1 < 0) ? -area->x1 : gr_tech.grid_x - area->x1) % gr_tech.grid_x;
  gr_tech.left_frac = tmp ? (double)tmp/gr_tech.grid_x : 1.0;
  tmp = ((area->x2+1 < 0) ? gr_tech.grid_x + area->x2+1 : (area->x2+1)) % gr_tech.grid_x;
  gr_tech.right_frac = tmp ? (double)tmp/gr_tech.grid_x : 1.0;

  gr_tech.ydim = ceil(1.0*area->y2 / gr_tech.grid_y) - gr_tech.offset_y + 1;
  gr_tech.offset_y = floor( 1.0*area->y1 / gr_tech.grid_y );

  tmp = ((area->y1 < 0) ? -area->y1 : gr_tech.grid_y - area->y1) % gr_tech.grid_y;
  gr_tech.bottom_frac = tmp ? (double)tmp/gr_tech.grid_y : 1.0;
  tmp = ((area->y2+1 < 0) ? gr_tech.grid_y + area->y2+1 : (area->y2+1)) % gr_tech.grid_y;
  gr_tech.top_frac = tmp ? (double)tmp/gr_tech.grid_y : 1.0;
}


// return non-zero on error;
static int init_tracks(nl_design design,char *hlayers,char *vlayers, grRect *track_area)
{
  error_catch {
    char layerbuf[1000], *list;
    int cnt;
    grWireTrack *wtp;


    load_track_data(design);

    cnt = 0;
    gr_tech.h_rsrc = 0;
    for (list = hlayers; parse_tokens(layerbuf,&list," ,"); ) {
      wtp = gr_find_layer(layerbuf,GR_HORIZONTAL);
      if (wtp == NULL) {
	ERRORF("error: horizontal wire layer %s not found or not horizontal\n",layerbuf);
	return 1;
      }
      if (cnt++ == 0) {
	// first layer is used to calculate default area,
	// and to calculate size of global grid units
	// from number of tracks specified by user.

	// Compute size of global grid from user specified ggrid_x on this layer.
	gr_tech.grid_x = wtp->grPitch * gr_tech.ggrid_x;

	track_area->x1 = wtp->grStart;
	track_area->x2 = wtp->grEnd;
      }

      // Add up available resources (tracks) on this layer inside a global routing grid.
      // This need not be integral!
      gr_tech.h_rsrc += gr_tech.grid_x / wtp->grPitch;
    }

    cnt = 0;
    gr_tech.v_rsrc = 0;
    for (list = vlayers; parse_tokens(layerbuf,&list," ,"); ) {
      wtp = gr_find_layer(layerbuf,GR_VERTICAL);
      if (wtp == NULL) {
	ERRORF("error: vertical wire layer %s not found, or not vertical\n",layerbuf);
	return 1;
      }
      if (cnt++ == 0) {
	gr_tech.grid_y = wtp->grPitch * gr_tech.ggrid_y;
	track_area->y1 = wtp->grStart;
	track_area->y2 = wtp->grEnd;
      }

      gr_tech.v_rsrc += gr_tech.grid_y / wtp->grPitch;
    }
  }
  error_on_error {
    ERRORF("ERROR: %s\n", error_message);
    return 1;
  }
  error_end;

  return 0;
}


#if 0
// Use the track data on any one of the layers specified by the hlayer and vlayer.
// If hlayer, vlayer are NULL, use the LAST layer found in the track data.
static int init_die (nl_design design,char *hlayers, char *vlayers)
{
  pnl_design pdesign;
  char *layers, *list1, *list2;
  char buf1[1000], buf2[1000];

  int x1, y1, x2, y2;
  int fnd, start, end, count;

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  // TODO: This is NOT USED!!!  Why bother to get it?
  if ( ! pnl_design_get_die_area (pdesign, &x1, &y1, &x2, &y2) ) {
    ERRORF("No die area in def file.\n");
    return TCL_ERROR;
  }

  // PRINTF ("\t\t diearea --> %d %d %d %d\n",x1,y1,x2,y2);

  // TODO: assumes only one x and one y for now
  fnd = 0;
  pnl_design_for_all_x_tracks (pdesign, tracks) {

    // layers --> ar_size(pnl_tracks_layers (tracks));

    if (hlayers) {
	layers = (char*)pnl_tracks_layers(tracks);
	// See if any of hlayers are in layers.
	for (list1 = layers; parse_tokens(buf1,&list1," "); ) {
	    for (list2 = hlayers; parse_tokens(buf2,&list2," ,"); ) {
		if (strcasecmp(buf1,buf2) == 0) {
		    fnd = 1; break;
		}
	    }
	}
	if (!fnd) continue;
    }

    // Pitch of this routing track in nanons.
    gr_tech.rgrid_x = pnl_tracks_step (tracks);

    // Left boundary of routing area in tracks.
    // It is relative to the origin, so it might be negative.
    start = floor( 1.0 * pnl_tracks_start (tracks) / gr_tech.rgrid_x );
    count = pnl_tracks_count(tracks) - 1;
    // Right boundary of routing area in tracks.
    end = count + start;

    // offset in ggrids (global routing box units)
    gr_tech.offset_x = floor( 1.0*start / gr_tech.ggrid_x );

    gr_tech.xdim = end / gr_tech.ggrid_x - gr_tech.offset_x + 1;

    gr_tech.left_size = ( gr_tech.ggrid_x - start ) % gr_tech.ggrid_x;
    gr_tech.right_size = end % gr_tech.ggrid_x;
    fnd = 1;

    //PRINTF ("%d %d -> %d  offset = %d, xdim = %d edges = %d, %d\n", start, count, end, gr_tech.offset_x, gr_tech.xdim, gr_tech.left_size, gr_tech.right_size);

  } pnl_end_for;

  if (! fnd) {
    if (hlayers) {
	ERRORF("Layer(s) %s not found in horizontal track data\n",hlayers);
    } else {
	ERRORF("No horizontal layer found in track data\n");
    }
    return TCL_ERROR;
  }

  fnd = 0;
  pnl_design_for_all_y_tracks (pdesign, tracks) {

    // layers --> ar_size(pnl_tracks_layers (tracks));
    if (vlayers) {
	layers = (char*)pnl_tracks_layers(tracks);
	// See if any of vlayers are in layers.
	for (list1 = layers; parse_tokens(buf1,&list1," "); ) {
	    for (list2 = vlayers; parse_tokens(buf2,&list2," ,"); ) {
		if (strcasecmp(buf1,buf2) == 0) {
		    fnd = 1; break;
		}
	    }
	}
	if (!fnd) continue;
    }

    gr_tech.rgrid_y = pnl_tracks_step (tracks);

    start = floor( 1.0 * pnl_tracks_start (tracks) / gr_tech.rgrid_y );
    count = pnl_tracks_count(tracks) - 1;
    end = count + start;

    // offset in ggrids
    gr_tech.offset_y = floor( 1.0*start / gr_tech.ggrid_y );

    gr_tech.ydim = end / gr_tech.ggrid_y - gr_tech.offset_y + 1;

    gr_tech.bottom_size = ( gr_tech.ggrid_y - start ) % gr_tech.ggrid_y;
    gr_tech.top_size = end % gr_tech.ggrid_y;

    //PRINTF ("%d %d -> %d  offset = %d, ydim = %d, edges = %d, %d\n", start, count, end, gr_tech.offset_y, gr_tech.ydim, gr_tech.bottom_size, gr_tech.top_size);
    fnd = 1;

  } pnl_end_for;

  if (! fnd) {
    if (vlayers) {
	ERRORF("Layer(s) %s not found in vertical track data\n",vlayers);
    } else {
	ERRORF("No vertical layer found in track data\n");
    }
    return TCL_ERROR;
  }

  // multiplier to get global grids from millimicrons
  gr_tech.grid_x = gr_tech.rgrid_x * gr_tech.ggrid_x;
  gr_tech.grid_y = gr_tech.rgrid_y * gr_tech.ggrid_y;

  return TCL_OK;
}
#endif


// initialize the grid.

static void init_grid (grGrid *grid)
{
  int i,j;

  // initialize
  for (i = 0; i < gr_tech.xdim ; i++) {
    for (j = 0; j < gr_tech.ydim ; j++) {
      grid[twod(i,j)].h = 0.0;
      grid[twod(i,j)].v = 0.0;
    }
  }
}


// fix up partial edge ggrids
// obstruct the edge grids by an amount that corresponds to the fraction of the edge they cover.
static void fix_edge_grids (grGrid *grid, int function)
{
  int i,j,value;

  // remove resources for edge cells

  // bottom edge
  if ( gr_tech.bottom_frac != 1.0 ) {
    j = 0;
    //value = (gr_tech.ggrid_y - gr_tech.bottom_size) * gr_tech.h_rsrc_track * function;
    value = (1-gr_tech.bottom_frac) * gr_tech.h_rsrc * function;
    for (i = 0; i < gr_tech.xdim ; i++) {
      grid[twod(i,j)].h += value;
    }
  }

  // top edge
  if ( gr_tech.top_frac != 1.0 ) {
    j = gr_tech.ydim - 1;
    //value = (gr_tech.ggrid_y - gr_tech.top_size) * gr_tech.h_rsrc_track * function;
    value = (1-gr_tech.top_frac) * gr_tech.h_rsrc * function;
    for (i = 0; i < gr_tech.xdim ; i++) {
      grid[twod(i,j)].h += value;
    }
  }

  // left edge
  if ( gr_tech.left_frac != 1.0 ) {
    i = 0;
    //value = (gr_tech.ggrid_x - gr_tech.left_size) * gr_tech.v_rsrc_track * function;
    value = (1-gr_tech.left_frac) * gr_tech.v_rsrc * function;
    for (j = 0; j < gr_tech.ydim ; j++) {
      grid[twod(i,j)].v += value;
    }
  }

  // right edge
  if ( gr_tech.right_frac != 1.0 ) {
    i = gr_tech.xdim - 1;
    //value = (gr_tech.ggrid_x - gr_tech.right_size) * gr_tech.v_rsrc_track * function;
    value = (1-gr_tech.right_frac) * gr_tech.v_rsrc * function;
    for (j = 0; j < gr_tech.ydim ; j++) {
      grid[twod(i,j)].v += value;
    }
  }
}


static dump_grid(char *msg,char *mode) {
    int g_i, g_j;
    FILE *pf = fopen("__congestion_grid_dump__",mode);
    fprintf(pf,"%s\n",msg);
    fprintf(pf,"offsets: %d %d\n",gr_tech.offset_x,gr_tech.offset_y);
    for (g_i = 0; g_i < gr_tech.xdim; g_i++) {
	for (g_j = 0; g_j < gr_tech.ydim; g_j++) {
	  int bin = twod(g_i,g_j);
	  int ggx = gr_tech.offset_x + g_i;	// global grid coord using origin of original cell.
	  int ggy = gr_tech.offset_y + g_j;
	  int congh = gr_cong_grid ? gr_cong_grid[bin].hblock : 0;
	  int congv = gr_cong_grid ? gr_cong_grid[bin].vblock : 0;
	  fprintf(pf,"%d %d at %g %g: %g %g %g %g\n",g_i,g_j,
		ggx * gr_tech.grid_x / 1000.0, ggy * gr_tech.grid_y / 1000.0,
		gr_pgrid[bin].h,gr_pgrid[bin].v, congh, congv);
	}
    }
    fclose(pf);
}

static void fix_blockages(int function) {
    int grid_i, grid_j;

    if (gr_cong_grid == NULL) return;

    // add blockages into probability grid
    for (grid_i = 0; grid_i < gr_tech.xdim; grid_i++) {
	for (grid_j = 0; grid_j < gr_tech.ydim; grid_j++) {
	  int bin = twod(grid_i,grid_j);
	  if (function == ADD) {
	    gr_pgrid[bin].h += gr_cong_grid[bin].hblock;
	    gr_pgrid[bin].v += gr_cong_grid[bin].vblock;
	  } else {
	    gr_pgrid[bin].h -= gr_cong_grid[bin].hblock;
	    gr_pgrid[bin].v -= gr_cong_grid[bin].vblock;
	  }
	}
    }
}


static void route_stats (grGrid *grid)
{
  int i, j;
  int h, v;
  int max_congestion_h = 0;
  int max_congestion_v = 0;
  int max_congestion = 0;

  double h_tot_r = 0;
  double v_tot_r = 0;
  double h_tot_s = 0;
  double v_tot_s = 0;
  int histogram[1000];

  grSegment *segment;
  grSLink *slink;
#if USE_MAX
  char *cellname = EditCellUse->cu_def->cd_name;
#else
  char *cellname = "sue_global_router";  // TODO:  Lee, what is the file name?
#endif
  char filename[1100];

  FILE *pf = fopen(strcat(strcpy(filename,cellname),".congestion_report"),"w");

  if (pf == NULL) {
    PRINTF("warning: Could not open congestion report file: %s\n",filename);
    return;
  }
  PRINTF("Writing congestion report to file: %s\n",filename);

  fprintf(pf,"Routing report for %s\n",cellname);
  { time_t now; char buf[1002];
    time(&now);
    fprintf(pf,"Date: %s",ctime(&now));  // ctime adds a newline
    getcwd(buf,1000);
    fprintf(pf,"Directory: %s\n\n",buf);
  }
  fprintf(pf,"Routing area is %g,%g to %g,%g\n",
	      gr_tech.grid_area.x1/1000.0,gr_tech.grid_area.y1/1000.0,
	      gr_tech.grid_area.x2/1000.0,gr_tech.grid_area.y2/1000.0);
  fprintf(pf,"Built %d X %d global route grid.  Each grid is %d X %d tracks = %g X %g microns.\n",
	      gr_tech.xdim, gr_tech.ydim, gr_tech.ggrid_x, gr_tech.ggrid_y,
	      gr_tech.grid_x/1000.0, gr_tech.grid_y/1000.0);
  fprintf(pf,"There are %g horizontal and %g vertical routing resources in each grid\n",
	      gr_tech.h_rsrc, gr_tech.v_rsrc);
  fprintf(pf,"Edge grid utilizations are: left=%g right=%g top=%g bottom=%g\n",
	      gr_tech.left_frac, gr_tech.right_frac,gr_tech.top_frac,gr_tech.bottom_frac);

  for (i = 0; i < 1000 ; i++) { histogram[i] = 0; }

  // routed length
  for (i = 0; i < gr_tech.xdim ; i++) {
    for (j = 0; j < gr_tech.ydim ; j++) {
      h_tot_r += grid[twod(i,j)].h;
      v_tot_r += grid[twod(i,j)].v;

      h = (int) ceil(grid[twod(i,j)].h - 0.0001);
      v = (int) ceil(grid[twod(i,j)].v - 0.0001);

      //fprintf(pf,"%g %g %d %d\n", grid[twod(i,j)].h, grid[twod(i,j)].v, h, v);

      histogram[ min(999,max (h,v)) ] += 1;

      max_congestion_h = max (max_congestion_h, h);
      max_congestion_v = max (max_congestion_v, v);
    }
  }

  // segment lengths
  for (slink = gr_unrouted_list ; slink != NULL ; slink = slink->next) {
    segment = slink->segment;

    // add extra for endpoints
    h_tot_s += abs(segment->pt1.x - segment->pt2.x) + 0.5;
    v_tot_s += abs(segment->pt1.y - segment->pt2.y) + 0.5;
  }

  fprintf(pf,"Routed %d nets and %d segments\n", gr_tech.num_nets, gr_tech.num_segments);
  fprintf(pf,"Total wire length: steiner = %g, global router = %g\n", 
	  h_tot_s * gr_tech.ggrid_x + v_tot_s * gr_tech.ggrid_y / gr_tech.units,
	  h_tot_r * gr_tech.ggrid_x + v_tot_r * gr_tech.ggrid_y / gr_tech.units);

  max_congestion = max( max_congestion_h, max_congestion_v);

  if (1) {
    // histogram
    int per_row = 16;
    fprintf(pf,"\nHistogram:\n");
    for (j = 0; j <= max_congestion; j += per_row) {
	for (i = 0; i < per_row && i+j <= max_congestion; i++) {
	  fprintf(pf,"%4d ", i+j);
	}
	fprintf(pf,"\n");

	for (i = 0; i < per_row && i+j <= max_congestion ; i++) {
	  fprintf(pf,"==== ");
	}
	fprintf(pf,"\n");

	for (i = 0; i < per_row && i+j <= max_congestion ; i++) {
	  fprintf(pf,"%4d ", histogram[i+j]);
	}
	fprintf(pf,"\n\n");
    }
  }

  fprintf(pf,"Maximum congestion: %d  (%g%% vertical, %g%% horizontal def/layout direction)\n", 
	  max_congestion, 100.0*max_congestion_v/gr_tech.v_rsrc, 
	  100.0*max_congestion_h/gr_tech.h_rsrc);

  // Compute IBM style congestion number.
  // Percentage congestion in top 20% of congested bins.
  { int i;
    int total_grids = 0;
    int grids_seen = 0;
    int congestion_seen = 0;
    for (i = 0; i <= max_congestion; i++) {
	total_grids += histogram[i];
    }
    for (i = max_congestion; i >= 0; i--) {
	congestion_seen += i * histogram[i];
	grids_seen += histogram[i];
	if (grids_seen >= total_grids * 0.2) break;
    }
    fprintf(pf,"IBM-Compatible Congestion Factor = %.1f%%\n",
	100.0 * congestion_seen/grids_seen/gr_tech.v_rsrc);
  }
  fclose(pf);
}

static gr_free_stuff() {
    grSLink *foo;
    while ((foo = gr_unrouted_list) != NULL) {
	gr_unrouted_list = gr_unrouted_list->next;
	GR_FREE(foo->segment);
	GR_FREE(foo);
    }

    if (gr_pgrid) { GR_FREE(gr_pgrid); }
    if (gr_cong_grid) { GR_FREE(gr_cong_grid); }
    gr_pgrid = NULL;
    gr_cong_grid = NULL;
}


#if 0
// Old Tcl entry point for global router.
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
  int code, show;
  double v_rsrc_track, h_rsrc_track;
  int ggrid_x, ggrid_y;

  gr_design = (nl_design) ui_obj_get_nl_object (objv[1]);

  //volatile mem_group prev_group;

  // print debugging info
  code = Tcl_GetIntFromObj(interp, objv[6], &show);
  if (code != TCL_OK) return code;

  // skip setup if show==3.  Already done and blockages added
  if ( show != 3 ) {

    // global route grid size in routing grids
    code = Tcl_GetIntFromObj(interp, objv[2], &ggrid_x);
    if (code != TCL_OK) return code;

    code = Tcl_GetIntFromObj(interp, objv[3], &ggrid_y);
    if (code != TCL_OK) return code;

    // routing resource per track
    code = Tcl_GetDoubleFromObj(interp, objv[4], &v_rsrc_track);
    if (code != TCL_OK) return code;

    code = Tcl_GetDoubleFromObj(interp, objv[5], &h_rsrc_track);
    if (code != TCL_OK) return code;

    //if ( gr_group == NULL ) {
    //  gr_group = mem_group_create ("gr", 8);
    //}

    // free from previous
    // mem_group_free_contents (gr_group);

    gr_free_stuff();

    // change to "gr" group for alloc/free
    // prev_group = mem_group_set (gr_group);

    if ( nl_object_kind ((nl_object)gr_design) != nl_kind_design ) {
      printf ("Error: arg isn't an nl design\n");

      // mem_group_set (prev_group);
      
      return TCL_ERROR;
    }

    printf ("Global Router\n");

    // setup
    init_tech(ggrid_x, ggrid_y);
    gr_tech.v_rsrc = gr_tech.ggrid_x * v_rsrc_track;
    gr_tech.h_rsrc = gr_tech.ggrid_y * h_rsrc_track;

    gr_unrouted_list = NULL;

    error_catch {
      
      init_die(gr_design,NULL,NULL);

      gr_pgrid = GR_MALLOC(gr_tech.xdim*gr_tech.ydim*sizeof(grGrid));
      init_grid (gr_pgrid);
      printf ("Built %d X %d global route grid.  Each grid is %d X %d tracks.\n",
	      gr_tech.xdim, gr_tech.ydim, gr_tech.ggrid_x, gr_tech.ggrid_y);

      fix_edge_grids (gr_pgrid, ADD);

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

    preroute_design (gr_design);

    if (show == TRUE) {
      show_grid(gr_pgrid);
    }

    printf ("Probability Matrix built with %d nets and %d segments, Routing ...\n", gr_tech.num_nets, gr_tech.num_segments);

    route ();

    // undo edge grids so they don't look full
    fix_edge_grids (gr_pgrid, SUBTRACT);

    printf ("Route elapsed time: %d seconds\n", time((time_t *) NULL) - start);

    if (show == TRUE) {
      show_grid(gr_pgrid);
    }

    route_stats(gr_pgrid);
  }
  error_on_error {
    fprintf (stderr, "ERROR: %s", error_message);
  }
  error_end;

  printf("done.\n");

  // mem_group_set (prev_group);

  return TCL_OK;
}
#endif


// New Tcl entry point for global router.
// assumes nl is already loaded up with the design.

// Usage (from tcl): gr_command [-options] <design>
//
// -options are:
//	-grid_size_tracks <horizontal> <vertical>
//		Specifies size of global grid in number of tracks on the first
//		layer specified in -vlayer and -hlayer layer lists.
//	-area x1 y1 x2 y2
//		Specifies the area to global route in microns.  If unspecified, uses the area
//		of the first DEF track that matches the first layer specified
//		in -vlayer and -hlayer lists.  Note: does NOT use the die area!
//	-avail <horizontal> <vertical>
//		Fraction of wiring resourcase that are available.  Defaults to -avail 1.0 1.0
//		Total wiring resources per grid are calculated using all tracks
//		on the layers specified by -vlayer and -hlayer options.
//		The result is then multiplied by the -avail numbers.
//		Then if -existing_congestion, grid resources are reduced by
//		congestion from layout in max.
//		Finally, edge grids are further derated by the fraction of the
//		grid inside the global routing area.
//	-vlayer <vertical_layer_list>
//		Comma-separated list of vertical layers, eg: m2,m4
//	-hlayer <horizontal_layer_list>
//		Comma-separated list of horizontal layers, eg: m3,m5
//	-use_existing <0|1>  Add the congestion from max.
//	-cover_cell <name>   If not an empty string, add the congestion from
//		specified cover cell, which must already be loaded.
//	-debug <0|1|2|3>
// 		Dumps the grid.
//	-show 1  Lee's debug mode.
//	-partial <0|2|3>
// 		if adding blockages, call this proc with partial=2 to setup grid, 
// 		then call gr_block to add blockages, and then call with partial=3 to 
// 		route.


int
tcl_gr_command2 (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{
  // Tcl Command Options:
  struct {
      int show, partial;
      char *hlayers, *vlayers;	// Default is to use last layer in track data.
      char *cover_cell;
      int ggrid_x, ggrid_y;
      double avail_x, avail_y;
      int use_existing;
      int fnd_area;
      double area_x1, area_y1, area_x2, area_y2;
      int debug;
    } o;

  int i, j, start;
  int code;
  char *design_name;

  char *cmdName = Tcl_GetStringFromObj(objv[0],NULL);
  objc--, objv++;

  // Init options
  memset(&o,0,sizeof(o));
  o.ggrid_x = o.ggrid_y = 10;

  // Parse options.
  while (objc >= 1) {
    char *option = Tcl_GetStringFromObj(objv[0],NULL);
    if (*option == '-') {
	if (objc>=2 && strcmp(option,"-hlayer")==0) {
	    o.hlayers = Tcl_GetStringFromObj(objv[1],NULL);
	    objc-=2, objv+=2;
	    continue;
	}
	if (objc>=2 && strcmp(option,"-vlayer")==0) {
	    o.vlayers = Tcl_GetStringFromObj(objv[1],NULL);
	    objc-=2, objv+=2;
	    continue;
	}
	if (objc>=2 && strcmp(option,"-use_existing")==0) {
	    if (Tcl_GetIntFromObj(interp,objv[1],&o.use_existing) != TCL_OK) {
		expecting_number:
		ERRORF("%s: error: bad argument, expecting number\n",cmdName);
		return TCL_ERROR;
	    }
	    objc-=2, objv+=2;
	    continue;
	}
	if (objc>=2 && strcmp(option,"-cover_cell")==0) {
	    o.cover_cell = Tcl_GetStringFromObj(objv[1],NULL);
	    objc-=2, objv+=2;
	    continue;
	}
	if (objc>=2 && strcmp(option,"-partial")==0) {
	    if (Tcl_GetIntFromObj(interp,objv[1],&o.partial) != TCL_OK) {
		goto expecting_number;
	    }
	    objc-=2, objv+=2;
	    continue;
	}
	if (objc>=2 && strcmp(option,"-show")==0) {
	    if (Tcl_GetIntFromObj(interp,objv[1],&o.show) != TCL_OK) {
		goto expecting_number;
	    }
	    objc-=2, objv+=2;
	    continue;
	}
	if (objc>=3 && strcmp(option,"-grid_size_tracks")==0) {
	    // global route grid size in routing grids
	    if (Tcl_GetIntFromObj(interp, objv[1], &o.ggrid_x) != TCL_OK) {
		goto expecting_number;
	    }
	    if (Tcl_GetIntFromObj(interp, objv[2], &o.ggrid_y) != TCL_OK) {
		goto expecting_number;
	    }
	    objc-=3, objv+=3;
	    continue;
	}
	if (objc>=3 && strcmp(option,"-avail")==0) {
	    // global route grid size in routing grids
	    if (Tcl_GetDoubleFromObj(interp, objv[1], &o.avail_x) != TCL_OK) {
		goto expecting_number;
	    }
	    if (Tcl_GetDoubleFromObj(interp, objv[2], &o.avail_y) != TCL_OK) {
		goto expecting_number;
	    }
	    objc-=3, objv+=3;
	    continue;
	}
	if (objc>=5 && strcmp(option,"-area")==0) {
	    o.fnd_area = 1;
	    // global route area in microns
	    if (Tcl_GetDoubleFromObj(interp, objv[1], &o.area_x1) != TCL_OK) {
		goto expecting_number;
	    }
	    if (Tcl_GetDoubleFromObj(interp, objv[2], &o.area_y1) != TCL_OK) {
		goto expecting_number;
	    }
	    if (Tcl_GetDoubleFromObj(interp, objv[3], &o.area_x2) != TCL_OK) {
		goto expecting_number;
	    }
	    if (Tcl_GetDoubleFromObj(interp, objv[4], &o.area_y2) != TCL_OK) {
		goto expecting_number;
	    }
	    objc-=5, objv+=5;
	    continue;
	}
	if (objc>=2 && strcmp(option,"-debug")==0) {
	    if (Tcl_GetIntFromObj(interp, objv[1], &o.debug) != TCL_OK) {
		goto expecting_number;
	    }
	    objc-=2, objv+=2;
	    continue;
	}
    }
    break;
  }

  // Parse fixed arguments.
  if (objc == 0) {
    ERRORF("%s: expecting design name",cmdName);
    return TCL_ERROR;
  }
  if (objc > 1) {
    ERRORF("%s: Too many arguments.  Unrecognized: %s\n",cmdName,Tcl_GetStringFromObj(objv[0],NULL));
    return TCL_ERROR;
  }

  // The design_name may be an nl design object, or just a string design name.
  if (objv[0]->typePtr == Tcl_GetObjType("nl_object")) {
      gr_design = (nl_design) ui_obj_get_nl_object (objv[0]);
      design_name = nl_design_name(gr_design);
  } else {
      // Assume it is a string.
      design_name = Tcl_GetStringFromObj(objv[0],NULL);
      // This is temporary: Jay is adding a way to return the design given the string.
      ERRORF("%s: string design name not yet supported\n",cmdName);
      return TCL_ERROR;
  }

  //volatile mem_group prev_group;

  // skip setup if partial==3.  Already done and blockages added
  if ( o.partial != 3 ) {

    gr_free_stuff();

    if ( nl_object_kind((nl_object)gr_design) != nl_kind_design ) {
      ERRORF("Error: arg isn't an nl design\n");
      return TCL_ERROR;
    }

    PRINTF ("Global Router\n");

    // setup
    init_tech(o.ggrid_x,o.ggrid_y);

    { grRect track_area;

      if (init_tracks(gr_design,o.hlayers,o.vlayers,&track_area)) {
	// The above already printed an error
	return TCL_ERROR;
      }

      // Use either user specified or area from track data.
      if (o.fnd_area) {
	grRect area;
	area.x1 = floor(gr_tech.units * o.area_x1 + 0.5);  // rounding
	area.y1 = floor(gr_tech.units * o.area_y1 + 0.5);
	area.x2 = floor(gr_tech.units * o.area_x2 + 0.5);
	area.y2 = floor(gr_tech.units * o.area_y2 + 0.5);
	tech_finish(&area);
      } else {
	tech_finish(&track_area);
      }
    }

    gr_unrouted_list = NULL;

    gr_pgrid = GR_MALLOC(gr_tech.xdim*gr_tech.ydim*sizeof(grGrid));
    init_grid (gr_pgrid);

    fix_edge_grids (gr_pgrid, ADD);
    fix_blockages(ADD);
    
    if ( o.partial == 2 ) {
      // setup only.  User is going to add blockages and then rerun with partial=3
      return TCL_OK;
    }
  }
    if (o.debug) { dump_grid("before congestion","a"); }

#if USE_MAX
    if (o.use_existing && o.hlayers && o.vlayers) {
	int gridsize = gr_tech.xdim * gr_tech.ydim + 1;	// +1 for safety
	int grid_i, grid_j;
	Rect area;

	PRINTF("Adding Blockages...\n");

	// Set the area to search congestion to the exact
	// area used by the global router.
	// All units in nanons, luckily.
	area.r_xbot = gr_tech.offset_x * gr_tech.grid_x;
	area.r_ybot = gr_tech.offset_y * gr_tech.grid_y;
	area.r_xtop = area.r_xbot + gr_tech.xdim * gr_tech.grid_x;
	area.r_ytop = area.r_ybot + gr_tech.ydim * gr_tech.grid_y;

	// Preload the congestion grid from the current cell.
	// Determine existing congestion:
	if (spCongSearch(cmdName,EditCellUse->cu_def,&area,o.hlayers,o.vlayers,
	    gr_tech.grid_x,gr_tech.grid_y,
	    gr_tech.ggrid_x,gr_tech.ggrid_y, "_obs",1,0)) {
		ERRORF("error during congestion search\n");
		return TCL_ERROR;
	}

	if (o.cover_cell && *o.cover_cell) {
	  CellDef *coverdef = SPCellLoad(o.cover_cell);
	  if (coverdef == NULL) {
	    PRINTF("%s: warning: cover cell %s not found\n",cmdName,o.cover_cell);
	  } else {
	    if (spCongSearch(cmdName,coverdef,&area,o.hlayers,o.vlayers,
		gr_tech.grid_x,gr_tech.grid_y,
		gr_tech.ggrid_x,gr_tech.ggrid_y, "_obs",1,1)) {
		    ERRORF("error during congestion search of cover cell\n");
		    return TCL_ERROR;
	    }
	  }
	}

	gr_cong_grid = GR_MALLOC(gridsize * sizeof(grBlockage));
	memset(gr_cong_grid,0,gridsize * sizeof(grBlockage));

	for (grid_i = 0; grid_i < gr_tech.xdim; grid_i++) {
	    for (grid_j = 0; grid_j < gr_tech.ydim; grid_j++) {
		int hcongestion, vcongestion;
		spCongGet(grid_i,grid_j,&hcongestion,&vcongestion);

		// Save congestion to be subtracted out at the end.
		gr_cong_grid[twod(grid_i,grid_j)].hblock = hcongestion;
		gr_cong_grid[twod(grid_i,grid_j)].vblock = vcongestion;
	    }
	}
	spCongTerm();
    }
#endif

  // preroute and route
  error_catch {

    // remember start time
    start = time((time_t *) NULL);

    preroute_design ();

    if (o.debug & 2) { dump_grid("before routing","a"); }

    if (o.show) {
      show_grid(gr_pgrid);
    }

    PRINTF ("Probability Matrix built with %d nets and %d segments, Routing ...\n", gr_tech.num_nets, gr_tech.num_segments);

    route ();

    if (o.debug & 2) { dump_grid("after routing","a"); }

    // undo edge grids so they don't look full
    fix_edge_grids (gr_pgrid, SUBTRACT);
    fix_blockages(SUBTRACT);

    if (o.debug & 2) { dump_grid("after blockage fix up","a"); }

    PRINTF ("Route elapsed time: %d seconds\n", time((time_t *) NULL) - start);

    if (o.show) {
      show_grid(gr_pgrid);
    }

    route_stats(gr_pgrid);
  }
  error_on_error {
    ERRORF ( "ERROR: %s\n", error_message);
  }
  error_end;

  PRINTF("done.\n");

  //mem_group_set (prev_group);

  return TCL_OK;
}


// Wrap the command for max and nl, then call the real command.
// If an error occurs, return the error message from calls to ERRORF
int tcl_gr_command (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{
  int result;
  CMD_BEGIN(interp);
  error_catch {
    tcl_gr_command2 (data, interp, objc, objv);
  }
  error_on_error {
    ERRORF ( "ERROR: %s\n", error_message);
  }
  error_end;
  CMD_RETURN(interp);
}


// Set up iterator to get congestion
// Takes a vertical minimum, horizontal minimum for return
// Syntax:
//	gr_grid [-options] <vertical_minimum> <horizontal_minimum>
//	WARNING!!!!! Note that horizontal and vertical are backwards from normal.
// By default, values

static int max_c_v, max_c_h;
static int grid_i, grid_j;

int
tcl_gr_grid (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{
  int code;
  char *cmdName = Tcl_GetStringFromObj(objv[0],NULL);
  objc--; objv++;
  CMD_BEGIN(interp);

  if (objc < 2) {
    ERRORF("%s: too few args\n",cmdName);
    CMD_RETURN(interp);
  }

  code = Tcl_GetIntFromObj(interp, objv[0], &max_c_v);
  if (code != TCL_OK) return code;

  code = Tcl_GetIntFromObj(interp, objv[1], &max_c_h);
  if (code != TCL_OK) return code;

  // eliminate rounding error
  max_c_v -= 0.5;
  max_c_h -= 0.5;

  // reset iterator
  grid_i = 0;
  grid_j = 0;

  //PRINTF ("--> %d %d\n", max_c_v, max_c_h);

  CMD_RETURN(interp);
}


// Return results for specified bin.
// value_h,value_v are the wiring resources used in the bin;
// rsrc_h and rsrc_v are the resources available in the bin - these are reduced
// for blockages and edges.
static gr_get_result(int grid_i, int grid_j, double *pvalue_h, double *pvalue_v, double *prsrc_h, double *prsrc_v)
{
    int bin = twod(grid_i,grid_j);
    int block_h = 0;			// number of blocked tracks in this grid, horizontal.
    int block_v = 0;

    *pvalue_h = gr_pgrid[bin].h;	// total routing resources used in this grid.
    *pvalue_v = gr_pgrid[bin].v;

    *prsrc_h = gr_tech.h_rsrc;
    *prsrc_v = gr_tech.v_rsrc;

    if (gr_cong_grid) {
    	*prsrc_h -= gr_cong_grid[bin].hblock;
    	*prsrc_v -= gr_cong_grid[bin].vblock;
    }

    if ( grid_j == 0) {
      // reduced resources at edge of cell.
      *prsrc_h *= gr_tech.bottom_frac;
    } else if ( grid_j == gr_tech.ydim - 1) {
      *prsrc_h *= gr_tech.top_frac;
    }

    if ( grid_i == 0) {
      *prsrc_h *= gr_tech.left_frac;
    } else if ( grid_i == gr_tech.xdim - 1) {
      *prsrc_v *= gr_tech.right_frac;
    }
}


#if USE_MAX
#define GRMAXCOLORS 20

// Send the results direct to the max display
// Syntax: gr_max_display [-scale val]  colors thresholds
int tcl_gr_max_display (ClientData data, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
    extern double atof();

    // Tcl command arguments:
    struct {
      int text_size;	// default is 0, which is smallest size.
      int add_text;
      char *colors;
      char *thresholds;
      double scale;   // full obstruction blocks this fraction of the display.
    } o;
    int layer_type[GRMAXCOLORS];	// max layer type for colors.
    double threshold[GRMAXCOLORS];
    int ncolors;

    double scale_width;
    CellDef *def = EditCellUse->cu_def;

    char *text_tag = "cg";

    char *cmdName = Tcl_GetStringFromObj(objv[0],NULL);
    objc--; objv++;
    CMD_BEGIN(interp);

    memset(&o,0,sizeof(o));
    o.scale = 0.2; 		// default scale

    // Parse options.
    while (objc >= 1) {
      char *option = Tcl_GetStringFromObj(objv[0],NULL);
      if (*option == '-') {
	  if (objc>=2 && strcmp(option,"-scale")==0) {
	      // global route grid size in routing grids
	      if (Tcl_GetDoubleFromObj(interp, objv[1], &o.scale) != TCL_OK) {
		  expecting_number:
		  ERRORF("%s: error: bad argument, expecting number\n",cmdName);
		  CMD_RETURN(interp);
	      }
	      objc-=2, objv+=2;
	      continue;
	  }
	  if (objc>=2 && strcmp(option,"-add_text")==0) {
	      // global route grid size in routing grids
	      if (Tcl_GetIntFromObj(interp, objv[1], &o.add_text) != TCL_OK) {
		  goto expecting_number;
	      }
	      objc-=2, objv+=2;
	      continue;
	  }
	  if (objc>=2 && strcmp(option,"-text_size")==0) {
	      // global route grid size in routing grids
	      if (Tcl_GetIntFromObj(interp, objv[1], &o.text_size) != TCL_OK) {
		  goto expecting_number;
	      }
	      objc-=2, objv+=2;
	      continue;
	  }
      }
      break;
    }

    if (objc != 2) {
      ERRORF("%s: error: wrong number of arguments\n",cmdName);
      CMD_RETURN(interp);
    }
    o.colors = Tcl_GetStringFromObj(objv[0],NULL);
    o.thresholds = Tcl_GetStringFromObj(objv[1],NULL);

    // Break out the color and threshold strings into their arrays.
    { char *list;
      char buf[1000];
      int n;

      for (n = 0, list = o.thresholds; parse_tokens(buf,&list," ,"); n++) {
	if (n >= GRMAXCOLORS) {
	  ERRORF("%s: error: too many colors\n",cmdName);
	  CMD_RETURN(interp);
	}
	threshold[n] = atof(buf);
      }
      ncolors = n;

      for (n = 0, list = o.colors; parse_tokens(buf,&list," ,"); n++) {
	if (n >= GRMAXCOLORS) {
	  ERRORF("%s: error: too many colors\n",cmdName);
	  CMD_RETURN(interp);
	}
	if ((layer_type[n] = DBTechNameType(buf)) < 0) {
	  ERRORF("%s: error: layer %s not found\n",cmdName,buf);
	  CMD_RETURN(interp);
	}
	printf("Displaying color %s type %d threshold %g\n",buf,layer_type[n],threshold[n]);
      }

      if (n != ncolors) {
	ERRORF("%s: error: number of colors and thresholds must be the same",cmdName);
	CMD_RETURN(interp);
      }
    }


    // Clear previous display.
    { int n;
      for (n = 0; n < ncolors; n++) {
        DBErase(def,DBBBoxCellDef(def),layer_type[n]);
      }
    }
    if (o.add_text) {
      layAnnotateTextClear(LayCurWindow(),text_tag);
    }

    // Compute scale to use for display.
    // The scale is the fraction of the width of routing grid rectangle
    // that is used to draw routing congestion when the box is fully utilized.
    // We want to use the same width visible lines in both directions, so compute
    // scale from the smaller dimension.
    if (gr_tech.grid_x > gr_tech.grid_y) {
      scale_width = o.scale * gr_tech.grid_y;
    } else {
      scale_width = o.scale * gr_tech.grid_x;
    }

    for (grid_i = 0; grid_i < gr_tech.xdim; grid_i++) {
      for (grid_j = 0; grid_j < gr_tech.ydim; grid_j++) {
	int ggx = gr_tech.offset_x + grid_i;	// global grid coord using origin of original cell.
	int ggy = gr_tech.offset_y + grid_j;
	double h_value, v_value;
	double h_rsrc, v_rsrc;
	double h_frac, v_frac;
	int n;

	// Get routing congestion at this global routing grid point.
	gr_get_result(grid_i,grid_j,&h_value,&v_value,&h_rsrc,&v_rsrc);

	// Get existing congestion at this global routing grid.

	// Percent congestion.
	h_frac = h_rsrc ? h_value / h_rsrc : 0;
	v_frac = v_rsrc ? v_value / v_rsrc : 0;

	// Display it in max.
	for (n = 0; n < ncolors; n++) {
	  if (h_frac >= threshold[n]) {
	    // display it...
	    Rect r;
	    double width2 = h_frac * scale_width / 2;
	    double ycenter = (ggy + 0.5) * gr_tech.grid_y;
	    r.r_xbot = ggx * gr_tech.grid_x;
	    r.r_xtop = (ggx + 1) * gr_tech.grid_x - 1;
	    r.r_ybot = ycenter - width2;
	    r.r_ytop = ycenter + width2;
	    DBPaint(def,&r,layer_type[n]);
	    break;
	  }
	}

	for (n = 0; n < ncolors; n++) {
	  if (v_frac >= threshold[n]) {
	    // display it...
	    Rect r;
	    double width2 = v_frac * scale_width / 2;
	    double xcenter = (ggx + 0.5) * gr_tech.grid_x;
	    r.r_xbot = xcenter - width2;
	    r.r_xtop = xcenter + width2;
	    r.r_ybot = ggy * gr_tech.grid_y;
	    r.r_ytop = (ggy + 1) * gr_tech.grid_y - 1;
	    DBPaint(def,&r,layer_type[n]);
	    break;
	  }
	}

	if (o.add_text) {
	  PointFloat location;
	  char text[100];
	  location.pf_x = (ggx + 0.5) * gr_tech.grid_x;  // draw in center of global grid box
	  location.pf_y = (ggy + 0.5) * gr_tech.grid_y;
	  sprintf(text,"h=%.3g/%.3g v=%.3g/%.3g",
	     h_value < 0.1 ? 0 : h_value,
	     h_rsrc  < 0.1 ? 0 : h_rsrc,
	     v_value < 0.1 ? 0 : v_value,
	     v_rsrc  < 0.1 ? 0 : v_rsrc);

	  {
	      TextStyle *ts;

	      switch (o.text_size) {
	      case 0:
		// The layTextStyleLookup is not in the .h file yet, so just cast it.
		ts = (TextStyle*) layTextStyleLookup("annotation_small");
		break;

	      default:
	      case 1:
		ts = (TextStyle*) layTextStyleLookup("annotation_medium");
		break;

	      case 2:
		ts = (TextStyle*) layTextStyleLookup("annotation_large");
		break;

	      case 3:
		ts = (TextStyle*) layTextStyleLookup("annotation_extra_large");
		break;
	      }
	      layAnnotateTextAdd(LayCurWindow(), location, GEO_CENTER, ts->ts_index, text, text_tag);
	  }
	}
      }
    }

    // being lazy: just mark the whole cell, all layers, for redisplay update.
    DBChangedArea(def,NULL,NULL,0);

    CMD_RETURN(interp);
}
#endif

// Print histogram.
int tcl_gr_histogram(ClientData data, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
  // TODO
}

// Terminate.  Free data structures used by global router.
int tcl_gr_term (ClientData data, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
    gr_free_stuff();
}



// Returns x, y, h, v.  Where x, y are the coords of the ggrid (offset
// to corresponds to microns) and h, v are the congestions there.
// Note: This does not need CMD_BEGIN/CMD_RETURN, because there are no error messages.
int tcl_gr_grid_iter (ClientData data, Tcl_Interp *interp,
	    int objc, Tcl_Obj *objv[])
{

  int done;
  double value_h, value_v;
  double v_rsrc, h_rsrc;

  grGrid *grid = gr_pgrid;

  Tcl_Obj *lobj = Tcl_NewObj();  // tcl list result

  if ( grid_j < 0 ) {
    // done
    Tcl_SetObjResult(interp,lobj);
    return TCL_OK;
  }

  // routed length
  do {

    int bin = twod(grid_i,grid_j);

    if ( grid_j == 0) {
      // fix up for edge cell
      value_h = grid[bin].h / gr_tech.bottom_frac;

    } else if ( grid_j == gr_tech.ydim - 1) {
      // fix up for edge cell
      value_h = grid[bin].h / gr_tech.top_frac;

    } else {
      value_h = grid[bin].h;
    }

    if ( grid_i == 0) {
      // fix up for edge cell
      value_v = grid[bin].v / gr_tech.left_frac;

    } else if ( grid_i == gr_tech.xdim - 1) {
      // fix up for edge cell
      value_v = grid[bin].v / gr_tech.right_frac;

    } else {
      value_v = grid[bin].v;
    }

    h_rsrc = gr_tech.h_rsrc;
    v_rsrc = gr_tech.v_rsrc;
    if (gr_cong_grid) {
	h_rsrc -= gr_cong_grid[bin].hblock;
	v_rsrc -= gr_cong_grid[bin].vblock;
    }

    if ( value_h >= max_c_h || value_v >= max_c_v ) {

      Tcl_ListObjAppendElement(interp,lobj,Tcl_NewIntObj(grid_i + gr_tech.offset_x));
      Tcl_ListObjAppendElement(interp,lobj,Tcl_NewIntObj(grid_j + gr_tech.offset_y));

      Tcl_ListObjAppendElement(interp, lobj, Tcl_NewIntObj(
		   (int) ceil(value_h - 0.0001)));
      Tcl_ListObjAppendElement(interp, lobj, Tcl_NewIntObj(
		   (int) ceil(value_v - 0.0001)));
      Tcl_ListObjAppendElement(interp, lobj, Tcl_NewIntObj(
		   (int) ceil(h_rsrc - 0.0001)));
      Tcl_ListObjAppendElement(interp, lobj, Tcl_NewIntObj(
		   (int) ceil(v_rsrc - 0.0001)));

      done = TRUE;
    } else {
      done = FALSE;
    }

    //PRINTF("---> %d %d %d %d %d (%g %g) %d %d\n", gr_tech.xdim, gr_tech.ydim, bin, grid_i, grid_j, grid[bin].h, grid[bin].v, (int) ceil(grid[bin].h - 0.0001), (int) ceil(grid[bin].v - 0.0001));

    if ( grid_i + 1 >= gr_tech.xdim ) {
      grid_i = 0;
      if ( grid_j + 1 >= gr_tech.ydim ) {
	// done
	grid_j = -1;
	break;

      } else {
	grid_j++;
      }

    } else {
      grid_i++;
    }
  } while (!done);

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

  if ( x < 0 || x >= gr_tech.xdim || y < 0 || y >= gr_tech.ydim ) {
    // oops, out of bounds
    ERRORF("ggrid %d,%d out of range, must be between 0 and %d,%d.\n",
	   x, y, gr_tech.xdim, gr_tech.ydim);
    return TCL_ERROR;
  }

  // vertical blockage in this ggrid
  code = Tcl_GetDoubleFromObj(interp, objv[4], &v);
  if (code != TCL_OK) return code;

  // horizontal blockage in this ggrid
  code = Tcl_GetDoubleFromObj(interp, objv[5], &h);
  if (code != TCL_OK) return code;

  // add directly into probability grid
  gr_pgrid[twod(x,y)].h += h;
  gr_pgrid[twod(x,y)].v += v;

  return TCL_OK;
}
