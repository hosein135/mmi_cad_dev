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
nl_attr
nl_attr_create (char *name, nl_object owner, nl_kind attr_of,
		nl_density density, int attr_size, void *init,
		nl_free_fun free_fun)
{
  nl_attr result = NULL;
  mem_group group;
  nl_kind owner_kind = nl_object_kind (owner);

  if ( owner_kind == nl_kind_design ) {
    nl_design design = (nl_design) owner;

    result = nl_design_alloc_attr (design, name);
    group = nl_design_mem_group (design);
  }
  else if ( owner_kind == nl_kind_idesign ) {
    nl_idesign idesign = (nl_idesign) owner;
    nl_design design = nl_idesign_design (idesign);

    result = nl_idesign_alloc_attr (idesign, name);
    group = nl_design_mem_group (design);
  }
  else if ( owner_kind == nl_kind_library ) {
    nl_library library = (nl_library) owner;

    result = nl_library_alloc_attr (library, name);
    group = nl_library_mem_group (library);
  }
  else {
    ASSERT (0);
  }

  result->owner = owner;
  result->attr_of = attr_of;
  result->density = density;

  if ( density == nl_density_dense ) {
    int num_elts;
    nl_dense_attr dense_result = (nl_dense_attr) result;
    void *init_copy;
    
    switch ( attr_of ) {
    case nl_kind_net:
    case nl_kind_cell:
    case nl_kind_port:
    case nl_kind_pin:
    case nl_kind_icell:
    case nl_kind_inet:
    case nl_kind_ipin:
    case nl_kind_iport:
      if ( owner_kind == nl_kind_design )
	num_elts = nl_design_max_id ((nl_design) owner, attr_of);
      else
	num_elts = nl_idesign_max_id ((nl_idesign) owner, attr_of);
      break;
    default:
      dense_result->density = nl_density_sparse;
      goto sparse_case;
    }

    dense_result->array = ar_alloc_from_group (num_elts, attr_size, group);

    ar_make_size (dense_result->array, num_elts);

    init_copy =  GMALLOC (attr_size, group);

    if ( init != NULL ) {
      memcpy (init_copy, init, attr_size);
    }
    else {
      memset (init_copy, '\0', attr_size);
    }

    dense_result->init = init_copy;
    dense_result->free_fun = free_fun;

    ar_init (dense_result->array, init_copy);
  }
  else if ( density == nl_density_sparse ) {
    nl_sparse_attr sparse_result;
  sparse_case:
    sparse_result = (nl_sparse_attr) result;
    sparse_result->table = ht_alloc_from_group (16, ht_hash_ptr, NULL, NULL,
						NULL, group);
    sparse_result->attr = ht_new_attribute (sparse_result->table, attr_size,
					    init, (ht_free_fn_t) free_fun);
  }
  else {
    ASSERT (0);
  }

  return result;
}


static
void
nl_attr_access (nl_attr attr, nl_object obj, int set, void *value_p)
{
  nl_density density = attr->density;

  ASSERT (attr->attr_of == nl_object_kind (obj));

  if ( density == nl_density_dense ) {
    nl_dense_attr dense_attr = (nl_dense_attr) attr;
    unsigned int id = nl_object_id (obj);
    size_t size = ar_size (dense_attr->array);

    if ( id >= size ) {
      size_t new_size = id + 1;
      ar_make_size (dense_attr->array, new_size);

      if ( dense_attr->init != NULL ) {
	size_t i;

	for ( i = size; i < new_size; i++ ) {
	  ar_set (dense_attr->array, i, dense_attr->init);
	}
      }
    }

    if ( set ) {
      if ( dense_attr->free_fun != NULL ) {
	void *old_value;
	ar_ref (dense_attr->array, id, &old_value);
	dense_attr->free_fun (&old_value);
      }
      ar_set (dense_attr->array, id, value_p);
    }
    else {
      ar_ref (dense_attr->array, id, value_p);
    }
  }
  else if ( density == nl_density_sparse ) {
    nl_sparse_attr sparse_attr = (nl_sparse_attr) attr;

    if ( set ) {
      ht_entry hte = ht_insert (sparse_attr->table, obj);
      ht_set_attribute_for_entry (sparse_attr->attr, hte, value_p);
    }
    else {
      ht_get_attribute (sparse_attr->attr, obj, value_p);
    }
  }
  else {
    ASSERT (0);
  }
}


/*exported*/
void
nl_attr_get (nl_attr attr, nl_object obj, void *dest)
{
  nl_attr_access (attr, obj, 0, dest);
}


/*exported*/
void
nl_attr_set (nl_attr attr, nl_object obj, void *src)
{
  nl_attr_access (attr, obj, 1, src);
}


/*exported*/
void
nl_attr_initialize (nl_attr attr, nl_object obj)
{
  if ( attr->density == nl_density_dense ) {
    nl_dense_attr dense_attr = (nl_dense_attr) attr;
    nl_attr_access (attr, obj, 1, dense_attr->init);
  }
}


/*internal*/
void
nl_attr_free (nl_attr attr)
{
  nl_density density = attr->density;

  if ( density == nl_density_sparse ) {
    nl_sparse_attr sparse_attr = (nl_sparse_attr) attr;
    ht_free (sparse_attr->table);
    /* Since attr->array is an ht_attribute, it gets freed by ht_free. */
  }
  else if ( density == nl_density_dense ) {
    nl_dense_attr dense_attr = (nl_dense_attr) attr;

    if ( dense_attr->free_fun != NULL ) {
      ar_for_all_pointers (dense_attr->array, elt_p) {
	dense_attr->free_fun (elt_p);
      } ar_end_for;
    }
      
    ar_free (dense_attr->array);

    if ( dense_attr->init ) {
      FREE (dense_attr->init);
    }
  }
  else {
    ASSERT (0);
  }

  if ( attr->name != NULL ) {
    FREE (attr->name);
  }

  FREE (attr);
}


/*exported*/
nl_design_attr
nl_design_attr_create (char *name, nl_design design, nl_density density,
		       int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_design, density,
		      attr_size, init, free_fun);

  return (nl_design_attr) result;
}


/*exported*/
nl_net_attr
nl_net_attr_create (char *name, nl_design design, nl_density density,
		    int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_net, density,
		      attr_size, init, free_fun);

  return (nl_net_attr) result;
}


/*exported*/
nl_bus_attr
nl_bus_attr_create (char *name, nl_object owner, nl_density density,
		    int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, owner, nl_kind_bus, density,
		      attr_size, init, free_fun);

  return (nl_bus_attr) result;
}


/*exported*/
nl_cell_attr
nl_cell_attr_create (char *name, nl_design design, nl_density density,
		     int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_cell, density,
		      attr_size, init, free_fun);

  return (nl_cell_attr) result;
}


/*exported*/
nl_pin_attr
nl_pin_attr_create (char *name, nl_design design, nl_density density,
		    int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_pin, density,
		      attr_size, init, free_fun);

  return (nl_pin_attr) result;
}


/*exported*/
nl_port_attr
nl_port_attr_create (char *name, nl_design design, nl_density density,
		     int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_port, density,
		      attr_size, init, free_fun);

  return (nl_port_attr) result;
}


/*exported*/
nl_reference_attr
nl_reference_attr_create (char *name, nl_design design, nl_density density,
			  int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_reference, density,
		      attr_size, init, free_fun);

  return (nl_reference_attr) result;
}


/*exported*/
nl_refpin_attr
nl_refpin_attr_create (char *name, nl_design design, nl_density density,
		       int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_refpin, density,
		      attr_size, init, free_fun);

  return (nl_refpin_attr) result;
}


/*exported*/
nl_symbol_attr
nl_symbol_attr_create (char *name, nl_design design, nl_density density,
		       int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) design, nl_kind_symbol, density,
		      attr_size, init, free_fun);

  return (nl_symbol_attr) result;
}


/*exported*/
nl_library_attr
nl_library_attr_create (char *name, nl_library library, nl_density density,
			int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) library, nl_kind_library, density,
		      attr_size, init, free_fun);

  return (nl_library_attr) result;
}


/*exported*/
nl_libcell_attr
nl_libcell_attr_create (char *name, nl_library library, nl_density density,
			int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) library, nl_kind_libcell, density,
		      attr_size, init, free_fun);

  return (nl_libcell_attr) result;
}


/*exported*/
nl_libpin_attr
nl_libpin_attr_create (char *name, nl_library library, nl_density density,
			int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) library, nl_kind_libpin, density,
		      attr_size, init, free_fun);

  return (nl_libpin_attr) result;
}


/*exported*/
nl_idesign_attr
nl_idesign_attr_create (char *name, nl_idesign idesign, nl_density density,
			int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result 
    = nl_attr_create (name, (nl_object) idesign, nl_kind_idesign, density,
		      attr_size, init, free_fun);

  return (nl_idesign_attr) result;
}


/*exported*/
nl_icell_attr
nl_icell_attr_create (char *name, nl_idesign idesign, nl_density density,
		      int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) idesign, nl_kind_icell, density,
		      attr_size, init, free_fun);

  return (nl_icell_attr) result;
}


/*exported*/
nl_inet_attr
nl_inet_attr_create (char *name, nl_idesign idesign, nl_density density,
		     int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) idesign, nl_kind_inet, density,
		      attr_size, init, free_fun);

  return (nl_inet_attr) result;
}


/*exported*/
nl_ipin_attr
nl_ipin_attr_create (char *name, nl_idesign idesign, nl_density density,
		      int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) idesign, nl_kind_ipin, density,
		      attr_size, init, free_fun);

  return (nl_ipin_attr) result;
}


/*exported*/
nl_iport_attr
nl_iport_attr_create (char *name, nl_idesign idesign, nl_density density,
		      int attr_size, void *init, nl_free_fun free_fun)
{
  nl_attr result
    = nl_attr_create (name, (nl_object) idesign, nl_kind_iport, density,
		      attr_size, init, free_fun);

  return (nl_iport_attr) result;
}


/*exported*/
void
nl_design_attr_get (nl_design_attr attr, nl_design design, void *data)
{
  ASSERT (attr->attr_of == nl_kind_design);

  nl_attr_get ((nl_attr) attr, (nl_object) design, data);
}


/*exported*/
void
nl_net_attr_get (nl_net_attr attr, nl_net net, void *data)
{
  ASSERT (attr->attr_of == nl_kind_net);
  ASSERT (attr->owner == (nl_object) nl_net_design (net));

  nl_attr_get ((nl_attr) attr, (nl_object) net, data);
}


/*exported*/
void
nl_cell_attr_get (nl_cell_attr attr, nl_cell cell, void *data)
{
  ASSERT (attr->attr_of == nl_kind_cell);
  ASSERT (attr->owner == (nl_object) nl_cell_design (cell));

  nl_attr_get ((nl_attr) attr, (nl_object) cell, data);
}


/*exported*/
void
nl_port_attr_get (nl_port_attr attr, nl_port port, void *data)
{
  ASSERT (attr->attr_of == nl_kind_port);
  ASSERT (attr->owner == (nl_object) nl_port_design (port));

  nl_attr_get ((nl_attr) attr, (nl_object) port, data);
}


/*exported*/
void
nl_pin_attr_get (nl_pin_attr attr, nl_pin pin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_pin);
  ASSERT (attr->owner ==
	  (nl_object) nl_cell_or_port_design (nl_pin_owner (pin)));

  nl_attr_get ((nl_attr) attr, (nl_object) pin, data);
}


/*exported*/
void
nl_reference_attr_get (nl_reference_attr attr, nl_reference reference,
		       void *data)
{
  ASSERT (attr->attr_of == nl_kind_reference);
  ASSERT (attr->owner ==
	  (nl_object) nl_reference_design (reference));

  nl_attr_get ((nl_attr) attr, (nl_object) reference, data);
}


/*exported*/
void
nl_refpin_attr_get (nl_refpin_attr attr, nl_refpin refpin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_refpin);
  ASSERT (attr->owner ==
	  (nl_object) nl_reference_design (nl_refpin_reference (refpin)));

  nl_attr_get ((nl_attr) attr, (nl_object) refpin, data);
}


/*exported*/
void
nl_bus_attr_get (nl_bus_attr attr, nl_bus bus, void *data)
{
  ASSERT (attr->attr_of == nl_kind_bus);
  ASSERT (attr->owner == (nl_object) nl_bus_owner (bus));

  nl_attr_get ((nl_attr) attr, (nl_object) bus, data);
}


/*exported*/
void
nl_symbol_attr_get (nl_symbol_attr attr, nl_symbol symbol, void *data)
{
  ASSERT (attr->attr_of == nl_kind_symbol);

  nl_attr_get ((nl_attr) attr, (nl_object) symbol, data);
}


/*exported*/
void
nl_library_attr_get (nl_library_attr attr, nl_library library, void *data)
{
  ASSERT (attr->attr_of == nl_kind_library);

  nl_attr_get ((nl_attr) attr, (nl_object) library, data);
}


/*exported*/
void
nl_libcell_attr_get (nl_libcell_attr attr, nl_libcell libcell, void *data)
{
  ASSERT (attr->attr_of == nl_kind_libcell);

  nl_attr_get ((nl_attr) attr, (nl_object) libcell, data);
}


/*exported*/
void
nl_libpin_attr_get (nl_libpin_attr attr, nl_libpin libpin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_libpin);

  nl_attr_get ((nl_attr) attr, (nl_object) libpin, data);
}


/*exported*/
void
nl_idesign_attr_get (nl_idesign_attr attr, nl_idesign idesign, void *data)
{
  ASSERT (attr->attr_of == nl_kind_idesign);

  nl_attr_get ((nl_attr) attr, (nl_object) idesign, data);
}


/*exported*/
void
nl_icell_attr_get (nl_icell_attr attr, nl_icell icell, void *data)
{
  ASSERT (attr->attr_of == nl_kind_icell);
  ASSERT (attr->owner == (nl_object) nl_icell_idesign (icell));

  nl_attr_get ((nl_attr) attr, (nl_object) icell, data);
}


/*exported*/
void
nl_inet_attr_get (nl_inet_attr attr, nl_inet inet, void *data)
{
  ASSERT (attr->attr_of == nl_kind_inet);
  ASSERT (attr->owner == (nl_object) nl_inet_idesign (inet));

  nl_attr_get ((nl_attr) attr, (nl_object) inet, data);
}


/*exported*/
void
nl_ipin_attr_get (nl_ipin_attr attr, nl_ipin ipin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_ipin);
  ASSERT (attr->owner == (nl_object) nl_ipin_idesign (ipin));

  nl_attr_get ((nl_attr) attr, (nl_object) ipin, data);
}


/*exported*/
void
nl_iport_attr_get (nl_iport_attr attr, nl_iport iport, void *data)
{
  ASSERT (attr->attr_of == nl_kind_iport);
  ASSERT (attr->owner == (nl_object) nl_iport_idesign (iport));

  nl_attr_get ((nl_attr) attr, (nl_object) iport, data);
}


/*exported*/
void
nl_design_attr_set (nl_design_attr attr, nl_design design, void *data)
{
  ASSERT (attr->attr_of == nl_kind_design);

  nl_attr_set ((nl_attr) attr, (nl_object) design, data);
}


/*exported*/
void
nl_net_attr_set (nl_net_attr attr, nl_net net, void *data)
{
  ASSERT (attr->attr_of == nl_kind_net);
  ASSERT (attr->owner == (nl_object) nl_net_design (net));

  nl_attr_set ((nl_attr) attr, (nl_object) net, data);
}


/*exported*/
void
nl_cell_attr_set (nl_cell_attr attr, nl_cell cell, void *data)
{
  ASSERT (attr->attr_of == nl_kind_cell);
  ASSERT (attr->owner == (nl_object) nl_cell_design (cell));

  nl_attr_set ((nl_attr) attr, (nl_object) cell, data);
}


/*exported*/
void
nl_port_attr_set (nl_port_attr attr, nl_port port, void *data)
{
  ASSERT (attr->attr_of == nl_kind_port);
  ASSERT (attr->owner == (nl_object) nl_port_design (port));

  nl_attr_set ((nl_attr) attr, (nl_object) port, data);
}


/*exported*/
void
nl_pin_attr_set (nl_pin_attr attr, nl_pin pin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_pin);
  ASSERT (attr->owner ==
          (nl_object) nl_cell_or_port_design (nl_pin_owner (pin)));

  nl_attr_set ((nl_attr) attr, (nl_object) pin, data);
}


/*exported*/
void
nl_reference_attr_set (nl_reference_attr attr, nl_reference reference,
		       void *data)
{
  ASSERT (attr->attr_of == nl_kind_reference);
  ASSERT (attr->owner == (nl_object) nl_reference_design (reference));

  nl_attr_set ((nl_attr) attr, (nl_object) reference, data);
}


/*exported*/
void
nl_refpin_attr_set (nl_refpin_attr attr, nl_refpin refpin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_refpin);
  ASSERT (attr->owner ==
          (nl_object) nl_reference_design (nl_refpin_reference (refpin)));

  nl_attr_set ((nl_attr) attr, (nl_object) refpin, data);
}


/*exported*/
void
nl_symbol_attr_set (nl_symbol_attr attr, nl_symbol symbol, void *data)
{
  ASSERT (attr->attr_of == nl_kind_symbol);

  nl_attr_set ((nl_attr) attr, (nl_object) symbol, data);
}


/*exported*/
void
nl_library_attr_set (nl_library_attr attr, nl_library library, void *data)
{
  ASSERT (attr->attr_of == nl_kind_library);
  ASSERT (attr->owner == (nl_object) library);

  nl_attr_set ((nl_attr) attr, (nl_object) library, data);
}


/*exported*/
void
nl_libcell_attr_set (nl_libcell_attr attr, nl_libcell libcell, void *data)
{
  ASSERT (attr->attr_of == nl_kind_libcell);
  ASSERT (attr->owner == (nl_object) nl_libcell_library (libcell));

  nl_attr_set ((nl_attr) attr, (nl_object) libcell, data);
}


/*exported*/
void
nl_libpin_attr_set (nl_libpin_attr attr, nl_libpin libpin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_libpin);
  ASSERT (attr->owner ==
	  (nl_object) nl_libcell_library (nl_libpin_libcell (libpin)));

  nl_attr_set ((nl_attr) attr, (nl_object) libpin, data);
}


/*exported*/
void
nl_bus_attr_set (nl_bus_attr attr, nl_bus bus, void *data)
{
  ASSERT (attr->attr_of == nl_kind_bus);
  ASSERT (attr->owner == (nl_object) nl_bus_owner (bus));

  nl_attr_set ((nl_attr) attr, (nl_object) bus, data);
}


/*exported*/
void
nl_idesign_attr_set (nl_idesign_attr attr, nl_idesign idesign, void *data)
{
  ASSERT (attr->attr_of == nl_kind_idesign);

  nl_attr_set ((nl_attr) attr, (nl_object) idesign, data);
}


/*exported*/
void
nl_icell_attr_set (nl_icell_attr attr, nl_icell icell, void *data)
{
  ASSERT (attr->attr_of == nl_kind_icell);
  ASSERT (attr->owner == (nl_object) nl_icell_idesign (icell));

  nl_attr_set ((nl_attr) attr, (nl_object) icell, data);
}


/*exported*/
void
nl_inet_attr_set (nl_inet_attr attr, nl_inet inet, void *data)
{
  ASSERT (attr->attr_of == nl_kind_inet);
  ASSERT (attr->owner == (nl_object) nl_inet_idesign (inet));

  nl_attr_set ((nl_attr) attr, (nl_object) inet, data);
}


/*exported*/
void
nl_ipin_attr_set (nl_ipin_attr attr, nl_ipin ipin, void *data)
{
  ASSERT (attr->attr_of == nl_kind_ipin);
  ASSERT (attr->owner == (nl_object) nl_ipin_idesign (ipin));

  nl_attr_set ((nl_attr) attr, (nl_object) ipin, data);
}


/*exported*/
void
nl_iport_attr_set (nl_iport_attr attr, nl_iport iport, void *data)
{
  ASSERT (attr->attr_of == nl_kind_iport);
  ASSERT (attr->owner == (nl_object) nl_iport_idesign (iport));

  nl_attr_set ((nl_attr) attr, (nl_object) iport, data);
}


/*exported*/
void
nl_design_attr_get_by_name (char *name, nl_design design, void *data)
{
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  if ( attr == NULL ) {
    return;
  }

  ASSERT (attr->attr_of == nl_kind_design);

  nl_attr_get ((nl_attr) attr, (nl_object) design, data);
}


/*exported*/
void
nl_net_attr_get_by_name (char *name, nl_net net, void *data)
{
  nl_design design = nl_net_design (net);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_net);

  nl_attr_get ((nl_attr) attr, (nl_object) net, data);
}


/*exported*/
void
nl_cell_attr_get_by_name (char *name, nl_cell cell, void *data)
{
  nl_design design = nl_cell_design (cell);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_cell);

  nl_attr_get ((nl_attr) attr, (nl_object) cell, data);
}


/*exported*/
void
nl_port_attr_get_by_name (char *name, nl_port port, void *data)
{
  nl_design design = nl_port_design (port);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_port);

  nl_attr_get ((nl_attr) attr, (nl_object) port, data);
}


/*exported*/
void
nl_pin_attr_get_by_name (char *name, nl_pin pin, void *data)
{
  nl_cell_or_port owner = nl_pin_owner (pin);
  nl_design design = nl_cell_or_port_design (owner);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_pin);

  nl_attr_get ((nl_attr) attr, (nl_object) pin, data);
}


/*exported*/
void
nl_reference_attr_get_by_name (char *name, nl_reference reference, void *data)
{
  nl_design design = nl_reference_design (reference);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_reference);

  nl_attr_get ((nl_attr) attr, (nl_object) reference, data);
}


/*exported*/
void
nl_refpin_attr_get_by_name (char *name, nl_refpin refpin, void *data)
{
  nl_reference reference = nl_refpin_reference (refpin);
  nl_design design = nl_reference_design (reference);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_refpin);

  nl_attr_get ((nl_attr) attr, (nl_object) refpin, data);
}


/*exported*/
void
nl_idesign_attr_get_by_name (char *name, nl_idesign idesign, void *data)
{
  nl_attr attr = nl_idesign_get_attr_by_name (idesign, name);

  if ( attr == NULL ) {
    return;
  }

  ASSERT (attr->attr_of == nl_kind_idesign);

  nl_attr_get ((nl_attr) attr, (nl_object) idesign, data);
}


/*exported*/
void
nl_icell_attr_get_by_name (char *name, nl_icell icell, void *data)
{
  nl_idesign idesign = nl_icell_idesign (icell);
  nl_attr attr = nl_idesign_get_attr_by_name (idesign, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_icell);

  nl_attr_get ((nl_attr) attr, (nl_object) icell, data);
}


/*exported*/
void
nl_inet_attr_get_by_name (char *name, nl_inet inet, void *data)
{
  nl_idesign idesign = nl_inet_idesign (inet);
  nl_attr attr = nl_idesign_get_attr_by_name (idesign, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_inet);

  nl_attr_get ((nl_attr) attr, (nl_object) inet, data);
}


/*exported*/
void
nl_iport_attr_get_by_name (char *name, nl_iport iport, void *data)
{
  nl_idesign idesign = nl_iport_idesign (iport);
  nl_attr attr = nl_idesign_get_attr_by_name (idesign, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_iport);

  nl_attr_get ((nl_attr) attr, (nl_object) iport, data);
}


/*exported*/
void
nl_library_attr_get_by_name (char *name, nl_library library, void *data)
{
  nl_attr attr = nl_library_get_attr_by_name (library, name);

  if ( attr != NULL ) {
    ASSERT (attr->attr_of == nl_kind_library);

    nl_attr_get ((nl_attr) attr, (nl_object) library, data);
  }
}


/*exported*/
void
nl_design_attr_set_by_name (char *name, nl_design design, void *data)
{
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_design);

  nl_attr_set ((nl_attr) attr, (nl_object) design, data);
}


/*exported*/
void
nl_net_attr_set_by_name (char *name, nl_net net, void *data)
{
  nl_design design = nl_net_design (net);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_net);

  nl_attr_set ((nl_attr) attr, (nl_object) net, data);
}


/*exported*/
void
nl_cell_attr_set_by_name (char *name, nl_cell cell, void *data)
{
  nl_design design = nl_cell_design (cell);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_cell);

  nl_attr_set ((nl_attr) attr, (nl_object) cell, data);
}


/*exported*/
void
nl_port_attr_set_by_name (char *name, nl_port port, void *data)
{
  nl_design design = nl_port_design (port);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_port);

  nl_attr_set ((nl_attr) attr, (nl_object) port, data);
}


/*exported*/
void
nl_pin_attr_set_by_name (char *name, nl_pin pin, void *data)
{
  nl_cell_or_port owner = nl_pin_owner (pin);
  nl_design design = nl_cell_or_port_design (owner);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_pin);

  nl_attr_set ((nl_attr) attr, (nl_object) pin, data);
}


/*exported*/
void
nl_reference_attr_set_by_name (char *name, nl_reference reference, void *data)
{
  nl_design design = nl_reference_design (reference);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_reference);

  nl_attr_set ((nl_attr) attr, (nl_object) reference, data);
}


/*exported*/
void
nl_refpin_attr_set_by_name (char *name, nl_refpin refpin, void *data)
{
  nl_reference reference = nl_refpin_reference (refpin);
  nl_design design = nl_reference_design (reference);
  nl_attr attr = nl_design_get_attr_by_name (design, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_refpin);

  nl_attr_set ((nl_attr) attr, (nl_object) refpin, data);
}


/*exported*/
void
nl_icell_attr_set_by_name (char *name, nl_icell icell, void *data)
{
  nl_idesign idesign = nl_icell_idesign (icell);
  nl_attr attr = nl_idesign_get_attr_by_name (idesign, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_icell);

  nl_attr_set ((nl_attr) attr, (nl_object) icell, data);
}


/*exported*/
void
nl_inet_attr_set_by_name (char *name, nl_inet inet, void *data)
{
  nl_idesign idesign = nl_inet_idesign (inet);
  nl_attr attr = nl_idesign_get_attr_by_name (idesign, name);

  ASSERT (attr != NULL);
  ASSERT (attr->attr_of == nl_kind_inet);

  nl_attr_set ((nl_attr) attr, (nl_object) inet, data);
}
