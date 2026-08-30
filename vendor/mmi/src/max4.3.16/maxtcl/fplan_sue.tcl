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

set RCSVERSION(fplan_sue.tcl) { $Revision: 1.6 $ }

# Routines to init a floorplan from a sue schematic.
# Dump sue icons

# TODO: Check for missing names in sue when the schematic is being dumped.
# TODO: Cross probe cells max to sue and back.  This is not really
#       special to the floorplanner.
# TODO: place ports close to the cell to which they are attached.
#       Add a portorder prop to control placement.
# TODO: change "update block size as well as placement" binary to tri-valued:
#       import: 1. placement 2. placement+sizes 3. new cells/ports only.
# TODO: fplan_sue should create pins using floorplanner routines instead
#       of db_label.

# Note: the spacer is not in this list:  It is placed normally,
# so that it will actually occupy some space,
# but then ignored at the very end so that no max cell is created for it.
set FPLAN_SUE(non_block_types) {row_spanner* dpc_control title_bar \
	global input output inout name_net_* suggested_name* \
	bus_combine* bus_ripper* sign_extend}


# Structure used below
set MAX_STRUCT(fplan_sue_idbbox) {id x1 y1 x2 y2}

# This is a map of sue icon orientation to max orientation.
set FPLAN_SUE(orient_sue2max) {\
	{R0 ""} {R90 r90} {RXY r180} {R270 r270} \
	{RX fx} {RY fy} {R90X fx_r90} {R90Y fy_r90}}



proc fplan_sue_get_icon_bbox {id} {
  global FPLAN_SUE_INFO
  set props $FPLAN_SUE_INFO($id)

  setl {bx1 by1 bx2 by2} [get_assoc bbox $props]
  if {$by2 == ""} {
    msg "fplan_read_sue: warning: origin or bbox missing for icon $id\n"
    return ""
  }

  # Special case for spacers.
  if {[get_assoc type $props] == "spacer"} {
    # TODO: This is hard.  The spacer 
    # The size is specifed in one direction.  In the other direction
    # they should expand to fit?
  }

  # The sue coord system has y reversed, so fix it by negating y.
  return [can_rect [list $bx1 [expr - $by1] $bx2 [expr - $by2]]]
}

proc _UNUSED_fplan_sue_get_icon_name {id} {
  global FPLAN_SUE_INFO
  set type [get_assoc type $FPLAN_SUE_INFO($id)]
  set name [get_assoc _name $FPLAN_SUE_INFO($id)]
  return "${type}:${name}"
}

proc fplan_sue_get_size {id} -desc {
  return x and y sizes in the normal (unrotated) orientation.
} {
  global FPLAN FPLAN_SUE FPLAN_SUE_INFO
  set grid $FPLAN(block_grid)  ;# The floorplanner block grid name.
  set props $FPLAN_SUE_INFO($id)
  set sizex 0
  set sizey 0

  set fplan_size [get_assoc _fplan_size $props]
  set type [get_assoc type $props]
  if {$fplan_size != ""} {
    switch [llength $fplan_size] {
      1 {
	# One number is area.  Set sizex and sizey to sqrt of area, snapping to grid.
	set sizex [uusnap -grid $grid [expr sqrt($fplan_size)]]
	setl {gx gy} [res2 $grid]
	if {$sizex == 0} {
	  set sizex $gx
	}
	setl {junk sizey} [uusnap -grid $grid 0 [expr $fplan_size * 1.0 / $sizex]]
	if {$sizey == 0} {
	  set sizey $gy
	}
      }
      2 {
	setl {sizex sizey} $fplan_size
      }
      3 {
	# Allow specification like "10 x 10"
	setl {sizex junk sizey} $fplan_size
	if {[string tolower $junk] != "x"} {
	  error "invalid fplan_size prop in sue icon: $sue_name"
	}
      }
      default {
	error "invalid fplan_size prop in sue icon: $sue_name"
      }
    }
  } elseif {$type == "spacer"} {
    # The orientation (rotation) of spacers is irrelevant.
    # The rows prop specifies horizontal, and cols, vertical.
    set rows [get_assoc _rows $props]
    if {[string match *r [string tolower $rows]]} {
      set num [string range $rows 0 [expr [string length $rows] - 2]]
      set sizex [expr $num * $FPLAN_SUE(DPC_ROW_HEIGHT)]
    } else {
      set sizex $rows
    }
    set cols [get_assoc _cols $props]
    if {[string match *p [string tolower $cols]]} {
      set num [string range $cols 0 [expr [string length $cols] - 2]]
      set sizey [expr $num * $FPLAN_SUE(DPC_PITCH)]
    } else {
      set sizey $cols
    }
  } else {
    # It is a normal sue icon, not a spacer, and no fplan_size was specified.
    # See if we have lef for this.
    setl {type sizex sizey} [fplan_cell_info -get $type]

    if {$sizey == ""} {
      # We will use the size of the icon itself, scaled by scale_factor.
      # So if no fplan_size are specified on any sue icons,
      # then this will make a max floorplan that looks
      # almost identical to the sue schematic.
      # Note that the sue bbox property already reflects the cell rotation,
      # so if the cell is rotated, the x size is currently the vertical dimension,
      # so swap them.
      msg "fplan_read_sue: warning: no fplan_size specified for sue icon $type\n"

      set sueori [get_assoc orient $props]
      setl {x1 y1 x2 y2} [fplan_sue_get_icon_bbox $id]
      set sizex [expr ($x2 - $x1) * $FPLAN_SUE(scale_factor)]
      set sizey [expr ($y2 - $y1) * $FPLAN_SUE(scale_factor)]
      if {[string match R90* $sueori] || [string match R270* $sueori]} {
	set tmp $sizex
	set sizex $sizey
	set sizey $tmp
      }
    }
  }
  return [list $sizex $sizey]
}

proc fplan_sue_cut {list x1 y1 x2 y2} -desc {
  Return the subset of boxes in list that are inside or intersect the box.
} -doc {
  Assumes all values are integers!  Does not correct for floating point round off.
} {
  set intersect ""
  foreach thingy $list {
    struct fplan_sue_idbbox a $thingy
    if {${a.x2} >= $x1 && \
	${a.x1} <= $x2 && \
	${a.y2} >= $y1 && \
	${a.y1} <= $y2} { 
      lappend intersect $thingy
    }
  }
  return $intersect
}

proc fplan_sue_dump_list {list} -desc {
  For debug: return names of blocks in list of idbbox.
} {
  global FPLAN_SUE_INFO
  set ret ""
  foreach thingy $list {
    set id [lindex $thingy 0]
    if {$id != ""} {
      lappend ret [get_assoc type $FPLAN_SUE_INFO($id)]:[get_assoc _name $FPLAN_SUE_INFO($id)]
    }
  }
  return $ret
}


proc fplan_read_sue {{-menu 0} {filename ""}} {
  global CELL FPLAN FPLAN_SUE FPLAN_SUE_INFO
  set POS_INF 2147483646 ;# 2^31 - 1, - 1 for luck
  set NEG_INF [expr - $POS_INF]

  # Number of grids between blocks
  use_init FPLAN_SUE(block_sep) 1
  # Which placement algorithm.
  use_init FPLAN_SUE(place_method) "globalxy"
  # Scale factor for sue icon.
  use_init FPLAN_SUE(scale_factor) 1
  use_init FPLAN_SUE(ignore_lef) 1
  use_init FPLAN_SUE(ignore_pat) "MMI_*"
  use_init FPLAN_SUE(f_add_to_editcell) 0 ;# Alternative is to use max cell with same name as schematic.
  use_init FPLAN_SUE(f_overwrite) 0       ;# Alternative is to merge changes.
  use_init FPLAN_SUE(f_update_size) 0	  ;# If merging, update sizes based on schematic.
  use_init FPLAN_SUE(f_update_placement) 0 ;# If merging, update placement based on schematic.
  use_init FPLAN_SUE(create_dir) "\$s"
  use_init FPLAN_SUE(f_read_verilog) 1

  set grid $FPLAN(block_grid)  ;# The floorplanner block grid name.
  setl {gridx gridy} [grid_find_named $grid]

  use_init FPLAN_SUE(DPC_ROW_HEIGHT) $gridx
  use_init FPLAN_SUE(DPC_PITCH) $gridy
  #use_init FPLAN_SUE(f_auto_create) 0

  if {$menu || $filename == ""} {
    set prop_list ""

    set FPLAN_SUE(filename) [use_first filename FPLAN_SUE(filename)]

    lappend prop_list [list filename FPLAN_SUE(filename) \
      -filename {-message {Sue Dump File} -pattern *.suedump}]

    lappend prop_list [list {Read associated verilog} FPLAN_SUE(f_read_verilog) -binary \
	    -help {If set, read the verilog file with same name as schematic but with .vh suffix.}]

    lappend prop_list [list "Create max files in directory:" \
	    FPLAN_SUE(create_dir) -entry \
	    -help {If set, any created max files are placed in this directory. \
	      $s is replaced with the directory the sue file for the module was found.}]

    lappend prop_list [list {ignore cells named (pattern)} \
	FPLAN_SUE(ignore_pat) -entry \
	-help {dont bother placing cells matching any of the space-separated patterns.}]

    lappend prop_list [list {ignore lef cells} FPLAN_SUE(ignore_lef) -binary]

    #lappend prop_list [list {create cells as needed} \
	FPLAN_SUE(f_auto_create) -binary]

    # Took this out just because it was confusing.  It works fine.
    #lappend prop_list [list {add to current editcell} \
	FPLAN_SUE(f_add_to_editcell) -binary \
	-help {if set, add cells in sue schematic into current cell instead of\
	switching to or creating a new cell with the same name as the schematic.}]

    # Just thinking: Possible operational modes could be:
    # Create new (aka overwrite existing).
    # Merge, keep existing size and placement, just add new ports/cells.
    # Merge, keep placement, change size.
    # Merge, keep size, change placement.
    # This is too complicated.  Just let the user overwrite vs merge changes.

    lappend prop_list [list {Overwite existing cell} FPLAN_SUE(f_overwrite) -binary \
	-help {If checked, the existing max cell will be over-written. \
	Otherwise, any new schematic cells/ports will be merged into the\
	existing max cell.}]

    lappend prop_list [list {update block sizes from schematic} \
	FPLAN_SUE(f_update_size) -binary \
	-help {if the block already exists, update the block size\
	from the fplan_size property, if any, in the sue schematic icon. \
	Blocks that do not already\
	exist are created, in which case this flag is inapplicable and the\
	initial block size is taken from the schematic.}]

    #lappend prop_list [list {placement algorithm} FPLAN_SUE(place_method) \
      -choice {globalxy localxy}]

    lappend prop_list [list {block separation (grids):} \
	FPLAN_SUE(block_sep) -number -incr [res] -snap [res -userx] \
	-help "spacing between floorplan blocks in units of the grid $grid"]

    lappend prop_list [list {sue icon scale factor} \
	FPLAN_SUE(scale_factor) -number -snap 0.1 \
	-help {the floorplan block size can be specified by the fplan_size\
	property in the sue icon, or if unspecified, taken directly from the\
	sue icon size scaled by this scale factor.}]
    
    # Let user know what grid we think we are using.
    lappend prop_list [list {block grid name} grid -label \
      -help {the grid name that controls sizing and placement of floorplanner blocks.\
      You can not change the name of the grid, but you can change the grid itself\
      in the grid menu (G hotkey.)}]

    #use_init FPLAN_SUE(port_sep_x) 1  ;# TODO: get something real here!
    #use_init FPLAN_SUE(port_sep_y) 1  ;# TODO: get something real here!
    #lappend prop_list [list {port separation in x dir} \
    #	FPLAN_SUE(port_sep_x) -number -incr [res] -snap [res -userx]]
    #lappend prop_list [list {port separation in y dir} \
    #	FPLAN_SUE(port_sep_y) -number -incr [res] -snap [res -usery]]

    set FPLAN_SUE(port_layer_horiz) m$FPLAN(layer_default,horizontal)
    set FPLAN_SUE(port_layer_vert) m$FPLAN(layer_default,vertical)

    #use_init FPLAN_SUE(port_layer_horiz) m3
    #use_init FPLAN_SUE(port_layer_vert) m4
    #lappend prop_list [list {port default layer horizontal} \
    #	FPLAN_SUE(port_layer_horiz) -entry]
    #lappend prop_list [list {port default layer vertical} \
    #	FPLAN_SUE(port_layer_vert) -entry]

    lappend prop_list [list "" "" -help {The following properties in sue\
      are used when importing a schematic to the floorplanner:
      Sue property "fplan_size"  specifies the floorplan block size in microns\
      as two numbers, x and y.
      Sue property "module" specifies the verilog module name, defaults to the icon type.
      Sue property "name" specifies the instance name in max, and is needed\
      when there are multiple instances of the same icon.}]

    if {[prop_menu2 -title "Import sue schematic placement" $prop_list]==0} {
      return  ;# cancelled
    }
  }

  set filename $FPLAN_SUE(filename)
  if {$filename == ""} {
    error "fplan_read_sue: no filename specified"
  }

  if {[file extension $filename] == ""} {
    append filename ".suedump"
  }

  if {$FPLAN_SUE(f_read_verilog)} {
    set vfile [file rootname $filename].vh
    if {![file readable $vfile]} {
      max_error -buffer "read_sue: could not read verilog file: $vfile"
    } else {
      nl2_read_verilog -include [use_first FPLAN(verilog_auto_include)] $vfile
    }
  }

  if {! $FPLAN_SUE(f_add_to_editcell)} {
    # Switch to a cell with same name as schematic.
    set cellname [file rootname [file  tail $filename]] 
    msg "Switching to cell $cellname\n"
    if {$FPLAN_SUE(f_overwrite)} {
      if {[cell_in_memory $cellname]} {
	catch {db_cell_delete $cellname}
	db_cell_new $cellname ./$cellname$CELL(default_suffix)
      }
    } else {
      if {! [cell_in_memory $cellname]} {
	db_cell_new $cellname ./$cellname$CELL(default_suffix)
      }
    }
    :load $cellname
  }

  set fd [open $filename r]

  # Suck in all the info on the sue schematic into FPLAN_SUE_INFO
  catch {unset FPLAN_SUE_INFO}
  while {![eof $fd]} {
    set line [gets $fd]
    if {$line == ""} {continue}
    set sue_id [get_assoc sue_id $line]
    if {$sue_id == ""} {
      msg "fplan_read_sue: unrecognized line in file $filename: $line\n"
    }
    set FPLAN_SUE_INFO($sue_id) $line
  }
  close $fd


  # Determine a max name for each block in the sue schematic and add to FPLAN_SUE_INFO..
  # After this point, can use existence of max_name prop in FPLAN_SUE_INFO
  # to determine which blocks are fplan blocks.
  # Check for non-unique max names; if found, quit now.
  set errors ""
  foreach id [array names FPLAN_SUE_INFO] {
    set props $FPLAN_SUE_INFO($id)
    set sue_type [get_assoc type $props]
    set sue_name [get_assoc netlist_name $props]
    if {$sue_name == ""} {
      set sue_name [get_assoc _name $props]
    }

    if {$FPLAN_SUE(ignore_lef) && [fplan_cell_info -is_lef [fplan_fix_name $sue_type]]} {
      continue
    }

    set bad_name 0
    foreach name_pat [concat $FPLAN_SUE(non_block_types) $FPLAN_SUE(ignore_pat)] {
      if {[string match $name_pat $sue_type]} {
	set bad_name 1 ;# Not a floorplan block.
	break
      }
    }
    if {$bad_name} {continue}

    if {$sue_name != ""} {
      set max_name $sue_name
    } else {
      set max_name $sue_type
    }

    if {[info exists used_max_names($max_name)]} {
      if {$max_name != "spacer" && $used_max_names($max_name) == 1} {
	append errors "Multiple sue icons of type $sue_type must have unique name props - run Sue netlister first\n"
      }
      incr used_max_names($max_name)
    } else {
      set used_max_names($max_name) 1
    }

    set FPLAN_SUE_INFO($id,max_name) $max_name
  }

  if {$errors != ""} {
    msg "fplan_read_sue: errors: $errors"
    prop_dialog -title "fplan_read_sue schematic errors" $errors
    msg "fplan_read_sue aborting...\n"
    return  ;# Give up.
  }


  # Compute bbox of each icon in schematic coords.
  # Make a list of all floorplan block icon locations.
  set sue_list ""
  foreach sue_id [array names FPLAN_SUE_INFO] {
    set type [get_assoc type $FPLAN_SUE_INFO($sue_id)]
    if {$type == $cellname} {
      # Special case.  A schematic can contain its own icon as a comment.
      # Ignore it.
      continue
    }
    if {$type == "spacer" || [info exists FPLAN_SUE_INFO($sue_id,max_name)]} {
      set bbox [fplan_sue_get_icon_bbox $sue_id]
      if {$bbox == ""} {
	# Something wrong.  Dont know what. 
	# Warning already printed by fplan_sue_get_icon_bbox.
	continue
      }
      setl {x1 y1 x2 y2} $bbox

      # If no max_name, ignore it, so only interesting floorplan
      # blocks are added to list.  We ignore all the ports, etc.
      # This uses the fplan_sue_idbbox structure.
      lappend sue_list [list $sue_id $x1 $y1 $x2 $y2]
    }
  }

  # Sort icon list by x1 and y1.
  set FPLAN_SUE(sort_x) [lsort -index 1 -integer $sue_list]
  set FPLAN_SUE(sort_y) [lsort -index 2 -integer $sue_list]

  # Fuzz is some allowed misalignment of edges in a sue schematic.
  set fuzz 10

  set llen [llength $sue_list]

  # Determine the stacking order of the icons in the sue schematic.
  # Set "above" and "right" props in each FPLAN_SUE_INFO($id)
  # These algorithms are n-squared, but this is just a prototype.

  # Method 1:  Icon is above (right) of any other icon
  # whose top (right) is below (left) in the sue schematic,
  # regardless of how far away the icon is.

  # For each icon i, make a list of icons j that i is to the right of.
  for {set i 0} {$i < $llen} {incr i} {
    set left "" ;# List of guys that are left of a.
    set stack_right ""
    struct fplan_sue_idbbox a [lindex $FPLAN_SUE(sort_x) $i]

    for {set j 0} {$j < $i} {incr j} {
      struct fplan_sue_idbbox b [set thingy [lindex $FPLAN_SUE(sort_x) $j]]
      if {${b.x2} <= ${a.x1}} {
	# b is to the left of a.
	lappend left $thingy
      }
    }

    # If localxy, keep only the nearest neighbor above and below,
    # and any guys who are really directly left of a.
    if {$FPLAN_SUE(place_method) == "localxy"} {
      # Look directly below of a; set ry1 to nearest lower neighbor edge.
      set list_below [fplan_sue_cut $FPLAN_SUE(sort_y) ${a.x1} $NEG_INF ${a.x2} [expr ${a.y1}-1]]
      # Sort on y2, save last (highest).
      struct fplan_sue_idbbox nb [lindex [lsort -integer -index 4 $list_below] end]
      set ry1 [expr {${nb.y2} != "" ? ${nb.y2} : $NEG_INF}]
      # Look directly above of a; set ry2 to nearest upper neighbor edge.
      set list_above [fplan_sue_cut $FPLAN_SUE(sort_y) ${a.x1} [expr ${a.y2}+1] ${a.x2} $POS_INF]
      # Sort on y1, save first (lowest).
      struct fplan_sue_idbbox na [lindex [lsort -integer -index 2 $list_above] 0]
      set ry2 [expr {${na.y1} != "" ? ${na.y1} : $POS_INF}]
      # A must be right of all guys between ry1 and ry2.
      # The search to POS_INF is not really necessary; but the $left list 
      # was already cut to include only guys to the left of a.
      foreach thingy [fplan_sue_cut $left $NEG_INF $ry1 $POS_INF $ry2] {
	struct fplan_sue_idbbox t $thingy
	lappend stack_right [list ${t.id} side_x2]
      }

      # If a is directly above or below someone, mark that as an
      # alignment on side_x1.  Find the rightmost of all neighbors
      # who are as close as the nearest neighbors.  We will be a little
      # fuzzy on the definition of "close", so that things dont
      # have their edges perfectly aligned in sue.

      # Tmp is a list of all neighbors as close as the nearest neighbor above a.
      set tmp [fplan_sue_cut $list_above $NEG_INF ${na.y1} $POS_INF [expr ${na.y1} + $fuzz]]
      # Sort to get the leftmost one.  (Maybe not necessary - already sorted?)
      set tmp2 [lindex [lsort -integer -index 1 $tmp] 0]
      if {$tmp2 != ""} {
	struct fplan_sue_idbbox t $tmp2
	lappend stack_right [list ${t.id} side_x1]
      }

      # Tmp is a list of all neighbors as close as the nearest neighbor below a.
      set tmp [fplan_sue_cut $list_below $NEG_INF [expr ${nb.y2} - $fuzz] $POS_INF ${nb.y2}]
      set tmp2 [lindex [lsort -integer -index 1 $tmp] 0]
      if {$tmp2 != ""} {
	struct fplan_sue_idbbox t $tmp2
	lappend stack_right [list ${t.id} side_x1]
      }

    } else {
      # a is to the right of everything in left
      foreach thingy $left {
	struct fplan_sue_idbbox t $thingy
	set leftid ${t.id}
	lappend stack_right [list $leftid side_x2]
      }
    }
    set FPLAN_SUE_EXTRA(${a.id},stack_right) $stack_right
  }

  # For each icon i, make a list of icons j that i is above.
  for {set i 0} {$i < $llen} {incr i} {
    set below ""
    set stack_above ""
    struct fplan_sue_idbbox a [lindex $FPLAN_SUE(sort_y) $i]

    for {set j 0} {$j < $i} {incr j} {
      struct fplan_sue_idbbox b [set thingy [lindex $FPLAN_SUE(sort_y) $j]]
      if {${b.y2} <= ${a.y1}} {
	lappend below $thingy
      }
    }

    if {$FPLAN_SUE(place_method) == "localxy"} {
      # Bound the search at the nearest neighbor to left and right.
      set list_left [fplan_sue_cut $FPLAN_SUE(sort_x) $NEG_INF ${a.y1} [expr ${a.x1}-1] ${a.y2}]
      struct fplan_sue_idbbox nl [lindex [lsort -integer -index 3 $list_left] end]
      set rx1 [expr {${nl.x2} != "" ? ${nl.x2} : $NEG_INF}]
      set list_right [fplan_sue_cut $FPLAN_SUE(sort_x) [expr ${a.x2}+1] ${a.y1} $POS_INF ${a.y2}]
      struct fplan_sue_idbbox nr [lindex [lsort -integer -index 1 $list_right] 0]
      set rx2 [expr {${nr.x1} != "" ? ${nr.x1} : $POS_INF}]
      # A must be above all guys between rx1 and rx2.
      foreach thingy [fplan_sue_cut $below $rx1 $NEG_INF $rx2 $POS_INF] {
	struct fplan_sue_idbbox t $thingy
	lappend stack_above [list ${t.id} side_y2]
      }

      # If a is directly left or right someone, mark that as an
      # alignment on side_y1.  Find the lowermost of all neighbors
      # who are as close as the nearest neighbor.  We will be a little
      # fuzzy on the definition of "close", so that things dont
      # have their edges perfectly aligned in sue.

      # Tmp is a list of all neighbors as close as the nearest neighbor on the right.
      set tmp [fplan_sue_cut $list_right ${nr.x1} $NEG_INF [expr ${nr.x1} + $fuzz] $POS_INF]
      set tmp2 [lindex [lsort -integer -index 2 $tmp] 0]
      if {$tmp2 != ""} {
	struct fplan_sue_idbbox t $tmp2
	lappend stack_above [list ${t.id} side_y1]
      }

      # Tmp is a list of all neighbors as close as the nearest neighbor on the left.
      set tmp [fplan_sue_cut $list_left [expr ${nl.x2} - $fuzz] $NEG_INF ${nl.x2} $POS_INF]
      set tmp2 [lindex [lsort -integer -index 2 $tmp] 0]
      if {$tmp2 != ""} {
	struct fplan_sue_idbbox t $tmp2
	lappend stack_above [list ${t.id} side_y1]
      }

    } else {
      # a is above everything in stack_above
      foreach thingy $below {
	struct fplan_sue_idbbox t $thingy
	lappend stack_above [list ${t.id} side_y2]
      }
    }
    set FPLAN_SUE_EXTRA(${a.id},stack_above) $stack_above
  }

  edit_push_direct  ;# Save where we were.

  # Now make the max stacking order match the sue stacking order.

  # Create any blocks that dont currently exist.
  set prb_layer [techinfo layer prb]
  foreach thingy $sue_list {
    struct fplan_sue_idbbox a $thingy
    set id ${a.id}
    set type [get_assoc type $FPLAN_SUE_INFO($id)]
    set sueori [get_assoc orient $FPLAN_SUE_INFO($id)]

    # Set sizex,sizey to the size of the block

    if {$type == "spacer" } {
      setl {sizex sizey} [fplan_sue_get_size $id]
      setl {sizex sizey} [uusnap -ceil -grid $grid $sizex $sizey]
      set max_size($id) [list $sizex $sizey]
      set max_space($id) [list $sizex $sizey]
      set max_ori($id) ""
      set max_location($id) {0 0}
      continue
    }

    set f_just_created 0
    if {! [cell_in_memory $type]} {
      if {[cell_path_find $type] == ""} {
	# Sue Sub-cell does not exist.  Create it.
	setl {sizex sizey} [fplan_sue_get_size $id]
	setl {sizex sizey} [uusnap -ceil -grid $grid $sizex $sizey]
	set module [get_assoc _module $FPLAN_SUE_INFO($id)]
	if {$module == ""} {set module $type}

	# This assignment is so you can use $s in FPLAN_SUE(create_dir)
	set s [file dirname $filename]
	set createdir [subst -nobackslashes -nocommands $FPLAN_SUE(create_dir)]
	fplan_init_cell -module $module -size "$sizex $sizey" $type $createdir
	# Add in the ports. Put them all in the center.
	setl {subcx subcy} [uusnap [expr $sizex/2.0] [expr $sizey/2.0]]
	foreach terminal [get_assoc terminals $FPLAN_SUE_INFO($id)] {
	  # This is all the information you get about the icon terminals.
	  set port_name [lindex $terminal 0]
	  set port_assoc [lindex $terminal 1]
	  set port_iotype [get_assoc type $port_assoc]
	  set port_origin [get_assoc origin $port_assoc]
	  set port_orient [get_assoc orient $port_assoc]
	  # We dont really have a clue where to put these to make
	  # sure they are on an edge.  We would have to take the specified
	  # origin and move it to the nearest edge.  Just put them in the center.
	  foreach bit [nlt_bus_explode $port_name] {
	    # We are creating ports for an icon in the sue schematic, so we
	    # dont have any idea what side they belong on.  Just put in center.
	    db_label -cell $type -kind $port_iotype space $bit $subcx $subcy
	  }
	}
	fplan_port_legalize -center_unplaced 1 $type
	set f_just_created 1
      } else {
	# Cell already exists.  Load it.
	cell_load -search $type

	# TODO: Should check that module property is not out of sync!
      }
    }

    # TODO: Should warn before creating cells, ask what to do!!

    if {$FPLAN_SUE(f_update_size) && ! $f_just_created && ![fplan_cell_info -is_lef $type]} {
      setl {sizex sizey} [fplan_sue_get_size $id]
      setl {sizex sizey} [uusnap -ceil -grid $grid $sizex $sizey]
      # Change size of existing max blocks.
      eval db_paint -cell $type -erase $prb_layer [db_bbox -cell $type]
      db_paint -cell $type $prb_layer 0 0 $sizex $sizey
      # If the user resized, also automatically replace the ports inside the icon.
      # This might not be what the user wanted, but its too confusing otherwise.
      # The single button "Update block sizes" both icon size and port re-placement.
      fplan_legalize_ports -center_unplaced 1 $type
    }


    # Cache cell size and orientation by sue id.
    setl {junk maxori} [lsearch2 -value -index 0 $FPLAN_SUE(orient_sue2max) $sueori]
    if {$junk != $sueori} {
      msg "fplan_read_sue: warning: unrecognized sue orientation $sueori\n"
    }
    set max_ori(${id}) $maxori

    # Run the size through the cell transform in case it is rotated.
    setl {bx1 by1 bx2 by2} [fplan_bbox -cell $type]
    set transform [orientation -reverse $maxori]
    setl {bx1 by1} [transform_coords $transform $bx1 $by1]
    setl {bx2 by2} [transform_coords $transform $bx2 $by2]
    setl {bx1 by1 bx2 by2} [can_rect [list $bx1 $by1 $bx2 $by2]]

    # Need to multiply by the number of cells in an array.
    set max_name $FPLAN_SUE_INFO($id,max_name)
    set arrayx [llength [nlt_bus_explode $max_name]]

    # The easy way to implement the block separation
    # is to add it into the block size:
    set max_size(${id}) [uusnap -grid $grid \
	[expr $arrayx * ($bx2 - $bx1) + $FPLAN_SUE(block_sep) * $gridx] \
	[expr $by2 - $by1 + $FPLAN_SUE(block_sep) * $gridy]]
    set max_location(${id}) {0 0}  ;# Init
  }

  edit_pop_direct

  # Determine max_location of each cell.
  # Move things to right as needed.
  foreach thingy $FPLAN_SUE(sort_x) {
    struct fplan_sue_idbbox a $thingy
    set sue_id ${a.id}
    setl {x1 y1} $max_location($sue_id)
    foreach altthingy $FPLAN_SUE_EXTRA($sue_id,stack_right) {
      setl {altid altside} $altthingy
      setl {altsizex altsizey} $max_size($altid)
      setl {altx1 alty1} $max_location($altid)
      # Make sure id is right of the specified side of altid.
      switch $altside {
	"side_x1" {
	  set x1 [max $x1 $altx1]
	}
	"side_x2" {
	  set altx2 [expr $altx1 + $altsizex]
	  set x1 [max $x1 $altx2]
	}
	default {error "internal"}
      }
    }
    set max_location($sue_id) [list $x1 $y1]
  }

  # Move things up as needed.
  foreach thingy $FPLAN_SUE(sort_y) {
    struct fplan_sue_idbbox a $thingy
    set sue_id ${a.id}
    setl {x1 y1} $max_location($sue_id)
    foreach altthingy $FPLAN_SUE_EXTRA($sue_id,stack_above) {
      setl {altid altside} $altthingy
      setl {altsizex altsizey} $max_size($altid)
      setl {altx1 alty1} $max_location($altid)
      # Make sure id is above the specified side of altid.
      switch $altside {
	"side_y1" {
	  set y1 [max $y1 $alty1]
	}
	"side_y2" {
	  set alty2 [expr $alty1 + $altsizey]
	  set y1 [max $y1 $alty2]
	}
	default { error "internal" }
      }
    }
    set max_location($sue_id) [list $x1 $y1]
  }

  # Now place em.
  foreach thingy $sue_list {
    struct fplan_sue_idbbox a $thingy
    set sue_id ${a.id}
    set max_id $FPLAN_SUE_INFO($sue_id,max_name)
    set type [get_assoc type $FPLAN_SUE_INFO($sue_id)]
    if {$type == "spacer"} {continue}
    setl {newx1 newy1} $max_location($sue_id)
    setl {sizex sizey} $max_size($sue_id)
    setl {basesizex basesizey} [fplan_sue_get_size $sue_id]
    foreach bit [nlt_bus_explode $FPLAN_SUE_INFO($sue_id,max_name)] {
      # We have to run the name through fix_name to eliminate bus brackets.
      # Sue changes [ and ] to $, so we must do the same.
      # Dont use fplan_fix_name, because sue doesnt!
      # set max_id [fplan_fix_name $bit]
      regsub -all {[][]} $bit {$} max_id
      # See if instance already exists.
      set cell_info [lindex [db_instances_l -id $max_id] 0]
      if {$cell_info == ""} {
	# Must instantiate new instance.
	# Do the orientation with selt_transform to rotate/flip around bbox.
	db_instance -dup_ok -id $max_id $type $newx1 $newy1
	sel_cell2 $max_id
	selt_transform $max_ori($sue_id)
      } elseif {$FPLAN_SUE(f_update_placement)} {
	# Move existing instance.
	sel_cell2 $max_id
	# Error check that type is correct.
	struct max_cell c $cell_info
	if {${c.def} != $type} {
	  msg "fplan_read_sue: warning: instance $max_id uses sue icon $type but max cell ${c.def}\n"
	}
	set oldori [orientation ${c.transform}]
	if {$oldori != $max_ori($sue_id)} {
	  # yucko.
	  selt_transform -cell_origin $type -reverse $oldori
	  selt_transform -cell_origin $type $max_ori($sue_id)
	  struct max_cell c [sel_what cells]
	}
	sel_move [expr $newx1 - ${c.x1}] [expr $newy1 - ${c.y1}]
      }

      # Increment to next bit location
      # TODO: This might want to depend on orientation.
      set newx1 [expr $newx1 + $basesizex]
    }
  }

  # Add prb to the newly created cell.
  setl {bx1 by1 bx2 by2} [lay_bbox]
  setl {x_size y_size} [uusnap -grid $grid [expr $bx2-$bx1] [expr $by2-$by1]]
  setl {gx gy} [res2 $grid]
  if {$x_size==0} {set x_size $gx}
  if {$y_size==0} {set y_size $gy}
  db_paint $prb_layer 0 0 $x_size $y_size


  _fplan_sue_do_ports


  sel_clear
  eval lay_box [lay_bbox]
  view_cell
}


proc _fplan_sue_do_ports {} -desc {
  place ports from sue schematic into current max cell.
} {
  global FPLAN_SUE FPLAN_SUE_INFO global sue_ports

  foreach dir {left right up down} {
    set sue_ports($dir) ""
  }

  # Determine schematic bbox; put in sx1,sy1,sx2,sy2.
  set sx1 9999999
  set sy1 9999999
  set sx2 -9999999
  set sy2 -9999999
  foreach id [array names FPLAN_SUE_INFO] {
    set props $FPLAN_SUE_INFO($id)
    set bbox [get_assoc bbox $props]
    if {$bbox != ""} {
      setl {tx1 ty1 tx2 ty2} $bbox
      set sx1 [min $sx1 $tx1]
      set sy1 [min $sy1 $ty1]
      set sx2 [max $sx2 $tx2]
      set sy2 [max $sy2 $ty2]
    }
  }

  # Invert y axis
  set sy1 [expr - $sy1]
  set sy2 [expr - $sy2]

  # Find center of schematic into scx, scy.
  set scx [expr ($sx1 + $sx2) / 2]
  set scy [expr ($sy1 + $sy2) / 2]

  # Snarf the ports out of the sue schematic info.
  foreach id [array names FPLAN_SUE_INFO] {
    set props $FPLAN_SUE_INFO($id)
    set type [get_assoc type $props]
    if {$type != "input" && $type != "output" && $type != "inout"} {continue}

    set orient [get_assoc orient $props]
    setl {x y} [get_assoc origin $props]
    # Sue y coord is top-to-bottom; reverse it so it goes bot-to-top.
    set y [expr - $y]
    set this_port [list $id $x $y]

    switch $type {
      "input" {
	# Save by direction the port visually points.
	switch $orient {
	  RY - R0 {
	    lappend sue_ports(left) $this_port
	  }
	  R90X - R90 {
	    lappend sue_ports(up) $this_port
	  }
	  RX - RXY {
	    lappend sue_ports(right) $this_port
	  }
	  R90Y - R270 {
	    lappend sue_ports(down) $this_port
	  }
	  default {
	    error "unrecognized sue port orientation: $orient\
	       on port id $id = [get_assoc _name $props]"
	  }
	}
      }
      "output" {
	switch $orient {
	  RY - R0 {
	    lappend sue_ports(right) $this_port
	  }
	  R90X - R90 {
	    lappend sue_ports(up) $this_port
	  }
	  RX - RXY {
	    lappend sue_ports(left) $this_port
	  }
	  R90Y - R270 {
	    lappend sue_ports(down) $this_port
	  }
	  default {
	    error "unrecognized sue port orientation: $orient\
	       on port id $id = [get_assoc _name $props]"
	  }
	}
      }
      "inout" {
	# This is tricky.  The port symbol doesnt have an obvious direction.
	# Instead, put it on the side it is closest to in the schematic.
	switch $orient {
	  RY - R0 -
	  RX - RXY {
	    # Left or right orientation.
	    if {$x < $scx} {
	      lappend sue_ports(left) $this_port
	    } else {
	      lappend sue_ports(right) $this_port
	    }
	  }
	  R90X - R90 -
	  R90Y - R270 {
	    # Up or down orientation.
	    if {$y < $scy} {
	      lappend sue_ports(down) $this_port
	    } else {
	      lappend sue_ports(up) $this_port
	    }
	  }
	  default {
	    error "unrecognized sue port orientation: $orient\
	       on port id $id = [get_assoc _name $props]"
	  }
	}
      }
      default {
	continue
      }
    }
  }

  # Sort em left-to-right and bottom-to-top.
  set sue_ports(up) [lsort -integer -index 1 $sue_ports(up)]
  set sue_ports(down) [lsort -integer -index 1 $sue_ports(down)]
  set sue_ports(right) [lsort -integer -index 2 $sue_ports(right)]
  set sue_ports(left) [lsort -integer -index 2 $sue_ports(left)]

  setl {bx1 by1 bx2 by2} [lay_bbox]

  setl {cx cy} [eval center_coords [lay_bbox]]

  setl {snapx snapy offx offy} [wire_get_grid $FPLAN_SUE(port_layer_horiz)]
  _fplan_sue_ports_int $sue_ports(left) $bx1 $cy \
    0 $snapy $FPLAN_SUE(port_layer_horiz) left

  _fplan_sue_ports_int $sue_ports(right) $bx2 $cy \
    0 $snapy $FPLAN_SUE(port_layer_horiz) right

  _fplan_sue_ports_int $sue_ports(up) $cx $by2 \
    $snapx 0 $FPLAN_SUE(port_layer_vert) top

  _fplan_sue_ports_int $sue_ports(down) $cx $by1 \
    $snapx 0 $FPLAN_SUE(port_layer_vert) bottom
  
}


proc _fplan_sue_ports_int {portlist cx cy sepx sepy default_layer region} {
  global FPLAN_SUE_INFO FPLAN_SUE
  set cell [lay_editcell]

  # Count up the ports so we can center them on the side.
  set port_count 0
  foreach thing $portlist {
    set id [lindex $thing 0]
    set name [get_assoc _name $FPLAN_SUE_INFO($id)]
    incr port_count [llength [nlt_bus_explode $name]]
  }

  set px [expr $cx - int($port_count/2) * $sepx]
  set py [expr $cy - int($port_count/2) * $sepy]

  foreach thing $portlist {
    set id [lindex $thing 0]
    # The sue type is one of: input, output, inout.
    set sue_type [get_assoc type $FPLAN_SUE_INFO($id)]
    set name [get_assoc _name $FPLAN_SUE_INFO($id)]
    set layerspec [get_assoc _layerspec $FPLAN_SUE_INFO($id)]
    set loc [get_assoc _loc $FPLAN_SUE_INFO($id)]
    set bitloc [get_assoc _bitloc $FPLAN_SUE_INFO($id)]
    if {$layerspec == ""} {
      set layer $default_layer
    } else {
      TODO: Must parse the layerspec to get the layer out of it.
      set layer ???
    }

    if {0} {   ;# Dont know what this was supposed to do.
      set bits [nlt_bus_explode $name]
      set busname [nlt_bus_get_name $name]
      if {$bitloc == "" && [llength $bits] > 1} {
	set lobit [nlt_bus_get_spec [lindex $bits 0]]
	set hibit [nlt_bus_get_spec [lindex $bits end]]
	if {$lobit < $hibit} {
	  set bitloc "track \$b"
	} else {
	  set bitloc "track [llength $bits] - \$b"
	}
      }
    }


    foreach bit [nlt_bus_explode $name] {

      if {$bitloc != ""} {
	fplan_db_pin -cell $cell setprop $bit bitloc $bitloc
      }

      if {$loc != ""} {
	fplan_db_pin -cell $cell setprop $bit locspec $loc
      } else {
	fplan_db_pin -cell $cell setprop $bit locspec $region
      }
      fplan_db_pin -cell $cell setprop $bit place "placed"

      _fplan_sue_make_label -region $region \
	      $bit $px $py $sue_type $layer
      set px [expr $px + $sepx]
      set py [expr $py + $sepy]
    }
  }
}

proc _fplan_sue_make_label {{-region ""} name x y iotype layer} {
  set cell [lay_editcell]
  sel_labels -text $name
  :delete
  set pos c
  switch -- $region {
    top {set pos n}
    bottom {set pos s}
    left {set pos w}
    right {set pos e}
  }
  db_label -pos $pos -kind $iotype $layer $name $x $y
}


proc _UNUSED_pat_fplan {} {

    # This is n-squared.
    # Walk through all the icons.  For each icon that
    # overlaps another in the x direction (or y direction),
    # add a left (or down) pointer from one icon to the other.

    foreach ida [array names FPLAN_SUE_INFO] {
	set left($ida) ""
	set below($ida) ""
	foreach idb [array names FPLAN_SUE_INFO] {
	    if {$id1 == $id2} {continue}
	    setl {ax1 ay1 ax2 ay2} $FPLAN_SUE_INFO($ida)
	    setl {bx1 by1 bx2 by2} $FPLAN_SUE_INFO($idb)

	    # Do the icons overlap horizontally or vertically?
	    set x_overlap [expr {$ax1 < $bx2 && $ax2 > $bx1}]
	    set y_overlap [expr {$ay1 < $by2 && $ay2 > $by1}]

	    # Warn if they overlap both ways.
	    if {$x_overlap && $y_overlap} {
		puts "Warning: cells overlap in both directions: \
			[pat_icon_name $ida] pat_icon_name $idb]"
	    }

	    if {$x_overlap} {
	    }

	    if {$ay1 < $by2 && $ay2 > $by1} {
	    }
	}
    }

    set x_list [sort -integer -index 0 $x_list]
    set y_list [sort -integer -index 0 $y_list]

    return

    # Sort by x and y
    set x_list ""
    set y_list ""
    foreach id [array names FPLAN_SUE_INFO] {
	setl {x1 y1 x2 y2} [icon_bbox $id]
	lappend x_list [list $x1 $id]
	lappend y_list [list $y1 $id]
    }
}


proc fplan_sue_update_sizes {} -desc {
  Update fplan_size prop in schematic being cross probed, if any.
} {
  set sue [misc_check_sue]  ;# Errors out if cross probe not inited.

  set cell [lay_editcell]

  foreach cell_info [db_search_l cells] {
    setl {bx1 by1 bx2 by2} [fplan_bbox -cell [cellinfo_def $cell_info]]
    set xsize [expr $bx2 - $bx1]
    set ysize [expr $by2 - $by1]
    send $sue [list from_max_set_prop $cell [cellinfo_id $cell_info] fplan_size "$xsize x $ysize"]
  }
}
