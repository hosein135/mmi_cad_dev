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

proc nl_infer_buses_for_libcell {libcell} {
    set libpins [nl_get_libcell_pins $libcell]
    set libpin_regexp "^(\[A-Za-z0-9_\]+)\\\[(\[0-9\]+)\\\]$"

    foreach libpin $libpins {
	if { [nl_get_libpin_bus $libpin] != {} } {
	    continue
	}

	set libpin_name [nl_get_libpin_name $libpin]

	if { [regexp $libpin_regexp $libpin_name name base index] == 1 } {
	    if { [info exists buses($base)] == 0 } {
		set buses($base) {}
	    }
	    set __${base}($index) [llength $buses($base)]
	    lappend buses($base) $libpin
	}
    }
    
    if { [info exists buses] == 1 } {
	puts "$libcell:"
    }

    foreach bus [array names buses] {
	set indexes [array names __$bus]
	set sorted [lsort -integer -increasing $indexes]
	set width [llength $sorted]
	set last [expr $width - 1]
	
	set left [lindex $sorted $last]
	set right [lindex $sorted 0]

	if { $left - $right + 1 != [llength $sorted] } {
	    puts -nonewline "  not inferring $bus\[$left:$right\],"
	    puts            " all indexes are not present"
	    continue
	}

	set members $buses($bus)
	set members_ordered {}
	for {set i $right} {$i <= $left} {incr i} {
	    set array_name __${bus}($i)
	    set index [eval "expr $$array_name"]
	    set member [lindex $members $index]
	    lappend members_ordered $member
	}

	puts "  inferring $bus\[$left:$right\]"

	nl_create_bus $bus $left $right $members_ordered
    }
}


proc nl_infer_libpin_buses args {
    nl_getopt nl_infer_libpin_buses "Infer libpin buses (based on name) for all cells of the specified library" {
    } {
	{library library "infer libpin buses for this library"}
    } $args

    set libcells [nl_list_libcells $library]

    foreach libcell $libcells {
	nl_infer_buses_for_libcell $libcell
    }
}


nl_register_command nl_infer_libpin_buses
