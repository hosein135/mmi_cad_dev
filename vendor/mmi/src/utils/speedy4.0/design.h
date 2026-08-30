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


#ifndef design_h
#define design_h

#define LINEBUFSIZE	0x1000

class PORT;
class INPORT;
class EXTCONN;
class ListOfEXTCONN;
class NET;
class COPY_NET;
class ListOfNET;
class SEGMENT;
class ListOfSEGMENT;
class INSTNCE;
class COPY_INSTANCE;
class ListOfINSTANCE;
class CELL;


class ListOfGLOBAL;
class CLONE;
class ListOfCLONE;
class PATH;
class ListOfPATH;
class PATHELEMENT;
class DOWNSTREAM;

class SBOX;
class ListOfROUTE;

/////////////////////////////////////////////////////////////////
//
// These class members always refer to a valid class instance:
//	INPORT::instance
//	OUTPORT::instance
//	INSTANCE::cell
//	NET::source	
//


/////////////////////////////////////////////////////////////////

enum GLOBAL_VALUE {
	NOT_GLOBAL,

	GLOBAL_ONE,
	GLOBAL_ZERO,
	GLOBAL_UNKNOWN,

	GLOBAL_UNCONNECTED,
	GLOBAL_DUMMYSOURCE,

	GLOBAL_CYCLEBREAKER,	// set by DOWNSTREAM::get_downstream_instances
				// when a cycle is discovered; prevents looping 
				// during timing, but may suppress interesting paths;
				// really the designer should handle it.

	GLOBAL_CLOCK		// clock net				
};


/////////////////////////////////////////////////////////////////
// .... design .....

// Top Level of flattened view
// basicly, consists of 3 types of entities: INSTANCEs, NETs, and EXTCONNS...
// which are interconnected.

class DESIGN {
    public:
		DESIGN();
		~DESIGN();

	// to be run after design has been loaded... 
	rc_t		complete_initialization();
	rc_t		compute_net_characteristics();

	ListOfNET *	netlist;
	ListOfNET *	globalnetlist;
	ListOfINSTANCE *instancelist;
	ListOfEXTCONN *	extconnlist;


	ListOfINSTANCE *dummysourcelist;	// globals, sources for nets with no sources, etc.
	rc_t		new_dummysource(NET *);

	NET *		unconnected_inport_net;		// parking place for unconnected inports
							// .... need 1 each global net for unconnected outports, too bad...
	NET *		unconnected_clock_inport_net;	// special treatement for clock pins, so timing will work

	ListOfCELL *	unidentified_celllist;
	ListOfINSTANCE *unidentified_instancelist;
	INSTANCE *	get_unidentified_instance(char *pathname);

	NL_INTERFACE *	nl_interface;

	NET *		new_net(NL_INET);
	INSTANCE *	new_instance(NL_ICELL);
	EXTCONN *	new_extconn(NL_IPORT);

	CLONE *		new_clone(INSTANCE *instance, NL_CELL, NL_DESIGN, char *name);

	int		n_nets;
	int		n_instances;
	int		n_extconns;
	int		n_clones;
	int		Q_count;		// how many flops? (...clock-to-Q arcs)

	// accessors
	INSTANCE *	get_instance(char *pathname);
	NET *		get_net(char *pathname);
	EXTCONN *	get_extconn(char *portname);

	rc_t		remove_instance(INSTANCE *);
	rc_t		remove_net(NET *);

	ListOfINSTANCE *removed_instancelist;
	ListOfNET *	removed_netlist;

	// during loading.... create one if it doesn't exist already
	NET *		get_net_for_global(char *global_name, PORT *);

	rc_t		compute_net_rc();		// rewhack all nets...    

	// parition into clone sets 
	ListOfCLONE *	clonelist;

	// New! copy feature! under development!
	rc_t		add_precursors(COPY_INSTANCE *, BOOLEAN add_input_extconns);
	COPY_INSTANCE *	add_copy(INSTANCE *);
	COPY_NET *	add_copy(NET *);

	////////////////////
	// global timing

	rc_t		initialize_global_downstream();
	rc_t		global_timing();

	DOWNSTREAM *	global_downstream;	

	// find all paths
	float		find_long_delay(INPORT *);	
	rc_t		find_all_paths();
	rc_t		find_all_paths_add_path(PATH *);
	int		path_count;
	double		total_pe_count;
	int		largest_pe_count;
	float		all_paths_long_delay;	

	////////////////////
	// resize 
	rc_t		resize_instances_by_threshold();	// ... according to output load
	rc_t		resize_clones_by_threshold();

	rc_t		try_to_downsize_instances();	
	rc_t		try_to_downsize_clones();	

	rc_t		optimize_long_path_by_clones();
	rc_t		optimize_path_by_clones(PATH *, int *upsize_count, int *downsize_count);

			// ... interesting ... but there isn't any way to put them back...
	rc_t		optimize_long_path_by_instances();
	rc_t		optimize_path_by_instances(PATH *, int *upsize_count, int *downsize_count);

	rc_t		resize_to_minimum();		// ... min 
	rc_t		resize_to_maximum();		// ... max

	rc_t		downsize_for_area_by_instances();	// for area
	rc_t		downsize_for_area(char *instancename);	// just this one
	rc_t		downsize_for_area_by_clones();
	rc_t		profile_slack_by_instances(char *filename);	// print a count for intervals
									// ... if filename, write weight file for placer

	// resize helpers
	rc_t		save_cell_pointers();		// capture current state
	rc_t		restore_saved_cell_pointers();
	rc_t		restore_nominal_cells();

	ListOfCLONE *	resized_clonelist;
						// ensure that all members of a clone are 	
						// set to the largest size of any of them
	rc_t		collect_clones();	// also from NL_INTERFACE::collect_nl_clones


	//////////////////////////
	// write libfile 
	void		clear_instance_pathlists();

	
	//////////////////////////
	// saved path
	PATH *	saved_path;	


	////////////////////
};


/////////////////////////////////////////////////////////////////
// .... ports .....

// basicly represents a fixed location
// INPORTs and OUTPORTs are points where a NET is connected to an INSTANCE or an EXTCONN
// (IN and OUT are with respect to the instance; 
// an OUTPORT is a NET source, an INPORT is a NET load)
// INPORTs and OUTPORTs connected to EXTCONNs have instance pointer NULL; 
// they are identified with a specific extconn by name
// NODEs are intermediate points on NETs
// PORTs are connected by SEGMENTs

// for non-cplusplusies: ...this is a class hierarchy....
// class PORT defines a purely virtual class... that is, all constructed
// instances are of one of the three subtypes; get_type() says which.
// The advantage is that we can mix subtypes, eg in segments use the same
// data member for INPORTs and NODEs.

enum PORTTYPE {INPORT_TYPE, OUTPORT_TYPE, NODE_TYPE};

class PORT {
    public:
		PORT(PORTTYPE, NET *);
		PORT(PORT &);
		~PORT();

	PORTTYPE	type;
	NET *		net;		
	
	// physical location
	int		x;
	int		y;

	char *		pathname;	// this is fully-qualified (eg, from dspf) .... for extconns, = net name
					// use inpin/outpin->name if that's what's wanted

	// delay on connected net, from net->source to here
	float		net_delay;

	// manhattan distance
	int		distance(PORT *from);
	int		distance(int from_x, int from_y);

	// same point? (...same location...)
	BOOLEAN		eq(PORT *);

};

class ListOfPORT {
    public:
		ListOfPORT(PORT *, ListOfPORT *);
		~ListOfPORT();

	PORT *		port;
	ListOfPORT *	next;
};


class INPORT : public PORT {
    public:
		INPORT(INPORT &);
		INPORT(INSTANCE *, char *portname);
		INPORT(CELL *, INPORT*);
		~INPORT();
	
	INSTANCE *	instance;	
	INPIN *		inpin;	

	float		tau_Re;	// lower bound on net delay estimate
				// ... see NET::compute_tc_bounds()
};

class ListOfINPORT {
    public:
		ListOfINPORT(INPORT *, ListOfINPORT *);
		~ListOfINPORT();

	void		append(INPORT *);

	INPORT *	inport;
	ListOfINPORT *	next;
};

class OUTPORT : public PORT {
    public:
		OUTPORT(OUTPORT &);
		OUTPORT(INSTANCE *, char *portname);
		OUTPORT(CELL *, OUTPORT *);
		~OUTPORT();

	INSTANCE *	instance;	
	OUTPIN *	outpin;	

	float		load_capacitance;

	SEGMENT *	segment;	// notice that this is a SEGMENT, not a ListOfSEGMENT.
					// OUTPORT::segment->right_end is the OUTPORT;
					// OUTPORT::segment->segmentlist is the set of SEGMENTs originating here.
					// It's done this way to eliminate a special case in the recursive 
					// algorithms that assemble & traverse SEGMENT trees.

	////////////////////
	// global timing

	PATHELEMENT * 	rising_long_path;
	PATHELEMENT *	falling_long_path;

	PATHELEMENT *	rising_ds_path;
	PATHELEMENT *	falling_ds_path;

};

class ListOfOUTPORT {
    public:
		ListOfOUTPORT(OUTPORT *, ListOfOUTPORT *);
		~ListOfOUTPORT();

	OUTPORT *	outport;
	ListOfOUTPORT *	next;
};

class NODE : public PORT {
    public:
		NODE(NET *);
		NODE(NET *, int x, int y, int index);
		~NODE();

	int		index;	// sequence number with a net
};

class ListOfNODE {
    public:
		ListOfNODE(NODE *, ListOfNODE *);
		~ListOfNODE();

	NODE *		node;
	ListOfNODE *	next;
};


/////////////////////////////////////////////////////////////////
// .... instances .....

// An INSTANCE is the instantation of a particular CELL; 
// may be a basic gate, or something more compliciated.
// The associated CELL contains timing and other generic information.
// 
// EXTCONNs are a subtype of INSTANCE

enum INSTANCETYPE {
	INSTANCE_INSTANCETYPE, 
	INPUT_EXTCONN_INSTANCETYPE,
	OUTPUT_EXTCONN_INSTANCETYPE
};


class INSTANCE {
    public:
		INSTANCE(char *name);
		INSTANCE(NL_ICELL);
    protected:	INSTANCE();
    public:
		virtual ~INSTANCE();

	char *		name;
	INSTANCETYPE	type;

	NL_ICELL	nlicell;
	NL_PCELL	nlpcell;
	CLONE *		nl_clone;

	rc_t		identify(CELL *);		// complete construction
	rc_t		identify(char *cell_name);	// complete construction

	virtual char *	get_name();
	virtual void	get_name(char *buf, int bufsize);

	CELL *		cell;		// this is the active cell

	ListOfINPORT *	inportlist;
	ListOfOUTPORT *	outportlist;

	// look up port by name
	PORT *		get_port(char *portname);
	INPORT *	get_inport(char *portname);
	OUTPORT *	get_outport(char *portname);
		// ... by pin name + index 
		// ... actual index is offset by xxpin->low_index...
	INPORT *	get_inport(char *port_name, int index);
	OUTPORT *	get_outport(char *port_name, int index);
		// ... by pin 
	INPORT *	get_inport(INPIN *);
	OUTPORT *	get_outport(OUTPIN *);

	CLONE *		clone;

	int		did_this_one;

	////////////////////
	// downstream

	rc_t		ds_timing();
	rc_t		ds_global_timing();	// duplicates ds_timing, except updates 
						// OUTPORT::rising/falling_long_path 
						// rather than ..._ds_...
	rc_t		ds_timing_and_update_long_path(); // for downsize_for_area

	
	////////////////////
	// write libfile

	ListOfPATH *	pathlist;	// ... for LIBFILE::write .... 
	void		clear_pathlist();

	////////////////////
	// resize

	CELL *		saved_cell;	// checkpoint cell pointer
	rc_t		resize_by_threshold();
	rc_t		try_upsize();	// ... change instance if it's better
	rc_t		try_downsize(); // ... change instance if it's better
	float		try_resize(CELL *new_cell);	// ... don't make changes... return how much better	
	rc_t		downsize_for_area(float long_path_delay, DOWNSTREAM *);
	rc_t		swap_inport_net_to_fast(INPORT *, INPORT **return_fast_inport, BOOLEAN by_clones);		// ... does the swap if there's a port marked FAST

	rc_t		change_cell(CELL *);
	rc_t		swap_inport_nets(INPORT *, INPORT *, BOOLEAN by_clones);

};

// // XXX ... future feature suggestion:
// // instead of EXTCONNs as special kind of INSTANCE,
// // let's have an unique INSTANCE called "SPEEDY_interface"
// // which has IN/OUTPORTs in the usual way (nearly...)
// // it refers to a unique CELL likewise called "SPEEDY_interface"
// // which has ordinary IN/OUTPINs.
// // ...
// // but this is too messy to get into right now.
// //
// // As things are:
//
// An EXTCONN (EXternal CONNection) is an instance with cell->name
// "external-input" or "external-output"; there's a typedef
// so it can look like a distinct type, which may be confusing
// or hopefully un-confusing.... 
//
// an EXTCONN is connected to exactly one net, consequently it has
// either an inportlist of length 1, or an outportlist of length 1.
//

class EXTCONN : public INSTANCE 
{
    public:
		EXTCONN(char *name, INSTANCETYPE);	// INPUT or OUTPUT extconn_instancetype
		virtual ~EXTCONN();

	float		delay;		// add this to timing path through this extconn
					//	.... input delay or output setup
	float		slope;		// input fixed slope
	CELL *		driver;		// input drive strength
	float		load;		// output external load					     

	NET *		get_net();
};

class ListOfINSTANCE {
    public:
		ListOfINSTANCE(INSTANCE *, ListOfINSTANCE *);
		~ListOfINSTANCE();

 	void			unlink_and_delete();

	INSTANCE *		instance;
	ListOfINSTANCE *	next;
};

class ListOfINSTANCELIST {
    public:
		ListOfINSTANCELIST(ListOfINSTANCE *, ListOfINSTANCELIST *);
		~ListOfINSTANCELIST();

	ListOfINSTANCE *	instancelist;
	ListOfINSTANCELIST *	next;
};

class ListOfEXTCONN {
    public:
		ListOfEXTCONN(EXTCONN *, ListOfEXTCONN *);
		~ListOfEXTCONN();

	EXTCONN *		extconn;
	ListOfEXTCONN *	next;
};



/////////////////////////////////////////////////////////////////
// .... nets .....

// NETs are "wires", running between and connecting PORTs
// *every* NET has exactly one OUTPORT, its "source"
// ... there are dummy sources for global nets
// The GLOBAL_VALUE identifies various types of NETs which are important
// to know about for timing purposes.

class NET {
    public:
		NET(char *name);
		virtual ~NET();

	char *		name;		// might or might not be where we keep the name

		NET(NL_INET);
	NL_INET		nlinet;		

    protected:	NET();			// for COPY_NET
    public:

	virtual char *	get_name();
	virtual void	get_name(char *buf, int bufsize);

	OUTPORT *	source;		// all nets have a source
					// no net has more than one.
					// (an external input is an OUTPORT with NULL instance)

	ListOfINPORT *	inportlist;	// this may be empty
	rc_t		remove_inport(INPORT *);

	GLOBAL_VALUE	global_value;	// ... if it's global, it isn't in design->netlist
					// (..except from assign statement...???)

	BOOLEAN		locate_all_ports();

	// net resistance and capacitance
	float		metal_capacitance;	// the net itself, exclusive of loads
						// redundant if segements are used, which sometimes they aren't			
	rc_t		compute_net_rc();
	rc_t		compute_net_characteristics();

	// net delay by timing constant method
	rc_t		estimate_tc_delay();
	void		compute_tc_bounds();	// ... limits to estimate
	float		tau_P;	// lower bound, for all inports
				// (upper bound is INPORT::tau_Re)
	void		compute_tau_Re();

	rc_t		steiner_route();
	ListOfPORT *	sort_ports();

	rc_t		insert_buffers_local(DOWNSTREAM *);
	rc_t		insert_buffers_optimize(DOWNSTREAM *);
	rc_t		split_net_for_parallel_drivers();
			// helper
	void		insert_buffer(INSTANCE **return_buffer = NULL, NET **return_buffer_in_net = NULL);
	rc_t		remove_buffer();
};

class ListOfNET {
    public:
		ListOfNET(NET *, ListOfNET *);
		~ListOfNET();
		
	ListOfNET *	append(NET *);

	NET *		net;
	ListOfNET *	next;
};


// SEGMENT represents a chunk of wire running from PORT to PORT.
// segments are formed into a tree rooted at NET::source
// segment contains a list of ROUTEs, representing a global route of this wire

class SEGMENT {
    public:
		SEGMENT(PORT *right_end);
		~SEGMENT();

	PORT *		right_end;
	ListOfSEGMENT *	segmentlist;

	float		resistance;	// the wire resistance
	float		capacitance;	// the capacitor at the right end;
			    // XXX not gate cap! just node cap!
			    // 1/2 the wire cap plus the gate cap, if any

	float		downstream_capacitance;	// all the capacitance that gets
		   	    // charged throught the resistance (includes right_end gate cap)

	// "left_end" and "right_end" are really the end towards
	// the driver & towards the load, respectively... this is
	// cool because the unique source for each net means the tree
	// of segments has a well-defined root and topology.
	//
	// XXX ... maybe left_end -> driver_end & right_end -> load_end...
	// on a schematic logic flows from left to right, but there
	// is confusion possible since sometimes we care about which 
	// end is physically "leftmost" (smaller x-value) on the layout...

	// go to net->source and search segment tree to find
	// the guy who hold a pointer to target segment; that 
	// guy's right_end is the desired left_end.
	// Maybe I am being excessively parsimonious with 
	// backpointers.... but that's the way I am.
	PORT *		get_left_end();
	PORT *		get_left_end_helper(SEGMENT *target);	

	SBOX *		collect_connected_segments(SBOX *);

	// helper functions for NET::compute_characteristics
	void		compute_rc(SEGMENT *upstream_segment);

	// helper function for DSPFFILE::write_net
	void		sum_net_r(float *resistance);

	void		estimate_tc_delay(float delay_to_left_end);
		// helper for NET::compute_tc_bounds()
	float		compute_tc_bounds(float, float, float, float);

	// debug/curiosity
	int		count_downstream_segments();
};

class ListOfSEGMENT {
    public:
		ListOfSEGMENT(SEGMENT *arg_segment, ListOfSEGMENT *arg_next);
		~ListOfSEGMENT();

	SEGMENT *	segment;	
	ListOfSEGMENT *	next;
};


/////////////////////////////////////////////////////////////////
// .... globals .....

// Basicly, these are fake nets... they don't want to get 
// routed, etc, in the usual way, but we need something to 
// attach to INPORTs

class GLOBAL {
    public:
			GLOBAL(char *);
			~GLOBAL();

	char *		name;
	NET *		net;	// not in design::netlist, 'cause it isn't REALLY real...
	ListOfINPORT *	inportlist;
};

class ListOfGLOBAL {
    public:
		ListOfGLOBAL(GLOBAL *, ListOfGLOBAL *);
		~ListOfGLOBAL();

	GLOBAL *		global;
	ListOfGLOBAL *	next;
};


///////////////////////////////////////////////
// helper class, mostly for print_cell_area()

class CELL_AREA_INFO {
    public:
	CELL_AREA_INFO() 
	: total_area(0.0), resizeable_area(0.0)
	{
	}
		
	rc_t figure();

	float total_area;
	float resizeable_area;
};


#endif
