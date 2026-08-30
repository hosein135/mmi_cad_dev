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

proc write_max {file} {
    set ofp [open $file "w"]

    set cells [list_cells -recursive -library -unlinked]

    foreach cell $cells {
	set loctype [get_cell_loctype $cell]
	
	if { $loctype == "FIXED" || $loctype == "PLACED" } {
	    set ref [get_cell_reference $cell]
	    set ref_name [get_reference_name $ref]
	    set location [get_cell_location $cell]
	    set x [expr [lindex $location 0] / 1000.0]
	    set y [expr [lindex $location 1] / 1000.0]
	    set orientation [get_cell_orientation $cell]
	    
	    switch $orientation {
		N  {set max_orient ""}
		S  {set max_orient "-orientation fy"}
		FN {set max_orient "-orientation fx"}
                FS {set max_orient "-orientation r180"}
		default {set max_orient ""}
	    }

	    puts $ofp "db_instance -id $cell -orientation $max_orient $ref_name $x $y
	    }

	    puts $ofp "    ($loctype))"
	}
    }

    close $ofp
}
