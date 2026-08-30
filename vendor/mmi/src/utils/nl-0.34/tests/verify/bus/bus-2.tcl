set bus_naming_style %s_%d

# (checkpoint)
read_verilog bus-2.v
# (find-string "Current design is now")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_verilog $tmp/bus-2.vout

# (checkpoint)
diff -b $tmp/bus-2.vout bus-2.vout
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")

set pins [lsort [get_net_pins a_3]]
# (assert "$pins == {a_3 zz1/p_3}")

set pins [lsort [get_net_pins a_0]]
# (assert "$pins == {a_0 zz1/p_0}")

set pins [lsort [get_net_pins b_3]]
# (assert "$pins == {b_3 zz2/p_3}")

set pins [lsort [get_net_pins b_0]]
# (assert "$pins == {b_0 zz2/p_0}")

set pins [lsort [get_net_pins y_3]]
# (assert "$pins == {y_3 zz1/q_0}")

set pins [lsort [get_net_pins y_0]]
# (assert "$pins == {y_0 zz1/q_3}")

set pins [lsort [get_net_pins z_3]]
# (assert "$pins == {z_3 zz2/q_3}")

set pins [lsort [get_net_pins z_0]]
# (assert "$pins == {z_0 zz2/q_0}")
