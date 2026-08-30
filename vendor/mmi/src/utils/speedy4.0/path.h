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

#ifndef timing_h
#define timing_h

// PATH captures a logical connection through the circuit, originating
// at an OUTPORT and proceeding through various INSTANCEs and NETs
// to a terminal INPORT.  In the case of DESIGN longpaths, that will
// always be from a clock driver outport or an external input, to a
// latch D-edge or other non-clock latch inport or external output.
// The NETs and INSTANCES are described by an ordered list of PATHELEMENTs.
//
// PATHELEMENT captures one stage in a delay, from OUTPORT to OUTPORT
// that is, OUTPORT -> NET -> INPORT -> INSTANCE (OUTPINTIMING) -> OUTPORT
// we save the terminal outport and the intermediate inport; we can
// get to the initial outport as previous->outport.
//
// It is in order to keep things regular here that EXTCONNs are
// akindof INSTANCE. 
// ...for inputs, the signal enters through an OUTPORT, which is the
// source of a NET in the usual way.  There *is* an INPORT on the
// "other" or "hyperspace" side, which is not connected in the simple
// case... the timing model of the input provides a fixed delay and
// drive from the ideal clock, exactly similar to FF clock-to-Q.
// So there is no "previous" pathelement.
// ...for outputs, the signal exits through an INPORT, ya-dee-da
// same as above... has a setup delay exactly similar to FF D-edge.
// 
// In more complicated cases, the external drive/load might be 
// separately modeled, but from the PATH point of view it's a
// series of PATHELEMENTs (ie, gate-outport-net-inport) until
// you get to a gate with no active inport, referenced to CLOCK.
// Etc ouputs. 
//
//
//
//
// NOTE, here is the external model I thrashed out with Pat.
// For display purposes there isn't any particular advantage to 
// make a list of uniform objects, so we make a rotating sequence
// of 4 types, 
//	I	inport		name	absolute-delay
//	G	gate... ie, INSTANCE, but 'I' was taken
//				name	cellname    arc-delay
//	O	outport		name	absolute-delay
//	N	net		name	net-delay
//	I
//	G
//	... &c.
//
// In the most ordinary case of things, a PATH begins and ends
// with a G-INSTANCE (begins with input or a FF with a Q, 
// ends with output or FF with a D), that is:
//	G O N I G O N I ... N I G
//
//
//
//
// warning, PHILOSOPHICAL SELF-JUSTIFICATION FOLLOWS: 
// In a world of alternating nets and instances, 
// there seems to be two ways of makeing PATHs to be  
// a list of uniform thingys (which I want to do to shorten 
// the list-handling code and reduce the number of separately 
// allocated objects, of which I already have a great number)
// ....represent the PATH's ELEMENTs
// as NET followed by INSTANCE, or as INSTANCE followed by NET.  
//
//	.... and I CONSTANTLY confuse myself as to 
//	WHICH I am doing.  See drawings. Uck.
//
//	a PE is *actually* an IGON, 
//	although I seem to think it's a GONI.
//
//
//
// Pearl has done the latter, but since NETs generally have
// a unique source but several loads, the PATHELEMENT delay
// depends on a which load is next, which is information 
// outside the pathelement where the NET is.
// It doesn't actually help to "enclose" the NET because the
// INSTANCE's inport has the same problem: we have to get the
// gate delay by looking to previous->inport.  But at least
// we do have a pointer to previous.
//
//


/////////////////////////////////////////
// forward declarations

#include	"lib.h"

class PATHELEMENT;
class INPORT;
class OUTPORT;
class INSTANCE;
class ListOfINSTANCE;


//////////////////////////////////////

class PATH {
    public:
		PATH(INPORT *, PATHELEMENT *);	 // for building from dest
		PATH(OUTPORT *, BOOLEAN rising); // for building from source
		PATH(PATH &);			
		~PATH();

	INPORT *	destination_inport;  
	float		setup_delay;	
	float		absolute_delay;		// includes setup & extra

	PATHELEMENT *	final_pathelement;

	float		compute_final_timing();	// return ablsolute_delay
	float		compute_complete_path();

	BOOLEAN		is_same_path(PATH *);

	rc_t		write_to_file(FILE *);

	// ... obsolete, or just born ugly?
	void		print_like_pearl(FILE *);

};



class PATHELEMENT {
    public:
		// PATHELEMENT();
		PATHELEMENT(OUTPORT *, BOOLEAN rising_at_outport);
		PATHELEMENT(OUTPORT *, INPORT *, OUTPINTIMING *);
		PATHELEMENT(INPORT *, OUTPORT *, CELL *, PATHELEMENT *);
		~PATHELEMENT();


	// .... paramaters ....		
	OUTPORT *	outport;
	INPORT *	inport;
	OUTPINTIMING *	outpintiming;
	BOOLEAN		rising_at_outport;
	PATHELEMENT *	previous;
			// XXX ... should outport->load and inport->net_delay be here?		

	// .... computed values ....
	float		slope_at_outport;
	float		gate_delay;
	float		absolute_delay;

	BOOLEAN		compute_timing();
	rc_t		compute_complete_path();

	void		clear();	// ... doesn't clear everything, be careful
	void		update_from(PATHELEMENT *);

	BOOLEAN		is_same_path(PATHELEMENT *);	// helper for PATH method

	rc_t		write_to_file(FILE *);

	// ... obsolete, or just born ugly?
	void		print_like_pearl(FILE *);
};

class ListOfPATH {
    public:
		ListOfPATH(PATH *, ListOfPATH *);
		ListOfPATH(ListOfPATH &);
		~ListOfPATH();


	PATH *		path;
	ListOfPATH *	next;
};

class ListOfPATHELEMENT {
    public:
		ListOfPATHELEMENT(PATHELEMENT *, ListOfPATHELEMENT *);
		~ListOfPATHELEMENT();

	void		delete_members();

	PATHELEMENT *		pathelement;
	ListOfPATHELEMENT *	next;
};


// What to do about circular paths?
// ... during get_downstream_instances, when we return to a previously 
// inspected instance, print a warning message and break the path.
// It's not treated as a path destination, just a dead end.

class DOWNSTREAM {
    public:
			DOWNSTREAM();
			~DOWNSTREAM();

	ListOfINSTANCE *root_instancelist;	// the calling guy is responsible for 
					// makeing sure that the root_instancelist gets
					// deleted at an appropriate time
	void		init();

	INSTANCE **	instancearray;	// both ends are NULL, ie instancearray[0] 
					// and instancearray[topindex + 1]
					// ... so we can say (while *(++iap) != NULL) ...
	int		instancearray_topindex;	// last used slot
					// ... so there are "topindex" instances 
					// valid instance indexes start with 1, 
					// end with topindex
	int		instancearray_max;	// maximum number of instances
					// ... so array size is max + 2 

	ListOfPATH *	pathlist;	// pathlist is created during get_downstream_instances...
	
	rc_t		get_downstream_instances(ListOfINSTANCE *);	// user function
	BOOLEAN		get_downstream_instances(INPORT *);		// helper ... returns true if there's a path thataway
	void		clean_instances();				// cleanup ... set "did_this_one" to 0

	rc_t		compute_timing();			// update all the outports
	rc_t		compute_global_timing();		// update _long_path rather than _ds_path
	rc_t		compute_timing_and_update_long_path();	// for downsize_for_area ...
								// see .cc for caveats

	ListOfPATHELEMENT *get_slow_nodes();	// ... instances with outports where rising or 
						// falling_long_path slope > maximum_desireable_slope

	float		get_long_delay();	// look through pathlist
	float		long_delay;
	PATH *		long_path;

	ListOfPATH *	get_long_pathlist(int howmany);		// look through pathlist

	// ... debug
	BOOLEAN		ds_paths_are_clear;
	void		find_instance(char *);
	void		print_instance(int);
};


#endif
