# (checkpoint)
set designs [read_verilog no-ports.v]
# (find-string "Current design is now")
# (assert "$designs == {m1 m2 m3 m4}")

set ports {dummy}
set ports [list_ports m1]
# (assert "$ports == {}")

set ports {dummy}
set ports [list_ports m2]
# (assert "$ports == {}")

set ports {dummy}
set ports [list_ports m3]
# (assert "$ports == {}")

set ports {dummy}
set ports [list_ports m4]
# (assert "$ports == {}")
