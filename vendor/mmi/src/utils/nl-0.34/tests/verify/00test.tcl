# (checkpoint)
report_hierarchy -help
# (find-string  "argument" "description" "<design>" "design to report")

# (checkpoint)
read_verilog 00test.v
# (find-string "Current design is now")
# (dont-find-string "argument")

#
# random comment
# 

# (dont-find-string "find-string")
# (assert "[llength [list_designs]] > 0")
