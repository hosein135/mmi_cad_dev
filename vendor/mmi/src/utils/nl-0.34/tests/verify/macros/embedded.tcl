set designs [nl_read_verilog embedded.v]

# (assert "$designs == {m}")

set ports [nl_list_ports]

# (assert "$ports == {{a[0]} {a[1]} {a[2]} {a[3]} {a[4]} {a[5]} {a[6]} {a[7]} {a[8]} {a[9]} {a[10]} {z[0]} {z[1]} {z[2]} {z[3]} {z[4]} {z[5]} {z[6]} {z[7]} {z[8]} {z[9]} {z[10]}}")
