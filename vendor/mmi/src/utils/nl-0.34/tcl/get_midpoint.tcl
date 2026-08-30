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
	    set size 0
	} else {
	    set size $libcell_size($ref_name)
	}
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
