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

set RCSVERSION(api.tcl) { $Revision: 1.2 $ }

proc api_flip {dir} -desc {
  Flip selection.  Dir is "x" or "y".
} -doc {
  As a special case, if the selection contains a single cell,
  and optionally labels and paint that do not go outside
  that cell boundary, and the origin is on the user grid,
  it is flipped about its origin.

  Otherwise the selection is flipped about its common bounding box.
} {
  set dir [string tolower $dir]
  if { $dir != "x" && $dir != "y" } {
    msg -warn "api_flip: unrecognized dir argument: $dir"
    return 0
  }

  set cells [sel_what_l cells -edit_only bad1]
  set labels [sel_what_l labels -edit_only bad2]
  set types [sel_what_l types]  ;# Includes paint and polygons
  if { $bad1 || $bad2 } {
    set message "Selection contains things not in the editcell.  Flip anyway?"
    set choice [tk_dialog .dialog "Warning" $message {} 0 Yes Cancel]
    if { $choice != 0 } { return }
  }

  set len_cells [llength $cells]
  set len_labels [llength $labels]
  set len_types [llength $types]
  if {$len_cells == 0 && $len_labels == 0 && $len_types == 0} {
    # Nothing selected.  In this case max flips the box about
    # the cell origin, which is very confusing, so instead, do nothing.
    return 0
  }

  if { $len_cells == 1} {
    # Remember the cell origin, and selection bounding box.
    setl {ox oy} [cell_origin]
    set sel_bbox [db_bbox -cell __SELECT__]
    struct max_cell c [lindex $cells 0]
    set cell_bbox [list ${c.x1} ${c.y1} ${c.x2} ${c.y2}]
  }

  if { $dir == "x" } {
    :sideways
  } else {
    :upsidedown
  }

  # If it was a cell with origin on grid originally, 
  # move it so the origin remains stationary.
  # If labels or paint selected, dont do it unless they are
  # inside the cell boundary.  Does not work for gcell groups,
  # because their origin is at rootcell origin.
  if {$len_cells == 1 && [rect_inside_rect $sel_bbox $cell_bbox] && \
      ![is_gcell ${c.def} group]} {

    # Was the original origin on grid?
    setl {tx ty} [uusnap -user $ox $oy]
    if { [approx $ox == $tx] && [approx $oy == $ty] } {
      # Yes.  Move cell to put new origin on grid.
      setl {nx ny} [cell_origin]
      set dx [expr $ox - $nx]
      set dy [expr $oy - $ny]
      sel_move $dx $dy
      box_move $dx $dy
    }
  }

  return 1
}


proc api_rotate {} -desc {
  Rotate the selection.
} -doc {
  As a special case, if the selection contains a single cell
  (and possibly labels), and the origin is on the user grid,
  it is flipped about its origin.

  Otherwise the selection is flipped about its common bounding box.
} {
  set cells [sel_what_l cells -edit_only bad1]
  set labels [sel_what_l labels -edit_only bad2]
  set types [sel_what_l types]  ;# Includes paint and polygons
  if { $bad1 || $bad2 } {
    set message "Selection contains things not in the editcell.  Rotate anyway?"
    set choice [tk_dialog .dialog "Warning" $message {} 0 Yes Cancel]
    if { $choice != 0 } { return }
  }

  set len_cells [llength $cells]
  set len_labels [llength $labels]
  set len_types [llength $types]
  if {$len_cells == 0 && $len_labels == 0 && $len_types == 0} {
    # Nothing selected.  In this case max flips the box about
    # the cell origin, which is very confusing, so instead, do nothing.
    return 0
  }

  if { $len_cells == 1 } {
    # Remember the cell origin, and selection bounding box.
    setl {ox oy} [cell_origin]
    set sel_bbox [db_bbox -cell __SELECT__]
    struct max_cell c [lindex $cells 0]
    set cell_bbox [list ${c.x1} ${c.y1} ${c.x2} ${c.y2}]
  }

  :clockwise

  # If it was a cell with origin on grid originally, 
  # move it so the origin remains stationary.
  if {$len_cells == 1 && [rect_inside_rect $sel_bbox $cell_bbox] && \
      ![is_gcell ${c.def} group]} {

    # Was the original origin on grid?
    setl {tx ty} [uusnap -user $ox $oy]
    if { [approx $ox == $tx] && [approx $oy == $ty] } {
      # Yes.  Move cell to put new origin on grid.
      setl {nx ny} [cell_origin]
      set dx [expr $ox - $nx]
      set dy [expr $oy - $ny]
      sel_move $dx $dy
      box_move $dx $dy
    }
  }

  return 1
}
