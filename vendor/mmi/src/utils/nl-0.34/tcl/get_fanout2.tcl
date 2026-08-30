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
    lmapcar -concat [lambda {net} {get_net_pins -loads -fanios $net}] \
	    [lmapcar get_pin_net [get_cell_pins -outputs -inouts $cell]]
}

proc get_cell_fanout_cells1 {cell} {
    set fanout_pins [get_cell_fanout_pins $cell]
    create_cell_attribute fanout_cell_tmp
    lmapcar -concat \
	    [lambda {cell} {
	        upvar cell_set cell_set
   	        if {[info exists cell_set($cell)] == 0} {
                    set cell_set($cell) 1
	            return $cell
	        } else {
     	            return {}
	        }
	    }] \
            [lmapcar get_pin_owner $fanout_pins]
}


proc get_cell_fanout_cells {args} {
    switch [lindex args 0] {
	-transitive

proc get_cell_fanout_cells {cell} {
    set fanout_pins [get_cell_fanout_pins $cell]
    create_cell_attribute fanout_cell_tmp
    lmapcar -concat \
	    [lambda {cell} {
	        upvar cell_set cell_set
   	        if {[info exists cell_set($cell)] == 0} {
                    set cell_set($cell) 1
	            return $cell
	        } else {
     	            return {}
	        }
	    }] \
            [lmapcar get_pin_owner $fanout_pins]
}

