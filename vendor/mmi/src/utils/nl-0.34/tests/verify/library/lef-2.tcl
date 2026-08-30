set lib [create_library mmi15]


# (checkpoint)
read_lef mmi15.lef $lib
# (dont-find-string "Error")


set type1 [object_type $lib]
# (assert "$type1 == {library}")

set libcell [lindex [list_libcells $lib] 0]
set type2 [object_type $libcell]
# (assert "$type2 == {libcell}")

set libpin [lindex [get_libcell_pins $libcell] 0]
set type3 [object_type $libpin]
# (assert "$type3 == {libpin}")


# (checkpoint)
set designs [read_verilog add4.vg]
# (find-string "Current design is now")
# (assert "$designs == {MMI_NOR2B_ MMI_INVC_ MMI_INVA_ MMIG_ADD_CS0HC MMIG_ADD_CSHC MMI_INOR2B_ MMIG_ADD_CBHC MMI_NOR2C_ MMI_OAI21B_ MMIG_ADD_CFLC adder_4CNCNYN add4}")


# (checkpoint)
link
# (find-repeated-string 31 "Could not resolve reference")


# (checkpoint)
link -libraries {mmi15}
# (dont-find-string "resolve")
# (dont-find-string "reference")
# (dont-find-string "missing")
# (dont-find-string "port")


# (checkpoint)
read_def add4.place.def
# (dont-find-string "Error")

set cells [lsort [list_cells -recur -library]]
# (assert "[llength $cells] == 40")

set cell1 [lindex $cells 0]
set cell2 [lindex $cells 2]


set loc1 [get_cell_location $cell1]
# (assert "$loc1 == {24000 10000}")

set loc2 [get_libpin_location mmi15/MMI_AOI21C/in0]
# (assert "$loc2 == {1468 2790}")

set loc3 [get_pin_location $cell1/in0]
# (assert "$loc3 == {25468 13410}")

set loc4 [get_cell_location $cell2]
# (assert "$loc4 == {38000 0}")

set loc5 [get_libpin_location mmi15/MMI_INOR2B/out]
# (assert "$loc5 == {1948 3043}")

set loc6 [get_pin_location $cell2/out]
# (assert "$loc6 == {39948 3043}")

set_cell_orientation $cell2 S
set loc7 [get_pin_location $cell2/out]
# (assert "$loc7 == {39772 3157}")

set_cell_orientation $cell2 E
set loc8 [get_pin_location $cell2/out]
# (assert "$loc8 == {41043 1772}")

set_cell_orientation $cell2 W
set loc9 [get_pin_location $cell2/out]
# (assert "$loc9 == {41157 1948}")

set_cell_orientation $cell2 FN
set loc10 [get_pin_location $cell2/out]
# (assert "$loc10 == {39772 3043}")

set_cell_orientation $cell2 FS
set loc11 [get_pin_location $cell2/out]
# (assert "$loc11 == {39948 3157}")

set_cell_orientation $cell2 FE
set loc12 [get_pin_location $cell2/out]
# (assert "$loc12 == {41157 1772}")

set_cell_orientation $cell2 FW
set loc13 [get_pin_location $cell2/out]
# (assert "$loc13 == {41043 1948}")

