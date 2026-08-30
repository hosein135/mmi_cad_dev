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

DSPFFILE::DSPFFILE(char *arg_name)
	: DIVIDER('/'), DELIMITER('.'), 
	rfid(NULL), 
	lineno(0),
	line_was_ungot(false), 
	rlist(NULL), clist(NULL)
{
	name = strdup(arg_name);
}

DSPFFILE::~DSPFFILE()
{
	free(name);
	if (rfid != NULL) {
		fclose(rfid);
		rfid = NULL;
	}
}

rc_t
DSPFFILE::read()
{
	// INSTANCEs are loaded; create NETs and connections to PORTs.

	rfid = fopen(name, "r");
	if (rfid == NULL)	{
		printf("dspf file \"%s\" not opened\n", name);
		return RC_NOTFOUND;
	}
	lineno = 0;
	error_count = 0;

	while (1) {

		rc_t rc = read_line();
		if (rc != RC_NOMINAL)	break;

		char field0[FIELDSIZE];
		char field1[FIELDSIZE];
		int rx = sscanf(linep, "%s", field0);
		if (rx == -1)	continue;


		else if (strcmp(field0, "*|NET") == 0)	{
			rc = read_dspfnet();	
			if (rc != RC_NOMINAL) {
				rc = skip_to_end_of_net();
				if (rc != RC_NOMINAL)	break;
				error_count++;
			}
		}			

		else if (strcmp(field0, "*|DSPF") == 0) {
			rx = sscanf(linep, "%s %s", field0, field1);
			if (rx == -1)	continue;
			if (strcmp(field1, "1.5") != 0) {
				printf("WARNING: dspf version is \"%s\", only 1.5 is guaranteed\n", field1);
			} else {
				printf("dspf version \"%s\"\n", field1);
			}
		}

		else if (strcmp(field0, "*|DESIGN") == 0) {
			rx = sscanf(linep, "%s %s", field0, field1);
			if (rx == -1)	continue;
			::top_level_cellname = strdup(field1);
			printf("design name \"%s\"\n", ::top_level_cellname);
		}
			
		else if (strcmp(field0, "*|DIVIDER") == 0) {
			rx = sscanf(linep, "%s %s", field0, field1);
			if (rx == -1)	continue;
			DIVIDER = field1[0];
		}

		else if (strcmp(field0, "*|DELIMITER") == 0) {
			rx = sscanf(linep, "%s %s", field0, field1);
			if (rx == -1)	continue;
			DELIMITER = field1[0];
		}

		// all done
		else if (strcmp(field0, ".ENDS") == 0) 	break;
		else if (strcmp(field0, ".END") == 0) 	break;

		// this section contains list of extconns, 
		// but doesn't say if they are ins or outs so can't use it.
		else if (strcmp(field0, ".SUBCKT") == 0)	;

		// send comments to console
		else if (strcmp(field0, "*|COMMENT") == 0) printf("%s", linep);

		// some don't care much stuff
		else if (strcmp(field0, "*|DATE") == 0)		;
		else if (strcmp(field0, "*|VENDOR") == 0)	;
		else if (strcmp(field0, "*|PROGRAM") == 0)	;
		else if (strcmp(field0, "*|BUSBIT") == 0)	;
		else if (strcmp(field0, "*|GROUND_NET") == 0)	;
		else if (strcmp(field0, "*|VERSION") == 0)	;

		else if (strcmp(field0, "*") == 0)		;	// comment?
		else if (strcmp(field0, "+") == 0)		;	// continuation line 


		else {
			printf("DSPFFILE::read: confused at lineno %d \"%s\"\n", lineno, linep);
			return RC_FAILED;
		}
	}

	fclose(rfid);
	rfid = NULL;

	if (error_count != 0) {
		printf("DSPFFILE NOT READ SUCCESSFULLY, %d errors encountered\n", error_count);
		return RC_FAILED;
	}
	return RC_NOMINAL;
}

rc_t
DSPFFILE::read_dspfnet()
{
	// linep -> "*|NET shift8/net_10[7] 3.3FF"

	char netname[FIELDSIZE];
	float netcapacitance;
	char capunits[FIELDSIZE];
	int rx = sscanf(linep, "%*s %s %f%s", netname, &netcapacitance, capunits);
	if (rx != 3) {
		printf("DSPFFILE::read_xxx: confused at line %s\n", linep);
		return RC_FAILED;
	}
	regularize_separators(netname);
	// printf("read_dspfnet: name \"%s\" cap %.3f units \"%s\"\n", netname, netcapacitance, capunits);

	NET *net = design->get_net(netname);
	if (net ==  fave_net) {
		printf("fave_net	DSPFFILE::read_dspfnet\n");
	}
	
	if (net == NULL) {
		printf("ERROR: net in dspf is not in design \"%s\"\n", netname);
		return RC_FAILED;
	}	

	if (::net_model == EXPLICIT_CAP_NETS) {
		// capacitance in Pico Farthings, plz.
		if (strcmp(capunits, "PF") == 0)	;	// cool
		else if (strcmp(capunits, "FF") == 0)	netcapacitance = netcapacitance / 1000;	
		else {
			printf("DSPFFILE::read_dspfnet: cap unit not recognized \"%s\" at line %d\n", capunits, lineno);
			return RC_FAILED;
		}
		net->metal_capacitance = netcapacitance;
	}

	if (rlist != NULL) {
		printf("read_dspffile: rlist not NULL starting net???\n");
		rlist = NULL;
	}
	if (clist != NULL) {
		printf("read_dspffile: clist not NULL starting net???\n");
		clist = NULL;
	}

	while (1) {
		rc_t rc = read_line();
		if (rc != RC_NOMINAL) return RC_FAILED;

		if (strncmp(linep, "*|", 2) != 0) {
			unget_line();
			break;
		}

		switch (linep[2]) {
		    case 'I':	
			rc = read_port(net);
			if (rc != RC_NOMINAL) return rc;
			continue;

		    case 'S':
			rc = read_node(net);
			if (rc != RC_NOMINAL) return rc;
			continue;

		    case 'P':
			rc = read_extconn(net);
			if (rc != RC_NOMINAL) return rc;
			continue;

		    default:
			printf("ERROR: unknown port code at line %d \"%s\"\n", lineno, linep);
			return RC_FAILED;
		}
		// not reached
	}

	while (1) {
		rc_t rc = read_line();
		if (rc != RC_NOMINAL) return RC_FAILED;

		switch (*linep) {
		    case 'C':
			rc = read_capacitor(net);
			if (rc != RC_NOMINAL) return rc;
			continue;

		    case 'R':
			rc = read_resistor(net);
			if (rc != RC_NOMINAL) return rc;
			continue;

		    case '*':
			// start of whatever's after this net (another net?)
		    case '.':
			// ... such as ".ENDS"
			unget_line();
			break;

			// else comment
			continue;
		
		    case '\0':
		    case '\n':
			// empty line
			continue;

			break;		

		    default:
			printf("ERROR: DSPFFILE::read_dspfnet confused in Rs and Cs at line %d \"%s\"\n", lineno, linep);
			return RC_FAILED;
			continue;
		}
		break;
	}


	// ... now chain them together, starting at source node
	// 
	OUTPORT *source = net->source;
	if (source == NULL) {
		if (::speedy_verbose == true) printf("net \"%s\" has no source, can't chain segments, so sad....\n", net->get_name());
	} else {
		source->segment = new SEGMENT(source);
		chain_segments(source->segment);
		if (rlist != NULL) printf("read dspfnet: leftover segements for net \"%s\"\n", netname);
		if (clist != NULL) printf("read dspfnet: leftover nodes for net \"%s\"\n", netname);
	}

	while (rlist != NULL) {
		R *tr = rlist;
		rlist = rlist->next;
		delete tr;
	}
	while (clist != NULL) {
		C *tc = clist;
		clist = clist->next;
		delete tc;
	}
	return RC_NOMINAL;
}

rc_t
DSPFFILE::read_port(NET *net)
{

	/////////////////////////////////////////////
	// ports
	// ... *|I (io_hsin|io_dim|MMI_MUX2A_3.out io_hsin|io_dim|MMI_MUX2A_3 out O 0.000000PF)
	// the capacitance value is "pin_cap", which always seems to be 0.0 in the sample file....
	// if the port refers to an instance we don't know about, just drop it (with warning message).

	char dspfpointname[FIELDSIZE];
	char instancename[FIELDSIZE];
	char portname[FIELDSIZE];
	char direction;
	float capacitance;
	char capunits[FIELDSIZE];

	int rx = sscanf(linep, "%*s (%s %s %s %c %f %s)", dspfpointname, instancename, portname, &direction, &capacitance, capunits);
	if (rx != 6) {
		printf("DSPFFILE::read_dspfnet port: sscanf confused at line %d\n", lineno);
		return RC_FAILED;
	}
	regularize_separators(dspfpointname);
	regularize_separators(instancename);

	// ignore pin cap; get it from libfile
	// if      (strcmp(capunits, "PF") == 0)	;	// cool
	// else if (strcmp(capunits, "FF") == 0)	capacitance = capacitance / 1000;	
	// else {
	// 	printf("DSPFFILE::read_dspfnet: cap unit not recognized \"%s\" at line %d\n", capunits, lineno);
	// 	return RC_FAILED;
	// }

	INSTANCE *instance = ::design->get_instance(instancename);
	if (instance == NULL) {
		printf("WARNING: unknown instance %s at line %d\n", instancename, lineno);
		PORT *port = new NODE(net);			
		port->pathname = strdup(dspfpointname);
		clist = new C(port, clist);
		return RC_NOMINAL;
	}
	if (instance->cell->type == CELLTYPE_UNKNOWN_CELL) {
		if (::speedy_verbose == true)	printf("WARNING: instance %s unidentified celltype \"%s\" at line %d\n", instancename, instance->cell->name, lineno);
		PORT *port = new NODE(net);			
		port->pathname = strdup(dspfpointname);
		clist = new C(port, clist);
		return RC_NOMINAL;
	}

	switch (direction) {
	    case 'I':
	    case 'i': {
		INPORT *inport = instance->get_inport(portname);
		if (inport == NULL) {
			// .... could be on a block we are ignoring .... 
			printf("can't find inport instance \"%s\" port \"%s\" on net %s\n", instance->get_name(), portname, net->get_name());
			return RC_FAILED;
		}
		inport->pathname = strdup(dspfpointname);
		ListOfINPORT *ipl = net->inportlist;
		while (ipl != NULL) {
			if (inport == ipl->inport)	break;
			ipl = ipl->next;
		}
		if (ipl == NULL) {
			printf("ERROR: can't find inport instance \"%s\" port \"%s\" on net %s ....2\n", instance->get_name(), portname, net->get_name());
			return RC_FAILED;
		}

		clist = new C((PORT *)inport, clist);
		return RC_NOMINAL;
	    }

	    case 'O':
	    case 'o': { 
		OUTPORT *outport = instance->get_outport(portname);
		if (outport == NULL) {
			// .... could be on a block we are ignoring .... 
			printf("ERROR: can't find inport instance \"%s\" inport \"%s\" on net \"%s\"...2\n", 
			    instance->get_name(), portname, net->get_name());
			return RC_FAILED;
		}

		outport->pathname = strdup(dspfpointname);
		clist = new C((PORT *)outport, clist);

		if (net->source != outport) {
			printf("ERROR: port \"%s\" is not source of net \"%s\" \n", dspfpointname, net->get_name()); 
			return RC_FAILED;
		} 
		return RC_NOMINAL;
	    }

	    case 'B':
	    case 'b': {
		OUTPORT *outport = instance->get_outport(portname);
		if (outport != NULL) {
			outport->pathname = strdup(dspfpointname);
			clist = new C((PORT *)outport, clist);

		} else {
			INPORT *inport = instance->get_inport(portname);
			if (inport != NULL) {
				inport->pathname = strdup(dspfpointname);
				clist = new C((PORT *)inport, clist);
				net->inportlist = new ListOfINPORT(inport, net->inportlist);
				inport->net = net;
			} else {	
			// .... could be on a block we are ignoring .... 
				printf("ERROR: can't find inport instance \"%s\" port  \"%s\" on net %s ...3\n", instance->get_name(), portname, net->get_name());
				return RC_FAILED;
			}
		}
		return RC_NOMINAL;
	    } 

	    default:
		printf("ERROR: unknown direction '%c' in net \"%s\"\n", direction, net->get_name());
		return RC_FAILED;
	}
	// not reached
}

rc_t
DSPFFILE::read_node(NET *net)
{

	/////////////////////////////////////////////
	// net-intermediate points
	// ... *|S (io_hsin|net_635.1 0.0 0.0)
	// that's an identifier + coordinates; yes, Virginia, real values are allowed.
	// ... but the location is obviously bogus this time....
	// 
	// ... or sometimes *|S (clk:1) ... no location info at all....

	char dspfpointname[FIELDSIZE];
	float xf = 0.0;
	float yf = 0.0;
	int rx = sscanf(linep, "%*s (%s %f %f)", dspfpointname, &xf, &yf);
	if (rx == 1) {
		int lastchar = strlen(dspfpointname) - 1;
		if (dspfpointname[lastchar] == ')')	dspfpointname[lastchar] = '\0';
	} else {
		printf("DSPFFILE::read_dspfnet 'S' port: sscanf confused at line %d\n", lineno);
		return RC_FAILED;
	}
	regularize_separators(dspfpointname);

	PORT *port = new PORT(NODE_TYPE, net);
	port->pathname = strdup(dspfpointname);
	clist = new C(port, clist);

	return RC_NOMINAL;
}				


rc_t
DSPFFILE::read_extconn(NET *net)
{
	////////////////////
	// extconns
	
	char dspfpointname[FIELDSIZE];
	char direction;
	float capacitance;
	char capunits[FIELDSIZE];
	int rx = sscanf(linep, "%*s (%s %c %f %s)", dspfpointname, &direction, &capacitance, capunits);
	if (rx != 4) {
		printf("DSPFFILE::read_dspfnet extconn: sscanf confused at line %d\n", lineno);
		return RC_FAILED;
	}
	regularize_separators(dspfpointname);

	// ignore pin cap; get it from libfile
	// if      (strcmp(capunits, "PF") == 0)	;	// cool
	// else if (strcmp(capunits, "FF") == 0)	capacitance = capacitance / 1000;	
	// else {
	// 	printf("DSPFFILE::read_dspfnet: cap unit not recognized \"%s\" at line %d\n", capunits, lineno);
	// 	return RC_FAILED;
	// }

	EXTCONN *extconn = design->get_extconn(dspfpointname);
	if (extconn == NULL) {
		printf("DSPFFILE::read_dspfnet: unknown extconn \"%s\" at line %d\n", dspfpointname, lineno);
		return RC_FAILED;
	}

	PORT *port;
	if (extconn->inportlist != NULL) port = (PORT *)extconn->inportlist->inport;
	else				 port = (PORT *)extconn->outportlist->outport;
	port->pathname = strdup(extconn->name);
	clist = new C(port, clist);

	return RC_NOMINAL;
}			

rc_t
DSPFFILE::read_capacitor(NET *net)
{

	////////////////////
	//  'C'apacitors

	char dspfpointname[FIELDSIZE];
	char cap_is_to_what[FIELDSIZE];
	float capacitance;
	char capunits[FIELDSIZE];
	int rx = sscanf(linep, "%*s %s %s %f%s", dspfpointname, cap_is_to_what, &capacitance, capunits);
	if (rx != 4) {
		printf("DSPFFILE::read_dspfnet 'C': sscanf confused at line %d\n", lineno);
		return RC_FAILED;
	}
	regularize_separators(dspfpointname);

	// capacitance in Pico Farthings, plz.
	if (strcmp(capunits, "PF") == 0)	;	// cool
	else if (strcmp(capunits, "FF") == 0)	capacitance = capacitance / 1000;	
	else {
		printf("DSPFFILE::read_dspfnet: 'C': cap unit not recognized \"%s\" at line %d\n", capunits, lineno);
		return RC_FAILED;
	}

	PORT *port;
	C *cl = clist;
	while (cl != NULL) {
		port = cl->port;
		if (strcmp(port->pathname, dspfpointname) == 0)	break;
		cl = cl->next;
	}
	if (cl == NULL) {
		printf("DSPFFILE::read_dspfnet: 'C': port name not recognized \"%s\" at line %d\n", dspfpointname, lineno);
		return RC_FAILED;
	}

	cl->capacitance = capacitance;
	return RC_NOMINAL;
}				


rc_t
DSPFFILE::read_resistor(NET *net)
{

	////////////////////
	// 'R'esistors ... this is where we get to find out how things are plugged together.
	// ... see declaration of class R in dspffile.h ....

	char end1name[FIELDSIZE];
	char end2name[FIELDSIZE];
	float resistance;
	int rx = sscanf(linep, "%*s %s %s %f", end1name, end2name, &resistance);
	if (rx != 3) {
		printf("DSPFFILE::read_dspfnet 'R': sscanf confused at line %d\n", lineno);
		return RC_FAILED;
	}
	regularize_separators(end1name);
	regularize_separators(end2name);
	
	PORT *end1 = NULL;
	PORT *end2 = NULL;
	C *cl = clist;
	while (cl != NULL) {
		PORT *p = cl->port;
		if (end1 == NULL			&&
		    strcmp(end1name, p->pathname) == 0	) {
			end1 = p;
			if (end2 != NULL) break;
		}
		if (end2 == NULL			&&
		    strcmp(end2name, p->pathname) == 0	) {
			end2 = p;
			if (end1 != NULL) break;
		}
		cl = cl->next;
	}
	if (cl == NULL) {
		if (end1 == NULL) {
			printf("DSPFFILE::read_dspfnet: 'R': port name not recognized \"%s\" at line %d\n", end1name, lineno);
		} else {
			printf("DSPFFILE::read_dspfnet: 'R': port name not recognized \"%s\" at line %d\n", end2name, lineno);
		}
		return RC_FAILED;
	}

	R* r = new R(end1, end2, resistance);
	r->next = rlist;
	rlist = r;

	return RC_NOMINAL;
}


void
DSPFFILE::chain_segments(SEGMENT *source_segment)
{
	// "source_segment" isn't necessarily the NET::source, 
	// but it's the uphill end of whatever segemnts we might find
	// ... after I find a segment, I start over to avoid any confusion with 
	// list pointers.  Maybe it's not necessary.... or could do breadth-first
	// ... but thinking is so hard.

	// first, find the capacitance in the 'C'-list.... if any...
	if (clist == NULL)	return;
	if (clist->port == source_segment->right_end) {
		source_segment->capacitance = clist->capacitance;
		C *tc = clist;
		clist = clist->next;
		delete tc;
	} else {	
		C *cl = clist;
		while (cl->next != NULL) {
			if (cl->next->port == source_segment->right_end) {
				source_segment->capacitance = cl->next->capacitance;
				C *tc = cl->next;
				cl->next = cl->next->next;
				delete tc;
				break;
			}
			cl = cl->next;
		}
	}
	
	if (rlist == NULL)	return;

	PORT *source = source_segment->right_end;
	if (rlist->end1 == source	||
	    rlist->end2 == source	) {
		// duplicate code, see below

		R *r = rlist;	// .... not a real ListOfR
		rlist = rlist->next;

		SEGMENT *segment;
		if (r->end1 == source)	segment = new SEGMENT(r->end2);
		else			segment = new SEGMENT(r->end1);
		source_segment->segmentlist = new ListOfSEGMENT(segment, source_segment->segmentlist);
		segment->resistance = r->resistance;
		delete r;
		
		chain_segments(segment);
		chain_segments(source_segment);
		return;
	}

	R* rl = rlist;
	while (rl->next != NULL) {
		if (rl->next->end1 == source	||
		    rl->next->end2 == source	) {
			// duplicate code (except for ->next), from above

			R *r = rl->next;
			rl->next = rl->next->next;

			SEGMENT *segment;
			if (r->end1 == source)	segment = new SEGMENT(r->end2);
			else			segment = new SEGMENT(r->end1);
			source_segment->segmentlist = new ListOfSEGMENT(segment, source_segment->segmentlist);
			segment->resistance = r->resistance;
			delete r;
		
			chain_segments(segment);
			chain_segments(source_segment);
			return;
		}
		rl = rl->next;
	}

	return;
}


void
DSPFFILE::unget_line() 
{
	line_was_ungot = true;
}

rc_t
DSPFFILE::read_line()
{
	if (line_was_ungot == true) {
		line_was_ungot = false;
		return RC_NOMINAL;
	}

	rv = fgets(linebuf, LINEBUFSIZE, rfid);
	lineno++;
	// if (lineno == fave_lineno) {
	// 	printf("fave_line %d\n", fave_lineno);
	// }

	if (rv == NULL)	{
		*linebuf = '\0';
		linep = linebuf;
		return RC_NOTFOUND;
	}

	linep =	linebuf;

	// // convert '$...$' notation to regular array '[...]'
	// char *p = linebuf;
	// char *endp = p + strlen(linebuf);
	// while (p < endp) {
	// 	if (*p == '$') {
	// 		*p++ = '[';
	// 		while (1) {
	// 			if (p > endp) {
	// 				printf("DSPFFILE::read_xxx: confused at line %s\n", linep);
	// 				return RC_FAILED;
	// 			}
	// 			if (*p == '$') {
	// 				*p = ']';
	// 				break;
	// 			}
	// 			p++;
	// 		}
	// 	}
	// 	p++;
	// }
	// printf("%s\n", linep);
	return RC_NOMINAL;
}

rc_t
DSPFFILE::skip_to_end_of_net() 
{
	while (1) {
		rc_t rc = read_line();
		if (rc != RC_NOMINAL) {
			printf("ERROR: read_line failed while skipping??\n");
			return RC_FAILED;
		}	

		if (strncmp(linep, "*|NET", 5) == 0) {
			unget_line();
			return RC_NOMINAL;
		}
		if (strncmp(linep, "*|N", 2) == 0)	continue;
		switch (*linep) {
		    case 'C':		continue;
		    case 'R':		continue;
		    case '*':
			// start of whatever's after this net (another net?)
			if (linep[1] == '|') {
				unget_line();
				return RC_NOMINAL;
			}

			// else comment
			continue;
		
		    case '\0':
		    case '\n':
			// empty line
			continue;

		    default:
			printf("ERROR: confused while skipping to end of net\n");
			return RC_FAILED;
			continue;
		}
		// not reached
	}
	// not reached
	return RC_FAILED;
}

void
DSPFFILE::regularize_separators(char *string)
{
	// change separators from whatever wierd stuff specified in file to '/' and ':'
	// ... if there are '/' in the file that aren't seprators, they will look
	//	like separators to me... so I need to change them to something else;
	//	and I know there aren't going to be any of the old separators, so
	//	I guess I can use them.  Unless they use ':' for DIVIDER and '\' for DELIMITER.... // 
	if (DIVIDER != '/') {
		char *p = string;
		char *endp = p + strlen(string);
		while (p < endp) {
			if (*p == DIVIDER) 	*p++ = '/';
			else if (*p == '/')	*p++ = DIVIDER;
			p++;
		}
	}
	if (DELIMITER != ':') {
		char *p = string;
		char *endp = p + strlen(string);
		while (p < endp) {
			if (*p == DELIMITER) 	*p++ = ':';
			else if (*p == ':')	*p++ = DELIMITER;
			p++;
		}
	}
}

