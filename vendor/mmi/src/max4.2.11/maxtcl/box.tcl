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

set RCSVERSION(box.tcl) { $Revision: 1.24 $ }

# box support.

proc _resize_box_mode_define {} -desc {
  resize box with mouse mode
} {
  mode_def resize_box _resize_box_gate_keeper "RELEASE-BUT-2 ends, CTRL-C aborts"

  mode_bind -cmd 0 resize_box <Any-B1-Motion> _resize_box_drag
  mode_bind -cmd 0 resize_box <Any-B1-ButtonRelease> mode_pop
  mode_bind -cmd 0 resize_box <Any-B2-Motion> _resize_box_drag
  mode_bind -cmd 0 resize_box <Any-B2-ButtonRelease> mode_pop
}

proc _resize_box_gate_keeper {event} -desc {
    called whenever mode is entered/exited
} {
    global BOXSAVE mode_abort 

    if {$event == "PUSH_TO"} {
	pan_enable
	box_set_move_cursor "$BOXSAVE(transform)"
	set BOXSAVE(origbox) [layt_box exact]
    } elseif {$event == "POP_FROM"} {
	pan_disable
	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting box resize!\n"
	} elseif { $BOXSAVE(command) != "" } {
	  eval $BOXSAVE(command)
	}
	set BOXSAVE(command) ""

	i_cmd_between
    }
}

proc _resize_box_drag {} -desc {
  resize the box with the cursor
} {

  global BOXSAVE
  set grid $BOXSAVE(grid)

  pan_auto _resize_box_drag  

  setl {x y} [eval uusnap -grid $grid [layt_point user]]
  if {$x == "" || $y == ""} {
    # off screen
    return
  }

  # Get the old box
  setl {x1 y1 x2 y2} $BOXSAVE(origbox)
  set dx [expr $x - $BOXSAVE(x)]
  set dy [expr $y - $BOXSAVE(y)]

  if {0} {
  # get the old box
  setl {x1 y1 x2 y2} [layt_box user]
  set BOXSAVE(x) $x
  set BOXSAVE(y) $y
  set dx [expr $x - $BOXSAVE(x)]
  set dy [expr $y - $BOXSAVE(y)]
  }

  # compute the new box
  setl {tx1 ty1 tx2 ty2} $BOXSAVE(transform)
  setl {nx1 ny1 nx2 ny2} [uusnap -grid $grid \
      [expr $x1 + $tx1*$dx] [expr $y1 + $ty1*$dy] \
      [expr $x2 + $tx2*$dx] [expr $y2 + $ty2*$dy]]

  if {[use_first BOXSAVE(area)] != ""} {
    # Use a constant area stretch method.
    set area $BOXSAVE(area)
    setl {resx resy} [res2 $grid]
    if {$resx == ""} {error "Grid $grid not defined"}
    set side [box_transform_to_compass $BOXSAVE(transform)]
    switch $side {
      "e" - "w" {
	set x_size [max $resx [expr abs($nx2 - $nx1)]]
	setl {x_size junk} [uusnap -ceil -grid $grid $x_size 0]
	setl {x_size y_size} [uusnap -ceil -grid $grid $x_size [expr (0.0 + $area) / $x_size]]
      }
      "n" - "s" {
	# Y size changed (or dragging a corner).  Mush x to make area correct.
	set y_size [max $resy [expr abs($ny2 - $ny1)]]
	setl {junk y_size} [uusnap -ceil -grid $grid 0 $y_size]
	setl {x_size y_size} [uusnap -ceil -grid $grid [expr (0.0 + $area) / $y_size] $y_size]
      }
      "se" - "sw" -
      "ne" - "nw" {
	# Note: we cant really stretch a corner and maintain a constant area.
	# I'm not even sure what it would mean.
	# So grabbing the corners is disallowed when we set the BOXSAVE(transform).
	assert 0
      }
    }
    switch $side {
      "w" {
	set nx1 [expr $nx2 - $x_size]
	set ny2 [expr $ny1 + $y_size]
      }
      "e"  {
	set nx2 [expr $nx1 + $x_size]
	set ny2 [expr $ny1 + $y_size]
      }
      "s" {
	set ny1 [expr $ny2 - $y_size]
	set nx2 [expr $nx1 + $x_size]
      }
      "n"  {
	set ny2 [expr $ny1 + $y_size]
	set nx2 [expr $nx1 + $x_size]
      }
    }
  }

  layt_box mask $nx1 $ny1 $nx2 $ny2
  box_msg_update
}

proc _move_box_mode_define {} -desc {
  move box with mouse mode
} {
  mode_def move_box _move_box_gate_keeper "RELEASE-BUT-2 ends, CTRL-C aborts"

  mode_bind -cmd 0 move_box <B2-Motion> _move_box_move
  mode_bind -cmd 0 move_box <Shift-B2-Motion> "_move_box_move shift"
  mode_bind -cmd 0 move_box <Any-B2-ButtonRelease> mode_pop
}
   
proc _move_box_gate_keeper {event} -desc {
    called whenever mode is entered/exited
} {
    global mode_abort
    global BOXSAVE

    if {$event == "PUSH_TO"} {
	set BOXSAVE(origbox) [layt_box exact]
	pan_enable
	cursor_mode "move"
    } elseif {$event == "POP_FROM"} {
	pan_disable

	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting move!\n"
	} 

	#catch {unset BOXSAVE}

	i_cmd_between
    }
}

proc _move_box_move {{shift ""}} -desc {
  move the box with the cursor
} {
  global BOXSAVE

  pan_auto _move_box_move

  setl {x y} [eval uusnap -grid $BOXSAVE(grid) [layt_point user]]
  if {$x == "" || $y == ""} {
    # off screen
    return
  }

  set dx [expr $x - $BOXSAVE(x)]
  set dy [expr $y - $BOXSAVE(y)]


  # get the old box
  #setl {x1 y1 x2 y2} [layt_box user]
  setl {x1 y1 x2 y2} $BOXSAVE(origbox)

  if {$shift != ""} {
    # constrain move to one direction only
    if { abs($dx) < abs($dy) } {
      set dx 0
    } else {
      set dy 0
    }
  }

  # make the new box
  layt_box user [expr $x1 + $dx] [expr $y1 + $dy] [expr $x2 + $dx] [expr $y2 + $dy]
  box_msg_update
}

proc box_mode_enter {args} -desc {
  drag out a new box
} -doc {
  USAGE:
    box_mode_enter [-cmd <cmd>] [-area <area>] [-grid <grid>] [-mode resize]

  The <cmd> is an optional command to execute after box has been dragged.
  Since this "command" consists of multiple events, it should not be 
  called with a command wrapper (i.e. use "mode_bind -cmd 0".)
  When box mode is exited, i_cmd_between is called.
  The <area>, if specified is the area of the box, in which case
  a constant area drag method is used.
  The <grid> is the optional grid to snap the box to; defaults to user.
} {
  global BOXSAVE
  set options {{cmd ""} {area ""} {grid "user"} {mode ""}}
  call_keyword $args $options
  set BOXSAVE(command) $cmd
  set BOXSAVE(grid) $grid
  set BOXSAVE(area) $area
  set BOXSAVE(allow_corners) [expr {$area == ""}]
  set BOXSAVE(mode) $mode
  mode_push box
}

proc _box_modify_int {} -desc {
  see box_modify
} {
  global BOXSAVE
  setl {BOXSAVE(x) BOXSAVE(y)} [eval uusnap -grid $BOXSAVE(grid) \
      [layt_point user]]
  set BOXSAVE(origbox) [layt_box exact]

  set box [layt_box exact]
  # If no visible box, cant do anything.
  if { $box == "" } { return }
  setl {x y} [layt_point exact]
  set allow_corners [expr {$BOXSAVE(area) != ""}]
  set BOXSAVE(transform) [box_get_nearest_side $x $y $box $BOXSAVE(allow_corners)]
  if { $BOXSAVE(transform) == "0 0 0 0" } {
    # Move box
    if {$BOXSAVE(mode) != "resize"} {
      mode_change move_box
    }
  } else {
      # resize box
      mode_change resize_box
  }
}

proc box_modify {} -desc {
  move/resize box depending on where the cursor is.
} -doc {
  If the cursor is near a corner of the box, resize the box. 
  Otherwise move the box.
  This is called from the move code if nothing is selected.
} {
    global BOXSAVE
    set BOXSAVE(grid) "user"
    set BOXSAVE(command) ""
    set BOXSAVE(allow_corners) 1
    set BOXSAVE(area) ""
    set BOXSAVE(mode) ""
    _box_modify_int
}

proc _box_show_cursor {{mark_mode 0}} -desc {
  Just modify the cursor as mouse is moved, until user presses a button.
} {
  global BOXSAVE
  if { $BOXSAVE(drag_started) } { return }
  setl {x y} [layt_point exact]
  set transform [box_get_nearest_side $x $y [layt_box exact] $BOXSAVE(allow_corners)]
  if { $mark_mode==0 || $transform == "0 0 0 0" } {
      # Not near any side of the box
      cursor_mode 1
  } else {
    # We are going to resize the box.  Change cursor.
    box_set_move_cursor $transform
  }
}

proc _box_drag_start {{mark_mode 0}} -doc {
  In old mode, button just draws a new box.
  In mark mode, the mouse button resizes the box if near an edge,
  otherwise draws a new box.  This functionality is also on button-2,
  but Mark wanted it on Button-1, too.  Lee later reported this
  as a bug.  I can only find it all amusing.
} {
  global BOXSAVE
  set BOXSAVE(drag_started) 1
  setl {BOXSAVE(x) BOXSAVE(y)} [eval uusnap -grid $BOXSAVE(grid) [layt_point user]]
  setl {x y} [layt_point exact]
  set BOXSAVE(transform) [box_get_nearest_side $x $y [layt_box exact] $BOXSAVE(allow_corners)]

  # If the cursor is near a side of the box, we will resize the box,
  # otherwise drag out a new box.
  if { $mark_mode==0 || $BOXSAVE(transform) == "0 0 0 0" } {
    # We are going to drag a new box: start with a zero sized box.
    layt_box user $BOXSAVE(x) $BOXSAVE(y) $BOXSAVE(x) $BOXSAVE(y)
  } else {
    # Do a resize instead of a drag.
    mode_change resize_box
  }
}

proc _box_mode_define {} -desc {
  drag out a new box mode
} {
  global BOXSAVE

  mode_def box _box_gate_keeper "BUT-1 creates/resizes box, BUT-2 moves/resizes box, Shift-BUT-1 just creates box, CTRL-C aborts"

  mode_bind -cmd 0 box <Motion> "_box_show_cursor 1"
  mode_bind -cmd 0 box <Shift-Motion> "_box_show_cursor 0"
  mode_bind -cmd 0 box <Button-1> "_box_drag_start 1"
  mode_bind -cmd 0 box <Shift-Button-1> "_box_drag_start 0"

  mode_bind -cmd 0 box <Any-B1-Motion> _box_drag
  mode_bind -cmd 0 box <Shift-B1-Motion> _box_drag
  mode_bind -cmd 0 box <Any-B1-ButtonRelease> mode_pop
  mode_bind -cmd 0 box <Any-Button-2> _box_modify_int
}

proc _box_gate_keeper {event} -desc {
    called whenever box mode is entered/exited
} -doc {
    saves box on entry, restores on exit.
} {
    global BOXSAVE mode_abort 

    if {$event == "PUSH_TO"} {
	set BOXSAVE(drag_started) 0
	pan_enable
	box_msg_update
	#sel_clear
    } elseif {$event == "POP_FROM"} {
	pan_disable

	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    set BOXSAVE(command) ""
	} elseif { $BOXSAVE(command) != "" && $BOXSAVE(mode) == "" } {
	  eval $BOXSAVE(command)
	  set BOXSAVE(command) ""
	}

	# undo boundary and updates
	i_cmd_between
    }
}

proc _box_drag {} -desc {
  drags a select box
} {
  global BOXSAVE

  if {$BOXSAVE(mode) == "resize"} {return}

  pan_auto _box_drag

  setl {x y} [eval uusnap -grid $BOXSAVE(grid) [layt_point user]]
  if {$x == "" || $y == ""} {
    # off screen
    return
  }
  layt_box user $BOXSAVE(x) $BOXSAVE(y) $x $y
  box_msg_update
}

proc box_dim_edit {} -desc {
    popup window to let user edit box dimensions
} {
  global BOX STATUS

  set BOX(specify_box_method) [use_first BOX(specify_box_method) 'origin+size]

  # current box - get exact size so user can specify exactly.
  setl {xbot ybot xtop ytop} [layt_box exact]
  if { $xbot == "" } {
    # No visible box - just started editing this cell.  Make something up.
    setl {xbot ybot xtop ytop} {0 0 1 1}
  }
  
  # setup property window
  set gridx [res -userx]
  set gridy [res -usery]

  while {1} {
    set width [expr $xtop - $xbot]
    set height [expr $ytop - $ybot]
    set xcenter [expr $xbot + $width/2.0]
    set ycenter [expr $ybot + $height/2.0]
    set prop_list  [list \
	    "{Specify Box by:} BOX(specify_box_method) \
	    -choice {origin+size corners center} -return 2"]
    set pos_props "-number 0 100000 -incr [res -mask] \
	    -width 10 -validate"
    set num_props "-number -100000 100000 -incr [res -mask] \
	    -width 10 -validate"
    set method $BOX(specify_box_method)
    switch $BOX(specify_box_method) {
      "origin+size" {
	lappend prop_list "x_lower_left xbot $num_props -snap $gridx"
	lappend prop_list "y_lower_left ybot $num_props -snap $gridy"
	lappend prop_list "width  width  $pos_props -snap $gridx"
	lappend prop_list "height height $pos_props -snap $gridy -separator" 
      }
      "center" {
	set xcenter [expr $xbot + $width/2.0]
	lappend prop_list "x_center xcenter  $num_props -snap $gridx" 
	lappend prop_list "y_center ycenter $num_props -snap $gridy"
	lappend prop_list "width  width  $pos_props -snap $gridx"
	lappend prop_list "height height $pos_props -snap $gridy -separator" 
      } 
      "corners" {
	lappend prop_list "x_lower_left xbot $num_props -snap $gridx"
	lappend prop_list "y_lower_left ybot $num_props -snap $gridy"
	lappend prop_list "x_upper_right xtop $num_props -snap $gridx"
	lappend prop_list "y_upper_right ytop $num_props -snap $gridy -separator"
      }
      default {
	error "internal box code: unrecognized method: $method"
      }
    }
    
    lappend prop_list [list "Display on status bar, box:" \
	STATUS(box_msg_type) -choice {size corners origin+size disable}]

      # popup window
      set title "box dimension"
      set message "Edit the box dimensions:" 
      set ret [prop_menu2 -message $message -title $title $prop_list]

      if {$ret == 0} {
	# user hit cancel
	return
      }

      # Update xbot,ybot,xtop,ytop according to the method that
      # was in use when we last popped up the menu.
      switch $method {
	"origin+size" {
	  set xtop [expr $xbot + $width]
	  set ytop [expr $ybot + $height]
	}
	"center" {
	  set xbot [expr $xcenter - $width/2.0]
	  set ybot [expr $ycenter - $height/2.0]
	  set xtop [expr $xbot + $width]
	  set ytop [expr $ybot + $height]
	}
	"corners" {
	  # This is the default.
	}
	default {
	  error "internal box code: unrecognized method: $method"
	}
      }
  
      # If user changed the BOX(specify_box_method)
      if { $ret == 2 } { continue }
      break
  }

  i_cmd_eval layt_box exact $xbot $ybot $xtop $ytop
}


# Not currently used (pat)...
#proc box_loc_edit {} -desc {
#    popup window to let user edit edit box location (coordinates)
#} {
#
#  # current box - get exact size so user can edit it exactly.
#  setl {x_lower_left y_lower_left x_upper_right y_upper_right} [layt_box exact]
#  
#  # setup property window
#  set numberprops "-number -100000 100000 -incr [res -mask] \
#	-width 10 -validate"
#  set prop_list  [list \
#	  "x_lower_left x_lower_left $numberprops -snap [res -userx]" \
#	  "y_lower_left y_lower_left $numberprops -snap [res -usery]" \
#	  "x_upper_right x_upper_right $numberprops -snap [res -userx]" \
#	  "y_upper_right y_upper_right $numberprops -snap [res -usery]" ]
#
#  # popup window
#  set title "box coordinates"
#  set message "Edit the box coordinates:" 
#  set ret [prop_menu2 -message $message -title $title $prop_list]
#
#  if {$ret == 0} {
#    # means the user hit cancel
#    return
#  }
#
#  i_cmd_eval layt_box exact $x_lower_left $y_lower_left $x_upper_right $y_upper_right
#}


proc _box_goto_validate {value propname} -desc {
  prop_menu validation function for box_goto_coords
} {
  return ""
}

proc box_goto_coords {} -desc {
    query for point and center there
} {
  global GOTO_COORDS

  #initial to origin
  set x [use_first GOTO_COORDS(x) '0]
  set y [use_first GOTO_COORDS(y) '0]
  use_init GOTO_COORDS(zoom) 0
  # Dont make the units persistent.
  # If you do, you have to convert the saved coords from microns to nanons when you pop it up.
  set units microns
 
  # setup property window
  set numberprops "-number -100000 100000 -incr [res -mask] \
	-width 10 -validate _box_goto_validate"
  set prop_list ""
  lappend prop_list "{X or X,Y} x $numberprops -snap [res -userx] \
    -help {You can specify X and Y coords in the two entry boxes, or specify both X and Y\
    separated by a space or comma in the X entry box, and leave the Y entry box clear}"
  lappend prop_list "Y y $numberprops -snap [res -usery]"
  lappend prop_list "units units -choice {microns nanons} \
    -help {Specify units in microns (10 ** -6 meter) or nanons (10 ** -9 meter)}"
  lappend prop_list "{Zoom In} GOTO_COORDS(zoom) -binary \
    -help {if set, max will move and zoom the window to center the specified point}"

  # popup window
  set title "coordinates"
  set message "Enter the coordinates to goto:" 
  set ret [prop_menu2 -message $message -title $title $prop_list]

  if {$ret == 0} {
    # means the user hit cancel
    return
  }

  # Change comma to space in $x so user can put in coords as x,y
  regsub {,} $x " " x

  if {[llength $x] == 2} {
    if {$y != "" && $y != 0} {
      error "Confusing x,y coordinates"
    }
    setl {x y} $x
  }

  if {$units == "nanons"} {
    setl {x y} [uusnap -mask [expr $x / 1000.0] [expr $y / 1000.0]]
  } else {
    setl {x y} [uusnap -mask $x $y]
  }

  set GOTO_COORDS(x) $x
  set GOTO_COORDS(y) $y

  if { $GOTO_COORDS(zoom) } {
    layt_box exact $x $y [expr $x + 1] [expr $y + 1]
    :findbox zoom
    #:zoom 10
  }
  i_cmd_eval layt_box exact $x $y $x $y
  :findbox

  layt_point -warp exact $x $y
}

proc box_transform_to_compass {side} {
  switch $side {
    "1 1 0 0" { return sw }
    "1 0 0 1" { return nw }
    "0 0 1 1" { return ne }
    "0 1 1 0" { return se }
    "1 0 0 0" { return w }
    "0 1 0 0" { return s }
    "0 0 1 0" { return e }
    "0 0 0 1" { return n }
    "0 0 0 0" { return "" }
  }
}


proc box_get_nearest_side {x y box {allow_corners 1} {slop 0}} -desc {
    determine which side of specified box is close to x,y
} -doc {
    Box is of the form "x1 y1 x2 y2"
    Return a transform "left bottom right top" that represents
    whether x,y is close to a side of the box.
    If allow_corners is set, also check if x,y is near a corner of the box.
    For example, "1 0 0 0" is near the left side, and
    "0 1 1 0" is near the bottom right corner.
    If not near any side or corner, return "0 0 0 0".

    If slop is 1, allow sloppy positioning - this is used in modes where
    the user is doing nothing but positioning the box.
} {
    setl {x1 y1 x2 y2} $box
    if { $x1 == "" } {
      # The box is non-existent
      return "0 0 0 0"
    }
    if { $slop } {
	set dd [nearby_dist 5]
	set minside [min [expr abs($x2-$x1)] [expr abs($y2-$y1)]]
	# But dont allow slop to be greater than half the size of the box.
	if { $dd > $minside / 2 } {
	    set dd [expr $minside / 2]
	}
    } else {
	set dd [nearby_dist]
    }
    if { $allow_corners } {
      if {[nearby $x $y $x1 $y1 $dd]} {
	# resize by lower left corner.
	return "1 1 0 0"
      } elseif {[nearby $x $y $x1 $y2 $dd]} {
	return "1 0 0 1"
      } elseif {[nearby $x $y $x2 $y2 $dd]} {
	return "0 0 1 1"
      } elseif {[nearby $x $y $x2 $y1 $dd]} {
	return "0 1 1 0"
      }
    }
    if {[nearby $x 0 $x1 0 $dd] && $y1 < $y && $y < $y2} {
      # resize left side
      return "1 0 0 0"
    } elseif {[nearby $x 0 $x2 0 $dd] && $y1 < $y && $y < $y2} {
      # resize right side
      return "0 0 1 0"
    } elseif {[nearby $y 0 $y1 0 $dd] && $x1 < $x && $x < $x2} {
      # resize bottom
      return "0 1 0 0"
    } elseif {[nearby $y 0 $y2 0 $dd] && $x1 < $x && $x < $x2} {
      # resize top
      return "0 0 0 1"
    } else {
      # Not near any corner or side.
      return "0 0 0 0"
    }
}


proc box_set_move_cursor {transform} -desc {
    Change the mode cursor based on the specified transform.
} -doc {
    The transform is returned by box_get_nearest_side
} {
    global BOXSAVE
    switch $transform {
    "1 1 0 0" { cursor_mode llcorner }
    "1 0 0 1" { cursor_mode ulcorner }
    "0 0 1 1" { cursor_mode urcorner }
    "0 1 1 0" { cursor_mode lrcorner }
    "1 0 0 0" { cursor_mode movex }
    "0 1 0 0" { cursor_mode movey }
    "0 0 1 0" { cursor_mode movex }
    "0 0 0 1" { cursor_mode movey }
    }
}


proc box_move {dx dy} -desc {
  Move box by dx,dy
} {
  eval layt_box exact [move_rect [layt_box exact] $dx $dy]
}
