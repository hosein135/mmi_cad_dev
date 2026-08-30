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
#include "unparse.h"
#include "nl.h"
#include "nl2sim.h"


static void nl2sim_write_design (unparse_fp, nl_design, int, char *, hashtab);


static
void
nl2sim_write_ports (unparse_fp ufp, nl_design design)
{
  nl_design_for_all_ports (design, port) {
    nl_direction dir = nl_port_direction (port);
    char *name = nl_port_name (port);

    unparse_token (ufp, "A", 0);
    unparse_token (ufp, name, 1);

    switch ( dir ) {
    case nl_direction_in:
      unparse_token (ufp, "input", 1);
      break;
    case nl_direction_out:
      unparse_token (ufp, "output", 1);
      break;
    case nl_direction_inout:
    case nl_direction_unknown:
      unparse_token (ufp, "inout", 1);
      break;
    default:
      ASSERT (0);
    }

    unparse_newline (ufp);
  } nl_end_for;
}


static
void
nl2sim_write_references (unparse_fp ufp, nl_design design,
			 int hierarchy, char *prefix, hashtab defined)
{
  nl_design_for_all_references (design, reference) {
    char *ref_name = nl_reference_name (reference);
    nl_object down_object = nl_reference_down_design (reference);
    int num_instances = nl_reference_num_instances (reference);
    int is_leaf = ((down_object == NULL) ||
		   nl_object_kind (down_object) == nl_kind_libcell ||
		   nl_design_libcell ((nl_design) down_object));

    if ( num_instances > 0 && (! hierarchy || is_leaf) ) {
      ht_entry ent = ht_lookup (defined, ref_name);

      if ( ent == ht_null ) {
	unparse_token (ufp, "DEFINE", 0);
	unparse_token (ufp, ref_name, 1);

	nl_reference_for_all_refpins (reference, refpin) {
	  char *refpin_name = nl_refpin_name (refpin);

	  unparse_token (ufp, refpin_name, 1);
	} nl_end_for;

	unparse_newline (ufp);

	ht_insert (defined, ref_name);
      }
    }
  } nl_end_for;
}


static
void
nl2sim_write_pins (unparse_fp ufp, nl_cell cell, nl_reference reference,
		   char *prefix, int *unconnected_count_p)
{
  nl_reference_for_all_refpins (reference, refpin) {
    nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
    nl_net net = nl_pin_net (pin);
    char *net_name;

    if ( net != NULL ) {
      net_name = nl_net_name (net);
    }
    else {
      char buf[40];
      sprintf (buf, "*MMI_NC_%d*", *unconnected_count_p);
      (*unconnected_count_p)++;
      net_name = buf;
    }

    unparse_token (ufp, prefix, 1);
    unparse_token (ufp, net_name, 0);
  } nl_end_for;
}


static
void
nl2sim_write_pin_equates (unparse_fp ufp, nl_cell cell, nl_reference reference,
			  char *up_prefix, char *down_prefix)
{
  nl_reference_for_all_refpins (reference, refpin) {
    char *refpin_name = nl_refpin_name (refpin);
    nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
    nl_net net = nl_pin_net (pin);
    char *net_name;

    if ( net != NULL ) {
      net_name = nl_net_name (net);

      unparse_token (ufp, "=", 0);
      unparse_token (ufp, up_prefix, 1);
      unparse_token (ufp, net_name, 0);
      unparse_token (ufp, down_prefix, 1);
      unparse_token (ufp, refpin_name, 0);
      unparse_newline (ufp);
    }
  } nl_end_for;
}


static
void
nl2sim_write_cells (unparse_fp ufp, nl_design design, int hierarchy,
		    char *prefix, hashtab defined)
{
  int unconnected_count = 0;

  nl_design_for_all_cells (design, cell) {
    nl_reference reference = nl_cell_reference (cell);
    nl_object down_object = nl_reference_down_design (reference);
    int is_leaf = ((down_object == NULL) ||
		   nl_object_kind (down_object) == nl_kind_libcell ||
		   nl_design_libcell ((nl_design) down_object));

    if ( ! hierarchy || is_leaf ) {
      char *ref_name = nl_reference_name (reference);

      unparse_token (ufp, ref_name, 0);
      nl2sim_write_pins (ufp, cell, reference, prefix, &unconnected_count);
      unparse_newline (ufp);
    }
    else {
      nl_design down_design = (nl_design) down_object;
      char *cell_name = nl_cell_name (cell);
      int cell_name_len = strlen (cell_name);
      int old_prefix_len = strlen (prefix);
      char *new_prefix = alloca (old_prefix_len + cell_name_len + 1 + 1);

      sprintf (new_prefix, "%s%s.", prefix, cell_name);
      nl2sim_write_pin_equates (ufp, cell, reference, prefix, new_prefix);
      nl2sim_write_design (ufp, down_design, hierarchy, new_prefix, defined);
    }
  } nl_end_for;
}


static
void
nl2sim_write_design (unparse_fp ufp, nl_design design, int hierarchy,
		     char *prefix, hashtab defined)
{
  unparse_token (ufp, "|", 0);
  unparse_token (ufp, "begin", 1);
  unparse_token (ufp, nl_design_name (design), 1);
  unparse_newline (ufp);

  if ( prefix[0] == 0 ) {
    nl2sim_write_ports (ufp, design);
  }
  nl2sim_write_references (ufp, design, hierarchy, prefix, defined);
  nl2sim_write_cells (ufp, design, hierarchy, prefix, defined);

  unparse_token (ufp, "|", 0);
  unparse_token (ufp, "end", 1);
  unparse_token (ufp, nl_design_name (design), 1);
  unparse_newline (ufp);
}


int
nl2sim_write_sim (FILE *ofp, nl_design design, int hierarchy)
{
  unparse_fp ufp;
  hashtab defined = ht_alloc (64, ht_hash_string, ht_compare_string,
			      NULL, NULL);
    
  fprintf (ofp, "| units: 1.0  tech: sue  format: UCB\n");

  ufp = unparse_open (ofp);
  unparse_set_line_limit (ufp, 0x7fffffff);

  nl2sim_write_design (ufp, design, hierarchy, "", defined);

  unparse_close (ufp);

  return 1;
}
