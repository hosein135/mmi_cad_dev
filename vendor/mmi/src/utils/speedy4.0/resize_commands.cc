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

///////////////////
// forward declarations

rc_t	print_resizes();
rc_t	print_cell_area();
rc_t	write_resizes_tcl(char *filename);

///////////////////


rc_t
resize(char *method) {

	if (design == NULL) {
		printf("no design loaded in Speedy\n");
		return RC_FAILED;
	}
	
	rc_t rc = cell_library->compute_thresholds(target_slope,
	    compute_thresholds_use_limit_method);	
	if (rc != RC_NOMINAL) {
		printf("compute thresholds failed\n"); 
		return RC_FAILED;
	}

	print_long_delay();

	if (strcmp(method, "") == 0) {
		print_cell_area();
		rc_t rc = design->global_timing();
		if (rc != RC_NOMINAL)	return rc;

		printf("\nI:...adjust clone sizes by thresholds...\n");
		rc = design->resize_clones_by_threshold();
		if (rc != RC_NOMINAL)	return rc;
		global_timing();

		printf("\nII: ...try to downsize clones...\n");
		rc = design->try_to_downsize_clones();
		if (rc != RC_NOMINAL)	return rc;
		global_timing();

		printf("\nIII:...adjust instance sizes by up/down sizing clones along long path...\n");
		rc = design->optimize_long_path_by_clones();
		if (rc != RC_NOMINAL)	return rc;
		global_timing();

		printf("\nIV:...downsize to reduce power/area OMITTED\n");
		// printf("\nIV:...downsize to reduce power/area\n");
		// print_cell_area();
		// design->downsize_by_for_area_by_clones();
		// print_cell_area();
		// if (rc != RC_NOMINAL)	return rc;

	}


	else if (strcmp(method, "instances") == 0) {
		print_cell_area();
		rc_t rc = design->global_timing();
		if (rc != RC_NOMINAL)	return rc;

		printf("\nI:...adjust instance sizes by thresholds...\n");
		design->resize_instances_by_threshold();
		print_long_delay();

		printf("\nII:...try to downsize instances...\n");
		design->try_to_downsize_instances();
		print_long_delay();

		printf("\nIII:...optimize path by instances...\n");
		design->optimize_long_path_by_instances();
		print_long_delay();

		printf("\n:IV...downsize to reduce power/area...OMITTED\n");
		// printf("\n:IV...downsize to reduce power/area...\n");
		// print_cell_area();
		// design->downsize_by_timing_slack_by_instances();
		// print_cell_area();
	}		

	else if (strcmp(method, "thresholds") == 0			||
		 strcmp(method, "thresholds_by_clone") == 0		) {
		printf("...adjust clone sizes by thresholds...\n");
		design->resize_clones_by_threshold();
	}

	else if (strcmp(method, "downsize") == 0		||
		 strcmp(method, "downsize_by_clone") == 0	) {
		printf("...try to downsize clones...\n");
		design->try_to_downsize_clones();
	}
	else if (strcmp(method, "optimize_path") == 0) {
		printf("...adjust instance sizes by up/down sizing clones along long path...\n");
		design->optimize_long_path_by_clones();
	}
	else if (strcmp(method, "optimize_path_by_instances") == 0) {
		printf("...adjust instance sizes by up/down sizing instances along long path...\n");
		design->optimize_long_path_by_instances();
	}
	else if (strcmp(method, "thresholds_by_instances") == 0) {
		printf("...adjust instance sizes individually by thresholds...\n");
		design->resize_instances_by_threshold();
	}
	else if (strcmp(method, "downsize_by_instances") == 0) {
		printf("...try to downsize instances individually...\n");
		design->try_to_downsize_instances();
	}
	else if (strcmp(method, "for_area") == 0) {
		printf("......downsize to reduce power/area...\n");
		print_cell_area();
		design->downsize_for_area_by_clones();

	}
	else if (strcmp(method, "for_area_by_instances") == 0) {
		printf("......downsize to reduce power/area...\n");
		print_cell_area();
		design->downsize_for_area_by_instances();
		print_cell_area();
	}
	else if (strcmp(method, "minimum") == 0) {
		printf("...set all cells at minimum size...\n");
		design->resize_to_minimum();
	}
	else if (strcmp(method, "maximum") == 0) {
		printf("...set all cells at maximum size...\n");
		design->resize_to_maximum();
	}
	else {
		printf("unknown resize method \"%s\"\n", method);
		printf("...supported methods:\n");
		printf("	<default>		... I-III by clones\n");
		printf("	instances		... I-III by instance\n");
		printf("	thresholds		... I	by clones\n");
		printf("	downsize		... II	by clones\n");
		printf("	optimize_path		... III by clones\n");
		printf("	for_area		... IV	by clones\n");
		printf("	thresholds_by_instances	... I	by instance\n");
		printf("	downsize_by_instances	... II	by instance\n");
		printf("	optimize_path_by_instances.. III by instance\n");
		printf("	for_area_by_instances	... IV	by instances\n");
		printf("	minimum\n");
		printf("	maximum\n");

		return RC_FAILED;
	}

	printf("\n...resize complete!\n");		
	// print_resizes();
	write_resizes_tcl("resizes.tcl");
	printf("...wrote \"resizes.tcl\"\n");
		
	printf("...computing long path\n");
	design->global_timing();
	print_long_path();

	printf("...instance size adjustment complete\n");
	return RC_NOMINAL;
}

rc_t
set_size(char *instancename, char *new_sizestr)
{
	INSTANCE *instance = design->get_instance(instancename);
	if (instance == NULL) {
		printf("instance \"%s\" not found\n", instancename);
		return RC_FAILED;
	}
	
	char new_size = new_sizestr[0];
	ListOfCELL *cl = instance->cell->functiongroup->celllist;
	while (cl != NULL) {
		if (cl->cell->size == new_size) {
			instance->change_cell(cl->cell);
			return RC_NOMINAL;
		}
		cl = cl->next;
	}
	
	printf("cell \"%s\" has no equivalent size '%c'\n", instance->cell->name, new_size);
	return RC_FAILED;
}		

rc_t
compare_saved_cell_pointers() 
{
	ListOfINSTANCE *il = design->instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		if (instance->cell != instance->saved_cell) {
			printf("%s is %s saved %s\n", instance->get_name(), instance->cell->name, instance->saved_cell->name);
		}
	}

	return RC_NOMINAL;		
}


rc_t
compare_nominal_cell_pointers() 
{
	ListOfINSTANCE *il = design->instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		if (instance->cell != instance->clone->nominal_cell) {
			printf("%s is %s nominal %s\n", instance->get_name(), instance->cell->name, instance->clone->nominal_cell->name);
		}
	}

	return RC_NOMINAL;		
}

rc_t
write_resizes_tcl(char *filename)
{
	design->collect_clones();

	FILE *f = fopen(filename, "w");
	if (f == NULL) {
		printf("open file \"%s\" failed errno %d\n", filename, errno);
		return RC_FAILED;
	}
	
	int counter = 0;
	ListOfCLONE *cl = design->resized_clonelist;
	while (cl != NULL) {
		CLONE* clone = cl->clone;
		cl = cl->next;

		INSTANCE *typical_instance = clone->instancelist->instance;
		fprintf(f, "load_resize %s	%s	%c\n",
		    clone->parent_cellname, clone->name, 
		    typical_instance->cell->size);		
		counter++;
	}

	fclose(f);
	printf("... %d resized clones written to file\n", counter);
	return RC_NOMINAL;
}

int MAX_PASSES = 50;
int MAX_PATHS = 20;

rc_t
try_slopes(char *min_str, char *max_str, char *delta_str, char *option)
{
	float min_slope;
	int rv = sscanf(min_str, "%f", &min_slope);
	if (rv != 1) {
		printf("can't convert \"%s\" to float for min_slope\n", min_str);
		return RC_FAILED;
	}
	if (min_slope <= 0.0 || min_slope > 1.000) {
		printf("min_slope %f out of reasonable range\n", min_slope);
		return RC_FAILED;
	}

	float max_slope;
	rv = sscanf(max_str, "%f", &max_slope);
	if (rv != 1) {
		printf("can't convert \"%s\" to float for max_slope\n", max_str);
		return RC_FAILED;
	}
	if (max_slope <= 0.0 || max_slope > 1.000) {
		printf("max_slope %f out of reasonable range\n", max_slope);
		return RC_FAILED;
	}

	float slope_delta;
	rv = sscanf(delta_str, "%f", &slope_delta);
	if (rv != 1) {
		printf("can't convert \"%s\" to float for slope_delta\n", delta_str);
		return RC_FAILED;
	}
	if (slope_delta <= 0.0 || slope_delta > 1.000) {
		printf("slope_delta %f out of reasonable range\n", slope_delta);
		return RC_FAILED;
	}
	float favorite_slope = 0.0;
	float best_average = FLT_MAX;

	if (strcmp(option, "thresholds") == 0) {

		printf("try resize by thresholds by clones from %.3f to %.3f by %.3f increments\n",
		    min_slope, max_slope, slope_delta);
		printf("\nslope		average long path delay		area\n");				
		CELL_AREA_INFO area_info;
	
		float working_slope = min_slope;
		int i;
		for (i = 0; i < MAX_PASSES; i++) {
			target_slope = working_slope;
			cell_library->compute_thresholds(working_slope, compute_thresholds_use_limit_method);
			design->resize_instances_by_threshold();
			design->global_timing();
			// float long_path_delay = design->global_downstream->long_delay;

			ListOfPATH *pl = design->global_downstream->get_long_pathlist(MAX_PATHS);
			int npaths = 0;		
			float total_delay = 0.0;
			while (pl != NULL) {
				PATH *path = pl->path;
				pl = pl -> next;
				npaths++;
				total_delay += path->absolute_delay;
			}
			float average_delay = total_delay / npaths;
		
			if (average_delay < best_average) {
				best_average = average_delay;
				favorite_slope = working_slope;
			}
				
			area_info.figure();
			printf("%.3f		%.3f				%.0f\n", working_slope, average_delay, area_info.resizeable_area);
	
			working_slope += slope_delta;
			if (working_slope > max_slope)	break;
		}
		if (i >= MAX_PASSES)	printf("...%d passes is enough, gonna break it off....\n", MAX_PASSES);
	}

	else if (strcmp(option, "optimize") == 0) {

		printf("try resize I-III by clones from %f to %f by %f increments\n",
		    min_slope, max_slope, slope_delta);
		CELL_AREA_INFO area_info;
		area_info.figure();
		printf("...initial resizeable area %.0f\n", area_info.resizeable_area);				

		printf("\n");
		printf("        I                 II                III\n");
		printf("slope   lp     area       lp     area       lp     area\n");				
	
		float slope = min_slope;
		float I_lp;
		float I_area;
		float II_lp;
		float II_area;
		float III_lp;
		float III_area;

		int i;
		for (i = 0; i < MAX_PASSES; i++) {

			target_slope = slope;
			cell_library->compute_thresholds(slope, compute_thresholds_use_limit_method);

			design->resize_clones_by_threshold();
			design->global_timing();
			I_lp = design->global_downstream->long_delay;
			area_info.figure();
			I_area = area_info.resizeable_area;	
			
			design->try_to_downsize_clones();
			design->global_timing();
			II_lp = design->global_downstream->long_delay;
			area_info.figure();
			II_area = area_info.resizeable_area;	

			design->optimize_long_path_by_clones();
			design->global_timing();
			III_lp = design->global_downstream->long_delay;
			area_info.figure();
			III_area = area_info.resizeable_area;	

			if (III_lp < best_average) {
				best_average = III_lp;
				favorite_slope = slope;
			}
				
			printf("%.3f	%.3f	%.0f	%.3f	%.0f	%.3f	%.0f\n", 
			    slope, I_lp, I_area, II_lp,	II_area, III_lp, III_area);

			slope += slope_delta;
			if (slope > max_slope)	break;
		}
	
		if (i >= MAX_PASSES)	printf("...%d passes is enough, gonna break it off....\n", MAX_PASSES);
	}
	
	else if (strcmp(option, "all") == 0) {

		printf("try resize I-IV by clones from %f to %f by %f increments\n",
		    min_slope, max_slope, slope_delta);
		CELL_AREA_INFO area_info;
		area_info.figure();
		printf("...initial resizeable area %.0f\n", area_info.resizeable_area);				

		printf("\n");
		printf("        I                 II                III               IV\n");
		printf("slope   lp     area       lp     area       lp     area       lp     area\n");				
	
		float slope = min_slope;
		float I_lp;
		float I_area;
		float II_lp;
		float II_area;
		float III_lp;
		float III_area;
		float IV_lp;
		float IV_area;
		
		int i;
		for (i = 0; i < MAX_PASSES; i++) {

			target_slope = slope;
			cell_library->compute_thresholds(slope, compute_thresholds_use_limit_method);

			design->resize_clones_by_threshold();
			design->global_timing();
			I_lp = design->global_downstream->long_delay;
			area_info.figure();
			I_area = area_info.resizeable_area;	
			
			design->try_to_downsize_clones();
			design->global_timing();
			II_lp = design->global_downstream->long_delay;
			area_info.figure();
			II_area = area_info.resizeable_area;	

			design->optimize_long_path_by_clones();
			design->global_timing();
			III_lp = design->global_downstream->long_delay;
			area_info.figure();
			III_area = area_info.resizeable_area;	

			design->downsize_for_area_by_clones();
			design->global_timing();
			IV_lp = design->global_downstream->long_delay;
			area_info.figure();
			IV_area = area_info.resizeable_area;	

			if (IV_lp < best_average) {
				best_average = IV_lp;
				favorite_slope = slope;
			}
				
			printf("%.3f	%.3f	%.0f	%.3f	%.0f	%.3f	%.0f	%.3f	%.0f\n", 
			    slope, I_lp, I_area, II_lp,	II_area, III_lp, III_area, IV_lp, IV_area);

			slope += slope_delta;
			if (slope > max_slope)	break;
		}
	
		if (i >= MAX_PASSES)	printf("...%d passes is enough, gonna break it off....\n", MAX_PASSES);
	}
	
	else {
		printf("what option??? \"thresholds\" or \"all\"\n");
		return RC_FAILED;
	}

	sprintf(tstr, "%f", favorite_slope);
	speedy2tcl_setvar("recommended_target_slope", tstr);
	return RC_NOMINAL;
}

rc_t
optimize_saved_path() 
{
	if (design->saved_path == NULL) {
		printf("no saved path\n");
		return RC_FAILED;
	}

	int upsize_count;
	int downsize_count;

	rc_t rc = design->optimize_path_by_clones(design->saved_path,
	    &upsize_count, &downsize_count);

	char *rcstr;
	switch (rc) {

	    case RC_IMPROVED:		
		rcstr = "RC_IMPROVED";		
		break;

	    case RC_NOIMPROVEMENT:	
		rcstr = "RC_NOIMPROVEMENT";	
		break;

	    default:			
		rcstr = "???";		
		break;
	}
	printf("...returned %s upsize_count %d downsize_count %d\n",
	    rcstr, upsize_count, downsize_count);

	return RC_NOMINAL;
}


rc_t
summarize_resized_instances()
{
	float resizeable_area = 0.0;
	int upsize_count = 0;
	int downsize_count = 0;

	ListOfINSTANCE *il = design->instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		// XXX ... i forget what the "there aren't any" case does ....
		if (instance->cell->functiongroup != NULL			&&
		    instance->cell->functiongroup->celllist != NULL		&&
		    instance->cell->functiongroup->celllist->next != NULL	) {
			resizeable_area += instance->cell->area;
		}

		if (instance->cell != instance->clone->nominal_cell) {
			if (instance->cell->size > instance->clone->nominal_cell->size) {
				upsize_count++;
			}
			else {
				downsize_count++;
			}
		}
	}
	
	printf("%d instances upsized, %d downsized, total area now %e\n", upsize_count, downsize_count, resizeable_area);
	print_cell_area();
	return RC_NOMINAL;
}

rc_t
count_resized_instances_by_type()
{
	// see "count_cell_types()" above

	printf("for each resizeable cell type, give the number of instances in the original design\n");
	printf("  and the number that have been resized, and if not zero,\n");
	printf("  followed by the number of times it was resized to each size\n");

	ListOfFUNCTIONGROUP *fgl = cell_library->functiongrouplist;
	while (fgl != NULL) {
		FUNCTIONGROUP *functiongroup = fgl->functiongroup;
		fgl = fgl->next;
	
		ListOfCELL *cl = functiongroup->celllist;
		while (cl != NULL) {
			CELL *cell = cl->cell;
			cl = cl->next;

			int total_count = 0;
			int resized_count = 0;
			int A_count = 0;
			int B_count = 0;
			int C_count = 0;
			int D_count = 0;
			int E_count = 0;

			ListOfINSTANCE *il = design->instancelist;
			while (il != NULL) {
				INSTANCE *instance = il->instance;
				il = il->next;

				if (instance->cell->size == ' ')		continue;
				if (instance->clone->nominal_cell != cell)	continue;

				total_count++;

				if (instance->clone->nominal_cell == instance->cell)	continue;

				resized_count++;
				switch (instance->cell->size) {
				    case 'A':	A_count++;	break;
				    case 'B':	B_count++;	break;
				    case 'C':	C_count++;	break;
				    case 'D':	D_count++;	break;
				    case 'E':	E_count++;	break;
				    default:	printf("unknown size??? '%c'\n", instance->cell->size);	break;
				}
			}

			printf("%d	%d	%s\n", total_count, resized_count, cell->name);
			if (resized_count != 0) {
				printf("	to A: %d	to B: %d	to C: %d	to D: %d	to E: %d\n",
				    A_count, B_count, C_count, D_count, E_count);
			}
		}
	}
	return RC_NOMINAL;
}

rc_t
clear_resizes()
{
	delete design->resized_clonelist;
	design->resized_clonelist = NULL;
	return RC_NOMINAL;
}

rc_t
print_resizes()
{
	design->collect_clones();

	printf("cell		instance	nominal cell	new cell\n");

	int counter = 0;
	ListOfCLONE *cl = design->resized_clonelist;
	while (cl != NULL) {
		CLONE* clone = cl->clone;
		cl = cl->next;

		INSTANCE *typical_instance = clone->instancelist->instance;
		printf("%s	%s	%s	-> %s\n",
		    clone->parent_cellname, clone->name, 
		    clone->nominal_cell->name,
		    typical_instance->cell->name);		
		counter++;
	}

	printf("... %d resized clones\n", counter);
	return RC_NOMINAL;
}


rc_t
remove_all_buffers()
{
	if (::buffer_cell == NULL) {
		printf("buffer cell is not declared\n");
		return RC_FAILED;
	}

	FUNCTIONGROUP *buffer_fg = ::buffer_cell->functiongroup;

	ListOfCLONE *cl = design->clonelist;
	while (cl != NULL) {
		CLONE *clone = cl->clone;
		cl = cl->next;

		// printf("clone %x cell %s\n", clone, clone->instancelist->instance->cell->name);
		if (clone->nominal_cell->functiongroup == buffer_fg) {
			ListOfINSTANCE *il = clone->instancelist;
			while (il != NULL) {
				INSTANCE *buffer = il->instance;
				il = il->next;

				NET *net = buffer->outportlist->outport->net;
				net->remove_buffer();
			}
		}
	}

	::design->complete_initialization();
	return RC_NOMINAL;
}


rc_t
insert_buffers(char *arg1)
{
	if (::buffer_cell == NULL) {
		printf("buffer cell is not declared\n");
		return RC_FAILED;
	}

	// see note on buffer insertion in commands.cc at definition
	// of ::buffer_insertion_threshold_slope
	// ... fearlessly assume that ::buffer_cell is the honest,
	// simple thing: one input, one output, one timing arc.


	if (::do_buffer_insertion == false) {
		printf("warning, actual buffer insertion is disabled\n");
	}

	// ... go find those slow nodes
	float restore_maximum_desireable_slope = ::maximum_desireable_slope;
	::maximum_desireable_slope = ::buffer_insertion_threshold_slope;
	printf("buffer insertion threshold slope %.3f\n", ::buffer_insertion_threshold_slope);
	ListOfPATHELEMENT *slow_nodes_pel = ::design->global_downstream->get_slow_nodes();
	if (slow_nodes_pel == NULL) printf("no slow nodes found\n");

	ListOfPATHELEMENT *pel = slow_nodes_pel;
	while (pel != NULL) {
		PATHELEMENT *slow_pe = pel->pathelement;
		pel = pel->next;
		
		NET *net = slow_pe->outport->net;
		float actual_load_cap = net->source->load_capacitance;
		CELL *driver_cell = net->source->instance->cell;
		if (actual_load_cap < driver_cell->max_capacitance)	continue;

		printf("original slope %.3f net %s driver type %s\n", slow_pe->slope_at_outport, net->get_name(), net->source->instance->cell->name);
		if (driver_cell == ::buffer_cell	||
		    driver_cell == ::inverter_cell	) { 
			if (::split_nets_during_add_buffers == true	&&
			    ::do_buffer_insertion == true		) {
				net->split_net_for_parallel_drivers();
			} 
			else {
				printf("....net %s driver needs a bufer/inverter in parallel\n", net->get_name());
			}
			continue;
		}
		else {
			if (::do_buffer_insertion == true) 	net->insert_buffer();		
		}
	}

	::design->complete_initialization();
	maximum_desireable_slope = restore_maximum_desireable_slope;
	if (slow_nodes_pel != NULL)	delete slow_nodes_pel;
	return RC_NOMINAL;
}


rc_t
change_cell_command(char *instancename, char *cellname) {

	INSTANCE *instance = design->get_instance(instancename);
	if (instance == NULL) {
		printf("instance \"%s\" not found\n", instancename);
		return RC_FAILED;
	}

	CELL *new_cell = cell_library->get_cell(cellname);
	if (new_cell == NULL) {
		printf("cell \"%s\" not found\n", cellname);
		return RC_FAILED;
	}

	if (new_cell->functiongroup != instance->cell->functiongroup) {
		printf("new cell \"%s\" is different functiongroup than existing cell \"%s\"\n", 
		    new_cell->name, instance->cell->name);
		return RC_FAILED;
	}

	instance->change_cell(new_cell);

	return RC_NOMINAL;
}

rc_t
print_cells_by_area()
{
	if (cell_library == NULL) {
		printf("cell library not installed\n");
		return RC_FAILED;
	}

	ListOfCELL *cl = ::cell_library->by_area_celllist;
	while (cl != NULL) {
		CELL *cell = cl->cell;
		cl = cl->next;

		printf("cell \"%s\"	area %.3f\n", cell->name, cell->area);
	}

	return RC_NOMINAL;
}

rc_t
print_buffer_trees()
{
	if (::buffer_cell == NULL) {
		printf("buffer cell is not declared\n");
		return RC_FAILED;
	}


	FUNCTIONGROUP *bufferfg = ::buffer_cell->functiongroup;

	ListOfCLONE *cl = design->clonelist;
	while (cl != NULL) {
		CLONE *clone = cl->clone;
		cl = cl->next;

		if (clone->nominal_cell->functiongroup != bufferfg)	continue;

		ListOfINSTANCE *il = clone->instancelist;
		while (il != NULL) {
			INSTANCE *buffer = il->instance;
			il = il->next;

			ListOfINPORT *ipl = buffer->outportlist->outport->net->inportlist;
			while (ipl != NULL) {
				INSTANCE *following = ipl->inport->instance;
				ipl = ipl->next;

				if (following->cell->functiongroup != bufferfg)	continue;

				printf("%s %s	drives	%s %s\n", buffer->cell->name, buffer->get_name(), 
				    following->cell->name, following->get_name());
			}
		}
	}
	return RC_NOMINAL;
}
		



//////////////////////////////////////////////////////////////////////

void
resize_help()
{
	printf("... resizing\n");
	printf("    variables for set/print...\n");
	printf("	target_slope ... synonym \"slope\"\n");
	printf("	upsize_threshold\n");
	printf("	limit_method ... synonym compute_thresholds_use_limit_method\n");
	printf("	downsize_threshold\n");
	printf("	minimum_desireable_slack\n");
	printf("	maximum_desireable_slope\n");
	printf("	allow_upsize_for_optimize\n");
	printf("	allow_downsize_on_critical_path_for_optimize\n");		printf("	allow_swap_inports_for_optimize\n");
	printf("	downsize_unloaded_instances\n");
	printf("	add_buffers_during_path_optimization\n");
	printf("    other things to print...\n");
	printf("	resizes\n");
	printf("	thresholds\n");
	printf("	slow_nodes\n");
	printf("commands:\n");
	printf("resize <option>		... available options:\n");
	printf("	<default>		... I-III by clones\n");
	printf("	instances		... I-I by instances, III by clones\n");
	printf("	thresholds		... I by clones\n");
	printf("	downsize		... II by clones\n");
	printf("	optimize_path		... III by clones\n");
	printf("	for_area		... IV by clones\n");
	printf("	thresholds_by_instances	... I by instances\n");
	printf("	downsize_by_instances	... II by instances\n");
	printf("	for_area_by_instancess	... IV by instances\n");
	printf("	minimum\n");
	printf("	maximum\n");
	printf("remove_all_buffers\n");
	printf("insert_buffers\n");
	printf("downsize_instance_for_area <instance_name>\n");
	printf("set_size <instancename> <size>\n");

	printf("select_target_slope		... synonym for \"try_slopes .010 .200 .005 thresholds\"\n");
	printf("try_slopes <min> <max> <delta> thresholds	... I by clones for various target_slopes\n");
	printf("	   <min> <max> <delta> optimize		... I-III by clones\n");
	printf("	   <min> <max> <delta> all		... I-IV by clones\n");
	printf("optimize_saved_path\n");
	printf("summarize_resized_instances\n");
	printf("count_resized_instances_by_type\n");
	printf("clear_resizes\n");
	printf("collect_clones\n");
	printf("write_resizes_tcl <filename>\n");
	printf("save_cell_pointers\n");
	printf("compare_saved_cell_pointers\n");
	printf("restore_saved_cell_pointers\n");
	printf("restore_nominal_cells\n");
	printf("profile_slack\n");
	printf("\n");

}



rc_t
resize_do_something(BOOLEAN executing_command_file, char *cmd, char *arg1, char *arg2, char *arg3, char *arg4)
{
	if (strcmp(cmd, "resize") == 0) {
		return resize(arg1);
	}

	if (strcmp(cmd, "set_size") == 0) {
		return set_size(arg1, arg2);
	}

	if (strcmp(cmd, "select_target_slope") == 0) {
		return try_slopes("0.010", "0.200", "0.005", "thresholds");
	}

	if (strcmp(cmd, "try_slopes") == 0) {
		return try_slopes(arg1, arg2, arg3, arg4);
	}

	if (strcmp(cmd, "remove_all_buffers") == 0) {
		return remove_all_buffers();
	}

	if (strcmp(cmd, "insert_buffers") == 0) {
		return insert_buffers(arg1);
	}

	if (strcmp(cmd, "optimize_saved_path") == 0) {
		return optimize_saved_path();
	}

	if (strcmp(cmd, "summarize_resized_instances") == 0) {
		return summarize_resized_instances();
	}

	if (strcmp(cmd, "count_resized_instances_by_type") == 0) {
		return count_resized_instances_by_type();
	}

	if (strcmp(cmd, "clear_resizes") == 0) {
		return clear_resizes();
	}

	if (strcmp(cmd, "collect_clones") == 0) {
		return design->collect_clones();
	}

	if (strcmp(cmd, "write_resizes_tcl") == 0) {
		return write_resizes_tcl(arg1);
	}

	if (strcmp(cmd, "downsize_for_area") == 0	||
	    strcmp(cmd, "downsize_for_area_by_clones") == 0	) {
		return design->downsize_for_area_by_clones();
	}

	if (strcmp(cmd, "downsize_for_area_by_instances") == 0) {
		return design->downsize_for_area_by_instances();
	}

	if (strcmp(cmd, "downsize_instance_for_area") == 0) {
		return design->downsize_for_area(arg1);
	}

	if (strcmp(cmd, "save_cell_pointers") == 0) {
		return design->save_cell_pointers();
	}

	if (strcmp(cmd, "compare_saved_cell_pointers") == 0) {
		return compare_saved_cell_pointers();
	}

	if (strcmp(cmd, "restore_saved_cell_pointers") == 0) {
		return design->restore_saved_cell_pointers();
	}

	if (strcmp(cmd, "restore_nominal_cells") == 0) {
		return design->restore_nominal_cells();
	}

	if (strcmp(cmd, "change_cell") == 0) {
		return change_cell_command(arg1, arg2);
	}

	if (strcmp(cmd, "profile_slack") == 0) {
		return design->profile_slack_by_instances(arg1);
	}

	if (strcmp(cmd, "compute_thresholds") == 0) {
		printf("computing thresholds from lib file...\n");
		return cell_library->compute_thresholds(target_slope, 
		    compute_thresholds_use_limit_method);	
	}

	return RC_NOTFOUND;
}
