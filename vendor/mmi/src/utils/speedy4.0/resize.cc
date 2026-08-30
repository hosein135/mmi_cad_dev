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

BOOLEAN resize_do_all = true;	// debugger switch
extern rc_t print_long_path();

rc_t
DESIGN::resize_instances_by_threshold()
{
	while (1) {
		int improved_count = 0;

		// do instances in frontwards order from instancearray
		INSTANCE **ia = &(global_downstream->instancearray[1]);
		while (*ia != NULL) {
			INSTANCE *instance = *(ia++);
			
			rc_t rc = instance->resize_by_threshold();
			if (rc == RC_IMPROVED) improved_count++;
		}
	
		if (improved_count == 0)	break;
	}

	return RC_NOMINAL;
}

rc_t
INSTANCE::resize_by_threshold()
{
	if (this == fave_instance) {
	    printf("fave_intance resize_by_threshold\n");
	}
	
	if (clone == NULL				||
	    clone->is_adjustable_for_size == false	) {
		// ...nope
		return RC_NOIMPROVEMENT;
	}

	// ... start with smallest cell of this functiongroup
	CELL *best_cell = cell->functiongroup->celllist->cell;

	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		CELL *try_cell;
		ListOfCELL *cl = cell->functiongroup->celllist;
		while (cl != NULL) {
			try_cell = cl->cell;

			if (try_cell->max_capacitance > outport->load_capacitance) {
				if (try_cell != best_cell		&&
				    try_cell->size > best_cell->size	) {
				 	best_cell = try_cell;
				}
				break;
			}

			cl = cl->next;
		}		
		if (cl == NULL) best_cell = try_cell;
	}

	if (cell == best_cell) {
		return RC_NOIMPROVEMENT;

	} else {
		change_cell(best_cell);
		return RC_IMPROVED;
	}

	return RC_NOMINAL; 
}

rc_t
DESIGN::resize_clones_by_threshold()
{
	while (1) {
		int improved_count = 0;
		ListOfCLONE *cl = clonelist;
		while (cl != NULL) {
			CLONE *clone = cl->clone;
			cl = cl->next;

			if (clone == fave_clone) {
				printf("fave_clone resize_clones_by_threshold\n");
			}

			if (clone->is_adjustable_for_size == false)	continue;
			if (clone->instancelist == NULL)		continue;

			INSTANCE *most_loaded_instance;
			float big_load;
			ListOfINSTANCE *il = clone->instancelist;
			while (il != NULL) {
				INSTANCE *instance = il->instance;
				il = il->next;
				
				if (instance->outportlist != NULL) {
					most_loaded_instance = instance;
					big_load = most_loaded_instance->outportlist->
					    outport->load_capacitance;
					break;
				}
			}	

			while (il != NULL) {
				INSTANCE *instance = il->instance;
				il = il->next;
			
				// ... there's a problem if instance has multiple
				// outports ... but let's not guild the lily...
				if (instance->outportlist->outport->load_capacitance > big_load) {
					most_loaded_instance = instance;
				}
			}

			rc_t rc = most_loaded_instance->resize_by_threshold();
			if (rc == RC_IMPROVED) {
				improved_count++;
				clone->change_cell(most_loaded_instance->cell);
			}
		}
	
		if (speedy_verbose == true) {
			printf("adjusting size: improved clones count %d\n", improved_count);	
		}
		if (improved_count == 0)	break;
	}

	return RC_NOMINAL;
}

rc_t
DESIGN::try_to_downsize_instances()
{
	int downsize_count = 0;
	ListOfINSTANCE *improved_list = NULL;	
	ListOfINSTANCE *til;

	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {

		INSTANCE *instance = il->instance;
		il = il->next;
		if (instance->cell == NULL)	continue;

		instance->saved_cell = instance->cell;

		rc_t rc = instance->try_downsize();
		if (rc == RC_IMPROVED	&& 
		    speedy_verbose == true	) {
			downsize_count++;
			improved_list = new ListOfINSTANCE(instance, improved_list);
		}
	}

	if (speedy_verbose == true) {
		printf("...downsized %d\n", downsize_count);
	
		printf("target of improvements counted (instances, not clones):\n");
		while (improved_list != NULL) {
	
			INSTANCE *instance = improved_list->instance;
			downsize_count = 1;
	
			ListOfINSTANCE *il = improved_list;
			while (il->next != NULL) {
				// got to save the list pointer so we can unlink the instance if it matches
				INSTANCE *next_instance = il->next->instance;
				if (next_instance->cell == instance->cell) {
					downsize_count++; 
	
					til = il->next;
					il->next = il->next->next;
					til->unlink_and_delete();
	
				} else	il = il->next;
			}
	
			printf("%i	%s\n", downsize_count, instance->cell->name);
	
			til = improved_list;
			improved_list = improved_list->next;
			til->unlink_and_delete();
		}
	}
	return RC_NOMINAL;
}

rc_t
INSTANCE::try_upsize()
{
	if (this == fave_instance) {
		printf("fave_instance try_upsize\n");
	}

	CELL *new_cell = cell->get_next_size_larger();
	if (new_cell == NULL)	return RC_NOIMPROVEMENT;
	
	float improvement = try_resize(new_cell);
	if (improvement > ::upsize_threshold) {
		change_cell(new_cell);
		return RC_IMPROVED;
	}

	return RC_NOIMPROVEMENT;
}
	
rc_t
INSTANCE::try_downsize()
{
	if (this == fave_instance) {
		printf("fave_instance try_downsize\n");
	}

	CELL *new_cell = cell->get_next_size_smaller();
	if (new_cell == NULL)	return RC_NOIMPROVEMENT;
	
	float improvement = try_resize(new_cell);
	if (improvement > ::downsize_threshold) {
		change_cell(new_cell);
		return RC_IMPROVED;
	}

	return RC_NOIMPROVEMENT;
}
	
float
INSTANCE::try_resize(CELL *new_cell)
{
	if (clone->is_adjustable_for_size == false)	return -FLT_MAX;

	// ... look at the 3-gate, or 3-pathelement, path,  
	// [ -> previous_stage -> this_stage -> next_stage -> ]
	// we can pick the previous_stage based on the long path to this, 
	// but just pick the load "nearest my thumb"

	PATHELEMENT *original_long_path = outportlist->outport->rising_long_path;
	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		if (outport->rising_long_path->absolute_delay > original_long_path->absolute_delay) {
			original_long_path = outport->rising_long_path;
		}
		if (outport->falling_long_path->absolute_delay > original_long_path->absolute_delay) {
			original_long_path = outport->falling_long_path;
		}
	}
	
	if (original_long_path->absolute_delay == 0) {
		// can't do better than that, ha ha!
		// ... this comes up when the instance is only driving global nets ...
		return -FLT_MAX;
	}		
	if (original_long_path->absolute_delay == -1		||
	    original_long_path->absolute_delay == -FLT_MAX	) {
		// ........ha ha! to you!!
		// ... this comes up when *driven* only by global nets (-1)
		// ... or a gate that doesn't show up in the global_downstream (-FLT_MAX)
		return -FLT_MAX;
	}		


	// ....... this stage (includes "this" instance) .....

	OUTPORT this_stage_outport(*original_long_path->outport);
	INPORT this_stage_inport(*original_long_path->inport);	
	PATHELEMENT this_stage(&this_stage_outport, &this_stage_inport, original_long_path->outpintiming);
	this_stage.rising_at_outport = original_long_path->rising_at_outport;

	if (this_stage_outport.net->inportlist == NULL) {
		// ... well, can't get 3 stages
		return -FLT_MAX;
	}


	// ....... previous stage .........

	OUTPORT previous_outport(*original_long_path->inport->net->source);
	if (previous_outport.instance->cell->type == CELLTYPE_EXTCONN) {
		// ... can't get 3 stages...
		// (don't want to resize first gates after extconn anyway)
		return -FLT_MAX;
	}

	OUTPINTIMING *previous_outpintiming = previous_outport.outpin->outpintiminglist->outpintiming;

	INPORT *previous_inport;
	ListOfINPORT *ipl = previous_outport.instance->inportlist;
	while (ipl != NULL) {
		previous_inport = ipl->inport;
		if (previous_inport->inpin == previous_outpintiming->related_inpin) break;
		ipl = ipl->next;
	}
	if (ipl == NULL) {
		printf("ERROR: can't find related inport\n");
		return -FLT_MAX;
	}

	// debug.....
	if (previous_inport->net == NULL) {
		printf("previous inport NULL instance %s\n", this->get_name());
	}


	PATHELEMENT previous_stage(&previous_outport, previous_inport, previous_outpintiming);
	this_stage.previous = &previous_stage;
	switch (this_stage.outpintiming->sense) {
	    case NEGATIVE_SENSE:
		if (this_stage.rising_at_outport == true) previous_stage.rising_at_outport = false;
		else					  previous_stage.rising_at_outport = true;
		break;
	    case POSITIVE_SENSE:
		previous_stage.rising_at_outport = this_stage.rising_at_outport;
		break;
	    default:
		// ... hope this_stage is sensible ...
		previous_stage.rising_at_outport = true;
	}

	// ....... origin stage .........

	PATHELEMENT origin(previous_stage.inport->net->source, NULL, NULL);
	previous_stage.previous = &origin;
	switch (previous_stage.outpintiming->sense) {
	    case NEGATIVE_SENSE:
		if (previous_stage.rising_at_outport == true) origin.rising_at_outport = false;
		else					  origin.rising_at_outport = true;
		break;
	    case POSITIVE_SENSE:
		origin.rising_at_outport = previous_stage.rising_at_outport;
		break;
	    case FALLING_EDGE: 
		origin.rising_at_outport = false;
		break;
	    case RISING_EDGE: 
		origin.rising_at_outport = true;
		break;

	    default:
		printf("INSTANCE::try_resize: unknown sense\n");
		return RC_FAILED;
	}


	if (origin.rising_at_outport == true) {
		origin.slope_at_outport = origin.outport->rising_long_path->slope_at_outport;
	}
	else {
		origin.slope_at_outport = origin.outport->falling_long_path->slope_at_outport;
	}


	// ....... next stage .........

	INPORT *next_stage_inport = this_stage_outport.net->inportlist->inport;
	if (next_stage_inport->instance->cell->type == CELLTYPE_EXTCONN			||
	    next_stage_inport->inpin->outpintiminglist == NULL	) {
		// ... more ways of not getting 3 stages
		return -FLT_MAX;
	}

	OUTPINTIMING *next_stage_outpintiming = next_stage_inport->inpin->outpintiminglist->outpintiming;

	OUTPORT *next_stage_outport;
	opl = next_stage_inport->instance->outportlist;
	while (opl != NULL) {
		next_stage_outport = opl->outport;
		if (next_stage_outport->outpin == next_stage_outpintiming->outpin)	break;
		opl = opl->next;
	}
	if (opl == NULL) {
		printf("ERROR: can't find next stage outport???\n");
		return RC_FAILED;
	}

	PATHELEMENT next_stage(next_stage_outport, next_stage_inport, next_stage_outpintiming);
	next_stage.previous = &this_stage;
	switch (next_stage_outpintiming->sense) {
	    case NEGATIVE_SENSE:
		if (this_stage.rising_at_outport == true) next_stage.rising_at_outport = false;
		else					  next_stage.rising_at_outport = true;
		break;
	    case POSITIVE_SENSE:
		next_stage.rising_at_outport = this_stage.rising_at_outport;
		break;
	    default:
		// ... hope this_stage is sensible ...
		next_stage.rising_at_outport = true;
	}

	// ....... go figure .........


	next_stage.compute_complete_path();
	float original_delay = next_stage.absolute_delay;

	// ............ now swap new_cell into this_stage ..........

	// .... ports with in-outpins from the new cell
	INPORT new_inport(new_cell, original_long_path->inport);
	OUTPORT new_outport(new_cell, original_long_path->outport);
	this_stage.inport = &new_inport;
	this_stage.outport = &new_outport;
	
	OUTPINTIMING *new_outpintiming;
	OUTPINTIMING_SENSE original_sense = this_stage.outpintiming->sense;
	ListOfOUTPINTIMING *optl = new_inport.inpin->outpintiminglist;
	while (optl != NULL) {
		new_outpintiming = optl->outpintiming;
		if (new_outpintiming->outpin == new_outport.outpin	&&
		    new_outpintiming->sense == original_sense		) {
			break;
		}
		optl = optl->next;
	}
	if (optl == NULL) {
		printf("ERROR: can't find  new outpintiming???\n");
		return RC_FAILED;
	}
	this_stage.outpintiming = new_outpintiming;
	
	float load_delta = new_inport.inpin->capacitance - this_stage_inport.inpin->capacitance;
	previous_outport.load_capacitance += load_delta;

	next_stage.compute_complete_path();
	float new_delay = next_stage.absolute_delay;

	// ............ how did we do? .............................

	if (this_stage.slope_at_outport > maximum_desireable_slope) {
		// don't go there
		return -FLT_MAX;
	}

	float improvement = original_delay - new_delay;
	return improvement;
}

rc_t
DESIGN::try_to_downsize_clones()
{
	int downsize_count = 0;
	ListOfCLONE *improved_clonelist = NULL;	

	ListOfCLONE *cl = clonelist;
	while (cl != NULL) {
		CLONE *clone = cl->clone;
		cl = cl->next;

		if (clone == fave_clone) {
			printf("DESIGN::try_to_downsize_clones	fave_clone\n");
		}

		if (clone->is_adjustable_for_size == false)	continue;
	
		CELL *original_cell = clone->instancelist->instance->cell;
		CELL *new_cell = original_cell->get_next_size_smaller();
		if (new_cell == NULL)	continue;
	
		ListOfINSTANCE *il = clone->instancelist;
		while (il != NULL) {
			INSTANCE *instance = il->instance;

			if (instance->cell != original_cell) {
				printf("not clonified... instance \"%s\"\n", instance->get_name());
				return RC_FAILED;
			}

			float improvement = instance->try_resize(new_cell);
			if (improvement < ::downsize_threshold)	break;

			il = il->next;
		}
		if (il == NULL) {
			// everybody was improved
			clone->change_cell(new_cell);

			if (speedy_verbose == true) {
				downsize_count++;	
				improved_clonelist = new ListOfCLONE(clone, improved_clonelist);
			}
		}
	}

	if (speedy_verbose == true) {
		printf("	... %d downsized\n", downsize_count);
		printf("target of improvements counted (clones):\n");
		ListOfCLONE *tcl;
	
		while (improved_clonelist != NULL) {
			CLONE *clone = improved_clonelist->clone;
			CELL *clone_cell = clone->instancelist->instance->cell;
			downsize_count = 1;
	
			ListOfCLONE *cl = improved_clonelist;
			while (cl->next != NULL) {
				// got to save the list pointer so we can unlink the clone if it matches
				CLONE *next_clone = cl->next->clone;
				CELL* next_clone_cell = next_clone->instancelist->instance->cell;
				if (next_clone_cell == clone_cell) {
					downsize_count++; 
	
					tcl = cl->next;
					cl->next = cl->next->next;
					tcl->unlink_and_delete();
	
				} else	cl = cl->next;
			}
	
			printf("%i	%s\n", downsize_count, clone_cell->name);
	
			tcl = improved_clonelist;
			improved_clonelist = improved_clonelist->next;
			tcl->unlink_and_delete();
		}
	}

	global_timing();
	return RC_NOMINAL;
}

rc_t
DESIGN::optimize_long_path_by_clones()
{
	// happy_counter = 0;
	rc_t rc = RC_IMPROVED;

	int upsize_count = 0;
	int downsize_count = 0;
	// clear_clone_tried_this_one(); ... try them as often as you like...

	while (rc == RC_IMPROVED) {
		global_timing();
		PATH *long_path = new PATH(*global_downstream->long_path);

		printf("...long path %f\n", long_path->absolute_delay);

		if (speedy_verbose == true) {
			long_path->write_to_file(stdout);
		}

		rc = optimize_path_by_clones(long_path, &upsize_count, &downsize_count);
		delete long_path;
	}
	if (speedy_verbose == true) {
		printf("upsize %d downsize %d\n", upsize_count, downsize_count);
	}
	return RC_NOMINAL;
}

rc_t
DESIGN::optimize_path_by_clones(PATH *path, int *upsize_count, int *downsize_count) 
{
	float path_delay = path->absolute_delay;

	rc_t return_v = RC_NOIMPROVEMENT;
	BOOLEAN global_timing_needed = false;
	
	PATHELEMENT *pe = path->final_pathelement;
	if (pe == NULL) {	// that silly corner case again
		return RC_NOIMPROVEMENT;
	}
	INPORT *next_stage_inport = path->destination_inport;

	while (pe != NULL) {
		OUTPORT *net_source = pe->outport;

		// ... if this is a clock net, don't even worry about it
		NET *net = net_source->net;
		if (net == fave_net) {
			printf("fave_net	optimize_path_by_clones\n");
		}


		if (net->global_value == GLOBAL_CLOCK)	break;

		// ... if we are coming from an extconn, just metion it's name
		if (net_source->instance->cell->type == CELLTYPE_EXTCONN) {
			if (speedy_verbose == true) {
				printf("..... driver extconn %s\n", net_source->outpin->name);
			}
			break;	
		} 

		// OK, here we go...
		if (speedy_verbose == true) {
			printf("..... net %s\n", net->get_name());
		}

		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {

			INPORT *net_inport = ipl->inport;
			ipl = ipl->next;

			// if (++happy_counter == happy_number) {
			// 	printf("happy counter match....\n");
			// 	// path->print(stdout);
			// }

			INSTANCE *instance = net_inport->instance;
			if (instance->cell->type == CELLTYPE_EXTCONN)	continue;	// ... extconn
			CLONE *clone = instance->clone;								
			if (clone->is_adjustable_for_size == false)	continue;
			// if (clone->tried_this_one == true)		continue;
			
			float new_delay = FLT_MAX;
			CELL *original_cell = instance->cell;
			CELL *new_cell;	

			if (net_inport == next_stage_inport) {
				// inport on the critical path
			
				if (net_inport->inpin->relative_speed == SLOW) {
					// find the FAST pin and swap with it
					INSTANCE *instance = net_inport->instance;
					INPIN *fast_inpin = instance->cell->get_fast_inpin();
					if (fast_inpin == NULL) {
						printf("slow inpin but no fast one???? cell \"%s\"\n", instance->cell->name);
						continue;
					}
					INPORT *other_inport = instance->get_inport(fast_inpin);
					if (other_inport == NULL) {
						printf("no inport for fast inpin??? instance \"%s\"\n", instance->get_name());
						continue;
					}

					printf("swapped input nets on instance \"%s\"\n", instance->get_name());
					instance->swap_inport_nets(net_inport, other_inport, true);
					goto keep_the_change;

					// XXX now we're not going to look at upsizing, but we don't do that anway....
				}

				if (allow_upsize_for_optimize == true		&&
					// can get caught in a loop, upsizeing this cell and then downsizeing it
					// depending on up_ and down_ thresholds
				    original_cell == clone->nominal_cell	) {
	
					OUTPORT *source = net_inport->net->source;
					if (source->instance->cell->type == CELLTYPE_EXTCONN) {
						// this gate is driven of extconn, which has infinite drive
						// so don't try to upsize it, 'cause it will always work...
						if (speedy_verbose == true) {
							printf("..........driven from extconn\n");
						}
						continue;
					}
	
					// ... if this connected instance is not actually *on* the 
					// interesting path, making this instance larger can't help
			
					new_cell = original_cell->get_next_size_larger();
					if (new_cell != NULL) {
						instance->change_cell(new_cell);
						new_delay = path->compute_complete_path();
						if (new_delay + ::upsize_threshold < path_delay) {
							CLONE *clone = instance->clone;
							clone->change_cell(new_cell);
							global_timing();
							global_timing_needed = true;	// 'cause we did a global-timing 
											// with non-official instances
							ListOfINSTANCE *clone_il = clone->instancelist;	// can't jump across declaration
	
							if (global_downstream->long_delay + ::upsize_threshold > path_delay) {
								goto this_upsize_not_good;
							}
	
							// check to see if we have made the slope too bad on input side
							while (clone_il != NULL) {
								INSTANCE *clone_instance = clone_il->instance;
								clone_il = clone_il->next;
	
								ListOfINPORT *ipl = clone_instance->inportlist;
								while (ipl != NULL) {
									INPORT *inport = ipl->inport;
									ipl = ipl->next;
								
									if (inport->net == NULL				||
									    inport->net->global_value != NOT_GLOBAL	) {
										continue;
									}
	
									OUTPORT *outport = inport->net->source;
									if (outport->rising_long_path->slope_at_outport > maximum_desireable_slope ||
									    outport->falling_long_path->slope_at_outport > maximum_desireable_slope) {
										goto this_upsize_not_good;
									}
								}
							}
							(*upsize_count)++;
							goto keep_the_change;
	
						    this_upsize_not_good:
							clone->change_cell(original_cell);
						} else {
							instance->change_cell(original_cell);
	
							// new_delay = path->compute_complete_path();
							// if (new_delay != path_delay) {
							// 	printf("WHATZIT!\n");
							// 	path->print(stdout);
							// 	path_delay = new_delay;
							// }
						}
					}
				}

				continue;
			}

			// inports collateral to the critical path

			new_cell = original_cell->get_next_size_smaller();
			if (new_cell != NULL) {
				instance->change_cell(new_cell);
				new_delay = path->compute_complete_path();

				// if (new_delay + ::downsize_threshold < path_delay) {
				if (new_delay < path_delay) {

					CLONE *clone = instance->clone;
					clone->change_cell(new_cell);
					global_timing();
					global_timing_needed = true;	// 'cause we did a global-timing 
									// with non-official instances
					ListOfINSTANCE *clone_il = clone->instancelist;	// can't jump across declaration

					// if (global_downstream->long_delay + ::downsize_threshold > path_delay	) {
					if (global_downstream->long_delay > path_delay	) {

						goto this_change_not_good;
					}

					// check to see if we have made the slope too bad
					while (clone_il != NULL) {
						INSTANCE *clone_instance = clone_il->instance;
						clone_il = clone_il->next;

						ListOfOUTPORT *opl = clone_instance->outportlist;
						while (opl != NULL) {
							OUTPORT *outport = opl->outport;
							opl = opl->next;

							if (outport->rising_long_path->slope_at_outport > maximum_desireable_slope ||
							    outport->falling_long_path->slope_at_outport > maximum_desireable_slope) {
								goto this_change_not_good;
							}
						}

					}
					(*downsize_count)++;
					goto keep_the_change;

				    this_change_not_good:
					clone->change_cell(original_cell);
				} else {
					instance->change_cell(original_cell);
				}
			}
			continue;

		    keep_the_change:

			global_timing_needed = false;	// 'cause we're making it good
			return_v = RC_IMPROVED;
			path->compute_complete_path();
			path_delay = path->absolute_delay;
			if (speedy_verbose == true) {
				printf("%s (%s in %s) %c -> %c \n    ... path delay -> %f design longpath delay -> %f\n", 
				    instance->get_name(), clone->name, clone->parent_cellname, 
				    original_cell->size, new_cell->size, 
				    path_delay, global_downstream->long_delay);
				path->write_to_file(stdout);
			}

			// .... if the long path is longer (therefore, different) than the present one, start working on it
			// otherwise, might just as well continue from where we are
			if (path_delay < global_downstream->long_delay)	return return_v;
		}
		next_stage_inport = pe->inport;
		pe = pe->previous;
	}

	if (global_timing_needed == true)	global_timing();
	return return_v;
}

rc_t
DESIGN::optimize_long_path_by_instances()
{
	// happy_counter = 0;
	rc_t rc = RC_IMPROVED;

	int upsize_count = 0;
	int downsize_count = 0;

	while (rc == RC_IMPROVED) {
		global_timing();
		PATH *long_path = new PATH(*global_downstream->long_path);

		printf("... long path %f\n", long_path->absolute_delay);
		if (::speedy_verbose == true) {
			long_path->write_to_file(stdout);
		}

		rc = optimize_path_by_instances(long_path, &upsize_count, &downsize_count);
		delete long_path;
	}
	printf("upsize %d downsize %d\n", upsize_count, downsize_count);
	return RC_NOMINAL;
}

rc_t
DESIGN::optimize_path_by_instances(PATH *path, int *upsize_count, int *downsize_count) 
{
	float path_delay = path->absolute_delay;

	rc_t return_v = RC_NOIMPROVEMENT;
	BOOLEAN global_timing_needed = false;
	
	PATHELEMENT *pe = path->final_pathelement;
	if (pe == NULL) {	// that silly corner case again
		return RC_NOIMPROVEMENT;
	}
	INPORT *next_stage_inport = path->destination_inport;

	while (pe != NULL) {
		OUTPORT *net_source = pe->outport;

		// ... if this is a clock net, don't even worry about it
		NET *net = net_source->net;
		if (net == fave_net) {
			printf("fave_net	optimize_path_by_instances\n");
		}


		if (net->global_value == GLOBAL_CLOCK)	break;

		// ... if we are coming from an extconn, just metion it's name
		if (net_source->instance->cell->type == CELLTYPE_EXTCONN) {
			printf("..... driver extconn %s\n", net_source->outpin->name);
			break;	
		} 

		// OK, here we go...
		if (::speedy_verbose == true) {
			printf("..... net %s\n", net->get_name());
		}

		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {

			INPORT *net_inport = ipl->inport;
			ipl = ipl->next;

			INSTANCE *instance = net_inport->instance;
			if (instance->cell->type == CELLTYPE_EXTCONN)		continue;	// ... extconn

			if (instance->clone != NULL				&&
			    instance->clone->is_adjustable_for_size == false	)	continue;

			float new_delay = FLT_MAX;
			CELL *original_cell = instance->cell;
			CELL *new_cell;	

			if (net_inport == next_stage_inport) {

				if (net_inport->inpin->relative_speed == SLOW) {
					// find the FAST pin and swap with it
					INSTANCE *instance = net_inport->instance;
					INPIN *fast_inpin = instance->cell->get_fast_inpin();
					if (fast_inpin == NULL) {
						printf("slow inpin but no fast one???? cell \"%s\"\n", instance->cell->name);
						continue;
					}
					INPORT *other_inport = instance->get_inport(fast_inpin);
					if (other_inport == NULL) {
						printf("no inport for fast inpin??? instance \"%s\"\n", instance->get_name());
						continue;
					}

					instance->swap_inport_nets(net_inport, other_inport, false);

					printf("swapped input nets for instance \"%s\"\n", instance->get_name());
				}

				if (allow_upsize_for_optimize == true) {

					OUTPORT *source = net_inport->net->source;
					if (source->instance->cell->type == CELLTYPE_EXTCONN) {
						// this gate is driven of extconn, which has infinite drive
						// so don't try to upsize it, 'cause it will always work...
						if (speedy_verbose == true) {
							printf("..........driven from extconn\n");
						}
						continue;
					}
	
					// ... if this connected instance is not actually *on* the 
					// interesting path, making this instance larger can't help
			
					new_cell = original_cell->get_next_size_larger();
					if (new_cell != NULL) {
						instance->change_cell(new_cell);
						new_delay = path->compute_complete_path();
						if (new_delay + ::upsize_threshold < path_delay) {
							global_timing();
							global_timing_needed = true;	// 'cause we did a global-timing 
											// with non-official instances
							
							if (global_downstream->long_delay + ::upsize_threshold > path_delay) {
								goto this_upsize_not_good;
							}
							else {
								// check to see if we have made the slope too bad on input side
								ListOfINPORT *ipl = instance->inportlist;
								while (ipl != NULL) {
									INPORT *inport = ipl->inport;
									ipl = ipl->next;
									
									if (inport->net == NULL				||
									    inport->net->global_value != NOT_GLOBAL	) {
										continue;
									}
		
									OUTPORT *outport = inport->net->source;
									if (outport->rising_long_path->slope_at_outport > maximum_desireable_slope ||
									    outport->falling_long_path->slope_at_outport > maximum_desireable_slope) {
										goto this_upsize_not_good;
									}
								}
							}
							(*upsize_count)++;
							goto keep_the_change;
	
						    this_upsize_not_good:
							instance->change_cell(original_cell);
						} else {
							instance->change_cell(original_cell);
						}
					}
				}

				if (::allow_downsize_on_critical_path_for_optimize == false)	continue;
			}

			new_cell = original_cell->get_next_size_smaller();
			if (new_cell != NULL) {
				instance->change_cell(new_cell);
				new_delay = path->compute_complete_path();

				// if (new_delay + ::downsize_threshold < path_delay) {
				if (new_delay < path_delay) {

					global_timing();
					global_timing_needed = true;	// 'cause we did a global-timing 
									// with non-official instances
					ListOfOUTPORT *opl;

					// if (global_downstream->long_delay + ::downsize_threshold > path_delay	) {
					if (global_downstream->long_delay > path_delay	) {

						goto this_change_not_good;
					}

					// check to see if we have made the slope too bad
					opl = instance->outportlist;
					while (opl != NULL) {
						OUTPORT *outport = opl->outport;
						opl = opl->next;

						if (outport->rising_long_path->slope_at_outport > maximum_desireable_slope ||
						    outport->falling_long_path->slope_at_outport > maximum_desireable_slope) {
							goto this_change_not_good;
						}

					}
					(*downsize_count)++;
					goto keep_the_change;

				    this_change_not_good:
					instance->change_cell(original_cell);
				} else {
					instance->change_cell(original_cell);
				}
			}
			
			continue;

		    keep_the_change:

			global_timing_needed = false;	// 'cause we're making it good
			path->compute_complete_path();
			path_delay = path->absolute_delay;

			printf("%s %c -> %c (%s) \n    ... path delay -> %f design longpath delay -> %f\n", 
			    instance->get_name(),
			    original_cell->size, new_cell->size, new_cell->name, 
			    path_delay, global_downstream->long_delay);
			if (speedy_verbose == true) {
				path->write_to_file(stdout);
			}

			// .... if the long path is longer (therefore, different) than the present one, start working on it
			// otherwise, might just as well continue from where we are
			if (path_delay < global_downstream->long_delay)	return RC_IMPROVED;
			return_v = RC_IMPROVED;		// ... but we still better ...
		}
		next_stage_inport = pe->inport;
		pe = pe->previous;
	}

	if (global_timing_needed == true)	global_timing();
	return return_v;
}


//////////////////////////////////////////////////////////////////////////

rc_t
DESIGN::resize_to_maximum()
{
	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		if (instance->clone->is_adjustable_for_size == false)	continue;

		// cells are in order smallest to largest;
		// we want the last one
		CELL *new_cell;
		ListOfCELL *cl = instance->cell->functiongroup->celllist;
		while (cl != NULL) {
			new_cell = cl->cell;
			cl = cl->next;
		}
		if (instance->cell != new_cell) {
			instance->change_cell(new_cell);
		}
	}

	return RC_NOMINAL;
}

rc_t
DESIGN::resize_to_minimum()
{

	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		if (instance->clone->is_adjustable_for_size == false)	continue;
	
		// cells are in order smallest to largest;
		// we want the first one
		CELL *new_cell = instance->cell->functiongroup->celllist->cell;
		if (instance->cell != new_cell) {
			instance->change_cell(new_cell);
		}
	}

	return RC_NOMINAL;
}

//////////////////////////////////////////////////////////////////////////

float area_saved;
int instances_downsized;

rc_t
DESIGN::downsize_for_area_by_clones()
{
	area_saved = 0.0;
	instances_downsized = 0;
	if (global_downstream == NULL) {
		printf("global_downstream not initialized\n");
		return RC_FAILED;
	}

	// don't want to keep allocating this... we only need 1 at a time...
	DOWNSTREAM *downstream = new DOWNSTREAM();	
	int downsize_counter = 0;
	int pass_counter = 0;

	global_timing();
	float long_path_delay = global_downstream->long_delay;
	if (speedy_verbose == true) {
		printf("initial long delay %f\n", long_path_delay);
	}
	float new_long_path_delay;

	// happy_counter = 0;

	// ListOfCELL *sorted_cl = cell_library->by_area_celllist;
	ListOfCELL *sorted_cl = cell_library->downsize_order_celllist;
	while (sorted_cl != NULL) {
		CELL *cell = sorted_cl->cell;
	 	sorted_cl = sorted_cl->next;
		printf("...cell %s\n", cell->name);

		pass_counter = 0;

		ListOfCLONE *cl = clonelist;
		while (cl != NULL) {
			CLONE *clone = cl->clone;
			cl = cl->next;
			if (clone->instancelist->instance->cell != cell)	continue;
			if (clone->is_adjustable_for_size == false)		continue;

			rc_t rc = clone->downsize_for_area(long_path_delay, downstream);
			if (rc == RC_IMPROVED)	pass_counter++;
		}

		if (speedy_verbose == true) {
			printf("this pass for cell '%s' downsized %d clones\n", cell->name, pass_counter);
			global_timing();
			new_long_path_delay = global_downstream->long_delay;
			if (new_long_path_delay > long_path_delay) {
				printf("ERROR: long path delay increased %f before -> %f after\n",
				    long_path_delay, new_long_path_delay);
				long_path_delay = new_long_path_delay;
			}
		} 

		downsize_counter += pass_counter;
	}

	if (speedy_verbose == true) {
		printf("downsized %d clones (%d instances)... area saved %f\n", downsize_counter, instances_downsized, area_saved);
	}
	global_timing();
	new_long_path_delay = global_downstream->long_delay;
	if (new_long_path_delay > long_path_delay) {
		printf("ERROR: long path delay increased %f before -> %f after\n",
		    long_path_delay, new_long_path_delay);
	} 
	else if (speedy_verbose == true) printf("new long path delay %f\n", new_long_path_delay);
	
	return RC_NOMINAL;
}


rc_t
DESIGN::profile_slack_by_instances(char *filename)
{
	FILE *f = NULL;
	if (strcmp(filename, "") != 0) {
		f = fopen(filename, "w");
		if (f == NULL) {
			printf("could not open file \"%s\" for writing\n", filename);
			return RC_FAILED;
		}
	}


	int i;

	if (global_downstream == NULL) {
		printf("global_downstream not initialized\n");
		return RC_FAILED;
	}

	const int	ncounters		= 200;
	int		counter[ncounters];
	int		more_counter		= 0;

	float threshold[ncounters];
	for (i = 0; i < ncounters; i++) {
		counter[i] = 0;
		threshold[i] = i * .005;
	}

	DOWNSTREAM *downstream = new DOWNSTREAM();	
	global_timing();
	float long_path_delay = global_downstream->long_delay;
	printf("initial long delay %f\n", long_path_delay);
	int instance_counter = 0;

	INSTANCE **ia = &global_downstream->instancearray[global_downstream->instancearray_topindex];
	while (*ia != NULL) {
		INSTANCE *instance = *(ia--);

		if (++instance_counter == 99) {
			printf(".");
			fflush(stdout);
			instance_counter = 0;
		}

		downstream->init();
		ListOfINSTANCE *root_instancelist = new ListOfINSTANCE(instance, NULL);
		downstream->get_downstream_instances(root_instancelist);
		downstream->compute_timing();
		downstream->get_long_delay();
		float slack = long_path_delay - downstream->long_delay;

		for (i = 0; i < ncounters; i++) {
			if (slack < threshold[i]) {
				counter[i]++;
				break;
			}
		}
		if (i == ncounters)	more_counter++;

		if (f != NULL) {
			char *netname = instance->outportlist->outport->net->get_name();
			if	(slack < .025)	fprintf(f, "set_timing_weights -effort ultra  {%s}\n", netname);
			else if (slack < .075)	fprintf(f, "set_timing_weights -effort high   {%s}\n", netname);
			else if (slack < .150)	fprintf(f, "set_timing_weights -effort medium {%s}\n", netname);
			else if (slack < .300)	fprintf(f, "set_timing_weights -effort low    {%s}\n", netname);
		}
	}

	for (i = 0; i < ncounters; i++) {
		printf("%d:	%.3f	%d\n", i, threshold[i], counter[i]);
	}
		printf("more:		%d\n", more_counter);
	
	
	return RC_NOMINAL;
}

rc_t
DESIGN::downsize_for_area_by_instances()
{
	area_saved = 0.0;
	if (global_downstream == NULL) {
		printf("global_downstream not initialized\n");
		return RC_FAILED;
	}

	DOWNSTREAM *downstream = new DOWNSTREAM();	
	int downsize_counter = 0;
	int pass_counter;

	global_timing();
	float long_path_delay = global_downstream->long_delay;
	printf("initial long delay %f\n", long_path_delay);
	float new_long_path_delay;

	ListOfCELL *sorted_cl = cell_library->downsize_order_celllist;
	while (sorted_cl != NULL) {
		CELL *cell = sorted_cl->cell;
		sorted_cl = sorted_cl->next;

		INSTANCE **ia = &global_downstream->instancearray[global_downstream->instancearray_topindex];
		while (*ia != NULL) {
			INSTANCE *instance = *(ia--);

			if (instance->cell != cell)	continue;
			rc_t rc = instance->downsize_for_area(long_path_delay, downstream);
			if (rc == RC_IMPROVED)	pass_counter++;
		}

		if (speedy_verbose == true) {
			printf("this pass for cell '%s' downsized %d instances\n", cell->name, pass_counter);
			global_timing();
			new_long_path_delay = global_downstream->long_delay;
			if (new_long_path_delay > long_path_delay) {
				printf("ERROR: long path delay increased %f before -> %f after\n",
				    long_path_delay, new_long_path_delay);
				long_path_delay = new_long_path_delay;
			}
		} 

		downsize_counter += pass_counter;
		if (pass_counter == 0) {
			sorted_cl = sorted_cl->next;
		}

	}

	printf("downsized %d instances... area saved %f\n", downsize_counter, area_saved);
	global_timing();
	new_long_path_delay = global_downstream->long_delay;
	if (new_long_path_delay > long_path_delay) {
		printf("ERROR: long path delay increased %f before -> %f after\n",
		    long_path_delay, new_long_path_delay);
	} 
	else printf("new long path delay %f\n", new_long_path_delay);
	
	return RC_NOMINAL;
}


rc_t
DESIGN::downsize_for_area(char *instancename)
{
	DOWNSTREAM *downstream = new DOWNSTREAM();	
	
	INSTANCE *instance = design->get_instance(instancename);
	if (instance == NULL) {
		printf("instance \"%s\" not found\n", instancename);
		return RC_FAILED;
	}

	float long_path_delay = global_downstream->long_delay;
	
	instance->downsize_for_area(long_path_delay, downstream);
	printf("%s...%d\n", instance->get_name(), downstream->instancearray_topindex);
		
	return RC_NOMINAL;
}

rc_t
CLONE::downsize_for_area(float long_path_delay, DOWNSTREAM *downstream)
{
	
	if (fave_instance != (INSTANCE *)-1	&&
	    this == fave_instance->clone	) {
		printf("fave_instance CLONE::downsize_for_area\n");
	}

	if (is_adjustable_for_size == false)	return RC_NOIMPROVEMENT;

	INSTANCE *typical_instance = instancelist->instance;
	CELL *original_cell = typical_instance->cell;
		// ... imagine my surprize, sometimes smaller cells are slower but no smaller....
		// but I guess we are saving power anyway...
	CELL *small_cell = original_cell->get_next_size_smaller();			;
	if (small_cell == NULL) return RC_NOIMPROVEMENT;	

	downstream->init();
	downstream->get_downstream_instances(instancelist);
	downstream->compute_timing();
	downstream->get_long_delay();

	if (downstream->long_delay < 0		&&
	    downsize_unloaded_instances == true	) {
		
		// this instance doesn't fan out to any terminals
		// ... might as well make it smallest, since we can't just delete it ....
		CELL *small_cell = original_cell->functiongroup->celllist->cell;
		if (small_cell != original_cell) {
			change_cell(small_cell);
			if (speedy_verbose == true) {
				printf("%s/%s %c->%c - no downstream terminals - area decrease %f\n",
				    parent_cellname, name, 
				    original_cell->size, small_cell->size, 
				    original_cell->area - small_cell->area);
			}
			return RC_IMPROVED;
		}
		return RC_NOIMPROVEMENT;
	}
	
	float slack = long_path_delay - downstream->long_delay;
	float working_slack = slack - minimum_desireable_slack;
	float slack_decrease;

	// I think it's probably better to distribute the downsizing as widely 
	// as possible... and anyway if we go down two steps and it turns out that some 
	// instance in the clone busts the longpath, it's hard to back off.
	// So we just do one.  If you want more, make multiple passes.

	slack_decrease = -(typical_instance->try_resize(small_cell));
	if (slack_decrease > working_slack) {
		// ... haven't changed anything yet
		return RC_NOIMPROVEMENT;
	}


	// XXX!!! if we don't accept the change, we don't restore
	// the long paths....

	change_cell(small_cell);		
	downstream->compute_timing_and_update_long_path();
	downstream->get_long_delay();
	float new_slack = long_path_delay - downstream->long_delay;
	if (new_slack < minimum_desireable_slack) {
		change_cell(original_cell);
		return RC_NOIMPROVEMENT;
	}

	float area_saved_for_this = (original_cell->area - small_cell->area) * n_instances;
	if (speedy_verbose == true) {
		printf("%s/%s	%c->%c	slack %.3f	slack decrease %.3f	area decrease %.3f * %d instances = %.3ff\n",
		    parent_cellname, name,
		    original_cell->size, small_cell->size, 
		    slack, slack - new_slack,
		    original_cell->area - small_cell->area, n_instances, area_saved_for_this);
	}
	area_saved += area_saved_for_this;
	instances_downsized += n_instances;
	return RC_IMPROVED;
}

rc_t
INSTANCE::downsize_for_area(float long_path_delay, DOWNSTREAM *downstream)
{
	if (this == fave_instance) {
		printf("fave_instance downsize_for_area\n");
	}

	if (clone == NULL				||
	    clone->is_adjustable_for_size == false	) {
		return RC_NOIMPROVEMENT;
	}

	CELL *original_cell = cell;
	CELL *good_cell = original_cell;
		// ... imagine my surprize, sometimes smaller cells are slower but no smaller....
		// but I guess we are saveing area anyway...
	CELL *small_cell = original_cell->get_next_size_smaller();			
	if (small_cell == NULL) return RC_NOIMPROVEMENT;	

	downstream->init();
	ListOfINSTANCE *root_instancelist = new ListOfINSTANCE(this, NULL);
	downstream->get_downstream_instances(root_instancelist);
	downstream->compute_timing();
	downstream->get_long_delay();

	if (downstream->long_delay < 0) {
		// this instance doesn't fan out to any terminals
		// ... might as well make it smallest, since we can't just delete it ....
		CELL *good_cell = cell->functiongroup->celllist->cell;
		if (good_cell != original_cell) {
			change_cell(good_cell);
			printf("%s %c->%c - no downstream terminals - area decrease %f\n",
			    get_name(), original_cell->size, good_cell->size, 
			    original_cell->area - good_cell->area);
			return RC_IMPROVED;
		}
		return RC_NOIMPROVEMENT;
	}
	
	float slack = long_path_delay - downstream->long_delay;
	float working_slack = slack - minimum_desireable_slack;
	float slack_decrease;
	while (1) {
		slack_decrease = -(try_resize(small_cell));
		if (slack_decrease > working_slack)	break;
		good_cell = small_cell;
		while (1) {
			small_cell = small_cell->get_next_size_smaller();
			if (small_cell == NULL)			goto done;
			if (small_cell->area < good_cell->area)	break;
		}
	}

    done:
	if (good_cell == original_cell)	return RC_NOIMPROVEMENT;

	change_cell(good_cell);		
	downstream->compute_timing_and_update_long_path();
	downstream->get_long_delay();
	float new_slack = long_path_delay - downstream->long_delay;
	if (new_slack < minimum_desireable_slack) {
		printf("ERROR or at least LOOK AT ME: new slack %f less than minimum %f\n", 
		    new_slack, minimum_desireable_slack);
	}
	printf("%s %c->%c slack %f slack decrease %f area decrease %f\n",
		get_name(), original_cell->size, good_cell->size, 
		slack, slack - new_slack,
		original_cell->area - good_cell->area);

	area_saved += original_cell->area - good_cell->area;
	return RC_IMPROVED;
}

//////////////////////////////////////////////////////////////////////////

rc_t
NET::split_net_for_parallel_drivers()
{
	if (::location_information_is_loaded == false) {
		printf("don't want to split nets prior to placement\n");
		// ... or else we need to pick loads differently, at least
		return RC_FAILED;
	}

	INSTANCE *driver_instance = this->source->instance;
	CELL *driver_cell = driver_instance->cell;
	OUTPORT *driver_outport = driver_instance->outportlist->outport;
	NET *driver_input_net = driver_instance->inportlist->inport->net;

	float ratio = (this->source->load_capacitance / driver_cell->max_capacitance);
	int how_many_ways = (int)ratio;	// ... truncates
	if (ratio - (float)how_many_ways < 0.3)		how_many_ways++;
	if (how_many_ways <= 1) {
		printf("split_net: split 1 way???\n");
		return RC_FAILED;
	}
	printf("splitting net \"%s\" %d ways...\n", get_name(), how_many_ways);
	
	for (int i = how_many_ways; i > 1; i--) {
		// ... create new buffer/inverter
		sprintf(tstr, "split_buffer_%d", ::next_sequential_number++);
		INSTANCE *split_buffer = new INSTANCE(tstr);
		split_buffer->identify(driver_cell->name);
		INPORT *split_buffer_inport = split_buffer->inportlist->inport;
		driver_input_net->inportlist = new ListOfINPORT(split_buffer_inport, driver_input_net->inportlist);
		split_buffer_inport->net = driver_input_net;
		OUTPORT *split_buffer_outport = split_buffer->outportlist->outport;

		// .... colocate split buffer with original
		split_buffer_inport->x = driver_outport->x;
		split_buffer_inport->y = driver_outport->y;
		split_buffer_outport->x = driver_outport->x;
		split_buffer_outport->y = driver_outport->y;

		// .... new net
		sprintf(tstr, "split_buffer_net_%d", ::next_sequential_number++);
		NET *split_buffer_net = new NET(tstr);
		split_buffer_net->source = split_buffer_outport;
		split_buffer_outport->net = split_buffer_net;

		// ... pick the loads ... 
		// ... let's take the farthest load, then the loads closest to that one ....
		ListOfINPORT *ipl = this->inportlist;
		INPORT *distant_inport = ipl->inport;
		int max_distance = distant_inport->distance(this->source);
		ipl = ipl->next;
		while (ipl != NULL) {
			INPORT *ip = ipl->inport;
			ipl = ipl->next;

			int distance = ip->distance(this->source);
			if (distance > max_distance) {
				max_distance = distance;
				distant_inport = ip;
			}
		}
		
		this->remove_inport(distant_inport);
		split_buffer_net->inportlist = new ListOfINPORT(distant_inport, NULL);
		split_buffer_net->compute_net_characteristics();
		
		while (split_buffer_net->source->load_capacitance < split_buffer->cell->max_capacitance) {
			// get another one....
			ipl = this->inportlist;
			INPORT *close_inport = ipl->inport;
			int min_distance = close_inport->distance(distant_inport);
			ipl = ipl->next;
			while (ipl != NULL) {
				INPORT *ip = ipl->inport;
				ipl = ipl->next;

				int distance = ip->distance(distant_inport);
				if (distance < min_distance) {
					min_distance = distance;
					close_inport = ip;
				}
			}

			this->remove_inport(close_inport);
			split_buffer_net->inportlist = new ListOfINPORT(close_inport, split_buffer_net->inportlist);
			split_buffer_net->compute_net_characteristics();
		}

		nl_interface->add_split_buffer(split_buffer, driver_instance);
	}		
	this->compute_net_characteristics();
	driver_input_net->compute_net_characteristics();
		
	return RC_NOMINAL;
}

int swap_count = 0;

rc_t
INSTANCE::swap_inport_net_to_fast(INPORT *arg_inport, INPORT **return_fast_inport, BOOLEAN by_clones)
{
	INPIN *fast_inpin = cell->get_fast_inpin();
	if (fast_inpin == NULL			||
	    fast_inpin == arg_inport->inpin	) {
		return RC_NOIMPROVEMENT;
	}

	INPORT *fast_inport;
	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		fast_inport = ipl->inport;
		if (fast_inport->inpin == fast_inpin)	break;
		ipl = ipl->next;
	}
	if (ipl == NULL) {
		printf("ERROR: rewire_to_fast_inport can't find fast inport??? instance \"%s\"\n", get_name());
		return RC_NOIMPROVEMENT;
	}

	swap_inport_nets(arg_inport, fast_inport, by_clones);

	*return_fast_inport = fast_inport;
	swap_count++;
	return RC_IMPROVED;
}

///////////////////////////////////////////////////////////////////////////////
////   these are the functions that axtuelly modify the design

rc_t
INSTANCE::swap_inport_nets(INPORT *inport1, INPORT *inport2, BOOLEAN by_clones)
{
	// .... the BOOLEAN by_clones is a little odd, but I want to return the
	// fast_inport of the favorite instance from rewire_to_fast_inport to
	// resize optimize method so I can fixup the pathelement.  Anyway, it works.

	NET *inport1_net = inport1->net;			
	inport1_net->remove_inport(inport1);

	NET *inport2_net = inport2->net;			
	inport2_net->remove_inport(inport2);

	inport1_net->inportlist = new ListOfINPORT(inport2, inport1_net->inportlist);
	inport2->net = inport1_net;

	inport2_net->inportlist = new ListOfINPORT(inport1, inport2_net->inportlist);
	inport1->net = inport2_net;

	inport1_net->compute_net_characteristics();
	inport2_net->compute_net_characteristics();

	if (by_clones == true		&&
	    clone != NULL		&&
	    clone->n_instances > 1	) {

		ListOfINSTANCE *il = clone->instancelist;
		while (il != NULL) {
			INSTANCE *i = il->instance;
			il = il->next;

			if (i == this)	continue;
			INPORT *ip1 = get_inport(inport1->inpin);
			INPORT *ip2 = get_inport(inport2->inpin);
			i->swap_inport_nets(ip1, ip2, false);
		}
	}			
	
	nl_interface->swap_inport_nets(inport1, inport2);
	return RC_NOMINAL;
}

void
NET::insert_buffer(INSTANCE **return_buffer, NET **return_buffer_in_net)
{
	OUTPORT *original_source = source;

	sprintf(tstr, "inserted_buffer_%d", ::next_sequential_number++);
	INSTANCE *buffer = new INSTANCE(tstr);
	buffer->identify(::buffer_cellname);
	OUTPORT *buffer_outport = buffer->outportlist->outport;
	buffer_outport->x = original_source->x;
	buffer_outport->y = original_source->y;
	INPORT *buffer_inport = buffer->inportlist->inport;
	buffer_inport->x = original_source->x;
	buffer_inport->y = original_source->y;

	source = buffer_outport;
	buffer_outport->net = this;

	sprintf(tstr, "inserted_buffer_input_%d", ::next_sequential_number++);
	NET *buffer_in_net = new NET(tstr);
	buffer_in_net->source = original_source;
	original_source->net = buffer_in_net;
	buffer_in_net->inportlist = new ListOfINPORT(buffer_inport, NULL);
	buffer_inport->net = buffer_in_net;

	this->compute_net_characteristics();
	buffer_in_net->compute_net_characteristics();

	buffer->resize_by_threshold();
	original_source->instance->resize_by_threshold();
	nl_interface->insert_buffer(this, buffer_in_net, buffer);
	if (return_buffer != NULL)	  *return_buffer = buffer;
	if (return_buffer_in_net != NULL) *return_buffer_in_net = buffer_in_net;
}

rc_t
NET::remove_buffer()
{
	INSTANCE *source_instance = source->instance;
	if (source_instance->cell->functiongroup != ::buffer_cell->functiongroup) {
		printf("NET::delete_buffer: source instance is \"%s\", not a buffer\n", source_instance->cell->name);
		return RC_FAILED;
	}
	printf("removing buffer \"%s\"\n", source_instance->get_name());

	nl_interface->remove_buffer(source_instance);

	INPORT *source_instance_inport = source_instance->inportlist->inport;
	NET *inport_net = source_instance_inport->net;
	
	// delete the source instance from the inport net
	ListOfINPORT *ipl = inport_net->inportlist;
	if (ipl->inport == source_instance_inport) {
		inport_net->inportlist = inport_net->inportlist->next;
	} else {
		while (ipl->next != NULL) {
			if (ipl->next->inport == source_instance_inport)	break;
			ipl = ipl->next;
		}
		if (ipl->next == NULL) {
			printf("NET::delete_buffer: can't find source inport on inport net \"%s\" buffer instance \"%s\"???\n",
			    inport_net->get_name(), source_instance->get_name());
			return RC_FAILED;
		}
		ipl->next = ipl->next->next;
	}

	// add the loads from this net to source net
	while (ipl->next != NULL)	ipl = ipl->next;
	ipl->next = this->inportlist;

	design->remove_instance(source_instance);
	design->remove_net(this);
	inport_net->compute_net_characteristics();

	return RC_NOMINAL;
}

rc_t
INSTANCE::change_cell(CELL *new_cell)
{
	cell = new_cell;

	ListOfINPORT *iportl = inportlist;
	while (iportl != NULL) {
		INPORT *inport = iportl->inport;
		iportl = iportl->next;

		ListOfINPIN *pinl = new_cell->inpinlist;
		while (pinl != NULL) {
			INPIN *inpin = pinl->inpin;
			if (strcmp(inpin->name, inport->inpin->name) == 0) {
				inport->inpin = inpin;
				break;
			}
			pinl = pinl->next;

		}
		if (pinl == NULL) {
			printf("ERROR: change_cell can't find corresponding inpin \"%s:%s\" new cell \"%s\"\n",
			    get_name(), inport->inpin->name, new_cell->name);
		}
		if (inport->net != NULL) {
			inport->net->compute_net_characteristics();
			inport->net->estimate_tc_delay();
		}
	}

	ListOfOUTPORT *oportl = outportlist;
	while (oportl != NULL) {
		OUTPORT *outport = oportl->outport;
		oportl = oportl->next;

		ListOfOUTPIN *pinl = new_cell->outpinlist;
		while (pinl != NULL) {
			OUTPIN *outpin = pinl->outpin;
			if (strcmp(outpin->name, outport->outpin->name) == 0) {
				outport->outpin = outpin;
				break;
			}
			pinl = pinl->next;
		}
		if (pinl == NULL) {
			printf("ERROR: change_cell can't find corresponding outpin \"%s:%s\" new cell \"%s\"\n",
			    get_name(), outport->outpin->name, new_cell->name);
		}
	}
	return RC_NOMINAL;
}


rc_t
CLONE::change_cell(CELL *cell) 
{
	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;
	
		if (instance->cell == cell)	continue;
		instance->change_cell(cell);
	}
	
	return RC_NOMINAL;
}

///////////////////////////////////////////////////////////////////////

rc_t
DESIGN::save_cell_pointers()
{
	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		instance->saved_cell = instance->cell;
	}

	return RC_NOMINAL;
}

rc_t
DESIGN::restore_saved_cell_pointers()
{
	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;
		
		if (instance->cell == NULL		||
		    instance->saved_cell == NULL	) {
			continue;
		}

		instance->change_cell(instance->saved_cell);
	}

	return RC_NOMINAL;
}

rc_t
DESIGN::restore_nominal_cells()
{
	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		// ... now we have a class of fake instances for input exconns...
		// so we have an ugly special case with it....
		if (instance->clone == NULL)	continue;

		instance->change_cell(instance->clone->nominal_cell);
	}

	return RC_NOMINAL;
}

rc_t
DESIGN::collect_clones()
{
	if (resized_clonelist != NULL) {
		delete resized_clonelist;
		resized_clonelist = NULL;
	}

	int	clone_count = 0;
	ListOfCLONE *cl = clonelist;
	while (cl != NULL) {
		CLONE *clone = cl->clone;
		cl = cl->next;

		clone_count++;
		int instance_count = 0;
		if (clone->is_adjustable_for_size == false)	continue;

		// ... make sure that this guy's clones is all set to same (largest) size
		ListOfINSTANCE *il = clone->instancelist;
		CELL *largest_cell = il->instance->cell;
		BOOLEAN all_equal_size = true;

		// find the largest cell amongst the clone
		while (il != NULL) {
			INSTANCE *instance = il->instance;
			il = il->next;
			instance_count++;

			if (instance->cell == largest_cell)	continue;
			all_equal_size = false;

			if (instance->cell->size > largest_cell->size) {
				largest_cell = instance->cell;
			}
		}

		// make everybody be the same as the largest guy
		if (all_equal_size == false)	clone->change_cell(largest_cell);

		// if it's different than nominal...
		if (clone->nominal_cell->size != largest_cell->size) {
			resized_clonelist = new ListOfCLONE(clone, resized_clonelist);
		}
	}

	return RC_NOMINAL;
}
