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
#include "tcl.h"
#include "ui.h"
#include "ui_int.h"


static void ui_obj_free (Tcl_Obj *);
static void ui_obj_dup (Tcl_Obj *, Tcl_Obj *);
static void ui_obj_update_string (Tcl_Obj *);
static int  ui_obj_set_from_any (Tcl_Interp *, Tcl_Obj *);

  
static Tcl_ObjType ui_obj_type = {
  "nl_object",
  ui_obj_free,
  ui_obj_dup,
  ui_obj_update_string,
  ui_obj_set_from_any
};


static
int
ui_obj_set_from_any (Tcl_Interp *interp, Tcl_Obj *result)
{
  Tcl_SetResult (interp, "can't create nl_objects from strings.\n",
		 TCL_STATIC);

  return TCL_ERROR;
}


static
void
ui_obj_format_path (char **result_p, int *len_p, ar path, ...)
{
  int length = 0;
  char *result;
  int pos = 0;
  int separator_length = strlen (ui_hierarchy_separator);
  int first;

  if ( path != NULL ) {
    ar_for_all (path, nl_cell, cell) {
      char *cell_name = nl_cell_name (cell);

      length += strlen (cell_name);
      length += separator_length;
    } ar_end_for;
  }

  {
    char *arg;
    va_list ap;

    va_start (ap, path);

    while ( (arg = va_arg (ap, char *)) != NULL ) {
      length += strlen (arg);
      length += separator_length;
    }

    va_end (ap);
  }

  result = Tcl_Alloc (length);

  first = 1;

  if ( path != NULL ) {
    ar_for_all (path, nl_cell, cell) {
      char *cell_name = nl_cell_name (cell);

      if ( !first ) {
	strcpy (result + pos, ui_hierarchy_separator);
	pos += separator_length;
      }
      first = 0;

      strcpy (result + pos, cell_name);
      pos += strlen (cell_name);
    } ar_end_for;
  }

  {
    char *arg;
    va_list ap;

    va_start (ap, path);

    while ( (arg = va_arg (ap, char *)) != NULL ) {
      if ( !first ) {
	strcpy (result + pos, ui_hierarchy_separator);
	pos += separator_length;
	first = 0;
      }
      first = 0;

      strcpy (result + pos, arg);
      pos += strlen (arg);
    }

    va_end (ap);
  }

  result[pos] = 0;

  *result_p = result;
  *len_p = pos;
}


static
char *
ui_obj_escape_hierarchy_separator (char *name)
{
  int sep_len = strlen (ui_hierarchy_separator);
  int name_len = strlen (name);
  char *s = name;
  char *t = s;
  int count = 0;
  char *result;
  char *u;

  while ( (t = strstr (t, ui_hierarchy_separator)) != NULL ) {
    count++;
    t += sep_len;
  }

  result = MALLOC (name_len + count * sep_len + 1);

  t = s;
  u = result;

  while ( (t = strstr (t, ui_hierarchy_separator)) != NULL ) {
    char *v;

    while ( s != t ) {
      *u = *s;
      u++;
      s++;
    }

    v = ui_hierarchy_separator;

    while ( *v != 0 ) {
      *u = '\\';
      u++;
      *u = *v;
      u++;
      v++;
    }

    s += sep_len;
    t += sep_len;
  }

  while ( *s != 0 ) {
    *u = *s;
    u++;
    s++;
  }

  *u = 0;

  return result;
}


static
int
ui_obj_format_icell_path (char **str_p, nl_icell icell, int length,
			  int sep_len)
{
  char *icell_name = nl_icell_name (icell);
  char *name = ui_obj_escape_hierarchy_separator (icell_name);
  int name_len = strlen (name);
  nl_idesign idesign = nl_icell_idesign (icell);
  nl_icell up_icell = nl_idesign_icell (idesign);
  int result;

  if ( up_icell == NULL ) {
    int total_length = name_len + length;

    *str_p = Tcl_Alloc (total_length + 1);
    strcpy (*str_p, name);

    result = name_len;
  }
  else {
    int new_length = name_len + sep_len + length;
    int start_at = ui_obj_format_icell_path (str_p, up_icell, new_length,
					     sep_len);

    strcpy ((*str_p) + start_at, ui_hierarchy_separator);
    strcpy ((*str_p) + start_at + sep_len, name);

    result = start_at + sep_len + name_len;
  }

  FREE (name);
  return result;
}


static
int
ui_obj_format_iport_path (char **str_p, nl_iport iport)
{
  char *name = nl_iport_name (iport);
  int name_len = strlen (name);
  nl_idesign idesign = nl_iport_idesign (iport);
  nl_icell up_icell = nl_idesign_icell (idesign);

  if ( up_icell == NULL ) {
    *str_p = Tcl_Alloc (name_len + 1);
    strcpy ((*str_p), name);

    return name_len;
  }
  else {
    int sep_len = strlen (ui_hierarchy_separator);
    int new_length = sep_len + name_len;
    int start_at = ui_obj_format_icell_path (str_p, up_icell, new_length,
					     sep_len);

    strcpy ((*str_p) + start_at, ui_hierarchy_separator);
    strcpy ((*str_p) + start_at + sep_len, name);

    return start_at + sep_len + name_len;
  }
}


static
int
ui_obj_format_inet_path (char **str_p, nl_inet inet)
{
  char *name = nl_inet_name (inet);
  int name_len = strlen (name);
  nl_idesign idesign = nl_inet_idesign (inet);
  nl_icell up_icell = nl_idesign_icell (idesign);

  if ( up_icell == NULL ) {
    *str_p = Tcl_Alloc (name_len + 1);
    strcpy ((*str_p), name);

    return name_len;
  }
  else {
    int sep_len = strlen (ui_hierarchy_separator);
    int new_length = sep_len + name_len;
    int start_at = ui_obj_format_icell_path (str_p, up_icell, new_length,
					     sep_len);

    strcpy ((*str_p) + start_at, ui_hierarchy_separator);
    strcpy ((*str_p) + start_at + sep_len, name);

    return start_at + sep_len + name_len;
  }
}


static
int
ui_obj_format_ipin_path (char **str_p, nl_ipin ipin)
{
  nl_idesign_object owner = nl_ipin_owner (ipin);
  nl_kind owner_kind = nl_idesign_object_kind (owner);

  if ( owner_kind == nl_kind_icell ) {
    char *name = nl_ipin_name (ipin);
    int name_len = strlen (name);
    nl_icell icell = (nl_icell) owner;
    int sep_len = strlen (ui_hierarchy_separator);
    int new_length = name_len + sep_len;
    int start_at = ui_obj_format_icell_path (str_p, icell, new_length,
					     sep_len);

    strcpy ((*str_p) + start_at, ui_hierarchy_separator);
    strcpy ((*str_p) + start_at + sep_len, name);

    return start_at + sep_len + name_len;
  }
  else if ( owner_kind == nl_kind_iport ) {
    nl_iport iport = (nl_iport) owner;
    int result = ui_obj_format_iport_path (str_p, iport);

    return result;
  }
  else {
    ASSERT (0);
  }
}


static
void
ui_obj_format_pin_path (Tcl_Obj *tcl_obj, ar path, nl_pin pin)
{
  nl_cell_or_port owner = nl_pin_owner (pin);
  char *owner_name = nl_cell_or_port_name (owner);

  if ( nl_cell_or_port_kind (owner) == nl_kind_cell ) {
    nl_refpin refpin = nl_pin_refpin (pin);
    char *refpin_name = nl_refpin_name (refpin);

    ui_obj_format_path (&tcl_obj->bytes, &tcl_obj->length,
			path, owner_name, refpin_name, NULL);
  }
  else {
    ui_obj_format_path (&tcl_obj->bytes, &tcl_obj->length,
			path, owner_name, NULL);
  }
}


static
int
ui_obj_format_library_path (char **str_p, nl_library library, int extra_space)
{
  char *name = nl_library_name (library);
  int name_len = strlen (name);
  int alloc_size = name_len + extra_space + 1;

  *str_p = Tcl_Alloc (alloc_size);

  strcpy (*str_p, name);

  return name_len;
}


static
int
ui_obj_format_libcell_path (char **str_p, nl_libcell libcell, int extra_space)
{
  char *name = nl_libcell_name (libcell);
  int name_len = strlen (name);
  int sep_len = strlen (ui_hierarchy_separator);
  int need = name_len + sep_len + extra_space;
  nl_library library = nl_libcell_library (libcell);
  int start_at = ui_obj_format_library_path (str_p, library, need);

  strcpy (*str_p + start_at, ui_hierarchy_separator);
  strcpy (*str_p + start_at + sep_len, name);

  return start_at + sep_len + name_len;
}


static
int
ui_obj_format_libpin_path (char **str_p, nl_libpin libpin)
{
  char *name = nl_libpin_name (libpin);
  int name_len = strlen (name);
  int sep_len = strlen (ui_hierarchy_separator);
  int need = name_len + sep_len;
  nl_libcell libcell = nl_libpin_libcell (libpin);
  int start_at = ui_obj_format_libcell_path (str_p, libcell, need);

  strcpy (*str_p + start_at, ui_hierarchy_separator);
  strcpy (*str_p + start_at + sep_len, name);

  return start_at + sep_len + name_len;
}


static
void
ui_obj_update_string (Tcl_Obj *tcl_obj)
{
  nl_object nl_obj = tcl_obj->internalRep.twoPtrValue.ptr1;
  ar path = tcl_obj->internalRep.twoPtrValue.ptr2;
  nl_kind kind = nl_object_kind (nl_obj);

  if ( kind == nl_kind_pin ) {
    nl_pin pin = (nl_pin) nl_obj;
    ui_obj_format_pin_path (tcl_obj, path, pin);
  }
  else if ( kind == nl_kind_ipin ) {
    nl_ipin ipin = (nl_ipin) nl_obj;

    tcl_obj->length = ui_obj_format_ipin_path (&tcl_obj->bytes, ipin);
  }
  else if ( kind == nl_kind_idesign ) {
    nl_idesign idesign = (nl_idesign) nl_obj;
    nl_design design = nl_idesign_design (idesign);
    char *name = nl_design_name (design);

    ui_obj_format_path (&tcl_obj->bytes, &tcl_obj->length,
			path, name, NULL);
  }
  else if ( kind == nl_kind_icell ) {
    nl_icell icell = (nl_icell) nl_obj;
    int sep_len = strlen (ui_hierarchy_separator);

    tcl_obj->length = ui_obj_format_icell_path (&tcl_obj->bytes, icell, 0,
						sep_len);
  }
  else if ( kind == nl_kind_inet ) {
    nl_inet inet = (nl_inet) nl_obj;

    tcl_obj->length = ui_obj_format_inet_path (&tcl_obj->bytes, inet);
  }
  else if ( kind == nl_kind_iport ) {
    nl_iport iport = (nl_iport) nl_obj;

    tcl_obj->length = ui_obj_format_iport_path (&tcl_obj->bytes, iport);
  }
  else if ( kind == nl_kind_library ) {
    nl_library library = (nl_library) nl_obj;

    tcl_obj->length = ui_obj_format_library_path (&tcl_obj->bytes, library, 0);
  }
  else if ( kind == nl_kind_libcell ) {
    nl_libcell libcell = (nl_libcell) nl_obj;

    tcl_obj->length = ui_obj_format_libcell_path (&tcl_obj->bytes, libcell, 0);
  }
  else if ( kind == nl_kind_libpin ) {
    nl_libpin libpin = (nl_libpin) nl_obj;

    tcl_obj->length = ui_obj_format_libpin_path (&tcl_obj->bytes, libpin);
  }
  else {
    char *name = nl_named_object_name ((nl_named_object) nl_obj);

    ui_obj_format_path (&tcl_obj->bytes, &tcl_obj->length,
			path, name, NULL);
  }
}


static
void
ui_obj_dup (Tcl_Obj *src, Tcl_Obj *dest)
{
  void *ptr1 = src->internalRep.twoPtrValue.ptr1;
  void *ptr2 = src->internalRep.twoPtrValue.ptr2;
  dest->internalRep.twoPtrValue.ptr1 = ptr1;
  dest->internalRep.twoPtrValue.ptr2 = ptr2;
}


static
void
ui_obj_free (Tcl_Obj *obj)
{
  ar path = obj->internalRep.twoPtrValue.ptr2;

  if ( path != NULL ) 
    ar_free (path);
}


Tcl_Obj *
ui_obj_create (nl_object nl_obj, ar path)
{
  Tcl_Obj *tcl_obj = Tcl_NewObj ();

  tcl_obj->typePtr = &ui_obj_type;
  tcl_obj->internalRep.twoPtrValue.ptr1 = nl_obj;

  if ( path != NULL )
    tcl_obj->internalRep.twoPtrValue.ptr2 = ar_copy (path);
  else
    tcl_obj->internalRep.twoPtrValue.ptr2 = NULL;

  tcl_obj->bytes = NULL;
  tcl_obj->length = 0;

  return tcl_obj;
}


Tcl_ObjType *
ui_obj_get_type (void)
{
  return &ui_obj_type;
}


nl_object
ui_obj_get_nl_object (Tcl_Obj *obj)
{
  nl_object result = obj->internalRep.twoPtrValue.ptr1;

  return result;
}


ar
ui_obj_get_nl_path (Tcl_Obj *obj)
{
  ar path = obj->internalRep.twoPtrValue.ptr2;

  return path;
}


void
ui_obj_register_type (void)
{
  Tcl_RegisterObjType (&ui_obj_type);
}
