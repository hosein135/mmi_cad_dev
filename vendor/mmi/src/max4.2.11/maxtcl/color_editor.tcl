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

set RCSVERSION(color_editor.tcl) { $Revision: 1.8 $ }

# Build a top level window for editing layer appearance (colors and stipples)
#
# palette/colors code broken up as follows:
#   pal.tcl             - procs to build and manipulate palette widget.
#   pal_file.tcl        - procs to read .palette file. 
#   colors.tcl          - procs to setup layout widget colors/styles 
#   color_editor.tcl    - builds widget for editing layer colors/styles


# TODO: make it so you can set SAMPLE_COLORS and SAMPLE_STIPPLES in .maxrc

# Some sample colors to choose from
lappend SAMPLE_COLORS "red 255 0 0"
lappend SAMPLE_COLORS "green 0 255 0"
lappend SAMPLE_COLORS "blue 0 0 255"
lappend SAMPLE_COLORS "white 255 255 255"
lappend SAMPLE_COLORS "black 0 0 0"
lappend SAMPLE_COLORS "bisque 255 228 196"
lappend SAMPLE_COLORS "cornsilk 255 248 220"
lappend SAMPLE_COLORS "lavender 230 230 250"
lappend SAMPLE_COLORS "gray 190 190 190"
lappend SAMPLE_COLORS "navy 0 0 128"
lappend SAMPLE_COLORS "DarkSlateBlue 72 61 139"
lappend SAMPLE_COLORS "MediumBlue 0 0 205"
lappend SAMPLE_COLORS "RoyalBlue 65 105 225"
lappend SAMPLE_COLORS "SkyBlue 135 206 235"
lappend SAMPLE_COLORS "SteelBlue 70 130 180"
lappend SAMPLE_COLORS "PowderBlue 176 224 230"
lappend SAMPLE_COLORS "turquoise 64 224 208"
lappend SAMPLE_COLORS "cyan 0 255 255"
lappend SAMPLE_COLORS "aquamarine 127 255 212"
lappend SAMPLE_COLORS "DarkGreen 0 100 0"
lappend SAMPLE_COLORS "SeaGreen 46 139 87"
lappend SAMPLE_COLORS "PaleGreen 152 251 152"
lappend SAMPLE_COLORS "chartreuse 127 255 0"
lappend SAMPLE_COLORS "GreenYellow 173 255 47"
lappend SAMPLE_COLORS "LimeGreen 50 205 50"
lappend SAMPLE_COLORS "ForestGreen 34 139 34"
lappend SAMPLE_COLORS "OliveDrab 107 142 35"
lappend SAMPLE_COLORS "khaki 240 230 140"
lappend SAMPLE_COLORS "yellow 255 255 0"
lappend SAMPLE_COLORS "gold 255 215 0"
lappend SAMPLE_COLORS "RosyBrown 188 143 143"
lappend SAMPLE_COLORS "IndianRed 205 92 92"
lappend SAMPLE_COLORS "sienna 160 82 45"
lappend SAMPLE_COLORS "peru 205 133 63"
lappend SAMPLE_COLORS "burlywood 222 184 135"
lappend SAMPLE_COLORS "wheat 245 222 179"
lappend SAMPLE_COLORS "tan 210 180 140"
lappend SAMPLE_COLORS "chocolate 210 105 30"
lappend SAMPLE_COLORS "firebrick 178 34 34"
lappend SAMPLE_COLORS "brown 165 42 42"
lappend SAMPLE_COLORS "salmon 250 128 114"
lappend SAMPLE_COLORS "orange 255 165 0"
lappend SAMPLE_COLORS "coral 255 127 80"
lappend SAMPLE_COLORS "tomato 255 99 71"
lappend SAMPLE_COLORS "pink 255 192 203"
lappend SAMPLE_COLORS "maroon 176 48 96"
lappend SAMPLE_COLORS "magenta 255 0 255"
lappend SAMPLE_COLORS "violet 238 130 238"
lappend SAMPLE_COLORS "plum 221 160 221"
lappend SAMPLE_COLORS "orchid 218 112 214"
lappend SAMPLE_COLORS "purple 160 32 240"
lappend SAMPLE_COLORS "thistle 216 191 216"



# Sample stipples for the color/stipple editor.  This is a global
# variable that can be changed in the .maxrc file.
# Add as many as you want, but make in multiples of 8

lappend SAMPLE_STIPPLES "\
    00100000 \
    00010000 \
    00001000 \
    00000100 \
    00000010 \
    00000001 \
    10000000 \
    01000000 "

lappend SAMPLE_STIPPLES "\
    01000000 \
    10000000 \
    00000001 \
    00000010 \
    00000100 \
    00001000 \
    00010000 \
    00100000 "

lappend SAMPLE_STIPPLES "\
    10001000 \
    01000100 \
    00100010 \
    00010001 \
    10001000 \
    01000100 \
    00100010 \
    00010001 "

lappend SAMPLE_STIPPLES "\
    00010001 \
    00100010 \
    01000100 \
    10001000 \
    00010001 \
    00100010 \
    01000100 \
    10001000 "

lappend SAMPLE_STIPPLES "\
    10000001 \
    01000010 \
    00100100 \
    00011000 \
    00011000 \
    00100100 \
    01000010 \
    10000001 "

lappend SAMPLE_STIPPLES "\
    10011001 \
    01000010 \
    00100100 \
    10011001 \
    10011001 \
    00100100 \
    01000010 \
    10011001 "

lappend SAMPLE_STIPPLES "\
    00000000 \
    00000000 \
    00011000 \
    00100100 \
    00100100 \
    00011000 \
    00000000 \
    00000000 "

lappend SAMPLE_STIPPLES "\
    00000000 \
    01100110 \
    01100110 \
    00000000 \
    00000000 \
    01000010 \
    00111100 \
    00000000 "

lappend SAMPLE_STIPPLES "\
    00001000 \
    00000100 \
    00000010 \
    00000001 \
    10000000 \
    01000000 \
    00100000 \
    00010000 "

lappend SAMPLE_STIPPLES "\
    00010000 \
    00100000 \
    01000000 \
    10000000 \
    00000001 \
    00000010 \
    00000100 \
    00001000"

lappend SAMPLE_STIPPLES "\
    00100010 \
    00010001 \
    10001000 \
    01000100 \
    00100010 \
    00010001 \
    10001000 \
    01000100 "

lappend SAMPLE_STIPPLES "\
    01000100 \
    10001000 \
    00010001 \
    00100010 \
    01000100 \
    10001000 \
    00010001 \
    00100010 "

lappend SAMPLE_STIPPLES "\
    00011000 \
    00100100 \
    01000010 \
    10000001 \
    10000001 \
    01000010 \
    00100100 \
    00011000 "

lappend SAMPLE_STIPPLES "\
    01100110 \
    10010000 \
    00001001 \
    01100110 \
    01100110 \
    00001001 \
    10010000 \
    01100110 "

lappend SAMPLE_STIPPLES "\
    00000000 \
    00111100 \
    01000010 \
    01000010 \
    01000010 \
    01000010 \
    00111100 \
    00000000 "

lappend SAMPLE_STIPPLES "\
    00000000 \
    01100110 \
    01100110 \
    00000000 \
    00000000 \
    00111100 \
    01000010 \
    00000000 "

lappend SAMPLE_STIPPLES "\
    10101010 \
    00000000 \
    10101010 \
    00000000 \
    10101010 \
    00000000 \
    10101010 \
    00000000"

lappend SAMPLE_STIPPLES "\
    01010101 \
    00000000 \
    01010101 \
    00000000 \
    01010101 \
    00000000 \
    01010101 \
    00000000"

lappend SAMPLE_STIPPLES "\
    00000000 \
    10101010 \
    00000000 \
    10101010 \
    00000000 \
    10101010 \
    00000000 \
    10101010"

lappend SAMPLE_STIPPLES "\
    00000000 \
    01010101 \
    00000000 \
    01010101 \
    00000000 \
    01010101 \
    00000000 \
    01010101"

lappend SAMPLE_STIPPLES "\
    10001000 \
    00000000 \
    00100010 \
    00000000 \
    10001000 \
    00000000 \
    00100010 \
    00000000"

lappend SAMPLE_STIPPLES "\
    01000100 \
    00000000 \
    00010001 \
    00000000 \
    01000100 \
    00000000 \
    00010001 \
    00000000"

lappend SAMPLE_STIPPLES "\
    00000000 \
    10001000 \
    00000000 \
    00100010 \
    00000000 \
    10001000 \
    00000000 \
    00100010"

lappend SAMPLE_STIPPLES "\
    00000000 \
    01000100 \
    00000000 \
    00010001 \
    00000000 \
    01000100 \
    00000000 \
    00010001"



# NOTE: max does not like layout windows to disappear so we withdraw
# this window when we don't need it.


proc _build_color_window {w} -desc {
  build a toplevel color editing window
} {

  global PAL SAMPLE_COLORS DIALOG_FONT

  # TOPLEVEL
  toplevel $w -borderwidth 0
  wm geometry $w "+200+200"
  wm title $w "max color/stipple editor"
  wm protocol $w WM_DELETE_WINDOW "_withdraw_color_window $w"
  # end build of toplevel

  # MESSAGE AT TOP -- current layer is placed in text by edit_color
  label $w.message -anchor c -relief raised -borderwidth 2 -font $DIALOG_FONT
  bind $w.message <Button-1> "color_layer_popup $w.message edit_color \$PAL(special_layers)"
  pack $w.message -side top -pady 3

  # a nice line
  frame $w.line -bd 1 -relief solid -height 2
  pack $w.line -expand 1 -fill x -pady 1m

  frame $w.colortype
  pack $w.colortype

  # choose your colortype
  set PAL(edit,colortype) hsb
  radiobutton $w.colortype.hsb -value hsb \
	    -text hsb \
	    -variable PAL(edit,colortype) \
	    -command "_change_colortype $w hsb" \
	    -anchor w -pady 1 -padx 1

  radiobutton $w.colortype.rgb -value rgb \
	    -text rgb \
	    -variable PAL(edit,colortype) \
	    -command "_change_colortype $w rgb" \
	    -anchor w -pady 1 -padx 1
  menubutton $w.colortype.menu -text Colors -padx 2 -pady 2 \
      -menu $w.colortype.menu.menu -relief raised
  menu $w.colortype.menu.menu -tearoff 0

  set break 0
  foreach color [lsort -dictionary $SAMPLE_COLORS] {
    $w.colortype.menu.menu add command -label [lindex $color 0] \
	-command [list _change_color $w {} [lrange $color 1 end] rgb] \
	-accelerator [lrange $color 1 end] \
	-columnbreak [expr ($break/20)*20 == $break]
    incr break
  }

  pack $w.colortype.hsb $w.colortype.rgb $w.colortype.menu -side left

  frame $w.lframe -borderwidth 10 -height 130 -width 130
  layout $w.lframe.layout -special -height 120 -width 120
  pack $w.lframe.layout
  pack $w.lframe

  set xlate(red) hue
  set xlate(green) satur
  set xlate(blue) bright

  foreach color "red green blue" {
    frame $w.$color -width 100
    label $w.$color.label -text $xlate($color) -anchor e -width 5
    scale $w.$color.v -orient horizontal -showvalue 0 \
	-variable _COLOR_$color \
	-length 100 \
	-width 10 \
	-from 0 \
	-to 255 \
	-highlightthickness 0

#    label $w.$color.var -textvariable _COLOR_$color -anchor w -width 5
    label $w.$color.var -textvariable "   " -anchor w -width 5

    pack $w.$color.label $w.$color.v $w.$color.var -side left -pady 2
    pack $w.$color -side top
  }

  # a nice line
  frame $w.line2 -bd 1 -relief solid -height 2
  pack $w.line2 -expand 1 -fill x -pady 1m

  # put in the fill radial/check buttons
  frame $w.fill

  set PAL(edit,fill,rb) solid
  radiobutton $w.fill.solid -value solid \
	    -text solid \
	    -variable PAL(edit,fill,rb) \
	    -command "_edit_color_button solid" \
	    -anchor w -pady 1 -padx 1

  radiobutton $w.fill.stipple -value stipple \
	    -text stipple \
	    -variable PAL(edit,fill,rb) \
	    -command "_edit_color_button stipple" \
	    -anchor w -pady 1 -padx 1

  checkbutton $w.fill.outline \
	    -text outline \
	    -variable PAL(edit,outline,cb) \
	    -command "_edit_color_button outline" \
	    -anchor w -pady 1 -padx 1

  pack $w.fill.solid $w.fill.stipple $w.fill.outline -side left
  pack $w.fill -side top

  # build the stipple editing window
  _make_stipple_edit $w

  # a nice line
  frame $w.line3 -bd 1 -relief solid -height 2
  pack $w.line3 -expand 1 -fill x -pady 1m

  # other layers
  if {0} {
	# 3-99: Moved these into the "Edit layer" button.
	# It was confusing before.

	frame $w.other

	foreach type [lrange $PAL(special_layers) 0 2] {
	  button $w.other.$type -text $type \
	    -padx 2 -pady 2 -command "edit_color $type"
	  pack $w.other.$type -side left
	}

	pack $w.other -side top

	frame $w.other1

	foreach type [lrange $PAL(special_layers) 3 end] {
	  button $w.other1.$type -text $type \
	    -padx 2 -pady 2 -command "edit_color $type"
	  pack $w.other1.$type -side left
	}

	pack $w.other1 -side top

	# a nice line
	frame $w.line -bd 1 -relief solid -height 2
	pack $w.line -expand 1 -fill x -pady 1m

  }

  # buttons of bottom of frame
  frame $w.buttons

  button $w.done -text "Close" -padx 1 -pady 2
  button $w.revert -text "Revert..." -padx 1 -pady 2
  button $w.save -text "Save" -padx 1 -pady 2

  pack $w.done $w.revert $w.save -side left \
      -in $w.buttons -padx 1m -ipadx 1m -pady 1m -expand 1

  pack $w.buttons -side bottom
}


proc color_layer_popup {widget cmd {add_auto ""}} -desc {
    popup a layer selector menu
} -doc {
    widget is the window that called us, for positioning purposes.
    cmd is the command to execute: this command is passed the name
    of the chosen layer.
    add_auto is a list of extra layers to be added to the
    layer list, in addition to the layers from the palette.

} {
    global max_win SMALL_FONT _COLOR_TEMP PAL

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
    set layers [pal_layers]
    set len [llength "$add_auto $layers"]
    foreach layer "$add_auto $layers" {
	if { $cnt == 1+floor($len/2) } {
	    set break 1
	} else {
	    set break 0
	}
	incr cnt
	$w add command -label $layer -font $SMALL_FONT \
		-columnbreak $break \
		-command "$cmd $layer"
    }

    # This variable will change when the popup is unposted or destroyed.
    set _COLOR_TEMP($widget) 0
    bind $w <Unmap> "set _COLOR_TEMP($widget) 1"
    bind $w <Destroy> "set _COLOR_TEMP($widget) 1"
    set menux [expr [winfo rootx $widget] + [winfo width $widget]]
    set menuy [winfo rooty $widget]
    tk_popup $w $menux $menuy
    # Wait for popup to go away.
    # Usually tkwait is wrapped by calls to cursor_wait, but in this case
    # the popup is only up as long as the user holds down Button-3,
    # so dont bother changing the cursor.
    tkwait variable _COLOR_TEMP($widget)
}


proc _withdraw_color_window {w {cell ""}} -desc {
  withdraw color window
} {

  wm withdraw $w

  update
}


proc _change_colortype {w type} -desc {
  change between rgb and hsb
} {

  global PAL

  switch $type {
    hsb {
      set xlate(red) hue
      set xlate(green) satur
      set xlate(blue) bright

      set var(red) "   "
      set var(green) "   "
      set var(blue) "   "

    } 
    rgb {
      set xlate(red) red
      set xlate(green) green
      set xlate(blue) blue

      set var(red) _COLOR_red
      set var(green) _COLOR_green
      set var(blue) _COLOR_blue
    }
  }

  foreach color "red green blue" {
    $w.$color.label configure -text $xlate($color)
    $w.$color.var configure -textvariable $var($color)
  }

  # change setup
  edit_color $PAL(edit,layer)
}


proc edit_color {{layer ""}} -desc {
    Popup menu to edit layer color
} {

  global PAL PAL_DATA COLORMAP GR_COLOR_MAPPED

  if {[info exist PAL_DATA(compose,$layer)]} {
    set message "Skipping, can't edit composed layer \"$layer\" directly."
    puts $message
    tk_dialog .dialog Warning $message {} 0 OK
    return
  }

  if {[lsearch $PAL(special_layers) $layer] != -1} {
    # special case
    set special 1

    if { $GR_COLOR_MAPPED } {
      set color_number $PAL_DATA(color,$layer)
    } else {
      switch $layer {
	feedback { set type feedback_pale }
	selection { set type selection_outline }
	grid { set type grid_coarse }
	drc { set type [lindex [lay_layer_styles error_p] 0] }
	bbox { set type unexpanded_instance }
	default { set type $layer }
      }

      set color_number [lindex [lay_style $type] 1]
    }

    if {[lsearch "drc selection feedback" $layer] != -1} {
      # these are stipples only
      set fill stipple

      switch $layer {
	drc {
	  set stipple \
	      [lindex [lay_style [lindex [lay_layer_styles error_p] 0]] 4]
	}
	selection {
	  set stipple [lindex [lay_style selection_stippled] 4]
	}
	feedback {
	  set stipple [lindex [lay_style feedback_pale] 4]
	}
      }

    } else {
      # otherwise solid only
      set fill solid
      set stipple 0
    }

  } else {
    # normal layer
    set special 0

    if {$layer == ""} {
      set layer [lindex $PAL(layers) 0]
    }

    set layer [dbt_long_name $layer]

    setl {style style2} [lay_layer_styles $layer]
    setl {mask color_number outline fill stipple} [lay_style $style]

    set PAL(edit,outline) 0
    if {$style2 != ""} {
      # the second style is either for pseudo-solid or outline
      if {[lindex [lay_style $style2] 3] == "stipple"} {
	# this layer is really solid
	set fill solid
      } else {
	# must mean stippled, outline
	set PAL(edit,outline) 1
      }
    } elseif {[info exists PAL_DATA(pseudo,$stipple)]} {
      # very special case of pseudo-solid layers
      set fill solid
    }
  }

  set PAL(edit,fill) $fill
  set PAL(edit,stipple) $stipple
  set PAL(edit,layer) $layer

  # convert to decimal
  if { $GR_COLOR_MAPPED } {
    set color_number [expr $color_number + 0]
  }

  set PAL(edit,color) $color_number

  set cell [lay_rootcell]

  ### BUILD WIDGET

  set w .color

  if {[winfo exists .color]} {
    # already there, just deiconify it and raise it
    wm deiconify $w
    raise $w

  } else {
    _build_color_window $w
  }

  $w.red.v configure -command "_change_color $w $color_number"
  $w.green.v configure -command "_change_color $w $color_number"
  $w.blue.v configure -command "_change_color $w $color_number"

  # set up with correct value
  _change_color $w $color_number $COLORMAP($color_number)

  $w.done configure -command "_withdraw_color_window $w $cell"
  $w.revert configure \
      -command {_colors_revert ; edit_color $PAL(edit,layer)}
  $w.save configure -command "pal_write_palette"

  # stuff this layer into the little window
  if {$special} {
    set pos -10

  } else {
    set pos [lsearch $PAL(layers) $PAL(name,[dbt_long_name $layer])]
    if {$pos == -1} {
      _withdraw_color_window $w $cell
      puts "Aborting, can't find layer $layer."
      return
    }
  }

  set x [expr 3 * $PAL(radius) * $pos]
  set y 0

  set v 1.2
  $w.lframe.layout frame \
      [expr $x - $PAL(radius)*$v] [expr $y - $PAL(radius)*$v] \
      [expr $x + $PAL(radius)*$v] [expr $y + $PAL(radius)*$v]

  # configure the stipple pattern
  _fill_stipple $w

  # Tell the user what we are editing
  if {$special} {
    $w.message configure -text "Edit \"$layer\" color"
  } else {
    $w.message configure -text "Edit layer \"$layer\""
  }
}


proc _colors_revert {} -desc {
  Popup menu for what to revert, then do it.
} {
  global PAL

  set _COLORS_REVERT {Start-up Defaults}
  set prop_list [list \
    [list  {Revert To:}  _COLORS_REVERT -radio \
	 {{Start-up Defaults} {Start-up Defaults (current layer only)} {System Defaults}} -help {\
      If you choose "Start-up Defaults", colors will be reset to what they\
      were when you started this max session or after the last time you saved\
      the colors in this session.  You can choose to revert all colors to\
      these default settings or only the color that is currently in the\
      color/stipple editor.  If you choose "System Defaults",\
      all your personal color preference settings will\
      be removed by deleting any color file in ~/mmi_private/max/tech\
      for this technology, and colors will\
      be reset to the defaults specified in the system tech file.}]]

  set title "Revert Color Choices"
  if {![prop_menu2 -title $title $prop_list]} {
    # cancelled
    msg "Revert Palette Cancelled\n"
    return
  }
  if {$_COLORS_REVERT == {Start-up Defaults}} {
    pal_revert_palette
  } elseif {$_COLORS_REVERT == {Start-up Defaults (current layer only)}} {
    puts "Reverting layer \"$PAL(edit,layer)\""
    _pal_regenerate_palette $PAL(edit,layer)

  } else {
    pal_revert_default_palette
  }
}


proc _change_color {w color_number {rgb ""} {type ""}} {

  global COLORMAP PAL_DATA PAL GR_COLOR_MAPPED

  if {$color_number == ""} {
    set color_number $PAL(edit,color)
  }

  set layer $PAL(edit,layer)

  if {[llength $rgb] == 3} {
    # set color
    if {$PAL(edit,colortype) == "hsb"} {
      setl {h s v} [rgb2hsv $rgb]
    } else {
      setl {h s v} $rgb
    }
    $w.red.v set $h
    $w.green.v set $s
    $w.blue.v set $v
  }

  if {0 && $color_number == 127 && $GR_COLOR_MAPPED} {
    # DISABLED since highlites changed
    # special case for highlites
    # fill up the upper bits
    if {$PAL(edit,colortype) == "hsb"} {
      set rgb \
	  [hsv2rgb "[.color.red.v get] [.color.green.v get] [.color.blue.v get]"]
    } else {
      set rgb "[.color.red.v get] [.color.green.v get] [.color.blue.v get]"
    }
    for {set i 64} {$i < 128} {incr i} {
      set COLORMAP($i) $rgb
      eval lay_cmap $i $rgb
    }

  } else {
    # set the color
    if { $GR_COLOR_MAPPED } {
      if {$PAL(edit,colortype) == "hsb"} {
	set COLORMAP($color_number) \
	    [hsv2rgb "[.color.red.v get] [.color.green.v get] [.color.blue.v get]"]
      } else {
	set COLORMAP($color_number) \
	    "[.color.red.v get] [.color.green.v get] [.color.blue.v get]"
      }

      # change the value for this entry of the colormap
      eval lay_cmap $color_number $COLORMAP($color_number)
      set color $color_number

    } else {
      # true color
      if {$PAL(edit,colortype) == "hsb"} {
	set rgb [hsv2rgb "[.color.red.v get] [.color.green.v get] [.color.blue.v get]"]

      } else {
	set rgb "[.color.red.v get] [.color.green.v get] [.color.blue.v get]"
      }

      set color [eval gr_rgb_to_pixel $rgb]
      set COLORMAP($color) $rgb
      set PAL(edit,color) $color

      # got the color, now change the style for this layer
      if {[catch "lay_layer_styles $layer" styles]} {
	# must be a special layer
	set styles $layer

	switch $layer {
	  selection {
	    set styles "selection_outline selection_stipple selection_solid"
	  }
	  grid {
	    set styles "grid_coarse grid_fine grid_origin"
	  }
	  feedback {
	    set styles "feedback_dotted feedback_medium feedback_outline feedback_pale feedback_solid"
	  }
	  bbox {
	    set styles "unexpanded_instance unexpanded_instance_dim"
	  }
	  drc {
	    set styles ""
	    foreach style "error_p error_s error_ps" {
	      eval lappend styles [lay_layer_styles $style]
	    }
	  }
	}
      }

      foreach style $styles {
	eval lay_style $style [lreplace [lay_style $style] 1 1 $color]
	if {![catch "expr $style"]} {
	  # don't do this on "named" styles
	  eval lay_style -dim $style \
	      [lreplace [lay_style -dim $style] 1 1 $color]
	}
      }
    }

    # fix up all the transparency overlap colors
    if {!$PAL(stipple_only)} {
      _make_transparency [min $PAL_DATA(solids) 5]
    }
  }

  # blend with special if needed
  if {[lsearch "flyline label" $layer] != -1} {
    # need to create dim of this
    if { $GR_COLOR_MAPPED } {
      set background 0
    } else {
      set background [lindex [lay_style background] 1]
    }

    set hl_color [expr [lindex [lay_style ${layer}_dim] 1] + 0]
    set hl_color [_blend_color -attenuation 200 $color $background $hl_color]
    eval lay_style ${layer}_dim \
	[lreplace [lay_style ${layer}_dim] 1 1 $hl_color]
  }


  # blend composed layers if not truly transparent
  foreach list $PAL_DATA(compose) {
    if {[lindex [lindex $list 2] 0] == "stipple"} {
      # these get blended automatically
      continue
    }

    if {[lsearch $list $layer] != -1} {
      # got one, blend
      setl {mask new} [lay_style \
	    [lindex [lay_layer_styles [dbt_long_name [lindex $list 0]]] 0]]
      setl {mask top} [lay_style \
            [lindex [lay_layer_styles [dbt_long_name [lindex $list 1]]] 0]]
      setl {mask bottom} [lay_style \
            [lindex [lay_layer_styles [dbt_long_name [lindex $list 2]]] 0]]

      if { $GR_COLOR_MAPPED } {
	if {[expr $new + 0] < $PAL_DATA(min_nontransparent_color)} {
	  # automatically blended
	  continue
	}

	_blend_color [expr $top + 0] [expr $bottom + 0] [expr $new + 0]

      } else {
	# truecolor
	set color [_blend_color $top $bottom $new]

	foreach style [lay_layer_styles [dbt_long_name [lindex $list 0]]] {
	  eval lay_style $style [lreplace [lay_style $style] 1 1 $color]
	}
      }
    }
  }

  # update the stipple display
  _fill_stipple $w
}


proc _make_transparency {bits} -desc {
  build up the transparent layer overlap colors
} {

  global COLORMAP

  for {set k 2} {$k <= $bits} {incr k} {
    set color_number [expr int(pow(2,($k - 1)))]

    for {set i 1} {$i < $color_number} {incr i} {
      _blend_color $color_number $i [expr $color_number + $i]
    }
  }
}


proc _blend_color {args} -desc {
  blends the top color with the bottom color to create a new color and saves it in the colormap
} {

  global COLORMAP ATTENUATION GR_COLOR_MAPPED

  set pos_args [call_with_keyword $args {
      {attenuation -1}
  }]

  if {$attenuation == -1} {
      set attenuation [use_first ATTENUATION '100]
  }

  setl {top bottom new} $pos_args

  setl {rtop gtop btop} $COLORMAP($top)
  setl {rbot gbot bbot} $COLORMAP($bottom)

  set a2 [expr  $attenuation / 255.0 ]
  set a1 [expr  1.0 - $a2]

  set r [expr int($a1 * $rtop + $a2 * $rbot) ]
  set g [expr int($a1 * $gtop + $a2 * $gbot) ]
  set b [expr int($a1 * $btop + $a2 * $bbot) ]

  if { $GR_COLOR_MAPPED } {
    # color map mode
    set COLORMAP($new) "$r $g $b"
    eval lay_cmap $new $COLORMAP($new)
    set color $new

#puts "blending top=$top, bot=$bottom --> $new"
#puts "$a1 $a2: ($COLORMAP($top)), ($COLORMAP($bottom)) --> ($COLORMAP($new))"

  } else {
    # truecolor mode
    # hack to convert to 4 chars
    set color [format "%04s" [gr_rgb_to_pixel $r $g $b]]
  }

  return $color
}


proc _make_stipple_edit {w} -desc {
  make a window for editing 8x8 stipple patterns
} {

  # make an 8x8 array of buttons

  frame $w.sframe -borderwidth 10
  frame $w.sframe.stipple -relief sunken -border 2

  for {set i 0} {$i < 8} {incr i} {

    set frame $w.sframe.stipple.row_${i}
    frame $frame -bd 0

    for {set j 0} {$j < 8} {incr j} {

      set bit $frame.bit_${i}x$j
      button $bit -text " " -padx 0 -pady 0 -bd 0 \
	  -height 1 -width 1 -font *-courier-Bold-R-Normal-*-80-* \
	  -command "_change_stipple $w $i $j"
      pack $bit -side left -padx 0 -pady 0 -ipadx 2p -ipady 0
    }

    pack $frame -side top
  }

  pack $w.sframe.stipple -side top
  pack $w.sframe -side top

  _make_stipple_examples $w
}


proc _make_stipple_examples {w} -desc {
  make some nice stipples for the user to select
} {

  global SAMPLE_STIPPLES

  set stipples $SAMPLE_STIPPLES
  for {set l 0} {$l < [llength $stipples]} {incr l 8} {

    set frame $w.sline_$l
    frame $frame -bd 2
    pack $frame -side top

    set k 0
    foreach stipple [lrange $stipples $l [expr $l + 7]] {

      incr k
      set canvas $frame.c_$k

      # make a canvas
      canvas $canvas -height 17 -width 17 -bd 1 -relief raised
      pack $canvas -side left

      # button-1 uses this stipple
      bind $canvas <Button-1> [list _use_stipple $w $stipple]

      set i 1.5
      foreach row $stipple {
	for {set j 0} {$j < 8} {incr j} {
	  if {[string index $row $j]} {
	    # draw a black square here
	    $canvas create rect [expr $j * 2 + 2.5] $i [expr $j * 2 + 3.5] \
		[expr $i + 2.5] -fill black
	  }
	}
	set i [expr $i + 2]
      }
    }
  }
}


proc _use_stipple {w stipple} -desc {
  replace current layers stipple with this one
} {
  global PAL PAL_DATA

  if {$PAL(edit,fill) == "solid"} {
    puts "Must be type \"stipple\" to change the stipple pattern"
    return
  }

  # save this stipple pattern to the layer
  set stipple_no $PAL(edit,stipple)
  set PAL_DATA(stipple,$stipple_no) $stipple

  # actually change it on the screen
  eval lay_stipple $stipple_no $stipple

  # update the stipple display
  _fill_stipple $w
}


proc _fill_stipple {w} -desc {
  fill the stipple array with the correct stipple values
} {
  global PAL PAL_DATA COLORMAP GR_COLOR_MAPPED

  if {$PAL(edit,fill) == "solid"} {
    # use all ones
    set stipple {11111111 11111111 11111111 11111111 11111111 11111111 11111111 11111111}

    # set the solid radiobutton
    set PAL(edit,fill,rb) solid

    # unset the outline checkbutton and disable
    set PAL(edit,outline,cb) 0
    $w.fill.outline configure -state disabled

  } else {
    # use the real stipple
    set stipple $PAL_DATA(stipple,$PAL(edit,stipple))

    # set the stipple radiobutton
    set PAL(edit,fill,rb) stipple

    # set the outline checkbutton and enable
    $w.fill.outline configure -state normal
    set PAL(edit,outline,cb) $PAL(edit,outline)
  }

  if {[lsearch $PAL(special_layers) $PAL(edit,layer)] != -1} {
    # can't change these
    $w.fill.solid configure -state disabled
    $w.fill.stipple configure -state disabled
    $w.fill.outline configure -state disabled

  } else {
    $w.fill.solid configure -state normal
    $w.fill.stipple configure -state normal
  }

  if { $GR_COLOR_MAPPED } {
    set background 0
  } else {
    set background [lindex [lay_style background] 1]
  }

  set colors [eval format {{#%02x%02x%02x #%02x%02x%02x}} \
		  $COLORMAP($background) $COLORMAP($PAL(edit,color))]

  set i 0
  foreach row $stipple {
    for {set j 0} {$j < 8} {incr j} {
      $w.sframe.stipple.row_${i}.bit_${i}x$j configure \
	  -background [lindex $colors [string index $row $j]] \
	  -activebackground [lindex $colors [string index $row $j]]
    }

    incr i
  }
}


proc _change_stipple {w i j} -desc {
  toggle a bit of the 8x8 stipple
} {

  global PAL PAL_DATA

  if {$PAL(edit,fill) == "solid"} {
    puts "Must be type \"stipple\" to change the stipple pattern"
    return
  }

  # change this in the stipple
  # get the existing fill pattern

  set stipple_no $PAL(edit,stipple)
  set stipple $PAL_DATA(stipple,$stipple_no)

  set row [lindex $stipple $i]
  set value [expr 1 - [string index $row $j]]

  # flip it
  set row "[string range $row 0 [expr $j - 1]]$value[string range $row [expr $j + 1] 7]"
#puts "$i,$j --> $value   $row"
  set stipple [lreplace $stipple $i $i $row]

  # save this new fill pattern
  _use_stipple $w $stipple
}


proc _edit_color_button {type} -desc {
  user hit a button on the edit_color popup
} {

  global PAL PAL_DATA

  switch $type {
    outline {
      if {$PAL(edit,outline,cb)} {
	# add temporary outline style
	# (will be reassigned by _pal_regenerate_palette below)
	lay_style $PAL(temp_style) 0177 0100 0 outline 0
	lay_layer_styles -add $PAL(edit,layer) $PAL(temp_style)

      } else {
	# remove outline
	lay_layer_styles $PAL(edit,layer) \
	    [lindex [lay_layer_styles $PAL(edit,layer)] 0]
      }

      # regenerate the palette
      _pal_regenerate_palette
      edit_color $PAL(edit,layer)
    }

    solid {
      if {$PAL(edit,fill) == "stipple"} {
	# user wants to change to solid

	if {$PAL_DATA(solids) > 9} {
	  set PAL(edit,fill,rb) stipple
	  warning "Too many solid colors.  Must make one stippled first."
	  return
	}

	set style [lindex [lay_layer_styles $PAL(edit,layer)] 0]
	# make sure there is only one style
	lay_layer_styles $PAL(edit,layer) $style
	setl {mask color outline fill stipple} [lay_style $style]
	# change to solid
	lay_style $style $mask $color $outline solid 0

	# regenerate the palette
	_pal_regenerate_palette
	edit_color $PAL(edit,layer)
      }
    }
    stipple {
      if {$PAL(edit,fill) == "solid"} {
	# user wants to change to stipple
	set style [lindex [lay_layer_styles $PAL(edit,layer)] 0]
	# make sure there is only one style
	lay_layer_styles $PAL(edit,layer) $style
	setl {mask color outline fill stipple} [lay_style $style]
	# change to stipple
	lay_style $style $mask $color $outline stipple 2

	# regenerate the palette
	_pal_regenerate_palette
	edit_color $PAL(edit,layer)
      }
    }
  }
}


proc hsv2rgb {hsv {maxrgb 255} {maxhsv 255}} -desc {
  h,s,v in [0,maxhsb]
returns
  r,g,b in [0,maxrgb]

  this algorithm taken from Foley & Van Dam
} {

  setl {h s v} $hsv

  set h [expr 1.0*$h/$maxhsv]
  set s [expr 1.0*$s/$maxhsv]
  set v [expr 1.0*$v/$maxhsv]

  if {$v == 0.0} {
    set r 0.0
    set g 0.0
    set b 0.0

  } else {

    if {$s == 0.0} {
      set r $v
      set g $v
      set b $v

    } else {
      set h [expr $h * 6.0]
      if {$h >= 6.0} {
	set h 0.0
      }

      set i [expr int($h)]
      set f [expr $h - $i]
      set p [expr $v * (1.0-$s)]
      set q [expr $v * (1.0-$s*$f)]
      set t [expr $v * (1.0-$s*(1.0-$f))]

      switch $i {
	0 {
	  set r $v
	  set g $t
	  set b $p
	}

	1 {
	  set r $q
	  set g $v
	  set b $p
	}

	2 {
	  set r $p
	  set g $v
	  set b $t
	}

	3 {
	  set r $p
	  set g $q
	  set b $v
	}

	4 {
	  set r $t
	  set g $p
	  set b $v
	}

	5 {
	  set r $v
	  set g $p
	  set b $q
	}
      }
    }
  }

  if {$maxrgb < 2} {
    return "$r $g $b"
  } else {
    return "[expr int(round($r*$maxrgb))] [expr int(round($g*$maxrgb))] [expr int(round($b*$maxrgb))]"
  }
}


proc rgb2hsv {rgb {maxrgb 255} {maxhsv 255}} -desc {
  r,g,b in [0,maxrgb]
returns
  h,s,v in [0,maxhsv]

  this algorithm taken from Foley & Van Dam
} {

  setl {r g b} $rgb

  set r [expr 1.0*$r/$maxrgb]
  set g [expr 1.0*$g/$maxrgb]
  set b [expr 1.0*$b/$maxrgb]

  set max [max $r $g $b]
  set min [min $r $g $b]

  set v $max

  if {$max != 0.0} {
    set s [expr ($max - $min) / $max]
  } else {
    set s 0.0
  }

  if {$s == 0.0} {
    set h 0.0      ;# doesn't matter
  } else {
    set rc [expr ($max - $r) / ($max - $min)]
    set gc [expr ($max - $g) / ($max - $min)]
    set bc [expr ($max - $b) / ($max - $min)]

    if {$r == $max} {
      set h [expr $bc - $gc]
    } elseif {$g == $max} {
      set h [expr 2 + $rc - $bc]
    } elseif {$b == $max} {
      set h [expr 4 + $gc - $rc]
    }

    set h [expr $h / 6.0]
    if {$h < 0} {
      set h [expr $h + 1.0]
    }
  }

  if {$maxhsv < 2} {
    return "$h $s $v"
  } else {
    return "[expr int(round($h*$maxhsv))] [expr int(round($s*$maxhsv))] [expr int(round($v*$maxhsv))]"
  }
}

