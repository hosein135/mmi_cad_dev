# (checkpoint)
read_verilog assign-1.v
# (find-string "Current design is now")

# (assert "[llength [find_cells {\\*assignment_*\\*}]] == 8")
# (assert "[llength [list_cells -noassign]] == 0")

# (checkpoint)
write_verilog -- -
# (find-string "assign z[0] = o[3];")
# (find-string "assign z[1] = o[2];")
# (find-string "assign z[2] = o[1];")
# (find-string "assign z[3] = o[0];")
# (find-string "assign o[3] = a;")
# (find-string "assign o[2] = b;")
# (find-string "assign o[1] = a;")
# (find-string "assign o[0] = b;")
