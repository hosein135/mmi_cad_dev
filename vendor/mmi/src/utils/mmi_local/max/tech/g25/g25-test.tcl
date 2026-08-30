# g25-test.tcl technology file.  Companion to g25-test.tech.

# set default MAX viewing grid
set GRID(fine_default_size)   0.1
set GRID(coarse_default_size) 1.0


set MN_TYPICAL_WIRE_WIDTH 0.3

# DRC Database.  Access with techinfo command.

set DRC_DATA(connect,ct) {ndif pdif nwc pwc poly m1}
set DRC_DATA(connect,m1) {ct v12}
set DRC_DATA(connect,m2) {v12 v23}
set DRC_DATA(connect,m3) {v23 v34}
set DRC_DATA(connect,m4) {v34 v45}
set DRC_DATA(connect,m5) v45
set DRC_DATA(connect,ndif) ct
set DRC_DATA(connect,nwc) ct
set DRC_DATA(connect,pdif) ct
set DRC_DATA(connect,poly) ct
set DRC_DATA(connect,pwc) ct
set DRC_DATA(connect,v12) {m1 m2}
set DRC_DATA(connect,v23) {m2 m3}
set DRC_DATA(connect,v34) {m3 m4}
set DRC_DATA(connect,v45) {m4 m5}
set DRC_DATA(device,fet,nfet) {poly ndif}
set DRC_DATA(device,fet,pfet) {poly pdif}
set DRC_DATA(enclose,all_poly_dif,ct) 0.14
set DRC_DATA(enclose,implant,poly) 0.1
set DRC_DATA(enclose,m1,ct) 0.09
set DRC_DATA(enclose,m1,v12) 0.09
set DRC_DATA(enclose,m2,v12) 0.09
set DRC_DATA(enclose,m2,v23) 0.1
set DRC_DATA(enclose,m3,v23) 0.09
set DRC_DATA(enclose,m3,v34) 0.09
set DRC_DATA(enclose,m4,v34) 0.09
set DRC_DATA(enclose,m4,v45) 0.09
set DRC_DATA(enclose,m5,v45) 0.09
set DRC_DATA(enclose,nplus,ndif) 0.26
set DRC_DATA(enclose,nplus,nfet) 0.33
set DRC_DATA(enclose,nplus,nwc) 0.04
set DRC_DATA(enclose,nw,nwc) 0.16
set DRC_DATA(enclose,nw,pdif) 0.6
set DRC_DATA(enclose,pplus,pdif) 0.26
set DRC_DATA(enclose,pplus,pfet) 0.33
set DRC_DATA(enclose,pplus,pwc) 0.04
set DRC_DATA(layer_order) {m5 v45 m4 v34 m3 v23 m2 v12 m1 ct poly nfet pfet ndif pdif nwc pwc nw pplus nplus prb}
set DRC_DATA(space_to,ct_ndif,nfet) 0.22
set DRC_DATA(space_to,ct_pdif,pfet) 0.22
set DRC_DATA(space_to,ct_poly,nfet) 0.28
set DRC_DATA(space_to,ct_poly,pfet) 0.28
set DRC_DATA(space_to,nplus,pdif) 0.3
set DRC_DATA(space_to,nplus,pfet) 0.33
set DRC_DATA(space_to,nplus,pplus) 0.1
set DRC_DATA(space_to,nplus,pwc) 0.14
set DRC_DATA(space_to,nw,ndif) 0.6
set DRC_DATA(space_to,nw,pwc) 0.16
set DRC_DATA(space_to,poly_not_fet,od) 0.14
set DRC_DATA(space_to,pplus,ndif) 0.3
set DRC_DATA(space_to,pplus,nfet) 0.33
set DRC_DATA(space_to,pplus,nwc) 0.14
set DRC_DATA(space_to,v12,nfet,pfet) 0.01
set DRC_DATA(spacing,ct) 0.3
set DRC_DATA(spacing,m1) 0.32
set DRC_DATA(spacing,m2) 0.4
set DRC_DATA(spacing,m3) 0.4
set DRC_DATA(spacing,m4) 0.4
set DRC_DATA(spacing,m5) 0.46
set DRC_DATA(spacing,nfet) 0.5
set DRC_DATA(spacing,nplus) 0.44
set DRC_DATA(spacing,nw) 0.6
set DRC_DATA(spacing,od) 0.4
set DRC_DATA(spacing,pfet) 0.5
set DRC_DATA(spacing,poly) 0.36
set DRC_DATA(spacing,pplus) 0.44
set DRC_DATA(spacing,v12) 0.35
set DRC_DATA(spacing,v23) 0.35
set DRC_DATA(spacing,v34) 0.35
set DRC_DATA(spacing,v45) 0.35
set DRC_DATA(vias) {ct v12 v23 v34 v45}
set DRC_DATA(width,ct) 0.3
set DRC_DATA(width,m1) 0.32
set DRC_DATA(width,m2) 0.4
set DRC_DATA(width,m3) 0.4
set DRC_DATA(width,m4) 0.4
set DRC_DATA(width,m5) 0.44
set DRC_DATA(width,nplus) 0.44
set DRC_DATA(width,nw) 1.2
set DRC_DATA(width,od) 0.3
set DRC_DATA(width,poly) 0.24
set DRC_DATA(width,pplus) 0.44
set DRC_DATA(width,v12) 0.36
set DRC_DATA(width,v23) 0.36
set DRC_DATA(width,v34) 0.36
set DRC_DATA(width,v45) 0.36

# Variables passed directly from technology source file.

set foo bar
set LAYINFO(crap) bogus
