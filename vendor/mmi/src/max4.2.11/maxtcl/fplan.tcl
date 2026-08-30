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

set RCSVERSION(fplan.tcl) { $Revision: 1.8 $ }


#======================================================================
# TODO NOW
#======================================================================

# Set the technology from the PROJECT.

# From jim: 

# TODO: Restore read/write/edit .ports file.  Needs to work on current cell
#       if none selected.

# TODO: Make cell grid 10 tracks wide so power can be drilled at regular intervals.

# TODO: Put the "Create Merge Overwrite" on the main import verilog propmenu.

# TODO: Add option in import sue to add new blocks, but NOT change
#       existing placement.  Did I already do this?
#       Test sue->fplan.

# TODO: If an instance references an undefined module, jim wants it to ask
#       what to do: ignore it or create a dummy module.  Maybe put it in
#       an orphan directory.  I dont where it goes, because there's no verilog dir.

# TODO: Add option to spread out ports on their side.

# TODO: Warn for user-expr ports that land on an obstruction.

# TODO: Iterate port placement

# TODO: Does import verilog need to call nl_create_idesign on something?
#       Dont think so.

# TODO: Need to specify top level of design?   Maybe not.  Only need it
#       for write_dspf?  Also would be nice to have a command to pop up
#       to top level, but that could be done by the list-box showing "All Cells".

# TODO: When reading verilog, warn if it does not match the max file. (jb request)
#       Can check number of ports and number of cells.  Tell user to
#       run design checker to diff the two.
#       ALTERNATIVE: add option to auto-design-check every newly read file?

# TODO: Warn if max file contains zero size cells, which are caused by
#       missing or empty max cell.  jballard requested, but I dont think
#       it should be automatic.

# BUG: Movement of cell by keyboard arrows gets it off grid.
# BUG: Movement of labels should be constrained, too?
# BUG: Flipping a cell screws up its origin.  Flipping two works, because
#       of the stupid heuristics.

# BUG: import_verilog: if cell already exists and you say "merge" it moves prb too?
#      Is this still true?


#======================================================================
# TEST
#======================================================================

# Sue2chipper: Test props on sue icons/ports.  Test Merge new cells.

#======================================================================
# TODO LATER
#======================================================================

# TODO: Design Checker: check max against verilog, or max file against max file.
#       Also find instances with no max cell, empty cells.

# Grid X was wrong at one point.  Think its fixed now.

# TODO: Have a listbox called "All loaded cells" - needed in ng where
#       there is only one cell per directory, the current list-box paradigm
#       does not work.  Might even display hierarchy.

# TODO: Change "T" command to use a pick-list.

# TODO: Place/edit ports: if viewing as busses, check that props are the same
#	for all pins in the bus!

# TODO: port placement locations for outputs from registers that travel to the
#       same cell should be spread a little farther apart to lessen miller capacitance.
#       Note that the decision should NOT be just to do this for busses, since
#       different bits of large busses might go to different cells, and the problem
#	is really generic to all registered outputs that go to the same cell.
#	Note that the port location for busses will probably be set from within
#	blocks to set the bit-pitch, so the whole problem may be moot.

# TODO: Communicate bitpitch from DPC.  Could put in .def file as a property.

# TODO: Flylines should have option of displaying repeater paths.
#       might want to see path through repeaters, or direct lines bypassing repeaters?.

# TODO: Lee wants flylines to show only the output that feeds the input of the
#       selected cell, not all the other inputs to which the net is also connected.
#       He also wants arrows on the flyline to indicate direction.

# TODO: Add new block?

# TODO:	Jballard wants a mode to show flylines into the contents of a cell,
#	rather than just to the ports that have been placed at the edge,
#	to help with placement of cells.

# TODO: When editing cell foo, want easy way to import the next level down (foo/*)
#       in the hierarchy from verilog.  Think this works now.
# TODO: Add Display Design Hierarchy like sue.  But use it for what?


# TODO: Cross-check lef to actual cells.  Maybe as a separate command.
# TODO: Write lef for cell including pin locations?  Needed for what?
# TODO: Beef up read lef and put in File Import menu.

# TODO: The pins in the def file need a real orientation.  Currently it is inferred
#       from the region.  We may need a separate "orientation" or "side" prop on pins.

# TODO: make sure 1'b0 maps to Vdd/Vss or whatever.
#	Update: fixed, need to test.

# TODO: Mark leaf cells in verilog hierarchy window.
#       Read/write stop list (use lef?)  Add button to show/hide leaf cells?

# TODO: Allow flatten verilog levels.
#       Add merge/overwrite button on menu.

# TODO: documentation.

# TODO: When popping from a cell, re-place ports in upper level cell.  (huh?)

# TODO: Add command to set prb to current size of enclosed cells.

# TODO: Make max selection select cells first, to avoid getting prb layer every time.
#       OR: make floorplan mode where you cant select prb at all.

# TODO: Rename after nl_ungroup in read_verilog so that removing demorgan
#       cells does not change their name.  nl_rename_cell is supposed to good now.


# Rejected: Import verilog: jballard asked that if there is no module,
#       should still get the port names.  However, we dont know the
#       port I/O direction in that case.

#======================================================================
# Should we use max at all?
#======================================================================

# Pros of using max for floorplanner:
#   edit-in-place, expand(view) multiple levels, obstruction layers, groups, align.
#   File-open/save undo clipboard flip/rotate/move help 
#   selection(point,area,cell/netby-name) ruler.
#   Future ability to show cells with I/O bumps, clock-trees, etc.
# Cons:
#   Cell bboxes. Use colors for different hierarchy levels.
#   Text control.  Colors.
#   Flylines.  Selection. Colors.
#   Instance properties with placement/visibility (like sue)
#   Need label layer visibility controlled by palette.
#   Aribtrary text attached to cell instances.
# 
#   For initial chip planning - do we want to allow someone to use max as a canvas
#   to draw cells, put in ports, and create verilog?

#======================================================================
#  BIG PROJECTS
#======================================================================

# TODO: Generate/display fake approximate timing just from block sizes.

# TODO: Use jay's def parser.  Its in nl/def2pnl.  Ask first about just using nl.
#       Need to put the def writer in the max extractor,
#       and/or mark all paint tiles with the net they are, and/or look
#       up net-names by seeing what sub-cell ports they are connected to.

# TODO: Add power post obstructions.  Avoid them when placing labels.

# TODO: Run pearl - working on pearl.tcl
# TODO: connect to speedy for timing.
#       Can we show the critical path through hierarchy?
# TODO: Run synthesis (dc_shell) or does psyn do this?
# TODO: show congestion.



# ==================================
# MAX INTERNAL PROBLEMS
# ==================================
#
# o Turn off port visibility based on palette.  Currently, only labels
#   that are on paint are affected by the palette.
# o Port color should be based on their palette color for their layer.
# o flatten must not destroy cell/label instance props.  

#======================================================================
# ISSUES:
# undefined modules?  Should a max cell be created?
#
# QUESTION: If there are big and little cells mixed together, we probably want
# to hand place the big cells then auto-place the little cells.  How?
#
# Note: jballard suggested using cells for ports when doing auto-place,
# and defining their locations using region constraints, so the auto-placer
# can decide where they go.
#
# If sue or nl has a bus for which not all pins are used, should the unused
# pins be deleted automatically when slurped into chipper?
#======================================================================


set FPLAN_PORT_OPTIONS {{place "unplaced"} {layerspec "space"} {loc ""} {bitloc ""}}

# The help is a list of option descriptions
set FPLAN_PORT_HELP {\
  {region: top, bottom, left, right indicate placement anywhere on that side. \
      "center" is used for new pins. \
      Additional regions may be added to the cell.} \
  {place: "region" means place port anywhere in its region. \
      "placed" means suggested placment provided, but may be moved by tools. \
      "fixed" means current placement may not over-ridden by tools.} \
  {type: To be defined, for wire size, shielding, etc.} \
  {iotype: input, output, inout} \
  {layer: "space" means layer is undefined. \
      The layer should be auto-magically\
      determined from the port side in the final placement, so this\
      should normally be left alone.} \
  {Cgate: input gate capacitance.  May be a number to specify cap\
    in fF, or letter (A, B, etc) to specify input cell size.} \
  {Lwire: wire length from port to gate inside module}\
  }

# List of gate sizes and input capacitance.
use_init FPLAN(gate_sizes) {{A 10} {B 20} {C 40} {D 80}}

use_init FPLAN(default_area_util) 90

# Defaults for verilog auto-load.
# These must be set because the auto-load hook (fplan_verilog_auto_load)
# may be called before floorplan setup menu.
use_init FPLAN(verilog_autoload) 0
use_init FPLAN(verilog_auto_include) ""
use_init FPLAN(verilog_auto_suffixes) ".v .vh .vg"
use_init FPLAN(verilog_auto_squish) 0
use_init FPLAN(verilog_auto_check) 1
use_init FPLAN(design_root) ""

# Use Jay's loadable external netlister if 1, internal if 0
if {![info exists FPLAN(use_nl_shell)]} {
  set FPLAN(use_nl_shell) 1
}

use_init FPLAN(block_type_list) {auto-place DPC macro}

init_global FPLAN(exists) -default 0 -type INT -desc {
  Set when the floorplanner menu is initialized.
}


# Name of grid used for floorplan block size/movement.
#set FPLAN(block_grid) "fplan-block"
init_global FPLAN(block_grid) -default "fplan-block" -type STRING -desc {
  The name of the grid used by floor planner for blocks derived from
  verilog modules.  This is the name of a grid.  The grid itself
  is defined in the grid menu.
}

#set FPLAN(hier_sep_char) "!"
init_global FPLAN(hier_sep_char) -default "!" -type STRING -desc {
  Cell names are uniquified by constructing a verilog path name of the
  module through the verilog module hierarchy.  This is the separator
  character in this path.  It must be a legal max cell name character,
  which also implies it is a legal UNIX filename character.
  Can not be "/".
}

init_global FPLAN(layer_default,horizontal) -default "3" -type STRING -desc {
  Name of default horizontal metal layer for default port placement.
}
init_global FPLAN(layer_default,vertical) -default "4" -type STRING -desc {
  Name of default veritical metal layer for default port placement.
}

init_global FPLAN(flyline_cells) -default center -type STRING -desc {
  Used in floorplanner.  How to show flylines between blocks.
}
init_global FPLAN(flyline_ports) -default individual -type STRING -desc {
  Used in floorplanner.  How to show flylines to top level ports.
}
init_global FPLAN(flyline_mode) -default selected -type STRING -desc {
  Used in floorplanner.  Whether to show flylines between blocks.
}
init_global FPLAN(flyline_trace_repeaters) -default 0 -type INT -desc {
  Used in floorplanner.  Trace flylines through repeaters.
}
init_global FPLAN(flyline_width_divisor) -default 8 -type INT -desc {
  Used in floorplanner.  Flyline bundle width divided by this for display.
}
init_global FPLAN(flyline_ignore) -default "clk* 1* 0*" -type STRING -desc {
  Used in floorplanner.  Do not draw flylines for these nets.
}

set SUFFIX(dspf) .fplan_est_dspf
# These should be the same except one is a glob pattern and one is the raw exts.
set SUFFIX(verilog_list)    ".v .vg .vh .sv"


proc select_end_hook {} -desc {
  Called at end of selection.
} {
  global FPLAN MN_TECH_VAR
  # Only do this if using floor planner.
  # Also cant change flylines on a read-only cell.
  # If flyline_mode is "all", we have already displayed all flylines,
  # so dont change them.
  if {$FPLAN(exists) && ![db_cell_read_only] &&\
    $FPLAN(flyline_mode) == "selected"} {
    cursor_busy 1
    db_flyline -delete

    set cell_info [sel_what_l cells -limit 2]
    if {[llength $cell_info] == 1} {
      struct max_cell c [lindex $cell_info 0]
      fplan_show_flylines ${c.id} ${c.def}
    }

    if {$FPLAN(flyline_ports) != "off"} {
      # Also show flylines for selected labels.
      foreach lab_info [sel_what_l labels] {
	fplan_sel_net -more [labinfo_text $lab_info]
      }
    }

    cursor_busy 0
  }
}

proc UNUSED_fplan_cell2id {cell} -desc {
  Deprecated.  Use db_instances_l
} -doc {
  Return list of max instance names given the max def name.
  cell can be -init (resets cache) or cell def.
  Note that all verilog instances have unique max cell defs in a floorplan.
} {
  global _FPLAN_CELL_CACHE

  if {$cell == "-init"} { catch {unset _FPLAN_CELL_CACHE};return }

  return [db_instances_l -of $cell]

  set top [lay_editcell]
  if {[info exists _FPLAN_CELL_CACHE($top/$cell)]} {
    return $_FPLAN_CELL_CACHE($top/$cell)
  }

  # Reload the cache
  catch {unset _FPLAN_CELL_CACHE}
  foreach thing [db_search_l cells] {
    struct max_cell c $thing
    lappend _FPLAN_CELL_CACHE($top/${c.def}) ${c.id}
  }
  return [use_first _FPLAN_CELL_CACHE($top/$cell)]
}


proc fplan_bbox {{-grid ""} {-parent} {-cell ""} {-cellid ""}} -desc {
  Return bbox of floorplan cell.
} -doc {

  If -grid user, snap to user grid instead of the big fplan-grid.
  If -grid mask, snap to mask grid.
  If -parent, return bbox in coordinates of lay_editcell.

  Bbox is determined by prb layer, if any, otherwise
  by actual cell bbox.
} {
  global FPLAN

  if {[lay_editcell] != [lay_rootcell]} {
    error "edit in place not supported"
  }

  if {$grid == "user"} {
    # Why would you use the user grid?
    set grid "user"
  } elseif {$grid == "mask"} {
    set grid "mask"
  } else {
    set grid $FPLAN(block_grid)
  }

  if {$cellid != ""} {
    set cell [cell_id2cell $cellid]
  } elseif {$cell != ""} {
    # Use specified cell.
  } else {
    error "fplan_bbox: must specify -cell or -cellid"
  }

  # For lef cells, the cell def name and module def name are identical.
  if {[fplan_cell_info -is_lef $cell]} {
    setl {type xsize ysize pinlist} [fplan_cell_info -get $cell]
    # We assume all the stdcells have 0 0 at the lower left corner.
    # But I am not sure anything bad would happen if this were not true.
    set x1 0; set y1 0;
    set x2 $xsize; set y2 $ysize;
  } else {


    # Get the size of the current prb layer.  It better be a rectangle.
    set badmsg ""
    set prb_list [db_search_l paint -cell $cell prb]
    if {[llength $prb_list] > 1} {
      # prb layer consists of multiple rectangles.  Thats bad.
      set badmsg "non-rectangular"
    } elseif {[llength $prb_list] == 1} {
      # Make sure prb layer on grid.
      struct max_paint p [lindex $prb_list 0]
      setl {fx1 fy1 fx2 fy2} [uusnap -grid $grid ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
      if {[approx $fx1 != ${p.x1}] || [approx $fy1 != ${p.y1}] || \
	[approx $fx2 != ${p.x2}] || [approx $fy2 != ${p.y2}]} {
	# prb layer not on fplan-block grid.  Thats bad.
	set badmsg "not on grid"
	append badmsg "cur=${p.x1} ${p.y1} ${p.x2} ${p.y2} on-grid=$fx1 $fy1 $fx2 $fy2"
      }
    }

    if {$badmsg != "" && $grid == $FPLAN(block_grid)} {
      set msg "PRB layer in cell $cell is damaged ($badmsg).  Fix it?"
      set choice [tk_dialog .dialog "Fix Floorplan Block Damage" $msg {} 0 \
		  Yes No Cancel]
      if {$choice == 2} {error "Operation cancelled"}
      if {$choice == 1} {
	# choice "no".  Just return existing bbox.
	return [db_bbox -cell $cell]
      }
      # Fix it by drawing prb everywhere.
      set oldbox [db_bbox -cell $cell]
      eval db_paint -cell $cell -erase prb [db_bbox -cell $cell]
      eval db_paint -cell $cell prb [eval uusnap -grid $grid $oldbox]
      set prb_list [db_search_l paint -cell $cell prb]
    }

    if {[llength $prb_list] == 1} {
      struct max_paint p [lindex $prb_list 0]
      set coords [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
    } else {
      if {[llength $prb_list] == 0} {
	msg "warning: cell $cell no prb layer found, using cell size for bbox\n"
      }
      # No prb layer found.
      set coords [db_bbox -cell $cell]
    }
    setl {x1 y1 x2 y2} [eval uusnap -grid $grid $coords]
  }

  if {$parent && $cell != [lay_editcell]} {
    # Must transform to root-cell coords in lay_editcell.
    # First have to find the bloody thing.
    struct max_cell c [lindex [db_instances_l -id $cellid] 0]
    setl {x1 y1} [transform_coords ${c.transform} $x1 $y1]
    setl {x2 y2} [transform_coords ${c.transform} $x2 $y2]
    # If cell is flipped, coords might get flipped too, so fix.
    setl {x1 y1 x2 y2} [can_rect [list $x1 $y1 $x2 $y2]]
  }
  return [list $x1 $y1 $x2 $y2]
}

proc _fplan_find_unique_cell_name {cell} -desc {
  Make a cell name based on $cell that does not currently exist in max.
} {
  # Cut off previous _n suffix, if any.
  regsub {_[0-9]+$} $cell "" newcellbase

  for {set i 1} {1} {incr i} {
    set newcell ${newcellbase}_$i
    if {[cell_empty $newcell]} {return $newcell}
  }
}

proc _fplan_uniquify_cell {cellid} {
  sel_cell2 $cellid
  struct max_cell c [sel_what cells]
  if {${c.id} == ""} {
    error "Could not find cell $cellid"
  }
  set cell ${c.def}

  setl {ox oy} [cell_origin]

  set newcell [_fplan_find_unique_cell_name ${c.def}]

  db_cell_copy -source $cell $newcell

  # Copy all the properties.
  foreach propname [db_prop -def $cell] {
    db_prop -def $newcell $propname [db_prop -def $cell $propname]
  }

  # Dont have any instance props in the containing cell yet.
  #foreach propname [db_prop] {
  #  if {[regexp "^$cellid(.*)\$" $propname junk subpropname]} {
  #    ...
  #  }
  #}

  sel_cell2 $cellid
  :delete
  db_instance -id $cellid $newcell $ox $oy
  sel_cell2 $cellid
}

proc _fplan_block_props_calc_area {} -desc {
  called from fplan_block_props to do the area recalc
} {
  global FPLAN_PROPS_TMP

  set area1 [fplan_get_lef_area -lef $FPLAN_PROPS_TMP(cell)]
  set area2 [fplan_get_lef_area $FPLAN_PROPS_TMP(cell)]

  if {[approx $area1 == $area2]} {
    set FPLAN_PROPS_TMP(min_area) $area1
    return
  }

  set prop_list ""
  set which area2
  lappend prop_list [list "compute area" which -radio [list \
    "add LEFs of leaf cells but current size (prb) of non-leaf cells ($area2)" \
    "add up only hierarchically contained LEFs ($area1)"] -values {area2 area1}]
  
  if {![prop_menu2 $prop_list]} {
    return ;# cancelled
  }

  if {$which == "area1"} {
    set FPLAN_PROPS_TMP(min_area) $area1
  } else {
    set FPLAN_PROPS_TMP(min_area) $area2
  }
}

proc fplan_block_props {{cellid ""}} -desc {
  prop menu for props of specified block (defaults to selected).
} -doc {
  If you are editing props for lay_editcell, you can only
  edit props related to the def, not instance props.
} {
  global FPLAN FPLAN_PROPS_TMP

  # This is the name of the grid that the floorplan main blocks snap to.
  # It is set up in the tech file.  We will error out if it is unset.
  set grid $FPLAN(block_grid)
  if {$grid == ""} {set grid "user"}
  setl {snapx snapy} [res2 $grid]

  if {$cellid == ""} {
    set cellid [_fplan_ask_cell "edit properties"]
  }
  if {$cellid == ""} {return}

  while {1} {

    if {$cellid == "."} {
      set cell [lay_editcell]
      setl {ox1 oy1 ox2 oy2} [fplan_bbox -grid mask -cell $cell]
    } else {
      set cell [cell_id2cell $cellid]
      setl {ox1 oy1 ox2 oy2} [fplan_bbox -grid mask -parent -cellid $cellid]
      set modid [fplan_db_cell celli2modi $cellid]
    }

    set FPLAN_PROPS_TMP(cellid) $cellid
    set FPLAN_PROPS_TMP(cell) $cell


    # Snap coords to fplan grid
    setl {nx1 ny1 nx2 ny2} [uusnap -grid $grid $ox1 $oy1 $ox2 $oy2]
    set FPLAN_PROPS_TMP(original_location) [list $nx1 $ny1 $nx2 $ny2]

    setl {FPLAN_PROPS_TMP(x_size) FPLAN_PROPS_TMP(y_size)} \
	  [list [expr $nx2 - $nx1] [expr $ny2 - $ny1]]
    set FPLAN_PROPS_TMP(x_origin) $nx1
    set FPLAN_PROPS_TMP(y_origin) $ny1

    set FPLAN_PROPS_TMP(timing) $cell
    set FPLAN_PROPS_TMP(min_area) [db_prop -def $cell min_area]
    if {$FPLAN_PROPS_TMP(min_area) == ""} {set FPLAN_PROPS_TMP(min_area) 0}

    set FPLAN_PROPS_TMP(cell_area_util) [db_prop -def $cell area_util]
    if {$FPLAN_PROPS_TMP(cell_area_util) == ""} {set FPLAN_PROPS_TMP(cell_area_util) 90}

    # TODO: The vpath needs to be an instance property!!!!!
    #set vpath [db_prop -def $cell verilog_path]
    set modname [db_prop -def $cell module]
    if {$modname == ""} {
      # Block was not read in from verilog
      set modname "*unknown*"
      set modid "*unknown*"
    }
    set FPLAN_PROPS_TMP(modtype) [db_prop -def $cell modtype]
    if {$FPLAN_PROPS_TMP(modtype) == ""} {
      set FPLAN_PROPS_TMP(modtype) [lindex $FPLAN(block_type_list) 0]
    }

    set size_type FIXED_SIZE

    set wire_util [db_prop -def $cell wire_util]
    if {$wire_util == ""} {set wire_util 0}

    set prop_list ""

    if {$cellid == "."} {
      # Only display a subset of props for lay_editcell
      lappend prop_list [list {verilog module} modname -label]
    } else {
      lappend prop_list [list {INSTANCE PROPERTIES} "" -label]
      lappend prop_list [list {verilog module} modname -label]
      lappend prop_list [list {verilog instance} modid -label \
	      -help {The name of the block, which must be the same as\
	      the base name of the associated schematic.}]
      #lappend prop_list [list {verilog path} vpath -label]

      lappend prop_list [list x_origin FPLAN_PROPS_TMP(x_origin) -number -incr $snapx]
      lappend prop_list [list y_origin FPLAN_PROPS_TMP(y_origin) -number -incr $snapx]
    }

    lappend prop_list [list "" "" -separator]

    lappend prop_list [list {PLACEMENT PROPERTIES} "" -label]
    lappend prop_list [list {max cell} cell -label]

    #lappend prop_list [list size_type size_type -choice "AREA FIXED_SIZE" \
	    -reload -help {If AREA, the area is fixed but the aspect\
	    ratio can change;  if FIXED_SIZE, the size is fixed.}]

    lappend prop_list [list "minimum area" FPLAN_PROPS_TMP(min_area) -number \
	    -incr [expr [max $snapx $snapy]] \
	    -help {minimum total area, used for stretching}]
    lappend prop_list [list "Recalculate min area from contents now" "" -button _fplan_block_props_calc_area]
    lappend prop_list [list "%area utilization" FPLAN_PROPS_TMP(cell_area_util) -number 1 100\
	    -help {x_size * y_size must be greater than min_area * %utilization}]

    lappend prop_list [list x_size FPLAN_PROPS_TMP(x_size) -number -incr $snapx \
	    -when { $size_type == "FIXED_SIZE" } \
	    -help {fixed x dimension}] 
    lappend prop_list [list y_size FPLAN_PROPS_TMP(y_size) -number -incr $snapy \
	    -when { $size_type == "FIXED_SIZE" } \
	    -help {fixed y dimension}]
    set current_area [expr $FPLAN_PROPS_TMP(x_size) * $FPLAN_PROPS_TMP(y_size)]
    lappend prop_list [list "current area" current_area -label]
    set FPLAN_PROPS_TMP(grid) $grid
    lappend prop_list [list "cell placement grid" FPLAN_PROPS_TMP(grid) -choice "$FPLAN(block_grid) user"]

    #lappend prop_list [list "module type" FPLAN_PROPS_TMP(modtype) -choice $FPLAN(block_type_list)]

    if {$cellid != "."} {
      lappend prop_list [list {uniquify placement of this cell} "" -button "_fplan_uniquify_cell $cellid" -return 2]
    }

    #lappend prop_list [list "Wire resource utilization% (guess)" wire_util \
	    -number 0 100 -incr 1 \
	    -help {Needed to estimate global wiring congestion over block}]

  if {0} {
    lappend prop_list [list "" "" -separator]

    lappend prop_list [list {TIMING PROPERTIES} "" -label]
    
    lappend prop_list [list {timing model} FPLAN_PROPS_TMP(timing) -entry]
    if {$cellid != "."} {
      lappend prop_list [list {uniquify timing of this cell} "" -button {warning "not implemented!"} -return]
    }
    lappend prop_list [list "view timing model..." "" -button {warning "not implemented!"}]
  }

    if {[approx $nx1 != $ox1] || [approx $ny1 != $ny1] ||
	[approx $nx2 != $ox2] || [approx $ny2 != $ny2]} {
      set msg "WARNING: block is not currently on fplan-grid."
      lappend prop_list [list $msg "" -label]
    }

    #lappend prop_list [list Stretch "" -button _fplan_stretch_cell]

    set title "Chipper Block Properties"
    set ret [prop_menu2 -apply _fplan_props_apply -title $title $prop_list]
    if {$ret == 0} {
      # cancelled
      return
    }

    if {$ret == 2} {
      continue ;# prop_menu -return 2 statement
    }
    break
  }

  _fplan_props_apply


  catch {unset FPLAN_PROPS_TMP}
}

proc _fplan_props_apply {} {
  global FPLAN_PROPS_TMP

  # Reselect the cell.  If it was uniquified, the cell def name has changed.
  set cellid $FPLAN_PROPS_TMP(cellid)
  sel_cell2 $cellid
  struct max_cell c [lindex [sel_what_l cells] 0]
  set cell ${c.def}

  setl {nx1 ny1 nx2 ny2} $FPLAN_PROPS_TMP(original_location)

  # New x_size and y_size It should be ok, but make sure!
  setl {x_size y_size} [uusnap -grid $FPLAN_PROPS_TMP(grid) $FPLAN_PROPS_TMP(x_size) $FPLAN_PROPS_TMP(y_size)]

  if {$x_size == 0 || $y_size == 0} {
    max_error "floorplan error: Size may not be 0"
    return
  }

  db_prop -def $cell min_area $FPLAN_PROPS_TMP(min_area)
  #db_prop -def $cell wire_util $wire_util
  db_prop -def $cell modtype $FPLAN_PROPS_TMP(modtype)
  db_prop -def $cell area_util $FPLAN_PROPS_TMP(cell_area_util)
  if {$FPLAN_PROPS_TMP(grid) == "user"} {
    db_prop -def $cell grid ""
  } else {
    db_prop -def $cell grid $FPLAN_PROPS_TMP(grid)
  }

  # Set box to new size, and change it.
  layt_box exact $nx1 $ny1 [expr $nx1 + $x_size] [expr $ny1 + $y_size]
  _fplan_block_resize_int $cell

  # Move to new location.
  sel_move [expr $FPLAN_PROPS_TMP(x_origin) - $nx1] [expr $FPLAN_PROPS_TMP(y_origin) - $ny1]

  if {$cellid != "."} {
    sel_cell2 $cellid ;# Leave cell selected for user convenience
  }

  set new_area [expr $x_size * $y_size]
  if {[approx $new_area < $FPLAN_PROPS_TMP(min_area)]} {
    set choice [prop_dialog -buttons "Yes No Show_props_again" \
    "Warning: specified block size (x_size * y_size = $new_area) is smaller than min_area ($FPLAN_PROPS_TMP(min_area)). \
    Do you want to change min_area to $new_area ?"]
    if {$choice == "Yes"} {
      db_prop -def $cell min_area $new_area
    } elseif { $choice == "Show_props_again"} {
      fplan_block_props $cell
    }
  }
}

proc UNUSED_fplan_mush_ports {} -desc {
  If any ports in the current cell are outside the bounding box, move them in.
} {
  # Get prb layer location.
  setl {x1 y1 x2 y2} [fplan_bbox -cell [lay_editcell]]

  # Mush all the ports into the bounding box.
  foreach label_info [db_search_l labels -non_hier] {
    struct max_label l $label_info
    sel_labels -text ${l.text}
    if { ${l.x1} < $x1 } {
      sel_move [expr $x1 - ${l.x1}] 0
    }
    if { ${l.x2} > $x2 } {
      sel_move [expr $x2 - ${l.x1}] 0
    }
    if { ${l.y1} < $y1 } {
      sel_move 0 [expr $y1 - ${l.y1}]
    }
    if { ${l.y2} > $y2 } {
      sel_move 0 [expr $y2 - ${l.y1}]
    }
  }
  sel_clear
}

proc _fplan_block_resize_int {cell} -desc {
  Resize selected leaf cell to match box.
} -doc {
  Cell can be the edit cell or a selected instance in the edit cell.
} {
  global FPLAN
  set grid $FPLAN(block_grid)

  # New requested size
  setl {nx1 ny1 nx2 ny2} [layt_box exact]

  # Save in cell coords for use by place_ports
  set original_rect [fplan_bbox -cell $cell]

  if {$cell == [lay_editcell]} {
    setl {nx1 ny1 nx2 ny2} [uusnap -grid $grid $nx1 $ny1 $nx2 $ny2]
    eval db_paint -cell $cell -erase prb [db_bbox -cell $cell]
    db_paint -cell $cell prb $nx1 $ny1 $nx2 $ny2
  } else {
    # Assume cell is selected and is inside current edit cell.
    struct max_cell c [sel_what cells]
    assert {$cell == ${c.def}}

    # Old (current) size
    setl {ox1 oy1 ox2 oy2} [fplan_bbox -parent -cellid ${c.id}]
    sel_cell2 ${c.id}  ;# Make sure just one selected.
    # Move cell to box; necessary if left or bottom was stretched.
    sel_move [expr $nx1 - $ox1] [expr $ny1 - $oy1]

    # New prb location.  Use same origin inside cell as previously.
    # Should we always anchor at 0,0?  Do other routines assume 0,0 origin?
    setl {bx1 by1 bx2 by2} $original_rect
    # Make sure it is snapped to the grid.
    setl {bx1 by1 bx2 by2} [uusnap -grid $grid $bx1 $by1 $bx2 $by2]
    eval db_paint -cell $cell -erase prb [db_bbox -cell $cell]
    db_paint -cell $cell prb $bx1 $by1 [expr $bx1+$nx2-$nx1] [expr $by1+$ny2-$ny1]
  }

  update idletasks
  set msg "Do you want to re-place the ports?"
  set choice [tk_dialog .dialog "Cell $cell" $msg {} 0 Yes No]
  if {$choice == 0} {
    fplan_place_ports -resize $original_rect $cell
  }

  if {$cell != [lay_editcell]} {
    sel_cell2 ${c.id} ;# Leave cell selected for user convenience
  }
  # Get rid of the box.
  layt_box user 0 0 0 0
}

proc _fplan_ask_cell {title} -desc {
  Return a cellid to be processed.  Return . to mean editcell.
} -doc {
  If one cell is selected, return that.
  Otherwise, ask user if they want to process the edit cell.
  Return "" if user cancels or we fail.
} {
  set cell_info [sel_what_l cells -limit 2]

  if {[llength $cell_info] == 0} {
    set ret [prop_dialog -title $title -buttons "Yes No" \
	"No block selected.  Do you want to $title the edit cell?"]
    if {$ret == "No"} {return ""}
    return "."
  } elseif {[llength $cell_info] == 1} {
    struct max_cell c [lindex $cell_info 0]
    if {${c.id} == {Topmost cell in the window}} {
      return "."
    } else {
      return ${c.id}
    }
  } else {
    error "Must select a single block"
  }
}

proc fplan_block_stretch {} {
  global FPLAN
  set grid $FPLAN(block_grid)
  setl {snapx snapy} [res2 $grid]

  set cellid [_fplan_ask_cell "stretch"]
  if {$cellid == ""} {return}
  set cell [expr {$cellid == "." ? [lay_editcell] : [cell_id2cell $cellid]}]

  # Make sure this block has a prb layer.  If none, paint it.
  set prb_list [db_search_l paint -cell $cell prb]
  if {[llength $prb_list] == 0} {
    eval db_paint -cell $cell prb [fplan_bbox -cell $cell]
    # BUG FIX: db_paint blows away the selection.
    if {$cell != [lay_editcell]} {
      sel_cell2 $cellid
    }
  }

  # Get bbox from prb layer
  if {$cellid == "."} {
    setl {ox1 oy1 ox2 oy2} [fplan_bbox -cell $cell]
  } else {
    setl {ox1 oy1 ox2 oy2} [fplan_bbox -parent -cellid $cellid]
  }
  set cur_area [expr ($ox2 - $ox1) * ($oy2 - $oy1)]

  set min_area [db_prop -def $cell min_area]
  if {$min_area == ""} {
    set min_area [fplan_get_lef_area -lef $cell]
  }
  set area_util [db_prop -def $cell area_util]
  if {$area_util == ""} {set area_util 90}
  set req_area [expr $min_area * 100.0 / $area_util]
  
  # Round areas to integers.
  set req_area [expr int($req_area)]
  set cur_area [expr int($cur_area)]

  set prop_list ""
  set stretch_type "constant area"
  set area_type "min"
  lappend prop_list [list "Stretch" stretch_type \
    -radio {"constant area" "change area"} -reload]

  lappend prop_list [list "Use area:" area_type \
    -radio [list "minimum area*utilization ($req_area)" "current area ($cur_area)"] \
    -values {min current} -when {$stretch_type == "constant area"}]
  
  set title "stretch block $cellid (type $cell)"

  if {![prop_menu2 -title $title $prop_list]} {
    return ;# cancelled
  }

  if {$stretch_type == "constant area"} {

    if {$area_type == "min"} {
      # Determine initial box.  Keep aspect ratio the same.
      setl {ox1 oy1 ox2 oy2} [rect_expand -grid $FPLAN(block_grid) \
	[list $ox1 $oy1 $ox2 $oy2] $req_area]
      set new_area $req_area
    } else {
      # Just use the current box.
      setl {ox1 oy1 ox2 oy2} [uusnap -grid $FPLAN(block_grid) $ox1 $oy1 $ox2 $oy2]
      set new_area $cur_area
    }

    # Let user stretch the box.
    layt_box mask $ox1 $oy1 $ox2 $oy2
    box_mode_enter -area $new_area -grid $FPLAN(block_grid) \
      -cmd "_fplan_block_resize_int $cell" -mode resize
  } else {
    # Just start a normal stretch.
    layt_box mask $ox1 $oy1 $ox2 $oy2
    box_mode_enter -grid $FPLAN(block_grid) \
      -cmd "_fplan_block_resize_int $cell" -mode resize
  }

  return

  # vvvvv UNUSED vvvvvv

  if {[approx $cur_area != $req_area]} {

    #set msg "Warning: no min_area has ever been specified for this block. \
    The min_area sets the minimum area during stretching. \
    Do you want to set min_area from the current size? \
    (To change the settings, use: Block Properties)"

    set msg "Warning: The current size ($cur_area) differs from \
      minimum area ($min_area) / utilization ($area_util) = $req_area. \
      Stretch using current size or minimum size?"

    set choice [prop_dialog -buttons {Current Minimum Cancel} $msg]
    switch -- $choice {
      "Current" {
	set req_area $cur_area
      }
      "Minimum" {
	# Nothing needed.
      }
      "Cancel" {
	return
      }
      default { assert 0 }
    }
  }

  # Determine initial box.  Keep aspect ratio the same.
  setl {ox1 oy1 ox2 oy2} [rect_expand -grid $FPLAN(block_grid) [list $ox1 $oy1 $ox2 $oy2] $min_area]

  # Let user stretch the box.
  layt_box mask $ox1 $oy1 $ox2 $oy2
  box_mode_enter -area $req_area -grid $FPLAN(block_grid) \
    -cmd "_fplan_block_resize_int $cell" -mode resize
}

proc fplan_setup {} -type local -desc {
  Menu for general floorplan options.
} {
  global FPLAN
  set prop_list ""

  lappend prop_list [list "Show flylines for:" FPLAN(flyline_mode) \
	-radio {"selected cell,ports" "all cells" "none (flylines off)"} \
	-values {selected all none} \
	-help {If set to "all", flylines are drawn when this menu closes. \
	If you later make changes that would affect flylines, bring\
	up this menu again to redraw new flylines. \
	If set to "selected", it will draw flylines for one (and only one) \
	selected cell, and any selected text labels.}]

  # The only thing that is working currently is "center".
  lappend prop_list [list "cell flylines show as:" FPLAN(flyline_cells) \
	-radio {"bundles to cell centers" "bundles to cell sides" "individual flylines"} \
	-values {center sides individual}]

  if {0} {
    # This is too much detail in the prop_menu.  User doesnt care.
    # Port flylines controlled by the man "Show flylines for" item.
    lappend prop_list [list "port flylines show as:" FPLAN(flyline_ports) \
	-radio {"bundles to cell side" "individual flylines" "off"} \
	-values {center individual off}]
  }

  #lappend prop_list [list "trace repeaters:" FPLAN(flyline_trace_repeaters) -binary \
	-help {if set, flylines will be traced through repeaters cells}]

  lappend prop_list [list "Flyline ignore nets" \
	FPLAN(flyline_ignore) -entry \
	-help {Do not draw flylines for these nets.  Value is a glob-style pattern.}]
  lappend prop_list [list "Flyline width divisor" \
	FPLAN(flyline_width_divisor) -number 1 \
	-help {How many wires per bundle needed to increment \
	visible flyline width}]

  lappend prop_list [list "Use nl_shell.so" \
	FPLAN(use_nl_shell) -binary \
	-help {If set, loads verilog using C library routines. \
	Otherwise, reads verilog with tcl.  Note: tcl reader\
	does not support verilog "assign" statement or repeater insertion.}]
  
  # These are not used yet, so dont display them yet.
  if {0} {
    lappend prop_list [list "" "" -separator]
    lappend prop_list [list "Default Gate Capacitance (set in startup file)" "" -label -align center]
    # We just display these; not reasonable to set them here because
    # they will be lost at end of session.  User should set the sizes
    # in the tcl start up file.
    foreach thingy $FPLAN(gate_sizes) {
      setl {gate_size cap} $thingy
      lappend prop_list [list "Gate $gate_size: Cap = $cap" "" -label]
    }
  }


  lappend prop_list [list "" "" -separator]

  lappend prop_list [list "Verilog Setup" "" -label -align center]
  lappend prop_list [list "Auto-Load Verilog" FPLAN(verilog_autoload) -binary \
    -help {If set, max will auto-load a verilog file in the same dir and\
    with the same name as the .max file but with a verilog suffix}]
  lappend prop_list [list "Verilog Header File" FPLAN(verilog_auto_include) -entry \
    -help {This file will be loaded, similar to an include file,\
    at the same time as all auto-loaded verilog files}]
  lappend prop_list [list "Verilog Suffixes" FPLAN(verilog_auto_suffixes) -entry \
    -help {List of verilog suffixes that will be tried when searching for\
    a verilog file to auto-load.}]

  lappend prop_list [list "Name of top level module:" FPLAN(design_root) -entry \
      -help {You must specify a top level cell before doing any operations \
	    that need hierarchical connectivity information}]
  lappend prop_list [list "Remove demorgans/cells with only one cell"  \
	FPLAN(verilog_auto_squish) -binary \
	-help {If a module contains only one cell, that level of hierarchy is\
	removed.  The new cell name is created by concatenating the old cell name,\
	an @ symbol, and the old module name.}]
  lappend prop_list [list "Auto Design Check when verilog auto-loaded"  \
	FPLAN(verilog_auto_check) -binary \
	-help {Runs design checker on cell when verilog is auto-loaded}]



  lappend prop_list [list "" "" -separator]
  lappend prop_list [list "Grid Setup" "" -label -align center]
  lappend prop_list [list "Grid name for cell block placement" \
	FPLAN(block_grid) -entry]
  catch {setl {snapx snapy} [res2 $FPLAN(block_grid)]}
  set grid_value "$snapx x $snapy"

  lappend prop_list [list "Grid $FPLAN(block_grid) is:" grid_value -label]

  lappend prop_list [list "Default horizontal metal layer for initial port placement" \
	FPLAN(layer_default,horizontal) -entry]
  lappend prop_list [list "Grid vertical metial layer for initial port placement" \
	FPLAN(layer_default,vertical) -entry]

  set title "Chipper Option Setup"
  if {![prop_menu2 -title $title $prop_list]} {
    # cancelled
    return
  }

  if {$FPLAN(flyline_mode) == "all"} {
    fplan_show_flylines -all
  } else {
    db_flyline -delete
  }
}

proc fplan_verilog_auto_load {{-maxfile} filename} -desc {
  Try to auto-load specified verilog filename, a full path.
} -doc {
  If -maxfile, the filename is the max filename; look for a
  verilog file in the same directory.
} {
  global CELL FPLAN _FPLAN_VERILOG_AUTOLOAD_MSG_PRINTED

  # Dont do it if we are not in floorplanner mode.
  if {!$FPLAN(exists) || !$FPLAN(verilog_autoload)} {return}

  if {[file extension $filename] == $CELL(default_suffix)} {
    set filename [file rootname $filename]
  }


  if {$maxfile} {
    set cell [file rootname [file tail $filename]]
    set mod [fplan_unfix_name $cell]
  } else {
    set mod [file rootname [file tail $filename]]
    set cell [fplan_fix_name $mod]
  }

  if {[fplan_cell_info -is_lef $mod]} {return}

  if {[nl2_loaded $mod]} {return}

  set verilog_file ""
  if {!$maxfile} {
    set verilog_file $filename
  } else {
    foreach suffix $FPLAN(verilog_auto_suffixes) {
      set dir [file dirname $filename]
      set try $dir/$cell$suffix
      if {[file readable $try]} {
	set verilog_file $try
	break
      }
    }
  }

  # Only print this message once.
  set suppress_msgs [info exists _FPLAN_VERILOG_MSG($filename)]
  set _FPLAN_VERILOG_AUTOLOAD_MSG_PRINTED($filename) 1

  if {$verilog_file == ""} {
    if {!$suppress_msgs} {
      msg "Verilog auto-load: warning: No verilog found for $filename\n"
    }
  } else {
    set cmd [list nl2_read_verilog -flags {-rtl} \
	-include $FPLAN(verilog_auto_include) $verilog_file]
puts "$cmd"
    if {![catch $cmd result]} {
      msg "Verilog auto-loaded file: $verilog_file\n"
      if {$FPLAN(verilog_auto_squish)} {
	verilog_squish
      }

      if {$FPLAN(verilog_auto_check) && [cell_in_memory $cell]} {
	fplan_design_check -cell $cell
      }
    } else {
      # This message must be suppressed, because we try to load a bad
      # verilog file over and over.
      if {!$suppress_msgs} {
	msg "Verilog auto-load: error reading verilog file: $try error was: $result\n"
      }
    }
  }

  return
}

proc fplan_write_verilog {} {
  fplan_check_verilog

  set filename [lay_editcell].out.vg
  set module [fplan_db_cell module [lay_editcell]]
  set hier 1

  set prop_list ""
  lappend prop_list [list Filename filename -entry]
  lappend prop_list [list Module module -entry]
  lappend prop_list [list "All hierarchy" hier -binary]

  if {[prop_menu2 -title "Write Verilog" $prop_list] == 0} {
    return ;# cancelled
  }

  if {$hier} {
    nl_write_verilog -hierarchy $filename $module
  } else {
    nl_write_verilog $filename $module
  }
}

proc fplan_read_verilog {{-rtl 1} {-ports_only 0} \
  {-link 0} {-design_root ""} {filename ""}} -type local -desc {
  Post menu to read structural verilog .v file, create top-level chip floorplan.
} {
  global FPLAN _VERILOG_OPT SUFFIX

  set _VERILOG_OPT(filename) [use_first _VERILOG_OPT(filename)]
  use_init FPLAN(design_root) ""
  use_init _VERILOG_OPT(act_read_verilog) 1
  use_init _VERILOG_OPT(act_squish_verilog) 0

  if {$filename == ""} {
    # Interactive use.
    load_options _VERILOG_OPT 1
  } else {
    load_options _VERILOG_OPT 0
  }

  # If the current cell has a verilog_filename prop, display it.
  if {$_VERILOG_OPT(filename) == ""} {
    set old_filename [db_prop verilog_filename]
    if {$old_filename != ""} {
      set _VERILOG_OPT(filename) $old_filename
    }
  }

  if {$filename != ""} {
    set _VERILOG_OPT(filename) $filename
  } else {

    set prop_list ""
    lappend prop_list [list Actions: "" -label]
    lappend prop_list [list "Read Verilog" \
	_VERILOG_OPT(act_read_verilog) -binary \
	-help {You can read any number of verilog files,
	but you should link_verilog only once.}]
    lappend prop_list [list "Link Verilog" \
	_VERILOG_OPT(link) -binary \
	-help {After all verilog files have been read in, you must link\
	starting at the root of the verilog tree before any connectivity
	based operations can be performed.}]
    lappend prop_list [list "Remove demorgans/cells with only one cell"  \
	_VERILOG_OPT(act_squish_verilog) -binary \
	-help {If a module contains only one cell, that level of hierarchy is\
	removed.  The new cell name is created by concatenating the old cell name,\
	an @ symbol, and the old module name.}]
    
    lappend prop_list [list "" "" -separator]
    lappend prop_list [list "Read Verilog Options:" "" -label]

    # Convert list of verilog suffixes into list of patterns for fs_box.
    set verilog_pattern ""
    foreach thingy $SUFFIX(verilog_list) {
      lappend verilog_pattern "*$thingy"
    }

    lappend prop_list [list {Verilog filename} \
	  _VERILOG_OPT(filename) \
	  -filename [list -message {Verilog file to read:} \
	    -pattern $verilog_pattern]]

    lappend prop_list [list "verilog is:" _VERILOG_OPT(rtl) -enum {GATE RTL}]
    lappend prop_list [list "ports only" _VERILOG_OPT(ports_only) -binary]

    lappend prop_list [list "" "" -separator]
    lappend prop_list [list "Link Verilog Options:" "" -label]

    lappend prop_list [list "Name of top level module:" FPLAN(design_root) -entry \
      -help {You must specify a top level cell before doing any operations \
	    that need connectivity information}]


    set title "Chipper: Read Verilog"
    if {![prop_menu2 -title $title $prop_list]} {
      # cancelled
      return
    }
  }

  if {$_VERILOG_OPT(act_read_verilog)} {

    if {$_VERILOG_OPT(filename) == ""} {
      error "no verilog filename specified"
    }

    set read_verilog_flags ""
    if {$_VERILOG_OPT(rtl)} {append read_verilog_flags "-rtl "}
    if {$_VERILOG_OPT(ports_only)} {append read_verilog_flags "-ports_only "}

    msg "Reading verilog file $_VERILOG_OPT(filename)\n"
    nl2_read_verilog -flags $read_verilog_flags $_VERILOG_OPT(filename)
  }

  if {$_VERILOG_OPT(act_squish_verilog)} {
    verilog_squish
  }

  if {$_VERILOG_OPT(link)} {

    if {$FPLAN(design_root) != ""} {
      fplan_link_verilog $FPLAN(design_root)
    } else {
      max_error -buffer "No top level module specified to link!"
    }
  }

  msg "verilog read done\n"
}




# This function is for Jim Ballard to load Juniper verilog file lists.
proc UNUSED_fplan_read_verilog_list {{-flags ""} {-include ""} {filename}} -type local -desc {
    Load all the verilog specified in another file.
} -doc {
    -flags <flags> specifies flags to the underlying nl_read_verilog command.
    -include <filename> includes the specified filename while reading
      every file in the list.
    The filename contains a list of files to be read into verilog.

    If a directory ends in "rtl", add the corresponding directory
    ending in "max" to the cell_path.
} {
    if {$filename == ""} {
        error "no filename"
    }

    set fd [open $filename r]
    unwind_catch {
        while {[gets $fd line] >= 0} {
            set line [string trim $line]
            if {$line == ""} {continue}
            if {[string match "#*" $line]} {continue}

            # Line is a verilog file name.
            nl2_read_verilog -include $include -flags $flags $line

            # If filename is .../rtl/foo.v,  add .../max to cell_path.
            set dir [file dirname $line]
            if {[string match */rtl $dir]} {
                regsub {/rtl$} $dir "" prevdir
                cell_path_add ${prevdir}/max
            }
        }
    } always {
        close $fd
    }

    # Still need to link and import.
}


proc fplan_link_verilog {mod} -type local -desc {
  Set <mod> as the top-level verilog module, and create idesign connectivity data-base.
} -doc {
  Must be called after all verilog is read in, but before any max operations
  that require connectivity information from the nl database.

  This proc calls nl_link and nl_create_idesign.
} {
  global FPLAN
  msg "fplan_link_verilog $mod\n"
  nl_link -silent $mod
  nl_create_idesign $mod
  nl2_set_current_design
  set FPLAN(f_verilog_linked) 1
}


proc _fplan_set_core_grid {{corename ""}} -desc {
  Init the block_grid from specified LEF corename, or default to FPLAN(lef_site)
} {
  # Init the grid.
  global FPLAN LEF_SITES
  if {$corename == ""} {
    set corename [use_first FPLAN(lef_site)]
  }
  if {$corename == "" || $corename == "*undefined*"} {
     set corename CORE1
  }

  if {![info exists LEF_SITES($corename)]} {
    msg "warning: Can not find lef site: $corename to set block grid.  Using default grid\n"
    return
  }

  if {[info exists LEF_SITES($corename)]} {
    set site_info $LEF_SITES($corename)
    set symmetry [get_assoc SYMMETRY $site_info]
    if {$symmetry != "" && $symmetry != "Y"} {
      max_error -buffer "import_verilog: warning: unsupported SYMMETRY $symmetry for LEF SITE $corename is ignored"
    }
    setl {x_size y_size} [get_assoc SIZE $site_info]
    if {$x_size == "" || $y_size == ""} {
      error "import_verilog: error: unrecognized SIZE for LEF SITE $corename"
    }

    # We double the cell placement grid it so cells can by flipped to make the power rails line up.
    set gridname $FPLAN(block_grid)
    setl {x_size y_size} [uusnap -mask $x_size $y_size]
    # If the block-grid does not exist, this will error out:
    if {[catch {grid_set -name $gridname $x_size [expr 2*$y_size] 0 0} errmsg]} {
      msg "grid_set: warning while setting grid from lef CORE SITE: $errmsg\n"
    }
  }
}


proc fplan_check_verilog {{-silent}} -desc {
  Check if we can use the nl database.
} -doc {
  If -silent, just return 1 if ok.
  Otherwise, error out if not ok.
} {
  global FPLAN
  if {![use_first FPLAN(f_verilog_read) '0]} {
    if {$silent} {return 0}
    max_error "No verilog file has been read in yet."
  }

  if {![use_first FPLAN(f_verilog_linked) '0]} {
    if {$silent} {return 0}
    max_error "fplan_link_verilog has not been called"
  }
  return 1
}


proc fplan_import_verilog {{-levels 0} {module ""}} -type local -desc {
  Import a previously read verilog module into max.
} {
  global FPLAN _VERILOG_OPT LEF_SITES SUFFIX


  fplan_check_verilog -silent


  set lef_sites "*undefined*"
  if {[llength [array names LEF_SITES]] == 0} {
    set msg "import_verilog: No LEF SITES defined.  Continue anyway using current placement grid?"
    set choice [tk_dialog .dialog Warning $msg {} 0 Yes Cancel]
    if {$choice != 0} {return}
  } else {
    set lef_sites [array names LEF_SITES]
  }

  # Pop up the import menu.

  use_init _VERILOG_OPT(mod_name) ""

  set top_mods [verilog_find_top]
  if {$module != ""} {
    set _VERILOG_OPT(mod_name) $module
  } elseif {$_VERILOG_OPT(mod_name) == ""} {
    set _VERILOG_OPT(mod_name) [lindex $top_mods 0]
  }

  set vpath [db_prop verilog_path]
  setl {snapx snapy} [res2 $FPLAN(block_grid)]
  # The x grid can be much smaller than y, making the aspect ratio tall and skinny.
  # Make the min size approximately square.
  set block_grid_x [expr floor([max $snapx $snapy]/$snapx) * $snapx]
  set FPLAN(min_block_size) [use_first _VERILOG_OPT(min_block_size)\
	'[expr $block_grid_x * $snapy]]
  use_init _VERILOG_OPT(levels) [expr {($levels > 0) ? $levels : 1000}]
  use_init _VERILOG_OPT(f_uniquify_cells) 0
  use_init FPLAN(small_cells) "pack"
  use_init FPLAN(lef_site) "*undefined*"
  use_init FPLAN(vcreate_dir) "\$v"

  if {$FPLAN(lef_site) == "*undefined*" } {
    # This is the first time through import_verilog.
    # Init FPLAN(lef_site) it to CORE1 if defined, otherwise to any old SITE.
    if {[lsearch $lef_sites CORE1] >= 0} {
      set FPLAN(lef_site) CORE1
    } else {
      set FPLAN(lef_site) [lindex $lef_sites 0]
    }
  }

  if {$module == ""} {
    # Throw up the prop menu

    lappend prop_list [list "Module name to import" \
	  _VERILOG_OPT(mod_name) -popup $top_mods \
	  -help {(required)  The name of the top-level verilog module to\
	  read into the current max cell.}]
    lappend prop_list [list "Number of levels to read" \
	  _VERILOG_OPT(levels) -number 1 \
	  -help {if 1, read only the specified cell.}]
    lappend prop_list [list "Make unique max cell for each verilog instance" \
	  _VERILOG_OPT(f_uniquify_cells) -enum {no yes}]

    lappend prop_list [list "Create max files in directory:" \
	  FPLAN(vcreate_dir) -entry \
	  -help {If set, any created max files are placed in this directory. \
	  $v is replaced with the directory the verilog file for the module was found.}]

    lappend prop_list [list "Minimum Block Size" \
	  FPLAN(min_block_size) -entry \
	  -help {Unrecognized leaf cells will be created with this initial size.}]

    lappend prop_list [list "%utilization" FPLAN(default_area_util) -number 1 100 \
	    -help {used to determine initial block size}]

    lappend prop_list [list "LEF SITE for placement grid" FPLAN(lef_site) \
	  -choice $lef_sites]

    lappend prop_list [list "Small LEF cells" \
	  FPLAN(small_cells) -choice {ignore pack place} \
	  -help {if "ignore", LEF cells that are small enough that they look like stdcells\
	  are not placed in the cell;  if "pack", they are packed together tightly;\
	  if "place", they are placed like other larger cells.}]

    #lappend prop_list [list "Verilog Path to current cell" \
	  vpath -entry -help {\
	  Each verilog instance must have a unique max cell def. \
	  To guarantee uniqueness, we use the verilog path as the max cell def name. \
	  Each max file stores its own verilog path as a property, so we can \
	  reload (merge) verilog at that level using the same path,\
	  without having to read starting at the top of the hierarchy.}]

    lappend prop_list [list "Show Hierarchy..." "" \
	  -button {verilog_new_hier_menu} \
	  -help {Displays the hierarchy, but you cant do anything\
	  interesting with it.}]

    set title "Chipper: Import Verilog"

    while {1} {
      set ret [prop_menu2 -title $title $prop_list]
      if {$ret == 0} {
	# cancelled
	return
      }

      if {$_VERILOG_OPT(mod_name) == ""} {
	max_error "import_verilog: error: No module name specified"
	continue
      }
      break
    }
  }

  # Make sure everything is sucked in first.
  # Otherwise, the import verilog command will create new cells
  # that overwrite the existing.
  # 7/26: try to do this incrementally!
  #msg "import_verilog: sucking in all max files...\n"
  #cell_load_tree
  #msg "import_verilog: sucking step done\n"

  set mod_name $_VERILOG_OPT(mod_name)

  # If user is editing the cell and attempting to read it,
  # the vpath will end with the module name.
  set vpaths [split $vpath $FPLAN(hier_sep_char)]
  if {[lindex $vpaths end] == $mod_name} {
    error "You are attempting to read a verilog cell into itself."
  }

  # We read in the top-level module.  Instantiate each of its instances.
  if {! [nl2_loaded $mod_name]} {
    # OK, lets try to auto-load it.
    set verilog_file [lindex \
	  [cell_path_find -exts $SUFFIX(verilog_list) -report_dups [fplan_fix_name $mod_name]] 0]
    if {$verilog_file == ""} {
      error "Module $mod_name not found"
    }

    # fplan_verilog_auto_load requires a .max extension file, so provide it.
    fplan_verilog_auto_load $verilog_file
  }

  # Make sure it is linked.
  # Note: no longer necessary, because we insist that fplan_link_verilog called first.
  #nl_link -silent $mod_name

  # Dont set the grid on import verilog!!
  # _fplan_set_core_grid

  set FPLAN(hier_apply_to_all) ""
  set FPLAN(hier_ignore_undef) 0
  # This is a list of new cells that we have added.  It is needed so that
  # when you try to create a new cell and it already exists,
  # you know whether you have already created it or not.
  set FPLAN(hier_new_cells) ""

  set top_cell [_fplan_create_hier $vpath $mod_name "" $_VERILOG_OPT(levels)]

  cell_load $top_cell

  # Save the verilog file from which the top-level cell was created.
  # Then if user edits this file later, we can read the same
  # verilog file by default.
  # NOTE: Took out.  This needs to be redone, since the verilog filenames are
  # in the VERILOG_MODULE2FILE array.
  #db_prop verilog_filename $_VERILOG_OPT(filename)
  puts "verilog import done"

  return
}


proc fplan_cell_info {option mod {new ""}} -doc {
  The FPLAN_CELL_INFO stores info about cells that did not appear
  in verilog.  They could be lef cells, or simply undefined cells
  that were referenced in verilog but have not been created yet.

  NOTE: The <mod> is the verilog module name, not the max cell name.
  This should probably be called fplan_mod_info.
} {
  global FPLAN _FPLAN_CELL_INFO
  set info [use_first _FPLAN_CELL_INFO($mod)]
  setl {type xsize ysize} $info
  switch -- $option {
    -define {
      set _FPLAN_CELL_INFO($mod) $new
    }
    -get {
      return $info
    }
    -is_lef {
      return [expr {$type == "lef" ? 1 : 0}]
    }
    -is_undef {
      if {$type == "undef"} {
	# Make sure it is still undefined.  Someone could read some verilog,
	# do an import that sets the type to undef, then read some
	# more verilog that resolves the undef.
	if {[nl2_loaded $mod]} {
	  # Its not undefined any more.
	  catch {unset _FPLAN_CELL_INFO($mod)}
	  return 0
	} else {
	  # Still undefined
	  return 1
	}
      }
      return 0
    }
    -is_hier {
      # This should be equivalent to querying the verilog to find out
      # if it is a sub-design, but this option is called from DEF that
      # does not use nl.
      # Make sure it is not a VIA cell or gcell.
      return [expr {$type != "lef" && $type != "undef" && \
	[string first "VIA" $mod] == -1 && [string first "#" $mod] != 0}]
    }
    -is_small {
      # Size chosen is pretty arbitrarily.  Use height, not width, which varies.
      # Our stdcells should all be smaller than this.
      # Note that size_y is the minimum size * 2 to account for flipping,
      # so stdcells are less than this side.
      setl {grid_x grid_y} [res2 $FPLAN(block_grid)]
      return [expr {$type == "lef" && $ysize < $grid_y}]
    }
    default {
      assert 0
    }
  }
}

#set DEBUG_FILE [open log w]

proc _fplan_add_hidden_labels {cell} {

  # Note: Hidden labels not needed for versions of max after 08/01
  # that support special label names {*center*}, etc.
  return

  edit_push_direct $cell
  sel_labels -kind hidden
  :delete
  edit_pop_direct

  setl {bx1 by1 bx2 by2} [db_bbox -cell $cell]
  setl {cx cy} [uusnap [expr ($bx1 + $bx2) / 2] [expr ($by1 + $by2) / 2]]
  db_label -cell $cell -kind hidden space _hidden_center $cx $cy
  db_label -cell $cell -kind hidden space _hidden_bottom $cx $by1
  db_label -cell $cell -kind hidden space _hidden_top $cx $by2
  db_label -cell $cell -kind hidden space _hidden_left $bx1 $cy
  db_label -cell $cell -kind hidden space _hidden_right $bx2 $cy
}

proc fplan_init_cell {{-size ""} {-module ""} {-vpath ""} cell dir} -doc {
  If <cell> is not in memory, then the <dir> arg specifies the
  directory associated with the cell.  If <dir> is empty, any created
  cell goes in current dir.

  Init props associated with an fplan module.
} {
  global FPLAN CELL

  if {![cell_in_memory $cell]} {
    if {$dir == ""} {
      db_cell_new $cell .
    } else {
      db_cell_new $cell $dir/$cell$CELL(default_suffix)
    }
  }

  # Special case to create max files in Juniper file structure.
  if {0} {
      if {$newdir != "" && $module != ""} {
	# Create in the dir found by appending $special the the verilog directory.
	set fn [use_first VERILOG_MODULE2FILE($module)]
	set dir [file dirname $fn]
	if {$newdir == "."} {
	  set outdir $dir
	} else {
	  set outdir [file join $dir $newdir]
	}
	cell_change_path -cell $cell $outdir
      }
  }

  db_prop -def $cell module $module
  # The verilog_path would have to be an instance prop, not a def prop.
  #db_prop -def $cell verilog_path $vpath
  db_prop -def $cell grid $FPLAN(block_grid)

  db_prop -def $cell area_util $FPLAN(default_area_util)

  if {$size != ""} {
    # add prb layer
    setl {sizex sizey} $size
    set prb_layer [techinfo layer prb]
    db_paint -cell $cell $prb_layer 0 0 $sizex $sizey
  }
}

proc _fplan_create_hier {vpath top_mod mod_inst levels} -desc {
  Create <levels> hierarchy starting at <top_mod>.  Return top cell name.
} -doc {
  vpath is the verilog path from top of design to current cell
  top_mod is verilog module def name
  mod_inst is verilog instance name, or empty if creating new.
  levels is how many levels deep in recursion
} {
  global CELL FPLAN SUFFIX _FPLAN_CELL_INFO _VERILOG_OPT global VERILOG_MODULE2FILE

  if {$levels <= 0} {return}
  incr levels -1

  set grid $FPLAN(block_grid)
  setl {snapx snapy} [res2 $grid]
  if {$snapx == ""} {
    error "grid $grid not defined"
  }

  # New: cell name defaults to module name, with bad characters fixed.
  set top_cell [fplan_fix_name $top_mod]

  # Logic below tries to figure out what kind of cell it is.
  # Here are our choices.
  # cell defined in LEF.
  # cell is a special RTL cell (eg, used to implement verilog assign statement) - ignored.
  #    (this check is done by the caller when the cell instance is encountered)
  # cell defined in verilog.
  # cell undefined.

  if {[fplan_cell_info -is_lef $top_mod]} {
    # Lef cells are treated totally differently.  We assume the cell is
    # either a stdcell or a hard macro, with pins already assigned.
    # Therefore, each instance is not unique, but is just an instance
    # of a pre-existing cell.
    # Only trick is that the cell might not exist if it is a ram or something.
    # Should give the user the opportunity to create it from the verilog.
    while {1} {
      if {$FPLAN(small_cells) == "ignore" && [fplan_cell_info -is_small $top_mod]} {
	return ""  ;# Causes caller to ignore this cell.
      }
      if {[cell_in_memory $top_cell]} {
	return $top_cell
      }

      set locations [cell_path_find $top_cell]
      if {$locations != ""} {
	if {[llength $locations] != 1} {
	  msg "Warning: cell $top_cell found in multiple locations (using first): $locations\n"
	}
	cell_load_file [lindex $locations 0]
	return $top_cell
      }

      if {[use_first FPLAN(hier_ignore_undef_lef) '0]} {
	# Note: This fails if top level contains only a stdcell, but who cares
	return ""  ;# Causes caller to ignore this cell.
      }
      set msg "Max cell for LEF cell $top_mod not found on disk.  What to do?"
      set choice [prop_dialog -buttons {Ignore Ignore_all \
	  "Search for Cell" Cancel} $msg]
      switch -- $choice {
	"Cancel" {
	  error "Warning: operation cancelled while in progress."
	}
	"Ignore" {
	  return ""
	}
	"Ignore_all" {
	  set FPLAN(hier_ignore_undef_lef) 1
	  return ""
	}
	"Search for Cell" {
	  set file [fs_box -dironly -message "Find stdcell $top_mod" -pattern "*.max"]
	  if {$file == ""} {
	    error "Warning: operation cancelled while in progress."
	  }
	  if {[file isdirectory $file]} {
	    cell_path_add $file
	  } else {
	    cell_path_add [file dirname $file]
	  }
	  continue  ;# See if cell really found in user specified directory.
	}
	default {
	  error "internal switch error"
	}
      }
    }
  }

  # Make sure any prior existing cell is read in, so we will preserve
  # the directory where it previously resided, and so we will be able
  # to merge changes into existing cell, if requested.

  # First, see if we can find an existing max file on the cell path.
  set top_cell_file [lindex [cell_path_find -report_dups $top_cell] 0]

  if {$top_cell_file != ""} {
    # Max file found.  This reads in both the .max and the verilog in the same dir.
    cell_load_file $top_cell_file
  } else {
    # Did not find a .max file, has the verilog module already been loaded?
    # If so, this is the location where its file was found.
    set verilog_file [use_first VERILOG_MODULE2FILE($top_mod)]

    if {$verilog_file == ""} {
      # Verilog module not already loaded.  See if we can find a verilog
      # file on the cell path with this name, and read it in.
      set verilog_file [lindex \
	  [cell_path_find -exts $SUFFIX(verilog_list) -report_dups $top_cell] 0]
      if {$verilog_file != ""} {
	# fplan_verilog_auto_load requires a .max extension file, so provide it.
	fplan_verilog_auto_load $verilog_file
      }
    }

    if {$verilog_file != ""} {
      set top_cell_file [file rootname $verilog_file]$CELL(default_suffix)
    } else {
      # Neither max nor verilog file found on path.
    }
  }
  
  # The prev_undef is set if we have already seen an instance of this undefined module before.
  set prev_undef [fplan_cell_info -is_undef $top_mod]
  set is_undef [expr {[nl2_loaded $top_mod] == 0}]

  if {! $is_undef} {

    # Jim Ballard painstakingly marked all the RTL-specific cells in the ng design,
    # with nl_is_libcell, and doesnt want that stuff to appear in max.
    # So if the algorithm for creating cells is:
    #  if it is LEF, it is a stcell or ram or something;
    #  else if it is a libcell, it is a nothing, ignore it.
    if {[nl_is_libcell $top_mod]} {return ""}
  }


  # If all cells are to be unique, uniquify the name now.
  if {$_VERILOG_OPT(f_uniquify_cells)} {
    set top_cell [_fplan_find_unique_cell_name $top_cell]
    lappend FPLAN(hier_new_cells) $top_cell
  } else {
    # If we already read it in during this invocation of read_verilog,
    # use the cell we already created.
    if {[lsearch -exact $FPLAN(hier_new_cells) $top_cell] >= 0} {
      # Use cell we built previously.
      return $top_cell
    } else {
      lappend FPLAN(hier_new_cells) $top_cell
    }
  }

  # In the floorplan view, each verilog instance may be unique, but maybe not.
  # We will start by making one max cell for all instances.
  # Later on, user may uniquify instances, which will also optionally
  # affect all the hierarchy below that point.
  # At level 1 (top level in design) there may not be an mod_inst.
  # If no instance name specified, use the module def name.


  if {$mod_inst != ""} {
    if {$vpath != ""} {
      append vpath $FPLAN(hier_sep_char)
    }
    append vpath [fplan_fix_name $mod_inst]
  }


  # The prev_undef keeps us from asking this question multiple times.
  if {$is_undef && ! $prev_undef} {
    # Module not defined in verilog or lef.
    # We could just go ahead and build a block anyway,
    # but we dont know port type (input/output) or how to hook it up.
    # jdj wants to create with i/o ports.  Guess it needs to be an option.


    max_error -buffer "import_verilog: warning: verilog module ${top_mod} not defined; creating empty cell."

    # 7/3: take this message out, replace with above warning.
    if {0} {
      if {![use_first FPLAN(hier_ignore_undef) '0]} {
	set choice [prop_dialog -buttons "Ignore Ignore_all Cancel" \
	   "Verilog module ${top_mod} not defined."]
	if {$choice == "Cancel"} {
	  error "Warning: operation cancelled while in progress."
	}
	if {$choice == "Ignore_all"} {
	  set FPLAN(hier_ignore_undef) 1
	}
      }
    }

    # Verilog module does not exist.
    # Should probably read it from a .lef somewhere,
    # but for now, just create an empty cell.
    # By doing this, we suppress any further messages for this cell.
    #_verilog_init_cell $top_mod undefined
    set _FPLAN_CELL_INFO($top_mod) "undef"
    set is_undef 1
    set levels 0
  }


  # This assignment is so you can use $v in FPLAN(vcreate_dir)
  set v [file dirname $top_cell_file]
  set createdir [subst -nobackslashes -nocommands $FPLAN(vcreate_dir)]


  # Load existing max cell, or create a new one.
  # Search not needed because we already loaded existing cell, above.
  #catch {cell_load -search $top_cell}
  fplan_init_cell -module $top_mod -vpath $vpath $top_cell $createdir

  if {$is_undef} {
    db_prop -def $top_cell verilog_flags "undefined"
    # Create prb of default minimum sized cell:
    _fplan_create_prb $top_cell
    _fplan_add_hidden_labels $top_cell
    return $top_cell
  }

  set is_empty [cell_empty $top_cell]

  set action [use_first FPLAN(hier_apply_to_all) 'create]
  if {! $is_empty} {
      if {$FPLAN(hier_apply_to_all) =="" } {
	set prop_list ""
	lappend prop_list [list "Action:" action -radio [list \
	  {Overwrite existing cell} {Merge changes into existing cell} \
	  {Create new cell with new name}] \
	  -values {create merge rename}]
	set apply_to_all 0
	lappend prop_list [list "Apply to all" apply_to_all -binary]
	set msg "Warning: cell $top_cell already exists."
	if {[prop_menu2 -message $msg $prop_list] == 0} {
	  error "Warning: operation canceled in progress. \
	  Changes before cancellation not undone."
	}
	if {$apply_to_all} {
	  set FPLAN(hier_apply_to_all) $action
	}
      }

      switch -- $action {
	"create" {
	  # overwrite existing cell.
	  db_cell_clear $top_cell

	  # This creates the max cell only if it did not previously exist.
	  fplan_init_cell -module $top_mod -vpath $vpath $top_cell $createdir
	}
	"rename" {
	  for {set i 1} {1} {incr i} {
	    set top_cell ${top_mod}_$i
	    if {[cell_empty $top_cell]} {break}
	  }
	}
	"merge" {
	  # handled below
	}
      }
  }

  msg "import_verilog: $action cell $top_cell for verilog module $top_mod\n"

  # Build tree from bottom up.
  if {$levels > 0} {

    # Step one: create hierarchy below.
    # Keep a list of small and large cells to be placed.
    set small_cells ""
    set large_cells ""

    if {$action == "merge"} {
      foreach cell_info [db_search_l cells -cell $top_cell] {
	set prev_cells([cellinfo_id $cell_info]) 1
      }
    }

    foreach modi [nl2_list_cells $top_mod] {
      set subdef [nl2_get_cell_ref $top_mod $modi]
      catch {unset prev_cells([fplan_fix_name $modi])}


      # Nl creates *assignment* cells for assign statements, and *process* cells
      # for RTL verilog.  We want to ignore both.
      # Check to see if top_mod was defined in .lef file.
      if {[nl2_is_rtl_cell $subdef]} {
	# Ignore this.  It is a dummy cell inserted by nl.
	continue
      }

      # This creates the cell for all contained hierarchy and returns it.
      set cell [_fplan_create_hier $vpath ${subdef} ${modi} $levels]
      
      if {$cell == ""} {
	# This happens if a lef cell was not found.  Ignore it and keep going.
	continue
      }

      if {[fplan_cell_info -is_lef ${subdef}]} {
	setl {sx1 sy1 sx2 sy2} [eval uusnap [fplan_bbox -cell $cell]]
      } else {
	setl {sx1 sy1 sx2 sy2} [eval uusnap -grid $grid -ceil [fplan_bbox -cell $cell]]
      }
      set x_size [expr $sx2 - $sx1]
      set y_size [expr $sy2 - $sy1]
      if {[fplan_cell_info -is_small ${subdef}]} {
	lappend small_cells [list $modi $subdef $cell $x_size $y_size]
      } else {
	lappend large_cells [list $modi $subdef $cell $x_size $y_size]
      }
    }

    if {[array size prev_cells] != 0} {
      set msg "Cell $top_cell: The following max cell instances do not exist in verilog.  "
      append msg "Delete the max cells?\n[array names prev_cells]"
      if {"Yes" == [prop_dialog -buttons "Yes No" $msg]} {
	# Delete the suckers that are no longer in the verilog.
	edit_push_direct $top_cell  ;# What a choke
	unwind_catch {
	  foreach celli [array names prev_cells] {
	    sel_cell $celli
	    :delete
	  }
	} always {
	  edit_pop_direct
	}
      }
    }

    switch -- $FPLAN(small_cells) {
      "place" {
	# Place small cells like normal cells.
	set large_cells [concat $large_cells $small_cells]
	set small_cells ""
      }
      "pack" {
	# Pack small cells after large cells.
      }
      "ignore" {
	# Dont place the small cells.
	set small_cells ""
      }
    }

    # Place the large cells

    set big_cnt [llength $large_cells]
    set cells_per_row(big) [expr int(ceil(sqrt($big_cnt)))]
    set max_row_y 0
    set big_cell_max_x 0
    set cnt 0
    set cx 0
    set cy 0

    foreach thing $large_cells {
	setl {modi subdef cell x_size y_size} $thing

	if {$action == "merge"} {
	  # If an instance already exists, leave it alone.
	  if {[db_instances_l -cell $top_cell -id [fplan_fix_name $modi]] != ""} {
	    continue ;# already exists.
	  }
	  msg "merge verilog creating $modi in $top_cell\n"
	}

	db_instance -id [fplan_fix_name ${modi}] -cell $top_cell $cell $cx $cy
	set vflags [db_prop -def $cell verilog_flags]
	if {[memq $vflags "undefined"]} {
	  lay_cell_text -cell $cell "" "undefined:${subdef}"
	}
	set cx [expr $cx + $x_size + $snapx]
	set big_cell_max_x [max $big_cell_max_x $cx]
	set max_row_y [max $max_row_y $y_size]

	incr cnt
	if {$cnt % $cells_per_row(big) == 0} {
	  set cx 0
	  set cy [expr $cy + $max_row_y]
	  set max_row_y 0
	}
    }

    # Place the small cells.
    # Place them to the right of everything else, I guess.

    set small_cnt [llength $small_cells]
    set cells_per_row(small) [expr int(ceil(sqrt($small_cnt)))]
    set max_row_y 0
    set cnt 0
    set cx $big_cell_max_x
    set cy 0
    foreach thing $small_cells {
	setl {modi subdef cell x_size y_size} $thing

	if {$action == "merge"} {
	  # If an instance already exists, leave it alone.
	  if {[db_instances_l -cell $top_cell -id [fplan_fix_name $modi]] != ""} {
	    continue ;# already exists.
	  }
	  msg "merge verilog creating $modi in $top_cell\n"
	}

	db_instance -id [fplan_fix_name ${modi}] -cell $top_cell $cell $cx $cy
	set vflags [db_prop -def $cell verilog_flags]
	if {[memq $vflags "undefined"]} {
	  lay_cell_text -cell $cell "" "undefined:${subdef}"
	}
	set cx [expr $cx + $x_size]
	set max_row_y [max $max_row_y $y_size]

	incr cnt
	if {$cnt % $cells_per_row(small) == 0} {
	  set cx $big_cell_max_x
	  set cy [expr $cy + $max_row_y]
	  set max_row_y 0
	}
    }
  }

  # Add prb if the cell was just created, or if merging and no prb previously.
  set prb_paint [eval db_search_l paint -cell $top_cell -area [db_bbox -cell $top_cell] -limit 1 prb]
  if {$action != "merge" || [llength $prb_paint] == 0} {

    # Set size from contained cells.
    set area [fplan_get_lef_area -lef $top_cell]
    db_prop -def $top_cell min_area $area

    # Paint its prb.
    # This may make the cell larger.
    _fplan_create_prb $top_cell
  }

  # Create ports in cell we just created.
  # This merges new ports with ones already there.
  _fplan_ver_merge_pins $top_cell $top_mod

  _fplan_add_hidden_labels $top_cell

  return $top_cell
}

proc _fplan_create_prb {{-max} cell} -desc {
  Add in the prb layer for a new cell.
} -doc {
  If -max, make it big enough to hold the prbs of contained cells.
} {
  global FPLAN FPLAN_PROPS_TMP
  set grid $FPLAN(block_grid)
  setl {snapx snapy} [res2 $grid]

  set area_util [db_prop -def $cell area_util]
  if {$area_util == ""} {set area_util 100}

  # req_area is the required minimum area = lef contents * utilization.
  set min_area [db_prop -def $cell min_area]
  if {$min_area == ""} {
    set min_area 0
  }

  # The *100 is because area_util is in percent.
  set req_area [expr $min_area * 100.0 / $area_util]
  set req_area [max $req_area $FPLAN(min_block_size)]

  # Not using this code:
  if {$max} {

    # Using the lef to determine the cell size is insufficient in two cases:
    # 1. For top-down design, some sub-cells might not have been read in yet,
    # but the user might still have given them a size, which we must use.
    # 2. Need to multiply times the utilization at each level, so upper cells
    # in hierarchy need to get bigger and bigger as you go up.
    #
    # Note that stdcell bboxes overlap their prb layer a little.
    # So if we use the cell bbox as the base for making the prb
    # in this cell, it will be pushed out an entire additional unit
    # in all four directions.  Instead look at prb of all contained cells.
    # This is gross.
    edit_push_direct $cell
    eval lay_box [lay_bbox]
    catch {lay_internals -area}
    eval sel_area -layers prb -any_cell -no_poly -no_wp -no_labels [lay_bbox]
    setl {bx1 by1 bx2 by2} [db_bbox -cell __SELECT__]
    # Un-expose cell contents.
    eval lay_box [lay_bbox]
    lay_internals -area -hide
    edit_pop_direct
    sel_clear

    # Make sure size is not 0.
    if {[approx $bx1 == $bx2]} { set bx2 [expr $bx1 + 1] }
    if {[approx $by1 == $by2]} { set by2 [expr $by1 + 1] }

    # Snap lower left corner down to next grid.
    setl {bx1 by1} [uusnap -floor -grid $grid $bx1 $by1]
    # Snap upper right corner up to next grid.
    setl {bx2 by2} [uusnap -ceil -grid $grid $bx2 $by2]
  } else {
    set bx1 0  ;# put prb origin at 0,0
    set by1 0

    # We want it to be roughly rectangular.
    # Since the block grid height is more, set the width
    # the same as the height, snapped to the x grid.
    # NOTE: The two 'snapy' below are not an error!
    setl {bx2 by2} [uusnap -grid $grid $snapy $snapy]
  }

  # Erase old prb, if any.
  eval db_paint -cell $cell -erase prb [db_bbox -cell $cell]

  set sizex [expr $bx2 - $bx1]
  set sizey [expr $by2 - $by1]
  setl {sizex sizey} [uusnap -ceil -grid $grid $sizex $sizey]


  # Make sure area is at least minimum required.
  # If not, make it bigger, keeping it roughly square.
  if {[approx [expr 1.0 * $sizex * $sizey] < $req_area]} {
    # Set X or Y first depending on which has the larger grid.
    # Then expand the smaller gridded dimension to fill it out.
    if {$snapx <= $snapy} {
      set sizey [round_list_scale [expr [max $sizey sqrt($req_area)]] $snapy]
      # Must not be 0.
      set sizey [max $sizey $snapy]
      set sizex [round_list_scale [expr $req_area/$sizey] $snapx]
      set sizex [max $sizex $snapx]
    } else {
      set sizex [round_list_scale [expr [max $sizex sqrt($req_area)]] $snapx]
      set sizex [max $sizex $snapx]
      set sizey [round_list_scale [expr $req_area/$sizex] $snapy]
      set sizey [max $sizey $snapy]
    }
  }

  #while {[approx [expr 1.0 * $sizex * $sizey] < $min_area]} {
  #  set sizex [expr $sizex + $snapx]
  #  if {1.0 * $sizex * $sizey < $min_area} {
  #    set sizey [expr $sizey + $snapy]
  #  }
  #}


  db_paint -cell $cell prb $bx1 $by1 [expr $bx1 + $sizex] [expr $by1 + $sizey]
}

proc UNUSED_fplan_prop {args} -desc {
  Add/query/delete a prop attached to an object in a cell.
} -doc {
  USAGE:
  fplan_prop [-def cell] [-delete] object [name [value]]

  Notes: properties are stored in the cell def as object@name
} {
  set options {{def ""} {delete}}
  set argv [call_keyword $args $options]
  setl {object name value} $argv
  if {$def ==""} {set def [lay_editcell]}
  if {$delete} {
    if {[llength $argv] != 2} {
      error "fplan_prop syntax"
    }
    db_prop -def $def -delete ${object}@${name}
  } else {
    switch [llength $argv] {
      1 {
	# Return names of all props for object
	set propnames ""
	foreach prop [split [string trim [db_prop -def $def] \n] \n] {
	  if {[regexp "^$object@(.*)\$" $prop junk name]} {
	    lappend propnames $name
	  }
	}
	return $propnames
      }
      2 {
	# Return specified prop for object
	return [db_prop -def $def ${object}@${name}]
      }
      3 {
	# Set prop for object
	db_prop -def $def ${object}@${name} $value
      }
      default {error "fplan_prop syntax"}
    }
  }
}


proc fplan_db_cell {action cell} {
  global FPLAN
  switch -- $action {
    #is_leaf {
    #  # Given the cell def, return TRUE if there are no child cells.
    #  set kids [db_search_l cells -cell $cell -limit 2]
    #  return [expr [llength $kids] == 0]
    #}
    modi2cell {
      # Given the verilog instance name (as opposed to the cell inst name)
      # in the current cell, return the max cell def name.
      # The cell def name was originally derived from the verilog instance
      # name so we dont have to look anything up.
      #set topmod [fplan_db_cell module [lay_editcell]]
      #set mod [nl2_get_cell_ref $topmod $cell]

      set mod_inst [fplan_fix_name $cell]  ;# Input param is verilog instance name.
      # Change verilog hierarchy (.) to max hierarchy (/)
      regsub -all "\\[verilog_hier_char]" $mod_inst "/" mod_inst

      set def [cell_id2cell $mod_inst]
      return $def

      if {$def != "" && [fplan_cell_info -is_lef $def]} {
	# Lef cells are normal: there is a single cell def for all,
	# and the verilog instance name is the cell id (after munging for bad chars)
	return $def
      } else {
	set ch $FPLAN(hier_sep_char)
	# Each verilog instance has a unique cell def, so we dont
	# even have to search for it.  Just return it.
	return [db_prop verilog_path]${ch}[fplan_fix_name ${cell}]
      }
    }
    #mod2cell {  ;# NOT USED!
      # Given the verilog module name (as opposed to the cell def name)
      # return the cell def name.
    #  set ch $FPLAN(hier_sep_char)
    #  return [db_prop verilog_path]${ch}[fplan_fix_name ${cell}]
    #}
    modi2celli {
      # Given the verilog instance name (as opposed to the cell inst name),
      # return the cell instance name.
      set result [fplan_fix_name $cell]
      # Handle hierarchical names: translate . (verilog) to / (max)
      regsub -all "\\[verilog_hier_char]" $result "/" result
      return $result
    }
    celli2modi {
      # Return verilog module instance name for this cell instance.

      return [fplan_unfix_name $cell]

      # OLD:
      # Need to peel off the hierchical path
      set mod_inst $cell
      set celldef [cell_id2cell [fplan_fix_name $mod_inst]]
      if {[fplan_cell_info -is_lef $celldef]} {
	# The verilog instance name and cell instance names are the same,
	# except for munging for legality.
	return [fplan_unfix_name $mod_inst]
      } else {
	set ch $FPLAN(hier_sep_char)
	set cell1 [lindex [split $celldef $ch] end]
	return [fplan_unfix_name $cell1]
      }
    }
    module {  ;# Should be called cell2mod
      # Return verilog module def name for this cell.
      if {[fplan_cell_info -is_lef $cell]} {
	# Module name is just the cell def name.
	return [fplan_unfix_name $cell]
      } else {
	if {[msg_catch {db_prop -def $cell module} mod junk junk] || $mod == ""} {
	  # No cells read from def have module props, and I
	  # dont want a zillion of these messages.
	  #max_error -buffer "warning: no module specified for cell $cell, assuming same name as cell"
	  set mod [fplan_unfix_name $cell]
	}
	return $mod
      }
    }
    list {
      # List all cells
      set cell_list ""
      foreach cell_info [db_search_l cells -cell $cell] {
	struct max_cell c $cell_info
	lappend cell_list ${c.def}
      }
      return $cell_list
    }
    #xform {
    #  struct max_cell c [db_instances_l -id $cellid]
    #  return ${c.transform}
    #}
    default {
      error "fplan_db_cell unrecognized action: $action"
    }
  }
}


proc fplan_dspf_setup {{-nomenu} {filename ""}} {
  global TIMING_DATA SUFFIX

  # Pick m3 for wire RC initial values.

  _fplan_init_rc
  # Set min_rc to 0 to avoid extraneous warnings from primetime about
  # the inputs that are left floating if you set this option.
  # (The way it works is that nets with less than this RC are reduced
  # to a capacitor at the output, with connected inputs left floating.)
  use_init TIMING_DATA(dspf_min_rc) 0
  use_init TIMING_DATA(flat) 0

  if {$filename == ""} {
    set filename [lay_editcell]$SUFFIX(dspf)
  }
  set TIMING_DATA(spf_file) $filename

  if {!$nomenu} {
    set prop_list ""
    lappend prop_list [list "DSPF file" TIMING_DATA(spf_file) -entry]

    lappend prop_list [list "Rw (ohm/micron)" TIMING_DATA(Rw) -label]
    lappend prop_list [list "Cw (fF/micron)" TIMING_DATA(Cw) -label]
    lappend prop_list [list "Modify Rw, Cw..." "" -button _fplan_set_rc_menu]
    lappend prop_list [list "min_rc (ps)" TIMING_DATA(dspf_min_rc) -number]
    lappend prop_list [list "flatten" TIMING_DATA(flat) -binary]
    prop_menu2 -title "DSPF Setup" $prop_list
  }
}



proc fplan_write_dspf {{-flat ""} {-cell ""} {filename ""}} {
  global FPLAN TIMING_DATA _VERILOG_OPT SUFFIX 
  global nl_hiearchy_separator

  fplan_check_verilog

  set show_menu [expr {$filename==""}]

  # Init TIMING_DATA variables needed for fplan_write_dspf
  fplan_dspf_setup -nomenu $filename

  if {$cell==""} {set cell [lay_editcell]}

  set curmod [fplan_db_cell module $cell]
  #set nl_current_design $curmod

  set hch [verilog_hier_char]
  nl "set nl_hierarchy_separator $hch"

  if {![nl2_loaded $curmod]} {
    error "write_dspf: no verilog read in for module $curmod (cell $cell)"
  }

  if {$show_menu} {
    set prop_list ""
    lappend prop_list [list "Read Verilog..." "" -button fplan_read_verilog]
    #lappend prop_list [list "flatten" flat -binary]
    lappend prop_list [list "DSPF Setup..." "" -button fplan_dspf_setup]
    lappend prop_list [list "output file" TIMING_DATA(spf_file) -entry]
    set title "Chipper: Read Verilog"
    if {![prop_menu2 -title $title $prop_list]} {
      # cancelled
      return
    }
  }
  set filename $TIMING_DATA(spf_file)
  set flat [use_first flat TIMING_DATA(flat) '1]

if {0} {
  if {$flat} {
    set root [use_first FPLAN(design_root)]
    if {$root == ""} {
      # We can only nl_create_idesign on one block, and this is it!
      set FPLAN(design_root) $root
    } elseif {$cell != $root} {
      max_error -buffer "Current cell is not the design root.  Change it in the Chipper SetUp menu"
      msg_flush
      return
    }
    nl_create_idesign [fplan_unfix_name $cell]
  }
}

  msg "Writing dspf for $cell to $filename...\n"

  # Need pats version to fix small bugs in steiner_package.
  util_load_pkg pats_steiner_package.so Steiner_package

  # open dspf output file
  set fd [open $filename "w"]
  edit_push_direct $cell
  unwind_catch {

    # dspf header
    puts $fd "*|DSPF 1.5"
    puts $fd "*|DESIGN \"$cell\""
    puts $fd "*|DATE \"[clock format [clock seconds]]\""
    puts $fd "*|VENDOR \"Micro Magic, Inc.\""
    puts $fd "*|PROGRAM \"Max Floorplanner\""
    puts $fd "*|DIVIDER /"
    puts $fd "*|DELIMITER :"
    puts $fd "*|BUSBIT \[\]\n"
    puts $fd ".SUBCKT $cell\n"

    puts $fd "*|GROUND_NET VSS"
    flush $fd

    # This is what sue uses:
    #$output_file_cmd $DPC_CAP(FILE_ID) -rconstx $res_xscale \
    #	-rconsty $res_yscale -cconstx $cap_xscale -cconsty $cap_yscale \
    #	-min_rc [parse_pp_number $DPC(MIN_RC)]

    steiner_output_file $fd \
	  -dup \
	  -rconstx $TIMING_DATA(Rw) \
	  -rconsty $TIMING_DATA(Rw) \
	  -cconstx $TIMING_DATA(Cw) \
	  -cconsty $TIMING_DATA(Cw) \
	  -min_rc [parse_pp_number $TIMING_DATA(dspf_min_rc)]


    # Bug fix was that steiner function did not save strings.  Fixed now
    # in pats version of steiner code.
    #set bugfix 1

    # Cache current labels and cell transforms.

    if {$flat} {
      # Flatten nl data-base.
      # Jay says explicit create_idesign is not needed if you nl_list_nets -hiearchy.
      # But we will do it explicitly to catch errors.
if {0} {
      nl2_flatten $curmod
}
      # If using an nl server, the nlnets variable is kept on the server.
      set numnets [llength [nl "set nlnets \[nl_list_nets -hierarchy -noassign -noconstant $curmod\]"]]
      # db_cache does not work more than one level deep, so dont use it.
      #fplan_db_cache -cells 1 -cell $cell
    } else {
      set numnets [llength [nl "set nlnets \[nl_list_nets -noassign -noconstant $curmod\]"]]
      #fplan_db_cache -all -cells 1
    }

    # The idea is:
    #   foreach net
    #     speedy_begin_net
    #     foreach port
    #       speedy_add_point
    for {set n 0} {$n < $numnets} {incr n} {
      # Each pin-name is subcell${hch}pin or a top-level port with no $hch.
      # nl_get_pins can return an empty list for an unconnected wire.
      if {$flat} {
	# The pin names can have multiple hierarchical levels.
	# Eg: shift8.MMI_BUFD$1$.out
	set pins [nl "nl_get_net_pins -hierarchy -noassign \[lindex \$nlnets $n\]"]
      } else {
	set pins [nl "nl_get_net_pins \[lindex \$nlnets $n\]"]
      }
      set cap_fudge 0
      if {[llength $pins] > 0} {
	#steiner_begin_net [set save([incr bugfix]) $nlnet]
	set nlnet [nl "lindex \$nlnets $n"]
	#puts "steiner_begin_net $nlnet"
	steiner_begin_net $nlnet

	foreach pin_name $pins {
	  if {$flat} {
	    setl {lx ly iodir curlayer text} \
		  [fplan_db_pin2 -xform -fixname $pin_name]
	  } else {
	    setl {lx ly iodir curlayer text} \
		  [fplan_db_pin2 -xform -fixname $pin_name]
	  }
	  set i [string last $hch $pin_name]
	  if {$i == -1} {
	    set lab $pin_name
	    set modpath ""
	  } else {
	    set modpath [string range $pin_name 0 [expr $i-1]]
	    regsub -all {\.} $modpath / modpath
	    set lab [string range $pin_name [expr $i+1] end]
	  }
	  # It does not take floating point, so round off the location.  Within a micron is close enough.
	  #puts "steiner_add_point $modpath $lab $iodir [expr int($lx)] [expr int($ly)]"
	  steiner_add_point $modpath $lab $iodir [expr int(round($lx))] [expr int(round($ly))]
	}
	#puts "steiner_end_net $cap_fudge"
	steiner_end_net $cap_fudge
	#catch {unset save}
      }
    }

    puts $fd ".ENDS"
    steiner_close_file $fd
  } always {

    close $fd
    edit_pop_direct

  }
  msg "write dspf done\n"
}


proc misc_text_edit {args} {
  global OPTIONS EDITOR

  set editor [use_first OPTIONS(editor) EDITOR env(EDITOR) env(VISUAL) 'vi]

  eval exec xterm -e "$editor $args"
}

proc _fplan_flyline_ignore {net} -desc {
  return TRUE if flylines should not be drawn for this net.
} {
  global FPLAN
  foreach pat $FPLAN(flyline_ignore) {
    if {[string match $pat $net]} {return 1}
  }
  return 0
}

proc fplan_show_flylines {{-all} {cellid ""} {celldef ""}} -desc {
  Draw flylines for specified cell, or -all flylines, or selected cell.
} -doc {
  Note: both id and def passed just to save us having to look up def given id.

  Action depends on FPLAN(flyline_cells)
  if FPLAN(flyline_cells) != "individual",
  we do not show individual flylines for each pin.  
  We will show a single flyline to each region (typically each side)
  of any pair of connected blocks.
  Create array: fplan_bundles, with index a pair of pins
  between blocks, and with contents the list of nets in the bundle.
} {
  global FPLAN _FPLAN_FLYLINE_CACHE DB_FLYLINES_SAVE

  set DB_FLYLINES_SAVE 0  ;# Dont save these flylines in a file.

  set hch [verilog_hier_char]
  set topmod [fplan_db_cell module [lay_editcell]]


  # This was overly restrictive:
  #if {![fplan_check_verilog -silent]} { return }

  # If no verilog for current edit cell, then no connectivity information,
  # and we cant draw any flylines.  abort now, because nl calls will fail.
  if {![nl2_loaded $topmod]} {
    return
  }

  # Link now, in case it hasnt been done yet.
  nl_link -silent $topmod

  #_fplan_cell2id -init
  if {$cellid == ""} {
    if {$all} {
      # Show flylines for all cells.
      foreach thing [db_search_l cells] {
	struct max_cell c $thing
	fplan_show_flylines ${c.id} ${c.def}
      }
      return
    } else {
      # Show flylines for selected cells.
      foreach thing [sel_what_l cells] {
	struct max_cell c $thing
	fplan_show_flylines ${c.id} ${c.def}
      }
      return
    }
  }

  # This stuff would be easy to cache if it is too slow:
  #set label_list [db_search_l labels -non_hier -cell $celldef]
  #set last_key [list $FPLAN(flyline_mode) $FPLAN(flyline_cells) $label_list]
  #
  #if {[use_first _FPLAN_FLYLINE_CACHE($celldef,$cellid,key)] == $last_key} {
  #  # Use cache.
  #  foreach flyline $_FPLAN_FLYLINE_CACHE($celldef,$cellid,flylines) {
  #  }
  #}

  #if {$mod == "" || ![nl2_loaded $mod]}
  set mod [fplan_db_cell module $celldef]
  if {$mod == ""} {
    max_error -buffer "fplan warning: verilog module $mod for cell: $celldef has not been read in"
    # nl2 will fail if no verilog for module, which is true for lef cells,
    # but we can keep going and just query the max data-base for port info.
    return
  }

  #if {![nl2_loaded $mod]} {
  #  if {[fplan_cell_info -is_lef $mod]} {
  #    max_error -buffer "fplan warning: can not display connectivity for lef-only cells"
  #    # TODO: We should query the max data-base for port info.
  #  } else {
  #    max_error -buffer "fplan warning: can not display connectivity for lef-only cells"
  #  }
  #  return
  #}

  set modi [fplan_db_cell celli2modi $cellid]

  if {$FPLAN(flyline_cells) == "individual"} {

    # One flyline for each individual wire.
    foreach porta [fplan_db_pin_list -cell $celldef] {
      set term1 $cellid/$porta
      set net [nl2_get_pin_net $topmod "${modi}${hch}[fplan_unfix_name -label ${porta}]"]
      if {$net == ""} {
	# The pin was defined in the verilog module but was left unconnected
	# when the verilog instance was instantiated.
	continue
      }
      if {[_fplan_flyline_ignore $net]} {continue}
      foreach pin_name [nl2_get_net_pins $topmod $net] {
	if {[string first $hch $pin_name] == -1} {
	  # It is a connection to a top-level port in the edit-cell.
	  set term2 $pin_name
	} else {
	  setl {modib pinb} [split $pin_name $hch]
	  # Skip connections from cell to itself
	  if {$modib == $modi} {continue}
	  set cellidb [fplan_db_cell modi2celli $modib]
	  set term2 $cellidb/[fplan_unfix_name -label $pinb]
	}
	db_flyline $term1 $term2
      }
    }
    return
  }

  if {[cell_flags $celldef] == ""} {
    msg "warning: cell contents not read in yet, so no flylines.\n"
    #return
  }

  #if {[lsearch -exact [nl2_list_designs] $mod] == -1} {
  #  msg "warning: no verilog file read for this module, so no flylines.\n"
  #  return
  #}

  msg "Drawing flylines for $modi\n"

  # Gather up wires from cell to all other cells in wires array.
  # Group them by the region they are in.

  foreach porta [fplan_db_pin_list -cell $celldef] {

    # This region info is not valid if the cell is a lef cell,
    # or if the ports have been placed.
    # So for now, draw all flylines to centers of cell.
    if {$FPLAN(flyline_cells) == "center"} {
      set regiona center
    } else {
      # If the port is on one of the cell sides, draw flylines to that side.
      # Have to figure out what side the port is on.
      # If not on a side, draw it to the center.
      set regiona [fplan_db_pin -cell $celldef getregion $porta]
    }
    #set cona _hidden_$regiona
    set cona "{*$regiona*}"
    # 8/24/01: We have magic flylines names now, so hidden labels do not need to exist.
    #if {[llength [db_search_l labels -cell $celldef -non_hier -exact $cona]] == 0} {
    #  # No hidden labels.  Use real port name.
    #  set cona $porta
    #}

    set net [nl2_get_pin_net $topmod "${modi}${hch}${porta}"]
    if {$net == ""} {
      # The pin was defined in the verilog module but was left unconnected
      # when the verilog instance was instantiated.
      # OR, the cell is a lef cell whose verilog model has different
      # pin names than the actual max cell.
      msg "Can not find net connected to: ${modi}${hch}${porta}\n"
      continue
    }
    if {[_fplan_flyline_ignore $net]} {continue}
    foreach pin_name [nl2_get_net_pins $topmod $net] {
      if {[string first $hch $pin_name] == -1} {
	# Its a top-level pin
	set cellidb "."
	# The pin_name is just the top level port name.
	set portb $pin_name
	if {$FPLAN(flyline_ports) == "individual"} {
	  # These are not grouped by region, so consider each pin
	  # its own unique region.
	  set conb $portb
	} elseif {$FPLAN(flyline_ports) == "center"} {
	  set regionb [fplan_db_pin -cell [lay_editcell] getregion $portb]
	  if {$regionb == "center" } {
	    msg "flylines: ignoring pin $portb, which is not placed properly\n"
	  } else {
	    #set conb _hidden_$regionb
	    set conb "{*$regionb*}"
	  }
	  # 8/24/01: We have magic flylines names now, so hidden labels do not need to exist.
	  #if {[llength [db_search_l labels -cell $celldef -non_hier -exact $conb]] == 0} {
	  #  # No hidden labels.  Use real port name.
	  #  set conb $portb
	  #}
	} else {
	  continue  ;# Not shown
	}
      } else {
	setl {modib portb} [split $pin_name $hch]
	# Skip connections from cell to itself
	if {$modib == $modi} {continue}
	if {[catch {set cellb [fplan_db_cell modi2cell $modib]}] || $cellb == ""} {
	  # This happens if the user deleted a cell that should
	  # be connected by flylines.  We dont want to error out
	  # because this code is called every time the user clicks on a cell.
	  msg "flyline warning: can not find cell corresponding to module $modib\n"
	  continue
	}
	if {[fplan_cell_info -is_lef $cellb]} {
	  set cellidb $modib
	} else {
	  set cellidb [fplan_db_cell modi2celli $modib]
	}
	if {$FPLAN(flyline_cells) == "center"} {
	  set regionb "center"
	} else {
	  set regionb [fplan_db_pin -cell $cellb getregion $portb]
	}
	# Connect to the hidden port with this name.
	#set conb _hidden_$regionb
	set conb "{*$regionb*}"
	# 8/24/01: We have magic flylines names now, so hidden labels do not need to exist.
	#if {[llength [db_search_l labels -cell $cellb -non_hier -exact $conb]] == 0} {
	#  # No hidden labels.  Use real port name.
	#  set conb $portb
	#}
      }
      set key "[list [fplan_fix_name $cellid]/$cona [fplan_fix_name $cellidb]/$conb]"
      set wirecnt [llength [nlt_bus_explode $net]]
      set bundles($key) [expr [use_first bundles($key) '0] + $wirecnt]
      #lappend wires([list $regiona $cellidb $regionb]) [list $porta $portb $net]
    }
  }


  foreach bun_info [array names bundles] {
    setl {pina pinb} $bun_info
    # Count of wires in this bundle.
    set cnt $bundles($bun_info)
    if {$cnt == 1} {
      db_flyline $pina $pinb
    } else {
      # width of flyline is proportional to number of wires in bundle.
      set divisor $FPLAN(flyline_width_divisor)
      set width [max 1 [expr int($cnt/$divisor)]]
      db_flyline -width $width -text $cnt $pina $pinb
    }
  }
}

proc _fplan_write_lef_macro {fd cell} -desc {
  Write lef for a floorplan block.  Does NOT work for stdcells.
} {
  global _FPLAN_WRITE_LEF_OPTS

  set mod [fplan_unfix_name $cell]

  # Lef header
  puts $fd "MACRO $mod"
  puts $fd "\tCLASS BLOCK ;"
  puts $fd "\tFOREIGN $mod 0 0 ;"   ;# uh, what is this?
  setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
  puts $fd "\tSIZE [expr $bx2 - $bx1] BY [expr $by2 - $by1] ;"
  puts $fd "\tSYMMETRY X Y ;"
  puts $fd "\tSITE CORE1 ;"

  # Output I/O pins.
  foreach lab_info [db_search_l labels -cell $cell -non_hier] {
    struct max_label l $lab_info
    switch -- ${l.kind} {
      input -
      output -
      inout {
	set layer ${l.layer}
	if {$layer == "space"} {
	  max_error -buffer "write_lef: warning: no layer specified for cell $cell pin ${l.text}, using m1"
	  set layer m1
	}
	set lap [uusnap -mask [expr [techinfo min_width $layer] / 2.0]]
	set pinname [fplan_unfix_name -label ${l.text}]

	puts $fd "\tPIN $pinname"
	puts $fd "\t\tDIRECTION [string toupper ${l.kind}] ;"
	puts $fd "\t\tUSE SIGNAL ;"
	puts $fd "\t\tPORT"
	puts $fd "\t\t\tLAYER [string toupper $layer] ;"
	puts $fd "\t\t\tRECT [expr ${l.x1} - $lap] [expr ${l.y1} - $lap] [expr ${l.x1} + $lap] [expr ${l.y1} + $lap] ;"
	puts $fd "\t\tEND"
	puts $fd "\tEND $pinname"
      }
    }
  }

  # Gather up all obstructions into an array obstructions().


  # Cover the cell with obstructions on these layers
  # to prevent anything from being placed or routed over it.
  foreach layer $_FPLAN_WRITE_LEF_OPTS(cover_obs) {
    setl {snapa(x) snapa(y) offseta(x) offseta(y)} [wire_get_grid $layer]
    if {$snapa(x) == ""} {
      set tmp [expr [techinfo min_width $layer] + [techinfo spacing $layer $layer]]
      setl {snapa(x) snapa(y) offseta(x) offseta(y)} [list $tmp $tmp 0 0]
    }

    # Move the cover obstruction one grid from the ports, which may already in by the offset,
    # which is typically 1/2 grid.  So the obstruction is typically 1.5 grids from cell edge.
    set sepx [expr $snapa(x) + $offseta(x)]
    set sepy [expr $snapa(y) + $offseta(y)]

    # Shrink the obstruction a little so it does not cover ports on the edge.
    lappend obstructions($layer) [list [expr $bx1+$sepx] [expr $by1+$sepy] [expr $bx2-$sepx] [expr $by2-$sepy]]
  }

  # Look for obstruction layers
  foreach mlayer [techinfo layers metal] {
    if {[msg_catch {db_search_l paint -cell $cell ${mlayer}_obs} paintballs junk junk]} {
      # This obstruction layer was not defined in the tech file.  Ignore it.
      continue
    }

    foreach paint_info $paintballs {
      struct max_paint p $paint_info
      lappend obstructions($mlayer) [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
    }
  }

  # Output obstructions array.
  set obslayers [array names obstructions]

  if {[llength $obslayers] != 0} {
    puts $fd "\tOBS"
    foreach layer $obslayers {
      puts $fd "\t\tLAYER [string toupper $layer] ;"
      foreach thing $obstructions($layer) {
	setl {x1 y1 x2 y2} $thing
	puts $fd "\t\tRECT $x1 $y1 $x2 $y2 ;"
      }
    }
    puts $fd "\tEND" ;# end of obstructions.
  }

  puts $fd "END $mod"
}

proc load_options {array_name interactive} -desc {
  If ! $interactive, load specified array with proc options.
  If $interactive, init the array only on the first call.
} {
  # The __proc_options in the caller are set transparently when the proc
  # is invoked to the options of the proc.  Its done by the replacement
  # "proc" function defined in doc0.tcl
  upvar __proc_options proc_options
  global $array_name

  foreach thingy $proc_options {
    # The format of proc_options is [list {option default} ...]
    set option [lindex $thingy 0]  ;# Get the option name.
    upvar $option this_option
    if {$interactive} {
      # For interactive use in menus, the array_name is persistent.
      # Init the array to the default values, only if not doen previously.
      use_init [set array_name]($option) $this_option
    } else {
      # Non-interactive.  No persistent options.
      # Set all elements of array_name to the options
      # specified on the command line.
      set [set array_name]($option) $this_option
    }
  }
}


proc fplan_write_lef {{-obstructions 1} {-cover_obs "m1 m2"} {cell ""}} {
  global FPLAN _FPLAN_WRITE_LEF_OPTS

  # Note: This is an experimental way to convert proc -options
  # into an array of options.  The __proc_options is set when
  # the proc starts to the list of options and their defaults.
  load_options _FPLAN_WRITE_LEF_OPTS [expr {$cell == ""}]

  if {0} {
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      if {$cell == ""} {
	# Show interactive menu.  Init options to defaults on first pass.
	use_init _FPLAN_WRITE_LEF_OPTS($option) [lindex $thingy 1]
      } else {
	# Cell specified.  Do not use persistent options;
	# set all options to those given on command line.
	set _FPLAN_WRITE_LEF_OPTS($option) [set $option]
      }
    }
  }

  if {$cell == ""} {
    set cellid [_fplan_ask_cell "write lef"]
    if {$cellid == ""} {return}
    set cell [expr {$cellid == "." ? [lay_editcell] : [cell_id2cell $cellid]}]

    set prop_list ""
    set leffile $cell.lef
    set fs_box_props [list -message "LEF file to write" -pattern "*.lef"]
    lappend fs_box_props -filename $leffile

    lappend prop_list [list "LEF File" leffile -filename $fs_box_props]

    lappend prop_list [list "Write obstructions" _FPLAN_WRITE_LEF_OPTS(obstructions) -binary]

    lappend prop_list [list "Full obstruction layers"  _FPLAN_WRITE_LEF_OPTS(cover_obs) \
	-entry -help {Will place LEF obstructions over the entire cell on these layers,\
	less a sliver around the edge to avoid covering ports.}]

    if {[prop_menu2 -title "Write LEF" $prop_list] == 0} {
      return ;# cancelled
    }
  } else {
    set leffile $cell.lef
  }

  set fd [open $leffile "w"]

  unwind_catch {

    _fplan_write_lef_macro $fd $cell

    puts $fd "\nEND LIBRARY"

  } always {
    close $fd
  }
}

proc fplan_get_lef_area {{-recalc} {-lef} cell} -desc {
  Get total size of cell from lef, using nl commands to traverse verilog.
} -doc {
  Obviously, must have read in LEF first.
  
  It calculates the sizes of the entire tree under cell, and caches
  them for future calls.
  If -recalc, throw away the cache and recalculate all cell sizes from scratch.
} {
  global _FPLAN_AREA_CACHE

  #if {$recalc} {catch {unset _FPLAN_AREA_CACHE}}

  setl {type xsize ysize} [fplan_cell_info -get $cell]
  if {$type == "lef"} {
    return [expr $xsize * $ysize]
  }

  if {![cell_in_memory $cell]} {
    max_error -buffer "warning: max cell $cell not read in, cannot compute size of parent cell accurately."
    return 0
  }

  # Dont put the cache back in unless this turns out to be too slow.
  #if {[info exists _FPLAN_AREA_CACHE($cell)]} {return $_FPLAN_AREA_CACHE($cell)}

  set topmod [fplan_db_cell module $cell]
  set area 0
  foreach inst [nl2_list_cells $topmod] {
    set subref [nl_get_cell_reference $inst]
    set subcell [fplan_fix_name $subref]
    if {$lef} {
      # Add in only the area used by lef in all contained cells.
      set subarea [fplan_get_lef_area -lef $subcell]
    } else {
      # Add in the LEF area of subcells,
      # but use current size of non-lef cells.
      setl {bx1 by1 bx2 by2} [fplan_bbox -cell $subcell]
      set subarea [expr ($bx2-$bx1) * ($by2-$by1)]
    }
    set area [expr $area + $subarea]
  }

  set _FPLAN_AREA_CACHE($cell) $area
  return $area
}


proc lef_parse_skip {fd origline} {
  # Figure out what section name is that we will be ENDing.
  regsub {#.*} $origline "" newline  ;# Remove comments
  if {[llength $newline] == 1} {
    set thing [lindex $newline 0]
  } else {
    set thing [lindex $newline 1]
  }

  while {[gets $fd line] != -1} {
    if {[lindex $line 0] == "END" && [lindex $line 1] == $thing} {
      return
    }
  }
  error "read_lef: unexpected end of file, last section started at: $origline"
}

proc lef_parse_site {fd line} -desc {
  parse the SITE info from the lef file.  Warn if site is redefined.
} -doc {
  For parsing, there must not be any newlines in the directives.

  The SITE info is left in global LEF_SITES as an assoc list.
} {
  global LEF_SITES
  set corename [lindex $line 1]

  set core_props ""

  while {[gets $fd line] != -1} {
    #puts "line=$line, lindex=[lindex $line 0]"

    regsub {;.*} $line "" line  ; # strip off semi-colon
    regsub {#.*} $line "" line  ; # remove comments

    # Skip comments and blank lines
    set line [string trimleft $line]
    if {[string length $line] == 0} {continue}

    set line [string toupper $line]
    switch -- [lindex $line 0] {
      "SIZE" {
	if {[lindex $line 2] != "BY"} {
	  max_error -buffer  "read_lef: error: unrecognized \"SIZE\" inside SITE $corename"
	} else {
	  lappend core_props [list SIZE "[lindex $line 1] [lindex $line 3]"]
	}
      }
      "CLASS" {
	lappend core_props [list CLASS [lindex $line 1]]
      }
      "SYMMETRY" {
	lappend core_props [list SYMMETRY [lindex $line 1]]
      }
      "END" {
	if {[lindex $line 1] != $corename} {
	  error "read_lef: error: reading SITE $corename: unexpected: $line"
	}
	break ;# done reading this SITE section.
      }
      default {
	max_error -buffer "read_lef: warning: unrecognized line in SITE: $line"
      }
    }
  }

  # Detect redefinition of a SITE that is not the same.
  if {[info exists LEF_SITES($corename)]} {
    set old $LEF_SITES($corename)
    foreach prop "SIZE SYMMETRY CLASS" {
      if {[get_assoc $prop $old] != [get_assoc $prop $core_props]} {
	max_error -buffer "read_lef: warning: Redefinition of SITE $corename conflicts with previous definition"
	break
      }
    }
  }

  msg "Reading LEF SITE $corename\n"

  set LEF_SITES($corename) $core_props
}

proc lef_parse_layer {fd line} -desc {
  parse the LAYER info from a lef file.
} {
    global WIRE

    set leflayer [lindex $line 1]
    set layer [string tolower $leflayer]

    set wire_layers [techinfo wire_layers]

    if {[lsearch $wire_layers $layer] == -1} {
      # Print this message if the layer we are ignoring
      # is genuinely unrecognized; ignore vias.
      if {![string match {via*} $layer ]} {
	msg "Ignoring LEF info for unrecognized layer $layer\n"
      }
      lef_parse_skip $fd $line
      return
    }

    set offset ""

    msg "Reading LEF LAYER $layer\n"
    while {[gets $fd line] != -1} {
      regsub {;.*} $line "" line  ; # strip off semi-colon
      regsub {#.*} $line "" line  ; # remove comments

      switch -- [lindex $line 0] {
	OFFSET {
	  set offset [lindex $line 1]
	}
	PITCH {
	  set WIRE($layer,snap) [uusnap -mask [lindex $line 1]]
	}
	DIRECTION {
	  set WIRE($layer,direction) [string tolower [lindex $line 1]]
	}
	WIDTH {
	  set WIRE($layer,width) [uusnap -mask [lindex $line 1]]
	}
	RESISTANCE {
	  if {[lindex $line 1] != "RPERSQ"} {
	    msg "Unrecognized LEF line: $line\n"
	  } else {
	    set WIRE($layer,rpersq) [lindex $line 2]
	  }
	}
	CAPACITANCE {
	  if {[lindex $line 1] != "CPERSQDIST"} {
	    msg "Unrecognized LEF line: $line\n"
	  } else {
	    # In pF.
	    set WIRE($layer,cpersq) [lindex $line 2]
	  }
	}
	EDGECAPACITANCE {
	    # In pF.
	    set WIRE($layer,cedge) [lindex $line 1]
	}
	END {
	  if {[lindex $line 1] != $leflayer} {
	    error "read_lef: unrecognized END statement in: $line"
	  }
	  break
	}
      }
    }

    # LEF documentation says explicitly that default OFFSET is PITCH/2.
    if {$offset == ""} {
      set WIRE($layer,offset) [uusnap -mask [expr $WIRE($layer,snap)/2.0]]
    } else {
      set WIRE($layer,offset) [uusnap -mask $offset]
    }
}


proc fplan_read_lef {{-menu} {leffile ""}} -desc {
  Read a lef file for cell sizes and pin names.
} {
  global FPLAN _FPLAN_CELL_INFO
  global _READ_LEF_MENU ;# persistent data in menu.

  use_init _READ_LEF_MENU(macros) 1
  use_init _READ_LEF_MENU(layers) 1

  if {$leffile == ""} {
    set leffile [use_first FPLAN(DEFAULT_LEF_FILE)]
  }

  if {! $menu && $leffile == ""} {
    max_error -buffer "fplan_read_lef: Dont know the default lef file!"
    return
  }

  if {$menu} {
    set prop_list ""
    set fs_box_props [list -message "LEF file to read" -pattern "*.lef"]
    if {$leffile != ""} {
      lappend fs_box_props -filename $leffile
    }
    lappend prop_list [list "LEF File" leffile -filename $fs_box_props]
    lappend prop_list [list "Read MACRO sizes+pins" _READ_LEF_MENU(macros) -binary]
    lappend prop_list [list "Read LAYER info" _READ_LEF_MENU(layers) -binary]
    lappend prop_list [list "Note: always reads UNITS and SITE" "" -label]
    if {[prop_menu2 -title "Read LEF" $prop_list] == 0} {
      return ;# cancelled
    }

    #if {[info exists FPLAN(DEFAULT_LEF_FILE)]} {
    #  set leffile [fs_box -message "LEF file to read:" -pattern "*.lef" \
    #  	-filename $FPLAN(DEFAULT_LEF_FILE)]
    #} else {
    #  set leffile [fs_box -message "LEF file to read:" -pattern "*.lef"]
    #}
    #if {$leffile ==""} {
    #  # cancelled
    #  return
    #}
  }

  if {![file readable $leffile]} {
    error "Can not read file: $leffile"
  }

  # To make it fast, run it through sed to get just what we need.
  # We want the LAYER info, which is everything inside LAYER,END pairs,
  # and the SIZE and PIN and DIRECTION lines inside MACRO,END pairs.
  #set sedcmd {^[ 	]*LAYER/,/^[ 	]*END/p;/^[ 	]*MACRO /p;/^[ 	]*SIZE /p;/^[ 	]*END/p;/^[ 	]*PIN/p;/^[ 	]*DIRECTION/p}
  #set sedcmd {s/^[ 	]*//;/^LAYER/,/^END/p;/^MACRO /p;/^SIZE /p;/^END/p;/^PIN/p;/^DIRECTION/p}
  #set cmd [list |sed -n $sedcmd $leffile]
  #set fd [open $cmd "r"]

  set fd [open $leffile "r"]

  unwind_catch {

  msg "Loading .lef file: $leffile\n"

  #set lefcell ""
  #set pinlist ""
  #set pinname ""
  #set width 0; set height 0
  set count 0
  while {[gets $fd line] != -1} {
    #puts "line=$line, lindex=[lindex $line 0]"

    # Skip comments
    set line [string trimleft $line]
    if {[string index $line 0] == "#"} {continue}

    if {[string length $line] == 0} {continue}


    switch -- [lindex $line 0] {
      UNITS {
	# We look at the units just to make sure it is 1000.
	# If not, give up.
	while {[gets $fd line] != -1} {
	  regsub {;.*} $line "" line  ; # strip off semi-colon
	  regsub {#.*} $line "" line  ; # remove comments
	  switch -- [lindex $line 0] {
	    DATABASE {
	      # This is screwy, but you specify 1000 to mean that the
	      # LEF units are in microns.  I think the 1000 is what they
	      # have to multiply by to get into DEF units.  If you omit
	      # this, they use 100 instead of 1000, so it is required.
	      if {[lindex $line 1] != "MICRONS" || \
	          [lindex $line 2] != 1000} {
		error "read_lef: error: unsupported UNITS specified: $line"
	      }
	    }
	    END {
	      if {[lindex $line 1] != "UNITS"} {
		error "read_lef: error: unexpected END reading UNITS: $line"
	      }
	      break
	    }
	    default {
	      msg "read_lef: warning: unsupported UNITS specified: $line\n"
	    }
	  }
	}
      }
      VIA {
	lef_parse_skip $fd $line
      }
      VIARULE {
	lef_parse_skip $fd $line
      }
      SPACING {
	lef_parse_skip $fd $line
      }
      NONDEFAULTRULE {
	lef_parse_site $fd $line
      }
      SITE {
	lef_parse_site $fd $line
      }

      MACRO {
	if {! $_READ_LEF_MENU(macros)} {
	  lef_parse_skip $fd $line
	  continue
	}

	set lefcell [lindex $line 1]
	msg "Reading LEF MACRO for $lefcell\n"

	set pinlist ""
	set pinname ""
	set width 0; set height 0

	while {[gets $fd line] != -1} {
	  regsub {;.*} $line "" line  ; # strip off semi-colon
	  regsub {#.*} $line "" line  ; # remove comments
	  switch -- [lindex $line 0] {
	    SIZE {
	      if {$lefcell != ""} {
		set width [lindex $line 1]
		set height [lindex $line 3]
		incr count
	      }
	    }
	    PIN {
	      set pinname [lindex $line 1]
	      if {[regexp -nocase {^(vdd|vss|gnd)$} $pinname]} {
		set pinname ""
	      }
	    }
	    DIRECTION {
	      set line [string trimright $line ";"]
	      set dir [string tolower [lindex $line 1]]
	      if {$pinname != ""} {
		lappend pinlist [list $pinname $dir]
	      }
	    }
	    END {
	      if {[lindex $line 1] == $lefcell} {
		set _FPLAN_CELL_INFO($lefcell) [list lef $width $height $pinlist]
		set lefcell ""
		set pinlist ""
		set pinname ""
		set width 0; set height 0
		break
	      }
	    }
	  }
	}
      }

      LAYER {

	if {! $_READ_LEF_MENU(layers)} {
	  lef_parse_skip $fd $line
	} else {
	  lef_parse_layer $fd $line
	}
      }

      VERSION {}
      NAMESCASESENSITIVE {}
      "#" {}
      INPUTPINANTENNASIZE {}
      OUTPUTPINANTENNASIZE {}
      INOUTPINANTENNASIZE {}
      MINFEATURE {}

      END {
	if {[lindex $line 1] != "LIBRARY"} {
	  msg "read_lef: unexpected: $line\n"
	}
      }


      default {
	msg "read_lef: ignoring lef line: $line\n"
	#error "unrecognized lef line: $line"
      }
    }
  }

  } always {
    close $fd
  }

  # Init the block grid from the default CORE SITE specified in LEF.
  _fplan_set_core_grid

  msg "LEF done, loaded $count cells\n"
}


# TODO: Add option to print lef cells, vias, fets or not.
# TODO: Add option to print to file.
# TODO: Add to listing printout: type (lef, undef), verilog filename.
proc fplan_print_hier {{cell ""} {level 0}} {
  if {$cell == ""} {
    set cell [lay_editcell]
    set spaces ""
  } else {
    # The format %*s does not work for level 0, it always
    # adds at least one space, which is why it is in an else clause.
    set spaces [format "%*s" $level " "]
  }

  setl {type xsize ysize} [fplan_cell_info -get $cell]

  # Do not print gcell groups.
  if {! [string match {#GROUP*} $cell]} {
    puts "$spaces$cell ([fplan_db_cell  module $cell]) $type"
    incr level
  }

  if {$type != "lef" && $type != "undef"} {
    foreach subcell [db_kids $cell] {
      fplan_print_hier $subcell $level
    }
  }
}


proc fplan_fix_name {{-label} name} -desc {
  Change bad chars in a verilog name to something max can use.
} {
  # The following chars are definitely NOT allowed:
  #   ! (used by us for hierarchy) - NO LONGER NECESSARY?
  #   \ (screws up tcl, easier to just toss it)
  #   / (not possible in unix filename)
  #   [] (used by max for cell arrays)
  if {$label} {
    # The only char not allowed in labels is forward slash:
    regsub -all {/}    $name {{FS}} name
  } else {
    #regsub -all {!}    $name {{EX}} name
    regsub -all "\\\\" $name {{BS}} name
    regsub -all {/}    $name {{FS}} name
    regsub -all {\[}   $name {{LB}} name
    regsub -all {\]}   $name {{RB}} name
    #regsub -all {<}    $name {{LT}} name
    #regsub -all {>}    $name {{GT}} name
    regsub -all {,}    $name {{CO}} name
  }
  return $name
}

proc fplan_unfix_name {{-label} {-pathok} name} -desc {
  Reverse of _fplan_fix_verilog_name
} {
  # The following chars are definitely NOT allowed in cell names:
  #   ! (used by us for hierarchy)
  #   \ (screws up tcl, easier to just toss it)
  #   / (not possible in unix filename)
  #  space (not allowed, obviously)
  #regsub -all {{EX}} $name {!} name

  if {$label} {
    regsub -all {{FS}} $name {/} name
  } else {
    regsub -all {{BS}} $name "\\" name
    regsub -all {{FS}} $name {/} name
    regsub -all {{LB}} $name {[} name
    regsub -all {{RB}} $name {]} name
    #regsub -all {{LT}} $name {<} name
    #regsub -all {{GT}} $name {>} name
    regsub -all {{CO}} $name {,} name
  }
  return $name
}


proc fplan_run_dc {} {
  global _SYNOPSYS_OPT
  set _SYNOPSYS_OPT(effort) [use_first _SYNOPSYS_OPT(effort) 'low]
  set _SYNOPSYS_OPT(db_lib) [use_first _SYNOPSYS_OPT(db_lib) \
    "'$TIMING_DATA(syn_libdb)"]
  set _SYNOPSYS_OPT(mod) [use_first _SYNOPSYS_OPT(mod)]

  set prop_list ""
  lappend prop_list [list "Synthesis optimization effort" _SYNOPSYS_OPT(effort) \
	-choice {low med high}]

  set cmd_file dc.dccmds_in
  set FILE [open $cmd_file w]
  puts $FILE "link_library = $_SYNOPSYS_OPT(db_lib)"
  puts $FILE "target_library = $_SYNOPSYS_OPT(db_lib)"

  puts "/* Need to figure out how to flatten the synthetic modules. */"
  puts "compile -map_effort $_SYNOPSYS_OPT(effort)"

  puts "write -format verilog -output f1.est_vg"

  puts "/* Use report_area to report the total area of module including"
  puts "/* synthetic blocks. */"
  puts "report_area"

    if {[catch "exec csh -cf \"$TIMING_DATA(pearl,command) < $cmd_file >&! $out_file\"" msg]} {
  }

TODO: How do I specify the verilog modules that go with each block?

L_CHIP = "/volume/lchip/design/gimlet"
L_INCLUDE = L_CHIP + "/design/asics/l/linclude"

/* You must read the macro files in the same read command for it to find them.*/
read -f verilog { \
	L_CHIP + "/central/asics/lib/include/gimlet.h" \
	L_CHIP + "/design/asics/l/rel/l_jspec.h" \
	L_INCLUDE + "/lout_nlif.h" \
	L_INCLUDE + "/linclude.h" \
	lout_nlif_dbufctl_pipe.v }

}

proc _fplan_rep_calc {} -desc {
  Recalculate values displayed in repeater menu.
} {
  global _FPLAN_REP_MENU TIMING_DATA

  _fplan_init_rc

  set Rw $TIMING_DATA(Rw)
  set Cw $TIMING_DATA(Cw)
    
  # This is the break-even wire length, ie, inserting a repeater has no effect.
  # l = sqrt(4*D(repeater)/r*c)
  # Units: D (ns=1e-9) / R (o/u=1e6) / C (fF/u=1e-9)
  # l = sqrt(1e-9 / 1e6 / 1e-9) = sqrt(1e-6)
  set _FPLAN_REP_MENU(lmin) [expr sqrt(1e6 * 4.0 * $_FPLAN_REP_MENU(Drep) / $Rw / $Cw)]

  # Round off these numbers.
  set _FPLAN_REP_MENU(lmin) [expr 1.0 * [format "%.4g" $_FPLAN_REP_MENU(lmin)]]
  set _FPLAN_REP_MENU(lmax) [expr 1.0 * [format "%.4g" \
	[expr $_FPLAN_REP_MENU(lmin) * $_FPLAN_REP_MENU(len_factor)] ]]
}


proc fplan_remove_repeaters {} -desc {
  A repeater is any cell of type _FPLAN_REP_MENU(rep_cell) named "REPEATER*"
} {
  global _FPLAN_REP_MENU 

  fplan_check_verilog

  use_init _FPLAN_REP_MENU(rep_cell) MMI_BUFE
  set rep_cell $_FPLAN_REP_MENU(rep_cell)

  set hch [verilog_hier_char]
  set mod [fplan_db_cell module [lay_editcell]]

  set repeater_cnt 0

  foreach cell_info [db_instances_l -of $rep_cell] {
    struct max_cell c $cell_info
    if {[string match {REPEATER*} ${c.id}]} {

      # vid is the name of this repeater cell in verilog netlist.
      set vid [fplan_unfix_name ${c.id}]

      # Rip up the cell in verilog; throw away the output.
      set outnet [nl2_get_pin_net $mod ${vid}${hch}out]
      set innet [nl2_get_pin_net $mod ${vid}${hch}in]
      # Jay says you do not need to call disconnect_pin if you are going
      # to call remove_cell.
      #nl_disconnect_pin ${vid}${hch}out
      #nl_disconnect_pin ${vid}${hch}in
      # set nl_cell [nl2_find_cell ...]
      # Note: You cant just pass vid to nl_remove_cell, you must
      # pass the nl object corresponding to the string vid found
      # in module $mod.
      nl_remove_cell [nl2_find_cell $mod $vid]
      # Disconnect the pin on the other end of the net what the output was
      # hooked to, and hook the innet to that pin.
      set otherpin [lindex [nl_get_net_pins $outnet] 0]
      nl_disconnect_pin $otherpin
      nl_remove_net $outnet
      nl_connect_pin $otherpin $innet

      # Blow it away in max.
      sel_cell2 ${c.id}
      :delete
      incr repeater_cnt
    }
  }
  msg "Removed $repeater_cnt repeaters\n"
}

proc _fplan_init_rc {} {
  global TIMING_DATA

  use_init TIMING_DATA(rc_layer) m3
  use_init TIMING_DATA(use_rc_layer) 1  ;# true/false

  if {$TIMING_DATA(use_rc_layer) || ![info exists TIMING_DATA(Rw)]} {
    setl {Rw Cw} [wire_get_rc $TIMING_DATA(rc_layer)]
    set TIMING_DATA(Rw) $Rw
    set TIMING_DATA(Cw) $Cw
  }

  msg_flush ;# Flush errors from wire_get_rc
}

proc _fplan_set_rc_menu {} {
  global TIMING_DATA

  _fplan_init_rc

  set prop_list ""
  lappend prop_list [list "Specify R and C by:" TIMING_DATA(use_rc_layer) \
    -radio {"wiring layer" "values below"} -values {1 0} -reload]

  lappend prop_list [list "Wiring layer for R C calculations" \
	TIMING_DATA(rc_layer) -entry \
	-when {$TIMING_DATA(use_rc_layer)} \
	-help {All calculations are made assuming all wires are on this layer}]

  lappend prop_list [list "Resistance Rw (ohms/micron length)" TIMING_DATA(Rw) -label \
      -when {$TIMING_DATA(use_rc_layer)}]
  lappend prop_list [list "Capacitance Cw  (fF/micron length)" TIMING_DATA(Cw) -label \
      -when {$TIMING_DATA(use_rc_layer)}]

  lappend prop_list [list "Resistance Rw (ohms/micron length)" TIMING_DATA(Rw) -number \
	-snap 0.1 -when {! $TIMING_DATA(use_rc_layer)}]
  lappend prop_list [list "Capacitance Cw (fF/micron length)" TIMING_DATA(Cw) -number \
	-snap 0.1 -when {! $TIMING_DATA(use_rc_layer)}]
  
  if {![prop_menu2 -title "Modify R/C" -apply _fplan_init_rc $prop_list]} {
    return ;# cancelled
  }

  _fplan_init_rc
}


proc fplan_repeater {{-remove 0}} -desc {
  Put in repeaters
} {
# Definitions:
#	D(gate) - intrinsic delay of gate
#	r	- resistance per unit length of wire
#	c	- cap per unit length of wire
#	l	- length of wire
#	Rw	- total resistance of wire
#	Cw	- total cap of wire
#	Ro(gate) - effective output resistance of gate
#	Ci(gate) - input cap of gate

# The basic idea is:
# +-------+                  +-------+
# | bufa->|------------------|->bufb |
# +-------+      length: l   +-------+
#
# Without repeater:
#	Rt = Rw + Ro(bufa)
# 	Delay = Rt*Cw/2 + Rt*Ci(bufb)
#	      = (r*l+Ro(bufa))*c*l*l/2 + (r*l+Ro(bufa))*Ci(bufb)
#
#	If we are considering a repeater, the Ro term is negligible compared to Rw,
#	and Ci(bufb) is negligible compared to Cw, so we reduce to approximately:
#
#	Ignoring Ro and Ci:
#
#	Delay(wire) = r*c*l*l/2
#
# With one repeater, ignoring Ro and Ci:
#
#	Delay(1rep) = D(repeater) + 2 * (r*c*l/2*l/2)/2
#	            = D(repeater) + (r*c*l*l/2) / 2
#
# Finding l such that Delay(1rep) == Delay(wire):
#	D(repeater) = r*c*l*l/4
#	l = sqrt(4*D(repeater)/r*c)
#
# So, at this length putting in a repeater is a wash.
# So we want to insert repeaters such that no wire segment
# length > l = sqrt(4*D(repeater)/r*c) * fudge_factor,
# Where fudge_factor is how much longer we let the wire get before
# we stick the repeater in.

  global TIMING_DATA _FPLAN_REP_MENU _FPLAN_PIN_CACHE 
  catch {unset _FPLAN_PIN_CACHE}

  _wire_init

  use_init _FPLAN_REP_MENU(def_layer) m3
  use_init _FPLAN_REP_MENU(max_delay) 1
  use_init _FPLAN_REP_MENU(len_factor) 1.2
  use_init _FPLAN_REP_MENU(use_layer) 1
  use_init _FPLAN_REP_MENU(Drep) 0.5  ;# Repeater delay, ns
  use_init _FPLAN_REP_MENU(rep_cell) MMI_BUFE

  set what_to_do [expr {$remove ? "remove" : "add"}]

  _fplan_rep_calc

  set prop_list ""
  lappend prop_list [list "Action:" what_to_do \
    -radio {"Add Repeaters" "Remove Repeaters"} -values {add remove}]
  

  lappend prop_list [list Rw TIMING_DATA(Rw) -label]
  lappend prop_list [list Cw TIMING_DATA(Cw) -label]
  lappend prop_list [list "Modify Rw, CW..." "" -button _fplan_set_rc_menu]

  lappend prop_list [list "Repeater intrinsic delay (ns)" \
	_FPLAN_REP_MENU(Drep) -number -snap 0.1]
  
  lappend prop_list [list "Over-length factor" \
	_FPLAN_REP_MENU(len_factor) -number -snap 0.1]

  lappend prop_list [list "Calculated min repeated wire length (microns):" \
      _FPLAN_REP_MENU(lmin) -label -when {$_FPLAN_REP_MENU(use_layer)}]
  lappend prop_list [list "Calculated min repeated wire length (microns):" \
      _FPLAN_REP_MENU(lmin) -number -when {!$_FPLAN_REP_MENU(use_layer)}]

  lappend prop_list [list "Calculated max non-repeated wire length (= min * factor):" \
      _FPLAN_REP_MENU(lmax) -label -when {$_FPLAN_REP_MENU(use_layer)}]
  lappend prop_list [list "Calculated max non-repeated wire length (= min * factor):" \
      _FPLAN_REP_MENU(lmax) -number -when {!$_FPLAN_REP_MENU(use_layer)}]

  lappend prop_list [list "Ignore wires with delay less than (ns)" \
      _FPLAN_REP_MENU(max_delay) -entry \
      -help {Wires with delays less than this value are ignored}]

  lappend prop_list [list "Repeater cell" \
      _FPLAN_REP_MENU(rep_cell) -entry \
      -help {Wires with delays less than this value are ignored}]

  lappend prop_list [list "Edit Wiring Grid ..." {} \
      -button wire_grid_menu]
  
  set buttons "Done=1=default Recalculate==apply Cancel=0=cancel"
  if {[prop_menu2 -title "Repeater Insertion" -apply _fplan_rep_calc \
	-buttons $buttons $prop_list] == 0} {
    return ;# cancelled
  }

  #_fplan_rep_update ;# Make sure all dependent values in menu are recalculated based on final values.

  if {$what_to_do == "remove"} {
    fplan_remove_repeaters
    return
  }

  # Make sure the repeater cell is loaded into memory.
  edit_push_direct [lay_editcell]
  :load $_FPLAN_REP_MENU(rep_cell)
  # And get the cell size from prb layer.
  setl {px1 py1 px2 py2} [fplan_bbox -cell $_FPLAN_REP_MENU(rep_cell)]
  set rep_sizex [expr $px2 - $px1]
  set rep_sizey [expr $py2 - $py1]
  edit_pop_direct

  # TODO: For multi-terminal output, initial wire segment length must be derated.


  # Now do it.  Traverse verilog connectivity.
  set hch [verilog_hier_char]
  set parentmod [fplan_db_cell module [lay_editcell]]

  set total_output_cnt 0
  set total_repeater_cnt 0

  foreach net [nl2_list_nets $parentmod] {
    set pin_objects [nl2_get_net_pins $parentmod $net]

    # Find the output pin, and count other pins.
    set output ""
    set outcnt 0
    set incnt 0
    set inoutcnt 0
    foreach nlpin $pins {
      # The nl_get_pin_direction is "in" if the pin is being driven,
      # or "out" if it is a driver, taking into account whether it is a subcell or not.
      # Ie: if IP is an input port:
      # nl_get_pin_direction subcell.IP  -> "in"
      # nl_get_pin_direction IP -> "out"
      set dir [nl_get_pin_direction $nlpin]
      switch -- $dir {
	inout { incr inoutcnt; break }
	in { incr incnt }
	out { set output $nlpin; break }
      }
    }

    # Do a little sanity checking.
    if {$outcnt > 1} {
      msg "fplan_repeater: WARNING: Multiple drivers on net $net - net ignored\n"
      continue
    }
    if {$output == ""} {
      if {$incnt} {
	msg "fplan_repeater: WARNING: No driver on net $net ($incnt inputs, $inoutcnt inouts)\n"
      }
      continue
    } else {
      if {$inoutcnt} {
	msg "fplan_repeater: WARNING: Both output and inout pins on net $net\n"
      }
    }

    incr total_output_cnt

    set repeater_chain_num 0

    # Net driver x,y location in parent cell coords.
    setl {sx sy} [fplan_db_pin2 -xform -fixname $nlpin]

    # Step through each input pin and add repeaters if necessary.
    foreach nlpin $pin_objects {
      set dir [nl_get_pin_direction $nlpin]
      if {$dir != "in"} {continue}

      incr repeater_chain_num  ;# Incremented for multiple repeater chains on the same net.

      # Found a pin being driven by this output.
      setl {ix iy} [fplan_db_pin2 -xform $nlpin]
      set dx [expr $ix - $sx]
      set dy [expr $iy - $sy]

      set curx $sx
      set cury $sy
      set curnet $net
      set repnum 1     ;# repeater number on this repeater chain.



      # Length of wire between repeaters.
      set rl $_FPLAN_REP_MENU(lmin)
      # Factor by which physical wire can exceed rl.
      set factor $_FPLAN_REP_MENU(len_factor)

      # Number of wire segments needed for this wire:
      # Number of repeaters needed is num_segs-1
      set num_segs [expr int(ceil((abs($dx) + abs($dy)) / ($rl * $factor) ))]
      # Length of wire segments between repeaters.
      set segl [expr (abs($dx) + abs($dy)) / $num_segs]

      while {[incr num_segs -1] > 0} {
	# Assign a location blindly.
	# Go in X dir first, then Y dir.
	if {abs($dx) > $segl} {
	  set curx [expr ($dx > 0) ? $curx + $segl : $curx - $segl]
	  set dx [expr ($dx > 0) ? $dx - $segl : $dx + $segl]
	} else {
	  # It is easier for the user to figure out what happened if we
	  # use up the remaining X direction first, then go in Y.
	  if {abs($dx) > 0} {
	    set curx [expr $curx + $dx]
	    set segl [expr ($dx > 0) ? $segl - $dx : $segl + $dx]
	    set dx 0
	  } 
	  if {abs($dy) > $segl} {
	    set cury [expr ($dy > 0) ? $cury + $segl : $cury - $segl]
	    set dy [expr ($dy > 0) ? $dy - $segl : $dy + $segl]
	  }
	}
	
	
	#elseif {abs($dy) > $segl} {
	#  set cury [expr ($dy > 0) ? $cury + $segl : $cury - $segl]
	#  set dy [expr ($dy > 0) ? $dy - $segl : $dy + $segl]
	#} else {
	#  # Neither segment is long enough.  Go as far as we can in X dir.
	#  set curx [expr ($dx > 0) ? $curx + $dx : $curx - $dx]
	#  set segl [expr ($dx > 0) ? $segl - $dx : $segl + $dx]
	#  set dx 0
	#  # Go remaining distance (segl) in Y dir.
	#  set cury [expr ($dy > 0) ? $cury + $segl : $cury - $segl]
	#  set dy [expr ($dy > 0) ? $dy - $segl : $dy + $segl]
	#}

	# Add the repeater location in max.
	set rep_cell $_FPLAN_REP_MENU(rep_cell)

	# Pick a unique name.
	set repname REPEATER_${net}_${repeater_chain_num}%${repnum}
	set newnet ${net}_REPEATER${repeater_chain_num}%${repnum}
	incr repnum
	incr total_repeater_cnt
	setl {tx ty} [uusnap -mask $curx $cury]

	# Jiggle so repeaters do not land exactly on one another,
	# in which case they disappear.
	while {1} {
	  # The cells are actually bigger than their bbox, so we need to search
	  # an area smaller than the full sizex/sizey.
	  set fudge [expr $rep_sizex / 4.0]  ;# Pulled out of the air.
	  set cells [db_search_l cells -area [expr $tx+$fudge] [expr $ty+$fudge] \
		[expr $tx + $rep_sizex - $fudge] [expr $ty + $rep_sizey - $fudge]]
	  set fnd 0
	  foreach cell_info $cells {
	    struct max_cell c $cell_info
	    if {[string match {REPEATER*} ${c.id}]} {
	      set fnd 1; break
	    }
	  }
	  if {$fnd} {
	    set tx [expr $tx + $rep_sizex]
	  } else {
	    db_instance -id [fplan_fix_name $repname] $rep_cell $tx $ty
	    break
	  }
	}

	# Add the repeater to the verilog.
	# If this is the first time and the MMI_BUFE does not exist, add it.
	if {1 != [llength [nl_find_references -exact $rep_cell]]} {
	   # Create a nl reference for the repeater buffer.
	  nl_create_reference $rep_cell
	  nl_create_refpin in $rep_cell
	  nl_create_refpin out $rep_cell
	}

	#nl_disconnect_pin pin
	#nl_create_net net "wire" [mod]
	#nl_connect_pin pin net

	# Unhook the old net destination (subcell input or top-level output).
	nl_disconnect_pin $nlpin

	# Add in the repater
	nl_create_cell $repname $rep_cell

	# Hook up repeater input to curnet.
	nl_connect_pin ${repname}${hch}in $curnet

	# Create new net for repeater output, xet curnet to it, and hook that up too.
	nl_create_net $newnet "wire"
	nl_connect_pin ${repname}${hch}out $newnet
	nl_connect_pin $nlpin $newnet

	set curnet $newnet
      }
    }
  }

  msg "fplan_repeater done - processed $total_output_cnt nets, added $total_repeater_cnt repeaters\n"
}

proc fplan_juniper_module_cmd {func modulename} -desc {
  Call the dopey Juniper modulecmd thing.  Merge results into environment
} {
  global env

  set junk [exec modulecmd sh $func $modulename]
  set cmds [split $junk ";"]

  if {[string match {*ERROR*} [lindex $cmds 0]]} {
    # It failed.  If it was an unload, its ok, module probably not loaded..
    if {$func == "add"} {
      msg "Warning: failed: modulecmd $func $modulename\n"
    }
    return
  }

  foreach cmd $cmds {
    # The stuff returned from modulecmd are export statements
    # and variable assignments like this: name=value
    set i [string first "=" $cmd]
    if {$i > 0} {
      set name [string range $cmd 0 [expr $i-1]]
      set value [string range $cmd [expr $i+1] end]
      set env($name) $value
    }
  }
}


proc fplan_place_it {{cell ""}} {
  global env MN_TECH

  fplan_check_verilog

  catch {set tech_root $env(TECH_ROOT)}

  if {$tech_root == "" || ![file isdirectory $tech_root]} {
    max_error -buffer "error: TECH_ROOT environment variable incorrect"
    return
  }


  if {$cell == ""} {set cell [lay_editcell]}
  set mod [fplan_db_cell module $cell]
  set dir "place_it"
  set modulename "synopsys/2000.11-SP1"

  catch {fplan_juniper_module_cmd unload synopsys}
  fplan_juniper_module_cmd add $modulename

  # Make a list of the hierarchical subcells in cell.
  set hier_defs ""
  foreach subcell [db_kids $cell] {
    if {[fplan_cell_info -is_hier $subcell]} {
      lappend hier_defs $subcell
    }
  }

  # Not used...
  set hier_ids ""
  foreach cell_info [db_search_l cells -cell $cell] {
    struct max_cell c $cell_info
    if {[fplan_cell_info -is_hier ${c.def}]} {
      lappend hier_ids ${c.id}
    }
  }

  catch {file mkdir $dir}
  if {![file isdirectory $dir]} {
    error "Can not create directory $dir"
  }
  set db $tech_root/$MN_TECH/library/synopsys/lee/$MN_TECH.db
  set pdb $tech_root/$MN_TECH/library/synopsys/lee/$MN_TECH.pdb


  # Write the verilog file.  Need only the modules of interest to us.
  # Note that the verilog might have changed due to grouping/ungrouping
  # of modules from the original verilog, or for sue demorgan cell removal.

  set vgfile $dir/$cell.vg
  catch {file delete -force $vgfile}
  foreach subcell [concat $hier_defs $cell] {
    # nl_write_verilog currently closes the file for you,
    # so have to do this:
    set fd [open $vgfile "a"]
    nl_write_verilog $fd [fplan_db_cell module $subcell]
    catch {close $fd}  ;# catch in case nl closed it.
  }

  # Write the input file for synopsys placer.
  set fd [open $dir/$cell.psyn_in "w"]

  puts $fd "set target_library $db"
  puts $fd "set physical_library $pdb"
  puts $fd "set link_library {\"*\" $db}"
  puts $fd "set physopt_set_max_placement_density 1.0"
  puts $fd "set hdlin_dont_post_process true"

  puts $fd "read_verilog $vgfile"

  #foreach subcell [concat $cell $hier_defs] {
  #  set submod [fplan_db_cell module $subcell]
  #  puts $fd "set current_design $submod"
  #  puts $fd "read_pdef $dir/$subcell.pdef"
  #}

  puts $fd "set current_design $mod"
  puts $fd "read_pdef $dir/$cell.pdef"

  puts $fd "link"
  puts $fd "uniquify"

  puts $fd "set current_design $mod"
  foreach cell_info [db_search_l cells -cell $cell] {
    struct max_cell c $cell_info
    if {[fplan_cell_info -is_hier ${c.def}]} {
      set modi [fplan_db_cell celli2modi ${c.id}]
      # The -name is just for informational purposes.
      puts $fd "create_obstruction -placement \
      -name ${c.id}_obstruction \
      -coordinate {${c.x1} ${c.y1} ${c.x2} ${c.y2}}"

      # This doesnt seem to do anything.
      # Maybe all the cells need to be in the alu8.def
      #puts $fd "set_dont_touch_placement $modi"
      puts $fd "set_dont_touch_placement \[get_cells $modi/*\]"
      puts $fd "set_dont_touch \[get_cells $modi/*\]"
    }
  }
  #puts $fd {report_attribute [get_cells alu8]}
  #puts $fd {report_attribute [get_cells adder8]}

  #puts $fd "$weights"
  # physopt - does synthesys too.
  # compile_physical - use for RTL.
  puts $fd "create_placement -effort high"
  puts $fd "legalize_placement"
  puts $fd "write -f db -hier -o $dir/$cell.out.db"
  puts $fd "exit"
  close $fd


  proc _fplan_run {args} {
    msg "$args\n"
    return [eval $args]
  }

  _fplan_run fplan_write_def -cells 2 -blockages 1 $cell $dir/$cell.def
  _fplan_run exec def2pdef -def $dir/$cell.def -pdb $pdb -output $dir/$cell.pdef

  #foreach subcell [concat $cell $hier_defs] {
  #  _fplan_run fplan_write_def -blockages 1 $subcell $dir/$subcell.def
  #  _fplan_run exec def2pdef -def $dir/$subcell.def -pdb $pdb -output $dir/$subcell.pdef
  #}


  set outfile $dir/$cell.psyn_out
  if {[catch {_fplan_run exec psyn_shell -f $dir/$cell.psyn_in > $outfile} stat]} {
    max_error -buffer "Placer exited abnormally.  See file $outfile"
    return
  }

  # Add placer warning/error messages to max errors.
  # The placer messages run on to multiple lines if the following
  # lines begin with a tab.
  set fnd_error 0
  if {[catch {set fd [open $outfile "r"]}]} {
    max_error -buffer "Error: could not open placer output file: $outfile"
    return
  } else {
    set line ""
    while {$line != "" || [gets $fd line] != -1} {
      set lowerline [string tolower $line]
      if {[expr [string first error: $lowerline] >= 0]} {
	set fnd_error 1
      }
      if {[string first warning: $lowerline] >= 0 || \
          [string first error: $lowerline] >= 0} {
        set msg $line
        while {[gets $fd line] != -1 && [string index $line 0] == "\t"} {
          append msg " [string trim $line]"
        }
        max_error -buffer "placer message: $msg"
        continue
      }
      set line ""
    }
    close $fd
  }

  if {$fnd_error} {
    max_error -buffer "Aborting placement update due to errors from psyn"
    return
  }

  _fplan_run exec db2def5 $dir/$cell.out.db -out $dir/$cell.out.def

  # Suck the placement back in.
  _fplan_run fplan_read_def -pins 0 -merge 1 -flat 0 $dir/$cell.out.def
}


proc ldiff {list1 list2} -desc {
  Diff two lists efficiently.  Return: [list extra_items_in_list1 extra_items_in_list2]
} {
  set extra2 ""
  foreach thing $list1 {
    set a1($thing) 1
  }
  foreach thing $list2 {
    if {[info exists a1($thing)]} {
      unset a1($thing)
    } else {
      lappend extra2 $thing
    }
  }
  set extra1 [array names a1]
  return [list $extra1 $extra2]
}


proc fplan_design_check {{-cell ""}} {
  global FPLAN

  if {$cell == ""} {set cell [lay_editcell]}
  msg "fplan_design_check cell $cell\n"

  set mod [fplan_db_cell module $cell]

  if {$mod == ""} {
    max_error -buffer "No 'module' property on cell $cell"
    set mod [fplan_unfix_name $cell]
  }

  # Look at prb
  set len [llength [set paintballs [db_search_l paint -cell $cell -limit 2 prb]]]
  if {$len == 0} {
    max_error -buffer "No prb layer in cell $cell"
  } elseif {$len > 1} {
    max_error -buffer "Non-rectangular prb layer in cell $cell"
  } else {
    struct max_paint p [lindex $paintballs 0]
    set grid $FPLAN(block_grid)
    setl {fx1 fy1 fx2 fy2} [uusnap -grid $grid ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
    if {[approx $fx1 != ${p.x1}] || [approx $fy1 != ${p.y1}] || \
      [approx $fx2 != ${p.x2}] || [approx $fy2 != ${p.y2}]} {
      # prb layer not on fplan-block grid.  Thats bad.
      max_error -buffer "prb layer not on grid in cell $cell"
    }
  }

  # TODO: Should check that it is on grid, too.

  if {![nl2_loaded $mod]} {
    msg "Cell $cell: No verilog loaded for module $mod, giving up\n"
  }

  # Gather up max labels; look for duplicated labels
  foreach lab_info [db_search_l labels -non_hier -cell $cell] {
    switch -- [labinfo_kind $lab_info] {
      hidden {continue}
    }
    set lab_id [labinfo_text $lab_info]
    if {[info exists max_labels($lab_id)]} {
      max_error -buffer "duplicated label $lab_id"
    }
    set max_labels($lab_id) $lab_info
  }

  set max_label_list [array names max_labels]
  set nl_port_list [nl_list_ports $mod]

  setl {extra_max_ports extra_nl_ports} [ldiff $max_label_list $nl_port_list]

  if {[llength $extra_nl_ports]} {
    max_error -buffer "Cell $cell: The following verilog ports did not appear in max: [lsort $extra_nl_ports]"
  }

  if {[llength $extra_max_ports]} {
    max_error -buffer "Cell $cell: The following max ports did not appear in verilog: [lsort $extra_max_ports]"
  }

  # Look for cells missing from verilog.
  set modobj [nl2_find_designs -exact $mod]
  if {$modobj == ""} {

    max_error -buffer "Cell $cell: Could not find module $mod  ??"

  } else {

    set nl_cell_list ""
    foreach modi [nl_list_cells -noassign $mod] {
      set subdef [nl2_get_cell_ref $modobj $modi]
      if {![nl2_is_rtl_cell $subdef]} {
	lappend nl_cell_list [fplan_fix_name $modi]
      }
    }

    set max_cell_list ""
    foreach cell_info [db_search_l cells -cell $cell] {
      lappend max_cell_list [cellinfo_id $cell_info]
    }
    setl {extra_max_cells extra_nl_cells} [ldiff $max_cell_list $nl_cell_list]

    if {[llength $extra_max_cells]} {
      max_error -buffer "Cell $cell: The following max cells did not appear in verilog: [lsort $extra_max_cells]"
    }

    if {[llength $extra_nl_cells]} {
      max_error -buffer "Cell $cell: The following verilog cells did not appear in max: [lsort $extra_nl_cells]"
    }
  }

  msg "fplan_design_check done\n"
}


proc _fplan_lab_dist {x1 y1 label_info} -desc {
  distance between label and point.
} {
  struct max_label l $label_info
  return [expr sqrt( (${l.x1}-$x1)*(${l.x1}-$x1)+(${l.y1}-$y1)*(${l.y1}-$y1) )]
}


proc fplan_sel_net {{-more} net} -desc {
  Highlight the named verilog net somehow.  Currently makes a flyline.
} {

  set cell [lay_editcell]
  set mod [fplan_db_cell module $cell]
  if {![nl2_loaded $mod]} {
    msg "fplan_sel_net: No verilog loaded; aborting\n"
  }

  if {!$more} {
    db_flyline -delete
    sel_clear
  }

  set hch [verilog_hier_char]
  regsub -all "/" $net $hch verilog_net

  # If you say nl2_get_net_pins -hiearchy, you do not get the non-leaf cell ports.
  # So call it with and without -hiearchy, and draw nets for all.
  if {[catch {set pins [nl2_get_net_pins $mod $verilog_net]}]} {
    # Net not found in mod.
    return
  }

  # The -hierarchy option fails if the design has not been linked.
  # Maybe I should just take this out.
  if {[catch {set hpins [nl2_get_net_pins -hierarchy $mod $verilog_net]} result]} {
    # Turn off the warning for the demo, which is generated all the time
    # because we have not called nl_create_idesign.
    # I dont know to do about this long term.
    # msg "warning: $result\n"
    set hpins ""
  }

  if {[llength $pins]==0 && [llength $hpins]==0} {
    return
  }

  # Eliminate duplicates from pins and hpins.
  foreach guy [concat $pins $hpins] {
    set nodups($guy) 0
  }
  set pins [array names nodups]

  set labels ""
  foreach pin_name $pins {
    set lab_path [_fplan_pin2label $pin_name "individual"]
    if {$lab_path != ""} {
      lappend labels $lab_path
    }
  }
  # msg "Selected net $net pins=$labels\n"

  # If the original net was a label, draw all flylines to that label.
  if {[db_search_label $net] == ""} {
    # Draw flylines in any order.
    for {set i 1} {$i < [llength $labels]} {incr i} {
      set lab1 [lindex $labels $i]
      set lab2 [lindex $labels [expr $i-1]]
      db_flyline $lab1 $lab2
    }
  } else {
    catch {sel_labels -more -text $net}
    for {set i 0} {$i < [llength $labels]} {incr i} {
      set lab1 [lindex $labels $i]
      if {$lab1 == $net} {continue}
      db_flyline $net $lab1
    }
  }
}


proc fplan_sel_net_point {x y} -desc {
  Try to find a label at x,y and select the attached verilog net.
} -doc {
  Called from select_cursed_net when there is no paint under the cursor,
  to see if maybe there is a label under the cursor with verilog
  to tell us what it is hooked to.

  TODO: Should only look in visible cells, but if sub-cell ports are visible,
  then also needs to look in those.
} {

  set near [nearby_dist]
  set ax1 [expr $x-$near]
  set ax2 [expr $x+$near]
  set ay1 [expr $y-$near]
  set ay2 [expr $y+$near]

  # This is an interface choke:  If you specify -cell, then it descends into
  # all loaded cells, not all expanded cells.
  set label_list [db_search_l labels -cell [lay_editcell] -any_cell -area $ax1 $ay1 $ax2 $ay2]

  # Find the nearest label to the point location.
  set nearest_lab_info [lindex $label_list 0]
  if {$nearest_lab_info == ""} {
    # No labels nearby the point.
    return
  }

  set nearest_dist [_fplan_lab_dist $x $y $nearest_lab_info]
  for {set i 1} {$i < [llength $label_list]} {incr i} {
    set this_dist [_fplan_lab_dist $x $y [lindex $label_list $i]]
    if {$nearest_dist > [_fplan_lab_dist $x $y [lindex $label_list $i]]} {
      set nearest_dist $this_dist
      set nearest_lab_info [lindex $label_list $i]
    }
  }

  struct max_label l $nearest_lab_info

  fplan_sel_net ${l.path}${l.text}
}


proc _fplan_pin2label {{-skip_mod ""} pin_name control} {

  set hch [verilog_hier_char]
  set dot [string last $hch $pin_name]
  if {$dot == -1} {
    # Its a top-level pin
    set cellidb "."
    # The pin_name is just the top level port name.
    set portb $pin_name
    if {$control == "individual"} {
      # These are not grouped by region, so consider each pin
      # its own unique region.
      set conb $portb
    } elseif {$control == "center"} {
      set regionb [fplan_db_pin -cell [lay_editcell] getregion $portb]
      if {$regionb == "center" } {
	msg "flylines: ignoring pin $portb, which is not placed properly\n"
      } else {
	#set conb _hidden_[fplan_db_pin -cell [lay_editcell] getregion $portb]
	set conb "{*$regionb*}"
      }
      if {[llength [db_search_l labels -cell $celldef -non_hier -exact $conb]] == 0} {
	# No hidden labels.  Use real port name.
	set conb $portb
      }
    } else {
      return "" ;# Not shown
    }
  } else {
    set modib [string range $pin_name 0 [expr $dot-1]]
    set portb [string range $pin_name [expr $dot+1] end]
    # Skip connections from cell to itself
    if {$modib == $skip_mod} {continue}
    if {[catch {set cellb [fplan_db_cell modi2cell $modib]}] || $cellb == ""} {
      # This happens if the user deleted a cell that should
      # be connected by flylines.  We dont want to error out
      # because this code is called every time the user clicks on a cell.
      msg "flyline warning: can not find cell corresponding to module $modib\n"
      return ""
    }
    #if {[fplan_cell_info -is_lef $cellb]} {
    #  set cellidb $modib
    #} else {
    #  set cellidb [fplan_db_cell modi2celli $modib]
    #}
    set cellidb [fplan_db_cell modi2celli $modib]
    if {$control == "individual"} {
      set conb ${cellidb}/${portb}
    } else {
      if {$control == "center"} {
	set regionb "center"
      } else {
	set regionb [fplan_db_pin -cell $cellb getregion $portb]
      }
      # Connect to the hidden port with this name.
      #set conb _hidden_$regionb
      set conb "{*$regionb*}"
      if {[llength [db_search_l labels -cell $cellb -non_hier -exact $conb]] == 0} {
	# No hidden labels.  Use real port name.
	set conb $portb
      }
    }
  }

  return $conb
}


proc fplan_post_command_hook {} -desc {
  Called after each interactive command to do fplan maintenance.
} {
  global CELL FPLAN _FPLAN_PREV_CELL_LIST
  if {!$FPLAN(exists) || !$FPLAN(verilog_autoload)} {return}

  set cell_things [db_cells -user]

  if {$cell_things == [use_first _FPLAN_PREV_CELL_LIST]} {
    # No changes since last call; just return
    return
  }
  set _FPLAN_PREV_CELL_LIST $cell_things

  # Try to load verilog for all max cells in memory.
  foreach cell_thing [split [string trim $cell_things] \n] {
    setl {cell flags filename changes junk} $cell_thing
    if {[lsearch -exact flags generated] != -1} {
      continue ;# Skip gcells
    }
    if {$filename != "" && $filename != "$CELL(UNNAMED)"} {
      fplan_verilog_auto_load -maxfile $filename
    }
  }
}


proc steiner_test {} -desc {
  Code to test the steiner router.
} -desc {
  Route the ports in the current file.  One can be an output port.
  Show the boxex that result.
} {
  # Need pats version to fix small bugs in steiner_package.
  util_load_pkg pats_steiner_package.so Steiner_package

  lay_line -clear
  steiner_begin_net foo
  foreach lab_info [db_search_l labels -non_hier] {
      struct max_label l $lab_info
      switch -- ${l.kind} {
	input { set iodir input }
	output { set iodir  output }
	default { set iodir inout }
      }
      puts "steiner_add_point {} ${l.text} $iodir [expr int(round(${l.x1}))] [expr int(round(${l.y1}))]"
      steiner_add_point "" ${l.text} $iodir [expr int(round(${l.x1}))] [expr int(round(${l.y1}))]
  }
  foreach box [steiner_get_route] {
    puts $box
    layt_rect [lindex $box 0] [lindex $box 1] [lindex $box 3] [lindex $box 4]
  }

}
