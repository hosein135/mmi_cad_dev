set designs [nl_read_verilog -define {{FOO mod1}} undef.v]
# (assert "$designs == {mod2}")

set designs [nl_read_verilog -define {{FOO mod1}} undef.v]
# (assert "$designs == {mod2}")
