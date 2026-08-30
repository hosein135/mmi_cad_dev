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

proc nl_get_cell_or_port_midpoint {arg} {
    global libcell_size

    set type [nl_object_type $arg]

    if { $type == "cell" || $type == "port" } {
	set cell_or_port $arg
    } elseif { $type == "string" } {
	set cell [lindex [nl_find_cells -exact $arg] 0]
	if { $cell != "" } {
	    set cell_or_port $cell
	    set type "cell"
	} else {
	    set port [lindex [nl_find_ports -exact $arg] 0]
	    if { $port != "" } {
		set cell_or_port $port
		set type "port"
	    } else {
		error "Cannot find cell or port named $arg."
	    }
	}
    } else {
	error "get_cell_or_port_midpoint requires an argument that is a cell, port, or string."
    }

    if { $type == "cell" } {
	set loc [nl_get_cell_location $cell_or_port]
	if { $loc == {} } {
	    return {}
	}
	set ref [nl_get_cell_reference $cell_or_port]
	set ref_name [nl_get_reference_name $ref]
	if { [info exists libcell_size($ref_name)] == 0 } {
	    set size {0 0}
	} else {
	    set size $libcell_size($ref_name)
	}
	set midx [expr int([lindex $loc 0] + [lindex $size 0] / 2.0)]
	set midy [expr int([lindex $loc 1] + [lindex $size 1] / 2.0)]
    } else {
	set loc [nl_get_port_location $cell_or_port]
	if { $loc == {} } {
	    return {}
	}
	set midx [lindex $loc 0]
	set midy [lindex $loc 1]
    }

    return "$midx $midy"
}


proc nl_get_net_bbox args {
    nl_getopt nl_get_net_bbox "Return the physical bounding box of the specified net." {
    } {
	{net net "get the bounding box of this net"}
    } $args

    set xmin 1e100
    set ymin 1e100
    set xmax -1e100
    set ymax -1e100

    set pins [nl_get_net_pins -noassign $net]

    foreach pin $pins {
        set loc [nl_get_pin_location $pin]
	
	if { $loc == {} } {
	    continue
	}

	set x [lindex $loc 0]
	set y [lindex $loc 1]
		
	if { $x > $xmax } {
	    set xmax $x
	}
	if { $y > $ymax } {
	    set ymax $y
	}
	if { $x < $xmin } {
	    set xmin $x
	}
	if { $y < $ymin } {
	    set ymin $y
	}
    }

    if { $xmin == 1e100 } {
	return "0 0 0 0"
    } else {
	return "$xmin $ymin $xmax $ymax"
    }
}


nl_register_command nl_get_net_bbox
