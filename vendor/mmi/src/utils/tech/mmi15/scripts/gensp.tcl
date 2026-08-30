#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
echo "source $0" | max -tech mmi15 ; exit

# Written by Lee Tavrow, 1997-9.

# extract_all:   Extracts spice netlists from max layout
# lef_all:       Generates LEFs from max layouts
# lef2size:      Creates a SUE DPC size file from a LEF file

# NOTE: the procedures "extract_all" and "lef_all" must be run
# from within MAX -- see echo line above


set TECH mmi15
set ROOTDIR /proj/tech/$TECH/stdcell

set MAXDIR $ROOTDIR/max
set EXTRACTDIR $ROOTDIR/extract
set IGNORE_CELL_LIST "MMI_FILL_1 MMI_FILL_2 MMI_FILL_4 MMI_FILL_8"

set LEFDIR $ROOTDIR/lef
set CELLSIZES $ROOTDIR/$TECH.dpc
 

# Technology information

# This grid is um's per grid
set DPGRID 0.62

# This is the default cell height in grids
set DEFAULT_HEIGHT 10


# needed for extract_spice
_mc_load


# Generates extracted spice netlists with diodes for source/drain
# area and wire capacitances.  Operates on all max files in a directory except
# those in the IGNORE_CELL_LIST.

# Reads all max files out of the MAXDIR directory.
# Extracts all and writes spice netlists to EXTRACTDIR directory.

proc extract_all {} {

  global EXTRACTDIR MAXDIR IGNORE_CELL_LIST

  set save_cd [pwd]

  # so extract_spice extracts to here (should check dir)
  cd $MAXDIR

  # walk thru all max cells in dir
  foreach cell [lsort [glob $MAXDIR/*.max]] {

    set cell_name [file root [file tail $cell]]

    if {[lsearch $IGNORE_CELL_LIST $cell_name] != -1} {
      # ignore this
      puts "\nSkipping cell \"$cell_name\"."
      continue
    }

    # load the cell into max
    if {[msg_catch "cell_load $cell_name [file dirname $cell]" "" toss]} {
      # probably already loaded, just goto cell
      cell_load $cell_name
    }

    # extract the spice netlist to MAXDIR
    puts "Extracting cell \"$cell_name\"..."
    extract_spice

    # see if it is different from the one in EXTRACTDIR
    if {[file readable $EXTRACTDIR/$cell_name.sp]} {
      catch "exec diff -w $MAXDIR/$cell_name.sp $EXTRACTDIR/$cell_name.sp" msg
    } else {
      set msg "different"
    }

    if {$msg != ""} {
      # netlists are different, cp
      puts "Cell \"$cell_name\" netlist changed, copying to $EXTRACTDIR."
      exec cp -f $MAXDIR/$cell_name.sp $EXTRACTDIR/$cell_name.sp
      lappend changed $cell_name
    }
  }

  if {[info exists changed]} {
    puts "\nChanged cells: $changed\n"
  } else {
    puts "\nNo Cells changed.\n"
  }

  cd $save_cd
  puts "extract all done."
}


# Reads all max files in MAXDIR directory.
# Writes lef files to LEFDIR directory.

proc lef_all {} {

  global LEFDIR MAXDIR

  # first, remove all the existing lef files
  catch {exec rm -f $LEFDIR/*.lef}

  foreach cell [lsort [glob $MAXDIR/*.max]] {

    set cell_name [file root [file tail $cell]]

    # load the cell into max
    if {[msg_catch "cell_load $cell_name [file dirname $cell]" "" toss]} {
      # probably already loaded, just goto cell
      cell_load $cell_name
    }

    # change the path of the cell to the LEFDIR
    db_cell_rename $cell_name $cell_name $LEFDIR/$cell_name.max

    eval lay_box [lay_bbox]
    lay_internals -area

    # write out the lef
    write_lef
  }

  puts "lef all done."
}


# Reads all the LEF files out of LEFDIR and creates a file called
# CELLSIZES that contains size information.  This file is used by
# the SUE Data Path compiler.

proc lef2size {} {

  global LEFDIR CELLSIZES DPGRID DEFAULT_HEIGHT

  set count 0

  # open the cell sizes file for writing
  if {[catch "open $CELLSIZES w" FILE_ID]} {
    # problem
    puts "lef2size error: $FILE_ID"
    return
  } 

  foreach cell [lsort [glob $LEFDIR/*.lef]] {

    set cell_name [file root [file tail $cell]]

    if {[catch "open $cell r" LEF_ID]} {
      # problem
      msg $LEF_ID
      continue
    }

    # look for a line of the form:
    # SIZE 5.6 BY 8.75 ;

    while {[gets $LEF_ID line] >= 0} {
      set line [string trim $line]

      if {[lindex $line 0] != "SIZE"} {
	continue
      }
      
      set x2 [lindex $line 1]
      set y2 [lindex $line 3]
      set x1 0
      set y1 0

      break
    }

    # close the file
    close $LEF_ID

    set width [expr ($x2 - $x1)/$DPGRID]
    set height [expr ($y2 - $y1)/$DPGRID]

    set the_height $height
    if {$height == $DEFAULT_HEIGHT} {
      set height ""
    } else {
      set height [format "%g" $height]
    }

    # write to CELLSIZES file
    puts $FILE_ID [format "$cell_name %g $height" $width]

    incr count
  }

  # close the files
  close $FILE_ID

  puts "Wrote SUE DPC size file $CELLSIZES with $count cells."
}


# now execute (in max)

puts "\nRunning gensp.tcl ...\n"

# iconify the max window
wm iconify $max_win

extract_all
lef_all

puts "\ngensp.tcl done"

# exit max
mn_exit -nobackup

