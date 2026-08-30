set designs [nl_read_verilog -rtl decl-assign-rtl.v]

# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/decl-assign-rtl.v

# (checkpoint)
diff -b $tmp/decl-assign-rtl.v decl-assign-rtl.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
