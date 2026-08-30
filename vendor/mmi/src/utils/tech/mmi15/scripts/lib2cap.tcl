#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit

# Written by Lee Tavrow, 1999
# mmi15 version, jdj Mon Apr  9 14:03:44 2001

# Reads a synopsys lib file and creates a capacitance file for 
# pwr_clk_scan script.

set TECH mmi15
set ROOT /volume/mmi_proj/proj/tech/$TECH
set LIBFILE $ROOT/library/synopsys/$TECH.lib
set CAPFILE $ROOT/library/dpc/$TECH.cap

# Technology information

proc lib2cap {{filename ""}} {

  global LIBFILE CAPFILE

  if {$filename != ""} {
    set LIBFILE $filename
  }

  # Open the lib file for reading
  if {[catch "open $LIBFILE r" LIB_ID]} {
    # problem
    puts "lib2cap error: $LIB_ID"
    exit 1
  }

  # open the cell sizes file for writing
  if {[catch "open $CAPFILE w" FILE_ID]} {
    # problem
    puts "lib2cap error: $FILE_ID"
    exit 1
  } 

  puts "Parsing $LIBFILE ..."

  # look for lines of the form:
  # capacitive_load_unit (1.0,pf);
  #
  # cell (MMI_INVB) {
  #   pin (out) {
  #     direction : output;
  #     ...
  #   }
  #   pin (in) {
  #     direction : input;
  #     capacitance : 0.0083;
  #   }
  # }

  set count 0
  set cells 0
  set cell ""
  set pin ""
  set dir ""
  set units ""
  set comment 0

  while {[gets $LIB_ID line] >= 0} {

    # simple comment parsing
    set line [string trim $line]
    if {[string range $line 0 1] == "/*"} {
      # start comment
      if {[string first "*/" $line] != -1} {
	# end comment
	set comment 0
	continue
      }

      set comment 1
      continue
    }

    if {$comment} {
      if {[string first "*/" $line] != -1} {
	# end comment
	set comment 0
      }
      continue
    }

    regsub -all {\{|\}|\;|\"|\(|\)|\:} $line " " line

    set line [string trim $line]

    if {$cell == "" && [string first capacitive_load_unit $line] == 0} {
      # get the units
      regsub -all {\(|\)|,|\;|\ } [string range $line 20 end] "" units
      set units [parse_pp_number $units]
      puts "units = $units"
    }

    switch -- [string tolower [lindex $line 0]] {
      cell {
	if {$units == ""} {
	  puts "lib2cap error: aborting, couldn't find capacitive_load_unit line."
	  return
	}
	set cell [lindex $line 1]
	incr cells

	set pin ""
      }

      test_cell {
	puts stderr testcell
      }

      pin {
	if {$pin != "" && $dir != "output"} {
	  puts "Warning: no capacitance for $cell/$pin"
	}

	regsub -all {\(|\)|,|\;|\ } [string range $line 3 end] "" pin
      }

      direction {
	regsub -all {\(|\)|,|\;|\ |\:} [string range $line 9 end] "" dir
      }

      capacitance {
	if {$pin == ""} {
	  # problem
	  puts "lib2cap error: aborting, bad capacitance after cell def $cell."
	  return
	}

	regsub -all {\(|\)|,|\;|\ |\:} [string range $line 11 end] "" cap

	# write to CAPFILE file
	puts $FILE_ID "$cell/$pin [pp_number [expr $cap * $units]]"

	set pin ""

	incr count
      }
    }
  }

  # close the file
  close $LIB_ID

  # close the dpc file
  close $FILE_ID

  puts "Wrote SUE DPC size file $CAPFILE with $count capacitances in $cells cells."
}


# do it
lib2cap $argv
exit 1
