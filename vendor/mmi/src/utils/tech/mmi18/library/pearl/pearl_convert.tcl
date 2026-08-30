#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit

# Written by Lee Tavrow, 1997

# Ties off all inputs which are not in the critical path to the 
# correct positions so the critical path works.

# Rearranges calling order of pins in instances to match subckts.

# Adds spice subckt definitions for all gates.

set ROOT /volume/mmi_proj/proj/tech/mmi18

#set SUBCKT(path) "$ROOT/char"
set SUBCKT(path) "$ROOT/stdcell/extract"
set SUBCKT(suffix) .sp
set SUBCKT(ties) "$ROOT/library/pearl/pearl.ties"

proc munge_file {file} {

  global CELL SUBCKT_DATA TIES

  load_tie_data

  set UNIQUE 0
  set UNIQUE_net 0

  # first parse the file to get the pin orderings of subckt calls
  set FILE_ID [open $file r]
     
  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] != ".subckt"} {
      continue
    }

    set CELL([lindex $line 1]) [lrange $line 2 end]
    while {[gets $FILE_ID cline] >= 0} {
      if {[string index $cline 0] != "+"} {
	break
      }

      # found a continuation line
      set CELL([lindex $line 1]) [concat $CELL([lindex $line 1]) \
				      [string range $cline 1 end]]
    }
  }

  # close the file
  close $FILE_ID

  # now build the new netlist
  set FILE_ID [open $file r]

  puts "*** Pearl critical path spice netlist\n***"
  puts "*** MUNGED SPICE NETLIST\n***"

  set start 1

  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == ".subckt"} {
      break
    }

    if {[lindex $line 1] != "Stage"} {
      puts $line
      continue
    }

    if {$start} {
      puts "***\n*** BEGIN MUNGED PART\n***"
      set start 0
    }

    gets $FILE_ID line
    if {[lindex $line 1] == ""} {
      # skip first one -- probably a wire
      continue
    }

    if {[lindex $line 0] == ".subckt"} {
      break
    }

    puts $line

    # need to munge this line
    gets $FILE_ID call_line

    if {[string toupper [string index $call_line 0]] != "X"} {
      # Not a subckt call, continue
      continue
    }

    # FIX probably need to deal with long lines

    set len [llength $call_line]
    set type [lindex $call_line [incr len -1]]
    incr len -1

    set tie_line_simple [list $type [lindex $line 2]]
    set tie_line_fancy [list $type [lrange $line 2 end]]

    set rest [lrange $call_line 1 end]
    set assoc ""
    for {set i 0} {$i < $len} {incr i} {
      set net [lindex $rest $i]
      # look for non numeric-only names
      if {[catch "expr $net + 1"]} {
	# must not be in the critical path, tie off
	set net tie[incr UNIQUE_net]
      } else {
	# don't tie off numeric nodes
	set VS($net) 1
      }

      lappend assoc "[lindex $CELL($type) $i] $net"
    }

    lookup_subckt $type

    set ios [lrange [lindex $SUBCKT_DATA($type) 0] 2 end]

    set rest [lrange $SUBCKT_DATA($type) 1 end]
    while {[string index [lindex $rest 0] 0] == "+"} {
      # continuation line
      set ios [concat $ios [string range [lindex $rest 0] 1 end]]
      set rest [lrange $rest 1 end]
    }

    set nets ""
    foreach io $ios {
      set net [get_assoc $io $assoc]
      if {$net != ""} {
	lappend nets $net
      } else {
	set net tie[incr UNIQUE_net]
	lappend nets $net
	lappend assoc "$io $net"
      }
    }

    # here is the new call
    puts "[lindex $call_line 0] $nets $type"

    # now tie off non-driven inputs
    foreach tie_line [list $tie_line_fancy $tie_line_simple] {
      if {[info exists TIES($tie_line)]} {
	foreach pair $TIES($tie_line) {
	  setl {net value} $pair
	  set vs [get_assoc $net $assoc]
	  if {![info exists VS($vs)]} {
	    set VS($vs) 1
	    puts "VTIE$UNIQUE $vs gnd $value"
	    incr UNIQUE
	  }
	}
	break
      }
    }
  }

  while {[gets $FILE_ID line] >= 0} {
    if {[lindex $line 0] == ".TRAN"} {
      set line ".TRAN 5P [lindex $line 2]"
      break
    }
  }

  puts "***\n*** SUBCKT defs ***\n***"
  foreach def [array names SUBCKT_DATA] {
    puts [join $SUBCKT_DATA($def) \n]
    puts "*"
  }

  puts "***\n*** END MUNGED PART\n***"
  puts $line

  while {[gets $FILE_ID line] >= 0} {
    puts $line
  }

  # close the file
  close $FILE_ID
}


proc lookup_subckt {name} {

  global SUBCKT SUBCKT_DATA

  foreach dir $SUBCKT(path) {
    set file $dir/$name$SUBCKT(suffix)
    if {[file exists $file]} {
      break
    }
  }

  set FILE_ID [open $file r]

  while {[gets $FILE_ID line] >= 0} {
    if {[string toupper [lindex $line 0]] != ".SUBCKT"} {
      continue
    }

    set type [lindex $line 1]
    if {[info exists SUBCKT_DATA($type)]} {
      # already got this one
      continue
    }

    set subckt ""
    lappend subckt $line

    while {[gets $FILE_ID line] >= 0} {
      lappend subckt $line

      if {[lindex $line 0] == ".ENDS"} {
	set SUBCKT_DATA($type) $subckt
	break
      }
    }
  }

  # close the file
  close $FILE_ID
}


# Reads in the file that tells us what inputs (if any) to tie off and
# to which rail.

proc load_tie_data {} {

  global SUBCKT TIES

  if {[catch "open $SUBCKT(ties) r" FILE_ID]} {
    # problem
    puts "PEARL CONVERT ERROR: $FILE_ID"
    return
  }

  # now read in the table
  while {[gets $FILE_ID line] >= 0} {
    set name [lindex $line 0]

    if {$name == "" || [string index $name 0] == "\#"} {
      # comment, skip
      continue
    }

    if {[lindex $line 1] == "="} {
      # special case assignment.  copy gate info

      setl {new equal old} $line

      foreach one [array names TIES "$old *"] {
	set TIES([list $new [lindex $one 1]]) $TIES($one)
      }

      continue
    }

    set TIES([lrange $line 0 1]) [lrange $line 2 end]
  }

  # close the file
  close $FILE_ID
}


# sets the nth variable name to be the nth value

proc setl {names values} {
  set i 0
  foreach name $names {
    uplevel [list set $name [lindex $values $i]]
    incr i
  }
  # returns number of variables set
  return $i
}


# Gets the value out of an associative list keyed by arg.  If the optional
# index is given, will get the "index" value out of the list which is
# used for getting the default value.

proc get_assoc {name list {nth 1}} {

  set index [lsearch $list "$name *"]
  if {$index == -1} {
    # no match
    return ""
  }

  return [lindex [lindex $list $index] $nth]
}

munge_file [lindex $argv 0]

exit
