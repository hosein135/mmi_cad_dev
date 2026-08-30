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
#include "skip-list.h"
#include "pnl.h"
#include "pnl_int.h"


pnl_dll_head
pnl_dll_create (void)
{
  pnl_dll_head result = MALLOC (sizeof (*result));

  result->next = (pnl_dll) result;
  result->prev = (pnl_dll) result;
  result->num_elements = 0;

  return result;
}


void
pnl_dll_add (pnl_dll_head head, pnl_dll dll)
{
  dll->next = (pnl_dll) head;
  dll->prev = (pnl_dll) head->prev;
  head->prev->next = dll;
  head->prev = dll;

  head->num_elements++;
}


void
pnl_dll_remove (pnl_dll_head head, pnl_dll dll)
{
  dll->prev->next = dll->next;
  dll->next->prev = dll->prev;
  dll->next = NULL;
  dll->prev = NULL;

  head->num_elements--;
}


pnl_dll
pnl_dll_gen_first (pnl_dll_head head)
{
  pnl_dll next = head->next;

  if ( next == (pnl_dll) head )
    return NULL;
  else
    return next;
}


pnl_dll
pnl_dll_gen_next (pnl_dll_head head, pnl_dll dll)
{
  pnl_dll next = dll->next;

  ASSERT (next != NULL);

  if ( next == (pnl_dll) head )
    return NULL;
  else
    return next;
}


void
pnl_dll_free (pnl_dll_head head)
{
  FREE (head);
}
