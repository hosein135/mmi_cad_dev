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

proc nl_make_row_sites_custom args {
    nl_getopt make_row_sites_custom "Build a row site array according to the specifications." {
    } {
	{core string "the name of the core site"}
	{area tcl_object "the core area as a list: {x_min y_min x_max y_max}"}
	{width integer "the width of each site in DEF units"}
	{height integer "the height of each site in DEF units"}
	&optional
	{pdesign current_idesign "make row sites for this design"}
    } $args

    set x0 [lindex $area 0]
    set y0 [lindex $area 1]
    set x_max [lindex $area 2]
    set y_max [lindex $area 3]

    set count [expr ($x_max - $x0) / $width]
    set row_num 1

    while { $y0 + $height <= $y_max } {
	set row_name [format "ROW_%04d" $row_num]

	if { $row_num % 2 == 1 } {
	    set orient N
	} else {
	    set orient S
	}

	add_row_site $row_name $core $x0 $y0 $orient $count $width $height $pdesign

	incr row_num
	incr y0 $height
    }
}

nl_register_command nl_make_row_sites_custom


proc nl_make_row_sites args {
    nl_getopt make_row_sites "Fill the die area with row sites." {
	{-halo integer "leave a border of the specified size (in tracks) around the placeable area"}
    } {
	{core_name string "the name of the core site"}
	&optional
	{width integer "the site width in tracks (default is 1)"}
	{height integer "the row height in tracks (default is 10)"}
	{pdesign current_idesign "make row sites for this design"}
    } $args

    set area [get_die_area $pdesign]

    if { $area == {} } {
	error "make_row_sites: $pdesign does not have the die area set"
    }

    set x_tracks [lindex [get_x_tracks $pdesign] 0]
    set y_tracks [lindex [get_y_tracks $pdesign] 0]

    if { $x_tracks == {} || $y_tracks == {} } {
	error "make_row_sites: $pdesign does not have X and Y routing tracks"
    }

    set x_track_width [lindex $x_tracks 2]
    set y_track_width [lindex $y_tracks 2]

    set halo_x $halo
    set halo_y $halo

    set x0 [expr [lindex $area 0] + $halo_x]
    set y0 [expr [lindex $area 1] + $halo_y]
    set x1 [expr [lindex $area 2] - $halo_x]
    set y1 [expr [lindex $area 3] - $halo_y]

    if { $width == 0 } {
	set width 1
    }

    if { $height == 0 } {
	set height 10
    }

    set width_units [expr $width * $x_track_width]
    set height_units [expr $height * $y_track_width]

    nl_make_row_sites_custom $core_name "$x0 $y0 $x1 $y1" $width_units $height_units $pdesign
}

nl_register_command nl_make_row_sites
