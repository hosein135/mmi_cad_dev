# (checkpoint)
read_verilog escape-test-2.v
# (find-string "Current design is now")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/escape-test-2.vout

# (checkpoint)
diff -b $tmp/escape-test-2.vout escape-test-2.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
