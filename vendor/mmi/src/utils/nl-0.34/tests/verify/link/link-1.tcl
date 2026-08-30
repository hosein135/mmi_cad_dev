# (checkpoint)
set designs [read_verilog link-1.v]
# (find-string "Current design is now")
# (assert "$designs == {m n o}")

link

set cells [find_cells "*/*/*assignment*"]
# (assert "[llength $cells] == 8")

set nets [lsort [list_nets -hier -noassign]]
# (assert "$nets == {{a[0]} {a[1]} {a[2]} {a[3]} {b[0]} {b[1]} {b[2]} {b[3]}}")

ungroup -all -recur
remove_design n
remove_design m

set cells [find_cells "*assignment*"]
# (assert "[llength $cells] == 8")

set nets [lsort [list_nets -noassign]]
# (assert "$nets == {{a[0]} {a[1]} {a[2]} {a[3]} {b[0]} {b[1]} {b[2]} {b[3]}}")
