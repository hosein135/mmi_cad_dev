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



/*internal*/
nl_dll_head
nl_dll_create (nl_context context, nl_kind element_kind)
{
  nl_dll_head result = MALLOC (sizeof (*result));

  result->kind = nl_kind_dll_head;
  result->id = nl_context_next_dll_id (context);
  result->next = (nl_dll) result;
  result->prev = (nl_dll) result;
  result->element_kind = element_kind;
  result->num_elements = 0;

  return result;
}


/*internal*/
void
nl_dll_free (nl_dll_head dll)
{
  FREE (dll);
}


/*internal*/
void
nl_dll_add (nl_dll_head dll, nl_dll element)
{
  ASSERT (dll->element_kind == nl_dll_kind (element));

  element->next = (nl_dll) dll;
  element->prev = (nl_dll) dll->prev;
  dll->prev->next = element;
  dll->prev = element;

  dll->num_elements++;
}


/*internal*/
void
nl_dll_insert_after (nl_dll_head dll, nl_dll elt, nl_dll after)
{
  ASSERT (dll->element_kind == nl_dll_kind (after));

  elt->next = after->next;
  elt->prev = after;
  after->next->prev = elt;
  after->next = elt;

  dll->num_elements++;
}


/*internal*/
void
nl_dll_remove (nl_dll_head dll, nl_dll element)
{
  ASSERT (element->kind != nl_kind_dll_head);

  element->prev->next = element->next;
  element->next->prev = element->prev;

  element->next = NULL;
  element->prev = NULL;

  dll->num_elements--;
}


/*exported*/
nl_dll
nl_dll_gen_first (nl_dll_head dll)
{
  ASSERT (nl_dll_head_kind (dll) == nl_kind_dll_head);

  if ( (nl_dll_head) dll->next == dll )
    return NULL;
  else
    return dll->next;
}


/*exported*/
nl_dll
nl_dll_gen_next (nl_dll dll)
{
  ASSERT (dll->next != NULL);

  if ( dll->next->kind == nl_kind_dll_head )
    return NULL;
  else
    return dll->next;
}
