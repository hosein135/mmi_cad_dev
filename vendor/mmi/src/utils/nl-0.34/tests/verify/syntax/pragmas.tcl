set designs [read_verilog -rtl pragmas-bad.v]

# (assert "[info exists designs] == 0")

set designs [read_verilog -rtl pragmas-good.v]

# (assert "$designs == {m}")

# (checkpoint)
write_verilog -- -
# (find-string "/* synopsys infer_mux parallel_case */")
