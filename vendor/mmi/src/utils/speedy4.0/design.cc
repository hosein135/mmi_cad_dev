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

/////////////////////////////////////////////////////////////////
// .... design .....


DESIGN::DESIGN()
	: netlist(NULL), globalnetlist(NULL), instancelist(NULL), extconnlist(NULL), 
	dummysourcelist(NULL),
	unidentified_celllist(NULL), unidentified_instancelist(NULL),
	nl_interface(NULL),
	n_nets(0), n_instances(0), n_extconns(0),
	 Q_count(-1),
	removed_instancelist(NULL), removed_netlist(NULL),
	clonelist(NULL), 
	global_downstream(NULL),
	resized_clonelist(NULL),
	saved_path(NULL)
{
	initialization_is_complete = false;

	// ... this seems out of place, but when we do INSTANCE::identify,
	// we expect something to be there
	if (::cell_library == NULL) {
		::cell_library = new CELL_LIBRARY();
	}

	unconnected_inport_net = new NET("unconnected_inport_net");
	new_dummysource(unconnected_inport_net);

	unconnected_clock_inport_net = new NET("unconnected_clock_inport_net");
	new_dummysource(unconnected_clock_inport_net);
}


// this is the top_level procedure for cleaning up prepatory to reloading.
DESIGN::~DESIGN()
{
	ListOfNET *nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		ListOfNET *here = nl;
		nl = nl->next;

		here->next = NULL;
		delete here;		
		delete net;
	}
	netlist = NULL;

	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		ListOfINSTANCE *here = il;
		il = il->next;

		here->next = NULL;
		delete here;
		delete instance;
	}
	instancelist = NULL;

	ListOfEXTCONN *el = extconnlist;
	while (el != NULL) {
		EXTCONN *extconn = el->extconn;
		el = el->next;

		delete extconn;
	}
	if (extconnlist != NULL)		delete extconnlist;

	il = removed_instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		ListOfINSTANCE *here = il;
		il = il->next;

		here->next = NULL;
		delete here;
		delete instance;
	}
	removed_instancelist = NULL;

	nl = removed_netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		ListOfNET *here = nl;
		nl = nl->next;

		here->next = NULL;
		delete here;		
		delete net;
	}
	removed_netlist = NULL;

	ListOfCLONE *cl = clonelist;
	while (cl != NULL) {
		CLONE *clone = cl->clone;
		ListOfCLONE *here = cl;
		cl = cl->next;

		here->next = NULL;
		delete here;		
		delete clone;
	}
	clonelist = NULL;

	il = dummysourcelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		ListOfINSTANCE *here = il;
		il = il->next;

		here->next = NULL;
		delete here;
		delete instance;
	}
	dummysourcelist = NULL;


}

rc_t
DESIGN::new_dummysource(NET *net)
{

	INSTANCE *instance = new INSTANCE(net->get_name());
	instance->identify("dummy_source");
	
	OUTPORT *outport = instance->get_outport("dummy_source");
	outport->net = net;
	net->source = outport;
	net->global_value = GLOBAL_DUMMYSOURCE;

	dummysourcelist = new ListOfINSTANCE(instance, dummysourcelist);
	return RC_NOMINAL;
}

rc_t
DESIGN::compute_net_characteristics()
{
	switch (::net_model) {
	    case EXTRACTED_NETS:
	    case STEINER_RC_NETS:
	    case STEINER_CAP_NETS:
		if (::location_information_is_loaded == false) {
			printf("ERROR: no location information, can't figure nets\n");
			return RC_FAILED;
		}
		break;

	    case IGNORE_NETS:
	    case WIRE_LOAD_CAP_NETS:
	    case EXPLICIT_CAP_NETS:
		break;
	}
		
	ListOfNET *nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		net->compute_net_characteristics();
	}
	
	return RC_NOMINAL;
}

rc_t
NET::compute_net_characteristics()
{
	ListOfINPORT *ipl;

	if (this == fave_net) {
		printf("fave_net compute_net_characteristicsc\n");
	}

	source->load_capacitance = 0.0;
	if (inportlist == NULL)		return RC_NOMINAL;
	if (global_value != NOT_GLOBAL) return RC_NOMINAL;

	// each case is responsible for setting source->load_capacitance
	// and for all inports, inport->net_delay

	switch (::net_model) {
	    case IGNORE_NETS: {
		ipl = inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			inport->net_delay = 0.0;
			source->load_capacitance += inport->inpin->capacitance;
		}
		return RC_NOMINAL;
	    }
	
	    case STEINER_CAP_NETS: 
	    case STEINER_RC_NETS:	{
		if (source->segment != NULL) {
		 	delete source->segment; 
			source->segment = NULL;
		} 
		else locate_all_ports();
		steiner_route();

		SEGMENT *source_segment = source->segment;
		if (source->instance != NULL) {
			source_segment->resistance = source->outpin->resistance;
		}
		source_segment->capacitance = 0.0;
		source_segment->downstream_capacitance = 0.0;

		ListOfSEGMENT *sl = source_segment->segmentlist;
		while (sl != NULL) {
			SEGMENT *segment = sl->segment;
			sl = sl->next;
	
			segment->compute_rc(source->segment);
			source_segment->downstream_capacitance += segment->downstream_capacitance;
		}
		source_segment->capacitance += cap_fudge;
		source_segment->downstream_capacitance += source_segment->capacitance;
		source->load_capacitance = source_segment->downstream_capacitance;

		if (::net_model == STEINER_RC_NETS) {
			return estimate_tc_delay();	// ... in timing.cc
			
		} else {
			// STEINER_CAP_NETS
			ipl = inportlist;
			while (ipl != NULL) {
				INPORT *inport = ipl->inport;
				ipl = ipl->next;
	
				inport->net_delay = 0.0;
				source->load_capacitance += inport->inpin->capacitance;
			}
			return RC_NOMINAL;
		}

	    } 

	    case EXTRACTED_NETS: {
		return estimate_tc_delay();	// ... in timing.cc
	    }

	    case WIRE_LOAD_CAP_NETS: {
		int n_loads = 0;
		ipl = inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			inport->net_delay = 0.0;
			n_loads++;
			source->load_capacitance += inport->inpin->capacitance;
		}
		source->load_capacitance += ::wire_cap_per_load_for_wire_load_model * n_loads;
		return RC_NOMINAL;
	    }

	    case EXPLICIT_CAP_NETS: {
		// just add up output load capacitance = input gate cap,
		// plus total net metal cap (from cap file if we've read one) or just cap_fudge
		ipl = inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			inport->net_delay = 0.0;
			source->load_capacitance += inport->inpin->capacitance;
		}
		if (this->metal_capacitance > ::cap_fudge)	source->load_capacitance += this->metal_capacitance;
		else						source->load_capacitance += cap_fudge;
		return RC_NOMINAL;
	    }
	}

	// not reached
	return RC_NOMINAL;
}	

/////////////////////////////////////////////////////////////////////////
rc_t
DESIGN::complete_initialization()
{
	int counter = 0;
	rc_t rc;

	rc = cell_library->sort_cells_by_area();
	if (rc != RC_NOMINAL)	return rc;

	rc = cell_library->sort_cells_for_downsize_list();
	if (rc != RC_NOMINAL)	return rc;




// XXX where should this go, anyway?
//	buffer_cell = cell_library->get_cell(::buffer_cellname);
//	if (buffer_cell == NULL) {
//		printf("can't find buffer_cell \"%s\"\n", buffer_cellname);
//	}
//	inverter_cell = cell_library->get_cell(::inverter_cellname);
//	if (inverter_cell == NULL) {
//		printf("can't find inverter_cell \"%s\"\n", inverter_cellname);
//	}




	counter = 0;
	ListOfINSTANCE *il = instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;

		counter++;

		if (::insert_names_in_nets_and_instances == true	&&
		    instance->name == NULL					) {
			instance->name = strdup(instance->get_name());
		}

		ListOfOUTPORT *opl = instance->outportlist;
		while (opl != NULL) {
			OUTPORT *outport = opl->outport;
			opl = opl->next;

			if (outport->net == NULL) {
				if (speedy_verbose == true) {
					printf("WARNING %s:%s ... no net\n", instance->get_name(), outport->outpin->name);
				}
 				get_net_for_global("unconnected", outport);
			}
		}
		ListOfINPORT *ipl = instance->inportlist;
		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			if (inport->net == NULL) {
				if (inport->inpin->is_clock_pin == true) {
					inport->net = unconnected_clock_inport_net;
					unconnected_clock_inport_net->inportlist = new ListOfINPORT(inport, unconnected_clock_inport_net->inportlist);;
				} else {
					inport->net = unconnected_inport_net;
					unconnected_inport_net->inportlist = new ListOfINPORT(inport, unconnected_inport_net->inportlist);;
				}
			}	
			else if (inport->inpin->is_clock_pin == true) {
				if (inport->net->global_value != GLOBAL_CLOCK) {
					printf("ERROR: clock pin \"%s:%s\" driven by non-clock net \"%s\"\n",
					    instance->get_name(), inport->inpin->name, inport->net->get_name());
				}
			}
		}
	}
	n_instances = counter;

	ListOfNET *nl = netlist;
	while (nl != NULL) {
		NET *net = nl->net;
		nl = nl->next;

		counter++;
		if (net == fave_net) {
			printf("gotcha64!\n");
		}

		if (::insert_names_in_nets_and_instances == true	&&
		    net->name == NULL					) {
			net->name = strdup(net->get_name());
		}

		// all nets need a source, if only a fake
		if (net->source == NULL) {
			new_dummysource(net);
		}

		// clock nets are designated by user "flag_net_as_clock"
		ListOfINPORT *ipl = net->inportlist;

		while (ipl != NULL) {
			INPORT *inport = ipl->inport;
			ipl = ipl->next;

			if (inport->inpin->is_clock_pin == true) {
				net->source->rising_long_path->absolute_delay = 0.0;
				net->source->falling_long_path->absolute_delay = 0.0;

				// anything connected to the business end 
				// of a clock net should be a clock pin...
				// that's a nice heuristic, but the designers don't always adhere to it

				if (check_inputs_on_clock_nets == true) {
					ipl = net->inportlist;
					while (ipl != NULL) {
						inport = ipl->inport;
						ipl = ipl->next;
						if (inport->inpin->is_clock_pin == false) {
							if (inport->instance != NULL) {
								printf("WARNING: clock net \"%s\" is connected to non-clock pin \"%s:%s\"\n", 
								    net->get_name(), inport->instance->get_name(), inport->inpin->name); 
							} 
							else {
								printf("WARNING: clock net \"%s\" is driving to external pin \"%s\"\n", 
								    net->get_name(), inport->inpin->name);
							}
						}
					}
				}
				break;
			}
		}

		if (::location_information_is_loaded) {
			net->locate_all_ports();
		}
	}
	n_nets = counter;


	counter = 0;
	ListOfEXTCONN *el = extconnlist;
	while (el != NULL) {
		el = el->next;
		counter++;
	}
	n_extconns = counter;

	counter = 0;
	rc = compute_net_characteristics();
	if (rc != RC_NOMINAL)	return rc;
	
	if (global_downstream != NULL) {
		delete global_downstream;
		global_downstream = (DOWNSTREAM *)NULL;
	}
	initialize_global_downstream();

	initialization_is_complete = true;
	return RC_NOMINAL;
}


INSTANCE *
DESIGN::get_instance(char *pathname)
{
#ifdef NL_FEATURE
	if (nl_interface != NULL) {
		return nl_interface->get_instance(pathname);
	}
#endif

	ListOfINSTANCE *instancel = instancelist;
	while (instancel != NULL) {
		INSTANCE *instance = instancel->instance;
		instancel = instancel->next;

		if (strcmp(instance->get_name(), pathname) == 0)	return instance;
	}

	return NULL;
}

INSTANCE *
DESIGN::get_unidentified_instance(char *pathname)
{
	if (nl_interface != NULL) {
		return nl_interface->get_instance(pathname);
	}

	ListOfINSTANCE *instancel = instancelist;
	while (instancel != NULL) {
		INSTANCE *instance = instancel->instance;
		instancel = instancel->next;

		if (strcmp(instance->get_name(), pathname) == 0)	return instance;
	}

	return NULL;
}

EXTCONN *
DESIGN::get_extconn(char *portname)
{
	ListOfEXTCONN *el = extconnlist;
	while (el != NULL) {
		EXTCONN *extconn = el->extconn;
		el = el->next;

		if (strcmp(portname, extconn->name) == 0)		return extconn;
	}

 
	return NULL;
}

NET *
DESIGN::get_net(char *pathname)
{
	if (nl_interface != NULL) {
		return nl_interface->get_net(pathname);
	}

	ListOfNET *netl = netlist;
	while (netl != NULL) {
		NET *net = netl->net;
		netl = netl->next;

		if (strcmp(net->get_name(), pathname) == 0)	return net;
	}

	return NULL;
}

NET *
DESIGN::get_net_for_global(char *global_name, PORT *port)
{
	NET *net = new NET(global_name);
	globalnetlist = new ListOfNET(net, globalnetlist);

	if (port->type == INPORT_TYPE) {
		net->inportlist = new ListOfINPORT((INPORT *)port, NULL);
		new_dummysource(net);
	}

	else if (port->type == OUTPORT_TYPE) {
		net->source = (OUTPORT *)port;
	}

	return net;
}

rc_t
DESIGN::remove_instance(INSTANCE *instance) 
{
// XXX also need to remove from clone::instancelist

	if (instancelist != NULL		&&
	    instancelist->instance == instance	) {
		ListOfINSTANCE *il_for_arg = instancelist;
		instancelist = instancelist->next;
		il_for_arg->next = removed_instancelist;
		removed_instancelist = il_for_arg;
		return RC_NOMINAL;
	}

	ListOfINSTANCE *il = instancelist;
	while (il->next != NULL) {
		if (il->next->instance == instance) {
			ListOfINSTANCE *il_for_arg = il->next;
			il->next = il->next->next;
			il_for_arg->next = removed_instancelist;
			removed_instancelist = il_for_arg;
			return RC_NOMINAL;
		}
		il = il->next;
	}
		
	printf("DESIGN::remove_instance: instance \"%s\" not found\n", instance->get_name());
	return RC_FAILED;
}	

rc_t
DESIGN::remove_net(NET *net) 
{
	if (netlist != NULL		&&
	    netlist->net == net	) {
		ListOfNET *nl_for_arg = netlist;
		netlist = netlist->next;
		nl_for_arg->next = removed_netlist;
		removed_netlist = nl_for_arg;
		return RC_NOMINAL;
	}

	ListOfNET *nl = netlist;
	while (nl->next != NULL) {
		if (nl->next->net == net) {
			ListOfNET *nl_for_arg = nl->next;
			nl->next = nl->next->next;
			nl_for_arg->next = removed_netlist;
			removed_netlist = nl_for_arg;
			return RC_NOMINAL;
		}
		nl = nl->next;
	}
		
	printf("DESIGN::remove_net: net \"%s\" not found\n", net->get_name());
	return RC_FAILED;
}	

/////////////////////////////////

/////////////////////////////////////////////////////////////////
// .... ports .....

PORT::PORT(PORTTYPE arg_type, NET *arg_net) 
	: type(arg_type), net(arg_net), x(-1), y(-1),
	pathname(NULL), net_delay(0.0)
{
}

PORT::PORT(PORT &arg_port) 
	: type(arg_port.type),
	net(arg_port.net),
	x(arg_port.x),
	y(arg_port.y),
	pathname(NULL),
	net_delay(arg_port.net_delay)  
{
	if (arg_port.pathname != NULL)	pathname = strdup(arg_port.pathname);
}

PORT::~PORT() {
	if (pathname != NULL)	free(pathname);
}

int
PORT::distance(PORT *arg_port)
{
	int xoff = abs(x - arg_port->x);
	int yoff = abs(y - arg_port->y);
	return xoff + yoff;
}

int
PORT::distance(int arg_x, int arg_y)
{
	int xoff = abs(x - arg_x);
	int yoff = abs(y - arg_y);
	return xoff + yoff;
}


ListOfPORT::ListOfPORT(PORT *arg_port, ListOfPORT *arg_next)
	: port(arg_port), next(arg_next)
{
}

ListOfPORT::~ListOfPORT() 
{
	if (next)	delete next;
}

INPORT::INPORT(INPORT &arg_inport)
	: PORT(arg_inport),
	instance(arg_inport.instance),
	inpin(arg_inport.inpin),
	tau_Re(0.0)
{
}

INPORT::INPORT(INSTANCE *arg_instance, char *arg_name)
	: PORT(INPORT_TYPE, NULL),
	instance(arg_instance),
	inpin(NULL),
	tau_Re(0.0)
{
	PORT::pathname = strdup(arg_name);
}

INPORT::INPORT(CELL *arg_cell, INPORT *arg_inport)
	: PORT(INPORT_TYPE, arg_inport->net),
	instance(arg_inport->instance),
	tau_Re(0.0)
{
	PORT::pathname = strdup(arg_inport->pathname);

	ListOfINPIN *ipl = arg_cell->inpinlist;
	while (ipl != NULL) {
		INPIN *ip = ipl->inpin;
		ipl = ipl->next;
		if (strcmp(ip->name, arg_inport->inpin->name) == 0) {
			this->inpin = ip;
			return;
		}
	}
	printf("matching inpin not found cell \"%s\" inpin \"%s\"\n", arg_cell->name, arg_inport->inpin->name);
}

INPORT::~INPORT()
{
}


ListOfINPORT::ListOfINPORT(INPORT *arg_inport, ListOfINPORT *arg_next)
	: inport(arg_inport), next(arg_next)
{
}

ListOfINPORT::~ListOfINPORT() 
{
	if (next)	delete next;
}

void
ListOfINPORT::append(INPORT *inport) 
{
	ListOfINPORT *ipl = this;
	while (ipl->next != NULL) {
		ipl = ipl->next;
	}
	ipl->next = new ListOfINPORT(inport, NULL);
}

OUTPORT::OUTPORT(OUTPORT &arg_outport)
	: PORT(arg_outport),
	instance(arg_outport.instance), outpin(arg_outport.outpin),
	load_capacitance(arg_outport.load_capacitance),
	segment(NULL)
{
	PORT::pathname = strdup(arg_outport.pathname);

	rising_long_path = new PATHELEMENT(this, true);
	falling_long_path = new PATHELEMENT(this, false);

	rising_ds_path = new PATHELEMENT(this, true);
	falling_ds_path = new PATHELEMENT(this, false);
}

OUTPORT::OUTPORT(INSTANCE *arg_instance, char *arg_name)
	: PORT(OUTPORT_TYPE, NULL),
	instance(arg_instance), outpin(NULL),
	load_capacitance(0.0),
	segment(NULL)
{
	PORT::pathname = strdup(arg_name);

	rising_long_path = new PATHELEMENT(this, true);
	falling_long_path = new PATHELEMENT(this, false);

	rising_ds_path = new PATHELEMENT(this, true);
	falling_ds_path = new PATHELEMENT(this, false);
}

OUTPORT::OUTPORT(CELL *arg_cell, OUTPORT *arg_outport)
	: PORT(OUTPORT_TYPE, NULL),
	instance(arg_outport->instance),
	load_capacitance(arg_outport->load_capacitance),
	rising_long_path(NULL), falling_long_path(NULL),
	rising_ds_path(NULL), falling_ds_path(NULL)
{
	PORT::pathname = strdup(arg_outport->pathname);

	ListOfOUTPIN *opl = arg_cell->outpinlist;
	while (opl != NULL) {
		OUTPIN *ip = opl->outpin;
		opl = opl->next;
		if (strcmp(ip->name, arg_outport->outpin->name) == 0) {
			this->outpin = ip;
			return;
		}
	}
	printf("matching outpin not found cell \"%s\" outpin \"%s\"\n", 
	    arg_cell->name, arg_outport->outpin->name);
}

OUTPORT::~OUTPORT()
{
}

ListOfOUTPORT::ListOfOUTPORT(OUTPORT *arg_outport, ListOfOUTPORT *arg_next)
	: outport(arg_outport), next(arg_next)
{
}

ListOfOUTPORT::~ListOfOUTPORT() 
{
	if (next)	delete next;
}

NODE::NODE(NET *arg_net)
	: PORT(NODE_TYPE, arg_net), index(0)
{
}

NODE::NODE(NET *arg_net, int arg_x, int arg_y, int arg_index)
	: PORT(NODE_TYPE, arg_net), index(arg_index)
{
	PORT::x = arg_x;
	PORT::y = arg_y;
}

NODE::~NODE()
{
}

ListOfNODE::ListOfNODE(NODE *arg_node, ListOfNODE *arg_next)
	: node(arg_node), next(arg_next)
{
}

ListOfNODE::~ListOfNODE() 
{
	if (next)	delete next;
}


/////////////////////////////////////////////////////////////////
// .... instances .....


INSTANCE::INSTANCE(char *arg_name) 
	: type(INSTANCE_INSTANCETYPE),
	nlicell(NULL),
	nlpcell(NULL),
	nl_clone(NULL),
	cell(NULL), 
	inportlist(NULL), outportlist(NULL),
	clone(NULL), 
	did_this_one(0),
	pathlist(NULL),
	saved_cell(NULL)
{
	name = strdup(arg_name);
}

INSTANCE::INSTANCE(NL_ICELL arg_nlicell) 
	: name(NULL), 
	type(INSTANCE_INSTANCETYPE),
	nlicell(arg_nlicell),
	nlpcell(NULL),
	nl_clone(NULL),
	cell(NULL), 
	inportlist(NULL), outportlist(NULL),
	clone(NULL),
	did_this_one(0), 
	pathlist(NULL), 
	saved_cell(NULL)
{
}
	

INSTANCE::INSTANCE() 
	: name(NULL), 
	type(INSTANCE_INSTANCETYPE),
	nlicell(NULL),
	nlpcell(NULL),
	nl_clone(NULL),
	cell(NULL), 
	inportlist(NULL), outportlist(NULL),
	clone(NULL),
	did_this_one(0), 
	pathlist(NULL),
	saved_cell(NULL)
{
}

INSTANCE::~INSTANCE() 
{
	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		delete inport;
	}
	delete inportlist;

	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		delete outport;
	}
	delete outportlist;

	if (pathlist != NULL)	clear_pathlist();
	if (name != NULL)	free(name);	// constructed with strdup
}

rc_t
INSTANCE::identify(char *cellname)
{
	CELL *cell;
	ListOfCELL *cl = cell_library->celllist;
	while (cl != NULL) {
		cell = cl->cell;

		if (strcmp(cell->name, cellname) == 0) 	break;

		cl = cl->next;
	}
	if (cl == NULL) {

		// not found; we want to print out *one* warning message;
		// also this might be interesting data later.

		cl = ::design->unidentified_celllist;
		while (cl != NULL) {
			cell = cl->cell;
			if (strcmp(cell->name, cellname) == 0) break;
			cl = cl->next;
		}
		if (cl == NULL) {
			printf("unidentified celltype \"%s\"...instances will be silently ignored\n", cellname);
			cell = new CELL(cellname, CELLTYPE_UNKNOWN_CELL);
			::design->unidentified_celllist = new ListOfCELL(cell, ::design->unidentified_celllist);
		}
		this->cell = cell;
		return RC_FAILED;
	}

	return identify(cell);
}


rc_t
INSTANCE::identify(CELL *arg_cell)
{
	this->cell = arg_cell;
	this->saved_cell = cell;

	// create inports and outports
	ListOfOUTPIN *opl = cell->outpinlist;
	while (opl != NULL) {
		OUTPIN *outpin = opl->outpin;
		opl = opl->next;

		if (outpin->is_array == false) {
			OUTPORT *outport = new OUTPORT(this, outpin->name);
			outport->outpin = outpin;
			outportlist = new ListOfOUTPORT(outport, outportlist);
		}
		else {
			for (int i = outpin->low_index; i <= outpin->high_index; i++) {
				sprintf(tstr, "%s[%d]", outpin->name, i);
				OUTPORT *outport = new OUTPORT(this, tstr);
				outport->outpin = outpin;
				outportlist = new ListOfOUTPORT(outport, outportlist);
			}
		}
	}

	ListOfINPIN *ipl = cell->inpinlist;
	while (ipl != NULL) {
		INPIN *inpin = ipl->inpin;
		ipl = ipl->next;

		if (inpin->is_array == false) {
			INPORT *inport = new INPORT(this, inpin->name);
			inport->inpin = inpin;
			inportlist = new ListOfINPORT(inport, inportlist);
		}
		else {
			for (int i = inpin->low_index; i <= inpin->high_index; i++) {
				sprintf(tstr, "%s[%d]", inpin->name, i);
				INPORT *inport = new INPORT(this, tstr);
				inport->inpin = inpin;
				inportlist = new ListOfINPORT(inport, inportlist);
			}
		}

	}

	return RC_NOMINAL;
}

PORT *
INSTANCE::get_port(char *portname)
{
	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		if (strcmp(portname, inport->inpin->name) == 0) {
			return inport;
		}
	}
	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		if (strcmp(portname, outport->outpin->name) == 0) {
			return outport;
		}
	}
	return NULL;
}

INPORT *
INSTANCE::get_inport(char *arg_portname)
{
	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		if (strcmp(arg_portname, inport->inpin->name) == 0) {
			return inport;
		}
	}
	return NULL;
}
	

OUTPORT *
INSTANCE::get_outport(char *arg_portname)
{
	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		if (strcmp(arg_portname, outport->outpin->name) == 0) {
			return outport;
		}
	}
	return NULL;
}

INPORT *
INSTANCE::get_inport(char *arg_portname, int arg_index)
{
	// ... see also for get_outport, just below

	if (cell == NULL) return NULL;

	// ... find the cell->inpin with this name, then relate
	// that inpin to an instance->inport ....
	INPIN *inpin;
	char *portname;
	ListOfINPIN *inpinlist = cell->inpinlist;
	while (inpinlist != NULL) {
		inpin = inpinlist->inpin;
		if (strcmp(arg_portname, inpin->name) == 0)	break;
		inpinlist = inpinlist->next;
	}
	if (inpinlist == NULL) {
		// ... maybe the inpin is a busted-out array ....
		sprintf(tstr, "%s[%d]", arg_portname, arg_index);
		inpinlist = cell->inpinlist;
		while (inpinlist != NULL) {
			inpin = inpinlist->inpin;
			if (strcmp(tstr, inpin->name) == 0)	break;
			inpinlist = inpinlist->next;
		}
		if (inpinlist == NULL)	return NULL;
		portname = tstr;
	}	
	else {
		if (inpin->is_array == true) {
			int port_index = inpin->low_index + arg_index;
			sprintf(tstr, "%s[%d]", arg_portname, port_index);
			portname = tstr;
		} 
		else 	portname = arg_portname;
	}

	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		if (strcmp(portname, inport->inpin->name) == 0) {
			return inport;
		}
	}
	return NULL;
}
	

OUTPORT *
INSTANCE::get_outport(char *arg_portname, int arg_index)
{
	// ... see comments for get_inport, just above

	if (cell == NULL) return NULL;

	OUTPIN *outpin;
	char *portname;

	ListOfOUTPIN *outpinlist = cell->outpinlist;
	while (outpinlist != NULL) {
		outpin = outpinlist->outpin;
		if (strcmp(arg_portname, outpin->name) == 0)	break;
		outpinlist = outpinlist->next;
	}
	if (outpinlist == NULL) {
		sprintf(tstr, "%s[%d]", arg_portname, arg_index);
		outpinlist = cell->outpinlist;
		while (outpinlist != NULL) {
			outpin = outpinlist->outpin;
			if (strcmp(tstr, outpin->name) == 0)	break;
			outpinlist = outpinlist->next;
		}
		if (outpinlist == NULL)	return NULL;
		portname = tstr;
	}	
	else {
		if (outpin->is_array == true) {
			int port_index = outpin->low_index + arg_index;
			sprintf(tstr, "%s[%d]", arg_portname, port_index);
			portname = tstr;
		} 
		else 	portname = arg_portname;
	}

	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		OUTPORT *outport = opl->outport;
		opl = opl->next;

		if (strcmp(portname, outport->outpin->name) == 0) {
			return outport;
		}
	}
	return NULL;
}


OUTPORT *
INSTANCE::get_outport(OUTPIN *outpin)
{
	ListOfOUTPORT *opl = outportlist;
	while (opl != NULL) {
		if (opl->outport->outpin == outpin)	return opl->outport;
		opl = opl->next;
	}
	return NULL;
}

INPORT *
INSTANCE::get_inport(INPIN *inpin)
{
	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		if (ipl->inport->inpin == inpin)	return ipl->inport;
		ipl = ipl->next;
	}
	return NULL;
}

	
char tinstancenamestr[0x1000];

char *
INSTANCE::get_name()
{
	if (name != NULL) {
		return name;
	}

	if (nlicell != NULL) {
		nl_interface->get_instance_name(this, tinstancenamestr, 0x1000);
		return tinstancenamestr;
	}

	return NULL;
}

void
INSTANCE::get_name(char *buf, int bufsize)
{
	if (name != NULL) {
		strncpy(buf, name, bufsize);
		return;
	}

	if (nlicell != NULL) {
		nl_interface->get_instance_name(this, buf, bufsize);
		return;
	}

	return;
}


ListOfINSTANCE::ListOfINSTANCE(INSTANCE *arg_instance, ListOfINSTANCE *arg_next)
    : instance(arg_instance), next(arg_next)
{
	if (arg_instance == NULL) {
		printf("yuck!\n");
	}
}

ListOfINSTANCE::~ListOfINSTANCE() 
{
	if (next)	delete next;
}

void
ListOfINSTANCE::unlink_and_delete()
{
	next = NULL;
	delete this;
}

ListOfINSTANCELIST::ListOfINSTANCELIST(ListOfINSTANCE *arg_instancelist, ListOfINSTANCELIST *arg_next)
    : instancelist(arg_instancelist), next(arg_next)
{
}

ListOfINSTANCELIST::~ListOfINSTANCELIST() 
{
	if (next)	delete next;
}

//////////////////////////////////////////////////

EXTCONN::EXTCONN(char *arg_name, INSTANCETYPE arg_type)
	: INSTANCE(arg_name), 
	delay(0.0), slope(0.0), driver((CELL *)NULL)
{
	type = arg_type;
}

EXTCONN::~EXTCONN()
{
}

NET *
EXTCONN::get_net()
{
	if (inportlist != NULL)		return inportlist->inport->net;
	if (outportlist != NULL)	return outportlist->outport->net;
	return NULL;
}

ListOfEXTCONN::ListOfEXTCONN(EXTCONN *arg_extconn, ListOfEXTCONN *arg_next)
    : extconn(arg_extconn), next(arg_next)
{
}

ListOfEXTCONN::~ListOfEXTCONN() 
{
	if (next)	delete next;
}



/////////////////////////////////////////////////////////////////
// .... nets .....

NET::NET(char *arg_name)
	:
	nlinet(NULL),
	source(NULL), inportlist(NULL), global_value(NOT_GLOBAL),
	metal_capacitance(0.0), tau_P(0.0)
{
	name = strdup(arg_name);
}


NET::NET(NL_INET arg_nlinet)
	: name(NULL),
	nlinet(arg_nlinet),
	source(NULL), inportlist(NULL), global_value(NOT_GLOBAL),
	tau_P(0.0)
{
}

NET::NET()
	: name(NULL),
	nlinet(NULL),
	source(NULL), inportlist(NULL), global_value(NOT_GLOBAL),
	tau_P(0.0)
{
}

NET::~NET()
{
	// we delete the ports themselves along with their instance
	if (inportlist != NULL)		delete inportlist;
	if (name != NULL)		free(name);	// ... constructed with strdup
}

char *
NET::get_name()
{
	static char tnetnamestr[0x1000];

	if (name != NULL) {	
		return name;
	}

	if (nlinet != NULL) {
		nl_interface->get_net_name(this, tnetnamestr, 0x1000);
		return tnetnamestr;
	}

	return NULL;
}

void
NET::get_name(char *buf, int bufsize)
{
	if (name != NULL) {
		strncpy(buf, name, bufsize);
		return;
	}

	if (nlinet != NULL) {
		nl_interface->get_net_name(this, buf, bufsize);
		return;
	}

	*buf = '\0';
}

rc_t
NET::remove_inport(INPORT *arg_inport)
{
	if (inportlist == NULL) {
		printf("NET::remove_inport: inportlist is empty!\n");
		return RC_FAILED;
	}
	if (inportlist->inport == arg_inport) {
		ListOfINPORT *t = inportlist;
		inportlist = inportlist->next;
		t->next = NULL;
		delete t;
		return RC_NOMINAL;
	}
	ListOfINPORT *ipl = inportlist;
	while (ipl->next != NULL) {
		if (ipl->next->inport == arg_inport) {
			ListOfINPORT *t = ipl->next;
			ipl->next = ipl->next->next;
			t->next = NULL;
			delete t;
			return RC_NOMINAL;
		}
		ipl = ipl->next;
	}
	printf("NET::remove_inport: arg_inport not found\n");
	return RC_FAILED;
}

BOOLEAN
NET::locate_all_ports() 
{
	if (source->x == -1	&& 
	    inportlist != NULL	) {
		if (source->instance->type == INSTANCE_INSTANCETYPE	&&
		    global_value == NOT_GLOBAL				) {
			printf("net %s source is not located\n", get_name());
		}
		INPORT *random_inport = inportlist->inport;
		source->x = random_inport->x;
		source->y = random_inport->y;
	}

	ListOfINPORT *ipl = inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;
	
		if (inport->x == -1) {
			if (inport->instance != NULL		&&
			    source->instance != NULL	) {
				// the perpetual where-is-the-extconn problem....
				if (inport->instance->type == INSTANCE_INSTANCETYPE) {
					printf("%s:%s on net %s is not located\n", inport->instance->get_name(), inport->inpin->name, get_name());
				}
				// randomly colocate it with the source
				inport->x = source->x;
				inport->y = source->y;
			}
			else {
				if (source != NULL) {
					inport->x = source->x;
					inport->y = source->y;
				}
				else if (inportlist->next != NULL) {
					 printf("%s on net %s is not located\n", inport->inpin->name, get_name());
				}
			}
		}
	}

	return true;
}


ListOfNET::ListOfNET(NET *arg_net, ListOfNET *arg_next)
    : net(arg_net), next(arg_next)
{
}

ListOfNET::~ListOfNET() 
{
	if (next)	delete next;
}

ListOfNET *
ListOfNET::append(NET *arg_net) {

	ListOfNET *new_nl = new ListOfNET(arg_net, NULL);

	if (this == NULL) {
		return new_nl;
	}

	ListOfNET *nl = this;
	while(nl->next != NULL) {
		nl = nl->next;
	}
	nl->next = new_nl;
	return this;	
}


//////////////////////////////


SEGMENT::SEGMENT(PORT *arg_right_end)
	: right_end(arg_right_end), segmentlist(NULL), 
	resistance(0.0), capacitance(0.0), downstream_capacitance(0.0)
//	routelist(NULL)

{
}

SEGMENT::~SEGMENT()
{
	if (segmentlist != NULL) {
		ListOfSEGMENT *sl = segmentlist;
		while (sl != NULL) {
			delete sl->segment;
			sl = sl->next;
		}
		delete segmentlist;
	}

// 	if (routelist != NULL)	delete routelist;
}

void
SEGMENT::compute_rc(SEGMENT *upstream_segment)
{
	PORT *left_end = upstream_segment->right_end;

	// if ends haven't been placed, set segment R and C to 0
	if (left_end->x < 0  ||  
	    right_end->x < 0 ) {
		resistance = 0.0;
		capacitance = 0.0;
	}
	else { 

		float xsize = (float)abs(left_end->x - right_end->x);
		float ysize = (float)abs(left_end->y - right_end->y);
	
		resistance = ::rconst  * (xsize + ysize);
		capacitance = (::cconst * (xsize + ysize)) / 2.0;
	}	
	upstream_segment->capacitance += capacitance;

	// recurse down following segments
	downstream_capacitance = 0.0;
	ListOfSEGMENT *sl = segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;
			
		segment->compute_rc(this);
		downstream_capacitance += segment->downstream_capacitance;
	}

	if (right_end->type == INPORT_TYPE) {
		INPORT *inport = (INPORT *)right_end;
		capacitance += inport->inpin->capacitance;
	}

	downstream_capacitance += capacitance;
}

PORT *
SEGMENT::get_left_end()
{
	OUTPORT *netsource = right_end->net->source;
	ListOfSEGMENT *sl = netsource->segment->segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;

		if (segment == this)	return netsource;

		PORT *port = segment->get_left_end_helper(this);
		if (port != NULL)	return port;
	}
	return NULL;
}

PORT *
SEGMENT::get_left_end_helper(SEGMENT *target_segment)
{
	ListOfSEGMENT *sl = this->segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;

		if (segment == target_segment)	return this->right_end;

		PORT *port = segment->get_left_end_helper(target_segment);
		if (port != NULL)	return port;
	}
	return NULL;
}

void
SEGMENT::sum_net_r(float *arg_resistance)
{
	*arg_resistance  += resistance;

	ListOfSEGMENT *sl = segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;

		segment->sum_net_r(arg_resistance);
	}
}

int
SEGMENT::count_downstream_segments()
{
	int return_count = 1;	//... namely, this
	ListOfSEGMENT *sl = segmentlist;
	while (sl != NULL) {
		SEGMENT *next_segment = sl->segment;
		sl = sl->next;

		return_count += next_segment->count_downstream_segments();
	}
	return return_count;	
}
	
ListOfSEGMENT::ListOfSEGMENT(SEGMENT *arg_segment, ListOfSEGMENT *arg_next)
    : segment(arg_segment), next(arg_next)
{
}

ListOfSEGMENT::~ListOfSEGMENT()
{
	if (next != NULL)	delete next;
}

///////////////////////////////////////////////////////////////

GLOBAL::GLOBAL(char *arg_name)
	: net(NULL), inportlist(NULL)
{
	name = strdup(arg_name);
}	

GLOBAL::~GLOBAL()
{
	delete name;
	if (inportlist != NULL) {
		delete inportlist;
	}
}


ListOfGLOBAL::ListOfGLOBAL(GLOBAL *arg_global, ListOfGLOBAL *arg_next)
    : global(arg_global), next(arg_next)
{
}

ListOfGLOBAL::~ListOfGLOBAL() 
{
	if (next)	delete next;
}


////////////////////////////////////////////////////////////////

CLONE::CLONE(INSTANCE *instance, BOOLEAN is_for_sue) 
	: parent_cellname(NULL), name(NULL), 
	nldesign(NULL), nlcell(NULL)

{
	instancelist = new ListOfINSTANCE(instance, NULL);
	nominal_cell = instance->cell;	
	n_instances = 1;

	if (nominal_cell == NULL	||
	    nominal_cell->size == ' '	) {
		is_adjustable_for_size = false;
	}
	else				is_adjustable_for_size = true;

	instance->clone = this;
}

CLONE::~CLONE()
{
	if (parent_cellname != NULL)	delete parent_cellname;
	if (name != NULL)		delete name;
	if (instancelist != NULL)	delete instancelist;
}

rc_t
CLONE::add_instance(INSTANCE *instance, BOOLEAN is_for_sue)
{
	instancelist = new ListOfINSTANCE(instance, instancelist);
	n_instances++;

	instance->clone = this;
	return RC_NOMINAL;
}

ListOfCLONE::ListOfCLONE(CLONE *arg_clone, ListOfCLONE *arg_next) 
	: clone(arg_clone), next(arg_next)
{
}

ListOfCLONE::~ListOfCLONE()
{
	if (next != NULL)	delete next;
}

void
ListOfCLONE::unlink_and_delete()
{
	next = NULL;
	delete this;
}

////////////////////////////////////////////////////////////////

rc_t
CELL_AREA_INFO::figure()
{

	total_area = 0.0;
	resizeable_area = 0.0;

	if (design == NULL) {
		return RC_INVALID;
	}

	ListOfINSTANCE *il = design->instancelist;
	while (il != NULL) {
		INSTANCE *instance = il->instance;
		il = il->next;
	
		if (instance->cell != NULL) {
			total_area += instance->cell->area;
		
			if (instance->cell->functiongroup != NULL			&&
			    instance->cell->functiongroup->celllist != NULL		&&
			    instance->cell->functiongroup->celllist->next != NULL 	&&
			    instance->clone->is_adjustable_for_size			) {
				resizeable_area += instance->cell->area;
			}
		}
	}

	return RC_NOMINAL;
}




 

