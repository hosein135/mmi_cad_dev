# hvi gap fill against the real .max rect format.
# tclsh pdk/tests/hvi_gap.tcl
set here [file dirname [info script]]
set root [file join $here .. ..]
set lib [file join $root pdk mag_import.tcl]
if {![file readable $lib]} {
  set lib [file join $here .. mag_import.tcl]
}
if {[catch {source $lib} err]} {
  if {[info commands mag_exact_merge_hvi] == ""} {
    puts "FAIL load: $err"
    exit 1
  }
}

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

set dir [file join [pwd] hvi_gap_test_tmp]
catch {file delete -force $dir}
file mkdir $dir
set path [file join $dir cell.max]
set fh [open $path w]
puts $fh "max 3
tech sky130A
resolution 0.0005

SECTION RECTS \{
layer hvi
700 70000 31090 73440
700 73680 31090 80000
0 0 100 100
1500 0 1600 100
layer met1
1 2 3 4
\} SECTION RECTS
"
close $fh

check "merge writes a bridge" {expr {[mag_exact_merge_hvi $path] == 1}}
set fh [open $path r]
set data [read $fh]
close $fh
check "gap under the pfet row is filled" {
  expr {[string first "700 73440 31090 73680" $data] >= 0}
}
check "0.7 um gap is not a spacing error" {
  expr {[string first "100 0 1500 100" $data] < 0}
}
check "met1 line stays" {
  expr {[string first "1 2 3 4" $data] >= 0}
}
check "second pass adds nothing" {expr {[mag_exact_merge_hvi $path] == 0}}

set fh [open $path r]
set data2 [read $fh]
close $fh
set n 0
foreach line [split $data2 \n] {
  if {[string trim $line] == "700 73440 31090 73680"} { incr n }
}
check "bridge is not duplicated" {expr {$n == 1}}

catch {file delete -force $dir}
if {$failed} {
  puts "$failed failed"
  exit 1
}
puts "all ok"
exit 0
