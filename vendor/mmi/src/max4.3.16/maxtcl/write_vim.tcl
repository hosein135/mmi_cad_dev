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

set RCSVERSION(write_vim.tcl) { $Revision$ }

proc nl_write_vim_version {ofp} {
    puts $ofp "VIM_VERSION 18.0"
}


proc nl_get_vim_direction {dir} {
    switch $dir {
	in      { return I }
	out     { return O }
	inout   { return B }
	default { error "Unrecognized direction: $dir" }
    }
}


proc fplan_vim_identity {arg} {
    return $arg
}

proc fplan_write_vim {} {
    global _FPLAN_WRITE_VIM
    use_init _FPLAN_WRITE_VIM(tech) 0
    use_init _FPLAN_WRITE_VIM(placement) 1
    use_init _FPLAN_WRITE_VIM(phys) 0


    set prop_list ""
    set cell [lay_editcell]
    set basename $cell
    lappend prop_list [list "Cell name:" cell -label]
    lappend prop_list [list "Output file basename:" basename -entry]
    lappend prop_list [list "Write placement" _FPLAN_WRITE_VIM(placement) -binary]
    #lappend prop_list [list "Write placement" _FPLAN_WRITE_VIM(tech) -binary]
    #lappend prop_list [list "Write placement" _FPLAN_WRITE_VIM(phys) -binary]
    if {![prop_menu2 -title "Write VIM" $prop_list]} {
      msg "cancelled\n"
      return
    }

    prop_dialog "Write VIM not working yet..."
    return

    if {$_FPLAN_WRITE_VIM(placement)} {
      set ofp [open ${basename}.vim.placement w]
      fplan_write_vim_placement -ofp $ofp [lay_editcell]
    }
}


proc fplan_write_vim_placement {{-cell_translate ""} {-gridless 0} {-ofp ""} cell} {
    #nl_getopt nl_write_vim_placement "Write out the placement information in VIM format." {
    #	{-cell_translate string "proc to call to translate cell names"}
    #	{-gridless boolean "write a VIM with a gridless scale"}
    #} {
    #	{ofp writable_channel "the name of the VIM file to write"}
    #	&optional
    #	{design current_design "design to be written"}
    #} $args
    #
    if { $cell_translate == {} } {
    	set cell_translate fplan_vim_identity
    }

    global nl_current_design
    set old_design $nl_current_design
    set design [fplan_db_cell module $cell]
    nlt_log {set nl_current_design $design}

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
	    
	    regsub -all {\\/} $cell_name "/" cell_name

	    puts -nonewline $ofp "PLACE [$cell_translate $cell_name]"
	    puts -nonewline $ofp " '$ref_name' $locx $locy $flipped $rotation"

	    set loctype [nl_get_cell_loctype $cell]

	    if { $loctype == "FIXED" || $loctype == "COVER" } {
		puts -nonewline $ofp " MOVETYPE=FIXED"
	    }

	    puts $ofp ""
	}
    } {
	nlt_log {set nl_current_design $old_design}
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}


proc nl_write_vim_tech args {
    nl_getopt nl_write_vim "Write out the design in VIM format." {
	{-clock_name string "the name of the clock signal"}
	{-cell_translate string "proc to call to translate cell names"}
	{-net_translate string "proc to call to translate net names"}
	{-port_translate string "proc to call to translate port names"}
    } {
	{ofp writable_channel "the name of the VIM file to write"}
	&optional
	{design current_design "design to be written"}
    } $args

    if { $cell_translate == {} } {
	set cell_translate nl_identity
    }

    if { $net_translate == {} } {
	set net_translate nl_identity
    }

    if { $port_translate == {} } {
	set port_translate nl_identity
    }

    unwind_protect {
	nl_write_vim_version $ofp

	puts $ofp "PRTDEF $design TECH $design"

	nl_foreach_design_net -recur -noconstant net $design {
	    puts $ofp "NET [$net_translate $net]"
	}

	puts $ofp "PNET GND P"
	puts $ofp "PNET VDD P"

	nl_foreach_design_port port $design {
	    if { [nl_get_port_name $port] == $clock_name } {
		continue
	    }
	
	    set dir [nl_get_vim_direction [nl_get_port_direction $port]]
	
	    set net [nl_get_pin_net $port]

	    puts $ofp "  PPIN [$port_translate $port] $dir [$net_translate $net]"
	}

	nl_foreach_design_cell -recur -library -unlinked -recursive -noassign cell $design {
	    set ref [nl_get_cell_reference $cell]
	    set ref_name [nl_get_reference_name $ref]
	    set cell_name $cell
	    
	    regsub -all {\\/} $cell_name "/" cell_name

	    puts $ofp "USGDEF [$cell_translate $cell_name] $ref_name"

	    set pins [nl_get_cell_pins $cell]

	    foreach pin $pins {
		set net [nl_get_pin_net $pin]

		if { $net == {} } {
		    continue
		}

		set net_name [nl_get_net_name $net]

		if { $net_name == $clock_name } {
		    continue
		}

		set pin_name [nl_get_pin_name $pin]

		set dir [nl_get_vim_direction [nl_get_pin_direction $pin]]

		if { $net_name == "1'b1" } {
		    set net VDD
		} elseif { $net_name == "1'b0" } {
		    set net GND
		}

		puts $ofp "  UPIN $pin_name $dir [$net_translate $net]"
	    }
	}
    } {
	if { $ofp != "stdout" } {
	    close $ofp
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
    nl_getopt nl_write_vim "Write out the design in VIM format." {
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


#nl_register_command nl_write_vim_placement
#nl_register_command nl_write_vim_tech
#nl_register_command nl_write_vim_physcell
