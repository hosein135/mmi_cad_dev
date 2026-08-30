## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
## ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
## JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
## DAMAGE.
## 
## JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
## UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************

proc write_move_bounds {n file} {
    set count 0
    set ofp [open $file w]
    for { set i 0 } { $i < $n } { incr i } {
	set x1 [expr ($n - $i - 1) * 24]
	set y1 0
	set x2 [expr ($n - $i) * 24]
	set y2 720
	set cells [find_cells *\$$i\$*]
	set good_cells {}
	foreach cell $cells {
	    if { [get_cell_location $cell] != {-1 -1} } {
		if { [regexp .*\[Cc\]tl.* $cell] == 0 } {
		    lappend good_cells $cell
		}
	    }
	}
	regsub -all \\\$ $good_cells \\\$ good_cells
	foreach good_cell $good_cells {
	    puts $ofp "set_bounds -coordinate {$x1 $y1 $x2 $y2} $good_cell"
	}

	set count [expr $count + [llength $good_cells]]
    }
    close $ofp
    puts "Set move bounds for $count cells."
}

proc check_cells {} {
    foreach cell [list_cells -noassign] {
	set location [get_cell_location $cell]
	set x [lindex $location 0]
	if { $x >= 1536000 } {
	    if { [regexp .*\[Cc\]tl.* $cell] == 0 } {
		puts $cell
	    }
	}
    }
}
