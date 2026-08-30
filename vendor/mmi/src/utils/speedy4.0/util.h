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

#ifndef util_h
#define util_h

//////////////////////////////////////////////////
//	time unit is nanosecond			//
//	capacitance unit is picofarad		//
//	resistance unit is ohm			//
//////////////////////////////////////////////////

#define		CHECKSTOP_ON_ERROR

#include	<stdio.h>
#include	<string.h>
#include	<ctype.h>
#include	<errno.h>
#include	<stdlib.h>
#include	<limits.h>
#include	<unistd.h>

///////////////////////////////////////////////////

// linux fixups
#ifndef		FLT_MAX
#define		FLT_MAX		LONG_MAX
#endif

extern "C" double sqrt(double);


///////////////////////////////////////////////////



typedef int	BOOLEAN;
#define	TRUE	1
#define FALSE	0

enum rc_t {
	// ... first 3 better stay as they are to agree with speedy_package.c
	RC_NOMINAL,	// it worked as expected, normal results produced
	RC_FAILED,	// ...was OK, but it didn't work (generic)
	RC_NOTFOUND,


	RC_INVALID,	// what you said was wrong
	RC_EXCEPTION,	// ...was OK, but turns out to be a special case
	RC_NOTSPECIFIED,// ...didn't work & here's a clue 
	RC_INUSE,
	RC_BADSYNTAX,
	RC_NOFILE,
	RC_OVERFLOW,

	// ...domain-specific...
	RC_NOIMPROVEMENT,
	RC_IMPROVED, 
	RC_GOALNOTMET,
	RC_COMPLETE,

	RC_UPSIZE,
	RC_DOWNSIZE,

	RC_SCALER,	// problems with libfile tables
	RC_OFFTABLE		
};


#define		ASSERT($cond)	if (!($cond)) {				\
					printf("ASSERT $cond\n");	\
					exxit();			\
				}


#define		pe1($format, $variable)		sprintf(tstr, $format, $variable);	\
						pe(tstr);

#define LINEBUFSIZE	0x1000

//////////////////////////////////////////

#include <tcl.h>

#include "path.h"
#include "constraintsfile.h"


extern rc_t initialize_global_downstream();

enum NET_MODEL {
	EXTRACTED_NETS,		// read segments eg from DSPF file
	STEINER_RC_NETS,	// steiner nets as r/c tree
	STEINER_CAP_NETS,	// steiner nets for metal load cap
	IGNORE_NETS,		// no wire load (gates only), no delay
	WIRE_LOAD_CAP_NETS,		// guess net metal (constant * n_inputs)
	EXPLICIT_CAP_NETS		// metal cap from file (could also be DSPF)
};

extern rc_t speedy2tcl(char *cmd, char *retv);
extern rc_t speedy2tcl_setvar(char *varname, char *value);

#include	"./nl_speedy.h"

extern		NL_INTERFACE *	nl_interface;

// we like all caps for class names... 
// ... actually these things are struct pointers, 
// but close enough...
typedef		nl_idesign	NL_IDESIGN;
typedef		nl_icell	NL_ICELL;
typedef		pnl_icell	NL_PCELL;	// different.... something has to be...
typedef		nl_inet		NL_INET;
typedef		nl_iport	NL_IPORT;
typedef		nl_cell		NL_CELL;
typedef		nl_design	NL_DESIGN;

extern		Tcl_Obj *	current_nldesign_tcl_obj;

#include "lib.h"
#include "design.h"
#include "clone.h"
#include "libfile.h"
#include "dspffile.h"

extern rc_t	clear(char *);

//////////////////////////////////////////
// definitions (and comments) corresponding to the 
// following declarations are in speedy_commands.cc

extern DESIGN *		design;
extern DESIGN *		temp_design;

extern char *		design_name;
extern char *		top_level_cellname;

extern BOOLEAN		initialization_is_complete;
extern BOOLEAN		use_sue_clones;		// ... as opposed to nl clones... 

extern CELL_LIBRARY *	cell_library;

extern float		clock_period;

extern float		rconst;		// in ohms per grid unit
extern float		cconst;		// in picofarads per grid unit 
extern float		cap_fudge;
extern char *		placement_distance_unit;
extern float		distance_unit_multiplier;

extern NET_MODEL	net_model;
extern float		wire_cap_per_load_for_wire_load_model;

extern NET_MODEL	net_model;
extern float		assumed_outport_load;
extern float		clock_slope;
extern float		target_slope;
extern BOOLEAN		use_rc_net_delay;
extern float		fast_net_delay;
extern int		pearl_maxpossibilities;
extern BOOLEAN		check_inputs_on_clock_nets;
extern float		maximum_desireable_slope;
extern char *		buffer_cellname;
extern char *		inverter_cellname;
extern CELL *		buffer_cell;
extern CELL *		inverter_cell;
extern BOOLEAN		compute_thresholds_use_limit_method;
extern float		threshold_slope;
extern float		upsize_threshold; 
extern float		downsize_threshold; 
extern float		minimum_desireable_slack;
extern BOOLEAN		allow_upsize_for_optimize;
extern BOOLEAN		allow_downsize_on_critical_path_for_optimize;
extern BOOLEAN		allow_swap_inports_for_optimize;
extern BOOLEAN		downsize_unloaded_instances;
extern float		permissable_table_underrun;
extern float		permissable_table_overrun;
extern float		buffer_insertion_threshold_slope;
extern BOOLEAN		do_buffer_insertion;
extern BOOLEAN		split_nets_during_add_buffers;
extern BOOLEAN		add_buffers_during_path_optimization;

extern BOOLEAN		print_modified_cells; 
extern char *		DEFAULT_COMMAND_FILE_NAME;

#define	TSTRSIZE	0x1000
extern char		tstr[];
extern char		tstr2[];

extern int		next_sequential_number;

extern char *		default_speedy_path;
extern char *		speedy_path;

extern BOOLEAN		location_information_is_loaded;

// length of buffers for net names, etc.
#define FIELDSIZE	0x1000

// debuggery....
extern NET *		fave_net;
extern INSTANCE *	fave_instance;
extern CLONE *		fave_clone;
extern INPORT *		fave_inport;
extern BOOLEAN		speedy_verbose;
extern BOOLEAN		insert_names_in_nets_and_instances;
extern void		exxit(int, char *);
extern void		exxit();

#endif
