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


# Selection stuff


proc _select {tag} {

  global cur_c cur_s

  $cur_c addtag selected withtag $tag
  if {[is_fp $cur_s]} {
    fp_display_flylines
  }
}


# selects what's under the cursor, bound to Button-1

proc icon_select {{add ""}} {

  global cur_c cur_s DISABLE_CANVAS_EVENT

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1

  set id [$cur_c find withtag current]
  select_id $id $add
}


# Deselects everything and then selects the given id.
# if the optional add is given, only adds to selection or
# unselects if already selected

proc select_id {id {add ""}} {

  global cur_c cur_s scale COLORS

  # get rid of any edit markers, and other temp. stuff
  $cur_c delete tmp

  set tag [find_origin_tag $id]

  # in "special" mode, if the object is already selected, just return
  if {$add == "special"} {
    if {[is_tagged $id selected]} {
      return
    } else {
      # see if anything nearby is selected
      if {$scale < 5} {
	# only do this if scale is small
	set id [find_origin_tag $id]
	setl {x y} [center_bbox [$cur_c bbox $id]]
	# look +/- 3 pixles
	set p 3
	foreach close_id [$cur_c find overlapping [expr $x - $p] \
			      [expr $y - $p] [expr $x + $p] [expr $y + $p]] {
	  if {[is_tagged $close_id selected]} {
	    # close enough, use it
	    return
	  }
	}
      }

      # selected current
      set add ""
    }
  }

  if {$add == ""} {
    # deselect everything
    show_color selected $COLORS(fore)
    $cur_c dtag selected

    # select 
    _select $tag

    # change color to show selected
    if {[is_tagged $id current]} {
      show_color $tag $COLORS(selected,active)
    } else {
      show_color $tag $COLORS(selected)
    }

  } else {
    # in add selection mode, deselect if selected
    if {[is_tagged $id selected]} {
      # unselect 
      $cur_c dtag $tag selected
      if {[is_tagged $id current]} {
	show_color $tag $COLORS(active)
      } else {
	show_color $tag $COLORS(fore)
      }

    } else {
      # select 
      _select $tag

      # change color to show selected
      if {[is_tagged $id current]} {
	show_color $tag $COLORS(selected,active)
      } else {
	show_color $tag $COLORS(selected)
      }
    }
  }

  display_selection
}


# deselects all then selects all ids given

proc select_ids {ids {add ""} {no_display ""}} {

  global cur_c cur_s COLORS

  # deselect everything
  if {$add == ""} {
    # get rid of any edit markers, and other temp. stuff
    $cur_c delete tmp

    show_color selected $COLORS(fore)
    $cur_c dtag selected
  }

  foreach id $ids {
    if {![is_tagged $id selected]} {
      set tag [find_origin_tag $id]

      # select 
      _select $tag
    }
  }

  # change color to show selected
  show_color selected $COLORS(selected)
  
  if {$no_display == ""} {
    display_selection
  }
}


# displays selection in message box

proc display_selection {{name ""}} {

  global cur_c cur_s DISPLAY_COORDS

  set sel_id [lindex [$cur_c find withtag selected] 0]
  if {$sel_id == ""} {
    # nothing selected
    msg_window "" no_save
    return
  }

  if {$name != ""} {
    msg_window "selected: $name" no_save
    return
  }

  set id [find_origin $sel_id]

  upvar #0 ${cur_s}_inst${id} i_data
  set name [use_first i_data(_name)]

  set type [find_type $id]

  if {$type == "text draw_item"} {
    # special case for text
    set tags [$cur_c gettags $id]
    set size [split [lindex $tags [lsearch $tags "size_*"]] _]
    set net "($size)"

  } else {
    set net [display_local_net]
    if {$net != ""} {
      set net "($net)"
    }
  }

  if {[use_first DISPLAY_COORDS] != ""} {
    set coords [sue_coords $id]
  } else {
    set coords ""
  }

  msg_window "selected: $type $name \#$id $net $coords" no_save
}


# returns the type and orientation of the id.

proc find_type {id} {

  global cur_c cur_s

  if {[is_tagged $id origin]} {
    set tags [$cur_c gettags $id]
    set name [string range [lindex $tags [lsearch $tags "icon_*"]] 5 end]

    upvar #0 ${cur_s}_inst${id} i_data

    if {[is_generator $name]} {
      return "$name (generator) [use_first i_data(orient)]"
    } else {
      return "$name [use_first i_data(orient)]"
    }
  }

  if {[is_tagged $id wire]} {
    return wire
  }

  if {[is_tagged $id origin_icon]} {
    return origin
  }

  if {[is_tagged $id draw_item]} {
    set type [$cur_c type $id]
    return "$type draw_item"
  }

  if {[is_tagged $id open]} {
    return open
  }

  if {[is_tagged $id dot]} {
    return dot
  }
}


# procedures for stroking out a rectangle on the canvas and 
# selecting what's inside of the stroked out rectangle

proc setup_select_region {x y {add ""}} {

  global cur_c scale COLORS SAVE
  global DISABLE_CANVAS_EVENT NOSNAP_XY SNAP_XY

  # Don't do anything if event already handled by a canvas item
  if {$DISABLE_CANVAS_EVENT == 1} {
    set DISABLE_CANVAS_EVENT 0
    return
  }

  enter_mode select_region

  # get rid of any edit markers, and other temp. stuff
  $cur_c delete tmp

  set SAVE(x) $x
  set SAVE(y) $y

  set SAVE(lastx) $x
  set SAVE(lasty) $y

  set SAVE(zoom) 0
  set SAVE(scale) $scale
  set SAVE(mode) 0
  set SAVE(add) $add

  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb1"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb2"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb3"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb4"

  msg_window "Drag select box, Tab bar moves box, Ctrl-C aborts"

  bind_add -mode select_region -hotkey Any-B1-Motion \
      -command "select_region_drag $NOSNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Draw select region."

  bind_add -mode select_region -hotkey Any-B1-ButtonRelease \
      -command "end_select_region; set SCROLL(status) off" \
      -help "End select region."

  bind_add -mode select_region -hotkey Any-Control-c \
      -command "abort_select_region; set SCROLL(status) off" \
      -help "Abort select region command."

  bind_add -mode select_region -hotkey z \
      -command "select_box_zoom $SNAP_XY 1.5" \
      -help "Zoom in on cursor."

  bind_add -mode select_region -hotkey Z \
      -command "select_box_zoom $SNAP_XY 0.7" \
      -help "Zoom out on cursor."

  # toggle mode with shift key
  bind_add -mode select_region -hotkey Any-Tab \
      -command {toggle SAVE(mode) $IDIOT_DELAY} \
      -help "Toggle modes between draging select box and translating select box."

  bind_add -mode select_region -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  if {[string first add $add] == -1} {
    # deselect everything
    show_color selected $COLORS(fore)
    $cur_c dtag selected

    update idletasks
  }
}


# drags the stroke box
# Uses the hack of moving each edge of the stroke box and then doing an
# update idletasks so that the entire bbox of the stroke box never has
# to be redrawn.  The additional overhead of the update is worth it.

proc select_region_drag {x y} {

  global cur_c SAVE

  if {![info exists SAVE(mode)]} {
    # if you got here on mistake
    abort_select_region
    return
  }

  if {$SAVE(zoom) == 1} {
    return
  }

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


proc end_select_region {} {

  global cur_c COLORS SAVE
  
  # select everything totally enclosed by the stroke bbox
  set bbox [$cur_c bbox stroke_box]

  # delete the dragged box since no longer needed
  $cur_c delete stroke_box

  if {[string first overlap [use_first SAVE(add)]] != -1} {
    select_overlap_bbox $bbox
  } else {
    select_in_bbox $bbox
  }

  show_color selected $COLORS(selected)

  display_selection

  leave_mode select_region
}

proc abort_select_region {} {

  global cur_c

  # delete the dragged box since no longer needed
  $cur_c delete stroke_box

  leave_mode select_region
}


# selects stuff that is TOTALLY inside the bbox
# doesn't select opens.

proc select_in_bbox {bbox} {

  global cur_c

  if {$bbox == ""} {
    return
  }

  busy

  eval $cur_c addtag enclosed enclosed $bbox

  # add selected to all enclosed of type wire, dot, or draw_item
  intersect_tag selected enclosed wire
  intersect_tag selected enclosed dot
  intersect_tag selected enclosed draw_item

  setl {x1 y1 x2 y2} $bbox

  # icon can have parts of them enclosed, ignore those
  foreach id [get_intersect_tag enclosed origin] {

    # don't include the text in the bbox
    $cur_c addtag xxx withtag inst$id
    $cur_c dtag scaletext xxx
    set instbbox [$cur_c bbox xxx]
    $cur_c dtag xxx

    # select an inst only if fully enclosed by original bbox
    if {[lindex $instbbox 0] > $x1 && [lindex $instbbox 1] > $y1 && \
	    [lindex $instbbox 2] < $x2 && [lindex $instbbox 3] < $y2} {
      _select inst$id
    }
  }

  $cur_c dtag enclosed

  ready
}


# selects stuff that is inside OR overlaps the bbox
# doesn't select opens.

proc select_overlap_bbox {bbox} {

  global cur_c

  if {$bbox == ""} {
    return
  }

  busy

  eval $cur_c addtag enclosed overlapping $bbox

  # add selected to all enclosed of type wire, dot, or draw_item
  intersect_tag selected enclosed wire
  intersect_tag selected enclosed dot
  intersect_tag selected enclosed draw_item

  setl {x1 y1 x2 y2} $bbox

  # make sure all of icon is selected if any part is selected
  foreach id [get_intersect_tag enclosed icon] {

    set tag [find_origin_tag $id]
    if {[info exists trace($tag)]} {
      # already been here
      continue
    }

    # ignore text in icons
    if {[$cur_c type $id] == "text"} {
      continue
    }

    set trace($tag) 1

    _select $tag
  }

  $cur_c dtag enclosed

  ready
}


# zoom when selecting a region

proc select_box_zoom {x y {zoom ""}} {

  global SAVE scale cur_c

  # turn off motion
  set SAVE(zoom) 1

  eval zoom_on_cursor $x $y $zoom doit

  # scale saved stuff
  set mult [expr 1.0 * $scale / $SAVE(scale)]

  set SAVE(x) [expr $SAVE(x) * $mult]
  set SAVE(y) [expr $SAVE(y) * $mult]
  set SAVE(lastx) [expr $SAVE(lastx) * $mult]
  set SAVE(lasty) [expr $SAVE(lasty) * $mult]

  # save the new scale
  set SAVE(scale) $scale

  # turn on motion again
  set SAVE(zoom) 0
}


# selects the entire wire connected to the segment under the cursor
# if branch is non-nil, then the segment only up to the first solder dot is
# selected

# traces connectivity

proc select_entire_wire {{type branch}} {

  global cur_c cur_s DISABLE_CANVAS_EVENT TRACE

  # stop general canvas binding events 
  # (required since called from double-button)
  set DISABLE_CANVAS_EVENT 1

  busy
  integer_scale

  catch {unset TRACE}

  set id [$cur_c find withtag current]

  if {[is_tagged $id wire]} {
    set TRACE($id) 1

    set coords [$cur_c coords $id]
    eval find_attached_wire [lrange $coords 0 1] $type
    eval find_attached_wire [lrange $coords 2 3] $type

  } elseif {[is_tagged $id dot] || [is_tagged $id open]} {
    eval find_attached_wire [center $id] $type
  }

  # finally select everything found
  select_ids [array names TRACE]

  unscale
  ready

  return
}


# find_attached_wire works with and is dependent on select_entire_wire

proc find_attached_wire {x y type} {

  global cur_c cur_s scale WIRES WIRE_NAME TRACE
  upvar #0 TERMS_$cur_s TERMS

  set del [expr $scale/3.0]
  set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
	      [expr $x + $del] [expr $y + $del]]

  if {$type == "no_branch"} {
    # stop when you hit a dot (i.e. wire splits)
    foreach id $ids {
      if {[is_tagged $id dot]} {
	return
      }
    }
  }

  foreach id $ids {
    if {[info exists TRACE($id)]} {
      # already got this one
      continue
    }

    if {[is_tagged $id wire]} {
      set TRACE($id) 1

      # this is the slow braindead way of doing it, but it's easy...
      set coords [$cur_c coords $id]
      eval find_attached_wire [lrange $coords 0 1] $type
      eval find_attached_wire [lrange $coords 2 3] $type
    }
  }
}


# like select by name but only selects correct bits on a bus
# NOTE: doesn't select dots or opens

# name cannot be a concatenated bus

proc select_wire_by_name {{name ""} {add ""} {no_display ""}} {

  global cur_s cur_c scale DISABLE_CANVAS_EVENT

  upvar #0 TERMS_$cur_s TERMS
  upvar #0 RTERMS_$cur_s RTERMS

  find_by_name ""

  if {$name == ""} {
    # stop general canvas binding events
    set DISABLE_CANVAS_EVENT 1

    set id [$cur_c find withtag current]

    if {[is_tagged $id dot] || [is_tagged $id open]} {
      # need to get nearest wire/term for name
      integer_scale

      set del [expr $scale/3.0]
      set ids [$cur_c find overlapping [expr $x - $del] [expr $y - $del] \
		   [expr $x + $del] [expr $y + $del]]

      set id -1
      foreach test_id $ids {
	if {[is_tagged $test_id wire] || [is_tagged $test_id term]} {
	  set id $test_id
	  break
	}
      }

      unscale

    } elseif {![is_tagged $id wire]} {
      # if this is an icon with one terminal, use
      set id [find_origin $id]
      if {[is_tagged $id origin]} {
	set id [get_intersect_tag inst$id term]
	if {[llength $id] != 1} {
	  return 0
	}
      } else {
	return 0
      }
    }

    if {[info exists TERMS($id)]} {
      set name $TERMS($id)
    } else {
      return 0
    }
  }

  set ids ""
  set term_ids ""

  set orig_name $name
  foreach name [split $orig_name ,] {

    set root [bus_root $name]

    foreach one [concat [array names RTERMS $root] [array names RTERMS $root\\\[*]] {

      foreach id $RTERMS($one) {

	if {[info exists TERMS($id)] && \
		![cbus_subset $orig_name $TERMS($id)]} { 
	  # ignore this
	  continue
	}

	if {[is_tagged $id term]} {
	  # if this has only one terminal select it
	  set term_id [get_intersect_tag "inst[find_origin $id]" term]
	  if {[lindex $term_id 1] != ""} {
	    # more than one term, don't select whole instance
	    lappend term_ids $id
	    continue
	  }
	}

	lappend ids $id
      }
    }
  }

  if {$ids == "" && $term_ids != ""} {
    # stub
    foreach term_id $term_ids {
      global cur_c scale COLORS
      setl {x y} [center $term_id]
      $cur_c create arc [expr $x-$scale] [expr $y-$scale] \
	  [expr $x+$scale] [expr $y+$scale] -outline $COLORS(anchor) \
	  -tags "tmp sel_terms" -start 0 -extent 359.9 -width 2 -style arc
    }

    if {$no_display == ""} {
      msg_window "stub net \"$name\"" no_save
    }

    return 1

  } elseif {$ids != ""} {
    select_ids $ids $add $no_display

    if {$no_display == ""} {
      msg_window "selected net \"$name\"" no_save
    }

    return 1
  }

  return 0
}


# brings up a pop-up and asks the user for the name of a net or instance
# in the current schematic.  Highlights if found.  Note that this will
# accept the "*" as a wildcard.

proc select_by_name {{name {}} {mode interactive} {by_type 0}} {

  global cur_c cur_s COLORS

  if {$name == ""} {
    # call a pop up
    set title "Select By Name:"
    set message "Enter net or instance name:" 

    set prop_list ""

    lappend prop_list "Name name -entry -help {Text to search for.  Accepts the \"*\" wilcard.}"

    lappend prop_list "{Search by instance type} by_type -binary -help {If true (1), only searches instances and by instance type only.}"

    # create the menu
    if {![prop_menu2 -message $message -title $title $prop_list]} {
      # cancelled
      return ""
    }
  }

  if {$mode == "interactive"} {
    busy
  }

  if {$by_type} {
    if {$mode == "interactive"} {
      # deselect all
      select_id ""
    }

    if {[string first * $name] != -1} {
      # wild card search
      set ids ""
      foreach id [$cur_c find withtag origin] {
	if {[lsearch [$cur_c gettags $id] icon_$name] != -1} {
	  lappend ids $id
	}
      }
    } else {
      set ids [$cur_c find withtag icon_$name]
    }

    select_ids $ids add no_display
    display_selection "type: $name"

    if {$mode == "interactive"} {

      # zoom to fit around selected and/or terminals (labeled sel_terms)
      $cur_c addtag zoom withtag selected
      $cur_c addtag zoom withtag sel_terms

      set bbox [$cur_c bbox zoom]
      if {$bbox == ""} {
	ready
	return 0
      }

      zoom_to_bbox [$cur_c bbox zoom] 20
      eval center_canvas [center_bbox [$cur_c bbox zoom]]

      $cur_c dtag zoom 
      ready 
    }

    return 1
  }

  if {[$cur_c gettags inst$name] != ""} {
    # the user is asking for an id
    set ids $name
    set by_id 1

  } else {
    set ids [find_by_name $name all $mode]
    set by_id 0
  }

  if {$ids == ""} {
    if {$mode == "interactive"} {
      sue_error "Aborting, couldn't find net or instance with name \"$name\"."
      sue_error flush

      ready
    }
    return 0
  }

  if {$mode == "interactive"} {
    # deselect all
    select_id ""
  }

  upvar #0 TERMS_$cur_s TERMS

  set wire 0
  foreach id $ids {
    if {[is_tagged $id origin]} {
      # must be an instance.  Just select it.
      select_ids $id add no_display

    } elseif {!$wire} {
      # Select the whole net.
      select_wire_by_name $name add no_display
      set wire 1
    }
  }

  if {$by_id} {
    display_selection 
  } else {
    display_selection "$name"
  }

  if {$mode == "interactive"} {
    # zoom to fit around selected and/or terminals (labeled sel_terms)
    $cur_c addtag zoom withtag selected
    $cur_c addtag zoom withtag sel_terms

    set bbox [$cur_c bbox zoom]
    if {$bbox == ""} {
      ready
      return 0
    }

    zoom_to_bbox [$cur_c bbox zoom] 20
    eval center_canvas [center_bbox [$cur_c bbox zoom]]

    $cur_c dtag zoom 

    ready
  }
  return 1
}


# Names selected objects (or a subset of them) according to a pattern.

proc name_selected {} {

  global cur_c cur_s tmp PROC PROP_SAVE

  modify_setup

  if {![info exists PROP_SAVE(name,name_prefix)]} {
    # set up defaults
    set PROP_SAVE(name,name_prefix) ""
    set PROP_SAVE(name,name_suffix) ""
    set PROP_SAVE(name,dir) n
    set PROP_SAVE(name,first) 0
    set PROP_SAVE(name,increment) 1
    set PROP_SAVE(name,width) 1
    set PROP_SAVE(name,icons) *
  }

  set winy [expr [winfo rooty $cur_c] + 50]
  set winx [expr [winfo rootx $cur_c] + 50]
  set title "Name Selected"
  set message "Enter Naming Information:" 
  set prop_list [list [list name_prefix $PROP_SAVE(name,name_prefix)] \
		     [list name_suffix $PROP_SAVE(name,name_suffix)] \
		     [list dir $PROP_SAVE(name,dir) choice {n s e w}] \
		     [list first $PROP_SAVE(name,first)] \
		     [list increment $PROP_SAVE(name,increment)] \
		     [list width $PROP_SAVE(name,width)] \
		     [list icons $PROP_SAVE(name,icons)]]

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
  if {$new_prop_list == ""} {
    # empty list means the user hit cancel or didn't change anything
    return
  }

  set name [get_assoc name_prefix $new_prop_list]
  set suffix [get_assoc name_suffix $new_prop_list]

  # fix up
  regsub -all {\{|\}} $name "" name
  regsub -all {\{|\}} $suffix "" suffix

  if {$name == "" && $suffix == ""} {
    sue_error "Aborting, you must provide a name prefix or suffix."
    sue_error flush
    return
  }

  set tag "icon_[get_assoc icons $new_prop_list]"

  set ids ""
  foreach id [$cur_c find withtag selected] {
    if {[is_tagged $id $tag] && ![is_tagged $id origin_icon]} {
      upvar #0 ${cur_s}_inst${id} i_data
      set type $i_data(type)

      if {![info exists i_data(_name)]} {
	# can't name things that don't have name properties
	continue
      }

      lappend ids $id
    }
  }

  # sort ids by the direction to be named
  set dir [get_assoc dir $new_prop_list]
  if {$dir == "s" || $dir == "e"} {
    set switch "-increasing"
  } elseif {$dir == "n" || $dir == "w"} {
    set switch "-decreasing"
  } else {
    sue_error "Aborting, Illegal direction specified.  Must be n, s, e, or w, NOT \"$dir\""
    sue_error flush
    return
  }

  busy

  integer_scale

  # for undo
  set PROC ""
  write_instances selected 1 undo
  set save_proc $PROC

  if {$dir == "n" || $dir == "s"} {
    set tmp y
  } elseif {$dir == "e" || $dir == "w"} {
    set tmp x
  }

  set ids [lsort -command name_selected_compare $switch $ids]

  # name'm
  set count [get_assoc first $new_prop_list]
  set increment [get_assoc increment $new_prop_list]
  set width [get_assoc width $new_prop_list]

  set new_ids ""
  foreach id $ids {
    upvar #0 ${cur_s}_inst${id} i_data
    if {$width == 1} {
      set i_data(_name) "$name$count$suffix"
    } else {
      set count2 [expr $count + $width - 1]
      set i_data(_name) "$name$count2:$count$suffix"
    }
    lappend new_ids [remake $id $id "" no_scale]

    incr count $increment
  }

  setup_undo $new_ids $save_proc

  unscale

  # save for next time
  set PROP_SAVE(name,name_prefix) $name
  set PROP_SAVE(name,name_suffix) $suffix
  set PROP_SAVE(name,dir) $dir
  set PROP_SAVE(name,first) [get_assoc first $new_prop_list]
  set PROP_SAVE(name,increment) $increment
  set PROP_SAVE(name,width) [get_assoc width $new_prop_list]
  set PROP_SAVE(name,icons) [get_assoc icons $new_prop_list]

  puts "Renamed [llength $ids] instances."
  ready
}


# used by name_selected procedure above for sorting

proc name_selected_compare {id1 id2} {

  global cur_c tmp

  if {$tmp == "x"} {
    setl {x1 y1} [$cur_c coords $id1]
    setl {x2 y2} [$cur_c coords $id2]
  } else {
    setl {y1 x1} [$cur_c coords $id1]
    setl {y2 x2} [$cur_c coords $id2]
  }

  if {$x1 > $x2} {
    return 1
  }
  if {$x1 < $x2} {
    return -1
  }
  if {$y1 > $y2} {
    return -1
  }
  return 1
}


# Bring up an editor to edit selected names.
# Sorts by position of selected names on screen.
# Block schematic editing until text editor is closed, so the IDs remain valid.
# Rather than including Id and confusing user, just go by order of
# names in file.
# If they add or delete, the number of entries will be wrong and it will
# refuse to update.

proc edit_selected_names {} {

  global cur_c cur_s env DEFAULT_EDITOR PROC

  # generate temp file name
  set file "/tmp/sue[pid]"

  # get list of names
  foreach id [$cur_c find withtag selected&origin] {
    upvar #0 ${cur_s}_inst${id} i_data
    if {![info exists i_data(_name)]} {
      # skip things without names
      continue
    }

    set name $i_data(_name)

    # replace returns with <CR>
    regsub -all \n $name "<CR>" name

    if {$name == ""} {
      set name "<UNNAMED $i_data(type)>"
    }

    lappend list [list $id $name]
  }

  foreach id [$cur_c find withtag selected&draw_item] {
    if {[$cur_c type $id] == "text"} {
      # let the user modify text items, too
      set name [$cur_c itemcget $id -text]
      # replace returns with <CR>
      regsub -all \n $name "<CR>" name

      lappend list [list $id $name]
    }
  }

  if {![info exists list]} {
    warning "Aborting, must first select objects with names."
    return
  }

  # sort them by screen position
  set list [lsort -command edit_selected_sorter $list]
  set num [llength $list]

  # find editor
  set editor [use_first env(EDITOR) DEFAULT_EDITOR]
  set help ""
  # special case for vi, need to put into a window
  if {[regexp -nocase {([a-z/._-]*vi[a-z/._-]*)} $editor match]} {
    set editor "xterm -e $match"
    set help "  :wq to write and quit."
  } elseif {[regexp -nocase {([a-z/._-]*emacs[a-z/._-]*)} $editor match]} {
    set help "  C-x C-s to save, C-x C-c to exit."
  }

  # write old names to temp file
  if {[catch "open $file {WRONLY CREAT TRUNC}" FILE_ID]} {
    warning "Aborting, can't create file \"$file\".  Check file permissions and disk usage.  $FILE_ID"
    return
  }

  puts $FILE_ID "# Edit entries to change names of instances.  Don't add or delete entries."
  puts $FILE_ID "# Use <CR> for carriage returns.  Use \"-\" to unname an object."
  puts $FILE_ID "# Save file and exit editor when done.$help"

  foreach element $list {
    puts $FILE_ID [lindex $element 1]
  }

  # close the file
  close $FILE_ID

  # run editor;  blocking so the IDs will remain valid
  puts "Running \"$editor\" on $file ..."
  if {[catch "eval exec $editor $file" msg]} {
    warning $msg
    catch "exec /bin/rm -f $file"
    return
  }

  # read new names from temp file
  if {[catch "open $file RDONLY" FILE_ID]} {
    warning "Aborting, can't read file \"$file\".  $FILE_ID."
    return
  }

  set netlist ""
  set newlist ""
  while {[gets $FILE_ID newname] >= 0} {
    set newname [string trim $newname]
    if {$newname == "" || [string index $newname 0] == "#"} {
      # skip blank, comment lines
      continue
    }

    lappend newlist $newname
  }

  # close the file
  close $FILE_ID

  # make sure they didn't add or delete entries
  if {$num != [llength $newlist]} {
    warning "Aborting, can't change number of entries.  It went from $num to [llength $newlist] entries."
    catch "exec /bin/rm -f $file"
    return
  }

  integer_scale

  # for undo
  set proc ""

  # update names that changed
  set count 0
  set new_ids ""
  set final_proc ""

  for {set i 0} {$i < $num} {incr i} {
    setl {id oldname} [lindex $list $i]
    set newname [lindex $newlist $i]

    # remove brackets
    if {[regsub -all {^\{(.*)\}$} $newname {\1} answer]} {
      set newname $answer
    }

    if {$newname == "-"} {
      # this is a shortcut for set name to nil
      set newname ""
    }

    if {$newname != $oldname && \
	    !($newname == "" && [string first "<UNNAMED " $oldname] == 0)} {
      # name changed
      puts "  $oldname --> $newname"

      if {[is_tagged $id origin]} {
	# add undo info
	set PROC $proc
	write_instances inst$id 1 undo
	set proc $PROC

	upvar #0 ${cur_s}_inst${id} i_data

	regsub -all {<CR>} $newname \n newname
	set i_data(_name) $newname

	# now remake the icon (this will flag modified)
	lappend new_ids [remake $id $id "" no_scale "" no_select]

      } else {
	# must be a text item
	regsub -all {<CR>} $newname \n newname

	# change the text
	$cur_c itemconfigure $id -text $newname

	# undo bogosity
	regsub -all {<CR>} $oldname \n oldname
	regsub -all \{ $oldname <<< oldname
        regsub -all \} $oldname >>> oldname
	lappend proc "set _TMP_ \{$oldname\} ; regsub -all <<< \$_TMP_ \\\{ _TMP_ ; regsub -all >>> \$_TMP_ \\\} _TMP_ ; $cur_c itemconfigure \[xform_ids $id\] -text \$_TMP_ ; set _TMP_ -1"

	# can't put into new_ids because they get deleted during undo.
	lappend final_proc "select_ids $id add no_display"
      }

      incr count
    }
  }

  select_ids $new_ids add
  unhighlite_selected

  if {$new_ids != "" || $final_proc != ""} {
    # we changed some
    if {$new_ids == ""} {
      set new_ids -1
    }

    setup_undo $new_ids $proc "" $final_proc

    # flag that this canvas has been modified
    is_modified

    puts "Changed $count names in $num instances."

  } else {
    puts "Ignoring, nothing changed."
  }

  unscale

  # delete temp file
  catch "exec /bin/rm -f $file"
}


# The usual sort comparator.
# It doesn't seem to like fractional returns,
# so I'm forcing -1 and 1 rather than simply subtracting.

proc edit_selected_sorter {a b} {

    global cur_c

    setl {ax ay} [$cur_c coords [lindex $a 0]]
    setl {bx by} [$cur_c coords [lindex $b 0]]

    # left to right has priority
    if {$ax < $bx} {return -1}
    if {$ax > $bx} {return 1}
    # then top to bottom
    if {$ay < $by} {return -1}
    if {$ay > $by} {return 1}

    return 0
}


# Modifies a property on all selected objects

proc modify_selected {} {

  global WIN cur_c cur_s PROC PROP_SAVE

  modify_setup

  if {![info exists PROP_SAVE(modify,property)]} {
    # set up defaults
    set PROP_SAVE(modify,property) ""
    set PROP_SAVE(modify,previous_value) *
    set PROP_SAVE(modify,new_value) ""
  }

  set winy [expr [winfo rooty $WIN] + 50]
  set winx [expr [winfo rootx $WIN] + 50]
  set title "Modify Selected"
  set message "Enter Modification Information:" 
  set prop_list [list [list property $PROP_SAVE(modify,property)] \
		     [list previous_value $PROP_SAVE(modify,previous_value)] \
		     [list new_value $PROP_SAVE(modify,new_value)]]

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
  if {$new_prop_list == ""} {
    # empty list means the user hit cancel
    return
  }

  set property [get_assoc property $new_prop_list]
  set previous [get_assoc previous_value $new_prop_list]
  set value [get_assoc new_value $new_prop_list]

  if {$property == ""} {
    sue_error "Aborting, you must provide a property to modify."
    sue_error flush
    return
  }

  busy

  integer_scale

  # for undo
  set PROC ""
  write_instances selected 1 undo
  set save_proc $PROC

  # fix up pattern for substitution
  regsub -all {\*} $previous {(.*)} pat
  regsub -all {(\[|\}|\$|\^)} $pat {\\&} pat

  set count 0
  set new_ids ""
  foreach id [$cur_c find withtag selected] {
    # only can change properties in icons
    if {[is_tagged $id icon_*]} {
      upvar #0 ${cur_s}_inst${id} i_data
      if {[info exists i_data(_$property)]} {
	# see if it matches the previous property string
	set old $i_data(_$property)
	if {[string match $previous $old]} {
	  # found a matching property, now change its value
	  if {$old == ""} {
	    # special case (empty prop)
	    # watch out for quoted wildcard
            regsub -all {\\\*} $value {><><} tmp
            regsub -all {\*} $tmp "" new
            regsub -all {><><} $new * new

            set i_data(_$property) $new

	  } else {
	    # normal substitution
	    set new_pat $value
	    set index 1
            # change pattern, ignore quoted wildcard
            regsub -all {\\\*} $new_pat {><><} new_pat

            while {[regexp {\*} $new_pat]} {
	      regsub {\*} $new_pat \\\\$index new_pat
	      incr index
	    }

#	    regsub -all {(\[|\]|\$|\^)} $new_pat {\\&} new_pat

#regsub $pat $old $new_pat foo
#puts "$previous --> $value : $pat --> $new_pat : $old --> $foo"

	    # finally, do the substitution
	    regsub $pat $old $new_pat new
            regsub -all {><><} $new * new

            set i_data(_$property) $new
	  }

	  lappend new_ids [remake $id $id "" no_scale]
	  incr count
	}
      }
    }
  }

  set PROP_SAVE(modify,property) $property
  set PROP_SAVE(modify,previous_value) $previous
  set PROP_SAVE(modify,new_value) $value

  if {$count > 0} {
    setup_undo $new_ids $save_proc
  }

  unscale

  puts "Modified $count instances."
  ready
}
