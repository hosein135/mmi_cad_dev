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

proc nl_write_netlist args {
    nl_getopt nl_write_netlist "Write out the design in .netlist format." {
	{-no_names boolean "don't include net names"}
	{-no_single_pin_nets boolean "don't include nets with only one connection"}
    } {
	{filename string "write the netlist to this file"}
	&optional
	{design current_design "write a netlist for this design"}
    } $args

    global nl_hierarchy_separator

    set old_hierarchy_separator $nl_hierarchy_separator
    set ofp {}

#    unwind_protect {
	set nl_hierarchy_separator .

	set zero_net [nl_find_nets -exact "1'b0" $design]
	set one_net [nl_find_nets -exact "1'b1" $design]

	set zero_pins [nl_get_net_pins -noassign $zero_net]
	set one_pins [nl_get_net_pins -noassign $one_net]

	set zero_nets [nl_get_net_nets -noassign $zero_net]
	set one_nets [nl_get_net_nets -noassign $one_net]

	set file [list]

	foreach pin $zero_pins {
	    lappend file "1'b0: $pin"
	}

	foreach pin $one_pins {
	    lappend file "1'b1: $pin"
	}

	set attr [nl_create_net_attribute -dense "netlist done"]

	foreach net $zero_nets {
	    nl_set_net_attribute $attr $net 1
	}

	foreach net $one_nets {
	    nl_set_net_attribute $attr $net 1
	}

	set nets [nl_list_nets $design]

	foreach net $nets {
	    if { [nl_get_net_attribute $attr $net] != {} } {
		continue
	    }

	    foreach other_net [nl_get_net_nets -noassign $net] {
		nl_set_net_attribute $attr $other_net 1
	    }

	    set pin_list [nl_get_net_pins -noassign $net]

	    if { $no_single_pin_nets && [llength $pin_list] < 2 } {
		continue
	    }

	    set line ""

	    if { ! $no_names } {
		append line "$net: "
	    }

	    set first 1

	    foreach pin [lsort $pin_list] {
		if { ! $first } {
		    append line " "
		} else {
		    set first 0
		}
		append line "$pin"
	    }

	    lappend file $line
	}

	set file [lsort $file]

	set ofp [open $filename w]

	foreach line $file {
	    puts $ofp $line
	}
#    } {
	set nl_hierarchy_separator $old_hierarchy_separator

	if { [info exists attr] } {
	    nl_remove_attribute $attr
	}

	if { $ofp != {} } {
	    close $ofp
	}
#    }
}


nl_register_command nl_write_netlist
