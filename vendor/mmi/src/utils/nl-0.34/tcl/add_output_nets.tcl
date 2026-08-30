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

proc create_tmp_net {} {
    while { 1 } {
	set net_name [format "unc_net_%06d" [expr int (rand () * 1000000)]]

	set net [nl_find_nets -exact $net_name]

	if { $net == {} } {
	    break
	}
    }

    set new_net [create_net $net_name wire]

    return $new_net
}
	    

proc add_output_nets {} {
    set designs [list_designs]

    foreach design $designs {

	if { [is_libcell $design] } {
	    continue;
	}

	puts "design is $design"

	set cells [list_cells -noassign $design]

	foreach cell $cells {
	    set out_pins [get_cell_pins -outputs $cell]

	    foreach out_pin $out_pins {
		set out_net [get_pin_net $out_pin]
	    
		if { $out_net == {} } {
		    set new_out_net [create_tmp_net]
		    nl_connect_pin $out_pin $new_out_net
		}
	    }
	}
    }
}
