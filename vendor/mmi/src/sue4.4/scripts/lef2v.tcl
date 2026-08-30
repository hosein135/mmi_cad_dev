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

# Reads a lef file and creates verilog module headers from it

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


proc lef2v {filename} {

  if {[catch "open $filename r" msg]} {
    # error
    puts stderr "Aborting, $msg"
    exit
  } 
  set FILE_ID $msg

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

    while {[gets $FILE_ID line] >= 0} {
      set word [lindex $line 0]
      if {$word == "END"} {
	if {$level == 0} {
	  break
	} else {
	  incr level -1
	}
      }

      if {$word == "OBS"} {
	incr level
      }

      if {$word == "PORT"} {
	incr level
      }

      if {$word == "PIN"} {
	set pin_name [lindex $line 1]

	while {[gets $FILE_ID line] >= 0} {
	  set word [lindex $line 0]
	  if {$word == "END"} {
	    # this is a pin
	    set root [lindex [split $pin_name \[] 0]
	    lappend pin_names($root) $pin_name
	    set pin_types($root) $dir

	    break
	  }

	  if {$word == "DIRECTION"} {
	    set dir [lindex $line 1]
	  }

          if {$word == "USE"} {
	    incr level
	    break
	  }

          if {$word == "PORT"} {
	    incr level
	  }
	}
      }
    }

    # write out the module
    set pins [lsort [array names pin_names]]

    puts "module $name ([join $pins ,]);"

    foreach pin $pins {
      if {[lindex $pin_names($pin) 1] == ""} {
	# scalar
	puts "\t$pin_types($pin)\t\t$pin;"
      } else {
	# vector
	set max 0
	set min 10000
	foreach bit $pin_names($pin) {
	  set value [lindex [split $bit \[\]] 1]
	  set max [max $max $value]
	  set min [min $min $value]
	}

	puts "\t$pin_types($pin)\t\[$max:$min\]\t$pin;"
      }
    }

    puts "endmodule\n"
  }

  # close the file
  close $FILE_ID

  puts stderr "done."
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

eval lef2v $argv

exit
