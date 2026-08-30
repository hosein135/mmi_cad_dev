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

set RCSVERSION(fplan_port.tcl) { $Revision: 1.5 $ }

# This and the code it references should be removed.
set OLD_OPTIMIZER 0

set FPLAN(use_db_prop) 1  ;# Turn this off to use a tcl hash table instead of db_prop.

# Map region to label -pos name
global _FPLAN_PORT
set _FPLAN_PORT(lab_pos,left) w
set _FPLAN_PORT(lab_pos,right) e
set _FPLAN_PORT(lab_pos,top) n
set _FPLAN_PORT(lab_pos,bottom) s

proc _port_snap {x y lay} {
  setl {snapx snapy offsetx offsety} [wire_get_grid m$lay]

  set x [expr $snapx*round(($x-$offsetx)/(0.0+$snapx))+$offsetx]
  set y [expr $snapy*round(($y-$offsety)/(0.0+$snapy))+$offsety]

  return [list $x $y]
}

proc words {str} -desc {
  Split string into space separated words and return list.
} {
  regsub -all { +} [string trim $str] " " str
  return [split $str " "]
}

proc word {str n} -desc {
  Return nth space separated word from str.
} {
  return [lindex [words $str] $n]
}


proc _fplan_parse_port_spec {cell port bitnum prop} -desc {
  Split port prop into optional keywords and expressions.
} -doc {
  The property looks like this:
  
	[keyword ...] [expr ...]

  The keyword begins with a letter, and expressions dont.
  Return a list that looks like:

	keywords [number ...]
  
  Where keywords is "" if unspecified, and the expressions have been evaluated
  with variable b set to bitnum.

  The <port> is a string like foo or x[1], and bitnum
  is the bit number, like "1".  It is passed as an argument
  just to avoid the effort of breaking it out of the <port> string.
} {
  global b h w;# This is a hack. b is used for the bitnum.

  #global FPLAN_PORT_INFO
  #set str [use_first FPLAN_PORT_INFO($cell,$port,$prop)]

  set str [fplan_db_pin -cell $cell getprop $port $prop]
  if {$str == ""} { return {"" ""} }
  set words [words $str]

  setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
  set w [expr $bx2 - $bx1]
  set h [expr $by2 - $by1]


  # Look for a keyword.
  set keywords ""
  while {[string match {[a-z]*} [lindex $words 0]]} {
    lappend keywords [lindex $words 0]
    set words [lrange $words 1 end]
  }

  lappend result $keywords

  # Evaluate expressions and append them to result.
  set b $bitnum
  foreach expr $words {
    if {[catch {uplevel #0 [list expr $expr]} value]} {
      error "cell $cell port $port: invalid expression in $prop property: $str"
      set value 0
    }
    lappend result $value
  }
  return $result

  ##############
  ### vvv OLD CODE vvv
  if {$x > 0} {
    set word [string range $str 0 [expr $x - 1]]
    set expr [string range $str [expr $x + 1] end]
    return [list $word $value]
  } elseif {$prop == "layerspec"} {
    # The layer may have come direct from the max port.
    if {$str == "space"} {
      # This is allowed as a special case.
      return "space space"
    } else {
      set metal_layers [techinfo layers metal]
      set i [lindex $metal_layers $layer]
      if {$i == -1} {
	error "on port $port: invalid layer: $str"
      } else {
	set layer [expr $i + 1]
      }
    }
  } else {
    error "on port $port: invalid $prop property: $str  (expecting: <type> <expression>)"
  }
}

proc _fplan_find_label {cell px py layer} -desc {
  Return label within a grid location of x,y coords, or "" if none.
} {
  set res [res -mask]
  setl {grid_h grid_v} [wire_get_grid $layer]
  # Grow an area to look for port conflicts.
  set ax1 [expr $px - $grid_h + $res]
  set ax2 [expr $px + $grid_h - $res]
  set ay1 [expr $py - $grid_v + $res]
  set ay2 [expr $py + $grid_v - $res]

  # 5/8/01: This db_search is currently an expensive operation.
  # However, it will be made more efficient in the near future
  # (next month?) so I used it. (pat)
  foreach label_info [db_search_l labels -cell $cell -non_hier \
	-area $ax1 $ay1 $ax2 $ay2 -layers $layer] {
    return $label_info
  }
  return ""
}

proc _fplan_snap_to_region {reg px py} -desc {
  Snap point to region of currently cached cell.
} {
    global _fplan_port_reg_dat
    setl {rx1 ry1 rx2 ry2} $_fplan_port_reg_dat($reg,new,area)
    switch $reg {
      top {
	set py $ry2
	set px [bound $px $rx1 $rx2]
      }
      bottom {
	set py $ry1
	set px [bound $px $rx1 $rx2]
      }
      left {
	set px $rx1
	set py [bound $py $ry1 $ry2]
      }
      right {
	set px $rx2
	set py [bound $py $ry1 $ry2]
      }
    }
  return [list $px $py]
}


proc _fplan_port_eval_layer {cell port reg} {
  global _fplan_port_reg_dat FPLAN

  # Is it a bus?  If not, bitnum will be "".
  set bitnum [nlt_bus_get_spec $port]

  # Evaluate the layer, loc and bitloc.
  # This layer is the preferred layer specified by the user, if any,
  # as opposed to the currently assigned layer from the label itself.

  setl {keyword reqlayer} [_fplan_parse_port_spec $cell $port $bitnum layerspec]


  # Assign a layer.  Use previously assigned layer, if any, if no
  # preferred layer was specified.
  if {$keyword == "" && $reqlayer == ""} {
    # No specified layer.  Preserve current layer port is on.
    setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell $port]
    set newlayer $curlayer
  } elseif {$keyword != ""} {
    # Keyworded layer (space, m1, etc)
    if {$keyword == "space"} {
      set ori $_fplan_port_reg_dat($reg,ori)
      set oriword [expr {$ori == "h" ? "horizontal" : "vertical"}]
      #set layernum $FPLAN(layer_default,$oriword)
      set newlayer m$FPLAN(layer_default,$oriword)
    } else {
      set newlayer $keyword
    }
  } elseif {$reqlayer != ""} {
    # Numeric layer
    set newlayer m$reqlayer
  } else {
    max_error -buffer "warning: cell $cell port $port: unrecognized layer: $reqlayer"
    set newlayer m1
  }

  return $newlayer
}


proc _fplan_place_1port {cell port reg placetype {best ""}} -doc {
  This is not called for "fixed" ports.
  reg is the region, effectively the side: top,bottom,left,right.
  placetype is either "expr" for ports that were placed by a user
  specified expression, or "placed" for ports that were placed
  by the optimizer or maybe moved manually by the user.
} {
  global _fplan_port_reg_dat
  upvar region_overflow region_overflow
  global FPLAN _FPLAN_PORT

  global OLD_OPTIMIZER
  if {$OLD_OPTIMIZER} {
    upvar _fplan_port_cur_loc _fplan_port_cur_loc
  }

  # This is the orientation of the wire, not the side.
  # For top/bottom, it will be "v", and for left/right will be "h".
  set ori $_fplan_port_reg_dat($reg,ori)

  setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell $port]

  # Is it a bus?  If not, bitnum will be "".
  set bitnum [nlt_bus_get_spec $port]

  set newlayer [_fplan_port_eval_layer $cell $port $reg]

  # h and v are non-intuitively backwards, because h/v refer to
  # the wire orientation, not the side.  Ie, You use the vertical
  # wire grid when moving in the x direction.
  setl {grid(v) grid(h) offset(v) offset(h)} [wire_get_grid $newlayer]

  set px ""
  set py ""


  # Start by placing the port in its region as close as possible to its current location.
  # Use -floor and -ceil to move the port inside the cell bbox.
  if {$reg == "top" || $reg == "right"} {
    setl {px py} [uusnap -floor -grid $newlayer $lx $ly]
  } else {
    setl {px py} [uusnap -ceil -grid $newlayer $lx $ly]
  }

  # If the block was resized, the x or y will be wrong.  Fix them.
#puts "snap $port $px $py -> [_fplan_snap_to_region $reg $px $py]"
  setl {px py} [_fplan_snap_to_region $reg $px $py]
  
  if {$placetype == "expr"} {

    setl {loc_keywords loc1} [_fplan_parse_port_spec $cell $port $bitnum loc]
    setl {bitloc_keywords bitloc} [_fplan_parse_port_spec $cell $port $bitnum bitloc]

    if {$loc1 != ""} {
      # Move the port to the user specified location.

      # The loc property is a request to place it somewhere.
      # If "track" was specified, compute in terms of wiring tracks.
      # Otherwise, compute location from specified track.
      if {[lsearch -exact $loc_keywords "track"] >= 0} {
	set tmp [expr $_fplan_port_reg_dat($reg,$newlayer,base,$ori) + $loc1 * $grid($ori)]
	if {$ori == "h"} {
	  set py $tmp  ;# It is a horizontal wire
	} else {
	  set px $tmp  ;# It is a vertical wire
	}
      } else {
	# loc1 is the optional exact positioning.
	if {$loc1 != ""} {
	  if {$ori == "h"} {
	    set py $loc1
	  } else {
	    set px $loc1
	  }
	}
      }
    }

    # Add in the bit pitch.
    if {$bitloc != ""} {
      if {[lsearch -exact $bitloc_keywords "track"] >= 0} {
	set tmp [expr $bitloc * $grid($ori)]
      } else {
	set tmp [expr $bitloc]
      }
      if {$ori == "h"} {
	set py [expr $py + $tmp]
      } else {
	set px [expr $px + $tmp]
      }
    }

  } else {

    # The best location was already calculated.
    if {$ori == "h"} {
      set py $best
    } else {
      set px $best
    }

    if {$OLD_OPTIMIZER} {
      # This is a "placed" port.  We can optimize the search for a
      # valid location a little by using the last known search location on this side.
      if {$ori == "h"} {
	if {$py < $_fplan_port_cur_loc($newlayer)} {
	  set py $_fplan_port_cur_loc($newlayer)
	}
      } else {
	if {$px < $_fplan_port_cur_loc($newlayer)} {
	  set px $_fplan_port_cur_loc($newlayer)
	}
      }
    }

  }


  # Place it.  If one already there, move until we find a free spot.
  # Currently, we dont try for other layers.  Simply place on the specified layer.
  set l_collision ""
  while {1} {
    # Look for another label in the same place.
    set fnd_lab [_fplan_find_label $cell $px $py $newlayer]

    if {$fnd_lab == ""} { break }

    # Increment to next location
    if {$l_collision == ""} {set l_collision $fnd_lab}
    if {$ori == "h"} {
      # It is a horizontal wire.  Advance y.
      set py [expr $py + $grid(v)]
    } else {
      # It is a vertical wire.  Advance x.
      set px [expr $px + $grid(h)]
    }
  }

  if {$l_collision != "" && $placetype == "expr" && $loc1 != ""} {
      struct max_label l $l_collision
      max_error -buffer "warning: cell $cell port $port has same location as port ${l.text}"
  }

  # Save next location for next time.
  if {$OLD_OPTIMIZER} {
    if {$ori == "h"} {
      set _fplan_port_cur_loc($newlayer) [expr $py + $grid($ori)]
    } else {
      set _fplan_port_cur_loc($newlayer) [expr $px + $grid($ori)]
    }
  }

  if {! [eval inside_rect $px $py $_fplan_port_reg_dat($reg,new,fuzzarea)]} {
#puts "overflow port $port $px $py $_fplan_port_reg_dat($reg,new,fuzzarea)"
    # Not enough room on the side for all the ports.
    # Place the port in the center, and set the overflow flag.
    set region_overflow($reg) 1
    setl {px py} [eval center_coords [fplan_bbox -cell $cell]]
  }

  db_label -kind $lkind -pos $_FPLAN_PORT(lab_pos,$reg) $newlayer $port $px $py
}


# Globally exported version.
proc fplan_place_ports {{-center_unplaced 1} {-resize ""} cell {port_list ""}} -desc {
  Update port placement in max based on port properties.
} {
  # If this fails, it will have screwed up or deleted the ports, so undo the damage.
  msg "fplan_place_ports $cell\n"
  undo_delim
  if {[catch {_fplan_place_ports_int -center_unplaced $center_unplaced -resize $resize $cell $port_list} result]} {
#DEBUG
#    undo_to_delim
    # If you use error, the trace traces only to this proc.
    # If you use bgerror, you get the correct errorInfo, but the caller
    # is not aborted.  The correct way is to use return, like this:
    global errorInfo
    return -code error -errorinfo $errorInfo $result
  }
}


proc _fplan_place_ports_int {{-center_unplaced 1} {-resize ""} cell port_list} -doc {
  Move max labels to location specified by port properties.
} -doc {
  If port_list is "", place all ports in cell.
  If -resize, the cell has just been resized from the size specified by -resize,
  so calculate current region of ports using that rectangle.
} {
  global _fplan_port_reg_dat _FPLAN_PORT

  util_prof begin

  catch { unset _fplan_port_reg_dat }

  edit_push_direct $cell

  # Delete the stupid hidden labels so we dont have any conflicts
  # between them and real ports.
  sel_labels -kind hidden
  :delete

  # Some initial values.
  # Fixed 7/3:
  #set cell_rect [fplan_bbox -grid user -cell $cell]
  set cell_rect [fplan_bbox -cell $cell]
  setl {bx1 by1 bx2 by2} $cell_rect

  set region_list "center top bottom left right"

  # Orientation of ports in each region: h (horizontal) or v (vertical).
  # It is used to determine the correct metal layer.
  set _fplan_port_reg_dat(top,ori) v
  set _fplan_port_reg_dat(bottom,ori) v
  set _fplan_port_reg_dat(right,ori) h
  set _fplan_port_reg_dat(left,ori) h
  set _fplan_port_reg_dat(center,ori) v  ;# dummy value

  # Figure out the region locations
  set cx [expr ($bx1 + $bx2) / 2]
  set cy [expr ($by1 + $by2) / 2]
  set _fplan_port_reg_dat(center,new,area) [uusnap -mask $cx $cy $cx $cy]

  set fuzz 2  ;# port must be within this number microns of region.
  foreach reg "top bottom left right" {
    set _fplan_port_reg_dat($reg,new,area) [_fplan_region -box $cell_rect area $reg]
    if {$resize == ""} {
      # New and old boxes are the same size.
      set _fplan_port_reg_dat($reg,old,area) $_fplan_port_reg_dat($reg,new,area)
    } else {
      set _fplan_port_reg_dat($reg,old,area) [_fplan_region -box $resize area $reg]
    }
    set _fplan_port_reg_dat($reg,new,fuzzarea) [grow_rect $fuzz $_fplan_port_reg_dat($reg,new,area)]
    set _fplan_port_reg_dat($reg,old,fuzzarea) [grow_rect $fuzz $_fplan_port_reg_dat($reg,old,area)]
  }
  
  # Calculate the first (lower or leftmost) port position
  # in each region.
  set metal_layers [techinfo layers metal]
  for {set lay 1} {$lay <= [llength $metal_layers]} {incr lay} {
    set metal [lindex $metal_layers [expr $lay - 1]]

    # Snap starting point to appropriate grid.
    foreach reg $region_list {
      setl {x y} $_fplan_port_reg_dat($reg,new,area)
      setl {x y} [_port_snap $x $y $lay]
      # This is non-intuitively backwards: the h/v refer to the
      # wire orientation; eg: base (starting location on the side)
      # for vertical wires is in the x direction.
      set _fplan_port_reg_dat($reg,$metal,base,v) $x
      set _fplan_port_reg_dat($reg,$metal,base,h) $y
    }
  }

  foreach reg $region_list {
    # region_overflow is an upvar arg to _fplan_place_1port
    set region_overflow($reg) 0
  }

  # Save current port locations.
  fplan_db_cache -cell $cell
  set port_list [fplan_db_pin_list -usecache -cell $cell]

  sel_clear


  # Sort out the fixed, user-specified, and non-fixed (ie placed/unplaced) ports
  # into regions based on current location.
  # Select the labels we are going to mess with.
  foreach reg $region_list {
    set user_expr_ports($reg) ""
    foreach m $metal_layers {
      set place_ports($reg,$m) ""
    }
  }
  set fixed_ports ""
  set unplaced_ports ""

  foreach port $port_list {
    set place [fplan_db_pin -cell $cell getprop $port place]
  
    switch -- $place {
      "cover" -
      "fixed" {
	# These port locations are fixed.
	# We will not place them, but we will check for conflicts.
	lappend fixed_ports $port
      }
      "" -
      "unplaced" {
	lappend unplaced_ports $port
	# Unplaced ports will be moved to cell center.
	_fplan_sel_label -more $port
      }
      "user" -
      "placed" {
	# User specified placement.
	# TODO: We should prioritize these, and place the ones
	# with an x or y location specified before ones that just
	# have a side specified.
	setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell $port]
	set loc [fplan_db_pin -cell $cell getprop $port loc]
	switch -- [lindex $loc 0] {
	  left -
	  right -
	  top -
	  bottom {
	    if {[llength $loc] == 1} {
	      # Only a side was specified.  Effectively, this is just a placed port.
	      set side $loc
	      set m [_fplan_port_eval_layer $cell $port $loc]
	      lappend place_ports([lindex $loc 0],$m) [list $port $lx $ly]
	    } else {
	      # User specified an expression. We will put it there and not move it.
	      lappend user_expr_ports([lindex $loc 0]) [list $port $lx $ly]
	    }
	    _fplan_sel_label -more $port
	  }
	  "" {
	    # No expression in the "loc" property.
	    # If the port is in a region, keep it in that region.
	    # The port may not be in a region due to any number of causes.
	    # So just snap it to the nearest region.
	    setl {region junk1 junk2} [_fplan_nearest_side $cell_rect [list [list $lx $ly]]]
	    setl {lx ly} [_fplan_snap_to_region $region $lx $ly]
	    set m [_fplan_port_eval_layer $cell $port $region]
	    lappend place_ports($region,$m) [list $port $lx $ly]
	    _fplan_sel_label -more $port
	  }
	  default {
	    max_error -buffer "error: cell $cell port $port unrecognized \"loc\" property: $loc"
	    # And leave it alone.
	  }
	}
      }
      default {
	max_error -buffer "error: cell $cell port $port: unrecognized place prop: $place"
      }
    }
  }

  # Delete the labels we are going to re-place.
  :delete

  #set user_expr_ports(top)   [lsort -real -index 1 $user_expr_ports(top)]
  #set user_expr_ports(bottom)   [lsort -real -index 1 $user_expr_ports(bottom)]
  #set user_expr_ports(right) [lsort -real -index 2 $user_expr_ports(right)]
  #set user_expr_ports(left)  [lsort -real -index 2 $user_expr_ports(left)]

  foreach reg "top bottom right left" {
    set ori _fplan_port_reg_dat($reg,ori)
    if {$ori == "h"} {
      set sort_index 2
    } else {
      set sort_index 1
    }
    set user_expr_ports($reg)  [lsort -real -index $sort_index $user_expr_ports($reg)]

    foreach m $metal_layers {
      # Sort em left-to-right and bottom-to-top.
      set place_ports($reg,$m)   [lsort -real -index $sort_index $place_ports($reg,$m)]
    }
  }


  # Check the fixed ports for conflicts.
  # TODO: This could be done more efficiently.
  foreach port $fixed_ports {
    struct max_label l [lindex [db_search_l labels -non_hier -exact $port] 0]
    set fnd_lab [_fplan_find_label $cell ${l.x1} ${l.y1} ${l.layer}]

    # Oops.  Port conflict detected.
    if {$fnd_lab != ""} {
      struct max_label l $fnd_lab
      max_error -buffer "warning: cell $cell fixed port $port has same location as port ${l.text}"
    }
  }



  # Put unplaced ports in center.
  setl {cx cy} [eval center_coords [fplan_bbox -cell $cell]]
  setl {junk step} [wire_get_grid m2]  ;# Just pick anything.

  if {!$center_unplaced} {
    # This spread out the unplaced ports making them easier to read,
    # but it also sometimes spread them out too far so they would
    # overlap the top and bottom sides of the cell,
    # so changed the default to center_unplaced==1 in proc defn, above.
    set cy [expr $cy + int([llength $unplaced_ports]/2) * $step]
  }

#puts "unplaced=$unplaced_ports"
  foreach port $unplaced_ports {
    setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell $port]
    db_label -kind $lkind -pos n $curlayer $port $cx $cy
    # Spread them out to make them easier to see.
    if {!$center_unplaced} {
      set cy [expr $cy - $step]
    }
  }

  # Place the user located ports
  foreach reg $region_list {
    set ori $_fplan_port_reg_dat($reg,ori)

    global OLD_OPTIMIZER
    if {$OLD_OPTIMIZER} {
      # Init _fplan_port_cur_loc
      # _fplan_port_cur_loc is an upvar arg to _fplan_place_1port
      foreach metal $metal_layers {
	# Half of the metal layers will not be used for any given side,
	# but doesnt matter.
	set _fplan_port_cur_loc($metal) $_fplan_port_reg_dat($reg,$metal,base,$ori)
      }
    }

    # Place the ports with user specified expressions.
    foreach port_thing $user_expr_ports($reg) {
      _fplan_place_1port $cell [lindex $port_thing 0] $reg "expr"
    }
  }


  # Place the non-fixed pre-placed ports.
  foreach reg $region_list {
    set ori $_fplan_port_reg_dat($reg,ori)
    set px $_fplan_port_reg_dat($reg,$metal,base,v)
    set py $_fplan_port_reg_dat($reg,$metal,base,h)

    foreach mlayer $metal_layers {
      # Determine optimal port locations
      set portslots [_fplan_port_make_buckets $cell $reg $mlayer $place_ports($reg,$mlayer)]

#puts "$place_ports($reg,$mlayer) -> $portslots"

      # Note that: [llength $portslots] == [llength $place_ports($reg,$mlayer)]
      # if all ports were placed, but will be <= if not all ports
      # fit in the region.

      for {set i 0} {$i < [llength $portslots]} {incr i} {
	set port [lindex [lindex $place_ports($reg,$mlayer) $i] 0]
	if {$ori == "h"} {
	  set py [lindex $portslots $i]
	} else {
	  set px [lindex $portslots $i]
	}
	setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell $port]
	db_label -kind $lkind -pos $_FPLAN_PORT(lab_pos,$reg) $mlayer $port $px $py
      }

      # The remaining ports have to go in the center.
      setl {cx cy} [eval center_coords [fplan_bbox -cell $cell]]
      for {} {$i < [llength $place_ports($reg,$mlayer)]} {incr i} {
	set port [lindex [lindex $place_ports($reg,$mlayer) $i] 0]
	setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell $port]
	db_label -kind $lkind -pos $_FPLAN_PORT(lab_pos,$reg) $mlayer $port $cx $cy
      }
    }
  }

  # Replace the hidden ports used for flylines.
  # There must be one port in the middle of each region defined,
  # with name set to _hidden_$region
  _fplan_add_hidden_labels $cell

  edit_pop_direct

  # See if we ran out of room in any region.
  foreach reg $region_list {
    if {$region_overflow($reg)} {
      max_error -buffer "warning: too many ports in region: $reg, extra ports moved to center"
    }
  }
  util_prof end
}


proc _fplan_port_make_buckets {cell reg mlayer new_ports} -desc {
  Put all ports on a side in buckets, and spread them out evenly.
} -doc {
  new_ports is a list of {port x y} that are also placed in the buckets.

  Return a list of locations where ports should be placed.

  This routine is clever way to rapidly spread out the ports optimally without
  having to do a zillion searches.
} {
  # The problem of spreading out the ports is kind of tricky.
  # I originally did it by doing a db_search in the each area where
  # a port was to be placed, and incrementing the location until
  # a hole was found.  It was slow.
  # 
  # New method: Make an array of buckets representing port locations.
  # A bucket contains only a count of the number of ports in that location.
  # The array is deliberately sparse, because the blocks we are manipulating
  # could be huge compared to the number of ports on a side.
  # Find all existing ports and put them in their buckets.
  # Then take the new_ports and place them in their preferred buckets.
  # Then go through the buckets and spread the ports out until
  # there is one port per bucket.  Return the buckets.
  # During port placement, one port must be placed in each bucket location.
  # The spreading algorithm can be easily sped up if necessary.

  util_prof begin

  global _fplan_port_reg_dat

  if {[llength $new_ports] == 0} {
    # Hey, that was easy!
    return
  }

  set ori $_fplan_port_reg_dat($reg,ori)
  setl {snapa(v) snapa(h) offseta(v) offseta(h)} [wire_get_grid $mlayer]
  set snap $snapa($ori)
  set offset $offseta($ori)
  # Use the new region, not the old:
  #OLD:setl {rx1 ry1 rx2 ry2} $_fplan_port_reg_dat($reg,old,fuzzarea)
  setl {rx1 ry1 rx2 ry2} [_fplan_region -cell $cell portarea $reg]

  if {$ori == "v"} {
    set sindex [struct_index max_label "x1"]
    set i_top [expr int((round($rx2-$offset)/$snap))]
  } else {
    set sindex [struct_index max_label "y1"]
    set i_top [expr int((round($ry2-$offset)/$snap))]
  }

  # Get existing labels in the region and put into the buckets.
  # Also make a list reserved_buckets of all reserved locations.
  set labels [db_search_l labels -non_hier -area $rx1 $ry1 $rx2 $ry2 -layers $mlayer]
#puts "db_search_l labels -non_hier -area $rx1 $ry1 $rx2 $ry2 -layers $mlayer"
#puts "cell [lay_editcell] reg $reg $rx1 $ry1 $rx2 $ry2 -layers $mlayer labels=$labels"
  set reserved_buckets ""
  foreach lab_info [lsort -real -index $sindex $labels] {
    set val [lindex $lab_info $sindex]
    set i [expr int(round(($val-$offset)/$snap))]
    if {![info exists buckets($i)]} {
      set buckets($i) 1
      lappend reserved_buckets $i
    }
  }

  # Add in obstruction layer, if any.
  # The db_search will fail if the obstruction layer does not exist.
  if {[catch {db_search_l paint -cell $cell -area $rx1 $ry1 $rx2 $ry2 ${mlayer}_obs} obs_paintballs]} {
    set obs_paintballs ""
  }
  foreach paint_info $obs_paintballs {
    struct max_paint p $paint_info
    if {$ori == "v"} {
      set istart [expr int(round((${p.x1}-$offset)/$snap))]
      set istop [expr int(round((${p.x2}-$offset)/$snap))]
    } else {
      set istart [expr int(round((${p.y1}-$offset)/$snap))]
      set istop [expr int(round((${p.y2}-$offset)/$snap))]
    }
    set istart [max 0 $istart]
    set istop [min $istop $i_top]
    for {set i $istart} {$i <= $istop} {incr i} {
      if {![info exists buckets($i)]} {
	set buckets($i) 1
	lappend reserved_buckets $i
      }
    }
  }

  # Add the placed ports into the buckets
  foreach port_thing $new_ports {
    setl {port px py} $port_thing
    setl {px py} [_fplan_snap_to_region $reg $px $py]
    if {$ori == "v"} {
      set i [expr int(round(($px-$offset)/$snap))]
    } else {
      set i [expr int(round(($py-$offset)/$snap))]
    }
    if {[catch {incr buckets($i)}]} {
      set buckets($i) 1
    }
  }

  # Some of the buckets contain more than one port, as indicated by a value > 1.
  # Spread out the ports one per bucket.
  # We will do it iteratively, but this could be sped up by keeping track
  # of high and low locations found.
  #set next_up -1
  #set next_down 99999999
  foreach index [lsort -integer [array names buckets]] {
    if {$buckets($index) == 0} {error "logic error"}
    if {$buckets($index) == 1} {continue}
    # Find the closest port up or down.
    set iu $index
    set id $index

    while {$buckets($index) > 1} {
      # Check for all buckets full.
      if {$id <= 0 && $iu >= $i_top} {
	max_error -buffer "warning: place_ports: side $reg is full on layer $mlayer"
	# The return result will be wrong.
	break
      }

      # Try looking up, first.
      if {$iu < $i_top} {
	incr iu
	if {![info exists buckets($iu)]} {
	  set buckets($iu) 1
	  incr buckets($index) -1
	}
      }

      # Try looking down.
      if {$buckets($index) > 1 && $id > 0} {
	incr id -1
	if {![info exists buckets($id)]} {
	  set buckets($id) 1
	  incr buckets($index) -1
	}
      }
    }

  }

  # Unset the reserved locations.
  foreach i $reserved_buckets {
    # unset could fail if multiple fixed ports were in the same location.
    catch {unset buckets($i)}
  }

  # Return the list of port locations.
  set result ""
  foreach num [lsort -integer [array names buckets]] {
    lappend result [expr $num * $snap + $offset]
  }

  util_prof end
  return $result
}


proc _fplan_nearest_point {ox oy point_list} -desc {
  Return entry from point_list nearest to ox,oy.
} -doc {
  point_list is a list of {x y optional_junk}
} {
  set nearest_dist 9e99
  set nearest_point [lindex $point_list 0]  ;# Just in case
  foreach pair $point_list {
    setl {nx ny} $pair
    set distsquared [expr ($nx - $ox) * ($nx - $ox) + ($ny - $oy) * ($ny - $oy)]
    if {$distsquared < $nearest_dist} {
      set nearest_point $pair
      set nearest_dist $distsquared
    }
  }
  return $nearest_point
}


proc _fplan_nearest_side {rect point_list} -desc {
  Find side of rect with the nearest point in point_list.  Return {side point distance}.
} -doc {
  Entries in point_list are {x y anything_else}.
  If -within, point must be within specified distance of the side to count,
  and return unknown if point is not within that distance of any side.
} {
  setl {x1 y1 x2 y2} $rect
  set cx [expr ($x1 + $x2)/2.0]
  set cy [expr ($y1 + $y2)/2.0]
  set nearest_dist 9e99
  #if {$within != ""} {
  #  set nearest_dist $within
  #  set nearest_side "unknown"
  #  set nearest_point ""
  #}
  foreach point $point_list {
    setl {x y} $point
    set dx [min [expr abs($x - $x1)] [expr abs($x - $x2)]]
    set dy [min [expr abs($y - $y1)] [expr abs($y - $y2)]]
    if {$dx < $dy} {
      if {$dx < $nearest_dist} {
	set nearest_side [expr {$x < $cx ? "left" : "right"}]
	set nearest_point $point
	set nearest_dist $dx
      }
    } else {
      if {$dy < $nearest_dist} {
	set nearest_side [expr {$y < $cy ? "bottom" : "top"}]
	set nearest_point $point
	set nearest_dist $dy
      }
    }
  }

  return [list $nearest_side $nearest_point $nearest_dist]
}


proc _fplan_port_opt_outside {{-verbose 0} {-withplace unplaced} {-adjacent 0} {-best_side 0} cellid} -desc {
  Find preferred location for pin based on stuff outside cellid.
} -doc {
  Assumes we are editing the parent cell of cellid.

  For each pin on cellid, find nearest other pin/port to which it is attached.
  If adjacent, move pin to horizontal/vertical extension from that pin.
  If !adjacent, move pin to edge of cell on a line between center of the two cells.
} {
  global FPLAN _FPLAN_PORT nl_hierarchy_separator
  set nl_hierarchy_separator .

  util_prof begin  _fplan_port_opt_outside

  struct max_cell c [lindex [db_instances_l -id $cellid] 0]
  if {${c.def} == ""} {
    error "Can not find cellid $cellid"
  }

  set topmod [fplan_db_cell module [lay_editcell]]

  set subcell ${c.def}
  set submod [fplan_db_cell module $subcell]
  set submodi [fplan_db_cell celli2modi $cellid]
  if {![nl2_loaded $submod]} {
    max_error -buffer "No verilog module loaded for $subcell"
    return ""  ;# verilog not loaded
  }

  set cellrect [fplan_bbox -parent -cellid $cellid]
  setl {bx1 by1 bx2 by2} $cellrect
  #set cellrect [list ${c.x1} ${c.y1} ${c.x2} ${c.y2}]

  # This returns port objects.
  foreach subpin [nl_find_pins $submodi.* $topmod] {
#puts "nl_find_pins $submodi.* $topmod subpin=$subpin"
    set stuff [split $subpin .]
    set portname [fplan_fix_name -label [lindex $stuff end]]

    setl {placeprop reg} \
	[_fplan_port_placetype -best_side $best_side -withplace $withplace $subcell $portname]
    if {$reg == "donttouch"} {continue}

    # Get connectivity on this net of cells outside this one.
    set net [nl2_get_pin_net $topmod $subpin]
    set otherpins [nl2_get_net_pins $topmod $net]
#puts "subpin=$subpin net=$net otherpins=$otherpins"

    # Gather up locations of other pins to which this is connected.
    set locations ""
    foreach pinname $otherpins {
      # The port itself will appear in the connected pins.  Skip it.
      if {$pinname == $subpin} {continue}
#puts "pinname=$pinname"

      # Determine x,y coords of the pinname.
      if {[string first "." $pinname] == -1} {
	# It is a port.  Find corresponding max label.
	struct max_label l [lindex [db_search_l labels -non_hier -exact [fplan_fix_name -label $pinname]] 0]
	if {${l.text} == ""} {
	  max_error -buffer "warning: port $pinname not found"
	  continue
	}

	set x ${l.x1}
	set y ${l.y1}

      } else {

	# nl has a bug where it returns the whole path, so be careful to strip
	# off any extraneous extra path on the front of pinname.
	set stuff [split $pinname .]
	set modi2 [lindex $stuff [expr [llength $stuff] - 2]]
	set pin2 [lindex $stuff end]

	set cellid2 [fplan_fix_name $modi2]
	struct max_cell c2 [lindex [db_instances_l -id $cellid2] 0]
	if {${c2.def} == ""} {
	  # Probably the cell has just not been placed, maybe its a stdcell.
	  max_error -buffer "warning: can not find cellid $cellid2 (connected pin $subpin net $net)"
	  continue
	}

	# Default: use center of cellid2
	set x [expr (${c2.x1}+${c2.x2})/2.0]
	set y [expr (${c2.y1}+${c2.y2})/2.0]

	if {$adjacent} {
	  # Align to adjacent pins on neighboring cell.

	  # Get location of the other pin, which is pin2 in cell2.
	  set pintext ${modi2}.${pin2}
	  setl {x y iodir curlayer text} [fplan_db_pin2 -fixname -xform $pintext]
	  if {$x == ""} {
	    max_error -buffer "warning: Pin $pintext not found (connected to pin $subpin net $net)"
	    # Just use center of subcell instead, which is already in x,y.
	  }
	}
      }
      # Add pin name to locations for reporting purposes only.
      lappend locations [list $x $y $pinname]
    } ;# foreach pinname

#puts "locations=$locations"
    if {[llength $locations] == 0} {
      # Could not find anything to which this pin was connected...
      max_error -buffer "warning: cell $cellid port $portname not connected to anything; not placed"
      continue
    }

    # Center of subcell in parent coords.
    set cx [expr ($bx1+$bx2)/2.0]
    set cy [expr ($by1+$by2)/2.0]

    # If it was not in any region, then put it on any side.
    if {$reg == "unknown"} {
      # Move the port to the best side.

      # Place pin on cellid based on the closest connected pin on any other cell.
      # Find closest pin from any cellid2 to center of cellid.
      setl {x y fndpin} [_fplan_nearest_point $cx $cy $locations]

      # Figure out the port location by drawing a line from the connection
      # point in cellid cx,cy to the connection point in cellid2 x,y.
      # Otherwise, just use the x,y location we found previously.
      setl {ix iy} [rect_intersect_line $cellrect $cx $cy $x $y]

      if {$x == ""} {
	max_error -buffer "warning: processing ${subcell}.$portname: nearest pin $fndpin\
	has location inside cell!"
	continue
      }
      #puts "rect_intersect_line $cellrect $cx $cy $x $y =$ix,$iy"

      # Figure out the region.
      if {[approx $ix == $bx1]} {
	set reg left
      } elseif {[approx $ix == $bx2]} {
	set reg right
      } elseif {[approx $iy == $by1]} {
	set reg bottom
      } elseif {[approx $iy == $by2]} {
	set reg bottom
      } else {
	max_error -buffer "internal error: cellid $cellid port $portname could not determine region after placement!"
	set reg ""
      }

      if {$adjacent} {
	# Move the pin to line up with the nearest pin, bounded to the region.
	# This tends to bunch up the ports in the corners for diagonal wires.
	switch $reg {
	  "left" - "right" {
	    set iy [bound $y $by1 $by2]
	  }
	  "top" - "bottom" {
	    set ix [bound $x $bx1 $bx2]
	  }
	}
      }
    } else {

      # Move port to best location on the current side.

      # Move the pin to the middle of the region, then
      # look for the closest other pin to that location.
      # This is probably what is desired even if there is a nearer pin on the
      # other side of the cell, and the pins on this side are far away,
      # because we will probably route horizontally/veritically to the nearer pin first.
      # Update: dont move to center.  Try to find nearest pin to current location.
      switch -- $reg {
	"left" {
	  set ix $bx1
	  set iy $cy
	}
	"right" {
	  set ix $bx2
	  set iy $cy
	}
	"top" {
	  set ix $cx
	  set iy $by2
	}
	"bottom" {
	  set ix $cx
	  set iy $by1
	}
	default {
	  error "cell $subcell port $portname unrecognized region: $reg"
	}
      }

      # Find closest other pin to ix,iy
      setl {x y fndpin} [_fplan_nearest_point $ix $iy $locations]

      switch $reg {
	"left" - "right" {
	  set iy [bound $y $by1 $by2]
	}
	"top" - "bottom" {
	  set ix [bound $x $bx1 $bx2]
	}
      }
    }



    # Convert ix,iy back to subcell coords.
    setl {ix iy} [transform_coords -reverse ${c.transform} $ix $iy]

    if {$verbose} {
      msg "Moving $portname to nearest pin $fndpin at $ix $iy reg $reg\n"
    }

    # And snap to a wire grid.  The ori for region "" is just anything.
    set ori [get_assoc $reg {{"" vertical} {left vertical} {right vertical} {top horizontal} {bottom horizontal}}]
    setl {ix iy} [uusnap -grid m$FPLAN(layer_default,$ori) $ix $iy]

    _fplan_move_label -cell $subcell $portname $ix $iy $reg
    if {0} {
      edit_push_direct $subcell
      sel_labels -text $portname
      struct max_label l [sel_what labels]
      if {${l.text} == ""} {
	error "cell $subcell: could not select label $portname"
      }
      :delete
      edit_pop_direct

      db_label -cell $subcell -pos $_FPLAN_PORT(lab_pos,$reg) -kind ${l.kind} ${l.layer} ${l.text} $ix $iy
    }

    if {[fplan_db_pin -cell $subcell getprop $portname place] == "unplaced"} {
      fplan_db_pin -cell $subcell setprop $portname place placed
    }
  }
  util_prof end  _fplan_port_opt_outside
}


proc _fplan_port_placetype {{-best_side 0} {-withplace ""} cell port} -desc {
  Return list: placeprop reg to be used for this port.
} -doc {
  The -best_side and -withplace options are as for opt_inside and opt_outside
  The <placeprop> is the original "place" property from the port.
  The <reg> is the region the port should be placed in,
  or "donttouch" if the port should not be placed,
  or "unknown" if a new region should be computed.
} {
  set placeprop [fplan_db_pin -cell $cell getprop $port place]
  if {$placeprop=="placed" || $placeprop=="user"} {
    set loc [fplan_db_pin -cell $cell getprop $port loc]
    if {$loc == ""} {
      set placekey "placed"
    } elseif {[llength $loc] == 1 && ($loc == "left" || $loc == "right" || \
      $loc == "top" || $loc == "bottom")} {
      set placekey "user_reg"
    } else {
      set placekey "user_expr"
    }
  } else {
    set placekey $placeprop
  }

  # Set reg to the region where the port should be placed, or "unknown"
  # to put in nearest region.
  switch -- $placekey {
    "user_expr" - "fixed" - "cover" {
      set reg "donttouch"
    }
    "placed" {
      if {$best_side} {
	set reg "unknown"
      } else {
	# This might be "unnknown", too, if it is not currently in a region.
	set reg [fplan_db_pin -cell $cell getregion $port]
      }
    }
    "user_reg" {
      set reg [fplan_db_pin -cell $cell getprop $port "loc"]
    }
    "" - "unplaced" {
      set reg "unknown"
    }
    default {
      error "cell $cell port $port: unrecognized place property: $placeprop"
    }
  }

  # For backward compatibility:
  # We will place "user" ports if withplace includes "placed".
  # This is not intuitive, and one of the reasons I did away with place="user".
  set ktype [expr {$placekey=="user_reg"?"placed":$placeprop}]
  if {[lsearch -exact $withplace $ktype] == -1} {
    return [list $placeprop "donttouch"]
  }

  return [list $placeprop $reg]
}


proc _fplan_port_opt_inside {{-verbose 0} {-withplace unplaced} {-best_side 1} cell ports} -desc {
  Find preferred location for pin in specified region based on cell contents.
} -doc {
  Preferred location is on horizontal/vertical extension
  from closest subcell pin inside cell.
  If no preferred location, return "".
  Otherwise return x,y
} {
  global _FPLAN_PORT

  util_prof begin

  # Find preferred location for non-fixed ports.
  # Can only do this if we have connectivity, so check if nl loaded.
  set lay_mod [fplan_db_cell module $cell]
  if {![nl2_loaded $lay_mod]} {
    max_error -buffer "No verilog module loaded for $cell"
    return ""  ;# verilog not loaded
  }

  edit_push_direct $cell

  set cell_bbox [fplan_bbox -cell $cell]
  setl {bx1 by1 bx2 by2} $cell_bbox
  set cx [expr ($bx1+$bx2)/2.0]
  set cy [expr ($by1+$by2)/2.0]

  foreach port $ports {

    setl {placeprop reg} \
	[_fplan_port_placetype -best_side $best_side -withplace $withplace $cell $port]
    if {$reg == "donttouch"} {continue}

    # Get connectivity inside lay_mod.
    # Make a pinlist of {x y name} for each pin in cell.
    # The name is put in the list for informative messages only.
    set pinlist ""
    set net [nl2_get_pin_net $lay_mod $port]
    foreach pin [nl2_get_net_pins $lay_mod $net] {
      if {$pin == $port} {continue}
      # This happens if a pin is connected to some cells, eg stdcells,
      # that were not placed in the cell.
      if {[catch {setl {px py} [fplan_db_pin2 -xform -cell $cell $pin]}]} {
	max_error -buffer "warning: cant find pin $cell.$pin maybe cell not placed?"
	continue
      }
      lappend pinlist [list $px $py $pin]
    }

    if {[llength $pinlist] == 0} {
      # Could not find anything to which this pin was connected...
      max_error -buffer "warning: cell $cell port $port not connected to anything; not placed"
      continue
    }


    setl {px py} [fplan_db_pin2 -cell $cell $port]

    # Set x,y to the nearest other point.
    if {$reg == "unknown"} {

      # Find nearest point to any side.  Set reg to that side.
      setl {reg point} [_fplan_nearest_side $cell_bbox $pinlist]
      if {$reg == "unknown"} {
	error "unexpected nearest side region"
      }
      setl {x y fndpin} $point
      if {$verbose} {
	msg "Moving port $port to be near pin $fndpin at $x $y side $reg\n"
      }

    } else {

      #if {$reg == "unknown"} {
      #	# Pin is not currently near any side.
      #	# See if a region prop was specified.
      #   NOTE: We dont use region props any more!!!
      #	set reg [fplan_db_pin -cell $cell getprop $port region]
      #	if {$reg == "center" || $reg == ""} {
      #	  # The port is not near any side, so we can hardly move it
      #	  # within that side.
      #	  max_error -buffer "warning: port $port not currently in any region, port not moved."
      #	  continue
      #	}
      #	# Start by moving the port to the center of the side specified by the region prop.
      #	setl {px py} [_fplan_region -cell $cell center $reg]
      #}

      # Find nearest point to current port location.
      setl {x y fndpin} [_fplan_nearest_point $px $py $pinlist]
      if {$verbose} {
	msg "Moving port $port to nearest pin $fndpin side $reg\n"
      }
    }

    # Set ix,iy to a point in $reg side of cell bbox.
    switch $reg {
      top {
	set ix [bound $x $bx1 $bx2]
	set iy $by2
      }
      bottom {
	set ix [bound $x $bx1 $bx2]
	set iy $by1
      }
      left {
	set ix $bx1
	set iy [bound $y $by1 $by2]
      }
      right {
	set ix $bx2
	set iy [bound $y $by1 $by2]
      }
    }

    # Move the port there.
    _fplan_move_label -cell $cell $port $ix $iy $reg
    if {0} {
      _fplan_sel_label $port
      struct max_label l [sel_what labels]
      if {${l.text} == ""} {
	error "cell $cell: could not select label $portname"
      }
      :delete
      db_label -cell $cell -pos $_FPLAN_PORT(lab_pos,$reg) -kind ${l.kind} ${l.layer} ${l.text} $ix $iy
    }

    if {[fplan_db_pin -cell $cell getprop $port place] == "unplaced"} {
      fplan_db_pin -cell $cell setprop $port place placed
    }
  }
  edit_pop_direct

  util_prof end
}


proc fplan_db_cache {{-all} {-cell ""} {-cells 0} {-clear}} -doc {
  Cache info on labels and cells.
  If -all, cache port info for current cell and all subcells.
  If -cell, cache ports only for that cell.
  If -cells, cache cell info as well as port info.
  If -clear, clear the cache.
} {
  # Update these two caches.
  global FPLAN_PORT_CACHE FPLAN_CELL_CACHE

  # At minimum, you always have to cache the cell defs, so just always do this.
  if {1 || $cells} {
    # Cache the cell transforms.
    catch {unset FPLAN_CELL_CACHE}
    set editcell [lay_editcell]
    foreach cell_info [db_search_l cells] {
      struct max_cell c $cell_info
      # This caches the transform of subcell c.id inside cell: cell.
      # We only use this inside the editcell, so the first cell
      # in the index is not really used, however, it is a good error check
      # that you are not trying to get a transform for a cell you havent cached.
      set FPLAN_CELL_CACHE($editcell,${c.id}) [list ${c.def} ${c.transform}]
    }
  }

  if {$all} {
# NOTE: Dont use this to try to get hierarchical transforms - I dont think it works.
error "-all not implemented"
    catch {unset FPLAN_PORT_CACHE}
    fplan_db_cache -cell [lay_editcell] -cells $cells
    foreach kid [db_kids] {
      fplan_db_cache -cell $kid -cells $cells
    }
    return
  }

  if {$cell != ""} {
    set port_list ""
    set global_port_list ""
    foreach lab_info [db_search_l labels -cell $cell -non_hier] {
      struct max_label l $lab_info
      switch -- ${l.kind} {
	input -
	output -
	inout {
	  set port ${l.text}
	  lappend port_list $port
	  set FPLAN_PORT_CACHE($cell,$port,info) [list ${l.x1} ${l.y1} ${l.kind} ${l.layer} $port]
	}
	global {
	  set port ${l.text}
	  lappend global_port_list $port
	}
      }
    }
    set FPLAN_PORT_CACHE($cell,io_port_list) $port_list
    set FPLAN_PORT_CACHE($cell,global_port_list) $global_port_list
    return
  }

  if {$clear} {
    catch {unset FPLAN_CELL_CACHE}
    catch {unset FPLAN_PORT_CACHE}
  }

  error "unrecognized options"
}

proc fplan_db_pin_list {{-cell ""} {-usecache} {-global}}  -desc {
  Return list of port names in specified cell.
} -doc {
  If -global, return list of global ports instead of io ports.
  If you call fplan_db_cache first, and use -usecache, this is instantaneous.
  Call fplan_db_pin2 to get data from the max label,
  or fplan_db_pin to get extra port data.
} {
  global FPLAN_PORT_CACHE
  if {$cell == ""} {set cell [lay_editcell]}

  if {$usecache} {
    if {$global} {
      return $FPLAN_PORT_CACHE($cell,global_port_list)
    } else {
      return $FPLAN_PORT_CACHE($cell,io_port_list)
    }
  } else {
    set port_list ""
    foreach lab_info [db_search_l labels -cell $cell -non_hier] {
      struct max_label l $lab_info
      set t ${l.kind}
      if {$global ? ($t=="global") : ($t=="input"||$t=="output"||$t=="inout")} {
	lappend port_list ${l.text}
      }
    }
    return $port_list
  }
}


proc fplan_db_pin2 {{-usecache} {-fixname} {-xform} {-cell ""} pin} -desc {
  Return label data.
} -doc {
  Return data that is stored in the max label structure as a list of:
    {x y iodir curlayer text}
  
  Pin is either a top-level port name, or subcellid.port
  Default action is to return data that is associated with the max port
  Note that curlayer may be "space".

  Why is the <text> name of the label returned?  Because if the
  input is subcellid.pin, it has been parsed out and had
  its name fixed if -fixname.

  If -fixname, the specified pin is from verilog, and must have
  characters fixed.  This operation is done in here
  instead of the caller because the cell and label part of a compound
  name like subcellid.pin must be fixed differently.

  If -usecache, use the cache, otherwise figure it out from scratch.

  If -cell, ports without a subcellid are assumed to be in that cell.

  -hch specifies the hierarchy separator char.

  If -xform and it is a sub-cell port, return x,y in the coordinate
  system of the current cell.  Note: if you specify -usecache,
  then the cache must have been created with the -cells option.
  The -xform only works one level deep.
} {
  global FPLAN_PORT_CACHE FPLAN_CELL_CACHE
  if {$cell == ""} {set cell [lay_editcell]}


  set hch .
  set i [string last $hch $pin]
  if {$i == -1} {
    set lab $pin
    set cellpath ""
  } else {
    set cellpath [string range $pin 0 [expr $i-1]]
    set lab [string range $pin [expr $i+1] end]
  }

  if {$fixname} {
    # The cellpath is actually the module path.  Turn names into legal max names.
    set cellpath [fplan_fix_name $cellpath]
    set lab [fplan_fix_name -label $lab]
  }

  if {$cellpath == ""} {
    if {$usecache} {
      return $FPLAN_PORT_CACHE($cell,$lab,info)
    }

    set lab_list [db_search_l labels -exact -non_hier -cell $cell $lab]
    if {[llength $lab_list] == 0} {
      error "label $pin not found"
    }
    struct max_label l [lindex $lab_list 0]
    return [list ${l.x1} ${l.y1} ${l.kind} ${l.layer} ${l.text}]
  } else {
    if {$usecache} {
      # If cell is not the editcell, this should error out:
      setl {def transform} $FPLAN_CELL_CACHE($cell,$cellpath)
      setl {x y kind layer text} $FPLAN_PORT_CACHE($def,$lab,info)
      if {$xform} { setl {x y} [transform_coords $transform $x $y] }
      return [list $x $y $kind $layer $text]
    }

    # No cache - find the cellpath and label using max commands.
    # The max data-base might be hierarchical or flat, so try both ways.
    regsub {\.} $cellpath "/" cellpath2
    if {[catch {sel_cell $cellpath2} result]} {
      # Maybe the cell is flat.
      regsub {\.} $cellpath "{FS}" cellpath2
      if {[catch {sel_cell $cellpath2} result]} {
	error "Can not find pin $pin (cell $cell)"
      }
    }

    set cell_list [sel_what_l cells]
    sel_clear
    if {[llength $cell_list] == 0} {
      error "cell $cellpath not found looking for pin $pin"
    }
    struct max_cell c [lindex $cell_list 0]

    # Find the label inside that cell.
    set lab_list [db_search_l labels -non_hier -cell ${c.def} -exact $lab]
    if {[llength $lab_list] == 0} {
      error "label $pin not found"
    }
    struct max_label l [lindex $lab_list 0]

    # OLD: This works, but path can be only one deep.
    #set cell_list [db_instances_l -cell $cell -id $cellpath]
    #if {[llength $cell_list] == 0} {
    #  error "cell $cellpath not found"
    #}
    #struct max_cell c [lindex $cell_list 0]
    #struct max_label l [lindex [db_search_l labels -exact -non_hier -cell ${c.def} $lab] 0]

    if {$xform} {
      setl {x y} [transform_coords ${c.transform} ${l.x1} ${l.y1}]
      return [list $x $y ${l.kind} ${l.layer} ${l.text}]
    }
    return [list ${l.x1} ${l.y1} ${l.kind} ${l.layer} ${l.text}]
  }
}

proc fplan_save_props {{-cell ""}} -desc {
  This is a temporary routine to save the props into the max file.
} -doc {
  It will go away when mha gives us hashed props and we use them directly without caching.
} {
  global FPLAN_PORT_INFO FPLAN_PORT_OPTIONS

  # Get just the names of the props out of FPLAN_PORT_OPTIONS
  set propnames ""
  foreach thing $FPLAN_PORT_OPTIONS {
    lappend propnames [lindex $thing 0]
  }

  # For each real cell, for each label in that cell...

  # TODO: Why is this reading in hierarchy?
  if {$cell != ""} {
    set cell_list [list $cell]
  } else {
    set cell_list ""
    foreach cell_thing [split [string trim [db_cells -user]] \n] {
      set cell [lindex $cell_thing 0]
      if {[cell_in_memory $cell]} {
	lappend cell_list $cell
      }
    }
  }

  foreach cell $cell_list {
    # Skip gcells.
    if {[string match {#*} $cell]} {continue}

    set label_list [db_search_l labels -non_hier -cell $cell]
    foreach lab_info $label_list {
      struct max_label l $lab_info
      if {${l.kind} == "hidden"} continue
      set port ${l.text}

      # Gather up props on this port into a list.
      set proplist ""
      foreach propname $propnames {
	if {[info exists FPLAN_PORT_INFO($cell,$port,$propname)]} {
	  lappend proplist [list $propname $FPLAN_PORT_INFO($cell,$port,$propname)]
	}
      }

      # Save it in the cell.
      if {$proplist != ""} {
	#puts "db_prop -def $cell PORT($port) $proplist"
	db_prop -def $cell PORT($port) $proplist
      }
    }
  }
}

proc fplan_db_pin {{-cell ""} action {pin ""} {propname ""} {value ""}} -desc {
  Manipulate pin data that is not part of the max label structure.
} -doc {
  USAGE:
    fplan_db_pin [-cell <cell>] getprop <pin> <propname>          - return value or propname.
    fplan_db_pin [-cell <cell>] setprop <pin> <propname> <value>  - set value of propname.
    fplan_db_pin [-cell <cell>] getregion <pin>                   - find region pin is currenly in.
	or return "unknown" if not near any region.
    fplan_db_pin [-cell <cell>] delete [<pin>]                 - delete pin info;
	    if no pin, delete all pins in cell.
    fplan_db_pin [-cell <cell>] init

  Note: Updates the database, but does not update the max cells.
} {
  global FPLAN FPLAN_PORT_INFO FPLAN_PORT_OPTIONS

  if {$cell == ""} {set cell [lay_editcell]}

  if {!$FPLAN(use_db_prop) && [use_first FPLAN_PORT_INFO($cell,loaded)] != 1} {

    # Load props from slow max db_props into hash table.
    # Only need to do this once when the file is loaded,
    # EXCEPT, what if user says db_cell_delete?

    # All fplan props on a port are saved in a single assoc list
    # on a max prop in the cell def with name PORT($portname)
    foreach propname [db_prop -def $cell] {
      if {[regexp {^PORT\((.*)\)$} $propname junk portname]} {
	set values [db_prop -def $cell $propname]
	foreach pair $values {
	  set FPLAN_PORT_INFO($cell,$portname,[lindex $pair 0]) [lindex $pair 1]
	}
      }
    }

    set FPLAN_PORT_INFO($cell,loaded) 1
  }

  switch -- $action {
    delete {
      # If pin is null, it will selecte all pins.
      foreach name [array names FPLAN_PORT_INFO "$cell,${pin}*"] {
	if {$FPLAN(use_db_prop)} {
	  foreach thing $FPLAN_PORT_OPTIONS {
	    db_prop -def $cell -delete PORT($pin,[lindex $thing 0])
	  }
	} else {
	  unset FPLAN_PORT_INFO($name)
	}
      }
    }
    init {
      # Set default values for a pin.
      if {$FPLAN(use_db_prop)} {
	foreach thing $FPLAN_PORT_OPTIONS {
	  if {[lindex $thing 1] != "" && \
	    [db_prop -def $cell PORT($pin,[lindex $thing 0])] == ""} {
	    db_prop -def $cell PORT($pin,[lindex $thing 0]) [lindex $thing 1]
	  }
	}
      } else {
	use_init FPLAN_PORT_INFO($cell,$pin,place) "unplaced"
	use_init FPLAN_PORT_INFO($cell,$pin,layerspec) "space"
      }
    }
    exists {
      return [expr [llength [db_search_l labels -non_hier -cell $cell -exact $pin]] == 1]
    }
    setprop {
      if {$FPLAN(use_db_prop)} {
	db_prop -def $cell PORT($pin,$propname) $value
      } else {
	set FPLAN_PORT_INFO($cell,$pin,$propname) $value
      }
    }
    getprop {
      if {$FPLAN(use_db_prop)} {
	return [db_prop -def $cell PORT($pin,$propname)]
      } else {
	return [use_first FPLAN_PORT_INFO($cell,$pin,$propname)]
      }
    }
    getregion {
      struct max_label l [lindex [db_search_l labels -non_hier -cell $cell -exact $pin] 0]

      set cell_rect [fplan_bbox -cell $cell]
      setl {side point dist} [_fplan_nearest_side $cell_rect [list [list ${l.x1} ${l.y1}]]]

      # If the port is within 20% of the minimum box dimension of the nearest side,
      # count as being in the region.
      setl {bx1 by1 bx2 by2} $cell_rect
      set mincord [min [expr $bx2-$bx1] [expr $by2-$by1]]
      if {$dist < [min 1 [expr $mincord * .2]]} {
	return $side
      } else {
	# Point is not within 20% of box dimension of any side.
	return "unknown"
      }


      setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
      # Fuzz is how close the port has to be to the region to count.
      set fuzz [expr [max [expr $bx2-$bx1] [expr $by2-$by1]] * .3]
      setl {gx1 gy1 gx2 gy2} [grow_rect $fuzz [list $bx1 $by1 $bx2 $by2]]

      if {[approx ${l.x1} == $bx1 $fuzz] && ${l.y1} >= $gy1 && ${l.y1} <= $gy2} {
	return right
      } elseif {[approx ${l.x2} == $bx2 $fuzz] && ${l.y1} >= $gy1 && ${l.y1} <= $gy2} {
	return left
      } elseif {[approx ${l.y1} == $by1 $fuzz] && ${l.x1} >= $gx1 && ${l.x1} <= $gx2} {
	return bottom
      } elseif {[approx ${l.y2} == $by2 $fuzz] && ${l.x1} >= $gx1 && ${l.x1} <= $gx2} {
	return top
      } else {
	# Dont know where it is.  Hook flyline to center to mean "dont know"
	return unknown
      }
    }
    default {
      error "unrecognized action: fplan_db_pin $action ..."
    }
  }
}

proc _fplan_region {{-cell ""} {-box ""} what region} -desc {
  Return info about a region.
} -doc {
  If -box, use that rectangle instead of the cell bbox.
} {
  global FPLAN

  if {$box != ""} {
    setl {bx1 by1 bx2 by2} $box
  } else {
    if {$cell == ""} {set cell [lay_editcell]}
    setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
  }


  # Shrink the rectangle by the wiring offset.
  switch -- $region {
    top - bottom {
      setl {snapx snapy offx offy} [wire_get_grid m$FPLAN(layer_default,vertical)]
    }
    default {
      setl {snapx snapy offx offy} [wire_get_grid m$FPLAN(layer_default,horizontal)]
    }
  }
  set bx1 [expr $bx1 + $offx]
  set bx2 [expr $bx2 - $offx]
  set by1 [expr $by1 + $offy]
  set by2 [expr $by2 - $offy]

  # Set bx1 by1 bx2 by2 to the rectangle representing the region.
  switch $region {
    "top"    { set by1 $by2 }
    "bottom" { set by2 $by1 }
    "left"   { set bx2 $bx1 }
    "right"  { set bx1 $bx2 }
    "center" {
      setl {bx1 by1} [uusnap [expr ($bx1 + $bx2)/2.0] [expr ($by1 + $by2)/2.0]]
      set bx2 $bx1
      set by2 $by1
    }
  }

  switch -- $what {
    "center" {
      # Return center of region.
      return [uusnap [expr ($bx1 + $bx2) / 2.0] [expr ($by1 + $by2) / 2.0]]
    }
    "area" {
      # Return a 0 width box representing the line where ports go.
      # If region is vertical then bx1==bx2; if horizontal then by1==by2
      return [list $bx1 $by1 $bx2 $by2]
    }
    "portarea" {
      # The area expanded by half the wire pitch to cover the port keep-out area.
      return [list [expr $bx1-$offx] [expr $by1-$offy] [expr $bx2+$offx] [expr $by2+$offy]]
    }
    default {
      error "unrecognized arg to fplan_region: $what"
    }

  }

}

proc _fplan_check_missing_ports {cell other_ports} -desc {
  See if labels in the max file are missing from the verilog/ports file, and optionally delete.
} {
  set max_ports [fplan_db_pin_list -cell $cell]

  setl {extra_max_ports extra_nl_ports} [ldiff $max_ports $other_ports]

  if {[llength $extra_max_ports]} {

    update idletasks   ;# Let user see the screen.

    set msg "There are ports in max cell $cell that are missing in the verilog or ports file. \
    Do you want to delete them from max?  Missing ports:\n $extra_max_ports"
    set choice [prop_dialog -title "Cell $cell" -buttons "Yes No" $msg]
    if {$choice == "Yes"} {
      edit_push_direct $cell
      sel_clear
      foreach pin $extra_max_ports {
	catch {_fplan_sel_label -more $pin}
      }
      :delete
      edit_pop_direct
    }
  }
}

proc fplan_edit_ports_file {} -desc {
  Write .ports file for cells, edit with text editor, read back in changes.
} {
  set cell_info_list [sel_what_l cells]

  set cell_list [cell_process_multiple -selection -title "Edit .ports file for cells:"]
  if {[llength $cell_list] == 0} {return}

  set file_list ""
  foreach cell $cell_list {
    fplan_write_ports $cell
    lappend file_list ${cell}.ports
  }

  misc_text_edit $file_list

  foreach cell $cell_list {
    fplan_read_ports $cell
  }

  # Restore selection for user convenience
  sel_clear
  foreach cell_info $cell_info_list {
    struct max_cell c $cell_info
    sel_cell2 -more ${c.id}
  }
}

proc _fplan_list_selected_ports {bus} -desc {
  Return [list cell cellid portlist] for currently selected ports.
} -doc {
  If a single cell is selected, return all its ports.
  If some ports are selected, return them.
  If nothing is selected, return ports in current cell.
  The cellid is . if cell is the lay_editcell
} {
  set portlist ""
  set cell_list [sel_what_l cells]
  set lab_list [sel_what_l labels]

  if {[llength $cell_list] > 0} {
    if {[llength $cell_list] > 1} {
      error "Select one cell, or edit cell and select some ports"
    }
    struct max_cell c [lindex $cell_list 0]
    set cell ${c.def}
    set cellid ${c.id}
    set portlist [fplan_db_pin_list -cell $cell]
  } elseif {[llength $lab_list] > 0} {
    set cell [lay_editcell]
    set cellid .
    foreach label_info $lab_list {
      struct max_label l $label_info
      if {${l.kind} != "hidden"} {
	lappend portlist ${l.text}
      }
    }
  } else {
    # No ports or cells selected.  Do ports in current cell.
    set cell [lay_editcell]
    set cellid .
    # Return all ports in cell.
    set portlist [fplan_db_pin_list]
    #foreach label_info [db_search_l labels -non_hier -cell $cell] {
    #  struct max_label l $label_info
    #  lappend portlist ${l.text}
    #}
  }


  # Optionally bussify the ports.
  set mod [fplan_db_cell module $cell]
  if {$bus} {

    # 7/17/01: Done on demand now.
    #if {! [nlt_agg_ok $mod]} {
    #  # No connectivity from verilog or elsewhere.
    #  # Just aggregate busses based on the port names.
    #  nlt_init_aggregate $mod $portlist
    #}

    set buslist ""
    foreach port $portlist {
      set busname [nlt_bus $mod $port]
      if {$busname != ""} {
	lappend buslist $busname
      }
    }
    return [list $cell $cellid $buslist]
  } else {
    return [list $cell $cellid $portlist]
  }
}

proc fplan_edit_selected_ports {{-editcell 0}} -desc {
  Edit floorplan props for ports in selected.  Selected may be a cell or some ports.
} -doc {
  If -editcell, edit all ports in edit cell.
  Otherwise edit selected cell, or selected ports.
} {
  # Save selection for later
  set cell_list [sel_what_l cells]
  set lab_list [sel_what_l labels]

  set aggbus 1
  set run_optimizer 1
  set run_spreader 1
  set adjacent 1
  set best_side 1
  set place_opts "unplaced placed"
  set verbose 0

  # Now create a proplist for the ports in cell.
  # There could be zillions, so do it in stages.
  # Make a top-level prop_list with buttons for each NPER ports.
  set NPER 16

  if {$editcell} {
    set cell [lay_editcell]
    set bitlist [fplan_db_pin_list -cell $cell]
    set cid "."
  } else {
    setl {cell cid bitlist} [_fplan_list_selected_ports 0]
  }

  # Init the port props.
  foreach bit $bitlist {
    fplan_db_pin -cell $cell init $bit
  }

  if {![nl2_loaded [fplan_db_cell module $cell]]} {
    max_error -buffer "Warning: No verilog loaded for module [fplan_db_cell module $cell]"
    msg_flush
    # Does not exit, just keeps going.
  }

  do {
    # Recreate the prop_menu.

    set prop_list ""

    lappend prop_list [list "" "" -help {
      Pin placement optimization: The main choices are:
      1.  If a subcell is selected, optimization is based on
      the nearest pin/port to any cell outside the selected cell.
      2. If no cells are selected, ports in the editcell are
      optimized based on the nearest pin inside the editcell.
      
      There are two options for each case:
      a.  Move pins to best side.
      b.  Shift pins to best location within their current regions,
	  ie, do not move pins to a different side.
      
      The optimizer moves ports with "place" == "unplaced",
      and optionally moves ports with "place" == "placed".
      The optimization phase moves ports to optimal locations without
      regard to port conflicts, and the "place" property is changed to "placed".

      Port location conflicts are resolved in the following order:
      If "place" == "fixed" or "cover", the port is not moved.
	A warning is printed if two fixed ports collide.
      If "place" == "placed", the port is moved as near as possible to the location
	specified by the "loc" and "bitloc" properties, if specified,.
	otherwise to the nearest free location.
      If "place" == "unplaced", the port is moved to the cell center.
    }]

    lappend prop_list [list "PIN LOCATION OPTIMIZER" "" -label]
    lappend prop_list [list "run optimizer" run_optimizer -binary]

    lappend prop_list [list "move pins to best side" best_side -binary]

    lappend prop_list [list "process ports with place=" place_opts \
      -choice {"unplaced placed" "unplaced" "placed"}]
    
    lappend prop_list [list "align adjacent pins" adjacent -binary]
    lappend prop_list [list "verbose" verbose -binary]

    lappend prop_list [list "" "" -separator]

    lappend prop_list [list "PIN LOCATION SPREADER" "" -label]
    lappend prop_list [list "run spreader" run_spreader -binary]
    lappend prop_list [list "" "" -separator]

    lappend prop_list [list "PIN EDITOR" "" -label]

    # Determine the cell and gather up a list of ports to process.
    # We have to do it again in case aggbus changed.
    setl {cell cid portlist} [_fplan_list_selected_ports $aggbus]
    if {[llength $portlist] == 0} {
      error "No ports found in cell $cell"
    }
    set portlist [lsort -dictionary $portlist]

    #lappend prop_list [list "Select a range of ports:" "" -label]

    # This option does a -return 2 so we can rebuild the prop menu.
    lappend prop_list [list "show ports as busses" aggbus -binary -return 2]

    for {set i 0} {$i < [llength $portlist]} {incr i $NPER} {
      set p1 [lindex $portlist $i]
      set i2 [expr [min [expr $i + $NPER] [llength $portlist]] - 1]
      set p2 [lindex $portlist $i2]
      set sublist [lrange $portlist $i $i2]
      lappend prop_list [list "$p1 - $p2" "" -button \
	[list _fplan_edit_port_list $cell $sublist]]
    }

    set ret [prop_menu2 -title "Cell $cell" $prop_list]
  } while {$ret == 2}

  if {$ret != 0} {
    # prop_menu not cancelled. Do it.

    # Get the port list again, to make sure we are getting individual ports, not busses.
    setl {cell cid bitlist} [_fplan_list_selected_ports 0]

    if {$run_optimizer} {
      msg "Optimize Ports $cell -verbose $verbose -withplace \"$place_opts\" -best_side $best_side\n"

      if {$cell == [lay_editcell]} {
	_fplan_port_opt_inside -verbose $verbose -withplace $place_opts -best_side $best_side $cell $bitlist
      } else {
	_fplan_port_opt_outside -verbose $verbose -withplace $place_opts -adjacent $adjacent -best_side $best_side $cid
      }
    }

    if {$run_spreader} {
      fplan_place_ports $cell $bitlist
    }
  }

  # Restore selection
  sel_clear
  foreach cell_info $cell_list {
    struct max_cell c $cell_info
    sel_cell2 ${c.id}
  }
  foreach label_info $lab_list {
    struct max_label l $label_info
    sel_labels -more -text ${l.text}
  }
}


proc _fplan_edit_port_list {cell portlist} -desc {
  Show prop menu for ports in portlist.
} {
  global FPLAN FPLAN_PORT_HELP _FPLAN_EDIT_PORT_LIST_OPTS

  use_init _FPLAN_EDIT_PORT_LIST_OPTS(all) 0  ;# TODO
  use_init _FPLAN_EDIT_PORT_LIST_OPTS(show_current) 0

  foreach port $portlist {
    # Cache the first bit of each port.
    set bitcache($port) [lindex [nlt_bus_explode $port] 0]
  }

  while {1} {
    # The prop_menu panels are vertical, so we have to load
    # up the rows one panel at a time.
    set prop_list ""
    set show $_FPLAN_EDIT_PORT_LIST_OPTS(show_current)

    foreach port $portlist {
      lappend prop_list [list $port "" -label]
      if {$show} {
	lappend prop_list [list "   " "" -label]
      }
    }

    # Put this at the bottom of the first column
    lappend prop_list [list "Show current port info" _FPLAN_EDIT_PORT_LIST_OPTS(show_current) \
	  -binary -return 2]

    lappend prop_list [list "" "" -break 20]

    # The ports might be aggregated busses.  Display properties
    # on the first bit of the bus.  TODO: Should check to make sure that
    # props on all other bits are the same.

    #foreach port $portlist {
    #  set port_info($port,region) [fplan_db_pin -cell $cell getprop $bitcache($port) region]
    #  lappend prop_list [list region port_info($port,region) \
    #    -choice {center top bottom left right}]
    #}

    lappend prop_list [list "" "" -break 20]
    foreach port $portlist {
      set port_info($port,place) [fplan_db_pin -cell $cell getprop $bitcache($port) place]
      lappend prop_list [list place port_info($port,place) \
	-choice {unplaced placed fixed}]
      if {$show} {
	set port_info($port,curside) [fplan_db_pin -cell $cell getregion $bitcache($port)]
	lappend prop_list [list "cur_side" port_info($port,curside) -label]
      }
    }

    lappend prop_list [list "" "" -break 20]
    foreach port $portlist {
      set port_info($port,loc) [fplan_db_pin -cell $cell getprop $bitcache($port) loc]
      lappend prop_list [list loc port_info($port,loc) -popup {left right top bottom ""}]
      if {$show} {
	struct max_label l [lindex [db_search_l labels -cell $cell -exact -non_hier $bitcache($port)] 0]
	set port_info($port,curxy) "${l.x1} ${l.y1}"
	set port_info($port,curlayer) ${l.layer}
	lappend prop_list [list "cur_xy" port_info($port,curxy) -label]
      }
    }

    lappend prop_list [list "" "" -break 20]
    foreach port $portlist {
      set port_info($port,bitloc) [fplan_db_pin -cell $cell getprop $bitcache($port) bitloc]
      lappend prop_list [list bitloc port_info($port,bitloc) -entry]
      if {$show} {
	lappend prop_list [list "  " "" -label]  ;# Place holder needed.
      }
    }

    lappend prop_list [list "" "" -break 20]
    set layer_choices [concat space [techinfo layers metal]]
    foreach port $portlist {
      set port_info($port,layerspec) [fplan_db_pin -cell $cell getprop $bitcache($port) layerspec]
      lappend prop_list [list layerspec port_info($port,layerspec) \
	-choice $layer_choices]
      if {$show} {
	lappend prop_list [list "cur_layer" port_info($port,curlayer) -label]
      }
    }

    if {$_FPLAN_EDIT_PORT_LIST_OPTS(all)} {
      lappend prop_list [list "" "" -break 20]
      foreach port $portlist {
	setl {x y iodir curlayer text} [fplan_db_pin2 -cell $cell $bitcache($port)]
	set port_info($port,iotype) $iodir
	lappend prop_list [list iotype port_info($port,iotype) \
	  -choice {input output inout}]
      }
    }

    # The help must be provided on only one thing, or it will appear
    # multiple times in the help screen.  So we just put the help
    # on empty props.

    foreach thingy $FPLAN_PORT_HELP {
      lappend prop_list [list "" "" -help $thingy]
    }

    if {0} {
    lappend prop_list [list "" "" -help {region: \
	top, bottom, left, right indicate placement\
	anywhere on that side. \
	"center" is used for new pins. \
	"placed" means suggested placment provided, but may be moved by tools. \
	"fixed" means current placement may not over-ridden by tools. \
	Additional regions may be added to the cell.}]
    lappend prop_list [list "" "" -help {type: \
	To be defined, for wire size, shielding, etc.}]
    lappend prop_list [list "" "" -help {iotype: \
	"space" means layer is undefined.  The layer should be auto-magically\
	determined from the port side in the final placement, so this\
	should normally be left alone.}]
    }

    set ret [prop_menu2 -title "Ports in cell $cell" $prop_list]
    if {$ret == 0} {
      # Cancelled
      return
    }
    if {$ret == 2} {
      # Reload menu with new options
      continue
    }
    break
  }

  # Save changed props.
  foreach port $portlist {
    foreach bit [nlt_bus_explode $port] {
      foreach propname {loc bitloc place layerspec} {
	fplan_db_pin -cell $cell setprop $bit $propname $port_info($port,$propname)
      }
    }
  }
}

proc _fplan_ver_merge_pins {{-verbose 0} cell mod} -desc {
  Add/merge pins in cell for verilog module mod.
} {

  set verilog_port_list [nl2_list_ports -incl_kind 1 $mod]

    if {0} {
	OLD WAY
      foreach port_info ${m.ports} {
	setl {id num1 num2 kind} $port_info
	# Make a list of port names, with busses optionally flattened.
	set port_names ""
	if {$num1 == -1 && $num2 == -1} {
	    lappend port_names $id
	} else {
	  set port_bits [_verilog_flatten_range $id $num1 $num2]
	  if {! $bus} {
	    set port_names [concat $port_names $port_bits]
	  } else {
	    foreach single_port $port_bits {
	      set bus_name [nlt_bus $mod $single_port]
	      if {$bus_name != ""} {
		lappend port_names $bus_name
	      }
	    }
	    #if {$num1 == $num2} {
	    #  lappend port_names "$id\[$num1\]"
	    #} else {
	    #  lappend port_names "$id\[$num1:$num2\]"
	    #}
	  }
	}
      }
    }

  # Keep a list of the ports seen in the verilog module.
  set ports_seen ""

  # Compute center of cell.
  setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
  setl {cx cy} [uusnap -mask [expr ($bx1 + $bx2) / 2.0] [expr ($by1 + $by2) / 2.0]]

  foreach thing $verilog_port_list {
    setl {port kind} $thing
    set port [fplan_fix_name -label $port]
    lappend ports_seen $port
    if {[llength [db_search_l labels -non_hier -cell $cell -exact $port]] == 0} {
      if {$verbose} {
	msg "adding verilog port ${cell}.$port\n"
      }
      db_label -cell $cell -kind $kind space $port $cx $cy
      fplan_db_pin -cell $cell init $port
    }
  }

    # Now see if some ports were deleted.
  _fplan_check_missing_ports $cell $ports_seen


  #setl {gx gy} [res2 $grid]
  #setl {x1 y1 x2 y2} [fplan_bbox -cell $cell]
  #setl {x1 y1 x2 y2} [uusnap -grid $grid [expr $x1 - $gx] [expr $y1 - $gy] \
  #  [expr $x2 + $gx] [expr $y2 + $gy]]
  #set y2 [round_list_scale [expr $y2 + $gy] $gy]
  #db_paint -cell $cell prb $x1 $y1 $x2 $y2

}

proc fplan_write_ports {{cell ""}} {

  if {$cell == ""} {
    set cell_list [cell_process_multiple -selection -title "Write .ports file for cells:"]
    foreach cell $cell_list {
      fplan_write_ports $cell
    }
    return

    # Write all subcells of root cell
    #set cell_list [db_search_l cells]
    #if {[llength $cell_list] == 0} {
    #  error "No subcells found!"
    #}

    #foreach cell_info $cell_list {
    #  struct max_cell c $cell_info
    #  fplan_write_ports ${c.def}
    #}

  } else {
    set filename "${cell}.ports"
    set fd [open $filename "w"]

    setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
    puts $fd "# Created by max floorplanner [clock format [clock seconds]]"
    puts $fd "# Cell: ${cell}"
    puts $fd "bbox [expr ${bx2} - ${bx1}] [expr ${by2} - ${by1}]"
    puts $fd "orient N"

    set pins [fplan_db_pin_list -cell $cell]
    set maxlen 0
    foreach pin $pins {
      set maxlen [max $maxlen [string length $pin]]
    }

    foreach pin [lsort -dictionary [fplan_db_pin_list -cell $cell]] {
      TODO: This is out of date.
      set x [fplan_db_pin -cell $cell getprop $pin x]
      set y [fplan_db_pin -cell $cell getprop $pin y]
      set portinfo [format "port %-*s %10s %10s" $maxlen $pin $x $y]
      set port_props [fplan_db_pin -cell $cell props $pin]
      foreach pair $port_props {
	setl {propname value} $pair
	if {$propname == "x" || $propname == "y"} {
	  # These are placed in the ports file above.
	  continue
	}
	if {$value != ""} {
	  append portinfo " -$propname [list $value]"
	}
      }
      puts $fd $portinfo
    }

    if {0} {
    edit_push_direct $cell
    # Cook up the transform to put relative (0,0) at the lower left.
    setl {bx1 by1 bx2 by2} [fplan_bbox]
    # NOTE: we do not need the transform because we are editing this cell!
    #set xform [list 1 0 [expr - ${bx1}] 0 1 [expr - ${by1}]]

    puts $fd "# Created by max floorplanner [clock format [clock seconds]]"
    puts $fd "# Cell: ${cell}"
    puts $fd "bbox [expr ${bx2} - ${bx1}] [expr ${by2} - ${by1}]"
    puts $fd "orient N"

    set sort_list ""
    foreach lab_info [db_search_l labels -non_hier] {
      struct max_label l $lab_info
      lappend sort_list [list ${l.text} $lab_info]
    }

    foreach thingy [lsort -dictionary $sort_list] {
      setl {junk port_info} $thingy
      struct max_label l $port_info
      #puts $fd "port ${l.text} [transform_coords $xform ${l.x1} ${l.y1}]"
      set portinfo [format "port %-20s %10s %10s" ${l.text} ${l.x1} ${l.y1}]
      set port_props [db_prop PORT(${l.text})]
      foreach pair $port_props {
	setl {propname value} $pair
	if {$value != ""} {
	  append portinfo " -$propname [list $value]"
	}
      }
      puts $fd $portinfo
    }
    edit_pop_direct
    }

    close $fd

    msg "Wrote file: $filename\n"
  }
}

proc fplan_read_ports {{-merge "ask_me"} {cell ""}} -doc {
  USAGE:
    fplan_read_ports [-merge yes|no|ask_me] [cell]
} {
  global FPLAN_PORT_OPTIONS

  set error_printed 0

  if {$cell == ""} {

    set cell_list [cell_process_multiple -selection -title "Read .ports file for cells:"]
    foreach cell $cell_list {
      fplan_read_ports $cell
    }
    return

    # Write all subcells of root cell
    #set cell_list [db_search_l cells]
    #if {[llength $cell_list] == 0} {
    #  error "No subcells found!"
    #}

    #foreach cell_info $cell_list {
    #  struct max_cell c $cell_info
    #  fplan_read_ports -merge $merge ${c.def}
    #}
  } else {
    edit_push_direct $cell

    # Keep a list of all the ports we have seen.
    set ports_seen ""

    # Compute center of cell.
    setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
    setl {cx cy} [uusnap -mask [expr ($bx1 + $bx2) / 2.0] [expr ($by1 + $by2) / 2.0]]

    set filename ${cell}.ports
    set fd [open $filename "r"]
    while {![eof $fd]} {
      set line [gets $fd]
      switch -- [lindex $line 0] {
	"port" {
	  setl {junk port x y} $line
	  lappend ports_seen $port
	  set port_opts [lrange $line 4 end]
	  set leftover [parse_keyword $port_opts $FPLAN_PORT_OPTIONS opt]

	  if {!$error_printed && $leftover != ""} {
	    set error_printed 1
	    max_error -buffer "warning: unrecognized stuff in ports file: $leftover"
	  }

	  if {[llength [db_search_l labels -non_hier -cell $cell -exact $port]] == 0} {

	    # Port does not exist in max.
	    if {$merge == "ask_me"} {
	      set msg "There are port additions in ports file for cell $cell. \
	      Do you want to merge into max?"
	      set choice [tk_dialog .dialog "Cell $cell" $msg {} 0 Yes No]
	      if {$choice == 0} {
		set merge "yes"
	      } else {
		set merge "no"
	      }
	    }

	    if { $merge == "no" } { continue }
	    # Create the port.

	    db_label -cell $cell space $port $x $y
	    #fplan_db_pin -cell $cell add $port
	  }

	  # Update port options from port file.
	  foreach pair $FPLAN_PORT_OPTIONS {
	    set propname [lindex $pair 0]
	    if {$opt($propname) != ""} {
	      fplan_db_pin -cell $cell setprop $port $propname $opt($propname)
	    }
	  }
	}
      }
    }
    close $fd

    _fplan_check_missing_ports $cell $ports_seen

    edit_pop_direct

    fplan_place_ports $cell

    msg "Read file: $filename\n"
  }
}


proc bound {val lo hi} {
  if {$val+0 < $lo} {set val $lo}
  if {$val+0 > $hi} {set val $hi}
  return $val
}


proc _fplan_add_label {portname ix iy kind layer reg} {
  global _FPLAN_PORT
  db_label -pos $_FPLAN_PORT(lab_pos,$reg) -kind $kind $layer $portname $ix $iy
  # Draw a little piece of metal.

  #BUG: THIS CAUSING MAX CORE DUMPS, so disabled.
  #set l [wire_info width $layer]
  #eval db_paint $layer [uusnap -mask \
  #	[expr $ix-$l/2] [expr $iy-$l/2] [expr $ix+$l/2] [expr $iy+$l/2]]
}

proc _fplan_sel_label {{-more} portname} {
  if {! $more} {sel_clear}
  sel_labels -more -text $portname
  # Select the attached paint, if any.
  struct max_label l [lindex [db_search_l labels -exact -non_hier $portname] 0]

  #BUG: THIS CAUSING MAX CORE DUMPS, so disabled.
  #sel_chunk -more ${l.layer} ${l.x1} ${l.y1} ${l.x1} ${l.y1}
}

proc _fplan_move_label {{-cell ""} portname ix iy reg} -doc {
  ix,iy are new location in cell's coordinate system.
} {

  if {$cell == ""} {set cell [lay_editcell]}

  edit_push_direct $cell
  sel_labels -text $portname
  struct max_label l [sel_what labels]
  if {${l.text} == ""} {
    error "cell $cell: could not select label $portname"
  }
  #BUG: THIS CAUSING MAX CORE DUMPS, so disabled.
  #sel_chunk -more ${l.layer} ${l.x1} ${l.y1} ${l.x1} ${l.y1}
  :delete

  _fplan_add_label $portname $ix $iy ${l.kind} ${l.layer} $reg
  edit_pop_direct
}




proc fplan_recover_ports {} -desc {
  Convert old port information to new port information.
} -doc {
  Temporary routine to recover info saved in the ng chip.
} {
  foreach propname [db_prop] {
    if {[regexp {^PORT\(([^,]+)\)$} $propname junk portname]} {
      # Old style port info.
      set old_props [db_prop $propname]
      puts "fixing $propname $old_props"
      foreach pair $old_props {
	setl {propname propval} $pair
	db_prop PORT($portname,$propname) $propval
      }
      db_prop -delete $propname
    }
  }
}
