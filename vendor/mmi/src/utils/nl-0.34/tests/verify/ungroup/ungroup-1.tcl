set designs [read_verilog ungroup-1.v]

# (assert "$designs == {subsub sub m}")

link -s

# (checkpoint)
ungroup -recursive -all
# (find-string "Ungrouping cell \"sub\"")
# (find-string "Ungrouping cell \"sub/ss\"")
# (find-string "Ungrouping cell \"sub2\"")

set cells [lsort [list_cells]]

# (assert "$cells == {*assignment_2* sub/ss/*assignment_2* sub/ss/*assignment_4* sub/ss/u1 sub/ss/u2 sub/ss/u3 sub2/*assignment_2* sub2/*assignment_4* sub2/u1 sub2/u2 sub2/u3}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/ungroup-1.ungroup.vout

# (checkpoint)
diff -b $tmp/ungroup-1.ungroup.vout ungroup-1.ungroup.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")

remove_assign 

set cells [lsort [list_cells]]

# (assert "$cells == {sub/ss/*assignment_2* sub/ss/u1 sub/ss/u2 sub/ss/u3 sub2/*assignment_2* sub2/u1 sub2/u2 sub2/u3}")

write_verilog $tmp/ungroup-1.noassign.vout

# (checkpoint)
diff -b $tmp/ungroup-1.noassign.vout ungroup-1.noassign.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
