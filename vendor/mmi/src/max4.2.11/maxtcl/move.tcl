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

set RCSVERSION(move.tcl) { $Revision: 1.38 $ }

# User interface to moves

# This is the message printed in the box status window.
set _move_message "dx: %6.3g  dy: %6.3g"


proc move_something {{type "move"}} -desc {
  Move something, bound to button-2 in main mode.
} -doc {
  Move selection, or move/resize the box if nothing selected.
} {
  # is anything selected?
  if {[dbt_any_selection]} {

    move_something_mode_enter $type
  } else {
    # nothing is selected so move/resize the box
    if { $type == "move" } {
      box_modify
    }
  }
}

proc _move_init {type} -desc {
  Init interactive move.
} {
  global SAVE

  # This defaults to use user grid.
  set gridname [_move_get_gridname]
  setl {x y} [eval uusnap -grid $gridname [layt_point user]]

  # SAVE(x),SAVE(y) is the last point we moved to.
  set SAVE(x) $x
  set SAVE(y) $y

  # SAVE(origx),SAVE(origy) is the original point we moved from.
  set SAVE(origx) $x
  set SAVE(origy) $y

  set SAVE(type) $type
  set SAVE(stretch) ""
  set SAVE(box) [lay_box]

  if { $type == "duplicate" } {
    # special case: The duplicate was already moved up and left,
    # so make origx,origy off by same amount.
    global DUP_OFFSET
    setl {offsetx offsety} $DUP_OFFSET
    set SAVE(origx) [expr $x - $offsetx]
    set SAVE(origy) [expr $y - $offsety]
  }
}

proc move_something_mode_enter {{type "move"}} -desc {
  move selected or move/resize the box if nothing is selected
} -doc {
  type is empty for move, "stretch" for stretch,
  "stretch2" for connectivity stretch, "rewire" for rewire.
} {
  # Warning: SAVE shared with clipboard.tcl
  _move_init $type

  # This code was used when rewire was called from main mode in mode.tcl
  switch $type {
    rewire {
      # wire mode
      #_select_wire
      mode_push move_selected
    }
    duplicate -
    paste {
      # Change from paste/duplicate mode to move_selected mode.
      # Do a -enter because we do NOT want to call the prop gate-keeper
      # for duplicate or clipboard-paste, because they move the selected
      # paint from group selected to group 0.
      mode_change -enter move_selected
    }
    default {
      mode_push move_selected
    }
  }
}

proc rewire_mode_enter {} -desc {
  Move wire segment.
} {
    mode_push rewire
}

proc _rewire_mode_define {} -desc {
  Define rewire mode.
} {
  # No gate_keeper required
  mode_def rewire {} "BUT-1 selects BUT-2 moves"
  mode_bind -cmd 0 rewire <Button-1> _rewire_select
}

proc _rewire_select {} {
  global SAVE

  # check to see if there is anything in the current cell
  # on this layer
  #if {[db_search paint -area $x $y $x $y] == ""} {
  #  # nothing, just return
  #  return
  #}
  catch {unset SAVE}

  if { [_select_wire] == 0} {
    # Nothing selected.  Do nothing.
    return
  }

  move_something_mode_enter rewire
}

proc _move_selected_mode_define {} -desc {
  move selected mode using mouse button-2
} {
  set mode move_selected

  mode_def $mode _move_selected_gate_keeper \
    "SHIFT constrains x/y, release button to end, s suspends, Ctrl-C aborts"

  mode_bind -cmd 0 $mode <Motion> _move_selected_move \
    -desc "drag selection"
  mode_bind -cmd 0 $mode <Shift-Motion> "_move_selected_move shift" \
    -desc "drag selection, restrict x or y"

  # Code used to let user push Ctrl button after starting move.
  # This was full of bugs, so I removed it. (pat)
  # If user wants a stretch, they must press Control before B2,
  # which then locks in stretch mode for that move.
  # Since the control button might be down, we need this binding.
  mode_bind -cmd 0 $mode <Control-Motion> _move_selected_move
  mode_bind -cmd 0 $mode <Any-B1-ButtonRelease> mode_pop
  mode_bind -cmd 0 $mode <Any-B2-ButtonRelease> mode_pop
  mode_bind -cmd 0 $mode s "mode_push move_again" \
    -desc "Temporarily suspend move; allows you to move mouse to new location"
}

if {0} {
proc _move_pasted_mode_define {} -desc {
  Move pasted with mouse mode
} -doc {
  Used for clipboard paste, duplicate, cell drop.
  Almost identical to move_selected, but moves without
  having to hold down a mouse button,
  and does not allow stretch.
} {
  set mode move_pasted
  # Use same gate-keeper as move_selected.
  mode_def $mode _move_selected_gate_keeper \
    "SHIFT constrains x/y, release button to end, s suspends, Ctrl-C aborts"

  mode_bind -cmd 0 $mode <Any-Motion> _move_selected_move \
    -desc "drag paste buffer"
  mode_bind -cmd 0 $mode <Any-Shift-Motion> "_move_selected_move shift" \
    -desc "drag paste buffer, restrict x or y"
  mode_bind -cmd 0 $mode <Any-Button> "mode_pop;mode_pop" \
    -desc "drop paste buffer in current position" 
  mode_bind -cmd 0 $mode s "mode_push move_again" \
    -desc "Temporarily suspend move; allows you to move mouse to new location"
}
}


proc _move_again_mode_define {} -desc {
  temporarily suspend move so user can reposition mouse.  Called from move_selected mode. 
} {
  set mode move_again

  mode_def $mode _move_again_gate_keeper \
    "BUT-2 re-starts move, Esc ends move, Ctrl-C aborts move"
  mode_bind -cmd 0 $mode <Escape> "mode_pop;mode_pop" \
    -desc "End move, leave selection at current position"
  # Restart the move in move_selected mode, so user does
  # not have to hold down the mouse button any longer.
  mode_bind -cmd 0 $mode <Any-Button-1> "mode_pop;mode_change -force move_selected;cursor_mode move" \
    -desc "Re-start moving selection from current point"
  mode_bind -cmd 0 $mode <Any-Button-2> "mode_pop;mode_change -force move_selected;cursor_mode move" \
    -desc "Re-start moving selection from current point"
}

proc _move_again_gate_keeper {event} {
  global SAVE
  if {$event == "PUSH_TO"} {
    pan_auto ""  ;# Dont auto-move during pan while suspended.
    cursor_mode move
  } else {
    # We are going to restart the move from the current point.
    # That means SAVE(x),SAVE(y) must be set to the current point.
    # We must also warp SAVE(origx),SAVE(origy)
    # to make sure that the total amount moved shown by
    # box_msg_update is correct, and that shift-mode (constrain manhattan)
    # will work properly.
    setl {x y} [eval uusnap -grid [_move_get_gridname] [layt_point user]]
    set SAVE(origx) [expr $SAVE(origx) + $x - $SAVE(x)]
    set SAVE(origy) [expr $SAVE(origy) + $y - $SAVE(y)]
    set SAVE(x) $x
    set SAVE(y) $y
  }
}

proc _move_get_gridname {} -desc {
  See if we want to use a different grid for any selected cells.
} -doc {
  This could be slow, do only do it if floorplanner on.
} {
  global SAVE FPLAN
  set SAVE(grid) "user"
  if {[use_first FPLAN(exists)] == "1"} {
    foreach cell_info [sel_what_l cells] {
      struct max_cell c $cell_info
      set cellgrid [db_prop -def ${c.def} grid]
      if {$cellgrid != "" && [res2 $cellgrid] != ""} {
	set SAVE(grid) $cellgrid
	break
      }
    }
  }
  return $SAVE(grid)
}

proc _move_selected_gate_keeper {event} -desc {
    called whenever mode is entered/exited
} {
  global SAVE mode_abort

  if {$event == "PUSH_TO"} {
    _move_get_gridname
    pan_enable

    status_enable box 0
    global _move_message
    box_msg_update [format $_move_message 0 0]

    cursor_mode move

    global MAX_NEW_SELECT
    if {[use_first MAX_NEW_SELECT] == 1} {
      db_group selected
    } else {
      # For "duplicate" and "paste" modes, the buffer has
      # already been copied to group "selected"
      switch $SAVE(type) {
	"move" {
	  sel_group_transfer selected
	}
	"stretch2" {
	  #save_selection __MOVE_TMP__
	}
      }
    }

  } elseif {$event == "POP_TO"} {
    # Coming from move_again mode.
    # Continue the move where we left off.
    cursor_mode move

  } elseif {$event == "POP_FROM"} {
    pan_disable
    status_enable box 1

    if { $mode_abort } {
      undo_to_delim
      undo_flush_redo
      msg "aborting $SAVE(type)!\n"
    } else {
      global MAX_NEW_SELECT
      if {[use_first MAX_NEW_SELECT] == 1} {
	# now that the move is over, put the moved stuff back
	# into its original group.
	if { $SAVE(type) == "move" || $SAVE(type) == "paste" } {
	    # Simple move of currently selected stuff.
	    # sel_group_transfer $SAVE(move_orig_group)
	} else {
	    # We must transfer the stuff we just stretched as well
	    # as the original selected group.
	    #group_transfer group_move_selected $SAVE(move_orig_group)
	    db_group selected
	    sel_group_transfer select_tmp
	    group_transfer selected 0
	    db_group select_tmp
	    sel_group_transfer selected
	    db_group 0
	}
      } else {
	db_group selected  ;# Just in case.
	sel_group_transfer 0
	sel_move 0 0  ;# Merge sub-cells that are on top of each other.
      }
    }
    db_group 0

    i_cmd_between
  }
}

proc _move_vec2dir {dx dy} -desc {
    return nearest manhattan direction ("",N,S,E,W) for vector dx,dy
} {
    if {$dx == 0 && $dy == 0} { return "" }
    if {abs($dx) > abs($dy)} {
	if { $dx > 0 } {
	    return "E"
	} else {
	    return "W"
	}
    } else {
	if { $dy < 0 } {
	    return "S"
	} else {
	    return "N"
	}
    }
}

proc _move_selected_move {{shift ""}} -desc {
  move selected with cursor
} -doc {
    If "shift", constrain move to strictly horizontal or vertical.  If "stretch" constrain and stretch.
} {
  global SAVE

  switch $SAVE(type) {
    "stretch" -
    "rewire" {
      # ignore shift/control keys, so user can't let go of
      # alt or control key and be surprised
      set op stretch
      set shift shift  ;# Always constrain
    }
    "stretch2" {
      # ignore shift/control keys, so user can't let go of
      # alt or control key and be surprised
      set op stretch2
      set shift shift  ;# Always constrain

      set shift stretch2  ;# TODO: what is this?
    }
    "move" {
      set op move
      # Do not let user "drop" into stretch mode in the
      # middle of a move.
      #if { $shift == "stretch" } {
      #	set op stretch  ;# Drop into stretch mode right now.
      #}
    }
    "duplicate" -
    "paste" {
      # clipboard_paste is identical to move, except you cant suddenly
      # drop into stretch mode.  It also uses different mouse bindings,
      # so you can move selection without holding Button-2.
      set op move
    }
    default { error "unrecognized $SAVE(type)" }
  }

  pan_auto "_move_selected_move $shift"

  setl {x y} [layt_point user]
  # Get cached grid from use_first instead of calling _move_get_gridname.
  setl {x y} [uusnap -grid [use_first SAVE(grid) 'user] $x $y]
  if {$x == "" || $y == ""} {
    # off screen
    return
  }


  if {$shift != ""} {
    # constrain move to one direction only

    # origdir is the direction we were going last.
    set origdx [expr $SAVE(x) - $SAVE(origx)] 
    set origdy [expr $SAVE(y) - $SAVE(origy)]
    set origdir [_move_vec2dir $origdx $origdy]

    # dir is the direction we are going now.
    set curdx [expr $x - $SAVE(origx)]
    set curdy [expr $y - $SAVE(origy)]

    # If SAVE(stretch), constrain move to be in that axis only.
    if {$SAVE(stretch) == "x"} {
	set dir [_move_vec2dir $curdx 0]
	if { $dir == "" } { set dir "E" }
    } elseif {$SAVE(stretch) == "y"} {
	set dir [_move_vec2dir 0 $curdy]
	if { $dir == "" } { set dir "N" }
    } else {
	set dir [_move_vec2dir $curdx $curdy]
    }

    if { $op == "stretch2" && $origdir != "" && $dir != $origdir } {
      # If stretching one direction removes some paint,
      # this will pop it back into existence, which is not what we want.
      #undo_to_delim
      #restore_selection __MOVE_TMP__

      # Go back to original spot, before moving in a different direction.
      stretch_selected W $origdx
      stretch_selected S $origdy

      set SAVE(x) $SAVE(origx)
      set SAVE(y) $SAVE(origy)
    }

    if { $op == "stretch" && $origdir != "" && $dir != $origdir } {
	# Switching from horiz to vert stretch, or vice versa,
	# in which case we MUST go through the zero position
	# or the stretch will fail to grab the stuff that needs stretching.
	# Or, we could be switching from E to W or N to S, in which
	# case undoing is a user convenience: if the user stretched too
	# far and accidently merged paint with something else, they can
	# move back to the original position to do an undo and
	# start over.

	# TODO: This did not work.  When you go through the zero position
	# it screws up somehow.
	#   undo_to_delim
	#   undo_delim
	#   sel_group_transfer selected
        #   update idletasks

	# Go back to original spot, before moving in a different direction.
	:stretch W $origdx
	:stretch S $origdy

	# We have moved back to the orig spot.
	set SAVE(x) $SAVE(origx)
	set SAVE(y) $SAVE(origy)
    }

    if { $dir == "E" || $dir == "W" } {
	set y $SAVE(origy)
    } else {
	set x $SAVE(origx)
    }
  } else {
    # normal unconstrained move
  }
  set dx [expr $x - $SAVE(x)]
  set dy [expr $y - $SAVE(y)]
  set SAVE(x) $x
  set SAVE(y) $y

  # If you dont check for 0, you can get things like 1e-23.
  global _move_message
  set totalx [expr $SAVE(x) - $SAVE(origx)]
  set totaly [expr $SAVE(y) - $SAVE(origy)]
  if {[approx $totalx == 0]} { set totalx 0 }
  if {[approx $totaly == 0]} { set totaly 0 }
  box_msg_update [format $_move_message $totalx $totaly]

  # do it

  switch $op {
    "stretch2" {
      stretch_selected E $dx
      stretch_selected N $dy
    }
    "stretch" {

#     if {$x != $SAVE(origx) || $y != $SAVE(origy)} {
#       :undo
#     }
#     if {[expr abs($x - $SAVE(origx))] > [expr abs($y -$SAVE(origy))]} {
#       set dx [expr $x - $SAVE(origx)]
#       set dy 0
#     } else {
#       set dy [expr $y - $SAVE(origy)]
#       set dx 0
#     }

      :stretch E $dx
      :stretch N $dy
    }
    default {
      # Move the box
      set SAVE(box) [move_rect $SAVE(box) $dx $dy]
      eval lay_box $SAVE(box)

      # Move the selection
      sel_move -dup_ok $dx $dy

      #:move E $dx;:move N $dy
    }
  }
}


proc _select_wire {} -desc {
  selects wire under cursor and attached vias
} -doc {
    return 1 if selected something, 0 on failure.
} {

  global SAVE max_win

  # start from cursor - use exact cursor location to find the paint
  # to select.
  setl {x y} [layt_point exact]

  set lay_rootcell [lay_rootcell]
  set lay_editcell [lay_editcell]

  # check to see if there is any paint under the mouse in the current cell
  if {[db_search paint -area $x $y $x $y] == ""} {
    # nothing, just return
    return 0
  }

  set layer ""
  # Choose last (highest) layer.
  foreach layer [lreverse [dbt_touchingtypes $x $y selectable]] {
    if {[db_search paint -area $x $y $x $y $layer] == ""} {
      # must be in a different cell, ignore
      continue
    }
    break
  }

  if { $layer == "" } {
    return 0  ;# Nothing under cursor
  }

  # need to select everything around here
  sel_chunk $layer $x $y $x $y
  setl {tmp xx1 yy1 xx2 yy2} [sel_what paint]
  set dx [expr $xx2 - $xx1]
  set dy [expr $yy2 - $yy1]

  set sep [techinfo sep $layer]
  # If no layinfo, make something up for layer separation.  This is awful:
  if { $sep == 0 || $sep == "" } {
      msg "Cant get layer separation. Guessing layer separation.\n"
      set sep [uusnap [expr [min $dx $dy] / 2.0]]
  }

  # box is now just for users benefit.
  layt_box exact [expr $xx1 - $sep] [expr $yy1 - $sep] \
      [expr $xx2 + $sep] [expr $yy2 + $sep]
  sel_area -layers $layer,labels \
      [expr $xx1 - $sep] [expr $yy1 - $sep] \
      [expr $xx2 + $sep] [expr $yy2 + $sep]

  # only allow stretching in one direction
  if {$dx > $dy} {
    set SAVE(stretch) y
  } else {
    set SAVE(stretch) x
  }

  if {[cell_info __WIRE_SELECT__] != "__NO_SUCH_BUFFER__"} {
    # remove it
    db_cell_delete __WIRE_SELECT__
  }

  # make this special internal cell
  db_cell_new -no_undo -internal __WIRE_SELECT__

  # copy selection in here
  db_cell_copy -source __SELECT__ __WIRE_SELECT__

  set frame [dbt_frame]

  # goto __WIRE_SELECT__ and delete all but desired net
  :load __WIRE_SELECT__

  sel_net -point $x $y $layer
  sel_vias

  :load __SELECT__
  # get what we want
  set save [split [db_search paint] \n]

  # return to original cell and edit
  global EDIT
  set bbox [lindex [lindex $EDIT(stack) 0] 4]
  if {$lay_editcell == $lay_rootcell || $bbox == ""} {
    # not in edit in place
    :load $lay_editcell

    # restore framing
    eval $max_win.layout frame $frame 

  } else {
    # special case for edit in place
    setl {inst_path cells frame box} [lindex $EDIT(stack) 0]	
    setl {root path} $cells

    # restore previous rootcell and editcell
    if {$root != [lay_rootcell]} { 	
      :load $root 
    }

    sel_cell $inst_path
    :edit

    # restore framing
    eval $max_win.layout frame $frame 
  }

  sel_clear
  foreach paint $save {
    #eval layt_box exact [lrange $paint 1 end]
    #:select more area [lindex $paint 0]
    struct max_paint p $paint
    sel_area -more -no_wp -no_poly -layers ${p.layer} \
	${p.x1} ${p.y1} ${p.x2} ${p.y2}
  }

  global MAX_NEW_SELECT
  if {[use_first MAX_NEW_SELECT] == 1} {
      sel_group_transfer selected
      db_group 0
  }
  #undo_delim
  return 1
}

proc move_point_enter {} {
  if { ! [dbt_any_selection] } {
    max_error "move_point_enter: error: Nothing selected to move"
    return
  }
  mode_push move_point
}

proc _move_point_mode_define {} {
  set mode move_point

  mode_def $mode _move_point_gate_keeper \
    "BUT-1 specifies over starting point of move, Ctrl-C aborts move"
  mode_bind -cmd 0 $mode <Button-1> "_move_point point" \
    "Point to move coordinate"
  mode_bind -cmd 0 $mode <Motion> "_move_point motion" \
    "Point to move coordinate"
}

proc _move_point {what} {
  global SAVE _MOVE_POINT _move_message
  setl {x1 y1} $_MOVE_POINT(point)
  setl {x2 y2} [layt_point user]
  # Get cached grid from use_first instead of calling _move_get_gridname.
  set gridname [use_first SAVE(grid) 'user]
  setl {x2 y2} [uusnap -grid $gridname $x2 $y2]
  switch $what {
    "motion" {
      if { $x1 != "" } {
	lay_line -tag move_point -clear
	layt_cross -tag move_point $x1 $y1
	layt_arrow -tag move_point $x1 $y1 $x2 $y2
	box_msg_update [format $_move_message [expr $x2 - $x1] [expr $y2 - $y1]]
      }
    }
    "point" {
      if { $_MOVE_POINT(point) == "" } {
	# Record first point.
	set _MOVE_POINT(point) [eval uusnap -grid $gridname [layt_point user]]
	eval layt_cross -tag move_point $_MOVE_POINT(point)
	mode_msg "BUT-1 specifies ending point of move, Ctrl-C aborts move"
	return
      } else {
	# Its the second point.  Do the move.
	sel_move [expr $x2 - $x1] [expr $y2 - $y1]
	move_box [expr $x2 - $x1] [expr $y2 - $y1]
	mode_pop
      }
    }
  }
}


proc _move_point_gate_keeper {event} {
  global mode_abort _MOVE_POINT _move_message
  if {$event == "PUSH_TO"} {
    _move_get_gridname
    set _MOVE_POINT(point) ""

    pan_enable
    status_enable box 0
    global _move_message
    box_msg_update [format $_move_message 0 0]
  } else {
    pan_disable
    lay_line -tag move_point -clear
    status_enable box 1

    if { $mode_abort } {
      undo_to_delim
      undo_flush_redo
      msg "aborting move\n"
    } else {
      i_cmd_between
    }
  }
}


proc move_to {} -desc {
  Prompt for exact amount to move selection, then move it.
} {
  global SAVE _MOVE_TO
  if { ! [dbt_any_selection] } {
    max_error "move_to: error: Nothing selected to move"
    return
  }

  setl {sx1 sy1 sx2 sy2} [db_bbox -cell __SELECT__]

  if { [use_first sx1] == "" } {
    # Just in case...
    setl {sx1 sy1 sx2 sy2} "0 0 0 0"
  }

  set abs_x $sx1
  set abs_y $sy1

  # These are persistent in the menu between calls:
  set _MOVE_TO(type) [use_first _MOVE_TO(type) 'absolute]
  set _MOVE_TO(ref) [use_first _MOVE_TO(ref) "'lower-left corner"]
  set _MOVE_TO(rel_x) [use_first _MOVE_TO(rel_x) '0]
  set _MOVE_TO(rel_y) [use_first _MOVE_TO(rel_y) '0]

  set res [res -mask]
  setl {res_x res_y} [res2 [_move_get_gridname]]

  # create prop menu
  set prop_list ""
  lappend prop_list [list "Move Type:" _MOVE_TO(type) \
	-radio {absolute relative} -reload]

  lappend prop_list [list "X coordinate:" abs_x \
	-number -incr $res -snap $res_x -validate \
	-when { $_MOVE_TO(type) == "absolute" } ]
  lappend prop_list [list "Y coordinate:" abs_y \
	-number -incr $res -snap $res_y -validate \
	-when { $_MOVE_TO(type) == "absolute" } ]
  lappend prop_list [list "Reference point:" _MOVE_TO(ref) \
	-radio {"lower-left corner" "lower-right corner" \
		"upper-left corner" "upper-right corner" center} \
	-when { $_MOVE_TO(type) == "absolute" } ]

  lappend prop_list [list "X amount:" _MOVE_TO(rel_x) \
	-number -incr $res -snap $res_x -validate \
	-when { $_MOVE_TO(type) == "relative" } ]
  lappend prop_list [list "Y amount:" _MOVE_TO(rel_y) \
	-number -incr $res -snap $res_y \
	-validate -when { $_MOVE_TO(type) == "relative" } ]

  set title "Move To"
  set message "Move Selection To:"
  set ret [prop_menu2 -message $message -title $title $prop_list]

  if {$ret == 0} {
    # user hit cancel
    return
  }

  if { $_MOVE_TO(type) == "absolute" } {
    switch $_MOVE_TO(ref) {
      "lower-left corner" { setl {rx ry} [list $sx1 $sy1] }
      "lower-right corner" { setl {rx ry} [list $sx2 $sy1] }
      "upper-left corner" { setl {rx ry} [list $sx1 $sy2] }
      "upper-right corner" { setl {rx ry} [list $sx2 $sy2] }
      "center" {
	  setl {rx ry} [uusnap -mask [expr ($sx1 + $sx2) / 2.0] \
		[expr ($sy1 + $sy2) / 2.0]]
      }
      default { error "internal error: invalid move_to ref" }
    }
    set mx [expr $abs_x - $rx]
    set my [expr $abs_y - $ry]
  } else {
    set mx $_MOVE_TO(rel_x)
    set my $_MOVE_TO(rel_y)
  }

  sel_move $mx $my
  move_box $mx $my
}


proc move_to_box {} -desc {
  Move lower left of selection to lower left of box.
} {
  
  if { ! [dbt_any_selection] } {
    max_error "move_to_box: error: Nothing selected to move"
    return
  }
  setl {x1 y1} [db_bbox -cell __SELECT__]

  setl {bx1 by1 bx2 by2} [layt_box mask]
  # Might have no box in new cell.
  if { $bx1 == "" } { return }

  sel_move [expr $bx1 - $x1] [expr $by1 - $y1]
}


proc move_cell_origin {{x ""} {y ""}} -desc {
  Move cell origin to specified location.
} -doc {
  If no location specified, prompt for location.
  Note that the contents of the cell do not need to be selected,
  and in fact, the selection is cleared by this command.
} {

  if { $x == "" } {
    set x 0
    set y 0
    set res [res -mask]
    setl {res_x res_y} [res2 [_move_get_grid]]
    set prop_list ""
    lappend prop_list [list "New Cell Origin X coordinate:" x \
	-number -incr $res -snap $res_x -validate \
	-help {New cell origin in coords of current cell. \
	This location will be the new (0,0) origin..}]
    lappend prop_list [list "New Cell Origin Y coordinate:" y \
	-number -incr $res -snap $res_x -validate \
	-help {New cell origin in coords of current cell. \
	This location will be the new (0,0) origin..}]
    lappend prop_list [list "Note: This operation cannot be undone!" "" \
	-label]
    set title "Enter New Origin"
    set message "New origin location in current coord system:"
    set ret [prop_menu2 -message $message -title $title $prop_list]

    if {$ret == 0} {
      # user hit cancel
      return
    }
  }

  # We are not going to use the selection, and it may slow us down.
  sel_clear

  set cellname [lay_editcell]
  # This saves current edit cell and view, to be restored later.
  # We have to pass it a cellname to edit, so just use current edit cell.
  edit_push_direct $cellname

  catch {db_cell_delete __MOVE_CELL_ORIGIN_TMP__}
  db_cell_new -internal -no_undo __MOVE_CELL_ORIGIN_TMP__
  # Dont use rename here: It also changes the parent cell, if any, to point
  # to the new cell name.  Too bad, have to do two copies.
  db_cell_copy -offset [expr -$x] [expr -$y] __MOVE_CELL_ORIGIN_TMP__
  move_box [expr -$x] [expr -$y]

  # Clear contents of cell.
  # This kills the undo stack as a side effect.
  db_cell_clear $cellname
  db_flyline -delete

  # This could possibly be a rename?
  db_cell_copy -source __MOVE_CELL_ORIGIN_TMP__ $cellname
  db_cell_delete __MOVE_CELL_ORIGIN_TMP__

  edit_pop_direct

  undo_flush  ;# Operation is not undo-able, because db_cell_clear isnt.

}


proc move_box {dx dy} -desc {
  Move visible box.
} {
  eval layt_box mask [move_rect [layt_box exact] $dx $dy]
}


if {0} {

  proc move_arrow {dir amt} -desc {
    move operation bound to arrow keys.
  } -doc {
    Discards events if too many come in at once, so arrow
    keys dont run on and on.

    Note: this command does its own command wrapping.
  } {
    global _MOVE_ARROW

    # On first time through, init this.
    set _MOVE_ARROW(amt,$dir) [use_first _MOVE_ARROW(amt,$dir) '0]

    set old_dir [use_first _MOVE_ARROW(dir)]
    if { $dir != $old_dir } {
      # New dir: finish move in previous dir, if any.
      if { [use_first _MOVE_ARROW(amt,$old_dir) '0] > 0 } {
	:move $old_dir $_MOVE_ARROW(amt,$old_dir)
	i_cmd_between
	set _MOVE_ARROW(amt,$old_dir) 0
      }
    }

    if { $_MOVE_ARROW(amt,$dir) == 0 } {
      # A new move in this direction.
      set _MOVE_ARROW(amt,$dir) $amt
      # This update allows additional arrow keys to be processed,
      # resulting in additional calls to this function, resulting
      # in _MOVE_ARROW(amt,$dir) being incremented, but with no other affects.
      update
      # Move by amount accumulated during update..
      :move $dir $_MOVE_ARROW(amt,$dir)
      i_cmd_between
      set _MOVE_ARROW(amt,$dir) 0
    } else {
      # This is the branch that is executed during the update, above.
      set _MOVE_ARROW(amt,$dir) [expr $_MOVE_ARROW(amt,$dir) + $amt]
    }
    set _MOVE_ARROW(dir) $dir
  }
}
