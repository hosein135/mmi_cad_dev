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



/*exported*/
void
nl_design_set_libcell (nl_design design, int flag)
{
  design->libcell = flag;
}


/**
   Create an empty design named 'name' in context 'context'.
**/
/*exported*/
nl_design
nl_design_create (char *name, nl_context context)
{
  mem_group group = mem_group_create (name, 4);
  mem_group prev_group = mem_group_set (group);
  volatile nl_design result;

  error_unwind_protect {
    result = nl_context_alloc_design (context, name);

    result->mem_group = group;
    result->context = context;
    result->bus_naming_style = NULL;
    result->libcell = 0;

    result->ports = nl_dll_create (context, nl_kind_port);
    result->port_buses = nl_dll_create (context, nl_kind_bus);
    result->cells = nl_dll_create (context, nl_kind_cell);
    result->cell_buses = nl_dll_create (context, nl_kind_bus);
    result->nets =nl_dll_create (context, nl_kind_net);
    result->net_buses = nl_dll_create (context, nl_kind_bus);
    result->references = nl_dll_create (context, nl_kind_reference);
    result->types = nl_dll_create (context, nl_kind_type);
    result->attrs = nl_dll_create (context, nl_kind_attr);
    result->subprograms = nl_dll_create (context, nl_kind_subprogram);
    result->idesigns = nl_dll_create (context, nl_kind_idesign);

    result->supply0s = AR_NEW (4, nl_object);
    result->supply1s = AR_NEW (4, nl_object);

    /* nets, net_buses, cells, cell buses */
    result->objects_by_name = ht_alloc (64, ht_hash_string,
					ht_compare_string, NULL, NULL);
    result->objects_attr = ht_new_attribute (result->objects_by_name,
					     sizeof (nl_named_object),
					     NULL, NULL);

    /* references */
    result->references_by_name = ht_alloc (32, ht_hash_string,
					   ht_compare_string, NULL, NULL);
    result->references_attr = ht_new_attribute (result->references_by_name,
						sizeof (nl_reference),
						NULL, NULL);

    /* ports, port_buses */
    result->ports_by_name = ht_alloc (32, ht_hash_string,
				      ht_compare_string, NULL, NULL);
    result->ports_attr = ht_new_attribute (result->ports_by_name,
					   sizeof (nl_named_object), NULL, NULL);

    /* types */
    result->types_by_name = ht_alloc (32, ht_hash_string, ht_compare_string,
				      NULL, NULL);
    result->types_attr = ht_new_attribute (result->types_by_name,
					   sizeof (nl_type), NULL, NULL);

    /* attributes */
    result->attrs_by_name = ht_alloc (4, ht_hash_string, ht_compare_string,
				      NULL, NULL);
    result->attrs_attr = ht_new_attribute (result->attrs_by_name,
					   sizeof (nl_attr), NULL, NULL);

    /* subprograms (functions and tasks) */
    result->subprograms_by_name = ht_alloc (4, ht_hash_string, ht_compare_string,
					    NULL, NULL);
    result->subprograms_attr = ht_new_attribute (result->subprograms_by_name,
						 sizeof (nl_attr), NULL, NULL);

    result->free_ports = NULL;
    result->free_cells = NULL;
    result->free_nets = NULL;
    result->free_pins = NULL;

    result->next_port_id = 0;
    result->next_cell_id = 0;
    result->next_net_id = 0;
    result->next_bus_id = 0;
    result->next_reference_id = 0;
    result->next_refpin_id = 0;
    result->next_pin_id = 0;
    result->next_type_id = 0;
    result->next_attr_id = 0;
    result->next_subprogram_id = 0;
    result->next_symbol_id = 0;
    result->next_idesign_id = 0;

  }
  error_on_exit {
    mem_group_set (prev_group);
  }
  error_end;

  return result;
}


/*internal*/
void
nl_design_free_freelist (nl_free_object obj)
{
  nl_free_object list = obj;

  while ( list != NULL ) {
    nl_free_object next = list->next;
    FREE (list);
    list = next;
  }
}


/**
   Free design 'design' along with all its contents.
**/
/*internal*/
void
nl_design_free (nl_design design)
{
  mem_group_free (design->mem_group);
}


/*internal*/
void
nl_design_free_object (nl_design design, nl_object obj)
{
  nl_kind kind = nl_object_kind (obj);
  nl_free_object free_obj = (nl_free_object) obj;

  switch ( kind ) {

  case nl_kind_port:
    free_obj->kind = nl_kind_free_port;
    free_obj->next = design->free_ports;
    design->free_ports = free_obj;
    break;

  case nl_kind_cell:
    free_obj->kind = nl_kind_free_cell;
    free_obj->next = design->free_cells;
    design->free_cells = free_obj;
    break;

  case nl_kind_net:
    free_obj->kind = nl_kind_free_net;
    free_obj->next = design->free_nets;
    design->free_nets = free_obj;
    break;

  case nl_kind_pin:
    free_obj->kind = nl_kind_free_pin;
    free_obj->next = design->free_pins;
    design->free_pins = free_obj;
    break;

  default:
    FREE (free_obj);
  }
}


static
nl_object
nl_design_alloc_object (nl_design design, char *name, nl_kind object_kind,
			int size, int *next_id_p, nl_free_object *free_list_p,
			hashtab table, ht_attr table_attr, nl_dll_head dll)
{
  nl_object result = NULL;

  if ( table != NULL && name != NULL ) {
    ht_entry hte = ht_lookup (table, name);

    if ( hte != ht_null ) {
      error ("attempt to create two objects with the same name -> %s", name);
    }
  }

  if ( free_list_p != NULL ) {
    if ( *free_list_p == NULL ) {
      goto malloc_it;
    }
    else {
      nl_free_object obj = *free_list_p;
      result = (nl_object)obj;
      *free_list_p = (*free_list_p)->next;
    }
  }
  else {
  malloc_it:
    result = GMALLOC (size, design->mem_group);
    result->id = *next_id_p;
    (*next_id_p)++;
  }

  result->kind = object_kind;
  
  /* There are three cases here:
     1. if name == NULL and table == NULL, it's not a named object
     2. if name == NULL and table != NULL, it's a named object with a NULL
        name
     3. if name != NULL and table != NULL, it's a named object with a name
  */
  if ( name != NULL ) {
    ((nl_named_object) result)->name = STRDUP (name);
  }
  else if ( table != NULL ) {
    ((nl_named_object) result)->name = NULL;
  }

  if ( table != NULL && name != NULL ) {
    ht_entry hte = ht_insert (table, ((nl_named_object) result)->name);
    ht_set_attribute_for_entry (table_attr, hte, &result);
  }

  if ( dll != NULL ) {
    nl_dll_add (dll, (nl_dll) result);
  }

  if ( object_kind != nl_kind_attr ) {
    nl_design_for_all_attributes (design, attr) {
      if ( (nl_object) attr != result ) {
	if ( nl_attr_attr_of (attr) == object_kind ) {
	  nl_attr_initialize (attr, (nl_object) result);
	}
      }
    } nl_end_for;
  }

  return result;
}


/*internal*/
nl_port
nl_design_alloc_port (nl_design design, char *name)
{
  nl_port result = (nl_port)
    nl_design_alloc_object (design, name, nl_kind_port, sizeof (*result),
			    &design->next_port_id, &design->free_ports,
			    design->ports_by_name, design->ports_attr,
			    design->ports);

  return result;
}

  
/*internal*/
nl_cell
nl_design_alloc_cell (nl_design design, char *name)
{
  nl_cell result = (nl_cell)
    nl_design_alloc_object (design, name, nl_kind_cell, sizeof (*result),
			    &design->next_cell_id, &design->free_cells,
			    design->objects_by_name, design->objects_attr,
			    design->cells);

  return result;
}


/**
   Remove cell 'cell' from design 'design'.  All the cell's pins will
   be disconnected; all references to the cell are removed from the
   design; and the cell itself is freed.  Any further reference to
   this cell is invalid.
**/
/*exported*/
void
nl_design_remove_cell (nl_design design, nl_cell cell)
{
  char *cell_name = nl_cell_name (cell);
  nl_bus cell_bus = nl_cell_bus (cell);

  if ( cell_bus != NULL ) {
    nl_design_remove_cell_bus (design, cell_bus, 0);
  }

  ht_delete (design->objects_by_name, cell_name);
  nl_dll_remove (design->cells, (nl_dll) cell);
  nl_cell_disconnect (cell);
  nl_cell_free (cell);
}


/**
   Remove port 'port' from design 'design'.  The port's pin will
   be disconnected; all references to the port are removed from the
   design; and the port itself is freed.  Any further reference to
   this port is invalid.
**/
/*exported*/
void
nl_design_remove_port (nl_design design, nl_port port)
{
  char *port_name = nl_port_name (port);
  nl_pin pin;
  nl_bus port_bus = nl_port_bus (port);

  if ( port_bus != NULL ) {
    nl_design_remove_port_bus (design, port_bus, 0);
  }


  ht_delete (design->ports_by_name, port_name);
  nl_dll_remove (design->ports, (nl_dll) port);
  pin = nl_port_pin (port);
  if ( pin != NULL ) {
    nl_pin_disconnect (pin);
  }
  nl_port_free (port);
}


/**
   Remove net 'net' from design 'design'.  All the net's pins will
   be disconnected; all references to the net are removed from the
   design; and the net itself is freed.  Any further reference to
   this net is invalid.
**/
/*exported*/
void
nl_design_remove_net (nl_design design, nl_net net)
{
  char *net_name = nl_net_name (net);
  nl_bus net_bus = nl_net_bus (net);

  if ( net_bus != NULL ) {
    nl_design_remove_net_bus (design, net_bus, 0);
  }

  ht_delete (design->objects_by_name, net_name);
  nl_dll_remove (design->nets, (nl_dll) net);

  nl_net_for_all_pins (net, pin) {
    nl_pin_disconnect (pin);
  } nl_end_for;

  nl_net_free (net);
}


/**
   Remove reference 'reference' from design 'design'.
**/
/*exported*/
void
nl_design_remove_reference (nl_design design, nl_reference reference)
{
  char *ref_name = nl_reference_name (reference);

  ht_delete (design->references_by_name, ref_name);
  nl_dll_remove (design->references, (nl_dll) reference);

  nl_reference_free (reference);
}


/*exported*/
void
nl_design_remove_net_bus (nl_design design, nl_bus bus, int and_members)
{
  char *bus_name = nl_bus_name (bus);

  ht_delete (design->objects_by_name, bus_name);
  nl_dll_remove (design->net_buses, (nl_dll) bus);

  nl_bus_for_all_net_members (bus, net) {
    nl_net_set_bus_and_offset (net, NULL, 0);

    if ( and_members ) {
      nl_design_remove_net (design, net);
    }
  } nl_end_for;

  nl_bus_free (bus);
}


/*exported*/
void
nl_design_remove_cell_bus (nl_design design, nl_bus bus, int and_members)
{
  char *bus_name = nl_bus_name (bus);

  ht_delete (design->objects_by_name, bus_name);
  nl_dll_remove (design->cell_buses, (nl_dll) bus);

  nl_bus_for_all_cell_members (bus, cell) {
    if ( and_members ) {
      nl_design_remove_cell (design, cell);
    }
    else {
      nl_cell_set_bus_and_offset (cell, NULL, 0);
    }
  } nl_end_for;

  nl_bus_free (bus);
}


/*exported*/
void
nl_design_remove_port_bus (nl_design design, nl_bus bus, int and_members)
{
  char *bus_name = nl_bus_name (bus);

  ht_delete (design->objects_by_name, bus_name);
  nl_dll_remove (design->port_buses, (nl_dll) bus);

  nl_bus_for_all_port_members (bus, port) {
    if ( and_members ) {
      nl_design_remove_port (design, port);
    }
    else {
      nl_port_set_bus_and_offset (port, NULL, 0);
    }
  } nl_end_for;

  nl_bus_free (bus);
}


/**
   Remove attribute 'attr' from design 'design'.  The attribute is
   removed from any object to which it is attached; all the storage
   associated with the attribute is freed; and the attribute itself is
   freed.  Any further reference to this attribute is invalid.
**/
/*exported*/
void
nl_design_remove_attr (nl_design design, nl_attr attr)
{
  char *attr_name = nl_attr_name (attr);

  if ( attr_name != NULL ) {
    ht_delete (design->attrs_by_name, attr_name);
  }
  nl_dll_remove (design->attrs, (nl_dll) attr);
  nl_attr_free (attr);
}


/*exported*/
void
nl_design_remove_subprogram (nl_design design, nl_subprogram subr)
{
  char *subr_name = nl_subprogram_name (subr);

  ht_delete (design->subprograms_by_name, subr_name);
  nl_dll_remove (design->subprograms, (nl_dll) subr);
  nl_subprogram_free (subr);
}


/*internal*/
nl_net
nl_design_alloc_net (nl_design design, char *name)
{
  nl_net result = (nl_net)
    nl_design_alloc_object (design, name, nl_kind_net, sizeof (*result),
			    &design->next_net_id, &design->free_nets,
			    design->objects_by_name, design->objects_attr,
			    design->nets);

  return result;
}


/*internal*/
nl_pin
nl_design_alloc_pin (nl_design design)
{
  nl_pin result = (nl_pin)
    nl_design_alloc_object (design, NULL, nl_kind_pin, sizeof (*result),
			    &design->next_pin_id, &design->free_pins,
			    NULL, NULL,
			    NULL);

  return result;
}


/*internal*/
nl_reference
nl_design_alloc_reference (nl_design design, char *name)
{
  nl_reference result = (nl_reference)
    nl_design_alloc_object (design, name, nl_kind_reference, sizeof (*result),
			    &design->next_reference_id, NULL,
			    design->references_by_name, design->references_attr,
			    design->references);

  return result;
}


/*internal*/
nl_refpin
nl_design_alloc_refpin (nl_design design, char *name)
{
  nl_refpin result = (nl_refpin)
    nl_design_alloc_object (design, name, nl_kind_refpin, sizeof (*result),
			    &design->next_refpin_id, NULL, NULL, NULL, NULL);

  return result;
}


/*internal*/
nl_type
nl_design_alloc_type (nl_design design, char *name)
{
  nl_type result = (nl_type)
    nl_design_alloc_object (design, name, nl_kind_type, sizeof (*result),
			    &design->next_type_id, NULL,
			    design->types_by_name, design->types_attr,
			    design->types);

  return result;
}


/*internal*/
nl_attr
nl_design_alloc_attr (nl_design design, char *name)
{
  nl_attr result = (nl_attr)
    nl_design_alloc_object (design, name, nl_kind_attr, sizeof (*result),
			    &design->next_attr_id, NULL,
			    design->attrs_by_name, design->attrs_attr,
			    design->attrs);

  return result;
}


/*internal*/
nl_subprogram
nl_design_alloc_subprogram (nl_design design, char *name)
{
  nl_subprogram result = (nl_subprogram)
    nl_design_alloc_object (design, name, nl_kind_subprogram, sizeof (*result),
			    &design->next_subprogram_id, NULL,
			    design->subprograms_by_name,
			    design->subprograms_attr, design->subprograms);

  return result;
}


/*exported*/
nl_subprogram
nl_design_get_subprogram_by_name (nl_design design, char *name)
{
  ht_entry ent = ht_lookup (design->subprograms_by_name, name);

  if ( ent == ht_null ) {
    return NULL;
  }
  else {
    nl_subprogram result;

    ht_get_attribute_for_entry (design->subprograms_attr, ent, &result);

    return result;
  }
}


/*internal*/
nl_symbol
nl_design_alloc_symbol (nl_design design, char *name)
{
  nl_symbol result = (nl_symbol)
    nl_design_alloc_object (design, name, nl_kind_symbol, sizeof (*result),
			    &design->next_symbol_id, NULL, NULL, NULL, NULL);

  return result;
}


/*exported*/
void
nl_design_add_symbol (nl_design design, nl_symbol symbol)
{
  char *name = nl_symbol_name (symbol);
  
  ht_set_attribute (design->symbols_attr, name, &symbol);
  nl_dll_add (design->symbols, (nl_dll) symbol);
}


/*exported*/
nl_symbol
nl_design_get_symbol_by_name (nl_design design, char *name)
{
  nl_symbol result;

  ht_get_attribute (design->subprograms_attr, name, &result);

  return result;
}


/*internal*/
nl_bus
nl_design_alloc_bus (nl_design design, char *name, nl_kind member_kind)
{
  nl_bus result;

  switch (member_kind) {
    {
      nl_dll_head dll_head;
      hashtab table;
      ht_attr table_attr;

    case nl_kind_port:
      dll_head = (nl_dll_head) design->port_buses;
      table = design->ports_by_name;
      table_attr = design->ports_attr;
      goto allocate_it;

    case nl_kind_cell:
      dll_head = (nl_dll_head) design->cell_buses;
      table = design->objects_by_name;
      table_attr = design->objects_attr;
      goto allocate_it;

    case nl_kind_net:
      dll_head = (nl_dll_head) design->net_buses;
      table = design->objects_by_name;
      table_attr = design->objects_attr;
      goto allocate_it;

    case nl_kind_refpin:
      dll_head = NULL;
      table = NULL;
      table_attr = NULL;

    allocate_it:
      result = (nl_bus)
	nl_design_alloc_object (design, name, nl_kind_bus, sizeof (*result),
				&design->next_bus_id, NULL,
				table, table_attr,
				dll_head);
      break;
    }
    
  default:
    ASSERT (0);
  }


  return result;
}


/**
   Return the cell named 'name' in design 'design'.  If the design
   does not contain a cell with this name, return NULL.
**/
/*exported*/
nl_cell
nl_design_get_cell_by_name (nl_design design, char *name)
{
  nl_named_object obj = nl_design_get_object_by_name (design, name);

  if ( obj == NULL ) {
    return NULL;
  }
  else if ( nl_named_object_kind (obj) != nl_kind_cell ) {
    return NULL;
  }
  else {
    return (nl_cell)obj;
  }
}


/**
   Return the reference named 'name' in design 'design'.  If the
   design does not contain a reference with this name, return NULL.
**/
/*exported*/
nl_reference
nl_design_get_reference_by_name (nl_design design, char *name)
{
  nl_reference result;

  ht_get_attribute (design->references_attr, name, &result);

  return result;
}


/**
   Return the net named 'name' in design 'design'.  If the design
   does not contain a net with this name, return NULL.
**/
/*exported*/
nl_net
nl_design_get_net_by_name (nl_design design, char *name)
{
  nl_named_object obj = nl_design_get_object_by_name (design, name);

  if ( obj == NULL ) {
    return NULL;
  }
  else if ( nl_named_object_kind (obj) != nl_kind_net ) {
    return NULL;
  }
  else {
    return (nl_net)obj;
  }
}


/**
   Return the net or bus or nets named 'name' in design 'design'.  If
   the design does not contain either a net or a bus of nets with this
   name, return NULL.
**/
/*exported*/
nl_named_object
nl_design_get_net_or_bus_by_name (nl_design design, char *name)
{
  nl_named_object obj = nl_design_get_object_by_name (design, name);

  if ( obj == NULL ) {
    return NULL;
  }
  else if ( nl_named_object_kind (obj) != nl_kind_net ) {
    if ( nl_named_object_kind (obj) != nl_kind_bus )
      return NULL;
    else if ( nl_bus_member_kind ((nl_bus) obj) != nl_kind_net ) {
      return NULL;
    }
    else {
      return obj;
    }
  }
  else {
    return obj;
  }
}


/**
   Return the cell, bus of cells, net, or bus of nets named 'name' in
   design 'design'.  If the design does not contain a cell, bus of
   cells, net, or bus of nets with this name, return NULL.
**/
/*exported*/
nl_named_object
nl_design_get_object_by_name (nl_design design, char *name)
{
  if ( strcmp (name, design->name) == 0 ) {
    return (nl_named_object) design;
  }
  else {
    nl_named_object object;

    ht_get_attribute (design->objects_attr, name, &object);

    return object;
  }
}



/**
   Return the port named 'name' in design 'design'.  If the design
   does not contain a port with this name, return NULL.
**/
/*exported*/
nl_object
nl_design_get_port_by_name (nl_design design, char *name)
{
  nl_object port;

  ht_get_attribute (design->ports_attr, name, &port);

  return port;
}


/**
   Return the type named 'name' in design 'design'.  If the design
   does not contain a type with this name, return NULL.
**/
/*exported*/
nl_type
nl_design_get_type_by_name (nl_design design, char *name)
{
  nl_type type;

  ht_get_attribute (design->types_attr, name, &type);

  return type;
}


/**
   Return the attribute named 'name' in design 'design'.  If the design
   does not contain a attribute with this name, return NULL.
**/
/*exported*/
nl_attr
nl_design_get_attr_by_name (nl_design design, char *name)
{
  nl_attr attr;

  ht_get_attribute (design->attrs_attr, name, &attr);

  return attr;
}


/**
   Declare 'net_or_bus', which must either be a net or a bus of nets,
   to be a "supply0" in design 'design'.  If this design is written
   out as Verilog, the specified net or bus will be declared using
   "supply0".
**/
/*exported*/
void
nl_design_add_supply0 (nl_design design, nl_object net_or_bus)
{
  ar_add (design->supply0s, &net_or_bus);
}


/**
   Declare 'net_or_bus', which must either be a net or a bus of nets,
   to be a "supply1" in design 'design'.  If this design is written
   out as Verilog, the specified net or bus will be declared using
   "supply1".
**/
/*exported*/
void
nl_design_add_supply1 (nl_design design, nl_object net_or_bus)
{
  ar_add (design->supply1s, &net_or_bus);
}


/*internal*/
int
nl_design_max_id (nl_design design, nl_kind kind)
{
  switch ( kind ) {
  case nl_kind_port:
    return design->next_port_id;
  case nl_kind_cell:
    return design->next_cell_id;
  case nl_kind_net:
    return design->next_net_id;
  case nl_kind_pin:
    return design->next_pin_id;
  case nl_kind_bus:
    return design->next_bus_id;
  case nl_kind_reference:
    return design->next_reference_id;
  case nl_kind_refpin:
    return design->next_refpin_id;
  case nl_kind_type:
    return design->next_type_id;
  default:
    ASSERT (0);
  }
}


/**
   Return the number of nets (including the ones that are in buses) in
   design 'design'.
**/
/*exported*/
int
nl_design_num_nets (nl_design design)
{
  int result = nl_dll_head_num_elements (design->nets);

  return result;
}
    

/**
   Return the number of buses of nets in design 'design'.
**/
/*exported*/
int
nl_design_num_net_buses (nl_design design)
{
  int result = nl_dll_head_num_elements (design->net_buses);

  return result;
}

    
/**
   Return the number of cells (including the ones that are in buses) in
   design 'design'.
**/
/*exported*/
int
nl_design_num_cells (nl_design design)
{
  int result = nl_dll_head_num_elements (design->cells);

  return result;
}
    

/**
   Return the number of buses of cells in design 'design'.
**/
/*exported*/
int
nl_design_num_cell_buses (nl_design design)
{
  int result = nl_dll_head_num_elements (design->cell_buses);

  return result;
}

    
/**
   Return the number of ports (including the ones that are in buses) in
   design 'design'.
**/
/*exported*/
int
nl_design_num_ports (nl_design design)
{
  int result = nl_dll_head_num_elements (design->ports);

  return result;
}

    
/**
   Return the number of buses of ports in design 'design'.
**/
/*exported*/
int
nl_design_num_port_buses (nl_design design)
{
  int result = nl_dll_head_num_elements (design->port_buses);

  return result;
}


/**
   Return the number of references in design 'design'.
**/
/*exported*/
int
nl_design_num_references (nl_design design)
{
  int result = nl_dll_head_num_elements (design->references);

  return result;
}

    
/**
   Return the number of types in design 'design'.
**/
/*exported*/
int
nl_design_num_types (nl_design design)
{
  int result = nl_dll_head_num_elements (design->types);

  return result;
}

    
/**
   Return the number of attributes in design 'design'.
**/
/*exported*/
int
nl_design_num_attrs (nl_design design)
{
  int result = nl_dll_head_num_elements (design->attrs);

  return result;
}


/*exported*/
void
nl_design_rename (nl_design design, char *new_name)
{
  nl_context context = nl_design_context (design);
  char *old_name = design->name;

  design->name = GSTRDUP (new_name, design->mem_group);

  nl_context_rename_design (context, design, old_name);

  FREE (old_name);
}

    
/*internal*/
void
nl_design_rename_object (nl_design design, nl_named_object object,
			 char *old_name)
{
  char *new_name = nl_named_object_name (object);
  nl_kind object_kind = nl_named_object_kind (object);
  nl_kind effective_kind = object_kind;
  hashtab table;
  ht_attr attr;

  if ( object_kind == nl_kind_bus ) {
    effective_kind = nl_bus_member_kind ((nl_bus) object);
  }

  switch ( effective_kind ) {
  case nl_kind_port:
    table = design->ports_by_name;
    attr = design->ports_attr;
    break;

  case nl_kind_net:
  case nl_kind_cell:
    table = design->objects_by_name;
    attr = design->objects_attr;
    break;

  case nl_kind_reference:
    table = design->references_by_name;
    attr = design->references_attr;
    break;

  default:
    ASSERT (0);
  }

  {
    ht_entry hte = ht_replace (table, old_name, new_name);
    nl_object object;

    ASSERT (hte != ht_null);

    ht_get_attribute_for_entry (attr, hte, &object);

    ASSERT (nl_object_kind (object) == object_kind);
  }
}


/*internal*/
nl_idesign
nl_design_alloc_idesign (nl_design design)
{
  nl_idesign result = GMALLOC (sizeof (*result), design->mem_group);
    
  result->kind = nl_kind_idesign;

  result->id = design->next_idesign_id;
  design->next_idesign_id++;

  nl_dll_add (design->idesigns, (nl_dll) result);

  return result;
}


/*internal*/
void
nl_design_free_idesign (nl_design design, nl_idesign idesign)
{
  nl_dll_remove (design->idesigns, (nl_dll) idesign);
  FREE (idesign);
}


/*exported*/
int
nl_design_num_idesigns (nl_design design)
{
  int result = nl_dll_head_num_elements (design->idesigns);

  return result;
}


/*exported*/
nl_idesign
nl_design_first_idesign (nl_design design)
{
  nl_idesign result = (nl_idesign) nl_dll_gen_first (design->idesigns);

  return result;
}


/*exported*/
void
nl_design_set_bus_naming_style (nl_design design, char *style)
{
  if ( design->bus_naming_style != NULL ) {
    FREE (design->bus_naming_style);
  }

  if ( style != NULL ) {
    design->bus_naming_style = GSTRDUP (style, design->mem_group);
  }
  else {
    design->bus_naming_style = NULL;
  }
}
