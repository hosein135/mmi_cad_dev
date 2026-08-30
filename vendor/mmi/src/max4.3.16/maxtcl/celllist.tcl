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

set RCSVERSION(celllist.tcl) { $Revision$ }


proc cell_lbox {} -desc {
  Do cell box with a prop menu.
} {
  global _CELL_LBOX LISTBOX_FONT

  # Other possibilities:
  # List: hierarchical_types hierarchical_insts all_types all_insts
  # View: Type path is_lef cong_effort timing_effort obstruct_parent wiring_resources
  # Inst: x,y,ori place stop_bit

  # These are the persistent radio buttons. 
  # Each sublist contains: Title variable_name list_of_values
    #[list Hierarchy: _CELL_LBOX(hier) [list "current cell" "all cells"]]
  set radios [list \
    [list List:   _CELL_LBOX(list)   "defs instances"] \
    [list Filter: _CELL_LBOX(filter) "large hierarchical selected all"] \
    [list View:   _CELL_LBOX(view)   "basic placement timing"] \
    [list Sort:   _CELL_LBOX(sort)   "def id x y"] \
    ]

  set prop_list ""
  foreach thing $radios {
    setl {title var values} $thing
    use_init $var [lindex $values 0]
    lappend prop_list [list $title $var -radio $values -inline -command _cell_lbox_fill -relief flat]
  }

  set _CELL_LBOX(match) ""
  set _CELL_LBOX(header) [_cell_lbox_header header]
  lappend prop_list [list Match: _CELL_LBOX(match) -entry -command _cell_lbox_fill]
  lappend prop_list [list "" _CELL_LBOX(header) -label -width 100 -fg blue -relief raised]

  # This is just a little tricky.  When the listbox is first mapped, the window
  # name is passed to _cell_lbox_fill as an argument.
  # Subsequent calls to _cell_lbox_fill use the same listbox window name,
  # as there can be only one at a time.
  set listbox_bindings [list \
    <ButtonRelease-1> "_cell_lbox_sel %W %x %y" \
    <Double-Button-1> "_cell_lbox_sel %W %x %y;_cell_lbox_edit" \
    <ButtonRelease-2> "_cell_lbox_edit" \
    <Map> "_cell_lbox_fill %W" ]

  lappend prop_list [list "" "" -listbox -bind $listbox_bindings]

  prop_menu2 -bg 1 -title "Cell Properties for [lay_editcell]" -font $LISTBOX_FONT \
    -buttons "Edit==_cell_lbox_edit Close==default Refresh==_cell_lbox_fill" $prop_list
}


proc _UNUSED_cell_lbox {} -desc {
  Popup text command documentation
} {
  global FPLAN MAX_DEVELOPER LISTBOX_FONT
  global _CELL_LBOX
  set font $LISTBOX_FONT

  set _CELL_LBOX(match) ""
  use_init _CELL_LBOX(list) defs
  use_init _CELL_LBOX(filter) large
  use_init _CELL_LBOX(view) basic
  use_init _CELL_LBOX(sort_key) id

  set w .cell_list

  util_win_create $w "Cell List for [lay_editcell]"
  wm geom $w "700x500"

  set tw 10  ;# Width of left hand titles in radiobutton area.
  set common "-command _cell_lbox_fill -font $font"

  set f $w.f1
  frame $f -borderwidth 0 -relief raised
  label $f.l -relief flat -font $font -width $tw -text "List:"
  set lvar "-variable _CELL_LBOX(list)"
  eval radiobutton $f.r1 $common $lvar -text {defs} -value defs
  eval radiobutton $f.r2 $common $lvar -text {instances} -value instances
  pack $f.l $f.r1 $f.r2 -side left

  set f $w.f3
  frame $f -borderwidth 0 -relief raised
  label $f.l -relief flat -font $font -width $tw -text "View:"
  set lvar "-variable _CELL_LBOX(view)"
  eval radiobutton $f.r1 $common $lvar -text basic -value basic
  eval radiobutton $f.r2 $common $lvar -text placement -value placement
  eval radiobutton $f.r3 $common $lvar -text timing -value timing
  eval radiobutton $f.r4 $common $lvar -text model -value model
  pack $f.l $f.r1 $f.r2 $f.r3 $f.r4 -side left

  set f $w.f2
  frame $f -borderwidth 0 -relief raised
  label $f.l -relief flat -font $font -width $tw -text "Filter:"
  set lvar "-variable _CELL_LBOX(filter)"
  eval radiobutton $f.r1 $common $lvar -text large -value large
  eval radiobutton $f.r2 $common $lvar -text hierarchical -value hierarchical
  eval radiobutton $f.r3 $common $lvar -text all -value all
  pack $f.l $f.r1 $f.r2 $f.r3 -side left

  set f $w.f4
  frame $f -borderwidth 0 -relief raised
  label $f.l -relief flat -font $font -width $tw -text "Match:"
  eval entry $f.e -font $font -relief raised -textvariable _CELL_LBOX(match) 
  bind $f.e <Return> "_cell_lbox_fill"
  pack $f.l $f.e -anchor w -side left -expand 0

  set f $w.f5
  frame $f -borderwidth 0 -relief raised
  label $f.l -relief flat -font $font -width $tw -text "Sort By:"
  eval entry $f.e -font $font -relief raised -textvariable _CELL_LBOX(sort_key) 
  bind $f.e <Return> "_cell_lbox_fill"
  pack $f.l $f.e -anchor w -side left -expand 0

  if {$FPLAN(exists)} {
    # If no floorplanner, only basic label information is shown.
    #pack $w.f3.l $w.f3.r31 $w.f3.r32 -anchor w -side left -expand 0
  }

  pack $w.f1 $w.f2 $w.f3 $w.f4 $w.f5 -side top -anchor w


  label $w.header -font $font -relief raised -foreground blue -anchor w ;# Filled in by _fill routine.
  pack $w.header -side top -fill x

  # listbox and scroll bars for cells
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
  bind $w.items.list <ButtonRelease-1> {_cell_lbox_sel $w.items.list -select %x %y;break}
  #bind $w.items.list <Double-Button-1> {_cell_lbox_sel -edit $w.items.list }
  #bind $w.items.list <ButtonRelease-2> {_cell_lbox_sel -edit $w.items.list }

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

  label $w.info -width 20 -anchor e
  button $w.fb.close -text "Close" -command "catch {util_win_destroy $w}"
  button $w.fb.refresh -text "Refresh" -command "_cell_lbox_fill"
  button $w.fb.help -text "Help" -command "prop_dialog -title {Edit Ports Help} {$help}"
  pack $w.fb.close $w.fb.refresh $w.fb.help -side left -padx 5 -pady 1
  pack $w.info -in $w.fb -side right -anchor e

  pack $w.fb -side bottom
  pack $w.ftools -side bottom

  util_win_finish $w -place normal
  
  _cell_lbox_fill
}


proc _cell_lbox_sel {{-select} {-edit} win lx ly} {
  global _CELL_LBOX _CELL_LBOX_EXP _CELL_MAP
  set old_cursor [cursor_busy 1]

  set n [$win index @$lx,$ly]
  set line [$win get $n]
  if {[string index $line 0] == "+"} {
    set kid [lindex $line 1]
    set _CELL_LBOX_EXP($kid) 0
  } elseif {[string index $line 0] == "-"} {
    set kid [lindex $line 1]
    set _CELL_LBOX_EXP($kid) 1
  } else {
    sel_clear
    foreach index [$win curselection] {
      set line [$win get $index]
      if {[string index $line 0] == " "} {
	#sel_cell -more [list [lindex $line end]]
	sel_cell -more [lindex $line end]
      }
    }
  }
  cursor_busy $old_cursor
  _cell_lbox_fill $win
  return

  # Make SURE the labels in the listbox are up to date with what is
  # in the max database; the listbox might be out of date with respect
  # to max, eg, if somone has edited a new cell, and we dont want
  # to create labels from a stale listbox in the current cell.
  # You cant do this if you are selecting, because _cell_lbox_fill
  # updates the listbox selection from the selected max labels,
  # undoing the current selected lines in the listbox.
  #if {$edit} {_cell_lbox_fill}

  set indicies [$w curselection]
  set sel_list ""
  foreach index $indicies {
    set sel_list [concat $sel_list $_CELL_MAP($index)]
  }

  set use_nl [nl2_loaded -cell [lay_editcell]]

  if {$select} {

    sel_clear
    db_flyline -delete

    # The _CELL_MAP contains a list of ports/nets that correspond to each listbox element.
    # If it was a bus, _CELL_MAP will contain the list of individual bits.

      foreach lab_info $sel_list {
	set port [labinfo_text $lab_info]
	sel_labels -more -text $port
	if {$use_nl} {
	  fplan_sel_net -more $port
	}
      }
  }

  if {$edit} {
      # Bring up the label editor on the selected labels.
      label_edit_new $sel_list
  }
  cursor_busy 0
  return
}


proc _cell_lbox_filter {def} -desc {
  Return 1 if cell_info should be displayed, 0 if not.
} {
  global _CELL_LBOX
  switch $_CELL_LBOX(filter) {
    "selected" {
      upvar sel_def_hash sel_def_hash
      return [info exists sel_def_hash($def)]
    }
    "all" {return 1}
    "hierarchical" {
      if {[fplan_cell_info -is_lef $def]} {
	return 0
      } else {
	return 1
      }
    }
    "large" {
      # Show all hierarchical and large cells.
      if {[fplan_cell_info -is_lef $def] && [fplan_cell_info -is_small $def]} {
	return 0
      } else {
	return 1
      }
    }
    default { error "unrecognized filter $_CELL_LBOX(filter)" }
  }
}


proc _cell_lbox_sort {cell_list} {
  global _CELL_LBOX
  switch $_CELL_LBOX(sort) {
    "def" {
      set index [struct_index max_cell def]
      return [lsort -dictionary -index $index $cell_list]
    }
    "id" {
      set index [struct_index max_cell id]
      return [lsort -dictionary -index $index $cell_list]
    }
    "x" {
      set index [struct_index max_cell x1]
      return [lsort -real -index $index $cell_list]
    }
    "y" {
      set index [struct_index max_cell y1]
      return [lsort -real -index $index $cell_list]
    }
    default {
      error "unrecognized sort key: $_CELL_LBOX(sort)"
    }
  }
}

proc _cell_lbox_get_prop {name cell_info} {
    switch $name {
      "def" -
      "id"  -
      "x1"  -
      "y1"  {
	set val [cellinfo_$name $cell_info]
      }
      "ori" {
	# A blank value is not allowed in a prop_menu box, in addition to being confusing,
	# so change blank orientation to "normal"
	set val [cellinfo_$name $cell_info]
	if {$val == ""} {set val "normal"}
      }

      "place" {
	set val [fplan_db_inst getprop [cellinfo_id $cell_info] place]
	if {$val == ""} {set val "unplaced"}
      }

      "use_cache" -
      "use_model" {
	set val [db_prop -def [cellinfo_def $cell_info] $name]
	if {$val == ""} {set val 0}
      }

      default {
	set val [db_prop -def [cellinfo_def $cell_info] $name]
      }
    }
    return $val
}

proc _cell_lbox_set_prop {name val cell_info} {
  switch $name {
    id {
      sel_cell [cellinfo_id $cell_info]
      :identify $val
    }
    "x1" {
       # It is inefficient to change x1, y1, and orientation with three different calls to this
       # function, but it will probably not happen.  If people are changing multiple
       # cells simultaneously, they are probably changing only x1 OR y1 OR orientation.
       # They wouldnt want to put all the cells on top of each other, for example.
       set id [cellinfo_id $cell_info]
       db_instance_delete $id
       db_instance -orientation [cellinfo_ori $cell_info] -dup_ok -id $id [cellinfo_def $cell_info] $val [cellinfo_y1 $cell_info]
    }
    "y1" {
       set id [cellinfo_id $cell_info]
       db_instance_delete $id
       db_instance -orientation [cellinfo_ori $cell_info] -dup_ok -id $id [cellinfo_def $cell_info] [cellinfo_x1 $cell_info] $val
    }
    "ori" {
       set id [cellinfo_id $cell_info]
       set def [cellinfo_def $cell_info]
       set old_ori [cellinfo_ori $cell_info]
       sel_cell $id
       selt_transform -cell_origin $def -reverse $old_ori
       selt_transform -cell_origin $def [expr {$val == "normal" ? "" : $val}]
    }
    "place" {
       set id [cellinfo_id $cell_info]
      set old_val [fplan_db_inst getprop $id "place"]
      fplan_db_inst setprop [cellinfo_id $cell_info] "place" $val

      # Special case required for place property to flatten/unflatten cells.
      if {$val == "flatten" && $old_val != "flatten"} {
	fplan_cell_flatten -flatten 1 $cell_info
      } elseif {$val != "flatten" && $old_val == "flatten"} {
	fplan_cell_flatten -flatten 0 $cell_info
      }
    }
    default {
      db_prop -def [cellinfo_def $cell_info] $name $val
    }
  }
}


proc _cell_lbox_line {format disp_list cell_info} -desc {
  Format cell for display, return "" if should not be displayed, based on Match string.
} {
  global _CELL_LBOX

  set id [cellinfo_id $cell_info]
  set def [cellinfo_def $cell_info]

  if {$_CELL_LBOX(filter) == "selected"} {
    upvar sel_id_hash sel_id_hash
    if {![info exists sel_id_hash($id)]} {
      return ""
    }
  }

  set cmd "format"
  lappend cmd $format
  foreach name $disp_list {
    lappend cmd [_cell_lbox_get_prop $name $cell_info]
  }
  set entry [eval $cmd]

  if {$_CELL_LBOX(match) != ""} {
    if {![regexp $_CELL_LBOX(match) $entry]} {return ""}
  }
  return $entry
}


proc _cell_lbox_header {what} -desc {
  return header for each display mode
} -doc {
  What argument can be:
    format  : return the format string
    list    : return the list of items to display in each line in this mode.
    header  : return the formatted header string.
} {
  global _CELL_LBOX

  switch -- $_CELL_LBOX(view) {
    basic {
      # This is the list of things from the label that we will display:
      set disp_list "x1 y1 ori def id"
      set format "  %-12s %-12s %-6s %-12s %s"
    }
    placement {
      # These are the placement properties we will display:
      set disp_list "place def id"
      set format "  %-12s %-12s %s"
    }
    timing {
      set disp_list "use_model use_cache def id"
      set format "  %-10s %-10s %-12s %s"
    }
    model {
      set disp_list "kind slack int_budget int_actual int_drive_res int_cap def id"
      set format "  %-8s %-12s %-12s %-12s %-14s %-12s %-12s %s"
    }
    default {
      error "_cell_lbox internal error"
    }
  }

  if {$what == "format"} {return $format}
  if {$what == "header"} {return [eval format {$format} $disp_list]}
  if {$what == "list"} {return $disp_list}
  error "bad args"
}

proc _cell_lbox_fill {{win ""}} -desc {
  fill list box with variables matching apropos pattern;  highlight selected labels.
} {
  global _CELL_LBOX	;# Options for this command.
  global _CELL_MAP     ;# Maps listbox indicies to label_info structures.
  global _CELL_LBOX_EXP	;# For each kid, do we want to see instances?

  set limit 1000	;# Max length of listbox

  if {$win != ""} {
    # The first time we are called, we get the window name,
    # and remember it for future calls.
    set _CELL_LBOX(window) $win
  }

  set format [_cell_lbox_header format]
  set disp_list [_cell_lbox_header list]
  set header [_cell_lbox_header header]

  #.cell_list.header configure -text $header
  set _CELL_LBOX(header) $header

  catch {unset _CELL_MAP}

  set plist $_CELL_LBOX(window)
  if {![winfo exists $plist]} {return}

  # Update title in case user edited a new cell.
  #wm title .cell_list "Cell List for [lay_editcell]"

  set old_cursor [cursor_busy 1]

  if {[$plist size] > 0} {
    set orig_index [$plist nearest 0]
    set orig_size [$plist size]
    $plist delete 0 end
  } else {
    set orig_index 0
    set orig_size 0
  }

  set sel_cells [sel_what_cells]
  # Make this array for use later.
  foreach c $sel_cells {
    set sel_id_hash([cellinfo_id $c]) 1
    set sel_def_hash([cellinfo_def $c]) 1
  }

  set lbox_index 0  ;# Index in listbox.

  #set key_index [lsearch $disp_list $_CELL_LBOX(sort_key)]
  #if {$key_index == -1} { set key_index end }

  # We will display a line for each cell type.
  # If the cell type is expanded, then show the instances, too.
  if {$_CELL_LBOX(list) == "defs"} {
    foreach kid [lsort -dictionary [db_kids]] {
      if {$lbox_index >= $limit} {break}

      # Pre-filter out uninteresting defs
      if {![_cell_lbox_filter $kid]} {continue}

      set is_lef [fplan_cell_info -is_lef $kid]
      set lef_marker [expr {$is_lef ? "(lef)" : ""}]

      use_init _CELL_LBOX_EXP($kid) 0
      if {$_CELL_LBOX_EXP($kid)} {
	$plist insert end "+ $kid $lef_marker"
	incr lbox_index
	foreach cell_info [_cell_lbox_sort [db_instances -of $kid]] {
	  if {$lbox_index >= $limit} {break}

	  set tmp [_cell_lbox_line $format $disp_list $cell_info]
	  if {$tmp != ""} {
	    $plist insert end $tmp

	    if {[info exists sel_id_hash([cellinfo_id $cell_info])]} {
	      # If cell is selected, show it as selected in the list box, too.
	      $plist selection set $lbox_index
	    }
	    incr lbox_index
	  }
	}
      } else {
	# Just put the kid def name in the listbox, but not the instances.
	$plist insert end "- $kid $lef_marker"
	if {[info exists sel_def_hash($kid)]} { $plist selection set $lbox_index }
	incr lbox_index
      }
    }

  } else {
    set inst_list ""
    foreach kid [lsort -dictionary [db_kids]] {
      # Pre-filter out uninteresting defs
      if {![_cell_lbox_filter $kid]} {continue}
      set kid_insts [db_instances -of $kid]
      set inst_list [concat $inst_list $kid_insts]
      if {[llength $inst_list] > $limit} {break}
    }

    # Now draw them.
    foreach cell_info [_cell_lbox_sort $inst_list] {
      if {$lbox_index >= $limit} {break}
      set tmp [_cell_lbox_line $format $disp_list $cell_info]
      if {$tmp != ""} {
	$plist insert end $tmp
	if {[info exists sel_id_hash([cellinfo_id $cell_info])]} {
	  # If cell is selected, show it as selected in the list box, too.
	  $plist selection set $lbox_index
	}
	incr lbox_index
      }
    }
  }

  if {$lbox_index >= $limit} {
    $plist insert end "**** Too many instances, list truncated ****"
  }

  set new_size [$plist size]
  if {$new_size == $orig_size} {
    $plist yview $orig_index
  } else {
    set sel [lindex [$plist curselection] 0]
    if {$sel != ""} {
      $plist see $sel
    }
  }

  # This could be time consuming to compute when selection is changed, so display total instead.
  # User can see number of selected ports by setting "View:" to "selected".
  #.cell_list.info config -text "Port Count: $lbox_cnt"

  cursor_busy $old_cursor
}


proc _cell_lbox_edit {} {
  global _CELL_LBOX

  set cell_list [sel_what_cells -user_bbox]
  if {[llength $cell_list] == 0} return

  set disp_list [_cell_lbox_header list]

  # Init info array holding values to be edited.
  foreach thing $disp_list {set info($thing) "**UNKNOWN**"}

  # Set info array to the values for the selected cells, or <various> if multiple values for any thing.
  foreach cell_info $cell_list {
    foreach thing $disp_list {
      set thing_value [_cell_lbox_get_prop $thing $cell_info]

      if {$info($thing) == "**UNKNOWN**"} {
	set info($thing) $thing_value
      } elseif {$info($thing) != $thing_value} {
	set info($thing) "<various>"  ;# Two labels have different values of $thing.
      }
    }
  }

  # Prop options defaults to "", which prop_menu interprets as -entry.
  set prop_opts(place) "-choice {unplaced fixed flatten}"
  set prop_opts(use_cache) "-choice {0 1 <various>}"
  set prop_opts(use_model) "-choice {0 1 <various>}"
  set prop_opts(ori) "-choice {normal r90 r180 r270 fx fy fx_r90 fy_r90  <various>}"
  set prop_opts(def) "-label"		;# Cant edit this

  foreach thing $disp_list {
    lappend prop_list [concat $thing info($thing) [use_first prop_opts($thing)]]
    set old_info($thing) $info($thing)
  }

  set title "Cell [lay_editcell] $_CELL_LBOX(view) properties"
  if {![prop_menu2 -title $title $prop_list]} {
    return ;# cancelled
  }

  # Distribute updated values back to cells.

  foreach cell_info $cell_list {
    foreach thing $disp_list {
      if {$info($thing) == "<various>"} { continue }
      if {$info($thing) == $old_info($thing)} { continue }
      _cell_lbox_set_prop $thing $info($thing) $cell_info
      continue

      if {$thing == "place"} {
	fplan_db_inst setprop [cellinfo_id $cell_info] $thing $info($thing)

	# Special case required for place property to flatten/unflatten cells.
	if {$info($thing) == "flatten" && $old_info($thing) != "flatten"} {
	  fplan_cell_flatten -flatten 1 $cell_info
	} elseif {$info($thing) != "flatten" && $old_info($thing) == "flatten"} {
	  fplan_cell_flatten -flatten 0 $cell_info
	}
      } else {
	db_prop -def [cellinfo_def $cell_info] $thing $info($thing)
      }
    }
  }
  _cell_lbox_fill

  return


  # OLD CODE:

  switch $_CELL_LBOX(view) {
    "basic" {
      fplan_block_props [cellinfo_id [lindex $cell_list 0]]
    }
    "timing" {
      _cell_lbox_timing [lindex $cell_list 0]
    }
    "placement" {
      fplan_block_props [cellinfo_id [lindex $cell_list 0]]
    }
    default {
      error "unrecognized lbox view"
    }
  }
}
