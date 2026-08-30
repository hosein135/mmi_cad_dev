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

proc get_cell_or_port_midpoint {arg} {
    upvar libcell_size libcell_size
    upvar port_locations port_locations

    set type [object_type $arg]

    if { $type == "cell" || $type == "port" } {
	set cell_or_port $arg
    } elseif { $type == "string" } {
	set cell [lindex [find_cells -exact $arg] 0]
	if { $cell != "" } {
	    set cell_or_port $cell
	    set type "cell"
	} else {
	    set port [lindex [find_ports -exact $arg] 0]
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
	set loc [get_cell_location $cell_or_port]
	if { [lindex $loc 0] == -1 || [lindex $loc 1] == -1 } {
	    error "Cell $arg has no location."
	}
	set ref [get_cell_reference $cell_or_port]
	set ref_name [get_reference_name $ref]
	if { [info exists libcell_size($ref_name)] == 0 } {
	    error "No libcell_size for $ref_name"
	}
	set size $libcell_size($ref_name)
	set midx [expr int([lindex $loc 0] + [lindex $size 0] / 2.0)]
	set midy [expr int([lindex $loc 1] + [lindex $size 1] / 2.0)]
    } else {
	if { [info exists port_locations($cell_or_port)] == 0 } {
	    set bad_p $cell_or_port
	    error "No port location for port $cell_or_port ([object_type $cell_or_port])."
	}
	set loc $port_locations($cell_or_port)
	set midx [lindex $loc 0]
	set midy [lindex $loc 1]
    }

    return "$midx $midy"
}


proc get_net_bbox {net} {
    set xmin 1e100
    set ymin 1e100
    set xmax -1e100
    set ymax -1e100

    set pins [get_net_pins -hier -noassign $net]

    if { $pins == {} } {
	return "0 0 0 0"
    }

    foreach pin $pins {
	set owner [get_pin_owner $pin]
	set loc [get_cell_or_port_midpoint $owner]

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

    return "$xmin $ymin $xmax $ymax"
}


proc find_spot_for_port {loc min_loc max_loc locs_taken} {
    upvar $locs_taken taken
    set loc0 $loc
    set loc1 $loc
	
    while { [info exists taken($loc0)] == 1 && $loc0 > $min_loc } {
	incr loc0 -1000
    }

    while { [info exists taken($loc1)] == 1 && $loc1 < $max_loc } {
	incr loc1 1000
    }
	    
    if { $loc0 > $min_loc && $loc1 < $max_loc } {
	if { $loc - $loc0 < $loc1 - $loc } {
	    return $loc0
	} else {
	    return $loc1
	}
    } elseif { $loc0 > $min_loc } {
	return $loc0
    } elseif { $loc1 < $max_loc } {
	return $loc1
    } else {
	error "Could not find a spot on the $locs_taken for port $port"
    }
}


proc assign_port_location {port {verbose 0}} {
    upvar bottom bottom
    upvar top top
    upvar left left
    upvar right right
    upvar die_x0 die_x0
    upvar die_y0 die_y0
    upvar die_x1 die_x1
    upvar die_y1 die_y1
    upvar libcell_size libcell_size

    set net [get_pin_net [get_port_pin $port]]
    set xmin [expr $die_x1 + 1]
    set ymin [expr $die_y1 + 1]
    set xmax -1
    set ymax -1

    foreach pin [get_net_pins -hier -noassign $net] {
	set owner [get_pin_owner $pin]
	if { [object_type $owner] == "cell" } {
	    set loc [get_cell_or_port_midpoint $owner]
	    set x [lindex $loc 0]
	    set y [lindex $loc 1]
	    
	    if { $verbose > 1 } {
		puts "  pin $pin: owner=$owner, x=$x, y=$y"
	    }

	    if { $x > $xmax } {
		set xmax $x
		set xmaxy $y
	    }
	    if { $y > $ymax } {
		set ymax $y
		set ymaxx $x
	    }
	    if { $x < $xmin } {
		set xmin $x
		set xminy $y
	    }
	    if { $y < $ymin } {
		set ymin $y
		set yminx $x
	    }
	}
    }

    if { $verbose > 0 } {
	puts "xmin = $xmin"
	puts "xmax = $xmax"
	puts "ymin = $ymin"
	puts "ymax = $ymax"
    }

    set xright [expr $die_x1 - $xmax]
    set ytop   [expr $die_y1 - $ymax]
    
    if { $xmin < $xright } {
	set xnearest $xmin
	set portx $die_x0
	set portxy $xminy
    } else {
	set xnearest $xright
	set portx $die_x1
	set portxy $xmaxy
    }
    
    if { $ymin < $ytop } {
	set ynearest $ymin
	set porty $die_y0
	set portyx $yminx
    } else {
	set ynearest $ytop
	set porty $die_y1
	set portyx $ymaxx
    }
    
    if { $xnearest < $ynearest } {
	set porty $portxy
    } else {
	set portx $portyx
    }
    
    if { $porty == $die_y0 } {
	# port is on the bottom
	set portx [find_spot_for_port $portx $die_x0 $die_x1 bottom]
	set bottom($portx) $port
    } elseif { $porty == $die_y1 } {
	# port is on the top
	set portx [find_spot_for_port $portx $die_x0 $die_x1 top]
	set top($portx) $port
    } elseif { $portx == $die_x0 } {
	# port is on the left
	set porty [find_spot_for_port $porty $die_y0 $die_y1 left]
	set left($porty) $port
    } elseif { $portx == $die_x1 } {
	# port is on the right
	set porty [find_spot_for_port $porty $die_y0 $die_y1 right]
	set right($porty) $port
    } else {
	error "Computed a bad port location: ($portx, $porty)"
    }
    
    return "$portx $porty"
}


proc assign_port_locations {} {
    upvar port_locations port_locations
    upvar libcell_size libcell_size

    set die_area [get_die_area]
    set die_x0 [lindex $die_area 0]
    set die_y0 [lindex $die_area 1]
    set die_x1 [lindex $die_area 2]
    set die_y1 [lindex $die_area 3]

    foreach port [list_ports] {
	set port_locations($port) [assign_port_location $port]
    }
}


proc fudge_port_locations {} {
    upvar port_locations port_locations

    foreach port [list_ports] {
	set loc $port_locations($port)
	set x [lindex $loc 0]
	set y [lindex $loc 1]

	if { $y == 0 } {
	    incr y -1000
	} else {
	    incr y 1000
	}

	set port_locations($port) "$x $y"
    }
}


proc report_wire_lengths {} {
    upvar port_locations port_locations
    upvar libcell_size libcell_size

    set die_area [get_die_area]
    set die_x0 [lindex $die_area 0]
    set die_y0 [lindex $die_area 1]
    set die_x1 [lindex $die_area 2]
    set die_y1 [lindex $die_area 3]
    set grand_total 0
    set grand_total_x 0
    set grand_total_y 0

    foreach net [list_nets -hier -noassign] {
	if { $xmax >= 0 && $ymax >= 0 } {
	    set xside [expr $xmax - $xmin]
	    set yside [expr $ymax - $ymin]
	    set total [expr $xside + $yside]
	    puts [format "%-64s:  %8d  %8d    %8d" $net $xside $yside $total]
	    incr grand_total_x $xside
	    incr grand_total_y $yside
	    incr grand_total $total
	} else {
	    puts [format "%-64s:  no connections" $net]
	}
    }

    puts ""
    puts "grand total is $grand_total (horizontal=$grand_total_x, vertical=$grand_total_y)"
    puts ""
}


proc write_port_locations_as_pdef {file} {
    upvar port_locations port_locations

    set ofp [open $file "w"]

    foreach port [list_ports] {
	set loc $port_locations($port)
	set x [lindex $loc 0]
	set y [lindex $loc 1]

	puts $ofp "  (PIN $port (LOC $x $y))"
    }

    close $ofp
}


proc write_port_locations_as_def {file} {
    upvar port_locations port_locations

    set ofp [open $file "w"]
    set ports [list_ports]

    puts $ofp "PINS [llength $ports] ;"

    foreach port $ports {
	set loc $port_locations($port)
	set x [lindex $loc 0]
	set y [lindex $loc 1]

	puts -nonewline $ofp "- $port"
	puts -nonewline $ofp " + NET $port"
	puts -nonewline $ofp " + PLACED ( $x $y ) N "
	puts $ofp ";"
    }

    puts $ofp "END PINS"

    close $ofp
}


proc write_port_locations_as_tcl {file} {
    upvar port_locations port_locations

    set ofp [open $file "w"]
    set ports [list_ports]

    foreach port $ports {
	set loc $port_locations($port)
	set x [lindex $loc 0]
	set y [lindex $loc 1]

	regsub -all "\\\[" $port "\\\[" port
	regsub -all "\\\]" $port "\\\]" port
	regsub -all "\\\$" $port "\\\$" port

	puts $ofp "set port_locations($port) {$x $y}"
    }

    close $ofp
}
