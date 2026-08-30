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

set RCSVERSION(view.tcl) { $Revision: 1.15 $ }

# implements view adjustment commands.
#
# These commands generally move (warp) cursor so it is pointing to same place in
# database - for continuity during drags etc.

init_global VIEW_MIN_SIZE -default 5 -type INT -desc {
  The minimum size view, in microns, that view_cell (v) command allows.
}

# We scale LAY_LABEL_SIZE for the user.  These are the max/min actual values permitted.
set LAY_LABEL_SIZE_MAX 1000.0
set LAY_LABEL_SIZE_MIN 0.1


proc view_center {x y} -desc {
    center max window on coordinates at x,y
} -doc {
    See also: view_center_cursor.
    This function works even if the specified x,y location
    is not currently on screen.
} {
    global max_win
    setl {x0 y0 x1 y1} [$max_win.layout frame]
    
    set w [expr $x1 - $x0]
    set h [expr $y1 - $y0] 

    set x0 [uusnap [expr $x-$w/2]]
    set y0 [uusnap [expr $y-$h/2]]
    set x1 [expr $x0+$w]
    set y1 [expr $y0+$h]

    $max_win.layout frame $x0 $y0 $x1 $y1
}

proc view_center_cursor {} -desc {
    center view on cursor 
} -doc {
    By "cursor" we mean the current mouse pointer location.
    After the view is centered, the cursor is moved on the screen
    so that its current current location remains unchanged
    with respect to the data-base.
} {
    setl {x y} [layt_point exact]
    view_center $x $y

    # restore cursor to original (db) location
    layt_point -warp exact $x $y
}
    
proc view_cell {{options ""}} -desc {
    adjust view to fit cell 
} -doc {
    If options == -warp, Cursor left fixed w/r/t database.
} {
    global max_win EDIT VIEW_MIN_SIZE

    setl {x y} [layt_point exact]

    if {[lay_editcell] == [lay_rootcell] || \
	    [lindex [lindex $EDIT(stack) 0] 4] == ""} {
      # not edit in place, just view
      :view
    } else {
      # edit in place
      set save_box [layt_box exact]  ;# Save box location

      eval layt_box exact [db_bbox]
      :findbox zoom

      # save_box will be empty if view_cell is called immediately after :load
      eval layt_box exact $save_box
    }

    setl {wx1 wy1 wx2 wy2} [dbt_frame]

    # Dont let view get too tiny.
    if { $wx2 - $wx1 < $VIEW_MIN_SIZE || $wy2 - $wy1 < $VIEW_MIN_SIZE } {
      # Increase view size to VIEW_MIN_SIZE, without moving center.
      set cx [expr ($wx1 + $wx2) / 2]
      set cy [expr ($wy1 + $wy2) / 2]
      set save_box [layt_box exact]
      layt_box exact \
	[expr $cx - $VIEW_MIN_SIZE/2] [expr $cy - $VIEW_MIN_SIZE/2] \
	[expr $cx + $VIEW_MIN_SIZE/2] [expr $cy + $VIEW_MIN_SIZE/2]
      :findbox zoom
      eval layt_box exact $save_box
    }

    # The view may have changed so that x,y is off-screen, particularly
    # if we were zoomed way out and had to zoom in.  In that case,
    # do not adjust the cursor.
    if { $options == "-warp" } {
      if {$x >= $wx1 && $x <= $wx2 && $y >= $wy1 && $y <= $wy2} {
	  layt_point -warp exact $x $y
      }
    }
}

proc view_zoom2 {factor} -desc {
  Zoom view.  Print message if too far.  Leave cursor alone.
} {
  setl {xbot ybot xtop ytop} [dbt_frame]
  set w [expr $xtop-$xbot]
  set h [expr $ytop-$ybot]
  set min_dimension [expr {$w < $h ? $w : $h}]
  if { $factor < 1 && $min_dimension < 2.0 * [res] } {
    msg "Zoomed in all the way, zoom command ignored\n"
    return
  }
  :zoom $factor

  if { $factor > 1 } {
    setl {nxbot nybot nxtop nytop} [dbt_frame]
    if { $nxbot == $xbot && $nybot == $ybot && \
	$nxtop == $xtop && $nytop == $nytop } {
	msg "Zoomed out all the way, zoom command ignored\n"
    }
  }
}

proc view_zoom {factor} -desc {
    zoom by factor 
} -doc {
    Cursor left fixed w/r/t database.
} {
    global max_win

    setl {x y} [layt_point exact]
    view_zoom2 $factor
    layt_point -warp exact $x $y
}
    
proc view_zoom_cursor {factor} -desc {
    zoom in (or out) on cursor
} -doc {
    Cursor left fixed w/r/t database.
} {
    view_center_cursor
    view_zoom $factor
}

    
proc view_zoom_region {} -desc {
    Let user drag box, then zoom view to enclose specified box.
} -doc {
    Cursor left fixed with respect to the database.
} {

  if { [mode_current] == "zoom" } { 
      return
  }

  zoom_mode_enter
}

proc view_state_change {var val} -desc {
  Change state of specified view or drc option; val is 1 or 0.
} {
  global drc_on VIEW_STATUS
  # Translate old names for compatibility with pal_special_on/off
  # No longer used in Max 4.0
  set var [string tolower $var]
  switch $var {
    fastd  { set var fastdraw }
    flylns { set var flylines }
    iport -
    iports {set var instanceports }
    inames -
    iname  { set var instancesNames }
  }

  if {$var != "drc" && ![info exists VIEW_STATUS(state.$var)]} {
    error "view_state_change: invalid view control variable: $var"
    return
  }

  # drc is special;  value is in drc_on instead of VIEW_STATUS(state.$var)
  if { $var == "drc" } {
    set drc_on $val
  } else {
    set VIEW_STATUS(state.$var) $val
  }

  view_state_update $var
}


proc view_state_update {var} -desc {
  Update max view and drc options based on VIEW_STATUS.
} -doc {
  Update based on appropriate VIEW_STATUS variable.
  If var is "all", do em all.
} {
  global VIEW_STATUS

  switch $var {
    "all" {
      foreach thingy [list subcellcommentlabels labels instancenames \
	instanceports flylines dimne fastdraw drc label_size] {
	view_state_update $thingy
      }
    }
    "subcellcommentlabels" {
      lay_labels non_edit_comments $VIEW_STATUS(state.subcellcommentlabels)
    }
    "labels" {
      if { $VIEW_STATUS(state.labels) } {
	:see labels
      } else {
	:see no labels
      }
    }
    "instancenames" {
      if { $VIEW_STATUS(state.instancenames) } {
	:see instanceNames
      } else {
	:see no instanceNames
      }
    }
    "instanceports" {
      if { $VIEW_STATUS(state.instanceports) } {
	:see instancePorts
      } else {
	:see no instancePorts
      }
    }
    "flylines" {
      if { $VIEW_STATUS(state.flylines) } {
	:see flyLines
      } else {
	:see no flyLines
      }
    }
    "dimne" {
      if { $VIEW_STATUS(state.dimne) } {
	:see no allSame
      } else {
	:see allSame
      }
    }
    "fastdraw" {
      # fast display uses higher single pixel threshold, causing larger 
      # cells to be rendered by single value during zoomed out redisplay.
      # Also disables stippling during redisplay of subcells (when zoomed out)
      global OPTIONS LAY_SINGLE_PIXEL_THRESHOLD LAY_STIPPLE_GROUPS
      global LAY_PAINT_ZOT

      # Max sets the initial ZOT from the features size in tech file; save it.
      if {![info exists OPTIONS(dev,zot_fast)]} {
	set OPTIONS(dev,zot_fast) $LAY_PAINT_ZOT
	# Dont do this without asking jdj about some tests he did?
	#set OPTIONS(dev,zot_slow) [max 1000 $LAY_PAINT_ZOT]
	# For now, dont change it.
	set OPTIONS(dev,zot_slow) $LAY_PAINT_ZOT
      }
      if { $VIEW_STATUS(state.fastdraw) } {
	set LAY_SINGLE_PIXEL_THRESHOLD $OPTIONS(dev,single_pixel_threshold_fast)
	set LAY_STIPPLE_GROUPS 0
	set LAY_PAINT_ZOT $OPTIONS(dev,zot_fast)
      } else {
	# Must be "Slow Draw" :-)
	set LAY_SINGLE_PIXEL_THRESHOLD $OPTIONS(dev,single_pixel_threshold_slow)
	set LAY_STIPPLE_GROUPS 1
	set LAY_PAINT_ZOT $OPTIONS(dev,zot_slow)
      }

      lay_cache_flush
      lay_changed
    }
    "drc" {
      global drc_on
      if { $drc_on } {
	:see errors
      } else {
	:see no errors
      }
      drc_status_update
    }
    "label_size" {
      global LAY_LABEL_SIZE_FACTOR LAY_LABEL_SIZE_MAX LAY_LABEL_SIZE_MIN
      # The VIEW_STATUS(label_size) is a number between 1 and 100,
      # which we will scale to the range 0.1 to LAY_LABEL_SIZE_MAX
      # 3/1/01: Note: we used to scale between 0.1 and 10, but for
      # floorplanning the scale is alot bigger.
      # The max is in case label_size is accidently set to 0.
      set new_size [util_scale $VIEW_STATUS(label_size) 1 100 $LAY_LABEL_SIZE_MIN $LAY_LABEL_SIZE_MAX -log]
      if { [approx $new_size != $LAY_LABEL_SIZE_FACTOR] } {
	set LAY_LABEL_SIZE_FACTOR $new_size
	lay_changed
      }
    }
    default { error "view_state_update bad var: $var" }
  }
}


proc view_state_init {} -desc {
  Init display control variables.
} {
  global VIEW_STATUS

  foreach thingy [list subcellcommentlabels labels instancenames \
    instanceports flylines dimne] {
      set VIEW_STATUS(state.$thingy) 1
  }

  # Mark says start with fastdraw turned off.
  set VIEW_STATUS(state.fastdraw) 0

  global LAY_LABEL_SIZE_FACTOR LAY_LABEL_SIZE_MAX LAY_LABEL_SIZE_MIN
  set VIEW_STATUS(label_size) [util_scale $LAY_LABEL_SIZE_FACTOR 1 100 $LAY_LABEL_SIZE_MIN $LAY_LABEL_SIZE_MAX -log -rev]

  # Cant actually update the display until after window is loaded,
  # so its done from win.tcl.
}

# Do it now
view_state_init


proc _view_text_display {} -desc {
  change what text is displayed
  no longer used in Max 4.0
} {
    # We have to keep status in a global variable because
    # there is no way to query max what the current text display status is.
    global VIEW_STATUS

    set prop_menu ""
    lappend prop_list \
	    "{Show labels}  VIEW_STATUS(state.labels) -binary"

    lappend prop_list \
	    "{Enable sub-cell comment and local labels} \
	    VIEW_STATUS(state.subcellcommentlabels) -binary"
	
    lappend prop_list \
	    "{Show cell instance names} \
	    VIEW_STATUS(state.instancenames) -binary"

    # Punt on instance ports.
    # Max displays them as regular ports over the top of the
    # instance ports.  I dont think they should be on ever.
    #lappend prop_list \
	    "{Show sub-cell instance ports} \
	    VIEW_STATUS(state.instanceports) -binary"

    # create the menu
    set title "Text Display Setup"
    set ret [prop_menu2 -title $title $prop_list]
    # If user hit cancel
    if { $ret == 0 } { return }

    foreach thingy {labels instancenames instanceports subcellcommentlabels} {
	view_state_update $thingy
    }
}


proc view_display_options {} {
  global max_win
  global win_${max_win}
  global VIEW_STATUS
  set prop_list ""

  lappend prop_list [list "Show Palette" win_${max_win}(pal) -binary \
    -help "show/hide palette of layers (on left side of window.)"]

  global MAX_MARK_MENU
  if {[use_first MAX_MARK_MENU] == 1} {
    lappend prop_list [list "Mark Menu" win_${max_win}(tool_bar) -binary \
      -help "show/hide Tool Buttons (above palette)."]
  }

  # This doesnt work any more
  #lappend prop_list [list "Show Indicators" win_${max_win}(indicators) -binary \
      -help "Indicators" "show/hide visibility indicators"]

  lappend prop_list [list "Show Cell Lists" win_${max_win}(list_boxes) -binary \
    -help "show/hide cell buffer lists (on right side of window.)"]

  lappend prop_list [list "Show Navigator Window" win_${max_win}(navigator) -binary \
    -help "show/hide navigator window. (Cell Lists must also be visible.)"]

  lappend prop_list [list "Show Bottom Bar" win_${max_win}(bot_bar) -binary \
    -help "show/hide status & zoom bar (at bottom of window.)"]

  lappend prop_list [list "Show Scroll Bars" win_${max_win}(scroll) -binary \
    -help "show/hide scroll bars."]

  lappend prop_list [list "Dim Non-Edit Cells" VIEW_STATUS(state.dimne) \
    -binary -help "show paint and text that is not in the current edit-cell in a dimmer color."]

  lappend prop_list [list "Fast Draw" VIEW_STATUS(state.fastdraw) \
    -binary -help "repaint very large views faster, but with less detail."]

  lappend prop_list [list "Show Flylines" VIEW_STATUS(state.flylines) \
    -binary -help "show flylines, when zoomed in far enough."]


  lappend prop_list [list "Show Text (labels)" VIEW_STATUS(state.labels) \
    -binary -help {show/hide Text (labels), when zoomed in far enough.\
    Does not affect cell instance names or other types of textual information.}]

  lappend prop_list [list \
    "   Show sub-cell comment and local Text (labels)" \
    VIEW_STATUS(state.subcellcommentlabels) -binary \
    -help {show/hide Text of types "local" and "comment" for sub-cells.\
    Only works if "Show Text (labels)" is also on.\
    Note that these Text types are always displayed in the edit-cell.}]
      
  lappend prop_list [list \
    {For sub-cells with internals hidden:} {} -label]

  lappend prop_list [list \
    {    Show cell instance names} \
    VIEW_STATUS(state.instancenames) -binary \
    -help {show/hide cell instance names of unselected sub-cells with internals hidden.}]

  # Max displays them as regular ports over the top of the
  # instance ports.  I dont think they should be on ever.
  lappend prop_list [list \
    {    Show ports} VIEW_STATUS(state.instanceports) -binary \
    -help {show/hide Text ports (Text of types "input", "output" or "inout")\
    even when sub-cell internals hidden.}]

  global LAY_LABEL_SIZE_FACTOR LAY_LABEL_SIZE_MAX LAY_LABEL_SIZE_MIN
  set VIEW_STATUS(label_size) [util_scale $LAY_LABEL_SIZE_FACTOR 1 100 $LAY_LABEL_SIZE_MIN $LAY_LABEL_SIZE_MAX -log -rev]
  lappend prop_list [list \
    {Text Size Factor:} VIEW_STATUS(label_size) -scale 1 100 \
    -help {controls the zoom level at which Text labels disappear.\
    Larger numbers make Text labels more visible when zoomed out.}]
  
  set title "Display Options"
  # NOTE: You MUST do the view_state_update before the win_pack.
  # The win_pack temporarily screws up LAY_DB_UNITS_PER_PIXEL until
  # the next update, and its needed by view_state_update.
  set ret [prop_menu2 -title $title -apply {view_state_update all;win_pack} $prop_list]
  # If user hit cancel
  if { $ret == 0 } { return }
  view_state_update all
  win_pack
  return
}
