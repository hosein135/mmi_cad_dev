set designs [nl_read_verilog associativity.v]

# (assert "$designs == {m}")

set ports [nl_list_ports]

# (assert "$ports == {{a[0]} {a[1]} {a[2]} {z[0]} {z[1]} {z[2]}}")
