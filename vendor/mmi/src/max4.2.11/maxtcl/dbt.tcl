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


set RCSVERSION(dbt.tcl) { $Revision: 1.7 $ }

# This is a file full of things that should be written in C.

proc dbt_flyline {args} -desc {
  Flyline operations.
} -doc {
  USAGE:
    dbt_flyline [-options] [args]
  
  OPTIONS:
  -cell <cell_def>
    The flylines in the specified cell should be changed, instead
    of the edit cell.  To prevent having to switch cells, this
    is totally kludged:  Must start with dbt_flyline -init,
    and end with dbt_flyline -restore.  Example:
      dbt_flyline -init foo
      dbt_flyline -cell foo ...
      ...
      dbt_flyline -restore foo
  
  dbt_flyline -init <cell_def>
    Save copy of flylines from <cell_def> for later use
    with dbt_flyline -cell option.
    Currently, cell_def can only be edit cell.

  dbt_flyline -restore <cell_def>
    Restore flylines for <cell_def> that were modified
    with dbt_flyline -cell option.
    Currently, cell_def can only be edit cell.

  dbt_flyline -pop <cell_id>
    Flatten cell out of flylines
  
  dbt_flyline -find label1 [label2]
    If one label, return flylines connected to it.
    If two labels, return flylines connected to both labels.

  dbt_flyline -change_path <path1> <path2>
    Change path1 to path2 in flylines.

  dbt_flyline -push <cell_id> [-push_def <def>]
    Cell is a newly added cell: add its id name onto
    each flyline that is hooked to anything in its contents.
    The -push_def specifies the cell def name, and is an optional optimization;
    if specified, dbt_flyline does not need to search for the cell def name.
  
  dbt_flyline -change <old> <new>
    Change label <old> to label <new> in any flyline.
    Return 1 if <old> was found, else 0.

  dbt_flyline -delete <l1> <l2>
    Delete flyline from <l1> to <l2>
    Return 1 if found, else 0.
  
  dbt_flyline -delete <old>
    Delete any flylines to label <old>
    Return 1 if <old> was found, else 0.
} {
  global _FLYLINES

#puts "dbt_flyline $args"

  set options {{push} {find} {pop} {push_def ""} {change} \
	{change_path} {delete} {cell ""} {init} {restore}}
  setl {arg1 arg2} [call_keyword $args $options]

  if { $cell != "" } {
    set flylines $_FLYLINES($cell)
  } else {
    set flylines [split [string trim [db_flyline] \n] \n]
  }
  set new_flylines ""
  set any_change 0

  if { $init } {

    assert { $arg1 == [lay_editcell] }
    set _FLYLINES($arg1) [split [string trim [db_flyline] \n] \n]
    return

  } elseif { $restore } {

    assert { $arg1 == [lay_editcell] }
    set new_flylines $_FLYLINES($arg1)
    set any_change 1
    # Work is done below.

  } elseif { $change } {

    # Find any flylines to arg1, change to arg2.
    assert { $arg1 != "" && $arg2 != "" }
    foreach fly $flylines {
      setl {junk l1 l2} $fly
      if { $l1 == $arg1 } {
	set l1 $arg2
	set any_change 1
      } elseif { $l2 == $arg1 } {
	set l2 $arg2
	set any_change 1
      }
      lappend new_flylines [list $junk $l1 $l2]
    }

  } elseif { $delete } {

    if { $arg1 == "" && $arg2 == "" } {
      # Delete all flylines by leaving new_flylines empty.
      if {[llength $flylines] != 0} {
	set any_change 1
      }
    } elseif { $arg2 == "" } {
      foreach fly $flylines {
	setl {junk l1 l2} $fly
	if { $l1 == $arg1 || $l2 == $arg1 } {
	  # Delete flyline by not including it in new_flylines.
	  set any_change 1
	} else {
	  lappend new_flylines [list $junk $l1 $l2]
	}
      }
    } else {
      foreach fly $flylines {
	setl {junk l1 l2} $fly
	if { $l1 == $arg1 || $l2 == $arg2 } {
	  # Delete flyline by not including it in new_flylines.
	  set any_change 1
	} else {
	  lappend new_flylines [list $junk $l1 $l2]
	}
      }
    }

  } elseif { $pop || $change_path } {

    if { $change_path } {
      set new_path ${arg2}/
    } else {
      set new_path ""
    }

    foreach fly $flylines {
      setl {junk l1 l2} $fly
      if { [string match "${arg1}/*" $l1] } {
	set len [string length "${arg1}/"]
	set l1 ${new_path}[string range $l1 $len end]
	set any_change 1
      }
      if { [string match "${arg1}/*" $l2] } {
	set len [string length "${arg1}/"]
	set l2 ${new_path}[string range $l2 $len end]
	set any_change 1
      }
      lappend new_flylines [list $junk $l1 $l2]
    }

  } elseif { $push } {

    if { $push_def == "" } {
      set push_def [dbt_find_cell $arg1]
      assert { $push_def != "" }
    }
    set cells [db_search_l cells -cell $push_def]
    set labels [db_search_l labels -non_hier -cell $push_def]

    foreach fly $flylines {
      setl {junk l1 l2} $fly
      # There is a problem if there exists a cell c such that $arg1 == $c.id
      # Prevent it with l1_changed and l2_changed.
      set l1_changed 0
      set l2_changed 0
      foreach cell_info $cells {
	struct max_cell c $cell_info
	if { [string match ${c.id}/* $l1] && ! $l1_changed } {
	  set l1 ${arg1}/$l1
	  set l1_changed 1
	  set any_change 1
	}
	if { [string match ${c.id}/* $l2] && ! $l2_changed } {
	  set l2 ${arg1}/$l2
	  set l2_changed 1
	  set any_change 1
	}
      }
      foreach lab_info $labels {
	struct max_label l $lab_info
	if { ${l.text} == $l1 } {
	  set l1 ${arg1}/$l1
	  set any_change 1
	}
	if { ${l.text} == $l2 } {
	  set l2 ${arg1}/$l2
	  set any_change 1
	}
      }
      lappend new_flylines [list $junk $l1 $l2]
    }

  } elseif { $find } {

    foreach fly $flylines {
      setl {junk l1 l2} $fly
      if { $arg1 == $l1 } {
	if { $arg2 == "" || $arg2 == $l2 } {
	  lappend new_flylines $fly
	}
      } elseif { $arg1 == $l2 } {
	if { $arg2 == "" || $arg2 == $l1 } {
	  lappend new_flylines $fly
	}
      }
    }
    return $new_flylines

  } else {
    # Not currently used.
    assert { 0 }
  }

  if { $any_change } {
    if { $cell != "" } {
      set _FLYLINES($cell) $new_flylines
    } else {
      db_flyline -delete
      foreach fly $new_flylines {
	setl {junk l1 l2} $fly
	db_flyline $l1 $l2
      }
    }
  }

  return $any_change
}

  
if {0} {
  proc _flyline_flatten {cell_id} -desc {
    Flatten cell out of flylines.
  } {
      set new_flylines ""
      foreach fly $_FLATTEN(flylines) {
	setl {junk l1 l2} $fly
	if { [string match ${cell_id}/* $l1] } {
	  set len [string length ${cell.id}/
	  set l1 [string range $l1 $len end]
	}
	if { [string match ${cell_id}/* $l2] } {
	  set len [string length ${cell.id}/
	  set l2 [string range $l2 $len end]
	}
	lappend new_flylines [list $junk $l1 $l2]
      }
      set _FLATTEN(flylines) $new_flylines
  }
}

proc dbt_find_cell {id}  -desc {
  return info on specified cell without changing the selection.
} -doc {
  returned info is in the coord system of the current edit cell,
  which will not be the same as sel_what cells returns if we
  are editing in place.

  Example:
    struct max_cell c [dbt_find_cell $cell_id]
    puts "cell def is ${c.id}"
} {
    set parent_def [lay_editcell]
    foreach cellinfo [db_search_l cells -cell $parent_def] {
	struct max_cell c $cellinfo
	if { ${c.id} == ${id} } {
	    return $cellinfo
	}
    }
    return ""
}


proc dbt_sort_tiles {tiles} -desc {
  Sort a list of paint tiles into proper layer ordering.
} -doc {
  The layer_order in DRC_DATA is used.  If it is invalid
  or missing, the sort will fail silently.

  Assumes the first element in each tile in the list is the layer name.
} {
    # Get the desired layer ordering.
    set order [techinfo layer_order opt]
    if { $order == "" } {
	# I guess we wont be sorting them after all...
	return $tiles
    }

    set n 0
    foreach layer $order {
      set layer_number($layer) [incr n]
    }

    # The lsort -command switch crashes, so instead, create a new
    # list whose first element is an integer we can sort on.

    set new_list ""
    foreach tile $tiles {
      set layer [lindex $tile 0]
      # Add the use_first to be absolutely save; dont think it can happen.
      lappend new_list [list [use_first layer_number($layer) '99] $tile]
    }

    set out_list ""
    foreach thing [lsort -integer -index 0 $new_list] {
      lappend out_list [lindex $thing 1]
    }
    return $out_list
}


proc dbt_sort_layers {layers} -desc {
  Return layers sorted by layer ordering.
} -doc {
  The layer_order in DRC_DATA is used.  If it is invalid
  or missing, the sort will fail silently.
} {
    # Get the desired layer ordering.
    set order [techinfo layer_order opt]
    if { $order == "" } {
	# I guess we wont be sorting them after all...
	return $layers
    }

    # Now sort layers into layer order.
    set result ""
    foreach layer $order {
	if { [lsearch -exact $layers $layer] != -1} {
	    lappend result $layer
	}
    }
    return $result
}


proc dbt_touchingtypes {x y mode} -desc {
  returns list of layers present at indicated (rootcell) coordinates.
} -doc {
  mode may be: all, visible, selectable 
  Layers are returned in order from lowest to highest.
  Searches in all expanded cells.
} {

    set touching [dbt_short_name [db_search touchingtypes $x $y]]

    switch $mode {

      all {
	set allowed_layers $touching
      }

      selectable {
	set allowed_layers [dbt_selectable_layers]
      }

      visible {
	set allowed_layers [dbt_visible_layers]
      }

      default {
	error "Illegal input (mode=$mode) to dbt_touching_types."
	return ""
      }
    }

    set layers ""
    set allowed_layers [dbt_short_name $allowed_layers]
    foreach layer $touching {
      if {[lsearch -exact $allowed_layers [dbt_short_name $layer]] != -1} {
	lappend layers $layer
      }
    }

    return [lreverse [dbt_sort_layers $layers]]
}

proc dbt_layers {} -desc {
  return list of all layers, except subcell and built-in layers like checkpaint.
} {
  set ret ""
  foreach thing [split [string trim [db_types] \n] \n] {
    setl {long short other plain flags} $thing
    if {[lsearch $flags builtin] == -1} {
      lappend ret $short
    }
  }
  return $ret
}


proc dbt_visible_layers {} -desc {
  returns list of visible layers
} {

  global max_win

  set layers [$max_win.layout visible]

  # why are these in here!
  foreach layer "magnet fence rotate" {
    set pos [lsearch $layers $layer]
    if {$pos != -1} {
      set layers [lreplace $layers $pos $pos]
    }
  }

  return $layers
}

proc dbt_is_visible {layer} -desc {
  is layer visible?
} {
    set visible [dbt_visible_layers]
    return [expr [lsearch -exact $visible $layer] >= 0]
}


proc dbt_selectable_layers {} -desc {
  returns list of selectable layers
} {
  global PAL

  if {[info exists PAL(selectable)]} {
    # return logical AND of selectable and visible layers
    foreach layer $PAL(selectable) {
      set array($layer) 1
    }
    if {[info exists array(subcell)]} {
      # special case, always visible
      set layers subcell
    } else {
      set layers ""
    }

    foreach layer [dbt_visible_layers] {
      if {[info exists array($layer)]} {
	lappend layers $layer
      }
    }

    return $layers

  } else {
    return [dbt_visible_layers]
  }
}

proc dbt_cursor_in_frame {} -desc {
  is the cursor in the layout window?
} {
  global max_win
  set w $max_win.layout
  setl {x y} [winfo pointerxy $w]
  set x1 [winfo rootx $w]
  set y1 [winfo rooty $w]
  set x2 [expr $x1 + [winfo width $w]]
  set y2 [expr $y1 + [winfo height $w]]
  return [expr $x >= $x1 && $x <= $x2 && $y >= $y1 && $y <= $y2]
}


proc dbt_frame {{fx1 ""} {fy1 ""} {fx2 ""} {fy2 ""}} -desc {
  Deprecated.  Use lay_frame.
} {
  return [eval lay_frame $fx1 $fy1 $fx2 $fy2]

  #global max_win
  #set old_frame [$max_win.layout frame]

  #if { $fx1 != "" } {
  #  $max_win.layout frame $fx1 $fy1 $fx2 $fy2
  #}

  #return $old_frame
}


proc dbt_frame_pixels {} -desc {
  returns number of pixels in visible field in x and y directions.
} {
  global max_win
  return [list [winfo width $max_win.layout] [winfo height $max_win.layout]]
}

proc dbt_next_edge {x y dir layer args} -desc {
  Find paint rectangle edges.
} -doc {
  USAGE:
    dbt_next_edge x y dir layer [-clip distance] [-area {x1 y1 x2 y2}] [-inside]
  
  Search for edge along ray from x,y in direction dir (n, s, e, w).
  If -clip, search only that far.
  If -area, find any edge in the specified area.
  If -inside, return an inside edge.  Ie, if already on an edge, return it.
  if -any_cell, look in any cell.
  Note: -clip and -area are mutually exclusive.
} {
  set options [list {clip ""} {area ""} {inside} {any_cell}]
  set left_over [call_keyword $args $options]
  assert {$left_over == ""}
  set res [res]
  if { $any_cell } { set ac -any_cell } else { set ac "" }

  switch $dir {
    up    { set dir n }
    down  { set dir s }
    left  { set dir w }
    right { set dir e }
  }

  if {$inside && [_sel_find_paint $x $y $layer $any_cell]} {
    # See if we are already on an edge, searching beyond it.  If so, return it.
    switch $dir {
      "n" {
	if {![_sel_find_paint $x [expr $y+$res] $layer $any_cell]} {
	  return $y
	}
      }
      "s" {
	if {![_sel_find_paint $x [expr $y-$res] $layer $any_cell]} {
	  return $y
	}
      }
      "e" {
	if {![_sel_find_paint [expr $x+$res] $y $layer $any_cell]} {
	  return $x
	}
      }
      "w" {
	if {![_sel_find_paint [expr $x-$res] $y $layer $any_cell]} {
	  return $x
	}
      }
      default { error "invalid dbt_next_edge dir" }
    }
    # See if we are already on an edge, and searching
    # parallel to it.  If so, move over one res inside the paint
    # so we will find an edge that goes from paint to not paint.
    # Otherwise it will also find an edge where the not paint side
    # of the edge goes to paint.
    switch $dir {
      "n" -
      "s" {
	if {![_sel_find_paint [expr $x-$res] $y $layer $any_cell]} {
	  set x [expr $x + $res]
	} elseif {![_sel_find_paint [expr $x+$res] $y $layer $any_cell]} {
	  set x [expr $x - $res]
	}
      }
      "e" -
      "w" {
	if {![_sel_find_paint $x [expr $y-$res] $layer $any_cell]} {
	  set y [expr $y + $res]
	} elseif {![_sel_find_paint $x [expr $y+$res] $layer $any_cell]} {
	  set y [expr $y - $res]
	}
      }
      default { error "invalid dbt_next_edge dir" }
    }
  }

  if { $area == ""} {
    # If you dont give it a clip, and you are on the edge of the
    # screen, it screws up.  So always give it a clip.
    setl {zx1 zy1 zx2 zy2} [lay_bbox]
    if { $clip == "" } {
      switch $dir {
	"n" { set clip [expr $zy2 - $y + 1]}
	"s" { set clip [expr $y - $zy1 + 1]}
	"e" { set clip [expr $zx2 - $x + 1]}
	"w" { set clip [expr $x - $zx1 + 1]}
      }
    }
    setl {xx yy} [eval db_next_edge $ac $x $y $dir $layer $clip]
  } else {
      setl {xx yy} [eval db_next_distance -area $area $ac $x $y $dir $layer]
  }
  switch $dir {
    "n" - "s" { return $yy }
    "e" - "w" { return $xx }
    default { error "invalid dbt_next_edge dir" }
  }
}


proc dbt_chunk {args} -desc {
  Similar to db_chunk, but works with edit-in-place.
} -doc {
USAGE:
  dbt_chunk [-cell <cellname>] -any_cell -group layer x1 y1 x2 y2

  Like db_chunk, but adds -cell option, and works with edit-in-place.

  When using edit-in-place, db_chunk returns edit-cell coords instead
  of root-cell coords.  This is a bug fix.
} {

  if {[lindex $args 0] == "-cell"} {
    set cellname [lindex $args 1]
    edit_push_direct $cellname
    set ret [eval dbt_chunk [lrange $args 2 end]]
    edit_pop_direct
    return $ret
  }

  if {[lay_editcell] == [lay_rootcell]} {
    return [eval db_chunk $args]
  } else {
    # Gack.  Its edit-in-place.
    # THIS IS A TOTAL KLUDGE!!!
    # Remove this when the db_chunk, above, works for edit-in-place.
    save_selection __DBT_CHUNK_TMP__
    eval sel_chunk $args
    set pball [sel_what paint]
    sel_clear
    restore_selection __DBT_CHUNK_TMP__
    if { $pball == "" } { return "" }
    struct max_paint p $pball
    return [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
  }
}


proc dbt_chunk2 {layer x y} -desc {
  Return the other chunk.
} -doc {
  db_chunk maximizes the minimum dimension.
  Lets try returning the chunk that may maximize the other dimension.
} {
  # Start with what db_chunk provides.
  set res [res]
  setl {cx1 cy1 cx2 cy2} [eval dbt_chunk $layer $x $y $x $y]
  if { $cx1 == "" } { return "" }
  setl {x1 y1 x2 y2} [list $cx1 $cy1 $cx2 $cy2]
  if { $cy2 - $cy1 > $cx2 - $cx1 } {
    # X dimension is smaller.  Try making X bigger at the expense of Y.
    set y1 $y
    set y2 $y
    set xmin [dbt_next_edge $x $y w $layer -inside]
    set xmax [dbt_next_edge $x $y e $layer -inside]
    if { [approx $x1 > $xmin] } {
      set x1 [expr $x1 - $res]
    } elseif { [approx $x2 < $xmax] } {
      set x2 [expr $x2 + $res]
    }
  } else {
    # Y dimension is smaller.  Try making Y bigger at the expense of X.
    set x1 $x
    set x2 $x
    set ymin [dbt_next_edge $x $y s $layer -inside]
    set ymax [dbt_next_edge $x $y n $layer -inside]
    if { [approx $y1 > $ymin] } {
      set y1 [expr $y1 - $res]
    } elseif { [approx $y2 < $ymax] } {
      set y2 [expr $y2 + $res]
    }
  }
  # Get a different db_chunk, with smaller dimension increased.
  setl {x1 y1 x2 y2} [dbt_chunk $layer $x1 $y1 $x2 $y2]
  if { $x1 != "" } {
    return [list $x1 $y1 $x2 $y2]
  } else {
    # Dont think this can happen.
    return ""
  }
}


proc dbt_any_selection {} -desc {
  Is anything selected?
} {
  #[sel_what types] != "" || [sel_what labels -edit_only {}] != "" || \
  #	  [sel_what cells -binary -edit_only {}] != "" || \
  # [sel_what polygons] != ""

  if {0 == \
      [llength [db_search_l cells -cell __SELECT__ -limit 1]] + \
      [llength [db_search_l labels -non_hier -cell __SELECT__ -limit 1]] + \
      [llength [db_search_l paint -cell __SELECT__ -limit 1]] + \
      [llength [db_search_l polygons -cell __SELECT__ -limit 1]] + \
      [llength [db_search_l wirepaths -cell __SELECT__ -limit 1]]} {
    return 0
  } else {
    return 1
  }
}


proc dbt_cell_delete {{cell ""}} -desc {
  Replaces db_cell_delete for user defined cells.
} -doc {
  Can still use db_cell_delete for internal cells.
  Use this instead for user defined cells.
  This will call any hooks necessary to clean up tcl
  parts of the data-base.
} {
  if {$cell == ""} {
    set cell [lay_editcell]
  }

  db_cell_delete $cell
}
