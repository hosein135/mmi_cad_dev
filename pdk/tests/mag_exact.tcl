# Exact-scale checks. Pure Tcl: no MAX, no PDK, no Magic.
#   tclsh pdk/tests/mag_exact.tcl
set here [file dirname [info script]]
set root [file join $here .. ..]
set lib [file join $root pdk mag_exact.tcl]
if {![file readable $lib]} {
  set lib [file join $here .. mag_exact.tcl]
}
source $lib

set failed 0
proc check {name script} {
  global failed
  if {![uplevel 1 $script]} {
    puts "FAIL $name"
    incr failed
  } else {
    puts "ok   $name"
  }
}

# sky130: lambda 10 nm = 20 hnm, magscale 1/2 → 5 nm = 10 hnm per file unit.
check "lambda 10 nm" {expr {[mag_exact_nm_hnm 10] == 20}}
check "file unit 5 nm" {expr {[mag_exact_file_hnm 20 1 2] == 10}}
check "0.0005 um is 1 hnm" {expr {[mag_exact_um_hnm 0.0005] == 1}}
check "0.001 um is 2 hnm" {expr {[mag_exact_um_hnm 0.001] == 2}}
check ".0005 um is 1 hnm" {expr {[mag_exact_um_hnm .0005] == 1}}

# odd_rect.mag: rect 70 7344 6652 7795. Corners are whole nanometres.
# 70 file units * 5 nm = 350 nm = 700 hnm = 700 db units at 0.5 nm, 350 at 1 nm.
foreach {src expect1 expect05} {70 350 700  7344 36720 73440  6652 33260 66520  7795 38975 77950} {
  check "corner $src at 1 nm" "expr {[mag_exact_coord $src 10 2] == $expect1}"
  check "corner $src at 0.5 nm" "expr {[mag_exact_coord $src 10 1] == $expect05}"
}

# Midpoint y is 7569.5 file units = 37847.5 nm = 75695 hnm.
# Not an integer database unit when the database unit is 1 nm (2 hnm).
set mid_hnm [expr {(7344 + 7795) * 10 / 2}]
check "midpoint y is 37847.5 nm" {expr {$mid_hnm == 75695}}
check "midpoint text" {expr {[mag_exact_hnm_text $mid_hnm] == "37847.5 nm"}}
check "midpoint rejected at 1 nm" {expr {$mid_hnm % 2 != 0}}
check "midpoint stored at 0.5 nm" {expr {$mid_hnm % 1 == 0}}

# A grid check: every integer file coordinate maps iff the file unit
# divides the destination unit. 5 nm divides both 1 nm and 0.5 nm.
check "5 nm grid divides 1 nm" {expr {10 % 2 == 0}}
check "5 nm grid divides 0.5 nm" {expr {10 % 1 == 0}}

# 2.5 nm file unit (5 hnm) does not divide a 1 nm database unit.
check "2.5 nm file unit" {expr {[mag_exact_file_hnm 10 1 2] == 5}}
check "2.5 nm corner rejected at 1 nm" {expr {[mag_exact_coord 1 5 2] == ""}}
check "2.5 nm corner kept at 0.5 nm" {expr {[mag_exact_coord 1 5 1] == 5}}

# contact.mag is 34 by 34 file units = 170 nm. Even, so its midpoint is on-grid.
check "contact width 170 nm" {expr {[mag_exact_coord 34 10 2] == 170}}
set cmid [expr {(557273 + 557307) * 10 / 2}]
check "contact midpoint on 1 nm" {expr {$cmid % 2 == 0}}

# Label anchor is the lower-left corner, not the midpoint.
# rlabel box 41 8275 183 8288 → anchor (41, 8275) = (205 nm, 41375 nm).
set anchor [mag_exact_label_anchor 183 8288 41 8275]
check "label anchor x" {expr {[lindex $anchor 0] == 41}}
check "label anchor y" {expr {[lindex $anchor 1] == 8275}}
check "label anchor nm" {expr {[mag_exact_coord 41 10 2] == 205 && [mag_exact_coord 8275 10 2] == 41375}}

# Grow 125 nm on a 5 nm grid is 25 file units, exact. 130 nm rounds outward to 26.
check "grow 125 nm exact" {expr {[mag_exact_grow_file [mag_exact_nm_hnm 125] 10] == 25}}
check "grow 130 nm outward" {expr {[mag_exact_grow_file [mag_exact_nm_hnm 130] 10] == 26}}

# tech27 units line.
set tmp [file join $here units_tech27.tmp]
set fh [open $tmp w]
puts $fh "tech\n\tdemo\nend\n\ncifoutput\nstyle demo\n\tunits .0005 .0005 .0005 .0005\nend\n"
close $fh
check "tech27 db unit" {expr {[mag_exact_tech27_db_hnm $tmp] == 1}}
file delete $tmp

if {$failed} {
  puts "$failed check(s) failed"
  exit 1
}
puts "all checks passed"
exit 0
