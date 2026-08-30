## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************


# Procedures for moving stuff in sue.  Allows existing wires
# and nodes to be dragged and maintain connectivity

# move mode

proc setup_move_mode args {

  global cur_c scale SAVE SNAP_XY IGNORE_MOVE

  modify_setup

  if {[use_first IGNORE_MOVE] != ""} {
    # somebody says to ignore, so do it (probably a button-3 add/
    # delete vertex.
    unset IGNORE_MOVE
    return
  }

  catch {unset SAVE}

  set ids [$cur_c find withtag selected]

  if {$ids == ""} {
    # nothing selected
    return
  }

  if {[llength $ids] == 1 && [is_tagged $ids wire]} {
    # single wires only move perpendicular to their direction
    # unless they are not connected to anything
    setl {x1 y1 x2 y2} [$cur_c coords $ids]
    set del [expr $scale/3.0]
    set ends 0

    set _ids [$cur_c find overlapping [expr $x1 - $del] [expr $y1 - $del] \
	      [expr $x1 + $del] [expr $y1 + $del]]
    foreach id $_ids {
      if {[is_tagged $id open]} {
	incr ends
	break
      }
    }
    set _ids [$cur_c find overlapping [expr $x2 - $del] [expr $y2 - $del] \
	      [expr $x2 + $del] [expr $y2 + $del]]
    foreach id $_ids {
      if {[is_tagged $id open]} {
	incr ends
	break
      }
    }

    if {$ends == 2} {
      # not attached
      set SAVE(movedir) B
    } else {
      # attached, constrain
      set SAVE(movedir) [wire_direction $ids]
    }

  } else {
    # othewise allow movement in both dirs.
    set SAVE(movedir) B
  }

  enter_mode move abort_move_mode

  bind_add -mode move -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  if {$args == ""} {
    # called from menu of hotkey.  Need to wait for a button press.
    msg_window "Button-1 to begin move. Shift-Button-1 for H or V only move.  Ctrl-c aborts"
    bind_add -mode move -hotkey Any-Button-1 \
	-command "begin_move_mode $SNAP_XY" \
	-help "Begin move."

    bind_add -mode move -hotkey Any-Control-c -command "abort_move_mode" \
	-help "Abort move mode."

  } else {
    eval begin_move_mode $args
  }
}


proc begin_move_mode {x y {button 1}} {

  global cur_c cur_s scale SAVE SNAP_XY SNAP10M_XY STRETCH_WIRES

  modify_setup

  msg_window "Drag objects to move. Shift key constrains move to H or V only. Release Button to end. Ctrl-c aborts"

  set SAVE(x) $x
  set SAVE(y) $y

  set SAVE(undo,x) $x
  set SAVE(undo,y) $y

  if {[is_icon $cur_s] || [is_placement $cur_s] || [is_fp $cur_s]} {
    # don't do wire move in icons
    proc SUE_MOVE_WIRES {x y} {}
    set STRETCH_WIRES ""

  } else {
    set cursor [busy]

    set SAVE(coordsall) [setup_save_wires]

    integer_scale

    # setup wire stretch/move
    setup_sticky_move [find_net_edges]

    # remove connection info as it is likely to change
    remove_connects selected

    unscale

    ready $cursor
  }

  bind_add -mode move -hotkey Any-B${button}-Motion \
      -command "move_drag $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Drag selected."

#  bind $cur_c <Any-B${button}-Motion> \
      "move_drag $SNAP_XY; set SCROLL(status) on; eval auto_scroll \[incrX SCROLL(mem)\] \[center_bbox \[\$cur_c bbox selected\]\]"

  bind_add -mode move -hotkey Shift-B${button}-Motion \
      -command "constrained_move_drag $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Drag selected constrained to either horizontal or vertical directions."

  bind_add -mode move -hotkey Control-B${button}-Motion \
      -command "move_drag $SNAP10M_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Drag selected OFF-GRID."

  bind_add -mode move -hotkey Any-B${button}-ButtonRelease \
      -command "end_move_mode; set SCROLL(status) off" \
      -help "End move mode."

  bind_add -mode move -hotkey Any-Control-c -command "abort_move_mode" \
      -help "Abort move mode.  Restore schematic to before move started."
}


# drag objects and attached wires

proc move_drag {x y} {

  global cur_s cur_c SAVE

  if {$SAVE(movedir) == "V"} {
    set y $SAVE(y)

  } elseif {$SAVE(movedir) == "H"} {
    set x $SAVE(x)
  }

  $cur_c move selected [expr $x - $SAVE(x)] [expr $y - $SAVE(y)]

  SUE_MOVE_WIRES [expr $x - $SAVE(x)] [expr $y - $SAVE(y)]

  set SAVE(x) $x
  set SAVE(y) $y

  if {[is_fp $cur_s]} {
    fp_update_nl selected
    fp_display_flylines
  }
}


# constrains movements to either horizontal or vertical, which is more.

proc constrained_move_drag {x y} {

  global cur_s cur_c SAVE

  if {$SAVE(movedir) == "V"} {
    set y $SAVE(y)
  } elseif {$SAVE(movedir) == "H"} {
    set x $SAVE(x)
  } else {
    # only move in the bigger direction
    if {[expr abs($x - $SAVE(undo,x))] > [expr abs($y - $SAVE(undo,y))]} {
      set y $SAVE(undo,y)
    } else {
      set x $SAVE(undo,x)
    }
  }

  $cur_c move selected [expr $x - $SAVE(x)] [expr $y - $SAVE(y)]

  SUE_MOVE_WIRES [expr $x - $SAVE(x)] [expr $y - $SAVE(y)]

  set SAVE(x) $x
  set SAVE(y) $y

  if {[is_fp $cur_s]} {
    fp_update_nl selected
    fp_display_flylines
  }
}


# fix up connectivity since we're done moving

proc end_move_mode {} {

  global cur_c scale SAVE

  modify_setup

  busy

  integer_scale

  # cleans up dragged wires
  end_sticky_move

  # show connection info
  foreach id [use_first SAVE(special)] {
    # special case of moving an open from a term to another term in 1 dir.
    $cur_c add selected withtag $id
  }
  show_connects selected clean

  unscale

  if {[nearby $SAVE(x) $SAVE(y) $SAVE(undo,x) $SAVE(undo,y)] != 1} {
    # setup undo of move
    
    lappend NEW_PROC "global cur_c cur_s scale COLORS"

    # gets all icons and draw_items (lines, text, arcs)
    set ids [concat [get_intersect_tag selected origin] \
		 [get_intersect_tag selected draw_item]]

    lappend NEW_PROC {set old_scale $scale}
    lappend NEW_PROC "scale_canvas $scale"

    if {[info exists SAVE(coordsall)] && $SAVE(coordsall) == 0} {
      # means that the "coordsall" function isn't in this wish
      # try to do something (won't be good).

      # NOTE: doesn't work for non-integer scale. (but should
      # never be used anyways.

      lappend NEW_PROC "select_ids \[xform_ids [list $ids]\]"
      lappend NEW_PROC "setup_sticky_move \[find_net_edges\]"
      lappend NEW_PROC "remove_connects selected"

      lappend NEW_PROC \
	  "$cur_c move selected [expr $SAVE(undo,x)-$SAVE(x)] [expr $SAVE(undo,y)-$SAVE(y)]"
      lappend NEW_PROC \
	  "SUE_MOVE_WIRES [expr $SAVE(undo,x)-$SAVE(x)] [expr $SAVE(undo,y)-$SAVE(y)]"
      lappend NEW_PROC "end_sticky_move"
      lappend NEW_PROC {scale_canvas $old_scale}

      lappend NEW_PROC "update"
      lappend NEW_PROC "show_connects selected clean"

    } else {
      # uses wire checkpointing using "coordsall"

      # delete all wires, opens, and dots
      lappend NEW_PROC "\$cur_c delete wire open dot"

      lappend NEW_PROC "select_ids \[xform_ids [list $ids]\]"
      lappend NEW_PROC \
	  "\$cur_c move selected [expr $SAVE(undo,x)-$SAVE(x)] [expr $SAVE(undo,y)-$SAVE(y)]"

      foreach line [setup_undo_wires {scale_canvas $old_scale}] {
	lappend NEW_PROC $line
      }
    }

    # define the procedure that undoes the delete
    proc undo {} [join $NEW_PROC "\n"]

    # now save away this proc
    save_undo
  }

  # flag that this canvas has been modified
  is_modified

  leave_mode move
  ready
}


proc abort_move_mode {} {

  global cur_c SAVE SCROLL

  modify_setup

  set SCROLL(status) off

  if {![info exists SAVE] || ![info exists SAVE(undo,x)] || \
	  ![info exists SAVE(undo,y)]} {
    # the user didn't even press Button-1 to start the move yet
    leave_mode move
    return
  }

  busy

  # move everything back to where it was
  $cur_c move selected [expr $SAVE(undo,x) - $SAVE(x)] \
      [expr $SAVE(undo,y) - $SAVE(y)]
  
  SUE_MOVE_WIRES [expr $SAVE(undo,x) - $SAVE(x)] \
      [expr $SAVE(undo,y) - $SAVE(y)]

  # so the user can see that things are going back to normal
  update

  integer_scale

  # cleans up dragged wires
  end_sticky_move

  # puts connection info back
  show_connects selected 

  unscale

  # flag that this canvas has been modified
  # this seems weird but is required since some changes are possibly made
  is_modified

  leave_mode move
  ready
}


# Finds the wires/terminals that are not selected but are attached to selected
# wires/terms.  Returns a list of coords which specify this boundary.

proc find_net_edges {} {

  global cur_c

  # mark everything in the bbox of selected with "edge"
  set bbox [$cur_c bbox selected]
  if {$bbox == ""} {
    return
  }
  eval $cur_c addtag edge overlapping $bbox

  # now remove all the things that are selected
  $cur_c dtag selected edge

  foreach id [$cur_c find withtag edge] {
    if {[is_tagged $id wire]} {
      set coords [$cur_c coords $id]
      test_net_edge [lrange $coords 0 1] net_edge
      test_net_edge [lrange $coords 2 3] net_edge
      continue
    }

    if {[is_tagged $id term]} {
      test_net_edge [center $id] net_edge
    }
  }
  $cur_c dtag edge

  if {[info exists net_edge]} {
    set xylist ""
    foreach coord [array names net_edge] {
      lappend xylist $coord
    }
    return $xylist
  }

  return ""
}


# tests a net edge to see if it contains any attached wires or terminals
# that are selected and returns the list of coords, otherwise returns "".

proc test_net_edge {coord array} {

  global cur_c scale
  upvar $array net_edge

  set d [expr $scale/3.0]
  set x [lindex $coord 0]
  set y [lindex $coord 1]

  set ids [$cur_c find overlapping [expr $x - $d] [expr $y - $d] \
		       [expr $x + $d] [expr $y + $d]]

  foreach id $ids {
    if {[is_tagged $id selected] != 1} {
      continue
    }

    # need opens and dots here so user can grab and move them
    if {[is_tagged $id wire] || [is_tagged $id term] || \
	    [is_tagged $id dot] || [is_tagged $id open]} {
      set net_edge([round_list $coord]) 1
    }
  }
  return ""
}


proc setup_sticky_move {coord_list} {

  global cur_c MOVE_WIRES STRETCH_WIRES

  catch {unset MOVE_WIRES}
  set STRETCH_WIRES ""

  foreach coord $coord_list {
    eval mark_attached_wires $coord
  }

  if {[info exists MOVE_WIRES] != 1} {
    proc SUE_MOVE_WIRES {x y} {}
    return
  }

  set PROC ""

  # want to group id's in order.  lsort groups but order is weird because
  # the id 99 is after 100.
  foreach tag [lsort [array names MOVE_WIRES]] {
    lappend PROC $MOVE_WIRES($tag)
  }

  proc SUE_MOVE_WIRES {x y} [join $PROC "\n"]
}


proc end_sticky_move {} {

  global cur_c STRETCH_WIRES

  # remove overlapping wires and generally clean up
# xxxxxx should we use remove_extra_wires or show_connect_wire???
  foreach id $STRETCH_WIRES {
#    show_connect_wire $id clean
    remove_extra_wires $id
  }
}


# mark all attached wires.  Add a new wire to an attached term
# this is a special procedure that is only used by setup_sticky_move

proc mark_attached_wires {x y} {

  global cur_c scale MOVE_WIRES STRETCH_WIRES SAVE

  set del [expr $scale/3.0]
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]

  foreach id $ids {
    if {[is_tagged $id dot] && ![is_tagged $id selected]} {
      set wire_id [make_wire $x $y $x $y]
      set MOVE_WIRES($wire_id,y) "$cur_c move $wire_id 0 \$y"
      set MOVE_WIRES($wire_id,end) "stretch_wire $wire_id end \$x 0"
      lappend STRETCH_WIRES $wire_id

      set wire_id [make_wire $x $y $x $y]
      set MOVE_WIRES($wire_id,end) "stretch_wire $wire_id end 0 \$y"
      lappend STRETCH_WIRES $wire_id

      return
    }
  }

  foreach id $ids {
    # Note that this will allow opens/dots, if selected, to survive.
    if {[is_tagged $id selected]} { 
      continue
    }

    if {[is_tagged $id open] || [is_tagged $id dot]} {
      $cur_c delete $id
      continue
    }

    if {[is_tagged $id wire]} {
      set coords [$cur_c coords $id]
      set p1 [lrange $coords 0 1]
      set p2 [lrange $coords 2 3]

      # lose point wires (shouldn't be necessary)
      if {[eval nearby $p1 $p2] == 1} {
	$cur_c delete $id
	continue
      }

      if {[eval nearby $x $y $p1] == 1} {
	set wire_dir [wire_direction $id]

	lappend STRETCH_WIRES $id
	
	if {$wire_dir == "H"} {
	  set MOVE_WIRES($id,y) "$cur_c move $id 0 \$y" 
	  set MOVE_WIRES($id,begin) "stretch_wire $id begin \$x 0"

	} elseif {$wire_dir == "V"} {
	  set MOVE_WIRES($id,x) "$cur_c move $id \$x 0" 
	  set MOVE_WIRES($id,begin) "stretch_wire $id begin 0 \$y"

	} elseif {$wire_dir == "B"} {
	  set MOVE_WIRES($id,begin) "stretch_wire $id begin \$x \$y"
	  continue
	}

	eval remove_connect_point $p2
	eval mark_attached $id $wire_dir $p2

	continue
      }
      if {[eval nearby $x $y $p2] == 1} {
	set wire_dir [wire_direction $id]

	lappend STRETCH_WIRES $id

	if {$wire_dir == "H"} {
	  set MOVE_WIRES($id,y) "$cur_c move $id 0 \$y" 
	  set MOVE_WIRES($id,end) "stretch_wire $id end \$x 0"

	} elseif {$wire_dir == "V"} {
	  set MOVE_WIRES($id,x) "$cur_c move $id \$x 0" 
	  set MOVE_WIRES($id,end) "stretch_wire $id end 0 \$y"

	} elseif {$wire_dir == "B"} {
	  set MOVE_WIRES($id,begin) "stretch_wire $id end \$x \$y"
	  continue
	}

	eval remove_connect_point $p1
	eval mark_attached $id $wire_dir $p1

	continue
      }
      continue
    }

    if {[is_tagged $id term]} {
      set wire_id [make_wire $x $y $x $y]
      lappend SAVE(special) $wire_id
      set MOVE_WIRES($wire_id,y) "$cur_c move $wire_id 0 \$y"
      set MOVE_WIRES($wire_id,end) "stretch_wire $wire_id end \$x 0"
      set wire_id [make_wire $x $y $x $y]
      lappend SAVE(special) $wire_id
      set MOVE_WIRES($wire_id,end) "stretch_wire $wire_id end 0 \$y"

      lappend STRETCH_WIRES $wire_id
    }
  }
}


# marks the objects attached to a wire at point x,y not including id.

proc mark_attached {wire_id wire_dir x y} {

  global cur_c scale MOVE_WIRES STRETCH_WIRES

  set del [expr $scale/3.0]
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]

  # if there is more than one wire attached or a term, add a new wire
  set attach_list ""

  foreach id $ids {
    if {$id == $wire_id} {
      continue
    }

    if {[is_tagged $id selected]} {
      continue
    }

    if {[is_tagged $id wire]} {
      set coords [$cur_c coords $id]
      set p1 [lrange $coords 0 1]
      set p2 [lrange $coords 2 3]

      # lose point wires (shouldn't be necessary)
      if {[eval nearby $p1 $p2] == 1} {
	continue
      }

      if {[eval nearby $x $y $p1] == 1} {
	lappend attach_list "$id begin"
	continue
      }
      if {[eval nearby $x $y $p2] == 1} {
	lappend attach_list "$id end"
	continue
      }
      continue
    }

    if {[is_tagged $id term]} {
      # this will force us to add a wire since there are at least two attached
      lappend attach_list "foo bar"
      lappend attach_list "foo bar"
    }
  }

  if {[llength $attach_list] == 0} {
    # nothing is attached to this wire so put the wire on the clean up list
    lappend STRETCH_WIRES $wire_id
    return
  }

  if {[llength $attach_list] > 1} {
    # make a new wire
    set id [make_wire $x $y $x $y]
    set end end

    if {$wire_dir == "V"} {
      set MOVE_WIRES($id,$end) "stretch_wire $id $end \$x 0"
    } else {
      set MOVE_WIRES($id,$end) "stretch_wire $id $end 0 \$y"
    }

  } else {
    set id [lindex [lindex $attach_list 0] 0]
    set end [lindex [lindex $attach_list 0] 1]

    set dir [wire_direction $id]
    if {$wire_dir == $dir} {
      if {$wire_dir == "V"} {
	set MOVE_WIRES($id,$end) "stretch_wire $id $end 0 \$y"
      } else {
	set MOVE_WIRES($id,$end) "stretch_wire $id $end \$x 0"
      }
    } else {
      if {$wire_dir == "V"} {
	set MOVE_WIRES($id,$end) "stretch_wire $id $end \$x 0"
      } else {
	set MOVE_WIRES($id,$end) "stretch_wire $id $end 0 \$y"
      }
    }
  }

  lappend STRETCH_WIRES $id
}


# removes extra wires due to overlapping wires around the given wire id

proc remove_extra_wires {wire_id} {

  global cur_c scale

  set dir [wire_direction $wire_id]

  if {$dir == "B"} {
    # boston wires don't need to be cleaned up
    return
  }

  set wire_coords [$cur_c coords $wire_id]

  # delete this wire, we will remake it later
  $cur_c delete $wire_id

  if {$wire_coords == ""} {
    return
  }

  setl {x1 y1 x2 y2} $wire_coords

  set del [expr $scale/3.0]

  # save coords for all wires parallel to the given wire
  if {$dir == "V"} {
    set coord $x1
    set coords "$y1 $y2"

  } else {
    set coord $y1
    set coords "$x1 $x2"
  }

  set select ""

  foreach id [$cur_c find overlapping [expr $x1 - $del] [expr $y1 - $del] \
		  [expr $x2 + $del] [expr $y2 + $del]] {
    if {[is_tagged $id wire]} {
      set c [$cur_c coords $id]

      if {[wire_direction $id] == $dir} {
	# wire is parallel, remember coords and delete
	if {$dir == "V"} {
	  lappend coords [lindex $c 1]
	  lappend coords [lindex $c 3]

	} else {
	  lappend coords [lindex $c 0]
	  lappend coords [lindex $c 2]
	}

	if {[is_tagged $id selected]} {
	  set select selected
	}
	$cur_c delete $id
	continue
      }

      # otherwise, look for wire ends that T

      if {$dir == "V"} {
	if {[expr abs([lindex $c 0] - $coord) < $del]} {
	  lappend coords [lindex $c 1]
	  continue
	} 
	if {[expr abs([lindex $c 2] - $coord) < $del]} {
	  lappend coords [lindex $c 3]
	}
      } else {
	if {[expr abs([lindex $c 1] - $coord) < $del]} {
	  lappend coords [lindex $c 0]
	  continue
	} 
	if {[expr abs([lindex $c 3] - $coord) < $del]} {
	  lappend coords [lindex $c 2]
	}
      }
      continue
    }

    if {[is_tagged $id term]} {
      if {$dir == "V"} {
	lappend coords [lindex [center $id] 1]
      } else {
	lappend coords [lindex [center $id] 0]
      }
    }
  }
  remake_wires $coord $coords $dir $select
}


# takes a list of points that are colinear and wires them correctly.
# Tosses points that are the same.

proc remake_wires {coord coords dir {selected ""}} {

  global cur_c scale COLORS

  set coords [lsort -real $coords]
  set del [expr $scale/3.0]

  if {$dir == "V"} {
    set old_y [lindex $coords 0]

    foreach y $coords {
      if {[expr $y-$old_y] >= $del} { 
	make_wire_selected $coord $old_y $coord $y $selected
	show_connect_point $coord $old_y clean
      }
      set old_y $y
    }
    if {$old_y != ""} {
      show_connect_point $coord $old_y clean
    }
  }

  if {$dir == "H"} {
    set old_x [lindex $coords 0]

    foreach x $coords {
      if {[expr $x-$old_x] >= $del} { 
	make_wire_selected $old_x $coord $x $coord $selected
	show_connect_point $old_x $coord clean
      }
      set old_x $x
    }
    if {$old_x != ""} {
      show_connect_point $old_x $coord clean
    }
  }
}


# Utility procedures for wires and connectivity
# Returns:  H - horizontal wire, V - vertical wire, T - terminal, B - Boston

proc wire_direction {id} {

  global cur_c scale

  # if the wire no longer exists, just punt
  if {[$cur_c type $id] == ""} {
    return
  }

  if {[is_tagged $id term]} {
    return T
  }

  set coords [$cur_c coords $id]
  set x1 [lindex $coords 0]
  set y1 [lindex $coords 1]
  set x2 [lindex $coords 2]
  set y2 [lindex $coords 3]

  set del [expr $scale/3.0]

  if {[expr abs($x1-$x2)] < $del} {
    return V
  }
  if {[expr abs($y1-$y2)] < $del} {
    return H
  }
  return B
}


proc nudge {dir} {

  global cur_c scale NUDGE KEYS SCROLL NUDGE_DELAY

  modify_setup

  if {![info exists NUDGE(no)]} {

    set ids [$cur_c find withtag selected]

    if {$ids == ""} {
      # nothing selected
      return
    }

    set NUDGE(no) 0
    set NUDGE(x) 0
    set NUDGE(y) 0
    setup_move_mode 0 0

    msg_window "Arrow keys move objects. Ctrl-c aborts"

    # setup_move_mode toasts nudge hotkeys so add
    clear_bindings
    bind $cur_c <Any-Control-c> {unset NUDGE; abort_move_mode}
    bind $cur_c <$KEYS(nudge_up)> {nudge up}
    bind $cur_c <$KEYS(nudge_down)> {nudge down}
    bind $cur_c <$KEYS(nudge_left)> {nudge left}
    bind $cur_c <$KEYS(nudge_right)> {nudge right}

  } else {
    incr NUDGE(no)
  }

  setl {x1 y1 x2 y2} [$cur_c bbox selected]

  switch $dir {
    "s" - "down" {
      set NUDGE(y) [expr $NUDGE(y) + $scale]
      set x [expr ($x1 + $x2) / 2]
      set y $y2
    }
    "e" - "right" {
      set NUDGE(x) [expr $NUDGE(x) + $scale]
      set x $x2
      set y [expr ($y1 + $y2) / 2]
    }
    "n" - "up" {
      set NUDGE(y) [expr $NUDGE(y) - $scale]
      set x [expr ($x1 + $x2) / 2]
      set y $y1
    }
    "w" - "left" {
      set NUDGE(x) [expr $NUDGE(x) - $scale]
      set x $x1
      set y [expr ($y1 + $y2) / 2]
    }
  }

  move_drag $NUDGE(x) $NUDGE(y)
  set SCROLL(status) on
#  set SCROLL(status) off
  eval auto_scroll [incrX SCROLL(mem)] "$x $y"
  set SCROLL(status) off

  after $NUDGE_DELAY nudge_continue $NUDGE(no)
}


proc nudge_continue {no} {

  global NUDGE

  if {[info exists NUDGE(no)] && $NUDGE(no) == $no} {
    # waited long enough for user to hit key again and hasn't so finish up.
    end_move_mode
    unset NUDGE
  }
}


# allows move to be toggled to allow control key to move off grid.

proc toggle_move_grid {} {

  global cur_c cur_s SNAP10_XY SNAP_XY SNAP10M_XY

  set title "Move Option"
  set message "Enter Option:" 

  if {[string compare $SNAP10M_XY $SNAP10_XY] == 0} {
    set offgrid 1
  } else {
    set offgrid 0
  }

  set prop_list ""
  lappend prop_list "{Allow Off-Grid Moves when Holding Down Control Key} offgrid binary"
  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  if {$offgrid} {
    set SNAP10M_XY $SNAP10_XY
    puts "Off-Grid moves ENABLED when holding down Control key."

  } else {
    set SNAP10M_XY $SNAP_XY
    puts "Off-Grid moves DISABLED when holding down Control key."
  }
}
