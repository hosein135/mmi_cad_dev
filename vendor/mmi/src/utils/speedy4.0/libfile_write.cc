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

CELL *
CELL_LIBRARY::design2cell() { 
	float save_cap_fudge = ::cap_fudge;
	::cap_fudge = 0.0;
	float save_target_slope = ::target_slope;
 
	// ... create the cell ... make IN/OUTPINs from EXTCONNs
	CELL *top_cell = new CELL(::top_level_cellname, CELLTYPE_BASIC);
	ListOfEXTCONN *el = ::design->extconnlist;
	CELL *input_cell = ::cell_library->get_cell("external_in");
	CELL *output_cell = ::cell_library->get_cell("external_out");
	while (el != NULL) {
		EXTCONN *extconn = el->extconn;
		el = el->next;

		if (extconn->cell == input_cell) {
			INPIN *inpin = top_cell->add_inpin(extconn->get_name());
			inpin->capacitance = extconn->outportlist->outport->load_capacitance;
		}
		else if (extconn->cell == output_cell)	top_cell->add_outpin(extconn->get_name());
		else 	printf("design2cell: don't recognize extconn cell name \"%s\"\n", extconn->cell->name);
	}

	// ... make sure pipes are clear...
	rc_t rc = ::design->global_timing();
	if (rc != RC_NOMINAL) {
		printf("design2cell: global timing failed???\n");
		return NULL;
	}
	::design->clear_instance_pathlists();

	// find the clock pin 
	// ... assume it's called "clk" ...
	// ... if we can't find it, let it be NULL & figure it out on the other side ...
	INPIN *clk_pin = top_cell->get_inpin("clk");
	if (clk_pin == NULL) {
		printf("WARNING: no \"clk\" pin found.......\n");
	}

	// for each root instance, find the set of paths which are 
	// the long paths from itself to each path destination (latch or output).
	DOWNSTREAM *ds = new DOWNSTREAM();
	ListOfINSTANCE *rootlist = ::design->global_downstream->root_instancelist;
	while (rootlist != NULL) {
		INSTANCE *rootinstance = rootlist->instance;
		rootlist = rootlist->next;

		ds->init();
		ListOfINSTANCE *root_instancelist = new ListOfINSTANCE(rootinstance, NULL);
		ds->get_downstream_instances(root_instancelist);	// ... construct ds->pathlist
		ds->compute_timing();					// ... link pathelements into path
		if (ds->pathlist == NULL)	rootinstance->pathlist = NULL;	
		else {
			rootinstance->pathlist = new ListOfPATH(*ds->pathlist);	// copy ....
		}

		delete ds->root_instancelist; ds->root_instancelist = NULL;
	}
	delete ds;

	// ... convert the pathlist to timings
	rootlist = ::design->global_downstream->root_instancelist;
	while (rootlist != NULL) {
		INSTANCE *rootinstance = rootlist->instance;
		rootlist = rootlist->next;

		if (rootinstance->type == INPUT_EXTCONN_INSTANCETYPE) {
			INPIN *inpin = top_cell->get_inpin(rootinstance->get_name());

			// find the longpath to a D-edge to use in figuring setup (INPINTIMING)
			// look for paths to output EXTCONNS... each is an arc (OUTPINTIMING)
			// ....note... these are wrong paths to use to figure hold time...
			PATH *rising_setup_path = NULL;
			PATH *falling_setup_path = NULL;;
			ListOfPATH *pl = rootinstance->pathlist;
			while (pl != NULL) {
				PATH *path = pl->path;
				pl = pl->next;

				INSTANCE *dest_instance = path->destination_inport->instance;
				if (dest_instance->type == OUTPUT_EXTCONN_INSTANCETYPE) {
					// ... arc
					top_cell->add_timing_arc(inpin, path);	
				} 
				else {
					// ... setup
					if (path->final_pathelement->rising_at_outport == true) {
						if (rising_setup_path == NULL					||
						    path->absolute_delay > rising_setup_path->absolute_delay	) { 
							rising_setup_path = path;
						}
					} else {			
						if (falling_setup_path == NULL					||
						    path->absolute_delay > falling_setup_path->absolute_delay	) { 
							falling_setup_path = path;
						}
					}
				}
				
			}

			if (rising_setup_path != NULL	||
			    falling_setup_path != NULL)	{
				INPINTIMING *new_inpintiming = new INPINTIMING();
				new_inpintiming->related_inpin = clk_pin;
				inpin->inpintiming = new_inpintiming;
				if (rising_setup_path != NULL) {
					top_cell->add_timing_setup(new_inpintiming, rising_setup_path);
				}
				if (falling_setup_path != NULL) {
					top_cell->add_timing_setup(new_inpintiming, falling_setup_path);
				}
			}
		}
	}

	::target_slope = save_target_slope;
	::cap_fudge = save_cap_fudge;
	return top_cell;
};

rc_t
CELL::add_timing_arc(INPIN *inpin, PATH *path) {
	
	// construct a new timing by makeing a set of tables (...{rise|fall}{slope|delay}...)
	// taking the slope-transition values from the outpintiming at the root_instance
	// and the load-capacitance values from the outpintiming at the final_pathelement stage
	// for each pair of values,
	// stick them into the path and compute path timing
	// read the values at the destination and insert them into the tables.

	BOOLEAN is_rising_path = path->final_pathelement->rising_at_outport;

	OUTPINTIMING *final_outpintiming = path->final_pathelement->outpintiming;
	char *outpinname = path->destination_inport->instance->name;	// yes, the outpin is an inport...
	OUTPIN *outpin = get_outpin(outpinname);
	if (outpin == NULL)	printf("add_timing_arc: no outpin found for \"%s\"???\n", outpinname);
	float save_external_capacitance = path->destination_inport->inpin->capacitance;

	// walk backwards to find the origin... 
	// ... there is a sorta-dummy pe inside inports to hold the slope...
	//     it doesn't have an outpintiming, so we don't want that one, but the first "real" one ....
	// ... want to upgrade this so exconn *does* contain an outpintiming...
	PATHELEMENT *origin_pe = path->final_pathelement;
	while (origin_pe->previous != NULL	&&
	    origin_pe->previous->outpintiming != NULL)	{
		origin_pe = origin_pe->previous;
	}
	OUTPINTIMING *origin_outpintiming = origin_pe->outpintiming;

	// ... but when we set the slope, we want to do it on the *real* origin_pe
	if (origin_pe->previous != NULL) origin_pe = origin_pe->previous;

	OUTPINTIMING *new_outpintiming = new OUTPINTIMING(origin_outpintiming, final_outpintiming, is_rising_path);
	inpin->outpintiminglist = new ListOfOUTPINTIMING(new_outpintiming, inpin->outpintiminglist);
	outpin->outpintiminglist = new ListOfOUTPINTIMING(new_outpintiming, outpin->outpintiminglist);

	if (origin_outpintiming->sense == RISING_EDGE) {
		new_outpintiming->sense = RISING_EDGE;
	} 
	else {
		if (path->final_pathelement->rising_at_outport == origin_pe->rising_at_outport) {
			new_outpintiming->sense = POSITIVE_SENSE;
		} else {
			new_outpintiming->sense = NEGATIVE_SENSE;
		}
	}

	new_outpintiming->related_inpin = inpin;
	new_outpintiming->outpin = outpin;
	
	LUTABLE *delay_lutable;
	LUTABLE *transition_lutable;
	if (is_rising_path == true) {
		delay_lutable = new_outpintiming->cell_rise;
		transition_lutable = new_outpintiming->rise_transition;
	} else {
		delay_lutable = new_outpintiming->cell_fall;
		transition_lutable = new_outpintiming->fall_transition;
	}

	// .... vary over all entries in the table
	LUTABLE *lut = new_outpintiming->cell_rise;	// ... template 
	if (lut == NULL)	lut = new_outpintiming->cell_fall;

	for (int ix_1 = 0; ix_1 < lut->index_1_size; ix_1++) {		// external load
		for (int ix_2 = 0; ix_2 < lut->index_2_size; ix_2++) {	// input transition

			// ... for this entry, enter table parameters in the path		
			path->destination_inport->inpin->capacitance = lut->index_1[ix_1];
			path->destination_inport->net->compute_net_characteristics();
			origin_pe->slope_at_outport = lut->index_2[ix_2];

			// ... compute result and store in new OUTPINTIMING
			path->compute_complete_path();
			delay_lutable->put_value(ix_1, ix_2, path->absolute_delay);
			transition_lutable->put_value(ix_1, ix_2, path->final_pathelement->slope_at_outport);
		}
	} 

	path->destination_inport->inpin->capacitance = save_external_capacitance;
	path->destination_inport->net->compute_net_characteristics();
	return RC_NOMINAL;
}


OUTPINTIMING::OUTPINTIMING(OUTPINTIMING *index_1_prototype, OUTPINTIMING *index_2_prototype, BOOLEAN is_rising_path)
    : outpin(NULL), related_inpin(NULL), related_pinname(NULL)
{
	LUTABLE *ix_1_luproto;
	if (index_1_prototype->cell_rise != NULL)	ix_1_luproto = index_1_prototype->cell_rise;	
	else						ix_1_luproto = index_1_prototype->cell_fall;	

	LUTABLE *ix_2_luproto;
	if (index_2_prototype->cell_rise != NULL)	ix_2_luproto = index_2_prototype->cell_rise;	
	else						ix_2_luproto = index_2_prototype->cell_fall;	

	int index_1_size = ix_1_luproto->index_1_size;
	int index_2_size = ix_2_luproto->index_2_size;

	if (is_rising_path == true) {
		cell_rise = new LUTABLE(index_1_size, index_2_size);
		cell_rise->variable_1 = strdup(ix_1_luproto->variable_1);
		cell_rise->variable_2 = strdup(ix_2_luproto->variable_2);

		rise_transition = new LUTABLE(index_1_size, index_2_size);
		rise_transition->variable_1 = strdup(ix_1_luproto->variable_1);
		rise_transition->variable_2 = strdup(ix_2_luproto->variable_2);

		for (int i = 0; i < index_1_size; i++) {
			float value = index_1_prototype->cell_rise->index_1[i];
			cell_rise->index_1[i] = value;
			rise_transition->index_1[i] = value;
		}
		for (int i = 0; i < index_2_size; i++) {
			float value = index_2_prototype->cell_rise->index_2[i];
			cell_rise->index_2[i] = value;
			rise_transition->index_2[i] = value;
		}

		cell_fall	= NULL;
		fall_transition = NULL;

	}
	else {
		cell_rise	= NULL;
		rise_transition = NULL;

		cell_fall	= new LUTABLE(index_1_size, index_2_size);
		cell_fall->variable_1 = strdup(ix_1_luproto->variable_1);
		cell_fall->variable_2 = strdup(ix_2_luproto->variable_2);

		fall_transition	= new LUTABLE(index_1_size, index_2_size);
		fall_transition->variable_1 = strdup(ix_1_luproto->variable_1);
		fall_transition->variable_2 = strdup(ix_2_luproto->variable_2);

		for (int i = 0; i < index_1_size; i++) {
			float value = index_1_prototype->cell_rise->index_1[i];
			cell_fall->index_1[i] = value;
			fall_transition	->index_1[i] = value;
		}
		for (int i = 0; i < index_2_size; i++) {
			float value = index_2_prototype->cell_rise->index_2[i];
			cell_fall->index_2[i] = value;
			fall_transition	->index_2[i] = value;
		}
	}
}

//////////////////////////////////////////////

rc_t
CELL::add_timing_setup(INPINTIMING *path_inpintiming, PATH *path)
{
	// same sort of thing as add_timing_arc...

	// the last timing is an INPINTIMING on the destination inport....
	INPIN *destination_inpin = path->destination_inport->inpin;
	INPINTIMING *final_inpintiming = destination_inpin->inpintiming;
	if (final_inpintiming == NULL) {
		printf("add_timing_setup: destination inpin has no inpintiming????\n");
		return RC_FAILED;
	}
	LUTABLE *final_setup_lutable;
	if (path->final_pathelement->rising_at_outport == true)	final_setup_lutable = final_inpintiming->setup_rise;
	else							final_setup_lutable = final_inpintiming->setup_fall;

	// if the inpin goes directly to a flipflop, we won't find an origin_pe->outpintiming;
	// but heck, we can just copy the final_setup_lutable .... add in extconn delay if applicable...
	if (path->final_pathelement->outpintiming == NULL) {
		LUTABLE *copy_lutable = new LUTABLE(*final_setup_lutable);

		INSTANCE *instance = path->final_pathelement->outport->instance;
		if (instance->type == INPUT_EXTCONN_INSTANCETYPE) {
			EXTCONN *extconn = (EXTCONN *)instance;
			float delay = extconn->delay;
			for (int i = 0; i < copy_lutable->values_size; i++) {
				copy_lutable->values[i] += delay;
			}
		}

		if (path->final_pathelement->rising_at_outport == true)	path_inpintiming->setup_rise = copy_lutable;
		else							path_inpintiming->setup_fall = copy_lutable;
		return RC_NOMINAL;
	}

	// walk backwards to find the origin... see notes in add_timing_arc
	PATHELEMENT *origin_pe = path->final_pathelement;
	while (origin_pe->previous != NULL	&&
	    origin_pe->previous->outpintiming != NULL)	{
		origin_pe = origin_pe->previous;
	}
	LUTABLE *origin_delay_lutable;
	if (origin_pe->rising_at_outport == true)	origin_delay_lutable = origin_pe->outpintiming->cell_rise;
	else						origin_delay_lutable = origin_pe->outpintiming->cell_fall;
	// ... and back up to exconn, as must be ....
	if (origin_pe->previous != NULL) origin_pe = origin_pe->previous;

	LUTABLE *setup_lutable = new LUTABLE(origin_delay_lutable, final_setup_lutable);
	if (origin_pe->rising_at_outport == true)	path_inpintiming->setup_rise = setup_lutable;
	else						path_inpintiming->setup_fall = setup_lutable;	

	// .... set size for new table & copy index values 
	// .... ix_1 (clk transistion) from final_setup_lutable ("related pin transition")
	// .... ix_2 ("D-edge" transition) from origin_delay_lutable ("input net transistion")
	setup_lutable->index_1_size = final_setup_lutable->index_1_size;
	setup_lutable->variable_1 = strdup(final_setup_lutable->variable_1);
	for (int ix_1 = 0; ix_1 < setup_lutable->index_1_size; ix_1++) {
		setup_lutable->index_1[ix_1] = final_setup_lutable->index_1[ix_1];
	}
	setup_lutable->index_2_size = origin_delay_lutable->index_2_size;
	setup_lutable->variable_2 = strdup(origin_delay_lutable->variable_2);
	for (int ix_2 = 0; ix_2 < setup_lutable->index_2_size; ix_2++) {
		setup_lutable->index_2[ix_2] = origin_delay_lutable->index_2[ix_2];
	}

	// .... characterize setup by calculating path delay 
	// .... vary over all entries in the new setup table
	for (int ix_1 = 0; ix_1 < setup_lutable->index_1_size; ix_1++) {		// "related pin" eg clk transition
		for (int ix_2 = 0; ix_2 < setup_lutable->index_2_size; ix_2++) {	// "constrained pin" eg data transition

			// ... for this entry, enter table parameters in the path		
			::target_slope = setup_lutable->index_1[ix_1];
			origin_pe->slope_at_outport = setup_lutable->index_2[ix_2];

			// ... compute result and store in new LUTABLE
			path->compute_complete_path();
			setup_lutable->put_value(ix_1, ix_2, path->absolute_delay);
		}
	}			

	return RC_NOMINAL;
}


LUTABLE::LUTABLE(LUTABLE *data_prototype, LUTABLE *clk_prototype)
{
	int index_1_size = clk_prototype->index_1_size;
	int index_2_size = data_prototype->index_2_size;

	for (int i = 0; i < index_1_size; i++) {
		index_1[i] = clk_prototype->index_1[i];
	}
	for (int i = 0; i < index_2_size; i++) {
		index_2[i] = data_prototype->index_2[i];
	}

	values_size = index_1_size * index_2_size;
}




////////////////////////////////////////////////////////////////////

rc_t
LIBFILE::write_cell_to_file(CELL *cell)
{
	f = fopen(name, "w");
	if (f == NULL)	{
		printf("can't open file \"%s\" for writing\n", name);
		return RC_FAILED;
	}

	// ... write library header
	fprintf(f, "library (%s) {\n", cell->name);
	fprintf(f, "comment:	written by Speedy write_libfile;\n");
	
	// ... write lu table templates
	ListOfLUTABLE *arc_lutablelist = NULL;
	ListOfLUTABLE *setup_lutablelist = NULL;
	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;

		INPINTIMING *inpintiming = inpin->inpintiming;
		if (inpintiming == NULL) continue;

		LUTABLE *	 lut = inpintiming->setup_rise;
		if (lut == NULL) lut = inpintiming->setup_fall;

		// same size in the setup list already?
		ListOfLUTABLE *ltl = setup_lutablelist;
		while (ltl != NULL) {
			LUTABLE *l = ltl->lutable;

			if (l->index_1_size == lut->index_1_size	&&
			    l->index_2_size == lut->index_2_size	) {
				break;
			}

			ltl = ltl->next;
		}
		if (ltl == NULL) {
			setup_lutablelist = new ListOfLUTABLE(lut, setup_lutablelist);
		}
	}

	ListOfOUTPIN *opl = cell->outpinlist;
	while (opl != NULL) {
		OUTPIN *outpin = opl->outpin;
		opl = opl->next;

		ListOfOUTPINTIMING *optl = outpin->outpintiminglist;
		while (optl != NULL) {
			OUTPINTIMING *outpintiming = optl->outpintiming;
			optl = optl->next;

			LUTABLE *	 lut = outpintiming->cell_rise;
			if (lut == NULL) lut = outpintiming->cell_fall;

			// same size in the setup list already?
			ListOfLUTABLE *ltl = arc_lutablelist;
			while (ltl != NULL) {
				LUTABLE *l = ltl->lutable;

				if (l->index_1_size == lut->index_1_size	&&
				    l->index_2_size == lut->index_2_size	) {
					break;
				}

				ltl = ltl->next;
			}
			if (ltl == NULL) {
				arc_lutablelist = new ListOfLUTABLE(lut, arc_lutablelist);
			}
		}

	}		

	ListOfLUTABLE *ltl = setup_lutablelist;
	while (ltl != NULL) {
		LUTABLE *lut = ltl->lutable;
		ltl = ltl->next;

		fprintf(f, "lu_table_template(cr%dx%d) {\n", lut->index_1_size, lut->index_2_size);
		fprintf(f, "	variable_1:	related_pin_transition;\n");
		fprintf(f, "	variable_2:	constrained_pin_transition;\n");

		fprintf(f, "	index_1 (\"0");
		for (int i = 1; i < lut->index_1_size; i++) {
			fprintf(f, ", %d", i);
		}
		fprintf(f, "\");");

		fprintf(f, "	index_2 (\"0");
		for (int i = 1; i < lut->index_2_size; i++) {
			fprintf(f, ", %d", i);
		}
		fprintf(f, "\");\n");

		fprintf(f, "}\n");
	}

	ltl = arc_lutablelist;
	while (ltl != NULL) {
		LUTABLE *lut = ltl->lutable;
		ltl = ltl->next;

		fprintf(f, "lu_table_template(li%dx%d) {\n", lut->index_1_size, lut->index_2_size);
		fprintf(f, "\tvariable_1:	total_output_net_capacitance;\n");
		fprintf(f, "\tvariable_2:	input_net_transition;\n");

		fprintf(f, "\tindex_1 (\"0");
		for (int i = 1; i < lut->index_1_size; i++) {
			fprintf(f, ", %d", i);
		}
		fprintf(f, "\");");

		fprintf(f, "\tindex_2 (\"0");
		for (int i = 1; i < lut->index_2_size; i++) {
			fprintf(f, ", %d", i);
		}
		fprintf(f, "\");\n");

		fprintf(f, "}\n");
	}

	if (setup_lutablelist)	delete setup_lutablelist;
	if (arc_lutablelist)	delete arc_lutablelist;

	// ... write cell header
	fprintf(f, "cell (%s) {\n", cell->name); 
	fprintf(f, "\tarea:	%.3f;\n", cell->area);

	// ... write input pins 
	BOOLEAN is_a_clkpin = false;
	ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;
	
		fprintf(f, "\tpin (%s) {\n", inpin->name);
		fprintf(f, "\t\tdirection: input;\n");
		fprintf(f, "\t\tcapacitance: %.3f;\n", inpin->capacitance);
		if (strcmp(inpin->name, "clk") == 0) {
			is_a_clkpin = true;
			fprintf(f, "\t\tclock: true;\n");
		}
	
 		INPINTIMING *ipt = inpin->inpintiming;
		if (ipt != NULL) {
			fprintf(f, "\t\ttiming () {\n");
			fprintf(f, "\t\t\ttiming_type:	setup_rising;\n");
			fprintf(f, "\t\t\trelated_pin:	\"clk\";\n");


			if (ipt->setup_rise != NULL) {
				LUTABLE *lut = ipt->setup_rise;
				fprintf(f, "\t\t\trise_constraint(cr%dx%d) {\n", lut->index_1_size, lut->index_2_size);
				write_lutable(lut);
				fprintf(f, "\t\t\t}\n");	// ... end of setup_rise
			}

			if (ipt->setup_fall != NULL) {
				LUTABLE *lut = ipt->setup_fall;
				fprintf(f, "\t\t\tfall_constraint(cr%dx%d) {\n", lut->index_1_size, lut->index_2_size);
				write_lutable(lut);
				fprintf(f, "\t\t\t}\n");	// ... end of setup_fall
			}

			fprintf(f, "\t\t}\n");	// ... end of timing
		}
		fprintf(f, "\t}\n");	// ... end of pin
	}

	// ... make sure there's a clock pin
	if (is_a_clkpin == false) {
		fprintf(f, "\t# dummy clock pin added\n");
		fprintf(f, "\tpin (clk) {\n");
		fprintf(f, "\t\tdirection: input;\n");
		fprintf(f, "\t\tcapacitance: 0.0;\n");
		fprintf(f, "\t\tclock: true;\n");
		fprintf(f, "\t}\n");	// ... end of pin
	}
	
	// ... write output pins 
	opl = cell->outpinlist;
	while (opl != NULL) {
		OUTPIN *outpin = opl->outpin;
		opl = opl->next;
	
		fprintf(f, "\tpin (%s) {\n", outpin->name);
		fprintf(f, "\t\tdirection: output;\n");
	
		ListOfOUTPINTIMING *optl = outpin->outpintiminglist;
		while (optl != NULL) {
			OUTPINTIMING *opt = optl->outpintiming;
			optl = optl->next;
	
			fprintf(f, "\t\ttiming () {\n");
			switch (opt->sense) {
			    case POSITIVE_SENSE:
				fprintf(f, "\t\t\ttiming_sense: positive_unate;\n");
				break;
			    case NEGATIVE_SENSE:
				fprintf(f, "\t\t\ttiming_sense: negative_unate;\n");
				break;
			    case RISING_EDGE:
				fprintf(f, "\t\t\ttiming_sense: rising_edge;\n");
				break;
			    case FALLING_EDGE:
				fprintf(f, "\t\t\ttiming_sense: falling_edge;\n");
				break;
			    default:
				printf("write_cell_to_file: unknown timing sense???\n");
				fprintf(f, "\t\t\ttiming_sense: unknown_sense;\n");
				break;
			}

			fprintf(f, "\t\t\trelated_pin:	\"%s\";\n", opt->related_inpin->name);

			if (opt->cell_rise != NULL) {
				fprintf(f, "\t\t\tcell_rise(li%dx%d) {\n", opt->cell_rise->index_1_size, opt->cell_rise->index_2_size);
				write_lutable(opt->cell_rise);
				fprintf(f, "\t\t\t}\n");
			}
			if (opt->rise_transition != NULL) {
				fprintf(f, "\t\t\trise_transition(li%dx%d) {\n", opt->rise_transition->index_1_size, opt->rise_transition->index_2_size);
				write_lutable(opt->rise_transition);
				fprintf(f, "\t\t\t}\n");
			}
			if (opt->cell_fall != NULL) {
				fprintf(f, "\t\t\tcell_fall(li%dx%d) {\n", opt->cell_fall->index_1_size, opt->cell_fall->index_2_size);
				write_lutable(opt->cell_fall);
				fprintf(f, "\t\t\t}\n");
			}
			if (opt->fall_transition != NULL) {
				fprintf(f, "\t\t\tfall_transition(li%dx%d) {\n", opt->fall_transition->index_1_size, opt->fall_transition->index_2_size);
				write_lutable(opt->fall_transition);
				fprintf(f, "\t\t\t}\n");
			}

			fprintf(f, "\t\t}\n");	// ... end of timing
		}
		fprintf(f, "\t}\n");	// ... end of pin
	}

	fprintf(f, "}\n");	// ... end of cell
	fprintf(f, "}\n");	// ... end of library

	fclose(f);
	return RC_NOMINAL;
}




rc_t
LIBFILE::write_lutable(LUTABLE *lut) 
{
	fprintf(f, "\t\t\t\tindex_1(\"%.4f", lut->index_1[0]);
	for (int i = 1; i < lut->index_1_size; i++) {
		fprintf(f, ", %.4f", lut->index_1[i]);
	}
	fprintf(f, "\");\n");		

	fprintf(f, "\t\t\t\tindex_2(\"%.4f", lut->index_2[0]);
	for (int i = 1; i < lut->index_2_size; i++) {
		fprintf(f, ", %.4f", lut->index_2[i]);
	}
	fprintf(f, "\");\n");		

	fprintf(f, "\t\t\t\tvalues(\"%.4f", lut->values[0]);
	int values_size = lut->index_1_size * lut->index_2_size;
	for (int i = 1; i < values_size; i++) {
		fprintf(f, ", %.4f", lut->values[i]);
	}
	fprintf(f, "\");\n");		

	// format nicely so human can read

	fprintf(f, "\n//\t");
	for (int i = 0; i < lut->index_2_size; i++) {
		fprintf(f, "%.4f\t", lut->index_2[i]);
	}
	fprintf(f, "%s (ix_2)\n//\n", lut->variable_2);

	int values_ix = 0;
	for (int ix_1 = 0; ix_1 < lut->index_1_size; ix_1++) {
		fprintf(f, "//\t");

		for (int ix_2 = 0; ix_2 < lut->index_2_size; ix_2++) {
			fprintf(f, "%.4f\t", lut->values[values_ix++]);
		}

		fprintf(f, "...%.4f\t", lut->index_1[ix_1]);
		if (ix_1 == 0)	fprintf(f, "%s (ix_1)\n", lut->variable_1);
		else		fprintf(f, "\n");
	}
	fprintf(f, "\n");

	return RC_NOMINAL;
}

////////////////////////////////////////////////////////////////////////////
// hackware by Lee's specification to support his idea of icon_creator

rc_t
add_extconn_for_limited_icon_creator(char *name, char *io_type, char *proto_pinname, char *delay_str)
{
	// bus name?
	// BOOLEAN is_bus = parse_bus_name(name);

	// pinname expected to be like MMI_BUFE:out
	char *proto_cellname = proto_pinname;
	char *p = proto_cellname;
	while (1) {
		switch (*p) {
		    case ':':
			*p++ = 0;	
			break;

		    case '\0':
			printf("pin name must be like \"MMI_BUFE:out\"\n");
			return RC_FAILED;

		    default:
			p++;
			continue;
		}
		break;
	}
	char *proto_cell_pinname = p;

	CELL *proto_cell = ::cell_library->get_cell(proto_cellname);
	if (proto_cell == NULL) {
		printf("no such cell as \"%s\"\n", proto_cellname);
		return RC_FAILED;
	}

	float delay;
 	int rv = sscanf(delay_str, "%f", &delay);
 	if (rv != 1) {
 		printf("can't convert to float for delay: \"%s\"\n", delay_str);
 		return RC_FAILED;
 	}

	NET *clk_net = ::design->get_net("clk");
	if (clk_net == NULL) {
		clk_net = new NET("clk");		
		::design->netlist = new ListOfNET(clk_net, ::design->netlist);

		EXTCONN *clk_extconn = new EXTCONN("clk", INPUT_EXTCONN_INSTANCETYPE);
		clk_extconn->identify("external_in");
		::design->extconnlist = new ListOfEXTCONN(clk_extconn, ::design->extconnlist);

		OUTPORT *clk_source = clk_extconn->get_outport("in");
		clk_source->net = clk_net;
		clk_net->source = clk_source;			
	}

	// .... all OK....
	
	sprintf(tstr, "%s_%s", name, proto_cellname);
	INSTANCE *instance = new INSTANCE(tstr);
	instance->identify(proto_cell);
	EXTCONN *extconn;
	NET *net = new NET(name);

	if (strcmp(io_type, "input") == 0) {
		extconn = new EXTCONN(name, INPUT_EXTCONN_INSTANCETYPE);
		extconn->identify("external_in");

		INPORT *instance_inport = instance->get_inport(proto_cell_pinname);
		if (instance_inport == NULL) {
			printf("can't find pin \"%s\" on cell  \"%s\"\n", proto_cell_pinname, proto_cellname);
			return RC_FAILED;
		}
		if (instance_inport->inpin->inpintiming == NULL) {
			printf("pin \"%s:%s\" has no setup spec\n", proto_cellname, proto_pinname);
			return RC_FAILED;
		}
		instance_inport->net = net;
		net->inportlist = new ListOfINPORT(instance_inport, NULL);

		OUTPORT *extconn_outport = extconn->get_outport("in");
		extconn_outport->net = net;
		net->source = extconn_outport;

		INPORT *clk_inport = instance->get_inport("clk");
		if (clk_inport == NULL) {
			printf("can't find pin \"%s\" on cell \"%s\"????\n", "clk", proto_cellname);
		} else {
			clk_net->inportlist = new ListOfINPORT(clk_inport, clk_net->inportlist);
			clk_inport->net = clk_net;
		}
	}

	else if (strcmp(io_type, "output") == 0) {
		// clk_net -> ff -> ff_net -> instance -> net -> extconn

		extconn = new EXTCONN(name, OUTPUT_EXTCONN_INSTANCETYPE);
		extconn->identify("external_out");
		INPORT *extconn_inport = extconn->get_inport("out");
		extconn_inport->net = net;
		net->inportlist = new ListOfINPORT(extconn_inport, NULL);

		OUTPORT *instance_outport = instance->get_outport(proto_cell_pinname);
		if (instance_outport == NULL) {
			printf("can't find pin \"%s\" on cell  \"%s\"\n", proto_cell_pinname, proto_cellname);
			return RC_FAILED;
		}
		instance_outport->net = net;
		net->source = instance_outport;

		sprintf(tstr, "%s_%s_net", name, "MMI_FFB");
		NET *ff_net = new NET(tstr);

		INPORT *buffer_inport = instance->inportlist->inport;
		buffer_inport->net = ff_net;
		ff_net->inportlist = new ListOfINPORT(buffer_inport, NULL);

		sprintf(tstr, "%s_%s", name, "MMI_FFB");
		INSTANCE *ff_instance = new INSTANCE(tstr);
		ff_instance->identify("MMI_FFB");
		::design->instancelist = new ListOfINSTANCE(ff_instance, ::design->instancelist);

		OUTPORT *ff_q = ff_instance->get_outport("q");
		ff_q->net = ff_net;
		ff_net->source = ff_q;
		
		INPORT *ff_clk = ff_instance->get_inport("clk");
		ff_clk->net = clk_net;
		clk_net->inportlist = new ListOfINPORT(ff_clk, clk_net->inportlist);
	}

	else {
		printf("type \"%s\" must be \"input\" or \"output\", please\n", io_type);
		return RC_FAILED;
	}

	extconn->delay = delay;

	//////////////////////

	::design->extconnlist = new ListOfEXTCONN(extconn, ::design->extconnlist);
	::design->instancelist = new ListOfINSTANCE(instance, ::design->instancelist);
	::design->netlist = new ListOfNET(net, ::design->netlist);
	return RC_NOMINAL;
}

BOOLEAN
parse_bus_name(char *arg_name, int *fromix, int *toix)
{
	char *name = strdup(arg_name);
	char *p = name;
	char *fromstr;
	char *tostr;
	while (1) {
		switch (*p) {
		    default:	
			p++; 
			continue;

		    case '\0':	
			free(name); 
			return false;

		    case '[': {
			fromstr = p;
			while (1) {
				switch (*p) {
				    default: p++; continue;
	
				    case '\0':	
					printf("WARNING: badly formed net name \"%s\"\n", name);
					free(name);
					return false;
				
				    case ']':
					// never mind, it's a single bit after all
					free(name);
					return false;

				    case ':':
					*p++ = '\0';
					tostr = p;
					while (1) {
						switch (*p) {	
					
						    default: p++; continue;
	
						    case '\0':	
							printf("WARNING: badly formed net name \"%s\"\n", arg_name);
							free(name);
							return false;
				
						    case ']':
							// never mind, it's a single bit after all
							free(name);
							return false;

						    case ':':
							*p++ = '\0';
							tostr = p;
							while (1) {
								switch (*p) {	
					
								    default: p++; continue;
	
								    case '\0':	
									printf("WARNING: badly formed net name \"%s\"\n", arg_name);
									free(name);
									return false;

								    case ']':
									*p++ = '\0';
									break;
								}
								break;
							}
							break;
						}
						break;
					}
					break;
				}
				break;
			    } // end case '['
			}
			break;
		}
		break;
	}

	*fromix = strtol(fromstr, NULL, 10);
	*toix = strtol(tostr, NULL, 10);
	free(name);
	return true;
}

