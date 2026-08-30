set designs [nl_read_verilog -rtl integer.v]

# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/integer.v

# (checkpoint)
diff -w $tmp/integer.v integer.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
