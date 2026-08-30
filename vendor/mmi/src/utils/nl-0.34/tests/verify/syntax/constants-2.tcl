# (checkpoint)
set designs [read_verilog constants-2a.v]
# (dont-find-string "Current design is now")
# (find-string "invalid character in binary constant")
# (assert "[info exists designs] == 0")

# (checkpoint)
set designs [read_verilog constants-2b.v]
# (find-string "Current design is now")
# (dont-find-string "decimal constants wider than 32 bits")
# (assert "[info exists designs] == 1")
