## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
## ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
## JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
## DAMAGE.
## 
## JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
## UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

set RCSVERSION(duplicate.tcl) { $Revision: 1.20 $ }

proc duplicate_mode_enter {} -desc {
  duplicate selected
} {

  global _DUPLICATE

  # is anything selected?
  if {[sel_what types] != "" || [sel_what labels] != "" || \
	  [sel_what cells -edit_only {}] != ""} {

    global MAX_NEW_SELECT
    if {[use_first MAX_NEW_SELECT] == 1} {
	# Drop the selection into group 0
	db_group selected
	sel_group_transfer 0
    }

    # make new copy of selected stuff in group selected
    db_group selected

    global DUP_OFFSET
    set DUP_OFFSET [list [max [res -userx] 0.25] [max [res -usery] 0.25]]
    set DUP_OFFSET [eval uusnap -user $DUP_OFFSET]
    setl {offsetx offsety} $DUP_OFFSET
    sel_duplicate -dup_ok $offsetx $offsety
    # Move box, too.
    box_move $offsetx $offsety

    # Hidden labels must NOT be duplicated.
    # It screws up flylines - they dont know whether they
    # should connect to the original or the duplicate.
    # However, this is a potentially expensive operation, so only
    # do it if there are flylines extant.
    if {[string trim [db_flyline]] != ""} {
      sel_labels -less -kind hidden
    }

    if {[use_first MAX_NEW_SELECT] == 1} {
	# NOTE: If you re-enable this code, then probably an old bug will
	# resurface: if you move the cursor after pushing d but
	# before pressing the button, the duplicated group will jump.
	# The auto-move after a duplicate could be eliminated
	# if selection is always in the select group, however. (pat)

	# NOTE: Also need to fix this bug: if you hold down shift key,
	# want to align with origx, origy, not location where duplicated
	# group is now.
	db_group 0
	move_something_mode_enter
	return
    }

    mode_push duplicate
  }
}

proc _duplicate_mode_define {} -desc {
  duplicate and move selection
} {
  mode_def duplicate _duplicate_gate_keeper "BUT-1/2 moves duplicate, CTRL-C aborts"

  mode_bind -cmd 0 duplicate <Any-Button-1> \
    "move_something_mode_enter duplicate"
  mode_bind -cmd 0 duplicate <Any-Button-2> \
    "move_something_mode_enter duplicate"
}

proc _duplicate_gate_keeper {event} {
  global mode_abort
  if { $event == "PUSH_TO" } {
    cursor_mode move
  } elseif { $event == "POP_FROM" } {
    if { $mode_abort } {
      # We aborted without ever getting into move_something mode.
      # Delete the duplicate we created.
      undo_to_delim
      undo_flush_redo
      msg "aborting duplicate!\n"
    } else {
      db_group selected
      sel_group_transfer 0
    }
  }
}
