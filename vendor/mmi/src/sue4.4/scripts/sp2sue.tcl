## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

#!/bin/csh -f
 
# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit
 
# Script to convert spice netlists to SUE schematics.
# pfets/nfets are placed randomly in 2 rows and connected by name.
# Written by Lee Tavrow, 1998

set TYPE(VSS) global
set TYPE(VDD) global
set TYPE(Y) output
set TYPE(_DEFAULT_) input

# the offset of the port on the fet
set OFFSET(n,d) "0 40 RY"
set OFFSET(n,g) "-60 0"
set OFFSET(n,s) "0 -40"
set OFFSET(p,d) "0 -40"
set OFFSET(p,g) "-60 0"
set OFFSET(p,s) "0 40 RY"

set FLIP(RY) ""
set FLIP() "RY"

# parse the spice file

proc parse_sp {filename} {

  global DATA

  puts stderr "Parsing file $filename ..."

  if {[catch "open $filename r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    exit
  } 

  # first read and merge continuations
  set lines ""
  set current ""
  while {[gets $FILE_ID line] >= 0} {

      set line [string trim $line]
      
      if {[string index $line 0] == "+"} {
	  # continuation
	  set line [string trim [string range $line 1 end]]
	  append current $line
      } elseif {[string index $line 0] == "*"} {
	  # comment, ignore
      } else {
	  # not a continuation, save the last line
	  if {$current != ""} {
	      lappend lines $current
	  }
	  set current $line
      }
  }

  if {$current != ""} {
      lappend lines $current
  }

  # close the file
  close $FILE_ID


  # now parse
  set name ""
  foreach line $lines {

      if {[lindex $line 0] == ".SUBCKT"} {
	  # found a subckt
	  set name [lindex $line 1]
	  lappend DATA(NAMES) $name
	  set DATA($name,args) [lrange $line 2 end]
	  continue
      } elseif {[lindex $line 0] == ".ENDS"} {
	  set name ""
	  continue
      }

      switch [string index $line 0] {
	  M {
	      # fet
	      lappend DATA($name,fets) $line
	  }
	  C {
	      # capacitor
	      lappend DATA($name,caps) $line
	  }
	  default {
	      puts "Syntax Error: $line"
	  }
      }
  }
}



proc build_sue {} {
    
    global DATA

    foreach name $DATA(NAMES) {

	puts "building schematic for $name ..."
	set schematic [build_schematic $name]
	# put a blank line at the end
	lappend schematic ""

	# strip out old schematic
	if {[file exists $name.sue]} {
	    # strip out the old schematic if there is one
	    catch "exec mv -f $name.sue $name.sue.old"

	    
	    if {[catch "open $name.sue.old r" FILE_ID]} {
		# error
		puts stderr "Aborting, $FILE_ID"
		exit
	    } 
	    
	    set lines ""
	    set in_proc 0
	    while {[gets $FILE_ID line] >= 0} {
		if {[string range $line 0 7] == "proc SCH"} {
		    set in_proc 1
		    continue
		}
		if {$in_proc && [string index $line 0] == "\}"} {
		    set in_proc 0
		    continue
		}
		if {$in_proc} {
		    continue
		}
		lappend lines $line
	    }

	    # close the file
	    close $FILE_ID

	    exec echo [join $lines \n] > tmp2

	} else {
	    puts "new cell (no file $name.sue)"
	    exec touch tmp2
	}
	
	# add new schematic
	exec echo [join $schematic \n] > tmp
	exec cat tmp tmp2 > $name.sue
    }
}


proc build_schematic {name} {
    
    global DATA TYPE OFFSET FLIP

    set schem ""

    lappend schem "proc SCHEMATIC_$name \{\} \{"

    # put in the name of the cell
    lappend schem "\tmake_text -origin \{0 0\} -text $name -size large"

    catch {unset type}
    set y 100

    # figure out the arguments
    foreach arg [lsort $DATA($name,args)] {

	if {[info exists TYPE($arg)]} {
	    set type($arg) $TYPE($arg)
	} else {
	    set type($arg) $TYPE(_DEFAULT_)
	}
	
	if {$type($arg) == "global"} {
	    continue
	}
	
	# make the pin
	lappend schem "\tmake $type($arg) -name $arg -origin \{0 $y\}"
	
	incr y 40
    }
    
    set xp 200
    set yp 200
    set xn 200
    set yn 400
    foreach fet $DATA($name,fets) {
	# ignore the bulk -- it is wrong anyways
	setl {fetname d g s b pn} $fet

	set pn [string tolower $pn]

	# first put in the name_net's/globals attached to each fet
	foreach net "d g s" {
	    set name [set $net]
	    setl {xoff yoff orient} $OFFSET(${pn},$net)

	    if {![info exists type($name)]} {
		# must be an internal net
		set type($name) inernal
	    }

	    if {$type($name) == "global"} {
		set net_type global
		set orient $FLIP($orient)
	    } else {
		set net_type name_net_s
	    }

	    if {$orient != ""} {
		set args " -orient $orient"
	    } else {
		set args ""
	    }
	    set x [expr [set x$pn] + $xoff]
	    set y [expr [set y$pn] + $yoff]

	    lappend schem "\tmake $net_type -name $name -origin \{$x $y\}$args"
	}

	# now make the fet
	set args ""
	set w [string tolower \
		   [lindex [split [lindex $fet [lsearch $fet "W=*"]] =] 1]]
	if {$w != ""} {
	    # unit of microns
	    append args " -W [expr 1.0e6 * [parse_pp_number $w]]"
	}
	set l [string tolower \
		   [lindex [split [lindex $fet [lsearch $fet "L=*"]] =] 1]]
	if {$l != ""} {
	    # unit of microns
	    set value [expr 1.0e6 * [parse_pp_number $l]]
	    if {$value != 0.18} {
		append args " -L ${value}u"
	    }
	}

	case $pn {
	    p {
		lappend schem "\tmake pmos -origin \{$xp $yp\}$args"
		incr xp 200
	    }
	    n {
		lappend schem "\tmake nmos -origin \{$xn $yn\}$args"
		incr xn 200
	    }
	}
    }
    lappend schem "\}"

    return $schem
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


# Pretty prints a number using the spice metric suffixes 
 
proc pp_number {num {format %g%s}} { 
  set num [parse_pp_number $num] 
 
  if {$num == 0} { 
    return 0 
  } 
  set suffixes {G M K "" m u n p f a} 
  set logscale [expr floor(log10(abs($num))/3.0)] 
  set mantissa [expr $num/pow(10,3.0*$logscale)] 
  set exp [lindex $suffixes [expr round(3 - $logscale)]] 
  return [format $format $mantissa $exp] 
} 
 
 
# Parses a string with spice notation into a number.  Trailing units 
# are ignored.  Examples: 3.2e-4, 32.4fF, 23 Ohms 
 
proc parse_pp_number {string} { 
  regexp -indices -nocase {[a-d]|[f-z]} $string index 
   
  if {[info exists index] == 0} { 
    return $string 
  } 
 
  set mantissa [string range $string 0 [expr [lindex $index 0]-1]] 
 
  set suffixes "GMK munpfa" 
  set suffix [string range $string [lindex $index 0] [lindex $index 1]] 
  set pos [string first $suffix $suffixes] 
  if {$pos == -1} { 
    return $mantissa 
  } 
  set num [expr $mantissa * pow(10,3.0*(3-$pos))] 
  return $num 
} 
 




# do it
parse_sp $argv
build_sue

exit
