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

set RCSVERSION(polygon.tcl) { $Revision: 1.25 $ }

# interface to draw/edit polygons (arbitrary angle geometries)
# Also wire paths interface -- BROKEN

# Problems:
# Can close a poly with a 45 (should be 90 or greater)


global POLY
# default wire width
set POLY(width) 1
set POLY(wire_flags) ""

# Number of sides on a circle.  The edit-properties code needs to
# know this so it can recognize a circle.
set POLY(sides_per_circle) 90

# type, either 45 or unconstrained
set POLY(type) 45

# needs to be defined
set POLY(layer) ""

proc polygon_mode_enter {wire} -desc {
  enter polygon mode (for creating a polygon)
} -doc {
  if arg = 1 will add wire path, else will add polygon.
} {  
  global POLY

  set POLY(wire) $wire  
  mode_push polygon
}


proc _polygon_mode_define {} -desc {
  create a polygon
} {
    mode_def polygon _polygon_gate_keeper \
	"BUT-1 starts BUT-2 ends BUT-3 selects layer under cursor"

    mode_bind -cmd 0 polygon <Any-Button-1> _poly_start \
	-desc "Start drawing a polygon"
    mode_bind -cmd 0 polygon <Any-Button-2> _poly_end \
	-desc "End the current polygon"
    mode_bind -cmd 0 polygon <Any-Button-3> _poly_choose_layer \
	-desc "Select the layer under the cursor to draw the polygon in"

    # flush ends
#    mode_bind -cmd 0 polygon f {global POLY; set POLY(wire_flags) ""}

    # rounded ends
#    mode_bind -cmd 0 polygon r {global POLY; set POLY(wire_flags) "-rounded"}
}


proc _poly_mode_msg {} -desc {
  post polygon mode message including current layer
} {
  global POLY

  mode_msg \
      "polygon mode. BUT-1 starts in $POLY(layer) BUT-2 ends BUT-3 selects layer under cursor"
}


proc _polygon_gate_keeper {event} -desc {
  called whenever polygon mode is entered/exited
} {
  global TOOL_BAR POLY mode_abort max_win PAL


  if {$event == "PUSH_TO"} {

    # initialize this polygon
    set POLY(coords) ""
    set POLY(exists) 0
    set POLY(close) ""
    set POLY(layer) ""

    # TODO: need to implement drawing for non-45s
    set POLY(type) 45

    # define button2 and button3 command on palette
    set PAL(button2) "_poly_choose_layer polygon"
    set PAL(button3) "_poly_choose_layer polygon"

    _poly_mode_msg

  } elseif {$event == "POP_FROM"} {
    if { $mode_abort } {
      undo_to_delim
      undo_flush_redo

      msg "Aborting polygon!\n"
    } else {

      # select this polygon
      # If user typed control-C, there will be no polygon to select.
      set index [_find_polygon $POLY(layer) $POLY(coords)]
      if {$index != ""} {
	sel_clear
	sel_polygons $index
	setl {layer bbox coords} [sel_what polygons]
	# Dont leave a box lying around: stick it in the center of the polygon.
	setl {cx cy} [eval center_coords $bbox]
	layt_box exact $cx $cy $cx $cy
      }
    }

    # clear away annotations
    _poly_clear_annotations

    catch {unset PAL(button2)}
    catch {unset PAL(button3)}

    # delimit command
    i_cmd_between
  }
}

proc _poly_find_layer {} -desc {
  return valid polygon layer found under cursor, or ""
} {
  setl {x y} [layt_point exact]
  # Choose last (highest) layer
  set touching [dbt_touchingtypes $x $y selectable]
  set layer [lindex $touching end]
  return $layer
}


proc _poly_choose_layer {{layer ""}} -desc {
  set layer to first valid wiring layer under the cursor.
} -doc {
    If layer is specified, we were called from palette: set layer
    to that specified.  Otherwise, it was mouse button-3, set layer
    to that under the cursor.
} {

  global POLY max_win
  
  if {$layer == ""} {
    set layer [_poly_find_layer]
  }

  if {$layer == ""} {
    # no layer under cursor
    return ""
  }

  tool_bar_set_layer $layer

  # found visible layer under cursor
  set POLY(layer) $layer

  # Redraw polygon with new layer.
  if { $POLY(wire) == 1 } {
    if {$POLY(exists) != ""} {
      db_wire_path -delete 0
      eval db_wire_path $POLY(wire_flags) $POLY(layer) $POLY(width) $POLY(coords) 
    }
  } else {
    if {[mode_current] == "polygon_edit"} {
      # show as closed
      set POLY(close) [lindex $POLY(coords) 0]
      _poly_display [list $POLY(close)]
    } else {
      _poly_display
    }
  }

  if {[mode_current] == "polygon"} {
    # change mode display to show new layer
    _poly_mode_msg
  }
  return $layer
}

proc _poly_init_layer {} -desc {
    Sets POLY(layer)
} {
    global TOOL_BAR POLY
    if { $TOOL_BAR(layer) == "auto" } {
	# choose a starting layer (can be modified with button-2/3)
	set POLY(layer) [_poly_find_layer]

	if {$POLY(layer) == ""} {
	  # first look for poly or metal1 to use
	  foreach layer "p1 poly polysilicon metal metal1 m1" {
	    set POLY(layer) [dbt_long_name $layer]
	    if {$POLY(layer) != ""} {
	      # got one
	      break
	    }
	  }
	}

	if {$POLY(layer) == ""} {
	  # choose first visible layer as starting layer
	  set POLY(layer) [lindex [dbt_visible_layers] 0]
	}

	if {$POLY(layer) == ""} {
	  max_error "polygon error: Cant find a layer to use!"
	  return
	}
    } else {
	set POLY(layer) $TOOL_BAR(layer)
    }
}


proc _poly_start {} -desc {
  drag new polygon vertex
} {
    global POLY

    if {$POLY(coords) == ""} {
      set p [layt_point user]
      set POLY(coords) [list $p]
      set POLY(last) ""
      sel_clear
    }

    _poly_init_layer


    # show the user what we got
    _poly_display

    mode_push polygon_drag
}


proc _poly_end {} -desc {
  end polygon
} {

  mode_pop
}


proc _poly_clear_annotations {} -desc {
  clear away any poly annotations
} {

  # toast any previous annotations
  lay_line -tag polygon -clear
  lay_dot -tag polygon -clear
}


proc _poly_display {{tmp ""}} -desc {
  show the user the polygon vertices and edges
} {

  global POLY

  # toast any previous annotations
  _poly_clear_annotations

  set last ""

  set coords [concat $POLY(coords) $tmp]

  foreach coord $coords {
    eval lay_dot -tag polygon -diameter 5 $coord

    if {$last != ""} {
      eval lay_line -tag polygon $last $coord
    }

    set last $coord
  }

  if {$POLY(exists)} {
    db_polygon -delete 0
    set POLY(exists) 0
  }

  if {$POLY(close) != "" && [_poly_ok]} {
    # draw it for the happy user if you can close it properly
    # Actually want nearby for rounding, not nearby visually.
    if {[eval nearby [lindex $POLY(coords) 0] $POLY(close) [expr [res]/2.0]]} {
      # don't add closing point
      set coords $POLY(coords)
    } else {
      set coords [concat $POLY(coords) $POLY(close)]
    }

    regsub -all {\{|\}} $coords "" coords
    eval db_polygon $POLY(layer) $coords
    set POLY(exists) 1
  }
}


proc _poly_ok {} -desc {
  returns 1 if polygon is well formed
} {
  global POLY

  set len [expr [llength $POLY(coords)] - 1]

  if {$len < 2} {
    # too wittle
    return 0
  }

  # compute final line segment minus a bit
  setl {p1x p1y} [lindex $POLY(coords) $len]
  setl {p2x p2y} $POLY(close)
  # compute new line: p2 to p3
  set p3x [expr $p2x - ($p2x - $p1x) * .001]
  set p3y [expr $p2y - ($p2y - $p1y) * .001]
  set line2 "$p1x $p1y $p3x $p3y"

  # check closing line segment
  for {set i 1} {$i < $len} {incr i} {
    set line1 \
	"[lindex $POLY(coords) [expr $i - 1]] [lindex $POLY(coords) $i]"
    if {[eval intersect_lines $line1 $line2]} {
      # self intersecting
      return 0
    }
  }

  return 1

  # also need to check one back
  incr len -1

  setl {p1x p1y} [lindex $POLY(coords) $len]
  setl {p2x p2y} $POLY(close)
  # compute new line: p2 to p3
  set p3x [expr $p1x - ($p1x - $p2x) * .001]
  set p3y [expr $p1y - ($p1y - $p2y) * .001]
  set line2 "$p1x $p1y $p3x $p3y"

  # check closing line segment
  for {set i 1} {$i < $len} {incr i} {
    set line1 \
	"[lindex $POLY(coords) [expr $i - 1]] [lindex $POLY(coords) $i]"
    if {[eval intersect_lines $line1 $line2]} {
      # self intersecting
      return 0
    }
  }

  return 1
}


proc _poly_compute_last {point} -desc {
  computes the last point of the polygon permitted to ensure 45s
} {
  global POLY

  # extend this last point until it meets the extension of
  # the first two points backwards


}


proc _polygon_drag_mode_define {} -desc {
  polygon_drag mode is active when adding vertices
} {
  mode_def polygon_drag pan_gate_keeper \
      "BUT-1 fixes vertex and starts new BUT-2 ends BUT-3 removes last vertex"

  mode_bind -cmd 0 polygon_drag <Any-Motion> _poly_drag
  mode_bind -cmd 0 polygon_drag <Any-Button-1> _poly_drag_fix
  mode_bind -cmd 0 polygon_drag <Any-Button-2> _poly_drag_end
  mode_bind -cmd 0 polygon_drag <Any-Button-3> _poly_remove_last
  mode_bind -cmd 0 polygon_drag <u> _poly_remove_last
  mode_bind -cmd 0 polygon_drag <Delete> _poly_remove_last
}


proc _poly_drag {} -desc {
  drag new polygon vertex
} {
  global POLY

  pan_auto _poly_drag

  set new [layt_point user]

  if {$POLY(wire) == 1} {
    if {$POLY(exists) != ""} {
      db_wire_path -delete 0
    }
    eval db_wire_path $POLY(wire_flags) $POLY(layer) $POLY(width) $POLY(coords) $new
    set POLY(exists) 1

  } else {
    # polygon mode

    set len [expr [llength $POLY(coords)] - 1]

    if {$POLY(type) == "45" && $len >= 0} {
      # restrict user to snap to 45 and no acute angles
      if {$len >= 1} {
	# compute angle of previous segment
	setl {xx yy} [lindex $POLY(coords) $len]
	setl {x y} [lindex $POLY(coords) [expr $len - 1]]

	set dx [expr $x - $xx]
	set dy [expr $y - $yy]

	set prev_angle [expr round(atan2($dy,$dx) * 4.0/3.14159) * 45.0]
      } else {
	# no previous angle
	set prev_angle ""
      }

      setl {xx yy} [lindex $POLY(coords) $len]
      setl {x y} $new

      if {$xx != $x || $yy != $y} {
	set dx [expr $x - $xx]
	set dy [expr $y - $yy]

	# round angle of line to 45 degrees
	set angle [expr round(atan2($dy,$dx) * 4.0/3.14159) * 45.0]

	if {$prev_angle != ""} {
	  # don't allow acute angles
	  if {[expr abs($angle - $prev_angle)] < 60 || \
		  [expr abs($angle - $prev_angle)] > 300} {
	    # acute, punt
	    return
	  }
	}

	# recompute endpoints
	set r [expr sqrt($dy * $dy + $dx * $dx)]
	setl {x y} [uusnap -user \
	  [expr $xx + $r * cos($angle * 3.14159/180)] \
	  [expr $yy + $r * sin($angle * 3.14159/180)] ]

	set new "$x $y"
      }
    }

    # see if this would make a self intersecting polygon
    if {$len > 0} {
      # check current line segment
      set line2 "[lindex $POLY(coords) $len] $new"
      for {set i 1} {$i < $len} {incr i} {
	set line1 \
	    "[lindex $POLY(coords) [expr $i - 1]] [lindex $POLY(coords) $i]"
	if {[eval intersect_lines $line1 $line2]} {
	  # self intersecting
	  return
	}
      }
    }

    # figure out how to close on a 45/90
    if {$len > 0} {
      # get the starting line
      setl {p1 p2} $POLY(coords)
      setl {p1x p1y} $p1
      setl {p2x p2y} $p2
      # compute new line: p2 to p3
      set p3x [expr $p1x + ($p1x - $p2x) * 1000]
      set p3y [expr $p1y + ($p1y - $p2y) * 1000]

      # extend current line
      setl {p2xx p2yy} [lindex $POLY(coords) $len]      
      setl {p1xx p1yy} $new
      # compute new line: p2 to p3
      set p3xx [expr $p1xx + ($p1xx - $p2xx) * 1000]
      set p3yy [expr $p1yy + ($p1yy - $p2yy) * 1000]
      
      global _INTERSECT_
# puts "intersect_lines $p1x $p1y $p3x $p3y $p1xx $p1yy $p3xx $p3yy"
      if {[intersect_lines $p1x $p1y $p3x $p3y $p1xx $p1yy $p3xx $p3yy]} {
	# can close
	set POLY(close) $_INTERSECT_
      } else {
	set POLY(close) ""

	# check for special case of parallel lines
	if {$p1x == $p2x} {
	  # special case
	  set m inf

	} else {
	  set m [expr ($p2y - $p1y) / ($p2x - $p1x)]
	}

	if {$p2xx == $p1xx} {
	  # special case
	  set mm inf

	} else {
	  set mm [expr ($p2yy - $p1yy) / ($p2xx - $p1xx)]
	}

	if {$mm == $m || \
		($mm != "inf" && $m != "inf" && [expr abs($mm - $m)] < 0.001)} {
	  # parallel lines
	  # now need to intersect start point with line from 
	  # last point and current projected out.  compute perpendicular
	  # to start line
	  if {$m == "inf"} {
	    # special case
	    set pp1x [expr $p1x + 1.0]
	    set pp1y $p1y
	  } else {
	    set pp1x [expr $p1x - $m]
	    set pp1y [expr $p1y + 1]
	  }
	  # extend this line
	  set pp3x [expr $pp1x + ($pp1x - $p1x) * 1000]
	  set pp3y [expr $pp1y + ($pp1y - $p1y) * 1000]
	  set pp2x [expr $pp1x - ($pp1x - $p1x) * 1000]
	  set pp2y [expr $pp1y - ($pp1y - $p1y) * 1000]

#puts "intersect_lines $pp2x $pp2y $pp3x $pp3y $p2xx $p2yy $p3xx $p3yy"

	  if {[intersect_lines $pp2x $pp2y $pp3x $pp3y $p2xx $p2yy $p3xx $p3yy]} {
	    set POLY(close) $_INTERSECT_
	  }
	}
      }
    }

    set POLY(last) $new
    _poly_display [list $new]
  }
}


proc _poly_drag_fix {} -desc {
  fix the vertex and begin another
} {
  global POLY

  set len [expr [llength $POLY(coords)] - 1]

  if {$POLY(last) != "" && [lindex $POLY(coords) $len] != $POLY(last)} {
    lappend POLY(coords) $POLY(last)
    set POLY(last) ""
  }
}


proc _poly_drag_end {} -desc {
  end drag new polygon vertex
} {

  global POLY

  set len [expr [llength $POLY(coords)] - 1]

  # check closing line segment
#  set line2 "[lindex $POLY(coords) $len] [lindex $POLY(coords) 0]"
#  for {set i 2} {$i <= $len} {incr i} {
#    set line1 \
	"[lindex $POLY(coords) [expr $i - 1]] [lindex $POLY(coords) $i]"
#    if {[eval intersect_lines $line1 $line2]} {
      # self intersecting
#      puts "Can't finish polygon, would be self-intersecting.  Move cursor and try again."
#      return
#    }
#  }

  if {$POLY(close) == ""} {
    puts "Can't finish polygon.  Move cursor and try again."
    return
  }

  # add this last coord if not the first
  # Actually want nearby for rounding, not nearby visually.
  if {![eval nearby [lindex $POLY(coords) 0] $POLY(close) [expr [res]/2.0]]} {
    lappend POLY(coords) $POLY(close)
  }

  mode_pop

  if {[mode_current] == "polygon"} {
    _poly_end
  } elseif {[mode_current] == "polygon_edit"} {
    # show as closed
    set POLY(close) [lindex $POLY(coords) 0]
    _poly_display [list $POLY(close)]
    _poly_edit_mode_msg
  }
}


proc _poly_remove_last {} -desc {
  toast last vertex
} {
  global POLY

  if {$POLY(coords) != ""} {  
    # remove last coord
    set len [llength $POLY(coords)]
    setl {x y} [lindex $POLY(coords) [expr $len - 1]]
    set POLY(coords) [lrange $POLY(coords) 0 [expr $len - 2]]

    layt_point -warp user $x $y
  }

  _poly_drag
}


proc intersect_lines {x1 y1 x2 y2 xx1 yy1 xx2 yy2} -desc {
  if lines intersect, return 1
} {

  global _INTERSECT_

  set _INTERSECT_ ""

  if {$x2 == $x1} {
    # special case
    set m inf

  } else {
    set m [expr ($y2 - $y1) / ($x2 - $x1)]
    set b [expr $y1 - $m * $x1]
  }

  if {$xx2 == $xx1} {
    # special case
    set mm inf

  } else {
    set mm [expr ($yy2 - $yy1) / ($xx2 - $xx1)]
    set bb [expr $yy1 - $mm * $xx1]
  }

  if {$mm == $m || \
	  ($mm != "inf" && $m != "inf" && [expr abs($mm - $m)] < 0.001)} {
    # parallel lines
    if {$x1 != $xx1} {
      return 0
    }

    if {($y1 > $yy1 && $y1 < $yy2)} {
      set _INTERSECT_ [list $x1 $y1]
    } elseif {($y2 > $yy1 && $y2 < $yy2)} {
      set _INTERSECT_ [list $x1 $y2]
    }
    return [expr ($y1 > $yy1 && $y1 < $yy2) || ($y2 > $yy1 && $y2 < $yy2)]

  } elseif {$m == "inf"} {
    set y [expr $mm * $x1 + $bb]
    set _INTERSECT_ [list $x1 $y]

    if {$xx2 > $xx1} {
      if {$y2 > $y1} {
	return [expr $x1 >= $xx1 && $x1 <= $xx2 && $y >= $y1 && $y <= $y2]
      } else {
	return [expr $x1 >= $xx1 && $x1 <= $xx2 && $y >= $y2 && $y <= $y1]
      }
    } else {
      if {$y2 > $y1} {
	return [expr $x1 >= $xx2 && $x1 <= $xx1 && $y >= $y1 && $y <= $y2]
      } else {
	return [expr $x1 >= $xx2 && $x1 <= $xx1 && $y >= $y2 && $y <= $y1]
      }
    }

  } elseif {$mm == "inf"} {
    set y [expr $m * $xx1 + $b]
    set _INTERSECT_ [list $xx1 $y]

    if {$x2 > $x1} {
      if {$yy2 > $yy1} {
	return [expr $xx1 >= $x1 && $xx1 <= $x2 && $y >= $yy1 && $y <= $yy2]
      } else {
	return [expr $xx1 >= $x1 && $xx1 <= $x2 && $y >= $yy2 && $y <= $yy1]
      }
    } else {
      if {$yy2 > $yy1} {
	return [expr $xx1 >= $x2 && $xx1 <= $x1 && $y >= $yy1 && $y <= $yy2]
      } else {
	return [expr $xx1 >= $x2 && $xx1 <= $x1 && $y >= $yy2 && $y <= $yy1]
      }
    }

  } else {
    set x [expr ($b - $bb) / ($mm - $m)]
    set _INTERSECT_ [list $x [expr $m * $x + $b]]

# puts "$m $b, $mm $bb, $x --> $x1, $x2"

    if {$x2 > $x1} {
      if {$xx2 > $xx1} {
	return [expr $x >= $x1 && $x <= $x2 && $x >= $xx1 && $x <= $xx2]
      } else {
	return [expr $x >= $x1 && $x <= $x2 && $x >= $xx2 && $x <= $xx1]
      }
    } else {
      if {$xx2 > $xx1} {
	return [expr $x >= $x2 && $x <= $x1 && $x >= $xx1 && $x <= $xx2]
      } else {
	return [expr $x >= $x2 && $x <= $x1 && $x >= $xx2 && $x <= $xx1]
      }
    }
  }
}

proc _poly_is_circle {} -desc {
    is the selected polygon a circle?
} -doc {
  A circle has a square bbox and a fixed number of coordinates,
  currently 182 coordinates for a circle or 364 for a donut.
  It is unlikely that a random polygon would have these attributes.
} {
  global POLY

  setl {layer bbox coords} [sel_what polygons]
  struct rect r $bbox
  set n_circle_coords [expr 2 * $POLY(sides_per_circle) + 2]
  set dx [expr abs(${r.x2} - ${r.x1})]
  set dy [expr abs(${r.y2} - ${r.y1})]
  set nc [llength ${coords}]
  if {[approx $dx == $dy] && \
	( $nc == $n_circle_coords || $nc == $n_circle_coords * 2 ) } {
      return 1
  }
  return 0
}

proc polygon_edit_props {} {
  if {[_poly_is_circle]} { _circle_menu; return }
  max_error "polygon error: Cant edit polygon properties yet"
}


proc polygon_edit {} -desc {
  edit the selected polygon
} {
  global POLY

  set POLY(wire) 0

  setl {layer bbox coords} [sel_what polygons]

  if {[_poly_is_circle]} { circle_edit; return }


  if {$coords == ""} {
    # no polygon selected, is there a box
    setl {layer x1 y1 x2 y2} [sel_what paint]
    if {$y2 == ""} {
      puts "Aborting, must select something first."
      return
    }

    set coords "$x1 $y1 $x1 $y2 $x2 $y2 $x2 $y1"

    # remove the paint
    layt_box exact $x1 $y1 $x2 $y2
    paint_erase $layer

    # We are going to interactively edit a pre-existing rectangle.
    # We will start by snapping its location to the user grid.
    layt_box user $x1 $y1 $x1 $y1
    sel_clear

  } else {
    # use the polygon
    
    # move to top of polygon list
    set index [_find_polygon $layer $coords]
    db_polygon -delete $index
    set POLY(exists) 0

    sel_clear
  }

  set POLY(layer) $layer

  regsub -all {([-]?[0-9.]+[ \t]+[-]?[0-9.]+)} $coords {{&}} POLY(coords)

  # show as closed
  set POLY(close) [lindex $POLY(coords) 0]

  _poly_display [list $POLY(close)]

  mode_push polygon_edit
}


proc _poly_edit_end {} -desc {
  end poly edit 
} {
  
  mode_pop
}


proc _polygon_edit_mode_define {} -desc {
  polygon_edit mode is active editing a polygon
} {
  mode_def polygon_edit _polygon_edit_gate_keeper ""

  mode_bind -cmd 0 polygon_edit <Any-Button-1> _poly_edit_get_vertex
  mode_bind -cmd 0 polygon_edit <Any-B1-Motion> _poly_edit_drag_vertex

  mode_bind -cmd 0 polygon_edit <Any-Button-2> _poly_edit_end
  mode_bind -cmd 0 polygon_edit <Button-3> _poly_edit_add_vertex
  mode_bind -cmd 0 polygon_edit <Shift-Button-3> _poly_edit_remove_vertex

  mode_bind -cmd 0 polygon_edit <Any-m> _poly_toggle_mode
}


proc _polygon_edit_gate_keeper {event} -desc {
  called whenever polygon edit mode is entered/exited
} {
  global POLY mode_abort max_win PAL

  if {$event == "PUSH_TO"} {
    # define button2 and button3 command on palette
    set PAL(button2) "_poly_choose_layer polygon_edit"
    set PAL(button3) "_poly_choose_layer polygon_edit"

    _poly_edit_mode_msg

  } elseif {$event == "POP_FROM"} {
    if { $mode_abort } {
      undo_to_delim
      undo_flush_redo
      msg "Aborting edit polygon!\n"
    } 

    # select this polygon
    set index [_find_polygon $POLY(layer) $POLY(coords)]
    if {$index != ""} {
      sel_polygons $index
    }

    # clear away annotations
    _poly_clear_annotations

    catch {unset PAL(button2)}
    catch {unset PAL(button3)}

    # delimit command
    i_cmd_between
  }
}


proc _poly_edit_mode_msg {} {

  global POLY
  
  if {$POLY(type) == "45"} {
    mode_msg "polygon edit mode. BUT-1 starts editing from nearby vertex BUT-2 ends, BUT-2/3 over palette changes layer, \"m\" toggles between 45 and all angle"
  } else {
    mode_msg "polygon edit mode. BUT-1 moves nearby vertex BUT-2 ends (SHIFT)-BUT-3 adds (deletes) closest, BUT-2/3 over palette changes layer, \"m\" toggles between 45 and all angle"
  }
}


proc _poly_toggle_mode {} -desc {
  toggle between 45 only and any angle
} {
  global POLY

  if {$POLY(type) == "45"} {
    set POLY(type) ""
    set message "Toggled to all angle mode"
		
  } else {
    set POLY(type) 45
    set message "Toggled to 45 only mode"
  }

  _poly_edit_mode_msg 
  tk_dialog .dialog "Toggle Polygon Mode" $message {} 0 OK
}


proc _poly_edit_get_vertex {} -desc {
  start editing the vertex nearest cursor
} {
  global POLY

  set POLY(index) [_poly_get_closest_vertex]

  if {$POLY(type) == "45"} {
    # need to constrain to 45/90
    # order coords so this vertex is last
    set POLY(coords) \
	[concat [lrange $POLY(coords) [expr $POLY(index) + 1] end] \
	     [lrange $POLY(coords) 0 [expr $POLY(index) - 1]]]

    # go back into creation mode from here
    mode_push polygon_drag    
  }
}


proc _poly_get_closest_vertex {} -desc {
  find vertex nearest cursor
} {
  global POLY

  setl {x y} [layt_point user]

  set i 0
  set min_dist 1.0e20
  set index ""

  foreach coord $POLY(coords) { 
    setl {xx yy} $coord

    set dist [expr ($xx - $x)*($xx - $x) + ($yy - $y)*($yy - $y)]
    if {$dist < $min_dist} {
      # this one is closer
      set index $i
      set min_dist $dist
    }

    incr i
  }

  return $index
}


proc _poly_edit_drag_vertex {} -desc {
  move vertex nearest cursor
} {
  global POLY

  if {$POLY(type) != "45"} {
    # let the user have a field day
    set POLY(coords) \
	[lreplace $POLY(coords) $POLY(index) $POLY(index) [layt_point user]]
  } else {
    # already accounted for
    return
  }

  # show as closed
  set POLY(close) [lindex $POLY(coords) 0]
  _poly_display [list $POLY(close)]
}


proc _poly_edit_remove_vertex {} -desc {
  find vertex nearest cursor and remove it
} {
  global POLY

  if {$POLY(type) == "45"} {
    return
  }

  if {[llength $POLY(coords)] < 4} {
    puts "Aborting, can't remove any more vertices from this polygon"
    return 
  }

  set index [_poly_get_closest_vertex]
  set POLY(coords) [lreplace $POLY(coords) $index $index]
  _poly_display
}


proc _poly_edit_add_vertex {} -desc {
  make a new vertex at cursor
} {
  global POLY

  if {$POLY(type) == "45"} {
    return
  }

  set index [_poly_get_closest_vertex]
  set closest [lindex $POLY(coords) $index]
  set POLY(coords) [lreplace $POLY(coords) $index $index \
	$closest [layt_point user]]
  _poly_display
}

proc _find_wirepath {this_layer this_coords this_width} -desc {
  returns the index for the wirepath on the given layer with the given coords
} {

  if {[llength [lindex $this_coords 0]] > 1} {
    # undo list format; remove extraneous curly brackets
    regsub -all {\{|\}} $this_coords "" this_coords
  }

  set i 0
  foreach wp [split [db_wire_path] \n] {
    struct max_wirepath w $wp
    set n1 [dbt_short_name ${w.layer}]
    set n2 [dbt_short_name $this_layer]
    if {$n1==$n2 && ${w.coords} == $this_coords && ${w.width} == $this_width} {
      # got it
      return $i
    }
    incr i
  }
  
  return ""
}


proc _find_polygon {this_layer this_coords} -desc {
  returns the index for the polygon on the given layer with the given coords
} {

  if {[llength [lindex $this_coords 0]] > 1} {
    # undo list format; remove extraneous curly brackets
    regsub -all {\{|\}} $this_coords "" this_coords
  }

  set i 0
  foreach polygon [split [db_polygon] \n] {
    struct max_polygon p $polygon
    set n1 [dbt_short_name ${p.layer}]
    set n2 [dbt_short_name $this_layer]
    if {$n1 == $n2 && ${p.coords} == $this_coords} {
      # got it
      return $i
    }
    incr i
  }
  
  return ""
}


proc _make_pie_wedge {layer x y inside_radius outside_radius start_angle end_angle {sides_per_degree 0.125}} -desc {
  make a wedge of a pie.  angles in degrees
} {

  if {$start_angle > $end_angle} {
    set end_angle [expr $end_angle + 360]
  }

  # munge this so the side are spaced correctly
  set angle [expr ($end_angle - $start_angle) / \
		 round(($end_angle - $start_angle) * $sides_per_degree)]

  set convert [expr 3.14159265 / 180]

  set inside ""
  set outside ""

  set end_angle [expr $end_angle + $angle/2.0]

  for {set i $start_angle} {$i <= $end_angle} {set i [expr $i + $angle]} {
    set theta [expr $i * $convert]

#    lappend inside [list \
	[uusnap [expr $x + $inside_radius * cos($theta)]] \
	[uusnap [expr $y + $inside_radius * sin($theta)]]]

#    lappend outside \
	[uusnap [expr $x + $outside_radius * cos($theta)]] \
	[uusnap [expr $y + $outside_radius * sin($theta)]]


    # Note: these two coords are reversed
    lappend inside \
      [uusnap [expr $y + $inside_radius * sin($theta)]] \
      [uusnap [expr $x + $inside_radius * cos($theta)]]

    lappend outside \
      [uusnap [expr $x + $outside_radius * cos($theta)]] \
      [uusnap [expr $y + $outside_radius * sin($theta)]]
  }

  if {$inside_radius == 0} {
    if {($end_angle - $start_angle) >= 360} {
      # full circle
      set coords $outside
    } else {
      # piece o' pie
      set coords [concat $outside 0 0]
    }

  } else {
    set coords [concat $outside [lreverse $inside]]
  }
  eval db_polygon $layer $coords
}


proc _poly_draw_circle {layer x y r1 r2} {
    global POLY
    _make_pie_wedge $layer $x $y $r1 $r2 0 360 \
	[expr $POLY(sides_per_circle) / 360.0]
    # Identify center of circle with box.
    layt_box exact $x $y $x $y
}

##
## circle code
##

proc circle_mode_enter {} -desc {
  enter circle mode (for creating a circle/donut)
} {  
  global POLY

  mode_push circle
}


proc _circle_mode_define {} -desc {
  create a circle
} {
    mode_def circle _circle_gate_keeper \
	"BUT-1 starts BUT-2 ends BUT-3 selects layer under cursor"

    mode_bind -cmd 0 circle <Any-Button-1> _circle_start
    mode_bind -cmd 0 circle <Any-Button-2> _circle_end
    mode_bind -cmd 0 circle <Any-Button-3> _circle_choose_layer
}


proc _circle_mode_msg {} -desc {
  post circle mode message including current layer
} {
  global POLY

  mode_msg \
      "circle mode.  BUT-1 starts in $POLY(layer) BUT-2 ends BUT-3 selects layer under cursor"
}


proc _circle_gate_keeper {event} -desc {
  called whenever circle mode is entered/exited
} {
  global POLY mode_abort max_win PAL

  if {$event == "PUSH_TO"} {

    # initialize this circle
    set POLY(coords) ""
    set POLY(exists) 0
    set POLY(toggle) outer

    # define button2 and button3 command on palette
    set PAL(button2) "_circle_choose_layer circle"
    set PAL(button3) "_circle_choose_layer circle"

    _circle_mode_msg

  } elseif {$event == "POP_FROM"} {
    if { $mode_abort } {
      undo_to_delim
      undo_flush_redo
      msg "Aborting circle!\n"

    } else {
      # select this circle
      if { $POLY(exists) } { sel_polygons 0 }
    }

    # toast any annotations
    _circle_clear_annotations

    catch {unset PAL(button2)}
    catch {unset PAL(button3)}

    # delimit command
    i_cmd_between
  }
}


proc _circle_choose_layer {{layer ""}} -desc {
  set layer to first valid wiring layer under the cursor.
} -doc {
    If layer is specified, we were called from palette: set layer
    to that specified.  Otherwise, it was mouse button-3, set layer
    to that under the cursor.
} {

  global POLY max_win
  
  if {$layer == ""} {
    set layer [_poly_find_layer]
  }


  if {$layer == ""} {
    # no layer
    return
  }
  tool_bar_set_layer $layer

  # found visible layer under cursor
  set POLY(layer) $layer

  _circle_display

  if {[mode_current] == "circle"} {
    # change mode display to show new layer
    _circle_mode_msg
  }
}


proc _circle_start {} -desc {
  drag new circle vertex
} {
  global POLY

  if {$POLY(coords) == ""} {
    set POLY(coords) "[layt_point user] 0 0"
    sel_clear
  }

  # choose a starting layer (can be modified with button-2/3)
  _poly_init_layer

  # show the user what we got
  _circle_display

  mode_push circle_drag
}


proc _circle_end {} -desc {
  end circle
} {

  mode_pop
}


proc _circle_clear_annotations {} -desc {
  clear away any circle annotations
} {

  # toast any previous annotations
  # Using the box to mark the center now.
  #lay_line -tag circle -clear
}


proc _circle_display {{tmp ""}} -desc {
  show the user the circle vertices and edges
} {

  global POLY

  # toast any previous annotations
  _circle_clear_annotations

  setl {x y r1 r2} $POLY(coords)

  # make a little X at the origin
  layt_box exact $x $y $x $y

  #setl {x1 y1 x2 y2} [dbt_frame]
  #set del [expr ($x2 - $x1) * 0.01]
  #lay_line -tag circle [expr $x - $del] [expr $y - $del] \
      [expr $x + $del] [expr $y + $del]
  #lay_line -tag circle [expr $x - $del] [expr $y + $del] \
      [expr $x + $del] [expr $y - $del]

  if {$POLY(exists)} {
    db_polygon -delete 0
    set POLY(exists) 0
  }

  if {$r2 > 0} {
    # draw it for the happy user

    #_make_pie_wedge $POLY(layer) $x $y $r1 $r2 0 360 0.25
    _poly_draw_circle $POLY(layer) $x $y $r1 $r2
    set POLY(exists) 1
  }
}


proc _circle_drag_mode_define {} -desc {
  circle_drag mode is active when adding vertices
} {
  mode_def circle_drag pan_gate_keeper \
      "BUT-1 toggles between draggin inner and outer radius BUT-2 ends, \"r\" for menu to directly enter radius"

  mode_bind -cmd 0 circle_drag <Any-Motion> _circle_drag
  mode_bind -cmd 0 circle_drag <Any-Button-1> _circle_toggle
  mode_bind -cmd 0 circle_drag <Any-Button-2> _circle_drag_end
  mode_bind -cmd 0 circle_drag <r> _circle_menu
  mode_bind -cmd 0 circle_drag <p> _circle_menu
}


proc _circle_drag {} -desc {
  drag new circle vertex
} {
  global POLY

  pan_auto _circle_drag

  setl {x y r1 r2 oldx oldy} $POLY(coords)
  setl {nx ny} [layt_point user]

  if {$POLY(toggle) == "origin"} {
    # move entire circle
    if {$oldy != ""} {
      set x [expr $x + ($nx - $oldx)]
      set y [expr $y + ($ny - $oldy)]
    }
    
  } else {
    # change radius

    set r [expr sqrt(($nx - $x)*($nx - $x) + ($ny - $y)*($ny - $y))]

    # TODO fix this
    set r [uusnap $r]

    if {$POLY(toggle) == "outer"} {
      if {$r > $r1} {
	set r2 $r
      }
    } else {
      if {$r < $r2} {
	set r1 $r
      }
    }
  }

  set POLY(coords) "$x $y $r1 $r2 $nx $ny"

  _circle_display
}


proc _circle_toggle {} -desc {
  toggle between point to drag: inner radius, or outer radius
} {
  global POLY

  set pos [lsearch "outer inner" $POLY(toggle)]
  set POLY(toggle) [lindex "outer inner outer" [incr pos]]
}


proc _circle_menu {} -desc {
  menu to directly edit circle radius
} -doc {
    This may be called from circle_drag mode or directly.
} {
  global POLY
  
  setl {layer bbox coords} [sel_what polygons]
  # No polygon selected
  if { $layer == "" } { return }
  set layer [dbt_short_name $layer]

  setl {x y} [center_bbox $bbox]
  set x1 [lindex $bbox 0]
  set r2 [expr $x - $x1]

  # Is it a circle or a donut?
  if {[llength $coords] == 4 * $POLY(sides_per_circle) + 4} {
    # Got enough sides to be a donut.
    # The last x coord is at 0 degrees, and can be used
    # directly to get the inner radius.
    # llength coords - 1 for 0 based and -1 for x of x,y coord pair.
    set x3 [lindex $coords [expr [llength $coords] - 2]]
    set r1 [expr $x3 - $x]
  } else {
    # Its a circle.
    set r1 0
  }

  set title "Circle Size"
  set message "Enter circle radii (um's):"

  set prop_list [list \
	"x x -number -incr [res] -snap 0.1 -validate" \
	"y y -number -incr [res] -snap 0.1 -validate" \
	"inner r1 -number -min 0 -incr [res] -snap 0.1 -validate" \
	"outer r2 -number -min [res] -incr [res] -snap 0.1 -validate" \
	"layer layer -popup {[pal_layers]}" \
	 ]

  # create the menu
  set ret [prop_menu2 -message $message -title $title $prop_list]

  if {$ret == 0} {
    # user hit cancel
    return
  }

  # delete old circle: its still selected.
  delete

  # redraw it
  _poly_draw_circle $layer $x $y $r1 $r2

  # try to select it.
  sel_polygons 0

  # Not needed, since we are leaving circle_drag mode.
  #set POLY(layer) $layer
  #set POLY(coords) [list $x $y $r1 $r2]
  _circle_clear_annotations

  # don't go back to drag mode or screw up values
  if { [mode_current] != "circle_drag" } {
      _circle_drag_end
  }
}


proc _circle_drag_end {} -desc {
  end dragging a circle
} {

  global POLY

  mode_pop

  _circle_end
}


# TODO: needs a wrapper to select at end and allow colors to change

proc circle_edit {} -desc {
  edit the selected circle
} {
  global POLY

  setl {layer bbox coords} [sel_what polygons]
  
  # delete this circle
  set index [_find_polygon $layer $coords]
  db_polygon -delete $index

  setl {x y} [center_bbox $bbox]
  set x1 [lindex $bbox 0]

  # Is it a circle or a donut?
  if {[llength $coords] == 4 * $POLY(sides_per_circle) + 4} {
    # Got enough sides to be a donut.
    # The last x coord is at 0 degrees, and can be used
    # directly to get the inner radius.
    # llength coords - 1 for 0 based and -1 for x of x,y coord pair.
    set x3 [lindex $coords [expr [llength $coords] - 2]]
    set inner_radius [expr $x3 - $x]
  } else {
    set inner_radius 0
  }

  set POLY(coords) "$x $y $inner_radius [expr $x - $x1]"
  sel_clear

  set POLY(layer) $layer
  set POLY(exists) 0
  set POLY(toggle) outer

  # show the user what we got
  _circle_display

  # warp the cursor to the boundary
  layt_point -warp user $x1 $y

  _circle_start
}
