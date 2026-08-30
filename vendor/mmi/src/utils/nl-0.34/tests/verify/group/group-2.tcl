set designs [read_verilog group-2.v]

# (assert "$designs == {m}")

set design [group {u1 u2 u3 u4} foo]

# (assert "$design == {foo}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog -hier $tmp/group-2.out.v

# (checkpoint)
diff -b $tmp/group-2.out.v group-2.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
