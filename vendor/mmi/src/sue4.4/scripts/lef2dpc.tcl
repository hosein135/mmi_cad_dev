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

# Written by Lee Tavrow, 1998

# Reads a LEF file and creates a dpc file that contains size information for
# the SUE Data Path compiler.

set LEFFILE tsmc25.lef
set DPCFILE tsmc25.dpc

# Technology information

# This grid is um's per grid
set DPGRID 1.0

# This is the default cell height in grids
set DEFAULT_HEIGHT 10


proc lef2dpc {} {

  global LEFFILE DPCFILE DPGRID DEFAULT_HEIGHT

  set count 0

  # open the lef file for reading
  if {[catch "open $LEFFILE r" LEF_ID]} {
    # problem
    puts "lef2dpc error: $LEF_ID"
    exit 1
  }

  # open the cell sizes file for writing
  if {[catch "open $DPCFILE w" FILE_ID]} {
    # problem
    puts "lef2dpc error: $FILE_ID"
    exit 1
  } 

  puts "Parsing $LEFFILE ..."

  # look for a line of the form:
  # MACRO <name>
  # SIZE <x> BY <y> ;
  # END <name>

  set cell ""
  while {[gets $LEF_ID line] >= 0} {
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

      if {$height == $DEFAULT_HEIGHT} {
	set height ""
      } else {
	set height [format "%g" $height]
      }

      # write to DPCFILE file
      puts $FILE_ID [format "$cell %g $height" $width]

      incr count
    }
  }

  # close the file
  close $LEF_ID

  # close the dpc file
  close $FILE_ID

  puts "Wrote SUE DPC size file $DPCFILE with $count cells."
}


# do it
lef2dpc
exit 1
