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

set RCSVERSION(cct.tcl) { $Revision: 1.4 $ }

# interface to cct router 
# used when sourcing output of cct2max program.
# OOOOLLLDDDD

proc cct_via {type x y} -desc {
    generate via specified in cct script
} {
    # VIA defined in tech dependent tcl file (e.g. g25.tcl)
    global VIA

    # convert to microns
    set x [expr $x / 1000.0]
    set y [expr $y / 1000.0]

    # layer below
    setl {layer size} $VIA($type,down)
    set grow [expr $size / 2.0]
    set x0 [uusnap [expr $x - $grow]]
    set y0 [uusnap [expr $y - $grow]]
    set x1 [uusnap [expr $x + $grow]]
    set y1 [uusnap [expr $y + $grow]]
    layt_box exact $x0 $y0 $x1 $y1
    :paint $layer

    # layer above
    setl {layer size} $VIA($type,up)
    set grow [expr $size / 2.0]
    set x0 [uusnap [expr $x - $grow]]
    set y0 [uusnap [expr $y - $grow]]
    set x1 [uusnap [expr $x + $grow]]
    set y1 [uusnap [expr $y + $grow]]
    layt_box exact $x0 $y0 $x1 $y1
    :paint $layer

    # via
    setl {layer size} $VIA($type)
    set grow [expr $size / 2.0]
    set x0 [uusnap [expr $x - $grow]]
    set y0 [uusnap [expr $y - $grow]]
    set x1 [uusnap [expr $x + $grow]]
    set y1 [uusnap [expr $y + $grow]]
    layt_box exact $x0 $y0 $x1 $y1
    :paint $layer
}

#TODO currently ignoring -lead_ext and -trail_ext
proc cct_path {layer width args} -desc {
    generate wire path specified in cct script
} {

    # parse switches
    set coords [call_with_keyword $args { {lead_ext 0} {trail_ext 0} } ] 

    #grow by half width (in microns)
    set grow [expr $width / 2000.0]

    set x0 [pop coords] 
    set x0 [expr $x0 / 1000.0]
    set y0 [pop coords]
    set y0 [expr $y0 / 1000.0]
    while {$coords != {}} {
	set x [pop coords] 
	set x [expr $x / 1000.0]
	set y [pop coords]
	set y [expr $y / 1000.0]

	set r [grow_rect $grow [can_rect "$x0 $y0 $x $y"]]
	eval layt_box exact [eval uusnap $r]
	:paint $layer

         set x0 $x
         set y0 $y
    }
}
