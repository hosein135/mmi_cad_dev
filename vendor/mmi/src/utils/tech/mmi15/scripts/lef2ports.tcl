#!/bin/csh -f

# The next line will be skipped in TCL because of the backslash \
mmi_wish -f $0 $* ; exit

# Written by Lee Tavrow, 1997

# JDJ 991117: Added 'grids per row' as the 3rd parameter for rounding
# up the Y size to a multiple of the row size.  Default is 1.

# JDJ 991213: Don't ignore 'USE CLOCK' pins

# JDJ 000628: Changed default grids per row to 10.
# JDJ 010321: GRID to 0.62, for mmi15

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
set GRID 0.62

proc lef2ports {filename {orient N} {grids_per_row 10}} {

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
	regsub LAYER $string "\; LAYER" string
	regsub PORT $string "PORT \;" string

	set lines [split $string \;]

	foreach line $lines {

	  set word [lindex $line 0]

	  if {$word == "DIRECTION"} {
	    set dirs($pin_name) [lindex $line 1]
	  }

	  if {$word == "USE" && [lindex $line 1] != "SIGNAL" && [lindex $line 1] != "CLOCK"} {
	    # ignore non-signals
	    break
	  }

	  if {$word == "RECT" || $word == "PATH"} {
	    # remember all the rectangles
	    lappend rects($pin_name) [lrange $line 1 2]
	    lappend rects($pin_name) [lrange $line 3 4]
	  }
	  if {$word == "POLYGON"} {
	    # remember all polygons
	    for {set coords [lrange $line 1 end]} {[llength $coords] > 1} \
		{set coords [lrange $coords 2 end]} {
  	      lappend rects($pin_name) [lrange $coords 0 1]
	    }
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
    # JDJ 991117: Round up to a multiple of grids per row.
    set dyg [expr ceil($dyg / $grids_per_row ) * $grids_per_row]

    puts "bbox [round $dxg] [round $dyg]"

    if {[round $dxg] != $dxg || [round $dyg] != $dyg} {
      puts stderr "WARNING, bounding box of cell not an integer number of grids."
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
	setl {x1 y1} $rect
	set minx [min $minx $x1]
	set maxx [max $maxx $x1]
	set miny [min $miny $y1]
	set maxy [max $maxy $y1]
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
  puts "Usage:"
  puts "\tlef2ports <lef_file> \[orientation \[grids per row\]\] > <ports_file>"
  puts "\t\torientation default:\tN"
  puts "\t\tgrids per row default:\t1\n"

} else {
  eval lef2ports $argv
}

exit
