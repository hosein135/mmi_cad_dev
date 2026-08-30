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
nl_ipin
nl_ipin_create (nl_pin pin, nl_idesign idesign)
{
  nl_ipin result = nl_idesign_alloc_ipin (idesign, pin);

  result->pin = pin;

  return result;
}


/*internal*/
void
nl_ipin_free (nl_ipin ipin)
{
  nl_idesign idesign = ipin->idesign;

  nl_idesign_free_object (idesign, (nl_idesign_object) ipin);
}


/*exported*/
char *
nl_ipin_name (nl_ipin ipin)
{
  nl_pin pin = ipin->pin;
  char *name = nl_pin_name (pin);

  return name;
}


/*exported*/
nl_idesign_object
nl_ipin_owner (nl_ipin ipin)
{
  nl_idesign idesign = ipin->idesign;
  nl_pin pin = ipin->pin;
  nl_cell_or_port owner = nl_pin_owner (pin);
  nl_idesign_object result
    = nl_idesign_get_iobject (idesign, (nl_object) owner);

  return result;
}


/*exported*/
nl_inet
nl_ipin_inet (nl_ipin ipin)
{
  nl_idesign idesign = ipin->idesign;
  nl_pin pin = ipin->pin;
  nl_net net = nl_pin_net (pin);
  nl_inet inet;

  if ( net == NULL ) {
    inet = NULL;
  }
  else {
    inet = nl_idesign_get_inet (idesign, net);
  }

  return inet;
}


/*exported*/
nl_direction
nl_ipin_direction (nl_ipin ipin)
{
  nl_pin pin = ipin->pin;
  nl_direction dir = nl_pin_direction (pin);

  return dir;
}


/*exported*/
nl_iport
nl_ipin_down_iport (nl_ipin ipin)
{
  nl_pin pin = ipin->pin;
  nl_idesign_object owner = nl_ipin_owner (ipin);
  nl_icell icell = (nl_icell) owner;
  nl_refpin refpin = nl_pin_refpin (pin);
  nl_object down_port = nl_refpin_down_port (refpin);
  nl_idesign down_idesign;
  nl_iport down_iport;

  if ( nl_idesign_object_kind (owner) != nl_kind_icell ) {
    return NULL;
  }

  if ( down_port == NULL || nl_object_kind (down_port) == nl_kind_libpin ) {
    return NULL;
  }

  down_idesign = nl_icell_down_design (icell);
  down_iport = nl_idesign_get_iport (down_idesign, (nl_port) down_port);

  return down_iport;
}


  
  
  


