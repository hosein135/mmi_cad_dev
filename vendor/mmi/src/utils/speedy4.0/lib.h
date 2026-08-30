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

#ifndef lib_h
#define lib_h

class CELL;
class ListOfCELL;
class INPIN;
class ListOfINPIN;
class OUTPIN;
class ListOfOUTPIN;
class INPINTIMING;
class OUTPINTIMING;
class ListOfOUTPINTIMING;
class FUNCTIONGROUP;
class ListOfFUNCTIONGROUP;
class INSTANCE;
class PATH;
class ListOfINPINTIMING;
class ListOfOUTPINTIMING;
class LUTABLE;

#define MAX_LU_INDEX	20

class CELL_LIBRARY {
    public:
		CELL_LIBRARY();
		~CELL_LIBRARY();

	ListOfCELL *	celllist;
	ListOfFUNCTIONGROUP *functiongrouplist;

	// utilties
	rc_t		sort_by_function(CELL *);
	CELL *		get_cell(char *name);
	rc_t		remove_cell(CELL *);	

	CELL *	design2cell();

	// compute the thresholds for use in "resize thresholds"
	// ...					    
	// according to the "limit method", we want to pick a size secure in 
	// the guess that no output slope will exceed the arg_slope.
	// according to the "get close method", we want to pick a size such
	// that the acutal slope will be as close as possible to the arg_slope,
	// plus or minus.
	rc_t		compute_thresholds(float target_slope, BOOLEAN use_limit_method);

	rc_t		sort_cells_by_area();
	ListOfCELL *	by_area_celllist;	// same content as celllist, ordered by area (largest first)

	rc_t		sort_cells_for_downsize_list();
	ListOfCELL *	downsize_order_celllist;	// cells to downsize, in order of area saved if it works

	// in support of ::add_extconn_for_Lee(...)
	// hackware by Lee's specification to support his idea of icon_creator
	// .... but there's some interesting ideas here. 
	// ... see speedy/doc/net_and_extconn_characterization.doc
	ListOfOUTPINTIMING *	copy_outpintiming_add_delay(ListOfOUTPINTIMING *, float delay);
	INPINTIMING *		copy_inpintiming_add_delay(INPINTIMING *, float delay);
	// ... helper
	rc_t			add_offset_to_lutable_values(LUTABLE *, float offset);

	// ... one-off for DaveW; a start on examining cell libraries
	// the germ of a whole new feature....
	rc_t		characterize(float load, float slope, FILE *f);
};

enum CELLTYPE {
	CELLTYPE_UNKNOWN_CELL,
	CELLTYPE_BASIC,
	CELLTYPE_EXTCONN,
	CELLTYPE_DUMMYSOURCE
};

class CELL {
    public:
		CELL(char *name, CELLTYPE);	
		~CELL();

	CELLTYPE	type;

	INPIN *		add_inpin(char *name);
	OUTPIN *	add_outpin(char *name);

	INPIN *		get_inpin(char *name);
	INPIN *		get_fast_inpin();	// if some inpin is tagged as FAST, return it
	OUTPIN *	get_outpin(char *name);

	rc_t		characterize(float load, float slope, FILE *f);

	CELL *		get_next_size_smaller();
	CELL *		get_next_size_larger();
	CELL *		get_smallest_size();
	
	char *		name;
	char		size;		// 'A' -> 'E', increasing bigness
					// or ' ' if concept doesn't apply (eg, rams)
	float		max_capacitance;
	BOOLEAN		is_flipflop;

	float		area;

	FUNCTIONGROUP *	functiongroup;

	ListOfINPIN *	inpinlist;
	ListOfOUTPIN *	outpinlist;

	rc_t		add_timing_arc(INPIN *, PATH *);
	rc_t		add_timing_setup(INPINTIMING *, PATH *);
};

class ListOfCELL {
    public:
		ListOfCELL(CELL *, ListOfCELL *);
		~ListOfCELL();

	CELL *		cell;
	ListOfCELL *	next;
};

class ListOfListOfCELL {
    public:
		ListOfListOfCELL(ListOfCELL *, ListOfListOfCELL *);
		~ListOfListOfCELL();

	ListOfCELL *		celllist;
	ListOfListOfCELL *	next;
};



enum DIRECTION {DIRECTION_IN, DIRECTION_OUT, DIRECTION_INOUT};
enum RELATIVE_SPEED {NOTORDERED, FAST, SLOW, XSLOW, XXSLOW, XXXSLOW, XXXXSLOW};

class INPIN {
    public:
		INPIN(char *name);
		INPIN(INPIN &);

		// #ifdef WRLIB_FEATURE
		// 		INPIN(EXTCONN *);
		// #endif

		~INPIN();

	char *		name;
	DIRECTION	direction;

	BOOLEAN		is_array;
	int		low_index;
	int		high_index;

	RELATIVE_SPEED	relative_speed;

	float		capacitance;
	BOOLEAN		is_clock_pin;

 	ListOfOUTPINTIMING *	outpintiminglist;

	// XXX ... no reason this should never be a list...
	INPINTIMING *	inpintiming;
};

class ListOfINPIN {
    public:
		ListOfINPIN(INPIN *, ListOfINPIN *);
		~ListOfINPIN();

	INPIN *		inpin;
	ListOfINPIN *	next;
};

enum OUTPINTIMING_SENSE {UNKNOWN_SENSE, NEGATIVE_SENSE, POSITIVE_SENSE, RISING_EDGE, FALLING_EDGE};

class OUTPIN {
    public:
		OUTPIN(char *name);
		OUTPIN(OUTPIN &);

		~OUTPIN();

	// ... parsing an input
	rc_t		add_outpintiming(OUTPINTIMING *);

	// what is the largest permitted load capacitance that will
	// always generate a slope better than given?
	rc_t		compute_maxc(float target_slope, float *return_cap);

	// what is the worst output slope (amongst the various outpintimings)
	// for the given load & input slope?
	float		lookup_worst_slope(float load, float slope);

	char *		name;
	DIRECTION	direction;

	BOOLEAN		is_array;
	int		low_index;
	int		high_index;

	float		resistance;	// internal resistance,
					// derived from table

 	ListOfOUTPINTIMING *	outpintiminglist;
};

class ListOfOUTPIN {
    public:
		ListOfOUTPIN(OUTPIN *, ListOfOUTPIN *);
		~ListOfOUTPIN();

	OUTPIN *	outpin;
	ListOfOUTPIN *	next;
};


// XXX .... really ought to dynamicly allocate arrays of float
// for index and table values... but it's SUCH a pain....
// as it is, we have limited table size and waste some space.
class LUTABLE {
    public:
		LUTABLE(char *template_name);
		LUTABLE(LUTABLE &);
		LUTABLE(int index_1_size, int index_2_size);
		LUTABLE(LUTABLE *, LUTABLE *);
		~LUTABLE();	

			// ... ix1 is load-c, ix2 is slope-t, often...
	float		lookup(float index_1_val, float index_2_val);
	rc_t		compute_maxc(float target_slope, float *return_cap);
	float		compute_implied_resistance(char);

	// private helper
	float		get_value(int ix1, int ix2);
	void		put_value(int ix1, int ix2, float value);

	char *		name;	// name is actually reference to template
				// this isn't a nice way to handle it, but heck....
	char *		variable_1;
	char *		variable_2;
	int		index_1_size;
	int		index_2_size;
	int		values_size;

	//	float *		index_1;
	//	float *		index_2;
	//	float *		values;

	float 		index_1[MAX_LU_INDEX];
	float 		index_2[MAX_LU_INDEX];
	float 		values[MAX_LU_INDEX * MAX_LU_INDEX];
};

class ListOfLUTABLE {
    public:
		ListOfLUTABLE(LUTABLE *, ListOfLUTABLE *);
		~ListOfLUTABLE();

	LUTABLE *	lutable;
	ListOfLUTABLE *	next;
};



class INPINTIMING {
    public:
			INPINTIMING();
			~INPINTIMING();

	// rise/fall is the slope time
	// transition is the gate delay

	INPIN *		related_inpin;	
	char *		related_pinname;	// need to save name temporarily, during lib file parsing
	rc_t		find_related_inpin(CELL *);

	LUTABLE *	setup_rise;
	LUTABLE *	hold_rise;
	LUTABLE *	setup_fall;
	LUTABLE *	hold_fall;

};

class ListOfINPINTIMING {
    public:
		ListOfINPINTIMING(INPINTIMING *, ListOfINPINTIMING *);
		~ListOfINPINTIMING();

	INPINTIMING *		inpintiming;
	ListOfINPINTIMING *	next;
};

class OUTPINTIMING {
    public:
			OUTPINTIMING();
			OUTPINTIMING(OUTPINTIMING *index_1_prototype, OUTPINTIMING *index_2_prototype, BOOLEAN is_rising_path);
			~OUTPINTIMING();

	float		get_rising_delay(float load, float input_slope);
	float		get_falling_delay(float load, float input_slope);
	float		get_rising_slope(float load, float input_slope);
	float		get_falling_slope(float load, float input_slope);

	rc_t		find_related_inpin(CELL *);
	float		compute_implied_resistance();
	
	OUTPIN *	outpin;
	INPIN *		related_inpin;	
	char *		related_pinname;	// need to save name temporarily, during lib file parsing

	OUTPINTIMING_SENSE	sense;

	LUTABLE *	cell_rise;
	LUTABLE *	rise_transition;
	LUTABLE *	cell_fall;
	LUTABLE *	fall_transition;
};

class ListOfOUTPINTIMING {
    public:
		ListOfOUTPINTIMING(OUTPINTIMING *, ListOfOUTPINTIMING *);
		~ListOfOUTPINTIMING();

	OUTPINTIMING *		outpintiming;
	ListOfOUTPINTIMING *	next;
};

enum FG_FUNCTION {
	FG_UNKNOWN,
	FG_INV,
	FG_AND2,
	FG_NAND2
};


class FUNCTIONGROUP {
    public:
		FUNCTIONGROUP(char *, CELL *);
		~FUNCTIONGROUP();

	char *		functionstr;
	FG_FUNCTION	function;
	ListOfCELL *	celllist;

	static FG_FUNCTION	lookup(char *cellname);
	void		get_functionstr(char *, int bufsize);	
};

class ListOfFUNCTIONGROUP {
    public:
		ListOfFUNCTIONGROUP(FUNCTIONGROUP *, ListOfFUNCTIONGROUP *);
		~ListOfFUNCTIONGROUP();

	FUNCTIONGROUP *		functiongroup;
	ListOfFUNCTIONGROUP *	next;
};

#endif

