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

set RCSVERSION(selc.tcl) { $Revision$ }


proc _selc_chk_valid_cell {{gcells_ok 0}} -desc {
  Check selected cell for validity; warn and return 0 if not valid.
} {
  set cells [sel_what cells -limit 2]
  if { $cells == "" } {
    warning "no cells selected"
    return 0
  }
  struct max_cell c $cells
  if {[is_gcell ${c.def}]} {
    if { $gcells_ok == 0 } {
      warning "can not operate on gcell"
      return 0
    } else {
      # Make sure gcell is in current cell.
      # TODO: This does not work for edit-in-place!!!!
      if { ${c.path} != "" } {
	warning "can only edit gcells in current cell"
	return 0
      }
    }
  }
  return 1
}

proc _selc_action {cmd} -desc {
  execute cmd only if selected cell is not a gcell
} {
  global SEL_CELL ;# Required by command being evaled!
  switch $cmd {
  "edit" {
      if { $SEL_CELL(windex) < 0 } {
	mode_pop
	edit_pop [expr -$SEL_CELL(windex)]
      } elseif { $SEL_CELL(windex) == 0 } {
	warning "Already editing the current cell"
	return
      } else {
	# TODO: if its a gcell, need to make sure it is
	# in the current directory.
	if {[_selc_chk_valid_cell 1]} {
	  mode_pop;edit_push
	}
      }
      i_cmd_between
    }
  "edit_in_place" {
      if { $SEL_CELL(windex) < 0 } {
	warning "Can only edit-in-place cells that are sub-cells of the current cell"
	return
      } elseif { $SEL_CELL(windex) == 0 } {
	warning "Already editing the current cell"
	return
      }
      if {[_selc_chk_valid_cell 1]} {
	mode_pop;edit_push in_place -point [list $SEL_CELL(x) $SEL_CELL(y)]
      }
      i_cmd_between
    }
  "props" {
      if { $SEL_CELL(windex) <= 0 } {
	warning "Can only change properies of cells that are\
	  sub-cells of the current cell"
	return
      }
      if {[_selc_chk_valid_cell 1]} {
	mode_pop;edit_any props
      }
      i_cmd_between
  }
  "array" {
      if { $SEL_CELL(windex) <= 0 } {
	warning "Can only change array of cells that are\
	  sub-cells of the current cell"
	return
      }
      if {[_selc_chk_valid_cell 1]} {
	mode_pop;array_cell
      }
      i_cmd_between
  }
  "expand" {
      if { $SEL_CELL(windex) <= 0 } {
	warning "Can only Expand Internals of Sub-Cells of the current cell"
	return
      }
      if { ! [_selc_chk_valid_cell]} {
	# message printed by sel_chk_valid_cell
	return
      }
      setl {old_depth old_id old_def old_exp} \
	[lindex $SEL_CELL(list) [expr $SEL_CELL(windex) - 1]]

      # Expand cell, and fill with cells visible after expanding.
      lay_internals;
      _selc_hier_fill

      # Expanding/unexpanding cells can add/subtract cells
      # throughout the window, if the same cell appears more than
      # once, because all cells with the same def are affected at once.
      # So to preserve the current radio button, we have to search
      # for it in the new list.
      set SEL_CELL(windex) [expr [lsearch $SEL_CELL(list) \
		"$old_depth $old_id *"] + 1]

      # Took this out.  Didnt like it because it changes the currently
      # selected cell, which is kind of confusing.
      if { 0 && ${old_exp} == "" } {
	# We have just expanded a previously unexpanded cell.
	# As a convenience, automatically select the first sub-cell
	# of the newly expanded cell, if any.  We have to search for the
	# correct "depth" value, because there can be multiple cells
	# selected at the current hierarchy level.
	# Note: windex starts at 1, cell_list indicies at 0.
	set llen [llength $SEL_CELL(list)]
	for {set i $SEL_CELL(windex)} {$i < $llen} {incr i} {
	  setl {depth id def exp} [lindex $SEL_CELL(list) $i]
	  if { $depth > $old_depth } {
	    # 1/31/02: change from sel_cell3 to sel_cell
	    sel_cell $id
	    set SEL_CELL(windex) [expr $i+1]
	    break
	  }
	}
      }
    }
  "hide" {
      if { $SEL_CELL(windex) <= 0 } {
	warning "Can only Hide Internals of Sub-Cells of the current cell"
	return
      }
      if { ! [_selc_chk_valid_cell] } {
	# message printed by sel_chk_valid_cell
	return
      }
      # Save name of currently selected cell.
      setl {old_depth old_id old_def old_exp} \
	  [lindex $SEL_CELL(list) [expr $SEL_CELL(windex) - 1]]

      lay_internals -hide; 
      _selc_hier_fill

      # Expanding/unexpanding cells can add/subtract cells
      # throughout the window, if the same cell appears more than
      # once, because all cells with the same def are affected at once.
      # So to preserve the current radio button, we have to search
      # for it in the new list.
      set SEL_CELL(windex) [expr [lsearch $SEL_CELL(list) \
		"$old_depth $old_id *"] + 1]
    }
  }
  _selc_hier_update
}

proc _selc_hier_update {} -desc {
  Update buttons on Find Cell window.
} {
  global SEL_CELL ;# Required by command being evaled!
  set win $SEL_CELL(window)
  if {! [winfo exists $win] } {
    # Find Cell window has been closed
    return
  }

  set buttons [list edit edit2 props exp unexp]
  foreach but $buttons {
    $win.$but config -state disabled
  }

  if { $SEL_CELL(windex) < 0 } {
    # Active cell is above us in hierarchy
    $win.edit config -state normal
    sel_clear
    layt_box user $SEL_CELL(x) $SEL_CELL(y) $SEL_CELL(x) $SEL_CELL(y)
  } elseif { $SEL_CELL(windex) == 0 } {
    # Active cell is current cell
    sel_clear
    eval layt_box user [lay_bbox]
  } else {
    setl {depth id def exp} [lindex $SEL_CELL(list) [expr $SEL_CELL(windex)-1]]
    # 1/31/02: change from sel_cell3 to sel_cell
    sel_cell $id
    # TODO: if its a gcell, need to make sure it is
    # in the current directory.
    set cells [sel_what cells -limit 2]
    if { $cells == "" } {
      # Say what?
      return
    }
    struct max_cell c $cells ;# Gets the first one
    if {[is_gcell ${c.def}]} {
      if { ${c.path} == "" } {
	$win.props config -state normal
	$win.edit config -state normal
      }
    } else {
      $win.edit config -state normal
      $win.edit2 config -state normal
      $win.exp config -state normal
      $win.unexp config -state normal
      if { ${c.path} == "" } {
	$win.props config -state normal
      }
    }
  }
}

proc _selc_gate_keeper {event} {
  global SEL_CELL

  if {$event == "PUSH_TO" } {
    set SEL_CELL(list) ""
    set SEL_CELL(original_cell) [lay_editcell]
    _selc_finder

  } elseif {$event == "POP_FROM"} {

    if {$SEL_CELL(original_cell) == [lay_editcell]} {
      # Do NOT put an undo here.  There was nothing to undo!
      i_cmd_between_undos
    } else {
      i_cmd_between
    }
    catch {destroy $SEL_CELL(window)}
  }
}

proc selc_mode_enter {} -desc {
  Show/select/view cell hierarchy at any point.
} {
  mode_push sel_cpath
}

proc _selc_mode_define {} {
  global SEL_CELL

  mode_def sel_cpath _selc_gate_keeper "BUT-1 points at cell(s), BUT-3 edits selected cell"

  mode_bind -cmd 0 sel_cpath <Button-1> "_selc_finder"
  mode_bind -cmd 0 sel_cpath <Button-2> "mode_pop;move_something"
  mode_bind -cmd 0 sel_cpath <Button-3> "_selc_action edit"
  # Save the bindings so we can also use them on the cell finder window.
  set SEL_CELL(bindings) [list \
    [list f "_selc_finder"] \
    [list e "_selc_action edit"] \
    [list E "_selc_action edit_in_place"] \
    [list p "_selc_action props"] \
    [list i "_selc_action expand"] \
    [list I "_selc_action expand"] \
    [list <Control-i> "_selc_action hide"] \
    [list <Any-Control-c> "mode_pop"] \
    [list <Escape> "mode_pop"] \
    ]



  foreach binding $SEL_CELL(bindings) {
    setl {key cmd} $binding
    mode_bind -cmd 0 sel_cpath $key $cmd
  }
}



proc _selc_hier_fill {} -desc {
  Fill window SEL_CELL(window).wmain with cell hierarchy
  at point given by SEL_CELL(x),SEL_CELL(y). 
  On exit, SEL_CELL(list) contains the list of sub-cells under cursor.
} {
  global EDIT SEL_CELL DIALOG_FONT
  set wmain $SEL_CELL(window).main
  set x $SEL_CELL(x)
  set y $SEL_CELL(y)

  foreach wchild [winfo children $wmain] {
      catch { destroy $wchild }
  }
  set prepath ""
  set indentamount  "   " ;# Amount each child is indented

  label $wmain.ledit -text "Cell Hierarchy (well, almost)" -font $DIALOG_FONT
  pack $wmain.ledit -side top -expand 1 -fill x

  # First, add in edit stack, if any.
  set indent ""
  if { $EDIT(stack) != "" } {
    set n [llength $EDIT(stack)]
    setl {inst_path cells frame box} [lindex $EDIT(stack) [expr $n-1]]
    setl {root path} $cells
    set prepath "$root/"
    radiobutton $wmain.root -variable SEL_CELL(windex) -value [expr -$n] \
	-text "$root" -anchor w -command "_selc_hier_update"
    pack $wmain.root -side top -expand 1 -fill x
    while { $n > 0 } {
      set thingy [lindex $EDIT(stack) [expr $n-1]]
      setl {inst_path cells frame box} $thingy
      setl {root path} $cells
      append indent $indentamount
      if { $n == 1 } {
	#set text "$prepath$inst_path   <- Current Edit Cell"
	regsub {.*/} $inst_path "" text
	set text "$text  <- Current Edit Cell"
      } else {
	#set text "$prepath$inst_path"
	regsub {.*/} $inst_path "" text
      }
      radiobutton $wmain.e$n -variable SEL_CELL(windex) -value [expr -$n+1] \
	-text "$indent$text" -anchor w -command "_selc_hier_update"
      pack $wmain.e$n -side top -expand 1 -fill x
      append prepath "$inst_path/"
      incr n -1
    }
  } else {

    # Add current cell
    #set text "$prepath[lay_editcell]
    set text [lay_editcell]
    radiobutton $wmain.e0 -variable SEL_CELL(windex) -value 0 \
	-text "$text   <- Current Edit Cell" -anchor w \
	-command "_selc_hier_update"
    pack $wmain.e0 -side top -expand 1 -fill x
  }

  set cells [db_search cells -any_cell -area $x $y $x $y]

  set windex 1
  set cell_list ""
  foreach cell [split [string trim $cells] \n] {
    struct max_cell c $cell
    set fnd_any 1

    # cell_list is a list of elements:
    # 0. nesting depth of sub-cell; 1. full pathname of cell;
    # 2. is cell def; 3. expansion flag.
    set realid [cellinfo_name -array $cell]

    regsub -all {[^/]*} $realid "" slashes
    if {[is_gcell ${c.def}]} {
      set c.def "[gcell_typename ${c.def}] gcell"
    }

    regsub "expanded" ${c.expansion} "(viewed)" view_flag

    lappend cell_list [list [string length $slashes] \
		$realid ${c.def} $view_flag]
  }
  set cell_list [lsort -index 1 $cell_list]

  if { [llength $cell_list] == 0 } {
    label $wmain.none -text "No sub-cells under cursor" -font $DIALOG_FONT
    pack $wmain.none -side top -expand 1 -fill x
  } else {
    label $wmain.lab2 -text "Sub-Cells under cursor" -font $DIALOG_FONT
    pack $wmain.lab2 -side top -expand 1 -fill x
  }

  foreach cell $cell_list {
    setl {depth id def exp} $cell
    set newindent ""
    for {set j $depth} {$j > 0} {incr j -1} {
      append newindent $indentamount
    }
    #set text "$prepath$id   $def $exp"
    set text "$def $exp"
    radiobutton $wmain.r$windex -variable SEL_CELL(windex) -value $windex \
      -text "$indent$newindent$text" -anchor w \
      -command "_selc_hier_update"
    pack $wmain.r$windex -side top -expand 1 -fill x
    incr windex
  }

  set SEL_CELL(list) $cell_list
}

proc _selc_finder {} -desc {
  Part of "sel_cell" mode.  (not to be confused with "sel_cell" command)
} {
  global SEL_CELL DIALOG_FONT

  # Generate list of cells at current point

  setl {SEL_CELL(x) SEL_CELL(y)} [layt_point exact]
  # Reset index from any previous invocation.

  # Create the window

  #set oldFocus [focus]
  set w .find_cell
  set SEL_CELL(window) $w
  if {! [winfo exists $w] } {
    util_win_create $w "Find Cell"

    frame $w.main -relief sunken -bd 2
    pack $w.main -side top -fill x

    # Put the buttons in columns so they line up nicely.
    frame $w.buttons
    frame $w.buttons1
    frame $w.buttons2

    # Add buttons at bottom of window

    button $w.edit -text "Edit Cell" -font $DIALOG_FONT -padx 2 -pady 2 \
      -command "_selc_action edit"
    button $w.edit2 -text "Edit in Place" -font $DIALOG_FONT -padx 2 -pady 2\
      -command "_selc_action edit_in_place"
    button $w.props -text "Properties..." -font $DIALOG_FONT -padx 2 -pady 2 \
      -command "_selc_action props"
    button $w.exp -text "View Internals" -font $DIALOG_FONT -padx 2 -pady 2 \
      -command {_selc_action expand}
    button $w.unexp -text "Hide Internals" -font $DIALOG_FONT -padx 2 -pady 2 \
	-command {_selc_action hide}
    # Array is not used enough to justify a button on this menu.
    #button $w.array -text "Array..." -font $DIALOG_FONT -padx 2 -pady 2 \
      -command "_selc_action array"

    pack $w.edit $w.edit2 $w.props -in $w.buttons1 -side top -padx 4m -fill x
    pack $w.exp $w.unexp -in $w.buttons2 -side top -padx 4m -fill x

    pack $w.buttons1 $w.buttons2 -in $w.buttons -side left -anchor n -fill x
    #pack $w.buttons -side top -expand 1 -fill x
    pack $w.buttons -side top

    #button $w.byname -text "Find by Name" -font $DIALOG_FONT -padx 2 -pady 2 \
	-command {mode_pop; select_cell_by_name}
    #pack $w.byname -in $w -side top -padx 4m -pady 2

    set helpmsg {This menu shows a list of cells in two parts: \
      the top part, labeled "Cell Hierarchy", displays a stack\
      of cells in the hierarchy above the current cell, that is, parents\
      of the current cell. \
      This hierarchy is displayed only if you edited the parent cell\
      first, and reached the current cell by selecting it and editing it\
      with this menu, or the "Edit Push" command; \
      max maintains a stack of the cells that you edited in this way.
The bottom part, labeled "Sub-Cells under cursor", is a list\
      of all cells under the mouse pointer, reaching down through\
      the cell hierarchy through cells whose internals are\
      being viewed. \
      The indent indicates the relative position of cells in the hierarchy.
Use mouse BUT-1 (or the f key) in the max window to show the list\
      of cells at that point.  You can use multiple mouse presses (or f keys)\
      at the same point to cycle the selected cell through the cells\
      at that point, or use mouse BUT-1 on one of the cells in\
      the Find Cell menu\
      to select that cell, and highlight it, if possible, in the max window. \
      You can then use the buttons at the bottom of the "Find Cell" window\
      to edit the cell, or view or hide its internals.\
    }

    frame $w.buttons3
    frame $w.default -relief sunken -bd 1
    button $w.done -text "Close" -font $DIALOG_FONT -padx 1 -pady 1 \
      -command "mode_pop"
    button $w.help -text "Help" -font $DIALOG_FONT -padx 1 -pady 2 \
      -command [list prop_dialog -title {Find Cell Help} $helpmsg]
    pack $w.done -in $w.default -padx 1 -pady 1 -ipadx 1
    pack $w.default -in $w.buttons3 -side left \
      -padx 4m -ipadx 1 -pady 3 -expand 1
    pack $w.help -in $w.buttons3 -side left -padx 1 -pady 1
    pack $w.buttons3 -in $w -side bottom 

    foreach binding $SEL_CELL(bindings) {
      setl {key cmd} $binding
      bind $w $key $cmd
    }

    util_win_finish $w -place right
  } else {
    # Reuse old window
    raise $w
  }

  # Fill the main panel with cells.  Save old list.

  set old_cell_list $SEL_CELL(list)
  if { $old_cell_list != "" } {
    setl {old_depth old_path old_def old_exp} [lindex $SEL_CELL(list) [expr $SEL_CELL(windex) - 1]]
  }
  set selection [sel_what cells]

  _selc_hier_fill

  sel_clear  ;# Deselect previously selected cell, if any.

  # Look at the cells at the current point.
  # If the list matches the same as the previous list,
  # select the next cell in the list.
  # Otherwise, if the user selected a cell some other way
  # (with the f key, or by pointing) select that cell.
  # Otherwise select the smallest (last) cell.
  # If no cells, draw a box around the editcell.
  # This method gives the user the choice of editing the largest
  # or the smallest cell under the given point.

  set len [llength $SEL_CELL(list)]
  if { $len == 0 } {
    # No sub-cells.  Just select current cell.
    set SEL_CELL(windex) 0
  } elseif { $SEL_CELL(list) == $old_cell_list } {
    # Same list as before.  Continue feedback of previous list.
    incr SEL_CELL(windex) -1
    if { $SEL_CELL(windex) == 0 } {
      set SEL_CELL(windex) $len  ;# Cycle back to end.
    }
  } elseif { $old_cell_list != "" } {
    # When we pointed, the cell list changed.
    # Try to select the cell that was previously selected by cell finder.
    # We need this different from the case for selected cell below,
    # because there could be multiple cells with the same id,
    # so we actually need to search for the path.
    set in [lsearch $SEL_CELL(list) "*${old_path}*"]
    if { $in >= 0 } {
      set SEL_CELL(windex) [expr $in + 1]
    } else {
      # Default to the smallest (last) cell.
      set SEL_CELL(windex) $len
    }
  } elseif { $selection != "" } {
    # Try to select the cell that was previously selected with f key
    # or other method.
    struct max_cell c [lindex [split $selection \n] 0]
    set in [lsearch $SEL_CELL(list) "*${c.id}*"]
    if { $in >= 0 } {
      set SEL_CELL(windex) [expr $in + 1]
    } else {
      # Default to the smallest (last) cell.
      set SEL_CELL(windex) $len
    }
  } else {
    # Select the smallest (last) cell.
    set SEL_CELL(windex) $len
  }

  if { $len != 0 } {
    setl {depth rid def} [lindex $SEL_CELL(list) [expr $SEL_CELL(windex)-1]]
    # 1/31/02: change from sel_cell3 to sel_cell
    sel_cell $rid
    # TODO: if its a gcell, the def was already set to "NFET gcell",
    # for example, so sel_cell_msg prints the wrong thing.
    #_selc_msg $rid $def
  } else {
    # No sub-cells under cursor.
    # Put box around top level cell.
    eval layt_box exact [lay_bbox]
  }


  # Exceptions are for Done and Cancel buttons, which must break
  # to prevent processing the global bind of $w
  #bind $w.done <Return> {set SELECT_CELL(result) "ok";break}
  #bind $w.cancel <Return> {set SELECT_CELL(result) "";break}
  #bind $w <Escape> {set SELECT_CELL(result) "";}
  #bind $w <Return> {set SELECT_CELL(result) "ok"; break}
  #bind $w <Any-Control-c> {set SELECT_CELL(result) ""}

  _selc_hier_update

  util_win_onscreen $w

  #catch {focus -force $oldFocus}
  #update
}


if {0} {
    # This routine puts a temporary box in the listbox area.
    proc sel_hierarchy_listbox {} {
      global SEL_CELL DIALOG_FONT
      setl {x y} [layt_point exact]
      set cells [db_search cells -any_cell -area $x $y $x $y]

      set cell_list ""
      foreach cell [split [string trim $cells] \n] {
	struct max_cell c $cell
	set fnd_any 1

	# First element in list is nesting depth of sub-cell;
	# second element is full pathname of cell;
	# third element is cell def.
	set realid [cellinfo_name -array $cell]
	regsub -all {[^/]*} $realid "" slashes

	# Only "f"select cells that have at least one boundary visible.
	if { [rect_is_visible ${c.x1} ${c.y1} ${c.x2} ${c.y2}] } {
	  lappend cell_list [list [string length $slashes] $realid ${c.def}]
	}
      }
      set cell_list [lsort -index 1 $cell_list]

      set title "Cell Hierarchy"


      #set oldFocus [focus]

      set use_listbox 1
      if {$use_listbox} {
	global max_win
	set w ${max_win}.list_boxes.find_cell
      } else {
	set w .find_cell
	set SEL_CELL(window) $w
      }
      if {! [winfo exists $w] } {
	# Create new window
	if {$use_listbox} {
	  frame $w -relief sunken -bd 2
	} else {
	  toplevel $w
	}
	global max_win
	set x [expr [winfo pointerx $max_win] + 10]
	set y [expr [winfo pointery $max_win] + 10]
	if {!$use_listbox} {
	  wm geometry $w "+$x+$y"
	  wm minsize $w 200 100
	  #wm withdraw $w
	}
      } else {
	# Reuse old window
	#wm withdraw $w
	raise $w
	foreach wchild [winfo children $w] {
	  catch { destroy $wchild }
	}
      }
      if {!$use_listbox} {
	wm title $w $title
      }


      frame $w.main -relief sunken -bd 2

      set i 1
      foreach cell $cell_list {
	setl {depth id def} $cell
	set indent ""
	#for {set j $depth} {$j > 0} {incr j -1} {
	#  append indent "  "
	#}
	radiobutton $w.main.r$i -variable SELECT_CELL(windex) -value $i \
	  -text "$id $def" -command "sel_cell $id"
	pack $w.main.r$i -side top -anchor w
	incr i
      }
      pack $w.main -side bottom -fill x

      # Select the first cell
      global SELECT_CELL
      set SELECT_CELL(windex) 1
      setl {depth id def} [lindex $cell_list 0]
      sel_cell $id

      if {$use_listbox} {

	set menu $w.title.menu
	global LISTBOX_FONT
	menubutton $w.title -text $title -font $LISTBOX_FONT \
	      -relief raised -bd 2 -menu $menu \
	      -padx 2 -pady 2
	pack $w.title -side top -fill x

	menu $menu -tearoff 0
	$menu add command -label "Edit cell" \
	    -command edit_push
	$menu add command -label "Edit cell in place" \
	    -command edit_any
	$menu add command -label "Close" \
	    -command "catch {destroy $w}"
      } else {
	frame $w.buttons
	frame $w.default -relief sunken -bd 1
	button $w.done -text "Close" -font $DIALOG_FONT -padx 1 -pady 1 \
	  -command "catch {destroy $w}"

	pack $w.done -in $w.default -padx 1 -pady 1 -ipadx 1
	pack $w.default -side left -in $w.buttons \
	    -padx 4m -ipadx 1 -pady 3 -expand 1
	pack $w.buttons -side bottom

	label $w.title -text $title -font $DIALOG_FONT
	pack $w.title -side top -fill x
      }

      # cancel always tries to destroy menu so can't be orphaned
      #button $w.cancel -text "Cancel" -font $DIALOG_FONT -padx 1 -pady 1 \
      #    -command "set SELECT_CELL(result) {} ; catch {destroy $w}"
      #pack $w.cancel -side left -in $w.buttons \
      #    -padx 4m -ipadx 1 -pady 3 -expand 1

      # Global bindings for Return, Control-C, Escape.
      # Exceptions are for Done and Cancel buttons, which must break
      # to prevent processing the global bind of $w
      #bind $w.done <Return> {set SELECT_CELL(result) "ok";break}
      #bind $w.cancel <Return> {set SELECT_CELL(result) "";break}
      #bind $w <Escape> {set SELECT_CELL(result) "";}
      #bind $w <Return> {set SELECT_CELL(result) "ok"; break}
      #bind $w <Any-Control-c> {set SELECT_CELL(result) ""}

      update idletasks

      # Border pixels for X windows.  Can't seem to figure these out.
      set xborder 3
      set yborder 25

      # If the menu floats off the screen, move it back on.
      set dx [min [expr [winfo screenwidth $w]-[winfo width $w]- \
		       $x-$xborder] 0]
      set dy [min [expr [winfo screenheight $w]-[winfo height $w]- \
		       $y-$yborder] 0]
      if { $use_listbox} {
	set firstbox ""
	global _LIST_BOX_
	catch {set firstbox [lindex $_LIST_BOX_($max_win) 0]}
	pack forget $w
	if { $firstbox != "" } {
	  pack $w -side top -before $firstbox -padx 1 -pady 1 -fill x
	} else {
	  pack $w -side top -padx 1 -pady 1 -fill x
	}
	#pack ${max_win}.list_boxes
      } else {
	if {$dx < 0 || $dy < 0} {
	  wm geometry $w "+[expr $x+$dx]+[expr $y+$dy]"    
	}
      }

      #catch {focus -force $oldFocus}
      #update

    }
}
