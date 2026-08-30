# (checkpoint)
set designs [read_verilog constants-1.v]
# (find-string "Current design is now")
# (assert "$designs == {m}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/constants-1.vout

# (checkpoint)
diff -b $tmp/constants-1.vout constants-1.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
