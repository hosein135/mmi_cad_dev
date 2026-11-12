# Rule audit. A generated width or spacing must not be stricter than the
# Magic deck when that deck states the number in nanometres.
#   tclsh pdk/tests/rule_audit.tcl
# Skips the deck comparison, with a message, when no Magic .tech is installed.
set here [file dirname [info script]]
source [file join $here .. importer pdk_tables.tcl]

set failed 0
proc bad {msg} {
  global failed
  puts "FAIL $msg"
  incr failed
}

proc report {msg} { puts "report: $msg" }

set rows [pdk_layers_sky130A]
set saw 0
foreach rec $rows {
  if {[lindex $rec 0] != "polyres"} continue
  set saw 1
  set w [lindex $rec 4]
  set s [lindex $rec 5]
  if {$w != "0.35" || $s != "0.21"} {
    bad "polyres width/space is $w/$s; width is the 0.35 um resistor, space is the 0.21 um Magic rule"
  }
}
if {!$saw} { bad "polyres row missing" }

proc deck_numbers {text kind} {
  set raw [split $text \n]
  set lines {}
  set buf ""
  set n [llength $raw]
  for {set i 0} {$i < $n} {incr i} {
    set line [string trim [lindex $raw $i]]
    if {$line == "" || [string match "#*" $line]} {
      if {$buf == ""} continue
    }
    if {[string index $line end] == "\\"} {
      append buf " " [string range $line 0 end-1]
      continue
    }
    append buf " " $line
    set joined [string trim $buf]
    set buf ""
    if {[regexp {^(width|spacing)\y} $joined] && ![regexp {[0-9]} $joined]} {
      set buf $joined
      continue
    }
    if {$joined != ""} { lappend lines $joined }
  }
  if {[string trim $buf] != ""} { lappend lines [string trim $buf] }
  set map {}
  foreach line $lines {
    set layers ""
    set num ""
    if {$kind == "width"} {
      if {![regexp {^width[ \t]+([^ \t]+)[ \t]+([0-9]+)} $line -> layers num]} continue
    } else {
      if {![regexp {^spacing[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([0-9]+)} $line -> a b num]} continue
      set layers $a
    }
    foreach layer [split $layers ,] {
      set layer [string trim $layer]
      set layer [string trimleft $layer *]
      if {$layer == ""} continue
      set i [lsearch -exact $map $layer]
      if {$i < 0} {
        lappend map $layer $num
      } elseif {$num < [lindex $map [expr {$i + 1}]]} {
        set map [lreplace $map [expr {$i + 1}] [expr {$i + 1}] $num]
      }
    }
  }
  return $map
}

proc deck_get {map key} {
  set i [lsearch -exact $map $key]
  if {$i < 0} { return "" }
  return [lindex $map [expr {$i + 1}]]
}

proc find_magic_tech {pdk file} {
  global env
  set roots {}
  if {[info exists env(PDK_ROOT)] && $env(PDK_ROOT) != ""} {
    lappend roots $env(PDK_ROOT)
  }
  if {[info exists env(HOME)] && $env(HOME) != ""} {
    lappend roots [file join $env(HOME) .ciel]
  }
  foreach root $roots {
    set cand [file join $root $pdk libs.tech magic $file]
    if {[file readable $cand]} { return $cand }
  }
  return ""
}

set alias {
  poly allpoly
  polyres xhrpoly
  nwell allnwell
  dnwell dnwell
  diff ndiff
  ndiff ndiff
  pdiff pdiff
  licon1 licon
  li1 locali
  met1 metal1
  met2 metal2
  met3 metal3
  met4 metal4
  met5 metal5
}

set tech [find_magic_tech sky130A sky130A.tech]
if {$tech == ""} {
  puts "rule audit: no sky130A.tech under PDK_ROOT or ~/.ciel; deck comparison skipped"
} else {
  puts "rule audit: $tech"
  set fh [open $tech r]
  set body [read $fh]
  close $fh
  set widths [deck_numbers $body width]
  set spaces [deck_numbers $body spacing]
  foreach rec $rows {
    set layer [lindex $rec 0]
    set w [lindex $rec 4]
    set s [lindex $rec 5]
    set i [lsearch -exact $alias $layer]
    if {$i < 0} {
      report "$layer is not mapped onto a Magic layer in this audit"
      continue
    }
    set key [lindex $alias [expr {$i + 1}]]
    if {[string is double -strict $w]} {
      set deck [deck_get $widths $key]
      if {$deck == ""} {
        report "$layer width $w um has no Magic width rule for $key"
      } elseif {[expr {$w * 1000.0 > $deck + 0.5}]} {
        bad "$layer width $w um is stricter than Magic $key ($deck nm)"
      }
    }
    if {[string is double -strict $s]} {
      set deck [deck_get $spaces $key]
      if {$deck == ""} {
        report "$layer space $s um has no Magic spacing rule for $key"
      } elseif {[expr {$s * 1000.0 > $deck + 0.5}]} {
        bad "$layer space $s um is stricter than Magic $key ($deck nm)"
      }
    }
  }
}

if {$failed} {
  puts "$failed failure(s)"
  exit 1
}
puts "rule audit passed"
exit 0
