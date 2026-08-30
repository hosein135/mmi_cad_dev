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

static int UI_CMD_FUNCTION (Tcl_Interp *interp, nl_context context
			    UI_CMD_PROTO);

static
int
UI_CMD_WRAPPER (ClientData __data, Tcl_Interp *interp,
		int __argc, Tcl_Obj *CONST __argv[])
{
  nl_context context = (nl_context) __data;
  UI_CMD_VAR_DECLS
  struct ui_option __opts[] = {
    { "-help", ui_help, NULL, NULL },
    UI_CMD_OPTIONS
    { NULL, ui_null, NULL, NULL }};
  static char *__switch_table[] = {
    "-help",
    UI_CMD_SWITCHES
    NULL };
  struct ui_argument __args[] = {
    UI_CMD_ARGUMENTS
    { ui_null, NULL, NULL, ui_null, NULL }};

  volatile int __status;

  UI_CMD_INIT_OPTIONS

  UI_CMD_INIT_ARGUMENTS

  error_catch {
    __status = ui_getopt (context, __opts, __switch_table, __args, UI_CMD_DOC,
		 interp, __argc, __argv);
  
    if ( __status == TCL_RETURN ) {
      __status = TCL_OK;
    }
    else if ( __status == TCL_OK ) {
      __status = UI_CMD_FUNCTION (interp, context UI_CMD_PARAMETERS);
    }
  } error_on_tag (1) {
    Tcl_AppendResult (interp, UI_CMD_NAME_STRING, ": ", error_message, NULL);
    __status = TCL_ERROR;
  } error_on_error {
    __status = error_current_tag;
  } error_on_exit {
    UI_CMD_CLEANUP;
  } error_end;

  {
    mem_group group = mem_group_set (ui_default_mem_group);
    ASSERT (group == ui_default_mem_group);
  }

  return __status;
}


static
int
UI_CMD_FUNCTION (Tcl_Interp *interp, nl_context context UI_CMD_PROTO)
