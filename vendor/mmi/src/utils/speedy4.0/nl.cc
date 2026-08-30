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

NL_INTERFACE::NL_INTERFACE(nl_design arg_design, nl_idesign arg_idesign)
	: // nlicell_instance_attr(NULL), 
	interface_nldesign(arg_design), interface_nlidesign(arg_idesign), interface_pnldesign(NULL),
	speedy_design(NULL)
{
	nl_design_attr_get_by_name ("pnl design", interface_nldesign, &interface_pnldesign);
}

NL_INTERFACE::~NL_INTERFACE()
{
}


rc_t
NL_INTERFACE::initialize()
{
	if (::design != NULL) {
		delete ::design;
		::design = NULL;
	}
	::design = new DESIGN();
	speedy_design = ::design;
	speedy_design->nl_interface = this;

	// create cells
	nl_walk_cells(interface_nldesign, interface_nlidesign, 1, 1, 1, 1, 0, &instance_creator_callback, (void *)NULL);

	// create nets
	nl_walk_nets(interface_nldesign, interface_nlidesign, 1, 1, 1, 1, 0, &net_creator_callback, (void *)NULL);

	// do constant nets, plz 
	nl_walk_nets(interface_nldesign, interface_nlidesign, 1, 1, 0, 1, 1, &constant_net_creator_callback, (void *)NULL);

	return RC_NOMINAL;	
}

rc_t
NL_INTERFACE::initialize_instances()
{
	// create cells
	nl_walk_cells(interface_nldesign, interface_nlidesign, 1, 1, 1, 1, 0, &instance_creator_callback, (void *)NULL);

	return RC_NOMINAL;	
}

nl_walk_status
NL_INTERFACE::instance_creator_callback(nl_object obj, void *)
{
	nl_icell nlicell = (nl_icell)obj;
	nl_idesign parent_idesign = nl_icell_idesign(nlicell);
	INSTANCE *instance = design->new_instance(nlicell);

	// set instance pointer on icell, so we can find it while attaching nets
	// nl_icell_attr_set(nl_interface->icell_instance_attr, icell, (void *)instance);		
	// .... do this even for UNKNOWN_CELLs....
	nl_icell_attr nlicell_instance_attr = 
	    (nl_icell_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlicell_instance_attr");
	if (nlicell_instance_attr == NULL) {
		nlicell_instance_attr = nl_icell_attr_create(
		    "nlicell_instance_attr", 
		    parent_idesign, 
		    nl_density_dense, 
		    sizeof(void *), 
		    NULL,	// (void *)(&null_ptr), 
		    NULL);

	}
	// ASSERT (nl_icell_attr_attr_of(nlicell_instance_attr) == nl_kind_icell);
	nl_icell_attr_set(nlicell_instance_attr, nlicell, &instance);

	if (instance->cell->type == CELLTYPE_UNKNOWN_CELL) return nl_walk_status_continue;

	// pcell, "physical cell", which we need for extracting pin locations
	// XXX .... Sue isn't doing lef files, so basic cell references come out as 
	// nl "design" rather than "libcell", which means that relative port location
	// information is not available, and we get an ASSERT when we ask for it.
	// So if that's the case, leave nlpcell NULL and don't ask.

	nl_reference ref = nl_icell_reference(nlicell);
	nl_object down_design = nl_reference_down_design(ref);
	instance->nlpcell = NULL;
	if (down_design == NULL) {
		// printf("NL can't identify down-design for ref \"%s\" for nlicell \"%s\"\n", refname, nl_icell_name(nlicell));
	} else {
		nl_kind down_design_kind = nl_object_kind(down_design);
		if (down_design_kind == nl_kind_libcell) {
			// cool!
			pnl_idesign pidesign;
			nl_idesign_attr_get_by_name ("pnl idesign", parent_idesign, &pidesign);
			if (pidesign != NULL) {	// ... if NULL, there is no physical info, so never mind... 
				instance->nlpcell = pnl_idesign_get_icell (pidesign, nlicell);
			}
		}
	}
	
	// clones.... different for Sue or NL
	if (use_sue_clones == false) {
		nl_cell nlcell = nl_icell_cell(nlicell);
		CLONE *clone;
		ListOfCLONE *cl = design->clonelist;
		while (cl != NULL) {
			clone = cl->clone;

			if (clone->nlcell == nlcell) {
				clone->add_instance(instance, false);
				break;
			}
	
			cl = cl->next;
		}
		if (cl == NULL) {
			design->new_clone(instance, nlcell, nl_idesign_design(parent_idesign), NULL);
		}
	}

	else {
		nl_design nldesign = nl_idesign_design(nl_icell_idesign(nlicell));
		strncpy(tstr, nl_cell_name(nl_icell_cell(nlicell)), TSTRSIZE );
	
		// ... we need for all members of indexed array to be in the same clone
		// in which case name will be like: MMI_INVA_2$23$
		// and we need to prune off the index part.
		// If Lee or whosomever changes the significator of indexhood,
		// for example to "[...]" (how radical) we need to fix this.
		
		char *p = tstr;
		*(p + TSTRSIZE) = '\0';
		while (1) {
			switch (*p) {
			    case '\0':	
				break;
		
			    case INDEX_OPENING_CHARACTER:
				*p = '\0';
				break;
	
			    default:
				p++;
				continue;
			}
			break;
		}

		CLONE *clone = NULL;
		ListOfCLONE *cl = design->clonelist;
		while (cl != NULL) {
			clone = cl->clone;
	
			if (clone->nldesign == nldesign		&&
			    strcmp(clone->name, tstr) == 0	) {
				clone->add_instance(instance, true);
				break;
			}
	
			cl = cl->next;
		}
		if (cl == NULL) {
			design->new_clone(instance, nl_icell_cell(nlicell), nldesign, tstr); 
		}
	}

	return nl_walk_status_continue;
}

nl_walk_status
NL_INTERFACE::net_counter_callback(nl_object obj, void *net_count)
{
	(*((int *)net_count))++;
	return nl_walk_status_continue;
}

nl_walk_status
NL_INTERFACE::net_creator_callback(nl_object obj, void *arg)
{
	nl_inet nlinet = (nl_inet)obj;
	NET *net = design->new_net(nlinet);

	// set net pointer on inet, for get_net, which we need to do *lots* during write_dspffile
	// nl_icell_attr_set(nl_interface->nlicell_instance_attr, icell, (void *)instance);		
	// XXX ... temporary (hopefully) hackaround while Jay does better
	nl_idesign parent_idesign = nl_inet_idesign(nlinet);
	nl_inet_attr nlinet_net_attr = 
	    (nl_inet_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlinet_net_attr");
	if (nlinet_net_attr == NULL) {
		nlinet_net_attr = nl_inet_attr_create(
		    "nlinet_net_attr", 
		    parent_idesign, 
		    nl_density_dense, 
		    sizeof(void *), 
		    NULL,	// (void *)(&null_ptr), 
		    NULL);

	}
	// ASSERT (nl_net_attr_attr_of(nlinet_net_attr) == nl_kind_inet);
	nl_inet_attr_set(nlinet_net_attr, nlinet, &net);

 	// Args to nl_walk_connected_nets_and_pins are:
 	//	nl_net net  (net to start from)
 	//	nl_idesign idesgin (idesign to start from)
 	//	int thru_assigns (traverse across assignment buffers)
  	//	int thru_hier (traverse through hierarchy)
 	//	int fanins (traverse the drivers of the net)
 	//	int fanouts (traverse the loads of the net)
 	//	int fanios (traverse the IOs of the net)
 	//	nl_walk_fun net_fun (function to call on each net traversed)
 	//	nl_walk_fun pin_fun (function to call on each pin traversed)
 	//	void *ptr (random pointer passed to the functions)
 	// 	
 	nl_walk_connected_nets_and_pins (
	    nl_inet_net(nlinet), 
	    nl_inet_idesign(nlinet), 
	    1, 1, 1, 1, 1, 
 	    net_alias_callback,
 	    net_pin_callback,
 	    (void *)net);

	return nl_walk_status_continue;
}

nl_walk_status
NL_INTERFACE::constant_net_creator_callback(nl_object obj, void *arg)
{
	nl_inet nlinet = (nl_inet)obj;
	NET *net = design->new_net(nlinet);
	char *netname = nl_net_name( nl_inet_net( nlinet ));
	
	if (strcmp(netname, "1'b0") == 0) {
		net->global_value = GLOBAL_ZERO;
	} 
	else
	if (strcmp(netname, "1'b1") == 0) {
		net->global_value = GLOBAL_ONE;
	} 
	else {
		printf("WARNING: constant net with unknown name \"%s\"\n", netname);
		net->global_value = GLOBAL_UNKNOWN;
	}
	
	// set net pointer on inet, for get_net, which we need to do *lots* during write_dspffile
	// nl_icell_attr_set(nl_interface->nlicell_instance_attr, icell, (void *)instance);		
	// XXX ... temporary (hopefully) hackaround while Jay does better
	nl_idesign parent_idesign = nl_inet_idesign(nlinet);
	nl_inet_attr nlinet_net_attr = 
	    (nl_inet_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlinet_net_attr");
	if (nlinet_net_attr == NULL) {
		nlinet_net_attr = nl_inet_attr_create(
		    "nlinet_net_attr", 
		    parent_idesign, 
		    nl_density_dense, 
		    sizeof(void *), 
		    NULL,	// (void *)(&null_ptr), 
		    NULL);

	}
	// ASSERT (nl_net_attr_attr_of(nlinet_net_attr) == nl_kind_inet);
	nl_inet_attr_set(nlinet_net_attr, nlinet, &net);

 	// Args to nl_walk_connected_nets_and_pins are:
 	//	nl_net net  (net to start from)
 	//	nl_idesign idesgin (idesign to start from)
 	//	int thru_assigns (traverse across assignment buffers)
 	//	int thru_hier (traverse through hierarchy)
 	//	int fanins (traverse the drivers of the net)
 	//	int fanouts (traverse the loads of the net)
 	//	int fanios (traverse the IOs of the net)
 	//	nl_walk_fun net_fun (function to call on each net traversed)
 	//	nl_walk_fun pin_fun (function to call on each pin traversed)
 	//	void *ptr (random pointer passed to the functions)
 	// 	
 	nl_walk_connected_nets_and_pins (
	    nl_inet_net(nlinet), 
	    nl_inet_idesign(nlinet), 
	    1, 1, 1, 1, 1, 
 	    net_alias_callback,
 	    net_pin_callback,
 	    (void *)net);

	return nl_walk_status_continue;
}

nl_walk_status
NL_INTERFACE::net_alias_callback(nl_object, void *)
{
	return nl_walk_status_continue;
}	

nl_walk_status
NL_INTERFACE::net_pin_callback(nl_object arg_obj, void *arg)
{
	nl_ipin ipin = (nl_ipin)arg_obj;
	NET *net = (NET *)arg;

	nl_idesign_object whatsit = nl_ipin_owner(ipin);
	nl_kind whatsit_kind = nl_idesign_object_kind(whatsit);
	switch (whatsit_kind) {
	    case nl_kind_icell: {	// .... nl "pin" is same as speedy "port"
		nl_icell nlicell = (nl_icell)whatsit;
		nl_interface->add_ipin_to_net(net, nlicell, ipin);
	    } break;

	    case nl_kind_iport: {	// .... nl "port" is same as speedy "extconn"
		nl_iport iport = (nl_iport)whatsit;
		nl_interface->add_iport_to_net(net, iport);
	    } break;

	    default:
		printf("NL_INTERFACE::net_pin_callback object is not nlicell or port??? %d actual\n", whatsit_kind);
		return nl_walk_status_stop;
	}

	return nl_walk_status_continue;
}	

void
NL_INTERFACE::add_ipin_to_net(NET *net, nl_icell nlicell, nl_ipin ipin)
{
	INSTANCE *instance = NULL;

	nl_idesign parent_idesign = nl_ipin_idesign(ipin);
	nl_icell_attr nlicell_instance_attr = 
	    (nl_icell_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlicell_instance_attr");
	if (nlicell_instance_attr == NULL)	return;	// probably unrecognized cell type; ignore the pin

	nl_icell_attr_get(nlicell_instance_attr, nlicell, (void *)(&instance));

 	if (instance->cell == NULL) {
		printf("net %s: instance \"%s\" has no cell identified/n",
		    net->get_name(), instance->get_name());
		return;
	}
	PORT *port = instance->get_port(nl_ipin_name(ipin));
	if (port == NULL) {
		printf("net %s: instance \"%s\" (->cell \"%s\") has no port named \"%s\"\n",
		    net->get_name(), instance->get_name(), instance->cell->name, nl_ipin_name(ipin));
		return;
	}
	port->net = net;	

	if (port->type == OUTPORT_TYPE) {
		if (net->source == NULL)	net->source = (OUTPORT *)port;
		else {
			printf("net %s: add outport \"%s\":\"%s\": already has a source \"%s\":\"%s\"\n",
			    net->get_name(), instance->get_name(), nl_ipin_name(ipin),
			    net->source->instance->get_name(), net->source->outpin->name);
		}
	} else {
		net->inportlist = new ListOfINPORT((INPORT *)port, net->inportlist);
	}

	return;
}

void
NL_INTERFACE::add_iport_to_net(NET *net, nl_iport iport)
{
	EXTCONN *extconn = design->new_extconn(iport);
	if (extconn->cell == NULL)	{
		// fixitup during DESIGN::complete_initialization
		return;
	}

	// extconn is in or out?
	OUTPORT *source = extconn->get_outport("in");	// ... it's a input, so port is OUTPORT_TYPE
	if (source != NULL) {
		source->net = net;	
		if (net->source == NULL)	net->source = source;
		else {
			printf("net %s: add external input \"%s\":\"%s\": already has a source \"%s\":\"%s\"\n",
			    net->get_name(), extconn->get_name(), nl_iport_name(iport),
			    net->source->instance->get_name(), net->source->outpin->name);
		}
		return;
	} 

	INPORT *dest = extconn->get_inport("out");	// ... it's an output, so port is INPORT_TYPE
	if (dest != NULL) {
		dest->net = net;	
		net->inportlist = new ListOfINPORT(dest, net->inportlist);
		return;
	} 

	printf("NL_INTERFACE::add_iport_to_net %s %s.... confused... shouldn't ever get here\n",
	    net->get_name(), nl_iport_name(iport));
	return;
}


//////////////////////////////////////////////////////////////

INSTANCE *
DESIGN::new_instance(NL_ICELL arg_nlicell)
{
	INSTANCE *instance = new INSTANCE(arg_nlicell);
	instance->nlicell = arg_nlicell;

	// reference; that is, CELL
	nl_reference ref = nl_icell_reference(arg_nlicell);
	char *refname = nl_reference_name(ref);

	rc_t rc = instance->identify(refname);
	if (rc != RC_NOMINAL) {
		// unknown celltype
		unidentified_instancelist = new ListOfINSTANCE(instance, unidentified_instancelist);
	}		
	else {
		instancelist = new ListOfINSTANCE(instance, instancelist);
	}

	return instance;
}

NET *
DESIGN::new_net(NL_INET arg_nlinet)
{
	NET *net = new NET(arg_nlinet);
	netlist = new ListOfNET(net, netlist);
	return net;
}

EXTCONN *
DESIGN::new_extconn(NL_IPORT arg_iport)
{
	EXTCONN *extconn;
	nl_direction direction = nl_iport_direction(arg_iport);
	switch (direction) {
	    case nl_direction_in:
	        extconn = new EXTCONN(nl_iport_name(arg_iport), INPUT_EXTCONN_INSTANCETYPE);
		extconn->identify("external_in");
		break;

	    case nl_direction_out:
	        extconn = new EXTCONN(nl_iport_name(arg_iport), OUTPUT_EXTCONN_INSTANCETYPE);
		extconn->identify("external_out");
		break;

	    case nl_direction_null:
	    case nl_direction_inout:
	    case nl_direction_unknown:
	        extconn = new EXTCONN(nl_iport_name(arg_iport), OUTPUT_EXTCONN_INSTANCETYPE);
		extconn->cell = NULL;	// fixitup in DESIGN::complete_initialization
		break;
	}

	extconnlist = new ListOfEXTCONN(extconn, extconnlist);
	extconn->nlicell = NULL;
	return extconn;
}

CLONE *
DESIGN::new_clone(INSTANCE *instance, NL_CELL nlcell, NL_DESIGN parent_nldesign, char *name)
{
	CLONE *clone = new CLONE(instance, true);
	clone->nlcell = nlcell;
	clone->parent_cellname = strdup(nl_design_name(parent_nldesign));
	if (name == NULL) {
		clone->name = strdup(nl_cell_name(nlcell));
	} else {
		clone->name = strdup(name);
	}
			    

	clonelist = new ListOfCLONE(clone, clonelist);
	return clone;
}

/////////////////////////////////////////////////////////////

rc_t
NL_INTERFACE::get_instance_name(INSTANCE *instance, char *buf, int bufsize)
{
	nl_icell nlicell = instance->nlicell;
	char *p = buf;
	char *endp = buf + bufsize;

	nl_idesign parent_idesign = nl_icell_idesign(nlicell);
	nl_icell   parent_icell   = nl_idesign_icell(parent_idesign);

	if (parent_icell != NULL) {
		rc_t rc = get_instance_name_recursive(parent_icell, &p, &endp);
		if (rc != RC_NOMINAL)	return rc;
	}			

	char *name_component = nl_icell_name(nlicell);
	int len = strlen(name_component);
	if (p + len + 1 >= endp) {
		printf("NL_INTERFACE::get_instance_name overflowed/n");
		return RC_OVERFLOW;
	}
	strcpy(p, name_component);
	p += len;
	*p = '\0';

	return RC_NOMINAL;
}

rc_t
NL_INTERFACE::get_net_name(NET *net, char *buf, int bufsize)
{
	nl_inet nlinet = net->nlinet;
	char *p = buf;
	char *endp = buf + bufsize;

	nl_idesign parent_idesign = nl_inet_idesign(nlinet);
	nl_icell   parent_icell   = nl_idesign_icell(parent_idesign);

	if (parent_icell != NULL) {
		rc_t rc = get_instance_name_recursive(parent_icell, &p, &endp);
		if (rc != RC_NOMINAL)	return rc;
	}			

	char *name_component = nl_inet_name(nlinet);
	int len = strlen(name_component);
	if (p + len + 1 >= endp) {
		printf("NL_INTERFACE::get_instance_name overflowed\n");
		return RC_OVERFLOW;
	}
	strcpy(p, name_component);
	p += len;
	*p = '\0';

	return RC_NOMINAL;
}


rc_t
NL_INTERFACE::get_instance_name_recursive(nl_icell nlicell, char **p, char **endp)
{
	nl_idesign parent_idesign = nl_icell_idesign(nlicell);
	nl_icell   parent_icell   = nl_idesign_icell(parent_idesign);

	if (parent_icell != NULL) {
		rc_t rc = get_instance_name_recursive(parent_icell, p, endp);
		if (rc != RC_NOMINAL)	return rc;
	}			

	char *name_component = nl_icell_name(nlicell);
	int len = strlen(name_component);
	if (*p + len + 1 >= *endp) {
		printf("NL_INTERFACE::get_instance_name overflowed\n");
		return RC_OVERFLOW;
	}
	strcpy(*p, name_component);
	*p += len;
	**p = '/';
	*p += 1;

	return RC_NOMINAL;
}	

/////////////////////////////////////////////////////////

INSTANCE *
NL_INTERFACE::get_instance(char *arg_pathname) 
{
	char *pathname = strdup(arg_pathname);
	NL_IDESIGN idesign;
	char *last_chunk;

	rc_t rc = nl_interface->descend_path(pathname, &idesign, &last_chunk);
	if (rc != RC_NOMINAL) {
		delete pathname;
		return NULL;
	}

	NL_ICELL nlicell = nl_idesign_get_icell_by_name(idesign, last_chunk);
	if (nlicell == NULL)	return NULL;

	// XXX more attr hack
	INSTANCE *instance = NULL;
	nl_icell_attr nlicell_instance_attr = 
	    (nl_icell_attr)nl_idesign_get_attr_by_name(idesign, "nlicell_instance_attr");
	if (nlicell_instance_attr == NULL) {
		if (::speedy_verbose == true) printf("NL_INTERFACE::get_instance: found nlicell, but no nlicell_instance_attr???\n");
		delete pathname;
		return NULL;
	}
	nl_icell_attr_get(nlicell_instance_attr, nlicell, (void *)(&instance));
	delete pathname;
	return instance;
}

NET *
NL_INTERFACE::get_net(char *arg_pathname) 
{
	char *pathname = strdup(arg_pathname);
	NL_IDESIGN idesign;
	char *last_chunk;

	rc_t rc = nl_interface->descend_path(pathname, &idesign, &last_chunk);
	if (rc != RC_NOMINAL) {
		delete pathname;
		return NULL;
	}

	NL_INET nlinet = nl_idesign_get_inet_by_name(idesign, last_chunk);
	if (nlinet == NULL)	return NULL;

	NET *net = NULL;
	// XXX more attr hack
	nl_idesign parent_idesign = nl_inet_idesign(nlinet);
	nl_inet_attr nlinet_net_attr = 
	    (nl_inet_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlinet_net_attr");
	if (nlinet_net_attr == NULL) {
		delete pathname;
		return NULL;
	}

	nl_inet_attr_get(nlinet_net_attr, nlinet, (void *)(&net));

	if (net != NULL) {
		delete pathname;
		return net;
	}
	
	// maybe this name is an alias.
	nl_walk_connected_nets(
	    nl_inet_net(nlinet),
	    parent_idesign,
	    1, 1, 1, 1, 1, 
	    get_net_alias_callback,
	    &net);

	// if it didn't turn up, Oh Well....
	delete pathname;
	return net;
}

rc_t
NL_INTERFACE::descend_path(char *pathname, NL_IDESIGN *arg_idesign, char **last_chunk)
{
	// there *is* an nl function to do this... ui_find_object ....if you think this is easier... 
	//
	// result = ar_alloc (0, sizeof (nl_object))
	// int	ui_find_iobject (Tcl_Interp *interp, char *path, char *hier_sep, nl_kind kind,
	//	 nl_idesign idesign, int exact, int glob, int regexp, ar result)
	//	... path is the name of the cell (cell1/cell2/...)
	//	... kind is nl_kind_icell
	//	... hier_sep = "/"
	//	... "exact" means exact, "glob" means *, "regexp" means regular expression
	//	... interp is only needed if regexp, otherwise NULL is OK
	// if (ar_size(ar) != <what you expect>) ....
	// nl_object element;
	// ar_ref(ar, index, &element)
	// nl_icell nlicell = (nl_icell)element;	// known to be nlicell because of "kind" parm
	//
	// .... be sure to see ui/ui_find.c for whatall this code actually does....
	// .... probably in this case speed is not of the essence, but it seems to me like
	//	a good example of generalized interface functions run amok... 
	//	... for example, he starts with allocating an generalized array (size 1),
	//	which already involves 4 levels of function calls and 2 mallocs in order to
	//	tokenize the path....
	//

	NL_IDESIGN idesign = nl_interface->interface_nlidesign;

	char *p = pathname;
	while (1) {
		// get next path chunk
		char *r = p;
		char *q = r;
		while (1) {
			switch (*r) {
			    case '\\':
				r++;
				*q++ = *r++;
				continue;

			    case '/':
				r++;	
				*q++ = '\0';
				break;

			    case '\0':
				*last_chunk = p;
				*arg_idesign = idesign;
				return RC_NOMINAL;
	
			    default:
				*q++ = *r++;
				continue;
			}
			break;
		}		

		// look up chunk in idesign
		NL_ICELL nlicell = nl_idesign_get_icell_by_name(idesign, p);
		if (nlicell == NULL)	return RC_NOTFOUND;
		idesign = nl_icell_down_design(nlicell);	
		if (idesign == NULL)	return RC_NOTFOUND;

		p = r;
	}
}

nl_walk_status
NL_INTERFACE::get_net_alias_callback(nl_object obj, void *arg_net_ptr)
{
	NET *net = NULL;
	nl_inet nlinet = (nl_inet)obj;
	nl_idesign parent_idesign = nl_inet_idesign(nlinet);
	nl_inet_attr nlinet_net_attr = 
	    (nl_inet_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlinet_net_attr");
	if (nlinet_net_attr == NULL)	return nl_walk_status_continue;

	nl_inet_attr_get(nlinet_net_attr, nlinet, (void *)(&net));
	if (net == NULL)		return nl_walk_status_continue;

	*(NET **)arg_net_ptr = net;
	return nl_walk_status_stop;
}

///////////////////////////////////////////////////////////////

rc_t
NL_INTERFACE::mark_dont_resize_cell(char *cellname)
{
	// ....in nl world, "cellname" is the name of an nl_design...
	nl_context context = nl_design_context(interface_nldesign);
	if (context == NULL) {
		printf("NL_INTERFACE::mark_dont_resize....null context???\n");
		return RC_FAILED;
	}
	nl_design target_design = nl_context_get_design_by_name (context, cellname);
	if (target_design == NULL) {
		printf("WARNING: nl_interface design not found for \"%s\"\n", cellname);
		return RC_NOMINAL;
	}

	// nl macro...
	nl_design_for_all_idesigns (target_design, target_idesign) {
	// create cells
		nl_walk_cells(target_design, target_idesign, 1, 1, 1, 1, 0, 
		    &mark_dont_resize_callback, (void *)NULL);
	} nl_end_for;

	return RC_NOMINAL;
}

rc_t
NL_INTERFACE::mark_dont_resize_path(char *arg_pathname)
{
	char *pathname = strdup(arg_pathname);
	NL_IDESIGN nlidesign;
	char *last_chunk;

	rc_t rc = nl_interface->descend_path(pathname, &nlidesign, &last_chunk);
	if (rc != RC_NOMINAL) {
		printf("NL_INTERFACE::mark_dont_resize_path: path \"%s\" not found\n", pathname);
		delete pathname;
		return RC_NOMINAL;
	}

	NL_ICELL nlicell = nl_idesign_get_icell_by_name(nlidesign, last_chunk);
	if (nlicell == NULL) {
		printf("NL_INTERFACE::mark_dont_resize_path: path \"%s\" not found\n", pathname);
		delete pathname;
		return RC_NOMINAL;
	}

	// is this a leaf cell?  if so, there is an nlicell_instance_attr....
	// XXX more attr hack
	INSTANCE *instance = NULL;
	nl_icell_attr nlicell_instance_attr = 
	    (nl_icell_attr)nl_idesign_get_attr_by_name(nlidesign, "nlicell_instance_attr");
	if (nlicell_instance_attr != NULL) {
		// .... since the attribute exists for this icell, *some* things 
		// within are leaf nodes, but this one may or may not be....
		// .... which is to say, attibute value may be NULL (default value) ....
		nl_icell_attr_get(nlicell_instance_attr, nlicell, (void *)(&instance));
		if (instance != NULL) {
			instance->nl_clone->is_adjustable_for_size = false;

			delete pathname;
			return RC_NOMINAL;
		}
	}

	// nope, so walk subinstances....
	nlidesign = nl_icell_down_design(nlicell);
	NL_DESIGN nldesign = nl_idesign_design(nlidesign);
	nl_walk_cells(nldesign, nlidesign, 1, 1, 1, 1, 0, 
	    &mark_dont_resize_callback, (void *)NULL);

	return RC_NOMINAL;
}

nl_walk_status
NL_INTERFACE::mark_dont_resize_callback(nl_object obj, void *)
{
	nl_icell nlicell = (nl_icell)obj;
	INSTANCE *instance = NULL;

	// set instance pointer on icell, so we can find it while attaching nets
	// nl_icell_attr_set(nl_interface->icell_instance_attr, icell, (void *)instance);		
	// XXX ... temporary (hopefully) hackaround while Jay does better
	nl_idesign parent_idesign = nl_icell_idesign(nlicell);
	nl_icell_attr nlicell_instance_attr = 
	    (nl_icell_attr)nl_idesign_get_attr_by_name(parent_idesign, "nlicell_instance_attr");
	if (nlicell_instance_attr == NULL) {
		printf("NL_INTERFACE::mark_dont_resize: no nlicell_instance_attr for object %x???\n", (unsigned int)obj);
		return nl_walk_status_continue;
	}
	nl_icell_attr_get(nlicell_instance_attr, nlicell, (void *)(&instance));
	if (instance == NULL) {
		printf("NL_INTERFACE::mark_dont_resize: no instance for object %x???\n", (unsigned int)obj);
		return nl_walk_status_continue;
	}	

	instance->nl_clone->is_adjustable_for_size = false;
	return nl_walk_status_continue;
}

rc_t
NL_INTERFACE::insert_buffer(NET *original_net, NET *buffer_in_net, INSTANCE *buffer)
{
	printf("NL insert buffer nets %s\n", original_net->get_name());

	// see note on clones in nl.h
	// buffer_in_net is new; it runs from original driver to buffer inport
	// original net exists in nl; it used to source at original driver, now at 
	//	buffer outport
	// buffer is new; assume it is one-input, one-output thingamy
	//
	// the key is the driver port (which is now the NET::source of buffer_in_net)
	// ... outport->instance->nl_icell->nl_cell->nl_design is going to define 
	// the local context for modification
	
	// original driver instance
	INSTANCE *driver_instance = buffer_in_net->source->instance;
	nl_icell driver_icell = driver_instance->nlicell;
	if (driver_icell == NULL) {
		printf("driver not in NL???\n");
		return RC_FAILED;
	}
	nl_cell driver_cell = nl_icell_cell(driver_icell);
	nl_design local_design = nl_cell_design(driver_cell);

	// original driver outport
	char *driver_pin_name = buffer_in_net->source->outpin->name;
	nl_reference driver_reference = nl_cell_reference(driver_cell);
	nl_object driver_refpin_object = nl_reference_get_refpin_by_name(driver_reference, driver_pin_name);
	if (nl_object_kind(driver_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin driver_refpin = (nl_refpin)driver_refpin_object;
	nl_pin driver_pin = nl_cell_get_pin_by_refpin(driver_cell, driver_refpin);

	// existing net .... want the fragment that's within the local design
	nl_net original_nlnet = nl_pin_net(driver_pin);
	nl_pin_disconnect(driver_pin);

	// new net
	nl_net new_nlnet = NULL;
	while (new_nlnet == NULL) {
		sprintf(tstr, "inserted_buffer_input_%d", ::next_sequential_number++);
		if (nl_design_get_net_by_name(local_design, tstr) == NULL) {
			new_nlnet = nl_net_create(tstr, nl_wireclass_wire, local_design);
		}
	}
	nl_pin_connect_net(driver_pin, new_nlnet);

	// buffer
	char *reference_name = buffer->cell->name;
	nl_reference buffer_reference = nl_design_get_reference_by_name(local_design, reference_name);
	if (buffer_reference == NULL) {
		buffer_reference = nl_reference_create(reference_name, local_design, NULL);
	}
	nl_cell buffer_nlcell = NULL;
	while (buffer_nlcell == NULL) {
		sprintf(tstr, "inserted_buffer_%d", ::next_sequential_number++);
		if (nl_design_get_cell_by_name(local_design, tstr) == NULL) {
			buffer_nlcell = nl_cell_create(tstr, buffer_reference);
		}
	}

	// buffer inport
	nl_refpin in_refpin;
	char *input_pin_name = buffer->inportlist->inport->inpin->name;
	nl_object in_refpin_object = nl_reference_get_refpin_by_name(buffer_reference, input_pin_name);
	if (in_refpin_object != NULL) {
		in_refpin = (nl_refpin)in_refpin_object;
	} else {
		in_refpin = nl_refpin_create(input_pin_name, NULL, buffer_reference);
	}
	nl_pin buffer_input_pin = nl_cell_get_pin_by_refpin(buffer_nlcell, in_refpin);
	nl_pin_connect_net(buffer_input_pin, new_nlnet);

	// buffer outport
	nl_refpin out_refpin;
	char *output_pin_name = buffer->outportlist->outport->outpin->name;
	nl_object out_refpin_object = nl_reference_get_refpin_by_name(buffer_reference, output_pin_name);
	if (out_refpin_object != NULL) {
		out_refpin = (nl_refpin)out_refpin_object;
	} else {
		out_refpin = nl_refpin_create(output_pin_name, NULL, buffer_reference);
	}
	nl_pin buffer_output_pin = nl_cell_get_pin_by_refpin(buffer_nlcell, out_refpin);
	nl_pin_connect_net(buffer_output_pin, original_nlnet);

	return RC_NOMINAL;
}

rc_t
NL_INTERFACE::set_reference(INSTANCE *instance, CELL *cell) 
{
	printf("NL set reference instance %s to %s\n", instance->get_name(), cell->name);


	if (instance->nlicell == NULL)	return RC_INVALID;

	nl_cell nlcell = nl_icell_cell(instance->nlicell);
	nl_design local_design = nl_cell_design(nlcell);

	char *reference_name = cell->name;
	nl_reference reference = nl_design_get_reference_by_name(local_design, reference_name);
	if (reference == NULL) {
		reference = nl_reference_create(reference_name, local_design, NULL);

		// can you believe it??? I have to manufacture pins for this booger.
		// Otherwise, nl will ASSERT while checking them.
		// "No, your room still isn't clean yet."

		ListOfINPIN *inpl = cell->inpinlist;
		while (inpl != NULL) {
			INPIN *inpin = inpl->inpin;
			inpl = inpl->next;

			nl_refpin_create (inpin->name, NULL, reference);
		}

		ListOfOUTPIN *outpl = cell->outpinlist;
		while (outpl != NULL) {
			OUTPIN *outpin = outpl->outpin;
			outpl = outpl->next;

			nl_refpin_create (outpin->name, NULL, reference);
		}
	}

	nl_cell_set_reference(nlcell, reference);

	// // update speedy
	// CLONE *clone = instance->nl_clone;
	// clone->nominal_cell = cell;
	// ListOfINSTANCE *il = clone->instancelist;
	// while (il != NULL) {
	// 	INSTANCE *i = il->instance;
	// 	il = il->next;
	//
	//	if (i->cell != cell) {
	// 		i->change_cell(cell);
	// 	}
	// }

	return RC_NOMINAL;
}

rc_t
NL_INTERFACE::remove_buffer(INSTANCE *buffer)
{
	printf("NL remove buffer instance %s\n", buffer->get_name());

	if (buffer->nlicell == NULL) {
		printf("remove buffer \"%s\": no nlicell???\n", buffer->get_name());
		return RC_FAILED;
	}

	nl_icell	buffer_icell = buffer->nlicell;
	if (buffer_icell == NULL) {
		printf("buffer not in NL???\n");
		return RC_FAILED;
	}
	nl_cell		buffer_cell = nl_icell_cell(buffer_icell);
	nl_design	local_design = nl_cell_design(buffer_cell);
	nl_reference	buffer_reference = nl_cell_reference(buffer_cell);

	// buffer outport
	OUTPORT *	buffer_outport = buffer->outportlist->outport;
	char *		outpin_name = buffer_outport->outpin->name;
	nl_object	outport_refpin_object = nl_reference_get_refpin_by_name(buffer_reference, outpin_name);
	if (nl_object_kind(outport_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin	outport_refpin = (nl_refpin)outport_refpin_object;
	nl_pin		outport_nlpin = nl_cell_get_pin_by_refpin(buffer_cell, outport_refpin);
	nl_net		outport_net = nl_pin_net(outport_nlpin);

	// buffer inport
	INPORT *	buffer_inport = buffer->inportlist->inport;
	char *		inpin_name = buffer_inport->inpin->name;
	nl_object	inport_refpin_object = nl_reference_get_refpin_by_name(buffer_reference, inpin_name);
	if (nl_object_kind(inport_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin	inport_refpin = (nl_refpin)inport_refpin_object;
	nl_pin		inport_nlpin = nl_cell_get_pin_by_refpin(buffer_cell, inport_refpin);
	nl_net		inport_net = nl_pin_net(inport_nlpin);

	// at last!
	nl_net_for_all_pins(outport_net, pin) {
		if (pin != outport_nlpin) {
			// ... nl will disconnect from outprt_net
			nl_pin_connect_net(pin, inport_net);
		}
	} nl_end_for;

	// ... nl will disconnect outport pin
	nl_design_remove_cell(local_design, buffer_cell);
	nl_design_remove_net(local_design, outport_net);

	return RC_NOMINAL;
}

rc_t
NL_INTERFACE::add_split_buffer(INSTANCE *split_buffer, INSTANCE *original_buffer)
{
	printf("NL split buffer instance %s .. <- %s\n", split_buffer->get_name(), original_buffer->get_name());

	// the split has already been done in the Speedy data base,
	// so the split_buffer (which is new) has a new net on its outport,
	// with a useful set of exisiting inports which have been removed 
	// from the out-net of the original_buffer.  
	// Goal is to replicate all this in NL.
	
	// ... original buffer
	if (original_buffer->nlicell == NULL) {
		printf("remove original_buffer \"%s\": no nlicell???\n", original_buffer->get_name());
		return RC_FAILED;
	}

	nl_icell	original_buffer_icell = original_buffer->nlicell;
	if (original_buffer_icell == NULL) {
		printf("original_buffer not in NL???\n");
		return RC_FAILED;
	}
	nl_cell		original_buffer_cell = nl_icell_cell(original_buffer_icell);
	nl_design	local_design = nl_cell_design(original_buffer_cell);
	nl_reference	original_buffer_reference = nl_cell_reference(original_buffer_cell);
	nl_idesign	local_idesign = nl_icell_idesign(original_buffer_icell);

	// ... split buffer
	nl_cell		split_buffer_nlcell = NULL;
	while (split_buffer_nlcell == NULL) {
		sprintf(tstr, "split_buffer_%d", ::next_sequential_number++);
		if (nl_design_get_cell_by_name(local_design, tstr) == NULL) {
			split_buffer_nlcell = nl_cell_create(tstr, original_buffer_reference);	// ... same reference as original
		}
	}
	split_buffer->nlicell = nl_idesign_get_icell(local_idesign, split_buffer_nlcell);	

	// ... split buffer's inport
	INPORT *	split_buffer_inport = split_buffer->inportlist->inport;
	char *		split_buffer_inpin_name = split_buffer_inport->inpin->name;
	nl_object	split_buffer_in_refpin_object = nl_reference_get_refpin_by_name(original_buffer_reference, split_buffer_inpin_name);
	if (nl_object_kind(split_buffer_in_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin	split_buffer_in_refpin = (nl_refpin)split_buffer_in_refpin_object;
	nl_cell		split_buffer_cell = nl_icell_cell(split_buffer->nlicell);
	nl_pin		split_buffer_in_nlpin = nl_cell_get_pin_by_refpin(split_buffer_cell, split_buffer_in_refpin);

	// ... connect to input net
	NET *		in_net = original_buffer->inportlist->inport->net;
	nl_net		in_nlnet = nl_inet_net(in_net->nlinet);
	nl_pin_connect_net(split_buffer_in_nlpin, in_nlnet);

	// ... split buffer's outport
	OUTPORT *	split_buffer_outport = split_buffer->outportlist->outport;
	char *		split_buffer_outpin_name = split_buffer_outport->outpin->name;
	nl_object	split_buffer_out_refpin_object = nl_reference_get_refpin_by_name(original_buffer_reference, split_buffer_outpin_name);
	if (nl_object_kind(split_buffer_out_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin	split_buffer_out_refpin = (nl_refpin)split_buffer_out_refpin_object;
	nl_pin		split_buffer_out_nlpin = nl_cell_get_pin_by_refpin(split_buffer_cell, split_buffer_out_refpin);


	// ... split net
	// ... create new nlnet & hook it up to split buffer outport
	nl_net		split_nlnet = NULL;
	while (split_nlnet == NULL) {
		sprintf(tstr, "split_net_%d", ::next_sequential_number++);
		if (nl_design_get_net_by_name(local_design, tstr) == NULL) {
			split_nlnet = nl_net_create(tstr, nl_wireclass_wire, local_design);
		}
	}
	nl_pin_connect_net(split_buffer_out_nlpin, split_nlnet);

	
	// ... loads ...
	// ... for each load on new net, find nlpin & connect it to split net
	NET *split_net = split_buffer->outportlist->outport->net;
	ListOfINPORT *ipl = split_net->inportlist;
	while (ipl != NULL) {
		INPORT *	split_inport = ipl->inport;
		ipl = ipl->next;

		nl_icell	inport_icell = split_inport->instance->nlicell;
		if (inport_icell == NULL) {
			printf("inport_instance not in NL???\n");
			return RC_FAILED;
		}
		nl_cell		inport_nlcell = nl_icell_cell(inport_icell);
		nl_reference	inport_nlcell_reference = nl_cell_reference(inport_nlcell);
		
		char *		inpin_name = split_inport->inpin->name;
		nl_object	inport_refpin_object = nl_reference_get_refpin_by_name(inport_nlcell_reference, inpin_name);
		if (nl_object_kind(inport_refpin_object) != nl_kind_refpin) {
			printf("wrong kind???\n");
			return RC_FAILED;
		}
		nl_refpin	inport_refpin = (nl_refpin)inport_refpin_object;
		nl_pin		inport_nlpin = nl_cell_get_pin_by_refpin(inport_nlcell, inport_refpin);
	
		// ... nl will disconnect from outprt_net
		nl_pin_connect_net(inport_nlpin, split_nlnet);
	}

	return RC_NOMINAL;
}

rc_t
NL_INTERFACE::swap_inport_nets(INPORT *inport1, INPORT *inport2)
{
	printf("NL swap inport nets %s %s instance %s\n", inport1->net->get_name(), inport2->net->get_name(), inport1->instance->get_name());

	INSTANCE *instance = inport1->instance;
	if (instance->nlicell == NULL) {
		printf("swap inport nets: instance \"%s\": no nlicell???\n", instance->get_name());
		return RC_FAILED;
	}

	nl_icell instance_icell = instance->nlicell;
	if (instance_icell == NULL) {
		printf("instance not in NL???\n");
		return RC_FAILED;
	}
	nl_cell instance_cell = nl_icell_cell(instance_icell);
	// nl_design local_design = nl_cell_design(instance_cell);
	nl_reference instance_reference = nl_cell_reference(instance_cell);

	// inport1
	char *inpin1_name = inport1->inpin->name;
	nl_object inport1_refpin_object = nl_reference_get_refpin_by_name(instance_reference, inpin1_name);
	if (nl_object_kind(inport1_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin inport1_refpin = (nl_refpin)inport1_refpin_object;
	nl_pin inport1_nlpin = nl_cell_get_pin_by_refpin(instance_cell, inport1_refpin);

	// inport2
	char *inpin2_name = inport2->inpin->name;
	nl_object inport2_refpin_object = nl_reference_get_refpin_by_name(instance_reference, inpin2_name);
	if (nl_object_kind(inport2_refpin_object) != nl_kind_refpin) {
		printf("wrong kind???\n");
		return RC_FAILED;
	}
	nl_refpin inport2_refpin = (nl_refpin)inport2_refpin_object;
	nl_pin inport2_nlpin = nl_cell_get_pin_by_refpin(instance_cell, inport2_refpin);

	// at last!
	nl_pin_disconnect(inport1_nlpin);
	nl_pin_disconnect(inport2_nlpin);

	// inport net
	// .... nets have been swapped already in speedy design
	NET *inport1_net = inport1->net;
	if (inport1_net->nlinet == NULL) {
		printf("swap inports: net \"%s\" has no nlinet???\n", inport1_net->get_name());
		return RC_FAILED;
	}
	nl_pin_connect_net(inport1_nlpin, nl_inet_net(inport1_net->nlinet));

	NET *inport2_net = inport2->net;
	if (inport2_net->nlinet == NULL) {
		printf("swap inports: net \"%s\" has no nlinet???\n", inport2_net->get_name());
		return RC_FAILED;
	}
	nl_pin_connect_net(inport2_nlpin, nl_inet_net(inport2_net->nlinet));

	return RC_NOMINAL;
}

//////////////////////////////////////////////////

