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

# inputs: 
# verilog_file
# width (bits) 
# height (rows)
# track_spacing
# tracks_per_bit
# tracks_per_row
# def_units
# signal_layers
# core_site
# vertical_layer
# horizontal_layer
# metal_width

proc plan_setup {} {
    global verilog_file
    global width
    global height
    global track_spacing
    global tracks_per_bit
    global tracks_per_row
    global def_units
    global signal_layers
    global core_site
    global vertical_layer
    global metal_width

    set track_spacing_units [expr int($track_spacing * $def_units)]
    set half_track_spacing_units [expr int($track_spacing_units / 2)]
    set width_tracks [expr int($width * $tracks_per_bit)]
    set height_tracks [expr int($height * $tracks_per_row)]
    set width_units [expr int($width_tracks * $track_spacing_units)]
    set height_units [expr int($height_tracks * $track_spacing_units)]
    set first_track [expr int($track_spacing_units / 2)]

    read_verilog $verilog_file
    link -s

    create_pdesign

    global top_bits
    global bottom_bits

    set top_bits 0
    set bottom_bits 0

    set die_x0 0
    set die_y0 0
    set die_x1 $width_units
    set die_y1 $height_units

    set_distance_units MICRONS $def_units
    set_die_area -- [list $die_x0 $die_y0 $die_x1 $die_y1]
    set_x_tracks $first_track $width_tracks $track_spacing_units $signal_layers
    set_y_tracks $first_track $height_tracks $track_spacing_units $signal_layers
    make_row_sites -halo 0 $core_site 1 $tracks_per_row
}


proc plan_get_port_range {bus left right} {
    global nl_bus_naming_style

    set result {}
    if { $left <= $right } {
	for {set i $left} {$i <= $right} {incr i} {
	    set name [format $nl_bus_naming_style $bus $i]
	    set port [find_ports -exact $name]
	    if { [llength $port] == 0 } {
		error "Could not find a port named $name"
	    }
	    lappend result [lindex $port 0]
	}
    } else {
	for {set i $left} {$i >= $right} {incr i -1} {
	    set name [format $nl_bus_naming_style $bus $i]
	    set port [find_ports -exact $name]
	    if { [llength $port] == 0 } {
		error "Could not find a port named $name"
	    }
	    lappend result [lindex $port 0]
	}
    }

    return $result
}


proc plan_place_ports {side ports} {
    global verilog_file
    global width
    global height
    global track_spacing
    global tracks_per_bit
    global tracks_per_row
    global def_units
    global signal_layers
    global core_site
    global vertical_layer
    global metal_width

    global top_bits
    global bottom_bits

    if { $side == "top" } {
	set bitpos $top_bits
	set y_rows $height
	incr top_bits
    } elseif { $side == "bottom" } {
	set bitpos $bottom_bits
	set y_rows 0
	incr bottom_bits
    } else {
	error "invalid side: $side"
    }

    set num_ports [llength $ports]

    if { $num_ports > $width } {
	error "Too many ports, $num_ports.  Should be <= $width."
    }

    set track_spacing_units [expr int($track_spacing * $def_units)]
    set half_track_spacing_units [expr int($track_spacing_units / 2)]

    set half_metal_width [expr int($metal_width * $def_units / 2)]
    set neg_half_metal_width [expr - $half_metal_width]

    set bit [expr $width - $num_ports]

    foreach port $ports {
	set x_tracks [expr $bit * $tracks_per_bit + $bitpos]
	set x_units [expr $x_tracks * $track_spacing_units + $half_track_spacing_units]
	set y_tracks [expr $y_rows * $tracks_per_row]
	set y_units [expr int($y_tracks * $track_spacing * $def_units)]

	if { $side == "top" } {
	    incr y_units [expr - $half_track_spacing_units]
	} else {
	    incr y_units $half_track_spacing_units
	}

	plan_place_port $port v $x_units $y_units

	incr bit 1
    }

    return $bitpos
}


proc plan_place_port {port v_or_h x y} {
    global def_units
    global metal_width
    global vertical_layer
    global horizontal_layer

    set half_metal_width [expr int($metal_width * $def_units / 2)]
    set neg_half_metal_width [expr - $half_metal_width]

    set geometry [list $neg_half_metal_width $neg_half_metal_width $half_metal_width $half_metal_width]
    nl_set_port_location $port $x $y
    nl_set_port_orientation $port N
    
    if { $v_or_h == "v" } {
	set layer $vertical_layer
    } elseif { $v_or_h == "h" } {
	set layer $horizontal_layer
    } else {
	error "v_or_h parameter should be either v or h, not $v_or_h."
    }

    nl_set_port_geometry $port $layer $geometry
}

    

proc plan_remove_unplaced_ports {} {
    foreach port [list_ports] {
	set geom [nl_get_port_geometry $port]

	if { $geom == {} } {
	    nl_remove_port $port
	}
    }
}


proc plan_place_unplaced_ports {spread} {
    global track_spacing
    global def_units

    set porty {}
    set sum 0
    set count 0

    foreach port [list_ports] {
	set geom [nl_get_port_geometry $port]

	if { $geom == {} } {
	    set bbox [get_net_bbox $port]
	    set y0 [lindex $bbox 1]
	    set y1 [lindex $bbox 3]
	    set ybar [expr ($y0 + $y1) / 2]

	    lappend porty [list $port $ybar]

	    incr sum $ybar
	    incr count
	}
    }
    
    set porty_sort [lsort -index 1 -integer $porty]

    set avg [expr $sum / $count]

    set area [nl_get_die_area]

    set ymin [lindex $area 1]
    set ymax [lindex $area 3]

    set track_spacing_units [expr int($track_spacing * $def_units)]
    set half_track_spacing_units [expr $track_spacing_units / 2]
    set spread_units [expr int($track_spacing_units * $spread)]

    set avg_units $avg
    set avg_track_units1 [expr int($track_spacing_units * int($avg / $track_spacing_units))]
    set avg_track_units [expr $avg_track_units1 + $half_track_spacing_units]

    puts "avg = $avg, avg_track_units = $avg_track_units"
    set y [expr $avg_track_units - ($count / 2) * $spread_units]

    foreach port $porty_sort {
	puts [format "%-32s  %8d  %8d" [lindex $port 0] [lindex $port 1] $y]

	plan_place_port [lindex $port 0] h $half_track_spacing_units $y
	
	incr y $spread_units
    }
}


