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


// Routines to create steiner trees and from those compute C or R/C
// networks for static timing analysis.  Creates either DSPF format R/C
// or simple capacitance files.



//#include "util.h"

#ifndef util_h
#define util_h

#include	<stdio.h>
#include	<string.h>
#include	<ctype.h>
#include	<errno.h>
#include	<stdlib.h>
#include	<assert.h>

typedef int	BOOLEAN;
#define	true	1
#define false	0
#define MAX_NAME 200
#define MAX_NET_NAME_SIZE	0x100 - 1

enum rc_t {
	RC_NOMINAL,	// it worked as expected, normal results produced
	RC_INVALID,	// what you said was wrong
	RC_EXCEPTION,	// ...was OK, but turns out to be a special case
	RC_FAILED,	// ...was OK, but it didn't work (generic)
	RC_NOTSPECIFIED,// ...didn't work & here's a clue 
	RC_NOTFOUND,
	RC_INUSE,
	RC_BADSYNTAX
};

class ListOfCHARSTAR {
    public:
		ListOfCHARSTAR(char *, ListOfCHARSTAR *);
		~ListOfCHARSTAR();

	char *		str;
	ListOfCHARSTAR *next;
};

#endif

#include <limits.h>	// for INT_MAX

#include <tcl.h>
#include <tk.h>

#define strieql(a,b) (strcasecmp((a),(b))==0)

static char *stralloc(char *s) {
    /*return s?(char*)strcpy((char*)malloc(strlen(s)+1),s):NULL;*/
    return (char*)strcpy((char*)malloc(strlen(s)+1),s);
}


// yes, should probably be something other than a global
static double cap_fudge = 0.0;
int rc_index;

// declare POINT data structure

class POINT {
    public:

		// used to create a temporary
		// automatic variable	
		// ... only x and y are used
		POINT() 
		{
		    x = y = 0;
		    sizex = sizey = 0;
		    strcpy(instance_name,"uninited");  // just to be safe
		    strcpy(port_name,"uninited");
		    dir = 0;
		    next = NULL;
		    instno = 0;
		}

		// used to create internal points
		// during compute-route
		POINT(POINT *argpt, POINT **generated_point_list) 
		    : x(argpt->x), y(argpt->y), next(NULL), sizex(0), sizey(0)
		{
		    strcpy(instance_name,argpt->instance_name);
		    strcpy(port_name,argpt->instance_name);
		    dir = argpt->dir;
		    // instance name will be net name;
		    // we can figure it when putting out
		    instno = next_instno++;

		    // link this onto generated point list
		    next = *generated_point_list;
		    *generated_point_list = this;
		}

		// used to construct points from input list
		POINT(int argx, int argy, 
		    char *arginstance_name, char *argport_name, char argdir,
		    POINT *argnext = NULL) 
		{
		    x = argx;
		    y = argy;
		    sizex = sizey = 0;
		    strncpy(instance_name,arginstance_name,MAX_NAME);
		    instance_name[MAX_NAME] = 0;
		    strncpy(port_name,argport_name,MAX_NAME);
		    port_name[MAX_NAME] = 0;
		    dir = argdir;
		    next = argnext;
		    instno = 0;
		}

                // destructor
		~POINT()
		{
			if (next)	delete next;
		}

		// manhattan distance
	int	distance(POINT *from);

	BOOLEAN	eq(POINT *);	// same point?

	void print() {
	    printf("%s %s %c x=%d y=%d sizex=%d sizey=%d\n",
		instance_name,port_name,dir,
		x,y,sizex,sizey);
	}

	// Return the name of the point.
	char *get_name();

	static unsigned	int	next_instno;

	int	x;
	int	y;


	char	instance_name[MAX_NAME+2];
	char	port_name[MAX_NAME+2];
	char    full_name[2*MAX_NAME+2];
	char	dir;
	int	instno;	// non-zero only for generated points.


	POINT	*next;	// ... in some ListOfPOINT
	int	sort;	// used for sorting list of pts; maybe 
			// something else

	int	sizex;
	int	sizey;
	
};
unsigned int POINT::next_instno = 1;


class BOX {
    public:
		BOX(POINT *argpt1, POINT*argpt2) 
		{
			// enforce x1 <= x2
			if (argpt1->x <= argpt2->x) {
				pt1 = argpt1;
				pt2 = argpt2;
			} else {
				pt1 = argpt2;
				pt2 = argpt1;
			}
			next = NULL;
			previous = NULL;
		}

		~BOX()
		{
			if (next)	delete next;
		}

		// compute minimal distance from point to somewhere on
		// box perimiter; remember what nearest point is
	int	distance(POINT *from, POINT *nearest);

		// compute manhatan distance of box diagonal
	int	sizex();
	int	sizey();

		// make this box into two boxes joined at the point
	void	split(POINT *);

	POINT	*pt1;	// pt1->x is <= pt2->x
	POINT	*pt2;

	BOX	*next;	// ...in some ListOfBOX
	BOX	*previous;
};

class NET {
    public:

		NET(char *arg_name) 
		    : point_list(NULL), box_list(NULL),
		    generated_point_list(NULL)
		{
			if (arg_name != NULL) {
				strncpy(name, arg_name, MAX_NET_NAME_SIZE);
				name[MAX_NET_NAME_SIZE] = '\0';
			} else {
				sprintf(name, "NET_%d", name_index++);
			}
		}

		~NET()
		{
			if (point_list != NULL) delete point_list;
			if (box_list != NULL)	delete box_list;
			if (generated_point_list != NULL) 
						delete generated_point_list;
		}

		// add the arg to the front of the pointlist
	rc_t	add_point(POINT *);

		// do the steiner thing
	rc_t	compute_route();

		// write the output file
	rc_t	write_DSPF();

		// remove the first point from the front 
		// of thepoint list & return it
	POINT	*take();
	POINT	*taken_list;

		// reorder the point list into increasing
		// distance from first point	
	void	sort_point_list();

		// list of port locations on this net
	POINT	*point_list;	

		// list of connecting segments, sort of...
	BOX	*box_list;

		// list of generated intermediate non-port segment junctions
	POINT	*generated_point_list;

		// we make up name if not supplied to constructor
	char	name[MAX_NET_NAME_SIZE+1];	
	static	int	name_index;

	// where to put added points
	static NET	*current_net;

	void print() {
	    POINT *p;
	    printf("net %s\n",name);
	    for (p = point_list; p; p = p->next) p->print();
	    printf("done\n");
	}
};

int NET::name_index = 1;
NET *NET::current_net = NULL;


// DPC opens the file & writes the header 
// it passes the file descriptor in "output_file" call
// which we convert to a FILE pointer with fdopen.

class DSPF_FILE {
    public:
		DSPF_FILE(int arg_fd,
			  double arg_rconstx, double arg_rconsty,
			  double arg_cconstx, double arg_cconsty, 
			  double arg_min_rc,
			  char *arg_string, int arg_pt)
		  : fd(arg_fd), string(arg_string?stralloc(arg_string):NULL), pt(arg_pt)
		{

			rconstx = arg_rconstx;
			rconsty = arg_rconsty;
			cconstx = arg_cconstx/2; //see note below,
			cconsty = arg_cconsty/2; //at declaration

			min_rc = arg_min_rc * 4.0e15; // convert to RC/2 in fs

			fid = fdopen(arg_fd, "w");
			if (fid == NULL) {
				printf("fdopen DSPF file failed\n");
			}

			DSPF_FILE::current_file = this;		//... static guy...
		}

	static DSPF_FILE *	current_file;	

		// multipliers.... R = rconst * length, C = cconst * length
		// ... cconst as stored should be divided by 2
		// since segment capacitance is distributed to 2 endpoints
		// (this way we divide just once, rather than everywhere...)

	double	rconstx;
	double	rconsty;
	double	cconstx;
	double	cconsty;
	double	min_rc;
	char *	string;  // never deallocated, but who cares
        int     pt;
  
	int	fd;
        FILE *  fid;

};

DSPF_FILE *DSPF_FILE::current_file = NULL;

rc_t
NET::add_point(POINT *arg_pt)
{
	arg_pt->next = point_list;
	point_list = arg_pt;
	return RC_NOMINAL;
}

rc_t
NET::compute_route()
{
	sort_point_list();

	// initialize box_list with box defined by first two points
        // if there is only 1 point, eventually don't make any output
	if (point_list->next == NULL) {
		box_list = NULL;
		return RC_NOMINAL;
	}
	taken_list = NULL;

	box_list = new BOX(take(), take());

	// take points off point_list, extend box_list 
	// to accomodate each one in turn
	while (point_list != NULL) {

		POINT *new_pt = take();	// next point to get merged in

		// find closest BOX in box_list

		BOX *near_box = NULL;	// nearest box so far
		int distance = INT_MAX;	// closest distance so far
		POINT near_pt;		// nearest point on nearest box
					// ...need to make a *real* pt later...
		POINT box_pt;		// nearest point on trial box

		BOX *bl = box_list;	// try each box generated so far....
		while (bl != NULL) {
			int d = bl->distance(new_pt, &box_pt);
			if (d < distance) {	// new closest
				distance = d;
				near_box = bl;
				near_pt.x = box_pt.x;
				near_pt.y = box_pt.y;
			}
			if (distance == 0) break;	
			bl = bl->next;
		}

		// new point is inside this box
		// ...won't ever happen if we sort points for distance...
		if (distance == 0) {
			// split the box
			near_box->split(new_pt);
			continue;
		}

		// is the nearest point an existing point?
		// ... the code flow is a bit funny here, I am maybe too busy
		// avoiding making the test twice.

		POINT *corner_pt;
		if (near_pt.eq(near_box->pt1) == true) {
			corner_pt = near_box->pt1;

		} else if (near_pt.eq(near_box->pt2) == true) {
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
			POINT *edge_pt = new POINT(&near_pt, &generated_point_list);
			near_box->split(edge_pt);

			BOX *new_box = new BOX(new_pt, edge_pt);
			new_box->next = box_list->next;
			if (box_list->next != NULL) box_list->next->previous = new_box;
			box_list->next = new_box;
			new_box->previous = box_list;
			
			continue;

		}

		// yes, nearest point is existing point;
		// just make a new box chained of existing point.

		BOX *new_box = new BOX(corner_pt, new_pt);
		new_box->previous = near_box;
		new_box->next = near_box->next;
		if (near_box->next != NULL) near_box->next->previous = new_box;
		near_box->next = new_box;

		continue;
	}

	// list has been reversed, if anybody cares...
	point_list = taken_list;

	return RC_NOMINAL;
}

// Simple n^2 sort algorithm

void
NET::sort_point_list()
{
	// If there is an output pin, it should be the anchor.
	// Otherwise, use any old point as the anchor.
	POINT *anchor = NULL;

	// search for an output pin.
	POINT **prevp;
	for (prevp = &point_list; *prevp; prevp = &(*prevp)->next) {
	    if ((*prevp)->dir == 'O') {
		// unlink the prevp element and save it as the anchor.
		anchor = *prevp;
		*prevp = anchor->next;
		break;
	    }
	}

	if (anchor == NULL) {
	    // No output pin; unlink the first point and save as anchor.
	    anchor = point_list;
	    point_list = point_list->next;
	}

	anchor->sort = 0;	// ... just for prettyness
	anchor->next = NULL;

	POINT *unsorted_list = point_list;
	point_list = anchor;

	while (unsorted_list != NULL) {
		POINT *pt = unsorted_list;
		unsorted_list = unsorted_list->next;

		int distance = anchor->distance(pt);
		pt->sort = distance;

		POINT *insert = point_list;
		while (1) {
			if (insert->next == NULL) {
				insert->next = pt;
				pt->next = NULL;
				break;
			}

			if (distance <= insert->next->sort) {
				pt->next = insert->next;
				insert->next = pt;
				break;
			}

			insert = insert->next;
		}
	}
}


rc_t
NET::write_DSPF()
{
	double rconstx = DSPF_FILE::current_file->rconstx;
	double rconsty = DSPF_FILE::current_file->rconsty;
	double cconstx = DSPF_FILE::current_file->cconstx;
	double cconsty = DSPF_FILE::current_file->cconsty;
	double min_rc = DSPF_FILE::current_file->min_rc;
	// extern double cap_fudge;
	extern int rc_index;

	// compute the capacitance at each point

	BOX *box = box_list;
	while (box != NULL) {
		box->pt1->sizex += box->sizex();
		box->pt1->sizey += box->sizey();
		box->pt2->sizex += box->sizex();
		box->pt2->sizey += box->sizey();

		box = box->next;
	}

	// total all the pt capacitances
	// for original and generated points

	double net_capx = 0;
	double net_capy = 0;
	POINT *point = point_list;
	while (point != NULL) {
		net_capx += (double)point->sizex;
		net_capy += (double)point->sizey;
		point = point->next;
	}
	point = generated_point_list;
	while (point != NULL) {
		net_capx += (double)point->sizex;
		net_capy += (double)point->sizey;
		point = point->next;
	}

	// convert to fF
	double net_capacitance = (cconstx * net_capx) + (cconsty * net_capy);

	if (net_capacitance == 0) {
		// don't do anything
		return RC_NOMINAL;
	}

	net_capacitance += cap_fudge;

	// ... capacitance only ...
	if (DSPF_FILE::current_file->string != NULL) {
	  if (DSPF_FILE::current_file->pt == 1) {
	    // special case for primetime
	    char *each;

	    each = strtok(name, " ");
	    while (1) {
	      fprintf(DSPF_FILE::current_file->fid, "%s%g %s\n", 
		      DSPF_FILE::current_file->string, net_capacitance, each);

	      each = strtok(NULL, " ");
	      if (each == NULL) {
		// done
		break;
	      }
	    }

	  } else {
	    fprintf(DSPF_FILE::current_file->fid, "%s%s %gfF\n", 
		    DSPF_FILE::current_file->string, name, net_capacitance);
	  }

	  return RC_NOMINAL;
	}

	// write DSPF
	// net header
	fprintf(DSPF_FILE::current_file->fid, "\n");

	fprintf(DSPF_FILE::current_file->fid, "*|NET %s %gFF\n", 
		name, net_capacitance);	

	// original points
	point = point_list;
	while (point != NULL) {
		
	  if (strcmp(point->instance_name, "") == 0) {
	    // special case of a toplevel pin
	    // third arg is pin capacitance.
	    fprintf(DSPF_FILE::current_file->fid, "*|P (%s %c %gFF %d %d)\n",
		    point->port_name,
		    point->dir,
		    0.0,
		    point->x,
		    point->y);

	  } else {
	    // it's an instance pin
	    fprintf(DSPF_FILE::current_file->fid, "*|I (%s:%s %s %s %c 0 %d %d)\n",
		    point->instance_name, point->port_name,
		    point->instance_name, point->port_name,
		    point->dir,
		    point->x,
		    point->y);
	  }

	  point = point->next;
	  continue;
	}

	// special case if smaller than min rc, just add a single cap
	double net_res = (rconstx * net_capx) + (rconsty * net_capy);
	if ((net_capacitance * net_res) < min_rc) {
	  // no R's cause they don't matter.
	  point = point_list;
	  fprintf(DSPF_FILE::current_file->fid, "C%d %s VSS %gFF\n",
		  rc_index++, point->get_name(), 
		  net_capacitance);

	  return RC_NOMINAL;
	}

	// generated points
	point = generated_point_list;
	while (point != NULL) {

		fprintf(DSPF_FILE::current_file->fid, "*|S (%s)\n",
		    point->get_name());

		point = point->next;
	}

	// capacitors
	int cap_fudged = 0;

	// ... same as just below, different point list
	point = point_list;
	while (point != NULL) {
		
		double capacitance = (cconstx * (double)point->sizex) +
		  (cconsty * (double)point->sizey);

		if (!cap_fudged) {
		  capacitance += cap_fudge;

		  // only do this once
		  cap_fudged = 1;
		}

		fprintf(DSPF_FILE::current_file->fid, "C%d %s VSS %gFF\n",
		    rc_index++, point->get_name(),
		    capacitance);

		point = point->next;
	}
	
	// ... same as just above, different point list
	point = generated_point_list;
	while (point != NULL) {
		
		double capacitance = (cconstx * (double)point->sizex) +
		  (cconsty * (double)point->sizey);

		fprintf(DSPF_FILE::current_file->fid, "C%d %s VSS %gFF\n",
		    rc_index++, point->get_name(), capacitance);

		point = point->next;
	}

	// resistors	
	box = box_list;
	while (box != NULL) {

		double resistance = (rconstx * (double)(box->sizex())) +
		  (rconsty * (double)(box->sizey()));

		fprintf(DSPF_FILE::current_file->fid, "R%d %s %s %g\n", 
			  rc_index++, box->pt1->get_name(),
			  box->pt2->get_name(), resistance);


		box = box->next;
	}
	
	return RC_NOMINAL;
}

POINT *
NET::take() 
{
	if (point_list == NULL) {
		printf("tried to take from empty point_list\n");
		exit(1);
	}

	POINT *retv = point_list;
	point_list = point_list->next;

	retv->next = taken_list;
	taken_list = retv;

	return retv;
}

// compute the distance from the point to the box
// create near_pt which is the closest point on the box

int
BOX::distance(POINT *arg_pt, POINT *near_pt)
{
	// ... since x1 <= x2 ...
	if (arg_pt->x <= pt1->x)		near_pt->x = pt1->x;
	else if (arg_pt->x >= pt2->x)		near_pt->x = pt2->x;
	else					near_pt->x = arg_pt->x;

	// ... but we don't know about y1 vz. y2
	if (pt1->y <= pt2->y) {			// box goes up & right
		if (arg_pt->y <= pt1->y) 	near_pt->y = pt1->y;
		else if (arg_pt->y >= pt2->y)	near_pt->y = pt2->y;
		else				near_pt->y = arg_pt->y;
			
	} else {				// box goes down & right
		if (arg_pt->y <= pt2->y) 	near_pt->y = pt2->y;
		else if (arg_pt->y >= pt1->y)	near_pt->y = pt1->y;
		else				near_pt->y = arg_pt->y;
	}


	// return manhattan distance from arg_pt to near_pt 
	// ... might be 0

	return arg_pt->distance(near_pt);
}


int
BOX::sizex()
{
	return (abs(pt1->x - pt2->x));
}

int
BOX::sizey()
{
	return (abs(pt1->y - pt2->y));
}

void
BOX::split(POINT *arg_pt)
{
	// change this box to go from pt1 to arg_pt;
	// splice in a new box from arg_pt to pt2

	BOX *new_box = new BOX(arg_pt, pt2);
	pt2 = arg_pt;

	new_box->previous = this;
	new_box->next = next;
	if (next != NULL) next->previous = new_box;
	next = new_box;
}

// distance from one point to another point

int
POINT::distance(POINT *arg_pt)
{
	int xoff = abs(x - arg_pt->x);
	int yoff = abs(y - arg_pt->y);
	return xoff + yoff;
}


BOOLEAN
POINT::eq(POINT *arg_pt)
{
	if (x == arg_pt->x && y == arg_pt->y)	return true;
	else					return false;
}

char *POINT::get_name() {
    if (instno > 0) {
	// It is a generated point.
	sprintf(full_name,"%s:%d",NET::current_net->name,instno);
    } else if (instance_name[0] == 0) {
	// It is a port
	sprintf(full_name,port_name);
    } else {
	// It is an instance port
	sprintf(full_name,"%s:%s",instance_name,port_name);
    }
    return &full_name[0];
}



//////////////////////////////////////////////////////////////////////////
//// TCL interface functions

extern "C" {

// Usage:
//  steiner_add_point instance_name port_name iodirection x y
//
//  Note: input and output pins may be given in any order.
int
add_point(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
	if (objc != 6) {
	    interp->result = "add_point syntax";
	    return TCL_ERROR;
	}

	if (NET::current_net == NULL) {
		interp->result = "no current net";
		return TCL_ERROR;
	}

	int x;
	int y;
	char dir;

	char *argdir = Tcl_GetStringFromObj(objv[3],NULL);
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
	

	int code = Tcl_GetIntFromObj(interp, objv[4], &x);
	if (code != TCL_OK) return code;

	code = Tcl_GetIntFromObj(interp, objv[5], &y);
	if (code != TCL_OK) return code;

	POINT *new_pt = new POINT(x, y, 
	    Tcl_GetStringFromObj(objv[1], NULL),
	    Tcl_GetStringFromObj(objv[2], NULL),
	    dir);
	    
	NET::current_net->add_point(new_pt);
	return TCL_OK;
}

// Usage:
// steiner_begin_net  netname
int
begin_net(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
	if (DSPF_FILE::current_file == NULL) {
		interp->result = "no current DSPF file";
		return TCL_ERROR;
	}

	if (NET::current_net != NULL) {
		NET::current_net->~NET();	// clean up
	}

	char *name = NULL;
	if (objc > 1) {
		name = Tcl_GetStringFromObj(objv[1], NULL);
	}

	NET::current_net = new NET(name);

	POINT::next_instno = 1;

	return TCL_OK;
}


// Usage:
//  steiner_end_net cap_fudge
//    cap_fudge is an extra capacitance added to this net.
//    Notes: cap_fudge must be a valid floating point number, not "".
int
end_net(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
	if (objc != 2) {
	    interp->result = "end_net syntax";
	    return TCL_ERROR;
	}
	if (NET::current_net == NULL) {
		interp->result = "no current net";
		return TCL_ERROR;
	}

	//NET::current_net->print();

	rc_t rc = NET::current_net->compute_route();
	if (rc != RC_NOMINAL) {
		interp->result = "compute_route failed";
		return TCL_ERROR;
	}

	int code = Tcl_GetDoubleFromObj(interp, objv[1], &cap_fudge);
	if (code != 0) {
	  interp->result = "can\'t read cap_fudge";
	  return TCL_ERROR;
	}

	rc = NET::current_net->write_DSPF();
	if (rc != RC_NOMINAL) {
		interp->result = "write DSPF file failed";
		return TCL_ERROR;
	}

	fflush (DSPF_FILE::current_file->fid);

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
int output_file(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
        // initialize index for R's and C's in DSPF
        rc_index = 1;

	// obj 1 is tcl channel descriptor, like "file6"
	// the number is a Unix file descriptor

	if (objc < 1) {
		interp->result = "need output channel descriptor";
		return TCL_ERROR;
	}
	char *channel_descriptor = Tcl_GetStringFromObj(objv[1], NULL);

	if (strncmp(channel_descriptor, "file", 4) != 0) {
		interp->result = "channel descriptor should be like \"file6\"";
		return TCL_ERROR;
	}
	int file_descriptor = atoi(channel_descriptor + 4);
	if (file_descriptor < 1 || file_descriptor > 64) {
		interp->result = "file descriptor appears to be out of range?????";
		return TCL_ERROR;
	}

	// parse objs
	double rconstx = 1.0;
	double rconsty = 1.0;
	double cconstx = 1.0;
	double cconsty = 1.0;
	double min_rc = 0.0;
	int pt = 0;
	char *string = NULL;

	for (int i = 2; i < objc; i++) {
		char *next = Tcl_GetStringFromObj(objv[i], NULL);

		if (strcmp(next, "-rconstx") == 0) {
			if (++i >= objc) {
				interp->result = "rconstx not specified";
				return TCL_ERROR;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &rconstx);
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
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &rconsty);
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
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &cconstx);
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
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &cconsty);
			if (rc != 0) {
				interp->result = "can\'t read cconsty";
				return TCL_ERROR;
			}
		}				

		else if (strcmp(next, "-min_rc") == 0) {
			if (++i >= objc) {
				interp->result = "min_rc not specified";
				return TCL_ERROR;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &min_rc);
			if (rc != 0) {
				interp->result = "can\'t read min_rc";
				return TCL_ERROR;
			}
		}				

		else if (strcmp(next, "-string") == 0) {
			if (++i >= objc) {
				interp->result = "string not specified";
				return TCL_ERROR;
			}
			string = Tcl_GetStringFromObj(objv[i], NULL);
		}				

		else if (strcmp(next, "-pt") == 0) {
			if (++i >= objc) {
				interp->result = "boolean not specified";
				return TCL_ERROR;
			}
			int code = Tcl_GetIntFromObj(interp, objv[i], &pt);
			if (code != TCL_OK) return code;
		}				

		else {
			interp->result = "unknown objv";
			return TCL_ERROR;
		}
	}

	// open the file
	DSPF_FILE *file = new DSPF_FILE(file_descriptor, rconstx, rconsty,
					cconstx, cconsty, min_rc, string, pt);

	// OK! ready for some nets.
	NET::name_index = 1;
	return TCL_OK;
}



}	// ....extern "C" { ....
