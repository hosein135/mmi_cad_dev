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

set RCSVERSION(label.tcl) { $Revision: 1.41 $ }

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
  popup select net by name menu, then select all nets connected to a given label name
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
  Return label pos from label_info returned by sel_what or db_search.
} {
  return [lindex $lab_info 5]
}

proc label_lbox {} -desc {
  Popup text command documentation
} {
  global FPLAN MAX_DEVELOPER LISTBOX_FONT
  global _LABEL_LBOX

  # 8/22/01: Switch to old code if floorplanner is not being used.
  # Eventually, we will use this code for all labels, but not for this release.
  global FPLAN
  if {[use_first FPLAN(exists) '0] == 0} {edit_label;return}

  use_init _LABEL_LBOX(view) "basic"     ;# Can be "basic", "placement", "timing"
  use_init _LABEL_LBOX(bussify) 1	 ;# Binary
  use_init _LABEL_LBOX(selection) "selected"  ;# Can be "selected" or "all"
  set _LABEL_LBOX(match) ""

  set w .text_list

  # Window contents:
  #   View: o selected ports; o all ports
  #   View: o basic info; o placement info; o timing info
  #   Show: o as bits; o as busses  (binary)

  #catch {destroy $w}
  #toplevel $w -borderwidth 0
  #wm geometry $w "600x500[_relative_origin]"
  #wm title $w "Edit Ports"
  #wm maxsize $w 1000 1000
  #wm minsize $w 100 100
  util_win_create $w "Edit Ports"
  wm geom $w "600x500"

  # end build of toplevel

  set tw 10  ;# Width of left hand titles in radiobutton area.

  set font $LISTBOX_FONT
  frame $w.f1 -borderwidth 0 -relief raised
  label $w.f1.l1 -relief flat -font $font -width $tw -text "View:"
  set common "-command _label_lbox_fill -font $font"
  set lvar "-variable _LABEL_LBOX(selection)"
  eval radiobutton $w.f1.r11 $common $lvar -text {{selected text}} -value selected
  eval radiobutton $w.f1.r12 $common $lvar -text {{all text}} -value all

  frame $w.f2 -borderwidth 0 -relief raised
  label $w.f2.l2 -relief flat -font $font -width $tw -text "List:"
  set lvar "-variable _LABEL_LBOX(view)"
  eval radiobutton $w.f2.r21 $common $lvar -text basic -value basic
  eval radiobutton $w.f2.r22 $common $lvar -text placement -value placement
  eval radiobutton $w.f2.r23 $common $lvar -text {{timing budget}} -value budget

  frame $w.f3 -borderwidth 0 -relief raised
  label $w.f3.l3 -relief flat -font $font -width $tw -text "Show:"
  set lvar "-variable _LABEL_LBOX(bussify)"
  eval radiobutton $w.f3.r31 $common $lvar -text {{as bits}} -value 0
  eval radiobutton $w.f3.r32 $common $lvar -text {{as busses}} -value 1

  frame $w.f4 -borderwidth 0 -relief raised
  label $w.f4.l4 -relief flat -font $font -width $tw -text "Match:"
  eval entry $w.f4.e -font $font -relief raised -textvariable _LABEL_LBOX(match) 
  bind $w.f4.e <Return> "_label_lbox_fill"

  pack $w.f1.l1 $w.f1.r11 $w.f1.r12 -side left
  pack $w.f2.l2 $w.f2.r21 $w.f2.r22 $w.f2.r23 -side left
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
  frame $w.fb -borderwidth 0 -relief raised

  set help {Button-1 selects.  Control-Button-1 adds to selection. \
    Shift-Button-1 selects all ports from the previously\
    selection to the mouse point.  "Edit" button, Double-Button-1 or Button-2\
    brings up edit dialog box on the selected ports. 
    The "Match" box is used to filter listed text.  If non-empty, only lines that match the\
    regular expression are displayed.  The line can match anywhere, not just the port name.}

  label $w.info -width 20 -anchor e
  button $w.fb.edit -text "Edit Ports" -command "_label_lbox_sel -edit"
  button $w.fb.refresh -text "Refresh" -command "_label_lbox_fill"
  button $w.fb.close -text "Close" -command "catch {util_win_destroy $w}"
  # We want to run the placer on the current cell, regardless of whether other cells are selected.
  button $w.fb.placer -text "Run placer" -command "fplan_edit_selected_ports -editcell 1"
  button $w.fb.help -text "Help" -command "prop_dialog -title {Edit Ports Help} {$help}"
  pack $w.fb.close -side left -padx 5 -pady 1
  pack $w.fb.refresh $w.fb.edit -side left -padx 5 -pady 1
  if {$FPLAN(exists)} {
    pack $w.fb.placer $w.fb.refresh -side left -padx 5 -pady 1
  }
  pack $w.fb.help -side left -padx 5 -pady 1
  pack $w.info -in $w.fb -side right -anchor e
  pack $w.fb -side bottom

  util_win_finish $w -place normal
  
  _label_lbox_fill
}


proc _label_lbox_sel {{-select} {-edit}} {
  global LABEL _LABEL_MAP

  set w .text_list.items.list

  set indicies [$w curselection]
  set label_list ""
  foreach index $indicies {
    set label_list [concat $label_list $_LABEL_MAP($index)]

    #set entry [$w get $index]
    #if {$entry == ""} {return}
    #set p [string first " " $entry]
    #if {$p == -1} {
    #  lappend idlist $entry
    #} else {
    #  lappend idlist [string range $entry 0 [expr $p-1]]
    #}
  }

  set use_nl [nl2_loaded -cell [lay_rootcell]]

  if {$select} {

    sel_clear
    db_flyline -delete

    # Things in the idlist can be individual ports (x or a[1]) or busses (a[0:7]).
    foreach lab_info $label_list {
      set port [labinfo_text $lab_info]
      sel_labels -more -text $port
      if {$use_nl} {
	fplan_sel_net -more $port
      }
    }
    # This could be time consuming.  Skip it.
    # .text_list.info config -text "Selected: [llength [sel_what_l labels]]"
  }

  if {$edit} {
    # Bring up the label editor on the selected labels.
    if {[label_edit_new $label_list] == 0} {
      # cancelled
      return
    }
  }


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

proc label_edit_new {lab_info_list} -desc {
  Edit labels specified.
} {
  global _LABEL_LBOX


  # TODO: Edit all label info in a single prop_menu.

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

  # Get basic information on label from max.

  # The "size" field is "point" or "box" and is synthesized from other label info.
  set basic_list "layer x1 y1 x2 y2 pos text kind size"
  foreach thing $basic_list {set LABEL($thing) ""}

  # Put current values of label into LABEL array.
  # If multiple labels have different values, set to "<various>"
  foreach lab_info $lab_info_list {
      struct max_label l $lab_info
      set l.pos [string tolower ${l.pos}] ;# The pos is too imposing as upper-case.
      set l.size [expr {(${l.x1}==${l.x2}&&${l.y1}==${l.y1}) ? "point" : "box"}]

      foreach thing $basic_list {
	set lab_value [set l.$thing]
	if {$LABEL($thing) == ""} {
	  set LABEL($thing) $lab_value
	} elseif {$LABEL($thing) != $lab_value} {
	  set LABEL($thing) "<various>"  ;# Two labels have different values of $thing.
	}
      }
  }

  switch -- $_LABEL_LBOX(view) {
  basic {
    # Edit basic information on label.

    set layer_choices [techinfo wire_layers]
    set pos_choices "northwest north northeast west center east southwest south southeast"

    set prop_list ""
    # Add the label name(s) to prop_menu
    # If only one label selected, user can change the label name, otherwise it is just a comment.
    lappend prop_list [list text names [expr {[llength $name_list_all]==1 ? "-entry" : "-label"}]]

    lappend prop_list [list layer LABEL(layer) -popup $layer_choices]
    lappend prop_list [list kind LABEL(kind) -choice {input output inout local global comment}]
    lappend prop_list [list {text position} LABEL(pos) -choice $pos_choices]
    # These are -entry instead of -number because they may be "<various>"
    lappend prop_list [list x LABEL(x1) -entry -when {$LABEL(size)=="point"}]
    lappend prop_list [list y LABEL(y1) -entry -when {$LABEL(size)=="point"}]
    lappend prop_list [list x1 LABEL(x1) -entry -when {$LABEL(size)=="box"}]
    lappend prop_list [list y1 LABEL(y1) -entry -when {$LABEL(size)=="box"}]
    lappend prop_list [list x2 LABEL(x2) -entry -when {$LABEL(size)=="box"}]
    lappend prop_list [list y2 LABEL(y2) -entry -when {$LABEL(size)=="box"}]
    lappend prop_list [list type LABEL(size) -choice {point box} -reload]
    if {![prop_menu2 -title "max edit text" $prop_list]} {
      return 0  ;# cancelled
    }

    # Basic info is updated back to labels below.
  }

  placement {
    # Edit placement info, including x,y from basic info.

    set disp_list "place loc bitloc layerspec"
    foreach thing $disp_list {set display($thing) ""}

    # Put current values of label into LABEL array.
    # If multiple labels have different values, set to "<various>"
    foreach lab_info $lab_info_list {
      set id [labinfo_text $lab_info]
      foreach thing $disp_list {
	set lab_value [fplan_db_pin getprop $id $thing]
	if {$display($thing) == ""} {
	  set display($thing) $lab_value
	} elseif {$display($thing) != $lab_value} {
	  set display($thing) "<various>"  ;# Two labels have different values of $thing.
	}
      }
    }

    set prop_list ""
    lappend prop_list [list name names -label]
    lappend prop_list [list place display(place) -choice {unplaced placed fixed}]
    lappend prop_list [list loc display(loc) -popup {left right top bottom ""}]
    lappend prop_list [list bitloc display(bitloc) -entry]
    lappend prop_list [list layerspec display(layerspec) -entry]
    lappend prop_list [list "current layer" LABEL(layer) -entry]
    lappend prop_list [list "current x" LABEL(x1) -entry]
    lappend prop_list [list "current y" LABEL(y1) -entry]

    if {![prop_menu2 -title "max edit text" $prop_list]} {
      return 0  ;# cancelled
    }

    foreach lab_info $lab_info_list {
      set id [labinfo_text $lab_info]
      foreach thing $disp_list {
	if {$display($thing) != "<various>"} {
	  fplan_db_pin setprop $id $thing $display($thing)
	}
      }
    }
  }

  budget {
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

  _label_lbox_fill  ;# Update changes in listbox, if mapped.
}


proc select_end_label_hook {} -desc {
  Called when selection changes.  Update the label list box, if any.
} {
  if {[winfo exists .text_list]} {
    _label_lbox_fill
  }
}


proc _label_lbox_fill {} -desc {
  fill list box with variables matching apropos pattern;  highlight selected labels.
} {
  global _LABEL_LBOX	;# Options for this command.
  global _LABEL_MAP     ;# Maps listbox indicies to label_info structures.

  catch {unset _LABEL_MAP}

  set plist .text_list.items.list
  if {![winfo exists $plist]} {return}

  if {[$plist size] > 0} { $plist delete 0 end }


  set sel_labels [sel_what_l labels]
  # Make this array for use later.
  foreach lab $sel_labels {
    set sel_label_hash($lab) 1
  }

  if {$_LABEL_LBOX(selection) == "all"} {
    set label_list [db_search_l labels -non_hier]
  } else {
    set label_list $sel_labels
  }

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
      } else {
	# It is not a bus.  Could be multiple instances
	# of each label, though, so save all in a list.
	lappend bits2labels($id) $lab_info
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
    }
  }

  # Fill in the column header label.
  switch -- $_LABEL_LBOX(view) {
    basic {
      # This is the list of things from the label that we will display:
      set disp_list "kind layer pos x1 y1"
      set format "%-25s %-12s %-12s %-12s %-12s %-12s"
      set header [eval format {$format} port $disp_list]
    }
    placement {
      # These are the placement properties we will display:
      set disp_list "place loc bitloc layerspec"
      set format "%-25s %-12s %-12s %-12s %-12s"
      set header [eval format {$format} port $disp_list]
    }
    budget {
      set format "%-25s %-12s %-12s %-12s %-12s %-12s"
      set disp_list "Slack Budget ActDelay Driver Cap"
      set header [eval format {$format} port $disp_list]
    }
    default {
      error "_label_lbox internal error"
    }
  }
  .text_list.header configure -text $header


  set lbox_cnt 0    ;# Count of total number of labels displayed, taking busses into account.
  set lbox_index 0  ;# Index in listbox.
  foreach sortkey [lsort [array names map]] {
    set lbox_name [lindex $sortkey 0]  ;# Its the sub name, or port name with optional "(count)" appended.
    switch -- $_LABEL_LBOX(view) {

      basic {
	# Set each displayed thingy to "<various>" if there are two that are different.

	# Init display array to empty
	foreach thing $disp_list {set display($thing) ""}

	foreach lab_info $map($sortkey) {
	  struct max_label l $lab_info
	  set l.pos [string tolower ${l.pos}]  ;# This pos is too imposing as upper case.
	  foreach thing $disp_list {
	    set lab_value [set l.$thing]
	    if {$display($thing) == ""} {
	      set display($thing) $lab_value
	    } elseif {$display($thing) != $lab_value} {
	      set display($thing) "<various>"  ;# Two labels have different values of $thing.
	    }
	  }
	}

	set entry [format $format $lbox_name $display(kind) $display(layer) $display(pos) $display(x1) $display(y1)]
      }

      placement {
	# Init display array to empty
	foreach thing $disp_list {set display($thing) ""}

	foreach lab_info $map($sortkey) {
	  set id [labinfo_text $lab_info]
	  foreach thing $disp_list {
	    set lab_value [fplan_db_pin getprop $id $thing]
	    if {$display($thing) == ""} {
	      set display($thing) $lab_value
	    } elseif {$display($thing) != $lab_value} {
	      set display($thing) "<various>"  ;# Two labels have different values of $thing.
	    }
	  }
	}

	set entry [format $format $lbox_name $display(place) $display(loc) $display(bitloc) $display(layerspec)]
      }

      budget {
	set entry [format $format $lbox_name TODO TODO TODO TODO TODO]
      }
    }

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

  # This could be time consuming to compute when selection is changed, so display total instead.
  # User can see number of selected ports by setting "View:" to "selected".
  #.text_list.info config -text "Selected: [llength $sel_labels]"
  .text_list.info config -text "Port Count: $lbox_cnt"
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
