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
#include "nl.h"
#include "ui.h"
#include "ui_int.h"


ar ui_all_commands;


void
ui_cmd_object_result (Tcl_Interp *interp, nl_object object, ar path)
{
  Tcl_Obj *result = ui_obj_create (object, path);

  Tcl_SetObjResult (interp, result);
}

void  
ui_cmd_append_object_list (Tcl_Interp *interp, Tcl_Obj *list,
			   nl_object object, ar path)
{
  Tcl_Obj *obj = ui_obj_create (object, path);

  Tcl_ListObjAppendElement (interp, list, obj);
}


void  
ui_cmd_object_list_result (Tcl_Interp *interp, ar objects, ar paths)
{
  Tcl_Obj *result = Tcl_NewListObj (0, NULL);

  ar_for_all_indexed (objects, nl_object, object, index) {
    ar object_path;

    if ( paths != NULL )
      ar_ref (paths, index, &object_path);
    else
      object_path = NULL;

    ui_cmd_append_object_list (interp, result, object, object_path);
  } ar_end_for;

  Tcl_SetObjResult (interp, result);
}


nl_walk_status
ui_cmd_append_result_walker (nl_object nl_obj, void *ptr)
{
  Tcl_Interp *interp = ptr;
  Tcl_Obj *tcl_obj = ui_obj_create ((nl_object) nl_obj, NULL);
  Tcl_Obj *list = Tcl_GetObjResult (interp);

  ASSERT (nl_obj != NULL);

  Tcl_ListObjAppendElement (interp, list, tcl_obj);

  return nl_walk_status_continue;
}


nl_idesign
ui_get_idesign_for_path (ar path, nl_context context)
{
  nl_idesign top_idesign = ui_get_current_idesign (context);

  if ( path != NULL ) {
    nl_icell icell = (nl_icell) ui_path_to_iobject (path, top_idesign);
    if ( icell != NULL ) {
      nl_idesign idesign = nl_icell_down_design (icell);

      return idesign;
    }
    else {
      return top_idesign;
    }
  }
  else {
    return top_idesign;
  }
}


void
ui_cmd_register (Tcl_Interp *interp, char *name, char *prefix,
		 Tcl_ObjCmdProc *proc, nl_context context)
{
  char *cmd_name = MALLOC (strlen (prefix) + strlen (name) + 1);

  sprintf (cmd_name, "%s%s", prefix, name);
  ar_add (ui_all_commands, &cmd_name);
  Tcl_CreateObjCommand (interp, cmd_name, proc, context, NULL);
}


void
ui_cmd_register_commands (Tcl_Interp *interp, char *prefix, nl_context context)
{
  ui_all_commands = ar_alloc (64, sizeof (char *));

  ui_cmd_register_basic_commands (interp, prefix, context);
  ui_cmd_register_find_commands (interp, prefix, context);
  ui_cmd_register_io_commands (interp, prefix, context);
  ui_cmd_register_misc_commands (interp, prefix, context);
  ui_cmd_register_physical_commands (interp, prefix, context);
  ui_cmd_register_synthesis_commands (interp, prefix, context);
  ui_cmd_register_pat_commands (interp, prefix, context);
}


void
ui_cmd_sort_commands (void)
{
  ar_sort (ui_all_commands, ar_compare_string);
}
