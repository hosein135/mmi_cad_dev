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

//////////////////////////////////////////////////////////////
// forward declarations

rc_t	print_long_path();
rc_t	print_long_delay();
rc_t	print_saved_path();
rc_t	print_timing_sources();
rc_t	print_timing_destinations();
rc_t	print_path(PATH *, FILE *);
rc_t	print_slow_nodes();



//////////////////////////////////////////////////////////////

rc_t
set_timing_stuff(char *var_name, char *arg_value)
{
	
	if (strcmp(var_name, "net_model") == 0) {
		if (strcmp(arg_value, "STEINER_RC_NETS") == 0) {
			::net_model = STEINER_RC_NETS;
		} else 
		if (strcmp(arg_value, "STEINER_CAP_NETS") == 0) {
			::net_model = STEINER_CAP_NETS;
		} else 
		if (strcmp(arg_value, "IGNORE_NETS") == 0) {
			::net_model = IGNORE_NETS;
		} else 
		if (strcmp(arg_value, "WIRE_LOAD_CAP_NETS") == 0) {
			::net_model = WIRE_LOAD_CAP_NETS;
		} else 
		if (strcmp(arg_value, "EXPLICIT_CAP_NETS") == 0) {
			::net_model = EXPLICIT_CAP_NETS;
		} else 

		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "clock_slope") == 0) {
		float arg;
		int rv = sscanf(arg_value, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can\'t convert to float for clock_slope: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg_value);
			return RC_FAILED;
		}
		if (arg > 1.0) {
			printf("WARNING: clock slope set to %f nanoseconds; that LOOKS like a large value...\n", arg);
		}
		clock_slope = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "maximum_desireable_slope") == 0) {
		float arg;
		int rv = sscanf(arg_value, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can\'t convert to float for maximum_desireable_slope: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg_value);
			return RC_FAILED;
		}
		maximum_desireable_slope = arg;
		return RC_NOMINAL;
	}

	if (strcmp(var_name, "target_slope") == 0) {
		float arg;
		int rv = sscanf(arg_value, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can\'t convert to float for target_slope: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg_value);
			return RC_FAILED;
		}
		if (arg > 1.0) {
			printf("WARNING: target slope set to %f nanoseconds; that LOOKS like a large value...\n", arg);
		}
		target_slope = arg;

#ifdef RESIZE_FEATURE
		if (cell_library != NULL) {
			printf("recalculating cell threshold load...\n");
			cell_library->compute_thresholds(target_slope, compute_thresholds_use_limit_method);
		}
#endif		
		
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "pearl_maxpossibilities") == 0) {
		int arg;
		int rv = sscanf(arg_value, "%d", &arg);
		if (rv != 1) {
			printf("file %s line %d: can\'t convert to int for pearl_maxpossibilities: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg_value);
			return RC_FAILED;
		}
		pearl_maxpossibilities = arg;
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "use_rc_net_delay") == 0) {
		BOOLEAN value_changed = false;

		if (strcmp(arg_value, "true") == 0) {
			if (use_rc_net_delay == false)	value_changed = true;
		 	use_rc_net_delay = true;
		}
		else if (strcmp(arg_value, "false") == 0) {
			if (use_rc_net_delay == true)	value_changed = true;
			use_rc_net_delay = false;
		}
 		else {
			printf("file %s line %d: use_rc_net_delay: specify \"true\" or \"false\", please\n",
			    cur_cmdfilename, cur_cmdfileline);
			return RC_FAILED;
		}

		if (value_changed == true		&&
		    initialization_is_complete == true	) {
			design->compute_net_characteristics();
		}
		return RC_NOMINAL;
	}
	
	if (strcmp(var_name, "fast_net_delay") == 0) {
		float arg;
		int rv = sscanf(arg_value, "%f", &arg);
		if (rv != 1) {
			printf("file %s line %d: can\'t convert to float for fast_net_delay: \"%s\"\n", 
			    cur_cmdfilename, cur_cmdfileline, arg_value);
			return RC_FAILED;
		}
		fast_net_delay = arg;
		return RC_NOMINAL;
	}

	return RC_NOTFOUND;
}

rc_t
print_timing_stuff(char *stuff_name, char *arg2, char *arg3)
{
	if (strcmp(stuff_name, "fast_net_delay") == 0) {
		printf("fast_net_delay = %f\n", fast_net_delay);
		return RC_NOMINAL;
	}
	
	if (strcmp(stuff_name, "pearl_maxpossibilities") == 0) {
		printf("pearl_maxpossibilities = %d\n", pearl_maxpossibilities);
		return RC_NOMINAL;
	}
	
	if (strcmp(stuff_name, "clock_slope") == 0) {
		printf("clock_slope = %f\n", clock_slope);
		return RC_NOMINAL;
	}
	
	if (strcmp(stuff_name, "assumed_outport_load") == 0) {
		printf("assumed_outport_load = %f\n", assumed_outport_load);
		return RC_NOMINAL;
	}
	
	if (strcmp(stuff_name, "use_rc_net_delay") == 0) {
		if (use_rc_net_delay == true)	printf("use_rc_net_delay = true\n");
		else				printf("use_rc_net_delay = false\n");
		return RC_NOMINAL;
	}
	if (strcmp(stuff_name, "long_path") == 0) {
		return print_long_path();
	}

	if (strcmp(stuff_name, "long_delay") == 0) {
		return print_long_delay();
	}

	if (strcmp(stuff_name, "saved_path") == 0) {
		return print_saved_path();
	}

	if (strcmp(stuff_name, "timing_destinations") == 0) {
		return print_timing_destinations();
	}

	if (strcmp(stuff_name, "timing_sources") == 0) {
		return print_timing_sources();
	}

	if (strcmp(stuff_name, "slow_nodes") == 0) {
		return print_slow_nodes();
	}

	return RC_NOTFOUND;
}

//////////////////////////////////////////////////
// print helpers

rc_t
print_long_path()
{
	if (design->global_downstream == NULL) {
		printf("no long path established, run global_timing\n");
		return RC_FAILED;
	}


	print_path(design->global_downstream->long_path, stdout);

	return RC_NOMINAL;
}

rc_t
print_long_delay()
{
	design->global_timing();
	PATH *long_path = design->global_downstream->long_path;
	printf("long path %f\n", long_path->absolute_delay);
	return RC_NOMINAL;
}

rc_t
print_saved_path()
{
	printf(".... display current values along saved path .... see also time_saved_path\n");

	if (design == NULL) {
		printf("speedy has no design loaded\n");
		return RC_FAILED;
	}  

	if (design->saved_path == NULL) {
		printf("no saved path established\n");
		return RC_NOTFOUND;
	}

	PATHELEMENT *pe = design->saved_path->final_pathelement;
	while (pe != NULL) {
		PATHELEMENT *db_pe = NULL;
		if (pe->rising_at_outport == true) {
			db_pe = pe->outport->rising_long_path;
		} else {
			db_pe = pe->outport->falling_long_path;
		}
		pe->gate_delay = db_pe->gate_delay;
		pe->absolute_delay = db_pe->absolute_delay;

		pe = pe->previous;
	}
	design->saved_path->compute_final_timing();

	print_path(design->saved_path, stdout);
	printf("...(final stage is computed)...\n");
	return RC_NOMINAL;
}

rc_t
print_timing_sources()
{
	if (design->global_downstream == NULL) {
		printf("global_downstream not initialized\n");
		return RC_FAILED;
	}

	ListOfINSTANCE *il = design->global_downstream->root_instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		switch (instance->type) {
		    case INSTANCE_INSTANCETYPE:
			printf("%s\n", instance->get_name());
			break;

		    case INPUT_EXTCONN_INSTANCETYPE:
			printf("<extconn> %s\n", instance->get_name());
			break;

		    case OUTPUT_EXTCONN_INSTANCETYPE:
			printf("<extconn> %s.... output instancetype?????\n", instance->get_name());
			break;
		}
	}
	return RC_NOMINAL;
}


rc_t
print_timing_destinations()
{
	if (design->global_downstream == NULL) {
		printf("global_downstream not initialized\n");
		return RC_FAILED;
	}

	printf("say! how DO we do this???\n");
	return RC_NOMINAL;
}


/////////////////////////////////////////////////////////
// file readers/writers

void
write_pathelement_for_timing_out_file(PATHELEMENT *pe, FILE *f)
{
	if (pe->previous != NULL)	write_pathelement_for_timing_out_file(pe->previous, f);

	char rise_or_fall;
	if (pe->rising_at_outport == true)	rise_or_fall = '^';
	else					rise_or_fall = 'v';

	int fanout = 0;
	ListOfINPORT *ipl = pe->outport->net->inportlist;
	while (ipl != NULL) {
		fanout++;
		ipl = ipl->next;
	}

	if (use_rc_net_delay == false) {

		if (pe->outport->instance->cell->type == CELLTYPE_EXTCONN) {
			// ... origin is an external
			fprintf(f, "0ps			0	%.0fps	_input_	%c\n", 
			    pe->slope_at_outport * 1000.0,
			    rise_or_fall);

			fprintf(f, "%.0fps	%.0fps	%.0ffF	%d	%.0fps	%s	%c	arrival\n", 
			    pe->absolute_delay * 1000.0, 
			    pe->gate_delay * 1000.0, 
			    pe->outport->load_capacitance * 1000.0,
			    fanout,
			    pe->slope_at_outport * 1000.0,
			    pe->outport->net->get_name(),
			    rise_or_fall);
		}
		else {  		
			fprintf(f, "%.0fps	%.0fps	%.0ffF	%d	%.0fps	%s	%c	%s	%s\n", 
			    pe->absolute_delay * 1000.0, 
			    pe->gate_delay * 1000.0, 
			    pe->outport->load_capacitance * 1000.0,
			    fanout,
			    pe->slope_at_outport * 1000.0,
			    pe->outport->net->get_name(),
			    rise_or_fall,
			    pe->outport->instance->get_name(),
			    pe->outport->instance->cell->name);
		}
	}
	else {
		NET *net = pe->outport->net;
		if (net->global_value == GLOBAL_CLOCK) {
			fprintf(f, "0ps			0	%.0fps	_input_	%c\n", 
			    pe->slope_at_outport * 1000.0,
			    rise_or_fall);

			fprintf(f, "0ps	0ps	%.0ffF	%d	%.0fps	%s	%c	arrival\n", 
			    pe->outport->load_capacitance * 1000.0,
			    fanout,
			    pe->slope_at_outport * 1000.0,
			    pe->outport->net->get_name(),
			    rise_or_fall);

		}
		else if (pe->outport->instance->cell->type == CELLTYPE_EXTCONN) {
			// ... origin is an external
			fprintf(f, "0ps			0	%.0fps	_input_	%c\n", 
			    pe->slope_at_outport * 1000.0,
			    rise_or_fall);

			fprintf(f, "%.0fps	%.0fps	%.0ffF	%d	%.0fps	%s	%c	arrival\n", 
			    (pe->absolute_delay - pe->gate_delay) * 1000.0, 
			    0.0, 
			    pe->outport->load_capacitance * 1000.0,
			    fanout,
			    pe->slope_at_outport * 1000.0,
			    pe->outport->net->get_name(),
			    rise_or_fall);
		}
		else {  		
//  498ps 124ps    102fF      1      55ps mezzanine/net_102[13] v  mezzanine/pi_wrapper/MMI_BUFE_11$13$     MMI_BUFE  
//  508ps   9ps    102fF      1      65ps mezzanine/net_102[13] v                                                       


			fprintf(f, "%.0fps	%.0fps	%.0ffF	%d	%.0fps	%s	%c	%s	%s\n", 
			    (pe->absolute_delay - pe->inport->net_delay) * 1000.0, 
			    pe->gate_delay * 1000.0, 
			    pe->outport->load_capacitance * 1000.0,
			    fanout,
			    pe->slope_at_outport * 1000.0,
			    pe->outport->net->get_name(),
			    rise_or_fall,
			    pe->outport->instance->get_name(),
			    pe->outport->instance->cell->name);
			fprintf(f, "%.0fps	%.0fps	%.0ffF	%d	%.0fps	%s	%c\n", 
			    pe->absolute_delay * 1000.0, 
			    pe->inport->net_delay * 1000.0, 
			    pe->outport->load_capacitance * 1000.0,
			    fanout,
			    pe->slope_at_outport * 1000.0,
			    pe->outport->net->get_name(),
			    rise_or_fall);
		}
	}
	return;
}



rc_t
write_timing_out_file(char *filename) 
{
	if (::design == NULL			||
	    ::design->global_downstream == NULL	){
		printf("global_timing not complete, write_timing_out_file aborted\n");
		return RC_FAILED;
	}

	if (filename[0] == '\0') {
		printf("timing out filename not specified\n");
		return RC_FAILED;
	}

	FILE *file = fopen(filename, "w");
	if (file == NULL) {
		printf("open file \"%s\" failed errno %d\n", filename, errno);
		return RC_FAILED;
	}

	fprintf(file, "cmd> findpathsfrom _input_\n");
	//  setl {first type constraint condition time} $line
	//
	//  1: 6367ps Path to maddr[6] ^
	//  2: 6213ps Path to multimatch_out ^
	//  ...
	// 10: 5587ps Path to maddr[11] ^

	ListOfPATH *long_pathlist = design->global_downstream->get_long_pathlist(pearl_maxpossibilities);

	ListOfPATH *pl = long_pathlist;
	for (int possibility = 0; possibility < pearl_maxpossibilities; possibility++) {
		if (pl == NULL)	break;
		PATH *path = pl->path;
		pl = pl->next;  

		char riseorfall;
		if (path->final_pathelement->rising_at_outport == true)	riseorfall = '^';
		else							riseorfall = 'v';
	
		fprintf(file, " %d: %.0fps Path to %s %c\n", possibility,
		    path->absolute_delay * 1000.0, path->destination_inport->net->get_name(), riseorfall);
	}
	
	fprintf(file, "cmd> showpossibility 1 %d\n", pearl_maxpossibilities);
	pl = long_pathlist;
	for (int possibility = 0; possibility < pearl_maxpossibilities; possibility++) {
		if (pl == NULL)	break;
		PATH *path = pl->path;
		pl = pl->next;  

		// cmd> showpossibility 1
		// Possibility 1:
		//  Delay  Delta Load Cap Fanout Rise/Fall Node   
		//  -----  ----- -------- ------ --------- ----   
		//    0ps                      0     120ps _input_ ...
		//    0ps    0ps     34fF      6     200ps match[2
		//  184ps  184ps     19fF      1     165ps bank0/p
		//  184ps    0ps     19fF      1     165ps bank0/p

		fprintf(file, "cmd> showpossibility %d\n", possibility);
		fprintf(file, "Possibility %d:\n", possibility);
		fprintf(file, " Delay Delta Load Cap Fanout Rise/Fall Node         Device       Cell\n");
		fprintf(file, " ----- ----- -------- ------ --------- ----         ------       ----\n");       

		PATHELEMENT *pe = path->final_pathelement;
		if (pe == NULL)		continue;
		write_pathelement_for_timing_out_file(path->final_pathelement, file);

	}
	delete long_pathlist;

	// this terminates the "Possibilities"
	fprintf(file, "cmd> # done\n");
	fprintf(file, "cmd> # done\n");

	fprintf(file, "cmd> findmincycletime\n");
	fprintf(file, "cmd> # done\n");

	ListOfNET *nl = design->netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		// ... in this case we *do* want duplicate entries for assigned nets
		fprintf(file, "x showdelays %s\n", net->get_name());

		float rising_delay = net->source->rising_long_path->absolute_delay * 1000.0; 
		float falling_delay = net->source->falling_long_path->absolute_delay * 1000.0;

		if (use_rc_net_delay == true) {
			// Sue doesn't have a way to report different net delays
			// to the various load pins, so we have to take the max
			// and apply it everywhere.

			float max_net_delay = -FLT_MAX;	
			ListOfINPORT *ipl = net->inportlist;
			while (ipl != NULL) {
				INPORT *inport = ipl->inport;
				ipl = ipl->next;

				if (inport->net_delay > max_net_delay) {
					max_net_delay = inport->net_delay;
				}
			}
			rising_delay += max_net_delay * 1000.0;
			falling_delay += max_net_delay * 1000.0;
		}
		
		fprintf(file, "_input_ ^ -> 0ps-%.0fps ^ 0ps-%.0fps v\n", rising_delay, falling_delay);
	}

	fclose(file);
	printf("done\n");

	return RC_NOMINAL;
}



//////////////////////////////////////////////////
// other methods

rc_t
flag_net_as_clock(char *netname)
{
	NET *net = design->get_net(netname);
	if (net == NULL) {
		printf("can't find net \"%s\"\n", netname);
		return RC_NOMINAL;
	}	

	net->global_value = GLOBAL_CLOCK;
	return RC_NOMINAL;
}

rc_t
set_input_delay(char *input_name, char *delay_str)
{
	float delay;
	int rv = sscanf(delay_str, "%f", &delay);
	if (rv != 1) {
		printf("can't convert to float for input delay: \"%s\"\n", delay_str);
		return RC_FAILED;
	}

	if (::design == NULL) {
		printf("no design\n");
		return RC_FAILED;
	}

	if (strcmp(input_name, "ALL") == 0) {
		ListOfEXTCONN *el = ::design->extconnlist;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (extconn->type != INPUT_EXTCONN_INSTANCETYPE) continue;
			extconn->delay = delay;
		}
	} else {
		EXTCONN *extconn = ::design->get_extconn(input_name);
		if (extconn == NULL) {
			printf("input \"%s\" not found\n", input_name);
			return RC_FAILED;
		}
		if (extconn->type != INPUT_EXTCONN_INSTANCETYPE) {
			printf("extconn \"%s\" is not input type\n", input_name);
			return RC_FAILED;
		}			
		extconn->delay = delay;
	}

	return RC_NOMINAL;
}		

rc_t
set_input_driver(char *input_name, char *driver_cellname)
{
	printf("set input driver not implemented\n");
	return RC_FAILED;
}

rc_t
set_input_slope(char *input_name, char *slope_str)
{
	float slope;
	int rv = sscanf(slope_str, "%f", &slope);
	if (rv != 1) {
		printf("can't convert to float for input slope: \"%s\"\n", slope_str);
		return RC_FAILED;
	}

	if (::design == NULL) {
		printf("no design\n");
		return RC_FAILED;
	}

	if (strcmp(input_name, "ALL") == 0) {
		ListOfEXTCONN *el = ::design->extconnlist;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (extconn->type != INPUT_EXTCONN_INSTANCETYPE) continue;
			extconn->slope = slope;
		}
	} else {
		EXTCONN *extconn = ::design->get_extconn(input_name);
		if (extconn == NULL) {
			printf("input \"%s\" not found\n", input_name);
			return RC_FAILED;
		}
		if (extconn->type != INPUT_EXTCONN_INSTANCETYPE) {
			printf("extconn \"%s\" is not input type\n", input_name);
			return RC_FAILED;
		}			
		extconn->slope = slope;
	}

	return RC_NOMINAL;
}		


rc_t
set_output_load(char *output_name, char *load_str)
{
	float load;
	int rv = sscanf(load_str, "%f", &load);
	if (rv != 1) {
		printf("can't convert to float for input load: \"%s\"\n", load_str);
		return RC_FAILED;
	}

	if (::design == NULL) {
		printf("no design\n");
		return RC_FAILED;
	}

	if (strcmp(output_name, "ALL") == 0) {
		ListOfEXTCONN *el = ::design->extconnlist;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (extconn->type != OUTPUT_EXTCONN_INSTANCETYPE) continue;
			extconn->load = load;
		}
	} else {
		EXTCONN *extconn = ::design->get_extconn(output_name);
		if (extconn == NULL) {
			printf("output \"%s\" not found\n", output_name);
			return RC_FAILED;
		}
		if (extconn->type != OUTPUT_EXTCONN_INSTANCETYPE) {
			printf("extconn \"%s\" is not output type\n", output_name);
			return RC_FAILED;
		}			
		extconn->load = load;
	}

	return RC_NOMINAL;
}		

rc_t
set_output_setup(char *output_name, char *delay_str)
{
	float delay;
	int rv = sscanf(delay_str, "%f", &delay);
	if (rv != 1) {
		printf("can't convert to float for output setup: \"%s\"\n", delay_str);
		return RC_FAILED;
	}

	if (::design == NULL) {
		printf("no design\n");
		return RC_FAILED;
	}

	if (strcmp(output_name, "ALL") == 0) {
		ListOfEXTCONN *el = ::design->extconnlist;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (extconn->type != OUTPUT_EXTCONN_INSTANCETYPE) continue;
			extconn->delay = delay;
		}
	} else {
		EXTCONN *extconn = ::design->get_extconn(output_name);
		if (extconn == NULL) {
			printf("output \"%s\" not found\n", output_name);
			return RC_FAILED;
		}
		if (extconn->type != OUTPUT_EXTCONN_INSTANCETYPE) {
			printf("extconn \"%s\" is not output type\n", output_name);
			return RC_FAILED;
		}			
		extconn->delay = delay;
	}

	return RC_NOMINAL;
}

rc_t
compute_net_characteristics()
{
	if (design == NULL) {
		printf("complete_initializtion: no design!\n");
		return RC_FAILED;
	}

	rc_t rc = design->compute_net_characteristics();
	return rc;
}	

rc_t
global_timing()
{  
	// DESIGN::global timing calls DESIGN::complete_initialization,
	// if global_downstream == NULL	

	rc_t rc = design->global_timing();
	if (rc != RC_NOMINAL) {
		printf("global timing failed\n");
		return RC_FAILED;
	}

	printf("long delay: %f\n", design->global_downstream->long_delay);
	PATH *path = design->global_downstream->long_path;
	if (path == NULL) {
		printf("no paths found for this design\n");
		return RC_NOMINAL;
	}
	path->write_to_file(stdout);
	return RC_NOMINAL;
}	

rc_t
write_long_paths_file(char *n_paths_str, char *filename)
{
	int n_long_paths = strtol(n_paths_str, NULL, 10);
	if (n_long_paths <= 1	||
	    n_long_paths > 10	) {
		printf("ERROR: number of long paths between 1 and 10, please, not \"%d\"\n", n_long_paths);
		return RC_FAILED;
	}

	if (::design == NULL			||
	    ::design->global_downstream == NULL	){
		printf("ERROR: design not initialized or global_timing not done\n");
		return RC_FAILED;
	}


	FILE *f = fopen(filename, "w");
	if (f == NULL) {
		printf("ERROR: can't open file \"%s\" for writing, errno %d\n", filename, errno);
		return RC_FAILED;
	}

	ListOfPATH *pathlist = ::design->global_downstream->get_long_pathlist(n_long_paths);
	ListOfPATH *pl = pathlist;
	int pathno = 0;
	while (pl != NULL		&&
	    pathno < n_long_paths	) {
		PATH *path = pl->path;
		pl = pl->next;
	
		pathno++;
		fprintf(f, "path %d %.3fns\n", pathno, path->absolute_delay);
		path->write_to_file(f);
		fprintf(f, "\n");
	}

	if (pathno != n_long_paths) {
		printf("you asked for %d paths, but only %d paths were found\n", n_long_paths, pathno);
	}

	fclose(f);
	delete pathlist;
	return RC_NOMINAL;
}



rc_t
print_slow_nodes()
{
	printf("outport transistions slower than %.3fns .... (\"set maximum_desireable_slope\")\n", maximum_desireable_slope);

	ListOfPATHELEMENT *slow_pelist = design->global_downstream->get_slow_nodes();	

	int count = 0;
	ListOfPATHELEMENT *pel = slow_pelist;
	while (pel != NULL) {
		PATHELEMENT *pathelement = pel->pathelement;
		pel = pel->next;
		count++;

		char riseorfall;
		if (pathelement->rising_at_outport == true)	riseorfall = '^';
		else						riseorfall = 'v';

		if (pathelement->outport->instance != NULL) {
			printf("%.3fns	%c	%s:%s	%s\n",	
			    pathelement->slope_at_outport,
			    riseorfall,
			    pathelement->outport->instance->get_name(),
			    pathelement->outport->outpin->name,
			    pathelement->outport->net->get_name());
		}
		else {
			printf("%.3fns	%c	%s (external input)\n",	
			    pathelement->slope_at_outport,
			    riseorfall,
			    pathelement->outport->outpin->name);
		}
	}
	printf("...%d slow nodes found, counting both directons\n", count);
	return RC_NOMINAL;
}




rc_t
write_slow_nodes_file(char *filename, char *limit_str)
{
	if (::design == NULL			||
	    ::design->global_downstream == NULL	){
		printf("global_timing not complete, write_slow_nodes_file aborted\n");
		return RC_FAILED;
	}

	if (strlen(limit_str) > 0x10) {
		printf("write_slow_nodes_file: limit_str is too long \"%s\"\n", limit_str);
		return RC_FAILED;
	}
	char limit_units[0x10];
	float limit_value;
	int rv = sscanf(limit_str, "%f%s", &limit_value, limit_units);
	if (rv != 2) {
		printf("write_slow_nodes_file: can't figure limit value \"%s\"\n", limit_str);
		return RC_FAILED;
	}
	switch (limit_units[0]) {
	    case 'n':
	    case 'N':
		// fine
		break;

	    case 'p':
	    case 'P':
		// convert to nanos
		limit_value /= 1000.0;
		break;

	    default:
		printf("write_slow_nodes_file: don't recognize units \"%s\"\n", limit_str);
		return RC_FAILED;
	}
	maximum_desireable_slope = limit_value;	
	
	if (filename[0] == '\0') {
		printf("slow_nodes filename not specified\n");
		return RC_FAILED;
	}
	FILE *file = fopen(filename, "w");
	if (file == NULL) {
		printf("open file \"%s\" failed errno %d\n", filename, errno);
		return RC_FAILED;
	}

	ListOfPATHELEMENT *slow_pelist = design->global_downstream->get_slow_nodes();	
	if (slow_pelist == NULL) {
		fprintf(file, "no slow nodes found\n");
		return RC_NOMINAL;
	}

	int count = 0;
	ListOfPATHELEMENT *pel = slow_pelist;
	while (pel != NULL) {
		PATHELEMENT *pathelement = pel->pathelement;
		pel = pel->next;
		count++;

		char riseorfall;
		if (pathelement->rising_at_outport == true)	riseorfall = '^';
		else						riseorfall = 'v';

		if (pathelement->outport->instance != NULL) {
			fprintf(file, "%.3fns	%c	%s:%s\n",	
			    pathelement->slope_at_outport,
			    riseorfall,
			    pathelement->outport->instance->get_name(),
			    pathelement->outport->outpin->name);
		}
		else {
			fprintf(file, "%.3fns	%c	%s (external input)\n",	
			    pathelement->slope_at_outport,
			    riseorfall,
			    pathelement->outport->outpin->name);
		}
	}
	fprintf(file, "...%d slow nodes found (counting ^ and v separately)\n", count);
	
	fclose(file);
	return RC_NOMINAL;
}



rc_t
write_long_path_file(char *filename)
{
	if (::design == NULL					||
	    ::design->global_downstream == NULL			||
	    ::design->global_downstream->long_path == NULL	){
		printf("no long path defined\n");
		return RC_FAILED;		
	}

	if (filename[0] == '\0') {
		printf("long path filename not specified\n");
		return RC_FAILED;
	}
	FILE *file = fopen(filename, "w");
	if (file == NULL) {
		printf("open file \"%s\" failed errno %d\n", filename, errno);
		return RC_FAILED;
	}

	rc_t rc = ::design->global_downstream->long_path->write_to_file(file);

	fclose(file);
	return rc;
}


rc_t
print_path(PATH *path, FILE *file)
{
	// write_timing_out_file uses this to write "possibilities" to t.o. file

	path->print_like_pearl(file);
	return RC_NOMINAL;
}

rc_t
create_saved_path(char *netname, char *rising_str)
{
	if (design->global_downstream == NULL) {
		design->global_timing();
	}

	if (design->saved_path != NULL) {
		delete design->saved_path;
		design->saved_path = NULL;
	}

	BOOLEAN rising;
	switch (*rising_str) {
	    case '^':	rising = true;	break;
	    case 'v':	rising = false;	break;
	    default:
		printf("rising should be '^' or 'v'\n");
		return RC_FAILED;
	}

	NET *net = design->get_net(netname);
	if (net == NULL) {
		printf("net \"%s\" not found\n", netname);
		return RC_NOTFOUND;
	}

	design->saved_path = new PATH(net->source, rising);
	return RC_NOMINAL;
}

rc_t
add_to_saved_path(char *netname, char *rising_str)
{
	PATH *path = design->saved_path;
	if (path == NULL) {
		printf("no current saved path just now\n");	
		return RC_FAILED;
	}

	// ..... find pathelement outport
	NET *net = design->get_net(netname);
	if (net == NULL) {
		printf("net \"%s\" not found\n", netname);
		return RC_NOTFOUND;
	}
	OUTPORT *outport = net->source;
	
	// ..... find pathelement inport
	INSTANCE *instance = outport->instance;
	if (instance->cell->type == CELLTYPE_EXTCONN) {
		printf("net is external connection???\n");
		return RC_FAILED;
	}
	INPORT *inport = NULL;
	ListOfINPORT *ipl = instance->inportlist;
	while (ipl != NULL) {
		inport = ipl->inport;
		if (inport->net->source == path->final_pathelement->outport) break;
		ipl = ipl->next;
	}
	if (ipl == NULL) {
		printf("net doesn't connect to end of saved_path\n");
		return RC_FAILED;
	}

	// ..... find outpintiming, paying attention to sense
	BOOLEAN rising;
	BOOLEAN previous_rising = path->final_pathelement->rising_at_outport;
	OUTPINTIMING_SENSE sense = UNKNOWN_SENSE;
	switch (*rising_str) {
	    case '^':	
		rising = true;	
		if (previous_rising == true)	sense = POSITIVE_SENSE;
		else				sense = NEGATIVE_SENSE;
		break;

	    case 'v':	
		rising = false;	
		if (previous_rising == true)	sense = NEGATIVE_SENSE;
		else				sense = POSITIVE_SENSE;
		break;

	    default:
		printf("rising should be '^' or 'v'\n");
		return RC_FAILED;
	}

	OUTPINTIMING *outpintiming;
	ListOfOUTPINTIMING *optl = outport->outpin->outpintiminglist;
	while (optl != NULL) {
		outpintiming = optl->outpintiming;
		if (outpintiming->related_inpin == inport->inpin) {
			switch (outpintiming->sense) {
			    case NEGATIVE_SENSE:
				if (sense == NEGATIVE_SENSE)	goto gotit;
				break;

			    case POSITIVE_SENSE:
				if (sense == POSITIVE_SENSE)	goto gotit;
				break;

			    case RISING_EDGE:
			    case FALLING_EDGE:
				goto gotit;

			    default:
				printf("ERROR: unknown sense\n");
				return RC_FAILED;
			}
		}
		optl = optl->next;
	}
	printf("ERROR: no outpintiming exists for this arc\n");	
	return RC_FAILED;

    gotit:
	PATHELEMENT *new_pe = new PATHELEMENT(outport, rising);
	new_pe->inport = inport;
	new_pe->outpintiming = outpintiming;

	new_pe->previous = path->final_pathelement;
	path->final_pathelement = new_pe;

	return RC_NOMINAL;
}

rc_t
complete_saved_path(char *instancename)
{
	PATH *path = design->saved_path;
	if (path == NULL) {
		printf("no current saved path just now\n");	
		return RC_FAILED;
	}

	INPORT *inport;
	NET *net = path->final_pathelement->outport->net;

	// name might be instance or extconn
	INSTANCE *instance = design->get_instance(instancename);
	if (instance != NULL) {

		// find which inport connects
		ListOfINPORT *ipl = instance->inportlist;
		while (ipl != NULL) {
			inport = ipl->inport;
			if (inport->net == net)		break;
			ipl = ipl->next;
		}
		if (ipl == NULL) {
			printf("instance \"%s\" doesn\'t connect\n", instancename);
			return RC_NOTFOUND;
		}	
		// we have arrived		
		path->destination_inport = inport;
		return RC_NOMINAL;	
	
	} 
	else {	
		// maybe it's an extconn...
		// ... which would be an output of a local instance...
		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {
			inport = ipl->inport;
			ipl = ipl->next;

			INSTANCE *instance = inport->instance;
			if (instance->cell->type != CELLTYPE_EXTCONN)	continue;

			// we have arrived		
			path->destination_inport = inport;
			return RC_NOMINAL;					 			
		}

		if (ipl == NULL) {
			printf("\"%s\" isn\'t a connected instance nor extconn\n", instancename);
			return RC_FAILED;
		}
	}		

	// not reached
	return RC_NOMINAL;	
}

void
save_long_path_recursive(FILE *f, PATHELEMENT *pe)
{
	char rise_or_fall;
	if (pe->rising_at_outport == true)	rise_or_fall = '^';
	else					rise_or_fall = 'v';

	if (pe->previous == NULL) {
		fprintf(f, "create_saved_path	%s	%c\n", pe->outport->net->get_name(), rise_or_fall);
		return;
	}
	save_long_path_recursive(f, pe->previous);
	fprintf(f, "add_to_saved_path	%s	%c\n", pe->outport->net->get_name(), rise_or_fall);
}

rc_t
save_long_path(char *filename)
{
	if (design == NULL) {
		printf("speedy has no design loaded\n");
		return RC_FAILED;
	}  


	if (design->global_downstream == NULL) {
		rc_t rc = design->global_timing();
		if (rc != RC_NOMINAL)	return rc;
	}

	if (design->saved_path != NULL) {
		delete design->saved_path;
		design->saved_path = NULL;
	}

	design->saved_path = new PATH(*design->global_downstream->long_path);
	printf("saved path at 0x%x\n", (unsigned)design->saved_path);

	if (strcmp(filename, "") != 0) {
		FILE *f = fopen(filename, "w");
		if (f == NULL) {
			printf("can't open file \"%s\" for writing\n", filename);
			return RC_FAILED;
		}
		
		save_long_path_recursive(f, design->saved_path->final_pathelement);
		fprintf(f, "complete_saved_path	%s\n", design->saved_path->destination_inport->instance->get_name());

		fclose(f);
	}		

	return RC_NOMINAL;
}

rc_t
time_saved_path()
{
	printf(".... recompute the saved path .... see also print_saved_path \n");

 	if (design == NULL) {
 		printf("speedy has no design loaded\n");
 		return RC_FAILED;
 	}  
 
	PATH *path = design->saved_path;
 	if (path == NULL) {
 		printf("no saved path established\n");
 		return RC_NOTFOUND;
 	}

	path->compute_complete_path();
	print_path(design->saved_path, stdout);
 	return RC_NOMINAL;
}

rc_t
timing_do_something(BOOLEAN executing_command_file, char *cmd, char *arg1, char *arg2, char *arg3, char *arg4)
{
	if (strcmp(cmd, "flag_net_as_clock") == 0) {
		return flag_net_as_clock(arg1);
	}

	if (strcmp(cmd, "set_input_delay") == 0) {
		return set_input_delay(arg1, arg2);
	}

	if (strcmp(cmd, "set_input_driver") == 0) {
		return set_input_driver(arg1, arg2);
	}

	if (strcmp(cmd, "set_input_slope") == 0) {
		return set_input_slope(arg1, arg2);
	}

	if (strcmp(cmd, "set_output_load") == 0) {
		return set_output_load(arg1, arg2);
	}

	if (strcmp(cmd, "set_output_setup") == 0) {
		return set_output_setup(arg1, arg2);
	}



	if (strcmp(cmd, "global_timing") == 0) {
		return global_timing();
	}



	if (strcmp(cmd, "write_slow_nodes_file") == 0) {
		return write_slow_nodes_file(arg1, arg2);
	}

	if (strcmp(cmd, "write_long_paths_file") == 0) {
		return write_long_paths_file(arg1, arg2);
	}




	///////////////////////////////////////////
	// saved path feature

	if (strcmp(cmd, "create_saved_path") == 0) {
		return create_saved_path(arg1, arg2);
	}

	if (strcmp(cmd, "save_long_path") == 0) {
		return save_long_path(arg1);
	}

	if (strcmp(cmd, "add_to_saved_path") == 0) {
		return add_to_saved_path(arg1, arg2);
	}

	if (strcmp(cmd, "complete_saved_path") == 0) {
		return complete_saved_path(arg1);
	}

	if (strcmp(cmd, "time_saved_path") == 0) {
		return time_saved_path();

	}

	if (strcmp(cmd, "print_saved_path") == 0) {
		// ... user should say "print saved_path", but leave us not be fussy
		return print_saved_path();
	}



	///////////////////////////////////////////
	// access to helpers

	if (strcmp(cmd, "compute_net_characteristics") == 0) {
		return compute_net_characteristics();
	}


	///////////////////////////////////////////
	// are these access to helpers, or are they obsolete??

	if (strcmp(cmd, "write_timing_out_file") == 0) {
		return write_timing_out_file(arg1);
	}

	return RC_NOTFOUND;
}

