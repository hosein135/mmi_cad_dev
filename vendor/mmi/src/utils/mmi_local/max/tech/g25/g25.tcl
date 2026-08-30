# g25.tcl technology dependent stuff for a generic 0.25um process.
# (supplements and extends g25.tech file)

# set Max viewing grid to something reasonable
set GRID(fine_default_size)   0.1
set GRID(coarse_default_size) 1.0

# palette (old -- uses palette file now)
    pal_group col1 "hmetal" m5 v4 m4 v3 m3 v2
    pal_group col1 "lmetal" m2 v1 m1 v0
    pal_group col1 "active" p1 pfet nfet pdif ndif nwc pwc
    pal_group col1 "other" nw ppls npls n2v res pad

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

# Note: In tsmc, a well_contact is the same as a contact.
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
# contact_width, well_contact_width, poly_contact_overlap, contact_gate_sep.

set LAYINFO(pplus_pdiff_overlap) 0.26	;# PP.E.1
set LAYINFO(pplus_pwc_overlap) 0.04	;# PP.E.2
set LAYINFO(nplus_ndiff_overlap) 0.26	;# NP.E.1
set LAYINFO(nplus_nwc_overlap) 0.04	;# NP.E.2
set LAYINFO(pplus_nplus_sep) 0.1        ;# PP.C.6
set LAYINFO(nwell_nwc_overlap) 0.16	;# OD.C.1
set LAYINFO(nwell_pdiff_overlap) 0.6	;# OD.C.4

set LAYINFO(poly_contact_overlap) 0.16  ;# CO.E.2
set LAYINFO(poly_diff_sep) 0.14		;# PO.C.1
set LAYINFO(poly_gate_overlap) 0.36	;# PO.O.1
set LAYINFO(poly_nwc_sep) 0.34		;# OD.C.6
set LAYINFO(poly_pwc_sep) 0.34		;# OD.C.6
set LAYINFO(poly_min_width) 0.24	;# PO.W.3
set LAYINFO(gate_min_width) 0.24	;# PO.W.1
set LAYINFO(gate_sep) 0.4    		;# PO.S.1
set LAYINFO(poly_sep) 0.36    		;# PO.S.2
set LAYINFO(diff_gate_overlap) 0.44

# This should really be 0.14, but to avoid problems given
# that the max grid is .02, add one grid to make it 0.16.
set LAYINFO(diff_contact_overlap) 0.16	;# CO.E.1
set LAYINFO(diff_diff_sep) 0.40		;# OD.S.1
set LAYINFO(diff_min_width) 0.3  	;# OD.W.2

set LAYINFO(contact_gate_sep) 0.24  	;# CO.C.1
# This should be width=0.3 and sep=0.3, but the max res in this
# technology is 0.02, and when you try to draw a via starting at
# the center, you do: 0.3/2 = .15, which is off-grid.
# Instead, use .28, and .32, and max will fix it.
set LAYINFO(contact_width) 0.28		;# CO.W.1 (should 0.3)
set LAYINFO(contact_sep) 0.32		;# CO.S.1 (should 0.3)
set LAYINFO(well_contact_width) 0.28	;# CO.W.1

# This could really be .01, not 0.1, for sides of contacts.
set LAYINFO(metal1_min_width) 0.32
set LAYINFO(metal2_min_width) 0.4
set LAYINFO(metal3_min_width) 0.4
set LAYINFO(metal4_min_width) 0.4
set LAYINFO(metal5_min_width) 0.44
set LAYINFO(metal1_sep)   0.32
set LAYINFO(metal2_sep)   0.4
set LAYINFO(metal3_sep)   0.4
set LAYINFO(metal4_sep)   0.4
set LAYINFO(metal5_sep)   0.46
set LAYINFO(v1_width) 0.36
set LAYINFO(v1_sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v2_width) 0.36
set LAYINFO(v2_sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v3_width) 0.36
set LAYINFO(v3_sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v4_width) 0.36
set LAYINFO(v4_sep) 0.36	;# (should be 0.35, but round to res)
set LAYINFO(v5_width) 0.36
set LAYINFO(v5_sep) 0.36     
# This could really be .01, not 0.1, for the narrow sides of contacts,
# but we dont have a way to specify that.
set LAYINFO(metal1_contact_overlap) 0.10	;# M1.E.2
set LAYINFO(metal1_v1_overlap) 0.10		;# VIA1.E.2
set LAYINFO(metal2_v1_overlap) 0.10
set LAYINFO(metal2_v2_overlap) 0.10
set LAYINFO(metal3_v2_overlap) 0.10
set LAYINFO(metal3_v3_overlap) 0.10
set LAYINFO(metal4_v3_overlap) 0.10
set LAYINFO(metal4_v4_overlap) 0.10
set LAYINFO(metal5_v4_overlap) 0.10
set LAYINFO(metal_sd) 1
set LAYINFO(metal1_router_pad_size) "0.6 x 0.6" ;# Size of landing pad for router.

################################################################
# These are used only as defaults the fet generator.
set LAYINFO(default_nfet_length) $LAYINFO(gate_min_width)
set LAYINFO(default_nfet_width) 1.0
set LAYINFO(default_pfet_length) $LAYINFO(gate_min_width)
set LAYINFO(default_pfet_width) 2.0


################################################################
# These are the default parameters for the Layout Generator.
set LAYINFO(stdcell:cell_height) 10.0
set LAYINFO_HELP(stdcell:cell_height) {-number -incr 1}
set LAYINFO(stdcell:cell_width_pitch)  1.0   ;# Width is a multiple of this
set LAYINFO(stdcell:power_strap_width) 1.40
set LAYINFO(stdcell:well_contact_pitch) 1.0
set LAYINFO(stdcell:router_pitch) 1.0  ;# Router pitch for poly/metal.
set LAYINFO(stdcell:router_offset_x,y) "0.5,0.5" 
set LAYINFO(stdcell:N/P_boundary) 5.0  ;# Height of cell devoted to N vs P
set LAYINFO_HELP(stdcell:N/P_boundary) {-number -incr 0.5}
# Well Ties.
# nwc_width should be calculated by:
# nwc_width = well_contact_width + 2*diff_contact_overlap = .62
# But it must be centered at the top/bottom of cell, and .62 / 2 = .31,
# which is currently off max grid, so round up to .64
set LAYINFO(stdcell:nwc_width) 0.64
set LAYINFO(stdcell:pwc_width) 0.64

################################################################
# These are old definitions needed only to make the old
# version of make_fet work.  They will be removed.
set LAYINFO(contact_space_to_gate) $LAYINFO(contact_gate_sep)
set LAYINFO(metal_contact_overlap) $LAYINFO(metal1_contact_overlap)
set LAYINFO(fet_poly_spacing) $LAYINFO(gate_sep)

################################################################

# order of routable layers from the top
set ROUTE(order) "metal5 metal4 metal3 metal2 metal1 polysilicon ndiffusion pdiffusion"
# Default route layer, if none found under cursor.  User may change.
set ROUTE(default_layer) metal1

# These are the layers the user can resize for the wiring tool.
set ROUTE(sizable_layers) "metal5 metal4 metal3 metal2 metal1 polysilicon ndiffusion pdiffusion pwc nwc"

# And these two layers need to be initialized here because
# the wiring tool is not smart enough to figure out what size
# they should start out as.
set ROUTE(pwc,width) \
	[expr $LAYINFO(contact_width) + 2.0 * $LAYINFO(diff_contact_overlap)]
set ROUTE(nwc,width) \
	[expr $LAYINFO(contact_width) + 2.0 * $LAYINFO(diff_contact_overlap)]

# These ROUTE entries are used by the wiring tool to draw
# composite layers.  Composite layers cause the wiring tool to draw
# multiple layers simultaneously.  The name of the composite layer
# (eg: via1) is what the user selected to draw the layer.
# The layers that are actually drawn could
# be anything, possibly totally unrelated to a via1.

# These are the names of the composite layers selected from the palette.
# Got to use the longgggg names, just like metal1 is long name of m1.
set ROUTE(composite_layers) \
	"psubstratepcontact nsubstratencontact contact m2contact m3contact m4contact m5contact"

# ROUTE($layer,layers) contains the actual layers to be drawn when the
# user selects composite layer: $layer.
# Note that the name of the composite layer (eg: pwc) may
# also be included as one of the actual layers in the composite layer.
# Note: if one of the layers is a contact, it should be FIRST!
# The wiring tool checks for overlaps of the other layers by the first layer.


# The contact composite layer could be used over poly, pdiff, ndiff,
# whatever, so it includes only contact and metal1.
set ROUTE(contact,layers) "contact metal1"
set ROUTE(m2contact,layers) "v1 metal1 metal2"
set ROUTE(m3contact,layers) "v2 metal2 metal3"
set ROUTE(m4contact,layers) "v3 metal3 metal4"
set ROUTE(m5contact,layers) "v4 metal4 metal5"
set ROUTE(nsubstratencontact,layers) "contact metal1 nwc"
set ROUTE(psubstratepcontact,layers) "contact metal1 pwc"

# via routing information
set ROUTE(pdiffusion,up) metal1
set ROUTE(ndiffusion,up) metal1
set ROUTE(polysilicon,up) metal1
set ROUTE(metal1,down) "polysilicon pdiffusion ndiffusion"
set ROUTE(metal1,up) metal2
set ROUTE(metal2,down) metal1
set ROUTE(metal2,up) metal3
set ROUTE(metal3,down) metal2
set ROUTE(metal3,up) metal4
set ROUTE(metal4,down) metal3
set ROUTE(metal4,up) metal5
set ROUTE(metal5,down) metal4

set VIA(pdiffusion,metal1) pdiffusion_contact
set VIA(metal1,pdiffusion) pdiffusion_contact
set VIA(ndiffusion,metal1) ndiffusion_contact
set VIA(metal1,ndiffusion) ndiffusion_contact
set VIA(metal1,polysilicon) contact
set VIA(polysilicon,metal1) contact

set VIA(metal1,metal2) v1
set VIA(metal2,metal1) v1
set VIA(metal2,metal3) v2
set VIA(metal3,metal2) v2
set VIA(metal3,metal4) v3
set VIA(metal4,metal3) v3
set VIA(metal4,metal5) v4
set VIA(metal5,metal4) v4

# You dont need to edit anything below this point:
# Everything below this point is calculated from LAYINFO.
set VIA(pdiffusion_contact) "contact $LAYINFO(contact_width)"
set VIA(pdiffusion_contact,down) "pdiffusion \
        [expr $LAYINFO(contact_width) + 2 * $LAYINFO(diff_contact_overlap)]"
set VIA(pdiffusion_contact,up) "metal1 \
        [expr $LAYINFO(contact_width) + 2 * $LAYINFO(metal1_contact_overlap)]"
set VIA(ndiffusion_contact) "contact $LAYINFO(contact_width)"
set VIA(ndiffusion_contact,down) "ndiffusion \
        [expr $LAYINFO(contact_width) + 2 * $LAYINFO(diff_contact_overlap)]"
set VIA(ndiffusion_contact,up) "metal1 \
        [expr $LAYINFO(contact_width) + 2 * $LAYINFO(metal1_contact_overlap)]"
set VIA(contact) "contact $LAYINFO(contact_width)"
set VIA(contact,down) "polysilicon \
        [expr $LAYINFO(contact_width) + 2 * $LAYINFO(poly_contact_overlap)]"
set VIA(contact,up) "metal1 \
        [expr $LAYINFO(contact_width) + 2 * $LAYINFO(metal1_contact_overlap)]"
set VIA(v1) "v1 $LAYINFO(v1_width)"
set VIA(v1,down) "metal1 \
        [expr $LAYINFO(v1_width) + 2 * $LAYINFO(metal1_v1_overlap)]"
set VIA(v1,up) "metal2 \
        [expr $LAYINFO(v1_width) + 2 * $LAYINFO(metal2_v1_overlap)]"
set VIA(v2) "v2 $LAYINFO(v2_width)"
set VIA(v2,down) "metal2 \
        [expr $LAYINFO(v2_width) + 2 * $LAYINFO(metal2_v2_overlap)]"
set VIA(v2,up) "metal3 \
        [expr $LAYINFO(v2_width) + 2 * $LAYINFO(metal3_v2_overlap)]"
set VIA(v3) "v3 $LAYINFO(v3_width)"
set VIA(v3,down) "metal3 \
        [expr $LAYINFO(v3_width) + 2 * $LAYINFO(metal3_v3_overlap)]"
set VIA(v3,up) "metal4 \
        [expr $LAYINFO(v3_width) + 2 * $LAYINFO(metal4_v3_overlap)]"
set VIA(v4) "v4 $LAYINFO(v4_width)"
set VIA(v4,down) "metal4 \
        [expr $LAYINFO(v5_width) + 2 * $LAYINFO(metal4_v4_overlap)]"
set VIA(v4,up) "metal5 \
        [expr $LAYINFO(v4_width) + 2 * $LAYINFO(metal5_v4_overlap)]"



# need these to use the correct longname
set VIA(m2contact,up) "metal2"
set VIA(m2contact,down) "metal1"
set VIA(m3contact,up) "metal3"
set VIA(m3contact,down) "metal2"
set VIA(m4contact,up) "metal4"
set VIA(m4contact,down) "metal3"
set VIA(m5contact,up) "metal5"
set VIA(m5contact,down) "metal4"
