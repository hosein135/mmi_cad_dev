# (checkpoint)
read_verilog assign-3.v
# (find-string "Current design is now")

link

set nets [lsort [list_nets]]
# (assert "$nets == {a b c s t u v w y z}")

set nets [lsort [list_nets -hier]]
# (assert "$nets == {a b c s sub_1/o sub_1/x sub_1/y sub_2/o sub_2/x sub_2/y t u v w y z}")

set nets [lsort [list_nets -hier -noassign]]
# (assert "$nets == {a b c sub_1/o sub_2/o t y z}")

set cells [lsort [list_cells]]
# (assert "$cells == {*assignment_2* *assignment_4* U1 sub_1 sub_2}")

set cells [lsort [list_cells -recursive]]
# (assert "$cells == {*assignment_2* *assignment_4* U1 sub_1 sub_1/*assignment_2* sub_1/*assignment_4* sub_1/*assignment_6* sub_1/U2 sub_1/U3 sub_2 sub_2/*assignment_2* sub_2/*assignment_4* sub_2/*assignment_6* sub_2/U2 sub_2/U3}")

set cells [lsort [list_cells -recursive -noassign]]
# (assert "$cells == {U1 sub_1 sub_1/U2 sub_1/U3 sub_2 sub_2/U2 sub_2/U3}")

set cells [lsort [list_cells -recursive -noassign -unlinked]]
# (assert "$cells == {U1 sub_1/U2 sub_1/U3 sub_2/U2 sub_2/U3}")

set pins [lsort [get_net_pins a]]
# (assert "$pins == {a sub_2/q sub_2/s}")

set pins [lsort [get_net_pins -hier a]]
# (assert "$pins == {a sub_2/*assignment_6*/in sub_2/U2/in1}")

set pins [lsort [get_net_pins -hier -noassign a]]
# (assert "$pins == {a sub_1/U2/in0 sub_2/U2/in1}")

set pins [lsort [get_net_pins -hier -noassign b]]
# (assert "$pins == {b sub_1/U2/in1}")

set pins [lsort [get_net_pins -hier -noassign c]]
# (assert "$pins == {U1/in0 c sub_2/U2/in0}")

set pins [lsort [get_net_pins -hier -noassign y]]
# (assert "$pins == {sub_2/U3/out y}")

set pins [lsort [get_net_pins -hier -noassign z]]
# (assert "$pins == {U1/out z}")

set pins [lsort [get_net_pins -hier -noassign t]]
# (assert "$pins == {U1/in1 sub_1/U3/out}")

set pins [lsort [get_net_pins -hier -noassign sub_1/o]]
# (assert "$pins == {sub_1/U2/out sub_1/U3/in}")

set pins [lsort [get_net_pins -hier -noassign sub_2/o]]
# (assert "$pins == {sub_2/U2/out sub_2/U3/in}")

set pins [lsort [get_net_pins -hier -noassign sub_1/x]]
# (assert "$pins == {a sub_1/U2/in0 sub_2/U2/in1}")

set pins [lsort [get_net_pins -hier -noassign sub_2/x]]
# (assert "$pins == {U1/in0 c sub_2/U2/in0}")
