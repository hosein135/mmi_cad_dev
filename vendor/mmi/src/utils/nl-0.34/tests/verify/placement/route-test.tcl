read_verilog route-test.vg

link

create_pdesign

add_net_route -type COVER sub1/a {{M2 {0 0} {100 *} VIA23 {* 200}}}
add_net_route -type FIXED sub1/x {{M1 {300 400} {500 *}} {M1 {300 400} {* 600}}}
add_net_route -type ROUTED p {{M3 {700 800} VIA34 {900 *} {* 1000}}}
add_net_route sub1/z {{M5 {1100 1200} VIA45 VIA34 {1300 *}}}

# (run-command (concat "set tmp " (regtest-make-temp-dir)))

write_def -net_routes -sort $tmp/route-test.def

# (checkpoint)
diff -b $tmp/route-test.def route-test.out.def
# (dont-find-string "<")
# (dont-find-string ">")
# (dont-find-string "child process exited abnormally")
