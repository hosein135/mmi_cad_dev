set designs [nl_read_verilog -rtl ungroup-2.v]

# (assert "$designs == {sub1 sub2 m}")

link -s

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

nl_write_verilog -hier $tmp/ungroup-2.v1

# (checkpoint)
diff -w $tmp/ungroup-2.v1 ungroup-2.vout1
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")

nl_ungroup sub1
nl_ungroup sub2

nl_write_verilog -hier $tmp/ungroup-2.v2

# (checkpoint)
diff -w $tmp/ungroup-2.v2 ungroup-2.vout2
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
