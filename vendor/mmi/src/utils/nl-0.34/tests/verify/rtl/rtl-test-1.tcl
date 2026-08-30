set designs [nl_read_verilog -rtl rtl-test-1.v]
# (assert "$designs == {m}")

apply_rewrites

set cells [nl_cells_with_attribute foo]
# (assert "$cells == {*process_1*}")

nl_group $cells sub

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

nl_write_verilog -hier $tmp/rtl-test-1.v

# (checkpoint)
diff -w $tmp/rtl-test-1.v rtl-test-1.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
