read_verilog orientations.v

create_library mmi15

read_lef mmi15.lef mmi15

link -lib mmi15

set cells [lmapcar find_cells {u0 u1 u2 u3 u4 u5 u6 u7}]

proc get_cell_orientation_max {cell} {get_cell_orientation -max $cell}

create_pdesign

set_cell_orientation u0 N
set_cell_orientation u1 S
set_cell_orientation u2 E
set_cell_orientation u3 W
set_cell_orientation u4 FN
set_cell_orientation u5 FS
set_cell_orientation u6 FE
set_cell_orientation u7 FW

set def_ori1 [lmapcar get_cell_orientation $cells]
set max_ori1 [lmapcar get_cell_orientation_max $cells]
set sue_ori1 [lmapcar [lambda {cell} {get_cell_orientation -sue $cell}] $cells]

# (assert "$def_ori1 == {N S E W FN FS FE FW}")
# (assert "$max_ori1 == {{} r180 r90 r270 fx fy fy_r90 fx_r90}")
# (assert "$sue_ori1 == {R0 RXY R90 R270 RX RY R90Y R90X}")

set_cell_orientation u0 fx
set_cell_orientation u1 fy
set_cell_orientation u2 fy_r90
set_cell_orientation u3 fx_r90
set_cell_orientation u4 ""
set_cell_orientation u5 r180
set_cell_orientation u6 r90
set_cell_orientation u7 r270

set def_ori2 [lmapcar get_cell_orientation $cells]
set max_ori2 [lmapcar get_cell_orientation_max $cells]
set sue_ori2 [lmapcar [lambda {cell} {get_cell_orientation -sue $cell}] $cells]

# (assert "$def_ori2 == {FN FS FE FW N S E W}")
# (assert "$max_ori2 == {fx fy fy_r90 fx_r90 {} r180 r90 r270}")
# (assert "$sue_ori2 == {RX RY R90Y R90X R0 RXY R90 R270}")

set_cell_orientation u0 R90X
set_cell_orientation u1 R90Y
set_cell_orientation u2 RY
set_cell_orientation u3 RX
set_cell_orientation u4 R270
set_cell_orientation u5 R90
set_cell_orientation u6 RXY
set_cell_orientation u7 R0

set def_ori3 [lmapcar get_cell_orientation $cells]
set max_ori3 [lmapcar get_cell_orientation_max $cells]
set sue_ori3 [lmapcar [lambda {cell} {get_cell_orientation -sue $cell}] $cells]

# (assert "$def_ori3 == {FW FE FS FN W E S N}")
# (assert "$max_ori3 == {fx_r90 fy_r90 fy fx r270 r90 r180 {}}")x
# (assert "$sue_ori3 == {R90X R90Y RY RX R270 R90 RXY R0}")
