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

proc nl_pdef_orientation {orientation} {
    switch $orientation {
	N  { return "0" }
	S  { return "180" }
	E  { return "270" }
	W  { return "90" }
	FN { return "0-mirror" }
	FS { return "180-mirror" }
	FE { return "270-mirror" }
	FW { return "90-mirror" }
	default { error "unhandled orientation, $orientation" }
    }
}


proc nl_pdef_direction {direction} {
    switch $direction {
	in { return "INPUT" }
	out { return "OUTPUT" }
	inout { return "INOUT" }
	default { error "unhandled direction, $direction" }
    }
}
    

proc nl_write_pdef args {
    nl_getopt nl_write_pdef "Write out the physical information for the specified design as a .pdef file" {
	{-fixed_only boolean "only include components with fixed placement"}
    } {
	{ofp writable_channel "the name of the .pdef file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    global nl_version

    unwind_protect {
	puts $ofp "(CLUSTERFILE"
	puts $ofp "  (PDEFVERSION \"IEEE 1481-1998\")"
	puts $ofp "  (DESIGN \"[nl_get_design_name $design]\")"
	puts $ofp "  (DATE \"[exec date]\")"
	puts $ofp "  (VENDOR \"Juniper Networks\")"
	puts $ofp "  (PROGRAM \"nl_shell $nl_version\")"
	puts $ofp "  (VERSION \"1.0\")"
	puts $ofp "  (DIVIDER / )"
	puts $ofp "  (PIN_DELIMITER / )"
	puts $ofp "  (BUS_DELIMITER \[ \] )"
	puts $ofp "  (NETLIST_TYPE VERILOG )"
	puts $ofp "  (DESIGN_FLOW \" \" )"

	set units [nl_get_distance_units $design]
    
	set def_unit [lindex $units 1]

	puts $ofp "  (DISTANCE_UNIT [expr 1.0 / $def_unit])"
	puts $ofp "  (DEF_CONVERSION_FACTOR $def_unit)"

	set row_sites [nl_list_row_sites $design]

	foreach row_site $row_sites {
	    set name  [lindex $row_site 0]
	    set site  [lindex $row_site 1]
	    set x     [lindex $row_site 2]
	    set y     [lindex $row_site 3]
	    set ori   [lindex $row_site 4]
	    set count [lindex $row_site 5]
	    set step  [lindex $row_site 6]

	    set ori [nl_pdef_orientation $ori]

	    puts $ofp "  (SITE $name \"$site\" \" $x $y \" \"H\" \"$ori\" \"$step\" \"$count\")"
	}

	set die_area [nl_get_die_area $design]

	set x0 [lindex $die_area 0]
	set y0 [lindex $die_area 1]
	set x1 [lindex $die_area 2]
	set y1 [lindex $die_area 3]

	puts $ofp "  (CORE_AREA $x0 $y0 $x1 $y1 )"

	set track_count 0

	set x_tracks [nl_get_x_tracks $design]
	set y_tracks [nl_get_y_tracks $design]

	foreach track $x_tracks {
	    set first  [lindex $track 0]
	    set count  [lindex $track 1]
	    set step   [lindex $track 2]
	    set layers [lindex $track 3]
	    puts $ofp "  (DEF_TRACK_$track_count \"X\" \"$first\" \"$count\" \"$step\" \"$layers\")"
	    incr track_count
	}
    
	foreach track $y_tracks {
	    set first  [lindex $track 0]
	    set count  [lindex $track 1]
	    set step   [lindex $track 2]
	    set layers [lindex $track 3]
	    puts $ofp "  (DEF_TRACK_$track_count \"X\" \"$first\" \"$count\" \"$step\" \"$layers\")"
	    incr track_count
	}

	puts $ofp "  (DEF_DIEAREA \"$x0\" \"$y0\" \"$x1\" \"$y1\")"

	set ports [nl_list_ports $design]

	puts $ofp "  (CLUSTER"
	puts $ofp "    \"DEFIN_CLUSTER\""

	foreach port $ports {
	    set loctype [nl_get_port_loctype $port]
	    set location [nl_get_port_location $port]
	    set orientation [nl_get_port_orientation $port]
	    set use [nl_get_port_use $port]
	    set dir [nl_get_port_direction $port]
	    set geometry [nl_get_port_geometry $port]

	    if { $location != {} } {
		set name $port
		regsub -all "\\\$" $name "\\\$" name
		regsub -all "\\\[" $name "\\\[" name
		regsub -all "\\\]" $name "\\\]" name
		regsub -all "\\\*" $name "\\\*" name
	    
		puts $ofp "    (PIN $name "
		puts $ofp "      (LOC [lindex $location 0] [lindex $location 1])"

		if { $loctype == "FIXED" || $loctype == "COVER" } {
		    puts $ofp "      (RESTRICTION FIXED_PLACEMENT)"
		}

		puts $ofp "      (ORIENT \"[nl_pdef_orientation $orientation]\" )"
		puts $ofp "      ( $loctype )"

		if { $use == "null" } {
		    set use SIGNAL
		}
		puts $ofp "      (PIN_TYPE $use )"

		puts $ofp "      (PIN_DIR [nl_pdef_direction $dir] )"

		if { $geometry != {} } {
		    set layer [lindex $geometry 0]
		    set geom_ll [lrange [lindex $geometry 1] 0 1]
		    set geom_ur [lrange [lindex $geometry 1] 2 3]

		    puts $ofp "      (PIN_LAYER \"$layer ( $geom_ll ) ( $geom_ur )\" )"
		}

		set net [nl_get_pin_net $port]

		puts $ofp "      (DEF_NET_NAME \"$net\" )"
	    
		puts $ofp "    )"
	    }
	}

	set cells [nl_list_cells -recursive -library -unlinked $design]

	foreach cell $cells {
	    set loctype [nl_get_cell_loctype $cell]

	    if { $fixed_only && !($loctype == "FIXED" || $loctype == "COVER") } {
		continue
	    }
	
	    if { $loctype == "FIXED" || $loctype == "PLACED" || $loctype == "COVER" } {
		set ref [nl_get_cell_reference $cell]
		set ref_name [nl_get_reference_name $ref]
		set location [nl_get_cell_location $cell]
		set orientation [nl_get_cell_orientation $cell]

		set name $cell
		regsub -all "\\\$" $name "\\\$" name
		regsub -all "\\\[" $name "\\\[" name
		regsub -all "\\\]" $name "\\\]" name
		regsub -all "\\\*" $name "\\\*" name

		puts $ofp "    (CELL $name "
		puts $ofp "      (GATE_NAME $ref_name )"
		puts $ofp "      (LOC [lindex $location 0] [lindex $location 1])"

		if { $loctype == "FIXED" || $loctype == "COVER" } {
		    puts $ofp "      (RESTRICTION FIXED_PLACEMENT)"
		}

		puts $ofp "      (ORIENT \"[nl_pdef_orientation $orientation]\" )"

		puts $ofp "      ( $loctype )"
		puts $ofp "    )"
	    }
	}

	# end of CLUSTER
	puts $ofp "  )"
	
	# end of CLUSTERFILE
	puts $ofp ")"
	
    } {
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}


nl_register_command nl_write_pdef
