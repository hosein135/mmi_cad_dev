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

#include	"util.h"

/////////////////////////////////////////////////////
// these functions "speedy_xxx" are registered as tcl ObjCommands
// (called by tcl interpreter, not through do_something)

// Interface routines the Sue uses to feed location data into DESIGN,
// and to develop an "xxx.est_dspf" file
//
// Sue has previously written an "xxx.vg" file, we do hope and suppose.
// If it isn't already in, we find & read it, initialising the global DESIGN.
// Sue then feeds us info from DPC, one net at a time; as each net is complete,
// we construct a steiner route for it 
//
// The steiner route is a minimal-distance spanning tree of the ports on the net... 
// introducing intermeiate "ports" or NODEs as necessary... and SEGMENTs are created 
// for each port-to-port connection.  The details of the physical connection between
// the ports are not specified; see the "global route" algorithm.
//
// Assuming that each segment can be physically accomplished with wire length equal
// to the manhattan distance between the end ports, we compute R and C for each 
// segment.
//
// The resulting information is stored in the DESIGN structure for use by the 
// static timing analyzer in computing net delays, and is also written out to the 
// .est_dspf file for the edification of whoever cares.
//


DSPFFILE::DSPFFILE(int arg_fd,
    double arg_rconstx, double arg_rconsty,
    double arg_cconstx, double arg_cconsty, 
    double arg_min_rc,
    char *arg_string, BOOLEAN arg_primetime)
	: rfid(NULL), 
	string(arg_string), timing_tool_is_primetime(arg_primetime),
	wfid(NULL)
{
	::rconst = arg_rconstx;
	::cconst = arg_cconstx;
	if (arg_rconstx != arg_rconsty) {
		printf("ERROR: can't handle rconstx != rconsty\n");
	}		
	if (arg_cconstx != arg_cconsty) {
		printf("ERROR: can't handle cconstx != cconsty\n");
	}	
	
	min_rc = arg_min_rc * 4.0e15; // convert to RC/2 in fs

	printf("writing est_dspf file: rconst %f  cconst %f  min_rc %f\n", 
	    ::rconst, ::cconst, min_rc);

	rc_index = 1;	// reference designator in output file

	wfd = dup(arg_fd);
	wfid = fdopen(wfd, "w");
	if (wfid == NULL) {
		printf("fdopen DSPF file failed\n");
	}

	// write physical constants as comments to output file
	// ... so Speedy can pick them up later...
	fprintf(wfid, "*|COMMENT rconst = %f ohms per x grid\n", ::rconst);
	fprintf(wfid, "*|COMMENT cconst = %f femtofarads per x grid\n", ::cconst);
	fprintf(wfid, "*|COMMENT cap_fudge = %f femtofarads\n", cap_fudge);
}

rc_t
DSPFFILE::write_net(NET *net)
{
	static float	recent_cap_fudge = -1.0;
	if (cap_fudge != recent_cap_fudge) {
		fprintf(wfid, "*|COMMENT cap_fudge = %f femtofarads\n", cap_fudge * 1000.0);
		recent_cap_fudge = cap_fudge;
	}

	OUTPORT *source = net->source;
	if (source == NULL) {
	    if (net->inportlist != NULL		&&
	        net->inportlist->next != NULL	) {
			// ... could also check for name ".../uc_net..."
			printf("ERROR: net \"%s\" has no source; not written\n", net->get_name());
		}
		return RC_NOMINAL;
	}

	// we did compute_net_characteristics in speedy_end_net

	float net_capacitance = net->source->load_capacitance * 1000.0;	// he likes femtofarads, we do picofarads
	if (net_capacitance == 0) {
		// don't do anything
		return RC_NOMINAL;
	}

	// ... capacitance only ...
	if (string != NULL) {
		if (timing_tool_is_primetime == true) {
			char *each = strtok(name, " ");
			while (1) {
				fprintf(wfid, "%s%g %s\n", string, net_capacitance, each);
				each = strtok(NULL, " ");
				if (each == NULL)	break;
			}
		} 
		else {
			fprintf(wfid, "%s%s %gfF\n", string, name, net_capacitance);
		}

		fflush(wfid);
		return RC_NOMINAL;
	}

	// ... full montey, please ...
	fprintf(wfid, "\n");
	fprintf(wfid, "*|NET %s %gFF\n", net->get_name(), net_capacitance);

	// instance ports
	switch (source->instance->cell->type) {
	    case CELLTYPE_BASIC:
		fprintf(wfid, "*|I (%s:%s %s %s O 0 %d %d)\n",
		    source->instance->get_name(), source->outpin->name,
		    source->instance->get_name(), source->outpin->name,
		    source->x, source->y);
		break;

	    case CELLTYPE_EXTCONN:
		// ... extconn
		// see note in DSPFFILE::read_dspfnet, case 'P'
		// fprintf(wfid, "*|P (%s O %d %d)\n",
		fprintf(wfid, "*|P (%s I %d %d)\n",
		    net->get_name(), source->x, source->y);
		break;

	    case CELLTYPE_DUMMYSOURCE:
	    case CELLTYPE_UNKNOWN_CELL:
		break;
	}
	
	ListOfINPORT *ipl = net->inportlist;
	while (ipl != NULL) {
		INPORT *inport = ipl->inport;
		ipl = ipl->next;

		if (inport->instance->cell->type == CELLTYPE_EXTCONN) {
			// ... extconn
			// see note in DSPFFILE::read_dspfnet, case 'P'
			// fprintf(wfid, "*|P (%s I %d %d)\n",
			fprintf(wfid, "*|P (%s O %d %d)\n",
			    inport->inpin->name, inport->x, inport->y);
		}
		else {
			fprintf(wfid, "*|I (%s:%s %s %s I 0 %d %d)\n",
			    inport->instance->get_name(), inport->inpin->name,
			    inport->instance->get_name(), inport->inpin->name,
			    inport->x, inport->y);
		}
	}

	// ... the capacitor at the source ...
	if (source->instance != NULL) {
		fprintf(wfid, "C%d %s:%s VSS %gFF\n",
		    rc_index++, 
		    source->instance->get_name(), source->outpin->name,
		    source->segment->capacitance);
	}
	else {
		fprintf(wfid, "C%d %s VSS %gFF\n",
		    rc_index++, 
		    net->get_name(),
		    source->segment->capacitance);
	}

	ListOfSEGMENT *sl = source->segment->segmentlist;
	while (sl != NULL) {
		SEGMENT *segment = sl->segment;
		sl = sl->next;

		write_segment(net, segment, net->source);
	}

	fflush(wfid);
	return RC_NOMINAL;
}

rc_t
DSPFFILE::write_segment(NET *net, SEGMENT *segment, PORT *left_end)
{
	float dspf_capacitance = segment->capacitance * 1000.0;

	// if either end is an extconn, this segment doesn't show up in dspffile
	if (left_end->type == OUTPORT_TYPE					&&
	    ((OUTPORT *)left_end)->instance->cell->type == CELLTYPE_EXTCONN	) {
		;	
	}
	else if (segment->right_end->type == INPORT_TYPE				&&
	    ((INPORT *)(segment->right_end))->instance->cell->type == CELLTYPE_EXTCONN	) {
		;	
	}

	else if (segment->right_end->type == NODE_TYPE) {
		NODE *node = (NODE *)segment->right_end;
		// ... the right end ...
		fprintf(wfid, "*|S (%s:%d)\n", net->get_name(), node->index);

		// ... the capacitor at the right end ...
		fprintf(wfid, "C%d %s:%d VSS %gFF\n",
		    rc_index++, net->get_name(), node->index,
		    dspf_capacitance);

		// ... the resistor from the left end to the right end ...
		if (left_end->type == OUTPORT_TYPE) {	
			OUTPORT *outport = (OUTPORT *)left_end;
			fprintf(wfid, "R%d %s:%s %s:%d %g\n", 
			    rc_index++, outport->instance->get_name(), outport->outpin->name, 
			    net->get_name(), node->index, segment->resistance);
		}
		else {	
			NODE *left_node = (NODE *)left_end;
			fprintf(wfid, "R%d %s:%d %s:%d %g\n", 
			    rc_index++, net->get_name(), node->index,
			    net->get_name(), left_node->index, segment->resistance);
		}			
	}
	else {
		// ... must be an INPORT ... already did the right end
		INPORT *inport = (INPORT *)segment->right_end;

		// ... the capacitor at the right end ...
		fprintf(wfid, "C%d %s:%s VSS %gFF\n",
		    rc_index++, inport->instance->get_name(), inport->inpin->name,
		    dspf_capacitance);

		// ... the resistor from the left end to the right end ...
		if (left_end->type == OUTPORT_TYPE) {	
			OUTPORT *outport = (OUTPORT *)left_end;
			fprintf(wfid, "R%d %s:%s %s:%s %g\n", 
			    rc_index++, outport->instance->get_name(), outport->outpin->name, 
			    inport->instance->get_name(), inport->inpin->name, segment->resistance);
		}
		else {	
			NODE *left_node = (NODE *)left_end;
			fprintf(wfid, "R%d %s:%d %s:%s %g\n", 
			    rc_index++, net->get_name(), left_node->index,
			    inport->instance->get_name(), inport->inpin->name, 
			    segment->resistance);

		}			
	}

	ListOfSEGMENT *sl = segment->segmentlist;
	while (sl != NULL) {
		SEGMENT *next_segment = sl->segment;
		sl = sl->next;

		write_segment(net, next_segment, segment->right_end);
	}
	
	return RC_NOMINAL;
}


//////////////////////////////////////////////////////////////////////////
//// TCL interface functions

// NOTE: this set of call instructions is independent 
// of the usual speedy interface.  

// the usual thing would be:
//	output_file;
//	while (happy) {
//		begin_net;
//		while (happy) {
//			add_point();
//		}
//		end_net;
//	close_file;
//
// XXX... actually Lee doesn't ever do any such close_file, but 
// retained state isn't awful.... still....

DSPFFILE *	dspffile = NULL;
NET *		current_net = NULL;

extern "C" {

int 
speedy_output_file(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
	// obj 1 is tcl channel descriptor, like "file6"
	// the number is a Unix file descriptor
	if (objc < 1) {
		interp->result = "need output channel descriptor";
		return TCL_OK;
	}
	char *channel_descriptor = Tcl_GetStringFromObj(objv[1], NULL);

	if (strncmp(channel_descriptor, "file", 4) != 0) {
		interp->result = "channel descriptor should be like \"file6\"";
		return TCL_OK;
	}

	int file_descriptor = atoi(channel_descriptor + 4);
	if (file_descriptor < 1 || file_descriptor > 64) {
		interp->result = "file descriptor appears to be out of range?????";
		return TCL_OK;
	}

	// parse objs
	// Lee passes distinct values for x and y directions, but 
	// they've never been different and I don't really know how to 
	// use them.  So we parse them, then check for equality when
	// write DSPFFILE is created.
	double rconstx = 1.0;
	double rconsty = 1.0;
	double cconstx = 1.0;
	double cconsty = 1.0;
	double min_rc = 0.0;
	BOOLEAN timing_tool_is_primetime = false;
	char *string = NULL;
	

	for (int i = 2; i < objc; i++) {
		char *next = Tcl_GetStringFromObj(objv[i], NULL);

		if (strcmp(next, "-rconstx") == 0) {
			if (++i >= objc) {
				interp->result = "rconstx not specified";
				return TCL_OK;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &rconstx);
			if (rc != 0) {
				interp->result = "can't read rconstx";
				return TCL_OK;
			}
		}				

		else if (strcmp(next, "-rconsty") == 0) {
			if (++i >= objc) {
				interp->result = "rconsty not specified";
				return TCL_OK;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &rconsty);
			if (rc != 0) {
				interp->result = "can't read rconsty";
				return TCL_OK;
			}
		}				

		else if (strcmp(next, "-cconstx") == 0) {
			if (++i >= objc) {
				interp->result = "cconstx not specified";
				return TCL_OK;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &cconstx);
			if (rc != 0) {
				interp->result = "can't read cconstx";
				return TCL_OK;
			}
		}				

		else if (strcmp(next, "-cconsty") == 0) {
			if (++i >= objc) {
				interp->result = "cconsty not specified";
				return TCL_OK;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &cconsty);
			if (rc != 0) {
				interp->result = "can't read cconsty";
				return TCL_OK;
			}
		}				

		else if (strcmp(next, "-min_rc") == 0) {
			if (++i >= objc) {
				interp->result = "min_rc not specified";
				return TCL_OK;
			}
			int rc = Tcl_GetDoubleFromObj(interp, objv[i], &min_rc);
			if (rc != 0) {
				interp->result = "can't read min_rc";
				return TCL_OK;
			}
		}				

		else if (strcmp(next, "-string") == 0) {
			if (++i >= objc) {
				interp->result = "string not specified";
				return TCL_OK;
			}
			string = Tcl_GetStringFromObj(objv[i], NULL);
		}				

		else if (strcmp(next, "-pt") == 0) {
			int pt;
			if (++i >= objc) {
				interp->result = "boolean not specified";
				return TCL_OK;
			}
			int code = Tcl_GetIntFromObj(interp, objv[i], &pt);
			if (code != TCL_OK) return code;
			if (pt != 0) timing_tool_is_primetime = true;
		}				

		else {
			interp->result = "unknown objv";
			return TCL_OK;
		}
	}

	// load the design ... from the vg file
	// rchar *dirname = Tcl_GetVar(interp, "cur_s", 0);
	int code = Tcl_Eval(interp, "sy_load_design_for_netlist");
	if (code != TCL_OK) {
		printf("load design failed: \"%s\"\n", interp->result);
		return RC_FAILED;
	}

	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	
	printf("open dspf file, SPEEDY_MODE \"%s\"\n", SPEEDY_MODE);
	if (strcmp(SPEEDY_MODE, "SMART_GLOBAL_TIMING") == 0)	return TCL_OK;

	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////


	// convert femtofarad constants for use with picofarads
	cconstx /= 1000.0;
	cconsty /= 1000.0;

	// yahoo!
	dspffile = new DSPFFILE(file_descriptor, rconstx, rconsty,
	    cconstx, cconsty, min_rc, string, timing_tool_is_primetime);
	
	// I would prefer to do this *after* the data has been loaded
	// (when the file is closed) but I never get any such callback.
	// Poor me.
	::location_information_is_loaded = true;
	return TCL_OK;
}

int
speedy_begin_net(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
	if (strcmp(SPEEDY_MODE, "SMART_GLOBAL_TIMING") == 0)	return TCL_OK;

	if (dspffile == NULL) {
		interp->result = "no current DSPF file";
		return TCL_OK;
	}

	char *name = NULL;
	if (objc > 1) {
		name = Tcl_GetStringFromObj(objv[1], NULL);
	}

	char *netname = strdup(Tcl_GetStringFromObj(objv[1], NULL));
	// sue represents array indexes as $...$, we need to conver to [...]
	// char *p = netname;
	// while (*p != '\0') {
	// 	if (*p == '$') {
	// 		*p++ = '[';
	// 		while (*p != '\0') {
	// 			if (*p == '$') {
	// 				*p++ = ']';
	// 				break;
	// 			} else p++;
	// 		}
	// 	} else p++;
	// }	

	current_net = design->get_net(netname);
	if (current_net == NULL) {
		printf("begin_net: no such net \"%s\"\n", netname);
		interp->result = "no such net";
		current_net = NULL;
		return TCL_OK;
	}
	delete netname;

	dspffile->rc_index = 1;
	return TCL_OK;
}


int
speedy_add_point(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
	if (strcmp(SPEEDY_MODE, "SMART_GLOBAL_TIMING") == 0)	return TCL_OK;

	if (current_net == NULL) {
		interp->result = "no current net";
		return TCL_OK;
	}

	int x;
	int y;

	int code = Tcl_GetIntFromObj(interp, objv[4], &x);
	if (code != TCL_OK) return code;

	code = Tcl_GetIntFromObj(interp, objv[5], &y);
	if (code != TCL_OK) return code;

	char *instancename = strdup(Tcl_GetStringFromObj(objv[1], NULL));
	// sue represents array indexes as $...$, we need to conver to [...]
	// char *p = instancename;
	// while (*p != '\0') {
	// 	if (*p == '$') {
	// 		*p++ = '[';
	// 		while (*p != '\0') {
	// 			if (*p == '$') {
	// 				*p++ = ']';
	// 				break;
	// 			} else p++;
	// 		}
	// 	} else p++;
	// }	

	char *portname = Tcl_GetStringFromObj(objv[2], NULL);

	INSTANCE *instance = design->get_instance(instancename);
	if (instance != NULL) {
		delete instancename;

		PORT *port = instance->get_port(portname);
		if (instance->cell == NULL) {
			printf("add_point net \"%s\" no cell definition for instance \"%s\"\n",
			    current_net->get_name(), instance->get_name());
			return TCL_OK;
		}
		if (port == NULL) {
			printf("add_point net \"%s\" no such port \"%s\" on instance \"%s\"\n",
			    current_net->get_name(), portname, instance->get_name());
			return TCL_OK;
		}

		// a lot of work for not much, but IMPORTANT not much...
		port->x = x;
		port->y = y;

		return TCL_OK;
	}

	char *extconnname = strdup(Tcl_GetStringFromObj(objv[2], NULL));
	EXTCONN *extconn = design->get_extconn(extconnname);
	if (extconn != NULL) {
		delete instancename;

		PORT *port;
		if (extconn->inportlist != NULL) {	
			port = extconn->inportlist->inport;
		} else {
			port = extconn->outportlist->outport;
		}
		port->x = x;
		port->y = y;

		return TCL_OK;
	}

	
	printf("add_point: no such instance or extconn \"%s\" \"%s\"\n", instancename, extconnname);
	interp->result = "no such instance or extconn";

	delete instancename;
	return TCL_OK;
}


int
speedy_end_net(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
	if (strcmp(SPEEDY_MODE, "SMART_GLOBAL_TIMING") == 0)	return TCL_OK;

	if (current_net == NULL) {
		interp->result = "no current net";
		return TCL_OK;
	}
	
	if (current_net->source == NULL) {
		printf("net %s has no source, not written\n", current_net->get_name());
		return TCL_OK;
	}


	current_net->locate_all_ports();
	// if (current_net->all_ports_are_located() != true) {
	// 	//sprintf(tstr, "some ports on net \"%s\" are not located", current_net->get_name());
	// 	// interp->result = tstr;
	// 	// return TCL_OK;
	// }

	// ... see note on cap_fudge in speedy_commands.cc ... "it's what we do.."
	double double_cap_fudge;
	int code = Tcl_GetDoubleFromObj(interp, objv[1], &double_cap_fudge);
	if (code != 0) {
		  interp->result = "can't read cap_fudge";
		  return TCL_OK;
	}
	cap_fudge = ((float)double_cap_fudge) / 1000.0;		//  fempto pharads -> piko ...

	if (current_net->inportlist == NULL)	return TCL_OK;

	rc_t rc = current_net->steiner_route(); 	
	if (rc != RC_NOMINAL) {	
		interp->result = "steiner_route failed";
		return TCL_OK;
	}

	rc = current_net->compute_net_characteristics(); 	
	if (rc != RC_NOMINAL) {	
		interp->result = "compute_net_characteristics failed";
		return TCL_OK;
	}

	rc = dspffile->write_net(current_net);
	if (rc != RC_NOMINAL) {
		interp->result = "write_net failed";
		return TCL_OK;
	}

	return TCL_OK;
}

int
close_file(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
	if (strcmp(SPEEDY_MODE, "SMART_GLOBAL_TIMING") == 0)	return TCL_OK;

	if (dspffile == NULL) {
		interp->result = "DSPF file not open";
		return TCL_OK;
	}
	delete dspffile;	
	dspffile = NULL;

	return TCL_OK;
}


}	// ....extern "C" { ....



////////////////////////////////////////////////
// ... these are in the usual command interface

rc_t
sue_do_something(BOOLEAN executing_command_file, char *cmd, char *arg1, char *arg2, char *arg3, char *arg4)
{
	return RC_NOTFOUND;
}

