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

proc set_timing_weights {{file -}} {
    if { $file == "-" } {
	set ofp stdout
    } else {
	set ofp [open $file "w"]
    }

    unwind_protect {
	set cells [list_cells -recur -library]

	foreach cell $cells {
	    set ref_name [get_reference_name [get_cell_reference $cell]]
	    set len [string length $ref_name]
	    set gate_size [string index $ref_name [expr $len - 1]]

	    switch $gate_size {
		A { set weight ultra }
		B { set weight high }
		C { set weight medium }
		D { set weight low }
		default { set weight {}}
	    }

	    if { $weight != {} } {
		set out_pins [get_cell_pins -output $cell]
		foreach out_pin $out_pins {
		    set out_net [get_pin_net $out_pin]

		    if { $out_net != {} } {
			puts $ofp "set_timing_weights -effort $weight {$out_net}"
		    }
		}
	    }
	}
    } {
	if { $ofp != "stdout" } {
	    close $ofp
	}
    }
}
