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

set RCSVERSION(ruler.tcl) { $Revision: 1.16 $ }

# Implements a ruler

init_global RULER(grid_mode) -default "user" -desc {
  Specifies ruler snap grid.  Possible values are defined by ruler_menu.
  Requires global initialization because it must
  be defined before calling grid_menu.
} -doc {
  internal to ruler code
} -flags internal

init_global RULER(coord_mode) -default "relative" -desc {
  Can be "relative" or "absolute" to specify text coords that
  will appear on the ruler.  Requires global initialization because
  it must be defined before calling grid_menu.
} -doc {
  internal to ruler code
} -flags internal

init_global RULER(alternate_grid) -default "1" -desc {
  Alternate ruler grid in microns.  Requires global initialization because
  it must be defined before calling grid_menu.
} -doc {
  internal to ruler code
} -flags internal

init_global RULER(font_size) -default "1" -desc {
  Default font size.  Must be 0, 1, 2, or 3, where
  0 is small and 3 is large.
} -doc {
  internal to ruler code
} -flags internal

init_global _RULER_INT(count) -default "0" -desc {
  Number of active rulers.
} -doc {
  internal to ruler code
} -flags internal

proc ruler_mode_enter {} -desc {
  start drawing a ruler
} -doc {
  leaves box and cursor undisturbed
} {
  # Without this, pressing Control-R twice gets you in ruler mode twice.
  if {[mode_current] != "ruler"} {
    mode_push ruler
  }
}


proc _ruler_mode_define {} -desc {
    drag ruler (leaves box and point undisturbed)
} {
    global _RULER_INT
    mode_def ruler _ruler_gate_keeper "BUT-1 starts ruler. Shift for angle. BUT-3 menu. CTRL-c aborts."

    mode_bind -cmd 0 -desc "start ruler" ruler <Any-Button-1> _ruler_vertex
    mode_bind -cmd 0 -desc "start ruler" ruler <Shift-Button-1> "_ruler_vertex shift"
    mode_bind -cmd 0                     ruler <Any-Motion>  _ruler_drag
    mode_bind -cmd 0                     ruler <Shift-Motion>  "_ruler_drag shift"
    mode_bind -cmd 0 -desc "end ruler"   ruler <Button-2> mode_pop
    mode_bind -cmd 0 -desc "ruler menu"   ruler <Button-3> ruler_menu
    mode_bind -cmd 0 -desc "clear all rulers"   ruler c \
	{ ruler_clear;mode_pop }
    # Second control-r with no intervening buttons clears ruler.
    mode_bind -cmd 0 -desc "ruler clear"   ruler <Control-r> \
	{ if { ! $_RULER_INT(did_ruler) } ruler_clear;mode_pop }
}


proc _ruler_gate_keeper {event} -desc {
    called whenever ruler mode is entered/exited
} -doc {
    saves box on entry, restores on exit.
} {
  global _RULER_INT mode_abort

  if {$event == "PUSH_TO"} {
    set _RULER_INT(state) 0
    incr _RULER_INT(count)
    set _RULER_INT(tag) "ruler$_RULER_INT(count)"
    set _RULER_INT(did_ruler) 0
    pan_enable
  } elseif {$event == "POP_FROM"} {
    pan_disable

    # Do NOT put an undo here.  There is nothing to undo!
    # And the ruler is common mode, so can be done from within
    # other modes, so we do not want an extraneous extra
    # undo delimiter in there.

    if { $mode_abort } {
	ruler_clear current
	# If user types control-C during ruler_mode, we abort the ruler
	# mode but do not abort the sub-mode that called the ruler, if any.
	set mode_abort 0
    }

    # Update the screen, but do not add an undo_delim.
    i_cmd_between_undos
  }
}

proc ruler_clear {{current ""}} -desc {
  erase the visible ruler
} {
  global _RULER_INT
  if { $current == "menu" } {
    # We were invoked from the ruler menu.
    if { [mode_current] == "ruler" } {
      mode_pop
    }
  }
  if { $current == "current" } {
    # Clear only the current ruler, used before a redraw.
    set tag "ruler$_RULER_INT(count)"
    lay_line -tag $tag -clear
    lay_text -tag $tag -clear
  } else {
    # toast all rulers.
    for {set i 1} {$i <= $_RULER_INT(count)} {incr i} {
	set tag "ruler$i"
	lay_line -tag $tag -clear
	lay_text -tag $tag -clear
    }
    # If currently drawing a ruler, toast it.  This happens when ruler_clear
    # called from popup on Button-3 in ruler mode.
    set _RULER_INT(state) 0
    set _RULER_INT(count) 0  ;# Rulers are all gone.
  }
}

proc _ruler_get_point {{shift ""}} -desc {
  Return the point the ruler should snap to.
} {
  global RULER _RULER_INT
  switch $RULER(grid_mode) {
  "exact" { return [layt_point exact] }
  "user" { return [layt_point user] }
  "alternate" {
      setl {x y} [layt_point exact]
      set x [round_list_scale $x $RULER(alternate_grid)]
      set y [round_list_scale $y $RULER(alternate_grid)]
  }
  "edge" {
      setl {px py} [layt_point exact]
      set dirs "nsew"
      if { $shift == ""} {
	# look for edge in horiz of vert direction only.
	set dx [expr $px - $_RULER_INT(x)]
	set dy [expr $py - $_RULER_INT(y)]
	if {abs($dx) > abs($dy)} {
	  set dirs "ew"
	} else {
	  set dirs "ns"
	}
      }
      setl {x y} [closest_edge $px $py $dirs]
      if { $dirs == "ew" } {
	# Only x gets to move.
	setl {x y} [list $x $_RULER_INT(y)]
      } elseif { $dirs == "ns" } {
	setl {x y} [list $_RULER_INT(x) $y]
      }
      if { $x == "" } {
	  setl {x y} [$_RULER_INT(x) $_RULER_INT(y)]
      }
  }
  }
  # Not likely that this could be off grid, but uusnap anyway.
  return [list [uusnap $x] [uusnap $y]]
}


proc _ruler_start {} {
  global _RULER_INT

  # Shift tells ruler_get_point to look for the nearest edge in any direction.
  setl {_RULER_INT(x) _RULER_INT(y)} [_ruler_get_point shift]
  ruler_draw $_RULER_INT(x) $_RULER_INT(y) $_RULER_INT(x) $_RULER_INT(y)
  set _RULER_INT(did_ruler) 1
}


proc _ruler_drag {{shift ""}} -desc {
  redraw the ruler based on cursor position
} {
    global _RULER_INT

    # User hasnt clicked button-1 yet.
    if { $_RULER_INT(state) == 0 } { return }

    pan_auto _ruler_drag
      
    setl {x2 y2} [_ruler_get_point $shift]
    if {$x2 == "" || $y2 == ""} {
      # off screen
      return
    }

    # draw the happy ruler
    ruler_clear current
    ruler_draw $_RULER_INT(x) $_RULER_INT(y) $x2 $y2 $shift
}


proc _ruler_end {shift} -desc {
    called to finish ruler
} {
    global _RULER_INT

    setl {x y} [_ruler_get_point $shift]
    ruler_clear current
    ruler_draw $_RULER_INT(x) $_RULER_INT(y) $x $y $shift
}


proc ruler_draw {x1 y1 x2 y2 {shift ""}} -desc {
  draw a ruler between the given coords
} {
    global RULER _RULER_INT

    set dx [expr $x2 - $x1]
    set dy [expr $y2 - $y1]

    if {$shift == ""} {
      # align to horiz of vert, whichever is larger
      if {abs($dx) > abs($dy)} {
	# horizontal
	set y2 $y1
      } else {
	# vertical
	set x2 $x1
      }
      set dx [expr $x2 - $x1]
      set dy [expr $y2 - $y1]
    }

    if { $RULER(coord_mode) == "absolute" } {
	setl {rx1 ry1 rx2 ry2} [list $x1 $y1 $x2 $y2]
    } else {
	setl {rx1 ry1 rx2 ry2} [list 0 0 $dx $dy]
    }

    # Report ruler length
    box_msg_update "ruler len = [format "%.3g" [expr sqrt($dx*$dx+$dy*$dy)]]"

    if { [approx $dx == 0] } {
	set text1 [format "%.3g" $ry1]
	set text2 [format "%.3g" $ry2]
	set pos w
    } elseif { [approx $dy == 0] } {
	set text1 [format "%.3g" $rx1]
	set text2 [format "%.3g" $rx2]
	set pos n
    } else {
	# All angle
	if { $rx1 == 0 && $ry1 == 0 } {
	    set text1 "0"
	} else {
	    set text1 [format "%.3g,%.3g" $rx1 $ry1]
	}
	set text2 [format "%.3g,%.3g" $rx2 $ry2]
	if { abs($dx) > abs($dy) } {
	    set pos n
	} else {
	    set pos w
	}
    }

    lay_line -tag $_RULER_INT(tag) $x1 $y1 $x2 $y2
    lay_text -tag $_RULER_INT(tag) -align $pos -size $RULER(font_size) \
	$x1 $y1 $text1
    lay_text -tag $_RULER_INT(tag) -align $pos -size $RULER(font_size) \
	$x2 $y2 $text2

    # Now the tick marks.  Compute tick mark len.
    setl {fx1 fy1 fx2 fy2} [dbt_frame]
    # How many microns are showing in the window
    set frame_microns [expr [min [expr $fx2 - $fx1] [expr $fy2 - $fy1]]]
    # Tick len is 1% of frame size.
    set tlen [expr $frame_microns * 0.01]

    if { $dx == 0 && $dy == 0 } {
	# make a little X at the origin
	# This is only used for zero length ruler, ie, drag hasnt started yet.
	lay_line -tag $_RULER_INT(tag) [expr $x1 - $tlen] [expr $y1 - $tlen] \
	    [expr $x1 + $tlen] [expr $y1 + $tlen]
	lay_line -tag $_RULER_INT(tag) [expr $x1 - $tlen] [expr $y1 + $tlen] \
	    [expr $x1 + $tlen] [expr $y1 - $tlen]
    } else {
	# Note atan2 cant take (x,y) == (0,0) argument, but we dont do that.
	# Angle of ruler.
	set angle [expr atan2($dy,$dx)]
	set pi_over_2 [expr 3.1415926536 / 2.0]
	# Tick mark end-points.
	set tx [expr $tlen * cos($angle + $pi_over_2)]
	set ty [expr $tlen * sin($angle + $pi_over_2)]
	lay_line -tag $_RULER_INT(tag) \
		[expr $x1 - $tx] [expr $y1 - $ty] \
		[expr $x1 + $tx] [expr $y1 + $ty]
	lay_line -tag $_RULER_INT(tag) \
		[expr $x2 - $tx] [expr $y2 - $ty] \
		[expr $x2 + $tx] [expr $y2 + $ty]

	# Can we stick in some intermediate tick marks?
	# Dont bother trying to put text on the tick if it is an absolute
	# coordinate system and the ruler is not manhattan.  Too confusing.
	if { $RULER(coord_mode) != "absolute" || $dx == 0 || $dy == 0} {
	    setl {px py} [dbt_frame_pixels]
	    set frame_pixels [min $px $py]
	    set rulerlen [expr sqrt($dx * $dx + $dy * $dy)]
	    set pix_per_u [expr $frame_pixels / $frame_microns]

	    # Compute tick mark interval.
	    # Make the interval about 50 pixels apart.
	    for {set interval 0.1} {1} {set interval [expr $interval*10]} {
		if { $interval * $pix_per_u > 50 } {
		    break
		}
		if { $interval*2.0 * $pix_per_u > 50 } {
		    set interval [expr $interval*2]
		    break
		}
		if { $interval*5.0 * $pix_per_u > 50 } {
		    set interval [expr $interval*5]
		    break
		}
		if { $interval > 1e15} {
		    # Give up.
		    return
		}
	    }
	    if { $dx < 0 || $dy < 0 } {
		set dir -1
	    } else {
		set dir 1
	    }
	    # The .04 is how close the final tick can come to the end tick.
	    for {set i $interval} {$i < ($rulerlen - $interval*0.04)} \
			{set i [expr $i + $interval]} {
		set tickx [expr $x1 + $i * cos($angle)]
		set ticky [expr $y1 + $i * sin($angle)]
		lay_line -tag $_RULER_INT(tag) \
		    [expr $tickx - $tx] [expr $ticky - $ty] \
		    [expr $tickx + $tx] [expr $ticky + $ty]
		if { $RULER(coord_mode) == "absolute" } {
		    # Note that one of dx or dy is 0.
		    if { $dx == 0 } {
			set coord [expr $i * $dir + $y1]
		    } else {
			set coord [expr $i * $dir + $x1]
		    }
		} else {
		    set coord [expr $i * $dir]
		}
		# We dont want the internal tick mark too close to the endpoint,
		# so subtract interval*.3
		if { $i < $rulerlen - $interval*0.3} {
		  lay_text -tag $_RULER_INT(tag) -align $pos \
		    -size $RULER(font_size) \
		    $tickx $ticky [format "%.3g" $coord]
		}
	    }
	}
    }
}


proc ruler_menu {} -desc {
    View ruler menu.
} {
    global RULER

    set prop_list ""

    lappend prop_list \
      "{Ruler Snap To:} RULER(grid_mode) \
      -radio {{Exact Point} {User Grid} {Nearest Edge} {Alternate Ruler Grid}} \
      -values {exact user edge alternate} \
      -help {Ruler will snap to the nearest specified grid or edge}"
    
    lappend prop_list \
        "{Alternate Ruler Grid} RULER(alternate_grid) \
	-number 0 -incr [res] -snap 0.1 -validate \
	-help {Alternate grid, in microns.  Only used if Ruler Snap To: Alternate Grid}"

    lappend prop_list \
      "{Ruler Coordinates:} RULER(coord_mode) \
      -radio {{absolute} {relative}} \
      -help {If set to 'relative', ruler is numbered starting at 0.
      If set to 'absolute', ruler is numbered with absolute coordinates}"

    lappend prop_list [list \
      {Ruler Font Size:} RULER(font_size) \
      -radio {small medium large {extra large}} \
      -values "0 1 2 3" \
      -help {Size of text displayed by ruler. \
      This option does not affect rulers that have already been drawn.}]

    lappend prop_list \
       [list {Clear Ruler Now} {} -button "ruler_clear menu" \
       -help {Clears any visible ruler when pressed}]
    
    prop_menu2 -title "Ruler Setup" $prop_list
}



proc _ruler_vertex {{shift ""}} -desc {
    function hooked to Button-1
} {
    global _RULER_INT
    if { $_RULER_INT(state) == 0 } {
	_ruler_start
	set _RULER_INT(state) 1
    } else {
	_ruler_end $shift
	set _RULER_INT(state) 0
	mode_pop
    }
}
