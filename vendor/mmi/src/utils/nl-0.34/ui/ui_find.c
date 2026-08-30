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

#include "port.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "str.h"
#include "nl.h"
#include "tcl.h"
#include "ui.h"
#include "ui_int.h"



static
int
ui_is_glob (char *str)
{
  char *s = str;

  while ( *s ) {
    if ( *s == '*' || *s == '?' || *s == '[' ) {
      return 1;
    }
    else if ( *s == '\\' ) {
      s++;
      if ( *s == 0 )
	return 0;
    }

    s++;
  }

  return 0;
}


static
int
ui_is_regexp (char *str)
{
  char *s = str;

  while ( *s ) {
    switch ( *s ) {
    case '|':
    case '*':
    case '+':
    case '?':
    case '(':
    case '[':
    case '.':
    case '^':
    case '$':
      return 1;
    case '\\':
      s++;
      if ( *s == 0 )
	return 0;
      break;
    }
    s++;
  }

  return 0;
}


static
void
ui_unescape_glob (char *str)
{
  char *s = str;
  char *t = str;

  while ( *s ) {
    if ( *s == '\\' ) {
      switch ( s[1] ) {
      case '*':
      case '?':
      case '[':
      case ']':
	*t = s[1];
	t++;
	s++;
	break;

      default:
	*t = *s;
	t++;
	break;
      }
    }
    else {
      *t = *s;
      t++;
    }
    
    s++;
  }

  *t = 0;
}


static
void
ui_unescape_regexp (char *str)
{
  char *s = str;
  char *t = str;

  while ( *s ) {
    if ( *s == '\\' ) {
      switch ( s[1] ) {
      case '|':
      case '*':
      case '+':
      case '?':
      case '(':
      case '[':
      case ']':
      case '.':
      case '^':
      case '$':
	*t = s[1];
	t++;
	s++;
	break;

      default:
	*t = *s;
	t++;
	break;
      }
    }
    else {
      *t = *s;
      t++;
    }
    
    s++;
  }

  *t = 0;
}


static
int
ui_find_objects_in_dll (Tcl_Interp *interp, char *pattern, ui_find_mode mode,
			nl_dll_head dll, ar path, ar result, ar paths)
{
  Tcl_RegExp tcl_regexp = NULL;

  ASSERT (mode == ui_find_mode_glob ||
	  mode == ui_find_mode_regexp ||
	  mode == ui_find_mode_subregexp);

  if ( mode == ui_find_mode_regexp || mode == ui_find_mode_subregexp ) {
    tcl_regexp = Tcl_RegExpCompile (interp, pattern);

    if ( tcl_regexp == NULL ) {
      return TCL_ERROR;
    }
  }

  nl_dll_for_all (dll, nl_named_object, obj) {
    char *name = nl_named_object_name (obj);
    int flag;

    if ( mode == ui_find_mode_glob ) {
      flag = Tcl_StringMatch (name, pattern);
    }
    else if ( mode == ui_find_mode_regexp ||
	      mode == ui_find_mode_subregexp ) {
      ASSERT (tcl_regexp != NULL);
      flag = Tcl_RegExpExec (interp, tcl_regexp, name, name);

      if ( mode == ui_find_mode_regexp ) {
	char *start;
	char *end;
	
	Tcl_RegExpRange (tcl_regexp, 0, &start, &end);

	flag = (start == name) && (*end == '\0');
      }
    }
    else {
      ASSERT (0);
    }

    if ( flag == 1 ) {
      ar_add (result, &obj);

      if ( paths != NULL ) {
	ar obj_path;

	if ( path == NULL )
	  obj_path = ar_alloc (0, sizeof (nl_object));
	else 
	  obj_path = ar_copy (path);
	
	ar_add (paths, &obj_path);
      }
    }
    else if ( flag == -1 ) {
      return TCL_ERROR;
    }
  } nl_end_for;

  return TCL_OK;
}


static
int
ui_find_objects_in_context (Tcl_Interp *interp, nl_context context,
			    nl_kind kind, char *pattern, ui_find_mode mode,
			    ar path, ar result, ar paths)
{
  nl_dll_head dll;
  int status;

  switch ( kind ) {
  case nl_kind_design:
    dll = nl_context_designs (context);
    break;
  case nl_kind_library:
    dll = nl_context_libraries (context);
    break;
  default:
    ASSERT (0);
  }

  status = ui_find_objects_in_dll (interp, pattern, mode, dll, path, result,
				   paths);

  return status;
}


static
int
ui_find_objects_in_design (Tcl_Interp *interp, nl_design design, nl_kind kind,
			   nl_kind subkind, char *pattern, ui_find_mode mode,
			   ar path, ar result, ar paths)
{
  nl_dll_head dll;
  int status;

  switch ( kind ) {
  case nl_kind_cell:
    dll = nl_design_cells (design);
    break;
  case nl_kind_port:
    dll = nl_design_ports (design);
    break;
  case nl_kind_net:
    dll = nl_design_nets (design);
    break;
  case nl_kind_reference:
    dll = nl_design_references (design);
    break;
  case nl_kind_attr:
    dll = nl_design_attrs (design);
    break;
  case nl_kind_type:
    dll = nl_design_types (design);
    break;
  case nl_kind_bus:
    switch (subkind) {
    case nl_kind_port:
      dll = nl_design_port_buses (design);
      break;
    case nl_kind_net:
      dll = nl_design_net_buses (design);
      break;
    case nl_kind_cell:
      dll = nl_design_cell_buses (design);
      break;
    default:
      ASSERT (0);
    }
    break;
  default:
    ASSERT (0);
  }

  status = ui_find_objects_in_dll (interp, pattern, mode, dll, path, result,
				   paths);

  return status;
}


static
int
ui_find_object_in_context (nl_context context, nl_kind kind, char *name,
			   ar path, ar result, ar paths)
{
  nl_object object;

  switch (kind) {
  case nl_kind_design:
    object = (nl_object) nl_context_get_design_by_name (context, name);
    break;
  case nl_kind_library:
    object = (nl_object) nl_context_get_library_by_name (context, name);
    break;
  default:
    ASSERT (0);
  }

  if ( object != NULL ) {
    ar_add (result, &object);

    if ( paths != NULL ) {
      ar object_path;

      if ( path == NULL ) {
	object_path = ar_alloc (0, sizeof (nl_object));
      }
      else {
	object_path = ar_copy (path);
      }
    
      ar_add (paths, &object_path);
    }
  }

  return TCL_OK;
}


static
int
ui_find_object_in_design (nl_design design, nl_kind kind, nl_kind subkind,
			  char *name, ar path, ar result, ar paths)
{
  nl_object object;
  nl_object append_to_path = NULL;

  switch (kind) {

  case nl_kind_cell:
    object = (nl_object) nl_design_get_cell_by_name (design, name);
    break;

  case nl_kind_net:
    object = (nl_object) nl_design_get_net_by_name (design, name);
    break;

  case nl_kind_reference:
    object = (nl_object) nl_design_get_reference_by_name (design, name);
    break;

  case nl_kind_port:
    object = (nl_object) nl_design_get_port_by_name (design, name);
    if ( object != NULL && nl_object_kind (object) != nl_kind_port ) {
      object = NULL;
    }
    break;

  case nl_kind_attr:
    object = (nl_object) nl_design_get_attr_by_name (design, name);
    break;

  case nl_kind_type:
    object = (nl_object) nl_design_get_type_by_name (design, name);
    break;

  case nl_kind_bus:
    switch (subkind) {
    case nl_kind_port:
      object = (nl_object) nl_design_get_port_by_name (design, name);
      break;
    case nl_kind_net:
      object = (nl_object) nl_design_get_object_by_name (design, name);
      break;
    case nl_kind_cell:
      object = (nl_object) nl_design_get_object_by_name (design, name);
      break;
    case nl_kind_null:
      object = (nl_object) nl_design_get_port_by_name (design, name);

      if ( object == NULL || nl_object_kind (object) != nl_kind_bus ) {
	object = (nl_object) nl_design_get_object_by_name (design, name);

	if ( object != NULL && nl_object_kind (object) != nl_kind_bus )
	  object = NULL;
      }
      break;
    default:
      ASSERT (0);
    }

    if ( object != NULL ) {
      if ( nl_object_kind (object) != nl_kind_bus ) {
	object = NULL;
      }
      else if ( subkind != nl_kind_null &&
		nl_bus_member_kind ((nl_bus) object) != subkind ) {
	object = NULL;
      }
    }
    break;

  case nl_kind_design: {
    nl_cell cell = nl_design_get_cell_by_name (design, name);

    if ( cell != NULL ) {
      nl_reference reference = nl_cell_reference (cell);
      nl_object down_design = nl_reference_down_design (reference);

      if ( down_design == NULL &&
	   nl_object_kind (down_design) == nl_kind_design ) {
	object = down_design;
	append_to_path = (nl_object) cell;
      }
      else {
	object = NULL;
	append_to_path = NULL;
      }
    }
    else {
      nl_context context = nl_design_context (design);

      object = (nl_object) nl_context_get_design_by_name (context, name);
    }
    break;
  }

  default:
    ASSERT (0);
  }

  if ( object != NULL ) {
    ar_add (result, &object);

    if ( paths != NULL ) {
      ar object_path;

      if ( path == NULL ) {
	object_path = ar_alloc (0, sizeof (nl_object));
      }
      else {
	object_path = ar_copy (path);
      }

      if ( append_to_path != NULL ) {
	ar_add (object_path, &append_to_path);
      }
      
      ar_add (paths, &object_path);
    }
  }

  return TCL_OK;
}


static
int
ui_find_object_in_library (nl_library library, nl_kind kind, char *name,
			   ar path, ar result, ar paths)
{
  nl_object object;

  switch (kind) {
  case nl_kind_libcell:
    object = (nl_object) nl_library_get_libcell_by_name (library, name);
    break;
  default:
    ASSERT (0);
  }

  if ( object != NULL ) {
    ar_add (result, &object);

    if ( paths != NULL ) {
      void *null = NULL;

      ar_add (paths, &null);
    }
  }

  return TCL_OK;
}


static
int
ui_find_objects_in_library (Tcl_Interp *interp, nl_library library,
			    nl_kind kind, char *pattern, ui_find_mode mode,
			    ar path, ar result, ar paths)
{
  nl_dll_head dll;
  int status;

  switch ( kind ) {
  case nl_kind_libcell:
    dll = nl_library_libcells (library);
    break;
  default:
    ASSERT (0);
  }

  status = ui_find_objects_in_dll (interp, pattern, mode, dll, path, result,
				   paths);

  return status;
}


static
int
ui_find_object_in_libcell (nl_libcell libcell, nl_kind kind, char *name,
			   ar path, ar result, ar paths)
{
  nl_object object;

  switch (kind) {
  case nl_kind_libpin:
    object = (nl_object) nl_libcell_get_libpin_by_name (libcell, name);
    break;
  default:
    ASSERT (0);
  }

  if ( object != NULL ) {
    ar_add (result, &object);

    if ( paths != NULL ) {
      void *null = NULL;

      ar_add (paths, &null);
    }
  }

  return TCL_OK;
}


static
int
ui_find_objects_in_libcell (Tcl_Interp *interp, nl_libcell libcell,
			    nl_kind kind, char *pattern, ui_find_mode mode,
			    ar path, ar result, ar paths)
{
  nl_dll_head dll;
  int status;

  switch ( kind ) {
  case nl_kind_libpin:
    dll = nl_libcell_libpins (libcell);
    break;
  default:
    ASSERT (0);
  }

  status = ui_find_objects_in_dll (interp, pattern, mode, dll, path, result,
				   paths);

  return status;
}


static
int
ui_find_iobjects_in_dll (Tcl_Interp *interp, char *pattern,
			 ui_find_mode mode, nl_dll_head dll,
			 nl_idesign idesign, ar result)
{
  Tcl_RegExp tcl_regexp = NULL;

  ASSERT (mode == ui_find_mode_glob || mode == ui_find_mode_regexp);

  if ( mode == ui_find_mode_regexp ) {
    tcl_regexp = Tcl_RegExpCompile (interp, pattern);

    if ( tcl_regexp == NULL ) {
      return TCL_ERROR;
    }
  }

  nl_dll_for_all (dll, nl_named_object, obj) {
    char *name = nl_named_object_name (obj);
    int flag;

    if ( mode == ui_find_mode_glob ) {
      flag = Tcl_StringMatch (name, pattern);
    }
    else {
      ASSERT (tcl_regexp != NULL);
      flag = Tcl_RegExpExec (interp, tcl_regexp, name, name);
    }

    if ( flag == 1 ) {
      nl_idesign_object iobj
	= nl_idesign_get_iobject (idesign, (nl_object) obj);

      ar_add (result, &iobj);
    }
    else if ( flag == -1 ) {
      return TCL_ERROR;
    }
  } nl_end_for;

  return TCL_OK;
}


static
int
ui_find_iobjects_in_design (Tcl_Interp *interp, nl_idesign idesign,
			    nl_kind kind, char *pattern, ui_find_mode mode,
			    ar result)
{
  nl_design design = nl_idesign_design (idesign);
  nl_dll_head dll;
  int status;

  switch ( kind ) {
  case nl_kind_icell:
    dll = nl_design_cells (design);
    break;
  case nl_kind_iport:
    dll = nl_design_ports (design);
    break;
  case nl_kind_inet:
    dll = nl_design_nets (design);
    break;
  default:
    ASSERT (0);
  }

  status
    = ui_find_iobjects_in_dll (interp, pattern, mode, dll, idesign, result);

  return status;
}


static
int
ui_find_iobject_in_design (nl_idesign idesign, nl_kind kind, char *name,
			   ar result)
{
  nl_idesign_object object;

  switch (kind) {
  case nl_kind_icell:
    object = (nl_idesign_object) nl_idesign_get_icell_by_name (idesign, name);
    break;
  case nl_kind_inet:
    object = (nl_idesign_object) nl_idesign_get_inet_by_name (idesign, name);
    break;
  case nl_kind_iport:
    object = (nl_idesign_object) nl_idesign_get_iport_by_name (idesign, name);
    if ( object != NULL && nl_idesign_object_kind (object) != nl_kind_iport ) {
      object = NULL;
    }
    break;
  case nl_kind_idesign: {
    nl_icell icell = nl_idesign_get_icell_by_name (idesign, name);

    if ( icell == NULL ) {
      nl_design tmp_design = nl_idesign_design (idesign);
      nl_context context = nl_design_context (tmp_design);
      nl_design design = nl_context_get_design_by_name (context, name);

      if ( design != NULL ) {
	nl_dll_head head = nl_design_idesigns (design);
	int num_elements = nl_dll_head_num_elements (head);

	if ( num_elements > 1 ) {
	  error ("there is more than one idesign for the specified design: %s", name);
	}
	else if ( num_elements == 0 ) {
	  error ("there are no idesigns for the specified design: %s", name);
	}
	else if ( nl_dll_head_num_elements (head) == 1 ) {
	  nl_idesign result_idesign = (nl_idesign) nl_dll_gen_first (head);

	  object = (nl_idesign_object) result_idesign;
	}
      }
    }
    else {
      nl_idesign idesign = nl_icell_down_design (icell);

      object = (nl_idesign_object) idesign;
    }
    break;
  }
  default:
    ASSERT (0);
  }

  if ( object != NULL ) {
    ar_add (result, &object);
  }

  return TCL_OK;
}


static
int
ui_find_path_array (Tcl_Interp *interp, nl_context context, ar path, int index,
		    nl_kind kind, nl_kind subkind, ui_find_mode mode, 
		    nl_design design, ar result, ar paths)
{
  ar objects = NULL;
  ar object_paths = NULL;
  int status = TCL_OK;

  if ( index > 0 ) {
    nl_kind next_kind;

    if ( kind == nl_kind_refpin )
      next_kind = nl_kind_reference;
    else if ( kind == nl_kind_libcell )
      next_kind = nl_kind_library;
    else if ( kind == nl_kind_libpin )
      next_kind = nl_kind_libcell;
    else
      next_kind = nl_kind_cell;

    if ( kind == nl_kind_design && design == NULL ) {
      error ("attempt to find a design by hierarchical name");
    }

    objects = ar_alloc (0, sizeof (nl_object));
    object_paths = ar_alloc (0, sizeof (ar));
    status = ui_find_path_array (interp, context, path, index-1, next_kind,
				 nl_kind_null, mode, design, objects,
				 object_paths);
  }

  if ( status == TCL_OK ) {
    char *last;
    int do_exact;

    ar_ref (path, index, &last);

    switch ( mode ) {
    case ui_find_mode_exact:
      do_exact = 1;
      break;
    case ui_find_mode_glob:
      do_exact = ! ui_is_glob (last);
      if ( do_exact ) {
	ui_unescape_glob (last);
      }
      break;
    case ui_find_mode_regexp:
      do_exact = ! ui_is_regexp (last);
      if ( do_exact ) {
	ui_unescape_regexp (last);
      }
      break;
    case ui_find_mode_subregexp:
      do_exact = 0;
      break;
    default:
      ASSERT (0);
    }

    if ( kind == nl_kind_refpin ) {
      if ( objects != NULL ) {
	ar_for_all_indexed (objects, nl_reference, reference, index) {
	  ar object_path;

	  ar_ref (object_paths, index, &object_path);

	  if ( do_exact ) {
	    nl_object refpin
	      = nl_reference_get_refpin_by_name (reference, last);

	    if ( refpin != NULL ) {
	      ar refpin_path = ar_copy (object_path);
	      
	      ar_add (result, &refpin);
	      if ( paths != NULL )
		ar_add (paths, &refpin_path);
	    }
	  }
	  else {
	    nl_dll_head refpins = nl_reference_refpins (reference);

	    status = ui_find_objects_in_dll (interp, last, mode, refpins,
					     object_path, result, paths);

	    if ( status != TCL_OK ) {
	      break;
	    }
	  }
	} ar_end_for;
      }
    }
    else if ( kind == nl_kind_pin ) {
      if ( objects == NULL ) {
	nl_object port = nl_design_get_port_by_name (design, last);

	if ( port != NULL ) {
	  if ( nl_object_kind (port) == nl_kind_port ) {
	    nl_pin pin = nl_port_pin ((nl_port) port);
	    ar pin_path = ar_alloc (0, sizeof (ar));

	    ar_add (result, &pin);
	    if ( paths != NULL )
	      ar_add (paths, &pin_path);
	  }
	  else {
	    /* It's a bus instead of a port. */
	  }
	}
      }
      else {
	ar_for_all_indexed (objects, nl_cell, cell, index) {
	  ar object_path;
	  nl_reference reference = nl_cell_reference (cell);

	  ar_ref (object_paths, index, &object_path);

	  if ( do_exact ) {
	    nl_object refpin
	      = nl_reference_get_refpin_by_name (reference, last);

	    if ( refpin != NULL ) {
	      if ( nl_object_kind (refpin) == nl_kind_refpin ) {
		nl_pin pin
		  = nl_cell_get_pin_by_refpin (cell, (nl_refpin) refpin);
		ar pin_path = ar_copy (object_path);

		ar_add (result, &pin);
		if ( paths != NULL )
		  ar_add (paths, &pin_path);
	      }
	      else {
		/* It's a bus instead of a single refpin. */
	      }
	    }
	  }
	  else {
	    nl_dll_head refpins = nl_reference_refpins (reference);
	    ar refpin_matches = ar_alloc (0, sizeof (nl_refpin));

	    status = ui_find_objects_in_dll (interp, last, mode, refpins,
					     NULL, refpin_matches, NULL);

	    if ( status == TCL_OK ) {
	      ar_for_all (refpin_matches, nl_refpin, refpin) {
		nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
		ar pin_path = ar_copy (object_path);

		ar_add (result, &pin);
		if ( paths != NULL )
		  ar_add (paths, &pin_path);
	      } ar_end_for;
	    }

	    ar_free (refpin_matches);

	    if ( status != TCL_OK )
	      break;
	  }
	} ar_end_for;
      }
    }
    else if ( kind == nl_kind_design ) {
      if ( objects == NULL ) {
	if ( do_exact ) {
	  status = ui_find_object_in_context (context, kind, last, NULL,
					      result, paths);
	}
	else {
	  status = ui_find_objects_in_context (interp, context, kind, last,
					       mode, NULL, result, paths);
	}
      }
      else {
	ar_for_all_indexed (objects, nl_cell, cell, index) {
	  ar object_path;
	  nl_reference reference = nl_cell_reference (cell);
	  nl_object down_obj = nl_reference_down_design (reference);

	  ar_ref (object_paths, index, &object_path);
	  ar_add (object_path, &cell);

	  if ( down_obj != NULL &&
	       nl_object_kind (down_obj) == nl_kind_design ) {
	    if ( do_exact ) {
	      status = ui_find_object_in_context (context, kind, last, 
						  object_path, result, paths);
	    }
	    else {
	      status = ui_find_objects_in_context (interp, context, kind,
						   last, mode, object_path,
						   result, paths);
	    }

	    if ( status != TCL_OK )
	      break;
	  }
	} ar_end_for;
      }
    }
    else if ( kind == nl_kind_library ) {
      if ( objects == NULL ) {
	if ( do_exact ) {
	  status = ui_find_object_in_context (context, kind, last, NULL,
					      result, paths);
	}
	else {
	  status = ui_find_objects_in_context (interp, context, kind, last,
					       mode, NULL, result, paths);
	}
      }
    }
    else if ( kind == nl_kind_libcell ) {
      if ( objects != NULL ) {
	ar_for_all (objects, nl_library, library) {
	  if ( do_exact ) {
	    status = ui_find_object_in_library (library, kind, last,
						NULL, result, NULL);
	  }
	  else {
	    status = ui_find_objects_in_library (interp, library, kind, last,
						 mode, NULL, result, NULL);
	  }

	  if ( status != TCL_OK )
	    break;
	} ar_end_for;
      }
    }
    else if ( kind == nl_kind_libpin ) {
      if ( objects != NULL ) {
	ar_for_all (objects, nl_libcell, libcell) {
	  if ( do_exact ) {
	    status = ui_find_object_in_libcell (libcell, kind, last, NULL,
						result, NULL);
	  }
	  else {
	    status = ui_find_objects_in_libcell (interp, libcell, kind, last,
						 mode, NULL, result, NULL);
	  }
	} ar_end_for;
      }
    }
    else {
      if ( objects == NULL ) {
	if ( do_exact ) {
	  status = ui_find_object_in_design (design, kind, subkind, last, NULL,
					     result, paths);
	}
	else {
	  status = ui_find_objects_in_design (interp, design, kind, subkind,
					      last, mode, NULL, result, paths);
	}
      }
      else {
	ar_for_all_indexed (objects, nl_cell, cell, index) {
	  ar object_path;
	  nl_reference reference = nl_cell_reference (cell);
	  nl_object down_obj = nl_reference_down_design (reference);

	  ar_ref (object_paths, index, &object_path);
	  ar_add (object_path, &cell);

	  if ( down_obj != NULL &&
	       nl_object_kind (down_obj) == nl_kind_design ) {
	    nl_design cell_design = (nl_design) down_obj;

	    if ( do_exact ) {
	      status = ui_find_object_in_design (cell_design, kind, subkind,
						 last, object_path,
						 result, paths);
	    }
	    else {
	      status = ui_find_objects_in_design (interp, cell_design, kind,
						  subkind, last, mode,
						  object_path,
						  result, paths);
	    }

	    if ( status != TCL_OK )
	      break;
	  }
	} ar_end_for;
      }
    }
  }

  if ( objects != NULL )
    ar_free (objects);

  if ( object_paths != NULL ) {
    ar_for_all (object_paths, ar, object_path) {
      ar_free (object_path);
    } ar_end_for;

    ar_free (object_paths);
  }

  return status;
}


static
int
ui_find_path_array_i (Tcl_Interp *interp, ar path, int index, nl_kind kind,
		      ui_find_mode mode, nl_idesign idesign, ar result)
{
  ar objects = NULL;
  int status = TCL_OK;

  if ( index > 0 ) {
    objects = ar_alloc (0, sizeof (nl_object));
    status = ui_find_path_array_i (interp, path, index-1, nl_kind_icell, mode,
				   idesign, objects);
  }

  if ( status == TCL_OK ) {
    char *last;
    int do_exact;

    ar_ref (path, index, &last);

    switch ( mode ) {
    case ui_find_mode_exact:
      do_exact = 1;
      break;
    case ui_find_mode_glob:
      do_exact = ! ui_is_glob (last);
      break;
    case ui_find_mode_regexp:
      do_exact = ! ui_is_regexp (last);
      break;
    default:
      ASSERT (0);
    }

    if ( kind == nl_kind_ipin ) {
      if ( objects == NULL ) {
	nl_iport iport = nl_idesign_get_iport_by_name (idesign, last);

	if ( iport != NULL ) {
	  nl_ipin ipin = nl_iport_ipin (iport);

	  ar_add (result, &ipin);
	}
	else {
	  /* It's a bus instead of a port. */
	}
      }
      else {
	ar_for_all (objects, nl_icell, icell) {
	  nl_cell cell = nl_icell_cell (icell);
	  nl_reference reference = nl_cell_reference (cell);

	  if ( do_exact ) {
	    nl_object refpin
	      = nl_reference_get_refpin_by_name (reference, last);

	    if ( refpin != NULL ) {
	      if ( nl_object_kind (refpin) == nl_kind_refpin ) {
		nl_ipin ipin
		  = nl_icell_get_ipin_by_refpin (icell, (nl_refpin) refpin);

		ar_add (result, &ipin);
	      }
	      else {
		/* It's a bus instead of a single refpin. */
	      }
	    }
	  }
	  else {
	    nl_dll_head refpins = nl_reference_refpins (reference);
	    ar refpin_matches = ar_alloc (0, sizeof (nl_refpin));

	    status = ui_find_objects_in_dll (interp, last, mode, refpins,
					     NULL, refpin_matches, NULL);

	    if ( status == TCL_OK ) {
	      ar_for_all (refpin_matches, nl_refpin, refpin) {
		nl_ipin ipin = nl_icell_get_ipin_by_refpin (icell, refpin);

		ar_add (result, &ipin);
	      } ar_end_for;
	    }

	    ar_free (refpin_matches);

	    if ( status != TCL_OK )
	      break;
	  }
	} ar_end_for;
      }
    }
    else {
      if ( objects == NULL ) {
	if ( do_exact ) {
	  status = ui_find_iobject_in_design (idesign, kind, last, result);
	}
	else {
	  status = ui_find_iobjects_in_design (interp, idesign, kind, last,
					       mode, result);
	}
      }
      else {
	ar_for_all (objects, nl_icell, icell) {
	  nl_idesign down_idesign = nl_icell_down_design (icell);

	  if ( down_idesign != NULL ) {
	    if ( do_exact ) {
	      status = ui_find_iobject_in_design (down_idesign, kind, last, 
						  result);
	    }
	    else {
	      status = ui_find_iobjects_in_design (interp, down_idesign, kind,
						   last, mode, result);
	    }

	    if ( status != TCL_OK )
	      break;
	  }
	} ar_end_for;
      }
    }
  }

  if ( objects != NULL )
    ar_free (objects);

  return status;
}


char *ui_hierarchy_separator = NULL;
char *ui_bus_naming_style = NULL;


ar
ui_tokenize_hierarchy_path (char *path, char **str_p, char *hier_sep)
{
  char *str = STRDUP (path);

  ar path_ar = ar_alloc (1, sizeof (char *));

  if ( hier_sep != NULL && hier_sep[0] != 0 ) {
    int toklen;
    int seplen = strlen (hier_sep);
    char *tok = str;

    while ( (toklen = str_match (hier_sep, tok, '\\')) >= 0 ) {
      tok[toklen] = 0;

      str_unescape (tok, '\\', hier_sep);
      ar_add (path_ar, &tok);

      tok += toklen + seplen;
    }

    str_unescape (tok, '\\', hier_sep);
    ar_add (path_ar, &tok);
  }
  else {
    str_unescape (str, '\\', hier_sep);
    ar_add (path_ar, &str);
  }

  *str_p = str;
  return path_ar;
}


int
ui_find_path (Tcl_Interp *interp, nl_context context, char *path, nl_kind kind,
	      nl_kind subkind, nl_design design, int exact, int glob, int regexp,
	      ar result, ar paths)
	      
{
  char *str;
  ar path_ar = ui_tokenize_hierarchy_path (path, &str, ui_hierarchy_separator);
  ui_find_mode mode;

  if ( exact )
    mode = ui_find_mode_exact;
  else if ( glob )
    mode = ui_find_mode_glob;
  else if ( regexp )
    mode = ui_find_mode_regexp;
  else
    ASSERT (0);

  {
    int index = ar_size (path_ar) - 1;
    int status = ui_find_path_array (interp, context, path_ar, index, kind,
				     subkind, mode, design, result, paths);

    FREE (str);
    ar_free (path_ar);

    return status;
  }
}


int 
ui_find_object_path (Tcl_Interp *interp, nl_context context, ar path,
		     nl_kind kind, nl_kind subkind, nl_design design,
		     ui_find_mode mode, ar result, ar paths)
{
  int index = ar_size (path) - 1;
  int status = ui_find_path_array (interp, context, path, index, kind, subkind,
				   mode, design, result, paths);

  return status;
}


int
ui_find_iobject (Tcl_Interp *interp, char *path, char *hier_sep, nl_kind kind,
		 nl_idesign idesign, int exact, int glob, int regexp, ar result)
{
  char *str;
  ar path_ar = ui_tokenize_hierarchy_path (path, &str, hier_sep);
  ui_find_mode mode;

  if ( exact )
    mode = ui_find_mode_exact;
  else if ( glob )
    mode = ui_find_mode_glob;
  else if ( regexp )
    mode = ui_find_mode_regexp;
  else
    ASSERT (0);

  {
    int index = ar_size (path_ar) - 1;
    int status = ui_find_path_array_i (interp, path_ar, index, kind, mode,
				       idesign, result);

    FREE (str);
    ar_free (path_ar);

    return status;
  }
}


int
ui_find_iobject_path (Tcl_Interp *interp, ar path, nl_kind kind,
		      nl_idesign idesign, ui_find_mode mode, ar result)
{
  int index = ar_size (path) - 1;
  int status = ui_find_path_array_i (interp, path, index, kind, mode, idesign,
				     result);

  return status;
}


nl_idesign_object
ui_path_to_iobject (ar path, nl_idesign top_idesign)
{
  int size = ar_size (path);
  nl_icell icell = NULL;

  ar_for_all_indexed (path, nl_object, obj, index) {
    nl_kind kind = nl_object_kind (obj);
    nl_idesign idesign;

    if ( icell == NULL ) {
      idesign = top_idesign;
    }
    else {
      idesign = nl_icell_down_design (icell);
    }

    switch ( kind ) {

    case nl_kind_cell: {
      nl_cell cell = (nl_cell) obj;

      icell = nl_idesign_get_icell (idesign, cell);

      break;
    }

    case nl_kind_pin: {
      nl_pin pin = (nl_pin) obj;
      nl_refpin refpin = nl_pin_refpin (pin);
      nl_ipin ipin = nl_icell_get_ipin_by_refpin (icell, refpin);

      ASSERT (index == size - 1);

      return (nl_idesign_object) ipin;
    }

    case nl_kind_net: {
      nl_net net = (nl_net) obj;
      nl_inet inet = nl_idesign_get_inet (idesign, net);

      ASSERT (index == size - 1);

      return (nl_idesign_object) inet;
    }
    default:
      ASSERT (0);
    }
  } ar_end_for;

  return (nl_idesign_object) icell;
}
