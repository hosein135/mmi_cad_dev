## ************************************************************************
## 
## Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
## Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
## 
## Permission is hereby granted, without written agreement and without
## license or royalty fees, to use, copy, modify, and distribute this
## software and its documentation for any purpose, provided that the
## above copyright notice and the following three paragraphs appear in
## all copies of this software.
## 
## IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
## LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
## CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
## DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
## INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
## 
## JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
## DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
## NON-INFRINGEMENT.
## 
## THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
## NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
## PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
## 
## ************************************************************************


# Procedures for making/remaking icons.  There are two display formats
# for icons: either as instances in schematics or as icons for editing.
#
# Note that for performance reasons, icon procedures aren't directly
# executed to display instances (~1000 primitive tcl instructions typically).  
# Instead, they are first compiled into two procedures _MAKE_$type and
# _MAKE90_$type which are then directly executed.  _MAKE90_ is created to
# display the 90 degree rotated version of the icon since canvas do not
# have any built in rotations.  From _MAKE_ and _MAKE90_ and using x and
# y scaling, all rotations/mirroring of the icons is possible.  Note that
# the compiled versions only require about 100 primitive tcl instructions
# to draw their icons typically.

# XFORM is scaled down by 10 since all things are saved at scale 10

set XFORM(R0,x) 0.1
set XFORM(R0,y) 0.1
set XFORM(RX,x) -0.1
set XFORM(RX,y) 0.1
set XFORM(RY,x) 0.1
set XFORM(RY,y) -0.1
set XFORM(RXY,x) -0.1
set XFORM(RXY,y) -0.1
set XFORM(R90,x) -0.1
set XFORM(R90,y) 0.1
set XFORM(R90X,x) 0.1
set XFORM(R90X,y) 0.1
set XFORM(R90Y,x) -0.1
set XFORM(R90Y,y) -0.1
set XFORM(R270,x) 0.1
set XFORM(R270,y) -0.1

set XFORM(R0,start) ""
set XFORM(R0,extent) 1
set XFORM(RX,start) "180 - "
set XFORM(RX,extent) -1
set XFORM(RY,start) "0 - "
set XFORM(RY,extent) -1
set XFORM(RXY,start) "180 + "
set XFORM(RXY,extent) 1
set XFORM(R90,start) "270 + "
set XFORM(R90,extent) 1
set XFORM(R90X,start) "270 - "
set XFORM(R90X,extent) -1
set XFORM(R90Y,start) "90 - "
set XFORM(R90Y,extent) -1
set XFORM(R270,start) "90 + "
set XFORM(R270,extent) 1

set XFORM(R0) ""
set XFORM(RX) ""
set XFORM(RY) ""
set XFORM(RXY) ""
set XFORM(R90) 90
set XFORM(R90X) 90
set XFORM(R90Y) 90
set XFORM(R270) 90

set XFORM(MX,R0) RX
set XFORM(MX,RX) R0
set XFORM(MX,RY) RXY
set XFORM(MX,RXY) RY
set XFORM(MX,R90) R90X
set XFORM(MX,R90X) R90
set XFORM(MX,R90Y) R270
set XFORM(MX,R270) R90Y

set XFORM(MY,R0) RY
set XFORM(MY,RX) RXY
set XFORM(MY,RY) R0
set XFORM(MY,RXY) RX
set XFORM(MY,R90) R90Y
set XFORM(MY,R90X) R270
set XFORM(MY,R90Y) R90
set XFORM(MY,R270) R90X

set XFORM(ROTATE,R0) R90
set XFORM(ROTATE,R90) RXY
set XFORM(ROTATE,RXY) R270
set XFORM(ROTATE,R270) R0
set XFORM(ROTATE,RX) R90Y
set XFORM(ROTATE,RY) R90X
set XFORM(ROTATE,R90X) RX
set XFORM(ROTATE,R90Y) RY

if {$ROTATE_TEXT} {
  # text rotation
  # only works for special modified versions of canvases

  set ROTATE_CMD(0) "-rotate 0"
  set ROTATE_CMD(1) "-rotate 1"
  set ROTATE_CMD() "-rotate 0"
  set ROTATE_CMD(90) "-rotate 1"

  set XFORM(ROTATE,0,R0) ""
  set XFORM(ROTATE,0,R90) "rotate"
  set XFORM(ROTATE,0,RXY) ""
  set XFORM(ROTATE,0,R270) "rotate"
  set XFORM(ROTATE,0,RX) ""
  set XFORM(ROTATE,0,RY) ""
  set XFORM(ROTATE,0,R90X) "rotate"
  set XFORM(ROTATE,0,R90Y) "rotate"

  set XFORM(ROTATE,1,R0) "rotate"
  set XFORM(ROTATE,1,R90) ""
  set XFORM(ROTATE,1,RXY) "rotate"
  set XFORM(ROTATE,1,R270) ""
  set XFORM(ROTATE,1,RX) "rotate"
  set XFORM(ROTATE,1,RY) "rotate"
  set XFORM(ROTATE,1,R90X) ""
  set XFORM(ROTATE,1,R90Y) ""

  # for changing the anchor points on text

  set XFORM(R0,0,n) n
  set XFORM(R0,0,s) s
  set XFORM(R0,0,e) e
  set XFORM(R0,0,w) w
  set XFORM(R0,0,nw) nw
  set XFORM(R0,0,sw) sw
  set XFORM(R0,0,ne) ne
  set XFORM(R0,0,se) se
  set XFORM(R0,0,center) center
  set XFORM(R0,0,c) center

  set XFORM(RX,0,n) n
  set XFORM(RX,0,s) s
  set XFORM(RX,0,e) w
  set XFORM(RX,0,w) e
  set XFORM(RX,0,nw) ne
  set XFORM(RX,0,ne) nw
  set XFORM(RX,0,sw) se
  set XFORM(RX,0,se) sw
  set XFORM(RX,0,center) center
  set XFORM(RX,0,c) center

  set XFORM(RY,0,n) s
  set XFORM(RY,0,s) n
  set XFORM(RY,0,e) e
  set XFORM(RY,0,w) w
  set XFORM(RY,0,nw) sw
  set XFORM(RY,0,ne) se
  set XFORM(RY,0,se) ne
  set XFORM(RY,0,sw) nw
  set XFORM(RY,0,center) center
  set XFORM(RY,0,c) center

  set XFORM(RXY,0,n) s
  set XFORM(RXY,0,s) n
  set XFORM(RXY,0,e) w
  set XFORM(RXY,0,w) e
  set XFORM(RXY,0,ne) sw
  set XFORM(RXY,0,nw) se
  set XFORM(RXY,0,se) nw
  set XFORM(RXY,0,sw) ne
  set XFORM(RXY,0,center) center
  set XFORM(RXY,0,c) center

  set XFORM(R90,0,n) n
  set XFORM(R90,0,s) s
  set XFORM(R90,0,e) e
  set XFORM(R90,0,w) w
  set XFORM(R90,0,nw) nw
  set XFORM(R90,0,ne) ne
  set XFORM(R90,0,se) se
  set XFORM(R90,0,sw) sw
  set XFORM(R90,0,center) center
  set XFORM(R90,0,c) center

  set XFORM(R270,0,n) n
  set XFORM(R270,0,s) s
  set XFORM(R270,0,e) w
  set XFORM(R270,0,w) e
  set XFORM(R270,0,nw) ne
  set XFORM(R270,0,ne) nw
  set XFORM(R270,0,sw) se
  set XFORM(R270,0,se) sw
  set XFORM(R270,0,center) center
  set XFORM(R270,0,c) center

  set XFORM(R90X,0,n) n
  set XFORM(R90X,0,s) s
  set XFORM(R90X,0,e) e
  set XFORM(R90X,0,w) w
  set XFORM(R90X,0,nw) nw
  set XFORM(R90X,0,ne) ne
  set XFORM(R90X,0,sw) sw
  set XFORM(R90X,0,se) se
  set XFORM(R90X,0,center) center
  set XFORM(R90X,0,c) center

  set XFORM(R90Y,0,n) n
  set XFORM(R90Y,0,s) s
  set XFORM(R90Y,0,w) e
  set XFORM(R90Y,0,e) w
  set XFORM(R90Y,0,ne) nw
  set XFORM(R90Y,0,nw) ne
  set XFORM(R90Y,0,se) sw
  set XFORM(R90Y,0,sw) se
  set XFORM(R90Y,0,center) center
  set XFORM(R90Y,0,c) center

  set XFORM(R0,1,n) n
  set XFORM(R0,1,s) s
  set XFORM(R0,1,e) e
  set XFORM(R0,1,w) w
  set XFORM(R0,1,nw) nw
  set XFORM(R0,1,ne) ne
  set XFORM(R0,1,sw) sw
  set XFORM(R0,1,se) se
  set XFORM(R0,1,center) center
  set XFORM(R0,1,c) center

  set XFORM(RX,1,n) s
  set XFORM(RX,1,s) n
  set XFORM(RX,1,e) e
  set XFORM(RX,1,w) w
  set XFORM(RX,1,nw) sw
  set XFORM(RX,1,ne) se
  set XFORM(RX,1,sw) nw
  set XFORM(RX,1,se) ne
  set XFORM(RX,1,center) center
  set XFORM(RX,1,c) center

  set XFORM(RY,1,n) n
  set XFORM(RY,1,s) s
  set XFORM(RY,1,e) w
  set XFORM(RY,1,w) e
  set XFORM(RY,1,nw) ne
  set XFORM(RY,1,ne) nw
  set XFORM(RY,1,sw) se
  set XFORM(RY,1,se) sw
  set XFORM(RY,1,center) center
  set XFORM(RY,1,c) center

  set XFORM(RXY,1,n) n
  set XFORM(RXY,1,s) s
  set XFORM(RXY,1,w) e
  set XFORM(RXY,1,e) w
  set XFORM(RXY,1,ne) nw
  set XFORM(RXY,1,nw) ne
  set XFORM(RXY,1,se) sw
  set XFORM(RXY,1,sw) se
  set XFORM(RXY,1,center) center
  set XFORM(RXY,1,c) center

  set XFORM(R90,1,n) s
  set XFORM(R90,1,s) n
  set XFORM(R90,1,w) e
  set XFORM(R90,1,e) w
  set XFORM(R90,1,ne) sw
  set XFORM(R90,1,nw) se
  set XFORM(R90,1,se) nw
  set XFORM(R90,1,sw) ne
  set XFORM(R90,1,center) center
  set XFORM(R90,1,c) center

  set XFORM(R270,1,n) s
  set XFORM(R270,1,s) n
  set XFORM(R270,1,e) e
  set XFORM(R270,1,w) w
  set XFORM(R270,1,nw) sw
  set XFORM(R270,1,ne) se
  set XFORM(R270,1,sw) nw
  set XFORM(R270,1,se) ne
  set XFORM(R270,1,center) center
  set XFORM(R270,1,c) center

  set XFORM(R90X,1,n) n
  set XFORM(R90X,1,s) s
  set XFORM(R90X,1,e) e
  set XFORM(R90X,1,w) w
  set XFORM(R90X,1,ne) ne
  set XFORM(R90X,1,nw) nw
  set XFORM(R90X,1,se) se
  set XFORM(R90X,1,sw) sw
  set XFORM(R90X,1,center) center
  set XFORM(R90X,1,c) center

  set XFORM(R90Y,1,n) n
  set XFORM(R90Y,1,s) s
  set XFORM(R90Y,1,w) e
  set XFORM(R90Y,1,e) w
  set XFORM(R90Y,1,ne) nw
  set XFORM(R90Y,1,nw) ne
  set XFORM(R90Y,1,se) sw
  set XFORM(R90Y,1,sw) se
  set XFORM(R90Y,1,center) center
  set XFORM(R90Y,1,c) center

} else {
  # no text rotation
  # TODO add n,s,se,sw

  set ROTATE_CMD(0) ""
  set ROTATE_CMD(1) ""
  set ROTATE_CMD() ""
  set ROTATE_CMD(90) ""

  set XFORM(ROTATE,0,R0) ""
  set XFORM(ROTATE,0,R90) ""
  set XFORM(ROTATE,0,RXY) ""
  set XFORM(ROTATE,0,R270) ""
  set XFORM(ROTATE,0,RX) ""
  set XFORM(ROTATE,0,RY) ""
  set XFORM(ROTATE,0,R90X) ""
  set XFORM(ROTATE,0,R90Y) ""

  set XFORM(ROTATE,1,R0) ""
  set XFORM(ROTATE,1,R90) ""
  set XFORM(ROTATE,1,RXY) ""
  set XFORM(ROTATE,1,R270) ""
  set XFORM(ROTATE,1,RX) ""
  set XFORM(ROTATE,1,RY) ""
  set XFORM(ROTATE,1,R90X) ""
  set XFORM(ROTATE,1,R90Y) ""

  # for changing the anchor points on text (not very good)

  set XFORM(R0,0,w) w
  set XFORM(R0,0,nw) nw
  set XFORM(R0,0,e) e
  set XFORM(R0,0,ne) ne
  set XFORM(R0,0,center) center
  set XFORM(R0,0,c) center
  set XFORM(RX,0,w) e
  set XFORM(RX,0,nw) ne
  set XFORM(RX,0,e) w
  set XFORM(RX,0,ne) nw
  set XFORM(RX,0,center) center
  set XFORM(RX,0,c) center
  set XFORM(RY,0,w) w
  set XFORM(RY,0,nw) nw
  set XFORM(RY,0,e) e
  set XFORM(RY,0,ne) ne
  set XFORM(RY,0,center) center
  set XFORM(RY,0,c) center
  set XFORM(RXY,0,w) e
  set XFORM(RXY,0,nw) ne
  set XFORM(RXY,0,e) w
  set XFORM(RXY,0,ne) nw
  set XFORM(RXY,0,center) center
  set XFORM(RXY,0,c) center
  set XFORM(R90,0,w) center
  set XFORM(R90,0,nw) center
  set XFORM(R90,0,e) center
  set XFORM(R90,0,ne) center
  set XFORM(R90,0,center) center
  set XFORM(R90,0,c) center
  set XFORM(R270,0,w) center
  set XFORM(R270,0,nw) center
  set XFORM(R270,0,e) center
  set XFORM(R270,0,ne) center
  set XFORM(R270,0,center) center
  set XFORM(R270,0,c) center
  set XFORM(R90X,0,w) center
  set XFORM(R90X,0,nw) center
  set XFORM(R90X,0,e) center
  set XFORM(R90X,0,ne) center
  set XFORM(R90X,0,center) center
  set XFORM(R90X,0,c) center
  set XFORM(R90Y,0,w) center
  set XFORM(R90Y,0,nw) center
  set XFORM(R90Y,0,e) center
  set XFORM(R90Y,0,ne) center
  set XFORM(R90Y,0,center) center
  set XFORM(R90Y,0,c) center

  set XFORM(R0,1,w) w
  set XFORM(R0,1,nw) nw
  set XFORM(R0,1,e) e
  set XFORM(R0,1,ne) ne
  set XFORM(R0,1,center) center
  set XFORM(R0,1,c) center
  set XFORM(RX,1,w) e
  set XFORM(RX,1,nw) ne
  set XFORM(RX,1,e) w
  set XFORM(RX,1,ne) nw
  set XFORM(RX,1,center) center
  set XFORM(RX,1,c) center
  set XFORM(RY,1,w) w
  set XFORM(RY,1,nw) nw
  set XFORM(RY,1,e) e
  set XFORM(RY,1,ne) ne
  set XFORM(RY,1,center) center
  set XFORM(RY,1,c) center
  set XFORM(RXY,1,w) e
  set XFORM(RXY,1,nw) ne
  set XFORM(RXY,1,e) w
  set XFORM(RXY,1,ne) nw
  set XFORM(RXY,1,center) center
  set XFORM(RXY,1,c) center
  set XFORM(R90,1,w) center
  set XFORM(R90,1,nw) center
  set XFORM(R90,1,e) center
  set XFORM(R90,1,ne) center
  set XFORM(R90,1,center) center
  set XFORM(R90,1,c) center
  set XFORM(R270,1,w) center
  set XFORM(R270,1,nw) center
  set XFORM(R270,1,e) center
  set XFORM(R270,1,ne) center
  set XFORM(R270,1,center) center
  set XFORM(R270,1,c) center
  set XFORM(R90X,1,w) center
  set XFORM(R90X,1,nw) center
  set XFORM(R90X,1,e) center
  set XFORM(R90X,1,ne) center
  set XFORM(R90X,1,center) center
  set XFORM(R90X,1,c) center
  set XFORM(R90Y,1,w) center
  set XFORM(R90Y,1,nw) center
  set XFORM(R90Y,1,e) center
  set XFORM(R90Y,1,ne) center
  set XFORM(R90Y,1,center) center
  set XFORM(R90Y,1,c) center
}



# For display properties

# ul = upper left
set XFORM(labelx,ul,R0) 0
set XFORM(labely,ul,R0) 1
set XFORM(labelx,ul,RX) 2
set XFORM(labely,ul,RX) 1
set XFORM(labelx,ul,RY) 0
set XFORM(labely,ul,RY) 3
set XFORM(labelx,ul,RXY) 2
set XFORM(labely,ul,RXY) 3
set XFORM(labelx,ul,R90) 2
set XFORM(labely,ul,R90) 1
set XFORM(labelx,ul,R270) 0
set XFORM(labely,ul,R270) 3
set XFORM(labelx,ul,R90X) 0
set XFORM(labely,ul,R90X) 1
set XFORM(labelx,ul,R90Y) 2
set XFORM(labely,ul,R90Y) 3

if {$ANCHOR_IN} {
  set XFORM(anchor,ul,R0) se
  set XFORM(anchor,ul,RX) sw
  set XFORM(anchor,ul,RY) ne
  set XFORM(anchor,ul,RXY) nw
  set XFORM(anchor,ul,R90) se
  set XFORM(anchor,ul,R270) nw
  set XFORM(anchor,ul,R90X) ne
  set XFORM(anchor,ul,R90Y) sw
} else {
  # more compact but chance of overlap
  set XFORM(anchor,ul,R0) sw
  set XFORM(anchor,ul,RX) se
  set XFORM(anchor,ul,RY) nw
  set XFORM(anchor,ul,RXY) ne
  set XFORM(anchor,ul,R90) sw
  set XFORM(anchor,ul,R270) ne
  set XFORM(anchor,ul,R90X) nw
  set XFORM(anchor,ul,R90Y) se
}

# ur = upper right
set XFORM(labelx,ur,R0) 2
set XFORM(labely,ur,R0) 1
set XFORM(labelx,ur,RX) 0
set XFORM(labely,ur,RX) 1
set XFORM(labelx,ur,RY) 2
set XFORM(labely,ur,RY) 3
set XFORM(labelx,ur,RXY) 0
set XFORM(labely,ur,RXY) 3
set XFORM(labelx,ur,R90) 2
set XFORM(labely,ur,R90) 3
set XFORM(labelx,ur,R270) 0
set XFORM(labely,ur,R270) 1
set XFORM(labelx,ur,R90X) 0
set XFORM(labely,ur,R90X) 3
set XFORM(labelx,ur,R90Y) 2
set XFORM(labely,ur,R90Y) 1

set XFORM(anchor,ur,R0) sw
set XFORM(anchor,ur,RX) se
set XFORM(anchor,ur,RY) nw
set XFORM(anchor,ur,RXY) ne
set XFORM(anchor,ur,R90) sw
set XFORM(anchor,ur,R270) ne
set XFORM(anchor,ur,R90X) nw
set XFORM(anchor,ur,R90Y) se

# lr = lower right
set XFORM(labelx,lr,R0) 2
set XFORM(labely,lr,R0) 3
set XFORM(labelx,lr,RX) 0
set XFORM(labely,lr,RX) 3
set XFORM(labelx,lr,RY) 2
set XFORM(labely,lr,RY) 1
set XFORM(labelx,lr,RXY) 0
set XFORM(labely,lr,RXY) 1
set XFORM(labelx,lr,R90) 0
set XFORM(labely,lr,R90) 3
set XFORM(labelx,lr,R270) 2
set XFORM(labely,lr,R270) 1
set XFORM(labelx,lr,R90X) 2
set XFORM(labely,lr,R90X) 3
set XFORM(labelx,lr,R90Y) 0
set XFORM(labely,lr,R90Y) 1

set XFORM(anchor,lr,R0) nw
set XFORM(anchor,lr,RX) ne
set XFORM(anchor,lr,RY) sw
set XFORM(anchor,lr,RXY) se
set XFORM(anchor,lr,R90) nw
set XFORM(anchor,lr,R270) se
set XFORM(anchor,lr,R90X) nw
set XFORM(anchor,lr,R90Y) se

# ll = lower left
set XFORM(labelx,ll,R0) 0
set XFORM(labely,ll,R0) 3
set XFORM(labelx,ll,RX) 2
set XFORM(labely,ll,RX) 3
set XFORM(labelx,ll,RY) 0
set XFORM(labely,ll,RY) 1
set XFORM(labelx,ll,RXY) 2
set XFORM(labely,ll,RXY) 1
set XFORM(labelx,ll,R90) 0
set XFORM(labely,ll,R90) 1
set XFORM(labelx,ll,R270) 2
set XFORM(labely,ll,R270) 3
set XFORM(labelx,ll,R90X) 2
set XFORM(labely,ll,R90X) 1
set XFORM(labelx,ll,R90Y) 0
set XFORM(labely,ll,R90Y) 3

set XFORM(anchor,ll,R0) ne
set XFORM(anchor,ll,RX) nw
set XFORM(anchor,ll,RY) se
set XFORM(anchor,ll,RXY) sw
set XFORM(anchor,ll,R90) ne
set XFORM(anchor,ll,R270) sw
set XFORM(anchor,ll,R90X) se
set XFORM(anchor,ll,R90Y) nw


# Entry point to display an instance of an icon.  If the icon has a procedure
# defined but that procedure hasn't yet been compiled yet into _MAKE_$type
# and _MAKE90_$type then it is first compiled and then displayed.

set __MAKE_SPECIAL__ 0

proc make {icon_type args} -type user -desc {

Primitive procedure to add an instance of an icon to the current
schematic at the given location with the given orientation and with
the given properties values.

Usage:

        make <icon_name> -origin <x_y_list> [-orient <orient>] <keyword_arguments>

The orientation defaults to R0.  

The keyword/argument pair order is unimportant.

<keyword_arguements> are unique for each icon and depend on the user
properties in the icon view of the cell.  Typically they contain at
least the "name" property.

Special tcl characters such as []$ must be quoted for surrounded by {}.

For example:

        sue> make inverter -name my_inv -origin {120 300} -orient RX
        sue> lappend ids [make input -name {in[2]} -origin {80 300}]

NOTE: this procedure can only be used on a new schematic or if
proceeded by api_zoom setup.  Otherwise, its position may be incorrect
or even off-grid.

ONLY the input, output, inout, and title_bar instances can be added to
the icon view of a cell.  Everything else must be lines, arcs, or text.

Returns the id of the icon or "" if unsuccessful.

NOT UN-DOABLE

Does not mark the cell as modified.  Use api_modify_cell to modify the cell
if desired.  Icons mus be marked modified to show their changes in
the schematics that they are instantiated into.

} {

  global cur_c cur_s scale FONT XFORM DISPLAY_PROPS COLORS ROTATE_CMD _MAKE_
  global GENERATORS _PROP_TYPES_
  upvar #0 icon_$icon_type g_data

  # has the drawing procedure been made yet for this type?
  # used to use
  #  if {[info commands _MAKE_$icon_type] == ""}
  # but this slowed down to 1.5 ms from < .2 ms

  if {![info exists _MAKE_($icon_type)]} {
    # first define the drawing procedure
    global _ICON_

    catch {unset _ICON_}

    set _ICON_(icon) instance
    set _ICON_(tag) "icon inst\$id"
    set _ICON_(type) $icon_type

    set error 0
    if {[catch [list ICON_$icon_type $args] msg]} {
      # it could be that the generator hasn't been defined
      if {[info exists GENERATORS($icon_type)]} {
	# make this generator
	if {[eval $GENERATORS($icon_type)] && \
		[info exists _MAKE_($icon_type)]} {
	  return [eval make $icon_type $args]

	} else {
          return [eval make "${icon_type}:[lindex $GENERATORS($icon_type) 2]" $args]
	}
      } else {
	# no generator to call
	set error 1
      }
    }

    if {!$error && ![info exists g_data(creator)]} {
      # error, probably no icon_setup
      set msg "Badly formed ICON procedure.  Probably missing or incorrect icon_setup command"
      set error 1
    }

    if {$error} {
      global __MAKE_SPECIAL__
      if {$__MAKE_SPECIAL__} {
	# just return
	return ""
      }

      # we got a problem.  It's probably can't find icon.
      if {$msg == "invalid command name \"ICON_$icon_type\""} {
	sue_error "SUE ERROR: Can't find icon definition for \"$icon_type\" in schematic \"$cur_s\""
      } else {
	sue_error "SUE ERROR: $msg in ICON \"$icon_type\""
	if {[string range $msg 0 4] != "Badly"} {
	  # don't leave anything.  Usually happens when user tried to change
	  # a generator and gave it bad values.
	  return ""
	}
      }

      # flag cell read only, so someone has to do something to modify it.
      upvar #0 SUE_$cur_s data

      if {![info exists data(read_only)] || $data(read_only) == 0} {
	sue_error "Converting cell to READ-ONLY."
      }

      set data(read_only) 1

      # put in the missing icon in the place of it
      call_use_keyword $args {{origin {0 0}}}
      set args [list -name $icon_type -origin $origin]
      set icon_type missing_icon
      if {[catch [list ICON_$icon_type $args] msg]} {
	# oh well, even this one doesn't work
	return ""
      } 

      set g_data(missing_icon) 1
    }

    lappend _ICON_(func) "return \$id"

    eval proc _MAKE_$icon_type [list "orient $g_data(prop_names)"] \
	[list [join $_ICON_(func) "\n"]]

    set _MAKE_($icon_type) 1

    lappend _ICON_(func90) "return \$id"

    eval proc _MAKE90_$icon_type [list "orient $g_data(prop_names)"] \
	[list [join $_ICON_(func90) "\n"]]

    # for api
    global ICON_TERMS
    set ICON_TERMS($icon_type) [use_first _ICON_(terms)]

    unset _ICON_
  }

  # now use it

  # get the keywords and go
  # Note that call_use_keyword is defining arbitrary variables.
  call_use_keyword $args $g_data(defaults)

  if {[catch {eval _MAKE$XFORM($orient)_$icon_type $orient $g_data(arglist)} \
	   id]} {
    # error create icon
    sue_error "SUE ERROR: $id in icon \"$icon_type\""

    # now we must clean up
    foreach id [$cur_c find withtag origin] {
      upvar #0 ${cur_s}_inst$id i_data
      if {![info exists i_data(orient)]} {
	# everything associated with this id is bogus
	$cur_c delete inst$id
	catch {unset i_data}
      }
    }

    return ""
  }

  upvar #0 ${cur_s}_inst$id i_data

  # save the orientation
  set i_data(orient) $orient

  # scale, mirror it, and move it (it is already rotated)
  $cur_c scale inst$id 0 0 [expr $XFORM($orient,x)*$scale] [expr $XFORM($orient,y)*$scale]
  eval $cur_c move inst$id $origin
  set fscale [expr int(ceil($scale))]

  # show display props at desired positions
  if {![info exists g_data(_primitive)]} {
    set bbox ""
    foreach prop_pair $DISPLAY_PROPS {
      set prop [lindex $prop_pair 0]
      if {[info exists g_data(\$$prop)]} {
	# this prop is already being shown, so don't show again
	continue
      }
      set pos [lindex $prop_pair 1]
      if {[info exists i_data(_$prop)] && [set data $i_data(_$prop)] != ""} {
	if {$prop == "name"} {
	  if {[string match "${icon_type}*" $data] || \
		  [string index $data 0] == "_"} {
	    if {[set i [string first \[ $data]] == -1} {
	      # special case -- don't show if same and type
	      continue
	    } else {
	      set data [string range $data $i end]
	    }
	  }
	  set extra_tag "_name_ "
	} else {
	  set extra_tag ""
	}

	if {[lindex $prop_pair 2] == ""} {
	  set text $data
	} else {
	  set text "[lindex $prop_pair 2]$data"
	}
	# must clean up the text
#	regsub -all {\[|\]|\"|\{|\}|\\} $text \\\\& text
#	if {[llength $text] > 1} {
#	  set text "\"$text\""
#	}

#	set _PROP_TYPES_($prop) 1

	setl {rotate value} $ROTATE_CMD($XFORM($orient))

	if {$pos == "origin"} {
	  set coords [$cur_c coords $id]
	  if {$rotate != ""} {
	    $cur_c create text [lindex $coords 0] [lindex $coords 1] \
		-anchor $XFORM($orient,0,c) -fill $COLORS(fore) \
		-text $text -font $FONT(standard,$fscale) \
		-tags "icon inst$id ${extra_tag}size_standard scaletext" \
		$rotate $value
	  } else {
	    $cur_c create text [lindex $coords 0] [lindex $coords 1] \
		-anchor $XFORM($orient,0,c) -fill $COLORS(fore) \
		-text $text -font $FONT(standard,$fscale) \
		-tags "icon inst$id ${extra_tag}size_standard scaletext"
	  }
	} else {
	  # only compute the bbox once and only if you have to
	  if {$bbox == ""} {
	    set bbox [$cur_c bbox inst$id]
	  }
	  if {$rotate != ""} {
	    $cur_c create text [lindex $bbox $XFORM(labelx,$pos,$orient)] \
		[lindex $bbox $XFORM(labely,$pos,$orient)] \
		-anchor $XFORM(anchor,$pos,$orient) -fill $COLORS(fore) \
		-text $text -font $FONT(standard,$fscale) \
		-tags "icon inst$id ${extra_tag}size_standard scaletext" \
		$rotate $value
	  } else {
	    $cur_c create text [lindex $bbox $XFORM(labelx,$pos,$orient)] \
		[lindex $bbox $XFORM(labely,$pos,$orient)] \
		-anchor $XFORM(anchor,$pos,$orient) -fill $COLORS(fore) \
		-text $text -font $FONT(standard,$fscale) \
		-tags "icon inst$id ${extra_tag}size_standard scaletext"
	  }
	}
      }
    }
  }

#  global HIDDEN_PROPS
#  foreach prop $HIDDEN_PROPS {
##    toggle_hidden_prop ${prop}&inst$id hidden
#    toggle_hidden_prop $prop hidden
#  }

  return $id
}


# Makes the icon for editing
# No drawing procedure needs to be made since this is only called solely.

proc icon_make {type args} {

  global cur_c cur_s scale FONT XFORM _ICON_

  catch {unset _ICON_}

  set _ICON_(icon) icon
  set _ICON_(tag) "draw_item"
  set _ICON_(type) $type

  # set scale to 10 for terminals and call the icon
  set save_scale $scale
  set scale 10
  set fscale $scale

  eval ICON_$type $args

  set scale $save_scale

  # the orientation of the icon is always R0
  set orient R0

  foreach line $_ICON_(func) {
    eval $line
  }

  $cur_c scale all 0 0 [expr $scale/10.0] [expr $scale/10.0]

  unset _ICON_
}



# creates the anchor rectangle (i.e., the origin) for an instance.

proc icon_setup {arglist defaults} {

  # do this in context of the calling procedure
  uplevel call_use_keyword $arglist [list $defaults]

  global _ICON_ COLORS

  set _ICON_(func) ""

  if {$_ICON_(icon) == "instance"} {
    upvar #0 icon_$_ICON_(type) icon_type
    catch {unset icon_type}

    set icon_type(defaults) $defaults
    set icon_type(arglist) ""
    set icon_type(prop_names) ""
    set icon_type(creator) $_ICON_(type)
    
    # if it's a generator, setup data structure for generator
    if {[info exists _ICON_(generator)]} {
      set icon_type(generator) $_ICON_(generator)
      set icon_type(gargs) $_ICON_(gargs)
      set icon_type(gdefaults) $_ICON_(gdefaults)
    }

    lappend _ICON_(func) "global cur_c cur_s scale FONT XFORM ICON_ERROR env"
    lappend _ICON_(func) "set fscale \[expr int(ceil(\$scale))\]"
    lappend _ICON_(func) "set id \[\$cur_c create line 0 0 0 0 -fill $COLORS(fore) -tags \"origin icon icon_$_ICON_(type)\"\]"
    lappend _ICON_(func) {$cur_c addtag inst$id withtag $id}
    lappend _ICON_(func) "upvar #0 \${cur_s}_inst\$id i_data"
    lappend _ICON_(func) "set i_data(type) $_ICON_(type)"

    set _ICON_(func90) $_ICON_(func)
  }
}


# creates a line for an icon
# args are a list of x,y pairs

proc icon_line {args} {

  global _ICON_ COLORS

  lappend _ICON_(func) "\$cur_c create line $args -tags \"$_ICON_(tag)\" -fill $COLORS(fore)"
  lappend _ICON_(func90) "\$cur_c create line [lreverse $args] -tags \"$_ICON_(tag)\" -fill $COLORS(fore)"
}


# creates an arc for an icon.  Note, an oval is an arc with an extent 
# of 359 degrees or so (can't use 360).

proc icon_arc {args} {

  global _ICON_ COLORS

  if {$_ICON_(icon) == "instance"} {

    # need to munge the orientation into the start and the extent
    if {[set pos [lsearch $args "-extent"]] != -1} {
      set extent [lindex $args [incr pos]]
    } else {
      set extent 360
    }

    if {[set pos [lsearch $args "-start"]] != -1} {
      set start [lindex $args [incr pos]]
    } else {
      set start 360
    }

    set se_args "-start \[eval expr \$XFORM(\$orient,start)$start\] -extent \[expr \$XFORM(\$orient,extent)*$extent\]"
  } else {
    set se_args [lrange $args 4 end]
  }

  lappend _ICON_(func) \
      "\$cur_c create arc [lrange $args 0 3] $se_args -style arc -outline $COLORS(fore) -tags \"$_ICON_(tag) arc\""
  lappend _ICON_(func90) \
      "\$cur_c create arc [lindex $args 1] [lindex $args 0] [lindex $args 3] [lindex $args 2] $se_args -style arc -outline $COLORS(fore) -tags \"$_ICON_(tag) arc\""
}


# creates text for an icon
# can pass in an optional anchor position

proc icon_text {origin text {size standard} {anchor w} {rotate 0}} {

  global _ICON_ COLORS ROTATE_CMD

  lappend _ICON_(func) "if {\[catch {\$cur_c create text $origin -text $text -font \$FONT($size,\$fscale) -tags \"$_ICON_(tag) size_$size scaletext\" -anchor \$XFORM(\$orient,$rotate,$anchor) -fill $COLORS(fore) $ROTATE_CMD($rotate)} msg\]} {lappend ICON_ERROR \$msg}"

  lappend _ICON_(func90) "if {\[catch {\$cur_c create text [lindex $origin 1] [lindex $origin 0] -text $text -font \$FONT($size,\$fscale) -tags \"$_ICON_(tag) size_$size scaletext\" -anchor \$XFORM(\$orient,$rotate,$anchor) -fill $COLORS(fore) $ROTATE_CMD([expr 1-$rotate])} msg\]} {lappend ICON_ERROR \$msg}"
}


# Used to display special icons like title_bars that show up in the
# icon but not in the instance of the icon

proc icon_special {args} {

  global _ICON_

  if {$_ICON_(icon) != "instance"} {
    # in an icon, show the title bar
    # first must save away the icon global array
    copy_array new_icon _ICON_

    set pos [lsearch $args -type]
    if {$pos == -1} {
      puts "SUE Warning, Badly formed argument list to icon_special in cell \"$_ICON_(type)\""
      return
    }
    set new_args [lreplace $args $pos [incr pos]]
    eval make [lindex $args $pos] $new_args

    # now restore state
    copy_array _ICON_ new_icon
  }
}


# creates an icon terminal (i.e. a small solid square)

proc icon_term {args} {

  call_by_keyword $args {{origin {0 0}} {type inout} {name ""} \
			     {orient R0} {priority term}}

  global _ICON_ COLORS XFORM

  # save these arguments for the api
  lappend _ICON_(terms) $args

  set x [lindex $origin 0]
  set y [lindex $origin 1]

  if {$_ICON_(icon) != "instance"} {
    # in an icon, actually show the full icon, not just a rectangle.
    # pretend to be a schematic and save state
    copy_array new_icon _ICON_
    set id [make $type -name $name -origin "$x $y" -orient $orient]
    
    # special case for priority not term
    if {$priority != "term"} {
      # special case of editing a primitive, so user can tell
      global cur_c cur_s scale FONT COLORS

      $cur_c create text [expr $x + $scale] [expr $y - $scale] \
	  -text "priority $priority" \
	  -font $FONT(small,$scale) -fill $COLORS(fore) \
	  -tags "icon inst$id size_small scaletext" -anchor c

      # special property for regenerating it
      $cur_c addtag priority_$priority withtag $id
    }

    # now restore state
    copy_array _ICON_ new_icon
    return
  }

  # assumes the scale is 10
#  set del [expr 10.0/6]
  set del 1.67

  # need to quote all special chars
  regsub -all {\[|\]} $name \\\\& name

  lappend _ICON_(func) \
      "\$cur_c create rectangle [expr $x - $del] [expr $y - $del] [expr $x + $del] [expr $y + $del] -tags \"$_ICON_(tag) term \{name $priority $type $name\} $XFORM(ROTATE,0,$orient)\" -fill $COLORS(fore) -outline {}"
  lappend _ICON_(func90) \
      "\$cur_c create rectangle [expr $y - $del] [expr $x - $del] [expr $y + $del] [expr $x + $del] -tags \"$_ICON_(tag) term \{name $priority $type $name\} $XFORM(ROTATE,1,$orient)\" -fill $COLORS(fore) -outline {}"
}


# create properties for the icon.  All text in icons are properties.

proc icon_property {args} {
  call_by_keyword $args {{origin {0 0}} {type text} {name ""} {label ""} \
			     {text ""} {default ""} {anchor w} \
			     {size standard} {rotate 0} {choices ""}}
  global _ICON_ scale env FONT COLORS _PROP_TYPES_

  if {$_ICON_(icon) == "instance"} {
    # make an instance of the icon for insertion into a schematic

    # generic data for the icon goes here
    upvar #0 icon_$_ICON_(type) g_data

    # labels have precedence
    if {$label != ""} {
      # need to quote all special chars
      regsub -all {\[|\]|\"|\{|\}|\\} $label \\\\& label

      # figure out what properties are being displayed here
      # TODO: look for ${foo} also
#      set tags ""
      set string $label
      while {[regexp {\$(([a-zA-Z0-9_-]+).*)} $string tmp string match]} {
	set g_data(\$$match) 1
#	set _PROP_TYPES_($match) 1
#	lappend tags prop_$match
      }

#      icon_text $origin \"$label\" $size $anchor $rotate $tags
      icon_text $origin \"$label\" $size $anchor $rotate

      return
    }

    switch $type {
      "text" { 
	icon_text $origin \"$text\" $size $anchor $rotate

	# figure out what properties are being displayed
	# TODO: look for ${foo} also
	while {[regexp {\$[a-zA-Z0-9_-]+} $text match]} {
	  set g_data($match) 1
	  set text [string range $text \
			[expr [string first $match $text] + 1] end]
	}
      }
      "user" { 
	if {[info exists g_data(_$name)] && $name != "_BREAK_"} {
	  puts "SUE Warning: Duplicate property \"$name\" in icon \"$_ICON_(type)\", skipped."
	  return
	}

	# can't use lappend since it puts {} around \$$name
	set g_data(arglist) [concat $g_data(arglist) \$$name]
	lappend g_data(prop_names) $name
    
	if {$text == ""} {
	  set text "\$$name"
	}

	lappend _ICON_(func) "set i_data(_$name) $text"
	lappend _ICON_(func90) "set i_data(_$name) $text"

	set g_data(_$name) $text
	set g_data(_$name,default) [eval concat $default]
	set g_data(_$name,choices) [eval concat $choices]
      }
      "fixed" - "auto" {
	# must be a fixed property
	set g_data(_$name) $text
      }
      "define" {
	# define a variable to be a tcl function
	# NOTE, requires {} around [] in icon
	# TODO: must change order in icon_write
	lappend _ICON_(func) "set $name \[eval concat $text\]"
	lappend _ICON_(func90) "set $name \[eval concat $text\]"
      }
      "comment" {
      }
      default {
	puts "SUE Warning: Unknown type \"$type\" in icon \"$_ICON_(type)\", ignoring."
      }
    }

  } else {
    # show the icon for editing in its own happy window

    if {$label != ""} { 
      icon_text $origin \{$label\} $size $anchor $rotate
    } else {
      # these definitions only show up in the icon editing window

      # remove origin, size, and anchor since they are passed separately
      foreach keyword {origin size anchor} {
	set pos [lsearch $args "-$keyword"]
	if {$pos != -1} {
	  set args [lreplace $args $pos [expr $pos+1]]
	}
      }
      icon_text $origin \{$args\} $size $anchor $rotate
    }
  }
}


# Look in the generic data (icon_<cell_name>) for a generator property
# to see if it is a generator.  However, it there is no creator
# property there, then the cell hasn't been defined.  In which case
# look in the icon procedure for the word "icon_generator"

proc is_generator {cell} {
  
  set cell_name [get_rootname $cell]

  upvar #0 icon_$cell_name g_data
  if {[use_first g_data(creator)] != ""} {
    # icon has been defined

    if {[use_first g_data(generator)] != ""} {
      # this is a generator
      return 1
    } else {
      # not a generator
      return 0
    }
 
  } else {
    # must look in the icon procedure if there is one to figure out
    if {[info proc ICON_$cell_name] == ""} {
      # no icon, not a generator
      return 0
    } else {
      if {[string first icon_generator [info body ICON_$cell_name]] == -1} {
	# no icon_generator, not a generator
	return 0
      } else {
	# this is a generator
	return 1
      }
    }
  }
}


# a call to this procedure needs to be in any icon definition that
# wants to be a generator.

proc icon_generator {arglist defaults} {

  global _ICON_

  # do this in context of the calling procedure
  uplevel call_use_keyword $arglist [list $defaults]

  # figure out generator name
  set name [string range [lindex [info level -1] 0] 5 end]

  # figure out the arg list
  set args ""
  foreach input $defaults {
    set variable [lindex $input 0]
    upvar $variable value
    if {[lindex $input 1] != $value} {
      lappend args -$variable $value
    }
  }

  # remember generator info
  set _ICON_(generator) $name
  set _ICON_(gargs) $args
  set _ICON_(gdefaults) $defaults
}


proc make_icon_origin {} {

  global cur_c cur_s scale COLORS

  if {[is_icon $cur_s]} {
    set plus [expr $scale/2.0]
    set minus [expr 0.0 - $scale/2.0]

    $cur_c create line 0 0 0 $plus 0 $minus 0 0 $plus 0 $minus 0 -fill \
	$COLORS(fore) -tags "origin_icon draw_item icon_[get_rootname $cur_s]"
  }
}


# flips or rotates selected depending on direction, either MX, MY, or ROTATE.
# Note that this will leave wires floating.  I never thought that dragging
# wires during this type of operation really saved any work.

proc transform_selected {dir} {

  global cur_c cur_s scale XFORM ROTATE_TEXT PROC

  modify_setup

  busy

  # gets all selected icons and draw_items (lines, text, arcs)
  set ids [string trim "[get_intersect_tag selected origin] [get_intersect_tag selected draw_item] [get_intersect_tag selected wire]"]

  if {$ids == ""} {
    # nothing selected
    ready
    return
  }

  integer_scale

  # if we are only transforming one object and its an origin, then we
  # only want to rotate/mirror it around its own origin.
  if {[llength $ids] == 1 && [is_tagged $ids origin]} {
    # undo stuff
    set PROC ""
    write_instances inst$ids 1 undo
    set save_proc $PROC
    setup_undo [transform_icon $ids $dir] $save_proc

    unscale

    ready
    return
  }

  # find group center for transformation
  set bbox [$cur_c bbox selected]
  if {$bbox == ""} {
    # nothing here, bail
    unscale

    ready
    return
  }

  # Note that this center moves because of rounding errors
  setl {xcenter ycenter} [center_bbox $bbox]

  # save undo info
  set PROC ""
  write_instances selected "" icon_undo
  write_wires selected icon_undo
  write_draw_items selected icon_undo
  set save_proc $PROC

  # special case for a single piece of text
  if {[llength $ids] == 1 && [$cur_c type $ids] == "text"} {
    if {$dir == "ROTATE" && $ROTATE_TEXT} {
      switch [$cur_c itemcget $ids -anchor] {
	"w" { 
	  set xcenter [lindex [$cur_c coords $ids] 0]
	  set ycenter [lindex [$cur_c coords $ids] 1]
	}
	"e" { 
	  if {[$cur_c itemcget $ids -rotate] == 0} {
	    set xcenter [expr round([lindex $bbox 2]/$scale)*$scale] 
	  } else {
	    set ycenter [expr round([lindex $bbox 3]/$scale)*$scale] 
	  }
	}
      }
    } else {

      unscale
      ready
      return
    }
  }

  remove_connects selected

  # remember spots that need to be cleaned up later
  eval $cur_c addtag clean overlapping $bbox
  $cur_c dtag selected clean
  set clean_wires ""
  set clean_terms ""
  foreach id [$cur_c find withtag clean] {
    if {[is_tagged $id wire]} {
      lappend clean_wires $id
      continue
    }
    if {[is_tagged $id term]} {
      lappend clean_terms [center $id]
    }
  }
  $cur_c dtag clean

  set new_ids ""

  # rotation is different than mirroring
  if {$dir == "ROTATE"} {
    # first move all objects so they reference centroid
    $cur_c move selected [expr 0 - $xcenter] [expr 0 - $ycenter]

    # now move to correct new rotated position relative to centroid
    foreach id $ids {
      set coords [$cur_c coords $id]
      set num_coords [llength $coords]
      set new_coords ""
      for {set i 0} {$i < $num_coords} {incr i 2} {
	lappend new_coords [expr 0 - [lindex $coords [expr $i + 1]]] \
	    [lindex $coords $i]
      }
      eval $cur_c coords $id $new_coords
    }

    # now move back from centriod to correct position
    $cur_c move selected $xcenter $ycenter

    # now rotate the objects themselves
    foreach id $ids {
      if {[is_tagged $id origin]} {
	lappend new_ids [transform_icon $id $dir no_show]
	continue
      }

      lappend new_ids $id

      if {[$cur_c type $id] == "text" && $ROTATE_TEXT} {
	set rotate [$cur_c itemcget $id -rotate]
	$cur_c itemconfigure $id -rotate [expr 1 - $rotate]
	$cur_c itemconfigure $id \
	    -anchor $XFORM(R90,$rotate,[$cur_c itemcget $id -anchor])
      } elseif {[$cur_c type $id] == "arc"} {
	set start [eval expr $XFORM(R90,start) [$cur_c itemcget $id -start]]
	set extent [expr $XFORM(R90,extent) * [$cur_c itemcget $id -extent]]
	$cur_c itemconfigure $id -start $start -extent $extent
      }
    }
  } else {
    # mirroring
    if {$dir == "MX"} {
      $cur_c scale selected $xcenter $ycenter -1.0 1.0
      set orient RX
    }
    if {$dir == "MY"} {
      $cur_c scale selected $xcenter $ycenter 1.0 -1.0
      set orient RY
    }

    foreach id $ids {
      if {[is_tagged $id origin]} {
	lappend new_ids [transform_icon $id $dir no_show]
	continue
      }

      lappend new_ids $id

      if {[$cur_c type $id] == "text"} {
	set rotate [$cur_c itemcget $id -rotate]
	$cur_c itemconfigure $id \
	    -anchor $XFORM($orient,$rotate,[$cur_c itemcget $id -anchor])
      } elseif {[$cur_c type $id] == "arc"} {
	set start [eval expr $XFORM($orient,start) \
		       [$cur_c itemcget $id -start]]
	set extent [expr $XFORM($orient,extent) * \
			[$cur_c itemcget $id -extent]]
	$cur_c itemconfigure $id -start $start -extent $extent
      }
    }
  }

  setup_undo $new_ids $save_proc

  # flag that this canvas has been modified
  is_modified

  if {[is_icon $cur_s]} {
    # don't show connects in an icon
    unscale

    ready
    return
  }

  unscale

  # this is going to take a while so show the user now
  update

  integer_scale

  show_connects selected

  foreach point $clean_terms {
    eval show_connect_point $point clean
  }
  foreach id $clean_wires {
    show_connect_wire $id clean
  }

  # now clean up connect on wires/terms that could have been transformed 
  # into connection
  eval $cur_c addtag clean overlapping [$cur_c bbox selected]
  $cur_c dtag selected clean
  set clean_wires ""
  set clean_terms ""
  foreach id [$cur_c find withtag clean] {
    if {[is_tagged $id wire]} {
      lappend clean_wires $id
      continue
    }
    if {[is_tagged $id term]} {
      lappend clean_terms [center $id]
    }
  }
  $cur_c dtag clean

  foreach point $clean_terms {
    eval show_connect_point $point clean
  }
  foreach id $clean_wires {
    show_connect_wire $id clean
  }

  unscale

  ready
}


# fixes up data structures for undo

proc id_undo {id_old id_new} {

  global cur_s cur_c

  # note that this will grow without bounds
  upvar #0 UNDO_$cur_s UNDO
  set UNDO($id_old) $id_new

  if {[is_tagged $id_new origin]} {
    # need to fix up TERMS data structure which contain netlisting info 
    # for icons
    upvar #0 TERMS_$cur_s TERMS

    foreach id [$cur_c find withtag inst$id_new] {
      if {[info exists TERMS($id_old)]} {
	set TERMS($id) $TERMS($id_old)
      }

      incr id_old
    }
  }

  return $id_new
}


# transforms ids through UNDO array since they could have changed

proc xform_ids {ids} {

  global cur_s
  upvar #0 UNDO_$cur_s UNDO

  set new_ids ""
  foreach id $ids {
    while {[info exists UNDO($id)]} {
      set id $UNDO($id)
    }

    lappend new_ids $id
  }

  return $new_ids
}


# makes the undo procedure

proc setup_undo {ids proc {no_delete ""} {final_proc ""}} {

  global cur_c cur_s scale

  lappend NEW_PROC "global scale"

  # delete old stuff
  if {$no_delete == ""} {
    lappend NEW_PROC "delete_selected \[xform_ids [list $ids]\] no_undo"
  }

  lappend NEW_PROC {set save_scale $scale}
  lappend NEW_PROC "scale_canvas $scale"
  lappend NEW_PROC {set ids ""}

  foreach line $proc {
    lappend NEW_PROC "lappend ids \[$line\]"
  }

  if {$no_delete != "wire"} {
    lappend NEW_PROC {select_ids $ids}
    lappend NEW_PROC {scale_canvas $save_scale}

    lappend NEW_PROC "update"
    lappend NEW_PROC "integer_scale"
    lappend NEW_PROC "show_connects selected"
    lappend NEW_PROC "unscale"
  }

  if {$final_proc != ""} {
    foreach line $final_proc {
      lappend NEW_PROC $line
    }
  }

  # define the procedure that undoes the delete
  proc undo {} [join $NEW_PROC "\n"]

  # now save away this proc
  save_undo
}


# rotates/mirrors a given icon only

proc transform_icon {id dir {no_show ""}} {

  global cur_s XFORM

  upvar #0 ${cur_s}_inst$id i_data
  set orient $i_data(orient)

  # set the new orientation
  set i_data(orient) $XFORM($dir,$orient)

  # now remake the icon
  set new_id [remake $id $id "" no_scale $no_show]

  # flag that this canvas has been modified
  is_modified

  return $new_id
}


# delete a id_old and then remake it using the information in
# the global data structure for id.  Thus can remake same or replace.

proc remake {id_old id {modify ""} {no_scale ""} {no_show ""} {no_select ""}} {

  global cur_c cur_s

  if {$no_scale == ""} {
    integer_scale
  }

  # get origin and orient of old id
  set coords [lrange [$cur_c coords $id_old] 0 1]
  upvar #0 ${cur_s}_inst$id_old i_data_old
  if {![info exists i_data_old(orient)]} {
    # must be a toasted icon.  Better clean it up
    $cur_c delete inst$id_old
    catch {unset i_data_old}
    unscale
    return
  }
  set orient $i_data_old(orient)
  set old_type $i_data_old(type)

  upvar #0 ${cur_s}_inst$id i_data
  set type $i_data(type)
  upvar #0 icon_$type g_data

  # build up the args
  set args "-origin [list $coords] -orient $orient"
  foreach name [use_first g_data(prop_names)] {
    lappend args -$name [use_first i_data(_$name) g_data(_$name,default)]
  }

  # is this selected
  set selected [is_tagged $id_old selected]

  # remember term locations
  foreach term_id [get_intersect_tag inst$id_old term] {
    set term_coords([round_list [center $term_id]]) 1
  }

  # delete old icon and lose the old data structure
  $cur_c delete inst$id_old
  unset i_data_old

  # now make the new icon 
  set new_id [eval make $type $args]

  # possibly update connection info if terminal locations have changed
  # Note that this will break if two terminals in the same icon overlap
  foreach term_id [get_intersect_tag inst$new_id term] {
    set xy [round_list [center $term_id]]
    if {[info exists term_coords($xy)]} {
      unset term_coords($xy)
    } else {
      set term_coords([round_list [center $term_id]]) 1
    }
  }
  if {![is_icon $cur_s] && [info exists term_coords] && $no_show == ""} {
    foreach xy [array names term_coords] {
      eval show_connect_point $xy clean
    }
  }

  if {$no_scale == ""} {
    unscale
  }

  if {$modify == ""} {
    # flag that this canvas has been modified
    is_modified
  }

  # reselect it if it was selected
  if {$selected && $no_select == ""} {
    select_ids $new_id add
    unhighlite_selected
  }

  return $new_id
}


# generates a new icon procedure from "generator" to be called "name"
# if one doesn't already exist.

proc generate {generator name args} -type user -desc {

Primitive procedure to run a generator with a given type, name and set
of arguments.  Before a generated icon can be added to a schematic
with the "make" command, it must be generated using the generate
command.  

Multiple identical generate commands are ignored.  Typically, a
generate line preceeds the first use of a generated icon in a
schematic but it can also preceed ever use with a small performance
penalty.

USAGE: generate <generator_name> <icon_name> <keyword_arguments>

<generator_name> is the name of the SUE generator.  

<icon_name> is the name of the desired icon/schematic that is
generated by running this generator with the given arguments.

<keyword_arguments> are keyword/value pair defined in the generator.

For example:

        sue> generate nand2 nand3 -ninputs 3
        sue> make nand3 -origin {130 260}

If you wish to use a generated icon without adding a generate line to
the schematic procedure, you can add the generate line to the global
array GENERATORS, instead.

} {

  global cur_c cur_s _ICON_ _MAKE_ GENERATORS

  # Just return if it already exists
  if {[info command ICON_$name] != "" && $generator != $name} {
    upvar #0 icon_$name g_data
#    if {$args != [use_first g_data(gargs)]} {
      # uh, oh trying to redefine this generator instance
#      sue_warning "SUE WARNING: generator $generator with name $name called with arguments \"$args\".  Existing generator (not replaced) has arguments \"[use_first g_data(gargs)]\"."
#    }
    return -1
  }

  add_auto_path $generator

  # extract out the name from the full path if given
  set genname [lindex [split_filename $generator] 1]
  set body $genname

  if {![info exists _MAKE_($genname)]} {
    # need to first make the default to set up g_data

    catch {unset _ICON_}
    set _ICON_(icon) instance
    set _ICON_(tag) "icon inst\$id"
    set _ICON_(type) $name

    if {[catch {ICON_$genname ""} msg]} {
      if {[info exists GENERATORS($genname)] && \
	      ![catch {ICON_[lindex $GENERATORS($genname) 1] ""} msg]} {
	# this translation worked
	set body [lindex $GENERATORS($genname) 1]

      } else {
	# we got a problem.  It's probably can't find generator.
	if {![info exists GENERATORS($name)]} {
	  if {$msg == "invalid command name \"ICON_$genname\""} {
	    sue_error "SUE ERROR: Can't find GENERATOR definition for \"$genname\" while making \"$name\" in cell $cur_s"
	  } else {
	    sue_error "SUE ERROR: $msg in GENERATOR in $cur_s \"$genname\""
	  }
	}

	unset _ICON_
	return 0
      }

      unset _ICON_
    }
  }

  # check to make sure that this is a generator
  upvar #0 icon_$genname g_data
  if {[array names g_data] != "" && [use_first g_data(generator)] == ""} {
    # not a generator, we got a problem
    sue_error "ERROR: tried to call \"$genname\" as a GENERATOR while making \"$name\" in cell $cur_s but it isn't one."

    return 0
  }

  set comment "  icon_property -origin {-100 -200} -type comment -text \"Generated from $genname $args\""
  eval proc ICON_$name args \
      [list [join [list [info body ICON_$body] $comment] \n]]

  # now make the new icon to compile and setup
  set id [eval make $name $args]
  if {$id == ""} {
    # generator errored out
    return 0
  }

  # delete the output
  $cur_c delete inst$id
  upvar #0 ${cur_s}_inst$id i_data
  catch {unset i_data}

  upvar #0 icon_$name g_data
  # this will insure that the generator name is correct
  set g_data(generator) $genname

  # need to add this to auto_path
  if {$name != $genname} {
    add_to_auto_index $name generators/$name
  }

  # FIX: this is really slow and should only be done once at the end	
#  make_icon_listbox

  return -1
}


# replaces an existing generator

proc regenerate {generator name args} {

  global cur_c MODIFY_ICON _MAKE_

  # save old generator args just in case we fail
  upvar #0 icon_$name g_data
  set old_args [use_first g_data(gargs)]

  # kill the old icon/schematic
  if {$generator == $name} {
    # special case for changing the generator default arguments
    catch {rename SCHEMATIC_$name SCHEMATIC_TMP_PROC}
    catch {rename ICON_$name ICON_TMP_PROC}
    delete_schematic $name
    catch {rename SCHEMATIC_TMP_PROC SCHEMATIC_$name}
    catch {rename ICON_TMP_PROC ICON_$name}
  } else {
    delete_schematic $name
    catch {rename ICON_$name ""}
  }

  # waste the old data structure if it exists
  catch {unset g_data}

  # lose any compiled version that may be around
  catch {unset _MAKE_($name)}
  catch {rename _MAKE_$name ""}
  catch {rename _MAKE90_$name ""}

  if {[eval generate $generator $name $args] == 0} {
    # generator errored out, recreate existing
    if {$old_args != ""} {
      eval generate $generator $name $old_args

    } else {
      # waste the old one if there is one
      catch {rename ICON_$name ""}
      upvar #0 icon_$name g_data
      catch {unset g_data}
    }

    return 0
  }

  # store this icon so it will propagate 
  set MODIFY_ICON([incr MODIFY_ICON(_index)]) $name

  # put it in the icon listboxes
  make_icon_listbox

  return -1
}


# replaces an instance with another instance in a schematic

proc setup_replace_instance {} {

  global cur_c

  modify_setup

  enter_mode replace abort_replace_mode

  # check to see if an instance is selected
  set id_old [lindex [get_intersect_tag selected origin] 0]
  if {$id_old == ""} {
    abort_replace_mode
    return
  }

  msg_window "Press Button-1 on icon or text to replace selected with, Ctrl-c cancels"

  bind_add -mode replace -hotkey Any-Button-1 \
      -command "replace_instance" \
      -help "Replace selected icon or text with highlighted one under cursor."

  bind_add -mode replace -hotkey Any-Control-c \
      -command "abort_replace_mode" \
      -help "Abort replace mode."

  bind_add -mode replace -hotkey space -command "help_window %x %y" \
      -help "Display this window."

  # binding icon items to highlight when you are over them
  $cur_c bind icon <Any-Enter> {item_enter}
  $cur_c bind icon <Any-Leave> {item_leave}

  # Note that we will have to undo this bind ourselves
  $cur_c bind scaletext <Any-Enter> {item_enter}
  $cur_c bind scaletext <Any-Leave> {item_leave}
}


proc replace_instance {} {

  global cur_c cur_s scale DONT_REPLACE_PROPS PROC

  set ids_old [get_intersect_tag selected origin]

  set id [find_origin [$cur_c find withtag current]]

  if {$id == "" || [lsearch $ids_old $id] != -1} {
    abort_replace_mode
    return
  }

  if {[is_tagged $id scaletext]} {
    # special case for text.  make text the name of the instance
    set id_old [lindex $ids_old 0]

    upvar #0 ${cur_s}_inst$id_old i_data_old
    if {![info exists i_data_old(_name)]} {
      # instance doesn't have a name property so punt
      abort_replace_mode
      return
    }

    integer_scale

    # setup for undo
    set PROC ""
    write_instances inst$id_old 1 undo
    set save_proc $PROC

    # make the text be the name of the icon
    set i_data_old(_name) [$cur_c itemcget $id -text]

    # setup undo stuff and do the switch
    setup_undo [remake $id_old $id_old "" no_scale] $save_proc

    unscale

    leave_mode replace
    $cur_c bind scaletext <Enter> ""
    $cur_c bind scaletext <Leave> ""

    return
  }

  if {![is_tagged $id origin]} {
    # not an instance or text, abort
    abort_replace_mode
    return
  }

  upvar #0 ${cur_s}_inst$id i_data

  integer_scale
  set PROC ""
  set new_ids ""
  set save_proc ""

  # multiple "old" ids can be replaced
  foreach id_old $ids_old {

    upvar #0 ${cur_s}_inst$id_old i_data_old

    # get the name and other save properties out of the old_icon
    # and put these properties temporarily into the id
    foreach prop $DONT_REPLACE_PROPS {
      if {[info exists i_data_old(_$prop)] && [info exists i_data(_$prop)]} {
	set save(_$prop) $i_data(_$prop)
	set i_data(_$prop) $i_data_old(_$prop)
      }
    }

    if {[info exists types($i_data_old(type))]} {
      incr types($i_data_old(type))
    } else {
      set types($i_data_old(type)) 1
    }

    # setup undo stuff and do the switch
    set PROC $save_proc
    write_instances inst$id_old 1 undo
    set save_proc $PROC

    lappend new_ids [remake $id_old $id "" no_scale]

    # restore existing properties to id
    if {[info exists save]} {
      foreach prop [array names save] {
	set i_data($prop) $save($prop)
      }

      catch {unset save}
    }
  }

  # undo
  setup_undo $new_ids $save_proc

  unscale

  set list ""
  foreach type [lsort -dictionary [array names types]] {
    if {$types($type) > 1} {
      lappend list "$type\($types($type)\)"
    } else {
      lappend list $type
    }
  }

  puts "Replaced [join $list ", "] with $i_data(type)."

  leave_mode replace
  $cur_c bind scaletext <Enter> ""
  $cur_c bind scaletext <Leave> ""
}


proc abort_replace_mode {} {

  global cur_c

  puts "Aborting replace mode."
  leave_mode replace

  $cur_c bind scaletext <Enter> ""
  $cur_c bind scaletext <Leave> ""
}


proc show_icon_term_names {} {

  global cur_s cur_c scale COLORS FONT XFORM

  set fscale [expr int(ceil($scale))]

  if {[is_placement $cur_s]} {
    # special case for placement cell
    # show ports specified through the ports file
    global DPC_SIZE DPC DPC_REL

    foreach inst_id [get_intersect_tag origin selected] {
      upvar #0 ${cur_s}_inst$inst_id i_data

      if {[string range $i_data(type) 0 6] != "_place_"} {
	# ignore I/O's, title_bars, etc
	continue
      }

      set name [use_first i_data(_instance)]

      if {[nl_object_type [nl_get_reference_link [nl_get_cell_reference $name]]] \
	      != "libcell"} {
	# hierarchical cell

	foreach pin [nl_get_cell_or_port_pins $name] {	
	  foreach to_pin [nl_get_net_pins -recursive -noassign \
			      [nl_get_pin_net $pin]] {	

	    set owner [nl_get_pin_owner $to_pin]	  
	  
	    if {[string first $name/ $owner] == 0} {
	      # this pin comes from this hier
	      lappend pins($pin) [_pin_location $to_pin $scale]
	    }
	  }
	}

	foreach pin [array names pins] {
	  if {[set count [llength $pins($pin)]] > 1} {
	    # find average location
	    set xt 0
	    set yt 0
	    foreach coords $pins($pin) {
	      setl {x y} $coords

	      set xt [expr $xt + $x]
	      set yt [expr $yt + $y]
	    }

	    set coord [list [expr 1.0 * $xt / $count] [expr 1.0 * $yt / $count]]
	    set suffix " ($count)"

	  } else {
	    # only one location
	    set coord [lindex $pins($pin) 0]
	    set suffix ""
	  }

	  switch [nl_get_pin_direction $pin] {
	    in { set prefix < }
	    out { set prefix > }
	    inout { set prefix <> }
	    default { set prefix "" }
	  }

	  setl {x y} $coord
	  set text "$prefix[string range $pin [string length $name/] end]$suffix"
	  $cur_c create text $x $y -tags "tmp scaletext size_small" \
	      -fill $COLORS(anchor) -text $text -font $FONT(small,$fscale)
	}

      } else {
	# leafcell (libcell in nl terminology)
	foreach kind {{-input <} {-output >} {-inout <>}} {
	  setl {switch prefix} $kind
	  foreach port [nl_get_cell_or_port_pins $switch $name] {
	    setl {x y} [_pin_location $port $scale]

	    $cur_c create text $x $y -tags "tmp scaletext size_small" \
		-fill $COLORS(anchor) -text "$prefix [nl_get_pin_name $port]" \
		-font $FONT(small,$fscale)
	  }
	}
      }
    }

  } else {
    # schematic
    foreach inst_id [get_intersect_tag origin selected] {
      foreach id [get_intersect_tag term inst$inst_id] {
	# get the terminal name
	set tags [$cur_c gettags $id]
	set name_list [lindex $tags [lsearch $tags "name*"]]
	switch [lindex $name_list 2] {
	  input { set prefix < }
	  output { set prefix > }
	  inout { set prefix <> }
	  default { set prefix "" }
	}

	set name "$prefix[lindex $name_list 3]"
	
	setl {x y} [$cur_c coords $id]

	if {[is_tagged $id rotate]} {
	  $cur_c create text $x $y -tags "tmp scaletext size_small" \
	      -fill $COLORS(anchor) -text $name -font $FONT(small,$fscale) \
	      -rotate 1
	} else {
	  $cur_c create text $x $y -tags "tmp scaletext size_small" \
	      -fill $COLORS(anchor) -text $name -font $FONT(small,$fscale)
	}
      }
    }
  }
}


proc show_instance_origins {} {

  global cur_c scale COLORS

  # waste any old anchors
  $cur_c delete anchor

  set del [expr $scale/3.0]

  foreach id [$cur_c find withtag origin] {
    setl {x y} [$cur_c coords $id]
    $cur_c create line [expr $x-$del] $y [expr $x+$del] $y $x $y \
	$x [expr $y-$del] $x [expr $y+$del] -tags "anchor tmp" -fill $COLORS(anchor) 
  }
}
