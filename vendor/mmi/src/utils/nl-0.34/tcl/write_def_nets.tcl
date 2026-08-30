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

proc write_def_nets {file} {
    global hierarchy_separator

    if { $file == "-" } {
	set ofp stdout
    } else {
	set ofp [open $file w]
    }

    fluid_let {{hierarchy_separator ",hier,"}} {
	set nets [list_nets -hierarchy -noassign -noconstant -noempty]
    
	puts $ofp "NETS [llength $nets] ;"

	foreach net $nets {
	    set net_name $net

	    set pins [get_net_pins -hierarchy -noassign $net]
	    
	    regsub -all "/" $net_name "\\/" net_name
	    regsub -all ",hier," $net_name "/" net_name
	    puts -nonewline $ofp "  - $net_name"
	
	    foreach pin $pins {
		set owner [get_pin_owner $pin]
		set owner_type [object_type $owner]

		regsub -all "/" $owner "\\/" owner
		regsub -all ",hier," $owner "/" owner

		if { $owner_type == "port" } {
		    puts -nonewline $ofp "\n    ( PIN $owner )"
		} else {
		    set pin_name [get_pin_name $pin]
		    puts -nonewline $ofp "\n    ( $owner $pin_name )"
		}
	    }
    
	    puts $ofp " ;"
	}
    }

    puts $ofp "END NETS"

    if { $ofp != "stdout" } {
	close $ofp
    }
}
