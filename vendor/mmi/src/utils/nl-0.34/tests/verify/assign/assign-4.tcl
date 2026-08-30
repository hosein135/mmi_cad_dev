# (checkpoint)
read_verilog assign-4.v
# (find-string "Current design is now")

link

set nets [lsort [list_nets]]
# (assert "$nets == {a c x y z}")

set nets [lsort [list_nets -hier]]
# (assert "$nets == {a c s/1'b0 s/1'b1 s/n t/1'b0 t/1'b1 x y z}")

set nets [lsort [list_nets -hier -noempty]]
# (assert "$nets == {a s/1'b1 s/n t/1'b1 x y z}")

set nets [lsort [list_nets -hier -noassign]]
# (assert "$nets == {a c s/1'b0 s/n t/1'b0 x y z}")

set nets [lsort [list_nets -hier -noconst]]
# (assert "$nets == {a c s/n x y z}")

set nets [lsort [list_nets -hier -noassign -noconst]]
# (assert "$nets == {a c x z}")

set nets [lsort [list_nets -hier -noempty -noconst]]
# (assert "$nets == {a s/n x y z}")

set nets [lsort [list_nets -hier -noassign -noempty]]
# (assert "$nets == {a s/n x y z}")

set nets [lsort [list_nets -hier -noassign -noempty -noconst]]
# (assert "$nets == {a x z}")
