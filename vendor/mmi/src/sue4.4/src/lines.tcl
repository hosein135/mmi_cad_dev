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


# routines for drawing and editing lines

proc setup_line_mode {} {

  global cur_c SNAP_XY SAVE

  modify_setup

  enter_mode line abort_line_mode

  # Line mode global variable initialization
  catch {unset SAVE}

  msg_window "Button-1 start line segments, Button-2/3 start rectangle, Ctrl-c aborts"

  bind_add -mode line -hotkey Button-1 \
      -command "begin_line_segment $SNAP_XY" \
      -help "Begin drawing line at cursor."

  bind_add -mode line -hotkey Button-2 \
      -command "begin_rectangle $SNAP_XY" \
      -help "Begin drawing rectangle at cursor."

  bind_add -mode line -hotkey Button-3 \
      -command "begin_rectangle $SNAP_XY" \
      -help "Begin drawing rectangle at cursor."

  bind_add -mode line -hotkey Any-Control-c \
      -command "abort_line_mode; set SCROLL(status) off" \
      -help "Abort drawing line/rectangle."

  bind_add -mode line -hotkey space -command "help_window %x %y" \
      -help "Display this window."
}


# Creates the line that user can drag around.

proc begin_line_segment {x y} {

  global cur_c COLORS SAVE SNAP_XY SNAP10_XY

  # make the line
  set SAVE(id) \
      [$cur_c create line $x $y $x $y -tags "draw_item" -fill $COLORS(fore)]

  msg_window "Button-1 start new segment, Button-2/3 ends, Delete removes last segment, Ctrl-c aborts"

  # setup bindings to drag the line, and add extra line segments
  bind_add -mode line -hotkey Any-Motion \
      -command "drag_line_segment $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw line segment."

  bind_add -mode line -hotkey Control-Motion \
      -command "drag_line_segment $SNAP10_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw line segment off grid."

  bind_add -mode line -hotkey Any-Button-1 \
      -command "add_line_segment $SNAP_XY" \
      -help "Start new connected line segment."

  bind_add -mode line -hotkey Any-Button-2 \
      -command "end_line_mode; set SCROLL(status) off" \
      -help "End line."

  bind_add -mode line -hotkey Any-Button-3 \
      -command "end_line_mode; set SCROLL(status) off" \
      -help "End line."

  bind_add -mode line -hotkey Control-Button-2 \
      -command "end_line_mode arrow; set SCROLL(status) off" \
      -help "End line with arrowhead."

  bind_add -mode line -hotkey Control-Button-3 \
      -command "end_line_mode arrow; set SCROLL(status) off" \
      -help "End line with arrowhead."

  bind_add -mode line -hotkey Delete \
      -command "remove_line_segment $SNAP_XY" \
      -help "Remove last line segment."

  # F20 is the "cut" key
  bind_add -mode line -hotkey Any-F20 \
      -command "remove_line_segment $SNAP_XY" \
      -help "Remove last line segment."
}


# Removes last_line segment drawn, except if there's only one line segment

proc remove_line_segment {x y} {

  global cur_c SAVE

  # augment the existing line, by adding a new coordinate
  set coords [$cur_c coords $SAVE(id)]
  set length [llength $coords]

  # if more than one segment, remove last one
  if {$length != 4} {
    set coords [lreplace $coords [expr $length - 4] [expr $length - 1] $x $y]
    eval $cur_c coords $SAVE(id) $coords 
  }
}


# add_line_segment create the line that user can drag around.

proc add_line_segment {x y} {

  global cur_c SAVE

  # augment the existing line, by adding a new coordinate
  set coords [$cur_c coords $SAVE(id)]
  lappend coords $x $y
  eval $cur_c coords $SAVE(id) $coords
}


# Drags around the new line that's being created

proc drag_line_segment {x y} {

  global cur_c SAVE

  # resize new line's last coordinate
  set coords [$cur_c coords $SAVE(id)]
  set length [llength $coords]
  set coords [lreplace $coords [expr $length - 2] [expr $length - 1] $x $y]

  # remake the line with the new coords
  eval $cur_c coords $SAVE(id) $coords
}


# Finishes the drawing of the line and returns the bindings
# state to the previous input state

proc end_line_mode {{arrow ""}} {

  global cur_c SAVE

  set coords [$cur_c coords $SAVE(id)]
  set length [llength $coords]

  if {$coords == ""} {
    # get rid of a point line
    abort_line_mode
    return
  }

  if {[lindex $coords [expr $length - 4]] == \
	  [lindex $coords [expr $length - 2]] && \
	  [lindex $coords [expr $length - 3]] == \
	  [lindex $coords [expr $length - 1]]} {

    if {$length == 4} {
      # get rid of a point line
      abort_line_mode
      return
    }

    # toss out last two points of line (i.e. last coord) since duped.
    set coords [lreplace $coords [expr $length - 2] [expr $length - 1]]
    eval $cur_c coords $SAVE(id) $coords
  }

  if {$arrow != ""} {
    add_arrow
  }

  select_id $SAVE(id)
  create_line_edit_markers $SAVE(id)

  # save undo information
  setup_undo $SAVE(id) ""

  # flag that this canvas has been modified
  is_modified

  leave_mode line

  msg_window "(Shift)-Button-1 moves marker (constrained), Button-3 adds mark near current, Shift-Button-3 deletes current mark"
}


# Add an arrow head to the end of the line just drawn

proc add_arrow {} {

  global cur_c scale SAVE ARROWS

  # compute direction to place the arrow

  set coords [$cur_c coords $SAVE(id)]
  set length [llength $coords]

  set x1 [lindex $coords [expr $length - 4]]
  set y1 [lindex $coords [expr $length - 3]]
  set x2 [lindex $coords [expr $length - 2]]
  set y2 [lindex $coords [expr $length - 1]]

  set angle [expr atan2($y2-$y1,$x2-$x1)]

  # add each point of arrow head to end of line
  set first 1
  foreach point [use_first ARROWS($ARROWS(current))] {
    setl {x y} $point
    if {$x == 0 && $y == 0} {
      if {$first} {
	# first point at origin is assumed
	continue
      }

      lappend coords $x2 $y2

    } else {
      set len [expr sqrt($x*$x + $y*$y) * $scale*0.1]

      lappend coords [expr $x2 + cos(atan2($y,$x)+$angle) * $len] 
      lappend coords [expr $y2 + sin(atan2($y,$x)+$angle) * $len] 
    }

    set first 0
  }

  eval $cur_c coords $SAVE(id) $coords
}


# Deletes the line being drawn and returns to a good state

proc abort_line_mode {} {

  global cur_c SAVE SCROLL

  # get rid of the line being drawn
  if {[info exists SAVE(id)]} {
    $cur_c delete $SAVE(id)
  }

  # get rid of stroke box in rectangle mode
  $cur_c delete stroke_box 

#  puts "Aborting line mode"

  set SCROLL(status) off

  leave_mode line
}


# Draws a rectangle (really just a line)

proc begin_rectangle {x y} {

  global cur_c COLORS SAVE SNAP_XY SNAP10_XY

  msg_window "Drag rectangle.  Tab toggles box, release Button-2/3 ends, Ctrl-C aborts"

  set SAVE(x) $x
  set SAVE(y) $y

  set SAVE(mode) 0

  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(fore) -tags "stroke_box sb1"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(fore) -tags "stroke_box sb2"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(fore) -tags "stroke_box sb3"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(fore) -tags "stroke_box sb4"

  bind_add -mode line -hotkey Any-Motion \
      -command "drag_rectangle $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw rectangle."

  bind_add -mode line -hotkey Control-Motion \
      -command "drag_rectangle $SNAP10_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw rectangle off grid."

  bind_add -mode line -hotkey Any-B2-ButtonRelease \
      -command "end_rectangle; set SCROLL(status) off" \
      -help "End rectangle."

  bind_add -mode line -hotkey Any-B3-ButtonRelease \
      -command "end_rectangle; set SCROLL(status) off" \
      -help "End rectangle."

  # toggle mode with shift key
  bind_add -mode line -hotkey Any-Tab \
      -command {toggle SAVE(mode) $IDIOT_DELAY} \
      -help "Toggle between draging rectangle and translating rectangle."
}


# drags the rectangle with the cursor

proc drag_rectangle {x y} {

  global cur_c SAVE

  if {$SAVE(mode) == 0} {
    # resize drag box to cursor location
    $cur_c coords sb1 $SAVE(x) $SAVE(y) $x $SAVE(y)
    update idletasks

    $cur_c coords sb2 $SAVE(x) $SAVE(y) $SAVE(x) $y
    update idletasks

    $cur_c coords sb3 $x $SAVE(y) $x $y
    update idletasks

    $cur_c coords sb4 $SAVE(x) $y $x $y
    update idletasks

  } else {

    # move the box
    set dx [expr $x - $SAVE(lastx)]
    set dy [expr $y - $SAVE(lasty)]

    $cur_c move sb1 $dx $dy
    update idletasks

    $cur_c move sb2 $dx $dy
    update idletasks

    $cur_c move sb3 $dx $dy
    update idletasks

    $cur_c move sb4 $dx $dy
    update idletasks

    set SAVE(x) [expr $SAVE(x) + $dx]
    set SAVE(y) [expr $SAVE(y) + $dy]
  }

  set SAVE(lastx) $x
  set SAVE(lasty) $y
}


# now make the rectangle (really just a line)

proc end_rectangle {} {

  global cur_c scale COLORS
  
  # get the bbox of the stroke_box
  # bbox gives the wrong answer (bloats a little).
#  setl {x1 y1 x2 y2} [round_list_scale [$cur_c bbox stroke_box] $scale]

  foreach id [$cur_c find withtag stroke_box] {
    setl {xx1 yy1 xx2 yy2} [round_list_scale [$cur_c coords $id] $scale]
    
    if {[info exists x1]} {
      set x1 [min $x1 $xx1]
      set y1 [min $y1 $yy1]
      set x2 [max $x2 $xx2]
      set y2 [max $y2 $yy2]
    } else {
      set x1 $xx1
      set y1 $yy1
      set x2 $xx2
      set y2 $yy2
    }
  }

  # get rid of stroke box
  $cur_c delete stroke_box 

  if {$x1 == $x2 || $y1 == $y2} {
    # bad rectangle
    abort_line_mode
    return
  }

  set id [$cur_c create line $x1 $y1 $x1 $y2 $x2 $y2 $x2 $y1 $x1 $y1 \
	      -tags "draw_item" -fill $COLORS(fore)]

  select_id $id
  create_line_edit_markers $id

  # save undo information
  setup_undo $id ""

  # flag that this canvas has been modified
  is_modified

  leave_mode line

  msg_window "Button-1 moves markers or lines, Button-3 adds mark near current, Shift-Button-3 deletes current mark"
}


# Makes a line.  Called from outside world

proc make_line {args} -type user -desc {

Primitive procedure to add a line to the current schematic.  Lines
contain 2 or more endpoints, i.e. unlike wires, they can be
multi-segment.  Lines are for annotation/documentation purposes only:
they are ignored by the netlister.  To create a closed polygon, simply
make the first and last endpoint the same.  Rectangles are simply a
line drawn to be a closed polygon.

USAGE: make_line <list_of_x_y_pairs>

For example:

        sue> make_line 120 150 200 300
        sue> make_line 0 0 100 0 100 100 0 100 0 0

NOTE: this procedure can only be used on a new schematic or if
proceeded by api_zoom setup.  Otherwise, its position may be incorrect
or even off-grid.

NOT UN-DOABLE

} {

  global cur_c COLORS

  set id [eval $cur_c create line $args -tags draw_item -fill $COLORS(fore)]

  return $id
}


# Make edit markers that the user can click on and drag to resize the line.

proc create_line_edit_markers {id} {

  global cur_c COLORS

  set coords [$cur_c coords $id]

  for {set i 0} {$i < [llength $coords]} {incr i 2} {
    # create the vertex edit marker
    set mark_id [create_edit_mark [lindex $coords $i] \
		     [lindex $coords [expr $i + 1]]]
    $cur_c addtag "proc resize $id $mark_id $i" withtag $mark_id

    $cur_c bind $mark_id <Button-3> "add_vertex $id $mark_id $i"
    $cur_c bind $mark_id <Control-Button-3> "add_vertex $id $mark_id $i"
    $cur_c bind $mark_id <Shift-Button-3> "delete_vertex $id $mark_id $i"
  }

  msg_window "(Shift-)Button-1 moves marker (constrained), Button-3 adds mark near current, Shift-Button-3 deletes current mark"
}


proc resize {id mark_id index} {

  global cur_c SAVE

  set coords [$cur_c coords $id]
  setl {xm ym} [center $mark_id]
  set length [expr [llength $coords] - 2]
  set dup ""

  if {[$cur_c type $id] == "line" && $length > 4} {
    setl {x y} [lrange $coords $index [expr $index + 1]]
    if {$index > 0} {
      set before [expr $index - 2]
    } else {
      setl {xx yy} [lrange $coords $length end]
      if {[nearby $x $y $xx $yy]} {
	# first and last point are overlaping (i.e. close polygon)
	set dup "$index $length"
	set before [expr $length - 2]
      } else {
	set before $length
      }
    }
    if {$index < $length} {
      set after [expr $index + 2]
    } else {
      setl {xx yy} [lrange $coords 0 1]
      if {[nearby $x $y $xx $yy]} {
	# first and last point are overlaping (i.e. close polygon)
	set dup "$index 0"
	set after 2
      } else {
	set after 0
      }
    }

    setl {xb yb} [lrange $coords $before [expr $before + 1]]
    setl {xa ya} [lrange $coords $after [expr $after + 1]]

    if {$before == 0} {
      setl {xx yy} [lrange $coords $length end]
      if {[nearby $xb $yb $xx $yy]} {
	set dup "0 $length"
      }
    }
    if {$after == $length} {
      setl {xx yy} [lrange $coords 0 1]
      if {[nearby $xa $ya $xx $yy]} {
	set dup "$length 0"
      }
    }

    if {$SAVE(shift) != ""} {
      # constrained, manhattan lines stay manhattan
      if {$x == $xb && $y != $yb && $before != $length} {
	set coords [lreplace $coords $before $before $xm]
	move_marker $xb $yb $xm $yb
      }
      if {$y == $yb && $x != $xb && $before != $length} {
	set coords [lreplace $coords [expr $before + 1] [expr $before + 1] $ym]
	move_marker $xb $yb $xb $ym
      }
      if {$x == $xa && $y != $ya && $after != 0} {
	set coords [lreplace $coords $after $after $xm]
	move_marker $xa $ya $xm $ya
      }
      if {$y == $ya && $x != $xa && $after != 0} {
	set coords [lreplace $coords [expr $after + 1] [expr $after + 1] $ym]
	move_marker $xa $ya $xa $ym
      }
    }
  }

  set coords [lreplace $coords $index [expr $index + 1] $xm $ym]

  if {$dup != ""} {
    setl {orig duped} $dup
    setl {xx yy} [lrange $coords $orig [expr $orig + 1]]
    eval move_marker [lrange $coords $duped [expr $duped + 1]] $xx $yy
    set coords [lreplace $coords $duped [expr $duped + 1] $xx $yy]
  }

  eval $cur_c coords $id $coords
}


proc move_marker {x y newx newy} {

  global cur_c scale

  # first find the marker at x,y
  set del [expr $scale/3.0]
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]
  foreach id $ids {
    if {[is_tagged $id edit_marker]} {
      # Found it, now move it
      $cur_c move $id [expr $newx - $x] [expr $newy - $y]
      return
    }
  }
    
  # couldn't find it???
}


proc delete_vertex {id mark_id index} {

  global cur_c IGNORE_MOVE

  set coords [$cur_c coords $id]

  # can't delete a vertex if there is only one line segment
  if {[llength $coords] <= 4} {
    return
  }

  # delete all marks since their indices are now wrong.
  $cur_c delete edit_marker

  set new_coords [lreplace $coords $index [expr $index + 1]]

  eval $cur_c coords $id $new_coords

  create_line_edit_markers $id

  is_modified

  # so the button-3 command won't also cause a move which deletes
  # edit markers
  set IGNORE_MOVE 1
}


proc add_vertex {id mark_id index} {

  global cur_c scale IGNORE_MOVE

  set coords [$cur_c coords $id]
  set mark_coords [center $mark_id]

  set new_coords [linsert $coords $index \
		      [expr $scale + [lindex $mark_coords 0]] \
		      [expr $scale + [lindex $mark_coords 1]]]

  # delete all marks since their indices are now wrong.
  $cur_c delete edit_marker

  eval $cur_c coords $id $new_coords

  create_line_edit_markers $id

  is_modified

  # so the button-3 command won't also cause a move which deletes
  # edit markers
  set IGNORE_MOVE 1
}
