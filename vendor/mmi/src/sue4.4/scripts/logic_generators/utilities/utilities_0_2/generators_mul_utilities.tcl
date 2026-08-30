# This file contains utility procedures used in the multiplier generator.


# This procedure generates and places a PPG circuit of type 1:  an AND2.
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{in0_x in0_y} {in1_x in1_y} {out_x out_y}}

proc generators_mul_ppg1 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  # get MMI_AND2 info
  setl {and2count and2inpins and2outpins and2inoutpins} [generators_get_pin_info "MMI_AND2"]
  # ins
  setl {and2_in0_x and2_in0_y} [generators_get_pin_xy "in0" $and2inpins]
  setl {and2_in1_x and2_in1_y} [generators_get_pin_xy "in1" $and2inpins]
  # out
  setl {and2_out_x and2_out_y} [generators_get_pin_xy "out" $and2outpins]
  # dimensions
  setl {and2_x and2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_AND2"]
  # place and2
  set ok [generators_place_cell "MMI_AND2" C 0 x $y curr_h $limit_h rswidth rsx $rsy $and2_x last_origin_x row_start row_count]

  # return input and output pin locations
  set in0pin [list [expr $x + $and2_in0_x] [expr $y + $and2_in0_y]]
  set in1pin [list [expr $x + $and2_in1_x] [expr $y + $and2_in1_y]]
  set outpin [list [expr $x + $and2_out_x] [expr $y + $and2_out_y]]
  return [list $in0pin $in1pin $outpin]
}


# This procedure generates and places a PPG circuit of type 2:  an AND3.
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{in0_x in0_y} {in1_x in1_y} {in2_x in2_y} {out_x out_y}}

proc generators_mul_ppg2 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  # get MMI_AND3 info
  setl {and3count and3inpins and3outpins and3inoutpins} [generators_get_pin_info "MMI_AND3"]
  # ins
  setl {and3_in0_x and3_in0_y} [generators_get_pin_xy "in0" $and3inpins]
  setl {and3_in1_x and3_in1_y} [generators_get_pin_xy "in1" $and3inpins]
  setl {and3_in2_x and3_in2_y} [generators_get_pin_xy "in2" $and3inpins]
  # out
  setl {and3_out_x and3_out_y} [generators_get_pin_xy "out" $and3outpins]
  # dimensions
  setl {and3_x and3_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_AND3"]
  # place and3
  set ok [generators_place_cell "MMI_AND3" C 0 x $y curr_h $limit_h rswidth rsx $rsy $and3_x last_origin_x row_start row_count]

  # return input and output pin locations
  set in0pin [list [expr $x + $and3_in0_x] [expr $y + $and3_in0_y]]
  set in1pin [list [expr $x + $and3_in1_x] [expr $y + $and3_in1_y]]
  set in2pin [list [expr $x + $and3_in2_x] [expr $y + $and3_in2_y]]
  set outpin [list [expr $x + $and3_out_x] [expr $y + $and3_out_y]]
  return [list $in0pin $in1pin $in2pin $outpin]
}


# This procedure generates and places a PPG circuit of type 3:  an INOR.
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{in1_x in1_y} {in0_x in0_y} {out_x out_y}}
#  Note that the non-inverted input is returned as the first input pin, and the inverted input
#  is returned as the second input pin (opposite their names on the MMI_INOR2 symbol)

proc generators_mul_ppg3 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  # get MMI_INOR2 info
  setl {inor2count inor2inpins inor2outpins inor2inoutpins} [generators_get_pin_info "MMI_INOR2"]
  # ins
  setl {inor2_in0_x inor2_in0_y} [generators_get_pin_xy "in0" $inor2inpins]
  setl {inor2_in1_x inor2_in1_y} [generators_get_pin_xy "in1" $inor2inpins]
  # out
  setl {inor2_out_x inor2_out_y} [generators_get_pin_xy "out" $inor2outpins]
  # dimensions
  setl {inor2_x inor2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_INOR2"]
  # place inor2
  set ok [generators_place_cell "MMI_INOR2" C 1 x $y curr_h $limit_h rswidth rsx $rsy $inor2_x last_origin_x row_start row_count]

  # return input and output pin locations
  set in0pin [list [expr $x + $inor2_in0_x] [expr $y + $inor2_in0_y]]
  set in1pin [list [expr $x + $inor2_in1_x] [expr $y + $inor2_in1_y]]
  set outpin [list [expr $x + $inor2_out_x] [expr $y + $inor2_out_y]]
  return [list $in1pin $in0pin $outpin]
}


# This procedure generates and places a PPG circuit of type 4:  a buffer.
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{in_x in_y} {out_x out_y}}

proc generators_mul_ppg4 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  # get MMI_BUF info
  setl {bufcount bufinpins bufoutpins bufinoutpins} [generators_get_pin_info "MMI_BUF"]
  # in
  setl {buf_in_x buf_in_y} [generators_get_pin_xy "in" $bufinpins]
  # out
  setl {buf_out_x buf_out_y} [generators_get_pin_xy "out" $bufoutpins]
  # dimensions
  setl {buf_x buf_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_BUF"]
  # place buffer
  set ok [generators_place_cell "MMI_BUF" C 0 x $y curr_h $limit_h rswidth rsx $rsy $buf_x last_origin_x row_start row_count]

  # return input and output pin locations
  set inpin [list [expr $x + $buf_in_x] [expr $y + $buf_in_y]]
  set outpin [list [expr $x + $buf_out_x] [expr $y + $buf_out_y]]
  return [list $inpin $outpin]
}


# This procedure generates and places a PPG circuit of type 5, which implements the equation:
#   out = (A . B . !C) + (A . !B . C)
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{A_x A_y} {B_x B_y} {C_x C_y} {out_x out_y}}

proc generators_mul_ppg5 { x_in y_in curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $y_in y
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  set ws1 60

  # get MMI_INV info
  setl {invcount invinpins invoutpins invinoutpins} [generators_get_pin_info "MMI_INV"]
  # in
  setl {inv_in_x inv_in_y} [generators_get_pin_xy "in" $invinpins]
  # out
  setl {inv_out_x inv_out_y} [generators_get_pin_xy "out" $invoutpins]
  # dimensions
  setl {inv_x inv_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_INV"]

  # place inv on C (lower inv)
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invCinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invCoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # place inv on B (upper inv)
  set yfudge $inv_y
  set y [expr $y - 2* $yfudge]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invBinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invBoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # get MMI_NAND3 info
  setl {nand3count nand3inpins nand3outpins nand3inoutpins} [generators_get_pin_info "MMI_NAND3"]
  # ins
  setl {nand3_in0_x nand3_in0_y} [generators_get_pin_xy "in0" $nand3inpins]
  setl {nand3_in1_x nand3_in1_y} [generators_get_pin_xy "in1" $nand3inpins]
  setl {nand3_in2_x nand3_in2_y} [generators_get_pin_xy "in2" $nand3inpins]
  # out
  setl {nand3_out_x nand3_out_y} [generators_get_pin_xy "out" $nand3outpins]
  # dimensions
  setl {nand3_x nand3_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND3"]

  # place upper NAND3
  set x [expr $x + $inv_x + $ws1]
  set y [expr [lindex $invBoutpin 1] - ($nand3_in1_y - $nand3_in2_y)]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set unand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set unand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set unand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set unand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # place lower NAND3
  set y [expr [lindex $invCoutpin 1] + ($nand3_in1_y - $nand3_in2_y)]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set lnand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set lnand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set lnand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set lnand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # get MMI_NAND2 info
  setl {nand2count nand2inpins nand2outpins nand2inoutpins} [generators_get_pin_info "MMI_NAND2"]
  # ins
  setl {nand2_in0_x nand2_in0_y} [generators_get_pin_xy "in0" $nand2inpins]
  setl {nand2_in1_x nand2_in1_y} [generators_get_pin_xy "in1" $nand2inpins]
  # out
  setl {nand2_out_x nand2_out_y} [generators_get_pin_xy "out" $nand2outpins]
  # dimensions
  setl {nand2_x nand2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND2"]

  # place nand2
  set x [expr $x + $inv_x + $ws1]
  set y [expr [lindex $lnand3outpin 1] - int(([lindex $lnand3outpin 1] - [lindex $unand3outpin 1])/2)]
  set ok [generators_place_cell "MMI_NAND2" C 1 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set nand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set nand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]
  
  # wire upper nand3 to nand2 in0
  set ok [generators_wireup $unand3outpin $nand2in0pin -1]

  # wire lower nand3 to nand2 in1
  set ok [generators_wireup $lnand3outpin $nand2in1pin -1]

  # wire inputs to upper nand3
  # in0
  set bx [lindex $invBinpin 0]
  set by [lindex $invBinpin 1]
  set ok [generators_wireup $invBoutpin $unand3in0pin -1]
  # in1
  set ax [expr $bx - 20]
  set ay [lindex $unand3in1pin 1]
  make_wire [lindex $unand3in1pin 0] $ay $ax $ay
  # in2
  set cx [expr $ax - 20]
  set cy [lindex $unand3in2pin 1]
  make_wire [lindex $unand3in2pin 0] $cy $cx $cy

  # wire inputs to lower nand3
  # in0
  make_wire [lindex $lnand3in0pin 0] [lindex $lnand3in0pin 1] $bx [lindex $lnand3in0pin 1]
  make_wire $bx [lindex $lnand3in0pin 1] $bx $by
  # in1
  make_wire [lindex $lnand3in1pin 0] [lindex $lnand3in1pin 1] $ax [lindex $lnand3in1pin 1]
  make_wire $ax [lindex $lnand3in1pin 1] $ax $ay
  # in2
  set ok [generators_wireup $invCoutpin $lnand3in2pin -1]
  make_wire [lindex $invCinpin 0] [lindex $invCinpin 1] $cx [lindex $invCinpin 1]
  make_wire $cx [lindex $invCinpin 1] $cx $cy
  
  # set y to highest device
  set y [lindex $invBinpin 1]

  # return input and output pin locations
  return [list [list $ax $ay] [list $bx $by] [list $cx $cy] $outpin]
}


# This procedure generates and places a PPG circuit of type 6, which implements the equation:
#   out = A . !(B . C)
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{A_x A_y} {B_x B_y} {C_x C_y} {out_x out_y}}

proc generators_mul_ppg6 { x_in y_in curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $y_in y
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count

  set ws1 60

  # get MMI_NAND2 info
  setl {nand2count nand2inpins nand2outpins nand2inoutpins} [generators_get_pin_info "MMI_NAND2"]
  # ins
  setl {nand2_in0_x nand2_in0_y} [generators_get_pin_xy "in0" $nand2inpins]
  setl {nand2_in1_x nand2_in1_y} [generators_get_pin_xy "in1" $nand2inpins]
  # out
  setl {nand2_out_x nand2_out_y} [generators_get_pin_xy "out" $nand2outpins]
  # dimensions
  setl {nand2_x nand2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND2"]
  # place nand2
  set ok [generators_place_cell "MMI_NAND2" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set nand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set nand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set nand2outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]

  # get MMI_AND2 info
  setl {and2count and2inpins and2outpins and2inoutpins} [generators_get_pin_info "MMI_AND2"]
  # ins
  setl {and2_in0_x and2_in0_y} [generators_get_pin_xy "in0" $and2inpins]
  setl {and2_in1_x and2_in1_y} [generators_get_pin_xy "in1" $and2inpins]
  # out
  setl {and2_out_x and2_out_y} [generators_get_pin_xy "out" $and2outpins]
  # dimensions
  setl {and2_x and2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_AND2"]
  # place and2
  set x [expr $x + $nand2_x + $ws1]
  set y [expr $y - $nand2_y]
  set ok [generators_place_cell "MMI_AND2" C 0 x $y curr_h $limit_h rswidth rsx $rsy $and2_x last_origin_x row_start row_count]
  set and2in0pin [list [expr $x + $and2_in0_x] [expr $y + $and2_in0_y]]
  set and2in1pin [list [expr $x + $and2_in1_x] [expr $y + $and2_in1_y]]
  set and2outpin [list [expr $x + $and2_out_x] [expr $y + $and2_out_y]]

  # hook up output of nand2 to in1 input of and2
  set ok [generators_wireup $nand2outpin $and2in1pin -1]

  # set y to highest device
  set y [lindex $and2outpin 1]

  # return input and output pin locations
  return [list $and2in0pin $nand2in0pin $nand2in1pin $and2outpin]
}



# This procedure generates and places a PPG circuit of type 7, which implements the equation:
#   out = (A . B . D. !C) + (A . !(B . D) . C)
#
# Parameters:
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
# last_origin_x_in - origin (schematic x coordinate) of the rightmost cell
#                    placed in the current row.  will be modified to reflect
#                    the placement of "cell".
# row_start_in     - the leftmost schematic x coordinate of this row.  will be
#                    modified to reflect placement of "cell".
# row_count_in     - used by calling function to keep track of the number of filled rows
#
# Returns:
#  {{A_x A_y} {B_x B_y} {C_x C_y} {D_x D_y} {out_x out_y}}

proc generators_mul_ppg7 { x_in y_in curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $y_in y
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  set ws1 60

  # get MMI_INV info
  setl {invcount invinpins invoutpins invinoutpins} [generators_get_pin_info "MMI_INV"]
  # in
  setl {inv_in_x inv_in_y} [generators_get_pin_xy "in" $invinpins]
  # out
  setl {inv_out_x inv_out_y} [generators_get_pin_xy "out" $invoutpins]
  # dimensions
  setl {inv_x inv_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_INV"]

  # get MMI_NAND2 info
  setl {nand2count nand2inpins nand2outpins nand2inoutpins} [generators_get_pin_info "MMI_NAND2"]
  # ins
  setl {nand2_in0_x nand2_in0_y} [generators_get_pin_xy "in0" $nand2inpins]
  setl {nand2_in1_x nand2_in1_y} [generators_get_pin_xy "in1" $nand2inpins]
  # out
  setl {nand2_out_x nand2_out_y} [generators_get_pin_xy "out" $nand2outpins]
  # dimensions
  setl {nand2_x nand2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND2"]

  # get MMI_NAND3 info
  setl {nand3count nand3inpins nand3outpins nand3inoutpins} [generators_get_pin_info "MMI_NAND3"]
  # ins
  setl {nand3_in0_x nand3_in0_y} [generators_get_pin_xy "in0" $nand3inpins]
  setl {nand3_in1_x nand3_in1_y} [generators_get_pin_xy "in1" $nand3inpins]
  setl {nand3_in2_x nand3_in2_y} [generators_get_pin_xy "in2" $nand3inpins]
  # out
  setl {nand3_out_x nand3_out_y} [generators_get_pin_xy "out" $nand3outpins]
  # dimensions
  setl {nand3_x nand3_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND3"]

  set yfudge $inv_y

  # place nand2
  set y [expr $y - 2 * $yfudge]
  set ok [generators_place_cell "MMI_NAND2" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set fnand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set fnand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set fnand2outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]

  # place inv on !(B . D) (upper inv)
  set x [expr $x + $inv_x + $ws1]
  set ok [generators_place_cell "MMI_INV" B 1 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invBinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invBoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # place inv on C (lower inv)
  set y [expr $y + ($nand3_in2_y - $nand3_in0_y)]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invCinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invCoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # place upper NAND3
  set x [expr $x + $inv_x + $ws1]
  set y [expr $y - ($nand3_in2_y - $nand3_in1_y)]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set unand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set unand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set unand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set unand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # place lower NAND3
  set y [expr $y + $yfudge]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set lnand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set lnand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set lnand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set lnand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # place nand2
  set x [expr $x + $inv_x + $ws1]
  set y [expr [lindex $lnand3outpin 1] - int(([lindex $lnand3outpin 1] - [lindex $unand3outpin 1])/2)]
  set ok [generators_place_cell "MMI_NAND2" C 1 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set nand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set nand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]
  
  # wire upper nand3 to nand2 in0
  set ok [generators_wireup $unand3outpin $nand2in0pin -1]

  # wire lower nand3 to nand2 in1
  set ok [generators_wireup $lnand3outpin $nand2in1pin -1]

  # wire inputs to upper nand3
  # in0
  set bx [expr [lindex $invBinpin 0] - 20]
  set by [lindex $invBinpin 1]
  set ok [generators_wireup $invBoutpin $unand3in0pin -1]
  make_wire [lindex $invBinpin 0] $by $bx $by
  # in1
  set ax [expr $bx - 20]
  set ay [lindex $unand3in1pin 1]
  make_wire [lindex $unand3in1pin 0] $ay $ax $ay
  # in2
  set ok [generators_wireup $invCoutpin $unand3in2pin -1]
  set cx [expr $ax - 20]
  set cy [lindex $invCinpin 1]
  make_wire [lindex $invCinpin 0] $cy $cx $cy

  # wire inputs to lower nand3
  # in0
  make_wire [lindex $lnand3in0pin 0] [lindex $lnand3in0pin 1] $bx [lindex $lnand3in0pin 1]
  make_wire $bx [lindex $lnand3in0pin 1] $bx $by
  # in1
  make_wire [lindex $lnand3in1pin 0] [lindex $lnand3in1pin 1] $ax [lindex $lnand3in1pin 1]
  make_wire $ax [lindex $lnand3in1pin 1] $ax $ay
  set ay [lindex $lnand3in1pin 1]
  # in2
  make_wire [lindex $lnand3in2pin 0] [lindex $lnand3in2pin 1] $cx [lindex $lnand3in2pin 1] 
  make_wire $cx [lindex $lnand3in2pin 1] $cx $cy
  
  # wire output of first nand2
  make_wire [lindex $fnand2outpin 0] [lindex $fnand2outpin 1] $bx $by

  # set y to highest device
  set y [lindex $fnand2outpin 1]

  # return input and output pin locations
  return [list [list $ax $ay] $fnand2in0pin [list $cx $cy] $fnand2in1pin $outpin]
}



# This procedure computes the PPG algorithm.
#
# Parameters:
#  NBITS_A  - number of bits in A operand (multiplier)
#  NBITS_B  - number of bits in B operand (multiplicand)
#  A        - type of A operand (Signed, Unsigned, or Both)
#  B        - type of B operand (Signed, Unsigned, or Both)

proc generators_mul_compute_ppg_alg { NBITS_A NBITS_B A B} {

  global PPGALG
  global PPGA
  global PPGB
  global PPGASIGNED
  global PPGBSIGNED
  global PPGNROWS
  global PPGNCOLS
  global PPGATYPE 
  global PPGBTYPE 

  set PPGATYPE [string toupper $A]
  set PPGBTYPE [string toupper $B]

  set PPGNROWS $NBITS_A
  set PPGNCOLS [expr $NBITS_A + $NBITS_B]

  for {set i 0} {$i < $NBITS_A} {incr i} {
    for {set j 0} {$j < $PPGNCOLS} {incr j} {
      # default values for usage of ASigned, BSigned
      set PPGASIGNED($i,$j) 0
      set PPGBSIGNED($i,$j) 0

      # bits below this partial product's least significant term
      if {$j < $i} {
	if {$i == [expr $NBITS_A - 1]} {
	  # last row 
	  set PPGALG($i,$j) f
	  if {[string toupper $A] == "UNSIGNED"} {
	    set PPGA($i,$j) x
	  } else {
	    set PPGA($i,$j) $i
	  }
	  set PPGB($i,$j) x
	  if {[string toupper $A] == "BOTH"} {
	    set PPGASIGNED($i,$j) 1
	  }
	} else {
	  # in all other rows these bits are 0
	  set PPGALG($i,$j) 0
	  set PPGA($i,$j) x
	  set PPGB($i,$j) x
	}
      }

      # A.B bits 
      if {($j >= $i) && ($j < [expr $i + $NBITS_B])} {
	if {$i == [expr $NBITS_A - 1]} {
	  set PPGALG($i,$j) d
	  if {[string toupper $A] == "BOTH"} {
	    set PPGASIGNED($i,$j) 1
	  }
	} else {
	  set PPGALG($i,$j) b
	}
	set PPGA($i,$j) $i
	set PPGB($i,$j) [expr $j - $i]
      }

      # sign/zero extend bits
      if {$j >= [expr $i + $NBITS_B]} {
	if {$i == [expr $NBITS_A - 1]} {
	  set PPGALG($i,$j) e
	  if {([string toupper $A] == "UNSIGNED") && ([string toupper $B] == "UNSIGNED")} {
	    set PPGA($i,$j) x
	  } else {
	    set PPGA($i,$j) $i
	  }
	  if {[string toupper $A] == "BOTH"} {
	    set PPGASIGNED($i,$j) 1
	  }
	} else {
	  set PPGALG($i,$j) c
	  if {([string toupper $B] == "UNSIGNED")} {
	    set PPGA($i,$j) x
	  } else {
	    set PPGA($i,$j) $i
	  }
	}
	if {[string toupper $B] == "UNSIGNED"} {
	  set PPGB($i,$j) x
	} else {
	  set PPGB($i,$j) [expr $NBITS_B - 1]
	}
	if {[string toupper $B] == "BOTH"} {
	  set PPGBSIGNED($i,$j) 1
	}
      }
    }
  }

  return 1
}



# This procedure prints out the values in the arrays PPGALG, PPGA, PPGB, PPGASIGNED, and PPGBSIGNED.
#

proc generators_mul_dump_ppg {} {

  global PPGALG
  global PPGA
  global PPGB
  global PPGASIGNED
  global PPGBSIGNED
  global PPGNROWS
  global PPGNCOLS

  set tenout ""
  set oneout ""
  set bar ""
  for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
    set tens [expr int($j / 10)]
    set ones [expr $j % 10]
    if {$ones == 0} {
      set tenout [format "%s %s" $tenout $tens]
    } else {
      set tenout [format "%s  " $tenout]
    }
    set oneout [format "%s %s" $oneout $ones]
    set bar [format "%s--" $bar]
  }

  puts ""

  puts [format "Algorithm:"]
  puts $tenout
  puts $oneout
  puts $bar

  for {set i 0} {$i < $PPGNROWS} {incr i} {
    set out ""
    set aout ""
    set bout ""
    for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
      set out [format "%s %s" $out $PPGALG($i,$j)]
    }
    puts $out
  }

  puts ""

  puts [format "A Usage, B Usage:"]
  puts [format "%s      %s" $tenout $tenout]
  puts [format "%s      %s" $oneout $oneout]
  puts [format "%s      %s" $bar $bar]

  for {set i 0} {$i < $PPGNROWS} {incr i} {
    set out ""
    set aout ""
    set bout ""
    for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
      set aout [format "%s %s" $aout $PPGA($i,$j)]
      set bout [format "%s %s" $bout $PPGB($i,$j)]
    }
    puts [format "%s      %s" $aout $bout]
  }

  puts ""

  puts [format "ASigned, BSigned:"]
  puts [format "%s      %s" $tenout $tenout]
  puts [format "%s      %s" $oneout $oneout]
  puts [format "%s      %s" $bar $bar]

  for {set i 0} {$i < $PPGNROWS} {incr i} {
    set asout ""
    set bsout ""
    for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
      set asout [format "%s %s" $asout $PPGASIGNED($i,$j)]
      set bsout [format "%s %s" $bsout $PPGBSIGNED($i,$j)]
    }
    puts [format "%s      %s" $asout $bsout]
  }
}


# This procedure retrieves a bitslice of a global PPG array.
#
# Parameters:
#   ppgarray  - name of ppg array.  legal values:  A, B, ASIGNED, BSIGNED, ALG
#   bit       - bitslice number
#
# Returns:
#   bitslice, from most significant partial product (on left end) to least significant pp (right end)

proc generators_mul_get_ppg_bitslice { ppgarray bit } {

  global PPGALG
  global PPGA
  global PPGB
  global PPGASIGNED
  global PPGBSIGNED
  global PPGNROWS
  global PPGNCOLS

  set ppgarrayname [string toupper $ppgarray]

  if {$bit > $PPGNCOLS} {
    error "ERROR: bit ($bit) > number of columns ($PPGNCOLS)"
  }

  set out ""
  for {set i 0} {$i < $PPGNROWS} {incr i} {
    switch $ppgarrayname {
      A { set out [format "%s %s" $PPGA($i,$bit) $out] }
      B { set out [format "%s %s" $PPGB($i,$bit) $out] }
      ASIGNED { set out [format "%s%s" $PPGASIGNED($i,$bit) $out] }
      BSIGNED { set out [format "%s%s" $PPGBSIGNED($i,$bit) $out] }
      ALG { set out [format "%s%s" $PPGALG($i,$bit) $out] }
      default { error "ERROR: unkown ppg array name ($ppgarray)" }
    }
  }

  return $out
}


# This procedure retrieves a chunk (4 bit segment) of a bitslice of a global PPG array.
#
# Parameters:
#   ppgarray  - name of ppg array.  legal values:  A, B, ASIGNED, BSIGNED, ALG
#   bit       - bitslice number
#   chunk     - list of bit positions to retrieve
#
# Returns:
#   operand bit usage, in the order corresponding to the input bit position order
#

proc generators_mul_get_ppg_chunk { ppgarray bit chunk } {

  global PPGNROWS

  set ppgarrayname [string toupper $ppgarray]

  set bitslice [generators_mul_get_ppg_bitslice $ppgarray $bit]

  set out ""
  foreach bit $chunk {
    if {$bit > [expr $PPGNROWS - 1]} {
      error "ERROR: chunk index ($bit) > number of bits in slice ([expr $PPGNROWS - 1])"
    }
    if {($ppgarrayname == "A") || ($ppgarrayname == "B")} {
      lappend out [lindex $bitslice $bit]
    } else {
      set out [format "%s%s" $out [string index $bitslice $bit]]
    }
  }

  # pad out the bitslice to a multiple of 4
  if {[llength $chunk] < 4} {
    for {set i [llength $chunk]} {$i < 4} {incr i} {
      if {($ppgarrayname == "A") || ($ppgarrayname == "B")} {
	set out [format "x %s" $out]
      } else {
	set out [format "0%s" $out]
      }
    }
  }

  return $out
}


# This procedure creates bitrange expressions from a string of numbers and x's.  x's are removed.  
# Repeated numbers are compressed.  The input can be given in any order.  The output ranges, if 
# there are more than one range, will be in descending order.
#
# Examples:
#   7 6 5 4  => [7:4]
#   7 x 5 4  => [7],[5:4]
#   7 x x 4  => [7],[4]
#
#   x x x 1  => [1]
#   x x 2 1  => [2:1]
#   1 2 x x  => [2:1]
#
#   3 3 3 3  => [3]
#   3 3 3 2  => [3:2]
#   x 3 3 2  => [3:2] 
#
#   x x x x  => x
#
# Returns:
# 1.  number of ranges
# 2.  list of (bits per range, range) pairs

proc generators_mul_get_range { bits } {

  # get rid of x's
  set imax [llength $bits]
  set newbits ""
  for {set i 0} {$i < $imax} {incr i} {
    set bit [lindex $bits $i]
    if {$bit != "x"} {
      lappend newbits $bit
    }
  }

  # done if the input was all x's
  if {$newbits == ""} {
    return [list 0 [list 0 x]]
  }

  # sort the list
  set bits [lsort -integer -decreasing $newbits]

  set nranges 0
  set ranges(0) ""

  for {set i 0} {$i < [llength $bits]} {incr i} {
    set bit [lindex $bits $i]

    if {[llength $ranges($nranges)] == 0} {
      lappend ranges($nranges) $bit
    } else {
      set diff [expr [lindex $ranges($nranges) end] - $bit]
      switch $diff {
	0 {
	  # go on to next bit....
	}
	1 {
	  # append this bit to the current range
	  lappend ranges($nranges) $bit
	}
	default {
	  # start new range
	  incr nranges
	  lappend ranges($nranges) $bit
	}
      }
    }
  }  
  incr nranges

  for {set i 0} {$i < $nranges} {incr i} {
    set range $ranges($i)

    if {[llength $range] == 1} {
      lappend out [list 1 [format "\[%d\]" $range]]
    } else {
      set max [lindex $range 0]
      set min [lindex $range end]
      set length [expr $max - $min + 1]
      lappend out [list $length [format "\[%d:%d\]" $max $min]]
    }
  }

  return [list $nranges $out]
}


# This procedure derives the pin names corresponding to input bitranges (arrays A and B).
#
# Rules:
# - if there is one range:
# -- if it contains only one bit, its name is ""
# -- if it contains more than one bit, its name is the same as the range
# - if there are 2 ranges:
# -- range0 must consist of only one bit position, its name is "msb"
# -- range1 follows the rules given above for the single-range case
#

proc generators_mul_get_pinnames { nranges ranges } {

  if {$nranges == 0} {
    return 0
  }

  if {$nranges == 1} {
    setl {nbits range} [lindex $ranges 0]
    if {$nbits == 1} {
      set retval ""
    } else {
      set retval $range
    }
  } 

  if {$nranges == 2} {
    # range0:  the msb
    set retval "msb"
    # range1:  non-msb
    setl {nbits range} [lindex $ranges 1]
    if {$nbits == 1} {
      lappend retval ""
    } else {
      lappend retval $range
    }
  }

  if {$nranges > 2} {
    return 0
  }

  return $retval
}


# This procedure figures out the name of a signal based on the pinname for the icon placed in this schematic.
#

proc generators_mul_get_uppinname { nabranges abranges arange } {

  if {$nabranges == 1} {
    # there is one continuous range in the current schematic
    setl {nbits_ab abrange} [lindex $abranges 0]

    if {$nbits_ab == 1} {
      return ""
    } else {
      return $arange
    }
  }

  if {$nabranges == 2} {
    # there are 2 ranges in the current schematic.  range0 consists of only the msb.
    setl {nbits_ab abrange} [lindex $abranges 0]
    if {$arange == $abrange} {
      return "msb"
    }

    # range1 is the non-msb bit(s)
    setl {nbits_ab abrange} [lindex $abranges 1]
    if {$nbits_ab == 1} {
      return ""
    } else {
      return $arange
    }
  }
}


# This procedure computes the number of rows of 4:2 adders in the multiplier array.
#

proc generators_mul_compute_rowcount { NBITS_A } {

  set j 1
  for {set i 4} {$i <= $NBITS_A} {set i [expr $i * 2]} {
    incr j
  }
  if {[expr pow(2,$j)] == $NBITS_A} {
    # NBITS_A is a power of 2
    set rowcount [expr $j - 1]
  } else {
    # no it's not
    set rowcount $j
  }

  return $rowcount
}


# This procedure computes the number of 4:2 adders ("boxes") needed in each row of the multiplier array.
#

proc generators_mul_compute_boxcount { NBITS_A addCSA rowcount boxcount_in } {
  
  upvar $boxcount_in boxcount

  # row 0
  set boxcount(0) [expr int($NBITS_A / 4)]
  if {[expr $NBITS_A % 4] != 0} {
    incr boxcount(0)
  }

  # row >= 1
  for {set i 1} {$i < $rowcount} {incr i} {
    set prevbc $boxcount([expr $i - 1])
    set boxcount($i) [expr int($prevbc / 2)]
    if {[expr $prevbc % 2] != 0} {
      incr boxcount($i)
    }
  }

  # add an extra row if an extra CSA is desired
  if {$addCSA} {
    set boxcount($rowcount) 1
  }


  return 1
}