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


// Routines to create steiner trees and from those compute C or R/C
// networks for static timing analysis.  Creates either DSPF format R/C
// or simple capacitance files.

#define STEINER_DEBUG 0

#include	<stdio.h>
#include	<string.h>
#include	<ctype.h>
#include	<errno.h>
#include	<stdlib.h>
#include 	<assert.h>
#include 	<limits.h>	// for INT_MAX
#include 	<tcl.h>
#include 	<tk.h>

typedef int	BOOLEAN;

#define MEMORY_TEST 0
#if MEMORY_TEST
/* Keep a count of the total number of memory blocks used for leak testing. */
static int memoryUse = 0;
#define malloc(p) (memoryUse++,malloc(p))
#define calloc(m,n) (memoryUse++,calloc(m,n))
#define free(p) (memoryUse--,free(p))
#define MEMORY_PRINT printf("Memory Block Count = %d\n",memoryUse);
#endif


enum rc_t {
	RC_NOMINAL,	// it worked as expected, normal results produced
	// the rest are not used!
	//RC_INVALID,	// what you said was wrong
	//RC_EXCEPTION,	// ...was OK, but turns out to be a special case
	//RC_FAILED,	// ...was OK, but it didn't work (generic)
	//RC_NOTSPECIFIED,// ...didn't work & here's a clue 
	//RC_NOTFOUND,
	//RC_INUSE,
	//RC_BADSYNTAX
};


#define MAX_NAME_SIZE 		200
#define MAX_NET_NAME_SIZE	(0x100-1)
#define MAX_DSPF_NAME_SIZE 	(2*MAX_NAME_SIZE+2)

#define strieql(a,b) (strcasecmp((a),(b))==0)

typedef struct s_Point {
	struct s_Point *flink, *blink;	/* Double linked list */
	int	x;
	int	y;
	char	inst_name[MAX_NAME_SIZE+2];
	char	port_name[MAX_NAME_SIZE+2];
	int	dir;
	int	generated_id;
	int	sort;	// used for sorting list of pts
	int	sizex;
	int	sizey;
} Point;


typedef struct s_box {
    struct s_box *flink, *blink;
    Point *pt1, *pt2;
} Box;


typedef struct {
    Point *point_list;		// list of port and pin locations on this net
    Box	*box_list; 			// list of connecting segments, sort of...
    Point *generated_point_list; 	// list of generated intermediate non-port segment junctions
    char name[MAX_NET_NAME_SIZE+1];	// we make up name if not supplied to constructor
    double cap_fudge;

    Box box_list_sentinel;		// avoids having to allocate one.
    Point point_list_sentinel;		// avoids having to allocate one.
    Point gen_point_list_sentinel;	// avoids having to allocate one.
} Net;


typedef struct {
    double	rconstx;
    double	rconsty;
    double	cconstx;
    double	cconsty;
    double	min_rc;
    char *	capstring;	// Prepended to cap in prime time mode.
    int     	prime_time;	// Set for special prime time mode.
    FILE *  fid;
    int		dup;	// Set if file descriptor was duped.
    int     rc_index;	// used for naming resistors and caps in dspf file.
} DspfFile;

// Generic doubly linked list.
typedef struct s_Dllist {
    struct s_Dllist *flink, *blink;
} Dllist;


// Forward declarations.
Net *steiner_begin_net(char *name);
void steiner_free_net(Net *net);
int steiner_add_point(Net *net,int x,int y,char *inst_name, char *port_name, int dir);
int steiner_get_route_seg(Net *net,int cmd, int *px1, int *py1, int *px2, int *py2, char *name1, char *name2);


static Net *current_net = NULL;
static int net_name_index = 1;
static DspfFile current_file;


// Utility functions to manipulate doubly linked lists.
// All such functions must begin with flink,blink pointers.


// Add item to doubly linked list.
static Dllist *dllink(Dllist *list,Dllist *item)
{
    item->flink = list->flink;
    item->blink = list;
    list->flink->blink = item;
    list->flink = item;
    return item;
}
#define DLLINK(list,item) dllink((Dllist*)(list),(Dllist*)(item))


// Delete item from doubly linked list.
static Dllist *dlunlink(Dllist *item)
{
    item->flink->blink = item->blink;
    item->blink->flink = item->flink;
    return item;
}
#define DLUNLINK(item) dlunlink((Dllist*)(item))




static char *stralloc(char *s)
{
    //return s?(char*)strcpy((char*)malloc(strlen(s)+1),s):NULL;
    return (char*)strcpy((char*)malloc(strlen(s)+1),s);
}


// allocate and return a point struct.
static Point *point_new(int x, int y, char *inst_name, char *port_name, int dir) {
    Point *new = (Point*)calloc(1,sizeof(Point));
    new->x = x;
    new->y = y;
    if (inst_name) {
	strncpy(new->inst_name,inst_name,MAX_NAME_SIZE);
	new->inst_name[MAX_NAME_SIZE] = 0;
    }
    if (port_name) {
	strncpy(new->port_name,port_name,MAX_NAME_SIZE);
	new->port_name[MAX_NAME_SIZE] = 0;
    }
    new->dir = dir;
    return new;
}


// allocate and return a box struct.
static Box *box_new(Point *argpt1, Point *argpt2)
{
    Box *box = (Box*)calloc(1,sizeof(Box));
    box->flink = box->blink = box;
    box->pt1 = argpt1;
    box->pt2 = argpt2;
    return box;
}

// Split box at arg_pt.  Replace with two boxes.
// Original box is modified to end at arg_pt, and
// splice in a new box from arg_pt to original box pt2.
static void box_split(Box *box,Point *arg_pt)
{
    Box *new_box = box_new(arg_pt, box->pt2);
    box->pt2 = arg_pt;
    DLLINK(box,new_box);
}


static int box_sizex(Box *box)
{
    return (abs(box->pt1->x - box->pt2->x));
}

static int box_sizey(Box *box)
{
    return (abs(box->pt1->y - box->pt2->y));
}

// distance from one point to another point
static int ptdistance(Point *p1, Point *p2)
{
    int xoff = abs(p1->x - p2->x);
    int yoff = abs(p1->y - p2->y);
    return xoff + yoff;
}


static BOOLEAN point_eq(Point *p1, Point *p2)
{
    return p1->x == p2->x && p1->y == p2->y;
}


// compute the distance from the point to the box
// create near_pt which is the closest point on the box
// Return nearest point in near_pt
static int box_distance(Box *box, Point *arg_pt, Point *near_pt)
{
    if (box->pt1->x <= box->pt2->x) {
	if (arg_pt->x <= box->pt1->x)		near_pt->x = box->pt1->x;
	else if (arg_pt->x >= box->pt2->x)	near_pt->x = box->pt2->x;
	else					near_pt->x = arg_pt->x;
    } else {
	if (arg_pt->x <= box->pt2->x)		near_pt->x = box->pt2->x;
	else if (arg_pt->x >= box->pt1->x)	near_pt->x = box->pt1->x;
	else					near_pt->x = arg_pt->x;
    }

    if (box->pt1->y <= box->pt2->y) {		// box goes up & right
	if (arg_pt->y <= box->pt1->y) 		near_pt->y = box->pt1->y;
	else if (arg_pt->y >= box->pt2->y)	near_pt->y = box->pt2->y;
	else					near_pt->y = arg_pt->y;
		    
    } else {					// box goes down & right
	if (arg_pt->y <= box->pt2->y) 		near_pt->y = box->pt2->y;
	else if (arg_pt->y >= box->pt1->y)	near_pt->y = box->pt1->y;
	else					near_pt->y = arg_pt->y;
    }

    // return manhattan distance from arg_pt to near_pt 
    // ... might be 0

    return ptdistance(arg_pt,near_pt);
}

// Simple n^2 sort algorithm
// First move the driver of the net to the start of the point list.
// All other points are sorted by distance from the first.
// Assumes there are at least two points.
static void sort_point_list(Net *net)
{
    Point *pt, *anchor;

    // Find output pin, if any.
    for (pt = net->point_list->flink; pt != net->point_list; pt = pt->flink) {
	// If inst_name is empty, its a port, otherwise an instance pin.
	if (pt->inst_name[0] == 0 ? pt->dir == 'I' : pt->dir == 'O') {
	    // Move output pin to the front of the list.
	    DLUNLINK(pt);
	    DLLINK(net->point_list,pt);
	    break;
	}
    }
    
    anchor = net->point_list->flink;

    // Compute distance of all points to the anchor.
    anchor->sort = 0;
    for (pt = anchor->flink; pt != net->point_list; pt = pt->flink) {
	pt->sort = ptdistance(anchor,pt);
    }

    for (pt = anchor->flink; pt != net->point_list->blink; pt = pt->flink) {
	assert(pt != net->point_list);
	if (pt->flink->sort < pt->sort) {
	    // Unlink pt->flink, and search backwards to find
	    // pt that is less than movept.
	    Point *movept = (Point*)DLUNLINK(pt->flink);
	    for (pt = pt->blink; pt != anchor; pt = pt->blink) {
		if (pt->sort < movept->sort) break;
	    }
	    // Link movept after pt
	    // for loop will restart with pt == movept
	    DLLINK(pt,movept);
	}
    }
}

static void net_dump(Net *net) {
#if STEINER_DEBUG
    Point *anchor, *pt; Box *box;
    fprintf(current_file.fid,"\n# net %s:\n",net->name);
    for (box = net->box_list->flink; box != net->box_list; box = box->flink) {
	fprintf(current_file.fid,"#	box (%d,%d)-(%d,%d)\n",
	    box->pt1->x, box->pt1->y, box->pt2->x,box->pt2->y);
    }

    anchor = net->point_list->flink;
    for (pt = net->point_list->flink; pt != net->point_list; pt = pt->flink) {
	fprintf(current_file.fid,"#	point (%d,%d) s=%d,%d d=%d\n",pt->x,pt->y,pt->sizex,pt->sizey,
	    ptdistance(anchor,pt));
    }
#endif
}

// Generate the box structures that represent the route.
// Leave them in the net structure.
// Also creates generated_points.
static int compute_route(Net *net)
{
    Point *new_pt; Box *new_box;

    // If box_list is non-empty, we already computed route for this net.
    if (net->box_list->flink != net->box_list) {return RC_NOMINAL;}

    // if there is only 1 point, don't make any output
    if (net->point_list->flink == net->point_list->blink) {
	return RC_NOMINAL;
    }

    sort_point_list(net);

    // initialize box_list with box defined by first two points
    DLLINK(net->box_list,box_new(net->point_list->flink, net->point_list->flink->flink));

    // Process each point, starting at the third.
    for (new_pt = net->point_list->flink->flink->flink;
       new_pt != net->point_list; new_pt=new_pt->flink) {

	    // find closest BOX in box_list

	    Box *near_box = NULL;	// nearest box so far
	    int distance = INT_MAX;	// closest distance so far
	    Point near_pt;		// nearest point on nearest box
				    // ...need to make a *real* pt later...
	    Point box_pt;		// nearest point on trial box
	    Point *corner_pt;

	    Box *bl;
	    // try each box generated so far....
	    for (bl = net->box_list->flink; bl != net->box_list; bl = bl->flink) {
		int d = box_distance(bl,new_pt, &box_pt);
		if (d < distance) {	// new closest
			distance = d;
			near_box = bl;
			near_pt.x = box_pt.x;
			near_pt.y = box_pt.y;
		}
		if (distance == 0) break;	
	    }
	    assert(near_box);

	    // new point is on an edge of this box
	    // This happens when you have something that looks like this:
	    //           foo5
	    //       +----+----+ foo4
	    //       |         |
	    //  foo3 +---------+
	    //       |
	    //  foo2 +---------+
	    //       |         |
	    //       +---------+ foo1
	    //
	    // Point foo1 is the driver.  Point foo4 is closer to foo1 than foo5,
	    // so it is done first, and foo5 ends up being on the box edge.
	    // If the new point is on a corner, we could just discard it, but dont bother.
	    if (distance == 0) {
		// split the box
		box_split(near_box,new_pt);
		continue;
	    }

	    // is the nearest point an existing point?
	    // ... the code flow is a bit funny here, I am maybe too busy
	    // avoiding making the test twice.

	    if (point_eq(&near_pt,near_box->pt1)) {
		    corner_pt = near_box->pt1;

	    } else if (point_eq(&near_pt,near_box->pt2)) {
		    corner_pt = near_box->pt2;

	    } else {
		    // no; 
		    // nearest point is along one of the sides,
		    // so we have to break the box into one 
		    // degnerate box (corresponding to the side)
		    // and one open (or not) box, then add
		    // a degenerate box from the nearest point to 
		    // the new point
    
		    // ...first, need to make a real point

		    Point *edge_pt = point_new(near_pt.x,near_pt.y,0,0,0);
		    DLLINK(net->generated_point_list->blink,edge_pt);
		    edge_pt->generated_id = edge_pt->blink->generated_id + 1;

		    box_split(near_box,edge_pt);

		    // The point_eq test is not really necessary, but
		    // avoids cluttering the box list with zero size boxes.
		    if (! point_eq(edge_pt,new_pt)) {
			new_box = box_new(new_pt, edge_pt);
			DLLINK(near_box,new_box);
		    }

		    continue;

	    }

	    // yes, nearest point is existing point;
	    // just make a new box chained of existing point.
	    // Note: Lee's original algorithm checked for the three points:
	    // near_pt and the near_box corners being colinear, and if so,
	    // just modified near_box.  Its not necessary, and it would
	    // result in points not being mentioned in the output, which might
	    // confuse whoever reads the DSPF file.
	    new_box = box_new(corner_pt, new_pt);
	    DLLINK(near_box,new_box);

	    continue;
    }

    return RC_NOMINAL;
}

// Get name of the point, return in buf.
// buf is of size MAX_DSPF_NAME_SIZE
static char *get_name(Net *net,Point *p,char *buf,int flag_generated_null) {
    if (p->generated_id > 0) {
        // It is a generated point.
	sprintf(buf,"%s:%d",net->name,p->generated_id);
    } else if (p->inst_name[0] == 0) {
        // It is a port
        sprintf(buf,p->port_name);
    } else {
        // It is an instance port
        sprintf(buf,"%s:%s",p->inst_name,p->port_name);
    }
    return buf;
}


static void dspf_file_init() {
    current_file.rconstx = 1.0;
    current_file.rconsty = 1.0;
    current_file.cconstx = 1.0;
    current_file.cconsty = 1.0;
    current_file.min_rc = 0.0;
    current_file.rc_index = 1;
    current_file.dup = 0;
}


// open the file
static int dspf_file_open(char*filename,char**errmsg) {
    int file_descriptor;

    if (strncmp(filename, "file", 4) != 0) {
	*errmsg = "channel descriptor should be like \"file6\"";
	return -1;
    }
    file_descriptor = atoi(filename + 4);

    if (file_descriptor < 1 || file_descriptor > 64) {
	*errmsg = "file descriptor appears to be out of range?????";
	return -1;
    }

    // Both UNIX stdio and the Tcl interpreter are bound and determined
    // to close this file, so dup the file descriptor so it can
    // be safely closed twice.  If you dont do this, and the tcl
    // caller closes the file, can get an error during exit() when
    // the C exit code attempts to fclose the file.
    if (current_file.dup) {file_descriptor = dup(file_descriptor);} 
    if ((current_file.fid = fdopen(file_descriptor, "w")) == NULL) {
	*errmsg = "fdopen DSPF file failed";
	return -1;
    }
    return 0;
}

static void dspf_file_close() {
    steiner_free_net(current_net); current_net = NULL; // no harm if already null

    // If you did not specify -dup when you opened the file, then you cant close it either!
    if (current_file.dup == 1) {
	if (current_file.fid) {
	    fclose(current_file.fid);
	}
    }
}

static int write_DSPF(Net *net)
{
    Point *point; Box *box;
    double rconstx = current_file.rconstx;
    double rconsty = current_file.rconsty;
    // The capacitance of the wire is added at both end-points, so divide by 2.
    double cconstx = current_file.cconstx / 2.0;
    double cconsty = current_file.cconsty / 2.0;
    double min_rc = current_file.min_rc;
    int net_total2x = 0;
    int net_total2y = 0;
    double net_res;
    double net_capacitance;
    int cap_fudged;
    char buf1[MAX_DSPF_NAME_SIZE+2], buf2[MAX_DSPF_NAME_SIZE+2];

    // compute the capacitance at each point

    for (box = net->box_list->flink; box != net->box_list; box = box->flink) {
	// We add the cap to both points, but then divide by 2 later using cconstx,
	// to avoid round off error at this point.
	box->pt1->sizex += box_sizex(box);
	box->pt1->sizey += box_sizey(box);
	box->pt2->sizex += box_sizex(box);
	box->pt2->sizey += box_sizey(box);
    }

    // total all the pt capacitances
    // for original and generated points

    // Note: net_total2x and net_total2y are total x and y distance times 2,
    // since we add both endpoints.
    for (point = net->point_list->flink; point != net->point_list; point = point->flink) {
	net_total2x += point->sizex;
	net_total2y += point->sizey;
    }
    for (point = net->generated_point_list->flink;
	 point != net->generated_point_list;
	 point = point->flink) {
	net_total2x += point->sizex;
	net_total2y += point->sizey;
    }

    // convert to fF
    net_capacitance = (cconstx * net_total2x) + (cconsty * net_total2y);

    net_dump(net);

    /* PATS NOTE: If user specifies cap_fudge on the end_net,
     * they probably want it to be output!  But I dont want
     * to change this and maybe break something.
     */
    if (net_capacitance == 0) {
	    // don't do anything
	    return RC_NOMINAL;
    }

    net_capacitance += net->cap_fudge;

    // ... capacitance only ...
    if (current_file.capstring != NULL) {
      if (current_file.prime_time == 1) {
	// special case for primetime
	char *each;

	each = strtok(net->name, " ");
	while (1) {
	  fprintf(current_file.fid, "%s%g %s\n", 
		  current_file.capstring, net_capacitance, each);

	  each = strtok(NULL, " ");
	  if (each == NULL) {
	    // done
	    break;
	  }
	}

      } else {
	fprintf(current_file.fid, "%s%s %gfF\n", 
		current_file.capstring, net->name, net_capacitance);
      }

      return RC_NOMINAL;
    }

    // write DSPF
    // net header
    fprintf(current_file.fid, "\n");

    fprintf(current_file.fid, "*|NET %s %gFF\n", net->name, net_capacitance);	

    // original points
    for (point = net->point_list->flink; point != net->point_list; point = point->flink) {

      if (strcmp(point->inst_name, "") == 0) {
	// special case of a toplevel pin
	// third arg is pin capacitance.
	fprintf(current_file.fid, "*|P (%s %c %gFF %d %d)\n",
		point->port_name,
		point->dir,
		0.0,
		point->x,
		point->y);

      } else {
	// it's an instance pin
	fprintf(current_file.fid, "*|I (%s:%s %s %s %c 0 %d %d)\n",
		point->inst_name, point->port_name,
		point->inst_name, point->port_name,
		point->dir,
		point->x,
		point->y);
      }

      continue;
    }

    // special case if smaller than min rc, just add a single cap
    net_res = (rconstx * net_total2x) + (rconsty * net_total2y);
    // The net_capictance is correct, but net_res is already times 2 (because
    // net_total2x and net_total2y are times 2) and we want to compare
    // to RC/2 because only half the cap is after the resister, so use min_rc*4
    if ((net_capacitance * net_res) < min_rc * 4.0) {
      // no R's cause they don't matter.
      point = net->point_list->flink;
      fprintf(current_file.fid, "C%d %s VSS %gFF\n",
	      current_file.rc_index++, get_name(net,point,buf1,0), 
	      net_capacitance);

      return RC_NOMINAL;
    }

    // generated points
    for (point = net->generated_point_list->flink;
	 point != net->generated_point_list;
	 point = point->flink) {

	    fprintf(current_file.fid, "*|S (%s)\n",
		get_name(net,point,buf1,0));
    }

    // capacitors
    cap_fudged = 0;

    // ... same as just below, different point list
    for (point = net->point_list->flink; point != net->point_list; point = point->flink) {
	double capacitance = ((cconstx * (double)point->sizex) +
	    (cconsty * (double)point->sizey));

	if (!cap_fudged) {
	    capacitance += net->cap_fudge;

	    // only do this once
	    cap_fudged = 1;
	}

	fprintf(current_file.fid, "C%d %s VSS %gFF\n",
	    current_file.rc_index++, get_name(net,point,buf1,0),
	    capacitance);
    }
    
    // ... same as just above, different point list
    for (point = net->generated_point_list->flink;
	 point != net->generated_point_list;
	 point = point->flink) {
	    
	double capacitance = ((cconstx * (double)point->sizex) +
	    (cconsty * (double)point->sizey));

	fprintf(current_file.fid, "C%d %s VSS %gFF\n",
	    current_file.rc_index++, get_name(net,point,buf1,0), capacitance);
    }

    // resistors	
    for (box = net->box_list->flink; box != net->box_list; box = box->flink) {
	double resistance = (rconstx * (double)(box_sizex(box))) +
	  (rconsty * (double)(box_sizey(box)));

	fprintf(current_file.fid, "R%d %s %s %g\n", 
		  current_file.rc_index++, get_name(net,box->pt1,buf1,0),
		  get_name(net,box->pt2,buf2,0), resistance);

    }
    
    return RC_NOMINAL;
}



//////////////////////////////////////////////////////////////////////////
//// C interface functions
//////////////////////////////////////////////////////////////////////////

#define INIT_SENTINEL(x) ((x)->flink = (x)->blink = (x))

// Start a new net.  Used both when writing dspf files, or just computing the routes.
// If net_name is NULL, make something up, which is not guaranteed not to be unique
// w.r.t. other specified net names.
// Return pointer to the new net.
Net *steiner_begin_net(char *name)
{
    Net *new = (Net*)calloc(1,sizeof(Net));

    steiner_free_net(NULL);

    if (name != NULL) {
	strncpy(new->name, name, MAX_NET_NAME_SIZE);
	new->name[MAX_NET_NAME_SIZE] = '\0';
    } else {
	sprintf(new->name, "NET_%d", net_name_index++);
    }

    new->point_list = INIT_SENTINEL(&new->point_list_sentinel);
    new->generated_point_list = INIT_SENTINEL(&new->gen_point_list_sentinel);
    new->generated_point_list->generated_id = 0; // redundant with calloc
    new->box_list = INIT_SENTINEL(&new->box_list_sentinel);
    new->cap_fudge = 0.0;
    current_net = new;
    return new;
}

// If net is NULL, free the current_net.  If that is NULL, do nothing.
void steiner_free_net(Net *net)
{
    Point *pt; Box *box;
    if (net == NULL) {net = current_net;}
    if (net == NULL) {return;}
    while (net->generated_point_list->flink != net->generated_point_list) {
	free(DLUNLINK(net->generated_point_list->flink));
    }
    while (net->box_list->flink != net->box_list) {
	free(DLUNLINK(net->box_list->flink));
    }

    while (net->point_list->flink != net->point_list) {
	free(DLUNLINK(net->point_list->flink));
    }
    free(net);
}


// Add point to route to specified net.  If no net specified, add to current_net,
// which is the one most recently specified to steiner_begin_net.
// port_name must be provided; it is the port name for top-level ports or pin name for instance pins.
// inst_name is cell instance name, or empty ("") for ports.  Must not be NULL.
// dir is the direction of the port and must be 'I', 'O' or 'B'.
// Note: a driver of a net would be 'O' for an instance pin or 'I' for a port.
int steiner_add_point(Net *net,int x,int y,char *inst_name, char *port_name, int dir)
{
    Point *new_pt;
    assert(dir == 'I' || dir == 'O' || dir == 'B');
    new_pt = point_new(x,y,inst_name,port_name,dir);
    if (net == NULL) {
	assert(current_net);
	net = current_net;
    }
    DLLINK(net->point_list,new_pt);
    return 0;
}


// Function computes the route and returns the route segments as a sequence
// of boxes, with one box returned per call.
// If no net specified, return routes for current_net.
// cmd is 1 for first box, 2 for next successive box.
// The corners of the box are returned in: px1, py1, px2, py2.
// If name1 and/or name2 are non-null, the point name is returned in those buffers, 
// which must have minimum size MAX_DSPF_NAME_SIZE.
// Return 1 on success, 0 on end of list, -1 on failure.
int steiner_get_route_seg(Net *net,int cmd, int *px1, int *py1, int *px2, int *py2, char *name1, char *name2)
{
    static Box *current_box;

    if (net == NULL) {net = current_net;}
    assert(net);

    if (cmd == 1) {
        if (compute_route(net) != RC_NOMINAL) {
	    return -1;
	}
	current_box = net->box_list->flink;
    } else {
	current_box = current_box->flink;
    }

    if (current_box == net->box_list) {return 0;}

    *px1 = current_box->pt1->x;
    *py1 = current_box->pt1->y;
    *px2 = current_box->pt2->x;
    *py2 = current_box->pt2->y;

    if (name1) {
	get_name(net,current_box->pt1,name1,1);
    }
    if (name2) {
	get_name(net,current_box->pt2,name2,1);
    }
    return 1;
}


//////////////////////////////////////////////////////////////////////////
//// TCL interface functions
//////////////////////////////////////////////////////////////////////////


// Usage:
//  steiner_add_point instance_name port_name iodirection x y
//
//  Note: input and output pins may be given in any order.
int
Tcl_steiner_add_point(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
    int x;
    int y;
    int dir;
    int code;
    char *argdir, *inst_name, *port_name;
    Point *new_pt;

    if (objc != 6) {
	interp->result = "steiner_add_point syntax";
	return TCL_ERROR;
    }

    if (current_net == NULL) {
	interp->result = "no current net";
	return TCL_ERROR;
    }

    code = Tcl_GetIntFromObj(interp, objv[4], &x);
    if (code != TCL_OK) return code;

    code = Tcl_GetIntFromObj(interp, objv[5], &y);
    if (code != TCL_OK) return code;

    inst_name = Tcl_GetStringFromObj(objv[1], NULL);
    port_name = Tcl_GetStringFromObj(objv[2], NULL);

    {   char *argdir;
	argdir = Tcl_GetStringFromObj(objv[3],NULL);
	if (strieql(argdir,"input")||strieql(argdir,"i")) {
	    dir = 'I';
	} else if (strieql(argdir,"output")||strieql(argdir,"o")) {
	    dir = 'O';
	} else if (strieql(argdir,"inout")||strieql(argdir,"b")) {
	    dir = 'B';
	} else {
	    interp->result = "invalid port dir";
	    return TCL_ERROR;
	}
    }

    steiner_add_point(current_net,x,y,inst_name,port_name,dir);
    return TCL_OK;
}


// Tcl Usage:
// steiner_begin_net  netname
int
Tcl_steiner_begin_net(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
    char *name = NULL;

    if (objc > 2) {
	interp->result = "steiner_begin_net syntax";
	return TCL_ERROR;
    }

    if (objc > 1) {
	name = Tcl_GetStringFromObj(objv[1], NULL);
    }

    steiner_free_net(current_net);
    current_net = NULL;

    steiner_begin_net(name);  // sets current_net as a side effect.

    return TCL_OK;
}


// Return the route as a list of boxes whose endpoints are the route info.
// The route was set up by calls to steiner_begin_net and steiner_add_point
// Returns a list of boxes, where each box is a list: {x1 y1 name1 x2 y2 name2}
// The names are either: "foo:foo for an an instance pin, "foo" for port foo,
// or empty for a generated point.
int Tcl_steiner_get_route(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
    Tcl_Obj *boxobj, *lobj;
    Box *box;
    Net *net = current_net;
    int code;

    char buf1[MAX_DSPF_NAME_SIZE+2], buf2[MAX_DSPF_NAME_SIZE+2];
    int x1, y1, x2, y2;

    if (objc != 1) {
	interp->result = "steiner_get_route syntax";
	return TCL_ERROR;
    }

    if (net == NULL) {
	interp->result = "steiner_get_route: no current net";
	return TCL_ERROR;
    }

    code = steiner_get_route_seg(current_net,1,&x1,&y1,&x2,&y2,buf1,buf2);

    if (code == -1) {
	interp->result = "compute_route failed";
	return TCL_ERROR;
    }
    if (code == 0) {
	interp->result = "no current route data";
	return TCL_ERROR;
    }

    // Return all segments in route as a tcl list of boxes.
    lobj = Tcl_NewObj();  // tcl list result
    do {
	boxobj = Tcl_NewObj();

	Tcl_ListObjAppendElement(interp,boxobj,Tcl_NewIntObj(x1));
	Tcl_ListObjAppendElement(interp,boxobj,Tcl_NewIntObj(y1));
	Tcl_ListObjAppendElement(interp,boxobj,Tcl_NewStringObj(buf1,-1));

	Tcl_ListObjAppendElement(interp,boxobj,Tcl_NewIntObj(x2));
	Tcl_ListObjAppendElement(interp,boxobj,Tcl_NewIntObj(y2));
	Tcl_ListObjAppendElement(interp,boxobj,Tcl_NewStringObj(buf2,-1));

	Tcl_ListObjAppendElement(interp,lobj,boxobj);
    } while (1 == steiner_get_route_seg(current_net,2,&x1,&y1,&x2,&y2,buf1,buf2));

    Tcl_SetObjResult(interp,lobj);
    return TCL_OK;
}


// Usage:
// steiner_output_file  output_file [-options]
//   The <output_file> is a tcl open file descriptor, to which the
//   dspf file header has already been written.
//   -options may be:
//   -rconstx <num>, -rconsty <num>  resistance per unit in x/y
//   -cconstx <num>, -cconsty <num>  cap per unit in x/y
//         Note: the unit distance is defined by whatever you use
//         when you send the points to this module.
//   -min_rc <num>   nodes with less than this capacitance are output
//         as a single capacitor instead of an RC tree.  An optimization
//         to make the result file smaller.
//   -pt <boolean>   set prime-time output mode.  -string must be set too.
//   -string <string>  If string is specified, then the output file
//         contains only capacitance.  Also, the string is prepended
//         to capacitance node names.
//   -dup  Dup the file descriptor.  Used if you later plan to call Tcl_steiner_close_file.
//         This is needed so default behavior can be backward compatibility with sue, which
//   	   does not call steiner_close_file.
int Tcl_steiner_output_file(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
    char *channel_descriptor;
    int code, rc, i;

    printf("steiner router compiled %s %s\n",__DATE__,__TIME__);

    dspf_file_close();  // close previous file, if any.

    // obj 1 is tcl channel descriptor, like "file6"
    // the number is a Unix file descriptor

    if (objc < 2) {
	    interp->result = "need output channel descriptor";
	    return TCL_ERROR;
    }
    channel_descriptor = Tcl_GetStringFromObj(objv[1], NULL);

    dspf_file_init();

    for (i = 2; i < objc; i++) {
	    char *next = Tcl_GetStringFromObj(objv[i], NULL);

	    if (strcmp(next, "-rconstx") == 0) {
		if (++i >= objc) {
		    interp->result = "rconstx not specified";
		    return TCL_ERROR;
		}
		rc = Tcl_GetDoubleFromObj(interp, objv[i], &current_file.rconstx);
		if (rc != 0) {
		    interp->result = "can\'t read rconstx";
		    return TCL_ERROR;
		}
	    }				

	    else if (strcmp(next, "-rconsty") == 0) {
		if (++i >= objc) {
		    interp->result = "rconsty not specified";
		    return TCL_ERROR;
		}
		rc = Tcl_GetDoubleFromObj(interp, objv[i], &current_file.rconsty);
		if (rc != 0) {
		    interp->result = "can\'t read rconsty";
		    return TCL_ERROR;
		}
	    }

	    else if (strcmp(next, "-cconstx") == 0) {
		if (++i >= objc) {
		    interp->result = "cconstx not specified";
		    return TCL_ERROR;
		}
		rc = Tcl_GetDoubleFromObj(interp, objv[i], &current_file.cconstx);
		if (rc != 0) {
		    interp->result = "can\'t read cconstx";
		    return TCL_ERROR;
		}
	    }				

	    else if (strcmp(next, "-cconsty") == 0) {
		if (++i >= objc) {
		    interp->result = "cconsty not specified";
		    return TCL_ERROR;
		}
		rc = Tcl_GetDoubleFromObj(interp, objv[i], &current_file.cconsty);
		if (rc != 0) {
		    interp->result = "can\'t read cconsty";
		    return TCL_ERROR;
		}
	    }				

	    else if (strcmp(next, "-min_rc") == 0) {
		double min_rc;
		if (++i >= objc) {
			interp->result = "min_rc not specified";
			return TCL_ERROR;
		}
		rc = Tcl_GetDoubleFromObj(interp, objv[i], &min_rc);
		if (rc != 0) {
			interp->result = "can\'t read min_rc";
			return TCL_ERROR;
		}

		/* Pats note: why times 4?
		 */
		current_file.min_rc = min_rc * 1e15; // convert min_rc to fs
	    }

	    else if (strcmp(next, "-string") == 0) {
		if (++i >= objc) {
		    interp->result = "string not specified";
		    return TCL_ERROR;
		}
		current_file.capstring = stralloc(Tcl_GetStringFromObj(objv[i], NULL));
	    }				

	    else if (strcmp(next, "-pt") == 0) {
		if (++i >= objc) {
		    interp->result = "boolean not specified";
		    return TCL_ERROR;
		}
		code = Tcl_GetIntFromObj(interp, objv[i], &current_file.prime_time);
		if (code != TCL_OK) return code;
	    }				

	    else if (strcmp(next,"-dup") == 0) {
		current_file.dup = 1;
	    }

	    else {
		interp->result = "unknown objv";
		return TCL_ERROR;
	    }
    }

    net_name_index = 1;

    if (dspf_file_open(channel_descriptor,&interp->result) != 0) {
	return TCL_ERROR;
    }


    // OK! ready for some nets.
    return TCL_OK;
}


// Usage:
//  steiner_end_net cap_fudge
//    Writes the net to the DSPF file, which must have been open with steiner_output_file.
//    cap_fudge is an extra capacitance added to this net.
//    Notes: cap_fudge must be a valid floating point number, not "".
int
Tcl_steiner_end_net(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
    int rc, code;

    if (objc != 2) {
	interp->result = "steiner_end_net syntax";
	return TCL_ERROR;
    }
    if (current_net == NULL) {
	interp->result = "no current net";
	return TCL_ERROR;
    }

    rc = compute_route(current_net);
    if (rc != RC_NOMINAL) {
	interp->result = "compute_route failed";
	return TCL_ERROR;
    }

    code = Tcl_GetDoubleFromObj(interp, objv[1], &current_net->cap_fudge);
    if (code != 0) {
	interp->result = "can\'t read cap_fudge";
	return TCL_ERROR;
    }

    rc = write_DSPF(current_net);
    if (rc != RC_NOMINAL) {
	interp->result = "write DSPF file failed";
	return TCL_ERROR;
    }

    /* This is not good!  Should do a close_file call and flush only once then! */
    fflush (current_file.fid);

    return TCL_OK;
}

// Close stdio file pointer fopend from tcl file in steiner_output_file
// Allows optional filename argument, which is currently ignored.
int Tcl_steiner_close_file(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
    if (objc > 2) {
	interp->result = "steiner_close_file: syntax error";
	return TCL_ERROR;
    }

    if (current_file.fid == NULL) {
	interp->result = "steiner_close_file: file is not open";
	return TCL_ERROR;
    }

    dspf_file_close();

    return TCL_OK;
}
