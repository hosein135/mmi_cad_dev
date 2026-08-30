nl_read_verilog hier.vg

nl_create_pdesign -nohier top
nl_create_pdesign -nohier sub1
nl_create_pdesign -nohier sub2
nl_set_die_area {0 0 1000 2000} top
nl_set_die_area {0 0 100 200} sub1
nl_set_die_area {100 200 300 400} sub2

set nl_current_design top
nl_set_cell_location -type COVER s1 0 0
nl_set_cell_location -type FIXED s2 100 0
nl_set_cell_location s3 200 0
nl_set_cell_location -type COVER s4 500 500
nl_set_cell_location -type FIXED s5 700 600
nl_set_cell_location s6 0 500
nl_set_cell_orientation s1 N
nl_set_cell_orientation s2 S
nl_set_cell_orientation s3 FE
nl_set_cell_orientation s4 FW
nl_set_cell_orientation s5 E
nl_set_cell_orientation s6 FN

set nl_current_design sub1
nl_set_cell_location u1 0 0
nl_set_cell_location u2 10 20
nl_set_cell_location -type FIXED u3 20 40
nl_set_cell_location -type COVER u4 30 60
nl_set_cell_orientation u1 FW
nl_set_cell_orientation u2 E
nl_set_cell_orientation u3 FS
nl_set_cell_orientation u4 N

set nl_current_design sub2
nl_set_cell_location u5 100 300
nl_set_cell_location u6 130 320
nl_set_cell_location -type FIXED u7 160 340
nl_set_cell_location -type COVER u8 190 360
nl_set_cell_orientation u5 N
nl_set_cell_orientation u6 FS
nl_set_cell_orientation u7 FE
nl_set_cell_orientation u8 W

set nl_current_design top
nl_link
nl_create_pdesign
nl_update_cell_locations

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

nl_write_def -components -sort $tmp/hier.def

# (checkpoint)
diff -b $tmp/hier.def hier.out.def
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
