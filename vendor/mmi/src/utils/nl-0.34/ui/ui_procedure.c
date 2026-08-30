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


static
int
ui_procedure_set_from_any (Tcl_Interp *interp, Tcl_Obj *result)
{
  Tcl_SetResult (interp, "can't create lambda_objects from strings.\n", TCL_STATIC);
  return TCL_ERROR;
}


static
void
ui_procedure_update_string (Tcl_Obj *tcl_obj)
{
  char *name = (char *)tcl_obj->internalRep.otherValuePtr;
  int length = strlen (name);
  tcl_obj->bytes = ckalloc (length + 1);
  strcpy (tcl_obj->bytes, name);
  tcl_obj->length = length;
}


static
void
ui_procedure_dup (Tcl_Obj *src, Tcl_Obj *dest)
{
}


static
void
ui_procedure_free (Tcl_Obj *obj)
{
}


static Tcl_ObjType ui_procedure_type = {
  "procedure",
  ui_procedure_free,
  ui_procedure_dup,
  ui_procedure_update_string,
  ui_procedure_set_from_any
};


void
ui_procedure_register_type (void)
{
  Tcl_RegisterObjType (&ui_procedure_type);
}


static
void
ui_procedure_free_tcl_obj (void *ptr)
{
  Tcl_Obj *obj = *(Tcl_Obj **)ptr;

  if ( obj != NULL ) {
    Tcl_DecrRefCount (obj);
  }
}


static
int
ui_hash_procedure (void *ptr)
{
  char **tag = (char **)ptr;
  int x = ht_hash_string (tag[0]);
  int y = ht_hash_string (tag[1]);

  return x - y;
}


static
int
ui_compare_procedure (void *ptr1, void *ptr2)
{
  char **tag1 = (char **)ptr1;
  char **tag2 = (char **)ptr2;

  return (strcmp (tag1[0], tag2[0]) == 0 &&
	  strcmp (tag1[1], tag2[1]) == 0);
}


static
void *
ui_copy_procedure (void *ptr)
{
  char **tag = (char **)ptr;
  char **copy = MALLOC (2 * sizeof (char *));

  copy[0] = STRDUP (tag[0]);
  copy[1] = STRDUP (tag[1]);

  return (void *) copy;
}


static
void
ui_free_procedure (void *ptr)
{
  char **tag = (char **)ptr;
  FREE (tag[0]);
  FREE (tag[1]);
  FREE (ptr);
}
  

hashtab ui_procedure_table = NULL;
ht_attr ui_procedure_attr = NULL;


int
ui_procedure_create (Tcl_Interp *interp, Tcl_Obj *args, Tcl_Obj *body,
		 Tcl_Obj **result_p)
{
  if ( ui_procedure_table == NULL ) {
    ui_procedure_table = ht_alloc (16, ui_hash_procedure, ui_compare_procedure,
				   ui_copy_procedure, ui_free_procedure);
    ui_procedure_attr = ht_new_attribute (ui_procedure_table, sizeof (Tcl_Obj *),
					  NULL, ui_procedure_free_tcl_obj);
  }

  {
    char *tag[2];
    int args_len;
    int body_len;
    Tcl_Obj *result;
    ht_entry ent;

    tag[0] = Tcl_GetStringFromObj (args, &args_len);
    tag[1] = Tcl_GetStringFromObj (body, &body_len);
    
    ent = ht_lookup (ui_procedure_table, tag);

    if ( ent != ht_null ) {
      ht_get_attribute_for_entry (ui_procedure_attr, ent, &result);
    }
    else {
      char buf[32];

      ent = ht_insert (ui_procedure_table, tag);

      sprintf (buf, "__procedure_%d", ent);

      {
	int length = strlen (buf);
	Tcl_Obj *proc = Tcl_NewStringObj ("proc", 4);
	Tcl_Obj *name = Tcl_NewStringObj (buf, length);
	Tcl_Obj *argv[4];
	Tcl_Obj *cmd;
	int status;

	argv[0] = proc;
	argv[1] = name;
	argv[2] = args;
	argv[3] = body;

	cmd = Tcl_NewListObj (4, argv);

	status = Tcl_EvalObj (interp, cmd);

	if ( status != TCL_OK ) {
	  return status;
	}
	else {
	  /* result = Tcl_NewStringObj (buf, length); */
	  result = Tcl_NewObj ();

	  result->bytes = NULL;
	  result->typePtr = &ui_procedure_type;
	  result->internalRep.otherValuePtr = STRDUP (buf);

	  ht_set_attribute_for_entry (ui_procedure_attr, ent, &result);
	  Tcl_IncrRefCount (result);
	}
      }
    }

    *result_p = result;
    return TCL_OK;
  }
}
