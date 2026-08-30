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


# delete_selected removes all netlist and drawing objects which are selected
# or just removes an optional id if given

proc delete_selected {{ids ""} {no_undo ""} {batch ""}} {

  global cur_c cur_s
  
  modify_setup

  if {$batch == ""} {
    busy
  }

  # waste any edit markers, anchors, or other temporary items
  $cur_c delete tmp

  if {$ids == ""} {
    set ids [$cur_c find withtag selected]
    set tag selected
  } else {
    set tag delete
    foreach id $ids {
      $cur_c addtag delete withtag $id
    }
  }


  if {[is_icon $cur_s] || [is_placement $cur_s]} {
    # much simpler case

    # save what is going to be deleted so it can be restored using undo
    if {$no_undo == ""} {
      delete_selected_undo undo $tag
    }

    if {$tag == "delete"} {
      $cur_c dtag delete
    }

    set changed 0

    foreach id $ids {
      if {[$cur_c type $id] == ""} {
	# already been deleted
	continue
      }

      # delete instances
      if {[is_tagged $id origin]} {
	# delete old icon and lose the old data structure
	$cur_c delete inst$id
	global ${cur_s}_inst$id
	unset ${cur_s}_inst$id

	set changed 1
	continue
      }

      if {[is_tagged $id draw_item] && [is_tagged $id origin_icon]} {
	# don't allow the origin of the icon to be deleted
	continue
      }

      $cur_c delete $id
      set changed 1
    }

    if {$changed} {
      # flag that this canvas has been modified
      is_modified
    }

    display_selection
    if {$batch == ""} {
      ready
    }
    return
  }

  integer_scale

  # special case of deleting the "dot" that connects two intersecting
  # wires.
  if {[lindex $ids 1] == "" && [is_tagged $ids dot]} {
    # this is probably the right case, see if it contains the endpoints
    # of four and only four wires

    set overlap_ids [eval $cur_c find overlapping [$cur_c coords $ids]]

    setl {xc yc} [center $ids]
    set count 0
    foreach overlap_id $overlap_ids {

      if {[is_tagged $overlap_id wire]} {
	setl {x1 y1 x2 y2} [round_list [$cur_c coords $overlap_id]]
	if {[nearby $xc $yc $x1 $y1]} {
	  if {$x1 == $x2} {
	    set slope inf
	  } else {
	    set slope [expr round(100.0 * ($y2 - $y1)/($x2 - $x1))]
	  }
	  lappend data($slope) "$overlap_id $x2 $y2"
	  incr count
	} elseif {[nearby $xc $yc $x2 $y2]} {
	  if {$x1 == $x2} {
	    set slope inf
	  } else {
	    set slope [expr round(100.0 * ($y2 - $y1)/($x2 - $x1))]
	  }
	  lappend data($slope) "$overlap_id $x1 $y1"
	  incr count
	}
      }
    }

    # we should have two sets of slopes, if so merge wires and 
    # waste the dot.
    if {$count == 4 && [llength [array names data]] == 2} {
      # waste dot
      $cur_c delete $ids

      setl {slope1 slope2} [array names data] 
      
      setl {wire1 wire2} $data($slope1)
      setl {wire3 wire4} $data($slope2)
      
      # setup undo stuff
      $cur_c addtag delete withtag [lindex $wire1 0]
      $cur_c addtag delete withtag [lindex $wire2 0]
      $cur_c addtag delete withtag [lindex $wire3 0]
      $cur_c addtag delete withtag [lindex $wire4 0]

      global PROC
      set PROC ""
      write_wires delete undo
      set save_proc $PROC

      # delete old wires
      $cur_c delete [lindex $wire1 0]
      $cur_c delete [lindex $wire2 0]
      $cur_c delete [lindex $wire3 0]
      $cur_c delete [lindex $wire4 0]

      # make two new wire
      set ids [eval make_wire [lrange $wire1 1 2] [lrange $wire2 1 2]]
      lappend ids [eval make_wire [lrange $wire3 1 2] [lrange $wire4 1 2]]

      unscale

      setup_undo $ids $save_proc

      select_ids $ids
      
      # flag that this canvas has been modified
      is_modified

      if {$batch == ""} {
	ready
      }
      return
    }
  }

  # people like to delete opens and watch the wire disappear, so...
  foreach id [get_intersect_tag $tag open] {
    set coords [$cur_c coords $id]
    set center [center $id]

    set wire_ids [eval $cur_c find overlapping [lrange $coords 0 1] \
		      [lrange $coords 4 5]]
    foreach wire_id $wire_ids {
      if {[is_tagged $wire_id wire]} {
	set wire_coords [$cur_c coords $wire_id]
	if {[eval nearby $center [lrange $wire_coords 0 1]]} {
	  $cur_c addtag $tag withtag $wire_id
	  lappend ids $wire_id
	  break
	}
	if {[eval nearby $center [lrange $wire_coords 2 3]]} {
	  $cur_c addtag $tag withtag $wire_id
	  lappend ids $wire_id
	  break
	}
      }
    }
  }

  # save what is going to be deleted so it can be restored using undo
  if {$no_undo == ""} {
    delete_selected_undo undo $tag
  }

  if {$tag == "delete"} {
    $cur_c dtag delete
  }

  set changed 0

  foreach id $ids {
    if {[$cur_c type $id] == ""} {
      # already been deleted
      continue
    }

    # delete instances, remember term coords for updating show connect 
    if {[is_tagged $id origin]} {
      foreach term_id [get_intersect_tag inst$id term] {
	set show_coords([round_list [center $term_id]]) 1
      }

      # delete old icon and lose the old data structure
      $cur_c delete inst$id
      global ${cur_s}_inst$id
      unset ${cur_s}_inst$id

      set changed 1
      continue
    }

    # delete wires, remember end coords for connection info
    if {[is_tagged $id wire]} {
      set coords [$cur_c coords $id]
      set show_coords([round_list [lrange $coords 0 1]]) 1
      set show_coords([round_list [lrange $coords 2 3]]) 1
      $cur_c delete $id

      set changed 1
      continue
    }

    # delete edit_markers along with drawing objects
    if {[is_tagged $id draw_item]} {
      # don't allow the origin of the icon to be deleted
      if {[is_tagged $id origin_icon]} {
	continue
      }

      $cur_c delete $id

      set changed 1
      continue
    }
  }

  # update the nodes on the connection points
  if {[info exists show_coords]} {
    foreach xy [array names show_coords] {
      eval show_connect_point $xy clean
    }
  }

  unscale

  if {$changed} {
    # flag that this canvas has been modified
    is_modified
  }

  display_selection
  if {$batch == ""} {
    ready
  }
}


# save what is selected so that it can be recreated for either undo
# or copy to clipboard

proc delete_selected_undo {{mode undo} {tag selected}} {

  global PROC cur_c scale

  if {$mode == "undo"} {
    modify_setup
  }

  set PROC ""
  if {$mode == "undo"} {
    # already scaled if undo -- should be but not in icons, etc.
    if {$scale != [expr int($scale)]} {
      integer_scale

      lappend NEW_PROC "global cur_c cur_s scale COLORS"
      write_instances $tag "" icon_undo
      write_wires $tag icon_undo
      write_draw_items $tag icon_undo
      set int_scale $scale

      unscale
    } else {

      lappend NEW_PROC "global cur_c cur_s scale COLORS"
      write_instances $tag "" icon_undo
      write_wires $tag icon_undo
      write_draw_items $tag icon_undo
      set int_scale $scale
    }

  } else {
    integer_scale
    write_instances $tag
    write_wires $tag
    write_draw_items $tag
    set int_scale $scale
    unscale
  }

  if {$PROC == ""} {
    # nothing is there
    return
  }

  # NOTE that this will select all of these icons even if they weren't
  # originally selected

  lappend NEW_PROC "set save_scale \$scale"
  lappend NEW_PROC "scale_canvas $int_scale"
  lappend NEW_PROC "set ids {}"
  foreach line $PROC {
    lappend NEW_PROC "lappend ids \[$line\]"
  }

  lappend NEW_PROC "select_ids \$ids"
  lappend NEW_PROC "scale_canvas \$save_scale"

  if {$mode == "undo"} {
    lappend NEW_PROC "update"
    lappend NEW_PROC "integer_scale"
    lappend NEW_PROC "show_connects selected"
    lappend NEW_PROC "unscale"

    # define the procedure that undoes the delete
    proc undo {} [join $NEW_PROC "\n"]

    unset PROC

    # now save away this proc
    save_undo

  } else {
    # write the paste procedure to a file
    global CLIPBOARD_FILE

    # open file
    if {[catch "open $CLIPBOARD_FILE w" msg] != 0} {
      # error, probably can't write to directory
      puts "CLIPBOARD ERROR, $msg"
      return
    }

    set file_id $msg

    # undo stuff
    lappend NEW_PROC {setup_undo $ids ""}

    # write out statements
    puts $file_id [join $NEW_PROC "\n"]

    # close file
    close $file_id

    if {$mode == "cut_to_clipboard"} {
      puts "Cut selected to clipboard."
    } else {
      puts "Copied selected to clipboard."
    }
  }
}


# routines for dropping (adding) icons into schematics

proc setup_drop_icon {{icon ""}} {

  global cur_c SNAP_XY auto_index __MAKE_SPECIAL__

  modify_setup

  if {$icon == ""} {
    return
  }

  enter_mode icon abort_icon_mode

  msg_window "Button-1 drops $icon and ends, Ctrl-c aborts."

  # if this is a generator, possibly look up name for icon
  upvar #0 icon_$icon g_data

  if {![info exists g_data(creator)]} {
    # never been made before, don't know if it's a generator
    # try making it

    global _ICON_
    catch {unset _ICON_}
    set _ICON_(icon) instance
    set _ICON_(tag) "icon inst\$id"
    set _ICON_(type) $icon

    if {[catch {ICON_$icon ""} msg]} {
      # not a generator
    }

    unset _ICON_
  }

  if {[info exists g_data(generator)]} {
    # Check that this is the correct NAME proc and if so execute
    if {[use_first auto_index(ICON_$icon)] == [use_first auto_index(NAME_$icon)] \
	  && ![catch NAME_$icon msg] && $msg != ""} {
      # worked, got a non-nil name.  Hope it is unique
      set name $msg

      # make sure this has been generated
      if {[generate $icon $name] == 0} {
	# generator errored out
	leave_mode icon
	sue_error flush
	return
      }

      # update this
      make_icon_listbox

      # this is now what we are going to drop
      set icon $name
    }
  }

  set __MAKE_SPECIAL__ 1
  set id [make $icon]
  set __MAKE_SPECIAL__ 0
  if {$id == ""} {
    leave_mode icon

    warning "Aborting drop icon.  No icon for cell $icon"
    return
  }
  select_id $id

  # select_id resets this
  msg_window "Button-1 drops $icon and ends, r rotates, x flips sideways, y flips upsidedown, Ctrl-c aborts."

#  bind_add -mode icon -hotkey B1-Motion -command "move_icon $SNAP_XY"

  bind_add -mode icon -hotkey Motion \
      -command "move_icon $SNAP_XY" \
      -help "Move icon."

  bind_add -mode icon -hotkey r \
      -command "transform_drop_icon ROTATE" \
      -help "Rotate icon."

  bind_add -mode icon -hotkey x \
      -command "transform_drop_icon MX" \
      -help "Flip the icon left-to-right."

  bind_add -mode icon -hotkey y \
      -command "transform_drop_icon MY" \
      -help "Flip the icon upsidedown."

  bind_add -mode icon -hotkey Button-1 \
      -command "end_icon_mode" \
      -help "Add icon at position.  End."

  bind_add -mode icon -hotkey Control-c \
      -command "abort_icon_mode" \
      -help "Abort adding icon."

  bind_add -mode icon -hotkey z \
      -command "drop_icon_zoom $SNAP_XY 1.5" \
      -help "Zoom in on cursor."

  bind_add -mode icon -hotkey Z \
      -command "drop_icon_zoom $SNAP_XY 0.7" \
      -help "Zoom out on cursor."

  bind_add -mode icon -hotkey space -command "help_window %x %y" \
      -help "Display this window."
}


proc move_icon {x y} {

  global cur_c

  set id [lindex [$cur_c find withtag selected] 0]
  set origin_id [find_origin $id]

  set coords [lrange [$cur_c coords $origin_id] 0 1]

  $cur_c move selected [expr $x - [lindex $coords 0]] \
      [expr $y - [lindex $coords 1]]
}


proc drop_icon_zoom {x y {zoom ""}} {

  eval zoom_on_cursor $x $y $zoom doit
}


# transform (e.g. rotate, flip) the icon before dropping it.

proc transform_drop_icon {dir} {

  global cur_s cur_c XFORM

  set id [find_origin [lindex [$cur_c find withtag selected] 0]]
  if {$id == ""} {
    # shouldn't happen
    return
  }

  upvar #0 ${cur_s}_inst$id i_data
  set orient $i_data(orient)

  # set the new orientation
  set i_data(orient) $XFORM($dir,$orient)

  remake $id $id "" "" no_show
}


proc end_icon_mode {} {

  global cur_s

  # show connection info on new icon unless we are in an icon
  if {![is_icon $cur_s] && ![is_placement $cur_s]} {
    integer_scale
    show_term_connects selected
    unscale
  }

  # save undo information
  setup_undo [get_intersect_tag selected origin] ""

  # flag that this canvas has been modified
  is_modified

  leave_mode icon
}

proc abort_icon_mode {} {

  global cur_c

  # it would be nice if this reselected previously selected -- later
  $cur_c delete selected

  leave_mode icon
}


# reconcile IO terminals between the current cell and its corresponding 
# cell if there is one.  Complicated by buses.

proc reconcile_ios {new_id old_name} {

  global cur_s cur_c scale SUE

  upvar #0 ${cur_s}_inst$new_id new_i_data
  set type $new_i_data(type)

  set range ""
  set range_type ""
  set max_width 0

  if {[lsearch "input output inout" $type] != -1} {
    set name $new_i_data(_name)
    set busroot [bus_root $name]
    set define 0

    if {[is_bus $name]} {
      if {![valid_bus $name]} {
	# must be a define
	set define 1
      } else {
	# figure out the range of this bus in this view
	foreach id [$cur_c find withtag icon_$type] {
	  upvar #0 ${cur_s}_inst$id i_data
	  set _name $i_data(_name)
	  if {[bus_root $_name] == $busroot} {
	    if {[valid_bus $_name]} {
	      lappend range $_name
	      set max_width [max $max_width [bus_width $_name]]
	    }
	  }
	}
	if {$range != ""} {
	  if {[bus_subset $name [bus_extent $range]]} {
	    set range_type "_MAX_"
	  }
	}
      }
    }

    # save the current canvas, schematic, and scale
    set save_cur_c $cur_c
    set save_cur_s $cur_s
    set save_scale $scale

    # look to see if the corresponding one is in a canvas yet
    set cell [corresponding_cell $cur_s]

    if {![info exists SUE($cell)]} {
      # put it in a canvas
      change_views 
      if {$cell != $cur_s} {
	# doesn't exist, punt
	return
      }
      update

      # change back
      change_views
    }

    set new 0

    # see if there is still a terminal with the old_name in the current cell
    foreach id [$cur_c find withtag icon_$type] {
      upvar #0 ${cur_s}_inst$id i_data
      if {$id != $new_id && $i_data(_name) == $old_name} {
	set new 1
	break
      }
    }

    # set up current canvas, schematic, and scale to corresponding cell
    set cur_s $cell
    upvar #0 SUE_$cur_s data
    set cur_c $data(canvas)
    set scale $data(scale)

    # if the new name is the same as a terminal in the corresponding cell
    # then don't add a new one.
    foreach id [$cur_c find withtag icon_$type] {
      upvar #0 ${cur_s}_inst$id i_data
      set _name $i_data(_name)

      if {$_name == $name} {
	# duplicate
	set new -1
	break
      }

      if {[bus_root $_name] == $busroot && !$define} {
	# same bus root
	set new -1

	if {[bus_subset $name $_name]} {
	  # subset, ignore
	  break
	}

	if {[bus_width $_name] > 1 && $range_type == "_MAX_"} {
	  # increase the range of this bus -- it might not be the
	  # biggest one but it is a bus...
	  if {$max_width == 1} {
	    # special case, use bit order of bus in $_name
	    setl {o1 o2} [bus_range $_name]
	    if {$o1 > $o2} {
	      set i_data(_name) $busroot[bus_extent "$name $range" down]
	    } else {
	      set i_data(_name) $busroot[bus_extent "$name $range" up]
	    }
	  } else {
	    set i_data(_name) $busroot[bus_extent "$name $range"]
	  }

	  remake $id $id
#	  do_other_canvas $cell {remake $id $id}
	  break
	}
      }
    }

    if {$new == 0} {
      # try to find the terminal with the same previous name and rename it
      foreach id [$cur_c find withtag icon_$type] {
	upvar #0 ${cur_s}_inst$id i_data
	if {$i_data(_name) == $old_name} {
	  # got it
	  set i_data(_name) $name

	  remake $id $id
#	  do_other_canvas $cell {remake $id $id}
	  set new -1
	}
      }
    }

    if {$new != -1} {
      # make a new IO in the corresponding cell
      if {[is_icon $cur_s]} {
	# put new I/O's at origin in icons
	set id [make $type -name $name]
      } else {
	# put new I/O's at lower left corner in schematics
	$cur_c addtag object all
	$cur_c dtag grid object
	setl {x1 y1 x2 y2} [round_list_scale [$cur_c bbox object] $scale]
	$cur_c dtag object
	if {$y2 == ""} {
	  # must be empty
	  set x 0
	  set y 0
	} else {
	  set x [expr $x1 - 5*$scale]
	  set y $y1
	}

	set id [make $type -origin "$x $y" -name $name]
      }

#      set id [do_other_canvas $cell {make $type -name $name}]
    }
    
    is_modified
    remember_modified

    # restore the current canvas, schematic, and scale
    set cur_c $save_cur_c
    set cur_s $save_cur_s
    set scale $save_scale
  }
}


# NOT USED

proc do_other_canvas {cell command} {

  global cur_s cur_c scale SUE

  # save the current canvas, schematic, and scale
  set save_cur_c $cur_c
  set save_cur_s $cur_s
  set save_scale $scale

  # change to the new canvas, schematic, and scale
  set cur_s $cell
  upvar #0 SUE_$cur_s data
  set cur_c $data(canvas)
  set scale $data(scale)

puts $command
  # do the command
  set result [uplevel $command]
puts $result

  # restore the current canvas, schematic, and scale
  set cur_c $save_cur_c
  set cur_s $save_cur_s
  set scale $save_scale

  return $result
}
