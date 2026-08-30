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


# NST zoom, show position, show delta, scroll, activate procs.


# things to do during button motion.

set _LAST_TYPE_ ""

proc nst_motion_procs {graph x y} {
  global _LAST_TYPE_

  nst_show_pos $graph $x $y
  set info [$graph legend get @$x,$y]
  nst_activate_node $graph $info

  # if info is non nil, then over a legend
  if {$info != $_LAST_TYPE_} {
    if {$info == ""} {
      # restore this
      msg_window __DEFAULT__

    } elseif {$_LAST_TYPE_ == ""} {
      # new
      msg_window "Button-1 to move signal to another panel, Button-2 to modify signal" message
    }
    set _LAST_TYPE_ $info
  }
}


# nst_show_pos is called by mouse motion and displays the cursor position
# in the lower left hand corner of the screen.

proc nst_show_pos {graph x y} {
  global WIN

  set position [$graph invtransform $x $y]
  set ylabel V
  if {[$graph yaxis cget -title] == "Current"} {
    set ylabel A
  }
  $WIN.cursor_pos configure -text \
      [format "%sS, %s%s" [pp_number [lindex $position 0]] \
	   [pp_number [lindex $position 1]] $ylabel]
}


# nst_mem_coord remembers the mouse location in nst_coord when a button is
# pressed for use with nst_show_delta and nst_draw_box

set nst_coord(dummy) ""

proc nst_mem_coord {graph x y {type ""}} {
  global nst_coord
  
  set new_coord [$graph invtransform $x $y]
  if {$type != ""} {
    $graph element closest $x $y closest -interpolate 1
    if {$closest(name) != ""} {
      # use the closest coords instead
      set new_coord "$closest(x) $closest(y)"
      setl {x y} [$graph transform $closest(x) $closest(y)]
    }
  }

  set new_coord [$graph invtransform $x $y]
  set nst_coord($graph,x) [lindex $new_coord 0]
  set nst_coord($graph,y) [lindex $new_coord 1]

#  setl {nst_coord($graph,x) nst_coord($graph,y)} [$graph invtransform $x $y]
  
  set nst_coord($graph,start_x) $x
  set nst_coord($graph,start_y) $y

  set nst_coord($graph,end_x) $x
  set nst_coord($graph,end_y) $y

  nst_goto_graph $graph
}


# nst_show_delta displays delta x and delta y in the lower right hand
# corner of the screen when button 2 is release after tracing out a box

proc nst_show_delta {graph x y} {
  global nst_coord WIN

  set position [$graph invtransform $x $y]
  set deltax [expr [lindex $position 0] - $nst_coord($graph,x)]
  set deltay [expr [lindex $position 1] - $nst_coord($graph,y)]
  set ylabel V
  if {[$graph yaxis cget -title] == "Current"} {
    set ylabel A
  }
  $WIN.delta configure -text \
      [format "Delta: %sS, %s%s" [pp_number $deltax] \
	   [pp_number $deltay] $ylabel]
}


proc nst_draw_box_setup {graph x y} {

  global nst_graphs _NST_TEXT_MARKER_

  if {[info exists _NST_TEXT_MARKER_(motion)]} {
    return
  }

  set info [$graph legend get @$x,$y]
  if {$info != ""} {
    # popup a menu for user to modify signal
    nst_modify_signal $graph $info $x $y
    
    return
  }

  # set up bindings
  foreach graph $nst_graphs {
    bind $graph <Any-Button2-Motion> \
	{nst_draw_box %W %x %y closest; nst_show_pos %W %x %y ; nst_show_delta %W %x %y}
    bind $graph <Any-ButtonRelease-2> {nst_show_delta %W %x %y}
    bind $graph <Shift-Button2-Motion> ""

    nst_remove_markers
  }
}


proc nst_draw_box {graph x y {type ""}} {
  global nst_coord BOX_COLOR WIN
  
  if {![info exists nst_coord($graph,start_x)]} {
    return
  }

  set new_coord [$graph invtransform $nst_coord($graph,start_x) \
		     $nst_coord($graph,start_y)]
  set x1 [lindex $new_coord 0]
  set y1 [lindex $new_coord 1]

  set new_coord [$graph invtransform $x $y]
  if {$type != ""} {
    $graph element closest $x $y closest -interpolate 1
    if {$closest(name) != ""} {
      # use the closest coords instead
      set new_coord "$closest(x) $closest(y)"
    }
  }

  set x2 [lindex $new_coord 0]
  set y2 [lindex $new_coord 1]

  if {$x1 == $x2} {
    # otherwise XOR of lines makes disappear
    set coords [list $x1 $y1 $x1 $y2]
  } elseif {$y1 == $y2} {
    # otherwise XOR of lines makes disappear
    set coords [list $x1 $y1 $x2 $y1]
  } else {
    set coords [list $x1 $y1 $x1 $y2 $x2 $y2 $x2 $y1 $x1 $y1]
  }
    
  if [$graph marker exists nst_zoom] {
    $graph marker configure nst_zoom -coords $coords
  } else {
    $graph marker create line -coords $coords -name nst_zoom -fill $BOX_COLOR \
	-dashes {1 1} -xor 1
  }

#  if [$graph marker exists nst_dx] {
#    $graph marker configure nst_dx \
	-coords "[expr ($x1 + $x2)/2.0] $y1" \
	-text [lindex [lindex [split [$WIN.delta cget -text] ,] 0] 1]
#  } else {
#    $graph marker create text -coords "[expr ($x1 + $x2)/2.0] $y1" \
	-text 0 -name nst_dx \
	-foreground $BOX_COLOR -fill "" -anchor s
#  }

#  if [$graph marker exists nst_dy] {
#    $graph marker configure nst_dy \
	-coords "$x1 [expr ($y1 + $y2)/2.0]" \
	-text [lindex [split [$WIN.delta cget -text] ,] 1]
#  } else {
#    $graph marker create text -coords "$x1 [expr ($y1 + $y2)/2.0]" \
	-text 0 -name nst_dy -rotate 90 \
	-foreground $BOX_COLOR -fill "" -anchor e
#  }

#  update
}


# zooms in when button-1 is release after tracing out a zoom box

proc nst_zoom_in {graph x y} {
  global nst_coord
  
  if {[info exists nst_coord($graph,x)] != 1} {
    return
  }

  if {[$graph element names] == ""} {
    # nothing here, don't zoom, user probably just selecting
    return
  }

  set xmin $nst_coord($graph,x)
  set ymin $nst_coord($graph,y)
  
  setl {xmax ymax} [$graph invtransform $x $y]
  setl {xold yold} [$graph transform $xmin $ymin]

  if {[expr abs($xold - $x)] < 5 && [expr abs($yold - $y)] < 5} {
    # user probably just selecting
    return
  }

  if {$xold == $x || $yold == $y} {
    # bad size, ignore
    return
  }

  if {$xmin > $xmax} { 
    set foo $xmin
    set xmin $xmax
    set xmax $foo
  }
  if {$ymin > $ymax} { 
    set foo $ymin
    set ymin $ymax
    set ymax $foo
  }
  nst_zoom $graph $xmin $ymin $xmax $ymax
}


# does the work

proc nst_zoom {graph xmin ymin xmax ymax} {
  global nst_coord NST_LOCK nst_graphs SCROLLBAR WIN

  # first save where we were
  setl {old_xmin old_xmax old_ymin old_ymax} [nst_find_limits $graph]
  set nst_coord(last) "$graph $old_xmin $old_ymin $old_xmax $old_ymax"

  if {$SCROLLBAR == "on"} {
    if {[$WIN.hscroll get] == "0.0 1.0"} {
      # we are zoomed out, save limits (must be a better way)
      set nst_coord(xlimit,$graph) [$graph xaxis limits]
    }

    if {![info exists nst_coord(xlimit,$graph)]} {
      $graph xaxis configure -min {} -max {}
      set nst_coord(xlimit,$graph) [$graph xaxis limits]
      $graph xaxis configure -min $old_xmin -max $old_xmax
    }

    setl {xstart xend} $nst_coord(xlimit,$graph)
    $WIN.hscroll set [expr ($xmin - $xstart) / ($xend - $xstart)] \
	[expr ($xmax - $xstart) / ($xend - $xstart)]

    catch {unset nst_coord(moveto,$graph)}
  }

  nst_remove_markers

  $graph xaxis configure -min $xmin -max $xmax
  $graph yaxis configure -min $ymin -max $ymax
  
  if {$NST_LOCK} {
    foreach win $nst_graphs {
      $win xaxis configure -min $xmin -max $xmax
      catch {unset nst_coord(moveto,$win)}
    }
  }
}


# unzooms to last position

proc nst_unzoom_last {} {
  global nst_coord

  if {[info exists nst_coord(last)] && $nst_coord(last) != ""} {
    eval nst_zoom $nst_coord(last)
  }
}


# Unzooms window when button-3 is pressed.

proc nst_unzoom {{graph ""}} {
  global NST_LOCK nst_graphs SCROLLBAR WIN nst_coord
  
  if {$graph == ""} {
    set graph [lindex $nst_graphs 0]
  }

  # nst_zoom gets called twice (why?).  This ignores second time
  if {[$graph xaxis cget -min] != 0.0} {
    setl {old_xmin old_xmax old_ymin old_ymax} [nst_find_limits $graph]
    set nst_coord(last) "$graph $old_xmin $old_ymin $old_xmax $old_ymax"
  }

  $graph xaxis configure -min {} -max {}
  $graph yaxis configure -min {} -max {}
  
  if {$SCROLLBAR == "on"} {
    $WIN.hscroll set 0.0 1.0

    catch {unset nst_coord(moveto,$graph)}
  }

  if {$NST_LOCK} {
    setl {xmin xmax} [$graph xaxis limits]

    foreach win $nst_graphs {
      $win xaxis configure -min $xmin -max $xmax

      catch {unset nst_coord(moveto,$win)}
    }
  }
  
  nst_goto_graph $graph
}


# Toggles between locked (all xaxis of graphs are fixed together) and unlocked

proc nst_toggle_lock {} {
  global NST_LOCK nst_graphs WIN
  
  # assumes that the lock/unlock zoom entry is the last entry in this menu.
  $WIN.mb.view.menu delete 12
  if {$NST_LOCK} {
    set NST_LOCK 0
    # change menu
    menu_add -menu view -label "Lock Zoom" -command nst_toggle_lock \
	-position 12 -help "Lock the X-axis between all panels so they are all coordinated."
    
  } else {
    set NST_LOCK 1
    # change menu
    menu_add -menu view -label "Unlock Zoom" -command nst_toggle_lock \
	-position 12 \
	-help "Unlock the X-axis between different panels so they can be different."
    set graph [lindex $nst_graphs 0]
    set min [lindex [$graph xaxis configure -min] 4]
    set max [lindex [$graph xaxis configure -max] 4]
    foreach win $nst_graphs {
      $win xaxis configure -min $min
      $win xaxis configure -max $max
    }
  }
  nst_fix_xaxis
}


proc nst_scroll {args} {
  global nst_graphs SCROLL NST_LOCK WIN nst_coord

  # cancel unzoom last
  set nst_coord(last) ""

  set graph [lindex $nst_graphs 0]

  # is the xaxis is in log mode, abort
  if {[$graph xaxis cget -logscale] == 1} {
    puts "Aborting: Scrollbar doesn't work with an X-axis logscale."
    return
  }

  setl {xmin xmax} [$graph xaxis limits]

  setl {cmd num units} $args

  # get the extent of this window
  if {![info exists nst_coord(xlimit,$graph)]} {
    # not defined, probably not zoomed out yet since defined there
    set nst_coord(xlimit,$graph) [$graph xaxis limits]
  }
  setl {xstart xend} $nst_coord(xlimit,$graph)
  set xwidth [expr $xend - $xstart]

  switch $cmd {
    scroll {
      if {$units == "units"} {
	set num [expr $num / 10.0]
      }
      
      # 20% overlap
      set delta [expr ($xmax - $xmin) * $num * 0.8]

      catch {unset nst_coord(moveto,$graph)}
    }

    moveto {
      # convert to graph coords
      if {![info exists nst_coord(moveto,$graph)]} {
	# save this position
	set nst_coord(moveto,$graph) $num
	return
      }

      # convert to graph units from percentage
      set delta [expr ($num - $nst_coord(moveto,$graph)) * $xwidth]

      # save this position
      set nst_coord(moveto,$graph) $num
    }

    default {
      # huh
      return
    }
  }

  # scroll away

  $WIN.hscroll set [expr ($xmin + $delta - $xstart) / $xwidth] \
      [expr ($xmax + $delta - $xstart) / $xwidth]

  if {$NST_LOCK} {
    foreach win $nst_graphs {
      $win xaxis configure -min [expr $xmin + $delta] \
	  -max [expr $xmax + $delta]
    }

  } else {
    $graph xaxis configure -min [expr $xmin + $delta] \
	-max [expr $xmax + $delta]
  }
}


# called by mouse motion to highlight node data if over appropriate legend

proc nst_activate_node {graph name} {
  global nst_active
  
  set last [use_first nst_active($graph)]
  if { $name != $last } {
    if { $last != "" } {
      $graph legend deactivate $last
      $graph element deactivate $last
    }
    if { $name != "" } {
      $graph legend activate $name
      $graph element activate $name 
    }
    set nst_active($graph) $name
  }
}


# draw a line between any two waveforms at designated y location

proc nst_measure {graph x y {mode ""}} {

  global NST_MEASURE_DATA BOX_COLOR MEASURE_YCOORD nst_graphs

  global _NST_TEXT_MARKER_
  if {[info exists _NST_TEXT_MARKER_(motion)]} {
    return
  }

  if {$mode == "start"} {
    # setup up bindings
    foreach _graph $nst_graphs {
      bind $_graph <Button2-Motion> ""
      bind $_graph <ButtonRelease-2> ""
    
      bind $_graph <Any-Button2-Motion> \
	  {nst_measure %W %x %y ; nst_show_pos %W %x %y}
    }

    nst_remove_markers

    catch {unset NST_MEASURE_DATA}
    set NST_MEASURE_DATA(lastx) -1.2e12
    set NST_MEASURE_DATA(lastx_win) -1.2e8
  }

  if {[info exists NST_MEASURE_DATA(graph)] && \
	  $NST_MEASURE_DATA(graph) != $graph} {
    # wrong graph
    return
  }

  if {![$graph marker exists nst_first]} {
    global nst_files 

    # insure that the y value is loaded
    set filename [nst_last $nst_files]
    nst_get_node_if_needed $filename $MEASURE_YCOORD
    global $MEASURE_YCOORD

    # bug in blt, can't use the following
    # if {[info exists ${MEASURE_YCOORD}(0)]}

    if {![catch "expr [set ${MEASURE_YCOORD}(0)] + 1"]} {
      # this is a vector

      # save the graph coord of this
      set NST_MEASURE_DATA(gy) [set ${MEASURE_YCOORD}(0)]

    } elseif {![catch "expr $MEASURE_YCOORD + 1"]} {
      # this is a number, just use it
      set NST_MEASURE_DATA(gy) $MEASURE_YCOORD

    } else {
      # invalid, query user for something else
      nst_change_measure_ycoord
      return
    }

    # save the window coord of this
    set NST_MEASURE_DATA(y) \
	[lindex [$graph transform 1 $NST_MEASURE_DATA(gy)] 1]

    set NST_MEASURE_DATA(graph) $graph

    $graph element closest $x $NST_MEASURE_DATA(y) closest -interpolate 1 \
	-halo 1i

    if {$closest(name) != ""} {
      # found something
      set NST_MEASURE_DATA(x) $closest(x)

      # setup for delta
      eval nst_mem_coord $graph \
	  [$graph transform $closest(x) $NST_MEASURE_DATA(gy)]

      # convert 10 pixels
      setl {x1 y1} [$graph invtransform 10 10]
      setl {x2 y2} [$graph invtransform 20 20]
      set dx [expr $x2 - $x1]
      set dy [expr $y2 - $y1]

      # a diamond
      # set coords [list [expr $closest(x) - $dx] $NST_MEASURE_DATA(gy) \
	  $closest(x) [expr $NST_MEASURE_DATA(gy) - $dy] \
	  [expr $closest(x) + $dx] $NST_MEASURE_DATA(gy) \
	  $closest(x) [expr $NST_MEASURE_DATA(gy) + $dy] \
	  [expr $closest(x) - $dx] $NST_MEASURE_DATA(gy) \
	 ]

      # an X
      set coords \
	[list [expr $closest(x) - $dx] [expr $NST_MEASURE_DATA(gy) - $dy]\
	     [expr $closest(x) + $dx] [expr $NST_MEASURE_DATA(gy) + $dy] \
	     $closest(x) $NST_MEASURE_DATA(gy) \
	     [expr $closest(x) - $dx] [expr $NST_MEASURE_DATA(gy) + $dy]\
	     [expr $closest(x) + $dx] [expr $NST_MEASURE_DATA(gy) - $dy] \
	    ]

      # make it
      $graph marker create line -coords $coords \
	  -name nst_first -fill $BOX_COLOR -dashes {1 1}
    }

    return
  }

  # can't change graphs in the middle of this
  set graph $NST_MEASURE_DATA(graph)

  if {$mode != "done"} {

    $graph element closest $x $NST_MEASURE_DATA(y) closest -interpolate 1 \
	-halo 1i

    if {$closest(name) != ""} {

      # convert to window coords
      setl {close_x close_y} [$graph transform $closest(x) $closest(y)]

      # do another search with this x since we really only want to
      # interpolate in y, this will minimize x variation
      $graph element closest $close_x $NST_MEASURE_DATA(y) closest \
	  -interpolate 1 -halo 1i

      # convert to window coords
      setl {close_x close_y} [$graph transform $closest(x) $closest(y)]

      # do another search with this x since we really only want to
      # interpolate in y, this will minimize x variation
      $graph element closest $close_x $NST_MEASURE_DATA(y) closest \
	  -interpolate 1 -halo 1i

      # found something
      if {[close_to $NST_MEASURE_DATA(x) $closest(x)]} {
	# same as starting point, ignore
	return
      }

      if {[close_to $NST_MEASURE_DATA(lastx_win) $close_x]} {
	# already set this
	return
      }

      set NST_MEASURE_DATA(lastx_win) $close_x
      set NST_MEASURE_DATA(lastx) $closest(x)

      # show delta
      eval nst_show_delta $graph \
	  [$graph transform $closest(x) $NST_MEASURE_DATA(gy)]

      set coords [list $NST_MEASURE_DATA(x) $NST_MEASURE_DATA(gy) \
		      $closest(x) $NST_MEASURE_DATA(gy)
		  ]

      if {[$graph marker exists nst_zoom]} {
	$graph marker configure nst_zoom -coords $coords
      } else {
	$graph marker create line -coords $coords \
	    -name nst_zoom -fill $BOX_COLOR -dashes {1 1} -xor 1
      }

      set x1 $NST_MEASURE_DATA(x)
      set x2 $NST_MEASURE_DATA(lastx)
      set delta [format "%sS" [pp_number [expr $x2 - $x1]]]
      set y1 $NST_MEASURE_DATA(gy)

      if [$graph marker exists nst_dx] {
	$graph marker configure nst_dx \
	    -coords "[expr ($x1 + $x2)/2.0] $y1" \
	    -text $delta
      } else {
	$graph marker create text -coords "[expr ($x1 + $x2)/2.0] $y1" \
	    -text $delta -name nst_dx \
	    -foreground $BOX_COLOR -fill "" -anchor s
      }
    }
  }
}


proc nst_change_measure_ycoord {} {

  global WIN MEASURE_YCOORD _NST_IN_PROP_

  if {[info exists _NST_IN_PROP_]} {
    # already in this prop
    return
  }

  set _NST_IN_PROP_ 1

  # major hack for now
  global cur_c
  set cur_c .nst

  set winy [expr [winfo rooty $WIN] + 50]
  set winx [expr [winfo rootx $WIN] + 50]
  set title "Measure Y Coordinate"
  set message "Enter New Measure Y Coordinate:" 

  set prop_list [list "value $MEASURE_YCOORD"]

  # create the menu
  set new_prop_list [prop_menu $winx $winy $message $title $prop_list]
  if {$new_prop_list == "" || $new_prop_list == $prop_list} {
    # empty list means the user hit cancel or didn't change anything
    unset _NST_IN_PROP_

    return
  }

  set MEASURE_YCOORD [get_assoc value $new_prop_list]

  unset _NST_IN_PROP_
}


# removes all marker in all graphs

proc nst_remove_markers {} {

  global nst_graphs

  foreach graph $nst_graphs {

    if [$graph marker exists nst_zoom] {
      $graph marker delete nst_zoom
    }

    if [$graph marker exists nst_first] {
      $graph marker delete nst_first
    }

    if [$graph marker exists nst_dx] {
      $graph marker delete nst_dx
    }
#  if [$graph marker exists nst_dy] {
#    $graph marker delete nst_dy
#  }

  }
}


# zoom to based on a menu with numbers

proc nst_zoom_to {} {

  global nst_graphs cur_c

  # total hack to get prop_menu2 to work with nst
  set cur_c .nst


  set graph [lindex $nst_graphs 0]

  set xmin [$graph xaxis cget -min]
  set xmax [$graph xaxis cget -max]
  set ymin [$graph yaxis cget -min]
  set ymax [$graph yaxis cget -max]

  if {$xmin == "" || $xmax == "" || $ymin == "" || $ymax == ""} {
    # zoomed all the way out. 
    setl {xmin xmax ymin ymax} [nst_find_limits $graph]
  }

  set xmin [pp_number $xmin]
  set xmax [pp_number $xmax]
  set ymin [pp_number $ymin]
  set ymax [pp_number $ymax]

  set title "NST Zoom To"
  set message "Enter Coordinates to Zoom to:    "

  set prop_list ""
  lappend prop_list [list "X min" xmin]
  lappend prop_list [list "Y min" ymin]
  lappend prop_list [list "X max" xmax]
  lappend prop_list [list "Y max" ymax]

  set all_panels 0
  lappend prop_list [list "All Panels" all_panels binary]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  # do it
  if {$all_panels} {
    foreach graph $nst_graphs {
      nst_zoom $graph [parse_pp_number $xmin] [parse_pp_number $ymin] \
	  [parse_pp_number $xmax] [parse_pp_number $ymax]
    }
  } else {
    nst_zoom $graph [parse_pp_number $xmin] [parse_pp_number $ymin] \
	[parse_pp_number $xmax] [parse_pp_number $ymax]
  }
}


# measure/display the slope of the closest waveform
# Assumes values of percentage of 2*mid_point

proc nst_slope {graph x y} {

  global MEASURE_YCOORD nst_graphs nst_files NST_SLOPE nst_coord

  global _NST_TEXT_MARKER_
  if {[info exists _NST_TEXT_MARKER_(motion)]} {
    return
  }

  foreach _graph $nst_graphs {
    bind $_graph <Any-Button2-Motion> ""
    bind $_graph <Any-ButtonRelease-2> ""
    bind $_graph <Shift-Button2-Motion> ""
  }

  set NST_SLOPE(min) [use_first NST_SLOPE(min) '0.2]
  set NST_SLOPE(max) [use_first NST_SLOPE(max) '0.8]

  # nst_remove_markers

  # insure that the y value is loaded
  set filename [nst_last $nst_files]
  nst_get_node_if_needed $filename $MEASURE_YCOORD
  global $MEASURE_YCOORD

  # bug in blt, can't use the following
  # if {[info exists ${MEASURE_YCOORD}(0)]}

  if {![catch "expr [set ${MEASURE_YCOORD}(0)] + 1"]} {
    # this is a vector

    # save the graph coord of this
    set mid_point [set ${MEASURE_YCOORD}(0)]

  } elseif {![catch "expr $MEASURE_YCOORD + 1"]} {
    # this is a number, just use it
    set mid_point $MEASURE_YCOORD

  } else {
    # invalid, query user for something else
    nst_change_measure_ycoord
    return
  }

  # find closest waveform
  $graph element closest $x $y closest -interpolate 1 -halo 1i

  if {$closest(name) == ""} {
    puts "Aborting, Nothing close enough"
    return
  }

  if {[nst_slope_int $graph $x $y $closest(name) $mid_point] == 0} {
    # have to zoom out to do this right
    set save_zoom [use_first $nst_coord(last)]
    setl {old_xmin old_xmax old_ymin old_ymax} [nst_find_limits $graph]
    # can't use nst_unzoom since it is broken if already zoomed out
    $graph xaxis configure -min {} -max {}
    $graph yaxis configure -min {} -max {}

    # transform back after zoom
    setl {nx ny} [$graph transform $closest(x) $closest(y)]  

    # needed (ack) to update values but flashes screen
    update

    nst_slope_int $graph $nx $ny $closest(name) $mid_point

    # restore zoom
    nst_zoom $graph $old_xmin $old_ymin $old_xmax $old_ymax
    set nst_coord(last) $save_zoom
  }
}


# does the work of computing slope and annotating

proc nst_slope_int {graph nx ny name mid_point} {

  global BOX_COLOR NST_SLOPE

  set top_point [expr 2 * $mid_point]

  # now find closest that this waveform goes thru mid_point
  $graph element closest $nx $ny closest -interpolate 1 -halo 20i $name

  if {[use_first closest(x)] == ""} {
    # time to zoom out
    return 0
  }

  set min_value [expr $NST_SLOPE(min) * $top_point]

  setl {nx ny} [$graph transform $closest(x) $min_value]
  $graph element closest $nx $ny min_closest -interpolate 1 -halo 20i $name

  if {[use_first min_closest(x)] == ""} {
    # time to zoom out
    return 0
  }

  # do it again to get closer
  setl {nx ny} [$graph transform $min_closest(x) $min_value]
  $graph element closest $nx $ny min_closest -interpolate 1 -halo 20i $name

  # third time's a charm
  setl {nx ny} [$graph transform $min_closest(x) $min_value]
  $graph element closest $nx $ny min_closest -interpolate 1 -halo 20i $name

  setl {nx ny} [$graph transform $min_closest(x) $min_value]
  $graph element closest $nx $ny min_closest -interpolate 1 -halo 20i $name

  if {$min_closest(y) > [expr 1.05 * $min_value]} {
    # zoomed in too close
    #puts "$min_closest(y) > [expr 1.05 * $min_value]  ($min_value)"
    return 0
  }

  set max_value [expr $NST_SLOPE(max) * $top_point]

  setl {nx ny} [$graph transform $closest(x) $max_value]
  $graph element closest $nx $ny max_closest -interpolate 1 -halo 20i $name

  if {[use_first max_closest(x)] == ""} {
    # time to zoom out
    return 0
  }

  # do it again to get closer
  setl {nx ny} [$graph transform $max_closest(x) $max_value]
  $graph element closest $nx $ny max_closest -interpolate 1 -halo 20i $name

  # third time's a charm
  setl {nx ny} [$graph transform $max_closest(x) $max_value]
  $graph element closest $nx $ny max_closest -interpolate 1 -halo 20i $name

  setl {nx ny} [$graph transform $max_closest(x) $max_value]
  $graph element closest $nx $ny max_closest -interpolate 1 -halo 20i $name

  if {$max_closest(y) < [expr 0.95 * $max_value]} {
    # zoomed in too close
    #puts "max $max_closest(y) < [expr 0.95 * $max_value]"
    return 0
  }

  # convert 100 pixels for a fixed distance on screen
  setl {x1 y1} [$graph invtransform 10 10]
  setl {x2 y2} [$graph invtransform 60 60]
  set dx [expr $x2 - $x1]
  set dy [expr $y2 - $y1]

  # show slope
  set c [list $min_closest(x) $min_closest(y) \
		  $max_closest(x) $max_closest(y)]

  set bot_x [eval nst_extend $c 0]
  set top_x [eval nst_extend $c $top_point]

  set coords [list $bot_x 0 $top_x $top_point]

  $graph marker create line -coords $coords \
      -name nst_slope -fill $BOX_COLOR -dashes {4 2} -xor 1

  if {$min_closest(x) < $max_closest(x)} {
    # rising edge
    set anchor se
    set theta 90
  } else {
    # falling edge
    set anchor sw
    set theta -90
  }

  $graph marker create text \
      -coords [list $closest(x) $closest(y)] \
      -text [pp_number [expr abs($max_closest(x) - $min_closest(x))]] \
      -name nst_slope_text \
      -foreground $BOX_COLOR -fill "" -anchor $anchor -rotate $theta

  # a bar at the min
  set coords [list [expr $min_closest(x) - $dx] $min_closest(y) \
		  [expr $min_closest(x) + $dx] $min_closest(y)]
  $graph marker create line -coords $coords \
      -name nst_slope_min -fill $BOX_COLOR -dashes {6 2} -xor 1
  $graph marker create text \
      -coords [list $min_closest(x) $min_closest(y)] \
      -text [format %.2fX [expr $min_closest(y)/$top_point]] \
      -name nst_slope_min_text \
      -foreground $BOX_COLOR -fill "" -anchor nw

  # a bar at the max
  set coords [list [expr $max_closest(x) - $dx] $max_closest(y) \
		  [expr $max_closest(x) + $dx] $max_closest(y)]
  $graph marker create line -coords $coords \
      -name nst_slope_max -fill $BOX_COLOR -dashes {6 2} -xor 1
  $graph marker create text \
      -coords [list $max_closest(x) $max_closest(y)] \
      -text [format %.2fX [expr $max_closest(y)/$top_point]] \
      -name nst_slope_max_text \
      -foreground $BOX_COLOR -fill "" -anchor sw

  # a bar at the bottom
  set coords [list [expr $bot_x - 2*$dx] 0 \
		  [expr $bot_x + 2*$dx] 0]
  $graph marker create line -coords $coords \
      -name nst_slope_bot -fill $BOX_COLOR -dashes {10 2} -xor 1
  $graph marker create text \
      -coords [list $bot_x 0] \
      -text 0V -name nst_slope_bot_text \
      -foreground $BOX_COLOR -fill "" -anchor sw

  # a bar at the top
  set coords [list [expr $top_x - 2*$dx] $top_point \
		  [expr $top_x + 2*$dx] $top_point]
  $graph marker create line -coords $coords \
      -name nst_slope_top -fill $BOX_COLOR -dashes {10 2} -xor 1
  $graph marker create text \
      -coords [list $top_x $top_point] \
      -text [format %.2fV $top_point] -name nst_slope_top_text \
      -foreground $BOX_COLOR -fill "" -anchor nw

  return 1
}

#   source /homes/tavrow/nst/nst_zoom.tcl




# Returns the x-coord for the extrapolated with newy.

proc nst_extend {x1 y1 x2 y2 newy} {

  if {[catch {expr ($y2 - $y1) / ($x2 -$x1)} m]} {
    # divide by zero, inifinite slope
    return $x1
  }

  if {$m == 0.0} {
    # can't do it
    return $x1
  }

  set b [expr $y1 - $m * $x1]

  return [expr ($newy - $b) / $m]
}


proc nst_change_slope_percentages {} {

  global WIN NST_SLOPE _NST_IN_PROP_

  if {[info exists _NST_IN_PROP_]} {
    # already in this prop
    return
  }

  set _NST_IN_PROP_ 1

  set NST_SLOPE(min) [use_first NST_SLOPE(min) '0.2]
  set NST_SLOPE(max) [use_first NST_SLOPE(max) '0.8]

  # major hack for now
  global cur_c
  set cur_c .nst

  set winy [expr [winfo rooty $WIN] + 50]
  set winx [expr [winfo rootx $WIN] + 50]
  set title "Slope Percentages"
  set message "Enter Slope Percentages:" 

  set prop_list ""
  lappend prop_list [list "min percentage" NST_SLOPE(min) -number 0 1 -incr .1]
  lappend prop_list [list "max percentage" NST_SLOPE(max) -number 0 1 -incr .1]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  unset _NST_IN_PROP_
}
