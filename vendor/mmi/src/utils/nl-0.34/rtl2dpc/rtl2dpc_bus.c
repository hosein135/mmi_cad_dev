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


static
int
rtl2dpc_parse_netname (char *name, char **bus_name_p, int *index_p)
{
  int i;
  int length = strlen (name);

  for ( i = 0; i < length; i++ ) {
    if ( name[i] == '[' ) {
      int j = i + 1;

      while ( isdigit ((int) name[j]) ) {
	j++;
      }

      if ( name[j] != ']' ) {
	continue;
      }
      else {
	char *base = MALLOC (i + 1);	
	int index = atoi (name + i + 1);

	strncpy (base, name + 1, i-1);
	base[i-1] = 0;
	*bus_name_p = base;
	*index_p = index;

	return 1;
      }
    }
  }

  return 0;
}


static
void
rtl2dpc_make_bus (char *name, int left, int right, nl_design design)
{
  nl_type scalar = nl_type_get_scalar ((nl_object) design);
  nl_type type = nl_type_get_array (scalar, left, right);
  nl_bus bus = nl_bus_create (name, type, nl_kind_net, (nl_object) design);
  int i;
  int length = strlen (name);
  char *old_net_name = alloca (length + 20);
  char *new_net_name = alloca (length + 20);

  for ( i = left; i >= right; i-- ) {
    nl_net net;

    sprintf (old_net_name, "\\%s[%d]", name, i);
    sprintf (new_net_name, "%s[%d]", name, i);

    net = nl_design_get_net_by_name (design, old_net_name);

    if ( net != NULL ) {
      nl_net_rename (net, new_net_name);
    }
    else {
      net = nl_net_create (new_net_name, nl_wireclass_wire, design);
    }

    nl_bus_add_net (bus, net);
  }
}


void
rtl2dpc_infer_buses (nl_design design)
{
  hashtab net_table = ht_alloc (256, ht_hash_string, ht_compare_string,
				NULL, ht_free_string);
  ht_attr net_indexes
    = ht_new_attribute (net_table, sizeof (ar), NULL, NULL);
  
  nl_design_for_all_nets (design, net) {
    char *name = nl_net_name (net);

    if ( name[0] == '\\' ) {
      char *bus_name;
      int index;
      int flag = rtl2dpc_parse_netname (name, &bus_name, &index);

      if ( flag ) {
	ht_entry hte = ht_insert (net_table, bus_name);
	ar indexes;

	ht_get_attribute_for_entry (net_indexes, hte, &indexes);

	if ( indexes == NULL ) {
	  indexes = AR_NEW (1, int);
	  ht_set_attribute_for_entry (net_indexes, hte, &indexes);
	}

	ar_add (indexes, &index);
      }
    }
  } nl_end_for;

  ht_for_all_entries (net_table, ent) {
    ar indexes;
    int min = 0x7fffffff;
    int max = 0x80000000;
    int span;
    int size;
    int metric;

    ht_get_attribute_for_entry (net_indexes, ent, &indexes);

    ASSERT (indexes != NULL);

    size = ar_size (indexes);

    ar_for_all (indexes, int, index) {
      if ( index < min )
	min = index;

      if ( index > max )
	max = index;
    } ar_end_for;

    span = max - min;

    metric = size / (size - span);

    if ( metric >= 2 ) { /* It's a bus. */
      char *bus_name = ht_get_key (net_table, ent);

      fprintf (stderr, "Inferring bus for %s, width = %d, range = [%d:%d]\n",
	       bus_name, size, max, min);
      rtl2dpc_make_bus (bus_name, max, min, design);
    }
  } ht_end_for;

  ht_free (net_table);
}
