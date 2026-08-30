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


# Routines for drawing and editing arcs/circles/ellipses.

proc setup_arc_mode {} {

  global cur_c SNAP_XY

  modify_setup

  enter_mode arc abort_arc_mode

  msg_window "Button-1 begins arc, Button-2/3 begins circle, Shift key constrains to circular, Ctrl-c aborts"

  bind_add -mode arc -hotkey Any-Button-1 \
      -command "begin_arc_draw $SNAP_XY" \
      -help "Begin an arc."

  bind_add -mode arc -hotkey Any-Button-2 \
      -command "begin_arc_draw $SNAP_XY circle" \
      -help "Begin a circle/ellipse."

  bind_add -mode arc -hotkey Any-Button-3 \
      -command "begin_arc_draw $SNAP_XY circle" \
      -help "Begin a circle/ellipse."

  bind_add -mode arc -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  bind_add -mode arc -hotkey Control-c -command "abort_arc_mode" \
      -help "Abort drawing and arc/circle."
}


# makes an arc.  Called from outside world

proc make_arc {x1 y1 x2 y2 args} -type user -desc {

Primitive procedure to add an arc to the current schematic.  

Arcs are drawn by specifying the bounding box of an ellipse.  The
start angle (in degrees) and the extent of the arc counterclockwise
(in degress) are also specified.  Circles are arcs with square
bounding boxes and an extent of 359 degrees.

SUE does not support splines.

USAGE: make_arc x1 y1 x2 y2 -start <start_angle> -extent <extent_angle>

<start_angle> defaults to 0 degrees which corresponds to the middle of
the right side of the bounding box.  

<extent_angle> defaults to 90 degrees and proceeds counterclockwise.
Note: the maximum extent is 359 degrees and creates a closed
circle/ellipse.

For example:

        sue> make_arc 0 0 200 200 -start 90 -extent 180
        sue> make_arc 100 100 300 300 -extent 359

NOTE: this procedure can only be used on a new schematic or if
proceeded by api_zoom setup.  Otherwise, its position may be incorrect
or even off-grid.

NOT UN-DOABLE

} {

  global cur_c COLORS

  set id [eval $cur_c create arc $x1 $y1 $x2 $y2 -tags \"draw_item arc\" \
	      -style arc -outline $COLORS(fore) $args]
  return $id
}


# creates the arc that user can drag around.

proc begin_arc_draw {x y {type arc}} {

  global cur_c SNAP_XY SNAP10_XY ARC

  msg_window "Drag $type, Shift constrains to Circular, Release Button to end, Ctrl-c aborts"

  set ARC(x) $x
  set ARC(y) $y
  set ARC(type) $type

  # make the starting arc -- prepare for warnings
  if {$type == "arc"} {
    set ARC(id) [make_arc $x $y $x $y -start 0 -extent 270]
  } else {
    set ARC(id) [make_arc $x $y $x $y -start 0 -extent 359]
  }

  # remove old bindings
  bind $cur_c <Any-Button-1> ""
  bind $cur_c <Any-Button-2> ""
  bind $cur_c <Any-Button-3> ""

  # setup bindings to drag the arc, and set the finish point
  if {$type == "arc"} {
    bind_add -mode arc -hotkey B1-Motion -command "drag_arc $SNAP_XY" \
	-help "Drag an arc."

    bind_add -mode arc -hotkey Control-B1-Motion \
	-command "drag_arc $SNAP10_XY" \
	-help "Drag an arc off grid."

    bind_add -mode arc -hotkey Control-Shift-B1-Motion \
	-command "drag_arc $SNAP10_XY circle" \
	-help "Drag an arc off grid (constrained to circular)."

    bind_add -mode arc -hotkey Shift-B1-Motion \
	-command "drag_arc $SNAP_XY circle" \
	-help "Drag an arc (constrained to circular)."

    bind_add -mode arc -hotkey Any-B1-ButtonRelease \
	-command "end_arc_mode" \
	-help "End drawing arc."
  } else {
    bind_add -mode arc -hotkey B2-Motion -command "drag_arc $SNAP_XY" \
	-help "Drag an circle."

    bind_add -mode arc -hotkey Control-B2-Motion \
	-command "drag_arc $SNAP10_XY" \
	-help "Drag a circle off grid."

    bind_add -mode arc -hotkey Control-Shift-B2-Motion \
	-command "drag_arc $SNAP10_XY circle" \
	-help "Drag a circle off grid (constrained to circular -- no ellipses)."

    bind_add -mode arc -hotkey Shift-B2-Motion \
	-command "drag_arc $SNAP_XY circle" \
	-help "Drag a circle (constrained to circular -- no ellipses)."

    bind_add -mode arc -hotkey Any-B2-ButtonRelease \
	-command "end_arc_mode" \
	-help "End drawing circle."

    bind_add -mode arc -hotkey B3-Motion -command "drag_arc $SNAP_XY" \
	-help "Drag an circle."

    bind_add -mode arc -hotkey Control-B3-Motion \
	-command "drag_arc $SNAP10_XY" \
	-help "Drag a circle off grid."

    bind_add -mode arc -hotkey Control-Shift-B3-Motion \
	-command "drag_arc $SNAP10_XY circle" \
	-help "Drag a circle off grid (constrained to circular -- no ellipses)."

    bind_add -mode arc -hotkey Shift-B3-Motion \
	-command "drag_arc $SNAP_XY circle" \
	-help "Drag a circle (constrained to circular -- no ellipses)."

    bind_add -mode arc -hotkey Any-B3-ButtonRelease \
	-command "end_arc_mode" \
	-help "End drawing circle."
  }

  bind_add -mode arc -hotkey Any-Control-c -command "abort_arc_mode" \
      -help "Abort drawning an arc/circle."
}


# drags around the new arc

proc drag_arc {x y {type ""}} {

  global cur_c ARC

  if {$type != ""} {
    # constrain to be circular
    if {[expr abs($ARC(x) - $x)] > [expr abs($ARC(y) - $y)]} {
      if {$y > $ARC(y)} {
	set y [expr $ARC(y) + abs($x - $ARC(x))]
      } else {
	set y [expr $ARC(y) - abs($x - $ARC(x))]
      }
    } else {
      if {$x > $ARC(x)} {
	set x [expr $ARC(x) + abs($y - $ARC(y))]
      } else {
	set x [expr $ARC(x) - abs($y - $ARC(y))]
      }
    }
  }

  # reshape the arc. Needed since Tk expects that
  # x1, y1 for a rectangle or arc are always less than x2,y2
  if {$ARC(x) > $x} {
    if {$ARC(y) > $y} { 
      # topleft quadrant
      catch "$cur_c coords $ARC(id) $x $y $ARC(x) $ARC(y)"
    } else { 
      # bottomleft quadrant
      catch "$cur_c coords $ARC(id) $x $ARC(y) $ARC(x) $y"
    }
  } else {
    if {$ARC(y) > $y} { 
      # topright quadrant
      catch "$cur_c coords $ARC(id) $ARC(x) $y $x $ARC(y)"
    } else { 
      # bottomright quadrant
      catch "$cur_c coords $ARC(id) $ARC(x) $ARC(y) $x $y"
    }
  }
}


# finishes the drawing of the arc

proc end_arc_mode {} {

  global cur_c ARC

  # is the arc bbox a point or a line? 
  set c [$cur_c coords $ARC(id)]
  if {[nearby_num [lindex $c 0] [lindex $c 2]] || \
	  [nearby_num [lindex $c 1] [lindex $c 3]]} {
    # throw away a point arc
    puts "Arc too small, aborted."
    abort_arc_mode
    return
  }

  select_id $ARC(id)
  create_arc_edit_markers $ARC(id)

  # save undo information
  setup_undo $ARC(id) ""

  # flag that this canvas has been modified
  is_modified

  leave_mode arc
}


# deletes the arc being drawn

proc abort_arc_mode {} {

  global cur_c ARC

  if {[info exists ARC(id)]} {
    $cur_c delete $ARC(id)
  }

  leave_mode arc
}


# disgusting procedures to try to make arc editing nice

proc create_arc_edit_markers {id} {

  global cur_c

  set coords [$cur_c coords $id]
  set x1 [lindex $coords 0]
  set y1 [lindex $coords 1]
  set x2 [lindex $coords 2]
  set y2 [lindex $coords 3]

  # edit markers for the overall size
  set mark_id [create_edit_mark $x1 $y1]
  $cur_c addtag "proc resize $id $mark_id 0" withtag $mark_id
  set mark_id [create_edit_mark $x2 $y2]
  $cur_c addtag "proc resize $id $mark_id 2" withtag $mark_id

  # edit markers for the arc start and extent
  # note that start and extent are in degrees, sin, cos take radians.
  set deg_to_rad [expr 3.14159265 / 180]
  set extent [expr [$cur_c itemcget $id -extent] * $deg_to_rad]
  set start [expr [$cur_c itemcget $id -start] * $deg_to_rad]
  set center [center $id]
  set dx [expr abs($x2-$x1)]
  set dy [expr abs($y2-$y1)]
  if {$dx > $dy} {
    set radius [expr $dx/2 + 20]
  } else {
    set radius [expr $dy/2 + 20]
  }
  
########################################################################
# Bogus tclc bug fix 1
#  set mark_id [create_edit_mark \
#		   [expr cos($start)*$radius + [lindex $center 0]] \
#		   [expr -sin($start)*$radius + [lindex $center 1]]]
########################################################################
  set wex [expr cos($start)*$radius + [lindex $center 0]]
  set wey [expr -sin($start)*$radius + [lindex $center 1]]
  set mark_id [create_edit_mark $wex $wey]

  $cur_c addtag "proc arc_start $id $mark_id" withtag $mark_id

########################################################################
# Bogus tclc bug fix 2
#  set mark_id [create_edit_mark \
#		   [expr cos($start+$extent)*$radius + [lindex $center 0]] \
#		   [expr -sin($start+$extent)*$radius + [lindex $center 1]]]
########################################################################
  set wex [expr cos($start+$extent)*$radius + [lindex $center 0]]
  set wey [expr -sin($start+$extent)*$radius + [lindex $center 1]]
  set mark_id [create_edit_mark $wex $wey]

  $cur_c addtag "proc arc_extent $id $mark_id" withtag $mark_id

  msg_window "Button-1 moves markers: 2 are for arc size, 1 for arc start, 1 for arc end"
}


proc arc_start {id mark_id} {

  global cur_c

  set deg_to_rad [expr 3.14159265 / 180]
  set start [$cur_c itemcget $id -start]
  set extent [$cur_c itemcget $id -extent]
  set mark_coords [center $mark_id]
  set center [center $id]
  set dx [expr [lindex $mark_coords 0] - [lindex $center 0]]
  set dy [expr [lindex $mark_coords 1] - [lindex $center 1]]
  set new_start [expr int(atan2($dx,$dy) / $deg_to_rad - 90)]
  set new_extent [expr int($extent - ($new_start - $start))]

  if {$new_extent > 345 && $new_extent < 380} {
    # make it a an oval
    set new_extent 359
    set new_start [expr int($start + $extent - $new_extent)]
  }

  $cur_c itemconfigure $id -start $new_start
  $cur_c itemconfigure $id -extent $new_extent
}


proc arc_extent {id mark_id} {

  global cur_c

  set deg_to_rad [expr 3.14159265 / 180]
  set start [$cur_c itemcget $id -start]
  set mark_coords [center $mark_id]
  set center [center $id]
  set dx [expr [lindex $mark_coords 0] - [lindex $center 0]]
  set dy [expr [lindex $mark_coords 1] - [lindex $center 1]]
  set degs [expr atan2($dx,$dy) / $deg_to_rad + 270]
  set extent [expr int($degs - $start)]

  if {$extent <= 0} {
    incr extent 360
  }

  if {$extent > 345 && $extent < 380} {
    # make it a an oval
    set extent 359
  }

  $cur_c itemconfigure $id -extent $extent
}
