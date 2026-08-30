# (checkpoint)
read_verilog group-1.v
# (find-string "Current design is now")

link

group [find_cells "int*"] sub

set cells [find_cells "int*"]
# (assert "$cells == {}")

set current_design sub

set cells [lsort [list_cells]]
# (assert "$cells == {int1 int10 int11 int12 int13 int14 int15 int16 int17 int18 int19 int2 int20 int21a int21b int21c int3 int4 int5 int6 int7 int8 int9}")

set nets [lsort [list_nets]]
# (assert "$nets == {a in1 in2 in3 in4 in5 in7 io8 io9 n21a n21b out13 out14 out15 out16 out17 out18 out19 out20 out6 unk10 unk11 unk12 z}")

set inputs [lsort [list_ports -inputs]]
# (assert "$inputs == {a in1 in2 in3 in4 in5 in7}")

set outputs [lsort [list_ports -outputs]]
# (assert "$outputs == {out13 out14 out15 out16 out17 out18 out19 out20 out6 z}")

set inouts [lsort [list_ports -inouts]]
# (assert "$inouts == {io8 io9 unk10 unk11 unk12}")

# (checkpoint)
write_verilog -- -
# (find-string "inout /* unknown */ unk10, unk11, unk12;")
