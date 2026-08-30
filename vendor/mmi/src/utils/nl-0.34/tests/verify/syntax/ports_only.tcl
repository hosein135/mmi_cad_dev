set designs [read_verilog -ports_only ports_only.v]

# (assert "$designs == {MMI_AND2B MMI_AND2C MMI_AND3B}")

set and2b_cells [list_cells MMI_AND2B]
set and2b_nets [list_nets MMI_AND2B]
set and2b_refs [list_references MMI_AND2B]
set and2b_ports [list_ports MMI_AND2B]
set and2b_dirs [lmapcar get_port_direction [list_ports MMI_AND2B]]

# (assert "$and2b_cells == {}")
# (assert "$and2b_refs == {}")
# (assert "$and2b_nets == {in0 in1 out}")
# (assert "$and2b_ports == {in0 in1 out}")
# (assert "$and2b_dirs == {in in out}")

set and2c_cells [list_cells MMI_AND2C]
set and2c_nets [list_nets MMI_AND2C]
set and2c_refs [list_references MMI_AND2C]
set and2c_ports [list_ports MMI_AND2C]
set and2c_dirs [lmapcar get_port_direction [list_ports MMI_AND2C]]

# (assert "$and2c_cells == {}")
# (assert "$and2c_refs == {}")
# (assert "$and2c_nets == {in0 in1 out}")
# (assert "$and2c_ports == {in0 in1 out}")
# (assert "$and2c_dirs == {in in out}")

set and3b_cells [list_cells MMI_AND3B]
set and3b_nets [list_nets MMI_AND3B]
set and3b_refs [list_references MMI_AND3B]
set and3b_ports [list_ports MMI_AND3B]
set and3b_dirs [lmapcar get_port_direction [list_ports MMI_AND3B]]

# (assert "$and3b_cells == {}")
# (assert "$and3b_refs == {}")
# (assert "$and3b_nets == {in0 in1 in2 out}")
# (assert "$and3b_ports == {in0 in1 in2 out}")
# (assert "$and3b_dirs == {in in in out}")
