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

proc nl_get_uppermost_net args {
    nl_getopt nl_get_uppermost_net "Return the highest inet in the hierarchy that is connected to the specified inet." {
	{-noassign boolean "traverse assignments"}
    } {
	{net inet "get the uppermost net of this net"}
    } $args
    
    if { $noassign } {
	set nets [nl_get_net_nets -hierarchy -noassign $net]
    } else {
	set nets [nl_get_net_nets -hierarchy $net]
    }

    set designs [lmapcar get_net_design $nets]

    foreach design [lmapcar nl_get_net_design $nets] {
	set in_set($design) 1
    }

    foreach net $nets {
	set design [nl_get_net_design $net]

	set up_cell [nl_get_idesign_cell $design]

	if { $up_cell == {} } {
	    return $net
	}

	set up_design [nl_get_cell_design $up_cell]

	if { [info exists in_set($up_design)] == 0 } {
	    return $net
	}
    }

    error "nl_get_uppermost_net: internal error"
}


nl_register_command nl_get_uppermost_net
