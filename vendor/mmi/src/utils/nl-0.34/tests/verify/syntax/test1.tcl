# (checkpoint)
read_verilog test1.v
# (find-string "Current design is now")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/test1.vout

# (checkpoint)
diff -b $tmp/test1.vout test1.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
