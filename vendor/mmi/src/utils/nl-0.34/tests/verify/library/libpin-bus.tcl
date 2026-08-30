set library [create_library lib]
# (assert "[object_type $library] == {library}")

set libcell [create_libcell foo lib]
# (assert "[object_type $libcell] == {libcell}")

set in_bus [create_libpin_bus in in 1 4 lib/foo]
# (assert "[object_type $in_bus] == {bus}")

set out_bus [create_libpin_bus out out 5 2 $libcell]
# (assert "[object_type $out_bus] == {bus}")

set designs [read_verilog libpin-bus.v]
# (assert "$designs == {m}")

set pins1 [get_cell_pins u1]
# (assert "$pins1 == {{u1/in[0]} {u1/in[1]} {u1/in[2]} {u1/in[3]} {u1/out[0]} {u1/out[1]} {u1/out[2]} {u1/out[3]}}")

set in_pins1 [get_cell_pins -inputs u1]
# (assert "$in_pins1 == {}")

set out_pins1 [get_cell_pins -outputs u1]
# (assert "$out_pins1 == {}")

# (checkpoint)
link -lib lib
# (dont-find-string "Could not resolve")

set down_libcell1 [get_reference_link [get_cell_reference u1]]
# (assert "[object_type $down_libcell1] == {libcell}")

set pins2 [get_cell_pins u1]
# (assert "$pins2 == {{u1/in[4]} {u1/in[3]} {u1/in[2]} {u1/in[1]} {u1/out[2]} {u1/out[3]} {u1/out[4]} {u1/out[5]}}")

set in_pins2 [get_cell_pins -inputs u1]
# (assert "$in_pins2 == {{u1/in[4]} {u1/in[3]} {u1/in[2]} {u1/in[1]}}")

set out_pins2 [get_cell_pins -outputs u1]
# (assert" $out_pins2 == {{u1/out[2]} {u1/out[3]} {u1/out[4]} {u1/out[5]}}")

# (checkpoint)
remove_library lib
# (find-string "Removing library")

set in_pins3 [get_cell_pins -inputs u1]
# (assert "$in_pins3 == {}")

set out_pins3 [get_cell_pins -outputs u1]
# (assert "$out_pins3 == {}")

set down_libcell2 [get_reference_link [get_cell_reference u1]]
# (assert "$down_libcell2 == {}")
