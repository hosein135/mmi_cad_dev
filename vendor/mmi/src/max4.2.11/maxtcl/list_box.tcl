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

set RCSVERSION(list_box.tcl) { $Revision: 1.30 $ }

# Routines implementing list boxes of cells and generators at right side 
# of max window

# these next three variables should be in the .maxrc
init_global LIST_BOXES -default 2 -desc {
  number of list boxes in the max window at startup
} -type INT

set _LIST_BOX_(width) 15

init_global ZOOM_BUTTONS -default "green blue yellow" -desc {
  the colors of the zoom buttons in the navigator window
} -type LIST

proc list_box_update args -desc {
  updates list_boxes
} -doc {
  called between each interactive command.
} {
  global _LIST_BOX_ 

  navigator_update

  # if state hasn't changed since last update, just return
  if { $args != "refresh" && [info exists _LIST_BOX_(last_db_cells)] && \
	   $_LIST_BOX_(last_db_cells) == [db_cells -user] } {
    return
  }

  set _LIST_BOX_(last_db_cells) [db_cells -user]

  foreach w [winfo children .] {
    if {[info exists _LIST_BOX_($w)]} {
      foreach win $_LIST_BOX_($w) {
	_list_box_fill $win
      }
    }
  }
}


proc list_boxes_build {w} -desc {
  Build list_boxes frame on right border of max window
} -doc {
  w = parent widget.
} {
  global _LIST_BOX_ LIST_BOXES

  if {![winfo exists $w.list_boxes]} {
    frame $w.list_boxes
  }

  if {![winfo exists $w.resize_list_boxes]} {
    # make a special frame for resizing the listboxes
    frame $w.resize_list_boxes -width 2 -bd 1
    pack $w.resize_list_boxes -side right -fill y
    bind $w.resize_list_boxes <Enter> "_listbox_resize $w enter"
    bind $w.resize_list_boxes <Leave> "_listbox_resize $w leave"
    bind $w.resize_list_boxes <Button-1> "_listbox_resize $w start %X"
    bind $w.resize_list_boxes <Button1-Motion> "_listbox_resize $w move %X"
    bind $w.resize_list_boxes <B1-ButtonRelease> "_listbox_resize $w release"
  }

  # this array keeps a list of the listboxes for this window
  if {[use_first _LIST_BOX_($w)] == ""} {
    for {set i 0} {$i < $LIST_BOXES} {incr i} {
      lappend _LIST_BOX_($w) $w.list_boxes.n$i
    }
  }

  foreach win $_LIST_BOX_($w) {
    if {![winfo exists $win]} {
      # make the window and pack it in
      _list_box_build $win
    }

    # fill this window with goob
    _list_box_fill $win
  }

  return $w.list_boxes
}


proc _list_box_build {win} -desc {
  Make a list_box frame and pack into given max window
} {
  global _LIST_BOX_ LISTBOX_FONT max_win

  # make a new listbox
  frame $win -relief sunken -bd 2 -width 10
  pack $win -side top -fill y -expand 1

  # get the desired width
  set command "[lindex $_LIST_BOX_($max_win) 0].names"
  if {[catch "$command cget -width" width]} {
    # first time, use default
    set width $_LIST_BOX_(width)
  }

  # just make the dir blank for now
  menubutton $win.dir -text "" -menu $win.dir.other -font $LISTBOX_FONT \
	-relief raised -bd 2 -anchor e -width $width \
	-padx 2 -pady 2
  pack $win.dir -side top -fill x

  menu $win.dir.other -tearoff 0

  scrollbar $win.scroll -command "$win.names yview" -highlightthickness 0
  pack $win.scroll -side right -fill y
  listbox $win.names -yscrollcommand "$win.scroll set" \
      -exportselection 0 \
      -selectmode single \
      -highlightthickness 0 \
      -width $width -height 4 
  pack $win.names -side left -fill both -expand 1

  # need to use a fixed width font here so modified "M" looks right
  $win.names configure -font $LISTBOX_FONT

  bind $win.names  <Any-Enter> \
      {mode_msg "ListBox: BUT-1 loads cell, SHIFT-BUT-1 drops cell into current" listbox}
  #bind $win.names <Any-Leave> "mode_msg __RESTORE__ listbox"

  bind $win.names <Any-Motion> \
      {%W selection clear 0 end; %W selection set [%W nearest %y]} 

  bind $win.names <Shift-Button-1> \
      "_list_box_execute $win.names cell_make_instance"
  bind $win.names <Button-1> \
      "_list_box_execute $win.names cell_load"

  pack $win -side top
}


proc _list_box_execute {lwin command} -desc {
  gets called when someone clicks on an entry in a listbox
} -doc {
  tack the currently selected filename from specified listbox window: lwin
  onto command, then execute it.
} {
  if {[set sel_index [$lwin curselection]] != ""} {
     set selection [$lwin get $sel_index]
  } else {
    return  ;# What to do?
  }

  set type [string index $selection 0]
  set cell [string range $selection 3 end]

  # If the cell name contains $, ", etc, the i_cmd_eval will
  # screw it up.  To avoid this, quote it.
  if {$type == "G"} {
    # special case for gcells
    #i_cmd_eval make_gcell [quote_string $cell]
    i_cmd_eval [list make_gcell $cell]

  } else {
    # just do the command
    #i_cmd_eval $command [quote_string $cell]
    i_cmd_eval [list $command $cell]
  }
}


proc _list_box_fill_dir {dir} -desc {
  fill list_boxes and make sure this directory is visible
} {

  global _LIST_BOX_ max_win

  if {[info exists max_win]} {
    foreach win $_LIST_BOX_($max_win) {
      set display_dir [$win.dir cget -text]
      if {$dir == $display_dir} {
	# already in, just update
	_list_box_fill $win
	return
      }
    }

    # not it, add this dir to top
    _list_box_fill [lindex $_LIST_BOX_($max_win) 0] $dir
  }
}


proc _list_box_fill {win {dir ""}} -desc {
  fill/refill list_boxes
} {

  global LISTBOX GCELL_DIRS

  # first remember where the scroll bar was to return there
  set scroll [lindex [$win.scroll get] 0]

  # clean out any old listbox info
  $win.names delete 0 end
  # clean out old listbox directories.  Wish end worked here too.
  $win.dir.other delete 0 1000

  if {$dir == ""} {
    set dir [$win.dir cget -text]
    if {$dir == ""} {
      # is this right?
      set dir [lindex [cell_path_add] 0]
    }
  }

  $win.dir configure -text $dir

  # now fill 'er up

  # add autoload and alphabetize
  $win.dir.other add command -label "Autoload directory" \
      -command "max_auto_load $dir"
  $win.dir.other add command -label "Alphabetize" \
      -command "set LISTBOX($dir) alpha ; list_box_update refresh"
  $win.dir.other add separator

  # put in a menu item for remove icon menu and add another
  $win.dir.other add command -label "Make new listbox" \
      -command "_new_list_box $win"
  $win.dir.other add command -label "Close this listbox" \
      -command "_waste_list_box $win"
  $win.dir.other add separator

  # get the gcells in this directory
  foreach gcell [lsort [array names GCELL_DIRS]] {

    set this_dir $GCELL_DIRS($gcell)

    # add directories
    if {![info exists dirs($this_dir)]} {
      $win.dir.other add command -label $this_dir \
	  -command "_list_box_fill $win $this_dir"
      set dirs($this_dir) 1
    }

    if {$this_dir != $dir} {
      # not in this directory
      continue
    }

    # gcells get this special prefix
    set prefix "G  "

    $win.names insert end "$prefix$gcell"
  }

  # Now put the cell names into it
  if {[lsearch [use_first LISTBOX($dir)] alpha] != -1} {
    # alphabetize
    set cells [lsort [split [db_cells] \n]]
  } else {
    set cells [split [db_cells] \n]
  }

  foreach cell $cells {
    setl {name flags file} $cell 

    set this_dir [file dirname $file]
    if {$this_dir == "."} {
      set this_dir [pwd]
    }

    # add directories
    if {![info exists dirs($this_dir)]} {
      $win.dir.other add command -label $this_dir \
	  -command "_list_box_fill $win $this_dir"
      set dirs($this_dir) 1
    }

    if {$this_dir != $dir} {
      continue
    }

    set internal [expr [memq $flags internal] || [memq $flags generated]]
    set modified [memq $flags modified]
    set available [memq $flags available]
    set readOnly [memq $flags readOnly]

    if {$internal || ( ! $available ) } {
      continue
    }

    if { $name == "(UNNAMED)" && !$modified } {
	continue
    }

    if {$readOnly && $modified} {
	set prefix "MR " 
    } elseif {$readOnly} {
	set prefix "R  " 
    } elseif {$modified} {
	set prefix "M  "
    } else {
	set prefix "   "
    }

    $win.names insert end "$prefix$name"
  }

  # put the scrollbar back where it was
  $win.names yview moveto $scroll
}


proc _waste_list_box {win} -desc {
  delete the given listbox
} {

  global _LIST_BOX_

  set win_list [split $win .]
  set w [join [lrange $win_list 0 [expr [llength $win_list] - 3]] .]

  if {[llength $_LIST_BOX_($w)] < 2} {
    error "Can't close last list box!"
    return
  }

  # first remove the window out of list_box
  set index [lsearch $_LIST_BOX_($w) $win]
  set _LIST_BOX_($w) [lreplace $_LIST_BOX_($w) $index $index]

  # then nuke the window
  if {[winfo exists $win]} {
    destroy $win
  }
}


proc _new_list_box {win} -desc {
  add a new listbox
} {

  global _LIST_BOX_

  set win_list [split $win .]
  set w [join [lrange $win_list 0 [expr [llength $win_list] - 3]] .]

  # pick unique win name
  set i 1
  while {[winfo exists $w.list_boxes.n$i]} {
    incr i;
  }

  set win $w.list_boxes.n$i

  lappend _LIST_BOX_($w) $win

  _list_box_build $win

  # fill this window with goob
  _list_box_fill $win ""
}


# NOT USED

#proc list_grow_shrink_build {top} -desc {
#  return two buttons for top menu bar
#} {
#
#  set grow [button $top.grow -text < -padx 0 -pady 0 \
		-highlightthickness 0 \
		-command {_resize_listboxes 2}]
#  set shrink [button $top.shrink -text > -padx 0 -pady 0 \
		  -highlightthickness 0 \
		  -command {_resize_listboxes -2}]
#
#  return "$shrink $grow"
#}

proc _resize_listboxes {w delta} -desc {
   resizes width of included listboxes
} -doc {
   w is the top-level window, typically .win1
} {
  global _LIST_BOX_ _navigator LISTBOX_FONT

  # Set the frame width in pixels.
  set old_width [[lindex $_LIST_BOX_($w) 0].names cget -width]
  set width [expr $old_width + $delta]

  if { $width < 4 } {
    return
  }
  # No more than 75% of screen.
  set winwidth [expr [winfo width $w] / [font measure $LISTBOX_FONT 0]]
  if { $width > 0.75 * $winwidth } {
    set width [expr int(0.75 * $winwidth)]
  }

  # Width of scrollbar.
  set swidth [min [expr $width + 5] 10]

  foreach listbox $_LIST_BOX_($w) {
    $listbox.names configure -width $width
    $listbox.dir configure -width $width

    $listbox.scroll configure -width $swidth
  }
  update
}


proc _listbox_resize {w type {x ""}} -desc {
  changes cursors and resizes the list box
} {
  global _LISTBOX_RESIZE_ _LIST_BOX_ LISTBOX_FONT

  switch $type {
    enter {
      mode_msg "ListBox resize bar: press and hold BUT-1 to resize ListBox border" tmp
      if {[info exists _LISTBOX_RESIZE_(cursor)]} {
	# already here
	return
      }
      cursor_override movex 
      $w.resize_list_boxes config -background black

      #set _LISTBOX_RESIZE_(cursor) [$w cget -cursor]
      # horiz double arrow
      #$w configure -cursor sb_h_double_arrow
    }

    leave {
      if {![info exists _LISTBOX_RESIZE_(button)]} {
      # 	      && [info exists _LISTBOX_RESIZE_(cursor)]
      #   $w configure -cursor $_LISTBOX_RESIZE_(cursor)
      #   catch {unset _LISTBOX_RESIZE_(cursor)}
          cursor_override ""
	  $w.resize_list_boxes config -background bisque
      }
    }

    start {
      set _LISTBOX_RESIZE_(button) 1

      # unpack all the boxes.
      pack forget $w.list_boxes.navigator
#      foreach win $_LIST_BOX_($w) {
#	if {[winfo exists $win]} {
#	  # unpack it temporarily.
#	  pack forget $win
#	}
#      }
    }

    move {
#      _resize_listboxes $w
#      foreach win $_LIST_BOX_($w) {
#	if {[winfo exists $win]} {
#	  # repack it.
#	  pack $win -side top -fill both -expand 1
#	}
#      }

      set actualx [winfo rootx $w.list_boxes]

      if {$x > [expr $actualx + 7]} {
      	_resize_listboxes $w -1
      } elseif {$x < [expr $actualx - 7]} {
      	_resize_listboxes $w 1
      }
    }

    release {
      cursor_override ""
      $w.resize_list_boxes config -background bisque

      catch {unset _LISTBOX_RESIZE_(button)}

      # repack navigator      
      set listbox [lindex $_LIST_BOX_($w) 0]
      # width in chars of first listbox
      set width [$listbox.names cget -width]
      # convert to pixels
      set width [expr $width * [font measure $LISTBOX_FONT 0]]
      # add scroll bar
      set width [expr $width + [$listbox.scroll cget -width]]
      # configure navigator
      $w.list_boxes.navigator config -width $width
      pack $w.list_boxes.navigator
      navigator_update
 
#      foreach win $_LIST_BOX_($w) {
#	if {[winfo exists $win]} {
#	  # repack it.
#	  pack $win -side top -fill both -expand 1
#	}
#      }
#      win_pack
    }
  }
}


##
## Navigator window stuff
##


# Build the navigator window
# We dont know the width of the frame yet.
# We will give it a default height and a width of 1.
# Whenever we do an update, we will check the width, and if it 1,
# we will resize it before redrawing it.
proc navigator_build { max_win } {
    global _navigator
    set _navigator(processed) 0
    canvas $max_win.list_boxes.navigator -height 100 -width 1 \
	-relief sunken -borderwidth 2
    # pack $max_win.list_boxes.navigator -side bottom
}

# Called on mouse press: mark current location
proc _navigator_mark { c x y } {
    global _navigator
    if { $_navigator(processed) } { return }
    set x [$c canvasx $x]
    set y [$c canvasy $y]
    set _navigator(X1) $x
    set _navigator(X2) $x
    set _navigator(Y1) $y;  # Init in case user releases immediately
    set _navigator(Y2) $y;  # without dragging the mouse
    $c delete view
}

# Called on mouse button-1 drag: drag out a rectangle for the new view window.
proc _navigator_drag { c x y } {
    global _navigator

    if {$_navigator(processed)} {
      # someone already got this
      return
    }

    set x [$c canvasx $x]
    set y [$c canvasy $y]
    if {($_navigator(X1) != $x) || ($_navigator(Y1) != $y)} {
	$c delete view; # deletes the rectangle tagged "view".
	$c create rectangle \
	    $_navigator(X1) $_navigator(Y1) \
	    $x $y -outline red -tag view
	set _navigator(X2) $x
	set _navigator(Y2) $y
    }
}

proc _navigator_move_view {x1 y1 x2 y2 {zoom {}}} {
    # The x1 y1 x2 y2 may not be on max grids, which would
    # cause lay_box to complain, but layt_box takes care of it.
    layt_box dontcare $x1 $y1 $x2 $y2
    eval :findbox $zoom
}


# Proc called to process navigator box mouse events.
# If event==1, then user dragged out a box, set the current selection
# to the user selection if it is non-empty.
# If event==2 or 3, user just clicked or dragged the mouse button 2 or 3,
# which means center the clicked location.
proc _navigator_zoom { event c x y {done ""}} {
    global _navigator max_win

    if { $_navigator(processed) } {
      # it was in the view button area; someone already got this
      return
    }
  
    set x [$c canvasx $x]
    set y [$c canvasy $y]
    set _navigator(X2) $x
    set _navigator(Y2) $y
    if { $event >= 2 } {
	# We are just moving the existing view, not dragging out a new one.
	# so the _navigator coordinates map a zero size box.
	# We will want to center the view on this point.
	set _navigator(X1) $x
	set _navigator(Y1) $y
    }
    # Convert the coords from nav window to main window.
    setl {x1 y1 x2 y2} \
	[_navigator_convert "$_navigator(X1) $_navigator(Y1) $_navigator(X2) $_navigator(Y2)"]

    # Save the old box, and move box to the moused coordinates.
    set oldbox [layt_box exact]
    if {$event == 1} {
	if { $_navigator(X1) != $_navigator(X2) &&
	    $_navigator(Y1) != $_navigator(Y2)} {
	    # The user dragged out a new view with mouse button 1.
	    # Move the view to the new location.
	    _navigator_move_view $x1 $y1 $x2 $y2 zoom
	}
    } elseif {$event == 2 || $event == 3} {
	# Move the box to the mouse location, without changing size.
	# First make sure the box is not being moved out into space.
	# To implement this, constrain the center of the new view not to
	# move outside of the rectangle enclosing the bbox and cursor box,
	# more than the width of the current view / 2.5.
	# Dividing by 2.5 instead of 2 makes sure that a little sliver
	# of the design is always visible on the edge of the view.
	scan [lay_bbox] "%f %f %f %f" bbox_x1 bbox_y1 bbox_x2 bbox_y2
	scan [layt_box dontcare] "%f %f %f %f" box_x1 box_y1 box_x2 box_y2
	scan [$max_win.layout frame] "%f %f %f %f" view_x1 view_y1 view_x2 view_y2
	set mx1 [expr [min $bbox_x1 $box_x1] - ($view_x2 - $view_x1)/2.5]
	set mx2 [expr [max $bbox_x2 $box_x2] + ($view_x2 - $view_x1)/2.5]
	set my1 [expr [min $bbox_y1 $box_y1] - ($view_y2 - $view_y1)/2.5]
	set my2 [expr [max $bbox_y2 $box_y2] + ($view_y2 - $view_y1)/2.5]
	set x1 [max $x1 $mx1]
	set x1 [min $x1 $mx2]
	set y1 [max $y1 $my1]
	set y1 [min $y1 $my2]
	# Note: we give it x1 y1 for both corners - thats not a mistake;
	# We are not changing the size, so size doesnt matter.
	_navigator_move_view $x1 $y1 $x1 $y1
    }
    # Restore original box and redraw nav window
    eval layt_box exact $oldbox
    navigator_update
}

# Draw a rectrangle.  Then, if its too tiny to see, draw a
# cross surrounding it.
# c is nav window name, commands are the drawing commands, eg: -fill 
proc _navigator_rectangle {c x1 y1 x2 y2 color {extra_command {}}} {
    eval $c create rectangle $x1 $y1 $x2 $y2 -outline $color $extra_command
    # If rectangle is less than a few pixels in its largest dimension,
    # draw a cross around it.
    if {[max [expr $x2-$x1] [expr $x1-$x2] [expr $y2-$y1] [expr $y1-$y2]] < 4} {
	set x [expr ($x1+$x2)/2]
	set y [expr ($y1+$y2)/2]
	$c create line [expr $x-10] $y [expr $x-5] $y -fill $color
	$c create line [expr $x+5] $y [expr $x+10] $y -fill $color
	$c create line $x [expr $y-10] $x [expr $y-5] -fill $color
	$c create line $x [expr $y+5] $x [expr $y+10] -fill $color
    }
}

# Update the navigator window, if necessary.
# We know it is necessary if the width is set to 1.
proc navigator_update {} -desc {
   Update navigator window, if necessary.
} {
    global max_win _navigator ZOOM_BUTTONS
    # Drawn lines only show if they are 2 pixels inside the border
    # of the canvas widget.  We also have to subtract the -borderwidth.
    # So the actual visible border is $border-2-borderwidth.
    set border 10;      # Unused border around stuff we draw.

    # See if the nav window is enabled.
    upvar #0 win_$max_win win_cur
    if {! $win_cur(navigator) } { return }

    set c $max_win.list_boxes.navigator;  # Name of our canvas window

    if {[$c cget -width] == 1} {
	set navwidth [winfo width $max_win.list_boxes]
	# Need to subtract -4 for the border.  Otherwise
	# the packer has to work harder to pack the list-boxes,
	# and it visibly shrinks and then grows the list-boxes in the x
	# direction when you resize.
	$c config -width [expr $navwidth-4]
    }

    # The reported width and height include the -borderwidth.
    set nav_width [winfo width $c]
    set nav_height [winfo height $c]

    # leave some room for the buttons
    set button_width 10
    set nav_width [expr $nav_width - $button_width + 4]

    # Clear ye olde navigator window
    eval $c delete [$c find all]

    # Get a bounding box (x1,y1,x2,y2) that encloses the
    # displayed chip (bbox), the cursor box (box), and the current view.

    set bbox [lay_bbox]
    set box [layt_box dontcare]	
		
    setl {bbox_x1 bbox_y1 bbox_x2 bbox_y2} $bbox
    if {$box != ""} {
        setl {box_x1 box_y1 box_x2 box_y2} $box
    } else {
        setl {box_x1 box_y1 box_x2 box_y2} $bbox
    }
    setl {view_x1 view_y1 view_x2 view_y2} [$max_win.layout frame]

    set x1 [min $bbox_x1 $box_x1 $view_x1]
    set x2 [max $bbox_x2 $box_x2 $view_x2]
    set y1 [min $bbox_y1 $box_y1 $view_y1]
    set y2 [max $bbox_y2 $box_y2 $view_y2]

    # Determine the scale factor to convert from view coordinates
    # to the nav window, and the (xorigin,yorigin) in the nav
    # window in pixels corresponding to (x1,y1).
    # Ie, (xorigin,yorigin) is the number of pixels from the corner
    # of the nav window where the world view (x1,y1) is.
    # First decide whether x or y is smaller
    # relative to world coordinates, and determine scale from
    # the limiting dimension (x or y).  Add $border extra pixels to make
    # sure stuff drawn in the nav window is visible with a nice border.

    set scale1 [expr (0.0 + $nav_width-$border*2) / ($x2-$x1)]
    set scale2 [expr (0.0 + $nav_height-$border*2) / ($y2-$y1)]
    if { $scale1 < $scale2 } {
	set scale $scale1
	set xorigin $border;
	set yorigin [expr (($nav_height) - (($y2-$y1) * $scale))/2]
    } else {
	set scale $scale2
	set xorigin [expr (($nav_width) - (($x2-$x1) * $scale))/2]
	set yorigin $border;
    }

    # Determine translation from view coords to nav coords.
    # The y coord is flipped, so subtract ($nav_height - 1)
    set xtranslate [expr $xorigin - $x1 * $scale]
    set ytranslate [expr ($nav_height-1) - ($yorigin - $y1 * $scale)]

    set _navigator(scale) $scale
    set _navigator(xtranslate) $xtranslate
    set _navigator(ytranslate) $ytranslate

    # Make the background of the canvas grey to match the layout.
    $c create rectangle 0 0 1000 1000 -fill grey

    # Draw a black box for the design bbox, and a white box
    # for the cursor box.  We would really like a thumbnail of the chip,
    # not a rectangle, but oh well.

    $c create rectangle \
	[expr $bbox_x1 * $scale + $xtranslate] \
	[expr $ytranslate - $bbox_y1 * $scale] \
	[expr $bbox_x2 * $scale + $xtranslate] \
	[expr $ytranslate - $bbox_y2 * $scale] \
	-fill black -stipple gray50
    _navigator_rectangle $c \
	[expr $view_x1 * $scale + $xtranslate] \
	[expr $ytranslate - $view_y1 * $scale] \
	[expr $view_x2 * $scale + $xtranslate] \
	[expr $ytranslate - $view_y2 * $scale] \
	"red" "-tag view"
    _navigator_rectangle $c \
	[expr $box_x1 * $scale + $xtranslate] \
	[expr $ytranslate - $box_y1 * $scale] \
	[expr $box_x2 * $scale + $xtranslate] \
	[expr $ytranslate - $box_y2 * $scale] \
	"white"
    
    # create some happy zoom buttons
    set num [llength $ZOOM_BUTTONS]
    set dy [expr ($nav_height - 4.0) / $num]
    set y [expr 1 + $dy * 0.15]
    set cell [lay_rootcell]

    # save last zoom if changed
    set frame [$max_win.layout frame]
    if {![info exists _navigator($cell,last)]} { 
      # remember for next time
      set _navigator($cell,last) $frame

    } elseif {$_navigator($cell,last) != $frame} {
      # save the last zoom into button 0
      set _navigator($cell,button_0) $_navigator($cell,last)
      set _navigator($cell,last) $frame
    }

    for {set i 0} {$i < $num} {incr i} {
      $c create rectangle \
	  [expr $nav_width - 8] $y \
	  [expr $nav_width + $button_width - 8] [expr $y + $dy * .7] \
	  -fill [lindex $ZOOM_BUTTONS $i] \
	  -tags "buttons button_$i"
      set y [expr $y + $dy]

      if {[info exists _navigator($cell,button_$i)]} {
	# show this to the user
	setl {x1 y1 x2 y2} \
	    [_navigator_unconvert $_navigator($cell,button_$i)]
	$c create rectangle $x1 $y1 $x2 $y2 \
	    -outline [lindex $ZOOM_BUTTONS $i] \
	    -tags "rect_button_$i"
      }
    }

    # setup bindings for buttons
    # don't let this button click go to the rest of the window
    $c bind buttons <Button-1> "_navigator_button goto ; set _navigator(processed) 1"
    $c bind buttons <Button-2> "_navigator_button save ; set _navigator(processed) 1"
    $c bind buttons <Button-3> "_navigator_button save ; set _navigator(processed) 1"

    set msg "Navigator: drag BUT-1 to zoom, BUT-2/3 pans"

    $c bind buttons <Any-Enter> \
	{mode_msg "Navigator Zoom: BUT-1 zooms, BUT-2/3 saves current zoom" nav}
    $c bind buttons <Any-Leave> [list mode_msg $msg nav]

    # button 0 is a special case
    $c bind button_0 <Any-Enter> \
	{mode_msg "Navigator Zoom: BUT-1 zooms to last" nav}
    $c bind button_0 <Any-Leave> [list mode_msg $msg nav]

    bind $c <Any-Enter> [list mode_msg $msg nav]
    #bind $c <Any-Leave> {mode_msg __RESTORE__ nav}

    bind $c <Button-1> "_navigator_mark $c %x %y"
    bind $c <Button1-Motion> "_navigator_drag $c %x %y"
    bind $c <ButtonRelease-1> "_navigator_zoom 1 $c %x %y done ; \
	set _navigator(processed) 0"
    bind $c <Button-2> "_navigator_zoom 2 $c %x %y"
    bind $c <Button2-Motion> "_navigator_zoom 2 $c %x %y"
    bind $c <ButtonRelease-2> "set _navigator(processed) 0"
    bind $c <Button-3> "_navigator_zoom 3 $c %x %y"
    bind $c <Button3-Motion> "_navigator_zoom 3 $c %x %y"
    bind $c <ButtonRelease-3> "set _navigator(processed) 0"

    # DEBUG: Draw a rectangle around the nav window so we can see where it is
    #$c create rectangle \
    #   1 1 [expr $nav_width-3] [expr $nav_height-3] -outline blue

}


proc _navigator_button {command} -desc {
  user clicked on a button in the navigator window.  Do something about it.
} {
  global max_win _navigator

  set c $max_win.list_boxes.navigator;  # Name of our canvas window

  # get the button number that the user pressed
  set id [$c find withtag current]
  set button [lindex [$c gettags $id] 1]
  
  set cell [lay_rootcell]

  if {$command == "save"} {
    # save this frame associated with this rootcell
    set _navigator($cell,$button) [$max_win.layout frame]
    puts "Saved current view; use Button-1 later to return to this view."
    navigator_update

  } else {
    # goto this zoom if defined
    if {[info exists _navigator($cell,$button)]} {
      set save_box [layt_box exact]

      eval layt_box dontcare $_navigator($cell,$button)
      :findbox zoom

      eval layt_box exact $save_box
    }
  }
}


proc _navigator_convert {coords} -desc {
  convert coords from nav window to max window
} {

  global _navigator

  setl {X1 Y1 X2 Y2} $coords

  set scale $_navigator(scale)
  set xt $_navigator(xtranslate)
  set yt $_navigator(ytranslate)

  set x1 [expr ($X1 - $xt) / $scale]
  set y1 [expr ($yt -  $Y1) / $scale]
  set x2 [expr ($X2 - $xt) / $scale]
  set y2 [expr ($yt -  $Y2) / $scale]

  return [list $x1 $y1 $x2 $y2]
}


proc _navigator_unconvert {coords} -desc {
  convert coords from max window to nav window
} {

  global _navigator

  setl {X1 Y1 X2 Y2} $coords

  set scale $_navigator(scale)
  set xt $_navigator(xtranslate)
  set yt $_navigator(ytranslate)

  set x1 [expr $scale * $X1 + $xt]
  set y1 [expr $yt - $scale * $Y1]
  set x2 [expr $scale * $X2 + $xt]
  set y2 [expr $yt - $scale * $Y2]

  return [list $x1 $y1 $x2 $y2]
}


