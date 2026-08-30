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
#include "str.h"

typedef struct nl_ast_s SORAST;
#define _refvar_inits ast2g_refvar_inits
#include "sorcerer.h"
#include "ast2g_infer_reg.h"

#include "ssa.h"
#include "ast2g_int.h"


static
nl_reference
ast2g_get_reg_ref (nl_design design, char clock_sense, int has_set_reset, 
		   int is_preset, char set_sense)
{
  char ref_name[16];
  nl_reference reference;

  if ( !has_set_reset ) {
    sprintf (ref_name, "JNPR_FF_%c", clock_sense);
  }
  else {
    char clear_preset;
    char *sync;

    if ( set_sense == 'H' || set_sense == 'L' ) {
      sync = "S";
    }
    else {
      sync = "";
    }

    if ( is_preset ) {
      clear_preset = 'P';
    }
    else {
      clear_preset = 'C';
    }

    sprintf (ref_name, "JNPR_FF_%c%s%c%c", clock_sense, sync, clear_preset,
	     set_sense);
  }

  reference = nl_design_get_reference_by_name (design, ref_name);

  if ( reference == NULL ) {
    char clock_name[8];
    char *clock_prefix;

    if ( clock_sense == 'L' || clock_sense == 'F' ) {
      clock_prefix = "n";
    }
    else {
      clock_prefix = "";
    }

    sprintf (clock_name, "%sclk", clock_prefix);

    reference = nl_reference_create (ref_name, design, NULL);

    nl_refpin_create (clock_name, NULL, reference);
    nl_refpin_create ("d", NULL, reference);
    nl_refpin_create ("q", NULL, reference);

    if ( has_set_reset ) {
      char reset_name[8];
      char *reset_prefix;
      char *reset_base;
      char *reset_suffix;

      if ( set_sense == 'L' || set_sense == 'F' ) {
	reset_prefix = "n";
      }
      else {
	reset_prefix = "";
      }

      if ( is_preset ) {
	reset_base = "set";
      }
      else {
	reset_base = "clr";
      }

      if ( set_sense == 'H' || set_sense == 'L' ) {
	reset_suffix = "";
      }
      else {
	reset_suffix = "b";
      }

      sprintf (reset_name, "%s%s%s", reset_prefix, reset_base, reset_suffix);

      nl_refpin_create (reset_name, NULL, reference);
    }
  }

  return reference;
}


int
ast2g_infer_registers_for_reference (nl_reference reference)
{
  nl_design design = nl_reference_design (reference);
  nl_ast tree = nl_reference_tree (reference);
  ar inputs = nl_reference_inputs (reference);
  ar outputs = nl_reference_outputs (reference);
  int num_inputs = ar_size (inputs);
  int num_outputs = ar_size (outputs);
  char *input_sense = MALLOC (num_inputs + 1);
  int clock_index;
  char clock_sense;
  int reset_index;
  int reset_sense;
  int reset_polarity;
  ar lhs_outs1 = ar_alloc (0, sizeof (int));
  ar lhs_outs2 = ar_alloc (0, sizeof (int));
  ar rhs_ins1 = ar_alloc (0, sizeof (int));
  ar rhs_ins2 = ar_alloc (0, sizeof (int));
  int *outs = NULL;
  char *reset_senses = NULL;
  int *data_values = NULL;
  int *reset_values = NULL;
  int i;
  int result = 0;

  for ( i = 0; i < num_inputs; i++ ) {
    input_sense[i] = ' ';
  }
  input_sense[num_inputs] = 0;

  {
    int finished = 0;

    error_unwind_protect {
      STreeParser stp;

      STreeParserInit (&stp);
      
      ast2g_register (&stp, &tree, num_inputs, num_outputs,
		      &reset_index, &reset_polarity, input_sense, 
		      lhs_outs1, rhs_ins1, lhs_outs2, rhs_ins2);
    } error_on_tag (2) {
      error_dont_continue ();
      finished = 1;
    } error_on_error {
      error_throw (error_current_tag);
    } error_end;

    if ( finished ) {
      goto done;
    }
  }

  /* Step 1. Get the clock index and sense. */
  clock_index = -1;
  for ( i = 0; i < num_inputs; i++ ) {
    if ( i == reset_index )
      continue;

    if ( clock_index < 0 ) {
      if ( input_sense[i] != ' ' ) {
	clock_index = i;
	clock_sense = input_sense[i];
      }
    }
    else {
      if ( input_sense[i] != ' ' ) {
	char *ref_name = nl_reference_name (reference);

	fprintf (stderr, "More than one clock in sensitivity list.  "
		 "Bailing on process %s\n", ref_name);
	goto done;
      }
    }
  }

  if ( clock_index < 0 ) {
    char *ref_name = nl_reference_name (reference);

    fprintf (stderr, "Couldn't find clock in sensitivity list.  "
	     "Bailing on process %s\n", ref_name);
    goto done;
  }

  /* Step 2. See what kind of reset we're dealing with. */
  if ( reset_index < 0 ) {
    reset_sense = ' ';
  }
  else {
    if ( input_sense[reset_index] == ' ' ) {
      /* Reset signal wasn't in the sensitivity list.  It must be
	 synchronous. */
      if ( reset_polarity == 0 )
	reset_sense = 'H';
      else
	reset_sense = 'L';
    }
    else {
      reset_sense = input_sense[reset_index];
    }
  }

  /* Step 3. Check the outputs */
  outs = MALLOC (num_outputs * sizeof (int));
  for ( i = 0; i < num_outputs; i++ ) {
    outs[i] = 0;
  }

  ar_for_all (lhs_outs1, int, out_index) {
    outs[out_index] |= 1;
  } ar_end_for;
      
  if ( reset_index < 0 ) {
    ar_for_all (lhs_outs1, int, out_index) {
      outs[out_index] |= 2;
    } ar_end_for;
  }
  else {
    ar_for_all (lhs_outs2, int, out_index) {
      outs[out_index] |= 2;
    } ar_end_for;
  }

  for ( i = 0; i < num_outputs; i++ ) {
    if ( outs[i] != 3 && outs[i] != 0 ) {
      char *ref_name = nl_reference_name (reference);

      /* One of the outputs does not appear in both branches. */
      fprintf (stderr, "Some output appears in only one branch.  "
	       "Bailing on process %s\n", ref_name);
      goto done;
    }
  }

  /* Step 4. Get the values for each of the outputs in both branches. */
  if ( reset_index < 0 ) {
    if ( ar_size (lhs_outs1) != ar_size (rhs_ins1) ) {
      char *ref_name = nl_reference_name (reference);

      fprintf (stderr, "LHS and RHS widths of branch 1 do not match.  "
	       "Bailing on process %s\n", ref_name);
      goto done;
    }

    data_values = MALLOC (num_outputs * sizeof (int));

    ar_for_all_indexed (lhs_outs1, int, out_index, i) {
      int in_index;

      ar_ref (rhs_ins1, i, &in_index);
	  
      data_values[out_index] = in_index;
    } ar_end_for;
  }
  else {
    char *rhs_values1 = MALLOC (num_outputs * sizeof (int));
    char *rhs_values2 = MALLOC (num_outputs * sizeof (int));

    if ( ar_size (lhs_outs1) != ar_size (rhs_ins1) ) {
      char *ref_name = nl_reference_name (reference);

      fprintf (stderr, "LHS and RHS widths of branch 1 do not match.  "
	       "Bailing on process %s\n", ref_name);
      FREE (rhs_values1);
      FREE (rhs_values2);
      goto done;
    }

    if ( ar_size (lhs_outs2) != ar_size (rhs_ins2) ) {
      char *ref_name = nl_reference_name (reference);

      fprintf (stderr, "LHS and RHS widths of branch 2 do not match.  "
	       "Bailing on process %s\n", ref_name);
      FREE (rhs_values1);
      FREE (rhs_values2);
      goto done;
    }

    ar_for_all_indexed (lhs_outs1, int, out_index, i) {
      int in_index;

      ar_ref (rhs_ins1, i, &in_index);

      rhs_values1[out_index] = in_index;
    } ar_end_for;

    ar_for_all_indexed (lhs_outs2, int, out_index, i) {
      int in_index;

      ar_ref (rhs_ins2, i, &in_index);

      rhs_values2[out_index] = in_index;
    } ar_end_for;

    /* Step 5. */
    reset_values = MALLOC (num_outputs * sizeof (int));
    reset_senses = MALLOC (num_outputs * sizeof (int));
    data_values = MALLOC (num_outputs * sizeof (int));
    for ( i = 0; i < num_outputs; i++ ) {
      if ( outs[i] == 3 ) {
	int rhs_in1 = rhs_values1[i];
	int rhs_in2 = rhs_values2[i];
	  
	if ( (reset_sense == 'R' && reset_polarity == 0) ||
	     (reset_sense == 'F' && reset_polarity == 1) ) {
	  if ( rhs_in1 < 0 ) {
	    reset_values[i] = rhs_in1;
	    data_values[i]  = rhs_in2;
	    reset_senses[i] = reset_sense;
	  }
	  else {
	    char *ref_name = nl_reference_name (reference);

	    fprintf (stderr, "Reset polarity does not match sensitivity "
		     "list.  Bailing on process %s\n", ref_name);
	    FREE (rhs_values1);
	    FREE (rhs_values2);
	    goto done;
	  }
	}
	else if ( (reset_sense == 'F' && reset_polarity == 0) ||
		  (reset_sense == 'R' && reset_polarity == 1) ) {
	  if ( rhs_in2 < 0 ) {
	    reset_values[i] = rhs_in2;
	    data_values[i]  = rhs_in1;
	    reset_senses[i] = reset_sense;
	  }
	  else {
	    char *ref_name = nl_reference_name (reference);

	    fprintf (stderr, "Reset polarity does not match sensitivity "
		     "list.  Bailing on process %s\n", ref_name);
	    FREE (rhs_values1);
	    FREE (rhs_values2);
	    goto done;
	  }
	}
	else {
	  ASSERT (reset_sense == 'H' || reset_sense == 'L');
	      
	  if ( rhs_in1 < 0 ) {
	    reset_values[i] = rhs_in1;
	    data_values[i]  = rhs_in2;
	    reset_senses[i] = reset_sense;
	  }
	  else if ( rhs_in2 < 0 ) {
	    reset_values[i] = rhs_in2;
	    data_values[i]  = rhs_in1;
	    if ( reset_sense == 'H' )
	      reset_senses[i] = 'L';
	    else 
	      reset_senses[i] = 'H';
	  }
	  else {
	    char *ref_name = nl_reference_name (reference);

	    fprintf (stderr, "Both branches of the IF are non-constant for"
		     " some output.  Bailing on process %s\n", ref_name);
	    FREE (rhs_values1);
	    FREE (rhs_values2);
	    goto done;
	  }
	}
      }
    }
  }

  /* Step 6. Report the result. */
  nl_reference_for_all_instances (reference, cell) {
    ar inputs = nl_cell_inputs (cell);
    ar outputs = nl_cell_outputs (cell);
    nl_pin clk_pin;
    nl_net clk_net;
    char *clk_name;
    nl_net rst_net;

    ar_ref (inputs, clock_index, &clk_pin);
    clk_net = nl_pin_net (clk_pin);
    clk_name = nl_net_name (clk_net);

    printf ("\n");
    printf ("Clock = %s, sense = %c\n", clk_name, clock_sense);

    if ( reset_index >= 0 ) {
      nl_pin rst_pin;
      char *rst_name;

      ar_ref (inputs, reset_index, &rst_pin);
      rst_net = nl_pin_net (rst_pin);
      rst_name = nl_net_name (rst_net);
      printf ("Reset = %s\n", rst_name);
    }
    else {
      printf ("No reset\n");
    }
	  
    printf ("+--------------+--------------+-------+-------+\n");
    printf ("| %-12s | %-12s | %-5s | %-5s |\n",
	    "Q", "D", "reset", "sense");
    printf ("+--------------+--------------+-------+-------+\n");

    for ( i = 0; i < num_outputs; i++ ) {
      if ( outs[i] == 3 ) {
	nl_pin q_pin;
	nl_net q_net;
	nl_pin d_pin;
	nl_net d_net;
	char *q_name;
	char *d_name;
	char *set;
	char set_sense;

	ar_ref (outputs, i, &q_pin);
	q_net = nl_pin_net (q_pin);

	if ( q_net != NULL )
	  q_name = nl_net_name (q_net);
	else
	  q_name = "*NC*";

	if ( data_values[i] < 0 ) {
	  if ( data_values[i] == -1 ) {
	    d_name = "1'b0";
	  }
	  else if ( data_values[i] == -2 ) {
	    d_name = "1'b1";
	  }
	  else {
	    ASSERT (0);
	  }

	  d_net = ast2g_get_net (NULL, design, d_name);
	}
	else {
	  ar_ref (inputs, data_values[i], &d_pin);
	  d_net = nl_pin_net (d_pin);

	  if ( d_net != NULL )
	    d_name = nl_net_name (d_net);
	  else
	    d_name = "*NC*";
	}

	if ( reset_index < 0 ) {
	  set = "---";
	  set_sense = '-';
	}
	else {
	  set_sense = reset_senses[i];
	  if ( reset_values[i] == -1 )
	    set = "clear";
	  else if ( reset_values[i] == -2 )
	    set = "set";
	  else
	    set = "???";
	}

	printf ("| %-12s | %-12s | %-5s | %-5c |\n",
		q_name, d_name, set, set_sense);

	{
	  nl_design design = nl_reference_design (reference);
	  int has_reset = reset_index >= 0;
	  int reset_val = has_reset ? reset_values[i] == -2 : 0;
	  nl_reference reg_ref = ast2g_get_reg_ref (design, clock_sense,
						    has_reset, reset_val,
						    set_sense);
	  char *cell_name = str_append (q_name, "_reg", NULL);
	  nl_cell reg_cell = nl_cell_create (cell_name, reg_ref);

	  FREE (cell_name);

	  if ( clock_sense == 'R' ) {
	    nl_refpin clk_refpin = (nl_refpin)
	      nl_reference_get_refpin_by_name (reg_ref, "clk");
	    nl_pin clk_pin
	      = nl_cell_get_pin_by_refpin (reg_cell, clk_refpin);

	    nl_pin_connect_net (clk_pin, clk_net);
	  }
	  else if ( clock_sense == 'F' ) {
	    nl_refpin clk_refpin = (nl_refpin)
	      nl_reference_get_refpin_by_name (reg_ref, "nclk");
	    nl_pin clk_pin
	      = nl_cell_get_pin_by_refpin (reg_cell, clk_refpin);

	    nl_pin_connect_net (clk_pin, clk_net);
	  }
	  else {
	    ASSERT (0);
	  }

	  {
	    nl_refpin d_refpin = (nl_refpin)
	      nl_reference_get_refpin_by_name (reg_ref, "d");
	    nl_pin d_pin
	      = nl_cell_get_pin_by_refpin (reg_cell, d_refpin);

	    nl_pin_connect_net (d_pin, d_net);
	  }

	  {
	    nl_refpin q_refpin = (nl_refpin)
	      nl_reference_get_refpin_by_name (reg_ref, "q");
	    nl_pin q_pin
	      = nl_cell_get_pin_by_refpin (reg_cell, q_refpin);

	    nl_pin_connect_net (q_pin, q_net);
	  }

	  if ( reset_index >= 0 ) {
	    if ( reset_values[i] == -1 ) {
	      /* clear */
	      char *clr_name;
	      nl_refpin clr_refpin;
	      nl_pin clr_pin;

	      switch ( set_sense ) {
	      case 'R':
		clr_name = "clrb";
		break;
	      case 'F':
		clr_name = "nclrb";
		break;
	      case 'H':
		clr_name = "clr";
		break;
	      case 'L':
		clr_name = "nclr";
		break;
	      default:
		ASSERT (0);
	      }

	      clr_refpin = (nl_refpin)
		nl_reference_get_refpin_by_name (reg_ref, clr_name);
	      clr_pin
		= nl_cell_get_pin_by_refpin (reg_cell, clr_refpin);

	      nl_pin_connect_net (clr_pin, rst_net);
	    }
	    else if ( reset_values[i] == -2 ) {
	      /* preset */
	      char *set_name;
	      nl_refpin set_refpin;
	      nl_pin set_pin;

	      switch ( set_sense ) {
	      case 'R':
		set_name = "setb";
		break;
	      case 'F':
		set_name = "nsetb";
		break;
	      case 'H':
		set_name = "set";
		break;
	      case 'L':
		set_name = "nset";
		break;
	      default:
		ASSERT (0);
	      }

	      set_refpin = (nl_refpin)
		nl_reference_get_refpin_by_name (reg_ref, set_name);
	      set_pin
		= nl_cell_get_pin_by_refpin (reg_cell, set_refpin);

	      nl_pin_connect_net (set_pin, rst_net);
	    }
	    else {
	      ASSERT (0);
	    }
	  }
	}
      }
    }

    printf ("+--------------+--------------+-------+-------+\n");
    printf ("\n");
  } nl_end_for;

  {
    nl_design design = nl_reference_design (reference);
    ar ref_cells = nl_reference_instances (reference);
    ar cells = ar_copy (ref_cells);

    ar_for_all (cells, nl_cell, cell) {
      nl_design_remove_cell (design, cell);
    } ar_end_for;

    ar_free (cells);

    nl_design_remove_reference (design, reference);

    result = 1;
  }

 done:
  FREE (input_sense);
  ar_free (lhs_outs1);
  ar_free (lhs_outs2);
  ar_free (rhs_ins1);
  ar_free (rhs_ins2);
  if ( outs != NULL )
    FREE (outs);
  if ( reset_senses != NULL )
    FREE (reset_senses);
  if ( reset_values != NULL )
    FREE (reset_values);
  if ( data_values != NULL )
    FREE (data_values);

  return result;
}


void
ast2g_infer_registers (nl_design design)
{
  nl_design_for_all_references (design, reference) {
    char *ref_name = nl_reference_name (reference);

    if ( strncmp (ref_name, "*process", 8) == 0 ) {
      ast2g_infer_registers_for_reference (reference);
    }
  } nl_end_for;
}
