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

set nl_port_count 1

proc nl_connect_pins {port pin} {
    set dir [nl_get_port_direction $port]
    set design [nl_get_port_design $port]
    set cell [nl_get_pin_owner $pin]

    if { [nl_object_type $cell] != "cell" } {
	error "pin must be a pin on a cell (not a port)"
    }

    if { $design == [nl_get_cell_design $cell] } {
	puts "Connecting pin $pin to net $port."
	connect_pin $pin $port
    } else {
	set cell_design [nl_get_cell_design $cell]
	set pin_net [nl_get_pin_net $pin]
	set pin_port {}
	
	if { $pin_net != {} } {
	    set pins [nl_get_net_pins $pin_net]
	    
	    foreach other_pin $pins {
		set other_owner [nl_get_pin_owner $other_pin]
		if { [nl_object_type $other_owner] == "port" } {
		    set pin_port $other_owner
		    break
		}
	    }
	}

	set cell_parent [nl_get_cell_parent [nl_get_pin_owner $pin]]

	if { $pin_port == {} } {
	    global nl_port_count

	    set pin_port_name [join "port $nl_port_count" _]
	    incr nl_port_count

	    puts "Creating port $pin_port_name on design $cell_design."
	    set pin_port [nl_create_port $pin_port_name $dir $cell_design]
	    set pin_port_net [nl_get_pin_net [nl_get_port_pin $pin_port]]

	    puts "Connecting pin $pin to net $pin_port_net in design $cell_design."
	    connect_pin $pin $pin_port_net
	}

	connect_pins $port [nl_get_cell_pin $cell_parent $pin_port]
    }
}
