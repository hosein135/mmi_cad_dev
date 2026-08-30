
# extract all toplevel nets using max's ext_capacitance and write
# to a file.

set EXT_CAP(power_labels) "vdd gnd"
set EXT_CAP(ignore_labels) "$EXT_CAP(power_labels) bbox"

set EXT_CAP(expand_cells) "VIA12 VIA23 VIA34 VIA45"

# ignore these cells.  expand_cells are also ignored.
set EXT_CAP(ignore_cells) "mm_sram FILL_1 FILL_2 FILL_4 FILL_8 POWER_CELL gmb_port_N4 gmb_port_E3 gmb_port_E1"

# suffix of output capacitance file
set EXT_CAP(suffix) .ext_cap


# main extraction procedure

proc cap_extract {} {

  global EXT_CAP

  # turn off undo
  undo_disable

  eval lay_box [lay_bbox]

  # expand all
  lay_internals -area
  # now unexpand toplevel
  lay_internals -area -hide

  # select all cells
  :select area subcell

  # expand all
  lay_internals -area

  set cells [split [sel_what cells] \n]

  set netnames ""
  set expand_cells ""

  foreach cell $cells {
    setl {cellname celltype} $cell

    if {[lsearch $EXT_CAP(expand_cells) $celltype] != -1} {
      lappend expand_cells $cellname
      continue
    }

    if {[lsearch $EXT_CAP(ignore_cells) $celltype] != -1} {
      continue
    }

    puts "Processing cell $cellname ($celltype) ..."

    select_q cell $cellname
    # edit it in place
    :edit

    # get the bbox of this cell (in place)
    eval lay_box [lay_bbox]
    select_q -editOnly area metal1
    set bbox [lay_bbox_selected $cellname]

    sel_labels
    foreach label [split [sel_what labels] \n] {
      setl {layer x1 y1 x2 y2 bogus labelname labelpath} $label

      if {[lsearch $EXT_CAP(ignore_labels) $labelname] != -1} {
	# ignore these
	continue
      }

      if {[info exists visited($labelpath$labelname)]} {
	# already been here
	continue
      }

#      puts "$cellname --> $labelname"

      sel_net -point $x1 $y1 $layer
      set netname ""
      set _labels [split [sel_what labels] \n]

      foreach _label $_labels {
	setl {_layer _x1 _y1 _x2 _y2 _bogus _labelname _labelpath} $_label
	
	if {[lsearch $EXT_CAP(power_labels) $labelname] != -1} {
	  # net connected to a supply
	  set netname _SUPPLY_
	  break
	}

	if {$_labelpath == ""} {
	  # this is a top level net, remember
	  set netname $_labelname
	}
      }

      if {$netname == ""} {
	# this is a local net, name after full port name of one terminal
	set netname $_labelpath$_labelname
      }

      if {$netname != "_SUPPLY_"} {
	# only remember if not connected to a supply

	# need to find paint (for later selection) that is NOT in this cell
	# nor in any other cell but in the toplevel.
	
	# deselect paint outside of the cell boundary
	setl {bx1 by1 bx2 by2} $bbox
	setl {bbx1 bby1 bbx2 bby2} [lay_bbox]
	lay_box $bbx1 $bby1 $bx1 $bby2
	select_q less area *
	lay_box $bx2 $bby1 $bbx2 $bby2
	select_q less area *
	lay_box $bbx1 $bby1 $bbx2 $by1
	select_q less area *
	lay_box $bbx1 $by2 $bbx2 $bby2
	select_q less area *

# set paints [sel_what paint]
# set foo($netname) $paints

	set found 0
        # need to reverse order to look at higher layers first
        foreach paint [list_lreverse [split [sel_what paint] \n]] {
	  setl {_layer _x1 _y1 _x2 _y2} $paint
	  lay_box $_x1 $_y1 $_x2 $_y2
	  select_q -editOnly area $_layer

	  if {[sel_what paint] != $paint} {
	    # found something not in cell
	    setl {tmp nx1 ny1 nx2 ny2} [sel_what paint]
	    if {$ny2 != ""} {
	      # partially not in cell, find outside part
#	      puts "--- $paint ---> [sel_what paint]"
	      if {$_x1 != $nx1} {
		set _x2 $nx1
	      } elseif {$_x2 != $nx2} {
		set _x1 $_x2
	      } elseif {$_y1 != $ny1} {
		set _y2 $ny1
	      } elseif {$_y2 != $ny2} {
		set _y1 $_y2
	      }
	    }

	    set found 1
	    break
	  }
	}

	if {$found} {
	  lappend netnames \
	      "$netname $_layer [center_coords $_x1 $_y1 $_x2 $_y2]"
	} else {
	  puts "Warning: no connect found on $netname"
	}
      }

      foreach _label $_labels {
	setl {_layer _x1 _y1 _x2 _y2 _bogus _labelname _labelpath} $_label

	set visited($_labelpath$_labelname) $netname
      }
    }

    # return to top most cell
    select_q cell .
    :edit
  }

  # Now do the extraction.  Note that we don't want to include
  # wiring in the cell.  This is already included in the cell 
  # characterization.  So we hide the cells.

  puts "Extracting ..."

  lay_internals -area -hide
  # must expand VIAS or bad news
  select_q clear
  foreach cell $expand_cells {
    select_q more cell $cell
  }
  lay_internals

  set filename [lay_rootcell]$EXT_CAP(suffix)
  if {[catch "open $filename w" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    return
  } 

  foreach list $netnames {
    setl {netname layer x1 y1} $list

    sel_net -point $x1 $y1 $layer
    set cap [ext_capacitance]
#    if {[lindex $cap 0] == 0} { puts $foo($netname) }
    if {[lindex $cap 0] == 0} { 
      puts "Warning: $netname = $cap"
puts "$x1 $y1 $layer $netname $cap"
    }

    puts $FILE_ID "$netname\t$cap"
  }

  # close the file
  close $FILE_ID

#  parray visited

  # turn undo back on
  undo_enable

  puts "Wrote extraction to file \"$filename\"."

  puts "done."
}


# finds the bounding box of the selected stuff
# need to pass the editcellname since lay_editcell -path is broken.

proc lay_bbox_selected {editcellname} {

  set rootcell [lay_rootcell]
  set editcell [lay_editcell]

  # go to select cell and get bbox
  msg_catch ":load __SELECT__" a b c
  set bbox [lay_bbox]

  # now return to where we were
  msg_catch ":load $rootcell" a b c

  if {$rootcell != $editcell} {
    select_q cell $editcellname
    # edit it in place
    :edit
  }

  return $bbox
}



# reverses the elements in a list

proc list_lreverse {list} {

  set new_list ""

  foreach element $list {
    set new_list [concat \{$element\} $new_list]
  }

  return $new_list
}
