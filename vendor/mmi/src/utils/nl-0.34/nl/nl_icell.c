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
#include "nl_int.h"



/*internal*/
nl_icell
nl_icell_create (nl_cell cell, nl_idesign idesign, nl_predicate pred)
{
  nl_icell result = nl_idesign_alloc_icell (idesign, cell);
  nl_reference reference = nl_cell_reference (cell);
  nl_object down_design = nl_reference_down_design (reference);

  result->cell = cell;

  nl_cell_for_all_pins (cell, pin) {
    nl_ipin_create (pin, idesign);
  } nl_end_for;

  {
    int stop = (down_design == NULL ||
		nl_object_kind (down_design) != nl_kind_design);
		
    if ( !stop && pred != NULL ) {
      stop = pred (down_design);
    }

    if ( stop ) {
      result->down_design = NULL;
    }
    else {
      result->down_design = nl_idesign_create ((nl_design) down_design, result, pred);
    }
  }

  return result;
}


/*internal*/
void
nl_icell_link (nl_icell icell)
{
  nl_cell cell = icell->cell;
  nl_reference reference = nl_cell_reference (cell);
  nl_object down_design = nl_reference_down_design (reference);

  if ( down_design != NULL &&
       nl_object_kind (down_design) == nl_kind_design ) {
    nl_idesign down_idesign
      = nl_idesign_create ((nl_design) down_design, icell, NULL);

    icell->down_design = down_idesign;
  }
}


/*internal*/
void
nl_icell_unlink (nl_icell icell)
{
  icell->down_design = NULL;
}


/*exported*/
nl_idesign
nl_icell_root_idesign (nl_icell icell)
{
  nl_icell parent = icell;
  nl_idesign result;

  do {
    result = nl_icell_idesign (parent);
    parent = nl_idesign_icell (result);
  } while (parent != NULL);

  return result;
}


/*internal*/
void
nl_icell_free (nl_icell icell)
{
  nl_idesign idesign = icell->idesign;

  nl_idesign_free_object (idesign, (nl_idesign_object) icell);
}


/*exported*/
char *
nl_icell_name (nl_icell icell)
{
  nl_cell cell = icell->cell;
  char *name = nl_cell_name (cell);

  return name;
}


/*exported*/
nl_ipin
nl_icell_get_ipin_by_refpin (nl_icell icell, nl_refpin refpin)
{
  nl_idesign idesign = icell->idesign;
  nl_cell cell = icell->cell;
  nl_pin pin = nl_cell_get_pin_by_refpin (cell, refpin);
  nl_ipin ipin = nl_idesign_get_ipin (idesign, pin);

  return ipin;
}


/*exported*/
nl_reference
nl_icell_reference (nl_icell icell)
{
  nl_cell cell = icell->cell;
  nl_reference reference = nl_cell_reference (cell);

  return reference;
}



