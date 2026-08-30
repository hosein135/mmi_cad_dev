# Creates a ports file for the current max cell.

# The next two lines go into the .maxrc to load this command and
# place into the tool menu.
#source $MMI_LOCAL/max/write_ports.tcl
#menu_tool_cmd "write ports" write_ports

#====================================================================#

# Technology dependent setup

# Use this layer to set the bounding box of the cell
set WRITE_LEF(boundary) prb

# tries to compute from tech
#set PORTS_GRID 0.62

# Cell height in grids
set CELL_HEIGHT 10


#====================================================================#

proc write_ports {} -desc {
  write ports file for current cell to cell's directory.
} {

  global MN_TECH PORTS_GRID WRITE_LEF

  # save so we can restore later
  set save_box [lay_box]

  # current cell name
  set cell [lay_rootcell]

  # find the directory
  set dir [file dirname [lindex [cell_info $cell] 1]]
  if {$dir == "."} {
    set dir [pwd]
  }

  set filename $dir/$cell.ports
  puts "Writing ports file for cell $cell to $filename ..."

  set x1 0
  set x2 0

  if {![info exists PORTS_GRID]} {
    # figure out grid
    switch $MN_TECH {
      mmi15 { set PORTS_GRID 0.62 }
      default {
	todo: ask user with a popup
      }
    }
  }

  # make sure the cell is showing all hierarchy
  eval lay_box [lay_bbox]
  lay_internals -area

  # first look for the prboundary layer
  if {[use_first WRITE_LEF(boundary)] != ""} {
    if {![catch "sel_area -any_cell -layers $WRITE_LEF(boundary) [lay_bbox]"]} {
      # layer is a valid max layer
      setl {x1 y1 x2 y2} [db_bbox -cell __SELECT__]
    }
  }

  if {$x2 > [expr $x1 + 2 * [res]]} {
    # got a valid bbox from the prboundary layer

  } else {
    # use the bbox of the cell.
    setl {x1 y1 x2 y2} [db_bbox]
    
    if {$x2 < [expr $x1 + 2 * [res]]} {
      warning "Aborting, the cell is empty.  Can't write ports file."
      return
    }
  }

  # clear any feedback or other annotations
  clear_annotations

  # need to expand all instances
  eval lay_box [lay_bbox]
  lay_internals -area
  
  # find all I/O's
  sel_labels -kind input
  sel_labels -more -kind output
  sel_labels -more -kind inout

  set io_labels [split [sel_what labels] \n]
  if {$io_labels == ""} {
#    warning "Aborting, cell has no I/O labels in it."
    puts "IFNO, cell has no I/O labels in it."
#    return
  }

  # open file for writing
  if {[catch "open $filename w" FILE_ID]} {
    # can't write file, abort
    warning "Aborting, $FILE_ID"
    return
  }

  # boiler plate
  puts $FILE_ID "\# Created by write_ports in MAX from cell $cell"

  puts $FILE_ID "bbox [_write_ports_scale $x2 $x1 $y2 $y1 bbox]"
  puts $FILE_ID "orient N"

  # add ports -- use label position
  foreach label $io_labels {
    setl {layer lx1 ly1 lx2 ly2 pos text path} $label

    if {$path != ""} {
      # ignore labels in subcells
      continue
    }

    if {[info exists save($text)]} {
      # already processed this
      continue
    }
    set save($text) 1

    puts $FILE_ID "port $text [_write_ports_scale $lx1 $x1 $ly1 $y1]"
  }

  # close the file
  close $FILE_ID
 
  # clear selection and restore box
  sel_clear
  eval lay_box $save_box
 
  puts "Added [llength [array names save]] ports."
}


proc _write_ports_scale {x2 x1 y2 y1 {text ""}} -desc {
  scales x2,y2 referenced to x1 y1

} {

  global PORTS_GRID CELL_HEIGHT

  set x [expr 1.0 * ($x2 - $x1) / $PORTS_GRID]

  if {$text != ""} {
    if {$x != [expr round($x)]} {
      puts "Warning: rounding x ($x) on $text to nearest grid."
    }

    set x [expr ceil($x)]
  }

  set y [expr 1.0 * ($y2 - $y1) / $PORTS_GRID]

  if {$text != ""} {
    if {$y != [expr round($y/$CELL_HEIGHT)*$CELL_HEIGHT]} {
      puts "Warning: rounding y ($y) on $text to nearest grid."
    }

    set y [expr ceil($y/$CELL_HEIGHT)*$CELL_HEIGHT]
  }

  return [list $x $y]
}
