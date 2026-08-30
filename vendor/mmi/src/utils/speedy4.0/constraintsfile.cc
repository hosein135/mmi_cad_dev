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

#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


FIXFILE::FIXFILE(char *arg_name)
	: f(NULL), lineno(0)
{
	name = strdup(arg_name);
}

FIXFILE::~FIXFILE()
{
	delete name;
	if (f) fclose(f);
}


rc_t
FIXFILE::read() 
{
	if (design == NULL) {
		printf("FIXFILE::read: no design???\n");
		return RC_FAILED;
	}

	f = fopen(name, "r");
	if (f == NULL)	{
		printf("WARNING: fopen fixfile \"%s\" failed\n", name);
		return RC_NOMINAL;
	}
	lineno = 0;
	
	while (1) {

		char *rv = fgets(linebuf, LINEBUFSIZE, f);
		lineno++;
		if (rv == NULL)	{
			*linebuf = '\0';
			return RC_NOMINAL;
		}

		char *p = linebuf;

		while (isspace(*p))	p++;
		
		// empty line?
		if (*p == '\0')		continue;

		// comment line?
		if (*p == '#')		continue;

		// what command?
		/////////////////////////////
		if (strncmp(p, "dont_resize", 11) == 0) {
#ifdef RESIZE_FEATURE
			p += 11;
			while (isspace(*p))	p++;

			char *kind = p;
			while (!isspace(*p))	p++;
			*p++ = '\0';
			while (isspace(*p))	p++;

			rc_t rc;
			if (strcmp(kind, "cell") == 0) {
		
				char *cellname = p;
				while (!isspace(*p))	p++;
				*p++ = '\0';
			
				if (speedy_verbose == true) {
					printf("mark cell dont_resize \"%s\"\n", cellname);
				}
				rc = mark_dont_resize_cell(cellname);
			}

		/////////////////////////////
		else if (strcmp(kind, "path") == 0) {
		
				char *pathname = p;
				while (!isspace(*p))	p++;
				*p++ = '\0';
			
				if (speedy_verbose == true) {
					printf("mark path dont_resize \"%s\"\n", pathname);
				}
				rc = mark_dont_resize_path(pathname);
			}
			else {
				printf("dont resize what??? \"cell\" or \"path\"\n");
				return RC_FAILED;
			}

			if (rc != RC_NOMINAL) {
				printf("dont_resize \"%s\" failed\n", name);
				return RC_FAILED;
			}
#endif
			continue;
		}

		/////////////////////////////
		else if (strncmp(p, "is_flipflop_type", 16) == 0) {
			p += 16;
			while (isspace(*p))	p++;

			char *name = p;
			while (!isspace(*p))	p++;
			*p = '\0';

			rc_t rc = mark_as_flipflop(name);
			if (rc != RC_NOMINAL) {
				printf("mark_as_flipflop \"%s\" failed\n", name);
			}
		}

		/////////////////////////////
#ifdef RESIZE_FEATURE
		else if (strncmp(p, "mark_fast_input", 15) == 0) {
			p += 15;
			while (isspace(*p))	p++;

			char *cellname = p;
			while (!isspace(*p))	p++;
			*p = '\0';

			while (isspace(*p))	p++;

			char *pinname = p;
			while (!isspace(*p))	p++;
			*p = '\0';

			rc_t rc = mark_fast_input(cellname, pinname);
			if (rc != RC_NOMINAL) {
				printf("mark_fast_input \"%s\" failed\n", cellname);
			}
		}
#endif
		/////////////////////////////
		else {
			char *nlp = p + strlen(p) - 1;
			if (*nlp == '\n')	*nlp = '\0';
			printf("what command??? lineno %d \"%s\"\n", lineno, p);
		}
	}

	// not reached
}		

#ifdef RESIZE_FEATURE
rc_t
FIXFILE::mark_fast_input(char *cellname, char *pinname)
{
	if (::cell_library == NULL) {
		printf("cell library not loaded\n");
		return RC_FAILED;
	}

	CELL *cell = cell_library->get_cell(cellname);
	if (cell == NULL) {
		printf("cell \"%s\" not found\n", cellname);
		return RC_FAILED;
	}

	INPIN *inpin = cell->get_inpin(pinname);
	if (inpin == NULL) {
		printf("inpin \"%s\" not found on cell \"%s\"\n", pinname, cellname);
		return RC_FAILED;
	}

	inpin->relative_speed = FAST;

	// .... mark others as slow
	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		inpin = ipl->inpin;
		ipl = ipl->next;

		if (inpin->relative_speed == NOTORDERED)	inpin->relative_speed = SLOW;
	}

	return RC_NOMINAL;
}


rc_t
FIXFILE::mark_dont_resize_cell(char *cellname)
{
	// mark all instances that are contained in any instance of 
	// a particular cell type (...vg module, nl design) 
	// as not resizeable

	// ... is this a basic cell?
	CELL *basic_cell = cell_library->get_cell(cellname);
	if (basic_cell != NULL) {
		ListOfCLONE *cl = design->clonelist;
		while (cl != NULL) {
			CLONE *clone = cl->clone;
			cl = cl->next;

			if (clone->nominal_cell == basic_cell) {
				clone->is_adjustable_for_size = false;
			}
		}		
		return RC_NOMINAL;
	}


#ifdef NL_FEATURE
	return nl_interface->mark_dont_resize_cell(cellname);
#endif

	printf("ERROR: don't know how to mark_dont_resize except with nl\n");
	return RC_FAILED;
}

rc_t
FIXFILE::mark_dont_resize_path(char *pathname)
{
	// mark all instances that are inside the named cell instance
	// (vginstance, I used to say ...vg module, nl design) 
	// as not resizeable

#ifdef NL_FEATURE
	return nl_interface->mark_dont_resize_path(pathname);
#endif

	printf("ERROR: don't know how to mark_dont_resize except with nl\n");
	return RC_FAILED;
}

#endif

/////////////////////////////////////////////////////////////////

rc_t
FIXFILE::mark_as_flipflop(char *name)
{
	if (speedy_verbose == true) {
		printf("...mark_as_flipflop \"%s\"\n", name);
	}

	CELL *cell;
	ListOfCELL *cl = cell_library->celllist;
	while (cl != NULL) {
		cell = cl->cell;
		
		if (strcmp(cell->name, name) == 0)	break;

		cl = cl->next;
	}
	if (cl == NULL) {
		printf("WARNING: cell not found  \"%s\"\n", name);
		return RC_NOTFOUND;
	}

	cell->is_flipflop = true;

	// check for clock pin
	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;

		if (inpin->is_clock_pin == true)	break;
	
		ipl = ipl->next;
	}
	if (ipl == NULL) {
		printf("WARNING: no clock pin for flipflop cell \"%s\" (fixfile \"%s\")\n",
		    cell->name, name);
	}

	return RC_NOMINAL;
}


/////////////////////////////////////////////////////////

CONSTRAINTSFILE::CONSTRAINTSFILE(char *arg_name)
	: f(NULL), lineno(0), ungotten_tokenlist(NULL)
{
	name = strdup(arg_name);
}

CONSTRAINTSFILE::~CONSTRAINTSFILE()
{
	delete name;
	if (f) fclose(f);
}


rc_t
CONSTRAINTSFILE::read() 
{
	f = fopen(name, "r");
	if (f == NULL)	{
		// exxit(10001, name);
		return RC_NOTFOUND;
	}
	lineno = 1;

	static BOOLEAN did_blockpathmessage = false;
	
	while (1) {
		CFTOKEN *t = get_token();
		
		switch (t->type) {
	
		    case CFSHARP:
			delete t;
			skiptoEOL();
			break;

		    case CF_CONSTANT: {
			delete t;

			t = get_token();
			if (t->type != CFSTRING) {
				printf("lineno %d: expected net name\n", lineno);
				delete t;
				skiptoEOL();
				return RC_NOMINAL;
			}
			NET *net = design->get_net(t->get_string());
			if (net == NULL) {
				printf("lineno %d: no such net \"%s\"\n", lineno, t->get_string());
				delete t;
				skiptoEOL();
				return RC_NOMINAL;
			}
			delete t;
	
			t = get_token();
			if (t->type != CFINTEGER) {
				printf("lineno %d: expected constant value\n", lineno);
				delete t;
				skiptoEOL();
				return RC_NOMINAL;
			}

			int constant_value = t->get_integer();
			switch (constant_value) {
			    case 0:
				net->global_value = GLOBAL_ZERO;
				break;

			    case 1:
				net->global_value = GLOBAL_ONE;
				break;

			    default:
				printf("lineno %d: constant value should be 0 or 1\n", lineno);
				delete t;
				skiptoEOL();
				return RC_NOMINAL;
			}
		    } break;
			
		    case CF_ARRIVAL:
			delete t;
			read_arrival();
			break;

		    case CF_BLOCKPATH:
			delete t;

			if (did_blockpathmessage == false) {
				printf("WARNING: lineno %d: BLOCK PATH feature not implemented\n", lineno);
				did_blockpathmessage = true;
			}
			delete t;
			skiptoEOL();
			break;

		    case CF_INPUT:
			delete t;

			printf("lineno %d: read \"input\" is broken\n", lineno);
			delete t;
			skiptoEOL();
			break;

			// read_inputslew();
			// break;

		    case CF_INPUTSLEW:
			delete t;
			read_inputslew();
			break;

		    case CF_READCELLLIBRARY: {
			delete t;

			t = get_token();
			if (t->type != CFSTRING) {
				printf("lineno %d: expected celllibrary file name\n", lineno);
				skiptoEOL();
				return RC_NOMINAL;
			}
			LIBFILE *libfile = new LIBFILE(t->get_string());
			rc_t rc = libfile->read();	
			if (rc != RC_NOMINAL) {
				printf("lineno %d: read celllibrary file \"%s\" failed\n",
				    lineno, libfile->name);
			}
			printf("...read cell library file \"%s\"\n", libfile->name);
			delete libfile;
			delete t;

		    } break;	

		    case CF_SETNODECAPACITANCE:
			delete t;
			read_setnodecapacitance();
			break;

		    case CF_SETMAXPOSSIBILITIES: {
			delete t;

			t = get_token();
			if (t->type != CFINTEGER) {
				printf("lineno %d: setpossibilities what???\n", lineno);
			} else {
				pearl_maxpossibilities = t->get_integer();
			}
			delete t;

			t = get_token();
			if (t->type != CFENDOFLINE) {
				printf("lineno %d: setpossibilities junk at end???\n", lineno);
				skiptoEOL();
			}
			delete t;


		    } break;

		    case CF_TOPLEVELCELL: {
			delete t;

			t = get_token();
			if (t->type != CFSTRING) {
				printf("lineno %d: toplevelcell expected name\n", lineno);
			} else {
				top_level_cellname = strdup(t->get_string());
			}
			delete t;

			skiptoEOL();

		    } break;

		    case CFENDOFLINE:
			delete t;
			break;

		    case CFENDOFFILE:
			delete t;
			printf("\n");
			return RC_NOMINAL;

		    case CFSTRING:
			printf("lineno %d: unknown command \"%s\"\n", lineno, t->get_string());
			delete t;
			skiptoEOL();
			break;

		    default:
			printf("lineno %d: confused\n", lineno);
			delete t;
			skiptoEOL();
			break;

		}
		lineno++;
	}
	// not reached
}		

void
CONSTRAINTSFILE::skiptoEOL()
{
	CFTOKEN *t = get_token();
	while (t->type != CFENDOFLINE && t->type != CFENDOFFILE) {
		delete t;
		t = get_token();
	}
	delete t;
}

ListOfNET *
CONSTRAINTSFILE::read_input_netlist()
{
	ListOfNET *netlist = NULL;

	CFTOKEN *t = get_token();
	switch (t->type) {
	    case CFSTAR: {
		ListOfEXTCONN *el = design->extconnlist;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (extconn->outportlist != NULL) {	// .... source-type extconns ....
				netlist = new ListOfNET(extconn->outportlist->outport->net, netlist);
			}
		}
		break;
	    }

	    case CFSTRING: {
		char *netname = strdup(t->get_string());	
		t = get_token();
		switch (t->type) {
		    default: {
			unget_token(t);
			NET *net = design->get_net(netname);
			netlist = new ListOfNET(net, netlist);
			delete netname;
			break;
		    }

		    case CFLSQUARE: {
			delete t;
				
			t = get_token();
			if (t->type != CFINTEGER)		goto so_sad;
			int low_ix = t->get_integer();
			delete t;

			t = get_token();
			switch (t->type) {
			    case CFRSQUARE: {
				delete t;
				sprintf(tstr, "%s[%d]", netname, low_ix);
				NET *net = design->get_net(tstr);
				netlist = new ListOfNET(net, netlist);
				delete netname;
				break;
			    }

			    case CFCOLON: {
				delete t; 
					
				t = get_token();
				if (t->type != CFINTEGER)		goto so_sad;
				int high_ix = t->get_integer();
				delete t;

				t = get_token();
				if (t->type != CFRSQUARE)		goto so_sad;
				delete t;

				if (low_ix > high_ix) {
					int tix = low_ix; low_ix = high_ix; high_ix = tix;
				}
				for (int i = low_ix; i <= high_ix; i++) {
					sprintf(tstr, "%s[%d]", netname, i);
					NET *net = design->get_net(tstr);
					netlist = new ListOfNET(net, netlist);
				}
				delete netname;
				break;
			    }

			    default:
				goto so_sad;
				break;
			}					
			break; 
		    }		// ... case LSQUARE

		}
		break;

	    }	// ... case STRING

	    default:
		goto so_sad;
	}

	return netlist;


    so_sad:
	printf("lineno %d: confused on reading input netlist\n", lineno);
	if (t->type != CFENDOFLINE)	skiptoEOL();
	return NULL;
}


 
rc_t
CONSTRAINTSFILE::read_arrival()
{
	ListOfNET *netlist = read_input_netlist();
	if (netlist == NULL) {
		return RC_NOMINAL;
	}

	CFTOKEN *t = get_token();
	// unused field... time reference clock?
	if (t->type != CFSTRING) goto so_sad;
	delete t;

	t = get_token();
	// unused field... time reference clock edge?
	if (t->type != CFUP	&&
	    t->type != CFDOWN	) {
		goto so_sad;
	}
	delete t;

	ListOfNET *nl;	// ... fwd declaration for goto
	float f1; 
	float f2; 
	float f3; 
	float f4; 
	
	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f1 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f1, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f2 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f2, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f3 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f3, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f4 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f4, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFENDOFLINE) goto so_sad;
	delete t;

	nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		OUTPORT *outport = net->source;
		if (outport->instance->cell->type != CELLTYPE_EXTCONN) {
			printf("arrival net \"%s\": there is an internal source on this net already\n", net->get_name());
			continue;
		}

		if (outport->rising_long_path == NULL) {
			outport->rising_long_path = new PATHELEMENT(outport, true);
			outport->falling_long_path = new PATHELEMENT(outport, false);
		}			
		outport->rising_long_path->absolute_delay = f1;
		outport->falling_long_path->absolute_delay = f1;
	}
	
	delete netlist;
	return RC_NOMINAL;


    so_sad:
	printf("lineno %d: confused on 'arrival'\n", lineno);
	if (t->type != CFENDOFLINE)	skiptoEOL();
	return RC_NOMINAL;
}

rc_t
CONSTRAINTSFILE::read_inputslew()
{
	ListOfNET *netlist = read_input_netlist();
	if (netlist == NULL) {
		printf("line %d: readinputslew: no matching nets found\n", lineno);
		skiptoEOL();
		return RC_NOMINAL;
	}

	ListOfNET *nl;
	float f1;
	float f2;
	float f3;
	float f4;
	
	CFTOKEN *t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f1 = ((float)t->get_integer());	
	delete t;

	t = get_token();
	if (convert_for_units(&f1, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f2 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f2, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f3 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f3, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFINTEGER) goto so_sad;
	f4 = (float)t->get_integer();
	delete t;

	t = get_token();
	if (convert_for_units(&f4, t) != true) goto so_sad;
	delete t;

	t = get_token();
	if (t->type != CFENDOFLINE) goto so_sad;
	delete t;

	nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		if (net->global_value != NOT_GLOBAL)	continue;

		OUTPORT *outport = net->source;
		if (outport->instance->cell->type != CELLTYPE_EXTCONN) {
			printf("inputslew net \"%s\": there is an internal source on this net already\n", net->get_name());
			continue;
		}

		if (outport->rising_long_path == NULL) {
			outport->rising_long_path = new PATHELEMENT(outport, true);
			outport->falling_long_path = new PATHELEMENT(outport, false);
		}			
		outport->rising_long_path->slope_at_outport = f1;
		outport->falling_long_path->slope_at_outport = f1;
	}
	
	delete netlist;
	return RC_NOMINAL;


    so_sad:
	printf("lineno %d: confused on inputslew\n", lineno);
	if (t->type != CFENDOFLINE)	skiptoEOL();
	return RC_NOMINAL;
}

rc_t
CONSTRAINTSFILE::read_setnodecapacitance()
{
	ListOfNET *netlist = NULL;
	ListOfNET *nl;

	// XXX .... there ought to be a good way to combine figuring the netnames with
	// with read_inputslew... the silly problem is that we select nets from 
	// extconns differently in the "*" case....
	
	CFTOKEN *t = get_token();
	switch (t->type) {
	    case CFSTAR: {
		ListOfEXTCONN *el = design->extconnlist;
		while (el != NULL) {
			EXTCONN *extconn = el->extconn;
			el = el->next;

			if (extconn->inportlist != NULL) {
				netlist = new ListOfNET(extconn->inportlist->inport->net, netlist);
			}
		}
		break;
	    }

	    case CFSTRING: {
		char *netname = strdup(t->get_string());	
		t = get_token();
		switch (t->type) {
		    default: {
			unget_token(t);
			NET *net = design->get_net(netname);
			if (net == NULL) {
				printf("WARNING: net \"%s\" not found\n", netname);
			} else {
				netlist = new ListOfNET(net, netlist);
			}
			delete netname;
			break;
		    }

		    case CFLSQUARE: {
			delete t;
				
			t = get_token();
			if (t->type != CFINTEGER)		goto so_sad;
			int low_ix = t->get_integer();
			delete t;

			t = get_token();
			switch (t->type) {
			    case CFRSQUARE: {
				delete t;
				sprintf(tstr, "%s[%d]", netname, low_ix);
				NET *net = design->get_net(tstr);
				if (net == NULL) {
					printf("WARNING: net \"%s\" not found\n", netname);
				} else {
					netlist = new ListOfNET(net, netlist);
				}
				delete netname;
				break;
			    }

			    case CFCOLON: {
				delete t; 
					
				t = get_token();
				if (t->type != CFINTEGER)		goto so_sad;
				int high_ix = t->get_integer();
				delete t;

				t = get_token();
				if (t->type != CFRSQUARE)		goto so_sad;
				delete t;

				if (low_ix > high_ix) {
					int tix = low_ix; low_ix = high_ix; high_ix = tix;
				}
				for (int i = low_ix; i <= high_ix; i++) {
					sprintf(tstr, "%s[%d]", netname, i);
					NET *net = design->get_net(tstr);
					if (net == NULL) {
						printf("WARNING: net \"%s\" not found\n", netname);
					} else {
						netlist = new ListOfNET(net, netlist);
					}
				}
				delete netname;
				break;
			    }

			    default:
				goto so_sad;
				break;

			}					
			break; 
		    }		// ... case LSQUARE

		}
		break;

	    }	// ... case STRING

	    default:
		printf("lineno %d: confused on nodecap\n", lineno);
	}

	// XXX .... actually, a '+' here means ADD ON this value... like '+='...
	t = get_token();
	if (t->type == CFPLUS) {
		delete t;
		t = get_token();
	}

    {	// ... bracket inline declarations so we can skip to so_sad	
	if (t->type != CFFLOAT		&&
	    t->type != CFINTEGER	) {
		 goto so_sad;
	}
	float capacitance = t->get_float();	// picofarads, by default
	delete t;

	while (1) {
		t = get_token();
		switch (t->type) {
		    case CFSTRING: {
			if (strcmp(t->get_string(), "fF") == 0	||
			    strcmp(t->get_string(), "FF") == 0	) {
				// convert to picofarad
				capacitance /= 1000.0;
			}
			else if (strcmp(t->get_string(), "pF") == 0	||
			    strcmp(t->get_string(), "PF") == 0		) {
				// OK!
				;
			}
			else {
			    printf("don't recognize capacitve uint \"%s\"\n", t->get_string());
			    goto so_sad;
			}
		    } break;

		    case CFENDOFLINE:
			delete t;
			break;

		    default:
			goto so_sad;
		}
		break;
	}

	nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		// find the inport on this net that corresponds to the extconn....
		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			if (inport->instance->cell->type == CELLTYPE_EXTCONN) {
				inport->inpin->capacitance = capacitance;
				break;
			}
		}

		if (net->source != NULL) {	// protect from segv if .vg file is bad
			net->compute_net_characteristics();
		}
	}
	
	delete netlist;
	return RC_NOMINAL;
    }


    so_sad:
	printf("lineno %d: confused on node cap\n", lineno);
	if (t->type != CFENDOFLINE)	skiptoEOL();
	return RC_NOMINAL;
}

BOOLEAN
CONSTRAINTSFILE::convert_for_units(float *f, CFTOKEN *t)
{
	if (t->type != CFSTRING)	return false;

	char *p = t->get_string();
	switch (*p) {
	    case 'n':
	    case 'N':
		// fine
		break;

	    case 'p':
	    case 'P':
		// convert to nanos
		*f /= 1000.0;
		break;

	    default:
		return false;
	}
	return true;
}

CFTOKEN *
CONSTRAINTSFILE::get_token() {

	if (ungotten_tokenlist != NULL) {
		CFTOKEN *t = ungotten_tokenlist->cftoken;
		ungotten_tokenlist = ungotten_tokenlist->next;
		return t;
	}
	
	char c;
	char *ptr;
	int char_counter;

#define	SVAL_SIZE		5000
	char	sval[SVAL_SIZE+3];

	// skip leading whitespace
	while(1) {
		c = fgetc(f);
		if (c == EOF)	return new CFTOKEN(CFENDOFFILE);
		if (c == '\n')	break;
		if (!isspace(c))	break;
	}

	// punctuation
	switch (c) {
		// commenting these out causes a problem with eg "setnodecapacitance outnet[143:0] +10ff"
		// ... I forget the problem commenting them in causes, but no doubt it will come back....
	    case '[':	return new CFTOKEN(CFLSQUARE);
	    case ']':	return new CFTOKEN(CFRSQUARE);


	    case ':':	return new CFTOKEN(CFCOLON);
	    case '*':	return new CFTOKEN(CFSTAR);
	    case '+':	return new CFTOKEN(CFPLUS);
	    case '#':	return new CFTOKEN(CFSHARP);
	    case '^':	return new CFTOKEN(CFUP);
	    case 'v':	return new CFTOKEN(CFDOWN);
	    case '\n':	{
		return new CFTOKEN(CFENDOFLINE);
	    }
	    default:	break;
	}


	// if it starts with a number, it's an integer
	if (isdigit(c)) {
		ptr = sval;
		*ptr++ = c;
		char_counter = 1;
		while (1) {
			c = fgetc(f);
			if (c == EOF)		break; 
			if (!isdigit(c)) {
				if (c == '.') goto float_token;
				ungetc(c, f);
				break;	
			}
			*ptr++ = c;

			if (char_counter++ >= SVAL_SIZE) {
				printf("read_cftoken: foolish long number?\n");
				return new CFTOKEN(CFINVALID);
			}
		}
		*ptr = '\0';
		return new CFTOKEN(CFINTEGER, atoi(sval));
	}

	// the only thing left is a string
	ptr = sval;
	*ptr++ = c;
	char_counter = 1;
	while (1) {
		c = fgetc(f);
		// if (isalnum(c)	||   c == '_' || c == '/'  || c == '.') {
		// 	*ptr++ = c;
		// 	if (char_counter >= SVAL_SIZE) {
		// 		printf("read_cftoken: foolish long string?\n");
		// 		return new CFTOKEN(CFINVALID);
		// 	}
		// 	continue;
		// }

		if (!isspace(c)		&&
		    c != '['		) {
		 	*ptr++ = c;
		 	if (char_counter >= SVAL_SIZE) {
		 		printf("read_cftoken: foolish long string?\n");
		 		return new CFTOKEN(CFINVALID);
		 	}

		} else {
			ungetc(c, f);
			break;
		}
	}
	*ptr = '\0';

	// is this string a keyword?
	// RFE... this could be more efficient, if we care...

	if (strcmp(sval, "arrival") == 0)		return new CFTOKEN(CF_ARRIVAL);
	if (strcmp(sval, "BlockPath") == 0)		return new CFTOKEN(CF_BLOCKPATH);
	if (strcmp(sval, "constant") == 0)		return new CFTOKEN(CF_CONSTANT);
	if (strcmp(sval, "input") == 0)			return new CFTOKEN(CF_INPUT);
	if (strcmp(sval, "inputslew") == 0)		return new CFTOKEN(CF_INPUTSLEW);
	if (strcmp(sval, "readcapacitances") == 0)	return new CFTOKEN(CF_READCAPACITANCES);
	if (strcmp(sval, "readcelllibrary") == 0)	return new CFTOKEN(CF_READCELLLIBRARY);
	if (strcmp(sval, "setnodecapacitance") == 0)	return new CFTOKEN(CF_SETNODECAPACITANCE);
	if (strcmp(sval, "setmaxpossibilities") == 0)	return new CFTOKEN(CF_SETMAXPOSSIBILITIES);
	if (strcmp(sval, "toplevelcell") == 0)		return new CFTOKEN(CF_TOPLEVELCELL);

	// regular string token
	return new CFTOKEN(CFSTRING, sval);

    float_token: {
	*ptr++ = c;	// ... the decimal point
	while (1) {
		c = fgetc(f);
		if (c == EOF)		break; 
		if (!isdigit(c)) {
			ungetc(c, f);
			break;	
		}
		*ptr++ = c;
		if (char_counter++ >= SVAL_SIZE) {
			printf("read_cftoken: foolish long float?\n");
			return new CFTOKEN(CFINVALID);
		}
	}
	*ptr = '\0';
	float f;
	int rv = sscanf(sval, "%f", &f);
	if (rv != 1) {
		printf("read_cftoken: can't read float?\n");
		return new CFTOKEN(CFINVALID);
	}
	return new CFTOKEN(CFFLOAT, f);
    }

}	

void
CONSTRAINTSFILE::unget_token(CFTOKEN *t)
{
	ungotten_tokenlist = new ListOfCFTOKEN(t, ungotten_tokenlist);
}


CFTOKEN::CFTOKEN(CFTOKEN_TYPE arg_type)
   : type(arg_type), string(NULL), integer(0), floater(0.0)
{
}	

CFTOKEN::CFTOKEN(CFTOKEN_TYPE arg_type, char *arg_string)
    : type(arg_type), integer(0), floater(0.0)
{
	if (type != CFSTRING) {
		type = CFINVALID;
		return;
	}
	string = strdup(arg_string);
}

CFTOKEN::CFTOKEN(CFTOKEN_TYPE arg_type, int arg_integer)
    : type(CFINTEGER), string(NULL), floater(0.0)
{
	if (arg_type != CFINTEGER) {
		type = CFINVALID;
		return;
	}
	integer = arg_integer;
}

CFTOKEN::CFTOKEN(CFTOKEN_TYPE arg_type, float arg_float)
    : type(CFFLOAT), string(NULL), integer(0)
{
	if (arg_type != CFFLOAT) {
		type = CFINVALID;
		return;
	}
	floater = arg_float;
}

CFTOKEN::~CFTOKEN()
{
	if (string) delete string;
}

char *
CFTOKEN::get_string()
{
	if (type != CFSTRING) {
		printf("CFTOKEN::get_string: get_string of non-string token\n");
	}

	return string;
}

int
CFTOKEN::get_integer()
{
	if (type != CFINTEGER) {
		printf("CFTOKEN::get_integer: get_integer of non-integer token\n");
	}

	return integer;
}

float
CFTOKEN::get_float()
{
	switch (type) {
	    case CFFLOAT:	return floater;
	    case CFINTEGER:	return (float)integer;
	    default:		printf("CFTOKEN::get_float: get_float of non-float token\n"); return -FLT_MAX;
	}	

	// not reached
	return 0.0;	// .... to keep -Wall happy
}


ListOfCFTOKEN::ListOfCFTOKEN(CFTOKEN *arg_cftoken, ListOfCFTOKEN *arg_next) 
	: cftoken(arg_cftoken), next(arg_next)
{
}

ListOfCFTOKEN::~ListOfCFTOKEN()
{
	if (next != NULL)	delete next;
}

