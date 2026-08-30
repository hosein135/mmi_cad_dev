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

///////////////////////////
// user definable-variables


///////////////////////////
// internal working state

NL_INTERFACE *	nl_interface = NULL;



///////////////////////////
// more stuff


///////////////////////////
// Debuggery


///////////////////////////
// declarations

extern "C"	nl_object ui_obj_get_nl_object (Tcl_Obj *);
extern	rc_t	clear(char *);		// in commands.cc

/////////////////////////////////////////////
// nlsh interface command

extern "C" {
int
speedy_load_from_nl(ClientData cd, Tcl_Interp *interp, int objc, Tcl_Obj *objv[])
{
	char *before = new char();
	
	Tcl_Obj *current_nldesign_tcl_obj = objv[1];
	nl_design interface_nldesign = (nl_design)ui_obj_get_nl_object(current_nldesign_tcl_obj);
	top_level_cellname = nl_design_name(interface_nldesign);

	nl_idesign interface_nlidesign = nl_idesign_get_or_create(interface_nldesign, NULL);
	nl_interface = new NL_INTERFACE(interface_nldesign, interface_nlidesign);
	rc_t rc = nl_interface->initialize();
	if (rc != RC_NOMINAL)	return RC_FAILED;

	char *after = new char();
	printf("...speedy data base initialization allocated %x (0x%d) bytes\n", after-before, after-before);
	return TCL_OK;
}
}

/////////////////////////////////////////////
// commands

rc_t
update_nl_with_resizes()
{
	design->collect_clones();
	ListOfCLONE *cl = design->resized_clonelist;
	while (cl != NULL) {
		CLONE *clone = cl->clone;
		cl = cl->next;

		INSTANCE *typical_instance = clone->instancelist->instance;
		if (typical_instance->nlicell == NULL) {
			printf("update_nl_with_resizes: instance %s got no icell????\n", typical_instance->get_name());
			continue;
		}

		nl_interface->set_reference(typical_instance, typical_instance->cell);
	}

	return RC_NOMINAL;
}

rc_t
load_design_from_nl()
{
	char *before = new char(); // for measureing memory usage

	if (::current_nldesign_tcl_obj == NULL) {
		printf("load_design_from_nl: current_nldesign_tcl_obj is not set\n");
		return RC_FAILED;	
	}

	nl_design interface_nldesign = (nl_design)ui_obj_get_nl_object(::current_nldesign_tcl_obj);
	nl_idesign interface_nlidesign = nl_idesign_get_or_create(interface_nldesign, NULL);

	nl_interface = new NL_INTERFACE(interface_nldesign, interface_nlidesign);

	if (::design != NULL) {
		delete ::design;
		::design = NULL;
	}
	::design = new DESIGN();
	nl_interface->speedy_design = ::design;
	nl_interface->speedy_design->nl_interface = nl_interface;
	::use_sue_clones = false;

	rc_t rc = nl_interface->initialize();
	if (rc != RC_NOMINAL)	return RC_FAILED;

	char *after = new char();
	printf("...speedy data base uses %x (0x%d) bytes\n", 
	   after-before, after-before);

	return RC_NOMINAL;
}

rc_t
load_instances_from_nl()
{
	if (::current_nldesign_tcl_obj == NULL) {
		printf("load_instances_from_nl: current_nldesign_tcl_obj is not set\n");
		return RC_FAILED;	
	}

	nl_design interface_nldesign = (nl_design)ui_obj_get_nl_object(::current_nldesign_tcl_obj);
	nl_idesign interface_nlidesign = nl_idesign_get_or_create(interface_nldesign, NULL);

	nl_interface = new NL_INTERFACE(interface_nldesign, interface_nlidesign);

	if (::design != NULL) {
		delete ::design;
		::design = NULL;
	}
	::design = new DESIGN();
	nl_interface->speedy_design = ::design;
	nl_interface->speedy_design->nl_interface = nl_interface;
	::use_sue_clones = false;

	rc_t rc = nl_interface->initialize_instances();
	if (rc != RC_NOMINAL)	return RC_FAILED;

	return RC_NOMINAL;
}

rc_t
nl_do_something(BOOLEAN executing_command_file, 
	char *cmd, char *arg1, char *arg2, char *arg3, char *arg4)
{
	rc_t rc = RC_NOTFOUND;

	if (strcmp(cmd, "update_nl_with_resizes") == 0) {
		return update_nl_with_resizes();
	}

	if (strcmp(cmd, "load_design_from_nl") == 0) {
		return load_design_from_nl();
	}

	if (strcmp(cmd, "load_instances_from_nl") == 0) {
		return load_instances_from_nl();
	}

	return rc;
}

