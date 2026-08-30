# (checkpoint)
read_verilog error-2.v
# (find-string "Current design is now")

# (checkpoint)
set pins [get_net_pins [list]]
# (find-string "could not find a net")
# (assert "[info exists pins] == 0")

# (checkpoint)
set pins [get_net_pins [list b]]
# (find-string "could not find a net")
# (assert "[info exists pins] == 0")

# (checkpoint)
set pins [get_net_pins [list b c]]
# (find-string "incorrect argument type")
# (assert "[info exists pins] == 0")
