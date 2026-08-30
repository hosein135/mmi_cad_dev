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
nl_symbol
nl_symbol_create (char *name, nl_type type, nl_wireclass class,
		  nl_subprogram owner)
{
  nl_design design = nl_subprogram_design (owner);
  nl_symbol result = nl_design_alloc_symbol (design, name);

  ASSERT (nl_type_owner (type) == (nl_object) design);

  result->type = type;
  result->owner = owner;
  result->class = class;
  result->constituents = NULL;
  result->binding = NULL;

  return result;
}


/*internal*/
void
nl_symbol_free (nl_symbol sym)
{
  if ( sym->constituents != NULL )
    ar_free (sym->constituents);

  FREE (sym);
}


/*exported*/
void
nl_symbol_add_constituent (nl_symbol symbol, nl_symbol constituent)
{
  ASSERT (nl_type_class (symbol->type) == nl_typeclass_array);

  if ( symbol->constituents == NULL ) {
    symbol->constituents = ar_alloc (1, sizeof (nl_symbol));
  }

  ar_add (symbol->constituents, &constituent);
}


/*exported*/
nl_symbol
nl_symbol_get_constituent (nl_symbol symbol, int offset)
{
  nl_symbol result;

  ASSERT (symbol->constituents);
  ASSERT (offset < ar_size (symbol->constituents));

  ar_ref (symbol->constituents, offset, &result);

  return result;
}


/*exported*/
void
nl_symbol_set_binding (nl_symbol symbol, void *binding)
{
  symbol->binding = binding;
}
