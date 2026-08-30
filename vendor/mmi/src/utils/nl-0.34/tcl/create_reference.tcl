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

proc nl_create_reference_for_design args {
    nl_getopt nl_create_reference_for_design "Create a reference referring to the specified design" {
    } {
	{down_design design "create a reference to this design"}
	&optional
	{design current_design "create the reference in this design"}
    } $args

    set ref [nl_create_reference $down_design]

    set prev_bus {}
    foreach port [nl_list_ports $down_design] {
	set bus [nl_get_port_bus $port]

	if { $bus != {} && $bus == $prev_bus } {
	    continue
	}

	set prev_bus $bus

	if { $bus != {} } {
	    set type [nl_get_bus_type $bus]
	    set left [nl_get_type_left $type]
	    set right [nl_get_type_right $type]

	    nl_create_refpin_bus [nl_get_bus_name $bus] $left $right $ref
	} else {
	    nl_create_refpin [nl_get_port_name $port] $ref
	}
    }

    return $ref
}

nl_register_command nl_create_reference_for_design


proc nl_get_reference_for_design args {
    nl_getopt nl_get_reference_for_design "Get the reference referring to the specified design.  Create one if none currently exists." {
    } {
	{down_design design "get the reference for this design"}
	&optional
	{design current_design "get the reference in this design"}
    } $args

    set refs [nl_find_references -exact [nl_design_name $down_design] $design]

    if { $refs != {} } {
	set ref [lindex $refs 0]
    } else {
	set ref [nl_create_reference_for_design $down_design $design]
    }

    return $ref
}

nl_register_command nl_get_reference_for_design


proc nl_create_reference_for_libcell args {
    nl_getopt nl_create_reference_for_libcell "Create a reference referring to the specified libcell" {
    } {
	{libcell libcell "create a reference to this design"}
	&optional
	{design current_design "create the reference in this design"}
    } $args

    set ref [nl_create_reference [nl_get_libcell_name $libcell] $design]

    set prev_bus {}
    foreach libpin [nl_get_libcell_pins $libcell] {
	set use [nl_get_libpin_use $libpin]

	if { $use == {power} || $use == {ground} } {
	    continue
	}

	set bus [nl_get_libpin_bus $libpin]

	if { $bus != {} && $bus == $prev_bus } {
	    continue
	}

	set prev_bus $bus

	if { $bus != {} } {
	    set type [nl_get_bus_type $bus]
	    set left [nl_get_type_left $type]
	    set right [nl_get_type_right $type]

	    nl_create_refpin_bus [nl_get_bus_name $bus] $left $right $ref
	} else {
	    nl_create_refpin [nl_get_libpin_name $libpin] $ref
	}
    }

    return $ref
}

nl_register_command nl_create_reference_for_libcell


proc nl_get_reference_for_libcell args {
    nl_getopt nl_get_reference_for_libcell "Get the reference referring to the specified libcell.  Create one if none currently exists." {
    } {
	{libcell libcell "get the reference for this libcell"}
	&optional
	{design current_design "get the reference in this design"}
    } $args

    set refs [nl_find_references -exact [nl_get_libcell_name $libcell] $design]

    if { $refs != "" } {
	set ref [lindex $refs 0]
    } else {
	set ref [nl_create_reference_for_libcell $libcell $design]
    }

    return $ref
}

nl_register_command nl_get_reference_for_libcell
