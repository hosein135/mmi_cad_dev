
# g18.tcl technology dependent stuff for generic 0.18um technology
# (supplements and extends g18.tech file)

# set Max viewing grid to something reasonable
set GRID(fine_default_size)   0.1
set GRID(coarse_default_size) 1.0

# palette 
pal_group col1 "hmetal" m5 v4 m4 v3 m3 v2
pal_group col1 "lmetal" m2 v1 m1 v0
pal_group col1 "active" p1 pfet nfet pdif ndif nwc pwc
pal_group col1 "other" nw ppls npls n2v fdrc
# This one crashes max:
#pal_group col1 "other" nw ppls npls n2v res pad

# pointer to foreign drc rules file
set DRC_RULES_FILE "/home/randy/verify/dractrans/tsmc33icv.drc"

# cif ostyle to use for printing with plotps
set PRINT(plotps,ostyle) "gen"

### info for generators
# LAYINFO contains process parameters, used by the wiring tool,
# the stdcell generator and fet generator.

# This is the underlying max grid.  It is used everywhere, but should go away.
set LAYINFO(grid) 0.01

################################################################
# Process/foundry dependent parameters.
# Designated by LAYINFO name with no colon.
# The user should not really change these.

set LAYINFO(pplus_pdiff_overlap) 0.32	;# PP.E.1
set LAYINFO(pplus_pwc_overlap) 0.08	;# PP.E.2
set LAYINFO(nplus_ndiff_overlap) 0.32	;# NP.E.1
set LAYINFO(nplus_nwc_overlap) 0.08	;# NP.E.2
set LAYINFO(pplus_nplus_sep) 0.1	;# PP.C.6 (non-shrink rule, page 7)
set LAYINFO(nwell_nwc_overlap) 0.26	;# OD.C.1
set LAYINFO(nwell_pdiff_overlap) 0.46	;# OD.C.4

set LAYINFO(poly_contact_overlap) 0.1	;# CO.E.2
set LAYINFO(poly_diff_sep) 0.12		;# PO.C.1
set LAYINFO(poly_gate_overlap) 0.22	;# PO.O.1
set LAYINFO(poly_nwc_sep) 0.32		;# OD.C.6 (non-shrink rule, page 7)
set LAYINFO(poly_pwc_sep) 0.32		;# OD.C.6
set LAYINFO(poly_min_width) 0.18	;# PO.W.3
set LAYINFO(gate_min_width) 0.18	;# PO.W.1
set LAYINFO(gate_sep) 0.28		;# PO.S.1
set LAYINFO(poly_sep) 0.26    		;# PO.S.2
set LAYINFO(diff_gate_overlap) 0.30

set LAYINFO(diff_contact_overlap) 0.1	;# CO.E.1
set LAYINFO_HELP(diff_diff_sep) { -help "diff-diff spacing for same type diff"}
set LAYINFO(diff_diff_sep) 0.28 	;# OD.S.1
set LAYINFO(diff_min_width) 0.26	;# OD.W.2
# Note: max will expand/shrink the contact width to the actual size needed.
set LAYINFO(contact_gate_sep) 0.16	;# CO.C.1
set LAYINFO(contact_width) 0.24		;# CO.W.1
set LAYINFO(contact_sep) 0.25		;# CO.S.1
set LAYINFO(well_contact_width) 0.24	;# CO.W.1

set LAYINFO(metal1_min_width) 0.28
set LAYINFO(metal2_min_width) 0.28
set LAYINFO(metal3_min_width) 0.28
set LAYINFO(metal4_min_width) 0.28
set LAYINFO(metal5_min_width) 0.28
set LAYINFO(metal6_min_width) 0.56
set LAYINFO(metal1_sep) 0.28
set LAYINFO(metal2_sep) 0.28
set LAYINFO(metal3_sep) 0.28
set LAYINFO(metal4_sep) 0.28
set LAYINFO(metal5_sep) 0.28
set LAYINFO(metal6_sep) 0.56
set LAYINFO(v1_width) 0.28
set LAYINFO(v1_sep) 0.26
set LAYINFO(v2_width) 0.28
set LAYINFO(v2_sep) 0.26
set LAYINFO(v3_width) 0.28
set LAYINFO(v3_sep) 0.26
set LAYINFO(v4_width) 0.28
set LAYINFO(v4_sep) 0.26
set LAYINFO(v5_width) 0.36
set LAYINFO(v5_sep) 0.35
set LAYINFO(metal1_contact_overlap) 0.08 ;# M1.E.2
set LAYINFO(metal1_v1_overlap) 0.08
set LAYINFO(metal2_v1_overlap) 0.08
set LAYINFO(metal2_v2_overlap) 0.08
set LAYINFO(metal3_v2_overlap) 0.08
set LAYINFO(metal3_v3_overlap) 0.08
set LAYINFO(metal4_v3_overlap) 0.08
set LAYINFO(metal4_v4_overlap) 0.08
set LAYINFO(metal5_v4_overlap) 0.08
set LAYINFO(metal5_v5_overlap) 0.08
set LAYINFO(metal6_v5_overlap) 0.12
set LAYINFO(metal_sd) 1
# The router_pad_size must be on grid after division by 2.
set LAYINFO(metal1_router_pad_size) "0.46 x 0.46"

################################################################
# These are used only as defaults by Lees fet generator.
set LAYINFO(default_nfet_length) 0.18
set LAYINFO(default_nfet_width) 1.0
set LAYINFO(default_pfet_length) 0.18
set LAYINFO(default_pfet_width) 2.0

################################################################
# These are the default parameters for the Layout Generator.
# These are the new LAYINFO definitions that control the process.
set LAYINFO(stdcell:router_pitch) 0.74  ;# Router pitch for poly/metal.
#set LAYINFO(stdcell:router_offset_x,y) "0,[expr 0.74/2]" 
set LAYINFO(stdcell:router_offset_x,y) "[expr 0.74/2],[expr 0.74/2]" 
set LAYINFO(stdcell:cell_height) [expr 10*0.74]
set LAYINFO_HELP(stdcell:cell_height) {-number -incr 0.74}
set LAYINFO(stdcell:cell_width_pitch)  0.74   ;# Width is a multiple of this
set LAYINFO(stdcell:power_strap_width) 1.00
set LAYINFO(stdcell:well_contact_pitch) 0.74
set LAYINFO(stdcell:N/P_boundary) [expr 4.5*0.74]
set LAYINFO_HELP(stdcell:N/P_boundary) "-number -incr [expr 0.74/2]"
# Well Ties.
# nwc_width may be calculated by:
# nwc_width = well_contact_width + 2*diff_contact_overlap,
# but it might also be limited by some other process rule.
set LAYINFO(stdcell:nwc_width) 0.44
set LAYINFO(stdcell:pwc_width) 0.44

################################################################
# These are old definitions needed only to make the old
# version of make_fet work.  They will be removed.
set LAYINFO(contact_space_to_gate) $LAYINFO(contact_gate_sep)
set LAYINFO(metal_contact_overlap) $LAYINFO(metal1_contact_overlap)
set LAYINFO(fet_poly_spacing) $LAYINFO(gate_sep)

################################################################

# order of routable layers from the top

set ROUTE(order) "metal4 metal3 metal2 metal1 polysilicon ndiffusion pdiffusion"
set ROUTE(default_layer) metal1

# default conductor widths - init to use minimum width wires

set ROUTE(pdiffusion) $LAYINFO(diff_min_width)
set ROUTE(ndiffusion) $LAYINFO(diff_min_width)
set ROUTE(polysilicon) $LAYINFO(poly_min_width)
set ROUTE(metal1) $LAYINFO(metal1_min_width)
set ROUTE(metal2) $LAYINFO(metal2_min_width)
set ROUTE(metal3) $LAYINFO(metal3_min_width)
set ROUTE(metal4) $LAYINFO(metal4_min_width)
set ROUTE(metal5) $LAYINFO(metal5_min_width)
set ROUTE(metal6) $LAYINFO(metal6_min_width)

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
set VIA(metal5,metal6) v5
set VIA(metal6,metal5) v5

# via cut size, size above and size below
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
        [expr $LAYINFO(v4_width) + 2 * $LAYINFO(metal4_v4_overlap)]"
set VIA(v4,up) "metal5 \
        [expr $LAYINFO(v4_width) + 2 * $LAYINFO(metal5_v4_overlap)]"

# need these to use the correct longname
set VIA(m2contact,up) "metal2"
set VIA(m2contact,down) "metal1"
set VIA(m3contact,up) "metal3"
set VIA(m3contact,down) "metal2"

# for power routing (larger metal => larger overlap in some technologies)
# Hey Leeee!  What are these supposed to do?  (pat)
set VIA(v1,overlap) 1.0
set VIA(v2,overlap) 1.0
set VIA(v3,overlap) 1.0
set VIA(v4,overlap) 1.0
