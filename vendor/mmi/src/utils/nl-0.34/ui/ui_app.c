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

#include "tcl.h"
#include "port.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "skip-list.h"
#include "nl.h"
#include "pnl.h"
#include "tcl.h"
#include "ui.h"
#include "ui_int.h"
#include "hier.h"
#include "tcl_init.h"


static
void
ui_set_string_variable (char **var_p, char *val)
{
  char *var = *var_p;
  int length = strlen (val);
  char *new_val = ckalloc (length + 1);

  strcpy (new_val, val);

  if ( var != NULL ) {
    ckfree (var);
  }

  *var_p = new_val;
}

mem_group ui_default_mem_group = NULL;


extern char *ui_update_current_design (ClientData, Tcl_Interp *,
				       char *, char *, int);

static nl_context ui_current_context = NULL;


nl_object
ui_get_nl_context (void)
{
  return (nl_object) ui_current_context;
}


int
ui_app_init (Tcl_Interp *interp, char *prefix, void **context_p,
	     const char *version)
{
  nl_context context;
  int prefix_len = strlen (prefix);
  char *command_buf = alloca (64 + prefix_len);

  if ( Tcl_Init (interp) == TCL_ERROR ) {
    return TCL_ERROR;
  }

  context = nl_context_create ();
  ui_current_context = context;

  ui_default_mem_group = mem_group_set (NULL);
  mem_group_set (ui_default_mem_group);

  if ( context_p != NULL ) {
    *context_p = context;
  }

  ui_obj_register_type (); 

  ui_cmd_register_commands (interp, prefix, context);
  ui_tcl_register_commands (interp, prefix, context);
  ui_cmd_sort_commands ();

  sprintf (command_buf, "%scurrent_design", prefix);
  /*  Tcl_LinkVar (interp, command_buf,
	       (char *) &ui_current_design_name,
	       TCL_LINK_STRING);
  */

  Tcl_TraceVar (interp, command_buf, TCL_GLOBAL_ONLY |
		TCL_TRACE_WRITES | TCL_TRACE_READS | TCL_TRACE_UNSETS,
		ui_update_current_design, (void *) context);

  sprintf (command_buf, "%shierarchy_separator", prefix);
  Tcl_LinkVar (interp, command_buf, (char *) &ui_hierarchy_separator,
	       TCL_LINK_STRING);
  ui_set_string_variable (&ui_hierarchy_separator, "/");

  sprintf (command_buf, "%sbus_naming_style", prefix);
  Tcl_LinkVar (interp, command_buf, (char *) &ui_bus_naming_style,
	       TCL_LINK_STRING);
  ui_set_string_variable (&ui_bus_naming_style, "%s[%d]");

  sprintf (command_buf, "%sx_grid_size", prefix);
  Tcl_LinkVar (interp, command_buf, (char *) &ui_x_grid_size, TCL_LINK_INT);
  ui_x_grid_size = 1;

  sprintf (command_buf, "%sy_grid_size", prefix);
  Tcl_LinkVar (interp, command_buf, (char *) &ui_y_grid_size, TCL_LINK_INT);
  ui_y_grid_size = 1;

  {
    static char *version_str;

    version_str = malloc (strlen (version) + 2);
    strcpy (version_str, (char *) version);

    sprintf (command_buf, "%sversion", prefix);
    Tcl_LinkVar (interp, command_buf, (char *) &version_str,
		 TCL_LINK_STRING | TCL_LINK_READ_ONLY);
  }

  Tcl_SourceRCFile (interp);

  {
    int status = tcl_init (interp);

    return status;
  }
}


int
ui_alias_init (Tcl_Interp *interp, char *prefix, void *context)
{
  const char make_aliases[] = "nl_make_aliases";
  char *buf = alloca (sizeof (make_aliases) + 1 + strlen (prefix) + 1);
  int status;
  
  sprintf (buf, "%s %s", make_aliases, prefix);

  status = Tcl_Eval (interp, buf);

  /*
  Tcl_LinkVar (interp, "current_design",
	       (char *) &ui_current_design_name,
	       TCL_LINK_STRING);
  */

  Tcl_TraceVar (interp, "current_design", TCL_GLOBAL_ONLY |
		TCL_TRACE_WRITES | TCL_TRACE_READS | TCL_TRACE_UNSETS,
		ui_update_current_design, (void *) context);

  Tcl_LinkVar (interp, "hierarchy_separator", (char *) &ui_hierarchy_separator,
	       TCL_LINK_STRING);

  Tcl_LinkVar (interp, "bus_naming_style", (char *) &ui_bus_naming_style,
	       TCL_LINK_STRING);

  Tcl_LinkVar (interp, "x_grid_size", (char *) &ui_x_grid_size, TCL_LINK_INT);

  Tcl_LinkVar (interp, "y_grid_size", (char *) &ui_y_grid_size, TCL_LINK_INT);

  return status;
}
