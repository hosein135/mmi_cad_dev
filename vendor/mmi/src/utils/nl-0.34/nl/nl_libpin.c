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
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "nl.h"
#include "nl_int.h"


/*exported*/
nl_libpin
nl_libpin_create (char *name, nl_direction direction, nl_libcell libcell)
{
  nl_library library = nl_libcell_library (libcell);
  nl_libpin result = nl_library_alloc_libpin (library, name);

  nl_libcell_add_libpin (libcell, result);

  result->libcell = libcell;
  result->bus = NULL;
  result->direction = direction;
  result->use = nl_use_null;

  return result;
}


/*exported*/
void
nl_libpin_set_direction (nl_libpin libpin, nl_direction direction)
{
  libpin->direction = direction;
}


/*exported*/
void
nl_libpin_set_use (nl_libpin libpin, nl_use use)
{
  libpin->use = use;
}


/*exported*/
void
nl_libpin_set_bus_and_offset (nl_libpin libpin, nl_bus bus, int offset)
{
  libpin->bus = bus;
  libpin->bus_offset = offset;
}


/*exported*/
void
nl_libpin_set_capacitance (nl_libpin libpin, float cap)
{
  libpin->capacitance = cap;
}
