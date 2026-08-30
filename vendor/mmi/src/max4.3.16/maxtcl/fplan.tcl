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

set RCSVERSION(fplan.tcl) { $Revision: 1.12 $ }

# DEF from physopt has \[ and \], so vaughn couldnt read it.

# Add ichip.rc and jchip.rc.  Use nl2_read_lef -direct

# TODO: Use DEF format for fplan_read_props/fplan_write_props.

# TODO: Read DEF hhierarchical needs to ignore flattened cells.  (maybe fixed?)

# TODO: Add rectangular regions.  They need to go in the .etc file.

# TODO: area estimator needs to look in the cover cell
#	to subtract obstruction area, including L-shaped blocks.

# TODO: Put "FIXED" in lay_cell_text?  Maybe not so needed now.

# TODO: show all flylines - need to ignore flattened cells.

# TODO: dbt_flyline is broken in maxy.

# TODO: Dont allow "flatten" as an option for LEF cells on Block Properties menu.

# TODO: read_cell_props.  Fails if not in the cell?
#	read_cell_props into UNNAMED, get db_bbox - couldnt find cell?

# Getting the error "No PRB label in cell foo" from jchip_block
# when sub-editing: it should not complain because there is PRB layer there.

# Need way to "goldify" after placement: copy the pertinent information
# back to the golden max per-placement file.  Equivalent to delete non-fixed.
# Update: If we use iconified flattened cells, any cell can be saved
# as the "golden" cell.

# Add Help to color map - stipples that when combined obstruct 50% will render
# subcells invisible with using dim-non-edit cells.  For example, the stipples
# for nw and nplus when combined must not do this.  Also, layers that
# commonly overlap between parent and subcells, eg: PRB, should be chosen
# from stipples that will not cause noticeable differences in shading when
# overlapped with different origins.  For example, cross hatched lines bad, 
# little circles good.  Occurs in both max and gdsplot.

# Set LAY_PAINT_ZOT really big.  This may need to be an option.
# When size is smaller than LAY_PAINT_ZOT, mha does not redraw contents
# of cells, he just stipples everything at once.  Thus, even if prb
# is a stipple with zero pixels set, it will show up as a solid if
# the LAY_PAINT_ZOT is exceeded.

# T-menu: should highlight nets that were selected in max via flylines.
#	option just show selected nets

# T-menu: when you switch from ports to nets, the net attached to
#	selected ports should be highlighted.

##### FLYLINES ######

# Flylines should be a hot-key, not automatic on cell selection.
# Need flyline "AND" mode, to show flylines between blocks.

# Trace through cells that have only one input and one output.

# Add a mode to display only flylines between two cells.

# Draw inter-cell flylines by doing a steiner route and drawing paint.
# This would let you find them.  Could even label them.


#======================================================================
# TODO NOW
#======================================================================

##### CONGESTION ANALYZER ######

# TODO: Do we need a way to mark leaf cells for timing.

# TODO: Congestion analyzer: Try an example with non-0 origins.

# TODO: Compute congestion number like ibm tools: take top 20% congested bins and print average.
#	Note that the reason they shoot for 70% is because they take power grid into
#	account later.

# TODO: Add a C data-base for wiring info, use it in congestion analyzer.

# TODO: Congestion analyzer:  Since you cant clear the nl x_tracks or y_tracks,
# you can only run it once!!!  Or maybe it works - maybe it just uses the last one defined!!


# BUG: "Stretch selected block" fails if you have  a cell selected.

# TODO: Do a test to make sure it is ok to link nl memory allocator from both max and nl
#	as a shared object - what happens to the global variable in nl?
#	Do both point to the same var, or are there two copies?

# TODO: When you click on a cell to show flylines, the selected nets
#       should be highlighted in the "T" (Edit Connectivity) lisbox.
#       Ditto when you select labels.

# TODO: Should port direction from $b be reversed?

# BUG: tim.tcl: Top cell is in generated tmp.vg  twice.

# BUG: The "flat" option on pearl just fails.

# TODO: Jim says that tracks output in def do not run all the way
#	to the left edge where the ports are placed.  He has wierd
#	wiring offsets.  From initial inspection, looks like
#	the TRACKS are being rounded up too much to avoid half wire width.

# TODO: Add a global bit-pitch to the port legalizer.
#	Add option to just spread out the ports on their side.

# BUG: Flipping a cell screws up its origin.  Flipping two works, because
#       of the stupid heuristics.

# TODO: Warn for user-expr ports that land on an obstruction.

# TODO: Run Placer menu: Add option to do just selected ports or all ports.

# TODO: Edit connectivity menu (label.tcl) should report wire length.
#       Need to get it from steiner route.  Add an indication if a repeater
#       would be needed.
#       Related: Add code to show steiner route, too.
#       Could make it a tool on the Edit Connectivity menu.

#======= B list ===================
# TODO: In T-menu: allow $b in the basic placement x/y locations.

# BUG: Movement of cell by keyboard arrows gets it off grid.
# BUG: Movement of labels should be constrained, too?

# TODO: Make cell grid 10 tracks wide so power can be drilled at regular intervals.

# TODO: Put the "Create Merge Overwrite" on the main import verilog propmenu.
# TODO: This dialog ALWAYS comes up!

# TODO: Add option in import sue to add new blocks, but NOT change
#       existing placement.  Did I already do this?
#       Test sue->fplan.

# TODO: If an instance references an undefined module, jim wants it to ask
#       what to do: ignore it or create a dummy module.  Maybe put it in
#       an orphan directory.  I dont where it goes, because there's no verilog dir.

# TODO: port placement menu: allow place-ports on all selected cells at once.

# TODO: When reading verilog, warn if it does not match the max file. (jb request)
#       Can check number of ports and number of cells.  Tell user to
#       run design checker to diff the two.
#       ALTERNATIVE: add option to auto-design-check every newly read file?

# TODO: Warn if max file contains zero size cells, which are caused by
#       missing or empty max cell.  jballard requested, but I dont think
#       it should be automatic.  Part of design checker?

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


# Rejected: Restore read/write/edit .ports file.  Needs to work on current cell
#       if none selected.
#       Answer: Ports files going away.  Will save info to nl database instead.

# Rejected: Import verilog: jballard asked that if there is no module,
#       should still get the port names.  However, we dont know the
#       port I/O direction in that case.

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


# Note: the slack is generated, but we go ahead and save it anyway.
set FPLAN_PORT_OPTIONS {{place "unplaced"} {layerspec "space"} {locspec ""} {bitloc ""} \
		{ext_budget ""} {int_budget ""} {ext_driver ""} {ext_cap ""} {int_cap ""} \
		{ext_actual ""} {int_actual ""} {int_drive_res ""} {slack ""}}

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
use_init FPLAN(verilog_auto_check) 0
use_init FPLAN(design_root) ""

init_global FPLAN(cell_props) {min_area cell_area_util wire_util}

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
  NOT USED
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

    set cell_list [sel_what_cells -limit 2]
    if {[llength $cell_list] == 1} {
      set cell_info [lindex $cell_list 0]
      #fplan_show_flylines [cellinfo_id $cell_info] [cellinfo_def $cell_info]
      flyc_sel_cell $cell_info
    }

    if {$FPLAN(flyline_ports) != "off"} {
      # Also show flylines for selected labels.
      foreach lab_info [sel_what_l labels] {
	switch [labinfo_kind $lab_info] {
	  "global" -
	  "input" -
	  "output" -
	  "inout" {
	    fplan_sel_net -more [labinfo_text $lab_info]
	  }
	}
      }
    }

    cursor_busy 0
  }

  # Unset nl_current_design.  This helps find bugs where
  # some code is assuming that nl_current_design is set to
  # the current cell.
  if {[nl2_loaded]} {
    nl2_unset_current_design
  }
}


proc fplan_set_bbox {{-erase} {-cell ""} x1 y1 x2 y2} {
  if {$cell == ""} {
    set cell [lay_editcell]
  }
  set prb [techinfo layer prb]

  # Delete any existing prb paint.
  eval db_paint -cell $cell -erase $prb [db_bbox -cell $cell]
  # Delete any existing prb labels.  Gack
  if {[llength [db_search_labels -non_hier -cell $cell bbox]] != 0} {
    edit_push_direct $cell
    sel_labels -layer $prb -text bbox
    :delete
    edit_pop_direct
  }

  if {!$erase} {
    db_label -cell $cell -pos sw -kind comment $prb bbox $x1 $y1 $x2 $y2
  }
}


proc fplan_bbox {{-grid ""} {-parent} {-test} {-cell ""} {-cellid ""}} -desc {
  Return bbox of floorplan cell.
} -doc {

  Must specify which cell either by -cell <def_name>, or by -cellid <inst_name>

  If -grid user, snap to user grid instead of the big fplan-grid.
  If -grid mask, snap to mask grid.
  If -parent, return bbox in coordinates of lay_editcell (requires -cellid option.)
  If -test, return "" if no specific bbox, and dont complain.

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
    set cell [cellinfo_def [dbt_find_cell -fast 1 $cellid]]
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
    set coords [list 0 0 $xsize $ysize]
  } else {

    # Get the size of the current prb layer.  It better be a rectangle.
    set prb [techinfo layer prb]
    set badmsg ""
    set coords [list]
    set prb_label [db_search_l labels -layers $prb -cell $cell -kind comment -non_hier bbox]
    if {[llength $prb_label] > 1} {
      set badmsg "multiple prb labels"
    } elseif {[llength $prb_label] == 1} {
      set coords [labinfo_loc [lindex $prb_label 0]]
    } else {

      set prb_list [db_search_l paint -cell $cell $prb]
      if {[llength $prb_list] > 1} {
	# prb layer consists of multiple rectangles.  Thats bad.
	set badmsg "non-rectangular"
      } elseif {[llength $prb_list] == 1} {
	# Found a prb paint layer.
	struct max_paint p [lindex $prb_list 0]
	set coords [list ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
      }
    }

    # Make sure prb layer is on grid.
    if {[llength $coords] != 0} {
      setl {px1 py1 px2 py2} $coords
      setl {fx1 fy1 fx2 fy2} [uusnap -grid $grid $px1 $py1 $px2 $py2]
      if {[approx $fx1 != $px1] || [approx $fy1 != $py1] || \
	[approx $fx2 != $px2] || [approx $fy2 != $py2]} {
	# prb layer not on fplan-block grid.  Thats bad.
	set badmsg "not on grid (cur=$coords on-grid=$fx1 $fy1 $fx2 $fy2)"
      }
    }


    if {$badmsg != "" && $grid == $FPLAN(block_grid) && !$test} {
      msg "warning: PRB layer in cell $cell is damaged ($badmsg).\n"
    }

    #if {$badmsg != "" && $grid == $FPLAN(block_grid)} {
    #  set msg "PRB layer in cell $cell is damaged ($badmsg).  Fix it?"
    #  set choice [tk_dialog .dialog "Fix Floorplan Block Damage" $msg {} 0 \
    #		  Yes No Cancel]
    #  if {$choice == 2} {error "Operation cancelled"}
    #  if {$choice == 1} {
    #	# choice "no".  Just return existing bbox.
    #	return [db_bbox -cell $cell]
    #  }
    #  # Fix it by drawing prb everywhere.
    #  # This sucks!  It really wants to have its origin at 0,0
    #  setl {oldx1 oldy1 oldx2 oldy2} [eval uusnap -grid $grid [db_bbox -cell $cell]]
    #  eval db_paint -cell $cell -erase $prb [db_bbox -cell $cell]
    #  eval db_paint -cell $cell $prb [eval uusnap -grid $grid $oldbox]
    #  set prb_list [db_search_l paint -cell $cell $prb]
    #  set coords ...
    #}

    if {[llength $coords] == 0} {
      if {$test} {return ""}
      msg "warning: cell $cell no prb layer ($prb) found, using cell size for bbox\n"
      # No prb layer found.
      set coords [db_bbox -cell $cell]
      set coords [eval uusnap -grid $grid $coords]
    }
  }

  if {$parent && $cell != [lay_editcell]} {
    # Must transform to root-cell coords in lay_editcell.
    # First have to find the bloody thing.
    struct max_cell c [lindex [db_instances -id $cellid] 0]
    setl {x1 y1 x2 y2} $coords
    setl {x1 y1} [transform_coords ${c.transform} $x1 $y1]
    setl {x2 y2} [transform_coords ${c.transform} $x2 $y2]
    # If cell is flipped, coords might get flipped too, so fix.
    set coords [can_rect [list $x1 $y1 $x2 $y2]]
  }
  return $coords
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
  global _FPLAN_PROPS_TMP

  set area1 [fplan_get_lef_area -lef $_FPLAN_PROPS_TMP(cell)]
  set area2 [fplan_get_lef_area $_FPLAN_PROPS_TMP(cell)]

  if {[approx $area1 == $area2]} {
    set contents_area $area1
  } else {

    set prop_list ""
    set which area2
    lappend prop_list [list "compute area" which -radio [list \
      "add LEFs of leaf cells but current size (prb) of non-leaf cells ($area2)" \
      "add up only hierarchically contained LEFs ($area1)"] -values {area2 area1}]
    
    if {![prop_menu2 $prop_list]} {
      return ;# cancelled
    }

    if {$which == "area1"} {
      set contents_area $area1
    } else {
      set contents_area $area2
    }
  }

  # Update prop_menu.
  set current_area [expr $_FPLAN_PROPS_TMP(x_size) * $_FPLAN_PROPS_TMP(y_size)]
  set current_utilization [expr {$current_area ? 100.0 * $contents_area / $current_area : 0}]
  set current_utilization [format "%.1f" $current_utilization]

  set _FPLAN_PROPS_TMP(contents_area) $contents_area
  set _FPLAN_PROPS_TMP(current_utilization) $current_utilization
}

proc fplan_block_props {{cellid ""}} -desc {
  prop menu for props of specified block (defaults to selected).
} -doc {
  If you are editing props for lay_editcell, you can only
  edit props related to the def, not instance props.
} {
  global FPLAN _FPLAN_PROPS_TMP
  catch {unset _FPLAN_PROPS_TMP}

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
      # The origin is unknown: leave it as - -
      set _FPLAN_PROPS_TMP(original_location) [list $ox1 $oy1 $ox2 $oy2 - -]
    } else {
      #set cell [cell_id2cell $cellid]
      set cell [cellinfo_def [dbt_find_cell $cellid]]
      setl {ox1 oy1 ox2 oy2} [fplan_bbox -grid mask -parent -cellid $cellid]
      set modid [fplan_db_inst celli2modi $cellid]

      setl {originx originy} [cell_origin [lindex [db_instances -id $cellid] 0]]
      set _FPLAN_PROPS_TMP(original_location) [list $ox1 $oy1 $ox2 $oy2 $originx $originy]
    }
    set is_lef [fplan_cell_info -is_lef $cell]

    set _FPLAN_PROPS_TMP(cellid) $cellid
    set _FPLAN_PROPS_TMP(cell) $cell

    setl {_FPLAN_PROPS_TMP(x_size) _FPLAN_PROPS_TMP(y_size)} \
	  [list [expr $ox2 - $ox1] [expr $oy2 - $oy1]]
    set _FPLAN_PROPS_TMP(x_origin) $ox1
    set _FPLAN_PROPS_TMP(y_origin) $oy1

    set _FPLAN_PROPS_TMP(timing) $cell
    # Note: The min_area was originally put in for the user to specify a
    # target area before the blocks had verilog contents.  But it was too
    # hard to use - jim ballard just set the x_size and y_size;
    # so I am slowly taking min_area out.  - pat -
    set _FPLAN_PROPS_TMP(min_area) [db_prop -def $cell min_area]
    if {$_FPLAN_PROPS_TMP(min_area) == ""} {set _FPLAN_PROPS_TMP(min_area) 0}

    set _FPLAN_PROPS_TMP(cell_area_util) [db_prop -def $cell cell_area_util]
    if {$_FPLAN_PROPS_TMP(cell_area_util) == ""} {
      set _FPLAN_PROPS_TMP(cell_area_util) $FPLAN(default_area_util)
    }

    set modname [db_prop -def $cell module]
    if {$modname == ""} {
      # Block was not read in from verilog
      set modname "*unknown*"
      set modid "*unknown*"
    }
    set _FPLAN_PROPS_TMP(modtype) [db_prop -def $cell modtype]
    if {$_FPLAN_PROPS_TMP(modtype) == ""} {
      set _FPLAN_PROPS_TMP(modtype) [lindex $FPLAN(block_type_list) 0]
    }

    set _FPLAN_PROPS_TMP(place) [fplan_db_inst getprop $cellid place]
    if {$_FPLAN_PROPS_TMP(place) == ""} {
      set _FPLAN_PROPS_TMP(place) "unplaced"
    }

    set prop_list ""

    if {$cellid == "."} {
      # Only display a subset of props for lay_editcell
      lappend prop_list [list {verilog module} modname -label]
    } else {
      lappend prop_list [list {INSTANCE PROPERTIES} "" -label]
      if {$is_lef} {
	lappend prop_list [list "This is a LEF cell" "" -label]
      } else {
	lappend prop_list [list "This is a hierarchical cell" "" -label]

	lappend prop_list [list {verilog module} modname -label]
	lappend prop_list [list {verilog instance} modid -label \
	      -help {The name of the block, which must be the same as\
	      the base name of the associated schematic.}]
      }

      lappend prop_list [list x_origin _FPLAN_PROPS_TMP(x_origin) -number -incr $snapx]
      lappend prop_list [list y_origin _FPLAN_PROPS_TMP(y_origin) -number -incr $snapx]
      lappend prop_list [list "Placer placement" _FPLAN_PROPS_TMP(place) -choice {unplaced fixed flatten} \
	-help {\
	If marked "fixed", the placement will not be modified. \
	Distinguishing between placed and unplaced is not currently necessary; \
	the cell has been "placed" if physopt was called, but we dont need to save that fact. }]
    }

    lappend prop_list [list "" "" -separator]

    lappend prop_list [list {CELL TYPE PROPERTIES} "" -label]

    if {! $is_lef} {
      set _FPLAN_PROPS_TMP(congestion_effort) [db_prop -def $cell congestion_effort]
      if {$_FPLAN_PROPS_TMP(congestion_effort) == ""} {set _FPLAN_PROPS_TMP(congestion_effort) none}
      lappend prop_list [list "Placer Congestion Effort" _FPLAN_PROPS_TMP(congestion_effort) -choice "none low medium high"]
      set _FPLAN_PROPS_TMP(timing_effort) [db_prop -def $cell timing_effort]
      if {$_FPLAN_PROPS_TMP(timing_effort) == ""} {set _FPLAN_PROPS_TMP(timing_effort) low}
      lappend prop_list [list "Placer Timing Effort" _FPLAN_PROPS_TMP(timing_effort) -choice "low medium high"]

      set _FPLAN_PROPS_TMP(stack_above) [db_prop -def $cell stack_above]
      lappend prop_list [list "Stack cell above cells" _FPLAN_PROPS_TMP(stack_above) -entry \
	-help {for overlapping hierarchical cells: the list of cell ids that do not create\
	  obstructions in this cell.  One way to think about this is that the selected cell\
	  is above the cells listed in this property in the stacking order.}]

      set _FPLAN_PROPS_TMP(place_obstruct_parent) [db_prop -def $cell place_obstruct_parent]
      if {$_FPLAN_PROPS_TMP(place_obstruct_parent) == ""} {set _FPLAN_PROPS_TMP(place_obstruct_parent) no}
      lappend prop_list [list "Obstruct parent" \
	_FPLAN_PROPS_TMP(place_obstruct_parent) -choice "no yes" \
	-help {This property is attached to hierarchical cells to allow/dis-allow\
	the parent cell to use excess area within the hierarchical cell to place\
	standard cells (from the parent).  These obstructions would have no\
	effect on the placement or routing of the hierarchical cell, only how\
	the excess space is used by the parent.}]

      set tmp [db_prop -def $cell place_wire_obstruct_x]
      set _FPLAN_PROPS_TMP(place_wire_obstruct_x) [use_first tmp FPLAN(place_wire_obstruct_x) '80]
      lappend prop_list [list "Available wiring resources in x (%)" _FPLAN_PROPS_TMP(place_wire_obstruct_x) -entry \
	-help {This property is attached to hierarchical cells or the top level\
	cell to attempt to limit the routing resources used over the cell.\
	In the case of hierarchical cells, the limit would first be imposed when\
	the hierarchical cell is being placed.  Later when the placed\
	hierarchical cell is a fixed structure in the top level placement, the\
	limit would be used again as a constrained region over the top of the\
	hierarchical cell.  Note that if the hierarchical cell placement used\
	most or all of the available routing resource, then the top level cell\
	would have no usable resource available in this region during it's\
	placement.  Thus the region would behave as though the metal layers were\
	completely obstructed.
	When the limit is applied to the top level module, then that limit is\
	applied to the entire top level bounding box (the exception being\
	hierarchical cells in the top cell with there own limits). 
	A few of notes about physopt (in relation to routing limits): first, it\
	defaults to 80% (in both X and Y) if we don't pass a routing limit to\
	it, second, this same limit is passed to the congestion_report functions\
	as a basis for determining what level of congestion should be reported\
	as an error.  Finally, if physopt is not be able to satisfy these\
	limits, they will simply be reported as errors in the congestion_report\
	(following a really long run time), but placement should complete regardless.}]

      set tmp [db_prop -def $cell place_wire_obstruct_y]
      set _FPLAN_PROPS_TMP(place_wire_obstruct_y) [use_first tmp FPLAN(place_wire_obstruct_y) '80]
      lappend prop_list [list "Available wiring resources in y (%)" _FPLAN_PROPS_TMP(place_wire_obstruct_y) -entry]


    }

    # This is redundant with filename:
    #lappend prop_list [list {max cell} cell -label]

    #lappend prop_list [list "design target area" _FPLAN_PROPS_TMP(min_area) -number \
	    -incr [expr [max $snapx $snapy]] \
	    -help {minimum total area, used for stretching}]

    lappend prop_list [list x_size _FPLAN_PROPS_TMP(x_size) -number -incr $snapx \
	    -help {fixed x dimension}]
    lappend prop_list [list y_size _FPLAN_PROPS_TMP(y_size) -number -incr $snapy \
	    -help {fixed y dimension}]

    set current_area [expr $_FPLAN_PROPS_TMP(x_size) * $_FPLAN_PROPS_TMP(y_size)]
    lappend prop_list [list "current area" current_area -label]

    lappend prop_list [list "Recalculate contents area now" "" -button _fplan_block_props_calc_area]

    use_init _FPLAN_PROPS_TMP(contents_area) "*not calculated*"
    lappend prop_list [list "contents area" _FPLAN_PROPS_TMP(contents_area) -label]

    #lappend prop_list [list "%area utilization" _FPLAN_PROPS_TMP(cell_area_util) -number 1 100\
	    -help {x_size * y_size must be greater than min_area * %utilization}]

    if {$_FPLAN_PROPS_TMP(contents_area) == "*not calculated*"} {
      set current_utilization "*not calculated*"		;# Dont know yet.
    } else {
      set contents_area $_FPLAN_PROPS_TMP(contents_area)
      set current_utilization [expr {$current_area ? 100.0 * $contents_area / $current_area : 0}]
      set current_utilization [format "%.1f" $current_utilization]
    }
    use_init _FPLAN_PROPS_TMP(current_utilization) $current_utilization
    lappend prop_list [list "current utilization%" _FPLAN_PROPS_TMP(current_utilization) -label]

    #lappend prop_list [list "module type" _FPLAN_PROPS_TMP(modtype) -choice $FPLAN(block_type_list)]

    set _FPLAN_PROPS_TMP(grid) $grid
    lappend prop_list [list "cell placement grid" _FPLAN_PROPS_TMP(grid) -choice "$FPLAN(block_grid) user"]

    set filename [cell_file $cell]
    lappend prop_list [list "filename" filename -label]

    if {$cellid != "." && ! $is_lef} {
      lappend prop_list [list {uniquify placement of this cell} "" -button "_fplan_uniquify_cell $cellid" -return 2]
    }

  if {0} {
    lappend prop_list [list "" "" -separator]

    lappend prop_list [list {TIMING PROPERTIES} "" -label]
    
    lappend prop_list [list {timing model} _FPLAN_PROPS_TMP(timing) -entry]
    if {$cellid != "."} {
      lappend prop_list [list {uniquify timing of this cell} "" -button {warning "not implemented!"} -return]
    }
    lappend prop_list [list "view timing model..." "" -button {warning "not implemented!"}]
  }

    # Snap coords to fplan grid
    # 1/7: Took this out.  If it is a lef cell, this is totally wrong
    # because it is only one row high, and the grid is two high.
    # I dont know why you would want to snap a hierarchical cell, either.
    setl {nx1 ny1 nx2 ny2} [uusnap -grid $grid $ox1 $oy1 $ox2 $oy2]
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


  catch {unset _FPLAN_PROPS_TMP}
}

proc _sel_cell_by_pattern {pat} -desc {
  TEMPORARY!!  Mha is adding to sel_cell
} {
  sel_clear
  foreach cellinfo [db_search_cells] {
    set id [cellinfo_id $cellinfo]
    if {[string match $pat $id]} {
      sel_cell -more $id
    }
  }
}

proc dbt_search_cells_by_pattern {pat} {
  set result ""
  foreach cellinfo [db_search_cells] {
    set id [cellinfo_id $cellinfo]
    if {[string match $pat $id]} {
      lappend result $cellinfo
    }
  }
  return $result
}


proc fplan_cell_flatten {{-flatten 1} cell_info} {
  
  set cellid [cellinfo_id $cell_info]
  set cell [cellinfo_def $cell_info]
  set hsep [expr {[use_list_path] ? "/" : "{FS}"}]

  if {$flatten} {

      # Flatten it.
      # If the cell we are dumping contains labels in exactly the same spot
      # as existing labels, then the dumping them into the main cell and deleting
      # them will delete both labels.
      # So instead, do the deletion in a temporary cell, then copy that.

      setl {ox1 oy1 ox2 oy2} [fplan_bbox -grid mask -parent -cellid $cellid]
      setl {originx originy} [cell_origin $cell_info]
      set original_location [list $ox1 $oy1 $ox2 $oy2 $originx $originy]

      catch {db_cell_delete __FPLAN_PROPS_TMP__}
      db_cell_new -no_undo -internal __FPLAN_PROPS_TMP__
      edit_push_direct __FPLAN_PROPS_TMP__
      setl {x y} [cellinfo_loc $cell_info]
      :dump -instance_prefix "${cellid}${hsep}" $cell child 0 0 parent $x $y
      # The dump copied everything, left it selected.
      # We only want the cells, so deselect them and delete everything else.

      eval sel_area -less -any_cell -layers subcell [lay_bbox]
      :delete
      edit_pop_direct
      :dump -dup_ok __FPLAN_PROPS_TMP__ child 0 0 parent 0 0
      #db_cell_delete __FPLAN_PROPS_TMP__

      # Remove subcells from inside the flattened cell
      # This is kind of a choke.
      edit_push_direct $cell
      eval sel_area -layers subcell [lay_bbox]
      :delete
      edit_pop_direct

      # Iconify it.  Save old position so we can restore it later.
      db_prop -def $cell location $original_location

      # Find x,y for new icon, search for empty spot.
      # Icons will be 5x5 at locations -10,0; -10,10; -10,20, etc.
      setl {ix iy} "5 5"     	;# Icon size.
      setl {ix2 iy2} "10 10" 	;# Icon origin separation.
      setl {bx1 by1 bx2 by2} [lay_bbox]
      set maxx [max $bx2 50]
      set fnd 0
      set y 0
      do {
	set y [expr $y-$iy2]
	for {set x 0} {$x < $maxx} {set x [expr $x+$ix2]} {
	  if {0 == [llength [db_search_cells -limit 1 -area $x $y [expr $x+$ix] [expr $y+$iy]]]} {
	    set fnd 1
	    break
	  }
	}
      } while {!$fnd}
      fplan_set_bbox -cell $cell 0 0 $ix $iy
      # Move to icon location
      db_instance_delete $cellid
      db_instance -id $cellid -orientation [orientation [cellinfo_transform ${cell_info}]] $cell $x $y
  } else {
      # Unflatten it.  We will snap it to its old spot, but we
      # wont bother to actually flatten all the cells.
      # That will be done by placer interface.

      setl {x1 y1 x2 y2 originx originy} [db_prop -def $cell location]
      fplan_set_bbox -cell $cell 0 0 [expr $x2-$x1] [expr $y2-$y1]
      db_instance_delete $cellid
      db_instance -id $cellid -orientation [orientation [cellinfo_transform ${cell_info}]] $cell $x1 $y1

      # We need to cut the initial hierarchy off of every instance name,
      # and move them by -$originx,-$originy.  Can do both at once.
      set cutlen [string length ${cellid}${hsep}]
      set cnt 1
      foreach instinfo [dbt_search_cells_by_pattern "[quote_glob ${cellid}]${hsep}*"] {
	set id [cellinfo_id $instinfo]
	setl {ox oy} [cell_origin $instinfo]
	db_instance_delete $id
	db_instance -cell $cell -id [string range $id $cutlen end] \
		-orientation [orientation [cellinfo_transform $instinfo]] \
		[cellinfo_def $instinfo] [expr $ox-$originx] [expr $oy-$originy]
	if {[incr cnt] % 1000 == 0} {msg "...${cnt}...\n"}
      }

      # To undo a former nl_ungroup, you must reread the verilog module.
      # This is not quite right, because there could be multiple restore contents in nlTODO: Try to restore its contents?
  }
}

proc _fplan_props_apply {} {
  global _FPLAN_PROPS_TMP

  # Reselect the cell.  If it was uniquified, the cell def name has changed.
  set cellid $_FPLAN_PROPS_TMP(cellid)
  if {$cellid == "."} {
    set cell [lay_editcell]
  } else {
    set cellinfo [lindex [db_instances -id $cellid] 0]
    set cell [cellinfo_def $cellinfo]
  }


  # New x_size and y_size It should be ok, but make sure!
  setl {x_size y_size} [uusnap -grid $_FPLAN_PROPS_TMP(grid) $_FPLAN_PROPS_TMP(x_size) $_FPLAN_PROPS_TMP(y_size)]

  if {$cellid != "."} {
    set old_place [fplan_db_inst getprop $cellid place]
    if {$x_size == 0 || $y_size == 0 && $old_place != "flatten"} {
      max_error "floorplan error: Size may not be 0"
      return
    }
  }

  #db_prop -def $cell min_area $_FPLAN_PROPS_TMP(min_area)
  #db_prop -def $cell wire_util $wire_util
  #db_prop -def $cell modtype $_FPLAN_PROPS_TMP(modtype)
  #db_prop -def $cell cell_area_util $_FPLAN_PROPS_TMP(cell_area_util)
  if {$_FPLAN_PROPS_TMP(grid) == "user"} {
    db_prop -def $cell grid ""
  } else {
    db_prop -def $cell grid $_FPLAN_PROPS_TMP(grid)
  }

  foreach prop "congestion_effort timing_effort stack_above place_obstruct_parent \
	place_wire_obstruct_x place_wire_obstruct_y" {
    if {[info exists _FPLAN_PROPS_TMP($prop)]} {
      db_prop -def $cell $prop $_FPLAN_PROPS_TMP($prop)
    }
  }

  if {$cellid != "."} {
    # Get previous instance property.
    set new_place $_FPLAN_PROPS_TMP(place)
    if {$new_place == "unplaced"} {
      # We mark cells "unplaced" by removing the place prop.
      set place ""
    }
    fplan_db_inst setprop $cellid place $new_place

    # Do we need to flatten or unflatten it?
    if {$new_place == "flatten" && $old_place != "flatten"} {

      # Flatten it
      fplan_cell_flatten -flatten 1 $cellinfo

      # Skip the move/resize code below.
      return

    } elseif {$new_place != "flatten" && $old_place == "flatten"} {

      # Unflatten it
      fplan_cell_flatten -flatten 0 $cellinfo

      # Skip the move/resize code below.
      return
    }
  }

  # Resize, if needed.
  setl {nx1 ny1 nx2 ny2} $_FPLAN_PROPS_TMP(original_location)
  set original_xsize [expr $nx2-$nx1]
  set original_ysize [expr $ny2-$ny1]
  set size_changed 0
  if {[approx $original_xsize != $x_size] || [approx $original_ysize != $y_size]} {
    # Set box to new size, and change it.
    setl {bx1 by1 bx2 by2} [fplan_bbox -cell $cell]
    fplan_set_bbox -cell $cell $bx1 $by1 [expr $bx1 + $x_size] [expr $by1 + $y_size]
    set size_changed 1
  }

  # Move, if needed.
  if {$cellid != "."} {
    sel_cell2 $cellid ;# Leave cell selected for user convenience

    # Move cell to new location.
    if {[approx $nx1 != $_FPLAN_PROPS_TMP(x_origin)] || [approx $ny1 != $_FPLAN_PROPS_TMP(y_origin)]} {
      sel_move [expr $_FPLAN_PROPS_TMP(x_origin) - $nx1] [expr $_FPLAN_PROPS_TMP(y_origin) - $ny1]
    }
  }

  if {$size_changed} {
    update idletasks
    set msg "Do you want to re-legalize the ports?"
    set choice [tk_dialog .dialog "Cell $cell" $msg {} 0 Yes No]
    if {$choice == 0} {
      fplan_port_legalize -resize $_FPLAN_PROPS_TMP(original_location) $cell
    }
  }

  set new_area [expr $x_size * $y_size]
  # The min_area is supposed to be the minimum area when stretching.
  # Otherwise, mulitple stretches would slowly grow the block.
  db_prop -def $cell min_area $new_area
}


proc _fplan_block_resize_int {cell} -desc {
  Resize selected leaf cell to match box.
} -doc {
  Cell can be the edit cell or a selected instance in the edit cell.
} {
  global FPLAN
  set grid $FPLAN(block_grid)
  #set prb [techinfo layer prb]

  # New requested size
  setl {nx1 ny1 nx2 ny2} [layt_box exact]

  # Save in cell coords for use by fplan_port_legalize
  set original_rect [fplan_bbox -cell $cell]

  if {$cell == [lay_editcell]} {
    setl {nx1 ny1 nx2 ny2} [uusnap -grid $grid $nx1 $ny1 $nx2 $ny2]
    fplan_set_bbox -cell $cell $nx1 $ny1 $nx2 $ny2
    #eval db_paint -cell $cell -erase $prb [db_bbox -cell $cell]
    #db_paint -cell $cell $prb $nx1 $ny1 $nx2 $ny2
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
    fplan_set_bbox -cell $cell $nx1 $ny1 $nx2 $ny2
    #eval db_paint -cell $cell -erase $prb [db_bbox -cell $cell]
    #db_paint -cell $cell $prb $bx1 $by1 [expr $bx1+$nx2-$nx1] [expr $by1+$ny2-$ny1]
  }

  update idletasks
  set msg "Do you want to re-legalize the ports?"
  set choice [tk_dialog .dialog "Cell $cell" $msg {} 0 Yes No]
  if {$choice == 0} {
    fplan_port_legalize -resize $original_rect $cell
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
  #set cell [expr {$cellid == "." ? [lay_editcell] : [cell_id2cell $cellid]}]
  if {$cellid == "."} {
    set cell [lay_editcell]
  } else {
    set cell_info [dbt_find_cell $cellid]
    if {$cell_info == ""} {error "Cell $cellid not found"}
    set cell [cellinfo_def $cell_info]
  }

  # Make sure this block has a prb layer.  If none, create it.
  eval fplan_set_bbox -cell $cell [fplan_bbox -cell $cell]

  #set prb_list [db_search_l paint -cell $cell $prb]
  #if {[llength $prb_list] == 0} {
  #  eval db_paint -cell $cell $prb [fplan_bbox -cell $cell]
  #  # BUG FIX: db_paint blows away the selection.
  #  if {$cell != [lay_editcell]} { sel_cell2 $cellid }
  #}

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
  set area_util [db_prop -def $cell cell_area_util]
  if {$area_util == ""} {set area_util $FPLAN(default_area_util)}
  set req_area [expr $min_area * 100.0 / $area_util]
  
  # Round areas to integers.
  set req_area [expr int($req_area+0.99)]
  set cur_area [expr int($cur_area+0.99)]

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
}

proc fplan_setup {} -type local -desc {
  Menu for general floorplan options.
} {
  global FPLAN
  set prop_list ""

  fplan_init

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
    flyc_sel_cell -all
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
  global CELL FPLAN
  global _FPLAN_VERILOG_AUTOLOAD_MSG_PRINTED _FPLAN_VERILOG_AUTOLOAD_FILES

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

  if {[cell_in_memory $cell]} {
    set cell_type [db_prop -def $cell cell_type]
    if {$cell_type == "cover" || $cell_type == "stdcell" || $cell_type == "lef"} {return}
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
  set suppress_msgs [info exists _FPLAN_VERILOG_AUTOLOAD_MSG_PRINTED($filename)]
  set _FPLAN_VERILOG_AUTOLOAD_MSG_PRINTED($filename) 1

  if {$verilog_file == ""} {
    if {!$suppress_msgs} {
      msg "Verilog auto-load: warning: No verilog found for $filename\n"
    }
  } else {
    if {[info exists _FPLAN_VERILOG_AUTOLOAD_FILES($verilog_file)]} {
      # We already tried to load this file once.
      # Dont read it again.
      return
    }
    set _FPLAN_VERILOG_AUTOLOAD_FILES($verilog_file) 1

    set cmd [list nl2_read_verilog -flags {-rtl} \
	-include $FPLAN(verilog_auto_include) $verilog_file]
    if {![catch $cmd result]} {
      msg "Verilog auto-loaded file: $verilog_file\n"

      # Make sure the design really was defined, because nl_read_verilog does not
      # necessarily fail.
      if {[nl_find_designs -exact $cell] == ""} {
	msg "Verilog auto-load warning: cell $cell not defined in file $verilog_file\n"
      }

      if {$FPLAN(verilog_auto_squish)} {
	verilog_squish
      }

      if {$FPLAN(verilog_auto_check) && [cell_in_memory $cell]} {
	fplan_design_check -cell $cell
      }
    } else {
      msg "Verilog auto-load: error reading verilog file: $verilog_file error was: $result\n"
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
    nlt_log {nl_write_verilog -hierarchy $filename $module}
  } else {
    nlt_log {nl_write_verilog $filename $module}
  }
}


proc UNDER_CONSTRUCTION_fplan_read_or_import_verilog_menu {} {
  global FPLAN _VERILOG_OPT LEF_SITES SUFFIX

  if {[use_first FPLAN(exists)] != 1} {
    error "Chipper not installed!"
  }

  # Init stuff for menu.

  set lef_sites "*undefined*"
  if {[llength [array names LEF_SITES]] == 0} {
    set msg "import_verilog: No LEF SITES defined.  Continue anyway using current placement grid?"
    set choice [tk_dialog .dialog Warning $msg {} 0 Yes Cancel]
    if {$choice != 0} {return}
  } else {
    set lef_sites [array names LEF_SITES]
  }

  set filename ""
  # Convert list of verilog suffixes into list of patterns for fs_box.
  set verilog_pattern ""
  foreach thingy $SUFFIX(verilog_list) {
    lappend verilog_pattern "*$thingy"
  }

  use_init FPLAN(design_root) ""
  use_init _FPLAN_IMPORT(act_read_verilog) 1
  use_init _FPLAN_IMPORT(act_read_etc) 1
  use_init _FPLAN_IMPORT(act_squish_verilog) 0

  use_init _FPLAN_IMPORT(mod_name) ""

  set top_mods [verilog_find_top]
  if {$_FPLAN_IMPORT(mod_name) == ""} {
    set _FPLAN_IMPORT(mod_name) [lindex $top_mods 0]
  }

  setl {snapx snapy} [res2 $FPLAN(block_grid)]
  # The x grid can be much smaller than y, making the aspect ratio tall and skinny.
  # Make the min size approximately square.
  set block_grid_x [expr floor([max $snapx $snapy]/$snapx) * $snapx]
  set _FPLAN_IMPORT(min_block_size) [use_first _VERILOG_OPT(min_block_size)\
	'[expr $block_grid_x * $snapy]]
  use_init _FPLAN_IMPORT(levels) [expr {($levels > 0) ? $levels : 1000}]
  use_init _FPLAN_IMPORT(uniquify_cells) 0
  use_init _FPLAN_IMPORT(small_cells) "pack"
  use_init FPLAN(lef_site) "*undefined*"
  use_init _FPLAN_IMPORT(vcreate_dir) "\$v"

  if {$FPLAN(lef_site) == "*undefined*" } {
    # This is the first time through import_verilog.
    # Init FPLAN(lef_site) it to CORE1 or CORE if defined, otherwise to any old SITE.
    if {[lsearch $lef_sites CORE1] >= 0} {
      set FPLAN(lef_site) CORE1
    } elseif {[lsearch $lef_sites CORE] >= 0} {
      set FPLAN(lef_site) CORE
    } else {
      set FPLAN(lef_site) [lindex $lef_sites 0]
    }
  }

  if {$module == ""} {
    # Throw up the prop menu

    lappend prop_list [list "Create placement for module:" \
	  _FPLAN_IMPORT(mod_name) -popup $top_mods \
	  -help {If specified, the contents of this verilog module (cell instances and ports)\
	  are placed in a max file.    If "Number of levels to read" is > 1, the hierarchy\
	  below this cell are also placed.   If the max file already exists, the verilog\
	  is optionally merged with the existing max file, meaning any new cells or ports\
	  are added.}]

    lappend prop_list [list "Verilog filename, if different" filename \
	  -filename [list -message {Verilog file to read:} -pattern $verilog_pattern]
	  -help {The name of the verilog file to read, if different from the module name. \
	  You can also leave the "Create placment for module" entry blank and specify\
	  just a verilog filename to just read verilog without creating placement.}]

    lappend prop_list [list "Number of hierchy levels to read" \
	  _FPLAN_IMPORT(levels) -number 1 \
	  -help {if 1, read only the specified cell.}]
    lappend prop_list [list "Make unique max cell for each verilog instance" \
	  _FPLAN_IMPORT(uniquify_cells) -enum {no yes}]

    lappend prop_list [list "Create max files in directory:" \
	  _FPLAN_IMPORT(vcreate_dir) -entry \
	  -help {If set, any created max files are placed in this directory. \
	  $v is replaced with the directory the verilog file for the module was found.}]

    lappend prop_list [list "Minimum Block Size" \
	  _FPLAN_IMPORT(min_block_size) -entry \
	  -help {Unrecognized leaf cells will be created with this initial size.}]

    lappend prop_list [list "%utilization" FPLAN(default_area_util) -number 1 100 \
	    -help {used to determine initial block size}]

    lappend prop_list [list "LEF SITE for placement grid" FPLAN(lef_site) -choice $lef_sites]

    lappend prop_list [list "Small LEF cells" \
	  _FPLAN_IMPORT(small_cells) -choice {ignore pack place} \
	  -help {if "ignore", LEF cells that are small enough that they look like stdcells\
	  are not placed in the cell;  if "pack", they are packed together tightly;\
	  if "place", they are placed like other larger cells.}]

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

      if {$_FPLAN_IMPORT(mod_name) == ""} {
	max_error "import_verilog: error: No module name specified"
	continue
      }
      break
    }
  }

return

  # Make sure everything is sucked in first.
  # Otherwise, the import verilog command will create new cells
  # that overwrite the existing.
  # 7/26: try to do this incrementally!
  #msg "import_verilog: sucking in all max files...\n"
  #cell_load_tree
  #msg "import_verilog: sucking step done\n"

  set mod_name $_FPLAN_IMPORT(mod_name)

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
  nl2_link $mod_name

  # Dont set the grid on import verilog!!
  # _fplan_set_core_grid

  # This is a list of new cells that we have added.  It is needed so that
  # when you try to create a new cell and it already exists,
  # you know whether you have already created it or not.
  global _FPLAN_IMPORT_NEW_CELLS
  catch {unset _FPLAN_IMPORT_NEW_CELLS}

  global _FPLAN_IMPORT_IGNORE_MODS	;# This is an optimization: remember modules to ignore.
  catch {unset _FPLAN_IMPORT_IGNORE_MODS}
  set top_cell [_fplan_create_hier "" $mod_name 0]

  cell_load $top_cell

  # Save the verilog file from which the top-level cell was created.
  # Then if user edits this file later, we can read the same
  # verilog file by default.
  # NOTE: Took out.  This needs to be redone, since the verilog filenames are
  # in the VERILOG_MODULE2FILE array.
  puts "verilog import done"

  return
}

proc fplan_read_verilog {{-rtl 1} {-ports_only 0} \
  {-act_read_etc 0} {-link 0} {-design_root ""} {filename ""}} -type local -desc {
  Post menu to read structural verilog .v file, create top-level chip floorplan.
} {
  global FPLAN _VERILOG_OPT SUFFIX

  set _VERILOG_OPT(filename) [use_first _VERILOG_OPT(filename)]
  use_init FPLAN(design_root) ""
  use_init _FPLAN_IMPORT(act_read_verilog) 1
  use_init _FPLAN_IMPORT(act_squish_verilog) 0

  # Note: the etc file is not working as of 1/18
  #use_init _FPLAN_IMPORT(act_read_etc) 1

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
	_FPLAN_IMPORT(act_read_verilog) -binary \
	-help {You can read any number of verilog files,
	but you should link_verilog only once.}]
    #lappend prop_list [list "Read Etc File (NL properties)" \
	_FPLAN_IMPORT(act_read_etc) -binary \
	-help {The .etc file contains previously saved nl properties, including placement.}]

    lappend prop_list [list "Link Verilog" \
	_VERILOG_OPT(link) -binary \
	-help {After all verilog files have been read in, you must link\
	starting at the root of the verilog tree before any connectivity
	based operations can be performed.}]

    lappend prop_list [list "Remove demorgans/cells with only one cell"  \
	_FPLAN_IMPORT(act_squish_verilog) -binary \
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

  if {$_FPLAN_IMPORT(act_read_verilog)} {

    if {$_VERILOG_OPT(filename) == ""} {
      error "no verilog filename specified"
    }

    set read_verilog_flags ""
    if {$_VERILOG_OPT(rtl)} {append read_verilog_flags "-rtl "}
    if {$_VERILOG_OPT(ports_only)} {append read_verilog_flags "-ports_only "}

    msg "Reading verilog file $_VERILOG_OPT(filename)\n"
    nl2_read_verilog -flags $read_verilog_flags $_VERILOG_OPT(filename)
  }

  if {$_FPLAN_IMPORT(act_squish_verilog)} {
    verilog_squish
  }

  if {$_VERILOG_OPT(link)} {

    if {$FPLAN(design_root) != ""} {
      fplan_link_verilog $FPLAN(design_root)
    } else {
      max_error -buffer "No top level module specified to link!"
    }
  }

  if {0} {
    if {$_FPLAN_IMPORT(act_read_etc)} {
      if {$_VERILOG_OPT(filename) == ""} {
	error "no verilog filename specified"
      }
      set fn [file rootname $_VERILOG_OPT(filename)].etc
      if {[file readable $fn]} {
	nlt_read_props $fn
	fplan_update_max_from_nl [file tail [file rootname $fn]]
      } else {
	msg "Etc file not found: $fn\n"
      }
    }
  }

  msg "verilog read done\n"
}

proc fplan_update_max_from_nl {cell} {
  if {[cell_in_memory $cell]} {
    set msg "Cell $cell exists.  Overwrite?"
    set choice [tk_dialog .dialog Warning $msg {} 0 Yes Cancel]
    if {$choice != 0} {
      msg "cancelled\n"
      return
    }
    db_cell_clear $cell
  } else {
    db_cell_new $cell
  }

  set mod [fplan_unfix_name $cell]

  foreach nlinst [nl_list_cells -noassign $mod] {
    set maxinst [fplan_fix_name $nlinst]
    nlt_log {set nlref [nl_get_cell_reference $nlinst]}
    set subcell [fplan_fix_name $nlref]

    nlt_log {setl {x y} [nl_get_cell_location -origin $nlinst]}
    nlt_log {set ori [nl_get_cell_orientation -max $nlinst]}

    if {! [nlt_log {nl_is_libcell $subcell}]} {
      # If a hierarchical cell does not exist, create it.
      if {! [cell_in_memory $subcell]} {
	setl {x1 y1 x2 y2} [nl2_get_design_size $subcell]
	catch {db_cell_new $subcell}
	fplan_set_bbox -cell $subcell $x1 $y1 $x2 $y2
      }
    }

    if {$ori == "none"} {set ori ""}
    db_instance -cell $cell -orientation $ori -id $maxinst $subcell $x $y
  }

  foreach nlport [nl_list_ports $mod] {
    nlt_log {set iodir [nl_get_port_direction $nlport]}
    nlt_log {setl {px py} [nl_get_port_location $nlport]}
    nlt_log {setl {layer blah blah blah} [nl_get_port_geometry $nlport]}
    db_label -kind $iodir $layer [fplan_fix_name -label $nlport] $px $py
  }
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
  nl2_link $mod
  nl2_unset_current_design
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
    if {[catch {grid_set -name $gridname -user "$x_size [expr 2*$y_size]"} errmsg]} {
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
  return 1
}

proc fplan_import_verilog {{-small_cells ignore} {-vcreate_dir "\$v"} \
	{-small_cell_size ""} {-verbose 0} {-merge 1} {-undef_cell_action quit} \
	{-interactive} {-stop_list ""} {-levels 0} {-uniquify_cells 0} {module ""}} -type local -desc {
  Import a verilog module into max, creating initial random placement.
} {
  global FPLAN _FPLAN_IMPORT _VERILOG_OPT LEF_SITES SUFFIX

  if {[use_first FPLAN(exists)] != 1} {
    error "Chipper not installed!"
  }

  if {$interactive} {
    # Interactive mode.  Load _FPLAN_READ_DEF from defaults first time through.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      use_init _FPLAN_IMPORT($option) [set $option]
    }
  } else {
    # Load _FPLAN_READ_DEF defaults from proc def, above,
    # which may be over-ridden by user on command line..
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      set _FPLAN_IMPORT($option) [set $option]
    }
  }

  fplan_check_verilog -silent


  if {0} {
    set lef_sites "*undefined*"
    if {[llength [array names LEF_SITES]] == 0} {
      set msg "import_verilog: No LEF SITES defined.  Continue anyway using current placement grid?"
      set choice [tk_dialog .dialog Warning $msg {} 0 Yes Cancel]
      if {$choice != 0} {return}
    } else {
      set lef_sites [array names LEF_SITES]
    }
  }

  # Pop up the import menu.

  use_init _FPLAN_IMPORT(mod_name) ""

  set top_mods [verilog_find_top]
  if {$module != ""} {
    set _FPLAN_IMPORT(mod_name) $module
  } elseif {$_FPLAN_IMPORT(mod_name) == ""} {
    set _FPLAN_IMPORT(mod_name) [lindex $top_mods 0]
  }

  setl {snapx snapy} [res2 $FPLAN(block_grid)]
  # The default block grid is 2 rows high, so divide by 2.
  if {$_FPLAN_IMPORT(small_cell_size) == ""} {
    set _FPLAN_IMPORT(small_cell_size) [expr $snapy/2.0]
  }

  # The x grid can be much smaller than y, making the aspect ratio tall and skinny.
  # Make the min size approximately square.
  set block_grid_x [expr floor([max $snapx $snapy]/$snapx) * $snapx]
  set _FPLAN_IMPORT(min_block_size) [use_first _VERILOG_OPT(min_block_size)\
	'[expr $block_grid_x * $snapy]]
  if {$_FPLAN_IMPORT(levels) == 0} {set _FPLAN_IMPORT(levels) 1000}

  if {0} {
    if {$FPLAN(lef_site) == "*undefined*" } {
      # This is the first time through import_verilog.
      # Init FPLAN(lef_site) it to CORE1 if defined, otherwise to any old SITE.
      if {[lsearch $lef_sites CORE1] >= 0} {
	set FPLAN(lef_site) CORE1
      } else {
	set FPLAN(lef_site) [lindex $lef_sites 0]
      }
    }
  }

  if {$module == ""} {
    # Throw up the prop menu

    lappend prop_list [list "Module name to import" \
	  _FPLAN_IMPORT(mod_name) -popup $top_mods \
	  -help {(required)  The name of the top-level verilog module to\
	  read into the current max cell.}]
    #lappend prop_list [list "Number of levels to read" \
    #	  _FPLAN_IMPORT(levels) -number 1 \
    #	  -help {if 1, read only the specified cell.}]
    
    lappend prop_list [list "Stop List (patterns)" _FPLAN_IMPORT(stop_list) -entry \
	-help {The list of stop-cells for the import process. \
	When a stop-cell is encountered while traversing the verilog tree, \
	a blank cell is created, if none already exists, and ports are created \
	to match the verilog module definition, but no instances are created inside the cell. \
	If a pre-existing cell already exists, the max ports are modified \
	to match the verilog module definition, but existing \
	contained cell instances are left alone. \
	Hint: set this to * to create placement for the specified module only.}]

    lappend prop_list [list "Make unique max cell for each verilog instance" \
	  _FPLAN_IMPORT(uniquify_cells) -enum {no yes}]

    lappend prop_list [list "Create new cells or merge into existing cells" \
	_FPLAN_IMPORT(merge) -enum {create merge:add_only merge:add/delete}]

    lappend prop_list [list "If module not found in verilog or LEF" \
	_FPLAN_IMPORT(undef_cell_action) -choice {quit create}]

    lappend prop_list [list "Create new max files in directory:" \
	  _FPLAN_IMPORT(vcreate_dir) -entry \
	  -help {If set, any created max files are placed in this directory. \
	  $v is replaced with the directory the verilog file for the module was found.}]

    lappend prop_list [list "Minimum Block Size for created cells" \
	  _FPLAN_IMPORT(min_block_size) -entry \
	  -help {Unrecognized leaf cells will be created with this initial size.}]

    lappend prop_list [list "%utilization for newly created cells" FPLAN(default_area_util) -number 1 100 \
	    -help {used to determine initial block size}]

    #lappend prop_list [list "LEF SITE for placement grid" FPLAN(lef_site) -choice $lef_sites]

    lappend prop_list [list "Small LEF cells" \
	  _FPLAN_IMPORT(small_cells) -choice {ignore pack place} \
	  -help {if "ignore", LEF cells that are small enough that they look like stdcells\
	  are not placed in the cell;  if "pack", they are packed together tightly;\
	  if "place", they are placed randomly in with the other larger cells.}]

    lappend prop_list [list "Small cell height" _FPLAN_IMPORT(small_cell_size) -number \
	  -help {Defines the maximum height of a "small" cell.  You can program import_verilog\
	  to ignore cells equal or smaller than this height.}]

    lappend prop_list [list "Verbose" _FPLAN_IMPORT(verbose) -binary]

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

      if {$_FPLAN_IMPORT(mod_name) == ""} {
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

  set mod_name $_FPLAN_IMPORT(mod_name)

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
  #nl_link -silent "" $mod_name

  # Dont set the grid on import verilog!!
  # _fplan_set_core_grid

  # This is a list of new cells that we have added.  It is needed so that
  # when you try to create a new cell and it already exists,
  # you know whether you have already created it or not.
  global _FPLAN_IMPORT_NEW_CELLS
  catch {unset _FPLAN_IMPORT_NEW_CELLS}

  global _FPLAN_IMPORT_IGNORE_MODS	;# This is an optimization: remember modules to ignore.
  catch {unset _FPLAN_IMPORT_IGNORE_MODS}
  set top_cell [_fplan_create_hier "" $mod_name 0]

  cell_load $top_cell

  # Save the verilog file from which the top-level cell was created.
  # Then if user edits this file later, we can read the same
  # verilog file by default.
  # NOTE: Took out.  This needs to be redone, since the verilog filenames are
  # in the VERILOG_MODULE2FILE array.
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
      # NOTE: This option is used only during verilog import!
      # Size chosen is pretty arbitrarily.  Use height, not width, which varies.
      # Our stdcells should all be smaller than this.
      # Note that size_y is the minimum size * 2 to account for flipping,
      # so stdcells are less than this side.
      global _FPLAN_IMPORT
      if {![info exists _FPLAN_IMPORT(small_cell_size)]} {
	setl {snapx snapy} [res2 $FPLAN(block_grid)]
	use_init _FPLAN_IMPORT(small_cell_size) [expr $snapy/2.0]
      }
      return [expr {$type == "lef" && $ysize <= $_FPLAN_IMPORT(small_cell_size)+0.0001}]
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

proc fplan_init_cell {{-size ""} {-module ""} cell dir} -doc {
  If <cell> is not in memory, then the <dir> arg specifies the
  directory associated with the cell.  If <dir> is empty, any created
  cell goes in current dir.

  Init props associated with an fplan module.
} {
  global FPLAN CELL

  if {![cell_in_memory $cell]} {
    if {$dir == ""} {
      db_cell_new $cell ./$cell$CELL(default_suffix)
    } else {
      db_cell_new $cell $dir/$cell$CELL(default_suffix)
    }
  }

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
  db_prop -def $cell grid $FPLAN(block_grid)

  db_prop -def $cell cell_area_util $FPLAN(default_area_util)

  if {$size != ""} {
    # add prb layer
    setl {sizex sizey} $size
    fplan_set_bbox -cell $cell 0 0 $sizex $sizey
  }
}

proc _fplan_create_hier {{-prepath ""} root_cell imp_mod levels} -desc {
  Create <levels> hierarchy starting at <imp_mod>.  Return top cell name.
} -doc {
  root_cell is the cell that is the parent of this one, or empty at the top level.
  imp_mod is verilog module name for the cell we want to create.
  levels is how many levels deep in recursion we are, 0 at top level.
} {
  global CELL FPLAN _FPLAN_IMPORT SUFFIX _FPLAN_CELL_INFO VERILOG_MODULE2FILE
  global _FPLAN_IMPORT_IGNORE_MODS	;# This is an optimization: remember modules to ignore.
  global _FPLAN_IMPORT_NEW_CELLS	;# Remember cells we have created.
  global _FPLAN_IMPORT_PREV_CELLS	;# Array of pre-existing instances used during merging.

  # cell name defaults to module name, with bad characters fixed.
  set imp_cell [fplan_fix_name $imp_mod]

  if {$root_cell != ""} {
    # The imp_cell was flattened.  Create instances found in imp_cell in its parent, which is root_cell.
    assert {$root_cell != $imp_cell}
    set flattened 1
  } else {
    # imp_cell not flattened. Create instances found in imp_cell in imp_cell
    set root_cell $imp_cell
    set flattened 0
  }

  set verbose $_FPLAN_IMPORT(verbose)
  #if {$verbose} {msg "processing cell $imp_mod $mod_inst\n"}

  # Set time_to_stop if we are not going to dive into hierarchical subcells.
  # Test levels so we always import the root module (at level 0),
  # even if it matches one of the stop patterns.
  set time_to_stop 0
  if {$levels > 0} {
    foreach pattern $_FPLAN_IMPORT(stop_list) {
      if {[string match $pattern $imp_mod]} {
	set time_to_stop 1
      }
    }
  }

  incr levels
  # 2/21: This piece of code is not currently used:
  #if {$levels >= $_FPLAN_IMPORT(levels)} {set time_to_stop 1}

  set grid $FPLAN(block_grid)
  setl {snapx snapy} [res2 $grid]
  if {$snapx == ""} {
    error "grid $grid not defined"
  }

  # Logic below tries to figure out what kind of cell it is.
  # Here are our choices.
  # cell defined in LEF.
  # cell is a special RTL cell (eg, used to implement verilog assign statement) - ignored.
  #    (this check is done by the caller when the cell instance is encountered)
  # cell defined in verilog.
  # cell undefined.

  if {[fplan_cell_info -is_lef $imp_mod]} {
    # Lef cells are treated totally differently.  We assume the cell is
    # either a stdcell or a hard macro, with pins already assigned.
    # Therefore, each instance is not unique, but is just an instance
    # of a pre-existing cell.
    # Only trick is that the cell might not exist if it is a ram or something.
    # Should give the user the opportunity to create it from the verilog.
      if {$_FPLAN_IMPORT(small_cells) == "ignore" && [fplan_cell_info -is_small $imp_mod]} {
	set _FPLAN_IMPORT_IGNORE_MODS($imp_mod) 1
	return $imp_cell  ;# caller will ignore this cell.
      }
      if {[cell_in_memory $imp_cell]} {
	return $imp_cell
      }

      set locations [cell_path_find $imp_cell]
      if {$locations != ""} {
	if {[llength $locations] != 1} {
	  msg "Warning: cell $imp_cell found in multiple locations (using first): $locations\n"
	}
	cell_load_file [lindex $locations 0]
	return $imp_cell
      }

      if {[use_first FPLAN(hier_ignore_undef_lef) '0]} {
	# Note: This fails if top level contains only a stdcell, but who cares
	return ""  ;# Causes caller to ignore this cell.
      }


      set msg "import_verilog: error: Max cell for LEF cell $imp_mod not found on disk. \n\
	  You must create a MAX cell for all LEF cells before the floorplanner\n\
	  can create instances of them during verilog import."

      if {$_FPLAN_IMPORT(undef_cell_action) == "quit"} {
	max_error -buffer $msg
	error "error during import"
      } else {
	msg "$msg\n"

	# Create prb of default minimum sized cell:
	#db_prop -def $imp_cell verilog_flags "undefined"  ;# Is this needed?
	_fplan_import_create_prb $imp_cell
	return $imp_cell
      }
  }

  # Make sure any prior existing cell is read in, so we will preserve
  # the directory where it previously resided, and so we will be able
  # to merge changes into existing cell, if requested.

  # First, see if we can find an existing max file on the cell path.
  set imp_cell_file [lindex [cell_path_find -report_dups $imp_cell] 0]

  if {$imp_cell_file != ""} {
    # Max file found.  This reads in both the .max and the verilog in the same dir.
    cell_load_file $imp_cell_file
  } else {
    # Did not find a .max file.  Has the verilog module already been loaded?
    # If so, this is the location where its file was found.
    set verilog_file [use_first VERILOG_MODULE2FILE($imp_mod)]

    if {$verilog_file == ""} {
      # Verilog module not already loaded.  See if we can find a verilog
      # file on the cell path with this name, and read it in.
      set verilog_file [lindex \
	  [cell_path_find -exts $SUFFIX(verilog_list) -report_dups $imp_cell] 0]
      if {$verilog_file != ""} {
	# fplan_verilog_auto_load requires a .max extension file, so provide it.
	fplan_verilog_auto_load $verilog_file
      }
    }

    if {$verilog_file != ""} {
      set imp_cell_file [file rootname $verilog_file]$CELL(default_suffix)
    } else {
      # Neither max nor verilog file found on path.
    }
  }
  
  # The prev_undef is set if we have already seen an instance of this undefined module before.
  set prev_undef [fplan_cell_info -is_undef $imp_mod]
  set is_undef [expr {[nl2_loaded $imp_mod] == 0}]

    # Jim Ballard painstakingly marked all the RTL-specific cells in the ng design,
    # with nl_is_libcell, and doesnt want that stuff to appear in max.
    # So the algorithm for creating cells is:
    #  if it is LEF, it is a stcell or ram or something;
    #  else if it is a libcell, it is a nothing, ignore it.
    # Update 2/14/02: Jim reported this behavior as a bug!
    # Now he is using libcell for something else, specifically
    # to control which modules to import.
    # So clearly this is too confusing, so I took this out.
  #if {! $is_undef} {}
    #if {[nlt_log {nl_is_libcell $imp_mod}]} {return ""}
  #{}


  # If all cells are to be unique, uniquify the name now.
  if {$_FPLAN_IMPORT(uniquify_cells)} {
    set imp_cell [_fplan_find_unique_cell_name $imp_cell]
    set _FPLAN_IMPORT_NEW_CELLS($imp_cell) 1
  } else {
    # If we already read it in during this invocation of read_verilog,
    # use the cell we already created.
    if {[info exists _FPLAN_IMPORT_NEW_CELLS($imp_cell)]} {
      # Use cell we built previously.
      return $imp_cell
    } else {
      set _FPLAN_IMPORT_NEW_CELLS($imp_cell) 1
    }
  }

  # In the floorplan view, each verilog instance may be unique, but maybe not.
  # We will start by making one max cell for all instances.
  # Later on, user may uniquify instances, which will also optionally
  # affect all the hierarchy below that point.
  # At level 0 (top level in design) there may not be an mod_inst.
  # If no instance name specified, use the module def name.


  # The prev_undef keeps us from asking this question multiple times.
  if {$is_undef && ! $prev_undef} {
    # Module not defined in verilog or lef.
    # We could just go ahead and build a block anyway,
    # but we dont know port type (input/output) or how to hook it up.
    # jdj wants to create with i/o ports.  Guess it needs to be an option.


    set msg "import_verilog: warning: no verilog or LEF found for module ${imp_mod} not defined"
    if {$_FPLAN_IMPORT(undef_cell_action) == "quit"} {
      max_error -buffer $msg
      error "error during import"
    } else {
      msg "$msg; creating empty cell\n"
    }


    # Verilog module does not exist.
    # Should probably read it from a .lef somewhere,
    # but for now, just create an empty cell.
    # By doing this, we suppress any further messages for this cell.
    set _FPLAN_CELL_INFO($imp_mod) "undef"
    set is_undef 1
    set time_to_stop 1
  }


  # This assignment is so you can use $v in _FPLAN_IMPORT(vcreate_dir)
  set v [file dirname $imp_cell_file]
  set createdir [subst -nobackslashes -nocommands $_FPLAN_IMPORT(vcreate_dir)]


  # We already loaded any existing max cell, above.
  # This call creates the cell in the case where it did
  # not exist, and initializes its props in any case.
  fplan_init_cell -module $imp_mod $imp_cell $createdir

  if {$is_undef} {
    db_prop -def $imp_cell verilog_flags "undefined"
    # Create prb of default minimum sized cell:
    _fplan_import_create_prb $imp_cell
    return $imp_cell
  }

  if {$_FPLAN_IMPORT(merge)} {
    set action "merge"		;# Might be merge:add or merge:add/delete
  } else {
    set action "create"
  }

  if { $action == "create" && ! $flattened } {
      # overwrite existing cell, but if it is time to stop,
      # do not clear it - we want to connect to any pre-existing
      # max cell that might have been imported earlier.
      if {! $time_to_stop} { db_cell_clear $imp_cell }

      # Just in case the db_cell_clear above blew away the properties,
      # re-init the cell.  Since the cell already exists in memory,
      # this call does nothing but re-init the cell props.
      fplan_init_cell -module $imp_mod $imp_cell $createdir
  }

  msg "import_verilog: $action cell $imp_cell for verilog module $imp_mod\n"

  # Build tree from bottom up.

  if {! $time_to_stop} {

    # Step one: create hierarchy below.
    # Keep a list of small and large cells to be placed.
    set small_cells ""
    set large_cells ""

    # We only set the PREV_CELLS var when we first see this cell.
    # On all subsequent passes, flattened==1.
    if {$action == "merge" && ! $flattened} {
      if {$verbose} {msg "cell $root_cell: searching for existing cells...\n"}
      foreach cell_info [db_search_cells -cell $root_cell] {
	set _FPLAN_IMPORT_PREV_CELLS(${root_cell},${prepath}[cellinfo_id $cell_info]) 1
      }
      if {$verbose} {msg "cell $root_cell: search done...\n"}
    }

    foreach modi [nl2_list_cells $imp_mod] {
      set subdef [nl2_get_cell_ref $imp_mod $modi]
      if {[info exists _FPLAN_IMPORT_IGNORE_MODS($subdef)]} {continue}

      set subcellid ${prepath}[fplan_fix_name $modi]
      catch {unset _FPLAN_IMPORT_PREV_CELLS($root_cell,$subcellid)}


      # Nl creates *assignment* cells for assign statements, and *process* cells
      # for RTL verilog.  We want to ignore both.
      # Check to see if imp_mod was defined in .lef file.
      if {[nl2_is_rtl_cell $subdef]} {
	# Ignore this.  It is a dummy cell inserted by nl.
	set _FPLAN_IMPORT_IGNORE_MODS($subdef) 1
	continue
      }


      # This creates the cell for subdef and all contained hierarchy and returns it.
      if {[fplan_db_inst -cell $imp_cell getprop [fplan_fix_name $modi] place] == "flatten"} {
	# The subcellid is flattened, so instances inside subdef are created in root_cell.
	set cell [_fplan_create_hier -prepath ${prepath}${modi}/ $root_cell $subdef $levels]
      } else {
	# Instances inside subdef will be created in cell for subdef.
	set cell [_fplan_create_hier "" $subdef $levels]
      }
      
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
    if {$verbose} {msg "cell $imp_cell: nl_list_cells done...\n"}

    if {! $flattened && $_FPLAN_IMPORT(merge) == 2} {
      set these [array names _FPLAN_IMPORT_PREV_CELLS ${root_cell},*]
      if {[llength $these] != 0} {
	# Delete the suckers that are no longer in the verilog.
	set prefix_len [string length "${root_cell},"]
	foreach thingy $these {
	  set celli [string range $prefix_len end]
	  if {$verbose} {msg "deleting $celli from $root_cell\n"}
	  db_instance_delete -cell $root_cell $celli
	}
	db_notify -cell $root_cell
      }
      if {$verbose} {msg "cell $imp_cell: delete cells done...\n"}
    }

    switch -- $_FPLAN_IMPORT(small_cells) {
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
	set celli3 ${prepath}[fplan_fix_name $modi]

	if {$action == "merge"} {
	  # If an instance already exists, leave it alone.
	  if {[db_instances -cell $root_cell -id $celli3] != ""} {
	    continue ;# already exists.
	  }
	  if {$verbose} { msg "adding $celli3 to $root_cell\n" }
	}

	db_instance -no_notify -id $celli3 -cell $root_cell $cell $cx $cy
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
    if {$verbose} {msg "cell $imp_cell: large cells placed...\n"}

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
	set celli2 ${prepath}[fplan_fix_name $modi]

	if {$action == "merge"} {
	  # If an instance already exists, leave it alone.
	  if {[db_instances -cell $root_cell -id $celli2] != ""} {
	    continue ;# already exists.
	  }
	  if {$verbose} { msg "adding $celli2 to $root_cell\n" }
	}

	db_instance -no_notify -id $celli2 -cell $root_cell $cell $cx $cy
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
    if {$verbose} {msg "cell $imp_cell: small cells placed...\n"}
  }
  db_notify -cell $root_cell

  if {! $flattened} {

    # Add prb if the cell was just created, or if merging and no prb previously.

    if {$action == "create" || [fplan_bbox -cell $imp_cell -test] == ""} {

      # Set size from contained cells.
      set area [fplan_get_lef_area -lef $imp_cell]
      db_prop -def $imp_cell min_area $area

      # Paint its prb.
      # This may make the cell larger.
      _fplan_import_create_prb $imp_cell
    }

    # Create ports in cell we just created.
    # This merges new ports with ones already there.
    if {$verbose} {msg "cell $imp_cell: merging pins...\n"}
    _fplan_ver_merge_pins $imp_cell $imp_mod

    _fplan_add_hidden_labels $imp_cell
  }
  if {$verbose} {msg "cell $imp_cell: done...\n"}

  return $imp_cell
}

proc _fplan_import_create_prb {{-max} cell} -desc {
  Add in the prb layer for a new cell.
} -doc {
  If -max, make it big enough to hold the prbs of contained cells.
} {
  global FPLAN _FPLAN_IMPORT
  set grid $FPLAN(block_grid)
  setl {snapx snapy} [res2 $grid]

  set area_util [db_prop -def $cell cell_area_util]
  if {$area_util == ""} {set area_util $FPLAN(default_area_util)}

  # req_area is the required minimum area = lef contents * utilization.
  set min_area [db_prop -def $cell min_area]
  if {$min_area == ""} {
    set min_area 0
  }
  #set prb [techinfo layer prb]

  # The *100 is because area_util is in percent.
  set req_area [expr $min_area * 100.0 / $area_util]
  set req_area [max $req_area $_FPLAN_IMPORT(min_block_size)]

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
    eval sel_area -layers $prb -any_cell -no_poly -no_wp -no_labels [lay_bbox]
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
  fplan_set_bbox -cell $cell -erase 0 0 0 0

  set sizex [expr $bx2 - $bx1]
  set sizey [expr $by2 - $by1]
  setl {sizex sizey} [uusnap -ceil -grid $grid $sizex $sizey]


  # Make sure area is at least minimum required.
  # If not, make it bigger, keeping it roughly square.
  if {[approx [expr 1.0 * $sizex * $sizey] < $req_area]} {
    # Set X or Y first depending on which has the larger grid.
    # Then expand the smaller gridded dimension to fill it out.
    if {$snapx <= $snapy} {
      set sizey [expr round([max $sizey sqrt($req_area)] / $snapy) * $snapy]
      # Must not be 0.
      set sizey [max $sizey $snapy]
      set sizex [expr ceil((1.0*$req_area/$sizey) / $snapx) * $snapx]
      set sizex [max $sizex $snapx]
    } else {
      set sizex [expr round([max $sizex sqrt($req_area)] / $snapx) * $snapx]
      set sizex [max $sizex $snapx]
      set sizey [expr ceil((1.0*$req_area/$sizex) / $snapy) * $snapy]
      set sizey [max $sizey $snapy]
    }
  }

  #while {[approx [expr 1.0 * $sizex * $sizey] < $min_area]} {
  #  set sizex [expr $sizex + $snapx]
  #  if {1.0 * $sizex * $sizey < $min_area} {
  #    set sizey [expr $sizey + $snapy]
  #  }
  #}


  fplan_set_bbox -cell $cell $bx1 $by1 [expr $bx1 + $sizex] [expr $by1 + $sizey]
}


proc fplan_db_inst {{-cell ""} action inst args} -desc {
  Get/set props for cell instances.
} -doc {
  USAGE:
  fplan_db_inst getprop <cell_inst> <propname>
  fplan_db_inst setprop <cell_inst> <propname> <propvalue>
	- note that properties on instances are saved in the parent cell,
	  not in the cell def of this instance.
  fplan_db_inst celli2modi <cell_inst>
	- returns verilog module instance name for this cell instance.
} {
  global FPLAN

  if {$cell == ""} {set cell [lay_editcell]}

  switch -- $action {
    getprop {
	set propname [lindex $args 0]
	return [db_prop -def $cell I($inst,$propname)]
    }
    setprop {
	set propname [lindex $args 0]
	set propval [lindex $args 1]
	db_prop -def $cell I($inst,$propname) $propval
    }
    celli2modi {
      # Return verilog module instance name for this cell instance.
      return [fplan_unfix_name $inst]

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
    default {
      error "fplan_db_inst unrecognized action: $action"
    }
  }
}


proc fplan_db_cell {action cell} -doc {
  fplan_db_cell module <cell_def>
	- returns verilog module name given cell def name.
  etc.
} {
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
      # Change verilog hierarchy (using nl_hierarchy_separator) to max hierarchy (/)
      regsub -all "\\[nlt_hier_char]" $mod_inst "/" mod_inst

      set def [cellinfo_def [dbt_find_cell $mod_inst]]
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
      regsub -all "\\[nlt_hier_char]" $result "/" result
      return $result
    }
    celli2modi {
      # OBSOLETE: Use fplan_db_inst celli2modi
      return [fplan_unfix_name $cell]
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
    #  struct max_cell c [db_instances -id $cellid]
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



proc fplan_write_dspf {{-interactive} {-hch ""} {-ohch "/"} {-flat ""} {-cell ""} {filename ""}} -desc {
  Write a dspf file.
} -doc {
  The -ohch char is the character used for hierarchy in the output dspf file.
  The -hch char is the character used to get hierarchy from the nl database.
      If -hch is unspecified, use current nl_hierarchy_separator.
      This character must NOT appear in any names in the database.
  If -flat 1, write out flat dspf all the way down to lef cells.
  If -flat 0, write out dspf only for the current level, although it
       searches down through cells that have been marked as flattened.
} {
  global FPLAN TIMING_DATA SUFFIX 

  fplan_check_verilog

  # Init TIMING_DATA variables needed for fplan_write_dspf
  fplan_dspf_setup -nomenu $filename

  if {$cell==""} {set cell [lay_editcell]}

  set curmod [fplan_db_cell module $cell]
  #set nl_current_design $curmod

  if {![nl2_loaded $curmod]} {
    error "write_dspf: no verilog read in for module $curmod (cell $cell)"
  }

  if {$interactive} {
    set prop_list ""
    #lappend prop_list [list "flatten" flat -binary]
    lappend prop_list [list "DSPF Setup..." "" -button fplan_dspf_setup]
    lappend prop_list [list "Read Verilog..." "" -button fplan_read_verilog]
    lappend prop_list [list "output file" TIMING_DATA(spf_file) -entry]
    set title "Chipper: Write DSPF"
    if {![prop_menu2 -title $title $prop_list]} {
      # cancelled
      return
    }
  }
  set filename $TIMING_DATA(spf_file)
  set flat [use_first flat TIMING_DATA(flat) '1]

  # Init the hier char:
  set orig_hier_char [nlt_hier_char]
  if {$hch != ""} {nlt_hier_char $hch}
  set hch [nlt_hier_char]

  fplan_reset_nl_hierarchy

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
    nlt_log {nl_create_idesign [fplan_unfix_name $cell]}
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
      # Jay says explicit create_idesign is not needed if you nl_list_nets -hierarchy.
      # But we will do it explicitly to catch errors.
      # If using an nl server, the nlnets variable is kept on the server.
      #set numnets [llength [nl "set nlnets \[nl_list_nets -hierarchy -noassign -noconstant $curmod\]"]]
      #nlt_log {set nlnets [nl_list_nets -hierarchy -noassign -noconstant $curmod]}
      nlt_set_idesign $curmod
    } else {
      #set numnets [llength [nl "set nlnets \[nl_list_nets -noassign -noconstant $curmod\]"]]
      # sync_nl_hierarchy creates the nl idesign for the current view.
      fplan_sync_nl_hierarchy
    }
    set nlnets [nl2_list_nets -hier 1 $curmod]

    set numnets [llength $nlnets]

    # The idea is:
    #   foreach net
    #     speedy_begin_net
    #     foreach port
    #       speedy_add_point
    for {set n 0} {$n < $numnets} {incr n} {
      # Each pin-name is subcell${hch}pin or a top-level port with no $hch.
      # nl_get_pins can return an empty list for an unconnected wire.
      set pinno [lindex $nlnets $n]
      # We use -recursive in both flat and non-flat cases, because in the
      # non-flat case
      set pins [nl2_get_net_pins -hier 1 $curmod $pinno]
      set cap_fudge 0
      if {[llength $pins] > 0} {
	#steiner_begin_net [set save([incr bugfix]) $nlnet]
	#set nlnet [nl "lindex \$nlnets $n"]
	set nlnet [lindex $nlnets $n]

	#puts "steiner_begin_net $nlnet"
	if {$hch != $ohch} {
	  regsub -all "\\$hch" $nlnet $ohch nlnet
	}
	steiner_begin_net $nlnet


	foreach pin_name $pins {
	  # TODO: Make a new function to do this!!!

	  set lab_info [dbt_find_label -hch $hch $pin_name]
	  if {$lab_info == ""} {
	    msg "warning: pin $pin_name not found.\n"
	    continue
	  }

	  if {0} {
	    setl {lx ly iodir curlayer text} \
	    	  [fplan_db_pin2 -hch $hch -xform -fixname $pin_name]
	    set i [string last $hch $pin_name]
	    if {$i == -1} {
	      set lab $pin_name
	      set modpath ""
	    } else {
	      set modpath [string range $pin_name 0 [expr $i-1]]
	      if {$hch != $ohch} {
		regsub -all "\\$hch" $modpath $ohch modpath
	      }
	      set lab [string range $pin_name [expr $i+1] end]
	    }
	  }

	  set modpath [join [labinfo_path $lab_info] $hch]
	  if {$hch != $ohch} {
	    regsub -all "\\$hch" $modpath $ohch modpath
	  }

	  set iodir [labinfo_kind $lab_info]
	  setl {lx ly} [labinfo_loc $lab_info]
	  # It does not take floating point, so round off the location.  Within a micron is close enough.
	  #puts "steiner_add_point $modpath $lab $iodir [expr int($lx)] [expr int($ly)]"
	  steiner_add_point $modpath [labinfo_text $lab_info] $iodir [expr int(round($lx))] [expr int(round($ly))]
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
    nlt_hier_char $orig_hier_char

  }
  msg "write dspf done\n"
}


proc misc_text_edit {args} {
  global OPTIONS EDITOR

  set editor [use_first OPTIONS(editor) EDITOR env(EDITOR) env(VISUAL) 'vi]

  eval exec xterm -e "$editor $args"
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
  foreach nlinst [nl2_list_cells $topmod] {
    # Note: This logged command can not be executed from the log file,
    # because the nlinst is an object, which when converted from a string
    # can not be converted back properly because nl_current_design is not set correctly.
    nlt_log {set subref [nl_get_cell_reference $nlinst]}
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




# TODO: Add option to print lef cells, vias, fets or not.
# TODO: Add option to print to file.
# TODO: Add to listing printout: type (lef, undef), verilog filename.
proc fplan_print_hier {{-gcells 0} {cell ""} {level 0}} {
  if {$cell == ""} {
    set cell [lay_editcell]
    set spaces ""
  } else {
    # The format %*s does not work for level 0, it always
    # adds at least one space, which is why it is in an else clause.
    set spaces [format "%*s" $level " "]
  }

  setl {type xsize ysize} [fplan_cell_info -get $cell]

  set is_gcell [string match {#*} $cell]

  if {$is_gcell} {

    if {[string match {#GROUP*} $cell]} {
      # Never print gcell groups.
      # Dont incr level for groups, either.
    } else {
      # Some other gcell.
      if {$gcells} {
	puts "$spaces$cell ([fplan_db_cell  module $cell]) $type"
      }
      return
    }
  } else {
      puts "$spaces$cell ([fplan_db_cell  module $cell]) $type"
      incr level
  }

  if {$type != "lef" && $type != "undef"} {
    # Dont bother about gcells.
    # Make sure the cell is loaded.
    edit_push_direct
    cell_load_cell -opt $cell
    edit_pop_direct
    foreach subcell [db_kids $cell] {
	fplan_print_hier $subcell $level
    }
  }
}


proc fplan_fix_name {{-label} name} -desc {
  Change bad chars in a verilog name to something max can use.
} {
  if {[use_list_path]} {return $name}

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
  Reverse of _fplan_fix_name
} {
  if {[use_list_path]} {return $name}

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

  set hch [nlt_hier_char]
  set mod [fplan_db_cell module [lay_editcell]]

  set repeater_cnt 0

  foreach cell_info [db_instances -of $rep_cell] {
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
      nlt_log {nl_remove_cell [nl2_find_cell $mod $vid]}
      # Disconnect the pin on the other end of the net what the output was
      # hooked to, and hook the innet to that pin.
      nlt_log {set otherpin [lindex [nl_get_net_pins $outnet] 0]}
      nlt_log {nl_disconnect_pin $otherpin}
      nlt_log {nl_remove_net $outnet}
      nlt_log {nl_connect_pin $otherpin $innet}

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

  fplan_sync_nl_hierarchy

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
  set hch [nlt_hier_char]
  set parentmod [fplan_db_cell module [lay_editcell]]

  set total_output_cnt 0
  set total_repeater_cnt 0

  foreach net [nl2_list_nets -hier 1 $parentmod] {
    set pin_objects [nl2_get_net_pins -hier 1 $parentmod $net]

    # Find the output pin, and count other pins.
    set output ""
    set outcnt 0
    set incnt 0
    set inoutcnt 0
    foreach nlpin $pin_objects {
      # The nl_get_pin_direction is "in" if the pin is being driven,
      # or "out" if it is a driver, taking into account whether it is a subcell or not.
      # Ie: if IP is an input port:
      # nl_get_pin_direction subcell.IP  -> "in"
      # nl_get_pin_direction IP -> "out"
      nlt_log {set dir [nl_get_pin_direction $nlpin]}
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
      nlt_log {set dir [nl_get_pin_direction $nlpin]}
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
	nlt_log {set this_repeater [nl_find_references -exact $rep_cell]}
	if {1 != [llength $this_repeater]} {
	   # Create a nl reference for the repeater buffer.
	  nlt_log {nl_create_reference $rep_cell}
	  nlt_log {nl_create_refpin in $rep_cell}
	  nlt_log {nl_create_refpin out $rep_cell}
	}

	#nl_disconnect_pin pin
	#nl_create_net net "wire" [mod]
	#nl_connect_pin pin net

	# Unhook the old net destination (subcell input or top-level output).
	nlt_log {nl_disconnect_pin $nlpin}

	# Add in the repater
	nlt_log {nl_create_cell $repname $rep_cell}

	# Hook up repeater input to curnet.
	nlt_log {nl_connect_pin ${repname}${hch}in $curnet}

	# Create new net for repeater output, xet curnet to it, and hook that up too.
	nlt_log {nl_create_net $newnet "wire"}
	nlt_log {nl_connect_pin ${repname}${hch}out $newnet}
	nlt_log {nl_connect_pin $nlpin $newnet}

	set curnet $newnet
      }
    }
  }

  msg "fplan_repeater done - processed $total_output_cnt nets, added $total_repeater_cnt repeaters\n"
}


proc _fplan_chop_list {list {max 10}} -desc {
  Return a message containing at most max elements from list.
} {
  set ret [lsort [lrange $list 0 $max]]
  if {[llength $ret] >= $max} {
    append ret "..."
  }
  return $ret
}


proc fplan_design_check {{-cell ""}} {
  global FPLAN

  if {$cell == ""} {set cell [lay_editcell]}
  msg "fplan_design_check cell $cell\n"

  set mod [fplan_db_cell module $cell]
  set prb [techinfo layer prb]
  set grid $FPLAN(block_grid)

  if {$mod == ""} {
    max_error -buffer "No 'module' property on cell $cell"
    set mod [fplan_unfix_name $cell]
  }

  # Look at prb
  set prb_label [db_search_l labels -layers $prb -cell $cell -kind comment -non_hier bbox]
  set prb_tiles [db_search_paint  -cell $cell $prb]
  set coords ""		;# Default if no prb found.

  if {[llength $prb_label] == 0 && [llength $prb_tiles] == 0} {
      max_error -buffer "No prb label or layer in cell $cell"
  }

  if {[llength $prb_tiles] == 1} {
    # Ok, it is still using a prb layer.
    set coords [lrange [lindex $prb_tiles 0] 1 4]
  }

  # If both prb label and tile, the label will be used,
  # so we check for a label after checking for a tile.
  if {[llength $prb_label] == 1} {
    set coords [labinfo_loc [lindex $prb_label 0]]
  }

  if {[llength $prb_tiles] > 1} {
    max_error -buffer "Non-rectangular prb layer!"
  }
  if {[llength $prb_label] > 1} {
    max_error -buffer "Multiple prb labels"
  }

  if {$coords != ""} {
    setl {px1 py1 px2 py2} $coords
    setl {fx1 fy1 fx2 fy2} [uusnap -grid $grid $px1 $py1 $px2 $py2]
    if {[approx $fx1 != $px1] || [approx $fy1 != $py1] || \
      [approx $fx2 != $px2] || [approx $fy2 != $py2]} {
      # prb layer not on fplan-block grid.  Thats bad.
      max_error -buffer "prb layer not on grid in cell $cell"
    }
  }


  if {0} {
    set len [llength [set paintballs [db_search_l paint -cell $cell -limit 2 $prb]]]
    if {$len == 0} {
      max_error -buffer "No prb layer in cell $cell"
    } elseif {$len > 1} {
      max_error -buffer "Non-rectangular prb layer in cell $cell"
    } else {
      struct max_paint p [lindex $paintballs 0]
      setl {fx1 fy1 fx2 fy2} [uusnap -grid $grid ${p.x1} ${p.y1} ${p.x2} ${p.y2}]
      if {[approx $fx1 != ${p.x1}] || [approx $fy1 != ${p.y1}] || \
	[approx $fx2 != ${p.x2}] || [approx $fy2 != ${p.y2}]} {
	# prb layer not on fplan-block grid.  Thats bad.
	max_error -buffer "prb layer not on grid in cell $cell"
      }
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
      comment {continue}
    }
    set lab_id [labinfo_text $lab_info]
    if {[info exists max_labels($lab_id)]} {
      max_error -buffer "duplicated label $lab_id"
    }
    set max_labels($lab_id) $lab_info
  }

  set max_label_list [array names max_labels]
  nlt_log {set nl_port_list [nl_list_ports $mod]}

  setl {extra_max_ports extra_nl_ports} [utils_ldiff $max_label_list $nl_port_list]

  if {[llength $extra_nl_ports]} {
    max_error -buffer "Cell $cell: [llength $extra_nl_ports] verilog ports did not appear in max:\
	[_fplan_chop_list $extra_nl_ports]"
  }

  if {[llength $extra_max_ports]} {
    max_error -buffer "Cell $cell: [llength $extra_max_ports] max ports did not appear in verilog:\
	[_fplan_chop_list $extra_max_ports]"
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
    setl {extra_max_cells extra_nl_cells} [utils_ldiff $max_cell_list $nl_cell_list]

    if {[llength $extra_max_cells]} {
      max_error -buffer "Cell $cell: [llength $extra_max_cells] max cells did not appear in verilog:\
	[_fplan_chop_list $extra_max_cells]"
    }

    if {[llength $extra_nl_cells]} {
      max_error -buffer "Cell $cell: [llength $extra_nl_cells] verilog cells did not appear in max:\
	[_fplan_chop_list $extra_nl_cells]"
    }
  }

  msg "fplan_design_check done\n"
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


proc fplan_save_nl_props {{cell ""}} -doc {
  You must have all cells for which this is to work already loaded into max.
} {
  global FPLAN

  if {$cell == ""} {
    # If no cell specified, do all non-lef cells in hierarachy.
    fplan_save_nl_props [lay_rootcell]
    foreach cell [dbt_kids -hierarchy -nogcells [lay_rootcell]] {
      if {![cell_in_memory $cell]} {continue}
      if {[fplan_cell_info -is_lef $cell]} {continue}

      fplan_save_nl_props $cell
    }
    return
  }

  set mod [fplan_db_cell module $cell]

  # Must set design sizes before setting location of instances using -origin.
  # Save size of cell.
  setl {x1 y1 x2 y2} [fplan_bbox -cell $cell]
  #nl_set_design_size $mod [expr $x2-$x1] [expr $y2-$y1]

  # Create pdesign for just the contents of this cell.
  # The second time through, this errors:
  nlt_log {catch {nl_create_pdesign -nohierarchy $mod}}
  nl2_set_design_size $mod $x1 $y1 $x2 $y2


  # Skip lef cells.
  if {[fplan_cell_info -is_lef $mod]} {return}

  # Set port locations.
  foreach lab_info [db_search_labels -cell $cell -non_hier] {
    switch -- [labinfo_kind $lab_info] {
      input - output - inout {
	setl {lx ly} [labinfo_loc $lab_info]
	set labtext [labinfo_text $lab_info]
	nlt_log {set nlport [nl2_find_port $mod $labtext]}
	nlt_log {nl_set_port_location $nlport $lx $ly}
      }
    }
  }

    # Save design props.
    foreach propname $FPLAN(cell_props) {
      # TODO: Jay just added nl commands to do this.
      set val [db_prop -def $cell $propname]
      if {$val != ""} {
	nl2_set_mod_attr $mod $propname $val
      }
    }

    # Save port props
    fplan_port_save_props_to_nl -cell $cell

    # Save cell locations (must save origin)
    edit_push_direct $cell  ;# Needed to use -parent with fplan_bbox.

    msg "saving instance locations in cell $cell...\n"
    set cnt 0

    nlt_log_puts "NOTE: not logging a zillion nl_set_cell_location and nl_set_cell_orientation"

    foreach cell_info [db_search_l cells -cell $cell] {
      incr cnt
      if {$cnt % 1000 == 0} {msg "$cnt...\n"}
      set inst [fplan_unfix_name [cellinfo_id $cell_info]]
      set ori [orientation [cellinfo_transform $cell_info]]
      #NO! setl {x1 y1 x2 y2} [fplan_bbox -parent -cellid [cellinfo_id $cell_info]]
      #NO! setl {x1 y1 x2 y2} [cellinfo_loc $cell_info]
      setl {x1 y1} [cell_origin $cell_info]


      # TEMPORARY!!!
      # Jay took out the recognition of max orientations, so use def orientations:
      global _DEF_ORIENT
      set ori $_DEF_ORIENT(out,$ori)

      # NOTE: This was pats way to do this:
      # nl_hier_set_cell_location [nl2_find_cell $inst $mod] [expr $x1*1000] [expr $y1*1000] $ori
      # This is jays way:

      # The nlt_log is *way* too slow.
      #nlt_log {set nlinstobj [nl2_find_cell $mod $inst]}
      #nlt_log {nl_set_cell_location -origin $nlinstobj [expr $x1*1000] [expr $y1*1000]}
      #nlt_log {nl_set_cell_orientation $nlinstobj $ori}

      set nlinstobj [nl2_find_cell $mod $inst]
      nl_set_cell_location -origin $nlinstobj [expr $x1*1000] [expr $y1*1000]
      nl_set_cell_orientation $nlinstobj $ori
    }
    edit_pop_direct
}

proc _fplan_obs_overlap {rootcell cellinfo1} -desc {
  Add a placement-obstruction layer to cover cell for overlapping hierarchical cells.
} {
    :load $rootcell
    set def1 [cellinfo_def $cellinfo1]
    #if {[is_gcell $def1] || [fplan_cell_info -is_lef $def1]} {continue}
    set id1 [cellinfo_id $cellinfo1]
    set area1 [fplan_bbox -parent -cellid $id1]
    foreach cellinfo2 [eval db_search_cells -area $area1] {
      set def2 [cellinfo_def $cellinfo2]
      if {[is_gcell $def2] || [fplan_cell_info -is_lef $def2]} {continue}
      set id2 [cellinfo_id $cellinfo2]
      if {$id2 == $id1} {continue}

      # We have two over-lapping hierarchical cells.
      # Default is to obstruct both of them, to make it really obvious
      # in the children, unless there is a label telling us which one.
      set result [db_prop -def $def1 stack_above]
      if {[lsearch -exact $result $id2] < 0} {
	# Cell id1 is not above id2, so place an obstruction for cell id2
	# in the cover cell of cell id1.
	# Cell id2 will be obstructed (maybe) when we see it as id1.
	setl {px1 py1 px2 py2} [fplan_bbox -parent -cellid $id2]
	set xform1 [cellinfo_transform $cellinfo1]
	setl {newx1 newy1} [transform_coords -reverse $xform1 $px1 $py1]
	setl {newx2 newy2} [transform_coords -reverse $xform1 $px2 $py2]

	# Clip to bbox of cell 1.
	set bbox1 [fplan_bbox -cell $def1]
	set cliprect [rect_clip $bbox1 [list $newx1 $newy1 $newx2 $newy2]]

	msg "obstructing $id1 with $id2 at $px1 $py1 $px2 $py2 result $newx1 $newy1 $newx2 $newy2\n"
	eval db_paint -cell ${def1}_cover pl_obs $cliprect
	foreach lay [techinfo layers metal] {
	  set obs_layer ${lay}_obs
	  if {[techinfo layer_exists $obs_layer]} {
	    eval db_paint -cell ${def1}_cover $obs_layer $cliprect
	  }
	}
      }
    }
}


proc _fplan_copy_cover_obs {subdef subcovercell} {
    edit_push_direct $subcovercell	;# Needed for fplan_bbox -parent
    set pl_obs pl_obs
    if {[techinfo layer_exists $pl_obs]} {
      eval db_paint -cell $subdef -erase $pl_obs [db_bbox -cell $subdef]
      foreach cellinfo [db_search_cells -cell $subcovercell] {
	set rect [fplan_bbox -parent -cellid [cellinfo_id $cellinfo]]
	if {$rect == ""} continue
	eval db_paint -cell $subdef $pl_obs $rect
      }

      # Copy pl_obs layer from cover cell to main cell.
      foreach paintball [db_search_paint -cell $subcovercell $pl_obs] {
	eval db_paint -cell $subdef $pl_obs [lrange $paintball 1 4]
      }
    }

    foreach layer [techinfo layers metal] {
      set obslayer ${layer}_obs
      if {[techinfo layer_exists $obslayer]} {
	eval db_paint -cell $subdef -erase $obslayer [db_bbox -cell $subdef]
	foreach paintball [db_search_paint -cell $subcovercell ${layer},${obslayer}] {
	  eval db_paint -cell $subdef $obslayer [lrange $paintball 1 4]
	}
      }
    }
    edit_pop_direct
}


proc fplan_cover_punch {{-cell ""} {-hier 2} {-add_obs 1} {-obs_overlap 1}} -doc {
  Copy metal and obstructions from cover.max
  into contained cells as metal obstructions.
} {
  global FPLAN
  set rootcell [expr {$cell == "" ? [lay_rootcell] : $cell}]
  set covercell ${rootcell}_cover

  if {[string match *_cover $rootcell]} {
    error "You are currently editing a cover cell!"
  }

  if {$cell == ""} {
    set prop_list ""
    lappend prop_list [list "Top cell:" rootcell -label]
    lappend prop_list [list "Top cover cell:" covercell -label]
    lappend prop_list [list "Punch top cover cell obstructions how far:" hier -enum {"none" "1 level hierarchy" "all levels hierarchy"}]
    lappend prop_list [list "Add obstructions for overlapping blocks to cover cells" obs_overlap -binary]
    lappend prop_list [list "Copy obstructions from cover cells to main cells" add_obs -binary \
      -help {copies metal in each cover cell to main cells as metal-obstruction layers,\
      and creates a placement-obstruction (pl_obs) layer to the main cell for each cell in the cover cell.\
      Pre-existing obstruction layers in main cells are deleted first.}]
    set title "Chipper Cover Cell Puncher"
    if {![prop_menu2 -title $title $prop_list]} {
      return  ;# cancelled
    }
  }

  cell_load_cell -opt $covercell
  if {[lay_rootcell] != $covercell} {
    error "Cell $covercell not found"
  }

  set save_autoload $FPLAN(verilog_autoload)
  set FPLAN(verilog_autoload) 0			;# Otherwise it tries to load verilog for subcells

  set subcell_list ""

  # Pass 1: gather up hierarchical cells.
  # If no hier, leave subcell_list empty
  if {$hier} {
    foreach subcellinfo [db_search_cells -user_bbox -cell $rootcell] {
      set subdef [cellinfo_def $subcellinfo]
      if {[is_gcell $subdef] || [fplan_cell_info -is_lef $subdef]} {continue}

      # Make sure subcell is loaded.
      if {[catch ":load $subdef" msg]} {
	max_error -buffer "Cannot find cell $subdef.  Cell skipped."
	continue
      }
      lappend subcell_list $subcellinfo
    }
  }

  # Pass 2: delete existing cover cells.

  foreach subcellinfo $subcell_list {
    set subdef [cellinfo_def $subcellinfo]
    set subcovercell ${subdef}_cover

    # Load or create subcell cover cell.
    # We delete it, instead of db_cell_clear, to make
    # sure it will go to the correct directory when written.

    set subdir [file dir [cell_file $subdef]]

    msg "Creating cell ${subdir}/${subcovercell}\n"
    # Delete any existing subcell cover cell.
    catch {db_cell_delete $subcovercell}
    db_cell_new $subcovercell ${subdir}/${subcovercell}.max
  }

  # Pass 3: Add obstructions for cell overlaps to cover cells.
  if {$obs_overlap} {
    foreach subcellinfo $subcell_list {
      _fplan_obs_overlap $rootcell $subcellinfo		;# This puts obstructions in the cover cells.
    }
  }

  # Punch the root cell cover cell down the hierarchy.
  foreach subcellinfo $subcell_list {
    set subdef [cellinfo_def $subcellinfo]
    set subcovercell ${subdef}_cover

    # Back to main cover cell.
    :load $covercell
    setl {x1 y1 x2 y2} [cellinfo_loc $subcellinfo]
    sel_area -no_labels $x1 $y1 $x2 $y2

    db_cell_copy -source __SELECT__ -offset [expr -1*$x1] [expr -1*$y1] $subcovercell

    # Add a prb label, so when viewing cover cell with db_bbox_user_layers,
    # the bounding box will look correct.
    setl {lx1 ly1 lx2 ly2} [fplan_bbox -cell $subdef]
    fplan_set_bbox -cell $subcovercell $lx1 $ly1 $lx2 $ly2

    db_prop -def $subcovercell cell_type cover

    if {$hier == 2} {
      fplan_cover_punch -hier $hier -cell $subdef
    }
  }

  if {$add_obs} {
    # If hier == 0, dont do this;
    # if hier == 2 , we did this when we recured down into the subcell.
    if {$hier == 1} {
      foreach subcellinfo $subcell_list {
	set subdef [cellinfo_def $subcellinfo]
	_fplan_copy_cover_obs $subdef ${subdef}_cover
      }
    }

    # Copy obstruction layers from root cover cell to root cell.
    _fplan_copy_cover_obs $rootcell $covercell
  }

  # Go back to original cell.
  :load $rootcell

  set FPLAN(verilog_autoload) $save_autoload
}

proc fplan_write_props_menu {} {
  global _FPLAN_WRITE_PROPS
  use_init _FPLAN_WRITE_PROPS(hier) 0

  set filename [lay_editcell].etc

  set prop_list ""
  lappend prop_list [list "Filename" filename -filename [list -message "Write Props" -filename $filename -pattern *.etc]]
  lappend prop_list [list "Include Hierarchy" _FPLAN_WRITE_PROPS(hier) -binary]
  set title "Write Props"
  if {![prop_menu2 -title $title $prop_list]} {
    return
  }
  fplan_write_props -hier $_FPLAN_WRITE_PROPS(hier) -filename $filename [lay_editcell]
  msg "write_props done\n"
}


proc fplan_write_props {{-hier 0} {-append} {-filename ""} {cell ""}} -desc {
  Save props for specified cell, including instance props on instances.
} -doc {
  If -hier 1, save props for all in-memory hierarchy in a single file.
  If -append, append to existing file.
  Save props any instance that has a placer property other than "unplaced"
} {
  global FPLAN_PORT_OPTIONS DEF_ORIENT

  if {$cell == ""} {
    set cell [lay_rootcell]
  }

  if {$filename == ""} {
    set filename [file rootname [cell_file $cell]].etc
  }

  # If no cell specified, do all non-lef cells in hierarachy.
  if {$hier} {
    fplan_write_props -filename $filename $cell
    foreach subcell [dbt_kids -hierarchy -nogcells $cell] {
      if {![cell_in_memory $subcell]} {continue}
      if {[fplan_cell_info -is_lef $subcell]} {continue}

      fplan_write_props -append -filename $filename $subcell
    }
    return
  }

  msg "Writing props for cell $cell to file $filename\n"

  set mod [fplan_db_cell module $cell]
  # Skip lef cells.
  if {[fplan_cell_info -is_lef $mod]} {return}

  set pf [open $filename [expr {$append ? "a" : "w"}]]

  unwind_catch {

    if {!$append} {
      # Output a header
      puts $pf {# NL Properties File.  Format:}
      puts $pf {# M modname - begin module}
      puts $pf {# P portname [x y layer kind ori] - begin port}
      puts $pf {# I cellname [type [x y ori]] - begin instance}
      puts $pf {# A name value - generic attribute on current object}
      puts $pf {# S... - special attributes, may be:}
      puts $pf {# SG x1 y1 x2 y2 - port geometry DEF orientation and DEF geometry}
      puts $pf {# SD x1 y1 x2 y2 - design size}
      puts $pf {# E modname - end module (required)}
      puts $pf {#}
    }


    puts $pf "M [list $mod]"

    set propnames [db_prop -def $cell]

    # Cell size
    puts $pf "\tSD [fplan_bbox -cell $cell]"

    # Cell props
    foreach prop $propnames {
      if {[string first "(" $prop] == -1} {
	puts $pf "\tA $prop [list [db_prop -def $cell $prop]]"
      }
    }

    # Ports
    foreach port [fplan_db_pin_list -cell $cell] {
      set labinfo [lindex [db_search_labels -cell $cell -no_glob $port] 0]
      if {[llength $labinfo] == 0 } {
	msg "cell $cell port $port not found!\n"
      }

      # Port name, location and layer are special.
      setl {x y} [labinfo_loc $labinfo]
      set layer [labinfo_layer $labinfo]
      puts $pf "\tP [list $port] $x $y [list $layer] [labinfo_kind $labinfo] N"

      # Port props
      foreach pair $FPLAN_PORT_OPTIONS {
	set atname [lindex $pair 0]
	set defaultvalue [lindex $pair 1]
	#set currentvalue [db_prop -def $cell $port($atname)]
	set currentvalue [fplan_db_pin -cell $cell getprop $port $atname]
	if {$currentvalue != $defaultvalue} {
	  puts $pf "\t\tA $atname [list $currentvalue]"
	}
      }
    }

    # Cell instances
    # Save the location of any cell with place="fixed" 
    foreach cellinfo [db_search_cells -cell $cell] {
      set id [cellinfo_id $cellinfo]
      set def [cellinfo_def $cellinfo]
      #set place [db_prop -def $cell I($id,place)]
      set place [fplan_db_inst -cell $cell getprop $id place]
      if {$place != "" && $place != "unplaced"} {
	setl {x y} [cellinfo_loc $cellinfo]
	set ori [orientation [cellinfo_transform $cellinfo]]
	# Note: The origin is the cell ORIGIN, not the lower left corner!
	# This is unlike DEF files.
	puts $pf "\tI [list $id] [list $def] $x $y $DEF_ORIENT(out,$ori)"
	puts $pf "\t\tA place [list $place]"
      }
    }

    puts $pf "E $mod"

  } always {
    close $pf
  }
}

proc fplan_read_props_menu {} {
  global _FPLAN_READ_PROPS

  use_init _FPLAN_READ_PROPS(filename) [lay_editcell].etc
  set prop_list ""
  lappend prop_list [list "Filename" _FPLAN_READ_PROPS(filename) -filename [list -message "Read Props" -pattern *.etc]]
  set title "Read Props"
  if {![prop_menu2 -title $title $prop_list]} {
    return
  }
  fplan_read_props $_FPLAN_READ_PROPS(filename)
}

proc fplan_read_props {{filename ""}} -desc {
  Read props and apply to any matching instance found.
} -doc {
  Warn if not found, except: do not warn about hierarchical
  blocks that have place=flatten.
} {
  global DEF_ORIENT

  if {$filename == ""} {
    set filename [file rootname [cell_file [lay_rootcell]]].etc
  }

  set pf [open $filename "r"]

  set cell ""
  set modcnt 0
  set type ""

  msg "reading file: $filename\n"
  set lineno 0
  set type ""

  unwind_catch {
    while {[gets $pf line] >= 0} {
      incr lineno

      switch -- [lindex $line 0] {
	"#" {continue}
	"M" {
	  set type M
	  set cell [lindex $line 1]
	  incr modcnt
	}
	"I" {
	  set type I
	  setl {junk instname itype x y defori} $line
	  if {$x != ""} {
	    # Move cell instance to where it goes.
	    set max_ori $DEF_ORIENT(in,$defori)
	    set cellinfo [lindex [db_instances -cell $cell -id $instname] 0]
	    if {[llength $cellinfo] == 0} {
	      msg "Warning: cell $cell instance $instname not found, creating\n"
	    } else {
	      db_instance_delete -cell $cell $instname
	    }
	    db_instance -cell $cell -orientation $max_ori -id $instname $itype $x $y
	  }
	}
	"P" {
	  set type P
	  setl {junk portname x y layer kind} $line
	  if {$x != ""} {
	    set old [lindex [db_search_labels -cell $cell -no_glob -non_hier $portname] 0]
	    if {[llength $old] == 0} {
	      msg "Cell $cell label $portname not found; creating\n"
	      set old_pos EAST
	    } else {
	      set old_kind [labinfo_kind $old]
	      if {$kind != $old_kind} {
		msg "warning: cell $cell port $portname: changed from kind $old_kind to $kind\n"
	      }
	      setl old_layer [labinfo_layer $old]  ;# Its ok to reassign the layer.
	      set old_pos [labinfo_pos $old]
	      setl {oldx1 oldy1 oldx2 oldy2} [labinfo_loc $old]
	      db_label -delete -cell $cell -pos $old_pos -kind $old_kind $old_layer $portname $oldx1 $oldy1 $oldx2 $oldy2
	    }
	    db_label -cell $cell -pos $old_pos -kind $kind $layer $portname $x $y
	  }
	}
	"A" {
	  set name [lindex $line 1]
	  set val [lindex $line 2]
	  switch $type {
	    I {
	      fplan_db_inst -cell $cell setprop $instname $name $val
	    }
	    P {
	      fplan_db_pin -cell $cell setprop $portname $name $val
	    }
	    M {
	      db_prop -def $cell $name $val
	    }
	    default {
	      error "file $filename line $lineno: orphan A line: $line"
	    }
	  }
	}
	"SG" {
	    if {$type != "P"} {error "file $filename line $lineno: SP prop not on cell instance: $line"}
	    # Max ignores this stuff.
	}
	"SD" { ;# design size.
	    setl {junk x1 y1 x2 y2} $line
	    fplan_set_bbox -cell $cell $x1 $y1 $x2 $y2
	}
	"E" {
	  if {$cell != [lindex $line 1]} {
	    error "file $filename line $lineno: E modulename does not match preceding M modulename"
	    break
	  }
	  set cell ""
	}
	default {
	  error "file $filename line $lineno: unrecognized line: $line"
	  break
	}
      }

    };#while

  } always {
    close $pf
  }

  if {$cell != ""} {
    error "file $filename: missing E line"
  }

  if {$modcnt == 0} {
    max_error -buffer "file $filename: no modules defined"
  }
}

proc fplan_goldify {{-interactive 0} {cell ""}} -desc {
  Make golden max file.
} -doc {
} {

  if {$cell == ""} {
    set cell [lay_editcell]
  }

  if {$interactive} {

    set title "Goldify Cell $cell"
    set msg "This command will delete all unplaced cells from the current cell\
       and all hierarchically contained cells.  Do you want to continue?"
    if {[prop_dialog -buttons "OK Cancel" -title $title $msg] == "Cancel"} {return}
  }

  foreach subcell [db_kids $cell] {
    foreach info [db_instances -cell $cell -of $subcell] {
      set status [fplan_db_inst getprop [cellinfo_id $info] place]
      if {$status == ""} {
        set status unplaced
      }
      if {[fplan_cell_info -is_hier $subcell]} {
        if {$status == "unplaced"} {
          puts "db_instance_delete -cell $cell [lindex $info 0]"
          db_instance_delete -cell $cell [lindex $info 0]
        } elseif {$status == "fixed"} {
	  fplan_goldify $subcell
	}
      } else {
        if {$status != "fixed"} {
          puts "db_instance_delete -cell $cell [lindex $info 0]"
          db_instance_delete -cell $cell [lindex $info 0]
        }
      }
    }
  }
}

proc _new_nl_version {} {
  global nl_version

  #global TEST_NL
  #if {[use_first TEST_NL] == ""} { return 0 }

  # nl_version looks like: "0.33x for SunOS blah blah..."
  regsub {[x ].*$} $nl_version "" version
  return [expr {$version >= 0.33}]
}


# I wanted to use nl_get_net_pins -hierarchy after setting
# the libcell flag for flattened cells, but it doesnt work because
# Jay's implementation requires an idesign in order to have object
# handles to return when you do a hierarchical traversal.
proc fplan_sync_nl_hierarchy {} -desc {
  Set the nl stop bit on subcells for the current cell based on flattening info.
} -doc {
  Allows you to use hierarchical operations in nl, example:
      nl_get_net_pins -hierarchy
  and have the hierarchy stop at the current set of non-flattened cells.
  Requires the nl idesign to be created rooted at the current cell.
} {
  # TODO: Need to delete the old idesign, as soon as jay makes a way.
  set mod [fplan_db_cell module [lay_rootcell]]

  set atname pats_design_stop_attr

  foreach cell [db_kids] {
    if {[fplan_cell_info -is_lef $cell]} {continue}
    foreach instinfo [db_instances -of $cell] {
      set type [fplan_db_inst getprop  [cellinfo_id $instinfo] place]
      set submod [fplan_db_cell module $cell]
      if {$type == "flatten"} {

	if {[_new_nl_version]} {
	  nlt_log {catch {nl_create_design_attribute $atname $submod}}
	  nlt_log {catch {nl_set_design_attribute [nl_find_attributes $atname $submod] $submod {}}}
	} else {
	  nlt_log {nl_unset_libcell $submod}
	}
      } else {
	if {[_new_nl_version]} {
	  nlt_log {catch {nl_create_design_attribute $atname $submod}}
	  nlt_log {nl_set_design_attribute [nl_find_attributes $atname $submod] $submod "stop"}
	} else {
	  nlt_log {nl_set_libcell $submod}
	}
      }
      # This prop is really on the cell type,
      # so we only need to check one instance.
      break
    }
  }

  if {[_new_nl_version]} {
    nlt_set_idesign -stop_attribute $atname $mod
  } else {
    nlt_set_idesign $mod
  }
}

proc fplan_reset_nl_hierarchy {} -desc {
  Unset the libcell flag on all currently loaded hierarchical designs.
} {
  if {[_new_nl_version]} {
    # We dont need to do anything - the attributes we set are harmless.
    return
  }

  set cell_names ""
  foreach cell_thing [split [string trim [db_cells -user] \n] \n] {
    lappend cell_names [lindex $cell_thing 0]
  }

  foreach cell $cell_names {
    set mod [fplan_db_cell module $cell]
    if {$mod == ""} {
      # Just assume it wasnt a cell we care about.
      # Dont know if this happens.
    }
    if {[string index $mod 0] == "#"} { continue }
    if {[nl_find_designs -exact $mod] == ""} {continue}
    if {! [fplan_cell_info -is_lef $mod]} {
      nl_unset_libcell $mod
    }
  }
}
