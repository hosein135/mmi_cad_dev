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

set RCSVERSION(select.tcl) { $Revision: 1.72 $ }

# selection interface


# Set this to work on db_next_distance.
# Update 6/30/00: db_next_edge does not implement -any_cell yet,
# so turn this off for now.
# Update 8/7/00: Still bugs in db_next_distance (doesnt return
# edges in some directions), so dont put this in.
global DB_NEXT_DISTANCE_BUG
set DB_NEXT_DISTANCE_BUG 1

init_global SEL_NET_SETUP(display_labels) \
    -type binary \
    -default 1 -desc {Binary value (0 or 1) that controls whether\
    the "Select Net" command will display label names.}

init_global SEL_NET_SETUP(display_label_path) \
    -type binary \
    -default 1 -desc {Binary value (0 or 1) that controls whether\
    the "Select Net" command will include path names in any displayed\
    label names.  See also SEL_NET_SETUP(display_labels).}

init_global SEL_NET_SETUP(via_limit) -type number -default 1000 \
    -desc {The "Select Net" command can optionally select\
    attached via cells as well as wires.  You would want to select\
    the via cells if you were planning to move the wire, for example,\
    and want the attached vias to move with it.  However, selecting\
    the via cells is time consuming and unnecessary if all you are\
    doing is viewing the connectivity, which is typically the case\
    when selecting large nets.   So you can control the behavior\
    with this variable.  If the net contains\
    fewer than this number of via cells, then they are selected.\
    If set to 0, via cells are not selected.\
    If set to -1, via cells are always selected.}

init_global SELECT_ANY_CELL \
    -type binary \
    -default 0 -desc {Binary value (0 or 1) that controls whether\
    the Button-1 select will select only in the current cell,\
    or in any visible cell. \
    NOTE: This will not work until sel_labels -any_cell is implemented.}



# This is the structure that saves selected items.
# It is returned by _select_list and saved in SAVE_SELECT(list)
# The sortkey is used to sort the paint/label/polygons for the
# presentation order to the user.
# The type is "paint" or "label" or "polygon" or "cell".
# For labels and polygons the other field is the complete sel_what list.
# The text field is for labels and cells only.
# For point-type labels, the bbox x1==x2 and y1==y2.
# The sbox is the selection box that the user dragged or clicked.
# For single click select, sbox is a pint, ie, x1==x2 and y1==y2
set MAX_STRUCT(select_struc) {sortkey type sbox layer bbox text other}


###
### Hook all select functions to do a sel_group_transfer
###

global MAX_NEW_SELECT
if {[use_first MAX_NEW_SELECT] == 1 && \
    [info commands new_:select] == ""} {
    foreach cmd {:select sel_area sel_clear sel_cell sel_chunk 
	sel_clear sel_labels sel_net sel_polygons sel_region} {
	if {[info command orig_$cmd] != ""} {continue}
	proc new_$cmd args "
	    if {\[lsearch -regexp \$args {^-more\$|^-less\$}\] == -1} {
		set tmp \[db_group\]
		db_group selected
		sel_group_transfer 0
		db_group \$tmp
	    }
	    eval orig_$cmd \$args
	"
	rename $cmd orig_$cmd
	rename new_$cmd $cmd
    }

    if {0} {
    # Fix max core-dump: disallow zero size area.
	proc new_sel_area args {
	    set l [llength $args]
	    set options [lrange $args 0 [expr $l-5]]
	    setl {x1 y1 x2 y2} [lrange $args [expr $l-4] [expr $l-1]]
	    if { $x1 == $x2 } {
		set x2 [expr $x2 + [res]]
	    }
	    if { $y1 == $y2 } {
		set y2 [expr $y2 + [res]]
	    }
	    eval orig_sel_area $options $x1 $y1 $x2 $y2
	}
	rename sel_area orig_sel_area
	rename new_sel_area sel_area
    }

}



proc sel_clear_g {} -desc {
    Unselect all without changing group of selection.
} {
    global MAX_NEW_SELECT
    if {[use_first MAX_NEW_SELECT] == 1} {
	orig_sel_clear
    } else {
	sel_clear
    }
}


proc sel_cell2 {args} -desc {
    Version of sel_cell that works with edit in place.
} -doc {
  sel_cell searches for a cell path starting at the root cell.
  sel_cell2 searches for a cell path starting at the edit cell.

USAGE:
    sel_cell2 [-more | -less] cell_name

    If the id contains a slash, assume it is already a path.

    This is really a bug-fix to sel_cell, which should go away
    as soon as sel_cell works properly.

    NOTE: 2/1/02: This function used to assume that if a cell_name
    began with "/" it was relative to the root directory.
} {
    # If id is already a path name, dont need anything special.
    set argc [llength $args]
    set id [lindex $args [expr $argc - 1]]
    set options [lrange $args 0 [expr $argc - 2]]

    if {[use_list_path]} {

      if {[lindex $id 0]  == {/}} {
	# already absolute path, just strip leading / 
	set id [lrange $id 1 end]
      } else {
	# Check if we are doing edit in place.
	setl {cell_name cell_path} [lay_path]
	if { $cell_path != "." } {
	  # Edit in place.  Must pre-pend the cell path.
	  set id [concat $cell_path $id]
	}
      }
    } else {
      if { [string first "/" $id] == -1 } {

	  # Check if we are doing edit in place.
	  setl {cell_name cell_path} [lay_path]
	  if { $cell_path != "." } {
	      # Edit in place.  Must pre-pend the cell path.
	      set id $cell_path$id
	  }
      }
    }

  # Extra curly braces required in case text has $ in it.
  eval sel_cell $options [list $id]
}


proc select_q args -desc {
  quiet version of select
} {
    max_error "select_q called!!  Dont do that!!!"
    set code [msg_catch ":select $args" result info]
    if { $code != 0 } {	error $result }
}

proc _sel_cell_contains_paint {cell layer} -desc {
  does the cell contain the given paint layer
} {
  global _SEL_CELL_PAINT_CACHE
  # Cache results.  Theoretically, the user could edit the via cell
  # and render this cache invalid, but its pretty unlikely.
  if {[info exists _SEL_CELL_PAINT_CACHE($cell,$layer)]} {
    return $_SEL_CELL_PAINT_CACHE($cell,$layer)
  }
  #set layer [dbt_short_name $layer]
  set ret [expr {[llength [db_search_l paint -limit 1 -cell $cell $layer]] > 0}]
  set _SEL_CELL_PAINT_CACHE($cell,$layer) $ret
  return $ret
}

proc sel_vias {} -desc {
  select vias whose paint is selected.
} {
  global SEL_NET_SETUP

  if { $SEL_NET_SETUP(via_limit) == 0 } { return }

  set start [clock seconds]

  # Search the selected paint for any via layers.
  set vialayers [techinfo layers via]

  # search only for relevant via paints, limit number to 1000.

  if { $SEL_NET_SETUP(via_limit) == -1 } {
    # via_limit == -1 means always select all via cells.
    # This could take awhile.
    set paints [db_search_l paint -cell __SELECT__ [join $vialayers ,]]
  } else {
    # If more than via_limit vias, dont select them; too time consuming.
    set limit [expr $SEL_NET_SETUP(via_limit) + 2]
    set paints [db_search_l paint -cell __SELECT__ -limit $limit [join $vialayers ,]]
    set llen [llength $paints]
    if {$llen > $SEL_NET_SETUP(via_limit)} { return }
  }

  set time1 [expr [clock seconds] - $start]


  foreach paint $paints {
    struct max_paint p $paint
    # This is a via layer.  Now look for cells at this spot.
    # We only select vias in the current cell.
    foreach cell [db_search_cells -area ${p.x1} ${p.y1} ${p.x2} ${p.y2}] {
      struct max_cell c $cell
      # Does it have "via" in the name?
      if {[regexp -nocase via ${c.def}]} {
	# It is a via.  But is it the one that contains vialayer?
	# There could be multiple vias at the same coordinates.
	# TODO: This fails if the cell contains the via layer
	# at some other location, but not where this via is.
	# This happened on the big power vias: They have a bunch
	# of empty internal space where the router put some vias,
	# so there is a regular via and a big power via at the same
	# spot, and they both are selected by this code.
	# Need to check if the via cell contains the via layer
	# at this coordinate, but that requires a transform.
	if { [_sel_cell_contains_paint ${c.def} ${p.layer}] } {
	  #sel_cell3 -more ${c.id}
	  sel_cell -more [cellinfo_name $cell]
	}
      }
    }
  }

  set time2 [expr [clock seconds] - $start]
  if { $time2 > 4 } {
    # Print time statistics.
    puts "sel_vias elapsed time $time2 ($time1 for [llength $paints] vias)"
  }
  return


  ### OLD SLOW METHOD
    set paintballs [split [string trim [sel_what paint] \n] \n]
    if {[llength $paintballs] == 0} { return }

    # Search the selected paint for any via layers.
    set vialayers [techinfo layers via]
    foreach paint $paintballs {
	struct max_paint p $paint
	set layer [dbt_short_name ${p.layer}]
	if { [lsearch -exact $vialayers $layer] >= 0 } {
	    # Found a via layer.  Now look for cells at this spot.
	    set cellinfo [db_search cells -area ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
	    foreach cell [split [string trim $cellinfo \n] \n] {
	      struct max_cell c $cell
	      # Does it have "via" in the name?
	      if {[regexp -nocase via ${c.def}]} {
		# Its a via.  But is it the one that contains vialayer?
		# There could be multiple vias at the same coordinates.
		if { [_sel_cell_contains_paint ${c.def} $layer] } {
		  sel_cell -more [cellinfo_name $cell]
		  #sel_cell3 -more ${c.id}
		}
	      }
	    }
	}
    }

}


proc select_area {{more ""}} -desc {
  called from the menus to select area
} -doc {
  this proc is needed because the built-in sel_area
  does not handle layer selectability from palette.
} {
  set layers [join [dbt_selectable_layers] ,]
  eval sel_area $more -layers $layers [layt_box exact]
}

proc select_cell_by_name {} -desc {
  NO LONGER USED.  proc bound to select cell by name on the menu 
} {
  global _SEL_CELL_BY_NAME
  use_init _SEL_CELL_BY_NAME(name) ""
  use_init _SEL_CELL_BY_NAME(zoom) 0
  use_init _SEL_CELL_BY_NAME(glob) 0
  use_init _SEL_CELL_BY_NAME(more) 0
  use_init _SEL_CELL_BY_NAME(search_inst) 0
  set prop_menu ""
  set kids [db_kids]

  set cell_types ""
  foreach kid $kids {
    if {[is_gcell $kid]} {
      # need to uniquify the gcell types.
      set gcells([gcell_typename $kid]) 1
    } else {
      lappend cell_types $kid
    }
  }

  foreach name [array names gcells] {
    if { $name == "GROUP" } {
      lappend cell_types "$name cells"
    } else {
      lappend cell_types "$name gcell"
    }
  }
  set cell_types [lsort $cell_types]

  set def_name [lindex $cell_types 0]
  set prop_list ""
  lappend prop_list [list "Search for:" _SEL_CELL_BY_NAME(search_inst) -radio {"Cell Def" "Cell Instance"} \
	-values {0 1} -reload]
  lappend prop_list [list "Enter Cell Def Name:" def_name -choice $cell_types -when {$_SEL_CELL_BY_NAME(search_inst)==0}]
  lappend prop_list [list "Enter Cell Instance Name:" _SEL_CELL_BY_NAME(name) -entry -when {$_SEL_CELL_BY_NAME(search_inst)==1} -width 30]
  lappend prop_list [list {Add to Existing Selection } _SEL_CELL_BY_NAME(more) -binary]
  lappend prop_list [list {Pattern match name} _SEL_CELL_BY_NAME(glob) \
	-binary -when {$_SEL_CELL_BY_NAME(search_inst)==1} \
      -help {Pattern matching, case insensitive, using characters:
      ?     match any character;
      *     match zero or more characters;
      \c    match character c
      [abc] match any one of the characters in brackets;
      [a-z] match range of characters;
      }]
  lappend prop_list [list "" "" -help {If searching for a cell def, all cells of the specified\
      type will be highlighted}]

  set title "Find Cell By Name"
  if {![prop_menu2 -title $title $prop_list]} {
    # cancelled
    return
  }

  if {!$_SEL_CELL_BY_NAME(more)} {
    sel_clear
  }

  set count 0

  if {$_SEL_CELL_BY_NAME(search_inst)} {
    if {$_SEL_CELL_BY_NAME(name) != ""} {
      if {$_SEL_CELL_BY_NAME(glob)} {
	# ugh
	set want [string toupper $_SEL_CELL_BY_NAME(name)]
	foreach cellinfo [db_search_cells] {
	  set thisid [cellinfo_id $cellinfo]
	  if {[string match $want [string toupper $thisid]]} {
	    sel_cell2 -more $thisid
	    incr count
	  }
	}
      } else {
	sel_cell2 -more $_SEL_CELL_BY_NAME(name)
	incr count
      }
    }
  } else {

    cursor_busy 1  ;# This could take awhile.

      # OLD CODE:
      #foreach cell [db_search_l cells] {
      #	struct max_cell c $cell
      #	if { [is_gcell ${c.def}] } {
      #	  set name [gcell_typename ${c.def}]
      #	  if { [gcell_typename ${c.def}] == [lindex $def_name 0] } {
      #	    sel_cell3 -more ${c.id}
      #	  }
      #	} else {
      #	  if { ${c.def} == $def_name } {
      #	    sel_cell3 -more ${c.id}
      #	  }
      #	}
      #}

    if {[llength $def_name] == 2} {
      # 8/27/01: NOTE: Currently there is a bug in db_kids
      # that if the gcells hash to the same value, they will
      # not show up as different in the list.
      # However, this bug does not affect this code for fet gcells,
      # because if the user asks for fets, we match all fets regardless of their props.

      foreach kid [db_kids] {
	if { [gcell_typename $kid] == [lindex $def_name 0] } {
	  foreach cell [db_instances -of $kid] {
	    #sel_cell3 -more [cellinfo_id $cell]
	    sel_cell -more [cellinfo_name $cell]
	    incr count
	  }
	}
      }

    } else {
      foreach cell [db_instances -of $def_name] {
	#sel_cell3 -more [cellinfo_id $cell]
	sel_cell -more [cellinfo_name $cell]
	incr count
      }
    }
    cursor_busy 0
  }

  msg "Selected $count cells\n"
}

proc select_by_name {} -desc {
  proc bound to select by name on the menu 
} {
  global _SEL_BY_NAME
  use_init _SEL_BY_NAME(net_name) ""
  use_init _SEL_BY_NAME(cell_name) ""
  use_init _SEL_BY_NAME(zoom) 0
  use_init _SEL_BY_NAME(glob) 0
  use_init _SEL_BY_NAME(more) 0
  use_init _SEL_BY_NAME(what) "Text"
  use_init _SEL_BY_NAME(hier) "none"

  set prop_menu ""

  set kids [db_kids]
  set cell_types ""
  foreach kid $kids {
    if {[is_gcell $kid]} {
      # need to uniquify the gcell types.
      set gcells([gcell_typename $kid]) 1
    } else {
      lappend cell_types $kid
    }
  }

  foreach name [array names gcells] {
    if { $name == "GROUP" } {
      lappend cell_types "$name cells"
    } else {
      lappend cell_types "$name gcell"
    }
  }
  set cell_types [lsort $cell_types]

  set def_name [lindex $cell_types 0]
  set prop_list ""
  global FPLAN
  if {[use_first FPLAN(exists)] == "1"} {
    set what_list {"Text" "Wire" "Net Connectivity" "Cell Instance" "Cell Def"}
  } else {
    set what_list {"Text" "Wire" "Cell Instance" "Cell Def"}
  }

  lappend prop_list [list "Search for:" _SEL_BY_NAME(what) -radio $what_list -reload \
    -help {For "Text", the specified text (labels) are selected.  \
	   For "Wire", the specified text and any attached layout geometry (wires) are selected. \
	   For "Net Connectivity", the specified net is shown using flylines. \
	   For "Cell Def", all cells of the specified type will be highlighted. \
	   }]

  lappend prop_list [list "Enter Cell Def Name:" def_name -choice $cell_types -when {$_SEL_BY_NAME(what)=="Cell Def"} -width 30]
  lappend prop_list [list "Enter Cell Instance Name:" _SEL_BY_NAME(cell_name) -entry -when {$_SEL_BY_NAME(what)=="Cell Instance"} -width 30]
  lappend prop_list [list "Enter Text (Label):" _SEL_BY_NAME(net_name) -entry -when {$_SEL_BY_NAME(what)=="Text"} -width 30]
  lappend prop_list [list "Enter Net Name:" _SEL_BY_NAME(net_name) -entry -when {$_SEL_BY_NAME(what)=="Net Connectivity"} -width 30]
  lappend prop_list [list "Enter Wire Name:" _SEL_BY_NAME(net_name) -entry -when {$_SEL_BY_NAME(what)=="Wire"} -width 30]

  lappend prop_list [list {Pattern match name} _SEL_BY_NAME(glob) \
	-binary -when {[regexp {Instance|Text|Wire} $_SEL_BY_NAME(what)]} \
      -help {Case insensitive glob-style pattern matching, using special characters:
      ?     match any character;
      *     match zero or more characters;
      \c    match character c
      [abc] match any one of the characters in brackets;
      [a-z] match range of characters;
      }]

  lappend prop_list [list {Add to Existing Selection } _SEL_BY_NAME(more) -binary]
  lappend prop_list [list {Zoom to selected} _SEL_BY_NAME(zoom) \
      -binary -help {Adjusts/zooms view to center what was selected}]

  lappend prop_list [list {Search:} _SEL_BY_NAME(hier) \
      -radio {current_cell any_visible_cell any_loaded_cell} \
      -values {none vis all} -when {[regexp {Instance|Text|Wire} $_SEL_BY_NAME(what)]}]

  set title "Find By Name"
  if {![prop_menu2 -title $title $prop_list]} {
    # cancelled
    return
  }

  if {!$_SEL_BY_NAME(more)} {
    sel_clear
  }

  set count 0

  switch $_SEL_BY_NAME(what) {
    "Net Connectivity" {
      fplan_sel_net -more $_SEL_BY_NAME(net_name)
    }

    "Wire" -
    "Text" {

      if {$_SEL_BY_NAME(net_name) == ""} {
	msg "Select by Name: No name specified.\n"
	return
      }

      # Build up select_net_by_name command.
      set cmd "select_net_by_name"
      if {$_SEL_BY_NAME(glob)} { lappend cmd "-glob" }
      if {$_SEL_BY_NAME(more)} { lappend cmd "-more" }
      if {$_SEL_BY_NAME(what) == "Text"} { lappend cmd -no_wires -no_vias }
      lappend cmd -hier $_SEL_BY_NAME(hier)
      lappend cmd $_SEL_BY_NAME(net_name)

      setl {found_labels unconnected_labels} [eval $cmd]

      if {[llength $found_labels] == 0} {
	mode_tmp_msg "No matching labels found"
      }

      # tell user what labels are on this net
      if {$_SEL_BY_NAME(what) == "Wire"} {
	# show the net to the user now just in case this next part takes a while
	update idletasks

	display_selected_labels

	if {$unconnected_labels != ""} {
	  set errmsg ""
	  foreach lab_info $unconnected_labels {
	    struct max_label l $lab_info
	    # Include label position in error message.
	    lappend errmsg  "${l.text} (${l.x1},${l.y1})"
	  }
	  max_error -buffer "warning: Unconnected labels: $errmsg"
	}
      }
    }

    "Cell Instance" {
      if {$_SEL_BY_NAME(cell_name) == ""} {
	msg "Select by Name: No name specified.\n"
	return
      }

      if {$_SEL_BY_NAME(glob) == 0 && $_SEL_BY_NAME(hier) == "none"} {
	# Can do it fast.
	sel_cell2 -more $_SEL_BY_NAME(cell_name)
	incr count
      } else {
	# ugh
	set want [string toupper $_SEL_BY_NAME(cell_name)]
	set cmd db_search_cells
	if {$_SEL_BY_NAME(hier) == "vis"} {
	  lappend cmd -any_cell
	} elseif {$_SEL_BY_NAME(hier) == "all"} {
	  lappend cmd -cell [lay_editcell] -any_cell
	}
	set glob $_SEL_BY_NAME(glob)
	foreach cellinfo [eval $cmd] {
	  set thisid [cellinfo_id $cellinfo]
	  if {$glob ? [string match $want [string toupper $thisid]] : $want == $thisid} {
	    sel_cell2 -more [cellinfo_name $cellinfo]
	    incr count
	  }
	}
      }
      msg "Selected $count cells\n"
    }

    "Cell Def" {
      cursor_busy 1  ;# This could take awhile.

      if {[llength $def_name] == 2} {
	# 8/27/01: NOTE: Currently there is a bug in db_kids
	# that if the gcells hash to the same value, they will
	# not show up as different in the list.
	# However, this bug does not affect this code for fet gcells,
	# because if the user asks for fets, we match all fets regardless of their props.

	foreach kid [db_kids] {
	  if { [gcell_typename $kid] == [lindex $def_name 0] } {
	    foreach cell [db_instances -of $kid] {
	      sel_cell -more [cellinfo_name $cell]
	      incr count
	    }
	  }
	}

      } else {
	foreach cell [db_instances -of $def_name] {
	  sel_cell -more [cellinfo_name $cell]
	  incr count
	}
      }
      cursor_busy 0
      msg "Selected $count cells\n"
    }
  }

  if { $_SEL_BY_NAME(zoom) } {
    zoom_to_selected
  }

}

proc select_cell_point {anycell {MoreOrLess ""}} -desc {
  implements the f and F menu commands to select cells at a point
} -doc {
  MoreOrLess can be "more" or "less" to to select more or less.
  Anycell is 1 to select in any cell, or 0 to select only in current cell.
} {
  global i_cmd SEL_CELL
  set fnd_any 0
  if { $MoreOrLess == "" } { sel_clear }

  # Construct a list of cells at the current point.
  # We will sort them to return the biggest sub-cell first,
  # down to the tiniest sub-cell, then the entire top-level cell.
  # TODO!!!
  # Remove any cells from the list that are invisible at the
  # current magnifcation.
  setl {x y} [layt_point exact]
  if {$anycell} {
    set any_cell "-any_cell"
  } else {
    set any_cell ""
  }
  # Note: the -user_bbox option does not exist in older maxes.
  if {[catch {set cells [eval db_search_cells $any_cell -user_bbox -area $x $y $x $y]}]} {
    set cells [eval db_search_cells $any_cell -area $x $y $x $y]
  }

  set cell_list ""
  foreach cell $cells {
    struct max_cell c $cell
    set fnd_any 1

    # Max returns cells whose real bbox overlaps the area x1 y1 x2 y2.
    # We only want cells whose user bbox overlaps this area.
    if {$x < ${c.x1}  || $x > ${c.x2} || $y < ${c.y1} || $y > ${c.y2}} {
      continue
    }

    # First element in list is nesting depth of sub-cell;
    # second element is full pathname of cell;
    # third element is cell def.
    set realid [cellinfo_name -array $cell]

    if {![use_list_path]} {
      regsub -all {[^/]*} $realid "" slashes
    }

    # 3/17: revert to original behavior f key behavior:
    # select all cells from smallest to largest.
    # If you uncomment below, it will select only cells
    # that have at least one visible boundary.
    #if { [rect_is_visible ${c.x1} ${c.y1} ${c.x2} ${c.y2}] }   #TODO!!
    if {[use_list_path]} {
      lappend cell_list [list [llength $realid] $realid ${c.def}]
    } else {
      lappend cell_list [list [string length $slashes] $realid ${c.def}]
    }
  }
  set cell_list [lsort -decreasing -index 0 $cell_list]

  # Add topmost cell in window as last element in list.
  #if { $MoreOrLess == "" && [eval rect_is_visible [lay_bbox]] }  #TODO!!
    lappend cell_list [list -1 {(Topmost Cell in Window)} [lay_rootcell]]

  # Select the correct cell.
  # If the list has not changed from last time,
  # continue feedback of previous list.
  if { [info exists SEL_CELL(f_list)] && \
	$i_cmd(num) == [expr $SEL_CELL(f_i_cmd) + 1] && \
	$SEL_CELL(f_list) == $cell_list } {
    # User has not moved cursor, nor executed any intervening commands,
    # continue feedback of previous list.
    set cell_index $SEL_CELL(f_index)
  } else {
    set cell_index 0
  }

  set len [llength $cell_list]
  if { $len == 0 } {
    if { $fnd_any } {
      tk_dialog .sel_cell_point "note" \
	{To select a cell, zoom out until you can see its borders} {} 0 "ok"
    } else {
      tk_dialog .sel_cell_point "note" \
	{No sub-cells found under cursor} {} 0 "ok"
    }
    return
  }
  if { $cell_index >= $len } {
    set cell_index 0
  }
  setl {junk rid def} [lindex $cell_list $cell_index]

  if { $rid == {(Topmost Cell in Window)}} {
    # Dont select anything, just show the top cell bounding box.
    switch -- $MoreOrLess {
      "more" { eval lay_box [lay_bbox] }
      "less" { lay_box 0 0 0 0 }
      ""     { sel_clear; eval lay_box [lay_bbox] }
    }
  } else {
    # Dont want to use eval to expand the -more flag,
    # because that would screw up cell names containing $ sign.
    # 1/31: changed from sel_cell3 to sel_cell!
    switch -- $MoreOrLess {
      "more" { sel_cell -more $rid }
      "less" { sel_cell -less $rid }
      "" { sel_cell $rid }
    }
  }
  _sel_cell_msg $rid $def

  # Save for next time.
  set SEL_CELL(f_index) [expr $cell_index + 1]
  set SEL_CELL(f_i_cmd) $i_cmd(num)
  set SEL_CELL(f_list) $cell_list
  return
}


proc select_net_menu {} -desc {
  Popup for select net options.  NOT CURRENTLY USED.
} {

  global SEL_NET_SETUP

  set title "Select Net Control"
  set message "Options:" 

  set prop_list ""

  lappend prop_list [list "Select attached vias" SEL_NET_SETUP(vias) \
    -choice {never "on small nets" always} -help {The "Select Net"\
    command can optionally select\
    attached via cells as well as wires.  You would want to select\
    the via cells if you were planning to move the wire, for example,\
    and want the attached vias to move with it.  However, selecting\
    the via cells is time consuming and unnecessary if all you are\
    doing is viewing the connectivity, which is typically the case\
    when selecting large nets.   Choose "on small nets" to\
    select attached vias only on nets with fewer than 1000 attached vias.}]
  lappend prop_list [list "Display selected labels" SEL_NET_SETUP(display_labels) \
    -binary -help {displays all unique labels on the net, which can be a long list.}]
  lappend prop_list [list "Display full hierarchical paths selected labels" \
    SEL_NET_SETUP(display_label_path) -binary]

  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return
  }
}

# Proc from Lee.
proc selt_net {{-max 10000} x y layer} -desc {
  like sel_net but returns early if finds a global port of net
} -doc {
  <max> is the maximum number of rectangles to search.
} {

  # First guess
  set n 500

  sel_clear
  while {1} {

    puts "Selecting with limit of $n ..."

    if {[sel_net -more -limit $n -point $x $y $layer] == 1} {
      # incomplete search, look for globals
      foreach label [sel_what_l labels] {
	if {[lindex $label 9] == "global"} {
	  # found a global, we're done
	  return $label
	}
      }
    } else {
      # complete
      return ""
    }

    if {$n > $max} {
      # too many to search -- maybe didn't use ports
      return -1
    }

    # try again
    set n [expr $n * 2]
  }
}



proc _select_is_paint_selected {x y layer} -desc {
  used only be select_cursed_net
} {
  # We do not have to search -any_cell, because we are checking only
  # if the layer might have been selected by sel_net, in which
  # case it will have been flattened.
  set thing [eval db_search paint -cell __SELECT__ \
	    -area $x $y $x $y $layer]
  return [expr {$thing != "" }]
}


proc select_cursed_net {{add ""}} -desc {
  select net under cursor
} {
  global SAVE_SELECT
  setl {x y} [layt_point exact]

  # Sorted from top to bottom.
  set possible_layers [lreverse [dbt_touchingtypes $x $y selectable]]

  # Restrict possible layers to known wiring layers.
  # If wire_layers not defined in tech file (because vias not defined)
  # then skip this step, which means we will attempt to sel_net
  # any paint under the cursor.
  set wire_layers [techinfo wire_layers "" opt]
  set layers ""
  if { $wire_layers != "" } {
    foreach lay $possible_layers {
      if {[lsearch -exact $wire_layers $lay] >= 0} {
	lappend layers $lay
      }
    }
  }

  if {$layers == ""} {
    # 3/1/01: Lee says if no wiring layers, just pick any old layer.
    set layers $possible_layers
  }

  if {$layers == ""} {
    if { $add == "" } {
	# no layers found, clear selection
	sel_clear
    }
    fplan_sel_net_point $x $y
    return
  }

  # Choose first (highest) wireable layer by default:
  set our_layer [lindex $layers 0]

  # Same location and layers as last "s" command?
  if {[info exists SAVE_SELECT(sel_net_xy)] && \
      $SAVE_SELECT(sel_net_layers) == $layers && \
      [eval nearby $x $y $SAVE_SELECT(sel_net_xy)] && \
      $SAVE_SELECT(sel_net_layers) == $layers} {
    # Yes.  Continue feedback of previous list.
    # Note that a single sel_net may select multiple layers if
    # they are inter-connected, so we look to see what is actually selected.
    # Start at bottom and highest unselected layer.  If bottom layer
    # is selected, select top layer.
    set bottom [lindex $layers end]
    if {[_select_is_paint_selected $x $y $bottom]} {
      # Select top layer.
      set our_layer [lindex $layers 0]
    } else {
      foreach lay [lreverse $layers] {
	if {! [_select_is_paint_selected $x $y $lay]} {
	  set our_layer $lay
	} else {
	  break
	}
      }
    }
  }

  set SAVE_SELECT(sel_net_xy) "$x $y"
  set SAVE_SELECT(sel_net_layers) $layers


  # select away
  layt_box exact $x $y $x $y
  # Note: sel_net does not support -less yet.
  # I am not sure it ever should. (pat)
  switch $add {
  "add" { set more -more }
  "sub" {
	# This does not work in the C code yet:
	# set more -less
	set more ""
  }
  ""    { set more "" }
  }

  global MAX_NEW_SELECT
  if {[use_first MAX_NEW_SELECT] == 1} {
      # What should we do about sel_net -more??
      #db_group selected
      #sel_group_transfer 0
  }

  # The sel_net command will not be undo-able, ie, user will not
  # see the results in the undo list.  It takes up too much memory,
  # and its no big deal because you cant do anything to the selection anyway.
  # Mha says no: cant do this unless you also undo_disable around sel_clear.
  #undo_disable

  # Initial number of rectangles to select before prompting user if
  # they want to continue
  set limit 2000

  while {1} {
    set result ""
    if {$more == ""} {
      # Try looking a little while, then ask the user if they want to keep going.
      if {$limit > 0} {
	set result [sel_net -point $x $y -limit $limit $our_layer]
      } else {
	sel_net -point $x $y $our_layer
      }
    } else {
      eval sel_net $more -point $x $y $our_layer
    }
    sel_vias
    #undo_enable

    if {[use_first MAX_NEW_SELECT] == 1} {
	#sel_group_transfer selected
	#db_group 0
    }

    # show the net to the user now just in case this next part takes a while
    update

    # tell user what labels are on this net

    global SEL_NET_SETUP
    if {$SEL_NET_SETUP(display_labels)} {
      # do it
      display_selected_labels
    }
  
    if {$result == 1} {
      set msg "This is a large net.  Do you want to continue selecting it?"
      set ret [prop_dialog -buttons "Continue Cancel" $msg]
      if {$ret == "Continue"} {
	set limit 0
	continue
      }
    }

    return
  }
}


proc display_selected_labels {} -desc {
  display selected labels in the mode_msg area and in text window
} {

  global SEL_NET_SETUP

  set labels ""
  foreach label [sel_what_l labels] {
    set name [lindex $label 6]
    if {$name == ""} {
      continue
    }

    # don't put in duplicates or hidden labels
    set type [lindex $label 9]
    switch $type {
      hidden {
	# do nothing
      }
      global {
	# add minus path
	set array($name) 1
      }
      default {
	# add with path
	if {$SEL_NET_SETUP(display_label_path)} {
	  set path [lindex $label 7]
	} else {
	  set path ""
	}
	set array($path$name) 1
      }
    }
  }

  regsub -all {\{|\}} [lsort -dictionary [array names array]] "" list
  switch [llength $list] {
    0 {
      mode_inform_msg "Selected net: (no labels on net)"
    }
    1 {
      mode_inform_msg "Selected net: $list"
    }
    default {
      mode_inform_msg "Selected nets: $list"
    }
  }
}  


proc select_mode_enter {{add ""}} -desc {
  select what's under the cursor or what's inside a drag box
} {
  global SAVE_SELECT TOOL_BAR

  set mode ""
  if { $add != "" } {
      set mode $add
  } elseif { [use_first TOOL_BAR(select_mode)] != "" } {
      # The TOOL_BAR(select_mode) is uninitialized if the tool_bar
      # code is not being used.
      set mode $TOOL_BAR(select_mode)
  }
  switch $mode {
    "add" {set SAVE_SELECT(more) "more"}
    "sub" {set SAVE_SELECT(more) "less"}
    default { set SAVE_SELECT(more) "" }
  }

  # We use the user grid for the selection box because we want
  # the paint that is automatically selected by max's dopey
  # automatic selection mechanism to be cut on the user grid.
  # But if it is a point-click select, we will use the exact point.
  # So start with a zero-size exact box, which will get aligned
  # to the user grid during the drag.
  set SAVE_SELECT(start_xy) [layt_point exact]
  eval layt_box exact $SAVE_SELECT(start_xy) $SAVE_SELECT(start_xy)

  # enter "select" mode
  mode_push select

  switch $mode {
    "add" {
      mode_msg "select mode.  BUT-1 drags box to select more"
    }
    "sub" {
      mode_msg "deselect mode.  BUT-1 drags box to select less"
    }
  }
}

proc _select_gate_keeper {event} {
    global mode_abort SAVE_SELECT

    if {$event == "PUSH_TO"} {
	pan_enable
	switch -- $SAVE_SELECT(more) {
	"more" { cursor_mode select }
	"less" { cursor_mode deselect }
	default { cursor_mode select }
	}
    } elseif {$event == "POP_FROM"} {
	pan_disable
	i_cmd_between 0
    }
}

proc _select_mode_define {} -desc {
  sets up a select drag box mode
} {
  mode_def select _select_gate_keeper "BUT1 drags select box"

  mode_bind -cmd 0 select <Any-B1-Motion> _select_drag
  mode_bind -cmd 0 select <Any-B1-ButtonRelease> _select_end

  global SAVE_SELECT
  # If user is single-clicking to step through objects at a point,
  # original_xy is where the first click took place.
  set SAVE_SELECT(original_xy) "-1.0e20 -1.0e20"
  set SAVE_SELECT(layer) ""
  set SAVE_SELECT(cmdnum) -1
  set SAVE_SELECT(list) ""
  set SAVE_SELECT(list_index) 0
  set SAVE_SELECT(mark_select) "more"
}

proc _select_drag {} -desc {
  drags a select box
} {
  global SAVE_SELECT 

  catch { destroy .probe }

  pan_auto _select_drag
    
  setl {x y} [layt_point user]
  if {$x == "" || $y == ""} {
    # off screen
    return
  }
  eval layt_box user $SAVE_SELECT(start_xy) $x $y
  box_msg_update
}

proc _sel_list_paint_rects {layer sbox f_chunks} -doc {
  Return the interesting (to the user) paint rectangle covering sbox.

  If <f_chunks>, return multiple possible rectangles.

  <sbox> is "x1 y1 x2 y2", but x2 and y2 are ignored.
} {
  global SAVE_SELECT

  assert { $layer != "subcell" }

  # First look in the cache:  Search for the "layer" we want.
  global MAX_STRUCT
  set index [lsearch $MAX_STRUCT(select_struc) "layer"]
  set paints [lsearch2 -value -index $index $SAVE_SELECT(paint_cache) $layer]
  if { $paints != "" } {
    return $paints
  }

  set item.sortkey 0
  set item.layer $layer
  set item.type paint
  set item.text ""
  set item.other ""
  set item.sbox $sbox
  set paints ""

  # This code for debugging db_next_distance
  # If variable DB_NEXT_DISTANCE_BUG is set,
  # then include that result in the selection.
  global DB_NEXT_DISTANCE_BUG
  if { $DB_NEXT_DISTANCE_BUG == 0 } {
    # Only return db_chunk result.  Nothing else works.
    set item.bbox [eval dbt_chunk $layer $sbox]
    if { ${item.bbox} != "" } {
      #set item.sortkey [incr key]
      lappend paints [destruct select_struc item]
    }
  } else {

    # Assumes sbox is a point!
    setl {x y} $sbox
    if { $f_chunks } {
      # Return a list of all the interesting rectangles.
      set bbox1 [_sel_smallest_box $layer $x $y]
      if { $bbox1 != "" } {
	set item.bbox $bbox1
	#set item.sortkey [incr key]
	lappend paints [destruct select_struc item]
      }

      # Add in a larger box, provided by db_chunk.
      set bbox2 [eval dbt_chunk $layer $sbox]
      if { $bbox2 != "" && $bbox2 != $bbox1 } {
	set item.bbox $bbox2
	#set item.sortkey [incr key]
	lappend paints [destruct select_struc item]
      }

      # Add in the alternate chunk, if different.
      setl {xx yy} $sbox
      set bbox3 [dbt_chunk2 $layer $xx $yy]
      if { $bbox3 != "" && $bbox3 != $bbox1 && $bbox3 != $bbox2 } {
	set item.bbox $bbox3
	#set item.sortkey [incr key]
	lappend paints [destruct select_struc item]
      }
    } else {
      # Return only the db_chunk result.
      # This code is used when doing select more (shift-button1)
      set item.bbox [eval dbt_chunk $layer $sbox]
      if { ${item.bbox} != "" } {
	#set item.sortkey [incr key]
	lappend paints [destruct select_struc item]
      }
    }
  }

  lappend SAVE_SELECT(paint_cache) $paints
  return $paints
}


proc _sel_list_reset {{list __UNDEFINED__}} {
  global SAVE_SELECT
  if { $list != "__UNDEFINED__" } {
    set SAVE_SELECT(list) $list
    set SAVE_SELECT(paint_cache) ""
  }
  set SAVE_SELECT(list_index) 0
  set SAVE_SELECT(paint_index) 0
}

if {0} {
  proc _UNUSED_sel_list_get {n} -desc {
    return select_struc for nth thing in object list.
  } -doc {
    This can only return one paint rectangle for each paint layer.
  } {
    set thing [lindex $SAVE_SELECT(list) $n]
    if { $thing == "" } { return "" }

    struct select_struc item $thing
    if { ${item.type} == "paint" } {
      setl {x y} ${item.sbox}  ;# x2 y2 in sbox are ignored.
      return [lindex [_sel_list_paint_rects ${item.layer} ${item.sbox} 0] 0]
    } else {
      return $thing
    }
  }
}


proc _sel_list_get_next {f_chunks {f_loop 1}} -desc {
  return select_struc structure corresponding to next thing in object list.
} -doc {
  This returns the next object in the list created by _select_list,
  except, if the object is paint, and f_chunks == 1, it may
  return, at its own discretion, mutiple interesting paint rectangles.

  It would have been much easier to calculate all the objects
  under the cursor and add them to the SAVE_SELECT(list) originally
  generated by _select_list.  However, paint rectangles are so slow
  to compute in tcl, calculation is deferred until needed.
  For paint, the select_list just has any old paint rectangle in it.
  Then if the user tries to select that paint, this routine looks
  more closely to generate additional interesting paint rectangles as needed.

  If f_chunks, return multiple useful paint rectangles,
  otherwise return only 1.

  If f_loop, when list exhausted, go back to first element.
} {
  global SAVE_SELECT

  if { $f_loop && $SAVE_SELECT(list_index) >= [llength $SAVE_SELECT(list)] } {
      _sel_list_reset
  }

  set thing [lindex $SAVE_SELECT(list) $SAVE_SELECT(list_index)]
  if { $thing == "" } { return "" }

  struct select_struc item $thing
  if { ${item.type} == "paint" } {
    # Paint rectangles are cached in the paint_rects list.
    set layer ${item.layer}
    set paints [_sel_list_paint_rects $layer ${item.sbox} $f_chunks]

    set thing [lindex $paints $SAVE_SELECT(paint_index)]
    incr SAVE_SELECT(paint_index)

    if { $SAVE_SELECT(paint_index) == [llength $paints] } {
      set SAVE_SELECT(paint_index) 0
      incr SAVE_SELECT(list_index)
    }

  } else {
    incr SAVE_SELECT(list_index)
  }

  return $thing
}


proc _select_is_item_selected {thing {anypaint ""}} -desc {
  Return 1 if item is selected
} -doc {
  See if item is selected.
  Thing is a structure (aka list) of type select_struc

  For paint, there are many possible paint tiles covering any
  given point.  If anypaint is "-anypaint", just see if there is any paint
  at all at that point.  Otherwise, see if any currently selected
  paint encloses the paint bbox specified by thing.

  Uses global PROBE(cache_*) so calls to this function must
  be preceded by a call to _select_update_cache.
} {
    global PROBE
    struct select_struc item $thing

    switch ${item.type} {
      "label" {
	 foreach label $PROBE(cache_labels) {
	    if { $label == ${item.other} } { return 1 }
	 }
      }
      "paint" {
	if { $anypaint == "-any_paint" } {
	  #foreach paint [split $PROBE(cache_paint) "\n"] {
	  #  # Test if paint encloses the point x,y
	  #  setl {layer tx1 ty1 tx2 ty2} $paint
	  #  if { $layer == ${item.layer} &&
	  #    $x >= $tx1 && $x <= $tx2 && $y >= $ty1 && $y <= $ty2 } {
	  #    return 1
	  #  }
	  #}

	  set thing [eval db_search paint -cell __SELECT__ \
	    -area ${item.sbox} ${item.layer}]
	  if { $thing != "" } { return 1 }

	} else {
	  # Test if paint encloses the item bbox.
	  set chunk [eval dbt_chunk -cell __SELECT__ ${item.layer} ${item.bbox}]
	  if { $chunk != "" } {
	    # If chunk succeeds, the entire piece of paint was in the selection.
	    return 1
	  }
	}
      }
      "polygon" {
	 foreach poly $PROBE(cache_polygons) {
	     # just compare the layer and coords.
	     # could maybe just compare p1 and p2.
	     struct max_polygon p1 $poly 
	     struct max_polygon p2 ${item.other}
	     if {${p1.layer} == ${p2.layer} && ${p1.coords} == ${p2.coords}} {
	       return 1
	     }
	 }
      }
      "wirepath" {
	 # TODO: This code just doesnt work.
	 # There is no sel_what wirepaths command,
	 # and the sel_what polygons returns the bouding boxes,
	 # which we can not correlate with the wirepaths.

	 foreach poly $PROBE(cache_wirepaths) {
	     # just compare the layer and coords.
	     # could maybe just compare p1 and p2.
	     struct max_wirepath p1 $poly 
	     struct max_wirepath p2 ${item.other}
	     if {${p1.layer} == ${p2.layer} && ${p1.coords} == ${p2.coords}} {
	       return 1
	     }
	 }
      }
      "cell" {
	 foreach cellstring $PROBE(cache_cells) {
	   if {[cellinfo_name $cellstring] == ${item.text}} { return 1 }
	 }
      }
    }
    return 0
}

proc cell_path_clean_gcell {cellpath} -desc {
  # Strip all the extra props out of the gcell names in the cell path.
} {
  regsub -all {/#([a-zA-Z]+)[^/]*} $cellpath {/\1} cellpath
  return $cellpath
}

proc _sel_cell_msg {cellid celldef} -desc {
  print message for name of cell
} {
  set cellid [cell_path_clean_gcell $cellid]
  set celldef [cell_path_clean_gcell $celldef]

  if {[is_gcell ${celldef}]} {
    set gtype [gcell_typename $celldef]
    set cellid [string trim $cellid /]
    if {[string first / $cellid] == -1} { 
      # Its a fet in the current edit cell.
      mode_tmp_msg "selected cell is gcell: $gtype  ( $gtype )\n"
    } else {
      set cellid [file dirname $cellid]
      mode_tmp_msg "selected cell is gcell: $gtype  ( $cellid/$gtype )\n"
    }
  } elseif { $celldef == [lay_rootcell] } {
    mode_tmp_msg "topmost cell in window is ${celldef}\n"
  } elseif { $cellid == "" } {
    # This happens from the cell finder menu:
    # No cellid means the cell is in the edit stack hierarchy above us.
    mode_tmp_msg "cell is ${celldef}\n"
  } else {
    set cellid [string trim $cellid /]
    mode_tmp_msg "selected cell is cell: ${celldef}  ( ${cellid} )\n"
  }
}


proc _select_item {thing verbose {option ""}} -desc {
  Select the specified item, which is a list of type select_struc
} -doc {
  The option can be "more" or "less"
  Note: if option is "less", the paint/polygons in the selection
  are merged.  We decided it was ok because user would normally
  only do less when setting up the selection initially.
  If option is not "less", set the box to something
  appropriate for the selected item.
} {
  global SAVE_SELECT SELECT_ANY_CELL
  struct select_struc item $thing
#puts "select_item $option $thing"
  switch $option {
    "more" {
      set area_option "-more"; set cell_option "-more"
      set polygon_option ""
      set label_option "-more"
    }
    "less" {
      # -any_cell is needed because sel_area is not implemented
      # to do -less without it.  Its ok, doesnt matter.
      set area_option "-less -any_cell"; set cell_option "-less"
      set polygon_option "-less"
      set label_option "-less"
      global MAX_NEW_SELECT
      if {[use_first MAX_NEW_SELECT] == 1} {
	  db_group selected
	  sel_group_transfer 0
      }
    }
    "" {
      set area_option ""; set cell_option ""
      set polygon_option ""
      set label_option ""
    }
  }

  if { $SELECT_ANY_CELL } {
    append label_option " -any_cell"
    append area_option " -any_cell"
    append polygon_option " -any_cell"
  }

  switch ${item.type} {
    "label" {
      # If it is a point label, then x1==x2 and y1==y2.
      # If it is a box label, we can select it with -rect.
      struct max_label lab ${item.other}
      eval sel_labels -layer ${item.layer} $label_option -rect ${item.bbox} \
	-kind ${lab.kind} -layer ${lab.layer} -pos ${lab.pos} -text {${lab.text}}
      if { $verbose == "verbose" && $option != "less" } {
	  mode_tmp_msg "selected label is ${item.text} on layer ${item.layer}\n"
      }

      # If only a single label is being selected, the box is
      # currently set to a point at wherever the user clicked.
      # Move the box to be a point exactly on the label.
      # For box labels, we really would like to put it on
      # the label edge, but too hard for now, so just leave it.
      setl {x1 y1 x2 y2} ${item.bbox}
      if {$option != "less" && [approx $x1 == $x2] && [approx $y1 == $y2]} {
	  layt_box exact $x1 $y1 $x1 $y1
      }
    }
    "paint" {
      if { $option == "less" } {
	# These options dont work with -less, currently, so dont do it.
	# append area_option " -no_wp -no_poly"
	eval sel_area -layers ${item.layer} $area_option ${item.bbox}
	# Deselect again to make sure we deselect the biggest piece.
	# Note: -any_cell needed to db_chunk so that it returns
	# root-cell coords instead of edit-cell coords, which is
	# important when editing in place.
	eval sel_area -layers ${item.layer} $area_option \
	     [eval dbt_chunk -any_cell ${item.layer} ${item.bbox}]
      } else {
	append area_option " -no_wp -no_poly"
	eval sel_area -layers ${item.layer} $area_option ${item.bbox}
	eval layt_box exact ${item.bbox}
	if { $verbose == "verbose" && $option != "less" } {
	  mode_tmp_msg "selected paint on layer ${item.layer}"
	}
      }
    }
    "wirepath" {
      # db_search returns center line coords of wirepath,
      # but db_polygons returns bounding boxes of individual
      # components of the wirepath, so there is no hope of
      # finding the wirepath in the db_polygons list,
      # so we could maybe use sel_polygons.
      # Instead, we will choose a point on the wirepath to select,
      # and just hope there are no other polygons around there.
      # Our best shot is selecting right in the middle of
      # the longest segment of the wirepath, so find it now.
      struct max_wirepath wp ${item.other}
      # number of points in wirepath.

      if {0} { ;# removed 8/3/00
	set longest_len 0
	set llen [llength ${wp.coords}]
	for {set i 0} {$i < $llen - 2} {incr i 2} {
	  setl {wx1 wy1 wx2 wy2} [lrange ${wp.coords} $i [expr $i+4]]
	  # well, not quite the length, but a close enough metric
	  set wlen [expr abs($wx2 - $wx1) + abs($wy2 - $wy1)]
	  if { $wlen > $longest_len } {
	    set cx [uusnap [expr ($wx1 + $wx2) / 2]]
	    set cy [uusnap [expr ($wy1 + $wy2) / 2]]
	    set longest_len $wlen
	  }
	}
      }

      # TODO: BUG BUG BUG!!!
      # This will select the wrong wirepath if there are multiple
      # wirepaths at x,y, even if they are on different layers.
      # Want to use -layers, but it doesnt work for wirepaths.
      # Even then, it wouldnt be reliable if multiple wirepaths
      # on the same layer.  What we really want is a sel_wire_path command.

      eval sel_area $area_option -no_labels -no_poly -no_tiles -layers ${item.layer} ${item.sbox}

      if { $verbose == "verbose" && $option != "less" } {
	mode_tmp_msg "selected wirepath on layer ${item.layer}"
      }

      # I dont know what to do with the box.
      # We cant turn it off.
      eval layt_box exact ${item.sbox}
    }
    "polygon" {
      # Dont want a special case for -less, because it confuses the
      # user when it doesnt work.
      # Tempted to use sel_polygons -less, and just wait for mha to implement it.
      if {1} {
	# sel_polygons -less STILL NOT IMPLEMENTED!!!

	# TODO: BUG BUG BUG!!!
	# This will select the wrong polygon if there are multiple
	# polygons at x,y, even if they are on different layers.
	# Want to use -layers, but it doesnt work for polygons.
	# Even then, it wouldnt be reliable if multiple polygons
	# on the same layer.  What we really want is
	# sel_polygons to work.
	eval sel_area $area_option -layers ${item.layer} -no_labels -no_wp -no_tiles ${item.sbox}
      } else {
	# TODO: This code works, but sel_polygons -less not implemented,
	# so we dont use it at all, cause its confusing when user
	# can select polygons, but not deselect them.

	# select it properly and reliably.
	struct max_polygon pol ${item.other}
	set i [_find_polygon ${pol.layer} ${pol.coords}]
	if { $i == "" } {
	  # The polygon is in a different cell.
	  # This can happen from the probe window if any_cell is set.
	  global PROBE
	  assert { $PROBE(any_cell) }
	} else {
	  eval sel_polygons $polygon_option $i

	  if { $verbose == "verbose" && $option != "less" } {
	    mode_tmp_msg "selected polygon on layer ${item.layer}"
	  }
	}
      }

      # I dont know what to do with the box.
      # We cant turn it off.
      eval layt_box exact ${item.sbox}
    }
    "cell" {
      set realid [cellinfo_name ${item.other}]
      # Extra curly braces required in case text has $ in it.
      eval sel_cell $cell_option {$realid}

      if { $verbose == "verbose" && $option != "less" } {
	struct max_cell cell ${item.other}
	_sel_cell_msg $realid ${cell.def}
	#_sel_cell_msg ${cell.id} ${cell.def}
      }
    }
  }

  # Put the newly selected thing in the selected group.
  global MAX_NEW_SELECT
  if {[use_first MAX_NEW_SELECT] == 1} {
      db_group 0  ;# Not needed
      sel_group_transfer selected
  }
  db_group 0
}


proc _select_something {mode list} -desc {
  select something from the list, return true if success
} -doc {
  This code is used in "Mark Select" mode (currently bound
  to shift-button1) to find something under the cursor
  to select (mode == "more") or deselect (mode == "less")
} {
  _sel_list_reset
  while { [set thingy [_sel_list_get_next 0 0]] != "" } {
    if { $mode == "more" } {
      # In "more" mode, if the item is paint, we will cycle
      # through each of the paint selections.
      if {! [_select_is_item_selected $thingy]} {
	_select_item $thingy verbose more
	return 1
      }
    } else {
      # In "less" mode, we pass x,y to _select_is_item_selected,
      # to find any paint tile at those coords: if any paint
      # is found, deselect it.
      if {[_select_is_item_selected $thingy -any_paint]} {
	_select_item $thingy verbose less
	return 1
      }
    }
  }
  return 0
}


proc _select_end {} -desc {
  bound to button release after dragging a select box
} {
  global SAVE_SELECT i_cmd
  global SELECT_ANY_CELL

  cursor_busy 1

  catch { destroy .probe }

  setl {x y} [layt_point exact]
  if {[eval nearby $x $y $SAVE_SELECT(start_xy)]} {

    # User just clicked and didn't stroke out a region
    # We must use the exact location in case the cursor
    # is over pre-existing paint that is off-grid.
    # Set the box to the point, in case nothing is selected, this
    # is where the box will be left.
    set start_xy $SAVE_SELECT(start_xy)
    eval layt_box user $start_xy $start_xy

    # Get a list of everything under this point.
    set list [eval _select_list $start_xy $start_xy $SELECT_ANY_CELL selectable]

    # If the user didnt do any intervening operations, and the list
    # of selected stuff at the current point hasnt changed,
    # or if the cursor is still nearby the previous point,
    # continue feedback of previous list.
    # Why do we check both? because if the user is really zoomed out
    # and extremely close to the edge of something, cursor jitter
    # could change the list each time, even though the user
    # is trying not to move the mouse.
    # This beats the previous method of seeing if the cursor hadnt moved,
    # which was hard for the user.
    # Use exact coords, because we are trying to see if the cursor wiggled.
    if { $i_cmd(num) == [expr 1+ $SAVE_SELECT(cmdnum)] && \
	      ([eval nearby $x $y $SAVE_SELECT(original_xy)] || \
	      $list == $SAVE_SELECT(list)) } {
      # If the user didnt do any intervening operations, and the list
      # of selected stuff at the current point hasnt changed,
      # or if the cursor is still nearby the previous point,
      # continue feedback of previous list.
      # Why do we check both? because if the user is really zoomed out
      # and extremely close to the edge of something, cursor jitter
      # could change the list each time, even though the user
      # is trying not to move the mouse.
      # This beats the previous method of seeing if the cursor hadnt moved,
      # which was hard for the user.
      # Use exact coords, because we are trying to see if the cursor wiggled.
    } else {
      # New cursor location, start new feedback list.
      _sel_list_reset $list

      set SAVE_SELECT(mark_select) "more"
      set SAVE_SELECT(original_xy) $SAVE_SELECT(start_xy)
    }

    if {$SAVE_SELECT(more) == ""} {
      sel_clear

      set thing [_sel_list_get_next 1]
      if { $thing != "" } {
	_select_item $thing verbose
      }
    } else {

      # Select the next thing in the list.
      # Mark wants this complicated method:
      # look through the list and select the items one at
      # a time from front to back, then when all are selected,
      # deselect them one at a time in the same order.
      # Have to save state to tell where we are in this scheme,
      # which is what the SAVE_SELECT(mark_select) is for.
      _select_update_cache $x $y
      if { $SAVE_SELECT(more) == "more" } {
	# This case is hooked to shift-button-1: select something
	# more under the cursor.
	# We are going to use marks complicated method:
	# Make a list of all objects under the cursor, and first add them
	# to the selection one by one, then when all are selected,
	# remove them from the selection in the same order, one by one.
	# This does not allow you to generate any arbitrary combination
	# of selected things, but at least it makes some sense.
	# If mark_select == "more", we are trying to select another
	# thing.  If everything is already selected, set mark_select == "less"
	# and try to select one less thing.
	if { $SAVE_SELECT(mark_select) == "more" } {
	  # We are trying to select something more.
	  if { ! [_select_something more $list] } {
	    # Failed.  Deselect something, and save state to make
	    # us deselect again on the next mouse click, unless
	    # the user moves the mouse.
	    set SAVE_SELECT(mark_select) "less"
	    _select_something less $list
	  }
	} else {
	  # We are in mark's complicated deselect mode.
	  if { ! [_select_something less $list] } {
	    # Failed to deselect anything.  Try to select something.
	    set SAVE_SELECT(mark_select) "more"
	    _select_something more $list
	  }
	}
      } else {
	# SAVE_SELECT(more) is "less"
	# Just deselect something.  Anything.
	_select_something less $list
      }
    }

  } else {
    # user stroked out a region
    set SAVE_SELECT(layer) ""

    # only select layers that are visible and selectable, plus labels.
    # TODO: won't pick up labels on "space" layer.  Can't add ,labels
    # or will get all labels, even on non-visible layers
    set layers [join [dbt_selectable_layers] ,]

    if {$SAVE_SELECT(more) == ""} {
      sel_clear
    }

    #:select -g -editOnly more area $layers
    # The -group is not really necessary, but its nice for debugging
    # so you can tell immediately when a bug leaves something in the
    # wrong group.
    switch $SAVE_SELECT(more) {
    "more" {
	set option "-more"
	if { $SELECT_ANY_CELL } {
	  append option " -any_cell"
	}
      }
    "less" {
	set option "-less -any_cell"
	global MAX_NEW_SELECT
	if {[use_first MAX_NEW_SELECT] == 1} {
	    db_group selected
	    sel_group_transfer 0
	}
      }
    "" {
	set option ""
	if { $SELECT_ANY_CELL } {
	  set option -any_cell
	}
      }
    }
    # If no layers are selectable, then layers will be "",
    # and sel_area will barf.
    if { $layers != "" } {
	eval sel_area -group $option -layers ${layers} [layt_box exact]
    }
    # Always add labels on layer space.
    # Labels on other layers were already selected above, if the
    # layer is selectable according to the palette.
    switch $SAVE_SELECT(more) {
    "more" -
    "" {
      eval sel_labels -more -layer space -inside [layt_box exact]
      }
    "less" {
      # 8/00:This generates error: sel_labels -any_cell not implemented.
      #eval sel_labels -less -any_cell -layer space -inside [layt_box exact]
      eval sel_labels -less -layer space -inside [layt_box exact]
      }
    }

    global MAX_NEW_SELECT
    if {[use_first MAX_NEW_SELECT] == 1} {
	sel_group_transfer selected
    }
    db_group 0

    if {1} {
      # Now lets print a nice message.
      # We would like to print a count of each type, but its too expensive
      # to compute?
      set stypes ""
      if { [sel_what types] != "" } {
	lappend stypes "paint"
      }
      if { [sel_what cells -boolean] } {
	lappend stypes "cells"
      }
      if { [sel_what polygons -limit 1] != "" } {
	lappend stypes "polygons"
      }
      if { [sel_what labels -limit 1] != "" } {
	lappend stypes "labels"
      }
      if { $stypes == "" } {
	mode_tmp_msg "nothing selected"
      } else {
	mode_tmp_msg "selection contains [join $stypes {, }]"
      }
    }

    # add any labels in the current group to der selection
    #if { $SAVE_SELECT(more) == "less" } {
    #	eval sel_labels -less -any_cell -inside [layt_box exact] -layer space
    #} else {
    #	# SAVE_SELECT(more) is "-more" or ""
    #	eval sel_labels -more -inside [layt_box exact] -layer space
    #}
  }

  set SAVE_SELECT(cmdnum) $i_cmd(num)

  # This is probably not necessary; we are probably exiting
  # back to main mode, which will reset the cursor.
  cursor_busy 0

  select_end_hook
  select_end_label_hook

  mode_pop
}

if {0} {
# TODO: Use this new proc in proc _select_list, below
# I put this in to use for align, but then decided not to align paint.

proc select_make_struc {type sortkey data} -desc {
  return a select_struc for the specified type of item
} -doc {
  the incoming data is in sel_what format
  the returned data is in struct select_struc format
} {
  switch $type {
    "label" {
      struct max_label lab $data
      set item.sortkey $sortkey
      set item.type label
      set item.layer ${lab.layer}
      set item.bbox [list ${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2}]
      set item.text  ${lab.text}
      set item.other $data
      return [destruct select_struc item]
    }
    "paint" {
      struct max_paint p $data
      assert { ${p.layer} != "subcell" }
      set item.sortkey $sortkey
      set item.type paint
      set item.layer ${p.layer}
      set item.bbox [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
      set item.text ""
      set item.other ""
      return [destruct select_struc item]
    }
    "wirepath" {
      set item.sortkey $sortkey
      set item.type wirepath
      set item.layer ${p.layer}
      set item.bbox ${p.bbox}
      set item.text ""
      set item.other $data
      return [destruct select_struc item]
    }
    "polygon" {
      struct max_polygon p $data
      set item.sortkey $sortkey
      set item.type polygon
      set item.layer ${p.layer}
      set item.bbox ${p.bbox}
      set item.text ""
      set item.other $data
      return [destruct select_struc item]
    }
    "cell" {
      struct max_cell cell $cellstring
      set item.sortkey $sortkey
      set item.type cell
      set item.layer ""
      set item.bbox "${cell.x1} ${cell.y1} ${cell.x2} ${cell.y2}"
      #set item.text  ${cell.id}
      set item.text  [cellinfo_name $cellstring]
      set item.other $data
      return [destruct select_struc item]
    }
  }
}
}

proc _select_list {x1 y1 x2 y2 f_any_cell vis} -desc {
  Return a list of cells, labels, paint and polygons under cursor.
} -doc {
  If f_any_cell == 1, will search in any expanded (currently visible) cell,
  else only the current (edit?) cell.  If vis == 1, uses the palette
  to control what paint and labels are returned.
  List format is: sort_key type layer bbox
  Where: sort_key is a number the paint/polygons will be sorted by;
  type is "label", "paint" or "polygon"; layer is the layer;
  bbox is the four coords for paint/label or the bbox for polygons.
  Note: this procecure destroys the current selection and moves the box.
} {

  if {$f_any_cell} { set any_cell "-any_cell" } else { set any_cell "" }

  if {$vis == "visible"} {
    set layer_list [lremove [dbt_visible_layers] subcell]
  } else {
    set layer_list [lremove [dbt_selectable_layers] subcell]
  }
  set layer_join [join $layer_list ","]

  set list ""

  set item.sbox [list $x1 $y1 $x2 $y2]

  # Try looking for labels first.  If the user just clicked, look for
  # labels near the mouse point adjusted by the zoom of the current view.
  set near [nearby_dist]
  setl {nx1 ny1 nx2 ny2} [list $x1 $y1 $x2 $y2]
  if { [approx $x1 == $x2] } {
      set nx1 [expr $x1 - $near]
      set nx2 [expr $x2 + $near]
  }
  if { [approx $y1 == $y2] } {
      set ny1 [expr $y1 - $near]
      set ny2 [expr $y2 + $near]
  }

  # db_search labels does -any_cell by default.
  if {$f_any_cell} {
    # db_search_labels searches any visible cell by default.
    set labels [db_search_labels -area $nx1 $ny1 $nx2 $ny2]
  } else {
    set labels [db_search_labels -non_hier -area $nx1 $ny1 $nx2 $ny2]
  }

  # Set editpath to the path of the current edit cell as returned
  # by db_search labels.
  #set editpath [lindex [lay_path] 1]
  #if { $editpath == "." } { set editpath "" }

  foreach lab_info $labels {
      struct max_label lab $lab_info

      # Dont get labels in other cells if not any_cell:
      # Not needed now that db_search labels has -non_hier option
      #if { ! $f_any_cell } {
      #	if { ${lab.path} != $editpath } { continue }
      #}

      if {!(${lab.layer}=="space" || [lsearch $layer_list ${lab.layer}]>=0)} {
	continue
      }
      if { ${lab.kind} == "hidden" } {
	  # Cant select a hidden label by pointing at it.
	  continue
      }
      # Select box labels only if point was nearby an edge of the box.
      if {[approx ${lab.x1} != ${lab.x2}] || [approx ${lab.y1} != ${lab.y2}]} {
	  # Its a box label.
	  set lab_box "${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2}"
	  if {[box_get_nearest_side $x1 $y1 $lab_box] == "0 0 0 0" } {
	      # Mouse is not near edge of box label; dont select it.
	      continue
	  }
      }
      # sortkey 0 insures that labels are first in sorted list.
      set item.sortkey 0
      set item.type label
      set item.layer ${lab.layer}
      set item.bbox "${lab.x1} ${lab.y1} ${lab.x2} ${lab.y2}"
      set item.text  ${lab.text}
      set item.other $lab_info
      lappend list [destruct select_struc item]
  }

  # Search for paint.
  # At this time, we only see if paint exists.
  # If user actually wants to select it, we will compute paint areas as needed.
  set key 1

  if { [approx $x1 == $x2] && [approx $y1 == $y2] } {

      # Gets all layers at once.
      set tiles ""
      if { $layer_join != "" } {
	set tiles [eval db_search_l paint $any_cell -area $x1 $y1 $x2 $y2 $layer_join]
      }
      foreach tile [dbt_sort_tiles $tiles] {
	struct max_paint p $tile
	if { $tile == "" } { continue }
	set item.layer ${p.layer}
	set item.type paint
	set item.text ""
	set item.other ""
	set item.bbox [lrange $tile 1 4]
	set item.sortkey [incr key]
	lappend list [destruct select_struc item]
      }
  } else {
      # This was only used by the probe for areas, not when the user strokes
      # out an area.  Not currently used at all.
      set layers [lremove [dbt_selectable_layers] subcell]
      foreach layer [dbt_sort_layers $layers] {
	  set tiles [eval db_search_l paint $any_cell -area $x1 $y1 $x2 $y2 $layer]
	  # Should be just one tile, but lets check.
	  foreach tile $tiles {
	      if { $tile == "" } { continue }
	      set item.bbox [lrange $tile 1 4]
	      set item.sortkey [incr key]
	      lappend list [destruct select_struc item]
	  }
      }
  }


  # Look for polygons
  set polygons ""
  if { $layer_join != "" } {
    set polygons [eval db_search_l polygons $any_cell -area $x1 $y1 $x2 $y2 $layer_join]
  }
  foreach poly $polygons {
      assert { $poly != "" }
      struct max_polygon p $poly
      if {[string match {*dependent*} ${p.attrs}]} {
	# This polygon is part of a wirepath.  It will be handled
	# as a wirepath.  Dont add it to the polygon list.
	continue
      }
      # sortkey 1e10 insures that polygons are at bottom of list.
      set item.sortkey 2e10
      set item.type polygon
      set item.layer ${p.layer}
      set item.bbox ${p.bbox}
      set item.text ""
      set item.other $poly
      lappend list [destruct select_struc item]
  }

  # Look for wirepaths
  set wps ""
  if { $layer_join != "" } {
    set wps [eval db_search_l wirepaths $any_cell -area $x1 $y1 $x2 $y2 $layer_join]
  }
  foreach wp $wps {
      assert { $wp != "" }
      struct max_wirepath p $wp
      # 1e10 insures polygons are at bottom of list.
      # sortkey 1e10 insures that polygons are at bottom of list.
      set item.sortkey 1e10
      set item.type wirepath
      set item.layer ${p.layer}
      set item.bbox ${p.bbox}
      set item.text ""
      set item.other $wp
      lappend list [destruct select_struc item]
  }

  # Now cells.

  # TODO:
  # Mha is fixing a bug in db_search,
  # if the bug is not fixed, use: db_search cells -cell [lay_editcell]

  if { [lsearch -exact [dbt_selectable_layers] "subcell"] >= 0 } {

      # Note: the -user_bbox option does not exist in older maxes.
      if {[catch {set cells [eval db_search_cells $any_cell -user_bbox -area $x1 $y1 $x2 $y2]}]} {
	set cells [eval db_search_cells $any_cell -area $x1 $y1 $x2 $y2]
      }

      foreach cellstring $cells {
	  if { $cellstring == "" } { continue }
	  struct max_cell cell $cellstring
	  # Max returns cells whose real bbox overlaps the area x1 y1 x2 y2.
	  # We only want cells whose user bbox overlaps this area.
	  if {$x2 < ${cell.x1}  || $x1 > ${cell.x2} || $y2 < ${cell.y1} || $y1 > ${cell.y2}} {
	    continue
	  }
	  set item.sortkey 3e10
	  set item.type cell
	  set item.layer ""
	  set item.bbox "${cell.x1} ${cell.y1} ${cell.x2} ${cell.y2}"
	  #set item.text  ${cell.id}
	  set item.text  [cellinfo_name $cellstring]
	  set item.other $cellstring
	  lappend list [destruct select_struc item]
      }
  }

  return [lsort -index 0 -real $list]
}


proc _UNUSED_dbt_largest_box_by_lee {layer x y} -desc {
  Like db_largest_box but tries to do the right thing.
} -doc {
  For example, if a horizontal wire runs into a vertical wire,
  return the horizontal metal up to the start of the vertical wire;
  do not return the slice including the vertical wire.
} {
  # Warning: Max bug!! sel_chunk moves the box.

  # first get the little guy
  # breaks on poly to gate
  #  setl {x1 y1 x2 y2} [db_largest_box -edit $layer $x $y]

  setl {tmp x1 y1 x2 y2} [db_search paint -area $x $y $x $y $layer]

  if { $tmp == "" } {
    # 7/99: Hopefully the db_search bug is fixed now. (pat)
	# There is a bug in db_search that it sometimes just fails.
	# But sel_chunk will get it when db_search fails.
	sel_chunk $layer $x $y $x $y
	setl {tmp xx1 yy1 xx2 yy2} [sel_what paint]
	if { $tmp != "" } {
	    return "$xx1 $yy1 $xx2 $yy2"
	} else {
	    # nothing in the current cell, just return
	    return ""
	}
  }

  # now get the chunk (bigger)
  #sel_chunk $layer $x1 $y1 $x2 $y2
  #setl {tmp xx1 yy1 xx2 yy2} [sel_what paint]

  setl {xx1 yy1 xx2 yy2} [db_chunk $layer $x1 $y1 $x2 $y2]
  if { $xx1 == "" } {
    error "db_chunk failed"
  }

  # find a point on chunk not on little
  if {$xx1 < $x1} {
    sel_chunk $layer $xx1 $y1 $xx1 $y2
    setl {tmp xxx1 yyy1 xxx2 yyy2} [sel_what paint]

    if {[approx $xx1 != $xxx1] || [approx $yy1 != $yyy1] || \
	[approx $xx2 != $xxx2] || [approx $yy2 != $yyy2]} {
      # return little guy
      return "$x1 $y1 $x2 $y2"
    }
  }
  if {$xx2 > $x2} {
    sel_chunk $layer $xx2 $y1 $xx2 $y2
    setl {tmp xxx1 yyy1 xxx2 yyy2} [sel_what paint]

    if {[approx $xx1 != $xxx1] || [approx $yy1 != $yyy1] || \
	[approx $xx2 != $xxx2] || [approx $yy2 != $yyy2]} {
      # return little guy
      return "$x1 $y1 $x2 $y2"
    }
  }
  if {$yy1 < $y1} {
    sel_chunk $layer $x1 $yy1 $x2 $yy1
    setl {tmp xxx1 yyy1 xxx2 yyy2} [sel_what paint]

    if {[approx $xx1 != $xxx1] || [approx $yy1 != $yyy1] || \
	[approx $xx2 != $xxx2] || [approx $yy2 != $yyy2]} {
      # return little guy
      return "$x1 $y1 $x2 $y2"
    }
  }
  if {$yy2 > $y2} {
    sel_chunk $layer $x1 $yy2 $x2 $yy2
    setl {tmp xxx1 yyy1 xxx2 yyy2} [sel_what paint]

    if {[approx $xx1 != $xxx1] || [approx $yy1 != $yyy1] || \
	[approx $xx2 != $xxx2] || [approx $yy2 != $yyy2]} {
      # return little guy
      return "$x1 $y1 $x2 $y2"
    }
  }    

  # return the chunk
  return "$xx1 $yy1 $xx2 $yy2"
}

proc _sel_find_paint {x y layer any_cell} {
  if { $any_cell } {
    set paint [db_search paint -any_cell -area $x $y $x $y $layer]
  } else {
    set paint [db_search paint -area $x $y $x $y $layer]
  }
  return [expr { $paint != "" }]
}


proc _select_find_blob {x y layer axis} -desc {
  used by _sel_smallest_box
} {
  set res [res]

  switch $axis {
    ns {
      # Maximize box chunk in north/south directions.
      set y1 [dbt_next_edge $x $y s $layer -inside]
      set y2 [dbt_next_edge $x $y n $layer -inside]
      if { $y1 == "" || $y2 == "" } { return "" }  ;# shouldnt happen
      setl {x1 y1 x2 y2} [dbt_chunk $layer $x $y1 $x $y2]
      if { $x1 == "" } { return "" }
      # Set x1 and x2 to truncate box left and right.
      set y2r [expr $y2+$res]
      set y1r [expr $y1-$res]
      set x1 [dbt_next_edge $x $y w $layer -area [list $x1 $y1r $x2 $y2r] -inside]
      set x2 [dbt_next_edge $x $y e $layer -area [list $x1 $y1r $x2 $y2r] -inside]
      if { $x1 == "" || $x2 == "" } { return "" }  ;# shouldnt happen
    }
    ew {
      # Maximize box in east/west directions.
      set x1 [dbt_next_edge $x $y w $layer -inside]
      set x2 [dbt_next_edge $x $y e $layer -inside]
      if { $x1 == "" || $x2 == "" } { return "" }  ;# shouldnt happen
      setl {x1 y1 x2 y2} [dbt_chunk $layer $x1 $y $x2 $y]
      if { $x1 == "" } { return "" }
      # Set y1 and y2 to truncate box south and north.
      set x2r [expr $x2+$res]
      set x1r [expr $x1-$res]
      set y1 [dbt_next_edge $x $y s $layer -area [list $x1r $y1 $x2r $y2] -inside]
      set y2 [dbt_next_edge $x $y n $layer -area [list $x1r $y1 $x2r $y2] -inside]
      if { $y1 == "" || $y2 == "" } { return "" }  ;# shouldnt happen
    }
  }

  # Test box to see if three of its sides
  # are edges all the way across.

  set y2r [expr $y2+$res]
  set y1r [expr $y1-$res]
  set x2r [expr $x2+$res]
  set x1r [expr $x1-$res]

  set full_edges 0
  # Look at edge to north
  if {[db_search paint -area $x1 $y2r $x2 $y2r $layer]==""} {
    incr full_edges
  }
  # Look at edge to south.
  if {[db_search paint -area $x1 $y1r $x2 $y1r $layer]==""} {
    incr full_edges
  }
  # Look at edge to west
  if {[db_search paint -area $x1r $y1 $x1r $y2 $layer]==""} {
    incr full_edges
  }
  # Look at edge to east
  if {[db_search paint -area $x2r $y1 $x2r $y2 $layer]==""} {
    incr full_edges
  }

  if { $full_edges == 3 } {
    # It was an attached blob.
    return [list $x1 $y1 $x2 $y2]
  }
  return ""  ;# Nope, it wasnt a blob.
}


proc _sel_smallest_box {layer x y} -desc {
  Return a smaller box than db_chunk, that might be a useful selection.
} -doc {
  Uses three algorithms to try to find a piece of paint, smaller
  than db_chunk, that might be interesting to the user.
  Return the rectangle, or "" if none found.

  Algorithm 1. handles wires properly.
    For example, if a horizontal wire runs into a vertical wire,
    return the horizontal metal up to the start of the vertical wire;
    do not return the slice including the vertical wire.
    This is used interactively only, so if it fails its no big deal.
    How it works: : get db_chunk.  Look at the box sides in
    the minimum dimension.  If both sides are edges, then truncate
    both ends of the box in the larger dimension at the first edge change.

  Algorithm 2. handles corners.  You often want to delete these.
    9/1: Take out the corner algorithm.  A better way to implement
    this would be to add gravity to area select, so the box automatically
    snaps to the nearest corner.  Taking this out also makes it a
    little less confusing for the user.

  Algorithm 3. handles rectangular blobs of paint warted onto the side
    of bigger pieces of paint.  This is very similar to alg 1,
    but does not care about the relative widths in X and Y.
    Its actually kind of tricky, because we need to ignore edge
    changes in the bigger piece of paint, but we dont really know
    which is the blob and which the bigger piece when we start.
    So we look for the biggest blob that has 3 sides that are
    actual paint edges in their entirety.

  This routine is vaguely similar to db_largest_box, which sort
  of does algorithm 1, above.  However, db_largest_box does not
  work in the case where there are edge changes off to the left
  or right but outside the area where we are looking.
  These edge changes fracture the paint tiles horizontally,
  and db_largest_box gets confused.  Its probably an oversight
  that should be fixed.

} {
  set res [res]
  set box_chunk [dbt_chunk $layer $x $y $x $y]
  if { $box_chunk == "" } { return "" }
  setl {cx1 cy1 cx2 cy2} $box_chunk

  # These are coords of box one res bigger than chunk
  set cy2r [expr $cy2+$res]
  set cy1r [expr $cy1-$res]
  set cx2r [expr $cx2+$res]
  set cx1r [expr $cx1-$res]

  # See if the sides of the box are on paint edges.
  # We check this on a horiz or vert ray from point x,y
  set edge_n [expr {[db_search paint -area $x $cy2r $x $cy2r $layer] == ""}]
  set edge_s [expr {[db_search paint -area $x $cy1r $x $cy1r $layer] == ""}]
  set edge_w [expr {[db_search paint -area $cx1r $y $cx1r $y $layer] == ""}]
  set edge_e [expr {[db_search paint -area $cx2r $y $cx2r $y $layer] == ""}]

  # Algorithm 1: Check for wires, or other long skinny features.
  set box_wire ""
  if { $cx2 - $cx1 > $cy2 - $cy1 } {
    # Y dimension is smaller.  See if y1 and y2 lie on edges.
    if {$edge_n && $edge_s} {
      # Yes!  Truncate the box in the X direction.
      set x1 [dbt_next_edge $x $y w $layer -area [list $cx1 $cy1r $cx2 $cy2r] -inside]
      if { $x1 == "" } { set x1 $cx1 }
      set x2 [dbt_next_edge $x $y e $layer -area [list $cx1 $cy1r $cx2 $cy2r] -inside]
      if { $x2 == "" } { set x2 $cx2 }
      set box_wire [list $x1 $cy1 $x2 $cy2]
    }
  } else {
    # X dimension is smaller.  See if x1 and x2 lie on edges.
    if {$edge_e && $edge_w} {
      # Yes!  Truncate the box in the Y direction.
      set y1 [dbt_next_edge $x $y s $layer -area [list $cx1r $cy1 $cx2r $cy2] -inside]
      if { $y1 == "" } { set y1 $cy1 }
      set y2 [dbt_next_edge $x $y n $layer -area [list $cx1r $cy1 $cx2r $cy2] -inside]
      if { $y2 == "" } { set y2 $cy2 }
      set box_wire [list $cx1 $y1 $cx2 $y2]
    }
  }

  if { $box_wire == $box_chunk } {
    set box_wire ""
  }



  # Algorithm 2: Check for corners.
  set box_corner ""

  # Disabled; see comment above.
  if {0} {
  # 8/7/00: NOte: this code can be simplified by taking
  # advantage of new db_next_distance syntax: the inside_rect stuff
  # can just go away because dbt_next_edge returns "" when
  # it fails, so I think we can just test ex2/ey2.

    if { $edge_s && $edge_w } {
      setl {ex1 ey1 ex2 ey2} [list $cx1 $cy1 $cx2 $cy2]
      set ey2 [dbt_next_edge $cx1 $cy1 n $layer]
      set ex2 [dbt_next_edge $cx1 $cy1 e $layer]
      if {$ex2 != "" && $ey2 != "" && [inside_rect $x $y $ex1 $ey1 $ex2 $ey2] && \
	$ey2-$ey1 < $cy2-$cy1 && $ex2-$ex1 < $cx2-$cx1} {
	set box_corner [list $cx1 $cy1 $ex2 $ey2]
      }
    }
    if { $edge_s && $edge_e } {
      setl {ex1 ey1 ex2 ey2} [list $cx1 $cy1 $cx2 $cy2]
      set ey2 [dbt_next_edge $cx2 $cy1 n $layer]
      set ex1 [dbt_next_edge $cx2 $cy1 w $layer]
      if {$ex1 != "" && $ey2 != "" && [inside_rect $x $y $ex1 $ey1 $ex2 $ey2] && \
	$ey2-$ey1 < $cy2-$cy1 && $ex2-$ex1 < $cx2-$cx1} {
	set box_corner [list $ex1 $cy1 $cx2 $ey2]
      }
    }
    if { $edge_n && $edge_w } {
      setl {ex1 ey1 ex2 ey2} [list $cx1 $cy1 $cx2 $cy2]
      set ey1 [dbt_next_edge $cx2 $cy1 s $layer]
      set ex2 [dbt_next_edge $cx2 $cy1 e $layer]
      if {$ey1 != "" && $ex2 != "" && [inside_rect $x $y $ex1 $ey1 $ex2 $ey2] && \
	$ey2-$ey1 < $cy2-$cy1 && $ex2-$ex1 < $cx2-$cx1} {
	set box_corner [list $cx1 $ey1 $ex2 $cy2]
      }
    }
    if { $edge_n && $edge_e } {
      setl {ex1 ey1 ex2 ey2} [list $cx1 $cy1 $cx2 $cy2]
      set ey1 [dbt_next_edge $cx2 $cy2 s $layer]
      set ex1 [dbt_next_edge $cx2 $cy2 w $layer]
      if {$ex1 != "" && $ey1 != "" && [inside_rect $x $y $ex1 $ey1 $ex2 $ey2] && \
	$ey2-$ey1 < $cy2-$cy1 && $ex2-$ex1 < $cx2-$cx1} {
	set box_corner [list $ex1 $ey1 $cx2 $cy2]
      }
    }

    if { $box_corner != "" && $box_wire != "" } {
      # Consider a wire that crosses another wire on one end
      # and has an uneven endpoint on the other.  If you click
      # in the middle of the wire somewhere, you could get a a corner
      # box due to the jagged ending. Eg, if you click on any
      # X below, you get the corner, when what you want is the wire segment.
      #
      #             WW
      #             WW
      #       WWWWWWWWWWWWWWWWWWWW
      #         XXXXWWWWWWWWWWWWWW
      #             WW
      #             WW
      #
      # To prevent this, the wire algorithm almost always takes
      # precedence over the corner algorithm.
      # However, some geometries end up having a wire box 
      # and a corner that overlap.  Eg: X in the diagram below.
      # W represents the Wire box.  In this case, you probably
      # want to be able to select the corner.  So allow the corner
      # to be selected if the wire length is less than the wire width.
      # The user can still select the wire sliver by clicking at W, below.
      #
      #     PPPPPWPPPPPPPPPP
      #     PPPPPWPPPPPPPPPP
      #          XPPPPPPPPPP
      #           PPPPPPPPPP
      #
      # Another possible algorithm would be to select a thing
      # that would not result in a DRC violation if deleted.
      # Hope we are not being too clever here.

      # 5/00 Note: the res is necessary because db_next_distance off by one.
      setl {wx1 wy1 wx2 wy2} $box_wire
      setl {px1 py1 px2 py2} $box_corner
      set d [expr 1.1 * $res]
      #if {[approx $wx1 == $px1 $d] + [approx $wy1 == $py1 $d] + \
	  [approx $wx2 == $px2 $d] + [approx $wy2 == $py2 $d] == 3}
      set width [techinfo width $layer opt]
      if {[approx [max [expr $py2-$py1] [expr $px2-$px1]] <= $width] } {
	return $box_corner
      } else {
	return $box_wire
      }
    }
  }

  if { $box_wire != "" } { return $box_wire }
  if { $box_corner != "" } { return $box_corner }

  # Algorithm 3: Check for a blob attached to a bigger object.
  # The blob has edges across its full length on three sides.
  # If found, return the blob so it can be easily deleted.
  # We take two stabs at it because that was a convenient
  # way to ignore edges in the bigger object.

  set blob [_select_find_blob $x $y $layer ns]
  if { $blob != "" } { return $blob }

  set blob [_select_find_blob $x $y $layer ew]
  if { $blob != "" } { return $blob }

  return ""
}

proc _UNUSED_not_quite_so_old_sel_smallest_box {layer x y} -desc {
  Return the smallest paint tile, optimized for wires.
} -doc {
  Similar db_largest_box but tries to do the right thing.
  In particular, handle wires properly.
  For example, if a horizontal wire runs into a vertical wire,
  return the horizontal metal up to the start of the vertical wire;
  do not return the slice including the vertical wire.
  This is used interactively only, so if it fails its no big deal.

  Note: db_largest_box does not do this properly in the case where there
  are edge changes off to the left or right but outside
  the area where we are looking.  These edge changes fracture
  the paint tiles horizontally, and db_largest_box gets confused.
  Probably, its an oversight that should be fixed.

  Algorithm: get db_chunk.  Look at the box sides in the minimum dimension.
  If both sides are edges, then truncate both ends of the box
  in the larger dimension at the first edge change.
} {
  set res [res]
  setl {cx1 cy1 cx2 cy2} [dbt_chunk $layer $x $y $x $y]
  if { $cx1 == "" } { return "" }

  if { $cx2 - $cx1 > $cy2 - $cy1 } {
    # Y dimension is smaller.  See if y1 and y2 lie on edges.
    set y2r [expr $cy2+$res]
    set y1r [expr $cy1-$res]
    if {[db_search paint -area $x $y2r $x $y2r $layer] == "" && \
	[db_search paint -area $x $y1r $x $y1r $layer] == ""} {
      # Yes!  Truncate the box in the X direction.
      set x1 [dbt_next_distance $x $y w $layer $cx1 $y1r $cx2 $y2r]
      set x2 [dbt_next_distance $x $y e $layer $cx1 $y1r $cx2 $y2r]
      return [list $x1 $cy1 $x2 $cy2]
    } else {
      # No smaller chunk worth noticing.
      return ""
    }
  } else {
    # X dimension is smaller.  See if x1 and x2 lie on edges.
    set x2r [expr $cx2+$res]
    set x1r [expr $cx1-$res]
    if {[db_search paint -area $x1r $y $x1r $y $layer] == "" && \
	[db_search paint -area $x2r $y $x2r $y $layer] == ""} {
      # Yes!  Truncate the box in the Y direction.
      set y1 [dbt_next_distance $x $y n $layer $x1r $cy1 $x2r $cy2]
      set y2 [dbt_next_distance $x $y s $layer $x1r $cy1 $x2r $cy2]
      return [list $cx1 $y1 $cx2 $y2]
    } else {
      # No smaller chunk worth noticing.
      return ""
    }
  }
}


proc save_selection {{cell __SAVE_SELECTION__}} -desc {
  save the selection away to be restored with restore_selection
} {

  if {[cell_info $cell] != "__NO_SUCH_BUFFER__"} {
    # remove old cell
    # This kills the undo stack!
    # NOTE: mha is going to provide db_cell_erase that does
    # not kill the undo stack.
    # That will need to be guarded by undo_disable/enable.
    # 5/00: Apparently this is fixed now, at least, undo works through this.
    db_cell_delete $cell
  }

  # make this special internal cell
  # We do NOT want to clear the undo stack, so use the -no_undo
  db_cell_new -no_undo -internal $cell

  # copy selection in here
  db_cell_copy -source __SELECT__ $cell
}


proc restore_selection {{cell __SAVE_SELECTION__}} -desc {
  restore the saved selection
} -doc {
    warning: the groups are not saved with the selection,
    so the restored selection goes into the current group.
} {

  if {[cell_info $cell] == "__NO_SUCH_BUFFER__"} {
    # tough luch charly
    msg "Aborting restore selection, no buffer $cell\n"
    return
  }

  sel_clear_g

  # everyting is this cell becomes selected
  sel_buffer $cell
}

proc _select_update_cache {x y} -desc {
   caches the sel_what info in PROBE() variables.
} {
  global PROBE
  # We will cache the sel_what for efficiency.
  # The select_is_item_selected proc will use the cache.
  set search_opts "-cell __SELECT__ -area $x $y $x $y"
  set PROBE(cache_paint) [eval db_search_l paint $search_opts]
  set PROBE(cache_wirepaths) [eval db_search_l wirepaths $search_opts]
  set PROBE(cache_polygons) [eval db_search_l polygons $search_opts]
  # Use sel_what for labels, to make sure we find box labels too.
  set PROBE(cache_labels) [sel_what_l labels]
  # Use sel_what for cells, because it is the only way to get
  # the correct edit-in-place path.  But, it does not take
  # x,y coords, so we will have to do it ourselves.

  # This is going to be too slow if there is alot selected.
  set PROBE(cache_cells) ""
  foreach cell_info [sel_what_l cells] {
    struct max_cell c $cell_info
    if {[inside_rect $x $y ${c.x1} ${c.y1} ${c.x2} ${c.y2}]} {
      lappend PROBE(cache_cells) $cell_info
    }
  }
}

proc select_count {args} -desc {
  Return total number of things selected.
} -doc {
  Options are as to db_search and sel_what, in particular:
  -limit <limit>
} {
  # Note: db_search labels -cell __SELECT__ includes hidden
  # labels in gcells, which is wrong, but sel_what labels works ok,
  # so use that instead, for labels.
  # Update 3/1/01: The reason db_search labels returns hidden labels
  # is probably because it traverses hiearchy unless -non_hier given,
  # but since this works, no reason to change it.
  return [expr \
    [llength [eval db_search_l paint -cell __SELECT__ $args]] + \
    [llength [eval sel_what_l labels $args]] + \
    [llength [eval db_search_l polygons -cell __SELECT__ $args]] + \
    [llength [eval db_search_l wirepaths -cell __SELECT__ $args]] + \
    [llength [eval db_search_l cells -cell __SELECT__ $args]] ]
}


# Update the probe window.
proc _probe_update {} {
    global PROBE
    set probe .probe
    set plist $probe.items.list

    if { ! [winfo exists $probe]} { return }

    set box [layt_box exact]
    setl {bx1 by1 bx2 by2} $box
    if {[approx $bx1 != $bx2] || [approx $by1 != $by2]} {
	# Box is not a point.  I tried to make this work, but
	# it was too confusing, so just remove the probe.
	destroy $probe
	return
    }

    # clear old list
    if {[$plist size] > 0} {
	$plist delete 0 end
    }

    # If user entered non-numbers into the location entries,
    # ignore them.  Otherwise we get wierd errors below.
    #if { ! [regexp {^[-+]?[0-9.]+$} $PROBE(x)] ||
    #        ! [regexp {^[-+]?[0-9.]+$} $PROBE(y)] } {
    #	return
    #}

    # Get the list of items under the cursor.
    # This destroys the selection, so restore it when done.
    set PROBE(list) [eval _select_list $box $PROBE(any_cell) visible]
    _sel_list_reset $PROBE(list)

    setl {PROBE(x) PROBE(y)} $box

    _select_update_cache $PROBE(x) $PROBE(y)

    set cnt [select_count -limit 100]
    if { $cnt >= 100 } {
      set cnt "> 100"
    }

    $probe.count config -text  "There are $cnt items selected"

    foreach thing $PROBE(list) {
	struct select_struc item $thing
	if { ${item.type} == "cell" } {
	    # Cells have no layer field, and we want the def field in there.
	    struct max_cell cell ${item.other}
	    if {[use_list_path]} {
	      set cellpath [cell_path_clean_gcell [join [cellinfo_name ${item.other}] /]]
	    } else {
	      set cellpath [string trim [cell_path_clean_gcell [cellinfo_name ${item.other}]] /]
	    }
	    if {[is_gcell ${cell.def}]} {
	      $plist insert end "gcell [gcell_typename ${cell.def}] ( $cellpath )"
	    } else {
	      $plist insert end "cell ${cell.def} ( $cellpath )"
	    }
	} else {
	    $plist insert end "${item.layer} ${item.type} ${item.text}"
	}
	# If the thing is selected, highlight it.
	if { [_select_is_item_selected $thing -any_paint] } {
	    $plist selection set end
	}
    }

    raise $probe
    eval layt_box exact $box
}

proc _probe_select {lx ly action} -desc {
    Select item number at y window coord x,y in the probe list.
} {
    global PROBE

    set plist .probe.items.list
    set n [$plist index @$lx,$ly]
    set box [layt_box exact]

    if { [$plist selection includes $n] } {
	set more less
    } else {
	set more more
    }

    # Toggle the selection.
    # In TK, we always get a single button-1 before receiving the
    # double button-1, so only toggle on Button-1.
    if { $action == "select" } {
	if { [$plist selection includes $n] } {
	    $plist selection clear $n
	} else {
	    $plist selection set $n
	}
    }

    switch -- $action {
      "select" {
	# Select/deselect item.
	_select_item [lindex $PROBE(list) $n] 0 $more
      }
      "selnet" {
	# select net
	struct select_struc item [lindex $PROBE(list) $n]
	if { ${item.type} == "paint" || \
		${item.type} == "polygon" || \
		${item.type} == "wirepath" } {
	    layt_point exact $PROBE(x) $PROBE(y)
	    # sel_net doesnt have a -less, so always just use -more.
	    $plist selection set $n
	    sel_net -more ${item.layer}
	    sel_vias
	    # show the net to the user now in case this next part takes a while
	    update
	    # tell user what labels are on this net
	    display_selected_labels
	}
      }
      default { assert { 0 } }
    }
    eval layt_box exact $box
    _probe_update
}

proc _probe_clear {} {
    sel_clear
    _probe_update
}


proc probe_init {{any_cell ""}} {
    global PROBE LISTBOX_FONT max_win

    set PROBE(any_cell) [use_first PROBE(any_cell) '0]
    if {$any_cell != ""} {
      set PROBE(any_cell) $any_cell
    }

    setl {x y} [layt_point exact]

    set probe .probe

    # If the probe window does not exist, build it.
    # Otherwise, we will update the existing probe window.
    if {! [winfo exists $probe] } {

        util_win_create $probe "Selection Probe"

	set font $LISTBOX_FONT; # Just a shorter name for the font

	bind $probe <Any-Control-c> "catch {destroy $probe}; break"
	bind $probe <Escape> "catch {destroy $probe}; break"

	#grab set $probe
	#cursor_wait $probe 1 "Probe"
	#tkwait variable _PROP_RETURN
	#cursor_wait $probe 0

	if {0} {
	# Took this out because it can be a rectangle.
	# It was confusing, too.
	# Put in x/y location
	frame $probe.location
	foreach xy "x y" {
	  label $probe.location.${xy}_text -text "${xy}:"
	  pack $probe.location.${xy}_text -side left -ipady 1
	  entry $probe.location.$xy -width 10 -highlightthickness 1 \
	      -textvariable PROBE($xy) \
	      -relief sunken -bd 1
	  pack $probe.location.$xy -side left -fill x -ipady 1 -expand 1
	  bind $probe.location.$xy <Leave> +_probe_update
	  bind $probe.location.$xy <KeyRelease> +_probe_update
	}
	pack $probe.location -side top
	}

	# This is filled in by probe_update.
	label $probe.count -text ""
	pack $probe.count -side top -fill x


	# Create a frame for the selected items.
	frame $probe.items

	scrollbar $probe.items.vscroll \
		-relief raised \
		-command "$probe.items.list yview"

	listbox $probe.items.list \
		-font $font \
		-exportselection false \
		-selectmode multiple \
		-relief raised \
		-yscrollcommand "$probe.items.vscroll set"

	# The break is necessary to keep the listbox from processing
	# the mouse buttons after we are done with them.
	bind $probe.items.list <Button-1> {_probe_select %x %y select;break}
	bind $probe.items.list <Double-Button-1> { \
		_probe_select %x %y selnet; break }
	bind $probe.items.list <Button-2> { \
		_probe_select %x %y selnet; break }

	# pack the list and scrollbars
	pack $probe.items.vscroll -side right -fill y
	pack $probe.items.list -side left -fill both -expand 1
	pack $probe.items -expand 1 -fill both

	# Now the buttons.
        radiobutton $probe.r1 -variable PROBE(any_cell) -value 0 \
	  -text "Current Cell" -anchor w -command "_probe_update"
        radiobutton $probe.r2 -variable PROBE(any_cell) -value 1 \
	  -text "All Expanded Cells" -anchor w -command "_probe_update"
	pack $probe.r1 $probe.r2 -side top -fill x

	button $probe.clear -text "Clear Selection" -command _probe_clear \
	  -padx 3 -pady 3
	pack $probe.clear -side top

	set helpmsg {The Selection Probe displays a list of all\
	  the visible objects under the cursor in the current edit cell. \
	  Objects that are currently selected are highlighted in the\
	  Selection Probe list.
Mouse BUT-1 over an item in the Selection Probe window\
	  selects or deselects that item in the max window. 
Mouse BUT-2 or Double-BUT-1 over a paint rectangle or polygon listed\
	  in the Probe Window selects the net attached to that layer\
	  in the max window.}

	# Buttons
        frame $probe.buttons

        button $probe.done -text "Close" -padx 1 -pady 2 \
	  -command "catch {destroy $probe}"
        button $probe.help -text "Help" -padx 1 -pady 2 \
	  -command [list prop_dialog -title {Selection Probe Help} $helpmsg]

        pack $probe.done $probe.help -side left \
          -in $probe.buttons -padx 1m -ipadx 1m -pady 1m
	pack $probe.buttons -side bottom

	util_win_finish $probe -place right
    }

    layt_box exact $x $y $x $y

    _probe_update

    #focus $probe
}
