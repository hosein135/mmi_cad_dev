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

CELL_LIBRARY::CELL_LIBRARY() 
	: celllist(NULL), functiongrouplist(NULL), 
	by_area_celllist(NULL),
	downsize_order_celllist(NULL)
{
	// // instead of EXTCONNs as special kind of INSTANCE,
	// // let's have an INSTANCE which is the interface...
	// // see EXTCONN class definition in design.h...
	// // ...
	// // as we discover EXTCONNs, we will create IN/OUTPINs
	// CELL *interface = new CELL("SPEEDY_interface");
	// interface->type = CELLTYPE_EXTCONN;

	// create special cells for EXTCONNs
	CELL *incell = new CELL("external_in", CELLTYPE_EXTCONN);
	incell->add_outpin("in");	// out of the extconn, into the world
	
	CELL *outcell = new CELL("external_out", CELLTYPE_EXTCONN);
	outcell->add_inpin("out");	// out of the world, into the extconn

	// and one to be the cell for instances for sources of nets that have no source
	CELL *dummycell = new CELL("dummy_source", CELLTYPE_DUMMYSOURCE);
	dummycell->add_outpin("dummy_source");	// out of the dummy, into the net

	celllist = // new ListOfCELL(interface, 
	   new ListOfCELL(incell, 
	   new ListOfCELL(outcell,
	   new ListOfCELL(dummycell, NULL)));
}

CELL_LIBRARY::~CELL_LIBRARY()
{
	ListOfCELL *cl = celllist;
	while (cl != NULL) {
		CELL *cell = cl->cell;
		cl = cl->next;
	
		delete cell;
	}
	if (celllist != NULL)			delete celllist;

	ListOfFUNCTIONGROUP *fgl = functiongrouplist;
	while (fgl != NULL) {
		FUNCTIONGROUP *functiongroup = fgl->functiongroup;
		fgl = fgl->next;

		delete functiongroup;
	}
	if (functiongrouplist != NULL) delete functiongrouplist;

	::buffer_cell = NULL;
	::inverter_cell = NULL;

	if (by_area_celllist != NULL)		delete by_area_celllist;
	if (downsize_order_celllist != NULL)	delete downsize_order_celllist;
}

rc_t
CELL_LIBRARY::sort_by_function(CELL *cell)
{
	// NOTE...
	// the logical function from the lib file "!(in0 & !in1)" doesn't
	// get it, unlike as you might think.  Latches all seem to be "IQ",
	// buffers are all "in" or "!in", etc.  So we have to decompose
	// the name, which is obviously very MMI specific.  Uck.
	// ... so "size" is the last character of the cell name, and 
	// what preceeds it is "function".  Check to see that 'size' is in
	// the range 'A' to 'E'.  We could still get into trouble, obviously,
	// but seems to work so far.

	// XXX ... really need to explicitly say what are the resizeable
	// functiongroups....

	char *functionstr = strdup(cell->name);
	char size = (cell->name)[strlen(cell->name) - 1];
	FG_FUNCTION function = FUNCTIONGROUP::lookup(cell->name);

	if (size >= 'A' && size <= 'E') {
		functionstr[strlen(cell->name) - 1] = '\0';
		cell->size = size;

		ListOfFUNCTIONGROUP *tll = functiongrouplist;
		while (tll != NULL) {
			FUNCTIONGROUP *functiongroup = tll->functiongroup;
			tll = tll->next;
	
			if (strcmp(functiongroup->functionstr, functionstr) == 0) {
				// ... this group, insert the cell in place, order of increasing size ...
	
				if (functiongroup->function != function	&&
				    speedy_verbose == true		) {
					printf("CELL_LIBRARY::sort_by_function: function mismatch, %s and group of %s...?\n",
					    cell->name, functiongroup->celllist->cell->name);
				}
				cell->functiongroup = functiongroup;
	
				if (cell->size < functiongroup->celllist->cell->size) {
					functiongroup->celllist = new ListOfCELL(cell, functiongroup->celllist);
				}
				else {	
					ListOfCELL *cl = functiongroup->celllist;
					while (cl->next != NULL) {
						if (cell->size < cl->next->cell->size)	break;
						cl = cl->next;
					}
	
					cl->next = new ListOfCELL(cell, cl->next);
				}
	
				cell->functiongroup = functiongroup;
				delete functionstr;
				return RC_NOMINAL;
			}
		}		
	}				
	else {
		// function is fine as it is
		cell->size = '-';
	}

	// ... not found, or not a valid size... new functiongroup ...
	FUNCTIONGROUP *new_functiongroup = new FUNCTIONGROUP(functionstr, cell);
	functiongrouplist = new ListOfFUNCTIONGROUP(new_functiongroup, functiongrouplist);
	cell->functiongroup = new_functiongroup;
	
	return RC_NOMINAL;
}

CELL *
CELL_LIBRARY::get_cell(char *arg_name)
{
	ListOfCELL *cl = celllist;
	while (cl != NULL) {
		CELL *cell = cl->cell;
		cl = cl->next;

		if (strcmp(cell->name, arg_name) == 0) return cell;
	}
	return NULL;
}

rc_t
CELL_LIBRARY::remove_cell(CELL *cell)
{
	// remove from celllist
	ListOfCELL *cl = celllist;
	if (cl->cell == cell) {
		celllist = celllist->next;
		cl->next = NULL;
		delete cl;
	}
	else {
		while (cl->next != NULL) {
			if (cl->next->cell == cell) break;
			cl = cl->next;
		}
		if (cl->next == NULL) {
			printf("remove cell: \"%s\" not found in celllist???\n", cell->name);
			return RC_FAILED;
		}
		ListOfCELL *tcl = cl->next;
		cl->next = cl->next->next;
		tcl->next = NULL;
		delete tcl;
	}

	// remove from functiongroup
	FUNCTIONGROUP *fg = cell->functiongroup;
	cl = fg->celllist;
	if (cl->cell == cell) {
		fg->celllist = fg->celllist->next;
		cl->next = NULL;
		delete cl;
	}
	else {
		while (cl->next != NULL) {
			if (cl->next->cell == cell) break;
			cl = cl->next;
		}
		if (cl->next == NULL) {
			printf("remove cell: \"%s\" not found in functiongrouplist???\n", cell->name);
		}
		else {
			ListOfCELL *tcl = cl->next;
			cl->next = cl->next->next;
			tcl->next = NULL;
			delete tcl;
		}
	}

	if (fg->celllist == NULL) {
		// ... cell was only member of functiongroup; now we have to delete the fg

		ListOfFUNCTIONGROUP *fgl = functiongrouplist;
		if (fgl->functiongroup == fg) {
			functiongrouplist = functiongrouplist->next;
			fgl->next = NULL;
			delete fgl;
		}
		else {
			while (fgl->next != NULL) {
				if (fgl->next->functiongroup == fg) break;
				fgl = fgl->next;
			}
			if (fgl->next == NULL) {
				printf("remove functiongroup: not found???\n");
				return RC_FAILED;
			}
			ListOfFUNCTIONGROUP *tfgl = fgl->next;
			fgl->next = fgl->next->next;
			tfgl->next = NULL;
			delete tfgl;
		}
	}

	// ... AND off the cell itself ...
	delete cell;

	return RC_NOMINAL;
};


//////////////////////////////////////////////////////////

void
DESIGN::clear_instance_pathlists() {

	// these are copy paths, so the pathelements are copies,
	// so we have to delete all that stuff.

	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		instance->clear_pathlist();
	}


	ListOfEXTCONN *el = extconnlist;
	while (el != NULL) {
		EXTCONN *extconn = el->extconn;
		el = el->next;

		extconn->clear_pathlist();
	}
};

void
INSTANCE::clear_pathlist()
{
	if (pathlist == NULL)	return;

	ListOfPATH *pl = pathlist;
	while (pl != NULL) {
		PATH *path = pl->path;
		pl = pl->next;

		PATHELEMENT *pe = path->final_pathelement;
		while (pe->previous != NULL) {
			PATHELEMENT *tpe = pe->previous;
			delete pe;
			pe = tpe;
		}
		delete pe;
		delete path;
	}
	delete pathlist;
	pathlist = NULL;
}

rc_t
CELL_LIBRARY::compute_thresholds(float arg_slope, BOOLEAN use_limit_method)
{
	// ... see note on "limit method" in header file

	if (this == NULL		||
	    functiongrouplist == NULL	) {
		printf("cell library is empty, maybe dpc_it\n");
		return RC_INVALID;
	}

	ListOfFUNCTIONGROUP *fll = functiongrouplist;
	while (fll != NULL) {
		FUNCTIONGROUP *functiongroup = fll->functiongroup;
		fll = fll->next; 

		// printf("\nfunction %s\n", functiongroup->function);
		ListOfCELL *cl = functiongroup->celllist;
		while (cl != NULL) {
			CELL *cell = cl->cell;
			cl = cl->next;

			float max_maxc = FLT_MAX;
			ListOfOUTPIN *opl = cell->outpinlist;
			while (opl != NULL) {
				OUTPIN *outpin = opl->outpin;

				float maxc;
				rc_t rc = outpin->compute_maxc(arg_slope, &maxc);
				switch (rc) {
				    case RC_SCALER:
					printf("scaler table: got no guess for target cap for cell \"%s\"\n", cell->name);
					cell->max_capacitance = 0.0;
					break;
					
				    case RC_OFFTABLE:
					printf("cell \"%s\": target slope is off characterizaion table; guess target cap = %0.3f\n", cell->name, maxc);
					cell->max_capacitance = 0.0;
					break;

				    default: 
					if (maxc < max_maxc)	max_maxc = maxc;
					opl = opl->next;	// tricky!
					continue;
				}
				break;

			}
			if (opl == NULL) {
				if (max_maxc <= 0) {
					printf("cell \"%s\" won't drive target slope (max cap = 0.0)\n", cell->name);
					max_maxc = 0.0;
				}
				cell->max_capacitance = max_maxc;
			}
		}
	}
	if (use_limit_method == false) {
		// get close method; so average the "limit method" capacitance
		// with that of the next larger size....
		fll = functiongrouplist;
		while (fll != NULL) {
			FUNCTIONGROUP *functiongroup = fll->functiongroup;
			fll = fll->next; 
	
			ListOfCELL *cl = functiongroup->celllist;
			while (cl != NULL) {
				CELL *cell = cl->cell;
				cl = cl->next;
	
				if (cl == NULL) {
					cell->max_capacitance = FLT_MAX;
					continue;
				}
				cell->max_capacitance += cl->cell->max_capacitance; 	
				cell->max_capacitance /= 2;
			}
		}		
	}

	// see note about buffer insertion in commands.cc 
	// at definition of buffer_insertion_threshold_slope

	if (::buffer_cell == NULL) {
		buffer_cell = get_cell(::buffer_cellname);
		if (buffer_cell == NULL) {
			printf("no buffer cell \"%s\" found\n", ::buffer_cellname);
		}
	}
	if (::inverter_cell == NULL) {	// ... while we're here ...
		inverter_cell = get_cell(::inverter_cellname);
		if (inverter_cell == NULL) {
			printf("no inverter cell \"%s\" found\n", ::inverter_cellname);
			// ... but who cares ...
		}
	}

	
	if (::buffer_cell != NULL) {
		float assumed_load;
		OUTPIN *outpin = ::buffer_cell->outpinlist->outpin;
		rc_t rc = outpin->compute_maxc(target_slope, &assumed_load);
		if (rc != RC_NOMINAL) {
			printf("compute_maxc failed for buffer \"%s\"\n", ::buffer_cell->name);
			return RC_FAILED;
		}
	
		OUTPINTIMING *opt = outpin->outpintiminglist->outpintiming;
		float rising_delay = opt->get_rising_delay(assumed_load, target_slope);
		float falling_delay = opt->get_falling_delay(assumed_load, target_slope);

		::buffer_insertion_threshold_slope = 
		    (rising_delay > falling_delay ? rising_delay : falling_delay)
		    + target_slope;
	} 


	// set max_capacitance for the largest cell in each functiongroup
	fll = functiongrouplist;
	while (fll != NULL) {
		FUNCTIONGROUP *functiongroup = fll->functiongroup;
		fll = fll->next; 

		CELL *cell;
		ListOfCELL *cl = functiongroup->celllist;
		while (cl != NULL) {
			cell = cl->cell;
			cl = cl->next;
		}

		
		float max_maxc = FLT_MAX;
		ListOfOUTPIN *opl = cell->outpinlist;
		while (opl != NULL) {
			OUTPIN *outpin = opl->outpin;
			opl = opl->next;

			float maxc;
			outpin->compute_maxc(::buffer_insertion_threshold_slope, &maxc);
			if (maxc < max_maxc)	max_maxc = maxc;
		}

		cell->max_capacitance = max_maxc;
	}		

	return RC_NOMINAL;
}

rc_t
OUTPIN::compute_maxc(float arg_slope, float *arg_return_cap)
{
	float	maxc = FLT_MAX;

	ListOfOUTPINTIMING *tl = outpintiminglist;
	while (tl != NULL) {
		OUTPINTIMING *outpintiming = tl->outpintiming;
		tl = tl->next;

		float return_cap;
		if (outpintiming->rise_transition != NULL) {
			rc_t rc = outpintiming->rise_transition->compute_maxc(arg_slope, &return_cap);
			if (rc != RC_NOMINAL) {
				*arg_return_cap = return_cap;
				return rc;
			}
			if (return_cap < maxc)	maxc = return_cap;
		}

		if (outpintiming->fall_transition != NULL) {
			rc_t rc = outpintiming->fall_transition->compute_maxc(arg_slope, &return_cap);
			if (rc != RC_NOMINAL) {
				*arg_return_cap = return_cap;
				return rc;
			}
			if (return_cap < maxc)	maxc = return_cap;
		}
	}

	*arg_return_cap = maxc;
	return RC_NOMINAL;
}

rc_t
CELL_LIBRARY::sort_cells_by_area()
{
	if (by_area_celllist != NULL) {
		delete by_area_celllist;
		by_area_celllist = NULL;
	}

	ListOfCELL *cl = celllist;
	if (cl == NULL)	return RC_FAILED;
	by_area_celllist = new ListOfCELL(cl->cell, NULL);
	cl = cl->next;

	while (cl != NULL) {
		CELL *cell = cl->cell;
		cl = cl->next;

		if (cell->area >= by_area_celllist->cell->area) {
			by_area_celllist = new ListOfCELL(cell, by_area_celllist);
			continue;
		}
	
		ListOfCELL *cl2 = by_area_celllist;
		while (cl2->next != NULL) {
			if (cell->area >= cl2->next->cell->area)	break;
			cl2 = cl2->next;
		}
		ListOfCELL *addon = new ListOfCELL(cell, cl2->next);
		cl2->next = addon;
	}
	return RC_NOMINAL;
}

rc_t
CELL_LIBRARY::sort_cells_for_downsize_list()
{
	if (downsize_order_celllist != NULL) {
		delete downsize_order_celllist;
		downsize_order_celllist = NULL;
	}

	class CELLSORTER {
	    public:
			CELLSORTER(CELL *arg_cell, float arg_incr) 
				: cell(arg_cell), incr_area(arg_incr), next(NULL) {
			}
			~CELLSORTER() {
				delete next;
			}

		// this is inefficient for long list, but fast to write
		// smallest first, please
		rc_t		insert(CELLSORTER *arg) {
					if (next == NULL) {
						next = arg;
						return RC_NOMINAL;
					}
					if (arg->incr_area < incr_area) {
						return RC_COMPLETE;
					}
					if (next->insert(arg) == RC_COMPLETE) {
						arg->next = next;
						next = arg;
						return RC_NOMINAL;
					}
					return RC_NOMINAL;
				}

		CELL *		cell;
		float		incr_area;
		CELLSORTER *	next;
	};

	CELLSORTER *cslist = NULL;	

	ListOfFUNCTIONGROUP *fgl = functiongrouplist;
	while (fgl != NULL) {
		FUNCTIONGROUP *fg = fgl->functiongroup;
		fgl = fgl->next;

		if (fg->celllist->next == NULL)	continue;	// one cell in this group

		ListOfCELL *cl = fg->celllist;
		while (cl->next != NULL) {
			CELL *previous_cell = cl->cell;
			CELL *this_cell = cl->next->cell;
			cl = cl->next;

			float incr_area = this_cell->area - previous_cell->area;
			CELLSORTER *cellsorter = new CELLSORTER(this_cell, incr_area);
			if (cslist == NULL			||
			    incr_area < cslist->incr_area	) {			
				cellsorter->next = cslist;
				cslist = cellsorter;
			} else cslist->insert(cellsorter);
		}
	}
		
	CELLSORTER *c = cslist;
	while (c != NULL) {
		downsize_order_celllist = new ListOfCELL(c->cell, downsize_order_celllist);
		c = c->next;
	}		

	delete cslist;
	return RC_NOMINAL;
}

rc_t
CELL_LIBRARY::characterize(float load, float slope, FILE *f)
{
	fprintf(f, "cellname\tinport\toutport\t^-delay\t\tv-delay\t\t^-slope\t\tv-slope\n");

	ListOfCELL *cl = celllist;
	while (cl != NULL) {
		CELL *cell = cl->cell;
		cl = cl->next;

		cell->characterize(load, slope, f);
	}
	return RC_NOMINAL;
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

CELL::CELL(char *arg_name, CELLTYPE arg_celltype)
	: type(arg_celltype),
	max_capacitance(0.0), is_flipflop(false),
	area(0.0),
	functiongroup(NULL),
	inpinlist(NULL), outpinlist(NULL)
{
	name = strdup(arg_name);
	size = name[strlen(name) - 1];
	switch (size) {
	    case 'A':
	    case 'B':
	    case 'C':
	    case 'D':
	    case 'E':
		break;

	    default:
		size = ' ';
	}
}

CELL::~CELL()
{
	delete name;

	ListOfINPIN *ipl = inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;
	
		delete inpin;
	}
	if (inpinlist != NULL) delete inpinlist;

	ListOfOUTPIN *opl = outpinlist;
	while (opl != NULL) {
		OUTPIN *outpin = opl->outpin;
		opl = opl->next;
	
		delete outpin;
	}
	if (outpinlist != NULL) delete outpinlist;

}

INPIN *
CELL::add_inpin(char *name)
{
	INPIN *inpin = new INPIN(name);
	inpinlist = new ListOfINPIN(inpin, inpinlist);
	return inpin;
}

OUTPIN *
CELL::add_outpin(char *name)
{
	OUTPIN *outpin = new OUTPIN(name);
	outpinlist = new ListOfOUTPIN(outpin, outpinlist);
	return outpin;
}


INPIN *
CELL::get_inpin(char *name)
{
	ListOfINPIN *ipl = inpinlist;
	while (ipl != NULL) {
		if (strcmp(ipl->inpin->name, name) == 0)	return ipl->inpin;
		ipl = ipl->next;
	}
	return NULL;
}

INPIN *
CELL::get_fast_inpin()
{
	ListOfINPIN *ipl = inpinlist;
	while (ipl != NULL) {
		if (ipl->inpin->relative_speed == FAST)	return ipl->inpin;
		ipl = ipl->next;
	}
	return NULL;
}	

OUTPIN *
CELL::get_outpin(char *name)
{
	ListOfOUTPIN *opl = outpinlist;
	while (opl != NULL) {
		if (strcmp(opl->outpin->name, name) == 0)	return opl->outpin;
		opl = opl->next;
	}
	return NULL;
}

///////////////////////////////////////////////////


ListOfOUTPINTIMING *
CELL_LIBRARY::copy_outpintiming_add_delay(ListOfOUTPINTIMING *arg_outpintiming, float delay)
{
	ListOfOUTPINTIMING *copy_optl = NULL;

	ListOfOUTPINTIMING *optl = arg_outpintiming;
	while (optl != NULL) {
		OUTPINTIMING *old_opt = optl->outpintiming;
		optl = optl->next;

		OUTPINTIMING *copy_opt = new OUTPINTIMING(*old_opt);
		copy_optl = new ListOfOUTPINTIMING(copy_opt, copy_optl);

		copy_opt->sense = old_opt->sense;
		copy_opt->related_pinname = strdup(old_opt->related_pinname);

		copy_opt->cell_rise = new LUTABLE(*old_opt->cell_rise);
		add_offset_to_lutable_values(copy_opt->cell_rise, delay);
		copy_opt->rise_transition = new LUTABLE(*old_opt->rise_transition);
		add_offset_to_lutable_values(copy_opt->rise_transition, delay);
		copy_opt->cell_fall = new LUTABLE(*old_opt->cell_fall);
		add_offset_to_lutable_values(copy_opt->cell_fall, delay);
		copy_opt->fall_transition = new LUTABLE(*old_opt->fall_transition);
		add_offset_to_lutable_values(copy_opt->rise_transition, delay);
	}

	return copy_optl;
}

INPINTIMING *
CELL_LIBRARY::copy_inpintiming_add_delay(INPINTIMING *arg_inpintiming, float delay)
{
	INPINTIMING *copy_ipt = new INPINTIMING(*arg_inpintiming);

	copy_ipt->related_pinname = strdup(arg_inpintiming->related_pinname);

	copy_ipt->setup_rise = new LUTABLE(*arg_inpintiming->setup_rise);
	add_offset_to_lutable_values(copy_ipt->setup_rise, delay);
	copy_ipt->hold_rise = new LUTABLE(*arg_inpintiming->hold_rise);
	add_offset_to_lutable_values(copy_ipt->hold_rise, delay);
	copy_ipt->setup_fall = new LUTABLE(*arg_inpintiming->setup_fall);
	add_offset_to_lutable_values(copy_ipt->setup_fall, delay);
	copy_ipt->hold_fall = new LUTABLE(*arg_inpintiming->hold_fall);
	add_offset_to_lutable_values(copy_ipt->hold_fall, delay);

	return copy_ipt;
}

rc_t
CELL_LIBRARY::add_offset_to_lutable_values(LUTABLE *lut, float offset)
{
	for (int i = 0; i < lut->values_size; i++) {
		lut->values[i] += offset;
	}

	return RC_NOMINAL;
}

///////////////////////////////////////////////////

rc_t
CELL::characterize(float load, float slope, FILE *f) {

	ListOfOUTPIN *opl = outpinlist;
	while (opl != NULL) {
		OUTPIN *outpin = opl->outpin;
		opl = opl->next;

		ListOfOUTPINTIMING *optl = outpin->outpintiminglist;
		while (optl != NULL) {
			OUTPINTIMING *outpintiming = optl->outpintiming;
			optl = optl->next;
		
			INPIN *related_inpin = outpintiming->related_inpin;
			float rising_delay = 0.0;
			if (outpintiming->cell_rise != NULL) {
				rising_delay = outpintiming->cell_rise->lookup(load, slope);
			}
			float falling_delay = 0.0;
			if (outpintiming->cell_fall != NULL) {
				falling_delay = outpintiming->cell_fall->lookup(load, slope);
			}
			float rise_transition = 0.0;
			if (outpintiming->rise_transition != NULL) {
				rise_transition = outpintiming->rise_transition->lookup(load, slope);
			}
			float fall_transition = 0.0;
			if (outpintiming->fall_transition != NULL) {
				fall_transition = outpintiming->fall_transition->lookup(load, slope);
			}

			fprintf(f, "%s	%s	%s	%f	%f	%f	%f\n",
			    name, related_inpin->name, outpin->name, rising_delay, falling_delay, rise_transition, fall_transition);
		}

	}
	return RC_NOMINAL;
}

CELL *
CELL::get_next_size_smaller()
{
	if (functiongroup == NULL)	return NULL;

	ListOfCELL *cl = functiongroup->celllist;
	if (cl->cell == this)		return NULL;
	while (cl->next != NULL) {
		if (cl->next->cell == this) {
			return cl->cell;
		}
		cl = cl->next;
	}

	printf("CELL::get_next_size_smaller: cell not in its own functiongroup???");
	return NULL;
}

CELL *
CELL::get_next_size_larger()
{
	if (functiongroup == NULL)	return NULL;

	ListOfCELL *cl = functiongroup->celllist;
	while (cl != NULL) {
		if (cl->cell == this)	break;
		cl = cl->next;
	}
	
	if (cl->next == NULL)		return NULL;
	return cl->next->cell;
}

CELL *
CELL::get_smallest_size() 
{
	if (functiongroup == NULL		||
	    functiongroup->celllist == NULL	) {
		return this;
	}
	return functiongroup->celllist->cell;
}

ListOfCELL::ListOfCELL(CELL *arg_cell, ListOfCELL *arg_next) 
    : cell(arg_cell), next(arg_next)
{
}


ListOfCELL::~ListOfCELL()
{
	if (next != NULL)	delete next;
}


ListOfListOfCELL::ListOfListOfCELL(ListOfCELL *arg_celllist, ListOfListOfCELL *arg_next) 
    : celllist(arg_celllist), next(arg_next)
{
}


ListOfListOfCELL::~ListOfListOfCELL()
{
	if (next != NULL)	delete next;
}



INPIN::INPIN(char *arg_name)
	: direction(DIRECTION_IN), 
	is_array(false), low_index(-1), high_index(-1),
	relative_speed(NOTORDERED),
	capacitance(0.0), is_clock_pin(false),
	outpintiminglist(NULL),
	inpintiming(NULL)
{
	name = strdup(arg_name);
}

INPIN::INPIN(INPIN &arg_inpin)
	: direction(arg_inpin.direction), 
	is_array(arg_inpin.is_array), low_index(arg_inpin.low_index), high_index(arg_inpin.high_index),
	relative_speed(arg_inpin.relative_speed),
	capacitance(arg_inpin.capacitance), is_clock_pin(arg_inpin.is_clock_pin),
	outpintiminglist(NULL),
	inpintiming(NULL)
{
	name = strdup(arg_inpin.name);
}

INPIN::~INPIN()
{
	delete name;
}


ListOfINPIN::ListOfINPIN(INPIN *arg_inpin, ListOfINPIN *arg_next) 
    : inpin(arg_inpin), next(arg_next)
{
}


ListOfINPIN::~ListOfINPIN()
{
	if (next != NULL)	delete next;
}


OUTPIN::OUTPIN(char *arg_name)
	: direction(DIRECTION_OUT), 
	is_array(false), low_index(-1), high_index(-1),
	resistance(0.0),
	outpintiminglist(NULL)
{
	name = strdup(arg_name);
}

OUTPIN::OUTPIN(OUTPIN &arg_outpin)
	: direction(arg_outpin.direction), 
	is_array(arg_outpin.is_array), 
	low_index(arg_outpin.low_index), high_index(arg_outpin.high_index),
	resistance(arg_outpin.resistance),
	outpintiminglist(NULL)
{
	name = strdup(arg_outpin.name);
}

OUTPIN::~OUTPIN()
{
	delete name;

	ListOfOUTPINTIMING *tl = outpintiminglist;
	while (tl != NULL) {
		OUTPINTIMING *outpintiming = tl->outpintiming;
		tl = tl->next;

		delete outpintiming;
	}
	if (outpintiminglist != NULL) delete outpintiminglist;
}

rc_t
OUTPIN::add_outpintiming(OUTPINTIMING *arg_outpintiming)
{
	outpintiminglist = new ListOfOUTPINTIMING(arg_outpintiming, outpintiminglist);
	return RC_NOMINAL;
}

float
OUTPIN::lookup_worst_slope(float arg_load, float arg_slope) 
{
	float	worsts = -FLT_MAX;

	ListOfOUTPINTIMING *tl = outpintiminglist;
	while (tl != NULL) {
		OUTPINTIMING *outpintiming = tl->outpintiming;
		tl = tl->next;

		float rising = outpintiming->rise_transition->lookup(arg_load, arg_slope);
		if (rising > worsts)	worsts = rising;

		float falling = outpintiming->fall_transition->lookup(arg_load, arg_slope);
		if (falling > worsts)	worsts = falling;
	}

	return worsts;
}



ListOfOUTPIN::ListOfOUTPIN(OUTPIN *arg_outpin, ListOfOUTPIN *arg_next) 
    : outpin(arg_outpin), next(arg_next)
{
}


ListOfOUTPIN::~ListOfOUTPIN()
{
	if (next != NULL)	delete next;
}


//////////////////////////////

LUTABLE::LUTABLE(char *arg_name)
	: variable_1(NULL), variable_2(NULL),
	index_1_size(0), index_2_size(0), values_size(0)
	// index_1(NULL), index_2(NULL),
	// values(NULL)
{ 
	name = strdup(arg_name);

	for (int i = 0; i < MAX_LU_INDEX; i++) {
		index_1[i] = FLT_MAX;
		index_2[i] = FLT_MAX;
	}
	for (int i = 0; i < MAX_LU_INDEX * MAX_LU_INDEX; i++) {
		values[i] = FLT_MAX;
	}
}

LUTABLE::LUTABLE(LUTABLE &arg_lutable)
	// : index_1(NULL), index_2(NULL), values(NULL)
{
	name = strdup(arg_lutable.name);
	variable_1 = strdup(arg_lutable.variable_1);
	variable_2 = strdup(arg_lutable.variable_2);
	index_1_size = arg_lutable.index_1_size;
	index_2_size = arg_lutable.index_2_size;
	values_size = arg_lutable.values_size;

	for (int i = 0; i < MAX_LU_INDEX; i++) {
		index_1[i] = arg_lutable.index_1[i];
		index_2[i] = arg_lutable.index_2[i];
	}
	for (int i = 0; i < MAX_LU_INDEX * MAX_LU_INDEX; i++) {
		values[i] = arg_lutable.values[i];
	}
}

LUTABLE::LUTABLE(int arg_index_1_size, int arg_index_2_size)
	: name(NULL), variable_1(NULL), variable_2(NULL),
	index_1_size(arg_index_1_size), index_2_size(arg_index_2_size)	
{
	for (int i = 0; i < MAX_LU_INDEX; i++) {
		index_1[i] = FLT_MAX;
		index_2[i] = FLT_MAX;
	}
	for (int i = 0; i < MAX_LU_INDEX * MAX_LU_INDEX; i++) {
		values[i] = FLT_MAX;
	}
	values_size = index_1_size * index_2_size;
}

LUTABLE::~LUTABLE() 
{
	if (name != NULL)	delete name;
	if (variable_1 != NULL)	delete variable_1;
	if (variable_2 != NULL)	delete variable_2;
	// if (index_1 != NULL)	delete[] index_1;
	// if (index_2 != NULL)	delete[] index_2;
	// if (values != NULL)	delete[] values;
}

float
LUTABLE::lookup(float arg_ix1, float arg_ix2)
{
	// scalar
	if (values_size == 1)	return values[0];

	// two dimensional linear interpolation

	int	ix1_low;
	int	ix1_high;
	int	ix2_low;
	int 	ix2_high;

	float	ix1_run;
	float	ix1_delta;
	float	ix1_rise_low;
	float	ix1_rise_high;
	float	ix2_value_low;
	float	ix2_value_high;
	float	ix2_run;
	float	ix2_rise;
	float	m;
	float	ix2_delta;
	float	retv;

	int i;
	for (i = 1; i < index_1_size - 1; i++) {
		if (arg_ix1 < index_1[i])	break;
	}
	ix1_high = i;
	ix1_low = i - 1;

	for (i = 1; i < index_2_size - 1; i++) {
		if (arg_ix2 < index_2[i])	break;
	}
	ix2_high = i;
	ix2_low = i - 1;

	ix1_run = index_1[ix1_high] - index_1[ix1_low];
	ix1_delta = arg_ix1 - index_1[ix1_low];

	// interpolate along the line of ix2_low
	ix1_rise_low = 
	    get_value(ix1_high, ix2_low) - 
	    get_value(ix1_low, ix2_low);
	m = ix1_rise_low / ix1_run;	 
	ix2_value_low = 
	    get_value(ix1_low, ix2_low) + 
	    ix1_delta * m;

	// interpolate along the line of ix2_high
	ix1_rise_high = 
	    get_value(ix1_high, ix2_high) - 
	    get_value(ix1_low, ix2_high);
	m = ix1_rise_high / ix1_run;
	ix2_value_high = 
	    get_value(ix1_low, ix2_high) + 
	    ix1_delta * m;

	// now interpolate along the line of arg_ix1,
	// between the two points just established
	ix2_run = index_2[ix2_high] - index_2[ix2_low];
	ix2_rise = ix2_value_high - ix2_value_low;
	m = ix2_rise / ix2_run;
	ix2_delta = arg_ix2 - index_2[ix2_low];
	retv = ix2_value_low + ix2_delta * m;

	return retv;
}

float
LUTABLE::get_value(int ix1, int ix2) 
{
	int index = ix1 * index_2_size + ix2;
	if (index >= values_size) {
		printf("LUTABLE::get_value: indexes out of range\n");
		return -FLT_MAX;
	}
	return values[index];
}

void
LUTABLE::put_value(int ix1, int ix2, float value) 
{
	int index = ix1 * index_2_size + ix2;
	if (index >= values_size) {
		printf("LUTABLE::put_value: indexes out of range\n");
		return;
	}
	values[index] = value;
}

rc_t
LUTABLE::compute_maxc(float arg_target_slope, float *return_cap)
{
	// scalar
	if (values_size == 1) {
		*return_cap = 0.0;
		return RC_SCALER;
	}

	// the target ix2 is both the assumed input ix2 ("index_2") 
	// and the desired ouput ix2 ("value")

	// does the table cover the target value reasonably?
	float min_table_input_slope = index_2[0];
	if (target_slope < (min_table_input_slope * ::permissable_table_underrun)) {
		*return_cap = 0.0;
		return RC_OFFTABLE;
	}
	float min_table_transition_value = values[0];
	if (target_slope < (min_table_transition_value * ::permissable_table_underrun)) {
		// return the minimum cap for the table 
		*return_cap = index_1[0];
		return RC_OFFTABLE;
	}
	float max_table_input_slope = index_2[index_2_size - 1];
	if (target_slope > (max_table_input_slope * ::permissable_table_overrun)) {
		*return_cap = 0.0;
		return RC_OFFTABLE;
	}
	float max_table_transition_value = values[index_2_size * index_1_size - 1];
	if (target_slope > (max_table_transition_value * ::permissable_table_overrun)) {
		// return the maximum cap for the table 
		*return_cap = index_1[0];
		return RC_OFFTABLE;
	}

	// so we are going to look at the cut through the table
	// along the line index_2 = arg_ix2;
	// find the index_1 for which value = arg_ix2.

	int ix1_high;
	float value_at_high;
	for (ix1_high = 1; ix1_high < index_1_size; ix1_high++) {
		value_at_high = lookup(index_1[ix1_high], arg_target_slope);
		if (arg_target_slope < value_at_high) break;
	}

	int ix1_low = ix1_high - 1;
	float value_at_low = lookup(index_1[ix1_low], arg_target_slope);

	float total_rise = value_at_high - value_at_low;
	float desired_rise = arg_target_slope - value_at_low;
	float fraction = desired_rise / total_rise;

	float ix1_delta = index_1[ix1_high] - index_1[ix1_low];
	float desired_ix1 = index_1[ix1_low] + (fraction * ix1_delta);

	*return_cap = desired_ix1;
	return RC_NOMINAL;
}

float
LUTABLE::compute_implied_resistance(char rise_or_fall)
{
	// t = RC; R = delta-t / delta-C
	// ohms = (nanoseconds / picoFarads) * 1000

	// scalar...
	if (values_size == 1)	return 0.0;
	if (index_2_size == 1)	return 0.0;

	// pick a slope value near the short end the table
	// measure the slope across the whole table?

	float rise = get_value(index_1_size - 1, 0) - get_value(0, 0);
	float run = index_1[index_1_size - 1] - index_1[0];
	float return_value = ((rise / run) * 1000.0);

	if (speedy_verbose == true) {
		printf("%c	%f	", rise_or_fall, 1000.0 * rise / run );

		for (int ix1 = 0; ix1 < index_1_size - 1; ix1++) {
			rise = get_value(ix1 + 1, 0) - get_value(ix1, 0);
			run = index_1[ix1 + 1] - index_1[ix1];
			printf("%f	", 1000.0 * rise / run);
		}
		printf("\n");
	}

	return return_value;
}
ListOfLUTABLE::ListOfLUTABLE(LUTABLE *arg_lutable, ListOfLUTABLE *arg_next) 
    : lutable(arg_lutable), next(arg_next)
{
}


ListOfLUTABLE::~ListOfLUTABLE()
{
	if (next != NULL)	delete next;
}

//////////////////////////////

INPINTIMING::INPINTIMING()
    : related_inpin(NULL), related_pinname(NULL),
      setup_rise(NULL), hold_rise(NULL),
      setup_fall(NULL), hold_fall(NULL)
{
}

INPINTIMING::~INPINTIMING()
{
	if (setup_rise != NULL)		delete setup_rise;
	if (hold_rise != NULL)		delete hold_rise;
	if (setup_fall != NULL)		delete setup_fall;
	if (hold_fall != NULL)		delete hold_fall;
}

rc_t
INPINTIMING::find_related_inpin(CELL *cell)
{
	related_inpin = NULL;  
	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;

		if (strcmp(related_pinname, inpin->name) == 0) {
			related_inpin = inpin;
			return RC_NOMINAL;
		}

	}
	printf("ERROR: no related inpin found for cell \"%s\" it says here \"%s\")\n",
	    cell->name, related_pinname);
	return RC_NOTFOUND;
}
	
ListOfINPINTIMING::ListOfINPINTIMING(INPINTIMING *arg_inpintiming, ListOfINPINTIMING *arg_next) 
    : inpintiming(arg_inpintiming), next(arg_next)
{
}


ListOfINPINTIMING::~ListOfINPINTIMING()
{
	if (next != NULL)	delete next;
}




OUTPINTIMING::OUTPINTIMING()
    : outpin(NULL), related_inpin(NULL), related_pinname(NULL),
    sense(UNKNOWN_SENSE),
    cell_rise(NULL), rise_transition(NULL),
    cell_fall(NULL), fall_transition(NULL)

{
}

OUTPINTIMING::~OUTPINTIMING()
{
	if (cell_rise != NULL)		delete cell_rise;
	if (rise_transition != NULL)	delete rise_transition;
	if (cell_fall != NULL)		delete cell_fall;
	if (fall_transition != NULL)	delete fall_transition;
}

float
OUTPINTIMING::get_rising_delay(float load, float input_slope)
{	
	if (cell_rise == NULL)	return 0.0;
	return cell_rise->lookup(load, input_slope);
}

float
OUTPINTIMING::get_falling_delay(float load, float input_slope)
{	
	if (cell_fall == NULL)	return 0.0;
	return cell_fall->lookup(load, input_slope);
}

float
OUTPINTIMING::get_rising_slope(float load, float input_slope)
{	
	if (rise_transition == NULL)	return 0.0;
	return rise_transition->lookup(load, input_slope);
}

float
OUTPINTIMING::get_falling_slope(float load, float input_slope)
{	
	if (fall_transition == NULL)	return 0.0;
	return fall_transition->lookup(load, input_slope);
}

rc_t
OUTPINTIMING::find_related_inpin(CELL *cell)
{
	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;

		if (strcmp(related_pinname, inpin->name) == 0) {
			related_inpin = inpin;
			inpin->outpintiminglist = new ListOfOUTPINTIMING(this, inpin->outpintiminglist);
			return RC_NOMINAL;
		}
	}

	printf("ERROR: no related inpin found for cell \"%s\" it says here \"%s\")\n",
	    cell->name, related_pinname);
	return RC_NOTFOUND;
}

float
OUTPINTIMING::compute_implied_resistance()
{
	float resistance = 0.0;
	if (cell_rise != NULL) {
		resistance = cell_rise->compute_implied_resistance('^');
	}
	if (cell_fall != NULL) {
		float r = cell_fall->compute_implied_resistance('v');
		if (r > resistance)	resistance = r;
	}
	
	return resistance;
}

ListOfOUTPINTIMING::ListOfOUTPINTIMING(OUTPINTIMING *arg_outpintiming, ListOfOUTPINTIMING *arg_next) 
    : outpintiming(arg_outpintiming), next(arg_next)
{
}


ListOfOUTPINTIMING::~ListOfOUTPINTIMING()
{
	if (next != NULL)	delete next;
}


FUNCTIONGROUP::FUNCTIONGROUP(char *arg_function, CELL *arg_cell)
	: function(FG_UNKNOWN)
{
	celllist = new ListOfCELL(arg_cell, NULL);
	functionstr = strdup(arg_function);
}

FUNCTIONGROUP::~FUNCTIONGROUP()
{
	delete functionstr;

	if (celllist)	delete celllist;
}

FG_FUNCTION
FUNCTIONGROUP::lookup(char *cellname)
{
	if (strcmp(cellname, "MMI_INVA") == 0)		return FG_INV;
	if (strcmp(cellname, "MMI_INVB") == 0)		return FG_INV;
	if (strcmp(cellname, "MMI_INVC") == 0)		return FG_INV;
	if (strcmp(cellname, "MMI_INVD") == 0)		return FG_INV;
	if (strcmp(cellname, "MMI_INVE") == 0)		return FG_INV;
	
	return FG_UNKNOWN;
}

void
FUNCTIONGROUP::get_functionstr(char *buf, int bufsize)
{
	if (bufsize < 10)	return;
	switch (function) {
	    case FG_INV:	sprintf(buf, "INV");	return;
	    default:		return;
	}

	// not reached
	return;
}


ListOfFUNCTIONGROUP::ListOfFUNCTIONGROUP(FUNCTIONGROUP *arg_functiongroup, ListOfFUNCTIONGROUP *arg_next) 
    : functiongroup(arg_functiongroup), next(arg_next)
{
}


ListOfFUNCTIONGROUP::~ListOfFUNCTIONGROUP()
{
	if (next != NULL)	delete next;
}



