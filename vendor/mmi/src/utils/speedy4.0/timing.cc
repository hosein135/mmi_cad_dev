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

#include  "util.h"

rc_t
DESIGN::initialize_global_downstream()
{
	Q_count = 0;
	if (global_downstream == NULL) {
		global_downstream = new DOWNSTREAM();
	}
	global_downstream->init();

	// make sure clock slopes are set, and so forth
	// & get list of starting instances
	//	... which is EXTCONN inputs
	//	    and drivers of GLOBAL_CLOCK 
	ListOfINSTANCE *root_instancelist = NULL;
	ListOfNET *nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		if (net == fave_net) {
			printf("fave_net initialize_global_downstream\n");
		}
		// if (strcmp(fave_netname, net->get_name()) == 0) {
		// 	printf("fave_netname initialize_global_downstream\n");
		// }

		if (net->global_value != NOT_GLOBAL	&&
		    net->global_value != GLOBAL_CLOCK	) {
			continue;
		}

		if (net->source->instance->cell->type == CELLTYPE_EXTCONN) {
			root_instancelist = new ListOfINSTANCE(net->source->instance, root_instancelist);

			// ... if long_paths haven't been set by timing-in file, set them
			if (net->source->rising_long_path->slope_at_outport < 0) {
				net->source->rising_long_path->slope_at_outport = target_slope;
				net->source->falling_long_path->slope_at_outport = target_slope;
			}
		}	
		else if (net->global_value == GLOBAL_CLOCK) {
			// clock driver... if it's also an extconn we did it already
			INSTANCE *instance = net->source->instance;
			root_instancelist = new ListOfINSTANCE(instance, root_instancelist);

			net->source->rising_long_path->slope_at_outport = clock_slope;
			net->source->falling_long_path->slope_at_outport = clock_slope;
		} 
		else if (net->global_value == NOT_GLOBAL) {
			net->source->rising_long_path->clear();
			net->source->falling_long_path->clear();
		}

	}		
	if (root_instancelist == NULL) {
		printf("...can't find any root instances...\n");
		return RC_FAILED;
	}

	// ... orderize the design instancelist ...
	global_downstream->get_downstream_instances(root_instancelist);

	// annoyingly enough, get_downstream_instances leaves the 
	// downstream->paths->final_pathelement pointing at ...._ds_path,
	// whereas we need _long_path.  It's either duplicate the 
	// get_downstream_instances code, or fix it up here.... 

	ListOfPATH *pl = global_downstream->pathlist;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		OUTPORT *outport = path->final_pathelement->outport;
		if (path->final_pathelement->rising_at_outport == true) {
			path->final_pathelement = outport->rising_long_path;
		} else {
			path->final_pathelement = outport->falling_long_path;
		}
	}

	global_downstream->clean_instances();
	return RC_NOMINAL;
}	

rc_t
DESIGN::global_timing()
{
	if (global_downstream == NULL) {
		rc_t rc = complete_initialization();
		if (rc != RC_NOMINAL)	return rc;
	}
	global_downstream->compute_global_timing();
	global_downstream->get_long_delay();

	return RC_NOMINAL;
}

	
///////////////////////////////////////////////////////////

BOOLEAN header_is_printed = true;

rc_t
NET::estimate_tc_delay()
{
	if (this == fave_net) {
		printf("fave_net compute_net_delay\n");
	}
	if (source == NULL)	return RC_NOMINAL;

	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		inport->net_delay = 0.0;
	}

	if (global_value == GLOBAL_CLOCK)	return RC_NOMINAL;
	if (global_value != NOT_GLOBAL) {
		source->rising_long_path->clear();
		source->falling_long_path->clear();
		return RC_NOMINAL;
	}	

	if (source->segment != NULL	&&
	    use_rc_net_delay == true	) {

		SEGMENT *source_segment = source->segment;
		ListOfSEGMENT *sl = source_segment->segmentlist;
		if (use_rc_net_delay == true) {
			// "...source_segment->estimate_tc_delay(0.0); "
			// don't do above, since the delay of the internal resistor 
			// driving the total capacitive load is included in the lib tables

			sl = source_segment->segmentlist;
			while (sl != NULL) {
				SEGMENT *segment = sl->segment;
				sl = sl->next;
			
				segment->estimate_tc_delay(0.0);
			}
		}

		compute_tc_bounds();
		if (tau_P < fast_net_delay) {
			// don't worry, be happy
			return RC_NOMINAL;
		}

		float upper_check = tau_P * 0.9;
		ListOfINPORT *ipl = inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			float lower_check = inport->tau_Re * 1.10;
			if (inport->net_delay > lower_check	||
			    inport->net_delay < upper_check	) {

				if (header_is_printed == false) {
					printf("inports with loose bounds on estimated net delay:\n");
					printf("low bound	est delay	high bound	low %%	high %%	net name	inport name\n");

					header_is_printed = true;
				}
		
				float low_ratio = inport->tau_Re / inport->net_delay;
				float high_ratio = tau_P / inport->net_delay;
				if (inport->instance != NULL) {
					printf("%.6f	%.6f	%.6f	%.3f	%.3f	%s	%s:%s\n", 
					    inport->tau_Re, inport->net_delay, tau_P, low_ratio * 100.0, high_ratio * 100.0, 
					    name, inport->instance->get_name(), inport->inpin->name);
				} else {
					printf("%.6f	%.6f	%.6f	%.3f	%.3f	%s	(external) %s\n", 
					    inport->tau_Re, inport->net_delay, tau_P, low_ratio, high_ratio, 
					    name, inport->inpin->name);
				}
			}
		}
	}
	else {

		// no segmentization...
		// set net delay to zero

		ipl = inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			inport->net_delay = 0.0;
		}
	}

	return RC_NOMINAL;
}

void
SEGMENT::estimate_tc_delay(float delay_to_left_end)
{
	// nanoseconds = ohms * picofarads / 1000

	float segment_delay = resistance * downstream_capacitance / 1000.0;

	float delay_to_right_end = delay_to_left_end + segment_delay;
	right_end->net_delay = delay_to_right_end;

	ListOfSEGMENT *sl = segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;

		segment->estimate_tc_delay(delay_to_right_end);
	}
}

void
NET::compute_tc_bounds()
{
	// ... correct to agree with net delay 
	if (source->segment == NULL)	return;

	float delay_included_in_lib = source->segment->resistance * source->segment->downstream_capacitance / 1000.0;

	SEGMENT *source_segment = source->segment;
	tau_P = source_segment->compute_tc_bounds(0.0, 0.0, 0.0, delay_included_in_lib);
	tau_P -= delay_included_in_lib;
}

float
SEGMENT::compute_tc_bounds(float upstream_resistance, 
    float partial_tR, float up_r_squared, float delay_incl)
{
	float inclusive_resistance = upstream_resistance + resistance;
	float incl_r_squared = inclusive_resistance * inclusive_resistance;

	float tP = inclusive_resistance * capacitance / 1000.0;

	partial_tR -= up_r_squared * downstream_capacitance;	// correct previous stage
	partial_tR += incl_r_squared * downstream_capacitance;
	if (right_end->type == INPORT_TYPE) {
		INPORT *inport = (INPORT *)right_end;
		float tR = partial_tR / inclusive_resistance;
		tR /= 1000.0;
		tR -= delay_incl;
		inport->tau_Re = tR;
	}

	ListOfSEGMENT *sl = segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;

		tP += segment->compute_tc_bounds(inclusive_resistance, partial_tR, incl_r_squared, delay_incl);
	}
	
	return tP;
}

