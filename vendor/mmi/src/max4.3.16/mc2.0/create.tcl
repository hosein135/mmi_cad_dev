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

# tries to create the MC MACRO directly from a layout

# TODO: eventually takes exact or relative

proc _mc_create {{mode ""}} -desc {
  tries to create the MC MACRO directly from a layout
} {

  global MC MC_CREATE max_win

  set MC(create,hierarchy) [use_first MC(create,hierarchy) '0]
  # TODO make exact work
  set MC(create,type) [use_first MC(create,type) 'relative]
  set MC(create,prefix) [use_first MC(create,prefix)]
  set MC(create,suffix) [use_first MC(create,suffix)]

  if {$mode == ""} {
    # get the options from the menu
    set win $max_win.layout
    set winy [expr [winfo rooty $win] + 50]
    set winx [expr [winfo rootx $win] + 50]

    set title "megacell generator what"
    set message "Create Options:" 
#       [list type $MC(create,type) radio {relative exact}]

    set prop_list [list \
       [list hierarchy $MC(create,hierarchy) binary] \
       [list remove_prefix $MC(create,prefix)] \
       [list remove_suffix $MC(create,suffix)] \
      ]

    # create the menu
    set new_prop_list [prop_menu $winx $winy $message $title $prop_list]

    if {$new_prop_list == ""} {
      # empty list means the user hit cancel
      return
    }

    set MC(create,hierarchy) [get_assoc hierarchy $new_prop_list] 
#    set MC(create,type) [get_assoc type $new_prop_list] 
    set MC(create,prefix) [get_assoc remove_prefix $new_prop_list] 
    set MC(create,suffix) [get_assoc remove_suffix $new_prop_list] 
  }

  set MC(create,count) 0

  catch {unset MC_CREATE}

  eval lay_box [lay_bbox]
  lay_internals -area

  puts "Creating MC build commands for cell \"[lay_rootcell]\" ...\n"

  _mc_create_int

  puts "\ndone."
}


proc _mc_create_int {} -desc {
  does the work
} {

  global MC MC_CREATE

  # check to see if already got this one
  set cell [_mc_create_strip [lay_rootcell]]
  if {[info exists MC_CREATE($cell)]} {
    # already got this one
    return 1
  }


  if {[catch "lay_layer_styles $MC(boundary)"]} {
    # boundary layer is not a max layer
    set blayer ""
  } else {
    set blayer ",$MC(boundary)"
  }

  # leaf cells here contain no fets or boundary layers
  eval sel_area -any_cell -layers [join [techinfo devices] ,]$blayer [lay_bbox]
  if {[sel_what paint] == ""} {
    # nothing here, ignore
    return 0
  }
  sel_clear

  # is this a leaf cell
  if {[_is_leaf_cell]} {
    # leaf cell
    return 1
  }

  set top_cell [_mc_create_strip [lay_rootcell]]
  set MC_CREATE($top_cell) 1

  eval lay_box [lay_bbox]
  lay_internals -area

  # select all the instances in this cell
  eval sel_area -layers subcell [lay_bbox]

  lay_internals -hide

  set cells ""
  foreach cell [split [sel_what cells] \n] {
    setl {name type x1 y1 x2 y2 path expansion xfrom array} $cell
    if {[is_gcell $type]} {
      # ignore gcells since we can't push into them
      continue
    }

    if {[use_first MC(create,hierarchy)] == 1} {
      # run recursively down to leaf cells
      sel_cell $name
      edit_push
      set return [_mc_create_int]
      edit_pop

      if {$return == 0} {
	# nothing here
	continue
      }

    } else {
      # check if this should even be considered
      sel_cell $name
      edit_push

      eval sel_area -any_cell -layers [join [techinfo devices] ,]$blayer [lay_bbox]
      if {[sel_what paint] == ""} {
	# nothing here, ignore
	edit_pop
	continue
      }
      sel_clear
      edit_pop
    }

    set orient [orientation $xfrom]

    if {$array != ""} {
      # expand array to individual instances
      setl {xlo xhi ylo yhi dx dy} $array

      # don't care if its left to right or right to left
      set dx [expr abs($dx)]
      set dy [expr abs($dy)]

      set iy $y1
      for {set y $ylo} {$y <= $yhi} {incr y} {
	set ix $x1
	for {set x $xlo} {$x <= $xhi} {incr x} {
	  # bounding box is the array skip
	  lappend cells \
	      "$type $ix $iy [expr $ix + $dx] [expr $iy + $dy] $orient"

	  set ix [expr $ix + abs($dx)]
	}
	set iy [expr $iy + abs($dy)]
      }

    } else {
      # not an array
      # get bounding box
      sel_cell $name
      lappend cells "$type [_mc_create_bbox "$x1 $y1 $x2 $y2"] $orient"
    }
  }

  # restore view to show internals
  eval sel_area -layers subcell [lay_bbox]
  lay_internals
  sel_clear

  # now order into rows
  set rows [_mc_create_order $cells]

  if {$rows != "" && $rows != "CELL"} {
    puts "set MACRO($top_cell) \{$rows\}"
  }

  return 1
}


proc _mc_create_bbox {bbox} -desc {
  return bbox of cell in root coords
} {

  global MC

  if {[catch "lay_layer_styles $MC(boundary)"]} {
    # boundary layer is not a max layer
    return $bbox
  }

  edit_push in_place
  eval sel_area -any_cell -layers $MC(boundary) [lay_bbox]

  catch {unset xmin}

  foreach paint [split [sel_what paint] \n] {
    setl {layer xx1 yy1 xx2 yy2} $paint
    if {![info exists xmin]} {
      set xmin $xx1
      set xmax $xx2
      set ymin $yy1
      set ymax $yy2

    } else {
      set xmin [min $xmin $xx1]
      set ymin [min $ymin $yy1]
      set xmax [max $xmax $xx2]
      set ymax [max $ymax $yy2]
    }
  }

  sel_clear

  edit_pop
  lay_internals -hide

  if {[info exists xmin]} {
    # use this boundary from the boundary layer
    return "$xmin $ymin $xmax $ymax"

  } else {
    # use the bbox of the cell
    return $bbox
  }
}


proc _mc_create_order {cells {rows CELL}} -desc {
  walk thru cells and create a list of rows
} {

  global MC

  while {$cells != ""} {

    catch {unset ymin}

    # figure out y coords for this row
    foreach cell $cells {
      setl {type x1 y1 x2 y2} $cell
    
      if {![info exists ymin]} {
	# first one
	set ymin $y1
	set ymax $y2
	# extension for overlap
	set dy [expr ($y2 - $y1) * 0.2]
      } elseif {$y1 < $ymin} {
	# below previous, use this as first row
	set ymin $y1
	set ymax $y2
	# extension for overlap
	set dy [expr ($y2 - $y1) * 0.2]
      } elseif {$y1 < [expr $ymax - $dy]} {
	# extend row upwards
	set ymax [max $ymax $y2]
      }
    }

    # put all with correct y coord in this row
    set row ""
    set other ""
    set last_x ""
    set new ""

    foreach cell [lsort -index 1 -real $cells] {
      setl {type x1 y1 x2 y2 orient} $cell
      if {$y2 <= $ymax} {
	# this goes in

	# special case of a column that is a non hierarchical cell
	if {$last_x != "" && $x1 < $last_x} {
	  # these overlap, make into a cell
	  if {$new == ""} {
	    # get last from row
	    set len [llength $row]
	    lappend new $last
	    set row [lrange $row 0 [expr [llength $row] - 2]]
	  }
	  lappend new $cell
	  continue

	} elseif {$new != ""} {
	  # make this new non-hierarchical cell
	  set new_name "_tmp_[incr MC(create,count)]"
	  puts "set MACRO($new_name) \{[_mc_create_order $new ""]\}"
	  # add to existing
	  lappend row $new_name
	  
	  set new ""
	}
	# this is near right to allow some overlap
	set last_x [expr $x1 + 0.8 * ($x2 - $x1)]
	set last $cell

	lappend row [concat [_mc_create_strip $type] $orient]

      } else {
	lappend other $cell
      }
    }

    # pick up any leftovers
    if {$new != ""} {
      # first check for special case
      if {$new == $cells} {
	# can't decompose, done with this
	set row ""

      } else {
	# make this new non-hierarchical cell
	set new_name "_tmp_[incr MC(create,count)]"
	puts "set MACRO($new_name) \{[_mc_create_order $new ""]\}"
	# add to existing
	lappend row $new_name
      }
    }

    # figure out repeats
    set row [_mc_create_repeat $row in_row]

    lappend rows $row

    # try again with the rest of the rows
    set cells $other
  }

  # figure out repeats
  set rows [_mc_create_repeat $rows]

  return $rows
}


proc _mc_create_strip {name} -desc {
  strip off any prefix and suffix
} {

  global MC

  # TODO quote special chars like $

  # strip prefix
  regsub "^$MC(create,prefix)" $name "" name

  # strip suffix
  regsub "$MC(create,suffix)\$" $name "" name

  return $name
}


proc _mc_create_repeat {list {type ""}} -desc {
  figure out repeats and merge
} {

  global MC

  # simple repeats first
  set last ""
  set return ""
  set count 0

  foreach item $list {
    if {$last != $item} {
      if {$last != ""} {
	# write
	if {$count == 1} {
	  lappend return $last
	} else {
	  # a true repeat
	  lappend return [list REPEAT $count $last]
	}
      }
      set last $item
      set count 1

    } else {
      # this is a repeat from the last one
      incr count
    }
  }

  # account for last item
  if {$last != ""} {
    # write
    if {$count == 1} {
      lappend return $last
    } else {
      # a true repeat
      lappend return [list REPEAT $count $last]
    }
  }

  set list $return
  set return ""

  # complicated repeats
  while {$list != ""} {
    set first [lindex $list 0]
    set rest [lrange $list 1 end]
    if {[set pos [lsearch $rest $first]] != -1} {
      # first is repeated but is it done regularly?
      set group [lrange $list 0 $pos]
      set rest2 [lrange $rest $pos end]
      incr pos

      if {[string first $group $rest2] == 0} {
	# this is a repeat

	# need to make a non-hierarchical cell for this
	set new_name "_tmp_[incr MC(create,count)]"

	if {$type == ""} {
	  puts "set MACRO($new_name) \{$group\}"
	} else {
	  # in a row, add more brackets
	  puts "set MACRO($new_name) \{\{$group\}\}"
	}

	set i 2
	set rest2 [lrange $rest2 $pos end]

	while {[string first $group $rest2] == 0} {
	  incr i
	  set rest2 [lrange $rest2 $pos end]
	}

	lappend return [list REPEAT $i $new_name]
	set list $rest2

      } else {
	# no repeat
	lappend return $first
	set list $rest
      }

    } else {
      # no repeat
      lappend return $first
      set list $rest
    }
  }

  return $return
}



