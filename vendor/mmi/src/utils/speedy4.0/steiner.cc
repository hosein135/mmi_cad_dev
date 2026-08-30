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

#include "util.h"

// Local Declaration

// steiner box....
// a temporary structure only used during steiner routing....
// we recast the iformation and save it as SEGMENTs..	
class SBOX {
    public:
		SBOX(PORT *arg_port1, PORT*arg_port2, SBOX *);
		~SBOX();

	// compute minimal distance from port to somewhere on
	// box perimiter; remember what nearest port is
	int		distance(PORT *from, int *xy, int *yp);

	// compute manhatan distance of box diagonal
	int		sizex();
	int		sizey();

	// make this box into two boxes joined at the port
	void		split(PORT *);

	PORT *		port1;	// port1->x <= port2->x
	PORT *		port2;

	// ...as opposed to usual practice, SBOXs form
	// a singly-linked list... no "ListOfSBOX" class...
	// NET::steiner_route puts them in no particular order...
	SBOX *		next;

};


//////////////////////////////////////////////

int nsboxes = 0;

SBOX::SBOX(PORT *arg_port1, PORT*arg_port2, SBOX *arg_next)
    : next(arg_next)
{
	// debug...
	nsboxes++;

	// enforce x1 <= x2
	if (arg_port1->x <= arg_port2->x) {
		port1 = arg_port1;
		port2 = arg_port2;
	} else {
		port1 = arg_port2;
		port2 = arg_port1;
	}
}

SBOX::~SBOX()
{
	if (next != NULL)	delete next;
}

int
SBOX::distance(PORT *arg_port, int *arg_xp, int *arg_yp)
{
	// ... since x1 <= x2 ...
	if (arg_port->x <= port1->x)			*arg_xp = port1->x;
	else if (arg_port->x >= port2->x)		*arg_xp = port2->x;
	else						*arg_xp = arg_port->x;

	// ... but we don't know about y1 vz. y2
	if (port1->y <= port2->y) {		// box goes up & right
		if (arg_port->y <= port1->y)		*arg_yp = port1->y;
		else if (arg_port->y >= port2->y)	*arg_yp = port2->y;
		else					*arg_yp = arg_port->y;
			
	} else {				// box goes down & right
		if (arg_port->y <= port2->y)		*arg_yp = port2->y;
		else if (arg_port->y >= port1->y)	*arg_yp = port1->y;
		else					*arg_yp = arg_port->y;
	}

	// return manhattan distance from arg_port to near_port 
	// ... might be 0

	return arg_port->distance(*arg_xp, *arg_yp);
}

void
SBOX::split(PORT *arg_port)
{
	// change this box to go from port1 to arg_port;
	// splice in a new box from arg_port to port2

	SBOX *new_box = new SBOX(arg_port, port2, this->next);
	port2 = arg_port;

	this->next = new_box;
}

rc_t
NET::steiner_route()
{
	// printf("steiner route net \"%s\"\n", name);
	if (this == fave_net) {
	    printf("gotcha 33\n");
	}

	if (global_value != NOT_GLOBAL)		return RC_NOMINAL;
	int node_index = 1;

	// create a POINT for each PORT in the portlist
	// sort them into increasing distance from the first point
	ListOfPORT *sorted_portlist = sort_ports();
	ListOfPORT *pl = sorted_portlist;

	if (pl == NULL		||
	    pl->next == NULL	) {
		return RC_NOMINAL;
	}

	// initialize sboxlist with box defined by first two points
	// ...as opposed to usual practice, SBOXs form
	// a singly-linked list... no "ListOfSBOX" class...
	PORT *p1 = pl->port;
	pl = pl->next;

	PORT *p2 = pl->port;
	pl = pl->next;

	SBOX *sboxlist =  new SBOX(p1, p2, NULL);

	// take points off point_list, extend box_list for each
	while (pl != NULL) {
		PORT *new_port = pl->port;	// next point to get merged in
		pl = pl->next;

		// find closest box in the boxlist
		SBOX *near_box = NULL;	// nearest box so far
		int distance = INT_MAX;	// closest distance so far

		int near_x;		// nearest point on nearest box
		int near_y;	

		int try_x;		// nearest point on trial box
		int try_y;

		SBOX *sbl = sboxlist;	// try each box generated so far....
		while (sbl != NULL) {
			int d = sbl->distance(new_port, &try_x, &try_y);
			if (d < distance) {	// new closest
				distance = d;
				near_box = sbl;
				near_x = try_x;
				near_y = try_y;
			}
			if (distance == 0) break;	
			sbl = sbl->next;
		}

		// ... since new_pt is at least as far from anchor
		// as any previous point, it can't be inside any
		// existing box.

		// is the nearest point an existing point?
		if (near_x == near_box->port1->x &&
		    near_y == near_box->port1->y) {
			// yes...
			sboxlist = new SBOX(near_box->port1, new_port, sboxlist);

		} else if (near_x == near_box->port2->x &&
		     near_y == near_box->port2->y) {
			// yes...
			sboxlist = new SBOX(near_box->port2, new_port, sboxlist);

		} else {
			// no; 
			// nearest point is along one of the sides,
			// so we have to break the box into one 
			// degnerate box (corresponding to the side)
			// and one open (or not) box, then add
			// a degenerate box from the nearest point to 
			// the new point
	
			PORT *edge_port = new NODE(this, near_x, near_y, node_index++);
			near_box->split(edge_port);

			// ...and here is the 3rd box at the edge_pt...
			sboxlist = new SBOX(new_port, edge_port, sboxlist); 
			
		}
		continue;
	}

	// now convert SBOXes to SEGMENTs & get them linked into nice tree
	// ... more recursion! yea!
	// make a temp segment to get started on
	source->segment = new SEGMENT(source);

	sboxlist = source->segment->collect_connected_segments(sboxlist);
	if (sboxlist != NULL)	printf("NET::steiner_route: net \"%s\": didn\'t catch all the sboxes\n", get_name());

	delete sorted_portlist;	
	return RC_NOMINAL;
}
	
ListOfPORT *
NET::sort_ports()
{
	if (source == NULL	&&
	    inportlist == NULL	) {
		return NULL;
	}

	PORT *anchor = source;
	ListOfPORT *portlist = new ListOfPORT(anchor, NULL); 

	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		PORT *port = ipl->inport;
		ipl = ipl->next;

		ListOfPORT *insert = portlist;
		while (1) {
			// ... this recomputes distances a lot, but there isn't any
			// convenient place to store the result.  Don't want to make 
			// it a permanent data member, & this is probably cheaper than
			// allocating some new ListOfthingy.

			if (insert->next == NULL						||
			    port->distance(anchor) <= insert->next->port->distance(anchor)	) {
				ListOfPORT *newpl = new ListOfPORT(port, insert->next);
				insert->next = newpl;
				break;
			}

			insert = insert->next;
		}
	}
	return portlist;
}


SBOX *
SEGMENT::collect_connected_segments(SBOX *arg_sboxlist)
{
	// search the given list of sboxes for boxes that have ports which are our right_end
	// remove them from the list, and create a segment that gets added to local segmentlist.
	// call each of the new segments to collect *their* connected segments from the reduced sboxlist.
	// return the remaining sboxlist, those sboxes that don't hook up along this branch.

	SBOX *sboxlist = arg_sboxlist;
	while (sboxlist != NULL) {
		if (sboxlist->port1 == right_end) {
			SEGMENT *segment = new SEGMENT(sboxlist->port2);
			segmentlist = new ListOfSEGMENT(segment, segmentlist);
			sboxlist = sboxlist->next;
		} 

		else 
		if (sboxlist->port2 == right_end) {
			SEGMENT *segment = new SEGMENT(sboxlist->port1);
			segmentlist = new ListOfSEGMENT(segment, segmentlist);
			sboxlist = sboxlist->next;
		} 

		else break;
	}		
	if (sboxlist == NULL)	return NULL;	

	SBOX *sbl = sboxlist;
	while (sbl->next != NULL) {
		if (sbl->next->port1 == right_end) {
			SEGMENT *segment = new SEGMENT(sbl->next->port2);
			segmentlist = new ListOfSEGMENT(segment, segmentlist);
			sbl->next = sbl->next->next;
		} 

		else 
		if (sbl->next->port2 == right_end) {
			SEGMENT *segment = new SEGMENT(sbl->next->port1);
			segmentlist = new ListOfSEGMENT(segment, segmentlist);
			sbl->next = sbl->next->next;
		} 

		else sbl = sbl->next;
	}

	ListOfSEGMENT *sgl = segmentlist;
	while (sgl != NULL) {
		SEGMENT *segment = sgl->segment;
		sgl = sgl->next;
	
		sboxlist = segment->collect_connected_segments(sboxlist);
	}

	return sboxlist;
}

