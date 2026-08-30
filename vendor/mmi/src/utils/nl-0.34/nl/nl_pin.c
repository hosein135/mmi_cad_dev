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


/**
   Create a new pin corresponding to 'refpin' on cell or port
   'cell_or_port'.  If 'cell_or_port' is a port, 'refpin' should be
   NULL.  It generally should not be necessary to call this routine,
   since pins are created on cells and ports with they are created.
**/
/*exported*/
nl_pin
nl_pin_create (nl_refpin refpin, nl_cell_or_port cell_or_port)
{
  nl_design design = nl_cell_or_port_design (cell_or_port);
  nl_pin result = nl_design_alloc_pin (design);

  result->owner = cell_or_port;
  result->refpin = refpin;
  result->net = NULL;

  if ( nl_cell_or_port_kind (cell_or_port) == nl_kind_cell ) {
    nl_cell_add_pin ((nl_cell) cell_or_port, result);
  }

  nl_design_for_all_idesigns (design, idesign) {
    nl_ipin_create (result, idesign);
  } nl_end_for;

  return result;
}


/*internal*/
void
nl_pin_free (nl_pin pin)
{
  nl_cell_or_port owner = pin->owner;
  nl_design design = nl_cell_or_port_design (owner);
  
  nl_design_free_object (design, (nl_object) pin);
}


/*exported*/
char *
nl_pin_name (nl_pin pin)
{
  nl_refpin refpin = pin->refpin;

  if ( refpin != NULL ) {
    char *name = nl_refpin_name (refpin);

    return name;
  }
  else {
    nl_cell_or_port owner = pin->owner;
    nl_port port;
    char *name;

    ASSERT (owner != NULL && nl_cell_or_port_kind (owner) == nl_kind_port);

    port = (nl_port) owner;
    name = nl_port_name (port);

    return name;
  }
}


/**
   Connect pin 'pin' to net 'net'.  Depending on its direction, the
   pin will be added to the fanouts, fanins, or fanios of the net.  If
   the direction of the pin is unknown, it will be added to the fanios
   of the net.
**/
/*exported*/
void
nl_pin_connect_net (nl_pin pin, nl_net net)
{
  if ( pin->net != NULL ) {
    nl_net_remove_pin (pin->net, pin);
  }
  pin->net = net;
  nl_net_add_pin (net, pin);
}


/**
   Disconnect pin 'pin' from any net it is currently connected to.
**/
/*exported*/
void
nl_pin_disconnect (nl_pin pin)
{
  nl_net net = pin->net;
  if ( net != NULL ) {
    nl_net_remove_pin (net, pin);
    pin->net = NULL;
  }
}


/**
   Return the direction of pin 'pin'.
**/
/*exported*/
nl_direction
nl_pin_direction (nl_pin pin)
{
  nl_cell_or_port owner = pin->owner;

  if ( nl_cell_or_port_kind (owner) == nl_kind_cell ) {
    nl_refpin refpin = pin->refpin;
    nl_direction direction = nl_refpin_direction (refpin);
    return direction;
  }
  else {
    nl_port port = (nl_port) owner;
    nl_direction port_direction = nl_port_direction (port);
    nl_direction pin_direction = nl_direction_reverse (port_direction);
    return pin_direction;
  }
}


/*internal*/
void
nl_pin_half_disconnect (nl_pin pin)
{
  nl_net net = pin->net;
  if ( net != NULL ) {
    nl_net_remove_pin (net, pin);
  }
}


/*internal*/
void
nl_pin_half_reconnect (nl_pin pin)
{
  nl_net net = pin->net;
  if ( net != NULL ) {
    nl_net_add_pin (net, pin);
  }
}
