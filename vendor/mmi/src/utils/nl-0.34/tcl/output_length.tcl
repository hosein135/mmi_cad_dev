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

proc get_output_bbox {cell} {
    set out_pins [get_cell_pins -outputs $cell]
    if { $out_pins == {}} {
	return "0 0 0 0"
    } else {
	set out_pin [lindex $out_pins 0]
	set out_net [get_pin_net $out_pin]
	return [get_net_bbox $out_net]
    }
}


proc get_bbox_size {bbox} {
    set xmin [lindex $bbox 0]
    set ymin [lindex $bbox 1]
    set xmax [lindex $bbox 2]
    set ymax [lindex $bbox 3]

    return [expr $xmax - $xmin + $ymax - $ymin]
}


proc get_average_bbox {ref {print 0}} {
    set cells [get_reference_cells $ref]

    set count 0
    set max 0
    set loads 0
    set total 0.0
    set totalsq 0.0

    foreach cell $cells {
	set size [get_bbox_size [get_output_bbox $cell]]
	set num_loads [llength [get_net_pins -noassign -hier [lindex [get_cell_pins -outputs $cell] 0]]]

	incr count
	incr loads $num_loads
	if { $print > 0 } {
	    puts [format "%8d  %5d  $cell" $size $num_loads]
	}

	if { $size > $max } {
	    set max [expr $size + 0.0]
	}

	set total [expr $total + $size]
	set totalsq [expr $totalsq + $size * ($size + 0.0)]
    }

    if { $count == 0 } {
	return "0 0 0 0"
    } else {
	return "$count $max [expr ($loads + 0.0) / $count] [expr $total / $count] [expr $totalsq / $count]"
    }
}


proc get_ref_bboxes {} {
    set refs [lsort [list_references]]

    foreach ref $refs {
	if { $ref == "*assignment*" } {
	    continue
	}

	if { [is_libcell $ref] == 0 } {
	    continue
	}

	set avg [get_average_bbox $ref]
	puts [format "%16s  %6d   %6.2e   %6.2f   %6.2e   %6.2e" $ref [lindex $avg 0] [lindex $avg 1] [lindex $avg 2] [lindex $avg 3] [lindex $avg 4]]
    }
}


proc dump_set_bounds_script {} {
    set refs [lsort [list_references]]

    set bbox(A) 12400
    set bbox(B) 24800
    set bbox(C) 49600
    set bbox(D) 99200

    foreach ref $refs {
	set drive [string index $ref [expr [string length $ref] - 1]]

	if { $drive == "E" } {
	    continue
	}

	set cells [get_reference_cells $ref]
	
	foreach cell $cells {
	    set out_pins [get_cell_pins -outputs $cell]

	    if { $out_pins == {}} {
		continue
	    } else {
		set out_pin [lindex $out_pins 0]
		set out_net [get_pin_net $out_pin]
		set out_pins [get_net_pins -noassign -hierarchy $out_net]
		set owners [lmapcar get_pin_owner $out_pins]

		puts "set_bounds -dim {$bbox($drive) $bbox($drive)} -effort high $owners"
	    }
	}
    }
}
