# Checks the ngspice raw -> NST ascii converter. Tcl 8.0 or later.
#   tclsh ngspice_nst_test.tcl

set here [file dirname [info script]]
source [file join $here ngspice_nst.tcl]

proc fail {msg} {
  puts "FAIL: $msg"
  exit 1
}

proc near {a b} {
  set d [expr {abs($a - $b)}]
  if {$d > 1.0e-6} {
    return 0
  }
  return 1
}

set tran {
Title: * inverter
Date: Thu Nov 12 12:00:00 2026
Plotname: Transient Analysis
Flags: real
No. Variables: 4
No. Points: 2
Variables:
	0	time	time
	1	v(out)	voltage
	2	v(Xu1.A)	voltage
	3	i(m1)	current
Values:
 0	0.000000000000000e+00
	1.800000000000000e+00
	0.000000000000000e+00
	1.250000000000000e-05
 1	1.000000000000000e-09
	1.200000000000000e+00
	9.000000000000000e-01
	3.000000000000000e-06
}

set text [ngspice_raw_to_nst $tran]
if {$text == ""} {
  fail "transient plot was empty"
}
set lines [split $text \n]
set prefix [string range [lindex $lines 0] 0 18]
if {[string first ascii $prefix] < 0} {
  fail "NST type word is not in the first 19 bytes: [lindex $lines 0]"
}
if {[lindex $lines 1] != "time out xu1.a i(m1"} {
  fail "column names: [lindex $lines 1]"
}
set row [lindex $lines 2]
if {![near [lindex $row 0] 0.0] || ![near [lindex $row 1] 1.8]} {
  fail "first sample: $row"
}
if {![near [lindex $row 3] 1.25e-5]} {
  fail "current sample: $row"
}
set row [lindex $lines 3]
if {![near [lindex $row 0] 1.0e-9] || ![near [lindex $row 2] 0.9]} {
  fail "second sample: $row"
}

set ac {
Title: * ac
Plotname: AC Analysis
Flags: complex
No. Variables: 2
No. Points: 1
Variables:
	0	frequency	frequency
	1	v(out)	voltage
Values:
 0	1.000000000000000e+03,0.000000000000000e+00
	2.500000000000000e+00,-1.000000000000000e+00
Title: * later tran
Plotname: Transient Analysis
Flags: real
No. Variables: 2
No. Points: 1
Variables:
	0	time	time
	1	v(out)	voltage
Values:
 0	5.000000000000000e-09
	4.000000000000000e-01
}

set text [ngspice_raw_to_nst $ac]
set lines [split $text \n]
if {[lindex $lines 1] != "time out"} {
  fail "kept an earlier plot: [lindex $lines 1]"
}
set row [lindex $lines 2]
if {![near [lindex $row 0] 5.0e-9] || ![near [lindex $row 1] 0.4]} {
  fail "last plot sample: $row"
}

set only_ac {
Title: * ac only
Plotname: AC Analysis
Flags: complex
No. Variables: 2
No. Points: 1
Variables:
	0	frequency	frequency
	1	v(out)	voltage
Values:
 0	1.000000000000000e+03,0.000000000000000e+00
	2.500000000000000e+00,-1.000000000000000e+00
}
set text [ngspice_raw_to_nst $only_ac]
set lines [split $text \n]
if {[lindex $lines 1] != "frequency out"} {
  fail "ac columns: [lindex $lines 1]"
}
set row [lindex $lines 2]
if {![near [lindex $row 0] 1000.0] || ![near [lindex $row 1] 2.5]} {
  fail "ac kept the imaginary part: $row"
}

set longv "v(nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn)"
set long [ngspice_column_name $longv]
if {[string length $long] != 40} {
  fail "long net name was shortened: $long"
}

if {[ngspice_raw_to_nst "Title: empty\n"] != ""} {
  fail "empty raw file produced a plot"
}

puts "ngspice_nst_test: ok"
exit 0
