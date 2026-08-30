set designs [nl_read_verilog -define {{MOD m1} {PORT z1}} define-test.v]
# (assert "$designs == {m1}")
set ports [nl_list_ports]
# (assert "$ports == {a z1}")

set designs [nl_read_verilog {define-test-a.v define-test.v}]
# (assert "$designs == {m2}")
set ports [nl_list_ports]
# (assert "$ports == {a z2}")

set designs [nl_read_verilog -define {{MOD m3}} {define-test-a.v define-test.v}]
# (assert "$designs == {m3}")
set ports [nl_list_ports]
# (assert "$ports == {a z2}")
