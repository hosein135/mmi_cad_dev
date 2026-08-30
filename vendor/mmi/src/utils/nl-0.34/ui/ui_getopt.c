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
#include "error.h"
#include "mem.h"
#include "hashtab.h"
#include "ar.h"
#include "str.h"
#include "skip-list.h"
#include "nl.h"
#include "pnl.h"
#include "ui.h"
#include "ui_int.h"


static Tcl_ObjType *ui_tcl_list_type = NULL;
static Tcl_ObjType *ui_nl_object_type = NULL;
static mem_group ui_getopt_mem_group = NULL;


static void ui_wrong_arg_type_error (const char *, const char *) NORETURN;


static
void
ui_getopt_init (void)
{
  ui_tcl_list_type = Tcl_GetObjType ("list");
  ui_nl_object_type = ui_obj_get_type ();
  ui_getopt_mem_group = mem_group_create ("ui_getopt", 8);
}


void
ui_set_current_design (Tcl_Interp *interp, nl_context context,
		       nl_design design, int silent)
{
  Tcl_Obj *tcl_obj1 = ui_obj_create ((nl_object) design, NULL);
  Tcl_Obj *tcl_obj2 = ui_obj_create ((nl_object) design, NULL);
  char *design_name = nl_design_name (design);
  Tcl_Obj *name1 = Tcl_NewStringObj ("nl_current_design",
				     sizeof ("nl_current_design"));
  Tcl_Obj *name2 = Tcl_NewStringObj ("current_design",
				     sizeof ("current_design"));

  nl_context_set_current_design (context, design);

  Tcl_ObjSetVar2 (interp, name1, NULL, tcl_obj1, TCL_GLOBAL_ONLY);
  Tcl_ObjSetVar2 (interp, name2, NULL, tcl_obj2, TCL_GLOBAL_ONLY);

  if ( !silent ) {
    fprintf (stderr, "Current design is now \"%s\".\n", design_name);
  }
}


nl_design
ui_get_current_design (nl_context context)
{
  nl_design design = nl_context_current_design (context);

  if ( design == NULL ) {
    error ("the current_design is not set.");
  }
  else {
    return design;
  }
}


nl_idesign
ui_get_current_idesign (nl_context context)
{
  nl_design design = ui_get_current_design (context);
  nl_dll_head idesign_head = nl_design_idesigns (design);
  nl_idesign idesign = (nl_idesign) nl_dll_gen_first (idesign_head);

  if ( idesign == NULL ) {
    idesign = nl_idesign_create (design, NULL, NULL);
  }

  return idesign;
}


static
int
ui_translate_integer_arg (Tcl_Obj *arg, int *val)
{
  int len;
  char *str = Tcl_GetStringFromObj (arg, &len);

  if ( str ) {
    *val = atoi (str);
    return TCL_OK;
  }
  else {
    return TCL_ERROR;
  }
}
  

static
int
ui_translate_string_arg (Tcl_Obj *arg, char **val)
{
  int len;
  char *str = Tcl_GetStringFromObj (arg, &len);

  if ( str != NULL ) {
    *val = str;
    return TCL_OK;
  }
  else {
    return TCL_ERROR;
  }
}


static
int
ui_translate_double_arg (Tcl_Obj *arg, double *val)
{
  int len;
  char *str = Tcl_GetStringFromObj (arg, &len);

  if ( str ) {
    double x;

    sscanf (str, "%lf", &x);
    *val = x;

    return TCL_OK;
  }
  else {
    return TCL_ERROR;
  }
}
  

static
int
ui_get_tcl_fd (char *str, int *fd_p)
{
  if ( strncmp (str, "file", 4) != 0 ) {
    return 0;
  }
  else {
    int i = 4;

    while ( str[i] ) {
      if ( ! isdigit ((int) str[i]) ) {
	return 0;
      }

      i++;
    }

    {
      int fd = atoi (str + 4);

      *fd_p = fd;
      
      return 1;
    }
  }
}
  

static
int
ui_translate_file_arg (Tcl_Interp *interp, Tcl_Obj *arg, char *access,
		       FILE **val)
{
  int len;
  char *str = Tcl_GetStringFromObj (arg, &len);

  if ( str != NULL ) {
    if ( str[0] == '-' && str[1] == '\0' ) {

      if ( access[0] == 'r' ) {
	*val = stdin;
      }
      else if ( access[0] == 'w' ) {
	*val = stdout;
      }
      else {
	ASSERT (0);
      }

      return TCL_OK;
    }
    else {
      FILE *fp;
      int fd;
      int flag = ui_get_tcl_fd (str, &fd);
      char *argtype;

      if ( flag ) {
	int dup_fd = dup (fd);

	fp = fdopen (dup_fd, access);

	argtype = "channel";
      }
      else {
	Tcl_DString buf;
	char *filename = Tcl_TranslateFileName (interp, str, &buf);
	fp = fopen (filename, access);

	Tcl_DStringFree (&buf);
	argtype = "file";
      }

      if ( fp != NULL ) {
	*val = fp;
	return TCL_OK;
      }

      {
	char *for_what = "";

	if ( access[0] == 'r' )
	  for_what = "for reading";
	else if ( access[0] == 'w' )
	  for_what = "for writing";
      
	error ("could not open %s \"%s\" %s.", argtype, str, for_what);
      }
    }
  }

  return TCL_ERROR;
}


static
int
ui_translate_channel_arg (Tcl_Interp *interp, Tcl_Obj *arg, char *access,
			  Tcl_Obj **val)
{
  int len;
  char *str = Tcl_GetStringFromObj (arg, &len);

  if ( str != NULL ) {
    if ( str[0] == '-' && str[1] == '\0' ) {

      if ( access[0] == 'r' ) {
	*val = Tcl_NewStringObj ("stdin", -1);
      }
      else if ( access[0] == 'w' ) {
	*val = Tcl_NewStringObj ("stdout", -1);
      }
      else {
	ASSERT (0);
      }

      return TCL_OK;
    }
    else {
      int mode;
      Tcl_Channel chan = Tcl_GetChannel (interp, str, &mode);

      if ( chan != NULL ) {
	if ( access[0] == 'r' && ((mode & TCL_READABLE) == 0) ) {
	  error ("channel \"%s\" is not open for reading.", str);
	}
	else if ( access[0] == 'w' && ((mode & TCL_WRITABLE) == 0) ) {
	  error ("channel \"%s\" is not open for writing.", str);
	}
	else {
	  *val = arg;
	  return TCL_OK;
	}
      }
      else {
	Tcl_Channel new_chan = Tcl_OpenFileChannel (interp, str, access, 0644);
	char *chan_name;

	if ( new_chan != NULL ) {
	  Tcl_RegisterChannel (interp, new_chan);

	  chan_name = Tcl_GetChannelName (new_chan);

	  *val = Tcl_NewStringObj (chan_name, -1);

	  return TCL_OK;
	}

	{
	  char *for_what = "";

	  if ( access[0] == 'r' )
	    for_what = "for reading";
	  else if ( access[0] == 'w' )
	    for_what = "for writing";
      
	  error ("could not open \"%s\" %s.", str, for_what);
	}
      }
    }
  }

  return TCL_ERROR;
}


static
nl_object
ui_translate_path (Tcl_Interp *interp, char *pattern, nl_kind kind,
		   nl_kind subkind, nl_context context, ar *path_p)
{
  nl_design design;
  ar result = ar_alloc (1, sizeof (nl_object));
  ar paths = ar_alloc (1, sizeof (ar));
  nl_object nl_obj;

  if ( kind != nl_kind_design &&
       kind != nl_kind_library &&
       kind != nl_kind_libcell &&
       kind != nl_kind_libpin ) {
    design = ui_get_current_design (context);
  }
  else {
    design = nl_context_current_design (context);
  }

  ui_find_path (interp, context, pattern, kind, subkind, design, 1, 0, 0,
		result, paths);

  {
    int size = ar_size (result);

    if ( size == 0 )
      nl_obj = NULL;
    else if ( size == 1 ) {
      ar_ref (result, 0, &nl_obj);
      if ( path_p != NULL ) {
	ar_ref (paths, 0, path_p);
      }
    }
    else {
      nl_obj = NULL;
    }
  }

  ar_free (result);

  ar_for_all_indexed (paths, ar, path, index) {
    if ( index > 0 ) {
      ar_free (path);
    }
  } ar_end_for;

  ar_free (paths);

  return nl_obj;
}


static
void
ui_wrong_arg_type_error (const char *expect, const char *got)
{
  error ("incorrect argument type, expected %s, got %s.", expect, got);
}


static
nl_kind
ui_object_to_iobject_kind (nl_kind kind)
{
  switch (kind) {
  case nl_kind_cell:
    return nl_kind_icell;
  case nl_kind_net:
    return nl_kind_inet;
  case nl_kind_pin:
    return nl_kind_ipin;
  case nl_kind_port:
    return nl_kind_iport;
  case nl_kind_design:
    return nl_kind_idesign;
  default:
    return nl_kind_null;
  }
}


static
nl_kind
ui_iobject_to_object_kind (nl_kind kind)
{
  switch (kind) {
  case nl_kind_icell:
    return nl_kind_cell;
  case nl_kind_inet:
    return nl_kind_net;
  case nl_kind_ipin:
    return nl_kind_pin;
  case nl_kind_iport:
    return nl_kind_port;
  case nl_kind_idesign:
    return nl_kind_design;
  default:
    return nl_kind_null;
  }
}


static
int
ui_translate_object_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			 nl_object *nl_obj_p, ar *path_p, nl_kind kind,
			 nl_kind subkind, int noerror)
{
  Tcl_ObjType *type = arg->typePtr;
  nl_object obj;

  if ( type == ui_nl_object_type &&
       (obj = ui_obj_get_nl_object (arg)) != NULL ) {
    nl_kind obj_kind = nl_object_kind (obj);

    if ( obj_kind == kind ) {
      ar path = ui_obj_get_nl_path (arg);

      *nl_obj_p = obj;

      if ( path_p != NULL ) {
	if ( path != NULL ) {
	  *path_p = ar_copy (path);
	}
	else {
	  *path_p = NULL;
	}
      }
      
      return TCL_OK;
    }
    else if ( obj_kind == ui_object_to_iobject_kind (kind) ) {
      switch ( obj_kind ) {
      case nl_kind_icell: {
	nl_icell icell = (nl_icell) obj;
	nl_cell cell = nl_icell_cell (icell);

	*nl_obj_p = (nl_object) cell;

	return TCL_OK;
      }
      case nl_kind_inet: {
	nl_inet inet = (nl_inet) obj;
	nl_net net = nl_inet_net (inet);

	*nl_obj_p = (nl_object) net;

	return TCL_OK;
      }
      case nl_kind_ipin: {
	nl_ipin ipin = (nl_ipin) obj;
	nl_pin pin = nl_ipin_pin (ipin);

	*nl_obj_p = (nl_object) pin;

	return TCL_OK;
      }
      case nl_kind_iport: {
	nl_iport iport = (nl_iport) obj;
	nl_port port = nl_iport_port (iport);

	*nl_obj_p = (nl_object) port;

	return TCL_OK;
      }
      case nl_kind_idesign: {
	nl_idesign idesign = (nl_idesign) obj;
	nl_design design = nl_idesign_design (idesign);

	*nl_obj_p = (nl_object) design;

	return TCL_OK;
      }
      default:
	ASSERT (0);
      }
    }
  }
  
  if ( type == ui_tcl_list_type ) {
    int length;
    int status = Tcl_ListObjLength (interp, arg, &length);

    if ( status != TCL_OK )
      return status;

    if ( length != 1 ) {
      ui_wrong_arg_type_error (nl_kind_to_string (kind), type->name);
    }
    else {
      Tcl_Obj *elt;
      int status = Tcl_ListObjIndex (interp, arg, 0, &elt);

      if ( status != TCL_OK )
	return status;

      status = ui_translate_object_arg (interp, elt, context, nl_obj_p, path_p,
					kind, subkind, noerror);
      return status;
    }
  }
  else {
    int len;
    char *str = Tcl_GetStringFromObj (arg, &len);
    nl_object object;

    if ( str == NULL ) {
      return TCL_ERROR;
    }

    object = ui_translate_path (interp, str, kind, subkind, context, path_p);

    if ( object == NULL ) {
      if ( ! noerror ) {
	error ("could not find a %s named '%s'",
	       nl_kind_to_string (kind), str);
      }
    }

    *nl_obj_p = object;

    return TCL_OK;
  }
}


static
int
ui_translate_object_or_iobject_arg (Tcl_Interp *interp, Tcl_Obj *arg,
				    nl_context context, nl_object *nl_obj_p,
				    ar *path_p, nl_kind kind, nl_kind ikind,
				    int noerror)
{
  Tcl_ObjType *type = arg->typePtr;

  if ( type == ui_nl_object_type ) {
    nl_object obj = ui_obj_get_nl_object (arg);

    if ( obj != NULL ) {
      nl_kind obj_kind = nl_object_kind (obj);

      if ( obj_kind == kind ) {
	ar path = ui_obj_get_nl_path (arg);

	*nl_obj_p = obj;

	if ( path_p != NULL ) {
	  if ( path != NULL ) {
	    *path_p = ar_copy (path);
	  }
	  else {
	    *path_p = NULL;
	  }
	}

	return TCL_OK;
      }
      else if ( obj_kind == ikind ) {
	*nl_obj_p = obj;

	if ( path_p != NULL ) {
	  *path_p = NULL;
	}

	return TCL_OK;
      }
    }
  }

  if ( type == ui_tcl_list_type ) {
    int length;
    int status = Tcl_ListObjLength (interp, arg, &length);

    if ( status != TCL_OK )
      return status;

    if ( length != 1 ) {
      ui_wrong_arg_type_error (nl_kind_to_string (kind), type->name);
    }
    else {
      Tcl_Obj *elt;
      int status = Tcl_ListObjIndex (interp, arg, 0, &elt);

      if ( status != TCL_OK )
	return status;

      status
	= ui_translate_object_or_iobject_arg (interp, elt, context, nl_obj_p,
					      path_p, kind, ikind, noerror);

      return status;
    }
  }
  else {
    int len;
    char *str = Tcl_GetStringFromObj (arg, &len);
    nl_object object;
    ar path = NULL;

    if ( str == NULL ) {
      return TCL_ERROR;
    }

    object = ui_translate_path (interp, str, kind, nl_kind_null, context, &path);

    if ( object == NULL && !noerror ) {
      error ("could not find a %s named '%s'",
	       nl_kind_to_string (kind), str);
    }

    if ( path != NULL && ar_size (path) > 0 ) {
      nl_idesign idesign = ui_get_idesign_for_path (path, context);
      nl_idesign_object iobject = nl_idesign_get_iobject (idesign, object);
	
      *nl_obj_p = (nl_object) iobject;
    }
    else {
      *nl_obj_p = object;
    }

    path = NULL;

    return TCL_OK;
  }
}


static
int
ui_translate_design_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			 nl_design *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_design, nl_kind_null, 0);
  return status;
}


static
int 
ui_translate_idesign_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  nl_idesign *val_p, ar *path_p)
{
  Tcl_ObjType *type = arg->typePtr;
  nl_object obj;

  if ( type == ui_nl_object_type &&
       (obj = ui_obj_get_nl_object (arg)) != NULL &&
       nl_object_kind (obj) == nl_kind_idesign ) {
    *val_p = (nl_idesign) obj;

    return TCL_OK;
  }
  else {
    nl_idesign current_idesign = ui_get_current_idesign (context);
    ar result = ar_alloc (1, sizeof (nl_icell));
    char *path = Tcl_GetStringFromObj (arg, NULL);
    int status = ui_find_iobject (interp, path, ui_hierarchy_separator,
				  nl_kind_idesign, current_idesign, 1, 0, 0,
				  result);
    int my_status;

    if ( status == TCL_OK ) {
      if ( ar_size (result) == 1 ) {
	ar_ref (result, 0, val_p);
	my_status = TCL_OK;
      }
      else {
	my_status = TCL_ERROR;
      }
    }
    else {
      my_status = status;
    }

    ar_free (result);

    return my_status;
  }
}
  

static
int 
ui_translate_pdesign_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  pnl_design *val_p, ar *path_p)
{
  nl_design design;
  int status = ui_translate_design_arg (interp, arg, context, &design, NULL);

  if ( status == TCL_OK ) {
    pnl_design pdesign = NULL;

    nl_design_attr_get_by_name ("pnl design", design, &pdesign);

    if ( pdesign == NULL ) {
      return TCL_ERROR;
    }
    else {
      *val_p = pdesign;
      return TCL_OK;
    }
  }
  else {
    return status;
  }
}
  

static
int
ui_translate_cell_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		       nl_cell *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_cell, nl_kind_null, 0);
  return status;
}
  

static
int
ui_translate_type_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		       nl_type *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_type, nl_kind_null, 0);
  return status;
}
  

static
int
ui_translate_cell_or_port_arg (Tcl_Interp *interp, Tcl_Obj *arg,
			       nl_context context,
			       nl_cell_or_port *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_cell, nl_kind_null, 1);

  if ( status == TCL_OK && *val_p != NULL )
    return TCL_OK;

  status = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
				    path_p, nl_kind_port, nl_kind_null, 1);

  if ( status == TCL_OK && *val_p != NULL )
    return TCL_OK;

  {
    char *str = Tcl_GetStringFromObj (arg, NULL);

    error ("could not find a cell or port named '%s'", str);
  }
}
  

static
int
ui_translate_cell_port_icell_or_iport_arg (Tcl_Interp *interp, Tcl_Obj *arg,
					   nl_context context,
					   nl_object *val_p, ar *path_p)
{
  int status
    = ui_translate_object_or_iobject_arg (interp, arg, context, val_p, path_p,
					  nl_kind_cell, nl_kind_icell, 1);

  if ( status == TCL_OK && *val_p != NULL )
    return TCL_OK;

  status = ui_translate_object_or_iobject_arg (interp, arg, context,
					       val_p, path_p,
					       nl_kind_port, nl_kind_iport, 1);

  if ( status == TCL_OK && *val_p != NULL )
    return TCL_OK;

  {
    char *str = Tcl_GetStringFromObj (arg, NULL);

    error ("could not find a cell or port named '%s'", str);
  }
}
  

static
int
ui_translate_net_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		      nl_net *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_net, nl_kind_null, 0);
  return status;
}


static
int 
ui_translate_bus_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		      nl_bus *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p, NULL,
			       nl_kind_bus, nl_kind_null, 0);

  return status;
}
  

static
int 
ui_translate_net_bus_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  nl_bus *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p, NULL,
			       nl_kind_bus, nl_kind_net, 0);

  return status;
}
  

static
int 
ui_translate_port_bus_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			   nl_bus *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p, NULL,
			       nl_kind_bus, nl_kind_port, 0);

  return status;
}
  

static
int 
ui_translate_cell_bus_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			   nl_bus *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p, NULL,
			       nl_kind_bus, nl_kind_cell, 0);

  return status;
}
  

static
int
ui_translate_net_or_inet_arg (Tcl_Interp *interp, Tcl_Obj *arg,
			      nl_context context, nl_object *val_p, ar *path_p)
{
  int status
    = ui_translate_object_or_iobject_arg (interp, arg, context, val_p, path_p,
					  nl_kind_net, nl_kind_inet, 0);
  return status;
}
  

static
int
ui_translate_cell_or_icell_arg (Tcl_Interp *interp, Tcl_Obj *arg,
				nl_context context, nl_object *val_p,
				ar *path_p)
{
  int status
    = ui_translate_object_or_iobject_arg (interp, arg, context, val_p, path_p,
					  nl_kind_cell, nl_kind_icell, 0);
  return status;
}
  

static
int
ui_translate_port_or_iport_arg (Tcl_Interp *interp, Tcl_Obj *arg,
				nl_context context, nl_object *val_p,
				ar *path_p)
{
  int status
    = ui_translate_object_or_iobject_arg (interp, arg, context, val_p, path_p,
					  nl_kind_port, nl_kind_iport, 0);
  return status;
}
  

static
int
ui_translate_pin_or_ipin_arg (Tcl_Interp *interp, Tcl_Obj *arg,
			      nl_context context, nl_object *val_p, ar *path_p)
{
  int status
    = ui_translate_object_or_iobject_arg (interp, arg, context, val_p, path_p,
					  nl_kind_pin, nl_kind_ipin, 0);
  return status;
}
  

static
int
ui_translate_port_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		       nl_port *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_port, nl_kind_null, 0);
  return status;
}
  

static
int
ui_translate_reference_arg (Tcl_Interp *interp, Tcl_Obj *arg,
			    nl_context context,
			    nl_reference *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_reference, nl_kind_null, 0);
  return status;
}


static
int
ui_translate_pin_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		      nl_pin *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_pin, nl_kind_null, 0);
  return status;
}


static
int
ui_translate_library_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  nl_library *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       NULL, nl_kind_library, nl_kind_null, 0);

  return status;
}


static
int
ui_translate_libcell_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  nl_libcell *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       NULL, nl_kind_libcell, nl_kind_null, 0);

  return status;
}


static
int
ui_translate_libpin_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  nl_libpin *val_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       NULL, nl_kind_libpin, nl_kind_null, 0);

  return status;
}


static
int
ui_translate_refpin_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			 nl_refpin *val_p, ar *path_p)
{
  int status
    = ui_translate_object_arg (interp, arg, context, (nl_object *) val_p,
			       path_p, nl_kind_refpin, nl_kind_null, 0);
  return status;
}


static
int
ui_translate_iobject_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			  nl_kind kind, nl_idesign_object *val_p)
{
  Tcl_ObjType *type = arg->typePtr;
  nl_object obj;

  if ( type == ui_nl_object_type &&
       (obj = ui_obj_get_nl_object (arg)) != NULL ) {
    int obj_kind = nl_object_kind (obj);

    if ( obj_kind == kind ) {
      *val_p = (nl_idesign_object) obj;

      return TCL_OK;
    }
    else if ( obj_kind == ui_iobject_to_object_kind (kind) ) {
      nl_idesign idesign = ui_get_current_idesign (context);

      switch ( obj_kind ) {
      case nl_kind_cell: {
	nl_cell cell = (nl_cell) obj;
	*val_p = (nl_idesign_object) nl_idesign_get_icell (idesign, cell);
	return TCL_OK;
      }
      case nl_kind_port: {
	nl_port port = (nl_port) obj;
	*val_p = (nl_idesign_object) nl_idesign_get_iport (idesign, port);
	return TCL_OK;
      }
      case nl_kind_net: {
	nl_net net = (nl_net) obj;
	*val_p = (nl_idesign_object) nl_idesign_get_inet (idesign, net);
	return TCL_OK;
      }
      case nl_kind_pin: {
	nl_pin pin = (nl_pin) obj;
	*val_p = (nl_idesign_object) nl_idesign_get_ipin (idesign, pin);
	return TCL_OK;
      }
      default:
	ASSERT (0);
      }
    }
  }

  {
    nl_idesign current_idesign = ui_get_current_idesign (context);
    ar result = ar_alloc (1, sizeof (nl_idesign_object));
    volatile int my_status = TCL_ERROR;
  
    error_unwind_protect {
      int len;
      char *path = Tcl_GetStringFromObj (arg, &len);
      int status = ui_find_iobject (interp, path, ui_hierarchy_separator,
				    kind, current_idesign, 1, 0, 0,
				    result);
      if ( status == TCL_OK ) {
	if ( ar_size (result) == 1 ) {
	  ar_ref (result, 0, val_p);
	  my_status = TCL_OK;
	}
	else {
	  my_status = TCL_ERROR;
	}
      }
      else {
	my_status = status;
      }
    }
    error_on_exit {
      ar_free (result);
    }
    error_end;

    return my_status;
  }
}

  
static
int
ui_translate_icell_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			nl_icell *val_p)
{
  int status = ui_translate_iobject_arg (interp, arg, context, nl_kind_icell,
					 (nl_idesign_object *) val_p);

  return status;
}


static
int
ui_translate_ipin_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		       nl_ipin *val_p)
{
  int status = ui_translate_iobject_arg (interp, arg, context, nl_kind_ipin,
					 (nl_idesign_object *) val_p);

  return status;
}


static
int
ui_translate_inet_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			nl_inet *val_p)
{
  int status = ui_translate_iobject_arg (interp, arg, context, nl_kind_inet,
					 (nl_idesign_object *) val_p);

  return status;
}


static
int
ui_translate_iport_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
			nl_iport *val_p)
{
  int status = ui_translate_iobject_arg (interp, arg, context, nl_kind_iport,
					 (nl_idesign_object *) val_p);

  return status;
}


static
int
ui_translate_attr_arg (Tcl_Interp *interp, Tcl_Obj *arg, nl_context context,
		       nl_attr *attr_p, nl_kind attr_of)
{
  Tcl_ObjType *type = arg->typePtr;
  nl_object obj;
  nl_attr attr;

  if ( type == ui_nl_object_type &&
       (obj = ui_obj_get_nl_object (arg)) != NULL ) {
    nl_kind obj_kind = nl_object_kind (obj);

    if ( obj_kind == nl_kind_attr ) {
      attr = (nl_attr) obj;
    }
    else {
      ui_wrong_arg_type_error ("attr", nl_kind_to_string (obj_kind));
    }
  }
  else if ( type == ui_tcl_list_type ) {
    int length;
    int status = Tcl_ListObjLength (interp, arg, &length);

    if ( status != TCL_OK ) {
      return status;
    }

    if ( length != 1 ) {
      ui_wrong_arg_type_error ("attr", type->name);
    }
    else {
      Tcl_Obj *elt;
      int status = Tcl_ListObjIndex (interp, arg, 0, &elt);

      if ( status != TCL_OK ) {
	return status;
      }

      status = ui_translate_attr_arg (interp, elt, context, attr_p, attr_of);

      return status;
    }
  }
  else {
    char *name = Tcl_GetStringFromObj (arg, NULL);
    nl_design design = ui_get_current_design (context);

    attr = nl_design_get_attr_by_name (design, name);

    if ( attr == NULL ) {
      error ("design %s does not contain an attribute named %s",
	     nl_design_name (design), name);
    }
  }

  if ( attr_of != nl_kind_null ) {
    nl_kind arg_attr_of = nl_attr_attr_of (attr);

    if ( arg_attr_of != attr_of ) {
      error ("attribute %s is a %s attribute, expected %s attribute",
	     nl_attr_name (attr), nl_kind_to_string (arg_attr_of),
	     nl_kind_to_string (attr_of));
    }
  }

  *attr_p = attr;
  return TCL_OK;
}


static
int
ui_translate_cell_list_arg (Tcl_Obj *arg, nl_context context,
			    Tcl_Interp *interp, ar *val_p)
{
  int num_elts;
  Tcl_Obj **elts;
  int status = Tcl_ListObjGetElements (interp, arg, &num_elts, &elts);
  int i;
  ar result;

  if ( status != TCL_OK )
    return status;

  result = ar_alloc (num_elts, sizeof (nl_cell));

  for ( i = 0; i < num_elts; i++ ) {
    nl_cell cell;
    int status = ui_translate_cell_arg (interp, elts[i], context, &cell, NULL);

    if ( status != TCL_OK ) {
      ar_free (result);
      return status;
    }

    ar_add (result, &cell);
  }

  *val_p = result;

  return TCL_OK;
}


static
int
ui_translate_icell_list_arg (Tcl_Obj *arg, nl_context context,
			    Tcl_Interp *interp, ar *val_p)
{
  int num_elts;
  Tcl_Obj **elts;
  int status = Tcl_ListObjGetElements (interp, arg, &num_elts, &elts);
  int i;
  ar result;

  if ( status != TCL_OK )
    return status;

  result = ar_alloc (num_elts, sizeof (nl_icell));

  for ( i = 0; i < num_elts; i++ ) {
    nl_icell icell;
    int status = ui_translate_icell_arg (interp, elts[i], context, &icell);

    if ( status != TCL_OK ) {
      ar_free (result);
      return status;
    }

    ar_add (result, &icell);
  }

  *val_p = result;

  return TCL_OK;
}


static
int
ui_translate_string_list_arg (Tcl_Obj *arg, nl_context context,
			      Tcl_Interp *interp, ar *val_p)
{
  int num_elts;
  Tcl_Obj **elts;
  int status = Tcl_ListObjGetElements (interp, arg, &num_elts, &elts);
  int i;
  ar result;

  if ( status != TCL_OK )
    return status;

  result = ar_alloc (num_elts, sizeof (char *));

  for ( i = 0; i < num_elts; i++ ) {
    char *string;
    int status = ui_translate_string_arg (elts[i], &string);

    if ( status != TCL_OK ) {
      ar_free (result);
      return status;
    }

    ar_add (result, &string);
  }

  *val_p = result;

  return TCL_OK;
}


static
int
ui_translate_integer_list_arg (Tcl_Obj *arg, nl_context context,
			       Tcl_Interp *interp, ar *val_p)
{
  int num_elts;
  Tcl_Obj **elts;
  int status = Tcl_ListObjGetElements (interp, arg, &num_elts, &elts);
  int i;
  ar result;

  if ( status != TCL_OK )
    return status;

  result = ar_alloc (num_elts, sizeof (int));

  for ( i = 0; i < num_elts; i++ ) {
    int integer;
    int status = ui_translate_integer_arg (elts[i], &integer);

    if ( status != TCL_OK ) {
      ar_free (result);
      return status;
    }

    ar_add (result, &integer);
  }

  *val_p = result;

  return TCL_OK;
}


static
int
ui_translate_argument (Tcl_Interp *interp, nl_context context, Tcl_Obj *arg,
		       enum ui_arg_type type, void *val, ar *path_val)
{
  int ok;

  switch ( type ) {

  case ui_tcl_object:
    *((Tcl_Obj **)val) = arg;
    ok = TCL_OK;
    break;

  case ui_integer:
    ok = ui_translate_integer_arg (arg, (int *) val);
    break;

  case ui_string:
    ok = ui_translate_string_arg (arg, (char **) val);
    break;

  case ui_double:
    ok = ui_translate_double_arg (arg, (double *) val);
    break;

  case ui_design:
  case ui_current_design:
    ok = ui_translate_design_arg (interp, arg, context,
				  (nl_design *) val, path_val);
    break;

  case ui_idesign:
  case ui_current_idesign:
    ok = ui_translate_idesign_arg (interp, arg, context,
				   (nl_idesign *) val, path_val);
    break;

  case ui_pdesign:
  case ui_current_pdesign:
    ok = ui_translate_pdesign_arg (interp, arg, context,
				   (pnl_design *) val, path_val);
    break;

  case ui_cell:
    ok = ui_translate_cell_arg (interp, arg, context,
				(nl_cell *) val, path_val);
    break;

  case ui_cell_or_port:
    ok = ui_translate_cell_or_port_arg (interp, arg, context,
					(nl_cell_or_port *) val, path_val);
    break;

  case ui_cell_port_icell_or_iport:
    ok = ui_translate_cell_port_icell_or_iport_arg (interp, arg, context,
					(nl_object *) val, path_val);
    break;

  case ui_net:
    ok = ui_translate_net_arg (interp, arg, context, (nl_net *) val, path_val);
    break;

  case ui_net_or_inet:
    ok = ui_translate_net_or_inet_arg (interp, arg, context,
				       (nl_object *) val, path_val);
    break;

  case ui_cell_or_icell:
    ok = ui_translate_cell_or_icell_arg (interp, arg, context,
					 (nl_object *) val, path_val);
    break;

  case ui_port_or_iport:
    ok = ui_translate_port_or_iport_arg (interp, arg, context,
					 (nl_object *) val, path_val);
    break;

  case ui_pin_or_ipin:
    ok = ui_translate_pin_or_ipin_arg (interp, arg, context,
				       (nl_object *) val, path_val);
    break;

  case ui_reference:
    ok = ui_translate_reference_arg (interp, arg, context,
				     (nl_reference *) val, path_val);
    break;

  case ui_port:
    ok = ui_translate_port_arg (interp, arg, context,
				(nl_port *) val, path_val);
    break;

  case ui_pin:
    ok = ui_translate_pin_arg (interp, arg, context,
			       (nl_pin *) val, path_val);
    break;

  case ui_refpin:
    ok = ui_translate_refpin_arg (interp, arg, context,
				  (nl_refpin *) val, path_val);
    break;

  case ui_attr:
    ok = ui_translate_attr_arg (interp, arg, context, (nl_attr *) val,
				nl_kind_null);
    break;

  case ui_cell_attr:
    ok = ui_translate_attr_arg (interp, arg, context, (nl_attr *) val,
				nl_kind_cell);
    break;

  case ui_net_attr:
    ok = ui_translate_attr_arg (interp, arg, context, (nl_attr *) val,
				nl_kind_net);
    break;

  case ui_port_attr:
    ok = ui_translate_attr_arg (interp, arg, context, (nl_attr *) val,
				nl_kind_port);
    break;

  case ui_design_attr:
    ok = ui_translate_attr_arg (interp, arg, context, (nl_attr *) val,
				nl_kind_design);
    break;

  case ui_type:
    ok = ui_translate_type_arg (interp, arg, context,
				(nl_type *) val, path_val);
    break;

  case ui_icell:
    ok = ui_translate_icell_arg (interp, arg, context, (nl_icell *) val);
    break;

  case ui_inet:
    ok = ui_translate_inet_arg (interp, arg, context, (nl_inet *) val);
    break;

  case ui_iport:
    ok = ui_translate_iport_arg (interp, arg, context, (nl_iport *) val);
    break;

  case ui_ipin:
    ok = ui_translate_ipin_arg (interp, arg, context, (nl_ipin *) val);
    break;

  case ui_writable_file:
    ok = ui_translate_file_arg (interp, arg, "w", (FILE **) val);
    break;

  case ui_readable_file:
    ok = ui_translate_file_arg (interp, arg, "r", (FILE **) val);
    break;

  case ui_writable_channel:
    ok = ui_translate_channel_arg (interp, arg, "w", (Tcl_Obj **) val);
    break;

  case ui_readable_channel:
    ok = ui_translate_channel_arg (interp, arg, "r", (Tcl_Obj **) val);
    break;

  case ui_cell_list:
    ok = ui_translate_cell_list_arg (arg, context, interp, (ar *) val);
    break;

  case ui_icell_list:
    ok = ui_translate_icell_list_arg (arg, context, interp, (ar *) val);
    break;

  case ui_string_list:
    ok = ui_translate_string_list_arg (arg, context, interp, (ar *) val);
    break;

  case ui_integer_list:
    ok = ui_translate_integer_list_arg (arg, context, interp, (ar *) val);
    break;

  case ui_bus:
    ok = ui_translate_bus_arg (interp, arg, context, (nl_bus *) val);
    break;

  case ui_net_bus:
    ok = ui_translate_net_bus_arg (interp, arg, context, (nl_bus *) val);
    break;

  case ui_cell_bus:
    ok = ui_translate_cell_bus_arg (interp, arg, context, (nl_bus *) val);
    break;

  case ui_port_bus:
    ok = ui_translate_port_bus_arg (interp, arg, context, (nl_bus *) val);
    break;

  case ui_library:
    ok = ui_translate_library_arg (interp, arg, context, (nl_library *) val);
    break;

  case ui_libcell:
    ok = ui_translate_libcell_arg (interp, arg, context, (nl_libcell *) val);
    break;

  case ui_libpin:
    ok = ui_translate_libpin_arg (interp, arg, context, (nl_libpin *) val);
    break;

  default:
    ASSERT (0);
  }

  return ok;
}
  

static
char *
ui_opt_type_string (enum ui_arg_type type)
{
  switch ( type ) {
  case ui_boolean:        return "boolean";
  case ui_integer:        return "integer";
  case ui_string:         return "string";
  case ui_readable_file:
  case ui_writable_file:  return "file";
  case ui_readable_channel:
  case ui_writable_channel: return "file";
  case ui_design:
  case ui_current_design: return "design";
  case ui_port:           return "port";
  case ui_cell:           return "cell";
  case ui_net:            return "net";
  case ui_reference:      return "reference";
  case ui_pin:            return "pin";
  case ui_refpin:         return "refpin";
  case ui_idesign:        return "idesign";
  case ui_current_idesign:return "idesign";
  case ui_icell:          return "icell";
  case ui_inet:           return "inet";
  case ui_iport:          return "iport";
  case ui_ipin:           return "ipin";
  case ui_cell_list:      return "cell_list";
  case ui_icell_list:     return "icell_list";
  case ui_string_list:    return "string_list";
  case ui_integer_list:   return "integer_list";
  case ui_tcl_object:     return "object";
  case ui_attr:	          return "attribute";
  case ui_cell_attr:      return "cell_attribute";
  case ui_net_attr:       return "net_attribute";
  case ui_port_attr:      return "port_attribute";
  case ui_reference_attr: return "reference_attribute";
  case ui_design_attr:    return "design_attribute";
  case ui_pin_attr:       return "pin_attribute";
  case ui_idesign_attr:   return "idesign_attribute";
  case ui_icell_attr:     return "icell_attribute";
  case ui_inet_attr:      return "inet_attribute";
  case ui_iport_attr:     return "iport_attribute";
  case ui_ipin_attr:      return "ipin_attribute";
  case ui_pdesign:        return "pdesign";
  case ui_current_pdesign:return "pdesign";
  case ui_pcell:          return "pcell";
  case ui_pport:          return "pport";
  case ui_cell_port_icell_or_iport:
  case ui_cell_or_port:   return "cell_or_port";
  case ui_net_or_inet:    return "inet";
  case ui_cell_or_icell:  return "icell";
  case ui_port_or_iport:  return "iport";
  case ui_pin_or_ipin:    return "ipin";
  case ui_type:           return "type";
  case ui_bus:            return "bus";
  case ui_net_bus:        return "net_bus";
  case ui_cell_bus:       return "cell_bus";
  case ui_port_bus:       return "port_bus";
  case ui_library:        return "library";
  case ui_libcell:        return "libcell";
  case ui_libpin:         return "libpin";
  case ui_double:         return "double";
  default:
    ASSERT (0);
  }
}


static
char *
ui_usage_string (Tcl_Obj *cmd, struct ui_option *opts,
		 struct ui_argument *args)
{
  int i;
  int len;
  char *str = Tcl_GetStringFromObj (cmd, &len);
  str_buf buf = str_concat_begin ();

  str_concat (buf, "Usage: ", str, NULL);

  for ( i = 0; opts[i].name != NULL; i++ ) {
    if ( opts[i].doc != NULL ) {
      if ( opts[i].type == ui_boolean ) {
	str_concat (buf, " [", opts[i].name, "]", NULL);
      }
      else {
	char *type_string = ui_opt_type_string (opts[i].type);
	str_concat (buf, " [", opts[i].name, " <", type_string, ">]", NULL);
		 
      }
    }
  }

  for ( i = 0; args[i].variable != NULL; i++ ) {
    if ( args[i].doc != NULL ) {
      str_concat (buf, " ", NULL);

      if ( args[i].requirement == ui_optional )
	str_concat (buf, "[", NULL);

      str_concat (buf, "<", ui_opt_type_string (args[i].type), ">", NULL);

      if ( args[i].requirement == ui_optional )
	str_concat (buf, "]", NULL);
    }
  }

  {
    char *result = str_concat_end (buf);

    return result;
  }
}


static
void
ui_usage_error (Tcl_Obj *cmd, struct ui_option *opts, struct ui_argument *args,
		char *problem)
{
  char *usage = ui_usage_string (cmd, opts, args);

  error ("%s\n%s", problem, usage);
}


static
void
ui_return_help (Tcl_Interp *interp, Tcl_Obj *cmd, char *doc,
		struct ui_option *opts, struct ui_argument *args)
{
  int i;
  char buf[256];
  int print_options = 0;
  int print_arguments = 0;
  char *usage = ui_usage_string (cmd, opts, args);

  Tcl_AppendResult (interp, "\n", doc, "\n\n", usage, "\n", NULL);
  FREE (usage);

  for ( i = 0; opts[i].name != NULL; i++ ) {
    if ( opts[i].doc != NULL ) {
      print_options = 1;
      break;
    }
  }

  if ( print_options ) {
    Tcl_AppendResult (interp,
		      "\n    option              description\n\n", NULL);

    for ( i = 0; opts[i].name != NULL; i++ ) {
      if ( opts[i].doc != NULL ) {
	if ( opts[i].type == ui_boolean ) {
	  sprintf (buf, "    %s", opts[i].name);
	}
	else {
	  sprintf (buf, "    %s <%s>", opts[i].name,
		   ui_opt_type_string (opts[i].type));
	}

	{
	  int j;
	  int len = strlen (buf);

	  Tcl_AppendResult (interp, buf, NULL);

	  for ( j = len; j < 24; j++ )
	    Tcl_AppendResult (interp, " ", NULL);

	  Tcl_AppendResult (interp, opts[i].doc, "\n", NULL);
	}
      }
    }
  }

  for ( i = 0; args[i].variable != NULL; i++ ) {
    if ( args[i].doc != NULL ) {
      print_arguments = 1;
      break;
    }
  }

  if ( print_arguments ) {
    Tcl_AppendResult (interp,
		      "\n    argument            description\n\n", NULL);

    for ( i = 0; args[i].variable != NULL; i++ ) {
      if ( args[i].doc != NULL ) {
	Tcl_AppendResult (interp, " ", NULL);

	sprintf (buf, "    <%s>", ui_opt_type_string (args[i].type));

	{
	  int j;
	  int len = strlen (buf);

	  Tcl_AppendResult (interp, buf, NULL);

	  for ( j = len; j < 24; j++ )
	    Tcl_AppendResult (interp, " ", NULL);

	  Tcl_AppendResult (interp, args[i].doc, "\n", NULL);
	}
      }
    }
  }
}


int
ui_getopt (nl_context context, struct ui_option *options, 
	   char **switch_table, struct ui_argument *arguments,
	   char *doc, Tcl_Interp *interp, int argc, Tcl_Obj *CONST argv[])
{
  mem_group prev_group;

  if ( ui_tcl_list_type == NULL ) {
    ui_getopt_init ();
  }

  mem_group_free_contents (ui_getopt_mem_group);

  prev_group = mem_group_set (ui_getopt_mem_group);

  error_unwind_protect {
    int index = 1;

    while ( index < argc ) {
      int len;
      char *str;
      int flag;
      int offset;

      if ( argv[index]->typePtr == ui_nl_object_type ) {
	break;
      }
	
      str = Tcl_GetStringFromObj (argv[index], &len);

      if ( str[0] != '-' ) {
	break;
      }

      if ( str[1] == '\0' ) {
	index++;
	continue;
      }
	
      if ( str[1] == '-' && str[2] == '\0' ) {
	index++;
	break;
      }

      flag = Tcl_GetIndexFromObj (NULL, argv[index], switch_table, NULL, 0,
				  &offset);

      if ( flag != TCL_OK ) {
	char *usage = ui_usage_string (argv[0], options, arguments);
	error ("unrecognized option \"%s\"\n%s", str, usage);
      }

      if ( options[offset].type == ui_boolean ) {
	*(int *)options[offset].variable = 1;
      }
      else if ( options[offset].type == ui_help ) {
	ui_return_help (interp, argv[0], doc, options, arguments);
	mem_group_set (prev_group);
	return TCL_RETURN;
      }
      else {
	int status;

	index++;
	status
	  = ui_translate_argument (interp, context, argv[index],
				   options[offset].type,
				   options[offset].variable, NULL);

	if ( status != TCL_OK ) {
	  char *usage = ui_usage_string (argv[0], options, arguments);
	  error ("processing argument %d\n%s", index, usage);
	}
      }

      index++;
    }

    {
      int i = 0;

      for ( i = 0; arguments[i].type != ui_null; i++ ) {
	if ( index + i >= argc ) {
	  if ( arguments[i].requirement == ui_optional ) {
	    /* Check to make sure that the rest of them are optional. */
	    for ( ; arguments[i].type != ui_null; i++ ) {
	      if ( arguments[i].requirement != ui_optional ) {
		ASSERT (0);
	      }
	      else if ( arguments[i].type == ui_current_design ) {
		nl_design current_design = ui_get_current_design (context);

		*(nl_design *) arguments[i].variable = current_design;
	      }
	      else if ( arguments[i].type == ui_current_idesign ) {
		nl_design current_design = ui_get_current_design (context);
		int num_idesigns;
		nl_idesign idesign;
	      
		num_idesigns = nl_design_num_idesigns (current_design);

		if ( num_idesigns == 0 ) {
		  error ("there are no instance designs (idesigns) "
			 "for the current_design.");
		}
		else if ( num_idesigns > 1 ) {
		  error ("the current_design has more than one instance "
			 "design (idesign).");
		  return TCL_ERROR;
		}

		idesign = nl_design_first_idesign (current_design);
		*(nl_idesign *) arguments[i].variable = idesign;
	      }
	      else if ( arguments[i].type == ui_current_pdesign ) {
		nl_design design = ui_get_current_design (context);
		pnl_design pdesign;

		nl_design_attr_get_by_name ("pnl design", design, &pdesign);

		*(pnl_design *) arguments[i].variable = pdesign;
	      }
	    }
	    break;
	  }
	  else {
	    char buf[4];
	    char *ord[] = { "st", "nd", "rd" };
	    char *problem;

	    mem_group_set (prev_group);

	    sprintf (buf, "%d%s", i+1, (i > 2) ? "th" : ord[i]);
	    problem = str_append ("required ", buf, " argument not supplied",
				  NULL);
	    ui_usage_error (argv[0], options, arguments, problem);
	  }
	}
	else {
	  int status;

	  status = ui_translate_argument (interp, context, argv[index+i],
					  arguments[i].type,
					  arguments[i].variable,
					  arguments[i].path_variable);

	  if ( status != TCL_OK ) {
	    char *problem;

	    mem_group_set (prev_group);

	    problem
	      = str_append ("could not convert ",
			    Tcl_GetStringFromObj (argv[index+i], NULL), " to ",
			    ui_opt_type_string (arguments[i].type), NULL);

	    ui_usage_error (argv[0], options, arguments, problem);
	  }
	}
      }

      if ( index + i < argc ) {
	mem_group_set (prev_group);

	ui_usage_error (argv[0], options, arguments,
			"too many arguments specified");
      }
    }
  }
  error_on_exit {
    mem_group_set (prev_group);
  } error_end;

  return TCL_OK;
}

  
char *
ui_update_current_design (ClientData data, Tcl_Interp *interp, char *name1,
			  char *name2, int flags)
{
  nl_context context = (nl_context) data;

  if ( flags & TCL_TRACE_UNSETS ) {
    nl_context_set_current_design (context, NULL);

    return NULL;
  }
  else if ( flags & TCL_TRACE_WRITES ) {
    Tcl_Obj *name1_obj = Tcl_NewStringObj (name1, -1);
    Tcl_Obj *nl_cur_des_obj = Tcl_NewStringObj ("nl_current_design", -1);
    Tcl_Obj *val = Tcl_ObjGetVar2 (interp, name1_obj, NULL, TCL_GLOBAL_ONLY);
    nl_design design;
    ar path = NULL;
    volatile int status;

    error_catch {
      status = ui_translate_design_arg (interp, val, context, &design,
					&path);
    }
    error_on_error {
      if ( path != NULL ) {
	ar_free (path);
      }

      return error_message;
    }
    error_end;

    if ( path != NULL ) {
      ar_free (path);
    }

    if ( status == TCL_OK ) {
      Tcl_Obj *design_obj = ui_obj_create ((nl_object) design, NULL);

      nl_context_set_current_design (context, design);
      Tcl_ObjSetVar2 (interp, nl_cur_des_obj, NULL, design_obj, TCL_GLOBAL_ONLY);

      return NULL;
    }
    else {
      static char buf[256];
      char *str = Tcl_GetStringFromObj (val, NULL);
      sprintf (buf, "can't set current_design to %s, no such design.", str);

      return buf;
    }
  }
  else if ( flags & TCL_TRACE_READS ) {
    nl_design design = nl_context_current_design (context);
    Tcl_Obj *name1_obj = Tcl_NewStringObj (name1, -1);
    Tcl_Obj *val = Tcl_ObjGetVar2 (interp, name1_obj, NULL, TCL_GLOBAL_ONLY);

    if ( val == NULL && design == NULL ) {
      return NULL;
    }
    else if ( val != NULL && (nl_design) ui_obj_get_nl_object (val) == design ) {
      return NULL;
    }
    else if ( val != NULL && design == NULL ) {
      Tcl_UnsetVar2 (interp, name1, NULL, TCL_GLOBAL_ONLY);
      return NULL;
    }
    else {
      Tcl_Obj *design_obj = ui_obj_create ((nl_object) design, NULL);

      Tcl_ObjSetVar2 (interp, name1_obj, NULL, design_obj, TCL_GLOBAL_ONLY);

      return NULL;
    }
  }
  else {
    return NULL;
  }
}
