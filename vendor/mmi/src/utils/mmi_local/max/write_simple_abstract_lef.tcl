# Creates an abstract LEF file for the current max cell.
# Different from a standard-cell LEF file in that it doesn't 
# include all geometries.  Instead blocks large areas.

# Written by Lee Tavrow, 1997.

# The next two lines go into the .maxrc
#source $local_dir/write_abstract_lef.tcl
#menu_tool_cmd "write abstract lef" write_abstract_lef

#TODO: add polygons, wirepaths NOT just paint

# How it works:

# Only looks at stuff outside of prb

proc l {} {
  uplevel #0 source /volume/cad/mmi/mmi_local.dev/max/write_simple_abstract_lef.tcl
  puts loaded
  write_abstract_lef
}

#====================================================================#

proc write_simple_abstract_lef {} -desc {
  write abstract lef for current cell to cell's directory
} {

  global WAL

  set title "Write Abstract LEF"
  set message "LEF Options:"

  set prop_list ""

  # set up tech stuff
  set metals [techinfo layers metal]
  # metals and vias, but not contacts
  set lef_layers [concat [lrange [techinfo layers via] 1 end] $metals]

  foreach metal $metals {
    set WAL($metal) [use_first WAL($metal) '1]
    lappend prop_list [list "block $metal" WAL($metal) binary]
  }

  set fets [techinfo devices]
  set diffs ""
  foreach fet $fets {
    lappend diffs [lindex [techinfo device $fet] 1]
  }

  set WAL(bogus) 1
  lappend prop_list "foo WAL(bogus) -break"

  foreach metal $metals {
    set WAL(xlate,$metal) [use_first WAL(xlate,$metal) metal]
    lappend prop_list [list "translate $metal" WAL(xlate,$metal)]
  }

  set WAL(bogus2) 1
  lappend prop_list "foo WAL(bogus2) -break"

  set WAL(site) [use_first WAL(site)]
  lappend prop_list [list "site" WAL(site)]

  set WAL(ignores) [use_first WAL(ignores)]
  lappend prop_list [list "ignore I/O's" WAL(ignores)]

  set WAL(roundx) [use_first WAL(roundx) '0.62]
  lappend prop_list [list "Round X to" WAL(roundx)]

  set WAL(roundy) [use_first WAL(roundy) '0.62]
  lappend prop_list [list "Round Y to" WAL(roundy)]

  set WAL(prb) [use_first WAL(prb) 'prb]
  lappend prop_list [list "Boundary Layer" WAL(prb)]


  # create the menu
  if {![prop_menu2 -message $message -title $title $prop_list]} {
    # cancelled
    return ""
  }

  set block_metals ""
  foreach layer $metals {
    if {$WAL($layer)} {
      # block this layer
      lappend block_metals $layer
    }
  }

  undo_disable

  set save_box [lay_box]

  set cell [lay_rootcell]

  # find the directory
  set dir [file dirname [lindex [cell_info $cell] 1]]
  if {$dir == "."} {
    set dir [pwd]
  }

  set filename $dir/$cell.lef
  puts "Writing LEF for cell $cell to $filename ..."

  # open lef file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  :feedback clear
  eval lay_box [lay_bbox]
  lay_internals -area

  eval sel_area -layers $WAL(prb) [lay_bbox]
  if {[sel_what paint] != ""} {
    # get boundary of WAL(prb)
    setl {x1 y1 x2 y2} [db_bbox -cell __SELECT__]

  } else {
    error "Aborting, No prb layer in design."
  }

  # boiler plate
  puts $FILE_ID "MACRO $cell"

  puts $FILE_ID "\tCLASS BLOCK ;"

  setl {bx1 by1 bx2 by2} [lay_bbox]

  puts $FILE_ID "\tFOREIGN $cell $bx1 $by1 ;"
  puts $FILE_ID "\tORIGIN 0 0 ;"

  # round up to desired
  puts $FILE_ID "\tSIZE [expr $WAL(roundx)*ceil(($bx2 - $bx1)/$WAL(roundx))] BY [expr $WAL(roundy)*ceil(($by2 - $by1)/$WAL(roundy))] ;"

  puts $FILE_ID "\tSYMMETRY X Y ;"

  if {[use_first WAL(site)] != ""} {
    puts $FILE_ID "\tSITE $WAL(site) ;"
  }

  # create 2 flattened versions with metal and via layers only
  set flags [cell_flags _TMP_]
  if { $flags != "__NO_SUCH_BUFFER__" } {
    # delete cell
    db_cell_delete _TMP_
  }

  set metal_vias [concat $metals [techinfo vias]]

  # get everything outside of prb bbox
  sel_clear
  sel_area -more -any_cell -layers [join $metal_vias ,] $bx1 $by1 $bx2 $y1
  sel_area -more -any_cell -layers [join $metal_vias ,] $bx1 $y2 $bx2 $by2
  sel_area -more -any_cell -layers [join $metal_vias ,] $bx1 $y1 $x1 $y2
  sel_area -more -any_cell -layers [join $metal_vias ,] $bx2 $y1 $x2 $y2

  db_cell_copy -source __SELECT__ _TMP_

  :load _TMP_

  # get all top level signal labels
  sel_labels -kind input
  sel_labels -more -kind output
  sel_labels -more -kind inout

  # motor thru signals
  set labels ""
  foreach label [split [sel_what labels] \n] {
    setl {layer lx1 ly1 lx2 ly2 pos text} $label

    if {[info exists TRACE($text)]} {
      # ignore dups
      continue
    }
    set TRACE($text) 1

    if {[lsearch $WAL(ignores) $text] != -1} {
      # skip it
      continue
    }

    lappend labels $label
  }

  # get all top level power/ground
  sel_labels -kind global

  # motor thru globals
  set glabels ""
  foreach label [split [sel_what labels] \n] {
    setl {layer lx1 ly1 lx2 ly2 pos text} $label

    if {[lsearch $WAL(ignores) $text] != -1} {
      # skip it
      continue
    }

    lappend glabels $label
  }

  # get all that's left for I/O's
  foreach label $labels {
    setl {layer lx1 ly1 lx2 ly2 pos text path group_unused kind} $label

    sel_net -point $lx1 $ly1 $layer

    if {[llength [sel_what paint -limit 1]] == 0} {
      # nothing connected, skip
      continue
    }

    puts $FILE_ID "\tPIN $text"
    puts $FILE_ID "\t\tDIRECTION $kind ;"

    puts $FILE_ID "\t\tUSE SIGNAL ;"

    puts $FILE_ID "\t\tPORT"

    set last_player ""

    set exists 0
    foreach paint [split [sel_what paint] \n] {
      set exists 1
      set player [lindex $paint 0]

      if {$player != $last_player} {
	if {[lsearch $lef_layers $player] == -1} {
	  # ignore, probably a contact
	  continue
	}

	puts $FILE_ID "\t\t\tLAYER [use_first WAL(xlate,$player) player] ;"
	set last_player $player
      }

      puts $FILE_ID "\t\t\tRECT [lrange $paint 1 4] ;"
    }

    # delete this layer
    :delete

    puts $FILE_ID "\t\tEND"

    # return to cell to look for antenna stuff
    :load $cell

    sel_net -point $lx1 $ly1 $layer

    set area 0
    set diffarea 0
    catch {unset perims}

#puts "$text $kind ($lx1 $ly1 $layer) --> [sel_what_paint]"

    foreach paint [sel_what_paint] {
      set player [lindex $paint 0]

      if {[lsearch $metals $player] != -1} {
	# metal, sum up
	setl {player px1 py1 px2 py2} $paint
	# NOTE: this is can be an overestimate
	set perim [expr 2 * (($px2 - $px1) + ($py2 - $py1))]
	if {[info exists perims($player)]} {
	  set perims($player) [expr $perims($player) + $perim]
	} else {
	  set perims($player) $perim
	}

      } elseif {[lsearch $fets $player] != -1} {
	setl {player px1 py1 px2 py2} $paint
	set this_area [expr ($px2 - $px1) * ($py2 - $py1)]
	set area [expr $area + $this_area]

      } elseif {[lsearch $diffs $player] != -1} {
	setl {player px1 py1 px2 py2} $paint
	set this_area [expr ($px2 - $px1) * ($py2 - $py1)]
	set diffarea [expr $diffarea + $this_area]
      }
    }

    foreach player [array names perims] {
      puts $FILE_ID "\t\tAntennaPartialMetalSideArea $perims($player) LAYER [use_first WRITE_LEF(xlate,$player) player] ;"      
    }

    if {$area > 0} {
      puts $FILE_ID "\t\tAntennaGateArea $area ;"
    }
    if {$diffarea > 0} {
      puts $FILE_ID "\t\tAntennaDiffArea $diffarea ;"
    }

    # return to _TMP_
    :load _TMP_

    puts $FILE_ID "\tEND $text"
  }

  # get all that's left for globals
  foreach text [array names glabel_array] {
    puts $FILE_ID "\tPIN $text"
    puts $FILE_ID "\t\tDIRECTION inout ;"

    # hack to figure out power vs. gnd
    if {[string first v [string tolower $text]] == -1} {
      puts $FILE_ID "\t\tUSE GROUND ;"
    } else {
      puts $FILE_ID "\t\tUSE POWER ;"
    }
      
    puts $FILE_ID "\t\tPORT"

    set last_player ""
    foreach label $glabel_array($text) {
      setl {layer lx1 ly1 lx2 ly2 pos text path group_unused kind} $label

      sel_region -point $lx1 $ly1 $layer

      foreach paint [split [sel_what paint] \n] {
	set player [lindex $paint 0]

	if {$player != $last_player} {
	  if {[lsearch $lef_layers $player] == -1} {
	    # ignore, probably a contact
	    continue
	  }

	  puts $FILE_ID "\t\t\tLAYER [use_first WAL(xlate,$player) player] ;"
	  set last_player $player
	}

	puts $FILE_ID "\t\t\tRECT [lrange $paint 1 4] ;"
      }

      # delete this layer
      :delete
    }

    puts $FILE_ID "\t\tEND"
    puts $FILE_ID "\tEND $text"
  }

  # get anything left over and make an obstruction
  eval sel_area [lay_bbox]

  foreach paint [split [sel_what paint] \n] {
    set player [lindex $paint 0]

    lappend obstructions($player) $paint
  }

  # now add the obstructions
  puts $FILE_ID "\tOBS"

  foreach layer $metals {
    if {$WAL($layer)} {
      # block this layer
      puts $FILE_ID "\t\t\tLAYER [use_first WAL(xlate,$layer) layer] ;"

      setl {dx1 dy1 dx2 dy2} "0 0 0 0"
      set coords [list [expr $x1 + $dx1] [expr $y1 + $dy1] \
		      [expr $x2 + $dx2] [expr $y2 + $dy2]]
      puts $FILE_ID "\t\t\tRECT $coords ;"

    } else {
      if {[info exists obstructions($layer)]} {
	puts $FILE_ID "\t\t\tLAYER [use_first WAL(xlate,$layer) layer] ;"
      }
    }

    foreach paint [use_first obstructions($layer)] {
      puts $FILE_ID "\t\t\tRECT [lrange $paint 1 4] ;"
    }
  }

  puts $FILE_ID "\tEND"
 
  puts $FILE_ID "END $cell"

  puts $FILE_ID "END LIBRARY"

  # close the file
  close $FILE_ID
 
  sel_clear

  # delete tmp buffers
#  set flags [cell_flags _TMP_]
#  if { $flags != "__NO_SUCH_BUFFER__" } {
#    # delete cell
#    db_cell_delete _TMP_
#  }

  # return to cell
  :load $cell

  eval lay_box $save_box
 
  undo_enable

  puts "Done."
}

