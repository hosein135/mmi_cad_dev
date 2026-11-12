# Exact Magic/GDS → MAX scale (Tcl 8.0 safe).
#
# Lengths are integer half-nanometres (1 hnm = 0.5 nm). That unit divides
# the 1 nm GDS lattice, the 5 nm and 50 nm mask grids, and the midpoint of
# an odd number of 5 nm file units. Coordinates stay integers; a conversion
# that would need a fraction is rejected instead of rounded.
#
#   1 um = 2000 hnm
#   1 nm = 2 hnm
#   database unit 0.0005 um = 1 hnm
#   database unit 0.001 um  = 2 hnm

proc mag_exact_is_int {s} {
  if {$s == "" || $s == "-"} { return 0 }
  set i 0
  if {[string index $s 0] == "-"} { set i 1 }
  set n [string length $s]
  if {$i >= $n} { return 0 }
  for {} {$i < $n} {incr i} {
    if {[string first [string index $s $i] 0123456789] < 0} { return 0 }
  }
  return 1
}

proc mag_exact_gcd {a b} {
  if {$a < 0} { set a [expr {0 - $a}] }
  if {$b < 0} { set b [expr {0 - $b}] }
  while {$b != 0} {
    set t [expr {$a % $b}]
    set a $b
    set b $t
  }
  if {$a == 0} { return 1 }
  return $a
}

# Decimal token times an integer "hnm per 1.0 of this token".
# "0.0005" * 2000 = 1.  "10" * 2 = 20.  Empty string on a remainder.
proc mag_exact_dec_hnm {token hnm_per_one} {
  set token [string trim $token]
  if {$token == ""} { return "" }
  set neg 0
  if {[string index $token 0] == "-"} {
    set neg 1
    set token [string range $token 1 end]
  }
  set parts [split $token .]
  if {[llength $parts] > 2} { return "" }
  set ip [lindex $parts 0]
  set fp [lindex $parts 1]
  if {$ip == ""} { set ip 0 }
  if {![mag_exact_is_int $ip]} { return "" }
  if {$fp != "" && ![mag_exact_is_int $fp]} { return "" }
  set flen [string length $fp]
  set denom 1
  set i 0
  while {$i < $flen} {
    set denom [expr {$denom * 10}]
    incr i
  }
  if {$fp == ""} {
    set value $ip
  } else {
    # Strip leading zeros so expr does not read "05" as octal.
    set fp [string trimleft $fp 0]
    if {$fp == ""} { set fp 0 }
    set value [expr {$ip * $denom + $fp}]
  }
  set num [expr {$value * $hnm_per_one}]
  if {[expr {$num % $denom}] != 0} { return "" }
  set hnm [expr {$num / $denom}]
  if {$neg} { set hnm [expr {0 - $hnm}] }
  return $hnm
}

# Microns, as written in a .tech27 "units" line, to half-nanometres.
proc mag_exact_um_hnm {token} {
  return [mag_exact_dec_hnm $token 2000]
}

# Nanometres (Magic "scalefactor N nanometers") to half-nanometres.
proc mag_exact_nm_hnm {token} {
  return [mag_exact_dec_hnm $token 2]
}

# One .mag file unit, in half-nanometres. lambda_hnm is one Magic lambda.
# magscale n/d. Returns "" when n/d does not divide the lambda.
proc mag_exact_file_hnm {lambda_hnm n d} {
  if {![mag_exact_is_int $lambda_hnm] || ![mag_exact_is_int $n] || \
      ![mag_exact_is_int $d]} {
    return ""
  }
  if {$d == 0 || $lambda_hnm <= 0 || $n <= 0} { return "" }
  set num [expr {$lambda_hnm * $n}]
  if {[expr {$num % $d}] != 0} { return "" }
  return [expr {$num / $d}]
}

# Map an integer source coordinate onto destination units.
# Returns "" when the result is not an integer or does not fit a 32-bit int
# (MAX's Tcl 8.0).
proc mag_exact_coord {src src_hnm dst_hnm} {
  if {![mag_exact_is_int $src] || $src_hnm <= 0 || $dst_hnm <= 0} { return "" }
  set num [expr {$src * $src_hnm}]
  if {[string first . $num] >= 0} { return "" }
  if {[expr {$num % $dst_hnm}] != 0} { return "" }
  set out [expr {$num / $dst_hnm}]
  if {[string first . $out] >= 0} { return "" }
  if {$out > 2000000000 || $out < -2000000000} { return "" }
  return $out
}

# Lower-left corner of a label box: smaller x, then smaller y.
proc mag_exact_label_anchor {x1 y1 x2 y2} {
  if {$x1 > $x2} { set t $x1; set x1 $x2; set x2 $t }
  if {$y1 > $y2} { set t $y1; set y1 $y2; set y2 $t }
  return [list $x1 $y1]
}

# Grow a distance (hnm) out to a whole number of file units.
# Returns the integer file-unit count. Never shrinks.
proc mag_exact_grow_file {grow_hnm file_hnm} {
  if {$grow_hnm <= 0 || $file_hnm <= 0} { return 0 }
  set q [expr {$grow_hnm / $file_hnm}]
  set r [expr {$grow_hnm % $file_hnm}]
  if {$r != 0} { incr q }
  return $q
}

# First "units DBRes ..." distance in a .tech27, in half-nanometres.
proc mag_exact_tech27_db_hnm {path} {
  if {![file readable $path]} { return "" }
  if {[catch {set fh [open $path r]}]} { return "" }
  set found ""
  while {[gets $fh line] >= 0} {
    set toks {}
    foreach w [split $line " \t"] {
      if {$w != ""} { lappend toks $w }
    }
    if {[lindex $toks 0] == "units" && [llength $toks] >= 2} {
      set found [mag_exact_um_hnm [lindex $toks 1]]
      break
    }
  }
  close $fh
  return $found
}

# Human reading of a half-nanometre count: "0.5 nm", "5 nm", "37847.5 nm".
proc mag_exact_hnm_text {hnm} {
  if {[expr {$hnm % 2}] == 0} {
    return "[expr {$hnm / 2}] nm"
  }
  set whole [expr {$hnm / 2}]
  if {$hnm < 0 && [expr {$hnm % 2}] != 0} {
    # -1 hnm is -0.5 nm; Tcl integer division truncates toward zero.
    if {$whole == 0} { return "-0.5 nm" }
    return "${whole}.5 nm"
  }
  return "${whole}.5 nm"
}
