set designs [nl_read_verilog -rtl out-test-1.v]

# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/out-test-1.v

# (checkpoint)
diff -w $tmp/out-test-1.v out-test-1.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
