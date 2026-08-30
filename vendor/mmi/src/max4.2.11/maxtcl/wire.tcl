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

set RCSVERSION(wire.tcl) { $Revision: 1.51 $ }
# Implements wire mode (a sticky wire drawing interface to max).

# Wire mode before tool_bar.

# ==== These are the structures used herein ====

# The wire_list structure.
# The current wire being drawn is saved in the list: wire_save(list).
# The wire_save(list) is a list of these structures.  Each structure
# describes one wire segment, and an optional via on the end of the segment.
# Contents:
#    x1 y1 x2 y2: The coords are the endpoints of the wire center-line,
#		  ie, not including the width.
#    layer:       layer of this wire segment (and one side of via, if any)
#    width:       width of this wire segment.
#    via:         0 if no via, otherwise the via type (eg: v1) of the via.
#    viatype:     "cell", "gcell" or "paint".
#    viaori       0 if unrotated, 90 otherwise.
#    viasym:      1 for symmetric via.
#    ori:         0, "horiz" or "vert".  Constrains the segment
#                 to the specified orientation.  The orientation is saved
#		  only when a segment is completed, ie, the current
#		  segment always has ori == 0.  Why?  For the current segment,
#                 if it is not obviously horizontal or vertical, we find
#                 the orientation by reversing the orientation of the
#                 previous segment.  That way we do not have to keep the ori
#                 in the current segment up to date when we bounce in
#                 and out of manhattan/angle modes.  Ori could be computed
#		  instead of saved in the structure.
set MAX_STRUCT(wire_list) "x1 y1 x2 y2 layer width ori via viatype viaori viasym"



proc wire_mode_enter {} -desc {
enter wiring mode (for drawing wires)
} {
  mode_push wire
}

# Define bindings common to mode: wire and mode: wire_draw
proc _wire_common_define {mode} {
    mode_bind -cmd 0 -desc "set spacing box to guide wiring" \
       $mode b "set WIRE(wire_box_display) 1"
    mode_bind -cmd 0 -desc "toggle snap to wire grid"  \
    	$mode s "_wire_set_snap_to_grid toggle"
    mode_bind -cmd 0 -desc "Set current wire size"  \
    	$mode S "_wire_width_popup"
    mode_bind -cmd 0 -desc "toggle 45/90 degree angle wiring mode" \
    	$mode f "_wire_set_snap_to_angle toggle"
    mode_bind -cmd 0 -desc "view wire mode menu" \
	$mode W "wire_menu"
    mode_bind -cmd 0 -desc "popup menu" \
	$mode <Any-Button-3> "_wire_popup $mode"
}

proc _wire_mode_define {} -desc {
  wire drawing mode (leaves box undisturbed)
} {
    mode_def wire _wire_gate_keeper {}

    mode_bind -cmd 0 \
	-desc "start min-width wire on current layer (in message area)" \
	wire <Button-1> "_wire_start"
    mode_bind -cmd 0 \
	-desc "start same width wire on current layer (in message area)" \
	wire <Shift-Button-1> "_wire_start 1"
    mode_bind -cmd 0 -desc "end wire mode" \
    	        wire <Button-2> "mode_pop"
    mode_bind -cmd 0 -desc "End wire mode" \
	wire <Escape> "mode_pop"
    mode_bind -cmd 0 -desc "undo last wire" \
	wire u "_wire_undo"

    _wire_common_define wire
}

# Init the wire_save array.
proc _wire_save_init {} {
    global wire_save

    set wire_save(drag_via) 0
    set wire_save(anchor) 0
    set wire_save(list) ""
    set wire_save(other_label_num) 0

    # If this is non-zero, dragging is disabled.
    # There can be wierd interactions with _wire_drag,
    # which is hooked to the Motion event, and popup menus
    # or prop menus.  So its better to disable wire_drag entirely,
    # while a menu is posted.
    set wire_save(disable_drag) 0

    # Start width is set if user uses Control-Button1 to route wire
    # same width as existing wire.  If this is non-zero, for each
    # segment the width will be max(start_width,min_width)
    set wire_save(start_width) 0
    # Max_via_width/max_wire_width are the largest via/wire ever drawn,
    # used solely for selecting painted via/wire to make sure we get it all.
    set wire_save(max_via_width) 0
    set wire_save(max_wire_width) 0

    set wire_save(flylabel) ""
    set wire_save(other_labels) ""
    set wire_save(other_label_num) 0
}

proc _wire_disable {} {
    global wire_save
    incr wire_save(disable_drag) 1   ;# Disable <Motion> event.
    pan_disable                      ;# Disable auto pan.

}

proc _wire_enable {} {
    global wire_save
    incr wire_save(disable_drag) -1  ;# Re-enable <Motion> event and pan
    pan_enable                       ;# Re-enable auto pan.
}

proc _wire_gate_keeper {event} -desc {
  called whenever wire mode is entered/exited
} -doc {
    wire_saves box on entry, restores on exit.
} {
  global wire_save WIRE mode_abort PAL

    if {$event == "PUSH_TO" } {
      sel_clear
      _wire_init
      # We are entering wire mode.
      catch {unset wire_save}
      # Init now to prevent unset errors if menu is invoked.
      _wire_save_init
      set wire_save(box) [layt_box exact]

      set wire_save(wire_count) 0  ;# How many wires have we drawn?

      # Choose a starting layer (can be modified with button-2/3)
      # Use highest routable layer under the cursor
      # NO, TOOK IT OUT: dont set layer when "w" is first pushed.
      # wire_choose_layer -auto

      # define button2 and button3 command on palette
      # When a button3 is clicked on the palette, wire_choose_layer
      # is called with an argument that is the palette layer selected.
      # The "wire" argument here is the mode we are in.
      #set PAL(button2) "tool_bar_set_layer wire"
      set PAL(button3) "tool_bar_set_layer wire"

      # The box status window will get the wire width.
      status_enable box 0 _wire_width_popup
      # Tell the user what will happen if they push a Mouse button,
      # and update the status windows.
      _wire_mode_msg

    } elseif {$event == "POP_TO" } {
      # We are coming from wire_draw mode back to wire mode.
      #set PAL(button2) "tool_bar_set_layer wire"
      set PAL(button3) "tool_bar_set_layer wire"
      status_enable box 0 _wire_width_popup
      _wire_mode_msg
	
    } elseif {$event == "POP_FROM"} {
	# We are leaving wire mode.
	status_enable box 1

	# restore the old box location
	eval layt_box exact $wire_save(box)

	db_group 0   ;# Make sure!
	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting wire!\n"
	}
	
	#catch {unset PAL(button2)}
	catch {unset PAL(button3)}

	# Kathy complained that sometimes most recently wired segment
	# is left selected.  Make sure it isnt.
	sel_clear

	# delimit command
	i_cmd_between
    }
}

proc _wire_draw_mode_define {} -desc {
  wire_draw mode is active during actual wiring (button 1 down)
} {

    # We set the message dynamically now.
    #set msg "BUT-1 adds new segment, (SHIFT-)BUT-2 ends (unaligned), "
    #append msg "(SHIFT)-BUT3 adds via up(down), DOUBLE-BUT-1 changes layer, DELETE removes via, \"z\" zooms in, \"Z\" Zooms out."
    #append msg "BUT3 popup menu"
    #mode_def wire_draw _wire_draw_gate_keeper $msg

    mode_def wire_draw _wire_draw_gate_keeper {}

    mode_bind -cmd 0 -desc "add wire segment" \
	wire_draw <Button-1> "_wire_add_segment"
    # This binding necessary if shift key depressed for 45s.
    # Removed 7/22: It lets people leave little 45 turds around.
    # mode_bind -cmd 0 wire_draw <Shift-Button-1> "_wire_add_segment shift"
    mode_bind -cmd 0 -desc "add wire segment" \
	wire_draw <Control-Button-1> "_wire_add_segment unaligned"
    mode_bind -cmd 0 -desc "end wire, aligned with underlying wire" \
	wire_draw <Button-2> "_wire_end_align"
    mode_bind -cmd 0 -desc "end wire, unaligned" \
	wire_draw <Control-Button-2> "_wire_end"
    mode_bind -cmd 0 -desc "end wire mode" \
	wire_draw <Escape> "_wire_end"
    mode_bind -cmd 0 -desc "(end of wire segment follows cursor)" \
	wire_draw <Motion> "_wire_drag"
    # Removed 7/22: It lets people leave little 45 turds around.
    # mode_bind -cmd 0 wire_draw <Shift-Motion> "_wire_drag shift"

  mode_bind -desc "undo last via or wire segment" \
  	  -cmd 0 wire_draw <Delete> "_wire_undo"

  mode_bind -cmd 0 -desc "undo last via or wire segment" \
	wire_draw <u> "_wire_undo"

  mode_bind -cmd 0 -desc "rotate via, if any" \
	    wire_draw r "_wire_change_via rotate"
  mode_bind -cmd 0 -desc "rotate via, if any" \
	    wire_draw x "_wire_change_via symmetry"

  # 6/29: This binding changed from a because a key is now common mode zoom.
  mode_bind -cmd 0 -desc "anchor/unanchor wiring vertex" \
	    wire_draw a "_wire_set_anchor toggle"

  # This is how pat thinks it should work: drop_via auto changes layers,
  # and leaves the via anchored.  Unanchor it to slide it.
  mode_bind -cmd 0 -desc "drop via, down" wire_draw D "_wire_add_via down"
  mode_bind -cmd 0 -desc "drop via, up" wire_draw d "_wire_add_via up"
  mode_bind -cmd 0 -desc "change drag via method (toggles)" \
	    wire_draw c "_wire_drag_via"
  
  # Olde method for changing layers:  Now use popup or type d or D.
  #mode_bind -cmd 0 -desc "add via, up" wire_draw <Button-3> "_wire_add_via up"
  #mode_bind -cmd 0 -desc "add via, down" wire_draw <Shift-Button-3> "_wire_add_via down"

  _wire_common_define wire_draw
}

# Using this proc prevents multiple error messages every time
# you access the tech data base.
proc _wire_info {what} -desc {
  return the default_layer or the wire layers
} {
    global WIRE _WIRE_TMP
    switch $what {
      "default_layer" {
	set WIRE(default_layer) [use_first WIRE(default_layer)]
	if { $WIRE(default_layer) == "" } {
	    # This will silently return "" if tech file is incomplete.
	    set metal1 [lindex [techinfo layers metal opt] 0]
	    set WIRE(default_layer) $metal1
	}
	if { $WIRE(default_layer) == "" } {
	      # tech data base is incomplete, but we need to use something
	      # to init the default layer.  Just use any layer.
	      set WIRE(default_layer) [lindex [techinfo layer_order] 0]
	}
	return $WIRE(default_layer)
      }

      "wire_layers" {
	# Get what the tech file thinks are the wiring layers.
	# This generates a warning message if the tech file does not
	# contain any via information.  Squirrel it away in
	# _WIRE_TMP(wire_layers) so we only generate the message once.
	if { ! [info exists _WIRE_TMP(wire_layers)] } {
	  set _WIRE_TMP(wire_layers) [techinfo wire_layers]
	}
	return $_WIRE_TMP(wire_layers)
      }
      default {
	  max_error "wire internal error: unexpected _wire_info $what"
      }
    }
}

proc _wire_init {} {
    global WIRE _WIRE_TMP
    global WIRE_BOX DEFAULT_WIRE_BOX  ;# for backward compatibility

    # Do not put inited in the WIRE array, because the user
    # can save/restore the WIRE array.
    if {[info exists _WIRE_TMP(inited)]} { return }
    set _WIRE_TMP(inited) 1
    
    # ============== Init WIRE data-base ===================
    # If any element is not initialized, supply a default value.
    # These values are persistent once set.
    # This must be done after the tech file is read in, so we can
    # not do it from _wire_mode_define.

    set WIRE(draw_mode) [use_first WIRE(draw_mode) 'paint]
    set WIRE(snap_to_grid) [use_first WIRE(snap_to_grid) '0]
    set WIRE(snap_to_angle) [use_first WIRE(snap_to_angle) '90]
    set WIRE(viatype) [use_first WIRE(viatype) 'any]
    set WIRE(composite_layers) [use_first WIRE(composite_layers)]
    set WIRE(wire_box_display) [use_first WIRE(wire_box_display) '0]
    set WIRE(move_flylines) [use_first WIRE(move_flylines) '1]
    set WIRE(check_connectivity) [use_first WIRE(check_connectivity) '0]
    set WIRE(min_angle) [use_first WIRE(min_angle) '90]
    set WIRE(via_gcell_name) [use_first WIRE(via_gcell_name) 'via]

    set WIRE(default_layer) [_wire_info default_layer]


    # The config_layers are the layers that appear in the wire set up menus.
    # If the user attempts to wire in an unknown layer, they are
    # prompted for width, etc, and the layer is added to config_layers.
    # The config_layers are saved in the users pref file.  However,
    # the tech file may have changed since the user saved the pref file.
    # Therefore we will add any wire_layers from the tech file into
    # the existing config layers.
    set old_config_layers [use_first WIRE(config_layers)]
    set WIRE(config_layers) [_wire_info wire_layers]
    foreach old $old_config_layers {
	if { [lsearch -exact $WIRE(config_layers) $old] == -1 } {
	    lappend WIRE(config_layers) $old
	}
    }

    # This will silently return "" if tech file is incomplete.
    set metal1 [lindex [techinfo layers metal opt] 0]

    # Look through the tech file at the wire widths.
    # Print a nice warning message about all the widths that
    # were not specified.
    set varsNotFound ""
    set varsWrong ""
    set varsLess ""
    # Init the wiring data base.
    set wire_layers [_wire_info wire_layers]
    foreach layer "$WIRE(config_layers)" {

	set width [techinfo width $layer "" opt]
	# Is it a simple layer, as opposed to a composite layer?
	set simple_layer [expr [lsearch -exact $wire_layers $layer] >= 0]
	if { $width == 0 && $simple_layer } {
	    # Tech file probably bad, issue warning and keep going.
	    # User can set the width in the Wiring Parameters Menu.
	    lappend varsNotFound "width $layer"
	}

	if { [info exists WIRE($layer,width)] } {
	    if { $width != 0 && $simple_layer } {
		if { [approx $WIRE($layer,width) != $width] } {
		    # Width in user pref file does not match width in tech file.
		    lappend varsWrong $layer
		}
		if { [approx $WIRE($layer,width) < $width] } {
		    # The width in the config file is less than the
		    # width in the tech file.  This is a serious problem.
		    lappend varsLess $layer
		}
	    }
	} else {
	    set WIRE($layer,width) $width
	}


	if { ![info exists WIRE($layer,sep)] } {
	    set WIRE($layer,sep) [techinfo sep $layer $layer opt]
	}
	if { $WIRE($layer,sep) == 0 || $WIRE($layer,sep) == "" } {
	    lappend varsNotFound "spacing $layer"
	    set WIRE($layer,sep) 1
	}

	set WIRE($layer,snap) \
		[use_first WIRE($layer,snap) WIRE($metal1,snap) '1]
	set WIRE($layer,offset) \
		[use_first WIRE($layer,offset) WIRE($metal1,offset) '0]
    }
    if { $varsNotFound != "" } {
	max_error -buffer "warning: could not find values in the technology file for the following: [join $varsNotFound ", "]; using defaults"
    }
    if { $varsWrong != "" } {
	max_error -buffer "warning: current wire width differs from minimum width\
	in technology file for layers: $varsWrong. \
	The current width may have come from LEF, from a .maxrc file, or from your\
	user preferences file ([max_local_pref_file_name])."
    }
    if { $varsLess != "" } {
	max_error -buffer "error: current wire width is *less than* the miniumum\
	width in technology file for the following layers: $varsLess. \
	The current width may have come from LEF, from a .maxrc file, or from your\
	user preferences file ([max_local_pref_file_name]). \
	Note: This is almost certainly an error. \
	You should consider removing your preferences file."
    }
}



proc wire_info {{-set} what {layer ""} {value ""}} -desc {
  Get/set wiring parameters
} {
  global WIRE
  switch -- $what {
    "width" {
      if {! $set} {return $WIRE($layer,width)}
    }
  }
}

proc wire_get_grid {layer} -desc {
  Return the wire grid for <layer> as {gridx gridy offsetx offsety}, or "" if layer unknown.
} {
  global WIRE
  _wire_init
  setl {snapx snapy} [use_first WIRE($layer,snap)]
  if {$snapx != ""} {
    if {$snapy == ""} { set snapy $snapx }
    setl {offsetx offsety} [use_first WIRE($layer,offset)]
    if {$offsetx == ""} {set offsetx 0}
    if {$offsety == ""} {set offsety $offsetx}
    return [list $snapx $snapy $offsetx $offsety]
  }
  return ""
}

proc _wire_draw_gate_keeper {event} -desc {
    gate keeper for wire draw mode
} {
    global mode_abort PAL

    if {$event == "PUSH_TO"} {
	#_wire_save_init		;# Get ready for new wire.

	#catch {unset PAL(button2)}
	# disable button3 in palette
	set PAL(button3) "format wire_draw"
        # While we are actually drawing the wire, the cursor status
	# window will show location of end of wire,
        # not the mouse pointer location.
        status_enable cursor 0

	pan_enable
	_wire_mode_msg
	cursor_mode wire_draw 1
    } elseif {$event == "POP_FROM"} {
        status_enable cursor 1
	pan_disable
	catch {unset PAL(button3)}
	# THIS CODE WAS HERE TO SUPPORT PERSISTENT WIRE MODE:
	# Remove visible spacing box, if any.
	lay_line -tag wire_box_lines -clear
	db_group 0  ;# Make sure!
        # i_cmd_between

	# mode msg is restored by wire_gate_keeper
    }
}

proc _wire_mode_msg {} -desc {
  post wire mode message
} {
    global wire_save TOOL_BAR OPTIONS

    if { [mode_current] == "wire" } {

	# If the layer has been chosen, then we know the actual width.
	# Otherwise, if the user specified a width, use that,
	# Otherwise just put "auto", because we dont have a clue
	# what the width is until the user actually starts wiring.
	if { $TOOL_BAR(layer) != "auto" || $wire_save(start_width) != 0 } {
	    set width [_wire_get_width $TOOL_BAR(layer)]
	} else {
	    set width "auto"
	}

	set but1 "(Ctrl-)BUT-1 wires in $TOOL_BAR(layer) (at same width)"
	# Tell user the default wire width, although they can over-ride
	# it by using Control-But-1 to start the wire.
	box_msg_update "wire width = $width"
    } else {
	set but1 "BUT-1 adds segment"
    }
    set but2 "BUT-2 ends"
    if { $OPTIONS(use_popups) } {
	set but3 "BUT-3 popup menu"
    } else {
	set but3 "BUT-3 selects layer"
    }
    mode_msg "[mode_current] mode. $but1, $but2, $but3"
}


proc wire_choose_layer {{cmd ""}} -desc {
    Choose a wiring layer
} -doc {
    TODO: cmd argument is ignored!
    Look under the cursor for a valid selectable, visible,
    wiring layer and return it.  Layers that are not used
    for wiring are ignored.
    If no such layers under cursor, return "".
} {
  global wire_save

  setl {x y} [layt_point exact]
  set layers [dbt_short_name [db_search touchingtypes $x $y]]
  set visible [dbt_short_name [dbt_selectable_layers]]

  # Look only at wiring layers.
  foreach layer [_wire_info wire_layers] {
    if {[lsearch $layers $layer] != -1 && [lsearch $visible $layer] != -1} {
      # found a routable, visible layer
      # Make sure the WIRE data-base is consistent:
      #if {![info exists WIRE($layer,width)]} {
      #	  msg "Unknown routing layer \"$layer\", no entry in WIRE array!\n"
      #	  continue
      #}
      return $layer
    }
  }

  # can't find any layers under cursor.
  return ""
}

# Dont let wire go below min for specified layer
# The layer can be "auto", in which case return the start_width,
# but dont try to figure out a width for the layer.
proc _wire_get_width {layer} {
    global wire_save WIRE
    set width 0
    # Use user specified width, or default width.
    if { $wire_save(start_width) != 0 } {
	set width $wire_save(start_width)
    } elseif { $layer != "auto" } {
	#set layer [dbt_long_name $layer]
	if { [lsearch $WIRE(composite_layers) $layer] >= 0} {
	    # Set width to max width of any of the layers in the
	    # composite wire.
	    set width 0
	    foreach lay $WIRE($layer,layers) {
		# The width can be specified by composite:layer,width,
		# or just by: layer,width.
		# Different layers have the width specified in different
		# places, so fish around for it with use_first.
		set width [max $width [techinfo width $lay]]
	    }
	} elseif {[info exists WIRE($layer,width)] &&
	    $WIRE($layer,width) != 0} {
	    set width $WIRE($layer,width)
	} else {
	    # This is not one of the routing layers, or no width
	    # has ever been specified.
	    # We will let the user wire in this layer, but they
	    # will have to tell use what width.
	    set wire_save(tmp) 0
	    set prop_list ""
	    lappend prop_list [list \
		"Layer: $layer does not have a default wire width" "" -label]
	    lappend prop_list [list \
		"Enter Wire width:" wire_save(tmp) \
    		-number 0 100000 -incr [res -mask] -width 10 -validate]
	    _wire_disable
	    set stat [prop_menu2 -atmouse 0 -title "Enter wire width" $prop_list]
	    _wire_enable
	    # If user hit cancel.
	    if { $stat == 0 } {
		mode_end
		return 0
	    }
	    if { $wire_save(tmp) == 0 } {
		max_error "wire error: invalid wire width, aborting"
		mode_end
		return 0
	    }

	    set minwidth [techinfo width $layer "" opt]
	    if { [approx $wire_save(tmp) < $minwidth] } {
	      max_error "warning: entered width ($wire_save(tmp)) less than minimum width ($minwidth) from tech file"
	      # But its ok: it will use the minwidth from the tech file on
	      # this wire.  If a future wire segment has a tech file width
	      # small than what was entered, it will be used then.
	    }

	    # We only ask the user once.  From then on, we save it.
	    set WIRE($layer,width) $wire_save(tmp)
	    lappend WIRE(config_layers) $layer
	    set width $WIRE($layer,width)
	}
    }
    # But dont go below process min width for this layer.
    if {$layer != "auto"} {
	set minwidth [techinfo width $layer "" opt]
	if { $minwidth != "" } {
	    set width [max $width $minwidth]
	}
    }
    # Save max width ever seen, used for selecting wires.
    set wire_save(max_wire_width) [max $wire_save(max_wire_width) $width]
    return $width
}


proc wire_default_layer {} -desc {
  return a default wiring layer
} {
    # Use default layer, if visible, otherwise first visible layer.
    # Look every where we can think of, but carefully.
    set visible [dbt_short_name [dbt_visible_layers]]
    foreach thing "[_wire_info default_layer] [_wire_info wire_layers]" {
	set layers [dbt_short_name $thing]
	foreach trylayer $layers {
	    if { [lsearch $visible $trylayer] != -1} {
		return $trylayer
	    }
	}
    }
    return ""
}


# Start a wire.  not_min arg may be:
#    empty:  start a minimum width wire.
#    "1":    start a wire using existing wire width
# Outputs:
#    Init wire_save(list) with a single wire segment.
proc _wire_start {{not_min "0"}} -desc {
    start drawing wire segment.
} {
    global TOOL_BAR wire_save


    set layer ""
    if { $TOOL_BAR(layer) == "auto" } {
	# Layer will be "" if no valid layer under cursor.
	set layer [wire_choose_layer -return]
	if { $layer == "" } {
	    set layer [wire_default_layer]
	}
    } else {
	set layer $TOOL_BAR(layer)
    }

    if { $layer == "" } {
	# This only happens if TOOL_BAR(layer) is auto and all routing
	# layers are currently not visible.
	max_error "wire error: No wiring layers are visible!  Dont know what layer to wire in!"
	return
    }

    # new wire
    msg "wiring...\n"

    # Get default width. May be changed below.
    set width [_wire_get_width $layer]
    if { $width == 0 } { return } ;# It failed.

    # Use exact point, then snap using wiring grid, instead of user grid.
    setl {xx yy} [layt_point exact]
    setl {x y} [_wire_snap $xx $yy $layer 0]

    # If cursor is over the drawing layer, then start the wire
    # from width/2 into the layer

    set layers [dbt_short_name [db_search touchingtypes $x $y]]
    if {[lsearch $layers $layer] != -1} {
      sel_clear_g

      # turn off other layers that may be around
      #  :see no *
      #  :see $layer
      #  layt_point exact $xx $yy
      #  # Use select, not sel_area, to get the whole piece of paint.
      #  :select

      #  # sometimes the select messes up so try again
      #  if {[sel_what paint] == ""} {
      #       layt_point exact $xx [expr $yy - [res]]
      #       :select
      #  }
      #  # return the visibility to where it was
      #  :see no *
      #  :see [join $visible ,]

      sel_chunk -any_cell $layer $xx $yy [expr $xx + [res]] [expr $yy + [res]]


      # get the bounding box of this layer so we can find its center
      setl {x1 y1 x2 y2} [lrange [sel_what paint] 1 4]
      if {$y2 == ""} {
	# something went wrong.  maybe a polygon
	set x $xx
	set y $yy

      } else {
	set dx [expr $x2 - $x1]
	set dy [expr $y2 - $y1]

	if {$not_min} {
	  # Use width of wire under cursor, and set wire_save(start_width),
	  # so all future segments will also use this width.
	  set wire_save(start_width) [min $dx $dy]
	}
	# This will usually return wire_save(start_width), set just above.
	set width [_wire_get_width $layer]
	if { $width == 0 } { return }  ;# It failed.

	# note that the 0.1*[res] fixes for rounding error
	#set dw2 [expr floor($width/2.0/[res]+0.1*[res])*[res]]
	# Make SURE we round up, so centerline will be offset
	# to right or up for wires whose centerline is not on grid,
	# to match the way wire_draw draws them.
        set lhwidth [uusnap -mask [expr $width/2.0 + [res]/10]]
        set rhwidth [expr $width - $lhwidth]

	# recompute (x,y) to lie nicely inside starting layer
	# We assume x1,y1 <= x2,y2
	if {[expr $x - $x1] <= $lhwidth} {
	  set x [expr $x1 + $lhwidth]
	} elseif {[expr $x2 - $x] <= $rhwidth} {
	  set x [expr $x2 - $rhwidth]
	}
	if {[expr $y - $y1] <= $lhwidth} {
	  set y [expr $y1 + $lhwidth]
	} elseif {[expr $y2 - $y] <= $rhwidth} {
	  set y [expr $y2 - $rhwidth]
	}
      }

      _wire_change_flylines $x $y $layer
    }

  set new.x1 [uusnap $x]
  set new.y1 [uusnap $y]

  # We start with a single zero-length segment at (x,y)
  set new.x2 ${new.x1}
  set new.y2 ${new.y1}
  set new.layer $layer
  set new.width $width
  set new.via 0
  set new.viatype 0
  set new.viaori 0
  set new.viasym 0
  set new.ori 0
  # Save the new wire segment as the only thing segment the data-base.
  set wire_save(list) [list [destruct wire_list new]]

  _wire_begin_draw

  mode_push wire_draw
}


# Is layer under specified x y coords?  Only checks visible layers.
# Test only layers that pre-existed before the wire,
# ie, ignore the wire and vias we are drawing.
proc _wire_find_layer {layer x1 y1 x2 y2} {
    global wire_save WIRE
    # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    # TODO: Fix max deficiency, and then this!
    # The sel_area command is finding paint in the gcell vias we are drawing.
    # We do not have to worry about painted vias, because they are in
    # their own group and max groups work for them.
    # There is no way NOT to select the via gcells!
    #  sel_area -group does not work on gcells - always gets them regardless.
    #  sel_cell -less on the gcell does not remove its paint from selection.
    # So we have this horrible ugly work around.
    # Delete all the vias, then put them back afterwards.
    set nsegs [llength $wire_save(list)]
    for {set i 0} {$i < $nsegs} {incr i} {
	struct wire_list w [lindex $wire_save(list) $i]
	if { ${w.viatype} == "cell" || ${w.viatype} == "gcell"} {
	    _wire_undraw_via $i
	}
    }
    # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    db_group 0
    # Find any paint that is not part of the current wire.
    sel_clear_g
    sel_area -any_cell -group -no_labels -layers $layer $x1 $y1 $x2 $y2
    # TODO: could use db_search on __SELECT__ to remove the vias
    # from the selection.
    set what_paint [sel_what paint]
    # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    # TODO: Fix max, and then this!
    # Now put the vias back.
    for {set i 0} {$i < $nsegs} {incr i} {
	struct wire_list w [lindex $wire_save(list) $i]
	if { ${w.viatype} == "cell" || ${w.viatype} == "gcell"} {
	    _wire_draw_via $i 0 0
	}
    }
    # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    if { $what_paint == "" } { return 0 }
    # Note: this uses visible, not selectable, so that we can
    # terminate the wire on any layer we run into.
    # There is no point in allowing a short.
    # Really, it should maybe be any layer, not just visible layers.
    set visible [dbt_short_name [dbt_visible_layers]]
    return [expr [lsearch $visible $layer] != -1]
}


# Get orientation of current wire segment.
proc _wire_get_ori {} {
    global wire_save
    struct wire_list w [lindex $wire_save(list) end]
    if { ${w.x1} == ${w.x2} && ${w.y1} == ${w.y2} } {
	# Current wire is zero length.
	# Switch orientation from previous wire segment, if any.
	set len [llength $wire_save(list)]
	if { $len >= 2 } {
	    struct wire_list p [lindex $wire_save(list) [expr $len - 2]]
	    switch ${p.ori} {
		"horiz" { return "vert" }
		"vert"  { return "horiz" }
	    }
	}
	# Just pick any orientation
	return "horiz"
    } elseif { ${w.x1} == ${w.x2} } {
	return "vert"
    } elseif { ${w.y1} == ${w.y2} } {
	return "horiz"
    }
    return 0
}


proc _wire_add_segment {{option ""}} -desc {
  In wiring mode: start new wire segment with same width and layer as old.
} {
    global wire_save

    # Move to the actual mouse press.  On a very slow system, the
    # wire may not have been keeping up with the mouse.
    if { $option == "shift" } {
	_wire_drag shift
    } else {
	_wire_drag
    }

    # Set struct w to the segment we were drawing interactively.
    struct wire_list w [lindex $wire_save(list) end]

    if {0} { ;# Removed 4/22/00
      # This is the code that auto-ends the wire when you push
      # mouse Button-1 over a wire.  Took it out so you MUST
      # use mouse Button-2 to end the wire.

      # If we are not right over our starting point
      # check if the layer we are wiring is under the mouse?
      # Get first segment:
      struct wire_list first [lindex $wire_save(list) 0]
      # Distance from starting point:
      set dist [max [expr abs(${w.x2} - ${first.x1})] \
		    [expr abs(${w.y2} - ${first.y1})]] 

      # compute bounding box of end of wire.
      set lhwidth [uusnap -mask [expr ${w.width}/2.0 + [res]/10]]
      set rhwidth [expr ${w.width} - $lhwidth]
      setl {bx1 by1 bx2 by2} [list \
	  [expr ${w.x2} - $lhwidth] [expr ${w.y2} - $lhwidth] \
	  [expr ${w.x2} + $rhwidth] [expr ${w.y2} + $rhwidth]]

      if { $dist > ${w.width} && \
	  [_wire_find_layer ${w.layer} $bx1 $by1 $bx2 $by2] } {
	  # We are over paint in the layer we are wiring;
	  # end the wire, it is connected up now.
	  if { $option == "unaligned" } {
	      _wire_end
	  } else {
	      _wire_end_align
	  }
	  return
      }
    }

    # Terminate interactive mode drawing.
    # This must be done AFTER _wire_find_layer, because that routine
    # blithely redraws the vias after it finishes.
    _wire_end_draw

    # Didnt like this.  Instead, should make it automatically not
    # move a via across a wire.
    if {0} {
      # If we have just dropped a via and havent moved yet,
      # then just drop anchor at the via.
      # This makes it easier to wire away from the via.
      set nsegs [llength $wire_save(list)]
      if { $wire_save(drag_via) == 0 && $nsegs >= 2 && ! $wire_save(anchor) } {
	  struct wire_list u [lindex $wire_save(list) [expr $nsegs - 2]]
	  # Are we still near the via?
	  if { ${u.via} != "0" && [nearby ${w.x1} ${w.y1} ${w.x2} ${w.y2}] } {
	      set wire_save(anchor) 1
	      # simulate a motion event to update the screen.
	      _wire_drag
	      return
	  }
      }
    }

    # Set orientation flag in completed segment to horiz or vert, if applicable.
    set w.ori [_wire_get_ori]

    # Make a new zero-length wire at location w.x2,w.y2.
    set new.x1 ${w.x2}
    set new.y1 ${w.y2}
    set new.x2 ${w.x2}
    set new.y2 ${w.y2}
    set new.layer ${w.layer}
    set new.width ${w.width}
    set new.via 0
    set new.viatype 0
    set new.viaori 0
    set new.viasym 0
    set new.ori 0

    # Is the via being dragged from segment to segment?
    if { ${w.via} != "0" && $wire_save(drag_via) } {
	# Remove via from segment w, and put it on the new segment.
	set new.via ${w.via}
	set new.viatype ${w.viatype}
	set new.viaori ${w.viaori}
	set new.viasym ${w.viasym}
	set w.via 0
	set w.viatype 0
	set w.viaori 0
	set w.viasym 0
    }
    # Replace the old segment.
    set wire_save(list) [lreplace $wire_save(list) end end \
	[destruct wire_list w]]

    # Add new zero length segment starting at old endpoint.
    lappend wire_save(list) [destruct wire_list new]

    # New segment always starts out unachored, so it can be moved.
    set wire_save(anchor) 0

    # simulate a motion event to update the screen.
    _wire_drag
}


proc _wire_end_align {} -desc {
  exit wiring mode with the new wire aligned to an overlapping wire.
} {
    global WIRE wire_save

    setl {x2 y2} [layt_point exact]
    if {$x2 == "" || $y2 == ""} {
	# off the screen
	_wire_end
	return
    }

    struct wire_list w [lindex $wire_save(list) end]

    # w.ori can be 0 if user just switched from an angle mode
    # to manhattan mode for the most recent wire segment.
    set wori [_wire_get_ori]
    if { $WIRE(snap_to_angle) != 90 || $wori == 0 } {
	_wire_end
	return
    }

  # put the box around the end point of the wire
  # make SURE we round up.
  set lhwidth [uusnap -mask [expr ${w.width}/2.0 + [res]/10]]
  set rhwidth [expr ${w.width} - $lhwidth]
  # compute bounding box of end of wire.
  setl {wx1 wy1 wx2 wy2} [list \
	[expr ${w.x2} - $lhwidth] [expr ${w.y2} - $lhwidth] \
	[expr ${w.x2} + $rhwidth] [expr ${w.y2} + $rhwidth]]

  set old_group [db_group]
  db_group 0

  # get any preexisting paint that is the same as the wire which overlaps
  # the last segment of the wire.
  sel_clear_g
  sel_area -any_cell -group -no_labels -layers ${w.layer} $wx1 $wy1 $wx2 $wy2 
  db_group $old_group

  setl {xx1 yy1 xx2 yy2} [lrange [sel_what paint] 1 4]
  if {$xx1 == ""} {
    _wire_end
    return
  }

  # now get the entire segment of the overlapping preexisting paint

  #  # turn off other layers that may be around
  #  set visible [dbt_visible_layers]
  #  sel_clear_g
  #  :see no *
  #  :see ${w.layer}
  #  layt_point exact $xx1 $yy1
  #  set old_group [db_group]
  #  db_group 0
  #  :select -g
  #  db_group $old_group
  #  # return the visibility to where it was
  #  :see no *
  #  :see [join $visible ,]

  db_group 0
  sel_chunk -any_cell -group ${w.layer} \
	$xx1 $yy1 [expr $xx1 + [res]] [expr $yy1 + [res]]

  # get the bounding box of this layer so we can find its center
  setl {xx1 yy1 xx2 yy2} [lrange [sel_what paint] 1 4]
  if {$xx1 == ""} {
    _wire_end
    return
  }
  set dx [expr $xx2 - $xx1]
  set dy [expr $yy2 - $yy1]

  set align 0

  if { $wori == "horiz" } {
    if { $wy1 < $yy1 } {
	# Must push wire up if possible
	if { $dy > ${w.width} } {
	    # Paint larger than wire: align bottom edge of wire.
	    set align "bottom"
	} elseif { $wy2 < $yy2 } {
	    # Paint smaller than wire: align top edge of wire.
	    set align "top"
	}
    } elseif { $wy2 > $yy2 } {
	# Must push wire down if possible
	if { $dy > ${w.width} } {
	    # Paint larger than wire: align top edge of wire.
	    set align "top"
	} elseif { $wy1 > $yy1 } {
	    # Paint smaller than wire: align bottom edge of wire.
	    set align "bottom"
	}
    }
  } elseif { $wori == "vert" } {
    if { $wx1 < $xx1 } {
	# Must push wire right if possible
	if { $dx > ${w.width} } {
	    # Paint larger than wire
	    set align "left"
	} elseif { $wx2 < $xx2 } {
	    set align "right"
	}
    } elseif { $wx2 > $xx2 }  {
	# Must push wire left if possible
	if { $dx > ${w.width} } {
	    # Paint larger than wire
	    set align "right"
	} elseif { $wx1 > $xx1 } {
	    set align "left"
	}
    }
  }

  # Center point of wire end.
  set wx ${w.x2}
  set wy ${w.y2}

  switch $align {
      "bottom" { set wy [expr $yy1 + $lhwidth] }
      "top" { set wy [expr $yy2 - $rhwidth] }
      "left" { set wx [expr $xx1 + $lhwidth] }
      "right" { set wx [expr $xx2 - $rhwidth] }
  }

  # We dont need to uusnap this.  We got the numbers
  # straight from an existing piece of wire.
  _wire_drag "" $wx $wy

  # This did not work when connecting to paint larger than wire:
  #if {$dx < $dy} {
  #  # In the case where the wire width is not divisible by 2*res,
  #  # the wire center line is not on grid.  In this case the
  #  # wire_draw routine always moves the wire down (or to the left),
  #  # so we must make sure we round the wire centerline up.
  #  _wire_drag [uusnap -ceil -mask [expr ($xx1 + $xx2) / 2.0]] $y2
  #} else {
  #  _wire_drag $x2 [uusnap -ceil -mask [expr ($yy1 + $yy2) / 2.0]]
  #}

  _wire_end
}


proc _wire_end {} -desc {
  exit wiring mode.
} {
    global WIRE wire_save

    set len [llength $wire_save(list)]

    # Delete all visible segments.
    for {set i 0} {$i < $len} {incr i} {
	_wire_undraw_segment $i
    }

    # And redraw them using paint, if possible.
    for {set i 0} {$i < $len} {incr i} {
	_wire_draw_segment $i 0 1
    }
    # lose any flylines for connections that are now complete
    _wire_clean_flylines
    incr wire_save(wire_count)

    # This was added for intel.
    # Currently, it only checks for labels in the current cell,
    # which is mostly useless because we do not label all our nets.
    # But it does detect if you connect two ports together, or vdd to gnd.
    if { [llength $wire_save(list)] != 0 && $WIRE(check_connectivity) } {
      struct wire_list w [lindex $wire_save(list) end]
      sel_clear_g
      sel_net -point ${w.x2} ${w.y2} ${w.layer}
      set labels [sel_what_l labels -edit_only foo]
      # To find unique labels, hash them in an array.
      foreach thing $labels {
	struct max_label lab $thing
	if { ${lab.kind} != "hidden" && ${lab.kind} != "comment" } {
	  set hash(${lab.text}) 0
	}
      }

      set uniq_labels [array names hash]
      if {[llength $uniq_labels] >= 2} {
	max_error "warning: Wire connects the following labels: $uniq_labels"
      }
    }

    # pop out of wire_draw then wire mode.
    mode_pop

    # we're done!
    mode_pop

    msg "wire done.\n"
}

proc _wire_change_via {subcmd} {
  global wire_save
  set llen [llength $wire_save(list)]
  set segn [expr $llen - 1]
  struct wire_list w [lindex $wire_save(list) $segn]
  if { ${w.viatype} == 0 && $llen >= 2 } {
    # Most recent via may be on the end of the previous segment.
    # Try setting segn to that one.
    set segn [expr $llen - 2]
  }

  struct wire_list w [lindex $wire_save(list) $segn]
  switch $subcmd {
    "rotate" {
      if { ${w.viatype} != 0 } {
	set w.viaori [expr {${w.viaori} == 0 ? 1 : 0}]
      }
    }
    "symmetry" {
      if { ${w.viatype} != 0 } {
	set w.viasym [expr {${w.viasym} == 0 ? 1 : 0}]
      }
    }
    default { assert 0 }
  }
  set wire_save(list) [lreplace $wire_save(list) $segn $segn \
		    [destruct wire_list w]]

  _wire_begin_draw
}

# Undraw segment number segn in wire_save(list)
# If the segment has not been drawn, just do nothing.
proc _wire_undraw_segment {segn} {
    global WIRE wire_save
    struct wire_list w [lindex $wire_save(list) $segn]
    if { ${w.via} != "0" } {
	_wire_undraw_via $segn
    }

    # If w.layer is a composite layer, make a list of all of the layers.
    set layers [use_first WIRE(${w.layer},layers) w.layer]
    set layers [join $layers ,]

    # Each wire segment was drawn in its own group.
    # Currently, the only other way to delete a wire_path is by number,
    # so we have to search the wire-path list for the one we want.
    # In the current polygon implementation this will be unacceptably
    # slow if on real designs that use polygons, which is why we use groups.
    db_group wire_$segn
    sel_clear_g
    if { $WIRE(draw_mode) == "paint" && 
	( ${w.x1} == ${w.x2} || ${w.y1} == ${w.y2} ) } {
	# Wire was drawn with paint.  Select a big enough area to make
	# sure we get it all.
	set area [grow_rect $wire_save(max_wire_width) \
		[can_rect "${w.x1} ${w.y1} ${w.x2} ${w.y2}"]]
	# sel_area grabs cells (ie gcell vias) as well, so specify -layers.
	if { $wire_save(flylabel) == "" } {
	  # This is an optimization:  dont look for labels
	  # if we dont have too.  On large designs, looking through
	  # the single linked list of labels is slow.
	  eval sel_area -no_labels -layers $layers -group $area
	} else {
	  eval sel_area -layers $layers -group $area
	}
	:delete
    } else {
	# Wire was drawn with a wire-path polygon.
	# sel_area grabs cells (ie gcell vias) as well, so specify -layers.
	sel_area -layers $layers -group ${w.x1} ${w.y1} ${w.x2} ${w.y2}
	if {[sel_what polygons] != ""} {
	    # Note: this deletes wire_save(flylabel) too.
	    :delete
	}
    }
}

proc _wire_is_manhat {segn} {
  global wire_save
  struct wire_list w [lindex $wire_save(list) $segn]
  return [expr ${w.x1} == ${w.x2} || ${w.y1} == ${w.y2}]
}

# If same_width assume prev and next segments have same width
# as current segment for width determination.  This is used for
# composite wires (guard rings) that have multiple layers that
# may each be a different width.
proc _wire_draw_1layer {iseg layer width same_width} {
    global wire_save WIRE

    set llen [llength $wire_save(list)]

    set iprev [expr $iseg-1]
    set inext [expr $iseg+1]

    if { $inext < $llen && ! [_wire_is_manhat $inext] } {
      # Next segment is non-manhattan.  Current seg will be
      # drawn as part of the wirepath for the next segment.
      return
    }

    # See if we have to use a wirepath.  A wirepath is used for
    # all adjoining non-manhattan segments, plus the manhattan
    # segments at the either end.  We need to draw a wirepath if
    # this is the final manattan segment in a wirepath,
    # or if this is the last segment in the wire, and it
    # is non-manhattan; this case occurs while drawing a wire.

    if { $WIRE(draw_mode) != "paint" } {

      set use_wirepath 1
      set ifirst 0
      set iprev -1

    } else {
      # We have to figure out whether to use a wire-path for
      # this part of the wire

      set use_wirepath 0
      if { [_wire_is_manhat $iseg] } {
	# Current segment is manhattan.
	if { $iprev >= 0 && ! [_wire_is_manhat $iprev] } {
	  # Previous segment was non-manhattan.
	  set use_wirepath 1
	}
      } else {
	# This segment is non-manhattan.
	# Dont draw it now unless it is the very last segment.
	if { $iseg < $llen-1 } { return }
	set use_wirepath 1
      }

      if { $use_wirepath } {
	# Look backwards to find first seg: ifirst, to be used in this wirepath.
	# Need to find two manhattan segments in a row.
	for {set ifirst [expr $iseg - 1]} {1} {incr ifirst -1} {
	  if { $ifirst <= 0 } {
	    set ifirst 0
	    break
	  }
	  if {[_wire_is_manhat $ifirst] && [_wire_is_manhat [expr $ifirst-1]]} {
	    break
	  }
	}
	set iprev [expr $ifirst - 1]
      } else {
	# This segment will be drawn with paint.
	# Only one segment, which is the first and last being drawn this time.
	set ifirst $iseg
      }
    }

    # First segment; same as last segment if it is not a wirepath
    struct wire_list f [lindex $wire_save(list) $ifirst]
    setl {fx1 fy1 fx2 fy2} [list ${f.x1} ${f.y1} ${f.x2} ${f.y2}]
    # Last segment.
    struct wire_list l [lindex $wire_save(list) $iseg]
    setl {lx1 ly1 lx2 ly2} [list ${l.x1} ${l.y1} ${l.x2} ${l.y2}]

    # We now ALWAYS use square endcaps!
    if { $same_width } {
	set pwidth $width
    } elseif { $iprev < 0 } {
	# No previous segment; use wire width of first segment.
	set pwidth ${f.width}
    } else {
	struct wire_list p [lindex $wire_save(list) $iprev]
	# Use end-cap width of prev segment, in case segments
	# have different widths.
	set pwidth ${p.width}
    }
    if { $inext >= $llen || $same_width } {
	# No next segment; use width of current segment,
	# which will also be the last segment if its a wire path.
	set nwidth $width
    } else {
	struct wire_list n [lindex $wire_save(list) $inext]
	set nwidth ${n.width}
    }

    # left-hand/right-hand endcaps at first vertex.
    # make SURE we round up.
    set lhpwidth [uusnap -mask [expr $pwidth/2.0 + [res]/10]]
    set rhpwidth [expr $pwidth - $lhpwidth]
    # left-hand/right-hand endcaps at vertex x2,y2
    # make SURE we round up.
    set lhnwidth [uusnap -mask [expr $nwidth/2.0 + [res]/10]]
    set rhnwidth [expr $nwidth - $lhnwidth]


    # Implement square end-caps by extending wire length.
    if { $fy1 == $fy2 } {
      set fx1 [expr $fx1>$fx2 ? $fx1 + $rhpwidth : $fx1 - $lhpwidth]
    } elseif { $fx1 == $fx2 } {
      set fy1 [expr $fy1>$fy2 ? $fy1 + $rhpwidth: $fy1 - $lhpwidth]
    }

    if { $ly1 == $ly2 } {
	set lx2 [expr $lx2>$lx1 ? $lx2 + $rhnwidth: $lx2 - $lhnwidth]
    } elseif { $lx1 == $lx2 } {
	set ly2 [expr $ly2>$ly1 ? $ly2 + $rhnwidth: $ly2 - $lhnwidth]
    }

    if { $use_wirepath } {
      set verticies [list $fx1 $fy1]
      for {set i [expr $ifirst+1]} {$i <= $iseg} {incr i} {
	struct wire_list w [lindex $wire_save(list) $i]
	lappend verticies ${w.x1}
	lappend verticies ${w.y1}
      }
      lappend verticies $lx2
      lappend verticies $ly2

      eval db_wire_path $layer ${width} $verticies
    } else {

      # Draw the wire from fx1,fy1 to lx2,ly2.
      # If drawing a wire-path, we should really draw it all at once,
      # except it might be in multiple layers, and no one is supposed
      # to be using wire-paths anyway, so dont bother for now.
      # make SURE we round up.
      set lhwidth [uusnap -mask [expr ${width}/2.0 + [res]/10]]
      set rhwidth [expr ${width} - $lhwidth]
      if { $fx1 == $lx2 } {
	db_paint $layer [expr $fx1 - $lhwidth] $fy1 [expr $lx2 + $rhwidth] $ly2
      } else {
	assert { $fy1 == $ly2 }
	db_paint $layer $fx1 [expr $fy1 - $lhwidth] $lx2 [expr $ly2 + $rhwidth]
      }
    }

    return

    #### pre 4/21 code:


    set extend1 0	; # TRUE if square end-cap needed at x1,y1
    set extend2 0	; # TRUE if square end-cap needed at x2,y2
    if { $y1 == $y2 || $x1 == $x2 } {
	# This segment is manhattan.
	set rounded ""
	# Look at previous segment.
	if { $iprev < 0 || $same_width } {
	    # No previous segment; use square end-cap for this wire.
	    set extend1 1
	    set pwidth ${width}
	} else {
	    # Use square end-cap if previous segment p was manhattan too.
	    struct wire_list p [lindex $wire_save(list) $iprev]
	    set extend1 [expr ${p.x1} == ${p.x2} || ${p.y1} == ${p.y2} ]
	    # Use end-cap width of prev segment, in case segments
	    # have different widths.
	    set pwidth ${p.width}
	}
	# Look at following segment.
	if { $inext >= $llen || $same_width } {
	    # No next segment;
	    set extend2 1
	    set nwidth ${width}
	} else {
	    # Use square end-cap if next segment n is manhattan too.
	    struct wire_list n [lindex $wire_save(list) $inext]
	    set extend2 [expr ${n.x1} == ${n.x2} || ${n.y1} == ${n.y2} ]
	    set nwidth ${n.width}
	}
    } elseif {0} {
	# Segment is non-manhattan.
	if { [use_first WIRE(end_style)] == "square" } {
	  set rounded ""
	  # Look at previous segment: we need to add a little nubbin
	  # going the direction of the previous segment.
	  if { $iprev < 0 || $same_width } {
	      # No previous segment; use square end-cap for this wire.
	      set x0 ""
	      set y0 ""
	  } else {
	      struct wire_list p [lindex $wire_save(list) $iprev]
	      # Temporary: Extend all the way to previous vertex.
	      set x0 ${p.x1}
	      set y0 ${p.y1}
	  }
	} else {
	  set rounded "-rounded"
	  set x0 ""
	  set y0 ""
	}
    }

    # This rh/lh width stuff avoids max resolution problems.
    if { $extend1 } {
	# left-hand/right-hand endcaps at vertex x1,y1
	# make SURE we round up.
	set lhpwidth [uusnap -mask [expr $pwidth/2.0 + [res]/10]]
	set rhpwidth [expr $pwidth - $lhpwidth]
    }
    if { $extend2 } {
	# left-hand/right-hand endcaps at vertex x2,y2
	# make SURE we round up.
	set lhnwidth [uusnap -mask [expr $nwidth/2.0 + [res]/10]]
	set rhnwidth [expr $nwidth - $lhnwidth]
    }

    # Implement square end-caps by extending wire length.
    if { $y1 == $y2 } {
	if { $extend1 } {
	    set x1 [expr $x1>$x2 ? $x1 + $rhpwidth : $x1 - $lhpwidth]
	}
	if { $extend2 } {
	    set x2 [expr $x2>$x1 ? $x2 + $rhnwidth: $x2 - $lhnwidth]
	}
    } elseif { $x1 == $x2 } {
	if { $extend1 } {
	    set y1 [expr $y1>$y2 ? $y1 + $rhpwidth: $y1 - $lhpwidth]
	    }
	if { $extend2 } {
	    set y2 [expr $y2>$y1 ? $y2 + $rhnwidth: $y2 - $lhnwidth]
	}
    }

    # Draw the wire.
    # If drawing a wire-path, we should really draw it all at once,
    # except it might be in multiple layers, and no one is supposed
    # to be using wire-paths anyway, so dont bother for now.
    # make SURE we round up.
    set lhwidth [uusnap -mask [expr ${width}/2.0 + [res]/10]]
    set rhwidth [expr ${width} - $lhwidth]
    if { $x1 == $x2 && $WIRE(draw_mode) == "paint" } {
	db_paint $layer [expr $x1 - $lhwidth] $y1 [expr $x2 + $rhwidth] $y2
    } elseif { $y1 == $y2 && $WIRE(draw_mode) == "paint" } {
	db_paint $layer $x1 [expr $y1 - $lhwidth] $x2 [expr $y2 + $rhwidth]
    } else {
	eval db_wire_path $rounded $layer ${width} $x0 $y0 $x1 $y1 $x2 $y2
    }
}


# Draw a wire segment.  This is complicated because the end-cap
# style depends on the wires it is joined to.
# If this segment and the adjoining segment are both manhattan
# and at right angles, then we must extend them both by width/2
# to avoid a notch where they join.  We must NOT extend them
# in any other case.  If there is a via, we dont have to worry about it.
# If box_flag, add a visible box as a placement aid around the wire,
# but only if WIRE(wire_box_display) is TRUE.
# If final_flag, we are doing the final draw: use group 0 and paint if possible.
proc _wire_draw_segment {segn {box_flag 0} {final_flag 0}} {
    global WIRE wire_save

    _wire_draw_via $segn $box_flag $final_flag

    struct wire_list w [lindex $wire_save(list) $segn]

    if {$final_flag} {db_group 0} else {db_group wire_$segn}

    if {[lsearch -exact $WIRE(composite_layers) ${w.layer}] >= 0} {
	# This is a composite layer.  Get the list of the actual layers to draw.
	set layers $WIRE(${w.layer},layers)
	# The first layer is the contact, if any layer is.
	set lay1 [lindex $layers 0]
	foreach lay $layers {
	    set lwidth [techinfo width $lay]
	    # If the first specified layer has an exact width and the
	    # other layer has an overlap, set the minimum size
	    # to include the overlap.  Otherwise just use the width of $lay
	    set xxx [expr [techinfo width $lay1 $lay1 opt] + \
		2.0 * [techinfo overlap $lay $lay1 opt]]
	    set lwidth [max $lwidth $xxx]
	    _wire_draw_1layer $segn $lay $lwidth 1
	}
    } else {
	_wire_draw_1layer $segn ${w.layer} ${w.width} 0
    }

    setl {x1 y1 x2 y2} "${w.x1} ${w.y1} ${w.x2} ${w.y2}"

    # And now, draw a visible spacing box around the wire segment, if requested.
    # TODO: Should outline the vias, too.
    if { $box_flag && $WIRE(wire_box_display) } {
	layt_line_box wire_box_lines $x1 $y1 $x2 $y2 \
		${w.width} [use_first WIRE(${w.layer},sep) '1]
    }
}

# Update the on-screen interactive wiring.
# This requires redrawing the current wire, and the previous wire.
# The previous wire must be redrawn for two reasons:
# 1.  Coords may have changed.
# 2.  Right angles require square endcaps, non-right angles
# require rounded endcaps.  As we move current wire, we have to
# redraw the last endcap of the previous wire.
proc _wire_draw_update {} {
    global wire_save

    # Delete last two segments and redraw them.
    set i [llength $wire_save(list)]
    incr i -1
    _wire_undraw_segment $i
    _wire_draw_segment $i 1
    incr i -1
    if { $i >= 0 } {
	_wire_undraw_segment $i
	_wire_draw_segment $i
    }
    return

}


# Start interactive drawing mode.
# Draw the interactive wire segment.
proc _wire_begin_draw {} {
    global wire_save WIRE

    _wire_draw_update

    # Move flyline label to endpoint of current wire.
    struct wire_list w [lindex $wire_save(list) end]
    if { $wire_save(flylabel) != "" } {
	# Flyline label is always a simple label in the current cell,
	# so sel_labels will work on it.
	# Note: this is probably redundant: it was probably deleted
	# when the previous wire segment was deleted.
	sel_clear_g
	sel_labels -any_group -text $wire_save(flylabel)
	:delete
	# Use group of last wire segment.
	db_group wire_[expr [llength $wire_save(list)] - 1]
	layt_box exact ${w.x2} ${w.y2} ${w.x2} ${w.y2}
	:label -kind hidden $wire_save(flylabel) n ${w.layer}
    }

    # Draw a little visible box around wire endpoint.
    # Make SURE we round up.
    set lhwidth [uusnap -mask [expr ${w.width}/2.0 + [res]/10]]
    set rhwidth [expr ${w.width} - $lhwidth]
    # These are the exact coords of a square box around wire endpoint.
    setl {bx1 by1 bx2 by2} [list \
	[expr ${w.x2} - $lhwidth] [expr ${w.y2} - $lhwidth] \
        [expr ${w.x2} + $rhwidth] [expr ${w.y2} + $rhwidth]]
    # If the wire is manhattan, draw a rectangular, instead of square,
    # box as a visual cue to the user which way the wire is going.
    # It is irrelevant past this point whether we use lhwidth or rhwidth,
    # because it is just a visual clue.
    struct wire_list w [lindex $wire_save(list) end]
    if { $WIRE(snap_to_angle) == 90 } {
	switch [_wire_get_ori] {
	    "vert" {
		if { ${w.y1} < ${w.y2} } {
		    set by1 [expr $by2 - $rhwidth]
		} else {
		    set by2 [expr $by1 + $rhwidth]
		}
	    }
	    "horiz" {
		if { ${w.x1} < ${w.x2} } {
		    set bx1 [expr $bx2 - $rhwidth]
		} else {
		    set bx2 [expr $bx1 + $rhwidth]
		}
	    }
	}
    }
    layt_box exact $bx1 $by1 $bx2 $by2
}

# End interactive drawing mode.
# Remove the visible wire box, if any.
proc _wire_end_draw {} {
    global wire_save

    # Delete current segment, which was rubber-banding on the mouse.
    # It may be redrawn later by wire_begin_draw.
    _wire_undraw_segment [expr [llength $wire_save(list)] - 1]

    # Remove visible spacing box.
    lay_line -tag wire_box_lines -clear
}

proc _wire_set_anchor {val} {
    global wire_save
    if { $val == "toggle" } {
	set val [expr ! $wire_save(anchor)]
    }
    set wire_save(anchor) $val
}

proc _wire_set_snap_to_grid {val} {
    global WIRE
    if { $val == "toggle" } {
	set val [expr ! $WIRE(snap_to_grid)]
    }
    set WIRE(snap_to_grid) $val
}

# Snap x,y to the nearest valid coords for the current wire segment.
# Return new x y in a string as "x y".
# NOTE:  If you drop a via and change layers, the new wire you are
# dragging does NOT snap to the grid for the previous segment.
# This is the correct behavior: you want the snap to be entirely
# controlled by the current layer.
proc _wire_snap {x y layer via} {
    global WIRE
    if { ! $WIRE(snap_to_grid) } { return [uusnap -user $x $y] }

    setl {snapx snapy} [use_first WIRE($layer,snap)]
    setl {offsetx offsety} [use_first WIRE($layer,offset)]
    if {$snapx == ""} { set snapx [res -mask] }
    if {$snapy == ""} { set snapy $snapx }
    if {$offsetx == ""} { set offsetx 0 }
    if {$offsety == ""} { set offsety $offsetx }

    # If there is a via on the end of the current wire,
    # the via placement should be constrained by the layer we
    # are going to, but only if its constraints are more severe than layer.
    if { $via != "0" } {
	set otherlayer [_wire_via_other_layer $via $layer]
	setl {snap2x snap2y} [use_first WIRE($otherlayer,snap)]
	setl {offset2x offset2y} [use_first WIRE($otherlayer,offset)]
	if {$snap2x == ""} { set snap2x [res -mask] }
        if {$snap2y == ""} { set snap2y $snap2x }
	if {$offset2x == ""} { set offset2x 0 }
	if {$offset2y == ""} { set offset2y $offset2x }
	# What about asymetric snap grids?
	if { $snap2x > $snapx } {
	    set snapx $snap2x
	    set snapy $snap2y
	    set offsetx $offset2x
	    set offsety $offset2y
	}
    }
    if {$snapx != 0} {
      set x [expr $snapx*round(($x-$offsetx)/(0.0+$snapx))+$offsetx]
    }
    if {$snapy != 0} {
      set y [expr $snapy*round(($y-$offsety)/(0.0+$snapy))+$offsety]
    }
    return [uusnap $x $y]
}

# Modify (x2,y2) to fall on a valid angle, and return it.
proc _wire_snap_to_angle {snap_angle x1 y1 x2 y2 layer via prev_seg} {
    global WIRE
    # figure out what angle the wire should go
    set dx [expr $x2 - $x1]
    set dy [expr $y2 - $y1]
    # atan2 cant take (x,y) == (0,0) argument.
    set orig_angle [expr ($dy==0 && $dx==0) ? 0 : atan2($dy,$dx) * 180/3.1416]
    # Snap angle to nearest multiple of WIRE(snap_to_angle)
    if { $snap_angle } {
	set angle [expr int(round($orig_angle / $snap_angle)) * $snap_angle]
    } else {
	set angle $orig_angle  ;# All angle
    }
   
    # Restrict wire angle to previous segment to be > min_angle.
    if { $prev_seg != "" } {
      # Determine angle of previous wire.
      struct wire_list p $prev_seg
      set pdx [expr ${p.x2} - ${p.x1}]
      set pdy [expr ${p.y2} - ${p.y1}]
      # angle of previous segment, or 0 if zero-length.
      set p_angle [expr ($pdy==0 && $pdx==0) ? 0 : atan2($pdy,$pdx) * 180/3.1416]
      # r_angle is inverse of p_angle.
      set r_angle [expr (($p_angle < 0) ? (180+$p_angle):(-180+$p_angle))]
      # Theta is interior angle between the current segment and previous.
      set theta [expr $r_angle - $angle]
      while { $theta < -180 } { set theta [expr $theta + 360] }
      if { $theta > 180 } { set theta [expr $theta - 360] }
      if { $theta >= 0 && $theta < $WIRE(min_angle) } {
	set angle [expr $p_angle + (180-$WIRE(min_angle))]
      } elseif { $theta < 0 && - $theta < $WIRE(min_angle) } {
	set angle [expr $p_angle - (180-$WIRE(min_angle))]
      }
      if { $angle > 180 } { set angle [expr $angle - 360] }
      if { $angle < -180 } { set angle [expr $angle + 360] }
    }


    # Determine distance from x1,y1 to current mouse position:
    set dist [expr sqrt($dx*$dx + $dy*$dy)]
    # Determine the length of the right-angle projection of the
    # mouse position onto the nearest legal angle:
    set radius [expr $dist * cos(($orig_angle - $angle)*3.14159/180)]
    # Point p is x2,y2 snapped to nearest allowed angle.
    set p.x [expr $x1+$radius*cos($angle * 3.14159/180)]
    set p.y [expr $y1+$radius*sin($angle * 3.14159/180)]

    # 4/22/00: even if snap_to_grid is off, still need to snap to mask grid!
    #if { $WIRE(snap_to_grid) } {}
    if {1} {
	# The end-point above may not be on grid for several reasons:
	#   1. the angle is wierd.
	#   2. The angle was 90 or 45, but the start point was not on grid.
	# In these cases, we CAN NOT end on a grid intersection.
	# However, we can make it lie on either the x or the y grid line,
	# but not both.  So move point p to the nearest x or y grid line.
	# Let point a be where the radius crosses the nearest x grid,
	# and point b be where the radius crosses the nearest y grid.
	setl {snap.x snap.y} [_wire_snap ${p.x} ${p.y} $layer $via]
	if { ${snap.x} == $x1 && ${snap.y} == $y1 } {
	    # User hasnt moved yet.  Avoid problems with zero: just return.
	    return [uusnap -mask ${snap.x} ${snap.y}]
	}
	set a.x ${snap.x}
	# Be careful to avoid overflow/divide by zero of tan result.
	set tmp [expr tan($angle * 3.14159/180)]
	if { abs($tmp) > 1e10 } {
	    set a.y 1e10  ;# Wire is vertical.  Must use point b.
	} else {
	    set a.y [expr ${p.y} + (${snap.x} - ${p.x}) * $tmp]
	}
	set b.y ${snap.y}
	if { abs($tmp) < 1e-10 } {
	    set b.x 1e10  ;# Wire is horizontal.  Must use point a.
	} else {
	    set b.x [expr ${p.x} + (${snap.y} - ${p.y}) / $tmp]
	}
	# Which of points a or b is closer to point p? (Distances are
	# squared, but doesnt matter because we are only comparing.)
	set dist_to_a [expr pow(${p.x} - ${a.x},2) + pow(${p.y} - ${a.y},2)]
	set dist_to_b [expr pow(${p.x} - ${b.x},2) + pow(${p.y} - ${b.y},2)]
	if { $dist_to_a < $dist_to_b } {
	    return [uusnap ${a.x} ${a.y}]
	} else {
	    return [uusnap ${b.x} ${b.y}]
	}
    } else {
	return [uusnap -mask ${p.x} ${p.y}]
    }
}


# Works with any angle (including 90).
# All wire segments are wire paths while the user is editing the wire.
# When the user is all done, we will convert it into paint,
# depending on WIRE options.
proc _wire_drag {{modifier ""} {orig_x ""} {orig_y ""}} -desc {
  Within wiring mode only: respond to cursor motion during wire segment
  drawing in non-manhattan angles (45 default) mode.
} {
    global wire_save WIRE

    # If Motion event is not wanted at the moment, dont do this.
    if { $wire_save(disable_drag) } { return }

    # This happens when wire_drag is called to simulate a motion
    # event from some command (like wire menu) that is called before
    # wiring begins.
    if { $wire_save(list) == "" } { return }

    pan_auto "_wire_drag"

    if {$orig_x == "" || $orig_y == ""} {
        setl {orig_x orig_y} [layt_point exact]
    }
    if {$orig_x == "" || $orig_y == ""} {
        # off the screen
        return
    }
    # x2,y2 will be the new wire end point we are calculating, which
    # may not equal orig_x,orig_y due to snap.
    set x2 $orig_x
    set y2 $orig_y


    # Set struct w to the last segment, which we are drawing interactively.
    struct wire_list w [lindex $wire_save(list) end]
    # prev_seg is the next-to-last segment, if any.
    set iprev [expr [llength $wire_save(list)] - 2]
    # prev_seg will be "" if no previous segment
    set prev_seg [lindex $wire_save(list) $iprev]

    # Terminate interactive mode drawing, and undraw current segment.
    _wire_end_draw

    set snap_angle $WIRE(snap_to_angle)
    if { $modifier == "shift" } { set snap_angle 45 }

  # TODO!!!
  if {[lay_rootcell] != [lay_editcell]} {
    # DONT allow 45's in edit in place -- they break
    set snap_angle 90
  }

    # If manhattan and current vertex is unanchored,
    # slide previous wire segment.
    if { $snap_angle == 90 } {
	set done_flag 0
	setl {x2 y2} [_wire_snap $x2 $y2 ${w.layer} ${w.via}]
	# Anchor = 1 indicates that the vertex is anchored,
	# ie, the previous segment is no longer stretching.
	if { $prev_seg != "" && $wire_save(anchor) != "1" } {
	    # Get previous segment: p
	    struct wire_list p $prev_seg
	    # Modify the appropriate coordinates to make segments line up.
	    # About the orientation:
	    # If it is horiz or vert, this segment can only be oriented in
	    # the specified direction.  This is used in the segment previous
	    # to the current segment.  When you are moving the current segment
	    # and automatically realigning the previous segment, we need to
	    # know whether it was originally horizontal or vertical, because
	    # if its length goes to zero, we can no longer tell from
	    # its coordinates.
	    if { ${p.ori} == "vert" } {
		# Prev segment was vertical, this one must be horizontal
		set w.y1 $y2
		set p.y2 $y2
		set done_flag 1
	    } elseif { ${p.ori} == "horiz" } {
		# Vice versa.
		set w.x1 $x2
		set p.x2 $x2
		set done_flag 1
	    } else {
		# The previous segment was not manhattan, so it cant slide.
		# Do not alter previous segment, but make current segment
		# snap to 90 degree angle.
		set done_flag 0
	    }
	    # Undraw previous segment now before we change the data-base.
	    _wire_undraw_segment $iprev
	    # Save new location of previous segment in data-base.
	    set wire_save(list) [lreplace $wire_save(list) $iprev $iprev \
		[destruct wire_list p]]
	}
	if { ! $done_flag } {
	    # Snap to grid at 90 degrees.
	    # This could use the all-angle code below, but I want
	    # absolutely no round off error.
	    if { abs($orig_x-${w.x1}) <= abs($orig_y-${w.y1}) } {
		set x2 ${w.x1}
	    } else {
		set y2 ${w.y1}
	    }
	}
    } else {
	# All angle code.  Actually, this would work for 90 too,
	# but wouldnt slide the segments.
	setl {x2 y2} [_wire_snap_to_angle $snap_angle \
		${w.x1} ${w.y1} $x2 $y2 ${w.layer} ${w.via} $prev_seg]
    }

    # Change current segment location.
    set w.x2 $x2
    set w.y2 $y2
    set wire_save(list) [lreplace $wire_save(list) end end \
	[destruct wire_list w]]
    
    # Update cursor location message.
    cursor_msg_update [format "%9.3f,%9.3f" $x2 $y2] 

    #OLD: Box message displays length of current wire.
    #OLD: box_msg_update [format "wire dx=%8.2f, dy=%8.2f" \
    #OLD:     [expr ${w.x2} - ${w.x1}] [expr ${w.y2} - ${w.y1}]] 

    # Box status window now used for wire width.
    box_msg_update "wire width=${w.width}"

    # Restart interactive mode drawing.
    _wire_begin_draw

    # move the labels is too slow so do one at a time
    if {$wire_save(other_labels) != ""} {
        _wire_move_label_to_closest $x2 $y2 \
	    [lindex $wire_save(other_labels) $wire_save(other_label_num)] \
	    $wire_save(flylabel)
        incr wire_save(other_label_num)
        if {$wire_save(other_label_num) >= [llength $wire_save(other_labels)]} {
            set wire_save(other_label_num) 0
        }
    }
    return
}

# Given a via type and a layer, return the other layer connected to the via.
proc _wire_via_other_layer {via layer} {

  # Figure out new layer.
  setl {via other} [split $via _]

  if {$other != ""} {
    set layer2 $other
  } else {
    set layer2 [techinfo below $via]
  }

  set layer1 [techinfo above $via]

  if { [lsearch $layer1 $layer] != -1 } {
    set otherlayer [lindex $layer2 0]
  } elseif { [lsearch $layer2 $layer] != -1 } {
    set otherlayer [lindex $layer1 0]
  } else {
    # Can this happen?
    error "ERROR, Layer $layer not in via $via"
  }
  return $otherlayer
}


# Like wire_change_layers, but for new interface.
# Toggle the dragging of the last via.
proc _wire_drag_via {} {
    global wire_save
    if { $wire_save(drag_via) } {
	# Exit drag-via mode.
	set wire_save(drag_via) 0  ;# Tell add_segment to stop dragging vias.
	# And change to the other side of the via.
	_wire_change_layers
	return
    }

    # Enter drag-via mode.
    # Notify add_segment to start dragging vias.
    set wire_save(drag_via) 1

    # If there is only one segment, we cant do anything yet, but set
    # wire_save(drag_via) above so via will be dragged on next mouse click.
    set nsegs [llength $wire_save(list)]
    if { $nsegs < 2 } { return }

    # Get next to last wire segment.
    struct wire_list w [lindex $wire_save(list) [expr $nsegs - 2]]

    # No via to drag.
    if { ${w.via} == "0" } { return }

    # Terminate interactive mode drawing, and undraw current segment.
    _wire_end_draw

    # Eliminate the last segment.
    set wire_save(list) [lreplace $wire_save(list) end end]

    # Update the screen.
    _wire_drag
}


proc _wire_change_layers {} -desc {
  change wiring layer to other side of via
} {
    global wire_save

    struct wire_list w [lindex $wire_save(list) end]

    # Has a via been dropped?
    if { ${w.via} == "0" } {
	# no.  Cant change layers.
	return
    }

    # Terminate interactive mode drawing, and undraw current segment.
    _wire_end_draw

    # After a change-layer command, we dont have to drag
    # the via around any more.
    set wire_save(drag_via) 0

    # Starts out unanchored, so vertex can be moved.
    set wire_save(anchor) 0

    # Set orientation in segment just ended to horiz or vert.
    set w.ori [_wire_get_ori]
    set wire_save(list) [lreplace $wire_save(list) end end \
	    [destruct wire_list w]]

    # Add new zero length segment starting at old endpoint,
    # using new layer from other side of via and calculated width.
    set new.x1 ${w.x2}
    set new.y1 ${w.y2}
    set new.x2 ${w.x2}
    set new.y2 ${w.y2}
    set new.layer [_wire_via_other_layer ${w.via} ${w.layer}]
    set new.width [_wire_get_width ${new.layer}]
    if { ${new.width} == 0 } { return } ;# It failed.
    set new.via 0
    set new.viatype 0
    set new.viaori 0
    set new.viasym 0
    set new.ori 0
    lappend wire_save(list) [destruct wire_list new]

    _wire_begin_draw
}

proc wire_paint_via {vianame x y {from_layer ""} {width 0}} -desc {
    places a via at the given coords between the given layers
} -doc {
    return 0 on failure, via width on success
} {

  if { $from_layer != "" } {
    set min_wire_width [techinfo width $from_layer]
    if { $min_wire_width == "" } {
	return 0
    }
    set delta_min [expr $width - $min_wire_width]
  } else {
    set min_wire_width 0
    set delta_min 0
  }

  if {[lsearch [techinfo vias] $vianame] == -1} {
    # this is a compound via
    setl {vianame below} [split $vianame _]

  } else {
    set below [techinfo below $vianame]
  }

  lappend layers $vianame
  lappend layers [techinfo above $vianame]
  lappend layers $below

  # when the wire width is greater than minimum so that a dog bone is not
  # required for a contact/via, we need to modify our placement algorithm.

  # first determine how much to increase contact/via size
  if {$delta_min > 0 && $min_wire_width > 0} {
    set max 0

    foreach info $layers {
      setl {layer_name width length} $info
      set length [use_first length width]

      set max [max $max $width $length]
    }

    set delta_min [max 0 [expr $min_wire_width + $delta_min - $max]]
  }
    
  set max 0

  foreach layer $layers {

    # Pre make_tech:
    #setl {layer_name width length} $layer
    #set length [use_first length width]

    if { $layer == $vianame } {
	set width [techinfo width $vianame]
	if { $width == "" } { return 0 }
    } else {
	set tech_viawidth [techinfo width $vianame]
	set tech_enclose [techinfo enclose $layer $vianame]
	if { $tech_viawidth == "" || $tech_enclose == "" } {
	    return 0
	}
	set width [expr $tech_viawidth + 2.0 * $tech_enclose ]
    }
    if { $width == 0 } { return 0 }
    set length $width  ;# For now, square vias only.

    set dwl [uusnap [expr ($width + $delta_min) / 2.0]]
    set dlu [uusnap [expr ($length + $delta_min) / 2.0]]
    set dwr [expr ($width + $delta_min) - $dwl]
    set dld [expr ($length + $delta_min) - $dlu]

    # now draw the layer
    db_paint $layer [expr $x-$dwr] [expr $y-$dld] [expr $x+$dwl] [expr $y+$dlu]

    set max [max $max $dwl]
    set max [max $max $dlu]
  }

  return $max
}


# Draw via from wire_save(list) number segn.
# The via is placed at the end of the wire segment.
# TODO: implement box_flag: draw visible spacing box around via.
proc _wire_draw_via {segn box_flag final_flag} {
    global WIRE wire_save
    struct wire_list w [lindex $wire_save(list) $segn]
    if { ${w.via} == "0" } {
	# No via here
	return
    }
    set x2 ${w.x2}  ;# x2,y2 is location of center of via.
    set y2 ${w.y2}

    set did_via 0

      # first try a gcell
      db_group 0 ;# Probly not necessary.
      set via_name [lindex $WIRE(via_gcell_name) 0]
      set via_args [lrange $WIRE(via_gcell_name) 1 end]
      if { ${w.viasym} } {
	append via_args " -symmetric 1"
      }
      if { ( $WIRE(viatype) == "any" || $WIRE(viatype) == "gcell" ) && \
	![catch [eval list place_gcell $via_name {"$x2 $y2"} -type ${w.via} \
		-_BBOX_ {"0 0 ${w.width} ${w.width}"} $via_args]] } {
	# It worked
	# Remember the cell name so we can later erase it.
	set wire_save(vianame,$segn) [lindex [sel_what cells] 0]
	#if { ! $final_flag } { :identify wire_via_$segn }
	set w.viatype "gcell"
	set did_via 1

      }

      if { ! $did_via && \
	 ( $WIRE(viatype) == "any" || $WIRE(viatype) == "cell" ) && \
         ![catch "set wire_save(vianame,$segn) \
		\[db_instance ${w.via} $x2 $y2\]"]} {
	# It worked.  Note: the via cell must have its 0,0 origin
	# at the location that wants to be at the center of the wire.
	# Note that db_instance returned the cell name, which we saved.

	# 10/00: Dont use expand!!!  Select the cell and use
	# lay_internals, so you dont expand everything under the via, too.
	#layt_box user $x2 $y2 [expr $x2 + [res]] [expr $y2 + [res]]
	#:expand
	sel_cell2 $wire_save(vianame,$segn)
	lay_internals   ;# Expand selected cell.
	set did_via 1
	set w.viatype "cell"
      }

      if { $did_via && ${w.viaori} != 0 } {
	# After rotating it, need to move it so its origin,
	# which we assume is in the center, is back where it
	# was originally.
	setl {ox oy} [cell_origin]
	:clockwise
	setl {nx ny} [cell_origin]
	sel_move [expr $ox - $nx] [expr $oy - $ny]
      }

      # no cell for contact/via, don't use cell
      # Only print this message once.
      #if {!$did_via && [use_first wire_save(via_error_message)] == ""} {
      #	  msg "cant find a via subcell or gcell of type ${w.via}, painting vias\n"
      #	  set wire_save(via_error_message) 1
      #}

    if { ! $did_via && \
	( $WIRE(viatype) == "any" || $WIRE(viatype) == "paint" ) } {
	# Painted vias go into their own group while we are wiring.
	# They are painted into group 0 when we are all done.
        if {$final_flag} {db_group 0} else {db_group wire_via_$segn}

        # Save maximum width ever used for a via, to be used when
        # selecting them later on.
        set viawidth [wire_paint_via ${w.via} $x2 $y2 ${w.layer} ${w.width}]
	if { $viawidth == 0 } {
	    # wire_paint_via failed due to technology data missing.
	} else {
	    set wire_save(max_via_width) [max $viawidth $wire_save(max_via_width)]
	    set w.viatype "paint"
	    set did_via 1
	    if { ${w.viaori} != 0 } {
	      # The painted via is currently symmetric, so rotation
	      # would do nothing.
	    }
	}
    }
    if { ! $did_via } {
	# Remove the via from the database.
	set w.viatype 0
	set w.via 0
	max_error "warning: Can not create $WIRE(viatype) type of via"
    }

    # Save the kind of via we drew
    set wire_save(list) [lreplace $wire_save(list) $segn $segn \
	    [destruct wire_list w]]
}

# Remove the via in wire_save(list) number segn.
proc _wire_undraw_via {segn} {
    global WIRE wire_save

    struct wire_list w [lindex $wire_save(list) $segn]

    if { ${w.viatype} == "cell" || ${w.viatype} == "gcell" } {
	# Search for a via instance.
	db_group 0 ;# Probly not necessary
	# remove the via instance
	sel_clear_g
	if { [info exists wire_save(vianame,$segn)] &&
	     ![msg_catch "sel_cell2 $wire_save(vianame,$segn)"] } {
	    # worked
	    # We use wire_save(vianame,...) as a semaphore: we set it
	    # when the via is drawn, and unset it when the via is removed.
	    # This prevents us from accidently removing a via with the
	    # same name but that we didnt draw.
	    unset wire_save(vianame,$segn)
	    :delete
	    return
	}
    }

    # Via is painted.  Erase anything using its group name.

    # FYI: the via is at w.x2,w.y2
    db_group wire_via_$segn
    #lay_box [expr ${w.x2} - $wire_save(max_via_width)] \
    #	[expr ${w.y2} - $wire_save(max_via_width)] \
    #	[expr ${w.x2} + $wire_save(max_via_width)] \
    #	[expr ${w.y2} + $wire_save(max_via_width)]
    #:select -g -editOnly area *,labels
    # The -layers * is necessary to avoid grabbing gcell vias.
    sel_clear_g
    sel_area -no_labels -group -layers * [expr ${w.x2} - $wire_save(max_via_width)] \
	[expr ${w.y2} - $wire_save(max_via_width)] \
	[expr ${w.x2} + $wire_save(max_via_width)] \
	[expr ${w.y2} + $wire_save(max_via_width)]
    # toast it
    :delete
}


# TODO: Make this delete from database and update screen.
#proc _wire_remove_via {} -desc {
#  in wire mode only: removes a via on current segment if there is one
#} {
#    global wire_save
#    struct wire_list w [lindex $wire_save(list) end]
#
#    # If no via on current segment, just return.
#    if { ${w.via} == "0" } { return }
#
#    # TODO: FIX THIS!!
#    # WHAT ABOUT CELLS?
#
#    set segn [expr [llength $wire_save(list)] - 1]
#    # Undraw the via, remove it from the data-base.
#    _wire_undraw_via $segn
#    set w.via 0
#    set wire_save(list) [lreplace $wire_save(list) end end \
#	[destruct wire_list w]]
#
#    # simulate a motion event to update the screen.
#    _wire_drag
#}


proc _wire_add_via {dir} -desc {
  Adds a via to the end of the current wire (up or down depending on argument).
  If change_layer, also changes to the new layer.
} {
  global wire_save

  set endit 0

  struct wire_list w [lindex $wire_save(list) end]

  if { ${w.via} != "0" } {
    assert { $wire_save(drag_via) == 1 }
    # Drop the via we are currently dragging, which creates
    # a new little tiny wire segment, on which we can put
    # the new via we want to drop.
    _wire_change_layers
    struct wire_list w [lindex $wire_save(list) end]
  }

  if {$dir == "up"} {
    set dir above
  } else {
    set dir below
  }

  set w.via [techinfo $dir ${w.layer} "" opt]

  if {${w.via} == ""} {
    max_error "warning: can't add via $dir ${w.layer}.  No more layers."
    return
  }

  set to_layer [techinfo $dir ${w.via} "" opt]

  if {$dir == "above" && [llength [techinfo below ${w.via}]] > 1} {
    set w.via ${w.via}_${w.layer}
  }

  if {[llength $to_layer] > 1} {
    # multiple layers below, use one under cursor or first one in list
    set layers [dbt_short_name [db_search touchingtypes ${w.x2} ${w.y2}]]

    foreach layer $to_layer {
      if {[lsearch $layers $layer] != -1} {
	set endit 1
	set to_layer $layer
	break
      }
    }

    if {!$endit} {
      # just choose a layer (prefer poly in devices)
      foreach fet [techinfo devices] {
	set poly [lindex [techinfo device $fet] 0]

	if {[lsearch $to_layer $poly]} {
	  # found one, use it
	  set to_layer $poly
	  break
	}
      }

      # just in case you couldn't find one
      set to_layer [lindex $to_layer 0]
    }

    # compound via name
    set w.via ${w.via}_$to_layer
  }

  # Save the new via name in the segment description.
  set wire_save(list) \
	[lreplace $wire_save(list) end end [destruct wire_list w]]
    
  if { $endit } {
    # The via connected to the layer below, so this wire is hooked up.
    _wire_end
    return
  }

  if { $wire_save(drag_via) == 0 } {
    _wire_change_layers

  } else {
    # simulate a motion event to update the screen.
    _wire_drag

    # We will drag the new via until user changes layers.
  }
}


#proc _wire_stub_calculate {x y list} -desc {
#  calculates if there is a stub that must be removed
#} {
#  global wire_save
#
#  setl {x1 y1 x2 y2} [lrange $list 0 3]
#
#  if {$x == [lindex $list 0]} {
#    set z $y
#    setl {bogus1 z1 bogus2 z2} [lrange $list 0 3]
#  } else {
#    set z $x
#    setl {z1 bogus1 z2 bogus2} [lrange $list 0 3]
#  }
#
#  if {$z1 > $z2} {
#    set z1 [expr $z1 + $wire_save(rhwidth)]
#    set z2 [expr $z2 + $wire_save(rhwidth)]
#    if {$z >= $z1} {
#      # no stub
#      return 0
#    } else {
#      if {$x == [lindex $list 0]} {
#	# vertical stub
#	return [list [expr $x - $wire_save(lhwidth)] $z1 \
#		    [expr $x + $wire_save(rhwidth)] \
#		    [expr [max $z $y2] + $wire_save(rhwidth)]]
#      } else {
#	# horizontal stub
#	return [list $z1 [expr $y - $wire_save(lhwidth)] \
#		    [expr [max $z $x2] + $wire_save(rhwidth)] \
#		    [expr $y + $wire_save(rhwidth)]]
#      }
#    }
#  } else {
#    set z1 [expr $z1 - $wire_save(lhwidth)]
#    set z2 [expr $z2 - $wire_save(lhwidth)]
#    if {$z <= $z1} {
#      # no stub
#      return 0
#    } else {
#      if {$x == [lindex $list 0]} {
#	# vertical stub
#	return [list [expr $x - $wire_save(lhwidth)] $z1 \
#		    [expr $x + $wire_save(rhwidth)] \
#		    [expr [min $z $y2] - $wire_save(lhwidth)]]
#      } else {
#	# horizontal stub
#	return [list $z1 [expr $y - $wire_save(lhwidth)] \
#		    [expr [min $z $x2] - $wire_save(lhwidth)] \
#		    [expr $y + $wire_save(rhwidth)]]
#      }
#    }
#  }
#}


# This routine is necessary because label selection does not work very well:
#    sel_labels does not work yet if label is in a sub-cell.
#    sel_attached_wire appears to work ONLY if label is in a sub-cell.
#    db_search takes a label name, but not fully qualified, and it
#    also returns coords in the sub-cell coord system, which must subsequently
#    be modified by the cell transform.  This is NOT the same as
#    translating by the cell bounding box.
# So get all matching labels with db_search, and then search for
# the sub-cell we want, transform it, and return that.
# Note: The cells must be expanded or this will not work.
# Note: This searches ALL labels in the design (if the cells are expanded),
# so only use this for stdcells!!!!
proc _wire_find_label {label} {
    # Label name consists of path/text
    regsub {^.*/} $label "" text
    regsub {[^/]*$} $label "" path  ;# path includes the trailing slash.
    foreach info [db_search_l labels -any_cell $text] {
	if { $path == "" } {
	    # Not in a subcell.
	    return $info
	}
    	struct max_label lab $info
	if { ${lab.path} == $path } {
	    global MAX_DB_SEARCH_FIXED
	    if {[use_first MAX_DB_SEARCH_FIXED] == 1} {
		return $info
	    } else {
		# Transfrom coords using the cell transform.
		# Given local coords x1,y1, the parent coords x2,y2 are:
		# x2 = x1 tax + y1 tay + tac
		# y2 = x1 tbx + y1 tby + tbc
		sel_clear_g
		sel_cell $path
		struct max_cell cell [sel_what cells]
		setl {tax tay tac tbx tby tbc} ${cell.transform}
		set lab.x1 [expr ${lab.x1}*$tax + ${lab.y1}*$tay + $tac]
		set lab.y1 [expr ${lab.x1}*$tbx + ${lab.y1}*$tby + $tbc]
		set lab.x2 [expr ${lab.x2}*$tax + ${lab.y2}*$tay + $tac]
		set lab.y2 [expr ${lab.x2}*$tbx + ${lab.y2}*$tby + $tbc]
		return [destruct max_label lab]
	    }
	}
    }
    return ""
}


proc _wire_unique_label {} -desc {
  returns a unique label name
} {
  global LABEL_COUNT
  if {![info exists LABEL_COUNT]} { set LABEL_COUNT 1 }

  set name wire_tmp_label[incr LABEL_COUNT]
  while {[_wire_find_label $name] != ""} {
     set name wire_tmp_label[incr LABEL_COUNT]
  }

  return $name
}


proc _wire_find_connected_labels {labels} -desc {
  Given a set of labels, recursively follow flylines to other nets
  that are connected by flylines.  Return the complete set of labels
  that were connected by flylines, and delete all those flylines.
  note, assumes that label names are unique
} {
  if {$labels == ""} {
    return ""
  }

  set other_labels ""

  # Make other_labels a list of labels that are connected to labels by flylines.
  # Delete those flylines.
  foreach label $labels {
    foreach line [split [db_flyline $label] \n] {
      setl {bogus label1 label2} $line
      if {$bogus == ""} {
	continue
      }

      if {$label1 == $label} {
	set other_label $label2
      } else {
	set other_label $label1
      }

      # lose the flyline
      db_flyline -delete $label $other_label

      lappend other_labels $other_label
    }
  }


    # Make search_labels a list of labels that are connected to
    # other_labels by paint.
    set search_labels ""
    foreach label $other_labels {

	set info [_wire_find_label $label]
	if { $info != "" } {

	    struct max_label lab $info
	    # select the entire net
	    sel_clear_g
	    sel_net -point ${lab.x1} ${lab.y1} ${lab.layer}

	    foreach con_label [split [sel_what labels] \n] {
	      struct max_label lab2 $con_label
	      set con_name "${lab2.path}${lab2.text}"
	      if {[lsearch -exact $search_labels $con_name] == -1} {
		  lappend search_labels $con_name
	      }
	    }
	}
    }

  return "$other_labels [_wire_find_connected_labels $search_labels]"
}


proc _wire_remove_duplicate_labels {labels} -desc {
  returns only one hidden label per net.  deletes redundant hidden labels
} {

  foreach label [string trim $labels] {
    # select the label
    #sel_labels -text $label
    #setl {layer x1 y1 x2 y2 pos text path_unused group_unused kind}
    set info [_wire_find_label $label]
    if { $info == "" } {
	# Ignore already removed labels.
	continue
    }
    struct max_label lab $info
    # Do not remove non-hidden labels.
    if {${lab.kind} != "hidden"} {
	set save($label) 1
        continue
    }

    set save($label) 1

    # select the entire net that this label is attached to
    sel_clear_g
    sel_net -point ${lab.x1} ${lab.y1} ${lab.layer}

    # now discard duplicate hidden labels
    foreach other_label [split [sel_what labels] \n] {
      if { $other_label == "" } { continue }
      struct max_label lab2 $other_label
      if {"${lab2.path}${lab2.text}" != $label && ${lab2.kind} == "hidden"} {
	  # toast it
	  sel_labels -text ${lab2.text}
	  :delete
      }
    }
  }

  if {[info exists save]} {
    return [array names save]
  } else {
    return ""
  }
}


proc _wire_change_flylines {x y layer} -desc {
  change all flylines on this virtual net to have one endpoint at the given label
} {

  global wire_save WIRE

  if { ! $WIRE(move_flylines) } { return }

  # find what labels are connected to this one

  if {[db_flyline] == ""} {
    # no flylines in this cell
    set wire_save(flylabel) ""
    set wire_save(other_labels) ""

    return
  }

  # select the entire net
  sel_clear_g
  sel_net -point $x $y $layer

  set labels ""
  foreach label [sel_what_l labels] {
      struct max_label lab $label
      lappend labels "${lab.path}${lab.text}"
  }

  set other_labels [string trim [_wire_find_connected_labels $labels]]
  set other_labels [_wire_remove_duplicate_labels $other_labels]

  # TODO: I am currently ignoring this label.
  set label [_wire_remove_duplicate_labels $labels]

  set wire_save(flylabel) [_wire_unique_label]

  # now put the flylines back in, all referenced to label that is moving
  foreach other_label $other_labels {
    db_flyline $wire_save(flylabel) $other_label
  }
  set wire_save(other_labels) $other_labels
}


proc _wire_clean_flylines {} -desc {
  Fixes up flylines at end of wire_draw mode:
  Moves flyline labels to group 0;
  Removes flylines between labels that are connected.
} {
    global WIRE wire_save
    if { ! $WIRE(move_flylines) } { return }

    if {$wire_save(flylabel) == ""} {
	return
    }
    # The wire_save(flylabel) is the temporary label at the end
    # of the wire segment we are currently wiring.
    set flylabel $wire_save(flylabel)

    # Set w to the info on the last wire segment.
    struct wire_list w [lindex $wire_save(list) end]
    # FYI: the label is at w.x2,w.y2

    # Remove the old flylabel (might already have been done)
    # and put it back where it belongs.
    sel_clear_g
    sel_labels -any_group -text $flylabel
    :delete
    db_group 0
    layt_box exact ${w.x2} ${w.y2} ${w.x2} ${w.y2}
    :label -kind hidden $flylabel n ${w.layer}

    # select the entire net from this point
    # TODO: This could be vdd/gnd!!!  Could take an hour!
    sel_clear_g
    sel_net -point ${w.x2} ${w.y2} ${w.layer}

    set selected ""
    foreach label_info [split [sel_what labels] \n] {
	struct max_label lab $label_info
	lappend selected "${lab.path}${lab.text}"
    }

    foreach flyline [split [db_flyline $flylabel] \n] {
      setl {bogus label1 label2} $flyline
      if {$bogus == ""} {
	continue
      }

      if {$label1 == $flylabel} {
	set other_label $label2
      } else {
	set other_label $label1
      }
      
      if {[lsearch -exact $selected $other_label] != -1} {
	# found a connected label.  Now delete flyline and label
	db_flyline -delete $flylabel $other_label
	sel_clear_g
	sel_labels -any_group -text $other_label
	# Delete the label if it is a hidden label.
        set label_info [lindex [split [sel_what labels] \n] 0]
	if { $label_info != "" } {
	    struct max_label lab $label_info
	    if { ${lab.kind} == "hidden" } {
		:delete
	    }
	}
      }
    }
    
    # is this label has no more flylines attached to it, waste it
    if {[db_flyline $flylabel] == ""} {
	sel_clear_g
        sel_labels -text $flylabel
        :delete
    }
}


proc _wire_move_label_to_closest {x y label flylabel} -desc {
  moves a label to the closest point to (x,y) on the same wire
} {

  global WIRE
  if { ! $WIRE(move_flylines) } { return }

  # If label is in a sub-cell, we cant move it.
  # We could, but we would have to rename it, because its name in
  # the subcell (subcell/lab) is not valid in the parent, and
  # we would destroy the ability to move the sub-cell and have
  # the labels go with it.

  if { [string first "/" $label] >= 0 } { return }


  # first select the entire line that contains the label
  #OLD: sel_labels -any_group -text $label
  set info [_wire_find_label $label]
  if { $info == "" } { return }  ;# This probably cant happen

  struct max_label lab $info
  if { ${lab.kind} != "hidden" } { return }
  set save_x ${lab.x1}
  set save_y ${lab.y1}

  if {[db_search touchingtypes $save_x $save_y] == ""} {
    # label isn't connected to anything, just return
    return
  }

  set old_group [db_group]
  db_group ${lab.group}

  # select the entire net
  sel_clear_g
  sel_net -point $save_x $save_y ${lab.layer}

  # if the connection is made then the other label will now be selected
  foreach label_info [sel_what_l labels] {
      struct max_label lab2 $label_info
      if {"${lab2.path}${lab2.text}" == $flylabel} {
          # we're connected, get out of here
          db_group $old_group
          return
      }
  }

  # shouldn't be farther away than this
  set save_delta 1.0e20

  # now walk through each piece of paint and look for closest
  foreach paint [split [sel_what paint] \n] {
    setl {layer x1 y1 x2 y2} $paint
    # move coords to inside of paint
    if {[expr $y2 - $y1] > [expr $x2 - $x1]} {
      set delta [uusnap [expr ($x2 - $x1)/2.0]]
      set x1 [expr $x1 + $delta]
      set x2 $x1
      set y1 [expr $y1 + $delta]
      set y2 [expr $y2 - $delta]
    } else {
      set delta [uusnap [expr ($y2 - $y1)/2.0]]
      set y1 [expr $y1 + $delta]
      set y2 $y1
      set x1 [expr $x1 + $delta]
      set x2 [expr $x2 - $delta]
    }
    
    # now find closest point to (x,y) in this paint
    if {$x < $x1} {
      set nx $x1
    } elseif {$x > $x2} {
      set nx $x2
    } else {
      set nx $x
    }
    if {$y < $y1} {
      set ny $y1
    } elseif {$y > $y2} {
      set ny $y2
    } else {
      set ny $y
    }

    # is this the closest yet
    set ndelta [expr ($x-$nx)*($x-$nx) + ($y-$ny)*($y-$ny)]
    if {$ndelta < $save_delta} {
      set save_delta $ndelta
      set save_x $nx
      set save_y $ny
      set save_layer $layer
    }
  }

  # now move the label to this new spot
  if {$save_x != "${lab.x1}" || $save_y != "${lab.y1}"} {
    # only move label if there is the correct editcell layer there
    # NOT VERY GOOD (lee)
    # Note: this also prevents us from moving a label onto the
    # wire we are currently wiring, because it is in a different group,
    # which is good, because if we later undid part of the wire,
    # the labels could end up in space. (pat)

    #OLD: lay_box $save_x $save_y [expr $save_x + [res]] [expr $save_y + [res]]
    #OLD: :select -editOnly area $layer
    sel_clear_g
    db_group 0
    sel_area -group -no_labels -any_cell -layer $layer \
	$save_x $save_y [expr $save_x + [res]] [expr $save_y + [res]]
    if {[sel_what paint] != ""} {
      # move the label
      sel_labels -text $label
      :delete

      #OLD: lay_box $save_x $save_y $save_x $save_y
      #OLD: :label -kind hidden $label n $save_layer
      db_label -kind hidden -pos n $save_layer $label \
	$save_x $save_y $save_x $save_y
    }
  }
  db_group $old_group
}


proc _wire_undo {} -desc {
  if in wire mode: undo last wire, if any
  if in wire_draw mode: undo last via or wire segment
  if last segment, pop out of wire_draw mode to wire mode.
} {
    global WIRE wire_save

    # FOR PERSISTENT WIRE MODE:
    # Are we still in wire mode?
    # Only undo wires.  Dont undo stuff that happened before wire mode.
    if { [mode_current] == "wire" } {
	if { $wire_save(wire_count) == 0 } {
	    msg "no wires to undo!\n"
	} else {
	    incr wire_save(wire_count) -1
	    :undo
	}
	return
    }


    set segn [expr [llength $wire_save(list)] - 1]
    # If user hasnt started wiring, do nothing.
    # This can happen if we were called from the popup menu in wire mode.
    if { $segn < 0 } { return }

    # Remove current segment, flyline label, and other visible stuff.
    _wire_end_draw

    # Get the current segment w
    struct wire_list w [lindex $wire_save(list) end]
    if { ${w.via} != "0" } {
	# Remove the via as our undo.
	set w.via 0
	set w.viatype 0
	set wire_save(list) [lreplace $wire_save(list) end end \
	    [destruct wire_list w]]
    } else {
	# Is this the last segment?
	if { $segn == 0 } {
	    # There is only one segment.  Is it really short?
	    # We test for shortness to allow some jitter in the mouse.
	    set near_flag [nearby ${w.x1} ${w.y1} ${w.x2} ${w.y2}]
	    if { $WIRE(snap_to_grid) } {
		# If you start unsnapped to grid and then set snap to grid,
		# the wire end point will never get "nearby" the starting
		# point;  the closest it can get is the nearest grid point.
		# So see if mouse is within one grid of starting point.
		setl {snapx snapy} [use_first WIRE(${w.layer},snap) '0]
		set snap [max $snapx $snapy]
		if { [max [expr abs(${w.x1} - ${w.x2})] \
			[expr abs(${w.y1} - ${w.y2})]] < $snap } {
		    set near_flag 1
		}
	    }

	    # Make the last segment zero length.
	    set w.x2 ${w.x1}
	    set w.y2 ${w.y1}
	    set w.ori 0
	    set wire_save(list) [lreplace $wire_save(list) end end \
		[destruct wire_list w]]
	    if { $near_flag } {
		# We want to back out of wire_draw mode entirely.
		# Segment was already undrawn, above.
		# The clean_flyline code fishes the flylabel location
		# from the last segment x2,y2.  So we must make the segment
		# zero length (above), or wire_clean_flyline will leave 
		# flylabel in space, and the flylines will end up unconnected.
		# lose any flylines for connections that are now complete
		_wire_clean_flylines
		# We have to clear wire_save(list) or the popups and
		# things will try to update the screen.
		set wire_save(list) ""  ;# Remove last segment.
		# Restore the box as a visual alert that we are done.
		eval layt_box exact $wire_save(box)
		mode_pop                ;# Pop out of wire_draw mode.
		return
	    }
	} else {
	    # Look at previous segment.  If it had a via, then
	    # if we are close, back out the via, otherwise
	    # make current segment zero length.
	    struct wire_list u [lindex $wire_save(list) [expr $segn - 1]]
	    if { ${u.via} != 0 } {
		if { [nearby ${w.x1} ${w.y1} ${w.x2} ${w.y2}] } {
		    # Remove the via, which is actually on the end of the
		    # previous segment, so we need to delete the current
		    # segment, then remove the via on the previous segment.
		    set wire_save(list) [lreplace $wire_save(list) end end]
		    _wire_undraw_via [expr $segn - 1]
		    set u.via 0
		    set wire_save(list) [lreplace $wire_save(list) end end \
			[destruct wire_list u]]
		} else {
		    # Make the current segment zero length.
		    set w.x2 ${w.x1}
		    set w.y2 ${w.y1}
		    set w.ori 0
		    set wire_save(list) [lreplace $wire_save(list) end end \
			[destruct wire_list w]]
		}
	    } else {
		# Remove current segment.
		set wire_save(list) [lreplace $wire_save(list) end end]
	    }
	}
	# If the cursor went off the screen, re-center it.
	setl {winx1 winy1 winx2 winy2} [dbt_frame]
	if { ${w.x1} < $winx1 || ${w.x1} > $winx2 || \
		${w.y1} < $winy1 || ${w.y2} > $winy2 } {
	    # view_center_cursor does not work if the location we want
	    # to go to is off-screen.
	    view_center ${w.x1} ${w.y1}
	}
	layt_point -warp exact ${w.x1} ${w.y1}
    }

    set wire_save(drag_via) 0
    set wire_save(anchor) 0

    # simulate a motion event so wire moves to new cursor position
    # This will eventually replace flylabel, too.
    _wire_drag
}


# Note that these procs assume the array is a global
#proc _encapsulate_array {array} -desc {
#  return a list that includes everything about an array
#} {
#  upvar #0 $array this_array
#
#  set list ""
#  foreach name [array names this_array] {
#    lappend list [list $name $this_array($name)]
#  }
#
#  return $list
#}

#proc _decapsulate_array {list array} -desc {
#  remake an array from an encapsulated array list
#} {
#  upvar #0 $array this_array
#
#  # first toast this array if it already exists
#  catch {unset this_array}
#
#  foreach pair $list {
#    set this_array([lindex $pair 0]) [lindex $pair 1]
#  }
#}

proc _wire_set_snap_to_angle {angle} {
    global wire_save WIRE
    if { $angle == "toggle" } {
	if { $WIRE(snap_to_angle) == 90 } {
	    set angle 45
	} else {
	    set angle 90
	}
    }
    if { $angle != 90 } {
    }
    set WIRE(snap_to_angle) $angle
    # simulate a motion event so wire moves to new cursor position
    _wire_drag
}


proc _wire_edit_process_parameters { {type 0} } {
    global LAYINFO

    set nitems 1
    foreach attr [lsort [array names LAYINFO]] {
	# Only edit LAYINFO entries that do not contain a colon.
	if { [regexp {:} $attr] } { continue }
	set item "$attr LAYINFO($attr)"
	if {[incr nitems] >= 25} {
	    set nitems 1
	    append item " -break"
	}
	lappend prop_list $item
    }

    # create the menu
    prop_menu2 -title "Process Parameters" $prop_list
}

# Creates a table to edit the wire widths and grid.
proc wire_grid_menu {} -desc {
  View the wire grid and width menu
} {
    global WIRE
    _wire_init  ;# Just in case

    set prop_list ""
    # TODO: I want to add this label to the top of the table,
    # but there is no way to do it in prop_menu yet.
    # TODO: I want to make the stuff below a real table with only
    # one set of labels on the right, but prop_menu does not work
    # with empty prop names now.
    #lappend prop_list [list {Note: origin can be one number for} "" -label]
    #lappend prop_list [list {    both x and y, or two numbers: x y} "" -label]

    # The re-initialization of the various WIRE things is necessary
    # in case the user wired in an unrecognized layer, which added
    # the new layer into config_layers.

    lappend prop_list [list "DEFAULT WIRE WIDTH" "" -label]
    foreach layer $WIRE(config_layers) {
	set WIRE($layer,width) [use_first WIRE($layer,width) '0]
	lappend prop_list [list "$layer width:" WIRE($layer,width)]
    }
    lappend prop_list [list "WIRE GRID (snap <or> snapx snapy)" "" -label]
    foreach layer "$WIRE(config_layers)" {
	set WIRE($layer,snap) [use_first WIRE($layer,snap) '1]
	lappend prop_list [list "$layer snap" WIRE($layer,snap) -entry]
    }

    # Add -break to last line.
    set last [lindex $prop_list end]
    set prop_list [lreplace $prop_list end end [lappend last -break]]

    lappend prop_list [list "WIRE SPACING" "" -label]

    foreach layer $WIRE(config_layers) {
	# If the separation is inited to 0, then when the user turns
	# on the spacing box, nothing visible will happen.  Therefore,
	# set it to 1, which will be wrong, but at least it will be
	# visible, and hopefully the user will figure out s/he has
	# to go to the wire menu to change it.
	set WIRE($layer,sep) [use_first WIRE($layer,sep) '1]
	lappend prop_list [list "$layer sep" WIRE($layer,sep)]
    }

    lappend prop_list [list "GRID ORIGIN (offset <or> offsetx offsety)" "" -label]
    foreach layer $WIRE(config_layers) {
	set WIRE($layer,offset) [use_first WIRE($layer,offset) '0]
	lappend prop_list [list "$layer origin" WIRE($layer,offset)]
    }

    prop_menu2 -title "Wiring Parameters" $prop_list
}


proc wire_menu {} -desc {
  Displays the wire mode menu
} {
  global TOOL_BAR WIRE wire_save

  _wire_init

  # create the prop menu
  set prop_list ""

  set layer $TOOL_BAR(layer)

  lappend prop_list [list "Active Layer:" layer \
    -choice "auto [_wire_info wire_layers]" \
    -help {the layer the wire tool will use to draw the wire.\
    If "auto", the wire tool will attempt to determine the correct\
    layer by looking under the mouse when the wire is started.\
    The Active Layer can also be set using the "Active:" indicator\
    at the upper left of the max screen.} ]
  lappend prop_list [list "Default Layer:" WIRE(default_layer) \
    -choice "[_wire_info wire_layers]" \
    -help {the preferred wire layer;  the wire tool will use this layer\
    if the "Active Layer" (in the box above the palette) is set to "auto",\
    and either the Default Layer is found under the cursor, or there are no\
    layers under the cursor.}]
  lappend prop_list [list "Display spacing box" WIRE(wire_box_display) \
    -binary -help {a visible spacing will be displayed showing the\
    current spacing of the wire being drawn, as specified in the\
    Wiring Parameters menu.}]
  lappend prop_list [list "Snap to Wire Grid" WIRE(snap_to_grid) \
    -binary -help {wire end-points and verticies will snap to the wiring\
    grid specified in the Wiring Parameters menu.  This is NOT the same\
    as the User Grid in the Grid menu.  You can specify a different\
    wiring grid for each layer being wired in the Wiring Parameters Menu.\
    When placing a via, the via will be moved to the nearest valid\
    intersection of the grids of the two layers being connected by the via.}]
  lappend prop_list [list "Snap to Angle" WIRE(snap_to_angle) \
    -choice "90 45 30 15 0" \
    -help {wires will be constrained to the specified angle.}]
  # This is disabled temporarily because wire-paths are not
  # implemented efficiently in max, so we dont want people using them.
  if {0} {
    lappend prop_list [list "Minimum angle" WIRE(min_angle) \
      -number 0 90 -validate -help {Minimum angle allowed in all angle mode}]
    lappend prop_list [list "Draw Wires Using" WIRE(draw_mode) \
      -choice {paint wire-path}]
  }
  lappend prop_list [list "Draw Vias Using" WIRE(viatype) \
    -choice {any gcell cell paint} \
    -help {if set to "any", the code will draw vias using the first\
    method that works: if there is a via gcell installed, that will\
    be used; if there is a via subcell found, that will be used;\
    as a last resort, vias will be painted using rectangles.}]

  lappend prop_list [list "Via gcell name" WIRE(via_gcell_name) -entry \
    -help {Name of gcell to use for vias, and default properties in the\
    form: -propname value.  Only used if "Draw Vias Using"\
    is set to "any" or "gcell".  You can use this to specify default\
    properties for the via, for example, to make vias symmetric by default,\
    set it to: via -symmetric 1.  You can also change this if you\
    have created your own via gcell for use by the wiring tool.}]

  lappend prop_list [list "Flylines follow mouse" WIRE(move_flylines) \
    -binary -help {if set, any flylines attached to the net being\
    wired will follow the end of the wire.  Connectivity is traced\
    only through expanded (currently visible) cells. \
    PERFORMANCE WARNING:  If this option is set, and there are any\
    flylines anywhere in the edit cell, then the wire tool will trace the wire\
    connectivity, using the sel_net function, each time a new wire is started. \
    If the wire is extensive (example: vdd or gnd), and the cells\
    through which the wire is connected are currently expanded\
    (ie, their contents are visible), then the wire tool may be slow.}]

  lappend prop_list [list "Check connectivity" WIRE(check_connectivity) \
    -binary -help {if set, max will check wire connectivity when the\
    wire is finished, and report shorts.  Connectivity is not traced\
    through unexpanded cells.  Only conflicts among labels in the\
    edit cell are reported. \
    PERFORMANCE WARNING:  If this option is set, then the wiring tool\
    will trace the wire connectivity using the sel_net function, which\
    can be slow if the wire is extensive (example: vdd or gnd.)}]

  lappend prop_list [list "Edit Wiring Parameters..." {} -button wire_grid_menu]
  #lappend prop_list [list "Edit Process Parameters..." {} \
  #		-button _wire_edit_process_parameters]

  # If the wire_menu is called while in wire or wire_draw mode,
  # we want to temporarily disable it, then update the screen after.
  set mode [mode_current]
  if { $mode == "wire" || $mode == "wire_draw" } {
    _wire_disable ;# Disable Motion event and pan
  }
  set ret [prop_menu2 -title "Wire Menu" $prop_list]
  if { $ret != 0 } {
    tool_bar_set_layer $layer
  }
  if { $mode == "wire" || $mode == "wire_draw" } {
    _wire_mode_msg
    _wire_enable ;# Enable Motion event and pan

    # Update screen to use any new options.
    _wire_drag
  }
}

# Its not a popup.  Its a prop menu.
proc _wire_width_popup {} {
    global wire_save WIRE TOOL_BAR

    if {[lsearch -exact $WIRE(composite_layers) $TOOL_BAR(layer)] >= 0} {
	set ret [tk_dialog .dialog "Note" \
	    "You are wiring a composite layer consisting of multiple layers.\n\
	    To change the width of this wire you must change the default \n\
	    width of each individual layer in the Wiring Parameters Menu.\n\
	    Select OK to go to the Wiring Parameters Menu now." \
	    "" 0 OK Cancel]
	    if { $ret == 0 } { wire_grid_menu }
	    return
    }

    # Get width of current wire, if any.
    set prop_list ""
    if { $wire_save(list) == "" } {
	# We havent started a wire yet.   If a layer or width was set
	# then we know the width, otherwise use 0.
	if { $TOOL_BAR(layer) != "auto" || $wire_save(start_width) != 0 } {
	    # This width is only if we start wiring on the specified layer.
	    # If the user clicks over an existing wire, it will
	    # start routing in that layer instead.
	    set wire_save(wire_width_tmp) [_wire_get_width $TOOL_BAR(layer)]
	    set layer $TOOL_BAR(layer)
	} else {
	    set wire_save(wire_width_tmp) 0
	    # Its still possible to specify a too-narrow wire width
	    # before we start wiring, because we do not know
	    # what layer, so we cant print a warning!
	    set layer ""
	}
    } else {
	# Get actual width of current segment.
	struct wire_list w [lindex $wire_save(list) end]
	set wire_save(wire_width_tmp) ${w.width}
	set layer ${w.layer}
    }
    # Note: even though we wire on center, the wire width does
    # not need to be disivible by 2*res -mask, because the lh/rh
    # calculation will move the wire off-center by res -mask, if necessary.
    lappend prop_list [list "Enter Wire width:" wire_save(wire_width_tmp) \
    		-number 0 100000 -incr [res -mask] -width 10 -validate]
    
    lappend prop_list \
	[list "Note: zero value means use width set in Wiring Parameters Menu"\
		"" -label]

    lappend prop_list [list "Edit Wiring Parameters..." {} \
	-button wire_grid_menu]

    _wire_disable
    set stat [prop_menu2 -atmouse 0 -title "Enter wire width" $prop_list]
    _wire_enable

    # If user hit cancel.
    if { $stat == 0 } { return }
    # Zero value has no meaning.
    if { $wire_save(wire_width_tmp) == 0 } { return }

    if { $layer != "" } {
      set minwidth [techinfo width $layer "" opt]
      if { [approx $wire_save(wire_width_tmp) < $minwidth] } {
	max_error "warning: entered width ($wire_save(wire_width_tmp)) less than minimum width ($minwidth) from tech file"
	# But its ok: it will use the minwidth from the tech file on
	# this wire.  If a future wire segment has a tech file width
	# small than what was entered, it will be used then.
      }
    }

    # All wires will be this size or larger, from now on.
    set wire_save(start_width) $wire_save(wire_width_tmp)

    if { $wire_save(list) != "" } {
	# Remove current wire and redraw with new width.
	_wire_undraw_segment [expr [llength $wire_save(list)] - 1]
	set w.width [_wire_get_width ${w.layer}]
	set wire_save(list) [lreplace $wire_save(list) end end \
	    [destruct wire_list w]]
	# Update screen.
	_wire_drag
    }

    _wire_mode_msg
}


# Create a little popup menu to let the user add vias, etc.
proc _wire_popup {mode} {
    global WIRE wire_save

    set start_pos [layt_point exact]

    set wire_save(popup_cmd) ""

    set w .wire_popup
    catch {destroy $w}
    menu $w -tearoff false ;#-postcommand "raise $w"
    if { $mode == "wire_draw" } {
	menu_add_widget $w add command -accel d -label "drop via, up" \
	    -command "set wire_save(popup_cmd) {_wire_add_via up}" \
	    -desc "Add via from current layer up to next wiring layer"
	menu_add_widget $w add command -accel Shift-d -label "drop via, down" \
	    -command "set wire_save(popup_cmd) {_wire_add_via down}" \
	    -desc "Add via from current layer down to next wiring layer"
	menu_add_widget $w add command -accel x -label "symmetric via" \
	    -command "set wire_save(popup_cmd) {_wire_change_via symmetry}" \
	    -desc "Make via symmetric/assymetric"
	menu_add_widget $w add command -accel r -label "rotate via" \
	    -command "set wire_save(popup_cmd) {_wire_change_via rotate}" \
	    -desc "Rotate via on current wire segment"
	menu_add_widget $w add command -accel u -label "undo" \
	    -command "set wire_save(popup_cmd) _wire_undo" \
	    -desc "Undo the most recent via or wire segment"
    } else {
	set layer [wire_choose_layer -return]
	if { $layer != "" } {
	    menu_add_widget $w add command -label "choose layer: $layer" \
	      -command "set wire_save(popup_cmd) {tool_bar_set_layer $layer}" \
	      -desc "Set the layer for the wire, otherwise it is picked for you"
	}
    }
    # Do the sub-menu commands NOW.  Dont wait until popup ends.
    menu_add_widget $w add command -accel Shift-s \
	-label "Set current wire size..." \
	-command _wire_width_popup \
	-desc "Set the width to be used for this wire only"

    menu_add_widget $w add command -accel Shift-w -label "Wiring menu..."  \
	-command "wire_menu" \
	-desc "Go to the wiring menu, then return here"
    $w add separator

    if { $mode == "wire_draw" } {
	menu_add_widget $w add checkbutton -accel a -label "anchor vertex" \
	  -variable "wire_save(anchor)"  \
	  -desc "Anchor/unanchor the current wiring segment; lets you move it sideways"
	# We dont want the check button to actually change wire_save(drag_via),
	# so use a temporary variable.
	set wire_save(_tmp_drag_via) $wire_save(drag_via)
	menu_add_widget $w add checkbutton -accel c \
	    -label "drag via" -variable wire_save(_tmp_drag_via) \
	    -command "set wire_save(popup_cmd) _wire_drag_via" \
	    -desc "If set, a dropped via moves with the mouse"
    }

    menu_add_widget $w add checkbutton -accel s \
	-label "snap to wire grid" \
	-variable "WIRE(snap_to_grid)" \
	-desc "If set, wires and vias will snap to the wiring grid set in the Wiring Menu"
    menu_add_widget $w add checkbutton -accel b -label "spacing box" \
      -variable "WIRE(wire_box_display)" \
      -desc "Display a visible box showing the minimum separation for this layer"
    $w add separator

    menu_add_widget $w add radiobutton -accel f -label "Manhattan" \
      -variable "WIRE(snap_to_angle)" -value 90 \
      -desc "Make all wire segments manhattan: horizontal or vertical only"

    menu_add_widget $w add radiobutton -accel f -label "45 angles" \
	-variable "WIRE(snap_to_angle)" -value 45 \
	-desc "Allow 45 degree wire segments - still disallows acute angles"
    menu_add_widget $w add radiobutton -label "All angles" \
	-variable "WIRE(snap_to_angle)" -value 0 \
	-desc "Allow wire segments at any angle"

    # There is a wierd interaction here.  After the popup is unmapped,
    # the binding on Mouse Motion can be invoked (possibly many times)
    # before we get around to warping the cursor.
    # This showed up especially when one invoked the "Set wire width",
    # which calls prop_menu, then if you use the mouse to hit Done
    # on that prop_menu, the mouse is far from where it started,
    # and if you quickly drag the mouse back to where
    # it was, the events are processed in the wrong order.
    # So now I disable the Motion event using _wire_disable.
    _wire_disable ;# Disable Motion event and pan

    # This variable will change when the popup is unposted or destroyed.
    set wire_save(wire_popup_notify_tmp) 0
    bind $w <Unmap> {set wire_save(wire_popup_notify_tmp) 1}
    bind $w <Destroy> {set wire_save(wire_popup_notify_tmp) 1}
    tk_popup $w [winfo pointerx .] [winfo pointery .]
    # Wait for popup to go away.
    # Usually tkwait is wrapped by calls to cursor_wait, but in this case
    # the popup is only up as long as the user holds down Button-3,
    # so dont bother changing the cursor.
    tkwait variable wire_save(wire_popup_notify_tmp)
    # Return the cursor to where it was before popup menu was posted.
    eval layt_point -warp exact $start_pos
    _wire_enable ;# Re-enable Motion event and pan

    # Do any command specified by popup.  Some commands need to wait
    # to now to avoid interactions between popup and any command.
    if { $wire_save(popup_cmd) != "" } {
        eval $wire_save(popup_cmd)
    }
    unset wire_save(popup_cmd)
}

#proc via_rule {rule layer1 {layer2 ""}} {
#    switch -- $rule {
#    "up" {
#	# This will return two or more layers.
#	# Last layer is the "up" layer.
#	# Others are possible "down" layer candidates.
#	set layers [drc_get "connect" $layer1]
#	return [lindex $layers [expr [llength $layers] - 1]]
#    }
#    "down" {
#	set layers [drc_get "connect" $layer1]
#	return [lrange $layers 0 [expr [llength $layers] - 2]]
#    }
#    default {
#	max_error "wire error: unrecognized drc rule request: $rule $layer1 $layer2"
#	return ""
#    }
#    }
#}

proc wire_get_rc {{-width 0} layer} -desc {
  Return wire resistance and cap in ohm/micron and fF/micron.
} -doc {
  If no width specified, use width from wiring table,
  which defaults to minimum width wire.
} {
  global WIRE
  _wire_init

  set rpersq [use_first WIRE($layer,rpersq)]
  set cpersq [use_first WIRE($layer,cpersq)]
  set cedge [use_first WIRE($layer,cedge)]

  if {$rpersq == ""} {
    max_error -buffer "error: No RESISTANCE RPERSQ values loaded for wire layer $layer, using 0 - maybe LEF file not read in?"
    set rpersq 0
  }
  if {$cpersq == ""} {
    max_error -buffer "error: No CAPACITANCE CPERSQ values loaded for wire layer $layer, using 0 - maybe LEF file not read in?"
    set cpersq 0
  }
  if {$cedge == ""} {
    max_error -buffer "error: No CAPACITANCE EDGE values loaded for wire layer $layer, using 0 - maybe LEF file not read in?"
    set cedge 0
  }

  if {$width == 0} {
    # Get default wire width.
    set width [use_first WIRE($layer,width)]
    if {$width == ""} {
      max_error -buffer "error: no wire width known for layer $layer"
      return "0 0"
    }
  }

  # Resistance in ohms/u.
  set Rw [expr $rpersq / $width]
  # Cap comes in pF/micron.  Convert to fF.
  set Cw [expr 1e3 * ($cpersq * $width + 2 * $cedge)]

  # Round numbers to 3 sig digits.
  set Rw [expr 1.0 * [format "%.4g" $Rw]]
  set Cw [expr 1.0 * [format "%.4g" $Cw]]

  return [list $Rw $Cw]
}
