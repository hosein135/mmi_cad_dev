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


# Scales everything in the schematic to new_scale.  New_scale will be rounded
# to the closest integer so that the gridding works.  
#
# Note that this will shift the apparent center of the screen usually.  the
# zoom proc below fixes this.

proc scale_canvas {new_scale} {

  global cur_c cur_s scale FONT
 
#puts "scaling $cur_c from $scale to $new_scale"

  # scales can only be integers and are bounded by 1 and FONT(MAX)
#  set new_scale [min $FONT(MAX) [max 1 [expr round($new_scale)]]]
  set new_scale [min $FONT(MAX) [max .01 $new_scale]]

  # Return if we are already there
  if {$scale == $new_scale} {
    return
  } 

  set scalefactor [expr 1.0 * $new_scale / $scale]
  $cur_c scale all 0 0 $scalefactor $scalefactor

#puts "scale $scale --> $new_scale"

  set scale $new_scale 
  global SUE_$cur_s
  set SUE_${cur_s}(scale) $scale

  # don't want this too small at smallest scales or you can't hit anything
  $cur_c configure -closeenough [expr 3 + $scale/2.0 - sqrt($scale)]

  # scale fonts (badly).  Allows for 3 font sizes on screen: standard,
  # large, and small. 
  set fontscale [max [expr int(round($scale))] 0]

  $cur_c itemconfigure size_standard -font $FONT(standard,$fontscale)
  $cur_c itemconfigure size_very-small -font $FONT(very-small,$fontscale)
  $cur_c itemconfigure size_small -font $FONT(small,$fontscale)
  $cur_c itemconfigure size_large -font $FONT(large,$fontscale)
  $cur_c itemconfigure size_very-large -font $FONT(very-large,$fontscale)

#  global HIDDEN_PROPS
#  foreach prop $HIDDEN_PROPS {
#    $cur_c itemconfigure prop_$prop -font $FONT(small,0)
#  }

  # scale buses
  $cur_c itemconfigure bus -width [expr int(floor($scale)) / 4 + 1]
}


# scales are integers unless less than 2 and then by tenhs, unless
# less than 1 and then they are by hundredths.

proc canvas_round_scale {new_scale} {

  if {$new_scale < 1.0} {
    set new_scale [expr floor($new_scale * 100) / 100.0]    

  } elseif {$new_scale < 3.0} {
    set new_scale [expr floor($new_scale * 10) / 10.0]
    # if scale is 1 or 2, needs to be an integer
    if {$new_scale == 2.0} {
      set new_scale 2
    } elseif {$new_scale == 1.0} {
      set new_scale 1
    }
  } else {
    set new_scale [expr int(floor($new_scale))]
  }

  return $new_scale
}


# if the current scale is not an integer, scales canvas to nearest
# integer size and remembers previous scale to return to later.

set _SAVE_SCALE_CUR_S_ ""

proc integer_scale {} {

  global cur_s scale _SAVE_SCALE_ _SAVE_SCALE_CUR_S_

  set _SAVE_SCALE_ $scale
  # remember if there is a problem.  Launch looks at this.
  set _SAVE_SCALE_CUR_S_ $cur_s

  scale_canvas [max 2 [expr int(ceil($scale))]]
}


# undo integer_scale operation

proc unscale {} {

  global _SAVE_SCALE_  _SAVE_SCALE_CUR_S_

  scale_canvas $_SAVE_SCALE_

  set _SAVE_SCALE_CUR_S_ ""
}


# returns the visible bbox of the current cell.

proc visible_bbox {{mode ""}} {

  global cur_c scale DEFAULT_VISIBLE_BBOX

  set width [winfo width $cur_c]
  set height [winfo height $cur_c]

  if {$mode == "default"} {
    # set the default
    return [list [expr 0 - $width/2.0] [expr 0 - $height/2.0] \
		[expr $width/2.0] [expr $height/2.0]]
  }

  if {$width == 1 && $height == 1} {
    # not packed/refreshed yet
# puts "----> using default $DEFAULT_VISIBLE_BBOX"

    return $DEFAULT_VISIBLE_BBOX

  } else {

    set bx1 [$cur_c canvasx 0]
    set by1 [$cur_c canvasy 0]
    set bx2 [expr $bx1 + $width]
    set by2 [expr $by1 + $height]

    return "$bx1 $by1 $bx2 $by2"
  }
}


# this routines assures that the center of the visual screen doesn't
# move when you scale in and out.

proc zoom {{factor 0.5}} {

  global cur_c scale

  # draw a little temporary rectangle at the center of the screen
  set center [center_bbox [visible_bbox]]
  set id [eval $cur_c create rectangle $center $center -tags box]

  set new_scale [canvas_round_scale [expr $scale * $factor]]

  # insure that we are actually changing the scale
  while {$new_scale == $scale} {
    set factor [expr $factor * $factor]
    set new_scale [canvas_round_scale [expr $scale * $factor]]
  }

  scale_canvas $new_scale
  # center the temporary rectangle
  eval center_canvas [round_list [center $id]]

  # lose the temporary rectangle
  $cur_c delete box

  set_scrollbars
}

proc zoom_to_fit {} {

  global cur_c cur_s scale WIN

  if {[lsearch [pack slaves $WIN] $cur_c] == -1} {
    # delay since not packed
    upvar #0 SUE_$cur_s data
    set data(zoom_to_fit) 1
    return
  }

  $cur_c addtag object all
  $cur_c dtag grid object

  set bbox [$cur_c bbox object]
  if {$bbox == ""} {
    return
  }

  zoom_to_bbox $bbox
  # once again for good measure
  zoom_to_bbox [$cur_c bbox object]
  # and again
  zoom_to_bbox [$cur_c bbox object]

  eval center_canvas [center_bbox [$cur_c bbox object]]

  $cur_c dtag object

  set_scrollbars
}


proc zoom_to_selected {{api 0}} {

  global cur_c scale

  set bbox [$cur_c bbox selected]
  if {$bbox == ""} {
    if {!$api} {
      puts "Aborting, nothing selected."
    }
    return 0
  }

  zoom_to_bbox $bbox 20
  eval center_canvas [center_bbox [$cur_c bbox selected]]

  set_scrollbars

  return 1
}


proc get_schematic_bbox {} {

  global cur_c scale

  # Don't look at the grid if it exists
  $cur_c addtag object all
  $cur_c dtag grid object

  set bbox [$cur_c bbox object]
  if {$bbox == ""} {
    return "0 0 0 0"
  }

  $cur_c dtag object

  return $bbox
}


proc zoom_to_bbox {bbox {border 6}} {

  global cur_c scale GEOMETRY ICON_MENU

  set border [expr $border * [max 4 $scale] - 2]

  set x1 [expr [lindex $bbox 0] - $border]
  set y1 [expr [lindex $bbox 1] - $border]
  set x2 [expr [lindex $bbox 2] + $border]
  set y2 [expr [lindex $bbox 3] + $border]

  setl {xwin1 ywin1 xwin2 ywin2} [visible_bbox]
  if {$xwin1 == ""} {
    # visible_bbox failed.  Sometimes happens when iconified
    return
  }

  if {$xwin1 == 0.0 && $ywin1 == 0.0 && \
	  $xwin2 == 0.0 && $ywin2 == 0.0} {
    return
  }

  set xratio [expr (1.0*$xwin2-$xwin1)/($x2-$x1)]
  set yratio [expr (1.0*$ywin2-$ywin1)/($y2-$y1)]

  if {$yratio > $xratio} {
    set ratio $xratio
  } else {
    set ratio $yratio
  }

  set new_scale [canvas_round_scale [expr $scale * $ratio]]

  scale_canvas $new_scale
}


# places the given coords at the center of the window

proc center_canvas {x y} {

  global cur_c

  setl {x1 y1 x2 y2} [lindex [$cur_c configure -scrollregion] 4]

  setl {xwin1 ywin1 xwin2 ywin2} [visible_bbox]

  # back compute these (hack)
  set xl [expr ($xwin1-$x1)/($x2-$x1)]
  set yl [expr ($ywin1-$y1)/($y2-$y1)]
  set xr [expr ($xwin2-$x1)/($x2-$x1)]
  set yr [expr ($ywin2-$y1)/($y2-$y1)]

  set xf [expr (1.0*($x-$x1))/($x2-$x1)-($xr-$xl)/2.0]
  set yf [expr (1.0*($y-$y1))/($y2-$y1)-($yr-$yl)/2.0]

  $cur_c xview moveto $xf
  $cur_c yview moveto $yf
}


proc delta_cursor {x y} {

  set bbox [visible_bbox]

  set band 20

  if {$x < [lindex $bbox 0] + $band} {
    set deltax [expr $x - [lindex $bbox 0] - $band]
  } elseif {$x > [lindex $bbox 2] - $band} {
    set deltax [expr $x - [lindex $bbox 2] + $band]
  } else {
    set deltax 0
  }

  if {$y < [lindex $bbox 1] + $band} {
    set deltay [expr $y - [lindex $bbox 1] - $band]
  } elseif {$y > [lindex $bbox 3] - $band} {
    set deltay [expr $y - [lindex $bbox 3] + $band]
  } else {
    set deltay 0
  }

  return "$deltax $deltay"
}


# This procedure filter commands sent from the scrollbar to the canvas.

proc scroll_me {type args} {

  global cur_c WIN SCROLL_LAST

  if {[lindex $args 0] == "moveto"} {
    # Have to scale this to size of drawing not size of (much bigger) canvas
    setl {l r} [$cur_c $type]

    set scroll [lindex $args 1]

    if {![info exists SCROLL_LAST(count)]} {
      set SCROLL_LAST(count) 0
    } else {
      incr SCROLL_LAST(count)
    }

    if {![info exists SCROLL_LAST($type)]} {
      set SCROLL_LAST($type) $scroll
    }

    if {$type == "xview"} {
      setl {ls rs} [$WIN.hscroll get]
    } else {
      setl {ls rs} [$WIN.vscroll get]
    }

    set diff [expr $rs - $ls]
    if {$diff < 0.05} {
      set diff 0.05
    }

    set new [expr ($scroll-$SCROLL_LAST($type))*($r-$l)/$diff + $l]

    set SCROLL_LAST($type) $scroll
    set args "moveto $new"

    after 250 "reset_scroll $SCROLL_LAST(count)"
  }

  eval $cur_c $type $args

  set_scrollbars
}


proc reset_scroll {count} {

  global SCROLL_LAST

  if {$count < $SCROLL_LAST(count)} {
    # another scroll happened so ignore this reset
    return
  }

  unset SCROLL_LAST
}


# set the scrollbars so that they display the correct percentage of the
# schematic/icon in the window

proc set_scrollbars {} {

  global cur_c WIN

  if {[lsearch [pack slaves $WIN] $cur_c] == -1} {
    # don't set since not packed
    return
  }

  $cur_c addtag object all
  $cur_c dtag grid object

  setl {x1 y1 x2 y2} [$cur_c bbox object]
  if {$x1 == ""} {
    # nobody's home.  Thus we are showing the entire schematic/icon
    $WIN.hscroll set 0 1
    $WIN.vscroll set 0 1
    return
  }

  $cur_c dtag object

  setl {xwin1 ywin1 xwin2 ywin2} [visible_bbox]  
  if {[expr $xwin2 - $xwin1] == 1 && [expr $ywin2 -$ywin1] == 1} {
    # no update yet.
    $WIN.hscroll set 0 1
    $WIN.vscroll set 0 1
    return
  }

  # now we know how big the schematic/icon is and how big the screen is

  set xl [expr (1.0*($xwin1-$x1))/($x2-$x1)]
  set xr [expr 1.0-(1.0*($x2-$xwin2))/($x2-$x1)]
  set yl [expr (1.0*($ywin1-$y1))/($y2-$y1)]
  set yr [expr 1.0-(1.0*($y2-$ywin2))/($y2-$y1)]

  $WIN.hscroll set $xl $xr
  $WIN.vscroll set $yl $yr
}


# this routine will scroll the screen if the cursor is off screen.  
# Unfortunately, it changes x and y and cannot tell the motion routine 
# so things sometimes look weird for awhile.

proc auto_scroll {mem x y} {

  global cur_c SCROLL

  if {$SCROLL(status) != "on" || $mem < $SCROLL(mem)} {
    return
  }

  setl {dx dy} [delta_cursor $x $y]
  if {$dx == 0 && $dy == 0} {
    # not near edge or off screen, don't do anything.
    return
  }

  set scroll_percent .001

  setl {x1 y1 x2 y2} [lindex [$cur_c configure -scrollregion] 4]

  setl {xwin1 ywin1 xwin2 ywin2} [visible_bbox]

  # back compute these (hack)
  set xl [expr ($xwin1-$x1)/($x2-$x1)]
  set yl [expr ($ywin1-$y1)/($y2-$y1)]
  set xr [expr ($xwin2-$x1)/($x2-$x1)]
  set yr [expr ($ywin2-$y1)/($y2-$y1)]

  set xf [expr ($xr-$xl)*$scroll_percent*$dx + $xl]
  set yf [expr ($yr-$yl)*$scroll_percent*$dy + $yl]

  $cur_c xview moveto $xf
  $cur_c yview moveto $yf

  set nextx [expr $x + ($xwin2-$xwin1)*$scroll_percent*$dx]
  set nexty [expr $y + ($ywin2-$ywin1)*$scroll_percent*$dy]

  set_scrollbars

  after 250 "auto_scroll $mem $nextx $nexty"
}


# allows the user to center the screen on the cursor

proc setup_pan_canvas {} {

  global cur_c SAVE

  enter_mode pan abort_pan_canvas

  catch {unset SAVE}

  setl {SAVE(x) SAVE(y)} [center_bbox [visible_bbox]]

  msg_window "Press and hold Button-1 to enter pan mode, Ctrl-C aborts"

  bind_add -mode pan -hotkey Any-Button-1 \
      -command "pan_canvas %x %y"

  bind_add -mode pan -hotkey Any-B1-Motion \
      -command "pan_canvas_drag %x %y" \
      -help "Pan screen."

  bind_add -mode pan -hotkey Any-B1-ButtonRelease \
      -command "pan_canvas_end" \
      -help "End pan mode."

  bind_add -mode pan -hotkey Any-Control-c -command "abort_pan_canvas" \
      -help "Abort pan, restore to original view."

  bind_add -mode pan -hotkey space -command "help_window %x %y" \
      -help "Display this window."
}


proc pan_canvas {x y} {

  global cur_c SAVE

  msg_window "Drag Button-1 to pan, release Button-1 to end, Ctrl-C aborts"

  $cur_c scan mark $x $y
  set SAVE(pan) "$x $y"
}


init_global PAN_MAG -flags user -type number \
    -default 2 -desc {

Amount of magnification to pan screen relative to the mouse motion.  1
means that the screen moves with the mouse.
}


proc pan_canvas_drag {x y} {

  global cur_c SAVE PAN_MAG

  # don't want 10x, just move with mouse
  setl {x1 y1} $SAVE(pan)
  set x [expr int(($x - $x1) * $PAN_MAG / 10.0 + $x1)]
  set y [expr int(($y - $y1) * $PAN_MAG / 10.0 + $y1)]

  $cur_c scan dragto $x $y

  set_scrollbars
}


proc pan_canvas_end {} {

  set_scrollbars

  leave_mode pan
}


proc abort_pan_canvas {} {

  global SAVE

  puts "Aborting pan canvas."

  if {[info exists SAVE]} {
    center_canvas $SAVE(x) $SAVE(y)
  }

  leave_mode pan
}



# user drags a stroke box which zooms window to contents

proc setup_zoom_box {} {

  global cur_c COLORS SAVE SNAP_XY

  enter_mode zoom abort_zoom_box

  msg_window "Button-1 begins zoom box, Ctrl-C aborts"

  bind_add -mode zoom -hotkey Button-1 \
      -command "begin_zoom_box $SNAP_XY" \
      -help "Begin drawing zoom box at cursor location."

  bind_add -mode zoom -hotkey Button-2 \
      -command "end_zoom_box $SNAP_XY" \
      -help "Zoom in around cursor location."

  bind_add -mode zoom -hotkey Any-z \
      -command "end_zoom_box $SNAP_XY" \
      -help "Zoom in around cursor location."

  bind_add -mode zoom -hotkey Button-3 \
      -command "end_zoom_box $SNAP_XY" \
      -help "Zoom in around cursor location."

  bind_add -mode zoom -hotkey Any-Control-c -command "abort_zoom_box" \
      -help "Abort zoom."

  bind_add -mode zoom -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  # get rid of any random stroke boxes
  $cur_c delete stroke_box 
}


proc begin_zoom_box {x y} {

  global cur_c COLORS SAVE SNAP_XY

  msg_window "Drag out zoom box.  Tab toggles move box, release Button-1 to zoom, Ctrl-C aborts"

  set SAVE(x) $x
  set SAVE(y) $y

  set SAVE(mode) 0

  # this draws faster than one line
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb1"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb2"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb3"
  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(stroke_box) -tags "stroke_box sb4"

  bind_add -mode zoom -hotkey Any-B1-Motion \
      -command "drag_zoom_box $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Drag zoom box."

  bind_add -mode zoom -hotkey Any-B1-ButtonRelease \
      -command "end_zoom_box; set SCROLL(status) off" \
      -help "End zoom box, zoom."

  bind_add -mode zoom -hotkey Any-Control-c \
      -command "abort_zoom_box; set SCROLL(status) off" \
      -help "Abort zoom."

  # unset these
  bind_add -mode zoom -hotkey Button-1 -command _UNSET_
  bind_add -mode zoom -hotkey Button-2 -command _UNSET_
  bind_add -mode zoom -hotkey Button-3 -command _UNSET_
  bind_add -mode zoom -hotkey Any-z -command _UNSET_

  # toggle mode with shift key
  bind_add -mode zoom -hotkey Any-Tab \
      -command {toggle SAVE(mode) $IDIOT_DELAY} \
      -help "Toggle modes between draging zoom box and translating zoom box."
}


set TOGGLE_LOCK 0

proc toggle {var {delay 500}} {

  global TOGGLE_LOCK

  # needed to add because of launch command
  upvar 1 $var a

  if {$TOGGLE_LOCK == 0} {
    set a [expr 1 - $a]
  }

  if {$delay > 100} {
    incr TOGGLE_LOCK
    after $delay incr TOGGLE_LOCK -1
  }
}


# drags the stroke box

proc drag_zoom_box {x y} {

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


# zooms to zoom box

proc end_zoom_box {{x ""} {y ""}} {

  global cur_c
  
  if {$y == ""} {
    # get the bbox of the stroke_box
    set bbox [$cur_c bbox stroke_box]

    zoom_to_bbox $bbox
    eval center_canvas [center_bbox [$cur_c bbox stroke_box]]

    # get rid of stroke box
    $cur_c delete stroke_box 

  } else {
    # just zoom in at cursor and center
    center_canvas $x $y
    zoom 1.5

    # warp cursor
    _warp_cursor_window $cur_c
  }

  set_scrollbars

  leave_mode zoom
}


# aborts the zoom box

proc abort_zoom_box {} {

  global cur_c

  # get rid of stroke box
  $cur_c delete stroke_box 

  leave_mode zoom
}


# just zoom in at cursor and center

proc zoom_on_cursor {{x ""} {y ""} {factor 1.5} {doit ""}} {

  global cur_c DISABLE_CANVAS_EVENT

  if {$DISABLE_CANVAS_EVENT && $doit == ""} {
    # we're busy
    return
  }

  if {$y == ""} {
    # called from menu, get user to click
    setup_zoom_on_cursor
    return
  }

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 1

  center_canvas $x $y
  zoom $factor

  # warp cursor
  _warp_cursor_window $cur_c
  
  set_scrollbars

  # stop general canvas binding events
  set DISABLE_CANVAS_EVENT 0
}


proc setup_zoom_on_cursor {} {

  global cur_c SNAP_XY

  enter_mode zoom_on_cursor "leave_mode zoom_on_cursor"

  msg_window "Move cursor to zoom origin and hit Button-1, Ctrl-C aborts"

  bind_add -mode zoom_on_cursor -hotkey Any-Button-1 \
      -command "zoom_on_cursor $SNAP_XY ; leave_mode zoom_on_cursor" \
      -help "Zoom in on cursor."

  bind_add -mode zoom_on_cursor -hotkey Any-Control-c \
      -command "leave_mode zoom_on_cursor" \
      -help "Abort zoom on cursor."

  bind_add -mode zoom_on_cursor -hotkey space -command "help_window %x %y" \
      -help "Display this window."
}


# toggles the grid on or off depending on status

proc toggle_grid {} {

  global cur_s cur_c
  global SUE_${cur_s} GRID_SPACING

  if {[info exists SUE_${cur_s}(grid)] != 1} {
    set SUE_${cur_s}(grid) 0
  }

  if {[set SUE_${cur_s}(grid)] == 0} {
    set SUE_${cur_s}(grid) 1
    make_grid $GRID_SPACING
  } else {
    set SUE_${cur_s}(grid) 0
    $cur_c delete grid
  }
}


# change the grid spacing from the default

proc change_grid {} {

  global cur_c cur_s GRID_SPACING

  set title "Grid Spacing"
  set message "Enter New Grid Spacing:" 

  set changed 0
  setl {x y} $GRID_SPACING
  if {$y == ""} {
    set y $x
    set uniform 1

  } else {
    # non-uniform grid
    set uniform 0
  }

  set prop_list ""
  lappend prop_list "x x -number 1 10000 -incr 1 -validate"
  lappend prop_list "y y -number 1 10000 -incr 1 -validate \
      -when {\$uniform == 0}"
  lappend prop_list "uniform uniform binary -reload"

  # create the menu
  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  if {$uniform} {
    set GRID_SPACING $x
  } else {
    set GRID_SPACING "$x $y"
  }

  puts "Grid spacing changed to \"$GRID_SPACING\"."		    

  # Now change the grid in this cell if it is already on

  global SUE_${cur_s}

  if {[info exists SUE_${cur_s}(grid)] != 1} {
    return
  }

  if {[set SUE_${cur_s}(grid)] != 0} {
    $cur_c delete grid
    make_grid $GRID_SPACING
  }

  if {$changed} {
    change_grid
  }
}


proc make_grid {spacing} {

  global cur_c COLORS scale

  busy

  $cur_c delete grid

  setl {xg yg} $spacing
  if {$yg == ""} {
    set yg $xg
  }

  set bbox [$cur_c bbox all]
  if {$bbox == ""} {
    set bbox "0 0 0 0"
  }

  setl {bx1 by1 bx2 by2} $bbox

  set xinc [expr $xg * $scale]
  set yinc [expr $yg * $scale]

  set xcenter [expr int(($bx1 + $bx2)/(2*$xinc))*$xinc]
  set ycenter [expr int(($by1 + $by2)/(2*$yinc))*$yinc]

  set min [expr 10000 * $scale]

  set dx [expr ceil([max [expr $bx2 - $bx1] $min]/$xinc)*$xinc]
  set dy [expr ceil([max [expr $by2 - $by1] $min]/$yinc)*$yinc]

  set x1 [expr $xcenter - $dx]
  set x2 [expr $xcenter + $dx]
  set y1 [expr $ycenter - $dy]
  set y2 [expr $ycenter + $dy]

  for {set x $x1} {$x <= $x2} {set x [expr $x + $xinc]} {
    $cur_c create line $x $y1 $x $y2 -fill $COLORS(grid) -tags grid
  }

  for {set y $y1} {$y <= $y2} {set y [expr $y + $yinc]} {
    $cur_c create line $x1 $y $x2 $y -fill $COLORS(grid) -tags grid
  }

  $cur_c lower grid

  ready
}


# allows the user to draw a ruler -- mostly for placement views

proc setup_ruler {} {

  global cur_c SAVE SNAP_XY

  enter_mode ruler abort_ruler

  catch {unset SAVE}

  msg_window "Press Button-1 to enter ruler mode, Ctrl-C aborts"

  bind_add -mode ruler -hotkey Any-Button-1 \
      -command "ruler $SNAP_XY"

  bind_add -mode ruler -hotkey Motion \
      -command "ruler_drag $SNAP_XY; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Ruler drag."

  bind_add -mode ruler -hotkey Shift-Motion \
      -command "ruler_drag $SNAP_XY 1; set SCROLL(status) on; auto_scroll \[incrX SCROLL(mem)\] $SNAP_XY" \
      -help "Ruler drag toggle manhattan."

  bind_add -mode ruler -hotkey Any-Button-2 \
      -command "ruler_end; set SCROLL(status) off" \
      -help "End ruler mode."

  bind_add -mode ruler -hotkey Any-Control-c \
      -command "abort_ruler; set SCROLL(status) off" \
      -help "Abort ruler, remove partial ruler."

  bind_add -mode ruler -hotkey space -command "help_window %x %y" \
      -help "Display this window."
}


proc ruler {x y} {

  global cur_c SAVE COLORS

  if {[info exists SAVE]} {
    # first finish last one
    ruler_end 1
  }

  msg_window "Button-1 new ruler, Button-2 ends, Shift forces toggle manhattan, Ctrl-C aborts"

  set SAVE(x) $x
  set SAVE(y) $y

  $cur_c create line $SAVE(x) $SAVE(y) $SAVE(x) $SAVE(y) \
      -fill $COLORS(anchor) -tags "ruler ruler_main"
}


init_global RULER(scale) -flags "user RULER" -type REAL \
    -default 1 -desc {

Ruler scale factor.

By setting this to the factor of microns/grid, the ruler will measure
in microns.
}


init_global RULER(coord_mode) -flags "user RULER" -type STRING \
    -default relative -desc {

Either "relative" or "absolute" for labeling ruler.

In relative mode, the start of the ruler is always (0,0).  In absolute
mode, it is the absolute coordinates at the start.
}


init_global RULER(manhattan) -flags "user RULER" -type BINARY \
    -default 1 -desc {

If true (1), then the ruler will be drawn either vertically or
horizontally.  If false (0), the ruler will be drawn diagonally.

Holding down the shift key while drawing the ruler will toggle to the
other mode. 
}


proc ruler_drag {x y {shift 0}} {

  global cur_c SAVE RULER

  if {![info exists SAVE]} {
    return
  }

  set x2 $x
  set y2 $y

  if {[expr $RULER(manhattan) ^ $shift]} {
    # manhattan
    if {[expr abs($x - $SAVE(x))] > [expr abs($y - $SAVE(y))]} {
      set y2 $SAVE(y)
    } else {
      set x2 $SAVE(x)
    }
  }

  # change rule main line
  $cur_c coords ruler_main $SAVE(x) $SAVE(y) $x2 $y2

  # draws everything else about the ruler
  ruler_draw $SAVE(x) $SAVE(y) $x2 $y2
}


proc ruler_end {{continue 0}} {

  global cur_c

  $cur_c addtag tmp withtag ruler
  $cur_c dtag ruler
  $cur_c dtag ruler_main
  $cur_c dtag ruler_tick

  if {$continue} {
    return
  }

  leave_mode ruler
}


proc abort_ruler {} {

  global cur_c

  puts "Aborting ruler."

  $cur_c delete ruler

  leave_mode ruler
}


proc ruler_draw {x1 y1 x2 y2} -desc {
  draw a ruler between the given coords
} {

  global cur_c scale FONT COLORS RULER

  # choose a font that is visible
  set size very-small
  foreach one "very-large large standard small very-small" {
    if {[expr $FONT($one) * $scale] < 10} {
      set size $one
      break
    }
  }
  lappend font size_$size
  set fscale [expr int(ceil($scale))]

  set dx [expr $x2 - $x1]
  set dy [expr $y2 - $y1]

  set scale_coord [expr 1.0 * [lindex $RULER(scale) 0] / $scale]

  if { $RULER(coord_mode) == "absolute" } {
    setl {rx1 ry1 rx2 ry2} [scale_list [list $x1 $y1 $x2 $y2] $scale_coord]
  } else {
    setl {rx1 ry1 rx2 ry2} [scale_list \
	[list 0 0 [expr abs($dx)] [expr abs($dy)]] $scale_coord]
  }

  if { [approx $dx == 0] } {
    set text1 [format "%.3g" $ry1]
    set text2 [format "%.3g" $ry2]
    set pos e
  } elseif { [approx $dy == 0] } {
    set text1 [format "%.3g" $rx1]
    set text2 [format "%.3g" $rx2]
    set pos s
  } else {
    # All angle
    if { $rx1 == 0 && $ry1 == 0 } {
      set text1 "0"
    } else {
      set text1 [format "%.3g,%.3g" $rx1 $ry1]
    }
    set text2 [format "%.3g,%.3g" $rx2 $ry2]
    if { abs($dx) > abs($dy) } {
      set pos s
    } else {
      set pos e
    }
  }

  set space ""
  if {$pos == "e"} {
    set space " "
  }

  # erase old
  $cur_c delete ruler_tick

  # draw the text
  $cur_c create text $x1 $y1 -text $text1$space \
      -font $FONT($size,$fscale) -fill $COLORS(anchor) \
      -tags "ruler ruler_tick $font" -anchor $pos
  $cur_c create text $x2 $y2 -text $text2$space \
      -font $FONT($size,$fscale) -fill $COLORS(anchor) \
      -tags "ruler ruler_tick $font" -anchor $pos

  # Now the tick marks.  Compute tick mark len.
  setl {fx1 fy1 fx2 fy2} [visible_bbox]
  # How many microns are showing in the window
  set frame_microns [expr [min [expr $fx2 - $fx1] [expr $fy2 - $fy1]]]
  # Tick len is 1% of frame size.
  set tlen [expr $frame_microns * 0.005]

  if { $dx == 0 && $dy == 0 } {
    # make a little X at the origin
    # This is only used for zero length ruler, ie, drag hasnt started yet.
    $cur_c create line [expr $x1 - $tlen] [expr $y1 - $tlen] \
	[expr $x1 + $tlen] [expr $y1 + $tlen] \
	-fill $COLORS(anchor) -tags "ruler ruler_tick"

    $cur_c create line  [expr $x1 - $tlen] [expr $y1 + $tlen] \
	[expr $x1 + $tlen] [expr $y1 - $tlen] \
	-fill $COLORS(anchor) -tags "ruler ruler_tick"

  } else {
    # Note atan2 cant take (x,y) == (0,0) argument, but we dont do that.
    # Angle of ruler.
    set angle [expr atan2($dy,$dx)]
    set pi_over_2 [expr 3.1415926536 / 2.0]

    # Tick mark end-points.
    set tx [expr $tlen * cos($angle + $pi_over_2)]
    set ty [expr $tlen * sin($angle + $pi_over_2)]
    $cur_c create line [expr $x1 - $tx] [expr $y1 - $ty] \
	[expr $x1 + $tx] [expr $y1 + $ty] \
	-fill $COLORS(anchor) -tags "ruler ruler_tick"

    $cur_c create line [expr $x2 - $tx] [expr $y2 - $ty] \
	[expr $x2 + $tx] [expr $y2 + $ty] \
	-fill $COLORS(anchor) -tags "ruler ruler_tick"
		
    # Can we stick in some intermediate tick marks?
    # Dont bother trying to put text on the tick if it is an absolute
    # coordinate system and the ruler is not manhattan.  Too confusing.
    if { $RULER(coord_mode) != "absolute" || $dx == 0 || $dy == 0} {
      # TODO FIX
#      setl {px py} [dbt_frame_pixels]
      setl {px py} "800 800"

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

	    $cur_c create line [expr $tickx - $tx] [expr $ticky - $ty] \
		[expr $tickx + $tx] [expr $ticky + $ty] \
		-fill $COLORS(anchor) -tags "ruler ruler_tick"

	    if { $RULER(coord_mode) == "absolute" } {
	      # Note that one of dx or dy is 0.
	      if { $dx == 0 } {
		set coord [expr ($i * $dir + $y1) * $scale_coord]
	      } else {
		set coord [expr ($i * $dir + $x1) * $scale_coord]
	      }
	    } else {
	      # relative
	      set coord [expr abs($i * $scale_coord)]
	    }
	    # We dont want the internal tick mark too close to the endpoint,
	    # so subtract interval*.3
	    if { $i < $rulerlen - $interval*0.3} {
	      $cur_c create text $tickx $ticky \
		  -text [format "%.3g$space" $coord] \
		  -font $FONT($size,$fscale) -fill $COLORS(anchor) \
		  -tags "ruler ruler_tick $font" -anchor $pos
	    }
	  }
    }
  }
}


proc ruler_setup {} -desc {
  creates a popup for the user to select the ruler parameters.

  NOTE: can't write these out to a file
} {

  global cur_c cur_s RULER

  set title "Ruler Setup"
  set message "Enter Parameters:" 

  set prop_list ""
  lappend prop_list "Scale RULER(scale) -number -validate -help {By entering the scale factor of microns/grid here, the ruler will measure in microns.}"
  lappend prop_list "Mode RULER(coord_mode) -radio {relative absolute} -help {In relative mode, the start of the ruler is always (0,0).  In absolute mode, it is the absolute coordinates.}"
  lappend prop_list "Manhattan RULER(manhattan) -binary -help {If true (1), then the ruler will be drawn either vertically or horizontally.  If false (0), the ruler will be drawn diagonally.}"

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }
}
