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
#include <sys/time.h>

///////////////////////////
// user definable-variables


char *	SPEEDY_MODE = NULL;

char *	top_level_cellname = NULL;

float	assumed_outport_load = .020;

float	clock_period = 0.0;

	// some physical information
	// wire resistance & capacitance per grid unit in whichever direction
float	rconst;		// in ohms per grid unit
float	cconst;		// in picofarads per grid unit 
float	cap_fudge = 0.000;	// femtofarads....  an arbitrary constant that makes
				// sure that very short nets present *some* load.  
				// More or less.  Ask Lee.

char *	default_speedy_path = "/mmi-cad/src/speedy";
char *	speedy_command_path = ".";
char *	speedy_path = NULL;

BOOLEAN	check_inputs_on_clock_nets = false;
BOOLEAN	use_sue_clones = true;

char *	placement_distance_unit	= "micron";
float	distance_unit_multiplier = 1.0;	// computed from placement_distance_unit

BOOLEAN speedy_verbose = false;

BOOLEAN	read_netlist_from_dspffile = false;

// how to figure net r's and c's?  mutually exclusive methods.
// WIRE LOAD MODEL
// assume total net length = number of loads * minimum distance between cells
// taking min-distance to be square root of area of minimum size inverter
// total net metal capacitance = net length * cconst
// ... see NET::compute_net_characteristics()
NET_MODEL	net_model = IGNORE_NETS;
float	wire_cap_per_load_for_wire_load_model;

float	clock_slope = .150;	// ns	... clock edges ... 150 is right for Music
float	target_slope = .082;	// ... reasonable value for mmi15 ... also default input slope
BOOLEAN use_rc_net_delay = false;
float	fast_net_delay = .002;	// pSec... if upper bound of estimated delay is 
					// less than this, don't worry further	
float	maximum_desireable_slope = 0.500;
int	pearl_maxpossibilities;

// mostly for resize, but we use inverter_cell to calculate wire_load model
// ...
// cell name of buffer cell to be used for buffer insertion
// (if accepted, it gets resized to the appropriate guy in 
// the same functiongroup) .... inverter cells are also special
// because we don't want to add buffers after them
char *	buffer_cellname = "MMI_BUFE";
char *	inverter_cellname = "MMI_INVE";

// .... hidden; updated with buffer/inverter_cellname (and during complete_initialization)
CELL *	buffer_cell = NULL;
CELL *	inverter_cell = NULL;

// used in resize thresholds algorithm... select gate size based 
// on load such that output slope is always less than this 
// (using lookup table comupted by LIB::compute_thresholds)
// (see note on ..use_limit_method in lib.h)
BOOLEAN compute_thresholds_use_limit_method = false;

// used in try_to_upsize/downsize
// require this much improvement to accept the change
// where improvement = delay_before - delay_after
// (... note for downsize default threshold is negative, 
// that is, accept slightly worse performance (the assumption
// being that area improves)
float	upsize_threshold = 0.020; 
float	downsize_threshold = -0.010; 

// used in "downsize for area" algorithm (DESIGN::downsize_by_slack)
// slack for a given instance is the difference between 
// the delay of the longest path that passes through that instance
// and the global long delay.  
// ... if the local path delay gets longer, the slack decreases,
// so the sign might appear to be backwards from upsize_threshold &c.
float	minimum_desireable_slack = 0.100;

BOOLEAN allow_upsize_for_optimize = false;
BOOLEAN	allow_downsize_on_critical_path_for_optimize = false;
BOOLEAN allow_swap_inports_for_optimize = true;

BOOLEAN	downsize_unloaded_instances = false;
// pertains to the LU_TABLEs in cell_library;
// the factor by which we will allow a value to be 
// under or over the range covered by the table....
// we are OK interpolating for *some* distance, but
// not indefinately....
float	permissable_table_underrun = 0.7;
float	permissable_table_overrun = 1.3;

// buffer insertion threshold
// ... original idea:
// Assume transition time is all delay; then stage delay is
// equal to gate delay plus output transition.
// So take a max buffer; assume target-slope input and 
// a load that gives target-slope at output; compute
// MagicNumber = stage delay(assumed_load, target_slope) + target_slope.
// Then if the actual slope > MagicNumber, insert a buffer.
//
// but on inspection we found nodes that were way slow because they 
// were slow on the input.  We just want nodes that are *too heavily loaded*,
// that is they would be slow even with a nominal (target_slope) input.
// That gives us a way to calculate max_capacitance for "largest" gates;
// NOW we want to add a buffer only if the node is slow (in the sense above)
// AND the driver is above his max_capacitance.
//
// .... computed by CELLLIBRARY::compute_thresholds ...
float	buffer_insertion_threshold_slope;

BOOLEAN split_nets_during_add_buffers = false;

// just talk about places to insert buffers, don't actually do it.
BOOLEAN do_buffer_insertion = true;

BOOLEAN add_buffers_during_path_optimization = true;

Tcl_Obj *	current_nldesign_tcl_obj = NULL;


///////////////////////////
// internal working state

DESIGN	*	design = NULL;
DESIGN	*	temp_design = NULL;

CELL_LIBRARY *	cell_library = NULL;

BOOLEAN		initialization_is_complete = false;

		// should we check for unlocated pins during
		// complete-initialization?
BOOLEAN		location_information_is_loaded = false;

		// for generating unique names, for anybody who wantsem.
int		next_sequential_number = 1;

///////////////////////////
// more stuff

char *	DEFAULT_COMMAND_FILE_NAME = "./speedy.cmd";
int	MAX_INLINE_SIZE = 0x1000;
char *	cur_cmdfilename = "";
int	cur_cmdfileline = 0;

BOOLEAN	STANDALONE_MODE = false;	// standalone or sue

char	tstr[TSTRSIZE];
char	tstr2[TSTRSIZE];

int	top_bbox_minx;
int	top_bbox_maxx;
int	top_bbox_miny;
int	top_bbox_maxy;
int	top_bbox_area;

///////////////////////////
// Debuggery

NET *fave_net = (NET *)-1;
INSTANCE *fave_instance = (INSTANCE *)-1;
INPORT *fave_inport = (INPORT *)-1;
CLONE *fave_clone = (CLONE *)-1;

BOOLEAN insert_names_in_nets_and_instances = true;

///////////////////////////
// forward declarations

rc_t	read_command_file(char *filename);
rc_t	do_something(BOOLEAN executing_from_command_file, 
	    char *cmd, char *arg1, char *arg2, char *arg3, char *arg4);
rc_t	print_cell_area();
rc_t	print_net(char *, char *);
rc_t	print_instance(char *, char *);
rc_t	print_extconn(char *, char *);
rc_t	print_netlist(char *);
rc_t	print_instancelist(char *);
rc_t	print_extconnlist(char *);
rc_t	print_clonelist(char *);
rc_t	print_cells_by_function();
rc_t	print_cells_by_area();
rc_t	print_buffer_trees();
rc_t	compute_wire_cap_per_load_for_wire_load_model();

// in libfile_write.cc
rc_t	add_extconn_for_limited_icon_creator(char *name, char *io_type, char *proto_pinname, char *delay_str);


////////////////////////////////////////////////////////////
// feature support

#include "timing_commands.cc"
#include "resize_commands.cc"
#include "sue_commands.cc"
#include "nl_commands.cc"

////////////////////////////////////////////////////////

rc_t
new_design(char *name) 
{
printf("new_design....name %s\n", name);
	if (::design != NULL) {
		delete ::design;
		::design = NULL;
	}


	::design = new DESIGN();
	::top_level_cellname = strdup(name);
printf("new_design....top name %s\n", top_level_cellname);

	return RC_NOMINAL;
}



////////////////////////////////////////////////////

void
exxit(int n, char *str)
{
	//
	printf("exxit %d \"%s\"\n", n, str);

#ifdef CHECKSTOP_ON_ERROR
	// force a checkstop
	int *foo = NULL;
	*foo = 0x86;

	exit(-1);
#endif
	
}

void
exxit()
{
	printf("exxit() is forcing checkstop\n");

#ifdef CHECKSTOP_ON_ERROR
	// force a checkstop
	int *foo = NULL;
	*foo = 0x86;

	exit(-1);
#endif
	
}

rc_t
time()
{
	struct timeval the_time;
	gettimeofday(&the_time, NULL);
	char *timestr = ctime(&the_time.tv_sec);
	printf("%s", timestr);
	return RC_NOMINAL;
}



///////////////////////////////////////////////////

rc_t
set(char *var_name, char *arg2, char *arg3)
{
	// templates
	//	extern goes in util.h
	//	definition goes at the top of commands.cc
	//	printf goes in help()
	//	first if goes here in set
	//	2nd if goes in print_stuff
	//
	// ... for float variable ...
	// extern float		x;
	// float	x = 0.0;
	// printf("	x\n");
	// if (strcmp(var_name, "x") == 0) {
	// 	float arg;
	// 	int rv = sscanf(arg2, "%f", &arg);
	// 	if (rv != 1) {
	// 		printf("file %s line %d: can't convert to float for x: \"%s\"\n", 
	// 		    cur_cmdfilename, cur_cmdfileline, arg2);
	// 		return RC_FAILED;
	// 	}
	// 	x = arg;
	// 	return RC_NOMINAL;
	// }
	// 
	// if (strcmp(stuff_name, "x") == 0) {
	// 	printf("x = %f\n", x);
	// 	return RC_NOMINAL;
	// }
	// 
	// ... for BOOLEAN variable ...
	// extern BOOLEAN	q;
	// BOOLEAN	q = false;
	// printf("	q\n");	
	// if (strcmp(var_name, "q") == 0) {
	// 	if (strcmp(arg2, "true") == 0) {
	// 	 	q = true;
	// 	}
	// 	else if (strcmp(arg2, "false") == 0) {
	// 		q = false;
	// 	} 
 	// 	else {
	// 		printf("file %s line %d: q: specify \"true\" or \"false\", please\n",
	// 		    cur_cmdfilename, cur_cmdfileline);
	// 		return RC_FAILED;
	// 	}
	// 	return RC_NOMINAL;
	// }
	// 
	// if (strcmp(stuff_name, "q") == 0) {
	// 	if (q == true)	printf("q = true\n");
	// 	else		printf("q = false\n");
	// 	return RC_NOMINAL;
	// }
	// 		
	// ... for string variable ...
	// extern char *	z;
	// char *	z = "";
	// printf("	z\n");
	// if (strcmp(var_name, "z") == 0) {
	// 	if (z != NULL)	delete z;
	// 	z = strdup(arg2);
	// 	return RC_NOMINAL;
	// }
	// 	
	// if (strcmp(stuff_name, "z") == 0) {
	// 	printf("z = \"%s\"\n", z);
	// 	return RC_NOMINAL;
	// }


	if (strcmp(var_name, "clock_period") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for clock_period: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		clock_period = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "SPEEDY_MODE") == 0) {
		if (SPEEDY_MODE != NULL)	delete SPEEDY_MODE;
		SPEEDY_MODE = strdup(arg2);
		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "top_level_cellname") == 0) {
		if (top_level_cellname != NULL)		delete top_level_cellname;
		top_level_cellname = strdup(arg2);
		if (design == NULL) 		design = new DESIGN();
		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "rconst") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for rconst: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		rconst = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "cconst") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for cconst: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		cconst = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "cap_fudge") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for cap_fudge: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		cap_fudge = arg;
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "placement_distance_unit") == 0) {
		if (::location_information_is_loaded == true) {
			printf("WARNING: location information is loaded already; this change has no effect unitl design is reloaded\n");
		}
		if (placement_distance_unit != NULL)	delete placement_distance_unit;

		if (strcmp(arg2, "micron") == 0) {
			distance_unit_multiplier = 1.0;
		}
		else if (strcmp(arg2, "millimicron") == 0) {
			distance_unit_multiplier = 0.001;
		}
		else {
			printf("don't recognize unit: microns or millimicrons, plz\n");
			return RC_FAILED;
		}

		placement_distance_unit = strdup(arg2);
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "assumed_outport_load") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for assumed_output_load: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		assumed_outport_load = arg;
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "net_model") == 0) {
		if	(strcmp(arg2, "EXTRACTED_NETS") == 0) {
			::net_model = EXTRACTED_NETS;
		}
		else if (strcmp(arg2, "STEINER_RC_NETS") == 0) {
			::net_model = STEINER_RC_NETS;
		}
		else if (strcmp(arg2, "STEINER_CAP_NETS") == 0) {
			::net_model = STEINER_CAP_NETS;
		}
		else if (strcmp(arg2, "IGNORE_NETS") == 0) {
			::net_model = IGNORE_NETS;
		}
		else if (strcmp(arg2, "WIRE_LOAD_CAP_NETS") == 0) {
			::net_model = WIRE_LOAD_CAP_NETS;
		}
		else if (strcmp(arg2, "EXPLICIT_CAP_NETS") == 0) {
			::net_model = EXPLICIT_CAP_NETS;
		}
		else {
			printf("file %s line %d: unknown net option \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}

		return RC_NOMINAL;
	}


	if (strcmp(var_name, "wire_cap_per_load_for_wire_load_model") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for wire_cap_per_load_for_wire_load_model: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		printf("...normally this value is computed...but Yo de Man\n");
		wire_cap_per_load_for_wire_load_model = arg;
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "default_speedy_path") == 0) {
		if (default_speedy_path != NULL)		free(default_speedy_path);
		default_speedy_path = strdup(arg2);
		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "speedy_path") == 0) {
		if (speedy_path != NULL)			free(speedy_path);
		speedy_path = strdup(arg2);
		
		if (speedy_command_path != NULL)		free(speedy_command_path);	
		sprintf(tstr, "%s/../cmd", arg2);
		speedy_command_path = strdup(tstr);

		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "check_inputs_on_clock_nets") == 0) {
		if (strcmp(arg2, "true") == 0) {
			check_inputs_on_clock_nets = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			check_inputs_on_clock_nets = false;
		}
		else {
			printf("file %s line %d: check_inputs_on_clock_nets: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		
		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "allow_upsize_for_optimize") == 0) {
		if (strcmp(arg2, "true") == 0) {
			allow_upsize_for_optimize = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			allow_upsize_for_optimize = false;
		}
		else {
			printf("file %s line %d: allow_upsize_for_optimize: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "allow_downsize_on_critical_path_for_optimize") == 0) {
		if (strcmp(arg2, "true") == 0) {
		 	allow_downsize_on_critical_path_for_optimize = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			allow_downsize_on_critical_path_for_optimize = false;
		} 
 		else {
			printf("file %s line %d: allow_downsize_on_critical_path_for_optimize: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "allow_swap_inports_for_optimize") == 0) {
		if (strcmp(arg2, "true") == 0) {
		 	allow_swap_inports_for_optimize = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			allow_swap_inports_for_optimize = false;
		} 
 		else {
			printf("file %s line %d: allow_swap_inports_for_optimize: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "downsize_unloaded_instances") == 0) {
		if (strcmp(arg2, "true") == 0) {
			downsize_unloaded_instances = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			downsize_unloaded_instances = false;
		}
		else {
			printf("file %s line %d: downsize_unloaded_instances: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "target_slope") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for target_slope: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		if (arg > 1.0) {
			printf("WARNING: target slope set to %f nanoseconds; that LOOKS like a large value...\n", arg);
		}
		target_slope = arg;

		if (cell_library != NULL) {
			printf("recalculating cell threshold load...\n");
			cell_library->compute_thresholds(target_slope, compute_thresholds_use_limit_method);
		}
		
		return RC_NOMINAL;
	}
	
	
	if (strcmp(var_name, "compute_thresholds_use_limit_method") == 0	||
	    strcmp(var_name, "limit_method") == 0				) {

		if (strcmp(arg2, "true") == 0) {
		 	compute_thresholds_use_limit_method = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			compute_thresholds_use_limit_method = false;
		} 
 		else {
			printf("file %s line %d: limit_method: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
			
		printf("limit_method set to %s....recomputing thresholds from lib file...\n", arg2);
		cell_library->compute_thresholds(target_slope,
		    compute_thresholds_use_limit_method);
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "upsize_threshold") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for upsize_threshold: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		upsize_threshold = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "downsize_threshold") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for down_threshold: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		downsize_threshold = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "minimum_desireable_slack") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for minimum_desireable_slack: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		minimum_desireable_slack = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "buffer_cellname") == 0) {
		if (buffer_cellname != NULL)		delete buffer_cellname;
		buffer_cellname = strdup(arg2);

		// ... if this doesn't work, never mind; 
		// we will try again if we want to use it.
		if (cell_library != NULL) {
			buffer_cell = cell_library->get_cell(buffer_cellname);
		}
		return RC_NOMINAL;
	}		

	if (strcmp(var_name, "inverter_cellname") == 0) {
		if (inverter_cellname != NULL)		delete inverter_cellname;
		inverter_cellname = strdup(arg2);

		// ... if this doesn't work, never mind; 
		// we will try again if we want to use it.
		if (cell_library != NULL) {
			inverter_cell = cell_library->get_cell(inverter_cellname);
		}
		return RC_NOMINAL;
	}		

	if (strcmp(var_name, "permissable_table_underrun") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for permissable_table_underrun: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		permissable_table_underrun = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "permissable_table_overrun") == 0) {
		float arg;
		int rv = sscanf(arg2, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can't convert to float for permissable_table_overrun: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg2);
			return RC_FAILED;
		}
		permissable_table_overrun = arg;
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "max_target_cap") == 0) {

		CELL *cell = ::cell_library->get_cell(arg2);
		if (cell == NULL) {
			printf("cell \"%s\" not found\n", arg2);
			return RC_FAILED;
		}

		float maxc;
	 	int rv = sscanf(arg3, "%f", &maxc);
	 	if (rv != 1) {
	 		printf("can't convert to float for max_target_cap: \"%s\"\n", arg3); 
	 		return RC_FAILED;
	 	}
		
		cell->max_capacitance = maxc;
		return RC_NOMINAL;
	}		

	if (strcmp(var_name, "buffer_insertion_threshold_slope") == 0) {
	 	float arg;
	 	int rv = sscanf(arg2, "%f", &arg);
	 	if (rv != 1) {
	 		printf("file %s line %d: can't convert to float for buffer_insertion_threshold_slope: \"%s\"\n", 
	 		    cur_cmdfilename, cur_cmdfileline, arg2);
	 		return RC_FAILED;
	 	}
	 	buffer_insertion_threshold_slope = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "do_buffer_insertion") == 0) {
		if (strcmp(arg2, "true") == 0) {
		 	do_buffer_insertion = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			do_buffer_insertion = false;
		} 
 		else {
			printf("file %s line %d: do_buffer_insertion: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "split_nets_during_add_buffers") == 0) {
		if (strcmp(arg2, "true") == 0) {
		 	split_nets_during_add_buffers = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			split_nets_during_add_buffers = false;
		} 
 		else {
			printf("file %s line %d: split_nets_during_add_buffers: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "add_buffers_during_path_optimization") == 0) {
		if (strcmp(arg2, "true") == 0) {
		 	add_buffers_during_path_optimization = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			add_buffers_during_path_optimization = false;
		} 
 		else {
			printf("file %s line %d: add_buffers_during_path_optimization: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		return RC_NOMINAL;
	}
	

	if (strcmp(var_name, "use_sue_clones") == 0) {
		if (strcmp(arg2, "true") == 0) {
			use_sue_clones = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			use_sue_clones = false;
		}
		else {
			printf("file %s line %d: use_sue_clones: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		
		return RC_NOMINAL;
	}
		
	if (strcmp(var_name, "speedy_verbose") == 0) {
		if (strcmp(arg2, "true") == 0) {
			speedy_verbose = true;
		}
		else if (strcmp(arg2, "false") == 0) {
			speedy_verbose = false;
		}
		else {
			printf("file %s line %d: speedy_verbose: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}
		
		return RC_NOMINAL;
	}

	rc_t rc = set_timing_stuff(var_name, arg2);
	if (rc != RC_NOTFOUND)	return rc;
	
	printf("file %s line %d: don't recognize variable name \"%s\"\n", 
	    cur_cmdfilename, cur_cmdfileline, var_name);
	return RC_FAILED;
}

rc_t
get(char **return_str, char *name, char *arg3, char *arg4)
{
	// variables

	if (strcmp(name, "clock_period") == 0) {
		printf("clock_period = %f\n", clock_period);
		return RC_NOMINAL;
	}

	if (strcmp(name, "SPEEDY_MODE") == 0) {
		sprintf(tstr, "%s", SPEEDY_MODE);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "top_level_cellname") == 0) {
		if (top_level_cellname == NULL) {
			sprintf(tstr, "top_level_cellname not set\n");
		} else {
			sprintf(tstr, "%s", top_level_cellname);
		}
		*return_str = tstr;
		return RC_NOMINAL;
	}
		
	if (strcmp(name, "rconst") == 0) {
		sprintf(tstr, "%f", rconst);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "cconst") == 0) {
		sprintf(tstr, "%f", cconst);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "net_model") == 0) {
		switch (::net_model) {
		    case EXTRACTED_NETS:
			printf("net_model = EXTRACTED_NETS\n");
			break;
		    case STEINER_RC_NETS:
			printf("net_model = STEINER_RC_NETS\n");
			break;
		    case STEINER_CAP_NETS:
			printf("net_model = STEINER_CAP_NETS\n");
			break;
		    case IGNORE_NETS:
			printf("net_model = IGNORE_NETS\n");
			break;
		    case WIRE_LOAD_CAP_NETS:
			printf("net_model = WIRE_LOAD_CAP_NETS\n");
			break;
		    case EXPLICIT_CAP_NETS:
			printf("net_model = EXPLICIT_CAP_NETS\n");
			break;
		}
		return RC_NOMINAL;
	}

	if (strcmp(name, "wire_cap_per_load_for_wire_load_model") == 0) {
		sprintf(tstr, "%f", wire_cap_per_load_for_wire_load_model);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "cap_fudge") == 0) {
		sprintf(tstr, "%f", cap_fudge);
		*return_str = tstr;
		return RC_NOMINAL;
	}
		
	if (strcmp(name, "placement_distance_unit") == 0) {
		sprintf(tstr, "%s", placement_distance_unit);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "default_speedy_path") == 0) {
		sprintf(tstr, "%s", default_speedy_path);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "speedy_path") == 0) {
		sprintf(tstr, "%s", speedy_path);
		*return_str = tstr;
		return RC_NOMINAL;
	}
		

	if (strcmp(name, "target_slope") == 0) {
		sprintf(tstr, "%f", target_slope);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "compute_thresholds_use_limit_method") == 0	||
	    strcmp(name, "compute_thresholds_use_limit_method") == 0		) {
		if (compute_thresholds_use_limit_method == true)	sprintf(tstr, "true");
		else							sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "upsize_threshold") == 0) {
		sprintf(tstr, "%f", upsize_threshold);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "downsize_threshold") == 0) {
		sprintf(tstr, "%f", downsize_threshold);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "maximum_desireable_slope") == 0) {
		sprintf(tstr, "%f", maximum_desireable_slope);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "minimum_desireable_slack") == 0) {
		sprintf(tstr, "%f", minimum_desireable_slack);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	

	if (strcmp(name, "allow_swap_inports_for_optimize") == 0) {
		if (allow_swap_inports_for_optimize == true)	sprintf(tstr, "true");
		else						sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "allow_upsize_for_optimize") == 0) {
		if (allow_upsize_for_optimize == true)	sprintf(tstr, "true");
		else					sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "allow_downsize_on_critical_path_for_optimize") == 0) {
		if (allow_downsize_on_critical_path_for_optimize == true)	sprintf(tstr, "true");
		else									sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "downsize_unloaded_instances") == 0) {
		if (downsize_unloaded_instances == true)	sprintf(tstr, "true");
		else						sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "buffer_cellname") == 0) {
		sprintf(tstr, "%s", buffer_cellname);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "inverter_cellname") == 0) {
		sprintf(tstr, "%s", inverter_cellname);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "resizes") == 0) {
		return print_resizes();
	}

	if (strcmp(name, "permissable_table_underrun") == 0) {
		sprintf(tstr, "%f", permissable_table_underrun);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "permissable_table_overrun") == 0) {
		sprintf(tstr, "%f", permissable_table_overrun);
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "buffer_insertion_threshold_slope") == 0) {
		sprintf(tstr, "%f", buffer_insertion_threshold_slope);
		*return_str = tstr;
		return RC_NOMINAL;
	}
	
	if (strcmp(name, "do_buffer_insertion") == 0) {
		if (do_buffer_insertion == true)	sprintf(tstr, "true");
		else					sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "split_nets_during_add_buffers") == 0) {
		if (split_nets_during_add_buffers == true)	sprintf(tstr, "true");
		else						sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "add_buffers_during_path_optimization") == 0) {
		if (add_buffers_during_path_optimization == true)	sprintf(tstr, "true");
		else							sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "use_sue_clones") == 0) {
		if (use_rc_net_delay == true)	sprintf(tstr, "true");
		else				sprintf(tstr, "false");
		*return_str = tstr;
		return RC_NOMINAL;
	}

	if (strcmp(name, "speedy_verbose") == 0) {
		if (use_rc_net_delay == true)	sprintf(tstr, "true");
		else				sprintf(tstr, "false");
		*return_str = tstr;
	}

	// other structures 

	if (strcmp(name, "net") == 0) {
		print_net(arg3, arg4);
		return RC_NOMINAL;
	}

	if (strcmp(name, "instance") == 0) {
		print_instance(arg3, arg4);
		return RC_NOMINAL;
	}

	if (strcmp(name, "extconn") == 0) {
		print_extconn(arg3, arg4);
		return RC_NOMINAL;
	}

	if (strcmp(name, "netlist") == 0) {
		print_netlist(arg3);
		return RC_NOMINAL;
	}

	if (strcmp(name, "instancelist") == 0) {
		print_instancelist(arg3);
		return RC_NOMINAL;
	}

	if (strcmp(name, "extconnlist") == 0) {
		print_extconnlist(arg3);
		return RC_NOMINAL;
	}

	if (strcmp(name, "clonelist") == 0) {
		print_clonelist(arg3);
		return RC_NOMINAL;
	}



	// // // // // // 

	if (strcmp(name, "cells") == 0) {
		if (strcmp(arg3, "by_function") == 0) {
			return print_cells_by_function();
		}
		if (strcmp(arg3, "by_area") == 0) {
			return print_cells_by_area();
		}
		printf("print cells ... by_function or by_area, please\n");
		*return_str = tstr;
		return RC_FAILED;
	}

	if (strcmp(name, "cell_area") == 0) {
		return print_cell_area();
	}

	if (strcmp(name, "buffer_trees") == 0) {
		return print_buffer_trees();
	}

	rc_t rc = print_timing_stuff(name, arg3, arg4);
	if (rc != RC_NOTFOUND)	return rc;
	
	sprintf(tstr, "file %s line %d: don't recognize what to print \"%s\"\n", 
	    cur_cmdfilename, cur_cmdfileline, name);
	*return_str = tstr;
	return rc;
}

/////////////////////////////////////////////////////////

rc_t
print_stuff(char *name, char *arg3, char *arg4) {

	char *return_str = NULL;
	rc_t rc = get(&return_str, name, arg3, arg4);
	if (rc != RC_NOMINAL)	return rc;

	if (return_str != NULL) {
		printf("%s: \"%s\"\n", name, return_str);
	}
	return RC_NOMINAL;
}

/////////////////////////////////////////////////////////
// print helper functions

rc_t
print_net(char *name, char *design_name)
{
	NET *net;
	if (design_name[0] == '\0')	net = design->get_net(name);
	else				net = temp_design->get_net(name);

	if (net == NULL) {
		printf("net \"%s\" not found\n", name);
		return RC_NOMINAL;
	}

	char *speedy_name = net->get_name();
	if (strcmp(speedy_name, name) != 0) {
		printf("...alias of net \"%s\"\n", speedy_name);
	}

	printf("	source %s:%s	load-c %.3f\n", 
	    net->source->instance->get_name(), net->source->outpin->name, net->source->load_capacitance);

	ListOfINPORT *ipl = net->inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		printf("	load %s:%s	%s	pin-c %.3f\n", 
		    inport->instance->get_name(), inport->inpin->name, inport->instance->cell->name, inport->inpin->capacitance);
	}

	return RC_NOMINAL;
}

rc_t
print_instance(char *name, char *design_name)
{
	INSTANCE *instance;
	if (design_name[0] == '\0')	instance = design->get_instance(name);
	else				instance = temp_design->get_instance(name);

	if (instance == NULL) {
		printf("instance \"%s\" not found\n", name);
		return RC_NOMINAL;
	}

	char *cellname;
	if      (instance->cell == NULL)	cellname = "no cell";
	else if (instance->cell->name == NULL)	cellname = "unnamed cell";
	else					cellname = instance->cell->name;
	printf("instance %s cell %s\n", instance->get_name(), cellname);

	ListOfINPORT *ipl = instance->inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		printf("	inport %s	net %s\n", inport->inpin->name, inport->net->get_name());
	}

	ListOfOUTPORT *opl = instance->outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		printf("	outport %s	net %s\n", outport->outpin->name, outport->net->get_name());
	}

	return RC_NOMINAL;
}

rc_t
print_extconn(char *name, char *design_name)
{
	ListOfEXTCONN *el;
	if (design_name[0] == '\0')	el = design->extconnlist;
	else				el = temp_design->extconnlist;

	EXTCONN *extconn = NULL;
	while (el != NULL) {
		extconn = el->extconn;
		if (strcmp(extconn->name, name) == 0)	break;
		el = el->next;
	}
	if (el == NULL) {
		printf("extconn \"%s\" not found\n", name);
		return RC_NOMINAL;
	}

	if (extconn->outportlist != NULL) {
		NET *net = extconn->outportlist->outport->net;
		printf("extconn %s	net %s	- external input\n", extconn->name, net->get_name());
		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			printf("	load %s:%s\n", inport->instance->get_name(), inport->inpin->name);
		}
	}		
	else if (extconn->inportlist != NULL) {
		NET *net = extconn->inportlist->inport->net;
		printf("extconn %s	net %s	- external output\n", extconn->name, net->get_name());
		printf("	source %s:%s\n", net->source->instance->get_name(), net->source->outpin->name);
		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			if (inport == extconn->inportlist->inport)	continue;			
			printf("	load %s:%s\n", inport->instance->get_name(), inport->inpin->name);
		}
	}
	else printf("extconn %s		has no connections\n", name);
	
	return RC_NOMINAL;
}

rc_t
print_netlist(char *design_name)
{
	ListOfNET *netl;
	if (design_name[0] == '\0')	netl = design->netlist;
	else				netl = temp_design->netlist;

	while (netl != NULL) {
		NET *net = netl->net;
		netl = netl->next;
	
		printf("net %s\n", net->get_name());
	}

	return RC_NOMINAL;
}

rc_t
print_instancelist(char *design_name)
{
	ListOfINSTANCE *instancel;
	if (design_name[0] == '\0')	instancel = design->instancelist;
	else				instancel = temp_design->instancelist;

	while (instancel != NULL) {
		INSTANCE *instance = instancel->instance;
		instancel = instancel->next;
	
		printf("instance %s\n", instance->get_name());
	}

	return RC_NOMINAL;
}

rc_t
print_extconnlist(char *design_name)
{
	ListOfEXTCONN *extconnl;
	if (design_name[0] == '\0')	extconnl = design->extconnlist;
	else				extconnl = temp_design->extconnlist;

	while (extconnl != NULL) {
		EXTCONN *extconn = extconnl->extconn;
		extconnl = extconnl->next;
	
		printf("extconn %s\n", extconn->name);
	}

	return RC_NOMINAL;
}


rc_t
print_clonelist(char *design_name)
{
	ListOfCLONE *clonel;
	if (design_name[0] == '\0')	clonel = design->clonelist;
	else				clonel = temp_design->clonelist;

	while (clonel != NULL) {
		CLONE *clone = clonel->clone;
		clonel = clonel->next;
	
		printf("%s..%s\n", clone->parent_cellname,  clone->name);
		ListOfINSTANCE *il = clone->instancelist;
		while (il != NULL) {
			INSTANCE *instance = il->instance;
			il = il->next;

			printf("	%s\n", instance->get_name());
		}	
	}
	return RC_NOMINAL;
}







/////////////////////////////////////////////////////////
// file readers/writers


rc_t
read_libfile(char *libfilename) 
{

	printf("read lib file %s\n", libfilename);

	LIBFILE *libfile = new LIBFILE(libfilename);
	rc_t rc = libfile->read();
	delete libfile;

	if (rc != RC_NOMINAL) {
		printf("read lib file failed\n"); 
		return RC_FAILED;
	}

	return RC_NOMINAL;
}


rc_t
write_libfile()
{
	if (top_level_cellname == NULL) {
		printf("no design loaded, DPC_it first\n");
		return RC_FAILED;
	}

	CELL *top_level_cell = ::cell_library->design2cell();
	if (top_level_cell == NULL)	return RC_FAILED;
		
	sprintf(tstr, "%s.lib", top_level_cell->name);
	LIBFILE *libfile = new LIBFILE(tstr);
	rc_t rc = libfile->write_cell_to_file(top_level_cell);
	if (rc == RC_NOMINAL) {
		printf("wrote libfile \"%s\"\n", libfile->name);
	}
	return rc;
}

rc_t
write_libfile_for_cell(char *cellname)
{
	CELL *cell = ::cell_library->get_cell(cellname);
	if (cell == NULL) {
		printf("cell \"%s\" not found\n", cellname);
		return RC_FAILED;
	}

	sprintf(tstr, "%s.lib", cellname);
	LIBFILE *libfile = new LIBFILE(tstr);
	return libfile->write_cell_to_file(cell);
}

rc_t
read_dspffile(char *dspffilename) {

	printf("...read dspffile %s\n", dspffilename);

	if (::design == NULL) {
		printf("ERROR: load instances and libs before reading dspf\n");
		return RC_FAILED;
	}

	DSPFFILE *dspffile = new DSPFFILE(dspffilename);
	rc_t rc = dspffile->read();
	if (rc != RC_NOMINAL) {
		printf("ERROR: file %s line %d: read dspf file failed\n", 
		    cur_cmdfilename, cur_cmdfileline);
		delete dspffile;
		return RC_FAILED;
	}

	printf("read_dspffile \"%s\" complete\n", dspffilename);
	delete dspffile;

	location_information_is_loaded = true;
	return RC_NOMINAL;
}


rc_t
read_constraintsfile(char *constraintsfilename) 
{
	printf("...read constraintsfile \"%s\"\n", constraintsfilename);

	CONSTRAINTSFILE *constraintsfile = new CONSTRAINTSFILE(constraintsfilename);
	rc_t rc = constraintsfile->read();

	delete constraintsfile;
	return rc;
}

///////////////////////////////////////////////////////////////

rc_t
count_things() 
{
	unsigned netcount = 0;
	unsigned assigned_netcount = 0;
	unsigned global_netcount = 0;
	unsigned external_input_netcount = 0;
	unsigned regular_netcount = 0;

	unsigned long segmentcount = 0;
	unsigned instancecount = 0;
	unsigned clonecount = 0;
	ListOfNET *nl = design->netlist;
	while (nl != 0) {
		NET *net = nl->net;
		nl = nl->next;

		netcount++;
		if (net->global_value != NOT_GLOBAL) {
			global_netcount++;
			continue;
		}
		regular_netcount++;
						
		if (net->source == NULL) {
			external_input_netcount++;
		}

		if (net->source->segment != NULL) {
			ListOfSEGMENT *sl = net->source->segment->segmentlist;
			while (sl != NULL) {
				SEGMENT *segment = sl->segment;
				sl = sl->next;

				segmentcount += segment->count_downstream_segments();
			}
		}
	}
	ListOfINSTANCE *il = design->instancelist;
	while (il != 0) {
		il = il->next;

		instancecount++;
	}

	printf("counting design...\n");
	printf("	%u nets\n", netcount);
	printf("	... %u assigned\n", assigned_netcount);
	printf("	... %u global\n", global_netcount);
	printf("	... %u regular\n", regular_netcount);
	printf("	... ... %u external input\n", external_input_netcount);

	unsigned int uint_segmentcount = (unsigned int)segmentcount;
	if (uint_segmentcount < UINT_MAX) {
		printf("	%u segments\n", uint_segmentcount);
	} else {
		printf("	%f segments\n", (float)segmentcount);
	}

	printf("	%u instances\n", instancecount);
	printf("	%u clones\n", clonecount);
	return RC_NOMINAL;
}

rc_t
count_cell_types() 
{
	ListOfFUNCTIONGROUP *fgl = cell_library->functiongrouplist;
	while (fgl != NULL) {
		FUNCTIONGROUP *functiongroup = fgl->functiongroup;
		fgl = fgl->next;
	
		ListOfCELL *cl = functiongroup->celllist;
		while (cl != NULL) {
			CELL *cell = cl->cell;
			cl = cl->next;

			int count = 0;
			ListOfINSTANCE *il = design->instancelist;
			while (il != NULL) {
				INSTANCE *instance = il->instance;
				il = il->next;

				if (instance->cell == cell)	count++;
			}

			printf("%d	%s\n", count, cell->name);
		}
	}
	return RC_NOMINAL;
}



rc_t
top_bbox(char *arg1, char *arg2, char *arg3, char *arg4)
{

	top_bbox_minx = atoi(arg1);
	top_bbox_miny = atoi(arg2);
	top_bbox_maxx = atoi(arg3);
	top_bbox_maxy = atoi(arg4);

	if (top_bbox_minx > top_bbox_maxx	||
	    top_bbox_miny > top_bbox_maxy	) {
		printf("...bbox corners are out of order???\n");
		return RC_FAILED;
	}

	top_bbox_area = (top_bbox_maxx - top_bbox_minx) * (top_bbox_maxy - top_bbox_miny);
	// printf("top_cell bbox from (%d, %d) to (%d, %d).... area %d\n",
	//    top_bbox_minx, top_bbox_miny, top_bbox_maxx, top_bbox_maxy, top_bbox_area);

	return RC_NOMINAL;
}		

rc_t
print_cell_area()
{
	// cell sizes in .lib file are in square microns

	CELL_AREA_INFO	info;
	rc_t rc = info.figure();
	if (rc != RC_NOMINAL)	return RC_FAILED;

	if (info.total_area >= FLT_MAX) {
		printf("total cell area: greater than FLT_MAX\n");
	} else {
		printf("total cell area = %.0f (%e)\n",info.total_area, info.total_area);
	}

	printf("resizeable cell area = %.0f (%e)\n", info.resizeable_area, info.resizeable_area);
	printf(".... resizeable => not marked dont_resize and alternatives exist\n");
	// printf(".... %.1f area utilization\n", (((float)info.total_area) / ((float) top_bbox_area)) * 100.0);
	
	return RC_NOMINAL;
}
		
rc_t
print_cells_by_function()
{
	if (cell_library == NULL) {
		printf("cell library not installed\n");
		return RC_FAILED;
	}

	ListOfFUNCTIONGROUP *fgl = cell_library->functiongrouplist;
	while (fgl != NULL) {
		FUNCTIONGROUP *functiongroup = fgl->functiongroup;
		fgl = fgl->next;
	
		functiongroup->get_functionstr(tstr, TSTRSIZE);
		printf("\nfunctiongroup for function \"%s\"\n", tstr); 
		ListOfCELL *cl = functiongroup->celllist;
		while (cl != NULL) {
			CELL *cell = cl->cell;
			cl = cl->next;

			if (cell->max_capacitance == FLT_MAX)	sprintf(tstr, ">>>");
			else					sprintf(tstr, "%.3f", cell->max_capacitance);

			if (cell->outpinlist != NULL) {
				printf("cell \"%s\" size %c \tmax_capacitance %s \tinternal r %.0f\n", cell->name,
				    cell->size, tstr, cell->outpinlist->outpin->resistance);
			} else {
				printf("cell \"%s\" size %c \tmax_capacitance %sf \t<no outpinlist>\n", cell->name,
				    cell->size, tstr);
			}
		
			ListOfOUTPIN *opl = cell->outpinlist;
			while (opl != NULL) {
				OUTPIN *outpin = opl->outpin;
				opl = opl->next;

				printf("	outpin %s\n", outpin->name);
			}
			ListOfINPIN *ipl = cell->inpinlist;
			while (ipl != NULL) {
				INPIN *inpin = ipl->inpin;
				ipl = ipl->next;

				printf("	inpin %s\n", inpin->name);
			}

		}
	}

	return RC_NOMINAL;
}

rc_t
characterize(char *arg1, char *arg2, char *arg3)
{
	// run through the cell_library; for each cell, 
	// for each timing arc,
	// print output delay & slope (rising and falling) 
	// for specified input slope and output load
	// .... by request from DaveW

	if (::cell_library == NULL) {
		printf("cell library not loaded... you can use 'read_libfile <filename.lib>'\n");
		return RC_FAILED;
	};

	float load = atof(arg2);
	float slope = atof(arg1);
	FILE *f;
	if (strcmp(arg3, "") != 0) {
		f = fopen(arg3, "w");
		if (f == NULL) {
			printf("open file \"%s\" failed errno %d\n", arg3, errno);
			return RC_FAILED;
		}
	} else	f = stdout;

	// printf("\ncharacterizing cell library for load %fpf input slope %fns\n", load, slope);
	return ::cell_library->characterize(load, slope, f);	
}

rc_t
clear(char *what)
{
	if (strcmp(what, "all") == 0) {
		if (design != NULL) {
			delete design;
			design = NULL;
		}
		
		if (nl_interface != NULL) {
			delete nl_interface;
			nl_interface = NULL;
		}

	} else if (strcmp(what, "cell_library") == 0) {

		if (cell_library != NULL) {
			delete cell_library;
			cell_library = NULL;
		}

	} else {
		printf("clear what??? \"%s\"\n", what);
		return RC_FAILED;
	}
	return RC_NOMINAL;
}

//////////////////////////////////////////////////////////////////

rc_t
debug_find(char *arg_kind, char *arg_name)
{
	// Sue substitutes "$...$" for "[...]" sometimes....
	char *p = arg_name;
	while (*p != '\0') {
		if (*p == '$') {
			*p++ = '[';
			while (*p != '\0') {
				if (*p == '$') {
					*p++ = ']';
					break;
				} else p++;
			}
			printf("....mismatched dollar signs???\n");
		} else p++;
	}

	if (strcmp(arg_kind, "instance") == 0) {
		INSTANCE *instance = design->get_instance(arg_name);
		if (instance == NULL) {
			printf("instance %s not found\n", arg_name);
			return RC_FAILED;
		}

		printf("INSTANCE %s at 0x%x..... print *(INSTANCE *)0x%x\n", arg_name, (unsigned)instance, (unsigned)instance);
		return RC_NOMINAL;
	}
	
	else if (strcmp(arg_kind, "net") == 0) {
		NET *net = design->get_net(arg_name);
		if (net == NULL) {
			printf("net %s not found\n", arg_name);
			return RC_FAILED;
		}

		printf("NET %s at 0x%x..... print *(NET *)0x%x\n", arg_name, (unsigned)net, (unsigned)net);
		return RC_NOMINAL;
	}
	
	else if (strcmp(arg_kind, "extconn") == 0) {
		ListOfEXTCONN *el = design->extconnlist;
		EXTCONN *fave_extconn = NULL;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (strcmp(extconn->name, arg_name) == 0) {
				printf("EXTCONN %s at 0x%x..... print *(EXTCONN *)0x%x\n", extconn->name, (unsigned)extconn, (unsigned)extconn);
				fave_extconn = extconn;
			}
		}
		if (fave_extconn == NULL) {
			printf("extconn %s not found\n", arg_name);
			return RC_FAILED;
		}
	}

	else if (strcmp(arg_kind, "cell") == 0) {
		if (cell_library == NULL) {
			printf("cell library is empty\n");
			return RC_FAILED;
		}
		ListOfCELL *cl = cell_library->celllist;
		CELL *fave_cell = NULL;
		while (cl != NULL) {
			CELL *cell = cl->cell;
			cl = cl->next;

			if (strcmp(cell->name, arg_name) == 0) {
				printf("CELL %s at 0x%x..... print *(CELL *)0x%x\n", cell->name, (unsigned)cell, (unsigned)cell);
				fave_cell = cell;
			}
		}
		if (fave_cell == NULL) {
			printf("cell %s not found\n", arg_name);
			return RC_FAILED;
		}
	}
	
	else {
		printf("find %s not implemented\n", arg_kind);
		return RC_FAILED;
	}

	return RC_NOMINAL;
}	

rc_t
debug_match(char *arg_kind, char *arg_name)
{
	if (strcmp(arg_kind, "net") == 0) {
		int count = 0;
	
		ListOfNET *nl = design->netlist;
		while (nl != NULL) {
			NET *net = nl->net;
			nl = nl->next;

			// printf("%s\n", net->get_name());

			if (strstr(net->get_name(), arg_name) != 0) {
				printf("NET %s at 0x%x..... print *(NET *)0x%x\n", net->get_name(), (unsigned)net, (unsigned)net);
				count++;
			}
		}
		if (count == 0) {
			printf("no matches found\n");
			return RC_NOMINAL;
		}
	}
	
	else {
		printf("find %s not implemented\n", arg_kind);
		return RC_FAILED;
	}

	return RC_NOMINAL;
}	

void
debug_show_net_segments(SEGMENT *segment, int indent)
{
	// helper function for "show net_segments"

	// see SEGMENT::elmore_delay
	// picoseconds = ohms * picofarads

	// .... 1st line
	for (int i = 0; i < indent; i++)	printf(". ");

	printf("%.3fps    x %d y %d    r %.0f c %.3f	", 
	    segment->right_end->net_delay, segment->right_end->x, segment->right_end->y,
	    segment->resistance, segment->capacitance);

	if (segment->right_end->type == INPORT_TYPE) {
		INPORT *inport = (INPORT *)segment->right_end;
		if (inport->instance != NULL) {
			printf("%s:%s (pin-c %f)\n", inport->instance->get_name(), inport->inpin->name, 
			   inport->inpin->capacitance);
		} else {
			printf("external:%s %f\n", inport->inpin->name, inport->net_delay);
		}
	} else {
		printf("\n");
	}

	ListOfSEGMENT *sl = segment->segmentlist;
	while (sl != NULL) {
		SEGMENT *downstream_segment = sl->segment;
		sl = sl->next;

		debug_show_net_segments(downstream_segment, indent + 1);
	}
	return;
}

// void
// debug_show_net_assigns(NET *net, int indent)
// {
// 	// helper function for "show net_assigns"
// 
// 	for (int i = 0; i < indent; i++)	printf(". ");
// 	printf("%s\n", net->get_name());
// 
// 	ListOfNET *nl = design->netlist;
// 	while (nl != NULL) {
// 		NET *nlnet = nl->net;
// 		nl = nl->next;
// 		
// 		if (nlnet->assigned_to == net) {
// 			debug_show_net_assigns(nlnet, indent + 1);
// 		}
// 	}
// 	return;
// }

float driver_resistance = 0.0;


rc_t
debug_show(char *arg_kind, char *arg_name)
{
	// Sue substitutes "$...$" for "[...]" sometimes....
	char *p = arg_name;
	while (*p != '\0') {
		if (*p == '$') {
			*p++ = '[';
			while (*p != '\0') {
				if (*p == '$') {
					*p++ = ']';
					break;
				} else p++;
			}
			printf("....mismatched dollar signs???\n");
		} else p++;
	}

	if (strcmp(arg_kind, "net_segments") == 0) {
		NET *net = design->get_net(arg_name);
		if (net == NULL) {
			printf("net \"%s\" not found\n", arg_name);
			return RC_FAILED;
		}

		OUTPORT *source = net->source;
		if (source->segment == NULL) {
			printf("net '%s' is not segmentized\n", net->get_name());
			return RC_NOMINAL;
		}
		printf("%.3f	%d %d	... source-r %f source-c %f\n", source->net_delay, source->x, source->y, 
		    source->outpin->resistance, source->segment->capacitance);
		printf("the first segment is the driver internal resisitance\n");
		debug_show_net_segments(net->source->segment, 1);
	}

	else if (strcmp(arg_kind, "cell") == 0) {
		CELL *cell = cell_library->get_cell(arg_name);
		if (cell == NULL) { 
			printf("cell \"%s\" not found\n", arg_name);
			return RC_FAILED;
		}
		printf("CELL %s size %c max_cap %.3f is_ff %d area %.3f\n",
		    cell->name, cell->size, cell->max_capacitance, cell->is_flipflop, cell->area);

		printf("inpins:\n");
		ListOfINPIN *ipl = cell->inpinlist;
		while (ipl != NULL) {
			INPIN *inpin = ipl->inpin;
			ipl = ipl->next;

			printf("    %s array %d low %d high %d cap %.3f is_clock %d\n",
			    inpin->name, inpin->is_array, inpin->low_index, inpin->high_index, inpin->capacitance, inpin->is_clock_pin);
		}

		printf("outpins:\n");
		ListOfOUTPIN *opl = cell->outpinlist;
		while (opl != NULL) {
			OUTPIN *outpin = opl->outpin;
			opl = opl->next;

			printf("    %s array %d low %d high %d res %.3f\n",
			    outpin->name, outpin->is_array, outpin->low_index, outpin->high_index, outpin->resistance);
		}
	}

	else if (strcmp(arg_kind, "instance") == 0) {
		INSTANCE *instance = design->get_instance(arg_name);
		if (instance == NULL) { 
			printf("instance \"%s\" not found\n", arg_name);
			return RC_FAILED;
		}
		// printf("INSTANCE %s cell %s clone %s\n",
		//     instance->get_name(), instance->cell->name, instance->clone->get_name());
		printf("INSTANCE %s cell %s\n",
		    instance->get_name(), instance->cell->name);

		printf("inports:\n");
		ListOfINPORT *ipl = instance->inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			printf("    %s net %s net-d %.3f 0x%x\n",
			    inport->inpin->name, inport->net->get_name(), inport->net_delay, (uint)inport);
		}

		printf("outports:\n");
		ListOfOUTPORT *opl = instance->outportlist;
		while (opl != NULL) {
			OUTPORT *outport = opl->outport;
			opl = opl->next;

			printf("    %s net %s load %.3f 0x%x\n",
			    outport->outpin->name, outport->net->get_name(), outport->load_capacitance, (uint)outport);
		}
	}

	else if (strcmp(arg_kind, "net") == 0) {
		NET *net = design->get_net(arg_name);
		if (net == NULL) { 
			printf("net \"%s\" not found\n", arg_name);
			return RC_FAILED;
		}

		char *global_value_str;
		switch (net->global_value) {
		    case NOT_GLOBAL:		global_value_str = "NOT_GLOBAL";	break;
		    case GLOBAL_ONE:		global_value_str = "GLOBAL_ONE";	break;
		    case GLOBAL_ZERO:		global_value_str = "GLOBAL_ZERO";	break;
		    case GLOBAL_UNKNOWN:	global_value_str = "GLOBAL_UNKNOWN";	break;
		    case GLOBAL_DUMMYSOURCE:	global_value_str = "GLOBAL_DUMMYSOURCE";break;
		    case GLOBAL_CLOCK:		global_value_str = "GLOBAL_CLOCK";	break;
		    default:			global_value_str = "???";		break;			
		}

		if (net->source != NULL) {
			OUTPORT *source = net->source;
			if (source->instance != NULL) {	
				printf("    source: %s:%s\n", source->instance->get_name(), source->outpin->name);
			}
			else {
				printf("    source: %s\n", source->outpin->name);
			}
		}
		else {
			printf("    ... no source ... \n");
		}

		printf("    inports:\n");
		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			if (inport->instance != NULL) {	
				printf("	%s:%s\n", inport->instance->get_name(), inport->inpin->name);
			}
			else {
				printf("	%s\n", inport->inpin->name);
			}
		}
	}

	else if (strcmp(arg_kind, "net_assigns") == 0) {
		printf("show net_assigns function is broken\n");
		return RC_FAILED;

// 		NET *net = design->get_net(arg_name);
// 		if (net == NULL) { 
// 			printf("net \"%s\" not found\n", arg_name);
// 			return RC_FAILED;
// 		}
// 
// 		while (net->assigned_to != NULL)	net = net->assigned_to;
// 		debug_show_net_assigns(net, 1);

 	}
	
// this won't do anything sensible either....
// 	else if (strcmp(arg_kind, "assigned_to") == 0) {
// 		NET *net = design->get_net(arg_name);
// 		if (net == NULL) { 
// 			printf("net \"%s\" not found\n", arg_name);
// 			return RC_FAILED;
// 		}
// 		
// 		ListOfNET *nl = design->netlist;
// 		while (nl != NULL) {
// 			NET *nlnet = nl->net;
// 			nl = nl->next;
// 		
// 			if (nlnet == net) {
// 				printf("	%s\n", nlnet->get_name());
// 			}
// 		}
// 	}

	else if (strcmp(arg_kind, "inpin_capacitance") == 0) {
		ListOfCELL *cl = cell_library->celllist;
		while (cl != NULL) {
			CELL *cell = cl->cell;
			cl = cl->next;

			printf("CELL %s\n", cell->name);
			ListOfINPIN *ipl = cell->inpinlist;
			while (ipl != NULL) {
				INPIN *inpin = ipl->inpin;
				ipl = ipl->next;
	
				printf("	%.3fpf	INPIN %s\n", inpin->capacitance, inpin->name);
			}
		}
	}

	else if (strcmp(arg_kind, "thresholds") == 0) {

		printf("rising and falling slope for all members of a functiongroup\n");
		printf("at the maximum load capacitance for each member of the functiongroup\n");
		printf("(input slope is target_slope)\n\n");

		printf("target_slope %.3fns\n\n", target_slope);

		ListOfFUNCTIONGROUP *fll = cell_library->functiongrouplist;
		while (fll != NULL) {
			FUNCTIONGROUP *functiongroup = fll->functiongroup;
			fll = fll->next; 

			if (functiongroup->celllist == NULL		||
			    functiongroup->celllist->next == NULL	) {
				continue;
			}
			functiongroup->get_functionstr(tstr, TSTRSIZE);
			printf("\nfunction group %s\n", tstr);

			ListOfCELL *cl = functiongroup->celllist;
			while (cl->next != NULL) {
				CELL *cell = cl->cell;
				cl = cl->next;

				float load = cell->max_capacitance;
				printf("\n...load = %.3fpf (max load cap of cell %s)\n", load, cell->name);

				CELL *show_cell = cell;
				for (int i = 0; i < 2; i++, show_cell = cl->cell) {	

					printf("    cell %s\n", show_cell->name);
	
					ListOfOUTPIN *opl = show_cell->outpinlist;
					while (opl != NULL) {
						OUTPIN *outpin = opl->outpin;
						opl = opl->next;
	
						ListOfOUTPINTIMING *optl = outpin->outpintiminglist;
						while (optl != NULL) {
							OUTPINTIMING *outpintiming = optl->outpintiming;
							optl = optl->next;
	
							INPIN *related_inpin = outpintiming->related_inpin;
							float rise_transition = 0.0;
							if (outpintiming->rise_transition != NULL) {
								rise_transition = outpintiming->rise_transition->lookup(load, target_slope);
							}
							float fall_transition = 0.0;
							if (outpintiming->fall_transition != NULL) {
								fall_transition = outpintiming->fall_transition->lookup(load, target_slope);
							}
				
							printf("	^ %f	v %f	arc %s -> %s\n",
							    rise_transition, fall_transition, related_inpin->name, outpin->name);
						}
					}
				}
			}
		}
	}

	else {
		printf("debug_show: \"%s\" not recognized\n", arg_kind);
		return RC_FAILED;
	}
	return RC_NOMINAL;
}	

/////////////////////////////////////////////////////

rc_t
get_speedy_vars_to_tcl() {

	sprintf(tstr, "%f", target_slope);
	
	speedy2tcl_setvar("speedy_vars", tstr);
	return RC_NOMINAL;
}

/////////////////////////////////////////////////////
////////////////////////////////////////////////////////

rc_t
read_command_file(char *cmdfilename)
{
	char *stacked_cmdfilename = cur_cmdfilename;
	int   stacked_cmdfileline = cur_cmdfileline;

	FILE *fd = fopen(cmdfilename, "r");
	if (fd == NULL) {
		// printf("open command file \"%s\" failed, errno %d\n",
		//     cmdfilename, errno);
		return RC_NOFILE;
	}
	cur_cmdfilename = cmdfilename;
	cur_cmdfileline = 0;
	rc_t  rc = RC_NOMINAL;

	printf("read command file %s\n", cmdfilename); 
	
	char line[MAX_INLINE_SIZE];

	while (1) {
		char *s = fgets(line, MAX_INLINE_SIZE, fd);
		if (s == NULL) break;

		char *p = line;
		char *endp = line + strlen(line);
		if (endp > line + MAX_INLINE_SIZE) {
			exxit(20001, "read command line overflowed buffer");
		}
		cur_cmdfileline++;

		// split out args
		char cmd[MAX_INLINE_SIZE];
		char arg1[MAX_INLINE_SIZE];
		char arg2[MAX_INLINE_SIZE];
		char arg3[MAX_INLINE_SIZE];
		char arg4[MAX_INLINE_SIZE];
		arg1[0] = '\0';
		arg2[0] = '\0';
		arg3[0] = '\0';
		arg4[0] = '\0';
		int argcount = sscanf(p, "%s%s%s%s%s", cmd, arg1, arg2, arg3, arg4);

		// skip blank lines and commment lines
		if (argcount < 1	||
		    cmd[0] == '#'	   ) {
			 continue;
		}

		printf(">>> %s %s %s %s %s\n", cmd, arg1, arg2, arg3, arg4);

		rc = do_something(true, cmd, arg1, arg2, arg3, arg4);
		switch (rc) {
		    case RC_NOMINAL:	continue;

		    case RC_NOTFOUND:
			printf("read_command_file \"%s\": command \"%s\" not found\n", cmdfilename, cmd);
			return RC_FAILED;

		    default:
			printf("read_command_file \"%s\": command \"%s\" failed\n", cmdfilename, cmd);
			return RC_FAILED;
		}
	}
	
	cur_cmdfilename = stacked_cmdfilename;
	cur_cmdfileline = stacked_cmdfileline;
	return RC_NOMINAL;
}


////////////////////////////////////////////////////////////

rc_t
help() 
{
	printf("available commands:\n");
	printf("print/set <variable>.... variables are\n");
	printf("	clock_period\n");
	printf("	SPEEDY_MODE\n");
	printf("	top_level_cellname <string>\n");
	printf("	design\n");
	printf("	rconst <float>\n");
	printf("	cconst <float>\n");
	printf("	cap_fudge <float>\n");
	printf("	placement_distance_unit\n");

	printf("	target_slope <float>\n");
	printf("	clock_slope\n");
	printf("	assumed_outport_load\n");
	printf("	net_model\n");
	printf("	pearl_maxpossibilities <int>\n");
	printf("	fast_net_delay <float>\n");
	printf("	speedy_path\n");
	printf("	check_inputs_on_clock_nets\n");
	printf("	speedy_verbose\n");

	printf("print <info>	.... available info\n");
	printf("	cells by_function\n");
	printf("	cells by_area\n");
	printf("	cell_area\n");
	printf("	buffer_trees\n");

	printf("	long_path\n");
	printf("	long_delay\n");
	printf("	saved_path\n");
	printf("	timing_destinations\n");
	printf("\n");
	printf("write_long_paths_file <n_paths> <filename>\n");
	printf("\n");
	printf("read_command_file <command_file_name>\n");
	printf("...or... exec <command_file_name>\n");
	printf("help\n");
	printf("echo\n");
	printf("quit\n");
	printf("q	... synonym\n");
	printf("exit	... synonym\n");
	printf("\n");

	printf("... initialization\n");
	printf("read_libfile <filename>\n");
	printf("read_deffile <filename>\n");
	printf("read_dspffile <filename>\n");
	printf("read_constraintsfile <filename>\n");
	printf("load_design_from_nl\n");
	printf("load_instances_from_nl\n");
	printf("compute_net_characteristics\n");
	printf("\n");

	printf("... static timing\n");
	printf("read_timing_in_file <filename>\n");
	printf("global_timing\n");
	printf("set_input_delay <input name or ALL> <delay>\n");
	printf("set_input_slope <input name or ALL> <slope>\n");
	printf("set_output_load <output name or ALL> <capacitance>\n");
	printf("\n");

	resize_help();

	printf("... fancy stuff\n");
	printf("save_long_path [filename]	...if filename, write a .cmd that will load the path.\n");
	printf("add_to_saved_path <net_name> <'^' or 'v'>\n");
	printf("complete_saved_path <instance_name or extconn_name>\n");
	printf("time_saved_path\n");
	printf("write_libfile\n");
	printf("\n");

	printf("... debuggery\n");
	printf("find <\"net\" or \"instance\"> <name>\n");
	printf("match <\"net\"> <partial_name>\n");
	printf("show <what> <name>	.... available what \n");
	printf("	NOTE: this provides low-level database info, for skilled user\n");
	printf("	net_segments\n");
	printf("	cell\n");
	printf("	instance\n");
	printf("	net\n");
	printf("	net_assigns\n");
	printf("	inpin_capacitance\n");
	printf("\n");
	printf("... miscellaneous (not too useful)\n");
	printf("count_things\n");
	printf("count_cell_types\n");
	printf("compute_thresholds\n");
	printf("characterize	... thing for DaveW.\n");
	printf("clear\n");
	printf("time\n");

	printf("write_libfile\n");
	printf("write_libfile_for_cell <cellname>\n");

	return RC_NOMINAL;
}



////////////////////////////////////////////////////////////
// return codes
//	RC_NOMINAL:	command was executed
//	RC_NOTFOUND:	command (that is, "cmd") not recognized; not for 
//	RC_FAILED:	all other cases, includeing bad subcommands or file not found
//
// notice that we often pass back returns from called commands; 
// so any directly called commands *must* return either RC_NOMINAL or RC_FAILED.
// .... otherwise, tcl scripts may suffer early ejaculation 
//	and error display stuff will behave badly.

rc_t
do_something(BOOLEAN executing_command_file, 
	char *cmd, char *arg2, char *arg3, char *arg4, char *arg5)
{
	// identify command, call appropriate routine

	if (strcmp(cmd, "") == 0) {
		return RC_NOMINAL;
	}

	if (strcmp(cmd, "help") == 0		||
	    strcmp(cmd, "?") ==0		) {
		return help();
	}

	if (strcmp(cmd, "echo") == 0) {
		printf("%s\n", arg2);
		return RC_NOMINAL;
	}

	if (strcmp(cmd, "set") == 0) {
		return set(arg2, arg3, arg4);
	}

	if (strcmp(cmd, "print") == 0) {
		return print_stuff(arg2, arg3, arg4);
	}

	///////////////////////////////////////
	// important stuff (published to Lee)

	if (strcmp(cmd, "read_libfile") == 0		||
	    strcmp(cmd, "read_cell_library") == 0	) {
		return read_libfile(arg2);
	}

	// load_design_from_nl	in nl_commands.cc
	// flag_net_as_clock	in timing_commands.cc
	// set_input_delay	in timing_commands.cc
	// set_input_driver	in timing_commands.cc
	// set_input_slope	in timing_commands.cc
	// set_output_load	in timing_commands.cc
	// set_output_setup	in timing_commands.cc

	if (strcmp(cmd, "read_constraintsfile") == 0) {
		return read_constraintsfile(arg2);
	}

	// global_timing	in timing_commands.cc
	// write_long_paths_file   timing_commands.cc
	// write_slow_nodes_file   timing_commands.cc

	/////////////////////////////////



	if (strcmp(cmd, "characterize") == 0) {
		return characterize(arg2, arg3, arg4);
	}

	if (strcmp(cmd, "quit") == 0	||
	    strcmp(cmd, "q") == 0	||
	    strcmp(cmd, "exit") == 0	) {
		printf("Thank you and good night.\n");
		exit(0);
	}

	if (strcmp(cmd, "new_design") == 0) {
		return new_design(arg2);
	}

	if (strcmp(cmd, "read_dspffile") == 0) {
		return read_dspffile(arg2);
	}

	if (strcmp(cmd, "clear") == 0) {
		return clear(arg2);
	}

	if (strcmp(cmd, "find") == 0) {
		return debug_find(arg2, arg3);
	}

	if (strcmp(cmd, "match") == 0) {
		return debug_match(arg2, arg3);
	}

	if (strcmp(cmd, "show") == 0) {
		return debug_show(arg2, arg3);
	}

	if (strcmp(cmd, "count_things") == 0) {
		return count_things();
	}

	if (strcmp(cmd, "count_cell_types") == 0) {
		return count_cell_types();
	}

	if (strcmp(cmd, "top_bbox") == 0) {
		return top_bbox(arg2, arg3, arg4, arg5);

	}

	if (strcmp(cmd, "time") == 0) {
		return time();
	}

	if (strcmp(cmd, "add_extconn_for_limited_icon_creator") == 0) {
		return add_extconn_for_limited_icon_creator(arg2, arg3, arg4, arg5);
	}

	if (strcmp(cmd, "read_command_file") == 0	||
	    strcmp(cmd, "exec") == 0			) {
		return read_command_file(arg2);
	}
		


	if (strcmp(cmd, "write_libfile") == 0) {
		return write_libfile();
	}

	if (strcmp(cmd, "write_libfile_for_cell") == 0) {
		return write_libfile_for_cell(arg2);
	}



	rc_t rc = RC_NOTFOUND;

	rc = timing_do_something(executing_command_file, cmd, arg2, arg3, arg4, arg5);
	if (rc != RC_NOTFOUND)	return rc;

	rc = resize_do_something(executing_command_file, cmd, arg2, arg3, arg4, arg5);
	if (rc != RC_NOTFOUND)	return rc;

	rc = nl_do_something(executing_command_file,cmd, arg2, arg3, arg4, arg5);
	if (rc != RC_NOTFOUND)	return rc;

	if (strcmp(cmd, "get_speedy_vars_to_tcl") == 0) {
		return get_speedy_vars_to_tcl();
	}


	// look for a .cmd file
	// .... local directory ....
	sprintf(tstr, "./%s.cmd", cmd);		
	rc = read_command_file(tstr);
	switch (rc) {
	    case RC_NOMINAL:	return RC_NOMINAL;
	    case RC_NOFILE:	break;
	    default:		return RC_FAILED;
	}
		
	// ... $SPEEDY_COMMAND_PATH  .... 
	// ...cute! reload it from environment every time
	char *path = getenv("SPEEDY_COMMAND_PATH");
	if (path != NULL) {
		if (strcmp(path, speedy_command_path) != 0) {
			if (speedy_command_path != NULL)	free(speedy_command_path);
			speedy_command_path = strdup(path);
		}
	}
	sprintf(tstr, "%s/cmd/%s.cmd", speedy_command_path, cmd);		
	rc = read_command_file(tstr);
	switch (rc) {
	    case RC_NOMINAL:	return RC_NOMINAL;
	    case RC_NOFILE:	break;
	    default:		return RC_FAILED;
	}


	printf("ERROR: speedy command \"%s\" not found\n", cmd);
	return RC_NOTFOUND;
}

