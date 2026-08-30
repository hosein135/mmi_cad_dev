# (checkpoint)
set designs [read_verilog error-1a.v]
# (dont-find-string "Current design is now")
# (find-string "Syntax error")

# (checkpoint)
set designs
# (find-string "can't read \"designs\": no such variable")

# (checkpoint)
set designs [read_verilog error-1b.v]
# (find-string "Current design is now")
# (assert "$designs == {m}")
unset designs

set designs [list_designs]
# (assert "$designs == {m}")
unset designs

# (checkpoint)
set designs [read_verilog error-1c.v]
# (find-string "Syntax error")
# (dont-find-string "Current design is now")

# (checkpoint)
set designs
# (find-string "can't read \"designs\": no such variable")

set designs [list_designs]
# (assert "$designs == {m}")
unset designs

set designs [list_designs]
# (assert "$designs == {m}")
unset designs

# (checkpoint)
write_verilog -- - m
# (find-string "MMI_INVB")
