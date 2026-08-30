# g25.tcl technology dependent stuff for a generic 0.25um process.
# (supplements and extends g25.tech file)

# set Max viewing grid to something reasonable
set GRID(fine,default,size)   0.1
set GRID(coarse,default,size) 1.0

# cif ostyle to use for printing with plotps
set PRINT(plotps,ostyle) "gen"

### info for generators
# LAYINFO contains process parameters, used by the wiring tool,
# the stdcell generator and fet generator.

# This is the underlying max grid.  It should go away.
set LAYINFO(grid) 0.02

################################################################
# Process/foundry dependent parameters.
# Designated by LAYINFO name with no colon.
# The user should not really change these.

# These are for TSMC25, 2.5v process, dated 9-25-98.
# Definitions: PO=poly, CO=contact, NP=N+diffusion, PP=P+diffusion

# Note: In tsmc, a well,contact is the same as a contact.
# The contact size is really 0.3.  But the well tie contacts want
# to be exactly centered on the boundary, otherwise they will not
# align properly when a flipped cell is stacked adjacent and
# above/below this one, and max will complain.  To get the well
# contact to really be 0.3 and centered, we have to make 0.28 and
# centered, then max will expand it to 0.3 automatically.
# This automatic mask generation is not subject to the max grid,
# so it ends up exactly 0.15 above and below the centerline.  Yuck.
# Note: the contact is .28 instead of .3, so it can be centered
# without missing the max grid, above.  So all other contact
# spacings must have .02 added to compensate.  This affects the following:
# contact,width, well,contact,width, poly,contact,overlap, contact,gate,sep.

set LAYINFO(ppls,pdif,overlap) 0.26	;# PP.E.1
set LAYINFO(ppls,pwc,overlap) 0.04	;# PP.E.2
set LAYINFO(npls,ndif,overlap) 0.26	;# NP.E.1
set LAYINFO(npls,nwc,overlap) 0.04	;# NP.E.2
set LAYINFO(ppls,npls,sep) 0.1        ;# PP.C.6
set LAYINFO(nw,nwc,overlap) 0.16	;# OD.C.1
set LAYINFO(nw,pdif,overlap) 0.6	;# OD.C.4

set LAYINFO(p1,v0,overlap) 0.16  ;# CO.E.2
set LAYINFO(p1,diff,sep) 0.14		;# PO.C.1
set LAYINFO(p1,gate,overlap) 0.36	;# PO.O.1
set LAYINFO(p1,nwc,sep) 0.34		;# OD.C.6
set LAYINFO(p1,pwc,sep) 0.34		;# OD.C.6
set LAYINFO(p1,min_width) 0.24	;# PO.W.3
set LAYINFO(gate,min_width) 0.24	;# PO.W.1
set LAYINFO(gate,gate,sep) 0.4    		;# PO.S.1
set LAYINFO(p1,p1,sep) 0.36    		;# PO.S.2
set LAYINFO(diff,gate,overlap) 0.44

# This should really be 0.14, but to avoid problems given
# that the max grid is .02, add one grid to make it 0.16.
set LAYINFO(diff,v0,overlap) 0.16	;# CO.E.1
set LAYINFO(diff,diff,sep) 0.40		;# OD.S.1
set LAYINFO(pdif,min_width) 0.3  	;# OD.W.2
set LAYINFO(ndif,min_width) 0.3  	;# OD.W.2
set LAYINFO(ndif,ndif,sep) 0.40	
set LAYINFO(pdif,pdif,sep) 0.40		

set LAYINFO(v0,gate,sep) 0.24  	;# CO.C.1
# This should be width=0.3 and sep=0.3, but the max res in this
# technology is 0.02, and when you try to draw a via starting at
# the center, you do: 0.3/2 = .15, which is off-grid.
# Instead, use .28, and .32, and max will fix it.
set LAYINFO(v0,width) 0.28		;# CO.W.1 (should 0.3)
set LAYINFO(v0,v0,sep) 0.32		;# CO.S.1 (should 0.3)

# This could really be .01, not 0.1, for sides of contacts.
set LAYINFO(m1,min_width) 0.32
set LAYINFO(m2,min_width) 0.4
set LAYINFO(m3,min_width) 0.4
set LAYINFO(m4,min_width) 0.4
set LAYINFO(m5,min_width) 0.44
set LAYINFO(m1,m1,sep)   0.32
set LAYINFO(m2,m2,sep)   0.4
set LAYINFO(m3,m3,sep)   0.4
set LAYINFO(m4,m4,sep)   0.4
set LAYINFO(m5,m5,sep)   0.46
set LAYINFO(v1,width) 0.36
set LAYINFO(v1,v1,sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v2,width) 0.36
set LAYINFO(v2,v2,sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v3,width) 0.36
set LAYINFO(v3,v3,sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v4,width) 0.36
set LAYINFO(v4,v4,sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v5,width) 0.36
set LAYINFO(v5,v5,sep) 0.36     
# This could really be .01, not 0.1, for the narrow sides of contacts,
# but we dont have a way to specify that.
set LAYINFO(m1,v0,overlap) 0.10	;# M1.E.2
set LAYINFO(m1,v1,overlap) 0.10		;# VIA1.E.2
set LAYINFO(m2,v1,overlap) 0.10
set LAYINFO(m2,v2,overlap) 0.10
set LAYINFO(m3,v2,overlap) 0.10
set LAYINFO(m3,v3,overlap) 0.10
set LAYINFO(m4,v3,overlap) 0.10
set LAYINFO(m4,v4,overlap) 0.10
set LAYINFO(m5,v4,overlap) 0.10
set LAYINFO(metal,sd) 1
set LAYINFO(m1,router_pad_size) "0.6 x 0.6" ;# Size of landing pad for router.

################################################################
# These are used only as defaults the fet generator.
set LAYINFO(default_nfet_length) $LAYINFO(gate,min_width)
set LAYINFO(default_nfet_width) 1.0
set LAYINFO(default_pfet_length) $LAYINFO(gate,min_width)
set LAYINFO(default_pfet_width) 2.0


################################################################
# These are the default parameters for the Layout Generator.
set LAYINFO(stdcell:cell_height) 10.0
set LAYINFO,HELP(stdcell:cell_height) {-number -incr 1}
set LAYINFO(stdcell:cell_width_pitch)  1.0   ;# Width is a multiple of this
set LAYINFO(stdcell:power_strap_width) 1.40
set LAYINFO(stdcell:well_v0_pitch) 1.0
set LAYINFO(stdcell:router_pitch) 1.0  ;# Router pitch for poly/metal.
set LAYINFO(stdcell:router_offset_x_y) "0.5,0.5" 

# TEMPORARY: maxy looks for this by mistake:
set LAYINFO(stdcell:router_offset_x,y) "0.5,0.5" 

set LAYINFO(stdcell:N/P_boundary) 5.0  ;# Height of cell devoted to N vs P
set LAYINFO,HELP(stdcell:N/P_boundary) {-number -incr 0.5}
# Well Ties.
# nwc,width should be calculated by:
# nwc,width = well,v0,width + 2*diff,v0,overlap = .62
# But it must be centered at the top/bottom of cell, and .62 / 2 = .31,
# which is currently off max grid, so round up to .64
set LAYINFO(stdcell:nwc,width) 0.64
set LAYINFO(stdcell:pwc,width) 0.64

# order of routable layers from the top
set ROUTE(order) "m5 m4 m3 m2 m1 p1 ndif pdif"
# Default route layer, if none found under cursor.  User may change.
set ROUTE(default_layer) m1

# These are the layers the user can resize for the wiring tool.
set ROUTE(config_layers) "m5 m4 m3 m2 m1 p1 ndif pdif pwc nwc"

# And these two layers need to be initialized here because
# the wiring tool is not smart enough to figure out what size
# they should start out as.
set ROUTE(pwc,width) \
	[expr $LAYINFO(v0,width) + 2.0 * $LAYINFO(diff,v0,overlap)]
set ROUTE(nwc,width) \
	[expr $LAYINFO(v0,width) + 2.0 * $LAYINFO(diff,v0,overlap)]

# These ROUTE entries are used by the wiring tool to draw
# composite layers.  Composite layers cause the wiring tool to draw
# multiple layers simultaneously.  The name of the composite layer
# (eg: via1) is what the user selected to draw the layer.
# The layers that are actually drawn could
# be anything, possibly totally unrelated to a via1.

# These are the names of the composite layers selected from the palette.
# Got to use the longgggg names, just like m1 is long name of m1.
set ROUTE(composite_layers) \
	"pwc nwc v0 v1 v2 v3 v4"

# ROUTE($layer,layers) contains the actual layers to be drawn when the
# user selects composite layer: $layer.
# Note that the name of the composite layer (eg: pwc) may
# also be included as one of the actual layers in the composite layer.
# Note: if one of the layers is a contact, it should be FIRST!
# The wiring tool checks for overlaps of the other layers by the first layer.


# The contact composite layer could be used over p1, pdif, ndif,
# whatever, so it includes only contact and m1.
set ROUTE(v0,layers) "v0 m1"
set ROUTE(v1,layers) "v1 m1 m2"
set ROUTE(v2,layers) "v2 m2 m3"
set ROUTE(v3,layers) "v3 m3 m4"
set ROUTE(v4,layers) "v4 m4 m5"
set ROUTE(nwc,layers) "v0 m1 nwc"
set ROUTE(pwc,layers) "v0 m1 pwc"

# via routing information
set ROUTE(pdif,up) m1
set ROUTE(ndif,up) m1
set ROUTE(p1,up) m1
set ROUTE(m1,down) "p1 pdif ndif"
set ROUTE(m1,up) m2
set ROUTE(m2,down) m1
set ROUTE(m2,up) m3
set ROUTE(m3,down) m2
set ROUTE(m3,up) m4
set ROUTE(m4,down) m3
set ROUTE(m4,up) m5
set ROUTE(m5,down) m4

set VIA(pdif,m1) pdif,v0
set VIA(m1,pdif) pdif,v0
set VIA(ndif,m1) ndif,v0
set VIA(m1,ndif) ndif,v0
set VIA(m1,p1) v0
set VIA(p1,m1) v0

set VIA(m1,m2) v1
set VIA(m2,m1) v1
set VIA(m2,m3) v2
set VIA(m3,m2) v2
set VIA(m3,m4) v3
set VIA(m4,m3) v3
set VIA(m4,m5) v4
set VIA(m5,m4) v4

# You dont need to edit anything below this point:
# Everything below this point is calculated from LAYINFO.
set VIA(pdif,v0) "v0 $LAYINFO(v0,width)"
set VIA(pdif,v0,down) "pdif \
        [expr $LAYINFO(v0,width) + 2 * $LAYINFO(diff,v0,overlap)]"
set VIA(pdif,v0,up) "m1 \
        [expr $LAYINFO(v0,width) + 2 * $LAYINFO(m1,v0,overlap)]"
set VIA(ndif,v0) "v0 $LAYINFO(v0,width)"
set VIA(ndif,v0,down) "ndif \
        [expr $LAYINFO(v0,width) + 2 * $LAYINFO(diff,v0,overlap)]"
set VIA(ndif,v0,up) "m1 \
        [expr $LAYINFO(v0,width) + 2 * $LAYINFO(m1,v0,overlap)]"
set VIA(v0) "v0 $LAYINFO(v0,width)"
set VIA(v0,down) "p1 \
        [expr $LAYINFO(v0,width) + 2 * $LAYINFO(p1,v0,overlap)]"
set VIA(v0,up) "m1 \
        [expr $LAYINFO(v0,width) + 2 * $LAYINFO(m1,v0,overlap)]"
set VIA(v1) "v1 $LAYINFO(v1,width)"
set VIA(v1,down) "m1 \
        [expr $LAYINFO(v1,width) + 2 * $LAYINFO(m1,v1,overlap)]"
set VIA(v1,up) "m2 \
        [expr $LAYINFO(v1,width) + 2 * $LAYINFO(m2,v1,overlap)]"
set VIA(v2) "v2 $LAYINFO(v2,width)"
set VIA(v2,down) "m2 \
        [expr $LAYINFO(v2,width) + 2 * $LAYINFO(m2,v2,overlap)]"
set VIA(v2,up) "m3 \
        [expr $LAYINFO(v2,width) + 2 * $LAYINFO(m3,v2,overlap)]"
set VIA(v3) "v3 $LAYINFO(v3,width)"
set VIA(v3,down) "m3 \
        [expr $LAYINFO(v3,width) + 2 * $LAYINFO(m3,v3,overlap)]"
set VIA(v3,up) "m4 \
        [expr $LAYINFO(v3,width) + 2 * $LAYINFO(m4,v3,overlap)]"
set VIA(v4) "v4 $LAYINFO(v4,width)"
set VIA(v4,down) "m4 \
        [expr $LAYINFO(v5,width) + 2 * $LAYINFO(m4,v4,overlap)]"
set VIA(v4,up) "m5 \
        [expr $LAYINFO(v4,width) + 2 * $LAYINFO(m5,v4,overlap)]"



# need these to use the correct longname
# No, I dont think we do (pat)
set VIA(m2contact,up) "m2"
set VIA(m2contact,down) "m1"
set VIA(m3contact,up) "m3"
set VIA(m3contact,down) "m2"
set VIA(m4contact,up) "m4"
set VIA(m4contact,down) "m3"
set VIA(m5contact,up) "m5"
set VIA(m5contact,down) "m4"



set DRC_DATA(connect,v0) {ndif pdif nwc pwc p1 m1}
set DRC_DATA(connect,m1) {v0 v1}
set DRC_DATA(connect,m2) {v1 v2}
set DRC_DATA(connect,m3) {v2 v3}
set DRC_DATA(connect,m4) {v3 v4}
set DRC_DATA(connect,m5) v4
set DRC_DATA(connect,ndif) v0
set DRC_DATA(connect,nwc) v0
set DRC_DATA(connect,pdif) v0
set DRC_DATA(connect,p1) v0
set DRC_DATA(connect,pwc) v0
set DRC_DATA(connect,v1) {m1 m2}
set DRC_DATA(connect,v2) {m2 m3}
set DRC_DATA(connect,v3) {m3 m4}
set DRC_DATA(connect,v4) {m4 m5}
set DRC_DATA(device,fet,nfet) {p1 ndif}
set DRC_DATA(device,fet,pfet) {p1 pdif}
set DRC_DATA(enclose,all_poly_dif,v0) 0.14
#set DRC_DATA(enclose,m1,v0) 0.09
#set DRC_DATA(enclose,m1,v1) 0.09
#set DRC_DATA(enclose,m2,v1) 0.09
#set DRC_DATA(enclose,m2,v2) 0.1
#set DRC_DATA(enclose,m3,v2) 0.09
#set DRC_DATA(enclose,m3,v3) 0.09
#set DRC_DATA(enclose,m4,v3) 0.09
#set DRC_DATA(enclose,m4,v4) 0.09
#set DRC_DATA(enclose,m5,v4) 0.09
set DRC_DATA(enclose,ndif,nfet) 0.44
set DRC_DATA(enclose,npls,ndif) 0.26
set DRC_DATA(enclose,npls,nfet) 0.33
set DRC_DATA(enclose,npls,nwc) 0.04
#set DRC_DATA(enclose,nw,nwc) 0.16
#set DRC_DATA(enclose,nw,pdif) 0.6
set DRC_DATA(enclose,pdif,pfet) 0.44
set DRC_DATA(extend,p1,nfet) 0.36
set DRC_DATA(extend,p1,pfet) 0.36
set DRC_DATA(enclose,ppls,pdif) 0.26
set DRC_DATA(enclose,ppls,pfet) 0.33
set DRC_DATA(enclose,ppls,pwc) 0.04
set DRC_DATA(layer_order) {m5 v4 m4 v3 m3 v2 m2 v1 m1 v0 p1 nfet pfet ndif pdif nwc pwc nw ppls npls prb}
#set DRC_DATA(space_to,v0_ndif,nfet) 0.22
#set DRC_DATA(space_to,v0_pdif,pfet) 0.22
#set DRC_DATA(space_to,v0_p1,nfet) 0.28
#set DRC_DATA(space_to,v0_p1,pfet) 0.28
#set DRC_DATA(space_to,npls,pdif) 0.3
#set DRC_DATA(space_to,npls,pfet) 0.33
#set DRC_DATA(space_to,npls,ppls) 0.1
#set DRC_DATA(space_to,npls,pwc) 0.14
#set DRC_DATA(space_to,nw,ndif) 0.6
#set DRC_DATA(space_to,nw,pwc) 0.16
#set DRC_DATA(space_to,poly_not_fet,od) 0.14
#set DRC_DATA(space_to,ppls,ndif) 0.3
#set DRC_DATA(space_to,ppls,nfet) 0.33
#set DRC_DATA(space_to,ppls,nwc) 0.14
#set DRC_DATA(space_to,v1,nfet,pfet) 0.01
#set DRC_DATA(spacing,v0) 0.3
#set DRC_DATA(spacing,m1) 0.32
#set DRC_DATA(spacing,m2) 0.4
#set DRC_DATA(spacing,m3) 0.4
#set DRC_DATA(spacing,m4) 0.4
#set DRC_DATA(spacing,m5) 0.46
set DRC_DATA(spacing,nfet) 0.5
#set DRC_DATA(spacing,npls) 0.44
#set DRC_DATA(spacing,nw) 0.6
#set DRC_DATA(spacing,od) 0.4
set DRC_DATA(spacing,pfet) 0.5
#set DRC_DATA(spacing,p1) 0.36
#set DRC_DATA(spacing,ppls) 0.44
#set DRC_DATA(spacing,v1) 0.35
#set DRC_DATA(spacing,v2) 0.35
#set DRC_DATA(spacing,v3) 0.35
#set DRC_DATA(spacing,v4) 0.35
set DRC_DATA(vias) {v0 v1 v2 v3 v4}
#set DRC_DATA(width,v0) 0.3
#set DRC_DATA(width,m1) 0.32
#set DRC_DATA(width,m2) 0.4
#set DRC_DATA(width,m3) 0.4
#set DRC_DATA(width,m4) 0.4
#set DRC_DATA(width,m5) 0.44
#set DRC_DATA(width,npls) 0.44
#set DRC_DATA(width,nw) 1.2
#set DRC_DATA(width,od) 0.3
set DRC_DATA(width,p1) 0.24
#set DRC_DATA(width,ppls) 0.44
#set DRC_DATA(width,v1) 0.36
#set DRC_DATA(width,v2) 0.36
#set DRC_DATA(width,v3) 0.36
#set DRC_DATA(width,v4) 0.36
# Variables passed directly from technology source file.
 
# These have to 0.24, not 0.22, because of 0.02 grid.
set DRC_DATA(space_to,v0,nfet) 0.24
set DRC_DATA(space_to,v0,pfet) 0.24
# These have to 0.16, not 0.14, because of 0.02 grid.
set DRC_DATA(enclose,ndif,v0) 0.16
set DRC_DATA(enclose,pdif,v0) 0.16

set LAYER_NAME(poly) p1
set LAYER_NAME(nplus) npls
set LAYER_NAME(pplus) ppls
set LAYER_NAME(nwell) nw
set LAYER_NAME(contact) v0

# Added 8/27/99, pat: This is the User Design Grid in the Grid Menu.
set GRID(resolution) 0.01
