read_verilog simple.v

create_pdesign

set_die_area -- {-1000 -2000 30000 40000}

add_x_tracks -- -500 30 1000 {M1 M2 M3 M4 M5}
add_y_tracks -- -1500 43 1000 {M1 M2 M3 M4 M5}

set_port_location a -500 -500
set_port_orientation a N
set_port_geometry a M2 {-100 -200 500 400}

set_port_location -fixed b -500 1500
set_port_geometry b M1 {400 500 -200 -100}
set_port_orientation b FE

set_port_location c -500 2500
set_port_orientation c FS
set_port_geometry c M3 {300 -300 -300 300}

set_port_geometry d M4 {250 -350 -350 250}
set_port_orientation d FW
set_port_location d 1500 -500

set_port_location -fixed z 29500 39500
set_port_orientation z S
set_port_geometry z M5 {50 -600 650 0}

set_cell_location u1 -500 -500
set_cell_orientation u1 E

set_cell_location u2 5000 1000
set_cell_orientation u2 W

set_cell_location -type fixed u3 10000 20000
set_cell_orientation u3 FN

set a_loc [get_port_location a]
set b_loc [get_port_location b]
set c_loc [get_port_location c]
set d_loc [get_port_location d]
set z_loc [get_port_location z]

#(assert "$a_loc == {-500 -500}")
#(assert "$b_loc == {-500 1500}")
#(assert "$c_loc == {-500 2500}")
#(assert "$d_loc == {1500 -500}")
#(assert "$z_loc == {29500 39500}")

set a_geom [get_port_geometry a]
set b_geom [get_port_geometry b]
set c_geom [get_port_geometry c]
set d_geom [get_port_geometry d]
set z_geom [get_port_geometry z]

#(assert "$a_geom == {M2 {-100 -200 500 400}}")
#(assert "$b_geom == {M1 {400 500 -200 -100}}")
#(assert "$c_geom == {M3 {300 -300 -300 300}}")
#(assert "$d_geom == {M4 {250 -350 -350 250}}") 
#(assert "$z_geom == {M5 {50 -600 650 0}}")

set orientations [lmapcar get_port_orientation [lsort [list_ports]]]
#(assert "$orientations == {N FE FS FW S}")

set u1_loc [get_cell_location u1]
set u2_loc [get_cell_location u2]
set u3_loc [get_cell_location u3]

#(assert "$u1_loc == {-500 -500}")
#(assert "$u2_loc == {5000 1000}")
#(assert "$u3_loc == {10000 20000}")

set orientations [lmapcar get_cell_orientation [lsort [list_cells]]]
#(assert "$orientations == {E W FN}")

make_row_sites CORE1
set row_sites_1 [list_row_sites]
# (assert "$row_sites_1 == {{ROW_0001 CORE1 -1000 -2000 N 31 1000 10000} {ROW_0002 CORE1 -1000 8000 S 31 1000 10000} {ROW_0003 CORE1 -1000 18000 N 31 1000 10000} {ROW_0004 CORE1 -1000 28000 S 31 1000 10000}}")

clear_row_sites
# (assert "[list_row_sites] == {}")

make_row_sites CORE1
set row_sites_2 [list_row_sites]
# (assert "$row_sites_2 == {{ROW_0001 CORE1 -1000 -2000 N 31 1000 10000} {ROW_0002 CORE1 -1000 8000 S 31 1000 10000} {ROW_0003 CORE1 -1000 18000 N 31 1000 10000} {ROW_0004 CORE1 -1000 28000 S 31 1000 10000}}")

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_def -specialnets -sort $tmp/simple.def

# (checkpoint)
diff -b $tmp/simple.def simple.out.def
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
