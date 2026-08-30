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



// // ....this guy is using the port connection information to output
// // a verilog netlist.  There's a command-line option that causes it 
// // to be called
// 
// rc_t
// SUE::write_netlist(VIEW_EXPR *view, char *cellname)
// {
// 	NET_EXPR *net;
// 	
// 	// ... here is the file we are going to write
// 	NETLIST_FILE nl_file(cellname);
// 	FILE *nl = nl_file.open();
// 	if (nl == NULL) exxit(7, "");
// 
// 	// ... write a list of ports
// 	INTERFACE_EXPR *interface = view->interface;
// 	ListOfPORT_EXPR *tport_list = interface->port_list;
// 	while (tport_list != NULL) {
// 		PORT_EXPR *port = tport_list->expr;
// 
// 		char *dirstring;
// 		switch (port->direction) {
// 		    case INPUT:		dirstring = "input";	break;
// 		    case OUTPUT:	dirstring = "output";	break;
// 		    case INOUT:		dirstring = "inout";	break;
// 		    default:		exxit(8, "");
// 		}
// 
// 		char *portname = port->namedef->get_stringvalue();
// 		fprintf(nl, "	%s		%s;\n",
// 		    dirstring, portname);
// 		// delete portname;
// 
// 		tport_list = tport_list->next;
// 	}
// 	fprintf(nl, "\n");
// 
// 	// ... now print out a list of internal wires
// 	CONTENTS_EXPR *contents = view->contents;
// 	if (contents == NULL ||
// 	    contents->page_list == NULL ||
// 	    contents->page_list->next != NULL)	exxit(9, "");
// 	PAGE_EXPR *page = contents->page_list->expr;
// 
// 	ListOfNET_EXPR *net_list = page->net_list;
// 	while (net_list != NULL) {
// 		NET_EXPR *net = net_list->expr;
// 
// 		char *namestr = net->namedef->get_stringvalue();
// 		
// 		// if this net is named after a port, skip it
// 		tport_list = interface->port_list;
// 		while (tport_list != NULL) {
// 			PORT_EXPR *port = tport_list->expr;
// 
// 			char *portname = port->namedef->get_stringvalue();
// 			if (strcmp(namestr, portname) == 0) {
// 				// delete portname;
// 				// delete namestr;
// 				namestr = NULL;
// 				break;
// 			}
// 
// 			tport_list = tport_list->next;
// 		}
// 		if (namestr != NULL) {
// 			fprintf(nl, "	wire		%s;\n", namestr);
// 			// delete namestr;
// 		}
// 
// 		net_list = net_list->next;
// 	}
// 	fprintf(nl, "\n");
// 
// 	// ....So! the hard part!
// 	// print out a list of instances, together with the
// 	// port or net connected to each instance port
// 	ListOfINSTANCE_EXPR *instance_list = page->instance_list;
// 	while (instance_list != NULL) {
// 		INSTANCE_EXPR *instance = instance_list->expr;
// 
// 		// .. find the cell of which this is an instance
// 		VIEWREF_EXPR *viewref = instance->viewref;
// 		if (viewref == NULL)  exxit(10, "");
// 		CELLREF_EXPR *cellref = viewref->cellref;
// 		if (cellref == NULL) exxit(11, "");
// 		char *instancecellname = cellref->cellnamedef->get_stringvalue();
// 		char *instancename = instance->namedef->get_stringvalue();
// 		fprintf(nl, "	%s%s %s(", cellname_prefix, instancecellname, instancename);
// 		// delete instancecellname;
// 		CELL_EXPR *cell;
// 		cellref->cellnamedef->get_where_defined(&cell);
// 
// 		// ...now I need to find a view of this cell that has a portlist.
// 		VIEW_EXPR *instanceview = NULL;
// 		ListOfVIEW_EXPR *tvl = cell->view_list;
// 		while (tvl != NULL) {
// 			instanceview = tvl->expr;
// 
// 			if (instanceview->viewtype == SCHEMATIC) break;
// 
// 			tvl = tvl->next;
// 		}
// 		if (instanceview == NULL ||
// 		    instanceview->interface == NULL ||
// 		    instanceview->interface->port_list == NULL)	exxit(12, "");
// 	
// 		// ... walk over the instance ports
// 		ListOfPORT_EXPR *port_list = instanceview->interface->port_list;
// 		ListOfCHARSTAR *outlist = NULL;
// 		while (port_list != NULL) {
// 			PORT_EXPR *port = port_list->expr;
// 			
// 			char *portname = port->namedef->get_stringvalue();
// 			char *netname = NULL;  
// 
// 			// ... look through the nets; 
// 			// ... look through the port references in the "joined"
// 			//	for a reference to this instance port...
// 
// 			net_list = page->net_list;
// 			while (net_list != NULL) {
// 				net = net_list->expr;
// 
// 				if (net->joined == NULL) exxit(13, "");
// 				ListOfPORTREF_EXPR *portref_list = net->joined->portref_list;
// 				while (portref_list != NULL) {
// 					PORTREF_EXPR *portref = portref_list->expr;
// 
// 					INSTANCEREF_EXPR *instanceref = portref->instanceref;
// 					if (instanceref == NULL) {
// 						; // this is a module port, can't be us
// 					} else {
// 						if (strcmp(portname, portref->resolved_name) == 0 &&
// 						    strcmp(instancename, portref->instanceref->resolved_name) == 0) {
// 							// found it!
// 							netname = net->namedef->get_stringvalue();
// 							break;
// 						}
// 					}
// 
// 					portref_list = portref_list->next;
// 				}
// 				if (netname != NULL) break;
// 
// 				net_list = net_list->next;
// 			}
// 
// 			// IT TURNS OUT that we are taking the ports in (apparantly)
// 			// the opposite order from the sue netlister.  So we are going
// 			// to stack the strings, then print them out when done. Yuck!
// #define STRSIZE 100			
// 			char *outstr = (char *)malloc(STRSIZE);
// 			// ... what to print if not connected???  ...we make empty parens.
// 			sprintf(outstr, ".%s(%s)", portname, netname);
// 			outlist = new ListOfCHARSTAR(outstr, outlist);
// 
// 			// if (netname != NULL)	delete netname;
// 
// 			port_list = port_list->next;
// 		}
// 
// 		while (outlist != NULL) {
// 			fprintf(nl, "%s", outlist->str);
// 			ListOfCHARSTAR *tl = outlist;
// 			outlist = outlist->next;
// 			// delete tl;
// 
// 			if (outlist != NULL)	fprintf(nl, ", ");
// 
// 		}
// 
// 
// 		fprintf(nl, ");\n");
// 
// 		instance_list = instance_list->next;
// 	}
// 	fprintf(nl, "\n");
// 
// 	return RC_NOMINAL;
// }

