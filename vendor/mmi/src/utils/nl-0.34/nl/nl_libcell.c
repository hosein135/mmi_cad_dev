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


/*exported*/
nl_libcell
nl_libcell_create (char *name, nl_library library)
{
  nl_libcell result = nl_library_alloc_libcell (library, name);
  mem_group group = nl_library_mem_group (library);
  mem_group prev_group = mem_group_set (group);
  nl_context context = nl_library_context (library);

  result->library = library;
  result->libpins_by_name
    = ht_alloc_from_group (4, ht_hash_string, ht_compare_string, NULL, NULL, group);
  result->libpins_attr = ht_new_attribute (result->libpins_by_name,
					   sizeof (nl_libpin), NULL, NULL);
  result->libpins = nl_dll_create (context, nl_kind_libpin);
  result->buses = nl_dll_create (context, nl_kind_bus);

  mem_group_set (prev_group);

  return result;
}


/*internal*/
void
nl_libcell_add_libpin (nl_libcell libcell, nl_libpin libpin)
{
  char *name = nl_libpin_name (libpin);
  ht_entry hte = ht_lookup (libcell->libpins_by_name, name);

  if ( hte != ht_null ) {
    error ("Attempt to place two libpins with the same name, %s, "
	   "on libcell %s", name, nl_libcell_name (libcell));
  }
  else {
    ht_set_attribute (libcell->libpins_attr, name, &libpin);
    nl_dll_add (libcell->libpins, (nl_dll) libpin);
  }
}


/*internal*/
void
nl_libcell_add_bus (nl_libcell libcell, nl_bus bus)
{
  char *name = nl_bus_name (bus);
  ht_entry hte = ht_lookup (libcell->libpins_by_name, name);

  if ( hte != ht_null ) {
    error ("Attempt to place two libpins with the same name, %s, "
	   "on libcell %s", name, nl_libcell_name (libcell));
  }
  else {
    ht_set_attribute (libcell->libpins_attr, name, &bus);
    nl_dll_add (libcell->buses, (nl_dll) bus);
  }
}


/*exported*/
nl_object
nl_libcell_get_libpin_by_name (nl_libcell libcell, char *name)
{
  nl_object libpin_or_bus;

  ht_get_attribute (libcell->libpins_attr, name, &libpin_or_bus);

  return libpin_or_bus;
}
