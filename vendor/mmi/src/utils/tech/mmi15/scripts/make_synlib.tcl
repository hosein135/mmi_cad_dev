#!/bin/sh

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit $?

# Written by Lee Tavrow, 1997
# Modified by pat 1999.

# Concatenates all file with a given suffix into a synopsys library.
# Takes care of extracting out cells.

#set SYNOPSYS_HEADER ./synopsys.header.tt
set SYNOPSYS_SUFFIX .syn
set LIBRARY_NAME mmi15


#################### Overridden by char.setup ######################
# Specifies spice header, voltage, and temperature (C) for all
# corners of interest.  The desired corner is specified from the
# command line.
set DATA(corner,tt) "/home/tavrow/char/header.tt 3.0V 105"
set DATA(corner,ss) "/home/tavrow/char/header.ss 3.0V 105"
set DATA(corner,ff) "/home/tavrow/char/header.ff 3.45V 25"

# Synopsys header information added to output file.
set DATA(synopsys_header_file) ./synopsys.header
######################################################################

proc setl {names values} {
  set i 0
  foreach name $names {
    uplevel [list set $name [lindex $values $i]]
    incr i
  }
  # returns number of variables set
  return $i
}

proc make_synlib {corner} {

  global SYNOPSYS_SUFFIX DATA LIBRARY_NAME

  puts stderr "Creating synopsys library $LIBRARY_NAME..."

  if {[catch "source char.setup"]} {
      puts stderr "Can't find file \"char.setup\", using defaults"
  } else {
      puts stderr "Using setup file \"char.setup\""
  }



  if {![info exists DATA(corner,$corner)]} {
      puts stderr "Aborting, corner $corner not defined in char.setup file."
      exit 1
  }
  setl {DATA(header_file) DATA(vdd) DATA(TEMP)} $DATA(corner,$corner)


  foreach cell [glob *$SYNOPSYS_SUFFIX] {
    
    if {[catch "open $cell r" FILE_ID]} {
      # error
      puts stderr "Skipping, $FILE_ID"
      continue
    } 

    # parse the file
    while {[gets $FILE_ID line] >= 0} {

      switch [string range $line 0 3] {

	lu_t {
	  # need to remember all lu_table_templates
	  set type [string trim $line]

	  if {[info exists lu($type)]} {
	    # already got this one
	    continue
	  }

	  # save away contents
	  regsub -all {\{|\}} $line \\\\& munged
	  set lu($type) ""
	  lappend lu($type) $munged
	  while {[gets $FILE_ID line] >= 0} {
	    regsub -all {\{|\}} $line \\\\& munged
	    lappend lu($type) $munged

	    if {[string index $line 0] == "\}"} {
	      # we're done
	      break
	    }
	  }
	}

	cell {
	  # got the cell
	  set type [string trim $line]

	  regsub -all {\{|\}} $line \\\\& munged
	  set timing($type) ""
	  lappend timing($type) $munged
	  while {[gets $FILE_ID line] >= 0} {
	    regsub -all {\{|\}} $line \\\\& munged
	    lappend timing($type) $munged

	    if {[string index $line 0] == "\}"} {
	      # we're done
	      break
	    }
	  }
	}
      }
    }

    # close the file
    close $FILE_ID
  }

  # now write out the library

  puts "library ($LIBRARY_NAME) \{"
  puts "comment : \"Built from MMI char.tcl on [clock format [clock seconds] -format %D]\";"
  puts "delay_model : table_lookup;"

  foreach table [array names lu] {
    foreach line $lu($table) {
      regsub -all {\\} $line "" munged
      puts $munged
    }
  }

  # Pat changed:
  # puts [exec cat $SYNOPSYS_HEADER]

  # puts in synopsys header info
  puts "nom_process                 : 1.0;"
  puts "nom_temperature             : [string trim $DATA(TEMP) Cc];"
  puts "nom_voltage                 : [string trim $DATA(vdd) Vv];"
  puts "pulling_resistance_unit     : \"1kohm\";"
  puts "time_unit                   : \"1ns\";"
  puts "voltage_unit                : \"1V\";"
  puts "current_unit                : \"1A\";"
  puts "capacitive_load_unit (1.0,pf);"

  # put in additional user-specified synopsys header info
  if {[catch "exec cat $DATA(synopsys_header_file)" msg]} {
    puts stderr $msg
  } else {
    puts $msg
  }

  foreach cell [lsort [array names timing]] {
    foreach line $timing($cell) {
      regsub -all {\\} $line "" munged
      regsub -all {\,$} $munged {,\\} munged
      puts $munged
    }
  }

  puts "\}"

  puts stderr "done."
}

if {[llength $argv] < 1} {
  puts "Creates a synopsys library of the .syn files in the current directory"
  puts "Usage:\n"
  puts "make_synlib <corner> > <synopsys_lib>\n"
  puts "Uses a char.setup file in this directory\n"
  exit 
}

make_synlib $argv

exit
