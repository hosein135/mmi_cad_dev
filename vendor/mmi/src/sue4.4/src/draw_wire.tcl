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


# Procedures for drawing wires in sue.

# What some of the wire global variables are for:
# SAVE(x) SAVE(y) first x,y coords of current line
# SAVE(id) the canvas id of current wire segment
# SAVE(ids) the canvas ids of all previous wires
# SAVE(HV) whether the current wire segment is vertical/horizontal, or if
#          it is at any angle
# SAVE(dir) records last wire segment being vertical or horizontal


proc setup_draw_wire {} {

  global cur_c cur_s scale SNAP_XY SAVE

  modify_setup

  if {[is_icon $cur_s]} {
    # must be an icon
    puts "Aborting wire mode.  Can't draw wires in icons.  Use lines."
    return
  }

  enter_mode wire abort_wire_mode

  # Wire mode global variable initialization
  catch {unset SAVE}
  
  set SAVE(HV) 1
  set SAVE(id) ""
  set SAVE(ids) ""
  set SAVE(dir) ""
  set SAVE(dirs) ""
  set SAVE(scale) $scale
  set SAVE(zoom) 0

  setup_save_wires

  # add tag to all potential wire-to locations (opens in this case)
  $cur_c addtag wire_to withtag open

  set SAVE(selection) [$cur_c find withtag selected]
  # deselect everything
  select_ids ""

  msg_window "Button-1 adds segment, Button-2/3 ends, Shift for non-manhattan, Contrl-Button-1 begins at closest. Ctrl-c cancels"

  # pressing the shift and button-1 causes the current wire being drawn 
  # To have a non manhattan geometry

  bind_add -mode wire -hotkey Button-1 \
      -command "set SAVE(HV) 1; begin_draw_wire $SNAP_XY" \
      -help "Begin drawing a wire at the cursor position."

  bind_add -mode wire -hotkey Shift-Button-1 \
      -command "set SAVE(HV) 0; begin_draw_wire $SNAP_XY" \
      -help "Begin drawing a non-manhattan wire at the cursor position."

  bind_add -mode wire -hotkey Any-Motion \
      -command "draw_wire_mark_closest $SNAP_XY" \
      -help "Show closest connect point with an X."

  bind_add -mode wire -hotkey Button-2 \
      -command "end_wire_mode $SNAP_XY; set SCROLL(status) off" \
      -help "End drawing a wire."

  bind_add -mode wire -hotkey Button-3 \
      -command "end_wire_mode $SNAP_XY; set SCROLL(status) off" \
      -help "End drawing a wire."

  bind_add -mode wire -hotkey Control-Button-1 \
      -command "set SAVE(HV) 1; begin_draw_wire $SNAP_XY closest" \
      -help "Begin drawing a wire at the closest (X)."

  bind_add -mode wire -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  bind_add -mode wire -hotkey Any-Control-c \
      -command "abort_wire_mode; set SCROLL(status) off" \
      -help "Abort wire mode, removing any partially completed wires."

  # double button-1 will finish wire and start a new one
#  bind $cur_c <Double-Button-1> \
#      "end_wire_mode $SNAP_XY ; setup_draw_wire ; begin_draw_wire $SNAP_XY"
}

proc end_wire_mode {x y {closest ""} {type ""}} {

  global cur_c scale SAVE SCROLL

  set SCROLL(status) off

  # if closest is called for, substitute x,y with closest term x,y
  if {$closest != ""} {
    set id [lindex [$cur_c find withtag closest] 0]
    if {$id != ""} {
      # first remove the last segment that we got from the double click
      if {$type == "double" && [llength $SAVE(ids)] > 2} {
	remove_wire_segment $x $y
      }

      # can't use center command because this is an X
      set coords [$cur_c coords $id]
      set x1 [expr ([lindex $coords 0] + [lindex $coords 2])/2]
      set y1 [expr ([lindex $coords 1] + [lindex $coords 3])/2]

      # get the thing this open is over
      set del [expr $scale/3.0]

      # NOTE: this can be done at sub 1 scale.
      set ids [$cur_c find overlapping [expr $x1 - $del] [expr $y1 - $del] \
		   [expr $x1 + $del] [expr $y1 + $del]]
      foreach id $ids {
	if {[is_tagged $id term]} {
	  if {[is_tagged $id rotate]} {
	    # come in vertically
	    if {$SAVE(dir) == "H"} {
	      # switch dir
	      add_wire_segment $x $y
	    }

	  } else {
	    # come in horizontally
	    if {$SAVE(dir) == "V"} {
	      # switch dir
	      add_wire_segment $x $y
	    }
	  }

	  break
	}
      }

      if {$SAVE(ids) == ""} {
	# first must add a segment
	add_wire_segment $x $y
      }
      rubber_band_wire $x1 $y1
    }
  }

  # finish the current wire -- unless the user never started any wires
  if {$SAVE(id) != ""} {
    finish_wire_segment $x $y

    integer_scale

    # clean up all wires
    foreach id $SAVE(ids) {
      show_connect_wire $id clean
    }

    unscale

    # flag that this canvas has been modified
    is_modified

    # clean up any leftover
    $cur_c delete tmp

    setup_undo "" [setup_undo_wires] wire
  }

  # clean up
  $cur_c dtag wire_to

  leave_mode wire
}


proc setup_save_wires {} {

  global cur_c scale SAVE

  # do we have the fancy version of wish?
  if {[catch "$cur_c coordsall {}"]} {
    # not implemented
    return 0
  }

  # special enhancement to canvases to quickly checkpoint all wires
  $cur_c addtag Xsect withtag wire
  $cur_c dtag selected Xsect
  # unselected wires
  set SAVE(undo,wires) [$cur_c coordsall Xsect]
  set SAVE(undo,scale) $scale
  $cur_c dtag Xsect
  
  intersect_tag sel_wires wire selected
  # selected wires
  set SAVE(undo,sel_wires) [$cur_c coordsall sel_wires]
  $cur_c dtag sel_wires

  return 1
}


proc setup_undo_wires {{scale_command ""}} {

  global SAVE

  # recreate wires from checkpoint, first non-selected, then selected for undo
  lappend new_proc "global cur_c scale"
  lappend new_proc "\$cur_c delete wire open dot"

  if {[info exists SAVE(undo,scale)]} {
    lappend new_proc "scale_canvas $SAVE(undo,scale)"
  }

  foreach coords [split [use_first SAVE(undo,wires)] ^] {
    if {[llength $coords] == 5} {
      lappend new_proc "id_undo [lindex $coords 0] \[make_wire [lrange $coords 1 end]\]"
    }
  }

  foreach coords [split [use_first SAVE(undo,sel_wires)] ^] {
    if {[llength $coords] == 5} {
      lappend new_proc "id_undo [lindex $coords 0] \[make_wire_selected [lrange $coords 1 end] selected\]"
    }
  }

  if {$scale_command != ""} {
    # add a scale command here before the update
    lappend new_proc $scale_command
  }

  lappend new_proc "update"
  lappend new_proc integer_scale
# clean not needed since coordsall gives us something that was clean
#  lappend new_proc {show_connects "" clean}
  lappend new_proc {show_connects "" fast}
  lappend new_proc "unscale"

  return $new_proc
}


proc abort_wire_mode {} {

  global cur_c SAVE SCROLL

  set SCROLL(status) off

  # delete closest thingy
  $cur_c delete closest

  # delete current line segments
  $cur_c delete tmp

  # delete previous line segments
  if {[info exists SAVE(ids)]} {
    foreach id $SAVE(ids) {
      $cur_c delete $id
    }
  }

  # reselect what was selected before
  select_ids $SAVE(selection)

  # clean up
  $cur_c dtag wire_to

  puts "Aborting wire mode"

  leave_mode wire
}

proc begin_draw_wire {x y {closest ""}} {

  global cur_c scale SAVE SNAP_XY

  set sx $x
  set sy $y

  if {$closest != ""} {
    # use the closest point
    set id [lindex [$cur_c find withtag closest] 0]
    if {$id != ""} {
      # can't use center command because this is an X
      set coords [$cur_c coords $id]
      set x [expr ([lindex $coords 0] + [lindex $coords 2])/2]
      set y [expr ([lindex $coords 1] + [lindex $coords 3])/2]
    }
  }

  # save the coords and just make a point wire.  This will get rubber
  # banded into a real wire
  set SAVE(x) $x
  set SAVE(y) $y	

  set SAVE(id) [create_line $x $y $x $y]

  # add tag to all potential wire-to locations (opens in this case)
  $cur_c addtag wire_to withtag open

  # if there is an open where we started from, remove it from the list
  set del [expr $scale/3.0]

  # NOTE: this can be done at sub 1 scale.
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]
  foreach id $ids {
    if {[is_tagged $id open]} {
      $cur_c dtag $id wire_to
    }
  }

  msg_window "Button-1 adds segment, Button-2/3 ends, Delete  or \"u\" removes last segment, Shift for non-manhattan, Control-Button-1 or Double_Button-1 ends to closest. Ctrl-c cancels"

  bind_add -mode wire -hotkey Double-Button-1 \
      -command "end_wire_mode $SNAP_XY closest double; set SCROLL(status) off" \
      -help "Finish wire to closest (X)."

  bind_add -mode wire -hotkey Control-Button-1 \
      -command "end_wire_mode $SNAP_XY closest; set SCROLL(status) off" \
      -help "Finish wire to closest (X)."

  bind_add -mode wire -hotkey Delete \
      -command "remove_wire_segment $SNAP_XY" \
      -help "Remove the last wire segment."

  bind_add -mode wire -hotkey u \
      -command "remove_wire_segment $SNAP_XY" \
      -help "Remove the last wire segment."

  # F20 is the "cut" key
  bind_add -mode wire -hotkey F20 \
      -command "remove_wire_segment $SNAP_XY" \
      -help "Remove the last wire segment."

#  bind_add -mode wire -hotkey B1-Motion \
      -command "set SAVE(HV) 1 ; rubber_band_wire $SNAP_XY ; \
          set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw wire."

  bind_add -mode wire -hotkey Motion \
      -command "set SAVE(HV) 1 ; rubber_band_wire $SNAP_XY ; \
          set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw wire."

#  bind_add -mode wire -hotkey Shift-B1-Motion \
      -command "set SAVE(HV) 0 ; rubber_band_wire $SNAP_XY; \
           set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw non-manhattan wire."

  bind_add -mode wire -hotkey Shift-Motion \
      -command "set SAVE(HV) 0 ; rubber_band_wire $SNAP_XY; \
           set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw non-manhattan wire."

  # Additional button-1 presses give us a new segment
  bind_add -mode wire -hotkey Button-1 \
      -command "set SAVE(HV) 1 ; add_wire_segment $SNAP_XY" \
      -help "Start new perpendicular wire segment."

  bind_add -mode wire -hotkey Shift-Button-1 \
      -command "set SAVE(HV) 0 ; add_wire_segment $SNAP_XY" \
      -help "Start new non-manhattan wire segment."

  bind_add -mode wire -hotkey z \
      -command "add_wire_zoom $SNAP_XY 1.5" \
      -help "Zoom in on cursor."

  bind_add -mode wire -hotkey Z \
      -command "add_wire_zoom $SNAP_XY 0.7" \
      -help "Zoom out on cursor."

  rubber_band_wire $sx $sy
}


proc add_wire_segment {x y} {

  global SAVE

  # first finish the last wire segment before starting the next one
  finish_wire_segment $x $y

  # SAVE(nx) and SAVE(ny) are the actual position of the wire
  set SAVE(x) $SAVE(nx)
  set SAVE(y) $SAVE(ny)
  # start a new segment
  set SAVE(id) [create_line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y)]

  set SAVE(dirs) "$SAVE(dir) $SAVE(dirs)"
}


# Fix up SAVE database after zooming

proc add_wire_zoom {x y {zoom ""}} {

  global SAVE scale cur_c

  # turn off rubber banding
  set SAVE(zoom) 1

  eval zoom_on_cursor $x $y $zoom doit

  # scale saved stuff
  set mult [expr 1.0 * $scale / $SAVE(scale)]

  set SAVE(x) [expr $SAVE(x) * $mult]
  set SAVE(y) [expr $SAVE(y) * $mult]
  set SAVE(nx) [expr $SAVE(nx) * $mult]
  set SAVE(ny) [expr $SAVE(ny) * $mult]

  # save the new scale
  set SAVE(scale) $scale

  # turn rubber banding back on
  set SAVE(zoom) 0
}


proc finish_wire_segment {x y} {

  global cur_c SAVE

  # delete current line, gets recreated below with good coords
  $cur_c delete $SAVE(id)
  set SAVE(id) ""

  # if the wire segment has no length, punt
  if {[nearby $SAVE(x) $SAVE(y) $SAVE(nx) $SAVE(ny)]} {
    return
  }

  # make a real wire (was a line before)
  set id [make_wire_selected $SAVE(x) $SAVE(y) $SAVE(nx) $SAVE(ny) selected]

  # show_connect_wire on the previous segment if there is one
  #if {[llength $SAVE(ids)] != 0} {
  #show_connect_wire [lindex $SAVE(ids) 0]
  #}

  set SAVE(ids) [concat $id $SAVE(ids)]

  # if we are manhattan, switch the direction for the new segment 
  if {$SAVE(HV) == 1} {
    if {$SAVE(dir) == ""} {
      set SAVE(dir) [wire_direction $id]
    }
    if {$SAVE(dir) == "V"} {
      set SAVE(dir) H
    } elseif {$SAVE(dir) == "H"} {
      set SAVE(dir) V
    }
  }
}


# remove a segment of the wire during drawing

proc remove_wire_segment {x y} {

  global cur_c SAVE

  if {[llength $SAVE(ids)] == 0} {
    # let use start wire at a new point
    if {$SAVE(id) != ""} {
      $cur_c delete $SAVE(id)
    }

    # start over again
    leave_mode wire

    setup_draw_wire

    return
  }

  # delete current line
  $cur_c delete $SAVE(id)

  # get information and then delete previous line
  set SAVE(id) [lindex $SAVE(ids) 0]
  setl {SAVE(x) SAVE(y)} [$cur_c coords $SAVE(id)]
  $cur_c delete $SAVE(id)

  set SAVE(id) [eval create_line $SAVE(x) $SAVE(y) $x $y]

  # remove previous line from list of ids
  set SAVE(ids) [lrange $SAVE(ids) 1 end]
  
  set id [lindex $SAVE(ids) 0]
  setl {x1 y1 x2 y2} [$cur_c coords $id]
  if {$y2 == "" || [nearby $x1 $y1 $x2 $y2]} {
    set SAVE(dir) ""

  } else {
    if {[nearby_num $x1 $x2]} {
      set SAVE(dir) H
    } elseif {[nearby_num $y1 $y2]} {
      set SAVE(dir) V
    } else {
      set SAVE(dir) B
    }
  }

  set SAVE(dirs) [lrange $SAVE(dirs) 1 end]

  # remove_connect_wire on the previous segment if there is one
  remove_connect_point $SAVE(x) $SAVE(y)
}


# makes a wire.  The outside world calls this procedure

proc make_wire {x1 y1 x2 y2} -type user -desc {

Primitive procedure to add a wire to the current schematic.  Wires
contain only two endpoints and hence are only one segment.  To create
wires with multiple segments, add multiple make_wire lines with the
segments overlapping at the endpoints.

USAGE: make_wire x1 y1 x2 y2

For example:

        sue> make_wire 100 200 180 200
        sue> make_wire 180 200 180 240

Wires will not automatically connect if the endpoint of one wire
intersects another one in the middle of the segment.  Thus, to make a
"T", you must specify 3 wire segements instead of 2.  To merge wires
that aren't connected solely by endpoints, follow them with
api_clean_connections.  Note that api_clean_connections is a slow
operation so should only be used sparingly.

Here is an example of a "T" junction:

        sue> make_wire 100 200 180 200
        sue> make_wire 180 200 250 200
        sue> make_wire 180 200 180 240

Which can also be done this way, but will be much slower:

        sue> make_wire 100 200 250 200
        sue> make_wire 180 200 180 240
        sue> api_clean_connections

NOTE: this procedure can only be used on a new schematic or if
proceeded by api_zoom setup.  Otherwise, its position may be incorrect
or even off-grid.

DO NOT use this to add wires to the icon view of cell.  Wires do not
belong in icon views.

NOT UN-DOABLE

} {

  global cur_c COLORS

  $cur_c create line $x1 $y1 $x2 $y2 -tags wire -fill $COLORS(fore)
}


# could be merged into make_wire but isn't since we wat make_wire to
# be as fast as possible.

proc make_wire_selected {x1 y1 x2 y2 {selected ""}} {

  global cur_c COLORS

  if {$selected == ""} {
    return [$cur_c create line $x1 $y1 $x2 $y2 -tags wire -fill $COLORS(fore)]
  } else {
    return [$cur_c create line $x1 $y1 $x2 $y2 -tags "wire selected" \
		-fill $COLORS(selected)]
  }
}


proc rubber_band_wire {x y} {

  global cur_c scale SAVE COLORS

  if {$SAVE(zoom)} {
    # ignore rubber banding until zoom is over
    return
  }

  if {[info exists SAVE(id)] != 1} {
    return
  }

  # remove the old wire segment
  $cur_c delete $SAVE(id)

  # stretch previous wire if there is one and its manhattan
  if {$SAVE(ids) != "" && [lindex $SAVE(dirs) 0] != "B"} {

    set id [lindex $SAVE(ids) 0]

    if {$SAVE(dir) == "V"} {
      if {$SAVE(x) == ""} {
	set SAVE(x) $x
      }
      stretch_wire $id end [expr $x - $SAVE(x)] 0
      set SAVE(x) $x

    } elseif {$SAVE(dir) == "H"} {
      if {$SAVE(y) == ""} {
	set SAVE(y) $y
      }
      stretch_wire $id end 0 [expr $y - $SAVE(y)]
      set SAVE(y) $y
    }
  }

  # remake the wire segment with the new coords
  set SAVE(id) [create_line $SAVE(x) $SAVE(y) $x $y]

  draw_wire_mark_closest $x $y

  # Do it now
  #update idletasks
}


proc draw_wire_mark_closest {x y} {

  global cur_c COLORS

  # mark the closest unconnected thingy
  if {![catch {$cur_c find closest $x $y -tag wire_to} msg] && $msg != ""} {
    # first, lose the old mark
    $cur_c delete closest
    # now make an x at the closest terminal position
    set coords [center $msg]
    set extent 10
    $cur_c create line [expr [lindex $coords 0] - $extent] \
	[expr [lindex $coords 1] - $extent] \
	[expr [lindex $coords 0] + $extent] \
	[expr [lindex $coords 1] + $extent] \
	-tags "tmp closest" -fill $COLORS(anchor)
    $cur_c create line [expr [lindex $coords 0] - $extent] \
	[expr [lindex $coords 1] + $extent] \
	[expr [lindex $coords 0] + $extent] \
	[expr [lindex $coords 1] - $extent] \
	-tags "tmp closest" -fill $COLORS(anchor)
  }
}


# Internal procedures that draws lines.  If the lines are manhattan, it
# figures out the correct coords (the mouse is only correct on one coord). 
# The correct coords are stored in SAVE(nx) and SAVE(ny).

proc create_line {x1 y1 x2 y2} {

  global cur_c SAVE COLORS

  if {$SAVE(HV) == 1} {
    # determine whether to be a horizontal or a vertical line
    if {[expr abs($x1-$x2)] >= [expr abs($y1-$y2)]} {
      set SAVE(nx) $x2
      set SAVE(ny) $y1

      if {$SAVE(dir) == "B"} {
	set SAVE(dir) "H"
      }

      return [$cur_c create line $x1 $y1 $x2 $y1 -tag tmp -fill $COLORS(fore)]

    } else {
      set SAVE(nx) $x1
      set SAVE(ny) $y2

      if {$SAVE(dir) == "B"} {
	set SAVE(dir) "V"
      }

      return [$cur_c create line $x1 $y1 $x1 $y2 -tag tmp -fill $COLORS(fore)]
    }

  } else {
    set SAVE(nx) $x2
    set SAVE(ny) $y2
    set SAVE(dir) "B"
    return [$cur_c create line $x1 $y1 $x2 $y2 -tag tmp -fill $COLORS(fore)]
  }
}


# given a wire id and the end from which to stretch (either "begin" or "end")
# stretch the wire appropriately

proc stretch_wire {id end dx dy} {

  global cur_c

  set coords [$cur_c coords $id]
  if {$coords == ""} {
    return
  }

  if {$end == "begin"} {
    $cur_c coords $id [expr [lindex $coords 0] + $dx] \
	[expr [lindex $coords 1] + $dy] [lindex $coords 2] [lindex $coords 3]
  } else {
    $cur_c coords $id [lindex $coords 0] [lindex $coords 1] \
	    [expr [lindex $coords 2] + $dx] [expr [lindex $coords 3] + $dy] 
  }
}
