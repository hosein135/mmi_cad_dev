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

LIBFILE::LIBFILE(char *arg_name)
	: were_read_errors(false),
	template_lutablelist(NULL),
	ignore_quotes(false), 
	bustypelist(NULL),
	ungotten_libtokenlist(NULL),
	libname(NULL), f(NULL)
{
	name = strdup(arg_name);
}

LIBFILE::~LIBFILE()
{
	delete name;

	if (template_lutablelist != NULL) {
		ListOfLUTABLE *tl = template_lutablelist;
		while (tl != NULL) {
			delete tl->lutable;
			tl = tl->next;
		}
		delete template_lutablelist;
	}

	if (bustypelist != NULL) {
		ListOfBUSTYPE *bl = bustypelist;
		while (bl != NULL) {
			delete bl->bustype;
			bl = bl->next;
		}
		delete bustypelist;
	}
}

rc_t
LIBFILE::read() 
{
	if (f != NULL)	return RC_INUSE;

	f = fopen(name, "r");
	if (f == NULL)	{
		printf("can't open .lib file \"%s\" for reading\n", name);
		return RC_NOTFOUND;
	}
	lineno = 1;
	were_read_errors = false;

	LIBTOKEN *t = get_token();
	if (t->type != LIB_LIBRARY) {
		printf("file doesn't start with \"library\"... not .lib file???\n");
		return RC_FAILED;
	}
	delete t;

	t = get_token();
	if (t->type != LIBLPAR)		pe("expected library name arg");
	delete t;

	t = get_token();
	if (t->type != LIBSTRING)	pe("expected library name");
	libname = strdup(t->get_string());
	delete t;

	t = get_token();
	if (t->type != LIBRPAR)		pe("expected library name arg 2");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected library body");
	delete t;

	if (cell_library == NULL) {
		cell_library = new CELL_LIBRARY();
	}
		
	while (1) {
		if (were_read_errors == true)	return RC_FAILED;

		t = get_token();
		switch (t->type) {

			// for all I know, the user can create any variables here 
			// he likes; certainly I keep seeing new ones.  And I don't
			// care about hardly any of them.  So let's just take the 
			// the cash and let the credit go, nor heed the rumble of 
			// a distant drum.
		    // case LIB_CAPACITVE_LOAD_UNIT:
		    // case LIB_COMMENT:
		    // case LIB_CURRENT_UNIT:
		    // case LIB_DEFAULT_CELL_LEAKAGE_POWER:
		    // case LIB_DEFAULT_FANOUT_LOAD:
		    // case LIB_DEFAULT_INOUT_PIN_CAP:
		    // case LIB_DEFAULT_INPUT_PIN_CAP:
		    // case LIB_DEFAULT_MAX_CAPACITANCE:
		    // case LIB_DEFAULT_MAX_FANOUT:
		    // case LIB_DEFAULT_MAX_TRANSITION:
		    // case LIB_DEFAULT_OUTPUT_PIN_CAP:
		    // case LIB_DELAY_MODEL:
		    // case LIB_INPUT_THRESHOLD_PCT_FALL:
		    // case LIB_INPUT_THRESHOLD_PCT_RISE:
		    // case LIB_INPUT_VOLTAGE:
		    // case LIB_MAX_CAPACITANCE:
		    // case LIB_MAX_FANOUT:
		    // case LIB_MAX_TRANSITION:
		    // case LIB_NOM_PROCESS:
		    // case LIB_NOM_TEMPERATURE:
		    // case LIB_NOM_VOLTAGE:
		    // case LIB_OUTPUT_THRESHOLD_PCT_FALL:
		    // case LIB_OUTPUT_THRESHOLD_PCT_RISE:
		    // case LIB_OUTPUT_VOLTAGE:
		    // case LIB_PULLING_RESISTANCE_UNIT:
		    // case LIB_SLEW_DERATE_FROM_LIBRARY:
		    // case LIB_SLEW_LOWER_THRESHOLD_PCT_FALL:
		    // case LIB_SLEW_LOWER_THRESHOLD_PCT_RISE:
		    // case LIB_SLEW_UPPER_THRESHOLD_PCT_FALL:
		    // case LIB_SLEW_UPPER_THRESHOLD_PCT_RISE:
		    // case LIB_TIME_UNIT:
		    // case LIB_VOLTAGE_UNIT:
			// skip_across_body();
			// continue;

		    case LIB_LU_TABLE_TEMPLATE:
			read_lu_table_template();
			continue;

		    case LIB_CELL:
			read_cell();
			continue;

		    case LIB_TYPE:
			read_type();
			continue;
		
		    case LIBRCURLY:
			delete t;
			break;

		    case LIBENDOFFILE:
			pe("premature EOF in LIBFILE");
			return RC_FAILED;

		    case LIBSTRING:
			// printf("unrecognized variable in libfile at top level: \"%s\" (ignored)\n", 
			//      t->get_string());
			delete t;
			skip_across_body();
			continue;

		    default:
			pe("junk in LIBFILE????");
			delete t;
			continue;
		}

		t = get_token();
		if (t->type != LIBENDOFFILE) {
			pe("junk after library definition in LIBFILE");
			return RC_FAILED;
		}
		delete t;

		if (were_read_errors == true)	return RC_FAILED;
		return RC_NOMINAL;

	}
	// not reached
}		

rc_t
LIBFILE::read_lu_table_template() {

	float	temp_lu_index[MAX_LU_INDEX];
	ignore_quotes = true;

	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("expected lutable name arg");
	delete t;

	t = get_token();
	if (t->type != LIBSTRING)	pe("expected lutable name");
	LUTABLE *lutable = new LUTABLE(t->get_string());
	delete t;

	t = get_token();
	if (t->type != LIBRPAR)		pe("expected lutable name arg 2");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected lutable body");
	delete t;

	t = get_token();
	while (1) {
		switch (t->type) {
		    case LIB_VARIABLE_1: {
			delete t;
	
			t = get_token();
			if (t->type != LIBCOLON)	pe("expected colon");
			delete t;
	
			t = get_token();
			if (t->type != LIBSTRING)	pe("expected varname");
			lutable->variable_1 = strdup(t->get_string());
			delete t;
	
			if (next_is_semicolon() != true)	pe("expected semicolon");
	
			t = get_token();
			continue;
		    }
	
		    case LIB_VARIABLE_2: {
			delete t;
	
			t = get_token();
			if (t->type != LIBCOLON)	pe("expected colon");
			delete t;
	
			t = get_token();
			if (t->type != LIBSTRING)	pe("expected varname");
			lutable->variable_2 = strdup(t->get_string());
			delete t;
	
			if (next_is_semicolon() != true)	pe("expected semicolon");
	
			t = get_token();
			continue;
		    }
	
		    case LIB_INDEX_1: {
			delete t;
	
			t = get_token();
			if (t->type != LIBLPAR)		pe("expected lpar");
			delete t;
	
			int size = 0;
			while (1) {
				t = get_token();
				if (t->is_float() == true) {
					if (size < MAX_LU_INDEX) {
						temp_lu_index[size++] = t->get_float();
					}
					else pe("MAX_LU_INDEX exceeded\n");
				} else break;
				 
				delete t;
			}
	
			if (t->type != LIBRPAR)		pe("expected rpar");
			delete t;
	
			if (next_is_semicolon() != true)	pe("expected semicolon");
	
			lutable->index_1_size = size;
			// lutable->index_1 = new float[size];
			for (int i = 0; i < size; i++) {
				lutable->index_1[i] = temp_lu_index[i];
			}
	
			t = get_token();
			continue;
		    }
		
		    case LIB_INDEX_2: {
			delete t;
	
			t = get_token();
			if (t->type != LIBLPAR)		pe("expected lpar");
			delete t;
	
			int size = 0;
			while (size < MAX_LU_INDEX) {
				t = get_token();
				if (t->is_float() == true) {
					if (size < MAX_LU_INDEX) {
						temp_lu_index[size++] = t->get_float();
					}
					else pe("MAX_LU_INDEX exceeded\n");
				} else break;
				 
				delete t;
			}
	
			if (t->type != LIBRPAR)		pe("expected rpar");
			delete t;
	
			if (next_is_semicolon() != true)	pe("expected semicolon");
	
			lutable->index_2_size = size;
			// lutable->index_2 = new float[size];
			for (int i = 0; i < size; i++) {
				lutable->index_2[i] = temp_lu_index[i];
			}
	
			t = get_token();
			continue;
		    }
		
		    case LIBRCURLY:
			break;
	
		    default:
			pe("junk in lutable");
			return RC_FAILED;
		}
		break;
	}

	template_lutablelist = new ListOfLUTABLE(lutable, template_lutablelist);
		
	ignore_quotes = false;
	return RC_NOMINAL;
}

rc_t
LIBFILE::read_cell() {

	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("expected cell name arg");
	delete t;

	t = get_token();
	if (t->type != LIBSTRING)	pe("expected cell name");
	char *cellname = t->get_string();
	CELL *cell = ::cell_library->get_cell(cellname);
	if (cell != NULL) {
		printf("libfile read: deleting previous definition for cell \"%s\"\n", cellname);
		::cell_library->remove_cell(cell);
		cell = NULL;
	}
	cell = new CELL(t->get_string(), CELLTYPE_BASIC);
	delete t;

	t = get_token();
	if (t->type != LIBRPAR)		pe("expected cell name arg 2");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected cell body");
	delete t;

	while (1) {
		t = get_token();
		switch (t->type) {
		    case LIB_AREA:
			delete t;
		
			t = get_token();
			if (t->type != LIBCOLON)	pe("bad area expr 1");
			delete t;

			t = get_token();
			if (t->is_float() != true) 	pe("expected area");
			cell->area = t->get_float();
			delete t;	

			if (next_is_semicolon() != true)	pe("bad area expr 2");
			continue;

		    case LIB_PIN:
			delete t;
			read_pin(cell);
			continue;

		    case LIB_BUS:
			delete t;
			read_bus(cell);
			continue;

		    case LIB_FF:
		    case LIB_LATCH:
			delete t;
			read_ff(cell);
			continue;

		    case LIB_TEST_CELL:
			delete t;
			skip_across_body();
			continue;
	
		    case LIB_DONT_USE:
			delete t;
			skip_to_semicolon();
			continue;
	
		    case LIBRCURLY:
			delete t;
			break;	

		    case LIBSTRING:
			// printf("unrecognized variable in libfile cell: \"%s\" (ignored)\n", 
			//     t->get_string());
			delete t;
			skip_to_semicolon();
			continue;

		    default:
			pe("junk in cell???");
			return RC_FAILED;
		}			
		break;
	}

	// outpintimings' related inpin are by name; find a pointer
	// compute pin driver internal resistance

	ListOfOUTPIN *opl = cell->outpinlist;
	while (opl != NULL) {
		OUTPIN *outpin = opl->outpin;
		opl = opl->next;
	
		if (speedy_verbose == true)	printf("cell %s outpin %s	", cell->name, outpin->name);
		outpin->resistance = 0.0; 
		ListOfOUTPINTIMING *tl = outpin->outpintiminglist;
		while (tl != NULL) {
			OUTPINTIMING *outpintiming = tl->outpintiming;
			tl = tl->next;

			outpintiming->find_related_inpin(cell);

			if (speedy_verbose == true)	printf("...inpin %s\n", outpintiming->related_pinname);
			float resistance = outpintiming->compute_implied_resistance();
			// ... take worst case ...
			if (resistance > outpin->resistance) outpin->resistance = resistance;
		}
	}

	// so far everything with an inpin with an inpintiming is a flipflop
	// with a D-edge setup to our single-phase clock... if that's not
	// true, our timing calculation possibly won't do the right thing...
	// ... of course, we may not know this is a flipflop-type until 
	// later... but at least we can check that it's related to a clock pin...

	// this sounds like a reasonable idea, but it creates messages for
	// MMI_LLxx and MMI_LATCHxx
	BOOLEAN cell_has_inpintimings = false;
	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;
	
	// 	// not a list!
	// 	// ListOfINPINTIMING *tl = inpin->inpintiminglist;
	// 	// while (tl != NULL) {
	// 	// 	INPINTIMING *inpintiming = tl->inpintiming;
	// 	//	tl = tl->next;
	// 
		INPINTIMING *inpintiming = inpin->inpintiming;
		if (inpintiming != NULL) {
			cell_has_inpintimings = true;
	// 		inpintiming->find_related_inpin(cell);
	// 
	// 		if (inpintiming->related_inpin != NULL) {
	// 			if (inpintiming->related_inpin->is_clock_pin == false) {
	// 				printf("WARNING: cell \"%s\" has inpin \"%s\" related to non-clock intpin \"%s\"\n",
	// 				    cell->name, inpin->name, inpintiming->related_inpin->name);
	// 			}
	// 		}
		}
	}

	if (cell_has_inpintimings == true	&&
	    cell->is_flipflop == false		) {
		// if it has a clock pin, let's just assume its a flipflop....
		ListOfINPIN *ipl = cell->inpinlist;
		while (ipl != NULL) {
			INPIN *inpin = ipl->inpin;
			if (inpin->is_clock_pin == true)	break;
			ipl = ipl->next;
		}
		if (ipl != NULL) {
			cell->is_flipflop = true;

		} else {
			// printf("WARNING: non-flipflop-type cell \"%s\" has inpintimings\n", cell->name);
		}

	}
	else if (cell->is_flipflop == true) {	// ... it better have a clock pin
		ListOfINPIN *ipl = cell->inpinlist;
		while (ipl != NULL) {
			INPIN *inpin = ipl->inpin;
			if (inpin->is_clock_pin == true)	break;
			ipl = ipl->next;
		}
		if (ipl == NULL					&&
		    strcmp(cell->name, "MMI_LLCB") != 0		&&
		    strcmp(cell->name, "MMI_LTCHNB") != 0	&&
		    strcmp(cell->name, "MMI_LTCHPB") != 0	) {

			printf("WARNING: flipflop-type cell \"%s\" has no clock pin\n", cell->name);
		}
	}

	// .... compute outpin internal resistance
	


	cell_library->celllist = new ListOfCELL(cell, cell_library->celllist);
	cell_library->sort_by_function(cell);

	return RC_NOMINAL;
}

rc_t
LIBFILE::read_pin(CELL *cell)
{
	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("expected pin name arg");
	delete t;

	LIBTOKEN *name_token = get_token();
	if (name_token->type != LIBSTRING)	pe("expected pin name");

	t = get_token();
	if (t->type != LIBRPAR)		pe("expected pin name arg 2");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected pin body");
	delete t;

	BOOLEAN is_clock_pin = false;
	LIBTOKEN *dir_token = NULL;
	while (1) {

		t = get_token();
		switch (t->type) {

		    case LIB_DIRECTION: {
			delete t;

			t = get_token();
			if (t->type != LIBCOLON)	pe("expected pin direction 2");
			delete t;

			dir_token = get_token();
			if (dir_token->type != LIBSTRING)	pe("expected pin direction value");

			if (next_is_semicolon() != true)	pe("expected pin direction 3");
		    } continue;

		    case LIB_CLOCK:
		    case LIB_CLK:
			delete t;
			is_clock_pin = true;
			skip_to_semicolon();
			continue;

		    case LIB_FUNCTION:
			delete t;
			skip_across_body();
			continue;

		    case LIBSTRING:
			// ... collision between keyword and common name ...
			if (strcmp(t->get_string(), "clk") == 0) {
				delete t;
				is_clock_pin = true;
				skip_to_semicolon();
			}
			else {
				delete t;
				// printf("unknown variable \"%s\" in pin ignored\n", t->get_string());
				skip_to_semicolon();
			}
			continue;

		    default:
			unget_token(t);
			break;
		}
		break;
	}

	char *direction = dir_token->get_string();
	if (strcmp(direction, "output") == 0) {
		OUTPIN *outpin = new OUTPIN(name_token->get_string());
		cell->outpinlist = new ListOfOUTPIN(outpin, cell->outpinlist);
		read_output_pin(outpin, cell);

	} else if (strcmp(direction, "input") == 0) {
		INPIN *inpin = new INPIN(name_token->get_string());
		inpin->is_clock_pin = is_clock_pin;
		cell->inpinlist = new ListOfINPIN(inpin, cell->inpinlist);
		read_input_pin(inpin);

	} else if (strcmp(direction, "inout") == 0) {		OUTPIN *outpin = new OUTPIN(name_token->get_string());
		cell->outpinlist = new ListOfOUTPIN(outpin, cell->outpinlist);
		INPIN *inpin = new INPIN(name_token->get_string());
		inpin->is_clock_pin = is_clock_pin;
		cell->inpinlist = new ListOfINPIN(inpin, cell->inpinlist);
		read_inout_pin(inpin, outpin, cell);

	} else	pe("what pin direction???");

	delete dir_token;
	delete name_token;
	return RC_NOMINAL;
}

rc_t
LIBFILE::read_bus(CELL *cell)
{
	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("expected bus name arg");
	delete t;

	LIBTOKEN *name_token = get_token();
	if (name_token->type != LIBSTRING)	pe("expected bus name");

	t = get_token();
	if (t->type != LIBRPAR)		pe("expected bus name arg 2");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected bus body");
	delete t;


	// xxx... requireing this order of terms is probably problematic...

	t = get_token();
	if (t->type != LIB_BUS_TYPE)	pe("expected bus type");
	delete t;

	t = get_token();
	if (t->type != LIBCOLON)	pe("expected bus type 2");
	delete t;

	LIBTOKEN *type_token = get_token();
	if (type_token->type != LIBSTRING)	pe("expected bus type value");
	BUSTYPE *bustype = NULL;
	ListOfBUSTYPE *btl = bustypelist;
	while (btl != NULL) {
		bustype = btl->bustype;
		if (strcmp(bustype->name, type_token->get_string()) == 0) break;
		btl = btl->next;
	}
	if (btl == NULL)		pe("bus type not found");

	if (next_is_semicolon() != true)	pe("expected bus type 3");

	t = get_token();
	if (t->type != LIB_DIRECTION)	pe("expected bus direction");
	delete t;

	t = get_token();
	if (t->type != LIBCOLON)	pe("expected bus direction 2");
	delete t;

	LIBTOKEN *dir_token = get_token();
	if (dir_token->type != LIBSTRING)	pe("expected bus direction value");

	if (next_is_semicolon() != true)	pe("expected bus direction 3");

	// 3 cases:  
	// I:
	//	pin (rdata[255:0]) {
	//		< pin body >
	//	}
	// II:
	//	< pin body >
	// III:	
	//	pin (rdata[0]) {
	//		< pin body >
	//	}
	//	pin (rdata[1]) {
	//		< pin body >
	//	}
	//	...
	//
	// I and II equivalently describe an array, eg a ram with 
	// dout and din all with identical timing with respect to a clock
	//
	// III describes a bus where each pin can have its own timing.

	t = get_token();
	if (t->type != LIB_PIN) {
		// case I
		unget_token(t);
		char *direction = dir_token->get_string();
		if (strcmp(direction, "output") == 0) {
			OUTPIN *outpin = new OUTPIN(name_token->get_string());
			outpin->is_array = true;
			outpin->low_index = bustype->bit_from;
			outpin->high_index = bustype->bit_to;
			cell->outpinlist = new ListOfOUTPIN(outpin, cell->outpinlist);
			read_output_pin(outpin, cell);

		} else if (strcmp(direction, "input") == 0) {
			INPIN *inpin = new INPIN(name_token->get_string());
			inpin->is_array = true;
			inpin->low_index = bustype->bit_from;
			inpin->high_index = bustype->bit_to;
			cell->inpinlist = new ListOfINPIN(inpin, cell->inpinlist);
			read_input_pin(inpin);

		} else	pe("what pin direction???");
		delete dir_token;
		delete name_token;
		return RC_NOMINAL;
	}

	delete t;
	t = get_token();
	if (t->type != LIBLPAR)		pe("expected lpar in pin name for bus\n");

	LIBTOKEN *pin_name = get_token();
	if (pin_name->type != LIBSTRING)	pe("expected pin name for bus\n");

	if (strchr(pin_name->get_string(), ':') != NULL) {		// ... pretty weak test ....
		// case II
		delete t;
		t = get_token();
		if (t->type != LIBRPAR)	pe("expected rpar for bus pin\n");

		delete t;
		t = get_token();
		if (t->type != LIBLCURLY)	pe("expected lcurly for bus pin\n");

		char *direction = dir_token->get_string();
		if (strcmp(direction, "output") == 0) {
			OUTPIN *outpin = new OUTPIN(name_token->get_string());
			outpin->is_array = true;
			outpin->low_index = bustype->bit_from;
			outpin->high_index = bustype->bit_to;
			cell->outpinlist = new ListOfOUTPIN(outpin, cell->outpinlist);
			read_output_pin(outpin, cell);

		} else if (strcmp(direction, "input") == 0) {
			INPIN *inpin = new INPIN(name_token->get_string());
			inpin->is_array = true;
			inpin->low_index = bustype->bit_from;
			inpin->high_index = bustype->bit_to;
			cell->inpinlist = new ListOfINPIN(inpin, cell->inpinlist);
			read_input_pin(inpin);

		} else	pe("what pin direction???");

		t = get_token();
		if (t->type != LIBRCURLY)	pe("expected LCURLY for bus expr");

		delete t;
		delete dir_token;
		delete name_token;
		return RC_NOMINAL;
	}

	// case III
	while (1) {
		delete t;
		t = get_token();
		if (t->type != LIBRPAR)		pe("expected rpar for bus pin 2\n");

		delete t;
		t = get_token();
		if (t->type != LIBLCURLY)	pe("expected lcurly for bus pin 2\n");

		char *direction = dir_token->get_string();
		if (strcmp(direction, "output") == 0) {
			OUTPIN *outpin = new OUTPIN(pin_name->get_string());
			cell->outpinlist = new ListOfOUTPIN(outpin, cell->outpinlist);
			read_output_pin(outpin, cell);

		} else if (strcmp(direction, "input") == 0) {
			INPIN *inpin = new INPIN(pin_name->get_string());
			cell->inpinlist = new ListOfINPIN(inpin, cell->inpinlist);
			read_input_pin(inpin);

		} else	pe("what pin direction???");

		t = get_token();
		if (t->type == LIBRCURLY)	break;

		if (t->type != LIB_PIN)		pe("junk in bus list of pins case III\n");
		delete t;

		t = get_token();
		if (t->type != LIBLPAR)		pe("expected lpar in pin name for bus 2\n");

		delete pin_name;
		pin_name = get_token();
		if (pin_name->type != LIBSTRING)	pe("expected pin name for bus 2\n");
	}

	delete t;
	delete pin_name;
	delete dir_token;
	delete name_token;
	return RC_NOMINAL;
}

rc_t
LIBFILE::read_output_pin(OUTPIN *outpin, CELL *cell)
{
	outpin->direction = DIRECTION_OUT;
	while (1) {
		LIBTOKEN *t = get_token();
		switch (t->type) {
		    case LIB_TIMING: {
			delete t;

			OUTPINTIMING *outpintiming = read_outpintiming();
			if (outpintiming == NULL) return RC_FAILED;
			if (outpintiming->sense == UNKNOWN_SENSE) {
				printf("ERROR: sense not specified in timing table for pin \"%s\", cell \"%s\"\n", outpin->name, cell->name);
			}
			outpintiming->outpin = outpin;
			outpin->outpintiminglist = new ListOfOUTPINTIMING(outpintiming, outpin->outpintiminglist);
			break;
		    }

		    case LIB_FUNCTION: {
			delete t;

			t = get_token();
			if (t->type != LIBCOLON)	pe("bad function expr 1");
			delete t;

			t = get_token();
			if (t->type != LIBSTRING)		pe("expected function");
			// outpin->function = strdup(t->get_string());
			delete t;	

			if (next_is_semicolon() != true)	pe("bad function expr 2");
		    }

		    case LIB_DIRECTION:
			// redundant, but it happens.
			// ... should check to be sure it's right, strictly....
			delete t;
			skip_to_semicolon();
			break;

		    // case LIB_MAX_CAPACITANCE:
		    // case LIB_MAX_FANOUT:
		    // case LIB_MAX_TRANSITION:
		    // case LIB_THREE_STATE:
		    case LIB_CAPACITANCE:
			delete t;
			skip_to_semicolon();
			break;

		    case LIBRCURLY:
			delete t;
			return RC_NOMINAL;

		    case LIBSTRING:
			// printf("unrecognized variable in libfile in output pin: \"%s\" (ignored)\n", 
			//    t->get_string());
			delete t;
			skip_to_semicolon();
			break;

		    default:
			pe("junk in outpin???");
			delete t;
			skip_to_semicolon();
			break;
		}			
	}

	// not reached
}

rc_t
LIBFILE::read_input_pin(INPIN *inpin)
{
	inpin->direction = DIRECTION_IN;

	while (1) {
		LIBTOKEN *t = get_token();
		switch (t->type) {

		    case LIBSTRING:
			// printf("unrecognized variable in libfile in input pin: \"%s\" (ignored)\n", 
			//    t->get_string());
			delete t;
			skip_to_semicolon();
			break;

		    case LIB_CAPACITANCE:
			delete t;
		
			t = get_token();
			if (t->type != LIBCOLON)	pe("bad capacitance expr 1");
			delete t;

			t = get_token();
			if (t->is_float() != true)		pe("expected capacitance");
			inpin->capacitance = t->get_float();
			delete t;	

			if (next_is_semicolon() != true)	pe("bad capacitance expr 2");
			break;

		    case LIB_TIMING:
			delete t;

			if (inpin->inpintiming == NULL) {
				inpin->inpintiming = new INPINTIMING();
			}

			t = get_token();
			if (t->type != LIBLPAR)		pe("read input timing 1");
			delete t;

			t = get_token();
			if (t->type != LIBRPAR)		pe("read input timing 2");
			delete t;

			t = get_token();
			if (t->type != LIBLCURLY)	pe("read input timing 3");
			delete t;

			while (1) {
				BOOLEAN is_setup;

				t = get_token();
				switch (t->type) {

				    case LIB_TIMING_TYPE: {
					delete t;

					t = get_token();
					if (t->type != LIBCOLON)	pe("read input timing 4");
					delete t;

					t = get_token();
					if (t->type != LIBSTRING)		pe("read input timing 5");
					char *timing_type = t->get_string();
					if	(strcmp(timing_type, "setup_rising") == 0)	is_setup = true;
					else if	(strcmp(timing_type, "setup_falling") == 0)	is_setup = true;
					else if (strcmp(timing_type, "hold_rising") == 0)	is_setup = false;
					else if (strcmp(timing_type, "hold_falling") == 0)	is_setup = false;
					else				pe("read input timing 6");
					delete t;	

					if (next_is_semicolon() != true)	pe("read input timing 7");
					continue;
				    }

				    case LIB_RELATED_PIN: {
					delete t;

					t = get_token();
					if (t->type != LIBCOLON)	pe("read input timing 8");
					delete t;

					t = get_token();
					if (t->type != LIBSTRING)		pe("read input timing 9");
					char *related_pinname = t->get_string();
					if (inpin->inpintiming->related_pinname == NULL) {
						inpin->inpintiming->related_pinname = strdup(related_pinname);
					} else if (strcmp(inpin->inpintiming->related_pinname, related_pinname) != 0) {
									pe("read input timing 10");
					}

					if (next_is_semicolon() != true)	pe("read input timing 10");
					continue;
				    }

				    case LIB_RISE_CONSTRAINT: {
					delete t;

					LUTABLE *lutable = read_lu_table();
					if (is_setup == true) {
						inpin->inpintiming->setup_rise = lutable; 
					} else {
						inpin->inpintiming->hold_rise = lutable;
					}	
					continue;
				    }	

				    case LIB_FALL_CONSTRAINT: {
					delete t;

					LUTABLE *lutable = read_lu_table();
					if (is_setup == true) {
						inpin->inpintiming->setup_fall = lutable;
					} else {
						inpin->inpintiming->hold_fall = lutable;
					}	
					continue;
				    }

				    case LIBRCURLY:
					break;

				    default:
					pe("read input timing 12");
					break;
				}
				break;
			}
			break;

		    case LIB_FANOUT_LOAD:
			delete t;
			skip_to_semicolon();
			break;

		    case LIB_CLOCK:
			delete t;
			inpin->is_clock_pin = true;
			skip_to_semicolon();
			break;

		    case LIB_DIRECTION:
			// redundant, but it happens.
			// ... should check to be sure it's right, strictly....
			delete t;
			skip_to_semicolon();
			break;

		    case LIB_FUNCTION:
			delete t;
			skip_to_semicolon();
			break;

		    case LIBRCURLY:
			delete t;
			return RC_NOMINAL;

		    default:
			if (t->type == LIBSTRING) {
				delete t;
				skip_across_body();
				continue;
			}
			else {			
				delete t;									
				pe("junk in inpin???");
				return RC_FAILED;
			}
		}			
	}

	// not reached
}

rc_t
LIBFILE::read_inout_pin(INPIN *inpin, OUTPIN *outpin, CELL *cell)
{
	inpin->direction = DIRECTION_INOUT;
	outpin->direction = DIRECTION_INOUT;

	while (1) {
		LIBTOKEN *t = get_token();
		switch (t->type) {

		    // outpin stuff		

		    case LIB_TIMING: {
		        delete t;

			OUTPINTIMING *outpintiming = read_outpintiming();
			if (outpintiming == NULL) return RC_FAILED;
			if (outpintiming->sense == UNKNOWN_SENSE) {
				printf("ERROR: sense not specified in timing table for pin \"%s\", cell \"%s\"\n", outpin->name, cell->name);
			}
			outpintiming->outpin = outpin;
			outpin->outpintiminglist = new ListOfOUTPINTIMING(outpintiming, outpin->outpintiminglist);
			break;
		    }

		    // inpin stuff

		    case LIB_CAPACITANCE:
			delete t;
		
			t = get_token();
			if (t->type != LIBCOLON)	pe("bad capacitance expr 1");
			delete t;

			t = get_token();
			if (t->is_float() != true)		pe("expected capacitance");
			inpin->capacitance = t->get_float();
			delete t;	

			if (next_is_semicolon() != true)	pe("bad capacitance expr 2");
			break;

		    case LIB_CLOCK:
			delete t;
			inpin->is_clock_pin = true;
			skip_to_semicolon();
			break;

		    case LIB_DIRECTION:
			// redundant, but it happens.
			// ... should check to be sure it's right, strictly....
			delete t;
			skip_to_semicolon();
			break;

		    case LIB_FANOUT_LOAD:
			delete t;
			skip_to_semicolon();
			break;

		    case LIB_FUNCTION:
			delete t;
			skip_to_semicolon();
			break;

		    case LIBRCURLY:
			delete t;
			return RC_NOMINAL;

		    default:
			if (t->type == LIBSTRING) {
				delete t;
				skip_across_body();
				continue;
			}
			else {			
				delete t;									
				pe("junk in inpin???");
				return RC_FAILED;
			}
		}			
	}

	// not reached
}


OUTPINTIMING *
LIBFILE::read_outpintiming()
{
	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("expected timing arg");
	delete t;

	t = get_token();
	if (t->type != LIBRPAR)		pe("actual args for timing???");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected pin body");
	delete t;

	OUTPINTIMING *outpintiming = new OUTPINTIMING();

	while (1) {
		t = get_token();
		switch (t->type) {
		    case LIB_TIMING_TYPE: {
			t = get_token();
			if (t->type != LIBCOLON)	pe("timing type colon");
			delete t;

			t = get_token();
			if (t->type != LIBSTRING)		pe("timing type");
			char *sense = t->get_string();
			if (strcmp(sense, "rising_edge") == 0) {
				outpintiming->sense = RISING_EDGE;
			} else if (strcmp(sense, "falling_edge") == 0) {
				outpintiming->sense = FALLING_EDGE;
			} else if (strcmp(sense, "clear") == 0) {
				;	// XXX ... don't know what this means ... or at least, what to do ...
			} else if (strcmp(sense, "preset") == 0) {
				;	// XXX ... don't know what this means ... or at least, what to do ...
			} else if (strcmp(sense, "three_state_enable") == 0) {
				;	// XXX ... MUCH LESS this one ....
			} else if (strcmp(sense, "three_state_disable") == 0) {
				;	// XXX ... MUCH LESS this one ....
			} else {
				pe("what timing type???");
			}
			delete t;

			if (next_is_semicolon() != true)	pe("timing sense semicolon");
		
		    }	break;

		    case LIB_TIMING_SENSE: {
			delete t;

			t = get_token();
			if (t->type != LIBCOLON)	pe("timing sense colon");
			delete t;

			t = get_token();
			if (t->type != LIBSTRING)		pe("timing sense");
			char *sense = t->get_string();
			if (strcmp(sense, "positive_unate") == 0) {
				outpintiming->sense = POSITIVE_SENSE;
			} else if (strcmp(sense, "negative_unate") == 0) {
				outpintiming->sense = NEGATIVE_SENSE;
			} else if (strcmp(sense, "rising_edge") == 0) {
				outpintiming->sense = RISING_EDGE;
			} else if (strcmp(sense, "falling_edge") == 0) {
				outpintiming->sense = FALLING_EDGE;
			} else if (strcmp(sense, "non_unate") == 0) {
				; // get sense from timing_type, I hope
			} else {
				pe("what timing sense???");
			}
			delete t;

			if (next_is_semicolon() != true)	pe("timing sense semicolon");
		
			break;
		    }

		    case LIB_RELATED_PIN: {
			delete t;

			t = get_token();
			if (t->type != LIBCOLON)	pe("related pin colon");
			delete t;

			t = get_token();
			if (t->type != LIBSTRING)	pe("related pin");
			outpintiming->related_pinname = strdup(t->get_string());
			delete t;

			if (next_is_semicolon() != true)	pe("related pin semicolon");
			break;
		    }

		    case LIB_CELL_FALL:
			delete t;
			outpintiming->cell_fall = read_lu_table();
			break;

		    case LIB_FALL_TRANSITION:
			delete t;
			outpintiming->fall_transition = read_lu_table();
			break;

		    case LIB_CELL_RISE:
			delete t;
			outpintiming->cell_rise = read_lu_table();
			break;

		    case LIB_RISE_TRANSITION:
			delete t;
			outpintiming->rise_transition = read_lu_table();
			break;

		    case LIBRCURLY:
			delete t;
			return outpintiming;

		    default:
			pe("junk in outpin???");
			return NULL;
		}			
	}

	// not reached
}

LUTABLE *
LIBFILE::read_lu_table()
{
	ignore_quotes = true;

	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("read lutable 1");
	delete t;

	LIBTOKEN *table_type_token = get_token();
	if (table_type_token->type != LIBSTRING)	pe("read lutable 2");

	t = get_token();
	if (t->type != LIBRPAR)		pe("read lutable 3");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("read lutable 4");
	delete t;

	LUTABLE *lutable;
	char *table_type = table_type_token->get_string();
	if (strcmp(table_type, "scalar") == 0) {
		lutable = new LUTABLE("scalar");
	} 
	else {
		ListOfLUTABLE *tl = template_lutablelist;
		while (tl != NULL) {
			LUTABLE *table_template = tl->lutable;
	
			if (strcmp(table_type, table_template->name) == 0) {
				lutable = new LUTABLE(*table_template);
				break;
			}

			tl = tl->next;
		}
		if (tl == NULL) {
			pe("no template for this table");
			return NULL;
		}
	}
		

	t = get_token();
	if (t->type == LIB_INDEX_1) {
		delete t;

		t = get_token();
		if (t->type != LIBLPAR)		pe("expected lpar");
		delete t;
	
		for (int i = 0; i < lutable->index_1_size; i++) {
			t = get_token();
			if (t->is_float() != true)	pe("expected index");
			lutable->index_1[i] = t->get_float();
			delete t;
		}
	
		t = get_token();
		if (t->type != LIBRPAR)		pe("expected rpar: table not right size?");
		delete t;
	
		if (next_is_semicolon() != true)	pe("expected semicolon");

		t = get_token();
	}

	if (t->type == LIB_INDEX_2) {
		delete t;

		t = get_token();
		if (t->type != LIBLPAR)		pe("expected lpar");
		delete t;
	
		for (int i = 0; i < lutable->index_2_size; i++) {
			t = get_token();
			if (t->is_float() != true)	pe("expected index");
			lutable->index_2[i] = t->get_float();
			delete t;
		}
	
		t = get_token();
		if (t->type != LIBRPAR)		pe("expected rpar; table not right size?");
		delete t;
	
		if (next_is_semicolon() != true)	pe("expected semicolon");
		t = get_token();
	}

	if (t->type == LIB_VALUES) {
		delete t;


		if (lutable->index_1_size == 0) {
			lutable->values_size = 1;
		}
		else if (lutable->values_size == 0) {
			lutable->values_size = 
			    lutable->index_1_size * lutable->index_2_size;
			// lutable->values = new float[lutable->values_size];
		}

		t = get_token();
		if (t->type != LIBLPAR)		pe("expected lpar");
		delete t;
	
		for (int i = 0; i < lutable->values_size; i++) {
			t = get_token();
			if (t->is_float() != true)	pe("expected value");
			lutable->values[i] = t->get_float();
			delete t;
		}
	
		t = get_token();
		if (t->type != LIBRPAR)		pe("expected rpar; table not right size?");
		delete t;
	
		if (next_is_semicolon() != true)	pe("expected semicolon");
		t = get_token();
	}

	if (t->type != LIBRCURLY)	pe("expected rcurly");
	delete t;

	ignore_quotes = false;
	return lutable;
}

rc_t
LIBFILE::read_type()
{
	LIBTOKEN *t = get_token();
	if (t->type != LIBLPAR)		pe("expected type name arg");
	delete t;

	LIBTOKEN *nametoken = get_token();
	if (nametoken->type != LIBSTRING)	pe("expected type name");

	t = get_token();
	if (t->type != LIBRPAR)		pe("expected type name arg 2");
	delete t;

	t = get_token();
	if (t->type != LIBLCURLY)	pe("expected type body");
	delete t;

	int bit_from = -1;
	int bit_to = -1;
	while (1) {
		t = get_token();
		switch (t->type) {
		    case LIB_BIT_FROM:
			delete t;
		
			t = get_token();
			if (t->type != LIBCOLON)	pe("bad bit_from expr 1");
			delete t;

			t = get_token();
			if (t->type != LIBINTEGER)		pe("expected bit_from");
			bit_from = t->get_integer();
			delete t;	

			if (next_is_semicolon() != true)	pe("bad bit_from expr 2");
			continue;

		    case LIB_BIT_TO:
			delete t;
		
			t = get_token();
			if (t->type != LIBCOLON)	pe("bad bit_to expr 1");
			delete t;

			t = get_token();
			if (t->type != LIBINTEGER)		pe("expected bit_to");
			bit_to = t->get_integer();
			delete t;	

			if (next_is_semicolon() != true)	pe("bad bit_to expr 2");
			continue;

		    case LIB_BASE_TYPE:
		    case LIB_DATA_TYPE:
		    case LIB_BIT_WIDTH:
		    case LIB_DOWNTO:
			delete t;
			skip_to_semicolon();
			continue;
	
		    case LIBRCURLY:
			delete t;
			break;	

		    default:
			pe("junk in type???");
			return RC_FAILED;
		}			
		break;
	}

	if (bit_from == -1)	pe("bit_from not specified");
	if (bit_to == -1)	pe("bit_to not specified");

	if (bit_to < bit_from) {
		int temp = bit_to;
		bit_to = bit_from;
		bit_from = temp;
	}

	BUSTYPE *bustype = new BUSTYPE(nametoken->get_string(), bit_from, bit_to);
	delete nametoken;
	bustypelist = new ListOfBUSTYPE(bustype, bustypelist);
	return RC_NOMINAL;
}

rc_t
LIBFILE::read_ff(CELL *cell)
{
	// ... "ff" or "latch" ....

	cell->is_flipflop = true;
	skip_across_body();

	return RC_NOMINAL;
}

#define	SVAL_SIZE		5000
char	sval[SVAL_SIZE+3];
int	previous_lineno;

LIBTOKEN *
LIBFILE::get_token() {

	if (ungotten_libtokenlist != NULL) {
		LIBTOKEN *t = ungotten_libtokenlist->libtoken;
		ungotten_libtokenlist = ungotten_libtokenlist->next;
		return t;
	}
	previous_lineno = lineno;
	
	char c;
	char *ptr;
	int char_counter = 1;

	// skip leading whitespace
	while(1) {
		c = fgetc(f);
		if (c == '\\')  continue;	// XXX .... if we get escape chars other than \n, we are in trouble ....
		if (c == '\n')	lineno++;
		if (c == EOF)	return new LIBTOKEN(LIBENDOFFILE);
		if (!isspace(c))	break;
	}

	// punctuation
	switch (c) {
	    case '(':	return new LIBTOKEN(LIBLPAR);
	    case ')':	return new LIBTOKEN(LIBRPAR);
	    case '{':	return new LIBTOKEN(LIBLCURLY);
	    case '}':	return new LIBTOKEN(LIBRCURLY);
	    case ':':	return new LIBTOKEN(LIBCOLON);
	    case ';':	return new LIBTOKEN(LIBSEMICOLON);
	    case '*':	return new LIBTOKEN(LIBSTAR);
	    default:	break;
	}

	// things in quotes
	// XXX ... this is a *really* ugly hack, due to my being 
	// to lazy to write something that parses tables in a nice 
	// general way.... we want to ignore quotes when doing
	// tables, but other times we need not to...

	if (c == '\"')	{

		if (ignore_quotes == true) {
			return get_token();
		}

		ptr = sval;
		while (1) {
			c = fgetc(f);
			if (c == '\n')	lineno++;
			if (c == '"')	break;
			*ptr++ = c;
		}
		*ptr = '\0';
		return new LIBTOKEN(LIBSTRING, sval);
	}
		

	// comma lists
	//	I don't know why we care about commas either, except as separators.
	if (c == ',')	return get_token();

	// comments
	if (c == '/') {
		c = fgetc(f);
		if (c == '\n')	lineno++;

		else if (c == '/') {	// line comment 
			while (1) {
				c = fgetc(f);
				if (c == EOF)	return new LIBTOKEN(LIBENDOFFILE);
				if (c == '\n') {
					lineno++;
					return get_token();
				}
			}
		}
		
		else if (c == '*') {	// block comment
			while (1) {
				switch (fgetc(f)) {
				    case EOF:	return new LIBTOKEN(LIBENDOFFILE);
				    case '\n':  {
					lineno++;
					break;
				    }
				    case '*':	{
					c = fgetc(f);
					if (c == '/')	return get_token();
					if (c == '\n')	lineno++;	
					break;
				    }
				    default:	break;	
				}
			}
		}

		else {
			return new LIBTOKEN(LIBSLASH);
		}
		// not reached
	}


	// if it starts with a number, it's a number... integer or float...
	// ... besides a number, might be a minus '-' or decimal '.'
	if (isdigit(c) || c == '-' || c == '.') {
		ptr = sval;

		if (c == '.') goto float_token;

		*ptr++ = c; char_counter++;
		while (1) {
			c = fgetc(f);
			if (c == EOF)		break; 
			if (c == '\n')		lineno++;
			if (!isdigit(c)) {
				if (c == '.') goto float_token;
				ungetc(c, f);
				break;	
			}
			*ptr++ = c; char_counter++;

			if (char_counter++ >= SVAL_SIZE) {
				printf("read_libtoken: foolish long number?\n");
				return new LIBTOKEN(LIBINVALID);
			}
		}
		*ptr = '\0';
		return new LIBTOKEN(LIBINTEGER, atoi(sval));
	}

	// the only thing left is a string
	ptr = sval;
	*ptr++ = c; char_counter++; 
	while (1) {
		c = fgetc(f);
		if (c == '\n') {
			// put the newline back so the is_semicolon hack will
			// work for lines that end with a string
			ungetc(c, f);
			// lineno++;
			break;
		}
		if (isalnum(c)	||   
		    c == '_'	|| 
		    // c == ':'	|| 
		    c == '['	|| 
		    c == ']'	) {
			*ptr++ = c; char_counter++;
			if (char_counter >= SVAL_SIZE) {
				printf("read_libtoken: foolish long string?\n");
				return new LIBTOKEN(LIBINVALID);
			}
			continue;
		}

		else {
			ungetc(c, f);
			break;
		}
	}
	*ptr = '\0';

	// is this string a keyword?

	if	(strcmp(sval, "area") == 0)			return new LIBTOKEN(LIB_AREA);

	else if (strcmp(sval, "base_type") == 0)		return new LIBTOKEN(LIB_BASE_TYPE);
	else if (strcmp(sval, "bit_from") == 0)			return new LIBTOKEN(LIB_BIT_FROM);
	else if (strcmp(sval, "bit_to") == 0)			return new LIBTOKEN(LIB_BIT_TO);
	else if (strcmp(sval, "bit_width") == 0)		return new LIBTOKEN(LIB_BIT_WIDTH);
	else if (strcmp(sval, "bus") == 0)			return new LIBTOKEN(LIB_BUS);
	else if (strcmp(sval, "bus_type") == 0)			return new LIBTOKEN(LIB_BUS_TYPE);
	else if (strcmp(sval, "capacitance") == 0)		return new LIBTOKEN(LIB_CAPACITANCE);
	else if (strcmp(sval, "cell") == 0)			return new LIBTOKEN(LIB_CELL);
	else if (strcmp(sval, "cell_fall") == 0)		return new LIBTOKEN(LIB_CELL_FALL);
	else if (strcmp(sval, "cell_rise") == 0)		return new LIBTOKEN(LIB_CELL_RISE);
	else if (strcmp(sval, "clock") == 0)			return new LIBTOKEN(LIB_CLOCK);
	else if (strcmp(sval, "data_type") == 0)		return new LIBTOKEN(LIB_DATA_TYPE);
	else if (strcmp(sval, "direction") == 0)		return new LIBTOKEN(LIB_DIRECTION);
	else if (strcmp(sval, "dont_use") == 0)			return new LIBTOKEN(LIB_DONT_USE);
	else if (strcmp(sval, "downto") == 0)			return new LIBTOKEN(LIB_DOWNTO);
	else if (strcmp(sval, "fall_constraint") == 0)		return new LIBTOKEN(LIB_FALL_CONSTRAINT);
	else if (strcmp(sval, "fall_transition") == 0)		return new LIBTOKEN(LIB_FALL_TRANSITION);
	else if (strcmp(sval, "fanout_load") == 0)		return new LIBTOKEN(LIB_FANOUT_LOAD);
	else if (strcmp(sval, "ff") == 0)			return new LIBTOKEN(LIB_FF);
	else if (strcmp(sval, "function") == 0)			return new LIBTOKEN(LIB_FUNCTION);
	else if (strcmp(sval, "index_1") == 0)			return new LIBTOKEN(LIB_INDEX_1);
	else if (strcmp(sval, "index_2") == 0)			return new LIBTOKEN(LIB_INDEX_2);
	else if (strcmp(sval, "latch") == 0)			return new LIBTOKEN(LIB_LATCH);
	else if (strcmp(sval, "library") == 0)			return new LIBTOKEN(LIB_LIBRARY);
	else if (strcmp(sval, "lu_table_template") == 0)	return new LIBTOKEN(LIB_LU_TABLE_TEMPLATE);
	else if (strcmp(sval, "pin") == 0)			return new LIBTOKEN(LIB_PIN);
	else if (strcmp(sval, "related_pin") == 0)		return new LIBTOKEN(LIB_RELATED_PIN);
	else if (strcmp(sval, "rise_constraint") == 0)		return new LIBTOKEN(LIB_RISE_CONSTRAINT);
	else if (strcmp(sval, "rise_transition") == 0)		return new LIBTOKEN(LIB_RISE_TRANSITION);
	else if (strcmp(sval, "table_lookup") == 0)		return new LIBTOKEN(LIB_TABLE_LOOKUP);
	else if (strcmp(sval, "test_cell") == 0)		return new LIBTOKEN(LIB_TEST_CELL);
	else if (strcmp(sval, "timing") == 0)			return new LIBTOKEN(LIB_TIMING);
	else if (strcmp(sval, "timing_sense") == 0)		return new LIBTOKEN(LIB_TIMING_SENSE);
	else if (strcmp(sval, "timing_type") == 0)		return new LIBTOKEN(LIB_TIMING_TYPE);
	else if (strcmp(sval, "type") == 0)			return new LIBTOKEN(LIB_TYPE);
	else if (strcmp(sval, "variable_1") == 0)		return new LIBTOKEN(LIB_VARIABLE_1);
	else if (strcmp(sval, "variable_2") == 0)		return new LIBTOKEN(LIB_VARIABLE_2);
	else if (strcmp(sval, "values") == 0)			return new LIBTOKEN(LIB_VALUES);
	
	// regular string token
	return new LIBTOKEN(LIBSTRING, sval);

    float_token: {
	*ptr++ = c;	// ... the decimal point
	while (1) {
		c = fgetc(f);
		if (!isdigit(c)) {
			ungetc(c, f);
			break;	
		}
		*ptr++ = c; char_counter++;
		if (char_counter++ >= SVAL_SIZE) {
			printf("read_libtoken: foolish long float?\n");
			return new LIBTOKEN(LIBINVALID);
		}
	}
	*ptr = '\0';
	float f;
	int rv = sscanf(sval, "%f", &f);
	if (rv != 1) {
		printf("read_libtoken: can't read float?\n");
		return new LIBTOKEN(LIBINVALID);
	}
	return new LIBTOKEN(LIBFLOAT, f);
    }
	// not reached	
}	

void
LIBFILE::unget_token(LIBTOKEN *t)
{
	ungotten_libtokenlist = new ListOfLIBTOKEN(t, ungotten_libtokenlist);
}

BOOLEAN
LIBFILE::next_is_semicolon()
{
	LIBTOKEN *t = get_token();
	if (t->type == LIBSEMICOLON) {
		delete t;
		return true;
	}

	// dirty rotten hack; see header
	// ... we aren't very strict about requireing semis....
	if (lineno != previous_lineno) {
		unget_token(t);
		return true;
	}
		
	return false;
}



void
LIBFILE::skip_to_semicolon()
{
	// .... see note in header file ...

	while (1) {
		char c = fgetc(f);
		switch (c) {
		    case EOF:
		    case ';': {
			return;
		    }

		    case '\n': {
			// printf("WARNING line %d, semicolon missing at end of expression\n", lineno);
			lineno++;
			return;
		    }

		    default:
			;
		}
	}
	// not reached
}

void
LIBFILE::skip_across_body()
{
	// assumes we are in a context like:
	// case I
	// "keyword (args) {
	//	body
	// }"
	// or
	// case II
	// "keyword (args) body_statment ;"
	// *or*
	// case III
	// "keyword (args) body_statment"	(no semicolon)

	// ... where we just read (and delete) the keyword, and we want to 
	// pitch the whole thing.  ...there may be nested expressions.

	int nest_count = 0;
	int original_lineno = lineno;
	while (1) {
		LIBTOKEN *t = get_token();

		if (nest_count == 0		&&
		    lineno != original_lineno	) {
			// case III
			unget_token(t);
			return;
		}

		switch (t->type) {
		    case LIBENDOFFILE:	{
			pe("EOF while skip to curly");
			return;
		    }

		    case LIBSEMICOLON:
			if (nest_count == 0) {
				// case II
				delete t;
				return;
			}
			break;

		    case LIBLCURLY:
			nest_count++;
			break;
			
		    case LIBRCURLY:
			nest_count--;
			if (nest_count == 0) {
				// case I
				delete t;
				return;
			}
			break;

		    default:	;
		}
		delete t;
	}
	// not reached
}

void
LIBFILE::pe(char *msg)
{
	printf("ERROR line %d: %s\n", lineno, msg);
	were_read_errors = true;
	return;
}


//////////////////////////////////////////////////
	
LIBTOKEN::LIBTOKEN(LIBTOKEN_TYPE arg_type)
   : type(arg_type), string(NULL), integer(0), floater(0.0)
{
}	

LIBTOKEN::LIBTOKEN(LIBTOKEN_TYPE arg_type, char *arg_string)
    : type(arg_type), integer(0), floater(0.0)
{
	if (type != LIBSTRING) {
		type = LIBINVALID;
		return;
	}
	string = strdup(arg_string);
}

LIBTOKEN::LIBTOKEN(LIBTOKEN_TYPE arg_type, int arg_integer)
    : type(LIBINTEGER), string(NULL), floater(0.0)
{
	if (arg_type != LIBINTEGER) {
		type = LIBINVALID;
		return;
	}
	integer = arg_integer;
}

LIBTOKEN::LIBTOKEN(LIBTOKEN_TYPE arg_type, float arg_float)
    : type(LIBFLOAT), string(NULL), integer(0)
{
	if (arg_type != LIBFLOAT) {
		type = LIBINVALID;
		return;
	}
	floater = arg_float;
}

LIBTOKEN::~LIBTOKEN()
{
	if (string) delete string;
}

char *
LIBTOKEN::get_string()
{
	if (type != LIBSTRING) {
		printf("get_string of non-string token\n");
		return "LIBTOKEN::get_string-ERROR";
	}

	return string;
}

int
LIBTOKEN::get_integer()
{
	if (type != LIBINTEGER) {
		printf("get_integer of non-integer token\n");
		return INT_MIN;
	}

	return integer;
}

BOOLEAN
LIBTOKEN::is_float()
{
	switch (type) {
	    case LIBFLOAT:
	    case LIBINTEGER:
		return true;
	    default:
		return false;
	}
	// not reached
}

float
LIBTOKEN::get_float()
{
	switch (type) {
	    case LIBFLOAT:	return floater;
	    case LIBINTEGER:	return (float)integer;
	    default:
		printf("get_float of non-float token\n");
		return -FLT_MAX;
	}

	return floater;
}

ListOfLIBTOKEN::ListOfLIBTOKEN(LIBTOKEN *arg_libtoken, ListOfLIBTOKEN *arg_next) 
	: libtoken(arg_libtoken), next(arg_next)
{
}

ListOfLIBTOKEN::~ListOfLIBTOKEN()
{
	if (next != NULL)	delete next;
}

///////////////////////////

BUSTYPE::BUSTYPE(char *arg_name, int arg_bit_from, int arg_bit_to)
	: bit_from(arg_bit_from), bit_to(arg_bit_to)
{
	name = strdup(arg_name);
}	

BUSTYPE::~BUSTYPE()
{
	delete name;
}


ListOfBUSTYPE::ListOfBUSTYPE(BUSTYPE *arg_bustype, ListOfBUSTYPE *arg_next) 
	: bustype(arg_bustype), next(arg_next)
{
}

ListOfBUSTYPE::~ListOfBUSTYPE()
{
	if (next != NULL)	delete next;
}
