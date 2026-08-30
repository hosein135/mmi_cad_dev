set nl_bus_naming_style "%s_%d"

# (checkpoint)
read_verilog bus-1.v
# (find-string "Current design is now")

set nets [lsort [list_nets]]
# (assert "$nets == {bin_0 bin_1 bin_2 bin_3 {gray[3]} gray_0 gray_1 gray_2 gray_3 n19}")
