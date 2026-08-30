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

proc get_cell_fanout_pins {cell} {
    set out_pins [get_cell_pins -outputs -inouts $cell]
    set num_outs [llength $out_pins]
    set fanout_pins {}
    for {set i 0} {$i < $num_outs} {incr i} {
	set pin [lindex $out_pins $i]
	set net [get_pin_net $pin]
	set new_pins [get_net_pins -loads -fanios $net]
	set num_new_pins [llength $new_pins]
	for {set j 0} {$j < $num_new_pins} {incr j} {
	    lappend fanout_pins [lindex $new_pins $j]
	}
    }
    return $fanout_pins
}

proc get_cell_fanout_cells {cell} {
    set fanout_pins [get_cell_fanout_pins $cell]
    set num_pins [llength $fanout_pins]
    set fanout_cells {}
    for {set i 0} {$i < $num_pins} {incr i} {
	set pin [lindex $fanout_pins $i]
	set owner [get_pin_owner $pin]
        if {[info exists cell_set($owner)] == 0} {
	    lappend fanout_cells $owner
	    set cell_set($owner) 1
	}
    }
    return $fanout_cells
}
