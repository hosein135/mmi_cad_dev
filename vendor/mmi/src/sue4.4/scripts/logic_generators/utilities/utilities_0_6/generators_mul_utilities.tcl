# This file contains utility procedures used in the multiplier generator.
# rev 0.6, 08/08/00

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
  set y [expr [lindex $invCoutpin 1] - ($nand3_in1_y - $nand3_in2_y)]
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
  set bx [expr [lindex $invBinpin 0] - 20]
  set by [lindex $invBinpin 1]
  set ok [generators_wireup $invBoutpin $unand3in0pin -1]
  make_wire $bx $by [lindex $invBinpin 0] $by
  # in1
  set ax [expr $bx - 20]
  set ay [lindex $unand3in1pin 1]
  make_wire [lindex $unand3in1pin 0] $ay $ax $ay
  # in2
  set cx [expr $ax - 20]
  set cy [lindex $unand3in2pin 1]
  make_wire [lindex $unand3in2pin 0] $cy $cx $cy

  # wire inputs to lower nand3
  # in2
  make_wire [lindex $lnand3in2pin 0] [lindex $lnand3in2pin 1] $bx [lindex $lnand3in2pin 1]
  make_wire $bx [lindex $lnand3in2pin 1] $bx $by
  # in1
  make_wire [lindex $lnand3in1pin 0] [lindex $lnand3in1pin 1] $ax [lindex $lnand3in1pin 1]
  make_wire $ax [lindex $lnand3in1pin 1] $ax $ay
  # in0
  set ok [generators_wireup $invCoutpin $lnand3in0pin -1]
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


# This procedure generates and places a PPG circuit of type 8:  a NAND2.
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

proc generators_mul_ppg8 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


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
  set ok [generators_place_cell "MMI_NAND2" C 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]

  # return input and output pin locations
  set in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]
  return [list $in0pin $in1pin $outpin]
}


# This procedure generates and places a PPG circuit of type 9:  an INAND.
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
#  is returned as the second input pin (opposite their names on the MMI_INAND2 symbol)

proc generators_mul_ppg9 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  # get MMI_INAND2 info
  setl {inand2count inand2inpins inand2outpins inand2inoutpins} [generators_get_pin_info "MMI_INAND2"]
  # ins
  setl {inand2_in0_x inand2_in0_y} [generators_get_pin_xy "in0" $inand2inpins]
  setl {inand2_in1_x inand2_in1_y} [generators_get_pin_xy "in1" $inand2inpins]
  # out
  setl {inand2_out_x inand2_out_y} [generators_get_pin_xy "out" $inand2outpins]
  # dimensions
  setl {inand2_x inand2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_INAND2"]
  # place inand2
  set ok [generators_place_cell "MMI_INAND2" C 1 x $y curr_h $limit_h rswidth rsx $rsy $inand2_x last_origin_x row_start row_count]

  # return input and output pin locations
  set in0pin [list [expr $x + $inand2_in0_x] [expr $y + $inand2_in0_y]]
  set in1pin [list [expr $x + $inand2_in1_x] [expr $y + $inand2_in1_y]]
  set outpin [list [expr $x + $inand2_out_x] [expr $y + $inand2_out_y]]
  return [list $in1pin $in0pin $outpin]
}


# This procedure generates and places a PPG circuit of type 10:  an XNOR.
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

proc generators_mul_ppg10 { x_in y curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
  upvar $x_in x
  upvar $curr_h_in curr_h
  upvar $rswidth_in rswidth
  upvar $rsx_in rsx
  upvar $last_origin_x_in last_origin_x
  upvar $row_start_in row_start
  upvar $row_count_in row_count


  # get MMI_XNOR2 info
  setl {xnor2count xnor2inpins xnor2outpins xnor2inoutpins} [generators_get_pin_info "MMI_XNOR2"]
  # ins
  setl {xnor2_in0_x xnor2_in0_y} [generators_get_pin_xy "in0" $xnor2inpins]
  setl {xnor2_in1_x xnor2_in1_y} [generators_get_pin_xy "in1" $xnor2inpins]
  # out
  setl {xnor2_out_x xnor2_out_y} [generators_get_pin_xy "out" $xnor2outpins]
  # dimensions
  setl {xnor2_x xnor2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_XNOR2"]
  # place xnor2
  set ok [generators_place_cell "MMI_XNOR2" C 0 x $y curr_h $limit_h rswidth rsx $rsy $xnor2_x last_origin_x row_start row_count]

  # return input and output pin locations
  set in0pin [list [expr $x + $xnor2_in0_x] [expr $y + $xnor2_in0_y]]
  set in1pin [list [expr $x + $xnor2_in1_x] [expr $y + $xnor2_in1_y]]
  set outpin [list [expr $x + $xnor2_out_x] [expr $y + $xnor2_out_y]]
  return [list $in0pin $in1pin $outpin]
}


# This procedure generates and places a PPG circuit of type 11, which implements the equation:
#   out = (A . !C) + (!A . C) + (B . C)
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

proc generators_mul_ppg11 { x_in y_in curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
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

  # place inv on A (upper inv)
  set yfudge $inv_y
  set y [expr $y - $yfudge]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invAinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invAoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # get MMI_NAND2 info
  setl {nand2count nand2inpins nand2outpins nand2inoutpins} [generators_get_pin_info "MMI_NAND2"]
  # ins
  setl {nand2_in0_x nand2_in0_y} [generators_get_pin_xy "in0" $nand2inpins]
  setl {nand2_in1_x nand2_in1_y} [generators_get_pin_xy "in1" $nand2inpins]
  # out
  setl {nand2_out_x nand2_out_y} [generators_get_pin_xy "out" $nand2outpins]
  # dimensions
  setl {nand2_x nand2_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND2"]

  # place upper NAND2
  set x [expr $x + $inv_x + $ws1]
  set y [expr [lindex $invAoutpin 1] - ($nand2_in0_y - $inv_out_y)]
  set ok [generators_place_cell "MMI_NAND2" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set unand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set unand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set unand2outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]

  # place middle NAND2
  set y [expr [lindex $invCoutpin 1] - ($nand2_in0_y - $inv_out_y)]
  set ok [generators_place_cell "MMI_NAND2" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set mnand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set mnand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set mnand2outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]

  # place lower NAND2
  set y [expr $y + $yfudge]
  set ok [generators_place_cell "MMI_NAND2" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set lnand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set lnand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set lnand2outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]

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

  # place final NAND3
  set x [expr $x + $inv_x + $ws1]
  set y [lindex $mnand2outpin 1]
  set ok [generators_place_cell "MMI_NAND3" C 1 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set nand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set nand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set nand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]
  
  # wire upper nand2 to nand3 in0
  set ok [generators_wireup $unand2outpin $nand3in0pin -1]

  # wire middle nand2 to nand3 in1
  set ok [generators_wireup $mnand2outpin $nand3in1pin -1]

  # wire lower nand2 to nand3 in2
  set ok [generators_wireup $lnand2outpin $nand3in2pin -1]

  # wire inputs to upper nand2 (!A . C)
  # in0
  set ax [expr [lindex $invAinpin 0] - 20]
  set ay [lindex $invAinpin 1]
  set ok [generators_wireup $invAoutpin $unand2in0pin -1]
  make_wire $ax $ay [lindex $invAinpin 0] $ay
  # in1
  set cx [expr $ax - 20]
  set cy [lindex $unand2in1pin 1]
  make_wire [lindex $unand2in1pin 0] $cy $cx $cy

  # wire inputs to middle nand2 (A . !C)
  # in0
  set ok [generators_wireup $invCoutpin $mnand2in0pin -1]
  make_wire $cx [lindex $invCinpin 1] [lindex $invCinpin 0] [lindex $invCinpin 1] 
  make_wire $cx $cy $cx [lindex $invCinpin 1]
  # in1
  make_wire $ax $ay $ax [lindex $mnand2in1pin 1]
  make_wire $ax [lindex $mnand2in1pin 1] [lindex $mnand2in1pin 0] [lindex $mnand2in1pin 1]

  # wire inputs to lower nand2 (B . C)
  # in0
  set bx [expr $cx - 20]
  set by [lindex $lnand2in0pin 1]
  make_wire [lindex $lnand2in0pin 0] $by $bx $by
  # in1
  make_wire [lindex $lnand2in1pin 0] [lindex $lnand2in1pin 1] $cx [lindex $lnand2in1pin 1]
  make_wire $cx [lindex $lnand2in1pin 1] $cx [lindex $invCinpin 1]
  
  # set y to highest device
  set y [lindex $invAinpin 1]

  # return input and output pin locations
  return [list [list $ax $ay] [list $bx $by] [list $cx $cy] $outpin]
}


# This procedure generates and places a PPG circuit of type 12, which implements the equation:
#   out = (!B . C . !D) + (A . !C . D) + (B . C . D) + (!A . C)
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

proc generators_mul_ppg12 { x_in y_in curr_h_in limit_h rswidth_in rsx_in rsy last_origin_x_in row_start_in row_count_in} {
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

  # get MMI_NAND4 info
  setl {nand4count nand4inpins nand4outpins nand4inoutpins} [generators_get_pin_info "MMI_NAND4"]
  # ins
  setl {nand4_in0_x nand4_in0_y} [generators_get_pin_xy "in0" $nand4inpins]
  setl {nand4_in1_x nand4_in1_y} [generators_get_pin_xy "in1" $nand4inpins]
  setl {nand4_in2_x nand4_in2_y} [generators_get_pin_xy "in2" $nand4inpins]
  setl {nand4_in3_x nand4_in3_y} [generators_get_pin_xy "in3" $nand4inpins]
  # out
  setl {nand4_out_x nand4_out_y} [generators_get_pin_xy "out" $nand4outpins]
  # dimensions
  setl {nand4_x nand4_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_NAND4"]

  # get MMI_INV info
  setl {invcount invinpins invoutpins invinoutpins} [generators_get_pin_info "MMI_INV"]
  # in
  setl {inv_in_x inv_in_y} [generators_get_pin_xy "in" $invinpins]
  # out
  setl {inv_out_x inv_out_y} [generators_get_pin_xy "out" $invoutpins]
  # dimensions
  setl {inv_x inv_y junk1 junk2 junk3 junk4} [generators_get_icon_size "MMI_INV"]
  set yfudge $inv_y

  # place inv on A (bottom inv)
  set y [expr $y - $yfudge]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invAinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invAoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]
  
  # place inv on C (next inv up)
  set y [expr $y - $yfudge]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invCinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invCoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # place inv on D (next inv up)
  set y [expr $y - $yfudge]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invDinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invDoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # place inv on B (top inv)
  set y [expr $y - ($nand3_in2_y - $nand3_in1_y)]
  set ok [generators_place_cell "MMI_INV" B 0 x $y curr_h $limit_h rswidth rsx $rsy $inv_x last_origin_x row_start row_count]
  set invBinpin [list [expr $x + $inv_in_x] [expr $y + $inv_in_y]]
  set invBoutpin [list [expr $x + $inv_out_x] [expr $y + $inv_out_y]]

  # place upper NAND3
  set x [expr $x + $inv_x + $ws1]
  set y [lindex $invDoutpin 1]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set unand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set unand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set unand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set unand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # place second NAND3
  set y [expr [lindex $invCoutpin 1] - ($nand3_in1_y - $nand3_in2_y)]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set mnand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set mnand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set mnand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set mnand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # place NAND2
  set y [expr [lindex $invAoutpin 1] - ($nand3_in1_y - $nand3_in2_y)]
  set ok [generators_place_cell "MMI_NAND2" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand2_x last_origin_x row_start row_count]
  set mnand2in0pin [list [expr $x + $nand2_in0_x] [expr $y + $nand2_in0_y]]
  set mnand2in1pin [list [expr $x + $nand2_in1_x] [expr $y + $nand2_in1_y]]
  set mnand2outpin [list [expr $x + $nand2_out_x] [expr $y + $nand2_out_y]]

  # place lower NAND3
  set y [expr $y + $yfudge]
  set ok [generators_place_cell "MMI_NAND3" B 0 x $y curr_h $limit_h rswidth rsx $rsy $nand3_x last_origin_x row_start row_count]
  set lnand3in0pin [list [expr $x + $nand3_in0_x] [expr $y + $nand3_in0_y]]
  set lnand3in1pin [list [expr $x + $nand3_in1_x] [expr $y + $nand3_in1_y]]
  set lnand3in2pin [list [expr $x + $nand3_in2_x] [expr $y + $nand3_in2_y]]
  set lnand3outpin [list [expr $x + $nand3_out_x] [expr $y + $nand3_out_y]]

  # place final NAND4
  set x [expr $x + $inv_x + $ws1]
  set y [expr int(([lindex $mnand2outpin 1] - [lindex $mnand3outpin 1]) / 2) + [lindex $mnand3outpin 1]]
  set ok [generators_place_cell "MMI_NAND4" C 1 x $y curr_h $limit_h rswidth rsx $rsy $nand4_x last_origin_x row_start row_count]
  set nand4in0pin [list [expr $x + $nand4_in0_x] [expr $y + $nand4_in0_y]]
  set nand4in1pin [list [expr $x + $nand4_in1_x] [expr $y + $nand4_in1_y]]
  set nand4in2pin [list [expr $x + $nand4_in2_x] [expr $y + $nand4_in2_y]]
  set nand4in3pin [list [expr $x + $nand4_in3_x] [expr $y + $nand4_in3_y]]
  set outpin [list [expr $x + $nand4_out_x] [expr $y + $nand4_out_y]]
  
  set bend1_x [expr [lindex $unand3outpin 0] - 10 + int(([lindex $nand4in0pin 0] - [lindex $unand3outpin 0])/2)]
  set bend2_x [expr $bend1_x + 20]

  # wire upper nand3 to final nand4 in0
  set ok [generators_wireup $unand3outpin $nand4in0pin $bend2_x]

  # wire middle nand3 to final nand4 in1
  set ok [generators_wireup $mnand3outpin $nand4in1pin $bend1_x]

  # wire middle nand2 to final nand4 in2
  set ok [generators_wireup $mnand2outpin $nand4in2pin $bend1_x]

  # wire lower nand3 to final nand4 in3
  set ok [generators_wireup $lnand3outpin $nand4in3pin -1]

  # wire inputs to upper nand3 (!B . !D . C)
  # in0
  set bx [expr [lindex $invBinpin 0] - 20]
  set by [lindex $invBinpin 1]
  set ok [generators_wireup $invBoutpin $unand3in0pin -1]
  make_wire [lindex $invBinpin 0] $by $bx $by
  # in2
  set dx [expr $bx - 20]
  set dy [lindex $invDinpin 1]
  set ok [generators_wireup $invDoutpin $unand3in1pin -1]
  make_wire [lindex $invDinpin 0] $dy $dx $dy
  # in2
  set cx [expr $dx - 20]
  set cy [lindex $unand3in2pin 1]
  make_wire [lindex $unand3in2pin 0] $cy $cx $cy

  # wire inputs to middle nand3 (!C . A . D)
  # in0
  set ok [generators_wireup $invCoutpin $mnand3in0pin -1]
  make_wire $cx [lindex $invCinpin 1] [lindex $invCinpin 0] [lindex $invCinpin 1]
  make_wire $cx [lindex $invCinpin 1] $cx $cy
  set cy [lindex $invCinpin 1]
  # in1
  set ax [expr $cx - 20]
  set ay [lindex $mnand3in1pin 1]
  make_wire [lindex $mnand3in1pin 0] $ay $ax $ay
  # in2
  make_wire $dx [lindex $mnand3in2pin 1] [lindex $mnand3in2pin 0] [lindex $mnand3in2pin 1]
  make_wire $dx [lindex $mnand3in2pin 1] $dx $dy
  set dy [lindex $mnand3in2pin 1]

  # wire inputs to middle nand2 (!A . C)
  # in0
  set ok [generators_wireup $invAoutpin $mnand2in0pin -1]
  make_wire $ax $ay $ax [lindex $invAinpin 1] 
  make_wire $ax [lindex $invAinpin 1] [lindex $invAinpin 0] [lindex $invAinpin 1]
  # in1
  make_wire $cx $cy $cx [lindex $mnand2in1pin 1]
  make_wire $cx [lindex $mnand2in1pin 1] [lindex $mnand2in1pin 0] [lindex $mnand2in1pin 1]
  set cy [lindex $mnand2in1pin 1]

  # wire inputs to lower nand3 (B . C . D)
  # in0
  make_wire $bx $by $bx [lindex $lnand3in0pin 1]
  make_wire $bx [lindex $lnand3in0pin 1] [lindex $lnand3in0pin 0] [lindex $lnand3in0pin 1]
  # in1
  make_wire $cx $cy $cx [lindex $lnand3in1pin 1]
  make_wire $cx [lindex $lnand3in1pin 1] [lindex $lnand3in1pin 0] [lindex $lnand3in1pin 1]
  # in2
  make_wire $dx $dy $dx [lindex $lnand3in2pin 1]
  make_wire $dx [lindex $lnand3in2pin 1] [lindex $lnand3in2pin 0] [lindex $lnand3in2pin 1]

  # set y to highest device
  set y [lindex $invBinpin 1]

  # return input and output pin locations
  return [list [list $ax $ay] [list $bx $by] [list $cx $cy] [list $dx $dy] $outpin]
}



# This procedure computes the PPG algorithm.
#
# Parameters:
#  NBITS_A  - number of bits in A operand (multiplier)
#  NBITS_B  - number of bits in B operand (multiplicand)
#  A        - type of A operand (Signed, Unsigned, or Both)
#  B        - type of B operand (Signed, Unsigned, or Both)

proc generators_mul_compute_ppg_alg { NBITS_A NBITS_B A B Algorithm Optimize } {

  set ext1 [generators_mul_ppg_name1 $NBITS_A $NBITS_B $A $B $Optimize $Algorithm]

  upvar #0 PPGALG$ext1 PPGALG
  upvar #0 PPGA$ext1 PPGA
  upvar #0 PPGB$ext1 PPGB
  upvar #0 PPGB2$ext1 PPGB2
  upvar #0 PPGB3$ext1 PPGB3
  upvar #0 PPGB4$ext1 PPGB4
  upvar #0 PPGASIGNED$ext1 PPGASIGNED
  upvar #0 PPGBSIGNED$ext1 PPGBSIGNED
  upvar #0 PPGNROWS$ext1 PPGNROWS
  upvar #0 PPGNCOLS$ext1 PPGNCOLS

  set PPGNROWS [generators_mul_compute_npps $NBITS_A $A $Algorithm]

  set PPGNCOLS [expr $NBITS_A + $NBITS_B]

  if {[string toupper $Algorithm] == "SIMPLE"} {
    for {set i 0} {$i < $NBITS_A} {incr i} {
      for {set j 0} {$j < $PPGNCOLS} {incr j} {
	# default values for usage of ASigned, BSigned
	set PPGASIGNED($i,$j) 0
	set PPGBSIGNED($i,$j) 0
	
	# bits below this partial product's least significant term
	if {$j < $i} {
	  if {$i == [expr $NBITS_A - 1]} {
	    # last row 
	    if {[string toupper $A] == "UNSIGNED"} {
	      set PPGALG($i,$j) 0
	      set PPGA($i,$j) x
	    } else {
	      set PPGALG($i,$j) f
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
	  if {([string toupper $Optimize] == "MSB") || ([string toupper $Optimize] == "BOTH")} {
	    # MSB optimization

	    # most significant PP
	    if {$i == [expr $NBITS_A - 1]} {
	      set PPGALG($i,$j) i
	      if {(([string toupper $A] == "UNSIGNED") && ([string toupper $B] == "UNSIGNED")) ||
		  (([string toupper $A] == "BOTH") && ([string toupper $B] == "SIGNED"))} {
		set PPGA($i,$j) x
	      } else {
		set PPGA($i,$j) $i
	      }
	      if {[string toupper $A] == "BOTH"} {
		set PPGASIGNED($i,$j) 1
	      }
	      if {[string toupper $B] == "UNSIGNED"} {
		set PPGB($i,$j) x
	      } else {
		set PPGB($i,$j) [expr $NBITS_B - 1]
	      }
	      if {[string toupper $B] == "BOTH"} {
		set PPGBSIGNED($i,$j) 1
	      }
	    } else {

	      # PP0, first sign extend bit
	      if {($i == 0) && ($j == $NBITS_B)} {
		set PPGALG($i,$j) c
		if {[string toupper $B] == "UNSIGNED"} {
		  set PPGA($i,$j) x
		  set PPGB($i,$j) x
		} else {
		  set PPGA($i,$j) $i
		  set PPGB($i,$j) [expr $NBITS_B - 1]
		}
		if {[string toupper $B] == "BOTH"} {
		  set PPGBSIGNED($i,$j) 1
		}
	      }
	      
	      # PP0, second sign extend bit
	      if {($i == 0) && ($j == [expr $NBITS_B + 1])} {
		set PPGALG($i,$j) g
		if {[string toupper $B] == "UNSIGNED"} {
		  set PPGA($i,$j) x
		  set PPGB($i,$j) x
		} else {
		  set PPGA($i,$j) $i
		  set PPGB($i,$j) [expr $NBITS_B - 1]
		}
		if {[string toupper $B] == "BOTH"} {
		  set PPGBSIGNED($i,$j) 1
		}
	      }
	    
	      # PP0, 0 bits
	      if {($i == 0) && ($j > [expr $NBITS_B + 1])} {
		set PPGALG($i,$j) z
		set PPGA($i,$j) x
		set PPGB($i,$j) x
	      }

	      # PP>0, sign extend bit
	      if {($i != 0) && ($j == [expr $i + $NBITS_B])} {
		set PPGALG($i,$j) g
		if {[string toupper $B] == "UNSIGNED"} {
		  set PPGA($i,$j) x
		  set PPGB($i,$j) x
		} else {
		  set PPGA($i,$j) $i
		  set PPGB($i,$j) [expr $NBITS_B - 1]
		}
		if {[string toupper $B] == "BOTH"} {
		  set PPGBSIGNED($i,$j) 1
		}
	      }

	      # PP>0, 0 bits
	      if {($i != 0) && ($j > [expr $i + $NBITS_B])} {
		set PPGALG($i,$j) z
		set PPGA($i,$j) x
		set PPGB($i,$j) x
	      }
	    }
	  } else {
	    # no MSB optimization
	    if {$i == [expr $NBITS_A - 1]} {
	      # most significant PP
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
	      # not most significant PP
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
    }
  } else {
    # Booth Algorithm

    if {[string toupper $Algorithm] == "BOOTHRADIX4"} {
      set bitmultiple 2
    }
    if {[string toupper $Algorithm] == "BOOTHRADIX8"} {
      set bitmultiple 3
    }
    # this is the length of the non-zero, non-sign-extend part of the partial product
    set pplen [expr $NBITS_B + $bitmultiple - 1]

    for {set i 0} {$i < $PPGNROWS} {incr i} {
      for {set j 0} {$j < $PPGNCOLS} {incr j} {
	set ishift [expr $i * $bitmultiple]

	set bmsb [expr $ishift + $NBITS_B]
	set msb [expr $ishift + $pplen]

	# default values
	set PPGB($i,$j) x
	set PPGB2($i,$j) x
	set PPGB3($i,$j) x
	set PPGB4($i,$j) x

	# first we compute the algorithm
	# bits below the lsb are 0
	if {$j < $ishift} {
	  set PPGALG($i,$j) 0
	}
	
	# regular bits
	if {($j >= $ishift) && ($j < $msb)} {
	  set PPGALG($i,$j) b
	}

	# bits above the msb may be zero or sign extended
	if {$j >= $msb} {
	  if {([string toupper $Optimize] == "MSB") || ([string toupper $Optimize] == "BOTH")} {
	    # MSB optimization
	    if {($i == 0)} {
	      if {($j >= $msb) && ($j < [expr $msb + $bitmultiple])} {
		set PPGALG($i,$j) h
	      }
	      if {$j == [expr $msb + $bitmultiple]} {
		set PPGALG($i,$j) g
	      }
	      if {$j > [expr $msb + $bitmultiple]} {
		set PPGALG($i,$j) z
	      }
	    } else {
	      # i > 0
	      if {$j == $msb} {
		set PPGALG($i,$j) g
	      }
	      if {($j > $msb) && ($j < [expr $msb + $bitmultiple])} {
		set PPGALG($i,$j) 1
	      }
	      if {$j >= [expr $msb + $bitmultiple]} {
		set PPGALG($i,$j) z
	      }
	    }
	  } else {
	    if {[string toupper $B] == "UNSIGNED"} {
	      set PPGALG($i,$j) z
	    } else {
	      set PPGALG($i,$j) c
	    }
	  }
	}

	set algbit $PPGALG($i,$j)

	# now we compute the B usage vectors
	# B
	if {($j >= $ishift) && ($j < $bmsb)} {
	  set PPGB($i,$j) [expr $j - $ishift]
	}
	if {$j >= $bmsb} {
	  if {[string toupper $B] == "UNSIGNED"} {
	    set PPGB($i,$j) x
	  } else {
	    if {($algbit == "g") || ($algbit == "h") || ($algbit == "c") || ($algbit == "b")} {
	      set PPGB($i,$j) [expr $NBITS_B - 1]
	    } else {
	      set PPGB($i,$j) x
	    }
	  }
	}

	# B2 = 2 * B vector
	if {($j >= [expr $ishift + 1]) && ($j < [expr $bmsb + 1])} {
	  set PPGB2($i,$j) [expr $j - ($ishift + 1)]
	}
	if {$j >= [expr $bmsb + 1]} {
	  if {[string toupper $B] == "UNSIGNED"} {
	    set PPGB2($i,$j) x
	  } else {
	    if {($algbit == "g") || ($algbit == "h") || ($algbit == "c") || ($algbit == "b")} {
	      set PPGB2($i,$j) [expr $NBITS_B - 1]
	    } else {
	      set PPGB2($i,$j) x
	    }
	  }
	}

	# B3 = 3 * B vector
	if {($j >= $ishift) && ($j < $msb)} {
	  set PPGB3($i,$j) [expr $j - $ishift]
	}
	if {$j >= $msb} {
	  if {[string toupper $B] == "UNSIGNED"} {
	    set PPGB3($i,$j) x
	  } else {
	    if {($algbit == "g") || ($algbit == "h") || ($algbit == "c") || ($algbit == "b")} {
	      set PPGB3($i,$j) [expr $pplen - 1]
	    } else {
	      set PPGB3($i,$j) x
	    }
	  }
	}

	# B4 = 4 * B vector
	if {($j >= [expr $ishift + 2]) && ($j < [expr $bmsb + 2])} {
	  set PPGB4($i,$j) [expr $j - ($ishift + 2)]
	}
	if {$j >= [expr $bmsb + 2]} {
	  if {[string toupper $B] == "UNSIGNED"} {
	    set PPGB4($i,$j) x
	  } else {
	    if {($algbit == "g") || ($algbit == "h") || ($algbit == "c") || ($algbit == "b")} {
	      set PPGB4($i,$j) [expr $NBITS_B - 1]
	    } else {
	      set PPGB4($i,$j) x
	    }
	  }
	}

      }
    }
  }

  return $ext1
}



# This procedure prints out the values in the arrays PPGALG, PPGA, PPGB, PPGASIGNED, and PPGBSIGNED.
#

proc generators_mul_dump_ppg { Algorithm ext1 } {

  upvar #0 PPGALG$ext1 PPGALG
  upvar #0 PPGA$ext1 PPGA
  upvar #0 PPGB$ext1 PPGB
  upvar #0 PPGB2$ext1 PPGB2
  upvar #0 PPGB3$ext1 PPGB3
  upvar #0 PPGB4$ext1 PPGB4
  upvar #0 PPGASIGNED$ext1 PPGASIGNED
  upvar #0 PPGBSIGNED$ext1 PPGBSIGNED
  upvar #0 PPGNROWS$ext1 PPGNROWS
  upvar #0 PPGNCOLS$ext1 PPGNCOLS

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

  puts [format "Algorithm: %s" $Algorithm]
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

  if {[string toupper $Algorithm] == "SIMPLE"} {
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

  if {[string toupper $Algorithm] == "BOOTHRADIX4"} {
    puts [format "B Usage, B2 Usage:"]
    puts [format "%s      %s" $tenout $tenout]
    puts [format "%s      %s" $oneout $oneout]
    puts [format "%s      %s" $bar $bar]
    
    for {set i 0} {$i < $PPGNROWS} {incr i} {
      set out ""
      set bout ""
      set b2out ""
      for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
	set bout [format "%s %s" $bout $PPGB($i,$j)]
	set b2out [format "%s %s" $b2out $PPGB2($i,$j)]
      }
      puts [format "%s      %s" $bout $b2out]
    }
    
    puts ""
  }


  if {[string toupper $Algorithm] == "BOOTHRADIX8"} {
    puts [format "B Usage, B2 Usage:"]
    puts [format "%s      %s" $tenout $tenout]
    puts [format "%s      %s" $oneout $oneout]
    puts [format "%s      %s" $bar $bar]
    
    for {set i 0} {$i < $PPGNROWS} {incr i} {
      set out ""
      set bout ""
      set b2out ""
      for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
	set bout [format "%s %s" $bout $PPGB($i,$j)]
	set b2out [format "%s %s" $b2out $PPGB2($i,$j)]
      }
      puts [format "%s      %s" $bout $b2out]
    }
    
    puts ""
    puts [format "B3 Usage, B4 Usage:"]
    puts [format "%s      %s" $tenout $tenout]
    puts [format "%s      %s" $oneout $oneout]
    puts [format "%s      %s" $bar $bar]
    
    for {set i 0} {$i < $PPGNROWS} {incr i} {
      set out ""
      set b3out ""
      set b4out ""
      for {set j [expr $PPGNCOLS - 1]} {$j >= 0} {set j [expr $j - 1]} {
	set b3out [format "%s %s" $b3out $PPGB3($i,$j)]
	set b4out [format "%s %s" $b4out $PPGB4($i,$j)]
      }
      puts [format "%s      %s" $b3out $b4out]
    }
    
    puts ""
  }

  return 1
}


# This procedure retrieves a bitslice of a global PPG array.
#
# Parameters:
#   ppgarray  - name of ppg array.  legal values:  A, B, ASIGNED, BSIGNED, ALG
#   bit       - bitslice number
#
# Returns:
#   bitslice, from most significant partial product (on left end) to least significant pp (right end)

proc generators_mul_get_ppg_bitslice { ppgarray ext1 bit } {

  upvar #0 PPGALG$ext1 PPGALG
  upvar #0 PPGA$ext1 PPGA
  upvar #0 PPGB$ext1 PPGB
  upvar #0 PPGB2$ext1 PPGB2
  upvar #0 PPGB3$ext1 PPGB3
  upvar #0 PPGB4$ext1 PPGB4
  upvar #0 PPGASIGNED$ext1 PPGASIGNED
  upvar #0 PPGBSIGNED$ext1 PPGBSIGNED
  upvar #0 PPGNROWS$ext1 PPGNROWS
  upvar #0 PPGNCOLS$ext1 PPGNCOLS

  set ppgarrayname [string toupper $ppgarray]

  if {$bit > $PPGNCOLS} {
    error "ERROR: bit ($bit) > number of columns ($PPGNCOLS)"
  }

  set out ""
  for {set i 0} {$i < $PPGNROWS} {incr i} {
    switch $ppgarrayname {
      A { set out [format "%s %s" $out $PPGA($i,$bit)] }
      B { set out [format "%s %s" $out $PPGB($i,$bit)] }
      B2 { set out [format "%s %s" $out $PPGB2($i,$bit)] }
      B3 { set out [format "%s %s" $out $PPGB3($i,$bit)] }
      B4 { set out [format "%s %s" $out $PPGB4($i,$bit)] }
      ASIGNED { set out [format "%s%s" $out $PPGASIGNED($i,$bit)] }
      BSIGNED { set out [format "%s%s" $out $PPGBSIGNED($i,$bit)] }
      ALG { set out [format "%s%s" $out $PPGALG($i,$bit)] }
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

proc generators_mul_get_ppg_chunk { ppgarray ext1 bit chunk } {

  upvar #0 PPGNROWS$ext1 PPGNROWS

  set ppgarrayname [string toupper $ppgarray]

  set bitslice [generators_mul_get_ppg_bitslice $ppgarray $ext1 $bit]

  set out ""
  for {set i 0} {$i < [llength $chunk]} {incr i} {
    set bit [lindex $chunk $i]
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
#  if {[llength $chunk] < 4} {
#    for {set i [llength $chunk]} {$i < 4} {incr i} {
#      if {($ppgarrayname == "A") || ($ppgarrayname == "B")} {
#	set out [format "x %s" $out]
#      } else {
#	set out [format "0%s" $out]
#      }
#    }
#  }

  return $out
}


# This procedure figures out the bitrange of a single partial product.  Bits which are '0'
# in the Algorithm are removed.  It is assumed that '0' bits can only be present on the
# lower end of the range.
#

proc generators_mul_get_pprange { ext1 pp zeroopt } {

  upvar #0 PPGALG$ext1 PPGALG
  upvar #0 PPGNCOLS$ext1 PPGNCOLS


  set msb [expr $PPGNCOLS - 1]

  # find last non-zero lsb
  if {$zeroopt} {
    set lsb $msb
    for {set i $msb} {$i >= 0} {set i [expr $i - 1]} {
      if {$PPGALG($pp,$i) != 0} {
	set lsb $i
      } else {
	break
      }
    }
  } else {
    set lsb 0
  }

  set rval [format "\[%d:%d\]" $msb $lsb]

  return $rval
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

proc generators_mul_compute_rowcount { NPPs } {

  set j 1
  for {set i 4} {$i <= $NPPs} {set i [expr $i * 2]} {
    incr j
  }
  if {[expr pow(2,$j)] == $NPPs} {
    # NPPs is a power of 2
    set rowcount [expr $j - 1]
  } else {
    # no it's not
    set rowcount $j
  }

  if {$rowcount == 0} {
    set rowcount 1
  }

  return $rowcount
}


# This procedure computes the number of 4:2 adders ("boxes") needed in each row of the multiplier array.
#

proc generators_mul_compute_boxcount { NPPs bit zeroopt rowcount_in boxcount_in ext1 } {
  
  upvar $rowcount_in rowcount
  upvar $boxcount_in boxcount

  set zerocount 0

  if {$zeroopt} {
    set alg [generators_mul_get_ppg_bitslice "ALG" $ext1 $bit]
    for {set i 0} {$i < [string length $alg]} {incr i} {
      if {[string index $alg $i] == 0} {
	incr zerocount
      }
    }
  }

  set nbits [expr $NPPs - $zerocount]

  set rowcount [generators_mul_compute_rowcount $nbits]

  # row 0
  set boxcount(0) [expr int($nbits / 4)]
  if {[expr $nbits % 4] != 0} {
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

  return $nbits
}


# This procedure computes the number of Cin and CarryIn bits for a bitslice of the multiplier array.
#

proc generators_mul_compute_ccount { NPPs addCSA c_count_in carry_count_in } {
  
  upvar $c_count_in c_count
  upvar $carry_count_in carry_count

  set rowcount [generators_mul_compute_rowcount $NPPs]

  # row 0
  set boxcount(0) [expr int($NPPs / 4)]
  if {[expr $NPPs % 4] != 0} {
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

  # add an extra row
  if {$addCSA} {
    set boxcount($rowcount) 1
    incr rowcount
  }

  # total box count
  set totboxcount 0
  for {set i 0} {$i < $rowcount} {incr i} {
    set totboxcount [expr $totboxcount + $boxcount($i)]
  }

  set c_count $totboxcount
  set carry_count [expr $c_count - 1]

  return 1
}


# This procedure computes the number of partial products required to implement the algorithm.
#

proc generators_mul_compute_npps { NBITS_A A Algorithm } {
  # For simple ppg:  there is one partial product per multiplier bit
  if {[string toupper $Algorithm] == "SIMPLE"} {
    return $NBITS_A
  }

  if {[string toupper $Algorithm] == "BOOTHRADIX4"} {
    set bitmultiple 2
  }
  if {[string toupper $Algorithm] == "BOOTHRADIX8"} {
    set bitmultiple 3
  }

  # For Booth multiplication:  if A=SIGNED and NBITS_A is evenly divisible by the bitmultiple,
  # there will be (NBITS_A/bitmultiple) partial products.  all other cases require one additional partial product.
  if {([string toupper $A] == "SIGNED") && (($NBITS_A % $bitmultiple) == 0)} {
    set npps [expr $NBITS_A / $bitmultiple]
  } else {
    set npps [expr ($NBITS_A / $bitmultiple) + 1]
  }

  return $npps
}


# This procedure computes the uniquifying name extension for these global PPG variables:
#   - PPGALG
#   - PPGA
#   - PPGB
#   - PPGASIGNED
#   - PPGBSIGNED
#   - PPGNROWS
#   - PPGNCOLS
#

proc generators_mul_ppg_name1 { NBITS_A NBITS_B A B OptimizeMulArray PPGAlgorithm } {

  # NBITS_A
  set nom [format "_%d" $NBITS_A]

  # A
  if {[string toupper $A] == "SIGNED"} {
    set nom [format "%sSx" $nom]
  }
  if {[string toupper $A] == "UNSIGNED"} {
    set nom [format "%sUx" $nom]
  }
  if {[string toupper $A] == "BOTH"} {
    set nom [format "%sBx" $nom]
  }

  # NBITS_B
  set nom [format "%s%d" $nom $NBITS_B]

  # B
  if {[string toupper $B] == "SIGNED"} {
    set nom [format "%sS_" $nom]
  }
  if {[string toupper $B] == "UNSIGNED"} {
    set nom [format "%sU_" $nom]
  }
  if {[string toupper $B] == "BOTH"} {
    set nom [format "%sB_" $nom]
  }

  # OptimizeMulArray
  if {[string toupper $OptimizeMulArray] == "LSB"} {
    set nom [format "%sL" $nom]
  } 
  if {[string toupper $OptimizeMulArray] == "MSB"} {
    set nom [format "%sM" $nom]
  } 
  if {[string toupper $OptimizeMulArray] == "BOTH"} {
    set nom [format "%sB" $nom]
  } 
  if {[string toupper $OptimizeMulArray] == "NONE"} {
    set nom [format "%sN" $nom]
  }

  # PPGAlgorithm
  if {[string toupper $PPGAlgorithm] == "SIMPLE"} {
    set nom [format "%sS" $nom]
  } 
  if {[string toupper $PPGAlgorithm] == "BOOTHRADIX4"} {
    set nom [format "%sB4" $nom]
  } 
  if {[string toupper $PPGAlgorithm] == "BOOTHRADIX8"} {
    set nom [format "%sB8" $nom]
  } 

  return $nom
} 


# This procedure computes the uniquifying name extension for these global PPG variables:
#   - PPGBOXCOUNT
#   - PPGROWCOUNT
#   - PPGTOTBOXCOUNT
#   - PPGROWSIZE
#

proc generators_mul_ppg_name2 { NBITS_A A AddExtraCSA OptimizeMulArray PPGAlgorithm } {

 # NBITS_A
  set nom [format "_%d" $NBITS_A]

  # A
  if {[string toupper $A] == "SIGNED"} {
    set nom [format "%sS_" $nom]
  }
  if {[string toupper $A] == "UNSIGNED"} {
    set nom [format "%sU_" $nom]
  }
  if {[string toupper $A] == "BOTH"} {
    set nom [format "%sB_" $nom]
  }

  # AddExtraCSA
  if {$AddExtraCSA == 1} {
    set nom [format "%sY" $nom]
  } else {
    set nom [format "%sN" $nom]
  }

  # OptimizeMulArray
  if {[string toupper $OptimizeMulArray] == "LSB"} {
    set nom [format "%sL" $nom]
  } 
  if {[string toupper $OptimizeMulArray] == "MSB"} {
    set nom [format "%sM" $nom]
  } 
  if {[string toupper $OptimizeMulArray] == "BOTH"} {
    set nom [format "%sB" $nom]
  } 
  if {[string toupper $OptimizeMulArray] == "NONE"} {
    set nom [format "%sN" $nom]
  }

  # PPGAlgorithm
  if {[string toupper $PPGAlgorithm] == "SIMPLE"} {
    set nom [format "%sS" $nom]
  } 
  if {[string toupper $PPGAlgorithm] == "BOOTHRADIX4"} {
    set nom [format "%sB4" $nom]
  } 
  if {[string toupper $PPGAlgorithm] == "BOOTHRADIX8"} {
    set nom [format "%sB8" $nom]
  } 

  return $nom
}