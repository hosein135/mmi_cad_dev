set designs [nl_read_verilog -rtl casex.v]

# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/casex.v

# (checkpoint)
diff -w $tmp/casex.v casex.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
