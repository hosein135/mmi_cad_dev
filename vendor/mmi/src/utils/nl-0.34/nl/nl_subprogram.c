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
nl_subprogram
nl_subprogram_create (char *name, nl_type type, nl_design design)
{
  nl_context context = nl_design_context (design);
  nl_subprogram result = nl_design_alloc_subprogram (design, name);

  result->design = design;
  result->type = type;
  result->symbols_by_name = ht_alloc (4, ht_hash_string, ht_compare_string,
				      NULL, NULL);
  result->symbols_attr = ht_new_attribute (result->symbols_by_name,
					   sizeof (nl_symbol), NULL, NULL);
  result->pragmas = NULL;
  result->formals = nl_dll_create (context, nl_kind_symbol);
  result->locals = nl_dll_create (context, nl_kind_symbol);
  result->body = NULL;

  return result;
}


/*internal*/
void
nl_subprogram_free (nl_subprogram subr)
{
  ht_for_all_entries (subr->symbols_by_name, ent) {
    nl_symbol sym;
    
    ht_get_attribute_for_entry (subr->symbols_attr, ent, &sym);
    nl_symbol_free (sym);
  } ht_end_for;

  ht_free (subr->symbols_by_name);

  nl_dll_free (subr->formals);
  nl_dll_free (subr->locals);

  if ( subr->pragmas != NULL ) {
    nl_ast_free_tree (subr->pragmas);
  }

  if ( subr->body != NULL ) {
    nl_ast_free_tree (subr->body);
  }

  FREE (subr);
}


/*exported*/
void
nl_subprogram_set_pragmas (nl_subprogram subprogram, nl_ast pragmas)
{
  subprogram->pragmas = pragmas;
}


/*exported*/
void
nl_subprogram_set_body (nl_subprogram subprogram, nl_ast body)
{
  subprogram->body = body;
}


/*exported*/
void
nl_subprogram_add_formal (nl_subprogram subprogram, nl_symbol symbol)
{
  char *name = nl_symbol_name (symbol);

  ht_set_attribute (subprogram->symbols_attr, name, &symbol);
  nl_dll_add (subprogram->formals, (nl_dll) symbol);
}


/*exported*/
void
nl_subprogram_add_local (nl_subprogram subprogram, nl_symbol symbol)
{
  char *name = nl_symbol_name (symbol);

  ht_set_attribute (subprogram->symbols_attr, name, &symbol);
  nl_dll_add (subprogram->locals, (nl_dll) symbol);
}


/*exported*/
int
nl_subprogram_num_formals (nl_subprogram subprogram)
{
  int result = nl_dll_head_num_elements (subprogram->formals);

  return result;
}


/*exported*/
void
nl_subprogram_add_symbol (nl_subprogram subprogram, nl_symbol symbol)
{
  char *name = nl_symbol_name (symbol);

  ht_set_attribute (subprogram->symbols_attr, name, &symbol);
}


/*exported*/
nl_symbol
nl_subprogram_get_symbol_by_name (nl_subprogram subprogram, char *name)
{
  nl_symbol symbol;
  
  ht_get_attribute (subprogram->symbols_attr, name, &symbol);

  return symbol;
}
