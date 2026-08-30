set bus_naming_style :%s:%d:
set hierarchy_separator _


# (checkpoint)
set designs [read_verilog link-2.v]
# (find-string "Current design is now")
# (assert "$designs == {m n}")


#
# Before linking, all pins on cells and nets should appear to be
# inouts because their direction is unknown.
#


set pin_dirs [lmapcar get_pin_direction [lsort [get_cell_pins u1]]]
# (assert "$pin_dirs == {unknown unknown unknown unknown unknown unknown unknown unknown unknown}")

unset pin_dirs


set cell_ins [get_cell_pins -inputs u1]
# (assert "$cell_ins == {}")

set cell_outs [get_cell_pins -outputs u1]
# (assert "$cell_outs == {}")

set cell_ios [lsort [get_cell_pins -inouts u1]]
# (assert "$cell_ios == {u1_:ins:0: u1_:ins:1: u1_:ins:2: u1_:ins:3: u1_:outs:0: u1_:outs:1: u1_:outs:2: u1_:outs:3: u1_inouts}")

unset cell_ins
unset cell_outs
unset cell_ios


set net_ins [lsort [get_net_pins -drivers :a:0:]]
# (assert "$net_ins == {:a:0:}")

set net_outs [lsort [get_net_pins -loads :a:0:]]
# (assert "$net_outs == {}")

set net_ios [lsort [get_net_pins -fanios :a:0:]]
# (assert "$net_ios == {u1_:ins:3:}")

unset net_ins
unset net_outs
unset net_ios

set net_ins [lsort [get_net_pins -drivers :b:3:]]
# (assert "$net_ins == {}")

set net_outs [lsort [get_net_pins -loads :b:3:]]
# (assert "$net_outs == {:b:3:}")

set net_ios [lsort [get_net_pins -fanios :b:3:]]
# (assert "$net_ios == {u1_:outs:0:}")

unset net_ins
unset net_outs
unset net_ios

set net_ins [lsort [get_net_pins -drivers c]]
# (assert "$net_ins == {}")

set net_outs [lsort [get_net_pins -loads c]]
# (assert "$net_outs == {}")

set net_ios [lsort [get_net_pins -fanios c]]
# (assert "$net_ios == {c u1_inouts}")

unset net_ins
unset net_outs
unset net_ios


# (checkpoint)
write_verilog -hier -- -
# (find-string "module n ")
# (dont-find-string "module m ")


link

#
# After linking, the pins on cells and nets should have the correct
# direction.
#


set pin_dirs [lmapcar get_pin_direction [lsort [get_cell_pins u1]]]
# (assert "$pin_dirs == {inout in in in in out out out out}")

unset pin_dirs


set cell_ins [lsort [get_cell_pins -inputs u1]]
# (assert "$cell_ins == {u1_:ins:2: u1_:ins:3: u1_:ins:4: u1_:ins:5:}")

set cell_outs [lsort [get_cell_pins -outputs u1]]
# (assert "$cell_outs == {u1_:outs:6: u1_:outs:7: u1_:outs:8: u1_:outs:9:}")

set cell_ios [lsort [get_cell_pins -inouts u1]]
# (assert "$cell_ios == {u1_:inouts:0:}")

unset cell_ins
unset cell_outs
unset cell_ios


set net_ins [lsort [get_net_pins -drivers :a:0:]]
# (assert "$net_ins == {:a:0:}")

set net_outs [lsort [get_net_pins -loads :a:0:]]
# (assert "$net_outs == {u1_:ins:5:}")

set net_ios [lsort [get_net_pins -fanios :a:0:]]
# (assert "$net_ios == {}")

unset net_ins
unset net_outs
unset net_ios


set net_ins [lsort [get_net_pins -drivers :b:3:]]
# (assert "$net_ins == {u1_:outs:9:}")

set net_outs [lsort [get_net_pins -loads :b:3:]]
# (assert "$net_outs == {:b:3:}")

set net_ios [lsort [get_net_pins -fanios :b:3:]]
# (assert "$net_ios == {}")

unset net_ins
unset net_outs
unset net_ios


set net_ins [lsort [get_net_pins -drivers c]]
# (assert "$net_ins == {}")

set net_outs [lsort [get_net_pins -loads c]]
# (assert "$net_outs == {}")

set net_ios [lsort [get_net_pins -fanios c]]
# (assert "$net_ios == {c u1_:inouts:0:}")

unset net_ins
unset net_outs
unset net_ios


# (checkpoint)
write_verilog -hier -- -
# (find-string "module n ")
# (find-string "module m ")


remove_design m

#
# When the child design is removed, the parent design should revert to
# its unlinked state.  The types of the ports on the child design are
# remembered, however.
#

set pin_dirs [lmapcar get_pin_direction [lsort [get_cell_pins u1]]]
# (assert "$pin_dirs == {unknown unknown unknown unknown unknown unknown unknown unknown unknown}")

unset pin_dirs


set cell_ins [get_cell_pins -inputs u1]
# (assert "$cell_ins == {}")

set cell_outs [get_cell_pins -outputs u1]
# (assert "$cell_outs == {}")

set cell_ios [lsort [get_cell_pins -inouts u1]]
# (assert "$cell_ios == {u1_:inouts:0: u1_:ins:2: u1_:ins:3: u1_:ins:4: u1_:ins:5: u1_:outs:6: u1_:outs:7: u1_:outs:8: u1_:outs:9:}")

unset cell_ins
unset cell_outs
unset cell_ios


set net_ins [lsort [get_net_pins -drivers :a:0:]]
# (assert "$net_ins == {:a:0:}")

set net_outs [lsort [get_net_pins -loads :a:0:]]
# (assert "$net_outs == {}")

set net_ios [lsort [get_net_pins -fanios :a:0:]]
# (assert "$net_ios == {u1_:ins:5:}")

unset net_ins
unset net_outs
unset net_ios

set net_ins [lsort [get_net_pins -drivers :b:3:]]
# (assert "$net_ins == {}")

set net_outs [lsort [get_net_pins -loads :b:3:]]
# (assert "$net_outs == {:b:3:}")

set net_ios [lsort [get_net_pins -fanios :b:3:]]
# (assert "$net_ios == {u1_:outs:9:}")

unset net_ins
unset net_outs
unset net_ios

set net_ins [lsort [get_net_pins -drivers c]]
# (assert "$net_ins == {}")

set net_outs [lsort [get_net_pins -loads c]]
# (assert "$net_outs == {}")

set net_ios [lsort [get_net_pins -fanios c]]
# (assert "$net_ios == {c u1_:inouts:0:}")

unset net_ins
unset net_outs
unset net_ios


# (checkpoint)
write_verilog -hier -- -
# (find-string "module n ")
# (dont-find-string "module m ")
