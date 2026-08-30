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
#include "nl_int.h"


/*internal*/
nl_idesign_object
nl_idesign_alloc_object (nl_idesign idesign, nl_kind kind, int size,
			 int *next_id_p, nl_free_object *free_list_p)
{
  nl_design design = idesign->design;
  mem_group design_group = nl_design_mem_group (design);
  nl_idesign_object result;

  if ( free_list_p != NULL && *free_list_p != NULL ) {
    nl_free_object obj = *free_list_p;
    result = (nl_idesign_object) obj;
    *free_list_p = (*free_list_p)->next;
  }
  else {
    result = GMALLOC (size, design_group);
    result->id = *next_id_p;
    (*next_id_p)++;
  }

  result->kind = kind;
  result->idesign = idesign;

  return result;
}


/*internal*/
nl_icell
nl_idesign_alloc_icell (nl_idesign idesign, nl_cell cell)
{
  nl_icell result 
    = (nl_icell) nl_idesign_alloc_object (idesign, nl_kind_icell,
					  sizeof (*result),
					  &(idesign->next_icell_id),
					  &(idesign->free_icells));

  nl_cell_attr_set (idesign->cell_attr, cell, &result);

  return result;
}


/*internal*/
nl_inet
nl_idesign_alloc_inet (nl_idesign idesign, nl_net net)
{
  nl_inet result 
    = (nl_inet) nl_idesign_alloc_object (idesign, nl_kind_inet,
					 sizeof (*result),
					 &(idesign->next_inet_id),
					 &(idesign->free_inets));

  nl_net_attr_set (idesign->net_attr, net, &result);

  return result;
}


/*internal*/
nl_ipin
nl_idesign_alloc_ipin (nl_idesign idesign, nl_pin pin)
{
  nl_ipin result 
    = (nl_ipin) nl_idesign_alloc_object (idesign, nl_kind_ipin,
					 sizeof (*result),
					 &(idesign->next_ipin_id),
					 &(idesign->free_ipins));

  nl_pin_attr_set (idesign->pin_attr, pin, &result);

  return result;
}


/*internal*/
nl_iport
nl_idesign_alloc_iport (nl_idesign idesign, nl_port port)
{
  nl_iport result 
    = (nl_iport) nl_idesign_alloc_object (idesign, nl_kind_iport,
					  sizeof (*result),
					  &(idesign->next_iport_id),
					  &(idesign->free_iports));

  nl_port_attr_set (idesign->port_attr, port, &result);

  return result;
}


/*exported*/
nl_attr
nl_idesign_alloc_attr (nl_idesign idesign, char *name)
{
  nl_design design = idesign->design;
  mem_group design_group = nl_design_mem_group (design);
  nl_attr result = (nl_attr)
    nl_idesign_alloc_object (idesign, nl_kind_attr, sizeof (*result),
			     &idesign->next_attr_id, NULL);

  if ( name != NULL ) {
    ht_entry ent = ht_lookup (idesign->attrs_by_name, name);

    if ( ent != ht_null ) {
      error ("attempt to create two attributes with the same name, %s, "
	     "in idesign for %s", name, nl_design_name (design));
    }

    result->name = GSTRDUP (name, design_group);
    ht_set_attribute (idesign->attrs_attr, result->name, &result);
  }
  else {
    result->name = NULL;
  }

  nl_dll_add (idesign->attrs, (nl_dll) result);

  return result;
}  


/*exported*/
nl_attr
nl_idesign_get_attr_by_name (nl_idesign idesign, char *name)
{
  nl_attr attr;

  ht_get_attribute (idesign->attrs_attr, name, &attr);

  return attr;
}



/*internal*/
void
nl_idesign_free_object (nl_idesign idesign, nl_idesign_object object)
{
  nl_kind kind = nl_idesign_object_kind (object);
  nl_free_object free_obj = (nl_free_object) object;

  switch ( kind ) {
  case nl_kind_icell:
    free_obj->kind = nl_kind_free_icell;
    free_obj->next = idesign->free_icells;
    idesign->free_icells = free_obj;
    break;
  case nl_kind_inet:
    free_obj->kind = nl_kind_free_inet;
    free_obj->next = idesign->free_inets;
    idesign->free_inets = free_obj;
    break;
  case nl_kind_ipin:
    free_obj->kind = nl_kind_free_ipin;
    free_obj->next = idesign->free_ipins;
    idesign->free_ipins = free_obj;
    break;
  case nl_kind_iport:
    free_obj->kind = nl_kind_free_iport;
    free_obj->next = idesign->free_iports;
    idesign->free_iports = free_obj;
    break;
  default:
    ASSERT (0);
  }
}


/*exported*/
nl_idesign_object
nl_idesign_get_iobject (nl_idesign idesign, nl_object obj)
{
  nl_kind kind = nl_object_kind (obj);
  
  switch ( kind ) {
  case nl_kind_cell: {
    nl_cell cell = (nl_cell) obj;
    nl_icell icell = nl_idesign_get_icell (idesign, cell);
    return (nl_idesign_object) icell;
  }
  case nl_kind_net: {
    nl_net net = (nl_net) obj;
    nl_inet inet = nl_idesign_get_inet (idesign, net);
    return (nl_idesign_object) inet;
  }
  case nl_kind_pin: {
    nl_pin pin = (nl_pin) obj;
    nl_ipin ipin = nl_idesign_get_ipin (idesign, pin);
    return (nl_idesign_object) ipin;
  }
  case nl_kind_port: {
    nl_port port = (nl_port) obj;
    nl_iport iport = nl_idesign_get_iport (idesign, port);
    return (nl_idesign_object) iport;
  }
  default:
    ASSERT (0);
  }
}


/*exported*/
nl_icell
nl_idesign_get_icell (nl_idesign idesign, nl_cell cell)
{
  nl_icell icell;
  nl_cell_attr_get (idesign->cell_attr, cell, &icell);

  return icell;
}


/*exported*/
nl_inet
nl_idesign_get_inet (nl_idesign idesign, nl_net net)
{
  nl_inet inet;
  nl_net_attr_get (idesign->net_attr, net, &inet);

  return inet;
}


/*exported*/
nl_ipin
nl_idesign_get_ipin (nl_idesign idesign, nl_pin pin)
{
  nl_ipin ipin;
  nl_pin_attr_get (idesign->pin_attr, pin, &ipin);

  return ipin;
}


/*exported*/
nl_iport
nl_idesign_get_iport (nl_idesign idesign, nl_port port)
{
  nl_iport iport;
  nl_port_attr_get (idesign->port_attr, port, &iport);

  return iport;
}


/*exported*/
nl_icell
nl_idesign_get_icell_by_name (nl_idesign idesign, char *name)
{
  nl_design design = idesign->design;
  nl_cell cell = nl_design_get_cell_by_name (design, name);

  if ( cell == NULL ) {
    return NULL;
  }
  else {
    nl_icell icell = nl_idesign_get_icell (idesign, cell);

    return icell;
  }
}


/*exported*/
nl_inet
nl_idesign_get_inet_by_name (nl_idesign idesign, char *name)
{
  nl_design design = idesign->design;
  nl_net net = nl_design_get_net_by_name (design, name);

  if ( net == NULL ) {
    return NULL;
  }
  else {
    nl_inet inet = nl_idesign_get_inet (idesign, net);

    return inet;
  }
}


/*exported*/
nl_iport
nl_idesign_get_iport_by_name (nl_idesign idesign, char *name)
{
  nl_design design = idesign->design;
  nl_object port_or_bus = nl_design_get_port_by_name (design, name);

  if ( port_or_bus == NULL ) {
    return NULL;
  }
  if ( nl_object_kind (port_or_bus) != nl_kind_port ) {
    return NULL;
  }
  else {
    nl_port port = (nl_port) port_or_bus;
    nl_iport iport = nl_idesign_get_iport (idesign, port);

    return iport;
  }
}


static
void
nl_idesign_free_icell_attr (void *ptr)
{
  nl_icell icell = *(nl_icell *)ptr;

  if ( icell != NULL ) {
    nl_icell_free (icell);
  }
}


static
void
nl_idesign_free_inet_attr (void *ptr)
{
  nl_inet inet = *(nl_inet *)ptr;

  if ( inet != NULL ) {
    nl_inet_free (inet);
  }
}


static
void
nl_idesign_free_ipin_attr (void *ptr)
{
  nl_ipin ipin = *(nl_ipin *)ptr;

  if ( ipin != NULL ) {
    nl_ipin_free (ipin);
  }
}


static
void
nl_idesign_free_iport_attr (void *ptr)
{
  nl_iport iport = *(nl_iport *)ptr;

  if ( iport != NULL ) {
    nl_iport_free (iport);
  }
}


/*exported*/
nl_idesign
nl_idesign_get_or_create (nl_design design, nl_icell icell)
{
  if ( icell == NULL ) {
    nl_dll_head idesigns = nl_design_idesigns (design);
    int num = nl_dll_head_num_elements (idesigns);

    if ( num == 0 ) {
      nl_idesign idesign = nl_idesign_create (design, NULL, NULL);

      return idesign;
    }
    else if ( num == 1 ) {
      nl_dll first = nl_dll_gen_first (idesigns);

      return (nl_idesign) first;
    }
    else {
      error ("attempt to the get idesign of a design with multiple idesigns.");
    }
  }
  else {
    nl_idesign down_idesign = nl_icell_down_design (icell);
    nl_design down_design = down_idesign->design;

    if ( down_design != design ) {
      error ("down design of icell does not match the first argument to "
	     "nl_idesign_get_or_create.");
    }

    return down_idesign;
  }
}


/*exported*/
nl_idesign
nl_idesign_create (nl_design design, nl_icell icell, nl_predicate pred)
{
  mem_group design_group = nl_design_mem_group (design);
  nl_context context = nl_design_context (design);
  nl_idesign result = nl_design_alloc_idesign (design);

  result->design = design;
  
  result->cell_attr
    = nl_cell_attr_create (NULL, design, nl_density_dense, sizeof (nl_icell),
			   NULL, nl_idesign_free_icell_attr);

  result->net_attr
    = nl_net_attr_create (NULL, design, nl_density_dense, sizeof (nl_inet),
			  NULL, nl_idesign_free_inet_attr);

  result->pin_attr
    = nl_pin_attr_create (NULL, design, nl_density_dense, sizeof (nl_inet),
			  NULL, nl_idesign_free_ipin_attr);

  result->port_attr
    = nl_port_attr_create (NULL, design, nl_density_dense, sizeof (nl_inet),
			   NULL, nl_idesign_free_iport_attr);

  result->icell = icell;
  result->next_icell_id = 0;
  result->next_inet_id = 0;
  result->next_ipin_id = 0;
  result->next_iport_id = 0;
  result->next_attr_id = 0;

  result->free_icells = NULL;
  result->free_inets = NULL;
  result->free_ipins = NULL;
  result->free_iports = NULL;

  {
    mem_group prev_group = mem_group_set (design_group);

    result->attrs = nl_dll_create (context, nl_kind_attr);
    mem_group_set (prev_group);
  }

  /* attributes */
  result->attrs_by_name = ht_alloc_from_group (4, ht_hash_string, ht_compare_string,
					       NULL, NULL, design_group);
  result->attrs_attr = ht_new_attribute (result->attrs_by_name,
					 sizeof (nl_attr), NULL, NULL);

  nl_design_for_all_cells (design, cell) {
    nl_icell_create (cell, result, pred);
  } nl_end_for;

  nl_design_for_all_nets (design, net) {
    nl_inet_create (net, result);
  } nl_end_for;

  {
    nl_cell cell = NULL;
    nl_reference reference = NULL;

    if ( icell != NULL ) {
      cell = nl_icell_cell (icell);
      reference = nl_cell_reference (cell);
    }

    nl_design_for_all_ports (design, port) {
      nl_ipin up_ipin = NULL;

      if ( icell != NULL ) {
	char *port_name = nl_port_name (port);
	nl_object refpin
	  = nl_reference_get_refpin_by_name (reference, port_name);

	ASSERT (refpin != NULL && nl_object_kind (refpin) == nl_kind_refpin);

	up_ipin = nl_icell_get_ipin_by_refpin (icell, (nl_refpin) refpin);
      }

      nl_iport_create (port, up_ipin, result);
    } nl_end_for;
  }

  return result;
}


static
void
nl_idesign_free (nl_idesign idesign)
{
  nl_dll_for_all (idesign->attrs, nl_attr, attr) {
    nl_attr_free (attr);
  } nl_end_for;

  nl_dll_free (idesign->attrs);
  ht_free (idesign->attrs_by_name);

  nl_design_remove_attr (idesign->design, (nl_attr) idesign->cell_attr);
  nl_design_remove_attr (idesign->design, (nl_attr) idesign->net_attr);
  nl_design_remove_attr (idesign->design, (nl_attr) idesign->port_attr);
  nl_design_remove_attr (idesign->design, (nl_attr) idesign->pin_attr);

  nl_design_free_freelist (idesign->free_ipins);
  nl_design_free_freelist (idesign->free_inets);
  nl_design_free_freelist (idesign->free_icells);
  nl_design_free_freelist (idesign->free_iports);

  nl_design_free_idesign (idesign->design, idesign);
}  


/*internal*/
void
nl_idesign_unlink (nl_idesign idesign)
{
  nl_icell icell = nl_idesign_icell (idesign);

  nl_icell_unlink (icell);

  nl_idesign_for_all_icells (idesign, icell) {
    nl_idesign down_idesign = nl_icell_down_design (icell);

    if ( down_idesign != NULL ) {
      ASSERT (down_idesign->icell == icell);
      down_idesign->icell = NULL;
    }
  } nl_end_for;
}


/*exported*/
void
nl_idesign_free_tree (nl_idesign idesign)
{
  if ( idesign->icell != NULL ) {
    nl_icell_unlink (idesign->icell);
    idesign->icell = NULL;
  }

  nl_idesign_for_all_icells (idesign, icell) {
    nl_idesign down_idesign = nl_icell_down_design (icell);

    if ( down_idesign != NULL ) {
      nl_idesign_free_tree (down_idesign);
    }
  } nl_end_for;

  nl_idesign_free (idesign);
}


/*exported*/
char *
nl_idesign_name (nl_idesign idesign)
{
  nl_design design = idesign->design;
  char *result = nl_design_name (design);

  return result;
}


/*internal*/
int
nl_idesign_max_id (nl_idesign idesign, nl_kind kind)
{
  switch ( kind ) {
  case nl_kind_iport:
    return idesign->next_iport_id;
  case nl_kind_icell:
    return idesign->next_icell_id;
  case nl_kind_inet:
    return idesign->next_inet_id;
  case nl_kind_ipin:
    return idesign->next_ipin_id;
  default:
    ASSERT (0);
  }
}


/**
   Remove attribute 'attr' from design 'design'.  The attribute is
   removed from any object to which it is attached; all the storage
   associated with the attribute is freed; and the attribute itself is
   freed.  Any further reference to this attribute is invalid.
**/
/*exported*/
void
nl_idesign_remove_attr (nl_idesign idesign, nl_attr attr)
{
  char *attr_name = nl_attr_name (attr);

  if ( attr_name != NULL ) {
    ht_delete (idesign->attrs_by_name, attr_name);
  }
  nl_dll_remove (idesign->attrs, (nl_dll) attr);
  nl_attr_free (attr);
}
