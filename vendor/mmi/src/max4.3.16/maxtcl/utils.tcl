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

set RCSVERSION(utils.tcl) { $Revision: 1.39 $ }

# Random useful generic utility procedures for Max.
# (see also $MMI_UTILS/sharedtcl/share_utils.tcl for utils shared
#  between Max Sue and who knows who.)

init_global MAX_ERROR_INFO -type STRING \
	-default "" \
	-desc { Contains stack trace after a call to max_error. }
 
proc res {args} -desc {
  Returns design grid size (minimum increment)
} -doc {
  USAGE: res [-userx | -usery | -internal | -mask]

  If -userx or -usery, return user resolution grid size
     in x or y, as set in the Grid Menu - this is the grid the mouse
     snaps to.
  If -mask, return foundry grid.
  If -internal, return max minimum internal grid.
  Default is -internal.
} {
  global GRID
  switch -- $args {
    "-userx" {
      # There is a race condition: GRID(userx) and GRID(usery) are
      # defined during max initialization in grid_init.
      # Unfortunately, it is possible to get res -userx called
      # by moving the mouse on the screen as max is coming up,
      # and it can beat out grid_init.  So it is possible that
      # GRID(userx) is undefined, but only during startup.
      if {[info exists GRID(userx)]} {
	return $GRID(userx)
      } else {
	return [res -internal]  ;# used only during startup.
      }
    }
    "-usery" {
      if {[info exists GRID(usery)]} {
	return $GRID(usery)
      } else {
	return [res -internal]  ;# used only during startup.
      }
    }
    "" -
    "-internal" {
      return [lindex [mn_units] 1]
    }
    "-mask" {
      # Old tech files will not have GRID(mask) defined, so use internal grid
      # Dont think this is necessary, because GRID(mask) is inited at start up.
      if {[info exists GRID(mask)]} {
	return $GRID(mask)
      } else {
	return [res -internal]
      }
    }
    default {
      error {res: syntax: res [-userx | -usery | -internal | -mask]}
    }
  }
}


proc res2 {name} -desc {
  Returns specified design grid as: {gridx gridy offsetx offsety}
} -doc {
  The <name> can be:
  "mask" - manufacturing mask grid
  "user" - current user grid, as set in the grid menu
  "internal" - max internal grid
  <name> - named user grid
  <wire_layer> - grid for specified wire layer

  Returns "" if named grid not found.
  USAGE: res [-userx | -usery | -internal | -mask]
} {
  global GRID
  switch -- $name {
    "user" {
      # There is a race condition: GRID(userx) and GRID(usery) are
      # defined during max initialization in grid_init.
      # Unfortunately, it is possible to get res -userx called
      # by moving the mouse on the screen as max is coming up,
      # and it can beat out grid_init.  So it is possible that
      # GRID(userx) is undefined, but only during startup.
      if {[info exists GRID(userx)]} {
	return [list $GRID(userx) $GRID(usery) 0 0]
      } else {
	return [res2 internal]  ;# used only during startup.
      }
    }
    "internal" {
      set res [lindex [mn_units] 1]
      return [list $res $res 0 0]
    }
    "mask" {
      # Old tech files will not have GRID(mask) defined, so use internal grid
      # Dont think this is necessary, because GRID(mask) is inited at start up.
      if {[info exists GRID(mask)]} {
	return [list $GRID(mask) $GRID(mask) 0 0]
      } else {
	return [res2 internal]
      }
    }
    default {
      # Try for a named grid.
      set stuff [grid_get -name $name]
      if {$stuff != ""} {return $stuff}

      # Try for a wire layer name.
      return [wire_get_grid $name]

      # Grid not found
      return ""
    }
  }
}

proc uusnap args -desc {
  Takes any number of values as args, returns list of results
} -doc {
  USAGE: uusnap [-floor | -ceil] [-user | -mask | -internal | -grid <name>]  arg ...
  Rounds args to nearest legal units (design grid points.)
  If -user, round to user units.   If the user grid is assymetric,
  the first arg is assumed to be an X coord, the second a Y coord, etc.
  If -grid <name>, use the named grid.  See res2 for acceptable grid names.
  if -mask, round to minimum mask units;
  if -internal, round to nearest legal internal units (default case).
  if -floor, round value down to the next smaller unit;
  if -ceil, round value up to the next higher unit;
  otherwise round to nearest unit.
} {
  global GRID
  set rounding_type "round"
  set resx [res]
  set resy $resx
  set offx 0
  set offy 0

  # Parse options out of args
  while {1} {
    switch -- [lindex $args 0] {
      "-floor" {
	# We want to round down.
	# Unfortunately, accumulated floating point error means
	# we cant just use the "floor" function below, because
	# the input value could be just one FP error unit
	# below a res.  Instead, we will later add in an
	# offset that is guaranteed to round down.
	set rounding_type "floor"
      }
      "-ceil" {
	set rounding_type "ceil"
      }
      "-grid" {
	set args [lrange $args 1 end]
	set gridname [lindex $args 0]
	setl {resx resy offx offy} [res2 $gridname]
	if {$gridname == "" || $resx == ""} {
	  error "Grid $gridname not found"
	}
      }
      "-user" {
        set resx [res -userx]
        set resy [res -usery]
      }
      "-mask" {
        set resx [res -mask]
        set resy $resx
      }
      "-internal" { ;# This is also the default case.
	set resx [res]
	set resy $resx
      }
      default {
	# The rest of the args are number arguments
	break
      }
    }
    set args [lrange $args 1 end]
  }

  set result {}
  set i 0
  foreach val $args {
    if { $i % 2 == 0 } {
      set res $resx
      set off $offx
    } else {
      set res $resy
      set off $offy
    }
    incr i
    switch $rounding_type {
      "ceil" { set val [expr $res * ceil(($val-$off)/(0.0+$res)) + $off] }
      "floor" { set val [expr $res * floor(($val-$off)/(0.0+$res)) + $off] }
      default { set val [expr $res * round(($val-$off)/(0.0+$res)) + $off] }
    }
     

    # DONT REMOVE THIS string trim!!!!
    # There is a horrible bug in tcl as follows:
    # If a floating point number is coerced to a string
    # and then converted back to a number, it may or may not
    # be the same number and will compare unequal nondeterministically.
    # I tracked this down, and the problem is the least significant
    # bit in the floating point may be set or not after reconversion.
    # Since tcl now preserves numbers in lists, the number
    # can end up being preserved as long as it is in lists
    # or variables, and then suddenly get converted back to
    # a string by some operation, or as a return value, and then
    # it will no longer be quite the same number any more.
    # This was very difficult to see because 
    # if you just look at the numbers (via puts or any normal
    # means) they will look identical; but if you print
    # them with format %20.18f you can see how they differ.
    # This is particularly bad for uusnap, because, essentially,
    # it was returning two different numbers for the
    # same input, depending on how the result was stored. (pat)

    set val [string trim $val]   ;# DO NOT REMOVE!!!!!!

    # If you take out the above string trim, the following
    # code will catch the error:
    # Without the string trim, sample output was:
    #     1.14 == 1.14  but 1.1400000000000000124 != 1.1399999999999999902
    #set dummy [string trim $val]
    #if { $val != 0 + $dummy } {
    #    error "uusnap failed!!! $val == $dummy but \
    #    	   [format %20.18f $val] != [format %20.18f $dummy]"
    #}

    lappend result $val
  }
  return $result
}

proc center_coords {x1 y1 x2 y2} -desc {
returns center of rectangle (rounded to design grid)
} {
  set x [uusnap [expr ($x1 + $x2) / 2.0]]
  set y [uusnap [expr ($y1 + $y2) / 2.0]]
  return "$x $y"
}

proc inside_rect {x y x1 y1 x2 y2} -desc {
  is point x y inside rect x1 y1 x2 y2
} {
    return [expr \
	[approx $x1 <= $x] && [approx $x <= $x2] && \
	[approx $y1 <= $y] && [approx $y <= $y2] ]
}

proc rect_inside_rect {rect1 rect2} -desc {
  is rect1 inside rect2?
} {
  struct rect r1 $rect1
  struct rect r2 $rect2
    return [expr \
	[approx ${r2.x1} <= ${r1.x1}] && [approx ${r1.x2} <= ${r2.x2}] && \
	[approx ${r2.y1} <= ${r1.y1}] && [approx ${r1.y2} <= ${r2.y2}] ]
}


proc rect_intersect_line {rect x1 y1 x2 y2} -desc {
  return the intersection of line x1,y1 to x2,y2 with rect, assuming x1,y1 is inside and x2,y2 outside rect.
} {
  # line is y = mx + b, where:
  # m is the slope => m = (y2-y1) / (x2-x1)
  # b == any y such that x==0 => y1 = m1*x1 + b => b = -y1/m*x1

  setl {rx1 ry1 rx2 ry2} $rect

  # Special case: vertical line
  # This is a special case because slope is infinite.
  if {[approx $x2 == $x1]} {
    if {$y2 > $y1} {
      # intersects top side
      return [list $x1 $ry2]
    } else {
      # intersects bottom side
      return [list $x1 $ry1]
    }
  }

  # Special case: horizontal line
  # Slope is zero, would get divide by zero error below.
  if {[approx $y2 == $y1]} {
    if {$x2 > $x1} {
      # intersects right side
      return [list $rx2 $y1]
    } else {
      # intersects left side
      return [list $rx1 $y1]
    }
  }

  # Compute m and b such that y = mx + b for line from x1,y1 to x2,y2.
  set m [expr ($y1 - $y2) / ($x1 - $x2)]
  #set b [expr - $y1 / ($m * $x1)]
  set b [expr $y1 - $m * $x1]

  # Solve for intersection.
  if {$x2 > $x1} {
    # Does it intersect the right side?
    set y [expr $m * $rx2 + $b]
    if {$ry1 <= $y && $y <= $ry2} {return [list $rx2 $y]}
  } else {
    # Does it intersect the left side?
    set y [expr $m * $rx1 + $b]
    if {$ry1 <= $y && $y <= $ry2} {return [list $rx1 $y]}
  }

  if {$y2 > $y1} {
    # Does it intersect the top side?  Note: x = (y-b)/m
    set x [expr ($ry2 - $b)/$m]  ;# Find x where line intersects top of rect
    if {$rx1 <= $x && $x <= $rx2} {return [list $x $ry2]}
  } else {
    # Does it intersect the bottom side?
    set x [expr ($ry1 - $b)/$m]  ;# Find x where line intersects top of rect
    if {$rx1 <= $x && $x <= $rx2} {return [list $x $ry1]}
  }

  # If we get here, maybe a round-off error prevented us from finding it.
  #error "rect_intersect_line: intersection not found"
  return ""
}


proc rect_is_visible {x1 y1 x2 y2} -desc {
  Is any edge of the specified rectangle visible?
} {
  setl {xleft ybot xright ytop} [dbt_frame]
  # Add 1% to frame size to make sure its really visible, not on the edge.
  set fudge [expr ($xright - $xleft) * 0.01]
  set xleft [expr $xleft + $fudge]
  set xright [expr $xright - $fudge]
  set ybot [expr $ybot + $fudge]
  set ytop [expr $ytop - $fudge]
  # First check that its not completely off screen.
  if { $x1 > $xright} { return 0 }
  if { $x2 < $xleft} { return 0 }
  if { $y1 > $ytop} { return 0 }
  if { $y2 < $ybot} { return 0 }
  # The box is visible, or we might be inside it.
  # See if any edge is visible.
  if { $x1 > $xleft && $x1 < $xright } { return 1 }
  if { $x2 > $xleft && $x2 < $xright } { return 1 }
  if { $y1 > $ybot && $y1 < $ytop } { return 1 }
  if { $y2 > $ybot && $y2 < $ytop } { return 1 }
  # We are completely inside the rectangle, so no edge is visible.
  return 0
}


proc rect_expand {{-grid mask} rect min_area} -desc {
  Expand rectangle to minarea, keeping aspect ratio as well as possible while keeping rect on grid.
} -doc {
  If -grid, it is name of grid to use.
  Rectangle origin is snapped to grid, so return rectangle is always on grid.
  Returned rectangle will be at least one grid in size in both directions.
} {
  # Determine initial box.  Keep aspect ratio the same.
  setl {snapx snapy} [res2 $grid]
  setl {ox1 oy1 ox2 oy2} $rect
  set x_size [expr $ox2 - $ox1]
  set y_size [expr $oy2 - $oy1]

  # Factor by which box must grow.
  set factor [expr sqrt(1.0 * $min_area / ($x_size * $y_size))]

  set x_size [expr $x_size * $factor]
  set y_size [expr $y_size * $factor]

  # Make sure box is at least one grid in size in both directions.
  set x_size [max $snapx $x_size]
  set y_size [max $snapy $y_size]

  # Round size up to grid.  Must round up to make sure box stays above min_area.
  setl {x_size y_size} [uusnap -ceil -grid $grid $x_size $y_size]

  # Jiggle origin to grid.
  setl {ox1 oy1} [uusnap -grid $grid $ox1 $oy1]

  return [list $ox1 $oy1 [expr $ox1 + $x_size] [expr $oy1 + $y_size]]
}


# Finds the center of the 4 coords or a bbox.  Center will be on grid

proc center_bbox {bbox} {

  global LAYINFO

  setl {x1 y1 x2 y2} $bbox

  set x [round_list_scale [expr ($x1 + $x2)/2.0] [res -mask]]
  set y [round_list_scale [expr ($y1 + $y2)/2.0] [res -mask]]

  return "$x $y $x $y"
}

proc nearby_dist {{factor 1}} -desc {
    Return the minimum spacing for nearby coordinates at the current
    screen size.
} {
  setl {xx1 yy1 xx2 yy2} [dbt_frame]
  set size [max [expr $xx2-$xx1] [expr $yy2-$yy1]]
  # the user can position to 1% accuracy
  set dist [uusnap [expr $size / 100.0]]
  # If they are zoomed way in...
  if { $dist == 0 } { set dist [res] }
  return [expr $dist * $factor]
}


proc nearby {x1 y1 x2 y2 {del ""}} -desc {
Return true if two sets of coords are nearby on the screen for mouse movements.
} -doc {
Nearby means that the coordinates are within 1% of the screen size.
} {

  if {$del == ""} {
      set del [nearby_dist]
  }

  if {[expr abs($x1-$x2)] <= $del && [expr abs($y1-$y2)] <= $del} {
    return 1
  }
  return 0
}

proc nearby_line {x y ax ay bx by} -desc {
    Is the point x,y near the line?
} {
    set near [nearby_dist]
    set dx [expr $bx - $ax]
    set dy [expr $by - $ay]
    #if { abs($dy) < $near && abs($dx) < $near } {
    #	# Line is just a point.  Punt.
    # NO, Dont punt. This case is fine.
    #	return 0
    #}
    # We have to compute both x and y in case line is near vertical or horiz.
    if { $ax < $bx ? ( $x < $ax - $near || $x > $bx + $near ) : 
    	( $x < $bx - $near || $x > $ax + $near ) } {
	# mouse is beyond ends of line.
	return 0
    }
    if { $ay < $by ? ( $y < $ay - $near || $y > $by + $near ) : 
    	( $y < $by - $near || $y > $ay + $near ) } {
	# mouse is beyond ends of line.
	return 0
    }
    if { $dx == 0 } {
	# Vertical line is special.
	return [nearby $x 0 $ax 0]
    }
    # Compute distance between a point and a line.
    # A line through point ax,ay with slope m is: y - ay = m(x - ax)
    # Putting this in canonical form: A*x + B*y + C == 0
    # yields: A = m; B = -1; C = ay - m*ax;
    # Distance from point to line is: (A*x + B*y + C) / (sqrt(A*A + B*B))
    # Therefore:
    set m [expr $dy / $dx] ;# slope
    set dist [expr ($m * $x - $y + $ay - $m * $ax) / sqrt(1 + $m * $m)]

    return [expr abs($dist) < $near]
}


# Accepts a list of numbers and rounds them to the nearest integer, 
# returning the rounding value in a new list

proc round_list {x} {

  set out ""
  foreach y $x {
    lappend out [expr round($y)]
  }

  return $out
}


# this could be merged into round_list but tcl is so pathetically slow
# with numbers, I couldn't do it.

proc round_list_scale {{-floor} {-ceil} x scale {offset 0}} {

  set out [list]
  if {$floor} {
    foreach val $x {
      lappend out [expr (floor(($val-$offset)/$scale)*$scale) + $offset]
    }
  } elseif {$ceil} {
    foreach val $x {
      lappend out [expr (ceil(($val-$offset)/$scale)*$scale) + $offset]
    }
  } else {
    foreach val $x {
      lappend out [expr (round(($val-$offset)/$scale)*$scale) + $offset]
    }
  }
  return $out
}

proc can_rect {rect} -desc {
  sorts rectangle coordinates to lower-left-corner / upper-right-corner order
} {
    setl {x0 y0 x1 y1} $rect

    if { $x1 < $x0 } {
	set t $x0
	set x0 $x1
	set x1 $t
    }

    if { $y1 < $y0 } {
	set t $y0
	set y0 $y1
	set y1 $t
    }

    return "$x0 $y0 $x1 $y1"
}

proc rect_clip {clip rect} -desc {
  Clip the second rectangle to area described by the first.
} {
  setl {cx1 cy1 cx2 cy2} $clip
  setl {rx1 ry1 rx2 ry2} $rect
  if {$rx1 < $cx1} {set rx1 $cx1}
  if {$ry1 < $cy1} {set ry1 $cy1}
  if {$rx2 > $cx2} {set rx2 $cx2}
  if {$ry2 > $cy2} {set ry2 $cy2}
  return [list $rx1 $ry1 $rx2 $ry2]
}

proc move_rect {rect dx dy} -desc {
  Move rectangle by dx,dy.
} {
  setl {bx1 by1 bx2 by2} $rect
  set bx1 [expr $bx1 + $dx]
  set bx2 [expr $bx2 + $dx]
  set by1 [expr $by1 + $dy]
  set by2 [expr $by2 + $dy]
  return [list $bx1 $by1 $bx2 $by2]
}

proc grow_rect {amount rect} -desc {
  expands each edge of rectangle out by given amount
} {
    setl {x0 y0 x1 y1} [can_rect $rect]
    set x0 [expr $x0 - $amount]
    set y0 [expr $y0 - $amount]
    set x1 [expr $x1 + $amount]
    set y1 [expr $y1 + $amount]
    return [list $x0 $y0 $x1 $y1]
}

proc warning {msg {buttons "ok"}} -desc {
  Bring up a warning popup in max and also print to screen.
} -doc {
  5/01: This function deprecated.  Use max_error.

  This function is similar to msg -warn.
  The differences are: 1. The warning is printed NOW, unlike msg -warn,
  which, during interactive commands, is defered until the current
  interactive command completes. (See i_cmd_eval.)
  2.  The warning message is not intercepted by catch or msg_catch.
  3.  Unlike msg, no trailing newline is required.

  Note: for gcells, system startup, and command line processing,
  the msg -warn function should be used instead of this function; in
  those cases the max C code has called tcl code and is awaiting its
  return.  Dialog boxes should not be issued when the C code is
  awaiting the return of a tcl function.

  If buttons is given, it is a list of button names to be
  put on the menu, and the function returns the zero-based index
  of the button that is pressed.
  If buttons is not given, the default buttons is just "ok".
} {
  set msg "Warning: [string trim $msg "\n"]"

  ####### vvvv NEW CODE
  max_error $msg
  return
  ####### ^^^^ NEW CODE

  puts $msg

  set list [split $msg \n]
  if {[llength $list] > 10} {
    set msg [join "[lrange $list 0 9]\n..." \n]
  }

  set ret [eval [list tk_dialog .warning "max warning" $msg {} 0] $buttons]
  # This does not interact properly with cursor_wait:
  #  tkMessageBox -icon warning -title "Max Warning" -message $msg
  return $ret
}


proc stack_trace {{-return}} -desc {
   print a simple stack trace
} -doc {
   This prints only the functions called, not the line numbers.
   It many only be possible to get that information as the stack
   is unwound, ie, by the error function.
   See also: error
} {
    set trace ""
    for {set i 1} {1} {incr i} {
	if { [catch { set thislevel [info level $i] }] } {
	    # All done
	    break
	}
	# Dont include the call to this routine.
	if { [string match {stack_trace*} $thislevel] } { break }
	set trace "$thislevel\n$trace"
    }
    if {!$return} {
      tk_dialog .stack_trace "Stack Trace" $trace {} 0 Done
    }
    return $trace
}


proc max_error {{-abort} {-buffer} {-nonewline} msg} -desc {
  Bring up an error popup in max and also print to screen.
} -doc {
  If -buffer, do not popup message now, just buffer it.  Popup can be posted by msg_flush.
  If -abort, abort caller, similar to error.
  If -nonewline, do not automatically append "\n".

  msg is printed

  OLD DOCUMENTATION:
  This function is similar to the tcl "error" function.
  The differences are:  1. The calling command is not aborted;
  instead, max_error just returns;  2. This command is not caught
  by the msg_catch or catch functions.
  3.  Unlike msg, no trailing newline is required.

  Note: for gcells, system startup, and command line processing,
  the tcl "error" function should be used instead of this function; in
  those cases the max C code has called tcl code and is awaiting its
  return.  Dialog boxes should not be issued when the C code is
  awaiting the return of a tcl function.

  Use "max_error" for user errors that should not abort.
  Use "error" for max internal errors and other errors that should abort.
} {
    ####### vvvv NEW CODE
    global MAX_ERROR_INFO

    # Save current stack trace for debugging purposes.
    # Note: cant use catch {error ""} to force a stack-trace,
    # because the errorInfo set by error stops at the call to catch.
    set MAX_ERROR_INFO [stack_trace -return]

    if {! $nonewline} {append msg "\n"}
    msg -warn $msg
    if {! $buffer} {msg_flush}

    if {$abort} {return -code error $msg}

    return
    ####### ^^^^ NEW CODE

    set msg "[string trim $msg \n]"
    puts $msg
    set list [split $msg \n]
    if {[llength $list] > 10} {
      set msg [join "[lrange $list 0 9]\n..." \n]
    }
    # 4/00: Took out stack trace - dont want users to see that!
    #set buttonpress [tk_dialog .warning "max error" $msg {} 0 ok {Stack Trace}]
    # Note: tk_dialog checks for BATCH variable.
    set buttonpress [tk_dialog .warning "max error" $msg {} 0 ok]
    #if { $buttonpress == 1 } {
	# debug button pressed in max developer mode
	# Give user a chance to get a stack trace...
	# stack_trace
    #}
}

proc button_down {} -desc {
    returns list of mouse buttons that are currently down
} {
    set result ""
    foreach i [mn_button_state] {
	if { [string match Button* $i] } {
	    set result "$result $i"
	}
    }

    return $result
}
    
proc orientation {{-reverse} xform} -desc {
  extract orientation from instance transform
} -doc {
  xform = first two rows of 3x3 transform from instance coords to rootcell.
            (this is how transforms are represented internally in Max)
  results:
    ""      - identity
    r90     - clockwise 90 degrees
    r180    - clockwise 180 degrees
    r270    - clockwise 270 degrees
    fx       - mirrored about y axis
    fy       - mirrored about x axis
    fx_r90 
    fy_r90

  If -reverse, perform the reverse transformation.
} {
  
  if {$reverse} {

    switch $xform {
    ""     { return "1 0 0 0 1 0" }
    r180   { return "-1 0 0 0 -1 0" }
    fx     { return "-1 0 0 0 1 0" }
    fy     { return "1 0 0 0 -1 0" }
    r90    { return "0 1 0 -1 0 0" }
    r270   { return "0 -1 0 1 0 0" }
    fx_r90 { return "0 1 0 1 0 0" }
    fy_r90 { return "0 -1 0 -1 0 0" }
    default { error "unrecognized orientation: $xform" }
    }

  } else {

    setl {a b c d e f} $xform
    if {$f == ""} {error "invalid transform"}

    if {$a == 1} {
	if {$e == 1} { 
	    return "" 
	} else {
	    return "fy"
	}
    } elseif {$a == -1} {
	if {$e == -1} {
	    return "r180"
	} else {
	    return "fx"
	}
    } elseif {$b == 1} {
	if {$d == -1} {
	    return "r90"
	} else {
	    return "fx_r90"
	}
    } else {
	if {$d == 1} {
	    return "r270"
	} else {
	    return "fy_r90"
	}
    }
  }
}


# Note: pat deprecated on 4/17/01.
proc transform_cell {cell_def xform} -desc {
  deprecated function.  use selt_transform instead.
} {
  selt_transform -cell_origin $cell_def -transform $xform
}

proc selt_transform {{-reverse} {-cell_origin ""} {-transform} xform} -desc {
  Apply the transform to the current selection.
} -doc {
  If -transform, xform is the first two rows of the matrix transform
  as defined by max db_search command.
  Otherwise, xform is specified as a max orientation ("", r90, r180, etc)
  If -reverse, then undo the transform.  (NOT TESTED)
  If -cell_origin, transform about the origin of the specified cell
  instead of using the bbox.  Note that it does not matter what cell
  is selected - the offset after translation comes from -cell_def.
  If that cell happens to be the only thing selected, then the result
  is that the cell is translated about its origin.

  NOTE: Currently assumes that -transform does not include linear translation,
  ie transform is "a b 0 d e 0"
} {

  if {$transform} {
    set orient [orientation $xform]
  } else {
    set orient $xform
  }

  if { $reverse} {
    # unorient
    switch $orient {
      "r90" {
	:clockwise 270
      }
      "r180" {
	:clockwise 180
      }
      "r270" {
	:clockwise 90
      }
      "fx" {
	:sideways
      }
      "fy" {
	:upsidedown
      }
      "fx_r90" {
	:clockwise 270
	:sideways
      }
      "fy_r90" {
	:clockwise 270
	:upsidedown
      }
    }
  } else {
    # change orientation according to transform
    switch $orient {
      "r90" {
	:clockwise
      }
      "r180" {
	:clockwise 180
      }
      "r270" {
	:clockwise 270
      }
      "fx" {
	:sideways
      }
      "fy" {
	:upsidedown
      }
      "fx_r90" {
	:sideways
	:clockwise
      }
      "fy_r90" {
	:upsidedown
	:clockwise
      }
    }
  }

  if {$cell_origin != ""} {
    setl {a b c d e f} $xform
    setl {x1 y1 x2 y2} [db_bbox -cell $cell_origin]
    # All max rotations are about the bounding box x1,y1.
    # We want to rotate/flip about the cell origin.
    # So compute lx,ly that moves origin to bbox x1,y1 in unrotated
    # coordinate system, then moves it back to (0,0) in
    # the new rotated/flipped coordinate system.
    switch $orient {
      "" {
	set lx 0
	set ly 0
      }
      "r90" {
	set lx [expr $y1 - $x1]
	set ly [expr - $x2 - $y1]
      }
      "r180" {
	set lx [expr - $x2 - $x1]
	set ly [expr - $y2 - $y1]
      }
      "r270" {
	set lx [expr - $y2 - $x1]
	set ly [expr $x1 - $y1]
      }
      "fx" {
	set lx [expr - $x2 - $x1]
	set ly 0
      }
      "fy" {
	set lx 0
	set ly [expr - $y2 - $y1]
      }
      "fx_r90" {
	set lx [expr $y1 - $x1]
	set ly [expr $x1 - $y1]
      }
      "fy_r90" {
	set lx [expr - $y2 - $x1]
	set ly [expr - $x2 - $y1]
      }
      default { error "unexpected orient: $orient" }
    }
    if { $reverse } {
      :move e [expr - $c - $lx]
      :move n [expr - $f - $ly]
    } else {
      :move e [expr $c + $lx]
      :move n [expr $f + $ly]
    }
  }
}


proc transform_coords {{-reverse} xform x y} -desc {
    Transform coords using matrix transform
} -doc {
    Max uses a matrix multiply to transform sub-cell coords
    to the parent cell.  This function performs the transform on x y
    and returns the new coords.
    Given local coords x,y, the parent coords x2,y2 are:
    x2 = x1 tax + y1 tay + tac
    y2 = x1 tbx + y1 tby + tbc

    This function is usually needed only when there is a bug in max
    that requires you to do the transform yourself.
} {
    setl {tax tay tac tbx tby tbc} $xform
    if {$reverse} {
      # Calculate the reverse transform: {rax ray rac rbx rby rbc} and use that.
      set tmp [expr $tay * $tbx - $tax * $tby]
      set rax [expr -1.0 * $tby/$tmp]
      set ray [expr 1.0 *  $tay/$tmp]
      set rac [expr (1.0 * $tby * $tac - $tay * $tbc)/$tmp]
      set tmp [expr $tby * $tax - $tbx * $tay]
      set rbx [expr -1.0 * $tbx/$tmp]
      set rby [expr 1.0 *  $tax/$tmp]
      set rbc [expr (1.0 * $tbx * $tac - $tax * $tbc)/$tmp]
      set x_new [expr $x*$rax + $y*$ray + $rac]
      set y_new [expr $x*$rbx + $y*$rby + $rbc]
    } else {
      set x_new [expr $x*$tax + $y*$tay + $tac]
      set y_new [expr $x*$tbx + $y*$tby + $tbc]
    }
    return [list $x_new $y_new]
}


# Note: db_search interacts with the "expanded" bit.
# When you search hierarchy, it only looks in cells the user can see in,
# unless you include -cell option.
proc db_search_l {action args} -desc {
  like db_search, but returns a list, and with other changes.
} -doc {

  This should be written in C.

db_search_l labels [-cell <def>] [-hier <type>] [-limit <n>] [-layers <commalist>]
      [-area <xbot> <ybot> <xtop> <ytop>] [-kind <kind>] [-exact] [-glob] [labelname]

  returns a list of labels of the form:  
    "layer xbot ybot xtop ytop pos text instance_path group kind"
    (root cell coordinates).

  If -cell, start the search in the specified cell instead of the edit-cell.

  If -area, find only labels in the specified area.

  -hier <type>
    <type> may be:
    "none" - (default) search edit cell only;
    "all"  - search all loaded cells;
    "vis"  - search all visible cells;
    "stop" - use cell stop list. (not implemented)

    NOTE:  Some of these are implemented using edit_push,
    which blows away the selection and may change the current view.
  
  -exact - (default) find specified label exactly.
    In this case, the labelname can be a path.

  -glob -  Return any labels matching the labelname as a glob pattern.
     The pattern may not be a pathname.

     Glob matching uses the characters: * ? [ ]
     To match one of these characters, precede it with a backslash.
     Note that both the backslash and bracket characters are special
     to tcl, and so must be enclosed in curly braces.
     To search for the label x[1], you must use:

	 db_search_l labels -glob {x\[1\]}

  -layers <commalist> 
    returns only labels on the specified comma-separated list of layers.

  -kind <kind>
    returns only labels of given kind (i.e. in, out, inout,
    local, global, text, or hidden)


  -any_cell - for backward compatibility, same as -hier vis
  -non_hier - for backward compatibility, same as -hier none


db_search_l paint [-cell <def>] [-hier <type>] [-limit <n>]
      [-area <xbot> <ybot> <xtop> <ytop>] [<layers>]
    
    This is not implemented yet.  Hopefully mha will put this inside:
    If <layers> not specified, only user defined layers are returned.
    Note that db_search paint returns checkpaint, etc.
  


db_search_l cells [-no_fets] [-no_vias] ...

    -no_fets  excludes fets from the returned list of cells.

    -no_vias  excludes vias from the returned list of cells.

    For other options, see db_search cells


  5/17/01: Results from timing tcl version of db_search_l:
  db_search label foo - 145us
  db_search_l label foo - 160us
  db_search_l label -exact foo - 240us
} {
  set no_fets -1  ;# -1 means dont do it.
  set no_vias -1  ;# -1 means dont do it.


  switch $action {
    "labels" {
      # This is slow

      set cell ""
      set hier none
      set layers ""
      set glob 0

      set opts {{cell ""} {hier none} {limit ""} {exact} {glob} \
	 {any_cell} {non_hier} {layers ""} {kind ""}}

      # Parse options, put those we dont want to process
      # back into the command line.
      # TODO: Could use db_search_labels here.
      set cmd [list db_search_labels]
      set len [llength $args]
      for {set i 0} {$i < $len} {} {
	switch -- [lindex $args $i] {
	  -cell {
	    set cell [lindex $args [expr $i+1]]
	    incr i 2
	  }
	  -hier {
	    set hier [lindex $args [expr $i+1]]
	    incr i 2
	  }
	  -limit {
	    lappend cmd -limit [lindex $args [expr $i+1]]
	    incr i 2
	  }
	  -exact {
	    set glob 0
	    incr i 1
	  }
	  -glob {
	    set glob 1
	    incr i 1
	  }
	  -any_cell { ;# For backward compatibility
	    set hier all
	    incr i 1
	  }
	  -non_hier { ;# For backward compatibility
	    set hier none
	    incr i 1
	  }
	  -layers {
	    set layers [lindex $args [expr $i+1]]
	    incr i 2
	  }
	  -kind {
	    lappend cmd -kind [lindex $args [expr $i+1]]
	    incr i 2
	  }
	  -area {
	    set cmd [concat $cmd [lrange $args $i [expr $i+4]]]
	    incr i 5
	  }
	  -- { ;# end of options
	    incr i 1
	    break
	  }
	  default {
	    # It better be a label name or pattern.
	    break
	  }
	}
      }

      if {$i < $len-1} {
	error "db_search_l labels: unrecognized: [lrange $args $i end]"
      }

      set pattern [lindex $args $i]

      set cell_pushed 0  ;# Set if we have to do an edit_push.
      switch $hier {
	none {
	  lappend cmd -non_hier
	  if {$cell != ""} {
	    lappend cmd -cell $cell
	  }
	}
	vis {
	  # Search visible cells is the default for db_search
	  # if no other options given.
	  # So if -cell IS given, then we have to edit push into the cell
	  # we want, pop out later.
	  if {$cell != "" && $cell != [lay_editcell]} {
	    edit_push_direct $cell
	    set cell_pushed 1
	  }
	}
	all {
	  # The db_search -cell option is overloaded: it sets an internal flag
	  # that traverses all hierarchy.
	  if {$cell == ""} {
	    lappend cmd -cell [lay_editcell]
	  } else {
	    lappend cmd -cell $cell
	  }
	}
	stop {
	  error "db_search_l labels: -hier stop not implemented"
	}
	default {
	  error "db_search_l: syntax: unrecognized -hier option: $hier"
	}
      }

      if {$pattern != ""} {
	if {$glob==0} {
	  # Quote initial "-" so result can be used as an argument without danger
	  # of being misinterpreted as an option.
	  regsub -all {(^-)|([][\*?])} $pattern {\\&} pattern
	}
	lappend cmd $pattern
      }

      #set result [split [string trim [eval $cmd] \n] \n]
      set result [eval $cmd]

      if {$cell_pushed} {
	edit_pop_direct
      }

      if {$layers == ""} {
	return $result
      } else {
	set layers [split $layers ,]

	# Process the result to include only the specified layers
	set label_layer_index [struct_index max_label layer]
	set ret ""
	foreach lab_info $result {
	  if {[lsearch -exact $layers [lindex $lab_info $label_layer_index]] >= 0} {
	    lappend ret $lab_info
	  }
	}
	return $ret
      }
    }

    "cells" {

      # Look for -no_vias and -no_fets options.
      set no_vias [lsearch -exact $args "-no_vias"]
      if {$no_vias >= 0} {set args [lreplace $args $no_vias $no_vias]}
      set no_fets [lsearch -exact $args "-no_fets"]
      if {$no_fets >= 0} {set args [lreplace $args $no_fets $no_fets]}

      #set result [split [string trim [eval [concat db_search $action $args]] \n] \n]
      set result [eval [concat db_search_cells $args]]

      if {$no_vias >= 0 || $no_fets >= 0} {

	set new_result ""
	foreach cell_info $result {
	  set def [cellinfo_def $cell_info]
	  switch -- [string tolower [string range def 0 3]] {
	    "#via" -
	    "#fet" -
	    "via" -
	    "fet" {
	      continue
	    }
	    default {
	      lappend new_result $cell_info
	    }
	  }
	}
	return $new_result
      } else {
	return $result
      }
    }

    default {
      return [split [string trim [eval [concat db_search $action $args]] \n] \n]
    }
  }
}


proc old_db_search_l {action args} -desc {
  like db_search, but returns a list, and with other changes.
} -doc {

  This should be written in C.

  Adds new options for labels:
  
    -exact searches for exact match instead of glob pattern.

    -any_cell searches any cell with internals visible.
	      Either -any_cell or -non_hier must be specified, unlike db_search.

    -layers   only returns labels on the specified comma-separated layer list
  
  Adds new options for cells:

    -no_fets  excludes fets from the returned list of cells.

    -no_vias  excludes vias from the returned list of cells.


  Note: This function will eventually be implemented in C.
  5/17/01: Results from timing tcl version of db_search_l:
  db_search label foo - 145us
  db_search_l label foo - 160us
  db_search_l label -exact foo - 240us
} {
  set no_fets -1  ;# -1 means dont do it.
  set no_vias -1  ;# -1 means dont do it.

  switch $action {
    "labels" {

      # Look for -exact option
      set i [lsearch -exact $args "-exact"]
      if {$i >= 0} {
	# Remove -exact
	set args [lreplace $args $i $i]
	# Prepend glob chars with a backslash.
	# 5/21/01: Note: must also escape an initial dash,
	# or db_search thinks the label name is an option!
	set pattern [lindex $args end]
	regsub -all {(^-)|([][\*?])} $pattern {\\&} pattern
	set args [lreplace $args end end $pattern]
      }

      # Look for -any_cell and -non_hier options
      set j [lsearch $args -any_cell]
      set k [lsearch $args -non_hier]
      if {$j < 0 && $k < 0} {
	# We do this to eliminate the many bugs that were in max
	# because people (like me) forget to use -non_hier.
	error "db_search_l labels: you must specify -any_cell or -non_hier"
      }
      if {$j >= 0} {
	# Remove -any_cell
	set args [lreplace $args $j $j]
      }

      # Look for -layers
      set layers ""
      set l [lsearch -exact $args "-layers"]
      if {$l >= 0} {
	set layers [split [lindex $args [expr $l+1]] ,]
	set args [lreplace $args $l [expr $l+1]]
      }

      set result [split [string trim [eval [concat db_search $action $args]] \n] \n]

      if {$layers == ""} {
	return $result
      }

      # Process the result to include only the specified layers
      set label_layer_index [struct_index max_label layer]
      set ret ""
      foreach lab_info $result {
	if {[lsearch -exact $layers [lindex $lab_info $label_layer_index]] >= 0} {
	  lappend ret $lab_info
	}
      }
      return $ret
    }

    "cells" {

      # Look for -no_vias and -no_fets options.
      set no_vias [lsearch -exact $args "-no_vias"]
      if {$no_vias >= 0} {set args [lreplace $args $no_vias $no_vias]}
      set no_fets [lsearch -exact $args "-no_fets"]
      if {$no_fets >= 0} {set args [lreplace $args $no_fets $no_fets]}

      set result [split [string trim [eval [concat db_search $action $args]] \n] \n]

      if {$no_vias >= 0 || $no_fets >= 0} {
	set new_result ""
	foreach cell_info $result {
	  set def [cellinfo_def $cell_info]
	  switch -- [string tolower [string range def 0 3]] {
	    "#via" -
	    "#fet" -
	    "via" -
	    "fet" {
	      continue
	    }
	    default {
	      lappend new_result $cell_info
	    }
	  }
	}
	return $new_result
      } else {
	return $result
      }
    }

    default {
      return [split [string trim [eval [concat db_search $action $args]] \n] \n]
    }
  }
}

proc sel_what_l {args} -desc {
  like sel_what, but return a list.
} {
  # Have to pass the -edit_only var from previous stack
  # frame up to this stack frame.
  if {[llength $args] == 3 && [lindex $args 1] == "-edit_only"} {
    set var [lindex $args 2]
    upvar $var $var
  }
  return [split [string trim [eval sel_what $args] \n] \n]
}


# Helper routines for creating toplevel window.
proc util_win_create {win title} -desc {
  create new toplevel window named win with title: title.
} {
    # Create new window
    catch { destroy $win }
    toplevel $win
    wm minsize $win 100 100
    wm withdraw $win   ;# Window will be brought back by util_win_finish
    wm title $win $title
}


proc util_win_finish {win args} -desc {
  Finish window created by util_win_create.
} -doc {
  The <placement> arg is "right" to align right edge of window
  with right side of screen; "normal" to bring up 50 pixels
  from left edge.

  Example:

  util_win_create .mywindow {This is the window title}
  # Stuff the window with widgets.
  util_win_finish normal 750x500
} {
    global max_win UTIL_WIN

    update idletasks

    # Use previous geometry to preserve user window placement, if possible.
    set geom [use_first UTIL_WIN($max_win,$win)]

    if {$geom != ""} {
      wm geom $win $geom
    } else {

      switch -- [lindex $args 0] {
	-place {
	  switch -- [lindex $args 1] {
	    right {
	      # Bring up the window at the top right side of the screen.
	      # We want to bring the window up near the top of the screen,
	      # but underneath the help window.  25 pixels seems to do it.
	      set xborder 8
	      set topborder 25

	      set wx [expr [winfo rootx $max_win] + [winfo width $max_win] - \
		  [winfo reqwidth $win] - $xborder]
	      set wy [expr [winfo rooty $max_win] + $topborder]
	      wm geom $win "+$wx+$wy"
	    }
	    normal {
	      wm geom $win [_relative_origin]
	    }
	  }
	}
      }
    }
    util_win_onscreen $win
    wm deiconify $win
}

proc util_win_destroy {win} -desc {
  Destroy window, but remember where it was.
} {
  global max_win UTIL_WIN
  set UTIL_WIN($max_win,$win) [wm geom $win]
  destroy $win
}

proc util_win_onscreen {win} -desc {
  move toplevel window on screen, in case it floated off to right/bottom.
} {
  update idletasks

  set xborder 8
  set topborder 25
  regexp {(.*)x(.*)\+(.*)\+(.*)} [wm geom $win] junk w_width w_height w_x w_y
  set dx [min [expr [winfo screenwidth $win] - $w_width - $w_x - $xborder] 0]
  set dy [min [expr [winfo screenheight $win] - $w_height - $w_y + $topborder] 0]
  if {$dx < 0 || $dy < 0} {
    wm geometry $win "+[expr round($w_x+$dx)]+[expr round($w_y+$dy)]"
  }
}


if {0} {
  # Defined in base c max now.
  proc lsearch2 {args} -desc {
    Like lsearch, with extra functionality.
  } -doc {
    USAGE:
      lsearch2 [-index n] [-value] [-nocase] [-exact|-glob|-regexp] list pattern

    If -index, treat each element as a sub-list, and look
    at the nth element.
    If -value, return the value, not the index, and return "" if not found.

    Should also support: -nocase, -exact, -glob, -regexp.
    Currently only -exact mode supported.
    This routine should really be implemented as a tcl extension.
    See also: get_assoc.
  } {
    setl {list pattern} [call_keyword $args {{index ""} {value} {nocase}}]
    if {$nocase} {
      set list [string tolower $list]
      set pattern [string tolower $pattern]
    }
    switch "$index" {
      "" {
	set n [lsearch $list $pattern]
      }
      0 {
	regsub -all {[][*?\\]} $pattern \\\\& pattern
	set n [lsearch $list "$pattern *"]
	# If the name has a space, quote or [] in it, tcl 8 will enclose
	# the name in {curly brackets} when it converts it to canonical
	# list notation, so search for that too.
	if { $n < 0 } {
	  set n [lsearch $list "{$pattern} *"]
	}
      }
      default {
	# This is really really really slow......
	set len [llength $list]
	for {set n 0} {$n < $len} {incr n} {
	  set element [lindex $list $n]
	  if {[lindex $element $index] == $pattern} {
	    return [expr {$value ? $element : $n}]
	  }
	}
      }
    }

    if { $n >= 0 } {
      return [expr {$value ? [lindex $list $n] : $n}]
    } else {
      # Failed.
      return [expr {$value ? "" : -1}]
    }
  }
}

proc do {body fwhile expr} {
  assert { $fwhile == "while" }
  while {1} {
    uplevel 1 $body
    if {[uplevel 1 "expr {$expr}"]} continue
    return
  }
}


proc util_mkdir {dirname} -desc {
  Create directory.  One or more path elements may not exist.
} {
  foreach string [split $dirname /] {
    if {$string == ""} {
      continue
    }
    append makedir /$string
    
    if {![file isdir $makedir]} {
      # make this directory
      catch "exec mkdir $makedir"
    }
  }
}

# Convert value in range omin..omax to range nmin..nmax.
# args can be -rev and/or -log
# Use logararithmic scale.
proc util_scale {val omin omax nmin nmax args} {
  set f_log [memq $args "-log"]
  if {$f_log} {
    set nmin [expr log10($nmin)]
    set nmax [expr log10($nmax)]
  }
  if {[memq $args "-rev"]} {
    # Perform reverse computation.
    if {$f_log} {
      return [expr (log10($val) - $nmin) * ($omax - $omin)/($nmax - $nmin) + $omin] 
    } else {
      return [expr ($val - $nmin) * ($omax - $omin)/($nmax - $nmin) + $omin] 
    }
  } else {
    if {$f_log} {
      return [expr pow(10,($val - $omin) * ($nmax-$nmin)/($omax - $omin) + $nmin)]
    } else {
      return [expr ($val - $omin) * ($nmax-$nmin)/($omax - $omin) + $nmin]
    }
  }
}

proc util_find_path {file {option executable}} -desc {
  Find file on the path.  option can be "isfile", "executable", or any tcl "file" subcmd.
} {
  global env
  foreach dir [split $env(PATH) :] {
    set filepath [file join $dir $file]
    if [file $option $filepath] {
      return $filepath
    }
  }
  return ""
}

proc util_load_pkg {pkg_file {pkg_name ""}} -desc {
  Load a tcl shared-object package.
} {
  global UTIL_PACKAGES MN_BIN_DIR MAX_DEVELOPER MMI_LOCAL MMI_TOOLS env

  if {[info exists UTIL_PACKAGES(${pkg_file},loaded)]} {return}

  # The tcl "load" command requires that the first argument be a path,
  # so if you really want to use a file in the current directory,
  # pass in ./filename.
  if {[string match */* $pkg_file] && [file exists $pkg_file]} {
    set filepath $pkg_file
  } else {
    # Look on PATH.
    set filepath [util_find_path $pkg_file]
  }

  if {$filepath == ""} {
    if {[string match /* $pkg_file]} {
      error "Could not find file: $pkg_file"
    } else {
      error "Could not find file $pkg_file on PATH"
    }
  } else {
    set cmd "load $filepath $pkg_name"
    msg "$cmd\n"
    eval $cmd
    set UTIL_PACKAGES(${pkg_file},loaded) 1

    # And now, since nl_shell over-writes some tcl procs
    # with non-functional versions, we have to reload maxtcl.
    # What a choke.
    # 6/26: Renamed unwind_protect to unwind_catch, so this is no longer necessary.
    # reload utils
  }
  return $cmd

  ##### OLD CODE ####

  # MN_BIN_DIR is something like bin.sparc-solaris2.
  # If max developer, look in current directory first.
  set path ""
  if {$MAX_DEVELOPER} { lappend path "." }
  if {[info exists env(HOME)]} {
    lappend path $env(HOME)/mmi_private/$MN_BIN_DIR
  }
  lappend path $MMI_LOCAL/$MN_BIN_DIR
  lappend path $MMI_TOOLS/$MN_BIN_DIR

  foreach dir $path {
    set filename [file join $dir $pkg_file]
    if {[file exists $filename]} {
      msg "Loading $pkg_file from $filename\n"
      eval load $filename $pkg_name
      set FPLAN(${pkg_file},loaded) 1
      return
    }
  }

  if {![info exists UTIL_PACKAGES(${pkg_file},loaded)]} {
    error "Could not find file $pkg_file on path: $path"
  }
}


# THIS SHOULD GO IN share_utils.tcl.
proc parse_keyword {args} -desc {
  Parse function options using -option syntax.
} -doc {
  SYNTAX:
    parse_keyword [-all] <args> <default_list> <array_name>

  If -all, generate an error if there is an unrecognized option.
  Return options in array named <array_name>.
  The <default_list> is as for call_keyword.

  Example:

  proc foo {args} {
     set options [list {a 34} {b} {c {hi there}} {d example}]
     parse_keyword $args $options opt
     ...
  }

  With input:
     foo -a 23 hi -b -c {bar qux} there -x

  Will return:
    hi there -x

  And will define, in the context of foo:
    set opt(a) 23
    set opt(b) 1
    set opt(c) {bar qux}
    set opt(d) example
} {

  set consume_all 0

  # Parse the options to parse_keyword itself.
  while {[llength $args] > 3} {
    switch -- [lindex $args 0] {
      "-all" {
	set consume_all 1
	set args [lrange $args 1 end]
	continue
      }
    }
    break
  }

  set _ARG_LIST [lindex $args 0]
  set _DEFAULT_LIST [lindex $args 1]
  set array_name [lindex $args 2]
  upvar $array_name result

  set ret ""

  foreach _DEFAULT $_DEFAULT_LIST {
    set _ARG_NAME [lindex $_DEFAULT 0] 
    if {[llength $_DEFAULT] == 1} {
      set binary(-$_ARG_NAME) 1
      set result($_ARG_NAME) 0
    } else {
      set binary(-$_ARG_NAME) 0
      set result($_ARG_NAME) [lindex $_DEFAULT 1]
    }
  }

  for {set _INDEX 0} {$_INDEX < [llength $_ARG_LIST]} {} {
    set this_arg [lindex $_ARG_LIST $_INDEX]
    if {[info exists binary($this_arg)]} {
      # This is a keyword.
      set name [string range $this_arg 1 end]
    
      if {$binary($this_arg)} {
	# binary switch
	set result($name) 1
	incr _INDEX
      } else {
	set result($name) [lindex $_ARG_LIST [expr $_INDEX+1]]
	incr _INDEX 2
      }
    } else {
      lappend ret $this_arg
      incr _INDEX
    }
  }
  if {$consume_all && $ret != ""} {
    error "unrecognized option(s): $ret"
  }
  return $ret
}


proc util_unglob {name} -desc {
  Quote glob matching characters, so name can be searched using exact match when a glob-pattern is needed.
} {
  regsub -all {\[|\]|\*|\?|\{|\}|\~} $name {\\&} result
  return $result
}


proc util_uniq {list} -desc {
  Return list with non-unique elements removed.  List order is randomized.
} {
  foreach thing $list {
    set hash($thing) 1
  }
  return [array names hash]
}


proc unwind_catch {body keyword after} -desc {
  Run commands in body, then in after, even if an error occurs while evaluating body.
} -doc {
  Keyword must be "always".
  Example:

  set fd [open filename r]
  edit_push -cell cellname
  unwind_catch {
    puts $fd whatever
    ...
  } always {
    close $fd
    edit_pop
  }

  Does nothing about messages passed by the msg command.
  Those are still passed to the calling contect without interference from unwind_catch.
} {
    global errorInfo errorCode

    if {$keyword != "always"} {error "unwind_catch syntax"}

    # Run in uplevel both to get local variables in parent.
    set code [catch {uplevel $body} result]

    uplevel $after

    if { $code == 0 } {
        return $result
    } elseif { $code == 1 } {
        #uplevel [concat return -code $code -errorinfo "{$errorInfo}" -errorcode $errorCode "{$msg}"]
	# The result is the error message.
        return -code $code -errorinfo $errorInfo -errorcode $errorCode $result
    } else {
        #uplevel [concat return -code $code "{$msg}"]
        return -code $code $result
    }
}


# TEMPORARY DEFINITION.  This is going in share_utils.tcl
proc struct_index {structname element} -desc {
  Return the index in the list of the specified element.
} {
  global MAX_STRUCT
  return [lsearch -exact $MAX_STRUCT($structname) $element]
}

proc util_prof {begin_end {procname ""}} -desc {
  Accumulate total elapsed time in PROF array.
} -doc {
  <begin_end> is "begin" to start and "end" to stop the time accumulation for <procname>.
  If <procname> is not given, use the name of the calling proc.
  If <procname> is specified, it can be any arbitrary string to time anything.
  View using parray PROF.
  Note that for procs, time includes elapsed time in subroutines, even
  if they are also profiled.
} {
  global PROF _PROF_BEGIN
  if {$procname == ""} {
    set procname [lindex [info level -1] 0]
  }
  if {$begin_end == "begin"} {
    set _PROF_BEGIN($procname) [clock seconds]
  } else {
    if {![info exists PROF($procname)]} {
      set PROF($procname) 0
    }
    set PROF($procname) [expr $PROF($procname) + [clock seconds] - $_PROF_BEGIN($procname)]
  }
}


proc utils_ldiff {list1 list2} -desc {
  Diff two lists efficiently.  Return: [list extra_items_in_list1 extra_items_in_list2]
} {
  set extra2 ""
  foreach thing $list1 {
    set a1($thing) 1
  }
  foreach thing $list2 {
    if {[info exists a1($thing)]} {
      unset a1($thing)
    } else {
      lappend extra2 $thing
    }
  }
  set extra1 [array names a1]
  return [list $extra1 $extra2]
}


proc util_match_list {patlist str} -desc {
  Return true if str matches any glob pattern from patlist.
} {
  foreach pat $patlist {
    if {[string match $pat $str]} { return 1; }
  }
  return 0;
}


proc grep {{-list} pattern lines} -desc {
  Search for regular expression pattern in lines.
} -doc {
  By default, lines is interepreted as newline separated lines.
  If -list, interpret lines as a list.
} {
  if {! $list} {
    set lines [split $lines \n]
  }
  foreach line $lines {
    if {[regexp $pattern $line]} {
      puts $line
    }
  }
}
