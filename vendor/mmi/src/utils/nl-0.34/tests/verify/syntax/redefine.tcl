set designs [nl_read_verilog redefine.v]
# (assert "$designs == {mod2}")

set designs [nl_read_verilog -define {{FOO mod0}} redefine.v]
# (assert "$designs == {mod0}")
