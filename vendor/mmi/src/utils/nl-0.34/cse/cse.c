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

struct cse_data {
  nl_net_attr net_attr;
  ar net_table;
  ar terms;
};


void
cse_build_tables (nl_design design)
{
  struct cse_data data;

  nl_design_for_all_references (design, reference) {
    char *ref_name = nl_reference_name (reference);

    if ( strncmp (ref_name, "*expression", 11) == 0 ) {
      nl_ast tree = nl_reference_tree (reference);

      nl_reference_for_all_instances (reference, cell) {
	ar inputs = nl_cell_inputs (cell);
	ar outputs = nl_cell_outputs (cell);

	cse_build_tables_for_expression (design, &data, tree,
					 inputs, outputs);
      } nl_end_for;
    }
    else if ( strncmp (ref_name, "*process", 8) == 0 ) {
      nl_ast tree = nl_reference_tree (reference);
      
      nl_reference_for_all_instances (reference, cell) {
	ar inputs = nl_cell_inputs (cell);
	ar outputs = nl_cell_outputs (cell);

	cse_build_tables_for_process (design, &data, tree,
				      inputs, outputs);
      } nl_end_for;
    }
  } nl_end_for;
}
