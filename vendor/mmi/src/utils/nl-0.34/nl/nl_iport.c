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
nl_iport
nl_iport_create (nl_port port, nl_ipin up_ipin, nl_idesign idesign)
{
  nl_iport result = nl_idesign_alloc_iport (idesign, port);
  nl_pin pin = nl_port_pin (port);

  result->port = port;
  result->up_pin = up_ipin;

  nl_ipin_create (pin, idesign);

  return result;
}


/*exported*/
char *
nl_iport_name (nl_iport iport)
{
  nl_port port = iport->port;
  char *result = nl_port_name (port);

  return result;
}


/*exported*/
nl_direction
nl_iport_direction (nl_iport iport)
{
  nl_port port = iport->port;
  nl_direction dir = nl_port_direction (port);

  return dir;
}


/*exported*/
nl_ipin
nl_iport_ipin (nl_iport iport)
{
  nl_idesign idesign = iport->idesign;
  nl_port port = iport->port;
  nl_pin pin = nl_port_pin (port);
  nl_ipin ipin = nl_idesign_get_ipin (idesign, pin);

  return ipin;
}


/*internal*/
void
nl_iport_free (nl_iport iport)
{
  nl_idesign idesign = iport->idesign;

  nl_idesign_free_object (idesign, (nl_idesign_object) iport);
}


