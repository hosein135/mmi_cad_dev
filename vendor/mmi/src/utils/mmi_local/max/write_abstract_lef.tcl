# Creates an abstract LEF file for the current max cell.
# Different from a standard-cell LEF file in that it doesn't 
# include all geometries.  Instead blocks large areas.

# Written by Lee Tavrow, 1997.

# The next two lines go into the .maxrc
#source $local_dir/write_abstract_lef.tcl
#menu_tool_cmd "write abstract lef" write_abstract_lef

#TODO: add polygons, wirepaths NOT just paint

# How it works:

# All of the metal and via layers are flattened into the new cells
# _TMP_ and _TMP2_.  In _TMP_, the complete nets attached to the I/O's
# are deleted as are the nets of globals only on the layer of the label.
# The bounding box of the blocked metals is then obtained.

# Next, we switch to _TMP2_ and delete all blocked layers inside this
# bounding box.  The complete nets attacked to the I/O's are then selected,
# written out and deleted as are the globals on the layer of the label.
# The rest is written out as obstructions.

# For this to work, the I/O's must be on unblocked layers or be outside
# of the bounding box of the blocked layer bounding box.

proc l {} {
  uplevel #0 source /home/tavrow/dev/max/write_abstract_lef.tcl
  puts loaded
  write_abstract_lef
}

#====================================================================#

proc write_abstract_lef {} -desc {
  write abstract lef for current cell to cell's directory
} {

  global WAL

  set title "Write Abstract LEF"
  set message "LEF Options:"

  set prop_list ""

  # set up tech stuff
  set metals [techinfo layers metal]

  foreach metal $metals {
    set WAL($metal) [use_first WAL($metal) '1]
    lappend prop_list [list "block $metal" WAL($metal) binary]
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

  set WAL(roundx) [use_first WAL(roundx) '0.001]
  lappend prop_list [list "Round X to" WAL(roundx)]

  set WAL(roundy) [use_first WAL(roundy) '0.001]
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

  eval sel_area -any_cell -layers $WAL(prb) [lay_bbox]
  if {[sel_what paint] != ""} {
    # get boundary of WAL(prb)
    setl {x1 y1 x2 y2} [db_bbox -cell __SELECT__]

  } else {
    # no WAL(prb) layer use bbox
    setl {x1 y1 x2 y2} [lay_bbox]
  }

  # boiler plate
  puts $FILE_ID "MACRO $cell"

  puts $FILE_ID "\tCLASS BLOCK ;"

  puts $FILE_ID "\tFOREIGN $cell $x1 $y1 ;"

  # round up to desired
  puts $FILE_ID "\tSIZE [expr $WAL(roundx)*ceil(($x2 - $x1)/$WAL(roundx))] BY [expr $WAL(roundy)*ceil(($y2 - $y1)/$WAL(roundy))] ;"

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
  set flags [cell_flags _TMP2_]
  if { $flags != "__NO_SUCH_BUFFER__" } {
    # delete cell
    db_cell_delete _TMP2_
  }

  set metal_vias [concat $metals [techinfo vias]]
  eval sel_area -any_cell -layers [join $metal_vias ,] [lay_bbox]
  db_cell_copy -source __SELECT__ _TMP_
  db_cell_copy -source __SELECT__ _TMP2_

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

  # move obstruction layers in from pins
  :load _TMP_
  foreach label $labels {
    setl {layer lx1 ly1 lx2 ly2 pos text} $label

    sel_net -point $lx1 $ly1 $layer
    :delete
  }

  # for globals, only get what's on this layer
  foreach label $glabels {
    setl {layer lx1 ly1 lx2 ly2 pos text} $label

    sel_region -point $lx1 $ly1 $layer
    :delete

    lappend glabel_array($text) $label
  }

  # toast any leftover labels???
  foreach l $block_metals {
    sel_labels -layer $l
    :delete
  }

  # this is the obstruction region
  eval sel_area -layers [join $block_metals ,] [lay_bbox]
  setl {ox1 oy1 ox2 oy2} [db_bbox -cell __SELECT__]

  # now remove all nets from obstruction region
  :load _TMP2_

  sel_area -layers [join [concat $block_metals [techinfo vias]] ,] \
      $ox1 $oy1 $ox2 $oy2
  :delete

  # get all that's left for I/O's
  foreach label $labels {
    setl {layer lx1 ly1 lx2 ly2 pos text path group_unused kind} $label

    puts $FILE_ID "\tPIN $text"
    puts $FILE_ID "\t\tDIRECTION $kind ;"

    puts $FILE_ID "\t\tUSE SIGNAL ;"

    puts $FILE_ID "\t\tPORT"

    sel_net -point $lx1 $ly1 $layer

    set last_player ""

    set exists 0
    foreach paint [split [sel_what paint] \n] {
      set exists 1
      set player [lindex $paint 0]

      if {$player != $last_player} {
	if {[lsearch $metals $player] == -1} {
	  # ignore, probably a via
	  continue
	}

	puts $FILE_ID "\t\t\tLAYER [use_first WAL(xlate,$player) player] ;"
	set last_player $player
      }

      puts $FILE_ID "\t\t\tRECT [lrange $paint 1 4] ;"
    }

    if {!$exists} {
      puts "WARNING: $kind \"$text\" inside obstruction bbox and not included in LEF."
    }

    # delete this layer
    :delete

    puts $FILE_ID "\t\tEND"
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
	  if {[lsearch $metals $player] == -1} {
	    # ignore, probably a via
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

  # return to cell
  :load $cell

  # now add the obstructions
  puts $FILE_ID "\tOBS"

  foreach layer $metals {
    if {$WAL($layer)} {
      # block this layer
      puts $FILE_ID "\t\t\tLAYER [use_first WAL(xlate,$layer) layer] ;"

      setl {dx1 dy1 dx2 dy2} "0 0 0 0"
      set coords [list [expr $ox1 + $dx1] [expr $oy1 + $dy1] \
		      [expr $ox2 + $dx2] [expr $oy2 + $dy2]]
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
 
  # close the file
  close $FILE_ID
 
  sel_clear

  # delete tmp buffers
#  set flags [cell_flags _TMP_]
#  if { $flags != "__NO_SUCH_BUFFER__" } {
#    # delete cell
#    db_cell_delete _TMP_
#  }
  set flags [cell_flags _TMP2_]
  if { $flags != "__NO_SUCH_BUFFER__" } {
    # delete cell
    db_cell_delete _TMP2_
  }

  eval lay_box $save_box
 
  undo_enable

  puts "Done."
}

