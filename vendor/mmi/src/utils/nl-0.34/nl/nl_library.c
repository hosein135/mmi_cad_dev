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
   Create an empty design named 'name' in context 'context'.
**/
/*exported*/
nl_library
nl_library_create (char *name, nl_context context)
{
  mem_group group = mem_group_create (name, 4);
  mem_group prev_group = mem_group_set (group);
  volatile nl_library result = NULL;

  error_unwind_protect {
    result = nl_context_alloc_library (context, name);

    result->mem_group = group;
    result->context = context;

    result->libcells = nl_dll_create (context, nl_kind_libcell);
    result->libcells_by_name = ht_alloc (128, ht_hash_string,
					 ht_compare_string, NULL, NULL);
    result->libcells_attr = ht_new_attribute (result->libcells_by_name,
					      sizeof (nl_libcell),
					      NULL, NULL);

    result->attrs = nl_dll_create (context, nl_kind_attr);
    result->attrs_by_name = ht_alloc (4, ht_hash_string, ht_compare_string,
				      NULL, NULL);
    result->attrs_attr = ht_new_attribute (result->attrs_by_name,
					   sizeof (nl_attr), NULL, NULL);

    result->types = nl_dll_create (context, nl_kind_type);
    result->types_by_name = ht_alloc (4, ht_hash_string, ht_compare_string,
				      NULL, NULL);
    result->types_attr = ht_new_attribute (result->types_by_name,
					   sizeof (nl_type), NULL, NULL);

    result->next_attr_id = 0;
    result->next_libcell_id = 0;
    result->next_libpin_id = 0;
    result->next_type_id = 0;
    result->next_bus_id = 0;
  
  }
  error_on_exit {
    mem_group_set (prev_group);
  }
  error_end;

  return result;
}


/*internal*/
void
nl_library_free (nl_library library)
{
  mem_group_free (library->mem_group);
}


/*internal*/
nl_libcell
nl_library_alloc_libcell (nl_library library, char *name)
{
  ht_entry hte = ht_lookup (library->libcells_by_name, name);

  if ( hte != ht_null ) {
    error ("attempt to create more than one libcell named %s.", name);
  }
  else {
    nl_libcell result = GMALLOC (sizeof (*result), library->mem_group);

    result->kind = nl_kind_libcell;
    result->name = GSTRDUP (name, library->mem_group);

    ht_set_attribute (library->libcells_attr, result->name, &result);

    nl_dll_add (library->libcells, (nl_dll) result);

    result->id = library->next_libcell_id;
    library->next_libcell_id++;

    return result;
  }
}


/*internal*/
nl_libpin
nl_library_alloc_libpin (nl_library library, char *name)
{
  nl_libpin result = GMALLOC (sizeof (*result), library->mem_group);

  result->kind = nl_kind_libpin;
  result->name = GSTRDUP (name, library->mem_group);

  result->id = library->next_libpin_id;
  library->next_libpin_id++;

  return result;
}


/*internal*/
nl_type
nl_library_alloc_type (nl_library library, char *name)
{
  ht_entry hte = ht_lookup (library->types_by_name, name);

  if ( hte != ht_null ) {
    error ("attempt to create more than one type named %s", name);
  }
  else {
    nl_type result = GMALLOC (sizeof (*result), library->mem_group);

    result->kind = nl_kind_type;
    result->name = GSTRDUP (name, library->mem_group);

    ht_set_attribute (library->types_attr, result->name, &result);

    nl_dll_add (library->types, (nl_dll) result);
    
    result->id = library->next_type_id;
    library->next_type_id++;

    return result;
  }
}


/*internal*/
nl_bus
nl_library_alloc_bus (nl_library library, char *name, nl_kind member_kind)
{
  nl_bus result = GMALLOC (sizeof (*result), library->mem_group);

  result->kind = nl_kind_bus;
  result->name = GSTRDUP (name, library->mem_group);

  result->id = library->next_bus_id;
  library->next_bus_id++;

  return result;
}


/*exported*/
nl_libcell
nl_library_get_libcell_by_name (nl_library library, char *name)
{
  nl_libcell result;

  ht_get_attribute (library->libcells_attr, name, &result);

  return result;
}


/*exported*/
nl_type
nl_library_get_type_by_name (nl_library library, char *name)
{
  nl_type result;

  ht_get_attribute (library->types_attr, name, &result);

  return result;
}


/*internal*/
nl_attr
nl_library_alloc_attr (nl_library library, char *name)
{
  nl_attr result = GMALLOC (sizeof (*result), library->mem_group);

  result->kind = nl_kind_attr;

  if ( name != NULL ) {
    ht_entry ent = ht_lookup (library->attrs_by_name, name);

    if ( ent != ht_null ) {
      error ("attempt to create two attributes with the same name, %s, "
	     "in library %s", name, library->name);
    }

    result->name = GSTRDUP (name, library->mem_group);
    ht_set_attribute (library->attrs_attr, result->name, &result);
  }
  else {
    result->name = NULL;
  }

  nl_dll_add (library->attrs, (nl_dll) result);

  return result;
}


/*exported*/
void
nl_library_remove_attr (nl_library library, nl_attr attr)
{
  char *attr_name = nl_attr_name (attr);

  if ( attr_name != NULL ) {
    ht_delete (library->attrs_by_name, attr_name);
  }

  nl_dll_remove (library->attrs, (nl_dll) attr);
  nl_attr_free (attr);
}


/*exported*/
nl_attr
nl_library_get_attr_by_name (nl_library library, char *name)
{
  nl_attr attr;

  ht_get_attribute (library->attrs_attr, name, &attr);

  return attr;
}

