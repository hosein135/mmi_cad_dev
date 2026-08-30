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


pnl_port
pnl_port_create (nl_port port)
{
  pnl_port result = MALLOC (sizeof (*result));

  result->kind = pnl_kind_port;
  result->nl_rep = port;
  result->x.x = 0;
  result->y.valid = 0;
  result->y.y = 0;
  result->orientation = pnl_orientation_none;
  result->use = pnl_use_null;
  result->rectangle = NULL;
  result->loctype = pnl_loctype_null;

  return result;
}


char *
pnl_port_name (pnl_port pport)
{
  nl_port port = pport->nl_rep;
  char *name = nl_port_name (port);

  return name;
}


pnl_design
pnl_port_pdesign (pnl_port pport)
{
  nl_port port = pport->nl_rep;
  nl_design design = nl_port_design (port);
  pnl_design pdesign = NULL;

  nl_design_attr_get_by_name ("pnl design", design, &pdesign);

  return pdesign;
}


void
pnl_port_free (pnl_port port)
{
  pnl_port_clear_geometry (port);
  FREE (port);
}

  
int
pnl_port_has_location (pnl_port pport)
{
  return pport->y.valid;
}


void
pnl_port_set_loctype (pnl_port pport, pnl_loctype loctype)
{
  pport->loctype = loctype;
}

  
void
pnl_port_set_location (pnl_port pport, int x, int y)
{
  pnl_cellx cx;
  pnl_celly cy;

  cx.origin = 0;
  cx.x = x;
  cy.valid = 1;
  cy.y = y;

  pport->x = cx;
  pport->y = cy;
}


void
pnl_port_get_location (pnl_port pport, int *x_p, int *y_p)
{
  pnl_cellx cx = pport->x;
  pnl_celly cy = pport->y;

  if ( cy.valid == 0 ) {
    error ("attempt to get the location of a cell before it has been set");
  }

  *x_p = cx.x;
  *y_p = cy.y;
}


void
pnl_port_set_orientation (pnl_port port, pnl_orientation orientation)
{
  port->orientation = orientation;
}


void
pnl_port_set_geometry (pnl_port pport, char *layer,
		       int x0, int y0, int x1, int y1)
{
  nl_port port = pport->nl_rep;
  nl_design design = nl_port_design (port);
  mem_group group = nl_design_mem_group (design);
  
  if ( pport->rectangle == NULL ) {
    pport->rectangle = GMALLOC (sizeof (*(pport->rectangle)), group);
  }

  pport->rectangle->layer = GSTRDUP (layer, group);

  pport->rectangle->x0 = x0;
  pport->rectangle->y0 = y0;
  pport->rectangle->x1 = x1;
  pport->rectangle->y1 = y1;
}


void
pnl_port_clear_geometry (pnl_port pport)
{
  if ( pport->rectangle != NULL ) {
    pnl_rectangle_free (pport->rectangle);
    pport->rectangle = NULL;
  }
}


int
pnl_port_get_geometry (pnl_port pport, char **layer,
		       int *x0, int *y0, int *x1, int *y1)
{
  if ( pport->rectangle == NULL ) {
    return 0;
  }

  *layer = pport->rectangle->layer;
  *x0 = pport->rectangle->x0;
  *y0 = pport->rectangle->y0;
  *x1 = pport->rectangle->x1;
  *y1 = pport->rectangle->y1;

  return 1;
}


void
pnl_port_set_use (pnl_port pport, pnl_use use)
{
  pport->use = use;
}

