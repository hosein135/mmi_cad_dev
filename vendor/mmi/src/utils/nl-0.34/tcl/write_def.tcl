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

proc nl_format_def_name {name} {
    global nl_write_def_dividerchar

    set dividerchar $nl_write_def_dividerchar
    regsub -all {[.*+?^$|]} $dividerchar {\\\0} dividerchar
    regsub -all $dividerchar $name "\\$nl_write_def_dividerchar" name
    regsub -all ",hier," $name $nl_write_def_dividerchar name
    return $name
}


proc nl_write_def_pin_connection {ofp pin} {
    set owner [nl_get_pin_owner $pin]
    set owner_type [nl_object_type $owner]
    set owner_name [nl_format_def_name $owner]

    if { $owner_type == "port" } {
	puts $ofp ""
	puts -nonewline $ofp "    ( PIN $owner_name )"
    } else {
	set pin_name [nl_get_pin_name $pin]
	puts $ofp ""
	puts -nonewline $ofp "    ( $owner_name $pin_name )"
    }
}


proc nl_write_def_net_routes {ofp net_routes special} {

    foreach route $net_routes {
	set routekind [lindex $route 0]
	set index 0

	foreach branch $route {
	    incr index

	    if { $index == 1 } {
		# branch is actually the route type
		puts $ofp ""
		puts $ofp "  + $branch"
		puts -nonewline $ofp "   "
		continue
	    } elseif { $index > 2 } {
		puts $ofp ""
		puts -nonewline $ofp "    NEW"
	    }

	    puts -nonewline $ofp " [lindex $branch 0]"
	    
	    set x0y0 [lindex $branch 1]

	    if { $special } {
		puts -nonewline $ofp " [lindex $x0y0 2]"
	    }

	    puts -nonewline $ofp " ( [lindex $x0y0 0] [lindex $x0y0 1] )"
	    
	    foreach segment [lrange $branch 2 end] {
		if { [llength $segment] == 2 } {
		    set x [lindex $segment 0]
		    set y [lindex $segment 1]
		    puts -nonewline $ofp " ( $x $y )"
		} else {
		    puts $ofp ""
		    puts -nonewline $ofp "      $segment"
		}
	    }
	}
    }
}


proc nl_get_net_special_routes {inet} {
    return [nl_get_net_routes -special $inet]
}


proc nl_get_net_nonspecial_routes {inet} {
    return [nl_get_net_routes -nonspecial $inet]
}    


proc nl_write_def_nets {design ofp connectivity routes sort specialnets nohierarchy} {
    if { $nohierarchy } {
	set hier_switch -
    } else {
	set hier_switch -hierarchy
    }

    set nets [nl_list_nets $hier_switch -noassign -noconstant $design]

    if { $sort != 0 } {
	set nets [lsort $nets]
    }

    set count 0
    set has_zero 0
    set has_one 0

    if { $specialnets } {
	set zero_nets [find_inets -recursive -exact 1'b0]
	set one_nets [find_inets -recursive -exact 1'b1]
    } else {
	set zero_nets {}
	set one_nets {}
    }

    if { $zero_nets != {} } {
	incr count
    }

    if { $one_nets != {} } {
	incr count
    }

    upvar special_only_nets special_only_nets

    foreach net $nets {
	if { [info exists special_only_nets($net)] == 1 } {
	    continue
	}

	set net_pins [nl_get_net_pins -hierarchy -noassign $net]
	set net_nets [nl_get_net_nets -hierarchy -noassign $net]
	set net_routes [lmapcar -concat nl_get_net_nonspecial_routes $net_nets]

	if { $connectivity != 0 && $net_pins != {} ||
	     $routes != 0 && $net_routes != {} } {
	    incr count
	}
    }

    if { $count == 0 } {
	return
    }

    puts $ofp "NETS $count ;"
    
    foreach net $nets {
	if { [info exists special_only_nets($net)] == 1 } {
	    continue
	}

	set net_pins [nl_get_net_pins -hierarchy -noassign $net]
	set net_nets [nl_get_net_nets -hierarchy -noassign $net]

#	if { $sort } {
#	    set net_pins [lsort $net_pins]
#	    set net_nets [lsort $net_nets]
#	}

	set net_routes [lmapcar -concat nl_get_net_nonspecial_routes $net_nets]

	if { $connectivity != 0 && $net_pins != {} ||
	     $routes != 0 && $net_routes != {} } {
	    puts -nonewline $ofp "- [nl_format_def_name $net]"

	    if { $connectivity != 0 } {
		foreach pin $net_pins {
		    nl_write_def_pin_connection $ofp $pin
		}
	    }

	    if { $routes != 0 } {
		nl_write_def_net_routes $ofp $net_routes 0
	    }

	    set use [nl_get_net_use $net]
	    if { $use != "null" } {
		puts -nonewline $ofp "\n  + USE $use"
	    }

	    set pattern [nl_get_net_pattern $net]
	    if { $pattern != "null" } {
		puts -nonewline $ofp "\n  + PATTERN $pattern"
	    }

	    puts $ofp " ;"
	}
    }

    if { $zero_nets != {} } {
	puts -nonewline $ofp "- GND"

	foreach net $zero_nets {
	    foreach pin [nl_get_net_pins -hierarchy -noassign $net] {
		nl_write_def_pin_connection $ofp $pin
	    }
	}
	puts $ofp "\n  + USE GROUND ;"
    }

    if { $one_nets != {} } {
	puts -nonewline $ofp "- VDD"

	foreach net $one_nets {
	    foreach pin [nl_get_net_pins -hierarchy -noassign $net] {
		nl_write_def_pin_connection $ofp $pin
	    }
	}
	puts $ofp "\n  + USE POWER ;"
    }

    puts $ofp "END NETS"
    puts $ofp ""
}


proc nl_write_def_specialnets {design ofp sort net_routes zero_name one_name nohierarchy} {
    if { $nohierarchy } {
	set hier_switch -
    } else {
	set hier_switch -hierarchy
    }

    set nets [nl_list_nets $hier_switch -noassign -noconstant $design]
    set special_nets {}

    upvar special_only_nets special_only_nets

    if { [nl_find_nets 1'b0] != {} } {
	lappend nets [nl_find_nets 1'b0]
    }

    if { [nl_find_nets 1'b1] != {} } {
	lappend nets [nl_find_nets 1'b1]
    }

    foreach net $nets {
	set net_nets [nl_get_net_nets -hierarchy -noassign $net]
	set use [nl_get_net_use $net]
	set pattern [nl_get_net_pattern $net]

	foreach other_net $net_nets {
	    set other_use [nl_get_net_use $other_net]

	    if { [nl_is_special $other_net] } {
		set_special $net 1
	    }

	    if { $other_use != "null" } {
		if { $use == "null" } {
		    nl_set_net_use $net $other_use
		} elseif { $use != $other_use } {
		    puts stderr "Warning: USE clause of net [nl_format_def_name $net], $use, does not match that of connected net [nl_format_def_name $other_net], $other_use"
		    puts stderr "\tUsing + USE $use for this net."
		}
	    }

	    set other_pattern [nl_get_net_pattern $other_net]

	    if { $other_pattern != "null" } {
		if { $pattern == "null" } {
		    nl_set_net_pattern $net $other_pattern
		} elseif { $pattern != $other_pattern } {
		    puts stderr "Warning: PATTERN clause of net [nl_format_def_name $net], $pattern, does not match that of connected net [nl_format_def_name $other_net], $other_pattern"
		    puts stderr "\tUsing + PATTERN $pattern for this net."
		}
	    }
	}

	if { [info exists special_only_nets($net)] == 1 } {
	    lappend special_nets $net
	} elseif { [nl_is_special $net] } {
	    lappend special_nets $net
	} elseif { $net_routes } {
	    set all_routes [lmapcar -concat nl_get_net_special_routes $net_nets]

	    if { $all_routes != {} } {
		lappend special_nets $net
	    }
	}
    }

    if { $special_nets == {} } {
	return
    }
    
    puts $ofp "SPECIALNETS [llength $special_nets] ;"
    
    foreach net $special_nets {

	set net_name [nl_get_net_name $net]

	if { $net_name == "1'b0" } {
	    puts -nonewline $ofp "- $zero_name"
	    puts -nonewline $ofp " ( * $zero_name )"
	} elseif { $net_name == "1'b1" } {
	    puts -nonewline $ofp "- $one_name"
	    puts -nonewline $ofp " ( * $one_name )"
	} else {
	    puts -nonewline $ofp "- [nl_format_def_name $net]"
	}

	if { [info exists special_only_nets($net)] == 1 } {
	    set net_pins [nl_get_net_pins -hierarchy -noassign $net]
	    foreach pin $net_pins {
		nl_write_def_pin_connection $ofp $pin
	    }
	}

	if { $net_routes } {
	    set net_nets [nl_get_net_nets -hierarchy -noassign $net]
	    set all_routes [lmapcar -concat nl_get_net_special_routes $net_nets]

	    nl_write_def_net_routes $ofp $all_routes 1
	}

	set use [nl_get_net_use $net]
	if { $use != "null" } {
	    puts -nonewline $ofp "\n  + USE $use"
	}

	set pattern [nl_get_net_pattern $net]
	if { $pattern != "null" } {
	    puts -nonewline $ofp "\n  + PATTERN $pattern"
	}

	puts $ofp " ;"
    }

    puts $ofp "END SPECIALNETS"
    puts $ofp ""
}


proc nl_write_def_pins {design ofp sort} {
    set ports [nl_list_ports $design]

    if { $sort != 0 } {
	set ports [lsort $ports]
    }

#    if { $specialnets } {
#	set consts {vdd! gnd!}
#    } else {
#	set consts {}
#    }

    set consts {}

    set num_pins [expr [llength $ports] + [llength $consts]]

    puts $ofp "PINS $num_pins ;"

    foreach const $consts {
	puts -nonewline $ofp "- $const + NET $const + DIRECTION INPUT"
	
	if { $const == "vdd!" } {
	    puts -nonewline $ofp " + USE POWER"
	} else {
	    puts -nonewline $ofp " + USE GROUND"
	}

	puts $ofp " ;"
    }

    foreach net [nl_list_nets -recursive -noassign] {
	set net_def_name $net

	foreach sub_net [nl_get_net_nets -hierarchy -noassign $net] {
	    set net_name [nl_get_net_name $sub_net]

	    if { $net_name == "1'b0" } {
		set net_def_name "gnd!"
		break
	    } elseif { $net_name == "1'b1" } {
		set net_def_name "vdd!"
		break
	    }
	}

	foreach pin [nl_get_net_pins -recursive -noassign $net] {
	    set owner [nl_get_pin_owner $pin]
	    
	    if { [nl_object_type $owner] == "port" } {
		set port $owner
		set port_loctype [nl_get_port_loctype $port]
		set port_geom [nl_get_port_geometry $port]

		switch [nl_get_port_direction $port] {
		    in { set port_dir INPUT }
		    out { set port_dir OUTPUT }
		    inout { set port_dir INOUT }
		    default { error "port $port does not have a valid direction" }
		}
		
		puts -nonewline $ofp "- $port"
		puts -nonewline $ofp " + NET $net_def_name"
		puts -nonewline $ofp " + DIRECTION $port_dir"
		puts -nonewline $ofp " + USE SIGNAL"
		
		if { $port_loctype != "null" } {
		    set loc [nl_get_port_location $port]
		    set orient [nl_get_port_orientation $port]
		    
		    puts $ofp ""
		    puts -nonewline $ofp "  + $port_loctype ( $loc ) $orient"
		}
		
		if { $port_geom != {} } {
		    set layer [lindex $port_geom 0]
		    set rect [lindex $port_geom 1]
		    
		    puts $ofp ""
		    set x0 [lindex $rect 0]
		    set y0 [lindex $rect 1]
		    set x1 [lindex $rect 2]
		    set y1 [lindex $rect 3]
		    puts -nonewline $ofp "  + LAYER $layer ( $x0 $y0 ) ( $x1 $y1 )"
		}
		
		puts $ofp " ;"
	    }
	}
    }

    puts $ofp "END PINS"
    puts $ofp ""
}


proc nl_write_def_components {design ofp sort nohierarchy fixed_only} {
    global nl_current_design

    if { $nohierarchy } {
	set hier_switch -
    } else {
	set hier_switch -recursive
    }

    set cells [nl_list_cells $hier_switch -unlinked -library -noassign $design]

    if { $sort != 0 } {
	set cells [lsort $cells]
    }

    set components [list]

    foreach cell $cells {
	set cell_loctype [nl_get_cell_loctype $cell]

	if { $fixed_only && !($cell_loctype == "FIXED" || $cell_loctype == "COVER") } {
	    continue
	}

	if { $cell_loctype == "null" } {
	    continue
	}

	lappend components $cell
    }

    puts $ofp "COMPONENTS [llength $components] ;"

    foreach cell $components {
	set cell_loctype [nl_get_cell_loctype $cell]
	set reference [nl_get_cell_reference $cell]
	set ref_name [nl_get_reference_name $reference]
	
	puts -nonewline $ofp "- [nl_format_def_name $cell] $ref_name"
	puts -nonewline $ofp " + $cell_loctype"

	if { $cell_loctype != "UNPLACED" } {
	    set loc [nl_get_cell_location $cell]
	    set orient [nl_get_cell_orientation $cell]
	    
	    puts -nonewline $ofp " ( $loc ) $orient"
	}

	puts $ofp " ;"
    }

    puts $ofp "END COMPONENTS"
    puts $ofp ""
}


proc nl_write_def_history {ofp idesign} {
    set history [nl_get_def_history $idesign]

    foreach str $history {
	puts $ofp "HISTORY $str ;"
    }

    if { $history != {} } {
	puts $ofp ""
    }
}


proc nl_write_def args {
    nl_getopt nl_write_def "Write out the physical information for the specified design as a .def file" {
	{-header boolean "write out header information"}
	{-components boolean "write out the placement of cells"}
	{-pins boolean "write out the placement and geometry of ports"}
	{-specialnets boolean "write out the special nets"}
	{-net_routes boolean "write out routing of nets"}
	{-net_connectivity boolean "write out connectivity"}
	{-nohistory boolean "don't write out the history strings"}
	{-special_only tcl_object "place the specified nets in the specialnets section only"}
	{-sort boolean "sort nets, pins, and components before writing them out"}
	{-zero_name string "name of logic zero net (e.g. GND)"}
	{-one_name string "name of logic one net (e.g. VDD)"}
	{-nohierarchy boolean "write out DEF for one level of hierarchy only"}
	{-fixed_only boolean "only include components with fixed placement"}
    } {
	{ofp writable_channel "the name of the .def file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    global nl_hierarchy_separator nl_write_def_dividerchar

    set hierarchy_separator_save $nl_hierarchy_separator

    unwind_protect {
	if { [string length $nl_hierarchy_separator] > 1 } {
	    error "write_def: nl_hierarchy_separator (currently \"$nl_hierarchy_separator\") must be a single character (e.g. \"/\")."
	}

	if { $header == 0 && $components == 0 && $pins == 0 && 
	     $net_routes == 0 && $net_connectivity == 0 } {
	    set header 1
	    set components 1
	    set pins 1
	    set net_routes 1
	    set net_connectivity 1
	}
    
	set nl_write_def_dividerchar $nl_hierarchy_separator

	puts $ofp "DIVIDERCHAR \"$nl_write_def_dividerchar\" ;"
	puts $ofp ""

	set nl_hierarchy_separator ",hier,"

	puts $ofp "DESIGN $design ;"
	puts $ofp ""

	if { $nohistory == 0 } {
	    nl_write_def_history $ofp $design
	}

	if { $header != 0 } {
	    set units [nl_get_distance_units $design]
	
	    if { $units != {}} {
		puts $ofp "UNITS DISTANCE $units ;"
		puts $ofp ""
	    }
	
	    set area [nl_get_die_area $design]
	
	    if { $area != {} } {
		set x0 [lindex $area 0]
		set y0 [lindex $area 1]
		set x1 [lindex $area 2]
		set y1 [lindex $area 3]
		puts $ofp "DIEAREA ( $x0 $y0 ) ( $x1 $y1 ) ;"
		puts $ofp ""
	    }

	    set x_tracks_list [nl_get_x_tracks $design]
	    set y_tracks_list [nl_get_y_tracks $design]

	    foreach x_tracks $x_tracks_list {
		set start [lindex $x_tracks 0]
		set count [lindex $x_tracks 1]
		set step [lindex $x_tracks 2]
		set layers [lindex $x_tracks 3]

		puts $ofp "TRACKS X $start DO $count STEP $step LAYER $layers ;"
	    }

	    foreach y_tracks $y_tracks_list {
		set start [lindex $y_tracks 0]
		set count [lindex $y_tracks 1]
		set step [lindex $y_tracks 2]
		set layers [lindex $y_tracks 3]

		puts $ofp "TRACKS Y $start DO $count STEP $step LAYER $layers ;"
	    }

	    if { $x_tracks_list != {} || $y_tracks_list != {} } {
		puts $ofp ""
	    }

	    set row_sites [nl_list_row_sites $design]
	
	    foreach site $row_sites {
		set name [lindex $site 0]
		set core [lindex $site 1]
		set x0 [lindex $site 2]
		set y0 [lindex $site 3]
		set orientation [lindex $site 4]
		set count [lindex $site 5]
		set width [lindex $site 6]
		set height [lindex $site 7]

		puts -nonewline $ofp "ROW $name $core"
		puts -nonewline $ofp [format " %8d %8d $orientation" $x0 $y0]
		puts -nonewline $ofp [format " DO %6d BY 1 STEP" $count]
		puts            $ofp [format " %8d %8d ;" $width $height]
	    }
	    
	    if { $row_sites != {} } {
		puts $ofp ""
	    }
	}

	if { $components != 0 } {
	    nl_write_def_components $design $ofp $sort $nohierarchy $fixed_only
	}

        if { $pins != 0 } {
	    nl_write_def_pins $design $ofp $sort
	}

	foreach net_name $special_only {
	    regsub -all "/" $net_name ",hier," net_name
	    regsub -all "\\\\,hier," $net_name "\\/" net_name
	    set net_nets [nl_get_net_nets -hier -noassign $net_name]
	    foreach inet $net_nets {
		set special_only_nets($inet) 1
	    }
	}

	if { $specialnets != 0 } {
	    nl_write_def_specialnets $design $ofp $sort $net_routes $zero_name $one_name $nohierarchy
	}

	if { $net_connectivity != 0 || $net_routes != 0 } {
	    nl_write_def_nets $design $ofp $net_connectivity $net_routes $sort $specialnets $nohierarchy
	}
	
	puts $ofp "END DESIGN"
    } {
	set nl_hierarchy_separator $hierarchy_separator_save

	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}

nl_register_command nl_write_def
