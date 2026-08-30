create_library mmi15

read_lef mmi15.lef mmi15

read_verilog origin.vg

link -lib mmi15

# (checkpoint)
get_cell_location MMI_XOR2A
# (find-string "does not have any physical")

create_pdesign -nohierarchy

set loc [get_cell_location MMI_XOR2A]
# (assert "$loc == {}")

set_cell_location MMI_XOR2A 10 20

set loca [get_cell_location MMI_XOR2A]
# (assert "$loca == {10 20}")

# (checkpoint)
get_cell_location -origin MMI_XOR2A
# (find-string "attempt to apply cell location transformation to cell with no orientation")

set_cell_orientation MMI_XOR2A N
set loc0a [get_cell_location MMI_XOR2A]
set loc0b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc0a == {10 20}")
# (assert "$loc0b == {10 20}")

set_cell_orientation MMI_XOR2A S
set loc1a [get_cell_location MMI_XOR2A]
set loc1b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc1a == {10 20}")
# (assert "$loc1b == {4350 6220}")

set_cell_orientation MMI_XOR2A E
set loc2a [get_cell_location MMI_XOR2A]
set loc2b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc2a == {10 20}")
# (assert "$loc2b == {10 4360}")

set_cell_orientation MMI_XOR2A W
set loc3a [get_cell_location MMI_XOR2A]
set loc3b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc3a == {10 20}")
# (assert "$loc3b == {6210 20}")

set_cell_orientation MMI_XOR2A FN
set loc4a [get_cell_location MMI_XOR2A]
set loc4b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc4a == {10 20}")
# (assert "$loc4b == {4350 20}")

set_cell_orientation MMI_XOR2A FS
set loc5a [get_cell_location MMI_XOR2A]
set loc5b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc5a == {10 20}")
# (assert "$loc5b == {10 6220}")

set_cell_orientation MMI_XOR2A FE
set loc6a [get_cell_location MMI_XOR2A]
set loc6b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc6a == {10 20}")
# (assert "$loc6b == {6210 4360}")

set_cell_orientation MMI_XOR2A FW
set loc7a [get_cell_location MMI_XOR2A]
set loc7b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc7a == {10 20}")
# (assert "$loc7b == {10 20}")

set_cell_location -origin MMI_XOR2A 0 0

set_cell_orientation MMI_XOR2A N
set loc0a [get_cell_location MMI_XOR2A]
set loc0b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc0a == {0 0}")
# (assert "$loc0b == {0 0}")

set_cell_orientation MMI_XOR2A S
set loc1a [get_cell_location MMI_XOR2A]
set loc1b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc1a == {-4340 -6200}")
# (assert "$loc1b == {0 0}")

set_cell_orientation MMI_XOR2A E
set loc2a [get_cell_location MMI_XOR2A]
set loc2b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc2a == {0 -4340}")
# (assert "$loc2b == {0 0}")

set_cell_orientation MMI_XOR2A W
set loc3a [get_cell_location MMI_XOR2A]
set loc3b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc3a == {-6200 0}")
# (assert "$loc3b == {0 0}")

set_cell_orientation MMI_XOR2A FN
set loc4a [get_cell_location MMI_XOR2A]
set loc4b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc4a == {-4340 0}")
# (assert "$loc4b == {0 0}")

set_cell_orientation MMI_XOR2A FS
set loc5a [get_cell_location MMI_XOR2A]
set loc5b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc5a == {0 -6200}")
# (assert "$loc5b == {0 0}")

set_cell_orientation MMI_XOR2A FE
set loc6a [get_cell_location MMI_XOR2A]
set loc6b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc6a == {-6200 -4340}")
# (assert "$loc6b == {0 0}")

set_cell_orientation MMI_XOR2A FW
set loc7a [get_cell_location MMI_XOR2A]
set loc7b [get_cell_location -origin MMI_XOR2A]
# (assert "$loc7a == {0 0}")
# (assert "$loc7b == {0 0}")
