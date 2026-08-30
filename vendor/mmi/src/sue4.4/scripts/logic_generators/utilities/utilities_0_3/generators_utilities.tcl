# This file contains utility routines used by the generators.
# rev 0.3, 05/19/00

# This procedure gets information on the pins for a cell.
# It returns an ordered list with the following format:
#   first term:  {{ninputs x} {noutputs y} {ninouts z}}
#   2nd term:  data for input pins; pins are sorted alphabetically
#   3rd term:  data for output pins; pins are sorted alphabetically
#   4th term:  data for inout pins; pins are sorted alphabetically
#
# Example:  for MMI_AND2, the following is returned:
# {{{ninputs 2} {noutputs 1} {ninouts 0}} {{in0 -60 -20} {in1 -60 20}} {{out 60 0}} {}

proc generators_get_pin_info {cell} {

  set ninputs 0
  set noutputs 0
  set ninouts 0

  set inpins ""
  set outpins ""
  set inoutpins ""

  set terms [api_terminal_data $cell]

  if {$terms == ""} {
    puts "Warning, cell $cell not found."
    return ""
  }

  # classify the pins by type
  foreach term $terms {
    set pname [lindex $term 0]
    set data [get_assoc $pname $terms]
    set type [get_assoc type $data]
    if {$type == "input"} {
      incr ninputs
      lappend inpins $pname
    } elseif {$type == "output"} {
      incr noutputs
      lappend outpins $pname
    } else {
      incr ninouts
      lappend inoutpins $pname
    }
  }

  # sort each pin list
  set inpins [lsort -dictionary -increasing $inpins]
  set outpins [lsort -dictionary -increasing $outpins]
  set inoutpins [lsort -dictionary -increasing $inoutpins]

  # build the pin data
  set inpindata ""
  foreach pin $inpins {
    set data [get_assoc $pin $terms]
    set origin [get_assoc origin $data]
    set pin_x [lindex $origin 0]
    set pin_y [lindex $origin 1]
    lappend inpindata [list $pin $pin_x $pin_y]
  }
  set outpindata ""
  foreach pin $outpins {
    set data [get_assoc $pin $terms]
    set origin [get_assoc origin $data]
    set pin_x [lindex $origin 0]
    set pin_y [lindex $origin 1]
    lappend outpindata [list $pin $pin_x $pin_y]
  }
  set inoutdata ""
  foreach pin $inoutpins {
    set data [get_assoc $pin $terms]
    set origin [get_assoc origin $data]
    set pin_x [lindex $origin 0]
    set pin_y [lindex $origin 1]
    lappend inoutdata [list $pin $pin_x $pin_y]
  }

  # build the count data
  set count [list [list "ninputs" $ninputs] [list "noutputs" $noutputs] [list "ninouts" $ninouts]]

  # build the return data
  set pindata [list $count $inpindata $outpindata $inoutdata]

  return $pindata
}


# This procedure returns the x and y values associated with a pin name, from
# pin data having the following format:
#
# {{pin_name_0 origin_x origin_y} {pin_name_1 origin_x origin_y} ... }
#
# The pin data format is that which is output by proc generators_get_pin_info.

proc generators_get_pin_xy {pin pindata} {
  foreach pdata $pindata {
    setl {pname px py} $pdata
    if {$pname == $pin} {
      return [list $px $py]
    }
  }

  puts "Warning, pin $pin not found, returning 0,0"
  return "0 0"
}


# This procedure returns the dimensions of an icon.
# Format of the return value:
# {width height lower_left_x lower_left_y upper_right_x upper_right_y}

proc generators_get_icon_size {cell} {

  set left_x 0
  set right_x 0
  set top_y 0
  set bot_y 0

  set terms [api_terminal_data $cell]

  if {$terms == ""} {
    puts "Warning, cell $cell not found."
    return ""
  }

  # find the leftmost pin and the rightmost pin,
  # as well as the highest and lowest pin y values

  foreach term $terms {
    set pname [lindex $term 0]
    set data [get_assoc $pname $terms]
    set origin [get_assoc origin $data]
    set type [get_assoc type $data]
    set pin_x [lindex $origin 0]
    set pin_y [lindex $origin 1]
    if {$pin_x < $left_x} {
      set left_x $pin_x
    }
    if {$pin_x > $right_x} {
      set right_x $pin_x
    }
    if {$pin_y < $top_y} {
      set top_y $pin_y
    }
    if {$pin_y > $bot_y} {
      set bot_y $pin_y
    }
  }

  # cover the cases where there are no pins on one edge:
  # assume icon is symmetrical about (0,0)
  if {$left_x == 0} {
    set left_x [expr -($right_x)]
  }
  if {$right_x == 0} {
    set right_x [expr -($left_x)]
  }
  if {$top_y == 0} {
    set top_y [expr -($bot_y)]
  }
  if {$bot_y == 0} {
    set bot_y [expr -($top_y)]
  }

  # if all else fails, cheat
  if {$top_y == $bot_y} {
    set top_y -50
    set bot_y 50
  }

  # most icons don't have their pins at the top & bottom edges, so add
  # a fudge factor of 10 in each direction
  set top_y [expr $top_y - 10]
  set bot_y [expr $bot_y + 10]

  # figure out width and height
  set width [expr $right_x - $left_x]
  set height [expr $bot_y - $top_y]

  # build return value
  set icon_dim [list $width $height $left_x $bot_y $right_x $top_y]

  return $icon_dim
}


# This procedure returns the cell height, from the file mmi25.dpc.

proc generators_get_cell_height {cell size} {
  
  # hack for the multiplier
  if {$cell == "MMIG_MUL_42ADD"} {
    return 50 
  }
  if {$cell == "MMIG_MUL_42ADDT"} {
    return 110
  }

  # open the file
  set file "/proj/tech/mmi25/library/dpc/mmi25.dpc"
  if {[catch "open $file r" FILE_ID]} {
    # problem
    puts "Aborting, error while reading file \"$file\": $FILE_ID"
    exit
  }

  set cellname [NAME_$cell -Size $size]

  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == $cellname} {
      close $FILE_ID
      return [lindex $line 1]
    }
  }  

  # warn if the cell wasn't found
  puts "WARNING, cell $cellname not found in mmi25.dpc, assuming height of 10"

  close $FILE_ID
  return 10
}


# This procedure computes the max index and various bitrange formats.

proc generators_compute_bitrange {N} {
  set maxidx [expr $N - 1]
  # bitranges
  if {$N == 1} {
    set max_bitrange [format "\[0\]"]
    set vmax_bitrange ""
  } else {
    set max_bitrange [format "\[%d:0\]" $maxidx]
    set vmax_bitrange $max_bitrange
  }

  return [list $maxidx $max_bitrange $vmax_bitrange]
}


# generators_place_cell
#
# This proc places a cell in the current row if its layout will fit in the bit pitch.
# Otherwise it starts a new row, and places the cell there.
#
# Parameters:
# cell             - name of cell, ex. MMI_NAND2
# size             - drive strength of cell, ex. B
# demorgan         - demorgan property of cell, ex. 0
# x_in             - desired schematic x coordinate of "cell".  this should be a location in 
#                    the row currently being populated.  if generators_place_cell determines that 
#                    there is not enough space in this row for "cell", it will place "cell" 
#                    in a new row, and modify x_in to reflect "cell"'s actual placement.  
#                    otherwise it will place "cell" at x_in.
# curr_h_in        - total (layout) height of the current row.  will be modified to
#                    reflect the total height after placement of "cell".
# limit_h          - maximum total (layout) height of a row
# rswidth_in       - schematic width (x dimension) of the row currently being drawn.
#                    also known as the row spanner width.  will be modified to reflect
#                    the drawn width of this row, after placement of "cell".
# rsx_in           - midpoint (schematic x coordinate) of the row currently being drawn.
#                    also known as the row spanner's x coordinate.  will be modified to
#                    reflect the new midpoint of the row after placement of "cell".
# rsy              - schematic y coordinate of the row spanner.
# cell_width       - width (schematic x dimension) of the "cell" icon.
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - value of row counter, being used by calling function to keep track of rows filled

proc generators_place_cell { cell size demorgan x_in y curr_h_in limit_h rswidth_in rsx_in rsy cell_width last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count

  set ws1 60

  # get the cell height info
  set cell_h [generators_get_cell_height $cell $size]

  # generate the cell
  set cellname [NAME_$cell -Size $size -DeMorgan $demorgan]
  generate $cell $cellname -Size $size -DeMorgan $demorgan

  # place it
  if {(($curr_h + $cell_h) > $limit_h) || ($curr_h == 0)} {
    # won't fit, so start a new row.
    # first drop the row spanner under the previous row, unless there isn't one
    if {$curr_h != 0} {
      set rsname [format "row_spanner%d" [expr int($rswidth/2)]]
      generate row_spanner $rsname -width [expr int($rswidth/2)]
      make $rsname -origin "$rsx $rsy"
      incr row_count

      # set start of new row
      set row_start [expr $row_start + $rswidth + $ws1]
     }

    # set new cell origin
    set last_origin_x [expr $row_start + int($cell_width / 2)]
    set x $last_origin_x

    # place cell
    make $cellname -origin "$last_origin_x $y"

    # adjust curr_h
    set curr_h $cell_h

    # set new row_spanner info
    set rswidth $cell_width
    set rsx $last_origin_x

    return 0

  } else {
    # will fit, place it in this row
    # place cell
    make $cellname -origin "$x $y"

    # adjust curr_h
    set curr_h [expr $curr_h + $cell_h]

    # adjust row_spanner info
    # set new cell origin
    if {$x > $last_origin_x} {
      set last_origin_x $x
      set rswidth [expr $rswidth + $ws1 + $cell_width]
      set rsx [expr $row_start + int($rswidth / 2)]
    }

    return 1
  }
}


# This procedure creates a wire between two pins.
#
# Parameters:
#  {outx outy}    - coordinates of cell1's output pin
#  {inx iny}      - coordinates of cell2's input pin
#  bendx          - x coordinate of wire bend

proc generators_wireup { out in bendx} {

  set outx [lindex $out 0]
  set outy [lindex $out 1]

  set inx [lindex $in 0]
  set iny [lindex $in 1]

  if {$inx < $outx} {
    set foox $inx
    set inx $outx
    set outx $inx
    set fooy $iny
    set iny $outy
    set outy $fooy
  }

  if {$bendx == -1} {
    set bendx [expr $outx + int(($inx - $outx)/2)]
  }

  make_wire $outx $outy $bendx $outy

  if {$outy != $iny} {
    make_wire $bendx $outy $bendx $iny
  }

  make_wire $bendx $iny $inx $iny


  return 1
}
