set designs [nl_read_verilog decl-assign.v]

# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/decl-assign.v

# (checkpoint)
diff -b $tmp/decl-assign.v decl-assign.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
