# (checkpoint)
read_verilog test3.v
# (find-string "Current design is now")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/test3.vout

# (checkpoint)
diff -b $tmp/test3.vout test3.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
