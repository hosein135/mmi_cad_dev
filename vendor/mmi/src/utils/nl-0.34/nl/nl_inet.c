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
nl_inet
nl_inet_create (nl_net net, nl_idesign idesign)
{
  nl_inet result = nl_idesign_alloc_inet (idesign, net);

  result->net = net;
  result->timestamp = 0;

  return result;
}


/*internal*/
void
nl_inet_free (nl_inet inet)
{
  nl_idesign idesign = inet->idesign;

  nl_idesign_free_object (idesign, (nl_idesign_object) inet);
}


/*exported*/
char *
nl_inet_name (nl_inet inet)
{
  nl_net net = inet->net;
  char *name = nl_net_name (net);

  return name;
}


/*exported*/
void
nl_inet_set_timestamp (nl_inet inet, int val)
{
  inet->timestamp = val;
}
