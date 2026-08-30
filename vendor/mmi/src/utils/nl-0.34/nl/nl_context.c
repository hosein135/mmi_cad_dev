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
#include "nl.h"
#include "nl_int.h"

/**
   Create and return an nl context.  All nl designs are contained
   within a context.  So, you have to create an nl context before you
   can create any nl designs.
**/
/*exported*/
nl_context
nl_context_create (void)
{
  nl_context result = MALLOC (sizeof (*result));

  result->kind = nl_kind_context;
  result->id = 0;

  result->next_dll_id = 0;
  result->next_design_id = 0;
  result->next_library_id = 0;

  result->designs_by_name = ht_alloc (16, ht_hash_string,
				      ht_compare_string, NULL, NULL);
  result->designs_attr = ht_new_attribute (result->designs_by_name,
					   sizeof (nl_design), NULL, NULL);
  result->designs = nl_dll_create (result, nl_kind_design);

  result->libraries_by_name = ht_alloc (16, ht_hash_string,
					ht_compare_string, NULL, NULL);
  result->libraries_attr = ht_new_attribute (result->libraries_by_name,
					   sizeof (nl_library), NULL, NULL);
  result->libraries = nl_dll_create (result, nl_kind_library);

  result->current_design = NULL;

  result->inet_timestamp = 0;

  return result;
}


/**
   Free nl_context 'context'.  All designs associated with this
   context are also freed.
**/
/*exported*/
void
nl_context_free (nl_context context)
{
  FREE (context);
}


/*internal*/
nl_design
nl_context_alloc_design (nl_context context, char *name)
{
  ht_entry hte;
  nl_design result;

  if ( ht_null != ht_lookup (context->designs_by_name, name) ) {
    error ("Attempt to create more than one design named %s.", name);
  }

  result = MALLOC (sizeof (*result));
    
  result->kind = nl_kind_design;
  result->name = STRDUP (name);

  hte = ht_insert (context->designs_by_name, result->name);
  ht_set_attribute_for_entry (context->designs_attr, hte, &result);

  nl_dll_add (context->designs, (nl_dll) result);

  result->id = context->next_design_id;
  context->next_design_id++;

  return result;
}


/*internal*/
nl_library
nl_context_alloc_library (nl_context context, char *name)
{
  ht_entry hte;
  nl_library result;

  if ( ht_null != ht_lookup (context->libraries_by_name, name) ) {
    error ("Attempt to create more than one library named %s.", name);
  }

  result = MALLOC (sizeof (*result));
    
  result->kind = nl_kind_library;
  result->name = STRDUP (name);

  hte = ht_insert (context->libraries_by_name, result->name);
  ht_set_attribute_for_entry (context->libraries_attr, hte, &result);

  nl_dll_add (context->libraries, (nl_dll) result);

  result->id = context->next_library_id;
  context->next_library_id++;

  return result;
}


/**
   Remove design 'design' from context 'context'.  All storage
   associated with the specified design (e.g. cells, nets) is also
   freed.
**/
/*exported*/
void
nl_context_remove_design (nl_context context, nl_design design)
{
  char *design_name = nl_design_name (design);

  nl_context_for_all_designs (context, des) {
    nl_reference ref = nl_design_get_reference_by_name (des, design_name);

    if ( ref != NULL ) {
      nl_reference_unlink (ref);
    }
  } nl_end_for;

  nl_design_for_all_idesigns (design, idesign) {
    nl_idesign_free_tree (idesign);
  } nl_end_for;

  if ( context->current_design == design ) {
    context->current_design = NULL;
  }
  
  ht_delete (context->designs_by_name, design_name);
  nl_dll_remove (context->designs, (nl_dll) design);

  nl_design_free (design);
}


/**
   Remove library 'library' from context 'context'.  All storage
   associated with the specified library (e.g. cells, nets) is also
   freed.
**/
/*exported*/
void
nl_context_remove_library (nl_context context, nl_library library)
{
  char *library_name = nl_library_name (library);

  nl_context_for_all_designs (context, design) {
    nl_design_for_all_references (design, reference) {
      nl_object down_object = nl_reference_down_design (reference);

      if ( down_object != NULL ) {
	nl_kind kind = nl_object_kind (down_object);

	if ( kind == nl_kind_libcell ) {
	  nl_libcell libcell = (nl_libcell) down_object;
	  nl_library lib = nl_libcell_library (libcell);

	  if ( lib == library ) {
	    nl_reference_unlink (reference);
	  }
	}
      }
    } nl_end_for;
  } nl_end_for;

  ht_delete (context->libraries_by_name, library_name);
  nl_dll_remove (context->libraries, (nl_dll) library);

  nl_library_free (library);
}


/*internal*/
void
nl_context_rename_design (nl_context context, nl_design design, char *old_name)
{
  char *new_name = nl_design_name (design);

  ht_replace (context->designs_by_name, old_name, new_name);
}


/*exported*/
void
nl_context_set_current_design (nl_context context, nl_design design)
{
  context->current_design = design;
}


/**
   Return the design in context 'context' whose name is 'name'.  If
   there is no design in the context with that name, return NULL.
**/
/*exported*/
nl_design
nl_context_get_design_by_name (nl_context context, char *name)
{
  nl_design result;

  ht_get_attribute (context->designs_attr, name, &result);

  return result;
}


/*exported*/
nl_library
nl_context_get_library_by_name (nl_context context, char *name)
{
  nl_library result;

  ht_get_attribute (context->libraries_attr, name, &result);

  return result;
}


/*internal*/
int
nl_context_next_dll_id (nl_context context)
{
  int result = context->next_dll_id;

  context->next_dll_id++;

  return result;
}


/*exported*/
int
nl_context_advance_inet_timestamp (nl_context context)
{
  context->inet_timestamp++;

  return context->inet_timestamp;
}
