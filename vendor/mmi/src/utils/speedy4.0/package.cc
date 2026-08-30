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


#include <util.h>

extern "C" {

extern int speedy_command(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *);
extern int speedy_set_tcl_obj(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *);
extern int speedy_output_file(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *);
extern int speedy_begin_net(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *);
extern int speedy_add_point(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *);
extern int speedy_end_net(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *);

int Speedy_package_Init(Tcl_Interp *interp)
{
  Tcl_CreateObjCommand(interp, "speedy_command", speedy_command, NULL, NULL);
  Tcl_CreateObjCommand(interp, "speedy_set_tcl_obj", speedy_set_tcl_obj, NULL, NULL);
  Tcl_CreateObjCommand(interp, "speedy_steiner_output_file", speedy_output_file, NULL, NULL);
  Tcl_CreateObjCommand(interp, "speedy_steiner_begin_net", speedy_begin_net, NULL, NULL);
  Tcl_CreateObjCommand(interp, "speedy_steiner_add_point", speedy_add_point, NULL, NULL);
  Tcl_CreateObjCommand(interp, "speedy_steiner_end_net", speedy_end_net, NULL, NULL);

  return TCL_OK;
}

}	   // end extern "C" 

/////////////////////////////////////////////
// interfaces to/from tcl

// global state
Tcl_Interp *interp = NULL;


extern rc_t do_something(BOOLEAN executing_from_command_file, 
	char *cmd, char *arg2, char *arg3, char *arg4, char *arg5);
extern rc_t get(char **retv, char *name, char *arg3, char *arg4);

extern "C" {
int
speedy_command(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *objv)
{
	interp = arg_interp;

	char *cmd = "";
	char *arg2 = "";
	char *arg3 = "";
	char *arg4 = "";
	char *arg5 = "";
	char *arg6 = "";
	char *arg7 = "";

	if (objc < 2) {
		interp->result = "sy_command: not enough args";
		return TCL_OK;
	}
	cmd = strdup(Tcl_GetStringFromObj(objv[1], NULL));

	// .... for strdup & free, 
	// see Welch "Practical Programming in Tcl and Tk" (3rd ed) 
	// page 617 "pitfalls..."

	if (objc < 3) goto callit;
	arg2 = strdup(Tcl_GetStringFromObj(objv[2], NULL));

	if (objc < 4) goto callit;
	arg3 = strdup(Tcl_GetStringFromObj(objv[3], NULL));

	if (objc < 5) goto callit;
	arg4 = strdup(Tcl_GetStringFromObj(objv[4], NULL));

	if (objc < 6) goto callit;
	arg5 = strdup(Tcl_GetStringFromObj(objv[5], NULL));

	if (objc < 7) goto callit;
	arg6 = strdup(Tcl_GetStringFromObj(objv[6], NULL));

	if (objc < 8) goto callit;
	arg7 = strdup(Tcl_GetStringFromObj(objv[7], NULL));

    callit:
	rc_t rc;		

	if (strcmp(cmd, "get") == 0) {
		char *retv;
		rc = get(&retv, arg2, arg3, arg4);
		if (rc == RC_NOMINAL) 	interp->result = retv;
	}

	else rc = do_something(false, cmd, arg2, arg3, arg4, arg5);

	switch (rc) {
	    case RC_NOMINAL:
		break;

	    case RC_NOTFOUND: 
		interp->result = "command not found";
		break;

	    default:
		interp->result = "command failed";
		break;
	}

	free(cmd);
	free(arg2);
	free(arg3);
	free(arg4);
	free(arg5);
	free(arg6);
	free(arg7);
	return TCL_OK;

}	// .. of sy_command(...) ...

int
speedy_set_tcl_obj(ClientData cd, Tcl_Interp *arg_interp, int objc, Tcl_Obj * const *objv)
{
	interp = arg_interp;

	char *name = "";

	if (objc < 2) {
		interp->result = "speedy_set_tcl_obj: not enough args";
		return TCL_OK;
	}

	// .... for strdup & free, 
	// see Welch "Practical Programming in Tcl and Tk" (3rd ed) 
	// page 617 "pitfalls..."

	name = strdup(Tcl_GetStringFromObj(objv[1], NULL));
	Tcl_Obj *tcl_obj = objv[2];

	if (strcmp(name, "nl_current_design") == 0) {
		::current_nldesign_tcl_obj = tcl_obj;
	}

	else {
		printf("speedy_set_tcl_obj: don't recognize object name \"%s\"\n", name);
	}



	free(name);
	return TCL_OK;

}	// .. speedy_set_tcl_obj(...) ...
}	// .. of extern 'C' ...

rc_t
speedy2tcl(char *cmd, char *retv)
{
	if (interp == NULL)	return RC_INVALID;

	int code = Tcl_Eval(interp, cmd);
	if (code == TCL_OK) {
		if (retv != NULL) {
			strcpy(retv, interp->result);
		}
	 	return RC_NOMINAL;
	}
	else {
		printf("tcl command: \"%s\"\n", cmd);
		printf("failed: \"%s\"\n", interp->result);
		return RC_FAILED;
	}
}

rc_t
speedy2tcl_setvar(char *varname, char *value)
{
	if (interp == NULL) 	return RC_INVALID;

	char *saved_value = Tcl_SetVar(interp, varname, value, TCL_GLOBAL_ONLY);

	if (strcmp(value, saved_value) == 0) {
	 	return RC_NOMINAL;
	}
	else {
		printf("tcl setvar \"%s\" value \"%s\" \n", varname, value);
		printf("failed: \"%s\"\n", saved_value);
		return RC_FAILED;
	}
}
