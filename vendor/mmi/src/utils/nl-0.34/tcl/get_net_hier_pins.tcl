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

proc get_net_hier_pins1 {net prefix no_port} {
    set result {}
    foreach pin [get_net_pins $net] {
	set owner [get_pin_owner $pin]
	set type [object_type $owner]
	set refpin [get_pin_refpin $pin]

	if {$type == "port"} {
	    if {$no_port == 0} {
		lappend result [join [concat $prefix $pin] "/"]
	    }
	} elseif {[get_refpin_down_port [get_pin_refpin $pin]] == {}} {
	    lappend result [join [concat $prefix $pin] "/"]
	} else {
	    set cell $owner
	    set down_port [get_refpin_down_port $refpin]
	    set down_pin [get_port_pin $down_port]
	    set down_net [get_pin_net $down_pin]

	    if {$down_net != {}} {
		set net_pins [get_net_hier_pins1 $down_net [concat $prefix $cell] 1]
		foreach net_pin $net_pins {
		    lappend result $net_pin
		}
	    }
	}
    }
    return $result
}

proc get_net_hier_pins {net} {
    get_net_hier_pins1 $net {} 0
}