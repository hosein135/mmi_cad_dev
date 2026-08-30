nl_read_verilog ungroup-3.v

nl_create_library lib
nl_create_libcell m1 lib
nl_create_libpin p in lib/m1
nl_create_libpin q in lib/m1
nl_create_libpin r out lib/m1

nl_link -lib lib

nl_ungroup s2
nl_ungroup s1
