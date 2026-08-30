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

set RCSVERSION(edit.tcl) { $Revision: 1.40 $ }

## this file implements edit stack.

global EDIT
init_global EDIT(stack) -default "" -desc {
  holds the edit-in-place history in a stack
} -flags internal -type LIST

# Routines implementing commands in edit menu

proc edit_push {args} -desc {
    push into selected instance
} -doc {
  Args can be:
    "": Max will push into the selected instance.
    "in_place": edit the cell in place.
    "paint_in_place": edit the cell containing paint under the cursor.
} -internal {
  Additional non-user visible options are:
    -point "x y"
      The point argument specifies the x,y coords of the cell,
      and is needed only with the "in_place" argument and
      only if the cell is an array to distinguish which array
      element should be edited-in-place.
    -override
      if gcell, edit the existing paint in the gcell def,
      This edits the sub-cell that was generated, and will affect all
      instances of the cell.  Since you are not changing the generator
      info, the changes are not saved when you exit max.
    -cell cell_def
      load it instead of the selection.
} {
  global EDIT

  set options [list {override} {point ""} {cell ""}]
  set flags [call_keyword "$args" $options]

  # See about old syntax for override.
  # Might be used by Lee somewhere, users didnt know about it.
  if {[lsearch -exact $flags override] >= 0} { set override 1 }

  if { $cell == "" } {
    # Edit selected cell

    if { [lsearch -exact $flags paint_in_place] >= 0 } {
      # need to find cell containing paint

      setl {x y} [layt_point exact]
      # choose last (highest) layer
      set layer [lindex [dbt_touchingtypes $x $y visible] end]
      if {$layer == ""} {
	msg "Aborting, no visible layer under cursor\n"
	return
      }

      if {![_find_paint_in_subcell $x $y $layer [lay_editcell]]} {
	msg "Couldn't find cell with layer $layer in it.\n"
      }
      return
    }

    set cell_list [sel_what_cells]
    if { [llength $cell_list] == 0 } {
      error "Aborting, must select a cell instance."
      return
    }
    if { [llength $cell_list] > 1 } {
      msg "Multiple cells selected; editing first one\n"
    }

    # get path name of first selected instance
    set cellball [lindex $cell_list 0]
    struct max_cell c [lindex $cell_list 0]
    # What a hack: we are depending on this string not changing.
    if { ${c.id} == "Topmost cell in the window" } {
      # We cant sub-edit the topmost cell: we already are!
      # So see if there is another selected instance.
      if { [llength $cell_list] > 1 } {
	set cellball [lindex $cell_list 1]
	struct max_cell c [lindex $cell_list 1]
      } else {
	error "Aborting, must select an instance (2)."
	return
      }
    }

    set cell ${c.def}

    if {! $override && [is_gcell ${c.def}]} {
      
      if { [is_gcell ${c.def} group] } {
	# The user is asking to edit the group geometry.

	# This currently only works if group is in the edit cell.
	if {![edit_this_cell_only]} {
	  return
	}

	# DRC will not work inside a group or gcell, because it
	# is marked drc_with_parent.  So we have to edit in place.
	# User will be justifiably confused, so print a message.
	if {[lsearch -exact $flags in_place] == -1} {
	  msg "Note: Can not push into Group cells; Group cells can only\
	     be edited-in-place.\n"
	  lappend flags in_place
	}

	# There may be additional copies of the cell that were
	# duplicated, so we will uniquify this one and change
	# the _edit prop in the cell def.
	gcell_edit_new
      } else {

	if {[is_gcell ${c.def} editable]} {
	  # This is no longer used.
	  assert {0}
	}

	# This is a regular gcell.  Make sure it is in the current cell.
	if {![edit_this_cell_only]} {
	  return
	}
	if { [lsearch -exact $flags "in_place"] >= 0} {
	  gcell_stretch_mode_enter
	  return
	} else {
	  edit_gcell_props ${c.id}
	  return ""
	}
      }
    }

    # inst_path is the path from the root cell to the cell
    # the user wants to edit.
    if {[use_list_path]} {
      set inst_path [concat ${c.path} ${c.id}]
    } else {
      set inst_path ${c.path}${c.id}
    }
    assert {$inst_path != ""}
    set cell_bbox "${c.x1} ${c.y1} ${c.x2} ${c.y2}"
  } else {
    # User specified the cell to edit.
    # There is no currently selected cell in the max frame
    # to restore on pop, so dont save any.
    set inst_path ""
    set cell_bbox ""
  }


  # push current edit path onto stack (also save frame and box for 
  # restore on pop)  The cell x1,y1,x2,y2 is saved so the view
  # command in edit_in_place mode can frame the view appropriately.
  push EDIT(stack) \
      [list $inst_path [lay_path] [dbt_frame] \
	[layt_box exact] $cell_bbox]


  if { [lsearch -exact $flags in_place] >= 0} {
    lay_internals
    if { $point != "" } {
      # pats note: This is not necessary?  :edit uses selected cell!
      eval layt_point exact $point
    }
    set code [msg_catch :edit r i w]
    if {$code || $i != {} || $w != {}} {
      edit_pop
      error "$r/n$w/$i/n"
    }
    cell_load_finish -edit

  } else {
    # cell_load_cell might print informative messages,
    # which we do not want to catch.
    if {[catch [list cell_load_cell ${cell}] r]} {
      catch {edit_pop}
      error "Couldn't load ${cell} $r"
    }

    #OLD, replaced 7/25/01:
    if {0} {
      set code [msg_catch [list :load ${cell}] r i w]
      if {$code || $i != {} || $w != {}} {
	# TODO delete new buffer created by :load
	# some bug causes "notFound" to be set?
	# NOTE: :load returns the error message in r!
	puts "Couldn't load ${cell} $r $w $i"
	edit_pop
	error "Couldn't load ${cell} $r $w $i"
      }
    }
    cell_load_finish
  }
  # There is only one selection buffer for all cells,
  # so if we are changing cells make sure it is cleared.
  sel_clear
}


# Is this a good idea, or should the calling command just be aborted
# if there are cells not in the edit-cell?
proc edit_this_cell_only {} -desc {
  See if there are selected cells that are not immediate descendents of editcell.
} -doc {
  Return 0 to abort caller, 1 if ok.
} {

  # MAX BUG: Max gets confused if two selected cells in different
  # cells have the same name, and returns only one, chosen at random.
  # This results in bizarre behavior if you actually have selected
  # something not in the edit cell, like having the selected cell
  # automatically deselected and the other cell selected for you,
  # without your consent.


  # First, make a quick check to see if this code is needed.
  # The edit_only flag returns only those cells in the current cell.
  set cell_info [sel_what_l cells -edit_only found_bad]
  if { ! $found_bad } { return 1 }

  if {[llength $cell_info] == 0} {
    # None of the selected cells are in the edit-cell.
    max_error "error: The selected cell(s) are not in the edit-cell"
    return 0
  }

  # OK, some cells are in the edit cell, and some in other cells.
  set message "Some selected cell(s) are not in the edit-cell.\
      Do you want to proceed only on the cell(s) that are in the edit-cell?"
  set choice [tk_dialog .dialog "Warning" $message {} 0 Yes Cancel]
  if { $choice != 0 } { return 0 }

  # Find and deselect cells that are not in the edit-cell.

  # 2/1/02: This is an easy way to deselect what is not in the edit cell.
  # It complains, so catch it.
  msg_catch {sel_move 0 0} junk junk junk

  #set editpath [lindex [lay_path] 1]
  #if { $editpath == "." } { set editpath "" }
  #set cell_info [sel_what_cells]
  #foreach cell $cell_info {
  #  struct max_cell c $cell
  #  if { ${c.path} != $editpath } {
  #    # Cell is not a sub-cell of the edit cell.
  #    sel_cell2 -less ${c.path}${c.id}
  #  }
  #}

  return 1
}


proc edit_pop {{n 1}} -desc {
  pop back to previous edit and root cells
} -doc {
  n is number of levels to pop
} {
  global EDIT FPLAN

  # pop the stack
  while {$n > 0} {
    setl {inst_path cells frame box} [pop EDIT(stack)]	
    setl {root path} $cells
    if {$root == ""} {
      set design_root [use_first FPLAN(design_root)]
      if {$design_root != "" && $design_root != [lay_editcell]} {
  	set msg "At top of edit stack.  Do you want to go to design_root: $design_root?"
	if {[prop_dialog -buttons "Yes No" $msg] == "No"} {
	  return
	}
	set root $design_root
      } else {
	msg "Aborting, can't pop.  Already at top of Edit stack.\n"
	return
      }
    }
    incr n -1
  }

  # restore previous rootcell and editcell
  if {$root != [lay_rootcell]} {
    clear_annotations
    # Could use :load here, since we supposedly "know" that the
    # cell is already in memory.  But it could have been db_deleted, I suppose.
    cell_load_cell $root 
  }
  # Do not need to clear annotations if we are popping from edit-in-place.

  if {$path != ""} {
    sel_cell $path
    :edit
    cell_load_finish -edit
  }
  sel_clear

  # select cell we were just editing (so user can easily push back)
  if { $inst_path != "" } {
    sel_cell $inst_path
  }

  #restore box	
  if { $box != "" } {
    eval layt_box exact $box
  }

  #make sure box is in edit cell
  if { [lindex [layt_box exact] 3] == "" } {
    eval layt_box exact [lay_bbox]
  }

  #restore framing	
  if { $frame != "" } {
    eval dbt_frame $frame 
  }
}



proc edit_push_direct {{filename ""}} -desc {
  internal edit_push without changing anything.
} -doc {
  Push current cell/view on internal stack and edit new cell.
  Former cell/view can be restored with edit_pop_direct.
  This proc uses an internal stack not related to the
  user's main edit stack.

  If filename is a path, load specified filename
  without changing MN_PATH_CELL.
} {
  global MN_PATH_CELL
  global _EDIT_DIRECT_STACK
  set root [lay_rootcell]
  set editpath [lindex [lay_path] 1]
  set frame [dbt_frame]
  set mnpath $MN_PATH_CELL
  if {![info exists _EDIT_DIRECT_STACK]} {
    set _EDIT_DIRECT_STACK ""
  }
  push _EDIT_DIRECT_STACK [list $root $editpath $frame]

  if {$filename != ""} {
    set dir [file dirname $filename]
    set cell [file tail $filename]
    if { $cell != $filename } {
      set MN_PATH_CELL $dir
    }
    :load $cell
    set MN_PATH_CELL $mnpath
  }
}

proc edit_pop_direct {} {
  global _EDIT_DIRECT_STACK
  setl {root editpath frame} [pop _EDIT_DIRECT_STACK]
  :load $root
  if { $editpath != "." } {
    # Gack.
    save_selection __FOOBAR__
    sel_cell [string trim $editpath "/"]
    :edit
    restore_selection __FOOBAR__
  }
  eval dbt_frame $frame
}


proc edit_stack_clear {} -desc {
  clear the edit stack (without changing editcell)
} -doc {
If the edit stack is cleared, no more pops are allowed.
} {
    global EDIT

    set EDIT(stack) ""
}


proc lay_path {{-all}} -desc {
  returns the edit cell path
} -doc {
  This command queries the path of cells that have been edited
  using max Push/Pop and/or Edit-in-Place commands.
  Returns a two element list, whose first element is the originally edited
  cell, and whose second element is the instance path to the currently edited cell.
  If -all, returns the complete path including push and edit-in-place commands.
  Otherwise returns only the edit-in-place info.
} {
  global EDIT

  if {$all} {
    set root [lay_rootcell]
    set inst_path ""
    foreach thing $EDIT(stack) {
      setl {this_path pair junk} $thing
      if {[use_list_path]} {
	set inst_path [concat $this_path $inst_path]
      } else {
	set inst_path [string trim $this_path/$inst_path /]
      }
      setl {root junk} $pair
    }
  } else {
    if {[lay_editcell] == [lay_rootcell]} {
      # not edit in place
      return [list [lay_rootcell] .]
    }

    setl {inst_path pair} [lindex $EDIT(stack) 0]
    setl {root} $pair

    if {$root == ""} {
      set root [lay_rootcell]
    }
  }

  if {[use_list_path]} {
    if {$inst_path == ""} {
      set inst_path .
    }
  } else {
    if {$inst_path == ""} {
      set inst_path .
    } else {
      set inst_path $inst_path/
    }
  }

  # return the new path
  return [list $root $inst_path]
}


proc _find_paint_in_subcell {x y layer root} -desc {
  looks for the highest subcell that has paint at coords
} {

  global EDIT max_win

#  puts "---- $x $y $layer $root [lay_editcell]"

  # is it in this cell
# should use db_search paint, but bug in edit in place
#  if {[db_search paint -area $x $y $x $y $layer] != ""}

  layt_box exact $x $y [expr $x + [res]] [expr $y + [res]]
  sel_area -layers $layer $x $y $x $y
  if {[sel_what paint] != ""} {
    # we're done

    # don't let the use go into gcells
    while {[is_gcell [lay_editcell]]} {
      edit_pop
    }

    if {[lay_editcell] == $root} {
      msg "Already editing cell with layer \"$layer\" in it\n"
    } else {
      msg "Editing cell \"[lay_editcell]\" in place with layer \"$layer\" in it\n"
    }

    return 1
  }

  # not in this cell, look for expanded subcells here
  #select_q -editOnly area subcell
  sel_area -layers subcell $x $y $x $y
  # this does a depth first search.  should probably do a breadth first search
  foreach list [sel_what_cells] {

    if { [lsearch -exact [cellinfo_flags $list] expanded] == -1 } {
      # not expanded
      continue
    }

    # edit in place and look for paint
    setl {inst_name cell_name xbot ybot xtop ytop path} [sel_what cells]
    set inst_path "$path$inst_name"

    # push current edit path onto stack (also save frame and box for 
    # restore on pop)
    push EDIT(stack) [list $inst_path [lay_path] \
			  [$max_win.layout frame] \
			  [layt_box exact] \
		          "$xbot $ybot $xtop $ytop"] 
    :edit

    if {[_find_paint_in_subcell $x $y $layer $root]} {
      return 1
    }

    # return to where we were
    edit_pop
  }

  return 0
}


proc edit_cell_props {} -desc {
  Edit properties of the selected cell.
} {
  # TODO: allow user to set array props and instance id.
  global FPLAN
  if {[use_first FPLAN(exists)] == 1} {fplan_block_props;return}
  set cells [sel_what_l cells]
  if { [llength $cells] == 0 } {
    warning "no cell selected"
    return
  }
  if { [llength $cells] > 1 } {
    msg "Multiple cells selected; editing first one\n"
  }
  struct max_cell c [lindex $cells 0]
  # Select the one cell we are going to display properties for,
  # in case multiple cells were selected.
  sel_cell2 ${c.id}

  set prop_list ""
  set id ${c.id}
  lappend prop_list [list "Cell Name:" {c.def} -label]
  set filename [cell_file ${c.def}]
  lappend prop_list [list "Filename:" filename -label]
  lappend prop_list [list "Cell Id:" id -entry]
  # Use move to change X/Y
  #lappend prop_list [list "X:" {c.x1} -label]
  #lappend prop_list [list "Y:" {c.y1} -label]
  set flags [cell_flags ${c.def}]
  lappend prop_list [list "Flags:" flags -label]

  if { ! [prop_menu2 -title "Cell Properties" $prop_list] } {
    # If user hit cancel
    return
  }
  :identify $id
}


proc edit_any {{flags ""}} -desc {
  Edit selected object in place.
} -doc {
  Function edits cells, gcells, polygons, circles, wire-paths, paint.
  If more than one thing selected, punt.
  If flags is "props", edit properties of object.
  Otherwise, edit object paint/geometry/whatever.
} {
    set cache_paint [sel_what_l paint]
    set cache_polygons [sel_what_l polygons]
    set cache_labels [sel_what_l labels]
    set cache_cells [sel_what_l cells]

    # The string trim is probably not necessary.
    set cnt_paint [llength $cache_paint]
    set cnt_polygons [llength $cache_polygons]
    set cnt_labels [llength $cache_labels]
    set cnt_cells [llength $cache_cells]
    set cnt [expr $cnt_paint + $cnt_polygons + $cnt_labels + $cnt_cells]
    
    if { $cnt == 0 } {
	warning "Nothing selected to edit"
	return
    }

    # The rules are:
    # Can only have one type of thing selected;
    # Can have ONE paint, or ONE polygon, or multiple cells,
    # or multiple labels.

    # 10/26 change: If selection contains both labels and something else,
    # ignore the labels.  This was required because if you select
    # paint with a label, for example, in order to edit the paint
    # using p, you have to individually deselect all the labels.
    # TODO: Popup a box to ask what to edit!

    if { $cnt_paint + $cnt_polygons > 1 ||
	$cnt_paint + $cnt_polygons + !!$cnt_cells > 1 } {
	warning "Too many objects selected; select just one object to edit"
	return
    }

    if { $cnt_paint } {
	if { $flags == "props" } {
	  paint_edit_props
	} else {
	  paint_edit_mode_enter
	}
	return
    }

    if { $cnt_polygons } {
	if { $flags == "props" } {
	  polygon_edit_props
	} else {
	  polygon_edit
	}
	return
    }

    if { $cnt_cells } {
      if { $flags == "props" } {
	if {![edit_this_cell_only]} { return }
	if { [is_gcell_selected] } {
	    edit_gcell_props
	} else {
	    edit_cell_props
	}
      } else {
	  # See if any cell is selected.
	  struct max_cell cell [sel_what cells]
	  if { ${cell.id} == ""} {
	    # This can not happen.
	    error "Aborting, must select an instance."
	    return
	  }
	  edit_push in_place
      }
      return
    }

    # Labels are all thats left.
    # We will do this even if there are multiple labels selected.
    edit_label
}
