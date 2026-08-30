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

set RCSVERSION(label.tcl) { $Revision: 1.43 $ }

#TODO: strip <> from values when editing in T menu

use_init TIMING_DATA(clk_names) clk

init_global LABEL(default_size) -default point -desc {
  determines the default type of label.
} -doc {
  either point or box
} -flags internal

init_global LABEL(default_pos) -default CENTER -desc {
  Determines the default label position in the label popup menu.
} -doc {
  The label position means the orientation of label text relative to label
  location.
  May be NORTH, SOUTH, EAST, WEST, CENTER,
  NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST
}

init_global LABEL(default_kind) -default local -desc {
  Determines the default kind of label in the label popup menu.
} -doc {
    May be local, global, input, output, or any other recognized
    port type from the label popup menu.
}


# This is called from the main menu.
proc label_add {} -desc {
    Create new label
} {
    global LABEL 

    # set initial parms
    # Use exact box size in case label is around something that came from gds?
    set LABEL(rect) [layt_box exact]
    if { $LABEL(rect) == "" } {
	set LABEL(rect) [lay_bbox]
    }
    set LABEL(pos) [use_first LABEL(default_pos) 'CENTER]
    set LABEL(size) [use_first LABEL(default_size) 'point]

    # pick initial layer
    # Try to pick a selected paint layer under the box.
    set LABEL(layer) ""
    setl {x y} [eval center_coords $LABEL(rect)]
    set paintballs [sel_what paint -edit_only foobar]
    foreach paint [split [string trim $paintballs \n] \n] {
	struct max_paint p $paint
	if { [dbt_is_visible ${p.layer}] &&
		[inside_rect $x $y ${p.x1} ${p.y1} ${p.x2} ${p.y2}] } {
	    set LABEL(layer) ${p.layer}
	}
    }

    if { $LABEL(layer) == "" } {
	# Choose last (highest) layer.
	set layers [dbt_touchingtypes $x $y selectable]
	if { $layers != "" } {
	    set LABEL(layer) [lindex $layers end]
	} else {
	    set LABEL(layer) "space"
	}
    }

    set save_focus [focus]
    set LABEL(text) ""
    focus -force $save_focus

    set LABEL(kind) [use_first LABEL(default_kind) 'local]

    #nil kind signals no old value
    set LABEL(kind,old) ""

    # create initial label
    _label_update
   
    mode_push label
}

proc label_edit {label} -desc {
    change label (called by edit_label)
} {
    global LABEL

    # parse arg
    setl {layer x1 y1 x2 y2 pos text path group_unused kind} $label

    set edit_path [lindex [lay_path] 1]
    if {$edit_path == "."} {
      set edit_path ""
    }

    if {$edit_path != $path} {
      max_error "Aborting, can't edit label that is not edit cell.  This label is in $path."
      return
    }

    # initialize parms
    set LABEL(layer) $layer
    set LABEL(rect) "$x1 $y1 $x2 $y2" 
    if {$x1 == $x2 && $y1 == $y2} {
      set LABEL(size) point
    } else {
      set LABEL(size) box
    }

    set LABEL(pos) $pos
    set LABEL(text) $text
    set LABEL(kind) $kind

    # nil kind signals no old value
    set LABEL(kind,old) ""

    # do initial update to stash initial values
    _label_update edit

    mode_push label
}

proc edit_label {} -desc {
    edit selected label
} {

    # 8/22/01: Switch to new code if floorplanner is being used.
    # Eventually, we will use this code for all labels, but not for this release.
    global FPLAN
    if {[use_first FPLAN(exists) '0] == 1} {
      set labels [sel_what_l labels]
      if {[llength $labels] == 0} {
	label_lbox
      } else {
	label_edit_new -type basic $labels
      }
      return
    }

    # get selected label.  If more than one label is selected,pick
    # the first one
    set label [label_first_non_hidden_selected]
    if {$label == ""} {
	warning "no labels selected to edit"
	# If you keep going will get error message, so dont bother.
	return
    }
    label_edit $label
}

proc label_mode_define {} -desc {
  label creation/change mode
} {
  mode_def label _label_gate_keeper "BUT-1 repositions label, RETURN ends, CTRL-C aborts, BUT-2/3 over palette changes layer"

    mode_bind -cmd 0 label -desc "drag out a position for label" \
	    <Button-1> \
	    {mode_push label_drag}
    mode_bind -cmd 0 label -desc "done" \
	    <Return> \
	    { _label_update; mode_pop }
}

proc _label_gate_keeper {event} -desc {
    called whenever mode is entered/exited
} {
    global LABEL PAL

    if {$event == "PUSH_TO"} {

        # define button2 and button3 command on palette
        set PAL(button2) "_label_choose_layer label"
        set PAL(button3) "_label_choose_layer label"

	# popup label edit box
	_label_edit_box

    } elseif {$event == "POP_FROM"} {
	global mode_abort

	catch {unset PAL(button2)}
	catch {unset PAL(button3)}

	if { $mode_abort } {
	    undo_to_delim
	    undo_flush_redo
	    msg "aborting label change\n"
	}

	# close label edit box
	_label_edit_box_close

	# invalidate "old" data
	set LABEL(kind,old) ""
	i_cmd_between
    }
}

proc _label_update {{mode ""}} {
    global LABEL

    # handle null text case
    set text $LABEL(text)
    if { $text == "" } {
	set text "?"
    }

    # if label text is invalid, give sensible message and abort update
    if { $mode != "edit" && [string first " " text] != -1 } {
	warning "Bad label text:  contains ' '\n"
	return
    }

    if { $mode != "edit" && [string first "/" $text] != -1 } {
	warning "Bad label text:  contains '/'\n"
	return
    }

    # delete old label

    if { $LABEL(kind,old) != "" } {
	setl {x1 y1 x2 y2} $LABEL(rect,old)

	# handle null text case
	set oldText $LABEL(text,old)
	if { $oldText == "" } {
	    set oldText "?"
	}

	sel_labels -kind $LABEL(kind,old) \
		-rect $x1 $y1 $x2 $y2 \
		-text $oldText \
		-pos $LABEL(pos,old) \
		-layer $LABEL(layer,old)
	:delete
    }

    # If point label, collapse label rect to center of box.
    if {$LABEL(size) == "point"} {
      set LABEL(draw,rect) [center_bbox $LABEL(rect)]
    } else {
      set LABEL(draw,rect) $LABEL(rect)
    }

    # put down new label
    eval layt_box exact $LABEL(draw,rect)
    setl {bx1 by1 bx2 by2} $LABEL(draw,rect)

    set cmd [list db_label -kind $LABEL(kind) -pos $LABEL(pos) $LABEL(layer) \
	$text $bx1 $by1 $bx2 $by2]

    set ret_code [msg_catch $cmd ret info warn]
    
    # if db_label didn't complete normally, post message and backout of change
    if {$ret_code != 0} {

	# restore old label
	if { $LABEL(kind,old) != "" } {
	    set LABEL(kind) $LABEL(kind,old)
	    set LABEL(rect)  $LABEL(rect,old) 
	    set LABEL(text) $LABEL(text,old)
	    set LABEL(pos) $LABEL(pos,old)
	    set LABEL(layer) $LABEL(layer,old)
	    set text $LABEL(text)
	    if { $text == "" } {
		set text "?"
	    }
	    setl {bx1 by1 bx2 by2} $LABEL(rect)
	    db_label -kind $LABEL(kind) -pos $LABEL(pos) $LABEL(layer) \
		$text $bx1 $by1 $bx2 $by2
	}

	warning "$ret\n$warn\n$info\n"
    }

    # get actual label layer
    set text $LABEL(text)
    if { $text == "" } {
	set text "?"
    }
    catch "sel_labels -kind $LABEL(kind) \
	    -rect $LABEL(draw,rect) \
	    -text [list $text] \
	    -pos $LABEL(pos)"
    set LABEL(layer) [lindex [sel_what labels] 0]

    # squirrel away settings
    set LABEL(kind,old) $LABEL(kind)
    set LABEL(rect,old)  $LABEL(draw,rect) 
    set LABEL(text,old) $LABEL(text)
    set LABEL(pos,old) $LABEL(pos)
    set LABEL(layer,old) $LABEL(layer)
}
	
proc label_drag_mode_define {} -desc {
  label creation/change mode
} {
    mode_def label_drag _label_drag_gate_keeper {}

    mode_bind -cmd 0 label_drag <Any-B1-Motion> _label_drag
    mode_bind -cmd 0 label_drag <Any-B1-ButtonRelease> "_label_drag; mode_pop"
}

proc _label_drag_gate_keeper {event} -desc {
    called whenever mode is entered/exited
} {
    global LABEL

    if {$event == "PUSH_TO"} {
	pan_enable

	setl {LABEL(x) LABEL(y)} [layt_point user]
    } elseif {$event == "POP_FROM"} {
	pan_disable

	set LABEL(rect) [layt_box exact]
	_label_update
    }
}

proc _label_drag {} {

  global LABEL

  pan_auto _label_drag

  setl {x2 y2} [layt_point user]
  if {$x2 == "" || $y2 == ""} {
    # off screen
    return
  }
  layt_box user $LABEL(x) $LABEL(y) $x2 $y2
}

proc _label_edit_box_close {} {
  global LABEL
  if {[info commands XFDestroy] != ""} {
    catch {XFDestroy .label_box}
  } {
    catch {destroy .label_box}
  }
  catch {focus -force $LABEL(oldFocus)}
  set LABEL(oldFocus) ""
}


proc _label_edit_box {} -desc {
    Popup label edit box 
} {
  global LABEL max_win
  global DIALOG_FONT SMALL_FONT

  global tab_list
  set tab_list ""

  # make sure no label edit window left around
  _label_edit_box_close
  	
  ### BUILD WIDGET

  # TOPLEVEL
  set w .label_box
  set wx [expr [winfo rootx $max_win] + 75]
  set wy [expr [winfo rooty $max_win] + 50]

  toplevel $w -borderwidth 0

  wm geometry $w "+$wx+$wy"
  wm title $w "max edit text"
    bind $w <Return> { _label_update; mode_pop }
  bind $w <Any-Control-c> mode_abort 

  # POS/KIND frame
  set pkf [frame .label_box.pkf]
  pack $pkf -side top -fill x -expand yes

  # KIND
  set w [frame $pkf.kindf -bd 1 -relief groove]
  pack $w -side left -fill y -expand yes -padx 1

  # Cut into top and bottom parts.
  frame $w.top -bd 0 -relief flat
  frame $w.bot -bd 0 -relief flat
  pack $w.top $w.bot -side top -padx 0 -pady 0

  label $w.top.label -text "kind:" -fg blue
  pack $w.top.label -side top -padx 0 -pady 0 -ipady 0

  set c [frame $w.bot.c1]
  pack $c -side left
  foreach kind { {" " local} {! global} {# comment}} {
      setl {symbol name} $kind 
      set b [radiobutton $c.$name\
	      -font $SMALL_FONT \
	      -text "$symbol $name"\
	      -variable LABEL(kind)\
              -value $name\
              -relief raised \
	      -anchor w \
	      -takefocus 0 \
	      -command _label_update]
      pack $b -side top -fill x
  }

  set c [frame $w.bot.c2]
  pack $c -side left
  foreach kind { {< input} {> output} {<> inout} } {
      setl {symbol name} $kind 
      set b [radiobutton $c.$name\
	      -font $SMALL_FONT \
	      -text "$symbol $name"\
	      -variable LABEL(kind)\
              -value $name\
              -relief raised \
	      -anchor w \
	      -takefocus 0 \
	      -command _label_update]
      pack $b -side top -fill x
  }

  # POSITION 
  set w [frame $pkf.posf -bd 1 -relief groove]
  pack $w -side left -fill y -expand yes -padx 1

  # Cut into top and bottom parts.
  frame $w.top -bd 0 -relief flat
  frame $w.bot -bd 0 -relief flat
  pack $w.top $w.bot -side top -padx 0 -pady 0

  label $w.top.label -text "position:" -fg blue
  pack $w.top.label -side top -padx 0 -pady 0 -ipady 0

  set rose [frame $w.bot.rose]
  pack $rose -side left -fill x 

  set c1 [frame $rose.c1]
  foreach pos {{nw NORTHWEST} {w WEST} {sw SOUTHWEST}} {
      set b [radiobutton $c1.[lindex $pos 0] \
	      -text [lindex $pos 0] \
	      -variable LABEL(pos)\
              -value [lindex $pos 1] \
	      -font $SMALL_FONT \
	      -relief raised\
	      -anchor w \
	      -takefocus 0 \
	      -command _label_update]
      pack $b -side top -fill x
  }
  pack $c1 -side left

  set c2 [frame $rose.c2]
  foreach pos {{n NORTH} {c CENTER} {s SOUTH}} {
      set b [radiobutton $c2.[lindex $pos 0] \
	      -text [lindex $pos 0]\
	      -variable LABEL(pos)\
              -value [lindex $pos 1]\
	      -font $SMALL_FONT \
	      -relief raised\
	      -anchor w \
	      -takefocus 0 \
	      -command _label_update]
      pack $b -side top -fill x
  }	
  pack $c2 -side left

  set c3 [frame $rose.c3]
  foreach pos {{ne NORTHEAST} {e EAST} {se SOUTHEAST}} {
      set b [radiobutton $c3.[lindex $pos 0] \
	      -text [lindex $pos 0]\
	      -variable LABEL(pos)\
              -value [lindex $pos 1]\
	      -font $SMALL_FONT \
	      -relief raised\
	      -anchor w \
	      -takefocus 0 \
	      -command _label_update]
      pack $b -side top -fill x
  }	
  pack $c3 -side left
  pack $w	
  

  # frame for making labels points only or entire boxes
  set w [frame $pkf.size -bd 1 -relief groove]
  pack $w -side left -fill x -anchor n -expand 1 -padx 1

  # Cut into top and bottom parts.
  frame $w.top -bd 0 -relief flat
  frame $w.bot -bd 0 -relief flat
  pack $w.top $w.bot -side top -padx 0 -pady 0

  label $w.top.label -text "type:" -fg blue
  pack $w.top.label -side top -padx 0 -pady 0 -ipady 0

  set rose [frame $w.bot.rose]
  pack $rose -side left -fill x 
  	
  set c1 [frame $rose.c1]
  foreach pos {point box}	{
      set b [radiobutton $c1.$pos\
	      -text $pos\
	      -variable LABEL(size)\
              -value $pos\
	      -font $SMALL_FONT \
	      -relief raised\
	      -anchor w \
	      -takefocus 0 \
	      -command _label_update]
      pack $b -side top -fill x
  }
  pack $c1 -side left


  # SPACER
  frame .label_box.spacer -bd 2 -relief flat
  pack .label_box.spacer -side top


  # TEXT
  set w [frame .label_box.textf -bd 3 -relief flat]
  pack $w -side top -fill x -expand yes

  label $w.label -font $DIALOG_FONT -text "text:    " -fg blue	
  pack $w.label -side left

  set entry [entry $w.entry -textvariable LABEL(text)\
	  -font $DIALOG_FONT -relief sunken\
	  -bd 1\
	  -highlightthickness 1]
  pack  $entry -side left -fill x -expand yes
  set LABEL(oldFocus) [focus]
  focus $entry  ;# Note: this returns nothing!   Thus statement above.
  lappend tab_list $entry

  bind $entry <Tab> "_label_update; tab_through_entries \$tab_list"
  bind $entry <Control-n> "_label_update; tab_through_entries \$tab_list"
  bind $entry <Control-p> "_label_update; tab_through_entries \$tab_list backword"

  # LAYER
  set w [frame .label_box.layerf -bd 2 -relief flat]
  pack $w -side top -fill x -expand yes

  label $w.label -font $DIALOG_FONT -text "layer:  " -fg blue	
  pack $w.label -side left

  set entry [entry $w.entry -textvariable LABEL(layer)\
	  -font $DIALOG_FONT -relief sunken\
	  -bd 1\
	  -highlightthickness 1]
  pack $entry -side left -fill x -expand yes
  lappend tab_list $entry

  bind $entry <Tab> "tab_through_entries \$tab_list"
  bind $entry <Control-n> "tab_through_entries \$tab_list"
  bind $entry <Control-p> "tab_through_entries \$tab_list backword"

  set f [frame .label_box.endf -bd 1 -relief flat]
  pack $f -side top -fill x -expand yes -padx 4m

  set w $f.done
  button $w -font $DIALOG_FONT -default active \
	-text "Done" -command "_label_update;mode_pop"
  pack $w -padx 1m -pady 1 -side left -fill x -expand 1

  # CANCEL BUTTON
  set w $f.cancel
  button $w -font $DIALOG_FONT -default normal -text "Cancel" -command mode_abort
  pack $w -padx 1m -pady 1 -side left -fill x -expand 1

  # HELP BUTTON
set helpmsg {This menu causes a textual label to be placed\
at the current box location. \
You can reposition the box by pointing with the mouse in the main max window. \
When you are finished, choose "Done". \

Kind:  The kind specifies the connectivity of the net to which\
the label is attached.  This information is typically used during\
various types of extraction.  A "local" textual label provides\
a name for the attached net, and indicates\
that the attached net is local to the current cell.  A "global" textual\
label indicates that the attached net is a global connection,\
for example, "Vdd" or "Gnd".   An "input", "output" or "inout" textual label\
indicates that the attached net is a port. \
Ports are important to various extractors, for example, to mark\
nets that must be connected by routing in the parent cell. \
The "comment" textual label is just a comment, and does not\
affect the connectivity of the attached net, if any.\

Position: Specifies the visual positioning of the text relative\
the the point location.  If "c", the text is centered over the point location. \
The other types cause the text to appear on the specified side\
(northwest, north, northeast, west, east, southwest, south, southeast)\
of the point position.\

Type:  A "point" text is a single point, and is the most common type. \
A "box" text is a rectangle, and is used in some applications\
to indicate bounding boxes.\

Text: The actual text of the textual label.\

Layer: If the layer is "space", it means the text is not attached\
to any layer.  If a layer is specified, and the text is\
physically positioned over geometry on that layer, then the text\
affects the connectivity of that layer, depending on the label "Kind".\

It is important to note that the text does not specify\
connectivity for a net unless it is physically positioned over mask geometry\
on the layer specified by "Layer:".  Typically, no warning is produced\
for textual labels whose specified "Layer" does not actually match\
any of the layers that are under the text.
}
  set w $f.help
  button $w -font $DIALOG_FONT -default normal -text "Help" \
      -command "prop_dialog -title {Text Edit Help} {$helpmsg}"
  pack $w -padx 1m -pady 1 -side left -fill x -expand 1
}

proc label_first_non_hidden_selected {} -desc {
    parse result of 'sel_what labels' for first label that isn't hidden
} {
    set ret ""
    foreach label [sel_what_l labels] {
	set kind [lindex $label 9] 
	if {$kind != "hidden"} {
	    if { $ret == "" } {
	      set ret $label
	    } else {
	      msg "Warning: Multiple labels selected\n"
	      break
	    }
	}
    }
    return $ret
}


proc _label_choose_layer {layer} -desc {
  change the label from the palette
} {
  global LABEL

  set LABEL(layer) $layer
  _label_update
}


proc select_net_by_name {{-glob} {-hier none} {-no_wires} {-no_vias} {-more} name} -desc {
  Select nets connected to named label.
} -doc {
  return [list found_labels unconnected_labels]
  where found_labels are the names of labels that matched name, or ""
  if the label was not found, and unconnected_labels is a list of
  labels that matched the name but that were not attached to any wire.

  if -no_wires, do not select the wires, just the labels.
  if -no_vias, do not select attached vias.
  -hier is as documented in db_search_l.
} {
    set options ""
    if {! $glob} {lappend options -exact}
    lappend options -hier $hier
    set labels [eval db_search_l labels $options [list $name]]
  
    if {! $more} {
      sel_clear
    }

    if {[llength $labels] == 0} {
      return ""
    }

    set res [res]

    set unconnected_labels ""
    set found_labels ""
    catch {db_cell_delete __TMP_CELL__}
    catch {db_cell_new -no_undo -internal __TMP_CELL__}
    foreach label_info $labels {
      struct max_label l $label_info
      # Select the label, in case it is not on a net, we want to
      # show it and zoom to it anyway.
      # Since sel_labels is non-hierarchical, dont use it.
      # Put the label in the tmp cell, then later copy the tmp cell to the selection.

      db_label -cell __TMP_CELL__ -kind ${l.kind} -pos ${l.pos} ${l.layer} ${l.text} \
      	   ${l.x1} ${l.y1} ${l.x2} ${l.y2}

      #OLD:
      #if {${l.path} == ""} {
      #	sel_labels -more -kind ${l.kind} -layer ${l.layer} -pos ${l.pos} \
      #	   -rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -text ${l.text}
      #}

      set x ${l.x1}
      set y ${l.y1}

      set layers [db_search touchingtypes [expr $x + $res] [expr $y + $res]]
      if {[lsearch $layers ${l.layer}] == -1} {
	# maybe on right/upper edge of paint tile.  Move back and try again.
	set x [expr ${l.x1} - $res]
	set y [expr ${l.y1} - $res]
	set layers [db_search touchingtypes $x $y]
      }

      if {[lsearch $layers ${l.layer}] == -1} {
	# Include label location in error message.
	lappend unconnected_labels $label_info
      } else {
	lappend found_labels $label_info
	if {! $no_wires } {
	  sel_net -more -point $x $y ${l.layer}
	}
      }
    }

    sel_buffer __TMP_CELL__


    if {! $no_vias } {
      sel_vias
    }

    return [list $found_labels $unconnected_labels]
}


proc sel_net_by_name {{name ""} {options ""}} -desc {
  NO LONGER USED. popup select net by name menu, then select all nets connected to a given label name
} {

  global SEL_NET_BY_NAME
  # By making global, they are persistent each time menu is used.
  use_init SEL_NET_BY_NAME(name) ""
  use_init SEL_NET_BY_NAME(zoom) 0
  use_init SEL_NET_BY_NAME(glob) 0
  use_init SEL_NET_BY_NAME(more) 0
  use_init SEL_NET_BY_NAME(lab_only) 0
  use_init SEL_NET_BY_NAME(hier) none

  if {$name == ""} {

    # prompt user for name of label
    set title "Select by name"
    set message "Enter net name:" 
    set prop_list ""
    lappend prop_list [list {Net name} SEL_NET_BY_NAME(name) \
      -entry -help {Nets with attached text with this name are selected.}]
    lappend prop_list [list {Zoom In} SEL_NET_BY_NAME(zoom) \
      -binary -help {Adjusts/zooms view to center selected net}]
    lappend prop_list [list {Add to Existing Selection } SEL_NET_BY_NAME(more) \
	-binary]
    lappend prop_list [list {Pattern match name} SEL_NET_BY_NAME(glob) -binary \
      -help {Pattern matching uses characters:
      ?     match any character;
      *     match zero or more characters;
      \c    match character c
      [abc] match any one of the characters in brackets;
      [a-z] match range of characters;
      }]
    lappend prop_list [list {Select only text, not attached nets} \
	SEL_NET_BY_NAME(lab_only) -binary \
	-help {If set, only the text labels themselves are selected,\
	not the nets they are over.  Hint: to search for unattached text,\
	set the text name to "<various>", and click on "Pattern match name" and \
	"Select only text".  A warning will be printed listing all unattached\
	labels in the cell.}]

    lappend prop_list [list {Search:} SEL_NET_BY_NAME(hier) \
      -radio {current_cell any_visible_cell any_loaded_cell} \
      -values {none vis all}]

    # popup window
    set ret [prop_menu2 -message $message -title $title $prop_list]

    if {$ret == 0} {
	# user hit cancel
	return ""
    }
    set name $SEL_NET_BY_NAME(name)
    set f_zoom $SEL_NET_BY_NAME(zoom)
    set f_more $SEL_NET_BY_NAME(more)
    set f_lab_only $SEL_NET_BY_NAME(lab_only)
    set f_interactive 1
  } else {
    set f_zoom [expr ! [memq $options no_zoom]]
    set f_more [memq $options more]
    set f_lab_only 0
    set f_interactive 0
  }

  set f_quiet [memq $options quiet]

  if {$name == ""} {
    # no name given
    return
  }

  if {0} { ;# 5/24/01, pat: rewrote code to use select_net_by_name.

    if { $SEL_NET_BY_NAME(glob) } {
      set labels [db_search_l labels -any_cell $name]
    } else {
      set labels [db_search_l labels -any_cell -exact $name]
    }


    if {! $f_more} {
      sel_clear
    }

    if {[llength $labels] == 0} {
      if {! $f_quiet} {
	mode_tmp_msg "No matching labels found"
      }
      return
    }

    set res [res]

    set unconnected_labels ""
    foreach label_info $labels {
      struct max_label l $label_info
      # Select the label, in case it is not on a net, we want to
      # show it and zoom to it anyway.
      sel_labels -more -kind ${l.kind} -layer ${l.layer} -pos ${l.pos} \
	-rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -text ${l.text}

      set x ${l.x1}
      set y ${l.y1}

      set layers [db_search touchingtypes [expr $x + [res]] [expr $y + [res]]]
      if {[lsearch $layers ${l.layer}] != -1} {
	# not on right/upper edge
	if {! $f_lab_only } {
	  sel_net -more -point $x $y ${l.layer}
	}
      } else {
	# on right/upper edge of paint tile.  move back
	set x [expr ${l.x1} - $res]
	set y [expr ${l.y1} - $res]
	set layers [db_search touchingtypes $x $y]
	if { $layers == "" } {
	  lappend unconnected_labels ${l.text}
	}
	if {! $f_lab_only } {
	  sel_net -more -point $x $y ${l.layer}
	}
      }
    }

    if {! $f_lab_only } {
      sel_vias
    }
  }

  # Build up select_net_by_name command.
  set cmd "select_net_by_name"
  if {$SEL_NET_BY_NAME(glob)} { lappend cmd "-glob" }
  if {$SEL_NET_BY_NAME(more)} { lappend cmd "-more" }
  if {$SEL_NET_BY_NAME(lab_only)} { lappend cmd -no_wires -no_vias }
  lappend cmd -hier $SEL_NET_BY_NAME(hier)
  lappend cmd $name

  setl {found_labels unconnected_labels} [eval $cmd]

  if {! $f_quiet && [llength $found_labels] == 0} {
    mode_tmp_msg "No matching labels found"
  }

  if { $f_zoom } {
    zoom_to_selected
  }

  # show the net to the user now just in case this next part takes a while
  update idletasks


  # tell user what labels are on this net
  if {! $f_quiet} {
    if {$unconnected_labels != ""} {
      set errmsg ""
      foreach lab_info $unconnected_labels {
	struct max_label l $lab_info
	# Include label position in error message.
	lappend errmsg  "${l.text} (${l.x1},${l.y1})"
      }
      if { $f_interactive } {
	warning "Unconnected labels: $errmsg"
	# TODO: fix this globally, instead of requiring this update here!
	# This update is needed for a wierd reason.
	# When the warning message ends, the cursor parachutes
	# into the max window, generates an <Enter> event,
	# and causes the mode_tmp_msg to disappear.
	# The mode_tmp_msg is actually posted below, but the
	# <Enter> event doesnt happen until update, which
	# normally would not occur until idle, so we do it now,
	# and mode_tmp_msg below stays put.
      } else {
	msg "warning Unconnected labels: $errmsg\n"
      }
    }
    display_selected_labels
  }
}


proc change_labels {} -desc {
  Change selected labels all at once.
} {
  global PROP_SAVE

  set labels [split [sel_what labels] \n]
  if {[llength $labels] == 0} {
    warning "no labels selected, will show you the next menu anyway"
    # We will continue anyway, so user can see the menu,
    # which is good for demos, at least.
  }

  set box [layt_box exact]

  if {![info exists PROP_SAVE(name,name_prefix)]} {
    # set up defaults
    set PROP_SAVE(name,change_name) 0
    set PROP_SAVE(name,name_prefix) ""
    set PROP_SAVE(name,name_suffix) ""
    set PROP_SAVE(name,dir) n
    set PROP_SAVE(name,first) 0
    set PROP_SAVE(name,increment) 1

    set PROP_SAVE(name,change_kind) 0
    set PROP_SAVE(name,kind) global

    set PROP_SAVE(name,change_layer) 0
    # Prefer a wiring layer.
    set PROP_SAVE(name,layer) [wire_default_layer]
    if { $PROP_SAVE(name,layer) == "" } {
	# Pick any selectable layer.
	set PROP_SAVE(name,layer) [dbt_short_name [lindex [dbt_selectable_layers] 0]]
    }
    if { $PROP_SAVE(name,layer) == "" } {
	# Pick any visible layer.
	set PROP_SAVE(name,layer) [dbt_short_name [lindex [dbt_visible_layers] 0]]
    }

    set PROP_SAVE(name,change_pos) 0
    set PROP_SAVE(name,pos) "c"
  }
  global MAX_DEVELOPER
  if { $MAX_DEVELOPER } {
    set label_choices {input output inout global local comment hidden}
  } else {
    set label_choices {input output inout global local comment}
  }

  set title "Change Selected Text"
  set message "Enter New Text Information:" 
  set help "This prop_menu lets you change the currently selected text (labels.) \
      You can optionally change the text kind, layer, text position, or\
      rename the text to: <prefix><number><suffix>\n"
  set prop_list [list \
      [list "" "" \
	-help $help] \
      [list "Change Text Names?" PROP_SAVE(name,change_name) -binary \
	-help {If set, the text will be renamed} ] \
      [list new_name_prefix PROP_SAVE(name,name_prefix) -entry \
	-help {the prefix to be used for new text names}] \
      [list new_name_suffix PROP_SAVE(name,name_suffix) -entry \
	-help {the suffix to be used for new text names}] \
      [list numbered_in_direction PROP_SAVE(name,dir) -choice {n s e w} \
	-help {the text names are numbered in order in this direction} ] \
      [list first_number PROP_SAVE(name,first) -number \
	-help {the number given to the first text name} ] \
      [list increment PROP_SAVE(name,increment) -number 1 \
	-help {number is incremented by this amount for each new text name} ] \
      [list "" "" -separator] \
      [list "Change Text Kind?" PROP_SAVE(name,change_kind) -binary \
	-help {If set, the text kind will be changed} ] \
      [list new_kind PROP_SAVE(name,kind) \
	-choice $label_choices \
	-help {optional new text kind}] \
      [list "" "" -separator] \
      [list "Change Text Layer?" PROP_SAVE(name,change_layer) -binary \
	-help {If set, the layer type will be changed} ] \
      [list new_layer PROP_SAVE(name,layer) -popup [pal_layers] \
	-help {optional new layer}] \
      [list "" "" -separator] \
      [list "Change Text Position?" PROP_SAVE(name,change_pos) -binary \
	-help {If set, the layer text position will be changed} ] \
      [list new_position PROP_SAVE(name,pos) \
	-choice {n s e w nw ne sw se c} \
	-help {optional new text position}] \
      ]


  while {1} {
    # create the menu
    set ret [prop_menu2 -message $message -title $title $prop_list]
    if { $ret == 0 } {
      # the user hit cancel
      return
    }

    set name $PROP_SAVE(name,name_prefix)
    set suffix $PROP_SAVE(name,name_suffix)
    set count $PROP_SAVE(name,first)
    set dir $PROP_SAVE(name,dir)

    if { $PROP_SAVE(name,change_name) && $name == "" && $suffix == ""} {
      max_error "label error: you must provide a name prefix or suffix."
      continue
    }
    break
  }

  # sort labels by the direction to be named
  if {$dir == "n" || $dir == "e"} {
    set switch "-increasing"
  } elseif {$dir == "s" || $dir == "w"} {
    set switch "-decreasing"
  }

  if {$dir == "n" || $dir == "s"} {
    set PROP_SAVE(tmp) y
  } elseif {$dir == "e" || $dir == "w"} {
    set PROP_SAVE(tmp) x
  }

  set labels [lsort -command _name_labels_compare $switch $labels]

  # name'm
  set select ""

  foreach label $labels {
    setl {layer x1 y1 x2 y2 pos text path_unused group_unused _kind} $label

    # toast this one
    sel_labels -kind $_kind \
	-rect $x1 $y1 $x2 $y2 \
	-text $text \
	-pos $pos \
	-layer $layer
    :delete

    # change label name if requested
    if { $PROP_SAVE(name,change_name) } {
      set text "$name$count$suffix"
    }

    # change label kind if requested
    if { $PROP_SAVE(name,change_kind) } {
      set _kind $PROP_SAVE(name,kind)
    }

    # change label layer if requested
    if { $PROP_SAVE(name,change_layer) } {
      set layer $PROP_SAVE(name,layer)
    }

    # change label pos if requested
    if { $PROP_SAVE(name,change_pos) } {
      set pos $PROP_SAVE(name,pos)
    }

    # add back
    layt_box exact $x1 $y1 $x2 $y2
    if {[msg_catch [list db_label -kind $_kind -pos $pos $layer \
	$text $x1 $y1 $x2 $y2] msg1 msg2]} {
      # Shoot.  Probably metal layer invalid.
      # Undo what we have done.
      undo_to_delim
      # restore original box
      eval layt_box exact $box
      max_error "label error: $msg1 $msg2"
      return
    }

    # remember labels to select at end
    lappend select [list sel_labels -more -kind $_kind -rect $x1 $y1 $x2 $y2 \
			-text $text -pos $pos -layer $layer]

    incr count $PROP_SAVE(name,increment)
  }

  # select all modified labels
  sel_clear
  foreach label $select {
    eval $label
  }
  # And restore original box
  eval layt_box exact $box

  puts "Modified [llength $labels] label instances."
}


proc _label_multiple_rename {} {
  global PROP_SAVE

  set box [lay_box]

  set labels [sel_what_l labels]
  if {[llength $labels] == 0} {
    msg "rename multiple labels: No labels selected; aborting.\n"
    return
  }

  if {![info exists PROP_SAVE(name,name_prefix)]} {
    # set up defaults
    set PROP_SAVE(name,change_name) 1
    set PROP_SAVE(name,name_prefix) ""
    set PROP_SAVE(name,name_suffix) ""
    set PROP_SAVE(name,dir) n
    set PROP_SAVE(name,first) 0
    set PROP_SAVE(name,increment) 1
  }

  set title "Rename Multiple Text"
  set message "Enter New Text Information:" 
  set help "This prop_menu lets you change the names of the selected text (labels.) \
      The name will be: <prefix><number><suffix>\n"
  set prop_list [list \
      [list "" "" \
	-help $help] \
      [list new_name_prefix PROP_SAVE(name,name_prefix) -entry \
	-help {the prefix to be used for new text names}] \
      [list new_name_suffix PROP_SAVE(name,name_suffix) -entry \
	-help {the suffix to be used for new text names}] \
      [list numbered_in_direction PROP_SAVE(name,dir) -choice {n s e w} \
	-help {the text names are numbered in order in this direction} ] \
      [list first_number PROP_SAVE(name,first) -number \
	-help {the number given to the first text name} ] \
      [list increment PROP_SAVE(name,increment) -number 1 \
	-help {number is incremented by this amount for each new text name} ] \
      ]

  while {1} {
    # create the menu
    set ret [prop_menu2 -message $message -title $title $prop_list]
    if { $ret == 0 } {
      # the user hit cancel
      return
    }

    set name $PROP_SAVE(name,name_prefix)
    set suffix $PROP_SAVE(name,name_suffix)
    set count $PROP_SAVE(name,first)
    set dir $PROP_SAVE(name,dir)

    if { $PROP_SAVE(name,change_name) && $name == "" && $suffix == ""} {
      max_error "label error: you must provide a name prefix or suffix."
      continue
    }
    break
  }

  # sort labels by the direction to be named
  if {$dir == "n" || $dir == "e"} {
    set switch "-increasing"
  } elseif {$dir == "s" || $dir == "w"} {
    set switch "-decreasing"
  }

  if {$dir == "n" || $dir == "s"} {
    set PROP_SAVE(tmp) y
  } elseif {$dir == "e" || $dir == "w"} {
    set PROP_SAVE(tmp) x
  }

  set labels [lsort -command _name_labels_compare $switch $labels]

  # name em
  set select ""

  foreach lab_info $labels {
    struct max_label l $lab_info

    # toast this one
    sel_labels -kind ${l.kind} \
	-rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} \
	-text ${l.text} \
	-pos ${l.pos} \
	-layer ${l.layer}
    :delete

    set l.text "$name$count$suffix"

    # add back
    if {[msg_catch [list db_label -kind ${l.kind} -pos ${l.pos} ${l.layer} \
	${l.text} ${l.x1} ${l.y1} ${l.x2} ${l.y2}] msg1 msg2]} {
      # Shoot.  Probably metal layer invalid.
      # Undo what we have done.
      undo_to_delim
      # restore original box
      eval layt_box exact $box
      max_error "label error: $msg1 $msg2"
      return
    }

    # remember labels to select at end
    lappend select [list -kind ${l.kind} -rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} \
			-text ${l.text} -pos ${l.pos} -layer ${l.layer}]

    incr count $PROP_SAVE(name,increment)
  }

  # select all modified labels
  sel_clear
  foreach label $select {
    eval [concat sel_labels -more $label]
  }

  # And restore original box
  eval layt_box exact $box

  puts "Modified [llength $labels] label instances."
}


proc _name_labels_compare {label1 label2} -desc {
  used by the name_labels command for sorting
} {
  global PROP_SAVE

  if {$PROP_SAVE(tmp) == "x"} {
    setl {x1 y1} [lrange $label1 1 2]
    setl {x2 y2} [lrange $label2 1 2]
  } else {
    setl {y1 x1} [lrange $label1 1 2]
    setl {y2 x2} [lrange $label2 1 2]
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


proc label_unique_id {args} -desc {
  Create unique id for a new label.
} -doc {
  -cell <cell_def>
    Find unique id for specified cell instead of edit cell.
  -cell2 <cell_def>
    Make sure the label is unique in this cell, too.
  -prefix <string>
    Text name uses prefix suffixed with a number.  Default "label".
    Note: name must not include glob matching characters, eg [].
} {
  global LABEL_COUNT
  call_keyword $args {{cell ""} {cell2 ""} {prefix "label"}}

  if { $cell == "" } {
    set cell [lay_editcell]
  }

  if {![info exists LABEL_COUNT]} {
    set LABEL_COUNT 1
  }
  while {1} {
    set name $prefix$LABEL_COUNT
    incr LABEL_COUNT
    if {[db_search labels -non_hier -cell $cell $name] != ""} { continue }
    if { $cell2 != "" } {
      if {[db_search labels -non_hier -cell $cell2 $name] != ""} { continue }
    }
    return $name
  }
}


proc label_list2names {{-uniq} label_list} -desc {
  Given a list of max label structures, return just the label names.
} {
  set label_names ""
  foreach label_info $label_list {
    struct max_label l $label_info
    lappend label_names ${l.text}
  }
  if {$uniq} { set label_names [util_uniq $label_names] }
  return $label_names
}

proc label_select {{-more} labinfo} -desc {
  Select a label from the labinfo returned by db_search or sel_what
} {
    setl {x1 y1} [labinfo_loc $labinfo]
    set cmd sel_labels
    if {$more} {lappend cmd -more}
    lappend cmd -rect $x1 $y1 $x1 $y1 -kind [labinfo_kind $labinfo] \
       -layer [labinfo_layer $labinfo] -text [labinfo_text $labinfo] \
       -pos [labinfo_pos $labinfo]
    eval $cmd
}


proc labinfo_text {lab_info} -desc {
  Return label text from label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 6]
}

proc labinfo_kind {lab_info} -desc {
  Return label kind from label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 9]
}

proc labinfo_loc {lab_info} -desc {
  Return label location as {x1 y1 x2 y2} from label_info returned by sel_what or db_search.
} {
  return [lrange $lab_info 1 4]
}

proc labinfo_x1 {lab_info} -desc {
  Return label x1 location label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 1]
}

proc labinfo_y1 {lab_info} -desc {
  Return label y1 location label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 2]
}

proc labinfo_layer {lab_info} -desc {
  Return label layer from label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 0]
}

proc labinfo_path {lab_info} -desc {
  Return label path from label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 7]
}

proc labinfo_pos {lab_info} -desc {
  Return label text orientation from label_info returned by sel_what or db_search.
} {
  # humans like lower case here
  return [string tolower [lindex $lab_info 5]]
}

proc label_lbox {} -desc {
  Popup text command documentation
} {
  global FPLAN MAX_DEVELOPER LISTBOX_FONT
  global _LABEL_LBOX

  # Can be "basic", "placement", "timing", or "model"
  use_init _LABEL_LBOX(view) "basic"
  use_init _LABEL_LBOX(bussify) 1	 ;# Binary
  use_init _LABEL_LBOX(selection) "all"  ;# Can be "selected", "all", "nets"
  set _LABEL_LBOX(match) ""

  set w .text_list

  # Window contents:
  #   View: o basic info; o placement info; o timing info o model info
  #   Show: o as bits; o as busses  (binary)

  # NOT implemented
  #   View: o selected ports; o all ports

  #catch {destroy $w}
  #toplevel $w -borderwidth 0
  #wm geometry $w "600x500[_relative_origin]"
  #wm title $w "Edit Ports"
  #wm maxsize $w 1000 1000
  #wm minsize $w 100 100
  util_win_create $w "Port/Net Editor for Cell [lay_editcell]"
  wm geom $w "700x500"

  # end build of toplevel

  set tw 10  ;# Width of left hand titles in radiobutton area.

  set font $LISTBOX_FONT
  frame $w.f1 -borderwidth 0 -relief raised
  label $w.f1.l1 -relief flat -font $font -width $tw -text "View:"
  set common "-command _label_lbox_fill -font $font"
  set lvar "-variable _LABEL_LBOX(selection)"
  eval radiobutton $w.f1.r12 $common $lvar -text {{text (ports)}} -value all
  #eval radiobutton $w.f1.r11 $common $lvar -text {{selected text}} -value selected
  eval radiobutton $w.f1.r13 $common $lvar -text {{nets}} -value nets

  frame $w.f2 -borderwidth 0 -relief raised
  label $w.f2.l2 -relief flat -font $font -width $tw -text "List:"
  set lvar "-variable _LABEL_LBOX(view)"
  eval radiobutton $w.f2.r21 $common $lvar -text basic -value basic
  eval radiobutton $w.f2.r22 $common $lvar -text placement -value placement
  eval radiobutton $w.f2.r23 $common $lvar -text timing -value timing
  eval radiobutton $w.f2.r24 $common $lvar -text model -value model

  frame $w.f3 -borderwidth 0 -relief raised
  label $w.f3.l3 -relief flat -font $font -width $tw -text "Show:"
  set lvar "-variable _LABEL_LBOX(bussify)"
  eval radiobutton $w.f3.r31 $common $lvar -text {{as bits}} -value 0
  eval radiobutton $w.f3.r32 $common $lvar -text {{as busses}} -value 1

  frame $w.f4 -borderwidth 0 -relief raised
  label $w.f4.l4 -relief flat -font $font -width $tw -text "Match:"
  eval entry $w.f4.e -font $font -relief raised -textvariable _LABEL_LBOX(match) 
  bind $w.f4.e <Return> "_label_lbox_fill"

  #pack $w.f1.l1 $w.f1.r11 $w.f1.r12 $w.f1.r13 -side left
  pack $w.f1.l1 $w.f1.r12 $w.f1.r13 -side left
  pack $w.f2.l2 $w.f2.r21 $w.f2.r22 $w.f2.r23 $w.f2.r24 -side left
  if {$FPLAN(exists)} {
    # If no floorplanner, only basic label information is shown.
    pack $w.f3.l3 $w.f3.r31 $w.f3.r32 -anchor w -side left -expand 0
  }
  pack $w.f4.l4 $w.f4.e -anchor w -side left -expand 0
  pack $w.f1 $w.f2 $w.f3 $w.f4 -side top -anchor w

  #grid $w.f1.l1 $w.f1.r11 $w.f1.r12           -sticky w -ipadx 1 -ipady 1 -row 0
  #grid $w.f1.l2 $w.f1.r21 $w.f1.r22 $w.f1.r23 -sticky w -ipadx 1 -ipady 1 -row 1
  #grid $w.f1.l3 $w.f1.r31 $w.f1.r32           -sticky w -ipadx 1 -ipady 1 -row 2
  #pack $w.f1 -side top -anchor w



  label $w.header -font $font -relief raised -foreground blue -anchor w ;# Filled in by _fill routine.
  pack $w.header -side top -fill x

  # listbox and scroll bars for ports
  frame $w.items \
	  -borderwidth 0 \
	  -relief raised

  scrollbar $w.items.vscroll \
	  -relief raised \
	  -command "$w.items.list yview"

  listbox $w.items.list \
	  -selectmode extended \
	  -font $font \
	  -exportselection false \
	  -relief raised \
	  -yscrollcommand "$w.items.vscroll set"

  # Use buttonrelease so that the listbox selection is updated
  # before the proc is called.
  bind $w.items.list <ButtonRelease-1> {_label_lbox_sel -select}
  bind $w.items.list <Double-Button-1> {_label_lbox_sel -edit}
  bind $w.items.list <ButtonRelease-2> {_label_lbox_sel -edit}

  bind $w <Escape> {util_win_destroy $w}
  bind $w <Control-C> {util_win_destroy $w}

  # The default binding on Listbox is disabled in max.tcl for unknown reasons,
  # maybe for the max right-hand listbox?  Turn it back on.
  bind $w.items.list <B1-Motion> {
      set tkPriv(x) %x
      set tkPriv(y) %y
      tkListboxMotion %W [%W index @%x,%y]
  }


  # packing
  pack $w.items.list -expand 1 -fill both -side left
  pack $w.items.vscroll -fill y -side right
  pack $w.items -expand 1 -fill both -side top

  # Frame for bottom buttons
  frame $w.ftools -borderwidth 0 -relief raised
  frame $w.fb -borderwidth 0 -relief raised

  set help {\
    In the listbox: Button-1 selects.  Control-Button-1 adds to selection. \
    Shift-Button-1 selects all ports from the previously selection to the mouse point. \
    Selected ports in the listbox are selected in max, and the net is highlighted if\
    verilog for this cell is loaded in the NL database.
    The "View" radiobutton controls whether the listbox contains\
    text (also called ports or labels), or nets.  Nets are available\
    only if the nl data-base is loaded with the verilog for the current cell.\
    You cannot edit the nets from here, but you can select nets in the listbox\
    and they will be highlighted in max.
    The "List" radiobutton controls what info about the ports will be displayed in the listbox.
    The "Show" radiobutton allows you to edit busses easily by combining all nets in a bus\
    on a single line; if set to "bits", there is one line for every bus element.
    The "Match" box filters the lines that are displayed.  If not blank, only lines that match the\
    regular expression are displayed.  The line can match anywhere, not just the port name.  To match based on name, precede with a "^".  for example, to \
    get only ports beginning with "c", type "^c" and hit return.
    The "Edit" button or Button-2 or Double-Button-1\
    brings up an edit dialog box on the selected ports. 
    The "Rename Mutiple" button brings up a dialog to rename the selected ports programatically; useful for busses.
    The "Run Port Placer" button brings up the Port Placer dialog.
    The "Show Connectivity" button shows connectivity of selected ports from\
    verilog, if the nl data-base is loaded.
    The "Refresh" button forces an update of this dialog box from the max data-base.
    }

  button $w.ftools.edit -text "Edit" -command "_label_lbox_sel -edit"
  button $w.ftools.rename -text "Rename Multiple" -command "_label_multiple_rename;_label_lbox_fill"
  # We want to run the placer on the current cell, regardless of whether other cells are selected.
  button $w.ftools.placer -text "Run Port Placer" -command "fplan_edit_selected_ports -editcell 1;_label_lbox_fill"
  button $w.ftools.conn -text "Show Connectivity" -command "_label_show_connectivity"
  button $w.ftools.time -text "Time" -command "_label_time_it"
  button $w.ftools.lib -text "Create Model" -command "_label_create_lib_model"
  pack $w.ftools.edit $w.ftools.rename -side left -padx 5 -pady 1
  if {$FPLAN(exists)} {
    pack $w.ftools.placer $w.ftools.conn $w.ftools.time $w.ftools.lib \
	-side left -padx 5 -pady 1
  }

  label $w.info -width 20 -anchor e
  button $w.fb.close -text "Close" -command "catch {util_win_destroy $w}"
  button $w.fb.refresh -text "Refresh" -command "_label_lbox_fill"
  button $w.fb.help -text "Help" -command "prop_dialog -title {Edit Ports Help} {$help}"
  pack $w.fb.close $w.fb.refresh $w.fb.help -side left -padx 5 -pady 1
  pack $w.info -in $w.fb -side right -anchor e

  pack $w.fb -side bottom
  pack $w.ftools -side bottom

  util_win_finish $w -place normal
  
  _label_lbox_fill
}


proc _label_show_connectivity {} {
  global _LABEL_MAP _LABEL_LBOX

  if {![nl2_loaded -cell [lay_editcell]]} {
    msg "Verilog not loaded for cell [lay_editcell]; aborting.\n"
    return
  }

  set w .text_list.items.list

  set result ""

  set indicies [$w curselection]
  set sel_list ""
  foreach index $indicies {
    set sel_list [concat $sel_list $_LABEL_MAP($index)]
  }

  set mod [fplan_db_cell module [lay_editcell]]

  if {$_LABEL_LBOX(selection) == "nets"} {
    # Show connectivity of the named nets.
    foreach id $sel_list {
      append result "Net: $id\n"
      set inet [nl2_find_net $mod $id]
      foreach p [nl_get_net_pins $inet] {
	append result "	$p  (dir: [nl_get_pin_direction $p])\n"
      }
    }
  } else {
    # Show connectivity of the specified ports.
    foreach lab_info $sel_list {
      set port [labinfo_text $lab_info]
      set nlport [nl2_find_port $mod $port]
      append result "Port: $port  (dir: [nl_get_port_direction $nlport])\n"
      set inet [nl2_find_net $mod $port]
      foreach p [nl_get_net_pins $inet] {
	if {$p != $port} {
	  append result "	$p  (dir: [nl_get_pin_direction $p])\n"
	}
      }
    }
  }

  prop_dialog -title Connectivity $result
}


proc _label_lbox_sel {{-select} {-edit}} {
  global LABEL _LABEL_LBOX _LABEL_MAP
  cursor_busy 1

  set w .text_list.items.list

  # Make SURE the labels in the listbox are up to date with what is
  # in the max database; the listbox might be out of date with respect
  # to max, eg, if somone has edited a new cell, and we dont want
  # to create labels from a stale listbox in the current cell.
  # You cant do this if you are selecting, because _label_lbox_fill
  # updates the listbox selection from the selected max labels,
  # undoing the current selected lines in the listbox.
  if {$edit} {_label_lbox_fill}

  set indicies [$w curselection]
  set sel_list ""
  foreach index $indicies {
    set sel_list [concat $sel_list $_LABEL_MAP($index)]
  }

  set use_nl [nl2_loaded -cell [lay_editcell]]

  if {$select} {

    sel_clear
    db_flyline -delete

    # The _LABEL_MAP contains a list of ports/nets that correspond to each listbox element.
    # If it was a bus, _LABEL_MAP will contain the list of individual bits.

    if {$_LABEL_LBOX(selection) == "nets"} {

      foreach id $sel_list {
	fplan_sel_net -more $id
      }

    } else {

      foreach lab_info $sel_list {
	set port [labinfo_text $lab_info]
	sel_labels -more -text $port
	if {$use_nl} {
	  fplan_sel_net -more $port
	}
      }
      # This could be time consuming.  Skip it.
      # .text_list.info config -text "Selected: [llength [sel_what_l labels]]"
    }
  }

  if {$edit} {
    if {$_LABEL_LBOX(selection) == "nets"} {

      msg "Cant edit nets.\n"

    } else {
      # Bring up the label editor on the selected labels.
      label_edit_new $sel_list
    }
  }
  cursor_busy 0


  return


  ### OLD CODE:

  if {$select} {

    sel_clear
    db_flyline -delete

    # Things in the idlist can be individual ports (x or a[1]) or busses (a[0:7]).
    foreach bus $idlist {
      foreach port $_LABEL_MAP($bus) {
	sel_labels -more -text $port
	lappend portlist $port
	if {$use_nl} {
	  fplan_sel_net -more $port
	}
      }
    }
  }

  if {$edit} {
    foreach bus $idlist {
      foreach port $_LABEL_MAP($bus) {
	lappend bitlist $port
      }
    }

    # Bring up the label editor on the selected labels.
    if {[label_edit_new $bitlist] == 0} {
      # cancelled
      return
    }
  }

  return
}

proc label_edit_new {{-type ""} lab_info_list} -desc {
  Edit labels specified.
} {
  global _LABEL_LBOX

  if {$type != ""} {
    set _LABEL_LBOX(view) $type
  }

  # Figure out the label names to be shown in the prop_menu.
  set name_list_all ""
  foreach lab_info $lab_info_list {
    lappend name_list_all [labinfo_text $lab_info]
  }

  # Make names a string indicating the label names we are editing.
  if {[llength $name_list_all] == 0} {
    msg "label_edit: No ports selected\n"
    return
  } elseif {[llength $name_list_all] == 1} {
    # If only one label selected, user can change the label name.
    set names [lindex $name_list_all 0]
  } else {
    # Make names a list of busses, but dont make it too long.
    set names ""
    # The sort is just for neatness, not compulsory.
    foreach name [lsort [nlt_bussify $name_list_all]] {
      if {[string length $names] + [string length $name] > 50} {
	append names "..."
	break
      }
      append names "$name "
    }
  }

  set current_view $_LABEL_LBOX(view)

  while {1} {
    set repeat 0

    # Get basic information on label from max.

    # The "size" field is "point" or "box" and is synthesized from other label info.
    set basic_list "layer x1 y1 x2 y2 pos text kind size"
    foreach thing $basic_list {set LABEL($thing) "**UNKNOWN**"}

    # Put current values of label into LABEL array.
    # If multiple labels have different values, set to "<various>"
    foreach lab_info $lab_info_list {
	struct max_label l $lab_info
	set l.pos [string tolower ${l.pos}] ;# The pos is too imposing as upper-case.
	set l.size [expr {(${l.x1}==${l.x2}&&${l.y1}==${l.y1}) ? "point" : "box"}]

	foreach thing $basic_list {
	  set lab_value [set l.$thing]
	  if {$LABEL($thing) == "**UNKNOWN**"} {
	    set LABEL($thing) $lab_value
	  } elseif {$LABEL($thing) != $lab_value} {
	    set LABEL($thing) "<various>"  ;# Two labels have different values of $thing.
	  }
	}
    }

    set prop_menu_buttons "Done=1=default Edit_All_Text=2 Cancel=0=cancel"
    set prop_list ""

    lappend prop_list [list "Edit Text Info:" current_view -radio {basic placement timing model} \
	  -return 3]

    switch -- $current_view {
      basic {
	# Edit basic information on label.
	global MAX_DEVELOPER
	if { $MAX_DEVELOPER } {
	  set label_choices {input output inout global local comment hidden}
	} else {
	  set label_choices {input output inout global local comment}
	}

	set layer_choices [techinfo wire_layers]
	set pos_choices [list northwest north northeast west center \
			     east southwest south southeast]

	# Add the label name(s) to prop_menu
	# If only one label selected, user can change the label name, 
	# otherwise it is just a comment.
	lappend prop_list [list text names [expr {[llength $name_list_all]==1 ? "-entry" : "-label"}] \
	-help {The name(s) of the selected text.  If a bus or multiple text are selected, you can not\
	change the names here.  To rename busses or multiple text simultaneously,\
	click "Edit_All_Text" and use the "Rename Multiple" button}]

	lappend prop_list [list layer LABEL(layer) -popup $layer_choices \
	-help {The layer the text is currently on.  Note that it is an error\
	if there is no paint of the matching type at the same physical location as the text.}]
      lappend prop_list [list kind LABEL(kind) -choice $label_choices \
	-help {Input, output and inout labels are I/O ports. \
	Global labels are interpreted by different tools differently, but are typically used\
	for assumed connections, for example, vdd and gnd. \
	Local labels are often used to label paint that should be connected by a router\
	in the current cell. \
	Comment labels have no connectivity implications. \
	Hidden labels are invisible in max.}]
      lappend prop_list [list {text position} LABEL(pos) -choice $pos_choices \
	-help {Controls the location and orientation of the viewable text\
	relative to the text position.}]
      # These are -entry instead of -number because they may be "<various>"
      lappend prop_list [list x LABEL(x1) -entry -when {$LABEL(size)=="point"}]
      lappend prop_list [list y LABEL(y1) -entry -when {$LABEL(size)=="point"}]
      lappend prop_list [list x1 LABEL(x1) -entry -when {$LABEL(size)=="box"}]
      lappend prop_list [list y1 LABEL(y1) -entry -when {$LABEL(size)=="box"}]
      lappend prop_list [list x2 LABEL(x2) -entry -when {$LABEL(size)=="box"}]
      lappend prop_list [list y2 LABEL(y2) -entry -when {$LABEL(size)=="box"}]
      lappend prop_list [list type LABEL(size) -choice {point box} -reload \
	-help {Almost always "point" to indicate text is at a single point.  \
	If "box", the text is attached to the specified rectangle.}]
     }

    placement {
      # Edit placement info, including x,y from basic info.
      #set disp_list "place loc bitloc layerspec"

      set disp_list "place locspec layerspec"
      foreach thing $disp_list {set display($thing) "**UNKNOWN**"}

      # Put current values of label into LABEL array.
      # If multiple labels have different values, set to "<various>"
      foreach lab_info $lab_info_list {
	set id [labinfo_text $lab_info]
	foreach thing $disp_list {
	  set lab_value [fplan_db_pin getprop $id $thing]
	  if {$display($thing) == "**UNKNOWN**"} {
	    set display($thing) $lab_value
	  } elseif {$display($thing) != $lab_value} {
	    set display($thing) "<various>"  ;# Two labels have different values of $thing.
	  }
	}
      }

      lappend prop_list [list text names -label \
	-help {The name(s) of the selected text.}]
      lappend prop_list [list place display(place) -choice {unplaced placed fixed} \
	-help {If "fixed", the port location will not be modified by the port placement tools.}]
      lappend prop_list [list locspec display(locspec) -popup {left right top bottom ""} \
	-help { This property is used by the Port Placer to specify either a desired\
	  side or an exact location for this port or bus.  The format of this property is:
	      <region> [track] [<expression>]
	  Where: \
	  <region> is the side of the cell the port is on; \
	  the optional "track" keyword indicates the <expression> refers to a track number\
	  instead of an absolute value in microns; \
	  the optional <expression> is evaluated to determine the location on that side. \
	  The <expression> must not contain any spaces. \
	  Inside the <expresssion>, $b is the bit number, $h is the cell\
	  height and $w is the cell width. \
	  If no expression is given, the port is\
	  just placed in the indicated region, as close as possible to its previous location. \
	  The Port Placer puts ports at the closest unoccupied on-grid location.\
	  }]
      #lappend prop_list [list bitloc display(bitloc) -entry]
      lappend prop_list [list layerspec display(layerspec) -entry \
	-help {An optional expression that must evaluate to a layer number (eg: 1 through 9)\
	  to indicate the desired layer for this port. \
	  The <expression> must not contain any spaces. \
	  Inside the <expresssion>, $b is the bit number, $h is the cell\
	  height and $w is the cell width. \
	  For example, $b%2?3:5 puts ports alternately on layer 3 and 5. \
	  }]
      lappend prop_list [list "current layer" LABEL(layer) -entry \
	-help {the layer the port is currently on, or "space" if unknown.}]
      lappend prop_list [list "current x" LABEL(x1) -entry]
      lappend prop_list [list "current y" LABEL(y1) -entry]

    }

    timing {

      set prop_list ""

      global MAX_DEVELOPER
      if { $MAX_DEVELOPER } {
	set label_choices {input output inout global local comment hidden}
      } else {
	set label_choices {input output inout global local comment}
      }

      lappend prop_list [list text names \
        [expr {[llength $name_list_all]==1 ? "-entry" : "-label"}] \
	-help {The name(s) of the selected text.  If a bus or multiple text are selected, you can not\
	change the names here.  To rename busses or multiple text simultaneously,\
	click "Edit_All_Text" and use the "Rename Multiple" button}]

      lappend prop_list [list kind LABEL(kind) -choice $label_choices \
	-help {Input, output and inout labels are I/O ports. \
	Global labels are interpreted by different tools differently, but are typically used\
	for assumed connections, for example, vdd and gnd. \
	Local labels are often used to label paint that should be connected by a router\
	in the current cell. \
	Comment labels have no connectivity implications. \
	Hidden labels are invisible in max.}]

      set disp_list "slack ext_budget ext_actual ext_driver ext_cap"
      foreach thing $disp_list {set display($thing) "**UNKNOWN**"}

      # Put current values of label into LABEL array.
      # If multiple labels have different values, set to "<various>"
      foreach lab_info $lab_info_list {
	set id [labinfo_text $lab_info]
	foreach thing $disp_list {
	  set lab_value [fplan_db_pin getprop $id $thing]
	  if {$display($thing) == "**UNKNOWN**"} {
	    set display($thing) $lab_value
	  } elseif {$display($thing) != $lab_value} {
	    set display($thing) "<various>"  ;# Two labels have different values of $thing.
	  }
	}

      }

      lappend prop_list [list slack display(slack) -label]
      lappend prop_list [list budget display(ext_budget)]
      lappend prop_list [list actual display(ext_actual)]
      lappend prop_list [list driver display(ext_driver)]
      lappend prop_list [list cap display(ext_cap)]
    }

    model {

      set prop_list ""

      global MAX_DEVELOPER
      if { $MAX_DEVELOPER } {
	set label_choices {input output inout global local comment hidden}
      } else {
	set label_choices {input output inout global local comment}
      }

      lappend prop_list [list text names \
        [expr {[llength $name_list_all]==1 ? "-entry" : "-label"}] \
	-help {The name(s) of the selected text.  If a bus or multiple text are selected, you can not\
	change the names here.  To rename busses or multiple text simultaneously,\
	click "Edit_All_Text" and use the "Rename Multiple" button}]

      lappend prop_list [list kind LABEL(kind) -choice $label_choices \
	-help {Input, output and inout labels are I/O ports. \
	Global labels are interpreted by different tools differently, but are typically used\
	for assumed connections, for example, vdd and gnd. \
	Local labels are often used to label paint that should be connected by a router\
	in the current cell. \
	Comment labels have no connectivity implications. \
	Hidden labels are invisible in max.}]

      set disp_list "slack int_budget int_actual int_drive_res int_cap"
      foreach thing $disp_list {set display($thing) "**UNKNOWN**"}

      # Put current values of label into LABEL array.
      # If multiple labels have different values, set to "<various>"
      foreach lab_info $lab_info_list {
	set id [labinfo_text $lab_info]
	foreach thing $disp_list {
	  set lab_value [fplan_db_pin getprop $id $thing]
	  if {$display($thing) == "**UNKNOWN**"} {
	    set display($thing) $lab_value
	  } elseif {$display($thing) != $lab_value} {
	    set display($thing) "<various>"  ;# Two labels have different values of $thing.
	  }
	}

      }

      lappend prop_list [list slack display(slack) -label]
      lappend prop_list [list budget display(int_budget)]
      lappend prop_list [list actual display(int_actual)]
      lappend prop_list [list driver display(int_drive_res)]
      lappend prop_list [list cap display(int_cap)]
    }
  }


    set prev_view $current_view
    switch [prop_menu2 -title "max edit text" -buttons $prop_menu_buttons $prop_list] {
      0 {
	return  ;# cancelled
      }
      2 {
	# Equivalent to a cancel, followed by posting the text listbox.
	label_lbox
	return
      }
      3 {
	# User hit the radiobutton to change the menu.
	set repeat 1
      }
    }

    # Update label info - must use prev_view because use may have changed something,
    # then clicked the radio button to change current_view
    switch -- $prev_view {
      basic {
	# basic info is always updated by code below
      }
      placement - timing - model {
	foreach lab_info $lab_info_list {
	  set id [labinfo_text $lab_info]
	  foreach thing $disp_list {
	    if {$display($thing) != "<various>"} {
	      fplan_db_pin setprop $id $thing $display($thing)
	    }
	  }
	}
      }
    }

    # Check that x,y are on user grid.  Warn if not.
    set off_grid 0
    if {$LABEL(x1) != "<various>"} {
      setl {rx1 junk} [uusnap -user $LABEL(x1) 0]
      if {[approx $rx1 != $LABEL(x1)]} {set off_grid 1}
    }
    if {$LABEL(y1) != "<various>"} {
      setl {junk ry1} [uusnap -user 0 $LABEL(y1)]
      if {[approx $ry1 != $LABEL(y1)]} {set off_grid 1}
    }
    if {$LABEL(size) == "box"} {
      if {$LABEL(x2) != "<various>"} {
	setl {rx2 junk} [uusnap -user $LABEL(x2) 0]
	if {[approx $rx2 != $LABEL(x2)]} {set off_grid 1}
      }
      if {$LABEL(y2) != "<various>"} {
	setl {junk ry2} [uusnap -user 0 $LABEL(y2)]
	if {[approx $ry2 != $LABEL(y2)]} {set off_grid 1}
      }
    }

    if {$off_grid} {
      set msg "Specified label coordinates are not on user grid.  Are you SURE?"
      set ret [prop_dialog -title Warning -buttons "Yes Cancel" $msg]
      if {$ret == "Cancel"} {return}
    }


    # Update any changed info in the max labels themselves.  Better not be in a hurry.
    set update_labels ""
    foreach lab_info $lab_info_list {
      struct max_label l $lab_info
      sel_labels -kind ${l.kind} -rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -text ${l.text} -pos ${l.pos} -layer ${l.layer}

      foreach thing "layer x1 y1 x2 y2 pos kind" {
	if {$LABEL($thing) != "<various>"} {set l.$thing $LABEL($thing)}
      }
      if {$LABEL(size) == "point"} {
	set l.x2 ${l.x1}
	set l.y2 ${l.y1}
      }

      if {[llength $lab_info_list] == 1} {
	# User might have changed the label name.
	set l.text $names
      }
      lappend updated_labels [destruct max_label l]

      :delete
      if {$LABEL(size) == "box"} {
	db_label -kind ${l.kind} -pos ${l.pos} ${l.layer} ${l.text} ${l.x1} ${l.y1} ${l.x2} ${l.y2}
      } else {
	db_label -kind ${l.kind} -pos ${l.pos} ${l.layer} ${l.text} ${l.x1} ${l.y1}
      }
    }

    # Now, since we blew away the selection, restore it.
    foreach labinfo $updated_labels {
      struct max_label l $labinfo
      sel_labels -more -kind ${l.kind} -rect ${l.x1} ${l.y1} ${l.x2} ${l.y2} -text ${l.text} -pos ${l.pos} -layer ${l.layer}
    }

    if {!$repeat} {break}
  }

  set _LABEL_LBOX(view) $current_view
  _label_lbox_fill  ;# Update changes in listbox, if mapped.
}


proc select_end_label_hook {} -desc {
  Called when selection changes.  Update the label list box, if any.
} {
  if {[winfo exists .text_list]} {
    _label_lbox_fill
  }
}


proc _label_lbox_fill_nets {} {
  global _LABEL_LBOX _LABEL_MAP
  set plist .text_list.items.list

  if {[$plist size] > 0} { $plist delete 0 end }

  if {[nl2_loaded -cell [lay_editcell]]} {
    set net_list [nl2_list_nets [fplan_unfix_name [lay_editcell]]]
  } else {
    set net_list ""
  }

  set max_name_len 10  ;# Wont make the name column any narrower than 10 chars.

  if {$_LABEL_LBOX(bussify)} {
    foreach id $net_list {
      if {[regexp {^(.*)\[([^[]*)\]$} $id junk base spec]} {
	# It was a bus.  Save the index in bus2indicies,
	# so we can later aggregate them into a nice bus name like a[9:17],
	# and save all the labels themselves in bus2labels.
	lappend bus2indicies($base) $spec
	lappend bus2labels($base) $id
	# Busses can have [123] after them, so add 5 for a space
	set max_name_len [max $max_name_len [expr [string length $id] + 5]]
      } else {
	set map($id) $id
	set max_name_len [max $max_name_len [string length $id]]
      }
    }

    # Process busses.  Each bus gets a single list box entry.
    foreach simple_name [array names bus2indicies] {
      set bus "$simple_name\[[nlt_list_compress $bus2indicies($simple_name)]\]"
      set map($bus) $bus2labels($simple_name)
    }
  } else {
    # Dont bussify.  Just put each individual label in the map array.
    foreach id $net_list {
      set map($id) $id
      set max_name_len [max $max_name_len [string length $id]]
    }
  }

  set _LABEL_LBOX(view) timing
# TODO: what to put here???
  set format "%-${max_name_len}s %-12s"
  set disp_list "slack"
  set header [eval format {$format} net $disp_list]
  .text_list.header configure -text $header

  set lbox_cnt 0    ;# Count of total number of labels displayed, taking busses into account.
  set lbox_index 0  ;# Index in listbox.
  foreach sortkey [lsort -dictionary [array names map]] {
    set lbox_name [lindex $sortkey 0]  ;# Its the sub name, or port name with optional "(count)" appended.
    switch -- $_LABEL_LBOX(view) {
      timing {

	# adds stuff to display array
	if {![_find_label_prop $disp_list $map($sortkey) io]} {
	  continue
	}

	# build display line
	set string $lbox_name
	foreach thing $disp_list {
	  lappend string $display($thing)
	}

	set entry [eval format \"$format\" $string]
      }
    }

    if {$_LABEL_LBOX(match) != ""} {
      if {![regexp $_LABEL_LBOX(match) $entry]} {continue}
    }

    $plist insert end $entry
    # Save the list of labels corresponding to this listbox entry.
    set nets_in_this_listbox_item $map($sortkey)
    set _LABEL_MAP($lbox_index) $nets_in_this_listbox_item
    incr lbox_cnt [llength $nets_in_this_listbox_item]

    # Synchronize the max selected labels to the listbox.
    # We will select the listbox entry if any label in the
    # list to which it corresponds is selected.
    foreach labinfo $nets_in_this_listbox_item {
      if {[info exists sel_label_hash($labinfo)]} {
	$plist selection set $lbox_index
	break
      }
    }

    incr lbox_index
  }

  # This could be time consuming to compute when selection is changed, so display total instead.
  # User can see number of selected ports by setting "View:" to "selected".
  #.text_list.info config -text "Selected: [llength $sel_labels]"
  .text_list.info config -text "Net Count: $lbox_cnt"
}


proc _label_lbox_fill {} -desc {
  fill list box with variables matching apropos pattern;  highlight selected labels.
} {
  global _LABEL_LBOX	;# Options for this command.
  global _LABEL_MAP     ;# Maps listbox indicies to label_info structures.
  global TIMING_DATA

  catch {unset _LABEL_MAP}

  set plist .text_list.items.list
  if {![winfo exists $plist]} {return}

  # Update title in case user edited a new cell.
  set cell [lay_editcell]
  wm title .text_list "Port/Net Editor for Cell $cell"

  cursor_busy 1

  use_init TIMING_DATA(cell_of_T_menu) ""

  set last_cell $TIMING_DATA(cell_of_T_menu)
  set TIMING_DATA(cell_of_T_menu) $cell

  use_init TIMING_DATA($last_cell,top_visible_label) ""
  use_init TIMING_DATA($cell,top_visible_label) ""

  if {[$plist size] > 0} { 
    # save position -- this is the thing at the top
    set TIMING_DATA($last_cell,top_visible_label) \
	[lindex [$plist get [$plist nearest 0]] 0]

    # delete contest of listbox
    $plist delete 0 end 
  }

  set sel_labels [sel_what_l labels]
  # Make this array for use later.
  foreach lab $sel_labels {
    set sel_label_hash($lab) 1
  }

  switch -- $_LABEL_LBOX(selection) {
    "all" {
      set label_list [db_search_l labels -non_hier -cell [lay_editcell]]
    }
    "selected" {
      set label_list $sel_labels
    }
    "nets" {
      _label_lbox_fill_nets
      cursor_busy 0
      return
    }
    default { error "unrecognized _LABEL_LBOX(selection): $_LABEL_LBOX(selection)" }
  }

  set max_name_len 10  ;# Wont make the name column any narrower than 10 chars.

  # Figure out the list of labels to process, and the map of bits to busses.
  # Each element in map array will correspond to a single entry in the list box.
  # The map array index is the sort-key for the selection box,
  # and the first element of the map array index will appear in the list box.
  # The contents of the map array is the list of labels represented by that listbox selection.
  if {$_LABEL_LBOX(bussify)} {
    foreach lab_info $label_list {
      if {[labinfo_kind $lab_info] == "hidden"} {continue}
      set id [labinfo_text $lab_info]


      if {[regexp {^(.*)\[([^[]*)\]$} $id junk base spec]} {
	# It was a bus.  Save the index in bus2indicies,
	# so we can later aggregate them into a nice bus name like a[9:17],
	# and save all the labels themselves in bus2labels.
	lappend bus2indicies($base) $spec
	lappend bus2labels($base) $lab_info
	# Busses can have [123] after them, so add 5 for a space
	set max_name_len [max $max_name_len [expr [string length $id] + 5]]
      } else {
	# It is not a bus.  Could be multiple instances
	# of each label, though, so save all in a list.
	lappend bits2labels($id) $lab_info
	set max_name_len [max $max_name_len [string length $id]]
      }
    }

    # Process the non-busses.  They each get a single list box entry,
    # optionally followed by the count of the number of times
    # that label appears.
    foreach id [array names bits2labels] {
      set cnt [llength $bits2labels($id)]
      set name_and_count $id
      if {$cnt > 1} {append name_and_count " ($cnt)"}
      set map([list $name_and_count]) $bits2labels($id)
    }

    # Process busses.  Each bus gets a single list box entry.
    foreach simple_name [array names bus2indicies] {
      set bus "$simple_name\[[nlt_list_compress $bus2indicies($simple_name)]\]"
      set map([list $bus]) $bus2labels($simple_name)
    }
  } else {
    # Dont bussify.  Just put each individual label in the map array.
    foreach lab_info $label_list {
      if {[labinfo_kind $lab_info] == "hidden"} {continue}
      set id [labinfo_text $lab_info]
      # There could be multiple labels with the same name, so to
      # disambiguate them, use the entire label as the sort key.
      lappend map([list $id $lab_info]) $lab_info

      set max_name_len [max $max_name_len [string length $id]]
    }
  }

  # Fill in the column header label.
  switch -- $_LABEL_LBOX(view) {
    basic {
      # This is the list of things from the label that we will display:
      set disp_list "kind layer pos x1 y1"
      set format "%-${max_name_len}s %-12s %-12s %-12s %-16s %-16s"
    }
    placement {
      # These are the placement properties we will display:
      set disp_list "place locspec layerspec"
      set format "%-${max_name_len}s %-12s %-12s %-12s"
    }
    timing {
      set format "%-${max_name_len}s %-7s %-14s %-12s %-14s %-12s %-12s"
      set disp_list "kind slack ext_budget ext_actual ext_driver ext_cap"
    }
    model {
      set format "%-${max_name_len}s %-7s %-14s %-12s %-14s %-14s %-12s"
      set disp_list "kind slack int_budget int_actual int_drive_res int_cap"
    }
    default {
      error "_label_lbox internal error"
    }
  }

  set header [eval format {$format} port $disp_list]

  .text_list.header configure -text $header

  set lbox_cnt 0    ;# Count of total number of labels displayed, taking busses into account.
  set lbox_index 0  ;# Index in listbox.

  switch -- $_LABEL_LBOX(view) {
    basic { set port_kinds all }
    default { set port_kinds io }
  }

  set label_list ""
  foreach sortkey [lsort -dictionary -index 0 [array names map]] {
    # Its the sub name, or port name with optional "(count)" appended.
    set lbox_name [lindex $sortkey 0]

    lappend label_list $lbox_name

    # Set each displayed thingy to "<various>" if there are two that 
    # are different and not numbers.

    # adds stuff to display array
    if {![_find_label_prop $disp_list $map($sortkey) $port_kinds]} {
      continue
    }

    # build display line
    set string $lbox_name
    foreach thing $disp_list {
      lappend string $display($thing)
    }

    set entry [eval format \"$format\" $string]

    if {$_LABEL_LBOX(match) != ""} {
      if {![regexp $_LABEL_LBOX(match) $entry]} {continue}
    }

    $plist insert end $entry
    # Save the list of labels corresponding to this listbox entry.
    set labels_in_this_listbox_item $map($sortkey)
    set _LABEL_MAP($lbox_index) $labels_in_this_listbox_item
    incr lbox_cnt [llength $labels_in_this_listbox_item]

    # Synchronize the max selected labels to the listbox.
    # We will select the listbox entry if any label in the
    # list to which it corresponds is selected.
    foreach labinfo $labels_in_this_listbox_item {
      if {[info exists sel_label_hash($labinfo)]} {
	$plist selection set $lbox_index
	break
      }
    }

    incr lbox_index
  }

  # now try to set the window so the old thing at the top is still near 
  # the top
  if {$TIMING_DATA($cell,top_visible_label) != ""} {
    set i [lsearch -exact $label_list $TIMING_DATA($cell,top_visible_label)]
    if {$i > 0} {
      $plist yview $i
    } else {
      # maybe went from bits to bytes, strip bits and look
      set root [lindex [split $TIMING_DATA($cell,top_visible_label) \[] 0]
      set i [lsearch $label_list ${root}*]
      if {$i > 0} {
	$plist yview $i
      }
    }
  }

  # This could be time consuming to compute when selection is changed, so display total instead.
  # User can see number of selected ports by setting "View:" to "selected".
  #.text_list.info config -text "Selected: [llength $sel_labels]"
  .text_list.info config -text "Port Count: $lbox_cnt"

  cursor_busy 0
}


proc _find_label_prop {display_list label_info_list port_kinds} {

  # put data here
  upvar display display

  # clear display
  foreach thing $display_list {
    set display($thing) "**UNKNOWN**"
  }

  # Put current values of label into LABEL array.
  # If multiple labels have different values, set to "<various>"
  foreach lab_info $label_info_list {
    set id [labinfo_text $lab_info]

    if {$id == ""} {
      # for nets -- don't get a label
      set id $lab_info
    } elseif {$port_kinds == "io"} {
      set kind [labinfo_kind $lab_info]
      if {[lsearch "input output inout" $kind] == -1} {
	# only show if I/O
	return 0
      }
    }

    foreach thing $display_list {
      set lab_value [fplan_db_pin getprop $id $thing]
      if {$lab_value == ""} {
	if {[catch {labinfo_$thing $lab_info} lab_value]} {
	  # get property if exists, "" otherwise.
	  set lab_value ""
	}
      }

      set num [parse_pp_number $lab_value]

      if {$display($thing) == "**UNKNOWN**"} {
	# unknown, just set.
	set display($thing) $lab_value

	if {$num == "" || ($num == 0 && [string index $lab_value 0] != "0") \
		|| [llength $num] != 1} {
	  # not a number or pp_number
	  set display($thing,number) 0
	} else {
	  set display($thing,number) 1
	  set display($thing,min) $num
	  set display($thing,max) $num
	}

      } elseif {$display($thing) != $lab_value} {
	# set AND different on this label
	set display($thing) "<various>"

	# if numbers (and pp_numbers), compute range
	if {$num == "" || ($num == 0 && [string index $lab_value 0] != "0") \
		|| [llength $num] != 1} {
	  # not a number or pp_number
	  set display($thing,number) 0

	} elseif {$display($thing,number)} {
	  # number
	  set display($thing,min) [min $num $display($thing,min)]
	  set display($thing,max) [max $num $display($thing,max)]
	}
      }
    }
  }

  foreach thing $display_list {
    if {$display($thing,number) && $display($thing) == "<various>"} {
      set display($thing) "[pp_number $display($thing,min)]-[pp_number $display($thing,max)]"
    }
  }

  return 1
}




# TIMING BUDGET:
#
# 8/13 (old):
# Leaf cells have:
#   For each input: internal delay (aka setup); wire len (worst case path); wire C (total); load (total)
#   For each output: internal delay; driver size; wire len (aka RC)
#   For each inout: all of the above.
#
# Hierarchical cells have:
#   For each input: delay=0; wire len (worst case path); wire C (total)
#   For each output: delay=0; wire len (aka RC)


# 8/14: When viewing a cell, want to see, for each port:
#   Total internal and external delay.  Internal delay is what is budgeted.
#   Total internal and external cap.
#   Net driver size.
#   Cant really show total wire length, because repeaters are inserted, making it meaningless.
#   For a detailed view: break it down into wire delay vs gate delay.
# What is saved in the file is:
#   For an input:  Ctotal, Deff (computed for Critical Path only)
#                  Details: Ctotal = Cwire+Csubcells;  Deff = Dsubcell (on C.P.) + Dwire, including repeaters.
#   For an output: Driver size, Deff, Ctotal.
#                  Details: contribution from wires vs subcells.
# Would also like to see the external delay, cap, and driver for each port, but this depends
# on the instance path in a fully hierarchical design.  So, a delay calculator must
# start at the top of the design tree, and annotate the external delay,cap,driver into
# the module for each instance seen.  Then when editing the module, can show the worst case.

      
# timing
use_init TIMING_DATA(ext_input_budget) 3ns
use_init TIMING_DATA(ext_output_budget) 2.5ns

use_init TIMING_DATA(ext_cap) 100fF
use_init TIMING_DATA(ext_driver) ""

# modeling
use_init TIMING_DATA(int_input_budget) 2ns
use_init TIMING_DATA(int_output_budget) 1ns

use_init TIMING_DATA(int_cap) 50fF
use_init TIMING_DATA(int_drive_res) 1000


proc add_default_budgets {{-reset} {-type ""} {-def ""}} -desc {
  add all defaults
} {

  global TIMING_DATA _LABEL_LBOX

  if {$def == ""} {
    # default to current cell
    set def [lay_editcell]
    set menu 1
  } else {
    set menu 0
  }

  # shared:
  #   slack  = cycle_time - int_input_delay - ext_input_delay
  #            cycle_time - int_output_delay - ext_output_delay
  # Note: slack computed and set elsewhere -- zeroed here

  if {$reset} {
    _add_default_budgets_int -reset $reset input slack ""
    _add_default_budgets_int -reset $reset output slack ""
  }

  # for timing:
  #   ext_budget   input/output
  #   ext_actual
  #   ext_cap
  #   ext_driver

  # for modeling:
  #   int_budget
  #   int_actual
  #   int_cap      input
  #   int_drive_res  output

  if {$type == ""} {
    set type $_LABEL_LBOX(view)
  }

  switch -- $type {
    timing {

      _add_default_budgets_int -reset $reset $def input ext_budget \
	  $TIMING_DATA(ext_input_budget)
      _add_default_budgets_int -reset $reset $def output ext_budget \
	  $TIMING_DATA(ext_output_budget)

      if {$reset} {
	_add_default_budgets_int -reset $reset $def input ext_actual ""
	_add_default_budgets_int -reset $reset $def output ext_actual ""
      }

      _add_default_budgets_int -reset $reset $def output ext_cap \
	  $TIMING_DATA(ext_cap)
      _add_default_budgets_int -reset $reset $def input ext_driver \
	  $TIMING_DATA(ext_driver)
    } 

    model {

      _add_default_budgets_int -reset $reset $def input int_budget \
	  $TIMING_DATA(int_input_budget)
      _add_default_budgets_int -reset $reset $def output int_budget \
	  $TIMING_DATA(int_output_budget)

      if {$reset} {
	_add_default_budgets_int -reset $reset $def input int_actual ""
	_add_default_budgets_int -reset $reset $def output int_actual ""
      }

      _add_default_budgets_int -reset $reset $def input int_cap \
	  $TIMING_DATA(int_cap)
      _add_default_budgets_int -reset $reset $def output int_drive_res \
	  $TIMING_DATA(int_drive_res)
    }  
  }

  # show changes in timing in "T" label menu
  if {$menu} {
    label_lbox
  }
}


proc _add_default_budgets_int {{-reset 0} def kind type default} -desc {
  walk thru all ports of type kind and add values if not set.
} {

  global TIMING_DATA

  if {$default != ""} {
    # pad with <> so user knows it was not individually set
    set default "<$default>"
  }

  foreach label_info [db_search_labels -cell $def -non_hier] {
    struct max_label l $label_info

    if {${l.kind} == $kind} {
      
      if {[lsearch $TIMING_DATA(clk_names) ${l.text}] != -1} {
	# ignore clocks
	fplan_db_pin -cell $def setprop ${l.text} $type ""
	continue
      }

      if {$reset} {
	# reset it
	set budget ""

      } else {
	# see if there is something there
	set budget [fplan_db_pin -cell $def getprop ${l.text} $type]
      }

      if {$budget == "" || [string index $budget 0] == "<"} {
	# not set or default budget, set it (possibly new budget)
	if {${l.kind} == $kind} {
	  fplan_db_pin -cell $def setprop ${l.text} $type $default
	}
      }
    }
  }
}


proc _label_time_it {} -desc {
  menu to control timing
} {

  global TIMING_DATA _LABEL_LBOX

  set cell [lay_editcell]

  # make sure user is here
  if {$_LABEL_LBOX(view) != "timing"} {
    set _LABEL_LBOX(view) timing
    label_lbox
  }

  set title "Timing Setup"
  set message "Time $cell with:" 
  set prop_list ""

  lappend prop_list [list {Add Budget} "" \
			 -button "add_default_budgets"]
  lappend prop_list [list {Reset Budget} "" \
			 -button "add_default_budgets -reset"]

  lappend prop_list [list {Default External Input Delay} \
			 TIMING_DATA(ext_input_budget) -entry]
  lappend prop_list [list {Default External Output Delay} \
			 TIMING_DATA(ext_output_budget) -entry]

  lappend prop_list [list {Default External Driver} \
			 TIMING_DATA(ext_driver) -entry]
  lappend prop_list [list {Default External Output Capacitance} \
			 TIMING_DATA(ext_cap) -entry]

  lappend prop_list [list {Clocks} TIMING_DATA(clk_names) -entry]

  # popup window
  set ret [prop_menu2 -message $message -title $title $prop_list]

  if {$ret == 0} {
    # user hit cancel
    return ""
  }

  # TODO
  puts fooo
}


proc _label_create_lib_model {} -desc {
  menu to control building a lib model using speedy
} {

  global TIMING_DATA _LABEL_LBOX

  set cell [lay_editcell]

  # make sure user is here
  if {$_LABEL_LBOX(view) != "model"} {
    set _LABEL_LBOX(view) model
    label_lbox
  }

  set title "Create Timing Model"
  set message "Model $cell with:" 
  set prop_list ""

  lappend prop_list [list {Add Budget} "" \
			 -button "add_default_budgets"]
  lappend prop_list [list {Reset Budget} "" \
			 -button "add_default_budgets -reset"]

# old
#  use_init TIMING_DATA(output_driver) MMI_BUFD:out
#  use_init TIMING_DATA(input_register) MMI_FFB:d

#  lappend prop_list [list {Default Output Driver:port} \
			 TIMING_DATA(output_driver) -entry]
#  lappend prop_list [list {Default Input Register:port} \
			 TIMING_DATA(input_register) -entry]

  lappend prop_list [list {Default Internal Input Delay} \
			 TIMING_DATA(int_input_budget) -entry]
  lappend prop_list [list {Default Internal output Delay} \
			 TIMING_DATA(int_output_budget) -entry]

  lappend prop_list [list {Default Output Drive Resistance} \
			 TIMING_DATA(int_drive_res) -entry]
  lappend prop_list [list {Default Input Capacitance} \
			 TIMING_DATA(int_cap) -entry]

  lappend prop_list [list {Clocks} TIMING_DATA(clk_names) -entry]

  use_init TIMING_DATA($cell,lib) \
      [file rootname [lindex [cell_info $cell] 1]].lib

  lappend prop_list [list {Lib Filename} \
			 TIMING_DATA($cell,lib) -entry]

  use_init TIMING_DATA(lib2db) 1
  lappend prop_list [list {Convert to db} \
			 TIMING_DATA(lib2db) -binary]

  lappend prop_list [list {lib2db setup} \
			 TIMING_DATA(lib2db_setup) -entry]
  lappend prop_list [list {lib2db command} \
			 TIMING_DATA(lib2db,command) -entry]

  # popup window
  set ret [prop_menu2 -message $message -title $title $prop_list]

  if {$ret == 0} {
    # user hit cancel
    return ""
  }

  tim_build_timing_model
}


proc speedy_build_timing_model {} -desc {
  builds a timing model using speedy for the current cell using the budgets
  NOTE: doesn't work and is incomplete.  Speedy doesn't handles buses, etc.
} {

  global TIMING_DATA

  # write the lib file
  set cell [lay_editcell]
  set file $TIMING_DATA($cell,lib)
  set tofile $file.BAK

  if {![catch "file rename -force -- $file $tofile"]} {
    puts "Moved file \"$file\" to \"$tofile\"."
  }

  # make sure speedy is loaded
#  util_load_pkg speedy_package.so
  util_load_pkg /volume/mmi/src/speedy/speedy_package.so

  # use speedy
  speedy_command new_design $cell

  # Speedy bitches if you do this twice, so do it just once.
  global TIM_SPEEDY_HAS_READ_LIBFILE
  if {[use_first TIM_SPEEDY_HAS_READ_LIBFILE] == ""} {
    speedy_command read_libfile $TIMING_DATA(lib_file)
    set TIM_SPEEDY_HAS_READ_LIBFILE 1
  }

#  speedy_command global_timing


  # find clocks and ignore
  foreach clk $TIMING_DATA(clk_names) {
    # so these won't be added
    set trace($clk) 1
  }

  foreach label_info [db_search_labels] {
    struct max_label l $label_info

    set name ${l.text}

    if {[info exists trace($name)]} {
      # ignore dups
      continue
    }
    set trace($name) 1

    set kind ${l.kind}

    if {$kind == "inout"} {
      msg "Warning: changing port $name form kind inout to input for lib file."
      set kind input
    }

    # note: speedy_command add_ext... takes values in ns.

# TODO: load .lib into speedy and other setup

    switch $kind {
      input { 

	set actual [fplan_db_pin getprop $name actual]
	set budget [string trim [fplan_db_pin getprop $name budget] <>]
	set arrival [use_first actual budget TIMING_DATA(arrival_time)]

	speedy_command add_extconn_for_limited_icon_creator \
	    $name $kind $TIMING_DATA(input_register) \
	    [expr [parse_pp_number $arrival] * 1.0e9]
      }

      output { 

	set actual [fplan_db_pin getprop $name actual]
	set budget [string trim [fplan_db_pin getprop $name budget] <>]
	set departure [use_first actual budget TIMING_DATA(departure_time)]

	speedy_command add_extconn_for_limited_icon_creator \
	    $name $kind $TIMING_DATA(output_driver) \
	    [expr [parse_pp_number $departure] * 1.0e9]
      }
    }
  }

  speedy_command write_libfile $file
}


proc tim_build_timing_model {} -desc {
  builds a simple .lib timing model for the current cell using the budgets
} {

  global TIMING_DATA MAX_VERSION

  # write the lib file
  set cell [lay_editcell]
  set file $TIMING_DATA($cell,lib)
  set tofile $file.BAK

  if {![catch "file rename -force -- $file $tofile"]} {
    puts "Moved file \"$file\" to \"$tofile\"."
  }

  # find clocks and ignore
  foreach clk $TIMING_DATA(clk_names) {
    # so these won't be added
    set trace($clk) 1
  }

  # open to write the lib file
  if {[catch "open $file w" msg]} {
    # error
    max_error -abort "ERROR: Can't open $file: $msg"
    return 0
  }
  set FILE_ID $msg

  puts $FILE_ID "library ($cell) \{"
  puts $FILE_ID "comment : \"Created by MAX $MAX_VERSION on [clock format [clock seconds]]\";"

  puts $FILE_ID "delay_model : table_lookup;"
  puts $FILE_ID "lu_table_template(li2X2) \{"
  puts $FILE_ID "variable_1 : total_output_net_capacitance;"
  puts $FILE_ID "variable_2 : input_net_transition;"
  puts $FILE_ID "\tindex_1 (\"0, 1\");"
  puts $FILE_ID "\tindex_2 (\"0, 1\");"
  puts $FILE_ID "\}"

  puts $FILE_ID "time_unit : \"1ns\";"
  puts $FILE_ID "capacitive_load_unit (1.0,pf);"

  # find busses
  set names ""
  foreach label_info [db_search_labels] {
    struct max_label l $label_info

    set name ${l.text}

    if {[info exists trace($name)]} {
      # ignore dups
      continue
    }
    set trace($name) 1

    lappend names $name

    setl {root msb lsb} [split $name "\[:\]"]
    set kinds($root) ${l.kind}
  }

  # write bus definitions to .lib
  foreach name [nlt_bussify $names] {
    set width [bus_width $name]
    if {$width > 1} {
      # get msb, lsb

      setl {root msb lsb} [split $name "\[:\]"]

      if {[info exists trace($msb,$lsb)]} {
	# already got one of these
	continue
      } 
      set trace($msb,$lsb) 1

      puts $FILE_ID "type (bus${msb}_$lsb) \{"
      puts $FILE_ID "\tbase_type : array;"
      puts $FILE_ID "\tdata_type : bit;"
      puts $FILE_ID "\tbit_width : $width;"
      puts $FILE_ID "\tbit_from : $msb;"
      puts $FILE_ID "\tbit_to : $lsb;"
      if {$msb > $lsb} {
	puts $FILE_ID "\tdownto : true;"
      } else {
	puts $FILE_ID "\tdownto : false;"
      }
      puts $FILE_ID "\}"
    }
  }

  puts $FILE_ID "cell ($cell) \{"
  # add max area in um2
  setl {x1 y1 x2 y2} [db_bbox -user]
  puts $FILE_ID "\tarea : [expr ($x2 - $x1) * ($y2 - $y1)];"

  # add a clock input
  set clk [lindex $TIMING_DATA(clk_names) 0]

  puts $FILE_ID "\tpin ($clk) {"
  puts $FILE_ID "\t\tdirection : input;"
  puts $FILE_ID "\t\tcapacitance : 0.000;"
  puts $FILE_ID "\t\tclock : true;"
  puts $FILE_ID "\t}"

  foreach name [nlt_bussify $names] {

    if {[bus_width $name] > 1} {
      # bus

      setl {root msb lsb} [split $name "\[:\]"]
      set kind $kinds($root)

      if {$kind == "inout"} {
	msg "Warning: changing port $name from kind inout to input for lib file."
	set kind input
      }
      
      puts $FILE_ID "\tbus ($root) \{"
      puts $FILE_ID "\tbus_type : bus${msb}_$lsb;"
      puts $FILE_ID "\tdirection : $kind;"

      foreach bit [bus_expand $name] {
	_tim_make_pin_for_lib $FILE_ID $bit $kind $clk
      }

      # close bus
      puts $FILE_ID "\t\}"

    } else {
      # scalar
      setl {root msb lsb} [split $name "\[:\]"]
      set kind $kinds($root)

      if {$kind == "inout"} {
	msg "Warning: changing port $name from kind inout to input for lib file."
	set kind input
      }

      _tim_make_pin_for_lib $FILE_ID $name $kind $clk
    }
  }

  # close cell
  puts $FILE_ID "\}"

  # close library
  puts $FILE_ID "\}"

  # close the tempfile
  close $FILE_ID

  puts "Wrote timing file \"$file\" for cell \"$cell\"."

  if {$TIMING_DATA(lib2db)} {
    # convert ot db
    set out_file [file rootname $file].lib2db
    lib2db $file $cell $out_file {see_output 1}
  }

  return 1
}


proc _tim_make_pin_for_lib {FILE_ID name kind clk} -desc {
  adds .lib info for a given pin
} {

  global TIMING_DATA

  # in pF
  set max_cap 1.0

  switch $kind {
    input {
      puts $FILE_ID "\tpin ($name) \{"
      puts $FILE_ID "\t\tdirection : input;"

      # convert to pf.
      set actual [string trim [fplan_db_pin getprop $name int_cap] <>]
      set value [use_first actual TIMING_DATA(int_cap)]
      set input_cap [expr [parse_pp_number value] / 1.0e-12]

      puts $FILE_ID "\t\tcapacitance : $input_cap;"
      puts $FILE_ID "\t\ttiming() \{"
      puts $FILE_ID "\t\t\ttiming_type : setup_rising;"
      puts $FILE_ID "\t\t\trelated_pin : \"$clk\";"

      set actual [fplan_db_pin getprop $name int_actual]
      set budget [string trim [fplan_db_pin getprop $name int_budget] <>]
      set arrival [use_first actual budget TIMING_DATA(int_input_budget)]

      # convert to .lib units
      set value [expr [parse_pp_number $arrival] * 1.0e9]

      puts $FILE_ID "\t\t\trise_constraint(scalar) \{"
      puts $FILE_ID "\t\t\t\tvalues(\"$value\");"
      puts $FILE_ID "\t\t\t\}"

      puts $FILE_ID "\t\t\tfall_constraint(scalar) \{"
      puts $FILE_ID "\t\t\t\tvalues(\"$value\");"
      puts $FILE_ID "\t\t\t\}"

      puts $FILE_ID "\t\t\}"
      puts $FILE_ID "\t\}"
    }

    output {
      puts $FILE_ID "\tpin ($name) \{"
      puts $FILE_ID "\t\tdirection : output;"
      puts $FILE_ID "\t\ttiming() \{"
      puts $FILE_ID "\t\t\ttiming_type : rising_edge;"
      puts $FILE_ID "\t\t\trelated_pin : \"$clk\";"

      set actual [fplan_db_pin getprop $name int_actual]
      set budget [string trim [fplan_db_pin getprop $name int_budget] <>]
      set departure [use_first actual budget TIMING_DATA(int_output_budget)]

      # convert to .lib units
      set value [expr [parse_pp_number $departure] * 1.0e9]

      # since cap is 1pF and units are ns.  (resistance in ohms)
      set tmp [string trim [fplan_db_pin getprop $name int_drive_res] <>]
      set resistance [use_first tmp budget TIMING_DATA(int_driver_res)]

      set delta [expr 0.6 * $resistance / ($max_cap*1000)]

      # in ns
      set slew 0.05
      set slew_loaded [expr $slew + $delta]

      # assumes 1 pF for Cap
      set value_loaded [expr $value + $delta]

      puts $FILE_ID "\t\t\tcell_rise(li2X2) \{"
      # output capacitance
      puts $FILE_ID "\t\t\t\tindex_1(\"0.00,$max_cap\");"
      # input slew of clock -- unimportant
      puts $FILE_ID "\t\t\t\tindex_2(\"0.01,0.50\");"
      puts $FILE_ID "\t\t\t\tvalues(\"$value,$value\",\\"
      puts $FILE_ID "\t\t\t\t\t\"$value_loaded,$value_loaded\");"
      puts $FILE_ID "\t\t\t\}"

      puts $FILE_ID "\t\t\tcell_fall(li2X2) \{"
      # output capacitance
      puts $FILE_ID "\t\t\t\tindex_1(\"0.00,$max_cap\");"
      # input slew of clock -- unimportant
      puts $FILE_ID "\t\t\t\tindex_2(\"0.01,0.50\");"
      puts $FILE_ID "\t\t\t\tvalues(\"$value,$value\",\\"
      puts $FILE_ID "\t\t\t\t\t\"$value_loaded,$value_loaded\");"
      puts $FILE_ID "\t\t\t\}"

      puts $FILE_ID "\t\t\trise_transition(li2X2) \{"
      # output capacitance
      puts $FILE_ID "\t\t\t\tindex_1(\"0.00,$max_cap\");"
      # input slew of clock -- unimportant
      puts $FILE_ID "\t\t\t\tindex_2(\"0.01,0.50\");"
      puts $FILE_ID "\t\t\t\tvalues(\"$slew,$slew\",\\"
      puts $FILE_ID "\t\t\t\t\t\"$slew_loaded,$slew_loaded\");"
      puts $FILE_ID "\t\t\t\}"
      
      puts $FILE_ID "\t\t\tfall_transition(li2X2) \{"
      # output capacitance
      puts $FILE_ID "\t\t\t\tindex_1(\"0.00,$max_cap\");"
      # input slew of clock -- unimportant
      puts $FILE_ID "\t\t\t\tindex_2(\"0.01,0.50\");"
      puts $FILE_ID "\t\t\t\tvalues(\"$slew,$slew\",\\"
      puts $FILE_ID "\t\t\t\t\t\"$slew_loaded,$slew_loaded\");"
      puts $FILE_ID "\t\t\t\}"

      puts $FILE_ID "\t\t\}"

      puts $FILE_ID "\t\}"
    }
  }
}


use_init TIMING_DATA(lib2db_setup) "module add synopsys/2000.11"
use_init TIMING_DATA(lib2db,command) lc_shell

proc lib2db {file cell out_file {see_output 1}} -desc {
  convert a lib file to a db file using synopsys
} {

  global TIMING_DATA

  puts "\nConverting lib to db ..."

  if {$TIMING_DATA(lib2db_setup) == ""} {
    set setup ""
  } else {
    set setup "$TIMING_DATA(lib2db_setup) ; "
  }

  # lc_shell -no_init -x "read_lib $file ; write_lib $cell ; quit"

  if {$see_output == 0} {
    # direct all output to output file
    if {[catch "exec csh -c \"$setup$TIMING_DATA(lib2db,command) -no_init -x \\\"read_lib $file ; write_lib $cell ; quit\\\" >&! $out_file\"" msg]} {
      puts $msg
      return 69
    }

  } else {
    # direct all output to screen and output file
    if {[catch "exec csh -c \"$setup$TIMING_DATA(lib2db,command) -no_init -x \\\"read_lib $file ; write_lib $cell ; quit\\\" |& tee $out_file >&! [exec tty]\"" msg]} {
      puts $msg
      return 69
    }
  }

  # show the user any error messages except bogus ones
  if {![catch "exec grep -i error: $out_file" msg]} {
    puts $msg
  }

  puts "lib2db completed.\n"

  return 0
}


proc bus_width {name} -desc {

Returns the bus width of <name>.  Only understands simple bus notation. 

For example: 

        sue> bus_width {foo[3:0]}
        4
        sue> bus_width bar
        1
} {

  if {$name == ""} {
    return 0
  }

  set name_list [split $name "\[:\]"]

  if {[llength $name_list] < 4} {
    # check for verilog syntax global, i.e. 2'b01
    if {[regexp {^([0-9]+)'} $name tmp width]} {
      return $width
    }

    # not a bus
    return 1
  }

  return [expr abs([lindex $name_list 1] - [lindex $name_list 2]) + 1]
}


use_init MAX_BUS_WIDTH 1024

proc bus_expand {name {format "%d"}} -type user -desc {

Expands <name> into a list of all of its bits and returns it.  Returns
bits in lsb to msb order.  Also expands verilog binary constant
notation like 2'b01.  Does not expand comma separated list or other
syntax.

For example: 

        sue> bus_expand {foo[3:0]}
        foo[0] foo[1] foo[2] foo[3]
        sue> bus_expand bar
        bar
        sue> bus_expand 2'b01
        vdd gnd
} {

  global MAX_BUS_WIDTH

  # null names return null names
  if {$name == ""} {
    return 
  }

  # remove any leading zeros in buses - tcl thinks it means octal
  regsub -all {(\[)(0)*([0-9])} $name {[\3} name
  regsub -all {(:)(0)*([0-9])} $name {:\3} name

  set name_list [split $name "\[:\]"]

  if {[set len [llength $name_list]] < 4} {
    # not a bus

    if {$len == 3} {
      # single bit of a bus
      set bit [lindex $name_list 1]

      if {[catch "expr $bit"]} {
	error "Invalid bus name \"$name\"."
	return $name
      }

      return "[lindex $name_list 0]\[[format $format $bit]\]"
    }

    if {[regexp {'(b|h|d|o)} $name]} {
      # this is a constant, expand and possible pad
      global GLOBAL_TRANSLATIONS NETLIST_TYPE

      # does the real work
      set bnum [const_to_binary $name]

      regsub -all {0|1} $bnum "1'b& " bus

      if {[info exists GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b0)]} {
	regsub -all {1'b0} $bus $GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b0) bus
      }

      if {[info exists GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b1)]} {
	regsub -all {1'b1} $bus $GLOBAL_TRANSLATIONS($NETLIST_TYPE,1'b1) bus
      }

      return [lreverse $bus]
    }

    return $name
  }

#  setl {root msb lsb} $name_list
    set root [lindex $name_list 0]
    set msb [lindex $name_list 1]
    set lsb [lindex $name_list 2]

  if {[catch "expr $lsb"] || [catch "expr $msb"]} {
    # error
    error "Invalid bus name \"$name\"."
    return $name
  }

  if {[expr abs($lsb - $msb)] > $MAX_BUS_WIDTH} {
    # error
    error "Invalid bus name \"$name\".  Bus too large, increase MAX_BUS_WIDTH (set to $MAX_BUS_WIDTH) if necessary."
    
    return $name
  }

  if {$lsb > $msb} {
    # count down
    set incr -1
  } else {
    set incr 1
  }

  set list ""
  for {set i $lsb} {$i != $msb} {incr i $incr} {
    lappend list $root\[[format $format $i]\]
  }
  lappend list $root\[[format $format $i]\]

  # lappend adds curly brackets -- lose them
  regsub -all {\{|\}} $list {} list

  return $list
}
