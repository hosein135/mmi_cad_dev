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
#include "skip-list.h"
#include "pnl.h"
#include "pnl_int.h"


pnl_net_data
pnl_net_data_create (nl_kind kind)
{
  pnl_net_data result = MALLOC (sizeof (*result));

  result->kind = kind;
  result->routes = NULL;
  result->use = pnl_use_null;
  result->pattern = pnl_pattern_null;
  result->special = 0;

  return result;
}


void
pnl_net_data_free (pnl_net_data data)
{
  FREE (data);
}


pnl_inet
pnl_inet_create (nl_inet inet)
{
  pnl_net_data data = pnl_net_data_create (pnl_kind_inet);
  pnl_inet result = (pnl_inet) data;

  result->nl_rep = inet;

  return result;
}


pnl_net
pnl_net_create (nl_net net)
{
  pnl_net_data data = pnl_net_data_create (pnl_kind_net);
  pnl_net result = (pnl_net) data;

  result->nl_rep = net;

  return result;
}
     

char *
pnl_inet_name (pnl_inet pinet)
{
  nl_inet inet = pinet->nl_rep;
  char *name = nl_inet_name (inet);

  return name;
}


char *
pnl_net_name (pnl_net pnet)
{
  nl_net net = pnet->nl_rep;
  char *name = nl_net_name (net);

  return name;
}


pnl_idesign
pnl_inet_pidesign (pnl_inet pinet)
{
  nl_inet inet = pinet->nl_rep;
  nl_idesign idesign = nl_inet_idesign (inet);
  pnl_idesign pidesign = NULL;

  nl_idesign_attr_get_by_name ("pnl idesign", idesign, &pidesign);

  return pidesign;
}


void
pnl_inet_free (pnl_inet pinet)
{
  pnl_net_data_free ((pnl_net_data) pinet);
}


void
pnl_net_free (pnl_net pnet)
{
  pnl_net_data_free ((pnl_net_data) pnet);
}


void
pnl_inet_add_route (pnl_inet pinet, pnl_route route)
{
  if ( pinet->routes == NULL ) {
    pinet->routes = pnl_dll_create ();
  }

  pnl_dll_add (pinet->routes, (pnl_dll) route);
}


void
pnl_net_add_route (pnl_net pnet, pnl_route route)
{
  if ( pnet->routes == NULL ) {
    pnet->routes = pnl_dll_create ();
  }

  pnl_dll_add (pnet->routes, (pnl_dll) route);
}


void
pnl_inet_set_use (pnl_inet pinet, pnl_use use)
{
  pinet->use = use;
}


void
pnl_net_set_use (pnl_net pnet, pnl_use use)
{
  pnet->use = use;
}


void
pnl_inet_set_pattern (pnl_inet pinet, pnl_pattern pattern)
{
  pinet->pattern = pattern;
}


void
pnl_net_set_pattern (pnl_net pnet, pnl_pattern pattern)
{
  pnet->pattern = pattern;
}


void
pnl_net_set_special (pnl_net pnet, int special)
{
  pnet->special = special;
}


void
pnl_inet_set_special (pnl_inet pinet, int special)
{
  pinet->special = special;
}
