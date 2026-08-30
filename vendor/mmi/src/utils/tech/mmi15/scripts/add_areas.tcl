#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit

# Written by Lee Tavrow, 1998

# Reads a LEF file and adds area data to a synopsys library file
# OR
# Reads a DPC file and adds area data to a synopsys library file

set TECH mmi15
set ROOT /proj/tech/$TECH
set LEFFILE $ROOT/library/lef/$TECH.lef

# Technology information

# This grid is um's per grid
set DPGRID 0.62

# ONLY NEEDED for dpc2area (when no LEF yet -- i.e. before layout)
# in grids
set DEFAULT_HEIGHT 10
set DPCFILE $ROOT/library/dpc/$TECH.dpc

proc lef2area {filename} {

  global LEFFILE DPCFILE DPGRID

  set count 0

  # open the lef file for reading
  if {[catch "open $LEFFILE r" FILE_ID]} {
    # problem
    puts "ERROR: $FILE_ID"
    exit 1
  }

  puts stderr "Parsing $LEFFILE ..."

  # look for a line of the form:
  # MACRO <name>
  # SIZE <x> BY <y> ;
  # END <name>

  set cell ""
  while {[gets $FILE_ID line] >= 0} {
    set line [string trim $line]

    if {[lindex $line 0] == "MACRO"} {
      set cell [lindex $line 1]
      continue
    }

    if {[lindex $line 0] == "END" && [lindex $line 1] == $cell} {
      set cell ""
      continue
    }

    if {$cell != "" && [lindex $line 0] == "SIZE"} {
      set width [expr [lindex $line 1]/$DPGRID]
      set height [expr [lindex $line 3]/$DPGRID]

      # write to DPCFILE file
      set AREA($cell) [expr $width * $height * $DPGRID * $DPGRID]

      incr count
    }
  }

  # close the file
  close $FILE_ID

  puts stderr "Adding areas to $filename ..."

  # open the lib file for reading
  if {[catch "open $filename r" FILE_ID]} {
    # problem
    puts "ERROR: $FILE_ID"
    exit 1
  }

  set cells 0
  set added 0

  while {[gets $FILE_ID line] >= 0} {
    puts $line

    regsub -all {\(|\)|\,\\|\{|\}|\;} $line " " line2
    if {[lindex $line2 0] == "cell"} {
      incr cells
      # add the area line here
      set name [lindex $line2 1]
      if {[info exists AREA($name)]} {
	puts "\tarea : $AREA($name) ;"
	incr added
      } else {
	puts stderr "No area data for cell \"$name\"."
      }
    }
  }

  # close the file
  close $FILE_ID

  puts stderr "Added areas to $added/$cells cells."

  puts stderr "done."
}


proc dpc2area {filename} {

  global DPCFILE DPGRID DEFAULT_HEIGHT

  set count 0

  # open the dpc file for reading
  if {[catch "open $DPCFILE r" FILE_ID]} {
    # problem
    puts "ERROR: $FILE_ID"
    exit 1
  }

  puts stderr "Parsing $DPCFILE ..."

  while {[gets $FILE_ID line] >= 0} {
    set line [string trim $line]

    setl {cell width height} $line

    if {$cell == "" || [string index $cell 0] == "\#"} {
      # skip comment or blank line
      continue
    }

    if {$height == ""} {
      set height $DEFAULT_HEIGHT
    }

    # write to DPCFILE file
    set AREA($cell) [expr $width * $height * $DPGRID * $DPGRID]

    incr count
  }

  # close the file
  close $FILE_ID

  puts stderr "Adding areas to $filename ..."

  # open the lib file for reading
  if {[catch "open $filename r" FILE_ID]} {
    # problem
    puts "ERROR: $FILE_ID"
    exit 1
  }

  set cells 0
  set added 0

  while {[gets $FILE_ID line] >= 0} {
    puts $line

    regsub -all {\(|\)|\,\\|\{|\}|\;} $line " " line2
    if {[lindex $line2 0] == "cell"} {
      incr cells
      # add the area line here
      set name [lindex $line2 1]
      if {[info exists AREA($name)]} {
	puts "\tarea : $AREA($name) ;"
	incr added
      } else {
	puts stderr "No area data for cell \"$name\"."
      }
    }
  }

  # close the file
  close $FILE_ID

  puts stderr "Added areas to $added/$cells cells."

  puts stderr "done."
}


# do it
#lef2area $argv
dpc2area $argv

exit 1
