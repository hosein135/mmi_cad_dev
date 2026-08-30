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

PATH::PATH(INPORT *arg_destination_inport, PATHELEMENT *arg_final_pathelement)
	: destination_inport(arg_destination_inport),
	setup_delay(-1.0), absolute_delay(-1.0),
	final_pathelement(arg_final_pathelement)
{
}

PATH::PATH(OUTPORT *arg_outport, BOOLEAN arg_rising)
	: destination_inport(NULL),
	setup_delay(-1.0), absolute_delay(-1.0)
{
	final_pathelement = new PATHELEMENT(arg_outport, arg_rising);
	if (arg_rising == true)		final_pathelement->update_from(arg_outport->rising_long_path);
	else				final_pathelement->update_from(arg_outport->falling_long_path);
}

PATH::PATH(PATH &arg_path)
	: destination_inport(arg_path.destination_inport),
	setup_delay(arg_path.setup_delay),
	absolute_delay(arg_path.absolute_delay)
{
	PATHELEMENT *arg_pe = arg_path.final_pathelement;
	PATHELEMENT *my_pe = new PATHELEMENT(*arg_pe);
	final_pathelement = my_pe;
	while (arg_pe->previous != NULL) {
		arg_pe = arg_pe->previous;
		my_pe->previous = new PATHELEMENT(*arg_pe);
		my_pe = my_pe->previous;
	}	
}	

PATH::~PATH()
{
	// normally the path's pathelements belong to outports
	// he who is dealing with a copy path must delete the
	// pathelements manually before deleteing the path
}

float
PATH::compute_final_timing()
{
	if (destination_inport == NULL			||
	    destination_inport->inpin == NULL		||
	    destination_inport->inpin->inpintiming == NULL	) {
		setup_delay = 0.0;
		absolute_delay = final_pathelement->absolute_delay + destination_inport->net_delay;
		return absolute_delay;
	}

	INPINTIMING *inpintiming = destination_inport->inpin->inpintiming;

	switch (destination_inport->instance->type) {
	    case INSTANCE_INSTANCETYPE:
		if (final_pathelement->rising_at_outport == true) {
			setup_delay = inpintiming->setup_rise->lookup(target_slope, final_pathelement->slope_at_outport);
		}
		else {
			setup_delay = inpintiming->setup_fall->lookup(target_slope, final_pathelement->slope_at_outport);
		}
		break;

	    case OUTPUT_EXTCONN_INSTANCETYPE: {
		EXTCONN *extconn = (EXTCONN *)destination_inport->instance;
		setup_delay = extconn->delay;
	    }	break;

	    case INPUT_EXTCONN_INSTANCETYPE:
		printf("ERROR: path terminates at an input???\n");
		setup_delay = 0.0;
		break;
	}

	absolute_delay = final_pathelement->absolute_delay + destination_inport->net_delay + setup_delay;
	return absolute_delay;
}

float
PATH::compute_complete_path()
{
	final_pathelement->compute_complete_path();
	compute_final_timing();	
	return absolute_delay;
}


BOOLEAN
PATH::is_same_path(PATH *arg_path)
{
	if (destination_inport != arg_path->destination_inport) {
		return false;
	}

	return final_pathelement->is_same_path(arg_path->final_pathelement);
}


void
PATH::print_like_pearl(FILE *f) 
{
	if (use_rc_net_delay == true) {
		fprintf(f,	"cume-d	gate-d	load	slope	net-d	net-name	driver-name\n");
	} 
	else {
		fprintf(f,	"cume-d	gate-d	load	slope	net-name	driver-name\n");
	}

	if (final_pathelement != NULL) {
		final_pathelement->print_like_pearl(f);
	}

	char net_delay_str[0x100];
	if (use_rc_net_delay == true) {
		sprintf(net_delay_str, "%.0fps	", destination_inport->net_delay * 1000.0);
	} 
	else	net_delay_str[0] = '\0';

	if (destination_inport->instance->cell->type == CELLTYPE_EXTCONN) {
		fprintf(f, "%.0fps				  %s%.0fps	%s	<external>\n", 
		    absolute_delay * 1000.0, 
		    net_delay_str,
		    setup_delay * 1000.0, 
		    destination_inport->net->get_name());
	} else {  		
		fprintf(f, "%.0fps				  %s%.0fps	%s	%s\n", 
		    absolute_delay * 1000.0, 
		    net_delay_str,
		    setup_delay * 1000.0, 
		    destination_inport->instance->get_name(),
		    destination_inport->instance->cell->name);
	}
}

void
PATHELEMENT::print_like_pearl(FILE *f) 
{
	char net_delay_str[0x100];
	char rise_or_fall;
	if (rising_at_outport == true)	rise_or_fall = '^';
	else				rise_or_fall = 'v';

	if (previous != NULL) 	previous->print_like_pearl(f);
	else {
		if (use_rc_net_delay == true)	strcpy(net_delay_str, "\t");
		else				net_delay_str[0] = '\0';

		fprintf(f, "0.0ps		%.1ffF	%.0fps	%c %s%s\n", 
		    outport->load_capacitance * 1000.0,
		    slope_at_outport * 1000.0,
		    rise_or_fall,
		    net_delay_str,
		    outport->net->get_name());

		return;
	}

	if (use_rc_net_delay == true	&&
	    previous != NULL		) {

		// For compatibility with Pearl output, we print the net delay
		// from the previous stage here, although that's wierd.
		// ... I can't do it in previous->print() because I don't know
		// which input is interesting.

		printf("%.0fps				  %.0fps	%s\n",
		    (absolute_delay - gate_delay) * 1000.0,	// .... what I really mean is the 
								// PREVIOUS absolute_delay + net_delay
		    inport->net_delay * 1000.0, 
		    inport->net->get_name());
		strcpy(net_delay_str, "\t");
	} 
	else	net_delay_str[0] = '\0';

	if (outport->instance->cell->type == CELLTYPE_EXTCONN) {
		fprintf(f, "%.0fps	%.0fps	%.1ffF	%.0fps	%c %s%s	%s	%s\n", 
		    absolute_delay * 1000.0, 
		    gate_delay * 1000.0, 
		    outport->load_capacitance * 1000.0,
		    slope_at_outport * 1000.0,
		    rise_or_fall,
		    net_delay_str,
		    outport->net->get_name(),
		    outport->outpin->name,
		    "<external>");
	} else {  		
		fprintf(f, "%.0fps	%.0fps	%.1ffF	%.0fps	%c %s%s	%s	%s\n", 
		    absolute_delay * 1000.0, 
		    gate_delay * 1000.0, 
		    outport->load_capacitance * 1000.0,
		    slope_at_outport * 1000.0,
		    rise_or_fall,
		    net_delay_str,
		    outport->net->get_name(),
		    outport->instance->get_name(),
		    outport->instance->cell->name);
	}
	return;
}


rc_t
PATH::write_to_file(FILE *f)
{
	if (final_pathelement != NULL) {
		final_pathelement->write_to_file(f);
	} else {
		fprintf(f, "ERROR: no pathelement in path???\n");
		return RC_FAILED;
	}

	//////////
	// final_pathelement gives IGON;
	// PATH adds IG.

	INSTANCE *instance = destination_inport->instance;
	float inport_abs_delay;
	if (final_pathelement == NULL) {
		inport_abs_delay = 0.0;
	} else {
		inport_abs_delay = final_pathelement->absolute_delay + destination_inport->net_delay;
	}

	fprintf(f, "I	%s	%.3f\n", destination_inport->inpin->name, inport_abs_delay);	

	NET *final_net = destination_inport->net;
	char rise_or_fall;
	if (final_pathelement->rising_at_outport == true)	rise_or_fall = '^';
	else							rise_or_fall = 'v';
	fprintf(f, "N	%s	%c	%.3f\n", final_net->get_name(), rise_or_fall, destination_inport->net_delay);

	fprintf(f, "G	%s	%s	%.3f\n", instance->get_name(), instance->cell->name, this->setup_delay);	

	return RC_NOMINAL;
}

rc_t
PATHELEMENT::write_to_file(FILE *f) 
{
	// ...recursive
	if (previous != NULL) 	previous->write_to_file(f);

	INSTANCE *instance = outport->instance;

	// termination case, that is, the origin of the PATH
	if (inport == NULL	||
	    previous == NULL	) {
		fprintf(f, "G	%s	%s	%.3f\n", instance->get_name(), instance->cell->name, gate_delay);	
		fprintf(f, "O	%s	%.3f\n", outport->outpin->name, absolute_delay);	
		return RC_NOMINAL;
	}
		
	// ... else

	// leftover business from previous pe, where I knew the NET but not which INPORT, therefore not net_delay
	NET *previous_net = previous->outport->net;
	char rise_or_fall;
	if (previous->rising_at_outport == true)	rise_or_fall = '^';
	else						rise_or_fall = 'v';

	fprintf(f, "N	%s	%c	%.3f\n", previous_net->get_name(), rise_or_fall, inport->net_delay);

	// and from this PE....
	float inport_abs_delay = previous->absolute_delay + inport->net_delay;

	fprintf(f, "I	%s	%.3f\n", inport->inpin->name, inport_abs_delay);	
	fprintf(f, "G	%s	%s	%.3f\n", instance->get_name(), instance->cell->name, gate_delay);	
	fprintf(f, "O	%s	%.3f\n", outport->outpin->name, absolute_delay);	

	return RC_NOMINAL;
}

//////////////////////////////////////

PATHELEMENT::PATHELEMENT(OUTPORT *arg_outport, BOOLEAN arg_rising_at_outport)
	: outport(arg_outport), inport(NULL), outpintiming(NULL),
	rising_at_outport(arg_rising_at_outport), 
	previous(NULL),
	slope_at_outport(-1.0),
	gate_delay(0.0), absolute_delay(0.0)
{
}

PATHELEMENT::PATHELEMENT(OUTPORT *arg_outport, INPORT *arg_inport, OUTPINTIMING *arg_outpintiming)
	: outport(arg_outport), inport(arg_inport), outpintiming(arg_outpintiming),
	rising_at_outport(-1), 
	previous(NULL),
	slope_at_outport(-1.0),
	gate_delay(0.0), absolute_delay(0.0)
{
}


PATHELEMENT::~PATHELEMENT() 
{
}

BOOLEAN
PATHELEMENT::compute_timing()
{
	OUTPIN *outpin = outport->outpin;
	INPIN *inpin = inport->inpin;

	if (outpintiming->outpin != outpin		||
	    outpintiming->related_inpin != inpin	) {

		// ... if cells have been changed, the inport & outport
		// pointers are still valid, but the outpintiming is different.
		// This comes up in optimize_path... it would be theological
		// to require the caller to get the right outpintiming, but
		// it isn't necessarily effiecient to have him locate the 
		// right pathelement.  So leave us just do it here.
		// .... make sure to keep the same sense.

		OUTPINTIMING_SENSE old_sense = outpintiming->sense;
		ListOfOUTPINTIMING *optl = outpin->outpintiminglist;
		while (optl != NULL) {
			outpintiming = optl->outpintiming;
			if (outpintiming->related_inpin == inpin	&&
			    outpintiming->sense == old_sense		) {
				break;
			}
			optl = optl->next;
		}
		if (optl == NULL) {
			printf("ERROR: no outpintiming exists for this arc\n");	
			return false;
		}
	}

	OUTPINTIMING_SENSE sense = outpintiming->sense;
	float	outport_load = outport->load_capacitance;
	float	net_delay = inport->net_delay;

	if (previous != NULL			&&
	    previous->slope_at_outport < 0.0)	{		
		// .... input net is constant 
		gate_delay = 0.0;
		slope_at_outport = -1.0;
		return true;
	}

	switch (outport->instance->type) {

	    case INSTANCE_INSTANCETYPE: 
		if (rising_at_outport == true) {
	
			if ((previous->rising_at_outport == true		&&
			      (sense == POSITIVE_SENSE || sense == RISING_EDGE)	)	||
			    (previous->rising_at_outport == false		&&
			      (sense == NEGATIVE_SENSE || sense == FALLING_EDGE))	) {
	
				gate_delay = outpintiming->get_rising_delay(
				    outport_load, previous->slope_at_outport);
				slope_at_outport = outpintiming->get_rising_slope(
				    outport_load, previous->slope_at_outport);
			}
			else {
				return false;
			}	
		}
		else {
			if ((previous->rising_at_outport == true		&&
			      (sense == NEGATIVE_SENSE || sense == RISING_EDGE))	||
			    (previous->rising_at_outport == false		&&
			      (sense == POSITIVE_SENSE || sense == FALLING_EDGE)	)	) {
	
				gate_delay = outpintiming->get_falling_delay(
				    outport_load, previous->slope_at_outport);
				slope_at_outport = outpintiming->get_falling_slope(
				    outport_load, previous->slope_at_outport);
			}
			else {
				return false;
			}	
		}
		absolute_delay = previous->absolute_delay + net_delay + gate_delay;
		break;
	
	    case INPUT_EXTCONN_INSTANCETYPE: {
		EXTCONN *extconn = (EXTCONN *)outport->instance;
		absolute_delay = extconn->delay;
	    }	break;

	    case OUTPUT_EXTCONN_INSTANCETYPE:
		printf("ERROR: path originates at output???\n");
		absolute_delay = 0.0;
		break;
	}

	// ... we DID compute some valid numbers ...
	return true;
}

rc_t
PATHELEMENT::compute_complete_path()
{
	// ... recurse to start at the origin
	if (previous != NULL) {
		previous->compute_complete_path();
	}
	else {
		if (outport->instance->type == OUTPUT_EXTCONN_INSTANCETYPE) {
			EXTCONN *extconn = (EXTCONN *)outport->instance;
			absolute_delay = extconn->delay;
		} else	absolute_delay = 0.0;
					
		return RC_NOMINAL;
	}

	BOOLEAN rv = this->compute_timing();
	if (rv != true) {
		printf("ERROR: PATHELEMENT::compute_complete_path failed??? pe at 0x%x\n", (unsigned int)this);
		return RC_FAILED;
	}
	return RC_NOMINAL;
}

void
PATHELEMENT::clear()
{
	inport = NULL;
	outpintiming = NULL;
	slope_at_outport = -1.0;
	previous = NULL;
	gate_delay = -1.0;
	absolute_delay = -1.0;
}

void
PATHELEMENT::update_from(PATHELEMENT *arg_pe)
{
	inport = arg_pe->inport;
	outport = arg_pe->outport;
	outpintiming = arg_pe->outpintiming;
	slope_at_outport = arg_pe->slope_at_outport;
	previous = arg_pe->previous;
	gate_delay = arg_pe->gate_delay;
	absolute_delay = arg_pe->absolute_delay;
}	

BOOLEAN
PATHELEMENT::is_same_path(PATHELEMENT *arg_pe)
{
	if (outport != arg_pe->outport) {
		return false;
	}
	if (previous == NULL) {
		if (arg_pe->previous == NULL)	return true;
		else				return false;
	}

	return previous->is_same_path(arg_pe->previous);
}


//////////////////////////////////////

ListOfPATH::ListOfPATH(PATH *arg_path, ListOfPATH *arg_next)
    : path(arg_path), next(arg_next)
{
}

ListOfPATH::ListOfPATH(ListOfPATH &argpl)
{
	ListOfPATH *pl = &argpl;
	this->path = new PATH(*(pl->path));
	pl = pl->next;

	ListOfPATH *copypl = this;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		PATH *copy_path = new PATH(*path);
		copypl->next = new ListOfPATH(copy_path, NULL);
		copypl = copypl->next;		
	}
}

ListOfPATH::~ListOfPATH() 
{
	if (next)	delete next;
}


ListOfPATHELEMENT::ListOfPATHELEMENT(PATHELEMENT *arg_pathelement, ListOfPATHELEMENT *arg_next)
    : pathelement(arg_pathelement), next(arg_next) 
{
}

ListOfPATHELEMENT::~ListOfPATHELEMENT() {
	if (next)	delete next;
}

//////////////////////////////////////

DOWNSTREAM::DOWNSTREAM()
	: root_instancelist(NULL), 
	pathlist(NULL),
	long_delay(-FLT_MAX), long_path(NULL),
	ds_paths_are_clear(false)
{
	instancearray_max = design->n_instances;
	instancearray = new (INSTANCE *)[instancearray_max + 2];
	instancearray_topindex = 0;
}

DOWNSTREAM::~DOWNSTREAM()
{
	if (instancearray != NULL)	delete[] instancearray;
	if (pathlist != NULL)		delete pathlist;
}

void
DOWNSTREAM::init()
{
	// if (root_instancelist != NULL) {
	// 	delete root_instancelist;
	// 	root_instancelist = NULL;
	// }

	// .... this is for re-initializeing ....
	if (instancearray_topindex != 0) {
		clean_instances();
	}

	instancearray_topindex = 0;
	instancearray[0] = 0;
	instancearray[1] = 0;

	if (pathlist != NULL) {
		delete pathlist;
		pathlist = NULL;
	}
}	

rc_t
DOWNSTREAM::get_downstream_instances(ListOfINSTANCE *arg_root_instancelist)
{
	if (instancearray_topindex != 0) {
		printf("ERROR: get_downstream_instances when not initialized\n");
		return RC_INVALID;
	}
	root_instancelist = arg_root_instancelist;

	ListOfINSTANCE *il = root_instancelist;
	while (il != NULL) {

		INSTANCE *instance = il->instance;
		il = il->next;

		if (instance == fave_instance) {
			printf("fave_instance get_downstream_instance\n");
		}
		
		ListOfOUTPORT *opl = instance->outportlist;
		while (opl != NULL) {
			NET *net = opl->outport->net;
			opl = opl->next;

			if (net == NULL)	continue;
			if (net == fave_net) {
				printf("fave_net get_downstream_instance\n");
			}

			if (net->global_value == NOT_GLOBAL	||
			    net->global_value == GLOBAL_CLOCK	) {
				// ... clock drivers are root instances for global_downstream
				ListOfINPORT *ipl = net->inportlist;
				while (ipl != NULL) {
					INPORT *inport = ipl->inport;
					ipl = ipl->next;

					get_downstream_instances(inport);					
				}
			}
		}
	}

	instancearray[instancearray_topindex + 1] = NULL;	// don't bump counter	
	clean_instances();	// clear the INSTANCE::did_this_one's that we touched
			// NOTE: for debugging it was kind of fun to keep the flags,
			// since they actually give the sequence timing will be done.
			// But they have to be cleared before get_downstream_instances
			// gets redone.  
				
	return RC_NOMINAL;
}

BOOLEAN
DOWNSTREAM::get_downstream_instances(INPORT *inport)
{
	if (inport->net == NULL)	return false;

	INSTANCE *instance = inport->instance;
	if (instance == fave_instance) {
		printf("fave_instance get_downstream_instances\n");
	}

	// if this is an external outport this is the end of a path
	if (instance->cell->type == CELLTYPE_EXTCONN) {

		PATH *path = new PATH(inport, inport->net->source->rising_ds_path);
		pathlist = new ListOfPATH(path, pathlist);
		path = new PATH(inport, inport->net->source->falling_ds_path);
		pathlist = new ListOfPATH(path, pathlist);
		return true;
	}

	// next look for timing arcs through this inport
	//	... if there are no paths from here, maybe we did this one already,
	//	we can't tell, so we will walk this subtree again.  But if we mark
	//	the instance without putting it in the instancearray, we won't
	//	clear it later.  So take the (small) hit....
	//	... but mark it to look for circular paths....
	if (instance->did_this_one != 0)	{
		if (instance->did_this_one == -1) {
			printf("circular path through \"%s:%s\" broken here\n", instance->get_name(), inport->inpin->name);
			printf("....mark net \"%s\" as constant (horrible hack)\n", inport->net->get_name());
			inport->net->global_value = GLOBAL_CYCLEBREAKER;
		}
		return true;
	}
	instance->did_this_one = -1;

	BOOLEAN found_one = false;
	ListOfOUTPINTIMING *optl = inport->inpin->outpintiminglist;
	while (optl != NULL) {
		OUTPIN *outpin = optl->outpintiming->outpin;
		optl = optl->next;

		// don't do clock drivers
		// ... this is because clock drivers are root instances of global_downstream
		// (I am suspecting this is a bad thing...)
		OUTPORT *outport;
		ListOfOUTPORT *opl = instance->outportlist;
		while (opl != NULL) {
			outport = opl->outport;
			opl = opl->next;
	
			if (outport->net == NULL)	continue;
			if (outport->net->global_value == GLOBAL_CLOCK) {
				instance->did_this_one = 0;
				return false;
			}								
		}

		opl = instance->outportlist;
		while (opl != NULL) {
			outport = opl->outport;
			opl = opl->next;

			if (outport->net == NULL)	continue;

			if (outport->outpin == outpin) {
				if (instance == fave_instance) {
					printf("fave_instance get_downstream_instances2\n");
				}

				if (outport->net == NULL)	break;

				if (outport->net->global_value == NOT_GLOBAL) {
					ListOfINPORT *ipl = outport->net->inportlist;
					while (ipl != NULL) {
						INPORT *next_stage_inport = ipl->inport;
						ipl = ipl->next;
	
						BOOLEAN found_one_downstream = get_downstream_instances(next_stage_inport);
						if (found_one_downstream == true)	found_one = true; 
					}
				}
				break;	// don't search the rest of the outpins, we found it already
			}
		}
	}

	// if this pin has an inpintiming, then it is the end of a path....
	// but it might also carry on from here through a timing arc,
	// so it's a good thing we checked for that first.
	if (inport->inpin->inpintiming != NULL) {
		PATH *path = new PATH(inport, inport->net->source->rising_ds_path);
		pathlist = new ListOfPATH(path, pathlist);
		path = new PATH(inport, inport->net->source->falling_ds_path);
		pathlist = new ListOfPATH(path, pathlist);
		found_one = true;
	}

	// ... if there aren't any downstream instances, this guy isn't interesting either
	if (found_one == false)	{
		instance->did_this_one = 0;
		return false;
	}

	// ... notice that current instance is on the instancearray
	// above all its descendents (more positive index)

	instancearray[++instancearray_topindex] = instance;
	instance->did_this_one = instancearray_topindex;

	ListOfOUTPORT *opl = instance->outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		outport->rising_ds_path->absolute_delay = -FLT_MAX;
		outport->falling_ds_path->absolute_delay = -FLT_MAX;
	}
	return true;
}

void
DOWNSTREAM::clean_instances()
{
	INSTANCE **instance_ap = instancearray;
	while (*(++instance_ap) != NULL) {
		(*instance_ap)->did_this_one = 0;
		ListOfOUTPORT *opl = (*instance_ap)->outportlist;
		while (opl != NULL) {
			OUTPORT *outport = opl->outport;
			opl = opl->next;
	
			outport->rising_ds_path->clear();
			outport->falling_ds_path->clear();
		}
	}
}

rc_t
DOWNSTREAM::compute_timing()
{
	// update the root instances from the global timing
	ListOfINSTANCE *il = root_instancelist;
	while (il != NULL) {
		INSTANCE *root_instance = il->instance;
		il = il->next;

		ListOfOUTPORT *opl = root_instance->outportlist;
		while (opl != NULL) {
			OUTPORT *outport = opl->outport;
			opl = opl->next;
	
			outport->rising_ds_path->update_from(outport->rising_long_path);
			outport->falling_ds_path->update_from(outport->falling_long_path);
		}		
	}

	// do instances in reverse order from instancearray
	INSTANCE **ia = &instancearray[instancearray_topindex];
	while (*ia != NULL) {
		INSTANCE *instance = *(ia--);
		rc_t rc = instance->ds_timing();
		if (rc != RC_NOMINAL)	return rc;
	}

	// .... now walk the terminals ....
	ListOfPATH *pl = pathlist;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		path->compute_final_timing();
	}

	return RC_NOMINAL;
}

rc_t
DOWNSTREAM::compute_global_timing()
{
	// ... update the "long_pathelement"s in all the outports of all the instances
	// ... because instancearray is a nice ordering, this is a purely local operation.
	// do instances in reverse order from instancearray
	INSTANCE **ia = &instancearray[instancearray_topindex];
	while (*ia != NULL) {
		INSTANCE *instance = *(ia--);
		rc_t rc = instance->ds_global_timing();
		if (rc != RC_NOMINAL)	return rc;
	}

	// ... setup delays are on inputs, not outputs
	// ... so walk the "destination_inports" and apply all the INPINTIMINGs...
	
	ListOfPATH *pl = pathlist;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		path->compute_final_timing();
	}

	return RC_NOMINAL;
}

ListOfPATHELEMENT *
DOWNSTREAM::get_slow_nodes()
{
	ListOfPATHELEMENT *return_pelist = NULL;

	int index = 1;
	INSTANCE **ia = &instancearray[1];
	while (*ia != NULL) {
		INSTANCE *instance = *(ia++);
		index++;

		ListOfOUTPORT *opl = instance->outportlist;
		while (opl != NULL) {
			OUTPORT *outport = opl->outport;
			opl = opl->next;

			if (outport->rising_long_path->slope_at_outport > maximum_desireable_slope) {
				return_pelist = new ListOfPATHELEMENT(outport->rising_long_path, return_pelist);
			} 
			if (outport->falling_long_path->slope_at_outport > maximum_desireable_slope) {
				return_pelist = new ListOfPATHELEMENT(outport->rising_long_path, return_pelist);
			} 
		}
	}

	return return_pelist;
}

float 
DOWNSTREAM::get_long_delay()
{
	long_delay = -FLT_MAX;	
	long_path = NULL;

	ListOfPATH *pl = pathlist;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		if (path->absolute_delay > long_delay) {
			long_path = path;
			long_delay = path->absolute_delay;
		}
	}
	
	return long_delay;
}

ListOfPATH *
DOWNSTREAM::get_long_pathlist(int maxpossibilities)
{
	float short_long_delay = -FLT_MAX;
	ListOfPATH *returnlist = NULL;

	ListOfPATH *pl = pathlist;
	if (pl == NULL)		return NULL;

	returnlist = new ListOfPATH(pl->path, NULL);
	pl = pl->next;	

	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		if (path->absolute_delay > returnlist->path->absolute_delay) {
			returnlist = new ListOfPATH(path, returnlist);
			continue;
		}

		if (path->absolute_delay > short_long_delay) {
			int ix = 0;
			ListOfPATH *pl2 = returnlist;	// we know returnlist != NULL
			while (1) {
				if (pl2->next == NULL) {
					pl2->next = new ListOfPATH(path, NULL);
					break;
				}
				if (ix++ > maxpossibilities) {
					// too slow, Joe! 
					short_long_delay = pl2->path->absolute_delay;
					break;
				}
				if (path->absolute_delay > pl2->next->path->absolute_delay) {
					pl2->next = new ListOfPATH(path, pl2->next);
					break;
				}

				pl2 = pl2->next;
			}
		}
	}

	return returnlist;	// might be longer than maxpossibilites, but nobody cares...
}


rc_t
DOWNSTREAM::compute_timing_and_update_long_path()
{
	// ... this is for downsize_for_area ...
	// presumably we have changed the root instance cells,
	// so we need to go back to their precursors and start
	// from there

	ListOfINSTANCE *il = root_instancelist;
	while (il != NULL) {
		INSTANCE *root_instance = il->instance;
		il = il->next;

		ListOfINPORT *ipl = root_instance->inportlist;
		while (ipl != NULL) {
			INPORT *precursor_inport = ipl->inport;
			ipl = ipl->next;

			if (precursor_inport->net == NULL)			continue;
			if (precursor_inport->net->global_value	!= NOT_GLOBAL)	continue;

			INSTANCE *precursor_instance = precursor_inport->net->source->instance;
			if (precursor_instance == NULL)	continue;	// extconn

			ListOfINPORT *precursor_ipl = precursor_instance->inportlist;
			while (precursor_ipl != NULL) {
				INPORT *way_back_there_inport = precursor_ipl->inport;
				precursor_ipl = precursor_ipl->next;

				if (way_back_there_inport->net == NULL)				continue;
				if (way_back_there_inport->net->global_value != NOT_GLOBAL)	continue;

				OUTPORT *way_back_there_outport = way_back_there_inport->net->source;
				way_back_there_outport->rising_ds_path->update_from(way_back_there_outport->rising_long_path);
				way_back_there_outport->falling_ds_path->update_from(way_back_there_outport->falling_long_path);
			}
			
			precursor_instance->ds_timing_and_update_long_path();
		}
		root_instance->ds_timing_and_update_long_path();
	}

	// do instances in reverse order from instancearray
	INSTANCE **ia = &instancearray[instancearray_topindex];
	while (*ia != NULL) {
		INSTANCE *instance = *(ia--);
		rc_t rc = instance->ds_timing_and_update_long_path();
		if (rc != RC_NOMINAL)	return rc;
	}

	// .... now walk the terminals ....
	ListOfPATH *pl = pathlist;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		path->compute_final_timing();
	}

	return RC_NOMINAL;
}


void
DOWNSTREAM::find_instance(char *arg_name)
{
	int counter = 0;
	int index = 1;
	INSTANCE **ia = &instancearray[1];
	while (*ia != NULL) {
		INSTANCE *instance = *(ia++);
		if (strcmp(arg_name, instance->get_name()) == 0) {
			printf("instance \"%s\" at instancearray[%d]\n", instance->get_name(), index);
		}
		index++;
	}
	if (counter == 0) {
		printf("instance \"%s\" NOT FOUND\n", arg_name);
	} 
	else if (counter > 1) {
		printf("ERROR: instance \"%s\" found multiple times!!\n", arg_name);
	}
}

void
DOWNSTREAM::print_instance(int index)
{
	if (index < 1				||
	    index > instancearray_max	) {
		printf("index out of range (1:%x)\n", instancearray_max);
		return;
	}
	if (index > instancearray_topindex) {
		printf("index greater than top (%x)\n", instancearray_topindex);
		return;
	}
	printf("index %d instance %s\n", index, instancearray[index]->get_name());
}

rc_t
INSTANCE::ds_timing()
{
	// ... see also ds_global_timing below ... duplicated code ...
	if (this == fave_instance) {
		printf("fave_instance ds_timing\n");
	}

	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;
	
		outport->rising_ds_path->absolute_delay = -FLT_MAX;
		outport->falling_ds_path->absolute_delay = -FLT_MAX;
	}

	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		if (inport->net == NULL)	continue;
		NET *net = inport->net;

		// ... interesting timing arcs are only when inport net is not global,
		// or this is clock_to_Q arc ....
		if (cell->is_flipflop == true) {
			if (net->global_value != GLOBAL_CLOCK)	continue;
		}
		else {
			if (net->global_value != NOT_GLOBAL) continue;
		}

		if (net->source->rising_ds_path->absolute_delay < 0) {
			// ... if we're doing a partial tree, naturally this will happen
			continue;
		}
	
		ListOfOUTPINTIMING *optl = inport->inpin->outpintiminglist;
		while (optl != NULL) {
			OUTPINTIMING *outpintiming = optl->outpintiming;
			optl = optl->next;

			OUTPORT *outport;
			ListOfOUTPORT *opl = outportlist;
			BOOLEAN found_one = false;
			while (opl != NULL) {
				outport = opl->outport;
				opl = opl->next;

				if (outport->outpin == outpintiming->outpin) {
					found_one = true;

					PATHELEMENT new_pe(outport, inport, outpintiming);
					// rising from rising
					new_pe.previous = net->source->rising_ds_path;
					new_pe.rising_at_outport = true;
					if (new_pe.compute_timing() == true) {
						if (new_pe.absolute_delay > outport->rising_ds_path->absolute_delay) {
							outport->rising_ds_path->update_from(&new_pe);
						}
					}
					else {
					// rising from falling
						new_pe.previous = net->source->falling_ds_path;
						if (new_pe.compute_timing() == true					&&
						    new_pe.absolute_delay > outport->rising_ds_path->absolute_delay	) {
							outport->rising_ds_path->update_from(&new_pe);
						}
					}
			
					// falling from rising
					new_pe.previous = net->source->rising_ds_path;
					new_pe.rising_at_outport = false;
					if (new_pe.compute_timing() == true) {
						if (new_pe.absolute_delay > outport->falling_ds_path->absolute_delay) {
							outport->falling_ds_path->update_from(&new_pe);
						}
					}
					else {
					// falling from falling
						new_pe.previous = net->source->falling_ds_path;
						if (new_pe.compute_timing() == true					&&
						    new_pe.absolute_delay > outport->falling_ds_path->absolute_delay	) {
							outport->falling_ds_path->update_from(&new_pe);
						}
					}
				}
			}
			if (found_one == false) {
				printf("ERROR: can't find outport for outpintiming??? instance 0x%x\n", (unsigned int)this);
				continue;
			}				
		}
 	}

	return RC_NOMINAL;
}

rc_t
INSTANCE::ds_global_timing()
{
	// ... seriously annoying ...
	// this duplicates INSTANCE::ds_timing except that we are updateing
	// OUPORT::rising/falling_long_path[element] rather than ..._ds_path...

	if (this == fave_instance) {
		printf("fave_instance ds_global_timing\n");
	}

	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;
	
		outport->rising_long_path->absolute_delay = -FLT_MAX;
		outport->falling_long_path->absolute_delay = -FLT_MAX;
	}

	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		if (inport->net == NULL)	continue;
		NET *net = inport->net;

		// ... interesting timing arcs are only when ....
		// ... this is clock_to_Q arc ....
		if (cell->is_flipflop == true) {
			if (net->global_value != GLOBAL_CLOCK)	continue;
			// else	design->Q_count++;	// counting clock-to-Q arcs; not in ds_timing

			// clock phase is always zero
			net->source->rising_long_path->absolute_delay = 0.0;			
			net->source->falling_long_path->absolute_delay = 0.0;			
		}
		// ... or inport net is regular = "not global"
		else {
			if (net->global_value != NOT_GLOBAL) continue;
		}


		//	for each outport on this instance,
		//	there is a list of arcs terminating here; 
		//		for each arc,
		//			construct a trial pathelement;
		//			if delay is longer, update the outport long_pathelement
		//			(do for as many  "timings" (LUTABLEs) as there are in the arc)
		ListOfOUTPINTIMING *optl = inport->inpin->outpintiminglist;
		while (optl != NULL) {
			OUTPINTIMING *outpintiming = optl->outpintiming;
			optl = optl->next;

			OUTPORT *outport;
			ListOfOUTPORT *opl = outportlist;
			BOOLEAN found_one = false;
			while (opl != NULL) {
				outport = opl->outport;
				opl = opl->next;

				if (outport->outpin == outpintiming->outpin) {
					found_one = true;

					PATHELEMENT new_pe(outport, inport, outpintiming);
					// rising from rising
					new_pe.previous = net->source->rising_long_path;
					new_pe.rising_at_outport = true;
					if (new_pe.compute_timing() == true) {
						if (new_pe.absolute_delay > outport->rising_long_path->absolute_delay) {
							outport->rising_long_path->update_from(&new_pe);
						}
					}
					else {
					// rising from falling
						new_pe.previous = net->source->falling_long_path;
						if (new_pe.compute_timing() == true					&&
						    new_pe.absolute_delay > outport->rising_long_path->absolute_delay	) {
							outport->rising_long_path->update_from(&new_pe);
						}
					}
			
					// falling from rising
					new_pe.previous = net->source->rising_long_path;
					new_pe.rising_at_outport = false;
					if (new_pe.compute_timing() == true) {
						if (new_pe.absolute_delay > outport->falling_long_path->absolute_delay) {
							outport->falling_long_path->update_from(&new_pe);
						}
					}
					else {
					// falling from falling
						new_pe.previous = net->source->falling_long_path;
						if (new_pe.compute_timing() == true					&&
						    new_pe.absolute_delay > outport->falling_long_path->absolute_delay	) {
							outport->falling_long_path->update_from(&new_pe);
						}
					}
				}
			}
			if (found_one == false) {
				printf("ERROR: can't find outport for outpintiming??? instance 0x%x\n", (unsigned int)this);
				continue;
			}				
		}
 	}

	return RC_NOMINAL;
}

rc_t
INSTANCE::ds_timing_and_update_long_path()
{
	ds_timing();

	// if the original long path came from an input pin we have updated,
	// and the ds path is faster, then the long path gets shorter.  BUT
	// I can't just dial it down to the ds path, because there might be 
	// a path longer than the ds path (but shorter than the original long
	// path) on some other input pin which was not part of the ds tree.
	// So I have to just leave it.  That means that the delays are not
	// going to add up on the long path.  Do I care??? 
	// ... if I *do*, then I have to compute the timing over all the arcs.
	// Anyway, I better do a global_timing at the end.
	// ... ALSO, we haven't updated the PATHs ... that WILL be bad later ...

	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		PATHELEMENT *ds_pe = outport->rising_ds_path;
		PATHELEMENT *long_pe = outport->rising_long_path;
		if (ds_pe->absolute_delay > long_pe->absolute_delay) {
			long_pe->update_from(ds_pe);
			if (ds_pe->previous->rising_at_outport == true)	long_pe->previous = ds_pe->previous->outport->rising_long_path;
			else						long_pe->previous = ds_pe->previous->outport->falling_long_path;
		}

		ds_pe = outport->falling_ds_path;
		long_pe = outport->falling_long_path;
		if (ds_pe->absolute_delay > long_pe->absolute_delay) {
			long_pe->update_from(ds_pe);
			if (ds_pe->previous->rising_at_outport == true)	long_pe->previous = ds_pe->previous->outport->rising_long_path;
			else						long_pe->previous = ds_pe->previous->outport->falling_long_path;
		}



	}
	return RC_NOMINAL;
}

