# (checkpoint)
read_verilog tri.v
# (find-string "Current design is now")

set nets [lsort [list_nets]]
# (assert "$nets == {a b q z}")

set cells [lsort [list_cells]]
# (assert "$cells == {u1 u2}")

set ports [lsort [list_ports]]
# (assert "$ports == {a b z}")

