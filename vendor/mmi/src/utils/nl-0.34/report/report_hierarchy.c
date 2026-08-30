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
#include "report.h"


static
void
report_hierarchy_internal (nl_design design, int indent)
{
  nl_design_for_all_references (design, reference) {
    char *ref_name = nl_reference_name (reference);
    int num_inst;

    if ( ref_name[0] == '*' ) {
      continue;
    }

    num_inst = nl_reference_num_instances (reference);

    if ( num_inst > 0 ) {
      nl_object down_object = nl_reference_down_design (reference);
      int i;

      for ( i = 0; i < indent; i++ ) {
	putchar (' ');
      }

      if ( down_object == NULL) {
	printf ("%s (unlinked)\n", nl_reference_name (reference));
      }
      else {
	nl_kind down_object_kind = nl_object_kind (down_object);

	if ( down_object_kind == nl_kind_libcell ) {
	  nl_libcell libcell = (nl_libcell) down_object;

	  printf ("%s (libcell)\n", nl_libcell_name (libcell));
	}
	else {
	  nl_design down_design = (nl_design) down_object;
	  char *name = nl_design_name (down_design);
	  printf ("%s:", name);

	  nl_reference_for_all_instances (reference, cell) {
	    char *cell_name = nl_cell_name (cell);

	    printf (" %s", cell_name);
	  } nl_end_for;

	  printf ("\n");

	  report_hierarchy_internal (down_design, indent + 4);
	}
      }
    }
  } nl_end_for;
}


void
report_hierarchy (nl_design design)
{
  char *name = nl_design_name (design);
  printf ("Hierarchy report for %s:\n", name);

  printf ("\n");
  printf ("%s\n", name);

  report_hierarchy_internal (design, 4);

  printf ("\n");
}
