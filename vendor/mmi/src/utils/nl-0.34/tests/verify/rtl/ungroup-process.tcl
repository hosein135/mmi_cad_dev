set designs [nl_read_verilog -rtl ungroup-process.v]
# (assert "$designs == {sub m}")

nl_link

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

nl_write_verilog -hier $tmp/ungroup-process.v1

# (checkpoint)
diff -w $tmp/ungroup-process.v1 ungroup-process.vout1
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")

nl_ungroup sub

nl_write_verilog -hier $tmp/ungroup-process.v2

# (checkpoint)
diff -w $tmp/ungroup-process.v2 ungroup-process.vout2
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")

nl_remove_assigns

nl_write_verilog -hier $tmp/ungroup-process.v3

# (checkpoint)
diff -w $tmp/ungroup-process.v3 ungroup-process.vout3
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
