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

proc nl_write_vim_version {ofp} {
    puts $ofp "VIM_VERSION 18.0"
}


proc nl_get_vim_direction {dir} {
    switch $dir {
	in      { return I }
	out     { return O }
	inout   { return B }
	default { error "unknown direction" }
    }
}


proc nl_identity {arg} {
    return $arg
}


proc nl_clean_vim_name {obj design type find_cmd} {
    global error_net1 error_net2 error_name

    set name $obj

    set count [regsub -all {\*} $name "_" name]

    if { $count > 0 } {
	set existing [lindex [$find_cmd -exact $name $design] 0]

	if { $existing != {} } {
	    set error_name $name
	    set error_net1 $obj
	    set error_net2 $existing
	    error "name collision occured when removing '*' characters from $type $obj ($existing)"
	}
    }

    set count [regsub -all {\\} $name "" name]

    if { $count > 0 } {
	set existing [lindex [$find_cmd -exact $name $design] 0]

	if { $existing != {} } {
	    set error_name $name
	    set error_net1 $obj
	    set error_net2 $existing
	    error "name collision occured when removing '\\' characters from $type $obj ($existing)"
	}
    }

    return $name
}


proc nl_clean_vim_names {design} {
    foreach cell [nl_list_cells $design] {
	set new_name [nl_clean_vim_name $cell $design cell nl_find_cells]

	nl_rename_cell $cell $new_name
    }

    foreach net [nl_list_nets $design] {
	set new_name [nl_clean_vim_name $net $design net nl_find_nets]

	nl_rename_net $net $new_name
    }

    foreach port [nl_list_ports $design] {
	set new_name [nl_clean_vim_name $port $design port nl_find_ports]

	nl_rename_port $port $new_name
    }

    foreach reference [nl_list_references $design] {
	if { [nl_get_reference_cells $reference] == {} } {
	    continue
	}

	foreach refpin [nl_get_reference_refpins $reference] {
	    set new_name [nl_clean_vim_name $reference/$refpin $design refpin nl_find_refpins]
	    
	    regsub "$reference/" $new_name "" new_name

	    nl_rename_refpin $refpin $new_name
	}
    }
}


proc nl_write_vim_placement args {
    nl_getopt nl_write_vim_placement "Write out the placement information in VIM format." {
	{-cell_translate string "proc to call to translate cell names"}
	{-gridless boolean "write a VIM with a gridless scale"}
    } {
	{ofp writable_channel "the name of the VIM file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    if { $cell_translate == {} } {
	set cell_translate nl_identity
    }

    unwind_protect {
	nl_write_vim_version $ofp

	puts $ofp "PRTREF $design TECH"

	if { $gridless } {
	    puts $ofp "SCALE GRIDLESS"
	    set grid_option -
	} else {
	    puts $ofp "SCALE GRIDDED"
	    set grid_option -grids
	}

	nl_foreach_design_cell -recur -library -unlinked cell $design {
	    set loctype [nl_get_cell_loctype $cell]

	    if { $loctype == "null" } {
		continue
	    }

	    set ref [nl_get_cell_reference $cell]
	    set ref_name [nl_get_reference_name $ref]
	    set orient [nl_get_cell_orientation $cell]

	    switch $orient {
		N  { set flipped N; set rotation 0   }
		E  { set flipped N; set rotation 90  }
		S  { set flipped N; set rotation 180 }
		W  { set flipped N; set rotation 270 }
		FN { set flipped Y; set rotation 180 }
		FE { set flipped Y; set rotation 270 }
		FS { set flipped Y; set rotation 0   }
		FW { set flipped Y; set rotation 90  }
	    }

	    set loc [nl_get_cell_location $grid_option -origin $cell]
	    set locx [lindex $loc 0]
	    set locy [lindex $loc 1]

	    if { $gridless } {
		set locx [expr $locx / 1000.0]
		set locy [expr $locy / 1000.0]
	    }

	    set cell_name $cell
	    
	    puts -nonewline $ofp "PLACE [$cell_translate $cell_name]"
	    puts -nonewline $ofp " '$ref_name' $locx $locy $flipped $rotation"

	    set loctype [nl_get_cell_loctype $cell]

	    if { $loctype == "FIXED" || $loctype == "COVER" } {
		puts -nonewline $ofp " MOVETYPE=FIXED"
	    }

	    puts $ofp ""
	}
    } {
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}


proc nl_write_vim_tech args {
    nl_getopt nl_write_vim_tech "Write out the design in VIM format." {
	{-clock_name string "the name of the clock signal"}
	{-cell_translate string "proc to call to translate cell names"}
	{-net_translate string "proc to call to translate net names"}
	{-nohierarchy boolean "do not descend hierarchy"}
	{-port_translate string "proc to call to translate port names"}
    } {
	{ofp writable_channel "the name of the VIM file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    global net_table

    if { [info exists net_table] } {
	unset net_table
    }

    if { $cell_translate == {} } {
	set cell_translate nl_identity
    }

    if { $net_translate == {} } {
	set net_translate nl_identity
    }

    if { $port_translate == {} } {
	set port_translate nl_identity
    }

    if { $nohierarchy } {
	set recur_switch "-"
	set hier_switch "-"
	set cell_hier_switch "-hierarchy"
    } else {
	set recur_switch "-recursive"
	set hier_switch "-hierarchy"
	set cell_hier_switch "-"
    }

    augment_error_message "nl_write_vim_tech: %s" {
	unwind_protect {
	    nl_write_vim_version $ofp

	    puts $ofp "PRTDEF $design TECH $design"

	    set nets [list_nets $recur_switch -noassign -onlyconstant $design]

	    foreach net $nets {
		set net_name {}

		set other_nets [nl_get_net_nets -noassign $hier_switch $net]

		foreach other_net $other_nets {
		    set other_name [nl_get_net_name $other_net]
	    
		    if { $other_name == "1'b1" } {
			set net_name VDD
			break
		    } elseif { $other_name == "1'b0" } {
			set net_name GND
			break
		    }
		}

		if { $net_name == {} } {
		    error "could not get constant value for net $net"
		}

		foreach other_net $other_nets {
		    set net_table($other_net) $net_name
		}
	    }

	    set nets [list_nets $recur_switch -noassign -noconstant $design]

	    foreach net $nets {
		if { [info exists net_table($net)] } {
		    error "internal error: $net is already in net_table"
		}

		set net_name [nl_get_net_name $net]

		if { $net_name == "1'b1" } {
		    set net_name VDD
		} elseif { $net_name == "1'b0" } {
		    set net_name GND
		} else {
		    set net_name $net
		    set net_name [$net_translate $net_name]
		    puts $ofp "NET $net_name"
		}

		set net_table($net) $net_name

		set other_nets [nl_get_net_nets $hier_switch -noassign $net]

		foreach other_net $other_nets {
		    set net_table($other_net) $net_name
		}
	    }

	    puts $ofp "PNET GND P"
	    puts $ofp "PNET VDD P"

	    set ports [nl_list_ports $design]

	    foreach port $ports {
		if { [nl_get_port_name $port] == $clock_name } {
		    continue
		}

		augment_error_message "%s, while getting the direction of port $port" {
		    set dir [nl_get_vim_direction [nl_get_port_direction $port]]
		}
	
		set net [nl_get_pin_net [nl_get_port_pin $port]]

		set net_name $net

		puts $ofp "  PPIN [$port_translate $port] $dir [$net_translate $net_name]"
	    }

	    set cells [nl_list_cells $recur_switch $cell_hier_switch -library -unlinked -noassign $design]

	    foreach cell $cells {
		set ref [nl_get_cell_reference $cell]
		set ref_name [nl_get_reference_name $ref]
		set cell_name $cell

		puts $ofp "USGDEF [$cell_translate $cell_name] $ref_name"

		set pins [nl_get_cell_pins $cell]

		foreach pin $pins {
		    set net [nl_get_pin_net $pin]

		    if { $net == {} } {
			continue
		    }

		    if { ! [info exists net_table($net)] } {
			error "internal error: $net is not in net_table, cell is $cell, pin is $pin"
			
		    }

		    set net_name $net_table($net)

		    set pin_name [nl_get_pin_name $pin]

		    augment_error_message "%s, while getting the direction of pin $pin" {
			set dir [nl_get_vim_direction [nl_get_pin_direction $pin]]
		    }

		    puts $ofp "  UPIN $pin_name $dir $net_name"
		}
	    }
	} {
	    if { $ofp != "stdout" } {
		close $ofp
	    }
	}
    }
}


proc nl_write_vim_ruledef {ofp design} {
    puts $ofp "RULEDEF $design PHYSCELL C8SF cu11.7lmc4"
    puts $ofp "+'RULEDEF' SC_PLACEMENT_CHANNEL_STEP=0.400000"
    puts $ofp "+'RULEDEF' PLACEMENT_CHANNEL_START=0.000000"
    puts $ofp "+'RULEDEF' MIRROR=SECONDROW"
}


proc nl_write_vim_outline {ofp design} {
    set die_area [nl_get_die_area $design]

    set xll [lindex $die_area 0]
    set yll [lindex $die_area 1]
    set xur [lindex $die_area 2] 
    set yur [lindex $die_area 3] 
    
    set xsize [expr $xur - $xll]
    set ysize [expr $yur - $yll]
    
    set xll_um [expr $xll / 1000.0]
    set yll_um [expr $yll / 1000.0]

    set xsize_um [expr $xsize / 1000.0]
    set ysize_um [expr $ysize / 1000.0]

    puts $ofp "OUTLINE P"
    puts $ofp "  RCT M5 DC $xll_um $yll_um $xsize_um $ysize_um"
}


proc nl_write_vim_row_sites {ofp design} {
    set row_sites [nl_list_row_sites $design]

    foreach row_site $row_sites {
	set name [lindex $row_site 0]
	set xll [lindex $row_site 2]
	set yll [lindex $row_site 3]
	set count [lindex $row_site 5]
	set step  [lindex $row_site 6]
	set height [lindex $row_site 7]

	set xll_um [expr $xll / 1000.0]
	set yll_um [expr $yll / 1000.0]

	set width_um [expr $count * $step / 1000.0]
	set height_um [expr $height / 1000.0]

	puts $ofp "CKTROW $name $xll_um $yll_um $width_um $height_um H 0"
    }
}


proc nl_write_vim_rpins {ofp design} {
    set ports [nl_list_ports $design]

    foreach port $ports {
	set dir [nl_get_vim_direction [nl_get_port_direction $port]]
	set loc [nl_get_port_location $port]
	set geom [nl_get_port_geometry $port]

	set locx [lindex $loc 0]
	set locy [lindex $loc 1]

	set layer [lindex $geom 0]
	set rect [lindex $geom 1]

	set xll [lindex $rect 0]
	set yll [lindex $rect 1]
	set xur [lindex $rect 2]
	set yur [lindex $rect 3]

	set xsize [expr $xur - $xll]
	set ysize [expr $yur - $yll]

	set xll [expr $xll + $locx]
	set yll [expr $yll + $locy]

	set pin_layer "${layer}PIN"
	set xll_um [expr $xll / 1000.0]
	set yll_um [expr $yll / 1000.0]
	set xsize_um [expr $xsize / 1000.0]
	set ysize_um [expr $ysize / 1000.0]

	puts $ofp "RPIN $port $port $dir '$port'"
	puts $ofp " PORT 0"
	puts $ofp "  RCT $pin_layer SH $xll_um $yll_um $xsize_um $ysize_um"
    }
}


proc nl_write_vim_physcell args {
    nl_getopt nl_write_vim_physcell "Write out the design in VIM format." {
    } {
	{ofp writable_channel "the name of the VIM file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    unwind_protect {
	nl_write_vim_version $ofp
	nl_write_vim_ruledef $ofp $design
	puts $ofp "SCALE GRIDLESS"
	nl_write_vim_outline $ofp $design
	nl_write_vim_row_sites $ofp $design
	nl_write_vim_rpins $ofp $design
    } {
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}


proc nl_write_vim_def args {
    nl_getopt nl_write_vim_def "Write out the design in VIM format." {
    } {
	{ofp writable_channel "the name of the VIM DEF file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    unwind_protect {
	nl_write_vim_version $ofp
	puts $ofp "DEF $design"

	foreach port [nl_list_ports $design] {
	    augment_error_message "%s, while getting the direction of port $port" {
		set dir [nl_get_vim_direction [nl_get_port_direction $port]]
	    }
	
	    puts -nonewline $ofp "  DPIN $port $dir"
	    
	    set bus [nl_get_port_bus $port]

	    if { $bus != {} } {
		puts -nonewline $ofp " VHDL_DIR="

		set type [nl_get_bus_type $bus]
		set left [nl_get_type_left $type]
		set right [nl_get_type_right $type]
		
		if { $left > $right } {
		    puts -nonewline $ofp "DOWNTO"
		} else {
		    puts -nonewline $ofp "TO"
		}
	    }

	    puts $ofp ""
	}
    } {
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}


nl_register_command nl_write_vim_placement
nl_register_command nl_write_vim_tech
nl_register_command nl_write_vim_physcell
nl_register_command nl_write_vim_def
