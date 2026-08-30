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

set RCSVERSION(tool_bar.tcl) { $Revision: 1.11 $ }

init_global TOOL_BAR(select_mode) \
	-type STRING \
	-default "Select" \
	-desc { Initial mode in tool bar }

init_global TOOL_BAR(layer) \
	-type STRING \
	-default "auto" \
	-desc { Initial layer in tool bar }


# These all work: these were the original toolbar items.
#set TOOL_BAR(items) "Select Rect Polygon Circle Wire Rewire Flyline Label"
set TOOL_BAR(items) "Select Wire Chipper"
set TOOL_BAR(mode) [lindex $TOOL_BAR(items) 0]

###########################################################
# NOTE!!!  The lines can not begin with a hash mark or they
# will be removed by remove_comments.tcl that is used
# when preparing tcl code to be used inside max.
# It *will* work in developer mode, though, so dont get confused.
###########################################################
set hashmark "#"
set BITMAPS(+,11) "
${hashmark}define cross_width 11
${hashmark}define cross_height 11
static char cross_bits[] = {
   0x20, 0x00, 0x20, 0x00, 0x20, 0x00, 0x20, 0x00, 0x20, 0x00, 0xff, 0x07,
   0x20, 0x00, 0x20, 0x00, 0x20, 0x00, 0x20, 0x00, 0x20, 0x00};
"

set BITMAPS(-,11) "
${hashmark}define cross_width 11
${hashmark}define cross_height 11
static char cross_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x07,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
"

set BITMAPS(+,9) "
${hashmark}define plus_width 9
${hashmark}define plus_height 9
static char plus_bits[] = {
   0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0xff, 0x01, 0x10, 0x00,
   0x10, 0x00, 0x10, 0x00, 0x10, 0x00};
"

set BITMAPS(-,9) "
${hashmark}define minus_width 9
${hashmark}define minus_height 9
static char minus_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x01, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
"

set BITMAPS(+,7) "
${hashmark}define plus_width 7
${hashmark}define plus_height 7
static char plus_bits[] = {
   0x08, 0x08, 0x08, 0x7f, 0x08, 0x08, 0x08};
"

set BITMAPS(-,7) "
${hashmark}define minus_width 7
${hashmark}define minus_height 7
static char minus_bits[] = {
   0x00, 0x00, 0x00, 0x7f, 0x00, 0x00, 0x00};
"

# 8x8 version with double wide + and -.
set BITMAPS(+) "
${hashmark}define plus_width 8
${hashmark}define plus_height 8
static char plus_bits[] = {
   0x18, 0x18, 0x18, 0xff, 0xff, 0x18, 0x18, 0x18};
"

set BITMAPS(-) "
${hashmark}define minus_width 8
${hashmark}define minus_height 8
static char minus_bits[] = {
   0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00};
"

# What should a button to clear the ruler look like?  Hmm.
set BITMAPS(clear) "
${hashmark}define clr_width 8
${hashmark}define clr_height 8
static char clr_bits[] = {
   0x81, 0x42, 0x3c, 0x24, 0x24, 0x3c, 0x42, 0x81};
"

proc tool_bar_set_layer {layer} -desc {
    Set the Tool bar layer indicator to that specified.
} -doc {
    The currently active layer is in TOOL_BAR(layer).
    This command sets TOOL_BAR(layer) to the specified layer
    and updates the Active Layer widget in the tool_bar.
    The specified layer can be any layer name or "auto".
    Commands that require an active layer (wire, polygon, etc)
    should map the palette buttons to this command while they are active.
} {
    global TOOL_BAR PAL

    # The layout command makes a little window into a max cell
    # called __PALETTE__.  This max cell is created by the
    # the palette code, which paints a bunch of little rectangles in a
    # single row.  The location of these little rectangles was
    # saved in PAL(<layername>,loc), but the layername used
    # was the canonical layer name, so we have to fish for it
    # with use_first.

    if { $layer == "auto" } {
	set TOOL_BAR(layer) "auto"
	pack forget $TOOL_BAR(layer_window_name)
	return
    }
    pack $TOOL_BAR(layer_window_name) -side right

    set long_name [dbt_long_name $layer]
    set pos [use_first PAL($layer,loc) PAL($long_name,loc)]
    if { $pos == "" } {
	msg "unknown layer: $layer\n"
	return
    }
    # Move the active layer window in the tool_bar so it is over
    # the currently selected layer in the special __PALETTE__ cell.
    # This window looks into the special __PALETTE__ cell.
    setl {x y} $pos
    $TOOL_BAR(layer_window_name).sample frame $x $y \
	    [expr $x + $PAL(radius)/2] [expr $y + $PAL(radius)/2]

    # For the text in the palette active_layer indicator we want
    # the short layer name.
    # Use a use_first so that if something changes in palette code
    # we will just use the long name, which will just make the
    # tool_bar fat, instead of crashing.
    set TOOL_BAR(layer) [use_first PAL(name,$layer) layer]
}

proc _tool_bar_reset -desc {
    Reset tool bar to the default tool.
} {} {
    global TOOL_BAR
    set TOOL_BAR(mode) [lindex $TOOL_BAR(items) 0]
}


# Create a small check button with the indicator on the right.
proc _tool_bar_checkbutton_r {win text var onval} {
    global SMALL_FONT
    # The smaller font is used to make the checkmarks in checkboxes smaller.
    set smaller_font {-*-*-*-*-*--*-80-*}
    set w $win.$text
    frame $w
    button $w.w1 -text "   $text" \
	    -font $SMALL_FONT \
	    -anchor w -pady 0 -padx 1 -borderwidth 0  \
	    -relief raised -highlightthickness 0 \
	    -command "$w.w2 invoke"
    if {0} {
	checkbutton $w.w2 -variable $var -onvalue $onval -text " " \
		-font $smaller_font \
		-anchor e -pady 0 -padx 1 -borderwidth 0  \
		-relief raised -highlightthickness 1 \
		-indicatoron 0 \
		-highlightcolor red
    } else {
	checkbutton $w.w2 -variable $var -onvalue $onval -text "" \
		-font $smaller_font \
		-anchor e -pady 0 -padx 1 -borderwidth 2  \
		-relief raised -highlightthickness 1  \
		-indicatoron 1
    }
	bind $w.w1 <Enter> "+ $w.w2 config -state active"
	bind $w.w1 <Leave> "+ $w.w2 config -state normal"
	bind $w.w2 <Enter> "+ $w.w1 config -state active"
	bind $w.w2 <Leave> "+ $w.w1 config -state normal"

    # This didnt work:
    #bind $w <Enter>  "+ $w.w1 config -state active; $w.w2 config -state active"
    #bind $w <Leave>  "+ $w.w1 config -state normal; $w.w2 config -state normal"
    # There is a little piece of frame showing between the two,
    # which also must be mapped.
    bind $w <Any-Button-1> "$w.w2 invoke"
    pack $w.w1 -side left
    pack $w.w2 -side right -fill x -expand 1
    return $w
}

proc _tool_bar_select_mode {mode {toggle ""}} -desc {
    Updates widgets in tool_bar; called when select mode changes.
} {
    global TOOL_BAR

    mode_end
    set TOOL_BAR(mode) "Select"

    if { $toggle == "toggle" } {
	if { $TOOL_BAR(select_mode) == $mode } {
	    set TOOL_BAR(select_mode) ""
	} else {
	    set TOOL_BAR(select_mode) $mode
	}
    } else {
	set TOOL_BAR(select_mode) $mode
    }
    switch -- $TOOL_BAR(select_mode) {
    "add" {
	$TOOL_BAR(win).select_mode.add.ind config -background red
	$TOOL_BAR(win).select_mode.sub.ind config -background bisque
      }
    "sub" {
	$TOOL_BAR(win).select_mode.add.ind config -background bisque
	$TOOL_BAR(win).select_mode.sub.ind config -background red
      }
    "" {
	$TOOL_BAR(win).select_mode.add.ind config -background bisque
	$TOOL_BAR(win).select_mode.sub.ind config -background bisque
      }
    default {
	error "invalid tool_bar_select_mode: $mode"
      }
    }
}

proc _tool_bar_small_radio {win text onval} -desc {
    Fabricate a widget like a radiobutton but with a smaller select button.
} {
    global BITMAPS
    set w $win
    frame $w      ;# Container frame
    # frame to be used as the indicator button.
    frame $w.ind -bd 2 -relief sunken -width 7 -height 7
	    #-text "$text" 
    button $w.text \
	    -image [image create bitmap -data $BITMAPS($text)] \
	    -anchor w -pady 0 -padx 1 -borderwidth 0  \
	    -highlightthickness 0
    pack $w.ind -side left -pady 4 -padx 2 -ipadx 0 -ipady 0
    pack $w.text -side left -ipady 0 -pady 0
    bind $w <Any-ButtonPress> " _tool_bar_select_mode $onval toggle"
    bind $w.ind <Any-ButtonPress> " _tool_bar_select_mode $onval toggle"
    bind $w.text <Any-ButtonPress> " _tool_bar_select_mode $onval toggle"
}

proc bind_with_kids {w event cmd} -desc {
    bind window and all its descendents
} {
    bind $w $event $cmd
    # winfo children only goes one level deep.
    foreach ww [winfo children $w] {
	bind_with_kids $ww $event $cmd
    }
}


# Create the tool bar for use in the specified screen side (top or left)
# but does not pack it.
proc tool_bar_build {win side} -desc {
  returns new menu_bar with win as parent, but does not pack it.
} {
    global TOOL_BAR SMALL_FONT BITMAPS
    set font $SMALL_FONT
    set tbar ${win}.tool_bar
    catch "destroy $tbar"
    set TOOL_BAR(win) $tbar

    ### create toolbar widget.  side specifies where it will go.
    if { $side == "top" } {
	frame $tbar -relief raised -borderwidth 2 -background 
    } else {
	frame $tbar -background blue -relief groove -borderwidth 3 
    }


    global MAX_MARK_MENU
    if {[use_first MAX_MARK_MENU] == 1} {

    # Add the Tool buttons.
    foreach but $TOOL_BAR(items) {
	set buttonname [string tolower $tbar.$but]

	if { $side == "top" } {
	    button $buttonname  -text $but -command _tool_bar_$but \
		    -padx 2 -pady 0 -borderwidth 0
	    pack $buttonname -side left
	} else {
	    radiobutton $buttonname  -text $but -font $font \
		    -anchor w -pady 0 -padx 1 -borderwidth 2 \
		    -relief raised -highlightthickness 0 \
		    -indicatoron 0 \
		    -selectcolor white \
		    -activebackground grey \
		    -variable TOOL_BAR(mode) -value $but
	    #-command _tool_bar_$but
	    i_cmd_bind $buttonname <Button-1> "_tool_bar_$but 0"
	    i_cmd_bind $buttonname <Shift-Button-1> "_tool_bar_$but 1"
	    pack $buttonname -side top -fill x -ipady 0 -pady 0
	}
	if {$but == "Select" } {
	    # Add select modes.

	    set TOOL_BAR(select_mode) ""
	    set w $tbar.select_mode
	    frame $w
	    set ww [_tool_bar_small_radio $w.add "+" add]
	    pack $w.add -side left -ipady 0 -pady 0
	    set ww [_tool_bar_small_radio $w.sub "-" sub]
	    pack $w.sub -side left -ipady 0 -pady 0
	    pack $w -anchor e -side top -fill x -ipady 0 -pady 0
	    if {0} {
		# This does not work well because the radiobuttons size
		# according to the font.  It would probably work great
		# if we had bit-maps to use as the button images.
		set w $tbar.select_mode2
		frame $w
		radiobutton $w.add2 -text "+" -indicatoron 0 \
				-font $SMALL_FONT -bd 2 \
				-selectcolor white \
				-variable TOOL_BAR(select_mode) -value "+" \
				-command "set TOOL_BAR(mode) Select"
		pack $w.add2 -side left -ipady 0 -pady 0
		radiobutton $w.sub2 -text "-" -indicatoron 0 \
				-font $SMALL_FONT -bd 2 \
				-selectcolor white \
				-variable TOOL_BAR(select_mode) -value "-" \
				-command "set TOOL_BAR(mode) Select"
		pack $w.sub2 -side left -ipady 0 -pady 0
		pack $w -anchor e -side top -fill x -ipady 0 -pady 0
	    }

	    	#set ww [_tool_bar_checkbutton_r $w $selbut \
	    	#    TOOL_BAR(select_mode) $selbut]
	    	#pack $ww -anchor e -side top -fill x -ipady 0 -pady 0

	    # Add an "inside" check button
	    #set TOOL_BAR(select_enclosed) 0
	    #set ww [_tool_bar_checkbutton_r $w inside \
	    #	TOOL_BAR(select_enclosed) 1]
	    #pack $ww -side top

	    #checkbutton $w.enclosed -text "inside" -font $font \
	    #		-anchor w -pady 0 -padx 1 -borderwidth 0 \
	    #		-relief raised -highlightthickness 0 \
	    #		-indicatoron 1 \
	    #		-variable TOOL_BAR(select_enclosed)
	    # pack $w.enclosed -side top

	}
    }


    # Add in the ruler, which is special because it has a clear button.
	frame $tbar.ruler
	set but Ruler
	set buttonname $tbar.ruler.ruler

	    radiobutton $buttonname  -text $but -font $font \
		    -anchor w -pady 0 -padx 1 -borderwidth 2 \
		    -relief raised -highlightthickness 0 \
		    -indicatoron 0 \
		    -selectcolor white \
		    -activebackground grey \
		    -variable TOOL_BAR(mode) -value $but
	    #-command _tool_bar_$but
	    bind $buttonname <Button-1> "_tool_bar_$but 0"
	    bind $buttonname <Shift-Button-1> "_tool_bar_$but 1"

	pack $buttonname -side left -expand 1 -fill x -ipady 0 -pady 0
	#-text C -font $font 
	button $tbar.ruler.clr \
	    -image [image create bitmap -data $BITMAPS(clear)] \
	    -pady 0 -padx 0 -borderwidth 2 \
	    -relief raised -highlightthickness 0 \
	    -command "ruler_clear"
	pack $tbar.ruler.clr -side left -ipady 0 -pady 0
	pack $tbar.ruler -side top -fill x -ipady 0 -pady 0

    }


    # Create a frame for the active layer.
    set f $tbar.active_layer
    frame $f -relief raised -borderwidth 2

    bind $f <Enter> {mode_msg "Active Layer indicator: BUT-1 selects layer for wiring or polygons." tmp}

    # Load the __PALETTE__ edit cell created by pal.tcl.
    if { [lay_editcell] != "__PALETTE__" } {
	# For debugging, pack it anyway so we can see it.
	:load __PALETTE__
    }


    # Add the layer indicator.
    label $f.label -text "Active:" -font $font -padx 1 -pady 0 -bd 0
    pack $f.label -side top -padx 0 -ipady 0 -pady 0 -anchor w
    # The layer name and sample go side by side in their own frame.
    # This needs a pady sufficient to make it the same height as the
    # flayer.f window, or the tool_bar will resize when the
    # flayer.f window is unpacked when the layer is set to "auto".
    frame $f.flayer -bd 0
    label $f.flayer.text -font $font -padx 1 -pady 1 -bd 0 \
	-textvariable TOOL_BAR(layer)
    pack $f.flayer.text -side left -fill x -anchor w -padx 0 -pady 0
    # The layer sample goes in its own little frame so it can
    # get a nice border.
    frame $f.flayer.f -bd 2 -relief sunken -height 10 -width 10
    layout $f.flayer.f.sample -special -height 9 -width 9
    pack $f.flayer.f.sample
    pack $f.flayer.f -side right
    pack $f.flayer -side top -padx 2 -fill x -expand 1
    pack $f -side top -fill x -ipady 0 -pady 0

    #bind_with_kids $f <Button-1> "_tool_bar_layer_popup $f"
    bind_with_kids $f <Button-1> "color_layer_popup $f tool_bar_set_layer auto"
    set TOOL_BAR(layer_window_name) $f.flayer.f

    # And call the function to set the default layer.
    tool_bar_set_layer $TOOL_BAR(layer)

    if {0} {
	# The wire size indicator does not fit within the palette width,
	# and the Angle indicator is not really needed.

	# Add a wire size indicator
	set w $f.width
	button $w -text "Width: auto" -font $font \
		-anchor w -pady 0 -padx 1 \
		-relief flat -bd 0 \
		-command ???
	pack $w -side top -fill x -ipady 0 -pady 0
	set TOOL_BAR(width_window_name) $w

	# Add a wire size indicator
	set w $f.angle
	button $w -text "Angle: 90" -font $font \
		-anchor w -pady 0 -padx 1 -borderwidth 2 \
		-relief flat -bd 0 \
		-command "_tool_bar_set_angle"
	set TOOL_BAR(angle_window_name) $w
	_tool_bar_set_angle 90
	pack $w -side top -fill x -ipady 0 -pady 0
    }

    pack $f -side top -fill x

    return $tbar
}


proc _tool_bar_layer_popup {caller} -desc {
    popup the layer selector menu for the tool_bar.
} -doc {
    caller is the window that called us, for positioning purposes.
} {
    global max_win SMALL_FONT TOOL_BAR
    set layers [pal_layers]

    # Remove unwanted layers.
    #foreach tmp "cells labels magnet fence rotate" {
    #	set pos [lsearch $layers $tmp]
    #	if {$pos != -1} {
    #	  set layers [lreplace $layers $pos $pos]
    #	}
    #}

    set w $max_win.layer_popup
    catch {destroy $w}
    menu $w -tearoff false
    set cnt 0
    foreach layer "auto $layers" {
	if { $cnt == 1+floor([llength $layers]/2) } {
	    set break 1
	} else {
	    set break 0
	}
	incr cnt
	$w add command -label $layer -font $SMALL_FONT \
		-columnbreak $break \
		-command "tool_bar_set_layer $layer"
    }

    # This variable will change when the popup is unposted or destroyed.
    set TOOL_BAR(layer_popup_notify_tmp) 0
    bind $w <Unmap> {set TOOL_BAR(layer_popup_notify_tmp) 1}
    bind $w <Destroy> {set TOOL_BAR(layer_popup_notify_tmp) 1}
    set menux [expr [winfo rootx $caller] + [winfo width $caller]]
    set menuy [winfo rooty $caller]
    tk_popup $w $menux $menuy
    # Wait for popup to go away.
    # Usually tkwait is wrapped by calls to cursor_wait, but in this case
    # the popup is only up as long as the user holds down Button-3,
    # so dont bother changing the cursor.
    tkwait variable TOOL_BAR(layer_popup_notify_tmp)
}


proc _tool_bar_set_width {width} -desc {
    Set the width field in the tool bar
} {
    global TOOL_BAR
    $TOOL_BAR(width_window_name) config -text "Width: $width"
}

proc _tool_bar_set_angle {{angle ""}} -desc {
    Set the angle field in the tool bar to the specified angle,
    or toggle it if no angle specified.
} {
    global TOOL_BAR
    if { $angle == "" } {
	switch "$TOOL_BAR(angle)" {
	"90" { set TOOL_BAR(angle) 45 }
	"45" { set TOOL_BAR(angle) 0 }
	default { set TOOL_BAR(angle) 90 }
	}
    } else {
	set TOOL_BAR(angle) $angle
    }
    if { $TOOL_BAR(angle) == 0 } {
	set new "Angle: all"
    } else {
	set new "Angle: $TOOL_BAR(angle)"
    }
    $TOOL_BAR(angle_window_name) config -text $new
}


# TEMPORARY: for debugging: call interactively after changes to the toolbar.
proc tool_bar {} {
    global max_win
    source "tool_bar.tcl"
    set cell [lay_editcell]
    tool_bar_build $max_win left
    win_pack
}



# Create temporary commands for all Toolbar items
#foreach but $TOOL_BAR(items) {
#    proc _tool_bar_$but "shift {name $but}" {
#	puts "tool_bar $name unimplemented"
#    }
#}

proc _tool_bar_Flyline {{shift 0}} {
    mode_end
    mode_push flyline $shift
}

proc _tool_bar_Wire {{shift 0}} {
    mode_end
    sel_clear
    mode_push wire $shift
}

proc _tool_bar_Rewire {{shift 0}} {
    mode_end
    sel_clear
    mode_push rewire $shift
}


proc _tool_bar_Select {{shift 0}} {
    # Unset the more and less buttons
    global TOOL_BAR
    _tool_bar_select_mode ""
    sel_clear
    # This just goes back to main mode.
    mode_end
}

proc _tool_bar_Polygon {{shift 0}} {
    global POLY
    mode_end
    set POLY(wire) 0  ;# bogus
    mode_push polygon $shift
}

proc _tool_bar_Circle {{shift 0}} {
    mode_end
    mode_push circle $shift
}

proc _tool_bar_Label {{shift 0}} {
    mode_end
    label_add
}

proc _tool_bar_Ruler {{shift 0}} {
    mode_end
    mode_push ruler $shift
}

proc _tool_bar_Rect {{shift 0}} {
    global TOOL_BAR
    set TOOL_BAR(persistent) $shift
    mode_end
    mode_push rect $shift
}

proc _tool_bar_Chipper {{unused}} {
  global TOOL_BAR
  set TOOL_BAR(persistent) 1
  mode_end
  mode_push fplan $TOOL_BAR(persistent)
}

#    Select?
#	Status: create/add/sub, touching/enclosed, wire/segment?
#	Note: cell selection now goes in palette.
#	B1, B1-drag: select
#	Shift-B1, Shift-B1-drag:  add
#	Ctrl-B1, Ctrl-B1-drag: sub, or probe?
#
#    Edit
#	B1: select
#	B1-drag: defines rectangle (does not select).
#	B3: paints specified rectangle
#	Del, B3 in space: deletes (hard on polygons)
#
#    Rect
#	B1..B1 or B1-drag: defines rectangle
#
#    Polygon
#	Status: 90/45/angle
#	B1..B1: defines polygon
#
#    Circle
#	Status: none
#	B1: define circle.
#
#    Wire
#	Status: size;  angle
#	B1: add
#	B2: end wire segment
#	B3: popup
#
#    Ruler (Measure)
#	Clear ruler
#
#    Label
