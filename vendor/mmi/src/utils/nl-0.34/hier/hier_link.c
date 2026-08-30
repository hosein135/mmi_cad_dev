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
#include "hier.h"


static
int
hier_link_check_port (nl_reference reference, nl_object refpin, nl_object port,
		      char *port_name, char *owner_name)
{
  int result = 1;
  int port_width;
  int refpin_width;
  nl_kind refpin_kind = nl_object_kind (refpin);
  nl_kind port_kind;
  char *name;

  if ( port == NULL ) {
    fprintf (stderr, "Could not find a port named '%s' on '%s'.\n",
	     port_name, owner_name);
    return 0;
  }

  port_kind = nl_object_kind (port);

  if ( refpin_kind == nl_kind_bus ) {
    nl_bus bus = (nl_bus) refpin;
    name = nl_bus_name (bus);
    refpin_width = nl_bus_width (bus);
  }
  else if ( refpin_kind == nl_kind_refpin ) {
    name = nl_refpin_name ((nl_refpin) refpin);
    refpin_width = 1;
  }
  else {
    ASSERT (0);
  }

  if ( port_kind == nl_kind_bus ) {
    port_width = nl_bus_width ((nl_bus) port);
  }
  else {
    port_width = 1;
  }

  if ( refpin_width != port_width ) {
    nl_design design = nl_reference_design (reference);

    fprintf (stderr, "In design '%s': width mismatch on port '%s' "
	     "of design '%s'.\n", nl_design_name (design), name, owner_name);
    fprintf (stderr, "  Port on reference has width of %d; "
	     "port on design has width of %d.\n", refpin_width, port_width);

    if ( refpin_width > port_width ) {
      fprintf (stderr, "  %s will not be linked.\n", owner_name);
      result = 0;
    }
  }

  return result;
}


static
void
hier_link_check_refpin (nl_reference reference, char *name, int silent)
{
  if ( !silent ) {
    nl_object refpin = nl_reference_get_refpin_by_name (reference, name);

    if ( refpin == NULL ) {
      nl_design design = nl_reference_design (reference);

      fprintf (stderr,
	       "In design '%s': port '%s' is missing on reference '%s'\n",
	       nl_design_name (design), name, nl_reference_name (reference));
    }
  }
}


static 
int
hier_link_check_reference (nl_reference reference, nl_object down_object,
			   int silent)
{
  int result = 1;
  nl_bus prev_bus = NULL;
  nl_kind down_object_kind = nl_object_kind (down_object);

  nl_reference_for_all_refpins (reference, refpin) {
    nl_bus bus = nl_refpin_bus (refpin);
    nl_object refpin_obj;
    char *refpin_name;
    nl_object down_port;
    char *down_name;

    if ( bus != NULL && bus == prev_bus )
      continue;

    prev_bus = bus;

    if ( bus != NULL ) {
      refpin_obj = (nl_object) bus;
      refpin_name = nl_bus_name (bus);
    }
    else {
      refpin_obj = (nl_object) refpin;
      refpin_name = nl_refpin_name (refpin);
    }

    if ( down_object_kind == nl_kind_design ) {
      nl_design down_design = (nl_design) down_object;
      down_port = nl_design_get_port_by_name (down_design, refpin_name);
      down_name = nl_design_name (down_design);
    }
    else if ( down_object_kind == nl_kind_libcell ) {
      nl_libcell down_libcell = (nl_libcell) down_object;
      down_port = nl_libcell_get_libpin_by_name (down_libcell, refpin_name);
      down_name = nl_libcell_name (down_libcell);
    }
    else {
      ASSERT (0);
    }

    result &= hier_link_check_port (reference, refpin_obj, down_port,
				    refpin_name, down_name);
  } nl_end_for;

  prev_bus = NULL;

  if ( down_object_kind == nl_kind_design ) {
    nl_design down_design = (nl_design) down_object;

    nl_design_for_all_ports (down_design, port) {
      char *name;
      nl_bus bus = nl_port_bus (port);

      if ( bus != NULL && bus == prev_bus )
	continue;

      prev_bus = bus;

      if ( bus != NULL ) {
	name = nl_bus_name (bus);
      }
      else {
	name = nl_port_name (port);
      }

      hier_link_check_refpin (reference, name, silent);
    } nl_end_for;
  }
  else if ( down_object_kind == nl_kind_libcell ) {
    nl_libcell down_libcell = (nl_libcell) down_object;

    nl_libcell_for_all_libpins (down_libcell, libpin) {
      nl_bus bus = nl_libpin_bus (libpin);
      nl_use use = nl_libpin_use (libpin);
      char *name;

      if ( bus != NULL && bus == prev_bus )
	continue;

      prev_bus = bus;

      if ( bus != NULL ) {
	name = nl_bus_name (bus);
      }
      else {
	name = nl_libpin_name (libpin);
      }

      if ( use != nl_use_power && use != nl_use_ground ) {
	hier_link_check_refpin (reference, name, silent);
      }
    } nl_end_for;
  }
  else {
    ASSERT (0);
  }

  return result;
}


void
hier_link_reference (nl_reference reference, int silent, int recursive,
		     ar libraries)
{
  char *name = nl_reference_name (reference);
  nl_object object = NULL;
  nl_design design = nl_reference_design (reference);
  nl_context context = nl_design_context (design);

  if ( libraries != NULL ) {
    ar_for_all (libraries, nl_library, library) {
      nl_libcell libcell = nl_library_get_libcell_by_name (library, name);

      if ( libcell != NULL ) {
	object = (nl_object) libcell;
	break;
      }
    } ar_end_for;
  }

  if ( object == NULL ) {
    nl_design down_design = nl_context_get_design_by_name (context, name);
    object = (nl_object) down_design;
  }

  if ( object == NULL ) {
    char *reference_name = nl_reference_name (reference);
    int is_synthetic = reference_name[0] == '*';

    if ( !silent && !is_synthetic ) {
      fprintf (stderr, "Could not resolve reference '%s' in design '%s'\n",
	       name, nl_design_name (design));
    }
  }
  else {
    int flag = hier_link_check_reference (reference, object, silent);

    if ( flag ) {
      nl_object linked_object = nl_reference_down_design (reference);

      if ( linked_object != object ) {
	if ( linked_object != NULL ) {
	  nl_reference_unlink (reference);
	}

	nl_reference_link (reference, object);
      }
    }

    if ( recursive && nl_object_kind (object) == nl_kind_design ) {
      nl_design down_design = (nl_design) object;
      int is_libcell = nl_design_libcell (down_design);

      if ( !is_libcell ) {
	hier_link_design (down_design, silent, recursive, libraries);
      }
    }
  }
}


void
hier_link_design (nl_design design, int silent, int recursive, ar libraries)
{
  nl_design_attr link_attr
    = (nl_design_attr) nl_design_get_attr_by_name (design, "link active");
  
  if ( link_attr != NULL ) {
    return;
  }
  
  link_attr = nl_design_attr_create ("link active", design, nl_density_sparse,
				     sizeof (int), NULL, NULL);

  nl_design_for_all_references (design, reference) {
    hier_link_reference (reference, silent, recursive, libraries);
  } nl_end_for;

  nl_design_remove_attr (design, (nl_attr) link_attr);
}
