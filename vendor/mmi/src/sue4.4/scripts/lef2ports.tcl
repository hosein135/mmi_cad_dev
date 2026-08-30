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

# Written by Lee Tavrow, 1997

# Reads a lef file and creates SUE dpc bbox and port locations file.

# parses something of the form

#MACRO INVA
#	CLASS CORE ;
#	FOREIGN INVA 0.00 0.00 ;
#	SIZE 4.2 BY 14 ;
#	SYMMETRY X Y ;
#	SITE CORE1 ;
#	PIN VDD
#		DIRECTION inout ;
#		USE POWER ;
#		SHAPE ABUTMENT ;
#		PORT
#			LAYER M1 ;
#			RECT 0 13 4.2 14 ;
#		END
#	END VDD
#	PIN in
#		DIRECTION input ;
#		PORT
#			LAYER M2 ;
#			RECT 1.7 5.9 2.5 6.7 ;
#		END
#	END in
#	OBS
#		LAYER M1 ;
#		RECT 0 1.5 4.2 12.5 ;
#	END
#END INVA


set multiplier 1
set GRID 1.4

proc lef2ports {filename {orient N}} {

  global GRID multiplier

  if {[catch "open $filename r" FILE_ID]} {
    # error
    puts stderr "Aborting, $FILE_ID"
    exit
  } 

  puts stderr "parsing $filename ..."

  while {[gets $FILE_ID line] >= 0} {

    if {[lindex $line 0] != "MACRO"} {
      continue
    }

    # found a cell
    set name [lindex $line 1]
    set level 0
    catch {unset pin_names}
    catch {unset pin_types}

    set x_offset 0
    set y_offset 0

    while {[gets $FILE_ID line] >= 0} {
      set word [lindex [string trim $line] 0]
      if {$word == "END"} {
	if {$level == 0} {
	  break
	} else {
	  incr level -1
	}
      }

      if {$word == "FOREIGN"} {
	# might be an offset
	regsub -all \; $line "" line
	setl {foreign name x_offset y_offset} $line
      }

      if {$word == "SIZE"} {
	regsub -all \; $line "" line
	setl {size dx by dy} $line
      }

      if {$word == "OBS"} {
	incr level
      }

      if {$word == "PIN"} {
	set pin_name [lindex $line 1]

	set string $line
	while {[gets $FILE_ID line] >= 0} {
	  setl {word1 word2} $line
	  if {$word1 == "END" && $word2 == $pin_name} {
	    # done with this pin
	    break
	  }

	  set string [concat $string $line]
	}

	regsub DIRECTION $string "\; DIRECTION" string
	set lines [split $string \;]

	foreach line $lines {

	  set word [lindex $line 0]

	  if {$word == "DIRECTION"} {
	    set dirs($pin_name) [lindex $line 1]
	  }

	  if {$word == "USE" && [lindex $line 1] != "SIGNAL"} {
	    # ignore non-signals
	    break
	  }

	  if {$word == "RECT" || $word == "PATH"} {
	    # remember all the rectangles
	    lappend rects($pin_name) [lrange $line 1 4]
	  }
	}
      }
    }

    if {![info exists dx]} {
      puts stderr "Aborting, lef doesn't include size."
      return
    }

    # write out the module
    puts "\# Created by lef2ports from cell $filename"

    set grid [expr $GRID * $multiplier]
    set dxg [expr 1.0 * $dx / $grid]
    set dyg [expr 1.0 * $dy / $grid]

    puts "bbox [round $dxg] [round $dyg]"

    if {[round $dxg] != $dxg || [round $dyg] != $dyg} {
      puts stderr "WARNING, bounding box of cell not an integer number of grids.  Rounding up."
    }

    if {$orient != ""} {
      puts "orient $orient"
    }

    foreach pin [array names rects] {
      set minx 1.0e9
      set maxx -1.0e9
      set miny 1.0e9
      set maxy -1.0e9
      # get center point of rectangles
      foreach rect $rects($pin) {
	setl {x1 y1 x2 y2} $rect
	set minx [min $minx [min $x1 $x2]]
	set maxx [max $maxx [max $x1 $x2]]
	set miny [min $miny [min $y1 $y2]]
	set maxy [max $maxy [max $y1 $y2]]
      }

      puts "port $pin [round [expr (($minx + $maxx) / 2.0 - $x_offset) / $grid]] [round [expr (($miny + $maxy) / 2.0 - $y_offset) / $grid]]"
    }
  }

  # close the file
  close $FILE_ID

  puts stderr "done."
}


proc round {num} {

  return [expr ceil($num)]
#  return [expr round($num*10) / 10.0]
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


# returns maximum of two numbers

proc max {a b} {

  if {$a > $b} {
    return $a

  } else {
    return $b
  }
}

# returns minimum of two numbers

proc min {a b} {

  if {$a < $b} {
    return $a

  } else {
    return $b
  }
}


# do it

if {$argv == ""} {
  puts "Usage:\n"
  puts "\tlef2ports <lef_file> \[orientation (defaults to N)\]\n"

} else {
  eval lef2ports $argv
}

exit
