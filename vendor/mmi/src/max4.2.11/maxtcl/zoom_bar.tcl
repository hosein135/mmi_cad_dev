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

set RCSVERSION(zoom_bar.tcl) { $Revision: 1.4 $ }

# procs for zoom slider (scale)
# (needs mhautils.tcl)

#zoomScaleIgnore used to break feedback loops between 
#zoomScale() and zoomScaleSet()
set zoomScaleIgnore 0

#   set zoomMinRadius to current resolution
#   set zoomMaxRadius to max dimension of current bbox
#   but not less than 10*zoomMinRadius
proc zoomComputeRadiusBounds {} {
    global zoomMinRadius
    global zoomMaxRadius
    set zoomMinRadius [res]
    set zoomMaxMin [expr 10*$zoomMinRadius]
    setl {xbot ybot xtop ytop} [lay_bbox]
    set w [expr $xtop-$xbot]
    set h [expr $ytop-$ybot]
    set zoomMaxRadius [expr ($w>$h)?$w:$h]
    if {$zoomMaxRadius<$zoomMaxMin} {set zoomMaxRadius $zoomMaxMin}
}

# called when user moves zoom slider
proc zoomScale {v} {
    global max_win
    global zoomMaxScale
    global zoomScaleIgnore
    global zoomMinRadius
    global zoomMaxRadius

    # we ignore motions of sliders due to reframing to avoid infinite
    # loop!
    if {$zoomScaleIgnore} {
	set zoomScaleIgnore 0
	return
    }

    # zoom min radius is function of resolution
    # zoom max radius is function of current bounding box
    zoomComputeRadiusBounds

    # fIn and fOut are zoom factors between 0 and 1.
    # transform so progressively less sensitive as we zoom in.
    set fIn [expr ($v+0.0) / $zoomMaxScale]
    set fOut [ expr (exp($fIn) - 1)/(exp(1) - 1) ]

    set zoomRadius [expr $zoomMinRadius + \
    	  ($zoomMaxRadius - $zoomMinRadius) * $fOut]

    setl {xbot ybot xtop ytop} [$max_win.layout frame]
    set xcenter [expr  ($xtop+$xbot)/2.0 ]
    set ycenter [expr  ($ytop+$ybot)/2.0 ]
    set xbot [uusnap [expr $xcenter - $zoomRadius ]]
    set ybot [uusnap [expr $ycenter - $zoomRadius ]]
    set xtop [uusnap [expr $xcenter + $zoomRadius ]]
    set ytop [uusnap [expr $ycenter + $zoomRadius ]]
    
    $max_win.layout frame $xbot $ybot $xtop $ytop
}

# called by layout widget to adjust slider when view changes
proc zoomScaleSet {} {
    global max_win
    global zoomMaxScale
    global zoomScaleIgnore
    global zoomMinRadius
    global zoomMaxRadius

    # zoom min radius is function of resolution
    # zoom max radius is function of current bounding box
    zoomComputeRadiusBounds

#   compute current zoomRadius from frame
    setl {xbot ybot xtop ytop} [dbt_frame]
    set w [expr $xtop-$xbot]
    set h [expr $ytop-$ybot]
    set zoomRadius [expr ($w<$h)?($w/2.0):($h/2.0)]

#   zoomRadius -> fOut -> fIn -> sliderPos
    set fOut [expr ($zoomRadius - $zoomMinRadius + 0.0)/($zoomMaxRadius-$zoomMinRadius)]
    set fIn [expr log($fOut*(exp(1)-1)+1)]
    set sliderPos [expr round($fIn*$zoomMaxScale)]

#   reset the scale to correspond to current view
#   set zoomScaleIgnore causes change this change in slider to be ignored
#   (i.e. don't do another zoom)
    set zoomScaleIgnore 1
    $max_win.zbar.scale set $sliderPos
}

proc zoom_bar_build {master} -desc { 
return new zoom_bar under master (doesn't pack it)
} { 
    global zoomMaxScale
    # From pat, 12/00:  The zoom bar scale position is computed from
    # the max window, but there is some slop, which resulted in tiny
    # little zooms not moving the scale bar at all.  So decreased
    # the courseness of the scale bar from 1000 to 100, which fixed it.
    set zoomMaxScale 100

    set zbar $master.zbar   
    frame $zbar
    button $zbar.msg0 -text "in <" -command {view_zoom2 .5} -padx 2 -pady 2 \
      -highlightthickness 0
    button $zbar.msg1 -text "> out" -command {view_zoom2 2.0} -padx 2 -pady 2 \
      -highlightthickness 0
    scale $zbar.scale -orient horizontal -showvalue 0 \
	    -from 0 \
	    -to $zoomMaxScale \
            -highlightthickness 0 \
	    -command {zoomScale}

    pack $zbar.msg0 -side left
    pack $zbar.msg1 -side right
    pack $zbar.scale -side left -fill x -expand 1

    return $zbar
}
