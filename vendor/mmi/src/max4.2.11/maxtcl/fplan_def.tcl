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

set RCSVERSION(fplan_def.tcl) { $Revision: 1.3 $ }



#set MAX_STRUCT(max_label) "layer x1 y1 x2 y2 pos text path group kind"
#set MAX_STRUCT(max_cell) "id def x1 y1 x2 y2 path expansion transform arrayinfo"

set MAX_SEL_BUG_WORK_AROUND 1

# TODO: Fix names for special chars!!

# TODO: Def writer should have option traverse hierarchy or just write
#	from current cell.  To traverse hierarchy, use lay_internals on
#	all non-leaf cells, then db_search -any_cell for cells and labels.
#	This will even work for the preroutes, because they are identified
#	by the labels on them.
#	But it will NOT work for arbitrary unlabeled paint, because there
#	is no way to get rid of the via paint.
# Resolution: the def writer for nets should be part of the max netlister.

# TODO: Add option to read_def without goto cell.
# TODO: Add warning if group found, and flatten it.
# TODO: Write def directly from hierarchical file.
# TODO: read_def should warn if bbox from def does not match prb in existing max file.
# TODO: read_def: Use jay's DEF parser.  Read special nets, including vias.
# TODO: Look at cadence web site for DEF test cases.

# If no lef size, use this default width the the cell when reading the def.
# Default height comes from grid.
set DEFAULT_WIDTH 10
set DEFAULT_HEIGHT 10


# Not used.
#set _DEF_ORIENT(out,) N
#set _DEF_ORIENT(out,fx) FN
#set _DEF_ORIENT(out,fy) FS
#set _DEF_ORIENT(out,r180) S
#set _DEF_ORIENT(out,r90) E
#set _DEF_ORIENT(out,fx_r90) FW
#set _DEF_ORIENT(out,fy_r90) FE
#set _DEF_ORIENT(out,r270) W

#set _DEF_ORIENT(in,N) ""
#set _DEF_ORIENT(in,FN) fx
#set _DEF_ORIENT(in,FS) fy
#set _DEF_ORIENT(in,S) r180
#set _DEF_ORIENT(in,E) r90
#set _DEF_ORIENT(in,FW) fx_r90
#set _DEF_ORIENT(in,FE) fy_r90
#set _DEF_ORIENT(in,W) r270


# Reads a def netlist and places cells.
# Only read COMPONENTS for now

proc fplan_read_def {{-save_port 0} {-flat 1} {-pins 1} {-merge 0} {filename ""}} -type local -desc {
  reads in the def file and places cells in the current window
} {

  global CELL _FPLAN_READ_DEF

  if {$filename == ""} {
    # Interactive mode.  Load _FPLAN_READ_DEF from defaults first time through.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      use_init _FPLAN_READ_DEF($option) [set $option]
    }

    # bring up file selection box
    set prop_list ""
    #set filename [fs_box -message "DEF File to Load:" -pattern "*.def"]

    use_init _FPLAN_READ_DEF(filename) [lay_editcell].def

    lappend prop_list [list filename _FPLAN_READ_DEF(filename) \
	-filename [list -message "DEF File to Load:" -pattern {*.def}]]

    lappend prop_list [list "Hierarchy" _FPLAN_READ_DEF(flat) \
	-enum {"load just current cell" "load all hierarchy into current cell" \
	  "load def hiearchy into max hierarchy (not implemented)"} \
	-help {if "load all hiearchy into current cell,\
	all def cells are read into the current cell with\
	hierarchical instance names.}]

    lappend prop_list [list "Merge placement" _FPLAN_READ_DEF(merge) -binary]

    lappend prop_list [list "Read PINS" _FPLAN_READ_DEF(pins) -binary]

    lappend prop_list [list "Preserve any existing label properties" _FPLAN_READ_DEF(save_port) -binary]


    if {[prop_menu2 -title "Read Def File" $prop_list] == 0} {
      return ;# cancelled
    }

    set filename $_FPLAN_READ_DEF(filename)
    if {$filename == ""} {
      error "no filename specified"
    }
  } else {
    # Load _FPLAN_READ_DEF with defaults from proc def, above.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      set _FPLAN_READ_DEF($option) [set $option]
    }
  }

  if {0} {
    global MC
    if {![info exists MC(boundary)] || [catch "lay_layer_styles $MC(boundary)"]} {
      # get a boundary layer
      if {![catch "lay_layer_styles prb"]} {
	# use the prb layer
	set MC(boundary) prb
      } else {
	# query user

	# get all the layers
	set layers ""
	foreach layer [split [db_types] \n] {
	  if {$layer != "" && [lsearch [lindex $layer 4] "builtin"] == -1} {
	    lappend layers [lindex $layer 0]
	  }
	}

	set prop_list ""
	set MC(boundary) [lindex [lreverse $layers] 0]
	lappend prop_list [list "bbox layer" MC(boundary) -choice $layers]

	set title "Boundary Layer"
	set message "Choose layer:"

	# create the menu
	if {![prop_menu2 -message $message -title $title $prop_list]} {
	  # cancelled
	  return
	}
      }
    }
  }

  set cell_name [file rootname [file rootname [file tail $filename]]]

  if {$_FPLAN_READ_DEF(merge)} {
    catch {cell_load -search $cell_name}
    if {![cell_in_memory $cell_name]} {
      db_cell_new $cell_name $cell_name$CELL(default_suffix)
    }
    cell_load $cell_name
  } else {

    # create a new cell if there isn't one in max of this name
    if {![_fplan_goto_cell $cell_name]} {
      # user said no
      return
    }
  }


  if {[catch {open $filename r} fd]} {
    # error
    error "Aborting, $fd"
  }
  # turn this off to make max faster
  undo_disable
  undo_flush

  unwind_catch {

    if {$_FPLAN_READ_DEF(pins) && ! $_FPLAN_READ_DEF(save_port)} {
      fplan_db_pin delete
    }

    puts "Parsing DEF file $filename ..."
    set cell_count 0
    set net_count 0
    set pin_count 0

    edit_push_direct

    set error [_fplan_read_def_internal $fd]

    edit_pop_direct ;# Re-edit original cell
  } always {
    # close the file
    close $fd

    db_notify
    undo_enable
  }

  if {$error != ""} {
    error $error
  }

  eval lay_box [lay_bbox]
  sel_clear
  :view

  puts "Read $cell_count components, $net_count nets, $pin_count pins, into cell \"$cell_name\"."
  puts "done."
}

proc _fplan_read_def_line {fd line} {

    # a line must end with a semicolon, otherwise get the next line
    while {[set n [string last \; $line]] == -1} {

      if {[gets $fd next_line] >= 0} {
	append line " $next_line"
      } else {
	error "read_def: aborting, unexpected end of file.  Missing ;"
      }
    }

    # Trim off the trailing semicolon

    set line [string range $line 0 $n]

    # Do NOT use lindex on the line without splitting it properly,
    # because the instance or net name may have tcl special
    # list characters (eg: \) in them.
    regsub -all {[ 	]+} $line " " line
    return [string trim $line]
}


proc _fplan_read_def_internal {{-flat 0} fd} -desc {
  Read def file.  Return error message or "".
} -doc {
  Users should not call this function!  -flat flag retained
  for backward compatibiliy because jdj might be calling this function.
} {
  global VIAS LEF_TRACKS _FPLAN_READ_DEF

  global MAX_SEL_BUG_WORK_AROUND

  if {$flat} {set _FPLAN_READ_DEF(flat) 1}

  set current_cell ""
  set top_cell [lay_editcell]

  upvar cell_count cell_count
  upvar net_count net_count
  upvar pin_count pin_count
  set line_num 0

  # parses something of the form
  # UNITS DISTANCE MICRONS 1000 ;
  # DIEAREA ( 0 0 ) ( 8400 30800 ) ;

  set unplaced_x 0

  while {[gets $fd line] >= 0} {

    set keyword [string range $line 0 [expr [string wordend $line 0] -1]]
    switch -exact -- $keyword {

      UNITS {
	set grid [expr [lindex $line 3] * 1.0]
      }

      DIEAREA {
	# found the bbox
	regsub -all {\(|\)} $line "" line
	setl {diearea die_x1 die_y1 die_x2 die_y2} $line

	set unplaced_x [expr $die_x2 + 20]

	# add a bbox for the boundary
	db_paint [techinfo layer prb] [expr $die_x1/$grid] [expr $die_y1/$grid] \
	    [expr $die_x2/$grid] [expr $die_y2/$grid]
      }

      TRACKS {
	# TRACKS Y 500 DO 84 STEP 1000 LAYER M1 M2 M3 M4 ;

	# a line must end with a semicolon, otherwise get the next line
	set line [_fplan_read_def_line $fd $line]

	# save these for writing
	set d [string toupper [lindex $line 1]]
	if {$d == "X" && [info exists die_y2]} {
	  set LEF_TRACKS($d) "$die_x1 $die_x2 $line"
	} elseif {$d == "Y" && [info exists die_y2]} {
	  set LEF_TRACKS($d) "$die_y1 $die_y2 $line"
	}
      }

      COMPONENTS {
	puts "read_def: parsing [lindex $line 1] $keyword"
	:load $top_cell
	# parses something of the form
	# COMPONENTS 2 ;
	# - OAI21B_ OAI21B + PLACED ( -14000 -19600 ) N ;
	# - INVA INVA + PLACED ( -12600 8400 ) N ;
	# END COMPONENTS

	set merge_cells ""

	# now read the components
	while {[gets $fd line] >= 0} {
	  if {[string trim $line] == ""} {continue}
	  if {[string first "END" $line] == 0} {
	    # we're done
	    break
	  }

	  set line [_fplan_read_def_line $fd $line]
	  set words [split $line " "]


	  # setl is pretty slow
#	  setl {dash instance_name type plus place leftp x y rightp orient} $line

	  if {[lindex $words 0] != "-"} {
	    # not a component
	    msg "read def: warning(1): unrecognized line: $line\n"
	    continue
	  }

	  set instance_name [lindex $words 1]
	  set newtype [fplan_fix_name [lindex $words 2]]
	  if {$newtype == ""} {
	    error "null component name on line: $line"
	  }

	  if {$_FPLAN_READ_DEF(flat) == 1} {
	    # for now, change hierarchical delimiter
	    # The fplan_fix_name does this by default.
	    set parent_cell [lay_editcell]
	    set newcellid [fplan_fix_name $instance_name]
	    set newcellpath $newcellid
	  } else {

	    set hierarchy [split $instance_name "/"]
	    set newcell [fplan_fix_name [lindex $hierarchy end]]

	    if {[llength $hierarchy] >= 2} {
	      if {$_FPLAN_READ_DEF(flat) == 0} {
		continue
	      }
	      error "read_def: full hierarchy not implemented"


	      # Create max hierarchical path name of parent of cell we are creating,
	      # being careful to fix special characters in the name supplied by def.
	      set path [fplan_fix_name [lindex $hierarchy 0]]
	      foreach element [lrange $hierarchy 1 [expr [llength $hierarchy] - 2]] {
		append path "/[fplan_fix_name $element]"
	      }

	      # Select the parent cell, figure out what its def is.
	      # TODO: catch error here
	      sel_cell3 $path
	      struct max_cell c [db_search cells -cell __SELECT__]
	      if {${c.def} == ""} {
		error "Can not find parent cell $path for cell $instance_name"
	      }
	      set parent_cell ${c.def}
	      set newcellid [fplan_fix_name ??]
	      ???

	    } else {
	      set parent_cell [lay_editcell]
	      set newcellid [fplan_fix_name $instance_name]
	      set newcellpath $newcellid
	    }
	  }
 
	  if {! [cell_in_memory $newtype]} {
	    catch {cell_load -search $newtype}
	    # cell_load moved us; return to parent cell.
	    :load $parent_cell
	    if {! [cell_in_memory $newtype]} {
	      # no cell, make a bogus cell from the lef data
	      db_notify
	      fplan_make_cell_from_lef $newtype
	    }
	  }

	  set loc_key ""

	  # Note: The fourth word (number 3), netName, is optional.
	  for {set wordn 3} {$wordn < [llength $words]} {} {

	    # Scan over stuff until we find something interesting.
	    # Each keyworded thing begins with a "+"
	    if {[lindex $words $wordn] != "+"} {incr wordn; continue}
	    incr wordn ;# Skip over +

	    set word [lindex $words $wordn]

	    switch -- $word {
	      "PLACED" -
	      "FIXED" -
	      "COVER" {
		set x [lindex $words [expr $wordn + 2]]
		set y [lindex $words [expr $wordn + 3]]
		set orient [lindex $words [expr $wordn + 5]]
		set loc_key $word
		incr wordn 5
		# Skip the rest of the COMPONENT statement, since we dont need anything else.
		break
	      }
	      "UNPLACED" {
		# This cell is unplaced.  Put it way outside the diearea
		if {[info exists die_x1]} {
		  # They will all mostly overlap, but we cant put them
		  # in exactly the same place or they would disappear.
		  set x $unplaced_x
		  set unplaced_x [expr $unplaced_x + 1]
		  set y 0
		  set orient N
		  set loc_key $word
		} else {
		  max_error -buffer "read_def: warning: skipping unplaced cell $instance_name"
		}
		incr wordn 5
		break
	      }
	    }
	  }

	  if {$loc_key == ""} {
	    max_error -buffer "read_def: error: Ignoring COMPONENT statement without placement: $line"
	    continue
	  }

	  setl {cx1 cy1 cx2 cy2} [fplan_bbox -grid mask -cell $newtype]
	  set xsize [expr $cx2 - $cx1]
	  set ysize [expr $cy2 - $cy1]

	  switch $orient {
	    N {
	      # don't flip
	      set ori ""
	      set cx [expr $x/$grid]
	      set cy [expr $y/$grid]
	    }
	    FN {
	      set ori fx
	      set cx [expr $x/$grid + $xsize]
	      set cy [expr $y/$grid]
	    }
	    FS {
	      # flip this 
	      set ori fy
	      set cx [expr $x/$grid]
	      set cy [expr $y/$grid + $ysize]
	    } 
	    S {
	      set ori r180
	      set cx [expr $x/$grid + $xsize]
	      set cy [expr $y/$grid + $ysize]
	    }
	    E {
	      # rotate this
	      set ori r90
	      set cx [expr $x/$grid]
	      set cy [expr $y/$grid + $xsize]
	    } 
	    FE {
	      # rotate this
	      set ori fy_r90
	      set cx [expr $x/$grid + $ysize]
	      set cy [expr $y/$grid + $xsize]
	    } 
	    FW {
	      # rotate this
	      set ori fx_r90
	      set cx [expr $x/$grid]
	      set cy [expr $y/$grid]
	    } 
	    W {
	      # rotate this
	      set ori r270
	      set cx [expr $x/$grid + $ysize]
	      set cy [expr $y/$grid]
	    } 
	    default {
	      max_error -buffer "read_def: warning: unrecognized orientation $orient on component $instance_name"
	    }
	  }

	  if {$current_cell != $parent_cell} {
	    :load $parent_cell
	    set current_cell $parent_cell
	  }

	  if {$_FPLAN_READ_DEF(merge)} {
	    # We would like to move the existing cell to the new location,
	    # but we cant, because max does not support having two cells
	    # at the same location.  So gather up the cells and then
	    # do it later.

	    if {$MAX_SEL_BUG_WORK_AROUND} {
	      sel_cell2 $newcellpath
	      :delete
	      lappend merge_cells [list $newcellid $newtype $cx $cy $ori]
	    } else {

	      # Be careful because it could land on an existing instance of the same cell.
	      sel_cell2 $newcellpath

	      if {0} {
		# This did not work: cells disappear during selt_transform
		# if they land on another cell.
		# UPDATE: It could work now because sel_transform has
		# a -dup_ok flag.  But its probably easier to delete
		# it and then re-instantiate it.

		# Get flipped right side up.
		struct max_cell c [db_search cells -cell __SELECT__]
		selt_transform -reverse -transform ${c.transform}

		setl {ox oy} [cell_origin]
		sel_move [expr $cx - $ox] [expr $cy - $oy]

		selt_transform -cell_origin ${c.def} $ori

		# This will error out if it fails
		if {[catch {sel_cell2 $newcellpath}]} {
		  puts "WARNING: cell $newcellpath disappeared!"
		}
	      } else {
		if {[llength [sel_what_l cells]] != 1} {
		  error "Cell $newcellpath not selected!"
		}
		# MAX BUG FIX: sel_what cells does not work if you used -dup_ok
		# and two instances have identical locations; it returns
		# one of the cells at random.  But the selection
		# is correct.  So fish the cell out of the selection.
		# BUG: DOESNT WORK:
		# struct max_cell c [sel_what cells]
		# BUG FIX: DOES WORK:
		struct max_cell junk [sel_what cells]
		if {${junk.id} != $newcellid} {
		  error "Cell $newcellid (path=$newcellpath) did not select, got ${junk.id} instead (THIS IS A MAX BUG - BEING FIXED)"
		}

		:delete

		if {![catch sel_cell $newcellid]} {
		  error "Cell $newcellid already exists!!!"
		}
		set result [db_instance -dup_ok -id $newcellid -orientation $ori $newtype $cx $cy]
		if {$result != $newcellid} {
		  error "db_instance failed: result=$result newcellid=$newcellid path=$newcellpath"
		}
	      }
	    }

	  } else {
	    # The cx,cy is where the cell origin will be.
	    db_instance -id $newcellid -orientation $ori $newtype $cx $cy
	  }

	  incr cell_count
	  if {[expr $cell_count % 1000] == 0} {
	    puts "... $cell_count ..."
	  }
	}

	if {$_FPLAN_READ_DEF(merge)} {
	  if {$MAX_SEL_BUG_WORK_AROUND} {
	    foreach thingy $merge_cells {
	      setl {newcellid newtype cx cy ori} $thingy
	      db_instance -id $newcellid -orientation $ori $newtype $cx $cy
	    }
	  } else {
	      lappend merge_cells [list $newcellid $newtype $cx $cy $ori]
	    # We have been placing instances with -dup_ok.
	    # We are supposed to make sure there are no dups now by doing this:
	    # Select only cells:
	    eval sel_area -no_poly -no_tiles -no_wp -no_labels [lay_bbox]
	    sel_move 0 0
	    # code goes here...
	    sel_clear
	  }
	}

	db_notify

      }

      PINS {
	puts "read_def: parsing [lindex $line 1] $keyword"
	:load $top_cell
	# TODO: Need to add merge pins
	while {[gets $fd line] >= 0} {
	  if {[string trim $line] == ""} {continue}
	  if {[string first "END" $line] == 0} {
	    # we're done
	    break
	  }

	  if {$_FPLAN_READ_DEF(pins) == 0} {continue}

	  set line [_fplan_read_def_line $fd $line]
	  set words [split $line " "]

	  if {[lindex $words 0] != "-"} {
	    # not a component
	    msg "read def: warning(2): unrecognized line: $line\n"
	    continue
	  }

	  incr pin_count

	  set pinName [lindex $words 1]
	  set layer space
	  set iotype ""
	  set pt_x 0
	  set pt_y 0
	  set place ""
	  # Subtract one to ignore the trailing ";"
	  set len [expr [llength $words] - 1]
	  set i 2
	  while {$i < $len} {
	    if {[lindex $words $i] != "+"} {
	      msg "read def: warning(i=$i): unrecognized line: $line\n"
	      break
	    }
	    switch [lindex $words [expr $i + 1]] {
	      "NET" {
		set netName [lindex $words [expr $i + 2]]
		incr i 3
	      }
	      "SPECIAL" {
		# Ignore it
		incr i 2
	      }
	      "DIRECTION" {
		set iotype [string tolower [lindex $words [expr $i + 2]]]
		incr i 3
	      }
	      "USE" {
		# Ignore it
		incr i 3
	      }
	      "LAYER" {
		set layer [string tolower [lindex $words [expr $i + 2]]]
		incr i 11
	      }
	      "COVER" -
	      "PLACED" -
	      "FIXED" {
		set place [lindex $words [expr $i + 1]]
		set pt_x [expr [lindex $words [expr $i + 3]] / 1000.0]
		set pt_y [expr [lindex $words [expr $i + 4]] / 1000.0]
		incr i 7
	      }
	    }
	  }

	  if {$iotype == ""} {
	    db_label $layer $pinName $pt_x $pt_y
	  } else {
	    db_label -kind $iotype $layer $pinName $pt_x $pt_y
	  }

	  if {$layer != "space"} {
	    fplan_db_pin -cell $top_cell setprop $pinName preflayer $layer
	  }
	  if {$place != ""} {
	    fplan_db_pin -cell $top_cell setprop $pinName place [string tolower $place]
	  }
	}
      }

      NETS - SPECIALNETS {
	puts "read_def: parsing [lindex $line 0] $keyword"
	:load $top_cell

	# For now, just skip nets.
	while {[gets $fd line] >= 0} {
	  if {[string trim $line] == ""} {continue}
	  if {[string first "END" $line] == 0} {
	    # we're done
	    break
	  }
	}
	continue

	# parses something of the form

	# - Cin
	# ( addimm$11$__ripple_start_H_1$1$__MUX2D  sel )
	# ( addimm$11$__ripple_start_H_2__MUX2D  sel )
	# ( exu_job_AU_decode__AOI21B  out )
	# + ROUTED
	#     M2  (  361500   485500 )  (  362500   485500 )
	# NEW  M2  (  362500   482500 )  (  362500   485500 )
	# NEW  M2  (  362500   482500 )  VIA23
	# NEW  M2  (  425500   482500 )  VIA23
	# + USE  SIGNAL
	# ;

	# now read the nets
	while {[gets $fd line] >= 0} {
	  if {[string trim $line] == ""} {continue}
	  if {[lindex $line 0] == "END"} {
	    # we're done
	    break
	  }

	  set netname [lindex $line 1]

	  # Skip lines until 'FIXED' or 'ROUTED' is found.
	  # We hope there is no ROUTED or FIXED in the compeonts names....
	  
	  set skipping 1
	  while {$skipping} {
	      if {[string last \; $line] != -1} {
		  set skipping 0
	      }
	      if {[string last ROUTED $line] != -1} {
		  set skipping 0
	      }
	      if {[string last FIXED $line] != -1} {
		  set skipping 0
	      }

	      if {$skipping} {
		  if {[gets $fd line] < 0} {
		      return "Aborting, unexpected end of file.  Missing ;"
		  }
	      }
	  }

	  # a line must end with a semicolon, otherwise get the next line
	  while {[string last \; $line] == -1} {
	    if {[gets $fd next_line] >= 0} {
	      set line "$line $next_line"
		incr line_num
		if {[expr $line_num % 1000] == 0} {
		    puts "... net line $line_num ..."
		}
	    } else {
	      return "Aborting, unexpected end of file.  Missing ;"
	    }
	  }
	  
	  # get just the routing section
	  set pos [string last ROUTED $line]
	  if {$pos == -1} {
	      set pos [string last FIXED $line]
	  }

	  if {$pos == -1} {
	    puts "Net $netname is not routed"
	    continue
	  }

	  incr net_count
	  set line [string range $line [expr $pos + 6] end]

	  # strip off + to end or ;
	  if {[set pos [string first + $line]] != -1} {
	    set line [string range $line 0 $pos]
	  }

	  set line [string trimright $line {;+}]

	  # puts "NET/SPECIALNET routing: $line"

	  while {1} {

	    set pos [string first NEW $line]
	    if {$pos == -1} {
	      if {$line == ""} {
		break
	      }
	      # last wire/via
	      set pos [expr [string length $line] + 1]
	      set wire $line

	      # puts "Last wire"

	    } else {
		set wire [string trim [string range $line 0 [expr $pos - 1]]]
	    }

	    # look for an optional wire width
	    set ppos [string first \( $wire]

	    setl {layer width} [string range $wire 0 [expr $ppos - 1]]

	    if {$width == ""} {
		# use default wire width
		set ww2 [uusnap [techinfo width $layer]/2.0]

		# puts "default width wire: $wire"
	    } else {
		# there is a wire width
		set ww2 [uusnap [expr $width / ( $grid * 2.0 )]]

		# puts "wire with width $ww2: $wire"
	    }
	    set wire [string range $wire $ppos end]

	    # puts "wire after stripping layername: $wire"

	    regsub -all {\(|\)} $wire " " wire
	    setl {x1 y1 x2 y2} $wire

	    if {$x1 == "*"} {
		set x1 $lastx
	    }
	    set lastx $x1

	    if {$y1 == "*"} {
		set y1 $lasty
	    } 
	    set lasty $y1

	    if {$x2 == "*"} {
		set x2 $lastx
	    }
	    set lastx $x2

	    if {$y2 == "*"} {
		set y2 $lasty
	    } 
	    set lasty $y2

	    # puts "parsed points: x1=$x1 y1=$y1 x2=$x2 y2=$y2"

	    if {$y2 == ""} {
	      # via

	      set x1 [expr $x1 / $grid] 
	      set y1 [expr $y1 / $grid]

	      place_gcell via "$x1 $y1" "-type $x2"
	      #foreach via $VIAS($x2) {
		#setl {layer xx1 yy1 xx2 yy2} $via
		#lay_box [expr $x1 + $xx1] [expr $y1 + $yy1] \
		    #[expr $x1 + $xx2] [expr $y1 + $yy2]
		#:paint $layer
	      #}

	    } else {

	      if {$x1 == $x2} {
		set xx1 [expr $x1 / $grid - $ww2] 
		set yy1 [expr $y1 / $grid]
		set xx2 [expr $x2 / $grid + $ww2] 
		set yy2 [expr $y2 / $grid]

	      } elseif {$y1 == $y2} {
		set xx1 [expr $x1 / $grid] 
		set yy1 [expr $y1 / $grid - $ww2]
		set xx2 [expr $x2 / $grid] 
		set yy2 [expr $y2 / $grid + $ww2]

	      } else {
		set xx1 [expr $x1 / $grid] 
		set yy1 [expr $y1 / $grid]
		set xx2 [expr $x2 / $grid] 
		set yy2 [expr $y2 / $grid]

	      }
	      lay_box $xx1 $yy1 $xx2 $yy2
	      :paint [techinfo layer $layer]

	      if {$netname != ""} {
		setl {lx1 ly1} [center_coords $xx1 $yy1 $xx2 $yy2]
		lay_box $lx1 $ly1 $lx1 $ly1
		:label $netname c [techinfo layer $layer]

		set netname ""
	      }
	    }

	    set line [string range $line [expr $pos + 3] end]
	  }
	}
      }
    }
  }
}




# Makes a boundary-only max cell

proc fplan_make_cell_from_lef {cell} -desc {
  Make a cell with a prb layer only from the LEF size.
} -doc {
  jdj uses this.  Dont change the name.
} {

  global CELL DEFAULT_HEIGHT DEFAULT_WIDTH
  global LEF_SITES USE_DEFAULTS

  setl {type xsize ysize} [fplan_cell_info -get $cell]

  if {$xsize == ""} {
    if {[use_first USE_DEFAULTS] != 1} {
      # ask user for lef file
      max_error -buffer "WARNING: no LEF size for cell $cell - using a default size."
    }
    set xsize $DEFAULT_WIDTH
    set ysize $DEFAULT_HEIGHT
    # If we have a better height available, use that instead:
    if {[info exists LEF_SITES(CORE1)]} {
      setl {xtmp ytmp} [get_assoc SIZE $LEF_SITES(CORE1)]
      if {$ytmp != ""} {set ysize $ytmp}
    }
  }

  # make a new cell
  db_cell_new $cell $cell$CELL(default_suffix) 

  # add prb layer
  db_paint -cell $cell [techinfo layer prb] 0 0 $xsize $ysize

#  puts "Made cell $cell."
}


# create a new cell if there isn't one in max of this name

proc _fplan_goto_cell {cell_name} {

  global CELL

  if {![cell_in_memory $cell_name]} {
    # create the new cell
    puts stderr "Creating cell $cell_name"
    db_cell_new $cell_name $cell_name$CELL(default_suffix)
    # goto the cell
    cell_load $cell_name

  } else {
    # goto the cell
    cell_load $cell_name

    # query user before stomping on existing def file
    set message "The cell \"$cell_name\" already exists.  Erase?"
    set choice [tk_dialog .dialog "Import DEF" $message {} 0 \
		    Yes Cancel]
    if { $choice != 0 } { 
      # user hit the cancel button
      return 0
    }

    # toast the contents of the cell
    eval sel_area [lay_bbox]
    :delete
  }

  return 1
}



proc fplan_write_def {{-cells 1} {-pins 1} {-nets 0} \
	{-no_unplaced_pins 0} {-power_names "vdd gnd"} \
	{-net_trunk 0} {-lef_site "*"} \
	{-ref "prb"} {-track_layers "*"} {-blockages 0} {-fast 0} \
	{-via_names "*VIA*"} {-via_comp_names ""} \
	{cell ""} {filename ""}} -type local -desc {
  Writes specified <cell> in DEF format to filename (default <cell>.def)
} -doc {
  -cells - controls cells output in COMPONENTS section:
    if 0, no COMPONETS section;
    if 1, cells in current cell are written;
    if 2, cells in current cell and all immediate subcells are written;
    if >= 3, all hierchical cells are written.
  -ref - reference layer for sizes of stdcells;
	 can be "_bbox_", "_lef_", or a layer name (usually "prb").
  -pins - output the PINS section if 1.
  -nets - output preroutes in the specialnets section if 1.
  -no_unplaced_pins - if pin has property "place=unplaced", dont put it in the PINS section.
  -power_names - defaults to "vdd gnd"
  -net_trunk - if 1, add the TRUNK property to nets (used for preroutes).
  -lef_site - SITE name for ROWS output to def file for stdcell placement,
      defaults to "CORE1".   If "", no ROWS is output.
  -track_layers - list of metal layers for which TRACKs will be generated.
      If "", no TRACKS will be output.
  -blockages - add blockage layers for non-leaf cells.
  -fast - if 1, write nets using faster algorithm, specifically, does not delete
      vias after sel_net to find nets for the nets section.  Two side-effects
      are that it will not warn about unconnected vias, and if there are two
      nets shorted by a via, things will get confused.  Probably the paint
      comes out under both net names.  Your results may vary.
  -via_names - a list of patterns of via type names that will be output in the NET section.
    Gcell vias are always placed in the NETS section.
  -via_comp_names - a list of patterns of via type names that over-rides -via_names,
    so these vias will be output as components.
} {
  global FPLAN _FPLAN_WRITE_DEF

  if {$cell == ""} {
    # Show interactive menu.  Init options to defaults on first pass.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      use_init _FPLAN_WRITE_DEF($option) [set $option]
    }
  } {
    # Non-interactive.  Set _FPLAN_WRITE_DEF from command line options.
    foreach thingy $__proc_options {
      set option [lindex $thingy 0]
      set _FPLAN_WRITE_DEF($option) [set $option]
    }
  }

  # Special cases.
  if {$_FPLAN_WRITE_DEF(lef_site) == "*"} {
    set _FPLAN_WRITE_DEF(lef_site) [use_first FPLAN(lef_site) 'CORE1]
  }
  if {$_FPLAN_WRITE_DEF(track_layers) == "*"} {
    set _FPLAN_WRITE_DEF(track_layers) \
	[use_first FPLAN(track_layers) '[techinfo layers metal]]
  }


  if {$cell == ""} {
    #set cell_list [cell_process_multiple -selection -title "Write .def file for cells:"]
    #foreach cell $cell_list { fplan_write_def $cell }

    set cell [lay_editcell]
    if {[lay_editcell] != [lay_rootcell]} {
      msg "warning: you are in edit-in-place mode\n"
    }

    set filename "${cell}.def"

    set prop_list ""
    lappend prop_list [list filename filename -entry]
    lappend prop_list [list "write components" _FPLAN_WRITE_DEF(cells) \
       -enum {none "current cell" "2-levels" "hierarchy"}]
    lappend prop_list [list "component reference layer" _FPLAN_WRITE_DEF(ref) \
      -radio {prb {cell bbox} {LEF file}} -values {prb _bbox_ _lef_}]
    lappend prop_list [list "write pins" _FPLAN_WRITE_DEF(pins) -binary]
    lappend prop_list [list "ignore (dont write) unplaced pins" _FPLAN_WRITE_DEF(no_unplaced_pins) -binary]
    lappend prop_list [list "write nets (preroutes only)" _FPLAN_WRITE_DEF(nets) -binary \
      -help {metal layers with labels are written to the SPECIALNETS section. \
      A warning is printed for unlabled metal, shorted labels, or unconnected labels}]
    lappend prop_list [list "add TRUNK prop to nets" _FPLAN_WRITE_DEF(net_trunk) -binary \
      -help {This prop makes silicon ensemble use the nets as preroutes}]
    lappend prop_list [list "write cell blockages" _FPLAN_WRITE_DEF(blockages) -binary]
    lappend prop_list [list "write ROWS using lef SITE name (null to diable)" _FPLAN_WRITE_DEF(lef_site) -entry]
    lappend prop_list [list "write TRACKS for layers (null to disable)" _FPLAN_WRITE_DEF(track_layers) -entry]

    #lappend prop_list [list "write power,gnd pins" _FPLAN_WRITE_DEF(power_pins) -binary]
    #lappend prop_list [list "power net names" _FPLAN_WRITE_DEF(power_names) -entry]

    lappend prop_list [list "via cell names to write to NET section" _FPLAN_WRITE_DEF(via_names) -entry]
    lappend prop_list [list "via cell names to write to COMPONENTS section" _FPLAN_WRITE_DEF(via_comp_names) -entry]
    set title "Write Def:"

    if {[prop_menu2 -title $title $prop_list] == 0} {
      return ;# cancelled
    }
  }

  if {$filename == ""} {
    set filename "${cell}.def"
  }

  set subcells [db_search_l cells -cell $cell -limit 1]
  if {[llength $subcells] == 0} {
    msg "write def: warning: No subcells found!\n"
  }


  if {0} {
    # This is NOT necessarily the same as db_search labels.
    # Only pins in the data-base are represented.
    set pin_list [fplan_db_pin -cell $cell list]

    # Lets do a little error checking:  Look for max text labels not in the data-base.
    # Could happen if user adds a pin by hand.  Will happen for vdd/gnd, too.
    set missing_pins ""
    foreach pin $pin_list {
      set pin_hash($pin) 1
    }
    foreach lab_info [db_search_l labels -non_hier -cell $cell] {
      struct max_label l $lab_info
      if {${l.kind} == "comment"} {continue}
      if {${l.kind} == "local"} {continue}
      if {${l.kind} == "hidden"} {continue}
      if {![info exists pin_hash(${l.text})]} {
	lappend missing_pins ${l.text}
      }
    }


    if {$missing_pins != ""} {
      prop_dialog "warning: the following max text labels in $cell are not in the\
      floorplan pin data-base;\
      will write pins to DEF file based on max text labels, but\
      some information (eg, orientation) will be missing:\n\
      $missing_pins"
    }
  }

  edit_push_direct $cell

  set fd [open $filename "w"]
  msg "writing DEF to file: $filename\n"

  unwind_catch {

    _fplan_write_def_int2 $cell $fd
  
  } always {
    close $fd

    edit_pop_direct
  }
}

proc _fplan_write_def_internal {args} -desc {
  deprecated, but jdj may be using it.
} {
  eval fplan_write_def $args
}


proc _fplan_expand_hier2 {cell path levels} -desc {
  part of fplan_expand_hier
} {
  if {$levels == 0} {return}

  foreach cell_info [db_search_l cells -no_fets -no_vias -cell $cell] {
    set def [cellinfo_def $cell_info]
    set type [lindex [fplan_cell_info -get $def] 0]
    switch $type {
      "lef" -
      "undef" {
	# Do not expand lef cells.
	# Undef cells had no verilog hierarchy under them - ignore them too.
	continue
      }
    }

    # Ta da!  Found a hierarchical cell or group.
    set id [cellinfo_id $cell_info]

    sel_cell2 $path$id
    lay_internals
    if {[string match {#GROUP*} $def]} {
      # Groups dont count as a level of hierarchy.
      _fplan_expand_hier2 $def [expr {$path == "" ? "$path" : "$path/"}]${id}/ $levels
    } else {
      _fplan_expand_hier2 $def [expr {$path == "" ? "$path" : "$path/"}]${id}/ [expr $levels-1]
    }
  }
}


proc _fplan_expand_hier {levels} -desc {
  Expand internals of all hierarhically contained cells, excepting LEF cells, fets and vias.
} -doc {
  Note that currently gcell fets/vias are always expanded.
} {
  eval lay_box [lay_bbox]
  lay_internals -hide -area
  _fplan_expand_hier2 [lay_editcell] "" $levels
}


proc _fplan_def_paint2rect {x1 y1 x2 y2} -desc {
  Return a DEF description of a max paint rectangle.
} {
    set px1 [expr int(round($x1 * 1000.0))]
    set px2 [expr int(round($x2 * 1000.0))]
    set py1 [expr int(round($y1 * 1000.0))]
    set py2 [expr int(round($y2 * 1000.0))]
    # The vias may be rotated/flipped, so the coords are not
    # guaranteed canonical, so fix it:
    if {$px1 > $px2} {
      set tmp $px2
      set px2 $px1
      set px1 $tmp
    }
    if {$py1 > $py2} {
      set tmp $py2
      set py2 $py1
      set py1 $tmp
    }

    set xlen [expr $px2 - $px1]
    set ylen [expr $py2 - $py1]

    # If one of the dimensions is odd, use the other as the width.
    # Otherwise, use the narrower dimension as the wdith (for no good reason.)
    set dir [expr {$xlen > $ylen}]
    if {$xlen%2==1} {
      # If odd in both directions, leave dir the narrowest,
      # otherwise, set dir to use xlen as the width.
      if {$ylen%2==0} {
	set dir 1
      }
    } elseif {$ylen%2==1} {
      set dir 0
    }

    if {$dir} {
      set width $ylen
      # The int is probably not be necessary here: in tcl div of int/int yields int.
      set ymid [expr int(($py1+$py2+1)/2)]
      append spec "( $px1 $ymid ) ( $px2 * )"
    } else {
      set width $xlen
      set xmid [expr int(($px1+$px2+1)/2)]
      append spec "( $xmid $py1 ) ( * $py2 )"
    }

    if {$width%2==1} {
      # This happens if the rectangle is odd in both directions.
      # We rounded the midpoint up so that when we incr width, it will be correct.
      msg "Warning: odd size rectangle at $x1 $y1 $x2 $y2 rounded up 0.001 micron\n"
      incr width
    }
    return "$width $spec"
}

proc _fplan_write_def_int2 {cell fd} {
  global FPLAN _FPLAN_WRITE_DEF

  set starttime [clock seconds]

  puts $fd "DESIGN $cell ;"
  puts $fd "UNITS DISTANCE MICRONS 1000 ;"
  puts $fd "HISTORY Created by max floorplanner [clock format [clock seconds]] ;"
  # THIS IS WRONG:  The diearea must come from the prb layer.
  # setl {x1 y1 x2 y2} [eval uusnap -grid $grid [db_bbox]]
  setl {x1 y1 x2 y2} [fplan_bbox -grid mask -cell [lay_editcell]]
  set x1 [expr round($x1 * 1000)]
  set y1 [expr round($y1 * 1000)]
  set x2 [expr round($x2 * 1000)]
  set y2 [expr round($y2 * 1000)]
  puts $fd "DIEAREA ( [format "%.0f %.0f" $x1 $y1] ) ( [format "%.0f %.0f" $x2 $y2] ) ;"

  # Write out the ROWS
  set lef_site $_FPLAN_WRITE_DEF(lef_site)
  if {$lef_site != ""} {
    global LEF_SITES
    if {![info exists LEF_SITES($lef_site)]} {
      max_error -buffer "write_def: error: No lef site found for site $lef_site, so no ROW info written to def file"
    } else {
      setl {sizeX sizeY} [get_assoc SIZE $LEF_SITES($lef_site)]
      set spaceX [expr int(round(1000.0 * $sizeX))]
      set spaceY [expr int(round(1000.0 * $sizeY))]
      # We assume that rows are oriented horizontally.
      puts $fd ""
      # Figure out how many rows fit in the diearea.
      set tx1 [expr int(ceil($x1/$spaceX)*$spaceX)]
      set tx2 [expr int(floor($x2/$spaceX)*$spaceX)]
      set ty1 [expr int(ceil($y1/$spaceY)*$spaceY)]
      set ty2 [expr int(floor($y2/$spaceY)*$spaceY)]
      # Do not let the row sites go outside the diearea.
      while {$tx1 < $x1} {set tx1 [expr $tx1 + $spaceX]}
      while {$tx2 > $x2 - $spaceX} {set tx2 [expr $tx2 - $spaceX]}
      while {$ty1 < $y1} {set ty1 [expr $ty1 + $spaceY]}
      while {$ty2 > $y2 - $spaceY} {set ty2 [expr $ty2 - $spaceY]}

      set numX [expr int(($tx2 - $tx1) / $spaceX) + 1]
      set numY [expr int(($ty2 - $ty1) / $spaceY) + 1]
      set whereY $y1
      for {set i 1} {$i <= $numY} {incr i} {
	set row_ori [expr {$i%2 ? "N" : "FS"}]
	puts $fd "ROW ROW$i $lef_site [format "%.0f %.0f" $x1 $whereY] $row_ori DO $numX BY 1 STEP $spaceX $spaceY ;"
	set whereY [expr $whereY + $spaceY]
      }
    }
  }

  # Write out the tracks
  if {$_FPLAN_WRITE_DEF(track_layers) != ""} {
    puts $fd ""
    msg "write_def: writing tracks....  Elapsed [expr [clock seconds]-$starttime]\n"
  }
  foreach tlayer $_FPLAN_WRITE_DEF(track_layers) {

    # 6/12/01: We are going to lay TRACKS in both direction regardless
    # of the routing layer direction, because jdj says we do some wrong way wiring.
    # But note: The memory use of the router is related to the number of tracks,
    # so only writing out the ones you need would save memory space.
    #set wire_dir [use_first WIRE($tlayer,direction)]
    #if {$wire_dir == ""} {
    #  max_error -buffer "No direction specified (in LEF) for layer $tlayer.  No TRACK data written."
    #  continue
    #}

    setl {wire_snapx wire_snapy wire_offx wire_offy} [wire_get_grid $tlayer]
    if {$wire_snapy == ""} {set wire_snapy $wire_snapx}
    if {$wire_snapx == ""} {
      max_error -buffer "write_def: warning: No pitch specified for layer $tlayer, no TRACKS written"
      continue
    }
    if {$wire_offx == ""} {set wire_offx 0}
    if {$wire_offy == ""} {set wire_offy $wire_offx}

    # Convert to DEF scale
    set wire_snapx [expr int(round($wire_snapx * 1000.0))]
    set wire_snapy [expr int(round($wire_snapy * 1000.0))]
    set wire_offx [expr int(round($wire_offx * 1000.0))]
    set wire_offy [expr int(round($wire_offy * 1000.0))]

    # Be careful the wire does not go outside the diearea, because the
    # coordinates are the center of the wire.
    set boundx1 [expr int(round(1.0*$x1/$wire_snapx) * $wire_snapx) + $wire_offx]
    while {$boundx1 - $wire_snapx/2 < $x1} {
      set boundx1 [expr $boundx1 + $wire_snapx]
    }
    set boundy1 [expr int(round($y1/$wire_snapy) * $wire_snapy) + $wire_offy]
    while {$boundy1 - $wire_snapy/2 < $y1} {
      set boundy1 [expr $boundy1 + $wire_snapy]
    }

    set boundx2 [expr int(round($x2/$wire_snapx) * $wire_snapx) + $wire_offx]
    while {$boundx2 + $wire_snapx/2 > $x2} {
      set boundx2 [expr $boundx2 - $wire_snapx]
    }
    set boundy2 [expr int(round($y2/$wire_snapy) * $wire_snapy) + $wire_offy]
    while {$boundy2 + $wire_snapy/2 > $y2} {
      set boundy2 [expr $boundy2 - $wire_snapy]
    }

    set numXTracks [expr int(round(($boundx2-$boundx1)/$wire_snapx)) + 1]
    puts $fd "TRACKS X $boundx1 DO $numXTracks STEP $wire_snapx LAYER [string toupper $tlayer] ;"
    set numYTracks [expr int(round(($boundy2-$boundy1)/$wire_snapy)) + 1]
    puts $fd "TRACKS Y $boundy1 DO $numYTracks STEP $wire_snapy LAYER [string toupper $tlayer] ;"

  }

  msg "write_def: finding subcells...  Elapsed [expr [clock seconds]-$starttime]\n"
  if {$_FPLAN_WRITE_DEF(cells) > 1} {
    set num_levels $_FPLAN_WRITE_DEF(cells)
    if {$num_levels >= 3} {set num_levels 999999}
    _fplan_expand_hier $num_levels
    set subcells [db_search_l cells -any_cell]
  } else {
    set subcells [db_search_l cells]
  }


  # Preprocess vias: we are going to put single-cut gcell vias into the
  # SPECIALNETS section of the def file.  Larger vias will be output as COMPONENTS.
  # We will also put normal via cells out as COMPONENTS.
  # So preprocess the subcells:
  # Print a warning if there is a gcell via with more than one cut.
  # Output the actual geometry of gcell vias that are encountered.
  set via_layers [techinfo layers via]
  set metal_layers [techinfo layers metal]
  set wire_layers [techinfo wire_layers]

  # Figure out which cells go in the components section
  # and which go in the nets section.
  # Set via_hash($celldef) to 1 if it goes in the NETS section, else 0.

  foreach def [db_kids] {
    if {[string match "#via*" $def]} {
      # Gcell vias must always go in the NETS section, because
      # their geometry has to go in the DEF file, since they
      # dont exist as separate cells.
      set via_hash($def) 1
    } else {
      set via_hash($def) 0
      foreach pat $_FPLAN_WRITE_DEF(via_names) {
	if {[string match $pat $def]} {
	  set via_hash($def) 1
	  break
	}
      }
      foreach pat $_FPLAN_WRITE_DEF(via_comp_names) {
	if {[string match $pat $def]} {
	  set via_hash($def) 0
	  break
	}
      }
    }
  }

  if {$_FPLAN_WRITE_DEF(nets)} {
    msg "write_def: preprocessing vias...  Elapsed [expr [clock seconds]-$starttime]\n"

    # Output the VIA section of the def file.

    # Make via_names a list of all via cell def names.
    set via_names ""
    foreach thing [array names via_hash] {
      if {$via_hash($thing)} {lappend via_names $thing}
    }

    # Pass 1: Remember names of non-gcell vias.
    foreach viacell $via_names {
      # Is it a normal cell?  A gcell def name begins with "#"
      if {[string first "#" $viacell] != 0} {
	set via_max2def($viacell) $viacell
	set via_names_used($viacell) 1
      }
    }


    # Pass 2: Figure out names for all the gcell vias.
    foreach viacell $via_names {
      # Is it a gcell?  A gcell def name begins with "#"
      if {[string first "#" $viacell] != 0} {
	continue
      }
      set cut_paintballs [db_search_l paint -cell $viacell [join $via_layers ,]]
      struct max_paint p [lindex $cut_paintballs 0]
      # Try to make up a reasonable via name by looking at the cut layer name,
      # and the number of cuts.
      set lay [string tolower ${p.layer}]
      if {$lay == "ct" || $lay == "contact"} {
	set vianame VIA_GCELL_CT
      } elseif {[regexp {^v[0-9]+$} $lay]} {
	set vianame VIA_GCELL_[string range $lay 1 end]
      } elseif {[regexp {^via[0-9]+$} $lay]} {
	set vianame VIA_GCELL_[string range $lay 3 end]
      } else {
	set vianame "VIA_GCELL_UNKNOWN"
      }

      # Append number of cuts.
      if {[llength $cut_paintballs] > 1} {
	append $vianame "_CUT[llength $cut_paintballs]"
      }

      # Make sure the name is unique.  There could be multiple vias
      # with the same cut layer, but with differing metal overlaps.
      set uniq_vianame $vianame
      set n 1
      while {[info exists via_names_used($uniq_vianame)]} {
	set uniq_vianame $vianame$n
	incr n
      }

      set via_names_used($uniq_vianame) 1
      set via_max2def($viacell) $uniq_vianame
    }


    # Pass 3: Write out the via names and layers to def.
    # The origin may not be the center, as long as the use matches the def.
    puts $fd ""
    puts $fd "VIAS [llength $via_names]"
    foreach viacell $via_names {
      # The SpecialNets section does not permit the via to be rotated,
      # so we are currently assuming the vias are 4-way symmetric.
      # Mark these in the via_unsymmetric hash table, and later print a warning
      # if these are used rotated!
      # TODO: Could add a rotated version of each via to allow rotation.
      setl {bx1 by1 bx2 by2} [db_bbox -cell $viacell]
      if {[approx [expr $by2-$by1] != [expr $bx2-$bx1]]} {
	set via_unsymmetric($viacell) 1
      }

      puts -nonewline $fd "- $via_max2def($viacell)"
      # jdj thinks that the cadence def parser may barf if the first RECT is not
      # on the same line as the VIA name.
      #
      # TODO: cadence wroute will not accept these vias if they have more than three rectangles.
      # Therefore, we should probably turn any such via into a cell.
      #
      set paintballs [db_search_l paint -cell $viacell [join [dbt_layers] ,]]
      for {set i 0} {$i < [llength $paintballs]} {incr i} {
	struct max_paint p [lindex $paintballs $i]
	# Only put out real layers, not prb.
	if {[string tolower ${p.layer}] == "prb"} {continue}

	# Error checK: should be only metal, poly, pwc, nwc, ct, etc., in here.
	if {[lsearch -exact $wire_layers ${p.layer}] == -1 && \
	    [lsearch -exact $via_layers ${p.layer}] == -1} {
	  max_error -buffer "unrecognized layer ${p.layer} in via $viacell"
	}

	if {$i != 0} {puts -nonewline $fd "\n"}
	puts -nonewline $fd " + RECT ${p.layer} ( [expr round(${p.x1} * 1000)] [expr round(${p.y1} * 1000)] ) \
	      ( [expr round(${p.x2} * 1000)] [expr round(${p.y2} * 1000)] )"
	
	# Save one of the metal layers to output in def statement.
	if {[lsearch $metal_layers ${p.layer}] >= 0} {
	  set via_max2layer1($viacell) [string toupper ${p.layer}]
	}
      }
      puts $fd " ;"
    }
    puts $fd "END VIAS"
  }



  puts $fd ""
  if {$_FPLAN_WRITE_DEF(cells)} {
    msg "write_def: writing [llength $subcells] COMPONENTS... Elapsed [expr [clock seconds]-$starttime]\n"
    puts $fd "COMPONENTS [llength $subcells] ;"

    foreach cell_info $subcells {
      struct max_cell c $cell_info

      if {$via_hash([cellinfo_def $cell_info])} {continue}

      setl {type xsize ysize} [fplan_cell_info -get ${c.def}]

      # If we are doing any hierarchy at all, output only lef cells.
      # This may not give enough control: If outputting 2 levels, you might
      # conceivably want the non-lef cells at the second level.
      # If outputing one level, you still might want lef cells only.
      if {$_FPLAN_WRITE_DEF(cells) >= 2 && $type != "lef"} {continue}

      # Get the cell origin out of the cell transform.
      set ox [lindex ${c.transform} 2]
      set oy [lindex ${c.transform} 5]

      # Need to get the cell size to translate rotated cells properly.

      if {$_FPLAN_WRITE_DEF(ref) == "_bbox_"} {
	setl {cx1 cy1 cx2 cy2} [db_bbox -cell ${c.def}]
	set xsize [expr $cx2 - $cx1]
	set ysize [expr $cy2 - $cy1]
      } elseif {$_FPLAN_WRITE_DEF(ref) == "_lef_"} {
	if {$type != "lef"} {
	  max_error -buffer "WARNING: No LEF found for cell: ${c.def}"
	  set xsize 0
	  set ysize 0
	}
      } else {
	# Use boundary of specified layer as cell boundary.
	edit_push_direct ${c.def}
	eval sel_area -no_labels -no_poly -no_wp -layers $_FPLAN_WRITE_DEF(ref) [lay_bbox]
	setl {cx1 cy1 cx2 cy2} [db_bbox -cell __SELECT__]
	edit_pop_direct
	# If the box is really tiny, dont use it.
	if {[approx $cx1 == $cx2 0.01] || \
	    [approx $cy1 == $cy2 0.01] } {
	    max_error -buffer "warning: no prb layer on cell ${c.id}, using cell bbox as boundary"
	    setl {cx1 cy1 cx2 cy2} [db_bbox -cell ${c.def}]
	}
	set xsize [expr $cx2 - $cx1]
	set ysize [expr $cy2 - $cy1]
      }

      set orient [orientation ${c.transform}]
      switch $orient {
	"" {
	  set defori N
	  set defx [expr round($ox * 1000.0)]
	  set defy [expr round($oy * 1000.0)]
	}
	fx {
	  set defori FN
	  set defx [expr round(($ox - $xsize) * 1000.0)]
	  set defy [expr round($oy * 1000.0)]
	}
	fy {
	  set defori FS
	  set defx [expr round($ox * 1000.0)]
	  set defy [expr round(($oy - $ysize) * 1000.0)]
	} 
	r180 {
	  set defori S
	  set defx [expr round(($ox - $xsize) * 1000.0)]
	  set defy [expr round(($oy - $ysize) * 1000.0)]
	}
	r90 {
	  # rotate this
	  set defori E
	  set defx [expr round(($ox - 0) * 1000.0)]
	  set defy [expr round(($oy - $xsize) * 1000.0)]
	} 
	fy_r90 {
	  # rotate this
	  set defori FE
	  set defx [expr round(($ox - $ysize) * 1000.0)]
	  set defy [expr round(($oy - $xsize) * 1000.0)]
	} 
	fx_r90 {
	  # rotate this
	  set defori FW
	  set defx [expr round(($ox - 0) * 1000.0)]
	  set defy [expr round(($oy - 0) * 1000.0)]
	}
	r270 {
	  # rotate this
	  set defori W
	  set defx [expr round(($ox - $ysize) * 1000.0)]
	  set defy [expr round(($oy - 0) * 1000.0)]
	} 
	default {
	  max_error -buffer "warning: unrecognized max orientation on cell ${c.id}"
	  # Use a default.  This may be wrong.
	  set defori N
	  set defx [expr round($ox * 1000.0)]
	  set defy [expr round($oy * 1000.0)]
	}
      }

      set mod [fplan_db_cell module ${c.def}]
      if {$mod == ""} {
	# This happens if the cell was created some way other than
	# reading in verilog or LEF.
	set mod [fplan_unfix_name ${c.def}]
      }

      # Groups represent phantom hierarchy that does not correspond to verilog,
      # so remove them from the path.
      # This is a little scarey - what if the user has a level of hierarchy
      # called "GROUP"?
      regsub {^GROUP[0-9]+/} [cellinfo_path $cell_info] "" tmppath
      regsub {/GROUP[0-9]+/} $tmppath "/" tmppath
      set cellidpath $tmppath${c.id}
      set modi [fplan_unfix_name $cellidpath]

      # Use floating point to avoid an integer round off error 
      # on these gigantic numbers.
      puts $fd "- $modi $mod + PLACED ( [format "%.0f %.0f" $defx $defy] ) $defori ;"
    }
    puts $fd "END COMPONENTS"
  }

  if {$_FPLAN_WRITE_DEF(pins)} {
    fplan_db_cache -cell $cell
    set io_port_list [fplan_db_pin_list -usecache -cell $cell]

#set debugfd [open /homes/pat/work/log w]
#puts $debugfd "io_port_list:"
#foreach thing $io_port_list {
  #puts $debugfd $thing
#}
#close $debugfd

    if {$_FPLAN_WRITE_DEF(no_unplaced_pins)} {
      set new_io_port_list ""
      foreach port $io_port_list {
	set place [fplan_db_pin -cell $cell getprop $port place]
	if {$place == "unplaced"} {continue}
	lappend new_io_port_list $port
      }
      set io_port_list $new_io_port_list
    }

    puts $fd "\nPINS [llength $io_port_list] ;"
    msg "write_def: writing [llength $io_port_list] PINS...  Elapsed [expr [clock seconds]-$starttime]\n"
    set pin_cnt 0
    foreach port $io_port_list {

      setl {lx ly lkind curlayer} [fplan_db_pin2 -usecache -cell $cell  $port]
      # Note: the net name is always the same as the top-level port name.
      puts -nonewline $fd "- $port + NET $port"

      set place [fplan_db_pin -cell $cell getprop $port place]

      if {$place == "user"} {
	set place fixed
      }

      # TODO: defori might want to be based on the side the thing is on.
      set defori N

      switch $place {
	cover -
	placed -
	fixed {
	  puts $fd [format " + [string toupper $place] ( %.0f %.0f ) %s" \
	    [expr $lx * 1000.0] [expr $ly * 1000.0] \
	    $defori]
	}
	unplaced {
	  # It is unplaced.  Do not output placement.
	}
	default {
	  max_error -buffer "write_def: error: cell $cell port $port unrecognized place property: $place"
	}
      }

      
      if {$curlayer == "space" || $curlayer == ""} {
	# This is rrrrreeeaaaallllyyyy sssssllllloooowwww
	# But it wont happen if labels already have assigned layers.
	switch -- [fplan_db_pin getregion $port] {
	  top -
	  bottom {
	    set curlayer m$FPLAN(layer_default,vertical)
	  }
	  default {
	    set curlayer m$FPLAN(layer_default,horizontal)
	  }
	}
	max_error -buffer "warning: no layer given for port $port, using $curlayer"
	set pin_layer ""
      }

      # In DEF specify two points to give a physical geometry for the port.
      set w2 [expr [uusnap [expr [wire_info width $curlayer] / 2.0]] * 1000.0]
      set pin_layer [format "+ LAYER %s ( -%.0f -%.0f ) ( %.0f %.0f ) " \
	  [string toupper $curlayer] $w2 $w2 $w2 $w2]

      puts $fd "	${pin_layer}+ DIRECTION [string toupper $lkind] ;"
    }

    if {0} {
    # Now write out pins that did not appear in the pin data-base.
    foreach pin $missing_pins {
      struct max_label l [llindex [db_search_l labels -non_hier [util_unglob $pin]] 0]
      if {${l.text} == ""} {
	max_error -buffer "warning: can not find label: $pin"
      }
      puts $fd "- $pin + NET $pin"
      if {${l.kind} == "global"} {
	# Assume global labels are power
	puts $fd " + USE POWER"
      } else {
	puts $fd " + USE SIGNAL + DIRECTION [string toupper ${l.kind}]"
      }
      if {${l.layer} != "space" && ${l.layer} != ""} {
	# The two points give a physical geometry for the port.
	set w2 [expr [uusnap [expr [techinfo width ${l.layer}] / 2.0]] * 1000.0]
	puts $fd " + LAYER [string toupper ${l.layer}] ( -$w2 $w2 ) ( -$w2 $w2 )"
      }
      # We dont know the orientation.  Just use N
      puts $fd " + PLACED ( [expr ${l.x1} * 1000.0] [expr ${l.y1} * 1000.0] ) N ;"
    }
    }

    puts $fd "END PINS"
  }

  set blockage_cells ""
  if {$_FPLAN_WRITE_DEF(blockages)} {
    # We will write out a blockage over each hierarchical subcell.
    foreach cell_info $subcells {
      if {[fplan_cell_info -is_hier [fplan_fix_name [cellinfo_def $cell_info]]]} {
	struct max_cell c $cell_info
	# Only subcells of the top-level cell are blockages.
	if {[cellinfo_path $cell_info] == ""} {
	  lappend blockage_cells $cell_info
	}
      }
    }
  }

  set label_names ""
  if {$_FPLAN_WRITE_DEF(nets)} {
    msg "write_def: preprocessing nets...  Elapsed [expr [clock seconds]-$starttime]\n"

    # We will write out all labeled nets in the current cell.
    # These are the possible error conditions: 
    #  1. label not on metal
    #  2. metal w/o label.
    #  3. different labels on same metal.

    # Select all the metal paint in current cell.
    sel_clear ;# redundant
    set metal [techinfo layers metal]
    eval sel_area -no_labels -no_poly -no_wp -layers [join $metal ,] [lay_bbox]

    # Select vias, too.
    foreach cell_info $subcells {
      if {$via_hash([cellinfo_def $cell_info])} {
	sel_cell -more [cellinfo_id $cell_info]
      }
    }

    # Add all global, local and io labels.
    sel_labels -more -kind input
    sel_labels -more -kind output
    sel_labels -more -kind inout
    sel_labels -more -kind global
    sel_labels -more -kind local

    # Yank into tmp cell.
    set tmpcell __FPLAN_WRITE_DEF_TMP__
    catch {db_cell_new -internal -no_undo $tmpcell}
    catch {db_cell_clear $tmpcell}
    db_cell_copy -source __SELECT__ $tmpcell

    # Get all the labels, and hash them to find just the unique label names.
    set label_list [db_search_l labels -non_hier -cell $tmpcell]
    set label_names [label_list2names -uniq $label_list]
  }

  set nspecialnets [expr [llength $label_names] + [llength $blockage_cells]]

  if {$nspecialnets} {
    puts $fd "\nSPECIALNETS $nspecialnets ;"
    msg "write_def: writing [llength $label_names] (nets) + [llength $blockage_cells] (blockages) to SPECIALNETS...  Elapsed [expr [clock seconds]-$starttime]\n"
  }

  if {$_FPLAN_WRITE_DEF(nets)} {

    edit_push_direct $tmpcell

    foreach kind "input output inout global local" {
      set uncon_labels($kind) ""
    }

    # For each unique label name.
    foreach netname $label_names {
      sel_clear
      setl {found_labels unconnected_labels} [select_net_by_name $netname]

      # NOTE: select_net_by_name selects the paint in via gcells,
      # as well as the gcell itself.  You could use:
      # sel_what paint -edit_only to get just the paint in the editcell,
      # but that fractures vertical wire paint when it crosses the
      # via boundaries, so there was a little tiny
      # stub at the end of each vertical wire where it crossed the
      # via boundary.  Dont really want this in the def file.
      # Using sel_move has the desired effect of deselecting paint that
      # is not in the editcell, in particular, the paint that originally
      # belonged to the vias.
      msg_catch {sel_move 0 0} junk junk junk

      # Error checking:  Save up unconnected_labels for later printing.
      foreach lab_info $unconnected_labels {
	struct max_label l $lab_info
	lappend uncon_labels(${l.kind}) "${l.text} ${l.x1},${l.y1}"
      }

      if {$found_labels == ""} {
	# Error already printed because this was an unconnected_label.
	# However, we have to keep going to print just - netname,
	# with no attached paint, because we already counted this
	# net in specialnets count.
      }

      # Check for shorted labels.
      set found_label_names [label_list2names -uniq [sel_what_l labels]]
      if {[llength $found_label_names] > 1} {
	# Ooops
	max_error -buffer "warning: found shorted labels: $found_label_names"
      }

      # Output each paint rectangle to the def file in special net section.
      # We disregard the fact they are wires, and just output them as rectangles.
      # Note: unconnected labels are output as a net with no rectangles,
      # because we already counted in the total printed on the SPECIALNETS line.
      puts -nonewline $fd "- [fplan_unfix_name -label $netname]"
      if {$_FPLAN_WRITE_DEF(net_trunk)} {puts -nonewline $fd " +PATTERN TRUNK"}

      set cell_list [sel_what_l cells -edit_only junk]

      set paint_list [sel_what_l paint -edit_only junk]

      # Delete the selected paint and vias.
      # There is a bug in max that causes select_net_by_name to leave
      # multiple copies of identical labels in the selection, which
      # then causes delete to print an error.  So catch it.
      if {$_FPLAN_WRITE_DEF(fast)} {
	# Dont bother to delete the vias.  Its too slow.  Remove vias from the selection.
	:erase subcell
      }
      catch {:delete}

      set net_thing_cnt 0
      foreach paintball $paint_list {
	struct max_paint p $paintball
	set spec [_fplan_def_paint2rect ${p.x1} ${p.y1} ${p.x2} ${p.y2}]

	if {$net_thing_cnt == 0} {
	  puts -nonewline $fd "\n+ FIXED [string toupper ${p.layer}] $spec"
	} else {
	  puts -nonewline $fd "\n  NEW [string toupper ${p.layer}] $spec"
	}
	incr net_thing_cnt
      }

      # Add in the vias.  The only cells currently selected were selected
      # by select_net_by_name, so they better be vias.
      # TODO: Could print a warning if a selected cell does
      # not have "VIA" in the name somewhere.
      foreach cell_info $cell_list {
	struct max_cell c $cell_info
	if {[info exists via_max2def(${c.def})]} {

	  # OLD:
	  # We are finding the center of the via using the max bounding box for the cell,
	  # (which is buggy and may be incorrect.)
	  # setl {viax viay} [center_coords ${c.x1} ${c.y1} ${c.x2} ${c.y2}]


	  # Changed 7/12/01: Place the cell using its own origin, which was
	  # also used when specifying the layers in the via section.
	  # The specialnets section does not support rotation/flipping,
	  # so we need to reorient the cell so it is right way up.
	  # If the cell origin is at the center, none of this matters.
	  setl {viax viay} [cell_origin $cell_info]
	  setl {cx cy} [eval center_coords [db_bbox -cell ${c.def}]]

	  # Move the origin so the cell will be in the right place if it is oriented
	  # right-way up.  We are assuming 4-way symmetric, so rotations map
	  # to the same thing as corresponding flips.
	  set viaori [orientation [cellinfo_transform $cell_info]]
	  switch $viaori {
	    fx_r90 -
	    ""     { }

	    r270 -
	    fx     { set viax [expr $viax - 2.0 * $cx]}

	    r90 -
	    fy     { set viay [expr $viay - 2.0 * $cy]}

	    fy_r90 -
	    r180   {
	      set viax [expr $viax - 2.0 * $cx]
	      set viay [expr $viay - 2.0 * $cy]
	    }
	    default { error "logic error: unrecognized orientation cell $cell_info" }
	  }

	  # Print message if non-symmetric via is used rotated
	  switch $viaori {
	    fx_r90 -
	    fy_r90 -
	    r90 -
	    r270 {
	      if {[info exists via_unsymmetric(${c.def})]} {
		max_error -buffer "warning: Via $viacell is used rotated but is not 4-way symmetric!"
		# Only print the message once per via.
		unset via_unsymmetric(${c.def})
	      }
	    }
	  }

	  set viax [expr round(1000 * $viax)]
	  set viay [expr round(1000 * $viay)]
	  if {$net_thing_cnt == 0} {
	    puts -nonewline $fd "\n+ FIXED "
	  } else {
	    puts -nonewline $fd "\n  NEW "
	  }
	  incr net_thing_cnt
	  # We have to put out a width, but the width makes no sense.
	  # Silicon ensemble uses a 0 here, but nl_shell is not yet
	  # prepared to use a 0, so just put out 2.
	  puts -nonewline $fd [format "%s 2 ( %.0f %.0f ) %s" \
		$via_max2layer1(${c.def}) $viax $viay $via_max2def(${c.def})]
	  
	  # wroute does not use connect to vias, only to metal.  So add little
	  # pieces of metal above and below the via.
	  foreach paintball [db_search_l paint -cell ${c.def} [join $metal_layers ,]] {
	    struct max_paint p $paintball
	    # These can be rotated, so we need to renormalize the coords.
	    setl {x1 y1} [transform_coords ${c.transform} ${p.x1} ${p.y1}]
	    setl {x2 y2} [transform_coords ${c.transform} ${p.x2} ${p.y2}]
	    set spec [_fplan_def_paint2rect $x1 $y1 $x2 $y2]
	    puts -nonewline $fd "\n  NEW [string toupper ${p.layer}] $spec"
	  }
	}
      }

      puts $fd " ;"
    }

    # Report any labels that did not land on paint.
    set uncon_labels(i/o) [concat $uncon_labels(input) $uncon_labels(output) $uncon_labels(inout)]

    foreach type "global local i/o" {
      set len [llength $uncon_labels($type)]
      if {$len != 0} {
	setl {uncon_port_name uncon_port_location} [lindex $uncon_labels($type) 0]
	max_error -buffer "warning: found $len $type labels with no attached paint:\
	  first was: $uncon_port_name at $uncon_port_location"
      }
    }

    # If there is anything left in tmpcell, it is metal that was unlabeled.
    set paintball [lindex [db_search_l paint -limit 1] 0]
    if {$paintball != ""} {
      # Copy the unlabeled paint into a cell we will leave for the user to see.
      set newcell FPLAN_WRITE_DEF_TMP
      catch {db_cell_new $newcell}
      catch {db_cell_clear $newcell}
      db_cell_copy -source $tmpcell $newcell

      struct max_paint p $paintball
      #max_error -buffer "warning: unlabeled paint ignored, first rectangle at ${p.x1},${p.y1};  see cell $newcell; list follows:"
      max_error -buffer "warning: unlabeled paint ignored;  see cell $newcell; list printed to max log window"
      fplan_mini_extract $tmpcell
    }

    # If -fast was specified, we did not delete the vias, so we cant detect unconnected vias.
    if {!$_FPLAN_WRITE_DEF(fast)} {
      set cells [db_search_l cells]
      if {[llength $cells] != 0} {
	struct max_cell c [lindex $cells 0]
	max_error -buffer "warning: [llength $cells] unconnected vias ignored, first at ${c.x1},${c.y1}"
      }
    }

    edit_pop_direct
  }

  if {$_FPLAN_WRITE_DEF(blockages)} {
    puts -nonewline $fd "- BLOCKAGE_RESERVED"
    set block_cnt 0
    foreach cell_info $blockage_cells {
      struct max_cell c $cell_info
      setl {px1 py1 px2 py2} [fplan_bbox -cellid ${c.id}]
      set px1 [expr int(round($px1 * 1000.0))]
      set px2 [expr int(round($px2 * 1000.0))]
      set py1 [expr int(round($py1 * 1000.0))]
      set py2 [expr int(round($py2 * 1000.0))]

      set xlen [expr $px2 - $px1]
      set ylen [expr $py2 - $py1]
      if {$xlen > $ylen} {
	set width $ylen
	set ymid [expr int(($py1+$py2)/2)]
	set spec "( $px1 $ymid ) ( $px2 * )"
      } else {
	set width $xlen
	set xmid [expr int(($px1+$px2)/2)]
	set spec "( $xmid $py1 ) ( * $py2 )"
      }

      if {$block_cnt == 0} {
	puts -nonewline $fd "\n+ ROUTED M1 $width + SHAPE BLOCKAGEWIRE $spec"
      } else {
	puts -nonewline $fd "\n  NEW M1 $width + SHAPE BLOCKAGEWIRE $spec"
      }
      incr block_cnt
    }
    puts $fd " ;"
  }

  if {$nspecialnets} {
    puts $fd "END SPECIALNETS"
  }

  puts $fd "END DESIGN"
  msg "write_def: done.  Elapsed [expr [clock seconds]-$starttime]\n"
}


proc fplan_mini_extract {cell} -desc {
  Look for unique paints in cell, and print their coordinates.
} {
  while {1} {
    set paintball [lindex [db_search_l paint -cell $cell -limit 1] 0]
    if {$paintball == ""} {break}
    struct max_paint p $paintball
    setl {x y} [uusnap -mask [expr (${p.x1} + ${p.x2}) / 2] \
	[expr (${p.y1} + ${p.y2}) / 2]]
    sel_net -point $x $y ${p.layer}
    set fnd_paint [sel_what paint -limit 1]
    # The delete complains about paint in via cells that was also selected.
    msg_catch {:delete} junk junk junk
    if {$fnd_paint == ""} {
      msg "Warning: db_search failed for a piece of paint\n"
      continue
    }
    struct max_paint f $fnd_paint
    msg "Paint found at coordinates ${f.x1} ${f.y1}\n"
  }
}
