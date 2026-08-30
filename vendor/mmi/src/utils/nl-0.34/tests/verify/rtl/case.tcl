set designs [nl_read_verilog -rtl case.v]

# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/case.v

# (checkpoint)
diff -w $tmp/case.v case.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
